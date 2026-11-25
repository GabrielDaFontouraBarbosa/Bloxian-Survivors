--!strict
-- Tela de titulo (a "capa" do jogo, no estilo da tela inicial do VS) e tudo que
-- acontece fora da partida. Telas:
--   title        -> logo, os personagens, menu: Jogar / PowerUps / Aventuras / Conquistas / Opcoes
--   select       -> escolha do personagem + fase, botao COMECAR
--   shop         -> PowerUps (loja permanente; so aqui, nunca dentro da run)
--   adventures   -> "Em breve"
--   achievements -> lista de conquistas (hoje vazia, de proposito)
--   options      -> skin propria x skin do personagem
-- So mostra e pede: o servidor valida tudo (MetaService/RunManager).
-- O nome do modulo continua "Lobby" para nao mexer no resto do cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Content = require(Shared:WaitForChild("Content"))
local Theme = require(script.Parent.Theme)

local Lobby = {}

export type Actions = {
	start: (req: any) -> (),
	buyPowerUp: (id: string) -> (),
	refund: () -> (),
	buyClass: (id: string) -> (),
	claimQuest: (index: number) -> (),
	setOption: (key: string, value: any) -> (),
}

local C = Theme.C

-- Nome provisorio (DESIGN.md secao 4: nome do jogo ainda em aberto).
local GAME_TITLE_TOP = "BLOXIAN"
local GAME_TITLE_BOTTOM = "SURVIVORS"

local gui: ScreenGui
local screenRoot: Frame -- onde cada tela e desenhada
local goldLabel: TextLabel
local actions: Actions
local profile: any = nil
local current = "title"
local sel = { class = "", stage = "" }
local batsConn: RBXScriptConnection? = nil

-- ===================== pecas visuais =====================

local function rect(parent: Instance, x: number, y: number, w: number, h: number, color: Color3, round: number?): Frame
	local f = Theme.frame({
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		BackgroundColor3 = color,
	}, parent)
	if round then
		Theme.make("UICorner", { CornerRadius = UDim.new(round, 0) }, f)
	end
	return f
end

local function darker(c: Color3, f: number): Color3
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

-- Retrato do personagem feito de retangulos (mesmas cores da skin 3D do SkinService).
local function portrait(def: any, parent: Instance, props: { [string]: any }): Frame
	local box = Theme.frame({ BackgroundTransparency = 1 }, parent)
	for key, value in props do
		(box :: any)[key] = value
	end
	Theme.make("UIAspectRatioConstraint", { AspectRatio = 0.62, DominantAxis = Enum.DominantAxis.Height }, box)
	local skin = def.skin or {}
	local shirt = skin.shirt or def.color
	local pants = skin.pants or darker(def.color, 0.5)
	local tone = skin.skinTone or Color3.fromRGB(230, 190, 150)
	local hatColor = skin.hatColor or shirt

	if skin.cape then
		rect(box, 0.2, 0.33, 0.6, 0.52, skin.cape, 0.1)
	end
	rect(box, 0.31, 0.66, 0.16, 0.3, pants, 0.15)
	rect(box, 0.53, 0.66, 0.16, 0.3, pants, 0.15)
	rect(box, 0.27, 0.36, 0.46, 0.34, shirt, 0.12)
	rect(box, 0.15, 0.37, 0.12, 0.3, darker(shirt, 0.85), 0.4)
	rect(box, 0.73, 0.37, 0.12, 0.3, darker(shirt, 0.85), 0.4)
	rect(box, 0.33, 0.13, 0.34, 0.24, tone, 0.2)
	rect(box, 0.4, 0.22, 0.06, 0.04, Color3.fromRGB(20, 15, 20))
	rect(box, 0.54, 0.22, 0.06, 0.04, Color3.fromRGB(20, 15, 20))

	local hat = skin.hat
	if hat == "tricorn" then
		rect(box, 0.16, 0.12, 0.68, 0.05, hatColor, 0.5)
		rect(box, 0.31, 0.02, 0.38, 0.11, hatColor, 0.2)
		rect(box, 0.31, 0.09, 0.38, 0.03, Color3.fromRGB(150, 30, 30))
	elseif hat == "hood" then
		rect(box, 0.28, 0.08, 0.44, 0.09, hatColor, 0.4)
		rect(box, 0.28, 0.1, 0.07, 0.3, hatColor, 0.3)
		rect(box, 0.65, 0.1, 0.07, 0.3, hatColor, 0.3)
	elseif hat == "wizard" then
		rect(box, 0.2, 0.12, 0.6, 0.04, hatColor, 0.5)
		rect(box, 0.34, 0.06, 0.32, 0.07, hatColor, 0.2)
		rect(box, 0.39, 0.0, 0.22, 0.07, hatColor, 0.2)
		rect(box, 0.45, -0.06, 0.12, 0.07, hatColor, 0.3)
	elseif hat == "bandana" then
		rect(box, 0.32, 0.15, 0.36, 0.05, hatColor, 0.2)
		rect(box, 0.66, 0.16, 0.1, 0.06, hatColor, 0.3)
	end
	return box
