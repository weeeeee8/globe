local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

local Maid = import('lib/maid')

local FlyAPI = import('packages/common/fly')
FlyAPI.Start()

local TeleportAPI = import('packages/common/teleport')
TeleportAPI.Start()

return {
    init = function(windw)
        local tab = windw:Tab{Text = "Common"}
        local function buildFlySection()
            local flySection = tab:Section{
                Text = "Fly"
            }

            flySection:Keybind{
                Text = "Toggle Fly",
                Default = Enum.KeyCode.F,
                Callback = FlyAPI.ToggleFly
            }

            flySection:Toggle{
                Text = "Enable Noclip",
                Tooltip = "Allows character to clip through objects during flight",
                Callback = FlyAPI.EnableNoClip,
            }

            flySection:Input{
                Text = "Modify flightspeed",
                Placeholder = "350",
                Callback = FlyAPI.SetSpeed
            }
        end
        
        local function buildTeleportSection()
            local teleportSection = tab:Section{
                Text = "Teleport Options"
            }

            local label = teleportSection:Label{
                Text = "Current target: None",
                Color = oh.Constants.StateColors.Invalid
            }

            teleportSection:Keybind{
                Text = "Toggle Mouse Teleport",
                Default = Enum.KeyCode.T,
                Callback = TeleportAPI.ToggleMouseTeleport
            }

            teleportSection:Keybind{
                Text = "Toggle Player Teleport",
                Default = Enum.KeyCode.G,
                Callback = TeleportAPI.TogglePlayerTeleport
            }

            teleportSection:Keybind{
                Text = "Toggle Stick to",
                Default = Enum.KeyCode.H,
                Callback = TeleportAPI.ToggleStickTo
            }

            teleportSection:Input{
                Text = "Target player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(v)
                    TeleportAPI.SetTargetPlayer(v, label)
                end
            }
        end

        local function buildLagSwitchSection()
            local enabled = false

            local realCharacter
            local function onCharacterAdded(char)
                realCharacter = char
                realCharacter.Archivable = true 
                char:WaitForChild("Humanoid").Died:Once(function()
                    realCharacter = nil
                end) 
            end
            oh.Maid:GiveTask(Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
            if Players.LocalPlayer.Character then onCharacterAdded(Players.LocalPlayer.Character) end

            local privateMaid = Maid.new()
            oh.Maid:GiveTask(privateMaid)

            local section = tab:Section{
                Text = "Lag Switch Options",
                Side = "Right",
            }

            section:Keybind{
                Text = "Simulate Lagswitch",
                Default = Enum.KeyCode.N,
                Callback = function()
                    enabled = not enabled
                    if not enabled then
                        privateMaid:DoCleaning()
                    else
                        local fakeChar = realCharacter:Clone()
                        fakeChar.Parent = workspace
                        Players.LocalPlayer.Character = fakeChar
                        realCharacter.Parent = nil
                        privateMaid:GiveTask(function()
                            realCharacter.Parent = workspace
                            realCharacter:PivotTo(fakeChar:GetPivot())
                            Players.LocalPlayer.Character = realCharacter
                            fakeChar:Destroy()
                        end)
                    end
                end,
            }

            return section
        end

        local function buildRejoiningSection()
            local rejoinSection = tab:Section{
                Text = "Rejoining Options",
                Side = "Right",
            }

            rejoinSection:Button{
                Text = "Rejoin Place",
                Callback = function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end
            }
        end

        buildFlySection()
        buildTeleportSection()
        buildRejoiningSection()
        buildLagSwitchSection()
        tab:Select()
    end
}