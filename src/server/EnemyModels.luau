--!strict
-- Visual dos inimigos: pecas simples soldadas (WeldConstraint) num Root ancorado.
-- SEM rig e SEM animacao: o EnemyService so muda o CFrame do Root e o resto vem
-- junto. Cabecas e morcegos "flutuam" pelo codigo (seno no Y), nao por animacao.
-- Frente do inimigo = -Z (CFrame.lookAt aponta -Z para o alvo).
-- Cada forma devolve a altura do centro do Root acima do chao.
local EnemyModels = {}

local BLACK = Color3.fromRGB(15, 10, 15)
local BONE = Color3.fromRGB(225, 220, 200)
local RED_EYE = Color3.fromRGB(255, 40, 40)
local YELLOW_EYE = Color3.fromRGB(255, 220, 60)

local function newPart(size: Vector3, color: Color3, ball: boolean?): Part
	local p = Instance.new("Part")
	if ball then
		p.Shape = Enum.PartType.Ball
	end
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Solda uma peca no Root numa posicao relativa (o Root esta na origem ao montar).
local function attach(root: BasePart, part: BasePart, offset: CFrame)
	part.Anchored = false
	part.Massless = true
	part.CFrame = root.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = root.Parent
end

local function ball(root: BasePart, d: number, color: Color3, x: number, y: number, z: number, neon: boolean?): Part
	local p = newPart(Vector3.one * d, color, true)
	if neon then
		p.Material = Enum.Material.Neon
	end
	attach(root, p, CFrame.new(x, y, z))
	return p
end

local function block(root: BasePart, size: Vector3, color: Color3, x: number, y: number, z: number, rot: CFrame?): Part
	local p = newPart(size, color)
	attach(root, p, CFrame.new(x, y, z) * (rot or CFrame.identity))
	return p
end

local function darker(c: Color3, f: number): Color3
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

type Builder = (root: BasePart, s: number, color: Color3) -> number

