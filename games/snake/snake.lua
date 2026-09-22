local ADDON, ns = ...
local ID = "snake"
local floor, sin = math.floor, math.sin
local SIZES = {
    { key = "yard",   cols = 11, rows = 8,
      label = "snake.sizeYardLabel",   tip = "snake.sizeYardTip" },
    { key = "garden", cols = 16, rows = 10,
      label = "snake.sizeGardenLabel", tip = "snake.sizeGardenTip" },
    { key = "park",   cols = 18, rows = 12,
      label = "snake.sizeParkLabel",   tip = "snake.sizeParkTip" },
}
local DEF_SIZE = "park"
local MAXC, MAXR = 18, 12
local COLS, ROWS = 18, 12
local CELL, GAP = 32, 2
local FX, FY = 0, 0
local miniOn = false
local MINI_MARGIN = 14
local NICHE_X, NICHE_Y, NICHE_H = 14, 10, 28
local NICHE_W = 640 - NICHE_X * 2
local NICHE_PAD = 12
local AREA_Y = NICHE_X
local AREA_H = 480 - NICHE_Y - NICHE_H - 12 - AREA_Y
local WALL = 16
local START_LEN = 3
local BASE_INTERVAL, MIN_INTERVAL, DECAY = 0.30, 0.09, 0.006
local FOOD_SCORE, WIN_BONUS = 10, 500
local END_FLASH = 0.8
local TONE_RUN, TONE_DEEP = 12, 0.55
local HEAD_LIFT = 1.5
local BULGE, BULGE_LIFT, BULGE_RUN = 6, 1.22, 2
local WALL_SOLID, WALL_WRAP = "solid", "wrap"
local WALLS = {
    { key = WALL_SOLID, label = "snake.wallSolidLabel" },
    { key = WALL_WRAP,  label = "snake.wallWrapLabel" },
}
local WALL_OPEN_K = 0.42
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local LEAF_TEX = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local C_FRAME  = { 0.62, 0.86, 0.44 }
local WALL_BED = { 0.30, 0.52, 0.24 }
local GROUND_TEX  = "Interface\\ItemTextFrame\\ItemText-Stone-TopLeft"
local GROUND_CROP = { 0.03125, 1, 0.046875, 1 }
local GROUND_C    = { 0.66, 0.68, 0.60 }
local GROUND_BED  = { 0.33, 0.34, 0.30 }
local LOOK_WOOD = { 0.230, 0.190, 0.130 }
local LOOK_EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE, screen = GROUND_C }
local KERB_C   = { 0.62, 0.63, 0.55 }
local KERB_W   = 3
local KERB_OUT = 3
local LEAF_CROP = { 0.06, 0.94, 0.06, 0.94 }
local LAWN_C    = { 0.56, 0.84, 0.38 }
local GRID_C    = { 0.46, 0.55, 0.26 }
local RIM_LO    = { 0.15, 0.19, 0.09 }
local RIM_HI    = { 0.72, 0.71, 0.62 }
local EYE_C     = { 0.06, 0.09, 0.07 }
local FOOD_ICON  = CELL - GAP - 4
local FOOD_GLOW  = CELL + 12
local GLOW_C     = { 1.0, 0.86, 0.45 }
local GLOW_LO, GLOW_HI = 0.30, 0.75
local SHADOW_A   = 0.45
local SHADOW_DX, SHADOW_DY = 2, -2
local BAR_RULE  = { 0.21, 0.185, 0.145 }
local VAL_FONT  = "Fonts\\FRIZQT__.TTF"
local C_SOFT    = { 0.78, 0.66, 0.36 }
local C_PAUSE   = { 0.5, 0.5, 0.5 }
local EMPTY_TEX = "Interface\\Buttons\\WHITE8X8"
local function SpeedFor(len)
    local v = BASE_INTERVAL - DECAY * (len - START_LEN)
    if v < MIN_INTERVAL then v = MIN_INTERVAL end
    return v
end
local function cellKey(x, y)
    return (y - 1) * COLS + x
end
local function clamp1(v)
    if v > 1 then return 1 end
    if v < 0 then return 0 end
    return v
end
local function cellX(x) return FX + WALL + (x - 1) * CELL end
local function cellY(y) return FY + WALL + (y - 1) * CELL end
local function midX(x) return FX + WALL + (x - 0.5) * CELL end
local function midY(y) return FY + WALL + (y - 0.5) * CELL end
local function tone(i)
    local k = (i - 1) / TONE_RUN
    if k > 1 then k = 1 end
    return 1 - TONE_DEEP * k
