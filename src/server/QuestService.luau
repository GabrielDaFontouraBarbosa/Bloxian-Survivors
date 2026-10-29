--!strict
-- Missoes (Config/Quests): sempre Config.Meta.QuestSlots ativas por jogador. O
-- progresso vem dos eventos da run; completou -> o jogador resgata no lobby,
-- ganha ouro e outra missao sorteada entra no lugar.
-- Regra de retencao do projeto: SEM prazo, SEM reset diario, SEM punicao.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local SaveService = require(script.Parent.SaveService)

local QuestService = {}

local toast = Remotes.event("Toast")

-- Tipos que guardam a MELHOR marca numa run (os outros somam).
local BEST_KINDS = { surviveMinutes = true, reachLevel = true }

local function isActive(profile: SaveService.Profile, id: string): boolean
	for _, q in profile.quests do
		if q.id == id then
			return true
		end
	end
	return false
end

-- Completa a lista de missoes ativas com sorteios (sem repetir as ativas).
function QuestService.ensure(profile: SaveService.Profile)
	while #profile.quests < Config.Meta.QuestSlots do
		local candidates = {}
		for _, def in Config.Quests do
			if not isActive(profile, def.id) then
				table.insert(candidates, def.id)
			end
		end
		if #candidates == 0 then
			return
		end
		table.insert(profile.quests, { id = candidates[math.random(#candidates)], progress = 0 })
	end
end

-- Resgata a missao `index` se estiver completa. Devolve o ouro ganho (0 se nao deu).
function QuestService.claim(player: Player, index: any): number
	local profile = SaveService.peek(player)
	if not profile or type(index) ~= "number" then
		return 0
	end
	local i = math.floor(index)
	local q = profile.quests[i]
	local def = q and Content.quests[q.id]
	if not q or not def or q.progress < def.n then
		return 0
	end
	profile.gold += def.reward
	table.remove(profile.quests, i)
	QuestService.ensure(profile)
	SaveService.markDirty(player)
	return def.reward
end

local function bump(run: Runs.Run, kind: string, amount: number, filter: ((any) -> boolean)?)
	local profile = SaveService.peek(run.player)
	if not profile then
		return
	end
	for _, q in profile.quests do
		local def = Content.quests[q.id]
		if def and def.kind == kind and q.progress < def.n and (filter == nil or filter(def)) then
			if BEST_KINDS[kind] then
				q.progress = math.max(q.progress, math.min(amount, def.n))
			else
				q.progress = math.min(def.n, q.progress + amount)
			end
			SaveService.markDirty(run.player)
			if q.progress >= def.n then
				toast:FireClient(run.player, { kind = "quest", id = q.id })
			end
		end
	end
end

function QuestService.init()
	Events.on("EnemyKilled", function(run: Runs.Run, enemy: any)
		if enemy.tier == "special" then
			return
		end
		bump(run, "kills", 1)
		local id = enemy.def.id
		bump(run, "killsEnemy", 1, function(def)
			return def.enemy == id
		end)
		if enemy.tier == "boss" then
			bump(run, "bossKills", 1)
		end
	end)
	Events.on("ChestOpened", function(run: Runs.Run)
		bump(run, "chests", 1)
	end)
	Events.on("WeaponEvolved", function(run: Runs.Run)
		bump(run, "evolveAny", 1)
	end)
	Events.on("PickupCollected", function(run: Runs.Run)
		bump(run, "pickups", 1)
	end)
	Events.on("MinuteReached", function(run: Runs.Run, minute: number)
		bump(run, "surviveMinutes", minute)
	end)
	Events.on("LevelReached", function(run: Runs.Run, level: number)
		bump(run, "reachLevel", level)
	end)
	Events.on("RunEnded", function(run: Runs.Run, _reason: string, results: any)
		bump(run, "runs", 1)
		bump(run, "gold", results.gold or 0)
	end)
end

return QuestService
