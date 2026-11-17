-- PlayerState.luau — the single source of truth for one player's progress.
-- Every other server module reads and writes through here; nothing else keeps
-- its own copy of cash, pads or rebirths. Cash and rebirths persist in a
-- DataStore (best effort: a failed save or load falls back to a fresh state
-- and never breaks the game). Placed brainrots are session-only by design.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlayerState = {}
PlayerState.States = {}

local DATASTORE_NAME = "BrainrotBeach-v1"
local store = nil
local storeOk, storeResult = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)
if storeOk then
	store = storeResult
end

-- A brainrot record: what a pad or a pair of hands holds.
-- { castId, name, rarity, rate, mutation, mutationMult, uid }
local nextUid = 1
function PlayerState.newBrainrot(entry, mutation)
	local mutationData = mutation or Config.MUTATIONS[1]
	local record = {
		castId = entry.id,
		name = entry.name,
		rarity = entry.rarity,
		rate = entry.rate,
		mutation = mutationData.name,
		mutationMult = mutationData.mult,
		uid = nextUid,
	}
	nextUid += 1
	return record
end

function PlayerState.newState(player)
	return {
		player = player,
		cash = Config.START_CASH,
		unbanked = 0, -- cash sitting in the base pile, not yet banked
		rebirths = 0,
		totalEarned = 0,
		pads = {}, -- [padIndex] = brainrot record or nil
		carried = nil, -- brainrot record being carried, or nil
		lockUntil = 0, -- os.clock timestamp: base shield ends
		lockCooldownUntil = 0,
		dashUntil = 0,
		dashCooldownUntil = 0,
		tackleCooldownUntil = 0,
		hasTurret = false,
		hasAutoBank = false,
		baseIndex = 0, -- assigned by BaseManager
	}
end

function PlayerState.get(player)
	return PlayerState.States[player]
end

-- Create state for a joining player, restoring cash and rebirths if saved.
function PlayerState.create(player)
	local state = PlayerState.newState(player)
	PlayerState.States[player] = state
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("player-" .. player.UserId)
		end)
		if ok and typeof(saved) == "table" then
			if typeof(saved.cash) == "number" then
				state.cash = math.max(0, math.floor(saved.cash))
			end
			if typeof(saved.rebirths) == "number" then
				state.rebirths = math.max(0, math.floor(saved.rebirths))
			end
			if typeof(saved.totalEarned) == "number" then
				state.totalEarned = math.max(0, math.floor(saved.totalEarned))
			end
		end
	end
	return state
end

-- Save cash and rebirths. Best effort; a failure is silently ignored.
function PlayerState.save(player)
	local state = PlayerState.States[player]
	if not state or not store then
		return
	end
	pcall(function()
		store:SetAsync("player-" .. player.UserId, {
			cash = state.cash,
			rebirths = state.rebirths,
			totalEarned = state.totalEarned,
		})
	end)
end

function PlayerState.destroy(player)
	PlayerState.save(player)
	PlayerState.States[player] = nil
end

-- Money helpers.
function PlayerState.addCash(player, amount)
	local state = PlayerState.States[player]
	if not state then
		return
	end
	state.cash += amount
end

-- Returns true and deducts, or false when the player cannot afford it.
function PlayerState.spendCash(player, amount)
	local state = PlayerState.States[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	return true
end

-- Move the pile into the bank.
function PlayerState.bankPile(player)
	local state = PlayerState.States[player]
	if not state or state.unbanked <= 0 then
		return 0
	end
	local amount = math.floor(state.unbanked)
	state.cash += amount
	state.totalEarned += amount
	state.unbanked = 0
	return amount
end

-- Pad slots grow with rebirths: 4 at start, +1 per rebirth, max 8.
function PlayerState.padSlots(player)
	local state = PlayerState.States[player]
	if not state then
		return Config.PAD_SLOTS_START
	end
	return math.min(Config.PAD_SLOTS_START + state.rebirths, Config.PAD_SLOTS_MAX)
end

function PlayerState.freePadIndex(player)
	local state = PlayerState.States[player]
	if not state then
		return nil
	end
	for i = 1, PlayerState.padSlots(player) do
		if state.pads[i] == nil then
			return i
		end
	end
	return nil
end

function PlayerState.placeOnPad(player, padIndex, record)
	local state = PlayerState.States[player]
	if not state or padIndex < 1 or padIndex > PlayerState.padSlots(player) then
		return false
	end
	if state.pads[padIndex] ~= nil then
		return false
	end
	state.pads[padIndex] = record
	return true
end

function PlayerState.removeFromPad(player, padIndex)
	local state = PlayerState.States[player]
	if not state then
		return nil
	end
	local record = state.pads[padIndex]
	state.pads[padIndex] = nil
	return record
end

function PlayerState.getRebirthMultiplier(player)
	local state = PlayerState.States[player]
	if not state then
		return 1
	end
	return 1 + Config.REBIRTH_MULT_PER * state.rebirths
end

-- A snapshot the client can render: cash, pile, rate, pads, lock, rebirths.
function PlayerState.snapshot(player)
	local state = PlayerState.States[player]
	if not state then
		return nil
	end
	local pads = {}
	for i = 1, PlayerState.padSlots(player) do
		local record = state.pads[i]
		if record then
			pads[i] = {
				name = record.name,
				rarity = record.rarity,
				rate = record.rate,
				mutation = record.mutation,
				mutationMult = record.mutationMult,
			}
		end
	end
	local carried = nil
	if state.carried then
		carried = {
			name = state.carried.name,
			rarity = state.carried.rarity,
			rate = state.carried.rate,
			mutation = state.carried.mutation,
		}
	end
	return {
		cash = state.cash,
		unbanked = math.floor(state.unbanked),
		rebirths = state.rebirths,
		pads = pads,
		padSlots = PlayerState.padSlots(player),
		carried = carried,
		lockSecondsLeft = math.max(0, state.lockUntil - os.clock()),
		lockCooldownLeft = math.max(0, state.lockCooldownUntil - os.clock()),
		hasTurret = state.hasTurret,
		hasAutoBank = state.hasAutoBank,
		baseIndex = state.baseIndex,
	}
end

-- All players currently in the game.
function PlayerState.allPlayers()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerState.States[player] then
			table.insert(list, player)
		end
	end
	return list
end

return PlayerState
