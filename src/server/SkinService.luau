--!strict
-- Skin do jogador (opcao "Skin" na tela Opcoes):
--   "own"   -> o avatar do proprio jogador no Roblox (sem mexer em nada)
--   "class" -> o visual do personagem escolhido (Config/Classes, campo skin):
--              tira roupas e acessorios, pinta o corpo e cola um chapeu/capa
--              feitos de pecas simples (sem asset externo, sem rig novo).
-- Roda no servidor (a aparencia replica para todo mundo). Reaplica quando o
-- personagem nasce, quando a run comeca (pode ter trocado de personagem) e
-- quando o jogador muda a opcao.
--
-- APIs usadas (confirmar no primeiro Play): Humanoid:ApplyDescription,
-- Humanoid:GetAppliedDescription, Players:GetHumanoidDescriptionFromUserId,
-- HumanoidDescription:SetAccessories. Tudo em pcall: se falhar, o jogador fica
-- com o proprio avatar e aparece um aviso no Output.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local Events = require(script.Parent.Events)
local SaveService = require(script.Parent.SaveService)

local SkinService = {}

local COSTUME = "ClassCostume" -- pasta com as pecas coladas no personagem
local ACCESSORY_PROPS = {
	"HatAccessory",
	"HairAccessory",
	"FaceAccessory",
	"NeckAccessory",
	"ShouldersAccessory",
	"FrontAccessory",
	"BackAccessory",
	"WaistAccessory",
}

local ownDesc: { [Player]: HumanoidDescription } = {}
local token: { [Player]: number } = {}
local warned = false

local function warnOnce(message: string)
	if not warned then
		warned = true
		warn("[Survivors] Skin: " .. message)
	end
end

-- Descricao original do avatar (cache por jogador; pega uma vez, antes de mexer).
local function ownDescription(player: Player, hum: Humanoid): HumanoidDescription?
	local cached = ownDesc[player]
	if cached then
		return cached
	end
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	if not ok or not desc then
		-- jogador de teste do Studio (UserId negativo) ou web fora: usa o que esta vestido
		ok, desc = pcall(function()
			return hum:GetAppliedDescription()
		end)
	end
	if ok and desc then
		ownDesc[player] = desc
		return desc
	end
	return nil
end

-- Descricao do personagem: corpo pintado, sem roupa nem acessorio.
local function classDescription(base: HumanoidDescription?, skin: any): HumanoidDescription
	local d = if base then base:Clone() else Instance.new("HumanoidDescription")
	for _, prop in ACCESSORY_PROPS do
		(d :: any)[prop] = ""
	end
	pcall(function()
		d:SetAccessories({}, true) -- acessorios em camadas (layered clothing)
	end)
	d.Shirt = 0
	d.Pants = 0
	d.GraphicTShirt = 0
	d.HeadColor = skin.skinTone
	d.TorsoColor = skin.shirt
	d.LeftArmColor = skin.shirt
	d.RightArmColor = skin.shirt
	d.LeftLegColor = skin.pants
	d.RightLegColor = skin.pants
	return d
end

-- ====== chapeu e capa (pecas simples soldadas) ======

