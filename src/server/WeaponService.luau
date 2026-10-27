--!strict
-- Arma automatica: por jogador, a cada FireInterval mira no inimigo vivo mais
-- proximo (dentro do alcance) e dispara um projetil que persegue o alvo.
-- Projeteis usam pool. Tudo decidido no servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EnemyService = require(script.Parent.EnemyService)
local Analytics = require(script.Parent.Analytics)

local WeaponService = {}

type Projectile = {
	part: Part,
	target: Part,
	owner: Player,
	bornAt: number,
}

local projFolder: Folder
local pool: { Part } = {}
local active: { Projectile } = {}
local fireAccum: { [Player]: number } = {}

local function makeProjectile(): Part
	local p = Instance.new("Part")
	p.Name = "Projectile"
	p.Shape = Enum.PartType.Ball
	p.Size = Config.Weapon.ProjectileSize
	p.Color = Config.Weapon.ProjectileColor
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

function WeaponService.init()
	projFolder = Instance.new("Folder")
	projFolder.Name = "Projectiles"
	projFolder.Parent = workspace
	for _ = 1, Config.Weapon.PoolSize do
		table.insert(pool, makeProjectile())
	end
	Players.PlayerRemoving:Connect(function(player)
		fireAccum[player] = nil
	end)
end

local function fire(root: BasePart, owner: Player)
	local target = EnemyService.nearestEnemy(root.Position, Config.Weapon.Range)
	if not target then
		return -- nada no alcance
	end
	local part = table.remove(pool)
	if not part then
		return -- sem projetil livre
	end
	part.Position = root.Position
	part.Parent = projFolder
	table.insert(active, { part = part, target = target, owner = owner, bornAt = os.clock() })
end

local function recycle(index: number)
	local pr = active[index]
	pr.part.Parent = nil
	local last = #active
	active[index] = active[last]
	active[last] = nil
	table.insert(pool, pr.part)
end

function WeaponService.update(dt: number)
	-- disparo por jogador
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			fireAccum[player] = (fireAccum[player] or 0) + dt
			if fireAccum[player] >= Config.Weapon.FireInterval then
				fireAccum[player] -= Config.Weapon.FireInterval
				fire(root, player)
			end
		end
	end

	-- move projeteis e aplica acerto
	local now = os.clock()
	for i = #active, 1, -1 do
		local pr = active[i]
		if now - pr.bornAt >= Config.Weapon.Lifetime or not EnemyService.isActive(pr.target) then
			recycle(i)
			continue
		end
		local to = pr.target.Position - pr.part.Position
		local dist = to.Magnitude
		if dist <= Config.Weapon.HitRadius then
			local killed = EnemyService.damage(pr.target, Config.Weapon.Damage)
			if killed then
				Analytics.firstEnemyKill(pr.owner)
			end
			recycle(i)
		else
			local step = math.min(Config.Weapon.ProjectileSpeed * dt, dist)
			pr.part.Position = pr.part.Position + (to / dist) * step
		end
	end
end

return WeaponService
