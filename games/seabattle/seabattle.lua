local ADDON, ns = ...
local ID = "seabattle"
local R = ns.seabattle
local floor = math.floor
local W, H = 760, 520
local N = 10
local ART = "Interface\\AddOns\\" .. ADDON .. "\\art\\"
local TEX = {
    ships = ART .. "seabattle_ships.tga",
    marks = ART .. "seabattle_marks.tga",
    sky = ART .. "seabattle_sky.tga",
    white = "Interface\\Buttons\\WHITE8X8",
}
local MARK = { miss = 0, hit = 1, dot = 2, smoke = 3, debris = 4, crestA = 5, crestH = 6, glow = 7 }
local L = {
    LAB = 18, PAD = 4, SIDE = 16,
    HEAD_Y = 12, HEAD_H = 44, HEAD_PANEL_W = 240, HEAD_PANEL_H = 44,
    BOARD_Y = 67,
    FOOT_Y = 423, FOOT_H = 26, ROWS_Y = 457, ROW_H = 16, ROW_GAP = 12,
    TIMER_W = 10, RESIGN_W = 100,
    HANGAR_ROW0 = 20, HANGAR_ROW_H = 64, HANGAR_X = 22, BTN_W = 200, BTN_H = 26,
    CREST_W = 26, CREST_H = 30,
    SETUP_LIMIT = 90, SHOT_LIMIT = 30, BOT_THINK = 1.0, BOT_ANS = 0.4,
    GHOST_DX = -6, GHOST_DY = -8, HALO = 3, DIM = 0.7,
}
local M = {
    TITLE_Y = 30, PANEL_X = 230, PANEL_Y = 248, PANEL_W = 300, PANEL_H = 214,
    SLOT_W = 66, SLOT_H = 40, SLOT_GAP = 6, SLOT_Y = 264, DESC_Y = 312, WHO_Y = 344, SCORE_Y = 364,
    PLAY_Y = 390, PLAY_W = 220, PLAY_H = 30, NOTE_Y = 428,
    SHIPS = {
        { 1, 4, 40, 100, 270, 68 }, { 2, 4, 452, 134, 270, 68, true },
        { 1, 2, 318, 90, 86, 43 }, { 2, 1, 392, 200, 40, 40, true },
        { 1, 1, 142, 206, 36, 36 }, { 2, 3, 614, 78, 114, 38, true },
    },
}
local SKIES = {
    { key = "seabattle.skyDay",
      sky1 = { 0.039, 0.114, 0.200 }, sky2 = { 0.184, 0.431, 0.659 }, sky3 = { 0.765, 0.871, 0.941 },
      cloud = { 0.953, 0.976, 1 }, cloud2 = { 0.714, 0.824, 0.918 },
      cit = { 0.102, 0.157, 0.220 }, cit2 = { 0.204, 0.325, 0.435 },
      ice = { 0.561, 0.737, 0.839 }, ice2 = { 0.886, 0.945, 0.973 },
      frame = { 0.365, 0.506, 0.616 }, frame2 = { 0.875, 0.933, 0.973 }, frame3 = { 0.122, 0.200, 0.275 },
      cell = { 0.784, 0.894, 0.980, 0.17 }, line = { 0.886, 0.953, 1, 0.5 },
      label = { 0.918, 0.965, 1 }, accent = { 0.925, 0.780, 0.388 }, panel = { 0.035, 0.086, 0.149, 0.74 },
      text = { 0.910, 0.945, 0.980 }, puff = { 0.969, 0.988, 1 }, dot = { 0.902, 0.961, 1 }, timer = { 0.498, 0.831, 1 },
      ok = { 0.373, 0.922, 0.490, 0.55 }, bad = { 0.941, 0.275, 0.235, 0.62 }, wreck = { 0.30, 0.32, 0.38 },
      sun = false, stars = false },
    { key = "seabattle.skyDusk",
      sky1 = { 0.165, 0.082, 0.216 }, sky2 = { 0.706, 0.271, 0.173 }, sky3 = { 0.965, 0.757, 0.451 },
      cloud = { 1, 0.839, 0.678 }, cloud2 = { 0.788, 0.416, 0.333 },
      cit = { 0.075, 0.051, 0.071 }, cit2 = { 0.176, 0.122, 0.157 },
      ice = { 0.420, 0.278, 0.337 }, ice2 = { 0.820, 0.565, 0.467 },
      frame = { 0.235, 0.176, 0.165 }, frame2 = { 0.847, 0.655, 0.263 }, frame3 = { 0.071, 0.043, 0.051 },
      cell = { 0.063, 0.039, 0.055, 0.55 }, line = { 0.847, 0.655, 0.263, 0.42 },
      label = { 0.965, 0.875, 0.682 }, accent = { 0.949, 0.773, 0.325 }, panel = { 0.063, 0.035, 0.051, 0.8 },
      text = { 0.969, 0.910, 0.796 }, puff = { 1, 0.953, 0.890 }, dot = { 0.965, 0.875, 0.682 }, timer = { 1, 0.702, 0.278 },
      ok = { 0.471, 0.922, 0.431, 0.55 }, bad = { 1, 0.314, 0.235, 0.62 }, wreck = { 0.30, 0.26, 0.26 },
      sun = true, stars = false },
    { key = "seabattle.skyNight",
      sky1 = { 0.008, 0.016, 0.043 }, sky2 = { 0.039, 0.102, 0.220 }, sky3 = { 0.106, 0.290, 0.400 },
      cloud = { 0.165, 0.282, 0.408 }, cloud2 = { 0.075, 0.145, 0.235 },
      cit = { 0.016, 0.024, 0.043 }, cit2 = { 0.055, 0.082, 0.133 },
      ice = { 0.141, 0.271, 0.376 }, ice2 = { 0.294, 0.494, 0.604 },
      frame = { 0.173, 0.180, 0.208 }, frame2 = { 0.812, 0.612, 0.294 }, frame3 = { 0.035, 0.039, 0.055 },
      cell = { 0.157, 0.376, 0.549, 0.22 }, line = { 0.471, 0.871, 1, 0.36 },
      label = { 0.769, 0.941, 1 }, accent = { 0.863, 0.682, 0.345 }, panel = { 0.016, 0.031, 0.063, 0.8 },
      text = { 0.886, 0.961, 1 }, puff = { 0.886, 0.925, 0.969 }, dot = { 0.643, 0.878, 1 }, timer = { 0.373, 0.941, 0.847 },
      ok = { 0.353, 0.941, 0.588, 0.5 }, bad = { 1, 0.275, 0.275, 0.6 }, wreck = { 0.26, 0.28, 0.34 },
      sun = false, stars = true },
}
local CLOUDS = {
    { 70, 150, 1.2 }, { 210, 110, 0.8 }, { 340, 175, 1.4 }, { 480, 120, 1 }, { 600, 185, 0.9 },
    { 120, 285, 1.1 }, { 390, 300, 1.3 }, { 570, 290, 0.8 }, { 260, 240, 0.7 }, { 40, 385, 1 },
    { 640, 400, 1.2 }, { 330, 420, 1.1 }, { 180, 380, 0.75 },
}
local STARS = 60
local SX, SY = W / 640, H / 480
local C = {
    dim = { 0.60, 0.62, 0.68 }, live = { 0.44, 0.75, 0.36 }, warn = { 0.90, 0.68, 0.20 },
    gone = { 0.55, 0.52, 0.48 }, red = { 1, 0.35, 0.3 }, white = { 1, 1, 1 },
    last = { 1, 0.85, 0.30, 0.55 }, odd = { 1, 0.2, 0.2, 0.45 }, aurora = { 0.29, 0.94, 0.69 },
    lostDeck = { 1, 0.55, 0.3 }, lastFill = { 1, 0.85, 0.30, 0.22 }, pend = { 1, 0.45, 0.25 },
}
local FOES = {
    { key = "nov", label = "seabattle.foeNovLabel", name = "seabattle.foeNovName", desc = "seabattle.foeNovDesc" },
    { key = "cap", label = "seabattle.foeCapLabel", name = "seabattle.foeCapName", desc = "seabattle.foeCapDesc" },
    { key = "adm", label = "seabattle.foeAdmLabel", name = "seabattle.foeAdmName", desc = "seabattle.foeAdmDesc" },
    { key = "duo", label = "seabattle.foeDuoLabel", name = "seabattle.foeDuoName", desc = "seabattle.foeDuoDesc" },
}
local DEF_FOE = "duo"
local SHIP_KEY = { { "seabattle.shipA4", "seabattle.shipA3", "seabattle.shipA2", "seabattle.shipA1" },
                   { "seabattle.shipH4", "seabattle.shipH3", "seabattle.shipH2", "seabattle.shipH1" } }
local FAC_KEY = { "seabattle.facA", "seabattle.facH" }
local LOOK = ns.MakeLook{ wood = { 0.160, 0.220, 0.300 }, edge = { 0.93, 0.78, 0.39 }, screen = { 0.039, 0.114, 0.200 } }
local FLEETS = {}
local pendingNote
local function foeBy(key)
    local fallback
    for _, f in ipairs(FOES) do
        if f.key == key then return f end
        if f.key == DEF_FOE then fallback = f end
    end
    return fallback or FOES[1]
end
local function shipName(fac, n)
    return ns.T(SHIP_KEY[fac][5 - n])
end
local function paint(tex, c, a)
    ns.Paint(tex, c[1], c[2], c[3], a or c[4] or 1)
end
local function tint(tex, c, a)
    tex:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
