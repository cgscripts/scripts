-- Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local FlyModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/cgscripts/scripts/main/fly.luau"))()

local Fly = FlyModule.new()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player
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
	if not object then return "" end
	local path = {}
	while object.Parent do
		table.insert(path, 1, object.Name)
		object = object.Parent
	end
	return table.concat(path, ".")
end

-- Settings
local Settings = {
	Spin_Speed = 1000
}

local Configs = {}

-- Window
local Window = Rayfield:CreateWindow({
	Name = "CgScripts | Blane County",
	LoadingTitle = "CgScripts",
	LoadingSubtitle = "Rayfield Edition",
	ConfigurationSaving = {
		Enabled = false
	}
})

-- Player Tab
local PlayerTab = Window:CreateTab("Player", 2795572800)

-- Movement
local Movement = PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {0, 500},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(Value)
		if Humanoid then
			Humanoid.WalkSpeed = Value
		end
	end
})

PlayerTab:CreateSlider({
	Name = "JumpHeight",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 7,
	Callback = function(Value)
		if Humanoid then
			Humanoid.JumpHeight = Value
		end
	end
})

PlayerTab:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Callback = function(Value)
		Fly.Toggle(Value)
	end
})

-- Spin
local SpinSection = PlayerTab:CreateSection("Spinning")

local spinning = false
local spinConnection

PlayerTab:CreateToggle({
	Name = "Spin",
	CurrentValue = false,
	Callback = function(Value)
		spinning = Value
		if spinning then
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
	Increment = 1,
	CurrentValue = 1000,
	Callback = function(Value)
		Settings.Spin_Speed = Value
	end
})

-- Car Tab
local CarTab = Window:CreateTab("Car", 123358713103625)

local CurrentCarSection = CarTab:CreateSection("Current Car")
local CurrentCarLabel = CarTab:CreateLabel("Nil")

CarTab:CreateButton({
	Name = "Update",
	Callback = function()
		if Humanoid.SeatPart and Humanoid.SeatPart:IsA("VehicleSeat") then
			Configs.Car = Humanoid.SeatPart.Parent
			CurrentCarLabel:Set(getPathAsString(Configs.Car))
		else
			Rayfield:Notify({
				Title = "Car not found",
				Content = "Sit on the driver seat",
				Duration = 2
			})
		end
	end
})

-- Body
CarTab:CreateSection("Body")

CarTab:CreateColorPicker({
	Name = "Body Color",
	Color = Color3.fromRGB(255,255,255),
	Callback = function(Value)
		if Configs.Car then
			local folder = Configs.Car:FindFirstChild("Body"):FindFirstChild("Color")
			for _,v in pairs(folder:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Color = Value
				end
			end
		end
	end
})

-- Engine
CarTab:CreateSection("Engine")

local speedValue = 0
local boostEnabled = false
local boostConnection

local function getCarPart()
	if Configs.Car then
		return Configs.Car.PrimaryPart or Configs.Car:FindFirstChildOfClass("VehicleSeat")
	end
end

local function getDriveSeat()
	if Configs.Car then
		return Configs.Car:FindFirstChildOfClass("VehicleSeat")
	end
end

boostConnection = RunService.RenderStepped:Connect(function()
	if not boostEnabled or speedValue <= 0 then return end
	local part = getCarPart()
	local seat = getDriveSeat()
	if part and seat and seat.Throttle ~= 0 then
		local forward = part.CFrame.LookVector
		local velY = part.AssemblyLinearVelocity.Y
		part.AssemblyLinearVelocity = Vector3.new(
			forward.X * speedValue * seat.Throttle,
			velY,
			forward.Z * speedValue * seat.Throttle
		)
	end
end)

CarTab:CreateToggle({
	Name = "Speed Boost",
	CurrentValue = false,
	Callback = function(Value)
		boostEnabled = Value
	end
})

CarTab:CreateSlider({
	Name = "Speed Boost",
	Range = {0,1000},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(Value)
		speedValue = Value
	end
})

-- Lights
CarTab:CreateSection("Lights")

CarTab:CreateColorPicker({
	Name = "Light Color",
	Color = Color3.fromRGB(255,255,255),
	Callback = function(Value)
		if Configs.Car then
			local folder = Configs.Car.Body.Lights.Headlight
			for _,v in pairs(folder:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Color = Value
					v.Attachment:FindFirstChildWhichIsA("Light").Color = Value
				end
			end
		end
	end
})

CarTab:CreateSlider({
	Name = "Brightness",
	Range = {0,100},
	Increment = 1,
	CurrentValue = 1,
	Callback = function(Value)
		if Configs.Car then
			for _,v in pairs(Configs.Car.Body.Lights.Headlight:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Attachment:FindFirstChildWhichIsA("Light").Brightness = Value
				end
			end
		end
	end
})

CarTab:CreateSlider({
	Name = "Range",
	Range = {0,100},
	Increment = 1,
	CurrentValue = 30,
	Callback = function(Value)
		if Configs.Car then
			for _,v in pairs(Configs.Car.Body.Lights.Headlight:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Attachment:FindFirstChildWhichIsA("Light").Range = Value
				end
			end
		end
	end
})

-- Trolling
local TrollTab = Window:CreateTab("Trolling", 72958894100814)
TrollTab:CreateParagraph({
	Title = "Work in Progress",
	Content = "If you have ideas, let me know"
})
