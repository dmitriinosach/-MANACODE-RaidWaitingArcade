local ADDON, ns = ...
local GRAINS  = 8
local FLY_T   = 0.36
local FALL_T  = 0.44
local WINDOW  = 0.12
ns.RegisterFX{
    key = "crumb", cost = 8, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        local cr = ns.CELL_CROP
        local w, h = cr[2] - cr[1], cr[4] - cr[3]
        for i = 1, #cells do
            local c = cells[i]
            local half = c.size / 2
            for g = 1, GRAINS do
                local side = (g % 2 == 0) and 1 or -1
                local u = rng:Float() * (1 - WINDOW)
                local v = rng:Float() * (1 - WINDOW)
                local crop = {
                    cr[1] + w * u, cr[1] + w * (u + WINDOW),
                    cr[3] + h * v, cr[3] + h * (v + WINDOW),
                }
                local sz = 2 + rng:Int(3)
                local ox = c.x + (rng:Float() - 0.5) * c.size * 0.6
                local oy = c.y + (rng:Float() - 0.5) * c.size * 0.6
                local f = ns.FX.Ghost(parent, ox, oy, sz, c.tex, crop)
                if type(c.tint) == "table" then
                    f.tex:SetVertexColor(c.tint[1], c.tint[2], c.tint[3])
                end
                local push = half * (0.8 + rng:Float() * 1.4)
                local life
                if g <= GRAINS / 2 then
                    life = FLY_T
                    f.move:SetOffset(side * push, half * (0.6 + rng:Float() * 1.2))
                    f.move:SetSmoothing("OUT")
                else
                    life = FALL_T
                    f.move:SetOffset(side * push * 0.7, -half * (1.4 + rng:Float() * 1.6))
                    f.move:SetSmoothing("IN")
                end
                f.move:SetDuration(life)
                f.grow:SetScale(0.4, 0.4)
                f.grow:SetDuration(life)
                f.grow:SetSmoothing("IN")
                ns.AlphaChange(f.fade, -1)
                f.fade:SetDuration(life * 0.45)
                f.fade:SetStartDelay(life * 0.55)
                f.anim:Play()
            end
        end
    end,
}
