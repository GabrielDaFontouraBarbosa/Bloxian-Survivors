--!strict
-- Ciclo de vida das runs (uma por jogador):
--   start  -> valida as escolhas do lobby contra o perfil, monta a run, sobe o
--             jogador para a arena dele
--   update -> loop central unico: estagio, inimigos, armas, XP, itens, vida
--   endRun -> morte, Ceifadora, desistencia ou saida: guarda o ouro (mesmo
--             morrendo — regra de retencao), avisa conquistas/missoes, limpa
--             tudo e devolve o jogador ao lobby
-- Tambem cuida do spawn do personagem (CharacterAutoLoads desligado).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local SaveService = require(script.Parent.SaveService)
local Stats = require(script.Parent.Stats)
local Arena = require(script.Parent.Arena)
local Loadout = require(script.Parent.Loadout)
local PlayerHealth = require(script.Parent.PlayerHealth)
local EnemyService = require(script.Parent.EnemyService)
local WeaponService = require(script.Parent.WeaponService)
local XpService = require(script.Parent.XpService)
local PickupService = require(script.Parent.PickupService)
local ChestService = require(script.Parent.ChestService)
local StageService = require(script.Parent.StageService)
local AdventureService = require(script.Parent.AdventureService)
local RateLimit = require(script.Parent.RateLimit)
local Analytics = require(script.Parent.Analytics)

local RunManager = {}

local requestStartRun = Remotes.event("RequestStartRun")
local quitRun = Remotes.event("QuitRun")
local runState = Remotes.event("RunState")
local runSync = Remotes.event("RunSync")
local runResults = Remotes.event("RunResults")
local notice = Remotes.event("Notice")

local function lobbyCFrame(): CFrame
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		return spawn.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(Config.Lobby.SpawnFallback)
end

