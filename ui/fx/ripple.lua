local ADDON, ns = ...
local SPEED = 260
local MAX_WAIT = 0.45
ns.RegisterFX{
    key = "ripple", cost = 1, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        local cx, cy = 0, 0
        for i = 1, #cells do
            cx = cx + cells[i].x
            cy = cy + cells[i].y
        end
        cx, cy = cx / #cells, cy / #cells
        for i = 1, #cells do
            local c = cells[i]
            local dx, dy = c.x - cx, c.y - cy
            local dist = math.sqrt(dx * dx + dy * dy)
            local wait = math.min(dist / SPEED, MAX_WAIT)
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            local a = (dist > 0) and math.atan2(dy, dx) or (rng:Float() * math.pi * 2)
            f.move:SetOffset(math.cos(a) * 26, math.sin(a) * 26)
            f.move:SetDuration(0.22)
            f.move:SetStartDelay(wait)
            f.grow:SetScale(0.15, 0.15)
            f.grow:SetDuration(0.22)
            f.grow:SetStartDelay(wait)
            f.grow:SetSmoothing("IN")
            ns.AlphaChange(f.fade, -1)
            f.fade:SetDuration(0.22)
            f.fade:SetStartDelay(wait)
            f.anim:Play()
        end
    end,
}
