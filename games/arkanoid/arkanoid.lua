local ADDON, ns = ...
local ID = "arkanoid"
local floor, ceil, abs, max, min, sqrt = math.floor, math.ceil, math.abs, math.max, math.min, math.sqrt
local sin, cos, rad, atan2 = math.sin, math.cos, math.rad, math.atan2
local CANVAS_W, CANVAS_H = 640, 480
local PAD_H, PAD_TOP = 12, 36
local BALL = 10
local BALL_HALF = BALL / 2
local COLS, ROWS = 16, 11
local BRICK_W, BRICK_H, GAP = 27, 20, 1
local MARGIN_X = 12
local TOP_ROW_Y = 455
local PLAY_W = 472
local PANEL_X = PLAY_W
local PANEL_W = CANVAS_W - PLAY_W
local WAVE_MAX = 999
local LIVES_CAP = 5
local MODES = {
    { key = "calm",  label = "arkanoid.modeCalm",  tip = "arkanoid.modeCalmTip",
      pad = 96, speed = 320, gain = 0.15, lives = 5 },
    { key = "usual", label = "arkanoid.modeUsual", tip = "arkanoid.modeUsualTip",
      pad = 80, speed = 380, gain = 0.25, lives = 3 },
    { key = "hard",  label = "arkanoid.modeHard",  tip = "arkanoid.modeHardTip",
      pad = 64, speed = 450, gain = 0.35, lives = 2 },
}
local MODE_DEFAULT = 2
local ANGLE_MAX = rad(60)
local ANTILOOP_FRAC = 0.20
local BOUNCE_JITTER = rad(1.5)
local SUBSTEP_MAX = 8
local NORMAL_SHADE, HIT_SHADE = 0.70, 0.45
local GOLD_LOW = { 0.58, 0.42, 0.12 }
local GOLD_HI  = { 0.95, 0.78, 0.32 }
local GOLD_BAR = 14
local FLASH_T, FLASH_BOOST = 0.18, 0.55
local LOOK_WOOD = { 0.16, 0.15, 0.20 }
local LOOK_EDGE = { 0.55, 0.62, 0.78 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE }
local FIELD_BG  = { 0.05, 0.05, 0.08 }
local RAIL      = { 0.33, 0.37, 0.47 }
local RAIL_LOW  = { 0.45, 0.16, 0.14 }
local VIG_SIDE, VIG_BOT, VIG_TOP = 48, 70, 25
local VIG_SIDE_A, VIG_BOT_A, VIG_TOP_A = 0.45, 0.55, 0.35
local BRICK_LOW = 0.70
local EDGE_HI_A, EDGE_LOW_A = 0.35, 0.45
local PAD_LOW = { 0.50, 0.53, 0.64 }
local PAD_HI  = { 0.86, 0.88, 0.95 }
local PAD_CAP_MIN, PAD_CAP_MAX = 8, 24
local BALL_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local HALO_TEX = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local HALO = 26
local HALO_A_MIN, HALO_A_RANGE = 0.20, 0.55
local COL_PAD = 10
local COL_IN = PANEL_W - COL_PAD * 2
local NICHE_Y, NICHE_H = 0, CANVAS_H
local ROW_SEP1, ROW_WAVE, ROW_PIC = 108, 118, 140
local ROW_SEP2, ROW_LIVES, ROW_DOTS = 178, 188, 208
local ROW_SEP3, ROW_MODE_CAP, ROW_MODE = 228, 236, 256
local ROW_PICK, ROW_STEP = 282, 302
local ROW_SKIP, ROW_RESET = 326, 350
local GRID_COLS = 10
local GRID_CW, GRID_CH, GRID_GAP, GRID_PAD, GRID_CAP = 38, 26, 4, 12, 22
local GRID_MARK = 13
local CHAIN_HOT = 5
local FX_SET = { "chip", "crumb", "crack" }
local GOLD_FX_GAP = 0.25
local DONE_TEX = "Interface\\RaidFrame\\ReadyCheck-Ready"
local DOT, DOT_STEP = 10, 16
local RECALL_AFTER = 4
local BALL_COLD = { 1.00, 1.00, 1.00 }
local BALL_HOT  = { 1.00, 0.35, 0.15 }
local BONUS_KINDS = { "wide", "multi", "sticky" }
local BONUS_COLOUR = { wide = "green", multi = "blue", sticky = "purple" }
local WIDE_MULT = 1.6
local WIDE_DURATION = 14
local STICKY_DURATION = 12
local FALL_SPEED = 150
local FALL_W, FALL_H = 20, 14
local MAX_FALL = 8
local MAX_BALLS = 8
local SPLIT_INTO = 3
local SPLIT_ANGLE = rad(18)
local BLANK_TEX = "Interface\\BUTTONS\\WHITE8X8"
local function rowTop(row)
    return TOP_ROW_Y - (ROWS - row) * (BRICK_H + GAP)
end
local function colLeft(col)
    return MARGIN_X + (col - 1) * (BRICK_W + GAP)
end
local SPEED_CEIL = 0
for i = 1, #MODES do
    local top = MODES[i].speed * (1 + MODES[i].gain)
    if top > SPEED_CEIL then SPEED_CEIL = top end
end
local PIC_SET = "screen"
local PIC_SQUEEZE = 4 / 3
local PIC_BACK = 0.38
local PIC_MIX = 0.75
local function fieldWindow(p)
    local w, h = (p.w or 1) * PIC_SQUEEZE, (p.h or 1)
    local want = PLAY_W / CANVAS_H
    local fx, fy = 1, 1
    if w / h > want then fx = want * h / w else fy = w / (want * h) end
    return (1 - fx) / 2, (1 + fx) / 2, (1 - fy) / 2, (1 + fy) / 2
end
local function cellWindow(win, row, col)
    local x0 = colLeft(col) / PLAY_W
    local x1 = (colLeft(col) + BRICK_W) / PLAY_W
    local y0 = (CANVAS_H - rowTop(row)) / CANVAS_H
    local y1 = (CANVAS_H - rowTop(row) + BRICK_H) / CANVAS_H
    local dw, dh = win[2] - win[1], win[4] - win[3]
    return win[1] + dw * x0, win[1] + dw * x1, win[3] + dh * y0, win[3] + dh * y1
end
local CELL = {
    ["."] = { hp = 0 },
    ["1"] = { hp = 1 },
    ["2"] = { hp = 2 },
    ["#"] = { hp = -1 },
    w = { hp = 1, bonus = "wide" },   m = { hp = 1, bonus = "multi" },   s = { hp = 1, bonus = "sticky" },
    W = { hp = 2, bonus = "wide" },   M = { hp = 2, bonus = "multi" },   S = { hp = 2, bonus = "sticky" },
}
local FALLBACK_BOARD = { key = "wall", label = "arkanoid.boardWall", colour = "row", rows = {} }
for i = 1, ROWS do
    FALLBACK_BOARD.rows[i] = (i >= 4 and i <= 6) and ("1"):rep(COLS) or ("."):rep(COLS)
