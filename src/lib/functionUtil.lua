local stack, pushStack, popStack do
    stack = {}
    pushStack = function(input)
        table.insert(stack, input)
    end
    popStack = function()
        if #stack <= 0 then return nil end
        return table.remove(stack, #stack)
    end
end

local util = {}

function util.hookmetamethod(object, type, hook)
    local old; old = hookmetamethod(object, type, function(...)
        return hook(old, ...)
    end)
    pushStack{
        Type = "hookmetamethod",
        Data = {
            Hook = hookmetamethod,
            Args = {
                [1] = object,
                [2] = type,
                [3] = function(...)
                    return old(...)
                end
            }
        }
    }
end

function util.clearhooks()
    while #stack > 1 do
        local hookData = popStack()
        if hookData.Type == "hookmetamethod" then
            hookData.Data.Hook(unpack(Data.Data.Args))
        end
    end
end

return util