-- init.client.luau — Brainrot Beach: Flush Hour, client bootstrap.
-- Waits for the server's Remotes, starts the HUD, shop, controls, world
-- tags and effects, and wires every server event to the module that owns it.
-- The client only renders and sends intents; the server owns all state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local HUD = require(script.modules.HUD)
local ShopUI = require(script.modules.ShopUI)
local Controls = require(script.modules.Controls)
local WorldTags = require(script.modules.WorldTags)
local Effects = require(script.modules.Effects)

-- The server creates the Remotes folder at start; wait for it.
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local function getRemote(name)
	return remotes:WaitForChild(name)
end

local RemoteEvents = {
	Buy = getRemote("Buy"),
	Hatch = getRemote("Hatch"),
	Rebirth = getRemote("Rebirth"),
	Interact = getRemote("Interact"),
	Dash = getRemote("Dash"),
	Lock = getRemote("Lock"),
	BuyTurret = getRemote("BuyTurret"),
	BuyAutoBank = getRemote("BuyAutoBank"),
	GetState = getRemote("GetState"),
	StateUpdate = getRemote("StateUpdate"),
	WaveUpdate = getRemote("WaveUpdate"),
	Notify = getRemote("Notify"),
	Placements = getRemote("Placements"),
}

HUD.init(RemoteEvents)
ShopUI.init(RemoteEvents)
Controls.init(RemoteEvents)
WorldTags.init(RemoteEvents)
Effects.init(RemoteEvents)

-- Cross-references (set, not required, so no module cycle).
HUD.ShopUI = ShopUI
Controls.ShopUI = ShopUI

-- Server-to-client events.
RemoteEvents.StateUpdate.OnClientEvent:Connect(function(snapshot)
	if snapshot then
		HUD.update(snapshot)
		ShopUI.update(snapshot)
		WorldTags.update(snapshot)
	end
end)

RemoteEvents.WaveUpdate.OnClientEvent:Connect(function(data)
	if data then
		HUD.updateWave(data)
		if data.warning then
			Effects.onWaveWarning()
		end
	end
end)

RemoteEvents.Notify.OnClientEvent:Connect(function(message, color)
	HUD.notify(message, color)
	Effects.onNotify(message, color)
end)

RemoteEvents.Placements.OnClientEvent:Connect(function(placements)
	WorldTags.updatePlacements(placements or {})
end)

-- Ask for the first snapshot (the server also sends one on join).
RemoteEvents.GetState:FireServer()
