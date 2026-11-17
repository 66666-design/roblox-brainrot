-- Config.luau — every tunable number of Brainrot Beach: Flush Hour.
-- Lives in ReplicatedStorage.Shared so the server and the client read the same
-- numbers. No services are used here, so both sides can require it safely.

local Config = {}

Config.GAME_NAME = "Brainrot Beach: Flush Hour"
Config.GAME_VERSION = 1

-- Money
Config.START_CASH = 100
Config.HATCH_COST = 50
Config.REBIRTH_MIN_CASH = 1000
Config.TURRET_COST = 500
Config.AUTO_BANK_COST = 250

-- Bases and pads
Config.BASE_COUNT = 8
Config.BASE_RADIUS = 180
Config.BASE_SIZE = 40
Config.PAD_SLOTS_START = 4
Config.PAD_SLOTS_MAX = 8

-- Rebirth
Config.REBIRTH_MULT_PER = 0.5 -- each rebirth adds +50% income

-- Base lock (F key): 30 s shield, 60 s cooldown
Config.LOCK_DURATION = 30
Config.LOCK_COOLDOWN = 60

-- The Skibidi Surge wave: every 180 s, 5 s warning, ~20 s sweep
Config.WAVE_INTERVAL = 180
Config.WAVE_WARNING = 5
Config.WAVE_DURATION = 20

-- Carrying a brainrot slows the carrier; heavier rarities slow more
Config.CARRY_SLOW_BASE = 0.30
Config.CARRY_SLOW_PER_TIER = 0.05
Config.DASH_SPEED = 32
Config.DASH_DURATION = 2
Config.DASH_COOLDOWN = 10
Config.TACKLE_COOLDOWN = 5

-- Rarities, in ladder order. Colour is the colour of the name label and aura.
Config.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(170, 170, 170), hatchWeight = 45 },
	{ name = "Uncommon", color = Color3.fromRGB(85, 200, 85), hatchWeight = 30 },
	{ name = "Rare", color = Color3.fromRGB(85, 140, 255), hatchWeight = 15 },
	{ name = "Epic", color = Color3.fromRGB(170, 85, 255), hatchWeight = 7 },
	{ name = "Legendary", color = Color3.fromRGB(255, 200, 40), hatchWeight = 2.5 },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 70), hatchWeight = 0.45 },
	{ name = "Secret", color = Color3.fromRGB(120, 60, 180), hatchWeight = 0.05 },
}

-- The cast. price is what the Shop charges; rate is cash per second on a pad.
-- bodyColor/headColor give each character a distinct look; gag is its joke.
Config.CAST = {
	{ id = "skibidoo", name = "Lil' Skibidoo", rarity = "Common", rate = 1, price = 25,
		bodyColor = Color3.fromRGB(200, 200, 200), headColor = Color3.fromRGB(120, 160, 200),
		gag = "Toilet-dwelling squeaker. Bobs up and down." },
	{ id = "capyappa", name = "Cap-yappa", rarity = "Common", rate = 2, price = 50,
		bodyColor = Color3.fromRGB(150, 110, 70), headColor = Color3.fromRGB(180, 140, 100),
		gag = "Capybara in a bucket hat. Unbothered." },
	{ id = "gyattgnome", name = "Gyatt Gnome", rarity = "Common", rate = 3, price = 75,
		bodyColor = Color3.fromRGB(200, 60, 60), headColor = Color3.fromRGB(255, 220, 180),
		gag = "Garden gnome that twerks." },
	{ id = "rizzraccoon", name = "Rizz Raccoon", rarity = "Uncommon", rate = 5, price = 125,
		bodyColor = Color3.fromRGB(90, 90, 100), headColor = Color3.fromRGB(140, 140, 150),
		gag = "Winks and finger-guns at everyone." },
	{ id = "ohiofrog", name = "Ohio Frog", rarity = "Uncommon", rate = 8, price = 200,
		bodyColor = Color3.fromRGB(60, 180, 80), headColor = Color3.fromRGB(120, 220, 120),
		gag = "Croaks a cursed ribbit in 4K." },
	{ id = "mewingmaven", name = "Mewing Maven", rarity = "Uncommon", rate = 10, price = 250,
		bodyColor = Color3.fromRGB(220, 220, 230), headColor = Color3.fromRGB(200, 200, 220),
		gag = "Silently jawlines at passers-by." },
	{ id = "sigmashark", name = "Sigma Shark", rarity = "Rare", rate = 15, price = 400,
		bodyColor = Color3.fromRGB(70, 110, 180), headColor = Color3.fromRGB(200, 220, 240),
		gag = "Nods to phonk only." },
	{ id = "fanumtaxman", name = "Fanum Taxman", rarity = "Rare", rate = 20, price = 500,
		bodyColor = Color3.fromRGB(40, 40, 40), headColor = Color3.fromRGB(220, 200, 120),
		gag = "Takes a 5% cut of his neighbours' income." },
	{ id = "tungtung", name = "Tung-Tung Sahur", rarity = "Epic", rate = 35, price = 900,
		bodyColor = Color3.fromRGB(140, 90, 50), headColor = Color3.fromRGB(200, 160, 110),
		gag = "A drum that never stops." },
	{ id = "bombardiro", name = "Bombardiro Crocodilo", rarity = "Epic", rate = 50, price = 1250,
		bodyColor = Color3.fromRGB(60, 140, 90), headColor = Color3.fromRGB(220, 220, 220),
		gag = "Croco-bomber. Loops the lagoon." },
	{ id = "tralalero", name = "Tralalero Tralala", rarity = "Legendary", rate = 75, price = 2000,
		bodyColor = Color3.fromRGB(80, 130, 200), headColor = Color3.fromRGB(255, 255, 255),
		gag = "Shark in Nikes. Moonwalks." },
	{ id = "lavaca", name = "La Vaca Saturno Saturnita", rarity = "Legendary", rate = 100, price = 2500,
		bodyColor = Color3.fromRGB(240, 240, 240), headColor = Color3.fromRGB(200, 170, 120),
		gag = "Cow with a Saturn head. Orbits a ring." },
	{ id = "cappuccino", name = "Cappuccino Assassino", rarity = "Mythic", rate = 150, price = 4000,
		bodyColor = Color3.fromRGB(90, 60, 40), headColor = Color3.fromRGB(255, 240, 220),
		gag = "Coffee-cup ninja." },
	{ id = "brrbrr", name = "Brr Brr Patapim", rarity = "Mythic", rate = 200, price = 5000,
		bodyColor = Color3.fromRGB(70, 120, 70), headColor = Color3.fromRGB(180, 220, 180),
		gag = "Forest creature. Plays the sax." },
	{ id = "rizzler", name = "The Rizzler", rarity = "Secret", rate = 500, price = 15000,
		bodyColor = Color3.fromRGB(30, 30, 40), headColor = Color3.fromRGB(255, 215, 0),
		gag = "Sunglasses at night." },
	{ id = "brainrotgod", name = "67 Brainrot God", rarity = "Secret", rate = 1000, price = 30000,
		bodyColor = Color3.fromRGB(20, 20, 30), headColor = Color3.fromRGB(255, 215, 0),
		gag = "Final boss of the ladder." },
}

