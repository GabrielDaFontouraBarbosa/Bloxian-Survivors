--!strict
-- Cenario da run SO NO CLIENTE (puro visual, sem colisao): arvores (floresta)
-- ou tumulos (cemiterio) numa grade em volta do jogador. Cada celula usa um
-- hash fixo, entao o mapa infinito e sempre igual no mesmo lugar. Mais a luz de
-- lua e neblina. Ao voltar ao lobby a luz original e restaurada.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Scenery = {}

local CELL = 26 -- tamanho da celula (studs)
local RADIUS = 125 -- ate onde espalha
local DENSITY = 0.38 -- chance de ter algo na celula
local UPDATE_EVERY = 0.25

local player = Players.LocalPlayer
local folder: Folder? = nil
local active = false
local floorY = 0
local kind = "forest"
local placed: { [number]: Model } = {}
local pools: { [string]: { Model } } = {}
local savedLighting: { [string]: any }? = nil
local savedAtmosphere: { [string]: any }? = nil
local conn: RBXScriptConnection? = nil
local acc = 0

local LIGHTING_KEYS = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "FogStart", "FogEnd", "FogColor" }
local ATMOSPHERE_KEYS = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" }

-- Numero pseudo-aleatorio fixo por celula (0..1).
local function hash(x: number, z: number, salt: number): number
	local h = math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	return h - math.floor(h)
end

local function cellKey(cx: number, cz: number): number
	return (cx + 50000) * 100000 + (cz + 50000)
end

