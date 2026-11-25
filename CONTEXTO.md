# CONTEXTO.md — onde o projeto está e por quê

Leia no começo de uma sessão nova. É curto de propósito: tudo que está aqui é reenviado a cada mensagem. Ao fim de cada passo do roteiro, atualize só a seção 3 (máx. 5 linhas) e mova decisões resolvidas da seção 4 para a 2. Não cole código aqui.

## 1. Projeto em 3 frases
Jogo no Roblox estilo Vampire Survivors ("bullet heaven"): o jogador só se move, as armas atacam sozinhas, inimigos vêm em ondas, o jogador sobe de nível e escolhe upgrades, e há meta-progressão entre partidas (a parte "incremental"). O código é Luau, sincronizado com o Studio pelo Rojo, e é escrito com o Claude Code. Objetivo: um jogo pequeno, jogável e com boa retenção, construído um sistema por vez.

## 2. Decisões (tomadas ou adotadas no CLAUDE.md) e motivo

| Decisão | Motivo |
|---|---|
| Vampire Survivors em vez de estilo Borderlands | Borderlands exige loot com stats aleatórios, muitas armas, mapas grandes e missões (meses de trabalho). Survivors é spawn + dano + XP; o resto é conteúdo. |
| Luau + Rojo, código só por arquivos | O Claude Code edita arquivos normais e o Studio sincroniza. Sem copiar e colar script por script. |
| Servidor autoritativo, object pooling, inimigos sem pathfinding, um loop central | Centenas de inimigos na tela engasgam o Roblox se a lógica for pesada. |
| Um passo do roteiro por vez, testando antes de seguir | Evita acumular bugs e gastar tokens refazendo. |
| Meta-progressão só no passo 6 | Primeiro o loop central tem que ser divertido. |
| Retenção (D1/D7/D30) como critério de design | Ver RETENCAO.md. |
| Sessão líder + 3 subagentes baratos | Ver AGENTES.md. Economiza tokens. |

## 3. Estado atual (atualizar a cada passo)
- Data da última atualização: 2026-11-25
- Roteiro original (6 passos) concluído; depois o **porte VS** (PORTE-VS.md). Em 2026-11-25 o usuário pediu um **RECORTE estilo VS** (passo 8 do CLAUDE.md): tela de título tipo capa do VS (Jogar / PowerUps / Aventuras "em breve" / Conquistas vazia / Opções), 4 personagens inspirados nos 4 primeiros do VS (Caçador=chicote, Vidente=Runa Traçante que quica, Piromante=Varinha de Fogo, Andarilho=facas), opção de skin (avatar próprio x skin do personagem, `SkinService`) e UMA fase, **Planícies**, só com morcegos (5 tipos + revoada, cerco e 3 chefes-morcego).
- O conteúdo antigo do porte (9 armas, 9 classes, 2 estágios, 34 conquistas, missões, aventuras) saiu dos CATÁLOGOS, não do código: os comportamentos de arma e os serviços continuam. Para voltar algo, recolocar a entrada no `Config` (a versão antiga está no git, commit cd36b18). Missões e arcanos ficaram sem tela.
- **NADA disso rodou ainda** (sessão na nuvem não dá Play). O primeiro Play vai achar erros de runtime — corrigir um por vez. SkinService usa APIs de HumanoidDescription não testadas aqui (tudo em pcall).
- Pendências: (1) PLAYTEST (seção 9); (2) balanceamento é chute; (3) AnalyticsService não verificado; (4) DataStore só em jogo publicado; (5) pets e cidade 3D não feitos; (6) nome do jogo ainda placeholder (aparece na capa).
- Repo: GabrielDaFontouraBarbosa/Bloxian-Survivors. MCP do Studio inalcançável da nuvem (AGENTES.md seção 6).

## 4. Ainda não decidido (perguntar ao usuário quando o passo exigir; não presumir)
As decisões de ARTE, LORE e PERSONAGENS migraram para o DESIGN.md (seção 4), que é mais detalhado. Resumo do que falta:
- ~~Tom / vibe do jogo~~ — DECIDIDO (DESIGN.md seção 0): VS gótico, low-poly 3D limpo.
- Visão de meta-progressão (classes, armadura=upgrade+skin, pets-familiares, cidade/lobby) — DECIDIDA em direção (DESIGN.md seção 6). Loot/gear RECUSADO. O porte VS implementou classes, PowerUps (a "armadura" como stat) e um lobby em tela; faltam skins, pets e a cidade 3D.
- **Nome do jogo.** "Bloxian Survivors" é placeholder do repo, não decisão.
- ~~Personagens desbloqueáveis vs. um boneco que upa~~ — FEITO no porte: 9 classes desbloqueáveis + PowerUps globais.
- Plataformas alvo (PC, celular, console). Afeta controles e UI; Roblox roda em todas. Sugestão: testar controle de celular cedo.
- Solo ou co-op. O RETENCAO.md aponta co-op como candidato forte para depois do passo 6.
- Estilo visual e origem dos assets (formas simples, modelos próprios ou Creator Store).
- Monetização. Por enquanto nenhuma. Se um dia vender algo aleatório com Robux, ler a seção 6 do RETENCAO.md (política oficial de itens aleatórios).
- Nome do jogo e público-alvo.

