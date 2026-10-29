--!strict
-- Lobby (a "cidade" provisoria ate existir o mapa 3D): tudo fora da partida.
--   Jogar      -> classe, estagio, arcano e o botao JOGAR
--   PowerUps   -> loja permanente (so aqui, nunca dentro da run)
--   Conquistas -> lista com o que cada uma libera
--   Missoes    -> 3 objetivos sem prazo, resgate de ouro
--   Aventuras  -> capitulos com regras proprias
-- So mostra e pede: o servidor valida tudo (MetaService/RunManager).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
}

local C = Theme.C

local gui: ScreenGui
local content: Frame
local goldLabel: TextLabel
local tabButtons: { [string]: TextButton } = {}
local actions: Actions
local profile: any = nil
local current = "play"
local sel = { class = "", stage = "", arcana = "" }

-- Quem libera cada coisa (para o texto de "bloqueado").
local requirement: { [string]: { [string]: any } } = {}
for _, ach in Config.Achievements do
	local r = ach.reward
	if r and r.kind ~= "gold" and r.id then
		requirement[r.kind] = requirement[r.kind] or {}
		requirement[r.kind][r.id] = ach
	end
end

local function lockText(kind: string, id: string): string
	local ach = requirement[kind] and requirement[kind][id]
	if ach then
		return "🔒 " .. ach.desc
	end
	return "🔒 Bloqueado"
end

