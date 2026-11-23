--!strict
-- Adagas: projeteis rapidos para onde o jogador esta olhando, lado a lado.
local Runs = require(script.Parent.Parent.Runs)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Directional = {}

local LIFETIME = 1.4

function Directional.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, i: number)
	local st = slot.state
	local dir = run.facing
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local offset = (i - (w.amount + 1) / 2) * w.spread
	local origin = Common.flat(run.rootPos) + side * offset
	local part = FxPool.get("blade", slot.def.color, Vector3.new(w.size * 0.5, w.size * 0.3, w.size * 2.2))
	local p = Common.newProjectile(part, origin, dir, LIFETIME, w.pierce, w.size * 0.6 + 0.3)
	st.list = st.list or {}
	table.insert(st.list, p)
end

function Directional.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local list = slot.state.list
	if not list then
		return
	end
	local y = Common.fxY(run)
	Common.stepAll(list, dt, function(p)
		p.pos += p.dir * w.projSpeed * dt
		Common.sweep(run, p, w)
		local here = Vector3.new(p.pos.X, y, p.pos.Z)
		p.part.CFrame = CFrame.lookAt(here, here + p.dir)
	end)
end

function Directional.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	Common.releaseAll(slot.state and slot.state.list)
end

return Directional