local function humanoidOf(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function resetLobbyHumanoid(player: Player)
	local hum = humanoidOf(player)
	if hum and hum.Health > 0 then
		hum.WalkSpeed = Config.Lobby.WalkSpeed
		hum.MaxHealth = Config.Lobby.MaxHealth
		hum.Health = Config.Lobby.MaxHealth
	end
end

-- Foto do que esta liberado no inicio (desbloqueios no meio valem na proxima run, como no VS).
local function snapshotUnlocks(profile: SaveService.Profile): { [string]: { [string]: boolean } }
	local out = { weapon = {}, passive = {} }
	for _, def in Config.Weapons do
		if not def.evolved and SaveService.isUnlocked(profile, "weapon", def.id) then
			out.weapon[def.id] = true
		end
	end
	for _, def in Config.Passives do
		if SaveService.isUnlocked(profile, "passive", def.id) then
			out.passive[def.id] = true
		end
	end
	return out
end

function RunManager.inRun(player: Player): boolean
	return Runs.get(player) ~= nil
end

-- Comeca uma run. `req` vem do cliente: { class, stage, arcana, adventure, chapter }.
-- Tudo e conferido contra o perfil (nunca confiar no cliente).
function RunManager.start(player: Player, req: any): (boolean, string?)
	if Runs.get(player) then
		return false, "Você já está numa partida."
	end
	local profile = SaveService.peek(player)
	if not profile then
		return false, "Seu perfil ainda está carregando."
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum or hum.Health <= 0 then
		return false, "Espere seu personagem aparecer."
	end
	if type(req) ~= "table" then
		req = {}
	end

	local classId: string = if type(req.class) == "string" then req.class else profile.selected.class
	local stageId: string = if type(req.stage) == "string" then req.stage else profile.selected.stage
	local arcanaId: string = if type(req.arcana) == "string" then req.arcana else ""
	local mods: { [string]: any } = {}
	local duration: number? = nil
	local adventureId: string? = nil
	local chapterIndex: number? = nil
	local forcedClass = false

	if type(req.adventure) == "string" then
		local chapter, err = AdventureService.resolve(profile, req.adventure, req.chapter)
		if not chapter then
			return false, err
		end
		adventureId = req.adventure
		chapterIndex = math.floor(req.chapter)
		mods = chapter.mods or {}
		duration = chapter.duration
		stageId = chapter.stage
		if chapter.class then
			classId = chapter.class
			forcedClass = true
		end
	elseif not SaveService.isUnlocked(profile, "stage", stageId) then
		return false, "Esse estágio ainda está bloqueado."
	end

	local class = Content.classes[classId]
	if not class then
		return false, "Classe inválida."
	end
	if not forcedClass and not SaveService.ownsClass(profile, classId) then
		return false, "Você ainda não tem essa classe."
	end
	local stage = Content.stages[stageId]
	if not stage then
		return false, "Estágio inválido."
	end
	local arcana = nil
	if arcanaId ~= "" then
		if not SaveService.isUnlocked(profile, "arcana", arcanaId) then
			return false, "Esse arcano ainda está bloqueado."
		end
		arcana = Content.arcanas[arcanaId]
	end

	-- lembra a escolha para a proxima vez
	if not adventureId then
		profile.selected.class = classId
		profile.selected.stage = stageId
	end
	profile.selected.arcana = arcanaId
	SaveService.markDirty(player)

	local run: Runs.Run = {
		id = Runs.newId(),
		player = player,
		classId = classId,
		class = class,
		stageId = stageId,
		stage = stage,
		arcanaId = arcanaId,
		arcana = arcana,
		adventureId = adventureId,
		chapterIndex = chapterIndex,
		mods = mods,
		duration = duration or stage.duration,
		unlocked = snapshotUnlocks(profile),
		time = 0,
		minute = 0,
		paused = false,
		pauses = {},
		ending = false,
		completed = false,
		reaperSpawned = false,
		slot = 0,
		floorY = 0,
		floor = nil,
		root = nil,
		rootPos = Vector3.zero,
		facing = Vector3.new(0, 0, -1),
		hp = 0,
		maxHp = 0,
		revivals = 0,
		revivalGranted = 0,
		invulnUntil = 0,
		frozenUntil = 0,
		level = 1,
		xp = 0,
		pendingLevels = 0,
		offering = nil,
		rerolls = 0,
		skips = 0,
		weapons = {},
		passives = {},
		evolvedFrom = {},
		bonus = {},
		stats = {},
		kills = 0,
		gold = 0,
		chests = 0,
		bossKills = 0,
		newAchievements = {},
		data = {},
		lastSync = 0,
	}
	Stats.setupRun(run, profile.powerUps)
	Stats.recompute(run)
	run.hp = run.maxHp
	Loadout.addWeapon(run, class.weapon)

	Arena.setup(run)
	Runs.add(run)
	StageService.start(run)

	local spawnAt = Arena.spawnCFrame(run)
	char:PivotTo(spawnAt)
	run.rootPos = spawnAt.Position
	hum.WalkSpeed = Config.Run.BasePlayerSpeed * run.stats.moveSpeed

	runState:FireClient(player, { active = true, floorY = run.floorY, stage = stageId, class = classId })
	Events.emit("RunStarted", run)
	Analytics.runStarted(player, stageId, classId)
	return true, nil
end

local function slotList(slots: { any }): { any }
	local out = {}
	for _, slot in slots do
		table.insert(out, { id = slot.id, level = slot.level })
	end
	return out
end

local function sendSync(run: Runs.Run)
	runSync:FireClient(run.player, {
		t = run.time,
		duration = run.duration,
		level = run.level,
		xp = run.xp,
		need = Content.xpForLevel(run.level),
		hp = run.hp,
		maxHp = run.maxHp,
		kills = run.kills,
		gold = math.floor(run.gold),
		revivals = run.revivals,
		rerolls = run.rerolls,
		skips = run.skips,
		frozen = os.clock() < run.frozenUntil,
		weapons = slotList(run.weapons),
		passives = slotList(run.passives),
	})
end

-- Fecha a run de verdade (chamado adiado pelo endRun, ou direto quando o jogador sai).
local function finish(run: Runs.Run, leaving: boolean)
	if run.data.finished then
		return
	end
	run.data.finished = true
	local player = run.player
	local reason: string = run.data.endReason or "death"
	if run.completed and reason == "death" then
		reason = "completed" -- chegou ate a Ceifadora: estagio completo
	end

	local gold = math.floor(run.gold)
	local profile = SaveService.peek(player)
	if profile then
		profile.gold += gold
		SaveService.markDirty(player)
	end

	local results = {
		reason = reason,
		time = math.floor(run.time),
		level = run.level,
		kills = run.kills,
		gold = gold,
		stage = run.stageId,
		class = run.classId,
		arcana = run.arcanaId,
		weapons = slotList(run.weapons),
		passives = slotList(run.passives),
		achievements = run.newAchievements, -- conquistas da run (RunEnded ainda pode somar)
		adventure = run.adventureId,
		chapter = run.chapterIndex,
		completed = run.completed,
		chapterDone = false,
	}
	Events.emit("RunEnded", run, reason, results)
	results.chapterDone = run.data.chapterDone == true

	StageService.clear(run)
	EnemyService.clear(run)
	WeaponService.clear(run)
	XpService.clear(run)
	PickupService.clear(run)
	Arena.release(run)
	Runs.remove(player)
	Analytics.runEnded(player, reason, run.time, run.level, run.kills)

	if leaving then
		return
	end
	runState:FireClient(player, { active = false })
	runResults:FireClient(player, results)
	local hum = humanoidOf(player)
	local char = player.Character
	if hum and char and hum.Health > 0 then
		char:PivotTo(lobbyCFrame())
		resetLobbyHumanoid(player)
	end
end

-- Encerra a run. A limpeza roda adiada (fim do frame), para nenhum servico no
-- meio do loop mexer numa run ja desmontada.
function RunManager.endRun(run: Runs.Run, reason: string)
	if run.ending then
		return
	end
	run.ending = true
	run.data.endReason = reason
	if reason == "death" then
		local hum = humanoidOf(run.player)
		if hum and hum.Health > 0 then
			hum.Health = 0 -- cai de verdade; renasce no lobby pelo handler de Died
		end
	end
	task.defer(finish, run, false)
end

function RunManager.update(dt: number)
	for player, run in Runs.all() do
		if run.ending then
			continue
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			continue
		end
		run.root = root
		run.rootPos = root.Position
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.1 then
			run.facing = flat.Unit
		end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			local speed = if run.paused then 0 else Config.Run.BasePlayerSpeed * run.stats.moveSpeed
			if hum.WalkSpeed ~= speed then
				hum.WalkSpeed = speed
			end
		end

		ChestService.update(run)
		if not run.paused then
			run.time += dt
			StageService.update(run, dt)
			EnemyService.update(run, dt)
			if not run.ending then
				WeaponService.update(run, dt)
				XpService.update(run, dt)
				PickupService.update(run, dt)
			end
		end
		if run.ending then
			continue
		end
		PlayerHealth.update(run, dt)
		Arena.update(run)
		if os.clock() - run.lastSync >= Config.Run.SyncInterval then
			run.lastSync = os.clock()
			sendSync(run)
		end
	end
end

local function hookCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum or not hum:IsA("Humanoid") then
		return
	end
	hum.WalkSpeed = Config.Lobby.WalkSpeed
	hum.Died:Connect(function()
		local run = Runs.get(player)
		if run and not run.ending then
			RunManager.endRun(run, "death")
		end
		task.delay(Config.Run.RespawnDelay, function()
			if player.Parent and player.Character == char then
				player:LoadCharacter()
			end
		end)
	end)
end

-- Chamado pelo Main no join (antes do perfil terminar de carregar).
function RunManager.onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char)
		hookCharacter(player, char)
	end)
	if player.Character then
		task.spawn(hookCharacter, player, player.Character)
	else
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end

