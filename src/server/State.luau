-- State: every player's game state, kept in one place.
--
-- The server owns all numbers. The client only displays what the server
-- sends it and asks for actions (buy, lock, rebirth) through remotes; the
-- server re-checks every price before it takes money, so a tampered client
-- cannot grant itself anything.
--
-- A player's state:
--   money        number, spendable cash
--   totalEarned  number, lifetime earnings (for the stats line)
--   brainrots    array of { id, mutation, slot } standing on their base
--   baseIndex    number, which of the eight plots is theirs
--   upgrades     { slots = level, feed = level, belt = level }
--   rebirths     number, how many times they rebirthed
--   lockUntil    number, os.clock() until which their base is locked
--   lockReadyAt  number, os.clock() when the lock button is usable again
--   catches      number, brainrots caught (for the stats line)

local Players = game:GetService("Players")

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local State = {}

local players = {}

local function freshState(baseIndex)
	return {
		money = 250,
		totalEarned = 0,
		brainrots = {},
		baseIndex = baseIndex,
		upgrades = { slots = 0, feed = 0, belt = 0 },
		rebirths = 0,
		lockUntil = 0,
		lockReadyAt = 0,
		catches = 0,
	}
end

-- The eight plots are handed out in join order; a plot frees up when its
-- owner leaves, so a late joiner reuses it.
local takenPlots = {}

function State.addPlayer(player)
	local baseIndex = nil
	for i = 0, 7 do
		if not takenPlots[i] then
			baseIndex = i
			break
		end
	end
	if baseIndex == nil then
		baseIndex = math.random(0, 7)
	end
	takenPlots[baseIndex] = player
	players[player] = freshState(baseIndex)
	return players[player]
end

function State.removePlayer(player)
	local st = players[player]
	if st then
		takenPlots[st.baseIndex] = nil
	end
	players[player] = nil
end

function State.get(player)
	return players[player]
end

function State.all()
	return players
end

function State.playerCount()
	local n = 0
	for _ in pairs(players) do
		n += 1
	end
	return n
end

-- How many brainrots a base can hold: six, plus two per Bigger Base level.
function State.maxSlots(st)
	return BrainrotData.BASE_SLOTS + st.upgrades.slots * BrainrotData.SLOT_BONUS
end

-- The first free slot number on a base, or nil when it is full.
function State.freeSlot(st)
	local used = {}
	for _, b in ipairs(st.brainrots) do
		used[b.slot] = true
	end
	for slot = 0, State.maxSlots(st) - 1 do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- The earn multiplier of one player: feed upgrades and rebirths.
function State.earnMult(st)
	return (1 + 0.25 * st.upgrades.feed) * BrainrotData.rebirthMult(st.rebirths)
end

-- Money per second of one player, before the Noodle Rain multiplier.
function State.incomePerSecond(st)
	local total = 0
	for _, b in ipairs(st.brainrots) do
		total += BrainrotData.baseRate(b)
	end
	return total * State.earnMult(st)
end

-- Add money and count it toward lifetime earnings.
function State.earn(st, amount)
	st.money += amount
	st.totalEarned += amount
end

-- Take money when the player can afford it. Returns true on success.
function State.spend(st, amount)
	if st.money < amount then
		return false
	end
	st.money -= amount
	return true
end

-- Is this base locked right now (the seagull cannot touch it)?
function State.isLocked(st)
	return os.clock() < st.lockUntil
end

-- Is the lock button ready to press again?
function State.lockReady(st)
	return os.clock() >= st.lockReadyAt
end

function State.lockBase(st)
	st.lockUntil = os.clock() + BrainrotData.LOCK_DURATION
	st.lockReadyAt = os.clock() + BrainrotData.LOCK_COOLDOWN
end

-- Reset for a rebirth: money and brainrots go, the multiplier stays.
function State.applyRebirth(st)
	st.money = 250
	st.brainrots = {}
	st.rebirths += 1
end

-- A small, safe snapshot for the client: no functions, no instances.
function State.snapshot(player)
	local st = players[player]
	if not st then
		return nil
	end
	local brains = {}
	for _, b in ipairs(st.brainrots) do
		table.insert(brains, { id = b.id, mutation = b.mutation, slot = b.slot })
	end
	return {
		money = math.floor(st.money),
		totalEarned = math.floor(st.totalEarned),
		brainrots = brains,
		baseIndex = st.baseIndex,
		upgrades = {
			slots = st.upgrades.slots,
			feed = st.upgrades.feed,
			belt = st.upgrades.belt,
		},
		rebirths = st.rebirths,
		locked = State.isLocked(st),
		lockReadyIn = math.max(0, math.floor(st.lockReadyAt - os.clock())),
		incomePerSecond = math.floor(State.incomePerSecond(st) + 0.5),
		catches = st.catches,
	}
end

Players.PlayerRemoving:Connect(function(player)
	State.removePlayer(player)
end)

return State
