--!strict
-- Visual compartilhado da interface: paleta gotica (DESIGN.md secao 0) e
-- construtores de GUI para os modulos de tela nao repetirem propriedade.
local Theme = {}

Theme.C = {
	backdrop = Color3.fromRGB(5, 3, 8),
	panel = Color3.fromRGB(22, 17, 28),
	panel2 = Color3.fromRGB(34, 26, 42),
	panel3 = Color3.fromRGB(50, 38, 60),
	border = Color3.fromRGB(95, 60, 85),
	accent = Color3.fromRGB(175, 25, 50),
	accentHi = Color3.fromRGB(225, 60, 85),
	gold = Color3.fromRGB(255, 205, 70),
	text = Color3.fromRGB(236, 228, 240),
	dim = Color3.fromRGB(160, 145, 170),
	good = Color3.fromRGB(90, 200, 110),
	bad = Color3.fromRGB(225, 75, 75),
	xp = Color3.fromRGB(80, 200, 255),
	hp = Color3.fromRGB(205, 40, 55),
	locked = Color3.fromRGB(75, 68, 82),
}

-- Fonte gotica se existir nesta versao do Roblox; senao cai para uma segura.
local function font(name: string, fallback: Enum.Font): Enum.Font
	local ok, value = pcall(function()
		return (Enum.Font :: any)[name]
	end)
	return if ok and value then value else fallback
end

Theme.TitleFont = font("GrenzeGotisch", Enum.Font.Fantasy)
Theme.BodyFont = Enum.Font.Gotham
Theme.BoldFont = Enum.Font.GothamBold
Theme.NumberFont = Enum.Font.GothamBlack

-- Cria uma instancia com propriedades e pai.
function Theme.make(className: string, props: { [string]: any }?, parent: Instance?): any
	local inst = Instance.new(className)
	if props then
		for key, value in props do
			(inst :: any)[key] = value
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Theme.corner(parent: Instance, radius: number?)
	Theme.make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?)
	Theme.make("UIStroke", {
		Color = color or Theme.C.border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

function Theme.pad(parent: Instance, px: number)
	Theme.make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	}, parent)
end

function Theme.list(parent: Instance, horizontal: boolean?, padding: number?): UIListLayout
	return Theme.make("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parent)
end

function Theme.frame(props: { [string]: any }?, parent: Instance?): Frame
	local f = Theme.make("Frame", { BackgroundColor3 = Theme.C.panel, BorderSizePixel = 0 }, parent)
	if props then
		for key, value in props do
			(f :: any)[key] = value
		end
	end
	return f
end

function Theme.label(text: string, props: { [string]: any }?, parent: Instance?): TextLabel
	local l = Theme.make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.C.text,
		Font = Theme.BodyFont,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
	if props then
		for key, value in props do
			(l :: any)[key] = value
		end
	end
	return l
end

function Theme.button(text: string, props: { [string]: any }?, parent: Instance?): TextButton
	local b = Theme.make("TextButton", {
		Text = text,
		BackgroundColor3 = Theme.C.panel3,
		BorderSizePixel = 0,
		TextColor3 = Theme.C.text,
		Font = Theme.BoldFont,
		TextSize = 16,
		AutoButtonColor = true,
		TextWrapped = true,
	}, parent)
	if props then
		for key, value in props do
			(b :: any)[key] = value
		end
	end
	Theme.corner(b, 6)
	return b
end

-- Barra de progresso. Devolve o frame de fundo e uma funcao set(ratio).
function Theme.bar(props: { [string]: any }, color: Color3, parent: Instance?): (Frame, (number) -> ())
	local bg = Theme.frame(props, parent)
	bg.BackgroundColor3 = Theme.C.backdrop
	Theme.corner(bg, 4)
	local fill = Theme.frame({ Size = UDim2.fromScale(0, 1), BackgroundColor3 = color }, bg)
	Theme.corner(fill, 4)
	local function set(ratio: number)
		fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	end
	return bg, set
end

-- Limpa os filhos de um container, menos os layouts/paddings.
function Theme.clear(container: Instance)
	for _, child in container:GetChildren() do
		if not child:IsA("UIComponent") then
			child:Destroy()
		end
	end
end

-- "mm:ss"
function Theme.clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	return ("%02d:%02d"):format(s // 60, s % 60)
end

return Theme
