-- WorldBuilder: builds the moving things in Brainrot Bay.
--
-- The static world (plaza, conveyor, plots, trees) lives in the Rojo
-- project file. This module builds what moves: each brainrot's blocky
-- character model with its hat and its name/rarity/$-per-second label, the
-- Greedy Seagull, and the owner sign on each base plot.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local WorldBuilder = {}

local HAT_COLORS = {
	TopHat = Color3.fromRGB(30, 30, 35),
	Crown = Color3.fromRGB(255, 210, 60),
	Cap = Color3.fromRGB(220, 60, 60),
	Wizard = Color3.fromRGB(110, 60, 180),
}

-- Where the eight plots sit, matching the generator in tools/gen-world.mjs.
local PLOT_RADIUS = 58
function WorldBuilder.plotPosition(index)
	local a = (index * math.pi) / 4 + math.pi / 8
	return Vector3.new(math.cos(a) * PLOT_RADIUS, 0, math.sin(a) * PLOT_RADIUS)
end

-- The six slot positions on a plot, matching the generator's slot pads.
function WorldBuilder.slotPosition(plotIndex, slot)
	local center = WorldBuilder.plotPosition(plotIndex)
	local row = math.floor(slot / 3)
	local col = slot % 3
	return Vector3.new(center.X + (col - 1) * 4.4, 1.1, center.Z + (row - 0.5) * 4.4)
end

