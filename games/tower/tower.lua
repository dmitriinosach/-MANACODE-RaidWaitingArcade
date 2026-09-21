local ADDON, ns = ...
local ID = "tower"
local floor, abs, min, max, sin = math.floor, math.abs, math.min, math.max, math.sin
local cos, pi, sqrt = math.cos, math.pi, math.sqrt
local atan2 = math.atan2
local ceil = math.ceil
local MAX_WINS   = 6
local MAX_SLICES = 6
local MAX_COLS   = 7
local RULER = {
    X = 14, W = 3, TOP = 44,
    STEP = 5, LABEL = 10,
    TICKS = 14, TEXTS = 5, RECS = 5,
    LX = 8, LTOP = 164, ROW = 2, GAP = 16, TIP = 16, TEXT_DX = 5,
    WEDGE = { 4, 8, 12, 16, 12, 8, 4 },
    BAR  = { 0.10, 0.11, 0.14, 0.22 },
    TICK = { 0.86, 0.87, 0.90 },
    BEST = { 1.00, 0.82, 0.00 },
    PAST = { 0.42, 0.74, 1.00 },
}
local WIN_SHARE  = 0.62
local RULES = {
    { key = "hut",   floors = 12, fw = 80, fh = 80, wins = 3 },
    { key = "house", floors = 18, fw = 72, fh = 72, wins = 4 },
    { key = "high",  floors = 26, fw = 64, fh = 64, wins = 5 },
    { key = "spire", floors = 36, fw = 56, fh = 56, wins = 6 },
}
local PAL = {}
PAL.GOLD = { 0.82, 0.66, 0.30 }
PAL.LAKHTA = {
    GLASS = { 0.42, 0.66, 0.74 }, FACET = { 0.22, 0.44, 0.54 }, PANE = { 0.19, 0.40, 0.50 },
    SLAB = { 0.16, 0.28, 0.34 }, MULLION = { 0.22, 0.38, 0.46 }, GLEAM = { 0.64, 0.84, 0.88 },
    EDGE = { 0.88, 0.96, 0.98 }, STONE = { 0.60, 0.62, 0.62 }, WATER = { 0.24, 0.44, 0.62 },
    CANOPY = { 0.74, 0.88, 0.92 }, DOOR = { 0.08, 0.14, 0.18 },
}
PAL.LAKHTA.tier = function(t)
    local rx, sign, deco, step = 8 * t, {}, {}, { 0, 3, 5 }
    for k = 0, 3 do
        sign[k + 1] = { (rx + 2 * k + 1 - 24) / 48, 12 * k, 2, 12, 1.00, PAL.LAKHTA.EDGE }
    end
    for k = 0, 2 do
        local left = rx + 2 + step[k + 1]
        local w = math.min(22, 48 - left)
        deco[k + 1] = { (left + w / 2) / 48, 16 * k, w / 48, 16, 1.00, PAL.LAKHTA.FACET, tex = false }
    end
    return { sign = { 1, sign }, deco = deco }
