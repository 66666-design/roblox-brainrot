-- WaveHazard.luau — the Skibidi Surge. Every WAVE_INTERVAL seconds a wall
-- of toilet-water sweeps the map from north to south. Players caught outside
-- their own base or the spawn island are knocked back and drop what they
-- carry; a dropped brainrot the wave touches comes back Corrupted (x15).
-- A base lock shields the whole base. The HUD counts the wave down.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteEvents = require(script.Parent.RemoteEvents)
local Stealing = require(script.Parent.Stealing)

local WaveHazard = {}
WaveHazard.BaseManager = nil -- set by init to avoid a require cycle
WaveHazard.SpawnCenter = Vector3.new(0, 0, 200) -- set by WorldBuilder

local WAVE_NORTH_Z = -260
local WAVE_SOUTH_Z = 260
local WAVE_HEIGHT = 14

local wavePart = nil
local nextWaveAt = 0
local warningSent = false

-- Build the wave wall once: a big translucent slab, hidden until it sweeps.
local function getWavePart()
	if wavePart then
		return wavePart
	end
	local part = Instance.new("Part")
	part.Name = "SkibidiSurge"
	part.Size = Vector3.new(520, WAVE_HEIGHT, 6)
	part.Color = Color3.fromRGB(120, 200, 255)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.35
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CFrame = CFrame.new(0, WAVE_HEIGHT / 2, WAVE_NORTH_Z)
	part.Parent = Workspace
	wavePart = part
	return part
end

-- Is this world position safe from the wave? Inside your own base plot, on
-- the spawn island, or behind an active base lock.
local function isSafe(player, position)
	if Stealing.isBaseLocked(player) then
		return true
	end
	if WaveHazard.BaseManager and WaveHazard.BaseManager.isInOwnBase(player, position) then
		return true
	end
	-- Spawn island: a 60x60 square around the spawn centre.
	if math.abs(position.X - WaveHazard.SpawnCenter.X) <= 30
		and math.abs(position.Z - WaveHazard.SpawnCenter.Z) <= 30 then
		return true
	end
	return false
end

-- One sweep: the wall travels north to south over WAVE_DURATION seconds.
-- Anyone it passes over outside a safe zone is knocked back and drops their
-- carried brainrot, which comes back Corrupted.
local function sweep()
	local part = getWavePart()
	local startTime = os.clock()
	local duration = Config.WAVE_DURATION
	while os.clock() - startTime < duration do
		local t = (os.clock() - startTime) / duration
		local z = WAVE_NORTH_Z + (WAVE_SOUTH_Z - WAVE_NORTH_Z) * t
		part.CFrame = CFrame.new(0, WAVE_HEIGHT / 2, z)
		-- Hit check: players within 4 studs of the wall's current line.
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and math.abs(root.Position.Z - z) <= 4 then
				if not isSafe(player, root.Position) then
					local state = PlayerState.get(player)
					-- Knock back toward the spawn island.
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.WalkSpeed = 0
						task.delay(1, function()
							local still = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
							if still then
								still.WalkSpeed = 16
							end
						end)
					end
					root.CFrame = CFrame.new(WaveHazard.SpawnCenter + Vector3.new(0, 5, 0))
					-- Drop the carried brainrot; the wave corrupts it, and
					-- it returns to its owner's first free pad after 5 s.
					if state and state.carried then
						local record = Stealing.dropCarried(player, false)
						if record then
							record.mutation = Config.CORRUPTED.name
							record.mutationMult = Config.CORRUPTED.mult
							RemoteEvents.fireClient("Notify", player,
								"The Surge CORRUPTED your " .. record.name .. "! Now x15!",
								Color3.fromRGB(180, 120, 255))
							task.delay(5, function()
								local ownerState = PlayerState.get(player)
								if ownerState and PlayerState.freePadIndex(player) then
									WaveHazard.BaseManager.placeBrainrot(
										player, PlayerState.freePadIndex(player), record)
								end
							end)
						end
					else
						RemoteEvents.fireClient("Notify", player,
							"The Skibidi Surge washed you back to spawn!",
							Color3.fromRGB(120, 200, 255))
					end
				end
			end
		end
		task.wait(0.1)
	end
	part.CFrame = CFrame.new(0, WAVE_HEIGHT / 2, WAVE_NORTH_Z)
end

-- The wave clock: counts down, warns 5 s early, sweeps, repeats.
function WaveHazard.startLoop()
	nextWaveAt = os.clock() + Config.WAVE_INTERVAL
	task.spawn(function()
		while true do
			local now = os.clock()
			local secondsLeft = nextWaveAt - now
			if secondsLeft <= Config.WAVE_WARNING and not warningSent then
				warningSent = true
				RemoteEvents.fireAll("WaveUpdate", {
					secondsLeft = math.max(0, math.ceil(secondsLeft)),
					warning = true,
				})
				RemoteEvents.fireAll("Notify",
					"SKIBIDI SURGE IN 5 SECONDS! DASH HOME!",
					Color3.fromRGB(255, 100, 100))
			elseif secondsLeft > Config.WAVE_WARNING then
				warningSent = false
				RemoteEvents.fireAll("WaveUpdate", {
					secondsLeft = math.ceil(secondsLeft),
					warning = false,
				})
			end
			if secondsLeft <= 0 then
				sweep()
				nextWaveAt = os.clock() + Config.WAVE_INTERVAL
				warningSent = false
			end
			task.wait(1)
		end
	end)
end

-- Fire the wave right now (used by the Tour helper for screenshots).
function WaveHazard.triggerNow()
	nextWaveAt = os.clock()
end

return WaveHazard
