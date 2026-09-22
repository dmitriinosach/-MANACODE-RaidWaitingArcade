local ADDON, ns = ...
local ID = "merge"
local N = 4
local GAP = 8
local MARGIN = 16
local COL_GAP = 32
local PANEL = 156
local PANEL_PAD = 12
local COL_W = PANEL - PANEL_PAD * 2
local CARD = 56
local NOMW = 46
local NOMGAP = 6
local LGAP = 2
local LPAD = 10
local ROW = 22
local BORDER = 2
local WELL = 8
local SHELF = "ladder"
local DRAG_MIN = 20
local T_SLIDE = 0.14
local T_POP   = 0.16
local T_FRESH = 0.18
local POP_GROW  = 0.18
local FRESH_MIN = 0.55
local POP_EDGE = { 1, 0.86, 0.4, 1 }
local HERE_EDGE = { 1, 0.93, 0.72, 1 }
local DIM = 0.35
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local BACK_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local SCREEN_TEX = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local C_SCREEN = { 0.16, 0.115, 0.070 }
local C_GROUT = { 0.045, 0.034, 0.024, 1 }
local C_FRAME = { 0.69, 0.55, 0.31, 1 }
local C_WELL  = { 0.085, 0.065, 0.048, 1 }
local C_PLATE = { 0.098, 0.072, 0.048, 1 }
local C_RULE  = { 0.235, 0.180, 0.120, 1 }
local LOOK = ns.MakeLook{ edge = C_FRAME, screen = C_SCREEN }
local VAL_FONT = "Fonts\\FRIZQT__.TTF"
local VAL_SIZE = 14
local ICON_DIM = 0.82
local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local sin, PI = math.sin, math.pi
local FAMILIES = (ns.alchemy and ns.alchemy.families) or {}
local STEPS = (ns.alchemy and ns.alchemy.heal) or {}
local TOP = #STEPS
local CROWN = (ns.alchemy and ns.alchemy.crown) or {}
local MAXRUNG = TOP + #CROWN
local VALUE = {}
do
    local v = 1
    for i = 1, MAXRUNG do v = v * 2; VALUE[i] = v end
end
local NUM = { 0.72, 0.58, 0.46, 0.38, 0.30 }
local MID_FROM = floor(TOP / 3) + 1
local HIGH_FROM = floor(TOP * 2 / 3) + 1
local TINT_LOW  = { 0.96, 0.96, 0.92 }
local TINT_MID  = { 1, 0.93, 0.72 }
local TINT_HIGH = { 1, 0.82, 0 }
local function numTint(rung)
    if rung >= HIGH_FROM then return TINT_HIGH end
    if rung >= MID_FROM then return TINT_MID end
    return TINT_LOW
end
local DIR = { l = true, r = true, u = true, d = true }
local KEY = { left = "l", right = "r", up = "u", down = "d" }
local Game = {}
Game.__index = Game
local pool, ui
local function dataTex(n)
    local c = CROWN[n - TOP]
    if c then return ns.IconPath(c.icon) end
    local s = STEPS[n]
    if not s then return nil end
    return ns.IconDex.Item(s.item) or ns.IconPath(s.icon)
end
local function rungTex(n)
    if n > TOP then return dataTex(n), false end
    local list = ns.Shelves and ns.Shelves.Get(ID, SHELF)
    local own = list and list[n]
    if type(own) == "string" and own ~= "" then return ns.IconPath(own), true end
    return dataTex(n), false
end
local function put(f, x, y, side)
    side = side or f._cs
    f:SetWidth(side)
    f:SetHeight(side)
    local off = (f._cs - side) / 2
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", f:GetParent(), "BOTTOMLEFT", x + off, y + off)
end
local function at(d, i, j)
    if d == "l" then return j, i end
    if d == "r" then return N + 1 - j, i end
    if d == "d" then return i, j end
    return i, N + 1 - j
