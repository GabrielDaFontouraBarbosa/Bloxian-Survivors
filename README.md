# Bloxian Survivors

Jogo estilo Vampire Survivors ("bullet heaven") no Roblox: o jogador **só se move**, as armas atacam sozinhas, inimigos vêm em ondas, o jogador sobe de nível escolhendo upgrades, e há meta-progressão entre partidas.

**Stack:** Luau + Rojo. O código vive em arquivos neste repositório; o Roblox Studio sincroniza via Rojo. Nunca editar script pelo Studio — a fonte da verdade é o repo.

## Estado

Os **6 passos do roteiro** (ver `CLAUDE.md`) estão implementados: loop completo de jogo + meta-progressão com DataStore. O jogo é jogável de ponta a ponta no Studio.

Em aberto: direção de arte e lore (`DESIGN.md`), verificação das APIs de Analytics, e balanceamento (nunca foi tunado com jogador real). Detalhes em `CONTEXTO.md`.

## Rodar o jogo

Ver **`SETUP.md`** (fluxo validado no Windows: clonar, `rojo serve`, plugin do Rojo, Play).

## Mapa dos documentos

| Arquivo | Para quê | Quando ler |
|---|---|---|
| `CLAUDE.md` | Regras do projeto e roteiro | Sempre (carrega sozinho) |
| `CONTEXTO.md` | Estado atual, decisões e pendências | Início de sessão nova |
| `SETUP.md` | Como rodar no Studio | Ao configurar a máquina |
| `DESIGN.md` | Arte, lore e decisões de design em aberto | Ao mexer em personagem/visual/conteúdo |
| `RETENCAO.md` | Fórmulas e mecânicas de retenção | Virou a skill `retention` (carrega sozinha) |
| `AGENTES.md` | Agentes, economia de tokens, MCP, skills | Ao delegar ou configurar agentes |

## Estrutura do código

```
default.project.json   -- mapa Rojo -> serviços do Roblox
src/
  server/              -- lógica autoritativa (ServerScriptService)
  client/              -- câmera, HUD, input (StarterPlayerScripts)
  shared/              -- Config, Remotes, utilidades (ReplicatedStorage)
```

Todo número de balanceamento mora em `src/shared/Config`.
