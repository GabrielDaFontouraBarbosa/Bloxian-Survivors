--!strict
-- Barramento de eventos do servidor: quem produz avisa, quem se interessa escuta.
-- Evita require circular entre servicos (ex.: inimigo morre -> gema, ouro, conquista).
-- Um handler com erro nao derruba os outros (pcall + warn).
--
-- Eventos usados:
--   RunStarted(run)                       RunEnded(run, reason, results)
--   EnemyKilled(run, enemy)               MinuteReached(run, minute)
--   LevelReached(run, level)              StageCompleted(run)
--   WeaponMaxed(run, weaponId)            WeaponEvolved(run, fromId, toId)
--   ChestOpened(run)                      PickupCollected(run, pickupId)
--   PlayerDowned(run)                     PlayerRevived(run)
--   AdventureChapterDone(player, adventureId, chapter)
local Events = {}

local handlers: { [string]: { (...any) -> () } } = {}

function Events.on(name: string, fn: (...any) -> ())
	local list = handlers[name]
	if not list then
		list = {}
		handlers[name] = list
	end
	table.insert(list, fn)
end

function Events.emit(name: string, ...: any)
	local list = handlers[name]
	if not list then
		return
	end
	for _, fn in list do
		local ok, err = pcall(fn, ...)
		if not ok then
			warn(("[Survivors] erro no evento %s: %s"):format(name, tostring(err)))
		end
	end
end

return Events
