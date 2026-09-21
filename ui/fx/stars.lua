local ADDON, ns = ...
local STAR_TEX = "Interface\\Cooldown\\star4"
local GLOW_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local FULL     = { 0, 1, 0, 1 }
local GOLD  = { 1.00, 0.88, 0.50 }
local WHITE = { 0.92, 0.96, 1.00 }
local SPARKS  = 9
local FLASH_T = 0.30
local SPARK_T = 0.55
local rng
function ns.FX.Stars(parent, x, y, size, scale)
    if not parent then return end
    local level = ns.FX.Level()
    if level == "off" then return end
    scale = scale or 1
    if level == "plain" then scale = scale * 0.5 end
    rng = rng or ns.RNG.New(time())
    local glow = ns.FX.Ghost(parent, x, y, size * 0.9, GLOW_TEX, FULL)
    glow.tex:SetBlendMode("ADD")
    glow.tex:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    glow:SetAlpha(0.7)
    glow.move:SetOffset(0, 0)
    glow.move:SetDuration(FLASH_T)
    glow.grow:SetScale(1.8, 1.8)
    glow.grow:SetDuration(FLASH_T)
    glow.grow:SetSmoothing("OUT")
    glow.fade:SetChange(-1)
    glow.fade:SetDuration(FLASH_T)
    glow.anim:Play()
    local flash = ns.FX.Ghost(parent, x, y, size * 0.8, STAR_TEX, FULL)
    flash.tex:SetBlendMode("ADD")
    flash.tex:SetVertexColor(WHITE[1], WHITE[2], WHITE[3])
    flash.move:SetOffset(0, 0)
    flash.move:SetDuration(FLASH_T)
    flash.grow:SetScale(2.2, 2.2)
    flash.grow:SetDuration(FLASH_T)
    flash.grow:SetSmoothing("OUT")
    flash.fade:SetChange(-1)
    flash.fade:SetDuration(FLASH_T)
    flash.anim:Play()
    local sparks = math.max(3, math.floor(SPARKS * scale + 0.5))
    for i = 1, sparks do
        local a = (i - 1) / sparks * math.pi * 2 + rng:Float() * 0.6
        local d = size * (0.35 + rng:Float() * 0.45)
        local sz = size * (0.18 + rng:Float() * 0.16)
        local c = (i % 3 == 0) and WHITE or GOLD
        local wait = rng:Float() * 0.16
        local life = SPARK_T * (0.7 + rng:Float() * 0.5)
        local f = ns.FX.Ghost(parent, x, y, sz, STAR_TEX, FULL)
        f.tex:SetBlendMode("ADD")
        f.tex:SetVertexColor(c[1], c[2], c[3])
        f.move:SetOffset(math.cos(a) * d, math.sin(a) * d + size * 0.12)
        f.move:SetDuration(life)
        f.move:SetStartDelay(wait)
        f.move:SetSmoothing("OUT")
        if i % 2 == 0 then
            f.grow:SetScale(1.7, 1.7)
            f.grow:SetSmoothing("OUT")
        else
            f.grow:SetScale(0.3, 0.3)
            f.grow:SetSmoothing("IN")
        end
        f.grow:SetDuration(life)
        f.grow:SetStartDelay(wait)
        f.fade:SetChange(-1)
        f.fade:SetDuration(life * 0.45)
        f.fade:SetStartDelay(wait + life * 0.55)
        f.anim:Play()
    end
end
ns.RegisterFX{
    key = "stars", cost = 12, cheaper = "burst",
    play = function(parent, cells)
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.move:SetOffset(0, 0)
            f.move:SetDuration(0.2)
            f.grow:SetScale(0.2, 0.2)
            f.grow:SetDuration(0.2)
            f.grow:SetSmoothing("IN")
            f.fade:SetChange(-1)
            f.fade:SetDuration(0.2)
            f.anim:Play()
            ns.FX.Stars(parent, c.x, c.y, c.size)
        end
    end,
}