end

-- Morcego de enfeite (corpo + duas asas que batem).
type Bat = { root: Frame, left: Frame, right: Frame, x: number, y: number, speed: number, phase: number, scale: number }
local bats: { Bat } = {}

local function makeBat(parent: Instance, scale: number): Bat
	local root = Theme.frame({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(70 * scale, 30 * scale) }, parent)
	local color = Color3.fromRGB(20, 10, 25)
	local left = Theme.frame({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.48, 0.32), BackgroundColor3 = color }, root)
	Theme.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, left)
	local right = Theme.frame({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.48, 0.32), BackgroundColor3 = color }, root)
	Theme.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, right)
	local body = Theme.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.22, 0.75), BackgroundColor3 = color }, root)
	Theme.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, body)
	rect(body, 0.18, 0.25, 0.22, 0.14, Color3.fromRGB(255, 50, 60), 0.5)
	rect(body, 0.6, 0.25, 0.22, 0.14, Color3.fromRGB(255, 50, 60), 0.5)
	return {
		root = root,
		left = left,
		right = right,
		x = math.random(),
		y = 0.1 + math.random() * 0.5,
		speed = 0.03 + math.random() * 0.05,
		phase = math.random() * 10,
		scale = scale,
	}
end

local function animateBats(dt: number)
	local t = os.clock()
	for _, b in bats do
		b.x += b.speed * dt
		if b.x > 1.1 then
			b.x = -0.1
			b.y = 0.08 + math.random() * 0.5
		end
		local bob = math.sin(t * 2 + b.phase) * 0.02
		b.root.Position = UDim2.fromScale(b.x, b.y + bob)
		local flap = math.sin(t * 14 + b.phase) * 28
		b.left.Rotation = flap
		b.right.Rotation = -flap
	end
end

-- Fundo do titulo: ceu de entardecer, lua, morros e morcegos voando.
local function buildBackground(parent: Instance)
	local sky = Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, parent)
	Theme.make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 8, 34)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(110, 30, 45)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 95, 55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 15, 20)),
		}),
	}, sky)
	-- lua com brilho
	local glow = Theme.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8, 0.2), Size = UDim2.fromScale(0.3, 0.3), BackgroundColor3 = Color3.fromRGB(255, 230, 190), BackgroundTransparency = 0.85 }, sky)
	Theme.make("UIAspectRatioConstraint", { AspectRatio = 1 }, glow)
	Theme.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
	local moon = Theme.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8, 0.2), Size = UDim2.fromScale(0.16, 0.16), BackgroundColor3 = Color3.fromRGB(250, 238, 210) }, sky)
	Theme.make("UIAspectRatioConstraint", { AspectRatio = 1 }, moon)
	Theme.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, moon)
	-- morros
	local hill = Color3.fromRGB(22, 10, 18)
	for i, h in { { 0.15, 0.82, 0.7 }, { 0.6, 0.86, 0.8 }, { 1.0, 0.8, 0.6 } } do
		local f = Theme.frame({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(h[1], h[2]), Size = UDim2.fromScale(h[3], 0.5), BackgroundColor3 = if i == 2 then darker(hill, 0.7) else hill }, sky)
		Theme.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
	end
	rect(sky, 0, 0.9, 1, 0.1, Color3.fromRGB(12, 6, 10))
	-- morcegos
	table.clear(bats)
	for i = 1, 9 do
		table.insert(bats, makeBat(sky, 0.5 + (i % 3) * 0.35))
	end
end

-- ===================== construtores comuns =====================

local function title(text: string, parent: Instance, order: number?): TextLabel
	return Theme.label(text, {
		Font = Theme.TitleFont,
		TextSize = 30,
		TextColor3 = C.gold,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = order or 0,
	}, parent)
