--!strict
-- Abertura de bau: lista o que veio (evolucao em destaque, niveis, ouro).
-- O servidor pausa a run ate o jogador continuar (ou fecha sozinho).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Content = require(Shared:WaitForChild("Content"))
local Theme = require(script.Parent.Theme)

local Chest = {}

local C = Theme.C

local gui: ScreenGui
local list: Frame
local onContinue: () -> ()

local function line(text: string, color: Color3, bold: boolean, order: number)
	Theme.label(text, {
		Font = if bold then Theme.BoldFont else Theme.BodyFont,
		TextSize = if bold then 18 else 16,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = order,
	}, list)
end

function Chest.show(data: any)
	gui.Enabled = true
	Theme.clear(list)
	for i, item in data.items do
		if item.kind == "evolve" then
			local from = Content.weapons[item.from]
			local to = Content.weapons[item.to]
			line(("✦ EVOLUÇÃO: %s → %s"):format(from and from.name or "?", to and to.name or "?"), C.gold, true, i)
		elseif item.kind == "weapon" then
			local def = Content.weapons[item.id]
			line(("%s  ·  Nível %d"):format(def and def.name or "?", item.level or 1), C.text, false, i)
		elseif item.kind == "passive" then
			local def = Content.passives[item.id]
			line(("%s  ·  Nível %d"):format(def and def.name or "?", item.level or 1), C.text, false, i)
		end
	end
	line(("+%d de ouro"):format(data.gold or 0), C.gold, true, 100)
end

function Chest.hide()
	if gui then
		gui.Enabled = false
	end
end

function Chest.init(parent: Instance, onDone: () -> ())
	onContinue = onDone
	gui = Theme.make("ScreenGui", {
		Name = "Chest",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 12,
		Enabled = false,
	}, parent)
	Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.backdrop, BackgroundTransparency = 0.5 }, gui)
	local panel = Theme.frame({
		Size = UDim2.fromOffset(480, 340),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.panel,
	}, gui)
	Theme.corner(panel, 12)
	Theme.stroke(panel, C.gold, 2)
	Theme.pad(panel, 14)
	Theme.label("BAÚ!", {
		Font = Theme.TitleFont,
		TextSize = 40,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 44),
	}, panel)
	list = Theme.frame({ Size = UDim2.new(1, 0, 1, -100), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1 }, panel)
	Theme.list(list, false, 4)
	local button = Theme.button("Continuar", {
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -40),
		BackgroundColor3 = C.accent,
		TextSize = 18,
	}, panel)
	button.Activated:Connect(function()
		Chest.hide()
		onContinue()
	end)
end

return Chest
