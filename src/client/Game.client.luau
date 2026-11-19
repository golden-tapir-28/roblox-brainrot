-- Game.client: Brainrot Bay's client entry point.
--
-- One job: wire the HUD to the server. The server pushes state twice a
-- second (money, income, lock, rain, stats); this script shows it, and
-- sends the player's choices back through one RemoteFunction: buy a lure,
-- buy an upgrade, lock the base, rebirth. Sounds play here, on the
-- client, when the server asks for them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local stateEvent = remotes:WaitForChild("StateUpdate")
local toastEvent = remotes:WaitForChild("Toast")
local soundEvent = remotes:WaitForChild("PlaySound")
local shopFunction = remotes:WaitForChild("ShopAction")

local hud

local function callShop(action, arg)
	local result = nil
	local ok = pcall(function()
		result = shopFunction:InvokeServer(action, arg)
	end)
	if not ok or not result then
		hud.toast("The shop didn't answer. Try again.")
		return
	end
	if result.ok == false and result.reason then
		hud.toast(result.reason)
		Sounds.play("error")
	end
end

hud = Hud.build({
	click = function()
		Sounds.play("click")
	end,
	buyLure = function(lureId)
		Sounds.play("click")
		callShop("buyLure", lureId)
	end,
	buyUpgrade = function(upgradeId)
		Sounds.play("click")
		callShop("buyUpgrade", upgradeId)
	end,
	lockBase = function()
		Sounds.play("click")
		callShop("lockBase")
	end,
	rebirth = function()
		Sounds.play("click")
		callShop("rebirth")
	end,
})

stateEvent.OnClientEvent:Connect(function(snap)
	if not snap then
		return
	end
	hud.setMoney(snap.money, snap.incomePerSecond)
	hud.setRain(snap.rainActive)
	hud.setLock(snap.locked, snap.lockReadyIn)
	hud.setRebirth(BrainrotData.rebirthCost(snap.rebirths), snap.rebirths)
	local slotsMax = BrainrotData.BASE_SLOTS + snap.upgrades.slots * BrainrotData.SLOT_BONUS
	hud.setStats(snap.catches, snap.totalEarned, snap.rebirths, #snap.brainrots, slotsMax)
end)

toastEvent.OnClientEvent:Connect(function(text)
	hud.toast(text)
end)

soundEvent.OnClientEvent:Connect(function(name)
	Sounds.play(name)
end)

-- Ask for the first state right away, instead of waiting for the push.
task.spawn(function()
	local snap = nil
	local ok = pcall(function()
		snap = shopFunction:InvokeServer("state")
	end)
	if ok and snap then
		hud.setMoney(snap.money, snap.incomePerSecond)
		hud.setRain(false)
		hud.setLock(snap.locked, snap.lockReadyIn)
		hud.setRebirth(BrainrotData.rebirthCost(snap.rebirths), snap.rebirths)
		local slotsMax = BrainrotData.BASE_SLOTS + snap.upgrades.slots * BrainrotData.SLOT_BONUS
		hud.setStats(snap.catches, snap.totalEarned, snap.rebirths, #snap.brainrots, slotsMax)
	end
end)

print("Brainrot Bay client is ready.")
