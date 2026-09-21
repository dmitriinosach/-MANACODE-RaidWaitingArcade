local ADDON, ns = ...
local ID = "mines"
local G = ns.mines
local floor = math.floor
local SIZES = {
    { key = "9x9", cols = 9, rows = 9, mines = 10,
      tip = "mines.size9x9Tip" },
    { key = "16x16", cols = 16, rows = 16, mines = 40,
      tip = "mines.size16x16Tip" },
}
local DEFAULT_SIZE = "9x9"
local END_FLASH = 0.8
local STEP_BIG = 10
local function clampMines(n, want)
    want = tonumber(want)
    if not want then return nil end
    want = floor(want)
    if want < 1 then return 1 end
    if want > n - 1 then return n - 1 end
    return want
end
local SIDE = 430
local GAP = 2
local MARGIN = 14
local PANEL_W = 156
local PANEL_PAD = 12
local COL_W = PANEL_W - PANEL_PAD * 2
local ROW = 22
local PAD = 6
local MINI_W = SIDE + PAD * 2 + MARGIN * 2
local MINI_H = MINI_W
local MARK_TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local FLAG_COORD = { 0.5, 0.75, 0.25, 0.5 }
local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }
local BOMB_TEX = "Interface\\Icons\\INV_Misc_Bomb_01"
local HL_TEX = "Interface\\Buttons\\ButtonHilight-Square"
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local BACK_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local GLOW_TEX = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local ASK_TEX = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local NUM_FONT = "Fonts\\ARIALN.TTF"
local T_CLOSED = { face = { 0.34, 0.36, 0.41, 1 }, rim = { 0.64, 0.68, 0.76, 1 } }
local T_OPEN   = { face = { 0.17, 0.17, 0.20, 1 }, rim = { 0.27, 0.28, 0.32, 1 } }
local T_BOOM   = { face = { 0.70, 0.16, 0.12, 1 }, rim = { 0.95, 0.45, 0.35, 1 } }
local T_WRONG  = { face = { 0.36, 0.13, 0.13, 1 }, rim = { 0.58, 0.26, 0.26, 1 } }
local T_MINE   = { face = { 0.24, 0.22, 0.27, 1 }, rim = { 0.40, 0.38, 0.45, 1 } }
local C_GROUT = { 0.05, 0.043, 0.035, 0.95 }
local C_FRAME = { 0.58, 0.47, 0.28, 1 }
local C_GROUND_TOP = { 0.052, 0.046, 0.038 }
local C_GROUND_BOT = { 0.098, 0.083, 0.063 }
local C_PLATE = { 0.105, 0.092, 0.075, 1 }
local C_RULE  = { 0.21, 0.185, 0.145, 1 }
local LOOK_WOOD = { C_FRAME[1], C_FRAME[2], C_FRAME[3] }
local LOOK_EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE, screen = C_GROUND_BOT }
local DONE_DIM = 0.45
local PRESS_A = 0.18
local NUMCOL = {
    { 0.45, 0.65, 1.00 },
    { 0.35, 0.90, 0.40 },
    { 1.00, 0.35, 0.35 },
    { 0.75, 0.55, 1.00 },
    { 1.00, 0.65, 0.20 },
    { 0.30, 0.90, 0.90 },
    { 1.00, 0.95, 0.40 },
    { 1.00, 1.00, 1.00 },
}
local field, deck, tiles, ui
local miniOn = false
local function tileAt(i)
    local t = tiles[i]
    if t then return t end
    t = {
        rim = deck:CreateTexture(nil, "BACKGROUND"),
        face = deck:CreateTexture(nil, "BORDER"),
        icon = deck:CreateTexture(nil, "ARTWORK"),
        num = deck:CreateFontString(nil, "OVERLAY", "NumberFontNormal"),
    }
    tiles[i] = t
    return t
