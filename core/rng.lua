local ADDON, ns = ...
local floor = math.floor
local M = 2147483648
local A = 1664525
local C = 1013904223
ns.RNG = {}
local RNG = {}
RNG.__index = RNG
function ns.RNG.New(seed)
    local s = tonumber(seed) or time()
    s = floor(s) % M
    if s < 0 then s = s + M end
    return setmetatable({ s = s }, RNG)
end
function ns.RNG.Restore(state)
    return ns.RNG.New(state)
end
function RNG:State()
    return self.s
end
local function step(self)
    self.s = (A * self.s + C) % M
    return self.s
end
function RNG:Float()
    return step(self) / M
end
function RNG:Int(a, b)
    if b == nil then
        a, b = 1, a
    end
    if b <= a then return a end
    return a + floor(self:Float() * (b - a + 1))
end
function RNG:Shuffle(t)
    for i = #t, 2, -1 do
        local j = self:Int(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end
function RNG:Pick(t)
    local n = #t
    if n == 0 then return nil end
    return t[self:Int(n)]
end
