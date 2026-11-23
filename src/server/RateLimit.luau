--!strict
-- Trava simples contra spam de RemoteEvent: no maximo 1 chamada por `interval`
-- segundos, por jogador e por acao. Nunca confiar no ritmo do cliente.
local Players = game:GetService("Players")

local RateLimit = {}

local last: { [Player]: { [string]: number } } = {}

function RateLimit.allow(player: Player, key: string, interval: number): boolean
	local byKey = last[player]
	if not byKey then
		byKey = {}
		last[player] = byKey
	end
	local now = os.clock()
	local prev = byKey[key]
	if prev and now - prev < interval then
		return false
	end
	byKey[key] = now
	return true
end

Players.PlayerRemoving:Connect(function(player)
	last[player] = nil
end)

return RateLimit
