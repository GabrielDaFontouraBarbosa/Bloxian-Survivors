--!strict
-- Bau de chefe (estilo VS): 1, 3 ou 5 itens (a Sorte melhora a chance) + ouro.
-- Cada item: EVOLUCAO se alguma arma estiver pronta (prioridade), senao sobe 1
-- nivel de algo que o jogador ja tem, senao vira ouro. Pausa a run enquanto o
-- jogador ve o que ganhou; fecha sozinho depois de Config.Run.ChestAutoContinue.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local Loadout = require(script.Parent.Loadout)

local ChestService = {}

local chestOpened = Remotes.event("ChestOpened")
local chestContinue = Remotes.event("ChestContinue")

local function itemCount(luck: number): number
	local roll = math.random()
	if roll < Config.Chest.FiveChance * luck then
		return 5
	elseif roll < (Config.Chest.FiveChance + Config.Chest.ThreeChance) * luck then
		return 3
	end
	return 1
end

function ChestService.open(run: Runs.Run)
	if run.ending then
		return
	end
	local n = itemCount(run.stats.luck)
	local items = {}
	local extraGold = 0
	for _ = 1, n do
		local ready = Loadout.evolvable(run)
		if #ready > 0 then
			local fromId, toId = Loadout.evolve(run, ready[1])
			table.insert(items, { kind = "evolve", from = fromId, to = toId })
		else
			local up = Loadout.randomUpgrade(run)
			if up then
				table.insert(items, { kind = up.kind, id = up.id, level = up.level })
			else
				extraGold += Config.Chest.GoldPerItem
			end
		end
	end
	local gold = (Config.Chest.GoldBase + Config.Chest.GoldPerItem * n + extraGold) * run.stats.greed
	run.gold += gold
	run.chests += 1
	Events.emit("ChestOpened", run)

	run.data.chestUntil = os.clock() + Config.Run.ChestAutoContinue
	Runs.setPause(run, "chest", true)
	chestOpened:FireClient(run.player, { items = items, gold = math.floor(gold) })
end

local function close(run: Runs.Run)
	if not run.pauses.chest then
		return
	end
	run.data.chestUntil = nil
	Runs.setPause(run, "chest", false)
	chestOpened:FireClient(run.player, nil) -- fecha o painel
end

-- Roda mesmo com a run pausada: fecha o bau sozinho se o jogador sumir.
function ChestService.update(run: Runs.Run)
	local untilTime = run.data.chestUntil
	if untilTime and os.clock() >= untilTime then
		close(run)
	end
end

function ChestService.init()
	chestContinue.OnServerEvent:Connect(function(player)
		local run = Runs.get(player)
		if run then
			close(run)
		end
	end)
end

return ChestService
