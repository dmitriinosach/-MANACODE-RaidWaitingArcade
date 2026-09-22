local ADDON, ns = ...
local SWEEP = 0.30
local HOLD  = 0.12
ns.RegisterFX{
    key = "beam", cost = 2, cheaper = "ripple", fancy = true,
    play = function(parent, cells, rng, opts)
        local vert = opts and opts.dir == "v"
        local minX, maxX = cells[1].x, cells[1].x
        local minY, maxY = cells[1].y, cells[1].y
        for i = 2, #cells do
            local c = cells[i]
            if c.x < minX then minX = c.x end
            if c.x > maxX then maxX = c.x end
            if c.y < minY then minY = c.y end
            if c.y > maxY then maxY = c.y end
        end
        local size = cells[1].size
        local thick = math.max(4, size / 3)
        local from, span, barW, barH, dx, dy
        if vert then
            from = minY - size
            span = (maxY + size) - from
            barW = maxX - minX + size * 1.6
            barH = thick
            dx, dy = 0, span
        else
            from = minX - size
            span = (maxX + size) - from
            barW = thick
            barH = maxY - minY + size * 1.6
            dx, dy = span, 0
        end
        local bx = vert and (minX + maxX) / 2 or from
        local by = vert and from or (minY + maxY) / 2
        local bar = ns.FX.Ghost(parent, bx, by, size, nil)
        bar:SetWidth(barW)
        bar:SetHeight(barH)
        bar.tex:SetTexCoord(0, 1, 0, 1)
        ns.Paint(bar.tex, 1, 0.95, 0.6)
        bar.tex:SetBlendMode("ADD")
        bar.tex:SetAlpha(0.85)
        bar.move:SetOffset(dx, dy)
        bar.move:SetDuration(SWEEP)
        bar.move:SetStartDelay(0)
        bar.grow:SetScale(1, 1)
        bar.grow:SetDuration(SWEEP)
        bar.grow:SetStartDelay(0)
        ns.AlphaChange(bar.fade, -1)
        bar.fade:SetDuration(HOLD)
        bar.fade:SetStartDelay(SWEEP)
        bar.anim:Play()
        for i = 1, #cells do
            local c = cells[i]
            local along = vert and (c.y - from) or (c.x - from)
            local wait = SWEEP * (along / span)
            local f = ns.FX.Ghost(parent, c.x, c.y, c.size, c.tex)
            f.move:SetOffset((rng:Float() - 0.5) * 18, -20 - rng:Int(20))
            f.move:SetDuration(0.26)
            f.move:SetStartDelay(wait)
            f.grow:SetScale(0.55, 0.55)
            f.grow:SetDuration(0.26)
            f.grow:SetStartDelay(wait)
            ns.AlphaChange(f.fade, -1)
            f.fade:SetDuration(0.26)
            f.fade:SetStartDelay(wait)
            f.anim:Play()
        end
    end,
}