local function part(size: Vector3, color: Color3, cf: CFrame, parent: Instance, ball: boolean?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	if ball then
		p.Shape = Enum.PartType.Ball
	end
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = cf
	p.Parent = parent
	return p
end

-- Monta um objeto de cenario na origem (PrimaryPart = base).
local function build(what: string): Model
	local m = Instance.new("Model")
	if what == "tree" then
		local trunk = part(Vector3.new(1.4, 7, 1.4), Color3.fromRGB(60, 42, 30), CFrame.new(0, 3.5, 0), m, false, Enum.Material.Wood)
		m.PrimaryPart = trunk
		part(Vector3.one * 7, Color3.fromRGB(28, 52, 30), CFrame.new(0, 8.5, 0), m, true, Enum.Material.Grass)
		part(Vector3.one * 5, Color3.fromRGB(34, 62, 34), CFrame.new(1.5, 10.5, 0.8), m, true, Enum.Material.Grass)
	elseif what == "deadTree" then
		local trunk = part(Vector3.new(1.1, 8, 1.1), Color3.fromRGB(55, 48, 45), CFrame.new(0, 4, 0), m, false, Enum.Material.Wood)
		m.PrimaryPart = trunk
		part(Vector3.new(0.5, 4, 0.5), Color3.fromRGB(55, 48, 45), CFrame.new(1, 7, 0) * CFrame.Angles(0, 0, math.rad(-40)), m, false, Enum.Material.Wood)
		part(Vector3.new(0.5, 3, 0.5), Color3.fromRGB(55, 48, 45), CFrame.new(-0.9, 6, 0.3) * CFrame.Angles(0, 0, math.rad(35)), m, false, Enum.Material.Wood)
	elseif what == "grave" then
		local stone = part(Vector3.new(2.4, 3, 0.6), Color3.fromRGB(105, 105, 115), CFrame.new(0, 1.5, 0), m, false, Enum.Material.Slate)
		m.PrimaryPart = stone
		part(Vector3.new(3, 0.3, 4), Color3.fromRGB(60, 55, 50), CFrame.new(0, 0.15, 1.6), m, false, Enum.Material.Ground)
	else -- "bush"
		local bush = part(Vector3.one * 3, Color3.fromRGB(30, 58, 32), CFrame.new(0, 1.2, 0), m, true, Enum.Material.Grass)
		m.PrimaryPart = bush
	end
	return m
end

-- O que nasce numa celula, por estagio.
local function pick(r: number): string
	if kind == "graves" then
		return if r < 0.6 then "grave" else "deadTree"
	end
	return if r < 0.75 then "tree" else "bush"
end

local function acquire(what: string): Model
	local pool = pools[what]
	local m = pool and table.remove(pool)
	if not m then
		m = build(what)
		m:SetAttribute("kind", what)
	end
	return m :: Model
end

local function releaseModel(m: Model)
	m.Parent = nil
	local what = m:GetAttribute("kind") :: string
	local pool = pools[what]
	if not pool then
		pool = {}
		pools[what] = pool
	end
	table.insert(pool, m)
end

local function refresh()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or not folder then
		return
	end
	local pos = root.Position
	local cx0, cz0 = math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
	local span = math.ceil(RADIUS / CELL)
	local wanted: { [number]: boolean } = {}
	for cx = cx0 - span, cx0 + span do
		for cz = cz0 - span, cz0 + span do
			local dx, dz = (cx - cx0) * CELL, (cz - cz0) * CELL
			if dx * dx + dz * dz <= RADIUS * RADIUS and hash(cx, cz, 1) < DENSITY then
				local key = cellKey(cx, cz)
				wanted[key] = true
				if not placed[key] then
					local m = acquire(pick(hash(cx, cz, 2)))
					local x = (cx + 0.2 + hash(cx, cz, 3) * 0.6) * CELL
					local z = (cz + 0.2 + hash(cx, cz, 4) * 0.6) * CELL
					local turn = hash(cx, cz, 5) * math.pi * 2
					-- o pivo e o centro da PrimaryPart; sobe metade dela para a base ficar no chao
					local lift = m.PrimaryPart and m.PrimaryPart.Size.Y / 2 or 0
					m:PivotTo(CFrame.new(x, floorY + lift, z) * CFrame.Angles(0, turn, 0))
					m.Parent = folder
					placed[key] = m
				end
			end
		end
	end
	for key, m in placed do
		if not wanted[key] then
			releaseModel(m)
			placed[key] = nil
		end
	end
end

local function saveAndSetLighting(stage: string)
	savedLighting = {}
	for _, key in LIGHTING_KEYS do
		(savedLighting :: any)[key] = (Lighting :: any)[key]
	end
	Lighting.ClockTime = 0
	Lighting.Brightness = 1.2
	Lighting.Ambient = Color3.fromRGB(50, 45, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 55, 85)
	Lighting.FogStart = 70
	Lighting.FogEnd = 230
	Lighting.FogColor = if stage == "graves" then Color3.fromRGB(25, 25, 32) else Color3.fromRGB(12, 14, 20)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		savedAtmosphere = {}
		for _, key in ATMOSPHERE_KEYS do
			(savedAtmosphere :: any)[key] = (atmosphere :: any)[key]
		end
		atmosphere.Density = 0.42
		atmosphere.Offset = 0
		atmosphere.Color = Color3.fromRGB(25, 22, 40)
		atmosphere.Decay = Color3.fromRGB(15, 10, 30)
		atmosphere.Glare = 0
		atmosphere.Haze = 2
	end
end

local function restoreLighting()
	if savedLighting then
		for key, value in savedLighting do
			(Lighting :: any)[key] = value
		end
		savedLighting = nil
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere and savedAtmosphere then
		for key, value in savedAtmosphere do
			(atmosphere :: any)[key] = value
		end
	end
	savedAtmosphere = nil
end

-- Entrou na run: espalha o cenario do estagio e escurece a luz.
function Scenery.enter(stageScenery: string, y: number)
	Scenery.leave()
	active = true
	kind = stageScenery
	floorY = y
	local f = Instance.new("Folder")
	f.Name = "Scenery"
	f.Parent = workspace
	folder = f
	saveAndSetLighting(stageScenery)
	acc = UPDATE_EVERY
	conn = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= UPDATE_EVERY then
			acc = 0
			refresh()
		end
	end)
end

-- Saiu da run: some com o cenario e devolve a luz do lobby.
function Scenery.leave()
	if not active then
		return
	end
	active = false
	if conn then
		conn:Disconnect()
		conn = nil
	end
	for key, m in placed do
		releaseModel(m)
		placed[key] = nil
	end
	if folder then
		folder:Destroy()
		folder = nil
	end
	restoreLighting()
end

return Scenery
