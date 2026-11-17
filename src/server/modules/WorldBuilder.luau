-- WorldBuilder.luau — builds the 3D world procedurally at server start.
-- The place file only holds the baseplate; everything else (spawn island,
-- promenade, Rot-O-Matic, shop, shrine, lagoon, billboards, palms and the
-- Surge gate) is built here by code, so the scripts account for the world
-- the screenshots show. Everything is flat and walkable: no step is higher
-- than 1 stud, so players never need to jump to get around.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

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

-- A sign on the front face of a part: big readable text.
local function addSign(part, text, textColor, size)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Sign"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = surface
	return label
end

-- A palm tree: brown trunk and a green ball crown.
local function makePalm(x, z)
	local trunk = makePart("PalmTrunk", Vector3.new(2, 12, 2),
		Color3.fromRGB(140, 100, 60), Enum.Material.Wood, 0)
	trunk.CFrame = CFrame.new(x, 6, z)
	trunk.Parent = Workspace
	local crown = makePart("PalmCrown", Vector3.new(9, 5, 9),
		Color3.fromRGB(60, 180, 80), Enum.Material.SmoothPlastic, 0)
	crown.Shape = Enum.PartType.Ball
	crown.CFrame = CFrame.new(x, 14, z)
	crown.Parent = Workspace
end

-- A big meme billboard facing the centre of the map.
local function makeBillboard(text, x, z, yaw)
	local board = makePart("Billboard", Vector3.new(24, 12, 1),
		Color3.fromRGB(40, 40, 50), Enum.Material.SmoothPlastic, 0)
	board.CFrame = CFrame.new(x, 8, z) * CFrame.Angles(0, yaw, 0)
	board.Parent = Workspace
	addSign(board, text, Color3.fromRGB(255, 230, 80), 24)
end

function WorldBuilder.build()
	-- A sunny afternoon: warm, bright, sun-soaked.
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(120, 120, 120)

	-- Spawn island: a flat 60x60 plaza at the south edge, top at y = 0.5.
	local island = makePart("SpawnIsland", Vector3.new(60, 0.5, 60),
		Color3.fromRGB(240, 220, 180), Enum.Material.Sand, 0)
	island.CFrame = CFrame.new(0, 0.25, 200)
	island.Parent = Workspace
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.CFrame = CFrame.new(0, 1, 200)
	spawn.Parent = Workspace

	-- Bridge from the island to the promenade: flat, 10 wide, top at y = 0.5.
	local bridge = makePart("Bridge", Vector3.new(10, 0.5, 130),
		Color3.fromRGB(180, 140, 90), Enum.Material.Wood, 0)
	bridge.CFrame = CFrame.new(0, 0.25, 105)
	bridge.Parent = Workspace

	-- The Rotway promenade: a 120x120 plaza at the centre, top at y = 0.5.
	local border = makePart("PromenadeBorder", Vector3.new(126, 0.3, 126),
		Color3.fromRGB(255, 120, 160), Enum.Material.SmoothPlastic, 0)
	border.CFrame = CFrame.new(0, 0.15, 0)
	border.Parent = Workspace
	local plaza = makePart("Promenade", Vector3.new(120, 0.5, 120),
		Color3.fromRGB(245, 230, 200), Enum.Material.Sand, 0)
	plaza.CFrame = CFrame.new(0, 0.25, 0)
	plaza.Parent = Workspace

	-- Rot-O-Matic 3000: the hatch machine, front facing the spawn (south).
	local rotomatic = makePart("RotOMatic", Vector3.new(10, 8, 6),
		Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, 0)
	rotomatic.CFrame = CFrame.new(0, 4.5, -15)
	rotomatic.Parent = Workspace
	local rotTop = makePart("RotOMaticTop", Vector3.new(11, 1, 7),
		Color3.fromRGB(255, 80, 80), Enum.Material.Neon, 0)
	rotTop.CFrame = CFrame.new(0, 9, -15)
	rotTop.Parent = Workspace
	addSign(rotomatic, "ROT-O-MATIC 3000\nHATCH $50", Color3.fromRGB(60, 40, 0), 24)

	-- Shop kiosk, west of the Rot-O-Matic.
	local shop = makePart("ShopKiosk", Vector3.new(8, 6, 6),
		Color3.fromRGB(80, 140, 255), Enum.Material.SmoothPlastic, 0)
	shop.CFrame = CFrame.new(-20, 3.5, -15)
	shop.Parent = Workspace
	addSign(shop, "SHOP", Color3.fromRGB(255, 255, 255), 24)

	-- Rebirth Shrine, east of the Rot-O-Matic: a glowing gold platform.
	local shrine = makePart("RebirthShrine", Vector3.new(8, 1, 8),
		Color3.fromRGB(255, 215, 0), Enum.Material.Neon, 0)
	shrine.CFrame = CFrame.new(20, 1, -15)
	shrine.Parent = Workspace
	addSign(shrine, "REBIRTH\nSHRINE", Color3.fromRGB(120, 80, 0), 24)

	-- The lagoon: a blue pool east of the promenade, decorative.
	local lagoon = makePart("Lagoon", Vector3.new(80, 0.5, 60),
		Color3.fromRGB(60, 160, 230), Enum.Material.Glass, 0.25)
	lagoon.CFrame = CFrame.new(70, 0.25, 50)
	lagoon.Parent = Workspace

	-- Meme billboards around the map, facing the centre.
	makeBillboard("ONLY IN OHIO", -210, 0, math.rad(90))
	makeBillboard("SKIBIDI", 210, 0, math.rad(-90))
	makeBillboard("RIZZ", 0, -210, math.rad(180))

	-- Palm trees on the promenade corners.
	makePalm(-50, -50)
	makePalm(50, -50)
	makePalm(-50, 50)
	makePalm(50, 50)

	-- Surge gate: two pillars and a beam at the north edge, where the wave enters.
	local pillarL = makePart("SurgeGateL", Vector3.new(4, 20, 4),
		Color3.fromRGB(120, 200, 255), Enum.Material.Neon, 0.2)
	pillarL.CFrame = CFrame.new(-15, 10, -240)
	pillarL.Parent = Workspace
	local pillarR = makePart("SurgeGateR", Vector3.new(4, 20, 4),
		Color3.fromRGB(120, 200, 255), Enum.Material.Neon, 0.2)
	pillarR.CFrame = CFrame.new(15, 10, -240)
	pillarR.Parent = Workspace
	local beam = makePart("SurgeGateBeam", Vector3.new(34, 4, 4),
		Color3.fromRGB(120, 200, 255), Enum.Material.Neon, 0.2)
	beam.CFrame = CFrame.new(0, 20, -240)
	beam.Parent = Workspace
	addSign(beam, "SURGE GATE", Color3.fromRGB(255, 255, 255), 24)

	return {
		spawnCenter = Vector3.new(0, 0, 200),
	}
end

return WorldBuilder
