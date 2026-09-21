local ADDON, ns = ...
local ID = "tetris"
local floor, min = math.floor, math.min
local COLS, ROWS = 10, 20
local SHAPES = {
    { n = 4, cells = { { 0, 1 }, { 1, 1 }, { 2, 1 }, { 3, 1 } } },
    { n = 2, cells = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } },
    { n = 3, cells = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } } },
    { n = 3, cells = { { 1, 0 }, { 2, 0 }, { 0, 1 }, { 1, 1 } } },
    { n = 3, cells = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 2, 1 } } },
    { n = 3, cells = { { 0, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } } },
    { n = 3, cells = { { 2, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } } },
}
local PIECE_RGB = {
    { 0.373, 0.690, 0.878 },
    { 0.761, 0.635, 0.290 },
    { 0.690, 0.435, 0.831 },
    { 0.541, 0.831, 0.435 },
    { 0.761, 0.290, 0.353 },
    { 0.435, 0.498, 0.831 },
    { 0.831, 0.627, 0.435 },
}
local DROP_BASE = 1.00
local SOFT_DROP = 0.05
local OVER_PAUSE = 0.8
local TUNE = {
    { key = "easy", rate = 0.86, floor = 0.05, lines = 8, pieces = 24,
      label = "tetris.diffEasyLabel", tip = "tetris.diffEasyTip" },
    { key = "mid",  rate = 0.84, floor = 0.04, lines = 6, pieces = 18,
      label = "tetris.diffMidLabel",  tip = "tetris.diffMidTip" },
    { key = "hard", rate = 0.80, floor = 0.03, lines = 5, pieces = 12,
      label = "tetris.diffHardLabel", tip = "tetris.diffHardTip" },
}
local DEF_DIFF = "mid"
local TUNE_BY = {}
for i = 1, #TUNE do TUNE_BY[TUNE[i].key] = TUNE[i] end
local function tuneOf(key)
    return TUNE_BY[key] or TUNE_BY[DEF_DIFF]
end
local LOCK_DELAY = 0.5
local KICKS = { 0, -1, 1, -2, 2 }
local LINE_SCORE = { 40, 100, 300, 1200 }
local STREAK_BONUS = 20
local DAS_DELAY, DAS_REPEAT = 0.20, 0.05
local function dropInterval(tune, level)
    local v = DROP_BASE * tune.rate ^ (level - 1)
    if v < tune.floor then v = tune.floor end
    return v
end
local rotCache = {}
local function rotateCells(cells, n)
    local out = {}
    for i = 1, #cells do
        out[i] = { n - 1 - cells[i][2], cells[i][1] }
    end
    return out
end
local function shapeCells(kind, rot)
    local key = kind * 4 + rot
    local c = rotCache[key]
    if c then return c end
    local shape = SHAPES[kind]
    c = shape.cells
    for _ = 1, rot do c = rotateCells(c, shape.n) end
    rotCache[key] = c
    return c
end
local function spanX(kind, rot)
    local cells = shapeCells(kind, rot)
    local minX, maxX = cells[1][1], cells[1][1]
    for i = 2, #cells do
        local x = cells[i][1]
        if x < minX then minX = x elseif x > maxX then maxX = x end
    end
    return minX, maxX
end
local CANVAS_W, CANVAS_H = 640, 480
local CELL = 24
local KANT = 2
local FIELD_W, FIELD_H = COLS * CELL, ROWS * CELL
local FIELD_X, FIELD_Y = floor((CANVAS_W - FIELD_W) / 2), 0
local WING_W = FIELD_X
local LEFT_X, LEFT_R = 20, 180
local NEXT_X, NEXT_TOP = 475, 43
local NEXT_W, NEXT_H = 134, 88
local RIGHT_R = NEXT_X + NEXT_W
local DIFF_CAP_Y = 364
local DIFF_TOP, DIFF_H, DIFF_GAP = 376, 24, 4
local DIFF_W = LEFT_R - LEFT_X
local BAR, BAR_GAP, BAR_N = 10, 2, 3
local DIFF_GHOST = 0.3
local DIFF_LOOK = {
    easy = { tone = 4, bars = 1 },
    mid  = { tone = 2, bars = 2 },
    hard = { tone = 5, bars = 3 },
}
local C_WELL  = { 0.055, 0.067, 0.098 }
local C_GRID  = { 0.110, 0.129, 0.188 }
local C_EDGE  = { 0.227, 0.263, 0.345 }
local C_WING  = { 0.039, 0.047, 0.071 }
local C_STRIP = { 0.102, 0.122, 0.180 }
local C_NEDGE = { 0.200, 0.227, 0.282 }
local C_SCR_TOP = { 0.043, 0.051, 0.071 }
local C_SCR_BOT = { 0.078, 0.094, 0.141 }
local C_CAP   = { 0.353, 0.408, 0.518 }
local C_VAL   = { 0.910, 0.925, 0.957 }
local C_SUB   = { 0.604, 0.643, 0.722 }
local C_MUTE  = { 0.5, 0.5, 0.5 }
local C_WARN  = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = C_WELL, edge = C_EDGE, screen = C_SCR_BOT }
local FONT = "Fonts\\FRIZQT__.TTF"
local TILE_TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local TILE_COORD = { 0.25, 0.5, 0.25, 0.5 }
local EMPTY_TEX = "Interface\\Buttons\\WHITE8X8"
local view, cellPool
local function cellFrame(canvas, level)
    local f = CreateFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + level)
    f:SetWidth(CELL - 1)
    f:SetHeight(CELL - 1)
    f.rim = f:CreateTexture(nil, "BACKGROUND")
    f.rim:SetAllPoints()
    f.face = f:CreateTexture(nil, "BORDER")
    f.face:SetPoint("TOPLEFT", f, "TOPLEFT", KANT, -KANT)
    f.face:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f:Hide()
    return f
