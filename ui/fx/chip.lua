local ADDON, ns = ...
local PUFF_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local FULL     = { 0, 1, 0, 1 }
local PIECE_T = 0.40
local PUFF_T  = 0.22
local PIECES = {
    { qy = 1, side = -1, kick = 0.9, drop = 1.0, squeeze = 0.35 },
    { qy = 1, side =  1, kick = 1.1, drop = 0.8, squeeze = 0.45 },
    { qy = 0, side = -1, kick = 0.4, drop = 1.3, squeeze = 0.6 },
}
local function tint(f, c)
    if type(c.tint) == "table" then
        f.tex:SetVertexColor(c.tint[1], c.tint[2], c.tint[3])
    end
end
ns.RegisterFX{
    key = "chip", cost = 4, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        local cr = ns.CELL_CROP
        local w, h = cr[2] - cr[1], cr[4] - cr[3]
        for i = 1, #cells do
            local c = cells[i]
            local half = c.size / 2
            local hitX = c.x + (rng:Float() - 0.5) * c.size * 0.6
            local hitY = c.y - half
            local puff = ns.FX.Ghost(parent, hitX, hitY, c.size * 0.7, PUFF_TEX, FULL)
            puff.tex:SetVertexColor(0.95, 0.92, 0.85)
            puff:SetAlpha(0.6)
            puff.move:SetOffset(0, -4)
            puff.move:SetDuration(PUFF_T)
            puff.grow:SetScale(1.8, 1.4)
            puff.grow:SetDuration(PUFF_T)
            puff.grow:SetSmoothing("OUT")
            puff.fade:SetChange(-1)
            puff.fade:SetDuration(PUFF_T)
            puff.anim:Play()
            for p = 1, #PIECES do
                local pc = PIECES[p]
                local qx = (pc.side < 0) and 0 or 1
                local crop = {
                    cr[1] + w * qx / 2, cr[1] + w * (qx + 1) / 2,
                    cr[3] + h * pc.qy / 2, cr[3] + h * (pc.qy + 1) / 2,
                }
                local ox = c.x + pc.side * half / 2
                local oy = c.y + (pc.qy == 0 and half / 2 or -half / 2)
                local f = ns.FX.Ghost(parent, ox, oy, half, c.tex, crop)
                tint(f, c)
                local kick = c.size * pc.kick * (0.7 + rng:Float() * 0.6)
                local drop = c.size * pc.drop * (0.9 + rng:Float() * 0.6)
                f.move:SetOffset(pc.side * kick, -drop)
                f.move:SetDuration(PIECE_T)
                f.move:SetSmoothing("IN")
                f.grow:SetScale(pc.squeeze, 0.85)
                f.grow:SetDuration(PIECE_T)
                f.grow:SetSmoothing("IN")
                f.fade:SetChange(-1)
                f.fade:SetDuration(PIECE_T * 0.4)
                f.fade:SetStartDelay(PIECE_T * 0.6)
                f.anim:Play()
            end
        end
    end,
}
