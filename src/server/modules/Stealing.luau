-- Stealing.luau — carrying, grabbing, tackling, base locks and turrets.
-- Carrying is the heart of the game: a brainrot in your hands earns nothing
-- until it stands on one of your pads, and anyone can take it from you.
-- Every action is validated on the server: distance, pads, locks, cooldowns.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteEvents = require(script.Parent.RemoteEvents)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local Stealing = {}
Stealing.BaseManager = nil -- set by init to avoid a require cycle
Stealing.CarriedModels = {} -- [player] = Model following the player

local GRAB_RANGE = 12
local TACKLE_RANGE = 10
local NORMAL_WALK_SPEED = 16

-- The carried model floats above the player's head. One shared loop keeps
-- every carried model glued to its carrier.
local function startCarryLoop()
	RunService.Heartbeat:Connect(function()
		for player, model in pairs(Stealing.CarriedModels) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if model.Parent == nil then
				-- The model was removed elsewhere: stop tracking it.
				Stealing.CarriedModels[player] = nil
			elseif not character or not root then
				-- Carrier is respawning: leave the model where it is; the
				-- loop re-attaches it as soon as the character returns.
			else
				local record = PlayerState.get(player) and PlayerState.get(player).carried
				if record then
					local cframe = root.CFrame * CFrame.new(0, 4.5, 0)
					BrainrotFactory.setBaseCFrame(model, cframe)
					local data = BrainrotFactory.Bobbing[model]
					if data then
						for _, item in ipairs(data.parts) do
							item.part.CFrame = cframe * item.offset
						end
					end
				end
			end
		end
	end)
end

-- Walk speed for a carrier: slower for rarer cargo.
local function applyCarrySpeed(player)
	local state = PlayerState.get(player)
	local character = player.Character
	if not state or not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if state.carried then
		local tier = Config.getRarityIndex(state.carried.rarity)
		local slow = Config.CARRY_SLOW_BASE + Config.CARRY_SLOW_PER_TIER * tier
		humanoid.WalkSpeed = math.max(6, NORMAL_WALK_SPEED * (1 - slow))
	else
		humanoid.WalkSpeed = NORMAL_WALK_SPEED
	end
end

-- Re-apply the walk speed after a respawn (so respawning never clears the
-- carry slow). Called by init.server.luau on CharacterAdded.
function Stealing.refreshWalkSpeed(player)
	applyCarrySpeed(player)
end

-- Hand a brainrot record to a player: it appears above their head.
function Stealing.giveCarried(player, record)
	local state = PlayerState.get(player)
	if not state then
		return false
	end
	state.carried = record
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local cframe = CFrame.new(0, 10, 0)
	if root then
		cframe = root.CFrame * CFrame.new(0, 4.5, 0)
	end
	local effective = Config.effectiveRate({ rate = record.rate }, record.mutationMult, state.rebirths)
	local model = BrainrotFactory.buildBrainrot(record, cframe, effective)
	model.Parent = Workspace
	Stealing.CarriedModels[player] = model
	applyCarrySpeed(player)
	return true
end

-- Take the carried brainrot away without placing it (steal-back, rebirth).
-- silent = true destroys the model and skips the return-to-pad timer.
function Stealing.dropCarried(player, silent)
	local state = PlayerState.get(player)
	if not state or not state.carried then
		return nil
	end
	local record = state.carried
	state.carried = nil
	local model = Stealing.CarriedModels[player]
	Stealing.CarriedModels[player] = nil
	if model and model.Parent ~= nil then
		model:Destroy()
	end
	applyCarrySpeed(player)
	return record
end