local function title(text: string, parent: Instance, order: number?): TextLabel
	return Theme.label(text, {
		Font = Theme.TitleFont,
		TextSize = 28,
		TextColor3 = C.gold,
		Size = UDim2.new(1, 0, 0, 34),
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

-- ===================== aba JOGAR =====================

local function buildPlay()
	local p = profile
	local left = Theme.frame({ Size = UDim2.new(0.56, -6, 1, 0), BackgroundColor3 = C.panel2 }, content)
	Theme.corner(left, 10)
	Theme.pad(left, 10)
	title("Classes", left)
	local grid = scroller({ Size = UDim2.new(1, 0, 1, -40), Position = UDim2.fromOffset(0, 40) }, left)
	Theme.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 120),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	for i, def in Config.Classes do
		local info = p.classes[def.id] or {}
		local selected = sel.class == def.id
		local card = Theme.button("", { LayoutOrder = i, BackgroundColor3 = if selected then C.accent else C.panel3 }, grid)
		if selected then
			Theme.stroke(card, C.gold, 2)
		end
		Theme.frame({ Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = def.color }, card)
		Theme.label(def.name, { Font = Theme.BoldFont, TextSize = 17, Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 10) }, card)
		local weapon = Content.weapons[def.weapon]
		Theme.label("Arma: " .. (weapon and weapon.name or "?"), { TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(6, 34) }, card)
		local status: string
		local statusColor = C.text
		if info.owned then
			status = if selected then "✓ Selecionada" else "Selecionar"
		elseif info.unlocked then
			status = ("Comprar · %d ouro"):format(def.price)
			statusColor = if p.gold >= def.price then C.gold else C.bad
		else
			status = lockText("class", def.id)
			statusColor = C.dim
		end
		Theme.label(status, { TextSize = 12, TextColor3 = statusColor, Size = UDim2.new(1, -12, 0, 56), Position = UDim2.fromOffset(6, 56), TextYAlignment = Enum.TextYAlignment.Top }, card)
		card.Activated:Connect(function()
			if info.owned then
				sel.class = def.id
				Lobby.refresh()
			elseif info.unlocked then
				actions.buyClass(def.id)
			end
		end)
	end

	-- coluna da direita: detalhes, estagio, arcano, JOGAR
	local right = Theme.frame({ Size = UDim2.new(0.44, -6, 1, 0), Position = UDim2.new(0.56, 6, 0, 0), BackgroundColor3 = C.panel2 }, content)
	Theme.corner(right, 10)
	Theme.pad(right, 10)
	local info = scroller({ Size = UDim2.new(1, 0, 1, -66) }, right)
	Theme.list(info, false, 6)

	local def = Content.classes[sel.class]
	if def then
		title(def.name, info, 1)
		Theme.label(def.desc, { TextSize = 14, TextColor3 = C.dim, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 2 }, info)
		local weapon = Content.weapons[def.weapon]
		if weapon then
			Theme.label(("Arma inicial: %s — %s"):format(weapon.name, weapon.desc), { TextSize = 14, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 3 }, info)
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
		Theme.label(table.concat(lines, "\n"), { TextSize = 14, TextColor3 = C.good, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 4 }, info)
	end

	-- estagio
	Theme.label("Estágio", { Font = Theme.BoldFont, TextSize = 18, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 10 }, info)
	local stageRow = Theme.frame({ Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 11 }, info)
	Theme.list(stageRow, true, 6)
	for i, stage in Config.Stages do
		local unlocked = p.stages[stage.id] == true
		local chosen = sel.stage == stage.id
		local b = Theme.button(if unlocked then stage.name else "🔒 " .. stage.name, {
			Size = UDim2.new(0.5, -4, 1, 0),
			LayoutOrder = i,
			TextSize = 14,
			BackgroundColor3 = if chosen then C.accent elseif unlocked then C.panel3 else C.locked,
		}, stageRow)
		b.Activated:Connect(function()
			if unlocked then
				sel.stage = stage.id
				Lobby.refresh()
			end
		end)
	end
	local stageDef = Content.stages[sel.stage]
	local stageText = stageDef and stageDef.desc or ""
	for _, stage in Config.Stages do
		if not p.stages[stage.id] then
			stageText ..= ("\n%s: %s"):format(stage.name, lockText("stage", stage.id))
		end
	end
	Theme.label(stageText, { TextSize = 13, TextColor3 = C.dim, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 12 }, info)

	-- arcano
	Theme.label("Arcano", { Font = Theme.BoldFont, TextSize = 18, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 20 }, info)
	local arcRow = scroller({ Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 21, AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X }, info)
	Theme.list(arcRow, true, 6)
	local options = { { id = "", name = "Nenhum" } }
	for _, arc in Config.Arcanas do
		table.insert(options, arc)
	end
	for i, arc in options do
		local unlocked = arc.id == "" or p.arcanas[arc.id] == true
		local chosen = sel.arcana == arc.id
		local b = Theme.button(if unlocked then arc.name else "🔒", {
			Size = UDim2.fromOffset(if unlocked then 150 else 44, 36),
			LayoutOrder = i,
			TextSize = 13,
			BackgroundColor3 = if chosen then C.accent elseif unlocked then C.panel3 else C.locked,
		}, arcRow)
		b.Activated:Connect(function()
			if unlocked then
				sel.arcana = arc.id
				Lobby.refresh()
			end
		end)
	end
	local arcDef = Content.arcanas[sel.arcana]
	Theme.label(if arcDef then arcDef.desc else "Sem arcano: regras normais.", { TextSize = 13, TextColor3 = C.dim, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 22 }, info)

	local play = Theme.button("JOGAR", {
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.new(0, 0, 1, -56),
		BackgroundColor3 = C.accent,
		Font = Theme.TitleFont,
		TextSize = 34,
	}, right)
	Theme.stroke(play, C.gold, 2)
	play.Activated:Connect(function()
		actions.start({ class = sel.class, stage = sel.stage, arcana = sel.arcana })
	end)
end

-- ===================== aba POWERUPS =====================

local function buildShop()
	local p = profile
	Theme.label(("PowerUps valem para sempre, em todas as classes. Cada compra encarece os próximos em %d%%. O reembolso devolve todo o ouro."):format(math.floor(Config.Meta.PowerUpMarkup * 100 + 0.5)), {
		TextSize = 14,
		TextColor3 = C.dim,
		Size = UDim2.new(1, 0, 0, 40),
	}, content)
	local grid = scroller({ Size = UDim2.new(1, 0, 1, -100), Position = UDim2.fromOffset(0, 44) }, content)
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
	local footer = Theme.frame({ Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44), BackgroundTransparency = 1 }, content)
	Theme.label(("Total investido: %d de ouro"):format(p.spent), { TextSize = 15, Size = UDim2.new(0.6, 0, 1, 0) }, footer)
	local refund = Theme.button("Reembolsar tudo", { Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.fromScale(0.7, 0), BackgroundColor3 = C.panel3 }, footer)
	refund.Activated:Connect(function()
		actions.refund()
	end)
end

-- ===================== aba CONQUISTAS =====================

