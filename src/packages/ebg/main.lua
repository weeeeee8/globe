local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

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

        local function getMouseWorldPosition()
            local pos = UserInputService:GetMouseLocation()
            local ray = workspace.CurrentCamera:ViewportPointToRay(pos.X, pos.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 2000)
            return if result then result.Position else ray.Origin + (ray.Direction * 2000)
        end

        local overrideMouseCFrame = CFrame.new()
        local isMouseOverriden = false
        local oldMouse; oldMouse = hookmetamethod(mouse, '__index', function(self, key)
            if not checkcaller() then
                if isMouseOverriden and key == "Hit" then
                    return overrideMouseCFrame
                end
                return oldMouse(self, key)
            end
            return oldMouse(self, key)
        end)

        oh.Maid:GiveTask(function()
            isMouseOverriden = false
            for k in pairs(spoofedSpells) do
                spoofedSpells[k] = false
            end
        end)

        local tab = windw:Tab{Text = "EBG-Exploits"}
        local function buildSpellSpoofSection()
            local remote = ReplicatedStorage:WaitForChild("Remotes").DoMagic
            local spellSpoofSection = tab:Section{Text = "Spell Spoofing Options"}

            local oldSpoof; oldSpoof = hookmetamethod(game, '__namecall', function(self, ...)
                if not checkcaller() then
                    if getnamecallmethod() == "InvokeServer" and self == remote then
                        local realArgs = {...}
                        local SpellName = tostring(realArgs[2])
                        local foundSpoofedData = spoofedSpells[SpellName]
                        if foundSpoofedData then
                            local fakeArgs = {unpack(realArgs)}
                            if SpellName == "Lightning Flash" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = realArgs[3].Origin
                                fakeArgs[3].End = getMouseWorldPosition()
                            elseif SpellName == "Lightning Barrage" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Direction = if isMouseOverriden or mouse.Target then CFrame.lookAt(mouse.Hit.Position - Vector3.new(0, 17, 0), mouse.Hit.Position) else realArgs[3].Direction
                            elseif SpellName == "Refraction" then
                                fakeArgs[3] = if isMouseOverriden or mouse.Target then CFrame.lookAt(mouse.Hit.Position - Vector3.new(0, 20, 0), mouse.Hit.Position) else realArgs[3]
                            elseif SpellName == "Splitting Slime" or SpellName == "Illusive Atake" then
                                fakeArgs[3] =  if isMouseOverriden or mouse.Target then CFrame.new(mouse.Hit.Position) else realArgs[3]
                            elseif SpellName == "Blaze Column" then
                                fakeArgs[3] = if isMouseOverriden or mouse.Target then CFrame.new(mouse.Hit.Position) * CFrame.new(0, 2, 0) * CFrame.Angles(math.pi / 2, math.pi / 2, 0) else realArgs[3]
                            elseif SpellName == "Water Beam" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = if isMouseOverriden or mouse.Target then mouse.Hit.Position + Vector3.new(0, 7, 0) else realArgs[3].Origin
                            elseif SpellName == "Orbital Strike" then
                                fakeArgs[3] = if isMouseOverriden or mouse.Target then CFrame.lookAt(mouse.Hit.Position, mouse.Hit.Position - Vector3.new(0, 20, 0)) else realArgs[3]
                            end
                            return oldSpoof(self, unpack(fakeArgs))
                        end
                    end
                end

                return oldSpoof(self, ...)
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

        local function buildAutotargetSection()
            local NUMS_OF_PREDICTIONS = 10
            local FIXED_TIME_SCALE = 1
            local PREDICTION_INDEX = 5
            local MINDIST = 200

            local pointsFolder = workspace:FindFirstChild(".points") or Instance.new("Folder", workspace)
            pointsFolder.Parent = workspace

            local targetPlayer
            local enabled = false
            local targetOption = "locked"
            local autofill = {"character", "mouse", "locked"}
            local players = {}
            local ignorePlayers= {[Players.LocalPlayer] = true}
            local points = {}
            oh.Maid:GiveTask(function()
                table.clear(ignorePlayers)
                for _, v in ipairs(points) do
                    v:Destroy()
                end
                table.clear(points)
                targetPlayer = nil
            end)

            local function newPoint(index, i)
                local point = points[index]
                if not point then
                    local part = Instance.new("Part")
                    part.Size = Vector3.one
                    part.Shape = Enum.PartType.Ball

                    part.Anchored = true
                    part.CanCollide = false
                    part.CanQuery = false
                    part.Transparency = 0
                    part.Material = Enum.Material.Neon

                    part.Parent = pointsFolder
                    points[index] = part
                    return part
                end
                point.BrickColor = if index == i then BrickColor.Green() else BrickColor.Red()
                point.Size = if index == i then Vector3.one * 3 else Vector3.one
                return point
            end

            local function cleanPoints()
                for i = #points, 1, -1 do
                    points[i].CFrame = CFrame.new(0, 10e8, 0)
                end
            end

            local function getNearestPlayerFromPosition(position)
                local plrs = {}
                for _,v in ipairs(Players:GetPlayers()) do
                    if ignorePlayers[v] then continue end
                    if not v.Character then continue end    
                    local hum = v.Character:FindFirstChild("Humanoid")
                    if v.Character:FindFirstChildOfClass("ForceField") then continue end
                    if not hum or hum.Health <= 0 then continue end
                    local d = v:DistanceFromCharacter(position)
                    if d > MINDIST then continue end
                    table.insert(plrs, {
                        dist = d,
                        plr = v
                    })
                end
        
                table.sort(plrs, function(a, b)
                    return a.dist < b.dist
                end)
        
                return if plrs[1] then plrs[1].plr else nil
            end

            local _lastPlayer = nil
            local dirty = false

            local section = tab:Section{
                Text = "Autotargeting Options", Side = "Right",
            }

            local playerLabel = section:Label{
                Text = "Current locked target: None",
                Color = oh.Constants.StateColors.Invalid
            }
            
            local optionLabel = section:Label{
                Text = "Current option: " .. (string.sub(targetOption, 1, 1):upper() .. string.sub(targetOption, 2, #targetOption)),
            }

            section:Keybind{
                Text = "Toggle autotarget",
                Default = Enum.KeyCode.C,
                Callback = function()
                    enabled = not enabled
                    StarterGui:SetCore("SendNotification", {
                        Title = "[Globe]",
                        Text = (if enabled then "En" else "Dis") .. "abled Autotargeting",
                        Duration = 2,
                    })
                end
            }

            section:Input{
                Text = "Set Minimum Distance",
                Placeholder = "Minimum Distance",
                Callback = function(txt)
                    local num = tonumber(txt)
                    if not num then num = 200 end
                    MINDIST = num
                end
            }

            section:Input{
                Text = "Set Prediction Index",
                Placeholder = "Prediction Index",
                Callback = function(txt)
                    local num = tonumber(txt)
                    if not num then num = 3 end
                    num = math.clamp(num, 1, NUMS_OF_PREDICTIONS)
                    PREDICTION_INDEX = num
                end
            }

            section:Input{
                Text = "Whitelist player",
                Placeholder = "Whitelist player",
                Callback = function(txt)
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:find(txt, 1) or plr.Name:find(txt, 1) then
                            player = plr
                            break
                        end
                    end
                    
                    if player and ignorePlayers[player] == nil then
                        ignorePlayers[player] = true
                        StarterGui:SetCore("SendNotification", {
                            Title = "[Globe]",
                            Text = "Whitelisted player \"" .. tostring(player) .. "\"",
                            Duration = 2,
                        })
                    end
                end
            }

            section:Input{
                Text = "Unwhitelist player",
                Placeholder = "Unwhitelist player",
                Callback = function(txt)
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:find(txt, 1) or plr.Name:find(txt, 1) then
                            player = plr
                            break
                        end
                    end
                    
                    if player and ignorePlayers[player] ~= nil then
                        ignorePlayers[player] = nil
                        StarterGui:SetCore("SendNotification", {
                            Title = "[Globe]",
                            Text = "Unwhitelisted player \"" .. tostring(player) .. "\" from autotargeting.",
                            Duration = 2,
                        })
                    end
                end
            }

            section:Input{
                Text = "Set Target Option",
                Placeholder = "Locked / Mouse / Character",
                Callback = function(txt)
                    for i = #autofill, 1, -1 do
                        if autofill[i]:find(txt:lower(), 1) then
                            targetOption = autofill[i]
                            optionLabel:Set{
                                Text = "Current option: " .. (string.sub(targetOption, 1, 1):upper() .. string.sub(targetOption, 2, #targetOption)),
                            }
                            return
                        end
                    end
                end
            }
            
            section:Input{
                Text = "Set Locked Player",
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
                    
                    targetPlayer = player
                end
            }

            
            oh.Maid:GiveTask(RunService.Stepped:Connect(function(_, dt)
                local pos = Vector3.zero
                local targetChar
                if targetOption == "locked" then
                    if targetPlayer then
                        targetChar = targetPlayer.Character
                    end
                elseif targetOption == "mouse" then
                    local foundPlayer = getNearestPlayerFromPosition(mouse.Hit.Position)
                    if foundPlayer then
                        targetChar = foundPlayer.Character
                    end
                elseif targetOption == "character" then
                    local rhrp = getHRP()
                    if rhrp then
                        local foundPlayer = getNearestPlayerFromPosition(rhrp.Position)
                        if foundPlayer then
                            targetChar = foundPlayer.Character
                        end
                    end
                end
                
                if targetChar and enabled then
                    dirty = true
                    local plr = Players:GetPlayerFromCharacter(targetChar)
                    if _lastPlayer ~= plr then
                        _lastPlayer = plr

                        playerLabel:Set{
                            Text = "Current locked target: " .. if plr ~= nil then tostring(plr.Name) else "None",
                            Color = if plr ~= nil then oh.Constants.StateColors.Valid else oh.Constants.StateColors.Invalid
                        }
                    end

                    if not players[plr] then
                        players[plr] = {
                            lastVelocity = Vector3.zero
                        }
                    end

                    local foundForceFied = targetChar:FindFirstChildOfClass("ForceField")
                    if foundForceFied then return end
                    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local data = players[plr]
        
                        local velocity = hrp.AssemblyLinearVelocity
                        local accel = (velocity-data.lastVelocity) / dt
        
                        for i = 1, NUMS_OF_PREDICTIONS do
                            local Point: Part = newPoint(i, PREDICTION_INDEX)
                            local t = (i / NUMS_OF_PREDICTIONS) * FIXED_TIME_SCALE
                            local p
                            if hrp:FindFirstChildOfClass("BodyPosition") then
                                p = hrp.Position
                            else
                                p = hrp.Position + velocity * t + 0.5 * accel * (t * t)
                            end
                            Point.Position = p
                            if i == PREDICTION_INDEX then
                                pos = p
                            end
                        end
        
                        data.lastVelocity = velocity
                    end
                else
                    if dirty then
                        dirty = false
                        cleanPoints()
                        playerLabel:Set{
                            Text = "Current locked target: None",
                            Color = oh.Constants.StateColors.Invalid
                        }
                    end
                end
        
                overrideMouseCFrame = CFrame.new(pos)
                if enabled == true then
                    if pos ~= Vector3.zero then
                        isMouseOverriden = true
                    else
                        isMouseOverriden = false
                    end
                else
                    isMouseOverriden = false
                end
            end))
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
									pos = pos + (ohrp.AssemblyLinearVelocity.Unit * (ohum.WalkSpeed * 0.75))
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
        buildAutotargetSection()
        buildDisorderIgnitionSection()
    end
}