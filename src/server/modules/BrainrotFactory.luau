-- BrainrotFactory.luau — builds one brainrot character as a 3D Model.
-- A character is a body and a head in its own colours, a rarity-coloured
-- PointLight aura, and a name/rarity/$-per-second BillboardGui. Placed models
-- bob gently on an idle dance loop driven by one shared Heartbeat connection.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local BrainrotFactory = {}
BrainrotFactory.Bobbing = {} -- [model] = { parts = {{part, offset}}, base = CFrame, phase = number }

-- One part, configured the same way every time.
local function makePart(name, size, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	return part
end

-- Build a brainrot Model at the given CFrame. effectiveRate is the $/s the
-- label shows (already includes mutation and rebirth multipliers).
function BrainrotFactory.buildBrainrot(record, cframe, effectiveRate)
	local entry = Config.getCastById(record.castId) or Config.CAST[1]
	local tier = Config.getRarityIndex(record.rarity)
	local scale = 1 + 0.18 * (tier - 1) -- rarer characters stand taller
	local bodySize = Vector3.new(2 * scale, 2 * scale, 2 * scale)
	local headSize = Vector3.new(1.4 * scale, 1.4 * scale, 1.4 * scale)

	local model = Instance.new("Model")
	model.Name = record.name

	local body = makePart("Body", bodySize, entry.bodyColor, Enum.Material.SmoothPlastic, 0)
	body.CFrame = cframe
	body.Parent = model
	model.PrimaryPart = body

	local head = makePart("Head", headSize, entry.headColor, Enum.Material.SmoothPlastic, 0)
	head.CFrame = cframe * CFrame.new(0, (bodySize.Y + headSize.Y) / 2, 0)
	head.Parent = model

	-- A rarity-coloured aura light, so rare characters glow on their pad.
	local light = Instance.new("PointLight")
	light.Color = Config.getRarityColor(record.rarity)
	light.Brightness = 1
	light.Range = 8
	light.Parent = body

	-- The readable label: name, rarity, mutation and money per second.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(180, 56)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.2 * scale + 1.2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.fromScale(1, 0.45)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = record.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.fromScale(0, 0.45)
	rarityLabel.Size = UDim2.fromScale(1, 0.3)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = record.rarity .. " • " .. record.mutation
	rarityLabel.TextColor3 = Config.getRarityColor(record.rarity)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.fromScale(0, 0.75)
	rateLabel.Size = UDim2.fromScale(1, 0.25)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = string.format("$%d/s", math.floor(effectiveRate + 0.5))
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = billboard

	-- Register the idle bob: the body and head rise and fall together.
	BrainrotFactory.Bobbing[model] = {
		parts = {
			{ part = body, offset = CFrame.new(0, 0, 0) },
			{ part = head, offset = CFrame.new(0, (bodySize.Y + headSize.Y) / 2, 0) },
		},
		base = cframe,
		phase = math.random() * math.pi * 2,
	}
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			BrainrotFactory.Bobbing[model] = nil
		end
	end)

	return model
end

-- The single shared idle-dance loop: every registered model bobs and sways.
-- Started once by init.server.luau.
function BrainrotFactory.startBobLoop()
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		for model, data in pairs(BrainrotFactory.Bobbing) do
			if model.Parent == nil then
				BrainrotFactory.Bobbing[model] = nil
			else
				local bob = math.sin(clock * 2 + data.phase) * 0.3
				local sway = math.sin(clock * 0.8 + data.phase) * 0.15
				local base = data.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, 0)
				for _, item in ipairs(data.parts) do
					if item.part.Parent ~= nil then
						item.part.CFrame = base * item.offset
					end
				end
			end
		end
	end)
end

-- Re-point a bobbing model at a new base position (after a steal or a move).
function BrainrotFactory.setBaseCFrame(model, cframe)
	local data = BrainrotFactory.Bobbing[model]
	if data then
		data.base = cframe
	end
end

return BrainrotFactory
