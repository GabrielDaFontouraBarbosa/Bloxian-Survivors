--!strict
-- Classes jogaveis (os "personagens" do VS). Cada classe = arma inicial + vida
-- base + bonus de stats + (opcional) um traco que cresce com o nivel + a skin.
-- Regra do DESIGN.md: bonus de classe pequenos e com personalidade; PowerUps sao
-- globais e modestos, para nenhuma classe virar a outra.
--   stats: bonus somados nos stats (ver Config/Stats).
--   perk:  { stat, amount, every, max } = +amount no stat a cada `every` niveis, ate `max`.
--   default = ja vem liberada E comprada. As outras: uma conquista libera, o ouro compra (price).
--   skin:  visual do personagem (server/SkinService), usado quando o jogador escolhe
--          "skin do personagem" nas Opcoes. Cores do corpo + chapeu e capa de pecas simples.
--            hat: "tricorn" | "hood" | "wizard" | "bandana"  (feather/band = enfeites do chapeu)
--            outfit: roupa completa por cima do corpo (casaco, botas, luvas...), ver
--                    OUTFITS no SkinService. Hoje so o "hunter" tem.
--
-- Conjunto atual (pedido do usuario, 2026-11): os 4 primeiros personagens do VS,
-- INSPIRADOS (nome, visual e numeros proprios), um para cada arma inicial.
return {
	{
		id = "hunter",
		name = "Caçador",
		title = "O caçador de monstros",
		desc = "Equilibrado. Fica mais forte a cada 10 níveis.",
		weapon = "whip",
		baseHp = 120,
		stats = {},
		perk = { stat = "might", amount = 0.1, every = 10, max = 0.5, desc = "+10% de Poder a cada 10 níveis (máx. +50%)." },
		default = true,
		price = 0,
		color = Color3.fromRGB(200, 170, 120),
		skin = {
			skinTone = Color3.fromRGB(234, 184, 146),
			shirt = Color3.fromRGB(125, 30, 38), -- casaco (mangas usam essa cor)
			pants = Color3.fromRGB(55, 42, 34),
			inner = Color3.fromRGB(225, 212, 188), -- camisa no decote
			trim = Color3.fromRGB(70, 18, 24), -- lapelas, manto, punhos, barra
			leather = Color3.fromRGB(48, 32, 24), -- cinto, luvas, botas
			metal = Color3.fromRGB(215, 175, 80), -- fivela e botoes
			hat = "tricorn",
			hatColor = Color3.fromRGB(40, 28, 22),
			band = Color3.fromRGB(150, 28, 36),
			feather = Color3.fromRGB(235, 232, 220),
			outfit = "hunter",
			cape = nil,
		},
	},
	{
		id = "runeSeer",
		name = "Vidente",
		title = "A leitora de runas",
		desc = "Projéteis mais rápidos e efeitos mais longos.",
		weapon = "runetracer",
		baseHp = 100,
		stats = { speed = 0.1, duration = 0.1 },
		default = true,
		price = 0,
		color = Color3.fromRGB(120, 220, 255),
		skin = {
			skinTone = Color3.fromRGB(245, 205, 175),
			shirt = Color3.fromRGB(40, 90, 130),
			pants = Color3.fromRGB(30, 45, 70),
			hat = "hood",
			hatColor = Color3.fromRGB(35, 70, 105),
			cape = Color3.fromRGB(25, 55, 90),
		},
	},
	{
		id = "pyromancer",
		name = "Piromante",
		title = "O velho do fogo",
		desc = "Dano maior, vida menor.",
		weapon = "fireWand",
		baseHp = 90,
		stats = { might = 0.15 },
		default = true,
		price = 0,
		color = Color3.fromRGB(255, 120, 40),
		skin = {
			skinTone = Color3.fromRGB(210, 160, 125),
			shirt = Color3.fromRGB(150, 45, 25),
			pants = Color3.fromRGB(70, 30, 20),
			hat = "wizard",
			hatColor = Color3.fromRGB(120, 30, 20),
			cape = Color3.fromRGB(90, 25, 15),
		},
	},
	{
		id = "rogue",
		name = "Andarilho",
		title = "O atirador de facas",
		desc = "Sempre um projétil a mais.",
		weapon = "knife",
		baseHp = 100,
		stats = { amount = 1 },
		default = true,
		price = 0,
		color = Color3.fromRGB(210, 215, 225),
		skin = {
			skinTone = Color3.fromRGB(190, 140, 105),
			shirt = Color3.fromRGB(70, 75, 85),
			pants = Color3.fromRGB(40, 40, 48),
			hat = "bandana",
			hatColor = Color3.fromRGB(170, 30, 40),
			cape = nil,
		},
	},
}