local function buildAchievements()
	local p = profile
	local done = 0
	for _ in p.achievements do
		done += 1
	end
	title(("Conquistas: %d / %d"):format(done, #Config.Achievements), content)
	local list = scroller({ Size = UDim2.new(1, 0, 1, -40), Position = UDim2.fromOffset(0, 40) }, content)
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

-- ===================== aba MISSOES =====================

local function buildQuests()
	local p = profile
	title("Missões", content)
	Theme.label("Sem prazo: complete no seu ritmo e resgate o ouro aqui.", { TextSize = 14, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 34) }, content)
	local col = Theme.frame({ Size = UDim2.new(0.62, -6, 1, -64), Position = UDim2.fromOffset(0, 62), BackgroundTransparency = 1 }, content)
	Theme.list(col, false, 8)
	for i, q in p.quests do
		local def = Content.quests[q.id]
		if not def then
			continue
		end
		local card = Theme.frame({ Size = UDim2.new(1, 0, 0, 96), LayoutOrder = i, BackgroundColor3 = C.panel2 }, col)
		Theme.corner(card, 8)
		Theme.pad(card, 10)
		Theme.label(def.desc, { Font = Theme.BoldFont, TextSize = 16, Size = UDim2.new(0.7, 0, 0, 22) }, card)
		Theme.label(("+%d ouro"):format(def.reward), { Font = Theme.NumberFont, TextSize = 16, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.3, 0, 0, 22), Position = UDim2.fromScale(0.7, 0) }, card)
		local _, setBar = Theme.bar({ Size = UDim2.new(0.7, -10, 0, 14), Position = UDim2.fromOffset(0, 34) }, if q.done then C.good else C.xp, card)
		setBar(q.progress / def.n)
		Theme.label(("%d / %d"):format(q.progress, def.n), { TextSize = 13, TextColor3 = C.dim, Size = UDim2.new(0.7, 0, 0, 18), Position = UDim2.fromOffset(0, 52) }, card)
		local claim = Theme.button(if q.done then "Resgatar" else "Em andamento", {
			Size = UDim2.new(0.28, 0, 0, 34),
			Position = UDim2.new(0.72, 0, 0, 36),
			TextSize = 14,
			BackgroundColor3 = if q.done then C.good else C.locked,
			AutoButtonColor = q.done,
		}, card)
		claim.Activated:Connect(function()
			if q.done then
				actions.claimQuest(i)
			end
		end)
	end

	local box = Theme.frame({ Size = UDim2.new(0.38, -6, 0, 200), Position = UDim2.new(0.62, 6, 0, 62), BackgroundColor3 = C.panel2 }, content)
	Theme.corner(box, 8)
	Theme.pad(box, 12)
	local s = p.stats
	Theme.label(
		("Suas marcas\n\nAbates: %d\nPartidas: %d\nMelhor tempo: %d min\nMelhor nível: %d\nOuro total: %d"):format(s.kills, s.runs, s.bestMinutes, s.bestLevel, s.goldTotal),
		{ TextSize = 15, Size = UDim2.fromScale(1, 1), TextYAlignment = Enum.TextYAlignment.Top },
		box
	)
end

-- ===================== aba AVENTURAS =====================

local function buildAdventures()
	local p = profile
	local list = scroller({ Size = UDim2.fromScale(1, 1) }, content)
	Theme.list(list, false, 10)
	for i, adv in Config.Adventures do
		local info = p.adventures[adv.id] or { unlocked = false, done = 0 }
		local box = Theme.frame({ Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, BackgroundColor3 = C.panel2 }, list)
		Theme.corner(box, 10)
		Theme.pad(box, 10)
		Theme.list(box, false, 6)
		title(adv.name, box, 1)
		Theme.label(adv.desc, { TextSize = 14, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 2 }, box)
		if not info.unlocked then
			Theme.label(lockText("adventure", adv.id), { TextSize = 14, TextColor3 = C.dim, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 3 }, box)
			continue
		end
		for c, chapter in adv.chapters do
			local row = Theme.frame({ Size = UDim2.new(1, 0, 0, 64), LayoutOrder = 10 + c, BackgroundColor3 = C.panel3 }, box)
			Theme.corner(row, 8)
			Theme.pad(row, 8)
			local forced = chapter.class and Content.classes[chapter.class]
			local extra = ("Tempo: %d min"):format(math.floor(chapter.duration / 60))
			if forced then
				extra ..= " · Classe: " .. forced.name
			end
			if chapter.reward and chapter.reward.gold then
				extra ..= (" · +%d ouro"):format(chapter.reward.gold)
			end
			Theme.label(chapter.name, { Font = Theme.BoldFont, TextSize = 15, Size = UDim2.new(0.7, 0, 0, 20) }, row)
			Theme.label(chapter.desc .. "  (" .. extra .. ")", { TextSize = 12, TextColor3 = C.dim, Size = UDim2.new(0.7, 0, 0, 28), Position = UDim2.fromOffset(0, 20) }, row)
			local completed = c <= info.done
			local playable = c <= info.done + 1
			local b = Theme.button(if completed then "✓ Jogar de novo" elseif playable then "Jogar" else "🔒", {
				Size = UDim2.new(0.28, 0, 1, 0),
				Position = UDim2.fromScale(0.72, 0),
				TextSize = 14,
				BackgroundColor3 = if playable and not completed then C.accent elseif playable then C.panel2 else C.locked,
				AutoButtonColor = playable,
			}, row)
			b.Activated:Connect(function()
				if playable then
					actions.start({ adventure = adv.id, chapter = c, class = sel.class, arcana = sel.arcana })
				end
			end)
		end
	end