## 5. Sobre o usuário e como trabalhar com ele
- Programa e já usa Claude Code no dia a dia (web: HTML/JS, banco, deploy). Tratar Roblox/Luau como novidade até ele mostrar o contrário.
- Aprende fazendo: dar o passo a passo prático e o que testar, com pouca teoria solta.
- Responder em português, direto: ideia central em 2–3 frases e o detalhe só se ele pedir.
- Usar analogia com o que ele conhece: Roblox ≈ navegador, Luau ≈ JavaScript, Rojo ≈ deploy automático entre o editor e o ambiente, RemoteEvent ≈ mensagem entre front e back.
- Se não souber algo, dizer que não sabe em vez de inventar.
- Se ele errar, explicar o raciocínio do erro, não só a resposta certa.
- Custo importa: ele vai usar o uso do Claude Code (nuvem) dele. Seguir as regras da seção 1 do AGENTES.md.

## 6. Fatos verificados e ressalvas
- O Roblox mede retenção por coorte e recomenda focar primeiro em D1 e tempo médio de sessão (doc oficial).
- Benchmarks por gênero são de blogs de terceiros. Não existe benchmark oficial para bullet heaven; o do Creator Hub (jogos similares) é o que vale.
- O Studio tem MCP embutido (Play, console, screenshot). O repositório `studio-rust-mcp-server` está arquivado; não usar. Detalhes no AGENTES.md, seção 6.
- NÃO VERIFICADO: todas as chamadas de AnalyticsService no código (`LogFunnelStepEvent`, `LogProgressionEvent`, `LogCustomEvent`, `LogEconomyEvent`) foram escritas sem confirmar a assinatura na doc atual. Estão todas em `pcall`, então não quebram nada, mas NÃO confie nos números antes de validar (candidato a tarefa do roblox-researcher).
- DataStore só funciona em jogo PUBLICADO e, no Studio, com "Enable Studio Access to API Services". Em teste local o SaveService cai para memória e avisa — comportamento esperado, não bug.
- Não verificado: os nomes exatos das ferramentas do Studio MCP dentro do Claude Code (ver `/mcp`).
- Rojo: `rokit.toml` fixa 7.5.1, versão NÃO confirmada como a mais recente. O usuário rodou com o `rojo.exe` baixado direto do GitHub Releases.

## 7. Mapa dos arquivos

| Arquivo | Para quê | Quando ler |
|---|---|---|
| README.md | Visão geral do repo e mapa | Primeiro contato com o repo |
| CLAUDE.md | Regras do projeto e roteiro | Sempre (carrega sozinho) |
| CONTEXTO.md | Estado atual e decisões (este) | Início de sessão nova |
| SETUP.md | Como rodar no Studio (fluxo validado) | Ao configurar a máquina ou debugar sync |
| DESIGN.md | Arte, lore, personagens e decisões em aberto | Ao mexer em visual, personagem ou conteúdo |
| RETENCAO.md | Fórmulas, benchmarks e mecânicas de retenção | Ao mexer em progressão, recompensas, level up, meta-progressão ou analytics |
| AGENTES.md | Agentes, economia de tokens, MCP e skills | Ao delegar tarefa ou configurar agentes, MCP ou skills |

## 8. Primeira ação
Se for a primeira sessão: criar os agentes (AGENTES.md, seção "Tarefa para o Claude Code agora") e então começar o passo 1 do roteiro. Antes do passo 1, confirmar que o Rojo e o plugin do Rojo no Studio estão instalados; se não estiverem, listar o passo a passo para o usuário.

## 9. Como testar (primeiro Play do recorte)
Parar no PRIMEIRO erro vermelho do Output e copiar a mensagem inteira (arquivo e linha) para a sessão.
1. Play -> tela de título: céu de entardecer, lua, morcegos voando, logo, 4 personagens e o menu. Output: "[Survivors] Servidor iniciado (tela de titulo, 4 personagens, Planicies)".
2. Aventuras -> "Em breve". Conquistas -> "Nenhuma ainda". Voltar funciona.
3. Opções -> trocar "Minha skin" / "Skin do personagem". Com a do personagem, o boneco perde roupa/acessórios e ganha cor, chapéu e capa.
4. Jogar -> escolher cada personagem -> COMEÇAR -> Planícies (chão verde, pedras, flores, luz de fim de tarde). Conferir a arma de cada um: chicote na frente; runa quicando nas bordas da tela; 3 bolas de fogo num inimigo aleatório; facas para onde olha.
5. Só morcegos chegam; 1:30 revoada; 3:00 Morcego Gigante -> baú. 6:00 cerco de morcegos.
6. Morrer/Desistir -> resultado -> "Voltar ao título" -> ouro somado; PowerUps compráveis.
Atalhos (mudar no Config e DESFAZER depois): Stages.plains.duration, events.at, Config.Progression.First.
