--!strict
-- Bestiario. Inimigo = forma (server/EnemyModels monta com pecas simples, SEM
-- rig e SEM animacao) + numeros. Adicionar inimigo = adicionar entrada aqui.
--   shape:    skull, bat, skeleton, ghoul, ghost, mud, werewolf, mummy, mantis,
--             flower, brazier, reaper (ver EnemyModels).
--   move:     "chase" (reto ate o jogador), "bob" (chase flutuando), "wave"
--             (chase serpenteando), "rush" (linha reta numa direcao, some depois
--             de `lifetime`), "static" (parado; com `lifetime` some sozinho).
--   radius:   raio de contato/acerto (vezes scale).
--   kbResist: 0 = voa longe no empurrao, 1 = nao se mexe.
--   tier:     "normal" (padrao; conta no teto de inimigos comuns e reaparece se
--             ficar longe), "event" (revoada/muro), "boss" (conta como chefe nas
--             conquistas), "special" (tocha, Ceifadora). chest = solta bau ao morrer.
--   targetable = false: armas teleguiadas ignoram (tochas).
return {
	-- ============ comuns ============
	{ id = "bat", name = "Morcego", shape = "bat", color = Color3.fromRGB(70, 50, 90), scale = 1, hp = 1, speed = 9, damage = 4, xp = 1, move = "bob", bobAmp = 0.6, bobFreq = 7, radius = 1, kbResist = 0 },
	{ id = "skull", name = "Crânio Flutuante", shape = "skull", color = Color3.fromRGB(225, 220, 200), scale = 1, hp = 8, speed = 6.5, damage = 5, xp = 1, move = "bob", bobAmp = 1.0, bobFreq = 2.2, radius = 1.2, kbResist = 0 },
	{ id = "skeleton", name = "Esqueleto", shape = "skeleton", color = Color3.fromRGB(210, 210, 200), scale = 1, hp = 15, speed = 6, damage = 7, xp = 2, move = "chase", radius = 1.1, kbResist = 0.1 },
	{ id = "ghoul", name = "Carniçal", shape = "ghoul", color = Color3.fromRGB(110, 140, 90), scale = 1, hp = 22, speed = 5, damage = 8, xp = 2, move = "chase", radius = 1.3, kbResist = 0.2 },
	{ id = "ghost", name = "Fantasma", shape = "ghost", color = Color3.fromRGB(190, 210, 255), scale = 1, hp = 12, speed = 9, damage = 6, xp = 2, move = "wave", bobAmp = 0.8, bobFreq = 3, radius = 1.2, kbResist = 0 },
	{ id = "mudman", name = "Homem de Lama", shape = "mud", color = Color3.fromRGB(95, 70, 45), scale = 1, hp = 45, speed = 4.5, damage = 10, xp = 3, move = "chase", radius = 1.6, kbResist = 0.5 },
	{ id = "mantis", name = "Louva-a-Deus", shape = "mantis", color = Color3.fromRGB(110, 190, 80), scale = 1, hp = 70, speed = 7.5, damage = 12, xp = 4, move = "chase", radius = 1.4, kbResist = 0.3 },
	{ id = "werewolf", name = "Lobisomem", shape = "werewolf", color = Color3.fromRGB(80, 60, 50), scale = 1, hp = 90, speed = 9.5, damage = 13, xp = 4, move = "chase", radius = 1.6, kbResist = 0.3 },
	{ id = "mummy", name = "Múmia", shape = "mummy", color = Color3.fromRGB(210, 195, 150), scale = 1, hp = 140, speed = 5, damage = 15, xp = 5, move = "chase", radius = 1.5, kbResist = 0.6 },

	-- ============ eventos ============
	-- revoada: morcegos rapidos que cruzam a tela em linha reta (o "vem rapido na direcao")
	{ id = "swarmBat", name = "Morcego em Revoada", shape = "bat", color = Color3.fromRGB(150, 30, 50), scale = 1.1, hp = 3, speed = 26, damage = 5, xp = 1, move = "rush", lifetime = 6, radius = 1.1, kbResist = 1, tier = "event" },
	-- muro de flores: um anel que prende o jogador por um tempo
	{ id = "flower", name = "Flor Carnívora", shape = "flower", color = Color3.fromRGB(200, 40, 70), scale = 1, hp = 30, speed = 0, damage = 10, xp = 1, move = "static", lifetime = 40, radius = 1.3, kbResist = 1, tier = "event" },

	-- ============ chefes (soltam bau) ============
	{ id = "giantBat", name = "Morcego Gigante", shape = "bat", color = Color3.fromRGB(120, 20, 40), scale = 3, hp = 300, speed = 10, damage = 15, xp = 30, move = "bob", bobAmp = 1.2, bobFreq = 3, radius = 1.2, kbResist = 0.9, tier = "boss", chest = true },
	{ id = "giantMantis", name = "Louva-a-Deus Gigante", shape = "mantis", color = Color3.fromRGB(70, 160, 50), scale = 2.6, hp = 1200, speed = 8, damage = 25, xp = 60, move = "chase", radius = 1.4, kbResist = 1, tier = "boss", chest = true },
	{ id = "giantSkull", name = "Crânio Ancestral", shape = "skull", color = Color3.fromRGB(240, 230, 190), scale = 3, hp = 900, speed = 7, damage = 22, xp = 50, move = "bob", bobAmp = 1.5, bobFreq = 1.5, radius = 1.2, kbResist = 1, tier = "boss", chest = true },
	{ id = "bigMummy", name = "Múmia Colossal", shape = "mummy", color = Color3.fromRGB(230, 210, 160), scale = 2.6, hp = 2500, speed = 6, damage = 30, xp = 80, move = "chase", radius = 1.5, kbResist = 1, tier = "boss", chest = true },
	{ id = "giantVenus", name = "Vênus Colossal", shape = "flower", color = Color3.fromRGB(220, 30, 90), scale = 3.2, hp = 4000, speed = 5.5, damage = 35, xp = 100, move = "chase", radius = 1.3, kbResist = 1, tier = "boss", chest = true },
	{ id = "boneLord", name = "Senhor dos Ossos", shape = "skeleton", color = Color3.fromRGB(240, 235, 220), scale = 2.8, hp = 1800, speed = 7, damage = 28, xp = 70, move = "chase", radius = 1.1, kbResist = 1, tier = "boss", chest = true },

	-- ============ especiais ============
	-- tocha: quebra com qualquer golpe e solta item (tabela "brazier" em Config/Pickups)
	{ id = "brazier", name = "Tocha", shape = "brazier", color = Color3.fromRGB(60, 55, 60), scale = 1, hp = 1, speed = 0, damage = 0, xp = 0, move = "static", radius = 1, kbResist = 1, targetable = false, drops = "brazier", tier = "special" },
	-- a Ceifadora: chega no fim do tempo e encerra a run (chegar ate ela = estagio completo)
	{ id = "reaper", name = "A Ceifadora", shape = "reaper", color = Color3.fromRGB(25, 20, 30), scale = 2.2, hp = 9999999, speed = 30, damage = 99999, xp = 0, move = "chase", radius = 1.3, kbResist = 1, tier = "special" },
}
