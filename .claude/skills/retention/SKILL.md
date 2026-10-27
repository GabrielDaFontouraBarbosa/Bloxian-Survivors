---
name: retention
description: Fórmulas, benchmarks e regras de retenção do Survivors. Use ao mexer em progressão, recompensas, level up, meta-progressão, onboarding ou analytics.
---

# Retenção de jogadores no Survivors (Roblox)

Referência para o Claude Code. Leia ao mexer em: progressão, recompensas, level up, meta-progressão, onboarding, analytics ou qualquer sistema que afete "o jogador volta ou não".

## Ideia central
Retenção = quantos jogadores voltam depois da primeira partida. No Roblox ela é medida por **coorte**: pega quem jogou pela primeira vez no dia X e vê quem voltou. Os números que mandam são **D1** (o onboarding funcionou?), **D7** (virou hábito?) e **D30** (tem objetivo de longo prazo?). O Roblox recomenda focar primeiro em D1 + tempo médio de sessão, depois D7/D30, e só então investir em atrair mais gente.

## Regras para o Claude Code (ao implementar qualquer sistema)
1. Antes de codar, diga **qual métrica o sistema move** (D1, D7, D30 ou tempo de sessão).
2. Todo valor de recompensa/dificuldade vai em `src/shared/Config`, nunca hardcoded. Retenção se ajusta por tuning.
3. Todo sistema novo vem com **eventos de analytics** (seção 5).
4. Não implementar mecânica que pune o jogador por ficar ausente (ver seção 6).
5. Se não souber uma API do Roblox, diga que não sabe e aponte a doc em vez de inventar.

---

## 1. Fórmulas

| Métrica | Fórmula | Observação |
|---|---|---|
| **Retenção Dia N** | `usuários da coorte que voltaram no dia N / usuários da coorte no dia 0` | Versão "clássica" (volta exatamente no dia N). É a que o Creator Hub mostra. |
| Retenção rolling | `usuários que voltaram no dia N **ou depois** / coorte` | Equivale a `100% - churn`. Mais otimista que a clássica. |
| **Churn** | `100% - retenção rolling` | Só vale como número agregado se for segmentado. |
| **Tempo médio de sessão** | `tempo total jogado / número de sessões` (por dia) | Definição do Roblox. |
| **DAU** | jogadores únicos que entraram no dia | |
| **Stickiness** | `DAU / MAU` | `0,5` = o jogador médio joga ~15 dos 30 dias. Use MAU de 28 dias móveis para o denominador ficar estável. |
| **D7/D1** | `D7 / D1` | Dos que voltaram no dia 1, quantos ainda voltam na semana. |
| **D30/D7** | `D30 / D7` | Dos que viraram "semanais", quantos viraram hábito. |
| **Queda no funil** | `usuários no passo n / usuários no passo n-1` | Achar o passo onde mais gente some. |
| **ARPDAU** | `receita do dia / DAU` | Só quando for monetizar. |
| **LTV** | `ARPU x tempo de vida` ou `soma(retenção_d x ARPDAU_d)` | Só quando for monetizar. |

**Exemplo:** 100 jogadores novos, 25 voltam no dia 1, 10 no dia 7, 4 no dia 30 -> D1=25%, D7=10%, D30=4%, D7/D1=0,40, D30/D7=0,40.

**Extrapolar a curva (estimativa):** curvas de retenção costumam seguir uma potência `ret(d) ≈ a * d^b`. Com `a = D1` e `b = ln(D30/D1) / ln(30)` dá pra prever dias intermediários e conferir com o D7 real. No exemplo acima, `b ≈ -0,54` e o D7 previsto é ~8,8% (real: 10%). Se o real destoar muito, a curva tem um "degrau" (algo especial acontece em certo dia).

---

## 2. Benchmarks (use com cuidado)

- **O melhor benchmark é o do próprio Creator Hub**: ele compara seu jogo com jogos similares (faixa do percentil 50 ao 90) para D1, D7, D30 e tempo de sessão. O Roblox avisa que esses benchmarks **não** entram direto no algoritmo de descoberta; servem de referência para você. O painel completo só libera com um mínimo de jogadores (um post antigo do DevForum cita 50 DAU e 50 horas jogadas em 7 dias; confira o valor atual).
- Não existe benchmark publicado para "bullet heaven" no Roblox. Os números abaixo são de **terceiros, não oficiais**, de gêneros próximos:

| Gênero (fonte: RoWatcher) | D1 | D7 | D30 |
|---|---|---|---|
| Obby | 25–35% | 10–15% | <5% (normal) |
| Tycoon | 20–28% | 12–18% | — |
| Shooter / PvP | 22–30% | 12–16% | — |
| Roleplay / social | 15–22% | — | 8–15% |

