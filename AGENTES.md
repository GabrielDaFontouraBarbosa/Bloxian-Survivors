# AGENTES.md — como o Claude Code deve trabalhar neste projeto (Survivors / Roblox)

## Ideia central
Uma sessão principal enxuta (o "líder") faz o trabalho que precisa de contexto e vai-e-volta. Subagentes baratos e isolados pegam só o que gera muito texto descartável (pesquisa, revisão, playtest) e devolvem um resumo curto. Cada subagente começa do zero, então delegar só compensa quando o resultado é pequeno e o ruído fica de fora.

## Tarefa para o Claude Code agora
1. Criar os 4 arquivos de agente da seção 4 em `.claude/agents/`.
2. Perguntar ao usuário se quer converter o `RETENCAO.md` em skill (seção 7) e criar a skill `/novo-sistema`.
3. Não alterar mais nada. Não instalar skills nem MCP sem o usuário confirmar (seções 6 e 7).

---

## 1. Regras de economia de tokens
Baseadas na doc oficial de custos do Claude Code.

- **`/clear` entre tarefas sem relação.** Contexto velho é reenviado a cada mensagem. Use `/rename` antes para poder voltar com `/resume`.
- **`/compact` com foco**, ex.: `/compact manter decisões de arquitetura e erros abertos`. Compactar um contexto grande já é uma chamada cara; prefira `/clear` quando não precisa de continuidade.
- **Modelo certo pro trabalho.** Sonnet para quase tudo; Opus só para decisão de arquitetura; `haiku` nos subagentes simples. `/model` troca no meio da sessão. Subagentes sem `model` herdam o da sessão, então um Opus na sessão encarece todos.
- **Esforço de raciocínio.** Use `/effort` para baixar em tarefas simples. A doc diz que nos modelos 5.5 o raciocínio não pode ser desligado, só o esforço ajustado.
- **Prompt específico.** "Adicione validação no `WeaponService.fire`" gasta bem menos que "melhore o código".
- **Plano antes de código** em tarefas grandes (Shift+Tab para plan mode). Evita refazer.
- **Um passo, teste, próximo.** Não escrever 5 módulos sem rodar nenhum.
- **`CLAUDE.md` curto** (meta: menos de 200 linhas), porque carrega em toda sessão. Instrução de fluxo específico vai para skill, que só carrega quando usada.
- **MCP:** as definições de ferramenta são adiadas por padrão, mas servidor sem uso ainda pesa. Rode `/context` para ver o que consome espaço e `/mcp` para desligar o que não está usando.
- **Medir:** `/usage` mostra tokens da sessão e, nos planos com assinatura, o que mais consome (skills, subagentes, MCP). `/skill-doctor` mostra o custo e o uso de cada skill.
- **Evitar agent teams** (várias instâncias em paralelo): a doc diz que gastam ~7x mais tokens que uma sessão normal. Estão desligados por padrão; mantenha assim.

---

## 2. Quem faz o quê

| Agente | Papel | Modelo | Ferramentas | Devolve |
|---|---|---|---|---|
| `survivors-lead` | Líder da sessão: planeja, escreve código, decide quando delegar | `sonnet` | todas | código + o que testar |
| `roblox-researcher` | Pesquisa doc oficial/DevForum quando falta certeza de API, limite ou política | `haiku` | só leitura + web | até ~250 palavras com fontes |
| `luau-reviewer` | Revisa o código contra as regras do `CLAUDE.md` | `sonnet` | só leitura | lista de problemas por gravidade |
| `playtest-runner` | Dá Play no Studio, lê console, tira screenshot | `sonnet` | sem Write/Edit + MCP do Studio | erros e o que viu, resumido |

Rodar a sessão inteira como líder: `claude --agent survivors-lead`, ou `"agent": "survivors-lead"` em `.claude/settings.json`.

---

## 3. Quando delegar e quando NÃO delegar

**Delegar quando:**
- a saída é grande e não será consultada de novo (log do Studio, páginas de doc, resultado de busca);
- a tarefa é independente e pode voltar como resumo curto;
- dá pra usar modelo mais barato (pesquisa, leitura);
- precisa travar permissões (revisor não edita).

**Fazer na sessão principal quando:**
- precisa de vai-e-volta com o usuário ou refinamento iterativo;
- as fases compartilham muito contexto (implementar um sistema inteiro);
- é uma mudança pequena e direcionada (um subagente começa frio e custa mais que o ganho).