end
local function paintKant(rim, face, c)
    local r, g, b = c[1], c[2], c[3]
    face:SetTexture(r, g, b, 1)
    rim:SetTexture(min(r * 1.35, 1), min(g * 1.35, 1), min(b * 1.35, 1), 1)
end
local function paintCell(f, kind)
    paintKant(f.rim, f.face, PIECE_RGB[kind])
end
local function styleBrick(b)
    local look = DIFF_LOOK[b.key] or DIFF_LOOK[DEF_DIFF]
    local tone = PIECE_RGB[look.tone]
    local lit = b.chosen or (b.hover and not b.locked)
    local edge = lit and tone or (b.hover and C_EDGE or C_NEDGE)
    b.rim:SetTexture(edge[1], edge[2], edge[3], 1)
    b.face:SetTexture(C_WELL[1], C_WELL[2], C_WELL[3], 1)
    local lc = lit and C_VAL or C_SUB
    b.label:SetTextColor(lc[1], lc[2], lc[3])
    for i = 1, BAR_N do
        local bar = b.bars[i]
        if i <= look.bars then
            paintKant(bar.rim, bar.face, lit and tone or C_CAP)
        else
            bar.rim:SetTexture(C_NEDGE[1], C_NEDGE[2], C_NEDGE[3], 1)
            bar.face:SetTexture(C_GRID[1], C_GRID[2], C_GRID[3], 1)
        end
    end
    b:SetAlpha((b.locked and not b.chosen) and DIFF_GHOST or 1)
end
local function diffBrick(parent, y)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(DIFF_W)
    b:SetHeight(DIFF_H)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT_X, -y)
    b.rim = b:CreateTexture(nil, "BACKGROUND")
    b.rim:SetAllPoints()
    b.face = b:CreateTexture(nil, "BORDER")
    b.face:SetPoint("TOPLEFT", b, "TOPLEFT", KANT, -KANT)
    b.face:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetFont(FONT, 12, "")
    b.label:SetJustifyH("LEFT")
    b.label:SetPoint("LEFT", b, "LEFT", 10, -1)
    b.bars = {}
    for i = 1, BAR_N do
        local rim = b:CreateTexture(nil, "ARTWORK")
        rim:SetWidth(BAR)
        rim:SetHeight(BAR)
        rim:SetPoint("RIGHT", b, "RIGHT", -(8 + (BAR_N - i) * (BAR + BAR_GAP)), -1)
        local face = b:CreateTexture(nil, "OVERLAY")
        face:SetPoint("TOPLEFT", rim, "TOPLEFT", KANT, -KANT)
        face:SetPoint("BOTTOMRIGHT", rim, "BOTTOMRIGHT", 0, 0)
        b.bars[i] = { rim = rim, face = face }
    end
    b:SetScript("OnEnter", function(self)
        self.hover = true
        styleBrick(self)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hover = nil
        styleBrick(self)
        ns.TipHide()
    end)
    b:SetScript("OnClick", function(self)
        if self.locked or self.chosen or not self.onPick then return end
        ns.Sfx.Ui("tick")
        self.onPick(self.key)
    end)
    b:Hide()
    return b
