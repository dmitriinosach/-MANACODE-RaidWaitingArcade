local ADDON, ns = ...
local ID = "recipe"
local TRIES  = 10
local ROWS   = TRIES + 1
local GAP    = 5
local MARGIN = 14
local PLATE_PAD = 6
local TOP_M  = MARGIN + PLATE_PAD
local HINT_H = 44
local NUMW   = 22
local MIDGAP = 10
local ANS_ICON  = 16
local ANS_NUM   = 11
local ANS_GAP   = 8
local ANS_STEP  = ANS_ICON + 3 + ANS_NUM + ANS_GAP
local ANS_W     = 3 * ANS_STEP - ANS_GAP
local PAL_COLS = 2
local PAL_GAP  = 6
local PANEL_W   = 156
local PANEL_PAD = 12
local COL_W     = PANEL_W - PANEL_PAD * 2
local ROW       = 22
local NOTE_H    = 28
local PLATE_BOT = MARGIN
local MAX_P = 5
local LEG_ICON = 14
local WIN_FLASH = 0.6
local SHELF_SALT = 7717
local SHELF = "reagent"
local READY_TEX = ns.RecipeArt.READY
local WAIT_TEX  = ns.RecipeArt.WAIT
local NOPE_TEX  = ns.RecipeArt.NOPE
local HL_TEX    = "Interface\\Buttons\\ButtonHilight-Square"
local EDGE_TEX  = "Interface\\Tooltips\\UI-Tooltip-Border"
local TILE_TEX  = "Interface\\ICONS\\inv_potion_31"
local GLOW_TEX  = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local C_GROUND_TOP = { 0.028, 0.026, 0.022 }
local C_GROUND_BOT = { 0.070, 0.055, 0.040 }
local C_PLATE   = { 0.165, 0.135, 0.095, 1 }
local C_COL     = C_PLATE
local C_EDGE    = { 0.30, 0.25, 0.165, 1 }
local C_RULE    = { 0.28, 0.245, 0.19, 1 }
local C_FLASK   = { 0.88, 0.70, 0.28, 0.22 }
local C_DOT_ON  = { 0.82, 0.64, 0.20, 1 }
local C_DOT_OFF = { 0.34, 0.30, 0.24, 1 }
local LOOK_WOOD = { 0.165, 0.135, 0.095 }
local LOOK_EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE, screen = C_GROUND_BOT }
local BG_EMPTY = { { 0.135, 0.11, 0.075, 1 }, { 0.07, 0.06, 0.05, 1 } }
local BG_DONE  = { { 0.26, 0.225, 0.17, 1 },  { 0.175, 0.155, 0.125, 1 } }
local BG_ACT   = { { 0.33, 0.28, 0.19, 1 },   { 0.225, 0.195, 0.145, 1 } }
local BG_CODE  = { { 0.34, 0.26, 0.13, 1 },   { 0.19, 0.145, 0.08, 1 } }
local PAL_BG   = { 0.06, 0.05, 0.04, 1 }
local LEVELS = {
    { key = "distinct", label = "recipe.lvlD46Label", p = 4, c = 6, rep = false,
      tip = "recipe.lvlD46Tip" },
    { key = "easy",   label = "recipe.lvlR46Label", p = 4, c = 6, rep = true,
      tip = "recipe.lvlR46Tip" },
    { key = "wide",   label = "recipe.lvlD48Label", p = 4, c = 8, rep = false,
      tip = "recipe.lvlD48Tip" },
    { key = "normal", label = "recipe.lvlR48Label", p = 4, c = 8, rep = true,
      tip = "recipe.lvlR48Tip" },
    { key = "long",   label = "recipe.lvlD58Label", p = 5, c = 8, rep = false,
      tip = "recipe.lvlD58Tip" },
    { key = "hard",   label = "recipe.lvlR58Label", p = 5, c = 8, rep = true,
      tip = "recipe.lvlR58Tip" },
}
local DEFAULT_LEVEL = "distinct"
local LEGEND = {
    { tex = READY_TEX, t = "recipe.legHit" },
    { tex = WAIT_TEX,  t = "recipe.legNear" },
    { tex = NOPE_TEX,  t = "recipe.legMiss" },
}
local ANS_TEX = { READY_TEX, WAIT_TEX, NOPE_TEX }
local LEG_HEAD = "recipe.legHead"
local REP_YES = "recipe.repYes"
local REP_NO  = "recipe.repNo"
local cellPool, pegPool, cntPool, numPool, ui, cur
local Game = {}
Game.__index = Game
local function levelOf(key)
    for _, l in ipairs(LEVELS) do
        if l.key == key then return l end
    end
    for _, l in ipairs(LEVELS) do
        if l.key == DEFAULT_LEVEL then return l end
    end
    return LEVELS[1]
end
local function judge(code, mix, c)
    local hit = 0
    local inCode, inMix = {}, {}
    for k = 1, c do
        inCode[k] = 0
        inMix[k] = 0
    end
    for i = 1, #code do
        local a, b = code[i], mix[i]
        if a == b then hit = hit + 1 end
        if a >= 1 and a <= c then inCode[a] = inCode[a] + 1 end
        if b and b >= 1 and b <= c then inMix[b] = inMix[b] + 1 end
    end
    local total = 0
    for k = 1, c do
        total = total + (inCode[k] < inMix[k] and inCode[k] or inMix[k])
    end
    return hit, total - hit
end
local function isOver(self)
    return self.overAt ~= nil
