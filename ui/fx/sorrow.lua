local ADDON, ns = ...
local SKULL_TEX   = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local SKULL_COORD = { 0.75, 1, 0.25, 0.5 }
local SINK = 0.44
ns.RegisterFX{
    key = "sorrow", cost = 2, cheaper = "shrink", fancy = true,
    play = function(parent, cells, rng)
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.tex:SetVertexColor(0.25, 0.20, 0.32)
            f.move:SetOffset((rng:Float() - 0.5) * 10, -22 - rng:Int(14))
            f.move:SetDuration(SINK)
            f.move:SetSmoothing("IN")
            f.grow:SetScale(0.8, 0.8)
            f.grow:SetDuration(SINK)
            ns.AlphaChange(f.fade, -1)
            f.fade:SetDuration(SINK)
            f.anim:Play()
        end
        local cx, cy = 0, 0
        for i = 1, #cells do
            cx = cx + cells[i].x
            cy = cy + cells[i].y
        end
        cx, cy = cx / #cells, cy / #cells
        local s = ns.FX.Ghost(parent, cx, cy, cells[1].size, SKULL_TEX, SKULL_COORD)
        s.tex:SetVertexColor(0.75, 0.70, 0.95)
        s:SetAlpha(0.9)
        s.move:SetOffset(0, 30)
        s.move:SetDuration(0.6)
        s.move:SetSmoothing("OUT")
        s.grow:SetScale(1.6, 1.6)
        s.grow:SetDuration(0.6)
        ns.AlphaChange(s.fade, -1)
        s.fade:SetDuration(0.4)
        s.fade:SetStartDelay(0.2)
        s.anim:Play()
    end,
}
