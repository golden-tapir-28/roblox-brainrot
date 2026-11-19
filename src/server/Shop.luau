-- Shop: everything the player buys, and the base lock and rebirth.
--
-- Every purchase arrives as a RemoteFunction call from the client. The
-- server re-checks the price, the level cap and the cooldown before it
-- takes a single dollar, and answers { ok = true } or { ok = false,
-- reason = "..." } so the client can say why a purchase failed.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local State = require(script.Parent:WaitForChild("State"))
local Spawner = require(script.Parent:WaitForChild("Spawner"))

local Shop = {}

-- Hooks the GameServer wires up.
Shop.onPurchase = function(_player, _label) end

function Shop.buyLure(player, lureId)
	local st = State.get(player)
	if not st then
		return { ok = false, reason = "No game state yet." }
	end
	local lure = nil
	for _, l in ipairs(BrainrotData.LURES) do
		if l.id == lureId then
			lure = l
			break
		end
	end
	if not lure then
		return { ok = false, reason = "Unknown lure." }
	end
	if not State.spend(st, lure.cost) then
		return { ok = false, reason = string.format("You need $%d for a %s.", lure.cost, lure.label) }
	end
	Spawner.forceNext(lure.rarity)
	Shop.onPurchase(player, lure.label .. " bought!")
	return { ok = true }
end

function Shop.buyUpgrade(player, upgradeId)
	local st = State.get(player)
	if not st then
		return { ok = false, reason = "No game state yet." }
	end
	local def = nil
	for _, u in ipairs(BrainrotData.UPGRADES) do
		if u.id == upgradeId then
			def = u
			break
		end
	end
	if not def then
		return { ok = false, reason = "Unknown upgrade." }
	end
	local level = st.upgrades[upgradeId]
	if level >= def.maxLevel then
		return { ok = false, reason = def.label .. " is already maxed out." }
	end
	local cost = BrainrotData.upgradeCost(def, level + 1)
	if not State.spend(st, cost) then
		return { ok = false, reason = string.format("You need $%d for %s.", cost, def.label) }
	end
	st.upgrades[upgradeId] = level + 1
	Shop.onPurchase(player, def.label .. " level " .. (level + 1) .. "!")
	return { ok = true, level = level + 1 }
end

function Shop.lockBase(player)
	local st = State.get(player)
	if not st then
		return { ok = false, reason = "No game state yet." }
	end
	if State.isLocked(st) then
		return { ok = false, reason = "Your base is already locked." }
	end
	if not State.lockReady(st) then
		return { ok = false, reason = "The lock is recharging. Try again soon." }
	end
	State.lockBase(st)
	Shop.onPurchase(player, "Base locked for 30 seconds! The seagull can't touch it.")
	return { ok = true }
end

function Shop.rebirth(player)
	local st = State.get(player)
	if not st then
		return { ok = false, reason = "No game state yet." }
	end
	local cost = BrainrotData.rebirthCost(st.rebirths)
	if st.money < cost then
		return { ok = false, reason = string.format("Rebirth costs $%d. Keep earning!", cost) }
	end
	if #st.brainrots < 3 then
		return { ok = false, reason = "Catch at least 3 brainrots before you rebirth." }
	end
	-- Clear the brainrots' models off the base before the state resets.
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") then
			local owner = model:GetAttribute("Owner")
			if owner == player.UserId then
				model:Destroy()
			end
		end
	end
	State.applyRebirth(st)
	Shop.onPurchase(player, string.format("REBIRTH #%d! All earnings x%.1f forever.", st.rebirths, BrainrotData.rebirthMult(st.rebirths)))
	return { ok = true, rebirths = st.rebirths }
end

return Shop
