local default = {
    new = function()
        local stack, pushStack, popStack, getSize, findAndRemove, clearAll do
            stack = {}
            pushStack = function(input)
                stack[#stack+1] = input
            end 
            popStack = function()
                if #stack <= 0 then return nil end
                local output = stack[#stack]
                stack[#stack] = nil
                return output
            end
            getSize = function()
                return #stack
            end
            findAndRemove = function(input)
                local function find(stack, input)
                    for i = #stack, 1, -1 do
                        if stack[i] == input then
                            return i
                        end
                    end
                    return nil
                end
                local foundIndex = find(stack, input)
                if foundIndex then
                    stack[#stack] = nil
                end
            end
            clearAll = function()
                for i = #stack, 1, -1 do
                    stack[i] = nil
                end
            end
        end

        return {
            Size = getSize,
            Push = pushStack,
            Pop = popStack,
            FindAndRemove = findAndRemove,
            Clear = clearAll
        }
    end
}

return default