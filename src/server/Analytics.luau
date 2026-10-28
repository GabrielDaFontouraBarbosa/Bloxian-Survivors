--!strict
-- Eventos de retencao (ver skill retention). ATENCAO: a assinatura de
-- AnalyticsService:LogFunnelStepEvent NAO foi verificada na doc atual e os
-- eventos so sao gravados em jogo PUBLICADO. Tudo protegido por pcall para
-- nao quebrar o teste no Studio. Confirmar na doc antes de confiar nos numeros.
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")

local Analytics = {}

local firstKillDone: { [Player]: boolean } = {}

-- Passo 2 do roteiro: primeira morte de inimigo do jogador (uma vez por vida de sessao).
function Analytics.firstEnemyKill(player: Player)
	if firstKillDone[player] then
		return
	end
	firstKillDone[player] = true
	pcall(function()
		local runId = HttpService:GenerateGUID(false)
		AnalyticsService:LogFunnelStepEvent(player, "RunProgress", runId, 2, "FirstKill")
	end)
end

-- Passo 4: cada nivel alcancado.
function Analytics.levelReached(player: Player, level: number)
	pcall(function()
		AnalyticsService:LogProgressionEvent(
			player,
			"Run",
			Enum.AnalyticsProgressionType.Complete,
			level,
			"LevelUp"
		)
	end)
end

-- Passo 4: upgrade escolhido no level up (vai como evento economico/custom).
function Analytics.upgradeChosen(player: Player, level: number, upgradeId: string)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "UpgradeChosen", 1, {
			level = level,
			upgrade = upgradeId,
		})
	end)
end

-- Passo 5: morte do jogador (onda e tempo de vida da partida).
function Analytics.runDeath(player: Player, wave: number, elapsed: number)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "RunDeath", 1, {
			wave = wave,
			seconds = math.floor(elapsed),
		})
	end)
end

Players.PlayerRemoving:Connect(function(player)
	firstKillDone[player] = nil
end)

return Analytics
