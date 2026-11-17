-- Economy.luau — the earn-per-second tick, purchase math and payouts.
-- Every placed brainrot accrues its effective rate into the base pile once a
-- second. The Fanum Taxman adds a 5% cut of his neighbours' rate. Banking
-- moves the pile into cash; Auto-Bank does it every tick.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteEvents = require(script.Parent.RemoteEvents)

local Economy = {}
Economy.BaseManager = nil -- set by init to avoid a require cycle

-- Total cash per second of one player's placed brainrots, including the
-- Fanum Taxman synergy: each Taxman adds 5% of the other pads' rate.
function Economy.getIncomeRate(player)
	local state = PlayerState.get(player)
	if not state then
		return 0
	end
	local baseSum = 0
	local othersSum = 0
	local taxmen = 0
	for _, record in pairs(state.pads) do
		if record then
			local rate = Config.effectiveRate(
				{ rate = record.rate },
				record.mutationMult,
				state.rebirths
			)
			baseSum += rate
			if record.castId == "fanumtaxman" then
				taxmen += 1
			else
				othersSum += rate
			end
		end
	end
	-- mult is already inside effectiveRate; baseSum is the total.
	return baseSum + 0.05 * othersSum * taxmen
end

-- One tick: accrue every player's income into their pile, then tell each
-- client its new snapshot. Auto-Bank moves the pile straight into cash.
function Economy.tick()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.get(player)
		if state then
			local rate = Economy.getIncomeRate(player)
			if rate > 0 then
				state.unbanked += rate
			end
			if state.hasAutoBank and state.unbanked >= 1 then
				PlayerState.bankPile(player)
			end
			if Economy.BaseManager then
				Economy.BaseManager.updatePileLabel(player)
			end
			RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
		end
	end
end

-- Can this player afford the price? (Pure check, does not spend.)
function Economy.canAfford(player, amount)
	local state = PlayerState.get(player)
	return state ~= nil and state.cash >= amount
end

-- Cost of a rebirth: 1000 banked cash, plus every brainrot is traded in.
function Economy.rebirthCost(player)
	return Config.REBIRTH_MIN_CASH
end

return Economy
