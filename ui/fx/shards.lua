local ADDON, ns = ...
local QUAD = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }
ns.RegisterFX{
    key = "shards", cost = 4, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        local cr = ns.CELL_CROP
        local w, h = cr[2] - cr[1], cr[4] - cr[3]
        for i = 1, #cells do
            local c = cells[i]
            local half = c.size / 2
            for q = 1, 4 do
                local qx, qy = QUAD[q][1], QUAD[q][2]
                local crop = {
                    cr[1] + w * qx / 2, cr[1] + w * (qx + 1) / 2,
                    cr[3] + h * qy / 2, cr[3] + h * (qy + 1) / 2,
                }
                local ox = c.x + (qx == 0 and -half / 2 or half / 2)
                local oy = c.y + (qy == 0 and half / 2 or -half / 2)
                local f = ns.FX.Ghost(parent, ox, oy, half, c.tex, crop)
                local a = math.atan2(oy - c.y, ox - c.x)
                local d = 30 + rng:Int(35)
                f.move:SetOffset(math.cos(a) * d, math.sin(a) * d - 12)
                f.move:SetDuration(0.42)
                f.grow:SetScale(0.7, 0.7)
                f.grow:SetDuration(0.42)
                f.fade:SetChange(-1)
                f.fade:SetDuration(0.42)
                f.anim:Play()
            end
        end
    end,
}