end
local function firstFree(self)
    for i = 1, self.p do
        if self.mix[i] == 0 then return i end
    end
    return nil
end
local function full(self)
    return firstFree(self) == nil
end
local function brewedBefore(self)
    for _, row in ipairs(self.rows) do
        local same = true
        for i = 1, self.p do
            if row.mix[i] ~= self.mix[i] then
                same = false
                break
            end
        end
        if same then return true end
    end
    return false
end
local function apply(self, move)
    if not move then return false end
    if isOver(self) then return false end
    local k = move.k
    if k == "put" then
        local i, c = move.i, move.c
        if type(i) ~= "number" or i < 1 or i > self.p then return false end
        if type(c) ~= "number" or c < 1 or c > self.c then return false end
        if self.mix[i] ~= 0 then return false end
        self.mix[i] = c
    elseif k == "clear" then
        local i = move.i
        if type(i) ~= "number" or i < 1 or i > self.p then return false end
        if self.mix[i] == 0 then return false end
        self.mix[i] = 0
    elseif k == "brew" then
        if not full(self) then return false end
        if brewedBefore(self) then return false end
        local mix = {}
        for i = 1, self.p do mix[i] = self.mix[i] end
        local hit, near = judge(self.code, mix, self.c)
        self.rows[#self.rows + 1] = { mix = mix, hit = hit, near = near }
        for i = 1, self.p do self.mix[i] = 0 end
        if hit == self.p then
            self.won = true
            self.overAt = self.t
        elseif #self.rows >= TRIES then
            self.overAt = self.t
        end
    else
        return false
    end
    self.started = true
    return true
end
local function takeIcons(self)
    local pick = ns.RNG.New((self.seed or 0) + SHELF_SALT)
    local shelf = ns.Shelves.Get(ID, SHELF)
    local bag = {}
    for i = 1, #shelf do bag[i] = shelf[i] end
    pick:Shuffle(bag)
    local tex = {}
    for k = 1, self.c do
        tex[k] = bag[k] and ns.IconPath(bag[k]) or ns.Icons.QMARK
    end
    self.tex = tex
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    self.lv = levelOf(self.opts and self.opts.level)
    self.opts = { level = self.lv.key }
    self.p, self.c = self.lv.p, self.lv.c
    self.seed = seed
    local rng = ns.RNG.New(seed)
    self.code = {}
    if self.lv.rep then
        for i = 1, self.p do self.code[i] = rng:Int(self.c) end
    else
        local bag = {}
        for k = 1, self.c do bag[k] = k end
        for i = 1, self.p do
            local j = rng:Int(i, self.c)
            bag[i], bag[j] = bag[j], bag[i]
            self.code[i] = bag[i]
        end
    end
    self.rows = {}
    self.mix = {}
    for i = 1, self.p do self.mix[i] = 0 end
    self.won = false
    self.overAt = nil
    self.started = false
    self.t = 0
    self.note = nil
    takeIcons(self)
    self:Layout()
    if moves and #moves > 0 then
        for n = 1, #moves do apply(self, moves[n]) end
        local rec = ns.Store.Load(ID)
        self.t = (rec and rec.elapsed) or 0
        self.started = true
        if isOver(self) then self.overAt = self.t end
    end
    cur = self
    self:Build()
    self:Draw()
    if not (moves and #moves > 0) and not ns.Config.Get(ID, "seenHelp", false) then
        ns.Config.Set(ID, "seenHelp", true)
        ns.window:ShowHelp()
    end
end
function Game:Move(move)
    self.note = nil
    local took = apply(self, move)
    if took then
        if move.k == "put" then
            ns.Sfx.Play("pick")
        elseif move.k == "brew" then
            ns.Sfx.Play(isOver(self) and "over" or "pop")
        end
    end
    self:Draw()
    return took
end
function Game:Click(x, y)
    if isOver(self) then return end
    local k = self:PalAt(x, y)
    if k then
        local i = firstFree(self)
        if not i then
            self:Nudge(ns.T("recipe.nudgeFull"))
            return
        end
        self:Move{ k = "put", i = i, c = k }
        return
    end
    local i = self:MixAt(x, y)
    if not i then return end
    if self.mix[i] == 0 then return end
    self:Move{ k = "clear", i = i }
end
function Game:CellClick(role, r, i)
    if isOver(self) then return end
    if role == "pal" then
        if type(i) ~= "number" or i > self.c then return end
        local at = firstFree(self)
        if not at then
            self:Nudge(ns.T("recipe.nudgeFull"))
            return
        end
        self:Move{ k = "put", i = at, c = i }
    elseif role == "row" then
        if r ~= self:ActiveRow() then return end
        if self.mix[i] == 0 then return end
        self:Move{ k = "clear", i = i }
    end
end
function Game:Key(action, down)
    if not down then return end
    if isOver(self) then return end
    local n = string.match(action, "^gem(%d)$")
    if n then
        local k = tonumber(n)
        if k < 1 or k > self.c then return end
        local i = firstFree(self)
        if not i then
            self:Nudge(ns.T("recipe.nudgeFull"))
            return
        end
        self:Move{ k = "put", i = i, c = k }
        return
    end
    if action == "fire" then
        self:Brew()
    elseif action == "back" then
        local last
        for i = 1, self.p do
            if self.mix[i] ~= 0 then last = i end
        end
        if last then self:Move{ k = "clear", i = last } end
    end
end
function Game:Brew()
    if isOver(self) then return end
    if not full(self) then
        self:Nudge(ns.T("recipe.nudgeEmpty"))
        return
    end
    if brewedBefore(self) then
        self:Nudge(ns.T("recipe.nudgeRepeat"))
        return
    end
    self:Move{ k = "brew" }
end
function Game:Nudge(text)
    self.note = text
    self:Draw()
end
function Game:Update(dt)
    if self.started then self.t = self.t + dt end
    if self.won then self:Flash() end
end
function Game:Score()
    return 0
end
function Game:ResultText()
    if self.won then return ns.T("recipe.resultWon", #self.rows) end
    return ns.T("recipe.resultLost")
end
function Game:IsOver()
    return isOver(self)
end
function Game:Stop()
    if cur == self then cur = nil end
    if cellPool then cellPool:HideAll() end
    if pegPool then pegPool:HideAll() end
    if cntPool then cntPool:HideAll() end
    if numPool then numPool:HideAll() end
    if ui then
        ui.brew:Hide()
        ui.status:Hide()
        ui.tipline:Hide()
        ui.label:Hide()
        ui.face:Hide()
        ui.act:Hide()
        ui.flash:Hide()
        ui.deco:Hide()
        ui.panel:Hide()
        ui.spotCode:Hide()
        ui.spotRow:Hide()
        ui.spotPal:Hide()
        ui.spotAns:Hide()
    end
    self.cells, self.pals, self.ans, self.nums = nil, nil, nil, nil
end
function Game:Layout()
    local canvas = self.canvas
    local avail = canvas.H - TOP_M - PLATE_BOT - HINT_H
    local cell, fits = ns.CellFit(ROWS, avail, GAP, 0)
    if not fits then
        ns.say(ns.T("recipe.layoutOverflow"))
    end
    self.cell = cell
    self.pitch = cell + GAP
    local L = ns.CellLadder()
    local up = ns.CellStep(cell) + 1
    if up > #L then up = #L end
    self.pal = L[up]
    self.palW = PAL_COLS * self.pal + (PAL_COLS - 1) * PAL_GAP
    self.mixW = self.p * self.pitch - GAP
    local blockH = ROWS * cell + (ROWS - 1) * GAP
    self.oy = PLATE_BOT + HINT_H + math.floor((avail - blockH) / 2)
    self.top = self.oy + blockH
    self.rowW = NUMW + self.mixW + MIDGAP + ANS_W
    self.plateW = NUMW + (MAX_P * self.pitch - GAP) + MIDGAP + ANS_W
    self.ox = MARGIN + PLATE_PAD + math.floor((self.plateW - self.rowW) / 2)
    self.colX = canvas.W - MARGIN - PANEL_W
    self.palPlateX = self.colX - MARGIN - (self.palW + PLATE_PAD * 2)
    self.palX = self.palPlateX + PLATE_PAD
    local palRows = math.ceil(self.c / PAL_COLS)
    self.palBottom = self.top - palRows * self.pal - (palRows - 1) * PAL_GAP
end
function Game:RowY(r)
    return self.oy + (ROWS - 1 - r) * self.pitch
end
function Game:MixX(i)
    return self.ox + NUMW + (i - 1) * self.pitch
end
function Game:AnsX(k)
    return self.ox + NUMW + self.mixW + MIDGAP + (k - 1) * ANS_STEP
end
function Game:PalXY(k)
    local col = (k - 1) % PAL_COLS + 1
    local row = math.floor((k - 1) / PAL_COLS) + 1
    return self.palX + (col - 1) * (self.pal + PAL_GAP),
           self.top - row * self.pal - (row - 1) * PAL_GAP
end
function Game:ActiveRow()
    if isOver(self) then return nil end
    return #self.rows + 1
end
function Game:MixAt(x, y)
    local r = self:ActiveRow()
    if not r then return nil end
    local ry = self:RowY(r)
    if y < ry or y > ry + self.cell then return nil end
    local dx = x - (self.ox + NUMW)
    if dx < 0 then return nil end
    local i = math.floor(dx / self.pitch) + 1
    if i < 1 or i > self.p then return nil end
    if dx - (i - 1) * self.pitch > self.cell then return nil end
    return i
end
function Game:PalAt(x, y)
    for k = 1, self.c do
        local px, py = self:PalXY(k)
        if x >= px and x <= px + self.pal and y >= py and y <= py + self.pal then return k end
    end
    return nil
end
local function makeCell(parent)
    local c = ns.MakeCell(parent)
    c:EnableMouse(false)
    ns.StyleCell(c, "plain")
    c.bg = c:CreateTexture(nil, "BACKGROUND")
    c.bg:SetAllPoints(c)
    c.bg2 = c:CreateTexture(nil, "BORDER")
    c.bg2:SetPoint("TOPLEFT", c, "TOPLEFT", 1, -1)
    c.bg2:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -1, 1)
    c.sel = c:CreateTexture(nil, "OVERLAY")
    c.sel:SetAllPoints(c)
    c.sel:SetTexture(HL_TEX)
    c.sel:SetBlendMode("ADD")
    c.sel:SetAlpha(0.35)
    c.sel:Hide()
    return c
end
local function resetCell(c)
    ns.ResetCell(c)
    c.sel:Hide()
    c:SetAlpha(1)
    c:EnableMouse(false)
end
local function cellClick(self)
    if ns.Loop.IsPaused() then
        ns.Loop.Resume()
        ns.window:RefreshHead()
        return
    end
    if not cur then return end
    cur:CellClick(self.role, self.rowAt, self.idx)
end
local function fillTex(tex, col)
    ns.Paint(tex, col[1], col[2], col[3], col[4])
end
local function fillCell(c, pair)
    fillTex(c.bg, pair[1])
    fillTex(c.bg2, pair[2])
end
local function buildUI(canvas)
    local u = {}
    u.deco = ns.NewFrame("Frame", nil, canvas)
    u.deco:SetFrameLevel(canvas:GetFrameLevel())
    u.deco:SetAllPoints(canvas)
    u.deco:Hide()
    local scr = ns.window:ScreenFill(u.deco)
    ns.Paint(scr, 1, 1, 1, 1)
    ns.Gradient(scr, "VERTICAL",
        C_GROUND_BOT[1], C_GROUND_BOT[2], C_GROUND_BOT[3], 1,
        C_GROUND_TOP[1], C_GROUND_TOP[2], C_GROUND_TOP[3], 1)
    u.glow = u.deco:CreateTexture(nil, "ARTWORK")
    u.glow:SetTexture(GLOW_TEX)
    u.glow:SetBlendMode("ADD")
    u.glow:SetVertexColor(0.72, 0.57, 0.18)
    u.glow:SetAlpha(0.07)
    u.glow:SetWidth(420)
    u.glow:SetHeight(120)
    u.glow:SetPoint("BOTTOM", canvas, "BOTTOM", -80, 0)
    u.rowPlate = u.deco:CreateTexture(nil, "BORDER")
    fillTex(u.rowPlate, C_PLATE)
    u.palPlate = u.deco:CreateTexture(nil, "BORDER")
    fillTex(u.palPlate, C_PLATE)
    local function outline(host, region)
        local function line(t)
            fillTex(t, C_EDGE)
            return t
        end
        local top = line(host:CreateTexture(nil, "ARTWORK"))
        top:SetHeight(1)
        top:SetPoint("TOPLEFT", region, "TOPLEFT", 0, 0)
        top:SetPoint("TOPRIGHT", region, "TOPRIGHT", 0, 0)
        local bot = line(host:CreateTexture(nil, "ARTWORK"))
        bot:SetHeight(1)
        bot:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", 0, 0)
        bot:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, 0)
        local lft = line(host:CreateTexture(nil, "ARTWORK"))
        lft:SetWidth(1)
        lft:SetPoint("TOPLEFT", region, "TOPLEFT", 0, 0)
        lft:SetPoint("BOTTOMLEFT", region, "BOTTOMLEFT", 0, 0)
        local rgt = line(host:CreateTexture(nil, "ARTWORK"))
        rgt:SetWidth(1)
        rgt:SetPoint("TOPRIGHT", region, "TOPRIGHT", 0, 0)
        rgt:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, 0)
    end
    outline(u.deco, u.rowPlate)
    outline(u.deco, u.palPlate)
    u.flask = {}
    for i = 1, 11 do
        local t = u.deco:CreateTexture(nil, "OVERLAY")
        fillTex(t, C_FLASK)
        u.flask[i] = t
    end
    u.face = ns.NewFrame("Frame", nil, canvas)
    u.face:SetFrameLevel(canvas:GetFrameLevel() + 4)
    u.face:SetAllPoints(canvas)
    u.status = u.face:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    u.status:Hide()
    u.tipline = u.face:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.tipline:SetJustifyH("LEFT")
    u.tipline:Hide()
    u.label = u.face:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.label:SetJustifyH("LEFT")
    u.brew = ns.MakeKitButton(canvas)
    u.brew:SetText(ns.T("recipe.brewLabel"))
    u.brew.tip = ns.T("recipe.brewTip")
    u.brew.onClick = function()
        if ns.Loop.IsPaused() then
            ns.Loop.Resume()
            ns.window:RefreshHead()
            return
        end
        if not cur then return end
        if isOver(cur) then return end
        cur:Brew()
    end
    local function border(r, g, b)
        local f = ns.NewFrame("Frame", nil, canvas)
        f:SetFrameLevel(canvas:GetFrameLevel() + 6)
        f:SetBackdrop({ edgeFile = EDGE_TEX, edgeSize = 12 })
        f:SetBackdropBorderColor(r, g, b, 1)
        f:Hide()
        return f
    end
    u.act = border(1, 0.82, 0)
    u.panel = ns.NewFrame("Frame", nil, canvas)
    u.panel:SetFrameLevel(canvas:GetFrameLevel() + 2)
    u.panel:SetWidth(PANEL_W)
    u.panel:Hide()
    u.plate = u.panel:CreateTexture(nil, "BACKGROUND")
    u.plate:SetAllPoints(u.panel)
    fillTex(u.plate, C_COL)
    outline(u.panel, u.panel)
    u.col = ns.NewFrame("Frame", nil, u.panel)
    u.col:SetFrameLevel(u.panel:GetFrameLevel() + 1)
    u.col:SetPoint("TOPLEFT", u.panel, "TOPLEFT", PANEL_PAD, -PANEL_PAD)
    u.col:SetPoint("BOTTOMRIGHT", u.panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
    local function rule(y)
        local t = u.col:CreateTexture(nil, "ARTWORK")
        fillTex(t, C_RULE)
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", u.col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", u.col, "TOPRIGHT", 0, -y)
        return t
    end
    u.tally = ns.MakeScoreboard(u.col, COL_W)
    u.tally:SetPoint("TOPLEFT", u.col, "TOPLEFT", 0, 0)
    u.leftCap = u.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.leftCap:SetPoint("TOPLEFT", u.col, "TOPLEFT", 0, -(ROW * 4 + 22))
    u.leftCap:SetText(ns.T("recipe.leftCap"))
    u.left = u.col:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    u.left:SetJustifyH("RIGHT")
    u.left:SetPoint("RIGHT", u.col, "TOPRIGHT", 0, -(ROW * 5 + 28))
    u.dots = {}
    for i = 1, TRIES do
        local t = u.col:CreateTexture(nil, "OVERLAY")
        t:SetWidth(8)
        t:SetHeight(8)
        t:SetPoint("TOPLEFT", u.col, "TOPLEFT", (i - 1) * 11, -(ROW * 5 + 24))
        u.dots[i] = t
    end
    u.ruleLeft = rule(ROW * 6 + 18)
    local legY = ROW * 6 + 28
    u.legHead = u.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.legHead:SetPoint("TOPLEFT", u.col, "TOPLEFT", 0, -legY)
    u.legHead:SetText(ns.TL(LEG_HEAD))
    local legOff = { 18, 42, 72 }
    u.leg = {}
    for i = 1, #LEGEND do
        local ln = {}
        ln.ic = u.col:CreateTexture(nil, "ARTWORK")
        ln.ic:SetWidth(LEG_ICON)
        ln.ic:SetHeight(LEG_ICON)
        ln.ic:SetTexture(LEGEND[i].tex)
        ln.ic:SetPoint("TOPLEFT", u.col, "TOPLEFT", 0, -(legY + legOff[i]))
        ln.fs = u.col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ln.fs:SetJustifyH("LEFT")
        ln.fs:SetWidth(COL_W - LEG_ICON - 6)
        ln.fs:SetPoint("TOPLEFT", u.col, "TOPLEFT", LEG_ICON + 6, -(legY + legOff[i] + 1))
        ln.fs:SetText(ns.TL(LEGEND[i].t))
        u.leg[i] = ln
    end
    u.ruleAxis = u.col:CreateTexture(nil, "ARTWORK")
    fillTex(u.ruleAxis, C_RULE)
    u.ruleAxis:SetHeight(1)
    u.ruleAxis:SetPoint("BOTTOMLEFT", u.col, "BOTTOMLEFT", 0, NOTE_H + ROW * 2 + 12)
    u.ruleAxis:SetPoint("BOTTOMRIGHT", u.col, "BOTTOMRIGHT", 0, NOTE_H + ROW * 2 + 12)
    u.lvlNote = u.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.lvlNote:SetJustifyH("LEFT")
    u.lvlNote:SetWidth(COL_W)
    u.lvlNote:SetTextColor(0.78, 0.66, 0.36)
    u.lvlNote:SetPoint("BOTTOMLEFT", u.col, "BOTTOMLEFT", 0, 0)
    u.lvlCap = u.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.lvlCap:SetPoint("BOTTOMLEFT", u.col, "BOTTOMLEFT", 0, NOTE_H + ROW + 4)
    u.lvl = ns.MakeStepper(u.col)
    u.lvl:SetWidth(COL_W)
    u.lvl:SetHeight(ROW)
    u.lvl:SetPoint("BOTTOMLEFT", u.col, "BOTTOMLEFT", 0, NOTE_H)
    local function spot(parent)
        local f = ns.NewFrame("Frame", nil, parent)
        f:EnableMouse(false)
        f:Hide()
        return f
    end
    u.spotCode = spot(canvas)
    u.spotRow  = spot(canvas)
    u.spotPal  = spot(canvas)
    u.spotAns  = spot(canvas)
    u.spotLeg  = spot(u.col)
    u.spotLvl  = spot(u.col)
    ns.SlideAnchor("recipe.code", u.spotCode)
    ns.SlideAnchor("recipe.row", u.spotRow)
    ns.SlideAnchor("recipe.pal", u.spotPal)
    ns.SlideAnchor("recipe.ans", u.spotAns)
    ns.SlideAnchor("recipe.legend", u.spotLeg)
    ns.SlideAnchor("recipe.level", u.spotLvl)
    u.spotLeg:SetPoint("TOPLEFT", u.col, "TOPLEFT", -4, -(legY - 4))
    u.spotLeg:SetPoint("TOPRIGHT", u.col, "TOPRIGHT", 4, -(legY - 4))
    u.spotLeg:SetHeight(96)
    u.spotLeg:Show()
    u.spotLvl:SetPoint("BOTTOMLEFT", u.col, "BOTTOMLEFT", -4, -4)
    u.spotLvl:SetPoint("BOTTOMRIGHT", u.col, "BOTTOMRIGHT", 4, -4)
    u.spotLvl:SetHeight(NOTE_H + ROW + 24)
    u.spotLvl:Show()
    u.flash = ns.NewFrame("Frame", nil, canvas)
    u.flash:SetFrameLevel(canvas:GetFrameLevel() + 8)
    u.flash.tex = u.flash:CreateTexture(nil, "OVERLAY")
    u.flash.tex:SetAllPoints(u.flash)
    u.flash.tex:SetTexture(HL_TEX)
    u.flash.tex:SetBlendMode("ADD")
    u.flash:Hide()
    return u
