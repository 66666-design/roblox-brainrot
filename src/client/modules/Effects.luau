-- Effects.luau — visual feedback only: the red flash and banner when the
-- Surge warns, and confetti when a hatch lands. No audio assets are used,
-- so nothing here can fail on a missing sound id.

local Players = game:GetService("Players")

local Effects = {}
Effects.Gui = nil
Effects.Flash = nil
Effects.Banner = nil

function Effects.init(_remoteEvents)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotEffects"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	Effects.Gui = gui

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = gui
	Effects.Flash = flash

	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.35)
	banner.Size = UDim2.new(0, 640, 0, 64)
	banner.BackgroundTransparency = 1
	banner.Text = ""
	banner.TextColor3 = Color3.fromRGB(255, 255, 255)
	banner.TextSize = 40
	banner.Font = Enum.Font.GothamBold
	banner.TextStrokeTransparency = 0.4
	banner.Parent = gui
	Effects.Banner = banner
end

-- A quick full-screen flash in the given colour.
local function flash(color)
	local frame = Effects.Flash
	if not frame then
		return
	end
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.25
	task.delay(0.1, function()
		for i = 1, 10 do
			if frame.Parent == nil then
				return
			end
			frame.BackgroundTransparency = 0.25 + (i / 10) * 0.75
			task.wait(0.05)
		end
	end)
end

-- A big centre banner that fades after a few seconds.
local function showBanner(text, color)
	local banner = Effects.Banner
	if not banner then
		return
	end
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	task.delay(3, function()
		if banner.Parent ~= nil then
			banner.Text = ""
		end
	end)
end

-- The Surge is coming: red flash plus a banner.
function Effects.onWaveWarning()
	flash(Color3.fromRGB(255, 60, 60))
	showBanner("SKIBIDI SURGE INCOMING!", Color3.fromRGB(255, 80, 80))
end

-- Confetti at a world position: small coloured parts that fall and fade.
local function confetti(position)
	local Workspace = game:GetService("Workspace")
	local colours = {
		Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 200, 40),
		Color3.fromRGB(120, 200, 80), Color3.fromRGB(80, 140, 255),
		Color3.fromRGB(170, 85, 255),
	}
	for _ = 1, 24 do
		local piece = Instance.new("Part")
		piece.Size = Vector3.new(0.4, 0.4, 0.4)
		piece.Color = colours[math.random(1, #colours)]
		piece.Material = Enum.Material.Neon
		piece.Anchored = true
		piece.CanCollide = false
		piece.CFrame = CFrame.new(position + Vector3.new(
			math.random(-3, 3), math.random(2, 5), math.random(-3, 3)))
		piece.Parent = Workspace
		task.spawn(function()
			for i = 1, 20 do
				if piece.Parent == nil then
					return
				end
				piece.CFrame = piece.CFrame * CFrame.new(0, -0.25, 0)
				piece.Transparency = i / 20
				task.wait(0.05)
			end
			if piece.Parent ~= nil then
				piece:Destroy()
			end
		end)
	end
end

-- React to server notifications: hatch confetti, rebirth banner.
function Effects.onNotify(message, _color)
	if not message or typeof(message) ~= "string" then
		return
	end
	local player = Players.LocalPlayer
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if string.sub(message, 1, 7) == "Hatched" and root then
		confetti(root.Position + Vector3.new(0, 3, 0))
	elseif string.sub(message, 1, 7) == "REBIRTH" then
		flash(Color3.fromRGB(255, 215, 0))
		showBanner(message, Color3.fromRGB(255, 215, 0))
	end
end

return Effects
