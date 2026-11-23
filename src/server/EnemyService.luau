--!strict
-- Inimigos por run. Tipos em Config/Enemies; visual em EnemyModels (sem animacao).
-- Movimento sem pathfinding (regra do projeto), num loop central:
--   chase  -> reto ate o jogador          bob    -> chase flutuando (cabecas, morcegos)
--   wave   -> chase serpenteando          rush   -> linha reta fixa (revoada), some depois
--   static -> parado (muro de flores, tochas)
-- Contato fere o jogador (PlayerHealth). Dano empurra (kbResist). Relogio congela.
-- Uma grade espacial por run deixa as armas acharem alvos sem varrer todos.
-- Modelos reaproveitados em pool por tipo (regra do projeto: object pooling).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local PlayerHealth = require(script.Parent.PlayerHealth)
local EnemyModels = require(script.Parent.EnemyModels)

local EnemyService = {}

export type Enemy = {
	def: any,
	run: Runs.Run,
	model: Model,
	root: BasePart,
	pos: Vector3, -- posicao no chao (Y = floorY)
	look: Vector3, -- para onde olha (plano XZ)
	hp: number,
	maxHp: number,
	speed: number,
	damage: number,
	radius: number,
	height: number, -- altura do centro do Root acima do chao
	tier: string,
	phase: number,
	born: number, -- run.time do spawn
	dir: Vector3?, -- direcao fixa (rush)
	lastHit: number,
	flashUntil: number,
	kb: Vector3, -- empurrao pendente (studs/s, decai rapido)
	hitCd: { [any]: number }, -- cooldown de acerto por fonte (grimorio, pocas)
	alive: boolean,
}

type RunEnemies = {
	set: { [Enemy]: boolean },
	count: number,
	normalCount: number,
	byId: { [string]: number },
	grid: { [number]: { Enemy } },
}

local CELL = 8 -- tamanho da celula da grade (studs)
local KB_SPEED = 25 -- empurrao base (studs/s)
local FLASH_TIME = 0.08
local FLASH_COLOR = Color3.fromRGB(255, 255, 255)

local enemiesFolder: Folder
local pools: { [string]: { Model } } = {}

local function state(run: Runs.Run): RunEnemies
	local s = run.data.enemies
	if not s then
		s = { set = {}, count = 0, normalCount = 0, byId = {}, grid = {} }
		run.data.enemies = s
	end
	return s
end

local function cellKey(cx: number, cz: number): number
	return (cx + 50000) * 100000 + (cz + 50000)
end

local function acquire(def: any): (Model, number)
	local template, height = EnemyModels.template(def)
	local pool = pools[def.id]
	local model = pool and table.remove(pool)
	if not model then
		model = template:Clone()
	end
	return model :: Model, height
end

local function release(enemy: Enemy)
	local model = enemy.model
	model.Parent = nil
	enemy.root.Color = enemy.def.color
	local pool = pools[enemy.def.id]
	if not pool then
		pool = {}
		pools[enemy.def.id] = pool
	end
	table.insert(pool, model)
end

-- Ponto no anel em volta de `center` (plano XZ).
function EnemyService.ringPoint(center: Vector3, radius: number, angle: number?): Vector3
	local a = angle or math.random() * math.pi * 2
	return Vector3.new(center.X + math.cos(a) * radius, 0, center.Z + math.sin(a) * radius)
end