end
local function ensureView(canvas)
    if view then return end
    view = {}
    local deco = CreateFrame("Frame", nil, canvas)
    deco:SetFrameLevel(canvas:GetFrameLevel() + 1)
    deco:SetAllPoints(canvas)
    deco:Hide()
    view.deco = deco
    local rim = CreateFrame("Frame", nil, canvas)
    rim:SetFrameLevel(canvas:GetFrameLevel() + 6)
    rim:SetAllPoints(canvas)
    rim:Hide()
    view.rim = rim
    local function fill(parent, layer, x, top, w, h, c, a)
        local t = parent:CreateTexture(nil, layer)
        t:SetTexture(c[1], c[2], c[3], a or 1)
        t:SetWidth(w); t:SetHeight(h)
        t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -top)
        return t
    end
    local scr = ns.window:ScreenFill(deco)
    scr:SetTexture(1, 1, 1, 1)
    scr:SetGradient("VERTICAL",
        C_SCR_BOT[1], C_SCR_BOT[2], C_SCR_BOT[3],
        C_SCR_TOP[1], C_SCR_TOP[2], C_SCR_TOP[3])
    for _, wx in ipairs({ 0, FIELD_X + FIELD_W }) do
        fill(deco, "BORDER", wx, 0, WING_W, FIELD_H, C_WING, 0.5)
        for i = 1, WING_W / 40 - 1 do
            fill(deco, "ARTWORK", wx + i * 40, 0, 1, FIELD_H, C_STRIP, 0.5)
        end
        for j = 1, FIELD_H / 40 - 1 do
            fill(deco, "ARTWORK", wx, j * 40, WING_W, 1, C_STRIP, 0.5)
        end
    end
    fill(deco, "BORDER", FIELD_X, 0, FIELD_W, FIELD_H, C_WELL)
    for i = 1, COLS - 1 do
        fill(deco, "ARTWORK", FIELD_X + i * CELL, 0, 1, FIELD_H, C_GRID)
    end
    for j = 1, ROWS - 1 do
        fill(deco, "ARTWORK", FIELD_X, j * CELL, FIELD_W, 1, C_GRID)
    end
    fill(rim, "BORDER", FIELD_X - 1, 0, 2, FIELD_H, C_EDGE)
    fill(rim, "BORDER", FIELD_X + FIELD_W - 1, 0, 2, FIELD_H, C_EDGE)
    fill(rim, "BORDER", FIELD_X - 1, 0, FIELD_W + 2, 2, C_EDGE)
    fill(rim, "BORDER", FIELD_X - 1, FIELD_H - 2, FIELD_W + 2, 2, C_EDGE)
    fill(deco, "BORDER", NEXT_X, NEXT_TOP, NEXT_W, NEXT_H, C_WELL)
    fill(deco, "ARTWORK", NEXT_X, NEXT_TOP, NEXT_W, 1, C_NEDGE)
    fill(deco, "ARTWORK", NEXT_X, NEXT_TOP + NEXT_H - 1, NEXT_W, 1, C_NEDGE)
    fill(deco, "ARTWORK", NEXT_X, NEXT_TOP, 1, NEXT_H, C_NEDGE)
    fill(deco, "ARTWORK", NEXT_X + NEXT_W - 1, NEXT_TOP, 1, NEXT_H, C_NEDGE)
    local function text(host, x, y, size, c, right)
        local fs = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetFont(FONT, size, "")
        fs:SetTextColor(c[1], c[2], c[3])
        fs:SetJustifyH(right and "RIGHT" or "LEFT")
        fs:SetPoint(right and "RIGHT" or "LEFT", deco, "TOPLEFT", x, -y)
        return fs
    end
    local ROW_SCORE, ROW_CLOCK = 33, 69
    ns.SetKeyText(text(deco, LEFT_X, ROW_SCORE, 11, C_CAP), "tetris.scoreCap")
    view.scoreVal = text(deco, LEFT_R, ROW_SCORE, 22, C_VAL, true)
    local clockBox = CreateFrame("Frame", nil, deco)
    clockBox:SetPoint("TOPLEFT", deco, "TOPLEFT", LEFT_X, -(ROW_CLOCK - 16))
    clockBox:SetWidth(LEFT_R - LEFT_X)
    clockBox:SetHeight(32)
    ns.SetKeyText(text(clockBox, LEFT_X, ROW_CLOCK, 11, C_CAP), "tetris.clockCap")
    view.clockVal = text(clockBox, LEFT_R, ROW_CLOCK, 22, C_VAL, true)
    ns.SetKeyText(text(deco, NEXT_X, ROW_SCORE, 11, C_CAP), "tetris.nextLabel")
    local function statRow(y, capKey)
        ns.SetKeyText(text(deco, NEXT_X, y, 11, C_SUB), capKey)
        return text(deco, RIGHT_R, y, 13, C_VAL, true)
    end
    view.levelVal = statRow(158, "tetris.levelLabel")
    view.linesVal = statRow(180, "tetris.linesLabel")
    view.streakVal = statRow(202, "tetris.streakLabel")
    ns.SetKeyText(text(deco, LEFT_X, DIFF_CAP_Y, 11, C_CAP), "tetris.diffCap")
    view.diff = {}
    for i = 1, #TUNE do
        view.diff[i] = diffBrick(rim, DIFF_TOP + (i - 1) * (DIFF_H + DIFF_GAP))
    end
    cellPool = ns.NewPool(function() return cellFrame(canvas, 2) end)
