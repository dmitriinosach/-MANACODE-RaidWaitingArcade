local ADDON, ns = ...
local FLASH_TEX = "Interface\\Cooldown\\star4"
local WAVE_TEX  = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local SPARK_TEX = "Interface\\Buttons\\WHITE8X8"
local FULL      = { 0, 1, 0, 1 }
local QUAD      = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }
local CORE = { 1.00, 0.97, 0.90 }
local HALO = { 0.45, 0.70, 1.00 }
local SPARKS  = 8
local FLASH_T = 0.26
local WAVE_T  = 0.40
local SHARD_T = 0.55
local SPARK_T = 0.45
local rng
function ns.FX.Nova(parent, x, y, size, tex, scale)
    if not parent then return end
    local level = ns.FX.Level()
    if level == "off" then return end
    scale = scale or 1
    if level == "plain" then scale = scale * 0.5 end
    rng = rng or ns.RNG.New(time())
    local wave = ns.FX.Ghost(parent, x, y, size, WAVE_TEX, FULL)
    wave.tex:SetBlendMode("ADD")
    wave.tex:SetVertexColor(HALO[1], HALO[2], HALO[3])
    wave:SetAlpha(0.8)
    wave.move:SetOffset(0, 0)
    wave.move:SetDuration(WAVE_T)
    wave.grow:SetScale(3.2, 3.2)
    wave.grow:SetDuration(WAVE_T)
    wave.grow:SetSmoothing("OUT")
    ns.AlphaChange(wave.fade, -1)
    wave.fade:SetDuration(WAVE_T)
    wave.anim:Play()
    local flash = ns.FX.Ghost(parent, x, y, size * 1.1, FLASH_TEX, FULL)
    flash.tex:SetBlendMode("ADD")
    flash.tex:SetVertexColor(CORE[1], CORE[2], CORE[3])
    flash.move:SetOffset(0, 0)
    flash.move:SetDuration(FLASH_T)
    flash.grow:SetScale(2.4, 2.4)
    flash.grow:SetDuration(FLASH_T)
    flash.grow:SetSmoothing("OUT")
    ns.AlphaChange(flash.fade, -1)
    flash.fade:SetDuration(FLASH_T)
    flash.anim:Play()
    if tex and scale >= 0.75 then
        local cr = ns.CELL_CROP
        local w, h = cr[2] - cr[1], cr[4] - cr[3]
        local half = size / 2
        for q = 1, 4 do
            local qx, qy = QUAD[q][1], QUAD[q][2]
            local crop = {
                cr[1] + w * qx / 2, cr[1] + w * (qx + 1) / 2,
                cr[3] + h * qy / 2, cr[3] + h * (qy + 1) / 2,
            }
            local ox = x + (qx == 0 and -half / 2 or half / 2)
            local oy = y + (qy == 0 and half / 2 or -half / 2)
            local f = ns.FX.Ghost(parent, ox, oy, half, tex, crop)
            f.tex:SetVertexColor(0.8, 0.85, 1)
            local a = math.atan2(oy - y, ox - x) + (rng:Float() - 0.5) * 0.5
            local d = size * (0.9 + rng:Float() * 0.8)
            f.move:SetOffset(math.cos(a) * d, math.sin(a) * d)
            f.move:SetDuration(SHARD_T)
            f.move:SetSmoothing("OUT")
            f.grow:SetScale(0.35, 0.35)
            f.grow:SetDuration(SHARD_T)
            ns.AlphaChange(f.fade, -1)
            f.fade:SetDuration(SHARD_T * 0.5)
            f.fade:SetStartDelay(SHARD_T * 0.5)
            f.anim:Play()
        end
    end
    local sparks = math.max(3, math.floor(SPARKS * scale + 0.5))
    for i = 1, sparks do
        local a = (i - 1) / sparks * math.pi * 2 + rng:Float() * 0.7
        local d = size * (1.2 + rng:Float() * 1.3)
        local sz = 2 + rng:Int(2)
        local c = (i % 2 == 0) and CORE or HALO
        local f = ns.FX.Ghost(parent, x, y, sz, SPARK_TEX, FULL)
        f.tex:SetBlendMode("ADD")
        f.tex:SetVertexColor(c[1], c[2], c[3])
        f.move:SetOffset(math.cos(a) * d, math.sin(a) * d)
        f.move:SetDuration(SPARK_T)
        f.move:SetSmoothing("OUT")
        f.grow:SetScale(0.4, 0.4)
        f.grow:SetDuration(SPARK_T)
        ns.AlphaChange(f.fade, -1)
        f.fade:SetDuration(SPARK_T * 0.6)
        f.fade:SetStartDelay(SPARK_T * 0.4)
        f.anim:Play()
    end
end
ns.RegisterFX{
    key = "nova", cost = 14, cheaper = "blast", fancy = true,
    play = function(parent, cells)
        for i = 1, #cells do
            local c = cells[i]
            ns.FX.Nova(parent, c.x, c.y, c.size, c.tex)
        end
    end,
}
