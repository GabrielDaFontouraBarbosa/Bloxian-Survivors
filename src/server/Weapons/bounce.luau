--!strict
-- Runa Traçante: sai numa direcao aleatoria, atravessa todo mundo e QUICA nas
-- bordas da "tela" (um retangulo de meia-largura halfX/halfZ em volta do
-- jogador, mais ou menos o que a camera de cima mostra). Some depois de
-- `duration` s. Pode acertar o mesmo inimigo de novo a cada `hitEvery` s.
-- Evolucao (Runa do Fim): cada quique explode (`blast` = raio da explosao).
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Bounce = {}

local BLAST_FLASH = 0.15

function Bounce.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, _i: number)
	local st = slot.state
	local a = math.random() * math.pi * 2
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	local size = w.size
	local part = FxPool.get("rune", slot.def.color, Vector3.new(size, 0.35, size))
	-- pierce -1: atravessa tudo; o controle de repeticao fica no p.hit (tempo do ultimo acerto)
	local p = Common.newProjectile(part, run.rootPos, dir, math.max(0.3, w.duration), -1, size * 0.6 + 0.4)
	st.list = st.list or {}
	table.insert(st.list, p)
end

-- Explosao do quique (so na evolucao).
local function blast(run: Runs.Run, slot: Runs.WeaponSlot, w: any, at: Vector3)
	local r = w.blast
	EnemyService.forEachInRadius(run, at, r, function(enemy)
		Common.hit(run, enemy, w, at)
	end)
	local d = r * 2
	local disc = FxPool.get("disc", slot.def.color, Vector3.new(0.3, d, d))
	disc.CFrame = CFrame.new(at.X, run.floorY + 0.4, at.Z) * CFrame.Angles(0, 0, math.rad(90))
	FxPool.flash(disc, BLAST_FLASH)
end

function Bounce.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local list = slot.state.list
	if not list then
		return
	end
	local y = Common.fxY(run)
	local center = Common.flat(run.rootPos)
	local halfX, halfZ = w.halfX or 34, w.halfZ or 22
	local hitEvery = w.hitEvery or 0.4
	Common.stepAll(list, dt, function(p)
		local pos = p.pos + p.dir * w.projSpeed * dt
		local dx, dz = p.dir.X, p.dir.Z
		local bounced = false
		-- quica: inverte o eixo que passou da borda e traz de volta para dentro
		local rx, rz = pos.X - center.X, pos.Z - center.Z
		if rx > halfX and dx > 0 or rx < -halfX and dx < 0 then
			dx = -dx
			pos = Vector3.new(center.X + math.clamp(rx, -halfX, halfX), 0, pos.Z)
			bounced = true
		end
		if rz > halfZ and dz > 0 or rz < -halfZ and dz < 0 then
			dz = -dz
			pos = Vector3.new(pos.X, 0, center.Z + math.clamp(rz, -halfZ, halfZ))
			bounced = true
		end
		p.pos = pos
		if bounced then
			p.dir = Vector3.new(dx, 0, dz).Unit
			if w.blast then
				blast(run, slot, w, pos)
			end
		end

		-- acerto com repeticao: cada inimigo de novo so depois de hitEvery s
		EnemyService.forEachInRadius(run, pos, p.radius, function(enemy)
			local last = p.hit[enemy]
			if last == nil or p.t - (last :: any) >= hitEvery then
				(p.hit :: any)[enemy] = p.t
				Common.hit(run, enemy, w, pos - p.dir)
			end
		end)

		p.spin += dt * 6
		p.part.CFrame = CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, p.spin + math.rad(45), 0)
	end)
end

function Bounce.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	Common.releaseAll(slot.state and slot.state.list)
end

return Bounce
