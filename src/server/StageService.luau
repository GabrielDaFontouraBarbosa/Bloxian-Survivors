--!strict
-- Roteiro do estagio por run (substitui o antigo WaveService):
--   * segmentos por minuto: quais inimigos, minimo vivo, ritmo e vida (Config/Stages)
--   * eventos com hora marcada: revoada (inimigos rapidos em linha reta),
--     muro de flores (anel em volta do jogador) e chefes (soltam bau)
--   * tochas espalhadas de tempos em tempos (quebram e soltam itens)
--   * no fim do tempo: some tudo e chega a Ceifadora (estagio completo)
-- Maldicao e regras da aventura escalam quantidade, vida e velocidade.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local EnemyService = require(script.Parent.EnemyService)

local StageService = {}

type StageState = {
	nextEvent: number,
	events: { any },
	spawnAcc: number,
	brazierAcc: number,
}

local function stateOf(run: Runs.Run): StageState
	return run.data.stage
end

-- Segmento do minuto atual (o ultimo vale depois que acabam).
local function segmentAt(run: Runs.Run, minute: number): any
	local segments = run.stage.segments
	for _, seg in segments do
		if minute >= seg.from and minute < seg.to then
			return seg
		end
	end
	return segments[#segments]
end

local function curse(run: Runs.Run): number
	return run.stats.curse or 1
end

local function hpMult(run: Runs.Run, seg: any): number
	return (seg and seg.hp or 1) * curse(run) * (run.mods.enemyHp or 1)
end

local function speedMult(run: Runs.Run): number
	return (run.mods.enemySpeed or 1) * (1 + (curse(run) - 1) * 0.5)
end

function StageService.start(run: Runs.Run)
	local events = {}
	for _, ev in run.stage.events do
		if ev.at < run.duration then
			table.insert(events, ev)
		end
	end
	table.sort(events, function(a, b)
		return a.at < b.at
	end)
	run.data.stage = {
		nextEvent = 1,
		events = events,
		spawnAcc = 0,
		brazierAcc = 0,
	} :: StageState
end

-- Revoada: uma coluna de inimigos que nasce de um lado e cruza a tela em linha
-- reta, mirando onde o jogador estava (o "vem rapido na direcao").
local function swarm(run: Runs.Run, ev: any)
	local center = run.rootPos
	local angle = math.random() * math.pi * 2
	local from = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local dir = -from
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local count = math.floor(ev.count * curse(run))
	local opts = { hpMult = curse(run) * (run.mods.enemyHp or 1), speedMult = run.mods.enemySpeed or 1, dir = dir }
	for i = 1, count do
		local lane = ((i - 1) % 6) - 2.5
		local row = math.floor((i - 1) / 6)
		local p = Vector3.new(center.X, 0, center.Z) + from * (Config.Run.SpawnRadius + row * 3) + side * lane * 2.5
		EnemyService.spawn(run, ev.enemy, p, opts)
	end
end

-- Muro: um anel de inimigos parados em volta do jogador.
local function ring(run: Runs.Run, ev: any)
	local center = run.rootPos
	local opts = { hpMult = curse(run) * (run.mods.enemyHp or 1) }
	for i = 1, ev.count do
		local angle = (i / ev.count) * math.pi * 2
		EnemyService.spawn(run, ev.enemy, EnemyService.ringPoint(center, ev.radius or 24, angle), opts)
	end
end

local function boss(run: Runs.Run, ev: any)
	local opts = { hpMult = curse(run) * (run.mods.enemyHp or 1), speedMult = speedMult(run) }
	EnemyService.spawn(run, ev.enemy, EnemyService.ringPoint(run.rootPos, Config.Run.SpawnRadius * 0.8), opts)
end

local function trigger(run: Runs.Run, ev: any)
	if ev.kind == "swarm" then
		swarm(run, ev)
	elseif ev.kind == "ring" then
		ring(run, ev)
	elseif ev.kind == "boss" then
		boss(run, ev)
	end
end

-- Fim do tempo: limpa a tela e solta a Ceifadora. Chegar aqui = estagio completo.
local function reaper(run: Runs.Run)
	run.reaperSpawned = true
	run.completed = true
	EnemyService.wipe(run)
	EnemyService.spawn(run, "reaper", EnemyService.ringPoint(run.rootPos, Config.Run.SpawnRadius * 0.7))
	Events.emit("StageCompleted", run)
end

local function spawnBrazier(run: Runs.Run)
	if EnemyService.countOf(run, "brazier") >= (run.stage.brazierMax or 0) then
		return
	end
	local dist = 25 + math.random() * 20
	EnemyService.spawn(run, "brazier", EnemyService.ringPoint(run.rootPos, dist))
end

function StageService.update(run: Runs.Run, dt: number)
	local st = stateOf(run)
	if not st then
		return
	end

	local minute = math.floor(run.time / 60)
	while run.minute < minute do
		run.minute += 1
		Events.emit("MinuteReached", run, run.minute)
	end

	if not run.reaperSpawned and run.time >= run.duration then
		reaper(run)
		return
	end
	if run.reaperSpawned then
		return -- so a Ceifadora agora
	end

	-- eventos marcados
	local events = st.events
	while st.nextEvent <= #events and run.time >= events[st.nextEvent].at do
		trigger(run, events[st.nextEvent])
		st.nextEvent += 1
	end

	-- inimigos comuns: mantem o minimo do segmento, nascendo no ritmo dele
	local seg = segmentAt(run, minute)
	local spawnMult = curse(run) * (run.mods.spawnMult or 1)
	local minAlive = math.floor(seg.min * spawnMult)
	local interval = seg.interval / spawnMult
	local normals = (run.data.enemies and run.data.enemies.normalCount) or 0
	if normals < minAlive then
		interval *= 0.4 -- abaixo do minimo: repoe rapido
	end
	st.spawnAcc += dt
	local opts = { hpMult = hpMult(run, seg), speedMult = speedMult(run) }
	local guard = 0
	while st.spawnAcc >= interval and guard < 20 do
		st.spawnAcc -= interval
		guard += 1
		local id = seg.enemies[math.random(#seg.enemies)]
		EnemyService.spawn(run, id, EnemyService.ringPoint(run.rootPos, Config.Run.SpawnRadius), opts)
	end
	if guard >= 20 then
		st.spawnAcc = 0 -- nunca acumula uma avalanche depois de um engasgo
	end

	-- tochas
	st.brazierAcc += dt
	if st.brazierAcc >= (run.stage.brazierInterval or 15) then
		st.brazierAcc = 0
		spawnBrazier(run)
	end
end

function StageService.clear(run: Runs.Run)
	run.data.stage = nil
end

return StageService
