--!strict
-- Grimorio: `amount` livros giram em volta do jogador por `duration` s a cada
-- recarga. Cada livro acerta o mesmo inimigo no maximo a cada `hitEvery` s.
-- Evolucao (Vesperas Profanas, permanent = true): os livros nunca param.
local Runs = require(script.Parent.Parent.Runs)
local EnemyService = require(script.Parent.Parent.EnemyService)
local FxPool = require(script.Parent.Parent.FxPool)
local Common = require(script.Parent.Common)

local Orbit = {}

local function setBooks(slot: Runs.WeaponSlot, w: any, count: number)
	local st = slot.state
	local books: { BasePart } = st.books or {}
	st.books = books
	while #books > count do
		FxPool.put(table.remove(books) :: BasePart)
	end
	while #books < count do
		local size = w.size
		table.insert(books, FxPool.get("book", slot.def.color, Vector3.new(size, size * 1.3, size * 0.35)))
	end
end

function Orbit.fire(run: Runs.Run, slot: Runs.WeaponSlot, w: any)
	slot.state.activeUntil = run.time + w.duration
end

function Orbit.update(run: Runs.Run, slot: Runs.WeaponSlot, w: any, dt: number)
	local st = slot.state
	local active = w.permanent or (st.activeUntil and run.time < st.activeUntil)
	if not active then
		setBooks(slot, w, 0)
		return
	end
	setBooks(slot, w, w.amount)
	st.angle = (st.angle or 0) + w.spin * dt
	local center = Common.flat(run.rootPos)
	local y = Common.fxY(run)
	local now = os.clock()
	local hitRadius = w.size * 0.7 + 0.3
	for k, book in st.books do
		local a = st.angle + (k - 1) * (math.pi * 2 / w.amount)
		local pos = center + Vector3.new(math.cos(a), 0, math.sin(a)) * w.radius
		if book.Size.X ~= w.size then
			book.Size = Vector3.new(w.size, w.size * 1.3, w.size * 0.35) -- Area subiu
		end
		book.CFrame = CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, -a, 0)
		EnemyService.forEachInRadius(run, pos, hitRadius, function(enemy)
			local ready = enemy.hitCd[slot]
			if ready and now < ready then
				return
			end
			enemy.hitCd[slot] = now + w.hitEvery
			Common.hit(run, enemy, w, center)
		end)
	end
end

function Orbit.release(_run: Runs.Run, slot: Runs.WeaponSlot)
	local st = slot.state
	if st and st.books then
		for _, book in st.books do
			FxPool.put(book)
		end
		st.books = {}
	end
end

return Orbit
