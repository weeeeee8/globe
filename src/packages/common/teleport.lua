local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local mouse = Players.LocalPlayer:GetMouse()

local targetPlayer = nil
local requestPlayerTeleport = false
local shouldStickTo = false

local function getHRP()
    return Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

return {
    Start = function()
        oh.Maid:GiveTask(RunService.RenderStepped:Connect(function()
            if requestPlayerTeleport or shouldStickTo then
                if requestPlayerTeleport then
                    requestPlayerTeleport = false
                end
    
                if targetPlayer then
                    local targetChar = targetPlayer.Character
                    if targetChar then
                        local hrp, rhrp = targetChar:FindFirstChild("HumanoidRootPart"), getHRP()
                        if hrp and rhrp then
                            local pos = hrp.Position
                            rhrp.CFrame = CFrame.new(pos)
                        end
                    end
                end
            end
        end))
    end,

    ToggleMouseTeleport = function()
        local mousepos = mouse.Hit.Position
        if mouse.Target ~= nil then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = CFrame.new(mousepos + Vector3.new(0, 4, 0))
            end
        end
    end,

    TogglePlayerTeleport = function()
        requestPlayerTeleport = true
    end,
    
    ToggleStickTo = function()
        shouldStickTo = not shouldStickTo
    end,
    
    SetTargetPlayer = function(txt: string)
        local player
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == Players.LocalPlayer then continue end
            if plr.DisplayName:find(txt, 1) or plr.Name:find(txt, 1) then
                player = plr
                break
            end
        end

        targetPlayer = player
    end
}