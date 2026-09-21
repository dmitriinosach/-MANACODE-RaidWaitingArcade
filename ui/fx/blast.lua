local ADDON, ns = ...
local FLASH_TEX = "Interface\\Buttons\\ButtonHilight-Square"
local BOOM = 0.36
ns.RegisterFX{
    key = "blast", cost = 2, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        local cx, cy = 0, 0
        for i = 1, #cells do
            cx = cx + cells[i].x
            cy = cy + cells[i].y
        end
        cx, cy = cx / #cells, cy / #cells
        local size = cells[1].size
        local flash = ns.FX.Ghost(parent, cx, cy, size, FLASH_TEX, { 0, 1, 0, 1 })
        flash.tex:SetBlendMode("ADD")
        flash.tex:SetVertexColor(1, 0.85, 0.45)
        flash.move:SetOffset(0, 0)
        flash.move:SetDuration(BOOM)
        flash.grow:SetScale(2.4, 2.4)
        flash.grow:SetDuration(BOOM)
        flash.grow:SetSmoothing("OUT")
        flash.fade:SetChange(-1)
        flash.fade:SetDuration(BOOM)
        flash.anim:Play()
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            local dx, dy = c.x - cx, c.y - cy
            local dist = math.sqrt(dx * dx + dy * dy)
            local a = (dist > 0) and math.atan2(dy, dx) or (rng:Float() * math.pi * 2)
            local push = 45 + dist * 0.7 + rng:Int(20)
            f.move:SetOffset(math.cos(a) * push, math.sin(a) * push)
            f.move:SetDuration(BOOM)
            f.move:SetSmoothing("OUT")
            f.grow:SetScale(0.5, 0.5)
            f.grow:SetDuration(BOOM)
            f.fade:SetChange(-1)
            f.fade:SetDuration(BOOM)
            f.anim:Play()
        end
    end,
}