end
local function ensureView(canvas)
    if field then return end
    field = CreateFrame("Frame", nil, canvas)
    field:SetFrameLevel(canvas:GetFrameLevel() + 1)
    field:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    field:SetBackdropColor(C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
    field:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], C_FRAME[4])
    field:Hide()
    deck = CreateFrame("Frame", nil, field)
    deck:SetFrameLevel(field:GetFrameLevel() + 1)
    tiles = {}
    ui = {}
    ui.deco = CreateFrame("Frame", nil, canvas)
    ui.deco:SetFrameLevel(canvas:GetFrameLevel())
    ui.deco:SetAllPoints(canvas)
    ui.deco:Hide()
    local scr = ns.window:ScreenFill(ui.deco)
    scr:SetTexture(1, 1, 1, 1)
    scr:SetGradient("VERTICAL",
        C_GROUND_BOT[1], C_GROUND_BOT[2], C_GROUND_BOT[3],
        C_GROUND_TOP[1], C_GROUND_TOP[2], C_GROUND_TOP[3])
    ui.panel = CreateFrame("Frame", nil, canvas)
    ui.panel:SetFrameLevel(canvas:GetFrameLevel() + 2)
    ui.panel:SetWidth(PANEL_W)
    ui.panel:SetHeight(SIDE + PAD * 2)
    ui.panel:SetPoint("TOPRIGHT", canvas, "TOPRIGHT",
        -MARGIN, -floor((canvas.H - (SIDE + PAD * 2)) / 2))
    ui.plate = ui.panel:CreateTexture(nil, "BACKGROUND")
    ui.plate:SetAllPoints(ui.panel)
    ui.plate:SetTexture(C_PLATE[1], C_PLATE[2], C_PLATE[3], C_PLATE[4])
    ui.col = CreateFrame("Frame", nil, ui.panel)
    ui.col:SetFrameLevel(ui.panel:GetFrameLevel() + 1)
    ui.col:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", PANEL_PAD, -PANEL_PAD)
    ui.col:SetPoint("BOTTOMRIGHT", ui.panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
    local function rule(y)
        local t = ui.col:CreateTexture(nil, "ARTWORK")
        t:SetTexture(C_RULE[1], C_RULE[2], C_RULE[3], C_RULE[4])
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y)
        return t
    end
    ui.tally = ns.MakeScoreboard(ui.col, COL_W)
    ui.tally:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, 0)
    ui.bestCap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.bestCap:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 3 + 10))
    ns.SetKeyText(ui.bestCap, "mines.bestCap")
    ui.best = ui.col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.best:SetJustifyH("RIGHT")
    ui.best:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -(ROW * 3 + 10))
    ui.ruleTally = rule(ROW * 5 - 2)
    ui.leftCap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.leftCap:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 5 + 8))
    ns.SetKeyText(ui.leftCap, "mines.leftCap")
    ui.mark = ui.col:CreateTexture(nil, "OVERLAY")
    ui.mark:SetTexture(MARK_TEX)
    ui.mark:SetTexCoord(FLAG_COORD[1], FLAG_COORD[2], FLAG_COORD[3], FLAG_COORD[4])
    ui.mark:SetWidth(18)
    ui.mark:SetHeight(18)
    ui.mark:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 6 + 6))
    ui.left = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.left:SetJustifyH("RIGHT")
    ui.left:SetPoint("RIGHT", ui.col, "TOPRIGHT", 0, -(ROW * 6 + 15))
    local function axis(y)
        local st = ns.MakeStepper(ui.col)
        st:SetWidth(COL_W)
        st:SetHeight(ROW)
        st:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, y)
        local cap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, y + ROW + 4)
        return cap, st
    end
    ui.chargeCap, ui.charge = axis(0)
    ui.sizeCap, ui.size = axis(ROW * 2 + 6)
    ui.ruleAxes = ui.col:CreateTexture(nil, "ARTWORK")
    ui.ruleAxes:SetTexture(C_RULE[1], C_RULE[2], C_RULE[3], C_RULE[4])
    ui.ruleAxes:SetHeight(1)
    ui.ruleAxes:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, ROW * 4 + 26)
    ui.ruleAxes:SetPoint("BOTTOMRIGHT", ui.col, "BOTTOMRIGHT", 0, ROW * 4 + 26)
    ui.panel:Hide()