end

local function scroller(props: { [string]: any }, parent: Instance): ScrollingFrame
	local s = Theme.make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.border,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, parent)
	for key, value in props do
		(s :: any)[key] = value
	end
	return s
end

local function go(screen: string)
	current = screen
	Lobby.refresh()
end

-- Painel central das telas internas: botao Voltar + titulo. Devolve a area de conteudo.
local function panel(heading: string): Frame
	local box = Theme.frame({
		Size = UDim2.fromScale(0.94, 0.86),
		Position = UDim2.fromScale(0.5, 0.53),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.05,
	}, screenRoot)
	Theme.corner(box, 12)
	Theme.stroke(box, C.border, 2)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(1120, 680) }, box)
	local back = Theme.button("‹ Voltar", { Size = UDim2.fromOffset(110, 38), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = C.panel3 }, box)
	back.Activated:Connect(function()
		go("title")
	end)
	Theme.label(heading, {
		Font = Theme.TitleFont,
		TextSize = 34,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -260, 0, 44),
		Position = UDim2.fromOffset(130, 8),
	}, box)
	local area = Theme.frame({
		Size = UDim2.new(1, -24, 1, -74),
		Position = UDim2.fromOffset(12, 62),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, box)
	return area
end

-- ===================== tela TITULO =====================

local MENU = {
	{ id = "select", name = "JOGAR", big = true },
	{ id = "shop", name = "PowerUps" },
	{ id = "adventures", name = "Aventuras" },
	{ id = "achievements", name = "Conquistas" },
	{ id = "options", name = "Opções" },
}

local function buildTitle()
	-- logo
	local logo = Theme.frame({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.8, 0.26) }, screenRoot)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(900, 230) }, logo)
	local top = Theme.label(GAME_TITLE_TOP, {
		Font = Theme.TitleFont,
		TextScaled = true,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 0.5),
	}, logo)
	Theme.make("UIStroke", { Color = Color3.fromRGB(90, 10, 20), Thickness = 4 }, top)
	local bottom = Theme.label(GAME_TITLE_BOTTOM, {
		Font = Theme.TitleFont,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 240, 220),
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 0.5),
		Position = UDim2.fromScale(0, 0.48),
	}, logo)
	Theme.make("UIStroke", { Color = Color3.fromRGB(120, 15, 30), Thickness = 4 }, bottom)

	-- personagens enfileirados embaixo do logo (como a capa do VS)
	local lineup = Theme.frame({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.97), Size = UDim2.fromScale(0.9, 0.34) }, screenRoot)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(1000, 300) }, lineup)
	local n = #Config.Classes
	local slotsLeft = math.ceil(n / 2)
	for i, def in Config.Classes do
		-- metade a esquerda do menu, metade a direita
		local x = if i <= slotsLeft then 0.02 + (i - 1) * 0.15 else 0.98 - (n - i) * 0.15
		portrait(def, lineup, {
			AnchorPoint = Vector2.new(if i <= slotsLeft then 0 else 1, 1),
			Position = UDim2.fromScale(x, 1),
			Size = UDim2.fromScale(0.2, if i % 2 == 0 then 0.85 else 1),
		})
	end

	-- menu
	local menu = Theme.frame({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(300, 330) }, screenRoot)
	Theme.list(menu, false, 10).HorizontalAlignment = Enum.HorizontalAlignment.Center
	for i, item in MENU do
		local b = Theme.button(item.name, {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, if item.big then 72 else 50),
			BackgroundColor3 = if item.big then C.accent else C.panel2,
			BackgroundTransparency = if item.big then 0 else 0.1,
			Font = if item.big then Theme.TitleFont else Theme.BoldFont,
			TextSize = if item.big then 40 else 20,
		}, menu)
		Theme.stroke(b, if item.big then C.gold else C.border, 2)
		b.Activated:Connect(function()
			go(item.id)
		end)
	end

	Theme.label("Nome provisório · versão de teste", {
		TextSize = 12,
		TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.5, 0, 0, 16),
	}, screenRoot)
end

-- ===================== tela SELECAO (personagem + fase) =====================

