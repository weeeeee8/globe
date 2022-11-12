local RunService = game:GetService("RunService")

local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

local Maid = import('lib/maid')

local RNG = Random.new()

return {
    init = function(windw)
        local tab = windw:Tab{Text = "Funky Friday"}
        local function buildAutoHitNoteSection()
            local tempMaid = Maid.new()
            oh.Maid:GiveTask(tempMaid)
            local stack, push_stack, pop_stack do
                stack = {}
                push_stack = function(input: any)
                    table.insert(stack, input)
                end
                pop_stack = function()
                    if #stack <= 0 then return nil end
                    local output = table.remove(stack, #stack)
                    return output
                end
            end

            local RUNNING_NOTES = {}
            local KEYCODE_BY_INDEX = {
                ["0"] = 0x41,
                ["1"] = 0x53,
                ["2"] = 0x4B,
                ["3"] = 0x4C,
            }

            local noteAccuracy = 0.05
            local tryNotAcccurate = false
            local section = tab:Section{Text = "AutoHit Note Options"}
            
            section:Input{
                Text = "Set Accuracy",
                Placeholder = "Accuracy <0-0.3>",
                Callback = function(str)
                    local num = tonumber(str)
                    if num then
                        num = math.clamp(num, 0, 0.3)
                        noteAccuracy = num
                    end
                end
            }

            section:Toggle{
                Text = "Should Try not Accurate",
                Callback = function(toggled)
                    tryNotAcccurate = toggled
                end
            }

            section:Button{
                Text = "Toggle Autohit",
                Callback = function()
                    local GUI = game.Players.LocalPlayer.PlayerGui:WaitForChild("GameUI")
                    local Arrows = GUI:WaitForChild("Arrows")
                    tempMaid:DoCleaning()
                    for _, frame in ipairs(Arrows.Left.Arrows:GetChildren()) do
                        if not frame:IsA("Frame") then continue end
                        local strIndex = tostring(frame.Name:sub(6, #frame.Name))
                        tempMaid:GiveTask(frame.InnerFrame.Column.ChildAdded:Connect(function(c)
                            local name = c.Name:lower()
                            if name == "frame" then
                                push_stack(c)
                            elseif name == "note" then
                                local data = {
                                    note = c,
                                    keycode = KEYCODE_BY_INDEX[strIndex],
                                    index = strIndex,
                                }
        
                                local foundFrame = pop_stack()
                                if foundFrame then
                                    data.frameSizeTime = (foundFrame.Size.Y.Scale * 0.35) - noteAccuracy
                                end
                                RUNNING_NOTES[data] = true
        
                                c.Destroying:Once(function()
                                    if not data.frameSizeTime then
                                        keyrelease(data.keycode)
                                    end
                                    RUNNING_NOTES[data] = nil
                                end)
                            end
                        end))
                    end
                end
            }
            
            oh.Maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
                for data in pairs(RUNNING_NOTES) do
                    local pos = data.note.Position.Y.Scale
                    local accuracy = noteAccuracy
                    if tryNotAcccurate then
                        accuracy = RNG:NextNumber(noteAccuracy, noteAccuracy+0.1)
                    end
                    if pos < (0 + accuracy) then
                        coroutine.wrap(function()
                            keypress(data.keycode)
                            if data.frameSizeTime then
                                task.wait(data.frameSizeTime)
                            end
                            keyrelease(data.keycode)
                        end)()
                        RUNNING_NOTES[data] = nil
                        continue
                    end
                end
            end))
        end

        buildAutoHitNoteSection()
    end,
}