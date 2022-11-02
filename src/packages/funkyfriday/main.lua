local RunService = game:GetService("RunService")
local env = assert(getgenv, "[GLOBE] getgenv cannot be found, executor might not be supported")()

return {
    init = function(windw)
        local tab = windw:Tab{Text = "Funky Friday"}
        local function buildAutoHitNoteSection()
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
            local GUI = game.Players.LocalPlayer.PlayerGui:WaitForChild("GameUI")
            local Arrows = GUI:WaitForChild("Arrows")

            local enabled = false

            local section = tab:Section{Text = "AutoHit Note Options"}

            section:Toggle{
                Text = "Toggle Autohit",
                Callback = function(toggled)
                    enabled = toggled
                end
            }
            
            for _, frame in ipairs(Arrows.Left.Arrows:GetChildren()) do
                if not frame:IsA("Frame") then continue end
                local strIndex = tostring(frame.Name:sub(6, #frame.Name))
                oh.Maid:GiveTask(frame.InnerFrame.Column.ChildAdded:Connect(function(c)
                    if not enabled then return end
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
                            data.frameScaleSize = foundFrame.Size.Y.Scale
                        end
                        RUNNING_NOTES[data] = true

                        c.Destroying:Once(function()
                            RUNNING_NOTES[data] = nil
                        end)
                    end
                end))
            end
            oh.Maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
                for data in pairs(RUNNING_NOTES) do
                    local pos = data.note.Position.Y.Scale
                    local translateY = math.abs(pos)
                    if (translateY > 0) and translateY < (0 + noteAccuracy) then
                        coroutine.wrap(function()
                            keypress(data.keycode)
                            task.wait(data.frameScaleSize or 1/60)
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