end
local PROGRESS_V = 1
local function progress()
    local ch = ns.Store.Char()
    local box = ch.arkanoid
    if type(box) ~= "table" or box.v ~= PROGRESS_V then
        box = { v = PROGRESS_V, done = 0, next = 1 }
        ch.arkanoid = box
    end
    if type(box.clear) ~= "table" then box.clear = {} end
    return box
end
local function paintGoldBar(f, boost)
    local k = 1 + boost
    f.bar:SetTexture(BLANK_TEX)
    f.bar:SetGradientAlpha("VERTICAL",
        min(GOLD_LOW[1] * k, 1), min(GOLD_LOW[2] * k, 1), min(GOLD_LOW[3] * k, 1), 1,
        min(GOLD_HI[1] * k, 1), min(GOLD_HI[2] * k, 1), min(GOLD_HI[3] * k, 1), 1)
end
local function brickRGB(board, row)
    local c = board.colour
    if c == "row" then return ns.Palette.RGB(1 + (row - 1) % 6) end
    if type(c) == "table" then return ns.Palette.RGB(c[1 + (row - 1) % #c]) end
    return ns.Palette.RGB(c)
end
local function modeOf()
    local box = progress()
    local i = floor(ns.Store.Num(box.mode, 1, #MODES, MODE_DEFAULT))
    return MODES[i], i
end
local function boardPool()
    local list = ns.arkanoidBoards
    if type(list) ~= "table" or #list == 0 then return { FALLBACK_BOARD } end
    return list
end
local view, brickPool, ballPool, fallPool
local function newBrick(canvas)
    local f = CreateFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + 2)
    f:SetWidth(BRICK_W)
    f:SetHeight(BRICK_H)
    f.fill = f:CreateTexture(nil, "BACKGROUND")
    f.fill:SetAllPoints()
    f.art = f:CreateTexture(nil, "BORDER")
    f.art:SetAllPoints()
    f.art:SetBlendMode("ADD")
    f.art:Hide()
    f.bar = f:CreateTexture(nil, "ARTWORK")
    f.bar:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.bar:Hide()
    f.edgeHi = f:CreateTexture(nil, "OVERLAY")
    f.edgeHi:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.edgeHi:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.edgeHi:SetHeight(1)
    f.edgeLow = f:CreateTexture(nil, "OVERLAY")
    f.edgeLow:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.edgeLow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.edgeLow:SetHeight(1)
    f.edgeHi:Hide()
    f.edgeLow:Hide()
    f:Hide()
    return f
end
local function newBall(canvas)
    local f = CreateFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + 4)
    f:SetWidth(BALL)
    f:SetHeight(BALL)
    f.halo = f:CreateTexture(nil, "BACKGROUND")
    f.halo:SetWidth(HALO)
    f.halo:SetHeight(HALO)
    f.halo:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.halo:SetTexture(HALO_TEX)
    f.halo:SetBlendMode("ADD")
    f.fill = f:CreateTexture(nil, "ARTWORK")
    f.fill:SetAllPoints()
    f.fill:SetTexture(BALL_TEX)
    f:Hide()
    return f
end
local function newFall(canvas)
    local f = CreateFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + 3)
    f:SetWidth(FALL_W)
    f:SetHeight(FALL_H)
    f.fill = f:CreateTexture(nil, "ARTWORK")
    f.fill:SetAllPoints()
    f.gloss = f:CreateTexture(nil, "OVERLAY")
    f.gloss:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.gloss:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.gloss:SetHeight(1)
    f.gloss:SetTexture(1, 1, 1, 0.5)
    f.badge = f:CreateTexture(nil, "OVERLAY")
    f.badge:SetWidth(FALL_H)
    f.badge:SetHeight(FALL_H)
    f.badge:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.badge:Hide()
    f:Hide()
    return f
end
local function gridClose()
    if view and view.grid then view.grid:Hide() end
end
local function gridFill()
    local g = view.game
    if not g then return end
    local box = progress()
    local pool = #boardPool()
    local top = box.done + 1
    if top > pool then top = pool end
    if top < 1 then top = 1 end
    local shut = 0
    for n = 1, pool do
        if box.clear[n] then shut = shut + 1 end
    end
    view.gridCap:SetText(ns.T("arkanoid.gridFmt"):format(shut, pool))
    view.gridPool:Reset()
    for n = 1, pool do
        local b = view.gridPool:Acquire()
        b:SetText(tostring(n))
        b.active = (n == g.wave)
        b.tip = (n <= box.done) and ns.TL(g:BoardFor(n).label) or nil
        if box.clear[n] then b.mark:Show() else b.mark:Hide() end
        if n <= top then b:Enable() else b:Disable() end
        b.onClick = function()
            gridClose()
            local bx = progress()
            bx.next = n
            ns.Store.Clear(ID)
            ns.window:StartGame(ID)
        end
        local r = ceil(n / GRID_COLS) - 1
        local c = (n - 1) % GRID_COLS
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", view.grid, "TOPLEFT",
            GRID_PAD + c * (GRID_CW + GRID_GAP),
            -(GRID_PAD + GRID_CAP + r * (GRID_CH + GRID_GAP)))
        b:Show()
    end
    view.gridPool:HideExtras()
end
local function gridOpen()
    if not view or not view.grid then return end
    gridFill()
    view.grid:Show()
