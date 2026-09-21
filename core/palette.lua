local ADDON, ns = ...
ns.Palette = {}
local SLOTS = {
    { key = "red",       loc = "colRed",        rgb = { 0.95, 0.25, 0.30 } },
    { key = "blue",      loc = "colBlue",       rgb = { 0.25, 0.60, 1.00 } },
    { key = "yellow",    loc = "colYellow",     rgb = { 1.00, 0.88, 0.25 } },
    { key = "purple",    loc = "colPurple",     rgb = { 0.75, 0.40, 1.00 } },
    { key = "orange",    loc = "colOrange",     rgb = { 1.00, 0.58, 0.20 } },
    { key = "green",     loc = "colGreen",      rgb = { 0.35, 0.90, 0.40 } },
    { key = "meta",      loc = "colMeta",       rgb = { 0.78, 0.72, 0.95 } },
    { key = "prismatic", loc = "colPrismatic",  rgb = { 0.90, 0.95, 1.00 } },
    { key = "dragonseye", loc = "colDragonseye", rgb = { 1.00, 0.80, 0.45 } },
}
local slotOf = {}
for i, s in ipairs(SLOTS) do slotOf[s.key] = i end
function ns.Palette.Colors()
    local out = {}
    for i, s in ipairs(SLOTS) do
        out[i] = { key = s.key, loc = s.loc, slot = i }
    end
    return out
end
function ns.Palette.RGB(color)
    local s = SLOTS[type(color) == "number" and color or (slotOf[color] or 0)]
    if not s then return 1, 1, 1 end
    return s.rgb[1], s.rgb[2], s.rgb[3]
end
