-- GameServer: Brainrot Bay's server entry point.
--
-- One job: wire the modules together. State holds the numbers, Spawner
-- runs the conveyor, Hazard runs the seagull and the rain, Shop checks
-- every purchase, and this script ticks the economy, hands the client its
-- state, and keeps the leaderstats honest.
-- Money ticks once a second on the server: income per second times the
-- weather multiplier, pushed to the client twice a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local State = require(script.Parent:WaitForChild("State"))
local Spawner = require(script.Parent:WaitForChild("Spawner"))
local Hazard = require(script.Parent:WaitForChild("Hazard"))
local Shop = require(script.Parent:WaitForChild("Shop"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

-- Remotes live in ReplicatedStorage so client and server both find them.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "StateUpdate"
stateEvent.Parent = remotes

local toastEvent = Instance.new("RemoteEvent")
toastEvent.Name = "Toast"
toastEvent.Parent = remotes

local soundEvent = Instance.new("RemoteEvent")
soundEvent.Name = "PlaySound"
soundEvent.Parent = remotes

local shopFunction = Instance.new("RemoteFunction")
shopFunction.Name = "ShopAction"
shopFunction.Parent = remotes

local function pushState(player)
	local snap = State.snapshot(player)
	if snap then
		snap.rainActive = Hazard.rainActive
		snap.parade = Spawner.paradeCount()
		stateEvent:FireClient(player, snap)
	end
end

local function pushAll()
	for player in pairs(State.all()) do
		pushState(player)
	end
end

local function toast(player, text)
	toastEvent:FireClient(player, text)
end

local function toastAll(text)
	toastEvent:FireAllClients(text)
end

local function playSound(player, name)
	soundEvent:FireClient(player, name)
end

-- Spawner and Hazard hooks: toasts, sounds and state pushes.
Spawner.announce = function(player, text)
	toast(player, text)
	playSound(player, "error")
end
Spawner.onCaught = function(player, def, entry)
	toast(player, string.format("Caught %s! It now earns $%d/s on your base.", def.name, BrainrotData.baseRate(entry)))
	playSound(player, "coin")
	pushState(player)
end
Hazard.announceAll = function(text)
	toastAll(text)
end
Hazard.onSteal = function(player, entry)
	local def = BrainrotData.byId(entry.id)
	if def then
		toast(player, "The seagull stole your " .. def.name .. "!")
	end
	playSound(player, "alarm")
	pushState(player)
end
Hazard.onSaved = function(player, entry)
	local def = BrainrotData.byId(entry.id)
	if def then
		toast(player, "You saved your " .. def.name .. " from the seagull!")
	end
	playSound(player, "coin")
end
Hazard.onRainStart = function()
	for player in pairs(State.all()) do
		playSound(player, "rain")
	end
	pushAll()
end
Hazard.onRainEnd = function()
	pushAll()
end
Shop.onPurchase = function(player, label)
	toast(player, label)
	playSound(player, "coin")
	pushState(player)
end

-- The shop's single door: one RemoteFunction, one action name, server-checked.
shopFunction.OnServerInvoke = function(player, action, arg)
	if action == "buyLure" then
		return Shop.buyLure(player, arg)
	elseif action == "buyUpgrade" then
		return Shop.buyUpgrade(player, arg)
	elseif action == "lockBase" then
		return Shop.lockBase(player)
	elseif action == "rebirth" then
		return Shop.rebirth(player)
	elseif action == "state" then
		return State.snapshot(player)
	end
	return { ok = false, reason = "Unknown action." }
end

-- A player's arrival: state, leaderstats, a base sign, a welcome toast.
local function onPlayerAdded(player)
	local st = State.addPlayer(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = math.floor(st.money)
	moneyValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = st.rebirths
	rebirthValue.Parent = leaderstats

	WorldBuilder.buildBaseSign(st.baseIndex, player.DisplayName, 0)
	pushState(player)
	task.delay(2, function()
		if player.Parent then
			toast(player, "Welcome to Brainrot Bay! Catch brainrots off the conveyor (hold E) and they earn money on your base.")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- The economy tick: once a second, every brainrot pays its owner.
local economyAcc = 0
local pushAcc = 0
RunService.Heartbeat:Connect(function(dt)
	economyAcc += dt
	pushAcc += dt
	Spawner.tick(dt)
	if economyAcc >= 1 then
		economyAcc = 0
		local weather = Hazard.weatherMult()
		for player, st in pairs(State.all()) do
			local income = State.incomePerSecond(st) * weather
			if income > 0 then
				State.earn(st, income)
			end
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local moneyValue = leaderstats:FindFirstChild("Money")
				if moneyValue then
					moneyValue.Value = math.floor(st.money)
				end
				local rebirthValue = leaderstats:FindFirstChild("Rebirths")
				if rebirthValue then
					rebirthValue.Value = st.rebirths
				end
			end
		end
	end
	if pushAcc >= 0.5 then
		pushAcc = 0
		pushAll()
	end
end)

-- Base signs show live income; refresh them every few seconds.
task.spawn(function()
	while true do
		task.wait(3)
		for player, st in pairs(State.all()) do
			local center = WorldBuilder.plotPosition(st.baseIndex)
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("TextLabel") and descendant.Name == "Income" then
					local signPart = descendant:FindFirstAncestorOfClass("Part")
					if signPart and (signPart.Position - (center + Vector3.new(0, 9, 0))).Magnitude < 1 then
						descendant.Text = string.format("$%d/s", math.floor(State.incomePerSecond(st) + 0.5))
					end
				end
			end
		end
	end
end)

Hazard.start()

WorldBuilder.buildWorldSigns()

print("Brainrot Bay is open: catch brainrots, guard your base, mind the seagull.")
