local ADDON, ns = ...
local ID = "stack"
local floor, ceil = math.floor, math.ceil
local format = string.format
local COLS, ROWS, CELL, GAP = 12, 8, 48, 4
local OFFSET_X, OFFSET_Y = 32, 16
local FIELD_W, FIELD_H = COLS * CELL, ROWS * CELL
local CANVAS_W, CANVAS_H = 640, 480
local LANE_H, BEAM_H, FLOOR_H = 56, 24, OFFSET_Y
local LANE_Y = OFFSET_Y + FIELD_H
local BEAM_Y = LANE_Y + LANE_H
local EMPTY_TEX = "Interface\\Buttons\\WHITE8X8"
local C_TIER = {
    { 0.200, 0.172, 0.142 },
    { 0.186, 0.160, 0.132 },
    { 0.174, 0.150, 0.124 },
    { 0.180, 0.156, 0.128 },
}
local RACK = {
    deep = { 0.105, 0.088, 0.072 },
    post = { 0.255, 0.300, 0.385 }, postLit = { 0.345, 0.400, 0.500 },
    beam = { 0.470, 0.290, 0.140 }, beamLit = { 0.620, 0.385, 0.190 },
    pallet = { { 0.40, 0.30, 0.19 }, { 0.36, 0.27, 0.175 }, { 0.32, 0.24, 0.16 }, { 0.29, 0.215, 0.145 } },
    boxA = { { 0.40, 0.33, 0.24 }, { 0.365, 0.30, 0.22 }, { 0.33, 0.27, 0.20 }, { 0.30, 0.245, 0.18 } },
    boxB = { { 0.35, 0.29, 0.21 }, { 0.32, 0.26, 0.19 }, { 0.29, 0.235, 0.175 }, { 0.26, 0.21, 0.155 } },
    boxEdge = { { 0.46, 0.38, 0.28 }, { 0.42, 0.35, 0.26 }, { 0.38, 0.31, 0.23 }, { 0.34, 0.28, 0.21 } },
    wrap = { 0.40, 0.39, 0.37 }, wrapLit = { 0.49, 0.48, 0.46 }, wrapDim = { 0.32, 0.31, 0.30 },
}
local C_WALL_SLAB = { 0.370, 0.340, 0.305 }
local C_WALL_SEAM = { 0.245, 0.225, 0.205 }
local C_WALL_EDGE = { 0.560, 0.520, 0.470 }
local C_WALL_DARK = { 0.190, 0.175, 0.160 }
local C_LANE      = { 0.080, 0.090, 0.105 }
local C_RAIL      = { 0.290, 0.315, 0.360 }
local C_RAIL_LIT  = { 0.480, 0.510, 0.565 }
local C_RAIL_SHADOW = { 0.135, 0.150, 0.172 }
local C_WIN       = { 0.200, 0.235, 0.285 }
local C_WIN_LIT   = { 0.305, 0.355, 0.415 }
local C_HUD       = { 0.086, 0.094, 0.110 }
local C_HUD_TOP   = { 0.228, 0.250, 0.282 }
local C_HUD_SEP   = { 0.200, 0.228, 0.260 }
local C_WALL      = { 0.105, 0.092, 0.082 }
local C_FLOOR     = { 0.290, 0.220, 0.150 }
local C_FLOOR_LIT = { 0.495, 0.385, 0.260 }
local C_FLOOR_MID = { 0.370, 0.290, 0.196 }
local C_SEAM      = { 0.190, 0.140, 0.100 }
local C_TAPE      = { 0.825, 0.655, 0.180 }
local C_TAPE_DARK = { 0.165, 0.118, 0.070 }
local C_LINE_V    = { 0.36, 0.32, 0.28 }
local C_LINE_H    = { 0.24, 0.21, 0.18 }
local C_NEAR      = { 1.00, 0.86, 0.35 }
local C_SEAM_D    = { 0.30, 0.19, 0.10 }
local C_SEAM_L    = { 0.72, 0.53, 0.32 }
local C_STRAP     = { 0.20, 0.14, 0.10 }
local C_METAL     = { 0.62, 0.60, 0.56 }
local C_LID       = { 0.66, 0.48, 0.28 }
local C_HOOP      = { 0.45, 0.43, 0.40 }
local CRATE_KINDS = {
    {
        body = { 0.55, 0.38, 0.22 }, top = { 0.76, 0.56, 0.33 }, bot = { 0.29, 0.18, 0.10 },
        b1 = { 13, 3, 2, 37, C_SEAM_D }, b2 = { 29, 3, 2, 37, C_SEAM_D },
        a1 = { 15, 3, 1, 37, C_SEAM_L }, a2 = { 31, 3, 1, 37, C_SEAM_L },
    },
    {
        body = { 0.57, 0.40, 0.22 }, top = { 0.78, 0.58, 0.34 }, bot = { 0.30, 0.19, 0.10 },
        b1 = { 0, 9, 44, 5, C_STRAP }, b2 = { 0, 28, 44, 5, C_STRAP },
        a1 = { 18, 3, 6, 37, C_STRAP }, a2 = { 30, 27, 6, 7, C_METAL },
    },
    {
        body = { 0.53, 0.38, 0.24 }, top = { 0.75, 0.56, 0.35 }, bot = { 0.28, 0.19, 0.11 },
        b1 = { 0, 31, 44, 9, C_LID }, b2 = { 0, 29, 44, 2, C_SEAM_D },
        a1 = { 3, 3, 3, 37, C_METAL }, a2 = { 38, 3, 3, 37, C_METAL },
    },
    {
        body = { 0.58, 0.44, 0.27 }, top = { 0.80, 0.62, 0.38 }, bot = { 0.30, 0.21, 0.13 },
        b1 = { 13, 3, 2, 37, C_SEAM_D }, b2 = { 29, 3, 2, 37, C_SEAM_D },
        a1 = { 0, 30, 44, 4, C_HOOP }, a2 = { 0, 9, 44, 4, C_HOOP },
    },
    {
        body = { 0.80, 0.74, 0.62 }, top = { 0.90, 0.85, 0.74 }, bot = { 0.42, 0.38, 0.30 },
        b1 = { 12, 20, 20, 9, { 1.00, 0.82, 0.18 } }, b2 = { 8, 17, 28, 3, { 1.00, 0.82, 0.18 } },
        a1 = { 15, 25, 6, 2, { 1.00, 0.94, 0.62 } },
        bonus = "helmet",
    },
    {
        body = { 0.80, 0.74, 0.62 }, top = { 0.90, 0.85, 0.74 }, bot = { 0.42, 0.38, 0.30 },
        b1 = { 19, 9, 6, 18, { 0.35, 0.85, 0.45 } }, b2 = { 13, 25, 18, 5, { 0.35, 0.85, 0.45 } },
        a1 = { 17, 30, 10, 4, { 0.35, 0.85, 0.45 } }, a2 = { 20, 34, 4, 3, { 0.35, 0.85, 0.45 } },
        bonus = "super",
    },
    {
        body = { 0.80, 0.74, 0.62 }, top = { 0.90, 0.85, 0.74 }, bot = { 0.42, 0.38, 0.30 },
        b1 = { 13, 13, 18, 18, { 0.95, 0.78, 0.25 } },
        a1 = { 17, 17, 10, 10, { 0.70, 0.52, 0.12 } },
        bonus = "points",
    },
}
local PLAIN_KINDS = 4
local BONUS_EVERY = 20
local TOAST_T = 2.4
local BONUS_GOT = { helmet = "stack.gotHelmet", super = "stack.gotSuper", points = "stack.gotPoints" }
local BONUS_ORDER = { 5, 6, 7 }
local SUPER_JUMPS = 3
local BONUS_SCORE = 150
local C_SKIN      = { 0.91, 0.73, 0.56 }
local C_LEG       = { 0.20, 0.24, 0.34 }
local LOOK = ns.MakeLook{ wood = C_FLOOR, edge = C_NEAR, screen = C_WALL }
local WORKER_DEF = "hand"
local WORKERS = {
    { key = "hand", label = "stack.workerHandLabel", push = 1, jump = 1,
      hat = { 1.00, 0.82, 0.18 }, vest = { 0.92, 0.42, 0.14 },
      tip = "stack.workerHandTip" },
    { key = "strong", label = "stack.workerStrongLabel", push = 2, jump = 1,
      hat = { 0.95, 0.30, 0.26 }, vest = { 0.86, 0.20, 0.16 },
      tip = "stack.workerStrongTip" },
    { key = "climber", label = "stack.workerClimberLabel", push = 1, jump = 2,
      hat = { 0.40, 0.85, 0.95 }, vest = { 0.16, 0.55, 0.72 },
      tip = "stack.workerClimberTip" },
}
local SHIFT_DEF = "day"
local SHIFTS = {
    { key = "morning", label = "stack.shiftMorningLabel", grabs = 1,
      tip = "stack.shiftMorningTip" },
    { key = "day", label = "stack.shiftDayLabel", grabs = 3,
      tip = "stack.shiftDayTip" },
    { key = "night", label = "stack.shiftNightLabel", grabs = 5,
      tip = "stack.shiftNightTip" },
}
local function shiftOf(key)
    for i = 1, #SHIFTS do
        if SHIFTS[i].key == key then return SHIFTS[i] end
    end
    return SHIFTS[2]
end
local function workerOf(key)
    for i = 1, #WORKERS do
        if WORKERS[i].key == key then return WORKERS[i] end
    end
    return WORKERS[1]
