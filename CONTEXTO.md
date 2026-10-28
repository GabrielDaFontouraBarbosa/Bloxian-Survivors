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
- Data da última atualização: 2026-10-28
- Roteiro: **todos os 6 passos concluídos**. Loop completo + meta-progressão.
- Código: câmera top-down; WaveService (ondas/dificuldade/chefe/morte), EnemyService (stats por inimigo), WeaponService, XpService (XP+nível+upgrades de run), PlayerStats (base permanente vs. run), SaveService (DataStore), MetaService (moedas + loja de perks), Remotes, PlayerUtil, Analytics; HUD com XP/nível, onda, upgrades, moedas, loja (tecla B) e aviso de morte.
- Cada vida = nova partida: nível/upgrades resetam; moedas e perks permanentes ficam.
- Meta-fase passo 1 FEITO (2026-10-28): CLASSES COMO DADO. Config.Classes + Config.DefaultClassId; perfil guarda classId (SaveService valida/persiste; setClass pronto p/ a cidade); MetaService.buildBase monta a base a partir da classe e loga a classe no startRun. 1 classe ("Cacador") = baseline atual (sem mudar balanceamento). Sem tela de seleção ainda (vem na cidade). Ordem da meta-fase: DESIGN.md seção 6.
- Pendências conhecidas: (1) chamadas de AnalyticsService não verificadas na doc (todas em pcall); (2) DataStore não persiste em teste local não publicado — SaveService cai para memória e avisa; (3) sem recompensa diária / gancho do dia 2 ainda (RETENCAO seção 4, candidatos a próximo trabalho).
- Documentação existente: README.md, CLAUDE.md, CONTEXTO.md, SETUP.md, DESIGN.md, AGENTES.md, RETENCAO.md.
- Agentes e skills do projeto: criados (4 agentes; skills retention e novo-sistema).
- Repo: GabrielDaFontouraBarbosa/Bloxian-Survivors (branch main).
- Jogo RODANDO: o usuário montou Rojo + Studio no Windows em 2026-10-28 e jogou. Passo a passo validado em SETUP.md.
- NUNCA foi feito playtest pelo Claude nem balanceamento com jogador real. O usuário achou "ficando bom"; nenhum ajuste de Config pedido ainda.
- Fase atual: design. TOM/VIBE DECIDIDO (2026-10-28): Vampire Survivors raiz — terror gótico/Castlevania, executado em low-poly 3D limpo (não pixel). Ver DESIGN.md seção 0. Ainda nada implementado desse visual.
- MCP do Studio: desligado. ATENÇÃO: de sessão na NUVEM o MCP do Studio é inalcançável (roda no PC do usuário). Ver AGENTES.md seção 6.
- Bloqueios: nenhum técnico. Em aberto no design: nome do jogo, fonte dos assets e nº de personagens (DESIGN.md seção 4).

## 4. Ainda não decidido (perguntar ao usuário quando o passo exigir; não presumir)
As decisões de ARTE, LORE e PERSONAGENS migraram para o DESIGN.md (seção 4), que é mais detalhado. Resumo do que falta:
- ~~Tom / vibe do jogo~~ — DECIDIDO (DESIGN.md seção 0): VS gótico, low-poly 3D limpo.
- Visão de meta-progressão (classes, armadura=upgrade+skin, pets-familiares, cidade/lobby) — DECIDIDA em direção (DESIGN.md seção 6). Loot/gear RECUSADO. Nada implementado ainda.
- **Nome do jogo.** "Bloxian Survivors" é placeholder do repo, não decisão.
- **Personagens desbloqueáveis vs. um boneco que upa** — rumo definido no DESIGN.md seção 1 (os dois, em ordem), mas não implementado.
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
