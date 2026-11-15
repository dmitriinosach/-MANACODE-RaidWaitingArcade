local ADDON, ns = ...
ns.pools = {}
local Pool = {}
Pool.__index = Pool
function ns.NewPool(factory, reset)
    return setmetatable({ items = {}, n = 0, factory = factory, reset = reset }, Pool)
end
function Pool:Acquire()
    self.n = self.n + 1
    local it = self.items[self.n]
    if not it then
        it = self.factory(self)
        self.items[self.n] = it
    end
    if self.reset then self.reset(it, self) end
    it:Show()
    return it
end
function Pool:Reset()
    self.n = 0
end
function Pool:HideExtras()
    for i = self.n + 1, #self.items do
        self.items[i]:Hide()
    end
end
function Pool:HideAll()
    self.n = 0
    for i = 1, #self.items do
        self.items[i]:Hide()
    end
end
function Pool:Size()
    return #self.items
end
function Pool:Take()
    local free = self.free
    local it = free and free[#free]
    if it then
        free[#free] = nil
        self.idle[it] = nil
    else
        it = self.factory(self)
        self.items[#self.items + 1] = it
    end
    if self.reset then self.reset(it, self) end
    it:Show()
    return it
end
function Pool:Release(it)
    self.idle = self.idle or {}
    if self.idle[it] then return end
    self.idle[it] = true
    self.free = self.free or {}
    self.free[#self.free + 1] = it
    it:Hide()
end
