--!strict
-- Arena de cada run: um "andar" proprio em altura (Y = ArenaBaseY + slot*Spacing),
-- assim runs de jogadores diferentes nunca se encostam. O chao e uma Part grande
-- que segue o jogador em passos fixos: o mapa e infinito, como no VS.
-- Cenario (arvores/tumulos) e luz ficam no cliente; aqui so o chao fisico.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Runs = require(script.Parent.Runs)

local Arena = {}

local usedSlots: { [number]: boolean } = {}
local folder: Folder

function Arena.init()
	folder = Instance.new("Folder")
	folder.Name = "Arenas"
	folder.Parent = workspace
end

-- Reserva um andar e cria o chao. Preenche run.slot, run.floorY e run.floor.
function Arena.setup(run: Runs.Run)
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	run.slot = slot
	run.floorY = Config.Run.ArenaBaseY + (slot - 1) * Config.Run.ArenaSpacing

	local size = Config.Run.FloorSize
	local floor = Instance.new("Part")
	floor.Name = "Floor_" .. tostring(run.id)
	floor.Anchored = true
	floor.Size = Vector3.new(size, 4, size)
	floor.Position = Vector3.new(0, run.floorY - 2, 0)
	floor.Material = run.stage.floorMaterial
	floor.Color = run.stage.floorColor
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = folder
	run.floor = floor
end

-- Onde o jogador aparece ao entrar na arena.
function Arena.spawnCFrame(run: Runs.Run): CFrame
	return CFrame.new(0, run.floorY + 4, 0)
end

-- Recentra o chao embaixo do jogador quando ele se afasta (mapa infinito).
function Arena.update(run: Runs.Run)
	local floor = run.floor
	if not floor then
		return
	end
	local pos = run.rootPos
	local center = floor.Position
	local dx, dz = pos.X - center.X, pos.Z - center.Z
	local limit = Config.Run.FloorRecenter
	if dx * dx + dz * dz > limit * limit then
		local snap = Config.Run.FloorSnap
		local x = math.floor(pos.X / snap + 0.5) * snap
		local z = math.floor(pos.Z / snap + 0.5) * snap
		floor.Position = Vector3.new(x, center.Y, z)
	end
end

function Arena.release(run: Runs.Run)
	if run.floor then
		run.floor:Destroy()
		run.floor = nil
	end
	usedSlots[run.slot] = nil
end

return Arena
