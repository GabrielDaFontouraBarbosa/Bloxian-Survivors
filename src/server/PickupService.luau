--!strict
-- Itens de chao por run (Config/Pickups): o jogador pega encostando.
--   ouro (x Ganancia), coxa assada (cura), rosario (limpa a tela), vacuo (puxa
--   todo o XP), relogio (congela inimigos), bau (ChestService).
-- Quem solta: tocha quebrada (tabela de drop com Sorte), chefe (bau) e, raramente,
-- inimigo comum (moeda). Visual simples, girando, reaproveitado em pool.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local EnemyService = require(script.Parent.EnemyService)
local XpService = require(script.Parent.XpService)
local PlayerHealth = require(script.Parent.PlayerHealth)
local ChestService = require(script.Parent.ChestService)

local PickupService = {}

type Pickup = { def: any, part: BasePart, pos: Vector3, spin: number }

local folder: Folder
local pools: { [string]: { BasePart } } = {}

local function makeVisual(def: any): BasePart
	local p = Instance.new("Part")
	p.Name = def.id
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Color = def.color
	p.Material = Enum.Material.SmoothPlastic
	local shape = def.shape
	if shape == "coin" then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.25, 1.1, 1.1)
		p.Material = Enum.Material.Neon
	elseif shape == "bag" then
		p.Size = Vector3.new(1.3, 1.3, 1.3)
		p.Material = Enum.Material.Neon
	elseif shape == "chicken" then
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * 1.4
	elseif shape == "cross" then
		p.Size = Vector3.new(0.35, 1.8, 0.35)
		p.Material = Enum.Material.Neon
		local arm = Instance.new("Part")
		arm.Size = Vector3.new(1.1, 0.35, 0.35)
		arm.Color = def.color
		arm.Material = Enum.Material.Neon
		arm.Anchored = false
		arm.Massless = true
		arm.CanCollide = false
		arm.CanTouch = false
		arm.CanQuery = false
		arm.CFrame = p.CFrame * CFrame.new(0, 0.35, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = arm
		weld.Parent = arm
		arm.Parent = p
	elseif shape == "orb" then
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * 1.3
		p.Material = Enum.Material.Neon
	elseif shape == "clock" then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.4, 1.4, 1.4)
		p.Material = Enum.Material.Neon
	elseif shape == "chest" then
		p.Size = Vector3.new(2.2, 1.5, 1.5)
		local band = Instance.new("Part")
		band.Size = Vector3.new(2.25, 0.3, 1.55)
		band.Color = Color3.fromRGB(255, 205, 60)
		band.Material = Enum.Material.Neon
		band.Anchored = false
		band.Massless = true
		band.CanCollide = false
		band.CanTouch = false
		band.CanQuery = false
		band.CFrame = p.CFrame * CFrame.new(0, 0.25, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = band
		weld.Parent = band
		band.Parent = p
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 210, 90)
		light.Range = 12
		light.Brightness = 2
		light.Parent = p
	end
	return p
end

local function listOf(run: Runs.Run): { Pickup }
	local list = run.data.pickups
	if not list then
		list = {}
		run.data.pickups = list
	end
	return list
end

local function releasePart(def: any, part: BasePart)
	part.Parent = nil
	local pool = pools[def.id]
	if not pool then
		pool = {}
		pools[def.id] = pool
	end
	table.insert(pool, part)
end

local function removeAt(list: { Pickup }, index: number)
	local item = list[index]
	releasePart(item.def, item.part)
	local last = #list
	list[index] = list[last]
	list[last] = nil
end

function PickupService.spawn(run: Runs.Run, id: string, pos: Vector3)
	local def = Content.pickups[id]
	if not def or run.ending then
		return
	end
	local list = listOf(run)
	if #list >= Config.Run.MaxPickups then
		-- o mais velho some (nunca um bau). table.remove preserva a ordem de idade;
		-- o removeAt do loop de coleta pode trocar com o ultimo, por isso nao serve aqui.
		for i = 1, #list do
			if list[i].def.effect ~= "chest" then
				releasePart(list[i].def, list[i].part)
				table.remove(list, i)
				break
			end
		end
	end
	local pool = pools[id]
	local part = (pool and table.remove(pool)) or makeVisual(def)
	local ground = Vector3.new(pos.X, run.floorY + 1.2, pos.Z)
	part.CFrame = CFrame.new(ground)
	part.Parent = folder
	table.insert(list, { def = def, part = part, pos = ground, spin = math.random() * math.pi * 2 })
end

local function collect(run: Runs.Run, def: any)
	local effect = def.effect
	if effect == "gold" then
		run.gold += (def.value or 0) * run.stats.greed
	elseif effect == "heal" then
		PlayerHealth.heal(run, def.value or 0)
	elseif effect == "rosary" then
		EnemyService.killCommon(run)
	elseif effect == "vacuum" then
		XpService.vacuum(run)
	elseif effect == "freeze" then
		run.frozenUntil = run.time + Config.Run.FreezeDuration
	elseif effect == "chest" then
		ChestService.open(run)
	end
	Events.emit("PickupCollected", run, def.id)
end

function PickupService.update(run: Runs.Run, dt: number)
	local list = run.data.pickups
	if not list then
		return
	end
	local target = run.rootPos
	local r = Config.Run.PickupRadius
	for i = #list, 1, -1 do
		local item = list[i]
		local dx, dz = item.pos.X - target.X, item.pos.Z - target.Z
		if dx * dx + dz * dz <= r * r then
			local def = item.def
			removeAt(list, i)
			collect(run, def)
			if run.ending or run.paused then
				return -- bau pausou a run: o resto fica para depois
			end
		else
			item.spin += dt * 2
			item.part.CFrame = CFrame.new(item.pos) * CFrame.Angles(0, item.spin, 0)
		end
	end
end

-- Sorteia o drop de uma tabela (Config.Pickups.drops). A Sorte pesa os raros.
local function rollDrop(tableId: string, luck: number): string?
	local entries = Config.Pickups.drops[tableId]
	if not entries then
		return nil
	end
	local total = 0
	for _, e in entries do
		total += e.weight * (if e.rare then luck else 1)
	end
	local roll = math.random() * total
	for _, e in entries do
		roll -= e.weight * (if e.rare then luck else 1)
		if roll <= 0 then
			return e.id
		end
	end
	return entries[#entries].id
end

function PickupService.clear(run: Runs.Run)
	local list = run.data.pickups
	if list then
		for _, item in list do
			releasePart(item.def, item.part)
		end
		run.data.pickups = nil
	end
end

function PickupService.init()
	folder = Instance.new("Folder")
	folder.Name = "Pickups"
	folder.Parent = workspace

	Events.on("EnemyKilled", function(run: Runs.Run, enemy: any)
		local def = enemy.def
		if def.chest then
			PickupService.spawn(run, "chest", enemy.pos)
		elseif def.drops then
			local id = rollDrop(def.drops, run.stats.luck)
			if id then
				PickupService.spawn(run, id, enemy.pos)
			end
		elseif enemy.tier == "normal" and math.random() < Config.Run.EnemyCoinChance * run.stats.luck then
			PickupService.spawn(run, "coin", enemy.pos)
		end
	end)
end

return PickupService
