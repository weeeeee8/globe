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

local function getHRP()
    return Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

return {
    init = function(windw)
        local tab = windw:Tab{Text = "EBG-Exploits"}
        local function buildSpellSpoofSection()
            local targetPlayer
            local remote = ReplicatedStorage:WaitForChild("Remotes").DoMagic
            local spoofedSpells = {
                ['Lightning Flash'] = false,
                ['Lightning Barrage'] = false,
                ['Splitting Slime'] = false,
                ['Illusive Atake'] = false,
                ['Blaze Column'] = false,
                ['Refraction'] = false,
                ['Water Beam'] = false,
                ['Orbital Strike'] = false,
            }
            local spellSpoofSection = tab:Section{Text = "Spell Spoofing Options"}

            local labelComponent = spellSpoofSection:Label{
                Text = "Current target: None",
                Color = oh.Constants.StateColors.Invalid
            }

            local old; old = hookmetamethod(game, '__namecall', function(self, ...)
                if not checkcaller() then
                    if getnamecallmethod() == "InvokeServer" and self == remote then
                        local realArgs = {...}
                        local SpellName = realArgs[2]
                        local foundSpoofedData = spoofedSpells[SpellName]
                        if foundSpoofedData then
                            local hrp
                            if targetPlayer then
                                local tchar = targetPlayer.Character
                                if tchar then
                                    hrp = tchar:FindFirstChild("HumanoidRootPart")
                                end
                            end

                            local fakeArgs = {unpack(realArgs)}
                            if SpellName == "Lightning Flash" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = realArgs[3].Origin
                                fakeArgs[3].End = if mouse.Target then mouse.Hit.Position else realArgs[3].End
                            elseif SpellName == "Lightning Barrage" then
                                fakeArgs[3] = {}
                                local arg
                                if hrp ~= nil then
                                    arg = CFrame.lookAt(hrp.Position - Vector3.new(0, 17, 0), hrp.Position)
                                elseif mouse.Target then
                                    arg = CFrame.lookAt(mouse.Hit.Position - Vector3.new(0, 17, 0), mouse.Hit.Position)
                                else
                                    arg = realArgs[3]
                                end
                                fakeArgs[3].Direction = arg
                            elseif SpellName == "Refraction" then
                                local arg
                                if hrp ~= nil then
                                    arg = CFrame.lookAt(hrp.Position, hrp.Position - Vector3.new(0, 20, 0))
                                elseif mouse.Target then
                                    arg = CFrame.lookAt(mouse.Hit.Position, mouse.Hit.Position - Vector3.new(0, 20, 0))
                                else
                                    arg = realArgs[3]
                                end
                                fakeArgs[3] = arg
                            elseif SpellName == "Splitting Slime" or SpellName == "Illusive Atake" then
                                local arg
                                if hrp ~= nil then
                                    arg = hrp.CFrame
                                elseif mouse.Target then
                                    arg = mouse.Hit
                                else
                                    arg = realArgs[3]
                                end
                                fakeArgs[3] = arg
                            elseif SpellName == "Blaze Column" then
                                local arg
                                if hrp ~= nil then
                                    arg = hrp.CFrame * CFrame.Angles(math.pi / 2, math.pi / 2, 0)
                                elseif mouse.Target then
                                    arg = mouse.Hit * CFrame.new(0, 2, 0) * CFrame.Angles(math.pi / 2, math.pi / 2, 0)
                                else
                                    arg = realArgs[3]
                                end
                                fakeArgs[3] = arg
                            elseif SpellName == "Water Beam" then
                                fakeArgs[3] = {}
                                local arg
                                if hrp ~= nil then
                                    arg = hrp.Position
                                elseif mouse.Target then
                                    arg = mouse.Hit.Position + Vector3.new(0, 7, 0)
                                else
                                    arg = realArgs[3].Origin
                                end
                                fakeArgs[3].Origin = arg
                            elseif SpellName == "Orbital Strike" then
                                local arg
                                if hrp ~= nil then
                                    arg = hrp.CFrame
                                elseif mouse.Target then
                                    arg = mouse.Hit
                                else
                                    arg = realArgs[3]
                                end
                                fakeArgs[3] = arg
                            end
                            return old(self, unpack(fakeArgs))
                        end
                    end
                end

                return old(self, ...)
            end)

            spellSpoofSection:Input{
                Text = "Set Target Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(txt)
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:find(txt, 1) or plr.Name:find(txt, 1) then
                            player = plr
                            break
                        end
                    end
                    
                    labelComponent:Set{
                        Text = "Current target: " .. if player ~= nil then tostring(player.Name) else "None",
                        Color = if player ~= nil then oh.Constants.StateColors.Valid else oh.Constants.StateColors.Invalid
                    }
                    targetPlayer = player
                end
            }

            for k, _ in pairs(spoofedSpells) do
                spellSpoofSection:Toggle{
                    Text = k,
                    Callback = function(v)
                        spoofedSpells[k] = v
                    end
                }
            end
        end

        local function buildDisorderIgnitionSection()
            local docmagic = ReplicatedStorage:WaitForChild("Remotes").DoClientMagic
            local domagic = ReplicatedStorage:WaitForChild("Remotes").DoMagic
            local reservekey = ReplicatedStorage:WaitForChild("Remotes").KeyReserve

            local targetPlayer = nil
            local voidPosition = Vector3.new(0, workspace.FallenPartsDestroyHeight + 3, 0)
            local floatPosition = Vector3.one * 2147483646
            local trolltype = "void"
            local spawnlocationsbyPlaceId = {
                [2569625809]  = Vector3.new(-1100.52, 65.125, 282.28),
                [570158081] = Vector3.new(-1907.776, 126.015, -414.179),
                [537600204] = Vector3.new(1282.834, -83.49, -758.368),
            }

            local section = tab:Section{
                Text = "Disorder Ignition Troll"
            }

            local labelComponent = section:Label{
                Text = "Current target: None",
                Color = oh.Constants.StateColors.Invalid
            }


            -- going to make a stack here in the future, so that itll be more efficient
            section:Keybind{
                Text = "Simulate troll",
                Default = Enum.KeyCode.X,
                Callback = function()
                    if targetPlayer then
						local targetCharacter = targetPlayer.Character
						if targetCharacter then
							if targetCharacter:FindFirstChildOfClass("ForceField") then return end

                            local ohum, ohrp, rhrp = targetCharacter:FindFirstChild("Humanoid"), targetCharacter:FindFirstChild("HumanoidRootPart"), getHRP()
                            if ohum and ohrp and rhrp then
                                local targetPos = Vector3.zero
                                if trolltype == "void" then
                                    targetPos = voidPosition
                                elseif trolltype == "spawn" then
                                    targetPos = spawnlocationsbyPlaceId[game.PlaceId]
                                elseif trolltype == "float" then
                                    targetPos = floatPosition
                                end

                                local pos = ohrp.Position
								if ohrp.AssemblyLinearVelocity.Magnitude > 0 then
									pos = pos + (ohrp.AssemblyLinearVelocity.Unit * 5.1)
								end
                                rhrp.CFrame = CFrame.new(pos)
                                task.wait(0.175)
                                local args = {[1] = "Chaos", [2] = "Disorder Ignition"}
                                docmagic:FireServer(unpack(args))
                                local args = {[1] = "Chaos", [2] = "Disorder Ignition", [3] = {
                                    ['nearestHRP'] = ohrp.Parent.Head,
                                    ['nearestPlayer'] = targetPlayer,
                                    ['rpos'] = ohrp.Position,
                                    ['norm'] = Vector3.yAxis,
                                    ['rhit'] = workspace.Map.Part
                                }}
                                domagic:InvokeServer(unpack(args))
                                reservekey:FireServer(Enum.KeyCode.Y)
                                local _s = tick()
                                while tick()-_s < 3 do task.wait() end
								if not rhrp:FindFirstChild("ChaosLink") then return end
								if ohum.Health <= 0 then return end
                                rhrp.CFrame = CFrame.new(targetPos)
                                task.wait(0.1)
                                reservekey:FireServer(Enum.KeyCode.Y)
                            end
                        end
                    end
                end
            }

            section:Input{
                Text = "Set Troll Type",
                Placeholder = "Troll type(?)",
                Tooltip = "Float / Void / Spawn",
                Callback = function(txt)
                    trolltype = txt:lower()
                end
            }

            section:Input{
                Text = "Set Target Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(txt)
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:find(txt, 1) or plr.Name:find(txt, 1) then
                            player = plr
                            break
                        end
                    end
                    
                    labelComponent:Set{
                        Text = "Current target: " .. if player ~= nil then tostring(player.Name) else "None",
                        Color = if player ~= nil then oh.Constants.StateColors.Valid else oh.Constants.StateColors.Invalid
                    }
                    targetPlayer = player
                end
            }
        end

        buildSpellSpoofSection()
        buildDisorderIgnitionSection()
    end
}