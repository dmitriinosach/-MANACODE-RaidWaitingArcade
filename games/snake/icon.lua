local ADDON, ns = ...
local floor, max = math.floor, math.max
local PLATE = { 0.078, 0.125, 0.055 }
local TAIL  = { 0.435, 0.722, 0.333 }
local BODY  = { 0.541, 0.831, 0.435 }
local HEAD  = { 0.769, 0.941, 0.690 }
local APPLE = { 0.878, 0.322, 0.373 }
local function put(t, host, x, y, w, h, c)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    t:SetWidth(max(1, w)); t:SetHeight(max(1, h))
    t:SetTexture(c[1], c[2], c[3], 1)
end
function ns.SnakeTileIcon(host, size)
    local seg = max(4, floor(size * 7 / 36 + 0.5))
    local x1  = floor(size * 6 / 36 + 0.5)
    local y1  = floor(size * 6 / 36 + 0.5)
    local x2  = x1 + seg
    local y2  = y1 + seg
    local y3  = y1 + seg * 2
    put(ns.ArtFill(host, 1, "BACKGROUND"), host, 0, 0, size, size, PLATE)
    put(ns.ArtFill(host, 2, "BORDER"), host, x1, y3, seg, seg, TAIL)
    put(ns.ArtFill(host, 3, "BORDER"), host, x2, y3, seg, seg, BODY)
    put(ns.ArtFill(host, 4, "BORDER"), host, x2, y2, seg, seg, BODY)
    put(ns.ArtFill(host, 5, "BORDER"), host, x2, y1, seg, seg, HEAD)
    local r  = max(2, floor(size * 0.10 + 0.5))
    local cx = floor(size * 0.75 + 0.5)
    local cy = floor(size * 24 / 36 + 0.5)
    local d  = r * 2
    local s  = max(2, floor(d * 0.7 + 0.5))
    put(ns.ArtFill(host, 6, "ARTWORK"), host, cx - r, cy - floor(s / 2), d, s, APPLE)
    put(ns.ArtFill(host, 7, "ARTWORK"), host, cx - floor(s / 2), cy - r, s, d, APPLE)
end
