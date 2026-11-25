--!strict
-- Visual das armas no CLIENTE (o acerto e decidido no servidor; aqui e so efeito).
-- Hoje: o chicote.
--   * modelo na mao (cabo + rolo do laco) enquanto o jogador tem um chicote na run
--   * chicotada: o laco sai da mao, se desenrola numa onda e ESTALA na ponta
--     (clarão + som), depois recolhe; o braco direito sobe e desce junto
-- Pecas locais (so este jogador ve), reaproveitadas em pool. Cores e sons vem do
-- campo `fx` da arma em Config/Weapons.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Content = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Content"))

local WeaponFx = {}

local player = Players.LocalPlayer

local SEGMENTS = 12 -- gomos do laco
local SWING_TIME = 0.26 -- s ate o estalo terminar de esticar
local RETRACT_TIME = 0.14 -- s recolhendo
local CRACK_AT = 0.78 -- fracao do golpe em que a ponta estala
local CRACK_TIME = 0.14 -- s do clarao na ponta
local LASH_HEIGHT = 1.4 -- altura da ponta acima do chao

type Swing = {
	parts: { Part },
	flash: Part?,
	t: number,
	dir: Vector3,
	side: Vector3,
	length: number,
	width: number,
	floorY: number,
	fx: any,
	cracked: boolean,
	crackT: number,
}

local folder: Folder? = nil
local freeParts: { Part } = {}
local swings: { Swing } = {}
local holding: string? = nil -- id da arma de chicote que esta na mao (nil = nenhuma)
local holdModel: Model? = nil
local shoulderBase: { [Motor6D]: CFrame } = {}
local armSwingT = -1 -- tempo da animacao do braco (-1 = parado)
local sounds: { [string]: { Sound } } = {}
local soundNext: { [string]: number } = {}

-- ====== pool de pecas locais ======

local function getFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "LocalWeaponFx"
	f.Parent = workspace
	folder = f
	return f
end

local function takePart(color: Color3, material: Enum.Material): Part
	local p = table.remove(freeParts)
	if not p then
		local np = Instance.new("Part")
		np.Anchored = true
		np.CanCollide = false
		np.CanQuery = false
		np.CanTouch = false
		np.CastShadow = false
		np.TopSurface = Enum.SurfaceType.Smooth
		np.BottomSurface = Enum.SurfaceType.Smooth
		p = np
	end
	local part = p :: Part
	part.Shape = Enum.PartType.Block
	part.Color = color
	part.Material = material
	part.Transparency = 0
	part.Parent = getFolder()
	return part
end

local function giveBack(part: Part)
	part.Parent = nil
	table.insert(freeParts, part)
end

-- ====== som ======

-- Toca um som nao-posicional (a camera fica longe do boneco). Pequeno rodizio
-- de Sounds por id para os golpes poderem se sobrepor.
local function play(id: string?, volume: number, pitch: number)
	if not id or id == "" then
		return
	end
	local list = sounds[id]
	if not list then
		list = {}
		for _ = 1, 4 do
			local s = Instance.new("Sound")
			s.SoundId = id
			s.Parent = SoundService
			table.insert(list, s)
		end
		sounds[id] = list
		soundNext[id] = 1
	end
	local i = soundNext[id]
	soundNext[id] = (i % #list) + 1
	local s = list[i]
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.TimePosition = 0
	s:Play()
end

-- ====== corpo do jogador ======

local function bodyPart(char: Model, r15: string, r6: string): BasePart?
	local p = char:FindFirstChild(r15) or char:FindFirstChild(r6)
	return if p and p:IsA("BasePart") then p else nil
end

local function rightShoulder(char: Model): Motor6D?
	local arm = char:FindFirstChild("RightUpperArm")
	local m = arm and arm:FindFirstChild("RightShoulder")
	if not m then
		local torso = char:FindFirstChild("Torso")
		m = torso and torso:FindFirstChild("Right Shoulder")
	end
	return if m and m:IsA("Motor6D") then m else nil
end

local function handPos(char: Model): Vector3?
	local hand = bodyPart(char, "RightHand", "Right Arm")
	if hand then
		return if hand.Name == "Right Arm" then (hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0)).Position else hand.Position
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- Angulo do ombro (rad, em torno do X do ombro) ao longo do golpe: sobe por cima
-- da cabeca, desce com forca para a frente e volta ao normal.
local function armAngle(t: number): number
	local total = SWING_TIME + RETRACT_TIME + 0.1
	local p = t / total
	if p < 0.3 then
		return math.rad(150) * (p / 0.3)
	elseif p < 0.6 then
		return math.rad(150 - 100 * ((p - 0.3) / 0.3))
	elseif p < 1 then
		return math.rad(50) * (1 - (p - 0.6) / 0.4)
	end
	return 0
