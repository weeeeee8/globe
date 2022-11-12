local stack = import('lib/stack')()

local util = {}

function util.hookmetamethod(object, type, hook)
    local old; old = hookmetamethod(object, type, function(...)
        return hook(old, ...)
    end)
    stack.Push{
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
    while stack.Size() > 1 do
        local hookData = stack.Pop()
        if hookData.Type == "hookmetamethod" then
            hookData.Data.Hook(unpack(Data.Data.Args))
        end
    end
end

return util