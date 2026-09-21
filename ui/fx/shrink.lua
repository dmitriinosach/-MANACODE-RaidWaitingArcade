local ADDON, ns = ...
ns.RegisterFX{
    key = "shrink", cost = 1,
    play = function(parent, cells)
        for i = 1, #cells do
            local c = cells[i]
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.move:SetOffset(0, 0)
            f.move:SetDuration(0)
            f.grow:SetScale(0.1, 0.1)
            f.grow:SetDuration(0.18)
            f.fade:SetChange(-1)
            f.fade:SetDuration(0.18)
            f.anim:Play()
        end
    end,
}
