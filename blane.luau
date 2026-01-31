-- Rayfield UI bootstrap
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer
task.wait(1)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Fly
local FlyModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/cgscripts/scripts/main/fly.luau"))()
local Fly = FlyModule.new()

-- Player refs
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	HRP = char:WaitForChild("HumanoidRootPart")
end)

-- Utils
local function getPathAsString(object)
	if not object then return "Nil" end
	local t = {}
	while object and object.Parent do
		table.insert(t, 1, object.Name)
		object = object.Parent
	end
	return table.concat(t, ".")
end

-- State
local Settings = { Spin_Speed = 1000 }
local Configs = {}

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
	Name = "CgScripts | Blane County",
	LoadingTitle = "CgScripts",
	LoadingSubtitle = "Rayfield Edition",
	ConfigurationSaving = {
		Enabled = false
	}
})

----------------------------------------------------------------
-- PLAYER TAB
----------------------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 2795572800)

local Movement = PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {0, 500},
	Increment = 1,
	Suffix = "Speed",
	CurrentValue = 16,
	Callback = function(v)
		if Humanoid then Humanoid.WalkSpeed = v end
	end
})

PlayerTab:CreateSlider({
	Name = "JumpHeight",
	Range = {0, 100},
	Increment = 1,
	Suffix = "Height",
	CurrentValue = 7,
	Callback = function(v)
		if Humanoid then Humanoid.JumpHeight = v end
	end
})

PlayerTab:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Callback = function(v)
		pcall(function()
			Fly.Toggle(v)
		end)
	end
})

----------------------------------------------------------------
-- SPIN
----------------------------------------------------------------
local SpinSection = PlayerTab:CreateSection("Spinning")
local spinConnection

PlayerTab:CreateToggle({
	Name = "Spin",
	CurrentValue = false,
	Callback = function(v)
		if v then
			if spinConnection then return end
			spinConnection = RunService.RenderStepped:Connect(function(dt)
				if HRP then
					HRP.CFrame *= CFrame.Angles(0, math.rad(Settings.Spin_Speed * dt), 0)
				end
			end)
		else
			if spinConnection then
				spinConnection:Disconnect()
				spinConnection = nil
			end
		end
	end
})

PlayerTab:CreateSlider({
	Name = "Spin Speed",
	Range = {0, 5000},
	Increment = 10,
	Suffix = "deg/s",
	CurrentValue = 1000,
	Callback = function(v)
		Settings.Spin_Speed = v
	end
})

----------------------------------------------------------------
-- CAR TAB
----------------------------------------------------------------
local CarTab = Window:CreateTab("Car", 123358713103625)

local CurrentCarSection = CarTab:CreateSection("Current Car")
local CurrentCarLabel = CarTab:CreateLabel("Current Car: Nil")

CarTab:CreateButton({
	Name = "Update",
	Callback = function()
		if Humanoid.SeatPart and Humanoid.SeatPart:IsA("VehicleSeat") then
			Configs.Car = Humanoid.SeatPart.Parent
			CurrentCarLabel:Set("Current Car: " .. getPathAsString(Configs.Car))
		else
			Rayfield:Notify({
				Title = "Car not found",
				Content = "Sit in driver seat",
				Duration = 2
			})
		end
	end
})

----------------------------------------------------------------
-- BODY
----------------------------------------------------------------
local CarBodySection = CarTab:CreateSection("Body")

CarTab:CreateColorPicker({
	Name = "Body Color",
	Color = Color3.fromRGB(255,255,255),
	Callback = function(val)
		local car = Configs.Car
		if not car then return end
		local body = car:FindFirstChild("Body")
		if not body then return end
		local colorFolder = body:FindFirstChild("Color")
		if not colorFolder then return end

		for _, p in ipairs(colorFolder:GetDescendants()) do
			if p:IsA("BasePart") or p:IsA("MeshPart") then
				p.Color = val
			end
		end
	end
})

----------------------------------------------------------------
-- ENGINE
----------------------------------------------------------------
local CarEngineSection = CarTab:CreateSection("Engine")

local boostEnabled = false
local speedValue = 0

local function getSeat(car)
	return car and car:FindFirstChildOfClass("VehicleSeat")
end

RunService.RenderStepped:Connect(function()
	if not boostEnabled or speedValue <= 0 then return end
	local car = Configs.Car
	local seat = getSeat(car)
	if not (car and seat) then return end

	local part = car.PrimaryPart or seat
	local vel = part.AssemblyLinearVelocity
	local forward = part.CFrame.LookVector

	if seat.Throttle == 0 then return end

	part.AssemblyLinearVelocity = Vector3.new(
		forward.X * speedValue * seat.Throttle,
		vel.Y,
		forward.Z * speedValue * seat.Throttle
	)
end)

CarTab:CreateToggle({
	Name = "Speed Boost",
	CurrentValue = false,
	Callback = function(v)
		boostEnabled = v
	end
})

CarTab:CreateSlider({
	Name = "Boost Power",
	Range = {0, 1000},
	Increment = 10,
	Suffix = "Power",
	CurrentValue = 0,
	Callback = function(v)
		speedValue = v
	end
})

----------------------------------------------------------------
-- LIGHTS
----------------------------------------------------------------
local CarLightSection = CarTab:CreateSection("Lights")

local function forEachHeadlight(fn)
	local car = Configs.Car
	if not car then return end
	local body = car:FindFirstChild("Body")
	local lights = body and body:FindFirstChild("Lights")
	local head = lights and lights:FindFirstChild("Headlight")
	if not head then return end

	for _, p in ipairs(head:GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("MeshPart") then
			local att = p:FindFirstChildWhichIsA("Attachment")
			local light = att and att:FindFirstChildWhichIsA("Light")
			fn(p, light)
		end
	end
end

CarTab:CreateColorPicker({
	Name = "Light Color",
	Color = Color3.fromRGB(255,255,255),
	Callback = function(v)
		forEachHeadlight(function(p, l)
			p.Color = v
			if l then l.Color = v end
		end)
	end
})

CarTab:CreateSlider({
	Name = "Brightness",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 1,
	Callback = function(v)
		forEachHeadlight(function(_, l)
			if l then l.Brightness = v end
		end)
	end
})

CarTab:CreateSlider({
	Name = "Range",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 30,
	Callback = function(v)
		forEachHeadlight(function(_, l)
			if l then l.Range = v end
		end)
	end
})

----------------------------------------------------------------
-- TROLLING
----------------------------------------------------------------
local TrollingTab = Window:CreateTab("Trolling", 72958894100814)

TrollingTab:CreateParagraph(
	"Work in Progress",
	"If you have any ideas, let me know"
)
