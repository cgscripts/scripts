-- Orion UI bootstrap
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer
task.wait(1)

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
getgenv()._ORION = OrionLib

pcall(function()
	if gethui then
		OrionLib.Parent = gethui()
	end
end)

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

-- Window
local Window = OrionLib:MakeWindow({
	Name = "CgScripts | Blane County",
	HidePremium = false,
	SaveConfig = false
})

----------------------------------------------------------------
-- PLAYER TAB
----------------------------------------------------------------
local PlayerTab = Window:MakeTab({
	Name = "Player",
	Icon = "rbxassetid://2795572800"
})

task.wait()

local Movement = PlayerTab:AddSection({ Name = "Movement" })

Movement:AddSlider({
	Name = "WalkSpeed",
	Min = 0, Max = 500, Default = 16,
	Callback = function(v)
		if Humanoid then Humanoid.WalkSpeed = v end
	end
})

Movement:AddSlider({
	Name = "JumpHeight",
	Min = 0, Max = 100, Default = 7.2,
	Callback = function(v)
		if Humanoid then Humanoid.JumpHeight = v end
	end
})

Movement:AddToggle({
	Name = "Fly",
	Default = false,
	Callback = function(v)
		pcall(function() Fly.Toggle(v) end)
	end
})

task.wait()

local Spin = PlayerTab:AddSection({ Name = "Spinning" })

local spinConnection
Spin:AddToggle({
	Name = "Spin",
	Default = false,
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

Spin:AddSlider({
	Name = "Spin Speed",
	Min = 0, Max = 5000, Default = 1000,
	Callback = function(v)
		Settings.Spin_Speed = v
	end
})

----------------------------------------------------------------
-- CAR TAB
----------------------------------------------------------------
task.wait()

local CarTab = Window:MakeTab({
	Name = "Car",
	Icon = "rbxassetid://123358713103625"
})

task.wait()

local CurrentCarSection = CarTab:AddSection({ Name = "Current Car" })
local CurrentCarLabel = CurrentCarSection:AddLabel("Nil")

CurrentCarSection:AddButton({
	Name = "Update",
	Callback = function()
		if Humanoid.SeatPart and Humanoid.SeatPart:IsA("VehicleSeat") then
			Configs.Car = Humanoid.SeatPart.Parent
			CurrentCarLabel:Set(getPathAsString(Configs.Car))
		else
			OrionLib:MakeNotification({
				Name = "Car not found",
				Content = "Sit in driver seat",
				Time = 2
			})
		end
	end
})

----------------------------------------------------------------
-- BODY
----------------------------------------------------------------
task.wait()

local CarBodySection = CarTab:AddSection({ Name = "Body" })

CarBodySection:AddColorpicker({
	Name = "Body Color",
	Default = Color3.fromRGB(255,255,255),
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
task.wait()

local CarEngineSection = CarTab:AddSection({ Name = "Engine" })

local boostEnabled = false
local speedValue = 0
local boostConnection

local function getSeat(car)
	return car and car:FindFirstChildOfClass("VehicleSeat")
end

boostConnection = RunService.RenderStepped:Connect(function()
	if not boostEnabled or speedValue <= 0 then return end
	local car = Configs.Car
	local seat = getSeat(car)
	if not (car and seat) then return end

	local part = car.PrimaryPart or seat
	local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
	local forward = part.CFrame.LookVector

	if seat.Throttle == 0 then return end

	part.AssemblyLinearVelocity = Vector3.new(
		forward.X * speedValue * seat.Throttle,
		vel.Y,
		forward.Z * speedValue * seat.Throttle
	)
end)

CarEngineSection:AddToggle({
	Name = "Speed Boost",
	Default = false,
	Callback = function(v)
		boostEnabled = v
	end
})

CarEngineSection:AddSlider({
	Name = "Boost Power",
	Min = 0, Max = 1000, Default = 0,
	Callback = function(v)
		speedValue = v
	end
})

----------------------------------------------------------------
-- LIGHTS
----------------------------------------------------------------
task.wait()

local CarLightSection = CarTab:AddSection({ Name = "Lights" })

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

CarLightSection:AddColorpicker({
	Name = "Light Color",
	Default = Color3.fromRGB(255,255,255),
	Callback = function(v)
		forEachHeadlight(function(p, l)
			p.Color = v
			if l then l.Color = v end
		end)
	end
})

CarLightSection:AddSlider({
	Name = "Brightness",
	Min = 0, Max = 100, Default = 1,
	Callback = function(v)
		forEachHeadlight(function(_, l)
			if l then l.Brightness = v end
		end)
	end
})

CarLightSection:AddSlider({
	Name = "Range",
	Min = 0, Max = 100, Default = 30,
	Callback = function(v)
		forEachHeadlight(function(_, l)
			if l then l.Range = v end
		end)
	end
})

----------------------------------------------------------------
-- TROLLING
----------------------------------------------------------------
task.wait()

local TrollingTab = Window:MakeTab({
	Name = "Trolling",
	Icon = "rbxassetid://72958894100814"
})

TrollingTab:AddParagraph(
	"Work in Progress",
	"If you have any ideas, let me know"
)

-- FINAL INIT
OrionLib:Init()
