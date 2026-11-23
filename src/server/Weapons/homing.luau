--!strict
-- Cetro: projetil teleguiado no inimigo mais proximo. Na mesma rajada cada
-- projetil tenta um alvo diferente. Se o alvo morre, segue reto.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Homing = {}

local LIFETIME = 3

function Homing.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, i: number)
	local st = slot.state
	if i == 1 or not st.targeted then
		st.targeted = {}
	end
	local origin = Common.flat(run.rootPos)
	local target = EnemyService.nearest(run, origin, w.range, st.targeted) or EnemyService.nearest(run, origin, w.range)
	if not target then
		return
	end
	st.targeted[target] = true
	local to = Common.flat(target.pos - origin)
	local dir = if to.Magnitude > 0.01 then to.Unit else run.facing
	local part = FxPool.get("ball", slot.def.color, Vector3.one * w.size)
	local p = Common.newProjectile(part, origin, dir, LIFETIME, w.pierce, w.size * 0.5 + 0.3)
	p.target = target
	st.list = st.list or {}
	table.insert(st.list, p)
end

function Homing.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local list = slot.state.list
	if not list then
		return
	end
	local y = Common.fxY(run)
	Common.stepAll(list, dt, function(p)
		local target = p.target
		if target and target.alive then
			local to = Common.flat(target.pos - p.pos)
			if to.Magnitude > 0.2 then
				p.dir = to.Unit
			end
		end
		p.pos += p.dir * w.projSpeed * dt
		Common.sweep(run, p, w)
		p.part.CFrame = CFrame.new(p.pos.X, y, p.pos.Z)
	end)
end

function Homing.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	Common.releaseAll(slot.state and slot.state.list)
end

return Homing
