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
local waveChanged = Remotes.event("WaveChanged")
local playerDied = Remotes.event("PlayerDied")

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

-- Onda atual (canto superior direito)
local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.fromOffset(160, 26)
waveLabel.Position = UDim2.new(1, -176, 0, 16)
waveLabel.BackgroundTransparency = 1
waveLabel.TextXAlignment = Enum.TextXAlignment.Right
waveLabel.TextColor3 = Color3.new(1, 1, 1)
waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.GothamBold
waveLabel.Text = "Onda 1"
waveLabel.Parent = gui

waveChanged.OnClientEvent:Connect(function(wave: number)
	waveLabel.Text = "Onda " .. tostring(wave)
end)

-- Aviso de morte (some sozinho)
local deathLabel = Instance.new("TextLabel")
deathLabel.Size = UDim2.fromOffset(420, 40)
deathLabel.Position = UDim2.fromScale(0.5, 0.3)
deathLabel.AnchorPoint = Vector2.new(0.5, 0.5)
deathLabel.BackgroundTransparency = 1
deathLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
deathLabel.TextScaled = true
deathLabel.Font = Enum.Font.GothamBold
deathLabel.Visible = false
deathLabel.Parent = gui

playerDied.OnClientEvent:Connect(function(wave: number, seconds: number)
	deathLabel.Text = ("Voce caiu na onda %d (%ds)"):format(wave, seconds)
	deathLabel.Visible = true
	task.delay(4, function()
		deathLabel.Visible = false
	end)
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

-- ============ Meta-progressao: moedas e loja de perks permanentes ============
local metaSync = Remotes.event("MetaSync")
local buyPerk = Remotes.event("BuyPerk")

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(220, 24)
coinsLabel.Position = UDim2.fromOffset(16, 68)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Text = "Moedas: 0"
coinsLabel.Parent = gui

local shopToggle = Instance.new("TextButton")
shopToggle.Size = UDim2.fromOffset(150, 32)
shopToggle.Position = UDim2.new(1, -166, 1, -48)
shopToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
shopToggle.BorderSizePixel = 0
shopToggle.TextColor3 = Color3.new(1, 1, 1)
shopToggle.TextScaled = true
shopToggle.Font = Enum.Font.GothamBold
shopToggle.Text = "Loja (B)"
shopToggle.Parent = gui

local shopPanel = Instance.new("Frame")
shopPanel.Size = UDim2.fromOffset(560, 240)
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
shopPanel.BackgroundTransparency = 0.05
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 34)
shopTitle.BackgroundTransparency = 1
shopTitle.TextColor3 = Color3.new(1, 1, 1)
shopTitle.TextScaled = true
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "Upgrades permanentes (ficam entre partidas)"
shopTitle.Parent = shopPanel

local shopRow = Instance.new("Frame")
shopRow.Size = UDim2.new(1, -24, 1, -52)
shopRow.Position = UDim2.fromOffset(12, 42)
shopRow.BackgroundTransparency = 1
shopRow.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.FillDirection = Enum.FillDirection.Horizontal
shopLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopLayout.VerticalAlignment = Enum.VerticalAlignment.Center
shopLayout.Padding = UDim.new(0, 12)
shopLayout.Parent = shopRow

local latestCoins = 0
local latestShop: { any } = {}

-- Reconstroi os botoes. So e chamado com a loja aberta, para nao ficar
-- recriando GUI a cada moeda ganha.
local function renderShop()
	for _, child in shopRow:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, item in latestShop do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(170, 150)
		btn.BackgroundColor3 = if latestCoins >= item.cost
			then Color3.fromRGB(45, 60, 45)
			else Color3.fromRGB(50, 40, 40)
		btn.BorderSizePixel = 0
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.Gotham
		btn.TextWrapped = true
		btn.TextSize = 15
		btn.Text = ("%s\n(nivel %d)\n\n%s\n\nCusto: %d"):format(
			tostring(item.name),
			item.level,
			tostring(item.desc),
			item.cost
		)
		btn.Parent = shopRow
		btn.Activated:Connect(function()
			buyPerk:FireServer(item.id)
		end)
	end
end

local function toggleShop()
	shopPanel.Visible = not shopPanel.Visible
	if shopPanel.Visible then
		renderShop()
	end
end
shopToggle.Activated:Connect(toggleShop)

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.B then
		toggleShop()
	end
end)

metaSync.OnClientEvent:Connect(function(coins: number, shop: { any })
	latestCoins = coins
	latestShop = shop
	coinsLabel.Text = "Moedas: " .. tostring(coins)
	if shopPanel.Visible then
		renderShop()
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