end
local view, segPool
local function bevelFrame(parent, level, size)
    local f = ns.NewFrame("Frame", nil, parent)
    f.baseLevel = parent:GetFrameLevel() + level
    f:SetFrameLevel(f.baseLevel)
    f:SetWidth(size)
    f:SetHeight(size)
    f.edge = f:CreateTexture(nil, "BACKGROUND")
    f.edge:SetAllPoints()
    f.body = f:CreateTexture(nil, "BORDER")
    f.body:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    f.body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    f.hi = f:CreateTexture(nil, "ARTWORK")
    f.hi:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    f.hi:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    f.hi:SetHeight(size >= 24 and 5 or 3)
    f:Hide()
    return f
end
local function paintBevel(f, r, g, b)
    ns.Paint(f.edge, r * 0.40, g * 0.40, b * 0.40, 1)
    ns.Paint(f.body, r, g, b, 1)
    ns.Paint(f.hi, clamp1(r * 1.45), clamp1(g * 1.45), clamp1(b * 1.45), 1)
end
local function buildField(canvas)
    local f = ns.NewFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + 1)
    f:SetWidth(MAXC * CELL + WALL * 2)
    f:SetHeight(MAXR * CELL + WALL * 2)
    f:SetBackdrop({ edgeFile = EDGE_TEX, edgeSize = WALL })
    f:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], 1)
    f.hedge = f:CreateTexture(nil, "BACKGROUND")
    f.hedge:SetAllPoints(f)
    f.hedge:SetTexture(LEAF_TEX)
    f.hedge:SetTexCoord(LEAF_CROP[1], LEAF_CROP[2], LEAF_CROP[3], LEAF_CROP[4])
    f.hedge:SetVertexColor(WALL_BED[1], WALL_BED[2], WALL_BED[3])
    local FW, FH = MAXC * CELL, MAXR * CELL
    local deck = ns.NewFrame("Frame", nil, f)
    deck:SetFrameLevel(f:GetFrameLevel() + 1)
    deck:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", WALL, WALL)
    deck:SetWidth(FW)
    deck:SetHeight(FH)
    local fl = deck:CreateTexture(nil, "BACKGROUND")
    fl:SetTexture(LEAF_TEX)
    fl:SetTexCoord(LEAF_CROP[1], LEAF_CROP[2], LEAF_CROP[3], LEAF_CROP[4])
    fl:SetVertexColor(LAWN_C[1], LAWN_C[2], LAWN_C[3])
    fl:SetAllPoints(deck)
    f.gridV, f.gridH = {}, {}
    for i = 1, MAXC - 1 do
        local t = ns.Fill(deck, "ARTWORK", GRID_C)
        t:SetWidth(2)
        f.gridV[i] = t
    end
    for i = 1, MAXR - 1 do
        local t = ns.Fill(deck, "ARTWORK", GRID_C)
        t:SetHeight(2)
        f.gridH[i] = t
    end
    local rt = ns.Fill(deck, "OVERLAY", RIM_LO)
    rt:SetHeight(2)
    rt:SetPoint("TOPLEFT", deck, "TOPLEFT", 0, 0)
    local rl = ns.Fill(deck, "OVERLAY", RIM_LO)
    rl:SetWidth(2)
    rl:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", 0, 0)
    local rb = ns.Fill(deck, "OVERLAY", RIM_HI)
    rb:SetHeight(2)
    rb:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", 0, 0)
    local rr = ns.Fill(deck, "OVERLAY", RIM_HI)
    rr:SetWidth(2)
    rr:SetPoint("BOTTOMRIGHT", deck, "BOTTOMRIGHT", 0, 0)
    f.deck, f.floor = deck, fl
    f.rims = { rt, rl, rb, rr }
    f:Hide()
    return f
end
local function layoutField()
    if not view or not view.field then return end
    local f = view.field
    local FW, FH = COLS * CELL, ROWS * CELL
    local W, H = FW + WALL * 2, FH + WALL * 2
    if miniOn then
        local canvas = f:GetParent()
        FX = floor(((canvas.W or W) - W) / 2)
        FY = floor(((canvas.H or H) - H) / 2)
    else
        FX = floor((640 - W) / 2)
        FY = AREA_Y + floor((AREA_H - H) / 2)
    end
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", f:GetParent(), "BOTTOMLEFT", FX, FY)
    f:SetWidth(W)
    f:SetHeight(H)
    f.deck:SetWidth(FW)
    f.deck:SetHeight(FH)
    for i = 1, MAXC - 1 do
        local t = f.gridV[i]
        if i <= COLS - 1 then
            t:SetHeight(FH)
            t:SetPoint("BOTTOMLEFT", f.deck, "BOTTOMLEFT", i * CELL - 1, 0)
            t:Show()
        else
            t:Hide()
        end
    end
    for i = 1, MAXR - 1 do
        local t = f.gridH[i]
        if i <= ROWS - 1 then
            t:SetWidth(FW)
            t:SetPoint("BOTTOMLEFT", f.deck, "BOTTOMLEFT", 0, i * CELL - 1)
            t:Show()
        else
            t:Hide()
        end
    end
    f.rims[1]:SetWidth(FW)
    f.rims[2]:SetHeight(FH)
    f.rims[3]:SetWidth(FW)
    f.rims[4]:SetHeight(FH)