local function buildSelect()
	local p = profile
	local area = panel("Escolha o personagem")

	local left = Theme.frame({ Size = UDim2.new(0.58, -6, 1, 0), BackgroundColor3 = C.panel2 }, area)
	Theme.corner(left, 10)
	Theme.pad(left, 10)
	local grid = scroller({ Size = UDim2.fromScale(1, 1) }, left)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 210),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	for i, def in Config.Classes do
		local info = p.classes[def.id] or {}
		local selected = sel.class == def.id
		local card = Theme.button("", { LayoutOrder = i, BackgroundColor3 = if selected then C.accent else C.panel3 }, grid)
		if selected then
			Theme.stroke(card, C.gold, 3)
		end
		local art = Theme.frame({ Size = UDim2.new(1, -12, 0, 120), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.backdrop }, card)
		Theme.corner(art, 6)
		portrait(def, art, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0.95) })
		Theme.label(def.name, { Font = Theme.BoldFont, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -12, 0, 22), Position = UDim2.fromOffset(6, 130) }, card)
		local weapon = Content.weapons[def.weapon]
		Theme.label(weapon and weapon.name or "?", { TextSize = 13, TextColor3 = if weapon then weapon.color else C.dim, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(6, 152) }, card)
		local status: string
		local statusColor = C.dim
		if info.owned then
			status = if selected then "✓ Escolhido" else ""
			statusColor = C.gold
		elseif info.unlocked then
			status = ("Comprar · %d ouro"):format(def.price)
			statusColor = if p.gold >= def.price then C.gold else C.bad
		else
			status = "🔒 Bloqueado"
		end
		Theme.label(status, { TextSize = 13, TextColor3 = statusColor, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -12, 0, 22), Position = UDim2.fromOffset(6, 178) }, card)
		card.Activated:Connect(function()
			if info.owned then
				sel.class = def.id
				Lobby.refresh()
			elseif info.unlocked then
				actions.buyClass(def.id)
			end
		end)
	end

	-- direita: detalhes, fase, COMECAR
	local right = Theme.frame({ Size = UDim2.new(0.42, -6, 1, 0), Position = UDim2.new(0.58, 6, 0, 0), BackgroundColor3 = C.panel2 }, area)
	Theme.corner(right, 10)
	Theme.pad(right, 12)
	local info = scroller({ Size = UDim2.new(1, 0, 1, -70) }, right)
	Theme.list(info, false, 6)

	local def = Content.classes[sel.class]
	if def then
		title(def.name, info, 1)
		if def.title then
			Theme.label(def.title, { TextSize = 14, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 2 }, info)
		end
		Theme.label(def.desc, { TextSize = 15, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 3 }, info)
		local weapon = Content.weapons[def.weapon]
		if weapon then
			Theme.label(("Arma inicial: %s — %s"):format(weapon.name, weapon.desc), { TextSize = 14, TextColor3 = weapon.color, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 4 }, info)
		end
		local lines = { ("Vida base: %d"):format(def.baseHp) }
		for key, value in def.stats do
			local stat = Content.stats[key]
			if stat then
				table.insert(lines, ("%s %s"):format(stat.name, Content.formatStat(key, value)))
			end
		end
		if def.perk then
			table.insert(lines, def.perk.desc)
		end
		Theme.label(table.concat(lines, "\n"), { TextSize = 14, TextColor3 = C.good, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 5 }, info)
	end

	Theme.label("Fase", { Font = Theme.BoldFont, TextSize = 18, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 10 }, info)
	for i, stage in Config.Stages do
		local unlocked = p.stages[stage.id] == true
		local chosen = sel.stage == stage.id
		local b = Theme.button(if unlocked then stage.name else "🔒 " .. stage.name, {
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = 10 + i,
			TextSize = 16,
			BackgroundColor3 = if chosen then C.accent elseif unlocked then C.panel3 else C.locked,
		}, info)
		b.Activated:Connect(function()
			if unlocked then
				sel.stage = stage.id
				Lobby.refresh()
			end
		end)
	end
	local stageDef = Content.stages[sel.stage]
	if stageDef then
		Theme.label(stageDef.desc, { TextSize = 13, TextColor3 = C.dim, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 40 }, info)
	end

	local play = Theme.button("COMEÇAR", {
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 1, -60),
		BackgroundColor3 = C.accent,
		Font = Theme.TitleFont,
		TextSize = 36,
	}, right)
	Theme.stroke(play, C.gold, 2)
	play.Activated:Connect(function()
		actions.start({ class = sel.class, stage = sel.stage, arcana = "" })
	end)
