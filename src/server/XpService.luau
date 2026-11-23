--!strict
-- Gemas de XP por run + level up estilo VS. Inimigo morre -> gema (cor pelo
-- valor); a gema voa ate o jogador dentro do Ima; XP x Crescimento. Ao subir de
-- nivel a run PAUSA e o jogador escolhe entre 3-4 opcoes (Loadout), podendo
-- rerrolar ou pular se tiver cargas (PowerUps). Tudo validado aqui.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local Stats = require(script.Parent.Stats)
local Loadout = require(script.Parent.Loadout)
local Analytics = require(script.Parent.Analytics)

local XpService = {}

type Gem = { part: Part, value: number, pulled: boolean }

local MAX_GEMS_PER_RUN = 250

local levelUpOffer = Remotes.event("LevelUpOffer")
local chooseUpgrade = Remotes.event("ChooseUpgrade")
local rerollUpgrade = Remotes.event("RerollUpgrade")
local skipUpgrade = Remotes.event("SkipUpgrade")

local gemsFolder: Folder
local gemPool: { Part } = {}

local function makeGem(): Part
	local p = Instance.new("Part")
	p.Name = "XpGem"
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

local function styleGem(gem: Gem)
	local tier = Config.Xp.Tiers[1]
	for _, t in Config.Xp.Tiers do
		if gem.value >= t.min then
			tier = t
		end
	end
	gem.part.Color = tier.color
	gem.part.Size = Vector3.one * tier.size
end

local function gemsOf(run: Runs.Run): { Gem }
	local gems = run.data.gems
	if not gems then
		gems = {}
		run.data.gems = gems
	end
	return gems
end

function XpService.dropGem(run: Runs.Run, pos: Vector3, value: number)
	if value <= 0 then
		return
	end
	local gems = gemsOf(run)
	local part = if #gems < MAX_GEMS_PER_RUN then table.remove(gemPool) else nil
	if not part then
		-- sem gema livre: funde o valor numa gema existente (estilo VS)
		local target = gems[math.random(math.max(1, #gems))]
		if target then
			target.value += value
			styleGem(target)
		end
		return
	end
	local jitter = Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2)
	part.Position = Vector3.new(pos.X, run.floorY + 1.2, pos.Z) + jitter
	part.Parent = gemsFolder
	local gem: Gem = { part = part, value = value, pulled = false }
	styleGem(gem)
	table.insert(gems, gem)
end

-- Vacuo: todas as gemas da run voam ate o jogador.
function XpService.vacuum(run: Runs.Run)
	for _, gem in gemsOf(run) do
		gem.pulled = true
	end
end

-- ===================== level up =====================

local function offer(run: Runs.Run)
	local options = Loadout.options(run)
	run.offering = options
	Runs.setPause(run, "levelup", true)
	levelUpOffer:FireClient(run.player, {
		level = run.level,
		options = options,
		rerolls = run.rerolls,
		skips = run.skips,
	})
end

local function closeOffer(run: Runs.Run)
	run.offering = nil
	run.pendingLevels = math.max(0, run.pendingLevels - 1)
	if run.pendingLevels > 0 then
		offer(run) -- subiu mais de um nivel de uma vez
	else
		Runs.setPause(run, "levelup", false)
		levelUpOffer:FireClient(run.player, nil) -- fecha o painel
	end
end

local function tryLevelUp(run: Runs.Run)
	while run.xp >= Content.xpForLevel(run.level) do
		run.xp -= Content.xpForLevel(run.level)
		run.level += 1
		run.pendingLevels += 1
		Stats.recompute(run) -- traco da classe pode subir com o nivel
		Events.emit("LevelReached", run, run.level)
		Analytics.levelReached(run.player, run.level)
	end
	if run.pendingLevels > 0 and not run.offering and not run.ending then
		offer(run)
	end
end

function XpService.addXp(run: Runs.Run, amount: number)
	run.xp += amount * run.stats.growth
	tryLevelUp(run)
end

-- ===================== loop =====================

local function recycle(gems: { Gem }, index: number)
	local gem = gems[index]
	gem.part.Parent = nil
	table.insert(gemPool, gem.part)
	local last = #gems
	gems[index] = gems[last]
	gems[last] = nil
end

function XpService.update(run: Runs.Run, dt: number)
	local gems = run.data.gems
	if not gems then
		return
	end
	local target = run.rootPos
	local magnet = Config.Run.BaseMagnet * run.stats.magnet
	local collect = Config.Run.CollectRadius
	for i = #gems, 1, -1 do
		local gem = gems[i]
		local pos = gem.part.Position
		local to = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		local dist = to.Magnitude
		if dist <= collect then
			local value = gem.value
			recycle(gems, i)
			XpService.addXp(run, value)
			if run.ending then
				return
			end
		elseif gem.pulled or dist <= magnet then
			gem.pulled = true -- uma vez puxada, vem ate o fim (como no VS)
			local speed = Config.Run.GemSpeed * (if dist > magnet then 2 else 1)
			local step = math.min(speed * dt, dist)
			gem.part.Position = pos + (to / dist) * step
		end
	end
end

function XpService.clear(run: Runs.Run)
	local gems = run.data.gems
	if gems then
		for _, gem in gems do
			gem.part.Parent = nil
			table.insert(gemPool, gem.part)
		end
		run.data.gems = nil
	end
	if run.offering then
		levelUpOffer:FireClient(run.player, nil)
	end
	run.offering = nil
end

function XpService.init()
	gemsFolder = Instance.new("Folder")
	gemsFolder.Name = "XpGems"
	gemsFolder.Parent = workspace
	for _ = 1, Config.Run.GemPoolSize do
		table.insert(gemPool, makeGem())
	end

	Events.on("EnemyKilled", function(run: Runs.Run, enemy: any)
		XpService.dropGem(run, enemy.pos, enemy.def.xp or 0)
	end)

	-- escolha: indice de uma das opcoes oferecidas (nunca o conteudo vindo do cliente)
	chooseUpgrade.OnServerEvent:Connect(function(player, index)
		local run = Runs.get(player)
		if not run or not run.offering or typeof(index) ~= "number" then
			return
		end
		local opt = run.offering[math.floor(index)]
		if not opt then
			return
		end
		Loadout.apply(run, opt)
		Analytics.upgradeChosen(player, run.level, (opt.id or opt.kind) :: string)
		closeOffer(run)
	end)

	rerollUpgrade.OnServerEvent:Connect(function(player)
		local run = Runs.get(player)
		if not run or not run.offering or run.rerolls <= 0 then
			return
		end
		run.rerolls -= 1
		offer(run)
	end)

	skipUpgrade.OnServerEvent:Connect(function(player)
		local run = Runs.get(player)
		if not run or not run.offering or run.skips <= 0 then
			return
		end
		run.skips -= 1
		closeOffer(run)
	end)
end

return XpService
