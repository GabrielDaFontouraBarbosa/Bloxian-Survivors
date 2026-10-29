--!strict
-- Conquistas: condicao -> recompensa (a arvore de desbloqueios estilo VS).
-- Condicoes (`kind`):
--   killsTotal n | killsEnemy enemy n | bossKills n          (somam na vida toda)
--   surviveMinutes n [class] [stage] | reachLevel n [class]  (numa unica run)
--   evolveAny | evolve weapon | evolveDistinct n | weaponMax weapon
--   goldTotal n | chestsTotal n | pickup pickup n | runs n
--   completeStage stage | adventureChapter adventure chapter
-- Recompensa (`reward.kind`): class (libera para comprar), weapon, passive, arcana,
--   stage, adventure (liberam direto) ou gold (`amount`).
return {
	-- abates
	{ id = "firstBlood", name = "Primeiro Sangue", desc = "Derrote 1 inimigo.", kind = "killsTotal", n = 1, reward = { kind = "gold", amount = 25 } },
	{ id = "kill100", name = "Caçada Começou", desc = "Derrote 100 inimigos.", kind = "killsTotal", n = 100, reward = { kind = "passive", id = "crown" } },
	{ id = "kill500", name = "Andarilho da Noite", desc = "Derrote 500 inimigos.", kind = "killsTotal", n = 500, reward = { kind = "class", id = "rogue" } },
	{ id = "kill2000", name = "Enxame Sem Fim", desc = "Derrote 2.000 inimigos.", kind = "killsTotal", n = 2000, reward = { kind = "arcana", id = "swarm" } },
	{ id = "kill10000", name = "Massacre", desc = "Derrote 10.000 inimigos.", kind = "killsTotal", n = 10000, reward = { kind = "arcana", id = "fury" } },
	{ id = "skull200", name = "Quebra-Crânios", desc = "Derrote 200 Crânios Flutuantes.", kind = "killsEnemy", enemy = "skull", n = 200, reward = { kind = "class", id = "garlicWitch" } },
	{ id = "bat1000", name = "Noite Sem Morcegos", desc = "Derrote 1.000 Morcegos.", kind = "killsEnemy", enemy = "bat", n = 1000, reward = { kind = "passive", id = "stoneMask" } },
	{ id = "boss1", name = "Matador de Gigantes", desc = "Derrote 1 chefe.", kind = "bossKills", n = 1, reward = { kind = "class", id = "priest" } },
	{ id = "boss10", name = "Colecionador de Troféus", desc = "Derrote 10 chefes.", kind = "bossKills", n = 10, reward = { kind = "passive", id = "reliquary" } },

	-- sobrevivencia e nivel (numa run)
	{ id = "survive1", name = "Primeiro Minuto", desc = "Sobreviva 1 minuto.", kind = "surviveMinutes", n = 1, reward = { kind = "weapon", id = "bible" } },
	{ id = "survive5", name = "Pele Grossa", desc = "Sobreviva 5 minutos.", kind = "surviveMinutes", n = 5, reward = { kind = "class", id = "lumberjack" } },
	{ id = "survive10", name = "A Noite Avança", desc = "Sobreviva 10 minutos.", kind = "surviveMinutes", n = 10, reward = { kind = "adventure", id = "eternalNight" } },
	{ id = "survive15", name = "Olho da Tempestade", desc = "Sobreviva 15 minutos.", kind = "surviveMinutes", n = 15, reward = { kind = "class", id = "stormcaller" } },
	{ id = "survive20", name = "Tempo Emprestado", desc = "Sobreviva 20 minutos.", kind = "surviveMinutes", n = 20, reward = { kind = "arcana", id = "time" } },
	{ id = "hunter20", name = "Veterano", desc = "Sobreviva 20 minutos com o Caçador.", kind = "surviveMinutes", n = 20, class = "hunter", reward = { kind = "gold", amount = 500 } },
	{ id = "level10", name = "Estudante", desc = "Chegue ao nível 10.", kind = "reachLevel", n = 10, reward = { kind = "class", id = "sorceress" } },
	{ id = "level20", name = "Devoto", desc = "Chegue ao nível 20.", kind = "reachLevel", n = 20, reward = { kind = "weapon", id = "cross" } },
	{ id = "level25", name = "Em Dobro", desc = "Chegue ao nível 25.", kind = "reachLevel", n = 25, reward = { kind = "passive", id = "duplicator" } },
	{ id = "level50", name = "Força Vital", desc = "Chegue ao nível 50.", kind = "reachLevel", n = 50, reward = { kind = "arcana", id = "life" } },

	-- armas
	{ id = "maxWhip", name = "Mestre do Chicote", desc = "Leve o Chicote ao nível máximo.", kind = "weaponMax", weapon = "whip", reward = { kind = "weapon", id = "water" } },
	{ id = "maxWand", name = "Mestre do Cetro", desc = "Leve o Cetro Arcano ao nível máximo.", kind = "weaponMax", weapon = "wand", reward = { kind = "weapon", id = "lightning" } },
	{ id = "maxKnife", name = "Mãos Rápidas", desc = "Leve as Adagas ao nível máximo.", kind = "weaponMax", weapon = "knife", reward = { kind = "passive", id = "clover" } },
	{ id = "evolveAny", name = "Transmutação", desc = "Evolua qualquer arma.", kind = "evolveAny", reward = { kind = "class", id = "monk" } },
	{ id = "evolve3", name = "Alquimista", desc = "Evolua 3 armas diferentes.", kind = "evolveDistinct", n = 3, reward = { kind = "arcana", id = "moon" } },
	{ id = "evolveWhip", name = "Sangue no Couro", desc = "Evolua o Chicote no Açoite Sangrento.", kind = "evolve", weapon = "bloodyWhip", reward = { kind = "gold", amount = 300 } },

	-- economia e itens
	{ id = "gold1000", name = "Bolso Cheio", desc = "Junte 1.000 de ouro (total).", kind = "goldTotal", n = 1000, reward = { kind = "arcana", id = "greed" } },
	{ id = "gold5000", name = "Pacto Sombrio", desc = "Junte 5.000 de ouro (total).", kind = "goldTotal", n = 5000, reward = { kind = "passive", id = "cursedSkull" } },
	{ id = "chests5", name = "Caçador de Baús", desc = "Abra 5 baús.", kind = "chestsTotal", n = 5, reward = { kind = "arcana", id = "magnet" } },
	{ id = "rosary1", name = "Purificação", desc = "Pegue um Rosário.", kind = "pickup", pickup = "rosary", n = 1, reward = { kind = "gold", amount = 100 } },
	{ id = "chicken10", name = "Banquete", desc = "Coma 10 Coxas Assadas.", kind = "pickup", pickup = "chicken", n = 10, reward = { kind = "gold", amount = 100 } },
	{ id = "runs10", name = "Persistente", desc = "Jogue 10 partidas.", kind = "runs", n = 10, reward = { kind = "gold", amount = 200 } },

	-- estagios e aventuras
	{ id = "forestDone", name = "A Floresta Caiu", desc = "Sobreviva até a Ceifadora na Floresta Maldita.", kind = "completeStage", stage = "forest", reward = { kind = "stage", id = "graveyard" } },
	{ id = "graveyardDone", name = "Dona da Foice", desc = "Sobreviva até a Ceifadora no Cemitério Esquecido.", kind = "completeStage", stage = "graveyard", reward = { kind = "class", id = "reaper" } },
	{ id = "nightDone", name = "Amanheceu", desc = "Termine a aventura A Noite Sem Fim.", kind = "adventureChapter", adventure = "eternalNight", chapter = 3, reward = { kind = "adventure", id = "boneTrial" } },
	{ id = "bonesDone", name = "Ossos do Ofício", desc = "Termine a aventura Provação dos Ossos.", kind = "adventureChapter", adventure = "boneTrial", chapter = 3, reward = { kind = "gold", amount = 1000 } },
}
