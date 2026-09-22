local ADDON, ns = ...
local floor, max = math.floor, math.max
local PLATE = { 0.106, 0.122, 0.149 }
local FIELD = { 0.141, 0.161, 0.208 }
local KANT  = { 0.788, 0.761, 0.690 }
local RULE  = { 0.431, 0.478, 0.565 }
local INK   = { 0.894, 0.914, 0.949 }
local DIGITS = {
    { col = 0, row = 0, text = "5" },
    { col = 2, row = 1, text = "9" },
    { col = 1, row = 2, text = "2" },
}
local NUM_FONT = "Fonts\\ARIALN.TTF"
local function put(t, host, x, y, w, h, c)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    t:SetWidth(max(1, w)); t:SetHeight(max(1, h))
    ns.Paint(t, c[1], c[2], c[3], 1)
end
function ns.SudokuTileIcon(host, size)
    local pad  = max(1, floor(size * 0.07 + 0.5))
    local kant = max(1, floor(size * 0.05 + 0.5))
    local rule = max(1, floor(size * 0.03 + 0.5))
    local cell  = max(2, floor((size - pad * 2 - kant * 2) / 3))
    local inner = cell * 3
    local field = inner + kant * 2
    local off   = floor((size - field) / 2)
    local ix    = off + kant
    put(ns.ArtFill(host, 1, "BACKGROUND"), host, 0, 0, size, size, PLATE)
    put(ns.ArtFill(host, 2, "BORDER"), host, off, off, field, field, FIELD)
    put(ns.ArtFill(host, 3), host, off, off, field, kant, KANT)
    put(ns.ArtFill(host, 4), host, off, off + field - kant, field, kant, KANT)
    put(ns.ArtFill(host, 5), host, off, off, kant, field, KANT)
    put(ns.ArtFill(host, 6), host, off + field - kant, off, kant, field, KANT)
    for k = 1, 2 do
        put(ns.ArtFill(host, 6 + k), host, ix + k * cell, ix, rule, inner, RULE)
        put(ns.ArtFill(host, 8 + k), host, ix, ix + k * cell, inner, rule, RULE)
    end
    local px = max(6, floor(cell * 1.05 + 0.5))
    for i, d in ipairs(DIGITS) do
        local fs = ns.ArtText(host, i)
        if not ns.SetFont(fs, NUM_FONT, px, "") then
            ns.SetFont(fs, (fs:GetFont()), px, "")
        end
        fs:SetWidth(cell); fs:SetHeight(cell)
        fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
        fs:SetPoint("TOPLEFT", host, "TOPLEFT", ix + d.col * cell, -(ix + d.row * cell))
        fs:SetTextColor(INK[1], INK[2], INK[3])
        fs:SetText(d.text)
    end
end