-- The E key: context action. Carrying + near a free own pad -> place it.
-- Not carrying + near a pad with a brainrot -> grab it (own pad: pick it up
-- to move it; another player's pad: steal it, unless their base is locked).
function Stealing.interact(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local pos = root.Position

	-- Carrying: try to place on a free pad of my own base.
	if state.carried then
		if not Stealing.BaseManager.isInOwnBase(player, pos) then
			RemoteEvents.fireClient("Notify", player,
				"Carry it home to your base first!", Color3.fromRGB(255, 200, 100))
			return
		end
		local padIndex = PlayerState.freePadIndex(player)
		if not padIndex then
			RemoteEvents.fireClient("Notify", player,
				"No free pad. Rebirth for more slots.", Color3.fromRGB(255, 150, 150))
			return
		end
		local record = state.carried
		Stealing.dropCarried(player, true)
		Stealing.BaseManager.placeBrainrot(player, padIndex, record)
		RemoteEvents.fireClient("Notify", player,
			record.name .. " is earning $" .. record.rate .. "/s on pad " .. padIndex .. "!",
			Color3.fromRGB(120, 255, 120))
		RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
		return
	end

	-- Not carrying: find the nearest pad with a brainrot, mine or theirs.
	local best = nil -- { owner, padIndex, record, distance }
	for _, other in ipairs(PlayerState.allPlayers()) do
		local otherState = PlayerState.get(other)
		if otherState and otherState.baseIndex >= 1 then
			for padIndex, record in pairs(otherState.pads) do
				if record then
					local padCFrame = Stealing.BaseManager.getPadCFrame(other, padIndex)
					if padCFrame then
						local dist = (padCFrame.Position - pos).Magnitude
						if dist <= GRAB_RANGE and (not best or dist < best.distance) then
							best = { owner = other, padIndex = padIndex, record = record, distance = dist }
						end
					end
				end
			end
		end
	end
	if not best then
		return
	end
	if best.owner == player then
		-- Pick up my own brainrot to move it.
		local record = Stealing.BaseManager.removeBrainrot(player, best.padIndex)
		if record then
			Stealing.giveCarried(player, record)
			RemoteEvents.fireClient("Notify", player,
				"Picked up " .. record.name .. ".", Color3.fromRGB(200, 220, 255))
		end
		return
	end
	-- Stealing from another player.
	local victimState = PlayerState.get(best.owner)
	if victimState and os.clock() < victimState.lockUntil then
		RemoteEvents.fireClient("Notify", player,
			best.owner.Name .. "'s base is LOCKED. Try again later!",
			Color3.fromRGB(255, 150, 150))
		return
	end
	local record = Stealing.BaseManager.removeBrainrot(best.owner, best.padIndex)
	if not record then
		return
	end
	Stealing.giveCarried(player, record)
	RemoteEvents.fireClient("Notify", player,
		"STOLE " .. record.name .. " from " .. best.owner.Name .. "! Run home!",
		Color3.fromRGB(255, 220, 80))
	RemoteEvents.fireClient("Notify", best.owner,
		"ALARM! " .. player.Name .. " stole your " .. record.name .. "!",
		Color3.fromRGB(255, 100, 100))
	RemoteEvents.fireClient("StateUpdate", best.owner, PlayerState.snapshot(best.owner))
end

-- The Q key: dash forward, or tackle a nearby carrier and make them drop it.
function Stealing.dashOrTackle(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	-- Tackle first: a carrier within range drops their brainrot.
	if os.clock() >= state.tackleCooldownUntil then
		for _, other in ipairs(PlayerState.allPlayers()) do
			if other ~= player then
				local otherState = PlayerState.get(other)
				local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if otherState and otherState.carried and otherRoot
					and (otherRoot.Position - root.Position).Magnitude <= TACKLE_RANGE then
					state.tackleCooldownUntil = os.clock() + Config.TACKLE_COOLDOWN
					local record = Stealing.dropCarried(other, false)
					-- The dropped brainrot returns to its owner's pad after 5 s.
					if record then
						task.delay(5, function()
							-- It was the victim's own if they bought it; find its home.
							-- Simplest honest rule: it goes back to the victim's first free pad.
							local victimState = PlayerState.get(other)
							if victimState and PlayerState.freePadIndex(other) then
								Stealing.BaseManager.placeBrainrot(other, PlayerState.freePadIndex(other), record)
							end
						end)
					end
					RemoteEvents.fireClient("Notify", player,
						"TACKLED " .. other.Name .. "! They dropped " .. (record and record.name or "it") .. ".",
						Color3.fromRGB(120, 255, 120))
					RemoteEvents.fireClient("Notify", other,
						player.Name .. " tackled you! Your brainrot dropped!",
						Color3.fromRGB(255, 100, 100))
					return
				end
			end
		end
	end
	-- Otherwise dash: a short speed burst.
	if os.clock() < state.dashCooldownUntil then
		return
	end
	state.dashCooldownUntil = os.clock() + Config.DASH_COOLDOWN
	state.dashUntil = os.clock() + Config.DASH_DURATION
	humanoid.WalkSpeed = Config.DASH_SPEED
	task.delay(Config.DASH_DURATION, function()
		applyCarrySpeed(player)
	end)
end

-- The F key: shield my base for 30 s (60 s cooldown).
function Stealing.activateLock(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if os.clock() < state.lockCooldownUntil then
		local left = math.ceil(state.lockCooldownUntil - os.clock())
		RemoteEvents.fireClient("Notify", player,
			"Lock recharging: " .. left .. "s left.", Color3.fromRGB(255, 200, 100))
		return
	end
	state.lockUntil = os.clock() + Config.LOCK_DURATION
	state.lockCooldownUntil = os.clock() + Config.LOCK_COOLDOWN
	RemoteEvents.fireClient("Notify", player,
		"BASE LOCKED for " .. Config.LOCK_DURATION .. "s! No one can steal from you.",
		Color3.fromRGB(120, 200, 255))
	RemoteEvents.fireClient("StateUpdate", player, PlayerState.snapshot(player))
end

-- Turret sweep: every second, a bought turret zaps a carrier inside the base.
function Stealing.turretTick()
	for _, player in ipairs(PlayerState.allPlayers()) do
		local state = PlayerState.get(player)
		if state and state.hasTurret and state.baseIndex >= 1 then
			local center = Stealing.BaseManager.getBaseCenter(player)
			if center then
				for _, other in ipairs(PlayerState.allPlayers()) do
					if other ~= player then
						local otherState = PlayerState.get(other)
						local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
						if otherState and otherState.carried and otherRoot
							and math.abs(otherRoot.Position.X - center.X) <= Config.BASE_SIZE / 2
							and math.abs(otherRoot.Position.Z - center.Z) <= Config.BASE_SIZE / 2 then
							Stealing.dropCarried(other, false)
							RemoteEvents.fireClient("Notify", other,
								"ZAPPED by " .. player.Name .. "'s turret! You dropped your brainrot.",
								Color3.fromRGB(255, 100, 100))
							RemoteEvents.fireClient("Notify", player,
								"Your turret zapped " .. other.Name .. "!",
								Color3.fromRGB(120, 255, 120))
						end
					end
				end
			end
		end
	end
end

function Stealing.isBaseLocked(player)
	local state = PlayerState.get(player)
	return state ~= nil and os.clock() < state.lockUntil
end

-- Clean up a leaving player's carried model.
function Stealing.cleanup(player)
	local model = Stealing.CarriedModels[player]
	if model and model.Parent ~= nil then
		model:Destroy()
	end
	Stealing.CarriedModels[player] = nil
end

startCarryLoop()

return Stealing
