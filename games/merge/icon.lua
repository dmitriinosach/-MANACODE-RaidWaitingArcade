local ADDON, ns = ...
local floor, max = math.floor, math.max
local PLATE = { 0.075, 0.070, 0.062 }
local GLASS = { 0.180, 0.165, 0.150 }
local CORK  = { 0.541, 0.404, 0.208 }
local LIQ   = { 0.660, 0.161, 0.122 }
local LIQ_T = { 0.878, 0.361, 0.290 }
local SHINE = { 1, 0.97, 0.90, 0.13 }
local INK   = { 1, 0.82, 0 }
local NUM_FONT = "Fonts\\ARIALN.TTF"
local function put(t, host, x, y, w, h, c)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    t:SetWidth(max(1, w)); t:SetHeight(max(1, h))
    t:SetTexture(c[1], c[2], c[3], c[4] or 1)
end
local function band(host, i, size, y, w, h, c, layer)
    put(ns.ArtFill(host, i, layer), host, floor((size - w) / 2), y, w, h, c)
end
function ns.MergeTileIcon(host, size)
    local corkW = max(3, floor(size * 0.24 + 0.5))
    local neckW = max(2, floor(size * 0.16 + 0.5))
    local shldW = max(4, floor(size * 0.46 + 0.5))
    local bodyW = max(6, floor(size * 0.68 + 0.5))
    local corkY = floor(size * 0.08 + 0.5)
    local neckY = floor(size * 0.18 + 0.5)
    local shldY = floor(size * 0.30 + 0.5)
    local bodyY = floor(size * 0.38 + 0.5)
    local bodyH = floor(size * 0.50 + 0.5)
    local px    = max(7, floor(size * 0.34 + 0.5))
    put(ns.ArtFill(host, 1, "BACKGROUND"), host, 0, 0, size, size, PLATE)
    band(host, 2, size, corkY, corkW, neckY - corkY, CORK, "BORDER")
    band(host, 3, size, neckY, neckW, shldY - neckY, GLASS, "BORDER")
    band(host, 4, size, shldY, shldW, bodyY - shldY, GLASS, "BORDER")
    band(host, 5, size, bodyY, bodyW, bodyH, GLASS, "BORDER")
    local inset = max(1, floor(size * 0.04 + 0.5))
    local liqH  = floor(bodyH * 0.66 + 0.5)
    local liqY  = bodyY + bodyH - inset - liqH
    band(host, 6, size, liqY, bodyW - inset * 2, liqH, LIQ)
    band(host, 7, size, liqY, bodyW - inset * 2, max(1, floor(liqH * 0.14 + 0.5)), LIQ_T)
    put(ns.ArtFill(host, 8), host,
        floor((size - bodyW) / 2) + inset + max(1, floor(bodyW * 0.10 + 0.5)),
        shldY, max(1, floor(bodyW * 0.09 + 0.5)), bodyY + bodyH - shldY - inset, SHINE)
    local fs = ns.ArtText(host, 1)
    if not fs:SetFont(NUM_FONT, px, "OUTLINE") then
        fs:SetFont((fs:GetFont()), px, "OUTLINE")
    end
    fs:SetWidth(size); fs:SetHeight(bodyH)
    fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
    fs:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -bodyY)
    fs:SetTextColor(INK[1], INK[2], INK[3])
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    fs:SetText("2048")
end
