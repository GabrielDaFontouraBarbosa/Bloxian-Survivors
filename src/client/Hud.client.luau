--!strict
-- HUD minimo: mostra o XP acumulado (o servidor manda o total por RemoteEvent).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivorsHud"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(160, 44)
label.Position = UDim2.fromOffset(16, 16)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.4
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "XP: 0"
label.Parent = gui

gui.Parent = player:WaitForChild("PlayerGui")

local xpChanged = Remotes.event("XpChanged")
xpChanged.OnClientEvent:Connect(function(total: number)
	label.Text = "XP: " .. tostring(total)
end)