-- Mutations rolled on hatch. Corrupted is never rolled: only the Surge grants it.
Config.MUTATIONS = {
	{ name = "Normal", mult = 1, chance = 92.2 },
	{ name = "Golden", mult = 3, chance = 5 },
	{ name = "Diamond", mult = 6, chance = 2 },
	{ name = "Rainbow", mult = 10, chance = 0.8 },
}
Config.CORRUPTED = { name = "Corrupted", mult = 15 }

-- Mythic and Secret can only be bought after at least one rebirth.
Config.BUY_REQUIRES_REBIRTH = { Mythic = 1, Secret = 1 }

-- RemoteEvent names, shared by server and client.
Config.REMOTES = {
	Buy = "Buy",
	Hatch = "Hatch",
	Rebirth = "Rebirth",
	Interact = "Interact",
	Dash = "Dash",
	Lock = "Lock",
	BuyTurret = "BuyTurret",
	BuyAutoBank = "BuyAutoBank",
	GetState = "GetState",
	StateUpdate = "StateUpdate",
	WaveUpdate = "WaveUpdate",
	Notify = "Notify",
	Placements = "Placements",
}

-- Look up a cast entry by id.
function Config.getCastById(id)
	for _, entry in ipairs(Config.CAST) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Rarity index (1 = Common) and colour for a rarity name.
function Config.getRarityIndex(rarityName)
	for i, rarity in ipairs(Config.RARITIES) do
		if rarity.name == rarityName then
			return i
		end
	end
	return 1
end

function Config.getRarityColor(rarityName)
	for _, rarity in ipairs(Config.RARITIES) do
		if rarity.name == rarityName then
			return rarity.color
		end
	end
	return Color3.fromRGB(170, 170, 170)
end

-- Roll a mutation for a fresh hatch.
function Config.rollMutation()
	local roll = math.random() * 100
	local acc = 0
	for _, mutation in ipairs(Config.MUTATIONS) do
		acc += mutation.chance
		if roll <= acc then
			return mutation
		end
	end
	return Config.MUTATIONS[1]
end

-- Roll a rarity for the Rot-O-Matic gacha, then a random character of it.
function Config.rollHatch()
	local total = 0
	for _, rarity in ipairs(Config.RARITIES) do
		total += rarity.hatchWeight
	end
	local roll = math.random() * total
	local acc = 0
	local picked = Config.RARITIES[1].name
	for _, rarity in ipairs(Config.RARITIES) do
		acc += rarity.hatchWeight
		if roll <= acc then
			picked = rarity.name
			break
		end
	end
	local pool = {}
	for _, entry in ipairs(Config.CAST) do
		if entry.rarity == picked then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return Config.CAST[1]
	end
	return pool[math.random(1, #pool)]
end

-- Effective cash per second of one placed brainrot for a player with this
-- rebirth count. Fanum Taxman synergy is added by Economy, not here.
function Config.effectiveRate(entry, mutationMult, rebirths)
	return entry.rate * mutationMult * (1 + Config.REBIRTH_MULT_PER * rebirths)
end

return Config
