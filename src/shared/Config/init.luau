--!strict
-- Tabela central de balanceamento. Numeros do jogo ficam aqui, nunca no codigo.
-- O CONTEUDO (armas, inimigos, classes, conquistas...) mora nos submodulos desta
-- pasta: adicionar conteudo novo = adicionar uma entrada no catalogo certo.
-- Mecanicas portadas do Vampire Survivors: ver PORTE-VS.md.
local Config = {}

-- Camera de cima que segue o personagem.
Config.Camera = {
	Offset = Vector3.new(0, 50, 20), -- alto e um pouco atras
	Smoothing = 0.15, -- 0 = gruda no alvo, perto de 1 = bem lento
}

-- Lobby: onde o jogador nasce e volta depois de cada run.
Config.Lobby = {
	SpawnFallback = Vector3.new(0, 5, 0), -- usado se o mapa nao tiver SpawnLocation
	WalkSpeed = 16,
	MaxHealth = 100,
}

-- Partida (run). Uma por jogador, cada uma no seu "andar" (arena empilhada em Y).
Config.Run = {
	ArenaBaseY = 1000, -- altura do chao da primeira arena (o lobby fica embaixo)
	ArenaSpacing = 1000, -- distancia vertical entre arenas
	FloorSize = 2048, -- chao quadrado que segue o jogador (mapa infinito)
	FloorRecenter = 300, -- recentra o chao quando o jogador se afasta disto
	FloorSnap = 64, -- recentra em passos fixos (textura nao "pula")

	MaxEnemies = 120, -- teto de inimigos comuns vivos por run (performance)
	HardCapEnemies = 210, -- teto absoluto: deixa folga para revoadas/aneis alem dos comuns
	SpawnRadius = 55, -- anel onde inimigos nascem (fora da tela)
	RelocateDistance = 95, -- inimigo comum mais longe que isto reaparece no anel
	ContactCooldown = 0.8, -- s entre acertos do mesmo inimigo no jogador
	PlayerRadius = 1.6, -- "tamanho" do jogador para contato

	BasePlayerSpeed = 16, -- WalkSpeed com MoveSpeed 100%
	MaxWeapons = 6,
	MaxPassives = 6,
	BaseOptions = 3, -- escolhas no level up (a Sorte pode dar a 4a)

	BaseMagnet = 7, -- raio base de puxar XP (studs), vezes o stat Ima
	CollectRadius = 2.5, -- distancia para pegar a gema
	PickupRadius = 3.5, -- distancia para pegar item de chao
	GemSpeed = 45,
	GemPoolSize = 900, -- compartilhado entre runs (250/run); folga para varias simultaneas
	MaxPickups = 60, -- itens de chao por run (o mais velho some)

	EnemyCoinChance = 0.01, -- chance de inimigo comum soltar moeda (vezes Sorte)
	ReviveHealthFraction = 0.5, -- volta com metade da vida ao ressuscitar
	ReviveInvuln = 2, -- s invulneravel depois de ressuscitar
	ChestAutoContinue = 12, -- s ate o bau fechar sozinho (nao trava a run)
	RespawnDelay = 2.5, -- s ate renascer no lobby depois de morrer
	SyncInterval = 0.2, -- s entre atualizacoes do HUD
	FreezeDuration = 10, -- s do Relogio
}

-- Gemas de XP: cor/tamanho por faixa de valor (azul < verde < vermelha).
Config.Xp = {
	Tiers = {
		{ min = 0, color = Color3.fromRGB(80, 200, 255), size = 0.9 },
		{ min = 5, color = Color3.fromRGB(90, 230, 120), size = 1.2 },
		{ min = 25, color = Color3.fromRGB(255, 70, 90), size = 1.6 },
	},
}

-- XP para subir do nivel N ao N+1 (curva estilo VS: degraus de +10, +13, +16).
Config.Progression = {
	First = 5, -- nivel 1 -> 2
	StepEarly = 10, -- ate o nivel 20
	StepMid = 13, -- 20 a 40
	StepLate = 16, -- 40+
	MidFrom = 20,
	LateFrom = 40,
}

-- Bau de chefe: quantos itens vem (a Sorte melhora) e quanto ouro.
Config.Chest = {
	ThreeChance = 0.12, -- chance de 3 itens (vezes Sorte)
	FiveChance = 0.04, -- chance de 5 itens (vezes Sorte)
	GoldBase = 20,
	GoldPerItem = 10,
	LevelUpGold = 25, -- ouro quando nao ha mais nada para subir
	LevelUpHeal = 30, -- cura quando nao ha mais nada para subir
}

-- Meta-progressao (entre partidas). Regra do projeto (retention): ouro e pago
-- mesmo morrendo, NAO existe punicao por ficar ausente, missoes nao expiram.
Config.Meta = {
	DataStoreName = "SurvivorsProfiles_v1", -- mesmo store; perfil tem campo de versao
	SaveIntervalSec = 30, -- flush periodico (respeita rate limit)
	PowerUpMarkup = 0.1, -- cada rank comprado encarece todos os PowerUps em 10%
	QuestSlots = 3,
	DefaultClassId = "hunter",
	DefaultStageId = "forest",
}

-- Catalogos de conteudo (cada um e uma lista de entradas com `id`).
Config.Stats = require(script.Stats)
Config.Weapons = require(script.Weapons)
Config.Passives = require(script.Passives)
Config.Classes = require(script.Classes)
Config.Enemies = require(script.Enemies)
Config.Stages = require(script.Stages)
Config.Pickups = require(script.Pickups)
Config.PowerUps = require(script.PowerUps)
Config.Arcanas = require(script.Arcanas)
Config.Achievements = require(script.Achievements)
Config.Quests = require(script.Quests)
Config.Adventures = require(script.Adventures)

-- Compatibilidade com o passo "classes como dado" (SaveService/MetaService antigos).
Config.DefaultClassId = Config.Meta.DefaultClassId

return Config