-- Chamado pelo Main ANTES de salvar o perfil de quem esta saindo: guarda o ouro da run.
function RunManager.onPlayerRemoving(player: Player)
	local run = Runs.get(player)
	if run then
		run.ending = true
		if not run.data.endReason then
			run.data.endReason = "quit"
		end
		finish(run, true)
	end
end

-- Servidor fechando: fecha todas as runs (o Main salva depois).
function RunManager.endAll()
	local list = {}
	for _, run in Runs.all() do
		table.insert(list, run)
	end
	for _, run in list do
		run.ending = true
		if not run.data.endReason then
			run.data.endReason = "quit"
		end
		finish(run, true)
	end
end

function RunManager.init()
	Players.CharacterAutoLoads = false -- o spawn e controlado aqui (lobby <-> arena)

	Events.on("PlayerDowned", function(run: Runs.Run)
		RunManager.endRun(run, "death")
	end)

	requestStartRun.OnServerEvent:Connect(function(player, req)
		if not RateLimit.allow(player, "startRun", 1) then
			return
		end
		local ok, err = RunManager.start(player, req)
		if not ok and err then
			notice:FireClient(player, err)
		end
	end)

	quitRun.OnServerEvent:Connect(function(player)
		if not RateLimit.allow(player, "quitRun", 1) then
			return
		end
		local run = Runs.get(player)
		if run and not run.ending then
			RunManager.endRun(run, "abandon")
		end
	end)
end

return RunManager
