local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

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
            local oldRootPart
            local fakeRootPart

            local section = tab:Section{
                Text = "Lag Switch Options",
                Side = "Right",
            }

            section:Keybind{
                Text = "Simulate Lagswitch",
                Callback = function()
                    local character = Players.LocalPlayer.Character
                    enabled = not enabled
                    if not enabled then
                        if fakeRootPart and oldRootPart then
                            oldRootPart.Parent = character
                            fakeRootPart:Destroy()
                            fakeRootPart = nil
                            oldRootPart = nil
                        end
                    else
                        oldRootPart = character.HumanoidRootPart
                        oldRootPart.Parent = nil

                        fakeRootPart = character.HumanoidRootPart:Clone()
                        fakeRootPart.RootJoint.C1 = character.Torso
                        fakeRootPart.Parent = character
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