-- Cria um inimigo do tipo `defId` em `pos` (so X/Z importam).
-- opts: hpMult, speedMult, dir (rush). Respeita os tetos de inimigos.
function EnemyService.spawn(run: Runs.Run, defId: string, pos: Vector3, opts: any?): Enemy?
	local def = Content.enemies[defId]
	if not def or run.ending then
		return nil
	end
	local s = state(run)
	local tier = def.tier or "normal"
	if tier == "normal" and s.normalCount >= Config.Run.MaxEnemies then
		return nil
	end
	if s.count >= Config.Run.HardCapEnemies and tier ~= "boss" and defId ~= "reaper" then
		return nil
	end
	local model, height = acquire(def)
	local root = model.PrimaryPart :: BasePart
	local hpMult = (opts and opts.hpMult) or 1
	local speedMult = (opts and opts.speedMult) or 1
	local hp = math.max(1, def.hp * hpMult)
	local enemy: Enemy = {
		def = def,
		run = run,
		model = model,
		root = root,
		pos = Vector3.new(pos.X, run.floorY, pos.Z),
		look = Vector3.new(0, 0, -1),
		hp = hp,
		maxHp = hp,
		speed = def.speed * speedMult,
		damage = def.damage,
		radius = (def.radius or 1) * (def.scale or 1),
		height = height,
		tier = tier,
		phase = math.random() * math.pi * 2,
		born = run.time,
		dir = opts and opts.dir,
		lastHit = 0,
		flashUntil = 0,
		kb = Vector3.zero,
		hitCd = {},
		alive = true,
	}
	root.CFrame = CFrame.new(enemy.pos.X, run.floorY + height, enemy.pos.Z)
	model.Parent = enemiesFolder
	s.set[enemy] = true
	s.count += 1
	s.byId[defId] = (s.byId[defId] or 0) + 1
	if tier == "normal" then
		s.normalCount += 1
	end
	return enemy
end

local function remove(enemy: Enemy)
	local s = state(enemy.run)
	if not s.set[enemy] then
		return
	end
	enemy.alive = false
	s.set[enemy] = nil
	s.count -= 1
	s.byId[enemy.def.id] = math.max(0, (s.byId[enemy.def.id] or 1) - 1)
	if enemy.tier == "normal" then
		s.normalCount -= 1
	end
	release(enemy)
end

-- Mata o inimigo. credit = conta abate e solta gema/itens (via evento EnemyKilled).
function EnemyService.kill(enemy: Enemy, credit: boolean)
	if not enemy.alive then
		return
	end
	local run = enemy.run
	remove(enemy)
	if credit then
		if enemy.tier ~= "special" then
			run.kills += 1
		end
		if enemy.tier == "boss" then
			run.bossKills += 1
		end
		Events.emit("EnemyKilled", run, enemy)
	end
end

-- Aplica dano. opts: kb (forca do empurrao), from (de onde veio o golpe).
-- Devolve true se matou.
function EnemyService.damage(enemy: Enemy, amount: number, opts: any?): boolean
	if not enemy.alive then
		return false
	end
	enemy.hp -= amount
	if enemy.hp <= 0 then
		EnemyService.kill(enemy, true)
		return true
	end
	enemy.flashUntil = os.clock() + FLASH_TIME
	enemy.root.Color = FLASH_COLOR
	local kb = opts and opts.kb
	local resist = enemy.def.kbResist or 0
	if kb and kb > 0 and resist < 1 then
		local from: Vector3 = (opts and opts.from) or enemy.run.rootPos
		local away = Vector3.new(enemy.pos.X - from.X, 0, enemy.pos.Z - from.Z)
		if away.Magnitude > 0.01 then
			enemy.kb = away.Unit * kb * KB_SPEED * (1 - resist)
		end
	end
	return false
end

-- Chama fn(enemy) para cada inimigo vivo encostando no circulo (pos, radius).
function EnemyService.forEachInRadius(run: Runs.Run, pos: Vector3, radius: number, fn: (Enemy) -> ())
	local s = run.data.enemies :: RunEnemies?
	if not s then
		return
	end
	local reach = radius + 3 -- folga para o raio do proprio inimigo
	local x0, x1 = math.floor((pos.X - reach) / CELL), math.floor((pos.X + reach) / CELL)
	local z0, z1 = math.floor((pos.Z - reach) / CELL), math.floor((pos.Z + reach) / CELL)
	for cx = x0, x1 do
		for cz = z0, z1 do
			local cell = s.grid[cellKey(cx, cz)]
			if cell then
				for _, enemy in cell do
					if enemy.alive then
						local dx, dz = enemy.pos.X - pos.X, enemy.pos.Z - pos.Z
						local r = radius + enemy.radius
						if dx * dx + dz * dz <= r * r then
							fn(enemy)
						end
					end
				end
			end
		end
	end
