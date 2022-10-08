local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

local mouse = Players.LocalPlayer:GetMouse()

local FlyAPI = import('packages/common/fly')
FlyAPI.Start()

local TeleportAPI = import('packages/common/teleport')
TeleportAPI.Start()

local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = deepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

return {
    init = function(windw)
        local tab = windw:Tab{Text = "EBG-Exploits"}
        local function buildSpellSpoofSection()
            local remote = ReplicatedStorage:WaitForChild("Remotes").DoMagic
            local spoofedSpells = {
                ['Lightning Flash'] = {
                    Enabled = false,
                    GetOverride = function()
                        if mouse.Target then
                            return {End = CFrame.new(mouse.Hit.Position + Vector3.new(0, 4, 0))}
                        end
                    end,
                },
                ['Lightning Barrage'] = function()
                    if mouse.Target then
                        local pos = mouse.Hit.Position
                        return {Direction = CFrame.lookAt(pos - Vector3.new(0, 10, 0), pos)}
                    end
                end,
            }
            local spellSpoofSection = tab:Section{Text = "Spell Spoofing Options"}
            
            local old; old = hookmetamethod(game, '__namecall', function(self, ...)
                if not checkcaller() then
                    if getnamecallmethod() == "InvokeServer" then
                        if self == remote then
                            local realArgs = {...}
                            local SpellName = realArgs[2]
                            local foundSpoofedData = spoofedSpells[SpellName]
                            if foundSpoofedData.Enabled ~= nil and foundSpoofedData.Enabled == true then
                                local fakeArgs = deepCopy(realArgs)
                                local originalData = table.remove(fakeArgs, 3)
                                local newData = foundSpoofedData.GetOverride()
                                table.insert(fakeArgs, if newData ~= nil then newData else originalData)
                                return old(self, unpack(fakeArgs))
                            end
                        end
                    end
                end

                return old(self, ...)
            end)
        end

        buildSpellSpoofSection()
    end
}