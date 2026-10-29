--!strict
-- Eventos de retencao (ver skill retention). ATENCAO: as assinaturas de
-- AnalyticsService (LogProgressionEvent, LogCustomEvent, LogEconomyEvent) NAO
-- foram verificadas na doc atual e os eventos so sao gravados em jogo PUBLICADO.
-- Tudo protegido por pcall para nao quebrar o teste no Studio. Confirmar na doc
-- antes de confiar nos numeros (tarefa para o roblox-researcher).
local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

function Analytics.runStarted(player: Player, stageId: string, classId: string)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "RunStarted", 1, { stage = stageId, class = classId })
	end)
end

function Analytics.runEnded(player: Player, reason: string, seconds: number, level: number, kills: number)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "RunEnded", 1, {
			reason = reason,
			seconds = math.floor(seconds),
			level = level,
			kills = kills,
		})
	end)
end

function Analytics.levelReached(player: Player, level: number)
	pcall(function()
		AnalyticsService:LogProgressionEvent(player, "Run", Enum.AnalyticsProgressionType.Complete, level, "LevelUp")
	end)
end

function Analytics.upgradeChosen(player: Player, level: number, upgradeId: string)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "UpgradeChosen", 1, { level = level, upgrade = upgradeId })
	end)
end

-- Ouro gasto no lobby (evento economico: para onde vai a moeda).
local function sink(player: Player, amount: number, balance: number, itemId: string)
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Sink,
			"Gold",
			amount,
			balance,
			Enum.AnalyticsEconomyTransactionType.Shop.Name,
			itemId
		)
	end)
end

function Analytics.powerUpBought(player: Player, id: string, rank: number, cost: number, balance: number)
	sink(player, cost, balance, "powerup_" .. id)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "PowerUpBought", 1, { powerUp = id, rank = rank, cost = cost })
	end)
end

function Analytics.classBought(player: Player, id: string, cost: number, balance: number)
	sink(player, cost, balance, "class_" .. id)
end

return Analytics
