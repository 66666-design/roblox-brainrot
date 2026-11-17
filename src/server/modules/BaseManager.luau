-- BaseManager.luau — the eight beach base plots, their pads and cash piles.
-- Builds every plot once at server start, assigns one per player, and owns
-- the placed brainrot models: placing, removing and the live placement
-- broadcast every client renders labels from.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteEvents = require(script.Parent.RemoteEvents)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local BaseManager = {}
BaseManager.Plots = {} -- [plotIndex] = { center, owner, platform, pads, pile, pileLabel, sign, console, turret }
BaseManager.PlacedModels = {} -- [player] = { [padIndex] = Model }

local PLOT_Y = 1 -- platform top height; a 1-stud step is walkable, the baseplate top is y = 0
local PAD_TOP = PLOT_Y + 0.5

-- Pad offsets on a plot: 4 columns by 2 rows, pad 1..8.
local PAD_OFFSETS = {
	Vector3.new(-12, 0, -8), Vector3.new(-4, 0, -8), Vector3.new(4, 0, -8), Vector3.new(12, 0, -8),
	Vector3.new(-12, 0, 8), Vector3.new(-4, 0, 8), Vector3.new(4, 0, 8), Vector3.new(12, 0, 8),
}

local function makePart(name, size, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	return part
end

-- Centre of plot i (1..8) on the ring around the promenade.
function BaseManager.getPlotCenter(index)
	local angle = math.rad((index - 1) * 45)
	return Vector3.new(
		Config.BASE_RADIUS * math.cos(angle),
		0,
		Config.BASE_RADIUS * math.sin(angle)
	)
end

-- World CFrame for the body of a brainrot standing on a pad.
function BaseManager.getPadCFrame(player, padIndex)
	local state = PlayerState.get(player)
	if not state or state.baseIndex < 1 then
		return nil
	end
	local plot = BaseManager.Plots[state.baseIndex]
	if not plot then
		return nil
	end
	local offset = PAD_OFFSETS[padIndex]
	if not offset then
		return nil
	end
	local record = state.pads[padIndex]
	local scale = 1
	if record then
		scale = 1 + 0.18 * (Config.getRarityIndex(record.rarity) - 1)
	end
	local pos = plot.center + offset + Vector3.new(0, PAD_TOP + scale, 0)
	return CFrame.new(pos)
end

-- Build one empty plot: platform, trim, 8 pads, cash pile, lock console,
-- owner sign. The sign reads EMPTY BASE until a player claims the plot.
local function buildPlot(index)
	local center = BaseManager.getPlotCenter(index)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = Workspace

	local platform = makePart("Platform", Vector3.new(Config.BASE_SIZE, PLOT_Y, Config.BASE_SIZE),
		Color3.fromRGB(230, 210, 170), Enum.Material.Sand, 0)
	platform.CFrame = CFrame.new(center + Vector3.new(0, PLOT_Y / 2, 0))
	platform.Parent = folder

	local trim = makePart("Trim", Vector3.new(Config.BASE_SIZE + 2, 0.4, Config.BASE_SIZE + 2),
		Color3.fromRGB(90, 160, 220), Enum.Material.SmoothPlastic, 0)
	trim.CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0))
	trim.Parent = folder

	local pads = {}
	for i, offset in ipairs(PAD_OFFSETS) do
		local pad = makePart("Pad" .. i, Vector3.new(6, 0.5, 6),
			Color3.fromRGB(200, 200, 210), Enum.Material.SmoothPlastic, 0)
		pad.CFrame = CFrame.new(center + offset + Vector3.new(0, PLOT_Y + 0.25, 0))
		pad.Parent = folder
		pads[i] = pad
	end

	-- Cash pile: a gold block by the plot's inner edge, with a live label.
	local towardCenter = (Vector3.new(0, 0, 0) - center).Unit
	local pile = makePart("CashPile", Vector3.new(4, 2, 4),
		Color3.fromRGB(255, 210, 60), Enum.Material.Neon, 0)
	pile.CFrame = CFrame.new(center + towardCenter * 16 + Vector3.new(0, PLOT_Y + 1, 0))
	pile.Parent = folder
	local pileBillboard = Instance.new("BillboardGui")
	pileBillboard.Name = "PileLabel"
	pileBillboard.Size = UDim2.fromOffset(120, 30)
	pileBillboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	pileBillboard.Parent = pile
	local pileText = Instance.new("TextLabel")
	pileText.Name = "Amount"
	pileText.Size = UDim2.fromScale(1, 1)
	pileText.BackgroundTransparency = 1
	pileText.Text = "$0"
	pileText.TextColor3 = Color3.fromRGB(255, 230, 100)
	pileText.TextScaled = true
	pileText.Font = Enum.Font.GothamBold
	pileText.Parent = pileBillboard

	-- Lock console: a dark post at the plot corner. Press F nearby to shield.
	local console = makePart("LockConsole", Vector3.new(2, 4, 2),
		Color3.fromRGB(40, 40, 50), Enum.Material.Metal, 0)
	console.CFrame = CFrame.new(center + Vector3.new(16, PLOT_Y + 2, -16))
	console.Parent = folder
	local consoleBillboard = Instance.new("BillboardGui")
	consoleBillboard.Name = "ConsoleLabel"
	consoleBillboard.Size = UDim2.fromOffset(140, 30)
	consoleBillboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	consoleBillboard.Parent = console
	local consoleText = Instance.new("TextLabel")
	consoleText.Name = "Hint"
	consoleText.Size = UDim2.fromScale(1, 1)
	consoleText.BackgroundTransparency = 1
	consoleText.Text = "LOCK  [F]"
	consoleText.TextColor3 = Color3.fromRGB(160, 220, 255)
	consoleText.TextScaled = true
	consoleText.Font = Enum.Font.GothamBold
	consoleText.Parent = consoleBillboard

	-- Owner sign: a tall post at the inner edge with a SurfaceGui name plate.
	local sign = makePart("Sign", Vector3.new(6, 8, 0.5),
		Color3.fromRGB(60, 60, 70), Enum.Material.Wood, 0)
	sign.CFrame = CFrame.new(center + towardCenter * 19 + Vector3.new(0, PLOT_Y + 4, 0))
		* CFrame.Angles(0, math.atan2(-towardCenter.X, -towardCenter.Z), 0)
	sign.Parent = folder
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Name = "OwnerName"
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "EMPTY BASE"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.Parent = surface

	BaseManager.Plots[index] = {
		center = center,
		owner = nil,
		folder = folder,
		platform = platform,
		pads = pads,
		pile = pile,
		pileLabel = pileText,
		sign = sign,
		signText = signText,
		console = console,
		turret = nil,
	}