end
PAL.ORC = {
    WOOD = { 0.50, 0.24, 0.14 }, WOOD_DARK = { 0.38, 0.17, 0.10 },
    TILE = { 0.92, 0.42, 0.18 }, TILE_DARK = { 0.56, 0.22, 0.14 }, TILE_LIGHT = { 0.98, 0.62, 0.36 },
    BONE = { 0.92, 0.88, 0.76 }, BONE_LIGHT = { 0.98, 0.96, 0.88 },
    IRON = { 0.40, 0.40, 0.44 }, HIDE = { 0.78, 0.60, 0.38 },
    RED = { 0.70, 0.12, 0.10 }, MARK = { 0.14, 0.08, 0.06 },
    DOOR = { 0.10, 0.08, 0.08 }, GLOW = { 0.40, 0.72, 0.50 },
}
PAL.ICC = {
    GLOW = { 0.42, 0.86, 1.00 }, ICE = { 0.30, 0.54, 0.68 },
    DEEP = { 0.14, 0.18, 0.24 }, RIB = { 0.22, 0.28, 0.36 },
    EDGE = { 0.52, 0.60, 0.70 }, BONE = { 0.88, 0.90, 0.84 },
    LIT = { 1.00, 0.84, 0.48 }, DOOR = { 0.05, 0.07, 0.10 },
}
PAL.ANT = {
    MARBLE = { 0.94, 0.90, 0.80 }, CREAM = { 0.90, 0.85, 0.72 }, WALL = { 0.86, 0.81, 0.70 },
    FLUTE = { 0.74, 0.68, 0.56 },
    STONE = { 0.78, 0.73, 0.62 }, NICHE = { 0.30, 0.25, 0.20 }, INNER = { 0.44, 0.37, 0.29 },
    BLUE = { 0.22, 0.34, 0.56 }, TERRA = { 0.68, 0.30, 0.20 },
    BRONZE = { 0.48, 0.34, 0.16 }, DOOR = { 0.24, 0.16, 0.10 },
    LIT = { 1.00, 0.80, 0.42 }, OFF = { 0.22, 0.18, 0.15 },
}
PAL.KEEP = {
    STONE = { 0.64, 0.63, 0.60 }, STONE_L = { 0.76, 0.75, 0.72 },
    DARK = { 0.40, 0.40, 0.38 }, SHADOW = { 0.26, 0.26, 0.25 },
    IRON = { 0.32, 0.33, 0.36 }, WOOD = { 0.46, 0.32, 0.18 },
    ROOF = { 0.46, 0.20, 0.18 }, FLAG = { 0.66, 0.16, 0.16 },
    DOOR = { 0.10, 0.09, 0.08 }, SLIT = { 0.18, 0.17, 0.16 },
    LIT = { 1.00, 0.84, 0.48 },
}
PAL.EMP = {
    STONE = { 0.78, 0.72, 0.60 }, STONE_D = { 0.62, 0.56, 0.46 }, GRANITE = { 0.40, 0.37, 0.34 },
    PIER = { 0.90, 0.84, 0.70 }, PIER_L = { 0.98, 0.94, 0.82 },
    SPAN = { 0.29, 0.27, 0.26 }, SHADOW = { 0.34, 0.30, 0.26 },
    GLOW = { 1.00, 0.80, 0.42 }, GLOW_L = { 1.00, 0.92, 0.66 },
    MAST = { 0.72, 0.72, 0.74 }, MAST_D = { 0.50, 0.50, 0.53 },
    DOOR = { 0.10, 0.09, 0.08 },
    LIT = { 1.00, 0.84, 0.48 }, OFF = { 0.17, 0.18, 0.22 },
}
local SKIN_ERA, SKIN_WOW = "era", "wow"
local LOOKS = {
    [SKIN_ERA] = {
        { label = "tower.eraHutLabel", tip = "tower.eraHutTip", roof = "pediment",
          chute = { 0.86, 0.82, 0.70 },
          folk = {
              { skin = { 0.92, 0.76, 0.58 }, robe = { 0.90, 0.88, 0.82 },
                legs = { 0.74, 0.72, 0.66 }, cap = { 0.28, 0.22, 0.16 } },
              { skin = { 0.94, 0.78, 0.60 }, robe = { 0.86, 0.80, 0.62 },
                legs = { 0.70, 0.66, 0.54 }, cap = { 0.62, 0.54, 0.28 } },
              { skin = { 0.90, 0.74, 0.56 }, robe = { 0.88, 0.86, 0.80 },
                legs = { 0.72, 0.70, 0.64 }, cap = { 0.80, 0.78, 0.74 },
                crest = { 0.52, 0.64, 0.34 }, item = { 0.60, 0.46, 0.28 } },
              { skin = { 0.94, 0.80, 0.64 }, robe = { 0.72, 0.32, 0.26 },
                legs = { 0.54, 0.28, 0.22 }, cap = { 0.24, 0.18, 0.14 } },
          },
          hero = {
              { skin = { 0.94, 0.80, 0.64 }, robe = { 0.94, 0.92, 0.86 },
                legs = { 0.80, 0.78, 0.70 }, cap = { 0.84, 0.68, 0.30 },
                crest = { 0.86, 0.72, 0.34 }, item = { 0.86, 0.72, 0.34 },
                chute = { 0.90, 0.80, 0.44 } },
          },
          fw = 80, fh = 80, wins = 3,
          tint = PAL.ANT.MARBLE, rtint = PAL.ANT.MARBLE,
          tex = "stone", texCol = "marble",
          lit = PAL.ANT.LIT, off = PAL.ANT.NICHE,
          ww = 16, wh = 30, wy = 31,
          col = { { 6, 42, 10, 1.00, PAL.ANT.MARBLE },
                  { 2, 42, 10, 1.00, PAL.ANT.FLUTE, tex = false },
                  { 6, 9, 57, 1.00, PAL.ANT.BLUE, tex = false } },
          wdeco = { { 0, 30.5, 6, 9, 1.00, PAL.ANT.BLUE }, { -6.67, 30.5, 4, 5, 1.00, PAL.GOLD } },
          deco = { { 0.5, 65, 1.00, 1, 1.00, PAL.ANT.INNER, tex = false },
                   { 0.5, 9, 1.00, 1, 1.00, PAL.ANT.MARBLE, tex = false },
                   { 0.5, 46, 0.94, 2, 1.00, PAL.ANT.INNER, tex = false } },
          sign = { 1, { { -0.469, 49, 5, 3, 1.00, PAL.ANT.CREAM }, { -0.1667, 49, 8, 3, 1.00, PAL.ANT.CREAM },
                        { 0.1667, 49, 8, 3, 1.00, PAL.ANT.CREAM }, { 0.469, 49, 5, 3, 1.00, PAL.ANT.CREAM } } },
          slices = { { 1.00, 10, 0.96, PAL.ANT.STONE }, { 0.94, 42, 1.00, PAL.ANT.NICHE, tex = false },
                     { 1.00, 5, 1.00, PAL.ANT.MARBLE, tex = "marble" }, { 1.00, 9, 1.00, PAL.ANT.CREAM, tex = false },
                     { 1.04, 4, 1.00, PAL.ANT.MARBLE, tex = "marble" }, { 1.00, 10, 0.88 } },
          tiers = { "", "ionic" },
          vars = {
              ionic = {
                  ww = 8, wh = 24, wy = 31,
                  col = { { 5, 42, 10, 1.00, PAL.ANT.MARBLE },
                          { 1, 42, 10, 1.00, PAL.ANT.FLUTE, tex = false },
                          { 4, 5, 59, 1.00, PAL.GOLD, tex = false } },
                  wdeco = { { 0, 30.5, 4, 5, 1.00, PAL.GOLD }, { -6.67, 30.5, 4, 5, 1.00, PAL.GOLD } },
                  deco = { { 0.5, 65, 1.00, 1, 1.00, PAL.ANT.INNER, tex = false },
                           { 0.5, 9, 1.00, 1, 1.00, PAL.ANT.MARBLE, tex = false },
                           { 0.5, 10, 0.94, 3, 1.00, PAL.ANT.STONE, tex = "stone" } },
                  slices = { { 1.00, 10, 0.96, PAL.ANT.STONE }, { 0.94, 42, 1.00, PAL.ANT.WALL, tex = "marble" },
                             { 1.00, 5, 1.00, PAL.ANT.MARBLE, tex = "marble" }, { 1.00, 9, 1.00, PAL.ANT.TERRA, tex = false },
                             { 1.04, 4, 1.00, PAL.ANT.MARBLE, tex = "marble" }, { 1.00, 10, 0.88 } } },
              base = {
                  ww = 1, wh = 1, wy = 20,
                  wdeco = { { 0, 41.5, 6, 9, 1.00, PAL.ANT.BLUE }, { -6.67, 41.5, 4, 5, 1.00, PAL.GOLD } },
                  deco = { { 0.5, 10, 0.22, 32, 1.00, PAL.ANT.DOOR, tex = false },
                           { 0.5, 10, 0.02, 32, 1.00, PAL.GOLD, tex = false },
                           { 0.5, 42, 0.28, 3, 1.00, PAL.ANT.MARBLE, tex = "marble" } },
                  sign = { 1, { { -0.31, 22, 8, 4, 1.00, PAL.ANT.BRONZE }, { -0.31, 10, 2, 12, 1.00, PAL.ANT.BRONZE },
                                { 0.31, 22, 8, 4, 1.00, PAL.ANT.BRONZE }, { 0.31, 10, 2, 12, 1.00, PAL.ANT.BRONZE } } },
                  slices = { { 1.20, 6, 0.92, PAL.ANT.STONE }, { 1.08, 4, 0.96, PAL.ANT.STONE },
                             { 0.94, 42, 1.00, PAL.ANT.NICHE, tex = false }, { 1.00, 14, 1.00, PAL.ANT.CREAM, tex = false },
                             { 1.04, 4, 0.94, PAL.ANT.MARBLE, tex = "marble" }, { 1.00, 10, 0.97, PAL.ANT.STONE } } },
              cap = {
                  ww = 1, wh = 1, wy = 20,
                  wdeco = { { 0, 18, 6, 8, 1.00, PAL.ANT.BLUE }, { -6.67, 18, 4, 5, 1.00, PAL.GOLD } },
                  col = { { 6, 20, 10, 1.00, PAL.ANT.MARBLE },
                          { 2, 20, 10, 1.00, PAL.ANT.FLUTE, tex = false },
                          { 6, 8, 34, 1.00, PAL.ANT.BLUE, tex = false } },
                  deco = { { 0.5, 54, 0.64, 8, 1.00, PAL.ANT.CREAM, tex = "marble" },
                           { 0.5, 62, 0.44, 8, 1.00, PAL.ANT.MARBLE, tex = "marble" },
                           { 0.5, 70, 0.24, 6, 1.00, PAL.ANT.CREAM, tex = "marble" } },
                  sign = { 1, { { 0, 75, 5, 6, 1.00, PAL.GOLD }, { -0.49, 46, 5, 5, 1.00, PAL.GOLD },
                                { 0.49, 46, 5, 5, 1.00, PAL.GOLD }, { 0, 47, 6, 12, 1.00, PAL.GOLD } } },
                  slices = { { 1.00, 10, 0.96, PAL.ANT.STONE }, { 0.94, 20, 1.00, PAL.ANT.NICHE, tex = false },
                             { 1.00, 12, 1.00, PAL.ANT.CREAM, tex = false }, { 1.06, 4, 1.00, PAL.ANT.MARBLE, tex = "marble" },
                             { 0.84, 8, 1.00, PAL.ANT.MARBLE, tex = "marble" }, { 0.05, 26, 1.00, PAL.ANT.MARBLE, tex = "marble" } } },
          } },
        { label = "tower.eraHouseLabel", tip = "tower.eraHouseTip", roof = "merlons",
          chute = { 0.52, 0.38, 0.28 },
          folk = {
              { skin = { 0.92, 0.76, 0.58 }, robe = { 0.44, 0.34, 0.24 },
                legs = { 0.30, 0.24, 0.18 }, cap = { 0.34, 0.24, 0.14 } },
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.36, 0.42, 0.30 },
                legs = { 0.26, 0.28, 0.22 }, cap = { 0.72, 0.60, 0.30 } },
              { skin = { 0.90, 0.74, 0.56 }, robe = { 0.32, 0.26, 0.20 },
                legs = { 0.24, 0.20, 0.16 }, cap = { 0.28, 0.22, 0.16 },
                item = { 0.56, 0.42, 0.26 }, arm = 2 },
              { skin = { 0.92, 0.76, 0.60 }, robe = { 0.52, 0.54, 0.56 },
                legs = { 0.30, 0.30, 0.32 }, cap = { 0.60, 0.62, 0.64 },
                item = { 0.76, 0.78, 0.80 }, arm = 4 },
          },
          hero = {
              { skin = { 0.92, 0.76, 0.60 }, robe = { 0.68, 0.20, 0.22 },
                legs = { 0.34, 0.30, 0.28 }, cap = { 0.72, 0.74, 0.78 },
                crest = { 0.86, 0.70, 0.32 }, item = { 0.84, 0.84, 0.88 },
                arm = 4, chute = { 0.80, 0.24, 0.24 } },
          },
          fh = 72, wins = 4,
          tint = PAL.KEEP.STONE, rtint = PAL.KEEP.DARK,
          tex = "stone",
          lit = PAL.KEEP.LIT, off = PAL.KEEP.SLIT,
          ww = 4, wh = 16, wy = 30,
          col = { { 8, 38, 10, 1.00 },
                  { 6, 6, 48, 1.00, PAL.KEEP.SHADOW, tex = false },
                  { 8, 8, 54, 1.00, PAL.KEEP.STONE_L, tex = false } },
          wdeco = { { 0, 3, 7, 2, 1.00, PAL.KEEP.SLIT },
                    { 0, -10, 8, 2, 1.00, PAL.KEEP.DARK } },
          deco = { { 0.5, 46, 0.94, 2, 1.00, PAL.KEEP.SHADOW, tex = false },
                   { 0.5, 62, 1.00, 2, 1.00, PAL.KEEP.DARK, tex = false } },
          sign = { 3, { { -0.34, 20, 0.03, 26, 1.00, PAL.KEEP.IRON },
                        { -0.30, 30, 0.10, 14, 1.00, PAL.KEEP.FLAG },
                        { 0.34, 20, 0.03, 26, 1.00, PAL.KEEP.IRON },
                        { 0.30, 30, 0.10, 14, 1.00, PAL.KEEP.FLAG } } },
          slices = { { 1.00, 10, 0.94 }, { 0.88, 38, 1.00 },
                     { 1.00, 6, 0.96 }, { 0.96, 8, 1.00, PAL.KEEP.DARK, tex = false },
                     { 1.00, 10, 0.94 } },
          tiers = { "", "hoard" },
          vars = {
              hoard = {
                  slices = { { 1.00, 10, 0.94 }, { 0.88, 38, 1.00 },
                             { 1.00, 6, 1.00, PAL.KEEP.WOOD, tex = "wood" },
                             { 0.96, 8, 1.00, PAL.KEEP.WOOD, tex = "wood" },
                             { 1.00, 10, 0.94 } },
                  col = { { 8, 38, 10, 1.00 },
                          { 6, 6, 48, 1.00, PAL.KEEP.SHADOW, tex = false },
                          { 5, 8, 54, 1.00, PAL.KEEP.SHADOW, tex = false } } },
              base = {
                  wins = 0, col = false, wdeco = false,
                  deco = { { 0.5, 16, 0.30, 40, 1.00, PAL.KEEP.DOOR, tex = false },
                           { 0.5, 42, 0.30, 3, 1.00, PAL.KEEP.IRON, tex = false },
                           { 0.5, 58, 0.96, 4, 1.00, PAL.KEEP.DARK, tex = false } },
                  sign = { 1, { { -0.40, 16, 0.16, 44, 1.00, PAL.KEEP.STONE_L },
                                { -0.40, 58, 0.18, 6, 1.00, PAL.KEEP.DARK },
                                { 0.40, 16, 0.16, 44, 1.00, PAL.KEEP.STONE_L },
                                { 0.40, 58, 0.18, 6, 1.00, PAL.KEEP.DARK } } },
                  slices = { { 1.24, 8, 0.92 }, { 1.10, 8, 0.94 },
                             { 1.00, 46, 1.00 }, { 1.00, 10, 0.94 } } },
              cap = {
                  wins = 0, col = false, wdeco = false,
                  deco = { { 0.5, 24, 0.10, 12, 1.00, PAL.KEEP.LIT, tex = false },
                           { 0.5, 54, 0.02, 26, 1.00, PAL.KEEP.IRON, tex = false },
                           { 0.56, 68, 0.16, 9, 1.00, PAL.KEEP.FLAG, tex = false } },
                  sign = { 1, { { -0.38, 10, 0.12, 34, 1.00, PAL.KEEP.STONE_L },
                                { -0.38, 44, 0.12, 10, 1.00, PAL.KEEP.ROOF },
                                { 0.38, 10, 0.12, 34, 1.00, PAL.KEEP.STONE_L },
                                { 0.38, 44, 0.12, 10, 1.00, PAL.KEEP.ROOF } } },
                  slices = { { 1.00, 10, 0.94 }, { 0.62, 28, 1.00 },
                             { 0.70, 6, 0.96 },
                             { 0.56, 10, 1.00, PAL.KEEP.DARK, tex = false },
                             { 0.20, 18, 1.00, PAL.KEEP.ROOF, tex = false } } },
          } },
        { label = "tower.eraHighLabel", tip = "tower.eraHighTip", roof = "ziggurat",
          chute = { 0.74, 0.62, 0.40 },
          folk = {
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.34, 0.40, 0.52 },
                legs = { 0.26, 0.28, 0.34 }, cap = { 0.30, 0.22, 0.16 } },
              { skin = { 0.96, 0.80, 0.66 }, robe = { 0.62, 0.34, 0.42 },
                legs = { 0.38, 0.22, 0.28 }, cap = { 0.28, 0.22, 0.26 },
                crest = { 0.72, 0.44, 0.50 } },
              { skin = { 0.90, 0.74, 0.56 }, robe = { 0.46, 0.42, 0.30 },
                legs = { 0.30, 0.28, 0.22 }, cap = { 0.36, 0.34, 0.28 },
                item = { 0.54, 0.46, 0.32 }, arm = 4 },
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.52, 0.50, 0.46 },
                legs = { 0.30, 0.28, 0.26 }, cap = { 0.54, 0.50, 0.44 } },
          },
          hero = {
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.74, 0.64, 0.34 },
                legs = { 0.36, 0.32, 0.24 }, cap = { 0.30, 0.24, 0.18 },
                crest = { 0.86, 0.72, 0.34 }, chute = { 0.88, 0.74, 0.36 } },
          },
          fh = 64, wins = 5,
          tint = PAL.EMP.STONE, rtint = PAL.EMP.STONE,
          tex = "stone", texCol = "stone",
          lit = PAL.EMP.LIT, off = PAL.EMP.OFF,
          ww = 6, wh = 22, wy = 32,
          col = { { 5, 64, 0, 1.00, PAL.EMP.PIER },
                  { 2, 64, 0, 1.00, PAL.EMP.PIER_L, tex = false } },
          wdeco = { { 0, -20, 8, 18, 1.00, PAL.EMP.SPAN },
                    { 0, 20, 8, 18, 1.00, PAL.EMP.SPAN } },
          sign = { 1, { { -0.48, 0, 3, 64, 1.00, PAL.EMP.PIER }, { 0.48, 0, 3, 64, 1.00, PAL.EMP.PIER },
                        { 0, 2, 1.00, 1, 1.00, PAL.EMP.SHADOW }, { 0, 61, 1.00, 1, 1.00, PAL.EMP.SHADOW } } },
          slices = { { 1.00, 10, 0.94 }, { 1.00, 44, 1.00 }, { 1.00, 10, 0.96 } },
          tiers = { "", "", "setback" },
          vars = {
              setback = {
                  ww = 6, wh = 22, wy = 28,
                  col = { { 5, 50, 0, 1.00, PAL.EMP.PIER },
                          { 2, 50, 0, 1.00, PAL.EMP.PIER_L, tex = false } },
                  wdeco = { { 0, -18, 8, 14, 1.00, PAL.EMP.SPAN },
                            { 0, 16.5, 8, 11, 1.00, PAL.EMP.SPAN } },
                  sign = { 1, { { -0.48, 0, 3, 50, 1.00, PAL.EMP.PIER }, { 0.48, 0, 3, 50, 1.00, PAL.EMP.PIER },
                                { 0, 48, 1.16, 2, 1.00, PAL.EMP.SHADOW }, { 0, 2, 1.00, 1, 1.00, PAL.EMP.SHADOW } } },
                  slices = { { 1.00, 10, 0.94 }, { 1.00, 40, 1.00 },
                             { 1.16, 4, 1.00, PAL.EMP.STONE_D }, { 1.00, 10, 0.97 } } },
              base = {
                  wins = 2, ww = 14, wh = 12, wy = 15, col = false,
                  wdeco = { { 0, 17, 14, 7, 1.00, PAL.EMP.OFF }, { 0, 28, 14, 7, 1.00, PAL.EMP.OFF } },
                  deco = { { 0.5, 5, 0.20, 26, 1.00, PAL.EMP.DOOR, tex = false },
                           { 0.5, 20, 0.14, 9, 1.00, PAL.EMP.LIT, tex = false },
                           { 0.5, 31, 0.36, 4, 1.00, PAL.GOLD, tex = false } },
                  sign = { 1, { { -0.42, 5, 6, 47, 1.00, PAL.EMP.PIER }, { 0.42, 5, 6, 47, 1.00, PAL.EMP.PIER },
                                { -0.125, 5, 4, 47, 1.00, PAL.EMP.PIER }, { 0.125, 5, 4, 47, 1.00, PAL.EMP.PIER } } },
                  slices = { { 1.24, 5, 1.00, PAL.EMP.GRANITE, tex = false }, { 1.18, 46, 1.00 },
                             { 1.22, 3, 1.00, PAL.EMP.STONE_D }, { 1.00, 10, 0.96 } } },
              cap = {
                  ww = 6, wh = 5, wy = 14, wdeco = false,
                  col = { { 3, 8, 10, 1.00, PAL.EMP.PIER } },
                  deco = { { 0.5, 40, 0.62, 2, 1.00, PAL.EMP.STONE_D, tex = false },
                           { 0.5, 45, 0.10, 6, 1.00, PAL.EMP.MAST_D, tex = false },
                           { 0.5, 61, 0.05, 3, 1.00, PAL.EMP.GLOW_L, tex = false } },
                  sign = { 1, { { -0.08, 22, 3, 18, 1.00, PAL.EMP.PIER }, { 0.08, 22, 3, 18, 1.00, PAL.EMP.PIER },
                                { -0.19, 22, 3, 18, 1.00, PAL.EMP.PIER }, { 0.19, 22, 3, 18, 1.00, PAL.EMP.PIER } } },
                  slices = { { 1.00, 10, 0.94 }, { 1.00, 8, 1.00 }, { 0.74, 4, 0.97 },
                             { 0.54, 18, 1.00, PAL.EMP.GLOW, tex = false }, { 0.30, 5, 1.00, PAL.EMP.GLOW_L, tex = false },
                             { 0.03, 19, 1.00, PAL.EMP.MAST, tex = false } } },
          } },
        { label = "tower.eraSpireLabel", tip = "tower.eraSpireTip", roof = "needle",
          chute = { 0.38, 0.56, 0.74 },
          folk = {
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.24, 0.28, 0.36 },
                legs = { 0.20, 0.22, 0.28 }, cap = { 0.28, 0.22, 0.16 } },
              { skin = { 0.96, 0.80, 0.66 }, robe = { 0.60, 0.62, 0.68 },
                legs = { 0.28, 0.30, 0.36 }, cap = { 0.74, 0.62, 0.34 } },
              { skin = { 0.88, 0.72, 0.54 }, robe = { 0.70, 0.44, 0.22 },
                legs = { 0.26, 0.26, 0.30 }, cap = { 0.24, 0.20, 0.16 },
                item = { 0.44, 0.34, 0.26 } },
              { skin = { 0.92, 0.76, 0.60 }, robe = { 0.32, 0.46, 0.44 },
                legs = { 0.24, 0.26, 0.28 }, cap = { 0.46, 0.42, 0.38 } },
          },
          hero = {
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.22, 0.24, 0.30 },
                legs = { 0.18, 0.20, 0.24 }, cap = { 0.30, 0.24, 0.18 },
                crest = { 0.86, 0.72, 0.34 }, item = { 0.86, 0.76, 0.42 },
                chute = { 0.86, 0.74, 0.38 } },
          },
          fw = 48, fh = 48, wins = 6,
          tint = PAL.LAKHTA.GLASS, rtint = PAL.LAKHTA.GLASS,
          lit = { 1.00, 0.84, 0.46 }, off = PAL.LAKHTA.PANE,
          ww = 4, wh = 36, wy = 25,
          col = { { 1, 48, 0, 1.00, PAL.LAKHTA.MULLION, tex = false } },
          sign = PAL.LAKHTA.tier(0).sign, deco = PAL.LAKHTA.tier(0).deco,
          slices = { { 1.00, 2, 1.00, PAL.LAKHTA.SLAB }, { 1.00, 1, 1.00, PAL.LAKHTA.GLEAM },
                     { 1.00, 45, 1.00 } },
          tiers = { "", "t1", "t2", "t3", "t4", "t5" },
          vars = {
              t1 = PAL.LAKHTA.tier(1), t2 = PAL.LAKHTA.tier(2), t3 = PAL.LAKHTA.tier(3),
              t4 = PAL.LAKHTA.tier(4), t5 = PAL.LAKHTA.tier(5),
              base = {
                  wins = 3, ww = 8, wh = 14, wy = 29,
                  col = { { 1, 30, 18, 1.00, PAL.LAKHTA.MULLION, tex = false } },
                  sign = { 1, { { -0.42, 18, 0.12, 2, 1.00, PAL.LAKHTA.EDGE },
                                { -0.14, 18, 0.12, 2, 1.00, PAL.LAKHTA.EDGE },
                                { 0.14, 18, 0.12, 2, 1.00, PAL.LAKHTA.EDGE },
                                { 0.42, 18, 0.12, 2, 1.00, PAL.LAKHTA.EDGE } } },
                  deco = { { 0.5, 3, 0.20, 9, 1.00, PAL.LAKHTA.DOOR, tex = false },
                           { 0.5, 3, 0.02, 9, 1.00, PAL.LAKHTA.GLEAM, tex = false } },
                  slices = { { 1.44, 3, 0.94, PAL.LAKHTA.STONE, tex = "stone" }, { 1.24, 11, 1.00, PAL.LAKHTA.STONE, tex = "stone" },
                             { 1.34, 2, 1.00, PAL.LAKHTA.CANOPY }, { 1.18, 2, 1.00, PAL.LAKHTA.GLEAM },
                             { 1.00, 29, 1.00 }, { 1.00, 1, 1.00, PAL.LAKHTA.GLEAM } } },
              cap = {
                  wins = 0, col = false, sign = false,
                  deco = { { 0.5, 8, 0.04, 40, 1.00, PAL.LAKHTA.EDGE, tex = false } },
                  slices = { { 1.00, 2, 1.00, PAL.LAKHTA.SLAB }, { 1.00, 6, 1.00 }, { 0.76, 4, 1.00 },
                             { 0.52, 4, 1.00 }, { 0.30, 5, 1.00, PAL.LAKHTA.GLEAM },
                             { 0.08, 27, 1.00, PAL.LAKHTA.GLEAM } } },
          } },
    },
    [SKIN_WOW] = {
        { label = "tower.wowHutLabel", tip = "tower.wowHutTip", roof = "orc",
          chute = { 0.58, 0.18, 0.14 },
          folk = {
              { skin = { 0.45, 0.63, 0.34 }, robe = { 0.55, 0.30, 0.20 },
                legs = { 0.30, 0.24, 0.18 }, cap = { 0.14, 0.12, 0.11 },
                tusk = { 0.92, 0.90, 0.80 }, arm = 4 },
              { skin = { 0.36, 0.53, 0.29 }, robe = { 0.34, 0.32, 0.30 },
                legs = { 0.22, 0.20, 0.19 }, cap = { 0.14, 0.12, 0.11 },
                tusk = { 0.92, 0.90, 0.80 }, item = { 0.55, 0.40, 0.24 }, arm = 4 },
              { skin = { 0.31, 0.53, 0.64 }, robe = { 0.24, 0.46, 0.42 },
                legs = { 0.20, 0.30, 0.32 }, crest = { 0.88, 0.44, 0.16 },
                tusk = { 0.92, 0.90, 0.80 }, arm = 2 },
              { skin = { 0.26, 0.45, 0.55 }, robe = { 0.44, 0.34, 0.22 },
                legs = { 0.24, 0.22, 0.18 }, crest = { 0.52, 0.68, 0.28 },
                tusk = { 0.92, 0.90, 0.80 }, item = { 0.42, 0.32, 0.22 }, arm = 2 },
              { skin = { 0.53, 0.68, 0.40 }, robe = { 0.72, 0.50, 0.20 },
                legs = { 0.32, 0.26, 0.20 }, cap = { 0.20, 0.14, 0.12 } },
          },
          hero = {
              { skin = { 0.42, 0.62, 0.34 }, robe = { 0.28, 0.38, 0.52 },
                legs = { 0.22, 0.24, 0.30 }, cap = { 0.14, 0.12, 0.11 },
                tusk = { 0.92, 0.90, 0.80 }, item = { 0.70, 0.56, 0.32 },
                arm = 4, chute = { 0.34, 0.52, 0.70 } },
              { skin = { 0.38, 0.55, 0.30 }, robe = { 0.24, 0.22, 0.22 },
                legs = { 0.20, 0.18, 0.18 }, cap = { 0.14, 0.12, 0.11 },
                crest = { 0.72, 0.20, 0.16 }, tusk = { 0.92, 0.90, 0.80 },
                item = { 0.78, 0.24, 0.18 }, arm = 4, chute = { 0.80, 0.26, 0.18 } },
          },
          tint = { 0.80, 0.52, 0.40 }, rtint = { 0.62, 0.26, 0.20 },
          tex = "stone", wins = 2,
          lit = { 1.00, 0.72, 0.36 }, off = { 0.22, 0.14, 0.10 },
          ww = 14, wh = 12, wy = 36,
          col = { { 6, 50, 10, 1.00, PAL.ORC.WOOD, tex = "wood" },
                  { 8, 3, 20, 1.00, PAL.ORC.IRON, tex = false },
                  { 8, 3, 40, 1.00, PAL.ORC.IRON, tex = false } },
          wdeco = { { 0, 0, 14, 2, 1.00, PAL.ORC.WOOD }, { 0, 0, 2, 12, 1.00, PAL.ORC.WOOD } },
          deco = { { 0.04, 10, 0.08, 18, 1.00, PAL.ORC.BONE, tex = false },
                   { 0.96, 10, 0.08, 18, 1.00, PAL.ORC.BONE, tex = false },
                   { 0.5, 3, 1.00, 2, 1.00, PAL.ORC.IRON, tex = false } },
          sign = { 3, { { 0.56, 60, 14, 3, 1.00, PAL.ORC.WOOD },
                        { 0.65, 63, 3, 8, 1.00, PAL.ORC.BONE },
                        { 0.62, 34, 12, 26, 1.00, PAL.ORC.RED },
                        { 0.62, 42, 6, 8, 1.00, PAL.ORC.MARK } } },
          slices = { { 1.00, 10, 1.00, PAL.ORC.WOOD, tex = "wood" }, { 0.84, 50, 1.00 },
                     { 0.94, 6, 1.00, PAL.ORC.TILE_DARK, tex = "tile" }, { 1.00, 8, 1.00, PAL.ORC.TILE, tex = "tile" },
                     { 1.00, 6, 1.00, PAL.ORC.TILE_LIGHT, tex = "tile" } },
          tiers = { "", "planks" },
          vars = {
              planks = {
                  ww = 12, wh = 10, wy = 34,
                  col = { { 6, 50, 10, 1.00, PAL.ORC.WOOD_DARK, tex = "wood" },
                          { 5, 5, 30, 1.00, PAL.ORC.IRON, tex = false } },
                  wdeco = { { 0, 9, 18, 4, 1.00, PAL.ORC.HIDE }, { 0, -9, 4, 4, 1.00, PAL.ORC.IRON } },
                  deco = { { 0.04, 10, 0.08, 18, 1.00, PAL.ORC.BONE, tex = false },
                           { 0.96, 10, 0.08, 18, 1.00, PAL.ORC.BONE, tex = false },
                           { 0.5, 3, 1.00, 2, 1.00, PAL.ORC.IRON, tex = false } },
                  sign = { 1, { { 0, 24, 0.16, 34, 1.00, PAL.ORC.RED },
                                { 0, 36, 0.08, 10, 1.00, PAL.ORC.MARK },
                                { 0, 56, 0.20, 3, 1.00, PAL.ORC.WOOD_DARK } } },
                  slices = { { 1.00, 10, 1.00, PAL.ORC.WOOD, tex = "wood" }, { 0.84, 50, 1.00, PAL.ORC.WOOD, tex = "wood" },
                             { 0.94, 6, 1.00, PAL.ORC.TILE_DARK, tex = "tile" }, { 1.00, 8, 1.00, PAL.ORC.TILE, tex = "tile" },
                             { 1.00, 6, 1.00, PAL.ORC.TILE_LIGHT, tex = "tile" } } },
              base = {
                  wins = 0, tint = { 0.72, 0.44, 0.34 },
                  col = false, wdeco = false,
                  deco = { { 0.5, 10, 0.32, 48, 1.00, PAL.ORC.DOOR, tex = false },
                           { 0.5, 10, 0.14, 38, 1.00, PAL.ORC.GLOW, tex = false },
                           { 0.5, 52, 0.40, 6, 1.00, PAL.ORC.HIDE, tex = false } },
                  sign = { 1, { { -0.26, 10, 0.10, 32, 1.00, PAL.ORC.BONE },
                                { -0.19, 42, 0.08, 16, 1.00, PAL.ORC.BONE_LIGHT },
                                { 0.26, 10, 0.10, 32, 1.00, PAL.ORC.BONE },
                                { 0.19, 42, 0.08, 16, 1.00, PAL.ORC.BONE_LIGHT } } },
                  slices = { { 1.30, 5, 0.92 }, { 1.18, 5, 0.96 }, { 1.00, 60, 1.00 },
                             { 1.00, 10, 1.00, PAL.ORC.WOOD, tex = "wood" } } },
              cap = {
                  wins = 0, col = false, wdeco = false, sign = false,
                  deco = { { 0.5, 16, 0.16, 12, 1.00, { 1.00, 0.72, 0.36 }, tex = false },
                           { 0.10, 34, 0.07, 16, 1.00, PAL.ORC.BONE, tex = false },
                           { 0.90, 34, 0.07, 16, 1.00, PAL.ORC.BONE, tex = false } },
                  slices = { { 1.00, 8, 1.00, PAL.ORC.WOOD, tex = "wood" }, { 0.56, 26, 1.00, PAL.ORC.WOOD, tex = "wood" },
                             { 0.90, 4, 1.00, PAL.ORC.TILE_DARK, tex = "tile" }, { 0.84, 10, 1.00, PAL.ORC.TILE, tex = "tile" },
                             { 0.60, 6, 1.00, PAL.ORC.TILE_LIGHT, tex = "tile" },
                             { 0.10, 26, 1.00, PAL.ORC.BONE_LIGHT, tex = false } } },
          } },
        { label = "tower.wowHouseLabel", tip = "tower.wowHouseTip", roof = "keep",
          chute = { 0.26, 0.40, 0.70 },
          folk = {
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.26, 0.36, 0.60 },
                legs = { 0.32, 0.26, 0.20 }, cap = { 0.36, 0.24, 0.14 } },
              { skin = { 0.96, 0.80, 0.66 }, robe = { 0.62, 0.22, 0.28 },
                legs = { 0.30, 0.24, 0.20 }, cap = { 0.84, 0.68, 0.34 } },
              { skin = { 0.92, 0.76, 0.60 }, robe = { 0.50, 0.54, 0.60 },
                legs = { 0.28, 0.30, 0.34 }, cap = { 0.62, 0.64, 0.68 },
                crest = { 0.84, 0.68, 0.30 }, item = { 0.78, 0.80, 0.84 }, arm = 4 },
              { skin = { 0.90, 0.74, 0.56 }, robe = { 0.46, 0.42, 0.28 },
                legs = { 0.34, 0.28, 0.20 }, cap = { 0.30, 0.22, 0.14 } },
              { skin = { 0.94, 0.78, 0.62 }, robe = { 0.44, 0.30, 0.44 },
                legs = { 0.28, 0.24, 0.22 }, cap = { 0.58, 0.54, 0.50 } },
          },
          hero = {
              { skin = { 0.92, 0.76, 0.60 }, robe = { 0.74, 0.76, 0.82 },
                legs = { 0.34, 0.36, 0.42 }, cap = { 0.78, 0.80, 0.86 },
                crest = { 0.86, 0.70, 0.32 }, item = { 0.90, 0.88, 0.76 },
                arm = 4, chute = { 0.86, 0.70, 0.30 } },
              { skin = { 0.94, 0.80, 0.66 }, robe = { 0.88, 0.86, 0.78 },
                legs = { 0.62, 0.60, 0.54 }, cap = { 0.86, 0.70, 0.32 },
                item = { 0.86, 0.72, 0.36 }, chute = { 0.92, 0.86, 0.64 } },
          },
          tint = { 0.94, 0.94, 0.97 }, rtint = { 0.24, 0.40, 0.72 },
          tex = "stone", texCol = "marble", texDeco = "marble",
          lit = { 1.00, 0.86, 0.50 }, off = { 0.30, 0.46, 0.76 },
          ww = 8, wh = 22, wy = 32,
          wdeco = { { 0, 13, 6, 3, 0.74 }, { 0, -13, 10, 2, 1.00, PAL.GOLD } },
          deco = { { 0.035, 10, 0.05, 38, 0.96 }, { 0.965, 10, 0.05, 38, 0.96 },
                   { 0.5, 48, 0.84, 1, 0.80, tex = false } },
          sign = { 3, { { 0.56, 52, 14, 2, 1.00, { 0.30, 0.21, 0.13 } },
                        { 0.62, 50, 2, 2, 1.00, { 0.30, 0.21, 0.13 } },
                        { 0.62, 41, 18, 9, 1.00, { 0.20, 0.34, 0.64 } },
                        { 0.62, 43, 12, 5, 1.00, { 0.86, 0.72, 0.34 } } } },
          slices = { { 1.00, 10, 0.90 }, { 0.84, 38, 1.00 }, { 1.00, 8, 1.00, { 0.26, 0.42, 0.70 } },
                     { 1.00, 6, 0.94 }, { 1.00, 10, 0.97 } },
          tiers = { "", "banners" },
          vars = {
              banners = {
                  ww = 8, wh = 18, wy = 34,
                  wdeco = { { -6.5, 2, 4, 24, 1.00, { 0.16, 0.30, 0.62 } },
                            { -6.5, 8, 3, 3, 1.00, PAL.GOLD } },
                  deco = { { 0.5, 54, 1.00, 1, 0.80, tex = false }, { 0.5, 10, 1.00, 2, 0.86 } },
                  slices = { { 1.00, 10, 0.90 }, { 1.00, 44, 1.00 }, { 1.00, 8, 1.00, { 0.26, 0.42, 0.70 } },
                             { 1.00, 10, 0.97 } } },
              base = {
                  wins = 0, tint = { 0.86, 0.87, 0.90 },
                  col = { { 6, 48, 12, 0.90 } },
                  wdeco = false,
                  deco = { { 0.5, 12, 0.24, 36, 1.00, { 0.14, 0.12, 0.14 }, tex = false },
                           { 0.5, 48, 0.16, 6, 1.00, { 0.14, 0.12, 0.14 }, tex = false },
                           { 0.5, 0, 0.14, 14, 1.00, { 0.62, 0.14, 0.14 }, tex = false } },
                  slices = { { 1.30, 4, 0.80 }, { 1.20, 4, 0.86 }, { 1.10, 4, 0.92 },
                             { 1.00, 48, 1.00 }, { 1.00, 2, 1.00, PAL.GOLD }, { 1.00, 10, 0.97 } } },
              cap = {
                  wins = 0, col = false, wdeco = false, deco = false, sign = false,
                  slices = { { 1.00, 8, 1.00 }, { 0.90, 12, 1.00, { 0.26, 0.42, 0.70 } },
                             { 0.70, 14, 1.00, { 0.24, 0.40, 0.68 } }, { 0.50, 14, 1.00, { 0.22, 0.38, 0.66 } },
                             { 0.30, 14, 1.00, { 0.20, 0.36, 0.64 } }, { 0.10, 10, 1.00, PAL.GOLD, tex = false } } },
          } },
        { label = "tower.wowHighLabel", tip = "tower.wowHighTip", roof = "arcane",
          chute = { 0.56, 0.40, 0.76 },
          folk = {
              { skin = { 0.94, 0.82, 0.72 }, robe = { 0.46, 0.30, 0.64 },
                legs = { 0.30, 0.22, 0.40 }, cap = { 0.40, 0.26, 0.56 },
                crest = { 0.46, 0.30, 0.64 }, item = { 0.62, 0.46, 0.28 }, arm = 2 },
              { skin = { 0.92, 0.80, 0.70 }, robe = { 0.28, 0.34, 0.66 },
                legs = { 0.20, 0.24, 0.44 }, cap = { 0.24, 0.30, 0.58 },
                crest = { 0.28, 0.34, 0.66 }, item = { 0.62, 0.46, 0.28 }, arm = 2 },
              { skin = { 0.94, 0.82, 0.72 }, robe = { 0.64, 0.24, 0.28 },
                legs = { 0.40, 0.18, 0.20 }, cap = { 0.56, 0.20, 0.24 },
                crest = { 0.64, 0.24, 0.28 }, item = { 0.62, 0.46, 0.28 }, arm = 2 },
              { skin = { 0.96, 0.84, 0.74 }, robe = { 0.52, 0.44, 0.70 },
                legs = { 0.32, 0.28, 0.46 }, cap = { 0.42, 0.30, 0.18 },
                item = { 0.74, 0.62, 0.40 }, arm = 2 },
              { skin = { 0.92, 0.78, 0.64 }, robe = { 0.58, 0.56, 0.72 },
                legs = { 0.34, 0.32, 0.46 }, cap = { 0.70, 0.68, 0.80 },
                item = { 0.80, 0.78, 0.88 }, arm = 4 },
          },
          hero = {
              { skin = { 0.90, 0.80, 0.72 }, robe = { 0.74, 0.74, 0.80 },
                legs = { 0.40, 0.40, 0.46 }, cap = { 0.90, 0.90, 0.92 },
                item = { 0.72, 0.58, 0.34 }, chute = { 0.84, 0.86, 0.94 } },
              { skin = { 0.80, 0.86, 0.94 }, robe = { 0.32, 0.56, 0.80 },
                legs = { 0.22, 0.38, 0.60 }, cap = { 0.44, 0.70, 0.92 },
                crest = { 0.58, 0.82, 0.98 }, chute = { 0.40, 0.70, 0.92 } },
              { skin = { 0.92, 0.82, 0.74 }, robe = { 0.72, 0.26, 0.22 },
                legs = { 0.46, 0.18, 0.16 }, cap = { 0.86, 0.42, 0.22 },
                crest = { 0.90, 0.52, 0.24 }, chute = { 0.86, 0.36, 0.22 } },
          },
          fw = 52, fh = 52, wins = 2,
          tint = { 0.80, 0.70, 0.60 }, rtint = { 0.46, 0.28, 0.60 },
          tex = "marble", texCol = "marble",
          lit = { 1.00, 0.88, 0.58 }, off = { 0.48, 0.20, 0.72 },
          ww = 10, wh = 34, wy = 27,
          wdeco = { { 0, 19, 6, 4, 1.00, { 0.48, 0.20, 0.72 } }, { 0, -19, 12, 2, 1.00, PAL.GOLD } },
          deco = { { 0.5, 8, 1.00, 2, 1.00, PAL.GOLD }, { 0.5, 44, 0.90, 2, 1.00, PAL.GOLD } },
          sign = { 3, { { 0, 24, 1.00, 2, 1.00, PAL.GOLD } } },
          slices = { { 1.00, 10, 0.92 }, { 0.90, 36, 1.00 }, { 1.00, 6, 0.96 } },
          tiers = { "", "spires" },
          vars = {
              spires = {
                  ww = 10, wh = 20, wy = 30,
                  col = { { 8, 30, 8, 1.00, { 0.56, 0.28, 0.82 } }, { 4, 10, 38, 1.00, { 0.86, 0.56, 1.00 } } },
                  wdeco = { { 0, 12, 6, 4, 1.00, { 0.48, 0.20, 0.72 } } },
                  deco = { { 0.5, 8, 1.00, 2, 1.00, PAL.GOLD }, { 0.5, 46, 0.78, 2, 1.00, PAL.GOLD } },
                  slices = { { 1.00, 10, 0.92 }, { 0.78, 36, 1.00 }, { 1.00, 6, 0.96 } } },
              base = {
                  wins = 0,
                  col = { { 10, 40, 6, 1.00, { 0.74, 0.62, 0.84 } } },
                  wdeco = false,
                  deco = { { 0.5, 6, 0.44, 34, 1.00, { 0.20, 0.08, 0.32 } },
                           { 0.5, 40, 0.24, 6, 1.00, { 0.20, 0.08, 0.32 } },
                           { 0.5, 8, 0.14, 30, 1.00, { 0.80, 0.48, 1.00 } } },
                  slices = { { 1.12, 6, 0.88 }, { 1.00, 40, 1.00 }, { 1.00, 6, 0.96 } } },
              cap = {
                  wins = 0, col = false, wdeco = false, deco = false, sign = false,
                  slices = { { 1.00, 4, 1.00, PAL.GOLD }, { 0.60, 6, 1.00, { 0.56, 0.28, 0.80 } },
                             { 0.92, 10, 1.00, { 0.66, 0.34, 0.88 } }, { 0.84, 10, 1.00, { 0.72, 0.38, 0.92 } },
                             { 0.56, 8, 1.00, { 0.78, 0.44, 0.96 } }, { 0.18, 14, 1.00, { 0.90, 0.62, 1.00 } } } },
          } },
        { label = "tower.wowSpireLabel", tip = "tower.wowSpireTip", roof = "citadel",
          chute = { 0.24, 0.28, 0.34 },
          folk = {
              { skin = { 0.58, 0.64, 0.52 }, robe = { 0.28, 0.28, 0.30 },
                legs = { 0.22, 0.22, 0.24 }, arm = 2 },
              { skin = { 0.84, 0.82, 0.74 }, robe = { 0.22, 0.22, 0.26 },
                legs = { 0.20, 0.20, 0.22 }, arm = 2 },
              { skin = { 0.64, 0.72, 0.78 }, robe = { 0.22, 0.28, 0.36 },
                legs = { 0.18, 0.22, 0.28 }, cap = { 0.44, 0.50, 0.56 },
                crest = { 0.68, 0.80, 0.88 }, item = { 0.56, 0.86, 0.94 }, arm = 4 },
              { skin = { 0.72, 0.74, 0.68 }, robe = { 0.28, 0.20, 0.36 },
                legs = { 0.20, 0.16, 0.26 }, cap = { 0.24, 0.18, 0.32 },
                crest = { 0.32, 0.24, 0.42 }, item = { 0.50, 0.40, 0.28 }, arm = 2 },
              { skin = { 0.88, 0.90, 0.94 }, robe = { 0.66, 0.74, 0.84 },
                legs = { 0.50, 0.58, 0.70 }, cap = { 0.86, 0.88, 0.92 },
                crest = { 0.92, 0.96, 1.00 } },
          },
          hero = {
              { skin = { 0.30, 0.34, 0.40 }, robe = { 0.24, 0.26, 0.32 },
                legs = { 0.18, 0.20, 0.24 }, cap = { 0.42, 0.46, 0.52 },
                crest = { 0.64, 0.70, 0.76 }, item = { 0.62, 0.92, 1.00 },
                arm = 4, chute = { 0.30, 0.56, 0.72 } },
              { skin = { 0.92, 0.78, 0.64 }, robe = { 0.80, 0.80, 0.84 },
                legs = { 0.42, 0.42, 0.48 }, cap = { 0.90, 0.90, 0.92 },
                crest = { 0.86, 0.70, 0.32 }, item = { 1.00, 0.88, 0.44 },
                arm = 4, chute = { 0.94, 0.82, 0.40 } },
          },
          fw = 56, fh = 56, wins = 3,
          tint = { 0.22, 0.27, 0.34 }, rtint = { 0.30, 0.36, 0.46 },
          lit = PAL.ICC.LIT, off = PAL.ICC.ICE,
          ww = 6, wh = 24, wy = 26,
          col = { { 7, 30, 10, 1.00, PAL.ICC.RIB },
                  { 2, 30, 10, 1.00, PAL.ICC.EDGE },
                  { 6, 12, 44, 1.00, PAL.ICC.DEEP } },
          wdeco = { { 0, 14, 6, 6, 1.00, PAL.ICC.DEEP },
                    { 0, -13, 8, 2, 1.00, PAL.ICC.GLOW } },
          deco = { { 0.5, 40, 0.76, 2, 1.00, PAL.ICC.GLOW },
                   { 0.5, 12, 0.76, 2, 1.00, PAL.ICC.GLOW },
                   { 0.5, 46, 1.00, 2, 1.00, PAL.ICC.DEEP } },
          sign = { 1, { { -0.44, 8, 0.13, 40, 1.00, PAL.ICC.DEEP },
                        { -0.44, 22, 0.04, 14, 1.00, PAL.ICC.GLOW },
                        { 0.44, 8, 0.13, 40, 1.00, PAL.ICC.DEEP },
                        { 0.44, 22, 0.04, 14, 1.00, PAL.ICC.GLOW } } },
          slices = { { 1.00, 10, 0.96 }, { 0.76, 30, 1.00 },
                     { 0.88, 6, 1.00, PAL.ICC.DEEP }, { 1.00, 10, 0.92 } },
          tiers = { "", "gallery" },
          vars = {
              gallery = {
                  ww = 10, wh = 20, wy = 26,
                  wdeco = { { 0, 12, 10, 4, 1.00, PAL.ICC.DEEP },
                            { 0, -11, 12, 2, 1.00, PAL.ICC.GLOW } } },
              base = {
                  wins = 0, col = false, wdeco = false,
                  deco = { { 0.5, 12, 0.38, 32, 1.00, PAL.ICC.DOOR, tex = false },
                           { 0.5, 12, 0.22, 26, 1.00, PAL.ICC.GLOW, tex = false },
                           { 0.5, 44, 0.86, 4, 1.00, PAL.ICC.EDGE, tex = false } },
                  sign = { 1, { { 0, 46, 0.16, 10, 1.00, PAL.ICC.BONE },
                                { -0.04, 48, 0.04, 4, 1.00, PAL.ICC.GLOW },
                                { 0.04, 48, 0.04, 4, 1.00, PAL.ICC.GLOW },
                                { 0, 42, 0.06, 4, 1.00, PAL.ICC.BONE } } },
                  slices = { { 1.24, 6, 0.92 }, { 1.12, 6, 0.94 },
                             { 1.00, 34, 1.00 }, { 1.00, 10, 0.94 } } },
              cap = {
                  wins = 0, col = false, wdeco = false,
                  deco = { { 0.30, 22, 0.08, 8, 1.00, PAL.ICC.EDGE },
                           { 0.70, 22, 0.08, 8, 1.00, PAL.ICC.EDGE },
                           { 0.5, 34, 0.06, 30, 1.00, PAL.ICC.GLOW } },
                  sign = { 1, { { 0, 62, 0.03, 44, 1.00, PAL.ICC.GLOW } } },
                  slices = { { 1.00, 10, 0.94 }, { 0.66, 12, 1.00 },
                             { 0.44, 6, 1.00, PAL.ICC.EDGE },
                             { 0.26, 28, 1.00, PAL.ICC.DEEP } } },
          } },
    },
}
local SKINS = {
    { key = SKIN_WOW, label = "tower.skinWowLabel" },
    { key = SKIN_ERA, label = "tower.skinEraLabel" },
}
local SKIN_DEF = SKIN_WOW
local function skinKey()
    local k = ns.Store.Skin(ID)
    return LOOKS[k] and k or SKIN_DEF
