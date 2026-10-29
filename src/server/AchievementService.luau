--!strict
-- Conquistas (Config/Achievements): escuta os eventos da run, atualiza as
-- estatisticas da vida toda no perfil e libera recompensas (classes, armas,
-- passivas, arcanos, estagios, aventuras, ouro). Arma/passiva liberada entra no
-- sorteio a partir da PROXIMA run (como no VS).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local SaveService = require(script.Parent.SaveService)

local AchievementService = {}

local toast = Remotes.event("Toast")

-- Conquistas agrupadas por tipo de condicao (so testa as que podem mudar).
local byKind: { [string]: { any } } = {}

local function unlock(player: Player, profile: SaveService.Profile, ach: any, run: Runs.Run?)
	if profile.achievements[ach.id] then
		return
	end
	profile.achievements[ach.id] = true
	SaveService.grant(profile, ach.reward)
	SaveService.markDirty(player)
	if run then
		table.insert(run.newAchievements, ach.id)
	end
	toast:FireClient(player, { kind = "achievement", id = ach.id })
end

local function check(player: Player, kind: string, run: Runs.Run?, test: (any) -> boolean)
	local profile = SaveService.peek(player)
	local list = byKind[kind]
	if not profile or not list then
		return
	end
	for _, ach in list do
		if not profile.achievements[ach.id] and test(ach) then
			unlock(player, profile, ach, run)
		end
	end
end

local function countSet(set: { [string]: boolean }): number
	local n = 0
	for _ in set do
		n += 1
	end
	return n
end

local function onEnemyKilled(run: Runs.Run, enemy: any)
	if enemy.tier == "special" then
		return -- tocha e Ceifadora nao contam
	end
	local profile = SaveService.peek(run.player)
	if not profile then
		return
	end
	local s = profile.stats
	local id = enemy.def.id
	s.kills += 1
	s.killsBy[id] = (s.killsBy[id] or 0) + 1
	SaveService.markDirty(run.player)
	check(run.player, "killsTotal", run, function(ach)
		return s.kills >= ach.n
	end)
	check(run.player, "killsEnemy", run, function(ach)
		return ach.enemy == id and (s.killsBy[id] or 0) >= ach.n
	end)
	if enemy.tier == "boss" then
		s.bossKills += 1
		check(run.player, "bossKills", run, function(ach)
			return s.bossKills >= ach.n
		end)
	end
end

local function onMinute(run: Runs.Run, minute: number)
	local profile = SaveService.peek(run.player)
	if profile and minute > profile.stats.bestMinutes then
		profile.stats.bestMinutes = minute
		SaveService.markDirty(run.player)
	end
	check(run.player, "surviveMinutes", run, function(ach)
		return minute >= ach.n
			and (ach.class == nil or ach.class == run.classId)
			and (ach.stage == nil or ach.stage == run.stageId)
	end)
end

local function onLevel(run: Runs.Run, level: number)
	local profile = SaveService.peek(run.player)
	if profile and level > profile.stats.bestLevel then
		profile.stats.bestLevel = level
		SaveService.markDirty(run.player)
	end
	check(run.player, "reachLevel", run, function(ach)
		return level >= ach.n and (ach.class == nil or ach.class == run.classId)
	end)
end

local function onWeaponMaxed(run: Runs.Run, weaponId: string)
	local profile = SaveService.peek(run.player)
	if profile then
		profile.stats.maxed[weaponId] = true
		SaveService.markDirty(run.player)
	end
	check(run.player, "weaponMax", run, function(ach)
		return ach.weapon == weaponId
	end)
end

local function onEvolved(run: Runs.Run, _fromId: string, toId: string)
	local profile = SaveService.peek(run.player)
	if not profile then
		return
	end
	profile.stats.evolved[toId] = true
	SaveService.markDirty(run.player)
	check(run.player, "evolveAny", run, function()
		return true
	end)
	check(run.player, "evolve", run, function(ach)
		return ach.weapon == toId
	end)
	local distinct = countSet(profile.stats.evolved)
	check(run.player, "evolveDistinct", run, function(ach)
		return distinct >= ach.n
	end)
end

local function onChest(run: Runs.Run)
	local profile = SaveService.peek(run.player)
	if not profile then
		return
	end
	profile.stats.chests += 1
	SaveService.markDirty(run.player)
	check(run.player, "chestsTotal", run, function(ach)
		return profile.stats.chests >= ach.n
	end)
end

local function onPickup(run: Runs.Run, pickupId: string)
	local profile = SaveService.peek(run.player)
	if not profile then
		return
	end
	local p = profile.stats.pickups
	p[pickupId] = (p[pickupId] or 0) + 1
	SaveService.markDirty(run.player)
	check(run.player, "pickup", run, function(ach)
		return ach.pickup == pickupId and p[pickupId] >= (ach.n or 1)
	end)
end

local function onStageCompleted(run: Runs.Run)
	if run.adventureId then
		return -- capitulo de aventura tem tempo proprio: nao conta como estagio completo
	end
	local profile = SaveService.peek(run.player)
	if profile then
		profile.stats.completed[run.stageId] = true
		SaveService.markDirty(run.player)
	end
	check(run.player, "completeStage", run, function(ach)
		return ach.stage == run.stageId
	end)
end

local function onRunEnded(run: Runs.Run, _reason: string, results: any)
	local profile = SaveService.peek(run.player)
	if not profile then
		return
	end
	local s = profile.stats
	s.runs += 1
	s.goldTotal += results.gold or 0
	SaveService.markDirty(run.player)
	check(run.player, "runs", run, function(ach)
		return s.runs >= ach.n
	end)
	check(run.player, "goldTotal", run, function(ach)
		return s.goldTotal >= ach.n
	end)
end

local function onChapter(player: Player, adventureId: string, chapter: number)
	check(player, "adventureChapter", Runs.get(player), function(ach)
		return ach.adventure == adventureId and chapter >= ach.chapter
	end)
end

function AchievementService.init()
	for _, ach in Config.Achievements do
		local list = byKind[ach.kind]
		if not list then
			list = {}
			byKind[ach.kind] = list
		end
		table.insert(list, ach)
	end

	Events.on("EnemyKilled", onEnemyKilled)
	Events.on("MinuteReached", onMinute)
	Events.on("LevelReached", onLevel)
	Events.on("WeaponMaxed", onWeaponMaxed)
	Events.on("WeaponEvolved", onEvolved)
	Events.on("ChestOpened", onChest)
	Events.on("PickupCollected", onPickup)
	Events.on("StageCompleted", onStageCompleted)
	Events.on("RunEnded", onRunEnded)
	Events.on("AdventureChapterDone", onChapter)
end

return AchievementService
