local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

local importLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/weeeeee8/globe/main/lib/import.lua'))()
env.import = importLib

importLib('/constructGui')