end
local function ink(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local function shipCoord(tex, fac, n, d, mirror)
    local row = (fac - 1) * 4 + (4 - n)
    local u0, u1 = 0, n * 64 / 256
    local v0, v1 = row * 64 / 512, (row + 1) * 64 / 512
    if mirror then u0, u1 = u1, u0 end
    tex:SetTexture(TEX.ships)
    if d == "v" then
        tex:SetTexCoord(u0, v1, u1, v1, u0, v0, u1, v0)
    else
        tex:SetTexCoord(u0, u1, v0, v1)
    end
end
local function markCoord(tex, slot)
    local col, row = slot % 4, floor(slot / 4)
    tex:SetTexture(TEX.marks)
    tex:SetTexCoord(col / 4, (col + 1) / 4, row / 2, (row + 1) / 2)
end
local function crestCoord(tex, fac)
    markCoord(tex, fac == 1 and MARK.crestA or MARK.crestH)
end
local Game = {}
Game.__index = Game
local ui, boards, menu, sky
local function makeShip(parent)
    local f = ns.PlainFrame(parent, 1)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    return f
end
local function makeMark(parent)
    local f = ns.PlainFrame(parent, 1)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    return f
end
local function makeFill(parent)
    local f = ns.PlainFrame(parent, 1)
    f.tex = ns.Fill(f, "ARTWORK", 1, 1, 1, 1)
    f.tex:SetAllPoints(f)
    return f
end
local function edgeBox(f, w, layer)
    local e = {}
    local function bar(p1, p2, ww, hh)
        local t = ns.Fill(f, layer or "BORDER", 1, 1, 1, 1)
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if ww then t:SetWidth(ww) end
        if hh then t:SetHeight(hh) end
        e[#e + 1] = t
    end
    bar("TOPLEFT", "TOPRIGHT", nil, w)
    bar("BOTTOMLEFT", "BOTTOMRIGHT", nil, w)
    bar("TOPLEFT", "BOTTOMLEFT", w, nil)
    bar("TOPRIGHT", "BOTTOMRIGHT", w, nil)
    return e
end
local function cellBox(parent, w, filled)
    local f = ns.PlainFrame(parent, 4)
    f.edge = edgeBox(f, w, "ARTWORK")
    if filled then
        f.plate = ns.Fill(f, "BORDER", 1, 1, 1, 1)
        f.plate:SetAllPoints(f)
    end
    f:Hide()
    return f
end
local function paintBox(f, c, a)
    for _, t in ipairs(f.edge) do paint(t, c, 1) end
    if f.plate then paint(f.plate, c, a or 0.22) end
    if f.cross then
        for _, t in ipairs(f.cross) do paint(t, c, 1) end
    end
end
local function makePanel(parent, level)
    local f = ns.PlainFrame(parent, level or 1)
    f.plate = ns.Fill(f, "BACKGROUND", 0, 0, 0, 0.7)
    f.plate:SetAllPoints(f)
    f.edge = edgeBox(f, 1)
    return f
end
local function paintPanel(f, sk, edgeCol)
    paint(f.plate, sk.panel)
    for _, t in ipairs(f.edge) do paint(t, edgeCol or sk.frame, 1) end
end
local function fitTex(t, x, y, w, h, u0, u1, v0, v1)
    local x0, y0, x1, y1 = x, y, x + w, y + h
    if x0 < 0 then x0 = 0 end
    if y0 < 0 then y0 = 0 end
    if x1 > W then x1 = W end
    if y1 > H then y1 = H end
    t:SetWidth(x1 - x0)
    t:SetHeight(y1 - y0)
    t:SetPoint("TOPLEFT", sky, "TOPLEFT", x0, -y0)
    local du, dv = u1 - u0, v1 - v0
    t:SetTexCoord(u0 + du * (x0 - x) / w, u0 + du * (x1 - x) / w, v0 + dv * (y0 - y) / h, v0 + dv * (y1 - y) / h)
end
local function buildSky(canvas)
    sky = ns.PlainFrame(canvas, 1)
    sky:SetAllPoints(canvas)
    sky.top = sky:CreateTexture(nil, "BACKGROUND")
    sky.top:SetTexture(TEX.white)
    sky.top:SetPoint("TOPLEFT", sky, "TOPLEFT", 0, 0)
    sky.top:SetPoint("TOPRIGHT", sky, "TOPRIGHT", 0, 0)
    sky.top:SetHeight(floor(H * 0.52))
    sky.bot = sky:CreateTexture(nil, "BACKGROUND")
    sky.bot:SetTexture(TEX.white)
    sky.bot:SetPoint("TOPLEFT", sky.top, "BOTTOMLEFT", 0, 0)
    sky.bot:SetPoint("BOTTOMRIGHT", sky, "BOTTOMRIGHT", 0, 0)
    sky.stars = {}
    local rng = ns.RNG.New(7)
    for k = 1, STARS do
        local t = sky:CreateTexture(nil, "BORDER")
        markCoord(t, MARK.dot)
        local s = (rng:Int(5) == 1) and 7 or 4
        t:SetWidth(s)
        t:SetHeight(s)
        t:SetPoint("TOPLEFT", sky, "TOPLEFT", rng:Int(W - 8), -rng:Int(floor(H * 0.6)))
        t.a = 0.4 + rng:Float() * 0.6
        sky.stars[k] = t
    end
    sky.aurora = {}
    for k = 1, 2 do
        local t = sky:CreateTexture(nil, "BORDER")
        t:SetTexture(TEX.sky)
        t:SetBlendMode("ADD")
        fitTex(t, -100 + (k - 1) * 60, 70 + (k - 1) * 50, W + 200, k == 1 and 70 or 50,
            k == 1 and 0 or 0.5, k == 1 and 0.5 or 1, 0, 0.5)
        sky.aurora[k] = t
    end
    sky.sun = {}
    for k = 1, 3 do
        local t = sky:CreateTexture(nil, "BORDER")
        markCoord(t, MARK.glow)
        local d = ({ 150, 110, 76 })[k]
        t:SetWidth(d)
        t:SetHeight(d)
        t:SetPoint("CENTER", sky, "TOPLEFT", floor(470 * SX), -floor(300 * SY))
        sky.sun[k] = t
    end
    sky.clouds = {}
    for k, c in ipairs(CLOUDS) do
        local w = floor(56 * c[3] * SX)
        local h = floor(w / 2)
        local x, y = floor(c[1] * SX - w / 2), floor(c[2] * SY - h * 0.6)
        local u0, u1 = (k % 2 == 0) and 0.5 or 0, (k % 2 == 0) and 1 or 0.5
        local pair = {}
        for j = 1, 2 do
            local t = sky:CreateTexture(nil, "ARTWORK")
            t:SetTexture(TEX.sky)
            fitTex(t, x, y + (j == 1 and 4 or 0), w, h, u0, u1, 0, 0.5)
            pair[j] = t
        end
        sky.clouds[k] = pair
    end
    sky.ice = sky:CreateTexture(nil, "BORDER")
    sky.ice:SetTexture(TEX.white)
    sky.ice:SetPoint("BOTTOMLEFT", sky, "BOTTOMLEFT", 0, 0)
    sky.ice:SetPoint("BOTTOMRIGHT", sky, "BOTTOMRIGHT", 0, 0)
    sky.ice:SetHeight(floor(48 * SY))
    sky.far = sky:CreateTexture(nil, "ARTWORK")
    sky.far:SetTexture(TEX.sky)
    fitTex(sky.far, -70, H - 30 - 150, W + 160, 150, 0, 1, 0.5, 1)
    sky.near = sky:CreateTexture(nil, "OVERLAY")
    sky.near:SetTexture(TEX.sky)
    fitTex(sky.near, 0, H - 216, W, 216, 0, 1, 0.5, 1)
    sky.beacon = sky:CreateTexture(nil, "OVERLAY")
    sky.beacon:SetTexture(TEX.white)
    sky.beacon:SetWidth(2)
    sky.beacon:SetHeight(18)
    sky.beacon:SetPoint("BOTTOM", sky, "BOTTOMLEFT", floor(276 * SX), 206)
end
local function paintSky(sk)
    ns.Gradient(sky.top, "VERTICAL", sk.sky2[1], sk.sky2[2], sk.sky2[3], 1, sk.sky1[1], sk.sky1[2], sk.sky1[3], 1)
    ns.Gradient(sky.bot, "VERTICAL", sk.sky3[1], sk.sky3[2], sk.sky3[3], 1, sk.sky2[1], sk.sky2[2], sk.sky2[3], 1)
    for _, t in ipairs(sky.stars) do
        if sk.stars then
            tint(t, C.white, t.a)
            t:Show()
        else
            t:Hide()
        end
    end
    for k, t in ipairs(sky.aurora) do
        if sk.stars then
            tint(t, C.aurora, k == 1 and 0.22 or 0.14)
            t:Show()
        else
            t:Hide()
        end
    end
    for k, t in ipairs(sky.sun) do
        if sk.sun then
            tint(t, { 1, 0.86, 0.5 }, ({ 0.35, 0.5, 1 })[k])
            t:Show()
        else
            t:Hide()
        end
    end
    for _, pair in ipairs(sky.clouds) do
        tint(pair[1], sk.cloud2)
        tint(pair[2], sk.cloud)
    end
    ns.Gradient(sky.ice, "VERTICAL", sk.ice[1], sk.ice[2], sk.ice[3], 1, sk.ice2[1], sk.ice2[2], sk.ice2[3], 1)
    tint(sky.far, sk.cit2)
    tint(sky.near, sk.cit)
    tint(sky.beacon, { 0.62, 0.91, 1 }, 0.7)
end
local function buildBoard(canvas, cell)
    local bd = ns.PlainFrame(canvas, 2)
    local gw = N * cell + 1
    bd.size = L.PAD * 2 + L.LAB + gw
    bd.cell = cell
    bd:SetWidth(bd.size)
    bd:SetHeight(bd.size)
    bd.plate = ns.Fill(bd, "BACKGROUND", 0, 0, 0, 0.7)
    bd.plate:SetAllPoints(bd)
    bd.outer = edgeBox(bd, 1, "BORDER")
    bd.inner = ns.PlainFrame(bd, 1)
    bd.inner:SetPoint("TOPLEFT", bd, "TOPLEFT", 1, -1)
    bd.inner:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", -1, 1)
    bd.innerEdge = edgeBox(bd.inner, 2, "BORDER")
    bd.cols, bd.rows = {}, {}
    for k = 1, N do
        local fs = bd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetWidth(cell)
        fs:SetHeight(L.LAB)
        fs:SetJustifyH("CENTER")
        fs:SetPoint("TOPLEFT", bd, "TOPLEFT", L.PAD + L.LAB + 1 + (k - 1) * cell, -L.PAD)
        bd.cols[k] = fs
        local rs = bd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rs:SetWidth(L.LAB)
        rs:SetHeight(cell)
        rs:SetJustifyH("CENTER")
        rs:SetPoint("TOPLEFT", bd, "TOPLEFT", L.PAD, -(L.PAD + L.LAB + 1 + (k - 1) * cell))
        rs:SetText(k)
        bd.rows[k] = rs
    end
    bd.grid = ns.PlainFrame(bd, 1)
    bd.grid:SetWidth(gw)
    bd.grid:SetHeight(gw)
    bd.grid:SetPoint("TOPLEFT", bd, "TOPLEFT", L.PAD + L.LAB, -(L.PAD + L.LAB))
    bd.gridPlate = ns.Fill(bd.grid, "BACKGROUND", 1, 1, 1, 0.5)
    bd.gridPlate:SetAllPoints(bd.grid)
    bd.cells = {}
    for i = 1, R.CELLS do
        local c, r = R.cr(i)
        local t = ns.Fill(bd.grid, "BORDER", 1, 1, 1, 0.2)
        t:SetWidth(cell - 1)
        t:SetHeight(cell - 1)
        t:SetPoint("TOPLEFT", bd.grid, "TOPLEFT", 1 + (c - 1) * cell, -(1 + (r - 1) * cell))
        bd.cells[i] = t
    end
    bd.under = ns.PlainFrame(bd.grid, 1)
    bd.under:SetAllPoints(bd.grid)
    bd.shipsL = ns.PlainFrame(bd.grid, 2)
    bd.shipsL:SetAllPoints(bd.grid)
    bd.marksL = ns.PlainFrame(bd.grid, 3)
    bd.marksL:SetAllPoints(bd.grid)
    bd.fills = ns.NewPool(function() return makeFill(bd.under) end)
    bd.ships = ns.NewPool(function() return makeShip(bd.shipsL) end)
    bd.marks = ns.NewPool(function() return makeMark(bd.marksL) end)
    bd.halo = ns.PlainFrame(bd, 5)
    bd.halo:SetAllPoints(bd)
    bd.halo.edge = edgeBox(bd.halo, L.HALO, "ARTWORK")
    bd.halo.far = ns.PlainFrame(bd.halo, 0)
    bd.halo.far:SetPoint("TOPLEFT", bd, "TOPLEFT", -L.HALO, L.HALO)
    bd.halo.far:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", L.HALO, -L.HALO)
    bd.halo.far.edge = edgeBox(bd.halo.far, L.HALO, "ARTWORK")
    bd.halo.far:SetAlpha(0.35)
    bd.halo:Hide()
    bd.lastBox = cellBox(bd.grid, 2, true)
    bd.aim = cellBox(bd.grid, 2, false)
    bd.aim.cross = {}
    for k = 1, 2 do
        local t = ns.Fill(bd.aim, "ARTWORK", 1, 1, 1, 1)
        if k == 1 then
            t:SetPoint("TOP", bd.aim, "TOP", 0, -2)
            t:SetPoint("BOTTOM", bd.aim, "BOTTOM", 0, 2)
            t:SetWidth(1)
        else
            t:SetPoint("LEFT", bd.aim, "LEFT", 2, 0)
            t:SetPoint("RIGHT", bd.aim, "RIGHT", -2, 0)
            t:SetHeight(1)
        end
        bd.aim.cross[k] = t
    end
    return bd
end
local function paintBoard(bd, sk)
    paint(bd.plate, sk.panel)
    for _, t in ipairs(bd.outer) do paint(t, sk.frame2, 1) end
    for _, t in ipairs(bd.innerEdge) do paint(t, sk.frame, 1) end
    paint(bd.gridPlate, sk.line)
    for i = 1, R.CELLS do paint(bd.cells[i], sk.cell) end
    for k = 1, N do
        ink(bd.cols[k], sk.label)
        ink(bd.rows[k], sk.label)
    end
    for _, t in ipairs(bd.halo.edge) do paint(t, sk.accent, 1) end
    for _, t in ipairs(bd.halo.far.edge) do paint(t, sk.accent, 1) end
    paintBox(bd.lastBox, C.last, 0.22)
    paintBox(bd.aim, sk.accent)
end
local function boardFocus(bd, on, dim)
    if on then bd.halo:Show() else bd.halo:Hide() end
    bd:SetAlpha(dim and L.DIM or 1)
end
local function boardReset(bd)
    bd.fills:Reset()
    bd.ships:Reset()
    bd.marks:Reset()
end
local function boardFlush(bd)
    bd.fills:HideExtras()
    bd.ships:HideExtras()
    bd.marks:HideExtras()
end
local function boardHide(bd)
    bd:Hide()
    bd.fills:HideAll()
    bd.ships:HideAll()
    bd.marks:HideAll()
end
local function cellXY(bd, i)
    local c, r = R.cr(i)
    return 1 + (c - 1) * bd.cell, 1 + (r - 1) * bd.cell
end
local function placeBox(bd, f, i)
    if not i then
        f:Hide()
        return
    end
    local x, y = cellXY(bd, i)
    f:ClearAllPoints()
    f:SetWidth(bd.cell - 1)
    f:SetHeight(bd.cell - 1)
    f:SetPoint("TOPLEFT", bd.grid, "TOPLEFT", x, -y)
    f:Show()
end
local function putShip(bd, ship, fac, col, alpha, mirror)
    local f = bd.ships:Acquire()
    local x, y = cellXY(bd, ship.s)
    local w, h = ship.n * bd.cell - 1, bd.cell - 1
    if ship.d == "v" then w, h = h, w end
    f:ClearAllPoints()
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetPoint("TOPLEFT", bd.grid, "TOPLEFT", x, -y)
    shipCoord(f.tex, fac, ship.n, ship.d, mirror)
    tint(f.tex, col or C.white, 1)
    f:SetAlpha(alpha or 1)
    return f
end
local function putMark(bd, i, slot, col, alpha)
    local f = bd.marks:Acquire()
    local x, y = cellXY(bd, i)
    f:ClearAllPoints()
    f:SetWidth(bd.cell - 1)
    f:SetHeight(bd.cell - 1)
    f:SetPoint("TOPLEFT", bd.grid, "TOPLEFT", x, -y)
    markCoord(f.tex, slot)
    tint(f.tex, col or C.white, alpha or 1)
    return f
end
local function putFill(bd, i, col)
    local f = bd.fills:Acquire()
    local x, y = cellXY(bd, i)
    f:ClearAllPoints()
    f:SetWidth(bd.cell - 1)
    f:SetHeight(bd.cell - 1)
    f:SetPoint("TOPLEFT", bd.grid, "TOPLEFT", x, -y)
    paint(f.tex, col)
    return f
end
local function buildHead(canvas)
    local hd = ns.PlainFrame(canvas, 3)
    hd:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -L.HEAD_Y)
    hd:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", 0, -L.HEAD_Y)
    hd:SetHeight(L.HEAD_H)
    hd.side = {}
    for k = 1, 2 do
        local s = {}
        s.crest = hd:CreateTexture(nil, "ARTWORK")
        s.crest:SetWidth(L.CREST_W)
        s.crest:SetHeight(L.CREST_H)
        s.name = hd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        s.state = hd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        s.dot = hd:CreateTexture(nil, "OVERLAY")
        markCoord(s.dot, MARK.dot)
        s.dot:SetWidth(12)
        s.dot:SetHeight(12)
        if k == 1 then
            s.crest:SetPoint("TOPLEFT", hd, "TOPLEFT", L.SIDE, -4)
            s.name:SetPoint("TOPLEFT", hd, "TOPLEFT", L.SIDE + L.CREST_W + 8, -6)
            s.name:SetJustifyH("LEFT")
            s.dot:SetPoint("TOPLEFT", hd, "TOPLEFT", L.SIDE + L.CREST_W + 6, -22)
            s.state:SetPoint("TOPLEFT", hd, "TOPLEFT", L.SIDE + L.CREST_W + 18, -24)
            s.state:SetJustifyH("LEFT")
        else
            s.crest:SetPoint("TOPRIGHT", hd, "TOPRIGHT", -L.SIDE, -4)
            s.name:SetPoint("TOPRIGHT", hd, "TOPRIGHT", -(L.SIDE + L.CREST_W + 8), -6)
            s.name:SetJustifyH("RIGHT")
            s.dot:SetPoint("TOPRIGHT", hd, "TOPRIGHT", -(L.SIDE + L.CREST_W + 6), -22)
            s.state:SetPoint("TOPRIGHT", hd, "TOPRIGHT", -(L.SIDE + L.CREST_W + 18), -24)
            s.state:SetJustifyH("RIGHT")
        end
        s.name:SetWidth(190)
        s.state:SetWidth(180)
        hd.side[k] = s
    end
    hd.panel = makePanel(hd, 1)
    hd.panel:SetWidth(L.HEAD_PANEL_W)
    hd.panel:SetHeight(L.HEAD_PANEL_H)
    hd.panel:SetPoint("TOP", hd, "TOP", 0, -2)
    hd.crest = hd.panel:CreateTexture(nil, "ARTWORK")
    hd.crest:SetWidth(20)
    hd.crest:SetHeight(23)
    hd.crest:SetPoint("LEFT", hd.panel, "LEFT", 8, 0)
    hd.line1 = hd.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hd.line1:SetPoint("TOP", hd.panel, "TOP", 0, -4)
    hd.line1:SetWidth(L.HEAD_PANEL_W - 40)
    hd.line1:SetJustifyH("CENTER")
    hd.line2 = hd.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hd.line2:SetPoint("BOTTOM", hd.panel, "BOTTOM", 0, 5)
    hd.line2:SetWidth(L.HEAD_PANEL_W - 16)
    hd.line2:SetJustifyH("CENTER")
    hd.timerBack = ns.PlainFrame(canvas, 3)
    hd.timerBack:SetWidth(L.TIMER_W)
    hd.timerBack.plate = ns.Fill(hd.timerBack, "BACKGROUND", 0, 0, 0, 1)
    hd.timerBack.plate:SetAllPoints(hd.timerBack)
    hd.timerBack.edge = edgeBox(hd.timerBack, 1)
    hd.timerFill = hd.timerBack:CreateTexture(nil, "ARTWORK")
    hd.timerFill:SetTexture(TEX.white)
    hd.timerFill:SetPoint("BOTTOMLEFT", hd.timerBack, "BOTTOMLEFT", 2, 2)
    hd.timerFill:SetPoint("BOTTOMRIGHT", hd.timerBack, "BOTTOMRIGHT", -2, 2)
    hd.timerText = hd.timerBack:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hd.timerText:SetPoint("BOTTOM", hd.timerBack, "TOP", 0, 2)
    hd.timerText:SetWidth(60)
    hd.timerText:SetJustifyH("CENTER")
    return hd
end
local function buildFoot(canvas)
    local ft = ns.PlainFrame(canvas, 3)
    ft:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -L.FOOT_Y)
    ft:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", 0, 0)
    ft.panel = makePanel(ft, 1)
    ft.panel:SetPoint("TOPLEFT", ft, "TOPLEFT", L.SIDE, 0)
    ft.panel:SetPoint("TOPRIGHT", ft, "TOPRIGHT", -L.SIDE, 0)
    ft.panel:SetHeight(L.FOOT_H)
    ft.crest = ft.panel:CreateTexture(nil, "ARTWORK")
    ft.crest:SetWidth(16)
    ft.crest:SetHeight(18)
    ft.crest:SetPoint("LEFT", ft.panel, "LEFT", 8, 0)
    ft.text = ft.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ft.text:SetPoint("LEFT", ft.panel, "LEFT", 30, 0)
    ft.text:SetWidth(W - 2 * L.SIDE - 30 - L.RESIGN_W - 20)
    ft.text:SetJustifyH("LEFT")
    ft.resign = ns.MakeKitButton(ft.panel)
    ft.resign:SetWidth(L.RESIGN_W)
    ft.resign:SetHeight(L.FOOT_H - 4)
    ft.resign:SetPoint("RIGHT", ft.panel, "RIGHT", -2, 0)
    ft.hint = ft:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ft.hint:SetPoint("TOPLEFT", ft, "TOPLEFT", L.SIDE + 8, -4)
    ft.hint:SetJustifyH("LEFT")
    ft.rows = { {}, {} }
    for side = 1, 2 do
        for k, n in ipairs(R.SIZES) do
            local e = {}
            e.ship = ft:CreateTexture(nil, "ARTWORK")
            e.ship:SetHeight(L.ROW_H)
            e.ship:SetWidth(L.ROW_H * n)
            e.cnt = ft:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            e.cnt:SetJustifyH("LEFT")
            e.hot = ns.PlainFrame(ft, 1)
            e.hot:SetHeight(L.ROW_H)
            e.hot:SetWidth(L.ROW_H * n + 34)
            ft.rows[side][k] = e
        end
    end
    return ft
