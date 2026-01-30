-- Orion UI
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

local FlyModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/cgscripts/scripts/main/fly.luau"))()

Fly = FlyModule.new()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	HRP = char:WaitForChild("HumanoidRootPart")
end)

local function getPathAsString(object)
    if not object then return "" end

    local pathSegments = {}
    local current = object

    while current.Parent do
        table.insert(pathSegments, 1, current.Name)
        current = current.Parent
    end

    if pathSegments[1] == game.Name then
        table.remove(pathSegments, 1)
    end

    local pathString = table.concat(pathSegments, ".")
    return pathString
end


local Settings = {
    Spin_Speed = 1000,
}

local Configs = {
}

local Window = OrionLib:MakeWindow({
	Name = "CgScripts | Blane County",
	HidePremium = false,
	SaveConfig = false,
	ConfigFolder = ""
})

local PlayerTab = Window:MakeTab({
	Name = "Player",
	Icon = "rbxassetid://2795572800",
	PremiumOnly = false
})

local Movement = PlayerTab:AddSection({
    Name = "Movement"
})

Movement:AddSlider({
	Name = "WalkSpeed",
	Min = 0,
	Max = 500,
	Default = 16,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "",
	Callback = function(Value)
		if Humanoid then
			Humanoid.WalkSpeed = Value
		end
	end
})

Movement:AddSlider({
	Name = "JumpHeight",
	Min = 0,
	Max = 100,
	Default = 7.2,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "",
	Callback = function(Value)
		if Humanoid then
			Humanoid.JumpHeight = Value
		end
	end
})

Movement:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(Value)
        Fly.Toggle(Value)
    end
})

task.wait()

local Spin = PlayerTab:AddSection({
    Name = "Spinning"
})

local spinning = false
        local spinConnection = nil

Spin:AddToggle({
	Name = "Spin",
	Default = false,
	Callback = function(Value)
        
		spinning = Value

		if spinning then
			if spinConnection then return end

			spinConnection = RunService.RenderStepped:Connect(function(dt)
				if HRP then
					HRP.CFrame =
						HRP.CFrame *
						CFrame.Angles(0, math.rad(Settings.Spin_Speed * dt), 0)
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
	Min = 0,
	Max = 5000,
	Default = 1000,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "°/s",
	Callback = function(Value)
		Settings.Spin_Speed = Value
	end
})



local CarTab = Window:MakeTab({
	Name = "Car",
	Icon = "rbxassetid://123358713103625",
	PremiumOnly = false
})

local CurrentCarSection = CarTab:AddSection({
    Name = "Current Car"
})

local CurrentCarLabel = CurrentCarSection:AddLabel("Nil")

CurrentCarSection:AddButton({
    Name = "Update",
    Callback = function()
        if Humanoid.SeatPart and Humanoid.SeatPart:IsA("VehicleSeat") then
            local Car = Humanoid.SeatPart.Parent
            
            if Car then
                print("Car found")
                Configs.Car = Car
                CurrentCarLabel:Set(getPathAsString(Car))
            end
        else
            OrionLib:MakeNotification({
                Name = "Car not found",
                Content = "Please make sure you are sitting on the driver seat",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

local CarBodySection = CarTab:AddSection({
    Name = "Body"
})

CarBodySection:AddColorpicker({
	Name = "Body Color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(Value)
		if Configs.Car then
            local ColorFolder = Configs.Car:FindFirstChild("Body"):FindFirstChild("Color")
            for _, child in pairs(ColorFolder:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    child.Color = Value
                end
            end
		end
	end	  
})

local CarEngineSection = CarTab:AddSection({
    Name = "Engine"
})
local boostConnection
local speedValue = 0
local boostEnabled = false

CarEngineSection:AddToggle({
	Name = "Speed Boost",
    Default = false,
    Callback = function(Value)
        boostEnabled = Value
    end
})

local function getCarPart()
    local car = Configs.Car
    if car and car.PrimaryPart then
        return car.PrimaryPart
    elseif car then
        return car:FindFirstChildOfClass("VehicleSeat")
    end
    return nil
end

local function getDriveSeat()
    local car = Configs.Car
    if car then
        return car:FindFirstChildOfClass("VehicleSeat")
    end
    return nil
end

local function startBoostEnforcer()
    if boostConnection then return end
    boostConnection = RunService.RenderStepped:Connect(function()
        if not boostEnabled or speedValue <= 0 then return end
        local part = getCarPart()
        local seat = getDriveSeat()
        if part and seat then
            local throttle = seat.Throttle
            if throttle == 0 then return end

            local forward = part.CFrame.LookVector
            local currentY = part.AssemblyLinearVelocity and part.AssemblyLinearVelocity.Y or part.Velocity.Y
            local desired = Vector3.new(
                forward.X * speedValue * throttle,
                currentY,
                forward.Z * speedValue * throttle
            )

            local vel = part.AssemblyLinearVelocity or part.Velocity
            if (throttle > 0 and vel:Dot(forward) < 0) or (throttle < 0 and vel:Dot(forward) > 0) then
                return
            end

            pcall(function()
                part.AssemblyLinearVelocity = desired
            end)
        end
    end)
end

startBoostEnforcer()

CarEngineSection:AddSlider({
    Name = "Speed Boost ",
    Min = 0,
    Max = 1000,
    Default = 0,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "",
    Callback = function(Value)
        if boostEnabled then
            speedValue = Value
            if Value > 0 and not boostConnection then
                startBoostEnforcer()
            end
        end
    end
})





local CarLightSection = CarTab:AddSection({
    Name = "Lights"
})

CarLightSection:AddColorpicker({
	Name = "Light Color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(Value)
		if Configs.Car then
            local HeadlightFolder = Configs.Car:FindFirstChild("Body"):FindFirstChild("Lights"):FindFirstChild("Headlight")
            for _, child in pairs(HeadlightFolder:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    child.Color = Value
                    child:FindFirstChild("Attachment"):FindFirstChildWhichIsA("Light").Color = Value
                end
            end
		end
	end	  
})

CarLightSection:AddSlider({
    Name = "Brightness",
	Min = 0,
	Max = 100,
	Default = 1,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "",
	Callback = function(Value)
		if Configs.Car then
            local HeadlightFolder = Configs.Car:FindFirstChild("Body"):FindFirstChild("Lights"):FindFirstChild("Headlight")
            for _, child in pairs(HeadlightFolder:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    child:FindFirstChild("Attachment"):FindFirstChildWhichIsA("Light").Brightness = Value
                end
            end
		end
	end
})

CarLightSection:AddSlider({
    Name = "Range",
	Min = 0,
	Max = 100,
	Default = 30,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "",
	Callback = function(Value)
		if Configs.Car then
            local HeadlightFolder = Configs.Car:FindFirstChild("Body"):FindFirstChild("Lights"):FindFirstChild("Headlight")
            for _, child in pairs(HeadlightFolder:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    child:FindFirstChild("Attachment"):FindFirstChildWhichIsA("Light").Range = Value
                end
            end
		end
	end
})

local TrollingTab = Window:MakeTab({
	Name = "Trolling",
	Icon = "rbxassetid://72958894100814",
	PremiumOnly = false
})

TrollingTab:AddParagraph("Work in Progress","If you have any ideas for this section, let me know in the discord server")

OrionLib:Init()
