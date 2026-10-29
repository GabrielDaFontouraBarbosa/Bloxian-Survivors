--!strict
-- Registro das runs ativas (uma por jogador) e o formato de uma run.
-- A run e o "estado da partida" que todos os servicos leem e escrevem. Cada
-- servico guarda o seu estado interno em run.data.<servico> (inimigos, gemas...).
local Runs = {}

export type WeaponSlot = {
	id: string,
	def: any, -- entrada de Config.Weapons
	level: number,
	cd: number, -- s ate o proximo ataque
	state: any, -- estado do comportamento (projeteis ativos etc.)
}

export type PassiveSlot = {
	id: string,
	def: any, -- entrada de Config.Passives
	level: number,
}

export type Run = {
	id: number,
	player: Player,
	-- escolhas
	classId: string,
	class: any,
	stageId: string,
	stage: any,
	arcanaId: string,
	arcana: any,
	adventureId: string?,
	chapterIndex: number?,
	mods: { [string]: any }, -- regras do capitulo de aventura (ou {})
	duration: number, -- s ate a Ceifadora
	unlocked: { [string]: { [string]: boolean } }, -- armas/passivas liberadas (foto do inicio)
	-- tempo e estado
	time: number,
	minute: number,
	paused: boolean,
	pauses: { [string]: boolean }, -- motivos de pausa ("levelup", "chest")
	ending: boolean,
	completed: boolean, -- chegou ate a Ceifadora
	reaperSpawned: boolean,
	-- arena
	slot: number,
	floorY: number,
	floor: BasePart?,
	root: BasePart?, -- HumanoidRootPart (atualizado todo frame)
	rootPos: Vector3,
	facing: Vector3, -- direcao para onde o jogador olha (plano XZ)
	-- combate do jogador
	hp: number,
	maxHp: number,
	revivals: number,
	revivalGranted: number,
	invulnUntil: number,
	frozenUntil: number,
	-- progresso
	level: number,
	xp: number,
	pendingLevels: number,
	offering: { any }?,
	rerolls: number,
	skips: number,
	weapons: { WeaponSlot },
	passives: { PassiveSlot },
	evolvedFrom: { [string]: boolean }, -- armas base que ja evoluiram (saem do sorteio)
	bonus: { [string]: number }, -- bonus fixos: classe + PowerUps + arcano + aventura
	stats: { [string]: number }, -- stats finais (Stats.recompute)
	-- contadores (resultado e conquistas)
	kills: number,
	gold: number,
	chests: number,
	bossKills: number,
	newAchievements: { string },
	-- estado interno dos servicos
	data: { [string]: any },
	lastSync: number,
}

local active: { [Player]: Run } = {}
local nextId = 0

function Runs.newId(): number
	nextId += 1
	return nextId
end

function Runs.get(player: Player): Run?
	return active[player]
end

function Runs.add(run: Run)
	active[run.player] = run
end

function Runs.remove(player: Player)
	active[player] = nil
end

-- Iteravel { [Player]: Run } com todas as runs ativas.
function Runs.all(): { [Player]: Run }
	return active
end

-- Liga/desliga um motivo de pausa. A run fica pausada enquanto houver algum.
function Runs.setPause(run: Run, reason: string, on: boolean)
	run.pauses[reason] = if on then true else nil
	run.paused = next(run.pauses) ~= nil
end

return Runs
