--!strict
-- Alho: aura permanente em volta do jogador; a cada recarga fere e empurra
-- todo mundo dentro do raio. Evolucao (Devorador de Almas): cura `healPerHit`
-- por inimigo atingido, ate `healCap` por pulso.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local PlayerHealth = require(script.Parent.Parent.PlayerHealth)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Aura = {}

function Aura.fire(run: Runs.Run, _slot: Runs.WeaponSlot, w: any)
	local center = Common.flat(run.rootPos)
	local healed = 0
	EnemyService.forEachInRadius(run, center, w.radius, function(enemy)
		Common.hit(run, enemy, w, center)
		if w.healPerHit and healed < (w.healCap or 2) then
			healed += w.healPerHit
			PlayerHealth.heal(run, w.healPerHit)
		end
	end)
end

function Aura.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, _dt: number)
	local st = slot.state
	local d = w.radius * 2
	local disc = st.disc
	if not disc then
		disc = FxPool.get("disc", slot.def.color, Vector3.new(0.3, d, d))
		st.disc = disc
	elseif disc.Size.Y ~= d then
		disc.Size = Vector3.new(0.3, d, d)
	end
	-- cilindro deitado: o eixo (X) vira vertical
	disc.CFrame = CFrame.new(run.rootPos.X, run.floorY + 0.3, run.rootPos.Z) * CFrame.Angles(0, 0, math.rad(90))
end

function Aura.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	local st = slot.state
	if st and st.disc then
		FxPool.put(st.disc)
		st.disc = nil
	end
end

return Aura
