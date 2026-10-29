# Bloxian Survivors

Jogo estilo Vampire Survivors ("bullet heaven") no Roblox: o jogador **só se move**, as armas atacam sozinhas, inimigos vêm em ondas, o jogador sobe de nível escolhendo upgrades, e há meta-progressão entre partidas.

**Stack:** Luau + Rojo. O código vive em arquivos neste repositório; o Roblox Studio sincroniza via Rojo. Nunca editar script pelo Studio — a fonte da verdade é o repo.

## Estado

Os **6 passos do roteiro** (ver `CLAUDE.md`) foram implementados e jogados. Em seguida veio o **porte das mecânicas do Vampire Survivors** (`PORTE-VS.md`): lobby, 9 classes, 9 armas com evolução, 16 passivas, baús, bestiário gótico sem animação, 2 estágios com eventos e a Ceifadora, PowerUps, conquistas que desbloqueiam conteúdo, missões, arcanos e aventuras.

**O porte ainda não foi testado com Play** — o roteiro de teste está no fim do `CONTEXTO.md`. Em aberto: playtest, balanceamento, nome do jogo, skins/pets/cidade 3D (`DESIGN.md`).

## Rodar o jogo

Ver **`SETUP.md`** (fluxo validado no Windows: clonar, `rojo serve`, plugin do Rojo, Play).

## Mapa dos documentos

| Arquivo | Para quê | Quando ler |
|---|---|---|
| `CLAUDE.md` | Regras do projeto e roteiro | Sempre (carrega sozinho) |
| `CONTEXTO.md` | Estado atual, decisões e pendências | Início de sessão nova |
| `SETUP.md` | Como rodar no Studio | Ao configurar a máquina |
| `DESIGN.md` | Arte, lore e decisões de design em aberto | Ao mexer em personagem/visual/conteúdo |
| `PORTE-VS.md` | Mapa VS -> nosso jogo e decisões de arquitetura do porte | Ao mexer em armas, inimigos, estágio, meta |
| `RETENCAO.md` | Fórmulas e mecânicas de retenção | Virou a skill `retention` (carrega sozinha) |
| `AGENTES.md` | Agentes, economia de tokens, MCP, skills | Ao delegar ou configurar agentes |

## Estrutura do código

```
default.project.json   -- mapa Rojo -> serviços do Roblox
src/
  server/              -- lógica autoritativa (ServerScriptService)
    RunManager         -- ciclo da run (início, loop central, fim, volta ao lobby)
    Stage/Enemy/Weapon/Xp/Pickup/ChestService, Loadout, Stats, PlayerHealth, Arena
    Weapons/           -- um módulo por comportamento de arma
    Meta/Achievement/Quest/AdventureService, SaveService (perfil v2)
    Events             -- barramento de eventos entre serviços
  client/              -- Main + Ui/ (lobby, HUD, level up, baú, resultado, avisos), cenário, câmera
  shared/
    Config/            -- catálogos: armas, passivas, classes, inimigos, estágios, conquistas...
    Content/           -- índice por id + fórmulas compartilhadas
    Remotes/           -- RemoteEvents
```

Todo número de balanceamento e todo conteúdo mora em `src/shared/Config`: adicionar arma, inimigo, classe ou conquista = adicionar uma entrada no catálogo.
