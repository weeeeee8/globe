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
                ['Lightning Flash'] = false,
                ['Lightning Barrage'] = false,
                ['Splitting Slime'] = false,
                ['Illusive Atake'] = false,
                ['Blaze Column'] = false,
                ['Refraction'] = false,
            }
            local spellSpoofSection = tab:Section{Text = "Spell Spoofing Options"}
            
            local old; old = hookmetamethod(game, '__namecall', function(self, ...)
                if not checkcaller() then
                    if getnamecallmethod() == "InvokeServer" and self == remote then
                        local realArgs = {...}
                        local SpellName = realArgs[2]
                        local foundSpoofedData = spoofedSpells[SpellName]
                        if foundSpoofedData then
                            local fakeArgs = {}
                            fakeArgs[1] = realArgs[1]
                            fakeArgs[2] = realArgs[2]
                            if SpellName == "Lightning Flash" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = realArgs[3].Origin
                                fakeArgs[3].End = if mouse.Target then mouse.Hit.Position else realArgs[3].End
                            elseif SpellName == "Lightning Barrage" or SpellName == "Refraction" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Direction = if mouse.Target then CFrame.lookAt(mouse.Hit.Position - Vector3.new(0, 15, 0), mouse.Hit.Position) else realArgs[3].Direction
                            elseif SpellName == "Splitting Slime" or SpellName == "Illusive Atake" then
                                fakeArgs[3] = if mouse.Target then mouse.Hit else realArgs[3]
                            elseif SpellName == "Blaze Column" then
                                fakeArgs[3] = (realArgs[3]) * CFrame.Angles(math.pi / 2, math.pi / 2, 0)
                            end
                            return old(self, unpack(fakeArgs))
                        end
                    end
                end

                return old(self, ...)
            end)

            for k, _ in pairs(spoofedSpells) do
                spellSpoofSection:Toggle{
                    Text = k,
                    Callback = function(v)
                        spoofedSpells[k] = v
                    end
                }
            end
        end

        buildSpellSpoofSection()
    end
}