local function border(r, g, b)
        local f = CreateFrame("Frame", nil, canvas)
        f:SetFrameLevel(field:GetFrameLevel() + 4)
        f:SetBackdrop({ edgeFile = EDGE_TEX, edgeSize = 12 })
        f:SetBackdropBorderColor(r, g, b, 1)
        f:Hide()
        return f
    end
    ui.hl = border(LOOK_EDGE[1], LOOK_EDGE[2], LOOK_EDGE[3])
    ui.kb = border(0.3, 1, 0.4)
    ui.press = CreateFrame("Frame", nil, canvas)
    ui.press:SetFrameLevel(field:GetFrameLevel() + 3)
    ui.press:SetAllPoints(canvas)
    ui.press.tex = {}
    for k = 1, 8 do
        local t = ui.press:CreateTexture(nil, "OVERLAY")
        t:SetTexture(HL_TEX)
        t:SetBlendMode("ADD")
        t:SetAlpha(PRESS_A)
        t:Hide()
        ui.press.tex[k] = t
    end
    ui.flash = CreateFrame("Frame", nil, canvas)
    ui.flash:SetFrameLevel(field:GetFrameLevel() + 6)
    ui.flash.tex = ui.flash:CreateTexture(nil, "OVERLAY")
    ui.flash.tex:SetAllPoints(ui.flash)
    ui.flash.tex:SetTexture(HL_TEX)
    ui.flash.tex:SetBlendMode("ADD")
    ui.flash:Hide()
    ui.blast = CreateFrame("Frame", nil, canvas)
    ui.blast:SetFrameLevel(field:GetFrameLevel() + 7)
    ui.blast.tex = ui.blast:CreateTexture(nil, "OVERLAY")
    ui.blast.tex:SetAllPoints(ui.blast)
    ui.blast.tex:SetTexture(GLOW_TEX)
    ui.blast.tex:SetBlendMode("ADD")
    ui.blast:Hide()
end
local Game = {}
Game.__index = Game
local function sizeOf(key)
    for _, s in ipairs(SIZES) do
        if s.key == key then return s end
    end
    for _, s in ipairs(SIZES) do
        if s.key == DEFAULT_SIZE then return s end
    end
    return SIZES[1]
end
local function sizeCells(key)
    local s = sizeOf(key)
    return s.cols * s.rows
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:CellXY(i)
    local c = (i - 1) % self.cols + 1
    local r = floor((i - 1) / self.cols) + 1
    return self.ox + (c - 1) * self.step, self.oy + (r - 1) * self.step
end
function Game:CellAt(x, y)
    if not self.step then return nil end
    if x < self.ox or y < self.oy then return nil end
    local c = floor((x - self.ox) / self.step) + 1
    local r = floor((y - self.oy) / self.step) + 1
    if c < 1 or c > self.cols or r < 1 or r > self.rows then return nil end
    return (r - 1) * self.cols + c
end
local function flagsAround(self, i)
    local k = 0
    for _, j in ipairs(self.nb[i]) do
        if self.flag[j] == 1 then k = k + 1 end
    end
    return k
end
local function chordHasWork(self, i)
    for _, j in ipairs(self.nb[i]) do
        if not self.open[j] and self.flag[j] ~= 1 then return true end
    end
    return false
end
local function reveal(self, i)
    if self.open[i] or self.flag[i] == 1 then return end
    if self.mine[i] then
        self.open[i] = true
        self.boom = i
        self.over = "lost"
        self.overAt = self.t
        return
    end
    local stack, top = self.stack, 0
    top = top + 1
    stack[top] = i
    while top > 0 do
        local k = stack[top]
        top = top - 1
        if not self.open[k] and self.flag[k] ~= 1 and not self.mine[k] then
            self.open[k] = true
            self.opened = self.opened + 1
            if self.near[k] == 0 then
                for _, j in ipairs(self.nb[k]) do
                    if not self.open[j] and self.flag[j] ~= 1 then
                        top = top + 1
                        stack[top] = j
                    end
                end
            end
        end
    end
end
local function ensureLaid(self, first)
    if self.laid then return end
    self.laid = true
    local mine, near, count, tries = G.Build(self.rng, self.cols, self.rows, self.mines, first)
    self.mine, self.near, self.mines, self.tries = mine, near, count, tries
