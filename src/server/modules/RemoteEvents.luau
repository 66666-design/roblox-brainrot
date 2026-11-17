-- RemoteEvents.luau — the network contract between server and client.
-- Creates one RemoteEvent per name in Config.REMOTES under
-- ReplicatedStorage.Remotes, and validates every payload the server receives.
-- The client only ever sends intents; the server owns all state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local RemoteEvents = {}
RemoteEvents.Folder = nil
RemoteEvents.Events = {}

-- Create the folder and every RemoteEvent the game uses.
function RemoteEvents.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	RemoteEvents.Folder = folder
	for _, name in pairs(Config.REMOTES) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		RemoteEvents.Events[name] = event
	end
	return RemoteEvents
end

function RemoteEvents.get(name)
	return RemoteEvents.Events[name]
end

-- Payload validators. Every handler checks its arguments with these first,
-- so a client can never crash the server or forge a value.
function RemoteEvents.isPlayer(value)
	return typeof(value) == "Instance" and value:IsA("Player")
end

function RemoteEvents.isString(value, maxLen)
	return typeof(value) == "string" and #value <= (maxLen or 64)
end

function RemoteEvents.isPositiveInt(value)
	return typeof(value) == "number" and value >= 1 and math.floor(value) == value
end

function RemoteEvents.isVector3(value)
	return typeof(value) == "Vector3"
end

-- Fire a server-to-client event to one player, safely.
function RemoteEvents.fireClient(name, player, ...)
	local event = RemoteEvents.Events[name]
	if event and RemoteEvents.isPlayer(player) then
		event:FireClient(player, ...)
	end
end

-- Fire a server-to-client event to every player.
function RemoteEvents.fireAll(name, ...)
	local event = RemoteEvents.Events[name]
	if event then
		event:FireAllClients(...)
	end
end

return RemoteEvents
