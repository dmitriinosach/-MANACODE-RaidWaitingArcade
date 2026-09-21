local ADDON, ns = ...
local GRAIN_TEX = "Interface\\Buttons\\WHITE8X8"
local PUFF_TEX  = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local FULL      = { 0, 1, 0, 1 }
local CHALK = { 0.90, 0.86, 0.78 }
local LIFT  = 0.22
local GRAINS  = 12
local PUFFS   = 6
local GRAIN_T = 0.42
local PUFF_T  = 0.55
local rng
local function tone(tint, k)
    local r = tint[1] + (CHALK[1] - tint[1]) * LIFT
    local g = tint[2] + (CHALK[2] - tint[2]) * LIFT
    local b = tint[3] + (CHALK[3] - tint[3]) * LIFT
    return math.min(1, r * k), math.min(1, g * k), math.min(1, b * k)
end
function ns.FX.Dust(parent, x, y, w, tint, scale)
    if not parent then return end
    local level = ns.FX.Level()
    if level == "off" then return end
    scale = scale or 1
    if level == "plain" then scale = scale * 0.5 end
    rng = rng or ns.RNG.New(time())
    tint = tint or { 0.6, 0.58, 0.55 }
    local half = w / 2
    local puffs = math.max(2, math.floor(PUFFS * scale + 0.5))
    for i = 1, puffs do
        local side = (i % 2 == 0) and 1 or -1
        local sz = w * (0.22 + rng:Float() * 0.16)
        local ox = side * half * (0.55 + rng:Float() * 0.4)
        local f = ns.FX.Ghost(parent, x + ox, y + sz * 0.15, sz, PUFF_TEX, FULL)
        f.tex:SetVertexColor(tone(tint, 0.9 + rng:Float() * 0.2))
        f:SetAlpha(0.55 + rng:Float() * 0.2)
        local push = half * (0.35 + rng:Float() * 0.45)
        f.move:SetOffset(side * push, 4 + rng:Int(6))
        f.move:SetDuration(PUFF_T)
        f.move:SetSmoothing("OUT")
        f.grow:SetScale(1.9, 1.5)
        f.grow:SetDuration(PUFF_T)
        f.grow:SetSmoothing("OUT")
        f.fade:SetChange(-1)
        f.fade:SetDuration(PUFF_T * 0.6)
        f.fade:SetStartDelay(PUFF_T * 0.4)
        f.anim:Play()
    end
    local grains = math.max(4, math.floor(GRAINS * scale + 0.5))
    for i = 1, grains do
        local side = (i % 2 == 0) and 1 or -1
        local sz = 2 + rng:Int(3)
        local ox = side * half * (0.7 + rng:Float() * 0.3)
        local f = ns.FX.Ghost(parent, x + ox, y + rng:Int(3), sz, GRAIN_TEX, FULL)
        f.tex:SetVertexColor(tone(tint, 0.75 + rng:Float() * 0.45))
        f:SetAlpha(0.8 + rng:Float() * 0.2)
        local push = half * (0.5 + rng:Float() * 0.9)
        local drop = -(2 + rng:Int(8))
        f.move:SetOffset(side * push, drop)
        f.move:SetDuration(GRAIN_T)
        f.move:SetSmoothing("OUT")
        f.grow:SetScale(0.6, 0.6)
        f.grow:SetDuration(GRAIN_T)
        f.fade:SetChange(-1)
        f.fade:SetDuration(GRAIN_T * 0.5)
        f.fade:SetStartDelay(GRAIN_T * 0.5)
        f.anim:Play()
    end
end
ns.RegisterFX{
    key = "dust", cost = 10, cheaper = "shrink",
    play = function(parent, cells)
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.move:SetOffset(0, -c.size * 0.3)
            f.move:SetDuration(0.22)
            f.move:SetSmoothing("IN")
            f.grow:SetScale(1, 0.15)
            f.grow:SetDuration(0.22)
            f.grow:SetSmoothing("IN")
            f.fade:SetChange(-1)
            f.fade:SetDuration(0.22)
            f.anim:Play()
            ns.FX.Dust(parent, c.x, c.y - c.size / 2, c.size, nil, 0.7)
        end
    end,
}