end
function Game:Build()
    local canvas = self.canvas
    ui = ui or buildUI(canvas)
    cellPool = cellPool or ns.NewPool(function() return makeCell(canvas) end, resetCell)
    pegPool = pegPool or ns.NewPool(function()
        local t = ui.face:CreateTexture(nil, "ARTWORK")
        t:SetWidth(ANS_ICON)
        t:SetHeight(ANS_ICON)
        return t
    end)
    cntPool = cntPool or ns.NewPool(function()
        local fs = ui.face:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
        fs:SetJustifyH('LEFT')
        return fs
    end)
    numPool = numPool or ns.NewPool(function()
        local fs = ui.face:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("RIGHT")
        fs:SetWidth(NUMW - 6)
        return fs
    end)
    cellPool:Reset()
    self.cells = {}
    for r = 0, ROWS - 1 do
        local line = {}
        for i = 1, self.p do
            local c = cellPool:Acquire()
            ns.StyleCell(c, r == 0 and "framed" or "plain")
            ns.SizeCell(c, self.cell, r == 0 and 2 or 3)
            c:ClearAllPoints()
            c:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self:MixX(i), self:RowY(r))
            c.bg2:Show()
            c.role, c.rowAt, c.idx = "row", r, i
            c.onClick = cellClick
            line[i] = c
        end
        self.cells[r] = line
    end
    self.pals = {}
    for k = 1, self.c do
        local c = cellPool:Acquire()
        ns.StyleCell(c, "framed")
        ns.SizeCell(c, self.pal, 2)
        c:ClearAllPoints()
        local x, y = self:PalXY(k)
        c:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y)
        c.bg2:Hide()
        c.role, c.rowAt, c.idx = "pal", nil, k
        c.onClick = cellClick
        self.pals[k] = c
    end
    cellPool:HideExtras()
    pegPool:Reset()
    cntPool:Reset()
    self.ans = {}
    for r = 1, ROWS - 1 do
        local line = {}
        for k = 1, 3 do
            local t = pegPool:Acquire()
            t:SetTexture(ANS_TEX[k])
            t:ClearAllPoints()
            t:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
                       self:AnsX(k), self:RowY(r) + math.floor((self.cell - ANS_ICON) / 2))
            t:Hide()
            local fs = cntPool:Acquire()
            fs:ClearAllPoints()
            fs:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
                        self:AnsX(k) + ANS_ICON + 3,
                        self:RowY(r) + math.floor((self.cell - 12) / 2))
            fs:SetText("")
            line[k] = { ic = t, fs = fs }
        end
        self.ans[r] = line
    end
    pegPool:HideExtras()
    cntPool:HideExtras()
    numPool:Reset()
    self.nums = {}
    for r = 1, ROWS - 1 do
        local fs = numPool:Acquire()
        fs:ClearAllPoints()
        fs:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
                    self.ox, self:RowY(r) + math.floor((self.cell - 12) / 2))
        fs:SetText(tostring(r))
        self.nums[r] = fs
    end
    numPool:HideExtras()
    ui.label:ClearAllPoints()
    ui.label:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
                      self:AnsX(1), self:RowY(0) + math.floor((self.cell - 12) / 2))
    ui.label:SetText(ns.T("recipe.codeRowLabel"))
    ui.label:Show()
    ui.act:SetWidth(self.mixW + 6)
    ui.act:SetHeight(self.cell + 6)
    local function spotAt(f, x, y, w, h)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y)
        f:SetWidth(w)
        f:SetHeight(h)
        f:Show()
    end
    spotAt(ui.spotCode, self:MixX(1) - 2, self:RowY(0) - 2, self.mixW + 4, self.cell + 4)
    spotAt(ui.spotRow, self.ox, self:RowY(1) - 2, NUMW + self.mixW + 2, self.cell + 4)
    spotAt(ui.spotPal, self.palX - 4, self.palBottom - 4,
           self.palW + 8, self.top - self.palBottom + 8)
    spotAt(ui.spotAns, self:AnsX(1) - 4, self:RowY(2) - 2,
           ANS_W + 8, self:RowY(1) - self:RowY(2) + self.cell + 4)
    ui.flash:SetWidth(self.mixW + 6)
    ui.flash:SetHeight(self.cell + 6)
    ui.flash:ClearAllPoints()
    ui.flash:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self:MixX(1) - 3, self:RowY(0) - 3)
    local by = self.palBottom - 14 - 22
    ui.brew:ClearAllPoints()
    ui.brew:SetWidth(self.palW)
    ui.brew:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.palX, by)
    ui.brew:Show()
    local plateH = self.top + PLATE_PAD - PLATE_BOT
    ui.rowPlate:ClearAllPoints()
    ui.rowPlate:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", MARGIN, PLATE_BOT)
    ui.rowPlate:SetWidth(self.plateW + PLATE_PAD * 2)
    ui.rowPlate:SetHeight(plateH)
    ui.palPlate:ClearAllPoints()
    ui.palPlate:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.palPlateX, PLATE_BOT)
    ui.palPlate:SetWidth(self.palW + PLATE_PAD * 2)
    ui.palPlate:SetHeight(plateH)
    ui.panel:ClearAllPoints()
    ui.panel:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -MARGIN, PLATE_BOT)
    ui.panel:SetHeight(plateH)
    local fx = self.palPlateX + math.floor((self.palW + PLATE_PAD * 2) / 2)
    local ax, bx = fx - 24, fx + 14
    local fl = {
        { ax - 13, 30, 26, 16 }, { ax - 9, 46, 18, 10 },
        { ax - 4,  56,  8, 14 }, { ax - 6, 70, 12,  4 },
        { bx - 11, 30, 22, 14 }, { bx - 7, 44, 14,  8 },
        { bx - 4,  52,  8, 12 }, { bx - 5, 64, 10,  4 },
        { ax - 2, 86, 3, 3 }, { bx, 78, 3, 3 }, { fx - 4, 100, 2, 2 },
    }
    for i = 1, 11 do
        local t = ui.flask[i]
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", fl[i][1], fl[i][2])
        t:SetWidth(fl[i][3])
        t:SetHeight(fl[i][4])
    end
    local sx = MARGIN + PLATE_PAD
    ui.status:ClearAllPoints()
    ui.status:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", sx, PLATE_BOT + 24)
    ui.tipline:ClearAllPoints()
    ui.tipline:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", sx, PLATE_BOT + 6)
    ui.tipline:SetWidth(self.plateW)
    ui.lvlNote:SetText(ns.TL(self.lv.rep and REP_YES or REP_NO))
    ui.deco:Show()
    ui.face:Show()
    ui.panel:Show()
    self._panelLock = nil
    ui._left = nil