end
local function apply(self, move)
    if self.over then return false end
    local k, i = move.k, move.i
    if type(i) ~= "number" or i < 1 or i > self.n then return false end
    if k == "open" then
        if self.open[i] or self.flag[i] == 1 then return false end
        ensureLaid(self, i)
        reveal(self, i)
    elseif k == "flag" or k == "quest" then
        if self.open[i] then return false end
        local want = (k == "flag") and 1 or 2
        local was = self.flag[i] or 0
        local now = (was == want) and 0 or want
        if was == 1 then self.flags = self.flags - 1 end
        if now == 1 then self.flags = self.flags + 1 end
        self.flag[i] = now
    elseif k == "chord" then
        if not self.laid or not self.open[i] then return false end
        if self.near[i] == 0 then return false end
        if flagsAround(self, i) ~= self.near[i] then return false end
        local list, n = {}, 0
        for _, j in ipairs(self.nb[i]) do
            if not self.open[j] and self.flag[j] ~= 1 then
                n = n + 1
                list[n] = j
            end
        end
        for m = 1, n do
            if not self.over then reveal(self, list[m]) end
        end
    else
        return false
    end
    self.started = true
    if not self.over and self.opened >= self.n - self.mines then
        self.over = "won"
        self.overAt = self.t
    end
    return true
