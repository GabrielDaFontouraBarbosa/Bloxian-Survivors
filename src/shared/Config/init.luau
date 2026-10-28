--!strict
-- Tabela central de balanceamento. Numeros do jogo ficam aqui, nunca no codigo.
local Config = {}

-- Camera de cima que segue o personagem.
Config.Camera = {
	-- Deslocamento da camera em relacao ao personagem (studs).
	-- Alto e um pouco atras = visao de cima levemente inclinada,
	-- o bastante para os controles WASD continuarem intuitivos.
	Offset = Vector3.new(0, 50, 20),
	-- Suavizacao do movimento da camera (0 = gruda no alvo, perto de 1 = bem lento).
	Smoothing = 0.15,
}

-- Inimigos: nascem em volta do jogador e andam em linha reta ate ele.
Config.Enemy = {
	Health = 3,
	Speed = 8, -- studs/s
	ContactDamage = 5, -- dano ao encostar no jogador
	ContactCooldown = 1, -- s entre acertos do mesmo inimigo
	ContactRange = 4, -- distancia para considerar "encostou"
	Size = Vector3.new(2, 2, 2),
	Color = Color3.fromRGB(200, 60, 60),
	SpawnRadius = 60, -- distancia do jogador onde nascem
	SpawnInterval = 0.5, -- s entre spawns
	MaxAlive = 100, -- teto de inimigos vivos (performance)
	PoolSize = 120, -- parts pre-criadas para reaproveitar
	FlashColor = Color3.fromRGB(255, 255, 255), -- cor do "pisca" ao levar dano
	FlashTime = 0.08, -- s que o pisca dura
	XpReward = 1, -- gemas soltas ao morrer
}

-- Chefe: inimigo grande e tanky que aparece a cada N ondas.
Config.Boss = {
	Health = 120,
	Speed = 6,
	ContactDamage = 20,
	Size = Vector3.new(6, 6, 6),
	Color = Color3.fromRGB(140, 20, 160),
	XpReward = 12, -- solta uma chuva de gemas
}

-- Ondas e dificuldade crescente. A curva toda mora aqui (retention: tuning).
Config.Wave = {
	Duration = 20, -- s por onda
	BossEveryWaves = 3, -- chefe no inicio de cada 3a onda
	SpawnIntervalStart = 0.5, -- s entre spawns na onda 1
	SpawnIntervalStep = 0.04, -- diminui por onda
	SpawnIntervalMin = 0.12, -- piso
	HealthStepPerWave = 0.15, -- vida *= 1 + step*(onda-1)
	SpeedStepPerWave = 0.04, -- velocidade *= 1 + step*(onda-1)
	SpeedMax = 22, -- teto de velocidade do inimigo
}

-- Arma automatica: mira no inimigo mais proximo e atira sozinha.
Config.Weapon = {
	Damage = 2,
	FireInterval = 0.35, -- s entre tiros
	Range = 40, -- so mira em inimigos dentro deste alcance
	ProjectileSpeed = 60, -- studs/s
	ProjectileSize = Vector3.new(0.6, 0.6, 0.6),
	ProjectileColor = Color3.fromRGB(255, 240, 120),
	HitRadius = 1.8, -- distancia do alvo para contar acerto
	Lifetime = 2, -- s ate o projetil se recolher se nao acertar
	PoolSize = 200,
}

-- Gemas de XP que os inimigos soltam ao morrer.
Config.Xp = {
	GemValue = 1,
	GemSize = Vector3.new(1, 1, 1),
	GemColor = Color3.fromRGB(80, 200, 255),
	MagnetRadius = 14, -- o jogador comeca a puxar a gema
	CollectRadius = 2.5, -- distancia para coletar
	GemSpeed = 40, -- velocidade da gema indo ate o jogador
	PoolSize = 300,
}

-- Stats base do jogador (PlayerStats parte daqui; upgrades sobem a partir disto).
Config.Player = {
	WalkSpeed = 16, -- padrao do Roblox
	MaxHealth = 100,
}

-- Progressao de nivel. XP para ir do nivel N ao N+1 = round(BaseXp * Growth^(N-1)).
Config.Progression = {
	BaseXp = 5, -- primeiro level up vem cedo (~5 gemas)
	Growth = 1.35, -- cada nivel custa 35% a mais
	FireIntervalMin = 0.08, -- piso da cadencia (upgrade de firerate nao passa disso)
}

-- Catalogo de upgrades do level up. So dados; o efeito fica no PlayerStats.
Config.Upgrades = {
	{ id = "damage", name = "+Dano", desc = "+1 de dano por tiro", amount = 1 },
	{ id = "firerate", name = "+Cadencia", desc = "-15% no tempo entre tiros", mult = 0.85 },
	{ id = "speed", name = "+Velocidade", desc = "+2 de velocidade de corrida", amount = 2 },
	{ id = "health", name = "+Vida", desc = "+20 de vida maxima (e cura)", amount = 20 },
	{ id = "magnet", name = "+Iman", desc = "+5 de raio de coleta de XP", amount = 5 },
}

-- Meta-progressao: moeda permanente e perks que ficam entre partidas.
-- Regra do projeto (retention): a moeda e paga mesmo morrendo e NAO existe
-- punicao por ficar ausente. Perks aceleram a habilidade, nao travam conteudo.
Config.Meta = {
	CoinPerKill = 1,
	SaveIntervalSec = 30, -- flush periodico no DataStore (respeita rate limit)
	DataStoreName = "SurvivorsProfiles_v1",
	Perks = {
		{
			id = "damage",
			field = "damage",
			name = "Dano permanente",
			desc = "+1 de dano base",
			amount = 1,
			baseCost = 10,
			costGrowth = 1.6,
		},
		{
			id = "health",
			field = "maxHealth",
			name = "Vida permanente",
			desc = "+20 de vida base",
			amount = 20,
			baseCost = 12,
			costGrowth = 1.6,
		},
		{
			id = "speed",
			field = "walkSpeed",
			name = "Velocidade permanente",
			desc = "+1 de velocidade base",
			amount = 1,
			baseCost = 15,
			costGrowth = 1.8,
		},
	},
}

return Config