end
local function byKey(list, key, def)
    for _, it in ipairs(list) do
        if it.key == key then return it end
    end
    for _, it in ipairs(list) do
        if it.key == def then return it end
    end
    return list[1]
end
local function useSize(key)
    local sz = byKey(SIZES, key, DEF_SIZE)
    COLS, ROWS = sz.cols, sz.rows
    layoutField()
    return sz
end
local function placeCell(f, canvas, x, y, big)
    local size = CELL - GAP + (big and BULGE or 0)
    if f.size ~= size then
        f:SetWidth(size)
        f:SetHeight(size)
        f:SetFrameLevel(f.baseLevel + (big and 1 or 0))
        f.size = size
    end
    local off = (CELL - size) / 2
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", cellX(x) + off, cellY(y) + off)
end
local function paintWalls(open)
    if not view then return end
    local k = open and WALL_OPEN_K or 1
    view.field:SetBackdropBorderColor(
        C_FRAME[1] * k, C_FRAME[2] * k, C_FRAME[3] * k, 1)
end
local function buildHead(canvas)
    local f = bevelFrame(canvas, 6, CELL - GAP)
    f.eyeL = ns.Fill(f, "OVERLAY", EYE_C)
    f.eyeL:SetWidth(5)
    f.eyeL:SetHeight(5)
    f.eyeR = ns.Fill(f, "OVERLAY", EYE_C)
    f.eyeR:SetWidth(5)
    f.eyeR:SetHeight(5)
    return f
end
local function wallsItem()
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.options then
            for i = 1, #it.options do
                if it.options[i].key == WALL_WRAP then return it end
            end
        end
    end
end
local function sizeItem()
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.options then
            for i = 1, #it.options do
                if it.options[i].key == DEF_SIZE then return it end
            end
        end
    end
end
local function buildBar(canvas)
    local f = ns.MakeNiche(canvas, 30, LOOK)
    f:SetPoint("TOPLEFT", canvas, "TOPLEFT", NICHE_X, -NICHE_Y)
    f:SetWidth(NICHE_W)
    f:SetHeight(NICHE_H)
    local function stat(xCap, xVal, capKey, host)
        host = host or f
        local cap = ns.MakeCap(f, xCap, 9)
        ns.SetKeyText(cap, capKey)
        local v = host:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.SetFont(v, VAL_FONT, 16, "")
        v:SetJustifyH("RIGHT")
        v:SetPoint("RIGHT", f, "LEFT", xVal, 0)
        return v
    end
    local function rule(x)
        local t = ns.Fill(f, "ARTWORK", BAR_RULE)
        t:SetWidth(1)
        t:SetPoint("TOP", f, "TOPLEFT", x, -6)
        t:SetPoint("BOTTOM", f, "TOPLEFT", x, -(NICHE_H - 6))
    end
    f.score = stat(NICHE_PAD, 108, "panelScore")
    rule(122)
    f.clockBox = ns.NewFrame("Frame", nil, f)
    f.clockBox:SetPoint("LEFT", f, "LEFT", 134, 0)
    f.clockBox:SetWidth(230 - 134); f.clockBox:SetHeight(NICHE_H)
    f.clock = stat(134, 230, "panelClock", f.clockBox)
    rule(244)
    f.best = stat(256, 352, "snake.bestCap")
    f.best:SetFontObject("GameFontHighlightSmall")
    f.best:SetJustifyH("RIGHT")
    rule(366)
    f.size = ns.MakeStepper(f)
    f.size:SetWidth(104)
    f.size:SetHeight(20)
    f.size:SetPoint("LEFT", f, "LEFT", 378, 0)
    f.check = ns.MakeCheck(f)
    ns.SetKeyText(f.check.label, "snake.wallCheck")
    f.PlaceCheck = function()
        f.check:ClearAllPoints()
        f.check:SetPoint("RIGHT", f, "RIGHT",
            -(NICHE_PAD + 16 + 2 + floor((f.check.label:GetStringWidth() or 60) + 0.5)), 0)
    end
    f.PlaceCheck()
    ns.OnLocale(f.PlaceCheck)
    f.check.onToggle = function(on)
        local it = wallsItem()
        if not it or it.disabled or not it.onPick then
            f.check:SetChecked(not on)
            return
        end
        it.onPick(on and WALL_WRAP or WALL_SOLID)
    end
    f:Hide()
    return f