end

-- Inimigo vivo mais proximo (ignora tochas). nil se ninguem no alcance.
function EnemyService.nearest(run: Runs.Run, pos: Vector3, range: number, skip: { [Enemy]: boolean }?): Enemy?
	local s = run.data.enemies :: RunEnemies?
	if not s then
		return nil
	end
	local best: Enemy? = nil
	local bestD = range * range
	for enemy in s.set do
		if enemy.def.targetable ~= false and not (skip and skip[enemy]) then
			local dx, dz = enemy.pos.X - pos.X, enemy.pos.Z - pos.Z
			local d = dx * dx + dz * dz
			if d <= bestD then
				best = enemy
				bestD = d
			end
		end
	end
	return best
end

-- Ate `count` inimigos sorteados dentro do alcance (para raios).
function EnemyService.randomInRange(run: Runs.Run, pos: Vector3, range: number, count: number): { Enemy }
	local s = run.data.enemies :: RunEnemies?
	local found: { Enemy } = {}
	if not s then
		return found
	end
	local r2 = range * range
	for enemy in s.set do
		if enemy.def.targetable ~= false then
			local dx, dz = enemy.pos.X - pos.X, enemy.pos.Z - pos.Z
			if dx * dx + dz * dz <= r2 then
				table.insert(found, enemy)
			end
		end
	end
	for i = #found, 2, -1 do
		local j = math.random(i)
		found[i], found[j] = found[j], found[i]
	end
	for i = #found, count + 1, -1 do
		found[i] = nil
	end
	return found
end

function EnemyService.countOf(run: Runs.Run, defId: string): number
	local s = run.data.enemies :: RunEnemies?
	return if s then s.byId[defId] or 0 else 0
end

-- Rosario: mata todo inimigo comum e de evento (com credito: solta gema).
function EnemyService.killCommon(run: Runs.Run)
	local s = run.data.enemies :: RunEnemies?
	if not s then
		return
	end
	local list = {}
	for enemy in s.set do
		if enemy.tier == "normal" or enemy.tier == "event" then
			table.insert(list, enemy)
		end
	end
	for _, enemy in list do
		EnemyService.kill(enemy, true)
	end
end

-- Some com todos os inimigos da run, sem credito (chegada da Ceifadora, fim da run).
function EnemyService.wipe(run: Runs.Run, keep: string?)
	local s = run.data.enemies :: RunEnemies?
	if not s then
		return
	end
	local list = {}
	for enemy in s.set do
		if enemy.def.id ~= keep then
			table.insert(list, enemy)
		end
	end
	for _, enemy in list do
		remove(enemy)
	end
end

-- Empurra para longe tudo perto do jogador (ao ressuscitar). Adiado: a
-- ressurreicao acontece dentro do update (grade meio reconstruida), entao
-- varre s.set direto e espera o fim do frame.
local function blast(run: Runs.Run)
	task.defer(function()
		local s = run.data.enemies :: RunEnemies?
		if not s or run.ending then
			return
		end
		for enemy in s.set do
			if enemy.alive then
				local dx, dz = enemy.pos.X - run.rootPos.X, enemy.pos.Z - run.rootPos.Z
				if dx * dx + dz * dz <= 18 * 18 then
					EnemyService.damage(enemy, 0, { kb = 3, from = run.rootPos })
				end
			end
		end
	end)
end

