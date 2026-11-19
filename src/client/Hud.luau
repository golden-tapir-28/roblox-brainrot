-- Hud: every pixel of Brainrot Bay's interface.
--
-- One ScreenGui over the 3D world. The money pill sits top-centre (never
-- the top-left corner, where Roblox's own menu buttons sit), the shop and
-- the lock and rebirth buttons sit on the right, toasts fade in at the
-- bottom, and the Noodle Rain banner hangs under the money while it rains.
-- The server owns the numbers; this module only shows them and asks the
-- server to act, through the callbacks the client entry wires up.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local Hud = {}

local function moneyText(n)
	-- 1,234,567 with commas, so big earnings stay readable.
	local s = tostring(math.floor(n))
	local out = ""
	while #s > 3 do
		out = "," .. s:sub(-3) .. out
		s = s:sub(1, -4)
	end
	return "$" .. s .. out
end

local function pillButton(parent, name, text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = 20
	b.Font = Enum.Font.SourceSansBold
	b.TextScaled = false
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	return b
end

local function sectionLabel(parent, text, y)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -16, 0, 24)
	l.Position = UDim2.new(0, 8, 0, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(255, 220, 100)
	l.TextSize = 17
	l.Font = Enum.Font.SourceSansBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

function Hud.build(callbacks)
	local player = game:GetService("Players").LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Money pill, top-centre.
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.AnchorPoint = Vector2.new(0.5, 0)
	moneyFrame.Position = UDim2.new(0.5, 0, 0, 12)
	moneyFrame.Size = UDim2.fromOffset(300, 64)
	moneyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	moneyFrame.BackgroundTransparency = 0.15
	moneyFrame.BorderSizePixel = 0
	moneyFrame.Parent = gui
	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 14)
	moneyCorner.Parent = moneyFrame

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "Money"
	moneyLabel.Size = UDim2.new(1, 0, 0.6, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Text = "$250"
	moneyLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	moneyLabel.TextSize = 30
	moneyLabel.Font = Enum.Font.SourceSansBold
	moneyLabel.Parent = moneyFrame

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Income"
	incomeLabel.Position = UDim2.new(0, 0, 0.6, 0)
	incomeLabel.Size = UDim2.new(1, 0, 0.4, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+$0/s"
	incomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	incomeLabel.TextSize = 17
	incomeLabel.Font = Enum.Font.SourceSans
	incomeLabel.Parent = moneyFrame

	-- Noodle Rain banner, under the money pill, hidden until it rains.
	local rainBanner = Instance.new("TextLabel")
	rainBanner.Name = "RainBanner"
	rainBanner.AnchorPoint = Vector2.new(0.5, 0)
	rainBanner.Position = UDim2.new(0.5, 0, 0, 84)
	rainBanner.Size = UDim2.fromOffset(320, 34)
	rainBanner.BackgroundColor3 = Color3.fromRGB(240, 200, 90)
	rainBanner.BorderSizePixel = 0
	rainBanner.Text = "NOODLE RAIN! Earnings x2!"
	rainBanner.TextColor3 = Color3.fromRGB(60, 30, 0)
	rainBanner.TextSize = 20
	rainBanner.Font = Enum.Font.SourceSansBold
	rainBanner.Visible = false
	rainBanner.Parent = gui
	local rainCorner = Instance.new("UICorner")
	rainCorner.CornerRadius = UDim.new(0, 10)
	rainCorner.Parent = rainBanner

	-- Right-side buttons: Shop, Lock, Rebirth.
	local shopButton = pillButton(gui, "ShopButton", "SHOP", UDim2.new(1, -124, 0, 12), UDim2.fromOffset(112, 44), Color3.fromRGB(60, 120, 220))
	local lockButton = pillButton(gui, "LockButton", "LOCK BASE", UDim2.new(1, -124, 0, 64), UDim2.fromOffset(112, 44), Color3.fromRGB(200, 90, 60))
	local rebirthButton = pillButton(gui, "RebirthButton", "REBIRTH", UDim2.new(1, -124, 0, 116), UDim2.fromOffset(112, 44), Color3.fromRGB(150, 80, 200))

	-- Shop panel, right side, hidden until the Shop button opens it.
	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "Shop"
	shopFrame.Position = UDim2.new(1, -336, 0, 168)
	shopFrame.Size = UDim2.fromOffset(324, 420)
	shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	shopFrame.BackgroundTransparency = 0.1
	shopFrame.BorderSizePixel = 0
	shopFrame.Visible = false
	shopFrame.Parent = gui
	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 12)
	shopCorner.Parent = shopFrame

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, -16, 0, 32)
	shopTitle.Position = UDim2.new(0, 8, 0, 6)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "SHOP — lures, upgrades, rebirth"
	shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopTitle.TextSize = 18
	shopTitle.Font = Enum.Font.SourceSansBold
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Parent = shopFrame

	local shopList = Instance.new("ScrollingFrame")
	shopList.Name = "ShopList"
	shopList.Position = UDim2.new(0, 8, 0, 44)
	shopList.Size = UDim2.new(1, -16, 1, -52)
	shopList.BackgroundTransparency = 1
	shopList.BorderSizePixel = 0
	shopList.ScrollBarThickness = 4
	shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopList.Parent = shopFrame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = shopList

	local function shopRow(labelText, priceText, onBuy)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 52)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.BorderSizePixel = 0
		row.Parent = shopList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -96, 0.55, 0)
		label.Position = UDim2.new(0, 8, 0, 2)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 15
		label.Font = Enum.Font.SourceSansBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		local price = Instance.new("TextLabel")
		price.Size = UDim2.new(1, -96, 0.4, 0)
		price.Position = UDim2.new(0, 8, 0.55, 0)
		price.BackgroundTransparency = 1
		price.Text = priceText
		price.TextColor3 = Color3.fromRGB(120, 255, 120)
		price.TextSize = 14
		price.Font = Enum.Font.SourceSans
		price.TextXAlignment = Enum.TextXAlignment.Left
		price.Parent = row
		local buy = Instance.new("TextButton")
		buy.Size = UDim2.fromOffset(80, 36)
		buy.Position = UDim2.new(1, -88, 0, 8)
		buy.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
		buy.BorderSizePixel = 0
		buy.Text = "BUY"
		buy.TextColor3 = Color3.fromRGB(255, 255, 255)
		buy.TextSize = 16
		buy.Font = Enum.Font.SourceSansBold
		buy.Parent = row
		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buy
		buy.MouseButton1Click:Connect(function()
			onBuy()
		end)
		return row
	end

	sectionLabel(shopList, "LURES — a brainrot parades next", 0)
	for _, lure in ipairs(BrainrotData.LURES) do
		shopRow(lure.label, moneyText(lure.cost) .. " — " .. lure.blurb, function()
			callbacks.buyLure(lure.id)
		end)
	end
	sectionLabel(shopList, "UPGRADES", 0)
	for _, up in ipairs(BrainrotData.UPGRADES) do
		shopRow(up.label, moneyText(BrainrotData.upgradeCost(up, 1)) .. " — " .. up.blurb, function()
			callbacks.buyUpgrade(up.id)
		end)
	end

	-- Bottom-left stats line.
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "Stats"
	statsLabel.AnchorPoint = Vector2.new(0, 1)
	statsLabel.Position = UDim2.new(0, 12, 1, -12)
	statsLabel.Size = UDim2.fromOffset(420, 22)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = ""
	statsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	statsLabel.TextSize = 15
	statsLabel.Font = Enum.Font.SourceSans
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = gui

	-- Catch hint, bottom-centre.
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 1)
	hintLabel.Position = UDim2.new(0.5, 0, 1, -12)
	hintLabel.Size = UDim2.fromOffset(560, 26)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Hold E near a brainrot on the conveyor to catch it — it earns money on your base!"
	hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	hintLabel.TextSize = 16
	hintLabel.Font = Enum.Font.SourceSansBold
	hintLabel.TextStrokeTransparency = 0.5
	hintLabel.Parent = gui

	-- Toasts, stacked above the hint.
	local toastFrame = Instance.new("Frame")
	toastFrame.Name = "Toasts"
	toastFrame.AnchorPoint = Vector2.new(0.5, 1)
	toastFrame.Position = UDim2.new(0.5, 0, 1, -44)
	toastFrame.Size = UDim2.fromOffset(560, 110)
	toastFrame.BackgroundTransparency = 1
	toastFrame.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 4)
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.Parent = toastFrame

	local handles = {}

	function handles.setMoney(money, incomePerSecond)
		moneyLabel.Text = moneyText(money)
		incomeLabel.Text = string.format("+$%d/s", incomePerSecond)
	end

	function handles.setRain(active)
		rainBanner.Visible = active
	end

	function handles.setLock(locked, readyIn)
		if locked then
			lockButton.Text = "LOCKED"
			lockButton.BackgroundColor3 = Color3.fromRGB(90, 160, 90)
		elseif readyIn > 0 then
			lockButton.Text = "LOCK " .. readyIn .. "s"
			lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		else
			lockButton.Text = "LOCK BASE"
			lockButton.BackgroundColor3 = Color3.fromRGB(200, 90, 60)
		end
	end

	function handles.setRebirth(cost, rebirths)
		if rebirths > 0 then
			rebirthButton.Text = string.format("REBIRTH %s (x%d)", moneyText(cost), rebirths)
		else
			rebirthButton.Text = "REBIRTH " .. moneyText(cost)
		end
	end

	function handles.setStats(catches, totalEarned, rebirths, slotsUsed, slotsMax)
		statsLabel.Text = string.format(
			"Caught: %d   •   Earned: %s   •   Rebirths: %d   •   Base: %d/%d slots",
			catches, moneyText(totalEarned), rebirths, slotsUsed, slotsMax
		)
	end

	function handles.toast(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 26)
		label.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		label.BackgroundTransparency = 0.2
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 240, 180)
		label.TextSize = 16
		label.Font = Enum.Font.SourceSansBold
		label.Parent = toastFrame
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = label
		task.delay(6, function()
			label:Destroy()
		end)
	end

	shopButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
		callbacks.click()
	end)
	lockButton.MouseButton1Click:Connect(function()
		callbacks.lockBase()
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		callbacks.rebirth()
	end)

	return handles
end

return Hud