end
local function placeFootRows(ft, bx)
    for side = 1, 2 do
        local x0 = bx[side] + 8
        local x = { x0, x0 }
        for k, n in ipairs(R.SIZES) do
            local e = ft.rows[side][k]
            local row = (n >= 3) and 1 or 2
            local y = L.ROWS_Y - L.FOOT_Y + (row - 1) * (L.ROW_H + L.ROW_GAP)
            e.ship:ClearAllPoints()
            e.ship:SetPoint("TOPLEFT", ft, "TOPLEFT", x[row], -y)
            e.cnt:ClearAllPoints()
            e.cnt:SetPoint("LEFT", e.ship, "RIGHT", 5, 0)
            e.hot:ClearAllPoints()
            e.hot:SetPoint("TOPLEFT", ft, "TOPLEFT", x[row], -y)
            e.x, e.y = x[row], L.FOOT_Y + y
            x[row] = x[row] + L.ROW_H * n + 44
        end
    end
end
local function buildHangar(canvas)
    local hg = makePanel(canvas, 3)
    hg.rows = {}
    for k, n in ipairs(R.SIZES) do
        local e = {}
        e.hot = ns.Fill(hg, "BORDER", 1, 1, 1, 0.15)
        e.hot:SetPoint("TOPLEFT", hg, "TOPLEFT", 10, -(L.HANGAR_ROW0 + (k - 1) * L.HANGAR_ROW_H - 10))
        e.hot:SetPoint("RIGHT", hg, "RIGHT", -10, 0)
        e.hot:Hide()
        e.ship = hg:CreateTexture(nil, "ARTWORK")
        e.cnt = hg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        e.cnt:SetJustifyH("RIGHT")
        e.cnt:SetPoint("TOPRIGHT", hg, "TOPRIGHT", -24, -(L.HANGAR_ROW0 + (k - 1) * L.HANGAR_ROW_H + 6))
        hg.rows[k] = e
    end
    hg.random = ns.MakeKitButton(hg)
    hg.random:SetWidth(L.BTN_W)
    hg.random:SetHeight(L.BTN_H)
    hg.ready = ns.MakeKitButton(hg)
    hg.ready:SetWidth(L.BTN_W)
    hg.ready:SetHeight(L.BTN_H)
    hg.random:SetPoint("BOTTOM", hg, "BOTTOM", 0, 52)
    hg.ready:SetPoint("BOTTOM", hg, "BOTTOM", 0, 14)
    return hg