end

-- ===================== tela POWERUPS =====================

local function buildShop()
	local p = profile
	local area = panel("PowerUps")
	Theme.label(("PowerUps valem para sempre, em todos os personagens. Cada compra encarece os próximos em %d%%. O reembolso devolve todo o ouro."):format(math.floor(Config.Meta.PowerUpMarkup * 100 + 0.5)), {
		TextSize = 14,
		TextColor3 = C.dim,
		Size = UDim2.new(1, 0, 0, 40),
	}, area)
	local grid = scroller({ Size = UDim2.new(1, 0, 1, -100), Position = UDim2.fromOffset(0, 44) }, area)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(200, 140),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	for i, def in Config.PowerUps do
		local info = p.powerUps[def.id] or { rank = 0, cost = def.cost }
		local card = Theme.frame({ LayoutOrder = i, BackgroundColor3 = C.panel2 }, grid)
		Theme.corner(card, 8)
		Theme.pad(card, 8)
		Theme.label(def.name, { Font = Theme.BoldFont, TextSize = 16, Size = UDim2.new(1, 0, 0, 20) }, card)
		Theme.label(("Rank %d/%d"):format(info.rank, def.maxLevel), { TextSize = 13, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 20) }, card)
		Theme.label(def.desc, { TextSize = 12, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 40), TextYAlignment = Enum.TextYAlignment.Top }, card)
		local maxed = info.cost < 0
		local affordable = not maxed and p.gold >= info.cost
		local buy = Theme.button(if maxed then "MÁXIMO" else ("Comprar · %d"):format(info.cost), {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 1, -30),
			TextSize = 14,
			BackgroundColor3 = if maxed then C.locked elseif affordable then C.good else C.panel3,
			AutoButtonColor = not maxed,
		}, card)
		buy.Activated:Connect(function()
			if not maxed then
				actions.buyPowerUp(def.id)
			end
		end)
	end
	local footer = Theme.frame({ Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44), BackgroundTransparency = 1 }, area)
	Theme.label(("Total investido: %d de ouro"):format(p.spent), { TextSize = 15, Size = UDim2.new(0.6, 0, 1, 0) }, footer)
	local refund = Theme.button("Reembolsar tudo", { Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.fromScale(0.7, 0), BackgroundColor3 = C.panel3 }, footer)
	refund.Activated:Connect(function()
		actions.refund()
	end)
end

-- ===================== tela AVENTURAS (em breve) =====================

local function comingSoon(area: Frame, heading: string, text: string)
	local box = Theme.frame({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.8, 0.5) }, area)
	Theme.label(heading, {
		Font = Theme.TitleFont,
		TextSize = 56,
		TextColor3 = C.accentHi,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 70),
	}, box)
	Theme.label(text, {
		TextSize = 16,
		TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 80),
	}, box)
end

local function buildAdventures()
	local area = panel("Aventuras")
	comingSoon(area, "Em breve", "Capítulos com regras próprias vão aparecer aqui.")
end

-- ===================== tela CONQUISTAS =====================

