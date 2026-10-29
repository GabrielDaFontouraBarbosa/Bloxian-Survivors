--!strict
-- Stats VS do jogador na run, em duas camadas:
--   run.bonus = fixos da run: classe + PowerUps + arcano + regras da aventura
--               (montado uma vez no inicio)
--   run.stats = defaults + bonus + passivas + traco da classe por nivel
--               (recalculado quando pega/sobe passiva ou sobe de nivel)
-- Catalogo dos stats em Config/Stats. Numeros dos bonus no Config.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Runs = require(script.Parent.Runs)

local Stats = {}

-- Pisos para nenhum stat zerar ou inverter (ex.: recarga negativa).
local FLOORS = {
	might = 0.1,
	health = 0.1,
	cooldown = 0.15,
	area = 0.2,
	speed = 0.2,
	duration = 0.2,
	moveSpeed = 0.3,
	magnet = 0.2,
	luck = 0.5,
	growth = 0,
	greed = 0,
	curse = 0.5,
	amount = 0,
	armor = 0,
	recovery = 0,
	revival = 0,
}

local function addAll(into: { [string]: number }, bonus: any)
	if type(bonus) ~= "table" then
		return
	end
	for key, value in bonus do
		if type(value) == "number" and Content.stats[key] then
			into[key] = (into[key] or 0) + value
		end
	end
end

function Stats.defaults(): { [string]: number }
	local s = {}
	for _, def in Config.Stats do
		s[def.id] = if def.kind == "mult" then 1 else 0
	end
	return s
end

-- Monta os bonus fixos da run e as cargas de rerrolar/pular (chamado no inicio).
function Stats.setupRun(run: Runs.Run, powerUps: { [string]: number })
	local bonus: { [string]: number } = {}
	addAll(bonus, run.class.stats)
	for id, rank in powerUps do
		local def = Content.powerUps[id]
		if def and def.stat and rank > 0 then
			bonus[def.stat] = (bonus[def.stat] or 0) + def.per * rank
		end
	end
	if run.arcana then
		addAll(bonus, run.arcana.stats)
	end
	addAll(bonus, run.mods.stats)
	run.bonus = bonus

	local rerolls, skips = 0, 0
	for id, rank in powerUps do
		local def = Content.powerUps[id]
		if def and def.util == "rerolls" then
			rerolls += def.per * rank
		elseif def and def.util == "skips" then
			skips += def.per * rank
		end
	end
	run.rerolls = rerolls
	run.skips = skips
end

-- Recalcula run.stats e ajusta vida maxima e ressurreicoes (estilo VS: ganhar
-- Vida Max. tambem cura a diferenca).
function Stats.recompute(run: Runs.Run)
	local s = Stats.defaults()
	for key, value in run.bonus do
		s[key] = (s[key] or 0) + value
	end
	for _, slot in run.passives do
		local def = slot.def
		s[def.stat] = (s[def.stat] or 0) + def.per * slot.level
	end
	local perk = run.class.perk
	if perk then
		local steps = math.floor(run.level / perk.every)
		s[perk.stat] = (s[perk.stat] or 0) + math.min(perk.max, perk.amount * steps)
	end
	for key, floor in FLOORS do
		if s[key] ~= nil and s[key] < floor then
			s[key] = floor
		end
	end
	run.stats = s
	run.data.statsVersion = (run.data.statsVersion or 0) + 1 -- armas recalculam

	local newMax = run.class.baseHp * s.health
	if run.maxHp > 0 and newMax > run.maxHp then
		run.hp += newMax - run.maxHp
	end
	run.maxHp = newMax
	run.hp = math.min(run.hp, run.maxHp)

	local revivals = math.floor(s.revival)
	if revivals > run.revivalGranted then
		run.revivals += revivals - run.revivalGranted
		run.revivalGranted = revivals
	end
end

return Stats
