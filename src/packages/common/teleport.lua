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
                            rhrp.CFrame = hrp.CFrame
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
                local dir = hrp.CFrame.LookVector * 50
                if hrp.Parent.Humanoid.MoveDirection.Magnitude > 0 then
                    dir = hrp.Parent.Humanoid.MoveDirection.Unit * 50
                end
                local pos = mousepos + Vector3.new(0, 2, 0)
                hrp.CFrame = CFrame.lookAt(pos, pos + dir)
            end
        end
    end,

    TogglePlayerTeleport = function()
        requestPlayerTeleport = true
    end,
    
    ToggleStickTo = function()
        shouldStickTo = not shouldStickTo
    end,

    SetTargetPlayer = function(txt: string?, labelComponent)
        if #txt <= 0 then return end
        local player
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == Players.LocalPlayer then continue end
            if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
                player = plr
                break
            end
        end
        
        labelComponent:Set{
            Text = "Current target: " .. if player ~= nil then tostring(player.Name) else "None",
            Color = if player ~= nil then oh.Constants.StateColors.Valid else oh.Constants.StateColors.Invalid
        }
        targetPlayer = player
    end
}