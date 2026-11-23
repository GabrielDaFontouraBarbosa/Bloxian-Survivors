--!strict
-- Armas e passivas da run (os slots do VS: Config.Run.MaxWeapons/MaxPassives),
-- sorteio das opcoes de level up e evolucao de arma.
-- So entra no sorteio o que o jogador ja liberou (foto tirada no inicio da run).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Runs = require(script.Parent.Runs)
local Stats = require(script.Parent.Stats)
local Events = require(script.Parent.Events)
local PlayerHealth = require(script.Parent.PlayerHealth)
local WeaponService = require(script.Parent.WeaponService)

local Loadout = {}

-- Opcao de level up / item de bau. kind: "weapon" | "passive" | "gold" | "heal".
export type Option = { kind: string, id: string?, level: number?, new: boolean? }

function Loadout.findWeapon(run: Runs.Run, id: string): Runs.WeaponSlot?
	for _, slot in run.weapons do
		if slot.id == id then
			return slot
		end
	end
	return nil
end

function Loadout.findPassive(run: Runs.Run, id: string): Runs.PassiveSlot?
	for _, slot in run.passives do
		if slot.id == id then
			return slot
		end
	end
	return nil
end

function Loadout.addWeapon(run: Runs.Run, id: string): Runs.WeaponSlot?
	local def = Content.weapons[id]
	if not def or #run.weapons >= Config.Run.MaxWeapons or Loadout.findWeapon(run, id) then
		return nil
	end
	local slot: Runs.WeaponSlot = { id = id, def = def, level = 1, cd = 0.4, state = nil }
	table.insert(run.weapons, slot)
	if def.evolved and def.from then
		run.evolvedFrom[def.from] = true -- a base desta evolucao nao aparece mais
	end
	return slot
end

function Loadout.addPassive(run: Runs.Run, id: string): Runs.PassiveSlot?
	local def = Content.passives[id]
	if not def or #run.passives >= Config.Run.MaxPassives or Loadout.findPassive(run, id) then
		return nil
	end
	local slot: Runs.PassiveSlot = { id = id, def = def, level = 1 }
	table.insert(run.passives, slot)
	Stats.recompute(run)
	return slot
end

type Candidate = { opt: Option, weight: number }

-- Sorteia as opcoes do level up (3, ou 4 com a Sorte). Sem nada para pegar:
-- oferece ouro ou cura (como o VS faz quando tudo esta no maximo).
function Loadout.options(run: Runs.Run): { Option }
	local pool: { Candidate } = {}
	for _, slot in run.weapons do
		if not slot.def.evolved and slot.level < slot.def.maxLevel then
			table.insert(pool, { opt = { kind = "weapon", id = slot.id, level = slot.level + 1, new = false }, weight = slot.def.rarity or 100 })
		end
	end
	for _, slot in run.passives do
		if slot.level < slot.def.maxLevel then
			table.insert(pool, { opt = { kind = "passive", id = slot.id, level = slot.level + 1, new = false }, weight = slot.def.rarity or 100 })
		end
	end
	if #run.weapons < Config.Run.MaxWeapons then
		for _, def in Config.Weapons do
			if not def.evolved and run.unlocked.weapon[def.id] and not Loadout.findWeapon(run, def.id) and not run.evolvedFrom[def.id] then
				table.insert(pool, { opt = { kind = "weapon", id = def.id, level = 1, new = true }, weight = def.rarity or 100 })
			end
		end
	end
	if #run.passives < Config.Run.MaxPassives then
		for _, def in Config.Passives do
			if run.unlocked.passive[def.id] and not Loadout.findPassive(run, def.id) then
				table.insert(pool, { opt = { kind = "passive", id = def.id, level = 1, new = true }, weight = def.rarity or 100 })
			end
		end
	end

	local count = Config.Run.BaseOptions
	local luck = run.stats.luck
	if luck > 1 and math.random() < 1 - 1 / luck then
		count += 1
	end

	local out: { Option } = {}
	while #out < count and #pool > 0 do
		local total = 0
		for _, c in pool do
			total += c.weight
		end
		local roll = math.random() * total
		local pick = #pool
		for i, c in pool do
			roll -= c.weight
			if roll <= 0 then
				pick = i
				break
			end
		end
		table.insert(out, pool[pick].opt)
		table.remove(pool, pick)
	end
	if #out == 0 then
		out = { { kind = "gold" }, { kind = "heal" } }
	end
	return out
