--!strict
-- Varinha de Fogo: sorteia UM inimigo no alcance e dispara a rajada inteira na
-- direcao dele, em leque (`spread` rad entre bolas). As bolas vao retas (nao
-- perseguem), sao lentas e batem forte. Sem alvo: atira para um lado qualquer.
-- Evolucao (Chama Infernal): bolas enormes que atravessam tudo (pierce = -1).
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Fireball = {}

function Fireball.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, i: number)
	local st = slot.state
	local origin = Common.flat(run.rootPos)
	if i == 1 or not st.aim then
		-- mira nova a cada rajada: um alvo aleatorio (e isso que diferencia do Cetro)
		local target = EnemyService.randomInRange(run, origin, w.range, 1)[1]
		local to = if target then Common.flat(target.pos - origin) else Vector3.zero
		if to.Magnitude > 0.01 then
			st.aim = to.Unit
		else
			local a = math.random() * math.pi * 2
			st.aim = Vector3.new(math.cos(a), 0, math.sin(a))
		end
	end
	-- leque centrado na mira
	local offset = (i - (w.amount + 1) / 2) * w.spread
	local aim: Vector3 = st.aim
	local dir = CFrame.Angles(0, offset, 0):VectorToWorldSpace(aim)
	local part = FxPool.get("fire", slot.def.color, Vector3.one * w.size)
	local p = Common.newProjectile(part, origin, Common.flat(dir).Unit, w.lifetime, w.pierce, w.size * 0.5 + 0.3)
	st.list = st.list or {}
	table.insert(st.list, p)
end

function Fireball.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local list = slot.state.list
	if not list then
		return
	end
	local y = Common.fxY(run)
	Common.stepAll(list, dt, function(p)
		p.pos += p.dir * w.projSpeed * dt
		Common.sweep(run, p, w)
		p.part.CFrame = CFrame.new(p.pos.X, y, p.pos.Z)
	end)
end

function Fireball.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	Common.releaseAll(slot.state and slot.state.list)
end

return Fireball
