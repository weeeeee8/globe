local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

if oh then
    oh.Maid:Destroy()
    oh = nil
end

local importLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/weeeeee8/globe/main/src/lib/import.lua'))()
local Maid = importLib('lib/maid')

env.import = importLib

env.oh = {
    Maid = Maid.new()
}

importLib('/constructGui')