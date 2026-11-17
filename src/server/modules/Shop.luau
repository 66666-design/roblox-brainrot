-- Shop.luau — buying a named brainrot, hatching at the Rot-O-Matic, and
-- rebirth at the shrine. Every request is validated here: cash, free pads,
-- tier locks and rebirth costs. The shop never trusts the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteEvents = require(script.Parent.RemoteEvents)
local Stealing = require(script.Parent.Stealing)

local Shop = {}

-- Buy one named character. It arrives in the buyer's hands; they carry it
-- home and press E on a free pad to place it.
function Shop.buyCharacter(player, castId)
	local state = PlayerState.get(player)
	if not state then
		return false, "No state."
	end
	if state.carried ~= nil then
		return false, "Your hands are full. Place your carried brainrot first."
	end
	if PlayerState.freePadIndex(player) == nil then
		return false, "No free pad. Rebirth for more slots."
	end
	local entry = Config.getCastById(castId)
	if not entry then
		return false, "No such brainrot."
	end
	local required = Config.BUY_REQUIRES_REBIRTH[entry.rarity]
	if required and state.rebirths < required then
		return false, entry.rarity .. " unlocks after " .. required .. " rebirth(s)."
	end
	if not PlayerState.spendCash(player, entry.price) then
		return false, "Not enough cash."
	end
	local record = PlayerState.newBrainrot(entry, Config.rollMutation())
	Stealing.giveCarried(player, record)
	return true, "Bought " .. record.name .. " (" .. record.mutation .. ")! Carry it to a pad."
end

-- Hatch at the Rot-O-Matic: 50 cash, a weighted rarity roll, a mutation roll.
function Shop.hatch(player)
	local state = PlayerState.get(player)
	if not state then
		return false, "No state."
	end
	if state.carried ~= nil then
		return false, "Your hands are full. Place your carried brainrot first."
	end
	if PlayerState.freePadIndex(player) == nil then
		return false, "No free pad. Rebirth for more slots."
	end
	if not PlayerState.spendCash(player, Config.HATCH_COST) then
		return false, "Hatching costs $" .. Config.HATCH_COST .. "."
	end
	local entry = Config.rollHatch()
	local mutation = Config.rollMutation()
	local record = PlayerState.newBrainrot(entry, mutation)
	Stealing.giveCarried(player, record)
	return true, "Hatched " .. record.name .. "! " .. record.rarity .. " • " .. record.mutation
		.. " • $" .. record.rate .. "/s. Carry it to a pad."
end

-- Rebirth at the shrine: trade all cash and every brainrot for +1 rebirth,
-- a permanent +50% income multiplier, +1 pad slot and higher tiers.
function Shop.rebirth(player)
	local state = PlayerState.get(player)
	if not state then
		return false, "No state."
	end
	if state.cash < Config.REBIRTH_MIN_CASH then
		return false, "Rebirth needs $" .. Config.REBIRTH_MIN_CASH .. " banked cash."
	end
	local placedCount = 0
	for _ in pairs(state.pads) do
		placedCount += 1
	end
	if placedCount == 0 and state.carried == nil then
		return false, "Rebirth needs at least one brainrot to trade in."
	end
	-- Trade in: clear every pad and the carried brainrot.
	local BaseManager = require(script.Parent.BaseManager)
	for padIndex in pairs(state.pads) do
		BaseManager.removeBrainrot(player, padIndex)
	end
	if state.carried ~= nil then
		Stealing.dropCarried(player, true) -- silent: no return-to-pad
		state.carried = nil
	end
	state.cash = 0
	state.unbanked = 0
	state.rebirths += 1
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
	return true, "REBIRTH " .. state.rebirths .. "! Income x"
		.. string.format("%.1f", PlayerState.getRebirthMultiplier(player))
		.. " forever, +" .. PlayerState.padSlots(player) .. " pad slots."
end

return Shop