end
local PERFECT_K = 0.13
local SNAP_K = 0.05
local function makeSet(rule, look, i)
    local T = {}
    for k, v in pairs(rule) do T[k] = v end
    for k, v in pairs(look) do T[k] = v end
    T.idx = i
    T.labelKey = look.label
    T.tipKey = look.tip
    T.near = floor(T.fw / 3)
    T.miss = T.fw
    T.perfect = max(6, floor(T.fw * PERFECT_K))
    T.snap = max(3, floor(T.fw * SNAP_K))
    T.mid = ceil(T.wins / 2)
    T.winX, T.winOff = {}, {}
    local pitch = T.fw / max(1, T.wins)
    for j = 1, T.wins do
        T.winX[j] = (j - 0.5) * pitch
        T.winOff[j] = T.winX[j] - T.fw / 2
    end
    T.pitch = pitch
    local k = min(1, WIN_SHARE * pitch / T.ww)
    if k < 1 then T.ww = floor(T.ww * k) end
    local sum, tall = 0, 1
    for j = 1, #T.slices do
        sum = sum + T.slices[j][2]
        if T.slices[j][2] > T.slices[tall][2] then tall = j end
    end
    local delta = T.fh - sum
    if delta ~= 0 then
        local list = {}
        for j = 1, #T.slices do
            local sl = T.slices[j]
            list[j] = { sl[1], sl[2] + ((j == tall) and delta or 0), sl[3], sl[4], tex = sl.tex }
        end
        T.slices = list
        T.wy = T.wy + delta / 2
    end
    if T.wdeco then
        local list = {}
        for j = 1, #T.wdeco do
            local d = T.wdeco[j]
            list[j] = { d[1] * k, d[2], min(d[3] * k, pitch - 2), d[4], d[5], d[6] }
        end
        T.wdeco = list
    end
    if T.col then
        local src = type(T.col[1]) == "table" and T.col or { T.col }
        local list = {}
        for j = 1, #src do
            local c = src[j]
            local grow = (c[2] >= 20) and delta or 0
            list[j] = { min(c[1], max(2, pitch - T.ww - 2)), c[2] + grow, c[3], c[4], c[5], tex = c.tex }
        end
        T.col = list
    end
    T.name = ""
    T.var = {}
    if look.vars then
        for name, over in pairs(look.vars) do
            local merged = {}
            for k, v in pairs(look) do if k ~= "vars" then merged[k] = v end end
            for k, v in pairs(over) do
                if v == false then merged[k] = nil else merged[k] = v end
            end
            merged.fw, merged.fh = T.fw, T.fh
            local V = makeSet(rule, merged, i)
            V.name = name
            T.var[name] = V
        end
    end
    return T