end
local function buildGround(canvas)
    local f = ns.PlainFrame(canvas, 0)
    f:SetAllPoints(canvas)
    local bed = ns.Fill(f, "BACKGROUND", GROUND_BED)
    bed:SetAllPoints(f)
    local t = ns.window:ScreenFill(f, "BORDER")
    t:SetTexture(GROUND_TEX)
    t:SetTexCoord(GROUND_CROP[1], GROUND_CROP[2], GROUND_CROP[3], GROUND_CROP[4])
    t:SetVertexColor(GROUND_C[1], GROUND_C[2], GROUND_C[3])
    f.kerb = {}
    for i = 1, 4 do
        f.kerb[i] = ns.Fill(f, "ARTWORK", KERB_C)
    end
    f:Hide()
    return f
end
local function placeKerb(ground, field)
    local k = ground.kerb
    local out, w = KERB_OUT, KERB_W
    k[1]:SetPoint("BOTTOMLEFT",  field, "TOPLEFT",  -(out + w), out)
    k[1]:SetPoint("BOTTOMRIGHT", field, "TOPRIGHT",   out + w,  out)
    k[1]:SetHeight(w)
    k[2]:SetPoint("TOPLEFT",  field, "BOTTOMLEFT",  -(out + w), -out)
    k[2]:SetPoint("TOPRIGHT", field, "BOTTOMRIGHT",   out + w,  -out)
    k[2]:SetHeight(w)
    k[3]:SetPoint("TOPRIGHT",    field, "TOPLEFT",    -out,  out)
    k[3]:SetPoint("BOTTOMRIGHT", field, "BOTTOMLEFT", -out, -out)
    k[3]:SetWidth(w)
    k[4]:SetPoint("TOPLEFT",    field, "TOPRIGHT",     out,  out)
    k[4]:SetPoint("BOTTOMLEFT", field, "BOTTOMRIGHT",  out, -out)
    k[4]:SetWidth(w)
end
local function ensureView(canvas)
    if view then return end
    view = {}
    view.ground = buildGround(canvas)
    view.bar = buildBar(canvas)
    view.field = buildField(canvas)
    placeKerb(view.ground, view.field)
    view.food = bevelFrame(canvas, 4, CELL - GAP)
    local fr, fg, fb = ns.Palette.RGB("red")
    paintBevel(view.food, fr, fg, fb)
    view.food.glow = view.food:CreateTexture(nil, "BACKGROUND")
    view.food.glow:SetTexture(ns.CELL_HL)
    view.food.glow:SetBlendMode("ADD")
    view.food.glow:SetVertexColor(GLOW_C[1], GLOW_C[2], GLOW_C[3])
    view.food.glow:SetPoint("CENTER", view.food, "CENTER", 0, 0)
    view.food.glow:SetWidth(FOOD_GLOW)
    view.food.glow:SetHeight(FOOD_GLOW)
    view.food.shadow = view.food:CreateTexture(nil, "BORDER")
    view.food.shadow:SetVertexColor(0, 0, 0)
    view.food.shadow:SetAlpha(SHADOW_A)
    view.food.shadow:SetPoint("CENTER", view.food, "CENTER", SHADOW_DX, SHADOW_DY)
    view.food.shadow:SetWidth(FOOD_ICON)
    view.food.shadow:SetHeight(FOOD_ICON)
    view.food.shadow:Hide()
    view.food.badge = view.food:CreateTexture(nil, "OVERLAY")
    view.food.badge:SetPoint("CENTER", view.food, "CENTER", 0, 0)
    view.food.badge:SetWidth(FOOD_ICON)
    view.food.badge:SetHeight(FOOD_ICON)
    view.food.badge:Hide()
    view.head = buildHead(canvas)
    local r, g, b = ns.Palette.RGB("green")
    paintBevel(view.head, clamp1(r * HEAD_LIFT), clamp1(g * HEAD_LIFT), clamp1(b * HEAD_LIFT))
    segPool = ns.NewPool(function() return bevelFrame(canvas, 3, CELL - GAP) end)
end
local function hideView()
    if not view then return end
    view.ground:Hide()
    view.bar:Hide()
    view.field:Hide()
    view.food:Hide()
    view.head:Hide()
    if segPool then segPool:HideAll() end