end
local function buildGrid(canvas)
    local rows = ceil(#boardPool() / GRID_COLS)
    local w = GRID_COLS * GRID_CW + (GRID_COLS - 1) * GRID_GAP + GRID_PAD * 2
    local h = GRID_PAD * 2 + GRID_CAP + rows * GRID_CH + (rows - 1) * GRID_GAP + GRID_CAP + 4
    local f = ns.PlainFrame(canvas, 20)
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetPoint("CENTER", canvas, "BOTTOMLEFT", PLAY_W / 2, CANVAS_H / 2)
    f:EnableMouse(true)
    ns.DressCard(f, LOOK)
    f:Hide()
    view.grid = f
    view.gridCap = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.gridCap:SetPoint("TOPLEFT", f, "TOPLEFT", GRID_PAD, -GRID_PAD)
    view.gridCap:SetText(ns.T("arkanoid.gridFmt"):format(0, 0))
    view.gridPool = ns.NewPool(function()
        local b = ns.MakeKitButton(f)
        b:SetWidth(GRID_CW)
        b:SetHeight(GRID_CH)
        b.mark = b:CreateTexture(nil, "OVERLAY")
        b.mark:SetTexture(DONE_TEX)
        b.mark:SetWidth(GRID_MARK)
        b.mark:SetHeight(GRID_MARK)
        b.mark:SetPoint("TOPRIGHT", b, "TOPRIGHT", 2, 2)
        b.mark:Hide()
        return b
    end)
    view.gridShut = ns.MakeKitButton(f)
    view.gridShut:SetWidth(80)
    view.gridShut:SetHeight(GRID_CAP - 4)
    view.gridShut:SetPoint("BOTTOM", f, "BOTTOM", 0, GRID_PAD - 6)
    ns.SetKeyText(view.gridShut, "arkanoid.close")
    view.gridShut.onClick = gridClose
end
local function ensureView(canvas)
    if view then return end
    view = {}
    view.table = ns.MakeTable(canvas, LOOK)
    view.field = ns.PlainFrame(canvas, 1)
    view.field:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, 0)
    view.field:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", 0, 0)
    view.field:SetWidth(PLAY_W)
    view.field:Hide()
    local plate = ns.Fill(view.field, "BACKGROUND", FIELD_BG)
    plate:SetAllPoints(view.field)
    view.art = view.field:CreateTexture(nil, "BORDER")
    view.art:SetAllPoints(view.field)
    view.art:Hide()
    local function vignette(p1, p2, w, h, dir, a1, a2)
        local t = view.field:CreateTexture(nil, "ARTWORK")
        t:SetPoint(p1, view.field, p1, 0, 0)
        t:SetPoint(p2, view.field, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        t:SetTexture(BLANK_TEX)
        t:SetGradientAlpha(dir, 0, 0, 0, a1, 0, 0, 0, a2)
    end
    vignette("TOPLEFT", "BOTTOMLEFT", VIG_SIDE, nil, "HORIZONTAL", VIG_SIDE_A, 0)
    vignette("TOPRIGHT", "BOTTOMRIGHT", VIG_SIDE, nil, "HORIZONTAL", 0, VIG_SIDE_A)
    vignette("BOTTOMLEFT", "BOTTOMRIGHT", nil, VIG_BOT, "VERTICAL", VIG_BOT_A, 0)
    vignette("TOPLEFT", "TOPRIGHT", nil, VIG_TOP, "VERTICAL", 0, VIG_TOP_A)
    local function rail(p1, p2, w, h, c)
        local t = ns.Fill(view.field, "OVERLAY", c)
        t:SetPoint(p1, view.field, p1, 0, 0)
        t:SetPoint(p2, view.field, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    rail("TOPLEFT", "TOPRIGHT", nil, 1, RAIL)
    rail("TOPLEFT", "BOTTOMLEFT", 1, nil, RAIL)
    rail("TOPRIGHT", "BOTTOMRIGHT", 1, nil, RAIL)
    rail("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2, RAIL_LOW)
    brickPool = ns.NewPool(function() return newBrick(canvas) end)
    ballPool = ns.NewPool(function() return newBall(canvas) end)
    fallPool = ns.NewPool(function() return newFall(canvas) end)
    view.pad = CreateFrame("Frame", nil, canvas)
    view.pad:SetFrameLevel(canvas:GetFrameLevel() + 3)
    view.pad:SetHeight(PAD_H)
    view.pad.fill = view.pad:CreateTexture(nil, "BACKGROUND")
    view.pad.fill:SetAllPoints()
    view.pad.capL = view.pad:CreateTexture(nil, "OVERLAY")
    view.pad.capL:SetPoint("TOPLEFT", view.pad, "TOPLEFT", 0, 0)
    view.pad.capL:SetPoint("BOTTOMLEFT", view.pad, "BOTTOMLEFT", 0, 0)
    view.pad.capR = view.pad:CreateTexture(nil, "OVERLAY")
    view.pad.capR:SetPoint("TOPRIGHT", view.pad, "TOPRIGHT", 0, 0)
    view.pad.capR:SetPoint("BOTTOMRIGHT", view.pad, "BOTTOMRIGHT", 0, 0)
    view.pad.gloss = view.pad:CreateTexture(nil, "ARTWORK")
    view.pad.gloss:SetPoint("TOPLEFT", view.pad, "TOPLEFT", 0, 0)
    view.pad.gloss:SetPoint("TOPRIGHT", view.pad, "TOPRIGHT", 0, 0)
    view.pad.gloss:SetHeight(1)
    view.pad:Hide()
    view.panel = ns.MakeNiche(canvas, 5, LOOK)
    view.panel:SetPoint("TOPLEFT", canvas, "TOPLEFT", PANEL_X, -NICHE_Y)
    view.panel:SetWidth(PANEL_W)
    view.panel:SetHeight(NICHE_H)
    view.panel:Hide()
    local col = ns.PlainFrame(view.panel, 1)
    col:SetPoint("TOPLEFT", view.panel, "TOPLEFT", COL_PAD, -COL_PAD)
    col:SetWidth(COL_IN)
    col:SetHeight(NICHE_H - COL_PAD * 2)
    view.board = ns.MakeScoreboard(col, COL_IN)
    view.board:SetPoint("TOPLEFT", col, "TOPLEFT", 0, 0)
    local function sep(y)
        local t = ns.Fill(col, "ARTWORK", RAIL[1], RAIL[2], RAIL[3], 0.5)
        t:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", col, "TOPRIGHT", 0, -y)
        t:SetHeight(1)
    end
    sep(ROW_SEP1)
    sep(ROW_SEP2)
    sep(ROW_SEP3)
    view.waveText = col:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.waveText:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -ROW_WAVE)
    view.picText = col:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    view.picText:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -ROW_PIC)
    view.picText:SetWidth(COL_IN)
    view.picText:SetJustifyH("LEFT")
    ns.SetKeyText(ns.MakeCap(col, 0, ROW_LIVES), "arkanoid.capLives")
    view.dot = {}
    for i = 1, LIVES_CAP do
        local t = col:CreateTexture(nil, "ARTWORK")
        t:SetWidth(DOT)
        t:SetHeight(DOT)
        t:SetPoint("TOPLEFT", col, "TOPLEFT", (i - 1) * DOT_STEP, -ROW_DOTS)
        t:SetTexture(BALL_TEX)
        view.dot[i] = t
    end
    sep(ROW_SEP3)
    ns.SetKeyText(ns.MakeCap(col, 0, ROW_MODE_CAP), "arkanoid.capMode")
    view.mode = ns.MakeSelect(col)
    view.mode:SetWidth(COL_IN)
    view.mode:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -ROW_MODE)
    view.mode.onPick = function(key)
        local box = progress()
        for i = 1, #MODES do
            if MODES[i].key == key then box.mode = i end
        end
        ns.Store.Clear(ID)
        ns.window:StartGame(ID)
    end
    ns.SetKeyText(ns.MakeCap(col, 0, ROW_PICK), "arkanoid.capPick")
    view.pick = ns.MakeKitButton(col)
    view.pick:SetWidth(COL_IN)
    view.pick:SetHeight(22)
    view.pick:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -ROW_STEP)
    view.pick.onClick = gridOpen
    view.skip = ns.MakeKitButton(col)
    view.skip:SetWidth(COL_IN)
    view.skip:SetHeight(22)
    view.skip:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -ROW_SKIP)
    ns.SetKeyText(view.skip, "arkanoid.skip")
    view.skip.onClick = function()
        local g = view.game
        if not g or g.phase == "over" then return end
        g:SkipWave()
    end
    view.reset = ns.MakeKitButton(col)
    view.reset:SetWidth(COL_IN)
    view.reset:SetHeight(22)
    view.reset:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -ROW_RESET)
    ns.SetKeyText(view.reset, "arkanoid.reset")
    view.reset.onClick = function()
        local box = progress()
        box.done, box.next, box.seed, box.mode = 0, 1, nil, MODE_DEFAULT
        box.clear = {}
        ns.Store.Clear(ID)
        ns.window:StartGame(ID)
    end
    buildGrid(canvas)
