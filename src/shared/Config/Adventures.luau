--!strict
-- Aventuras: sequencias de capitulos com regras proprias (inspiradas nas Adventures
-- do VS). Capitulo N so libera depois do N-1. Completar = sobreviver `duration` s
-- (a Ceifadora chega no fim, como num estagio normal).
--   class:  se definido, o capitulo forca essa classe (nao precisa ter comprado).
--   stage:  estagio usado (pode ser um ainda bloqueado no modo normal).
--   mods:   enemyHp (x vida), enemySpeed (x velocidade), spawnMult (x quantidade),
--           stats (bonus somados no jogador, podem ser negativos).
--   reward: gold (ouro) e/ou unlock ({ kind, id }, mesmo formato das conquistas).
return {
	{
		id = "eternalNight",
		name = "A Noite Sem Fim",
		desc = "Três noites cada vez piores. Use a classe que quiser.",
		chapters = {
			{ name = "I — Clareira", desc = "Sobreviva 8 minutos na Floresta.", stage = "forest", duration = 8 * 60, mods = {}, reward = { gold = 150 } },
			{ name = "II — Revoada", desc = "10 minutos com inimigos 30% mais rápidos e 40% mais numerosos.", stage = "forest", duration = 10 * 60, mods = { enemySpeed = 1.3, spawnMult = 1.4 }, reward = { gold = 250 } },
			{ name = "III — Lua de Sangue", desc = "12 minutos no Cemitério, inimigos com +50% de vida.", stage = "graveyard", duration = 12 * 60, mods = { enemyHp = 1.5 }, reward = { gold = 400 } },
		},
	},
	{
		id = "boneTrial",
		name = "Provação dos Ossos",
		desc = "Só o Caçador, contra o Cemitério, com desvantagens.",
		chapters = {
			{ name = "I — Mãos Fracas", desc = "8 minutos com -20% de Poder.", class = "hunter", stage = "graveyard", duration = 8 * 60, mods = { stats = { might = -0.2 } }, reward = { gold = 200 } },
			{ name = "II — Fuga", desc = "10 minutos com inimigos +30% de vida (você corre +20%).", class = "hunter", stage = "graveyard", duration = 10 * 60, mods = { enemyHp = 1.3, stats = { moveSpeed = 0.2 } }, reward = { gold = 350 } },
			{ name = "III — Ossuário", desc = "15 minutos: inimigos mais fortes, rápidos e numerosos.", class = "hunter", stage = "graveyard", duration = 15 * 60, mods = { enemyHp = 1.6, enemySpeed = 1.2, spawnMult = 1.3 }, reward = { gold = 600, unlock = { kind = "arcana", id = "fury" } } },
		},
	},
}
