--!strict
-- Sino do Trovao: raios caem em `amount` inimigos aleatorios no alcance, ferindo
-- tudo num raio pequeno em volta. Evolucao (Ciclo do Trovao, double = true): cada
-- raio cai de novo no mesmo lugar logo depois.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Strike = {}

local SECOND_STRIKE_DELAY = 0.25
local BOLT_HEIGHT = 30

local function bolt(run: Runs.Run, slot: Runs.WeaponSlot, w: any, pos: Vector3)
	EnemyService.forEachInRadius(run, pos, w.radius, function(enemy)
		Common.hit(run, enemy, w, pos)
	end)
	local part = FxPool.get("bolt", slot.def.color, Vector3.new(0.7, BOLT_HEIGHT, 0.7))
	part.CFrame = CFrame.new(pos.X, run.floorY + BOLT_HEIGHT / 2, pos.Z)
	FxPool.flash(part, 0.15)
end

function Strike.fire(run: Runs.Run, slot: Runs.WeaponSlot, w: any)
	local targets = EnemyService.randomInRange(run, run.rootPos, w.range, w.amount)
	local st = slot.state
	for _, enemy in targets do
		local pos = enemy.pos
		bolt(run, slot, w, pos)
		if w.double then
			st.pending = st.pending or {}
			table.insert(st.pending, { at = run.time + SECOND_STRIKE_DELAY, pos = pos })
		end
	end
end

-- Segundo raio respeita a pausa da run (usa run.time, nao task.delay).
function Strike.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, _dt: number)
	local pending = slot.state.pending
	if not pending then
		return
	end
	for i = #pending, 1, -1 do
		local item = pending[i]
		if run.time >= item.at then
			bolt(run, slot, w, item.pos)
			table.remove(pending, i)
		end
	end
end

function Strike.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	if slot.state then
		slot.state.pending = nil
	end
end

return Strike
