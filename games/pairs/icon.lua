local ADDON, ns = ...
local floor, max = math.floor, math.max
local PLATE = { 0.118, 0.141, 0.212 }
local BACK  = { 0.561, 0.651, 0.788 }
local BEDGE = { 0.322, 0.396, 0.510 }
local FACE  = { 0.839, 0.804, 0.714 }
local FEDGE = { 0.541, 0.498, 0.388 }
local EMBL  = { 0.541, 0.431, 0.180 }
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local function put(t, host, x, y, w, h, c)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    t:SetWidth(max(1, w)); t:SetHeight(max(1, h))
    t:SetTexture(c[1], c[2], c[3], 1)
end
local function card(host, i, x, y, w, h, edge, fill, layer)
    local k = max(1, floor(w * 0.09 + 0.5))
    put(ns.ArtFill(host, i, layer), host, x, y, w, h, edge)
    put(ns.ArtFill(host, i + 1, layer), host, x + k, y + k, w - k * 2, h - k * 2, fill)
end
function ns.PairsTileIcon(host, size)
    local cw = max(4, floor(size * 0.39 + 0.5))
    local ch = max(6, floor(size * 0.53 + 0.5))
    put(ns.ArtFill(host, 1, "BACKGROUND"), host, 0, 0, size, size, PLATE)
    card(host, 2, floor(size * 0.14), size - floor(size * 0.19) - ch,
         cw, ch, BEDGE, BACK, "BORDER")
    card(host, 4, size - floor(size * 0.14) - cw, floor(size * 0.19),
         cw, ch, FEDGE, FACE, "ARTWORK")
    local fx = size - floor(size * 0.14) - cw
    local fy = floor(size * 0.19)
    local d  = max(3, floor(cw * 0.52 + 0.5))
    local t  = ns.ArtFill(host, 6, "OVERLAY")
    t:SetPoint("TOPLEFT", host, "TOPLEFT",
        fx + floor((cw - d) / 2), -(fy + floor((ch - d) / 2)))
    t:SetWidth(d); t:SetHeight(d)
    t:SetTexture(DISC)
    t:SetVertexColor(EMBL[1], EMBL[2], EMBL[3], 1)
end
