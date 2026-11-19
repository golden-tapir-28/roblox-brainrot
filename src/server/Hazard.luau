-- Hazard: the threats that force a dash home.
--
-- 1. The Greedy Seagull. Every so often it swoops from the sky onto a
--    random occupied base and grabs its most valuable brainrot, then flies
--    for the edge of the map. Touch the seagull to make it drop the catch,
--    or lock your base before it arrives: a locked base is never targeted.
-- 2. Noodle Rain. Every few minutes the sky rains noodles for thirty
--    seconds and every brainrot earns double. It is announced, and the
--    client shows the storm banner while it lasts.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local State = require(script.Parent:WaitForChild("State"))

local Hazard = {}

Hazard.rainActive = false
Hazard.rainEndsAt = 0

-- Hooks the GameServer wires up. Assigned here so this module stays testable.
Hazard.announceAll = function(_text) end
Hazard.onSteal = function(_player, _entry) end
Hazard.onSaved = function(_player, _entry) end
Hazard.onRainStart = function() end
Hazard.onRainEnd = function() end

local function randomTarget()
	-- Pick a random player whose base is unlocked and holds a brainrot.
	local candidates = {}
	for player, st in pairs(State.all()) do
		if #st.brainrots > 0 and not State.isLocked(st) then
			table.insert(candidates, { player = player, st = st })
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

local function richestBrainrot(st)
	local best, bestRate = nil, -1
	for _, b in ipairs(st.brainrots) do
		local rate = BrainrotData.baseRate(b)
		if rate > bestRate then
			best, bestRate = b, rate
		end
	end
	return best
end

local function removeBrainrot(st, entry)
	for i, b in ipairs(st.brainrots) do
		if b == entry then
			table.remove(st.brainrots, i)
			return
		end
	end
end

-- One seagull attack, run as its own task so the main loop never waits.
local function seagullAttack()
	local target = randomTarget()
	if not target then
		return
	end
	local player, st = target.player, target.st
	local entry = richestBrainrot(st)
	if not entry then
		return
	end
	local def = BrainrotData.byId(entry.id)
	local plotPos = WorldBuilder.plotPosition(st.baseIndex)
	local slotPos = WorldBuilder.slotPosition(st.baseIndex, entry.slot)

	-- Find the brainrot's model on the base and lift it off its slot.
	local victim = nil
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model.Name == def.name and model:GetAttribute("Owner") == player.UserId then
			local pivot = model:GetPivot().Position
			if (pivot - (slotPos + Vector3.new(0, 1.6, 0))).Magnitude < 2 then
				victim = model
				break
			end
		end
	end

	local gull = WorldBuilder.buildSeagull(plotPos + Vector3.new(0, 30, 0))
	gull.Parent = workspace
	Hazard.announceAll("The Greedy Seagull is diving for " .. player.Name .. "'s base! Touch it to scare it off!")

	-- Swoop down to the slot.
	local body = gull.PrimaryPart
	local startPos = body.Position
	local diveTarget = slotPos + Vector3.new(0, 4, 0)
	for t = 0, 1, 0.05 do
		if not gull.Parent then
			return
		end
		local pos = startPos:Lerp(diveTarget, t)
		gull:PivotTo(CFrame.new(pos))
		task.wait(0.06)
	end

	-- Grab: the brainrot rides under the seagull now.
	if victim and victim.Parent then
		victim:PivotTo(CFrame.new(body.Position + Vector3.new(0, -2.5, 0)))
	end
	local grabbed = true
	local touchConn
	touchConn = body.Touched:Connect(function(hit)
		if not grabbed then
			return
		end
		local character = hit.Parent
		local toucher = game:GetService("Players"):GetPlayerFromCharacter(character)
		if toucher then
			grabbed = false
			-- Scared off: the brainrot drops back onto its slot.
			if victim and victim.Parent then
				victim:PivotTo(CFrame.new(slotPos + Vector3.new(0, 1.6, 0)))
			end
			Hazard.onSaved(toucher, entry)
			Hazard.announceAll(toucher.Name .. " scared the seagull off! " .. def.name .. " is safe.")
			gull:Destroy()
		end
	end)

	-- Fly for the east edge. If nobody touches it, the catch is gone.
	local escape = Vector3.new(120, 26, 0)
	local escapeStart = body.Position
	for t = 0, 1, 0.02 do
		if not gull.Parent or not grabbed then
			break
		end
		local pos = escapeStart:Lerp(escape, t)
		gull:PivotTo(CFrame.new(pos))
		if victim and victim.Parent then
			victim:PivotTo(CFrame.new(pos + Vector3.new(0, -2.5, 0)))
		end
		task.wait(0.12)
	end
	if touchConn then
		touchConn:Disconnect()
	end
	if grabbed and gull.Parent then
		-- It got away with the brainrot.
		removeBrainrot(st, entry)
		if victim then
			victim:Destroy()
		end
		gull:Destroy()
		Hazard.onSteal(player, entry)
		Hazard.announceAll("The seagull stole " .. def.name .. " from " .. player.Name .. "! Lock your base next time.")
	end
end

-- Noodle Rain: thirty seconds of double earnings, with falling noodles.
local function noodleRain()
	Hazard.rainActive = true
	Hazard.rainEndsAt = os.clock() + BrainrotData.RAIN_DURATION
	Hazard.onRainStart()
	Hazard.announceAll("NOODLE RAIN! Every brainrot earns DOUBLE for 30 seconds!")
	local debris = game:GetService("Debris")
	for _ = 1, 120 do
		if not Hazard.rainActive then
			break
		end
		local noodle = Instance.new("Part")
		noodle.Name = "Noodle"
		noodle.Size = Vector3.new(0.4, 2.5, 0.4)
		noodle.Color = Color3.fromRGB(240, 200, 90)
		noodle.Material = Enum.Material.Neon
		noodle.Anchored = true
		noodle.CanCollide = false
		noodle.Position = Vector3.new(math.random(-90, 90), 45, math.random(-90, 90))
		noodle.Parent = workspace
		debris:AddItem(noodle, 4)
		task.wait(0.25)
	end
	task.wait(math.max(0, Hazard.rainEndsAt - os.clock()))
	Hazard.rainActive = false
	Hazard.onRainEnd()
	Hazard.announceAll("The Noodle Rain has passed. The bay smells of broth.")
end

function Hazard.nextSeagullDelay()
	return math.random(BrainrotData.SEAGULL_MIN_DELAY, BrainrotData.SEAGULL_MAX_DELAY)
end

function Hazard.nextRainDelay()
	return math.random(BrainrotData.RAIN_MIN_DELAY, BrainrotData.RAIN_MAX_DELAY)
end

-- The current earnings multiplier from the weather (1, or 2 in the rain).
function Hazard.weatherMult()
	if Hazard.rainActive then
		return BrainrotData.RAIN_MULT
	end
	return 1
end

-- Start the two hazard loops. Each runs in its own task forever.
function Hazard.start()
	task.spawn(function()
		while true do
			task.wait(Hazard.nextSeagullDelay())
			local ok, err = pcall(seagullAttack)
			if not ok then
				warn("Seagull attack failed: " .. tostring(err))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Hazard.nextRainDelay())
			local ok, err = pcall(noodleRain)
			if not ok then
				warn("Noodle Rain failed: " .. tostring(err))
			end
		end
	end)
end

return Hazard
