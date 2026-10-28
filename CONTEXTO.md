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
- Data da última atualização: 2026-10-27
- Roteiro: passos 1 a 5 concluídos. Próximo: passo 6 (meta-progressão: moedas, upgrades permanentes, DataStore).
- Código do jogo escrito: câmera top-down; WaveService (ondas/dificuldade/chefe/morte), EnemyService (stats por inimigo), WeaponService, XpService (XP+nível+upgrades), PlayerStats, Remotes, PlayerUtil, Analytics; HUD com XP/nível, onda, painel de upgrades e aviso de morte.
- Upgrades (Config.Upgrades): dano, cadência, velocidade, vida, ímã. Curva de ondas em Config.Wave; chefe em Config.Boss (a cada 3 ondas).
- Pendente de verificação: todas as chamadas de AnalyticsService (em pcall). Reinício de partida de verdade só no passo 6.
- Documentação existente: CLAUDE.md, RETENCAO.md, AGENTES.md, CONTEXTO.md.
- Agentes e skills do projeto: criados (4 agentes; skills retention e novo-sistema).
- Repo: GabrielDaFontouraBarbosa/Bloxian-Survivors (branch main).
- MCP do Studio: provavelmente desligado; confirmar com `/mcp`. Rojo: confirmar versão em rokit.toml.
- Bloqueios: nenhum conhecido.

## 4. Ainda não decidido (perguntar ao usuário quando o passo exigir; não presumir)
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
- Conferir na doc atual a assinatura de `AnalyticsService:LogFunnelStepEvent` antes de usar o exemplo do RETENCAO.md.
- Não verificado: os nomes exatos das ferramentas do Studio MCP dentro do Claude Code (ver `/mcp`).

## 7. Mapa dos arquivos

| Arquivo | Para quê | Quando ler |
|---|---|---|
| CLAUDE.md | Regras do projeto e roteiro | Sempre (carrega sozinho) |
| CONTEXTO.md | Estado atual e decisões (este) | Início de sessão nova |
| RETENCAO.md | Fórmulas, benchmarks e mecânicas de retenção | Ao mexer em progressão, recompensas, level up, meta-progressão ou analytics |
| AGENTES.md | Agentes, economia de tokens, MCP e skills | Ao delegar tarefa ou configurar agentes, MCP ou skills |

## 8. Primeira ação
Se for a primeira sessão: criar os agentes (AGENTES.md, seção "Tarefa para o Claude Code agora") e então começar o passo 1 do roteiro. Antes do passo 1, confirmar que o Rojo e o plugin do Rojo no Studio estão instalados; se não estiverem, listar o passo a passo para o usuário.
