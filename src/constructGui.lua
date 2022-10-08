local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()
local shaman = import('/lib/shaman')

local Windw = shaman:Window{
    Text = "Globe"
}

local commonPlugins = import('/packages/common/main')
commonPlugins.init(Windw)