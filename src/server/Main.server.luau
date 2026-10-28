--!strict
-- Ponto de entrada do servidor. Liga os sistemas e roda o loop central unico.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStats = require(script.Parent.PlayerStats)
local EnemyService = require(script.Parent.EnemyService)
local XpService = require(script.Parent.XpService)
local WeaponService = require(script.Parent.WeaponService)
local WaveService = require(script.Parent.WaveService)

print("[Survivors] Servidor iniciado (passo 5: ondas, dificuldade crescente e chefe).")

PlayerStats.init()
XpService.init()
EnemyService.init()
WeaponService.init()
WaveService.init()

-- Loop central: um unico Heartbeat cuida de ondas, inimigos, arma e gemas.
RunService.Heartbeat:Connect(function(dt)
	WaveService.update(dt) -- avanca a onda e spawna (comum + chefe)
	EnemyService.update(dt) -- inimigos perseguem e batem
	WeaponService.update(dt) -- arma mira no mais proximo e atira
	XpService.update(dt) -- gemas voam ate o jogador
end)