end
local function buildGhost(canvas)
    local g = ns.PlainFrame(canvas, 8)
    g.tex = g:CreateTexture(nil, "ARTWORK")
    g.tex:SetAllPoints(g)
    g:Hide()
    return g
end
local cursorXY
local function setupMouse(f)
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(_, button)
        local g = ns.Loop.Current()
        if not g or not g.Press or ns.Loop.IsPaused() then return end
        local x, y = cursorXY(g.canvas)
        if x then g:Press(x, y, button) end
    end)
    f:SetScript("OnMouseUp", function(_, button)
        local g = ns.Loop.Current()
        if not g or not g.Drop or ns.Loop.IsPaused() then return end
        local x, y = cursorXY(g.canvas)
        if x then g:Drop(x, y, button) end
    end)
end
local function buildCatcher(canvas)
    local f = ns.PlainFrame(canvas, 4)
    f:SetAllPoints(canvas)
    setupMouse(f)
    f:Hide()
    return f
end
local function buildHeld(canvas)
    local f = makePanel(canvas, 9)
    f:SetPoint("BOTTOM", canvas, "BOTTOM", 0, 14)
    f:SetHeight(34)
    f:EnableMouse(true)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.text:SetPoint("LEFT", f, "LEFT", 14, 0)
    f.call = ns.MakeKitButton(f)
    f.call:SetWidth(130)
    f.call:SetPoint("LEFT", f.text, "RIGHT", 12, 0)
    f.call.onClick = function() ns.Duo.Resume() end
    f.drop = ns.MakeKitButton(f)
    f.drop:SetWidth(130)
    f.drop:SetPoint("LEFT", f.call, "RIGHT", 8, 0)
    f.drop.onClick = function()
        ns.Duo.GoSolo()
        ns.window:RefreshHead()
    end
    f:Hide()
    return f
end
local function buildMenu(canvas)
    menu = {}
    menu.root = ns.PlainFrame(canvas, 6)
    menu.root:SetAllPoints(canvas)
    menu.root:Hide()
    menu.title = menu.root:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    menu.title:SetPoint("TOP", menu.root, "TOP", 0, -M.TITLE_Y)
    menu.ships = {}
    for k, s in ipairs(M.SHIPS) do
        local t = menu.root:CreateTexture(nil, "ARTWORK")
        shipCoord(t, s[1], s[2], "h", s[7])
        t:SetWidth(s[5])
        t:SetHeight(s[6])
        t:SetPoint("TOPLEFT", menu.root, "TOPLEFT", s[3], -s[4])
        menu.ships[k] = t
    end
    menu.panel = makePanel(menu.root, 1)
    menu.panel:SetWidth(M.PANEL_W)
    menu.panel:SetHeight(M.PANEL_H)
    menu.panel:SetPoint("TOPLEFT", menu.root, "TOPLEFT", M.PANEL_X, -M.PANEL_Y)
    menu.tile = {}
    local total = #FOES * M.SLOT_W + (#FOES - 1) * M.SLOT_GAP
    local x0 = floor((W - total) / 2)
    for i = 1, #FOES do
        local t = ns.MakeSlot(menu.root, LOOK)
        t:SetFrameLevel(menu.panel:GetFrameLevel() + 1)
        t:SetWidth(M.SLOT_W)
        t:SetHeight(M.SLOT_H)
        t:SetPoint("TOPLEFT", menu.root, "TOPLEFT", x0 + (i - 1) * (M.SLOT_W + M.SLOT_GAP), -M.SLOT_Y)
        t.title = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.title:SetPoint("CENTER", t, "CENTER", 0, 0)
        t.title:SetWidth(M.SLOT_W - 6)
        t.title:SetJustifyH("CENTER")
        t:SetScript("OnClick", function()
            local g = ns.Loop.Current()
            if g and g.PickFoe then
                ns.Sfx.Ui()
                g:PickFoe(FOES[i].key)
            end
        end)
        menu.tile[i] = t
    end
    local py = M.PANEL_Y
    menu.desc = menu.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    menu.desc:SetPoint("TOP", menu.panel, "TOP", 0, -(M.DESC_Y - py))
    menu.desc:SetWidth(M.PANEL_W - 30)
    menu.desc:SetJustifyH("CENTER")
    menu.desc:SetJustifyV("TOP")
    menu.who = menu.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menu.who:SetPoint("TOP", menu.panel, "TOP", 0, -(M.WHO_Y - py))
    menu.who:SetWidth(M.PANEL_W - 30)
    menu.who:SetJustifyH("CENTER")
    menu.score = menu.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menu.score:SetPoint("TOP", menu.panel, "TOP", 0, -(M.SCORE_Y - py))
    menu.score:SetWidth(M.PANEL_W - 20)
    menu.score:SetJustifyH("CENTER")
    menu.play = ns.MakeKitButton(menu.root)
    menu.play:SetFrameLevel(menu.panel:GetFrameLevel() + 1)
    menu.play:SetWidth(M.PLAY_W)
    menu.play:SetHeight(M.PLAY_H)
    menu.play:SetPoint("TOP", menu.root, "TOP", 0, -M.PLAY_Y)
    menu.note = menu.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    menu.note:SetPoint("TOP", menu.panel, "TOP", 0, -(M.NOTE_Y - py))
    menu.note:SetWidth(M.PANEL_W - 20)
    menu.note:SetJustifyH("CENTER")
    menu.crest = menu.root:CreateTexture(nil, "ARTWORK")
    menu.crest:SetWidth(22)
    menu.crest:SetHeight(26)
    menu.crest:SetPoint("BOTTOMLEFT", menu.root, "BOTTOMLEFT", 14, 12)
    menu.nick = menu.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menu.nick:SetPoint("LEFT", menu.crest, "RIGHT", 6, 0)
end
local function ensureView(canvas)
    if ui then return end
    ui = {}
    buildSky(canvas)
    local cell = ns.CellFit(N, 320, 0, 0)
    boards = { buildBoard(canvas, cell), buildBoard(canvas, cell) }
    local bw = boards[1].size
    ui.bx = { L.SIDE + L.HALO, W - L.SIDE - L.HALO - bw }
    for k = 1, 2 do
        boards[k]:SetPoint("TOPLEFT", canvas, "TOPLEFT", ui.bx[k], -L.BOARD_Y)
    end
    ui.gridX = { ui.bx[1] + L.PAD + L.LAB, ui.bx[2] + L.PAD + L.LAB }
    ui.gridY = L.BOARD_Y + L.PAD + L.LAB
    ui.head = buildHead(canvas)
    local gapL, gapR = ui.bx[1] + bw, ui.bx[2]
    ui.head.timerBack:SetPoint("TOPLEFT", canvas, "TOPLEFT", floor((gapL + gapR - L.TIMER_W) / 2), -ui.gridY)
    ui.head.timerBack:SetHeight(N * cell + 1)
    ui.foot = buildFoot(canvas)
    placeFootRows(ui.foot, ui.bx)
    ui.catcher = buildCatcher(canvas)
    ui.held = buildHeld(canvas)
    ui.hangar = buildHangar(canvas)
    ui.hangar:SetFrameLevel(canvas:GetFrameLevel() + 5)
    setupMouse(ui.hangar)
    ui.hangar:SetWidth(bw)
    ui.hangar:SetHeight(bw)
    ui.hangar:SetPoint("TOPLEFT", canvas, "TOPLEFT", ui.bx[2], -L.BOARD_Y)
    for k, n in ipairs(R.SIZES) do
        local e = ui.hangar.rows[k]
        e.ship:SetWidth(n * cell - 1)
        e.ship:SetHeight(cell - 1)
        e.ship:SetPoint("TOPLEFT", ui.hangar, "TOPLEFT", L.HANGAR_X, -(L.HANGAR_ROW0 + (k - 1) * L.HANGAR_ROW_H))
        e.hot:SetHeight(cell + 20)
    end
    ui.ghost = buildGhost(canvas)
    ui.tipper = ns.PlainFrame(canvas, 9)
    ui.tipper:SetWidth(1)
    ui.tipper:SetHeight(1)
    buildMenu(canvas)
    ui.canvas = canvas
