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

        local function buildCamSpySection()
            local function getHumOf(char)
                return char:FindFirstChildOfClass("Humanoid")
            end

            local function setCamSubjectByChar(char)
                local hum = getHumOf(char)
            end

            local enabled = false

            local section = tab:Section{
                Text = "Player Spy", Side = "Right"
            }

            local label = section:Label{
                Text = "Current target: None",
                Color = oh.Constants.StateColors.Invalid
            }
            
            section:Toggle{
                Text = "Toggle camera spy",
                Callback = function(toggled)
                    enabled = toggled
                    if not toggled then
                        setCamSubjectByChar(Players.LocalPlayer.Character)
                    end
                end
            }

            section:Input{
                Text = "Set Target Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(txt)
                    if #txt <= 0 then return end
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:find(txt, 1) or plr.Name:find(txt, 1) then
                            player = plr
                            break
                        end
                    end
                    
                    label:Set{
                        Text = "Current target: " .. if player ~= nil then tostring(player.Name) else "None",
                        Color = if player ~= nil then oh.Constants.StateColors.Valid else oh.Constants.StateColors.Invalid
                    }

                    if enabled then
                        setCamSubjectByChar(player.Character)
                    end
                end
            }
        end

        local function buildLagSwitchSection()
            local enabled = false
            local disabled = false

            local privateMaid = Maid.new()
            oh.Maid:GiveTask(privateMaid)

            local section = tab:Section{
                Text = "Lag Switch Options",
                Side = "Right",
            }

            section:Keybind{
                Text = "Simulate Lagswitch",
                Default = Enum.KeyCode.V,
                Callback = function()
                    if not disabled then
                        enabled = not enabled
                        settings().Network.IncomingReplicationLag = enabled and 1000 or 0
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
        buildCamSpySection()
        tab:Select()
    end
}