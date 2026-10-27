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

return Config