end
local function packLine(src)
    local out, moves, gained = {}, {}, 0
    local i, k = 1, 0
    while i <= N do
        local v = src[i]
        if v then
            local j = i + 1
            while j <= N and not src[j] do j = j + 1 end
            if j <= N and src[j] == v and v < MAXRUNG then
                k = k + 1
                out[k] = v + 1
                gained = gained + VALUE[v + 1]
                moves[#moves + 1] = { from = i, to = k }
                moves[#moves + 1] = { from = j, to = k, merge = true }
                i = j + 1
            else
                k = k + 1
                out[k] = v
                moves[#moves + 1] = { from = i, to = k }
                i = j
            end
        else
            i = i + 1
        end
    end
    return out, moves, gained
end
function Game:Simulate(d)
    local moved, gained, plan = false, 0, {}
    for i = 1, N do
        local src = {}
        for j = 1, N do
            local c, r = at(d, i, j)
            src[j] = self.cell[c][r]
        end
        local out, mv, g = packLine(src)
        gained = gained + g
        for j = 1, N do
            if out[j] ~= src[j] then moved = true end
        end
        plan[i] = { out = out, mv = mv }
    end
    return moved, gained, plan
end
function Game:Apply(d, plan)
    local anim = {}
    for i = 1, N do
        local p = plan[i]
        for m = 1, #p.mv do
            local mv = p.mv[m]
            local c0, r0 = at(d, i, mv.from)
            local c1, r1 = at(d, i, mv.to)
            anim[#anim + 1] = {
                v = self.cell[c0][r0],
                x0 = self:X(c0), y0 = self:Y(r0),
                x1 = self:X(c1), y1 = self:Y(r1),
            }
            if mv.merge then
                self.pops[#self.pops + 1] = { c = c1, r = r1, t = T_POP }
            end
        end
        for j = 1, N do
            local c, r = at(d, i, j)
            self.cell[c][r] = p.out[j]
        end
    end
    return anim
end
function Game:Spawn()
    local free = {}
    for c = 1, N do
        for r = 1, N do
            if not self.cell[c][r] then free[#free + 1] = { c, r } end
        end
    end
    if #free == 0 then return nil end
    local pick = free[self.rng:Int(#free)]
    local rung = (self.rng:Int(1, 10) == 1) and 2 or 1
    self.cell[pick[1]][pick[2]] = min(rung, TOP)
    return pick[1], pick[2]
end
function Game:HasMove()
    for c = 1, N do
        for r = 1, N do
            if not self.cell[c][r] then return true end
        end
    end
    for c = 1, N do
        for r = 1, N do
            local v = self.cell[c][r]
            if v and v < MAXRUNG then
                if c < N and self.cell[c + 1][r] == v then return true end
                if r < N and self.cell[c][r + 1] == v then return true end
            end
        end
    end
    return false
end
function Game:Rescan()
    local top = 0
    for c = 1, N do
        for r = 1, N do
            local v = self.cell[c][r]
            if v and v > top then top = v end
        end
    end
    if top > self.top then
        self.top = top
        if not self.replay and not self.quiet then ns.Sfx.Play("clear") end
    end
    self.over = not self:HasMove()
end
local function step(self, d)
    local moved, gained, plan = self:Simulate(d)
    if not moved then return false end
    self.pops = {}
    local anim = self:Apply(d, plan)
    self.score = self.score + gained
    self.plays = self.plays + 1
    local c, r = self:Spawn()
    self.fresh = c and { c = c, r = r, t = T_FRESH } or nil
    self:Rescan()
    return true, anim
end
local function cellCap()
    return ns.Config.ICON_MAX + BORDER * 2
end
function Game:Measure()
    local canvas = self.canvas
    local cap = cellCap()
    local room = canvas.H - LPAD * 2
    self.ls = ns.CellFit(TOP, min(room, TOP * cap + (TOP - 1) * LGAP), LGAP, 0)
    self.lh = TOP * self.ls + (TOP - 1) * LGAP
    self.lw = self.ls + NOMGAP + NOMW
    self.lx = MARGIN
    self.ly = floor((canvas.H - self.lh) / 2)
    local free = canvas.W - MARGIN * 2 - self.lw - PANEL
    local avail = min(free - COL_GAP * 2 - WELL * 2,
                      canvas.H - MARGIN * 2 - WELL * 2,
                      N * cap + (N - 1) * GAP)
    self.cs = ns.CellFit(N, avail, GAP, 0)
    self.fw = N * self.cs + (N - 1) * GAP
    self.ox = floor(MARGIN + self.lw + (free - self.fw - WELL * 2) / 2 + WELL)
    self.oy = floor((canvas.H - self.fw) / 2)
end
function Game:X(c)
    return self.ox + (c - 1) * (self.cs + GAP)
end
function Game:Y(r)
    return self.oy + (r - 1) * (self.cs + GAP)
end
function Game:LadderY(i)
    return self.ly + (i - 1) * (self.ls + LGAP)
end
local function ensurePool(canvas)
    if pool then return pool end
    pool = ns.NewPool(function()
        local f = ns.MakeCell(canvas)
        f:EnableMouse(false)
        ns.StyleCell(f, "framed")
        f:SetFrameLevel(canvas:GetFrameLevel() + 5)
        return f
    end, function(f)
        ns.ResetCell(f)
        f:SetAlpha(1)
    end)
    return pool
end
local function ensureUI(canvas)
    if ui then return ui end
    ui = { rung = {}, nom = {}, well = {} }
    ui.deco = ns.NewFrame("Frame", nil, canvas)
    ui.deco:SetFrameLevel(canvas:GetFrameLevel())
    ui.deco:SetAllPoints(canvas)
    ui.deco:Hide()
    local scr = ns.window:ScreenFill(ui.deco)
    scr:SetTexture(SCREEN_TEX)
    scr:SetVertexColor(C_SCREEN[1], C_SCREEN[2], C_SCREEN[3], 1)
    ui.nums = ns.NewFrame("Frame", nil, canvas)
    ui.nums:SetFrameLevel(canvas:GetFrameLevel() + 3)
    ui.nums:SetAllPoints(canvas)
    ui.nums:Hide()
    ui.board = ns.NewFrame("Frame", nil, canvas)
    ui.board:SetFrameLevel(canvas:GetFrameLevel() + 1)
    ui.board:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    ui.board:SetBackdropColor(C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
    ui.board:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], C_FRAME[4])
    ui.board:Hide()
    for i = 1, N * N do
        local t = ui.board:CreateTexture(nil, "ARTWORK")
        ns.Paint(t, C_WELL[1], C_WELL[2], C_WELL[3], C_WELL[4])
        ui.well[i] = t
    end
    for i = 1, TOP do
        local c = ns.MakeCell(canvas)
        ns.StyleCell(c, "framed")
        c:EnableMouse(true)
        c:Hide()
        ui.rung[i] = c
        local t = ui.nums:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        t:SetWidth(NOMW)
        t:SetJustifyH("LEFT")
        t:SetJustifyV("MIDDLE")
        t:SetText(tostring(VALUE[i]))
        t:Hide()
        ui.nom[i] = t
    end
    ui.panel = ns.NewFrame("Frame", nil, canvas)
    ui.panel:SetFrameLevel(canvas:GetFrameLevel() + 2)
    ui.panel:SetWidth(PANEL)
    ui.panel:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", -MARGIN, -MARGIN)
    ui.panel:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -MARGIN, MARGIN)
    ui.plate = ui.panel:CreateTexture(nil, "BACKGROUND")
    ui.plate:SetAllPoints(ui.panel)
    ns.Paint(ui.plate, C_PLATE[1], C_PLATE[2], C_PLATE[3], C_PLATE[4])
    ui.col = ns.NewFrame("Frame", nil, ui.panel)
    ui.col:SetFrameLevel(ui.panel:GetFrameLevel() + 1)
    ui.col:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", PANEL_PAD, -PANEL_PAD)
    ui.col:SetPoint("BOTTOMRIGHT", ui.panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
    ui.tally = ns.MakeScoreboard(ui.col, COL_W)
    ui.tally:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, 0)
    local function stat(y, key)
        local cap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("LEFT", ui.col, "TOPLEFT", 0, -(y + ROW / 2))
        ns.SetKeyText(cap, key)
        local val = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.SetFont(val, VAL_FONT, VAL_SIZE, "")
        val:SetJustifyH("RIGHT")
        val:SetPoint("RIGHT", ui.col, "TOPRIGHT", 0, -(y + ROW / 2))
        return cap, val
    end
    ui.bestCap, ui.best = stat(ROW, "merge.bestCap")
    ui.playsCap, ui.plays = stat(ROW * 2, "merge.playsCap")
    local function rule(y)
        local t = ui.col:CreateTexture(nil, "ARTWORK")
        ns.Paint(t, C_RULE[1], C_RULE[2], C_RULE[3], C_RULE[4])
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y)
        return t
    end
    ui.ruleTally = rule(ROW * 3 + 2)
    ui.tally:Notices(ui.col, 0, ROW * 3 + 10)
    ui.step = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.step:SetWidth(COL_W)
    ui.step:SetJustifyH("CENTER")
    ui.step:SetPoint("BOTTOM", ui.col, "BOTTOM", 0, 0)
    ui.name = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.name:SetWidth(COL_W)
    ui.name:SetJustifyH("CENTER")
    ui.name:SetPoint("BOTTOM", ui.col, "BOTTOM", 0, 16)
    ui.card = ns.MakeCell(ui.col)
    ns.StyleCell(ui.card, "framed")
    ns.SizeCell(ui.card, CARD, BORDER)
    ui.card:SetPoint("BOTTOM", ui.name, "TOP", 0, 8)
    ui.ruleCard = ui.col:CreateTexture(nil, "ARTWORK")
    ns.Paint(ui.ruleCard, C_RULE[1], C_RULE[2], C_RULE[3], C_RULE[4])
    ui.ruleCard:SetHeight(1)
    ui.ruleCard:SetWidth(COL_W)
    ui.ruleCard:SetPoint("BOTTOM", ui.card, "TOP", 0, 12)
    ui.panel:Hide()
    return ui
end
function Game:Dress(f, rung)
    ns.SizeCell(f, self.cs, BORDER)
    f._cs = self.cs
    f.icon:SetTexture((rungTex(rung)))
    f.icon:SetVertexColor(ICON_DIM, ICON_DIM, ICON_DIM)
    local text = tostring(VALUE[rung])
    ns.CellCenter(f, text)
    local font = f.center:GetFont()
    local k = NUM[min(#text, #NUM)]
    ns.SetFont(f.center, font, floor(self.cs * k), "THICKOUTLINE")
    local t = numTint(rung)
    f.center:SetTextColor(t[1], t[2], t[3])
    f.center:SetShadowColor(0, 0, 0, 1)
    f.center:SetShadowOffset(1, -1)
end
function Game:Draw()
    local p = ensurePool(self.canvas)
    p:Reset()
    self.tile = {}
    for c = 1, N do
        self.tile[c] = {}
        for r = 1, N do
            local v = self.cell[c][r]
            if v then
                local f = p:Acquire()
                self:Dress(f, v)
                put(f, self:X(c), self:Y(r))
                self.tile[c][r] = f
            end
        end
    end
    p:HideExtras()
    for i = 1, #self.pops do
        local pp = self.pops[i]
        local f = self.tile[pp.c] and self.tile[pp.c][pp.r]
        if f then
            f:SetBackdropBorderColor(POP_EDGE[1], POP_EDGE[2], POP_EDGE[3], POP_EDGE[4])
        end
    end
    if self.fresh then
        local f = self.tile[self.fresh.c] and self.tile[self.fresh.c][self.fresh.r]
        if f then
            f:SetAlpha(0)
            put(f, self:X(self.fresh.c), self:Y(self.fresh.r), self.cs * FRESH_MIN)
        end
    end
end
function Game:DrawAnim()
    local p = ensurePool(self.canvas)
    p:Reset()
    self.tile = {}
    for i = 1, #self.anim do
        local a = self.anim[i]
        a.f = p:Acquire()
        self:Dress(a.f, a.v)
        put(a.f, a.x0, a.y0)
    end
    p:HideExtras()
end
function Game:Animate(t)
    local q = 1 - (1 - t) * (1 - t)
    for i = 1, #self.anim do
        local a = self.anim[i]
        if a.f then
            put(a.f, a.x0 + (a.x1 - a.x0) * q, a.y0 + (a.y1 - a.y0) * q)
        end
    end
end
function Game:Board(u)
    u.board:ClearAllPoints()
    u.board:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT",
                     self.ox - WELL, self.oy - WELL)
    u.board:SetWidth(self.fw + WELL * 2)
    u.board:SetHeight(self.fw + WELL * 2)
    u.board:Show()
    local pitch = self.cs + GAP
    for c = 1, N do
        for r = 1, N do
            local t = u.well[(c - 1) * N + r]
            t:ClearAllPoints()
            t:SetPoint("BOTTOMLEFT", u.board, "BOTTOMLEFT",
                       WELL + (c - 1) * pitch, WELL + (r - 1) * pitch)
            t:SetWidth(self.cs)
            t:SetHeight(self.cs)
            t:Show()
        end
    end
end
function Game:Layout()
    local u = ensureUI(self.canvas)
    local canvas = self.canvas
    u.deco:Show()
    u.nums:Show()
    self:Board(u)
    u.panel:Show()
    u.best:SetText(self.bestText or "—")
    u.plays:SetText(tostring(self.plays))
    for i = 1, TOP do
        local c = u.rung[i]
        local tex, own = rungTex(i)
        ns.SizeCell(c, self.ls, BORDER)
        c:ClearAllPoints()
        c:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.lx, self:LadderY(i))
        c.icon:SetTexture(tex)
        local t = u.nom[i]
        t:ClearAllPoints()
        t:SetHeight(self.ls)
        t:SetPoint("BOTTOMLEFT", u.nums, "BOTTOMLEFT",
                   self.lx + self.ls + NOMGAP, self:LadderY(i))
        local tint = numTint(i)
        t:SetTextColor(tint[1], tint[2], tint[3])
        t:SetAlpha(i <= self.top and 1 or DIM)
        t:Show()
        if own then
            c.tipItem = nil
            c.tipTitle = ns.T("merge.rungTipTitle", i)
            c.tip = ns.T("merge.rungTip")
        else
            c.tipItem = STEPS[i] and STEPS[i].item
            c.tipTitle, c.tip = nil, nil
        end
        if i <= self.top then
            ns.CellDim(c, nil)
            c.icon:SetVertexColor(1, 1, 1)
            ns.CellCheck(c)
            if i == min(self.top, TOP) then
                c:SetBackdropBorderColor(HERE_EDGE[1], HERE_EDGE[2],
                                         HERE_EDGE[3], HERE_EDGE[4])
            end
        else
            ns.CellDim(c, DIM)
            c.icon:SetVertexColor(DIM, DIM, DIM)
            c.check:Hide()
        end
        c:Show()
    end
    local at = max(self.top, 1)
    local tex, own = rungTex(at)
    local s = STEPS[at]
    u.card.icon:SetTexture(tex)
    if own then
        u.card.tipItem = nil
        u.card.tipTitle = ns.T("merge.rungTipTitle", at)
        u.card.tip = ns.T("merge.rungTip")
    else
        u.card.tipItem = s and s.item
        u.card.tipTitle, u.card.tip = nil, nil
    end
    u.name:ClearAllPoints()
    u.name:SetPoint("BOTTOM", u.col, "BOTTOM", 0, own and 0 or 16)
    u.name:SetText(own and ns.T("merge.rungLabel", at, MAXRUNG)
                   or (s and (ns.Compat.ItemInfo(s.item) or "")) or ns.T("merge.crown"))
    u.step:SetText(ns.T("merge.rungLabel", at, MAXRUNG))
    if own then u.step:Hide() else u.step:Show() end
end
function Game:Try(d)
    if self.phase ~= "idle" or self.over then return end
    if not DIR[d] then return end
    if not self:Simulate(d) then return end
    self:Move{ k = "slide", d = d }
end
function Game:Key(action, down)
    if not down then return end
    local d = KEY[action]
    if d then self:Try(d) end
end
function Game:Click(x, y, button)
    if button and button ~= "LeftButton" then return end
    self.drag = { x = x, y = y }
end
function Game:Release(x, y, button)
    local g = self.drag
    self.drag = nil
    if not g or (button and button ~= "LeftButton") then return end
    local dx, dy = x - g.x, y - g.y
    local ax, ay = abs(dx), abs(dy)
    if ax == ay then return end
    if max(ax, ay) < DRAG_MIN then return end
    if ax > ay then
        self:Try(dx > 0 and "r" or "l")
    else
        self:Try(dy > 0 and "u" or "d")
    end
end
function Game:Move(move)
    if type(move) ~= "table" or move.k ~= "slide" or not DIR[move.d] then return false end
    local ok, anim = step(self, move.d)
    if not ok then return false end
    self.anim = anim
    self:DrawAnim()
    self.phase, self.pt = "slide", 0
    return true
end
function Game:PickSet(seed)
    local ok = {}
    for _, f in ipairs(FAMILIES) do
        if type(f.steps) == "table" and #f.steps == TOP then ok[#ok + 1] = f end
    end
    if #ok == 0 then return end
    local f = ok[floor(abs(seed)) % #ok + 1]
    STEPS = f.steps
end
function Game:Start(seed, moves)
    self.seed = seed
    self.score, self.plays, self.top = 0, 0, 0
    self.over = false
    self.phase, self.pt = "idle", 0
    self.anim, self.drag = nil, nil
    self.pops, self.fresh = {}, nil
    self.tile = {}
    self.cell = {}
    for c = 1, N do self.cell[c] = {} end
    self.rng = ns.RNG.New(seed)
    self:PickSet(seed)
    self:Measure()
    local best = ns.Records.Best(ID, nil)
    local mark = ns.Records.MarkFor(self.def, "score")
    self.bestText = best and ns.Records.Format(mark, best[mark.key]) or "—"
    self.quiet = true
    self:Spawn()
    self:Spawn()
    self:Rescan()
    self.quiet = false
    if moves then
        self.replay = true
        for i = 1, #moves do
            local m = moves[i]
            if type(m) == "table" and m.k == "slide" and DIR[m.d] then
                step(self, m.d)
            end
        end
        self.replay = false
        self.pops, self.fresh = {}, nil
    end
    self:Layout()
    self:Draw()
end
function Game:Update(dt)
    if self.phase == "slide" then
        self.pt = self.pt + dt
        if self.pt >= T_SLIDE then
            self.phase = "idle"
            self.anim = nil
            self:Draw()
            self:Layout()
            ns.Sfx.Play("pop")
        else
            self:Animate(self.pt / T_SLIDE)
        end
        return
    end
    for i = #self.pops, 1, -1 do
        local p = self.pops[i]
        p.t = p.t - dt
        local f = self.tile[p.c] and self.tile[p.c][p.r]
        if p.t <= 0 then
            if f then
                ns.CellDim(f, nil)
                put(f, self:X(p.c), self:Y(p.r))
            end
            table.remove(self.pops, i)
        elseif f then
            local k = sin(PI * (1 - p.t / T_POP))
            put(f, self:X(p.c), self:Y(p.r), self.cs * (1 + POP_GROW * k))
        end
    end
    if self.fresh then
        local fr = self.fresh
        fr.t = fr.t - dt
        local f = self.tile[fr.c] and self.tile[fr.c][fr.r]
        if fr.t <= 0 then
            if f then
                f:SetAlpha(1)
                put(f, self:X(fr.c), self:Y(fr.r))
            end
            self.fresh = nil
        elseif f then
            local k = 1 - fr.t / T_FRESH
            f:SetAlpha(k)
            put(f, self:X(fr.c), self:Y(fr.r), self.cs * (FRESH_MIN + (1 - FRESH_MIN) * k))
        end
    end
end
function Game:PanelSync()
    if ui and ui.tally then ui.tally:Sync() end
end
function Game:Relocalize()
    if not ui then return end
    self:Layout()
end
function Game:Score()
    return self.score
end
function Game:IsOver()
    if self.phase ~= "idle" then return false end
    return self.over
end
function Game:Stop()
    if pool then pool:HideAll() end
    if ui then
        ui.deco:Hide()
        ui.nums:Hide()
        ui.board:Hide()
        for i = 1, TOP do
            ui.rung[i]:Hide()
            ui.nom[i]:Hide()
        end
        ui.panel:Hide()
    end
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
local MINI_CELL = 32
local MINI_STEP = 30
local MINI_TILE = 26
local MINI_GAP = 3
local MINI_WELL = { 0.085, 0.065, 0.048 }
local MINI_FRAME = { 0.69, 0.55, 0.31, 1 }
local MINI_INK = { 0.96, 0.96, 0.92 }
local MINI_PALE = { 0.62, 0.58, 0.50 }
local MINI_WAS = { 0.14, 0.11, 0.075 }
local MINI_NOW = { 0.27, 0.21, 0.135 }
local MINI = {
    {
        cols = 4, rows = 1, cell = MINI_CELL, gap = MINI_GAP, face = MINI_WELL,
        text = { { c = 1, r = 1, s = "2", col = MINI_INK } },
        arrow = { { c1 = 1, r1 = 1, c2 = 4, r2 = 1 } },
        ring = { { c = 4, r = 1 } },
    },
    {
        cols = 3, rows = 2, cell = MINI_STEP, gap = MINI_GAP, face = MINI_WELL,
        fill = {
            { c = 1, r = 2, col = MINI_WAS }, { c = 2, r = 2, col = MINI_WAS },
            { c = 3, r = 1, col = MINI_NOW },
        },
        text = {
            { c = 1, r = 2, s = "2", col = MINI_PALE },
            { c = 2, r = 2, s = "2", col = MINI_PALE },
            { c = 3, r = 1, s = "4", col = MINI_INK },
        },
        arrow = { { c1 = 1, r1 = 2, c2 = 3, r2 = 2 } },
        ring = { { c = 3, r = 1 } },
    },
    {
        cols = 4, rows = 2, cell = MINI_STEP, gap = MINI_GAP, face = MINI_WELL,
        fill = {
            { c = 1, r = 2, col = MINI_WAS }, { c = 2, r = 2, col = MINI_WAS },
            { c = 3, r = 2, col = MINI_WAS },
            { c = 3, r = 1, col = MINI_NOW }, { c = 4, r = 1, col = MINI_NOW },
        },
        text = {
            { c = 1, r = 2, s = "2", col = MINI_PALE },
            { c = 2, r = 2, s = "2", col = MINI_PALE },
            { c = 3, r = 2, s = "2", col = MINI_PALE },
            { c = 3, r = 1, s = "2", col = MINI_INK },
            { c = 4, r = 1, s = "4", col = MINI_INK },
        },
        arrow = { { c1 = 1, r1 = 2, c2 = 4, r2 = 2 } },
        ring = { { c = 4, r = 1 } },
    },
    {
        cols = 4, rows = 2, cell = MINI_STEP, gap = MINI_GAP, face = MINI_WELL,
        fill = {
            { c = 1, r = 2, col = MINI_WAS }, { c = 2, r = 2, col = MINI_WAS },
            { c = 3, r = 2, col = MINI_WAS }, { c = 4, r = 2, col = MINI_WAS },
            { c = 3, r = 1, col = MINI_NOW }, { c = 4, r = 1, col = MINI_NOW },
        },
        text = {
            { c = 1, r = 2, s = "2", col = MINI_PALE },
            { c = 2, r = 2, s = "2", col = MINI_PALE },
            { c = 3, r = 2, s = "2", col = MINI_PALE },
            { c = 4, r = 2, s = "2", col = MINI_PALE },
            { c = 3, r = 1, s = "4", col = MINI_INK },
            { c = 4, r = 1, s = "4", col = MINI_INK },
        },
        arrow = { { c1 = 1, r1 = 2, c2 = 4, r2 = 2 } },
        ring = { { c = 3, r = 1 }, { c = 4, r = 1 } },
    },
    {
        cols = 4, rows = 4, cell = MINI_TILE, gap = 2, face = MINI_WELL,
        fill = {
            { c = 1, r = 1, col = MINI_NOW }, { c = 2, r = 1, col = MINI_NOW },
            { c = 3, r = 1, col = MINI_NOW }, { c = 4, r = 1, col = MINI_NOW },
            { c = 1, r = 2, col = MINI_WAS }, { c = 2, r = 2, col = MINI_WAS },
        },
        text = {
            { c = 1, r = 1, s = "64", col = MINI_INK },
            { c = 2, r = 1, s = "32", col = MINI_INK },
            { c = 3, r = 1, s = "16", col = MINI_INK },
            { c = 4, r = 1, s = "8", col = MINI_INK },
            { c = 1, r = 2, s = "4", col = MINI_PALE },
            { c = 2, r = 2, s = "2", col = MINI_PALE },
        },
        ring = { { c = 1, r = 1 } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, spec.face or MINI_WELL)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.text or {}) do g:Text(m.c, m.r, m.s, m.col) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, MINI_FRAME) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
end
local function helpSlide(host) paintMini(host, MINI[1]) end
local function helpMerge(host) paintMini(host, MINI[2]) end
local function helpThree(host) paintMini(host, MINI[3]) end
local function helpRow(host) paintMini(host, MINI[4]) end
local function helpCorner(host) paintMini(host, MINI[5]) end
ns.RegisterGame{
    id = ID,
    label = "merge.label",
    icon = { draw = ns.MergeTileIcon },
    tip = "merge.tip",
    order = 14,
    duo = "score",
    physics = false,
    clock = "off",
    ownPanel = true,
    done = true,
    New = New,
    look = LOOK,
    controls = {
        { action = "left",  label = "merge.ctlLeft",  mouse = "DRAG" },
        { action = "right", label = "merge.ctlRight", mouse = "DRAG" },
        { action = "up",    label = "merge.ctlUp",    mouse = "DRAG" },
        { action = "down",  label = "merge.ctlDown",  mouse = "DRAG" },
    },
    help = {
        "merge.help1",
        "merge.help2",
        { art = helpSlide, h = MINI_CELL + 8 },
        "merge.help3",
        { art = helpMerge, h = MINI_STEP * 2 + MINI_GAP + 8, sub = "merge.helpMergeSub" },
        "merge.help4",
        { art = helpThree, h = MINI_STEP * 2 + MINI_GAP + 8 },
        "merge.help5",
        { art = helpRow, h = MINI_STEP * 2 + MINI_GAP + 8 },
        "merge.help6",
        "merge.help7",
        { art = helpCorner, h = MINI_TILE * 4 + 6 + 8 },
        "merge.help8",
        "merge.help9",
        "merge.help10",
        "merge.help11",
    },
}
