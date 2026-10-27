--!strict
-- Gemas de XP: soltas quando um inimigo morre, voam ate o jogador proximo
-- e somam XP no servidor. O level up vem no passo 4; aqui so acumula e mostra.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerUtil = require(ReplicatedStorage.Shared.PlayerUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local XpService = {}

local gemsFolder: Folder
local gemPool: { Part } = {}
local activeGems: { Part } = {}
local xpByPlayer: { [Player]: number } = {}

local xpChanged = Remotes.event("XpChanged")

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

function XpService.init()
	gemsFolder = Instance.new("Folder")
	gemsFolder.Name = "XpGems"
	gemsFolder.Parent = workspace
	for _ = 1, Config.Xp.PoolSize do
		table.insert(gemPool, makeGem())
	end
	Players.PlayerRemoving:Connect(function(player)
		xpByPlayer[player] = nil
	end)
end

function XpService.dropGem(pos: Vector3)
	local gem = table.remove(gemPool)
	if not gem then
		return -- sem gema livre; ignora (raro com PoolSize alto)
	end
	gem.Position = pos
	gem.Parent = gemsFolder
	table.insert(activeGems, gem)
end

function XpService.addXp(player: Player, amount: number)
	local total = (xpByPlayer[player] or 0) + amount
	xpByPlayer[player] = total
	xpChanged:FireClient(player, total)
end

local function recycle(index: number)
	local gem = activeGems[index]
	gem.Parent = nil
	-- remove rapido trocando com o ultimo (ordem nao importa)
	local last = #activeGems
	activeGems[index] = activeGems[last]
	activeGems[last] = nil
	table.insert(gemPool, gem)
end

-- Loop central (chamado pelo Main junto com o EnemyService).
function XpService.update(dt: number)
	for i = #activeGems, 1, -1 do
		local gem = activeGems[i]
		local root = PlayerUtil.nearestRoot(gem.Position)
		if not root then
			continue
		end
		local to = root.Position - gem.Position
		local dist = to.Magnitude
		if dist <= Config.Xp.CollectRadius then
			local character = root.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				XpService.addXp(player, Config.Xp.GemValue)
			end
			recycle(i)
		elseif dist <= Config.Xp.MagnetRadius and dist > 0 then
			local step = math.min(Config.Xp.GemSpeed * dt, dist)
			gem.Position = gem.Position + (to / dist) * step
		end
	end
end

return XpService