end
local function hideView()
    if not view then return end
    view.deco:Hide()
    view.rim:Hide()
    if cellPool then cellPool:HideAll() end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:CursorPos()
    if not ns.Keys.MouseOn() then return nil, nil end
    local canvas = self.canvas
    local s = canvas:GetEffectiveScale()
    if not s or s == 0 then return nil, nil end
    local l, b = canvas:GetLeft(), canvas:GetBottom()
    if not l or not b then return nil, nil end
    local cx, cy = GetCursorPosition()
    return cx / s - l, cy / s - b
end
function Game:Collides(piece)
    local cells = shapeCells(piece.kind, piece.rot)
    for i = 1, #cells do
        local col = piece.x + cells[i][1]
        local row = piece.y + cells[i][2]
        if col < 0 or col >= COLS or row < 0 or row >= ROWS then return true end
        if self.grid[row * COLS + col + 1] ~= 0 then return true end
    end
    return false
end
function Game:TryMove(dx, dy)
    local test = { kind = self.cur.kind, rot = self.cur.rot, x = self.cur.x + dx, y = self.cur.y + dy }
    if self:Collides(test) then return false end
    self.cur.x, self.cur.y = test.x, test.y
    return true
end
function Game:Grounded()
    local test = { kind = self.cur.kind, rot = self.cur.rot, x = self.cur.x, y = self.cur.y + 1 }
    return self:Collides(test)
end
function Game:Steering()
    if self.leftDown or self.rightDown then return true end
    return self.aim ~= nil and self:AimFrameX() ~= self.cur.x
end
function Game:AimFrameX()
    local minX, maxX = spanX(self.cur.kind, self.cur.rot)
    local x = self.aim - floor((maxX - minX) / 2) - minX
    if x < -minX then x = -minX end
    if x > COLS - 1 - maxX then x = COLS - 1 - maxX end
    return x
end
function Game:TryRotate()
    local rot = (self.cur.rot + 1) % 4
    local test = { kind = self.cur.kind, rot = rot, y = self.cur.y }
    for i = 1, #KICKS do
        test.x = self.cur.x + KICKS[i]
        if not self:Collides(test) then
            self.cur.x, self.cur.rot = test.x, rot
            ns.Sfx.Play("pick")
            return true
        end
    end
    return false
