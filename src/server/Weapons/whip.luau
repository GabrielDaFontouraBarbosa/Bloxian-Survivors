--!strict
-- Chicote: golpe retangular na frente do jogador; golpes pares vao para tras.
-- Evolucao (Acoite Sangrento): critico + cura `lifesteal` por inimigo atingido.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local PlayerHealth = require(script.Parent.Parent.PlayerHealth)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Whip = {}

local MAX_HEALS_PER_SWING = 4

function Whip.shot(run: Runs.Run, slot: Runs.WeaponSlot, w: any, i: number)
	local facing = run.facing
	if i % 2 == 0 then
		facing = -facing
	end
	local len, width = w.length, w.width
	local origin = Common.flat(run.rootPos)
	local center = origin + facing * (len / 2 + 0.5)
	local side = Vector3.new(-facing.Z, 0, facing.X)
	local healed = 0
	EnemyService.forEachInRadius(run, center, len / 2 + width, function(enemy)
		local rel = Vector3.new(enemy.pos.X - center.X, 0, enemy.pos.Z - center.Z)
		if math.abs(rel:Dot(facing)) <= len / 2 + enemy.radius and math.abs(rel:Dot(side)) <= width / 2 + enemy.radius then
			Common.hit(run, enemy, w, origin)
			if w.lifesteal and healed < MAX_HEALS_PER_SWING then
				healed += 1
				PlayerHealth.heal(run, w.lifesteal)
			end
		end
	end)
	local y = Common.fxY(run)
	local here = Vector3.new(center.X, y, center.Z)
	local part = FxPool.get("slash", slot.def.color, Vector3.new(width * 0.45, 0.25, len))
	part.CFrame = CFrame.lookAt(here, here + facing)
	FxPool.flash(part, 0.12)
end

function Whip.release(_run: Runs.Run, _slot: Runs.WeaponSlot)
	-- golpes somem sozinhos (FxPool.flash)
end

return Whip
