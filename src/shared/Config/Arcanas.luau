--!strict
-- Arcanos (as "cartas" do VS): escolhe 1 no lobby antes da run. Mudam as regras.
--   stats: bonus somados nos stats (ver Config/Stats).
--   flags: regras especiais lidas pelo servidor:
--     evolveWithoutPassive -> arma no nivel maximo evolui no bau mesmo sem a passiva par.
-- Nenhum vem liberado: todos saem de conquistas.
return {
	{ id = "fury", name = "Arcano da Fúria", desc = "+30% de Poder, mas -20% de Vida Máx.", stats = { might = 0.3, health = -0.2 }, color = Color3.fromRGB(220, 50, 50) },
	{ id = "swarm", name = "Arcano do Enxame", desc = "+1 de Quantidade, mas +25% de Maldição.", stats = { amount = 1, curse = 0.25 }, color = Color3.fromRGB(150, 60, 200) },
	{ id = "greed", name = "Arcano da Ganância", desc = "+60% de Ganância, mas +20% de Maldição.", stats = { greed = 0.6, curse = 0.2 }, color = Color3.fromRGB(255, 210, 60) },
	{ id = "time", name = "Arcano do Tempo", desc = "+30% de Duração e -10% de Recarga.", stats = { duration = 0.3, cooldown = -0.1 }, color = Color3.fromRGB(120, 200, 255) },
	{ id = "life", name = "Arcano da Vida", desc = "+50% de Vida Máx. e +1 de Recuperação.", stats = { health = 0.5, recovery = 1 }, color = Color3.fromRGB(90, 210, 110) },
	{ id = "magnet", name = "Arcano do Ímã", desc = "+100% de Ímã e +20% de Crescimento.", stats = { magnet = 1, growth = 0.2 }, color = Color3.fromRGB(80, 200, 255) },
	{ id = "moon", name = "Arcano da Lua", desc = "Armas no nível máximo evoluem no baú sem precisar da passiva.", stats = {}, flags = { evolveWithoutPassive = true }, color = Color3.fromRGB(220, 220, 255) },
}
