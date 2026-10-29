--!strict
-- Persistencia do perfil via DataStore: ouro, PowerUps, desbloqueios, classes
-- compradas, conquistas, missoes, aventuras, estatisticas e ultima selecao.
-- Perfil v2. Le o v1 (moedas + perks + classId) e migra.
--
-- IMPORTANTE: DataStore so funciona em jogo PUBLICADO e, no Studio, exige
-- "Enable Studio Access to API Services". Fora disso cai para perfil em memoria
-- e avisa uma vez: o jogo roda normal, so nao persiste entre sessoes.
--
-- Uso: SaveService.load (pode esperar o DataStore) e chamado UMA vez no join;
-- o resto do jogo usa SaveService.peek (nunca espera; nil se ainda carregando).
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local SaveService = {}

local VERSION = 2
local UNLOCK_KINDS = { "class", "weapon", "passive", "arcana", "stage", "adventure" }

export type ProfileStats = {
	kills: number,
	killsBy: { [string]: number },
	bossKills: number,
	chests: number,
	goldTotal: number,
	runs: number,
	pickups: { [string]: number },
	evolved: { [string]: boolean },
	maxed: { [string]: boolean },
	completed: { [string]: boolean },
	bestMinutes: number,
	bestLevel: number,
}

export type QuestState = { id: string, progress: number }

export type Profile = {
	v: number,
	gold: number,
	powerUps: { [string]: number }, -- id -> rank
	spent: number, -- ouro gasto em PowerUps (para o reembolso)
	bought: number, -- ranks comprados no total (encarece os proximos)
	unlocks: { [string]: { [string]: boolean } }, -- kind -> id -> true
	owned: { [string]: boolean }, -- classes compradas
	achievements: { [string]: boolean },
	stats: ProfileStats,
	quests: { QuestState },
	adventures: { [string]: number }, -- id -> capitulos completos
	selected: { class: string, stage: string, arcana: string },
}

local store: DataStore? = nil
local profiles: { [Player]: Profile } = {}
local loading: { [Player]: boolean } = {}
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

local function keyFor(player: Player): string
	return "player_" .. tostring(player.UserId)
end

local function emptyStats(): ProfileStats
	return {
		kills = 0,
		killsBy = {},
		bossKills = 0,
		chests = 0,
		goldTotal = 0,
		runs = 0,
		pickups = {},
		evolved = {},
		maxed = {},
		completed = {},
		bestMinutes = 0,
		bestLevel = 0,
	}
end

local function defaultProfile(): Profile
	local unlocks = {}
	for _, kind in UNLOCK_KINDS do
		unlocks[kind] = {}
	end
	return {
		v = VERSION,
		gold = 0,
		powerUps = {},
		spent = 0,
		bought = 0,
		unlocks = unlocks,
		owned = {},
		achievements = {},
		stats = emptyStats(),
		quests = {},
		adventures = {},
		selected = { class = Config.Meta.DefaultClassId, stage = Config.Meta.DefaultStageId, arcana = "" },
	}
end

-- ====== validacao do que vem salvo (nunca confiar cegamente) ======

local function num(value: any, default: number): number
	if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
		return value
	end
	return default
end

local function count(value: any): number
	return math.max(0, math.floor(num(value, 0)))
end

-- Mapa id -> true, aceitando so ids que existem no catalogo.
local function boolSet(value: any, catalog: { [string]: any }?): { [string]: boolean }
	local out = {}
	if type(value) == "table" then
		for id, flag in value :: { [any]: any } do
			if type(id) == "string" and flag == true and (catalog == nil or catalog[id] ~= nil) then
				out[id] = true
			end
		end
	end
	return out
end

-- Mapa id -> contagem, aceitando so ids que existem no catalogo.
local function countMap(value: any, catalog: { [string]: any }?): { [string]: number }
	local out = {}
	if type(value) == "table" then
		for id, n in value :: { [any]: any } do
			if type(id) == "string" and (catalog == nil or catalog[id] ~= nil) then
				local c = count(n)
				if c > 0 then
					out[id] = c
				end
			end
		end
	end
	return out
end

