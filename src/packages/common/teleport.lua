local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local activeRenderUpdate
local activeInputListeners = {}

local function getHRP()
    return Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    return Players.LocalPlayer.Character:FindFirstChild("Humanoid")
end

return {
    
}