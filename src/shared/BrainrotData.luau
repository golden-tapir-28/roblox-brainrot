-- BrainrotData: the whole cast of Brainrot Bay, in one place.
--
-- Every brainrot is an original, absurd character of this game's own: a
-- pickle in a top hat, a toast with a captain's hat, a spaghetti baron.
-- Nothing here copies Steal a Brainrot's characters or names.
-- Both the server (spawning, prices, earnings) and the client (shop list,
-- labels) read this module, so a number changed here changes everywhere.

local BrainrotData = {}

-- Rarity ladder, cheapest first. `mult` multiplies the brainrot's base
-- money-per-second; `color` is the label colour the UI shows.
BrainrotData.RARITIES = {
	{ name = "Common", mult = 1, color = Color3.fromRGB(200, 200, 200) },
	{ name = "Uncommon", mult = 2, color = Color3.fromRGB(120, 220, 120) },
	{ name = "Rare", mult = 4, color = Color3.fromRGB(90, 160, 255) },
	{ name = "Epic", mult = 8, color = Color3.fromRGB(180, 110, 250) },
	{ name = "Legendary", mult = 16, color = Color3.fromRGB(255, 200, 60) },
	{ name = "Mythic", mult = 32, color = Color3.fromRGB(255, 90, 160) },
	{ name = "Secret", mult = 64, color = Color3.fromRGB(90, 230, 230) },
}

function BrainrotData.rarityIndex(name)
	for i, r in ipairs(BrainrotData.RARITIES) do
		if r.name == name then
			return i
		end
	end
	return 1
end

function BrainrotData.rarityColor(name)
	for _, r in ipairs(BrainrotData.RARITIES) do
		if r.name == name then
			return r.color
		end
	end
	return Color3.fromRGB(200, 200, 200)
end

