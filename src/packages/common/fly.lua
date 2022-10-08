local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local activeRenderUpdate
local activeInputListeners = {}
local activeCollisionUpdate

local velocityObject, gyroObject
local activeInputs = {
    Left = false,
    Right = false,
    Forward = false,
    Backward = false,
}

local toggled = false
local shouldNoClip = false
local flightSpeed = 350

local function getHRP()
    return Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return Players.LocalPlayer.Character:FindFirstChild("Humanoid")
end

return {
    Start = function()
        if activeRenderUpdate then
            for _, v in ipairs(activeInputListeners) do
                v:Disconnect()
            end
            table.clear(activeInputListeners)
    
            activeRenderUpdate:Disconnect()
            activeRenderUpdate = nil
    
            activeCollisionUpdate:Disconnect()
            activeCollisionUpdate = nil
            
            if velocityObject then
                velocityObject:Destroy()
                velocityObject = nil
            end
    
            if gyroObject then
                gyroObject:Destroy()
                gyroObject = nil
            end
            
            local hum = getHum()
            if hum then
                hum.AutoRotate = true
            end
        end

        activeRenderUpdate = RunService.RenderStepped:Connect(function(deltaTime)
            if toggled then
                local f = Vector3.zero
                if activeInputs.Forward then
                    f += workspace.CurrentCamera.CFrame.LookVector * flightSpeed
                end
                if activeInputs.Backward then
                    f -= workspace.CurrentCamera.CFrame.LookVector * flightSpeed
                end
                if activeInputs.Right then
                    f += workspace.CurrentCamera.CFrame.RightVector * flightSpeed
                end
                if activeInputs.Left then
                    f -= workspace.CurrentCamera.CFrame.RightVector * flightSpeed
                end
                    
                if velocityObject then
                    velocityObject.Velocity = f
                end
                if gyroObject then
                    gyroObject.CFrame = workspace.CurrentCamera.CFrame
                end
            end
        end)
    
        activeCollisionUpdate = RunService.Stepped:Connect(function(time, deltaTime)
            if toggled and shouldNoClip then
                for _, v in ipairs(Players.LocalPlayer.Character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end)
    
        table.insert(activeInputListeners, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.A then
                activeInputs.Left = true
            end
            if input.KeyCode == Enum.KeyCode.D then
                activeInputs.Right = true
            end
            if input.KeyCode == Enum.KeyCode.S then
                activeInputs.Backward = true
            end
            if input.KeyCode == Enum.KeyCode.W then
                activeInputs.Forward = true
            end
        end))
        table.insert(activeInputListeners, UserInputService.InputEnded:Connect(function(input, gpe)
            if input.KeyCode == Enum.KeyCode.A then
                activeInputs.Left = false
            end
            if input.KeyCode == Enum.KeyCode.D then
                activeInputs.Right = false
            end
            if input.KeyCode == Enum.KeyCode.S then
                activeInputs.Backward = false
            end
            if input.KeyCode == Enum.KeyCode.W then
                activeInputs.Forward = false
            end
        end))
    end,

    SetSpeed = function(value)
        value = value
        flightSpeed = if value then value else flightSpeed
    end,

    EnableNoClip = function(value)
        shouldNoClip = value
    end,

    ToggleFly = function()
        toggled = not toggled

        if toggled then
            local hrp = getHRP()
            local hum = getHum()
            if hum then
                hum.AutoRotate = false
            end

            if not hrp then return end
            if velocityObject then
                velocityObject:Destroy()
                velocityObject = nil
            end

            if gyroObject then
                gyroObject:Destroy()
                gyroObject = nil
            end
            
            local velocity = Instance.new("BodyVelocity")
            velocity.P = 2500
            velocity.Velocity = Vector3.zero
            velocity.MaxForce = Vector3.one * math.huge
            velocity.Parent = hrp
            velocityObject = velocity
            local gyro = Instance.new("BodyGyro")
            gyro.P = 10^6
            gyro.CFrame = hrp.CFrame
            gyro.MaxTorque = Vector3.one * 10^6
            gyro.Parent = hrp
            gyroObject = gyro
        else
            if velocityObject then
                velocityObject:Destroy()
                velocityObject = nil
            end

            if gyroObject then
                gyroObject:Destroy()
                gyroObject = nil
            end

            local hum = getHum()
            if hum then
                hum.AutoRotate = true
            end
        end
    end
}