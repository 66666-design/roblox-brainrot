-- Tour.luau — scene setters for the entry's screenshots and the finalist
-- review. TOUR.json calls these (module ServerScriptService.Tour) to bring
-- the game to each screenshot: the promenade, a stocked base, the Surge.
-- Each function takes the calling player and the tour's argument string.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(ServerScriptService.Server.modules.PlayerState)
local BaseManager = require(ServerScriptService.Server.modules.BaseManager)
local Stealing = require(ServerScriptService.Server.modules.Stealing)
local WaveHazard = require(ServerScriptService.Server.modules.WaveHazard)

local Tour = {}

local function firstPlayer(player)
	if player and typeof(player) == "Instance" and player:IsA("Player") then
		return player
	end
	local list = Players:GetPlayers()
	return list[1]
end

local function teleport(player, position)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
	end
end

local function ensureCash(player, amount)
	local state = PlayerState.get(player)
	if state and state.cash < amount then
		PlayerState.addCash(player, amount - state.cash)
	end
end

-- 1-start.png: the player on the promenade in front of the Rot-O-Matic,
-- with a Tralalero and a Sigma Shark idling nearby.
function Tour.setupStart(player, _arg)
	player = firstPlayer(player)
	if not player then
		return
	end
	ensureCash(player, 500)
	-- A couple of showcase brainrots standing on the promenade.
	local showcase = {
		{ id = "tralalero", at = Vector3.new(-6, 1, -8) },
		{ id = "sigmashark", at = Vector3.new(6, 1, -8) },
	}
	for _, item in ipairs(showcase) do
		local entry = Config.getCastById(item.id)
		if entry then
			local record = PlayerState.newBrainrot(entry, Config.MUTATIONS[1])
			local BrainrotFactory = require(ServerScriptService.Server.modules.BrainrotFactory)
			local model = BrainrotFactory.buildBrainrot(record, CFrame.new(item.at), entry.rate)
			model.Parent = Workspace
		end
	end
	teleport(player, Vector3.new(0, 0, 5))
end

-- 2-play.png: the player's own base, three brainrots earning on pads, the
-- cash pile filling and the wave bar counting down.
function Tour.setupPlay(player, _arg)
	player = firstPlayer(player)
	if not player then
		return
	end
	ensureCash(player, 5000)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local picks = { "tralalero", "sigmashark", "capyappa" }
	for _, castId in ipairs(picks) do
		local entry = Config.getCastById(castId)
		local padIndex = PlayerState.freePadIndex(player)
		if entry and padIndex then
			local record = PlayerState.newBrainrot(entry, Config.rollMutation())
			BaseManager.placeBrainrot(player, padIndex, record)
		end
	end
	local center = BaseManager.getBaseCenter(player)
	if center then
		teleport(player, center + Vector3.new(0, 0, 10))
	end
end

-- 3-end.png: the Surge sweeping the map while the player dashes home
-- across the bridge carrying a golden Legendary.
function Tour.setupSurge(player, _arg)
	player = firstPlayer(player)
	if not player then
		return
	end
	ensureCash(player, 5000)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if not state.carried then
		local entry = Config.getCastById("tralalero")
		if entry then
			local record = PlayerState.newBrainrot(entry, { name = "Golden", mult = 3 })
			Stealing.giveCarried(player, record)
		end
	end
	teleport(player, Vector3.new(0, 0, 115))
	WaveHazard.triggerNow()
end

return Tour
