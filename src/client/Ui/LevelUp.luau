--!strict
-- Painel de level up (estilo VS): 3-4 cartas com o que muda, dica de evolucao,
-- teclas 1-4 para escolher, Rerrolar e Pular (se tiver cargas de PowerUp).
-- Manda so o INDICE da escolha; o servidor confere contra o que ofereceu.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Content = require(Shared:WaitForChild("Content"))
local Theme = require(script.Parent.Theme)

local LevelUp = {}

export type Actions = {
	choose: (index: number) -> (),
	reroll: () -> (),
	skip: () -> (),
}

local C = Theme.C

local gui: ScreenGui
local titleLabel: TextLabel
local list: Frame
local rerollButton: TextButton
local skipButton: TextButton
local actions: Actions
local open = false
local optionCount = 0

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

-- Texto de uma opcao: nome, etiqueta, descricao e dica.
local function describe(opt: any): (string, string, string, string, Color3)
	if opt.kind == "weapon" then
		local def = Content.weapons[opt.id]
		if not def then
			return "?", "", "", "", C.panel3
		end
		local desc = if opt.new then def.desc else (def.levelDesc and def.levelDesc[opt.level - 1] or def.desc)
		local hint = ""
		if def.evolution then
			local passive = Content.passives[def.evolution.passive]
			local into = Content.weapons[def.evolution.into]
			if passive and into then
				hint = ("Evolui em %s com %s"):format(into.name, passive.name)
			end
		end
		return def.name, if opt.new then "NOVO!" else ("Nível %d"):format(opt.level), desc, hint, def.color
	elseif opt.kind == "passive" then
		local def = Content.passives[opt.id]
		if not def then
			return "?", "", "", "", C.panel3
		end
		local hint = ""
		if def.evolves then
			local weapon = Content.weapons[def.evolves]
			if weapon then
				hint = "Ajuda a evoluir: " .. weapon.name
			end
		end
		return def.name, if opt.new then "NOVO!" else ("Nível %d"):format(opt.level), def.desc, hint, def.color
	elseif opt.kind == "gold" then
		return "Saco de Ouro", "", ("+%d de ouro."):format(Config.Chest.LevelUpGold), "", C.gold
	end
	return "Coxa Assada", "", ("Recupera %d de vida."):format(Config.Chest.LevelUpHeal), "", C.hp
end

function LevelUp.show(data: any)
	open = true
	gui.Enabled = true
	titleLabel.Text = ("SUBIU DE NÍVEL!  ·  NV %d"):format(data.level)
	Theme.clear(list)
	optionCount = #data.options
	for i, opt in data.options do
		local name, tag, desc, hint, color = describe(opt)
		local card = Theme.button("", { Size = UDim2.new(1, 0, 0, 84), LayoutOrder = i, BackgroundColor3 = C.panel2 }, list)
		Theme.stroke(card, C.border, 1)
		local icon = Theme.frame({ Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(12, 14), BackgroundColor3 = color }, card)
		Theme.corner(icon, 8)
		Theme.label(tostring(i), { Font = Theme.NumberFont, TextSize = 22, TextColor3 = C.backdrop, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) }, icon)
		Theme.label(name, { Font = Theme.BoldFont, TextSize = 18, Size = UDim2.new(1, -190, 0, 24), Position = UDim2.fromOffset(80, 8) }, card)
		Theme.label(tag, {
			Font = Theme.BoldFont,
			TextSize = 15,
			TextColor3 = if tag == "NOVO!" then C.gold else C.dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.fromOffset(100, 24),
			Position = UDim2.new(1, -110, 0, 8),
		}, card)
		Theme.label(desc, { TextSize = 14, Size = UDim2.new(1, -92, 0, 22), Position = UDim2.fromOffset(80, 32) }, card)
		Theme.label(hint, { TextSize = 12, TextColor3 = C.accentHi, Size = UDim2.new(1, -92, 0, 18), Position = UDim2.fromOffset(80, 56) }, card)
		card.Activated:Connect(function()
			if open then
				open = false
				actions.choose(i)
			end
		end)
	end
	rerollButton.Text = ("Rerrolar (%d)"):format(data.rerolls)
	rerollButton.BackgroundColor3 = if data.rerolls > 0 then C.panel3 else C.locked
	rerollButton.AutoButtonColor = data.rerolls > 0
	skipButton.Text = ("Pular (%d)"):format(data.skips)
	skipButton.BackgroundColor3 = if data.skips > 0 then C.panel3 else C.locked
	skipButton.AutoButtonColor = data.skips > 0
	rerollButton:SetAttribute("charges", data.rerolls)
	skipButton:SetAttribute("charges", data.skips)
end

function LevelUp.hide()
	open = false
	if gui then
		gui.Enabled = false
	end
end

function LevelUp.init(parent: Instance, acts: Actions)
	actions = acts
	gui = Theme.make("ScreenGui", {
		Name = "LevelUp",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Enabled = false,
	}, parent)
	Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.backdrop, BackgroundTransparency = 0.5 }, gui)
	local panel = Theme.frame({
		Size = UDim2.fromOffset(520, 470),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.panel,
	}, gui)
	Theme.corner(panel, 12)
	Theme.stroke(panel, C.gold, 2)
	Theme.pad(panel, 12)
	titleLabel = Theme.label("SUBIU DE NÍVEL!", {
		Font = Theme.TitleFont,
		TextSize = 32,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 36),
	}, panel)
	list = Theme.frame({ Size = UDim2.new(1, 0, 1, -96), Position = UDim2.fromOffset(0, 42), BackgroundTransparency = 1 }, panel)
	Theme.list(list, false, 6)

	rerollButton = Theme.button("Rerrolar", { Size = UDim2.new(0.5, -4, 0, 38), Position = UDim2.new(0, 0, 1, -38), TextSize = 15 }, panel)
	skipButton = Theme.button("Pular", { Size = UDim2.new(0.5, -4, 0, 38), Position = UDim2.new(0.5, 4, 1, -38), TextSize = 15 }, panel)
	rerollButton.Activated:Connect(function()
		if open and (rerollButton:GetAttribute("charges") or 0) > 0 then
			actions.reroll()
		end
	end)
	skipButton.Activated:Connect(function()
		if open and (skipButton:GetAttribute("charges") or 0) > 0 then
			open = false
			actions.skip()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not open then
			return
		end
		local index = table.find(KEYS, input.KeyCode)
		if index and index <= optionCount then
			open = false
			actions.choose(index)
		end
	end)
end

return LevelUp
