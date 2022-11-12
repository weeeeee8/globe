local default = {
    new = function()
        local stack, pushStack, popStack, getSize, findAndRemove, clearAll do
            stack = {}
            pushStack = function(input)
                table.insert(stack, input)
            end 
            popStack = function()
                if #stack <= 0 then return nil end
                return table.remove(stack, #stack)
            end
            getSize = function()
                return #stack
            end
            findAndRemove = function(input)
                local foundIndex = table.find(stack, input)
                if foundIndex then
                    table.remove(stack, foundIndex)
                end
            end
            clearAll = function()
                table.clear(stack)
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