-- Mutations roll when a brainrot spawns. `mult` multiplies its earnings.
-- A mutation is shown in the label as a coloured prefix, e.g. "GOLDEN".
BrainrotData.MUTATIONS = {
	{ name = "None", mult = 1, chance = 0.60, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Frozen", mult = 1.5, chance = 0.18, color = Color3.fromRGB(150, 220, 255) },
	{ name = "Golden", mult = 2, chance = 0.12, color = Color3.fromRGB(255, 210, 60) },
	{ name = "Diamond", mult = 4, chance = 0.07, color = Color3.fromRGB(170, 240, 255) },
	{ name = "Rainbow", mult = 8, chance = 0.025, color = Color3.fromRGB(255, 120, 220) },
	{ name = "Void", mult = 12, chance = 0.005, color = Color3.fromRGB(120, 60, 200) },
}

function BrainrotData.rollMutation()
	local roll = math.random()
	local acc = 0
	for _, m in ipairs(BrainrotData.MUTATIONS) do
		acc += m.chance
		if roll <= acc then
			return m
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- The cast. `body` is the shape of the model's main part ("Block" or
-- "Ball"), `color` its body colour, `hat` the accessory on top ("TopHat",
-- "Crown", "Cap", "Wizard", "None"), `quirk` is the joke the label shows.
-- `cost` is what the player pays to catch it off the conveyor; `rate` is
-- its base money per second before rarity, mutation and rebirth multipliers.
BrainrotData.CAST = {
	{
		id = "picklefin",
		name = "Sir Reginald Picklefin",
		rarity = "Common",
		cost = 50,
		rate = 2,
		body = "Block",
		color = Color3.fromRGB(90, 160, 60),
		hat = "TopHat",
		quirk = "A pickle with a title and no manners.",
	},
	{
		id = "wobbletoast",
		name = "Captain Wobbletoast",
		rarity = "Common",
		cost = 150,
		rate = 5,
		body = "Block",
		color = Color3.fromRGB(230, 190, 120),
		hat = "Cap",
		quirk = "Sails the butter seas. Always slightly burnt.",
	},
	{
		id = "spaghetti",
		name = "Baron von Spaghetti",
		rarity = "Uncommon",
		cost = 500,
		rate = 12,
		body = "Ball",
		color = Color3.fromRGB(240, 200, 90),
		hat = "Wizard",
		quirk = "Twirls his own moustache. It is also pasta.",
	},
	{
		id = "mooncheese",
		name = "Duchess Mooncheese",
		rarity = "Uncommon",
		cost = 1200,
		rate = 25,
		body = "Ball",
		color = Color3.fromRGB(250, 230, 130),
		hat = "Crown",
		quirk = "Rules the moon. The moon is cheese. Obviously.",
	},
	{
		id = "quackers",
		name = "Professor Quackers",
		rarity = "Rare",
		cost = 3500,
		rate = 55,
		body = "Block",
		color = Color3.fromRGB(250, 220, 60),
		hat = "Wizard",
		quirk = "Has a PhD in puddles. Quacks in Latin.",
	},
	{
		id = "biscuitbottom",
		name = "Lord Biscuitbottom",
		rarity = "Rare",
		cost = 8000,
		rate = 110,
		body = "Block",
		color = Color3.fromRGB(190, 130, 70),
		hat = "TopHat",
		quirk = "Dunks himself in tea. On purpose. Every time.",
	},
	{
		id = "noodler",
		name = "The Grand Noodler",
		rarity = "Epic",
		cost = 20000,
		rate = 240,
		body = "Ball",
		color = Color3.fromRGB(240, 170, 60),
		hat = "Wizard",
		quirk = "Can see your future. It is also noodles.",
	},
	{
		id = "bananaphone",
		name = "Sir Bananaphone",
		rarity = "Epic",
		cost = 45000,
		rate = 500,
		body = "Block",
		color = Color3.fromRGB(250, 230, 40),
		hat = "Cap",
		quirk = "Rings. You answer. It is a banana.",
	},
	{
		id = "soggycereal",
		name = "Emperor Soggy Cereal",
		rarity = "Legendary",
		cost = 120000,
		rate = 1100,
		body = "Ball",
		color = Color3.fromRGB(220, 150, 180),
		hat = "Crown",
		quirk = "Once crunchy. Now rules the milk ocean.",
	},
	{
		id = "voidsponge",
		name = "Void Sponge",
		rarity = "Legendary",
		cost = 300000,
		rate = 2400,
		body = "Block",
		color = Color3.fromRGB(90, 60, 160),
		hat = "None",
		quirk = "Absorbs light, sound, and your savings.",
	},
	{
		id = "galactictoaster",
		name = "Galactic Toaster",
		rarity = "Mythic",
		cost = 800000,
		rate = 5500,
		body = "Block",
		color = Color3.fromRGB(180, 190, 210),
		hat = "Crown",
		quirk = "Toasted a star once. It was delicious.",
	},
	{
		id = "chairmanmeow",
		name = "Chairman Meow",
		rarity = "Secret",
		cost = 2500000,
		rate = 15000,
		body = "Ball",
		color = Color3.fromRGB(255, 160, 60),
		hat = "TopHat",
		quirk = "The rarest cat in the bay. Do not pet the chairman.",
	},
	{
		id = "butterbean",
		name = "Baroness Butterbean",
		rarity = "Uncommon",
		cost = 800,
		rate = 18,
		body = "Ball",
		color = Color3.fromRGB(245, 215, 110),
		hat = "Cap",
		quirk = "Melts on warm toast. Prefers it that way.",
	},
	{
		id = "crumpet",
		name = "Sir Crumpet McFluff",
		rarity = "Rare",
		cost = 5500,
		rate = 80,
		body = "Block",
		color = Color3.fromRGB(200, 150, 90),
		hat = "TopHat",
		quirk = "Fluffiest knight in the bay. Butter is his shield.",
	},
	{
		id = "croissant",
		name = "Madame Croissant",
		rarity = "Epic",
		cost = 32000,
		rate = 360,
		body = "Ball",
		color = Color3.fromRGB(235, 180, 80),
		hat = "Crown",
		quirk = "Flaky, fabulous, and always fashionably late.",
	},
	{
		id = "donutduke",
		name = "Duke of Donut",
		rarity = "Legendary",
		cost = 200000,
		rate = 1700,
		body = "Ball",
		color = Color3.fromRGB(240, 140, 180),
		hat = "Crown",
		quirk = "Sprinkles for a crown. Glaze for a throne.",
	},
	{
		id = "pretzel",
		name = "The Infinite Pretzel",
		rarity = "Mythic",
		cost = 1500000,
		rate = 9000,
		body = "Block",
		color = Color3.fromRGB(170, 120, 60),
		hat = "Wizard",
		quirk = "Twisted beyond time. Still salty about it.",
	},
	{
		id = "jellybean",
		name = "Empress Jellybean",
		rarity = "Secret",
		cost = 5000000,
		rate = 26000,
		body = "Ball",
		color = Color3.fromRGB(255, 90, 200),
		hat = "Crown",
		quirk = "Ruler of the candy aisle. Sweet, but do not cross her.",
	},
}

