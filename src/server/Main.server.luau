--!strict
-- Ponto de entrada do servidor. Liga os sistemas e roda o loop central unico.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyService = require(script.Parent.EnemyService)
local XpService = require(script.Parent.XpService)
local WeaponService = require(script.Parent.WeaponService)

print("[Survivors] Servidor iniciado (passo 3: arma automatica mira e atira sozinha).")

XpService.init()
EnemyService.init()
WeaponService.init()

-- Loop central: um unico Heartbeat move inimigos, arma e gemas.
RunService.Heartbeat:Connect(function(dt)
	EnemyService.update(dt) -- inimigos perseguem e batem
	WeaponService.update(dt) -- arma mira no mais proximo e atira
	XpService.update(dt) -- gemas voam ate o jogador
end)
