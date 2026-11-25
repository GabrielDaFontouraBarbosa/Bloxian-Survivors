--!strict
-- Estagios. Cada estagio = chao/cenario + ondas por minuto + eventos com hora marcada.
--   segments: de `from` a `to` minutos, sorteia entre `enemies`, mantendo pelo menos
--             `min` vivos e nascendo um a cada `interval` s. `hp` multiplica a vida.
--             (Maldicao do jogador escala `min` e `hp`.)
--   events:   `at` em segundos. kind:
--               "swarm" -> revoada: `count` inimigos `enemy` cruzando a tela em linha reta
--               "ring"  -> cerco: `count` inimigos `enemy` em circulo de raio `radius`
--               "boss"  -> chefe `enemy` (solta bau)
--   duration: aos `duration` s a Ceifadora chega (chegar ate ela = estagio completo).
--   scenery:  o que o cliente espalha no chao ("plains" = campo aberto, "forest" =
--             arvores, "graves" = tumulos; ver client/Scenery).
--
-- Conjunto atual (pedido do usuario, 2026-11): UMA fase, Planicies, onde todo
-- inimigo e um morcego. A dificuldade sobe trocando o tipo de morcego (mais vida,
-- maior, mais rapido) e com revoadas, cercos e chefes-morcego.
return {
	{
		id = "plains",
		name = "Planícies",
		desc = "Campo aberto ao entardecer. Só morcegos — muitos morcegos.",
		default = true,
		duration = 30 * 60,
		floorColor = Color3.fromRGB(78, 120, 58),
		floorMaterial = Enum.Material.Grass,
		scenery = "plains",
		brazierInterval = 12,
		brazierMax = 6,
		segments = {
			{ from = 0, to = 1, enemies = { "bat" }, min = 14, interval = 0.45, hp = 1 },
			{ from = 1, to = 2, enemies = { "bat" }, min = 24, interval = 0.38, hp = 1 },
			{ from = 2, to = 4, enemies = { "bat", "vampireBat" }, min = 32, interval = 0.34, hp = 1 },
			{ from = 4, to = 6, enemies = { "vampireBat", "bat" }, min = 42, interval = 0.3, hp = 1.1 },
			{ from = 6, to = 8, enemies = { "vampireBat", "duskBat" }, min = 52, interval = 0.28, hp = 1.1 },
			{ from = 8, to = 10, enemies = { "duskBat", "vampireBat", "bat" }, min = 62, interval = 0.25, hp = 1.2 },
			{ from = 10, to = 13, enemies = { "duskBat", "elderBat" }, min = 72, interval = 0.22, hp = 1.3 },
			{ from = 13, to = 16, enemies = { "elderBat", "duskBat", "vampireBat" }, min = 82, interval = 0.2, hp = 1.4 },
			{ from = 16, to = 20, enemies = { "elderBat", "shadowBat" }, min = 92, interval = 0.18, hp = 1.6 },
			{ from = 20, to = 24, enemies = { "shadowBat", "elderBat", "duskBat" }, min = 100, interval = 0.16, hp = 1.9 },
			{ from = 24, to = 27, enemies = { "shadowBat", "elderBat" }, min = 110, interval = 0.15, hp = 2.3 },
			{ from = 27, to = 30, enemies = { "shadowBat", "elderBat", "duskBat", "vampireBat" }, min = 120, interval = 0.14, hp = 2.7 },
		},
		events = {
			{ at = 90, kind = "swarm", enemy = "swarmBat", count = 24 },
			{ at = 180, kind = "boss", enemy = "giantBat" },
			{ at = 300, kind = "swarm", enemy = "swarmBat", count = 32 },
			{ at = 360, kind = "ring", enemy = "ringBat", count = 40, radius = 26 },
			{ at = 480, kind = "swarm", enemy = "swarmBat", count = 40 },
			{ at = 600, kind = "boss", enemy = "giantBat" },
			{ at = 720, kind = "swarm", enemy = "swarmBat", count = 48 },
			{ at = 840, kind = "ring", enemy = "ringBat", count = 48, radius = 28 },
			{ at = 900, kind = "boss", enemy = "batLord" },
			{ at = 1020, kind = "swarm", enemy = "swarmBat", count = 56 },
			{ at = 1200, kind = "boss", enemy = "batLord" },
			{ at = 1320, kind = "ring", enemy = "ringBat", count = 56, radius = 30 },
			{ at = 1440, kind = "swarm", enemy = "swarmBat", count = 64 },
			{ at = 1500, kind = "boss", enemy = "batQueen" },
			{ at = 1680, kind = "swarm", enemy = "swarmBat", count = 72 },
		},
	},
}
