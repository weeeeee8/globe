local stack, pushStack, popStack, getSize do
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
end

Size = getSize
Push = pushStack
Pop = popStack
return getfenv()