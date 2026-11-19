-- Spawner: the conveyor belt parade.
--
-- Brainrots spawn at the west end of the belt and waddle east along it.
-- Each carries a ProximityPrompt: walk up and hold E to catch it. The
-- server checks the price, takes the money, and walks the brainrot to a
-- free slot on the catcher's base, where it starts earning.
-- A lure from the shop forces the next parade to be a chosen rarity.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local State = require(script.Parent:WaitForChild("State"))

local Spawner = {}

local active = {} -- model -> { entry, prompt, connection }
local forcedRarity = nil
local spawnTimer = 0

local function beltSpeed(st)
	-- The fastest belt upgrade among online players sets the parade pace.
	local best = 0
	for _, s in pairs(State.all()) do
		best = math.max(best, s.upgrades.belt)
	end
	return BrainrotData.CONVEYOR_SPEED * (1 + 0.15 * best)
end

function Spawner.forceNext(rarity)
	forcedRarity = rarity
end

local function pickForSpawn()
	if forcedRarity then
		local want = forcedRarity
		forcedRarity = nil
		local pool = {}
		for _, b in ipairs(BrainrotData.CAST) do
			if b.rarity == want then
				table.insert(pool, b)
			end
		end
		if #pool > 0 then
			return pool[math.random(1, #pool)]
		end
	end
	return BrainrotData.rollSpawn()
end

local function placeOnBase(player, st, entry, model)
	local slot = State.freeSlot(st)
	if slot == nil then
		return false
	end
	table.insert(st.brainrots, { id = entry.id, mutation = entry.mutation, slot = slot })
	st.catches += 1
	-- Tag the model with its owner so rebirth cleanup and the seagull
	-- can find exactly this player's brainrots.
	model:SetAttribute("Owner", player.UserId)
	local target = WorldBuilder.slotPosition(st.baseIndex, slot)
	-- The pivot is the body, which stands 1.6 studs above the slot pad.
	local bodyTarget = target + Vector3.new(0, 1.6, 0)
	-- Walk it over in a little hop: two short pivots read as a waddle.
	local start = model:GetPivot().Position
	local mid = (start + bodyTarget) / 2 + Vector3.new(0, 3, 0)
	model:PivotTo(CFrame.new(mid))
	task.wait(0.35)
	model:PivotTo(CFrame.new(bodyTarget))
	-- Face the plaza.
	model:PivotTo(CFrame.new(bodyTarget) * CFrame.Angles(0, math.pi, 0))
	return true
end

local function attachPrompt(model, def, entry, onCatch)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Catch!"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		onCatch(player)
	end)
	return prompt
end

function Spawner.spawnOne()
	local def = pickForSpawn()
	local mutation = BrainrotData.rollMutation()
	local entry = { id = def.id, mutation = mutation.name }
	local start = Vector3.new(BrainrotData.CONVEYOR_FROM_X, 1, BrainrotData.CONVEYOR_Z)
	local model = WorldBuilder.buildBrainrot(entry, start)
	if not model then
		return
	end
	-- The price tag lives on the prompt, so the player sees the cost.
	local prompt
	local caught = false
	prompt = attachPrompt(model, def, entry, function(player)
		if caught then
			return
		end
		local st = State.get(player)
		if not st then
			return
		end
		if State.freeSlot(st) == nil then
			Spawner.announce(player, "Your base is full! Buy Bigger Base in the shop.")
			return
		end
		if not State.spend(st, def.cost) then
			Spawner.announce(player, string.format("You need $%d to catch %s!", def.cost, def.name))
			return
		end
		caught = true
		prompt.Enabled = false
		active[model] = nil
		local ok = placeOnBase(player, st, entry, model)
		if not ok then
			State.earn(st, def.cost) -- refund: no slot after all
			model:Destroy()
			return
		end
		Spawner.onCaught(player, def, entry)
	end)
	model.Parent = workspace
	active[model] = { entry = entry, prompt = prompt, x = BrainrotData.CONVEYOR_FROM_X }
end

-- Hooks the GameServer wires up: a toast for one player, and the sound +
-- state push after a catch. Assigned here so this module stays testable.
Spawner.announce = function(_player, _text) end
Spawner.onCaught = function(_player, _def, _entry) end

-- Advance the parade one tick: every live brainrot waddles east, and a
-- new one spawns on the timer. Returns nothing; run it in a loop.
function Spawner.tick(dt)
	spawnTimer -= dt
	if spawnTimer <= 0 then
		Spawner.spawnOne()
		spawnTimer = BrainrotData.SPAWN_INTERVAL
	end
	local speed = beltSpeed()
	for model, info in pairs(active) do
		if not model.Parent then
			active[model] = nil
		else
			info.x += speed * dt
			if info.x >= BrainrotData.CONVEYOR_TO_X then
				-- It paraded past everyone and wanders off the east end.
				active[model] = nil
				model:Destroy()
			else
				-- The pivot is the body, 1.6 studs above the belt's top.
				local bob = math.sin(os.clock() * 6 + info.x) * 0.15
				model:PivotTo(CFrame.new(info.x, 2.6 + bob, BrainrotData.CONVEYOR_Z))
			end
		end
	end
end

-- How many brainrots are on the belt right now (for the HUD's parade line).
function Spawner.paradeCount()
	local n = 0
	for _ in pairs(active) do
		n += 1
	end
	return n
end

return Spawner