local function piece(parent: Instance, size: Vector3, color: Color3, attachTo: BasePart, offset: CFrame, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = attachTo.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = attachTo
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	p.Parent = parent
	return p
end

-- Cilindro deitado em pe (o eixo do Cylinder do Roblox e o X).
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local HATS: { [string]: (Instance, BasePart, Color3) -> () } = {
	-- chapeu de aba larga do cacador
	tricorn = function(folder, head, color)
		local h = head.Size
		local top = h.Y / 2
		piece(folder, Vector3.new(0.18, h.X * 2.1, h.X * 2.1), color, head, CFrame.new(0, top + 0.05, 0) * UPRIGHT, Enum.PartType.Cylinder)
		piece(folder, Vector3.new(0.7, h.X * 1.05, h.X * 1.05), color, head, CFrame.new(0, top + 0.4, 0) * UPRIGHT, Enum.PartType.Cylinder)
		piece(folder, Vector3.new(0.12, h.X * 1.08, h.X * 1.08), Color3.fromRGB(150, 30, 30), head, CFrame.new(0, top + 0.16, 0) * UPRIGHT, Enum.PartType.Cylinder)
	end,
	-- capuz: topo, nuca e laterais (o rosto fica livre)
	hood = function(folder, head, color)
		local h = head.Size
		piece(folder, Vector3.new(h.X * 1.25, 0.3, h.Z * 1.25), color, head, CFrame.new(0, h.Y / 2 + 0.1, 0.05), nil, Enum.Material.Fabric)
		piece(folder, Vector3.new(h.X * 1.25, h.Y * 1.15, 0.25), color, head, CFrame.new(0, 0, h.Z / 2 + 0.12), nil, Enum.Material.Fabric)
		piece(folder, Vector3.new(0.2, h.Y * 1.1, h.Z * 1.1), color, head, CFrame.new(-h.X / 2 - 0.1, 0, 0.05), nil, Enum.Material.Fabric)
		piece(folder, Vector3.new(0.2, h.Y * 1.1, h.Z * 1.1), color, head, CFrame.new(h.X / 2 + 0.1, 0, 0.05), nil, Enum.Material.Fabric)
	end,
	-- chapeu pontudo de mago: aba + cilindros cada vez mais finos, meio torto
	wizard = function(folder, head, color)
		local h = head.Size
		local top = h.Y / 2
		piece(folder, Vector3.new(0.15, h.X * 1.9, h.X * 1.9), color, head, CFrame.new(0, top + 0.05, 0) * UPRIGHT, Enum.PartType.Cylinder)
		local widths = { 1.15, 0.85, 0.55, 0.28 }
		for i, f in widths do
			local tilt = CFrame.Angles(math.rad(-6 * i), 0, 0)
			piece(folder, Vector3.new(0.55, h.X * f, h.X * f), color, head, CFrame.new(0, top + 0.25 + (i - 1) * 0.48, 0.06 * i) * tilt * UPRIGHT, Enum.PartType.Cylinder)
		end
	end,
	-- bandana: faixa na testa + no atras
	bandana = function(folder, head, color)
		local h = head.Size
		piece(folder, Vector3.new(h.X * 1.08, 0.3, h.Z * 1.08), color, head, CFrame.new(0, h.Y * 0.22, 0), nil, Enum.Material.Fabric)
		piece(folder, Vector3.new(0.35, 0.3, 0.6), color, head, CFrame.new(0.15, h.Y * 0.18, h.Z / 2 + 0.3) * CFrame.Angles(math.rad(-30), 0, 0), nil, Enum.Material.Fabric)
	end,
}

local function addCape(folder: Instance, char: Model, color: Color3)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return
	end
	local t = torso.Size
	local height = t.Y * 2.1
	-- presa nos ombros, pendurada atras e levemente aberta
	local offset = CFrame.new(0, t.Y / 2 - height / 2 + 0.1, t.Z / 2 + 0.12) * CFrame.Angles(math.rad(6), 0, 0)
	piece(folder, Vector3.new(t.X * 1.05, height, 0.12), color, torso, offset, nil, Enum.Material.Fabric)
end

local function removeCostume(char: Model)
	local old = char:FindFirstChild(COSTUME)
	if old then
		old:Destroy()
	end
end

local function addCostume(char: Model, skin: any)
	removeCostume(char)
	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = COSTUME
	local hat = HATS[skin.hat]
	if hat then
		hat(folder, head, skin.hatColor or skin.shirt)
	end
	if skin.cape then
		addCape(folder, char, skin.cape)
	end
	folder.Parent = char
end

-- ====== API ======

-- Aplica a skin certa no personagem atual (pode esperar: ApplyDescription demora).
function SkinService.refresh(player: Player)
	local profile = SaveService.peek(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not profile or not char or not hum or hum.Health <= 0 then
		return
	end
	local my = (token[player] or 0) + 1
	token[player] = my

	local base = ownDescription(player, hum)
	if token[player] ~= my or player.Character ~= char then
		return -- outra chamada mais nova assumiu
	end

	local class = Content.classes[profile.selected.class]
	local useClass = profile.settings.skin == "class" and class ~= nil and class.skin ~= nil
	local desc: HumanoidDescription? = nil
	if useClass then
		desc = classDescription(base, (class :: any).skin)
	elseif base then
		desc = base:Clone()
	end
	if not desc then
		return
	end
	local ok, err = pcall(function()
		hum:ApplyDescription(desc :: HumanoidDescription)
	end)
	if not ok then
		warnOnce("nao consegui aplicar a skin (" .. tostring(err) .. ").")
	end
	if token[player] ~= my or player.Character ~= char then
		return
	end
	if useClass then
		addCostume(char, (class :: any).skin)
	else
		removeCostume(char)
	end
end

local function onCharacter(player: Player, char: Model)
	-- espera o avatar carregar, senao a descricao "original" vem pela metade
	local deadline = os.clock() + 6
	while player.Parent and player.Character == char and not player:HasAppearanceLoaded() and os.clock() < deadline do
		task.wait(0.1)
	end
	if player.Parent and player.Character == char then
		local hum = char:WaitForChild("Humanoid", 5)
		if hum and hum:IsA("Humanoid") then
			ownDescription(player, hum) -- guarda o original ANTES de qualquer troca
		end
		SkinService.refresh(player)
	end
end

function SkinService.onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

function SkinService.onPlayerRemoving(player: Player)
	ownDesc[player] = nil
	token[player] = nil
end

function SkinService.init()
	Events.on("RunStarted", function(run: any)
		task.spawn(SkinService.refresh, run.player)
	end)
end

return SkinService