end

-- Build all eight plots. Called once by init.server.luau.
function BaseManager.buildPlots()
	for i = 1, Config.BASE_COUNT do
		buildPlot(i)
	end
end

-- Claim the first free plot for a player and write their name on its sign.
function BaseManager.assignBase(player)
	local state = PlayerState.get(player)
	if not state then
		return 0
	end
	for i = 1, Config.BASE_COUNT do
		local plot = BaseManager.Plots[i]
		if plot and plot.owner == nil then
			plot.owner = player
			state.baseIndex = i
			plot.signText.Text = player.Name .. "'s BASE"
			-- Walking over the pile banks it. Debounced per player.
			local lastBank = 0
			plot.pile.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then
					return
				end
				local toucher = Players:GetPlayerFromCharacter(character)
				if toucher ~= player then
					return
				end
				if os.clock() - lastBank < 1 then
					return
				end
				lastBank = os.clock()
				local banked = PlayerState.bankPile(player)
				if banked > 0 then
					RemoteEvents.fireClient("Notify", player,
						string.format("Banked $%d from your pile!", banked),
						Color3.fromRGB(120, 255, 120))
				end
			end)
			return i
		end
	end
	return 0
end

-- Free a player's plot when they leave: remove their brainrots, clear the sign.
function BaseManager.freeBase(player)
	local state = PlayerState.get(player)
	if state and state.baseIndex >= 1 then
		local plot = BaseManager.Plots[state.baseIndex]
		if plot then
			plot.owner = nil
			plot.signText.Text = "EMPTY BASE"
		end
	end
	local models = BaseManager.PlacedModels[player]
	if models then
		for _, model in pairs(models) do
			if model.Parent ~= nil then
				model:Destroy()
			end
		end
		BaseManager.PlacedModels[player] = nil
	end
	if state then
		state.baseIndex = 0
	end
end

