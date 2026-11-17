-- Leaderboard.luau — the in-world rich list. A board on the promenade shows
-- the five richest players by banked cash, refreshed every 10 seconds.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerState = require(script.Parent.PlayerState)

local Leaderboard = {}
Leaderboard.Labels = {}

-- Build the board: a dark slab with a SurfaceGui and five name rows.
function Leaderboard.build()
	local board = Instance.new("Part")
	board.Name = "RichListBoard"
	board.Size = Vector3.new(16, 10, 1)
	board.Color = Color3.fromRGB(30, 30, 40)
	board.Material = Enum.Material.SmoothPlastic
	board.Anchored = true
	board.CanCollide = true
	board.CFrame = CFrame.new(30, 5.5, -25) * CFrame.Angles(0, math.rad(180), 0)
	board.Parent = Workspace

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = board

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "RICHEST BEACHGOERS"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = surface

	for i = 1, 5 do
		local row = Instance.new("TextLabel")
		row.Name = "Row" .. i
		row.Position = UDim2.new(0, 0, 0, 30 + (i - 1) * 26)
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.Text = ""
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextScaled = true
		row.Font = Enum.Font.Gotham
		row.Parent = surface
		Leaderboard.Labels[i] = row
	end
end

-- Refresh the five rows from the current cash standings.
function Leaderboard.refresh()
	local standings = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.get(player)
		if state then
			table.insert(standings, { name = player.Name, cash = state.cash })
		end
	end
	table.sort(standings, function(a, b)
		return a.cash > b.cash
	end)
	for i = 1, 5 do
		local label = Leaderboard.Labels[i]
		if label then
			local entry = standings[i]
			if entry then
				label.Text = string.format("%d. %s  $%d", i, entry.name, entry.cash)
			else
				label.Text = ""
			end
		end
	end
end

-- Refresh every 10 seconds. Started once by init.server.luau.
function Leaderboard.startLoop()
	task.spawn(function()
		while true do
			Leaderboard.refresh()
			task.wait(10)
		end
	end)
end

return Leaderboard