end
function Game:Start(seed, moves)
    local sz = sizeOf(self.opts and self.opts.size)
    self.sz = sz
    self.cols, self.rows = sz.cols, sz.rows
    self.n = sz.cols * sz.rows
    self.nb = G.Neighbors(sz.cols, sz.rows)
    self.mines = clampMines(self.n, self.opts and self.opts.mines) or sz.mines
    self.rng = ns.RNG.New(seed)
    local names = ns.Shelves and ns.Shelves.Get("mines", "bomb") or {}
    local db = ns.bombDB or {}
    local cnt = (#names > 0) and #names or #db
    local pick = self.rng:Int(cnt > 1 and cnt or 2)
    self.bombTex, self.bombID = nil, nil
    if names[pick] then
        self.bombTex = ns.IconPath(names[pick])
    else
        self.bombID = db[pick] and db[pick].id
        if self.bombID and not GetItemIcon(self.bombID) then GetItemInfo(self.bombID) end
    end
    self.mine, self.near = {}, {}
    self.open, self.flag = {}, {}
    for i = 1, self.n do
        self.open[i] = false
        self.flag[i] = 0
    end
    self.stack = {}
    self.laid = false
    self.opened, self.flags = 0, 0
    self.boom, self.over, self.overAt = nil, nil, nil
    self.tries = 0
    self.cur, self.hover = nil, nil
    self.t, self.started = 0, false
    if moves and #moves > 0 then
        for m = 1, #moves do apply(self, moves[m]) end
        local rec = ns.Store.Load(ID)
        self.t = (rec and rec.elapsed) or 0
        self.started = true
        if self.over then self.overAt = self.t - END_FLASH end
    end
    self:Build()
    self:Draw()
end
function Game:Move(move)
    local before = self.opened
    local took = apply(self, move)
    self:Draw()
    if took then
        if move.k == "flag" and self.flag[move.i] == 1 then
            ns.Sfx.Play("pick")
        elseif move.k == "open" or move.k == "chord" then
            if self.over == "lost" then
                ns.Sfx.Play("over")
            elseif self.over == "won" then
                ns.Sfx.Play("clear")
            elseif self.opened - before > 1 then
                ns.Sfx.Play("big")
            elseif self.opened - before == 1 then
                ns.Sfx.Play("pop")
            end
        end
    end
    return took
end
function Game:Click(x, y, button)
    if self.over then return end
    local i = self:CellAt(x, y)
    if not i then return end
    if button == "RightButton" then
        if self.open[i] then return end
        if IsShiftKeyDown() then
            self:Move{ k = "quest", i = i }
        else
            self:Move{ k = "flag", i = i }
        end
        return
    end
    if self.open[i] then
        if self.near[i] == 0 then return end
        if flagsAround(self, i) ~= self.near[i] then return end
        if not chordHasWork(self, i) then return end
        self:Move{ k = "chord", i = i }
        return
    end
    if self.flag[i] == 1 then return end
    self:Move{ k = "open", i = i }
end
function Game:Key(action, down)
    if not down or self.over then return end
    if action == "left" or action == "right" or action == "up" or action == "down" then
        if not self.cur then
            self.cur = floor(self.n / 2)
        else
            local c = (self.cur - 1) % self.cols + 1
            local r = floor((self.cur - 1) / self.cols) + 1
            if action == "left" then c = (c > 1) and (c - 1) or self.cols
            elseif action == "right" then c = (c < self.cols) and (c + 1) or 1
            elseif action == "up" then r = (r < self.rows) and (r + 1) or 1
            else r = (r > 1) and (r - 1) or self.rows
            end
            self.cur = (r - 1) * self.cols + c
        end
        self:Cursor()
        return
    end
    local i = self.cur
    if not i then return end
    if action == "fire" then
        if self.open[i] then
            if self.near[i] == 0 then return end
            if flagsAround(self, i) ~= self.near[i] then return end
            if not chordHasWork(self, i) then return end
            self:Move{ k = "chord", i = i }
        elseif self.flag[i] ~= 1 then
            self:Move{ k = "open", i = i }
        end
    elseif action == "mark" then
        if self.open[i] then return end
        self:Move{ k = "flag", i = i }
    end
end
function Game:Update(dt)
    if self.started then self.t = self.t + dt end
    if self.over then
        self:Flash()
        return
    end
    self:Hover()
end
function Game:Score()
    return 0
end
function Game:Brink()
    if not self.laid then
        local first = 1
        while first <= self.n and self.flag[first] == 1 do first = first + 1 end
        ensureLaid(self, first)
        self.started = true
    end
    local spare
    for i = 1, self.n do
        if self.mine[i] then
            if self.flag[i] ~= 1 then
                self.flag[i] = 1
                self.flags = self.flags + 1
            end
        elseif not self.open[i] then
            if not spare then
                spare = i
            else
                self.open[i] = true
                self.opened = self.opened + 1
            end
        end
    end
    self:Draw()
end
function Game:Ranked()
    if self.over ~= "won" then return false end
    if self.mines ~= self.sz.mines then return ns.T("mines.rankedCustom") end
    return true
end
function Game:IsOver()
    if not self.over then return false end
    return (self.t - (self.overAt or 0)) >= END_FLASH
end
function Game:Mini(on)
    miniOn = on and true or false
    if field then self:Build() end
end
function Game:MiniNote()
    if not self.mines then return "" end
    local left = self.mines - self.flags
    if self.over == "won" then left = 0 end
    return ns.T("mines.miniLeft", left)
end
function Game:Stop()
    miniOn = false
    if field then field:Hide() end
    if ui then
        ui.deco:Hide()
        ui.panel:Hide()
        ui.hl:Hide()
        ui.kb:Hide()
        ui.flash:Hide()
        ui.blast:Hide()
        for k = 1, 8 do ui.press.tex[k]:Hide() end
    end
end
local function putAxis(it)
    local st, cap = ui.size, ui.sizeCap
    if not it.options then
        st, cap = ui.charge, ui.chargeCap
        local bare = {}
        for k, v in pairs(it) do bare[k] = v end
        bare.format = "%d"
        it = bare
    end
    cap:SetText(it.label or "")
    st:SetSpec(it)
    if it.disabled then st:Disable() else st:Enable() end
    st:Restyle()
end
function Game:PanelSync()
    if not ui or ns.Loop.Current() ~= self then return end
    ui.tally:Sync()
    local locked = ns.window:AxisLocked()
    if self._panelLock == locked then return end
    self._panelLock = locked
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.kind == "step" then putAxis(it) end
    end
end
function Game:Build()
    local canvas = self.canvas
    ensureView(canvas)
    local big = (self.cols > self.rows) and self.cols or self.rows
    self.step = floor((SIDE + GAP) / big)
    self.cell = self.step - GAP
    local w = self.cols * self.step - GAP
    local h = self.rows * self.step - GAP
    if miniOn then
        self.ox = floor((canvas.W - w) / 2)
        self.oy = floor((canvas.H - h) / 2)
    else
        self.ox = MARGIN + PAD + floor((SIDE - w) / 2)
        self.oy = floor((canvas.H - SIDE) / 2) + floor((SIDE - h) / 2)
    end
    field:ClearAllPoints()
    field:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.ox - PAD, self.oy - PAD)
    field:SetWidth(w + PAD * 2)
    field:SetHeight(h + PAD * 2)
    field:Show()
    deck:ClearAllPoints()
    deck:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", PAD, PAD)
    deck:SetWidth(w)
    deck:SetHeight(h)
    local edge = (self.cell >= 40) and 2 or 1
    local face = self.cell - edge * 2
    local px = floor(face * 0.78 + 0.5)
    for i = 1, self.n do
        local t = tileAt(i)
        local x, y = self:CellXY(i)
        x, y = x - self.ox, y - self.oy
        t.rim:ClearAllPoints()
        t.rim:SetWidth(self.cell)
        t.rim:SetHeight(self.cell)
        t.rim:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", x, y)
        t.rim:Show()
        t.face:ClearAllPoints()
        t.face:SetWidth(face)
        t.face:SetHeight(face)
        t.face:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", x + edge, y + edge)
        t.face:Show()
        t.icon:ClearAllPoints()
        t.icon:SetWidth(face - 4)
        t.icon:SetHeight(face - 4)
        t.icon:SetPoint("CENTER", t.face, "CENTER", 0, 0)
        t.num:ClearAllPoints()
        t.num:SetPoint("CENTER", t.face, "CENTER", 0, 0)
        if not t.num:SetFont(NUM_FONT, px, "THICKOUTLINE") then
            t.num:SetFont((t.num:GetFont()), px, "THICKOUTLINE")
        end
    end
    for i = self.n + 1, #tiles do
        tiles[i].rim:Hide()
        tiles[i].face:Hide()
        tiles[i].icon:Hide()
        tiles[i].num:Hide()
    end
    local sz = self.cell + 6
    ui.hl:SetWidth(sz)
    ui.hl:SetHeight(sz)
    ui.kb:SetWidth(sz)
    ui.kb:SetHeight(sz)
    for k = 1, 8 do
        ui.press.tex[k]:SetWidth(self.cell)
        ui.press.tex[k]:SetHeight(self.cell)
    end
    ui.deco:Show()
    if miniOn then ui.panel:Hide() else ui.panel:Show() end
    self._panelLock = nil
    local best = ns.Records.Best(ID, self.opts)
    local mark = ns.Records.Main(self.def)
    ui.best:SetText(best and ns.Records.Format(mark, best[mark.key]) or "—")
    ui.flash:ClearAllPoints()
    ui.flash:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.ox, self.oy)
    ui.flash:SetWidth(w)
    ui.flash:SetHeight(h)
    ui.flash:Hide()
    ui.blast:Hide()
