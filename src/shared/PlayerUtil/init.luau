--!strict
-- Utilidades para achar jogadores/personagens. Usado pelo spawn e pela mira.
local Players = game:GetService("Players")

local PlayerUtil = {}

-- HumanoidRootPart do jogador mais proximo de uma posicao (nil se ninguem nasceu).
function PlayerUtil.nearestRoot(pos: Vector3): BasePart?
	local best: BasePart? = nil
	local bestDist: number? = nil
	for _, pl in Players:GetPlayers() do
		local char = pl.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local d = (root.Position - pos).Magnitude
			if bestDist == nil or d < bestDist then
				best = root
				bestDist = d
			end
		end
	end
	return best
end

-- Um jogador aleatorio que ja tem personagem no mundo (nil se nenhum).
function PlayerUtil.randomPlayerWithChar(): Player?
	local candidates: { Player } = {}
	for _, pl in Players:GetPlayers() do
		local char = pl.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			table.insert(candidates, pl)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(#candidates)]
end

return PlayerUtil
