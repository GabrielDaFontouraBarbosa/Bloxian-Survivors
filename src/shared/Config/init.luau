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

return Config
