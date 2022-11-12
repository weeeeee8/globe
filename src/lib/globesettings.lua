local HttpService = game:GetService("HttpService")
assert(isfolder and makefolder, "Executor does not support 'isfolder' and 'makefolder'")

local SAVED_SETTINGS_PATH = 'globe/savedsettings'
local SPECIAL_KEY_CHARACTER = '$' -- prevent duplicate values from [self.env] and self itself incase

local stack = import('lib/stack')
stack = stack.new()

local function createFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

local function createSettingClass(path, template)
    local settingsClass = setmetatable({
        env = {}
    }, {
        __index = function(self, key)
            local tbl = rawget(self, 'env')
            local result = tbl[SPECIAL_KEY_CHARACTER..key]
            return if result then result else rawget(self, key)
        end
    })
    function settingsClass:newsetting(name, value)
        self.env[SPECIAL_KEY_CHARACTER..name] = value
    end

    function settingsClass:getsetting(name)
        return self.env[SPECIAL_KEY_CHARACTER..name]
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

    stack.Push(settingsClass)

    return settingsClass
end

createFolder('globe')
createFolder(SAVED_SETTINGS_PATH)

local globesettings = {}
function globesettings.new(path, template)
    return createSettingClass(path .. ".txt", template)
end

function globesettings.group(groupName)
    local pathName = SAVED_SETTINGS_PATH .. "/" .. groupName
    createFolder(pathName)
    return function(name, template)
        return createSettingClass(pathName .. "/" .. name .. ".txt", template)
    end
end

function globesettings.saveAll()
    while stack.Size() > 1 do
        local setting = stack.Pop()
        setting:save()
    end
end

return globesettings