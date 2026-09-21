local ADDON, ns = ...
ns.RegisterFX{
    key = "burst", cost = 1, cheaper = "shrink",
    play = function(parent, cells, rng)
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            local a = rng:Float() * math.pi * 2
            local d = 40 + rng:Int(30)
            f.move:SetOffset(math.cos(a) * d, math.sin(a) * d)
            f.move:SetDuration(0.32)
            f.grow:SetScale(1.35, 1.35)
            f.grow:SetDuration(0.32)
            f.fade:SetChange(-1)
            f.fade:SetDuration(0.32)
            f.anim:Play()
        end
    end,
}