end
local function hideView()
    if not ui then return end
    sky:Hide()
    boardHide(boards[1])
    boardHide(boards[2])
    ui.head:Hide()
    ui.head.timerBack:Hide()
    ui.foot:Hide()
    ui.hangar:Hide()
    ui.ghost:Hide()
    ui.catcher:Hide()
    ui.held:Hide()
    menu.root:Hide()
    ns.TipHide()
end
cursorXY = function(canvas)
    local s = canvas:GetEffectiveScale()
    local l, t = canvas:GetLeft(), canvas:GetTop()
    if not s or s == 0 or not l or not t then return nil end
    local x, y = GetCursorPosition()
    return x / s - l, t - y / s
end
local function cellAt(side, x, y)
    if not ui then return nil end
    local bd = boards[side]
    local cx, cy = x - (ui.gridX[side] + 1), y - (ui.gridY + 1)
    if cx < 0 or cy < 0 then return nil end
    local c, r = floor(cx / bd.cell) + 1, floor(cy / bd.cell) + 1
    if not R.inside(c, r) then return nil end
    return R.idx(c, r)
end
local function hangarRowAt(x, y)
    if not ui then return nil end
    local hx, hy = ui.bx[2], L.BOARD_Y
    if x < hx or x > hx + boards[1].size then return nil end
    for k, n in ipairs(R.SIZES) do
        local y0 = hy + L.HANGAR_ROW0 + (k - 1) * L.HANGAR_ROW_H - 10
        if y >= y0 and y < y0 + boards[1].cell + 20 then return n end
    end
    return nil
end
local function deckIndex(ship, i)
    local c, r = R.cr(i)
    local sc, sr = R.cr(ship.s)
    if ship.d == "v" then return r - sr end
    return c - sc
end
local function noseFrom(hand, i)
    local c, r = R.cr(i)
    if hand.d == "v" then r = r - hand.k else c = c - hand.k end
    if not R.inside(c, r) then return nil end
    return R.idx(c, r)
end
ns.Duo.OnChange(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    if game.SyncHead then game:SyncHead() end
    if game.SyncMenu then game:SyncMenu() end
end)
ns.Pair.OnChange(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    if game.SyncMenu then game:SyncMenu() end
end)
ns.OnLocale(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    game:Draw()
end)
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
local function botFleet(self)
    if not self.botFleetCache then
        self.botFleetCache = R.generate(ns.RNG.New(self.seed + 101))
    end
    return self.botFleetCache
end
local function apply(self, move)
    local ok = R.apply(self.st, move, self.ctx)
    if ok then self.n = self.n + 1 end
    return ok
end
function Game:Start(seed, moves)
    self.seed = seed
    self.t, self.n = 0, 0
    self.setupT, self.shotT, self.think = 0, 0, 0
    self.hand, self.locked, self.readyWant, self.resignWant = nil, false, false, false
    self.tallied, self.abandon, self.hoverKey, self.aimAt = false, nil, nil, nil
    self.firstShown = true
    self.foe = (self.opts and self.opts.foe) or DEF_FOE
    local restored = moves and #moves > 0
    if not ns.Duo.Active() then ns.Duo.Adopt(ID) end
    local dropped
    if not restored and ns.Duo.Held() then
        dropped = ns.Duo.Peer()
        ns.Duo.GoSolo()
    end
    local duo = ns.Duo.Active() or ns.Duo.Held()
    if duo then self.foe = "duo" end
    local isDuo = (self.foe == "duo")
    self.st = R.newState(seed, isDuo, ns.Duo.Side())
    self.bot = (not isDuo) and (3 - self.st.me) or nil
    self.botFleetCache = nil
    self.parity = ns.RNG.New(seed + 5):Int(2) - 1
    self.ctx = { duo = isDuo, bot = self.bot, botFleet = function() return botFleet(self) end }
    if restored then
        for k = 1, #moves do apply(self, moves[k]) end
    end
    local st, me = self.st, self.st.me
    self.firstShown = (st.shots[1] + st.shots[2] == 0)
    if isDuo then
        st.fleet[me] = FLEETS[seed] or {}
        self.locked = FLEETS[seed] ~= nil or st.ready[me]
    else
        st.fleet[me] = st.fleet[me] or {}
        self.locked = st.ready[me]
    end
    self.readyWant = self.locked and not st.ready[me]
    if isDuo and restored and st.phase ~= "over" then
        if not duo then
            self.abandon = "seabattle.broken"
        elseif st.ready[me] and FLEETS[seed] == nil then
            self.abandon = "seabattle.lostFleet"
        end
    end
    self.menu = not restored and not duo
    if isDuo and not duo then self.menu = true end
    self:Build()
    boards[2].aim:Hide()
    self:Draw()
    local note = pendingNote
    pendingNote = nil
    if note then
        ns.Curtain.Ask(self.canvas, ns.T("seabattle.label"), { ns.T(note) },
            { { label = ns.T("seabattle.heldGoneOk"), onClick = function() ns.Curtain.Hide() end } })
    elseif dropped then
        ns.Curtain.Ask(self.canvas, ns.T("seabattle.label"), { ns.T("seabattle.heldGone", dropped) },
            { { label = ns.T("seabattle.heldGoneOk"), onClick = function() ns.Curtain.Hide() end } })
    end
end
function Game:Build()
    ensureView(self.canvas)
    local sk = SKIES[self.st.sky] or SKIES[1]
    paintSky(sk)
    for k = 1, 2 do paintBoard(boards[k], sk) end
    paintPanel(ui.head.panel, sk, sk.accent)
    paintPanel(ui.foot.panel, sk)
    paintPanel(ui.hangar, sk)
    paintPanel(menu.panel, sk)
    paint(menu.panel.plate, sk.panel, 1)
    paint(ui.head.timerBack.plate, sk.frame3)
    for _, t in ipairs(ui.head.timerBack.edge) do paint(t, sk.frame2, 1) end
    paint(ui.head.timerFill, sk.timer)
    for _, e in ipairs(ui.hangar.rows) do paint(e.hot, sk.cell) end
    ink(ui.head.timerText, sk.accent)
    ink(ui.foot.hint, sk.label)
    ink(menu.title, sk.accent)
    for b = 1, 2 do
        for k = 1, N do boards[b].cols[k]:SetText(ns.T("seabattle.col" .. k)) end
    end
    paintPanel(ui.held, sk, sk.accent)
end
function Game:Frozen()
    return self.menu or self.abandon or ns.Duo.Held() or self.st.phase == "over"
end
function Game:Lock()
    local st = self.st
    self.hand = nil
    self.locked = true
    if self.foe == "duo" then FLEETS[self.seed] = st.fleet[st.me] end
    self.readyWant = true
    ns.TipHide()
end
function Game:RandomFleet()
    if self.locked or self.st.phase ~= "setup" then return end
    local rng = ns.RNG.New(time() + floor((GetTime() % 1) * 1000))
    self.st.fleet[self.st.me] = R.generate(rng)
    self.hand = nil
    ns.Sfx.Play("slide")
    self:Draw()
end
function Game:Ready()
    local st = self.st
    if self.locked or st.phase ~= "setup" then return end
    if #st.fleet[st.me] < 10 or not R.fleetLegal(st.fleet[st.me]) then return end
    self:Lock()
    self:Draw()
end
function Game:AskResign()
    local st = self.st
    if self.resignWant or (st.phase ~= "aim" and st.phase ~= "answer") then return end
    local me = self
    ns.Curtain.Ask(self.canvas, ns.T("seabattle.resign"), { ns.T("seabattle.resignAsk") }, {
        { label = ns.T("seabattle.resignYes"), onClick = function()
            ns.Curtain.Hide()
            me.resignWant = true
            me:Draw()
        end },
        { label = ns.T("seabattle.resignNo"), onClick = function() ns.Curtain.Hide() end },
    })
end
function Game:Move(move)
    local st = self.st
    local prevPhase, prevShooter = st.phase, st.shooter
    local author = R.turn(st)
    if not apply(self, move) then return false end
    local me = st.me
    if move.k == "ready" and st.phase == "aim" then
        ns.Sfx.Play("start")
        self.shotT = 0
        self.firstShown = true
    elseif move.k == "shot" then
        if move.a == 1 and author == me then ns.Sfx.Play("stuck") end
        self.firstShown = false
    elseif move.k == "ans" then
        if st.ans == "miss" then ns.Sfx.Play("pop")
        elseif st.ans == "hit" then ns.Sfx.Play("big")
        else ns.Sfx.Play("clear") end
        if st.phase == "aim" and st.shooter == me and prevShooter ~= me then ns.Sfx.Play("turn") end
        self.shotT = 0
        self.think = 0
    end
    if st.winner and not self.tallied and not st.broke then
        self.tallied = true
        local t = ns.Config.Get(ID, "tally", nil)
        if type(t) ~= "table" then t = {} end
        local b = t[self.foe]
        if type(b) ~= "table" then b = { w = 0, l = 0 } end
        if st.winner == me then b.w = (b.w or 0) + 1 else b.l = (b.l or 0) + 1 end
        t[self.foe] = b
        ns.Config.Set(ID, "tally", t)
    end
    if (st.phase == "reveal" and prevPhase ~= "reveal") or (st.broke and prevPhase ~= "over") then
        ns.Sfx.Play("over")
    end
    if st.resigned then self.resignWant = false end
    self:Draw()
    return true
end
function Game:Click(x, y, button)
    self:Press(x, H - y, button)
end
function Game:Release(x, y, button)
    self:Drop(x, H - y, button)
