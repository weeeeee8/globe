local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local mouse = Players.LocalPlayer:GetMouse()
local stack = import('lib/stack')
local globesettings = import('lib/globesettings')
local fnUtil = import('lib/functionUtil')

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

local function makeSet(...)
    local t = {} 
    local set = {...}
    for i = 1, #set do t[set[i]] = true end
    return t
end

return {
    init = function(windw)
        local wrapSettingFn = globesettings.group("ebg")

        local function getMouseWorldPosition()
            local pos = UserInputService.GetMouseLocation(UserInputService)
            local ray = workspace.CurrentCamera.ViewportPointToRay(workspace.CurrentCamera, pos.X, pos.Y)
            local result = workspace.Raycast(workspace, ray.Origin, ray.Direction * 2000)
            return if result then result.Position else ray.Origin + (ray.Direction * 2000)
        end

        local overrideMouseCFrame = CFrame.new()
        local isMouseOverriden = false
        fnUtil.hookmetamethod(mouse, '__index', function(old, self, key)
            if not checkcaller() then
                if isMouseOverriden and key == "Hit" then
                    return overrideMouseCFrame
                end
                return old(self, key)
            end
            return old(self, key)
        end)
        
        local docmagic = ReplicatedStorage:WaitForChild("Remotes").DoClientMagic
        local domagic = ReplicatedStorage:WaitForChild("Remotes").DoMagic
        local reservekey = ReplicatedStorage:WaitForChild("Remotes").KeyReserve

        local tab = windw:Tab{Text = "Elemental Battlegrounds"}
        local function buildSpellSpoofSection()
            local spoofedSpells = wrapSettingFn('SavedSpoofSpellsSettings',{
                ['Lightning Flash'] = false,
                ['Lightning Barrage'] = false,
                ['Splitting Slime'] = false,
                ['Illusive Atake'] = false,
                ['Blaze Column'] = false,
                ['Refraction'] = false,
                ['Water Beam'] = false,
                ['Orbital Strike'] = false,
                ['Orbs of Enlightment'] = false,
            })

            oh.Maid:GiveTask(function()
                spoofedSpells:save()
            end)

            local spellSpoofSection = tab:Section{Text = "Spell Spoofing Options"}

            fnUtil.hookmetamethod(game, '__namecall', function(old, self, ...)
                if not checkcaller() then
                    if getnamecallmethod() == "InvokeServer" and self == domagic then
                        local realArgs = {...}
                        local SpellName = tostring(realArgs[2])
                        local isSpoofed = spoofedSpells[SpellName]
                        if isSpoofed == true then
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
                                fakeArgs[3] = if isMouseOverriden or mouse.Target then CFrame.new(mouse.Hit.Position) * CFrame.Angles(math.pi / 2, math.pi / 2, 0) else realArgs[3]
                            elseif SpellName == "Water Beam" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = if isMouseOverriden or mouse.Target then mouse.Hit.Position + Vector3.new(0, 7, 0) else realArgs[3].Origin
                            elseif SpellName == "Orbital Strike" then
                                fakeArgs[3] = if isMouseOverriden or mouse.Target then CFrame.lookAt(mouse.Hit.Position, mouse.Hit.Position - Vector3.new(0, 20, 0)) else realArgs[3]
                            elseif SpellName == "Orbs of Enlightment" then
                                local c = {}
                                for i = 1, #realArgs[3].Coordinates do
                                    c[#c+1] = if isMouseOverriden or mouse.Target then mouse.Hit.Position + Vector3.new(0, 2, 0) else realArgs[3].Coordinates[i] or CFrame.identity
                                end
                                local newArgs = {
                                    Origin = if isMouseOverriden or mouse.Target then mouse.Hit.Position + Vector3.new(0, 2, 0) else realArgs[3].Origin,
                                    Coordinates = c
                                }
                                fakeArgs[3] = newArgs
                            end
                            return old(self, unpack(fakeArgs))
                        else
                            local fakeArgs = {unpack(realArgs)}
                            if SpellName == "Lightning Flash" then
                                if isMouseOverriden then
                                    local hrp = Players.LocalPlayer.Character.FindFirstChild(Players.LocalPlayer.Character, "HumanoidRootPart")
                                    if hrp then
                                        fakeArgs[3] = {}
                                        fakeArgs[3].Origin = hrp.Position
                                        fakeArgs[3].End = hrp.Position + ((getMouseWorldPosition() - hrp.Position).Unit * 50)
                                    end
                                end
                            elseif SpellName == "Rainbow Dash" then
                                if isMouseOverriden then
                                    local hrp = Players.LocalPlayer.Character.FindFirstChild(Players.LocalPlayer.Character, "HumanoidRootPart")
                                    if hrp then
                                        fakeArgs[3] = {}
                                        fakeArgs[3].Dir = CFrame.lookAt(hrp, getMouseWorldPosition())
                                    end
                                end
                            end
                            return old(self, unpack(fakeArgs))
                        end
                    end
                end

                return old(self, ...)
            end)

            for k, _ in pairs(spoofedSpells.env) do
                k = k:sub(2, #k)
                spellSpoofSection:Toggle({
                    Text = k,
                    Callback = function(v)
                        spoofedSpells:newsetting(k, v)
                    end
                }):Set(spoofedSpells:getsetting(k))
            end
        end

        local function buildPunchAuraSection()
            local MINDIST = 20

            local enabled = false
            local ignorePlayers= {[Players.LocalPlayer] = true}
            local remote = ReplicatedStorage:WaitForChild("Remotes").Combat

            oh.Maid:GiveTask(function()
                table.clear(ignorePlayers)
            end)

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

            local section = tab:Section{
                Text = "Punch Aura Options", Side = "Right",
            }

            section:Keybind{
                Text = "Toggle Aura",
                Default = Enum.KeyCode.Z,
                Callback = function()
                    enabled = not enabled
                    StarterGui:SetCore("SendNotification", {
                        Title = "[Globe]",
                        Text = (if enabled then "En" else "Dis") .. "abled Punch Aura",
                        Duration = 2,
                    })
                end
            }

            section:Input{
                Text = "Blacklist player",
                Placeholder = "Blacklist player",
                Callback = function(txt)
                    if #txt <= 0 then return end
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
                            player = plr
                            break
                        end
                    end
                    
                    if player and ignorePlayers[player] == nil then
                        ignorePlayers[player] = true
                        StarterGui:SetCore("SendNotification", {
                            Title = "[Globe]",
                            Text = "Blacklisted player \"" .. tostring(player) .. "\" for punch aura",
                            Duration = 2,
                        })
                    end
                end
            }

            section:Input{
                Text = "Unblacklist player",
                Placeholder = "Unblacklist player",
                Callback = function(txt)
                    if #txt <= 0 then return end
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
                            player = plr
                            break
                        end
                    end
                    
                    if player and ignorePlayers[player] ~= nil then
                        ignorePlayers[player] = nil
                        StarterGui:SetCore("SendNotification", {
                            Title = "[Globe]",
                            Text = "Unblacklisted player \"" .. tostring(player) .. "\" from punch aura.",
                            Duration = 2,
                        })
                    end
                end
            }

            oh.Maid:GiveTask(RunService.Heartbeat:Connect(function()
                if enabled then
                    local rhrp = getHRP()
                    if rhrp then
                        local targetPlayer = getNearestPlayerFromPosition(rhrp.Position)
                        if targetPlayer then
                            remote:FireServer(1)
                            remote:FireServer(targetPlayer.Character)
                        end
                    end
                end
            end))
        end

        local function buildTechDiskSection()
            local setting = wrapSettingFn('SavedEnableTechLagValue', {
                Enabled = false
            })

            oh.Maid:GiveTask(function()
                setting:save()
            end)


            local conns = {}
            function conns:Destroy()
                for _, v in ipairs(self) do
                    v:Disconnect()
                    v = nil
                end
            end
            oh.Maid:GiveTask(conns)

            local function updateState()
                if not setting.Enabled then
                    conns:Destroy()
                else
                    table.insert(conns, game.Players.LocalPlayer.PlayerScripts.ChildAdded:Connect(function(c)
                        if c.Name == "DiscScript" then
                              c.Disabled = true
                            task.delay(1, c.Destroy, c)
                        end
                    end))

                    table.insert(conns, workspace['.Ignore']['.LocalEffects'].ChildAdded:Connect(function(c)
                        if c.Name == "LightDisc" then
                            task.delay(1, c.Destroy, c)
                        end
                        if c.Name == "DeadlyDisc" then
                            task.delay(1, c.Destroy, c)
                        end
                    end))
                end
            end

            local section = tab:Section{
                Text = "Disable Tech Lag State", Side = "Right",
            }

            section:Toggle({
                Text = "Disable All",
                Callback = function(toggle)
                    setting:newsetting("Enabled", toggle)
                    updateState()
                end,
            }):Set(setting:getsetting("Enabled"))
            updateState()
        end

        local function buildAutotargetSection()
            local setting = wrapSettingFn("SavedAutoTargetSettings", {
                PREDICTION_INDEX = 5,
                MINDIST = 200,
                RespectsObstruction = false,
                TargetOption = "Locked",
            })

            oh.Maid:GiveTask(function()
                setting:save()
            end)

            local NUMS_OF_PREDICTIONS = 16
            local FIXED_TIME_SCALE = 1
            local PREDICTION_INDEX = 5

            local pointsFolder = workspace:FindFirstChild(".points") or Instance.new("Folder", workspace)
            pointsFolder.Name = ".points"
            pointsFolder.Parent = workspace

            local targetPlayer
            local falsePredictionIndex = PREDICTION_INDEX
            local autoPredictIndex = false
            local enabled = false
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

            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {workspace.Map}
            params.FilterType = Enum.RaycastFilterType.Whitelist
            local function isObstructedByMap(p0, p1)
                return workspace.Raycast(workspace, p0, p1 - p0, params) ~= nil
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
                    if d > setting.MINDIST then continue end
                    if setting.RespectsObstruction == true and isObstructedByMap(getHRP().Position, hum.RootPart.Position) then continue end
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
                Text = "Current option: " .. (string.sub(setting.TargetOption, 1, 1):upper() .. string.sub(setting.TargetOption, 2, #setting.TargetOption)),
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

            section:Toggle({
                Text = "Respect Terrain",
                Callback = function(toggle)
                    setting:newsetting("RespectsObstruction", toggle)
                end
            }):Set(setting:getsetting("RespectsObstruction"))

            section:Toggle{
                Text = "Auto Index",
                Callback = function(toggle)
                    autoPredictIndex = toggle
                end
            }


            section:Input({
                Text = "Set Minimum Distance",
                Placeholder = "Minimum Distance",
                Callback = function(txt)
                    local num = tonumber(txt)
                    if not num then num = 200 end
                    setting:newsetting("MINDIST", num)
                end
            }):Set(setting:getsetting("MINDIST"))

            section:Input({
                Text = "Set Prediction Index",
                Placeholder = "Prediction Index",
                Callback = function(txt)
                    local num = tonumber(txt)
                    if not num then num = 3 end
                    num = math.clamp(num, 1, NUMS_OF_PREDICTIONS)
                    setting:newsetting("PREDICTION_INDEX", num)
                    falsePredictionIndex = setting.PREDICTION_INDEX
                end
            }):Set(setting:getsetting("PREDICTION_INDEX"))

            section:Input{
                Text = "Blacklist player",
                Placeholder = "Blacklist player",
                Callback = function(txt)
                    if #txt <= 0 then return end
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
                            player = plr
                            break
                        end
                    end
                    
                    if player and ignorePlayers[player] == nil then
                        ignorePlayers[player] = true
                        StarterGui:SetCore("SendNotification", {
                            Title = "[Globe]",
                            Text = "Blacklisted player \"" .. tostring(player) .. "\" for autotargeting",
                            Duration = 2,
                        })
                    end
                end
            }

            section:Input{
                Text = "Unblacklist player",
                Placeholder = "Unblacklist player",
                Callback = function(txt)
                    if #txt <= 0 then return end
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
                            player = plr
                            break
                        end
                    end
                    
                    if player and ignorePlayers[player] ~= nil then
                        ignorePlayers[player] = nil
                        StarterGui:SetCore("SendNotification", {
                            Title = "[Globe]",
                            Text = "Unblacklisted player \"" .. tostring(player) .. "\" from autotargeting.",
                            Duration = 2,
                        })
                    end
                end
            }

            section:Input({
                Text = "Set Target Option",
                Placeholder = "Locked / Mouse / Character",
                Callback = function(txt)
                    for i = #autofill, 1, -1 do
                        if autofill[i]:find(txt:lower(), 1) then
                            setting:newsetting("TargetOption", autofill[i])
                            optionLabel:Set{
                                Text = "Current option: " .. (string.sub(setting.TargetOption, 1, 1):upper() .. string.sub(setting.TargetOption, 2, #setting.TargetOption)),
                            }
                            break
                        end
                    end
                end
            }):Set(setting:getsetting("TargetOption"))
            
            section:Input{
                Text = "Set Locked Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(txt)
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
                            player = plr
                            break
                        end
                    end
                    
                    targetPlayer = player
                end
            }

            
            oh.Maid:GiveTask(RunService.Stepped:Connect(function(_, dt)
                local rhrp = getHRP()
                if rhrp then
                    local pos = Vector3.zero
                    local targetChar
                    if setting.TargetOption == "locked" then
                        if targetPlayer then
                            targetChar = targetPlayer.Character
                        end
                    elseif setting.TargetOption == "mouse" then
                        local foundPlayer = getNearestPlayerFromPosition(getMouseWorldPosition())
                        if foundPlayer then
                            targetChar = foundPlayer.Character
                        end
                    elseif setting.TargetOption == "character" then
                        local foundPlayer = getNearestPlayerFromPosition(rhrp.Position)
                        if foundPlayer then
                            targetChar = foundPlayer.Character
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
                        if foundForceFied then cleanPoints() return end
                        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                        local flipsHolder = targetChar:FindFirstChild("FlipsHolder")
                        if hrp then
                            if autoPredictIndex then
                                falsePredictionIndex = math.clamp(math.floor((hrp.Position - rhrp.Position).Magnitude / 10 + 0.5), 1, NUMS_OF_PREDICTIONS)
                            end

                            local data = players[plr]
            
                            local velocity = hrp.AssemblyLinearVelocity
                            local accel = (velocity-data.lastVelocity) / dt
            
                            for i = 1, NUMS_OF_PREDICTIONS do
                                local Point: Part = newPoint(i, setting.PREDICTION_INDEX)
                                local t = (i / NUMS_OF_PREDICTIONS) * FIXED_TIME_SCALE
                                local p
                                if (flipsHolder ~= nil) then
                                    if flipsHolder:FindFirstChildOfClass("BodyPosition") or flipsHolder:FindFirstChildOfClass("BodyForce") or hrp.Parent.Humanoid.FloorMateral == Enum.Material.Air then
                                        p = hrp.Position
                                    else
                                        p = hrp.Position + velocity * t + 0.5 * accel * (t * t)
                                    end
                                else
                                    p = hrp.Position + velocity * t + 0.5 * accel * (t * t)
                                end
                                Point.Position = p
                                if i == (if autoPredictIndex then falsePredictionIndex else setting.PREDICTION_INDEX) then
                                    if isObstructedByMap(hrp.Position, p) or (p - hrp.Position).Magnitude > 100 then
                                        pos = hrp.Position
                                    else
                                        pos = p
                                    end
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
                end
            end))
        end

        local function buildDisorderIgnitionSection()
            local setting = wrapSettingFn("SavedDisorderIgnitionTrollType", {
                Type = "void"
            })

            oh.Maid:GiveTask(function()
                setting:save()
            end)

            local targetPlayer = nil
            local voidPosition = Vector3.new(0, workspace.FallenPartsDestroyHeight + 3, 0)
            local floatPosition = Vector3.new(10e5, 2^26, 10e5)
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
                                if setting.Type == "void" then
                                    targetPos = voidPosition
                                elseif setting.Type == "spawn" then
                                    targetPos = spawnlocationsbyPlaceId[game.PlaceId]
                                elseif setting.Type == "float" then
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

            section:Input({
                Text = "Set Troll Type",
                Placeholder = "Troll type(?)",
                Tooltip = "Float / Void / Spawn",
                Callback = function(txt)
                    setting:newsetting("Type", txt:lower())
                end
            }):Set(setting:getsetting("Type"))

            section:Input{
                Text = "Set Target Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(txt)
                    local player
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == Players.LocalPlayer then continue end
                        if plr.DisplayName:sub(1, #txt) == txt or plr.Name:sub(1, #txt) == txt then
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

        local function buildAntiStaggerSection()
            local set = makeSet("BodyPosition", "BodyVelocity", "BodyGyro", "BodyForce", "BodyThrust")
            local bodyparts = makeSet("Head", "HumanoidRootPart", "FlipsHolder")
            local enabled = false
            local function onCharacterAdded(character)
                local hum = character:WaitForChild("Humanoid") :: Humanoid
                hum.StateChanged:Connect(function(old, new)
                    if (new == Enum.HumanoidStateType.PlatformStanding or new == Enum.HumanoidStateType.Seated or new == Enum.HumanoidStateType.Ragdoll) and enabled then
                        hum:ChangeState(old)
                    end
                end)
                for _, v in ipairs(character:GetChildren()) do
                    if not bodyparts[v.Name] then continue end
                    v.ChildAdded:Connect(function(c)
                        if not enabled then return end
                        if set[c.ClassName] then
                            if c:IsA("BodyVelocity") and (c.Name:lower() == "flyvel") then return end
                            if c:IsA("BodyGyro") and (c.Name:lower() == "flylook") then return end
                            task.delay(0.03, c.Destroy, c)
                        end
                    end)
                end
            end
            oh.Maid:GiveTask(Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
            if Players.LocalPlayer.Character then onCharacterAdded(Players.LocalPlayer.Character) end
            local section = tab:Section{Text = "Antistagger (anti-stuns) Options"}
            section:Toggle{
                Text = "Enable Antistagger",
                Callback = function(toggled)
                    enabled = toggled
                end
            }
        end

        local function buildAnimatorModifierSection()
            local section = tab:Section{Text = "Animator", Side = "Right"}
            local playerAnimator, hum
            local function onCharacterAdded(character)
                hum = character:WaitForChild("Humanoid")
                playerAnimator = hum:WaitForChild("Animator")
            end
            oh.Maid:GiveTask(Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
            oh.Maid:GiveTask(function()
                playerAnimator = nil
                hum = nil
            end)
            if Players.LocalPlayer.Character then onCharacterAdded(Players.LocalPlayer.Character) end
            section:Button{
                Text = "Remove Animator",
                Callback = function()
                    if playerAnimator then
                        playerAnimator.Parent = nil
                    end
                end
            }
            section:Button{
                Text = "Add Animator",
                Callback = function()
                    if playerAnimator then
                        playerAnimator.Parent = hum
                    end
                end
            }
        end

        local function buildUltTrollSection()
            local activeUltimate
            local section = tab:Section{Text = "Ult Troll Options"}
            local enabledUltimates = makeSet({
                    Name = "Arcane Guardian",
                    Parent = "Angel"
                }, {
                    Name = "Ethereal Acumen",
                    Parent = "Illusion"
                }, {
                    Name = "The World",
                    Parent = "Time"
                }, {
                    Name = "Void Opening",
                    Parent = "Void"
                }
            )
            local activeUltimateLabel = section:Label{
                Text = "Current Active Ultimate: None",
                Tooltip = "Will instantly cast the input ultimate displayed here."
            }

            section:Input{
                Text = "Set Ultimate",
                Placeholder = "Ultimate Name",
                Tooltip = "Arcane Guardian / Ethereal Acumen",
                Callback = function(txt)
                    if #txt <= 0 then
                        activeUltimate = nil
                        activeUltimateLabel:Set{
                            Text = "Current Active Ultimate: None",
                        }
                        return
                    end
                    
                    for v in pairs(enabledUltimates) do
                        if v.Name:sub(1, #txt) == txt then
                            activeUltimate = v
                            break
                        end
                    end
                    
                    activeUltimateLabel:Set{
                        Text = "Current Active Ultimate: " .. if activeUltimate ~= nil then tostring(activeUltimate.Name) else "None",
                        Color = if activeUltimate ~= nil then oh.Constants.StateColors.Valid else oh.Constants.StateColors.Invalid
                    }
                end
            }

            section:Keybind{
                Text = "Simulate Troll",
                Default = Enum.KeyCode.N,
                Callback = function()
                    if not activeUltimate then return end
                    local args = {
                        [1] = activeUltimate.Parent,
                        [2] = activeUltimate.Name,
                    }
                    local mousePos = if isMouseOverriden then overrideMouseCFrame.Position else mouse.Hit.Position

                    local additionalClientVals = {}
                    if activeUltimate.Name == "Arcane Guardian" then
                        args[3] = CFrame.new(mousePos + Vector3.new(0, 15.6, 0))
                    elseif activeUltimate.Name == "Ethereal Acumen" then
                        args[3] = CFrame.new(mousePos - Vector3.new(0, 25, 0))
                    elseif activeUltimate.Name == "The World" then
                        args[3] = {
                            rPos = mousePos,
                            norm = Vector3.yAxis,
                            rhit = workspace.Map.Part
                        }

                        additionalClientVals[1] = mousePos
                    elseif activeUltimate.Name == "Void Opening" then
                        args[3] = {
                            pos = mousePos
                        }
                    end
                    docmagic:FireServer(unpack(args, 1, 2), unpack(additionalClientVals))
                    domagic:InvokeServer(unpack(args))
                end
            }
        end

        local function buildSoundUltLag()
            local ULTIMATE_NAME = "Ultra-Sonic Wail"

            local curEventId = ""
            local forceCleanHooks
            local section = tab:Section{Text = "SoundUlt Lag [TEST]"}
            section:Toggle{
                Text = "Spoof Sound Ult",
                Callback = function(toggled)
                    if toggled then
                        
                        forceCleanHooks = fnUtil.hookmetamethod(game, "__namecall", function(old, self, ...)
                            if not checkcaller() then
                                local args = {...}
                                if getnamecallmethod() == "InvokeServer" and self == domagic then
                                    if args[2] == ULTIMATE_NAME then
                                        curEventId = args[3].eventid
                                    end
                                elseif getnamecallmethod() == "FireServer" and curEventId then
                                    if self.Name == curEventId then
                                        local c = {}
                                        for i = 1, 5 do
                                            for _, v in ipairs(game.Players.GetPlayers(game.Players)) do
                                                c[#c+1] = v.Character
                                            end
                                        end
                                        c[#c+1] = Players.LocalPlayer.Character
                                        return old(self, unpack{
                                            [1] = Vector3.new(0, 10e5, 0),
                                            [2] = c
                                        })
                                    end
                                end
                            end
                            return old(self, ...)
                        end)
                    else
                        stack.Clear()
                        if forceCleanHooks then
                            forceCleanHooks()
                            forceCleanHooks = nil
                        end
                    end
                end
            }
        end

        buildTechDiskSection()
        buildSpellSpoofSection()
        buildAutotargetSection()
        buildDisorderIgnitionSection()
        buildPunchAuraSection()
        buildAntiStaggerSection()
        buildAnimatorModifierSection()
        buildUltTrollSection()

        buildSoundUltLag()
    end
}