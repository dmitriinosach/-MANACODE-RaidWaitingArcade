local ADDON, ns = ...
local FEL = { 0.45, 1, 0.25 }
local RISE = 0.40
ns.RegisterFX{
    key = "fel", cost = 1, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.tex:SetVertexColor(FEL[1], FEL[2], FEL[3])
            local wait = rng:Float() * 0.10
            f.move:SetOffset((rng:Float() - 0.5) * 24, 34 + rng:Int(22))
            f.move:SetDuration(RISE)
            f.move:SetStartDelay(wait)
            f.move:SetSmoothing("OUT")
            f.grow:SetScale(0.45, 0.45)
            f.grow:SetDuration(RISE)
            f.grow:SetStartDelay(wait)
            ns.AlphaChange(f.fade, -1)
            f.fade:SetDuration(RISE)
            f.fade:SetStartDelay(wait)
            f.anim:Play()
        end
    end,
}
