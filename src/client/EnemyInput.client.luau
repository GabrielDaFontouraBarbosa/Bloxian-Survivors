--!strict
-- DEBUG (temporario): clicar num inimigo pede ao servidor pra mata-lo.
-- Vai embora no passo 3, quando a arma mira e ataca sozinha.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local debugKill = Remotes.event("DebugKillEnemy")

mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if target and target.Name == "Enemy" and target.Parent and target.Parent.Name == "Enemies" then
		-- o servidor ainda valida que e um inimigo vivo; aqui e so um filtro barato
		debugKill:FireServer(target)
	end
end)
