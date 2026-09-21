local ADDON, ns = ...
local GLOW_TEX = "Interface\\Buttons\\WHITE8X8"
local FULL     = { 0, 1, 0, 1 }
local GLOW_T  = 0.12
local SPLIT_AT = 0.08
local SPLIT_T  = 0.36
ns.RegisterFX{
    key = "crack", cost = 3, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        local cr = ns.CELL_CROP
        local w, h = cr[2] - cr[1], cr[4] - cr[3]
        local mid = cr[1] + w / 2
        for i = 1, #cells do
            local c = cells[i]
            local half = c.size / 2
            local heavy = rng:Int(2)
            for s = 1, 2 do
                local side = (s == 1) and -1 or 1
                local crop = (s == 1)
                    and { cr[1], mid, cr[3], cr[4] }
                    or  { mid, cr[2], cr[3], cr[4] }
                local f = ns.FX.Ghost(parent, c.x + side * half / 2, c.y, c.size, c.tex, crop)
                f:SetWidth(half)
                f:SetHeight(c.size)
                if type(c.tint) == "table" then
                    f.tex:SetVertexColor(c.tint[1], c.tint[2], c.tint[3])
                end
                local drop = c.size * (0.8 + rng:Float() * 0.6)
                if s == heavy then drop = drop * 1.5 end
                f.move:SetOffset(side * c.size * (0.35 + rng:Float() * 0.3), -drop)
                f.move:SetDuration(SPLIT_T)
                f.move:SetStartDelay(SPLIT_AT)
                f.move:SetSmoothing("IN")
                f.grow:SetScale(0.55, 0.8)
                f.grow:SetDuration(SPLIT_T)
                f.grow:SetStartDelay(SPLIT_AT)
                f.grow:SetSmoothing("IN")
                f.fade:SetChange(-1)
                f.fade:SetDuration(SPLIT_T * 0.4)
                f.fade:SetStartDelay(SPLIT_AT + SPLIT_T * 0.6)
                f.anim:Play()
            end
            local glow = ns.FX.Ghost(parent, c.x, c.y, c.size, GLOW_TEX, FULL)
            glow.tex:SetBlendMode("ADD")
            glow.tex:SetVertexColor(1, 0.96, 0.85)
            glow:SetAlpha(0.75)
            glow.move:SetOffset(0, 0)
            glow.move:SetDuration(GLOW_T)
            glow.grow:SetScale(1.15, 1.15)
            glow.grow:SetDuration(GLOW_T)
            glow.grow:SetSmoothing("OUT")
            glow.fade:SetChange(-1)
            glow.fade:SetDuration(GLOW_T)
            glow.anim:Play()
        end
    end,
}
