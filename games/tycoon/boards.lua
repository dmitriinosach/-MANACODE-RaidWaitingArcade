local ADDON, ns = ...
local B = {}
ns.TycoonBoards = B
B.ORDER = { "azeroth", "icc", "dalaran" }
B.INDEX = { azeroth = 0, icc = 1, dalaran = 2 }
B.PREFIX = { azeroth = "az", icc = "icc", dalaran = "dal" }
local function street(g, price, rent, house, mort)
    return { t = "prop", g = g, price = price, rent = rent, house = house, mort = mort }
end
B.cells = {
    [0]  = { t = "go" },
    [1]  = street(1, 60, { 2, 10, 30, 90, 160, 250 }, 50, 30),
    [2]  = { t = "chest" },
    [3]  = street(1, 60, { 4, 20, 60, 180, 320, 450 }, 50, 30),
    [4]  = { t = "tax", tax = 200 },
    [5]  = { t = "rail", g = 9, price = 200, mort = 100 },
    [6]  = street(2, 100, { 6, 30, 90, 270, 400, 550 }, 50, 50),
    [7]  = { t = "chance" },
    [8]  = street(2, 100, { 6, 30, 90, 270, 400, 550 }, 50, 50),
    [9]  = street(2, 120, { 8, 40, 100, 300, 450, 600 }, 50, 60),
    [10] = { t = "jail" },
    [11] = street(3, 140, { 10, 50, 150, 450, 625, 750 }, 100, 70),
    [12] = { t = "util", g = 10, price = 150, mort = 75 },
    [13] = street(3, 140, { 10, 50, 150, 450, 625, 750 }, 100, 70),
    [14] = street(3, 160, { 12, 60, 180, 500, 700, 900 }, 100, 80),
    [15] = { t = "rail", g = 9, price = 200, mort = 100 },
    [16] = street(4, 180, { 14, 70, 200, 550, 750, 950 }, 100, 90),
    [17] = { t = "chest" },
    [18] = street(4, 180, { 14, 70, 200, 550, 750, 950 }, 100, 90),
    [19] = street(4, 200, { 16, 80, 220, 600, 800, 1000 }, 100, 100),
    [20] = { t = "free" },
    [21] = street(5, 220, { 18, 90, 250, 700, 875, 1050 }, 150, 110),
    [22] = { t = "chance" },
    [23] = street(5, 220, { 18, 90, 250, 700, 875, 1050 }, 150, 110),
    [24] = street(5, 240, { 20, 100, 300, 750, 925, 1100 }, 150, 120),
    [25] = { t = "rail", g = 9, price = 200, mort = 100 },
    [26] = street(6, 260, { 22, 110, 330, 800, 975, 1150 }, 150, 130),
    [27] = street(6, 260, { 22, 110, 330, 800, 975, 1150 }, 150, 130),
    [28] = { t = "util", g = 10, price = 150, mort = 75 },
    [29] = street(6, 280, { 24, 120, 360, 850, 1025, 1200 }, 150, 140),
    [30] = { t = "gojail" },
    [31] = street(7, 300, { 26, 130, 390, 900, 1100, 1275 }, 200, 150),
    [32] = street(7, 300, { 26, 130, 390, 900, 1100, 1275 }, 200, 150),
    [33] = { t = "chest" },
    [34] = street(7, 320, { 28, 150, 450, 1000, 1200, 1400 }, 200, 160),
    [35] = { t = "rail", g = 9, price = 200, mort = 100 },
    [36] = { t = "chance" },
    [37] = street(8, 350, { 35, 175, 500, 1100, 1300, 1500 }, 200, 175),
    [38] = { t = "tax", tax = 100 },
    [39] = street(8, 400, { 50, 200, 600, 1400, 1700, 2000 }, 200, 200),
}
B.props, B.pidx, B.groups = {}, {}, {}
for c = 0, 39 do
    local cell = B.cells[c]
    if cell.price then
        B.props[#B.props + 1] = c
        B.pidx[c] = #B.props
        B.groups[cell.g] = B.groups[cell.g] or {}
        local g = B.groups[cell.g]
        g[#g + 1] = c
    end
end
B.RAILS = { 5, 15, 25, 35 }
B.UTILS = { 12, 28 }
B.HOUSES, B.HOTELS = 32, 12
B.GROUP_COLOR = {
    { 0.55, 0.35, 0.17 }, { 0.35, 0.55, 0.90 }, { 0.83, 0.42, 0.60 }, { 0.88, 0.54, 0.16 },
    { 0.75, 0.22, 0.17 }, { 0.55, 0.78, 0.25 }, { 0.20, 0.60, 0.35 }, { 0.30, 0.32, 0.78 },
    { 0.36, 0.39, 0.44 }, { 0.72, 0.70, 0.62 },
}
B.SEAT_COLOR = {
    { 0.17, 0.36, 0.84 }, { 0.85, 0.66, 0.16 }, { 0.18, 0.62, 0.36 }, { 0.79, 0.19, 0.24 },
}
B.TOKENS = { "murloc", "kobold", "goblin", "gnome", "wolvar", "penguin", "skeleton", "tauren" }
B.music = {
    azeroth = { "CityMusic/Stormwind", "CityMusic/Orgrimmar" },
    icc = { "ZoneMusic/IcecrownRaid" },
    dalaran = { "Zone-DalaranCity" },
}
local function hex(h)
    return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255 }
end
local function palette(t)
    local out = {}
    for k, v in pairs(t) do out[k] = hex(v) end
    return out
end
B.palette = {
    azeroth = palette({ bg = "17110a", bg2 = "241a10", panel = "2a1c11", panel2 = "3c2a18", frame = "6e4f24", frame2 = "cfa75d",
        text = "efe1c2", muted = "a8946f", accent = "dcb866", field = "1d140c", field2 = "2d1f13", cell = "e9d9b4",
        cell2 = "cdb588", cellline = "6b4a2a", log = "120c07", title = "f3d98a", rail = "5a6470", util = "d9d2c3", tax = "9a9a9a", go = "d9c27a" }),
    icc = palette({ bg = "05080e", bg2 = "0b131d", panel = "0d1724", panel2 = "182a3e", frame = "2a4a68", frame2 = "8fc3e6",
        text = "d8e8f5", muted = "7f98ad", accent = "8fe0ff", field = "060b12", field2 = "0e1a27", cell = "c4dbe9",
        cell2 = "8fb0c6", cellline = "2a4a6a", log = "04070c", title = "d8ecff", rail = "2c4a70", util = "cfdde6", tax = "9a9a9a", go = "bfe6ff" }),
    dalaran = palette({ bg = "10081a", bg2 = "1c0f2c", panel = "231236", panel2 = "36204f", frame = "5a3a8a", frame2 = "e3bd5a",
        text = "efe4fa", muted = "a893c2", accent = "e3bd5a", field = "140a20", field2 = "221331", cell = "dccbee",
        cell2 = "b49bd4", cellline = "4a2a7a", log = "0d0614", title = "f2dc9a", rail = "3a2f6a", util = "d6cde6", tax = "9a9a9a", go = "f2dc9a" }),
}
B.look = {}
for key, p in pairs(B.palette) do B.look[key] = { wood = p.bg2, edge = p.frame2 } end
local function common(spec)
    local out = {}
    for c = 0, 39 do
        local t = B.cells[c].t
        local k
        if t == "chance" then k = "chance"
        elseif t == "chest" then k = "chest"
        else k = "c" .. c end
        out[c] = k
    end
    return out
end
B.nameKey = common()
local function icons(list)
    local out = {}
    for c = 0, 39 do out[c] = list[c] end
    return out
end
B.icon = {
    azeroth = icons({
        [0] = 0, "Achievement_Zone_ElwynnForest", 4, "Achievement_Zone_Durotar", 5, 7, "INV_Drink_05", 3, "INV_Misc_Lantern_01", "INV_Drink_04",
        1, 2129, "Ability_Mount_Gryphon_01", "Achievement_Zone_Barrens_01", 765, 8, "INV_Misc_Bag_14", 4, "INV_Misc_Bomb_06", "INV_Misc_Map_01",
        2, "Spell_Arcane_PortalShattrath", 3, "Achievement_Reputation_ArgentCrusader", "Spell_Arcane_PortalDalaran", 9, 45580, 45585, "Ability_Mount_Wyvern_01", 45579,
        "INV_Misc_Head_Gnoll_01", 45577, 45583, 4, 45584, 10, 3, 45581, 6, 45574,
    }),
    icc = icons({
        [0] = 11, 2508, 16, "Achievement_Dungeon_HordeAirship", 17, 19, "Achievement_Boss_Bronjahm", 15, "Achievement_Dungeon_Icecrown_PitofSaron", "Achievement_Dungeon_Icecrown_HallsofReflection",
        12, "Achievement_Boss_LadyDeathwhisper", 23, "Achievement_Boss_LordMarrowgar", "Achievement_Boss_Saurfang", 20, "Achievement_Boss_FestergutRotface", 16, "Achievement_Zone_IceCrown_04", 46376,
        13, 1645, 15, 40586, "Achievement_Boss_Lanathel", 21, "Achievement_Dungeon_Icecrown_FrostwingHalls", 765, 24, "Achievement_Boss_Sindragosa",
        "Achievement_Boss_SvalaSorrowgrave", "Achievement_Zone_IceCrown_01", "Achievement_Zone_IceCrown_02", 16, "Achievement_Zone_IceCrown_03", 22, 15, "Achievement_Dungeon_Icecrown_Frostmourne", 18, "Achievement_Boss_LichKing",
    }),
    dalaran = icons({
        [0] = 25, "INV_Misc_Bag_10_Black", 29, "Achievement_Arena_2v2_1", 30, 32, "INV_Drink_08", 28, "INV_Drink_03", "INV_Drink_10",
        "Achievement_Dungeon_TheVioletHold", "INV_Misc_Toy_10", 36, 8485, "INV_Drink_11", 33, "INV_Scroll_02", 29, "INV_MISC_DUST_03", "INV_Misc_PocketWatch_01",
        "INV_Misc_Statue_04", "Trade_LeatherWorking", 28, "INV_Fabric_Frostweave_Bolt", 36920, 34, "INV_Sword_27", "INV_Staff_20", 37, "INV_Misc_Herb_03",
        27, "Achievement_PVP_A_01", "Achievement_PVP_H_01", 29, "INV_Misc_Coin_02", 35, 28, "Spell_Arcane_TeleportDalaran", 31, "INV_Misc_Gem_Amethyst_01",
    }),
}
function B.PlacePath(key) return "Interface\\AddOns\\" .. ADDON .. "\\art\\place\\" .. key end
local place = B.PlacePath
B.place = {
    azeroth = {
        [0] = place("az_c0"), [10] = place("az_c32"), [15] = place("az_c15"), [19] = place("az_c19"), [20] = place("az_c20"),
        [21] = place("az_c21"), [24] = place("az_c24"), [26] = place("az_c26"), [27] = place("az_c27"), [29] = place("az_c29"),
        [31] = place("az_c31"), [32] = place("az_c32"), [34] = place("az_c34"), [35] = place("az_c15"), [37] = place("az_c37"), [39] = place("az_c39"),
    },
    icc = {
        [0] = place("icc_c0"), [6] = place("icc_c6"), [8] = place("icc_c8"), [9] = place("icc_c9"),
        [32] = place("icc_c32"), [34] = place("icc_c34"), [37] = place("icc_c37"), [39] = place("icc_c39"),
    },
    dalaran = { [0] = place("dal_c0"), [20] = place("dal_c20"), [30] = place("dal_c30") },
}
B.HOUSE_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_houses.tga"
function B.HouseCoord(board, hotel)
    local i = (B.INDEX[board] or 0) * 2 + (hotel and 1 or 0)
    local col, row = i % 4, math.floor(i / 4)
    return col * 0.25 + 0.004, col * 0.25 + 0.246, row * 0.5 + 0.004, row * 0.5 + 0.496
end
B.SPECIAL_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_specials.tga"
B.SPECIAL_N = 38
function B.SpecialCoord(i)
    local col, row = i % 8, math.floor(i / 8)
    return col * 0.125 + 0.004, col * 0.125 + 0.121, row * 0.125 + 0.004, row * 0.125 + 0.121
end
B.bgTile = {}
for _, key in ipairs({ "azeroth", "icc", "dalaran", "room", "felt" }) do
    B.bgTile[key] = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_bg_" .. key .. ".tga"
end
B.thumb = {
    azeroth = { path = "Interface\\WorldMap\\World\\World6", coord = { 0, 1, 0, 1 } },
    icc = { path = "Interface\\Glues\\LoadingScreens\\LoadScreenIcecrownCitadel", coord = { 0.1, 0.5, 0.3, 0.7 } },
    dalaran = { path = "Interface\\WorldMap\\Dalaran\\Dalaran1_6", coord = { 0, 1, 0, 1 } },
}
function B.Key(board, name)
    return "tycoon." .. (B.PREFIX[board] or "az") .. "." .. name
end
function B.GroupKey(board, g)
    if g == 9 then return B.Key(board, "gR") end
    if g == 10 then return B.Key(board, "gU") end
    return B.Key(board, "g" .. g)
end
function B.CardKey(board, deck, id)
    return B.Key(board, (deck == "c" and "ch" or "cc") .. id)
end
function B.CellName(board, c)
    return B.Key(board, B.nameKey[c])
end
function B.CellWhat(board, c)
    local k = B.nameKey[c]
    if k == "chance" or k == "chest" then return B.Key(board, "w" .. k) end
    return B.Key(board, "w" .. c)
end
