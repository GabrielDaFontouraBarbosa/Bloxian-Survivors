--!strict
-- Catalogo de armas. Cada arma tem um `kind` (comportamento em server/Weapons/<kind>)
-- e numeros proprios. Nivel 1 = `base`; `levels[i]` e o que SOMA ao subir para o
-- nivel i+1 (e `levelDesc[i]` o texto mostrado no level up).
--
-- Stats da arma (somados por nivel, depois multiplicados pelos stats do jogador):
--   damage (x Poder), cooldown s (x Recarga), amount (+ Quantidade), area (x Area,
--   escala length/width/radius/size), speed (x Velocidade, escala projSpeed/spin),
--   duration s (x Duracao), pierce (-1 = infinito), knockback, interval (s entre
--   disparos de uma rajada), crit/critMult, lifesteal (vida por inimigo atingido).
--
-- Evolucao (VS): arma no nivel maximo + passiva `evolution.passive` + abrir bau
-- de chefe = vira `evolution.into` (entrada com evolved = true, nivel unico).
-- default = liberada desde o inicio; as outras vem de conquistas.
-- rarity = peso no sorteio do level up (maior = aparece mais).
--
-- Conjunto atual (pedido do usuario, 2026-11): as 4 armas dos 4 primeiros
-- personagens, INSPIRADAS no VS (mecanica parecida, nome e numeros proprios).
-- Os comportamentos antigos (arc, boomerang, orbit, aura, pool, strike) continuam
-- em server/Weapons para voltar depois: basta recolocar a entrada aqui.
return {
	-- ===================== ARMAS BASE =====================
	{
		id = "whip",
		name = "Chicote",
		desc = "Golpeia na frente; com mais Quantidade, alterna para trás.",
		kind = "whip",
		color = Color3.fromRGB(200, 170, 120),
		rarity = 100,
		default = true,
		maxLevel = 8,
		base = { damage = 10, cooldown = 1.35, area = 1, amount = 1, interval = 0.12, knockback = 1, length = 8, width = 2.6 },
		levels = {
			{ amount = 1 },
			{ damage = 5 },
			{ damage = 5, area = 0.1 },
			{ damage = 5 },
			{ damage = 5, area = 0.1 },
			{ damage = 5 },
			{ damage = 5 },
		},
		levelDesc = {
			"+1 golpe (para trás).",
			"+5 de dano.",
			"+5 de dano e +10% de área.",
			"+5 de dano.",
			"+5 de dano e +10% de área.",
			"+5 de dano.",
			"+5 de dano.",
		},
		evolution = { passive = "hollowHeart", into = "bloodyWhip" },
	},
	{
		id = "runetracer",
		name = "Runa Traçante",
		desc = "Uma runa que atravessa tudo e quica nas bordas da tela.",
		kind = "bounce",
		color = Color3.fromRGB(120, 220, 255),
		rarity = 100,
		default = true,
		maxLevel = 8,
		-- duration = quanto tempo a runa fica quicando; halfX/halfZ = "tela" em volta do jogador
		base = { damage = 10, cooldown = 3, amount = 1, interval = 0.15, pierce = -1, projSpeed = 30, duration = 2.25, size = 1.1, knockback = 0.6, halfX = 34, halfZ = 22, hitEvery = 0.4 },
		levels = {
			{ damage = 5, speed = 0.2 },
			{ damage = 5, duration = 0.3 },
			{ amount = 1 },
			{ damage = 5, speed = 0.2 },
			{ damage = 5, duration = 0.3 },
			{ amount = 1 },
			{ duration = 0.5 },
		},
		levelDesc = {
			"+5 de dano e +20% de velocidade.",
			"+5 de dano e +0,3s de duração.",
			"+1 runa.",
			"+5 de dano e +20% de velocidade.",
			"+5 de dano e +0,3s de duração.",
			"+1 runa.",
			"+0,5s de duração.",
		},
		evolution = { passive = "armor", into = "endRune" },
	},
	{
		id = "fireWand",
		name = "Varinha de Fogo",
		desc = "Bolas de fogo lentas e fortes num inimigo aleatório.",
		kind = "fireball",
		color = Color3.fromRGB(255, 120, 40),
		rarity = 100,
		default = true,
		maxLevel = 8,
		base = { damage = 20, cooldown = 3, amount = 3, interval = 0.1, pierce = 1, projSpeed = 22, range = 50, spread = 0.22, lifetime = 3.5, size = 1.3, knockback = 1 },
		levels = {
			{ damage = 10 },
			{ damage = 10, speed = 0.2 },
			{ damage = 10 },
			{ damage = 10, speed = 0.2 },
			{ damage = 10 },
			{ damage = 10, speed = 0.2 },
			{ damage = 10 },
		},
		levelDesc = {
			"+10 de dano.",
			"+10 de dano e +20% de velocidade.",
			"+10 de dano.",
			"+10 de dano e +20% de velocidade.",
			"+10 de dano.",
			"+10 de dano e +20% de velocidade.",
			"+10 de dano.",
		},
		evolution = { passive = "wolfFang", into = "hellfire" },
	},
	{
		id = "knife",
		name = "Facas",
		desc = "Arremessa facas rápidas para onde você olha.",
		kind = "directional",
		color = Color3.fromRGB(210, 215, 225),
		rarity = 100,
		default = true,
		maxLevel = 8,
		base = { damage = 6.5, cooldown = 1.0, amount = 1, interval = 0.08, pierce = 1, projSpeed = 70, spread = 0.7, size = 0.6, knockback = 0.5 },
		levels = {
			{ amount = 1 },
			{ amount = 1, damage = 5 },
			{ amount = 1 },
			{ pierce = 1 },
			{ amount = 1 },
			{ amount = 1, damage = 5 },
			{ pierce = 1 },
		},
		levelDesc = {
			"+1 faca.",
			"+1 faca e +5 de dano.",
			"+1 faca.",
			"Atravessa +1 inimigo.",
			"+1 faca.",
			"+1 faca e +5 de dano.",
			"Atravessa +1 inimigo.",
		},
		evolution = { passive = "bracer", into = "thousandEdge" },
	},

	-- ===================== EVOLUCOES (nao aparecem no level up) =====================
	{
		id = "bloodyWhip",
		name = "Açoite Sangrento",
		desc = "Chicote evoluído: golpes críticos que curam.",
		kind = "whip",
		evolved = true,
		from = "whip",
		color = Color3.fromRGB(200, 30, 50),
		maxLevel = 1,
		base = { damage = 35, cooldown = 1.2, area = 1.4, amount = 2, interval = 0.1, knockback = 1.2, length = 8, width = 2.6, crit = 0.3, critMult = 2, lifesteal = 1 },
	},
	{
		id = "endRune",
		name = "Runa do Fim",
		desc = "Runa evoluída: explode a cada quique.",
		kind = "bounce",
		evolved = true,
		from = "runetracer",
		color = Color3.fromRGB(255, 90, 200),
		maxLevel = 1,
		base = { damage = 30, cooldown = 2.5, amount = 3, interval = 0.15, pierce = -1, projSpeed = 40, duration = 4, size = 1.4, knockback = 0.8, halfX = 34, halfZ = 22, hitEvery = 0.35, blast = 4.5, blastFlash = 0.15 },
	},
	{
		id = "hellfire",
		name = "Chama Infernal",
		desc = "Varinha evoluída: meteoros enormes que atravessam tudo.",
		kind = "fireball",
		evolved = true,
		from = "fireWand",
		color = Color3.fromRGB(255, 60, 20),
		maxLevel = 1,
		base = { damage = 100, cooldown = 3, amount = 2, interval = 0.25, pierce = -1, projSpeed = 20, range = 60, spread = 0.3, lifetime = 3.5, size = 3, knockback = 1.5 },
	},
	{
		id = "thousandEdge",
		name = "Mil Lâminas",
		desc = "Facas evoluídas: uma chuva contínua de lâminas.",
		kind = "directional",
		evolved = true,
		from = "knife",
		color = Color3.fromRGB(240, 240, 255),
		maxLevel = 1,
		base = { damage = 15, cooldown = 0.12, amount = 2, interval = 0.04, pierce = 3, projSpeed = 90, spread = 1.2, size = 0.6, knockback = 0.5 },
	},
}
