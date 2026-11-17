-- WorldTags.luau — in-world pointers for the local player: a highlight box
-- on the pad the E key will act on, and a CARRIED tag above the brainrot in
-- your hands. Pure client-side rendering; the server owns the state.
-- Pads are real Parts in Workspace (Base1..Base8, Pad1..Pad8).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WorldTags = {}
WorldTags.Snapshot = nil
WorldTags.Placements = {}
WorldTags.Highlight = nil
WorldTags.CarryTag = nil

local GRAB_RANGE = 12

function WorldTags.init(_remoteEvents)
	local player = Players.LocalPlayer
	-- One reusable highlight box.
	local highlight = Instance.new("SelectionBox")
	highlight.Name = "PadHighlight"
	highlight.Color3 = Color3.fromRGB(120, 255, 120)
	highlight.LineThickness = 0.1
	highlight.SurfaceTransparency = 0.7
	highlight.Parent = Workspace
	WorldTags.Highlight = highlight

	-- One reusable CARRIED tag, re-parented to the carried model's body.
	local tag = Instance.new("BillboardGui")
	tag.Name = "CarriedTag"
	tag.Size = UDim2.fromOffset(160, 28)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = tag
	WorldTags.CarryTag = tag
	WorldTags.CarryLabel = label

	task.spawn(function()
		while true do
			WorldTags.refresh()
			task.wait(0.25)
		end
	end)
end

function WorldTags.update(snapshot)
	WorldTags.Snapshot = snapshot
end

function WorldTags.updatePlacements(placements)
	WorldTags.Placements = placements or {}
end

-- Find the pad Part for a base index and pad index, if it exists.
local function getPadPart(baseIndex, padIndex)
	local baseFolder = Workspace:FindFirstChild("Base" .. baseIndex)
	if not baseFolder then
		return nil
	end
	return baseFolder:FindFirstChild("Pad" .. padIndex)
end

-- The carried model: the Model whose body floats just above my head.
local function findCarriedModel(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local headPos = root.Position + Vector3.new(0, 4.5, 0)
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child.PrimaryPart then
			if (child.PrimaryPart.Position - headPos).Magnitude <= 6 then
				return child
			end
		end
	end
	return nil
end

function WorldTags.refresh()
	local player = Players.LocalPlayer
	local snapshot = WorldTags.Snapshot
	local highlight = WorldTags.Highlight
	if not highlight then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not snapshot or not root then
		highlight.Adornee = nil
		if WorldTags.CarryTag then
			WorldTags.CarryTag.Parent = nil
		end
		return
	end
	local pos = root.Position

	-- The CARRIED tag follows the brainrot in my hands.
	local carriedModel = nil
	if snapshot.carried then
		carriedModel = findCarriedModel(player)
		if carriedModel and WorldTags.CarryTag then
			WorldTags.CarryLabel.Text = "CARRIED: " .. snapshot.carried.name
			if WorldTags.CarryTag.Parent ~= carriedModel.PrimaryPart then
				WorldTags.CarryTag.Parent = carriedModel.PrimaryPart
			end
		end
	else
		if WorldTags.CarryTag then
			WorldTags.CarryTag.Parent = nil
		end
	end

	-- The pad highlight: green on a free pad of my base while I carry,
	-- yellow on the nearest stocked pad I can grab or steal from.
	local target = nil
	local targetColor = Color3.fromRGB(120, 255, 120)
	if snapshot.carried and snapshot.baseIndex and snapshot.baseIndex >= 1 then
		local bestDist = GRAB_RANGE
		for padIndex = 1, snapshot.padSlots or 4 do
			if not snapshot.pads or snapshot.pads[padIndex] == nil then
				local pad = getPadPart(snapshot.baseIndex, padIndex)
				if pad then
					local dist = (pad.Position - pos).Magnitude
					if dist <= bestDist then
						bestDist = dist
						target = pad
					end
				end
			end
		end
	else
		local bestDist = GRAB_RANGE
		for _, placement in ipairs(WorldTags.Placements) do
			local pad = getPadPart(placement.baseIndex, placement.padIndex)
			if pad then
				local dist = (pad.Position - pos).Magnitude
				if dist <= bestDist then
					bestDist = dist
					target = pad
					targetColor = Color3.fromRGB(255, 220, 80)
				end
			end
		end
	end
	if target then
		highlight.Adornee = target
		highlight.Color3 = targetColor
	else
		highlight.Adornee = nil
	end
end

return WorldTags