local function sanitizeV2(data: any, profile: Profile)
	profile.gold = count(data.gold)
	profile.spent = count(data.spent)
	profile.bought = count(data.bought)
	-- PowerUps: limita ao rank maximo do catalogo
	if type(data.powerUps) == "table" then
		for id, rank in data.powerUps :: { [any]: any } do
			local def = type(id) == "string" and Content.powerUps[id]
			if def then
				profile.powerUps[id] = math.min(count(rank), def.maxLevel)
			end
		end
	end
	if type(data.unlocks) == "table" then
		for _, kind in UNLOCK_KINDS do
			profile.unlocks[kind] = boolSet((data.unlocks :: any)[kind], Content.byKind[kind])
		end
	end
	profile.owned = boolSet(data.owned, Content.classes)
	profile.achievements = boolSet(data.achievements, Content.achievements)

	local s = type(data.stats) == "table" and data.stats or {}
	profile.stats = {
		kills = count(s.kills),
		killsBy = countMap(s.killsBy, Content.enemies),
		bossKills = count(s.bossKills),
		chests = count(s.chests),
		goldTotal = count(s.goldTotal),
		runs = count(s.runs),
		pickups = countMap(s.pickups, Content.pickups),
		evolved = boolSet(s.evolved, Content.weapons),
		maxed = boolSet(s.maxed, Content.weapons),
		completed = boolSet(s.completed, Content.stages),
		bestMinutes = count(s.bestMinutes),
		bestLevel = count(s.bestLevel),
	}

	if type(data.quests) == "table" then
		for _, q in data.quests :: { any } do
			if type(q) == "table" and type(q.id) == "string" and Content.quests[q.id] and #profile.quests < Config.Meta.QuestSlots then
				table.insert(profile.quests, { id = q.id, progress = count(q.progress) })
			end
		end
	end
	if type(data.adventures) == "table" then
		for id, done in data.adventures :: { [any]: any } do
			local adv = type(id) == "string" and Content.adventures[id]
			if adv then
				profile.adventures[id] = math.min(count(done), #adv.chapters)
			end
		end
	end
	if type(data.selected) == "table" then
		local sel = data.selected :: any
		if type(sel.class) == "string" and Content.classes[sel.class] then
			profile.selected.class = sel.class
		end
		if type(sel.stage) == "string" and Content.stages[sel.stage] then
			profile.selected.stage = sel.stage
		end
		if type(sel.arcana) == "string" and (sel.arcana == "" or Content.arcanas[sel.arcana]) then
			profile.selected.arcana = sel.arcana
		end
	end
end

-- Perfil v1 (antes do porte): { coins, perks = { damage, health, speed }, classId }.
local V1_PERK_TO_POWERUP = { damage = "might", health = "health", speed = "moveSpeed" }

local function migrateV1(data: any, profile: Profile)
	profile.gold = count(data.coins)
	if type(data.perks) == "table" then
		for oldId, rank in data.perks :: { [any]: any } do
			local newId = type(oldId) == "string" and V1_PERK_TO_POWERUP[oldId]
			local def = newId and Content.powerUps[newId]
			if newId and def then
				profile.powerUps[newId] = math.min(count(rank), def.maxLevel)
			end
		end
	end
	if type(data.classId) == "string" and Content.classes[data.classId] then
		profile.selected.class = data.classId
	end
end

-- ====== API ======

-- Carrega (ou cria) o perfil. PODE ESPERAR o DataStore: chamar so no join.
function SaveService.load(player: Player): Profile
	local cached = profiles[player]
	if cached then
		return cached
	end
	while loading[player] do
		task.wait()
		local again = profiles[player]
		if again then
			return again
		end
	end
	loading[player] = true
	local profile = defaultProfile()
	local ds = getStore()
	if ds then
		local ok, data = pcall(function()
			return ds:GetAsync(keyFor(player))
		end)
		if ok and type(data) == "table" then
			if (data :: any).v == VERSION then
				sanitizeV2(data, profile)
			else
				migrateV1(data, profile)
			end
		elseif not ok then
			warnOnce("Falha ao ler o DataStore.")
		end
	end
	loading[player] = nil
	if player.Parent then
		profiles[player] = profile -- saiu enquanto carregava: nao guarda em memoria
	end
	return profile
end

-- Perfil ja carregado (nunca espera). nil enquanto carrega.
function SaveService.peek(player: Player): Profile?
	return profiles[player]
end

function SaveService.markDirty(player: Player)
	dirty[player] = true
end

-- Conteudo liberado? (entrada default = sempre liberada)
function SaveService.isUnlocked(profile: Profile, kind: string, id: string): boolean
	local catalog = Content.byKind[kind]
	local def = catalog and catalog[id]
	if not def then
		return false
	end
	if def.default then
		return true
	end
	local set = profile.unlocks[kind]
	return set ~= nil and set[id] == true
end

-- Classe comprada? (default = ja vem comprada)
function SaveService.ownsClass(profile: Profile, id: string): boolean
	local def = Content.classes[id]
	if not def then
		return false
	end
	return def.default == true or profile.owned[id] == true
end

-- Aplica uma recompensa ({ kind = "gold", amount } ou { kind, id }). Devolve true se mudou algo.
function SaveService.grant(profile: Profile, reward: any): boolean
	if type(reward) ~= "table" then
		return false
	end
	if reward.kind == "gold" then
		profile.gold += count(reward.amount)
		return true
	end
	local set = profile.unlocks[reward.kind]
	local catalog = Content.byKind[reward.kind]
	if set and catalog and catalog[reward.id] and not set[reward.id] then
		set[reward.id] = true
		return true
	end
	return false
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
		ds:SetAsync(keyFor(player), profile)
	end)
	if ok then
		dirty[player] = nil
	else
		warnOnce("Falha ao gravar no DataStore.")
	end
end

-- Salva e solta da memoria (jogador saindo). Chamado pelo Main depois de fechar a run.
function SaveService.release(player: Player)
	SaveService.save(player)
	profiles[player] = nil
	dirty[player] = nil
	loading[player] = nil
end

function SaveService.saveAll()
	for player in profiles do
		SaveService.save(player)
	end
end

function SaveService.init()
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
end

return SaveService
