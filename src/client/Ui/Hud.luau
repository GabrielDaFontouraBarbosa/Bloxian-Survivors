--!strict
-- HUD da partida (estilo VS): barra de XP no topo, nivel, cronometro, abates,
-- ouro, slots de armas/passivas e barra de vida. So mostra o que o servidor
-- manda (RunSync). Botao "Desistir" pede confirmacao (2 cliques).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Content = require(Shared:WaitForChild("Content"))
local Theme = require(script.Parent.Theme)

local Hud = {}

local C = Theme.C

local gui: ScreenGui
local setXp: (number) -> ()
local levelLabel: TextLabel
local timerLabel: TextLabel
local killsLabel: TextLabel
local goldLabel: TextLabel
local frozenLabel: TextLabel
local setHp: (number) -> ()
local hpLabel: TextLabel
local weaponRow: Frame
local passiveRow: Frame
local quitButton: TextButton
local lastSlots = ""

-- Duas primeiras letras (por caractere UTF-8, para nao quebrar acento).
local function initials(name: string): string
	local stop = utf8.offset(name, 3)
	return if stop then string.sub(name, 1, stop - 1) else name
end

local function slotBox(parent: Instance, def: any, level: number, size: number, order: number)
	local box = Theme.frame({ Size = UDim2.fromOffset(size, size), BackgroundColor3 = C.panel, LayoutOrder = order }, parent)
	Theme.corner(box, 6)
	Theme.stroke(box, if def and def.evolved then C.gold else C.border, if def and def.evolved then 2 else 1)
	if def then
		local inner = Theme.frame({
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.fromOffset(4, 4),
			BackgroundColor3 = def.color or C.panel3,
		}, box)
		Theme.corner(inner, 4)
		Theme.label(initials(def.name), {
			Font = Theme.BoldFont,
			TextSize = math.floor(size * 0.36),
			TextColor3 = C.backdrop,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
		}, inner)
		Theme.label(if def.evolved then "★" else tostring(level), {
			Font = Theme.NumberFont,
			TextSize = 12,
			TextColor3 = C.text,
			TextStrokeTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Size = UDim2.new(1, -2, 1, 0),
		}, box)
	end
end

local function renderSlots(weapons: { any }, passives: { any })
	-- so redesenha quando muda (RunSync chega 5x por segundo)
	local key = ""
	for _, w in weapons do
		key ..= w.id .. w.level .. ","
	end
	key ..= "|"
	for _, p in passives do
		key ..= p.id .. p.level .. ","
	end
	if key == lastSlots then
		return
	end
	lastSlots = key
	Theme.clear(weaponRow)
	Theme.clear(passiveRow)
	for i = 1, Config.Run.MaxWeapons do
		local w = weapons[i]
		slotBox(weaponRow, w and Content.weapons[w.id], w and w.level or 0, 40, i)
	end
	for i = 1, Config.Run.MaxPassives do
		local p = passives[i]
		slotBox(passiveRow, p and Content.passives[p.id], p and p.level or 0, 30, i)
	end
end

function Hud.update(data: any)
	setXp(if data.need > 0 then data.xp / data.need else 0)
	levelLabel.Text = ("NV %d"):format(data.level)
	timerLabel.Text = Theme.clock(data.t)
	timerLabel.TextColor3 = if data.t >= data.duration then C.bad else C.text
	killsLabel.Text = ("☠ %d"):format(data.kills)
	goldLabel.Text = ("● %d"):format(data.gold)
	frozenLabel.Visible = data.frozen == true
	setHp(if data.maxHp > 0 then data.hp / data.maxHp else 0)
	hpLabel.Text = ("%d / %d%s"):format(math.ceil(data.hp), math.floor(data.maxHp), if data.revivals > 0 then ("  ✚%d"):format(data.revivals) else "")
	renderSlots(data.weapons or {}, data.passives or {})
end

function Hud.setVisible(on: boolean)
	gui.Enabled = on
	if on then
		lastSlots = ""
		quitButton.Text = "Desistir"
	end
end

function Hud.init(parent: Instance, onQuit: () -> ())
	gui = Theme.make("ScreenGui", {
		Name = "RunHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Enabled = false,
	}, parent)

	local xpBg
	xpBg, setXp = Theme.bar({ Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 8) }, C.xp, gui)
	Theme.stroke(xpBg, C.border, 1)
	levelLabel = Theme.label("NV 1", {
		Font = Theme.NumberFont,
		TextSize = 14,
		TextColor3 = C.text,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(1, -8, 1, 0),
	}, xpBg)

	timerLabel = Theme.label("00:00", {
		Font = Theme.NumberFont,
		TextSize = 34,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(200, 40),
		Position = UDim2.new(0.5, -100, 0, 28),
	}, gui)
	frozenLabel = Theme.label("CONGELADO", {
		Font = Theme.BoldFont,
		TextSize = 16,
		TextColor3 = C.xp,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(200, 20),
		Position = UDim2.new(0.5, -100, 0, 68),
		Visible = false,
	}, gui)

	killsLabel = Theme.label("☠ 0", {
		Font = Theme.NumberFont,
		TextSize = 20,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(180, 26),
		Position = UDim2.new(1, -196, 0, 30),
	}, gui)
	goldLabel = Theme.label("● 0", {
		Font = Theme.NumberFont,
		TextSize = 20,
		TextColor3 = C.gold,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(180, 26),
		Position = UDim2.new(1, -196, 0, 56),
	}, gui)

	weaponRow = Theme.frame({ Size = UDim2.fromOffset(300, 40), Position = UDim2.fromOffset(10, 30), BackgroundTransparency = 1 }, gui)
	Theme.list(weaponRow, true, 4)
	passiveRow = Theme.frame({ Size = UDim2.fromOffset(300, 30), Position = UDim2.fromOffset(10, 74), BackgroundTransparency = 1 }, gui)
	Theme.list(passiveRow, true, 4)

	local hpBg
	hpBg, setHp = Theme.bar({ Size = UDim2.fromOffset(320, 18), Position = UDim2.new(0.5, -160, 1, -40) }, C.hp, gui)
	Theme.stroke(hpBg, C.border, 1)
	hpLabel = Theme.label("", {
		Font = Theme.BoldFont,
		TextSize = 13,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
	}, hpBg)

	quitButton = Theme.button("Desistir", {
		Size = UDim2.fromOffset(110, 30),
		Position = UDim2.new(0, 10, 1, -44),
		TextSize = 14,
		BackgroundColor3 = C.panel3,
	}, gui)
	local armedUntil = 0
	quitButton.Activated:Connect(function()
		if os.clock() < armedUntil then
			armedUntil = 0
			onQuit()
		else
			armedUntil = os.clock() + 3
			quitButton.Text = "Confirmar?"
			task.delay(3, function()
				if os.clock() >= armedUntil then
					quitButton.Text = "Desistir"
				end
			end)
		end
	end)
end

return Hud