end
local function applyFoodTex(self)
    local name = ns.Shelves.Pick(ID, "food", self.pickRng)
    self.foodTex = name and ns.IconPath(name) or nil
    if self.foodTex and view.food.badge:SetTexture(self.foodTex) then
        view.food.shadow:SetTexture(self.foodTex)
        ns.CropIcon(view.food.badge)
        ns.CropIcon(view.food.shadow)
        view.food.badge:Show()
        view.food.shadow:Show()
        view.food.edge:Hide()
        view.food.body:Hide()
        view.food.hi:Hide()
    else
        self.foodTex = nil
        view.food.badge:Hide()
        view.food.shadow:Hide()
        view.food.edge:Show()
        view.food.body:Show()
        view.food.hi:Show()
    end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.snake = {}
    self.occ = {}
    self.bulges = {}
    self.dir = { x = 1, y = 0 }
    self.queued = { x = 1, y = 0 }
    self.food = { x = 1, y = 1 }
    return self
end
function Game:SpawnFood()
    local free = {}
    for y = 1, ROWS do
        for x = 1, COLS do
            if not self.occ[cellKey(x, y)] then free[#free + 1] = { x = x, y = y } end
        end
    end
    local f = self.rng:Pick(free)
    if not f then return false end
    self.food.x, self.food.y = f.x, f.y
    applyFoodTex(self)
    return true
end
function Game:Move(move)
    if not move or move.k ~= "turn" then return end
    if self.phase == "over" then return end
    if self.turnedThisStep then return end
    local dx, dy = tonumber(move.x), tonumber(move.y)
    local ok = (dx == 1 and dy == 0) or (dx == -1 and dy == 0)
        or (dx == 0 and dy == 1) or (dx == 0 and dy == -1)
    if not ok then return end
    if dx == -self.dir.x and dy == -self.dir.y then
        ns.Sfx.Play("deny")
        return
    end
    self.queued.x, self.queued.y = dx, dy
    self.turnedThisStep = true
end
function Game:Key(action, down)
    if not down then return end
    local dx, dy
    if action == "left" then dx, dy = -1, 0
    elseif action == "right" then dx, dy = 1, 0
    elseif action == "up" then dx, dy = 0, 1
    elseif action == "down" then dx, dy = 0, -1
    else return end
    self:Move{ k = "turn", x = dx, y = dy }
end
function Game:Click(x, y, button)
end
function Game:Step()
    self.turnedThisStep = false
    self.dirty = true
    self.dir.x, self.dir.y = self.queued.x, self.queued.y
    local head = self.snake[1]
    local nx, ny = head.x + self.dir.x, head.y + self.dir.y
    if self.wrap then
        if nx < 1 then nx = COLS elseif nx > COLS then nx = 1 end
        if ny < 1 then ny = ROWS elseif ny > ROWS then ny = 1 end
    elseif nx < 1 or nx > COLS or ny < 1 or ny > ROWS then
        self:EndGame(false)
        return
    end
    local grow = (nx == self.food.x and ny == self.food.y)
    local tail = self.snake[#self.snake]
    local intoTail = (not grow) and tail.x == nx and tail.y == ny
    local k = cellKey(nx, ny)
    if self.occ[k] and not intoTail then
        self:EndGame(false)
        return
    end
    table.insert(self.snake, 1, { x = nx, y = ny })
    self.occ[k] = true
    if grow then
        self.score = self.score + FOOD_SCORE
        ns.Sfx.Play("pop")
        if self.score == FOOD_SCORE and ns.window then ns.window:SyncBar() end
        ns.FX.Stop()
        ns.FX.Play(self.canvas, {
            { x = midX(self.food.x), y = midY(self.food.y),
              size = CELL - GAP, tex = self.foodTex or EMPTY_TEX },
        })
        if not self:SpawnFood() then
            self:EndGame(true)
            return
        end
    else
        local old = table.remove(self.snake)
        self.occ[cellKey(old.x, old.y)] = nil
    end
    local live = {}
    for i = 1, #self.bulges do
        local b = self.bulges[i] + BULGE_RUN
        if b <= #self.snake then live[#live + 1] = b end
    end
    if grow then table.insert(live, 1, 1) end
    self.bulges = live
    self.stepInterval = SpeedFor(#self.snake)
end
function Game:EndGame(won)
    if self.phase == "over" then return end
    self.phase = "over"
    self.phaseT = END_FLASH
    self.won = won
    self.dirty = true
    if won then self.score = self.score + WIN_BONUS end
    local cells = {}
    for i = 1, #self.snake do
        local s = self.snake[i]
        cells[#cells + 1] = {
            x = midX(s.x), y = midY(s.y),
            size = CELL - GAP, tex = EMPTY_TEX,
        }
    end
    ns.FX.Stop()
    ns.FX.Play(self.canvas, cells, { big = true })
    ns.Sfx.Play(won and "clear" or "over")
end
function Game:Update(dt)
    self.t = self.t + dt
    if self.phase == "over" then
        self.phaseT = self.phaseT - dt
        self:Draw()
        return
    end
    self.stepT = self.stepT + dt
    if self.stepT >= self.stepInterval then
        self.stepT = self.stepT - self.stepInterval
        self:Step()
    end
    self:Draw()
end
function Game:Start(seed, moves)
    ensureView(self.canvas)
    self.rng = ns.RNG.New(seed)
    self.wrap = (self.opts and self.opts.walls == WALL_WRAP) or false
    local sz = useSize(self.opts and self.opts.size)
    self.opts = {}
    if self.wrap then self.opts.walls = WALL_WRAP end
    if sz.key ~= DEF_SIZE then self.opts.size = sz.key end
    paintWalls(self.wrap)
    self.pickRng = ns.RNG.New(seed)
    local cx, cy = floor(COLS / 2), floor(ROWS / 2)
    self.snake = {
        { x = cx, y = cy }, { x = cx - 1, y = cy }, { x = cx - 2, y = cy },
    }
    self.dir.x, self.dir.y = 1, 0
    self.queued.x, self.queued.y = 1, 0
    self.turnedThisStep = false
    self.occ = {}
    for i = 1, #self.snake do
        local s = self.snake[i]
        self.occ[cellKey(s.x, s.y)] = true
    end
    self.bulges = {}
    self:SpawnFood()
    self.score = 0
    self.stepT = 0
    self.stepInterval = SpeedFor(#self.snake)
    self.t = 0
    self.phase, self.phaseT, self.won = "play", 0, false
    self.dirty = true
    if moves and type(moves[1]) == "table" and moves[1].k == "snap" then
        self:Restore(moves[1])
    end
    local best = ns.Records.Best(ID, self.opts)
    local mark = ns.Records.Main(self.def)
    view.bar.best:SetText(best and ns.Records.Format(mark, best[mark.key]) or "—")
    self._panelLock = nil
    view.ground:Show()
    view.bar:Show()
    view.field:Show()
    self:Draw()
end
function Game:Score()
    return floor(self.score or 0)
end
function Game:Brink()
    local x, y = 6, 6
    self.snake = {
        { x = x,     y = y },
        { x = x - 1, y = y },
        { x = x - 1, y = y + 1 },
        { x = x,     y = y + 1 },
        { x = x + 1, y = y + 1 },
        { x = x + 1, y = y },
        { x = x + 2, y = y },
    }
    self.occ = {}
    for i = 1, #self.snake do
        local s = self.snake[i]
        self.occ[cellKey(s.x, s.y)] = true
    end
    self.bulges = {}
    self.dir.x, self.dir.y = 1, 0
    self.queued.x, self.queued.y = 1, 0
    self.turnedThisStep = false
    self.stepT = 0
    self.stepInterval = SpeedFor(#self.snake)
    self:SpawnFood()
    self.dirty = true
end
function Game:Locked()
    return (self.score or 0) > 0
end
function Game:PanelSync()
    if not view or ns.Loop.Current() ~= self then return end
    local bar = view.bar
    local mark = ns.Records.MarkFor(self.def, "score")
    bar.score:SetText(ns.Records.Format(mark, floor(self.score or 0)))
    local paused = ns.Loop.IsPaused()
    bar.clock:SetText(ns.Records.Span(ns.window:Elapsed()))
    local c = paused and C_PAUSE or C_SOFT
    bar.clock:SetTextColor(c[1], c[2], c[3])
    local locked = ns.window:AxisLocked()
    if self._panelLock == locked then return end
    self._panelLock = locked
    local sit = sizeItem()
    if sit then
        bar.size:SetSpec(sit)
        if sit.disabled then bar.size:Disable() else bar.size:Enable() end
        bar.size:Restyle()
    end
    local it = wallsItem()
    bar.check:SetChecked(self.wrap and true or false)
    bar.check.tip = it and it.tip or ns.T("snake.optWallsTip")
    bar.check.tipDim = it and it.tipDim or nil
    if it and it.disabled then
        bar.check:Disable()
        bar.check:SetAlpha(0.45)
    else
        bar.check:Enable()
        bar.check:SetAlpha(1)
    end
end
function Game:IsOver()
    return self.phase == "over" and self.phaseT <= 0
end
function Game:Stop()
    hideView()
    miniOn = false
end
function Game:MiniSize()
    return COLS * CELL + WALL * 2 + MINI_MARGIN * 2,
        ROWS * CELL + WALL * 2 + MINI_MARGIN * 2
end
function Game:Mini(on)
    miniOn = on and true or false
    if view then
        if miniOn then
            view.ground:Hide()
            view.bar:Hide()
        else
            view.ground:Show()
            view.bar:Show()
        end
    end
    layoutField()
    self.dirty = true
end
function Game:MiniNote()
    local mark = ns.Records.MarkFor(self.def, "score")
    return ns.Records.Format(mark, floor(self.score or 0))
end
local SNAP_V = 4
function Game:Serialize()
    local sn = {}
    for i = 1, #self.snake do
        local s = self.snake[i]
        local n = #sn
        sn[n + 1], sn[n + 2] = s.x, s.y
    end
    return {
        k = "snap", v = SNAP_V,
        score = self.score, t = self.t,
        dx = self.dir.x, dy = self.dir.y,
        qx = self.queued.x, qy = self.queued.y,
        stepT = self.stepT, stepInterval = self.stepInterval,
        fx = self.food.x, fy = self.food.y,
        phase = self.phase, pt = self.phaseT, won = self.won and 1 or 0,
        rng = self.rng:State(),
        snake = sn,
    }
end
local function dirPair(x, y, defx, defy)
    x, y = tonumber(x), tonumber(y)
    if (x == 1 and y == 0) or (x == -1 and y == 0)
        or (x == 0 and y == 1) or (x == 0 and y == -1) then
        return x, y
    end
    return defx, defy
end
function Game:Restore(s)
    if s.v ~= SNAP_V then return end
    self.score = ns.Store.Num(s.score, 0, 1e9, 0)
    self.t = ns.Store.Num(s.t, 0, 1e6, 0)
    local dx, dy = dirPair(s.dx, s.dy, 1, 0)
    self.dir.x, self.dir.y = dx, dy
    local qx, qy = dirPair(s.qx, s.qy, dx, dy)
    self.queued.x, self.queued.y = qx, qy
    self.turnedThisStep = false
    local body = type(s.snake) == "table" and s.snake or {}
    local list = {}
    for i = 1, floor(#body / 2) * 2, 2 do
        list[#list + 1] = {
            x = floor(ns.Store.Num(body[i], 1, COLS, 1)),
            y = floor(ns.Store.Num(body[i + 1], 1, ROWS, 1)),
        }
    end
    if #list < 1 then
        local cx, cy = floor(COLS / 2), floor(ROWS / 2)
        list = { { x = cx, y = cy }, { x = cx - 1, y = cy }, { x = cx - 2, y = cy } }
    end
    self.snake = list
    self.occ = {}
    for i = 1, #self.snake do
        local seg = self.snake[i]
        self.occ[cellKey(seg.x, seg.y)] = true
    end
    self.bulges = {}
    self.stepInterval = ns.Store.Num(s.stepInterval, MIN_INTERVAL, BASE_INTERVAL, SpeedFor(#self.snake))
    self.stepT = ns.Store.Num(s.stepT, 0, self.stepInterval, 0)
    self.phase = (s.phase == "over") and "over" or "play"
    self.phaseT = ns.Store.Num(s.pt, 0, END_FLASH, 0)
    self.won = s.won == 1
    if s.rng then self.rng = ns.RNG.Restore(s.rng) end
    self.food.x = floor(ns.Store.Num(s.fx, 1, COLS, 1))
    self.food.y = floor(ns.Store.Num(s.fy, 1, ROWS, 1))
    if self.occ[cellKey(self.food.x, self.food.y)] then
        self:SpawnFood()
    else
        applyFoodTex(self)
    end
    self.dirty = true
end
function Game:Paint()
    local canvas = self.canvas
    local r, g, b = ns.Palette.RGB("green")
    local dead = (self.phase == "over")
    local bump = {}
    for i = 1, #self.bulges do bump[self.bulges[i]] = true end
    segPool:Reset()
    if not dead then
        for i = 2, #self.snake do
            local s = self.snake[i]
            local f = segPool:Acquire()
            local big = bump[i] or false
            placeCell(f, canvas, s.x, s.y, big)
            local key = big and -i or i
            if f.tone ~= key then
                local k = tone(i) * (big and BULGE_LIFT or 1)
                paintBevel(f, clamp1(r * k), clamp1(g * k), clamp1(b * k))
                f.tone = key
            end
        end
    end
    segPool:HideExtras()
    local head = self.snake[1]
    if dead or not head then
        view.head:Hide()
    else
        placeCell(view.head, canvas, head.x, head.y, bump[1] or false)
        local dx, dy = self.dir.x, self.dir.y
        local sx, sy = -dy, dx
        view.head.eyeL:ClearAllPoints()
        view.head.eyeL:SetPoint("CENTER", view.head, "CENTER",
            dx * 6 + sx * 5, dy * 6 + sy * 5)
        view.head.eyeR:ClearAllPoints()
        view.head.eyeR:SetPoint("CENTER", view.head, "CENTER",
            dx * 6 - sx * 5, dy * 6 - sy * 5)
        view.head:Show()
    end
    view.food:ClearAllPoints()
    view.food:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
        cellX(self.food.x) + GAP / 2, cellY(self.food.y) + GAP / 2)
    view.food:Show()
end
function Game:Draw()
    if self.dirty then
        self.dirty = false
        self:Paint()
    end
    view.food.glow:SetAlpha(
        (GLOW_LO + GLOW_HI) / 2 + (GLOW_HI - GLOW_LO) / 2 * sin(self.t * 4))
end
local MINI_FACE = { 0.17, 0.20, 0.14 }
local MINI_TAIL = { 0.14, 0.38, 0.17 }
local MINI_BODY = { 0.22, 0.58, 0.26 }
local MINI_HEAD = { 0.55, 1.00, 0.60 }
local MINI_FOOD = { 0.95, 0.25, 0.30 }
local MINI = {
    {
        cols = 6, rows = 3, cell = 28, gap = 2, back = "plain",
        fill = {
            { c = 2, r = 2, col = MINI_TAIL },
            { c = 3, r = 2, col = MINI_BODY },
            { c = 4, r = 2, col = MINI_HEAD },
            { c = 6, r = 2, col = MINI_FOOD },
        },
        arrow = { { c1 = 4, r1 = 2, c2 = 6, r2 = 2, col = GLOW_C } },
    },
    {
        cols = 5, rows = 3, cell = 28, gap = 2, back = "plain",
        fill = {
            { c = 2, r = 2, col = MINI_TAIL },
            { c = 3, r = 2, col = MINI_BODY },
            { c = 4, r = 2, col = MINI_HEAD },
        },
        ring  = { { c = 3, r = 2 } },
        arrow = { { c1 = 4, r1 = 2, c2 = 3, r2 = 2, col = MINI_FOOD } },
    },
    {
        cols = 6, rows = 3, cell = 28, gap = 2, back = "plain",
        fill = {
            { c = 2, r = 2, col = MINI_TAIL },
            { c = 3, r = 2, col = MINI_BODY },
            { c = 4, r = 2, col = MINI_HEAD },
            { c = 6, r = 2, col = C_FRAME },
        },
        arrow = { { c1 = 4, r1 = 2, c2 = 6, r2 = 2, col = GLOW_C } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_FACE)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpGrowthArt(host) paintMini(host, MINI[1]) end
local function helpTurnArt(host) paintMini(host, MINI[2]) end
local function helpEdgeArt(host) paintMini(host, MINI[3]) end
ns.RegisterGame{
    id = ID,
    label = "snake.label",
    icon = { draw = ns.SnakeTileIcon },
    tip = "snake.tip",
    order = 9,
    duo = "none",
    physics = true,
    done = true,
    ownPanel = true,
    fx = true,
    look = LOOK,
    mini = { w = MAXC * CELL + WALL * 2 + MINI_MARGIN * 2,
             h = MAXR * CELL + WALL * 2 + MINI_MARGIN * 2 },
    finale = function(game) return game.won end,
    New = New,
    opts = {
        { key = "walls", label = "snake.optWallsLabel", def = WALL_SOLID, options = WALLS,
          tip = "snake.optWallsTip" },
        { key = "size", label = "snake.optSizeLabel", def = DEF_SIZE, options = SIZES,
          ordered = true, thin = true, tip = "snake.optSizeTip" },
    },
    keymap = {
        LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
    },
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
        { action = "up",    mouse = false },
        { action = "down",  mouse = false },
    },
    help = function(opts)
        local wrap = opts and opts.walls == WALL_WRAP
        local out = {
            wrap
                and ns.T("snake.help1Wrap")
                or ns.T("snake.help1Solid"),
            { art = helpEdgeArt, h = 96 },
        }
        if wrap then
            out[#out + 1] = ns.T("snake.helpEdgeSubWrap")
        end
        out[#out + 1] = ns.T("snake.helpGrowth")
        out[#out + 1] = { art = helpGrowthArt, h = 96, sub = ns.T("snake.helpGrowthSub") }
        out[#out + 1] = ns.T("snake.helpTurn")
        out[#out + 1] = { art = helpTurnArt, h = 96 }
        out[#out + 1] = ns.T("snake.help3")
        out[#out + 1] = wrap
            and ns.T("snake.help6Wrap")
            or ns.T("snake.help6Solid")
        return out
    end,
}