-- Look a brainrot up by id; returns nil when the id is unknown.
function BrainrotData.byId(id)
	for _, b in ipairs(BrainrotData.CAST) do
		if b.id == id then
			return b
		end
	end
	return nil
end

-- Money per second of one owned brainrot, before the owner's multipliers.
function BrainrotData.baseRate(entry)
	local def = BrainrotData.byId(entry.id)
	if not def then
		return 0
	end
	local rarity = BrainrotData.RARITIES[BrainrotData.rarityIndex(def.rarity)]
	local mutation = BrainrotData.MUTATIONS[1]
	for _, m in ipairs(BrainrotData.MUTATIONS) do
		if m.name == (entry.mutation or "None") then
			mutation = m
			break
		end
	end
	return def.rate * rarity.mult * mutation.mult
end

-- Weighted pick of a cast member for the conveyor. Cheap ones parade
-- often; the chairman almost never shows his face.
function BrainrotData.rollSpawn()
	local weights = { 30, 24, 16, 12, 8, 5, 2.4, 1.4, 0.7, 0.35, 0.12, 0.03, 14, 6.5, 1.8, 0.5, 0.07, 0.015 }
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local roll = math.random() * total
	for i, w in ipairs(weights) do
		roll -= w
		if roll <= 0 then
			return BrainrotData.CAST[i]
		end
	end
	return BrainrotData.CAST[1]
end

-- Shop lures: pay to make a brainrot of a given rarity parade next.
BrainrotData.LURES = {
	{ id = "lure_common", label = "Common Lure", rarity = "Common", cost = 500, blurb = "A common brainrot parades next." },
	{ id = "lure_rare", label = "Rare Lure", rarity = "Rare", cost = 5000, blurb = "A rare brainrot parades next." },
	{ id = "lure_epic", label = "Epic Lure", rarity = "Epic", cost = 25000, blurb = "An epic brainrot parades next." },
	{ id = "lure_legendary", label = "Legendary Lure", rarity = "Legendary", cost = 100000, blurb = "A legendary brainrot parades next." },
}

-- Base upgrades, bought in the shop. Each level costs more than the last.
BrainrotData.UPGRADES = {
	{
		id = "slots",
		label = "Bigger Base",
		blurb = "+2 brainrot slots on your base.",
		maxLevel = 3,
		baseCost = 10000,
		costMult = 2.5,
	},
	{
		id = "feed",
		label = "Golden Feed",
		blurb = "+25% money from every brainrot.",
		maxLevel = 5,
		baseCost = 15000,
		costMult = 2.2,
	},
	{
		id = "belt",
		label = "Fast Conveyor",
		blurb = "Brainrots parade 15% faster.",
		maxLevel = 4,
		baseCost = 8000,
		costMult = 2,
	},
}

function BrainrotData.upgradeCost(def, level)
	-- `level` is the level being bought (1-based).
	return math.floor(def.baseCost * (def.costMult ^ (level - 1)) + 0.5)
end

-- Rebirth: reset money and brainrots for a permanent +50% earnings each.
-- The price grows with every rebirth.
BrainrotData.REBIRTH_BASE_COST = 100000
function BrainrotData.rebirthCost(rebirths)
	return math.floor(BrainrotData.REBIRTH_BASE_COST * ((rebirths + 1) ^ 2) + 0.5)
end
function BrainrotData.rebirthMult(rebirths)
	return 1 + 0.5 * rebirths
end

-- The Greedy Seagull strikes this often, and a lock holds this long.
BrainrotData.SEAGULL_MIN_DELAY = 75
BrainrotData.SEAGULL_MAX_DELAY = 120
BrainrotData.LOCK_DURATION = 30
BrainrotData.LOCK_COOLDOWN = 90

-- Noodle Rain: a double-earnings storm, this often, lasting this long.
BrainrotData.RAIN_MIN_DELAY = 200
BrainrotData.RAIN_MAX_DELAY = 300
BrainrotData.RAIN_DURATION = 30
BrainrotData.RAIN_MULT = 2

-- Conveyor and base numbers the server and the screenshots share.
BrainrotData.CONVEYOR_FROM_X = -66
BrainrotData.CONVEYOR_TO_X = 66
BrainrotData.CONVEYOR_Z = 0
BrainrotData.CONVEYOR_SPEED = 6
BrainrotData.SPAWN_INTERVAL = 9
BrainrotData.BASE_SLOTS = 6
BrainrotData.SLOT_BONUS = 2

return BrainrotData
