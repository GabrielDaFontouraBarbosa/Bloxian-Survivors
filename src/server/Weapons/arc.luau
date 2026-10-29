--!strict
-- Machado: arremessado para frente com desvio aleatorio, sobe e desce em arco
-- (so visual: o acerto e no plano), girando e atravessando inimigos.
-- Evolucao (Espiral da Morte, radial = true): solta todos de uma vez em volta do
-- jogador e eles abrem em espiral.
local Runs = require(script.Parent.Parent.Runs)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Arc = {}

local SPREAD = math.rad(55) -- desvio maximo para os lados (modo normal)
local SPIRAL_TURN = 1.3 -- rad/s de curva na espiral

local function rotate(v: Vector3, angle: number): Vector3
	local c, s = math.cos(angle), math.sin(angle)
	return Vector3.new(v.X * c - v.Z * s, 0, v.X * s + v.Z * c)
end

function Arc.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, i: number)
	local st = slot.state
	local dir: Vector3
	if w.radial then
		if i == 1 then
			st.base = math.random() * math.pi * 2
		end
		local a = (st.base or 0) + (i - 1) * (math.pi * 2 / w.amount)
		dir = Vector3.new(math.cos(a), 0, math.sin(a))
	else
		dir = rotate(run.facing, (math.random() * 2 - 1) * SPREAD)
	end
	local size = w.size
	local part = FxPool.get("axe", slot.def.color, Vector3.new(size, size * 0.3, size))
	local p = Common.newProjectile(part, run.rootPos, dir, w.lifetime, w.pierce, size * 0.6 + 0.4)
	st.list = st.list or {}
	table.insert(st.list, p)
end

function Arc.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local list = slot.state.list
	if not list then
		return
	end
	local baseY = Common.fxY(run)
	Common.stepAll(list, dt, function(p)
		if w.radial then
			p.dir = rotate(p.dir, SPIRAL_TURN * dt)
		end
		p.pos += p.dir * w.projSpeed * dt
		Common.sweep(run, p, w)
		p.spin += dt * 12
		local lift = 0
		if (w.arcHeight or 0) > 0 then
			lift = math.sin(math.pi * math.clamp(p.t / w.lifetime, 0, 1)) * w.arcHeight
		end
		p.part.CFrame = CFrame.new(p.pos.X, baseY + lift, p.pos.Z) * CFrame.Angles(p.spin, 0, 0)
	end)
end

function Arc.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	Common.releaseAll(slot.state and slot.state.list)
end

return Arc