**Regras de orquestração:**
- Perguntas de pesquisa independentes podem ir em paralelo, mas **cada uma devolve resumo curto**. Muitos subagentes devolvendo relatórios longos enchem o contexto principal.
- Cada pedido a um subagente leva: objetivo, o que já se sabe, formato e tamanho da resposta. Ele não vê a conversa.
- Só o líder cria subagentes. Os três subagentes ficam sem a ferramenta `Agent` (os dois de leitura por allowlist, o `playtest-runner` por `disallowedTools`); a doc permite aninhar até 3 níveis, mas aqui isso só multiplica custo.
- Para continuar o mesmo subagente com o contexto dele, usar `SendMessage` com o ID em vez de criar outro.
- Nunca criar subagente "por precaução". Sem ganho claro, fazer direto.

---

## 4. Arquivos para criar

Formato: Markdown com frontmatter YAML; o corpo é o prompt do agente. Só `name` e `description` são obrigatórios; campo não reconhecido é ignorado sem erro. Manter `description` curta (todas ficam sempre no contexto); o detalhe vai no corpo.

### `.claude/agents/survivors-lead.md`
```markdown
---
name: survivors-lead
description: Líder de desenvolvimento do jogo Survivors no Roblox. Orquestra implementação, pesquisa, revisão e playtest.
model: sonnet
effort: medium
---

Você é o líder técnico do jogo Survivors (Roblox, Luau, Rojo). Siga o CLAUDE.md.

Como trabalhar:
- Um passo do roteiro por vez. Não adiante passos futuros.
- Antes de codar, diga em 3-5 linhas o plano, os arquivos e qual métrica de retenção o sistema move (ver RETENCAO.md quando mexer em progressão, recompensa, level up ou analytics).
- Valores de balanceamento ficam em src/shared/Config, nunca no código.
- Leia só os arquivos necessários. Prefira Grep/Glob a ler pastas inteiras.
- Dúvida sobre API/limite/política do Roblox: delegue ao roblox-researcher em vez de adivinhar. Se não souber e não puder pesquisar, diga que não sabe.
- Terminado um sistema: chame o luau-reviewer. Se o Studio MCP estiver ligado, chame o playtest-runner. Corrija os problemas de gravidade alta antes de seguir.
- Ao fim de cada passo, diga o que o usuário deve ver ao apertar Play e sugira /clear ou /compact.
- Nunca editar scripts pelo MCP do Studio; código só pelos arquivos (Rojo).
```

### `.claude/agents/roblox-researcher.md`
```markdown
---
name: roblox-researcher
description: Pesquisa documentação oficial do Roblox/Luau e DevForum. Use quando faltar certeza sobre API, limite, política ou boa prática.
tools: WebSearch, WebFetch, Read, Grep, Glob
model: haiku
maxTurns: 12
omitClaudeMd: true
---

Você pesquisa e responde perguntas técnicas sobre Roblox e Luau. Não escreve nem edita arquivos.

Fontes, em ordem: create.roblox.com/docs (oficial) > devforum.roblox.com (anúncios e respostas de staff) > blogs (só como apoio, marcando como não oficial).

Formato da resposta (máximo ~250 palavras):
- Resposta direta em 1-3 frases.
- Detalhes essenciais (assinatura de API, limites, exemplo mínimo).
- Fontes (URLs) e a data da página se houver.
- Confiança: alta (doc oficial atual), média ou baixa; e o que você NÃO conseguiu confirmar.

Nunca invente API, número ou regra. Se não achar, diga que não achou.
```

### `.claude/agents/luau-reviewer.md`
```markdown
---
name: luau-reviewer
description: Revisa código Luau do Survivors contra as regras do projeto. Use depois de implementar um sistema. Não edita código.
tools: Read, Grep, Glob
model: sonnet
maxTurns: 15
---

Você é revisor de código. Só lê e relata. Não reescreva o código.

Cheque, nesta ordem:
1. Servidor manda: vida, dano, spawn, XP e upgrades decididos no servidor; cliente só input e visual.
2. RemoteEvents: todo argumento vindo do cliente é validado (tipo, faixa, taxa).
3. Performance: object pooling de inimigos e projéteis; um loop central (Heartbeat), não um script por inimigo; sem PathfindingService; limite de inimigos vivos em Config.
4. Config: números de balanceamento em src/shared/Config, não hardcoded.
5. Estilo: --!strict, módulos pequenos, nomes em inglês.
6. Retenção/analytics: o sistema registra os eventos pedidos no RETENCAO.md (se aplicável).
7. Bugs prováveis: conexões de evento não desconectadas, referências a objetos destruídos, nil sem checagem.

Resposta: no máximo 15 itens, cada um com arquivo:linha, gravidade (alta/média/baixa) e uma frase de correção sugerida. Se estiver tudo certo, diga isso em uma linha.
```

