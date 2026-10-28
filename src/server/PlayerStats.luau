--!strict
-- Stats de combate por jogador em duas camadas:
--   base    = Config + perks permanentes (definido pelo MetaService no inicio da vida)
--   current = base + upgrades do level up (reseta a cada nova vida/partida)
-- A arma e o XP leem o `current`. Numeros base no Config.
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

local base: { [Player]: Stats } = {}
local current: { [Player]: Stats } = {}

local function defaults(): Stats
	return {
		damage = Config.Weapon.Damage,
		fireInterval = Config.Weapon.FireInterval,
		walkSpeed = Config.Player.WalkSpeed,
		maxHealth = Config.Player.MaxHealth,
		magnetRadius = Config.Xp.MagnetRadius,
	}
end

-- Stats usados em jogo (cria defaults se ainda nao houver base definido).
function PlayerStats.get(player: Player): Stats
	local c = current[player]
	if not c then
		c = defaults()
		current[player] = c
		base[player] = table.clone(c)
	end
	return c
end

-- Define a base permanente (Config + perks) e zera os upgrades de run.
function PlayerStats.setBase(player: Player, stats: Stats)
	base[player] = stats
	current[player] = table.clone(stats)
end

-- Novo run: volta current para a base (perde os upgrades do level up).
function PlayerStats.resetRun(player: Player)
	local b = base[player]
	current[player] = if b then table.clone(b) else defaults()
end

function PlayerStats.applyToHumanoid(player: Player)
	local s = PlayerStats.get(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = s.walkSpeed
		hum.MaxHealth = s.maxHealth
		hum.Health = s.maxHealth
	end
end

-- Soma delta na base E no current (perk comprado durante a run: vale ja e persiste).
function PlayerStats.bump(player: Player, field: string, delta: number)
	local c = PlayerStats.get(player) -- garante tabelas
	local b = base[player]
	if b then
		local bAny = b :: any
		bAny[field] += delta
	end
	local cAny = c :: any
	cAny[field] += delta
	if field == "walkSpeed" or field == "maxHealth" then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if field == "walkSpeed" then
				hum.WalkSpeed = c.walkSpeed
			else
				hum.MaxHealth = c.maxHealth
				hum.Health = math.min(c.maxHealth, hum.Health + delta)
			end
		end
	end
end

-- Upgrade do level up (so no current, reseta no proximo run).
function PlayerStats.applyUpgrade(player: Player, entry: { [string]: any })
	local s = PlayerStats.get(player)
	if entry.id == "damage" then
		s.damage += entry.amount
	elseif entry.id == "firerate" then
		s.fireInterval = math.max(Config.Progression.FireIntervalMin, s.fireInterval * entry.mult)
	elseif entry.id == "speed" then
		s.walkSpeed += entry.amount
		PlayerStats.applyToHumanoid(player)
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

function PlayerStats.cleanup(player: Player)
	base[player] = nil
	current[player] = nil
end

return PlayerStats
