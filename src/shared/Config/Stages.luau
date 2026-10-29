--!strict
-- Estagios. Cada estagio = chao/cenario + ondas por minuto + eventos com hora marcada.
--   segments: de `from` a `to` minutos, sorteia entre `enemies`, mantendo pelo menos
--             `min` vivos e nascendo um a cada `interval` s. `hp` multiplica a vida.
--             (Maldicao do jogador escala `min` e `hp`.)
--   events:   `at` em segundos. kind:
--               "swarm" -> revoada: `count` inimigos `enemy` cruzando a tela em linha reta
--               "ring"  -> muro: `count` inimigos `enemy` em circulo de raio `radius`
--               "boss"  -> chefe `enemy` (solta bau)
--   duration: aos `duration` s a Ceifadora chega (chegar ate ela = estagio completo).
--   scenery:  o que o cliente espalha no chao ("forest" = arvores, "graves" = tumulos).
return {
	{
		id = "forest",
		name = "Floresta Maldita",
		desc = "Uma floresta escura cheia de morcegos e crânios flutuantes.",
		default = true,
		duration = 30 * 60,
		floorColor = Color3.fromRGB(38, 58, 34),
		floorMaterial = Enum.Material.Grass,
		scenery = "forest",
		brazierInterval = 12,
		brazierMax = 6,
		segments = {
			{ from = 0, to = 1, enemies = { "bat" }, min = 14, interval = 0.45, hp = 1 },
			{ from = 1, to = 2, enemies = { "bat", "skull" }, min = 22, interval = 0.4, hp = 1 },
			{ from = 2, to = 4, enemies = { "skull", "bat", "skeleton" }, min = 30, interval = 0.35, hp = 1 },
			{ from = 4, to = 6, enemies = { "skeleton", "skull", "ghoul" }, min = 40, interval = 0.3, hp = 1.1 },
			{ from = 6, to = 8, enemies = { "ghoul", "skeleton", "ghost" }, min = 50, interval = 0.28, hp = 1.1 },
			{ from = 8, to = 10, enemies = { "ghost", "mudman", "skull" }, min = 60, interval = 0.25, hp = 1.2 },
			{ from = 10, to = 13, enemies = { "mudman", "skeleton", "mantis" }, min = 70, interval = 0.22, hp = 1.3 },
			{ from = 13, to = 16, enemies = { "mantis", "ghoul", "werewolf" }, min = 80, interval = 0.2, hp = 1.4 },
			{ from = 16, to = 20, enemies = { "werewolf", "ghost", "mudman" }, min = 90, interval = 0.18, hp = 1.6 },
			{ from = 20, to = 24, enemies = { "werewolf", "mummy", "mantis" }, min = 100, interval = 0.16, hp = 1.9 },
			{ from = 24, to = 27, enemies = { "mummy", "werewolf", "skull" }, min = 110, interval = 0.15, hp = 2.3 },
			{ from = 27, to = 30, enemies = { "mummy", "mantis", "werewolf", "ghost" }, min = 120, interval = 0.14, hp = 2.7 },
		},
		events = {
			{ at = 90, kind = "swarm", enemy = "swarmBat", count = 24 },
			{ at = 180, kind = "boss", enemy = "giantBat" },
			{ at = 300, kind = "swarm", enemy = "swarmBat", count = 32 },
			{ at = 360, kind = "ring", enemy = "flower", count = 40, radius = 24 },
			{ at = 480, kind = "swarm", enemy = "swarmBat", count = 40 },
			{ at = 600, kind = "boss", enemy = "giantMantis" },
			{ at = 720, kind = "swarm", enemy = "swarmBat", count = 48 },
			{ at = 840, kind = "ring", enemy = "flower", count = 48, radius = 26 },
			{ at = 900, kind = "boss", enemy = "giantSkull" },
			{ at = 1020, kind = "swarm", enemy = "swarmBat", count = 56 },
			{ at = 1200, kind = "boss", enemy = "bigMummy" },
			{ at = 1320, kind = "ring", enemy = "flower", count = 56, radius = 28 },
			{ at = 1440, kind = "swarm", enemy = "swarmBat", count = 64 },
			{ at = 1500, kind = "boss", enemy = "giantVenus" },
			{ at = 1680, kind = "swarm", enemy = "swarmBat", count = 72 },
		},
	},
	{
		id = "graveyard",
		name = "Cemitério Esquecido",
		desc = "Esqueletos, fantasmas e múmias. Mais duro que a floresta.",
		duration = 30 * 60,
		floorColor = Color3.fromRGB(52, 52, 58),
		floorMaterial = Enum.Material.Slate,
		scenery = "graves",
		brazierInterval = 14,
		brazierMax = 5,
		segments = {
			{ from = 0, to = 2, enemies = { "skull", "skeleton" }, min = 20, interval = 0.4, hp = 1.2 },
			{ from = 2, to = 5, enemies = { "skeleton", "ghost" }, min = 35, interval = 0.32, hp = 1.3 },
			{ from = 5, to = 8, enemies = { "ghost", "ghoul", "skeleton" }, min = 50, interval = 0.27, hp = 1.4 },
			{ from = 8, to = 12, enemies = { "ghoul", "mummy", "ghost" }, min = 65, interval = 0.23, hp = 1.6 },
			{ from = 12, to = 16, enemies = { "mummy", "skeleton", "werewolf" }, min = 80, interval = 0.2, hp = 1.8 },
			{ from = 16, to = 20, enemies = { "werewolf", "mummy", "ghost" }, min = 95, interval = 0.17, hp = 2.1 },
			{ from = 20, to = 25, enemies = { "mummy", "werewolf", "skull" }, min = 110, interval = 0.15, hp = 2.5 },
			{ from = 25, to = 30, enemies = { "mummy", "werewolf", "ghost", "skeleton" }, min = 120, interval = 0.13, hp = 3 },
		},
		events = {
			{ at = 120, kind = "swarm", enemy = "swarmBat", count = 30 },
			{ at = 240, kind = "boss", enemy = "boneLord" },
			{ at = 420, kind = "ring", enemy = "flower", count = 44, radius = 24 },
			{ at = 600, kind = "boss", enemy = "giantSkull" },
			{ at = 780, kind = "swarm", enemy = "swarmBat", count = 50 },
			{ at = 900, kind = "boss", enemy = "bigMummy" },
			{ at = 1080, kind = "ring", enemy = "flower", count = 56, radius = 27 },
			{ at = 1200, kind = "boss", enemy = "boneLord" },
			{ at = 1380, kind = "swarm", enemy = "swarmBat", count = 70 },
			{ at = 1500, kind = "boss", enemy = "giantVenus" },
		},
	},
}
