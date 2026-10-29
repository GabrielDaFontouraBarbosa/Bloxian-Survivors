--!strict
-- Armas da run: para cada slot calcula os stats finais (nivel da arma x stats do
-- jogador), conta a recarga e dispara o comportamento (server/Weapons/<kind>).
-- Rajadas (Quantidade > 1) saem uma a uma a cada `interval` s.
-- Tudo decidido no servidor; o visual vem do FxPool.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local Runs = require(script.Parent.Runs)
local FxPool = require(script.Parent.FxPool)

local WeaponService = {}

local Behaviors = script.Parent.Weapons
local BEHAVIORS: { [string]: any } = {
	whip = require(Behaviors.whip),
	homing = require(Behaviors.homing),
	directional = require(Behaviors.directional),
	arc = require(Behaviors.arc),
	boomerang = require(Behaviors.boomerang),
	orbit = require(Behaviors.orbit),
	aura = require(Behaviors.aura),
	pool = require(Behaviors.pool),
	strike = require(Behaviors.strike),
}

-- Chaves de geometria que crescem com a Area.
local AREA_KEYS = { "length", "width", "radius", "size" }

-- Stats finais da arma: nivel (Content.weaponStats) x stats do jogador.
local function computeStats(run: Runs.Run, slot: Runs.WeaponSlot): { [string]: any }
	local w = Content.weaponStats(slot.def, slot.level)
	local s = run.stats
	w.damage = (w.damage or 0) * s.might
	w.cooldown = math.max(0.05, (w.cooldown or 1) * s.cooldown)
	w.area = (w.area or 1) * s.area
	w.speed = (w.speed or 1) * s.speed
	w.duration = (w.duration or 0) * s.duration
	w.amount = math.max(1, math.floor((w.amount or 1) + s.amount))
	w.interval = w.interval or 0.1
	w.pierce = w.pierce or 1
	w.knockback = w.knockback or 1
	for _, key in AREA_KEYS do
		if w[key] then
			w[key] *= w.area
		end
	end
	if w.projSpeed then
		w.projSpeed *= w.speed
	end
	if w.spin then
		w.spin *= w.speed
	end
	return w
end

-- Cache por slot: so recalcula quando o nivel da arma ou os stats mudam.
local function statsFor(run: Runs.Run, slot: Runs.WeaponSlot): { [string]: any }
	local st = slot.state
	local version = run.data.statsVersion or 0
	if st.cacheLevel ~= slot.level or st.cacheVersion ~= version or st.cacheId ~= slot.id then
		st.cache = computeStats(run, slot)
		st.cacheLevel = slot.level
		st.cacheVersion = version
		st.cacheId = slot.id
	end
	return st.cache
end

function WeaponService.update(run: Runs.Run, dt: number)
	for _, slot in run.weapons do
		local behavior = BEHAVIORS[slot.def.kind]
		if not behavior then
			continue
		end
		if not slot.state then
			slot.state = {}
		end
		local st = slot.state
		local w = statsFor(run, slot)

		-- recarga
		slot.cd -= dt
		if slot.cd <= 0 then
			slot.cd = math.max(slot.cd + w.cooldown, w.cooldown * 0.5)
			if behavior.fire then
				behavior.fire(run, slot, w)
			end
			if behavior.shot then
				st.burstLeft = w.amount
				st.burstIndex = 0
				st.burstTimer = 0
			end
		end

		-- rajada: um disparo a cada `interval`
		if behavior.shot and (st.burstLeft or 0) > 0 then
			st.burstTimer -= dt
			while st.burstLeft > 0 and st.burstTimer <= 0 do
				st.burstIndex += 1
				st.burstLeft -= 1
				st.burstTimer += w.interval
				behavior.shot(run, slot, w, st.burstIndex)
			end
		end

		if behavior.update then
			behavior.update(run, slot, w, dt)
		end
		if run.ending then
			return
		end
	end
end

-- Recolhe tudo o que a arma tem na tela (evolucao ou fim de run).
function WeaponService.releaseSlot(run: Runs.Run, slot: Runs.WeaponSlot)
	local behavior = BEHAVIORS[slot.def.kind]
	if behavior and slot.state then
		behavior.release(run, slot)
	end
	slot.state = nil
end

function WeaponService.clear(run: Runs.Run)
	for _, slot in run.weapons do
		WeaponService.releaseSlot(run, slot)
	end
end

function WeaponService.init()
	FxPool.init()
end

return WeaponService
