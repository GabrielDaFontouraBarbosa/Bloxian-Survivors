--!strict
-- PowerUps: melhorias permanentes compradas com ouro NO LOBBY (nunca durante a
-- partida — decisao do usuario). Cada rank soma `per` no stat `stat`.
-- `util` em vez de `stat` = cargas por run (rerolls / skips no level up).
-- Custo do proximo rank = cost * (rank + 1) * (1 + Meta.PowerUpMarkup * ranks ja
-- comprados no total). Reembolso devolve tudo (estilo VS) — sem punicao.
-- Regra do DESIGN.md: PowerUps globais e MODESTOS; a personalidade fica na classe.
return {
	{ id = "might", stat = "might", name = "Poder", per = 0.05, maxLevel = 5, cost = 200, desc = "+5% de dano por rank." },
	{ id = "armor", stat = "armor", name = "Armadura", per = 1, maxLevel = 3, cost = 600, desc = "+1 de armadura por rank." },
	{ id = "health", stat = "health", name = "Vida Máx.", per = 0.1, maxLevel = 3, cost = 200, desc = "+10% de vida máxima por rank." },
	{ id = "recovery", stat = "recovery", name = "Recuperação", per = 0.1, maxLevel = 5, cost = 200, desc = "+0,1 de vida por segundo por rank." },
	{ id = "cooldown", stat = "cooldown", name = "Recarga", per = -0.025, maxLevel = 2, cost = 900, desc = "-2,5% de recarga por rank." },
	{ id = "area", stat = "area", name = "Área", per = 0.05, maxLevel = 2, cost = 300, desc = "+5% de área por rank." },
	{ id = "speed", stat = "speed", name = "Velocidade", per = 0.1, maxLevel = 2, cost = 300, desc = "+10% de velocidade de projétil por rank." },
	{ id = "duration", stat = "duration", name = "Duração", per = 0.15, maxLevel = 2, cost = 300, desc = "+15% de duração por rank." },
	{ id = "amount", stat = "amount", name = "Quantidade", per = 1, maxLevel = 1, cost = 5000, desc = "+1 projétil em todas as armas." },
	{ id = "moveSpeed", stat = "moveSpeed", name = "Movimento", per = 0.05, maxLevel = 2, cost = 300, desc = "+5% de velocidade de corrida por rank." },
	{ id = "magnet", stat = "magnet", name = "Ímã", per = 0.25, maxLevel = 2, cost = 300, desc = "+25% de raio do ímã por rank." },
	{ id = "luck", stat = "luck", name = "Sorte", per = 0.1, maxLevel = 3, cost = 600, desc = "+10% de sorte por rank." },
	{ id = "growth", stat = "growth", name = "Crescimento", per = 0.03, maxLevel = 5, cost = 900, desc = "+3% de XP por rank." },
	{ id = "greed", stat = "greed", name = "Ganância", per = 0.1, maxLevel = 5, cost = 200, desc = "+10% de ouro por rank." },
	{ id = "curse", stat = "curse", name = "Maldição", per = 0.1, maxLevel = 5, cost = 1666, desc = "+10% de inimigos e vida deles (mais XP, mais risco)." },
	{ id = "revival", stat = "revival", name = "Ressurreição", per = 1, maxLevel = 1, cost = 10000, desc = "Volta à vida uma vez por run." },
	{ id = "reroll", util = "rerolls", name = "Rerrolar", per = 2, maxLevel = 5, cost = 1000, desc = "+2 cargas de rerrolar as opções do level up." },
	{ id = "skip", util = "skips", name = "Pular", per = 2, maxLevel = 5, cost = 150, desc = "+2 cargas de pular um level up." },
}
