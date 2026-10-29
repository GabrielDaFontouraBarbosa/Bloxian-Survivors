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
- Data da última atualização: 2026-10-29
- Roteiro original (6 passos) concluído. Depois veio o **PORTE DAS MECÂNICAS DO VAMPIRE SURVIVORS** (pedido do usuário, plano em PORTE-VS.md): código ESCRITO e revisado por leitura, **NUNCA RODADO** (sessão na nuvem não dá Play). O primeiro Play vai achar erros de runtime — é esperado; corrigir um por vez.
- O que o porte tem: runs por jogador em arenas empilhadas (chão infinito); lobby com abas (Jogar/PowerUps/Conquistas/Missões/Aventuras) — PowerUps SÓ no lobby; 9 classes; 9 armas com comportamentos + 9 evoluções (arma máx + passiva + baú); 16 passivas; 16 stats estilo VS; level up 3-4 opções + rerrolar/pular; baús 1/3/5; bestiário sem animação (cabeças flutuantes, morcegos, louva-a-deus...); estágios Floresta Maldita e Cemitério Esquecido com ondas por minuto, revoada, muro de flores, chefes, tochas e Ceifadora aos 30:00; itens de chão; 34 conquistas que liberam conteúdo; missões sem prazo; 7 arcanos; 2 aventuras.
- Arquitetura nova: Config virou pasta de catálogos (+ índice Content); serviços conversam pelo barramento `Events`; cada serviço guarda estado em `run.data`. PlayerStats→Stats, WaveService→StageService, Hud.client→Main.client + Ui/*.
- Pendências conhecidas: (1) PLAYTEST do porte (ver "Como testar" no fim deste arquivo); (2) balanceamento é chute (proporções do VS); (3) AnalyticsService não verificado na doc (tudo em pcall); (4) DataStore só persiste em jogo publicado; (5) skins de "armadura", pets-familiares e cidade 3D ainda não feitos (DESIGN.md seção 6).
- Documentação existente: README.md, CLAUDE.md, CONTEXTO.md, SETUP.md, DESIGN.md, AGENTES.md, RETENCAO.md.
- Agentes e skills do projeto: criados (4 agentes; skills retention e novo-sistema).
- Repo: GabrielDaFontouraBarbosa/Bloxian-Survivors (branch main).
- Jogo RODANDO: o usuário montou Rojo + Studio no Windows em 2026-10-28 e jogou. Passo a passo validado em SETUP.md.
- NUNCA foi feito playtest pelo Claude nem balanceamento com jogador real. O usuário achou "ficando bom"; nenhum ajuste de Config pedido ainda.
- Fase atual: playtest do porte VS. TOM/VIBE: Vampire Survivors raiz, gótico, low-poly 3D limpo (DESIGN.md seção 0) — o porte já usa formas góticas simples e luz de lua.
- MCP do Studio: desligado. ATENÇÃO: de sessão na NUVEM o MCP do Studio é inalcançável (roda no PC do usuário). Ver AGENTES.md seção 6. Os arquivos do VS que o usuário tem ficam no PC dele — a nuvem não alcança (Windows); o porte usou fontes públicas.
- Bloqueios: nenhum técnico conhecido antes do primeiro Play. Em aberto no design: nome do jogo e fonte dos assets (DESIGN.md seção 4).

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

## 9. Como testar o porte VS (primeiro Play)
Ordem sugerida, parando no PRIMEIRO erro vermelho do Output (copiar a mensagem inteira, com arquivo e linha, para a sessão):
1. Play -> deve aparecer o lobby (abas Jogar/PowerUps/Conquistas/Missões/Aventuras) e "[Survivors] Servidor iniciado (porte VS...)" no Output.
2. Aba Jogar -> Caçador + Floresta Maldita -> JOGAR -> sobe para a arena: chão verde escuro, árvores, luz de lua, HUD (XP no topo, tempo, vida embaixo).
3. Morcegos e crânios chegam; o chicote golpeia na frente; gemas azuis caem e são puxadas.
4. Level up -> run pausa, 3 cartas, teclas 1-3 funcionam; pegar Cetro/Adagas e ver os slots no HUD.
5. 1:30 -> revoada de morcegos vermelhos em linha reta. 3:00 -> Morcego Gigante; matar -> baú -> painel do baú.
6. Tochas aparecem; quebrar -> moeda/coxa/rosário etc.
7. Morrer ou Desistir (2 cliques) -> tela de resultado -> "Voltar ao lobby" -> ouro somado; conquistas (Primeiro Sangue...) liberadas; comprar um PowerUp.
Atalhos para testar rápido (mudar no Config e DESFAZER depois): Stages.forest.duration (Ceifadora antes), events.at (chefe antes), Config.Progression.First (level up mais rápido).