local function makePart(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	return p
end

-- Face parts sit on the front (+Z) of the body, relative to the model's
-- origin on the ground. `origin` is where the model stands.
local function addFace(model, origin)
	local function facePart(name, size, color, offset)
		local p = makePart(name, size, color)
		p.Position = origin + offset
		p.Parent = model
		return p
	end
	facePart("EyeL", Vector3.new(0.5, 0.7, 0.2), Color3.fromRGB(255, 255, 255), Vector3.new(-0.6, 2.1, 1.35))
	facePart("PupilL", Vector3.new(0.25, 0.35, 0.1), Color3.fromRGB(20, 20, 20), Vector3.new(-0.6, 2.1, 1.48))
	facePart("EyeR", Vector3.new(0.5, 0.7, 0.2), Color3.fromRGB(255, 255, 255), Vector3.new(0.6, 2.1, 1.35))
	facePart("PupilR", Vector3.new(0.25, 0.35, 0.1), Color3.fromRGB(20, 20, 20), Vector3.new(0.6, 2.1, 1.48))
	facePart("Mouth", Vector3.new(0.9, 0.25, 0.2), Color3.fromRGB(60, 20, 20), Vector3.new(0, 1.25, 1.35))
end

local function addHat(model, hat, origin, bodyTopY)
	if hat == "None" then
		return
	end
	local color = HAT_COLORS[hat] or Color3.fromRGB(40, 40, 40)
	local function hatPart(name, size, mat, offset)
		local p = makePart(name, size, color, mat)
		p.Position = origin + offset
		p.Parent = model
		return p
	end
	if hat == "TopHat" then
		hatPart("HatBrim", Vector3.new(3, 0.3, 3), nil, Vector3.new(0, bodyTopY + 0.15, 0))
		hatPart("HatTop", Vector3.new(1.8, 1.6, 1.8), nil, Vector3.new(0, bodyTopY + 1, 0))
	elseif hat == "Crown" then
		hatPart("HatBand", Vector3.new(2.4, 0.7, 2.4), Enum.Material.Neon, Vector3.new(0, bodyTopY + 0.35, 0))
		for i = -1, 1 do
			hatPart("HatSpike" .. i, Vector3.new(0.5, 0.9, 0.5), Enum.Material.Neon, Vector3.new(i * 0.9, bodyTopY + 1, 0))
		end
	elseif hat == "Cap" then
		hatPart("HatCap", Vector3.new(2.8, 0.7, 2.8), nil, Vector3.new(0, bodyTopY + 0.35, 0))
		hatPart("HatBrim", Vector3.new(2.2, 0.25, 1.2), nil, Vector3.new(0, bodyTopY + 0.25, 1.6))
	elseif hat == "Wizard" then
		hatPart("HatCone", Vector3.new(2, 2.4, 2), nil, Vector3.new(0, bodyTopY + 1.2, 0))
		hatPart("HatBrim", Vector3.new(3.2, 0.3, 3.2), nil, Vector3.new(0, bodyTopY + 0.15, 0))
	end
end

local function addLabel(model, title, subtitle, color)
	-- The readable label every brainrot carries: name, rarity, $/sec.
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(140, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.4, 0)
	gui.AlwaysOnTop = false
	gui.Parent = model
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = title
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = gui
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Rate"
	subLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subLabel.Size = UDim2.new(1, 0, 0.5, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = subtitle
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.SourceSansBold
	subLabel.TextColor3 = color
	subLabel.TextStrokeTransparency = 0.4
	subLabel.Parent = gui
	return gui
end

-- Build one brainrot's model at a position. `entry` is { id, mutation }.
-- Returns the Model; its PrimaryPart is the body.
function WorldBuilder.buildBrainrot(entry, position)
	local def = BrainrotData.byId(entry.id)
	if not def then
		return nil
	end
	local mutation = nil
	for _, m in ipairs(BrainrotData.MUTATIONS) do
		if m.name == (entry.mutation or "None") then
			mutation = m
			break
		end
	end
	mutation = mutation or BrainrotData.MUTATIONS[1]

	local model = Instance.new("Model")
	model.Name = def.name

	local bodySize = def.body == "Ball" and Vector3.new(2.6, 2.6, 2.6) or Vector3.new(2.4, 2.8, 2.4)
	local body = makePart("Body", bodySize, def.color)
	body.Shape = def.body == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
	body.Position = position + Vector3.new(0, 1.6, 0)
	body.Parent = model
	model.PrimaryPart = body

	-- Little feet so it reads as a walking character on the belt.
	local footL = makePart("FootL", Vector3.new(0.8, 0.5, 1), Color3.fromRGB(40, 40, 40))
	footL.Position = position + Vector3.new(-0.6, 0.25, 0)
	footL.Parent = model
	local footR = makePart("FootR", Vector3.new(0.8, 0.5, 1), Color3.fromRGB(40, 40, 40))
	footR.Position = position + Vector3.new(0.6, 0.25, 0)
	footR.Parent = model

	addFace(model, position)
	addHat(model, def.hat, position, 1.6 + bodySize.Y / 2)

	-- A mutation tints the body with a glowing outline part.
	if mutation.name ~= "None" then
		local aura = makePart("Aura", bodySize + Vector3.new(0.4, 0.4, 0.4), mutation.color, Enum.Material.Neon)
		aura.Shape = def.body == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
		aura.Transparency = 0.75
		aura.Position = body.Position
		aura.Parent = model
	end

	local title = def.name
	if mutation.name ~= "None" then
		title = mutation.name:upper() .. " " .. def.name
	end
	local rate = BrainrotData.baseRate(entry)
	local subtitle = string.format("%s  •  $%d/s", def.rarity, rate)
	addLabel(model, title, subtitle, BrainrotData.rarityColor(def.rarity))

	return model
end

-- The Greedy Seagull: a white bird that swoops in to steal a brainrot.
function WorldBuilder.buildSeagull(position)
	local model = Instance.new("Model")
	model.Name = "GreedySeagull"

	local body = makePart("Body", Vector3.new(2.2, 1.4, 3.2), Color3.fromRGB(245, 245, 245))
	body.Shape = Enum.PartType.Ball
	body.Position = position
	body.Parent = model
	model.PrimaryPart = body

	local beak = makePart("Beak", Vector3.new(0.7, 0.5, 1.2), Color3.fromRGB(255, 170, 40))
	beak.Position = position + Vector3.new(0, 0.1, 2)
	beak.Parent = model
	local eyeL = makePart("EyeL", Vector3.new(0.3, 0.3, 0.2), Color3.fromRGB(20, 20, 20))
	eyeL.Position = position + Vector3.new(-0.7, 0.5, 1.2)
	eyeL.Parent = model
	local eyeR = makePart("EyeR", Vector3.new(0.3, 0.3, 0.2), Color3.fromRGB(20, 20, 20))
	eyeR.Position = position + Vector3.new(0.7, 0.5, 1.2)
	eyeR.Parent = model
	local wingL = makePart("WingL", Vector3.new(2.6, 0.25, 1.4), Color3.fromRGB(230, 230, 230))
	wingL.Position = position + Vector3.new(-2.2, 0.4, 0)
	wingL.Parent = model
	local wingR = makePart("WingR", Vector3.new(2.6, 0.25, 1.4), Color3.fromRGB(230, 230, 230))
	wingR.Position = position + Vector3.new(2.2, 0.4, 0)
	wingR.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "SeagullLabel"
	gui.Size = UDim2.fromOffset(180, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.Parent = model
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "GREEDY SEAGULL!"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui

	return model
end

-- The welcome sign and the shop sign. Their boards live in the Rojo
-- project file; their text lives here, because Rojo's project JSON
-- cannot carry a UDim2 (no encoding this Rojo accepts).
function WorldBuilder.buildWorldSigns()
	local function signOn(partName, text, color)
		local board = workspace:FindFirstChild(partName)
		if not board then
			return
		end
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.TextColor3 = color
		label.Parent = gui
	end
	signOn("SignBoard", "BRAINROT BAY", Color3.fromRGB(64, 38, 12))
	signOn("ShopSign", "SHOP", Color3.fromRGB(76, 38, 12))
end

-- A floating owner sign above a base plot: "ABS'S BASE" and its income.
function WorldBuilder.buildBaseSign(plotIndex, ownerName, incomePerSecond)
	local center = WorldBuilder.plotPosition(plotIndex)
	local guiPart = makePart("BaseSign", Vector3.new(6, 2.4, 0.4), Color3.fromRGB(40, 40, 50))
	guiPart.Position = center + Vector3.new(0, 9, 0)
	guiPart.Parent = workspace
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = guiPart
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ownerName .. "'s BASE"
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Parent = gui
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Income"
	incomeLabel.Position = UDim2.new(0, 0, 0.55, 0)
	incomeLabel.Size = UDim2.new(1, 0, 0.45, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = string.format("$%d/s", incomePerSecond)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	incomeLabel.Parent = gui
	return guiPart
end

return WorldBuilder
