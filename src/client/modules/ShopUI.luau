-- ShopUI.luau — the shop and hatch panel: the full cast gallery with name,
-- rarity, money per second and price, the Rot-O-Matic hatch button, and the
-- rebirth, turret and Auto-Bank upgrades. Toggled with B or the SHOP button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ShopUI = {}
ShopUI.Gui = nil
ShopUI.Panel = nil
ShopUI.RemoteEvents = nil
ShopUI.CashLabel = nil
ShopUI.BuyButtons = {} -- [castId] = TextButton

function ShopUI.init(remoteEvents)
	ShopUI.RemoteEvents = remoteEvents
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotShop"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	ShopUI.Gui = gui

	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 620, 0, 460)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 2
	panel.BorderColor3 = Color3.fromRGB(255, 200, 40)
	panel.Visible = false
	panel.Parent = gui
	ShopUI.Panel = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.new(0, 0, 0, 0)
	title.Size = UDim2.new(1, 0, 0, 36)
	title.BackgroundTransparency = 1
	title.Text = "ROT-O-MATIC  •  SHOP"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	ShopUI.CashLabel = Instance.new("TextLabel")
	ShopUI.CashLabel.Name = "Cash"
	ShopUI.CashLabel.Position = UDim2.new(0, 0, 0, 36)
	ShopUI.CashLabel.Size = UDim2.new(1, 0, 0, 24)
	ShopUI.CashLabel.BackgroundTransparency = 1
	ShopUI.CashLabel.Text = "Cash: $0"
	ShopUI.CashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ShopUI.CashLabel.TextSize = 18
	ShopUI.CashLabel.Font = Enum.Font.GothamBold
	ShopUI.CashLabel.Parent = panel

	local hatchButton = Instance.new("TextButton")
	hatchButton.Name = "HatchButton"
	hatchButton.Position = UDim2.new(0, 12, 0, 64)
	hatchButton.Size = UDim2.new(1, -24, 0, 40)
	hatchButton.BackgroundColor3 = Color3.fromRGB(255, 120, 160)
	hatchButton.Text = "HATCH AT THE ROT-O-MATIC  —  $50  (random brainrot!)"
	hatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	hatchButton.TextSize = 18
	hatchButton.Font = Enum.Font.GothamBold
	hatchButton.Parent = panel
	hatchButton.MouseButton1Click:Connect(function()
		remoteEvents.Hatch:FireServer()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "CastList"
	scroll.Position = UDim2.new(0, 12, 0, 112)
	scroll.Size = UDim2.new(1, -24, 0, 260)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, #Config.CAST * 44)
	scroll.Parent = panel

	for i, entry in ipairs(Config.CAST) do
		local card = Instance.new("Frame")
		card.Name = entry.id
		card.Position = UDim2.new(0, 0, 0, (i - 1) * 44)
		card.Size = UDim2.new(1, 0, 0, 40)
		card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		card.BorderSizePixel = 0
		card.Parent = scroll

		local rarityDot = Instance.new("Frame")
		rarityDot.Name = "RarityDot"
		rarityDot.Position = UDim2.new(0, 6, 0, 12)
		rarityDot.Size = UDim2.new(0, 16, 0, 16)
		rarityDot.BackgroundColor3 = Config.getRarityColor(entry.rarity)
		rarityDot.BorderSizePixel = 0
		rarityDot.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Position = UDim2.new(0, 30, 0, 0)
		nameLabel.Size = UDim2.new(0, 220, 0, 40)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Name = "Info"
		infoLabel.Position = UDim2.new(0, 250, 0, 0)
		infoLabel.Size = UDim2.new(0, 190, 0, 40)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = entry.rarity .. "  •  $" .. entry.rate .. "/s"
		infoLabel.TextColor3 = Config.getRarityColor(entry.rarity)
		infoLabel.TextSize = 15
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.Parent = card

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Position = UDim2.new(1, -110, 0, 5)
		buyButton.Size = UDim2.new(0, 100, 0, 30)
		buyButton.BackgroundColor3 = Color3.fromRGB(120, 200, 80)
		buyButton.Text = "BUY $" .. entry.price
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 15
		buyButton.Font = Enum.Font.GothamBold
		buyButton.Parent = card
		buyButton.MouseButton1Click:Connect(function()
			remoteEvents.Buy:FireServer(entry.id)
		end)
		ShopUI.BuyButtons[entry.id] = buyButton
	end

	-- Upgrades row at the bottom of the panel.
	local upgrades = Instance.new("Frame")
	upgrades.Name = "Upgrades"
	upgrades.Position = UDim2.new(0, 12, 0, 384)
	upgrades.Size = UDim2.new(1, -24, 0, 64)
	upgrades.BackgroundTransparency = 1
	upgrades.Parent = panel

	local function upgradeButton(name, text, x)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Position = UDim2.new(0, x, 0, 0)
		button.Size = UDim2.new(0, 190, 0, 30)
		button.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
		button.Text = text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 14
		button.Font = Enum.Font.GothamBold
		button.Parent = upgrades
		return button
	end

	local rebirthButton = upgradeButton("RebirthButton", "REBIRTH  ($1000)", 0)
	rebirthButton.MouseButton1Click:Connect(function()
		remoteEvents.Rebirth:FireServer()
	end)
	local turretButton = upgradeButton("TurretButton", "LASER TURRET  ($500)", 200)
	turretButton.MouseButton1Click:Connect(function()
		remoteEvents.BuyTurret:FireServer()
	end)
	local autoBankButton = upgradeButton("AutoBankButton", "AUTO-BANK  ($250)", 400)
	autoBankButton.MouseButton1Click:Connect(function()
		remoteEvents.BuyAutoBank:FireServer()
	end)

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Position = UDim2.new(1, -40, 0, 4)
	closeButton.Size = UDim2.new(0, 32, 0, 32)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = panel
	closeButton.MouseButton1Click:Connect(function()
		ShopUI.Panel.Visible = false
	end)
end

function ShopUI.toggle()
	if ShopUI.Panel then
		ShopUI.Panel.Visible = not ShopUI.Panel.Visible
	end
end

-- Refresh the cash label and grey out what the player cannot afford.
function ShopUI.update(snapshot)
	if not ShopUI.Panel or not snapshot then
		return
	end
	ShopUI.CashLabel.Text = "Cash: $" .. snapshot.cash
	for _, entry in ipairs(Config.CAST) do
		local button = ShopUI.BuyButtons[entry.id]
		if button then
			if snapshot.cash >= entry.price then
				button.BackgroundColor3 = Color3.fromRGB(120, 200, 80)
			else
				button.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
			end
		end
	end
end

return ShopUI
