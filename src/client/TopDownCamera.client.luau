--!strict
-- Camera de cima que segue o personagem local (estilo bullet heaven).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Pega a HumanoidRootPart do personagem atual (nil enquanto nao nasce / durante respawn).
local function getRoot(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

camera.CameraType = Enum.CameraType.Scriptable

local offset = Config.Camera.Offset
local smoothing = Config.Camera.Smoothing

RunService:BindToRenderStep("TopDownCamera", Enum.RenderPriority.Camera.Value, function(dt: number)
	local root = getRoot()
	if not root then
		return
	end

	local target = root.Position
	local desiredPos = target + offset
	local desired = CFrame.lookAt(desiredPos, target)

	-- Interpola suave, com passo independente de FPS.
	local alpha = 1 - (smoothing ^ (dt * 60))
	camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(alpha, 0, 1))
end)
