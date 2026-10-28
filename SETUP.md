# SETUP.md — como rodar o jogo no Roblox Studio

Fluxo **validado no Windows** em 2026-10-28. Precisa de duas coisas rodando ao mesmo tempo: o **servidor do Rojo** (no terminal do PC) e o **plugin do Rojo** (dentro do Studio). O Studio sozinho não puxa o código.

## Uma vez só

### 1. Clonar
```powershell
cd ~\Documents
git clone https://github.com/GabrielDaFontouraBarbosa/Bloxian-Survivors.git
cd Bloxian-Survivors
```

### 2. Pegar o Rojo
Não precisa instalar: é um executável solto.

1. Abrir <https://github.com/rojo-rbx/rojo/releases/latest>
2. Baixar o zip do Windows (o nome tem `windows` e `x86_64`).
3. Extrair e colocar o **`rojo.exe` na raiz do projeto**, junto do `default.project.json`.

> Alternativa "correta": gerenciar a versão com Rokit (`rokit add rojo-rbx/rojo`), que respeita o `rokit.toml`. O `.exe` solto é mais rápido pra começar.

### 3. Instalar o plugin do Studio
```powershell
.\rojo.exe plugin install
```
Depois **fechar e reabrir o Studio**.

> Pela interface dá no mesmo: `View → Toolbox → Creator Store → Plugins`, buscar "Rojo".

## Toda vez que for desenvolver

### 1. Ligar o servidor (deixar a janela aberta)
```powershell
cd ~\Documents\Bloxian-Survivors
git pull
.\rojo.exe serve
```
Aparece algo como *"Rojo server listening on port 34872"*. **Fechar essa janela desconecta o Studio.**

### 2. No Studio
1. Lugar novo com template **Baseplate** (precisa de chão e spawn, senão o personagem não nasce).
2. Aba **Plugins → Rojo → Connect** (o endereço padrão já vem certo). Permitir, se pedir permissão.
3. Confirmar no Explorer:
   - `ServerScriptService → Server` (Main, EnemyService, WaveService, WeaponService, XpService, PlayerStats, MetaService, SaveService, Analytics)
   - `ReplicatedStorage → Shared` (Config, Remotes, PlayerUtil)
   - `StarterPlayer → StarterPlayerScripts → Client` (TopDownCamera, Hud)
4. **F5 / Play.**

Com o Rojo conectado, mudança em arquivo sincroniza na hora — não precisa reiniciar o Studio. Depois de um `git pull`, o Rojo propaga sozinho.

## O que esperar no Output

- `[Survivors] Servidor iniciado (passo 6: ...)` — tudo certo.
- Um **`warn` do DataStore** — **esperado** em lugar não publicado. Ver abaixo.

## Controles

| Ação | Como |
|---|---|
| Mover | WASD |
| Atacar | automático (a arma mira sozinha) |
| Escolher upgrade | clicar num dos 3 botões no level up |
| Abrir a loja permanente | tecla **B** (ou o botão no canto) |

## Pegadinhas conhecidas

- **`rojo` não reconhecido como comando:** o `rojo.exe` não está na pasta onde você rodou o comando. Use `.\rojo.exe` dentro da raiz do projeto.
- **Connect não acha nada:** o `rojo serve` não está rodando (ou a janela foi fechada).
- **Personagem não nasce / cai no vazio:** o lugar não é Baseplate, falta chão ou SpawnLocation.
- **Moedas e perks zeram ao fechar:** esperado. DataStore só funciona em jogo **publicado** e, no Studio, com *Game Settings → Security → Enable Studio Access to API Services*. Sem isso o `SaveService` cai para memória e avisa — o jogo roda normal, só não persiste.
