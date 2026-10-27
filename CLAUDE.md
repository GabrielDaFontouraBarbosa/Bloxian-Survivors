# Survivors — jogo estilo Vampire Survivors no Roblox

## Ideia central
Jogo de sobrevivência em arena: o jogador só se move, as armas atacam sozinhas, inimigos vêm em ondas, o jogador sobe de nível e escolhe upgrades. Depois entra meta-progressão (parte "incremental").

Loop do jogo: **spawn de inimigos -> dano automático -> XP -> level up -> upgrade**.

## Stack e ferramentas
- Linguagem: **Luau** (arquivos `.luau` ou `.lua`)
- Sincronização com o Studio: **Rojo** (pasta do projeto <-> Roblox Studio)
- Teste: o usuário aperta Play no Roblox Studio. Se o MCP embutido do Studio estiver ligado (ver AGENTES.md, seção 6), o Claude Code também pode dar Play, ler o console e tirar screenshot. Código só por arquivos (Rojo), nunca editando script pelo MCP.
- Gerenciador de ferramentas sugerido: Rokit (instala o Rojo e fixa a versão)

## Estrutura de pastas
```
default.project.json     -- config do Rojo (mapeia pastas -> serviços do Roblox)
src/
  server/                -- ServerScriptService (lógica autoritativa)
  client/                -- StarterPlayerScripts (input, câmera, UI)
  shared/                -- ReplicatedStorage (configs, tipos, utilidades)
```

## Regras de arquitetura
1. **Servidor manda**: vida, dano, spawn, XP e upgrades são decididos no servidor. O cliente só mostra e envia input.
2. **Dados em tabelas de config** (`src/shared/Config`): stats de inimigos, armas e upgrades ficam em tabelas, não espalhados no código. Adicionar conteúdo novo = adicionar uma entrada.
3. **Object pooling**: nunca criar/destruir inimigos e projéteis toda hora. Reaproveitar objetos de um pool.
4. **Inimigos simples**: movimento em linha reta até o jogador. SEM PathfindingService.
5. **Um loop central de update** (Heartbeat) para mover todos os inimigos, em vez de um script por inimigo.
6. **Limite de inimigos vivos** configurável (começar em ~100) para não engasgar.
7. **Módulos pequenos** com uma responsabilidade (ex.: `EnemySpawner`, `WeaponService`, `XPService`).

## Convenções de código
- `--!strict` no topo dos módulos quando possível
- Nomes em inglês no código, comentários curtos em português
- Eventos cliente<->servidor via `RemoteEvent` em `ReplicatedStorage/Remotes`
- Nunca confiar em dados vindos do cliente sem validar

## Roteiro (fazer UM passo por vez, testar antes de seguir)
- [ ] 1. Projeto Rojo funcionando + jogador se movendo + câmera de cima
- [ ] 2. Inimigos: spawn em volta do jogador, perseguem, morrem, soltam XP
- [ ] 3. Arma automática: mira no inimigo mais próximo e ataca sozinha
- [ ] 4. XP + level up com tela de escolha de 3 upgrades
- [ ] 5. Ondas, dificuldade crescente e chefe
- [ ] 6. Meta-progressão: moedas entre partidas, upgrades permanentes, DataStore

## Como trabalhar comigo
- Antes de codar um passo, explique em poucas linhas o plano e quais arquivos vai criar/mudar.
- Faça só o passo pedido; não adiante passos futuros.
- Ao terminar, diga exatamente o que testar no Studio (ex.: "aperte Play, o que deve acontecer é X").
- Se algo depende de configuração manual no Studio (ex.: criar um Part, ligar o plugin do Rojo), liste como passo a passo.
- Se tiver dúvida de API do Roblox, diga que não tem certeza em vez de inventar.
- Em sessão nova, leia primeiro o CONTEXTO.md (estado atual e decisões) e atualize a seção 3 dele ao fim de cada passo.
- Para delegar pesquisa, revisão e playtest e economizar tokens, siga o AGENTES.md.
- Regras de retenção (progressão, recompensas, level up, meta-progressão, analytics): a skill `retention` carrega sozinha quando o assunto aparece.
