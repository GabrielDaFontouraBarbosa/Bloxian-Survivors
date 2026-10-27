--!strict
-- Acesso central aos RemoteEvents em ReplicatedStorage/Remotes.
-- No servidor cria o evento se faltar; no cliente espera ele existir.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local function getFolder(): Instance
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
		return folder
	end
	return ReplicatedStorage:WaitForChild("Remotes")
end

function Remotes.event(name: string): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		local ev = folder:FindFirstChild(name)
		if not ev then
			ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
		return ev :: RemoteEvent
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