end
local C_PAD       = { 1.00, 0.62, 0.20 }
local C_PAD_KILL  = { 0.96, 0.22, 0.16 }
local GC = {
    grab = { 0.880, 0.480, 0.095 }, lit = { 0.965, 0.700, 0.410 }, dim = { 0.590, 0.285, 0.045 },
    arm = { 0.790, 0.410, 0.060 }, pad = { 0.110, 0.110, 0.125 },
    wheel = { 0.590, 0.630, 0.675 }, mast = { 0.430, 0.465, 0.520 }, chain = { 0.275, 0.380, 0.495 },
}
local G = {
    w = 60, frameH = LANE_H, dropT = 0.22,
    ride = 150, ridePath = CANVAS_W + 2 * CELL, max = 8,
    wait = 0.2, holdGaps = 3, holdP = 80,
}
local C_BOOT = { 0.12, 0.10, 0.09 }
local C_EYE  = { 0.10, 0.08, 0.06 }
local C_STRIPE = { 0.96, 0.91, 0.75 }
local C_BELT = { 0.16, 0.13, 0.11 }
local KIND_ORDER = { 1, 3, 2, 4, 1, 2, 4, 3, 2, 1, 4, 3, 1 }
local function KindFor(drop)
    if drop % BONUS_EVERY == 0 then
        return BONUS_ORDER[((drop / BONUS_EVERY - 1) % #BONUS_ORDER) + 1]
    end
    return KIND_ORDER[(drop % #KIND_ORDER) + 1]
end
local BAY_W, TIER_H, BAYS, TIERS = 72, 96, 8, 4
local RACK_PLAN = { "FWEFHFEW", "HFFEWFHF", "FEWFFHFE", "WFHFEFWF" }
local WIN_W, WIN_H = 60, 22
local NEAR_LEFT = 4
local P = {
    fallTick = 0.18, stepTick = 0.15, walkV = 256, airK = 0.6, grav = 1400, jumpClear = 11,
    coyote = 0.08, pushDelay = 0.10, substep = 1 / 120,
    bodyH = CELL - GAP, halfW = (CELL - GAP) / 2, edge = 6,
    jumpBuffer = 0.30, overFlash = 0.6,
}
local JUMP_V = {
    math.sqrt(2 * P.grav * (1 * CELL + P.jumpClear)),
    math.sqrt(2 * P.grav * (2 * CELL + P.jumpClear)),
    math.sqrt(2 * P.grav * (3 * CELL + P.jumpClear)),
}
local BOX_SCORE, ROW_SCORE = 5, 100
local SNAP_V = 6
local START_MIN, START_MAX = 10, 12
local START_H, START_GAP = 2, 3
local START_TRIES, START_SEED = 40, 1
local function startWall(heights, c)
    if c < 1 or c > COLS then return START_H end
    return heights[c]
end
local function startOk(heights, wc)
    local total = 0
    for c = 1, COLS do total = total + heights[c] end
    if total < START_MIN or total > START_MAX then return false end
    if heights[wc] > 0 then return false end
    if startWall(heights, wc - 1) >= START_H then return false end
    if startWall(heights, wc + 1) >= START_H then return false end
    for r = 1, START_H do
        local fill = 0
        for c = 1, COLS do
            if heights[c] >= r then fill = fill + 1 end
        end
        if fill > COLS - START_GAP then return false end
    end
    for c = 1, COLS do
        if heights[c] == 0 and startWall(heights, c - 1) >= START_H
            and startWall(heights, c + 1) >= START_H then
            return false
        end
    end
    return true
end
local function startGrid(rng, wc)
    local heights
    for _ = 1, START_TRIES do
        local h = {}
        for c = 1, COLS do h[c] = 0 end
        local want = rng:Int(START_MIN, START_MAX)
        local left, bases = want, 0
        for _ = 1, want * 8 do
            if left == 0 then break end
            local c = rng:Int(COLS)
            local lim = START_H
            if c == wc then
                lim = 0
            elseif c == wc - 1 or c == wc + 1 then
                lim = START_H - 1
            end
            if h[c] == 0 and bases >= COLS - START_GAP then lim = 0 end
            if h[c] < lim then
                if h[c] == 0 then bases = bases + 1 end
                h[c] = h[c] + 1
                left = left - 1
            end
        end
        if left == 0 and startOk(h, wc) then heights = h; break end
    end
    if not heights then
        heights = {}
        for c = 1, COLS do
            heights[c] = (c < wc - 1 or c > wc + 1) and 1 or 0
        end
        heights[1] = START_H
    end
    local grid = {}
    for c = 1, COLS do
        for r = 1, heights[c] do
            grid[r] = grid[r] or {}
            grid[r][c] = rng:Int(PLAIN_KINDS)
        end
    end
    return grid
end
local function clamp01(v)
    if v > 1 then return 1 end
    if v < 0 then return 0 end
    return v
end
local function cellCenterX(c) return OFFSET_X + (c - 1) * CELL + CELL / 2 end
local function cellCenterY(r) return (r - 1) * CELL + CELL / 2 end
local view, boxPool, grabPool, markPool, holdPool
local showcase
local pending
local function boxFrame(canvas)
    local f = ns.PlainFrame(canvas, 2)
    f:Hide()
    local side = CELL - GAP
    f:SetWidth(side)
    f:SetHeight(side)
    f.body = ns.Fill(f, "BACKGROUND", CRATE_KINDS[1].body)
    f.body:SetAllPoints()
    f.b1 = ns.Fill(f, "BORDER", CRATE_KINDS[1].b1[5])
    f.b2 = ns.Fill(f, "BORDER", CRATE_KINDS[1].b2[5])
    f.top = ns.Fill(f, "ARTWORK", CRATE_KINDS[1].top)
    f.top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.top:SetHeight(4)
    f.bot = ns.Fill(f, "ARTWORK", CRATE_KINDS[1].bot)
    f.bot:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.bot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.bot:SetHeight(3)
    f.a1 = ns.Fill(f, "ARTWORK", CRATE_KINDS[1].a1[5])
    f.a2 = ns.Fill(f, "ARTWORK", CRATE_KINDS[1].a2[5])
    f.badge = f:CreateTexture(nil, "OVERLAY")
    f.badge:SetWidth(26)
    f.badge:SetHeight(26)
    f.badge:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.badge:Hide()
    f.kind = nil
    return f
end
local function dressBox(f, kind)
    if f.kind == kind then return end
    f.kind = kind
    local k = CRATE_KINDS[kind] or CRATE_KINDS[1]
    ns.Paint(f.body, k.body[1], k.body[2], k.body[3])
    ns.Paint(f.top, k.top[1], k.top[2], k.top[3])
    ns.Paint(f.bot, k.bot[1], k.bot[2], k.bot[3])
    local slots = { f.b1, f.b2, f.a1, f.a2 }
    local parts = { k.b1, k.b2, k.a1, k.a2 }
    for i = 1, 4 do
        local t, p = slots[i], parts[i]
        if p then
            ns.Paint(t, p[5][1], p[5][2], p[5][3])
            t:SetWidth(p[3]); t:SetHeight(p[4])
            t:ClearAllPoints()
            t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", p[1], p[2])
            t:Show()
        else
            t:Hide()
        end
    end
end
local function grabFrame(canvas)
    local f = ns.PlainFrame(canvas, 4)
    f:Hide()
    f:SetWidth(G.w)
    f:SetHeight(G.frameH)
    local function part(layer, col, x, y, w, h)
        local t = ns.Fill(f, layer, col)
        t:SetWidth(w); t:SetHeight(h)
        t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
        return t
    end
    part("BORDER", GC.wheel, 10, 50, 6, 5)
    part("BORDER", GC.wheel, 44, 50, 6, 5)
    part("BORDER", GC.mast, 26, 50, 8, 4)
    part("ARTWORK", GC.chain, 15, 50, 30, 2)
    f.beam = part("BACKGROUND", GC.grab, 6, 44, 48, 6)
    part("BORDER", GC.lit, 6, 49, 48, 1)
    part("BORDER", GC.dim, 6, 44, 48, 1)
    f.arm, f.pad = {}, {}
    for i = 1, 2 do
        f.arm[i] = ns.Fill(f, "ARTWORK", GC.arm)
        f.arm[i]:SetWidth(6)
        f.pad[i] = ns.Fill(f, "OVERLAY", GC.pad)
        f.pad[i]:SetWidth(7); f.pad[i]:SetHeight(10)
    end
    return f
end
local function spreadGrab(f, k)
    if f.spread == k then return end
    f.spread = k
    local out, lift = 6 * k, 8 * k
    local h = 38 - lift
    for i = 1, 2 do
        local ax = (i == 1) and (6 - out) or (48 + out)
        f.arm[i]:SetHeight(h)
        f.arm[i]:ClearAllPoints()
        f.arm[i]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", ax, 6 + lift)
        f.pad[i]:ClearAllPoints()
        f.pad[i]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", (i == 1) and ax or (ax - 1), 4 + lift)
    end
end
local function markFrame(canvas)
    local f = ns.PlainFrame(canvas, 1)
    f:Hide()
    f:SetWidth(CELL - GAP)
    f:SetHeight(CELL - GAP)
    f.pad = ns.Fill(f, "BORDER", C_PAD)
    f.pad:SetAllPoints()
    f.line = ns.Fill(f, "ARTWORK", C_PAD)
    f.line:SetWidth(CELL - GAP); f.line:SetHeight(3)
    f.line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.guide = ns.Fill(f, "ARTWORK", C_PAD)
    f.guide:SetWidth(2); f.guide:SetHeight(1)
    f.guide:SetPoint("BOTTOM", f, "TOP", 0, 0)
    return f
end
local function workerFrame(canvas)
    local f = ns.PlainFrame(canvas, 3)
    f:Hide()
    local side = CELL - GAP
    f:SetWidth(side)
    f:SetHeight(side)
    f.legL = ns.Fill(f, "BACKGROUND", C_LEG)
    f.legR = ns.Fill(f, "BACKGROUND", C_LEG)
    f.bootL = ns.Fill(f, "BORDER", C_BOOT)
    f.bootL:SetWidth(7); f.bootL:SetHeight(3)
    f.bootR = ns.Fill(f, "BORDER", C_BOOT)
    f.bootR:SetWidth(7); f.bootR:SetHeight(3)
    f.body = ns.Fill(f, "BORDER", WORKERS[1].vest)
    f.body:SetWidth(22); f.body:SetHeight(17)
    f.stripe = ns.Fill(f, "ARTWORK", C_STRIPE)
    f.stripe:SetWidth(22); f.stripe:SetHeight(3)
    f.belt = ns.Fill(f, "ARTWORK", C_BELT)
    f.belt:SetWidth(22); f.belt:SetHeight(2)
    f.armL = ns.Fill(f, "BORDER", WORKERS[1].vest)
    f.armR = ns.Fill(f, "BORDER", WORKERS[1].vest)
    f.gloveL = ns.Fill(f, "ARTWORK", C_SKIN)
    f.gloveR = ns.Fill(f, "ARTWORK", C_SKIN)
    f.head = ns.Fill(f, "BORDER", C_SKIN)
    f.head:SetWidth(13); f.head:SetHeight(10)
    f.eye = ns.Fill(f, "ARTWORK", C_EYE)
    f.eye:SetWidth(2); f.eye:SetHeight(2)
    f.eye2 = ns.Fill(f, "ARTWORK", C_EYE)
    f.eye2:SetWidth(2); f.eye2:SetHeight(2)
    f.hat = ns.Fill(f, "BORDER", WORKERS[1].hat)
    f.hat:SetWidth(21); f.hat:SetHeight(6)
    f.brim = ns.Fill(f, "ARTWORK", WORKERS[1].hat)
    f.brim:SetWidth(25); f.brim:SetHeight(2)
    f.badge = f:CreateTexture(nil, "OVERLAY")
    f.badge:SetWidth(15); f.badge:SetHeight(15)
    f.badge:Hide()
    return f
end
local function paintFloor(box)
    box("BACKGROUND", C_FLOOR, 0, 0, CANVAS_W, FLOOR_H)
    box("BORDER", C_FLOOR_LIT, 0, FLOOR_H - 1, CANVAS_W, 1)
    box("BORDER", C_FLOOR_MID, 0, FLOOR_H - 3, CANVAS_W, 2)
    for k = 1, 9 do box("BORDER", C_SEAM, k * 64, 6, 1, FLOOR_H - 9) end
    box("BORDER", C_TAPE_DARK, 0, 0, CANVAS_W, 6)
    for x = 0, CANVAS_W - 12, 24 do box("ARTWORK", C_TAPE, x, 0, 12, 6) end
end
local function paintRack(box)
    for t = 1, TIERS do
        local y = OFFSET_Y + FIELD_H - t * TIER_H
        box("BACKGROUND", C_TIER[t], OFFSET_X, y, FIELD_W, TIER_H)
        local a, b, e = RACK.boxA[t], RACK.boxB[t], RACK.boxEdge[t]
        for i = 1, BAYS do
            local kind = RACK_PLAN[t]:sub(i, i)
            local x = OFFSET_X + (i - 1) * BAY_W
            if kind == "E" then
                box("BORDER", RACK.deep, x + 5, y + 5, 62, 86)
            else
                box("BORDER", RACK.pallet[t], x + 6, y + 5, 60, 6)
                box("ARTWORK", e, x + 6, y + 10, 60, 1)
            end
            if kind == "F" then
                box("BORDER", a, x + 7, y + 11, 28, 36); box("ARTWORK", e, x + 7, y + 45, 28, 2)
                box("BORDER", b, x + 37, y + 11, 28, 30); box("ARTWORK", e, x + 37, y + 39, 28, 2)
                box("BORDER", b, x + 12, y + 47, 26, 24); box("ARTWORK", e, x + 12, y + 69, 26, 2)
                box("ARTWORK", C_TIER[t], x + 20, y + 11, 2, 34)
            elseif kind == "H" then
                box("BORDER", b, x + 9, y + 11, 32, 28); box("ARTWORK", e, x + 9, y + 37, 32, 2)
                box("BORDER", a, x + 43, y + 11, 22, 20); box("ARTWORK", e, x + 43, y + 29, 22, 2)
            elseif kind == "W" then
                box("BORDER", RACK.wrap, x + 8, y + 11, 56, 64)
                box("ARTWORK", RACK.wrapLit, x + 8, y + 73, 56, 2)
                box("ARTWORK", RACK.wrapLit, x + 11, y + 50, 50, 3)
                box("ARTWORK", RACK.wrapLit, x + 11, y + 28, 50, 3)
                box("ARTWORK", RACK.wrapDim, x + 8, y + 11, 3, 62)
                box("ARTWORK", RACK.wrapDim, x + 61, y + 11, 3, 62)
            end
        end
    end
    for i = 0, BAYS do
        local x = OFFSET_X + i * BAY_W
        if i == BAYS then x = OFFSET_X + FIELD_W - 5 end
        box("ARTWORK", RACK.postLit, x, OFFSET_Y, 1, FIELD_H)
        box("ARTWORK", RACK.post, x + 1, OFFSET_Y, 4, FIELD_H)
    end
    for t = 0, TIERS do
        local y = OFFSET_Y + t * TIER_H
        if t == TIERS then y = OFFSET_Y + FIELD_H - 5 end
        box("OVERLAY", RACK.beam, OFFSET_X, y, FIELD_W, 4)
        box("OVERLAY", RACK.beamLit, OFFSET_X, y + 4, FIELD_W, 1)
    end
end
local function paintNear(box)
    for side = 0, 1 do
        local x = side * (OFFSET_X + FIELD_W)
        local inner = (side == 0) and (x + OFFSET_X - 4) or x
        local outer = (side == 0) and x or (x + OFFSET_X - 3)
        box("BACKGROUND", C_WALL_SLAB, x, OFFSET_Y, OFFSET_X, FIELD_H)
        for r = 1, ROWS - 1 do
            local y = OFFSET_Y + r * CELL
            local shift = (r % 2 == 0) and 0 or 14
            box("BORDER", C_WALL_SEAM, x, y - 1, OFFSET_X, 2)
            box("BORDER", C_WALL_SEAM, x + shift, y + 1, 2, CELL - 3)
        end
        box("BORDER", C_WALL_SEAM, x + 14, OFFSET_Y, 2, CELL - 2)
        box("ARTWORK", C_WALL_EDGE, inner, OFFSET_Y, 4, FIELD_H)
        box("ARTWORK", C_WALL_DARK, outer, OFFSET_Y, 3, FIELD_H)
    end
end
local function paintLane(box)
    box("BACKGROUND", C_LANE, 0, LANE_Y, CANVAS_W, LANE_H)
    for k = 0, 5 do
        local x = OFFSET_X + 18 + k * 96
        box("BORDER", C_WIN, x, LANE_Y + 16, WIN_W, WIN_H)
        box("ARTWORK", C_WIN_LIT, x + 2, LANE_Y + 18, WIN_W - 4, WIN_H - 4)
    end
    box("BORDER", C_RAIL_SHADOW, 0, LANE_Y + LANE_H - 12, CANVAS_W, 2)
    box("BORDER", C_RAIL, 0, LANE_Y + LANE_H - 6, CANVAS_W, 4)
    box("ARTWORK", C_RAIL_LIT, 0, LANE_Y + LANE_H - 3, CANVAS_W, 1)
    box("BACKGROUND", C_HUD, 0, BEAM_Y, CANVAS_W, BEAM_H)
    box("BORDER", C_HUD_TOP, 0, BEAM_Y + BEAM_H - 1, CANVAS_W, 1)
end
local function hudFrame(canvas)
    local hud = ns.PlainFrame(canvas, 4)
    hud:Hide()
    hud:SetAllPoints()
    hud.hat = ns.Fill(hud, "ARTWORK", WORKERS[1].hat)
    hud.hat:SetWidth(11); hud.hat:SetHeight(10)
    hud.hat:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12, BEAM_Y + 7)
    local function text(anchor, font, gap)
        local fs = hud:CreateFontString(nil, "OVERLAY", font)
        fs:SetPoint("LEFT", anchor, "RIGHT", gap, 0)
        return fs
    end
    local function sep(anchor)
        local t = ns.Fill(hud, "ARTWORK", C_HUD_SEP)
        t:SetWidth(1); t:SetHeight(14)
        t:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
        return t
    end
    hud.name = text(hud.hat, "GameFontHighlightSmall", 6)
    hud.shiftCap = text(sep(hud.name), "GameFontDisableSmall", 12)
    hud.shift = text(hud.shiftCap, "GameFontHighlightSmall", 5)
    hud.grabsCap = text(sep(hud.shift), "GameFontDisableSmall", 12)
    hud.grabs = text(hud.grabsCap, "GameFontHighlightSmall", 5)
    hud.grabs:SetTextColor(GC.grab[1], GC.grab[2], GC.grab[3])
    hud.scoreCap = text(sep(hud.grabs), "GameFontDisableSmall", 12)
    hud.score = text(hud.scoreCap, "GameFontHighlight", 5)
    hud.bonus = text(hud.score, "GameFontNormalSmall", 16)
    hud.clock = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hud.clock:SetPoint("RIGHT", hud, "TOPRIGHT", -12, -BEAM_H / 2)
    hud.clock:SetTextColor(0.78, 0.70, 0.54)
    return hud
end
local function ensureView(canvas)
    if view then return end
    view = {}
    view.field = ns.PlainFrame(canvas, 0)
    view.field:Hide()
    view.field:SetAllPoints()
    local function at(t, x, y)
        t:SetPoint("BOTTOMLEFT", view.field, "BOTTOMLEFT", x, y)
    end
    local function box(layer, col, x, y, w, h)
        local t = ns.Fill(view.field, layer, col)
        t:SetWidth(w); t:SetHeight(h)
        at(t, x, y)
        return t
    end
    view.stage = ns.PlainFrame(canvas, 0)
    view.stage:SetWidth(CANVAS_W); view.stage:SetHeight(CANVAS_H - OFFSET_Y)
    view.stage:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", 0, OFFSET_Y)
    paintFloor(box)
    paintRack(box)
    paintNear(box)
    for c = 1, COLS - 1 do
        box("HIGHLIGHT", C_LINE_V, OFFSET_X + c * CELL, OFFSET_Y, 1, FIELD_H)
    end
    for r = 1, ROWS - 1, 2 do
        box("HIGHLIGHT", C_LINE_H, OFFSET_X, OFFSET_Y + r * CELL, FIELD_W, 1)
    end
    paintLane(box)
    view.field.near = ns.Fill(view.field, "HIGHLIGHT", C_NEAR)
    view.field.near:SetWidth(FIELD_W)
    view.field.near:SetHeight(CELL)
    view.field.near:Hide()
    markPool = ns.NewPool(function() return markFrame(canvas) end)
    view.worker = workerFrame(canvas)
    view.toast = ns.PlainFrame(canvas, 6)
    view.toast:Hide()
    view.toast:SetWidth(FIELD_W); view.toast:SetHeight(26)
    view.toast:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", OFFSET_X, OFFSET_Y + 6 * CELL)
    view.toast.bg = ns.Fill(view.toast, "BACKGROUND", { 0, 0, 0, 0.6 })
    view.toast.bg:SetAllPoints()
    view.toast.text = view.toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.toast.text:SetPoint("CENTER", view.toast, "CENTER", 0, 0)
    view.hud = hudFrame(canvas)
    view.lane = ns.NewFrame("ScrollFrame", nil, canvas)
    view.lane:SetWidth(CANVAS_W); view.lane:SetHeight(LANE_H)
    view.lane:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", 0, LANE_Y)
    view.lane:SetFrameLevel(canvas:GetFrameLevel() + 2)
    view.laneChild = ns.NewFrame("Frame", nil, view.lane)
    view.laneChild:SetWidth(CANVAS_W); view.laneChild:SetHeight(LANE_H)
    view.lane:SetScrollChild(view.laneChild)
    grabPool = ns.NewPool(function() return grabFrame(view.laneChild) end)
    holdPool = ns.NewPool(function() return boxFrame(view.laneChild) end)
    boxPool = ns.NewPool(function() return boxFrame(canvas) end)
end
local function hideView()
    if not view then return end
    view.field:Hide()
    view.worker:Hide()
    view.hud:Hide()
    if boxPool then boxPool:HideAll() end
    if grabPool then grabPool:HideAll() end
    if holdPool then holdPool:HideAll() end
    if markPool then markPool:HideAll() end
    if view.toast then view.toast:Hide() end
end
local function badge(f, name, size)
    if f.badgeName == name and f.badgeSet then return end
    f.badgeName, f.badgeSet = name, true
    if name then
        f.badge:SetTexture(ns.IconPath(name))
        ns.CropIcon(f.badge)
        f.badge:SetWidth(size); f.badge:SetHeight(size)
        f.badge:Show()
    else
        f.badge:Hide()
    end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.grid = {}
    return self
end
function Game:GridOcc(c, r)
    local row = self.grid[r]
    return row ~= nil and row[c] ~= nil
end
function Game:Blocked(c, r)
    if c < 1 or c > COLS or r < 1 or r > ROWS then return true end
    if self:GridOcc(c, r) then return true end
    for i = 1, #self.falls do
        local f = self.falls[i]
        if f.c == c and f.r == r then return true end
    end
    return false
end
local function colOf(x) return floor((x - OFFSET_X) / CELL) + 1 end
local function rowOf(y) return floor(y / CELL) + 1 end
local function floorY(r) return (r - 1) * CELL + GAP / 2 end
function Game:BodyCols(px)
    local c1 = colOf(px - P.halfW + P.edge)
    local c2 = colOf(px + P.halfW - P.edge)
    if c1 < 1 then c1 = 1 end
    if c2 > COLS then c2 = COLS end
    return c1, c2
end
function Game:BodyRows(py)
    return rowOf(py + 2), rowOf(py + P.bodyH - 2)
end
function Game:Supported()
    local w = self.worker
    local r = rowOf(w.py)
    if math.abs(w.py - floorY(r)) > 0.01 then return false end
    if r == 1 then return true end
    local c1, c2 = self:BodyCols(w.px)
    for c = c1, c2 do
        if self:GridOcc(c, r - 1) then return true end
    end
    return false
end
function Game:SyncWorkerCell()
    local w = self.worker
    w.c = colOf(w.px)
    w.r = rowOf(w.py + P.bodyH / 2)
    if w.c < 1 then w.c = 1 elseif w.c > COLS then w.c = COLS end
    if w.r < 1 then w.r = 1 elseif w.r > ROWS then w.r = ROWS end
end
function Game:PlaceWorker(c, r)
    local w = self.worker
    w.px = cellCenterX(c)
    w.py = floorY(r)
    w.vy = 0
    w.coyote = 0
    w.pressT = 0
    self:SyncWorkerCell()
end
function Game:AddSlide(kind, fromC, fromR, toC, toR)
    self.slides[#self.slides + 1] = {
        kind = kind, c = toC, r = toR,
        fromC = fromC, fromR = fromR, t = 0,
    }
end
function Game:UpdateSlides(dt)
    local i, landed = 1, false
    while i <= #self.slides do
        local s = self.slides[i]
        s.t = s.t + dt
        local total = P.stepTick + (s.fromR - s.r) * P.fallTick
        if s.t >= total then
            if s.fromR > s.r then landed = true end
            table.remove(self.slides, i)
        else
            i = i + 1
        end
    end
    if landed then ns.Sfx.Play("pop") end
end
local function slidePos(s)
    if s.t < P.stepTick then
        local k = s.t / P.stepTick
        return s.fromC + (s.c - s.fromC) * k, s.fromR
    end
    local drop = (s.fromR - s.r) * P.fallTick
    if drop <= 0 then return s.c, s.r end
    local k = clamp01((s.t - P.stepTick) / drop)
    return s.c, s.fromR + (s.r - s.fromR) * k
end
function Game:TakeBonus(c, r)
    local kind = self.grid[r][c]
    self.grid[r][c] = nil
    self:ApplyBonus(kind)
end
function Game:ApplyBonus(kind)
    local what = CRATE_KINDS[kind].bonus
    if what == "helmet" then
        self.helmet = true
    elseif what == "super" then
        self.superJumps = SUPER_JUMPS
    else
        self.score = self.score + BONUS_SCORE
    end
    self.toast, self.toastT = what, TOAST_T
    ns.Sfx.Play("hover")
end
function Game:TryPush(dir, r, tc)
    local first = self.grid[r] and self.grid[r][tc]
    if first and first > PLAIN_KINDS and not self:GridOcc(tc, r + 1) then
        self:TakeBonus(tc, r)
        return true
    end
    local run = 0
    while run < self.push do
        local bc = tc + run * dir
        if bc < 1 or bc > COLS then break end
        if not self:GridOcc(bc, r) then break end
        if self:GridOcc(bc, r + 1) then break end
        run = run + 1
    end
    if run == 0 then return false end
    local past = tc + run * dir
    if past < 1 or past > COLS or self:Blocked(past, r) then return false end
    for i = 1, #self.falls do
        local f = self.falls[i]
        if f.c == past and f.r <= r then return false end
    end
    for i = run - 1, 0, -1 do
        local from = tc + i * dir
        local to = from + dir
        local dr = r
        while dr > 1 and not self:GridOcc(to, dr - 1) do dr = dr - 1 end
        local kind = self.grid[r][from]
        self.grid[r][from] = nil
        self.grid[dr] = self.grid[dr] or {}
        self.grid[dr][to] = kind
        self:AddSlide(kind, from, r, to, dr)
    end
    self.gridDirty = true
    ns.Sfx.Play("slide")
    return true
end
function Game:MoveWorkerX(dir, dt)
    local w = self.worker
    local nx = w.px + dir * P.walkV * (self:Supported() and 1 or P.airK) * dt
    local lo, hi = OFFSET_X + P.halfW, OFFSET_X + FIELD_W - P.halfW
    if nx < lo then nx = lo elseif nx > hi then nx = hi end
    local cc = colOf(nx + dir * (P.halfW + 0.02))
    if cc >= 1 and cc <= COLS then
        local r1, r2 = self:BodyRows(w.py)
        local hit, boxRow, boxes = false, nil, 0
        for rr = r1, r2 do
            if self:Blocked(cc, rr) then hit = true end
            if self:GridOcc(cc, rr) then boxes = boxes + 1; boxRow = rr end
        end
        if hit then
            local edge = (dir == 1) and (OFFSET_X + (cc - 1) * CELL) or (OFFSET_X + cc * CELL)
            local lim = edge - dir * (P.halfW + 0.01)
            if (dir == 1 and lim < nx) or (dir == -1 and lim > nx) then nx = lim end
            w.pressT = w.pressT + dt
            if boxes == 1 and boxRow == rowOf(w.py + P.bodyH / 2) and w.vy <= 0
                and w.pressT >= P.pushDelay and self.stepCD <= 0
                and self:TryPush(dir, boxRow, cc) then
                self.stepCD = P.stepTick
            end
        else
            w.pressT = 0
        end
    end
    w.px = nx
end
function Game:MoveWorkerY(dt)
    local w = self.worker
    w.vy = w.vy - P.grav * dt
    local ny = w.py + w.vy * dt
    local c1, c2 = self:BodyCols(w.px)
    if w.vy > 0 then
        local headRow = rowOf(ny + P.bodyH - 2)
        local hit = headRow > ROWS
        if not hit then
            for c = c1, c2 do
                if self:Blocked(c, headRow) then hit = true; break end
            end
        end
        if hit then
            local lim = (headRow - 1) * CELL - P.bodyH + GAP / 2 - 0.01
            if lim < ny then ny = lim end
            w.vy = 0
        end
        w.py = ny
        return
    end
    local rFrom = floor((w.py - GAP / 2) / CELL) + 1
    if rFrom > ROWS then rFrom = ROWS end
    for r = rFrom, 1, -1 do
        local fy = floorY(r)
        if fy <= w.py + 0.001 and fy >= ny then
            local support = (r == 1)
            if not support then
                for c = c1, c2 do
                    if self:GridOcc(c, r - 1) then support = true; break end
                end
            end
            if support then
                w.py = fy
                w.vy = 0
                return
            end
        end
    end
    if ny < floorY(1) then
        ny = floorY(1)
        w.vy = 0
    end
    w.py = ny
end
function Game:UpdateWorker(dt, dir)
    local w = self.worker
    if dir ~= 0 then w.dir = dir else w.pressT = 0 end
    self.stepCD = self.stepCD - dt
    if self.stepCD < 0 then self.stepCD = 0 end
    if self.jumpWanted then
        self.jumpWanted = self.jumpWanted - dt
        if self.jumpWanted <= 0 then self.jumpWanted = nil end
    end
    local supported = self:Supported()
    if supported then
        w.coyote = P.coyote
        if w.vy < 0 then w.vy = 0 end
    else
        w.coyote = w.coyote - dt
        if w.coyote < 0 then w.coyote = 0 end
    end
    if self.jumpWanted and w.coyote > 0 and w.vy <= 0 then
        self.jumpWanted = nil
        local above = rowOf(w.py + P.bodyH / 2) + 1
        if above > ROWS or self:Blocked(w.c, above) then
            ns.Sfx.Play("deny")
        else
            local height = self.jump
            if (self.superJumps or 0) > 0 then
                self.superJumps = self.superJumps - 1
                height = height + 1
            end
            w.vy = JUMP_V[height] or JUMP_V[#JUMP_V]
            w.coyote = 0
            supported = false
            ns.Sfx.Play("pick")
        end
    end
    local left = dt
    while left > 0 do
        local step = (left > P.substep) and P.substep or left
        left = left - step
        if dir ~= 0 then self:MoveWorkerX(dir, step) end
        if not supported or w.vy > 0 then
            self:MoveWorkerY(step)
            supported = self:Supported()
        elseif not self:Supported() then
            supported = false
        end
    end
    self:SyncWorkerCell()
end
function Game:ColumnEligible(c)
    if self:GridOcc(c, ROWS) then return false end
    local w = self.worker
    if w.c == c and w.r == ROWS then return false end
    return true
end
function Game:ColumnTop(c)
    for r = ROWS, 1, -1 do
        if self:GridOcc(c, r) then return r end
    end
    return 0
end
function Game:ColumnTaken(c, skip)
    for i = 1, #self.grabs do
        local g = self.grabs[i]
        if g ~= skip and (g.st == "ride" or g.st == "open") and g.c == c then return true end
    end
    for i = 1, #self.falls do
        if self.falls[i].c == c then return true end
    end
    return false
end
function Game:RowGaps(r)
    local row = self.grid[r]
    if not row then return COLS end
    local n = 0
    for c = 1, COLS do
        if not row[c] then n = n + 1 end
    end
    return n
end
function Game:PickDropColumn(g)
    local roll = self.rng:Int(COLS)
    local hold = self.rng:Int(100) <= G.holdP
    if hold then
        for i = 0, COLS - 1 do
            local c = ((roll - 1 + i) % COLS) + 1
            if self:ColumnEligible(c) and not self:ColumnTaken(c, g)
                and self:RowGaps(self:ColumnTop(c) + 1) > G.holdGaps then return c end
        end
    end
    for i = 0, COLS - 1 do
        local c = ((roll - 1 + i) % COLS) + 1
        if self:ColumnEligible(c) and not self:ColumnTaken(c, g) then return c end
    end
    return nil
end
function Game:AnyEligible()
    for c = 1, COLS do
        if self:ColumnEligible(c) then return true end
    end
    return false
end
function Game:AnyFree(g)
    for c = 1, COLS do
        if self:ColumnEligible(c) and not self:ColumnTaken(c, g) then return true end
    end
    return false
end
function Game:EnterGrab(g)
    local side = (self.rng:Int(2) == 1) and 1 or -1
    local c = self:PickDropColumn(g)
    self.entries = self.entries + 1
    g.side = side
    g.c = c
    g.st = "ride"
    g.t = 0
    g.kind = KindFor(self.entries)
    g.x = (side == 1) and -CELL / 2 or (CANVAS_W + CELL / 2)
end
function Game:SendGrab(g)
    if not self:AnyEligible() then
        self:EndGame(true)
        return false
    end
    if not self:AnyFree(g) then
        g.st = "off"
        g.t = G.wait
        return true
    end
    self:EnterGrab(g)
    return true
end
function Game:ReleaseGrab(g)
    self.falls[#self.falls + 1] =
        { c = g.c, r = ROWS, fromR = ROWS + 1, t = 0, kind = g.kind, ft = 0 }
    ns.Sfx.Play("turn")
    g.kind = nil
end
function Game:SettleFall(f)
    self.grid[f.r] = self.grid[f.r] or {}
    self.grid[f.r][f.c] = f.kind or 1
    f.done = true
    self.gridDirty = true
    self.score = self.score + BOX_SCORE
    ns.Sfx.Play("pop")
end
function Game:UnstickWorker()
    local w = self.worker
    local lo, hi = OFFSET_X + P.halfW, OFFSET_X + FIELD_W - P.halfW
    for _ = 1, 4 do
        local hitC, hitR
        local r1, r2 = self:BodyRows(w.py)
        local c1, c2 = colOf(w.px - P.halfW + 0.5), colOf(w.px + P.halfW - 0.5)
        for c = (c1 < 1) and 1 or c1, (c2 > COLS) and COLS or c2 do
            for r = (r1 < 1) and 1 or r1, (r2 > ROWS) and ROWS or r2 do
                if self:GridOcc(c, r) then hitC, hitR = c, r; break end
            end
            if hitC then break end
        end
        if not hitC then
            if w.px < lo then w.px = lo elseif w.px > hi then w.px = hi end
            self:SyncWorkerCell()
            return
        end
        local x0 = OFFSET_X + (hitC - 1) * CELL
        local outL, outR = (w.px + P.halfW) - x0, (x0 + CELL) - (w.px - P.halfW)
        local nx = (outL < outR) and (x0 - P.halfW - 0.01) or (x0 + CELL + P.halfW + 0.01)
        if nx < lo or nx > hi then
            w.py = floorY((hitR < ROWS) and (hitR + 1) or ROWS)
            w.vy = 0
            self:SyncWorkerCell()
            return
        end
        w.px = nx
    end
    local _, r2 = self:BodyRows(w.py)
    w.py = floorY((r2 > ROWS) and ROWS or r2)
    w.vy = 0
    self:SyncWorkerCell()
end
function Game:StepFall(f)
    local c, r = f.c, f.r
    local br = r - 1
    if br < 1 then
        self:SettleFall(f)
        return
    end
    local w = self.worker
    if w.c == c and w.r == br then
        if (f.kind or 1) > PLAIN_KINDS then
            self:ApplyBonus(f.kind)
            f.done = true
            return
        end
        if self.helmet then
            self.helmet = nil
            f.done = true
            ns.FX.Play(self.canvas, { { x = cellCenterX(c), y = cellCenterY(r) + OFFSET_Y,
                size = CELL - GAP, tex = EMPTY_TEX } })
            ns.Sfx.Play("pop")
            return
        end
        self:EndGame()
        return
    end
    if self:GridOcc(c, br) then
        self:SettleFall(f)
        return
    end
    f.fromR = r
    f.r = br
    f.t = 0
end
function Game:UpdateFalls(dt)
    local i = 1
    while i <= #self.falls do
        local f = self.falls[i]
        f.ft = f.ft + dt
        while not f.done and not self.over and f.ft >= P.fallTick do
            f.ft = f.ft - P.fallTick
            self:StepFall(f)
        end
        if f.done then
            table.remove(self.falls, i)
        else
            f.t = clamp01(f.ft / P.fallTick)
            i = i + 1
        end
    end
end
function Game:UpdateGrabs(dt)
    for i = 1, #self.grabs do
        local g = self.grabs[i]
        if g.st == "off" then
            g.t = g.t - dt
            if g.t <= 0 then
                if not self:SendGrab(g) then return end
            end
        elseif g.st == "ride" then
            local was = g.x
            g.x = g.x + g.side * G.ride * dt
            local target = cellCenterX(g.c)
            if (g.side == 1 and was < target and g.x >= target)
                or (g.side == -1 and was > target and g.x <= target) then
                g.x = target
                g.st = "open"
                g.t = 0
            end
        elseif g.st == "open" then
            g.t = g.t + dt
            if g.t >= G.dropT then
                if g.kind and self:ColumnEligible(g.c) then self:ReleaseGrab(g) end
                g.st = "leave"
                g.t = 0
            end
        else
            g.x = g.x + g.side * G.ride * dt
            local out = (g.side == 1 and g.x > CANVAS_W + CELL / 2)
                or (g.side == -1 and g.x < -CELL / 2)
            if out then
                if not self:SendGrab(g) then return end
            end
        end
    end
end
function Game:AddGrabs(n)
    for _ = 1, n do
        if #self.grabs >= G.max then return end
        self.grabs[#self.grabs + 1] = { st = "off", x = 0, side = 1, t = 0 }
    end
end
function Game:ResolveRows()
    local full = {}
    for r = 1, ROWS do
        local ok = true
        for c = 1, COLS do
            if not self:GridOcc(c, r) then ok = false; break end
        end
        if ok then full[#full + 1] = r end
    end
    local n = #full
    if n == 0 then return end
    local mark = {}
    for i = 1, n do mark[full[i]] = true end
    local crateTex = self.crateName and ns.IconPath(self.crateName) or EMPTY_TEX
    local cells = {}
    for i = 1, n do
        local r = full[i]
        for c = 1, COLS do
            cells[#cells + 1] = { x = cellCenterX(c), y = cellCenterY(r) + OFFSET_Y,
                size = CELL - GAP, tex = crateTex }
        end
    end
    local function shiftFor(r)
        local s = 0
        for i = 1, n do if full[i] < r then s = s + 1 end end
        return s
    end
    local newGrid = {}
    for r = 1, ROWS do
        if not mark[r] and self.grid[r] then
            newGrid[r - shiftFor(r)] = self.grid[r]
        end
    end
    self.grid = newGrid
    for i = 1, #self.falls do
        local f = self.falls[i]
        local sh = shiftFor(f.r)
        if sh > 0 then
            f.r = f.r - sh
            f.fromR = f.r
            f.t = 0
        end
    end
    local w = self.worker
    local ws = shiftFor(w.r)
    if ws > 0 then
        w.py = w.py - ws * CELL
        if w.py < floorY(1) then w.py = floorY(1); w.vy = 0 end
        self:SyncWorkerCell()
    end
    self.slides = {}
    self.rowsCleared = self.rowsCleared + n
    self:AddGrabs(n)
    self.score = self.score + ROW_SCORE * n * n
    ns.Sfx.Play((n >= 2) and "big" or "clear")
    ns.FX.Play(self.canvas, cells, { big = true })
end
function Game:EndGame(stuck)
    if self.over then return end
    self.over = true
    self.overT = P.overFlash
    ns.Sfx.Play(stuck and "stuck" or "over")
end
function Game:Key(action, down)
    if action == "left" then self.keyLeft = down and true or nil
    elseif action == "right" then self.keyRight = down and true or nil
    elseif action == "up" then
        if down then self.jumpWanted = P.jumpBuffer end
    end
end
function Game:DesiredDir()
    if self.keyLeft and self.keyRight then return 0 end
    if self.keyLeft then return -1 end
    if self.keyRight then return 1 end
    return 0
end
function Game:Click(x, y, button) end
function Game:Move(move) end
function Game:Update(dt)
    self.t = self.t + dt
    if self.over then
        self.overT = self.overT - dt
        self:Draw()
        return
    end
    if self.gate then
        self:Draw()
        return
    end
    local dir = self:DesiredDir()
    self:UpdateSlides(dt)
    self:UpdateWorker(dt, dir)
    if not self.over then self:UpdateFalls(dt) end
    if not self.over then self:UpdateGrabs(dt) end
    if self.gridDirty and not self.over and #self.slides == 0 then
        self.gridDirty = false
        self:ResolveRows()
    end
    if not self.over then self:UnstickWorker() end
    if self.toastT then
        self.toastT = self.toastT - dt
        if self.toastT <= 0 then self.toast, self.toastT = nil, nil end
    end
    self:Draw()
end
function Game:Start(seed, moves)
    ns.Curtain.Hide()
    ensureView(self.canvas)
    self.rng = ns.RNG.New(seed)
    local shelfRng = ns.RNG.New(seed)
    self.crateName = ns.Shelves.Pick(ID, "crate", shelfRng)
    self.workerName = ns.Shelves.Pick(ID, "worker", shelfRng)
    self.class = workerOf(self.opts and self.opts.worker)
    self.shift = shiftOf(self.opts and self.opts.shift)
    self.opts = { worker = self.class.key, shift = self.shift.key }
    self.push, self.jump = self.class.push, self.class.jump
    self.helmet, self.superJumps = nil, 0
    local snap = moves and type(moves[1]) == "table" and moves[1].k == "snap"
        and tonumber(moves[1].v) == SNAP_V and tonumber(moves[1].over) ~= 1
        and moves[1] or nil
    local restored = snap ~= nil
    local startC = ceil(COLS / 2)
    self.grid = restored and {}
        or startGrid(ns.RNG.New((tonumber(seed) or 0) + START_SEED), startC)
    self.falls = {}
    self.slides = {}
    self.worker = { dir = 1 }
    self:PlaceWorker(startC, 1)
    self.entries = 0
    self.rowsCleared = 0
    self.score = 0
    self.over, self.overT = false, 0
    self.t = 0
    self.stepCD = 0
    self.keyLeft, self.keyRight, self.jumpWanted = nil, nil, nil
    self.gridDirty = false
    self.grabs = {}
    local cycle = G.ridePath / G.ride
    for i = 1, self.shift.grabs do
        self.grabs[i] = { st = "off", x = 0, side = 1,
            t = (i - 1) * cycle / self.shift.grabs }
    end
    if restored then self:Restore(snap) end
    view.field:Show()
    view.hud:Show()
    local skip = (pending ~= nil)
    pending = nil
    if not restored and not skip then
        self:ShowShowcase()
    else
        self.gate = nil
    end
    self:Draw()
end
function Game:Score()
    return floor(self.score or 0)
end
function Game:IsOver()
    return self.over and self.overT <= 0
end
function Game:Stop()
    ns.Curtain.Hide()
    hideView()
end
function Game:Serialize()
    local rows = {}
    for r = 1, ROWS do
        local chars = {}
        local row = self.grid[r]
        for c = 1, COLS do
            local kind = row and row[c]
            chars[c] = kind and tostring(kind) or "0"
        end
        rows[r] = table.concat(chars)
    end
    local falls = {}
    for i = 1, #self.falls do
        local f = self.falls[i]
        falls[i] = f.c .. "," .. f.r .. "," .. (f.kind or 1)
            .. "," .. format("%.3f", f.ft or 0)
    end
    local grabs = {}
    for i = 1, #self.grabs do
        local g = self.grabs[i]
        grabs[i] = g.side .. "," .. format("%.3f", g.x) .. "," .. (g.c or 0)
            .. "," .. g.st .. "," .. (g.kind or 0) .. "," .. format("%.3f", g.t or 0)
    end
    local w = self.worker
    return {
        k = "snap", v = SNAP_V,
        score = self.score,
        helmet = self.helmet and 1 or 0, superJumps = self.superJumps or 0,
        entries = self.entries, rowsCleared = self.rowsCleared,
        t = self.t,
        rows = rows,
        falls = falls, grabs = grabs,
        wc = w.c, wr = w.r, wdir = w.dir,
        over = self.over and 1 or 0, overT = self.overT,
    }
end
function Game:Restore(s)
    if s.v ~= SNAP_V then return end
    self.score = ns.Store.Num(s.score, 0, 1e9, 0)
    self.helmet = (ns.Store.Num(s.helmet, 0, 1, 0) == 1) or nil
    self.superJumps = floor(ns.Store.Num(s.superJumps, 0, SUPER_JUMPS, 0))
    self.entries = floor(ns.Store.Num(s.entries, 0, 1e9, 0))
    self.rowsCleared = floor(ns.Store.Num(s.rowsCleared, 0, 1e9, 0))
    self.t = ns.Store.Num(s.t, 0, 1e7, 0)
    self.grid = {}
    local rows = type(s.rows) == "table" and s.rows or {}
    for r = 1, ROWS do
        local line = rows[r]
        if type(line) == "string" then
            local row
            for c = 1, COLS do
                local kind = tonumber(line:sub(c, c))
                if kind and kind > 0 then
                    row = row or {}
                    row[c] = (kind <= #CRATE_KINDS) and kind or 1
                end
            end
            if row then self.grid[r] = row end
        end
    end
    self.falls = {}
    local fl = type(s.falls) == "table" and s.falls or {}
    for i = 1, #fl do
        local a, b, k, ft = tostring(fl[i]):match("^(-?%d+),(-?%d+),(%d+),([%d.-]+)$")
        if a then
            local fc = floor(ns.Store.Num(a, 1, COLS, 1))
            local fr = floor(ns.Store.Num(b, 1, ROWS, 1))
            local kind = floor(ns.Store.Num(k, 1, #CRATE_KINDS, 1))
            self.falls[#self.falls + 1] = { c = fc, r = fr, fromR = fr, t = 0,
                kind = kind, ft = ns.Store.Num(ft, 0, P.fallTick, 0) }
        end
    end
    self.grabs = {}
    local gr = type(s.grabs) == "table" and s.grabs or {}
    for i = 1, #gr do
        local sd, x, c, st, k, gt =
            tostring(gr[i]):match("^(-?%d+),([%d.-]+),(%d+),(%a+),(%d+),([%d.-]+)$")
        if sd and (st == "ride" or st == "open" or st == "leave" or st == "off") then
            local kind = floor(ns.Store.Num(k, 0, #CRATE_KINDS, 0))
            self.grabs[#self.grabs + 1] = {
                side = (tonumber(sd) == -1) and -1 or 1,
                x = ns.Store.Num(x, -CELL, CANVAS_W + CELL, 0),
                c = floor(ns.Store.Num(c, 1, COLS, 1)),
                st = st, t = ns.Store.Num(gt, 0, G.ridePath / G.ride, 0),
                kind = (kind > 0) and kind or nil,
            }
        end
    end
    if #self.grabs == 0 then
        self.grabs[1] = { st = "off", x = 0, side = 1, t = 0 }
    end
    local startC = ceil(COLS / 2)
    local wc = floor(ns.Store.Num(s.wc, 1, COLS, startC))
    local wr = floor(ns.Store.Num(s.wr, 1, ROWS, 1))
    local wdir = (s.wdir == -1) and -1 or 1
    self.worker = { dir = wdir }
    self:PlaceWorker(wc, wr)
    self.slides = {}
    self.over = s.over == 1
    self.overT = ns.Store.Num(s.overT, 0, P.overFlash, 0)
    for _ = 1, self.entries do
        self.rng:Int(2)
        self.rng:Int(COLS)
        self.rng:Int(100)
    end
    self.stepCD = 0
    self.keyLeft, self.keyRight, self.jumpWanted = nil, nil, nil
    self.gridDirty = true
end
local SHOW_ROW_H, SHOW_GAP = 58, 6
local PLATE_H, PLATE_GAP = 52, 7
local function markRow(row, on)
    row.sel:SetAlpha(on and 1 or 0)
    row.name:SetTextColor(on and 1 or 0.75, on and 0.94 or 0.75, on and 0.62 or 0.75)
end
local function markPlate(p, on)
    p.sel:SetAlpha(on and 1 or 0)
    p.name:SetTextColor(on and 1 or 0.75, on and 0.94 or 0.75, on and 0.62 or 0.75)
end
local function dressWorker(f, class)
    if f.dressed == class.key then return end
    f.dressed = class.key
    ns.Paint(f.hat, class.hat[1], class.hat[2], class.hat[3])
    ns.Paint(f.brim, class.hat[1], class.hat[2], class.hat[3])
    ns.Paint(f.body, class.vest[1], class.vest[2], class.vest[3])
    ns.Paint(f.armL, class.vest[1], class.vest[2], class.vest[3])
    ns.Paint(f.armR, class.vest[1], class.vest[2], class.vest[3])
end
local function put(t, f, x, y)
    t:ClearAllPoints()
    t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
end
local function size(t, w, h)
    t:SetWidth(w); t:SetHeight(h)
end
local function poseWorker(f, pose, phase, dir)
    local key = pose .. phase .. dir
    if f.pose == key then return end
    f.pose = key
    local cx = 22 + dir * 2
    local lx, rx, lh, rh = 10, 27, 12, 12
    if pose == "walk" then
        if phase == 0 then lh = 9 else rh = 9 end
    elseif pose == "jump" then
        lx, rx, lh, rh = 6, 31, 10, 10
    elseif pose == "fall" then
        lx, rx = 13, 24
    end
    size(f.legL, 7, lh); put(f.legL, f, lx, 12 - lh)
    size(f.legR, 7, rh); put(f.legR, f, rx, 12 - rh)
    put(f.bootL, f, lx, 12 - lh)
    put(f.bootR, f, rx, 12 - rh)
    put(f.body, f, cx - 11, 11)
    put(f.stripe, f, cx - 11, 17)
    put(f.belt, f, cx - 11, 11)
    if pose == "jump" then
        size(f.armL, 5, 9); put(f.armL, f, cx - 16, 24)
        size(f.armR, 5, 9); put(f.armR, f, cx + 11, 24)
        size(f.gloveL, 5, 3); put(f.gloveL, f, cx - 16, 33)
        size(f.gloveR, 5, 3); put(f.gloveR, f, cx + 11, 33)
    elseif pose == "fall" then
        size(f.armL, 8, 5); put(f.armL, f, cx - 19, 21)
        size(f.armR, 8, 5); put(f.armR, f, cx + 11, 21)
        size(f.gloveL, 3, 5); put(f.gloveL, f, cx - 22, 21)
        size(f.gloveR, 3, 5); put(f.gloveR, f, cx + 19, 21)
    else
        size(f.armL, 6, 5); put(f.armL, f, cx - 17, 19)
        size(f.armR, 6, 5); put(f.armR, f, cx + 11, 19)
        size(f.gloveL, 6, 3); put(f.gloveL, f, cx - 17, 16)
        size(f.gloveR, 6, 3); put(f.gloveR, f, cx + 11, 16)
    end
    put(f.head, f, cx - 6, 28)
    put(f.eye, f, cx + dir * 2 - 3, 32)
    put(f.eye2, f, cx + dir * 2 + 2, 32)
    put(f.hat, f, cx - 10, 38)
    put(f.brim, f, cx - 12 + dir * 2, 37)
    put(f.badge, f, cx - 7, 13)
end
local function showcaseArt(host)
    if showcase and showcase.host == host then return end
    showcase = { rows = {}, host = host }
    local width = host:GetWidth()
    for i = 1, #WORKERS do
        local w = WORKERS[i]
        local row = ns.NewFrame("Button", nil, host)
        row:SetWidth(width)
        row:SetHeight(SHOW_ROW_H)
        row:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -(i - 1) * (SHOW_ROW_H + SHOW_GAP))
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        ns.Paint(row.bg, 1, 1, 1, 0.05)
        row.sel = row:CreateTexture(nil, "BORDER")
        row.sel:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.sel:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        row.sel:SetWidth(3)
        ns.Paint(row.sel, 1, 0.82, 0.18, 1)
        row.fig = workerFrame(row)
        row.fig:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -7)
        dressWorker(row.fig, w)
        poseWorker(row.fig, "stand", 0, 1)
        row.fig:Show()
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 62, -9)
        row.name:SetText(ns.TL(w.label))
        row.stat = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.stat:SetPoint("TOPLEFT", row, "TOPLEFT", 62, -27)
        row.stat:SetText(format(ns.T("stack.showcaseStats"), w.jump, w.push))
        row.best = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.best:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -27)
        row.key = w.key
        row:SetScript("OnClick", function()
            ns.Sfx.Ui()
            showcase.sel = row.key
            for j = 1, #showcase.rows do
                markRow(showcase.rows[j], showcase.rows[j].key == row.key)
            end
        end)
        showcase.rows[i] = row
    end
end
local function refreshShowcase(shiftKey)
    for i = 1, #showcase.rows do
        local row = showcase.rows[i]
        local best = ns.Records.Best(ID, { worker = row.key, shift = shiftKey })
        row.best:SetText(best and best.score
            and format(ns.T("stack.showcaseBest"), floor(best.score))
            or ns.T("stack.showcaseNoBest"))
        markRow(row, row.key == showcase.sel)
    end
    for i = 1, #(showcase.plates or {}) do
        local p = showcase.plates[i]
        markPlate(p, p.key == shiftKey)
    end
end
local function shiftArt(host)
    if not showcase or showcase.shiftHost == host then return end
    showcase.shiftHost = host
    showcase.plates = {}
    local pw = floor((host:GetWidth() - 2 * PLATE_GAP) / #SHIFTS)
    for i = 1, #SHIFTS do
        local sh = SHIFTS[i]
        local p = ns.NewFrame("Button", nil, host)
        p:SetWidth(pw)
        p:SetHeight(PLATE_H)
        p:SetPoint("TOPLEFT", host, "TOPLEFT", (i - 1) * (pw + PLATE_GAP), 0)
        p.bg = p:CreateTexture(nil, "BACKGROUND")
        p.bg:SetAllPoints()
        ns.Paint(p.bg, 1, 1, 1, 0.05)
        p.sel = p:CreateTexture(nil, "BORDER")
        p.sel:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
        p.sel:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
        p.sel:SetHeight(3)
        ns.Paint(p.sel, 1, 0.82, 0.18, 1)
        p.name = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        p.name:SetPoint("TOP", p, "TOP", 0, -7)
        p.name:SetText(ns.TL(sh.label))
        local n = sh.grabs
        local gw, gg = 14, 6
        local x0 = floor((pw - (n * gw + (n - 1) * gg)) / 2)
        for k = 1, n do
            local gx = x0 + (k - 1) * (gw + gg)
            local beam = ns.Fill(p, "ARTWORK", GC.grab)
            beam:SetWidth(gw); beam:SetHeight(3)
            beam:SetPoint("TOPLEFT", p, "TOPLEFT", gx, -27)
            for a = 0, 1 do
                local arm = ns.Fill(p, "ARTWORK", GC.arm)
                arm:SetWidth(2); arm:SetHeight(9)
                arm:SetPoint("TOPLEFT", p, "TOPLEFT", gx + a * (gw - 2), -30)
            end
            local crate = ns.Fill(p, "BORDER", CRATE_KINDS[1].body)
            crate:SetWidth(gw - 6); crate:SetHeight(8)
            crate:SetPoint("TOPLEFT", p, "TOPLEFT", gx + 3, -30)
        end
        p.key = sh.key
        p.tip = ns.T(sh.tip)
        p:SetScript("OnClick", function()
            ns.Sfx.Ui()
            showcase.shift = p.key
            refreshShowcase(p.key)
        end)
        p:SetScript("OnEnter", function(self) ns.TipShow(self) end)
        p:SetScript("OnLeave", function() ns.TipHide() end)
        showcase.plates[i] = p
    end
end
function Game:ShowShowcase()
    self.gate = true
    local body = {
        { art = showcaseArt,
          h = #WORKERS * SHOW_ROW_H + (#WORKERS - 1) * SHOW_GAP },
        ns.T("stack.showcaseShift"),
        { art = shiftArt, h = PLATE_H },
    }
    ns.Curtain.Ask(self.canvas, ns.T("stack.showcaseTitle"), body, {
        {
            label = ns.T("stack.showcaseEnter"),
            tip = ns.T("stack.showcaseEnterTip"),
            onClick = function()
                ns.Curtain.Hide()
                ns.Sfx.Play("start")
                local key = showcase and showcase.sel or self.class.key
                local shiftKey = showcase and showcase.shift or self.shift.key
                if key ~= self.class.key or shiftKey ~= self.shift.key then
                    pending = true
                    ns.Store.Clear(ID)
                    ns.window:StartGame(ID, { worker = key, shift = shiftKey })
                else
                    self.gate = nil
                end
            end,
        },
    })
    if showcase then
        showcase.sel = self.class.key
        showcase.shift = self.shift.key
        refreshShowcase(self.shift.key)
    end
end
function Game:BeginRound()
    if not self.gate then return end
    ns.Curtain.Hide()
    ns.Sfx.Play("start")
    self.gate = nil
    self:Draw()
end
function Game:PanelSync()
    if not view or not self.class then return end
    local h = view.hud
    local hat = self.class.hat
    ns.Paint(h.hat, hat[1], hat[2], hat[3])
    h.name:SetText(ns.TL(self.class.label))
    h.shiftCap:SetText(ns.T("stack.hudShift"))
    h.shift:SetText(ns.TL(self.shift.label))
    h.grabsCap:SetText(ns.T("stack.hudGrabs"))
    h.grabs:SetText(tostring(#self.grabs))
    h.scoreCap:SetText(ns.T("stack.hudScore"))
    h.score:SetText(tostring(floor(self.score or 0)))
    local bonus = ""
    if self.helmet then bonus = ns.T("stack.hudHelmet") end
    if (self.superJumps or 0) > 0 then
        bonus = bonus .. (bonus ~= "" and "   " or "") .. format(ns.T("stack.hudSuper"), self.superJumps)
    end
    h.bonus:SetText(bonus)
    h.clock:SetText(ns.Records.Span(ns.window:Elapsed()))
end
function Game:Doomed(f)
    local w = self.worker
    return w.c == f.c and w.r >= self:LandingRow(f) and w.r < f.r
        and (f.kind or 1) <= PLAIN_KINDS
end
function Game:LandingRow(f)
    local r = f.r
    while r > 1 and not self:GridOcc(f.c, r - 1) do r = r - 1 end
    return r
end
function Game:NearestRow()
    local best, bestLeft = nil, COLS
    for r = 1, ROWS do
        local row = self.grid[r]
        if row then
            local left = 0
            for c = 1, COLS do
                if not row[c] then left = left + 1 end
            end
            if left > 0 and left < bestLeft then best, bestLeft = r, left end
        end
    end
    return best, bestLeft
end
local function placeBox(f, canvas, x, y)
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y)
end
function Game:Draw()
    local stage = view.stage
    local half = GAP / 2
    local w = self.worker
    local nearR, nearLeft = self:NearestRow()
    if nearR and nearLeft <= NEAR_LEFT then
        view.field.near:SetPoint("BOTTOMLEFT", view.field, "BOTTOMLEFT",
            OFFSET_X, (nearR - 1) * CELL)
        view.field.near:SetAlpha(0.08 + 0.18 * (NEAR_LEFT - nearLeft) / NEAR_LEFT)
        view.field.near:Show()
    else
        view.field.near:Hide()
    end
    markPool:Reset()
    for i = 1, #self.falls do
        local fl = self.falls[i]
        local lr = self:LandingRow(fl)
        local kill = self:Doomed(fl)
        local col = kill and C_PAD_KILL or C_PAD
        local m = markPool:Acquire()
        ns.Paint(m.pad, col[1], col[2], col[3], kill and 0.34 or 0.16)
        ns.Paint(m.line, col[1], col[2], col[3], 1)
        m:ClearAllPoints()
        m:SetPoint("BOTTOMLEFT", stage, "BOTTOMLEFT",
            OFFSET_X + (fl.c - 1) * CELL + half, (lr - 1) * CELL + half)
        local drawR = fl.r + (1 - (fl.t or 0)) * (fl.fromR - fl.r)
        local gh = (drawR - lr - 1) * CELL + GAP
        if gh >= 1 then
            ns.Paint(m.guide, col[1], col[2], col[3], kill and 0.6 or 0.35)
            m.guide:SetHeight(gh)
            m.guide:Show()
        else
            m.guide:Hide()
        end
    end
    markPool:HideExtras()
    boxPool:Reset()
    grabPool:Reset()
    holdPool:Reset()
    local sliding = {}
    for i = 1, #self.slides do
        local s = self.slides[i]
        sliding[s.r * 100 + s.c] = s
    end
    for r = 1, ROWS do
        local row = self.grid[r]
        if row then
            for c = 1, COLS do
                local kind = row[c]
                if kind then
                    local f = boxPool:Acquire()
                    local dc, dr = c, r
                    local s = sliding[r * 100 + c]
                    if s then dc, dr = slidePos(s) end
                    placeBox(f, stage, OFFSET_X + (dc - 1) * CELL + half, (dr - 1) * CELL + half)
                    dressBox(f, kind)
                    badge(f, kind <= PLAIN_KINDS and self.crateName or nil, 26)
                end
            end
        end
    end
    for i = 1, #self.falls do
        local fl = self.falls[i]
        local t = fl.t or 0
        local drawR = fl.r + (1 - t) * (fl.fromR - fl.r)
        local f = boxPool:Acquire()
        placeBox(f, stage, OFFSET_X + (fl.c - 1) * CELL + half, (drawR - 1) * CELL + half)
        dressBox(f, fl.kind or 1)
        badge(f, (fl.kind or 1) <= PLAIN_KINDS and self.crateName or nil, 26)
    end
    for i = 1, #self.grabs do
        local g = self.grabs[i]
        if g.st ~= "off" then
            local gx = g.x
            if g.kind then
                local f = holdPool:Acquire()
                placeBox(f, view.laneChild, gx - (CELL - GAP) / 2, 0)
                dressBox(f, g.kind)
                badge(f, g.kind <= PLAIN_KINDS and self.crateName or nil, 26)
            end
            local gf = grabPool:Acquire()
            local k = 1
            if g.st == "ride" or (g.st == "leave" and g.kind) then
                k = 0
            elseif g.st == "open" then
                k = floor(clamp01((g.t or 0) / G.dropT) * 4) / 4
            end
            spreadGrab(gf, k)
            gf:SetAlpha(g.kind and 1 or 0.78)
            gf:ClearAllPoints()
            gf:SetPoint("BOTTOMLEFT", view.laneChild, "BOTTOMLEFT", gx - G.w / 2, 0)
        end
    end
    grabPool:HideExtras()
    holdPool:HideExtras()
    boxPool:HideExtras()
    if self.toast then
        local left = self.toastT or 0
        view.toast.text:SetText(self.toast == "points" and format(ns.T(BONUS_GOT.points), BONUS_SCORE)
            or ns.T(BONUS_GOT[self.toast]))
        view.toast:SetAlpha(left < 0.5 and left / 0.5 or 1)
        view.toast:Show()
    else
        view.toast:Hide()
    end
    dressWorker(view.worker, self.class)
    local pose, phase = "stand", 0
    local supported = self:Supported()
    if not supported then
        pose = (w.vy > 0) and "jump" or "fall"
    elseif self:DesiredDir() ~= 0 then
        pose, phase = "walk", floor(w.px / 24) % 2
    end
    poseWorker(view.worker, pose, phase, w.dir or 1)
    badge(view.worker, self.workerName, 15)
    view.worker:ClearAllPoints()
    view.worker:SetPoint("BOTTOMLEFT", stage, "BOTTOMLEFT", w.px - P.halfW, w.py)
    view.worker:Show()
end
local MINI_CRATE  = { 0.55, 0.38, 0.22 }
local MINI_WORKER = { 0.92, 0.42, 0.14 }
local MINI = {
    {
        cols = 5, rows = 2, cell = 28, gap = 2, back = "plain", face = C_FLOOR,
        fill = {
            { c = 1, r = 1, col = MINI_CRATE }, { c = 2, r = 1, col = MINI_CRATE },
            { c = 4, r = 1, col = MINI_CRATE }, { c = 5, r = 1, col = MINI_CRATE },
            { c = 1, r = 2, col = MINI_WORKER }, { c = 2, r = 2, col = MINI_CRATE },
        },
        arrow = {
            { c1 = 2, r1 = 2, c2 = 3, r2 = 2, col = MINI_CRATE },
            { c1 = 3, r1 = 2, c2 = 3, r2 = 1, col = MINI_CRATE },
        },
    },
    {
        cols = 5, rows = 2, cell = 28, gap = 2, back = "plain", face = C_FLOOR,
        fill = {
            { c = 1, r = 1, col = MINI_CRATE }, { c = 2, r = 1, col = MINI_CRATE },
            { c = 3, r = 1, col = MINI_CRATE }, { c = 4, r = 1, col = MINI_CRATE },
            { c = 5, r = 1, col = MINI_CRATE },
            { c = 1, r = 2, col = MINI_CRATE }, { c = 2, r = 2, col = MINI_CRATE },
            { c = 4, r = 2, col = MINI_CRATE },
        },
        ring = {
            { c = 1, r = 1 }, { c = 2, r = 1 }, { c = 3, r = 1 },
            { c = 4, r = 1 }, { c = 5, r = 1 },
        },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, spec.face)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpPit(host) paintMini(host, MINI[1]) end
local function helpRow(host) paintMini(host, MINI[2]) end
local HELP_CRATES = { 1, 3, 5, 6, 7 }
local function helpCrates(host)
    local side, gap = CELL - GAP, 12
    local x0 = floor((host:GetWidth() - (#HELP_CRATES * side + (#HELP_CRATES - 1) * gap)) / 2)
    for i = 1, #HELP_CRATES do
        local f = boxFrame(host)
        f:SetPoint("TOPLEFT", host, "TOPLEFT", x0 + (i - 1) * (side + gap), 0)
        dressBox(f, HELP_CRATES[i])
        f:Show()
    end
end
ns.RegisterGame{
    id = ID,
    label = "stack.label",
    icon = { draw = ns.StackTileIcon },
    tip = "stack.tip",
    order = 11,
    duo = "none",
    physics = true,
    fx = true,
    look = LOOK,
    ownPanel = true,
    done = true,
    finale = true,
    New = New,
    record = {
        { key = "score", label = "stack.recScore", by = "max", mark = "token" },
        { key = "time",  label = "stack.recTime",  by = "max", mark = "clock",
          format = "span" },
    },
    opts = {
        { key = "worker", label = "stack.optWorkerLabel", def = WORKER_DEF, options = WORKERS,
          tip = "stack.optWorkerTip" },
        { key = "shift", label = "stack.optShiftLabel", def = SHIFT_DEF,
          ordered = true, options = SHIFTS, tip = "stack.optShiftTip" },
    },
    keymap = {
        LEFT = "left", RIGHT = "right", UP = "up",
    },
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
        { action = "up",    label = "stack.ctlJump", mouse = false },
    },
    help = {
        "stack.help1",
        { art = helpRow, h = 66, sub = "stack.helpRowSub" },
        "stack.help2",
        "stack.help3",
        { art = helpPit, h = 66 },
        "stack.helpPitSub",
        "stack.help4",
        "stack.help5",
        "stack.help6",
        "stack.help7",
        { art = helpCrates, h = 48 },
        "stack.helpCratesSub",
    },
}