- Um guia geral (creation.dev) diz que jogos Roblox bem-sucedidos ficam em D1 de 20–30% e que D1 abaixo de 15% indica problema no primeiro contato.
- Mobile F2P "ótimo" (Medium/GameAnalytics): D1 40%, D7 15%, D28 6,5%. Referência de outra plataforma, não de Roblox.
- Stickiness: jogos acima de ~20% de DAU/MAU são considerados acima da média; casual games ficam tipicamente entre 15% e 35%.
- Razões saudáveis (heurística de um autor, **não oficial**): D7/D1 > 0,5 e D30/D7 > 0,4.
- Pico de tráfego novo (ex.: promoção) derruba D1/D7/D30 temporariamente. Isso é normal; não conclua que o jogo piorou.

---

## 3. Diagnóstico: o número diz o quê, e o que fazer

| Sintoma | Leitura provável | Ação |
|---|---|---|
| **D1 baixo** | Onboarding ruim: jogador confuso, frustrado ou demorando pra chegar na parte divertida | Medir o funil do primeiro minuto, cortar passos, deixar a 1ª recompensa vir rápido |
| **D1 ok, D7 baixo** | Falta hábito/progressão depois da novidade. D7 é em grande parte definido nas primeiras 48h | Criar um gancho pro dia 2 (seção 4) e metas de curto prazo |
| **D7 ok, D30 baixo** | Falta conteúdo/objetivo de fim de jogo (diagnóstico oficial do Roblox) | Metas de longo prazo, desbloqueios raros, eventos e updates |
| **Tempo de sessão baixo** | Tempo morto, pico de dificuldade, ação repetitiva, próximo passo pouco claro | Encurtar o trajeto entre recompensa e próximo desafio |
| **DAU/MAU caindo** | Jogadores novos não criam hábito diário | Melhorar onboarding, eventos, ganchos de engajamento |
| D1 sobe mas D7 despenca depois de aumentar recompensas | Recompensa adiantada demais "gasta" a expectativa das sessões futuras | Voltar o ritmo e misturar recompensas rápidas pequenas com lentas grandes |

---

## 4. Mecânicas de retenção aplicadas ao Survivors

Jogos fortes rodam laços em **três escalas de tempo ao mesmo tempo**. Mapeamento pro nosso jogo:

**Segundos (sensação de jogo)** -> move D1 e tempo de sessão
- Feedback em todo acerto: número de dano, som, inimigo piscando ao morrer.
- Gemas de XP que voam até o jogador (coletar é recompensa por si só).
- O loop "mover, matar, subir de nível, escolher poder" tem que ser divertido já nos primeiros minutos.

**Minutos (dentro da partida)** -> move tempo de sessão e D1
- Primeiro level up bem cedo (valor inicial a tunar em Config, ex.: dentro dos primeiros ~30s; é hipótese, teste).
- Escolha de 3 upgrades a cada level up (o "cassino" do jogo: aleatoriedade dentro de regras justas).
- Ondas com escalada clara e chefe como marco.

**Sessões (entre partidas)** -> move D7 e D30
- **Moeda permanente paga mesmo morrendo.** Partida curta ou interrompida nunca parece perdida; é o que sustenta o "só mais uma".
- **Meta-progressão que acelera habilidade** (mais opções, ferramentas melhores), em vez de travar conteúdo só pra esticar tempo de jogo.
- Desbloqueio de personagens/armas como metas visíveis de médio prazo.
- **Gancho pro dia 2 (hipótese de design):** ao fim da 1ª partida, o jogador deve ver algo desbloqueável "quase alcançado" (ex.: falta pouco pra próxima melhoria permanente). Deixar algo em aberto dá motivo pra voltar.
- Recompensa diária **sem punição** por faltar (seção 6).
- Eventos sazonais e updates regulares de conteúdo; guias de terceiros apontam esses como os maiores picos de retenção.
- Social: o Roblox recomenda eventos de experiência e **convite de amigos** (invite prompts). Co-op é candidato forte pra fase 6.

**Ritmo de recompensas:** não adiantar tudo pra "consertar o D1". Misturar recompensas rápidas e pequenas com lentas e grandes.

---

## 5. Instrumentação (analytics)

Sem medir, não dá pra saber qual passo derruba o jogador. O Roblox tem **Funnel Events** (onde o jogador abandona onboarding/progressão/loja) e **Economy Events** (de onde vem e pra onde vai a moeda). Doc: https://create.roblox.com/docs/production/analytics/funnel-events

**Funil de uma partida** (exemplo, módulo `src/server/Analytics.luau`). A assinatura abaixo vem da doc do Roblox; **confira na doc atual antes de usar**, inclusive o tipo do `funnelSessionId`:

```lua
--!strict
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")

local Analytics = {}

function Analytics.newRunId(): string
	return HttpService:GenerateGUID(false)
end

-- passos sugeridos: 1 RunStarted, 2 FirstKill, 3 Level2, 4 Level5, 5 BossSeen, 6 RunEnded
function Analytics.runStep(player: Player, runId: string, step: number, name: string)
	AnalyticsService:LogFunnelStepEvent(player, "RunProgress", runId, step, name)
end

return Analytics
```

