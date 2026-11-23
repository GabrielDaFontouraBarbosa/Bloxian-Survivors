--!strict
-- Itens de chao. O jogador pega encostando (raio Config.Run.PickupRadius).
--   effect: "gold" (soma `value` x Ganancia), "heal" (cura `value`), "rosary"
--           (mata todo inimigo comum da tela), "vacuum" (puxa todas as gemas),
--           "freeze" (congela inimigos por Config.Run.FreezeDuration), "chest" (abre bau).
--   shape:  visual simples montado pelo PickupService.
-- drops.brazier = o que uma tocha solta (peso; a Sorte aumenta os itens raros).
return {
	items = {
		{ id = "coin", name = "Moeda", effect = "gold", value = 1, shape = "coin", color = Color3.fromRGB(255, 205, 60) },
		{ id = "coinBag", name = "Saco de Moedas", effect = "gold", value = 10, shape = "bag", color = Color3.fromRGB(230, 180, 50) },
		{ id = "richBag", name = "Saco Farto", effect = "gold", value = 40, shape = "bag", color = Color3.fromRGB(255, 230, 120) },
		{ id = "chicken", name = "Coxa Assada", effect = "heal", value = 30, shape = "chicken", color = Color3.fromRGB(170, 100, 50) },
		{ id = "rosary", name = "Rosário", effect = "rosary", shape = "cross", color = Color3.fromRGB(255, 255, 255) },
		{ id = "vacuum", name = "Vácuo", effect = "vacuum", shape = "orb", color = Color3.fromRGB(90, 200, 255) },
		{ id = "clock", name = "Relógio", effect = "freeze", shape = "clock", color = Color3.fromRGB(150, 220, 255) },
		{ id = "chest", name = "Baú", effect = "chest", shape = "chest", color = Color3.fromRGB(120, 75, 40) },
	},
	drops = {
		brazier = {
			{ id = "coin", weight = 45 },
			{ id = "coinBag", weight = 18 },
			{ id = "chicken", weight = 16, rare = false },
			{ id = "richBag", weight = 5, rare = true },
			{ id = "vacuum", weight = 6, rare = true },
			{ id = "rosary", weight = 5, rare = true },
			{ id = "clock", weight = 5, rare = true },
		},
	},
}
