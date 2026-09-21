local ADDON, ns = ...
local floor, max, min = math.floor, math.max, math.min
local PLATE = { 0.133, 0.102, 0.063 }
local EDGE  = { 0.431, 0.306, 0.125 }
local HANG  = { 0.753, 0.541, 0.271 }
local DOWN  = { 0.659, 0.463, 0.235 }
local CABLE = { 0.541, 0.576, 0.659 }
local function put(t, host, x, y, w, h, c)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    t:SetWidth(max(1, w)); t:SetHeight(max(1, h))
    t:SetTexture(c[1], c[2], c[3], 1)
end
local function crate(host, i, x, y, w, h, fill)
    local k = max(1, floor(w * 0.11 + 0.5))
    put(ns.ArtFill(host, i, "BORDER"), host, x, y, w, h, EDGE)
    put(ns.ArtFill(host, i + 1, "ARTWORK"), host, x + k, y + k, w - k * 2, h - k * 2, fill)
    put(ns.ArtFill(host, i + 2, "OVERLAY"), host,
        x + k, y + k, w - k * 2, max(1, floor(h * 0.22 + 0.5)),
        { min(fill[1] * 1.3, 1), min(fill[2] * 1.3, 1), min(fill[3] * 1.3, 1) })
end
function ns.StackTileIcon(host, size)
    put(ns.ArtFill(host, 1, "BACKGROUND"), host, 0, 0, size, size, PLATE)
    local hw = max(6, floor(size * 0.50 + 0.5))
    local hh = max(4, floor(size * 0.31 + 0.5))
    local hx = floor((size - hw) / 2)
    local hy = max(2, floor(size * 0.19 + 0.5))
    local cw = max(1, floor(size * 0.06 + 0.5))
    put(ns.ArtFill(host, 2, "BORDER"), host, floor((size - cw) / 2), 0, cw, hy, CABLE)
    crate(host, 3, hx, hy, hw, hh, HANG)
    local bw = max(4, floor(size * 0.30 + 0.5))
    local bh = max(4, floor(size * 0.25 + 0.5))
    local by = size - bh - max(1, floor(size * 0.07 + 0.5))
    local bx = max(1, floor(size * 0.09 + 0.5))
    crate(host, 6, bx, by, bw, bh, DOWN)
    crate(host, 9, size - bx - bw, by, bw, bh, DOWN)
end
