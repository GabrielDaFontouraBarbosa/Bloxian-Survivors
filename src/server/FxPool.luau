--!strict
-- Pool das pecas visuais das armas (projeteis, golpes, auras, pocas, raios).
-- Regra do projeto: nunca criar/destruir toda hora — pega do pool e devolve.
-- So visual: acerto e dano sao calculados em 2D pelos comportamentos.
local FxPool = {}

local folder: Folder
local pools: { [string]: { BasePart } } = {}
local kindOf: { [BasePart]: string } = {}

local function base(): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Como cada tipo de peca nasce (tamanho e cor sao definidos a cada uso).
local MAKERS: { [string]: () -> Part } = {
	ball = function()
		local p = base()
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.Neon
		return p
	end,
	blade = function()
		local p = base()
		p.Material = Enum.Material.Neon
		return p
	end,
	axe = function()
		local p = base()
		p.Material = Enum.Material.Metal
		return p
	end,
	cross = function()
		local p = base()
		p.Material = Enum.Material.Neon
		return p
	end,
	book = function()
		local p = base()
		p.Material = Enum.Material.SmoothPlastic
		return p
	end,
	slash = function()
		local p = base()
		p.Material = Enum.Material.Neon
		p.Transparency = 0.2
		return p
	end,
	disc = function()
		local p = base()
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		p.Transparency = 0.8
		return p
	end,
	puddle = function()
		local p = base()
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		p.Transparency = 0.45
		return p
	end,
	bolt = function()
		local p = base()
		p.Material = Enum.Material.Neon
		return p
	end,
}

function FxPool.init()
	folder = Instance.new("Folder")
	folder.Name = "WeaponFx"
	folder.Parent = workspace
end

-- Pega uma peca do tipo `kind`, ja com cor e tamanho, dentro do workspace.
function FxPool.get(kind: string, color: Color3, size: Vector3): BasePart
	local pool = pools[kind]
	local part = pool and table.remove(pool)
	if not part then
		local maker = MAKERS[kind] or MAKERS.ball
		part = maker()
		part.Name = kind
		kindOf[part :: BasePart] = kind
	end
	local p = part :: BasePart
	p.Color = color
	p.Size = size
	p.Parent = folder
	return p
end

-- Devolve a peca para o pool (some da tela).
function FxPool.put(part: BasePart)
	if part.Parent == nil then
		return -- ja devolvida
	end
	part.Parent = nil
	local kind = kindOf[part] or "ball"
	local pool = pools[kind]
	if not pool then
		pool = {}
		pools[kind] = pool
	end
	table.insert(pool, part)
end

-- Mostra a peca por `seconds` e devolve sozinha (golpes e raios).
function FxPool.flash(part: BasePart, seconds: number)
	task.delay(seconds, FxPool.put, part)
end

return FxPool