end
function Game:RefillQueue()
    while #self.queue < 2 do
        local bag = { 1, 2, 3, 4, 5, 6, 7 }
        self.rng:Shuffle(bag)
        for i = 1, 7 do self.queue[#self.queue + 1] = bag[i] end
    end
end
function Game:Spawn()
    self:RefillQueue()
    local kind = table.remove(self.queue, 1)
    self:RefillQueue()
    local shape = SHAPES[kind]
    local piece = { kind = kind, rot = 0, x = floor((COLS - shape.n) / 2), y = 0 }
    if self:Collides(piece) then
        self.cur = nil
        self:EndGame()
        return
    end
    self.cur = piece
    self.dropT = 0
    self.lockT = nil
    self.pieces = self.pieces + 1
    self:Relevel()
end
function Game:Relevel()
    local byLines = floor(self.lines / self.tune.lines)
    local byPieces = floor(self.pieces / self.tune.pieces)
    self.level = (byLines > byPieces and byLines or byPieces) + 1
end
function Game:ClearLines()
    local newGrid = {}
    local writeRow = ROWS - 1
    local cleared = 0
    local rows = {}
    for row = ROWS - 1, 0, -1 do
        local full = true
        for col = 0, COLS - 1 do
            if self.grid[row * COLS + col + 1] == 0 then full = false break end
        end
        if full then
            cleared = cleared + 1
            rows[#rows + 1] = row
        else
            for col = 0, COLS - 1 do
                newGrid[writeRow * COLS + col + 1] = self.grid[row * COLS + col + 1]
            end
            writeRow = writeRow - 1
        end
    end
    for row = writeRow, 0, -1 do
        for col = 0, COLS - 1 do newGrid[row * COLS + col + 1] = 0 end
    end
    self.grid = newGrid
    return cleared, rows
end
function Game:Lock()
    local cells = shapeCells(self.cur.kind, self.cur.rot)
    for i = 1, #cells do
        local col = self.cur.x + cells[i][1]
        local row = self.cur.y + cells[i][2]
        if row >= 0 and row < ROWS and col >= 0 and col < COLS then
            self.grid[row * COLS + col + 1] = self.cur.kind
        end
    end
    local n, rows = self:ClearLines()
    if n > 0 then
        self.score = self.score + LINE_SCORE[n] * self.level
        self.streak = self.streak + 1
        if self.streak >= 2 then
            self.score = self.score + STREAK_BONUS * self.streak * self.level
        end
        self.lines = self.lines + n
        self:Relevel()
        self:PlayClearFX(rows, n)
        local big = n >= 4 and ns.Sfx.Get(ID, "big")
        ns.Sfx.Play(big and "big" or "clear")
    else
        self.streak = 0
        ns.Sfx.Play("pop")
    end
    self.cur = nil
    self:Spawn()
end
function Game:PlayClearFX(rows, n)
    local tex = EMPTY_TEX
    local cells = {}
    for i = 1, #rows do
        local row = rows[i]
        local cy = FIELD_Y + (ROWS - 1 - row) * CELL + CELL / 2
        for col = 0, COLS - 1 do
            cells[#cells + 1] = {
                x = FIELD_X + col * CELL + CELL / 2, y = cy,
                size = CELL - 1, tex = tex,
            }
        end
    end
    ns.FX.Stop()
    ns.FX.Play(self.canvas, cells, { big = n >= 2 })
end
function Game:HardDrop()
    if not self.cur then return end
    while self:TryMove(0, 1) do end
    self.dropT = 0
    self:Lock()
end
function Game:EndGame()
    if self.phase == "over" then return end
    self.phase = "over"
    self.phaseT = OVER_PAUSE
    ns.Sfx.Play("over")
end
function Game:Start(seed, moves)
    ensureView(self.canvas)
    self.tune = tuneOf(self.opts and self.opts.diff)
    self.rng = ns.RNG.New(seed)
    self.grid = {}
    for i = 1, COLS * ROWS do self.grid[i] = 0 end
    self.queue = {}
    self.cur = nil
    self.level, self.lines, self.score = 1, 0, 0
    self.pieces = 0
    self.streak = 0
    self.dropT = 0
    self.lockT = nil
    self.leftDown, self.rightDown = false, false
    self.dasDir, self.dasT = 0, 0
    self.softDown = false
    self.mouseSoft = false
    self.phase, self.phaseT = "play", 0
    self.lastCX = nil
    self.aim = nil
    if moves and type(moves[1]) == "table" and moves[1].k == "snap" then
        self:Restore(moves[1])
    else
        self:Spawn()
    end
    self.panelLock = nil
    view.deco:Show()
    view.rim:Show()
    self:SyncBoard()
    self:Draw()
end
function Game:Move(move)
end
function Game:Click(x, y, button)
    if self.phase ~= "play" or not self.cur then return end
    if button == "RightButton" then
        self:TryRotate()
    end
end
function Game:Key(action, down)
    if self.phase ~= "play" or not self.cur then return end
    if action == "left" or action == "right" then self.aim = nil end
    if action == "left" then
        self.leftDown = down
        if down then
            self.dasDir, self.dasT = -1, DAS_DELAY
            self:TryMove(-1, 0)
        elseif self.rightDown then
            self.dasDir, self.dasT = 1, DAS_DELAY
        else
            self.dasDir = 0
        end
    elseif action == "right" then
        self.rightDown = down
        if down then
            self.dasDir, self.dasT = 1, DAS_DELAY
            self:TryMove(1, 0)
        elseif self.leftDown then
            self.dasDir, self.dasT = -1, DAS_DELAY
        else
            self.dasDir = 0
        end
    elseif action == "down" then
        self.softDown = down
    elseif action == "up" then
        if down then self:TryRotate() end
    elseif action == "fire" then
        if down then self:HardDrop() end
    end
end
function Game:Update(dt)
    if self.phase == "over" then
        self.phaseT = self.phaseT - dt
        return
    end
    if not self.cur then return end
    if self.dasDir ~= 0 then
        self.dasT = self.dasT - dt
        if self.dasT <= 0 then
            self:TryMove(self.dasDir, 0)
            self.dasT = DAS_REPEAT
        end
    end
    local cx, cy = self:CursorPos()
    local onScreen = cx ~= nil
        and cx >= 0 and cx <= CANVAS_W and cy >= 0 and cy <= CANVAS_H
    if cx and cx ~= self.lastCX then
        self.lastCX = cx
        if onScreen then self.aim = floor((cx - FIELD_X) / CELL) end
    end
    if self.aim then
        local want = self:AimFrameX()
        if want > self.cur.x then self:TryMove(1, 0)
        elseif want < self.cur.x then self:TryMove(-1, 0) end
    end
    self.mouseSoft = onScreen and IsMouseButtonDown("LeftButton") and true or false
    local soft = self.softDown or self.mouseSoft
    local interval = dropInterval(self.tune, self.level)
    if soft and SOFT_DROP < interval then interval = SOFT_DROP end
    self.dropT = self.dropT + dt
    if self.dropT >= interval then
        self.dropT = self.dropT - interval
        self:TryMove(0, 1)
    end
    if self.cur then
        if self:Grounded() then
            if not self:Steering() then
                self:Lock()
            else
                self.lockT = (self.lockT or LOCK_DELAY) - dt
                if self.lockT <= 0 then self:Lock() end
            end
        else
            self.lockT = nil
        end
    end
    self:Draw()
end
function Game:Score()
    return floor(self.score or 0)
end
function Game:SyncBoard()
    view.scoreVal:SetText(floor(self.score or 0))
    local paused = ns.Loop.IsPaused()
    view.clockVal:SetText(ns.Records.Span(ns.window:Elapsed()))
    local c = paused and C_MUTE or C_VAL
    view.clockVal:SetTextColor(c[1], c[2], c[3])
end
function Game:PanelSync()
    if not view or ns.Loop.Current() ~= self then return end
    self:SyncBoard()
    local locked = ns.window:AxisLocked()
    if self.panelLock == locked then return end
    self.panelLock = locked
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.kind == "select" then
            for i, b in ipairs(view.diff) do
                local o = it.options and it.options[i]
                if o then
                    b.key = o.key
                    b.label:SetText(o.label or o.key)
                    b.tipTitle = o.label or o.key
                    b.tip = o.tip
                    b.tipDim = it.tipDim
                    b.onPick = it.onPick
                    b.chosen = o.key == it.value
                    b.locked = it.disabled and true or false
                    styleBrick(b)
                    b:Show()
                else
                    b:Hide()
                end
            end
            return
        end
    end
end
function Game:Relocalize()
    self.panelLock = nil
    self:PanelSync()
end
function Game:IsOver()
    return self.phase == "over" and self.phaseT <= 0
end
function Game:Stop()
    hideView()
end
local ghostProbe = {}
function Game:DropY()
    local p = ghostProbe
    p.kind, p.rot, p.x = self.cur.kind, self.cur.rot, self.cur.x
    local y = self.cur.y
    p.y = y + 1
    while not self:Collides(p) do
        y = p.y
        p.y = y + 1
    end
    return y
end
function Game:Draw()
    cellPool:Reset()
    local function place(col, row, kind, ghost)
        local f = cellPool:Acquire()
        paintCell(f, kind)
        f:SetAlpha(ghost and 0.25 or 1)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT",
            FIELD_X + col * CELL, FIELD_Y + (ROWS - 1 - row) * CELL)
    end
    for row = 0, ROWS - 1 do
        for col = 0, COLS - 1 do
            local kind = self.grid[row * COLS + col + 1]
            if kind ~= 0 then place(col, row, kind) end
        end
    end
    if self.cur then
        local cells = shapeCells(self.cur.kind, self.cur.rot)
        local gy = self:DropY()
        if gy > self.cur.y then
            for i = 1, #cells do
                local col, row = self.cur.x + cells[i][1], gy + cells[i][2]
                if row >= 0 then place(col, row, self.cur.kind, true) end
            end
        end
        for i = 1, #cells do
            local col, row = self.cur.x + cells[i][1], self.cur.y + cells[i][2]
            if row >= 0 then place(col, row, self.cur.kind) end
        end
    end
    if self.queue[1] then
        local kind = self.queue[1]
        local cells = SHAPES[kind].cells
        local minX, minY, maxX, maxY = cells[1][1], cells[1][2], cells[1][1], cells[1][2]
        for i = 2, #cells do
            local c = cells[i]
            if c[1] < minX then minX = c[1] elseif c[1] > maxX then maxX = c[1] end
            if c[2] < minY then minY = c[2] elseif c[2] > maxY then maxY = c[2] end
        end
        local left = NEXT_X + floor((NEXT_W - (maxX - minX + 1) * CELL) / 2)
        local top = NEXT_TOP + floor((NEXT_H - (maxY - minY + 1) * CELL) / 2)
        for i = 1, #cells do
            local c = cells[i]
            local f = cellPool:Acquire()
            paintCell(f, kind)
            f:SetAlpha(1)
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT",
                left + (c[1] - minX) * CELL,
                FIELD_H - top - (c[2] - minY + 1) * CELL)
        end
    end
    cellPool:HideExtras()
    view.levelVal:SetText(self.level)
    view.linesVal:SetText(self.lines)
    if self.streak >= 2 then
        local c = PIECE_RGB[4]
        view.streakVal:SetText("x" .. self.streak)
        view.streakVal:SetTextColor(c[1], c[2], c[3])
    else
        view.streakVal:SetText(ns.T("tetris.streakNone"))
        view.streakVal:SetTextColor(C_MUTE[1], C_MUTE[2], C_MUTE[3])
    end
