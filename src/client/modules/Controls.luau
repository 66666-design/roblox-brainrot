-- Controls.luau — keyboard bindings through ContextActionService.
-- Roblox's default camera scripts own the arrow keys, so actions are bound
-- here (never through InputBegan with gameProcessedEvent, which never sees
-- them). E grabs or places, Q dashes or tackles, F locks the base, R
-- rebirths, B toggles the shop.

local ContextActionService = game:GetService("ContextActionService")

local Controls = {}
Controls.RemoteEvents = nil
Controls.ShopUI = nil -- set by init.client.luau

local function onBegin(remoteName)
	return function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			local event = Controls.RemoteEvents and Controls.RemoteEvents[remoteName]
			if event then
				event:FireServer()
			end
		end
	end
end

function Controls.init(remoteEvents)
	Controls.RemoteEvents = remoteEvents
	ContextActionService:BindAction("BrainrotInteract", onBegin("Interact"), false, Enum.KeyCode.E)
	ContextActionService:BindAction("BrainrotDash", onBegin("Dash"), false, Enum.KeyCode.Q)
	ContextActionService:BindAction("BrainrotLock", onBegin("Lock"), false, Enum.KeyCode.F)
	ContextActionService:BindAction("BrainrotRebirth", onBegin("Rebirth"), false, Enum.KeyCode.R)
	ContextActionService:BindAction("BrainrotShop", function(_, inputState)
		if inputState == Enum.UserInputState.Begin and Controls.ShopUI then
			Controls.ShopUI.toggle()
		end
	end, false, Enum.KeyCode.B)
end

return Controls