end
local function touch(c, item, hot)
    c.tipItem = item
    c:EnableMouse((item ~= nil) or hot)
    if hot then
        c:SetHighlightTexture(HL_TEX, "ADD")
    else
        ns.Compat.ClearHighlight(c)
    end
end
function Game:Draw()
    if not self.cells then return end
    local canvas = self.canvas
    local act = self:ActiveRow()
    local free = (not isOver(self)) and firstFree(self) or nil
    for i = 1, self.p do
        local c = self.cells[0][i]
        fillCell(c, BG_CODE)
        if isOver(self) then
            c.icon:SetTexture(self.tex[self.code[i]])
            c:SetAlpha(1)
            touch(c, nil, false)
        else
            c.icon:SetTexture(ns.Icons.QMARK)
            c:SetAlpha(0.75)
            touch(c, nil, false)
        end
        c.sel:Hide()
    end
    for r = 1, ROWS - 1 do
        local row = self.rows[r]
        local isAct = (r == act)
        for i = 1, self.p do
            local c = self.cells[r][i]
            if row then
                fillCell(c, BG_DONE)
                c.icon:SetTexture(self.tex[row.mix[i]])
                touch(c, nil, false)
                c.sel:Hide()
            elseif isAct then
                fillCell(c, BG_ACT)
                local v = self.mix[i]
                c.icon:SetTexture(v ~= 0 and self.tex[v] or nil)
                touch(c, nil, v ~= 0)
                if i == free then c.sel:Show() else c.sel:Hide() end
            else
                fillCell(c, BG_EMPTY)
                c.icon:SetTexture(nil)
                touch(c, nil, false)
                c.sel:Hide()
            end
        end
        self:Answer(r, row)
        local fs = self.nums[r]
        if isAct then fs:SetTextColor(1, 0.82, 0)
        elseif row then fs:SetTextColor(0.7, 0.65, 0.55)
        else fs:SetTextColor(0.4, 0.38, 0.34) end
    end
    for k = 1, self.c do
        local c = self.pals[k]
        fillTex(c.bg, PAL_BG)
        c.icon:SetTexture(self.tex[k])
        c:SetAlpha(isOver(self) and 0.4 or 1)
        ns.CellCount(c, k)
        touch(c, nil, not isOver(self))
    end
    if act then
        ui.act:ClearAllPoints()
        ui.act:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self:MixX(1) - 3, self:RowY(act) - 3)
        ui.act:Show()
    else
        ui.act:Hide()
    end
    if isOver(self) then
        ui.brew:Disable()
        ui.brew.tipDim = nil
    elseif not full(self) then
        ui.brew:Disable()
        ui.brew.tipDim = ns.T("recipe.brewTipDim")
    else
        ui.brew:Enable()
        ui.brew.tipDim = nil
    end
    local left = TRIES - #self.rows
    if ui._left ~= left then
        ui._left = left
        ui.left:SetText(tostring(left))
        for i = 1, TRIES do
            fillTex(ui.dots[i], i <= #self.rows and C_DOT_OFF or C_DOT_ON)
        end
    end
    self:Status()
end
function Game:Answer(r, row)
    local line = self.ans[r]
    if not row then
        for k = 1, 3 do
            line[k].ic:Hide()
            line[k].fs:SetText("")
        end
        return
    end
    local n = { row.hit, row.near, self.p - row.hit - row.near }
    for k = 1, 3 do
        local g = line[k]
        g.ic:SetAlpha(n[k] > 0 and 1 or 0.25)
        g.ic:Show()
        g.fs:SetText(tostring(n[k]))
        if n[k] > 0 then g.fs:SetTextColor(1, 1, 1) else g.fs:SetTextColor(0.4, 0.38, 0.34) end
    end
end
function Game:Status()
    ui.status:Show()
    ui.tipline:Show()
    if isOver(self) then
        if self.won then
            ui.status:SetText(ns.T("recipe.statusWon", #self.rows))
        else
            ui.status:SetText(ns.T("recipe.statusLost"))
        end
        ui.tipline:SetText(ns.T("recipe.tipOver"))
        return
    end
    ui.status:SetText("")
    ui.tipline:SetText(self.note or "")
end
local function putLevel(it)
    ui.lvlCap:SetText(it.label or "")
    ui.lvl:SetSpec(it)
    if it.disabled then ui.lvl:Disable() else ui.lvl:Enable() end
    ui.lvl:Restyle()
end
function Game:PanelSync()
    if not ui or ns.Loop.Current() ~= self then return end
    ui.tally:Sync()
    local locked = ns.window:AxisLocked()
    if self._panelLock == locked then return end
    self._panelLock = locked
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.kind == "step" then putLevel(it) end
    end
end
function Game:Relocalize()
    if not ui then return end
    ui.brew:SetText(ns.T("recipe.brewLabel"))
    ui.brew.tip = ns.T("recipe.brewTip")
    ui.leftCap:SetText(ns.T("recipe.leftCap"))
    ui.legHead:SetText(ns.TL(LEG_HEAD))
    for i = 1, #LEGEND do
        ui.leg[i].fs:SetText(ns.TL(LEGEND[i].t))
    end
    ui.label:SetText(ns.T("recipe.codeRowLabel"))
    if self.lv then ui.lvlNote:SetText(ns.TL(self.lv.rep and REP_YES or REP_NO)) end
    self._panelLock = nil
    self:PanelSync()
    self:Draw()
end
function Game:Flash()
    if not ui then return end
    local k = (self.t - (self.overAt or 0)) / WIN_FLASH
    if k < 0 or k > 1 then
        ui.flash:Hide()
        return
    end
    local a = (k < 0.2) and (k / 0.2) or ((1 - k) / 0.8)
    ui.flash.tex:SetAlpha(a * 0.7)
    ui.flash:Show()
end
local MINI_RED    = { 0.95, 0.25, 0.30 }
local MINI_GREEN  = { 0.35, 0.90, 0.40 }
local MINI_BLUE   = { 0.25, 0.60, 1.00 }
local MINI_YELLOW = { 1.00, 0.88, 0.25 }
local MINI_HIT    = { 0.40, 0.85, 0.45 }
local MINI_NEAR   = { 0.95, 0.78, 0.25 }
local MINI = {
    {
        cols = 4, rows = 2, cell = 32, gap = 5,
        fill = {
            { c = 1, r = 2, col = MINI_RED }, { c = 2, r = 2, col = MINI_GREEN },
            { c = 3, r = 2, col = MINI_BLUE }, { c = 4, r = 2, col = MINI_YELLOW },
            { c = 1, r = 1, col = MINI_GREEN }, { c = 2, r = 1, col = MINI_RED },
            { c = 3, r = 1, col = MINI_BLUE }, { c = 4, r = 1, col = MINI_YELLOW },
        },
        dot = {
            { c = 1, r = 1, col = MINI_NEAR }, { c = 2, r = 1, col = MINI_NEAR },
            { c = 3, r = 1, col = MINI_HIT }, { c = 4, r = 1, col = MINI_HIT },
        },
    },
    {
        cols = 4, rows = 2, cell = 32, gap = 5,
        fill = {
            { c = 1, r = 2, col = MINI_RED }, { c = 2, r = 2, col = MINI_GREEN },
            { c = 3, r = 2, col = MINI_BLUE }, { c = 4, r = 2, col = MINI_BLUE },
            { c = 1, r = 1, col = MINI_RED }, { c = 2, r = 1, col = MINI_RED },
            { c = 3, r = 1, col = MINI_RED }, { c = 4, r = 1, col = MINI_GREEN },
        },
        dot = {
            { c = 1, r = 1, col = MINI_HIT }, { c = 4, r = 1, col = MINI_NEAR },
        },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    for _, m in ipairs(spec.fill) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.dot) do g:Dot(m.c, m.r, m.col) end
end
local function helpAnswer(host) paintMini(host, MINI[1]) end
local function helpRepeat(host) paintMini(host, MINI[2]) end
ns.RegisterGame{
    id = ID,
    label = "recipe.label",
    icon = { tex = TILE_TEX, coord = { 0.07, 0.93, 0.07, 0.93 } },
    tip = "recipe.tip",
    order = 7,
    duo = "score",
    physics = false,
    done = true,
    ownPanel = true,
    finale = true,
    look = LOOK,
    New = New,
    opts = {
        { key = "level", label = "recipe.optLevelLabel", def = DEFAULT_LEVEL,
          ordered = true, options = LEVELS,
          tip = "recipe.optLevelTip" },
    },
    record = false,
    tally = false,
    keymap = {
        ["1"] = "gem1", ["2"] = "gem2", ["3"] = "gem3", ["4"] = "gem4",
        ["5"] = "gem5", ["6"] = "gem6", ["7"] = "gem7", ["8"] = "gem8",
        SPACE = "fire", BACKSPACE = "back",
    },
    controls = {
        { action = "gem1", label = "recipe.ctlGem",  keys = "recipe.ctlGemKeys", mouse = "LMB", where = "recipe.ctlOnGem" },
        { action = "back", label = "recipe.ctlBack", mouse = "LMB", where = "recipe.ctlOnMix" },
        { action = "fire", label = "recipe.ctlBrew", mouse = "LMB", where = "recipe.ctlOnCauldron" },
    },
    slides = ns.recipeSlides,
    help = {
        "recipe.help1",
        "recipe.help2",
        "recipe.help3",
        "recipe.help4",
        "recipe.help5",
        { art = helpAnswer, h = 77, sub = "recipe.help5Sub" },
        "recipe.help6",
        "recipe.help7",
        "recipe.help8",
        { art = helpRepeat, h = 77, sub = "recipe.help8Sub" },
        "recipe.help9",
    },
}