end
function Game:Serialize()
    local grid = {}
    for i = 1, COLS * ROWS do grid[i] = self.grid[i] end
    local queue = {}
    for i = 1, #self.queue do queue[i] = self.queue[i] end
    return {
        k = "snap", v = 1,
        grid = grid, queue = queue,
        kind = self.cur and self.cur.kind or nil,
        rot = self.cur and self.cur.rot or nil,
        x = self.cur and self.cur.x or nil,
        y = self.cur and self.cur.y or nil,
        lines = self.lines, score = self.score,
        pieces = self.pieces,
        streak = self.streak,
        dropT = self.dropT,
        lockT = self.lockT,
        phase = self.phase, phaseT = self.phaseT,
        rng = self.rng:State(),
    }
end
function Game:Restore(s)
    if s.v ~= 1 then
        self:Spawn()
        return
    end
    local grid = type(s.grid) == "table" and s.grid or {}
    for i = 1, COLS * ROWS do
        local c = floor(ns.Store.Num(grid[i], 0, 7, 0))
        self.grid[i] = c
    end
    self.queue = {}
    if type(s.queue) == "table" then
        for i = 1, #s.queue do
            local k = tonumber(s.queue[i])
            if k and k >= 1 and k <= 7 then self.queue[#self.queue + 1] = floor(k) end
        end
    end
    self.lines = floor(ns.Store.Num(s.lines, 0, 1e6, 0))
    self.pieces = floor(ns.Store.Num(s.pieces, 0, 1e6, 0))
    self.score = ns.Store.Num(s.score, 0, 1e12, 0)
    self.streak = floor(ns.Store.Num(s.streak, 0, 1e6, 0))
    self.dropT = ns.Store.Num(s.dropT, 0, DROP_BASE, 0)
    self.lockT = s.lockT ~= nil and ns.Store.Num(s.lockT, 0, LOCK_DELAY, LOCK_DELAY) or nil
    self.phase = (s.phase == "over") and "over" or "play"
    self.phaseT = ns.Store.Num(s.phaseT, 0, OVER_PAUSE, 0)
    if s.rng then self.rng = ns.RNG.Restore(s.rng) end
    self.cur = nil
    local kind = tonumber(s.kind)
    if kind and kind >= 1 and kind <= 7 then
        kind = floor(kind)
        local rot = floor(ns.Store.Num(s.rot, 0, 3, 0)) % 4
        local minX, maxX = spanX(kind, rot)
        local piece = {
            kind = kind,
            rot = rot,
            x = floor(ns.Store.Num(s.x, -minX, COLS - 1 - maxX, floor((COLS - maxX - minX - 1) / 2))),
            y = floor(ns.Store.Num(s.y, 0, ROWS - 1, 0)),
        }
        if not self:Collides(piece) then self.cur = piece end
    end
    if not self.cur and self.phase == "play" then self:Spawn() end
    self:Relevel()
end
local MINI_WELL = { 0.055, 0.067, 0.098 }
local MINI_FULL = { 0.30, 0.30, 0.34 }
local MINI_WALL = { 0.16, 0.19, 0.27 }
local MINI_WARN = { 1.00, 0.82, 0.00 }
local MINI_PIVOT = { 0.20, 0.23, 0.28 }
local MINI_I = { 0.373, 0.690, 0.878 }
local MINI_S = { 0.541, 0.831, 0.435 }
local MINI_T = { 0.690, 0.435, 0.831 }
local MINI_BEFORE = { 0.690, 0.435, 0.831, 0.35 }
local MINI_AFTER = { 0.690, 0.435, 0.831, 1 }
local MINI = {
    {
        cols = 6, rows = 5, cell = 20, gap = 1, back = "plain",
        fill = {
            { c = 1, r = 1, col = MINI_FULL }, { c = 2, r = 1, col = MINI_FULL },
            { c = 3, r = 1, col = MINI_FULL }, { c = 4, r = 1, col = MINI_FULL },
            { c = 5, r = 1, col = MINI_FULL }, { c = 6, r = 1, col = MINI_FULL },
            { c = 2, r = 2, col = MINI_S }, { c = 2, r = 3, col = MINI_S },
            { c = 5, r = 2, col = MINI_I },
        },
        ring = {
            { c = 1, r = 1 }, { c = 2, r = 1 }, { c = 3, r = 1 },
            { c = 4, r = 1 }, { c = 5, r = 1 }, { c = 6, r = 1 },
        },
        arrow = {
            { c1 = 2, r1 = 3, c2 = 2, r2 = 2, col = MINI_S },
            { c1 = 2, r1 = 2, c2 = 2, r2 = 1, col = MINI_S },
            { c1 = 5, r1 = 2, c2 = 5, r2 = 1, col = MINI_I },
        },
    },
    {
        cols = 3, rows = 3, cell = 30, gap = 1, back = "plain",
        fill = {
            { c = 2, r = 2, col = MINI_PIVOT },
            { c = 1, r = 2, col = MINI_BEFORE }, { c = 2, r = 1, col = MINI_BEFORE },
            { c = 2, r = 3, col = MINI_AFTER }, { c = 3, r = 2, col = MINI_AFTER },
        },
        ring = { { c = 2, r = 2 } },
        arrow = {
            { c1 = 1, r1 = 2, c2 = 2, r2 = 3, col = MINI_T },
            { c1 = 2, r1 = 1, c2 = 3, r2 = 2, col = MINI_T },
        },
    },
    {
        cols = 5, rows = 4, cell = 20, gap = 1, back = "plain",
        fill = {
            { c = 5, r = 1, col = MINI_WALL }, { c = 5, r = 2, col = MINI_WALL },
            { c = 5, r = 3, col = MINI_WALL }, { c = 5, r = 4, col = MINI_WALL },
            { c = 4, r = 1, col = MINI_I }, { c = 4, r = 2, col = MINI_I },
            { c = 4, r = 3, col = MINI_I }, { c = 4, r = 4, col = MINI_I },
        },
        dot = { { c = 5, r = 2, col = MINI_WARN } },
        arrow = { { c1 = 5, r1 = 2, c2 = 4, r2 = 2, col = MINI_I } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_WELL)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r, m.alpha) end
    for _, m in ipairs(spec.dot or {}) do g:Dot(m.c, m.r, m.col, m.frac) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpClear(host) paintMini(host, MINI[1]) end
local function helpRotate(host) paintMini(host, MINI[2]) end
local function helpKick(host) paintMini(host, MINI[3]) end
ns.RegisterGame{
    id = ID,
    label = "tetris.label",
    icon = { draw = ns.TetrisTileIcon },
    tip = "tetris.tip",
    order = 9,
    duo = "none",
    look = LOOK,
    physics = true,
    ownPanel = true,
    fx = true,
    done = true,
    New = New,
    opts = {
        { key = "diff", label = "tetris.optDiffLabel", def = DEF_DIFF,
          options = TUNE, tip = "tetris.optDiffTip" },
    },
    controls = {
        { action = "up",   label = "tetris.ctlRotate", mouse = "RMB" },
        { action = "down", label = "tetris.ctlSoft",   mouse = "LMB" },
        { action = "fire", label = "tetris.ctlDrop" },
    },
    help = {
        "tetris.help1",
        "tetris.help2",
        { art = helpClear, h = 112 },
        "tetris.help3",
        { art = helpRotate, h = 100, sub = "tetris.helpRotateSub" },
        "tetris.help4",
        { art = helpKick, h = 91 },
        "tetris.help5",
        "tetris.help6",
        { icon = TILE_TEX, coord = TILE_COORD,
          t = "tetris.help7" },
        "tetris.help7Sub",
        { icon = TILE_TEX, coord = TILE_COORD,
          t = "tetris.help8" },
        "tetris.help9",
        "tetris.help10",
    },
}
