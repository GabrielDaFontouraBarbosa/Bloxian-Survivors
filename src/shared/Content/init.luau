--!strict
-- Indice dos catalogos do Config por id (lookup O(1)) + formulas compartilhadas
-- entre servidor e cliente (o cliente usa para mostrar nomes, custos e textos).
local Config = require(script.Parent.Config)

local Content = {}

local function index(list: { any }): { [string]: any }
	local map = {}
	for _, entry in list do
		map[entry.id] = entry
	end
	return map
end

Content.stats = index(Config.Stats)
Content.weapons = index(Config.Weapons)
Content.passives = index(Config.Passives)
Content.classes = index(Config.Classes)
Content.enemies = index(Config.Enemies)
Content.stages = index(Config.Stages)
Content.pickups = index(Config.Pickups.items)
Content.powerUps = index(Config.PowerUps)
Content.arcanas = index(Config.Arcanas)
Content.achievements = index(Config.Achievements)
Content.quests = index(Config.Quests)
Content.adventures = index(Config.Adventures)

-- Catalogo de cada tipo de desbloqueio (o que uma recompensa pode liberar).
Content.byKind = {
	class = Content.classes,
	weapon = Content.weapons,
	passive = Content.passives,
	arcana = Content.arcanas,
	stage = Content.stages,
	adventure = Content.adventures,
}

-- Stats da arma num nivel: base + soma dos degraus ate la (sem os stats do jogador).
function Content.weaponStats(def: any, level: number): { [string]: any }
	local s = table.clone(def.base)
	local levels = def.levels
	if levels then
		for i = 1, math.min(level - 1, #levels) do
			for key, delta in levels[i] do
				if type(delta) == "number" then
					s[key] = (s[key] or 0) + delta
				else
					s[key] = delta
				end
			end
		end
	end
	return s
end

-- XP para ir do nivel `level` ao `level + 1` (degraus estilo VS).
function Content.xpForLevel(level: number): number
	local p = Config.Progression
	if level < p.MidFrom then
		return p.First + p.StepEarly * (level - 1)
	end
	local atMid = p.First + p.StepEarly * (p.MidFrom - 1)
	if level < p.LateFrom then
		return atMid + p.StepMid * (level - p.MidFrom + 1)
	end
	local atLate = atMid + p.StepMid * (p.LateFrom - p.MidFrom)
	return atLate + p.StepLate * (level - p.LateFrom + 1)
end

-- Preco do proximo rank de um PowerUp.
function Content.powerUpCost(def: any, rank: number, totalBought: number): number
	return math.floor(def.cost * (rank + 1) * (1 + Config.Meta.PowerUpMarkup * totalBought) + 0.5)
end

-- Nome legivel de um id de desbloqueio (para textos de recompensa).
function Content.unlockName(kind: string, id: string): string
	local catalog = Content.byKind[kind]
	local entry = catalog and catalog[id]
	return if entry then entry.name else id
end

local KIND_LABEL = {
	class = "Classe",
	weapon = "Arma",
	passive = "Passiva",
	arcana = "Arcano",
	stage = "Estágio",
	adventure = "Aventura",
}

-- Texto de uma recompensa de conquista/aventura ("Classe: Feiticeira", "+300 de ouro").
function Content.rewardText(reward: any): string
	if not reward then
		return ""
	end
	if reward.kind == "gold" then
		return ("+%d de ouro"):format(reward.amount or 0)
	end
	return ("%s: %s"):format(KIND_LABEL[reward.kind] or reward.kind, Content.unlockName(reward.kind, reward.id))
end

-- Formata um valor de stat para mostrar ("+15%", "+2", "+0,5/s").
function Content.formatStat(id: string, value: number): string
	local def = Content.stats[id]
	local sign = if value >= 0 then "+" else ""
	if def and def.fmt == "pct" then
		return ("%s%d%%"):format(sign, math.floor(value * 100 + (if value >= 0 then 0.5 else -0.5)))
	elseif def and def.fmt == "hps" then
		local text = ("%s%.1f/s"):format(sign, value):gsub("%.", ",")
		return text
	end
	return ("%s%s"):format(sign, tostring(value))
end

return Content
