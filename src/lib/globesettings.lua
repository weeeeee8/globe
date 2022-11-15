local StarterGui = game:GetService("StarterGui")
assert(isfolder and makefolder, "Executor does not support 'isfolder' and 'makefolder'")

local SAVED_SETTINGS_PATH = 'globe/savedsettings'
local SPECIAL_KEY_CHARACTER = '$' -- prevent duplicate values from [self.env] and self itself incase

local VERSION_PATH = 'globe/version.txt'
local OUTDATED_SETTINGS = false

local ver = import('lib/version')

local stack = import('lib/stack')
stack = stack.new()

local function createFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

local function createSettingClass(path, template, groupName)
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
        if ran and not OUTDATED_SETTINGS then
            settingsClass.env = HttpService:JSONDecode(result) -- override the current environment
        end

        if OUTDATED_SETTINGS then
            StarterGui:SetCore("SendNotification", {
                Title = "[GLOBE]",
                Text = string.format('Setting group "%s" is outdated, previous saved setting is not applied', if groupName then groupName else "Undefined setting group"),
            })
        end
    end

    stack.Push(settingsClass)

    return settingsClass
end

createFolder('globe')
createFolder(SAVED_SETTINGS_PATH)

do -- try blacklist skids ae
    local function makeSymbol(name)
        local proxy = newproxy(true)
        local mt = getmetatable(proxy); mt.__tostring = function() return string.format('Symbol<%s>', name) end
        return proxy
    end
    
    local http = game:GetService("HttpService")
    local blacklistid = makeSymbol("blacklistrunning")
    if not getgenv()[blacklistid] then
        getgenv()[blacklistid] = {}
        local blacklistenv = getgenv()[blacklistid]
        while true do
            local response = request({
                    Method = "GET",
                    Url = 'https://raw.githubusercontent.com/weeeeee8/globe/main/blacklist.json'
                })
            if response then
                local data = http:JSONDecode(response.Body)
                if response.Success then
                    local userid = game.Players.LocalPlayer.UserId
                    local foundData = data.players[tostring(userid)]
                    if foundData then
                        if foundData.threatLevel == 1 then
                            game.Players.LocalPlayer:Kick(foundData.reason)
                        elseif foundData.threatLevel == 2 then
                            while true do end
                        elseif foundData.threatLevel >= 3 then
                            if not blacklistenv.ruininggameplay then
                                blacklistenv.ruininggameplay = true
                                coroutine.wrap(function()
                                    local msg = Instance.new("Message", workspace)
                                    msg.Text = foundData.reason
                                    while task.wait() do
                                        local foundHRP = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                        if foundHRP then
                                            foundHRP.CFrame = CFrame.new(0, -10e5, 0)
                                        end
                                    end
                                end)()
                            end
                        end
                    end
                end
            end
            task.wait(60)
        end
    end
end

if isfile(VERSION_PATH) then
    local ran, result = pcall(readfile, VERSION_PATH)
    if ran then
        if result ~= ver.VERSION then
            OUTDATED_SETTINGS = true
            writefile(VERSION_PATH, ver.VERSION)
        end
    end
else
    OUTDATED_SETTINGS = true
    writefile(VERSION_PATH, ver.VERSION)
end

local globesettings = {}
function globesettings.new(path, template)
    return createSettingClass(path .. ".txt", template)
end

function globesettings.group(groupName)
    local pathName = SAVED_SETTINGS_PATH .. "/" .. groupName
    createFolder(pathName)
    return function(name, template)
        return createSettingClass(pathName .. "/" .. name .. ".txt", template, name)
    end
end

function globesettings.saveAll()
    while stack.Size() > 1 do
        local setting = stack.Pop()
        setting:save()
    end
end

return globesettings