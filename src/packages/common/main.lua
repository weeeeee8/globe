local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

local FlyAPI = import('packages/common/fly')
FlyAPI.Start()

return {
    init = function(windw)
        local function buildFlySection()
            local flySection = windw:Section{
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

        buildFlySection()
    end
}