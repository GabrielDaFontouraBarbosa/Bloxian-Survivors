--!strict
-- HUD: nivel + barra de XP (canto) e painel de escolha de upgrade (centro).
-- O servidor manda o progresso e as 3 opcoes; o cliente so mostra e escolhe.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer

local progressChanged = Remotes.event("ProgressChanged")
local levelUp = Remotes.event("LevelUp")
local chooseUpgrade = Remotes.event("ChooseUpgrade")

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivorsHud"
gui.ResetOnSpawn = false

-- Nivel + barra de XP (canto superior esquerdo)
local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.fromOffset(220, 26)
levelLabel.Position = UDim2.fromOffset(16, 16)
levelLabel.BackgroundTransparency = 1
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.TextColor3 = Color3.new(1, 1, 1)
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Text = "Nivel 1"
levelLabel.Parent = gui

local barBg = Instance.new("Frame")
barBg.Size = UDim2.fromOffset(220, 16)
barBg.Position = UDim2.fromOffset(16, 46)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barBg.BorderSizePixel = 0
barBg.Parent = gui

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

progressChanged.OnClientEvent:Connect(function(level: number, xp: number, need: number)
	levelLabel.Text = "Nivel " .. tostring(level)
	local ratio = if need > 0 then math.clamp(xp / need, 0, 1) else 0
	barFill.Size = UDim2.new(ratio, 0, 1, 0)
end)

-- Painel de escolha de upgrade (centro)
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(520, 180)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "Level up! Escolha um upgrade"
title.Parent = panel

local row = Instance.new("Frame")
row.Size = UDim2.new(1, -24, 1, -56)
row.Position = UDim2.fromOffset(12, 44)
row.BackgroundTransparency = 1
row.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 12)
layout.Parent = row

local function clearRow()
	for _, child in row:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

levelUp.OnClientEvent:Connect(function(_level: number, options: { { [string]: any } })
	clearRow()
	for _, opt in options do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(150, 110)
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btn.BorderSizePixel = 0
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.Gotham
		btn.TextWrapped = true
		btn.TextSize = 16
		btn.Text = tostring(opt.name) .. "\n\n" .. tostring(opt.desc)
		btn.Parent = row
		btn.Activated:Connect(function()
			chooseUpgrade:FireServer(opt.id)
			panel.Visible = false
		end)
	end
	panel.Visible = true
end)

gui.Parent = player:WaitForChild("PlayerGui")