end
local function tone(t, tn)
    local f, r = tn.face, tn.rim
    t.face:SetTexture(f[1], f[2], f[3], f[4])
    t.rim:SetTexture(r[1], r[2], r[3], r[4])
end
function Game:Draw()
    if not field or not self.step then return end
    local lost = (self.over == "lost")
    local won = (self.over == "won")
    local bomb = self.bombTex
                 or (self.bombID and ns.Icons.Item(self.bombID))
                 or ns.Icons.QMARK
    for i = 1, self.n do
        local t = tiles[i]
        local isMine = self.mine[i]
        local fl = self.flag[i]
        t.num:Hide()
        t.icon:SetVertexColor(1, 1, 1)
        if self.open[i] then
            if i == self.boom then
                tone(t, T_BOOM)
                t.icon:SetTexture(bomb)
                t.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
                t.icon:Show()
            else
                tone(t, T_OPEN)
                t.icon:Hide()
                local v = self.near[i]
                if v and v > 0 then
                    local c = NUMCOL[v] or NUMCOL[8]
                    local d = (flagsAround(self, i) == v) and DONE_DIM or 1
                    t.num:SetText(v)
                    t.num:SetTextColor(c[1] * d, c[2] * d, c[3] * d)
                    t.num:Show()
                end
            end
        elseif lost and isMine and fl ~= 1 then
            tone(t, T_MINE)
            t.icon:SetTexture(bomb)
            t.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
            t.icon:SetVertexColor(0.85, 0.85, 0.85)
            t.icon:Show()
        elseif lost and fl == 1 and not isMine then
            tone(t, T_WRONG)
            t.icon:SetTexture(MARK_TEX)
            t.icon:SetTexCoord(FLAG_COORD[1], FLAG_COORD[2], FLAG_COORD[3], FLAG_COORD[4])
            t.icon:SetVertexColor(0.5, 0.5, 0.5)
            t.icon:Show()
        elseif fl == 1 or (won and isMine) then
            tone(t, T_CLOSED)
            t.icon:SetTexture(MARK_TEX)
            t.icon:SetTexCoord(FLAG_COORD[1], FLAG_COORD[2], FLAG_COORD[3], FLAG_COORD[4])
            t.icon:Show()
        elseif fl == 2 then
            tone(t, T_CLOSED)
            t.icon:Hide()
            t.num:SetText("?")
            t.num:SetTextColor(0.72, 0.74, 0.82)
            t.num:Show()
        else
            tone(t, T_CLOSED)
            t.icon:Hide()
        end
    end
    self:Cursor()
    local left = self.mines - self.flags
    if won then left = 0 end
    ui.left:SetText(left)
    ui.left:Show()
    if left < 0 then
        ui.left:SetTextColor(1, 0.35, 0.35)
    else
        ui.left:SetTextColor(1, 0.82, 0)
    end
