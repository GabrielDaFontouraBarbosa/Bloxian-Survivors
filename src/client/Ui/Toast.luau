--!strict
-- Avisos que somem sozinhos (canto superior direito): conquista liberada,
-- missao completa, capitulo de aventura concluido e mensagens do servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Content = require(Shared:WaitForChild("Content"))
local Theme = require(script.Parent.Theme)

local Toast = {}

local C = Theme.C
local LIFETIME = 5
local MAX_VISIBLE = 5

local gui: ScreenGui
local stack: Frame
local order = 0

local function push(titleText: string, bodyText: string, color: Color3)
	order += 1
	local items = {}
	for _, child in stack:GetChildren() do
		if child:IsA("Frame") then
			table.insert(items, child)
		end
	end
	if #items >= MAX_VISIBLE then
		table.sort(items, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		items[1]:Destroy()
	end
	local card = Theme.frame({ Size = UDim2.new(1, 0, 0, 62), LayoutOrder = order, BackgroundColor3 = C.panel }, stack)
	Theme.corner(card, 8)
	Theme.stroke(card, color, 2)
	Theme.pad(card, 8)
	Theme.label(titleText, { Font = Theme.BoldFont, TextSize = 16, TextColor3 = color, Size = UDim2.new(1, 0, 0, 20) }, card)
	Theme.label(bodyText, { TextSize = 13, TextColor3 = C.text, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 20) }, card)
	task.delay(LIFETIME, function()
		if card.Parent then
			local tween = TweenService:Create(card, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			card:Destroy()
		end
	end)
end

-- Aviso vindo do evento Toast do servidor.
function Toast.event(data: any)
	if type(data) ~= "table" then
		return
	end
	if data.kind == "achievement" then
		local ach = Content.achievements[data.id]
		if ach then
			push("🏆 Conquista: " .. ach.name, Content.rewardText(ach.reward), C.gold)
		end
	elseif data.kind == "quest" then
		local q = Content.quests[data.id]
		if q then
			push("📜 Missão completa!", q.desc .. " — resgate no lobby.", C.good)
		end
	elseif data.kind == "chapter" then
		local adv = Content.adventures[data.adventure]
		local chapter = adv and adv.chapters[data.chapter]
		if adv and chapter then
			push("📖 Capítulo concluído!", adv.name .. ": " .. chapter.name, C.accentHi)
		end
	end
end

-- Mensagem simples (Notice do servidor: "ouro insuficiente" etc.).
function Toast.notice(text: any)
	if type(text) == "string" then
		push("Aviso", text, C.dim)
	end
end

function Toast.init(parent: Instance)
	gui = Theme.make("ScreenGui", {
		Name = "Toasts",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
	}, parent)
	stack = Theme.frame({
		Size = UDim2.fromOffset(340, 400),
		Position = UDim2.new(1, -350, 0, 96),
		BackgroundTransparency = 1,
	}, gui)
	Theme.list(stack, false, 6)
end

return Toast
