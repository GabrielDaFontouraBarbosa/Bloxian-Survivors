--!strict
-- Missoes: sempre Config.Meta.QuestSlots ativas. Completou -> resgata no lobby ->
-- ganha ouro e uma nova missao sorteada entra no lugar.
-- Regra do projeto (retention): SEM prazo, SEM reset diario, SEM punicao por ausencia.
-- kind:
--   kills n | killsEnemy enemy n | bossKills n | chests n | evolveAny n
--   pickups n (qualquer item de chao) | runs n | gold n (ouro levado para casa)
--   surviveMinutes n | reachLevel n   (melhor marca numa unica run)
return {
	{ id = "q_kill300", desc = "Derrote 300 inimigos.", kind = "kills", n = 300, reward = 100 },
	{ id = "q_kill1000", desc = "Derrote 1.000 inimigos.", kind = "kills", n = 1000, reward = 250 },
	{ id = "q_bats150", desc = "Derrote 150 Morcegos.", kind = "killsEnemy", enemy = "bat", n = 150, reward = 80 },
	{ id = "q_skulls100", desc = "Derrote 100 Crânios Flutuantes.", kind = "killsEnemy", enemy = "skull", n = 100, reward = 90 },
	{ id = "q_skeletons80", desc = "Derrote 80 Esqueletos.", kind = "killsEnemy", enemy = "skeleton", n = 80, reward = 100 },
	{ id = "q_boss2", desc = "Derrote 2 chefes.", kind = "bossKills", n = 2, reward = 150 },
	{ id = "q_chests3", desc = "Abra 3 baús.", kind = "chests", n = 3, reward = 120 },
	{ id = "q_evolve", desc = "Evolua uma arma.", kind = "evolveAny", n = 1, reward = 250 },
	{ id = "q_pickups10", desc = "Pegue 10 itens de chão.", kind = "pickups", n = 10, reward = 80 },
	{ id = "q_runs3", desc = "Jogue 3 partidas.", kind = "runs", n = 3, reward = 60 },
	{ id = "q_gold300", desc = "Leve 300 de ouro para casa.", kind = "gold", n = 300, reward = 100 },
	{ id = "q_survive8", desc = "Sobreviva 8 minutos numa partida.", kind = "surviveMinutes", n = 8, reward = 150 },
	{ id = "q_survive15", desc = "Sobreviva 15 minutos numa partida.", kind = "surviveMinutes", n = 15, reward = 300 },
	{ id = "q_level15", desc = "Chegue ao nível 15 numa partida.", kind = "reachLevel", n = 15, reward = 120 },
	{ id = "q_level30", desc = "Chegue ao nível 30 numa partida.", kind = "reachLevel", n = 30, reward = 250 },
}
