--!strict
-- Aventuras (Config/Adventures): confere se o capitulo pedido pode ser jogado
-- e, quando o jogador sobrevive ao tempo dele, marca o progresso e paga a
-- recompensa (so na primeira vez que completa cada capitulo).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)
local SaveService = require(script.Parent.SaveService)

local AdventureService = {}

local toast = Remotes.event("Toast")

-- Capitulo jogavel? Devolve a definicao do capitulo ou (nil, motivo).
function AdventureService.resolve(profile: SaveService.Profile, adventureId: string, chapter: any): (any?, string?)
	local adv = Content.adventures[adventureId]
	if not adv then
		return nil, "Aventura inválida."
	end
	if not SaveService.isUnlocked(profile, "adventure", adventureId) then
		return nil, "Essa aventura ainda está bloqueada."
	end
	if type(chapter) ~= "number" then
		return nil, "Capítulo inválido."
	end
	local index = math.floor(chapter)
	local def = adv.chapters[index]
	if not def then
		return nil, "Capítulo inválido."
	end
	local done = profile.adventures[adventureId] or 0
	if index > done + 1 then
		return nil, "Termine o capítulo anterior primeiro."
	end
	return def, nil
end

local function onStageCompleted(run: Runs.Run)
	local advId = run.adventureId
	local index = run.chapterIndex
	if not advId or not index then
		return
	end
	local profile = SaveService.peek(run.player)
	local adv = Content.adventures[advId]
	if not profile or not adv then
		return
	end
	local done = profile.adventures[advId] or 0
	if index ~= done + 1 then
		return -- capitulo repetido: sem recompensa de novo
	end
	profile.adventures[advId] = index
	local chapter = adv.chapters[index]
	local reward = chapter and chapter.reward
	if reward then
		if reward.gold then
			profile.gold += reward.gold
		end
		if reward.unlock then
			SaveService.grant(profile, reward.unlock)
		end
	end
	SaveService.markDirty(run.player)
	run.data.chapterDone = true
	toast:FireClient(run.player, { kind = "chapter", adventure = advId, chapter = index })
	Events.emit("AdventureChapterDone", run.player, advId, index)
end

function AdventureService.init()
	Events.on("StageCompleted", onStageCompleted)
end

return AdventureService
