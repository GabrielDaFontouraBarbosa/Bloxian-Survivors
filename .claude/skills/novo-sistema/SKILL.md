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