end
function Game:Press(x, y, button)
    if self:Frozen() then return end
    local st, me = self.st, self.st.me
    if st.phase == "setup" then
        if self.locked then return end
        local fleet = st.fleet[me]
        local i = cellAt(1, x, y)
        if button == "RightButton" then
            if self.hand then
                self.hand.d = (self.hand.d == "h") and "v" or "h"
                if self.hand.n > 1 then ns.Sfx.Play("slide") end
                return
            end
            if not i then return end
            local k = R.shipAt(fleet, i)
            if not k then return end
            local sh = fleet[k]
            if sh.n == 1 then return end
            local hand = { n = sh.n, d = (sh.d == "h") and "v" or "h", k = deckIndex(sh, i) }
            local nose = noseFrom(hand, i)
            if nose and R.canPlace(fleet, { s = nose, d = hand.d, n = sh.n }, k) then
                sh.s, sh.d = nose, hand.d
                ns.Sfx.Play("slide")
            else
                table.remove(fleet, k)
                hand.from = { s = sh.s, d = sh.d }
                self.hand = hand
                ns.Sfx.Play("pick")
                ns.TipHide()
            end
            self:Draw()
            return
        end
        if button ~= "LeftButton" then return end
        if self.hand then
            self:Drop(x, y, "LeftButton")
            return
        end
        if i then
            local k = R.shipAt(fleet, i)
            if not k then return end
            local sh = table.remove(fleet, k)
            self.hand = { n = sh.n, d = sh.d, k = deckIndex(sh, i), from = { s = sh.s, d = sh.d } }
            ns.Sfx.Play("pick")
            ns.TipHide()
            self:Draw()
            return
        end
        local n = hangarRowAt(x, y)
        if n and self:HangarLeft(n) > 0 then
            self.hand = { n = n, d = "h", k = 0 }
            ns.Sfx.Play("pick")
            self:Draw()
        end
        return
    end
    if st.phase ~= "aim" or button ~= "LeftButton" then return end
    if st.shooter ~= me or self.resignWant then return end
    local i = cellAt(2, x, y)
    if not i or st.marks[3 - me][i] ~= R.NONE then return end
    self:Move{ k = "shot", i = i }
