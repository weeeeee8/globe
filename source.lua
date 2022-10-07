local env = getgenv()

local player = game:GetService("Players").LocalPlayer
local doMagic = game:GetService("ReplicatedStorage").Remotes.DoMagic
local mouse = player:GetMouse()

if ebg then
    ebg.clean()
end

local conns = {}

local main = {}
main.init = function()
    local function makeSet(...)
        local t = {} for _, v in ipairs({...}) do t[v] = true end return t
    end

    local MOVER_TYPES = makeSet('BodyForce', 'BodyPosition')

    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if not checkcaller() then
            if getnamecallmethod() == "InvokeServer" and self == doMagic then
                local args = {...}
                if args[2] == "Lightning Flash" then
                    local newArgs = {}
                    newArgs[1] = args[1]
                    newArgs[2] = args[2]
                    newArgs[3] = {}
                    newArgs[3].Origin = args[3].Origin
                    newArgs[3].End = if mouse.Target then mouse.Hit.Position else args[3].End
                    return old(self, unpack(newArgs))
                elseif args[2] == "Blaze Column" then
                    local newArgs = {}
                    newArgs[1] = args[1]
                    newArgs[2] = args[2]
                    newArgs[3] = args[3] * CFrame.Angles(math.pi / 2, math.pi / 2, 0)
                    return old(self, unpack(newArgs))
                elseif args[2] == "Lightning Barrage" then
                    local newArgs = {}
                    newArgs[1] = args[1]
                    newArgs[2] = args[2]
                    newArgs[3] = {
                        Direction = if mouse.Target then CFrame.lookAt(mouse.Hit.Position - Vector3.new(0, 15, 0), mouse.Hit.Position) else args[3]
                    }
                    return old(self, unpack(newArgs))
                end
            end
        end
        return old(self, ...)
    end)

    local function onCharacterAdded(character)
        character:WaitForChild("FlipsHolder").ChildAdded:Connect(function(child)
            if MOVER_TYPES[child.ClassName] then
                child:Destroy()
            end
        end)
    end
    table.insert(conns, player.CharacterAdded:Connect(onCharacterAdded))
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

function main.clean()
    for _, c in ipairs(conns) do c:Disconnect() end
    table.clear(conns)
end

env.ebg = main
return main