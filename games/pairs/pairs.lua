local ADDON, ns = ...
local ID = "pairs"
local GAP        = 3
local BORDER     = 2
local FLIP_DELAY = 0.8
local POP_TIME   = 0.4
local SOCKET_DIM = 0
local RUSH_TIME = 120
local RUSH_WARN = 15
local TRY_PAIR   = 1.58
local TRY_TRIPLE = 2.07
local TRY_SLACK  = 0.9
local TRY_WARN   = 3
local PEEK_BASE = 2
local PEEK_PER  = 0.06
local BACK_TINT = { 0.55, 0.55, 0.55 }
local PAD_X = 12
local PAD_Y = 10
local MID   = 12
local COL_W = 146
local ROW   = 22
local ROWS  = 6
local BAR_H = 4
local M_PAD    = 16
local CAP_TOP  = 14
local TILE_W, TILE_H, TILE_GAP = 146, 104, 8
local TILE_TOP = 31
local SEAM1    = 147
local BAND_CAP = 162
local BAND_TOP = 176
local SAMPLE_W, SAMPLE_H = 388, 208
local SAMPLE_MIN = 12
local SAMPLE_GAP = 0
local SAMPLE_SETS = 4
local SEAM_X = 412
local PICK_X, PICK_W = 420, 204
local SIZE_TOP, SIZE_H, SIZE_STEP = 176, 30, 36
local COP_CAP, COP_TOP, COP_H = 290, 304, 30
local THEME_CAP, THEME_TOP = 346, 360
local CTRL_H = 24
local SEAM2 = 394
local PLAY_TOP, PLAY_W, PLAY_H = 408, 220, 44
local PLAY_X, CALL_X = 94, 326
local NOTE_TOP = 458
local TEX_HIDE = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local C_HIDE     = { 0.150, 0.112, 0.070 }
local C_SEAM     = { 0.52, 0.42, 0.26 }
local C_PLATE    = { 0.115, 0.086, 0.055 }
local C_PLATE_ON = { 0.215, 0.165, 0.090 }
local C_EDGE     = { 0.30, 0.24, 0.15 }
local C_EDGE_HOT = { 0.52, 0.42, 0.24 }
local C_GOLD     = { 1, 0.82, 0 }
local C_SOFT     = { 0.72, 0.64, 0.50 }
local C_DIM      = { 0.52, 0.47, 0.38 }
local C_WARN     = { 1, 0.35, 0.30 }
local C_LIVE     = { 0.44, 0.75, 0.36 }
local C_VAL      = { 0.94, 0.90, 0.82 }
local C_DARK     = { 0.06, 0.045, 0.03 }
local C_NONE     = { 0, 0, 0, 0 }
local LOOK = ns.MakeLook{ wood = C_HIDE, edge = C_GOLD, screen = C_HIDE }
local VAL_FONT = "Fonts\\FRIZQT__.TTF"
local FLASH_GROW = 0.6
local GHOST_GROW = 0.45
local GHOST_RISE = 0.55
local MODES = {
    { key = "classic", label = "pairs.modeClassicLabel",
      tip = "pairs.modeClassicTip" },
    { key = "moves", label = "pairs.modeMovesLabel",
      tip = "pairs.modeMovesTip" },
    { key = "rush", label = "pairs.modeRushLabel",
      tip = "pairs.modeRushTip" },
    { key = "peek", label = "pairs.modePeekLabel",
      tip = "pairs.modePeekTip" },
}
local COPIES = {
    { key = "2", n = 2, label = "pairs.copies2Label", tip = "pairs.copies2Tip" },
    { key = "3", n = 3, label = "pairs.copies3Label",
      tip = "pairs.copies3Tip" },
}
local SIZES = {
    ["2"] = {
        { key = "4x4", cols = 4, rows = 4, tip = "pairs.sizePair4x4Tip" },
        { key = "6x6", cols = 6, rows = 6, tip = "pairs.sizePair6x6Tip" },
        { key = "8x8", cols = 8, rows = 8, tip = "pairs.sizePair8x8Tip" },
    },
    ["3"] = {
        { key = "6x6", cols = 6, rows = 6, tip = "pairs.sizeTriple6x6Tip" },
        { key = "9x9", cols = 9, rows = 9, tip = "pairs.sizeTriple9x9Tip" },
    },
}
local DEF_MODE, DEF_SIZE, DEF_COPIES = "classic", "6x6", "2"
local DUO_MODES = { classic = true, peek = true }
local TIME_MODES = { classic = true, peek = true }
local pool, hl, deco, field, ui, menu, current
local ensureView, layoutCol
local preDeck, preKeep
local Game = {}
Game.__index = Game
local function byKey(list, key, def)
    for _, it in ipairs(list) do
        if it.key == key then return it end
    end
    for _, it in ipairs(list) do
        if it.key == def then return it end
    end
    return list[1]
end
local function sizeOf(copies, key)
    return byKey(SIZES[copies] or SIZES[DEF_COPIES], key, DEF_SIZE)