end
function Game:Drop(x, y, button)
    local hand = self.hand
    if not hand or button ~= "LeftButton" then return end
    self.hand = nil
    local st = self.st
    local fleet = st.fleet[st.me]
    local i = (st.phase == "setup" and not self.locked) and cellAt(1, x, y) or nil
    local nose = i and noseFrom(hand, i)
    if nose then
        local sh = { s = nose, d = (hand.n == 1) and "h" or hand.d, n = hand.n }
        if R.canPlace(fleet, sh) then
            fleet[#fleet + 1] = sh
            ns.Sfx.Play("slide")
            self:Draw()
            return
        end
        ns.Sfx.Play("deny")
    elseif i then
        ns.Sfx.Play("deny")
    end
    if hand.from then fleet[#fleet + 1] = { s = hand.from.s, d = hand.from.d, n = hand.n } end
    self:Draw()
end
function Game:HangarLeft(n)
    local fleet = self.st.fleet[self.st.me]
    local used = 0
    for _, sh in ipairs(fleet) do
        if sh.n == n then used = used + 1 end
    end
    local left = R.COUNT[n] - used
    if self.hand and self.hand.n == n then left = left - 1 end
    return left
end
local function autoFill(self)
    local st = self.st
    local fleet = st.fleet[st.me]
    if self.hand and self.hand.from then
        fleet[#fleet + 1] = { s = self.hand.from.s, d = self.hand.from.d, n = self.hand.n }
    end
    self.hand = nil
    local rng = ns.RNG.New(time() + floor((GetTime() % 1) * 1000))
    st.fleet[st.me] = R.generate(rng, fleet)
    self:Lock()
    self:Draw()
end
function Game:AfterPeer()
    if self.menu or self.foe ~= "duo" then return end
    local ph = self.st.phase
    if ph == "answer" or ph == "reveal" or ph == "setup" then self:Update(0) end
end
function Game:Update(dt)
    if self.abandon then
        pendingNote = self.abandon
        self.abandon = nil
        ns.Store.Clear(ID)
        ns.window:StartGame(ID, { foe = "duo" })
        ns.Store.Clear(ID)
        return
    end
    if self.menu then return end
    local st, me = self.st, self.st.me
    local isDuo = (self.foe == "duo")
    local held = ns.Duo.Held()
    if isDuo and st.phase ~= "over" and not held and not ns.Duo.Active() then
        self.abandon = "seabattle.broken"
        return
    end
    if not held then self.t = self.t + dt end
    self:Hover()
    if held or st.phase == "over" then return end
    if st.phase == "setup" then
        if isDuo and not self.locked then
            self.setupT = self.setupT + dt
            if self.setupT >= L.SETUP_LIMIT then autoFill(self) end
        end
        if self.readyWant and R.turn(st) == me then
            if isDuo then
                self:Move{ k = "ready" }
            else
                self:Move{ k = "ready", f = R.encode(st.fleet[me]) }
            end
            if st.ready[me] then self.readyWant = false end
        elseif self.bot and R.turn(st) == self.bot then
            self:Move{ k = "ready" }
        end
        return
    end
    if st.phase == "aim" then
        if self.resignWant and st.shooter == me then
            self:Move{ k = "resign" }
            return
        end
        if st.shooter == self.bot then
            self.think = self.think + dt
            if self.think >= L.BOT_THINK then
                self.think = 0
                local rng = ns.RNG.New(self.seed + self.n)
                local i = R.pick(self.foe, st.marks[me], st.left[me], rng, self.parity)
                if i then self:Move{ k = "shot", i = i } end
            end
        elseif isDuo then
            self.shotT = self.shotT + dt
            if st.shooter == me and self.shotT >= L.SHOT_LIMIT then
                local rng = ns.RNG.New(time() + floor((GetTime() % 1) * 1000))
                local all = R.targets(st.marks[3 - me])
                if #all > 0 then self:Move{ k = "shot", i = all[rng:Int(#all)], a = 1 } end
            end
        end
        return
    end
    if st.phase == "answer" then
        local def = 3 - st.shooter
        if self.resignWant and def == me then
            self:Move{ k = "resign" }
            return
        end
        if isDuo and def ~= me then return end
        if st.shooter == self.bot then
            self.think = self.think + dt
            if self.think < L.BOT_ANS then return end
        end
        local fleet = st.fleet[def]
        if not fleet or (def == me and not self.locked) then return end
        local r, sh = R.answer(fleet, st.marks[def], st.shot)
        if r == "kill" then
            self:Move{ k = "ans", r = r, s = sh.s, d = sh.d, n = sh.n }
        else
            self:Move{ k = "ans", r = r }
        end
        return
    end
    if st.phase == "reveal" then
        local win = st.winner
        if isDuo and win ~= me then return end
        local fleet = st.fleet[win]
        if not fleet or #fleet < 10 then return end
        self:Move{ k = "fleet", f = R.encode(fleet) }
    end
end
function Game:Hover()
    if not ui then return end
    local x, y = cursorXY(self.canvas)
    local st, me = self.st, self.st.me
    local key, name, fx, fy, fw, fh
    local pulse = 0.55 + 0.45 * math.sin(self.t * 6)
    boards[1].lastBox:SetAlpha(pulse)
    boards[2].lastBox:SetAlpha(pulse)
    local aimAt
    if x and not self.menu and not self.hand and st.phase == "aim" and st.shooter == me
        and not self.resignWant and not ns.Duo.Held() then
        local i = cellAt(2, x, y)
        if i and st.marks[3 - me][i] == R.NONE then aimAt = i end
    end
    if aimAt ~= self.aimAt then
        self.aimAt = aimAt
        placeBox(boards[2], boards[2].aim, aimAt)
    end
    if self.hand and x then
        local g = ui.ghost
        local bd = boards[1]
        local w, h = self.hand.n * bd.cell - 1, bd.cell - 1
        if self.hand.d == "v" and self.hand.n > 1 then w, h = h, w end
        local ox = (self.hand.d == "v" or self.hand.n == 1) and bd.cell / 2 or (self.hand.k + 0.5) * bd.cell
        local oy = (self.hand.d == "v" and self.hand.n > 1) and (self.hand.k + 0.5) * bd.cell or bd.cell / 2
        g:ClearAllPoints()
        g:SetWidth(w)
        g:SetHeight(h)
        g:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", floor(x - ox + L.GHOST_DX), -floor(y - oy + L.GHOST_DY))
        shipCoord(g.tex, st.fac[me], self.hand.n, (self.hand.n == 1) and "h" or self.hand.d)
        g:Show()
        local i = cellAt(1, x, y)
        local nose = i and noseFrom(self.hand, i)
        if nose ~= self.ghostNose or self.hand.d ~= self.ghostD then
            self.ghostNose, self.ghostD = nose, self.hand.d
            self:Draw()
        end
    else
        ui.ghost:Hide()
        if self.ghostNose then
            self.ghostNose = nil
            self:Draw()
        end
    end
    if x and not self.menu and not self.hand then
        local i = cellAt(1, x, y)
        if i then
            local k = R.shipAt(st.fleet[me] or {}, i)
            if k then
                local sh = st.fleet[me][k]
                key, name = "own" .. k, shipName(st.fac[me], sh.n)
                local cx, cy = cellXY(boards[1], sh.s)
                fx, fy = ui.gridX[1] + cx, ui.gridY + cy
                fw, fh = sh.n * boards[1].cell, boards[1].cell
                if sh.d == "v" then fw, fh = fh, fw end
            end
        else
            i = cellAt(2, x, y)
            if i and st.phase ~= "setup" then
                local foe = 3 - me
                local k = R.shipAt(st.sunk[foe], i)
                local src = k and st.sunk[foe] or (st.phase == "over" and st.fleet[foe] or {})
                k = k or R.shipAt(src, i)
                if k then
                    local sh = src[k]
                    key, name = "foe" .. k .. sh.s, shipName(st.fac[foe], sh.n)
                    local cx, cy = cellXY(boards[2], sh.s)
                    fx, fy = ui.gridX[2] + cx, ui.gridY + cy
                    fw, fh = sh.n * boards[2].cell, boards[2].cell
                    if sh.d == "v" then fw, fh = fh, fw end
                end
            end
        end
        if not key and st.phase ~= "setup" then
            for side = 1, 2 do
                for k, n in ipairs(R.SIZES) do
                    local e = ui.foot.rows[side][k]
                    if x >= e.x and x < e.x + L.ROW_H * n + 34 and y >= e.y and y < e.y + L.ROW_H then
                        local who = (side == 1) and me or (3 - me)
                        key, name = "row" .. side .. n, shipName(st.fac[who], n)
                        fx, fy, fw, fh = e.x, e.y, L.ROW_H * n + 34, L.ROW_H
                    end
                end
            end
        end
        if not key and st.phase == "setup" then
            local n = hangarRowAt(x, y)
            if n then
                key, name = "hangar" .. n, shipName(st.fac[me], n)
                fx, fy = ui.bx[2] + L.HANGAR_X, L.BOARD_Y + L.HANGAR_ROW0 + (4 - n) * L.HANGAR_ROW_H
                fw, fh = n * boards[1].cell, boards[1].cell
            end
        end
    end
    if key ~= self.hoverKey then
        self.hoverKey = key
        if key then
            ui.tipper:ClearAllPoints()
            ui.tipper:SetWidth(fw)
            ui.tipper:SetHeight(fh)
            ui.tipper:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", fx, -fy)
            ui.tipper.tipTitle = name
            ns.TipShow(ui.tipper)
        else
            ns.TipHide()
        end
    end
end
function Game:Score()
    return 0
end
function Game:Ranked()
    return false
end
function Game:Turn()
    return R.turn(self.st)
end
function Game:IsOver()
    return self.st.phase == "over"
end
function Game:ResultText()
    local st = self.st
    if st.broke then return ns.T("seabattle.resBroke", ns.T("seabattle.brokeTargets")) end
    local s = (st.winner == st.me) and ns.T("seabattle.resWin") or ns.T("seabattle.resLose")
    if st.oddNote == "norev" then
        s = s .. ". " .. ns.T("seabattle.oddNoFleet")
    elseif st.oddNote == "odd" then
        s = s .. ". " .. ns.T("seabattle.oddNote")
    end
    return s
end
function Game:Stop()
    self.hand = nil
    ns.CallPanel.Hide()
    ns.Curtain.Hide()
    hideView()
end
function Game:PickFoe(key)
    if not self.menu or key == self.foe then return end
    if ns.Duo.Waiting() or ns.Duo.Active() then return end
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, { foe = key })
end
function Game:BeginRound()
    if not self.menu or self.foe == "duo" then return end
    self.menu = false
    self:Draw()
end
local PAIR_KEY = {
    live = "seabattle.pairLive", duo = "seabattle.pairInGame", combat = "seabattle.pairCombat",
    away = "seabattle.pairAway", gone = "seabattle.pairOffline",
}
local STATE_KEY = {
    live = "seabattle.peerLive", combat = "seabattle.peerCombat",
    away = "seabattle.peerAway", quiet = "seabattle.peerQuiet",
}
function Game:SyncMenu()
    if not menu or not menu.root:IsShown() then return end
    local me = self
    local sk = SKIES[self.st.sky] or SKIES[1]
    local waiting = ns.Duo.Waiting()
    local mate = ns.Pair.Bound() and ns.Pair.Mate() or nil
    local duoPick = (self.foe == "duo")
    menu.title:SetText(ns.T("seabattle.label"))
    for i = 1, #FOES do
        local t = menu.tile[i]
        local on = (FOES[i].key == self.foe)
        t:Tone(on)
        t.title:SetText(ns.T(FOES[i].name))
        ink(t.title, on and sk.accent or sk.text)
        t:SetAlpha(waiting and 0.45 or 1)
        t:EnableMouse(not waiting)
    end
    menu.desc:SetText(ns.T(foeBy(self.foe).desc))
    ink(menu.desc, sk.label)
    if duoPick then
        if mate then
            local where = ns.Pair.Where() or "gone"
            local col = (where == "live" or where == "duo") and C.live or (where == "gone") and C.gone or C.warn
            menu.who:SetText(mate .. " - " .. ns.T(PAIR_KEY[where] or PAIR_KEY.gone))
            ink(menu.who, col)
        else
            menu.who:SetText(ns.T("seabattle.menuNobody"))
            ink(menu.who, C.dim)
        end
    else
        menu.who:SetText("")
    end
    local t = ns.Config.Get(ID, "tally", nil)
    local b = type(t) == "table" and t[self.foe] or nil
    menu.score:SetText(ns.T("seabattle.menuScore", b and b.w or 0, b and b.l or 0))
    ink(menu.score, sk.accent)
    if waiting then
        menu.play:SetText(ns.T("duoCancel"))
        menu.play.tip = ns.T("duoCancelTip")
        menu.play.onClick = function() ns.Duo.Cancel() end
    elseif duoPick and mate then
        menu.play:SetText(ns.T("seabattle.menuPlayMate", mate))
        menu.play.tip = ns.T("seabattle.menuPlayMateTip")
        menu.play.onClick = function() ns.Pair.Play(ID, me.opts) end
    elseif duoPick then
        menu.play:SetText(ns.T("seabattle.menuCall"))
        menu.play.tip = ns.T("seabattle.menuCallTip")
        menu.play.onClick = function()
            ns.CallPanel.Show(ns.window:Frame(), {
                pair = true, title = ns.T("seabattle.menuCall"), autoHide = true,
            })
        end
    else
        menu.play:SetText(ns.T("seabattle.menuPlay"))
        menu.play.tip = ns.T("seabattle.menuPlayTip")
        menu.play.onClick = function() me:BeginRound() end
    end
    menu.play:Enable()
    local said = ns.Duo.Status() or ns.Pair.Status()
    if said then
        menu.note:SetText(said)
        ink(menu.note, C.live)
    elseif duoPick and not mate then
        menu.note:SetText(ns.T("seabattle.menuHint"))
        ink(menu.note, C.dim)
    else
        menu.note:SetText("")
    end
    local fac = (UnitFactionGroup("player") == "Horde") and 2 or 1
    crestCoord(menu.crest, fac)
    menu.nick:SetText(UnitName("player") or "")
    ink(menu.nick, sk.text)
end
function Game:FoeName()
    if self.bot then return ns.T(foeBy(self.foe).label) end
    return ns.Duo.Peer() or ns.T("seabattle.menuNobody")
end
function Game:SyncHead()
    if not ui or self.menu then return end
    local st, me = self.st, self.st.me
    local sk = SKIES[st.sky] or SKIES[1]
    local hd = ui.head
    local foe = 3 - me
    local held = ns.Duo.Held()
    local mine, his = hd.side[1], hd.side[2]
    crestCoord(mine.crest, st.fac[me])
    crestCoord(his.crest, st.fac[foe])
    mine.name:SetText(UnitName("player") or "")
    ink(mine.name, sk.text)
    his.name:SetText(self:FoeName())
    ink(his.name, sk.text)
    mine.state:SetText(ns.T(FAC_KEY[st.fac[me]]))
    ink(mine.state, sk.label)
    tint(mine.dot, sk.label, 0.8)
    local stText, stCol
    if held then
        stText, stCol = ns.T("seabattle.peerHeld"), C.gone
    elseif self.bot then
        local thinks = (st.phase == "aim" and st.shooter == self.bot)
        stText = thinks and ns.T("seabattle.botThinks") or ns.T(FAC_KEY[st.fac[foe]])
        stCol = thinks and C.warn or sk.label
    elseif ns.Duo.Active() then
        local s = ns.Duo.PeerState() or "live"
        stText = ns.T(STATE_KEY[s] or STATE_KEY.live)
        stCol = (s == "live") and C.live or C.warn
    else
        stText, stCol = ns.T(FAC_KEY[st.fac[foe]]), sk.label
    end
    his.state:SetText(stText)
    ink(his.state, stCol)
    tint(his.dot, stCol, 0.9)
    local l1, l2, c1 = "", "", sk.accent
    local crestSide
    if st.phase == "setup" then
        l1 = self.locked and ns.T("seabattle.setupWait") or ns.T("seabattle.setupCap")
        l2 = ns.T(sk.key)
    elseif st.phase == "aim" or st.phase == "answer" then
        if held then
            l1, c1 = ns.T("seabattle.turnWait"), C.gone
        elseif st.shooter == me then
            l1 = ns.T("seabattle.turnMine")
            crestSide = me
        else
            l1 = self.bot and ns.T("seabattle.turnBot") or ns.T("seabattle.turnPeer", self:FoeName())
            c1 = sk.text
            crestSide = foe
        end
        if self.resignWant then
            l2 = ns.T("seabattle.resignWait")
        elseif self.firstShown then
            l2 = (st.shooter == me) and ns.T("seabattle.firstMe") or ns.T("seabattle.firstFoe", self:FoeName())
        elseif st.auto and st.ans then
            l2 = ns.T("seabattle.timeOut")
        elseif st.ans then
            l2 = ns.T("seabattle.ans" .. st.ans:sub(1, 1):upper() .. st.ans:sub(2))
        end
    else
        l1 = self:ResultText() or ""
        if st.winner then crestSide = st.winner end
        c1 = (st.winner == me) and sk.accent or sk.text
    end
    hd.line1:SetText(l1)
    ink(hd.line1, c1)
    hd.line2:SetText(l2)
    ink(hd.line2, sk.label)
    if crestSide then
        crestCoord(hd.crest, st.fac[crestSide])
        hd.crest:Show()
    else
        hd.crest:Hide()
    end
    local battle = (st.phase == "aim" or st.phase == "answer") and not held
    local mine = battle and st.shooter == me
    paintPanel(hd.panel, sk, mine and sk.accent or sk.frame)
    boardFocus(boards[2], mine, battle and not mine)
    boardFocus(boards[1], battle and not mine, mine)
    local isDuo = (self.foe == "duo")
    local showTimer = isDuo and not held and (
        (st.phase == "setup" and not self.locked) or st.phase == "aim")
    if showTimer then
        local limit = (st.phase == "setup") and L.SETUP_LIMIT or L.SHOT_LIMIT
        local used = (st.phase == "setup") and self.setupT or self.shotT
        local left = limit - used
        if left < 0 then left = 0 end
        local hgt = hd.timerBack:GetHeight() or 0
        local fh = floor((hgt - 4) * left / limit)
        if fh < 1 then fh = 1 end
        hd.timerFill:SetHeight(fh)
        hd.timerText:SetText(tostring(math.ceil(left)))
        ink(hd.timerText, (left <= 5) and C.red or sk.accent)
        hd.timerBack:Show()
    else
        hd.timerBack:Hide()
    end
    local ft = ui.foot
    if st.phase == "aim" or st.phase == "answer" then
        ft.resign:SetText(ns.T("seabattle.resign"))
        if self.resignWant then
            ft.resign.tip = ns.T("seabattle.resignWait")
            ft.resign:Disable()
        else
            ft.resign.tip = ns.T("seabattle.resignTip")
            if held then ft.resign:Disable() else ft.resign:Enable() end
        end
        ft.resign.onClick = function() self:AskResign() end
        ft.resign:Show()
    else
        ft.resign:Hide()
    end
    if held and ns.Duo.Peer() then
        local at = ns.Duo.HeldAt()
        ui.held.text:SetText(ns.Duo.Peer() .. " " .. ns.T("pairHeld", at and floor((time() - at) / 60) or 0))
        ink(ui.held.text, sk.accent)
        ui.held.call:SetText(ns.T("pairResume"))
        ui.held.call.tip = ns.T("pairResumeTip")
        if ns.Duo.Calling() then ui.held.call:Disable() else ui.held.call:Enable() end
        ui.held.drop:SetText(ns.T("seabattle.heldDrop"))
        ui.held.drop.tip = ns.T("seabattle.heldDropTip")
        ui.held:SetWidth(14 + (ui.held.text:GetStringWidth() or 0) + 12 + 130 + 8 + 130 + 14)
        ui.held:Show()
    else
        ui.held:Hide()
    end
    if st.phase == "setup" then
        if self.locked or held then ui.catcher:Hide() else ui.catcher:Show() end
        local hg = ui.hangar
        hg.random:SetText(ns.T("seabattle.btnRandom"))
        hg.random.tip = ns.T("seabattle.btnRandomTip")
        hg.random.onClick = function() self:RandomFleet() end
        hg.ready:SetText(ns.T("seabattle.btnReady"))
        local full = #st.fleet[me] == 10
        hg.ready.tip = ns.T("seabattle.btnReadyTip")
        hg.ready.tipDim = (not full) and ns.T("seabattle.btnReadyDim") or nil
        hg.ready.onClick = function() self:Ready() end
        if self.locked or held then
            hg.random:Disable()
            hg.ready:Disable()
        else
            hg.random:Enable()
            if full then hg.ready:Enable() else hg.ready:Disable() end
        end
    end
end
function Game:PanelSync()
    if not ui then return end
    if self.menu then
        self:SyncMenu()
        return
    end
    self:SyncHead()
end
function Game:Screen()
    sky:Show()
    if self.menu then
        boardHide(boards[1])
        boardHide(boards[2])
        ui.head:Hide()
        ui.head.timerBack:Hide()
        ui.foot:Hide()
        ui.hangar:Hide()
        ui.ghost:Hide()
        ui.catcher:Hide()
        ui.held:Hide()
        menu.root:Show()
        return
    end
    menu.root:Hide()
    ui.head:Show()
    boards[1]:Show()
    if self.st.phase == "setup" then
        boardHide(boards[2])
        ui.hangar:Show()
        ui.foot:Show()
        ui.foot.panel:Hide()
        ui.foot.hint:Show()
        for side = 1, 2 do
            for _, e in ipairs(ui.foot.rows[side]) do
                e.ship:Hide()
                e.cnt:Hide()
            end
        end
    else
        boards[2]:Show()
        ui.hangar:Hide()
        ui.catcher:Hide()
        ui.foot:Show()
        ui.foot.panel:Show()
        ui.foot.hint:Hide()
    end
end
local function drawOwn(self, bd)
    local st, me = self.st, self.st.me
    local sk = SKIES[st.sky] or SKIES[1]
    local marks = st.marks[me]
    local fleet = st.fleet[me] or {}
    if self.hand and self.ghostNose then
        local sh = { s = self.ghostNose, d = (self.hand.n == 1) and "h" or self.hand.d, n = self.hand.n }
        local ok = R.canPlace(fleet, sh)
        local cs = R.cells(sh) or {}
        for _, i in ipairs(cs) do putFill(bd, i, ok and sk.ok or sk.bad) end
    end
    local sunkAt = {}
    for _, sh in ipairs(st.sunk[me]) do
        for _, i in ipairs(R.cells(sh) or {}) do sunkAt[i] = true end
    end
    for _, sh in ipairs(fleet) do
        local dead = false
        local cs = R.cells(sh) or {}
        if #cs > 0 and sunkAt[cs[1]] then dead = true end
        putShip(bd, sh, st.fac[me], dead and sk.wreck or nil, dead and 0.9 or 1)
    end
    local pend = (st.phase == "answer" and st.shooter ~= me) and st.shot or nil
    paintBox(bd.lastBox, pend and C.pend or C.last, 0.22)
    placeBox(bd, bd.lastBox, pend or st.last[me])
    for i = 1, R.CELLS do
        local m = marks[i]
        if m == R.MISS then
            putMark(bd, i, MARK.miss, sk.puff)
        elseif m == R.HIT then
            putMark(bd, i, MARK.hit)
        elseif m == R.SUNK then
            putMark(bd, i, (i % 2 == 0) and MARK.debris or MARK.smoke)
        elseif m == R.SHUT then
            putMark(bd, i, MARK.dot, sk.dot, 0.75)
        end
    end
    if st.odd[me] then
        for _, i in ipairs(st.odd[me]) do putFill(bd, i, C.odd) end
    end
end
local function drawFoe(self, bd)
    local st, me = self.st, self.st.me
    local foe = 3 - me
    local sk = SKIES[st.sky] or SKIES[1]
    local marks = st.marks[foe]
    local sunkAt = {}
    for _, sh in ipairs(st.sunk[foe]) do
        putShip(bd, sh, st.fac[foe], sk.wreck, 0.9)
        for _, i in ipairs(R.cells(sh) or {}) do sunkAt[i] = true end
    end
    if st.phase == "over" and st.fleet[foe] then
        for _, sh in ipairs(st.fleet[foe]) do
            local cs = R.cells(sh) or {}
            if #cs > 0 and not sunkAt[cs[1]] then
                putShip(bd, sh, st.fac[foe], nil, 0.6)
            end
        end
    end
    local pend = (st.phase == "answer" and st.shooter == me) and st.shot or nil
    paintBox(bd.lastBox, pend and C.pend or C.last, 0.22)
    placeBox(bd, bd.lastBox, pend or st.last[foe])
    for i = 1, R.CELLS do
        local m = marks[i]
        if m == R.MISS then
            putMark(bd, i, MARK.miss, sk.puff)
        elseif m == R.HIT then
            putMark(bd, i, MARK.hit)
        elseif m == R.SUNK then
            putMark(bd, i, (i % 2 == 0) and MARK.debris or MARK.smoke)
        elseif m == R.SHUT then
            putMark(bd, i, MARK.dot, sk.dot, 0.75)
        end
    end
    if st.odd[foe] then
        for _, i in ipairs(st.odd[foe]) do putFill(bd, i, C.odd) end
    end
end
local function drawHangar(self)
    local st, me = self.st, self.st.me
    local sk = SKIES[st.sky] or SKIES[1]
    local hg = ui.hangar
    for k, n in ipairs(R.SIZES) do
        local e = hg.rows[k]
        local left = self:HangarLeft(n)
        shipCoord(e.ship, st.fac[me], n, "h")
        e.ship:SetAlpha(left > 0 and 1 or 0.35)
        e.cnt:SetText("x" .. left)
        ink(e.cnt, left > 0 and sk.label or C.dim)
        if self.hand and self.hand.n == n and not self.hand.from then e.hot:Show() else e.hot:Hide() end
    end
    ui.foot.hint:SetText(ns.T("seabattle.hintRotate"))
end
local function drawFoot(self)
    local st, me = self.st, self.st.me
    local sk = SKIES[st.sky] or SKIES[1]
    local ft = ui.foot
    if st.lastSunk then
        crestCoord(ft.crest, st.fac[st.lastSunk.side])
        ft.crest:Show()
        ft.text:SetText(ns.T("seabattle.sunkLine", shipName(st.fac[st.lastSunk.side], st.lastSunk.n)))
    else
        ft.crest:Hide()
        ft.text:SetText("")
    end
    ink(ft.text, sk.text)
    for side = 1, 2 do
        local who = (side == 1) and me or (3 - me)
        for k, n in ipairs(R.SIZES) do
            local e = ft.rows[side][k]
            local left = st.left[who][n]
            shipCoord(e.ship, st.fac[who], n, "h")
            tint(e.ship, left > 0 and C.white or sk.wreck, left > 0 and 1 or 0.7)
            e.cnt:SetText("x" .. left)
            ink(e.cnt, left > 0 and sk.label or C.dim)
            e.ship:Show()
            e.cnt:Show()
        end
    end
end
function Game:Draw()
    if not ui then return end
    self:Screen()
    if self.menu then
        self:SyncMenu()
        return
    end
    local st = self.st
    boardReset(boards[1])
    boardReset(boards[2])
    drawOwn(self, boards[1])
    if st.phase ~= "setup" then drawFoe(self, boards[2]) end
    boardFlush(boards[1])
    boardFlush(boards[2])
    if st.phase == "setup" then drawHangar(self) else drawFoot(self) end
    self:SyncHead()
end
local function TileIcon(host, size)
    local t = ns.ArtFill(host, 1, "ARTWORK")
    shipCoord(t, 1, 2, "h")
    t:SetWidth(size)
    t:SetHeight(floor(size / 2))
    t:SetPoint("CENTER", host, "CENTER", 0, floor(size * 0.18))
    local m = ns.ArtFill(host, 2, "OVERLAY")
    markCoord(m, MARK.hit)
    local d = floor(size * 0.5)
    m:SetWidth(d)
    m:SetHeight(d)
    m:SetPoint("CENTER", host, "CENTER", floor(size * 0.2), -floor(size * 0.2))
end
ns.RegisterGame{
    id = ID,
    label = "seabattle.label",
    icon = { draw = TileIcon },
    tip = "seabattle.tip",
    order = 11,
    duo = "turns",
    physics = false,
    ownPanel = true,
    look = LOOK,
    canvas = { w = W, h = H },
    heldStrip = false,
    opts = {
        { key = "foe", label = "seabattle.optFoeLabel", def = DEF_FOE, options = FOES,
          tip = "seabattle.optFoeTip" },
    },
    record = false,
    finale = true,
    New = New,
    controls = {
        { action = "pick", label = "seabattle.ctlPick", mouse = "LMB", where = "seabattle.ctlOnShip" },
        { action = "drop", label = "seabattle.ctlDrop", mouse = "LMB", where = "seabattle.ctlOnOwn" },
        { action = "rotate", label = "seabattle.ctlRotate", mouse = "RMB", where = "seabattle.ctlOnShip" },
        { action = "shoot", label = "seabattle.ctlShoot", mouse = "LMB", where = "seabattle.ctlOnFoe" },
    },
    help = {
        "seabattle.help1",
        "seabattle.help2",
        { t = "seabattle.help3", sub = "seabattle.help3Sub" },
        { t = "seabattle.help4", sub = "seabattle.help4Sub" },
        "seabattle.help5",
        "seabattle.help6",
        "seabattle.help7",
    },
}
