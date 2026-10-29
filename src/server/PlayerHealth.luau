--!strict
-- Vida do jogador na run, decidida no servidor (armadura, recuperacao,
-- ressurreicao) e espelhada no Humanoid so para a barra/morte do Roblox.
-- Quem causa dano chama PlayerHealth.damage; ao zerar sem ressurreicao, avisa
-- PlayerDowned e o RunManager encerra a run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Runs = require(script.Parent.Runs)
local Events = require(script.Parent.Events)

local PlayerHealth = {}

local function humanoidOf(run: Runs.Run): Humanoid?
	local char = run.player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function PlayerHealth.damage(run: Runs.Run, amount: number)
	if run.paused or run.ending or run.hp <= 0 then
		return
	end
	if os.clock() < run.invulnUntil then
		return
	end
	local dmg = math.max(1, amount - run.stats.armor)
	run.hp -= dmg
	if run.hp > 0 then
		return
	end
	if run.revivals > 0 then
		run.revivals -= 1
		run.hp = run.maxHp * Config.Run.ReviveHealthFraction
		run.invulnUntil = os.clock() + Config.Run.ReviveInvuln
		Events.emit("PlayerRevived", run)
		return
	end
	run.hp = 0
	Events.emit("PlayerDowned", run)
end

function PlayerHealth.heal(run: Runs.Run, amount: number)
	if run.hp <= 0 then
		return
	end
	run.hp = math.min(run.maxHp, run.hp + amount)
end

-- Regenera (Recuperacao) e espelha no Humanoid. Roda todo frame, pausado ou nao.
function PlayerHealth.update(run: Runs.Run, dt: number)
	if not run.paused and run.hp > 0 then
		local regen = run.stats.recovery
		if regen > 0 then
			PlayerHealth.heal(run, regen * dt)
		end
	end
	local hum = humanoidOf(run)
	if hum and hum.Health > 0 and run.hp > 0 then
		if hum.MaxHealth ~= run.maxHp then
			hum.MaxHealth = run.maxHp
		end
		if math.abs(hum.Health - run.hp) > 0.05 then
			hum.Health = run.hp
		end
	end
end

return PlayerHealth
