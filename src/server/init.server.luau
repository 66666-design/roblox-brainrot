-- init.server.luau — Brainrot Beach: Flush Hour, server bootstrap.
-- Builds the world, wires the remotes, loads characters and starts the loops:
-- the earn tick, the Surge clock, the turret sweep and the rich list.
-- The server owns all state; the client only sends intents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteEvents = require(script.modules.RemoteEvents)
local PlayerState = require(script.modules.PlayerState)
local Economy = require(script.modules.Economy)
local BaseManager = require(script.modules.BaseManager)
local BrainrotFactory = require(script.modules.BrainrotFactory)
local Shop = require(script.modules.Shop)
local Stealing = require(script.modules.Stealing)
local WaveHazard = require(script.modules.WaveHazard)
local Leaderboard = require(script.modules.Leaderboard)
local WorldBuilder = require(script.modules.WorldBuilder)

-- 1. Network, then the world.
RemoteEvents.init()
local world = WorldBuilder.build()
BaseManager.buildPlots()
WaveHazard.SpawnCenter = world.spawnCenter

-- 2. Cross-references (set, not required, so no module cycle).
Economy.BaseManager = BaseManager
Stealing.BaseManager = BaseManager
WaveHazard.BaseManager = BaseManager

-- 3. Loops: idle dance, earn tick, Surge clock, turret sweep, rich list.
BrainrotFactory.startBobLoop()
WaveHazard.startLoop()
Leaderboard.build()
Leaderboard.startLoop()
task.spawn(function()
	while true do
		Economy.tick()
		task.wait(1)
	end
end)
task.spawn(function()
	while true do
		Stealing.turretTick()
		task.wait(1)
	end
end)

-- 4. Remote handlers. Every intent is validated by the module it calls.
local Events = RemoteEvents.Events

Events.Buy.OnServerEvent:Connect(function(player, castId)
	if not RemoteEvents.isString(castId, 32) then
		return
	end
	local ok, message = Shop.buyCharacter(player, castId)
	RemoteEvents.fireClient("Notify", player, message,
		ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 150, 150))
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
end)

Events.Hatch.OnServerEvent:Connect(function(player)
	local ok, message = Shop.hatch(player)
	RemoteEvents.fireClient("Notify", player, message,
		ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 150, 150))
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
end)

Events.Rebirth.OnServerEvent:Connect(function(player)
	local ok, message = Shop.rebirth(player)
	RemoteEvents.fireClient("Notify", player, message,
		ok and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 150, 150))
end)

Events.Interact.OnServerEvent:Connect(function(player)
	Stealing.interact(player)
end)

Events.Dash.OnServerEvent:Connect(function(player)
	Stealing.dashOrTackle(player)
end)

Events.Lock.OnServerEvent:Connect(function(player)
	Stealing.activateLock(player)
end)

Events.BuyTurret.OnServerEvent:Connect(function(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if BaseManager.buyTurret(player) then
		RemoteEvents.fireClient("Notify", player,
			"Laser turret installed! It zaps carriers in your base.",
			Color3.fromRGB(120, 255, 120))
	else
		RemoteEvents.fireClient("Notify", player,
			"Turret costs $" .. Config.TURRET_COST .. " (or you already own one).",
			Color3.fromRGB(255, 150, 150))
	end
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
end)

Events.BuyAutoBank.OnServerEvent:Connect(function(player)
	local state = PlayerState.get(player)
	if not state or state.hasAutoBank then
		return
	end
	if PlayerState.spendCash(player, Config.AUTO_BANK_COST) then
		state.hasAutoBank = true
		RemoteEvents.fireClient("Notify", player,
			"Auto-Bank on! Your pile banks itself every second.",
			Color3.fromRGB(120, 255, 120))
	else
		RemoteEvents.fireClient("Notify", player,
			"Auto-Bank costs $" .. Config.AUTO_BANK_COST .. ".",
			Color3.fromRGB(255, 150, 150))
	end
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
end)

Events.GetState.OnServerEvent:Connect(function(player)
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
	BaseManager.broadcastPlacements()
end)

-- 5. Players: state, base, character. CharacterAutoLoads is off in the
-- project file, so the server loads each character itself.
local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
	Stealing.refreshWalkSpeed(player)
end

local function onPlayerAdded(player)
	PlayerState.create(player)
	BaseManager.assignBase(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player:LoadCharacter()
	task.wait(1)
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
	BaseManager.broadcastPlacements()
end

local function onPlayerRemoving(player)
	Stealing.cleanup(player)
	BaseManager.freeBase(player)
	PlayerState.destroy(player)
	BaseManager.broadcastPlacements()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("Brainrot Beach: Flush Hour — server ready.")