end
function Game:Cursor()
    if not ui then return end
    local me = self
    local function put(f, i)
        if not i or me.over then
            f:Hide()
            return
        end
        local x, y = me:CellXY(i)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", me.canvas, "BOTTOMLEFT", x - 3, y - 3)
        f:Show()
    end
    put(ui.hl, self.hover)
    put(ui.kb, self.cur)
    self:Press()
end
function Game:Press()
    if not ui or not self.step then return end
    local n = 0
    local function light(j)
        n = n + 1
        local t = ui.press.tex[n]
        local x, y = self:CellXY(j)
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x, y)
        t:Show()
    end
    local i = self.hover
    if i and not self.over then
        if self.open[i] then
            local v = self.near[i]
            if v and v > 0 and flagsAround(self, i) == v and chordHasWork(self, i) then
                for _, j in ipairs(self.nb[i]) do
                    if not self.open[j] and self.flag[j] ~= 1 then light(j) end
                end
            end
        elseif self.flag[i] ~= 1 then
            light(i)
        end
    end
    for k = n + 1, 8 do ui.press.tex[k]:Hide() end
end
function Game:Hover()
    local canvas = self.canvas
    local i
    if not ns.Help.IsShown() then
        local left, bottom = canvas:GetLeft(), canvas:GetBottom()
        local scale = canvas:GetEffectiveScale()
        if left and bottom and scale and scale > 0 then
            local mx, my = GetCursorPosition()
            i = self:CellAt(mx / scale - left, my / scale - bottom)
        end
    end
    if i == self.hover then return end
    self.hover = i
    self:Cursor()
end
function Game:Flash()
    if not ui then return end
    local p = (self.t - (self.overAt or 0)) / END_FLASH
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    if p >= 1 then
        ui.flash:Hide()
        ui.blast:Hide()
        return
    end
    local a = (p < 0.2) and (p / 0.2) or ((1 - p) / 0.8)
    if self.over == "lost" then
        ui.flash.tex:SetVertexColor(1, 0.3, 0.15)
        ui.flash.tex:SetAlpha(a * 0.35)
    else
        ui.flash.tex:SetVertexColor(1, 0.92, 0.55)
        ui.flash.tex:SetAlpha(a * 0.55)
    end
    ui.flash:Show()
    if self.over == "lost" and self.boom and self.cell then
        local x, y = self:CellXY(self.boom)
        local s = self.cell * (1.4 + 4.2 * p)
        ui.blast:ClearAllPoints()
        ui.blast:SetPoint("CENTER", self.canvas, "BOTTOMLEFT",
            x + self.cell / 2, y + self.cell / 2)
        ui.blast:SetWidth(s)
        ui.blast:SetHeight(s)
        ui.blast.tex:SetVertexColor(1, 0.55, 0.12)
        ui.blast.tex:SetAlpha((1 - p) * 0.9)
        ui.blast:Show()
    end
