-- fly.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local BV, BG, conn
local control = {F=0,B=0,L=0,R=0,U=0,D=0}
local FlySpeed = 60
local flying = false

local function updateDirection()
    local cam = workspace.CurrentCamera
    local dir = (cam.CFrame.LookVector*(control.F-control.B)) + 
                (cam.CFrame.RightVector*(control.R-control.L)) + 
                Vector3.new(0,1,0)*(control.U-control.D)
    if BV then BV.Velocity = dir.Magnitude>0 and dir.Unit*FlySpeed or Vector3.zero end
    if BG then BG.CFrame = cam.CFrame end
end

local function onInputBegan(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.W then control.F=1 end
    if input.KeyCode==Enum.KeyCode.S then control.B=1 end
    if input.KeyCode==Enum.KeyCode.A then control.L=1 end
    if input.KeyCode==Enum.KeyCode.D then control.R=1 end
    if input.KeyCode==Enum.KeyCode.Space then control.U=1 end
    if input.KeyCode==Enum.KeyCode.LeftControl then control.D=1 end
end

local function onInputEnded(input)
    if input.KeyCode==Enum.KeyCode.W then control.F=0 end
    if input.KeyCode==Enum.KeyCode.S then control.B=0 end
    if input.KeyCode==Enum.KeyCode.A then control.L=0 end
    if input.KeyCode==Enum.KeyCode.D then control.R=0 end
    if input.KeyCode==Enum.KeyCode.Space then control.U=0 end
    if input.KeyCode==Enum.KeyCode.LeftControl then control.D=0 end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

function ToggleFly(value)
    flying = value
    if flying then
        Humanoid.PlatformStand = true
        BV = Instance.new("BodyVelocity", HRP)
        BV.MaxForce = Vector3.new(9e9,9e9,9e9)
        BG = Instance.new("BodyGyro", HRP)
        BG.P = 9e4
        BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
        conn = RunService.RenderStepped:Connect(updateDirection)
    else
        Humanoid.PlatformStand = false
        if BV then BV:Destroy() BV=nil end
        if BG then BG:Destroy() BG=nil end
        if conn then conn:Disconnect() conn=nil end
    end
end