end

local function updateArm(char: Model, dt: number)
	local motor = rightShoulder(char)
	if not motor then
		return
	end
	local base = shoulderBase[motor]
	if not base then
		base = motor.C0
		shoulderBase[motor] = base
	end
	if armSwingT < 0 then
		return
	end
	armSwingT += dt
	local angle = armAngle(armSwingT)
	motor.C0 = base * CFrame.Angles(angle, 0, 0)
	if angle == 0 then
		armSwingT = -1
	end
end

-- ====== chicote na mao ======

local function removeHold()
	if holdModel then
		holdModel:Destroy()
		holdModel = nil
	end
end

local function weld(part: BasePart, to: BasePart, offset: CFrame)
	part.Anchored = false
	part.Massless = true
	part.CFrame = to.CFrame * offset
	local w = Instance.new("Weld")
	w.Part0 = to
	w.Part1 = part
	w.C0 = offset
	w.Parent = part
end

local function newPiece(model: Model, size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function buildHold(char: Model, fx: any)
	removeHold()
	local hand = bodyPart(char, "RightHand", "Right Arm")
	if not hand then
		return
	end
	local model = Instance.new("Model")
	model.Name = "WhipInHand"
	-- cabo: sai da mao para a frente, com pomo na ponta de tras
	local grip = if hand.Name == "Right Arm" then CFrame.new(0, -hand.Size.Y / 2, 0) else CFrame.new(0, -0.1, 0)
	local handle = newPiece(model, Vector3.new(0.28, 0.28, 1.3), fx.handle, Enum.Material.Wood)
	weld(handle, hand, grip * CFrame.new(0, 0, -0.35))
	local pommel = newPiece(model, Vector3.one * 0.42, fx.crack, Enum.Material.Metal, Enum.PartType.Ball)
	weld(pommel, hand, grip * CFrame.new(0, 0, 0.35))
	-- rolo do laco pendurado embaixo da mao (some durante a chicotada)
	for i = 1, 3 do
		local ring = newPiece(model, Vector3.new(0.14, 1.1 - i * 0.12, 1.1 - i * 0.12), fx.lash, Enum.Material.Fabric, Enum.PartType.Cylinder)
		ring.Name = "Coil"
		weld(ring, hand, grip * CFrame.new(0.05 * i, -0.55 - i * 0.08, -0.2) * CFrame.Angles(0, math.rad(90 + i * 12), math.rad(8)))
	end
	model.Parent = char
	holdModel = model
end

local function setCoilVisible(on: boolean)
	if not holdModel then
		return
	end
	for _, p in holdModel:GetChildren() do
		if p.Name == "Coil" and p:IsA("BasePart") then
			p.Transparency = if on then 0 else 1
		end
	end
end

-- ====== chicotada ======

local function easeOut(x: number): number
	local c = 1 - math.clamp(x, 0, 1)
	return 1 - c * c * c
end

local function stepSwing(s: Swing, char: Model, dt: number): boolean
	s.t += dt
	local hand = handPos(char)
	if not hand then
		return false
	end
	local p = s.t / SWING_TIME
	local reach: number
	local fade = 0
	if p <= 1 then
		reach = s.length * easeOut(p)
	else
		local r = (s.t - SWING_TIME) / RETRACT_TIME
		if r >= 1 then
			return false
		end
		reach = s.length * (1 - r * 0.7)
		fade = r
	end
	local wave = math.max(0, 1 - p) -- a onda morre quando o laco estica
	local tipY = s.floorY + LASH_HEIGHT
	local amp = s.width * 0.55

	local prev = hand
	for k = 1, SEGMENTS do
		local u = k / SEGMENTS
		local along = hand + s.dir * (reach * u)
		local y = hand.Y + (tipY - hand.Y) * u + math.sin(math.pi * u) * 1.6 * wave
		local sway = math.sin(u * math.pi * 2.2 - p * math.pi * 3) * amp * wave * u
		local point = Vector3.new(along.X, y, along.Z) + s.side * sway
		local part = s.parts[k]
		local d = (point - prev).Magnitude
		local thick = 0.26 * (1 - u * 0.65)
		part.Size = Vector3.new(thick, thick, math.max(d, 0.05))
		if d > 0.01 then
			part.CFrame = CFrame.lookAt((prev + point) / 2, point)
		end
		part.Transparency = fade
		prev = point
	end

	-- estalo na ponta
	if not s.cracked and p >= CRACK_AT then
		s.cracked = true
		s.crackT = 0
		local flash = takePart(s.fx.crack, Enum.Material.Neon)
		flash.Shape = Enum.PartType.Ball
		s.flash = flash
		play(s.fx.crackSound, s.fx.volume or 0.6, 1.35 + math.random() * 0.2)
	end
	local flash = s.flash
	if flash then
		s.crackT += dt
		local c = s.crackT / CRACK_TIME
		if c >= 1 then
			giveBack(flash)
			s.flash = nil
		else
			flash.Size = Vector3.one * (0.6 + c * 2.4)
			flash.Transparency = 0.2 + c * 0.8
			flash.CFrame = CFrame.new(prev)
		end
	end
	return true
end

local function endSwing(s: Swing)
	for _, part in s.parts do
		giveBack(part)
	end
	if s.flash then
		giveBack(s.flash)
	end
end

local function startWhip(data: any)
	local def = Content.weapons[data.weapon]
	local fx = def and def.fx
	if not fx then
		return
	end
	local dir: Vector3 = data.dir
	if typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then
		return
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local parts = {}
	for _ = 1, SEGMENTS do
		table.insert(parts, takePart(fx.lash, Enum.Material.Fabric))
	end
	table.insert(swings, {
		parts = parts,
		flash = nil,
		t = 0,
		dir = dir,
		side = Vector3.new(-dir.Z, 0, dir.X) * (if data.back then -1 else 1),
		length = tonumber(data.length) or 8,
		width = tonumber(data.width) or 2.6,
		floorY = tonumber(data.floorY) or 0,
		fx = fx,
		cracked = false,
		crackT = 0,
	})
	armSwingT = 0
	play(fx.swingSound, (fx.volume or 0.6) * 0.5, 0.8 + math.random() * 0.15)
end

-- ====== API ======

-- Evento WeaponFx do servidor.
function WeaponFx.event(data: any)
	if type(data) ~= "table" then
		return
	end
	if data.kind == "whip" then
		startWhip(data)
	end
end

-- Lista de armas da run (RunSync). Decide se o chicote fica na mao.
function WeaponFx.setLoadout(weapons: { any }?)
	local found: string? = nil
	for _, w in weapons or {} do
		local def = Content.weapons[w.id]
		if def and def.kind == "whip" and def.fx then
			found = def.id
		end
	end
	if found ~= holding then
		holding = found
		removeHold() -- o loop remonta com o visual certo (ex.: evoluiu)
	end
end

-- Saiu da run: limpa tudo.
function WeaponFx.clear()
	WeaponFx.setLoadout(nil)
	for _, s in swings do
		endSwing(s)
	end
	table.clear(swings)
	armSwingT = -1
	local char = player.Character
	local motor = char and rightShoulder(char)
	if motor and shoulderBase[motor] then
		motor.C0 = shoulderBase[motor]
	end
end

function WeaponFx.init()
	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		if not char then
			return
		end
		-- chicote na mao (remonta se o personagem renasceu)
		if holding then
			if not holdModel or holdModel.Parent ~= char then
				local def = Content.weapons[holding]
				if def and def.fx then
					buildHold(char, def.fx)
				end
			end
		elseif holdModel then
			removeHold()
		end

		for i = #swings, 1, -1 do
			local s = swings[i]
			if not stepSwing(s, char, dt) then
				endSwing(s)
				table.remove(swings, i)
			end
		end
		setCoilVisible(#swings == 0)
		updateArm(char, dt)
	end)
	player.CharacterAdded:Connect(function()
		table.clear(shoulderBase) -- motores novos
		armSwingT = -1
	end)
end

return WeaponFx
