-- Sounds: the game's sound effects, client-side.
--
-- Roblox ships a small set of built-in sounds under rbxasset://sounds/,
-- so the game needs no uploaded audio: these always load, even for a
-- reviewer opening the place on a house account. The server asks for a
-- sound by name through the PlaySound remote; this module plays it.

local SoundService = game:GetService("SoundService")

local Sounds = {}

-- Built-in Roblox sounds. Nothing here is an uploaded asset id.
local LIBRARY = {
	coin = "rbxasset://sounds/electronicpingshort.wav",
	click = "rbxasset://sounds/button.wav",
	error = "rbxasset://sounds/electronicpingshort.wav",
	alarm = "rbxasset://sounds/impact_water.mp3",
	rain = "rbxasset://sounds/impact_water.mp3",
	pop = "rbxasset://sounds/button.wav",
}

local VOLUME = {
	coin = 0.6,
	click = 0.5,
	error = 0.4,
	alarm = 0.7,
	rain = 0.5,
	pop = 0.5,
}

local PITCH = {
	coin = 1.2,
	click = 1,
	error = 0.7,
	alarm = 0.9,
	rain = 1,
	pop = 1.4,
}

function Sounds.play(name)
	local id = LIBRARY[name]
	if not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = VOLUME[name] or 0.5
	sound.PlaybackSpeed = PITCH[name] or 1
	sound.Parent = SoundService
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	local ok = pcall(function()
		sound:Play()
	end)
	if not ok then
		sound:Destroy()
	end
	-- A sound that never ends (a missed Ended event) is cleaned up anyway.
	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return Sounds