end
local function varAt(T, i, cap)
    if i == 1 and T.var.base then return T.var.base end
    if cap and i == cap and T.var.cap then return T.var.cap end
    if T.tiers then return T.var[T.tiers[max(0, i - 2) % #T.tiers + 1]] or T end
    return T
end
local SETS = {}
for sk, look in pairs(LOOKS) do
    local set = {}
    for i = 1, #RULES do
        set[i] = makeSet(RULES[i], look[i], i)
    end
    SETS[sk] = set
end
local function nameOf(T) return ns.T(T.labelKey) end
local function tipOf(T) return ns.T(T.tipKey) end
local function types()
    return SETS[skinKey()]
end
local function typeByKey(key)
    local set = types()
    for i = 1, #set do
        if set[i].key == key then return set[i] end
    end
    return nil
end
local LOOK_KEY = "rushLook"
local MODE_CLIMB = "climb"
local MODE_RUSH  = "rush"
local MODES = {
    { key = MODE_CLIMB, label = "tower.modeClimbLabel",
      tip = "tower.modeClimbTip" },
    { key = MODE_RUSH, label = "tower.modeRushLabel",
      tip = "tower.modeRushTip" },
}
local DONE_PREFIX = "done:"
local FORM = {
    MAX_WDECO = 2, MAX_DECO = 3, MAX_COL_PARTS = 3, SIGN_PARTS = 4, CREST_H = 2,
    PIVOT_SY = 900, CABLE_SEGS = 14, YOKE_W = 0.34,
    CRANE_B = 24, CRANE_DIP = 0.6, CRANE_EIGHT = 0.4, CRANE_HOLD = 2, CUT = 0,
    COMBO_TIME = 8, COMBO_CAP = 5, POPS = 5, POP_LIFE = 1.1, POP_RISE = 34,
    TIP_EDGE = 0.75, BAD_OVER = 0.40, BAD_WIN = 9, BAD_BREAK = 3,
    CRACK = 0.55, LOAD = 0.35,
    DEBRIS_V = -60, DEBRIS_SPIN = 40,
    RIDE_V = 420, RIDE_MIN = 1, RIDE_MAX = 4, RIDE_HOLD = 0.9,
    RIDE_RIG = 0.35, RIDE_NEAR = 12,
}
local PACE = {
    TOP_SCREEN_Y = 258, DROP_H = 100, CENTER_X = 320, RAIL_SY = 474,
    GROUND_SY = 26, MENU_SOIL = 72,
    CRANE_A = 110, CRANE_W = 1.75, RUSH_RAMP = 36,
    GRAV = 2200, CAM_EASE = 6, OVER_PAUSE = 0.8, MISS_PAUSE = 0.8, DONE_PAUSE = 1.4,
    LIVES = 4,
}
PACE.CAM_MIN = -PACE.GROUND_SY
local SWAY = {
    W_LO = 3.4, W_HI = 2.7, ALT = 44, WILD = 36, MAX = 70,
    AMP_EASE = 0.8, WIND_W = 0.62, BEND_P = 1.6,
    FLEX_LO = 3, FLEX_HI = 15, STRESS_WOB = 0.6, ALT_FULL = 180,
    WOB_UP = 0.82, WOB_DOWN = 0.012, WOB_RECOV = 4.25, WOB_HGT = 0.011,
}
local BG = {
    SKY_BANDS = 24, SKY_FULL = 2600, STARS = 16,
    SUN_X = 472, SUN_Y = 404,
    SUN_DAY = { 1.00, 0.96, 0.78 },
    MOUNT_BASE  = 118,
    MOUNT_PAR   = 0.03,
    MOUNT_STEPS = 8,
    MOUNT_TINT  = { 0.34, 0.42, 0.62 },
    MOUNT_MIX   = 0.42,
    MOUNT_SNOW  = { 0.56, 0.62, 0.74 },
    MOUNTS = { { 20, 150, 176 }, { 128, 190, 232 }, { 246, 140, 136 },
               { 344, 210, 250 }, { 462, 160, 190 }, { 566, 170, 160 },
               { 660, 150, 206 } },
    DECK_H    = 130,
    DECK_FROM = 320,
    DECK_FULL = 980,
    DECK_A    = 0.62,
    DECK_DAY   = { 0.88, 0.92, 0.98 },
    DECK_NIGHT = { 0.26, 0.30, 0.42 },
    STRATUS   = 3,
    STRATUS_P = 0.45,
    BIRDS   = 6,
    BIRD_V  = 46,
    BIRD_P  = 0.60,
    BIRD_LO = 120,
    BIRD_HI = 1100,
    BIRD_C  = { 0.14, 0.14, 0.18 },
}
local KIND = { FLAT = 0, STEP = 1, DOME = 2, MAST = 3, TANK = 4 }
local CITY = {
    { base = 104, par = 0.07, tint = { 0.34, 0.42, 0.58 }, mix = 0.52, glaz = 0.94,
      b = { { -10, 60, 132, KIND.FLAT, 3 }, {  58, 54,  96, KIND.STEP, 2 },
            { 124, 64, 168, KIND.MAST, 3 }, { 196, 48, 112, KIND.FLAT, 2 },
            { 258, 60, 146, KIND.DOME, 3 }, { 330, 56, 188, KIND.MAST, 2 },
            { 402, 50,  88, KIND.FLAT, 2 }, { 470, 62, 152, KIND.STEP, 3 },
            { 546, 66, 120, KIND.DOME, 3 } } },
    { base = 88, par = 0.13, tint = { 0.26, 0.34, 0.50 }, mix = 0.44, glaz = 0.90,
      b = { { -16, 74, 118, KIND.STEP, 3 }, {  66, 68,  86, KIND.FLAT, 2 },
            { 152, 78, 140, KIND.MAST, 3 }, { 244, 82, 104, KIND.TANK, 3 },
            { 340, 72, 128, KIND.DOME, 3 }, { 434, 76,  92, KIND.FLAT, 2 },
            { 530, 88, 132, KIND.STEP, 4 } } },
    { base = PACE.GROUND_SY, par = 1.00, tint = { 0.15, 0.19, 0.30 }, mix = 0.12, glaz = 0.72,
      b = { { -20, 92,  84, KIND.FLAT, 3 }, {  88, 96, 104, KIND.STEP, 4 },
            { 202, 88,  72, KIND.TANK, 3 }, { 316, 84,  96, KIND.MAST, 3 },
            { 430, 90,  78, KIND.FLAT, 3 }, { 540,100, 110, KIND.DOME, 4 } } },
}
local FOREST = {
    { base = 104, par = 0.07, tint = { 0.36, 0.50, 0.46 }, mix = 0.50, glaz = 0.80,
      trunk = { 0.30, 0.24, 0.18 },
      t = { { -20, 700, 30, hill = true },
            {  10, 28, 40 }, {  58, 24, 34 }, { 104, 32, 46 }, { 156, 26, 38 },
            { 204, 30, 42 }, { 250, 24, 34 }, { 302, 34, 46 }, { 356, 28, 40 },
            { 402, 26, 36 }, { 452, 32, 44 }, { 500, 24, 34 }, { 548, 30, 42 },
            { 600, 28, 38 }, { 646, 32, 44 } } },
    { base = 88, par = 0.13, tint = { 0.24, 0.42, 0.30 }, mix = 0.40, glaz = 0.70,
      trunk = { 0.30, 0.22, 0.14 },
      t = { {  -6, 48, 70 }, {  66, 56, 80 }, { 140, 44, 62 }, { 214, 52, 76 },
            { 286, 46, 66 }, { 360, 56, 82 }, { 436, 48, 70 }, { 510, 54, 78 },
            { 584, 44, 64 }, { 650, 52, 74 } } },
    { base = PACE.GROUND_SY, par = 1.00, tint = { 0.13, 0.30, 0.17 }, mix = 0.12, glaz = 0.55,
      trunk = { 0.26, 0.18, 0.12 },
      t = { {  20, 84, 104 }, { 130, 72, 92 }, { 250, 90, 110 }, { 400, 76, 96 },
            { 520, 92, 108 }, { 630, 70, 90 } } },
}
local SCENES = { [SKIN_ERA] = CITY, [SKIN_WOW] = FOREST }
local NEAR_ROW = #CITY
local TREES = { 4, 142, 260, 380, 496, 560, 612 }
local SITE = {
    post = { 0.30, 0.28, 0.26 }, red = { 0.78, 0.22, 0.18 }, white = { 0.90, 0.88, 0.84 },
    face = { 0.94, 0.92, 0.86 }, ink = { 0.20, 0.18, 0.16 },
    board = { 16, 14, 120, 16 }, fences = { { 150, 250 }, { 390, 490 } }, step = 40, stripe = 8,
}
local TREE_CROWN = { 0.14, 0.26, 0.20 }
local TREE_TRUNK = { 0.14, 0.13, 0.12 }
local HAZE_H   = 90
local HAZE_A   = 0.40
local HAZE_DAY = { 0.58, 0.66, 0.78 }
local CLOUDS  = 4
local CLOUD_P = 0.45
local CLOUD_V = 26
local CLOUD_A = 0.72
local BAL_P   = 0.62
local BAL_V   = 24
local BAL_GAP = 20
local RES_V     = 150
local RES_SWAY  = 9
local RES_FLY   = 10
local RES_ROPE = { 0.22, 0.20, 0.18 }
local RES_ARM_MAX = 4
local RES_FOLK_DEF = {
    { skin = { 0.94, 0.78, 0.62 }, robe = { 0.34, 0.44, 0.62 },
      legs = { 0.26, 0.28, 0.36 }, cap = { 0.36, 0.24, 0.14 } },
    { skin = { 0.92, 0.76, 0.60 }, robe = { 0.62, 0.30, 0.30 },
      legs = { 0.28, 0.26, 0.30 }, cap = { 0.80, 0.66, 0.34 } },
    { skin = { 0.90, 0.74, 0.58 }, robe = { 0.40, 0.50, 0.40 },
      legs = { 0.24, 0.24, 0.28 }, cap = { 0.24, 0.20, 0.16 } },
}
local RES_CHUTE_DEF = { 0.84, 0.42, 0.34 }
local WIN_OFF = { 0.16, 0.15, 0.20 }
local WIN_ON  = { 1.00, 0.86, 0.42 }
local EMPTY_TEX = "Interface\\Buttons\\WHITE8X8"
local ART = {
    LINE = "Interface\\AddOns\\HTP_Arcade\\art\\line.tga",
    ROPE = "Interface\\AddOns\\HTP_Arcade\\art\\rope.tga",
    HOOK = "Interface\\AddOns\\HTP_Arcade\\art\\hook.tga",
    TRUSS_H = "Interface\\AddOns\\HTP_Arcade\\art\\truss_h.tga",
    TRUSS_V = "Interface\\AddOns\\HTP_Arcade\\art\\truss_v.tga",
    BLOCK = "Interface\\AddOns\\HTP_Arcade\\art\\block_%s_%s_%s%s.tga",
    PART = "Interface\\AddOns\\HTP_Arcade\\art\\%s.tga",
    TEX_SIDE = 128, BLOCK_SIDE = 128, HOOK_SIDE = 32, FIT = sqrt(2), TILT_FALL = 6, LINE_FILL = 180 / 256,
}
ART.RIG = {
    MAST_X = 150, MAST_W = 16, JIB_Y = 460, JIB_H = 16, TIP_X = 470, TAIL_X = 100, TILE = 32,
    TROLLEY_W = 22, TROLLEY_H = 8,
    HOOK_UP = 16, HOOK_EYE = 8, HOOK_TOP = 12, SLING = 0.42,
    PAINT    = { 0.93, 0.70, 0.14 },
    STEEL    = { 0.24, 0.24, 0.27 },
    STEEL_HI = { 0.50, 0.50, 0.54 },
    ROPE     = { 0.12, 0.12, 0.14 },
    SLAB     = { 0.62, 0.60, 0.56 },
    GLASS    = { 0.55, 0.76, 0.92 },
    BEACON   = { 1.00, 0.25, 0.15 },
}
local SHADE = { 1.00, 1.00, 1.00, 1.00 }
local SKY_DAY_LO,   SKY_DAY_HI   = { 0.46, 0.58, 0.74 }, { 0.14, 0.28, 0.58 }
local SKY_NIGHT_LO, SKY_NIGHT_HI = { 0.09, 0.12, 0.30 }, { 0.02, 0.03, 0.09 }
local LOOK = ns.MakeLook{ wood = WIN_OFF, edge = PAL.GOLD, screen = SKY_DAY_HI }
local GROUND_DAY, GROUND_NIGHT = { 0.26, 0.23, 0.18 }, { 0.07, 0.06, 0.07 }
local KERB_DAY,   KERB_NIGHT   = { 0.38, 0.44, 0.26 }, { 0.10, 0.12, 0.10 }
local LOCK_TINT  = { 0.46, 0.47, 0.51 }
local IDLE_K     = 0.80
local EDGE_K     = 0.30
local PLOT_SEL   = { 0.36, 0.32, 0.25 }
local PLOT_HOVER = { 0.31, 0.28, 0.22 }
local BASE_SEL   = { 1.00, 0.82, 0.00 }
local BASE_HOVER = { 0.62, 0.52, 0.16 }
local function mix(a, b, t)
    return a + (b - a) * t
end
local mixA, mixB = {}, {}
local function mixTo(out, a, b, t)
    out[1] = mix(a[1], b[1], t)
    out[2] = mix(a[2], b[2], t)
    out[3] = mix(a[3], b[3], t)
    return out
end
local function mix3(a, b, t)
    return a[1] + (b[1] - a[1]) * t,
           a[2] + (b[2] - a[2]) * t,
           a[3] + (b[3] - a[3]) * t
end
local function clamp01(v)
    if v < 0 then return 0 elseif v > 1 then return 1 end
    return v
end
local function unlocked(i)
    if i <= 1 then return true end
    if ns.Dev and ns.Dev.On() then return true end
    return ns.Config.Get(ID, DONE_PREFIX .. types()[i - 1].key, false) and true or false
end
local function topUnlocked()
    local n = 1
    for i = 1, #RULES do
        if unlocked(i) then n = i end
    end
    return n
end
local function rushTypes()
    return types()
end
local function rushLook()
    local i = ns.Config.Get(ID, LOOK_KEY, 0)
    if type(i) ~= "number" or i < 1 or i > #RULES then return topUnlocked() end
    return floor(i)
end
local view, floorPool, resPool
local function cityRects(b, hk)
    local x, w, kind, cols = b[1], b[2], b[4], b[5]
    local h = floor(b[3] * hk)
    local r = {
        { x, 0, w, h, "body" },
        { x, h - 2, w, 2, "trim" },
    }
    local sw = max(2, floor(w / (cols * 2.6)))
    for i = 1, cols do
        r[#r + 1] = { x + w * (i - 0.5) / cols - sw / 2, 4, sw, max(1, h - 11), "glass" }
    end
    if kind == KIND.STEP then
        local sh = floor(h * 0.16)
        r[#r + 1] = { x + w * 0.20, h, w * 0.60, sh, "body" }
        r[#r + 1] = { x + w * 0.20, h + sh - 2, w * 0.60, 2, "trim" }
    elseif kind == KIND.DOME then
        r[#r + 1] = { x + w * 0.26, h, w * 0.48, 8, "body" }
        r[#r + 1] = { x + w * 0.38, h + 8, w * 0.24, 6, "body" }
    elseif kind == KIND.MAST then
        r[#r + 1] = { x + w * 0.42, h, w * 0.16, 6, "body" }
        r[#r + 1] = { x + w * 0.50 - 1, h, 2, 22, "trim" }
    elseif kind == KIND.TANK then
        r[#r + 1] = { x + w * 0.56, h + 4, w * 0.28, 9, "body" }
        r[#r + 1] = { x + w * 0.60, h, 2, 4, "body" }
        r[#r + 1] = { x + w * 0.78, h, 2, 4, "body" }
    end
    return r
end
local function oakRects(t, hk)
    local x, w = t[1], t[2]
    local h = floor(t[3] * hk)
    if t.hill then return { { x, 0, w, h, "body" } } end
    return {
        { x - w * 0.07, 0,        w * 0.14, h * 0.40, "glass" },
        { x - w * 0.50, h * 0.30, w,        h * 0.34, "body" },
        { x - w * 0.36, h * 0.58, w * 0.72, h * 0.26, "body" },
        { x - w * 0.20, h * 0.80, w * 0.40, h * 0.20, "body" },
        { x - w * 0.30, h * 0.64, w * 0.22, h * 0.10, "trim" },
    }
end
local function rowRects(row, item, hk)
    if row.t then return oakRects(item, hk) end
    return cityRects(item, hk)
end
local function placeClipped(tex, host, x, y, w, h, W, H)
    local x0, y0 = x, y
    local x1, y1 = x + w, y + h
    if x0 < 0 then x0 = 0 end
    if y0 < 0 then y0 = 0 end
    if x1 > W then x1 = W end
    if y1 > H then y1 = H end
    if x1 - x0 < 1 or y1 - y0 < 1 then
        tex:Hide()
        return
    end
    tex:SetWidth(x1 - x0)
    tex:SetHeight(y1 - y0)
    tex:ClearAllPoints()
    tex:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", x0, y0)
    tex:Show()
end
local function mountRects(m)
    local cx, w, h = m[1], m[2], m[3]
    local r = {}
    local sh = h / BG.MOUNT_STEPS
    for j = 0, BG.MOUNT_STEPS - 1 do
        local sw = w * (1 - j / BG.MOUNT_STEPS) ^ 1.5
        r[#r + 1] = { cx - sw / 2, j * sh, sw, sh + 1,
                      (j >= BG.MOUNT_STEPS - 2) and "snow" or "rock" }
    end
    return r
end
local function treeRects(x)
    return {
        { x - 1,   0,  3,  8, "trunk" },
        { x - 6,   8, 12,  9, "crown" },
        { x - 3.5, 16, 7,  4, "crown" },
    }
end
local function siteRects()
    local r = {}
    local function add(x, y, w, h, c) r[#r + 1] = { x = x, y = y, w = w, h = h, c = c } end
    local b = SITE.board
    add(b[1] + 8, 0, 3, b[2], SITE.post)
    add(b[1] + b[3] - 11, 0, 3, b[2], SITE.post)
    add(b[1], b[2], b[3], b[4], SITE.face)
    for _, f in ipairs(SITE.fences) do
        local x = f[1]
        while x <= f[2] do
            add(x, 0, 3, 14, SITE.post)
            x = x + SITE.step
        end
        local k = 0
        for sx = f[1] + 3, f[2] - SITE.stripe, SITE.stripe do
            add(sx, 5, SITE.stripe, 6, (k % 2 == 0) and SITE.red or SITE.white)
            k = k + 1
        end
    end
    return r
end
local function floorParts(host)
    local p = { slice = {}, deco = {}, win = {}, col = {}, wdeco = {}, sign = {} }
    for i = 1, FORM.SIGN_PARTS do p.sign[i] = ns.Fill(host, "OVERLAY", 0.5, 0.5, 0.5) end
    p.crest = ns.Fill(host, "OVERLAY", PAL.GOLD[1], PAL.GOLD[2], PAL.GOLD[3])
    for i = 1, MAX_SLICES do p.slice[i] = ns.Fill(host, "BACKGROUND", 0.55, 0.47, 0.38) end
    for i = 1, FORM.MAX_DECO   do p.deco[i]  = ns.Fill(host, "BORDER", 0.5, 0.5, 0.5) end
    for i = 1, MAX_WINS   do p.win[i]   = ns.Fill(host, "ARTWORK", WIN_OFF[1], WIN_OFF[2], WIN_OFF[3]) end
    for i = 1, MAX_COLS * FORM.MAX_COL_PARTS do p.col[i] = ns.Fill(host, "OVERLAY", 0.5, 0.5, 0.5) end
    for i = 1, MAX_WINS * FORM.MAX_WDECO do p.wdeco[i] = ns.Fill(host, "OVERLAY", 0.5, 0.5, 0.5) end
    return p
end
local function placeRect(t, host, x, y, w, h)
    if w < 1 then w = 1 end
    if h < 1 then h = 1 end
    if FORM.CUT > 0 and y < FORM.CUT then
        h = h - (FORM.CUT - y)
        y = FORM.CUT
        if h < 1 then h = 1 end
    end
    t:SetWidth(w)
    t:SetHeight(h)
    t:ClearAllPoints()
    t:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", x, y)
    t:Show()
end
local function partTex(entry, default)
    if entry.tex == nil then return default end
    return entry.tex or nil
end
local function texPart(t, tex, w, h, seed)
    if not tex then return end
    t:SetTexture(format(ART.PART, tex))
    local cw, ch = min(ART.TEX_SIDE, ceil(w)), min(ART.TEX_SIDE, ceil(h))
    local x0 = (seed * 37) % max(1, ART.TEX_SIDE - cw + 1)
    local y0 = (seed * 53) % max(1, ART.TEX_SIDE - ch + 1)
    t:SetTexCoord(x0 / ART.TEX_SIDE, (x0 + cw) / ART.TEX_SIDE, y0 / ART.TEX_SIDE, (y0 + ch) / ART.TEX_SIDE)
end
local function layFloor(p, T, host, x0, y0, sc, skew)
    local fw = T.fw
    skew = skew or 0
    local mid = T.fh / 2
    local function lean(cy) return skew * (cy - mid) * sc end
    local y = 0
    for i = 1, MAX_SLICES do
        local t, sl = p.slice[i], T.slices[i]
        if sl then
            local w = fw * sl[1]
            placeRect(t, host, x0 + (fw - w) / 2 * sc + lean(y + sl[2] / 2),
                      y0 + y * sc, w * sc, sl[2] * sc)
            texPart(t, partTex(sl, T.tex), w, sl[2], i)
            y = y + sl[2]
        else
            t:Hide()
        end
    end
    for i = 1, FORM.MAX_DECO do
        local t, d = p.deco[i], T.deco and T.deco[i]
        if d then
            local w = fw * d[3]
            placeRect(t, host, x0 + (fw * d[1] - w / 2) * sc + lean(d[2] + d[4] / 2),
                      y0 + d[2] * sc, w * sc, d[4] * sc)
            texPart(t, partTex(d, T.texDeco), w, d[4], 10 + i)
        else
            t:Hide()
        end
    end
    for i = 1, MAX_WINS do
        local w = p.win[i]
        if i <= T.wins then
            placeRect(w, host, x0 + (T.winX[i] - T.ww / 2) * sc + lean(T.wy),
                      y0 + (T.wy - T.wh / 2) * sc, T.ww * sc, T.wh * sc)
        else
            w:Hide()
        end
    end
    for i = 1, MAX_COLS do
        for j = 1, FORM.MAX_COL_PARTS do
            local c = p.col[(i - 1) * FORM.MAX_COL_PARTS + j]
            local d = T.col and T.col[j]
            if d and i <= T.wins + 1 then
                local px = (i - 1) * T.pitch
                local xa, xb = max(0, px - d[1] / 2), min(fw, px + d[1] / 2)
                placeRect(c, host, x0 + xa * sc + lean(d[3] + d[2] / 2), y0 + d[3] * sc,
                          (xb - xa) * sc, d[2] * sc)
                texPart(c, partTex(d, T.texCol), xb - xa, d[2], 20 + i * 3 + j)
            else
                c:Hide()
            end
        end
    end
    for i = 1, MAX_WINS do
        for j = 1, FORM.MAX_WDECO do
            local t = p.wdeco[(i - 1) * FORM.MAX_WDECO + j]
            local d = T.wdeco and T.wdeco[j]
            if d and i <= T.wins then
                placeRect(t, host, x0 + (T.winX[i] + d[1] - d[3] / 2) * sc + lean(T.wy + d[2]),
                          y0 + (T.wy + d[2] - d[4] / 2) * sc, d[3] * sc, d[4] * sc)
            else
                t:Hide()
            end
        end
    end
    for i = 1, FORM.SIGN_PARTS do
        local t = p.sign[i]
        local d = T.sign and T.sign[2][i]
        if d then
            local sw = (d[3] <= 1.5) and (fw * d[3]) or min(d[3], fw)
            local sx = (abs(d[1]) <= 1.5) and (fw * d[1]) or d[1]
            placeRect(t, host, x0 + (fw / 2 + sx - sw / 2) * sc + lean(d[2] + d[4] / 2),
                      y0 + d[2] * sc, sw * sc, d[4] * sc)
        end
        t:Hide()
    end
    placeRect(p.crest, host, x0 + lean(T.fh), y0 + (T.fh - FORM.CREST_H) * sc,
              fw * sc, FORM.CREST_H * sc)
    p.crest:Hide()
end
local function line(t, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local len = sqrt(dx * dx + dy * dy)
    if len < 1 then t:Hide() return end
    local side = len / ART.LINE_FILL * ART.FIT
    t:SetWidth(side)
    t:SetHeight(side)
    t:ClearAllPoints()
    t:SetPoint("CENTER", t:GetParent(), "BOTTOMLEFT", (x1 + x2) / 2, (y1 + y2) / 2)
    t:SetRotation(atan2(-dx, dy))
    t:Show()
end
local function crestFloor(p, on)
    if on then p.crest:Show() else p.crest:Hide() end
end
local function signFloor(p, T, idx)
    local on = T.sign and (idx % T.sign[1] == 0)
    for i = 1, FORM.SIGN_PARTS do
        if on and T.sign[2][i] then p.sign[i]:Show() else p.sign[i]:Hide() end
    end
end
local function partTone(T, k, ek, c)
    if c then return c, k end
    return T.tint, k * ek
end
local function plainTone(c, kk)
    return min(1, c[1] * kk), min(1, c[2] * kk), min(1, c[3] * kk)
end
local function paintPart(t, tex, r, g, b)
    if tex then
        t:SetVertexColor(r, g, b)
    else
        t:SetTexture(r, g, b, 1)
        t:SetVertexColor(1, 1, 1)
    end
end
local function tintFloor(p, T, k, tone)
    for i = 1, MAX_SLICES do
        local sl = T.slices[i]
        if sl then
            local c, kk = partTone(T, k, sl[3], sl[4])
            paintPart(p.slice[i], partTex(sl, T.tex), tone(c, kk))
        end
    end
    for i = 1, FORM.MAX_DECO do
        local d = T.deco and T.deco[i]
        if d then
            local c, kk = partTone(T, k, d[5], d[6])
            paintPart(p.deco[i], partTex(d, T.texDeco), tone(c, kk))
        end
    end
    if T.col then
        for j = 1, FORM.MAX_COL_PARTS do
            local d = T.col[j]
            if d then
                local c, kk = partTone(T, k, d[4], d[5])
                local r, g, b = tone(c, kk)
                for i = 1, T.wins + 1 do
                    paintPart(p.col[(i - 1) * FORM.MAX_COL_PARTS + j], partTex(d, T.texCol), r, g, b)
                end
            end
        end
    end
    if T.wdeco then
        for j = 1, FORM.MAX_WDECO do
            local d = T.wdeco[j]
            if d then
                local c, kk = partTone(T, k, d[5], d[6])
                local r, g, b = tone(c, kk)
                for i = 1, T.wins do
                    p.wdeco[(i - 1) * FORM.MAX_WDECO + j]:SetTexture(r, g, b, 1)
                end
            end
        end
    end
    if T.sign then
        for i = 1, FORM.SIGN_PARTS do
            local d = T.sign[2][i]
            if d then
                local c, kk = partTone(T, k, d[5], d[6])
                p.sign[i]:SetTexture(tone(c, kk))
            end
        end
    end
end
local function floorFrame(canvas)
    local f = ns.PlainFrame(canvas, 4)
    f:Hide()
    for k, v in pairs(floorParts(f)) do f[k] = v end
    f.badge = f:CreateTexture(nil, "OVERLAY")
    f.badge:SetWidth(28)
    f.badge:SetHeight(28)
    f.badge:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.badge:Hide()
    return f
end
local function shapeFloor(f, T, skew)
    f:SetWidth(T.fw)
    f:SetHeight(T.fh)
    layFloor(f, T, f, 0, 0, 1, skew)
end
local function paintFloor(f, T, k)
    tintFloor(f, T, k, plainTone)
end
local function resFrame(canvas)
    local f = ns.PlainFrame(canvas, 7)
    f:Hide()
    f:SetWidth(24)
    f:SetHeight(34)
    local function part(layer, w, h, x, y, c)
        local t = ns.Fill(f, layer, c[1], c[2], c[3])
        t:SetWidth(w); t:SetHeight(h)
        t:SetPoint("TOP", f, "TOP", x, -y)
        return t
    end
    f.crown = part("BACKGROUND", 10, 3, 0, 0, RES_CHUTE_DEF)
    f.dome  = part("BACKGROUND", 18, 4, 0, 3, RES_CHUTE_DEF)
    f.rim   = part("BACKGROUND", 24, 3, 0, 7, RES_CHUTE_DEF)
    f.ropeL = part("BORDER", 1, 6, -7, 10, RES_ROPE)
    f.ropeR = part("BORDER", 1, 6,  7, 10, RES_ROPE)
    local DEF = RES_FOLK_DEF[1]
    f.head  = part("ARTWORK", 5, 5,  0, 16, DEF.skin)
    f.armL  = part("ARTWORK", 3, 8, -7, 16, DEF.skin)
    f.armR  = part("ARTWORK", 3, 8,  7, 16, DEF.skin)
    f.torso = part("ARTWORK", 9, 7,  0, 21, DEF.robe)
    f.legL  = part("ARTWORK", 3, 6, -2, 28, DEF.legs)
    f.legR  = part("ARTWORK", 3, 6,  2, 28, DEF.legs)
    f.cap   = part("ARTWORK", 7, 3,  0, 13, DEF.cap)
    f.crest = part("ARTWORK", 5, 3,  0, 10, DEF.cap)
    f.tuskL = part("ARTWORK", 1, 2, -3, 19, DEF.skin)
    f.tuskR = part("ARTWORK", 1, 2,  3, 19, DEF.skin)
    f.item  = part("ARTWORK", 2, 14, 10, 14, DEF.robe)
    f.man = { f.head, f.armL, f.armR, f.torso, f.legL, f.legR,
              f.cap, f.crest, f.tuskL, f.tuskR, f.item }
    f.extra = { f.cap, f.crest, f.tuskL, f.tuskR, f.item }
    for i = 1, #f.extra do f.extra[i]:Hide() end
    f.badge = f:CreateTexture(nil, "ARTWORK")
    f.badge:SetWidth(18); f.badge:SetHeight(18)
    f.badge:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    f.badge:Hide()
    return f
end
local function setPart(t, c)
    if c then
        t:SetTexture(c[1], c[2], c[3])
        t:Show()
    else
        t:Hide()
    end
end
local function dress(f, F, chute)
    local c = F.chute or chute
    f.crown:SetTexture(min(1, c[1] * 1.10), min(1, c[2] * 1.10), min(1, c[3] * 1.10))
    f.dome:SetTexture(c[1], c[2], c[3])
    f.rim:SetTexture(c[1] * 0.84, c[2] * 0.84, c[3] * 0.84)
    local sk, rb, lg = F.skin, F.robe, F.legs
    f.head:SetTexture(sk[1], sk[2], sk[3])
    f.armL:SetTexture(sk[1], sk[2], sk[3])
    f.armR:SetTexture(sk[1], sk[2], sk[3])
    f.torso:SetTexture(rb[1], rb[2], rb[3])
    f.legL:SetTexture(lg[1], lg[2], lg[3])
    f.legR:SetTexture(lg[1], lg[2], lg[3])
    local aw = min(RES_ARM_MAX, F.arm or 3)
    f.armL:SetWidth(aw)
    f.armR:SetWidth(aw)
    for i = 1, #f.man do f.man[i]:Show() end
    setPart(f.cap,   F.cap)
    setPart(f.crest, F.crest)
    setPart(f.tuskL, F.tusk)
    setPart(f.tuskR, F.tusk)
    setPart(f.item,  F.item)
end
local ROOF_PARTS = 10
local function roofFrame(canvas)
    local f = ns.PlainFrame(canvas, 4)
    f:Hide()
    f.part = {}
    for i = 1, ROOF_PARTS do
        f.part[i] = ns.Fill(f, "ARTWORK", 0.5, 0.5, 0.5)
    end
    return f
end
local ROOF_SHAPE = {
    pediment = { { 1.16, 5, 0, 0 }, { 1.02, 5, 0, 5 }, { 0.76, 5, 0, 10 },
                 { 0.50, 5, 0, 15 }, { 0.24, 5, 0, 20 }, { 0.08, 4, 0, 25 } },
    merlons  = { { 1.10, 6, 0, 0 }, { 0.14, 9, -0.36, 6 }, { 0.14, 9, -0.12, 6 },
                 { 0.14, 9, 0.12, 6 }, { 0.14, 9, 0.36, 6 }, { 0.04, 14, 0, 6 } },
    ziggurat = { { 1.04, 4, 0, 0, 1.08 }, { 0.80, 8, 0, 4, 1.00 }, { 0.60, 9, 0, 12, 1.05 },
                 { 0.42, 11, 0, 21, 0.98 }, { 0.22, 14, 0, 32, 1.03 }, { 0.04, 28, 0, 46, 0.58 } },
    needle   = { { 1.00, 3, 0, 0, 1.10 }, { 0.96, 3, 0, 3, 1.00 }, { 0.86, 2, 0, 6, 0.92 },
                 { 0.66, 2, 0, 8, 0.84 }, { 0.16, 4, 0.22, 10, 0.70 }, { 0.025, 20, 0, 10, 1.30 } },
    orc      = { { 1.16, 6, 0, 0 }, { 0.88, 5, 0, 6 }, { 0.07, 10, -0.46, 3 },
                 { 0.07, 10, 0.46, 3 }, { 0.13, 11, 0, 11 }, { 0.30, 4, 0, 20 } },
    keep     = { { 1.14, 4, 0, 0 }, { 0.92, 8, 0, 4 }, { 0.70, 8, 0, 12 },
                 { 0.48, 8, 0, 20 }, { 0.26, 8, 0, 28 }, { 0.06, 12, 0, 36 } },
    arcane   = { { 0.88, 5, 0, 0 }, { 0.70, 4, 0, 5, true }, { 0.78, 9, 0, 9 },
                 { 0.64, 10, 0, 18 }, { 0.42, 11, 0, 28 }, { 0.14, 15, 0, 39 } },
    citadel  = { { 1.14, 5, 0, 0, 0.52 }, { 0.86, 4, 0, 5, 0.64 },
                 { 0.62, 4, 0, 9, 0.76 }, { 0.44, 5, 0, 13, 0.88 },
                 { 0.30, 6, 0, 18, 0.44 },
                 { 0.10, 26, -0.20, 13, 0.40 }, { 0.10, 26, 0.20, 13, 0.40 },
                 { 0.07, 30, 0, 24, 0.34 },
                 { 0.04, 22, 0, 40, 1.00, PAL.ICC.GLOW },
                 { 0.02, 26, 0, 60, 1.00, PAL.ICC.GLOW } },
}
local function roofHeight(T)
    local shape, h = ROOF_SHAPE[T.roof], 0
    for i = 1, #shape do
        local top = shape[i][4] + shape[i][2]
        if top > h then h = top end
    end
    return h
end
local function shapeRoof(T)
    local f = view.roof
    local shape = ROOF_SHAPE[T.roof]
    local c = T.rtint or T.tint
    f:SetWidth(T.fw * 1.2)
    for i = 1, ROOF_PARTS do
        local p = shape[i]
        local t = f.part[i]
        if p then
            t:SetWidth(T.fw * p[1])
            t:SetHeight(p[2])
            t:ClearAllPoints()
            t:SetPoint("BOTTOM", f, "BOTTOM", T.fw * p[3], p[4])
            if p[5] == true then
                t:SetTexture(PAL.GOLD[1], PAL.GOLD[2], PAL.GOLD[3], 1)
            elseif p[6] then
                t:SetTexture(p[6][1], p[6][2], p[6][3], 1)
            else
                local k = p[5] or (1.15 - 0.06 * i)
                t:SetTexture(min(1, c[1] * k), min(1, c[2] * k), min(1, c[3] * k), 1)
            end
            t:Show()
        else
            t:Hide()
        end
    end
    local h = roofHeight(T)
    f:SetHeight(h)
    return h
end
local MENU_SLOTS  = #RULES + 1
local MENU_COL_W  = 640 / MENU_SLOTS
local MENU_SCALE  = 0.90
local MENU_FLOORS = { 1, 2, 3, 4 }
local MENU_RUSH_FLOORS = 5
local MENU_NAME_Y = 50
local MENU_REC_Y  = 30
local PLAY_W, PLAY_H = 170, 36
local PLAY_CY     = 442
local SKINB_W, SKINB_H = 84, 24
local SKINB_GAP   = 8
local SKINB_CY    = 404
local MENU_COL, MENU_X = {}, {}
do
    for i = 1, MENU_SLOTS do
        MENU_COL[i] = MENU_COL_W
        MENU_X[i] = (i - 0.5) * MENU_COL_W
    end
end
local function miniHouse(root, n)
    local h = ns.PlainFrame(root, 1)
    h:Hide()
    h.floor = {}
    for i = 1, n + 1 do
        h.floor[i] = floorParts(h)
    end
    h.roof = {}
    for i = 1, ROOF_PARTS do h.roof[i] = ns.Fill(h, "BORDER", 0.5, 0.5, 0.5) end
    return h
end
local function drawMini(h, T, n, mode, withCap)
    local sc = MENU_SCALE
    local locked = (mode == "locked")
    local cap = (withCap and T.var.cap) and (n + 1) or nil
    local total = cap or n
    local function tone(c, k)
        if locked then c = LOCK_TINT end
        if mode == "idle" then k = k * IDLE_K end
        return min(1, c[1] * k), min(1, c[2] * k), min(1, c[3] * k)
    end
    local function hideParts(f)
        for _, set in pairs(f) do
            for q = 1, #set do set[q]:Hide() end
        end
    end
    for i = 1, #h.floor do
        local f = h.floor[i]
        if i <= total then
            local V = varAt(T, i, cap)
            local k = SHADE[(i - 1) % #SHADE + 1]
            layFloor(f, V, h, 0, (i - 1) * T.fh * sc, sc)
            tintFloor(f, V, k, tone)
            signFloor(f, V, i)
            local litC = V.lit or WIN_ON
            for q = 1, V.wins do
                local t = f.win[q]
                if locked then
                    t:SetTexture(LOCK_TINT[1] * 0.42, LOCK_TINT[2] * 0.42,
                                 LOCK_TINT[3] * 0.42, 1)
                elseif mode == "sel" then
                    t:SetTexture(litC[1], litC[2], litC[3], 1)
                else
                    local off = V.off or WIN_OFF
                    t:SetTexture(off[1], off[2], off[3], 1)
                end
            end
        else
            hideParts(f)
        end
    end
    local body = total * T.fh
    local shape = ROOF_SHAPE[T.roof]
    local rc = T.rtint or T.tint
    local roofH = cap and 0 or roofHeight(T)
    for i = 1, ROOF_PARTS do
        local t, sp = h.roof[i], shape[i]
        if sp and not cap then
            t:SetWidth(T.fw * sp[1] * sc)
            t:SetHeight(sp[2] * sc)
            t:ClearAllPoints()
            t:SetPoint("BOTTOM", h, "BOTTOMLEFT",
                       (T.fw / 2 + T.fw * sp[3]) * sc, (body + sp[4]) * sc)
            if sp[5] == true then
                t:SetTexture(tone(PAL.GOLD, 1))
            elseif sp[6] then
                t:SetTexture(tone(sp[6], 1))
            else
                t:SetTexture(tone(rc, sp[5] or (1.15 - 0.06 * i)))
            end
            t:Show()
        else
            t:Hide()
        end
    end
    h:SetWidth(T.fw * sc)
    h:SetHeight((body + roofH) * sc)
    h:Show()
    return (body + roofH) * sc
end
local function buildMenu(canvas)
    local m = { hover = nil }
    m.root = ns.PlainFrame(canvas, 8)
    m.root:Hide()
    m.root:SetAllPoints(canvas)
    m.slot = {}
    for i = 1, MENU_SLOTS do
        local cx, col = MENU_X[i], MENU_COL[i] - 4
        local plot = ns.Fill(m.root, "BACKGROUND", 0.36, 0.32, 0.25)
        plot:SetWidth(col)
        plot:SetHeight(PACE.MENU_SOIL)
        plot:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", cx - col / 2, 0)
        plot:Hide()
        local base = ns.Fill(m.root, "BORDER", 1, 0.82, 0)
        base:SetWidth(col)
        base:SetHeight(3)
        base:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", cx - col / 2, PACE.MENU_SOIL - 3)
        base:Hide()
        local mini = miniHouse(m.root, (i <= #RULES) and MENU_FLOORS[i] or MENU_RUSH_FLOORS)
        mini:SetPoint("BOTTOM", m.root, "BOTTOMLEFT", cx, PACE.MENU_SOIL)
        local name = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("CENTER", m.root, "BOTTOMLEFT", cx, MENU_NAME_Y)
        local rec = m.root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        rec:SetPoint("CENTER", m.root, "BOTTOMLEFT", cx, MENU_REC_Y)
        local hgt = m.root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        hgt:SetPoint("CENTER", m.root, "BOTTOMLEFT", cx, MENU_REC_Y - 15)
        local hit = CreateFrame("Button", nil, m.root)
        hit:SetFrameLevel(m.root:GetFrameLevel() + 2)
        hit:SetWidth(col)
        hit:SetHeight(300)
        hit:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", cx - col / 2, 0)
        hit:SetScript("OnEnter", function(self)
            ns.TipShow(self)
            if self.onHover then self.onHover(true) end
        end)
        hit:SetScript("OnLeave", function(self)
            ns.TipHide()
            if self.onHover then self.onHover(false) end
        end)
        hit:SetScript("OnClick", function(self)
            if self.locked then return end
            if self.onPick then ns.Sfx.Ui(); self.onPick() end
        end)
        m.slot[i] = { cx = cx, plot = plot, base = base, mini = mini,
                      name = name, rec = rec, hgt = hgt, hit = hit }
    end
    m.playBg = ns.Fill(m.root, "ARTWORK", 0.035, 0.035, 0.043)
    m.playBg:SetWidth(PLAY_W)
    m.playBg:SetHeight(PLAY_H)
    m.playBg:SetPoint("CENTER", m.root, "BOTTOMLEFT", 320, PLAY_CY)
    m.play = ns.MakeKitButton(m.root)
    m.play:SetFrameLevel(m.root:GetFrameLevel() + 3)
    m.play:SetWidth(PLAY_W)
    m.play:SetHeight(PLAY_H)
    m.play:SetPoint("CENTER", m.root, "BOTTOMLEFT", 320, PLAY_CY)
    m.play:SetText(ns.T("tower.menuPlay"))
    m.skin = {}
    local total = #SKINS * SKINB_W + (#SKINS - 1) * SKINB_GAP
    for i = 1, #SKINS do
        local b = ns.MakeKitButton(m.root)
        b:SetFrameLevel(m.root:GetFrameLevel() + 3)
        b:SetWidth(SKINB_W)
        b:SetHeight(SKINB_H)
        b:SetPoint("CENTER", m.root, "BOTTOMLEFT",
                   320 - total / 2 + (i - 0.5) * SKINB_W + (i - 1) * SKINB_GAP, SKINB_CY)
        b:SetText(ns.T(SKINS[i].label))
        m.skin[i] = b
    end
    m.root:Hide()
    return m
end
local function ensureView(canvas)
    if view then return end
    view = {}
    local W, H = canvas.W or 640, canvas.H or 480
    view.sky = ns.PlainFrame(canvas, 1)
    view.sky:Hide()
    view.sky:SetAllPoints(canvas)
    view.band = {}
    local bh = H / BG.SKY_BANDS
    for i = 1, BG.SKY_BANDS do
        local t = ns.Fill(view.sky, "BACKGROUND", 0.3, 0.5, 0.8)
        t:SetPoint("BOTTOMLEFT", view.sky, "BOTTOMLEFT", 0, (i - 1) * bh)
        t:SetPoint("BOTTOMRIGHT", view.sky, "BOTTOMRIGHT", 0, (i - 1) * bh)
        t:SetHeight(bh + 1)
        view.band[i] = t
    end
    view.sun = {}
    local function sunPart(w, h)
        local t = ns.Fill(view.sky, "BORDER", BG.SUN_DAY[1], BG.SUN_DAY[2], BG.SUN_DAY[3])
        t:SetWidth(w); t:SetHeight(h)
        t:SetPoint("CENTER", view.sky, "BOTTOMLEFT", BG.SUN_X, BG.SUN_Y)
        view.sun[#view.sun + 1] = t
    end
    sunPart(22, 12)
    sunPart(12, 22)
    sunPart(18, 18)
    view.mount = {}
    for i = 1, #BG.MOUNTS do
        local rects = mountRects(BG.MOUNTS[i])
        for k = 1, #rects do
            local rc = rects[k]
            view.mount[#view.mount + 1] = {
                tex = ns.Fill(view.sky, "BORDER", 0.5, 0.6, 0.75),
                x = rc[1], y = rc[2], w = rc[3], h = rc[4], tone = rc[5],
            }
        end
    end
    view.haze = view.sky:CreateTexture(nil, "ARTWORK")
    view.haze:SetTexture(EMPTY_TEX)
    view.haze:SetWidth(W)
    view.haze:SetHeight(HAZE_H)
    view.star = {}
    local srng = ns.RNG.New(4242)
    for i = 1, BG.STARS do
        local s = ns.Fill(view.sky, "ARTWORK", 1, 1, 1)
        local sz = srng:Int(2, 3)
        s:SetWidth(sz); s:SetHeight(sz)
        s:SetPoint("BOTTOMLEFT", view.sky, "BOTTOMLEFT",
                   srng:Int(10, W - 10), srng:Int(floor(H * 0.35), H - 12))
        s:SetAlpha(0)
        view.star[i] = s
    end
    view.cloud = {}
    for i = 1, CLOUDS do
        view.cloud[i] = {
            ns.Fill(view.sky, "OVERLAY", 0.97, 0.98, 1.00),
            ns.Fill(view.sky, "OVERLAY", 0.97, 0.98, 1.00),
            ns.Fill(view.sky, "OVERLAY", 0.97, 0.98, 1.00),
        }
    end
    view.cityFar = ns.PlainFrame(canvas, 2)
    view.cityFar:Hide()
    view.cityFar:SetAllPoints(canvas)
    view.cityNear = ns.PlainFrame(canvas, 3)
    view.cityNear:Hide()
    view.cityNear:SetAllPoints(canvas)
    local LAYERS = {
        { view.cityFar,  "BACKGROUND", "BORDER"  },
        { view.cityFar,  "ARTWORK",    "OVERLAY" },
        { view.cityNear, "BACKGROUND", "BORDER"  },
    }
    view.scene = {}
    for sk, set in pairs(SCENES) do
        view.scene[sk] = {}
        for ri = 1, #set do
            local host, layBody, layTrim = LAYERS[ri][1], LAYERS[ri][2], LAYERS[ri][3]
            local parts = { host = host }
            local row = set[ri]
            local items = row.b or row.t
            for bi = 1, #items do
                local rects = rowRects(row, items[bi], 1)
                for k = 1, #rects do
                    local t = ns.Fill(host, rects[k][5] == "body" and layBody or layTrim,
                                      0.3, 0.4, 0.5)
                    t:Hide()
                    parts[#parts + 1] = { tex = t, tone = rects[k][5] }
                end
            end
            view.scene[sk][ri] = parts
        end
    end
    view.sceneKey = nil
    view.rowFloor = {}
    for ri = 1, NEAR_ROW - 1 do
        local t = ns.Fill(LAYERS[ri][1], LAYERS[ri][3], 0.2, 0.3, 0.4)
        t:SetPoint("BOTTOMLEFT", LAYERS[ri][1], "BOTTOMLEFT", 0, 0)
        t:SetWidth(canvas.W or 640)
        t:Hide()
        view.rowFloor[ri] = t
    end
    view.tree = {}
    for i = 1, #TREES do
        local rects = treeRects(TREES[i])
        for k = 1, #rects do
            local rc = rects[k]
            view.tree[#view.tree + 1] = {
                tex = ns.Fill(view.cityNear, "ARTWORK", 0.2, 0.35, 0.28),
                x = rc[1], y = rc[2], w = rc[3], h = rc[4], tone = rc[5],
            }
        end
    end
    view.site = {}
    for _, rc in ipairs(siteRects()) do
        rc.tex = ns.Fill(view.cityNear, "ARTWORK", rc.c[1], rc.c[2], rc.c[3])
        view.site[#view.site + 1] = rc
    end
    view.siteText = view.cityNear:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.siteText:SetTextColor(SITE.ink[1], SITE.ink[2], SITE.ink[3])
    view.siteText:SetShadowOffset(0, 0)
    view.siteText:SetText(ns.T("tower.siteSign", (tonumber(date("%Y")) or 2026) + 1))
    view.bal = {}
    local function balPart(w, h, dy, r, g, b)
        local t = ns.Fill(view.cityNear, "OVERLAY", r, g, b)
        t:SetWidth(w); t:SetHeight(h)
        view.bal[#view.bal + 1] = { tex = t, w = w, h = h, dy = dy }
        return t
    end
    balPart(18, 6,   0, 0.86, 0.44, 0.32)
    balPart(28, 16, -6, 0.90, 0.52, 0.30)
    balPart(14, 6, -22, 0.80, 0.38, 0.28)
    balPart(2,  6, -28, 0.25, 0.20, 0.16)
    balPart(10, 8, -34, 0.46, 0.32, 0.18)
    view.bird = {}
    for i = 1, BG.BIRDS do
        view.bird[i] = {
            ns.Fill(view.cityNear, "OVERLAY", BG.BIRD_C[1], BG.BIRD_C[2], BG.BIRD_C[3]),
            ns.Fill(view.cityNear, "OVERLAY", BG.BIRD_C[1], BG.BIRD_C[2], BG.BIRD_C[3]),
            ns.Fill(view.cityNear, "OVERLAY", BG.BIRD_C[1], BG.BIRD_C[2], BG.BIRD_C[3]),
        }
    end
    view.ground = ns.Fill(view.cityNear, "BACKGROUND", 0.26, 0.23, 0.18)
    view.ground:SetWidth(W)
    view.kerb = ns.Fill(view.cityNear, "BORDER", 0.38, 0.44, 0.26)
    view.kerb:SetWidth(W)
    view.kerb:SetHeight(5)
    view.roof = roofFrame(canvas)
    view.menu = buildMenu(canvas)
    view.hudBox = ns.PlainFrame(canvas, 8)
    view.hudBox:SetPoint("TOPLEFT", canvas, "TOPLEFT", 6, -48)
    view.hudBox:SetWidth(130)
    view.hudBox:SetHeight(106)
    view.hudBox:Hide()
    local plate = ns.Fill(view.hudBox, "BACKGROUND", 0.13, 0.14, 0.17, 0.94)
    plate:SetAllPoints(view.hudBox)
    local cap = ns.Fill(view.hudBox, "BORDER", ART.RIG.PAINT)
    cap:SetPoint("TOPLEFT", view.hudBox, "TOPLEFT", 0, 0)
    cap:SetPoint("TOPRIGHT", view.hudBox, "TOPRIGHT", 0, 0)
    cap:SetHeight(2)
    local foot = ns.Fill(view.hudBox, "BORDER", ART.RIG.STEEL_HI)
    foot:SetPoint("BOTTOMLEFT", view.hudBox, "BOTTOMLEFT", 0, 0)
    foot:SetPoint("BOTTOMRIGHT", view.hudBox, "BOTTOMRIGHT", 0, 0)
    foot:SetHeight(1)
    view.hud = view.hudBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.hud:SetPoint("TOPLEFT", view.hudBox, "TOPLEFT", 8, -9)
    view.tally = ns.MakeScoreboard(canvas, 114)
    view.tally:SetPoint("TOPLEFT", canvas, "TOPLEFT", 14, -70)
    view.tally:Hide()
    view.top = ns.PlainFrame(canvas, 9)
    view.top:SetAllPoints(canvas)
    view.pop = {}
    for i = 1, FORM.POPS do
        local fs = view.top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:Hide()
        view.pop[i] = fs
    end
    view.combo = view.top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.combo:SetPoint("TOPRIGHT", view.top, "TOPRIGHT", -16, -10)
    view.combo:Hide()
    view.comboBar = ns.Fill(view.top, "OVERLAY", PAL.GOLD)
    view.comboBar:SetHeight(3)
    view.comboBar:SetPoint("TOPRIGHT", view.top, "TOPRIGHT", -16, -32)
    view.comboBar:Hide()
    view.back = ns.MakeKitButton(canvas)
    view.back:SetFrameLevel(canvas:GetFrameLevel() + 9)
    view.back:SetWidth(114)
    view.back:SetHeight(22)
    view.back:SetPoint("TOPLEFT", canvas, "TOPLEFT", 14, -124)
    view.back:SetText(ns.T("tower.toMenu"))
    view.back.tip = ns.T("tower.toMenuTip")
    view.back.onClick = function()
        local g = ns.Loop.Current()
        if g and g.ToMenu then g:ToMenu() end
    end
    view.back:Hide()
    view.ruler = ns.PlainFrame(canvas, 6)
    view.ruler:Hide()
    view.ruler:SetAllPoints(canvas)
    view.rulerBar = ns.Fill(view.ruler, "BACKGROUND", RULER.BAR)
    view.rulerBar:SetWidth(RULER.W)
    view.rulerBar:SetPoint("TOPRIGHT", view.ruler, "TOPRIGHT", -RULER.X, -RULER.TOP)
    view.rulerBar:SetPoint("BOTTOMRIGHT", view.ruler, "BOTTOMRIGHT", -RULER.X, 0)
    view.tick = {}
    for i = 1, RULER.TICKS do
        view.tick[i] = ns.Fill(view.ruler, "BORDER", RULER.TICK)
    end
    view.rulerText = {}
    for i = 1, RULER.TEXTS do
        view.rulerText[i] = view.ruler:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    end
    view.recMark = {}
    for i = 1, RULER.RECS do
        local m = { rows = {} }
        for r = 1, #RULER.WEDGE do
            local t = ns.Fill(view.ruler, "ARTWORK", RULER.PAST)
            t:SetWidth(RULER.WEDGE[r])
            t:SetHeight(RULER.ROW)
            m.rows[r] = t
        end
        m.text = view.ruler:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        m.text:SetJustifyH("LEFT")
        view.recMark[i] = m
    end
    view.rig = ns.PlainFrame(canvas, 5)
    view.rig:Hide()
    view.rig:SetAllPoints(canvas)
    local function rigRect(t, x, y, w, h)
        t:SetWidth(w)
        t:SetHeight(h)
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", view.rig, "BOTTOMLEFT", x, y)
        return t
    end
    local function rigFill(layer, c, x, y, w, h)
        return rigRect(ns.Fill(view.rig, layer, c), x, y, w, h)
    end
    local function truss(vert, x, y, w, h, u0, u1, v0, v1)
        local t = view.rig:CreateTexture(nil, "BORDER")
        t:SetTexture(vert and ART.TRUSS_V or ART.TRUSS_H)
        t:SetTexCoord(u0, u1, v0, v1)
        t:SetVertexColor(ART.RIG.PAINT[1], ART.RIG.PAINT[2], ART.RIG.PAINT[3])
        return rigRect(t, x, y, w, h)
    end
    local rx = ART.RIG.MAST_X + ART.RIG.MAST_W
    while rx < ART.RIG.TIP_X do
        local w = min(ART.RIG.TILE, ART.RIG.TIP_X - rx)
        truss(false, rx, ART.RIG.JIB_Y, w, ART.RIG.JIB_H, 0, w / ART.RIG.TILE, 0, 1)
        rx = rx + w
    end
    view.mast = {}
    local ry = ART.RIG.JIB_Y
    while ry > 0 do
        local h = min(ART.RIG.TILE, ry)
        local t = truss(true, ART.RIG.MAST_X, ry - h, ART.RIG.MAST_W, h, 0, 1, 0, h / ART.RIG.TILE)
        view.mast[#view.mast + 1] = { tex = t, y = ry - h, h = h }
        ry = ry - h
    end
    view.pad = rigFill("ARTWORK", ART.RIG.SLAB, ART.RIG.MAST_X - 7, 0, ART.RIG.MAST_W + 14, 9)
    rigFill("ARTWORK", ART.RIG.STEEL, ART.RIG.TIP_X, ART.RIG.JIB_Y - 2, 3, ART.RIG.JIB_H + 4)
    rigFill("OVERLAY", ART.RIG.BEACON, ART.RIG.TIP_X, ART.RIG.JIB_Y + ART.RIG.JIB_H + 1, 3, 3)
    local lx = ART.RIG.TAIL_X
    while lx < ART.RIG.MAST_X do
        local w = min(ART.RIG.TILE, ART.RIG.MAST_X - lx)
        truss(false, lx, ART.RIG.JIB_Y, w, ART.RIG.JIB_H, 0, w / ART.RIG.TILE, 0, 1)
        lx = lx + w
    end
    rigFill("ARTWORK", ART.RIG.STEEL, ART.RIG.TAIL_X - 3, ART.RIG.JIB_Y - 2, 3, ART.RIG.JIB_H + 4)
    rigFill("OVERLAY", ART.RIG.STEEL, ART.RIG.TAIL_X + 14, ART.RIG.JIB_Y + 4, 24, 10)
    rigFill("OVERLAY", ART.RIG.STEEL_HI, ART.RIG.TAIL_X + 17, ART.RIG.JIB_Y + 11, 18, 2)
    for i = 0, 2 do
        rigFill("ARTWORK", ART.RIG.SLAB, ART.RIG.TAIL_X + 12, ART.RIG.JIB_Y - 7 * (i + 1), 36, 6)
    end
    rigFill("ARTWORK", ART.RIG.STEEL, ART.RIG.TAIL_X + 15, ART.RIG.JIB_Y - 21, 2, 21)
    rigFill("ARTWORK", ART.RIG.STEEL, ART.RIG.TAIL_X + 43, ART.RIG.JIB_Y - 21, 2, 21)
    rigFill("ARTWORK", ART.RIG.STEEL, ART.RIG.MAST_X - 4, ART.RIG.JIB_Y - 8, ART.RIG.MAST_W + 8, 8)
    rigFill("ARTWORK", ART.RIG.PAINT, ART.RIG.MAST_X + ART.RIG.MAST_W, ART.RIG.JIB_Y - 22, 18, 20)
    rigFill("OVERLAY", ART.RIG.GLASS, ART.RIG.MAST_X + ART.RIG.MAST_W + 2, ART.RIG.JIB_Y - 14, 14, 10)
    rigFill("OVERLAY", ART.RIG.STEEL, ART.RIG.MAST_X + ART.RIG.MAST_W, ART.RIG.JIB_Y - 22, 18, 3)
    rigFill("ARTWORK", ART.RIG.STEEL, ART.RIG.MAST_X + ART.RIG.MAST_W, ART.RIG.JIB_Y - 26, 6, 5)
    view.trolley = rigFill("ARTWORK", ART.RIG.STEEL, 0, ART.RIG.JIB_Y - ART.RIG.TROLLEY_H, ART.RIG.TROLLEY_W, ART.RIG.TROLLEY_H)
    view.trolleyHi = rigFill("OVERLAY", ART.RIG.STEEL_HI, 0, ART.RIG.JIB_Y - 3, ART.RIG.TROLLEY_W, 2)
    view.trolley:Hide()
    view.trolleyHi:Hide()
    view.crane = ns.PlainFrame(canvas, 6)
    view.crane:Hide()
    view.crane:SetAllPoints(canvas)
    view.cable = {}
    for i = 1, 3 do
        local t = view.crane:CreateTexture(nil, "BORDER")
        t:SetTexture((i == 1) and ART.ROPE or ART.LINE)
        t:SetVertexColor(ART.RIG.ROPE[1], ART.RIG.ROPE[2], ART.RIG.ROPE[3])
        t:Hide()
        view.cable[i] = t
    end
    view.block = view.crane:CreateTexture(nil, "ARTWORK")
    view.block:SetWidth(ART.BLOCK_SIDE * ART.FIT)
    view.block:SetHeight(ART.BLOCK_SIDE * ART.FIT)
    view.block:Hide()
    view.blockBadge = view.crane:CreateTexture(nil, "OVERLAY")
    view.blockBadge:SetWidth(28)
    view.blockBadge:SetHeight(28)
    view.blockBadge:Hide()
    view.deck = view.crane:CreateTexture(nil, "BACKGROUND")
    view.deck:SetTexture(EMPTY_TEX)
    view.deck:SetPoint("BOTTOMLEFT", view.crane, "BOTTOMLEFT", 0, 0)
    view.deck:SetPoint("BOTTOMRIGHT", view.crane, "BOTTOMRIGHT", 0, 0)
    view.deck:SetHeight(BG.DECK_H)
    view.deck:Hide()
    view.stratus = {}
    for i = 1, BG.STRATUS do
        view.stratus[i] = {
            ns.Fill(view.crane, "BORDER", 0.96, 0.97, 1.00),
            ns.Fill(view.crane, "BORDER", 0.96, 0.97, 1.00),
        }
    end
    view.hook = ns.PlainFrame(canvas, 7)
    view.hook:Hide()
    view.hook:SetWidth(ART.HOOK_SIDE * ART.FIT)
    view.hook:SetHeight(ART.HOOK_SIDE * ART.FIT)
    view.hook.tex = view.hook:CreateTexture(nil, "ARTWORK")
    view.hook.tex:SetTexture(ART.HOOK)
    view.hook.tex:SetAllPoints()
    floorPool = ns.NewPool(function() return floorFrame(canvas) end)
    resPool = ns.NewPool(function() return resFrame(canvas) end)
end
local function hideView()
    if not view then return end
    view.sky:Hide()
    view.cityFar:Hide()
    view.cityNear:Hide()
    view.crane:Hide()
    view.rig:Hide()
    view.ruler:Hide()
    view.hook:Hide()
    for i = 1, 3 do view.cable[i]:Hide() end
    view.deck:Hide()
    view.roof:Hide()
    view.menu.root:Hide()
    view.hudBox:Hide()
    view.tally:Hide()
    view.back:Hide()
    view.top:Hide()
    if floorPool then floorPool:HideAll() end
    if resPool then resPool:HideAll() end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.floors = {}
    self.residents = {}
    self.debris = {}
    self.clouds = {}
    self.strati = {}
    self.birds = {}
    return self
end
function Game:CraneOff()
    local p, b = self.craneP, FORM.CRANE_B
    local dip = b * FORM.CRANE_DIP
    if self.craneShape == "eight" then
        return PACE.CRANE_A * sin(p), b * sin(2 * p) - dip
    end
    return PACE.CRANE_A * sin(p), b * cos(p) - dip
end
function Game:CraneVel()
    local p = self.craneP
    if self.craneShape == "eight" then
        return PACE.CRANE_A * cos(p), 2 * FORM.CRANE_B * cos(2 * p)
    end
    return PACE.CRANE_A * cos(p), -FORM.CRANE_B * sin(p)
end
function Game:CraneX()
    local dx = self:CraneOff()
    return PACE.CENTER_X + dx
end
function Game:Var(idx)
    local T = self.T
    return varAt(T, idx, (self.mode == MODE_CLIMB) and T.floors or nil)
end
function Game:CraneUp(cx, cy)
    local dx, dy = PACE.CENTER_X - cx, FORM.PIVOT_SY - cy
    local L = sqrt(dx * dx + dy * dy)
    if L < 1 then return 0, 1, 0 end
    local ux, uy = dx / L, dy / L
    return ux, uy, atan2(-ux, uy)
end
function Game:CraneSag()
    local _, dy = self:CraneOff()
    return dy
end
function Game:Mast()
    if not view.mast then return end
    local gy = self:ScreenY(0)
    local cut = max(0, gy)
    for i = 1, #view.mast do
        local m = view.mast[i]
        local top = m.y + m.h
        if top <= cut then
            m.tex:Hide()
        else
            local y = max(m.y, cut)
            local h = top - y
            m.tex:SetHeight(h)
            m.tex:SetTexCoord(0, 1, 0, h / ART.RIG.TILE)
            m.tex:ClearAllPoints()
            m.tex:SetPoint("BOTTOMLEFT", view.rig, "BOTTOMLEFT", ART.RIG.MAST_X, y)
            m.tex:Show()
        end
    end
    if gy >= 0 and gy < self.H then
        view.pad:ClearAllPoints()
        view.pad:SetPoint("BOTTOMLEFT", view.rig, "BOTTOMLEFT", ART.RIG.MAST_X - 7, max(0, gy - 2))
        view.pad:Show()
    else
        view.pad:Hide()
    end
end
function Game:Combo(dt)
    if (self.comboT or 0) > 0 then
        self.comboT = self.comboT - dt
        if self.comboT <= 0 then self.combo, self.comboT = 0, 0 end
    end
    local list = self.pops
    if not list then return end
    for i = #list, 1, -1 do
        list[i].t = list[i].t + dt
        if list[i].t >= FORM.POP_LIFE then table.remove(list, i) end
    end
end
function Game:Crane(dt)
    local vx, vy = self:CraneVel()
    local sp = sqrt(vx * vx + vy * vy)
    if sp < 1 then sp = 1 end
    self.craneP = self.craneP + PACE.CRANE_A * (2 / pi) * PACE.CRANE_W * dt / sp
    if self.craneP >= 2 * pi then
        self.craneP = self.craneP - 2 * pi
        self.craneLoop = (self.craneLoop or 0) + 1
        if self.craneRng and self.craneLoop % FORM.CRANE_HOLD == 0 then
            self.craneShape = (self.craneRng:Float() < FORM.CRANE_EIGHT)
                              and "eight" or "oval"
        end
    end
end
function Game:TopY()
    local n = #self.floors
    if n == 0 then return 0 end
    return self.floors[n].y + self.T.fh
end
function Game:TargetX()
    local n = #self.floors
    if n == 0 then return PACE.CENTER_X end
    return self.floors[n].x
end
function Game:Over(i)
    if i < 2 then return 0 end
    return abs(self.floors[i].x - self.floors[i - 1].x) / self.T.fw
end
function Game:MarkBad(i)
    local f = self.floors[i]
    f.ov = (i > 1) and (f.x - self.floors[i - 1].x) or 0
    f.bad = (abs(f.ov) >= FORM.BAD_OVER * self.T.fw) or nil
end
function Game:BadCount()
    local n = #self.floors
    local k, low = 0, nil
    for i = max(2, n - FORM.BAD_WIN + 1), n do
        if self.floors[i].bad then
            k = k + 1
            if not low then low = i end
        end
    end
    return k, low
end
function Game:Stress()
    local k = self:BadCount()
    return min(1, k / FORM.BAD_BREAK)
end
function Game:Wobble()
    return clamp01(self.wob + SWAY.STRESS_WOB * self:Stress())
end
function Game:Topple()
    local n = #self.floors
    if n < 2 then return nil end
    local fw = self.T.fw
    if self:Over(n) >= FORM.TIP_EDGE then return n end
    local load = 0
    for i = n, max(2, n - FORM.BAD_WIN + 1), -1 do
        local ov = self.floors[i].ov or 0
        if i < n and abs(ov) >= FORM.CRACK * fw and load * ov >= FORM.LOAD * fw * abs(ov) then
            return i
        end
        load = load + ov
    end
    local k, low = self:BadCount()
    if k >= FORM.BAD_BREAK then return low end
    return nil
end
function Game:Collapse(from)
    self.combo, self.comboT = 0, 0
    local n = #self.floors
    from = max(2, from)
    local lost, back = 0, 0
    for i = n, from, -1 do
        local p = self.floors[i]
        lost = lost + (p.lit or 1)
        back = back + (p.wobAdd or 0)
        self.debris[#self.debris + 1] = {
            x = p.x + self:Bend(i, n), y = p.y, vy = FORM.DEBRIS_V,
            vx = (p.x > self.floors[from - 1].x) and FORM.DEBRIS_SPIN or -FORM.DEBRIS_SPIN,
            idx = i, on = p.on or 0,
        }
        self.floors[i] = nil
    end
    for i = #self.residents, 1, -1 do
        if self.residents[i].fi >= from then table.remove(self.residents, i) end
    end
    self.n = #self.floors
    self.pop = max(0, self.pop - lost)
    self.wob = max(0, self.wob - back)
    self.lives = self.lives - 1
    ns.Sfx.Play("stuck")
    if self.lives <= 0 then self:GameOver() end
end
function Game:Amp()
    local h = min(1, self.n / SWAY.ALT_FULL)
    return min(SWAY.MAX, SWAY.ALT * h + SWAY.WILD * self:Wobble()) * self:Flex()
end
function Game:Flex()
    local hi = min(SWAY.FLEX_HI, max(SWAY.FLEX_LO + 2, self.ramp * 0.85))
    return clamp01((self.n - SWAY.FLEX_LO) / (hi - SWAY.FLEX_LO))
end
function Game:SwayW()
    return mix(SWAY.W_LO, SWAY.W_HI, min(1, self.n / SWAY.ALT_FULL))
end
function Game:Bend(i, n)
    if n <= 0 then return 0 end
    return self.sway * (i / n) ^ SWAY.BEND_P
end
function Game:Alt()
    if self.phase == "menu" then return PACE.GROUND_SY - PACE.MENU_SOIL end
    local a = self.cam - PACE.CAM_MIN
    if a < 0 then return 0 end
    return a
end
function Game:GameOver()
    if self.phase == "over" then return end
    self.phase = "over"
    self.phaseT = PACE.OVER_PAUSE
    ns.Sfx.Play("over")
end
function Game:Complete()
    self.roof = true
    self.phase = "done"
    self.phaseT = PACE.DONE_PAUSE
    ns.Config.Set(ID, DONE_PREFIX .. self.T.key, true)
    local T = self.T
    local n = #self.floors
    for i = 1, n do
        local p = self.floors[i]
        p.on = p.lit
    end
    for i = #self.residents, 1, -1 do table.remove(self.residents, i) end
    local sy = self:ScreenY(self:TopY())
    local cx = self:TargetX() + self:Bend(n, n)
    ns.FX.Dust(self.canvas, cx, sy, T.fw * 1.6, T.tint, 1.4)
    ns.Sfx.Play("clear")
end
function Game:RideTime()
    local d = self.cam - PACE.CAM_MIN
    if d < FORM.RIDE_NEAR then return 0 end
    return min(FORM.RIDE_MAX, max(FORM.RIDE_MIN, d / FORM.RIDE_V)) + FORM.RIDE_HOLD
end
function Game:Ride(dt)
    if not self.rideT then
        self.rideY = self.cam
        self.rideT = self:RideTime()
        self.ride = 0
        self.active = nil
        for i = #self.residents, 1, -1 do table.remove(self.residents, i) end
    end
    if self.ride >= self.rideT then return end
    self.ride = min(self.rideT, self.ride + dt)
    local d = self.rideT - FORM.RIDE_HOLD
    local u = (d > 0) and clamp01(self.ride / d) or 1
    self.cam = self.rideY + (PACE.CAM_MIN - self.rideY) * u * u * (3 - 2 * u)
end
function Game:RideSkip()
    if not self.rideT or self.ride >= self.rideT then return false end
    self.cam = PACE.CAM_MIN
    self.ride = self.rideT
    return true
end
function Game:Veil(sy, h, band)
    if not self.rideT then return 1 end
    return clamp01((self.H - h - sy) / band)
end
function Game:MoveIn(fi, count)
    for j = 1, count do
        if #self.residents >= RES_FLY then return end
        self.residents[#self.residents + 1] = {
            fi = fi, s = j,
            w = fi + j,
            y = self.cam + self.H + 20 + (j - 1) * 30,
            t = self.decor:Float() * 6,
        }
    end
end
function Game:PopUp(x, wy, n)
    if n <= 0 then return end
    local list = self.pops
    list[#list + 1] = { x = x, y = wy, t = 0, n = n }
    while #list > FORM.POPS do table.remove(list, 1) end
end
function Game:BonusIn()
    self.pop = self.pop + 1
    if #self.residents >= RES_FLY then return end
    local fi = #self.floors
    for k = fi - 1, 1, -1 do
        local p = self.floors[k]
        if p.lit < self:Var(k).wins then
            p.lit = p.lit + 1
            fi = k
            break
        end
    end
    local wins = self:Var(fi).wins
    if wins == 0 then return end
    self.residents[#self.residents + 1] = {
        fi = fi, s = min(wins, self.floors[fi].lit), hero = true,
        w = #self.floors,
        y = self.cam + self.H + 20,
        t = self.decor:Float() * 6,
    }
end
function Game:Residents(dt)
    for i = #self.residents, 1, -1 do
        local r = self.residents[i]
        local p = self.floors[r.fi]
        if not p then
            table.remove(self.residents, i)
        else
            r.t = r.t + dt
            r.y = r.y - RES_V * dt
            if r.y <= p.y + self.T.fh then
                p.on = min(p.lit, (p.on or 0) + 1)
                table.remove(self.residents, i)
            end
        end
    end
end
function Game:Debris(dt)
    for i = #self.debris, 1, -1 do
        local d = self.debris[i]
        d.vy = d.vy - PACE.GRAV * dt
        d.y = d.y + d.vy * dt
        d.x = d.x + d.vx * dt
        if self:ScreenY(d.y) < -self.T.fh - 20 then table.remove(self.debris, i) end
    end
end
function Game:Wind(dt)
    self.windT = self.windT + dt
    local target = self:Amp()
    self.amp = self.amp + (target - self.amp) * min(1, SWAY.AMP_EASE * dt)
    self.swayP = self.swayP + self:SwayW() * dt
    if self.swayP > 2 * pi then self.swayP = self.swayP - 2 * pi end
    self.sway = self.amp * sin(self.swayP)
end
function Game:Cloud(i, above)
    local c = self.clouds[i]
    local r = self.decor
    local alt = self:Alt()
    c.w = r:Int(70, 150)
    c.h = r:Int(24, 44)
    c.x = above and r:Int(-40, self.W - 40) or r:Int(-80, self.W + 40)
    c.by = alt * CLOUD_P + (above and (self.H + r:Int(10, 90)) or r:Int(60, self.H + 40))
end
function Game:Stratus(i, fresh)
    local c = self.strati[i]
    local r = self.decor
    local alt = self:Alt()
    c.w = r:Int(120, 240)
    c.h = r:Int(8, 14)
    if fresh then
        c.x = (r:Int(0, 1) == 0) and (-c.w - r:Int(10, 200)) or (self.W + r:Int(10, 200))
    else
        c.x = r:Int(-60, self.W + 20)
    end
    c.by = alt * BG.STRATUS_P + r:Int(30, BG.DECK_H + 40)
end
function Game:Bird(i, fresh)
    local b = self.birds[i]
    local r = self.decor
    local alt = self:Alt()
    b.dir = (r:Int(0, 1) == 0) and -1 or 1
    b.x = fresh and ((b.dir > 0) and (-20 - r:Int(0, 300)) or (self.W + 20 + r:Int(0, 300)))
              or r:Int(20, self.W - 20)
    b.by = alt * BG.BIRD_P + r:Int(140, self.H - 60)
    b.t = r:Float() * 3
    b.v = BG.BIRD_V * (0.8 + r:Float() * 0.5)
end
function Game:Decor(dt)
    local alt = self:Alt()
    local drift = CLOUD_V * sin(SWAY.WIND_W * self.windT)
    for i = 1, BG.STRATUS do
        local c = self.strati[i]
        c.x = c.x + drift * 1.6 * dt
        local sy = c.by - alt * BG.STRATUS_P
        if sy < -c.h - 10 or c.x < -c.w - 260 or c.x > self.W + 260 then
            self:Stratus(i, true)
        end
    end
    local flying = alt >= BG.BIRD_LO and alt <= BG.BIRD_HI
    for i = 1, BG.BIRDS do
        local b = self.birds[i]
        b.t = b.t + dt
        b.x = b.x + b.dir * b.v * dt
        local sy = b.by - alt * BG.BIRD_P
        if b.x < -340 or b.x > self.W + 340 or sy < -20 then
            if flying then self:Bird(i, true) else b.x = -400 end
        end
    end
    for i = 1, CLOUDS do
        local c = self.clouds[i]
        c.x = c.x + drift * dt
        local sy = c.by - alt * CLOUD_P
        if sy < -c.h - 30 or c.x < -c.w - 100 or c.x > self.W + 100 then
            self:Cloud(i, true)
        end
    end
    if self.bal then
        self.bal.by = self.bal.by + BAL_V * dt
        self.bal.x = self.bal.x + drift * 0.5 * dt
        if self.bal.by - alt * BAL_P > self.H + 80 then
            self.bal = nil
            self.balT = BAL_GAP
        end
    else
        self.balT = self.balT - dt
        if self.balT <= 0 then
            self.bal = { x = self.decor:Int(40, self.W - 40), by = alt * BAL_P - 70 }
        end
    end
end
function Game:Land(dx, topY, ax, swayTop)
    local T = self.T
    local d = abs(dx)
    if d >= T.miss then
        self.combo, self.comboT = 0, 0
        self.lives = self.lives - 1
        if self.lives <= 0 then
            self:GameOver()
        else
            self.phase = "miss"
            self.phaseT = PACE.MISS_PAUSE
            ns.Sfx.Play("deny")
        end
        return
    end
    local perfect = d <= T.perfect
    local snapped = d <= T.snap
    local near = d <= T.near
    local V = self:Var(self.n + 1)
    local lit = perfect and V.wins or (near and V.mid or min(1, V.wins))
    self.n = self.n + 1
    local x = snapped and self:TargetX() or (ax - swayTop)
    self.floors[#self.floors + 1] = { x = x, y = topY, lit = lit, on = 0,
                                      crest = snapped and 1 or nil }
    self:MarkBad(#self.floors)
    self.pop = self.pop + lit
    ns.FX.Dust(self.canvas, x, self:ScreenY(topY), T.fw, T.tint, snapped and 0.7 or 1)
    local e = snapped and 0 or (d / T.miss)
    self.floors[#self.floors].wobAdd = e * e * SWAY.WOB_UP
    self.wob = clamp01(self.wob + e * e * SWAY.WOB_UP
                       - SWAY.WOB_DOWN * (1 + SWAY.WOB_RECOV * self.wob)
                       + SWAY.WOB_HGT)
    local gain = lit
    self:MoveIn(#self.floors, lit)
    if perfect then self:BonusIn(); gain = gain + 1 end
    if snapped then
        self.combo = min(FORM.COMBO_CAP, (self.combo or 0) + 1)
        self.comboT = FORM.COMBO_TIME
        for _ = 1, self.combo do self:BonusIn() end
        gain = gain + self.combo
    elseif not perfect then
        self.combo, self.comboT = 0, 0
    end
    self:PopUp(x, topY + T.fh, gain)
    local tip = self:Topple()
    if tip then self:Collapse(tip) end
    self.active = nil
    if self.phase == "over" then return end
    self.phase = "aim"
    if self.mode == MODE_CLIMB and #self.floors >= T.floors then
        self:Complete()
        return
    end
    if perfect then
        local sy = self:ScreenY(topY) + T.fh / 2
        ns.FX.Stars(self.canvas, x, sy, snapped and T.fw * 1.3 or T.fw)
    end
    ns.Sfx.Play("pop")
    if snapped then ns.Sfx.Play("big") end
end
function Game:Update(dt)
    if self.phase == "menu" then
        self:Draw()
        return
    end
    self:Combo(dt)
    self:Wind(dt)
    self:Crane(dt)
    self:Decor(dt)
    self:Residents(dt)
    self:Debris(dt)
    if self.phase == "over" or self.phase == "miss" or self.phase == "done" then
        if self.phaseT > 0 then self.phaseT = max(0, self.phaseT - dt) end
        if self.active then
            self.active.vy = self.active.vy - PACE.GRAV * dt
            self.active.y = self.active.y + self.active.vy * dt
        end
        if self.phaseT <= 0 then
            if self.phase == "miss" then
                self.active = nil
                self.phase = "aim"
            else
                self:Ride(dt)
            end
        end
        self:Draw()
        return
    end
    if self.phase == "fall" then
        local a = self.active
        local y0 = a.y
        a.vy = a.vy - PACE.GRAV * dt
        a.y = a.y + a.vy * dt
        a.rot = (a.rot or 0) * max(0, 1 - ART.TILT_FALL * dt)
        local topY = self:TopY()
        if a.vy < 0 and a.y <= topY and y0 > topY then
            local swayTop = (#self.floors > 0) and self.sway or 0
            self:Land(a.x - (self:TargetX() + swayTop), topY, a.x, swayTop)
        end
    end
    local target = max(PACE.CAM_MIN, self:TopY() - PACE.TOP_SCREEN_Y)
    self.cam = self.cam + (target - self.cam) * min(1, PACE.CAM_EASE * dt)
    self:Draw()
end
function Game:PanelSync()
    if not view then return end
    if self.phase == "menu" or not self.phase then
        view.tally:Hide()
        view.hudBox:Hide()
        return
    end
    view.hudBox:Show()
    view.tally:Show()
    view.tally:Sync()
    view.top:Show()
end
function Game:Restart(opts)
    if self.started then return end
    if ns.Loop.Current() ~= self then return end
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, opts)
end
function Game:ToMenu()
    if self.phase == "menu" then return end
    if self.phase == "over" or self.phase == "done" then return end
    if ns.Loop.Current() ~= self then return end
    if not self.started then
        self.phase = "menu"
        self.phaseT = 0
        self.active = nil
        self:PanelSync()
        self:SyncMenu()
        self:Draw()
        return
    end
    local o = self.opts
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, o and { m = o.m, b = o.b, s = o.s } or nil)
end
function Game:SlotChosen(i)
    if i > #RULES then return self.mode == MODE_RUSH end
    return self.mode == MODE_CLIMB and self.T.key == types()[i].key
end
function Game:PaintSlot(i)
    local s = view.menu.slot[i]
    local chosen = self:SlotChosen(i)
    local hot = (view.menu.hover == i)
    local locked = s.hit.locked
    if chosen or hot then
        local p = chosen and PLOT_SEL or PLOT_HOVER
        local b = chosen and BASE_SEL or BASE_HOVER
        s.plot:SetTexture(p[1], p[2], p[3], 1)
        s.base:SetTexture(b[1], b[2], b[3], 1)
        s.plot:Show()
        s.base:Show()
    else
        s.plot:Hide()
        s.base:Hide()
    end
    local mode = locked and "locked" or (chosen and "sel" or "idle")
    if i > #RULES then
        drawMini(s.mini, rushTypes()[rushLook()], MENU_RUSH_FLOORS, mode, false)
    else
        drawMini(s.mini, types()[i], MENU_FLOORS[i], mode, true)
    end
    if locked then
        local k = hot and 0.58 or 0.45
        s.name:SetTextColor(k, k, k + 0.02)
        s.rec:SetTextColor(k, k, k + 0.02)
        s.hgt:SetTextColor(k * 0.9, k * 0.9, k * 0.9)
    elseif chosen then
        s.name:SetTextColor(1, 1, 1)
        s.rec:SetTextColor(0.89, 0.86, 0.80)
        s.hgt:SetTextColor(0.74, 0.72, 0.67)
    elseif hot then
        s.name:SetTextColor(0.94, 0.94, 0.95)
        s.rec:SetTextColor(0.78, 0.78, 0.79)
        s.hgt:SetTextColor(0.64, 0.64, 0.65)
    else
        s.name:SetTextColor(0.71, 0.71, 0.73)
        s.rec:SetTextColor(0.60, 0.60, 0.61)
        s.hgt:SetTextColor(0.50, 0.50, 0.51)
    end
end
function Game:SyncMenu()
    local m = view.menu
    local me = self
    for i = 1, MENU_SLOTS do
        local s = m.slot[i]
        local isRush = (i > #RULES)
        local T = (not isRush) and types()[i] or nil
        s.name:SetText(isRush and ns.T("tower.modeRushLabel") or nameOf(T))
        s.hit.locked = (not isRush) and not unlocked(i)
        s.hit.tipTitle = isRush and ns.T("tower.modeRushLabel") or nameOf(T)
        if s.hit.locked then
            s.rec:SetText(ns.T("tower.menuLockedLabel"))
            s.hgt:SetText("")
            s.hit.tip = ns.T("tower.ladderNextTip", nameOf(T), nameOf(types()[i - 1]))
        else
            local opts = isRush and { m = MODE_RUSH, b = RULES[rushLook()].key, s = skinKey() }
                         or { m = MODE_CLIMB, b = T.key, s = skinKey() }
            local rec = ns.Records.Best(ID, opts)
            s.rec:SetText(ns.T("tower.menuRecordFmt", ns.Records.Format(nil, rec and rec.score)))
            local f = rec and tonumber(rec.floors)
            s.hgt:SetText(ns.T("tower.menuHeightFmt",
                               ns.Records.Format(nil, f and floor(f) or nil)))
            s.hit.tip = isRush and ns.T("tower.modeRushTip") or tipOf(T)
        end
        s.hit.onPick = function() me:PickSlot(i) end
        s.hit.onHover = function(on)
            if on then
                m.hover = i
            elseif m.hover == i then
                m.hover = nil
            end
            me:PaintSlot(i)
        end
        self:PaintSlot(i)
    end
    local cur = skinKey()
    for i = 1, #SKINS do
        local b = m.skin[i]
        local on = (SKINS[i].key == cur)
        b.active = on
        b.tip = ns.T("tower.skinTip")
        ns.StyleButton(b)
        b.onClick = function()
            if SKINS[i].key == skinKey() then return end
            ns.Store.SetSkin(ID, SKINS[i].key)
            me:ApplySkin()
        end
    end
    m.play.onClick = function() me:BeginRound() end
end
function Game:ApplySkin()
    self.T = typeByKey(self.T.key) or types()[topUnlocked()]
    view.roofT = nil
    if floorPool then floorPool:HideAll() end
    self:SyncMenu()
    self:Draw()
end
function Game:PickSlot(i)
    if self:SlotChosen(i) then return end
    if i > #RULES then
        self:Restart({ m = MODE_RUSH })
    elseif unlocked(i) then
        ns.Config.Set(ID, LOOK_KEY, i)
        self:Restart({ m = MODE_CLIMB, b = types()[i].key })
    end
end
function Game:StepSlot(dir)
    local cur
    for i = 1, MENU_SLOTS do
        if self:SlotChosen(i) then cur = i; break end
    end
    if not cur then return end
    local i = cur + dir
    while i >= 1 and i <= MENU_SLOTS do
        if i > #RULES or unlocked(i) then self:PickSlot(i); return end
        i = i + dir
    end
end
function Game:BeginRound()
    if self.phase ~= "menu" then return end
    self.phase = "aim"
    self:Draw()
end
function Game:Clock()
    return tostring(self.lives), self.lives <= 1
end
function Game:SeedDecor()
    local r = self.decor
    for _, sk in ipairs({ SKIN_ERA, SKIN_WOW }) do
        local set = SCENES[sk]
        for ri = 1, #set do
            local row = set[ri]
            local parts = view.scene[sk][ri]
            local items = row.b or row.t
            local k = 1
            for bi = 1, #items do
                local hk = 0.90 + r:Int(0, 20) / 100
                local dx = r:Int(-8, 8)
                local rects = rowRects(row, items[bi], hk)
                for j = 1, #rects do
                    local rc, p = rects[j], parts[k]
                    p.x, p.y, p.w, p.h = rc[1] + dx, rc[2], rc[3], rc[4]
                    k = k + 1
                end
            end
        end
    end
    view.worldAlt = nil
    for i = 1, CLOUDS do
        self.clouds[i] = self.clouds[i] or {}
        self:Cloud(i, false)
    end
    for i = 1, BG.STRATUS do
        self.strati[i] = self.strati[i] or {}
        self:Stratus(i, false)
    end
    for i = 1, BG.BIRDS do
        self.birds[i] = self.birds[i] or {}
        self:Bird(i, true)
    end
    self.bal = nil
    self.balT = r:Int(3, BAL_GAP)
end
function Game:Start(seed, moves)
    ensureView(self.canvas)
    self.W, self.H = self.canvas.W or 640, self.canvas.H or 480
    local o = self.opts
    self.mode = (o and o.m == MODE_RUSH) and MODE_RUSH or MODE_CLIMB
    local pickRng = ns.RNG.New(seed)
    pickRng:Int(1, #RULES)
    if self.mode == MODE_RUSH then
        self.T = rushTypes()[rushLook()]
        self.ramp = PACE.RUSH_RAMP
        self.opts = { m = MODE_RUSH, b = RULES[self.T.idx].key, s = skinKey() }
    else
        local T = (o and o.b) and typeByKey(o.b) or nil
        if not T or not unlocked(T.idx) then T = types()[topUnlocked()] end
        self.T = T
        self.ramp = T.floors
        self.opts = { m = MODE_CLIMB, b = T.key, s = skinKey() }
    end
    local name = ns.Shelves.Pick(ID, "floor", pickRng)
    self.badge = name and ns.IconPath(name) or nil
    local rider = ns.Shelves.Pick(ID, "rider", pickRng)
    self.rider = rider and ns.IconPath(rider) or nil
    self.decor = ns.RNG.New(seed * 7 + 13)
    for i = #self.floors, 1, -1 do self.floors[i] = nil end
    for i = #self.residents, 1, -1 do self.residents[i] = nil end
    for i = #self.debris, 1, -1 do self.debris[i] = nil end
    self.n = 0
    self.pop = 0
    self.lives = PACE.LIVES
    self.clockTip = ns.T("tower.clockTip")
    self.clockCap = ns.T("tower.clockCap")
    self.marks = {}
    for _, rec in ipairs(ns.Records.List(ID, self.opts)) do
        local f = tonumber(rec.floors)
        if f and f > 0 then self.marks[#self.marks + 1] = floor(f) end
    end
    self.wob = 0
    self.roof = false
    self.started = false
    self.active = nil
    self.phase = "menu"
    self.phaseT = 0
    self.craneP = 0
    self.craneShape = "oval"
    self.craneRng = ns.RNG.New(seed)
    self.combo, self.comboT = 0, 0
    self.pops = {}
    self.cam = PACE.CAM_MIN
    self.ride, self.rideT, self.rideY = nil, nil, nil
    self.sway, self.swayP, self.windT = 0, 0, 0
    self.amp = 0
    if moves and type(moves[1]) == "table" and moves[1].k == "snap" then
        self:Restore(moves[1])
    end
    if self.roof then ns.Config.Set(ID, DONE_PREFIX .. self.T.key, true) end
    self:SeedDecor()
    view.roofT = nil
    view.paintT = nil
    view.worldAlt = nil
    view.hudText = nil
    self:SyncMenu()
    self:Draw()
end
function Game:Key(action, down)
    if not down then return end
    if self.phase == "menu" then
        if action == "left" then self:StepSlot(-1)
        elseif action == "right" then self:StepSlot(1)
        elseif action == "fire" then self:BeginRound() end
        return
    end
    if action == "fire" then
        if self:RideSkip() then return end
        self:Move{ k = "drop" }
    end
end
function Game:Move(move)
    if not move or move.k ~= "drop" then return end
    if self.phase ~= "aim" then return end
    local x, y = self:CraneX(), self:TopY() + PACE.DROP_H + self:CraneSag()
    local _, _, rot = self:CraneUp(x, self:ScreenY(y) + self.T.fh / 2)
    self.active = { x = x, y = y, vy = 0, rot = rot }
    self.phase = "fall"
    self.started = true
end
function Game:Click(x, y, button)
    if self:RideSkip() then return end
    self:Move{ k = "drop" }
end
function Game:Marks()
    return { floors = self.n }
end
function Game:Score()
    return self.pop or 0
end
function Game:IsOver()
    if self.phase ~= "over" and self.phase ~= "done" then return false end
    if self.phaseT > 0 then return false end
    return self.rideT ~= nil and self.ride >= self.rideT
end
function Game:Stop()
    hideView()
end
function Game:Serialize()
    local fl = {}
    for i = 1, #self.floors do
        local p = self.floors[i]
        local n = #fl
        fl[n + 1], fl[n + 2], fl[n + 3] = p.x, p.y, p.lit or 1
        fl[n + 4] = p.crest and 1 or 0
    end
    local a = self.active
    return {
        k = "snap", v = 4,
        n = self.n, pop = self.pop, cam = self.cam,
        lives = self.lives, wob = self.wob,
        started = self.started and 1 or 0,
        phase = self.phase, pt = self.phaseT, crp = self.craneP,
        crs = self.craneShape, cmb = self.combo, cmt = self.comboT,
        swp = self.swayP, amp = self.amp, wt = self.windT,
        ax = a and a.x, ay = a and a.y, avy = a and a.vy,
        floors = fl,
    }
end
function Game:Restore(s)
    if s.v ~= 4 then return end
    local T = self.T
    for i = #self.floors, 1, -1 do self.floors[i] = nil end
    local fl = type(s.floors) == "table" and s.floors or {}
    for i = 1, floor(#fl / 4) * 4, 4 do
        local lit = floor(ns.Store.Num(fl[i + 2], 0, MAX_WINS, 1))
        self.floors[#self.floors + 1] = {
            x = ns.Store.Num(fl[i], 0, self.W, PACE.CENTER_X),
            y = ns.Store.Num(fl[i + 1], -1e6, 1e9, 0),
            lit = lit, on = lit,
            crest = (ns.Store.Num(fl[i + 3], 0, 1, 0) > 0) and 1 or nil,
        }
    end
    self.n = ns.Store.Num(s.n, 0, 1e6, #self.floors)
    self.pop = ns.Store.Num(s.pop, 0, 1e9, 0)
    self.cam = ns.Store.Num(s.cam, PACE.CAM_MIN, 1e9, PACE.CAM_MIN)
    self.lives = floor(ns.Store.Num(s.lives, 0, PACE.LIVES, PACE.LIVES))
    self.wob = ns.Store.Num(s.wob or s.lean, 0, 1, 0)
    self.started = (ns.Store.Num(s.started, 0, 1, 0) > 0) or #self.floors > 0
    self.swayP = ns.Store.Num(s.swp, 0, 7, 0)
    self.amp = ns.Store.Num(s.amp, 0, SWAY.MAX, 0)
    self.sway = 0
    self.windT = ns.Store.Num(s.wt, 0, 1e6, 0)
    for i = 1, #self.floors do
        local p = self.floors[i]
        local below = (i > 1) and self.floors[i - 1].x or PACE.CENTER_X
        local e = p.crest and 0 or min(1, abs(p.x - below) / T.miss)
        p.wobAdd = e * e * SWAY.WOB_UP
        self:MarkBad(i)
    end
    local ph = s.phase
    if ph ~= "fall" and ph ~= "over" and ph ~= "miss" and ph ~= "done" and ph ~= "menu" then
        ph = "aim"
    end
    self.phase = ph
    self.phaseT = ns.Store.Num(s.pt, 0, PACE.DONE_PAUSE, 0)
    self.craneP = ns.Store.Num(s.crp, 0, 62832, 0)
    self.craneShape = (s.crs == "eight") and "eight" or "oval"
    self.combo = ns.Store.Num(s.cmb, 0, FORM.COMBO_CAP, 0)
    self.comboT = ns.Store.Num(s.cmt, 0, FORM.COMBO_TIME, 0)
    self.roof = (ph == "done")
                or (self.mode == MODE_CLIMB and #self.floors >= T.floors)
    if ph == "fall" or ((ph == "over" or ph == "miss") and s.ax) then
        self.active = {
            x = ns.Store.Num(s.ax, 0, self.W, PACE.CENTER_X),
            y = ns.Store.Num(s.ay, -1e6, 1e9, self:TopY() + PACE.DROP_H),
            vy = ns.Store.Num(s.avy, -1e5, 1e5, 0),
        }
    else
        self.active = nil
    end
end
function Game:ScreenY(wy)
    return wy - self.cam
end
function Game:Paint()
    local t = clamp01(self:Alt() / BG.SKY_FULL)
    if view.paintT and abs(view.paintT - t) < 0.006 then return end
    view.paintT = t
    local lo = mixTo(mixA, SKY_DAY_LO, SKY_NIGHT_LO, t)
    local hi = mixTo(mixB, SKY_DAY_HI, SKY_NIGHT_HI, t)
    for i = 1, BG.SKY_BANDS do
        local k = (i - 1) / (BG.SKY_BANDS - 1)
        view.band[i]:SetTexture(mix(lo[1], hi[1], k), mix(lo[2], hi[2], k),
                                mix(lo[3], hi[3], k), 1)
    end
    local sa = clamp01(t * 1.7 - 0.55)
    for i = 1, BG.STARS do view.star[i]:SetAlpha(sa) end
    local suna = 1 - clamp01(t * 2.2)
    for i = 1, #view.sun do view.sun[i]:SetAlpha(suna) end
    local mr, mg, mb = mix3(BG.MOUNT_TINT, lo, BG.MOUNT_MIX)
    local sr, sg, sb = mix3(BG.MOUNT_SNOW, lo, 0.35)
    for i = 1, #view.mount do
        local p = view.mount[i]
        if p.tone == "snow" then
            p.tex:SetTexture(sr, sg, sb, 1)
        else
            p.tex:SetTexture(mr, mg, mb, 1)
        end
    end
    local alt = self:Alt()
    local da = BG.DECK_A * clamp01((alt - BG.DECK_FROM) / (BG.DECK_FULL - BG.DECK_FROM))
    local d = mixTo(mixA, BG.DECK_DAY, BG.DECK_NIGHT, t)
    if da > 0.01 then
        view.deck:SetGradientAlpha("VERTICAL", d[1], d[2], d[3], da, d[1], d[2], d[3], 0)
        view.deck:Show()
    else
        view.deck:Hide()
    end
    local stra = da * 0.9
    for i = 1, BG.STRATUS do
        local c = view.stratus[i]
        c[1]:SetTexture(d[1], d[2], d[3], stra)
        c[2]:SetTexture(d[1], d[2], d[3], stra * 0.7)
    end
    local hr, hg, hb = HAZE_DAY[1], HAZE_DAY[2], HAZE_DAY[3]
    local ha = HAZE_A * (1 - clamp01(t * 1.15))
    view.haze:SetGradientAlpha("VERTICAL", hr, hg, hb, ha, hr, hg, hb, 0)
    local set = SCENES[skinKey()]
    for ri = 1, #set do
        local row = set[ri]
        local br, bg, bb = mix3(row.tint, lo, row.mix)
        local gr, gg, gb = mix3(row.trunk or row.tint, lo, row.mix * row.glaz)
        local tr, tg, tb = mix3(row.tint, lo, min(0.95, row.mix + 0.12))
        local parts = view.scene[skinKey()][ri]
        for i = 1, #parts do
            local p = parts[i]
            if p.tone == "body" then
                p.tex:SetTexture(br, bg, bb, 1)
            elseif p.tone == "glass" then
                p.tex:SetTexture(gr, gg, gb, 1)
            else
                p.tex:SetTexture(tr, tg, tb, 1)
            end
        end
        local floor = view.rowFloor[ri]
        if floor then
            floor:SetTexture(br, bg, bb, 1)
        end
    end
    local cr, cg, cb = mix3(TREE_CROWN, lo, 0.16)
    local kr, kg, kb2 = mix3(TREE_TRUNK, lo, 0.10)
    for i = 1, #view.tree do
        local p = view.tree[i]
        if p.tone == "crown" then
            p.tex:SetTexture(cr, cg, cb, 1)
        else
            p.tex:SetTexture(kr, kg, kb2, 1)
        end
    end
    local g = mixTo(mixA, GROUND_DAY, GROUND_NIGHT, t)
    view.ground:SetTexture(g[1], g[2], g[3], 1)
    local kb = mixTo(mixB, KERB_DAY, KERB_NIGHT, t)
    view.kerb:SetTexture(kb[1], kb[2], kb[3], 1)
    local ca = mix(CLOUD_A, 0.14, t)
    for i = 1, CLOUDS do
        local c = view.cloud[i]
        for k = 1, 3 do c[k]:SetTexture(0.97, 0.98, 1.00, ca) end
    end
    local ba = mix(1, 0.45, t)
    for i = 1, #view.bal do view.bal[i].tex:SetAlpha(ba) end
end
function Game:DrawWorld(alt)
    local W, H = self.W, self.H
    view.sky:Show()
    view.cityFar:Show()
    view.cityNear:Show()
    local sk = skinKey()
    if view.sceneKey ~= sk then
        if view.sceneKey then
            for ri = 1, #view.scene[view.sceneKey] do
                local parts = view.scene[view.sceneKey][ri]
                for i = 1, #parts do parts[i].tex:Hide() end
            end
        end
        view.sceneKey = sk
        view.worldAlt = nil
    end
    local set = SCENES[sk]
    if not view.worldAlt or abs(view.worldAlt - alt) >= 0.5 then
        view.worldAlt = alt
        local nearBase = set[NEAR_ROW].base - alt * set[NEAR_ROW].par
        local mountBase = BG.MOUNT_BASE - alt * BG.MOUNT_PAR
        view.haze:ClearAllPoints()
        view.haze:SetPoint("BOTTOMLEFT", view.sky, "BOTTOMLEFT", 0, mountBase)
        for i = 1, #view.mount do
            local p = view.mount[i]
            placeClipped(p.tex, view.sky, p.x, mountBase + p.y, p.w, p.h, W, H)
        end
        for ri = 1, #set do
            local row = set[ri]
            local sy = row.base - alt * row.par
            local parts = view.scene[sk][ri]
            for i = 1, #parts do
                local p = parts[i]
                placeClipped(p.tex, parts.host, p.x, sy + p.y, p.w, p.h, W, H)
            end
            local floor = view.rowFloor[ri]
            if floor then
                if sy > 0 then
                    floor:SetWidth(W)
                    floor:SetHeight(min(sy, H))
                    floor:Show()
                else
                    floor:Hide()
                end
            end
        end
        for i = 1, #view.tree do
            local p = view.tree[i]
            placeClipped(p.tex, view.cityNear, p.x, nearBase + p.y, p.w, p.h, W, H)
        end
        local menu = (self.phase == "menu")
        for i = 1, #view.site do
            local p = view.site[i]
            if menu then
                p.tex:Hide()
            else
                placeClipped(p.tex, view.cityNear, p.x, nearBase + p.y, p.w, p.h, W, H)
            end
        end
        local b = SITE.board
        if menu or nearBase + b[2] + b[4] < 0 then
            view.siteText:Hide()
        else
            view.siteText:ClearAllPoints()
            view.siteText:SetPoint("CENTER", view.cityNear, "BOTTOMLEFT",
                                   b[1] + b[3] / 2, nearBase + b[2] + b[4] / 2)
            view.siteText:Show()
        end
        if nearBase > 0 then
            view.ground:ClearAllPoints()
            view.ground:SetHeight(min(nearBase, H))
            view.ground:SetPoint("BOTTOMLEFT", view.cityNear, "BOTTOMLEFT", 0, 0)
            view.ground:Show()
            view.kerb:ClearAllPoints()
            view.kerb:SetPoint("BOTTOMLEFT", view.cityNear, "BOTTOMLEFT", 0, nearBase - 5)
            view.kerb:Show()
        else
            view.ground:Hide()
            view.kerb:Hide()
        end
    end
    for i = 1, CLOUDS do
        local c = self.clouds[i]
        local t = view.cloud[i]
        local sy = c.by - alt * CLOUD_P
        placeClipped(t[1], view.sky, c.x,               sy, c.w,        c.h * 0.50, W, H)
        placeClipped(t[2], view.sky, c.x + c.w * 0.10,  sy, c.w * 0.52, c.h * 0.95, W, H)
        placeClipped(t[3], view.sky, c.x + c.w * 0.58,  sy, c.w * 0.34, c.h * 0.72, W, H)
    end
    for i = 1, BG.STRATUS do
        local c = self.strati[i]
        local t = view.stratus[i]
        local sy = c.by - alt * BG.STRATUS_P
        placeClipped(t[1], view.crane, c.x, sy, c.w, c.h, W, H)
        placeClipped(t[2], view.crane, c.x + c.w * 0.18, sy + c.h, c.w * 0.5, c.h * 0.6, W, H)
    end
    local flying = alt >= BG.BIRD_LO and alt <= BG.BIRD_HI
    for i = 1, BG.BIRDS do
        local b = self.birds[i]
        local t = view.bird[i]
        if flying and b.x > -30 and b.x < W + 30 then
            local sy = b.by - alt * BG.BIRD_P + 3 * sin(b.t * 2.1)
            local flap = (floor(b.t * 6) % 2 == 0) and 1 or 0
            placeClipped(t[1], view.cityNear, b.x - 1, sy, 3, 2, W, H)
            placeClipped(t[2], view.cityNear, b.x - 5, sy + flap, 4, 2, W, H)
            placeClipped(t[3], view.cityNear, b.x + 2, sy + flap, 4, 2, W, H)
        else
            t[1]:Hide(); t[2]:Hide(); t[3]:Hide()
        end
    end
    if self.bal then
        local sy = self.bal.by - alt * BAL_P
        for i = 1, #view.bal do
            local p = view.bal[i]
            placeClipped(p.tex, view.cityNear, self.bal.x - p.w / 2,
                         sy + 44 + p.dy - p.h, p.w, p.h, W, H)
        end
    else
        for i = 1, #view.bal do view.bal[i].tex:Hide() end
    end
end
function Game:DrawRuler()
    local H, fh = self.H, self.T.fh
    local lo = max(0, floor(self.cam / fh))
    local hi = floor((self.cam + H) / fh)
    local ti, li = 0, 0
    for n = lo, hi do
        if n % RULER.STEP == 0 then
            local sy = self:ScreenY(n * fh)
            if sy > 4 and sy < H - RULER.TOP then
                local long = (n % RULER.LABEL == 0)
                if ti < RULER.TICKS then
                    ti = ti + 1
                    local t = view.tick[ti]
                    t:SetWidth(long and 15 or 9)
                    t:SetHeight(long and 2 or 1)
                    t:ClearAllPoints()
                    t:SetPoint("BOTTOMRIGHT", view.ruler, "BOTTOMRIGHT", -RULER.X, sy)
                    t:Show()
                end
                if long and n > 0 and li < RULER.TEXTS then
                    li = li + 1
                    local fs = view.rulerText[li]
                    fs:SetText(n)
                    fs:ClearAllPoints()
                    fs:SetPoint("RIGHT", view.ruler, "BOTTOMRIGHT", -RULER.X - 17, sy + 1)
                    fs:Show()
                end
            end
        end
    end
    for i = ti + 1, RULER.TICKS do view.tick[i]:Hide() end
    for i = li + 1, RULER.TEXTS do view.rulerText[i]:Hide() end
    local mi = 0
    local half = #RULER.WEDGE * RULER.ROW / 2
    for i = 1, #self.marks do
        local sy = self:ScreenY(self.marks[i] * fh)
        local free = sy > half + 1 and sy < H - RULER.LTOP and mi < RULER.RECS
        for k = 1, mi do
            if abs(view.recMark[k].sy - sy) < RULER.GAP then free = false end
        end
        if free then
            mi = mi + 1
            local m = view.recMark[mi]
            m.sy = sy
            local best = (i == 1)
            local c = best and RULER.BEST or RULER.PAST
            local a = best and 1 or 0.8
            for r = 1, #RULER.WEDGE do
                local t = m.rows[r]
                t:SetTexture(c[1], c[2], c[3], a)
                t:ClearAllPoints()
                t:SetPoint("BOTTOMLEFT", view.ruler, "BOTTOMLEFT", RULER.LX, sy + half - r * RULER.ROW)
                t:Show()
            end
            m.text:SetText(self.marks[i])
            m.text:SetTextColor(c[1], c[2], c[3])
            m.text:SetAlpha(a)
            m.text:ClearAllPoints()
            m.text:SetPoint("LEFT", view.ruler, "BOTTOMLEFT", RULER.LX + RULER.TIP + RULER.TEXT_DX, sy + 1)
            m.text:Show()
        end
    end
    for i = mi + 1, RULER.RECS do
        local m = view.recMark[i]
        for r = 1, #RULER.WEDGE do m.rows[r]:Hide() end
        m.text:Hide()
    end
end
function Game:Draw()
    local canvas = self.canvas
    local T = self.T
    local alt = self:Alt()
    self:Paint()
    self:DrawWorld(alt)
    if self.phase == "menu" then
        view.crane:Hide()
        view.rig:Hide()
        view.hook:Hide()
        for i = 1, 3 do view.cable[i]:Hide() end
        view.roof:Hide()
        floorPool:HideAll()
        resPool:HideAll()
        view.ruler:Hide()
        view.back:Hide()
        view.hudBox:Hide()
        view.menu.root:Show()
        return
    end
    view.menu.root:Hide()
    view.hudBox:Show()
    if self.phase == "over" or self.phase == "done" then
        view.back:Hide()
    else
        view.back:Show()
    end
    view.crane:Show()
    self:Mast()
    if not self.rideT then
        view.rig:SetAlpha(1)
        view.rig:Show()
    elseif self.ride < FORM.RIDE_RIG then
        view.rig:SetAlpha(clamp01(1 - self.ride / FORM.RIDE_RIG))
        view.rig:Show()
    else
        view.rig:Hide()
    end
    view.ruler:Show()
    self:DrawRuler()
    local txt = (self.mode == MODE_CLIMB)
        and (nameOf(T) .. "   " .. self.n .. "/" .. T.floors)
        or (nameOf(T) .. "   " .. self.n)
    if view.hudText ~= txt then
        view.hudText = txt
        view.hud:SetText(txt)
    end
    floorPool:Reset()
    local function drawFloor(wx, wy, idx, on, skew)
        local sy = self:ScreenY(wy)
        local fa = self:Veil(sy, (T.var.cap and idx >= #self.floors) and T.fh * 2 or T.fh, T.fh)
        if fa > 0.02 and sy > -T.fh and sy < self.H + 10 then
            local f = floorPool:Acquire()
            f:SetAlpha(fa)
            local V = self:Var(idx)
            local cut = (sy < 0) and ceil(-sy) or 0
            local mark = T.key .. skinKey() .. V.name .. cut
            if f.shapeDrawn ~= mark then
                f.shapeDrawn = mark
                f.tintDrawn = nil
                f.onDrawn = nil
                f.signDrawn = nil
                f.crestDrawn = nil
                FORM.CUT = cut
                shapeFloor(f, V, 0)
                FORM.CUT = 0
            end
            local si = (idx - 1) % #SHADE + 1
            if f.tintDrawn ~= si then
                f.tintDrawn = si
                paintFloor(f, V, SHADE[si])
            end
            if f.signDrawn ~= idx then
                f.signDrawn = idx
                signFloor(f, V, idx)
            end
            local crest = (self.floors[idx] and self.floors[idx].crest) and true or false
            if f.crestDrawn ~= crest then
                f.crestDrawn = crest
                crestFloor(f, crest)
            end
            if f.onDrawn ~= on then
                f.onDrawn = on
                local lit = V.lit or WIN_ON
                for i = 1, V.wins do
                    local c = (i <= on) and lit or (V.off or WIN_OFF)
                    f.win[i]:SetTexture(c[1], c[2], c[3], 1)
                end
            end
            if f.badgeDrawn ~= self.badge then
                f.badgeDrawn = self.badge
                if self.badge then
                    f.badge:SetTexture(self.badge)
                    ns.CropIcon(f.badge)
                    f.badge:Show()
                else
                    f.badge:Hide()
                end
            end
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", wx - T.fw / 2, sy)
        end
    end
    local n = #self.floors
    for i = 1, n do
        local p = self.floors[i]
        drawFloor(p.x + self:Bend(i, n), p.y, i, p.on or 0)
    end
    for i = 1, #self.debris do
        local d = self.debris[i]
        drawFloor(d.x, d.y, d.idx, d.on)
    end
    local vname = self:Var(n + 1).name
    local bkey = skinKey() .. RULES[T.idx].key .. self.mode .. vname
    if view.blockDrawn ~= bkey then
        view.blockDrawn = bkey
        view.blockOk = view.block:SetTexture(format(ART.BLOCK, skinKey(), RULES[T.idx].key, self.mode,
                                                    (vname ~= "") and ("_" .. vname) or ""))
                       and true or false
    end
    if not view.blockOk then
        if self.active then
            drawFloor(self.active.x, self.active.y, n + 1, 0)
        elseif self.phase == "aim" then
            drawFloor(self:CraneX(), self:TopY() + PACE.DROP_H + self:CraneSag(), n + 1, 0)
        end
    end
    floorPool:HideExtras()
    if self.roof and n > 0 and not T.var.cap then
        local rmark = T.key .. skinKey()
        if view.roofT ~= rmark then
            view.roofT = rmark
            shapeRoof(T)
        end
        local sy = self:ScreenY(self:TopY())
        local ra = self:Veil(sy, roofHeight(T) + 6, 40)
        if ra > 0.02 and sy > -80 and sy < self.H + 20 then
            view.roof:SetAlpha(ra)
            view.roof:ClearAllPoints()
            view.roof:SetPoint("BOTTOM", canvas, "BOTTOMLEFT",
                               self.floors[n].x + self:Bend(n, n), sy)
            view.roof:Show()
        else
            view.roof:Hide()
        end
    else
        view.roof:Hide()
    end
    resPool:Reset()
    for i = 1, #self.residents do
        local r = self.residents[i]
        local p = self.floors[r.fi]
        if p then
            local sy = self:ScreenY(r.y)
            if sy > 0 and sy < self.H + 40 then
                local f = resPool:Acquire()
                if f.badgeDrawn ~= self.rider then
                    f.badgeDrawn = self.rider
                    f.figDrawn = nil
                    if self.rider then
                        f.badge:SetTexture(self.rider)
                        ns.CropIcon(f.badge)
                        f.badge:Show()
                        for k = 1, #f.man do f.man[k]:Hide() end
                    else
                        f.badge:Hide()
                    end
                end
                if not self.rider then
                    local list = (r.hero and T.hero) or T.folk or RES_FOLK_DEF
                    local F = list[1 + (r.w - 1) % #list]
                    if f.figDrawn ~= F then
                        f.figDrawn = F
                        dress(f, F, T.chute or RES_CHUTE_DEF)
                    end
                end
                local x = p.x + self:Bend(r.fi, n) + (self:Var(r.fi).winOff[r.s] or 0)
                          + RES_SWAY * sin(r.t * 1.7)
                f:ClearAllPoints()
                f:SetPoint("BOTTOM", canvas, "BOTTOMLEFT", x, sy)
            end
        end
    end
    resPool:HideExtras()
    for i = 1, FORM.POPS do
        local p, fs = self.pops and self.pops[i], view.pop[i]
        if p then
            local k = p.t / FORM.POP_LIFE
            fs:SetText("+" .. p.n)
            fs:SetTextColor(1, 0.88, 0.45)
            fs:SetAlpha(1 - k * k)
            fs:ClearAllPoints()
            fs:SetPoint("BOTTOM", view.top, "BOTTOMLEFT", p.x,
                        self:ScreenY(p.y) + 6 + FORM.POP_RISE * k)
            fs:Show()
        else
            fs:Hide()
        end
    end
    if (self.combo or 0) > 1 and self.phase ~= "menu" then
        view.combo:SetText("x" .. self.combo)
        view.combo:SetTextColor(PAL.GOLD[1], PAL.GOLD[2], PAL.GOLD[3])
        view.combo:Show()
        view.comboBar:SetWidth(max(1, 58 * self.comboT / FORM.COMBO_TIME))
        view.comboBar:Show()
    else
        view.combo:Hide()
        view.comboBar:Hide()
    end
    local bx, by, brot
    if self.active then
        bx = self.active.x
        by = self:ScreenY(self.active.y) + T.fh / 2
        brot = self.active.rot or 0
    elseif self.phase == "aim" then
        bx = self:CraneX()
        by = self:ScreenY(self:TopY() + PACE.DROP_H) + self:CraneSag() + T.fh / 2
    end
    if bx then
        local ux, uy, rot = 0, 1, 0
        if view.blockOk then
            if view.blockBadgeDrawn ~= self.badge then
                view.blockBadgeDrawn = self.badge
                if self.badge then
                    view.blockBadge:SetTexture(self.badge)
                    ns.CropIcon(view.blockBadge)
                end
            end
            ux, uy, rot = self:CraneUp(bx, by)
            if brot then rot = brot end
            view.block:ClearAllPoints()
            view.block:SetPoint("CENTER", canvas, "BOTTOMLEFT", bx, by)
            view.block:SetRotation(rot)
            view.block:Show()
            if self.badge then
                view.blockBadge:ClearAllPoints()
                view.blockBadge:SetPoint("CENTER", canvas, "BOTTOMLEFT", bx, by)
                view.blockBadge:SetRotation(rot)
                view.blockBadge:Show()
            else
                view.blockBadge:Hide()
            end
        else
            view.block:Hide()
            view.blockBadge:Hide()
        end
        if self.phase == "aim" then
            local tx, ty = bx + ux * T.fh / 2, by + uy * T.fh / 2
            local hx, hy = tx + ux * ART.RIG.HOOK_UP, ty + uy * ART.RIG.HOOK_UP
            view.hook:ClearAllPoints()
            view.hook:SetPoint("CENTER", canvas, "BOTTOMLEFT", hx, hy)
            view.hook.tex:SetRotation(rot)
            view.hook:Show()
            local kx, ky = hx + ux * ART.RIG.HOOK_TOP, hy + uy * ART.RIG.HOOK_TOP
            local ropeY = ART.RIG.JIB_Y - ART.RIG.TROLLEY_H
            local xt = kx
            if ky < ropeY - 1 then
                local t = (ropeY - FORM.PIVOT_SY) / (ky - FORM.PIVOT_SY)
                xt = PACE.CENTER_X + (kx - PACE.CENTER_X) * t
                line(view.cable[1], xt, ropeY, kx, ky)
            else
                view.cable[1]:Hide()
            end
            view.trolley:ClearAllPoints()
            view.trolley:SetPoint("BOTTOMLEFT", view.rig, "BOTTOMLEFT", xt - ART.RIG.TROLLEY_W / 2, ropeY)
            view.trolleyHi:ClearAllPoints()
            view.trolleyHi:SetPoint("BOTTOMLEFT", view.rig, "BOTTOMLEFT", xt - ART.RIG.TROLLEY_W / 2, ART.RIG.JIB_Y - 3)
            view.trolley:Show()
            view.trolleyHi:Show()
            local ex, ey = hx - ux * ART.RIG.HOOK_EYE, hy - uy * ART.RIG.HOOK_EYE
            local e = T.fw * ART.RIG.SLING * 0.5
            for i = 1, 2 do
                local side = (i == 1) and -1 or 1
                line(view.cable[i + 1], ex, ey,
                     tx + side * e * uy - ux * 2, ty - side * e * ux - uy * 2)
            end
        end
    else
        view.block:Hide()
        view.blockBadge:Hide()
    end
    if self.phase ~= "aim" then
        view.hook:Hide()
        view.trolley:Hide()
        view.trolleyHi:Hide()
        for i = 1, 3 do view.cable[i]:Hide() end
    end
end
local function drawFloors(host)
    local T = types()[2]
    local w = host:GetWidth() or 0
    local scale = 0.5
    local fw, fh = T.fw * scale, T.fh * scale
    local ox = max(0, floor((w - fw) / 2))
    local offs = { 0, 9, -5 }
    local lit = { T.wins, T.mid, 1 }
    local litC = T.lit or WIN_ON
    for i = 1, 3 do
        local f = CreateFrame("Frame", nil, host)
        f:SetWidth(fw)
        f:SetHeight(fh)
        f:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", ox + offs[i], 4 + (i - 1) * (fh + 2))
        local p = floorParts(f)
        layFloor(p, T, f, 0, 0, scale)
        tintFloor(p, T, SHADE[i], plainTone)
        for j = 1, T.wins do
            local t = (j <= lit[i]) and litC or (T.off or WIN_OFF)
            p.win[j]:SetTexture(t[1], t[2], t[3], 1)
        end
    end
end
ns.RegisterGame{
    id = ID,
    label = "tower.label",
    look = LOOK,
    icon = { tex = "Interface\\Icons\\INV_Crate_03", coord = { 0, 1, 0, 1 } },
    tip = "tower.tip",
    order = 13,
    duo = "none",
    physics = true,
    fx = true,
    ownPanel = true,
    finale = true,
    New = New,
    record = {
        { key = "score", label = "tower.recPop", by = "max", mark = "token" },
        { key = "floors", label = "tower.recFloors", by = "max", mark = "flask" },
    },
    controls = {
        { action = "fire", label = "tower.ctlDrop", mouse = "LMB" },
    },
    help = {
        "tower.help1",
        { art = drawFloors, h = 46 },
        "tower.help2Sub",
        "tower.help3",
        "tower.help4",
        "tower.help5",
        "tower.help6",
        "tower.help7",
    },
}
