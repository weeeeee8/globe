local HttpService = game:GetService("HttpService")
assert(isfolder and makefolder, "Executor does not support 'isfolder' and 'makefolder'")

local SAVED_SETTINGS_PATH = 'globe/savedsettings'
local SPECIAL_KEY_CHARACTER = '$' -- prevent duplicate values from [self.env] and self itself incase

local function createFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

createFolder('globe')
createFolder(SAVED_SETTINGS_PATH)

local function createSettingClass(path, template)
    local settingsClass = {}
    settingsClass.env = {}
    settingsClass.__index = function(self, key)
        local result = self.env[key:sub(2, #key)]
        if result then return result end
        return self[key]
    end

    settingsClass = setmetatable({}, settingsClass)
    function settingsClass:newsetting(name, value)
        settingsClass.env[SPECIAL_KEY_CHARACTER..name] = value
    end

    function settingsClass:getsetting(name)
        return settingsClass.env[SPECIAL_KEY_CHARACTER..name]
    end

    function settingsClass:save()
        local content = HttpService:JSONEncode(self.env)
        writefile(path, content)
    end

    if template then
        for k, v in pairs(template) do
            settingsClass:newsetting(k, v)
        end
    end

    if isfile(path) then
        local ran, result = pcall(readfile, path)
        if not ran then
            settingsClass.env = HttpService:JSONDecode(result) -- override the current environment
        end
    end

    return settingsClass
end

local globesettings = {}
function globesettings.new(name, template)
    local pathName = SAVED_SETTINGS_PATH .. "/" .. name
    return createSettingClass(pathName, template)
end

return globesettings