local SHAPES: { [string]: { root: (s: number, color: Color3) -> Part, build: Builder } } = {
	skull = {
		root = function(s, color)
			return newPart(Vector3.one * 2.2 * s, color, true)
		end,
		build = function(root, s, color)
			ball(root, 0.55 * s, BLACK, -0.45 * s, 0.15 * s, -0.85 * s)
			ball(root, 0.55 * s, BLACK, 0.45 * s, 0.15 * s, -0.85 * s)
			block(root, Vector3.new(0.25, 0.3, 0.2) * s, BLACK, 0, -0.25 * s, -1.0 * s)
			block(root, Vector3.new(1.2, 0.4, 0.8) * s, darker(color, 0.85), 0, -0.95 * s, -0.35 * s)
			return 2.2 * s
		end,
	},
	bat = {
		root = function(s, color)
			return newPart(Vector3.one * 1.1 * s, color, true)
		end,
		build = function(root, s, color)
			local wing = darker(color, 0.7)
			block(root, Vector3.new(1.6, 0.12, 0.9) * s, wing, -1.2 * s, 0.15 * s, 0, CFrame.Angles(0, 0, math.rad(20)))
			block(root, Vector3.new(1.6, 0.12, 0.9) * s, wing, 1.2 * s, 0.15 * s, 0, CFrame.Angles(0, 0, math.rad(-20)))
			ball(root, 0.22 * s, RED_EYE, -0.22 * s, 0.15 * s, -0.48 * s, true)
			ball(root, 0.22 * s, RED_EYE, 0.22 * s, 0.15 * s, -0.48 * s, true)
			return 2.5 * s
		end,
	},
	skeleton = {
		root = function(s, color)
			return newPart(Vector3.new(1.2, 2.4, 0.7) * s, color)
		end,
		build = function(root, s, color)
			ball(root, 1.1 * s, BONE, 0, 1.8 * s, 0)
			ball(root, 0.28 * s, BLACK, -0.22 * s, 1.85 * s, -0.45 * s)
			ball(root, 0.28 * s, BLACK, 0.22 * s, 1.85 * s, -0.45 * s)
			local rib = darker(color, 0.6)
			block(root, Vector3.new(1.3, 0.15, 0.75) * s, rib, 0, 0.4 * s, 0)
			block(root, Vector3.new(1.3, 0.15, 0.75) * s, rib, 0, -0.1 * s, 0)
			block(root, Vector3.new(0.35, 1.1, 0.35) * s, color, -0.3 * s, -1.65 * s, 0)
			block(root, Vector3.new(0.35, 1.1, 0.35) * s, color, 0.3 * s, -1.65 * s, 0)
			return 2.3 * s
		end,
	},
	ghoul = {
		root = function(s, color)
			return newPart(Vector3.new(1.5, 2.2, 1.0) * s, color)
		end,
		build = function(root, s, color)
			ball(root, 1.1 * s, darker(color, 0.9), 0, 1.6 * s, -0.1 * s)
			ball(root, 0.2 * s, YELLOW_EYE, -0.22 * s, 1.7 * s, -0.6 * s, true)
			ball(root, 0.2 * s, YELLOW_EYE, 0.22 * s, 1.7 * s, -0.6 * s, true)
			block(root, Vector3.new(0.35, 0.35, 1.3) * s, color, -0.85 * s, 0.5 * s, -0.6 * s)
			block(root, Vector3.new(0.35, 0.35, 1.3) * s, color, 0.85 * s, 0.5 * s, -0.6 * s)
			block(root, Vector3.new(1.2, 1.0, 0.8) * s, darker(color, 0.6), 0, -1.55 * s, 0)
			return 2.1 * s
		end,
	},
	ghost = {
		root = function(s, color)
			local p = newPart(Vector3.one * 2.0 * s, color, true)
			p.Transparency = 0.3
			return p
		end,
		build = function(root, s, color)
			local tail = ball(root, 1.3 * s, color, 0, -1.1 * s, 0.3 * s)
			tail.Transparency = 0.5
			ball(root, 0.35 * s, BLACK, -0.35 * s, 0.2 * s, -0.85 * s)
			ball(root, 0.35 * s, BLACK, 0.35 * s, 0.2 * s, -0.85 * s)
			ball(root, 0.4 * s, BLACK, 0, -0.35 * s, -0.88 * s)
			return 2.8 * s
		end,
	},
	mud = {
		root = function(s, color)
			return newPart(Vector3.one * 2.8 * s, color, true)
		end,
		build = function(root, s, color)
			local lump = darker(color, 0.8)
			ball(root, 1.2 * s, lump, -1.0 * s, -0.6 * s, 0.3 * s)
			ball(root, 1.2 * s, lump, 1.0 * s, -0.6 * s, 0.3 * s)
			ball(root, 0.35 * s, YELLOW_EYE, -0.5 * s, 0.5 * s, -1.25 * s, true)
			ball(root, 0.35 * s, YELLOW_EYE, 0.5 * s, 0.5 * s, -1.25 * s, true)
			return 1.6 * s
		end,
	},
	werewolf = {
		root = function(s, color)
			return newPart(Vector3.new(1.7, 2.6, 1.1) * s, color)
		end,
		build = function(root, s, color)
			local fur = darker(color, 0.8)
			block(root, Vector3.new(1.1, 1.0, 1.4) * s, color, 0, 1.75 * s, -0.35 * s)
			block(root, Vector3.new(0.6, 0.5, 0.7) * s, fur, 0, 1.6 * s, -1.3 * s)
			block(root, Vector3.new(0.3, 0.6, 0.2) * s, fur, -0.35 * s, 2.45 * s, -0.2 * s)
			block(root, Vector3.new(0.3, 0.6, 0.2) * s, fur, 0.35 * s, 2.45 * s, -0.2 * s)
			ball(root, 0.2 * s, YELLOW_EYE, -0.3 * s, 1.9 * s, -1.06 * s, true)
			ball(root, 0.2 * s, YELLOW_EYE, 0.3 * s, 1.9 * s, -1.06 * s, true)
			block(root, Vector3.new(0.45, 1.6, 0.45) * s, fur, -1.1 * s, 0.1 * s, -0.2 * s)
			block(root, Vector3.new(0.45, 1.6, 0.45) * s, fur, 1.1 * s, 0.1 * s, -0.2 * s)
			block(root, Vector3.new(0.55, 1.2, 0.6) * s, fur, -0.45 * s, -1.9 * s, 0)
			block(root, Vector3.new(0.55, 1.2, 0.6) * s, fur, 0.45 * s, -1.9 * s, 0)
			return 2.5 * s
		end,
	},
	mummy = {
		root = function(s, color)
			return newPart(Vector3.new(1.5, 2.8, 1.0) * s, color)
		end,
		build = function(root, s, color)
			local band = darker(color, 0.75)
			ball(root, 1.2 * s, color, 0, 2.0 * s, 0)
			block(root, Vector3.new(1.55, 0.2, 1.05) * s, band, 0, 0.8 * s, 0)
			block(root, Vector3.new(1.55, 0.2, 1.05) * s, band, 0, 0, 0)
			block(root, Vector3.new(1.55, 0.2, 1.05) * s, band, 0, -0.8 * s, 0)
			ball(root, 0.2 * s, RED_EYE, -0.25 * s, 2.05 * s, -0.55 * s, true)
			ball(root, 0.2 * s, RED_EYE, 0.25 * s, 2.05 * s, -0.55 * s, true)
			block(root, Vector3.new(0.4, 0.4, 1.4) * s, color, -0.95 * s, 0.9 * s, -0.7 * s)
			block(root, Vector3.new(0.4, 0.4, 1.4) * s, color, 0.95 * s, 0.9 * s, -0.7 * s)
			block(root, Vector3.new(1.2, 1.2, 0.8) * s, band, 0, -2.0 * s, 0)
			return 2.6 * s
		end,
	},
	mantis = {
		root = function(s, color)
			return newPart(Vector3.new(0.9, 2.2, 0.9) * s, color)
		end,
		build = function(root, s, color)
			local dark = darker(color, 0.7)
			local light = Color3.new(math.min(1, color.R * 1.3), math.min(1, color.G * 1.3), math.min(1, color.B * 1.3))
			ball(root, 1.4 * s, dark, 0, -0.6 * s, 1.0 * s)
			block(root, Vector3.new(0.8, 0.6, 0.6) * s, color, 0, 1.4 * s, -0.3 * s)
			ball(root, 0.35 * s, light, -0.4 * s, 1.5 * s, -0.4 * s, true)
			ball(root, 0.35 * s, light, 0.4 * s, 1.5 * s, -0.4 * s, true)
			local pitch = CFrame.Angles(math.rad(-30), 0, 0)
			block(root, Vector3.new(0.25, 0.25, 1.8) * s, light, -0.6 * s, 0.9 * s, -0.9 * s, pitch)
			block(root, Vector3.new(0.25, 0.25, 1.8) * s, light, 0.6 * s, 0.9 * s, -0.9 * s, pitch)
			block(root, Vector3.new(0.2, 1.2, 0.2) * s, light, -0.6 * s, 0.5 * s, -1.8 * s)
			block(root, Vector3.new(0.2, 1.2, 0.2) * s, light, 0.6 * s, 0.5 * s, -1.8 * s)
			for _, x in { -0.6, 0.6 } do
				for _, z in { -0.4, 0.4 } do
					block(root, Vector3.new(0.15, 1.4, 0.15) * s, dark, x * s, -1.6 * s, z * s)
				end
			end
			return 2.4 * s
		end,
	},
	flower = {
		root = function(s, color)
			return newPart(Vector3.one * 1.8 * s, color, true)
		end,
		build = function(root, s, color)
			local green = Color3.fromRGB(50, 120, 50)
			ball(root, 0.9 * s, BLACK, 0, 0, -0.6 * s)
			block(root, Vector3.new(0.4, 2.2, 0.4) * s, green, 0, -1.7 * s, 0)
			block(root, Vector3.new(1.6, 0.15, 0.6) * s, green, -1.0 * s, -1.6 * s, 0, CFrame.Angles(0, 0, math.rad(15)))
			block(root, Vector3.new(1.6, 0.15, 0.6) * s, green, 1.0 * s, -1.6 * s, 0, CFrame.Angles(0, 0, math.rad(-15)))
			return 2.8 * s
		end,
	},
	brazier = {
		root = function(s, color)
			return newPart(Vector3.new(0.9, 2.2, 0.9) * s, color)
		end,
		build = function(root, s, color)
			block(root, Vector3.new(1.6, 0.4, 1.6) * s, darker(color, 0.7), 0, 1.2 * s, 0)
			local flame = ball(root, 1.0 * s, Color3.fromRGB(255, 140, 40), 0, 1.8 * s, 0, true)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 160, 70)
			light.Range = 16
			light.Brightness = 2
			light.Parent = flame
			return 1.1 * s
		end,
	},
	reaper = {
		root = function(s, color)
			local p = newPart(Vector3.new(2, 3.6, 1.4) * s, color)
			p.Material = Enum.Material.Fabric
			return p
		end,
		build = function(root, s, color)
			ball(root, 1.6 * s, darker(color, 1.2), 0, 2.4 * s, 0)
			ball(root, 1.1 * s, BONE, 0, 2.35 * s, -0.35 * s)
			ball(root, 0.25 * s, RED_EYE, -0.25 * s, 2.45 * s, -0.85 * s, true)
			ball(root, 0.25 * s, RED_EYE, 0.25 * s, 2.45 * s, -0.85 * s, true)
			block(root, Vector3.new(0.25, 5, 0.25) * s, Color3.fromRGB(90, 60, 40), 1.4 * s, 0.6 * s, -0.4 * s)
			local blade = block(root, Vector3.new(0.2, 0.6, 2.6) * s, Color3.fromRGB(200, 205, 215), 1.4 * s, 3.0 * s, -1.4 * s)
			blade.Material = Enum.Material.Metal
			return 1.8 * s
		end,
	},
}

local templates: { [string]: { model: Model, height: number } } = {}

-- Modelo-molde de um tipo de inimigo (montado uma vez; o EnemyService clona).
function EnemyModels.template(def: any): (Model, number)
	local cached = templates[def.id]
	if cached then
		return cached.model, cached.height
	end
	local shape = SHAPES[def.shape] or SHAPES.skeleton
	local s = def.scale or 1
	local model = Instance.new("Model")
	model.Name = def.id
	local root = shape.root(s, def.color)
	root.Name = "Root"
	root.Anchored = true
	root.CFrame = CFrame.identity
	root.Parent = model
	model.PrimaryPart = root
	local height = shape.build(root, s, def.color)
	templates[def.id] = { model = model, height = height }
	return model, height
end

return EnemyModels
