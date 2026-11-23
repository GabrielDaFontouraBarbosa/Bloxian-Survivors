--!strict
-- Ponto de entrada do cliente: monta as telas (lobby, HUD, level up, bau,
-- resultado, avisos), o cenario da run e liga os RemoteEvents.
-- O cliente so mostra e pede; o servidor decide e valida tudo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Content = require(Shared:WaitForChild("Content"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = script.Parent:WaitForChild("Ui")
local Lobby = require(Ui:WaitForChild("Lobby"))
local Hud = require(Ui:WaitForChild("Hud"))
local LevelUp = require(Ui:WaitForChild("LevelUp"))
local Chest = require(Ui:WaitForChild("Chest"))
local Results = require(Ui:WaitForChild("Results"))
local Toast = require(Ui:WaitForChild("Toast"))
local Scenery = require(script.Parent:WaitForChild("Scenery"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- servidor -> cliente
local profileSync = Remotes.event("ProfileSync")
local runState = Remotes.event("RunState")
local runSync = Remotes.event("RunSync")
local runResults = Remotes.event("RunResults")
local levelUpOffer = Remotes.event("LevelUpOffer")
local chestOpened = Remotes.event("ChestOpened")
local toast = Remotes.event("Toast")
local notice = Remotes.event("Notice")
-- cliente -> servidor
local requestProfile = Remotes.event("RequestProfile")
local requestStartRun = Remotes.event("RequestStartRun")
local quitRun = Remotes.event("QuitRun")
local buyPowerUp = Remotes.event("BuyPowerUp")
local refundPowerUps = Remotes.event("RefundPowerUps")
local buyClass = Remotes.event("BuyClass")
local claimQuest = Remotes.event("ClaimQuest")
local chooseUpgrade = Remotes.event("ChooseUpgrade")
local rerollUpgrade = Remotes.event("RerollUpgrade")
local skipUpgrade = Remotes.event("SkipUpgrade")
local chestContinue = Remotes.event("ChestContinue")

local inRun = false
local showingResults = false

-- Lobby aparece so fora da run e depois de fechar a tela de resultado.
local function refreshLobby()
	Lobby.setVisible(not inRun and not showingResults)
end

Toast.init(playerGui)
Lobby.init(playerGui, {
	start = function(req)
		requestStartRun:FireServer(req)
	end,
	buyPowerUp = function(id)
		buyPowerUp:FireServer(id)
	end,
	refund = function()
		refundPowerUps:FireServer()
	end,
	buyClass = function(id)
		buyClass:FireServer(id)
	end,
	claimQuest = function(index)
		claimQuest:FireServer(index)
	end,
})
Hud.init(playerGui, function()
	quitRun:FireServer()
end)
LevelUp.init(playerGui, {
	choose = function(index)
		chooseUpgrade:FireServer(index)
	end,
	reroll = function()
		rerollUpgrade:FireServer()
	end,
	skip = function()
		skipUpgrade:FireServer()
	end,
})
Chest.init(playerGui, function()
	chestContinue:FireServer()
end)
Results.init(playerGui, function()
	showingResults = false
	refreshLobby()
	requestProfile:FireServer()
end)

profileSync.OnClientEvent:Connect(function(data)
	Lobby.render(data)
end)

runState.OnClientEvent:Connect(function(data)
	if type(data) == "table" and data.active then
		inRun = true
		showingResults = false
		Results.hide()
		Hud.setVisible(true)
		local stage = Content.stages[data.stage]
		Scenery.enter(if stage then stage.scenery else "forest", data.floorY)
	else
		inRun = false
		Hud.setVisible(false)
		LevelUp.hide()
		Chest.hide()
		Scenery.leave()
	end
	refreshLobby()
end)

runSync.OnClientEvent:Connect(function(data)
	if inRun then
		Hud.update(data)
	end
end)

levelUpOffer.OnClientEvent:Connect(function(data)
	if data then
		LevelUp.show(data)
	else
		LevelUp.hide()
	end
end)

chestOpened.OnClientEvent:Connect(function(data)
	if data then
		Chest.show(data)
	else
		Chest.hide()
	end
end)

runResults.OnClientEvent:Connect(function(data)
	showingResults = true
	Results.show(data)
	refreshLobby()
end)

toast.OnClientEvent:Connect(Toast.event)
notice.OnClientEvent:Connect(Toast.notice)

refreshLobby()
requestProfile:FireServer() -- caso o ProfileSync do join tenha chegado antes das telas
