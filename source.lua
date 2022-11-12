local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

if oh then
    oh.Maid:Destroy()
    oh = nil
end

env.import = loadstring(game:HttpGet('https://raw.githubusercontent.com/weeeeee8/globe/main/src/lib/import.lua'))()
local Maid = import('lib/maid')
local fnUtil = import('lib/functionUtil')
local setting = import('lib/globesettings')

env.oh = {
    Maid = Maid.new(),
    Constants = {
        StateColors = {
            Valid = Color3.fromRGB(41, 204, 106),
            Invalid = Color3.fromRGB(243, 36, 36),
        }
    }
}

import('/constructGui')
oh.Maid:GiveTask(fnUtil.clearhooks)
oh.Maid:GiveTask(setting.saveAll)