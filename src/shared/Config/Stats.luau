--!strict
-- Os stats do jogador (conceito do VS, nomes nossos). Todo bonus SOMA no valor:
--   kind "mult": base 1 (100%); +0.1 = +10%. Recarga negativa = ataca mais rapido.
--   kind "add":  base 0; soma direta (armadura, quantidade, ressurreicao...).
-- Fontes de bonus: classe, PowerUps (lobby), passivas (run), arcano e aventura.
-- fmt: como o cliente mostra ("pct" = porcentagem, "num" = numero, "hps" = vida/s).
-- Textos com acento = o que o jogador ve.
return {
	{ id = "might", name = "Poder", kind = "mult", fmt = "pct", desc = "Dano de todas as armas." },
	{ id = "armor", name = "Armadura", kind = "add", fmt = "num", desc = "Reduz o dano de cada golpe recebido." },
	{ id = "health", name = "Vida Máx.", kind = "mult", fmt = "pct", desc = "Vida máxima." },
	{ id = "recovery", name = "Recuperação", kind = "add", fmt = "hps", desc = "Vida regenerada por segundo." },
	{ id = "cooldown", name = "Recarga", kind = "mult", fmt = "pct", desc = "Tempo entre ataques (menos é melhor)." },
	{ id = "area", name = "Área", kind = "mult", fmt = "pct", desc = "Tamanho dos ataques." },
	{ id = "speed", name = "Velocidade", kind = "mult", fmt = "pct", desc = "Velocidade dos projéteis." },
	{ id = "duration", name = "Duração", kind = "mult", fmt = "pct", desc = "Duração dos efeitos das armas." },
	{ id = "amount", name = "Quantidade", kind = "add", fmt = "num", desc = "Projéteis extras por ataque." },
	{ id = "moveSpeed", name = "Movimento", kind = "mult", fmt = "pct", desc = "Velocidade de corrida." },
	{ id = "magnet", name = "Ímã", kind = "mult", fmt = "pct", desc = "Raio para puxar gemas de XP." },
	{ id = "luck", name = "Sorte", kind = "mult", fmt = "pct", desc = "4ª opção no level up, baús melhores, mais itens." },
	{ id = "growth", name = "Crescimento", kind = "mult", fmt = "pct", desc = "XP ganho." },
	{ id = "greed", name = "Ganância", kind = "mult", fmt = "pct", desc = "Ouro ganho." },
	{ id = "curse", name = "Maldição", kind = "mult", fmt = "pct", desc = "Mais inimigos, com mais vida (mais XP e mais risco)." },
	{ id = "revival", name = "Ressurreição", kind = "add", fmt = "num", desc = "Volta à vida ao cair." },
}
