--!strict
-- Ondas e dificuldade crescente. Controla o ritmo de spawn, escala os stats
-- dos inimigos por onda e solta um chefe a cada N ondas. Tambem loga a morte
-- (onda/tempo) para analytics. Curva toda em Config.Wave / Config.Boss.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerUtil = require(ReplicatedStorage.Shared.PlayerUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)
local Analytics = require(script.Parent.Analytics)

local WaveService = {}

local elapsed = 0 -- s desde o inicio da partida
local wave = 0 -- onda atual (0 = ainda nao comecou)
local spawnAccumulator = 0

local waveChanged = Remotes.event("WaveChanged")
local playerDied = Remotes.event("PlayerDied")

-- Multiplicadores da onda atual.
local function spawnInterval(): number
	local w = Config.Wave
	return math.max(w.SpawnIntervalMin, w.SpawnIntervalStart - w.SpawnIntervalStep * (wave - 1))
end

local function normalStats(): EnemyService.Stats
	local w = Config.Wave
	local healthMult = 1 + w.HealthStepPerWave * (wave - 1)
	local speedMult = 1 + w.SpeedStepPerWave * (wave - 1)
	return {
		health = math.max(1, math.floor(Config.Enemy.Health * healthMult + 0.5)),
		speed = math.min(w.SpeedMax, Config.Enemy.Speed * speedMult),
		contactDamage = Config.Enemy.ContactDamage,
		xpReward = Config.Enemy.XpReward,
		size = Config.Enemy.Size,
		color = Config.Enemy.Color,
	}
end

local function bossStats(): EnemyService.Stats
	local w = Config.Wave
	local healthMult = 1 + w.HealthStepPerWave * (wave - 1)
	return {
		health = math.floor(Config.Boss.Health * healthMult + 0.5),
		speed = Config.Boss.Speed,
		contactDamage = Config.Boss.ContactDamage,
		xpReward = Config.Boss.XpReward,
		size = Config.Boss.Size,
		color = Config.Boss.Color,
	}
end

local function spawnOne(stats: EnemyService.Stats)
	local player = PlayerUtil.randomPlayerWithChar()
	local char = player and player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		EnemyService.spawn(root, stats)
	end
end

local function startWave(n: number)
	wave = n
	waveChanged:FireAllClients(wave)
	-- chefe no inicio de cada BossEveryWaves ondas
	if wave % Config.Wave.BossEveryWaves == 0 then
		spawnOne(bossStats())
	end
end

function WaveService.update(dt: number)
	elapsed += dt

	local targetWave = math.floor(elapsed / Config.Wave.Duration) + 1
	while wave < targetWave do
		startWave(wave + 1)
	end

	spawnAccumulator += dt
	local interval = spawnInterval()
	while spawnAccumulator >= interval do
		spawnAccumulator -= interval
		spawnOne(normalStats())
	end
end

function WaveService.init()
	local function hookDeath(player: Player, char: Model)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		hum.Died:Connect(function()
			Analytics.runDeath(player, wave, elapsed)
			playerDied:FireClient(player, wave, math.floor(elapsed))
		end)
	end
	local function onPlayer(player: Player)
		task.defer(function()
			waveChanged:FireClient(player, math.max(1, wave))
		end)
		player.CharacterAdded:Connect(function(char)
			hookDeath(player, char)
		end)
		if player.Character then
			hookDeath(player, player.Character)
		end
	end
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
end

return WaveService
