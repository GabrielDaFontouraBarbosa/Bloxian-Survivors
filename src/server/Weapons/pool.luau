--!strict
-- Agua Benta: joga frascos perto de inimigos; cada um vira uma poca que fere
-- quem esta dentro a cada `tick` s, por `duration` s.
-- Evolucao (Mare Profana, follow = true): as pocas deslizam atras do jogador.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Pool = {}

local FOLLOW_SPEED = 7

type Puddle = { part: BasePart, pos: Vector3, untilT: number, tickAcc: number }

function Pool.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, _i: number)
	local st = slot.state
	local origin = Common.flat(run.rootPos)
	local spot: Vector3
	local targets = EnemyService.randomInRange(run, origin, w.throwRange * 2, 1)
	if targets[1] then
		spot = targets[1].pos
	else
		local a = math.random() * math.pi * 2
		spot = origin + Vector3.new(math.cos(a), 0, math.sin(a)) * (math.random() * w.throwRange)
	end
	local d = w.radius * 2
	local part = FxPool.get("puddle", slot.def.color, Vector3.new(0.3, d, d))
	local puddle: Puddle = { part = part, pos = Common.flat(spot), untilT = run.time + w.duration, tickAcc = w.tick }
	st.puddles = st.puddles or {}
	table.insert(st.puddles, puddle)
end

function Pool.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local puddles: { Puddle }? = slot.state.puddles
	if not puddles then
		return
	end
	local target = Common.flat(run.rootPos)
	for i = #puddles, 1, -1 do
		local pd = puddles[i]
		if run.time >= pd.untilT then
			FxPool.put(pd.part)
			local last = #puddles
			puddles[i] = puddles[last]
			puddles[last] = nil
			continue
		end
		if w.follow then
			local to = target - pd.pos
			if to.Magnitude > 1 then
				pd.pos += to.Unit * math.min(FOLLOW_SPEED * dt, to.Magnitude)
			end
		end
		pd.tickAcc += dt
		if pd.tickAcc >= w.tick then
			pd.tickAcc = 0
			EnemyService.forEachInRadius(run, pd.pos, w.radius, function(enemy)
				Common.hit(run, enemy, w, pd.pos)
			end)
		end
		pd.part.CFrame = CFrame.new(pd.pos.X, run.floorY + 0.25, pd.pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	end
end

function Pool.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	local st = slot.state
	if st and st.puddles then
		for _, pd in st.puddles do
			FxPool.put(pd.part)
		end
		st.puddles = {}
	end
end

return Pool
