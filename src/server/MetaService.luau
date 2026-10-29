--!strict
-- Lobby: tudo que acontece FORA da partida (decisao do usuario: nada de loja
-- permanente dentro da run).
--   * PowerUps: compra (custo cresce com cada rank comprado) e reembolso total
--   * Classes: comprar com ouro as que uma conquista liberou
--   * Missoes: resgatar recompensa
--   * ProfileSync: manda ao cliente o retrato do perfil para montar o lobby
-- Toda acao e validada aqui contra o perfil; o cliente so pede.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Events = require(script.Parent.Events)
local SaveService = require(script.Parent.SaveService)
local RunManager = require(script.Parent.RunManager)
local QuestService = require(script.Parent.QuestService)
local RateLimit = require(script.Parent.RateLimit)
local Analytics = require(script.Parent.Analytics)

local MetaService = {}

local profileSync = Remotes.event("ProfileSync")
local requestProfile = Remotes.event("RequestProfile")
local buyPowerUp = Remotes.event("BuyPowerUp")
local refundPowerUps = Remotes.event("RefundPowerUps")
local buyClass = Remotes.event("BuyClass")
local claimQuest = Remotes.event("ClaimQuest")
local notice = Remotes.event("Notice")

-- Retrato do perfil para o lobby (so dados; nomes/textos o cliente tira do Content).
local function snapshot(player: Player, profile: SaveService.Profile): any
	local powerUps = {}
	for _, def in Config.PowerUps do
		local rank = profile.powerUps[def.id] or 0
		powerUps[def.id] = {
			rank = rank,
			cost = if rank < def.maxLevel then Content.powerUpCost(def, rank, profile.bought) else -1,
		}
	end
	local classes = {}
	for _, def in Config.Classes do
		classes[def.id] = {
			unlocked = SaveService.isUnlocked(profile, "class", def.id),
			owned = SaveService.ownsClass(profile, def.id),
		}
	end
	local stages = {}
	for _, def in Config.Stages do
		stages[def.id] = SaveService.isUnlocked(profile, "stage", def.id)
	end
	local arcanas = {}
	for _, def in Config.Arcanas do
		arcanas[def.id] = SaveService.isUnlocked(profile, "arcana", def.id)
	end
	local adventures = {}
	for _, def in Config.Adventures do
		adventures[def.id] = {
			unlocked = SaveService.isUnlocked(profile, "adventure", def.id),
			done = profile.adventures[def.id] or 0,
		}
	end
	local quests = {}
	for _, q in profile.quests do
		local def = Content.quests[q.id]
		table.insert(quests, { id = q.id, progress = q.progress, done = def ~= nil and q.progress >= def.n })
	end
	return {
		gold = profile.gold,
		spent = profile.spent,
		powerUps = powerUps,
		classes = classes,
		stages = stages,
		arcanas = arcanas,
		adventures = adventures,
		achievements = table.clone(profile.achievements),
		quests = quests,
		selected = table.clone(profile.selected),
		stats = {
			kills = profile.stats.kills,
			runs = profile.stats.runs,
			bestMinutes = profile.stats.bestMinutes,
			bestLevel = profile.stats.bestLevel,
			goldTotal = profile.stats.goldTotal,
		},
		inRun = RunManager.inRun(player),
	}
end

function MetaService.sync(player: Player)
	local profile = SaveService.peek(player)
	if profile then
		profileSync:FireClient(player, snapshot(player, profile))
	end
end

-- Acoes do lobby: perfil carregado, fora de run, sem spam.
local function lobbyProfile(player: Player, action: string): SaveService.Profile?
	if not RateLimit.allow(player, action, 0.15) then
		return nil
	end
	if RunManager.inRun(player) then
		notice:FireClient(player, "Isso só pode ser feito no lobby.")
		return nil
	end
	return SaveService.peek(player)
end

function MetaService.init()
	requestProfile.OnServerEvent:Connect(function(player)
		if RateLimit.allow(player, "requestProfile", 0.5) then
			MetaService.sync(player)
		end
	end)

	buyPowerUp.OnServerEvent:Connect(function(player, id)
		local profile = lobbyProfile(player, "buyPowerUp")
		if not profile or type(id) ~= "string" then
			return
		end
		local def = Content.powerUps[id]
		if not def then
			return -- id inventado pelo cliente
		end
		local rank = profile.powerUps[id] or 0
		if rank >= def.maxLevel then
			return
		end
		local cost = Content.powerUpCost(def, rank, profile.bought)
		if profile.gold < cost then
			notice:FireClient(player, "Ouro insuficiente.")
			MetaService.sync(player)
			return
		end
		profile.gold -= cost
		profile.powerUps[id] = rank + 1
		profile.spent += cost
		profile.bought += 1
		SaveService.markDirty(player)
		Analytics.powerUpBought(player, id, rank + 1, cost, profile.gold)
		MetaService.sync(player)
	end)

	refundPowerUps.OnServerEvent:Connect(function(player)
		local profile = lobbyProfile(player, "refund")
		if not profile then
			return
		end
		profile.gold += profile.spent
		profile.powerUps = {}
		profile.spent = 0
		profile.bought = 0
		SaveService.markDirty(player)
		MetaService.sync(player)
	end)

	buyClass.OnServerEvent:Connect(function(player, id)
		local profile = lobbyProfile(player, "buyClass")
		if not profile or type(id) ~= "string" then
			return
		end
		local def = Content.classes[id]
		if not def or SaveService.ownsClass(profile, id) then
			return
		end
		if not SaveService.isUnlocked(profile, "class", id) then
			notice:FireClient(player, "Essa classe ainda está bloqueada.")
			return
		end
		if profile.gold < def.price then
			notice:FireClient(player, "Ouro insuficiente.")
			return
		end
		profile.gold -= def.price
		profile.owned[id] = true
		profile.selected.class = id
		SaveService.markDirty(player)
		Analytics.classBought(player, id, def.price, profile.gold)
		MetaService.sync(player)
	end)

	claimQuest.OnServerEvent:Connect(function(player, index)
		local profile = lobbyProfile(player, "claimQuest")
		if not profile then
			return
		end
		local gold = QuestService.claim(player, index)
		if gold > 0 then
			notice:FireClient(player, ("Missão resgatada: +%d de ouro!"):format(gold))
		end
		MetaService.sync(player)
	end)

	-- fim de run: o lobby volta com ouro, conquistas e missoes atualizados
	Events.on("RunEnded", function(run: any)
		task.defer(MetaService.sync, run.player)
	end)
end

return MetaService