end
local function pickFaces(n, pick)
    local seen, out = {}, {}
    local function take(tex)
        if tex and tex ~= ns.Icons.QMARK and not seen[tex] then
            seen[tex] = true
            out[#out + 1] = tex
        end
    end
    local shelf = ns.Shelves.Get(ID, "face")
    local bag = {}
    for i = 1, #shelf do bag[i] = shelf[i] end
    pick:Shuffle(bag)
    for i = 1, #bag do
        if #out >= n then break end
        take(ns.IconPath(bag[i]))
    end
    if #out < n then
        local raw = ns.Icons.Set("items", n * 2)
        for i = 1, #raw do
            if #out >= n then break end
            take(raw[i])
        end
    end
    local numbered = {}
    while #out < n do
        out[#out + 1] = ns.Icons.QMARK
        numbered[#out] = true
    end
    return out, numbered
end
function Game:Layout()
    local canvas = self.canvas
    local cols, rows = self.size.cols, self.size.rows
    local availW = canvas.W - PAD_X * 2 - MID - COL_W
    local availH = canvas.H - PAD_Y * 2
    local byW = ns.CellFit(cols, availW, GAP, 0)
    local byH = ns.CellFit(rows, availH, GAP, 0)
    local cell = byW < byH and byW or byH
    local top = ns.Config.ICON_MAX + BORDER * 2
    if cell > top then cell = top end
    self.cell = cell
    local fieldW = cols * cell + (cols - 1) * GAP
    local fieldH = rows * cell + (rows - 1) * GAP
    self.ox = PAD_X + math.floor((availW - fieldW) / 2)
    self.oy = math.floor((canvas.H - fieldH) / 2)
end
function Game:CellXY(i)
    local cols = self.size.cols
    local row = math.floor((i - 1) / cols) + 1
    local col = (i - 1) % cols + 1
    local step = self.cell + GAP
    return self.ox + (col - 1) * step,
           self.oy + (self.size.rows - row) * step
end
function Game:CellAt(x, y)
    local step = self.cell + GAP
    local dx = x - self.ox
    local col = math.floor(dx / step) + 1
    if col < 1 or col > self.size.cols then return nil end
    if dx - (col - 1) * step > self.cell then return nil end
    local dy = y - self.oy
    local up = math.floor(dy / step) + 1
    if up < 1 or up > self.size.rows then return nil end
    if dy - (up - 1) * step > self.cell then return nil end
    local row = self.size.rows - up + 1
    return (row - 1) * self.size.cols + col
end
local function isUp(self, i)
    for k = 1, #self.up do
        if self.up[k] == i then return true end
    end
    return false
end
local function deal(self)
    local face = {}
    for k = 1, self.sets do
        for _ = 1, self.copies do face[#face + 1] = k end
    end
    self.rng:Shuffle(face)
    self.face = face
    self.open = {}
    self.up = {}
    self.flipAt = nil
    self.left = self.sets
end
local function apply(self, move, replay)
    if not move then return false end
    if move.k == "next" then
        if self.mode.key ~= "rush" or self.left > 0 then return false end
        self.round = self.round + 1
        deal(self)
        return true
    end
    if move.k ~= "open" then return false end
    local i = move.i
    if type(i) ~= "number" or not self.face[i] then return false end
    if self.open[i] then return false end
    if isUp(self, i) then return false end
    if self.flipAt then
        self.up = {}
        self.flipAt = nil
    end
    self.up[#self.up + 1] = i
    self.started = true
    local same = true
    for k = 2, #self.up do
        if self.face[self.up[k]] ~= self.face[self.up[1]] then same = false break end
    end
    if not same then
        self.tries = self.tries + 1
        if replay then self.up = {} else self.flipAt = self.t + FLIP_DELAY end
        return true
    end
    if #self.up < self.copies then return true end
    local who = self:Turn()
    self.tries = self.tries + 1
    for k = 1, self.copies do self.open[self.up[k]] = true end
    self.found = self.found + 1
    self.by[who] = self.by[who] + 1
    self.left = self.left - 1
    self.up = {}
    return true
end
local function overNow(self)
    if self.mode.key == "rush" then return self.t >= RUSH_TIME end
    if self.mode.key == "moves" then return self.left <= 0 or self.tries >= self.limit end
    return self.left <= 0
end
local function sayOver(self)
    if self.overSaid or not overNow(self) then return false end
    self.overSaid = true
    ns.Sfx.Play("over")
    return true
end
local function sayVerdict(self)
    local kind = self.say
    if not kind then
        sayOver(self)
        return
    end
    if self.cards and ns.FlipBusy(self.cards[self.sayCard]) then return end
    self.say, self.sayCard = nil, nil
    if sayOver(self) then return end
    if kind == "miss" then
        ns.Sfx.Play("deny")
    else
        ns.Sfx.Play(self.left <= 0 and "clear" or "pop")
    end
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    if preKeep then preKeep = nil else preDeck = nil end
    ensureView(self.canvas)
    self.mode = byKey(MODES, self.opts and self.opts.mode, DEF_MODE)
    self.copiesDef = byKey(COPIES, self.opts and self.opts.copies, DEF_COPIES)
    self.copies = self.copiesDef.n
    self.size = sizeOf(self.copiesDef.key, self.opts and self.opts.size)
    self.opts = {
        mode = self.mode.key, size = self.size.key, copies = self.copiesDef.key,
    }
    self.cells = self.size.cols * self.size.rows
    self.sets = math.floor(self.cells / self.copies)
    local per = (self.copies > 2) and TRY_TRIPLE or TRY_PAIR
    self.limit = math.ceil(self.sets * per + TRY_SLACK * math.sqrt(self.sets))
    self.rng = ns.RNG.New(seed)
    local pick = ns.RNG.New(seed)
    self.faces, self.numbered = pickFaces(self.sets, pick)
    self.back = ns.IconPath(ns.Shelves.Pick(ID, "back", pick))
    self.round = 1
    deal(self)
    self.found, self.tries = 0, 0
    self.by = { 0, 0 }
    self.t = 0
    self.started = false
    self.hover = nil
    self.peekUntil = nil
    self.say, self.sayCard = nil, nil
    self.pop = {}
    self.gone = {}
    self.cards = nil
    self:Layout()
    self.menu = not (moves and #moves > 0)
    if not ns.Duo.Active() then ns.Duo.Adopt(ID) end
    if not (moves and #moves > 0) and ns.Duo.Held() then ns.Duo.GoSolo() end
    self.wasDuo = ns.Duo.Active() or ns.Duo.Held()
    self.duoPeer = (ns.Duo.Active() or ns.Duo.Held()) and ns.Duo.Peer() or nil
    self.side = ns.Duo.Side() or 1
    if self.duoPeer then
        self.menu = false
        self.autoPeek = (self.mode.key == "peek") and not (moves and #moves > 0)
    end
    current = self
    self.best = ns.Records.Best(ID, self.opts)
    layoutCol(self)
    local me = self
    ui.back.onClick = function() me:ToMenu() end
    if moves and #moves > 0 then
        for i = 1, #moves do apply(self, moves[i], true) end
        local rec = ns.Store.Load(ID)
        self.t = (rec and rec.elapsed) or 0
        self.started = true
        local bad = false
        for k = 2, #self.up do
            if self.face[self.up[k]] ~= self.face[self.up[1]] then bad = true break end
        end
        if bad then self.flipAt = self.t + FLIP_DELAY end
    end
    self.overSaid = overNow(self)
    self.instant = true
    self:Draw()
    self.instant = nil
end
function Game:Move(move)
    local found = self.found
    local took = apply(self, move)
    if not took then return false end
    if move.k == "open" then
        ns.Sfx.Play("pick")
        if self.found > found then
            self.say = "set"
        elseif self.flipAt then
            self.say = "miss"
        else
            self.say = nil
        end
        self.sayCard = self.say and move.i or nil
    end
    self:Draw()
    return true
end
function Game:Click(x, y)
    if self.menu or self.peekUntil then return end
    if ns.Duo.Held() then return end
    local i = self:CellAt(x, y)
    if not i then return end
    if self.open[i] then return end
    if isUp(self, i) then return end
    self:Move{ k = "open", i = i }
end
function Game:Update(dt)
    if self.menu then return end
    if self.autoPeek then
        self.autoPeek = nil
        self:Peek()
    end
    if self.duoPeer and not (ns.Duo.Active() or ns.Duo.Held()) then
        self.duoPeer = nil
        layoutCol(self)
    end
    if self.started then
        self.t = self.t + dt
        if self.peekUntil and self.t >= self.peekUntil then
            self.peekUntil = nil
            self:Draw()
        end
        if self.flipAt and self.t >= self.flipAt then
            self.flipAt = nil
            self.up = {}
            self:Draw()
        end
        if self.mode.key == "rush" and self.left <= 0 and not self:Busy() then
            self:Move{ k = "next" }
        end
        self:Animate()
        sayVerdict(self)
    end
    self:Hover()
end
function Game:Clock()
    if self.mode.key == "rush" then
        local left = RUSH_TIME - self.t
        return ns.Records.Span(left), left <= RUSH_WARN
    end
    if self.mode.key == "moves" then
        local left = self.limit - self.tries
        if left < 0 then left = 0 end
        return tostring(left), left <= TRY_WARN
    end
    return ns.Records.Span(self.t)
end
function Game:Marks()
    return { time = self.t, sets = self.found }
end
function Game:Turn()
    return ((self.tries - self.found) % 2) + 1
end
function Game:ResultText()
    if self.duoPeer then
        local a, b = self.by[self.side], self.by[3 - self.side]
        if a > b then return ns.T("pairs.resultWin", a, b) end
        if a < b then return ns.T("pairs.resultLose", a, b) end
        return ns.T("pairs.resultDraw", a)
    end
    if TIME_MODES[self.mode.key] then
        return ns.T("pairs.resultTime", ns.Records.Span(self.t))
    end
    return ns.T("pairs.resultSets", self.found, self.sets)
end
function Game:Ranked()
    if self.wasDuo then return ns.T("pairs.unrankedDuo") end
    return true
end
function Game:Score()
    return 0
end
function Game:Busy()
    if not self.cards then return false end
    for i = 1, self.cells do
        if self.pop[i] then return true end
        if ns.FlipBusy(self.cards[i]) then return true end
    end
    return false
end
function Game:IsOver()
    if self.menu then return false end
    if not overNow(self) then return false end
    return not self:Busy()
end
function Game:Stop()
    if pool then pool:HideAll() end
    if hl then hl:Hide() end
    if field then field:Hide() end
    if ui then ui.root:Hide() end
    if menu then menu.root:Hide() end
    if deco then deco:Hide() end
    ns.CallPanel.Hide()
    if current == self then current = nil end
    self.cards = nil
end
function Game:Peek()
    if self.mode.key ~= "peek" or self.started then return end
    if ns.Loop.Current() ~= self then return end
    self.started = true
    self.peekUntil = self.t + PEEK_BASE + self.cells * PEEK_PER
    self:Draw()
end
function Game:Locked()
    return self.started and true or false
end
local function makeCard(canvas)
    local c = ns.MakeFlip(canvas, "slot")
    c:EnableMouse(false)
    c.fx = ns.NewFrame("Frame", nil, c)
    c.fx:SetAllPoints(c)
    c.fx:SetFrameLevel(c:GetFrameLevel() + 2)
    c.fx.flash = c.fx:CreateTexture(nil, "ARTWORK")
    c.fx.flash:SetTexture(ns.CELL_HL)
    c.fx.flash:SetBlendMode("ADD")
    c.fx.ghost = c.fx:CreateTexture(nil, "OVERLAY")
    c.fx.ghost:SetTexCoord(0, 1, 0, 1)
    c.fx:Hide()
    return c
end
local function resetCard(c)
    ns.FlipReset(c)
    c.fx:Hide()
end
local function socket(c)
    c.icon:SetTexture(nil)
    c.icon:SetAlpha(1)
    ns.CellCenter(c, nil)
    c.fx:Hide()
    ns.CellDim(c, SOCKET_DIM)
end
local function showPop(self, c, i, p)
    local art = ns.FlipArt(c)
    local tex = self.faces[self.face[i]]
    local fade = 1 - p * 3
    if fade < 0 then fade = 0 end
    c.icon:SetAlpha(fade)
    ns.CellCenter(c, nil)
    local flash = (p < 0.25) and (p / 0.25) or ((1 - p) / 0.75)
    local fs = art * (1 + FLASH_GROW * p)
    c.fx.flash:SetAlpha(flash)
    ns.PlaceTex(c.fx.flash, c.fx, fs, fs)
    local gs = art * (1 + GHOST_GROW * p)
    c.fx.ghost:SetTexture(tex)
    c.fx.ghost:SetAlpha(1 - p)
    ns.PlaceTex(c.fx.ghost, c.fx, gs, gs, art * GHOST_RISE * p)
    c.fx:Show()
    ns.CellDim(c, 1 - (1 - SOCKET_DIM) * p)
end
function Game:Build()
    pool = pool or ns.NewPool(function() return makeCard(field) end, resetCard)
    pool:Reset()
    self.cards = {}
    self.builtRound = self.round
    self.pop, self.gone = {}, {}
    for i = 1, self.cells do
        local c = pool:Acquire()
        ns.FlipSize(c, self.cell, BORDER)
        local face = self.face[i]
        ns.FlipFaces(c, self.back, self.faces[face], {
            text = self.numbered[face] and tostring(face) or nil,
            backColor = BACK_TINT,
        })
        ns.FlipSet(c, "back")
        c:ClearAllPoints()
        local x, y = self:CellXY(i)
        c:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", x, y)
        self.cards[i] = c
    end
    self.art = ns.FlipArt(self.cards[1])
    pool:HideExtras()
end
local function sync(self, instant)
    for i = 1, self.cells do
        local c = self.cards[i]
        if self.open[i] then
            if instant then
                ns.FlipSet(c, "face")
                self.pop[i] = nil
                self.gone[i] = true
                socket(c)
            elseif not self.gone[i] and not self.pop[i] then
                ns.FlipTo(c, "face", self.t)
                self.pop[i] = self.t + ns.FLIP_TIME
            end
        else
            local side = (self.peekUntil or isUp(self, i)) and "face" or "back"
            if instant then ns.FlipSet(c, side) else ns.FlipTo(c, side, self.t) end
        end
    end
end
function Game:Animate()
    if not self.cards then return end
    for i = 1, self.cells do
        local c = self.cards[i]
        ns.FlipStep(c, self.t)
        local t0 = self.pop[i]
        if t0 and self.t >= t0 then
            local p = (self.t - t0) / POP_TIME
            if p >= 1 then
                self.pop[i] = nil
                self.gone[i] = true
                socket(c)
            else
                showPop(self, c, i, p)
            end
        end
    end
end
function Game:Draw()
    deco:Show()
    if self.menu then
        field:Hide()
        ui.root:Hide()
        if hl then hl:Hide() end
        menu.root:Show()
        self:SyncMenu()
        return
    end
    menu.root:Hide()
    field:Show()
    ui.root:Show()
    if not self.cards or self.builtRound ~= self.round then self:Build() end
    sync(self, self.instant)
end
function Game:Hover()
    local canvas = self.canvas
    if not hl then
        hl = ns.NewFrame("Frame", nil, field)
        hl:SetFrameLevel(field:GetFrameLevel() + 5)
        hl.tex = hl:CreateTexture(nil, "OVERLAY")
        hl.tex:SetAllPoints(hl)
        hl.tex:SetTexture(ns.CELL_HL)
        hl.tex:SetBlendMode("ADD")
        hl:Hide()
    end
    local i
    if not ns.Help.IsShown() and ns.Duo.MyTurn() then
        local left, bottom = canvas:GetLeft(), canvas:GetBottom()
        local scale = canvas:GetEffectiveScale()
        if left and bottom and scale and scale > 0 then
            local mx, my = GetCursorPosition()
            i = self:CellAt(mx / scale - left, my / scale - bottom)
        end
    end
    if i == self.hover then return end
    self.hover = i
    if not i or self.open[i] then
        hl:Hide()
        return
    end
    local art = self.art or self.cell
    local off = math.floor((self.cell - art) / 2)
    local x, y = self:CellXY(i)
    hl:ClearAllPoints()
    hl:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", x + off, y + off)
    hl:SetWidth(art)
    hl:SetHeight(art)
    hl:Show()
end
local function bigFont(fs, size)
    ns.SetFont(fs, VAL_FONT, size, "")
end
local function makePlate(parent, kind)
    local f = ns.NewFrame(kind or "Frame", nil, parent)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.line = {}
    for i = 1, 4 do f.line[i] = f:CreateTexture(nil, "BORDER") end
    f.line[1]:SetPoint("TOPLEFT");     f.line[1]:SetPoint("TOPRIGHT");     f.line[1]:SetHeight(1)
    f.line[2]:SetPoint("BOTTOMLEFT");  f.line[2]:SetPoint("BOTTOMRIGHT");  f.line[2]:SetHeight(1)
    f.line[3]:SetPoint("TOPLEFT");     f.line[3]:SetPoint("BOTTOMLEFT");   f.line[3]:SetWidth(1)
    f.line[4]:SetPoint("TOPRIGHT");    f.line[4]:SetPoint("BOTTOMRIGHT");  f.line[4]:SetWidth(1)
    return f
end
local function paintPlate(f, bg, edge)
    ns.Paint(f.bg, bg[1], bg[2], bg[3], bg[4] or 1)
    for i = 1, 4 do ns.Paint(f.line[i], edge[1], edge[2], edge[3], edge[4] or 1) end
end
local function makeCap(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    fs:SetText(text)
    fs:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    return fs
end
local function makeSeam(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    ns.Paint(t, C_SEAM[1], C_SEAM[2], C_SEAM[3], 0.45)
    return t
end
local COL_CAPS = {
    best  = "pairs.bestCap",
    mine  = "pairs.youCap",
    sets  = "pairs.setsCap",
    tries = "pairs.triesCap",
    acc   = "pairs.accCap",
    round = "pairs.roundCap",
    found = "pairs.foundCap",
    miss  = "pairs.missCap",
    peek  = "pairs.peekCap",
}
local function buildCol(canvas)
    ui = {}
    ui.root = ns.NewFrame("Frame", nil, canvas)
    ui.root:SetFrameLevel(canvas:GetFrameLevel() + 3)
    ui.root:SetAllPoints(canvas)
    ui.root:Hide()
    ui.seam = makeSeam(ui.root)
    ui.seam:SetWidth(1)
    ui.seam:SetPoint("TOP", ui.root, "TOPRIGHT", -(PAD_X + COL_W + MID / 2), -PAD_Y)
    ui.seam:SetPoint("BOTTOM", ui.root, "BOTTOMRIGHT", -(PAD_X + COL_W + MID / 2), PAD_Y)
    ui.col = ns.NewFrame("Frame", nil, ui.root)
    ui.col:SetFrameLevel(ui.root:GetFrameLevel() + 1)
    ui.col:SetPoint("TOPRIGHT", ui.root, "TOPRIGHT", -PAD_X, -PAD_Y)
    ui.col:SetPoint("BOTTOMRIGHT", ui.root, "BOTTOMRIGHT", -PAD_X, PAD_Y)
    ui.col:SetWidth(COL_W)
    ui.tally = ns.MakeScoreboard(ui.col, COL_W)
    ui.tally:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, 0)
    ui.row = {}
    for i = 1, ROWS do
        local r = {}
        r.cap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.cap:SetJustifyH("LEFT")
        r.val = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bigFont(r.val, 16)
        r.val:SetJustifyH("RIGHT")
        r.cap:Hide()
        r.val:Hide()
        ui.row[i] = r
    end
    ui.rule = makeSeam(ui.col)
    ui.rule:SetHeight(1)
    ui.rule:Hide()
    ui.barBg = ui.col:CreateTexture(nil, "ARTWORK")
    ns.Paint(ui.barBg, C_DARK[1], C_DARK[2], C_DARK[3], 1)
    ui.barBg:SetWidth(COL_W)
    ui.barBg:SetHeight(BAR_H)
    ui.barBg:Hide()
    ui.bar = ui.col:CreateTexture(nil, "OVERLAY")
    ns.Paint(ui.bar, C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.85)
    ui.bar:SetHeight(BAR_H)
    ui.bar:SetWidth(1)
    ui.bar:SetPoint("TOPLEFT", ui.barBg, "TOPLEFT", 0, 0)
    ui.bar:Hide()
    ui.back = ns.MakeKitButton(ui.col)
    ui.back:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, 0)
    ui.back:SetWidth(COL_W)
    ui.back:SetHeight(ROW)
    ui.back:SetText(ns.T("pairs.toMenu"))
    ui.back.tip = ns.T("pairs.toMenuTip")
    ui.set = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.set:SetPoint("BOTTOMLEFT", ui.back, "TOPLEFT", 0, 8)
    ui.set:SetWidth(COL_W)
    ui.set:SetJustifyH("LEFT")
    ui.set:SetTextColor(C_VAL[1], C_VAL[2], C_VAL[3])
end
local function buildMenu(canvas)
    local m = {}
    m.root = ns.NewFrame("Frame", nil, canvas)
    m.root:SetFrameLevel(canvas:GetFrameLevel() + 6)
    m.root:SetAllPoints(canvas)
    m.root:Hide()
    m.modeCap = makeCap(m.root, M_PAD, CAP_TOP, ns.T("pairs.optModeLabel"))
    m.mode = {}
    for i = 1, #MODES do
        local t = makePlate(m.root, "Button")
        t:SetFrameLevel(m.root:GetFrameLevel() + 1)
        t:SetWidth(TILE_W)
        t:SetHeight(TILE_H)
        t:SetPoint("TOPLEFT", m.root, "TOPLEFT",
                   M_PAD + (i - 1) * (TILE_W + TILE_GAP), -TILE_TOP)
        t.title = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t.title:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -11)
        t.title:SetText(ns.TL(MODES[i].label))
        t.desc = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.desc:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -34)
        t.desc:SetWidth(TILE_W - 24)
        t.desc:SetJustifyH("LEFT")
        t.desc:SetJustifyV("TOP")
        t.desc:SetText(ns.TL(MODES[i].tip))
        t.rec = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.rec:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 12, 9)
        if DUO_MODES[MODES[i].key] then
            t.duo = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            t.duo:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -10, 9)
            t.duo:SetText(ns.T("pairs.menuDuoTag"))
        end
        t:SetScript("OnEnter", function(self) self.hot = true; if m.paint then m.paint() end end)
        t:SetScript("OnLeave", function(self) self.hot = nil; if m.paint then m.paint() end end)
        t:SetScript("OnClick", function()
            if m.onMode then ns.Sfx.Ui(); m.onMode(MODES[i].key) end
        end)
        m.mode[i] = t
    end
    m.paint = function()
        for i = 1, #m.mode do
            local t = m.mode[i]
            local on = (MODES[i].key == m.modeKey)
            paintPlate(t, on and C_PLATE_ON or C_PLATE,
                          on and C_GOLD or (t.hot and C_EDGE_HOT or C_EDGE))
            local c = on and C_GOLD or C_VAL
            t.title:SetTextColor(c[1], c[2], c[3])
            c = on and C_SOFT or C_DIM
            t.desc:SetTextColor(c[1], c[2], c[3])
            t.rec:SetTextColor(c[1], c[2], c[3])
            if t.duo then t.duo:SetTextColor(c[1], c[2], c[3]) end
        end
    end
    m.seam1 = makeSeam(m.root)
    m.seam1:SetHeight(1)
    m.seam1:SetPoint("TOPLEFT", m.root, "TOPLEFT", M_PAD, -SEAM1)
    m.seam1:SetPoint("TOPRIGHT", m.root, "TOPRIGHT", -M_PAD, -SEAM1)
    m.seam2 = makeSeam(m.root)
    m.seam2:SetHeight(1)
    m.seam2:SetPoint("TOPLEFT", m.root, "TOPLEFT", M_PAD, -SEAM2)
    m.seam2:SetPoint("TOPRIGHT", m.root, "TOPRIGHT", -M_PAD, -SEAM2)
    m.seamV = makeSeam(m.root)
    m.seamV:SetWidth(1)
    m.seamV:SetPoint("TOP", m.root, "TOPLEFT", SEAM_X, -(SEAM1 + 16))
    m.seamV:SetPoint("BOTTOM", m.root, "TOPLEFT", SEAM_X, -(SEAM2 - 10))
    m.setCap = makeCap(m.root, M_PAD, BAND_CAP, "")
    m.sample = {}
    m.layout = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.layout:SetPoint("TOPRIGHT", m.root, "TOPLEFT", M_PAD + SAMPLE_W, -BAND_CAP)
    m.layout:SetJustifyH("RIGHT")
    m.layout:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    m.sizeCap = makeCap(m.root, PICK_X, BAND_CAP, ns.T("pairs.optSizeLabel"))
    m.size = {}
    for i = 1, 3 do
        local r = makePlate(m.root, "Button")
        r:SetFrameLevel(m.root:GetFrameLevel() + 1)
        r:SetWidth(PICK_W)
        r:SetHeight(SIZE_H)
        r:SetPoint("TOPLEFT", m.root, "TOPLEFT", PICK_X, -(SIZE_TOP + (i - 1) * SIZE_STEP))
        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.name:SetPoint("LEFT", r, "LEFT", 10, 0)
        r.score = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bigFont(r.score, 15)
        r.score:SetJustifyH("RIGHT")
        r.score:SetPoint("RIGHT", r, "RIGHT", -10, 0)
        r:SetScript("OnEnter", function(self)
            self.hot = true
            if m.paintPick then m.paintPick() end
            ns.TipShow(self)
        end)
        r:SetScript("OnLeave", function(self)
            self.hot = nil
            if m.paintPick then m.paintPick() end
            ns.TipHide()
        end)
        r:SetScript("OnClick", function(self)
            if m.onSize and self.key then ns.Sfx.Ui(); m.onSize(self.key) end
        end)
        m.size[i] = r
    end
    m.copiesCap = makeCap(m.root, PICK_X, COP_CAP, ns.T("pairs.optCopiesLabel"))
    m.copies = {}
    local copW = math.floor((PICK_W - TILE_GAP) / 2)
    for i = 1, #COPIES do
        local b = makePlate(m.root, "Button")
        b:SetFrameLevel(m.root:GetFrameLevel() + 1)
        b:SetWidth(copW)
        b:SetHeight(COP_H)
        b:SetPoint("TOPLEFT", m.root, "TOPLEFT",
                   PICK_X + (i - 1) * (copW + TILE_GAP), -COP_TOP)
        b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.name:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.name:SetText(ns.TL(COPIES[i].label))
        b.tipTitle = ns.TL(COPIES[i].label)
        b.tip = ns.TL(COPIES[i].tip)
        b:SetScript("OnEnter", function(self)
            self.hot = true
            if m.paintPick then m.paintPick() end
            ns.TipShow(self)
        end)
        b:SetScript("OnLeave", function(self)
            self.hot = nil
            if m.paintPick then m.paintPick() end
            ns.TipHide()
        end)
        b:SetScript("OnClick", function()
            if m.onCopies then ns.Sfx.Ui(); m.onCopies(COPIES[i].key) end
        end)
        m.copies[i] = b
    end
    m.paintPick = function()
        for i = 1, #m.size do
            local r = m.size[i]
            local on = (r.key ~= nil and r.key == m.sizeKey)
            paintPlate(r, on and C_PLATE_ON or C_NONE,
                          on and C_GOLD or (r.hot and C_EDGE_HOT or C_EDGE))
            local c = on and C_GOLD or C_VAL
            r.name:SetTextColor(c[1], c[2], c[3])
        end
        for i = 1, #m.copies do
            local b = m.copies[i]
            local on = (COPIES[i].key == m.copiesKey)
            paintPlate(b, on and C_PLATE_ON or C_NONE,
                          on and C_GOLD or (b.hot and C_EDGE_HOT or C_EDGE))
            local c = on and C_GOLD or C_VAL
            b.name:SetTextColor(c[1], c[2], c[3])
        end
    end
    m.themeCap = makeCap(m.root, PICK_X, THEME_CAP, ns.T("pairs.menuFaceCap"))
    m.theme = ns.MakeSelect(m.root)
    m.theme:SetFrameLevel(m.root:GetFrameLevel() + 3)
    m.theme:SetPoint("TOPLEFT", m.root, "TOPLEFT", PICK_X, -THEME_TOP)
    m.theme:SetWidth(PICK_W)
    m.theme:SetHeight(CTRL_H)
    m.theme.tip = ns.T("pairs.menuFaceTip")
    m.play = ns.MakeKitButton(m.root)
    m.play:SetFrameLevel(m.root:GetFrameLevel() + 2)
    m.play:SetWidth(PLAY_W)
    m.play:SetHeight(PLAY_H)
    m.play:SetPoint("TOPLEFT", m.root, "TOPLEFT", PLAY_X, -PLAY_TOP)
    m.play:SetText(ns.T("pairs.menuPlay"))
    bigFont(m.play.text, 16)
    m.call = ns.MakeKitButton(m.root)
    m.call:SetFrameLevel(m.root:GetFrameLevel() + 2)
    m.call:SetWidth(PLAY_W)
    m.call:SetHeight(PLAY_H)
    m.call:SetPoint("TOPLEFT", m.root, "TOPLEFT", CALL_X, -PLAY_TOP)
    m.call:SetText(ns.T("pairs.menuCall"))
    bigFont(m.call.text, 16)
    m.note = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.note:SetPoint("TOP", m.root, "TOP", 0, -NOTE_TOP)
    m.note:SetWidth(600)
    m.note:SetJustifyH("CENTER")
    m.lock = ns.NewFrame("Frame", nil, m.root)
    m.lock:SetFrameLevel(m.root:GetFrameLevel() + 5)
    m.lock:SetPoint("TOPLEFT", m.root, "TOPLEFT", 0, 0)
    m.lock:SetPoint("TOPRIGHT", m.root, "TOPRIGHT", 0, 0)
    m.lock:SetHeight(SEAM2)
    m.lock:EnableMouse(true)
    m.lock:Hide()
    m.setLock = function(on)
        local a = on and 0.42 or 1
        for i = 1, #m.mode do m.mode[i]:SetAlpha(a) end
        for i = 1, #m.size do m.size[i]:SetAlpha(a) end
        for i = 1, #m.copies do m.copies[i]:SetAlpha(a) end
        for i = 1, #m.sample do m.sample[i]:SetAlpha(a * (m.sample[i].fade or 1)) end
        m.theme:SetAlpha(a)
        if on then m.lock:Show() else m.lock:Hide() end
    end
    return m
end
function ensureView(canvas)
    if field then return end
    deco = ns.NewFrame("Frame", nil, canvas)
    deco:SetFrameLevel(canvas:GetFrameLevel())
    deco:SetAllPoints(canvas)
    local skin = ns.window:ScreenFill(deco)
    skin:SetTexture(TEX_HIDE)
    skin:SetVertexColor(C_HIDE[1], C_HIDE[2], C_HIDE[3], 1)
    field = ns.NewFrame("Frame", nil, canvas)
    field:SetFrameLevel(canvas:GetFrameLevel() + 1)
    field:SetAllPoints(canvas)
    field:Hide()
    buildCol(canvas)
    menu = buildMenu(canvas)
end
function Game:Restart(opts, keep)
    if self.started then return end
    if ns.Loop.Current() ~= self then return end
    preKeep = keep or nil
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, opts)
end
function Game:PickMode(key)
    if key == self.mode.key then return end
    ns.Sfx.Ui("tick")
    self:Restart({ mode = key, copies = self.copiesDef.key, size = self.size.key }, true)
end
function Game:PickCopies(key)
    if key == self.copiesDef.key then return end
    ns.Sfx.Ui("tick")
    self:Restart({ mode = self.mode.key, copies = key,
                   size = sizeOf(key, self.size.key).key }, true)
end
function Game:PickSize(key)
    if key == self.size.key then return end
    ns.Sfx.Ui("tick")
    self:Restart({ mode = self.mode.key, copies = self.copiesDef.key, size = key }, true)
end
function Game:BeginRound()
    if not self.menu then return end
    self.menu = false
    self:Draw()
    if self.mode.key == "peek" then self:Peek() end
end
function Game:ToMenu()
    if self.menu then return end
    if not self.started then
        self.menu = true
        self:Draw()
        return
    end
    ns.window:Restart()
end
local function previewDeck()
    local theme, stamp = ns.Shelves.Theme(ID), ns.Shelves.stamp
    if preDeck and preDeck.theme == theme and preDeck.stamp == stamp then
        return preDeck
    end
    local seed = math.floor(GetTime() * 1000)
    local roll = ns.RNG.New(seed)
    preDeck = {
        theme = theme, stamp = stamp, seed = seed,
        faces = pickFaces(SAMPLE_SETS, roll),
        back = ns.IconPath(ns.Shelves.Pick(ID, "back", roll)),
    }
    return preDeck
end
local function syncSample(self)
    local pre = previewDeck()
    local copies = self.copies
    local cols, rows = self.size.cols, self.size.rows
    local byW = math.floor((SAMPLE_W - (cols - 1) * SAMPLE_GAP) / cols)
    local byH = math.floor((SAMPLE_H - (rows - 1) * SAMPLE_GAP) / rows)
    local cell = byW < byH and byW or byH
    if cell > self.cell then cell = self.cell end
    if cell < SAMPLE_MIN then cell = SAMPLE_MIN end
    local step = cell + SAMPLE_GAP
    local gridW = cols * cell + (cols - 1) * SAMPLE_GAP
    local gridH = rows * cell + (rows - 1) * SAMPLE_GAP
    local x0 = M_PAD + math.floor((SAMPLE_W - gridW) / 2)
    local y0 = BAND_TOP
    if gridH < SAMPLE_H then y0 = y0 + math.floor((SAMPLE_H - gridH) / 2) end
    local n = cols * rows
    local shown = math.floor(n / copies)
    if shown > SAMPLE_SETS then shown = SAMPLE_SETS end
    local spot = {}
    for i = 1, n do spot[i] = i end
    ns.RNG.New(pre.seed):Shuffle(spot)
    local face = {}
    for s = 1, shown do
        for k = 1, copies do face[spot[(s - 1) * copies + k]] = s end
    end
    for i = 1, n do
        local top = math.floor((i - 1) / cols) * step
        local seen = SAMPLE_H - top
        if seen > cell then seen = cell end
        local c = menu.sample[i]
        if seen <= 0 then
            if c then c.fade = 0; c:Hide() end
        else
            if not c then
                c = makeCard(menu.root)
                c:SetFrameLevel(menu.root:GetFrameLevel() + 1)
                menu.sample[i] = c
            end
            c:Show()
            resetCard(c)
            ns.FlipSize(c, cell, BORDER)
            c.fade = seen / cell
            c:SetAlpha(c.fade)
            local f = face[i]
            ns.FlipFaces(c, pre.back, pre.faces[f or 1], { backColor = BACK_TINT })
            ns.FlipSet(c, f and "face" or "back")
            c:ClearAllPoints()
            c:SetPoint("TOPLEFT", menu.root, "TOPLEFT",
                       x0 + ((i - 1) % cols) * step, -(y0 + top))
        end
    end
    for i = n + 1, #menu.sample do
        menu.sample[i].fade = 0
        menu.sample[i]:Hide()
    end
    menu.setCap:SetText(ns.T(copies > 2 and "pairs.menuSetCapTriple"
                                         or "pairs.menuSetCapPair"))
end
local function bestText(mode, rec)
    if rec then
        if TIME_MODES[mode] then
            if rec.time then return ns.Records.Span(rec.time) end
        elseif rec.sets then
            return tostring(rec.sets)
        end
    end
    return ns.T("pairs.menuNoRec")
end
local function syncPick(self)
    local sizes = SIZES[self.copiesDef.key]
    for i = 1, #menu.size do
        local r = menu.size[i]
        local size = sizes[i]
        if not size then
            r.key = nil
            r:Hide()
        else
            r.key = size.key
            r.tipTitle = size.key
            r.tip = ns.TL(size.tip)
            r:Show()
            r.name:SetText(size.key)
            local best = ns.Records.Best(ID, { mode = self.mode.key,
                                               copies = self.copiesDef.key, size = size.key })
            r.score:SetText(bestText(self.mode.key, best))
            r.score:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
        end
    end
    for i = 1, #MODES do
        local best = ns.Records.Best(ID, { mode = MODES[i].key,
                                           copies = self.copiesDef.key, size = self.size.key })
        menu.mode[i].rec:SetText(ns.T("pairs.menuTileRecFmt",
            bestText(MODES[i].key, best)))
    end
    menu.sizeKey = self.size.key
    menu.copiesKey = self.copiesDef.key
    menu.paintPick()
end
local function syncTheme(self)
    local opts = {}
    for _, t in ipairs(ns.Shelves.Themes(ID)) do
        if ns.Shelves.Filled(ID, t.key) then
            opts[#opts + 1] = { key = t.key, label = t.label }
        end
    end
    if #opts < 2 then
        menu.themeCap:Hide()
        menu.theme:Hide()
        return
    end
    menu.themeCap:Show()
    menu.themeCap:SetText(ns.T("pairs.menuFaceCap"))
    menu.theme:Show()
    menu.theme:SetOptions(opts, ns.Shelves.Theme(ID), ns.T("pairs.menuFaceCap"))
    local me = self
    menu.theme.onPick = function(key)
        if key == ns.Shelves.Theme(ID) then return end
        ns.Shelves.SetTheme(ID, key)
        me:Restart{ mode = me.mode.key, copies = me.copiesDef.key, size = me.size.key }
    end
end
function Game:SyncMenu()
    local me = self
    menu.modeCap:SetText(ns.T("pairs.optModeLabel"))
    menu.sizeCap:SetText(ns.T("pairs.optSizeLabel"))
    menu.copiesCap:SetText(ns.T("pairs.optCopiesLabel"))
    for i = 1, #MODES do
        local t = menu.mode[i]
        t.title:SetText(ns.TL(MODES[i].label))
        t.desc:SetText(ns.TL(MODES[i].tip))
        if t.duo then t.duo:SetText(ns.T("pairs.menuDuoTag")) end
    end
    for i = 1, #COPIES do
        local b = menu.copies[i]
        b.name:SetText(ns.TL(COPIES[i].label))
        b.tipTitle = ns.TL(COPIES[i].label)
        b.tip = ns.TL(COPIES[i].tip)
    end
    menu.play:SetText(ns.T("pairs.menuPlay"))
    menu.modeKey = self.mode.key
    menu.paint()
    menu.onMode = function(key) me:PickMode(key) end
    menu.onSize = function(key) me:PickSize(key) end
    menu.onCopies = function(key) me:PickCopies(key) end
    syncSample(self)
    syncTheme(self)
    syncPick(self)
    menu.layout:SetText(ns.T(self.copies > 2 and "pairs.menuLayoutTripleFmt"
                                              or "pairs.menuLayoutPairFmt",
                             self.cells, self.sets))
    menu.play.onClick = function() me:BeginRound() end
    local waiting = ns.Duo.Waiting()
    local canDuo = DUO_MODES[self.mode.key] or false
    menu.setLock(waiting)
    if waiting then
        menu.play:Disable()
        menu.call:SetText(ns.T("duoCancel"))
        menu.call.tip = ns.T("duoCancelTip")
        menu.call.onClick = function() ns.Duo.Cancel() end
        menu.call:Enable()
        menu.note:SetText(ns.Duo.Status() or "")
        menu.note:SetTextColor(C_LIVE[1], C_LIVE[2], C_LIVE[3])
        return
    end
    menu.play:Enable()
    local mate = ns.Pair.Bound() and ns.Pair.Mate() or nil
    if mate then
        menu.call:SetText(ns.T("pairWith", mate))
        menu.call.tip = ns.T("pairWithTip")
        menu.call.onClick = function() ns.Pair.Play(ID, me.opts) end
    else
        menu.call:SetText(ns.T("pairs.menuCall"))
        menu.call.tip = ns.T("pairs.menuCallTip")
        menu.call.onClick = function()
            ns.CallPanel.Show(ns.window:Frame(), {
                pair = true, title = ns.T("pairCall"), autoHide = true,
            })
        end
    end
    if canDuo then menu.call:Enable() else menu.call:Disable() end
    if not canDuo then
        menu.note:SetText(ns.T("pairs.menuDuoModes"))
        menu.note:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    else
        menu.note:SetText(ns.Duo.Status() or "")
        menu.note:SetTextColor(C_WARN[1], C_WARN[2], C_WARN[3])
    end
end
local function syncIfMenu()
    if current and current.menu and menu and ns.Loop.Current() == current then
        current:SyncMenu()
    end
end
ns.Duo.OnChange(syncIfMenu)
ns.Pair.OnChange(syncIfMenu)
function layoutCol(self)
    if self.mode.key == "rush" then
        self.clockTip = nil
        self.clockCap = nil
    elseif self.mode.key == "moves" then
        self.clockTip = ns.T("pairs.clockTipMoves")
        self.clockCap = ns.T("pairs.clockCapMoves")
    else
        self.clockTip = nil
        self.clockCap = nil
    end
    local list
    if self.duoPeer then
        list = { "mine", "peer", "sets", "tries" }
    elseif self.mode.key == "rush" then
        list = { "best", "sets", "round", "found", "miss" }
    else
        list = { "best", "sets", "tries", "acc" }
    end
    if self.mode.key == "peek" then list[#list + 1] = "peek" end
    self.rows = list
    local y = ROW * 4 + 6
    ui.rule:Hide()
    ui.barBg:Hide()
    ui.bar:Hide()
    for i = 1, ROWS do
        local r, key = ui.row[i], list[i]
        if not key then
            r.cap:Hide()
            r.val:Hide()
        else
            r.cap:ClearAllPoints()
            r.cap:SetPoint("LEFT", ui.col, "TOPLEFT", 0, -(y + ROW / 2))
            r.cap:SetText(key == "peer" and (self.duoPeer or "") or ns.T(COL_CAPS[key]))
            r.cap:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
            r.cap:Show()
            r.val:ClearAllPoints()
            r.val:SetPoint("RIGHT", ui.col, "TOPRIGHT", 0, -(y + ROW / 2))
            r.val:Show()
            y = y + ROW
            if key == "best" then
                ui.rule:ClearAllPoints()
                ui.rule:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(y + 3))
                ui.rule:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -(y + 3))
                ui.rule:Show()
                y = y + 10
            elseif key == "sets" then
                ui.barBg:ClearAllPoints()
                ui.barBg:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
                ui.barBg:Show()
                ui.bar:Show()
                y = y + BAR_H + 8
            end
        end
    end
    ui.back:SetText(ns.T("pairs.toMenu"))
    ui.back.tip = ns.T("pairs.toMenuTip")
    ui.set:SetText(ns.Records.Label(self.def, self.opts))
    if self.duoPeer then ui.back:Disable() else ui.back:Enable() end
end
ns.OnLocale(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    layoutCol(game)
    game:Draw()
end)
function Game:PanelSync()
    if not ui then return end
    if self.menu then
        ui.tally:Hide()
        return
    end
    ui.tally:Show()
    ui.tally:Sync()
    local done = self.sets - self.left
    for i, key in ipairs(self.rows or {}) do
        local r = ui.row[i]
        local text, c = "", C_VAL
        if key == "best" then
            text = bestText(self.mode.key, self.best)
            c = C_SOFT
        elseif key == "mine" then
            text = tostring(self.by[self.side])
            c = C_GOLD
        elseif key == "peer" then
            text = tostring(self.by[3 - self.side])
        elseif key == "sets" then
            text = ns.T("pairs.setsFmt", done, self.sets)
            local w = math.floor(COL_W * done / self.sets)
            if w < 1 then
                ui.bar:Hide()
            else
                ui.bar:SetWidth(w)
                ui.bar:Show()
            end
        elseif key == "tries" then
            text = tostring(self.tries)
        elseif key == "acc" then
            text = (self.tries > 0)
                and ns.T("pairs.accFmt", math.floor(100 * self.found / self.tries + 0.5))
                or ns.T("pairs.menuNoRec")
        elseif key == "round" then
            text = tostring(self.round)
        elseif key == "found" then
            text = tostring(self.found)
        elseif key == "miss" then
            local miss = self.tries - self.found
            text = tostring(miss)
            if miss > 0 then c = C_WARN end
        elseif key == "peek" then
            if not self.peekUntil then
                r.cap:Hide()
                r.val:Hide()
            else
                r.cap:Show()
                r.val:Show()
                text = ns.T("pairs.peekFmt", math.ceil(self.peekUntil - self.t))
                c = C_GOLD
            end
        end
        r.val:SetText(text)
        r.val:SetTextColor(c[1], c[2], c[3])
    end
end
local MINI_BACK   = { 0.30, 0.24, 0.16, 1 }
local MINI_OPEN   = { 0.46, 0.40, 0.28, 1 }
local MINI_EMPTY  = { 0.150, 0.112, 0.070, 1 }
local MINI_ICON_A = { 1.00, 0.82, 0.20, 1 }
local MINI_ICON_B = { 0.45, 0.66, 0.86, 1 }
local MINI = {
    {
        cols = 4, rows = 1, cell = 40, gap = 4, back = "plain",
        fill = {
            { c = 2, r = 1, col = MINI_OPEN }, { c = 3, r = 1, col = MINI_OPEN },
            { c = 4, r = 1, col = MINI_EMPTY },
        },
        ring = { { c = 2, r = 1 }, { c = 3, r = 1 } },
        dot = { { c = 2, r = 1, col = MINI_ICON_A }, { c = 3, r = 1, col = MINI_ICON_A } },
    },
    {
        cols = 4, rows = 1, cell = 40, gap = 4, back = "plain",
        fill = { { c = 2, r = 1, col = MINI_OPEN }, { c = 3, r = 1, col = MINI_OPEN } },
        dot = { { c = 2, r = 1, col = MINI_ICON_A }, { c = 3, r = 1, col = MINI_ICON_B } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_BACK)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.dot or {}) do g:Dot(m.c, m.r, m.col) end
end
local function helpMatch(host) paintMini(host, MINI[1]) end
local function helpMiss(host) paintMini(host, MINI[2]) end
ns.RegisterGame{
    id = ID,
    label = "pairs.label",
    icon = { draw = ns.PairsTileIcon },
    tip = "pairs.tip",
    order = 2,
    duo = "turns",
    physics = false,
    look = LOOK,
    ownPanel = true,
    tally = false,
    done = true,
    New = New,
    opts = {
        { key = "mode", label = "pairs.optModeLabel", def = DEF_MODE, options = MODES,
          tip = "pairs.optModeTip" },
        { key = "copies", label = "pairs.optCopiesLabel", def = DEF_COPIES, ordered = true,
          options = COPIES, tip = "pairs.optCopiesTip" },
        { key = "size", label = "pairs.optSizeLabel", def = DEF_SIZE, ordered = true,
          options = function(sel) return SIZES[sel.copies] or SIZES[DEF_COPIES] end,
          tip = "pairs.optSizeTip" },
    },
    record = {
        { key = "sets", label = "pairs.recSets", by = "max", mark = "token" },
        { key = "time", label = "pairs.recTime", by = "min", mark = "clock", format = "span" },
    },
    mainMark = function(opts)
        local mode = byKey(MODES, opts and opts.mode, DEF_MODE)
        return TIME_MODES[mode.key] and "time" or "sets"
    end,
    controls = {
        { action = "flip", label = "pairs.ctlFlip", mouse = "LMB", where = "pairs.ctlOnCard" },
    },
    help = function(opts)
        local mode = byKey(MODES, opts and opts.mode, DEF_MODE)
        local cop = byKey(COPIES, opts and opts.copies, DEF_COPIES)
        local many = cop.n > 2
        local out = {
            many and ns.T("pairs.help1Triple") or ns.T("pairs.help1Pair"),
            { art = helpMatch, h = 48 },
            ns.T("pairs.helpMatchSub"),
            ns.T("pairs.help2"),
            { art = helpMiss, h = 48 },
            ns.T("pairs.helpMissSub"),
        }
        if mode.key == "rush" then
            out[#out + 1] = ns.T("pairs.helpRush")
        elseif mode.key == "moves" then
            out[#out + 1] = ns.T("pairs.helpMoves")
        elseif mode.key == "peek" then
            out[#out + 1] = ns.T("pairs.helpPeek")
        end
        out[#out + 1] = ns.T("pairs.helpFooter")
        return out
    end,
}