Observações da doc: se o jogador repete um passo, só a primeira ocorrência conta; só os 10 `funnelSessionId` mais recentes por jogador são rastreados. Para o **funil de onboarding (uma vez por jogador)** a doc tem uma seção "Track one-time funnels"; siga ela.

**Eventos a instrumentar por fase do roteiro:**
- Passo 2 (inimigos): primeira morte de inimigo.
- Passo 4 (level up): cada nível alcançado e a opção escolhida.
- Passo 5 (ondas): onda/minuto em que o jogador morre (mostra onde a dificuldade quebra).
- Passo 6 (meta): ganho e gasto de moeda (economy events), o que foi comprado primeiro.

**Planilha semanal** (fixe uma janela de coorte, ex.: novos jogadores dos últimos 30 dias):

| Semana | D1 | D7 | D30 | D7/D1 | D30/D7 | Sessão média | DAU | MAU 28d | DAU/MAU | O que mudei no jogo |
|---|---|---|---|---|---|---|---|---|---|---|

Regra: **uma mudança grande por release**, anotada na última coluna. Sem isso não dá pra saber o que moveu o número. D7 e D30 só aparecem depois que passam 7 e 30 dias, então tenha paciência antes de concluir.

**Plano de 30 dias (resumo):** semana 1 mapear o funil da primeira sessão e observar ~5 pessoas jogando sem ajuda; semana 2 corrigir a maior falha e medir de novo; semana 3 olhar D1 e sessão por origem/plataforma; semana 4 testar uma mudança controlada e documentar.

---

## 6. Cuidados

- **Recompensa diária sem punição.** Guias de terceiros sugerem streak que "pune" quem falta. Recomendação deste projeto: não zerar progresso por ausência. Em jogo com público jovem, pressão por FOMO é dark pattern e piora a relação com o jogo. Dar bônus por voltar, não castigo por sumir.
- **Itens aleatórios pagos com Robux têm regra oficial.** Se um dia vender baú/roleta/ovo (direto ou via moeda comprada com Robux): é obrigatório mostrar as **chances numéricas**, respeitar a restrição por região/idade via `PolicyService` (`ArePaidRandomItemsRestricted`) e não permitir troca do resultado. Os upgrades de level up ganhos jogando, sem Robux, não entram nisso. Doc: https://create.roblox.com/docs/production/monetization/paid-random-items
- **Não comprar tráfego antes de ajustar retenção.** Aquisição amplifica o primeiro contato, inclusive os defeitos dele.
- **Amostra pequena engana.** Com poucos jogadores, observe pessoas jogando em vez de confiar só em percentual.

---

## 7. Onde isso encaixa no roteiro do CLAUDE.md

| Passo | Entrega de retenção |
|---|---|
| 1–2 | Primeiros segundos divertidos; evento de 1ª morte de inimigo |
| 3 | Feedback de dano/acerto |
| 4 | Level up cedo; log do nível e da escolha |
| 5 | Log de onda/minuto da morte; curva de dificuldade em Config |
| 6 | Moeda permanente, gancho do dia 2, recompensa diária sem punição, economy events |

---

## Fontes
Oficiais (Roblox):
- Retenção: https://create.roblox.com/docs/en-us/production/analytics/retention
- Analytics (ordem de foco, benchmarks): https://create.roblox.com/docs/production/analytics
- Engajamento / sessão: https://create.roblox.com/docs/production/analytics/engagement
- Analytics essentials (D1/D7/D30): https://create.roblox.com/docs/production/game-design/analytics-essentials
- Funnel events: https://create.roblox.com/docs/production/analytics/funnel-events
- DAU/MAU e coortes: https://devforum.roblox.com/t/analytics-track-new-user-retention-by-daily-and-weekly-cohort/3817030
- Itens aleatórios pagos: https://create.roblox.com/docs/production/monetization/paid-random-items

Terceiros (não oficiais, tratar como referência):
- Benchmarks por gênero, razões D7/D1 e D30/D7, ritmo de recompensa, "D2 antes de D7": https://rowatcher.com/news/retention-benchmarks-by-roblox-genre-what-good-actually-looks-like , https://rowatcher.com/news/return-rate-is-measurable-on-roblox-you-re-just-not-looking-right , https://rowatcher.com/news/reward-pacing-in-roblox-why-generosity-kills-retention , https://rowatcher.com/news/d7-retention-is-a-lagging-indicator-design-for-d2-instead
- Tipos de retenção (clássica/rolling/full), LTV: https://www.slideshare.net/slideshow/cheat-sheetgamepublisher1/56018711
- Stickiness: https://mwm.ai/glossary/stickiness
- KPIs F2P mobile: https://medium.com/@splintervoit/a-primer-on-kpis-for-f2p-mobile-games-40e1399e6dda
- Análise do design de Vampire Survivors: https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors
- Roblox analytics (plano 30 dias): https://www.obby.fun/blog/roblox-analytics-guide
- Daily rewards no Roblox: https://www.creation.dev/blog/roblox-player-retention
