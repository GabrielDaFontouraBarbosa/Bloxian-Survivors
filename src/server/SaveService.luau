--!strict
-- Persistencia do perfil do jogador (moedas + perks permanentes) via DataStore.
--
-- IMPORTANTE: DataStore so funciona em jogo PUBLICADO e, no Studio, exige
-- "Enable Studio Access to API Services" (Game Settings > Security). Em teste
-- local via Rojo num lugar nao publicado as chamadas falham. Por isso tudo esta
-- em pcall e o servico cai para um perfil em memoria, avisando uma vez. O jogo
-- continua jogavel; so nao persiste entre sessoes.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SaveService = {}

export type Profile = {
	coins: number,
	perks: { [string]: number }, -- id do perk -> quantas vezes comprado
	classId: string, -- classe escolhida (DESIGN.md secao 6)
}

local store: DataStore? = nil
local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}
local warned = false

local function warnOnce(message: string)
	if not warned then
		warned = true
		warn("[Survivors] " .. message .. " O jogo roda normal, mas o progresso nao persiste.")
	end
end

local function getStore(): DataStore?
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Meta.DataStoreName)
	end)
	if ok then
		store = result
		return store
	end
	warnOnce("DataStore indisponivel (jogo nao publicado ou API Services desligado).")
	return nil
end

local function defaultProfile(): Profile
	return { coins = 0, perks = {}, classId = Config.DefaultClassId }
end

-- Confere se o id existe no catalogo de classes (nao confiar no que vem salvo/cliente).
local function classExists(id: string): boolean
	for _, class in Config.Classes do
		if class.id == id then
			return true
		end
	end
	return false
end

local function keyFor(player: Player): string
	return "player_" .. tostring(player.UserId)
end

-- Carrega (ou cria) o perfil. Sincrono e seguro: sempre devolve um perfil.
function SaveService.get(player: Player): Profile
	local cached = profiles[player]
	if cached then
		return cached
	end
	local profile = defaultProfile()
	local ds = getStore()
	if ds then
		local ok, data = pcall(function()
			return ds:GetAsync(keyFor(player))
		end)
		if ok and type(data) == "table" then
			-- aceita so o que a gente conhece, com tipos certos
			local coins = (data :: any).coins
			local perks = (data :: any).perks
			if type(coins) == "number" then
				profile.coins = math.max(0, math.floor(coins))
			end
			if type(perks) == "table" then
				for id, level in (perks :: { [string]: any }) do
					if type(id) == "string" and type(level) == "number" then
						profile.perks[id] = math.max(0, math.floor(level))
					end
				end
			end
			local classId = (data :: any).classId
			if type(classId) == "string" and classExists(classId) then
				profile.classId = classId -- senao fica o DefaultClassId
			end
		elseif not ok then
			warnOnce("Falha ao ler o DataStore.")
		end
	end
	profiles[player] = profile
	return profile
end

function SaveService.addCoins(player: Player, amount: number)
	local profile = SaveService.get(player)
	profile.coins += amount
	dirty[player] = true
end

-- Gasta se tiver saldo. Devolve true se gastou.
function SaveService.trySpend(player: Player, cost: number): boolean
	local profile = SaveService.get(player)
	if profile.coins < cost then
		return false
	end
	profile.coins -= cost
	dirty[player] = true
	return true
end

function SaveService.markDirty(player: Player)
	dirty[player] = true
end

-- Troca a classe escolhida (usado pela selecao da cidade, mais pra frente).
-- Ignora id invalido. Devolve true se mudou de fato.
function SaveService.setClass(player: Player, id: string): boolean
	if not classExists(id) then
		return false
	end
	local profile = SaveService.get(player)
	if profile.classId == id then
		return false
	end
	profile.classId = id
	dirty[player] = true
	return true
end

function SaveService.save(player: Player)
	local profile = profiles[player]
	if not profile or not dirty[player] then
		return
	end
	local ds = getStore()
	if not ds then
		return
	end
	local ok = pcall(function()
		ds:SetAsync(keyFor(player), { coins = profile.coins, perks = profile.perks, classId = profile.classId })
	end)
	if ok then
		dirty[player] = nil
	else
		warnOnce("Falha ao gravar no DataStore.")
	end
end

function SaveService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(SaveService.get, player) -- pre-carrega sem travar o join
	end)
	Players.PlayerRemoving:Connect(function(player)
		SaveService.save(player)
		profiles[player] = nil
		dirty[player] = nil
	end)

	-- flush periodico: evita bater no rate limit do DataStore a cada compra
	task.spawn(function()
		while true do
			task.wait(Config.Meta.SaveIntervalSec)
			-- coleta antes de salvar: save() limpa a flag da tabela que estamos lendo
			local pending: { Player } = {}
			for player in dirty do
				table.insert(pending, player)
			end
			for _, player in pending do
				SaveService.save(player)
			end
		end
	end)

	-- ultima chance de gravar quando o servidor fecha
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			SaveService.save(player)
		end
	end)
end

return SaveService