-- Place a brainrot record on a pad and build its model there.
function BaseManager.placeBrainrot(player, padIndex, record)
	local state = PlayerState.get(player)
	if not state then
		return false
	end
	local cframe = BaseManager.getPadCFrame(player, padIndex)
	if not cframe then
		return false
	end
	if not PlayerState.placeOnPad(player, padIndex, record) then
		return false
	end
	local mult = PlayerState.getRebirthMultiplier(player)
	local effective = Config.effectiveRate(
		{ rate = record.rate },
		record.mutationMult,
		state.rebirths
	)
	local model = BrainrotFactory.buildBrainrot(record, cframe, effective)
	model.Parent = Workspace
	if not BaseManager.PlacedModels[player] then
		BaseManager.PlacedModels[player] = {}
	end
	BaseManager.PlacedModels[player][padIndex] = model
	BaseManager.broadcastPlacements()
	return true
end

-- Remove a brainrot from a pad and return its record.
function BaseManager.removeBrainrot(player, padIndex)
	local record = PlayerState.removeFromPad(player, padIndex)
	if not record then
		return nil
	end
	local models = BaseManager.PlacedModels[player]
	if models and models[padIndex] then
		local model = models[padIndex]
		models[padIndex] = nil
		if model.Parent ~= nil then
			model:Destroy()
		end
	end
	BaseManager.broadcastPlacements()
	return record
end

-- Is this world position inside a player's own base plot?
function BaseManager.isInOwnBase(player, position)
	local state = PlayerState.get(player)
	if not state or state.baseIndex < 1 then
		return false
	end
	local plot = BaseManager.Plots[state.baseIndex]
	if not plot then
		return false
	end
	local half = Config.BASE_SIZE / 2
	return math.abs(position.X - plot.center.X) <= half
		and math.abs(position.Z - plot.center.Z) <= half
end

function BaseManager.getBaseCenter(player)
	local state = PlayerState.get(player)
	if not state or state.baseIndex < 1 then
		return nil
	end
	local plot = BaseManager.Plots[state.baseIndex]
	if not plot then
		return nil
	end
	return plot.center
end

-- Refresh the cash pile label for one player.
function BaseManager.updatePileLabel(player)
	local state = PlayerState.get(player)
	if not state or state.baseIndex < 1 then
		return
	end
	local plot = BaseManager.Plots[state.baseIndex]
	if plot and plot.pileLabel then
		plot.pileLabel.Text = string.format("$%d", math.floor(state.unbanked))
	end
end

-- Buy the laser turret for a player's base: a tower that zaps carriers.
function BaseManager.buyTurret(player)
	local state = PlayerState.get(player)
	if not state or state.baseIndex < 1 or state.hasTurret then
		return false
	end
	if not PlayerState.spendCash(player, Config.TURRET_COST) then
		return false
	end
	state.hasTurret = true
	local plot = BaseManager.Plots[state.baseIndex]
	local center = plot.center
	local tower = makePart("Turret", Vector3.new(3, 6, 3),
		Color3.fromRGB(80, 80, 90), Enum.Material.Metal, 0)
	tower.CFrame = CFrame.new(center + Vector3.new(-16, PLOT_Y + 3, 16))
	tower.Parent = plot.folder
	local barrel = makePart("TurretBarrel", Vector3.new(1, 1, 4),
		Color3.fromRGB(255, 80, 80), Enum.Material.Neon, 0)
	barrel.CFrame = CFrame.new(center + Vector3.new(-16, PLOT_Y + 5, 16))
	barrel.Parent = plot.folder
	plot.turret = tower
	return true
end

-- Every placed brainrot in the game, for the client labels.
function BaseManager.getAllPlacements()
	local list = {}
	for _, player in ipairs(PlayerState.allPlayers()) do
		local state = PlayerState.get(player)
		if state and state.baseIndex >= 1 then
			for padIndex, record in pairs(state.pads) do
				if record then
					table.insert(list, {
						playerName = player.Name,
						baseIndex = state.baseIndex,
						padIndex = padIndex,
						name = record.name,
						rarity = record.rarity,
						rate = record.rate,
						mutation = record.mutation,
						mutationMult = record.mutationMult,
						rebirths = state.rebirths,
					})
				end
			end
		end
	end
	return list
end

function BaseManager.broadcastPlacements()
	RemoteEvents.fireAll("Placements", BaseManager.getAllPlacements())
end

return BaseManager