### `.claude/agents/playtest-runner.md`
```markdown
---
name: playtest-runner
description: Roda o jogo no Roblox Studio via MCP, lê o console e resume erros. Use depois de implementar ou corrigir algo.
disallowedTools: Write, Edit, Agent
model: sonnet
maxTurns: 10
---

Você testa o jogo no Roblox Studio pelo MCP. Não edita arquivos do projeto.

Use apenas estas ferramentas do Studio: get_studio_state, start_stop_play, get_console_output, screen_capture, search_game_tree, inspect_instance. Não use execute_luau nem ferramentas de edição ou de geração de assets.

Fluxo: confirmar o estado do Studio, iniciar o Play, esperar alguns segundos, ler o console, tirar 1 screenshot se for útil, parar o Play.

Resposta (curta): 1) subiu sem erro? 2) erros/avisos do console, agrupados e deduplicados, com o script e a linha; 3) o que o screenshot mostra, em 1-2 frases. Nunca cole o console inteiro.
```

Observação: `disallowedTools` e `omitClaudeMd` constam da doc de subagentes. Se o nome real das ferramentas do Studio aparecer diferente em `/mcp`, ajustar a lista no corpo do `playtest-runner`. A lista no corpo é uma instrução ao agente, não um bloqueio técnico; o bloqueio real seria um `tools` com os nomes exatos.

---

## 5. Ciclo de trabalho por passo do roteiro

1. **Plano** (plan mode se o passo for grande): arquivos, riscos, métrica de retenção.
2. **Pesquisa pontual** só se houver dúvida de API: `roblox-researcher`.
3. **Implementar** na sessão principal, em pedaços pequenos.
4. **Revisar:** `luau-reviewer`. Corrigir os itens de gravidade alta.
5. **Testar:** `playtest-runner` (se o Studio MCP estiver ligado) ou o usuário aperta Play.
6. **Fechar o passo:** marcar no `CLAUDE.md`, commit, e `/clear` (ou `/compact` com foco).

---

## 6. Studio MCP (deixa o Claude Code "ver" o Studio)

Correção a uma afirmação anterior: o Roblox Studio tem um servidor MCP embutido. Com ele o Claude Code consegue dar Play, ler o console, tirar screenshot e inspecionar a árvore do jogo.

**Opções, da mais recomendada à menos:**
- **MCP embutido do Studio (recomendado).** Na doc oficial: Assistant > `...` > Manage MCP Servers > ligar "Enable Studio as MCP server". Para o Claude Code, usar Assistant Settings > MCP Servers > Quick connect > ligar Claude Code. A doc não traz comando específico do Claude Code; o caminho manual é o executável `StudioMCP` (macOS: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`; Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`). Reiniciar Studio e Claude Code depois. Ferramentas incluem: leitura/edição de scripts, busca na árvore do jogo, `execute_luau`, Play/Stop, console, screenshot, entrada de teclado/mouse e geração/inserção de assets.
- **`Roblox/studio-rust-mcp-server`: não usar.** O repositório foi arquivado em 03/04/2026 e o próprio Roblox diz que migrou o investimento para o MCP embutido.
- **Servidores de terceiros** (ex.: `robloxstudio-mcp`): exigem plugin e HTTP habilitado, e rodam via `npx -y`, que baixa e executa a última versão. Só se o embutido não bastar, e depois de revisar o código.

**Segurança:** a doc avisa que clientes MCP podem ler e modificar o que está nos seus lugares abertos no Studio. Conectar só clientes confiáveis e dar commit antes de sessões longas.

**Regra do projeto (recomendação, não doc):** código só por arquivos (Rojo é a fonte da verdade). O MCP serve para testar e inspecionar. Editar script pelos dois lados pode sobrescrever trabalho.

**Custo:** MCP adiciona ferramentas ao contexto. Ligar só quando for testar e desligar depois (`/mcp`).

---

## 7. Skills

