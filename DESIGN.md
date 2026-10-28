# DESIGN.md — arte, lore e decisões de design

Leia ao mexer em personagem, visual, conteúdo ou identidade do jogo. Mecânica e balanceamento ficam no `CLAUDE.md` e no `Config`; retenção na skill `retention`.

Este documento registra **decisões tomadas e perguntas ainda abertas**. Atualize quando algo for decidido, movendo da seção "Em aberto" para "Decidido".

---

## 0. Tom e visual — DECIDIDO (2026-10-28)

**Tom:** Vampire Survivors raiz — terror gótico / caça-monstros estilo Castlevania. Nada de pet quadrado nem rig padrão do Roblox: a identidade própria é o antídoto ao visual genérico de free model que domina o gênero no Roblox (é a brecha de diferenciação).

**Execução visual:** gótico limpo em **low-poly 3D** — NÃO tentar emular o pixel art 2D do VS. Monstros 3D simples mas de silhueta clara, arena escura com luz de lua e magia brilhante. Captura o *tom* do VS respeitando a câmera top-down e o teste dos 40px (seção 2).

Decorre daí (detalhar quando cada um for implementado):
- **Boneco:** caçador solitário (casaco/chapéu/chicote), não o avatar padrão.
- **Inimigos:** bestiário clássico — morcego, esqueleto, caveira voadora, ghoul; chefe tipo ceifador/lorde. Cada um com silhueta bem distinta.
- **Armas:** fantasia do VS — chicote, cruz, alho, bíblia, água benta — no lugar de "projétil genérico".
- **Paleta:** a atual já encaixa (inimigo vermelho, chefe roxo, gema azul-neon, projétil amarelo = VS gótico). Falta fundo escuro + luz de lua.

---

## 1. A pergunta central: personagens desbloqueáveis ou um boneco que upa?

**Decisão de rumo (2026-10-28): os dois, em ordem — e personagem tratado como DADO desde já.**

Os dois fazem trabalhos diferentes e não competem:

| Sistema | O que entrega | Métrica |
|---|---|---|
| Upgrade permanente do boneco (feito) | sensação de poder crescendo; motor do "só mais uma" | D1 / D7 |
| Personagens desbloqueáveis (não feito) | variedade e meta visível de médio prazo; o "quero testar o outro" | D7 / D30 |

O Vampire Survivors usa os dois: os upgrades permanentes são **globais e modestos**, e cada personagem muda a **arma inicial e o jeito que a run começa**.

**Plano:** começar com 1 personagem. **Não** construir a tela de desbloqueio agora — só deixar o formato de dados pronto.

**Por que é barato:** o `PlayerStats` já funciona em duas camadas (base permanente vs. stats da run) e a base é calculada de `Config + perks`. Um personagem é **uma entrada numa tabela de Config**: stats iniciais + arma inicial + aparência. Entra na mesma conta, sem refactor.

### Regra pra não sabotar o sistema
Se personagens vão existir, **a loja permanente não pode deixar maxar tudo**. Se der, todo personagem converge pro mesmo boneco e o desbloqueio perde sentido.

- Perks permanentes: **modestos e globais**.
- Personalidade: **no personagem** (arma inicial, um ponto forte, um ponto fraco).

---

## 2. Restrição visual que manda aqui

Câmera de cima, longe, com até 100 inimigos na tela (`Config.Enemy.MaxAlive`). Nesse contexto **silhueta e cor ganham de detalhe** — detalhe simplesmente desaparece.

O jogador precisa ler três coisas em meio segundo:

1. **Eu** — tem que destacar de todo o resto.
2. **Inimigo comum vs. chefe** — tamanho + cor diferentes (hoje: cubo vermelho vs. cubo roxo grande).
3. **Gema de XP** — brilho (hoje: Neon azul), nunca confundível com inimigo.

**Teste prático ao desenhar:** olhe o boneco num quadradinho de ~40px. Se virar uma mancha indistinguível, o design não serve pra este jogo, por bonito que seja.

Cores atuais ocupadas (ver `src/shared/Config`): inimigo vermelho `200,60,60`; chefe roxo `140,20,160`; gema azul `80,200,255`; projétil amarelo `255,240,120`; moedas (HUD) amarelo `255,220,90`.

---

## 3. Papel da lore (sendo honesto)

Lore no Roblox **quase não move retenção sozinha**. O que ela faz bem:

- Dá **personalidade** e torna o jogo seu — motivação do dev, que não é pouco.
- Alimenta o que **de fato** importa pra descoberta no Roblox: **nome, ícone e thumbnail**.
- Vira texto de sabor nas descrições de personagens e upgrades — barato e eficaz.

**Conclusão:** investir em lore o quanto der vontade, e usá-la pra decidir nome/ícone. Não esperar que prenda jogador — isso é o loop e os ganchos de retenção.

---

## 4. Em aberto (perguntar ao usuário; não presumir)

- ~~**Tom / vibe.**~~ DECIDIDO — ver seção 0 (VS gótico, low-poly 3D limpo).
- **Nome do jogo.** Hoje o repo se chama "Bloxian Survivors" — placeholder, não decisão. Agora com o tom definido (seção 0), dá pra puxar um nome gótico/caça-monstros.
- **Origem dos assets.** Direção é low-poly 3D próprio e simples (seção 0); falta decidir a fonte: formas simples (atual), rigs de avatar Roblox + acessórios (barato), Creator Store, ou modelagem própria em Blender (caro). Reaproveitar rig de avatar é muito mais rápido que modelar.
- **Quantos personagens no lançamento** e qual o eixo de diferença entre eles (arma inicial? stat marcante?).
- **Plataformas alvo** (PC, celular, console) — afeta UI e controles. O painel de upgrade e a loja hoje assumem mouse/clique.
- **Solo ou co-op** (a skill `retention` aponta co-op como candidato forte depois do loop estar bom).

---

## 5. Ganchos de retenção ainda não implementados

Vêm da skill `retention` (seção 4 do RETENCAO original). Nenhum foi feito:

- **Gancho do dia 2:** ao morrer, mostrar algo quase alcançado (ex.: "faltam 7 moedas pro próximo nível de Dano").
- **Recompensa diária sem punição:** bônus por voltar, nunca zerar progresso por ausência (regra firme do projeto — FOMO é dark pattern com público jovem).
- **Desbloqueio de personagens/armas** como meta de médio prazo (depende da seção 1).