end
local function hideView()
    if not view then return end
    gridClose()
    view.pad:Hide()
    view.table:Hide()
    view.field:Hide()
    view.panel:Hide()
    view.art:Hide()
    if brickPool then brickPool:HideAll() end
    if ballPool then ballPool:HideAll() end
    if fallPool then fallPool:HideAll() end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.brick = {}
    self.brickMax = {}
    self.brickBonus = {}
    self.ball = {}
    self.fall = {}
    self.bonusIcon = {}
    self.pic = {}
    self.boardOrder, self.picOrder = {}, {}
    self.flash = {}
    self.chain, self.idleT = 0, 0
    self.padWideT, self.padStickyT = 0, 0
    return self
end
function Game:ApplyLayout(wave)
    local board = self:BoardFor(wave)
    for row = 1, ROWS do
        local s = board.rows[ROWS + 1 - row] or ""
        for col = 1, COLS do
            local i = (row - 1) * COLS + col
            local def = CELL[s:sub(col, col)] or CELL["."]
            self.brickMax[i] = def.hp
            self.brickBonus[i] = def.bonus or false
        end
    end
    local total = 0
    for i = 1, ROWS * COLS do
        if self.brickMax[i] > 0 then total = total + 1 end
    end
    self.total = total
end
function Game:BuildWave(wave)
    self.wave = wave
    progress().next = wave
    self:ApplyLayout(wave)
    local left = 0
    for i = 1, ROWS * COLS do
        self.brick[i] = self.brickMax[i]
        if self.brick[i] > 0 then left = left + 1 end
    end
    self.left = left
    self.idleT = 0
    self.flash = {}
    self.bricksDirty = true
end
function Game:AcquireBricks()
    brickPool:Reset()
    self.brickFrame = self.brickFrame or {}
    for row = 1, ROWS do
        for col = 1, COLS do
            local i = (row - 1) * COLS + col
            local f = brickPool:Acquire()
            self.brickFrame[i] = f
            if not f.positioned then
                f:ClearAllPoints()
                f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT",
                    colLeft(col), rowTop(row) - BRICK_H)
                f.positioned = true
            end
        end
    end
    brickPool:HideExtras()
end
function Game:RefreshBricks()
    if not self.bricksDirty then return end
    self.bricksDirty = false
    local pic = self:PicFor(self.wave)
    if pic then
        view.art:SetTexture(pic.path)
        view.art:SetTexCoord(pic.win[1], pic.win[2], pic.win[3], pic.win[4])
        view.art:SetVertexColor(PIC_BACK, PIC_BACK, PIC_BACK, 1)
        view.art:Show()
    else
        view.art:Hide()
    end
    local board = self:BoardFor(self.wave)
    for row = 1, ROWS do
        local r, g, b = brickRGB(board, row)
        for col = 1, COLS do
            local i = (row - 1) * COLS + col
            local f = self.brickFrame[i]
            local hp = self.brick[i]
            f.fill:SetVertexColor(1, 1, 1, 1)
            if self.brickMax[i] < 0 then
                local hasH = (col > 1 and self.brickMax[i - 1] < 0)
                    or (col < COLS and self.brickMax[i + 1] < 0)
                local hasV = (row > 1 and self.brickMax[i - COLS] < 0)
                    or (row < ROWS and self.brickMax[i + COLS] < 0)
                if hasH and hasV then
                    f.bar:SetWidth(BRICK_W)
                    f.bar:SetHeight(BRICK_H)
                elseif hasV then
                    f.bar:SetWidth(GOLD_BAR)
                    f.bar:SetHeight(BRICK_H)
                else
                    f.bar:SetWidth(BRICK_W)
                    f.bar:SetHeight(GOLD_BAR)
                end
                paintGoldBar(f, self.flash[i] and FLASH_BOOST or 0)
                f.bar:Show()
                f.fill:SetTexture(0, 0, 0, 0)
                f.edgeHi:Hide()
                f.edgeLow:Hide()
                f.art:Hide()
                f:Show()
            elseif hp <= 0 then
                f:Hide()
            else
                f.bar:Hide()
                local strong = self.brickMax[i] >= 2
                local hurt = hp < self.brickMax[i]
                local shade = 1
                if hurt then shade = HIT_SHADE
                elseif not strong then shade = NORMAL_SHADE end
                f.fill:SetTexture(BLANK_TEX)
                f.fill:SetGradientAlpha("VERTICAL",
                    r * shade * BRICK_LOW, g * shade * BRICK_LOW, b * shade * BRICK_LOW, 1,
                    r * shade, g * shade, b * shade, 1)
                if strong and not hurt then
                    f.edgeHi:SetTexture(1, 1, 1, EDGE_HI_A)
                    f.edgeLow:SetTexture(0, 0, 0, EDGE_LOW_A)
                    f.edgeHi:Show()
                    f.edgeLow:Show()
                else
                    f.edgeHi:Hide()
                    f.edgeLow:Hide()
                end
                if pic then
                    local k = PIC_MIX * shade
                    f.art:SetTexture(pic.path)
                    f.art:SetTexCoord(cellWindow(pic.win, row, col))
                    f.art:SetVertexColor(k, k, k, 1)
                    f.art:Show()
                else
                    f.art:Hide()
                end
                f:Show()
            end
        end
    end
end
function Game:CursorPos()
    local canvas = self.canvas
    local s = canvas:GetEffectiveScale()
    if not s or s == 0 then return nil, nil end
    local l, b = canvas:GetLeft(), canvas:GetBottom()
    if not l or not b then return nil, nil end
    local cx, cy = GetCursorPosition()
    return cx / s - l, cy / s - b
end
function Game:PadHalfW()
    local h = modeOf().pad / 2
    if self.padWideT > 0 then h = h * WIDE_MULT end
    return h
end
function Game:Speed()
    local m = modeOf()
    local total = self.total or 0
    local done = 0
    if total > 0 then done = (total - (self.left or 0)) / total end
    if done < 0 then done = 0 elseif done > 1 then done = 1 end
    return m.speed * (1 + m.gain * done)
end
function Game:AfterBounce(ball)
    local S = self:Speed()
    local floorV = ANTILOOP_FRAC * S
    if ball.vy == 0 then
        ball.vy = floorV
    elseif abs(ball.vy) < floorV then
        ball.vy = (ball.vy > 0) and floorV or -floorV
    end
    local mag = sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
    if mag > 0 then
        local k = S / mag
        ball.vx, ball.vy = ball.vx * k, ball.vy * k
    end
end
function Game:PushOut(ball, c)
    if c.axis == "x" then
        if ball.x < (c.left + c.right) / 2 then ball.x = c.left - BALL_HALF
        else ball.x = c.right + BALL_HALF end
    else
        if ball.y < (c.top + c.bottom) / 2 then ball.y = c.bottom - BALL_HALF
        else ball.y = c.top + BALL_HALF end
    end
end
function Game:HitBrick(i)
    if self.brickMax[i] < 0 then
        self.flash[i] = FLASH_T
        return false
    end
    self.idleT = 0
    self.chain = self.chain + 1
    local hp = self.brick[i] - 1
    if hp < 0 then hp = 0 end
    self.brick[i] = hp
    self.bricksDirty = true
    if hp > 0 then return false end
    self.left = self.left - 1
    local strong = self.brickMax[i] >= 2
    local kind = self.brickBonus[i]
    if kind then self:SpawnBonus(i, kind) end
    return true
