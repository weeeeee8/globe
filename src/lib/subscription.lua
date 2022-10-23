local Signal = import('lib/signal')

local Subscription = {}
Subscription.__index = Subscription

function Subscription.new(v, maid)
    local self = setmetatable({
        _v = v,
        _changed = Signal.new(),
        value = v
    })

    if maid then
        maid:GiveTask(self._changed)
    end

    return self
end

function Subscription:get()
    return self._v
end

function Subscription:set(nV)
    if self.value ~= nV then
        self._v = nV
    end
    self.value = nV
    self._changed:Fire(nV)
end

function Subscription:subscribe(fn)
    return self._changed:Connect(fn)
end

return Subscription