Skills carregam sob demanda: só nome e descrição ficam sempre no contexto (limitadas a ~1.500 caracteres); o corpo entra quando a skill é usada. Por isso são o lugar certo para instruções longas, e cada skill instalada tem um custo fixo por turno.

### Criar no projeto (`.claude/skills/<nome>/SKILL.md`)
- **`retention`** (recomendado): mover o conteúdo do `RETENCAO.md` para o corpo, com a descrição: "Fórmulas, benchmarks e regras de retenção do Survivors. Use ao mexer em progressão, recompensas, level up, meta-progressão, onboarding ou analytics." Assim carrega sozinha quando o assunto aparece e não precisa de linha no `CLAUDE.md`. Se converter, apagar a linha "leia também o RETENCAO.md" do `CLAUDE.md`.
- **`novo-sistema`** (comando do usuário): fluxo padrão para criar um sistema novo.

```markdown
---
name: novo-sistema
description: Cria um sistema novo do Survivors seguindo as regras do projeto. Use com /novo-sistema <nome>.
disable-model-invocation: true
argument-hint: [nome-do-sistema]
---

Criar o sistema "$ARGUMENTS":
1. Descreva em 3-5 linhas: objetivo, arquivos, métrica de retenção que move.
2. Crie o módulo em src/server (lógica) e, se preciso, src/client (visual) e src/shared/Config (números).
3. Valide todo dado vindo do cliente. Use pool para objetos repetidos.
4. Registre os eventos de analytics aplicáveis (RETENCAO.md).
5. Diga exatamente o que testar ao apertar Play.
Não adiante outros sistemas.
```

### Skills de terceiros (opcionais, revisar antes)
| Skill | O que cobre | Instalar | Sinais de confiança |
|---|---|---|---|
| `roblox-luau` (gamedev-skills) | Serviços, Instances, eventos, divisão servidor/cliente, remotes, projetos Rojo | `npx skills add https://github.com/gamedev-skills/awesome-gamedev-agent-skills --skill roblox-luau` | ~5 mil estrelas no repositório e ~6,6 mil instalações, com auditorias de segurança aprovadas, segundo a página do skills.sh |
| `luau-types`, `luau-performance`, `roblox-networking` (stackfox-labs/luau-skills) | Tipos/strict, otimização, remotes seguros | `npx skills add stackfox-labs/luau-skills --skill <nome>` | Repositório novo e pequeno (6 commits, sem estrelas visíveis). Ler o conteúdo antes. |

Regras para skills de terceiros:
- Skill é instrução que o agente segue com as ferramentas dele. **Ler o `SKILL.md` inteiro antes de instalar** e rejeitar qualquer coisa que peça rede, credenciais ou comandos fora do escopo.
- Instalar **só o que vai usar** (cada descrição custa tokens em todo turno). Não instalar o pacote inteiro "por via das dúvidas".
- Depois de instalar, rodar `/skill-doctor` e remover o que não é usado.
- Para DataStore, tratar como skill separada e só quando chegar no passo 6 do roteiro.

---

## 8. Checklist de setup
- [ ] Criar os 4 arquivos de `.claude/agents/`
- [ ] Rodar `claude --agent survivors-lead` (ou configurar em `.claude/settings.json`)
- [ ] Converter `RETENCAO.md` em skill `retention` (opcional, recomendado)
- [ ] Criar skill `novo-sistema`
- [ ] Ligar o MCP embutido do Studio só para testar; commit antes
- [ ] Instalar no máximo 1 skill de Luau, depois de ler o `SKILL.md`
- [ ] Olhar `/usage` depois da primeira sessão para ver o custo por agente

---

## Fontes
- Subagentes (formato, campos, modelo, contexto): https://code.claude.com/docs/en/sub-agents
- Skills (formato, carregamento, custo, boas práticas): https://code.claude.com/docs/en/skills
- Gerenciar custos (clear/compact, modelo, MCP, agent teams): https://code.claude.com/docs/en/costs
- Studio MCP embutido: https://create.roblox.com/docs/studio/mcp
- Servidor MCP arquivado do Roblox: https://github.com/Roblox/studio-rust-mcp-server
- `robloxstudio-mcp` (terceiros): https://glama.ai/mcp/servers/@boshyxd/robloxstudio-mcp/blob/981a32b3a6c305df9ff8637c390000a55c9cc1be/README.md
- `roblox-luau`: https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/roblox-luau
- `luau-skills`: https://gh.r-mj.com/stackfox-labs/luau-skills
