local ADDON, ns = ...
ns.FLIP_TIME = 0.25
local function paint(c)
    local f = c.flip
    local side = f.shown
    local tex = (side == "face") and f.face or f.back
    c.icon:SetTexture(tex)
    if side == "back" and f.backColor then
        c.icon:SetVertexColor(f.backColor[1], f.backColor[2], f.backColor[3])
    else
        c.icon:SetVertexColor(1, 1, 1)
    end
    ns.PlaceTex(c.icon, c, f.art * f.k, f.art)
    if c.slot:IsShown() then
        local s = f.art * ns.SLOT_SCALE
        ns.PlaceTex(c.slot, c, s * f.k, s)
    end
    ns.CellCenter(c, (f.k >= 1 and side == "face") and f.text or nil)
end
function ns.MakeFlip(parent, style)
    local c = ns.MakeCell(parent)
    ns.StyleCell(c, style or "framed")
    c.flip = {
        back = nil, face = nil, text = nil, backColor = nil,
        dur = ns.FLIP_TIME,
        art = ns.ICON_SIZE,
        shown = "back",
        to = nil,
        t0 = nil,
        k = 1,
    }
    return c
end
function ns.FlipSize(c, cell, border)
    local art = ns.SizeCell(c, cell, border)
    c.flip.art = art
    paint(c)
end
function ns.FlipFaces(c, back, face, opts)
    local f = c.flip
    f.back, f.face = back, face
    f.text = opts and opts.text or nil
    f.backColor = opts and opts.backColor or nil
    f.dur = (opts and opts.dur) or ns.FLIP_TIME
    local crop = opts and opts.coord
    if crop then c.icon:SetTexCoord(crop[1], crop[2], crop[3], crop[4]) end
    paint(c)
end
function ns.FlipSet(c, side)
    local f = c.flip
    f.shown, f.to, f.t0, f.k = side, nil, nil, 1
    paint(c)
end
function ns.FlipTo(c, side, t)
    local f = c.flip
    if f.to then
        if f.to == side then return end
        local p = (t - f.t0) / f.dur
        if p < 0.5 then
            f.to = side
            return
        end
        f.to = side
        f.t0 = t - f.dur * (1 - f.k) / 2
        return
    end
    if f.shown == side then return end
    f.to, f.t0 = side, t
end
function ns.FlipStep(c, t)
    local f = c.flip
    if not f.to then return false end
    local p = (t - f.t0) / f.dur
    if p < 0 then p = 0 end
    if p >= 1 then
        f.shown, f.to, f.t0, f.k = f.to, nil, nil, 1
        paint(c)
        return false
    end
    if p < 0.5 then
        f.k = 1 - p * 2
    else
        f.shown = f.to
        f.k = p * 2 - 1
    end
    paint(c)
    return true
end
function ns.FlipBusy(c)
    return c.flip.to ~= nil
end
function ns.FlipSide(c)
    return c.flip.to or c.flip.shown
end
function ns.FlipArt(c)
    return c.flip.art
end
function ns.FlipReset(c)
    ns.ResetCell(c)
    local f = c.flip
    f.text, f.backColor = nil, nil
    f.shown, f.to, f.t0, f.k = "back", nil, nil, 1
    c:SetAlpha(1)
end