end
function Game:SpawnBonus(i, kind)
    if #self.fall >= MAX_FALL then return end
    local row = ceil(i / COLS)
    local col = i - (row - 1) * COLS
    self.fall[#self.fall + 1] = {
        x = colLeft(col) + BRICK_W / 2,
        y = rowTop(row) - BRICK_H / 2,
        kind = kind,
    }
end
function Game:CheckBricks(ball)
    if self.left <= 0 then return end
    local left, right = ball.x - BALL_HALF, ball.x + BALL_HALF
    local bottom, top = ball.y - BALL_HALF, ball.y + BALL_HALF
    local hstep = BRICK_W + GAP
    local c1 = max(1, floor((left - MARGIN_X) / hstep) + 1)
    local c2 = min(COLS, floor((right - MARGIN_X) / hstep) + 1)
    if c1 > c2 then return end
    local vstep = BRICK_H + GAP
    local rt1 = floor((TOP_ROW_Y - top) / vstep)
    local rt2 = floor((TOP_ROW_Y - bottom) / vstep)
    local r1 = max(1, ROWS - rt2)
    local r2 = min(ROWS, ROWS - rt1)
    if r1 > r2 then return end
    local cand = {}
    for row = r1, r2 do
        local bTop, bBottom = rowTop(row), rowTop(row) - BRICK_H
        for col = c1, c2 do
            local i = (row - 1) * COLS + col
            if self.brick[i] ~= 0 then
                local bLeft = colLeft(col)
                local bRight = bLeft + BRICK_W
                local ox = min(right, bRight) - max(left, bLeft)
                local oy = min(top, bTop) - max(bottom, bBottom)
                if ox > 0 and oy > 0 then
                    cand[#cand + 1] = {
                        i = i, depth = min(ox, oy),
                        axis = (ox < oy) and "x" or "y",
                        left = bLeft, right = bRight, top = bTop, bottom = bBottom,
                    }
                end
            end
        end
    end
    if #cand == 0 then return end
    table.sort(cand, function(a, b) return a.depth > b.depth end)
    local primary = cand[1]
    local secondary
    for i = 2, #cand do
        if cand[i].axis ~= primary.axis then
            secondary = cand[i]
            break
        end
    end
    local removed = {}
    if self:HitBrick(primary.i) then removed[#removed + 1] = primary end
    self:PushOut(ball, primary)
    if secondary then
        if self:HitBrick(secondary.i) then removed[#removed + 1] = secondary end
        self:PushOut(ball, secondary)
        ball.vx, ball.vy = -ball.vx, -ball.vy
    elseif primary.axis == "x" then
        ball.vx = -ball.vx
    else
        ball.vy = -ball.vy
    end
    local a = (((floor(self.t * 997) % 7) - 3) / 3) * BOUNCE_JITTER
    local cs, sn = cos(a), sin(a)
    ball.vx, ball.vy = ball.vx * cs - ball.vy * sn, ball.vx * sn + ball.vy * cs
    if #removed == 0 and self.brickMax[primary.i] < 0 then
        ns.Sfx.Play("hover")
        self:GoldFX(primary.i)
    else
        ns.Sfx.Play("pop")
    end
    self:AfterBounce(ball)
    self:PlayBrickFX(removed)
    if self.left <= 0 then self:WaveClear() end
end
function Game:FXCell(row, col)
    local r, g, b = brickRGB(self:BoardFor(self.wave), row)
    return {
        x = colLeft(col) + BRICK_W / 2, y = rowTop(row) - BRICK_H / 2,
        size = BRICK_H, tex = self.brickTex, tint = { r, g, b },
    }
end
function Game:GoldFX(i)
    if self.t - (self.chimeT or -99) < GOLD_FX_GAP then return end
    self.chimeT = self.t
    local row = ceil(i / COLS)
    ns.FX.Play(self.canvas, { self:FXCell(row, i - (row - 1) * COLS) }, { force = "chime" })
end
function Game:PlayBrickFX(removed)
    if #removed == 0 then return end
    local big = self.left <= 0 or self.chain >= 3
    local cells = {}
    for _, c in ipairs(removed) do
        if self.brickMax[c.i] >= 2 then big = true end
        local row = ceil(c.i / COLS)
        cells[#cells + 1] = self:FXCell(row, c.i - (row - 1) * COLS)
    end
    ns.FX.Stop()
    ns.FX.Play(self.canvas, cells, { big = big, set = FX_SET })
end
function Game:PaddleTouch()
    ns.Sfx.Play("turn")
    self.chain = 0
end
function Game:PhysicsStep(ball, subDt, padHalf, sticky)
    local oldX, oldY = ball.x, ball.y
    if ball.vy < 0 then
        local oldBottom = oldY - BALL_HALF
        local newBottom = oldY + ball.vy * subDt - BALL_HALF
        if oldBottom >= PAD_TOP and newBottom < PAD_TOP then
            local frac = (oldBottom - PAD_TOP) / (oldBottom - newBottom)
            local hitX = oldX + ball.vx * subDt * frac
            if hitX + BALL_HALF > self.px - padHalf and hitX - BALL_HALF < self.px + padHalf then
                local u = (hitX - self.px) / padHalf
                if u < -1 then u = -1 elseif u > 1 then u = 1 end
                self:PaddleTouch()
                if sticky then
                    ball.stuck = true
                    ball.u = u
                    ball.x, ball.y = self.px + u * padHalf, PAD_TOP + BALL_HALF
                    ball.vx, ball.vy = 0, 0
                    return
                end
                local S = self:Speed()
                local a = u * ANGLE_MAX
                ball.vx = S * sin(a)
                ball.vy = S * cos(a)
                ball.x, ball.y = hitX, PAD_TOP + BALL_HALF
                return
            end
        end
    end
    local nx = oldX + ball.vx * subDt
    local ny = oldY + ball.vy * subDt
    local bounced = false
    if nx - BALL_HALF < 0 then
        nx = BALL_HALF
        ball.vx = -ball.vx
        bounced = true
    elseif nx + BALL_HALF > self.W then
        nx = self.W - BALL_HALF
        ball.vx = -ball.vx
        bounced = true
    end
    if ny + BALL_HALF > self.H then
        ny = self.H - BALL_HALF
        ball.vy = -ball.vy
        local S = self:Speed()
        if abs(ball.vx) < ANTILOOP_FRAC * S then
            ball.vx = (nx > self.W / 2) and -(ANTILOOP_FRAC * S) or (ANTILOOP_FRAC * S)
        end
        bounced = true
    end
    ball.x, ball.y = nx, ny
    if bounced then
        ns.Sfx.Play("hover")
        self:AfterBounce(ball)
    end
    self:CheckBricks(ball)
end
function Game:UpdateFalling(dt, padHalf)
    local padBottom, padTop = PAD_TOP - PAD_H, PAD_TOP
    local padLeft, padRight = self.px - padHalf, self.px + padHalf
    for i = #self.fall, 1, -1 do
        local f = self.fall[i]
        f.y = f.y - FALL_SPEED * dt
        local capLeft, capRight = f.x - FALL_W / 2, f.x + FALL_W / 2
        local capBottom, capTop = f.y - FALL_H / 2, f.y + FALL_H / 2
        if capRight > padLeft and capLeft < padRight and capTop > padBottom and capBottom < padTop then
            self:CatchBonus(f.kind)
            table.remove(self.fall, i)
        elseif capTop < 0 then
            table.remove(self.fall, i)
        end
    end
end
function Game:CatchBonus(kind)
    if kind == "wide" then
        self.padWideT = WIDE_DURATION
        ns.Sfx.Play("pick")
    elseif kind == "sticky" then
        self.padStickyT = STICKY_DURATION
        ns.Sfx.Play("pick")
    elseif kind == "multi" then
        self:SplitBalls()
        ns.Sfx.Play("big")
    end
end
function Game:SplitBalls()
    local S = self:Speed()
    local balls = {}
    for i = 1, #self.ball do
        local b = self.ball[i]
        local baseAngle = 0
        if b.vx ~= 0 or b.vy ~= 0 then baseAngle = atan2(b.vx, b.vy) end
        for k = 1, SPLIT_INTO do
            if #balls >= MAX_BALLS then break end
            local a = baseAngle + (k - (SPLIT_INTO + 1) / 2) * SPLIT_ANGLE
            balls[#balls + 1] = {
                x = b.x, y = b.y, vx = S * sin(a), vy = S * cos(a),
                stuck = false, u = 0,
            }
        end
    end
    if #balls > 0 then self.ball = balls end
end
function Game:FreshServe()
    self.phase = "serve"
    self.chain, self.idleT = 0, 0
    self.padWideT, self.padStickyT = 0, 0
    self.fall = {}
    self.ball = {
        { x = self.px, y = PAD_TOP + BALL_HALF, vx = 0, vy = 0, stuck = false, u = 0 },
    }
end
function Game:NextWave(scored)
    local box = progress()
    if self.wave > box.done then box.done = self.wave end
    if scored then
        ns.Sfx.Play("clear")
        box.clear[self.wave] = true
    end
    self.ball = {}
    self.fall = {}
    self.chain = 0
    self:BuildWave(self.wave + 1)
    self:FreshServe()
end
function Game:WaveClear()
    self:NextWave(true)
end
function Game:SkipWave()
    if self.phase == "over" then return end
    self:NextWave(false)
end
function Game:LoseBall()
    self.lives = self.lives - 1
    ns.Sfx.Play("deny")
    if self.lives <= 0 then
        self:EndGame()
    else
        self:FreshServe()
    end
end
function Game:EndGame()
    if self.phase == "over" then return end
    self.phase = "over"
    ns.Sfx.Play("over")
end
function Game:Stage(n)
    self:BuildWave(max(1, floor(n)))
    self:FreshServe()
end
function Game:Brink()
    self.lives = 1
end
function Game:PickOrder(rng)
    self.boardOrder = {}
    for i = 1, #boardPool() do self.boardOrder[i] = i end
    rng:Shuffle(self.boardOrder)
    self.picOrder = {}
    for i = 1, #ns.Pics.List(PIC_SET) do self.picOrder[i] = i end
    rng:Shuffle(self.picOrder)
    self.pic = {}
end
function Game:BoardFor(wave)
    local n = #self.boardOrder
    if n == 0 then return FALLBACK_BOARD end
    return boardPool()[self.boardOrder[1 + (wave - 1) % n]] or FALLBACK_BOARD
end
function Game:PicFor(wave)
    local got = self.pic[wave]
    if got ~= nil then return got or nil end
    local n = #self.picOrder
    local p = (n > 0) and ns.Pics.List(PIC_SET)[self.picOrder[1 + (wave - 1) % n]] or nil
    local path = p and ns.Pics.Path(PIC_SET, p.f)
    if not path then
        self.pic[wave] = false
        return nil
    end
    local l, r, t, b = fieldWindow(p)
    self.pic[wave] = { path = path, win = { l, r, t, b }, rec = p }
    return self.pic[wave]
end
function Game:Start(seed, moves)
    ensureView(self.canvas)
    self.W, self.H = PLAY_W, self.canvas.H or CANVAS_H
    self.px = self.W / 2
    self.lives = modeOf().lives
    self.phase = "serve"
    self.t = 0
    local box = progress()
    if not box.seed then box.seed = seed or 1 end
    self:PickOrder(ns.RNG.New(box.seed))
    local pickRng = ns.RNG.New(seed)
    self:BuildWave(floor(ns.Store.Num(progress().next, 1, WAVE_MAX, 1)))
    self:FreshServe()
    local brickName = ns.Shelves.Pick(ID, "brick", pickRng)
    self.brickTex = (brickName and ns.IconPath(brickName)) or BLANK_TEX
    for _, kind in ipairs(BONUS_KINDS) do
        local name = ns.Shelves.Pick(ID, "bonus_" .. kind, pickRng)
        self.bonusIcon[kind] = name and ns.IconPath(name) or nil
    end
    if moves and type(moves[1]) == "table" and moves[1].k == "snap" then
        self:Restore(moves[1])
    end
    self:AcquireBricks()
    view.table:Show()
    view.field:Show()
    view.panel:Show()
    view.pad:Show()
    self:Draw()
end
function Game:FadeFlash(dt)
    for i, t in pairs(self.flash) do
        t = t - dt
        if t <= 0 then
            self.flash[i] = nil
            local f = self.brickFrame and self.brickFrame[i]
            if f then paintGoldBar(f, 0) end
        else
            self.flash[i] = t
        end
    end
end
function Game:Update(dt)
    if view and view.grid and view.grid:IsShown() then return end
    if self.phase == "over" then
        self:Draw()
        return
    end
    self.t = self.t + dt
    local cx = self:CursorPos()
    local padHalf = self:PadHalfW()
    if cx then
        if cx < padHalf then cx = padHalf
        elseif cx > self.W - padHalf then cx = self.W - padHalf end
        self.px = cx
    end
    if self.phase == "serve" then
        for i = 1, #self.ball do
            self.ball[i].x = self.px
            self.ball[i].y = PAD_TOP + BALL_HALF
        end
        self:FadeFlash(dt)
        self:Draw()
        return
    end
    if self.padWideT > 0 then self.padWideT = max(0, self.padWideT - dt) end
    if self.padStickyT > 0 then self.padStickyT = max(0, self.padStickyT - dt) end
    local sticky = self.padStickyT > 0
    for i = 1, #self.ball do
        local b = self.ball[i]
        if b.stuck then
            b.x, b.y = self.px + b.u * padHalf, PAD_TOP + BALL_HALF
        end
    end
    local dist = SPEED_CEIL * dt
    local steps = (dist > SUBSTEP_MAX) and ceil(dist / SUBSTEP_MAX) or 1
    local subDt = dt / steps
    for i = 1, steps do
        if self.phase ~= "play" then break end
        for bi = #self.ball, 1, -1 do
            if self.phase ~= "play" then break end
            local b = self.ball[bi]
            if b and not b.stuck then
                self:PhysicsStep(b, subDt, padHalf, sticky)
            end
        end
    end
    if self.phase == "play" then
        for i = #self.ball, 1, -1 do
            local b = self.ball[i]
            if not b.stuck and b.y - BALL_HALF < 0 then table.remove(self.ball, i) end
        end
        if #self.ball == 0 then self:LoseBall() end
    end
    self:FadeFlash(dt)
    if self.phase == "play" then self:IdleTick(dt) end
    if self.phase == "play" then self:UpdateFalling(dt, padHalf) end
    self:Draw()
end
function Game:Recall()
    ns.Sfx.Play("stuck")
    self:FreshServe()
end
function Game:IdleTick(dt)
    if self.left <= 0 then return end
    self.idleT = self.idleT + dt
end
function Game:HasStuckBall()
    for i = 1, #self.ball do
        if self.ball[i].stuck then return true end
    end
    return false
end
function Game:Move(move)
    if not move then return end
    if move.k ~= "launch" then return end
    if self.phase == "serve" then
        self.phase = "play"
        local S = self:Speed()
        for i = 1, #self.ball do
            local b = self.ball[i]
            b.vx, b.vy = 0, S
        end
        ns.Sfx.Play("start")
        return
    end
    if self.phase == "play" then
        local S = self:Speed()
        local freed = false
        for i = 1, #self.ball do
            local b = self.ball[i]
            if b.stuck then
                b.stuck = false
                b.vx, b.vy = 0, S
                freed = true
            end
        end
        if freed then ns.Sfx.Play("start") end
    end
end
function Game:Click(x, y, button)
    if view and view.grid and view.grid:IsShown() then return end
    if button == "RightButton" then
        if self.phase == "play" and self.idleT >= RECALL_AFTER then self:Recall() end
        return
    end
    if button ~= "LeftButton" then return end
    if self.phase == "serve" then
        self:Move{ k = "launch" }
    elseif self.phase == "play" and self:HasStuckBall() then
        self:Move{ k = "launch" }
    end
end
function Game:Score()
    return 0
end
function Game:IsOver()
    return self.phase == "over"
end
function Game:Stop()
    hideView()
end
function Game:Draw()
    self:RefreshBricks()
    for i, t in pairs(self.flash) do
        local f = self.brickFrame and self.brickFrame[i]
        if f then paintGoldBar(f, FLASH_BOOST * (t / FLASH_T)) end
    end
    local padHalf = self:PadHalfW()
    view.pad:SetWidth(padHalf * 2)
    view.pad:ClearAllPoints()
    view.pad:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", self.px - padHalf, PAD_TOP - PAD_H)
    view.pad.fill:SetTexture(BLANK_TEX)
    view.pad.fill:SetGradientAlpha("VERTICAL",
        PAD_LOW[1], PAD_LOW[2], PAD_LOW[3], 1,
        PAD_HI[1], PAD_HI[2], PAD_HI[3], 1)
    local cr, cg, cb = PAD_HI[1], PAD_HI[2], PAD_HI[3]
    local capW = PAD_CAP_MIN
    if self.padStickyT > 0 then
        cr, cg, cb = ns.Palette.RGB(BONUS_COLOUR.sticky)
        capW = PAD_CAP_MIN + (PAD_CAP_MAX - PAD_CAP_MIN) * (self.padStickyT / STICKY_DURATION)
    elseif self.padWideT > 0 then
        cr, cg, cb = ns.Palette.RGB(BONUS_COLOUR.wide)
        capW = PAD_CAP_MIN + (PAD_CAP_MAX - PAD_CAP_MIN) * (self.padWideT / WIDE_DURATION)
    end
    view.pad.capL:SetWidth(capW)
    view.pad.capL:SetTexture(BLANK_TEX)
    view.pad.capL:SetGradientAlpha("VERTICAL", cr * 0.7, cg * 0.7, cb * 0.7, 1, cr, cg, cb, 1)
    view.pad.capR:SetWidth(capW)
    view.pad.capR:SetTexture(BLANK_TEX)
    view.pad.capR:SetGradientAlpha("VERTICAL", cr * 0.7, cg * 0.7, cb * 0.7, 1, cr, cg, cb, 1)
    view.pad.gloss:SetTexture(cr, cg, cb, 0.5)
    local heat = min(self.chain, CHAIN_HOT) / CHAIN_HOT
    local br = BALL_COLD[1] + (BALL_HOT[1] - BALL_COLD[1]) * heat
    local bg = BALL_COLD[2] + (BALL_HOT[2] - BALL_COLD[2]) * heat
    local bb = BALL_COLD[3] + (BALL_HOT[3] - BALL_COLD[3]) * heat
    ballPool:Reset()
    for i = 1, #self.ball do
        local b = self.ball[i]
        local f = ballPool:Acquire()
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", b.x - BALL_HALF, b.y - BALL_HALF)
        f.fill:SetVertexColor(br, bg, bb, 1)
        f.halo:SetVertexColor(br, bg, bb, HALO_A_MIN + HALO_A_RANGE * heat)
    end
    ballPool:HideExtras()
    fallPool:Reset()
    for i = 1, #self.fall do
        local fb = self.fall[i]
        local f = fallPool:Acquire()
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", fb.x - FALL_W / 2, fb.y - FALL_H / 2)
        if f.kindDrawn ~= fb.kind then
            f.kindDrawn = fb.kind
            local r, g, b = ns.Palette.RGB(BONUS_COLOUR[fb.kind])
            f.fill:SetTexture(BLANK_TEX)
            f.fill:SetGradientAlpha("VERTICAL", r * 0.6, g * 0.6, b * 0.6, 1, r, g, b, 1)
            local icon = self.bonusIcon[fb.kind]
            if icon then
                f.badge:SetTexture(icon)
                ns.CropIcon(f.badge)
                f.badge:Show()
            else
                f.badge:Hide()
            end
        end
    end
    fallPool:HideExtras()
    view.waveText:SetText((ns.T("arkanoid.waveFmt")):format(self.wave))
    local pic = self:PicFor(self.wave)
    local cap = pic and pic.rec and ns.Pics.Label(pic.rec) or ""
    view.picText:SetText((cap ~= "?") and cap or "")
    local lives = max(self.lives, 0)
    local have = modeOf().lives
    for i = 1, LIVES_CAP do
        if i > have then
            view.dot[i]:Hide()
        else
            view.dot[i]:Show()
            if i <= lives then
                view.dot[i]:SetVertexColor(1, 1, 1, 1)
            else
                view.dot[i]:SetVertexColor(0.35, 0.35, 0.42, 0.5)
            end
        end
    end
end
function Game:PanelSync()
    if not view then return end
    view.game = self
    if view.board then view.board:Sync() end
    local box = progress()
    local top = box.done + 1
    local pool = #boardPool()
    if top > pool then top = pool end
    if top < 1 then top = 1 end
    view.pick:SetText(ns.T("arkanoid.pickFmt"):format(self.wave))
    local _, mi = modeOf()
    if view.modeAt ~= mi then
        view.modeAt = mi
        view.mode:SetOptions(MODES, MODES[mi].key, "arkanoid.capMode")
    end
    if view.pickTop ~= top or view.pickAt ~= self.wave then
        view.pickTop, view.pickAt = top, self.wave
        if view.grid and view.grid:IsShown() then gridFill() end
    end
end
function Game:Serialize()
    local br = {}
    for i = 1, ROWS * COLS do br[i] = self.brick[i] end
    local balls = {}
    for i = 1, #self.ball do
        local b = self.ball[i]
        balls[i] = { x = b.x, y = b.y, vx = b.vx, vy = b.vy, stuck = b.stuck and 1 or 0, u = b.u or 0 }
    end
    local fall = {}
    for i = 1, #self.fall do
        local f = self.fall[i]
        fall[i] = { x = f.x, y = f.y, kind = f.kind }
    end
    return {
        k = "snap", v = 7,
        wave = self.wave, lives = self.lives,
        phase = self.phase,
        t = self.t,
        padWideT = self.padWideT, padStickyT = self.padStickyT,
        chain = self.chain,
        brick = br, ball = balls, fall = fall,
    }
end
function Game:Restore(s)
    if s.v ~= 7 then return end
    self.wave  = floor(ns.Store.Num(s.wave, 1, WAVE_MAX, 1))
    progress().next = self.wave
    local lv = modeOf().lives
    self.lives = floor(ns.Store.Num(s.lives, 0, lv, lv))
    self.t     = ns.Store.Num(s.t, 0, 1e6, 0)
    local phase = s.phase
    if phase ~= "serve" and phase ~= "play" and phase ~= "over" then phase = "serve" end
    self.phase = phase
    self.chain = floor(ns.Store.Num(s.chain, 0, 999, 0))
    self:ApplyLayout(self.wave)
    local br = type(s.brick) == "table" and s.brick or nil
    local left = 0
    if br and #br == ROWS * COLS then
        for i = 1, ROWS * COLS do
            if self.brickMax[i] < 0 then
                self.brick[i] = -1
            else
                local hp = floor(ns.Store.Num(br[i], 0, self.brickMax[i], 0))
                self.brick[i] = hp
                if hp > 0 then left = left + 1 end
            end
        end
    end
    local emptyOK = (self.phase == "over")
    if not br or #br ~= ROWS * COLS or (left == 0 and not emptyOK) then
        self:BuildWave(self.wave)
    else
        self.left = left
        self.bricksDirty = true
    end
    self.padWideT   = ns.Store.Num(s.padWideT, 0, WIDE_DURATION, 0)
    self.padStickyT = ns.Store.Num(s.padStickyT, 0, STICKY_DURATION, 0)
    local S = self:Speed()
    self.ball = {}
    local balls = type(s.ball) == "table" and s.ball or nil
    if balls then
        for i = 1, min(#balls, MAX_BALLS) do
            local bs = balls[i]
            if type(bs) == "table" then
                local x = ns.Store.Num(bs.x, BALL_HALF, self.W - BALL_HALF, self.W / 2)
                local y = ns.Store.Num(bs.y, BALL_HALF, self.H - BALL_HALF, PAD_TOP + BALL_HALF)
                local stuck = (bs.stuck == 1 or bs.stuck == true)
                local u = ns.Store.Num(bs.u, -1, 1, 0)
                local vx, vy = 0, 0
                if self.phase == "play" and not stuck then
                    vx = ns.Store.Num(bs.vx, -SPEED_CEIL, SPEED_CEIL, 0)
                    vy = ns.Store.Num(bs.vy, -SPEED_CEIL, SPEED_CEIL, S)
                    local mag = sqrt(vx * vx + vy * vy)
                    if mag > 0 then vx, vy = vx * (S / mag), vy * (S / mag) else vx, vy = 0, S end
                end
                self.ball[#self.ball + 1] = { x = x, y = y, vx = vx, vy = vy, stuck = stuck, u = u }
            end
        end
    end
    if #self.ball == 0 and self.phase ~= "over" then
        self.ball[1] = { x = self.px, y = PAD_TOP + BALL_HALF, vx = 0, vy = 0, stuck = false, u = 0 }
        if self.phase == "play" then self.phase = "serve" end
    end
    self.fall = {}
    local fall = type(s.fall) == "table" and s.fall or nil
    if fall then
        for i = 1, min(#fall, MAX_FALL) do
            local fs = fall[i]
            if type(fs) == "table" and (fs.kind == "wide" or fs.kind == "multi" or fs.kind == "sticky") then
                self.fall[#self.fall + 1] = {
                    x = ns.Store.Num(fs.x, 0, self.W, self.W / 2),
                    y = ns.Store.Num(fs.y, 0, self.H, self.H),
                    kind = fs.kind,
                }
            end
        end
    end
end
local MINI_BACK  = { 0.05, 0.05, 0.08 }
local MINI_GOLD  = { 0.80, 0.62, 0.24 }
local MINI_BRICK = { 0.25, 0.60, 1.00 }
local MINI_BALL  = { 1.00, 0.95, 0.85 }
local MINI = {
    {
        cols = 7, rows = 5, cell = 22, gap = 2, back = "plain",
        fill = {
            { c = 1, r = 5, col = MINI_GOLD }, { c = 2, r = 5, col = MINI_GOLD },
            { c = 3, r = 5, col = MINI_GOLD }, { c = 4, r = 5, col = MINI_GOLD },
            { c = 5, r = 5, col = MINI_GOLD }, { c = 6, r = 5, col = MINI_GOLD },
            { c = 7, r = 5, col = MINI_GOLD },
            { c = 1, r = 4, col = MINI_GOLD }, { c = 7, r = 4, col = MINI_GOLD },
            { c = 1, r = 3, col = MINI_GOLD }, { c = 7, r = 3, col = MINI_GOLD },
            { c = 1, r = 2, col = MINI_GOLD }, { c = 2, r = 2, col = MINI_GOLD },
            { c = 6, r = 2, col = MINI_GOLD }, { c = 7, r = 2, col = MINI_GOLD },
            { c = 2, r = 4, col = MINI_BRICK }, { c = 3, r = 4, col = MINI_BRICK },
            { c = 4, r = 4, col = MINI_BRICK }, { c = 5, r = 4, col = MINI_BRICK },
            { c = 6, r = 4, col = MINI_BRICK },
            { c = 2, r = 3, col = MINI_BRICK }, { c = 3, r = 3, col = MINI_BRICK },
            { c = 4, r = 3, col = MINI_BRICK }, { c = 5, r = 3, col = MINI_BRICK },
            { c = 6, r = 3, col = MINI_BRICK },
        },
        arrow = { { c1 = 4, r1 = 1, c2 = 4, r2 = 3, col = MINI_BALL } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_BACK)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpArtCamera(host) paintMini(host, MINI[1]) end
ns.RegisterGame{
    id = ID,
    label = "arkanoid.label",
    icon = 40001,
    tip = "arkanoid.tip",
    order = 9,
    duo = "none",
    look = LOOK,
    physics = true,
    ownPanel = true,
    tally = false,
    record = false,
    finale = true,
    done = true,
    fx = true,
    New = New,
    stages = { max = WAVE_MAX },
    help = {
        "arkanoid.help1",
        "arkanoid.help2",
        "arkanoid.help3",
        { art = helpArtCamera, h = 126 },
        "arkanoid.help4",
        "arkanoid.help5",
    },
}