end
local MINI_CLOSED = { 0.34, 0.36, 0.41 }
local MINI_OPEN   = { 0.17, 0.17, 0.20 }
local MINI_MINE   = { 0.70, 0.16, 0.12 }
local MINI_FLAG   = { 0.58, 0.26, 0.26 }
local MINI_N1     = { 0.45, 0.65, 1.00 }
local MINI_N2     = { 0.35, 0.90, 0.40 }
local MINI_N3     = { 1.00, 0.35, 0.35 }
local MINI = {
    {
        cols = 3, rows = 3, cell = 26, gap = 2, back = "plain",
        fill = { { c = 2, r = 2, col = MINI_OPEN } },
        dot = { { c = 1, r = 3, col = MINI_MINE }, { c = 3, r = 3, col = MINI_MINE },
                 { c = 1, r = 1, col = MINI_MINE } },
        text = { { c = 2, r = 2, s = "3", col = MINI_N3 } },
    },
    {
        cols = 3, rows = 3, cell = 26, gap = 2, back = "plain",
        fill = { { c = 2, r = 2, col = MINI_OPEN } },
        dot = { { c = 1, r = 3, col = MINI_FLAG }, { c = 3, r = 1, col = MINI_FLAG } },
        ring = { { c = 1, r = 1 }, { c = 2, r = 1 }, { c = 1, r = 2 },
                 { c = 3, r = 2 }, { c = 2, r = 3 }, { c = 3, r = 3 } },
        text = { { c = 2, r = 2, s = "2", col = MINI_N2 } },
    },
    {
        cols = 5, rows = 5, cell = 22, gap = 2, back = "plain",
        fill = {
            { c = 3, r = 3, col = MINI_OPEN }, { c = 2, r = 3, col = MINI_OPEN },
            { c = 4, r = 3, col = MINI_OPEN }, { c = 3, r = 2, col = MINI_OPEN },
            { c = 3, r = 4, col = MINI_OPEN },
            { c = 2, r = 2, col = MINI_OPEN }, { c = 2, r = 4, col = MINI_OPEN },
            { c = 4, r = 2, col = MINI_OPEN }, { c = 4, r = 4, col = MINI_OPEN },
        },
        text = {
            { c = 2, r = 2, s = "1", col = MINI_N1 }, { c = 2, r = 4, s = "1", col = MINI_N1 },
            { c = 4, r = 2, s = "1", col = MINI_N1 }, { c = 4, r = 4, s = "1", col = MINI_N1 },
        },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_CLOSED)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.dot or {}) do g:Dot(m.c, m.r, m.col) end
    for _, m in ipairs(spec.text or {}) do g:Text(m.c, m.r, m.s, m.col) end
end
local function helpNumber(host) paintMini(host, MINI[1]) end
local function helpChord(host) paintMini(host, MINI[2]) end
local function helpCascade(host) paintMini(host, MINI[3]) end
ns.RegisterGame{
    id = ID,
    label = "mines.label",
    icon = { tex = BOMB_TEX, coord = ICON_CROP },
    tip = "mines.tip",
    order = 6,
    duo = "score",
    physics = false,
    done = true,
    New = New,
    look = LOOK,
    mini = { w = MINI_W, h = MINI_H },
    ownPanel = true,
    opts = {
        { key = "size", label = "mines.optSizeLabel", def = DEFAULT_SIZE, ordered = true,
          options = SIZES, reset = { "mines" },
          tip = "mines.optSizeTip" },
        { key = "mines", label = "mines.optMinesLabel", thin = true,
          min = 1, step = 1, big = STEP_BIG, format = "mines.optMinesFmt",
          max = function(sel) return sizeCells(sel.size) - 1 end,
          def = function(sel) return sizeOf(sel.size).mines end,
          tip = "mines.optMinesTip" },
    },
    record = {
        { key = "time", label = "mines.recTime", by = "min", mark = "clock", format = "span" },
    },
    clock = "hard",
    tally = false,
    finale = true,
    keymap = {
        LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
        SPACE = "fire", ["SHIFT-SPACE"] = "mark",
    },
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
        { action = "up",    mouse = false },
        { action = "down",  mouse = false },
        { action = "fire",  label = "mines.ctlDig",  mouse = "LMB" },
        { action = "mark",  label = "mines.ctlMark", mouse = "RMB" },
    },
    help = {
        "mines.help1",
        "mines.helpNumber",
        { art = helpNumber, h = 90,
          sub = "mines.helpNumberSub" },
        { t = "mines.help3" },
        { icon = MARK_TEX, coord = FLAG_COORD,
          t = "mines.help4" },
        "mines.help4Sub",
        { icon = ASK_TEX, coord = { 0, 1, 0, 1 },
          t = "mines.help5" },
        "mines.help5Sub",
        "mines.helpChord",
        { art = helpChord, h = 90 },
        "mines.helpChordSub",
        "mines.helpCascade",
        { art = helpCascade, h = 126,
          sub = "mines.helpCascadeSub" },
        { t = "mines.help7" },
        "mines.help8",
    },
}