end

local BUILDERS: { [string]: () -> () } = {
	play = buildPlay,
	shop = buildShop,
	achievements = buildAchievements,
	quests = buildQuests,
	adventures = buildAdventures,
}

-- Redesenha a aba atual (barato: so acontece quando o perfil muda ou ao clicar).
function Lobby.refresh()
	if not profile then
		return
	end
	goldLabel.Text = ("%d de ouro"):format(profile.gold)
	for id, b in tabButtons do
		b.BackgroundColor3 = if id == current then C.accent else C.panel3
	end
	Theme.clear(content)
	BUILDERS[current]()
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
		sel.arcana = data.selected.arcana or ""
	end
	-- classe que ACABOU de ser comprada vira a selecionada
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
	if sel.arcana ~= "" and not data.arcanas[sel.arcana] then
		sel.arcana = "" -- arcano que nao esta mais liberado; "" (Nenhum) e sempre valido
	end
	Lobby.refresh()
end

function Lobby.setVisible(on: boolean)
	gui.Enabled = on
end

function Lobby.init(parent: Instance, acts: Actions)
	actions = acts
	gui = Theme.make("ScreenGui", {
		Name = "Lobby",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, parent)
	local backdrop = Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.backdrop, BackgroundTransparency = 0.35 }, gui)
	local panel = Theme.frame({
		Size = UDim2.fromScale(0.95, 0.92),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.panel,
	}, backdrop)
	Theme.corner(panel, 12)
	Theme.stroke(panel, C.border, 2)
	Theme.make("UISizeConstraint", { MaxSize = Vector2.new(1120, 720) }, panel)

	local header = Theme.frame({ Size = UDim2.new(1, -24, 0, 54), Position = UDim2.fromOffset(12, 8), BackgroundTransparency = 1 }, panel)
	Theme.label("BLOXIAN SURVIVORS", { Font = Theme.TitleFont, TextSize = 40, TextColor3 = C.accentHi, Size = UDim2.new(0.65, 0, 1, 0) }, header)
	goldLabel = Theme.label("", {
		Font = Theme.NumberFont,
		TextSize = 22,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(0.35, 0, 1, 0),
		Position = UDim2.fromScale(0.65, 0),
	}, header)

	local tabsRow = Theme.frame({ Size = UDim2.new(1, -24, 0, 38), Position = UDim2.fromOffset(12, 66), BackgroundTransparency = 1 }, panel)
	Theme.list(tabsRow, true, 6)
	local tabs = {
		{ id = "play", name = "Jogar" },
		{ id = "shop", name = "PowerUps" },
		{ id = "achievements", name = "Conquistas" },
		{ id = "quests", name = "Missões" },
		{ id = "adventures", name = "Aventuras" },
	}
	for i, tab in tabs do
		local b = Theme.button(tab.name, { Size = UDim2.new(0.2, -5, 1, 0), LayoutOrder = i, TextSize = 16 }, tabsRow)
		tabButtons[tab.id] = b
		b.Activated:Connect(function()
			current = tab.id
			Lobby.refresh()
		end)
	end

	content = Theme.frame({
		Size = UDim2.new(1, -24, 1, -124),
		Position = UDim2.fromOffset(12, 112),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, panel)
end

return Lobby
