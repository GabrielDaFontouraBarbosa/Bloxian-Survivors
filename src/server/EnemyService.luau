--!strict
-- Inimigos: pool de parts, perseguicao em linha reta (sem Pathfinding) e dano
-- por contato. Cada inimigo carrega seus proprios stats, entao o mesmo pool
-- serve para inimigo comum e chefe. O spawn e comandado pelo WaveService.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerUtil = require(ReplicatedStorage.Shared.PlayerUtil)
local XpService = require(script.Parent.XpService)

local EnemyService = {}

-- Stats de um inimigo no momento do spawn (montados pelo WaveService).
export type Stats = {
	health: number,
	speed: number,
	contactDamage: number,
	xpReward: number,
	size: Vector3,
	color: Color3,
}

type EnemyData = {
	part: Part,
	health: number,
	speed: number,
	contactDamage: number,
	xpReward: number,
	baseColor: Color3,
	lastHit: number, -- os.clock do ultimo dano causado no jogador
	flashUntil: number, -- os.clock ate quando fica "piscado"
}

local enemiesFolder: Folder
local pool: { Part } = {}
local active: { [Part]: EnemyData } = {}
local activeCount = 0

local function makePart(): Part
	local p = Instance.new("Part")
	p.Name = "Enemy"
	p.Size = Config.Enemy.Size
	p.Color = Config.Enemy.Color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true -- movido via CFrame no loop central (sem fisica)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

function EnemyService.init()
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = workspace
	for _ = 1, Config.Enemy.PoolSize do
		table.insert(pool, makePart())
	end
end

-- Spawna um inimigo com os stats dados, num ponto do anel em volta do root.
function EnemyService.spawn(root: BasePart, stats: Stats)
	if activeCount >= Config.Enemy.MaxAlive then
		return
	end
	local part = table.remove(pool)
	if not part then
		return -- pool esgotado
	end
	local angle = math.random() * math.pi * 2
	local r = Config.Enemy.SpawnRadius
	local base = root.Position
	part.Size = stats.size
	part.Color = stats.color
	part.Position = Vector3.new(base.X + math.cos(angle) * r, base.Y, base.Z + math.sin(angle) * r)
	part.Parent = enemiesFolder
	active[part] = {
		part = part,
		health = stats.health,
		speed = stats.speed,
		contactDamage = stats.contactDamage,
		xpReward = stats.xpReward,
		baseColor = stats.color,
		lastHit = 0,
		flashUntil = 0,
	}
	activeCount += 1
end

-- Inimigo vivo mais proximo de uma posicao, dentro de maxRange (nil se nenhum).
function EnemyService.nearestEnemy(pos: Vector3, maxRange: number): Part?
	local best: Part? = nil
	local bestDist = maxRange
	for part in active do
		local d = (part.Position - pos).Magnitude
		if d <= bestDist then
			best = part
			bestDist = d
		end
	end
	return best
end

function EnemyService.isActive(inst: Instance?): boolean
	return typeof(inst) == "Instance" and inst:IsA("Part") and active[inst :: Part] ~= nil
end

function EnemyService.kill(part: Part)
	local data = active[part]
	if not data then
		return
	end
	active[part] = nil
	activeCount -= 1
	local pos = part.Position
	part.Parent = nil
	table.insert(pool, part)
	-- solta as gemas (chefe solta varias, espalhadas)
	for _ = 1, data.xpReward do
		local offset = Vector3.new((math.random() - 0.5) * 6, 0, (math.random() - 0.5) * 6)
		XpService.dropGem(pos + offset)
	end
end

-- Aplica dano; mata e solta XP se a vida zerar. Devolve true se matou.
function EnemyService.damage(part: Part, amount: number): boolean
	local data = active[part]
	if not data then
		return false
	end
	data.health -= amount
	if data.health <= 0 then
		EnemyService.kill(part)
		return true
	end
	data.flashUntil = os.clock() + Config.Enemy.FlashTime
	part.Color = Config.Enemy.FlashColor
	return false
end

-- Loop central: mover todos + dano por contato (o spawn fica no WaveService).
function EnemyService.update(dt: number)
	local now = os.clock()
	for part, data in active do
		local targetRoot = PlayerUtil.nearestRoot(part.Position)
		if not targetRoot then
			continue
		end
		local to = targetRoot.Position - part.Position
		local flat = Vector3.new(to.X, 0, to.Z)
		local dist = flat.Magnitude
		if dist > 0.05 then
			local step = math.min(data.speed * dt, dist)
			local dir = flat / dist
			local newPos = part.Position + dir * step
			part.Position = Vector3.new(newPos.X, targetRoot.Position.Y, newPos.Z)
		end

		if data.flashUntil > 0 and now >= data.flashUntil then
			data.flashUntil = 0
			part.Color = data.baseColor
		end

		if (targetRoot.Position - part.Position).Magnitude <= Config.Enemy.ContactRange then
			if now - data.lastHit >= Config.Enemy.ContactCooldown then
				data.lastHit = now
				local character = targetRoot.Parent
				local hum = character and character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(data.contactDamage)
				end
			end
		end
	end
end

return EnemyService
