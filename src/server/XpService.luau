--!strict
-- Gemas de XP + progressao de nivel. Inimigos soltam gemas; elas voam ate o
-- jogador, somam XP e, ao cruzar o limite, sobem o nivel e oferecem 3 upgrades.
-- Tudo no servidor; o cliente so escolhe (e e validado aqui).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerUtil = require(ReplicatedStorage.Shared.PlayerUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerStats = require(script.Parent.PlayerStats)
local Analytics = require(script.Parent.Analytics)

local XpService = {}

local gemsFolder: Folder
local gemPool: { Part } = {}
local activeGems: { Part } = {}

type Prog = {
	xp: number, -- XP dentro do nivel atual
	level: number,
	pending: boolean, -- true enquanto espera a escolha de upgrade
	offered: { string }, -- ids oferecidos (para validar a escolha)
}
local prog: { [Player]: Prog } = {}

local progressChanged = Remotes.event("ProgressChanged")
local levelUp = Remotes.event("LevelUp")
local chooseUpgrade = Remotes.event("ChooseUpgrade")

local function makeGem(): Part
	local p = Instance.new("Part")
	p.Name = "XpGem"
	p.Shape = Enum.PartType.Ball
	p.Size = Config.Xp.GemSize
	p.Color = Config.Xp.GemColor
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

local function getProg(player: Player): Prog
	local pr = prog[player]
	if not pr then
		pr = { xp = 0, level = 1, pending = false, offered = {} }
		prog[player] = pr
	end
	return pr
end

-- XP necessario para ir do nivel `level` ao `level+1`.
local function xpForLevel(level: number): number
	local p = Config.Progression
	return math.floor(p.BaseXp * p.Growth ^ (level - 1) + 0.5)
end

local function fireProgress(player: Player)
	local pr = getProg(player)
	progressChanged:FireClient(player, pr.level, pr.xp, xpForLevel(pr.level))
end

-- Sorteia ate 3 upgrades distintos do catalogo.
local function pickThree(): { any }
	local copy = table.clone(Config.Upgrades)
	-- embaralha (Fisher-Yates)
	for i = #copy, 2, -1 do
		local j = math.random(i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	local out = {}
	for i = 1, math.min(3, #copy) do
		table.insert(out, copy[i])
	end
	return out
end

local function findUpgrade(id: string): any
	for _, entry in Config.Upgrades do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

local function tryLevelUp(player: Player)
	local pr = getProg(player)
	while not pr.pending and pr.xp >= xpForLevel(pr.level) do
		pr.xp -= xpForLevel(pr.level)
		pr.level += 1
		Analytics.levelReached(player, pr.level)

		local options = pickThree()
		pr.offered = {}
		for _, entry in options do
			table.insert(pr.offered, entry.id)
		end
		pr.pending = true
		levelUp:FireClient(player, pr.level, options)
	end
	fireProgress(player)
end

function XpService.addXp(player: Player, amount: number)
	local pr = getProg(player)
	pr.xp += amount
	tryLevelUp(player)
end

function XpService.dropGem(pos: Vector3)
	local gem = table.remove(gemPool)
	if not gem then
		return
	end
	gem.Position = pos
	gem.Parent = gemsFolder
	table.insert(activeGems, gem)
end

local function recycle(index: number)
	local gem = activeGems[index]
	gem.Parent = nil
	local last = #activeGems
	activeGems[index] = activeGems[last]
	activeGems[last] = nil
	table.insert(gemPool, gem)
end

function XpService.update(_dt: number)
	for i = #activeGems, 1, -1 do
		local gem = activeGems[i]
		local root = PlayerUtil.nearestRoot(gem.Position)
		if not root then
			continue
		end
		local character = root.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		local magnet = Config.Xp.MagnetRadius
		if player then
			magnet = PlayerStats.get(player).magnetRadius
		end

		local to = root.Position - gem.Position
		local dist = to.Magnitude
		if dist <= Config.Xp.CollectRadius then
			if player then
				XpService.addXp(player, Config.Xp.GemValue)
			end
			recycle(i)
		elseif dist <= magnet and dist > 0 then
			local step = math.min(Config.Xp.GemSpeed * _dt, dist)
			gem.Position = gem.Position + (to / dist) * step
		end
	end
end

function XpService.init()
	gemsFolder = Instance.new("Folder")
	gemsFolder.Name = "XpGems"
	gemsFolder.Parent = workspace
	for _ = 1, Config.Xp.PoolSize do
		table.insert(gemPool, makeGem())
	end

	-- escolha de upgrade vinda do cliente: valida que e uma das 3 oferecidas
	chooseUpgrade.OnServerEvent:Connect(function(player, id)
		if typeof(id) ~= "string" then
			return
		end
		local pr = getProg(player)
		if not pr.pending or not table.find(pr.offered, id) then
			return
		end
		local entry = findUpgrade(id)
		if entry then
			PlayerStats.applyUpgrade(player, entry)
			Analytics.upgradeChosen(player, pr.level, id)
		end
		pr.pending = false
		pr.offered = {}
		tryLevelUp(player) -- caso tenha acumulado mais de um nivel
	end)

	Players.PlayerRemoving:Connect(function(player)
		prog[player] = nil
	end)

	local function onPlayer(player: Player)
		getProg(player)
		task.defer(fireProgress, player)
	end
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
end

return XpService
