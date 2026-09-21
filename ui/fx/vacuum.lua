local ADDON, ns = ...
local FLY = 0.34
ns.RegisterFX{
    key = "vacuum", cost = 1, cheaper = "shrink", fancy = true,
    play = function(parent, cells)
        local cx, cy = 0, 0
        for i = 1, #cells do
            cx = cx + cells[i].x
            cy = cy + cells[i].y
        end
        cx, cy = cx / #cells, cy / #cells
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.move:SetOffset(cx - c.x, cy - c.y)
            f.move:SetDuration(FLY)
            f.move:SetSmoothing("IN")
            f.grow:SetScale(0.2, 0.2)
            f.grow:SetDuration(FLY)
            f.grow:SetSmoothing("IN")
            f.fade:SetChange(-1)
            f.fade:SetDuration(FLY * 0.4)
            f.fade:SetStartDelay(FLY * 0.6)
            f.anim:Play()
        end
    end,
}
