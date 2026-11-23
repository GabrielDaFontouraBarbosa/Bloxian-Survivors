--!strict
-- Crucifixo: vai na direcao do inimigo mais proximo, freia, volta passando pelo
-- jogador e segue (bumerangue). Atravessa tudo e pode acertar de novo na volta.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Boomerang = {}

local AIM_RANGE = 40

function Boomerang.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, _i: number)
	local st = slot.state
	local origin = Common.flat(run.rootPos)
	local target = EnemyService.nearest(run, origin, AIM_RANGE)
	local dir = run.facing
	if target then
		local to = Common.flat(target.pos - origin)
		if to.Magnitude > 0.01 then
			dir = to.Unit
		end
	end
	local size = w.size
	local part = FxPool.get("cross", slot.def.color, Vector3.new(size * 0.35, size * 0.25, size))
	local p = Common.newProjectile(part, origin, dir, w.lifetime, w.pierce, size * 0.5 + 0.4)
	st.list = st.list or {}
	table.insert(st.list, p)
end

function Boomerang.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local list = slot.state.list
	if not list then
		return
	end
	local y = Common.fxY(run)
	local outTime = w.outTime or 0.55
	Common.stepAll(list, dt, function(p)
		-- velocidade cai ate zero no outTime e depois fica negativa (volta)
		local before = p.t - dt
		local v = w.projSpeed * (1 - p.t / outTime)
		v = math.max(v, -w.projSpeed * 1.5)
		if before < outTime and p.t >= outTime then
			table.clear(p.hit) -- na volta pode acertar os mesmos de novo
		end
		p.pos += p.dir * v * dt
		Common.sweep(run, p, w)
		p.spin += dt * 14
		p.part.CFrame = CFrame.new(p.pos.X, y, p.pos.Z) * CFrame.Angles(0, p.spin, 0)
	end)
end

function Boomerang.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	Common.releaseAll(slot.state and slot.state.list)
end

return Boomerang
