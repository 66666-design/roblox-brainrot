-- HUD.luau — the ScreenGui over the 3D world: cash and income, the Surge
-- timer, the base panel, the key hints and the notification stack.
-- Kept clear of Roblox's own top-left menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local HUD = {}
HUD.Gui = nil
HUD.CashLabel = nil
HUD.WaveLabel = nil
HUD.WaveBar = nil
HUD.BasePanel = nil
HUD.PromptLabel = nil
HUD.NotifyFrame = nil
HUD.ShopButton = nil
HUD.RebirthButton = nil
HUD.RemoteEvents = nil
HUD.ShopUI = nil -- set by init to avoid a require cycle

local function makeLabel(name, parent, position, size, text, textColor, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 20
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.6
	label.Parent = parent
	return label
end

-- Income per second from a snapshot's pads (mirrors Economy on the server).
local function incomeRate(snapshot)
	local mult = 1 + Config.REBIRTH_MULT_PER * (snapshot.rebirths or 0)
	local baseSum = 0
	local othersSum = 0
	local taxmen = 0
	for _, pad in pairs(snapshot.pads or {}) do
		if pad then
			local rate = pad.rate * (pad.mutationMult or 1) * mult
			baseSum += rate
			if pad.name == "Fanum Taxman" then
				taxmen += 1
			else
				othersSum += rate
			end
		end
	end
	return baseSum + 0.05 * othersSum * taxmen
end

function HUD.init(remoteEvents)
	HUD.RemoteEvents = remoteEvents
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	HUD.Gui = gui

	-- Cash, top centre: big and always visible.
	HUD.CashLabel = makeLabel("Cash", gui,
		UDim2.new(0.5, -200, 0, 8), UDim2.new(400, 0, 0, 36),
		"$0  •  +$0/s", Color3.fromRGB(255, 255, 255), 28)
	HUD.CashLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Surge timer, top right: the wave countdown.
	HUD.WaveLabel = makeLabel("Wave", gui,
		UDim2.new(1, -260, 0, 8), UDim2.new(250, 0, 0, 30),
		"SKIBIDI SURGE 3:00", Color3.fromRGB(120, 200, 255), 20)
	HUD.WaveLabel.TextXAlignment = Enum.TextXAlignment.Right
	local waveBarBg = Instance.new("Frame")
	waveBarBg.Name = "WaveBarBg"
	waveBarBg.Position = UDim2.new(1, -260, 0, 40)
	waveBarBg.Size = UDim2.new(250, 0, 0, 8)
	waveBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	waveBarBg.BorderSizePixel = 0
	waveBarBg.Parent = gui
	HUD.WaveBar = Instance.new("Frame")
	HUD.WaveBar.Name = "WaveBar"
	HUD.WaveBar.Size = UDim2.fromScale(1, 1)
	HUD.WaveBar.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	HUD.WaveBar.BorderSizePixel = 0
	HUD.WaveBar.Parent = waveBarBg

	-- Shop button, top right under the wave timer.
	HUD.ShopButton = Instance.new("TextButton")
	HUD.ShopButton.Name = "ShopButton"
	HUD.ShopButton.Position = UDim2.new(1, -260, 0, 56)
	HUD.ShopButton.Size = UDim2.new(250, 0, 0, 36)
	HUD.ShopButton.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	HUD.ShopButton.Text = "SHOP  [B]"
	HUD.ShopButton.TextColor3 = Color3.fromRGB(60, 40, 0)
	HUD.ShopButton.TextSize = 20
	HUD.ShopButton.Font = Enum.Font.GothamBold
	HUD.ShopButton.Parent = gui

	-- Base panel, left side below the Roblox menu buttons.
	local panel = Instance.new("Frame")
	panel.Name = "BasePanel"
	panel.Position = UDim2.new(0, 12, 0, 64)
	panel.Size = UDim2.new(0, 220, 0, 150)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.35
	panel.BorderSizePixel = 0
	panel.Parent = gui
	HUD.BasePanel = panel
	HUD.PadLabel = makeLabel("Pads", panel,
		UDim2.new(0, 10, 0, 8), UDim2.new(200, 0, 0, 24),
		"Pads 0/4", Color3.fromRGB(255, 255, 255), 18)
	HUD.LockLabel = makeLabel("Lock", panel,
		UDim2.new(0, 10, 0, 36), UDim2.new(200, 0, 0, 24),
		"Lock: READY [F]", Color3.fromRGB(120, 200, 255), 18)
	HUD.TurretLabel = makeLabel("Turret", panel,
		UDim2.new(0, 10, 0, 64), UDim2.new(200, 0, 0, 24),
		"Turret: not bought ($500)", Color3.fromRGB(255, 255, 255), 18)
	HUD.AutoBankLabel = makeLabel("AutoBank", panel,
		UDim2.new(0, 10, 0, 92), UDim2.new(200, 0, 0, 24),
		"Auto-Bank: off ($250)", Color3.fromRGB(255, 255, 255), 18)
	HUD.RebirthButton = Instance.new("TextButton")
	HUD.RebirthButton.Name = "RebirthButton"
	HUD.RebirthButton.Position = UDim2.new(0, 10, 0, 118)
	HUD.RebirthButton.Size = UDim2.new(200, 0, 0, 26)
	HUD.RebirthButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	HUD.RebirthButton.Text = "REBIRTH  [R]  ($1000)"
	HUD.RebirthButton.TextColor3 = Color3.fromRGB(60, 40, 0)
	HUD.RebirthButton.TextSize = 16
	HUD.RebirthButton.Font = Enum.Font.GothamBold
	HUD.RebirthButton.Parent = panel

	-- Key hints, bottom centre.
	HUD.PromptLabel = makeLabel("Prompt", gui,
		UDim2.new(0.5, -300, 1, -44), UDim2.new(600, 0, 0, 28),
		"E — Grab / Place    Q — Dash / Tackle    F — Lock    R — Rebirth    B — Shop",
		Color3.fromRGB(230, 230, 230), 16)
	HUD.PromptLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Notifications, bottom right: newest on top, fading after 5 s.
	HUD.NotifyFrame = Instance.new("Frame")
	HUD.NotifyFrame.Name = "Notifications"
	HUD.NotifyFrame.Position = UDim2.new(1, -320, 1, -220)
	HUD.NotifyFrame.Size = UDim2.new(0, 310, 0, 170)
	HUD.NotifyFrame.BackgroundTransparency = 1
	HUD.NotifyFrame.Parent = gui

	HUD.ShopButton.MouseButton1Click:Connect(function()
		if HUD.ShopUI then
			HUD.ShopUI.toggle()
		end
	end)
	HUD.RebirthButton.MouseButton1Click:Connect(function()
		remoteEvents.Rebirth:FireServer()
	end)
end

-- Refresh every label from a state snapshot.
function HUD.update(snapshot)
	if not HUD.Gui then
		return
	end
	local rate = incomeRate(snapshot)
	HUD.CashLabel.Text = string.format("$%d  •  +$%d/s  •  pile $%d",
		snapshot.cash, math.floor(rate + 0.5), snapshot.unbanked or 0)
	local used = 0
	for _ in pairs(snapshot.pads or {}) do
		used += 1
	end
	HUD.PadLabel.Text = string.format("Pads %d/%d  •  Rebirths %d",
		used, snapshot.padSlots or 4, snapshot.rebirths or 0)
	if snapshot.lockSecondsLeft and snapshot.lockSecondsLeft > 0 then
		HUD.LockLabel.Text = string.format("Lock: SHIELD %ds", math.ceil(snapshot.lockSecondsLeft))
		HUD.LockLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	elseif snapshot.lockCooldownLeft and snapshot.lockCooldownLeft > 0 then
		HUD.LockLabel.Text = string.format("Lock: recharging %ds", math.ceil(snapshot.lockCooldownLeft))
		HUD.LockLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	else
		HUD.LockLabel.Text = "Lock: READY [F]"
		HUD.LockLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
	end
	if snapshot.hasTurret then
		HUD.TurretLabel.Text = "Turret: installed"
	else
		HUD.TurretLabel.Text = "Turret: not bought ($500)"
	end
	if snapshot.hasAutoBank then
		HUD.AutoBankLabel.Text = "Auto-Bank: ON"
	else
		HUD.AutoBankLabel.Text = "Auto-Bank: off ($250)"
	end
	if snapshot.carried then
		HUD.PromptLabel.Text = "Carrying " .. snapshot.carried.name
			.. " — walk to a free pad on your base and press E to place it!"
	else
		HUD.PromptLabel.Text = "E — Grab / Place    Q — Dash / Tackle    F — Lock    R — Rebirth    B — Shop"
	end
end

-- The Surge countdown bar and label.
function HUD.updateWave(data)
	if not HUD.Gui then
		return
	end
	local seconds = data.secondsLeft or 0
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	if data.warning then
		HUD.WaveLabel.Text = string.format("SURGE IN %d... DASH HOME!", seconds)
		HUD.WaveLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		HUD.WaveBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	else
		HUD.WaveLabel.Text = string.format("SKIBIDI SURGE %d:%02d", minutes, secs)
		HUD.WaveLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
		HUD.WaveBar.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	end
	local frac = math.clamp(seconds / 180, 0, 1)
	HUD.WaveBar.Size = UDim2.fromScale(frac, 1)
end

-- Push a notification onto the stack; it fades after 5 seconds.
function HUD.notify(message, color)
	if not HUD.NotifyFrame then
		return
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Text = message
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = 15
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Parent = HUD.NotifyFrame
	-- Newest on top: shift the older ones down.
	for _, child in ipairs(HUD.NotifyFrame:GetChildren()) do
		if child ~= label and child:IsA("TextLabel") then
			child.Position += UDim2.new(0, 0, 0, 32)
		end
	end
	task.delay(5, function()
		if label.Parent ~= nil then
			label:Destroy()
		end
	end)
	-- Cap the stack at five.
	local labels = {}
	for _, child in ipairs(HUD.NotifyFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > 5 then
		labels[#labels]:Destroy()
	end
end

return HUD
