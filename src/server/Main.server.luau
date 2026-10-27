--!strict
-- Ponto de entrada do servidor. Liga os sistemas e roda o loop central unico.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)
local XpService = require(script.Parent.XpService)
local Analytics = require(script.Parent.Analytics)

print("[Survivors] Servidor iniciado (passo 2: inimigos spawnam, perseguem, morrem e soltam XP).")

XpService.init()
EnemyService.init()

-- DEBUG (temporario, sai no passo 3 com a arma automatica):
-- o cliente clica num inimigo e pede pra matar. O servidor valida tipo e taxa.
local debugKill = Remotes.event("DebugKillEnemy")
local lastKillAt: { [Player]: number } = {}

debugKill.OnServerEvent:Connect(function(player, enemy)
	if not EnemyService.isActive(enemy) then
		return -- so aceita inimigo vivo de verdade
	end
	local now = os.clock()
	if lastKillAt[player] and now - lastKillAt[player] < 0.05 then
		return -- limita a taxa de cliques
	end
	lastKillAt[player] = now
	EnemyService.damage(enemy :: Part, math.huge)
	Analytics.firstEnemyKill(player)
end)

Players.PlayerRemoving:Connect(function(player)
	lastKillAt[player] = nil
end)

-- Loop central: um unico Heartbeat move todos os inimigos e todas as gemas.
RunService.Heartbeat:Connect(function(dt)
	EnemyService.update(dt)
	XpService.update(dt)
end)