function EnemyService.update(run: Runs.Run, dt: number)
	local s = run.data.enemies :: RunEnemies?
	if not s then
		return
	end
	local target = run.rootPos
	local now = os.clock()
	local t = run.time
	local frozen = t < run.frozenUntil -- Relogio conta no tempo da run (para na pausa)
	local contactCd = Config.Run.ContactCooldown
	local playerRadius = Config.Run.PlayerRadius
	local relocate = Config.Run.RelocateDistance
	local grid = s.grid
	table.clear(grid)

	local expired: { Enemy } = {}
	for enemy in s.set do
		local def = enemy.def
		if def.lifetime and t - enemy.born >= def.lifetime then
			table.insert(expired, enemy)
			continue
		end
		local pos = enemy.pos
		local move = def.move
		if move == "static" then
			-- parado e muito longe (tocha, flor que ficou para tras): some, libera a cota
			local fx, fz = pos.X - target.X, pos.Z - target.Z
			local far = relocate * 1.5
			if fx * fx + fz * fz > far * far then
				table.insert(expired, enemy)
				continue
			end
		end
		if not frozen then
			if move == "rush" then
				local dir = enemy.dir or enemy.look
				pos += dir * enemy.speed * dt
				enemy.look = dir
			elseif move ~= "static" then
				local to = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
				local dist = to.Magnitude
				if dist > 0.05 then
					local dir = to / dist
					enemy.look = dir
					if move == "wave" then
						local side = Vector3.new(-dir.Z, 0, dir.X)
						dir = (dir + side * math.sin(t * (def.bobFreq or 3) + enemy.phase) * 0.8).Unit
					end
					pos += dir * math.min(enemy.speed * dt, dist)
				end
			end
			if enemy.kb.Magnitude > 0.05 then
				pos += enemy.kb * dt
				enemy.kb *= math.max(0, 1 - 10 * dt)
			end
			-- comum/chefe que ficou muito para tras reaparece no anel (o jogador correu dele)
			if enemy.tier == "normal" or enemy.tier == "boss" then
				local fx, fz = pos.X - target.X, pos.Z - target.Z
				local limit = if enemy.tier == "normal" then relocate else relocate * 1.5
				if fx * fx + fz * fz > limit * limit then
					local p = EnemyService.ringPoint(target, Config.Run.SpawnRadius)
					pos = Vector3.new(p.X, pos.Y, p.Z)
				end
			end
			enemy.pos = pos
		end

		-- visual: altura (+ flutuar), olhando para onde anda
		local y = run.floorY + enemy.height
		if def.bobAmp then
			y += math.sin(t * (def.bobFreq or 2) + enemy.phase) * def.bobAmp
		end
		local here = Vector3.new(pos.X, y, pos.Z)
		enemy.root.CFrame = CFrame.lookAt(here, here + enemy.look)
		if enemy.flashUntil > 0 and now >= enemy.flashUntil then
			enemy.flashUntil = 0
			enemy.root.Color = def.color
		end

		-- contato com o jogador
		if not frozen and enemy.damage > 0 then
			local dx, dz = pos.X - target.X, pos.Z - target.Z
			local r = enemy.radius + playerRadius
			if dx * dx + dz * dz <= r * r and now - enemy.lastHit >= contactCd then
				enemy.lastHit = now
				PlayerHealth.damage(run, enemy.damage)
				if run.ending then
					return
				end
			end
		end

		-- grade espacial (para as armas)
		local key = cellKey(math.floor(pos.X / CELL), math.floor(pos.Z / CELL))
		local cell = grid[key]
		if not cell then
			cell = {}
			grid[key] = cell
		end
		table.insert(cell, enemy)
	end

	for _, enemy in expired do
		remove(enemy)
	end
end

function EnemyService.clear(run: Runs.Run)
	EnemyService.wipe(run)
	run.data.enemies = nil
end

function EnemyService.init()
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = workspace
	Events.on("PlayerRevived", blast)
end

return EnemyService
