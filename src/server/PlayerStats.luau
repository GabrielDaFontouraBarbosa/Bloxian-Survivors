--!strict
-- Stats de combate por jogador. Comeca dos valores base do Config e sobe com
-- os upgrades do level up. A arma e o XP leem daqui (nao do Config global).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerStats = {}

export type Stats = {
	damage: number,
	fireInterval: number,
	walkSpeed: number,
	maxHealth: number,
	magnetRadius: number,
}

local stats: { [Player]: Stats } = {}

local function defaults(): Stats
	return {
		damage = Config.Weapon.Damage,
		fireInterval = Config.Weapon.FireInterval,
		walkSpeed = Config.Player.WalkSpeed,
		maxHealth = Config.Player.MaxHealth,
		magnetRadius = Config.Xp.MagnetRadius,
	}
end

function PlayerStats.get(player: Player): Stats
	local s = stats[player]
	if not s then
		s = defaults()
		stats[player] = s
	end
	return s
end

-- Aplica velocidade e vida no Humanoid atual (se existir).
local function applyToHumanoid(player: Player)
	local s = PlayerStats.get(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = s.walkSpeed
		hum.MaxHealth = s.maxHealth
		if hum.Health < s.maxHealth then
			hum.Health = s.maxHealth
		end
	end
end

-- Aplica um upgrade do Config.Upgrades. O efeito mora aqui; os numeros no Config.
function PlayerStats.applyUpgrade(player: Player, entry: { [string]: any })
	local s = PlayerStats.get(player)
	if entry.id == "damage" then
		s.damage += entry.amount
	elseif entry.id == "firerate" then
		s.fireInterval = math.max(Config.Progression.FireIntervalMin, s.fireInterval * entry.mult)
	elseif entry.id == "speed" then
		s.walkSpeed += entry.amount
		applyToHumanoid(player)
	elseif entry.id == "health" then
		s.maxHealth += entry.amount
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = s.maxHealth
			hum.Health = math.min(s.maxHealth, hum.Health + entry.amount)
		end
	elseif entry.id == "magnet" then
		s.magnetRadius += entry.amount
	end
end

function PlayerStats.init()
	local function onPlayer(player: Player)
		PlayerStats.get(player)
		player.CharacterAdded:Connect(function()
			-- espera o Humanoid aparecer e reaplica os stats atuais
			task.defer(applyToHumanoid, player)
		end)
		if player.Character then
			applyToHumanoid(player)
		end
	end
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		stats[player] = nil
	end)
end

return PlayerStats
