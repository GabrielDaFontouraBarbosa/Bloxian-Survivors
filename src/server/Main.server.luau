--!strict
-- Ponto de entrada do servidor. Liga os sistemas, cuida da entrada/saida dos
-- jogadores e roda o loop central unico (regra do projeto: um Heartbeat so).
-- Mecanicas portadas do Vampire Survivors: ver PORTE-VS.md.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SaveService = require(script.Parent.SaveService)
local Arena = require(script.Parent.Arena)
local EnemyService = require(script.Parent.EnemyService)
local XpService = require(script.Parent.XpService)
local WeaponService = require(script.Parent.WeaponService)
local PickupService = require(script.Parent.PickupService)
local ChestService = require(script.Parent.ChestService)
local AchievementService = require(script.Parent.AchievementService)
local QuestService = require(script.Parent.QuestService)
local AdventureService = require(script.Parent.AdventureService)
local RunManager = require(script.Parent.RunManager)
local MetaService = require(script.Parent.MetaService)

print("[Survivors] Servidor iniciado (porte VS: runs, armas, evolucao, conquistas, missoes, aventuras).")

SaveService.init()
Arena.init()
EnemyService.init()
XpService.init()
WeaponService.init()
PickupService.init()
ChestService.init()
AchievementService.init()
QuestService.init()
AdventureService.init()
RunManager.init()
MetaService.init()

local function onPlayerAdded(player: Player)
	RunManager.onPlayerAdded(player) -- personagem nasce no lobby
	task.spawn(function()
		local profile = SaveService.load(player) -- pode esperar o DataStore
		if player.Parent then
			QuestService.ensure(profile)
			MetaService.sync(player)
		end
	end)
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	RunManager.onPlayerRemoving(player) -- guarda o ouro da run ANTES de salvar
	SaveService.release(player)
end)

game:BindToClose(function()
	RunManager.endAll()
	SaveService.saveAll()
end)

-- Loop central: um unico Heartbeat atualiza todas as runs (estagio, inimigos,
-- armas, XP, itens, vida).
RunService.Heartbeat:Connect(function(dt)
	RunManager.update(dt)
end)