local function buildAchievements()
	local p = profile
	local done = 0
	for _ in p.achievements do
		done += 1
	end
	local area = panel(("Conquistas  %d / %d"):format(done, #Config.Achievements))
	if #Config.Achievements == 0 then
		comingSoon(area, "Nenhuma ainda", "As conquistas vão aparecer aqui.")
		return
	end
	local list = scroller({ Size = UDim2.fromScale(1, 1) }, area)
	Theme.list(list, false, 6)
	for i, ach in Config.Achievements do
		local got = p.achievements[ach.id] == true
		local row = Theme.frame({ Size = UDim2.new(1, -10, 0, 58), LayoutOrder = i, BackgroundColor3 = if got then C.panel3 else C.panel2 }, list)
		Theme.corner(row, 8)
		Theme.label(if got then "✓" else "🔒", {
			Font = Theme.NumberFont,
			TextSize = 24,
			TextColor3 = if got then C.good else C.dim,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(0, 44, 1, 0),
		}, row)
		Theme.label(ach.name, { Font = Theme.BoldFont, TextSize = 16, Size = UDim2.new(0.55, -50, 0, 24), Position = UDim2.fromOffset(48, 6) }, row)
		Theme.label(ach.desc, { TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(0.55, -50, 0, 22), Position = UDim2.fromOffset(48, 30) }, row)
		Theme.label(Content.rewardText(ach.reward), {
			TextSize = 14,
			TextColor3 = if got then C.gold else C.dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(0.45, -12, 1, 0),
			Position = UDim2.fromScale(0.55, 0),
		}, row)
	end
end

-- ===================== tela OPCOES =====================

local SKIN_OPTIONS = {
	{ id = "class", name = "Skin do personagem", desc = "Você vira o personagem escolhido (roupa, chapéu e capa dele)." },
	{ id = "own", name = "Minha skin", desc = "Você joga com o seu próprio avatar do Roblox." },
}

local function buildOptions()
	local p = profile
	local area = panel("Opções")
	local col = Theme.frame({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.new(0.8, 0, 1, -10) }, area)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(640, 2000) }, col)
	Theme.list(col, false, 10)
	Theme.label("Aparência", { Font = Theme.BoldFont, TextSize = 20, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1 }, col)
	local currentSkin = (p.settings and p.settings.skin) or Config.Meta.DefaultSkin
	for i, opt in SKIN_OPTIONS do
		local chosen = currentSkin == opt.id
		local b = Theme.button("", {
			Size = UDim2.new(1, 0, 0, 70),
			LayoutOrder = 1 + i,
			BackgroundColor3 = if chosen then C.accent else C.panel2,
		}, col)
		if chosen then
			Theme.stroke(b, C.gold, 2)
		end
		Theme.label((if chosen then "● " else "○ ") .. opt.name, { Font = Theme.BoldFont, TextSize = 18, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 8) }, b)
		Theme.label(opt.desc, { TextSize = 14, TextColor3 = if chosen then C.text else C.dim, Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 36) }, b)
		b.Activated:Connect(function()
			if not chosen then
				actions.setOption("skin", opt.id)
			end
		end)
	end
	Theme.label("A troca vale na hora, inclusive no meio da partida.", { TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 10 }, col)
end

local BUILDERS: { [string]: () -> () } = {
	title = buildTitle,
	select = buildSelect,
	shop = buildShop,
	adventures = buildAdventures,
	achievements = buildAchievements,
	options = buildOptions,
}

-- Redesenha a tela atual (barato: so acontece quando o perfil muda ou ao clicar).
function Lobby.refresh()
	if not profile then
		return
	end
	goldLabel.Text = ("%d de ouro"):format(profile.gold)
	Theme.clear(screenRoot)
	local builder = BUILDERS[current] or buildTitle
	builder()
end

local seeded = false

-- Perfil novo do servidor (ProfileSync).
function Lobby.render(data: any)
	local prev = profile
	profile = data
	-- Na PRIMEIRA vez, semeia a selecao local com a ultima escolha salva.
	-- Depois a selecao e local (o jogador clicou), e so corrige o que ficou invalido.
	if not seeded then
		seeded = true
		sel.class = data.selected.class
		sel.stage = data.selected.stage
	end
	-- personagem que ACABOU de ser comprado vira o escolhido
	if prev then
		for id, info in data.classes do
			local before = prev.classes[id]
			if info.owned and before and not before.owned then
				sel.class = id
			end
		end
	end
	-- corrige selecao que deixou de ser valida
	local cls = data.classes[sel.class]
	if not cls or not cls.owned then
		sel.class = data.selected.class
	end
	if sel.stage == "" or not data.stages[sel.stage] then
		sel.stage = data.selected.stage
	end
	Lobby.refresh()
end

function Lobby.setVisible(on: boolean)
	if on and not gui.Enabled then
		current = "title" -- voltando de uma partida: sempre pela capa
		Lobby.refresh()
	end
	gui.Enabled = on
	if on and not batsConn then
		batsConn = RunService.Heartbeat:Connect(animateBats)
	elseif not on and batsConn then
		batsConn:Disconnect()
		batsConn = nil
	end
end

function Lobby.init(parent: Instance, acts: Actions)
	actions = acts
	gui = Theme.make("ScreenGui", {
		Name = "Lobby",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = false,
	}, parent)
	buildBackground(gui)
	screenRoot = Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
	goldLabel = Theme.label("", {
		Font = Theme.NumberFont,
		TextSize = 22,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(240, 30),
		Position = UDim2.new(1, -16, 0, 10),
	}, gui)
	Theme.make("UIStroke", { Color = C.backdrop, Thickness = 2 }, goldLabel)
end

return Lobby
