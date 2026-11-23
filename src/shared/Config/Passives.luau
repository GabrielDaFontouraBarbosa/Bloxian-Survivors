--!strict
-- Catalogo de passivas (itens que mexem nos stats durante a run, estilo VS).
-- Cada nivel soma `per` no stat `stat` (ver Config/Stats). `evolves` e so texto
-- de ajuda: a regra de evolucao fica na arma (Config/Weapons, campo evolution).
-- default = liberada desde o inicio; as outras vem de conquistas.
return {
	{ id = "wolfFang", name = "Presa de Lobo", stat = "might", per = 0.1, maxLevel = 5, rarity = 100, default = true, color = Color3.fromRGB(200, 60, 60), desc = "+10% de Poder por nível." },
	{ id = "armor", name = "Armadura", stat = "armor", per = 1, maxLevel = 5, rarity = 100, default = true, color = Color3.fromRGB(150, 150, 165), desc = "+1 de Armadura por nível." },
	{ id = "hollowHeart", name = "Coração Oco", stat = "health", per = 0.2, maxLevel = 5, rarity = 100, default = true, color = Color3.fromRGB(220, 70, 110), desc = "+20% de Vida Máx. por nível.", evolves = "whip" },
	{ id = "vitalTomato", name = "Tomate Vital", stat = "recovery", per = 0.2, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(230, 80, 50), desc = "+0,2 de vida por segundo por nível.", evolves = "garlic" },
	{ id = "emptyTome", name = "Tomo Vazio", stat = "cooldown", per = -0.08, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(120, 140, 220), desc = "-8% de Recarga por nível.", evolves = "wand" },
	{ id = "candelabra", name = "Candelabro", stat = "area", per = 0.1, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(240, 190, 90), desc = "+10% de Área por nível.", evolves = "axe" },
	{ id = "bracer", name = "Braçadeira", stat = "speed", per = 0.1, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(160, 120, 80), desc = "+10% de Velocidade de projétil por nível.", evolves = "knife" },
	{ id = "spellbinder", name = "Encantamento", stat = "duration", per = 0.1, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(170, 100, 220), desc = "+10% de Duração por nível.", evolves = "bible" },
	{ id = "wings", name = "Asas", stat = "moveSpeed", per = 0.1, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(230, 230, 240), desc = "+10% de Movimento por nível." },
	{ id = "attractor", name = "Orbe Atrator", stat = "magnet", per = 0.4, maxLevel = 5, rarity = 90, default = true, color = Color3.fromRGB(90, 200, 255), desc = "+40% de Ímã por nível.", evolves = "water" },
	{ id = "duplicator", name = "Duplicador", stat = "amount", per = 1, maxLevel = 2, rarity = 60, color = Color3.fromRGB(255, 255, 255), desc = "+1 de Quantidade por nível.", evolves = "lightning" },
	{ id = "clover", name = "Trevo", stat = "luck", per = 0.1, maxLevel = 5, rarity = 80, color = Color3.fromRGB(90, 200, 90), desc = "+10% de Sorte por nível.", evolves = "cross" },
	{ id = "crown", name = "Coroa", stat = "growth", per = 0.08, maxLevel = 5, rarity = 70, color = Color3.fromRGB(255, 210, 60), desc = "+8% de Crescimento (XP) por nível." },
	{ id = "stoneMask", name = "Máscara de Pedra", stat = "greed", per = 0.1, maxLevel = 5, rarity = 70, color = Color3.fromRGB(140, 130, 120), desc = "+10% de Ganância (ouro) por nível." },
	{ id = "cursedSkull", name = "Caveira Maldita", stat = "curse", per = 0.1, maxLevel = 5, rarity = 50, color = Color3.fromRGB(110, 60, 130), desc = "+10% de Maldição por nível: mais inimigos, mais XP." },
	{ id = "reliquary", name = "Relicário", stat = "revival", per = 1, maxLevel = 2, rarity = 40, color = Color3.fromRGB(255, 240, 180), desc = "+1 Ressurreição por nível." },
}
