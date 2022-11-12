local stack = import('lib/stack')
stack = stack.new()

local function cleanhook(hookData)
    if hookData.Type == "hookmetamethod" then
        hookData.Data.Hook(unpack(hookData.Data.Args))
    end
end

local util = {}

function util.hookmetamethod(object, type, hook)
    local old; old = hookmetamethod(object, type, function(...)
        return hook(old, ...)
    end)
    local data = {
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
    stack.Push(data)
    return function()
        stack.FindAndRemove(data)
        cleanhook(data)
    end
end

function util.clearhooks()
    while stack.Size() > 1 do
        local hookData = stack.Pop()
        cleanhook(hookData)
    end
end

return util