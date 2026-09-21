local ADDON, ns = ...
local ID = "slide"
local GAP = 4
local SEAM = 0.9
local MIX = 40
local MARGIN    = 14
local VMARGIN   = 19
local ZONE      = 442
local BAGUETTE  = 13
local INNER     = ZONE - BAGUETTE * 2
local PANEL_W   = 156
local PANEL_PAD = 12
local COL_W     = PANEL_W - PANEL_PAD * 2
local ROW       = 22
local MINI_SIZE = COL_W
local ACT_W     = (COL_W - 4) / 2
local WELL      = 3
local EDGE_IN   = 2
local CELL_UP = 2
local SCREEN_TEX = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local C_WALL = { 0.195, 0.150, 0.095 }
local C_MAT = { 0.300, 0.235, 0.150 }
local C_BED   = { 0.050, 0.044, 0.038 }
local C_FRAME = { 0.58, 0.47, 0.28 }
local C_PIT   = { 0.028, 0.024, 0.020 }
local C_PIT_E = { 0.230, 0.190, 0.150 }
local C_PLATE = { 0.145, 0.112, 0.072 }
local C_RULE  = { 0.260, 0.210, 0.150 }
local C_TAG = { 0.055, 0.050, 0.044, 1 }
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local BACK_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local VAL_FONT = "Fonts\\FRIZQT__.TTF"
local VAL_SIZE = 16
local TAG_FONT = "Fonts\\ARIALN.TTF"
local EDGE_A      = 0.9
local EDGE_DARK_A = 0.55
local BLANK = { 0.22, 0.26, 0.32 }
local LOOK = ns.MakeLook{ wood = C_WALL, edge = C_FRAME, screen = C_WALL }
local SETS, SET_KEY, SQUEEZE = {}, {}, {}
local MENU_PIC
do
    local shelf = ns.slideShelf or {}
    for _, it in ipairs(shelf.sets or {}) do
        SETS[#SETS + 1] = it.key
        SET_KEY[it.key] = it.label
        if it.squeeze then SQUEEZE[it.key] = it.squeeze end
    end
    local m = shelf.menu or {}
    MENU_PIC = ns.Pics.Path(m.set, m.file)
end
local function window(w, h, k)
    k = k or 1
    w, h = (w or 1) * k, (h or 1)
    local side = (w < h) and w or h
    local fw, fh = side / w, side / h
    return (1 - fw) / 2, (1 + fw) / 2, (1 - fh) / 2, (1 + fh) / 2
end
local function keyOf(set, p) return set .. "|" .. (p.f or "") end
local function picByKey(key)
    if type(key) ~= "string" then return nil end
    local set, file = key:match("^([^|]+)|(.+)$")
    if not set then return nil end
    for _, p in ipairs(ns.Pics.List(set)) do
        if p.f == file then return set, p end
    end
    return nil
end
local flat
local function allPics()
    if flat then return flat end
    flat = {}
    for _, set in ipairs(SETS) do
        for _, p in ipairs(ns.Pics.List(set)) do
            flat[#flat + 1] = { set = set, p = p }
        end
    end
    return flat
end
local function solvedSet()
    local s = ns.Config.Get(ID, "solved", nil)
    return type(s) == "table" and s or {}
end
local function markSolved(key)
    if type(key) ~= "string" then return end
    local s = solvedSet()
    if s[key] then return end
    s[key] = true
    ns.Config.Set(ID, "solved", s)
end
local SIZES = {
    { key = "3x3", n = 3, tip = "slide.size3x3Tip" },
    { key = "4x4", n = 4, tip = "slide.size4x4Tip" },
    { key = "5x5", n = 5, tip = "slide.size5x5Tip" },
    { key = "6x6", n = 6, tip = "slide.size6x6Tip" },
}
local DEF_SIZE = "5x5"
local pool, view, picker
local Game = {}
Game.__index = Game
local function live()
    local g = ns.Loop.Current()
    if g and g.def and g.def.id == ID then return g end
    return nil
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
local function rowcol(n, i)
    local r = math.floor((i - 1) / n) + 1
    return r, i - (r - 1) * n
end
local function legal(self, i)
    if i == self.hole then return false end
    local hr, hc = rowcol(self.n, self.hole)
    local ir, ic = rowcol(self.n, i)
    return hr == ir or hc == ic
end
local function slide(self, i)
    local n, h = self.n, self.hole
    local hr, hc = rowcol(n, h)
    local ir, ic = rowcol(n, i)
    local step, count
    if hr == ir then
        step = (hc < ic) and 1 or -1
        count = math.abs(ic - hc)
    elseif hc == ic then
        step = (hr < ir) and n or -n
        count = math.abs(ir - hr)
    else
        return 0
    end
    local p = h
    for _ = 1, count do
        self.tile[p] = self.tile[p + step]
        p = p + step
    end
    self.tile[p] = 0
    self.hole = p
    return count
end
local function complete(self)
    for i = 1, self.n * self.n - 1 do
        if self.tile[i] ~= i then return false end
    end
    return true
end
local function mix(self)
    local n = self.n
    local cand, prev = {}, 0
    for _ = 1, MIX * n * n do
        local h = self.hole
        local hr, hc = rowcol(n, h)
        local m = 0
        if hr > 1 and h - n ~= prev then m = m + 1; cand[m] = h - n end
        if hr < n and h + n ~= prev then m = m + 1; cand[m] = h + n end
        if hc > 1 and h - 1 ~= prev then m = m + 1; cand[m] = h - 1 end
        if hc < n and h + 1 ~= prev then m = m + 1; cand[m] = h + 1 end
        prev = h
        slide(self, cand[self.rng:Int(m)])
    end
end
local function deal(self)
    local n2 = self.n * self.n
    self.tile = {}
    for i = 1, n2 - 1 do self.tile[i] = i end
    self.tile[n2] = 0
    self.hole = n2
    mix(self)
end
local function apply(self, move)
    if self.done then return 0 end
    if type(move) ~= "table" or move.k ~= "slide" then return 0 end
    local i = move.i
    if type(i) ~= "number" or i < 1 or i > self.n * self.n then return 0 end
    if not legal(self, i) then return 0 end
    local moved = slide(self, i)
    self.steps = self.steps + moved
    if complete(self) then
        self.done = true
        self.seamT = 0
        self.showcase = false
    end
    return moved
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    self.sizeDef = byKey(SIZES, self.opts and self.opts.size, DEF_SIZE)
    self.n = self.sizeDef.n
    self.rng = ns.RNG.New(seed)
    self.seed = seed
    self:UsePicture(ns.Config.Get(ID, "pic", nil))
    self.steps = 0
    self.done = false
    self.seamT = 0
    self.showcase = false
    self.numbers = ns.Config.Get(ID, "numbers", true) and true or false
    self.hover = nil
    deal(self)
    if moves then
        for i = 1, #moves do apply(self, moves[i]) end
    end
    self:Layout()
    self:Build()
    self:Draw()
end
function Game:Layout()
    local n = self.n
    self.cell = ns.CellFit(n, INNER, GAP, CELL_UP)
    self.side = n * self.cell + (n - 1) * GAP
    local off = math.floor((INNER - self.side) / 2)
    self.ox = MARGIN + BAGUETTE + off
    self.oy = VMARGIN + BAGUETTE + off
end
function Game:CellXY(i)
    local r, c = rowcol(self.n, i)
    local step = self.cell + GAP
    return self.ox + (c - 1) * step, self.oy + (self.n - r) * step
end
function Game:CellAt(x, y)
    local step = self.cell + GAP
    local dx = x - self.ox
    local col = math.floor(dx / step) + 1
    if col < 1 or col > self.n then return nil end
    if dx - (col - 1) * step > self.cell then return nil end
    local dy = y - self.oy
    local up = math.floor(dy / step) + 1
    if up < 1 or up > self.n then return nil end
    if dy - (up - 1) * step > self.cell then return nil end
    return (self.n - up) * self.n + col
end
function Game:Move(move)
    if apply(self, move) == 0 then return false end
    if self.done then
        markSolved(self.picKey)
        ns.Config.Set(ID, "pic", nil)
    end
    ns.Sfx.Play(self.done and "clear" or "pick")
    self:Draw()
    return true
end
function Game:Click(x, y)
    if self.showcase or self.done then return end
    if picker and picker:IsShown() then return end
    local i = self:CellAt(x, y)
    if not i or i == self.hole then return end
    if not legal(self, i) then return end
    self:Move{ k = "slide", i = i }
end
function Game:Key(action, down)
    if not down or self.showcase or self.done then return end
    if picker and picker:IsShown() then return end
    local n, h = self.n, self.hole
    local hr, hc = rowcol(n, h)
    local i
    if action == "left" and hc < n then i = h + 1
    elseif action == "right" and hc > 1 then i = h - 1
    elseif action == "up" and hr < n then i = h + n
    elseif action == "down" and hr > 1 then i = h - n
    end
    if i then self:Move{ k = "slide", i = i } end
end
local function seam(self)
    if not self.done then return 0 end
    local p = (self.seamT or SEAM) / SEAM
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    return p * p * (3 - 2 * p)
end
function Game:Update(dt)
    self:Hover()
    if not self.done then return end
    if (self.seamT or SEAM) >= SEAM then return end
    self.seamT = (self.seamT or 0) + dt
    self:Draw()
end
function Game:Score()
    return 0
end
function Game:Brink()
    local n2 = self.n * self.n
    for i = 1, n2 - 1 do self.tile[i] = i end
    self.tile[n2] = 0
    self.hole = n2
    slide(self, n2 - 1)
    self.done = false
    self.seamT = 0
end
function Game:Relocalize()
    self._panelLock = nil
    self:PanelSync()
    self:ShowPicture()
    if picker and picker:IsShown() then picker.Open(picker.set, picker.page) end
end
function Game:IsOver()
    return self.done and true or false
end
function Game:Stop()
    if pool then pool:HideAll() end
    if view then
        view.deco:Hide()
        view.field:Hide()
        view.panel:Hide()
        view.hl:Hide()
        view.shot:Hide()
        view.note:Hide()
        view.noteOn = false
    end
    if picker then picker:Hide() end
    self.frames = nil
end
function Game:UsePicture(key)
    local set, pic = picByKey(key)
    if not pic then
        local list = allPics()
        if #list > 0 then
            local roll = ns.RNG.New(self.seed)
            roll:Float()
            local it = list[roll:Int(#list)]
            set, pic = it.set, it.p
        end
    end
    self.set, self.pic = set, pic
    self.picKey = pic and keyOf(set, pic) or nil
    self.picPath = pic and ns.Pics.Path(set, pic.f) or nil
    if pic then
        self.picL, self.picR, self.picT, self.picB =
            window(pic.w, pic.h, SQUEEZE[set])
    else
        self.picL, self.picR, self.picT, self.picB = 0, 1, 0, 1
    end
end
function Game:Repaint()
    for k, c in pairs(self.frames or {}) do self:Face(c, k) end
    self:ShowPicture()
    self:Showcase()
end
function Game:ShowPicture()
    if not view then return end
    if self.pic then
        view.mini.icon:SetTexture(self.picPath)
        view.mini.icon:SetTexCoord(self.picL, self.picR, self.picT, self.picB)
        view.place:SetText(ns.Pics.Label(self.pic))
        view.mini.tipTitle = ns.Pics.Label(self.pic)
    else
        view.mini.icon:SetTexture(BLANK[1], BLANK[2], BLANK[3])
        view.mini.icon:SetTexCoord(0, 1, 0, 1)
        view.place:SetText("")
        view.mini.tipTitle = false
    end
end
function Game:Peek()
    self.showcase = not self.showcase
    self:SyncActions()
    self:Draw()
end
function Game:Numbers()
    self.numbers = not self.numbers
    ns.Config.Set(ID, "numbers", self.numbers)
    self:SyncActions()
    for k = 1, self.n * self.n - 1 do
        local c = self.frames and self.frames[k]
        if c then self:Tag(c, self.pic and k or nil) end
    end
end
function Game:SyncActions()
    if not view then return end
    view.picBtn.active = self.showcase
    view.numBtn.active = self.numbers
    ns.StyleButton(view.picBtn)
    ns.StyleButton(view.numBtn)
end
local function makeTile(parent)
    local c = ns.MakeCell(parent)
    c:EnableMouse(false)
    c:SetFrameLevel(parent:GetFrameLevel() + 2)
    c.over:SetFrameLevel(c:GetFrameLevel() + 1)
    c.tag = c.over:CreateTexture(nil, "BACKGROUND")
    c.tag:SetTexture(C_TAG[1], C_TAG[2], C_TAG[3], C_TAG[4])
    c.tag:Hide()
    c.tagText = c.over:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.tagText:SetPoint("CENTER", c.tag, "CENTER", 0, 0)
    c.tagText:Hide()
    return c
end
local function resetTile(c)
    ns.ResetCell(c)
    c.tag:Hide()
    c.tagText:Hide()
    c.over:SetAlpha(1)
end
local function ensureView(canvas)
    if view then return end
    view = {}
    view.deco = CreateFrame("Frame", nil, canvas)
    view.deco:SetFrameLevel(canvas:GetFrameLevel())
    view.deco:SetAllPoints(canvas)
    view.deco:Hide()
    local scr = ns.window:ScreenFill(view.deco)
    scr:SetTexture(SCREEN_TEX)
    scr:SetVertexColor(C_WALL[1], C_WALL[2], C_WALL[3], 1)
    view.field = CreateFrame("Frame", nil, canvas)
    view.field:SetFrameLevel(canvas:GetFrameLevel() + 1)
    view.field:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = BAGUETTE,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    view.field:SetBackdropColor(C_MAT[1], C_MAT[2], C_MAT[3], 1)
    view.field:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], 1)
    view.field:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", MARGIN - EDGE_IN, VMARGIN - EDGE_IN)
    view.field:SetWidth(ZONE + EDGE_IN * 2)
    view.field:SetHeight(ZONE + EDGE_IN * 2)
    view.field:Hide()
    view.well = view.field:CreateTexture(nil, "OVERLAY")
    view.well:SetTexture(C_BED[1], C_BED[2], C_BED[3], 1)
    view.deck = CreateFrame("Frame", nil, view.field)
    view.deck:SetFrameLevel(view.field:GetFrameLevel() + 1)
    view.bed = view.deck:CreateTexture(nil, "BACKGROUND")
    view.bed:SetAllPoints(view.deck)
    view.bed:SetTexture(C_BED[1], C_BED[2], C_BED[3], 1)
    view.pit = CreateFrame("Frame", nil, view.deck)
    view.pit:SetFrameLevel(view.deck:GetFrameLevel() + 1)
    view.pit:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    view.pit:SetBackdropColor(C_PIT[1], C_PIT[2], C_PIT[3], 1)
    view.pit:SetBackdropBorderColor(C_PIT_E[1], C_PIT_E[2], C_PIT_E[3], 1)
    view.pit:Hide()
    view.hl = CreateFrame("Frame", nil, canvas)
    view.hl:SetAllPoints(canvas)
    view.hl:SetFrameLevel(canvas:GetFrameLevel() + 6)
    view.hl.dark, view.hl.light = {}, {}
    for k = 1, 4 do
        view.hl.dark[k] = view.hl:CreateTexture(nil, "ARTWORK")
        view.hl.dark[k]:SetTexture(0, 0, 0, EDGE_DARK_A)
        view.hl.light[k] = view.hl:CreateTexture(nil, "OVERLAY")
        view.hl.light[k]:SetTexture(1, 1, 1, EDGE_A)
    end
    view.hl:Hide()
    view.shot = CreateFrame("Frame", nil, canvas)
    view.shot:SetFrameLevel(canvas:GetFrameLevel() + 8)
    view.shot.art = view.shot:CreateTexture(nil, "ARTWORK")
    view.shot.art:SetAllPoints(view.shot)
    view.shot:Hide()
    view.panel = CreateFrame("Frame", nil, canvas)
    view.panel:SetFrameLevel(canvas:GetFrameLevel() + 2)
    view.panel:SetWidth(PANEL_W)
    view.panel:SetHeight(ZONE)
    view.panel:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -MARGIN, VMARGIN)
    view.panelEdge = view.panel:CreateTexture(nil, "BACKGROUND")
    view.panelEdge:SetAllPoints(view.panel)
    view.panelEdge:SetTexture(C_FRAME[1] * 0.55, C_FRAME[2] * 0.55, C_FRAME[3] * 0.55, 1)
    view.plate = view.panel:CreateTexture(nil, "BORDER")
    view.plate:SetPoint("TOPLEFT", view.panel, "TOPLEFT", 1, -1)
    view.plate:SetPoint("BOTTOMRIGHT", view.panel, "BOTTOMRIGHT", -1, 1)
    view.plate:SetTexture(C_PLATE[1], C_PLATE[2], C_PLATE[3], 1)
    view.col = CreateFrame("Frame", nil, view.panel)
    view.col:SetFrameLevel(view.panel:GetFrameLevel() + 1)
    view.col:SetPoint("TOPLEFT", view.panel, "TOPLEFT", PANEL_PAD, -PANEL_PAD)
    view.col:SetPoint("BOTTOMRIGHT", view.panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
    local function stat(y, key)
        local cap = view.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("LEFT", view.col, "TOPLEFT", 0, -(y + ROW / 2))
        ns.SetKeyText(cap, key)
        local val = view.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetFont(VAL_FONT, VAL_SIZE, "")
        val:SetJustifyH("RIGHT")
        val:SetPoint("RIGHT", view.col, "TOPRIGHT", 0, -(y + ROW / 2))
        return cap, val
    end
    local function rule(y)
        local t = view.col:CreateTexture(nil, "ARTWORK")
        t:SetTexture(C_RULE[1], C_RULE[2], C_RULE[3], 1)
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", view.col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", view.col, "TOPRIGHT", 0, -y)
    end
    view.tally = ns.MakeScoreboard(view.col, COL_W)
    view.tally:SetPoint("TOPLEFT", view.col, "TOPLEFT", 0, 0)
    view.note = CreateFrame("Frame", nil, canvas)
    view.note:SetFrameLevel(canvas:GetFrameLevel() + 7)
    view.note:SetHeight(ROW * 2)
    view.notePlate = view.note:CreateTexture(nil, "BACKGROUND")
    view.notePlate:SetAllPoints(view.note)
    view.notePlate:SetTexture(0, 0, 0, 0.7)
    view.note:Hide()
    view.tally.duo:ClearAllPoints()
    view.tally.duo:SetJustifyH("CENTER")
    view.tally.duo:SetPoint("TOP", view.note, "TOP", 0, -3)
    view.bestCap, view.best = stat(ROW + 4, "slide.colBest")
    rule(ROW * 2 + 8)
    view.movesCap, view.moves = stat(ROW * 2 + 14, "slide.colMoves")
    view.placedCap, view.placed = stat(ROW * 3 + 14, "slide.colPlaced")
    view.size = ns.MakeStepper(view.col)
    view.size:SetWidth(COL_W)
    view.size:SetHeight(ROW)
    view.size:SetPoint("BOTTOMLEFT", view.col, "BOTTOMLEFT", 0, 0)
    view.sizeCap = view.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.sizeCap:SetPoint("BOTTOMLEFT", view.col, "BOTTOMLEFT", 0, ROW + 4)
    local ruleAxis = view.col:CreateTexture(nil, "ARTWORK")
    ruleAxis:SetTexture(C_RULE[1], C_RULE[2], C_RULE[3], 1)
    ruleAxis:SetHeight(1)
    ruleAxis:SetPoint("BOTTOMLEFT", view.col, "BOTTOMLEFT", 0, ROW * 2 + 6)
    ruleAxis:SetPoint("BOTTOMRIGHT", view.col, "BOTTOMRIGHT", 0, ROW * 2 + 6)
    local function action(x, label, tip, method)
        local b = ns.MakeKitButton(view.col)
        b:SetWidth(ACT_W)
        b:SetHeight(ROW)
        b:SetPoint("BOTTOMLEFT", view.col, "BOTTOMLEFT", x, ROW * 2 + 12)
        ns.SetKeyText(b, label)
        ns.SetKeyTip(b, tip)
        b.onClick = function()
            local g = live()
            if g then g[method](g) end
        end
        return b
    end
    view.numBtn = action(0, "slide.barNumbersLabel", "slide.barNumbersTip", "Numbers")
    view.picBtn = action(ACT_W + 4, "slide.barShowcaseLabel", "slide.barShowcaseTip", "Peek")
    view.mini = ns.MakeCell(view.col)
    ns.StyleCell(view.mini, "framed")
    view.mini:SetWidth(MINI_SIZE)
    view.mini:SetHeight(MINI_SIZE)
    view.mini:SetPoint("BOTTOM", view.col, "BOTTOM", 0, ROW * 5 + 2)
    view.mini.onClick = function()
        local g = live()
        if g then g:PickPicture() end
    end
    view.place = view.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.place:SetPoint("TOP", view.col, "BOTTOM", 0, ROW * 5 - 4)
    view.place:SetWidth(COL_W)
    view.place:SetJustifyH("CENTER")
    view.place:SetTextColor(0.90, 0.86, 0.78)
    view.panel:Hide()
end
function Game:Tag(c, k)
    if not k or not self.numbers then
        c.tag:Hide()
        c.tagText:Hide()
        return
    end
    local px = math.floor(self.cell * 0.16)
    if px < 9 then px = 9 elseif px > 14 then px = 14 end
    if not c.tagText:SetFont(TAG_FONT, px, "") then
        c.tagText:SetFont((c.tagText:GetFont()), px, "")
    end
    c.tagText:SetText(k)
    c.tag:ClearAllPoints()
    c.tag:SetWidth(math.floor(px * 1.55) + 6)
    c.tag:SetHeight(px + 5)
    c.tag:SetPoint("TOPLEFT", c, "TOPLEFT", 3, -3)
    c.tag:Show()
    c.tagText:Show()
end
function Game:Face(c, k)
    local n = self.n
    local r, col = rowcol(n, k)
    ns.StyleCell(c, "plain")
    c:SetWidth(self.cell)
    c:SetHeight(self.cell)
    if self.pic then
        local wide = (self.picR - self.picL) / n
        local tall = (self.picB - self.picT) / n
        c.icon:SetTexture(self.picPath)
        c.icon:SetTexCoord(self.picL + (col - 1) * wide, self.picL + col * wide,
                           self.picT + (r - 1) * tall, self.picT + r * tall)
        ns.CellCenter(c, nil)
        self:Tag(c, k)
    else
        c.icon:SetTexture(BLANK[1], BLANK[2], BLANK[3])
        c.icon:SetTexCoord(0, 1, 0, 1)
        self:Tag(c, nil)
        ns.CellCenter(c, tostring(k))
    end
end
function Game:Build()
    local canvas = self.canvas
    ensureView(canvas)
    view.field:Show()
    local inset = self.ox - MARGIN + EDGE_IN
    view.deck:ClearAllPoints()
    view.deck:SetPoint("BOTTOMLEFT", view.field, "BOTTOMLEFT", inset, inset)
    view.deck:SetWidth(self.side)
    view.deck:SetHeight(self.side)
    view.well:ClearAllPoints()
    view.well:SetPoint("BOTTOMLEFT", view.field, "BOTTOMLEFT", inset - WELL, inset - WELL)
    view.well:SetWidth(self.side + WELL * 2)
    view.well:SetHeight(self.side + WELL * 2)
    pool = pool or ns.NewPool(function() return makeTile(view.deck) end, resetTile)
    pool:Reset()
    self.frames = {}
    for k = 1, self.n * self.n do
        local c = pool:Acquire()
        self:Face(c, k)
        self.frames[k] = c
    end
    self:Tag(self.frames[self.n * self.n], nil)
    self.frames[self.n * self.n]:Hide()
    pool:HideExtras()
    view.pit:SetWidth(self.cell)
    view.pit:SetHeight(self.cell)
    view.note:ClearAllPoints()
    view.note:SetPoint("TOP", view.deck, "TOP", 0, 0)
    view.note:SetWidth(self.side)
    view.tally.duo:SetWidth(self.side - 16)
    self:ShowPicture()
    local best = ns.Records.Best(ID, self.opts)
    local mark = ns.Records.Main(self.def)
    view.best:SetText(best and ns.Records.Format(mark, best[mark.key]) or "—")
    view.deco:Show()
    view.panel:Show()
    self:SyncActions()
    self._panelLock = nil
end
function Game:Draw()
    if not self.frames then self:Build() end
    local n = self.n
    local p = seam(self)
    local gap = GAP * (1 - p)
    local cell = (self.side - (n - 1) * gap) / n
    local step = cell + gap
    for i = 1, n * n do
        local v = self.tile[i]
        local f, filler
        if v == 0 then
            filler = (p > 0)
            f = filler and self.frames[n * n] or view.pit
        else
            f = self.frames[v]
        end
        local r, c = rowcol(n, i)
        f:SetWidth(cell)
        f:SetHeight(cell)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", view.deck, "BOTTOMLEFT", (c - 1) * step, (n - r) * step)
        f:SetAlpha(filler and p or 1)
        f:Show()
        if f.over then f.over:SetAlpha(1 - p) end
    end
    if p > 0 then view.pit:Hide() else view.pit:Show() end
    self:Readout()
    self:Showcase()
end
function Game:Readout()
    view.moves:SetText(self.steps)
    local last = self.n * self.n - 1
    local placed = 0
    for i = 1, last do
        if self.tile[i] == i then placed = placed + 1 end
    end
    view.placed:SetText(ns.T("slide.placedFmt", placed, last))
end
function Game:Showcase()
    if not self.showcase or not self.pic then
        view.shot:Hide()
        return
    end
    view.shot:ClearAllPoints()
    view.shot:SetPoint("BOTTOMLEFT", view.deck, "BOTTOMLEFT", 0, 0)
    view.shot:SetWidth(self.side)
    view.shot:SetHeight(self.side)
    view.shot.art:SetTexture(self.picPath)
    view.shot.art:SetTexCoord(self.picL, self.picR, self.picT, self.picB)
    view.shot:Show()
end
function Game:PanelSync()
    if not view or ns.Loop.Current() ~= self then return end
    view.tally:Sync()
    local said = view.tally.duo:GetText() or ""
    if (said ~= "") ~= view.noteOn then
        view.noteOn = (said ~= "")
        if view.noteOn then view.note:Show() else view.note:Hide() end
    end
    local locked = ns.window:AxisLocked()
    if self._panelLock == locked then return end
    self._panelLock = locked
    view.mini.tip = locked and ns.T("slide.pickLocked") or ns.T("slide.pickTip")
    local glow = view.mini:GetHighlightTexture()
    if glow then glow:SetAlpha(locked and 0 or 1) end
    if locked and picker then picker:Hide() end
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.kind == "step" then
            view.sizeCap:SetText(it.label or "")
            view.size:SetSpec(it)
            if it.disabled then view.size:Disable() else view.size:Enable() end
            view.size:Restyle()
        end
    end
end
local function frame(set, x, y, w, h, t)
    local function line(k, lx, ly, lw, lh)
        local e = set[k]
        e:SetWidth(lw)
        e:SetHeight(lh)
        e:ClearAllPoints()
        e:SetPoint("BOTTOMLEFT", view.hl, "BOTTOMLEFT", lx, ly)
        e:Show()
    end
    line(1, x, y, t, h)
    line(2, x + w - t, y, t, h)
    line(3, x + t, y + h - t, w - t * 2, t)
    line(4, x + t, y, w - t * 2, t)
end
function Game:Hover()
    local canvas = self.canvas
    if not view then return end
    local hl = view.hl
    local i
    if not ns.Help.IsShown() and not self.showcase and not self.done
        and not (picker and picker:IsShown()) then
        local left, bottom = canvas:GetLeft(), canvas:GetBottom()
        local scale = canvas:GetEffectiveScale()
        if left and bottom and scale and scale > 0 then
            local mx, my = GetCursorPosition()
            i = self:CellAt(mx / scale - left, my / scale - bottom)
        end
    end
    if i == self.hover then return end
    self.hover = i
    if not i or not legal(self, i) then
        hl:Hide()
        return
    end
    ns.Sfx.Play("hover")
    local n = self.n
    local hr, hc = rowcol(n, self.hole)
    local ir, ic = rowcol(n, i)
    local r1, r2, c1, c2 = ir, ir, ic, ic
    if hr == ir then
        local near = hc + ((hc < ic) and 1 or -1)
        c1, c2 = math.min(ic, near), math.max(ic, near)
    else
        local near = hr + ((hr < ir) and 1 or -1)
        r1, r2 = math.min(ir, near), math.max(ir, near)
    end
    local step = self.cell + GAP
    local x = self.ox + (c1 - 1) * step
    local y = self.oy + (n - r2) * step
    local w = (c2 - c1 + 1) * self.cell + (c2 - c1) * GAP
    local h = (r2 - r1 + 1) * self.cell + (r2 - r1) * GAP
    local t = (self.cell >= 52) and 2 or 1
    frame(hl.dark, x - 1, y - 1, w + 2, h + 2, t + 1)
    frame(hl.light, x, y, w, h, t)
    hl:Show()
end
local COVER_A   = 0.86
local THUMB     = 72
local THUMB_GAP = 4
local COLS, ROWS_G = 8, 4
local PAGE      = COLS * ROWS_G
local GRID_TOP  = 74
local EDGE_PICK = { 1, 0.92, 0.45, 1 }
local function ensurePicker(canvas)
    if picker then return end
    picker = CreateFrame("Frame", nil, canvas)
    picker:SetFrameLevel(canvas:GetFrameLevel() + 40)
    picker:SetAllPoints(canvas)
    picker:EnableMouse(true)
    picker:SetScript("OnMouseUp", function() picker:Hide() end)
    picker:Hide()
    picker.dim = picker:CreateTexture(nil, "BACKGROUND")
    picker.dim:SetAllPoints(picker)
    picker.dim:SetTexture(0, 0, 0, COVER_A)
    picker.title = picker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    picker.title:SetPoint("TOP", picker, "TOP", 0, -14)
    ns.SetKeyText(picker.title, "slide.pickTitle")
    picker.tabs = {}
    local tw, tgap = 140, 6
    local tx = math.floor((canvas.W - (#SETS * tw + (#SETS - 1) * tgap)) / 2)
    for i, set in ipairs(SETS) do
        local b = ns.MakeKitButton(picker)
        b:SetWidth(tw)
        b:SetHeight(ROW)
        b:SetPoint("TOPLEFT", picker, "TOPLEFT", tx + (i - 1) * (tw + tgap), -42)
        ns.SetKeyText(b, SET_KEY[set])
        b.onClick = function() picker.Open(set, 1) end
        picker.tabs[set] = b
    end
    local w = COLS * (THUMB + THUMB_GAP) - THUMB_GAP
    local x0 = math.floor((canvas.W - w) / 2)
    picker.cells = {}
    for i = 1, PAGE do
        local c = ns.MakeCell(picker)
        c:SetWidth(THUMB)
        c:SetHeight(THUMB)
        local r = math.floor((i - 1) / COLS)
        local col = (i - 1) - r * COLS
        c:SetPoint("TOPLEFT", picker, "TOPLEFT",
            x0 + col * (THUMB + THUMB_GAP), -(GRID_TOP + r * (THUMB + THUMB_GAP)))
        c.onClick = function()
            local g, it = live(), c.arcPic
            if g and it then g:ChoosePicture(keyOf(it.set, it.p)) end
        end
        picker.cells[i] = c
    end
    picker.now = picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    picker.now:SetPoint("TOP", picker, "TOP", 0, -(GRID_TOP + ROWS_G * (THUMB + THUMB_GAP) + 8))
    picker.now:SetTextColor(0.90, 0.86, 0.78)
    local function foot(x, wdt, tipKey, fn)
        local b = ns.MakeKitButton(picker)
        b:SetWidth(wdt)
        b:SetHeight(ROW)
        b:SetPoint("BOTTOM", picker, "BOTTOM", x, 20)
        if tipKey then ns.SetKeyTip(b, tipKey) else b.tipTitle = false end
        b.onClick = fn
        return b
    end
    picker.prev = foot(-232, 28, nil,
        function() picker.Open(picker.set, picker.page - 1) end)
    picker.prev:SetText("<")
    picker.page = 1
    picker.pageText = picker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    picker.pageText:SetPoint("BOTTOM", picker, "BOTTOM", -160, 26)
    picker.next = foot(-88, 28, nil,
        function() picker.Open(picker.set, picker.page + 1) end)
    picker.next:SetText(">")
    picker.rand = foot(30, 120, "slide.pickRandomTip",
        function()
            local g = live()
            if g then g:ChoosePicture(nil) end
        end)
    ns.SetKeyText(picker.rand, "slide.pickRandom")
    picker.close = foot(170, 100, "slide.pickCloseTip",
        function() picker:Hide() end)
    ns.SetKeyText(picker.close, "slide.pickClose")
    function picker.Open(set, page)
        local list = ns.Pics.List(set)
        local pages = math.floor((#list - 1) / PAGE) + 1
        if pages < 1 then pages = 1 end
        if page < 1 then page = pages elseif page > pages then page = 1 end
        picker.set, picker.page = set, page
        for _, s in ipairs(SETS) do
            picker.tabs[s].active = (s == set)
            ns.StyleButton(picker.tabs[s])
        end
        local solved = solvedSet()
        local g = live()
        local cur = g and g.picKey or nil
        for i = 1, PAGE do
            local c = picker.cells[i]
            local p = list[(page - 1) * PAGE + i]
            if not p then
                c.arcPic = nil
                c:Hide()
            else
                local key = keyOf(set, p)
                c.arcPic = { set = set, p = p }
                ns.StyleCell(c, "framed")
                c.icon:SetTexture(ns.Pics.Path(set, p.f))
                c.icon:SetTexCoord(window(p.w, p.h, SQUEEZE[set]))
                if solved[key] then ns.CellCheck(c) else c.check:Hide() end
                local e = (key == cur) and EDGE_PICK or ns.CELL_FRAME
                c:SetBackdropBorderColor(e[1], e[2], e[3], e[4])
                c.tipTitle = ns.Pics.Label(p)
                c.tip = solved[key] and ns.T("slide.pickSolved") or nil
                c:Show()
            end
        end
        picker.pageText:SetText(ns.T("slide.pickPage", page, pages))
        picker.now:SetText(ns.T("slide.pickNow",
            (g and g.pic) and ns.Pics.Label(g.pic) or ns.T("slide.pickRandom")))
    end
end
function Game:PickPicture()
    if ns.window:AxisLocked() or self.done then return end
    ensurePicker(self.canvas)
    local set = self.set or SETS[1]
    local page, list = 1, ns.Pics.List(set)
    for i = 1, #list do
        if self.pic and list[i].f == self.pic.f then page = math.floor((i - 1) / PAGE) + 1 end
    end
    picker.Open(set, page)
    picker:Show()
end
function Game:ChoosePicture(key)
    if ns.window:AxisLocked() or self.done then return end
    ns.Config.Set(ID, "pic", key)
    self:UsePicture(key)
    self:Repaint()
    if picker then picker:Hide() end
end
local MINI_INK = { 0.90, 0.86, 0.78 }
local MINI = {
    {
        cols = 4, rows = 1, cell = 32, gap = 3, back = "plain",
        fill = { { c = 4, r = 1, col = C_PIT } },
        ring = { { c = 1, r = 1 }, { c = 2, r = 1 }, { c = 3, r = 1 }, { c = 4, r = 1 } },
        text = {
            { c = 1, r = 1, s = "5", col = MINI_INK },
            { c = 2, r = 1, s = "6", col = MINI_INK },
            { c = 3, r = 1, s = "7", col = MINI_INK },
        },
        arrow = { { c1 = 1, r1 = 1, c2 = 4, r2 = 1 } },
    },
    {
        cols = 3, rows = 3, cell = 30, gap = 2, back = "plain",
        fill = { { c = 3, r = 1, col = C_PIT } },
        text = {
            { c = 1, r = 3, s = "1", col = MINI_INK }, { c = 2, r = 3, s = "2", col = MINI_INK },
            { c = 3, r = 3, s = "3", col = MINI_INK },
            { c = 1, r = 2, s = "4", col = MINI_INK }, { c = 2, r = 2, s = "5", col = MINI_INK },
            { c = 3, r = 2, s = "6", col = MINI_INK },
            { c = 1, r = 1, s = "7", col = MINI_INK }, { c = 2, r = 1, s = "8", col = MINI_INK },
        },
    },
    {
        cols = 2, rows = 1, cell = 44, gap = 4, back = "plain",
        fill = { { c = 1, r = 1, col = C_PIT } },
        text = { { c = 2, r = 1, s = "3", col = MINI_INK } },
        arrow = { { c1 = 2, r1 = 1, c2 = 1, r2 = 1 } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, C_MAT)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.text or {}) do g:Text(m.c, m.r, m.s, m.col) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, C_FRAME) end
end
local function helpPush(host) paintMini(host, MINI[1]) end
local function helpSolved(host) paintMini(host, MINI[2]) end
local function helpKeys(host) paintMini(host, MINI[3]) end
ns.RegisterGame{
    id = ID,
    label = "slide.label",
    icon = { tex = MENU_PIC, coord = { 0.35, 0.65, 0.3, 0.7 } },
    tip = "slide.tip",
    order = 15,
    duo = "score",
    physics = false,
    ownPanel = true,
    look = LOOK,
    done = true,
    clock = "hard",
    finale = true,
    tally = false,
    opts = {
        { key = "size", label = "slide.optSizeLabel", def = DEF_SIZE, ordered = true,
          options = SIZES, tip = "slide.optSizeTip" },
    },
    record = {
        { key = "time", label = "slide.recTime", by = "min", mark = "clock",
          format = "span" },
    },
    New = New,
    controls = {
        { action = "left",  label = "slide.ctlLeft",  mouse = "LMB", where = "slide.ctlByTile" },
        { action = "right", label = "slide.ctlRight", mouse = "LMB", where = "slide.ctlByTile" },
        { action = "up",    label = "slide.ctlUp",    mouse = "LMB", where = "slide.ctlByTile" },
        { action = "down",  label = "slide.ctlDown",  mouse = "LMB", where = "slide.ctlByTile" },
    },
    help = {
        "slide.help1",
        "slide.help2",
        { art = helpPush, h = 40 },
        "slide.helpPushSub",
        "slide.help3",
        { art = helpSolved, h = 102, sub = "slide.helpSolvedSub" },
        "slide.help4",
        { art = helpKeys, h = 52, sub = "slide.helpKeysSub" },
        "slide.help5",
        "slide.help6",
        "slide.help7",
    },
}
if #SETS == 0 then
    ns.MarkBroken(ID, "games/slide/shelves.lua")
end
