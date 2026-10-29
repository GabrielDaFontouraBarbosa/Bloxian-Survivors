--!strict
-- Pecas compartilhadas pelos comportamentos de arma: acerto (critico, empurrao),
-- projetil generico com perfuracao e utilitarios de plano XZ.
-- Os comportamentos NAO requerem o WeaponService (evita require circular).
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)

local Common = {}

export type Projectile = {
	part: BasePart,
	pos: Vector3, -- no plano (Y ignorado no acerto)
	dir: Vector3,
	life: number,
	pierce: number, -- -1 = infinito; chega a 0 = some
	radius: number,
	hit: { [any]: boolean },
	t: number,
	target: any?,
	spin: number,
}

-- Vetor no plano XZ.
function Common.flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Altura dos efeitos (mais ou menos o meio dos inimigos).
function Common.fxY(run: Runs.Run): number
	return run.floorY + 2.2
end

-- Um acerto da arma: dano x Poder ja vem em w.damage; aqui entra o critico.
function Common.hit(run: Runs.Run, enemy: any, w: any, from: Vector3?): boolean
	local dmg = w.damage
	if w.crit and math.random() < w.crit then
		dmg *= w.critMult or 2
	end
	return EnemyService.damage(enemy, dmg, { kb = w.knockback, from = from or run.rootPos })
end

function Common.newProjectile(part: BasePart, pos: Vector3, dir: Vector3, life: number, pierce: number, radius: number): Projectile
	return {
		part = part,
		pos = Common.flat(pos),
		dir = dir,
		life = life,
		pierce = pierce,
		radius = radius,
		hit = {},
		t = 0,
		target = nil,
		spin = 0,
	}
end

-- Acerta quem o projetil esta tocando (uma vez por inimigo), gastando perfuracao.
function Common.sweep(run: Runs.Run, p: Projectile, w: any)
	if p.pierce == 0 then
		return
	end
	EnemyService.forEachInRadius(run, p.pos, p.radius, function(enemy)
		if p.pierce == 0 or p.hit[enemy] then
			return
		end
		p.hit[enemy] = true
		Common.hit(run, enemy, w, p.pos - p.dir)
		if p.pierce > 0 then
			p.pierce -= 1
		end
	end)
end

function Common.alive(p: Projectile): boolean
	return p.life > 0 and p.pierce ~= 0
end

-- Atualiza uma lista de projeteis: `step` move cada um; os mortos voltam ao pool.
function Common.stepAll(list: { Projectile }, dt: number, step: (Projectile, number) -> ())
	for i = #list, 1, -1 do
		local p = list[i]
		p.t += dt
		p.life -= dt
		step(p, dt)
		if not Common.alive(p) then
			FxPool.put(p.part)
			local last = #list
			list[i] = list[last]
			list[last] = nil
		end
	end
end

function Common.releaseAll(list: { Projectile }?)
	if not list then
		return
	end
	for _, p in list do
		FxPool.put(p.part)
	end
	table.clear(list)
end

return Common
