--!strict
-- Tela de fim de run: como acabou, tempo, nivel, abates, ouro levado para casa,
-- armas finais e conquistas liberadas. "Voltar ao lobby" fecha.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Content = require(Shared:WaitForChild("Content"))
local Theme = require(script.Parent.Theme)

local Results = {}

local C = Theme.C

local gui: ScreenGui
local titleLabel: TextLabel
local body: TextLabel
local onClose: () -> ()

local TITLES = {
	completed = { "VOCÊ SOBREVIVEU!", C.gold },
	death = { "VOCÊ CAIU", C.bad },
	abandon = { "VOCÊ DESISTIU", C.dim },
}

function Results.show(data: any)
	gui.Enabled = true
	local t = TITLES[data.reason] or TITLES.death
	titleLabel.Text = t[1]
	titleLabel.TextColor3 = t[2]

	local stage = Content.stages[data.stage]
	local class = Content.classes[data.class]
	local lines = {
		("Estágio: %s   ·   Classe: %s"):format(stage and stage.name or "?", class and class.name or "?"),
		("Tempo: %s   ·   Nível: %d   ·   Abates: %d"):format(Theme.clock(data.time), data.level, data.kills),
		("Ouro levado para casa: +%d"):format(data.gold),
	}
	if data.adventure then
		local adv = Content.adventures[data.adventure]
		local chapter = adv and adv.chapters[data.chapter or 0]
		local status = if data.chapterDone then "concluído!" elseif data.completed then "repetido" else "não concluído"
		table.insert(lines, ("Aventura: %s — %s (%s)"):format(adv and adv.name or "?", chapter and chapter.name or "?", status))
	end
	local weapons = {}
	for _, w in data.weapons or {} do
		local def = Content.weapons[w.id]
		if def then
			table.insert(weapons, if def.evolved then def.name .. " ★" else ("%s %d"):format(def.name, w.level))
		end
	end
	if #weapons > 0 then
		table.insert(lines, "Armas: " .. table.concat(weapons, ", "))
	end
	local achievements = {}
	for _, id in data.achievements or {} do
		local ach = Content.achievements[id]
		if ach then
			table.insert(achievements, ("🏆 %s — %s"):format(ach.name, Content.rewardText(ach.reward)))
		end
	end
	if #achievements > 0 then
		table.insert(lines, "")
		table.insert(lines, "Conquistas nesta partida:")
		for _, text in achievements do
			table.insert(lines, text)
		end
	end
	body.Text = table.concat(lines, "\n")
end

function Results.hide()
	if gui then
		gui.Enabled = false
	end
end

function Results.init(parent: Instance, close: () -> ())
	onClose = close
	gui = Theme.make("ScreenGui", {
		Name = "Results",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 15,
		Enabled = false,
	}, parent)
	Theme.frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.backdrop, BackgroundTransparency = 0.25 }, gui)
	local panel = Theme.frame({
		Size = UDim2.fromOffset(620, 460),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.panel,
	}, gui)
	Theme.corner(panel, 12)
	Theme.stroke(panel, C.border, 2)
	Theme.pad(panel, 16)
	titleLabel = Theme.label("", {
		Font = Theme.TitleFont,
		TextSize = 44,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 52),
	}, panel)
	body = Theme.label("", {
		TextSize = 16,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 1, -116),
		Position = UDim2.fromOffset(0, 60),
	}, panel)
	local button = Theme.button("Voltar ao lobby", {
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -44),
		BackgroundColor3 = C.accent,
		TextSize = 18,
	}, panel)
	button.Activated:Connect(function()
		Results.hide()
		onClose()
	end)
end

return Results
