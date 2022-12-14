local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()
local shaman = import('lib/shaman')

local Packages = {
    [224422602] = 'packages/ebg/main',
    [2404080894] = 'packages/funkyfriday/main',
}

local Windw = shaman:Window{
    Text = "Globe"
}

env.Windw = Windw

local commonPlugins = import('packages/common/main')
commonPlugins.init(Windw)

local gamePlugin = import(assert(Packages[game.GameId], game:GetFullName() .. " does not have any supported plugins"))
gamePlugin.init(Windw)