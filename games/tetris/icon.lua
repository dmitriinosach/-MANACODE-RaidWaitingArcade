local ADDON, ns = ...
local floor, max = math.floor, math.max
local PLATE = { 0.063, 0.110, 0.141 }
local FACE  = { 0.373, 0.690, 0.878 }
local RIM   = { 0.561, 0.816, 0.941 }
local CELLS = {
    { 0, 0 }, { 0, 1 }, { 1, 1 }, { 1, 2 },
}
local function put(t, host, x, y, w, h, c)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    t:SetWidth(max(1, w)); t:SetHeight(max(1, h))
    ns.Paint(t, c[1], c[2], c[3], 1)
end
function ns.TetrisTileIcon(host, size)
    local cell = max(3, floor(size / 4))
    local gap  = max(1, floor(cell * 0.12 + 0.5))
    local kant = max(1, floor(cell * 0.18 + 0.5))
    local ox = floor((size - cell * 2) / 2)
    local oy = floor((size - cell * 3) / 2)
    put(ns.ArtFill(host, 1, "BACKGROUND"), host, 0, 0, size, size, PLATE)
    for i, c in ipairs(CELLS) do
        local x = ox + c[1] * cell
        local y = oy + c[2] * cell
        local w = cell - gap
        put(ns.ArtFill(host, 1 + i, "BORDER"), host, x, y, w, w, RIM)
        put(ns.ArtFill(host, 5 + i, "ARTWORK"), host,
            x + kant, y + kant, w - kant, w - kant, FACE)
    end
end
