# PORTE-VS.md — porte das mecânicas do Vampire Survivors

Plano do porte pedido em 2026-10-28: estudar o Vampire Survivors (VS) e trazer a **maioria das features** para o nosso jogo, **sem copiar literalmente** — mecânica igual, nomes, números e visual próprios (tom gótico, DESIGN.md seção 0).

Fonte: wiki e guias públicos do VS (os arquivos do jogo estão no PC do usuário, fora do alcance da sessão na nuvem).

---

## 1. Mapa VS -> Bloxian

| Feature do VS | Como fica aqui | Onde mora |
|---|---|---|
| Run de 30 min, Ceifador aos 30:00 | Run de 30 min; aos 30:00 a **Ceifadora** limpa a tela e caça o jogador. Chegar lá = estágio completo | `StageService` |
| Armas automáticas, até 6, nível 1-8 | 9 armas com **comportamentos** diferentes (chicote, cetro teleguiado, adagas, machado em arco, crucifixo bumerangue, grimório orbital, alho/aura, água benta/poças, sino do trovão) | `Config/Weapons`, `server/Weapons/*` |
| Passivas, até 6, nível 1-5 | 16 passivas que mexem nos stats (Poder, Área, Recarga, Quantidade...) | `Config/Passives` |
| Level up com 3 (ou 4) escolhas | Igual: 3 opções, 4ª pela Sorte; **Rerrolar** e **Pular** como cargas | `XpService`, `Loadout` |
| Evolução (arma máx + passiva par + baú) | Igual. Cada arma tem uma evolução com nome próprio | `ChestService` |
| Baús de chefe (1/3/5 itens) | Igual, com chance pela Sorte + ouro | `ChestService` |
| Stats (Might, Area, Cooldown, Amount, Luck, Greed, Curse, Revival...) | Mesmos 16 conceitos, nomes em português | `Config/Stats`, `Stats` |
| Inimigos por minuto, eventos | Estágio = segmentos por minuto + eventos: **revoada** de morcegos (o "inimigo rápido na direção"), **muro de flores**, chefes | `Config/Stages` |
| Light sources (candelabros) | **Tochas** que quebram e soltam itens | `PickupService` |
| Itens de chão (moeda, frango, rosário, vácuo, relógio) | Moeda/saco, coxa assada (cura), rosário (limpa tela), vácuo (puxa XP), relógio (congela) | `Config/Pickups` |
| Ouro + PowerUps na tela inicial | Ouro guardado no fim da run (mesmo morrendo). **PowerUps só no lobby** — nada de loja dentro da partida | `MetaService` |
| Personagens desbloqueáveis | **Classes** (nossa palavra): arma inicial + bônus. Desbloqueia por conquista, compra com ouro | `Config/Classes` |
| Conquistas que desbloqueiam conteúdo | Conquistas liberam classes, armas, passivas, arcanos, estágios e aventuras | `Config/Achievements` |
| Arcanas (cartas modificadoras) | **Arcanos**: escolhe 1 antes da run | `Config/Arcanas` |
| Adventures | **Aventuras**: capítulos com regras próprias (mais rápido, mais vida, tempo menor) e recompensas | `Config/Adventures` |
| (não tem no VS) Missões | **Missões**: 3 objetivos ativos com recompensa em ouro, **sem prazo e sem punição** (regra de retenção do projeto) | `Config/Quests` |

## 2. Decisões de arquitetura

1. **Uma run por jogador.** Cada jogador joga a sua run solo, com timer próprio. O lobby (o chão do Baseplate) é o espaço social — base para a cidade depois.
2. **Arenas empilhadas em altura.** Cada run ganha um "andar" (Y = 1000, 2000...). O chão segue o jogador (mapa infinito, como no VS). Runs nunca se encostam.
3. **Tudo que pertence à run fica na run:** inimigos, projéteis, gemas e itens têm dono. Inimigo só persegue o dono.
4. **Vida própria no servidor** (armadura, ressurreição, recuperação), espelhada no Humanoid.
5. **Pausa por run.** Level up e baú pausam só a run daquele jogador (como no VS).
6. **Barramento de eventos** (`Events`): serviços avisam ("inimigo morreu", "evoluiu", "minuto X") e conquistas/missões/itens escutam. Evita require circular.
7. **Conteúdo é dado.** Arma, passiva, inimigo, estágio, classe, conquista, arcano, missão e aventura = uma entrada no `Config`. Comportamento novo de arma = um módulo em `server/Weapons`.
8. **Inimigo sem animação.** Formas primitivas soldadas num `Root` ancorado; cabeças flutuam com seno; corpo vira na direção do jogador. Zero rig, zero frame de animação.
9. **Grade espacial** dos inimigos por run, para acerto de área sem varrer todo mundo.
10. **Cenário no cliente.** Árvores/túmulos e luz de lua são só visuais, gerados no cliente em volta do jogador.
11. **Perfil v2** com migração do v1 (moedas viram ouro, perks viram PowerUps).

## 3. Fases (cada uma = commit)

1. Config de conteúdo modular + índice `Content`
2. Núcleo do servidor: perfil v2, runs, arena, vida, stats, loadout, XP/level up, baús
3. Armas (9 comportamentos + 9 evoluções)
4. Inimigos + estágio + eventos + chefes + Ceifadora + tochas e itens
5. Meta: PowerUps, classes, conquistas, missões, arcanos, aventuras
6. Cliente: lobby, HUD, level up, baú, resultado, avisos, cenário
7. Revisão (`luau-reviewer`) + correções + docs

## 4. Riscos conhecidos

- **Nada disso foi testado com Play** (sessão na nuvem não alcança o Studio). O primeiro playtest vai achar erro de runtime: é esperado. Ver "Como testar" no CONTEXTO.md.
- Balanceamento é chute educado (números do VS como referência de proporção). Tunar no `Config` depois de jogar.
- DataStore continua só em jogo publicado (SaveService cai pra memória no Studio).
