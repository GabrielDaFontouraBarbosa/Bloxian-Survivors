--!strict
-- Inimigos: pool de parts, spawn em volta do jogador, perseguicao em linha reta
-- (sem Pathfinding) e dano por contato. Tudo decidido no servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerUtil = require(ReplicatedStorage.Shared.PlayerUtil)
local XpService = require(script.Parent.XpService)

local EnemyService = {}

type EnemyData = {
	part: Part,
	health: number,
	lastHit: number, -- os.clock do ultimo dano causado no jogador
}

local enemiesFolder: Folder
local pool: { Part } = {}
local active: { [Part]: EnemyData } = {}
local activeCount = 0
local spawnAccumulator = 0

local function makePart(): Part
	local p = Instance.new("Part")
	p.Name = "Enemy"
	p.Size = Config.Enemy.Size
	p.Color = Config.Enemy.Color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true -- movido via CFrame no loop central (sem fisica)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true -- precisa ser clicavel para o debug kill
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

function EnemyService.spawnAround(root: BasePart)
	if activeCount >= Config.Enemy.MaxAlive then
		return
	end
	local part = table.remove(pool)
	if not part then
		return -- pool esgotado; teto efetivo = PoolSize
	end
	local angle = math.random() * math.pi * 2
	local r = Config.Enemy.SpawnRadius
	local base = root.Position
	part.Position = Vector3.new(base.X + math.cos(angle) * r, base.Y, base.Z + math.sin(angle) * r)
	part.Parent = enemiesFolder
	active[part] = { part = part, health = Config.Enemy.Health, lastHit = 0 }
	activeCount += 1
end

-- true se o instance for um inimigo vivo (usado para validar o clique do cliente).
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
	XpService.dropGem(pos)
end

-- Aplica dano; mata e solta XP se a vida zerar. Reaproveitado pela arma no passo 3.
function EnemyService.damage(part: Part, amount: number)
	local data = active[part]
	if not data then
		return
	end
	data.health -= amount
	if data.health <= 0 then
		EnemyService.kill(part)
	end
end

-- Loop central: spawn por tempo + mover todos + dano por contato.
function EnemyService.update(dt: number)
	spawnAccumulator += dt
	while spawnAccumulator >= Config.Enemy.SpawnInterval do
		spawnAccumulator -= Config.Enemy.SpawnInterval
		local player = PlayerUtil.randomPlayerWithChar()
		local char = player and player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			EnemyService.spawnAround(root)
		end
	end

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
			local step = math.min(Config.Enemy.Speed * dt, dist)
			local dir = flat / dist
			local newPos = part.Position + dir * step
			-- mantem o inimigo no mesmo nivel do jogador
			part.Position = Vector3.new(newPos.X, targetRoot.Position.Y, newPos.Z)
		end

		if (targetRoot.Position - part.Position).Magnitude <= Config.Enemy.ContactRange then
			if now - data.lastHit >= Config.Enemy.ContactCooldown then
				data.lastHit = now
				local character = targetRoot.Parent
				local hum = character and character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(Config.Enemy.ContactDamage)
				end
			end
		end
	end
end

return EnemyService
