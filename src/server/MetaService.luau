--!strict
-- Meta-progressao: moeda ganha matando (fica mesmo morrendo), loja de perks
-- permanentes e inicio de cada vida/partida (base = Config + perks, run resetada).
-- Catalogo e custos em Config.Meta. Compra validada aqui, nunca no cliente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SaveService = require(script.Parent.SaveService)
local PlayerStats = require(script.Parent.PlayerStats)
local XpService = require(script.Parent.XpService)
local Analytics = require(script.Parent.Analytics)

local MetaService = {}

local metaSync = Remotes.event("MetaSync")
local buyPerk = Remotes.event("BuyPerk")

local lastSync: { [Player]: number } = {}

local function perkById(id: string): any
	for _, perk in Config.Meta.Perks do
		if perk.id == id then
			return perk
		end
	end
	return nil
end

-- Resolve a classe do jogador (cai no DefaultClassId se o id nao existir mais).
local function classFor(player: Player): any
	local profile = SaveService.get(player)
	for _, class in Config.Classes do
		if class.id == profile.classId then
			return class
		end
	end
	for _, class in Config.Classes do
		if class.id == Config.DefaultClassId then
			return class
		end
	end
	return Config.Classes[1]
end

local function costFor(perk: any, level: number): number
	return math.floor(perk.baseCost * perk.costGrowth ^ level + 0.5)
end

-- Manda pro cliente o saldo e o estado da loja (nivel e preco de cada perk).
function MetaService.sync(player: Player)
	local profile = SaveService.get(player)
	local shop = {}
	for _, perk in Config.Meta.Perks do
		local level = profile.perks[perk.id] or 0
		table.insert(shop, {
			id = perk.id,
			name = perk.name,
			desc = perk.desc,
			level = level,
			cost = costFor(perk, level),
		})
	end
	lastSync[player] = os.clock()
	metaSync:FireClient(player, profile.coins, shop)
end

local function syncThrottled(player: Player)
	local last = lastSync[player]
	if last and os.clock() - last < 0.2 then
		return
	end
	MetaService.sync(player)
end

-- Base permanente da vida atual: stats iniciais da CLASSE + perks comprados.
local function buildBase(player: Player): PlayerStats.Stats
	local profile = SaveService.get(player)
	local cs = (classFor(player).stats or {}) :: any
	local stats: PlayerStats.Stats = {
		damage = cs.damage or Config.Weapon.Damage,
		fireInterval = cs.fireInterval or Config.Weapon.FireInterval,
		walkSpeed = cs.walkSpeed or Config.Player.WalkSpeed,
		maxHealth = cs.maxHealth or Config.Player.MaxHealth,
		magnetRadius = cs.magnetRadius or Config.Xp.MagnetRadius,
	}
	local statsAny = stats :: any
	for _, perk in Config.Meta.Perks do
		local level = profile.perks[perk.id] or 0
		if level > 0 then
			statsAny[perk.field] += perk.amount * level
		end
	end
	return stats
end

-- Chamado quando o inimigo morre: paga a moeda ao dono do tiro.
function MetaService.onKill(player: Player)
	SaveService.addCoins(player, Config.Meta.CoinPerKill)
	syncThrottled(player)
end

-- Comeca uma nova vida/partida: aplica a base e zera o progresso de run.
function MetaService.startRun(player: Player)
	local class = classFor(player)
	print(("[Survivors] %s entrou como %s (arma: %s)."):format(player.Name, class.name, class.weapon.name))
	PlayerStats.setBase(player, buildBase(player))
	PlayerStats.applyToHumanoid(player)
	XpService.resetRun(player)
	MetaService.sync(player)
end

function MetaService.init()
	buyPerk.OnServerEvent:Connect(function(player, id)
		if typeof(id) ~= "string" then
			return
		end
		local perk = perkById(id)
		if not perk then
			return -- id inventado pelo cliente
		end
		local profile = SaveService.get(player)
		local level = profile.perks[id] or 0
		local cost = costFor(perk, level)
		if not SaveService.trySpend(player, cost) then
			MetaService.sync(player) -- saldo insuficiente: so re-sincroniza
			return
		end
		profile.perks[id] = level + 1
		SaveService.markDirty(player)
		-- vale ja nesta vida e persiste nas proximas
		PlayerStats.bump(player, perk.field, perk.amount)
		Analytics.perkBought(player, id, level + 1, cost, profile.coins)
		MetaService.sync(player)
	end)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(MetaService.startRun, player)
		end)
		if player.Character then
			task.defer(MetaService.startRun, player)
		end
	end
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerAdded:Connect(onPlayer)

	Players.PlayerRemoving:Connect(function(player)
		PlayerStats.cleanup(player)
		lastSync[player] = nil
	end)
end

return MetaService