end

-- Aplica uma opcao (escolha do level up ou item do bau). Devolve true se aplicou.
function Loadout.apply(run: Runs.Run, opt: Option): boolean
	if opt.kind == "weapon" and opt.id then
		local slot = Loadout.findWeapon(run, opt.id)
		if slot then
			if slot.def.evolved or slot.level >= slot.def.maxLevel then
				return false
			end
			slot.level += 1
		else
			slot = Loadout.addWeapon(run, opt.id)
			if not slot then
				return false
			end
		end
		if slot and not slot.def.evolved and slot.level >= slot.def.maxLevel then
			Events.emit("WeaponMaxed", run, slot.id)
		end
		return true
	elseif opt.kind == "passive" and opt.id then
		local slot = Loadout.findPassive(run, opt.id)
		if slot then
			if slot.level >= slot.def.maxLevel then
				return false
			end
			slot.level += 1
			Stats.recompute(run)
		else
			if not Loadout.addPassive(run, opt.id) then
				return false
			end
		end
		return true
	elseif opt.kind == "gold" then
		run.gold += Config.Chest.LevelUpGold * run.stats.greed
		return true
	elseif opt.kind == "heal" then
		PlayerHealth.heal(run, Config.Chest.LevelUpHeal)
		return true
	end
	return false
end

-- Arma pronta para evoluir: nivel maximo + passiva par (ou Arcano da Lua).
function Loadout.canEvolve(run: Runs.Run, slot: Runs.WeaponSlot): boolean
	local def = slot.def
	local evo = def.evolution
	if def.evolved or not evo or slot.level < def.maxLevel or not Content.weapons[evo.into] then
		return false
	end
	local flags = run.arcana and run.arcana.flags
	if flags and flags.evolveWithoutPassive then
		return true
	end
	return Loadout.findPassive(run, evo.passive) ~= nil
end

function Loadout.evolvable(run: Runs.Run): { Runs.WeaponSlot }
	local out = {}
	for _, slot in run.weapons do
		if Loadout.canEvolve(run, slot) then
			table.insert(out, slot)
		end
	end
	return out
end

-- Troca a arma pela evolucao (mesmo slot). Devolve (idAntigo, idNovo).
function Loadout.evolve(run: Runs.Run, slot: Runs.WeaponSlot): (string, string)
	local into = Content.weapons[slot.def.evolution.into]
	local fromId = slot.id
	WeaponService.releaseSlot(run, slot) -- recolhe projeteis da arma antiga
	slot.id = into.id
	slot.def = into
	slot.level = 1
	slot.cd = 0.3
	slot.state = nil
	run.evolvedFrom[fromId] = true
	Events.emit("WeaponEvolved", run, fromId, into.id)
	return fromId, into.id
end

-- Sobe 1 nivel de algo que o jogador ja tem (item de bau sem evolucao).
function Loadout.randomUpgrade(run: Runs.Run): Option?
	local candidates: { Option } = {}
	for _, slot in run.weapons do
		if not slot.def.evolved and slot.level < slot.def.maxLevel then
			table.insert(candidates, { kind = "weapon", id = slot.id, level = slot.level + 1 })
		end
	end
	for _, slot in run.passives do
		if slot.level < slot.def.maxLevel then
			table.insert(candidates, { kind = "passive", id = slot.id, level = slot.level + 1 })
		end
	end
	if #candidates == 0 then
		return nil
	end
	local opt = candidates[math.random(#candidates)]
	if Loadout.apply(run, opt) then
		return opt
	end
	return nil
end

return Loadout
