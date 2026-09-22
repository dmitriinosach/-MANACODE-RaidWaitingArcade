local ADDON, ns = ...
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min
local sin = math.sin
local Apo = ns.Apo
local ID = "apothecary"
local CAP = 4
local EMPTY = 2
local COLORS_START = 7
local COLORS_MAX = 12
local STEP_EVERY = 2
local UNDO_MAX = 200
local function colorsFor(level)
    if level < 1 then
        level = 1
    end
    local c = COLORS_START + floor((level - 1) / STEP_EVERY)
    if c > COLORS_MAX then
        c = COLORS_MAX
    end
    return c
end
local BLOCK_MIN, BLOCK_MAX = 8, 10
local MODE_SALT = 1013
local MODE_GUARD = 500
local function modeAt(seed, level)
    local r = ns.RNG.New(seed + MODE_SALT)
    local start, blind = 1, false
    for _ = 1, MODE_GUARD do
        local len = r:Int(BLOCK_MIN, BLOCK_MAX)
        if level < start + len then
            return blind
        end
        start = start + len
        blind = not blind
    end
    return blind
end
local HUE = {
    { 0.86, 0.22, 0.22 },
    { 0.30, 0.68, 0.96 },
    { 0.96, 0.72, 0.16 },
    { 0.36, 0.74, 0.34 },
    { 0.72, 0.42, 0.90 },
    { 0.96, 0.52, 0.20 },
    { 0.20, 0.72, 0.68 },
    { 0.94, 0.60, 0.75 },
    { 0.90, 0.90, 0.35 },
    { 0.30, 0.42, 0.86 },
    { 0.60, 0.78, 0.28 },
    { 0.68, 0.48, 0.30 },
}
local COL_HIDDEN = { 0.30, 0.31, 0.35 }
local HUE_ICON = {}
for i = 1, #HUE do
    local h = HUE[i]
    HUE_ICON[i] = { h[1] + (1 - h[1]) * 0.38,
                    h[2] + (1 - h[2]) * 0.38,
                    h[3] + (1 - h[3]) * 0.38 }
end
local LADDER_V = 3
local function ladder()
    local ch = ns.Store.Char()
    local box = ch.apothecary
    if type(box) ~= "table" or box.v ~= LADDER_V then
        box = { v = LADDER_V, done = 0 }
        ch.apothecary = box
    end
    return box
end
local FLY_DUR = 0.35
local FLY_LAG = 0.14
local DROPS = 3
local DROP_LAG = 0.05
local DROP_K = { 0.36, 0.28, 0.22 }
local FILL_T = 0.18
local function flyDrain(m)
    return max(0.05, (m - 1) * FLY_LAG + (DROPS - 1) * DROP_LAG)
end
local function flyEnd(m)
    return (m - 1) * FLY_LAG + (DROPS - 1) * DROP_LAG + FLY_DUR
end
local ANIM_CORK = 0.35
local ANIM_FLASH = 0.2
local PASS_TIME = 0.6
local RIPPLE_DUR = 0.5
local RIPPLE_W = 12.6
local BUBBLES = 2
local BUB_RISE = 3.1
local BUB_SWAY = 1.7
local BUB_A = 0.34
local SHELF_SALT = 4409
local function herbIcons(seed, n)
    local out, seen = {}, {}
    local pick = ns.RNG.New(seed + SHELF_SALT)
    for k = 1, n do
        local name = ns.Shelves.Pick(ID, "b" .. k, pick)
        local t = name and ns.IconPath(name) or nil
        if t and not seen[t] then
            seen[t] = true
            out[k] = t
        end
    end
    local spare = {}
    for _, row in ipairs(ns.herbDB or {}) do
        if #spare >= n then
            break
        end
        local t = ns.IconDex.Item(row.id)
        if t and not seen[t] then
            seen[t] = true
            spare[#spare + 1] = t
        end
    end
    local at = 1
    for k = 1, n do
        if not out[k] then
            out[k] = spare[at]
            at = at + 1
        end
    end
    return out
end
local Game = {}
Game.__index = Game
local cur
local back
local flaskPool
local flyPool
local ui
local tickLiquid
local stampSeq = 0
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
local function reveal(self)
    if not self.blind then
        return
    end
    for i = 1, self.n do
        local b = self.bag[i]
        local nb = #b
        if nb > 0 then
            local _, blk = Apo.TopRun(b)
            local row = self.seen[i]
            for s = nb - blk + 1, nb do
                row[s] = true
            end
        end
    end
end
local function pushUndo(self)
    local st = self.undo
    st[#st + 1] = Apo.CopyBag(self.bag)
    if #st > UNDO_MAX then
        table.remove(st, 1)
    end
end
local function setLevel(self, level)
    if level < 1 then
        level = 1
    end
    self.level = level
    self.solved = level - 1
    self.cap = CAP
    self.blind = modeAt(self.seed, level)
    local colors = colorsFor(level)
    local empty = EMPTY
    self.n = colors + empty
    local rng = ns.RNG.New(self.seed + level * 7919)
    local bag = Apo.Build(rng, colors, CAP, empty)
    self.colors = colors
    self.bag = bag
    self.start = Apo.CopyBag(bag)
    self.seen = {}
    for i = 1, self.n do
        self.seen[i] = {}
    end
    self.icons = herbIcons(self.seed, colors)
    self.undo = {}
    self.picked = nil
    self.fly, self.cork, self.flash, self.pass = nil, nil, nil, nil
    self.ripple = nil
    self.bubT = 0
    self.geom = nil
    self.rect = {}
    self.stuck = false
    self.brinked = false
    stampSeq = stampSeq + 1
    self.stamp = stampSeq
    reveal(self)
end
local function checkpoint(self)
    if self.replay then
        return
    end
    if ns.window and ns.window.Checkpoint then
        ns.window:Checkpoint { k = "lvl", n = self.level, v = LADDER_V }
    end
end
local function advance(self)
    setLevel(self, self.level + 1)
    checkpoint(self)
end
local function checkStuck(self)
    self.stuck = not Apo.HasMove(self)
end
local function checkLevel(self)
    if not Apo.Solved(self) then
        checkStuck(self)
        return
    end
    self.solved = self.level
    self.stuck = false
    if not self.replay then
        ns.Sfx.Play("clear")
        if not self.brinked then
            local box = ladder()
            if self.solved > (box.done or 0) then
                box.done = self.solved
            end
        end
    end
    if self.replay then
        advance(self)
    else
        self.pass = { t = PASS_TIME, level = self.level }
    end
end
local function apply(self, move)
    local k = move.k
    if k == "lvl" then
        setLevel(self, move.n or 1)
        return true
    elseif self.pass then
        return false
    elseif k == "pour" then
        local from, to = move.from, move.to
        if not Apo.CanPour(self, from, to) then
            return false
        end
        pushUndo(self)
        local nb = #self.bag[to]
        local na = #self.bag[from]
        local col, m = Apo.Pour(self, from, to)
        self.picked = nil
        reveal(self)
        if not self.replay then
            ns.Sfx.Play("pop")
            self.fly = { from = from, to = to, col = col, m = m, na = na, nb = nb, t = 0 }
            self.ripple = { i = to, t = -FLY_DUR }
            if Apo.Corked(self, to) then
                self.cork = { i = to, t = ANIM_CORK, wait = flyEnd(m) }
            end
        end
    elseif k == "undo" then
        local st = self.undo
        local s = st[#st]
        if not s then
            return false
        end
        st[#st] = nil
        self.bag = s
        self.picked, self.fly, self.cork, self.flash = nil, nil, nil, nil
        self.ripple = nil
        reveal(self)
    elseif k == "reset" then
        self.bag = Apo.CopyBag(self.start)
        self.undo = {}
        self.picked, self.fly, self.cork, self.flash = nil, nil, nil, nil
        self.ripple = nil
        self.brinked = false
        reveal(self)
    else
        return false
    end
    checkLevel(self)
    return true
end
local function moveListOK(moves)
    local first = moves[1]
    return first ~= nil and first.k == "lvl" and first.v == LADDER_V
end
function Game:Start(seed, moves)
    self.seed = seed
    self.time = 0
    cur = self
    setLevel(self, (ladder().done or 0) + 1)
    if moves and #moves > 0 then
        if moveListOK(moves) then
            self.replay = true
            for i = 1, #moves do
                apply(self, moves[i])
            end
            self.replay = nil
        else
            for i = #moves, 1, -1 do
                moves[i] = nil
            end
            moves[1] = { k = "lvl", n = self.level, v = LADDER_V }
        end
    else
        checkpoint(self)
    end
    checkStuck(self)
    self:Bar()
    self:Draw()
end
function Game:Move(move)
    local took = apply(self, move)
    self:Draw()
    return took
end
local function pick(self, i)
    if self.pass then
        return
    end
    if not i then
        self.picked = nil
        self:Draw()
        return
    end
    if Apo.Corked(self, i) then
        ns.Sfx.Play("deny")
        self.flash = { i = i, t = ANIM_FLASH }
        self.picked = nil
        self:Draw()
        return
    end
    if self.picked == nil then
        if #self.bag[i] == 0 then
            ns.Sfx.Play("deny")
            self.flash = { i = i, t = ANIM_FLASH }
            self:Draw()
            return
        end
        self.picked = i
        ns.Sfx.Play("pick")
        self:Draw()
        return
    end
    if self.picked == i then
        self.picked = nil
        self:Draw()
        return
    end
    if Apo.CanPour(self, self.picked, i) then
        local from = self.picked
        self.picked = nil
        self:Move { k = "pour", from = from, to = i }
    else
        ns.Sfx.Play("deny")
        self.flash = { i = i, t = ANIM_FLASH }
        self.picked = nil
        self:Draw()
    end
end
function Game:Click(x, y)
    for i = 1, self.n or 0 do
        local r = self.rect[i]
        if r and x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            pick(self, i)
            return
        end
    end
    pick(self, nil)
end
function Game:Update(dt)
    self.time = self.time + dt
    local live = false
    if self.fly then
        self.fly.t = self.fly.t + dt
        if self.fly.t >= flyEnd(self.fly.m) then
            self.fly = nil
        end
        live = true
    end
    if self.cork then
        if self.cork.wait then
            self.cork.wait = self.cork.wait - dt
            if self.cork.wait <= 0 then
                self.cork.wait = nil
                ns.Sfx.Play("big")
            end
        else
            self.cork.t = self.cork.t - dt
            if self.cork.t <= 0 then
                self.cork = nil
            end
        end
        live = true
    end
    if self.ripple then
        self.ripple.t = self.ripple.t + dt
        if self.ripple.t >= RIPPLE_DUR then
            self.ripple = nil
        end
        live = true
    end
    if self.flash then
        self.flash.t = self.flash.t - dt
        if self.flash.t <= 0 then
            self.flash = nil
        end
        live = true
    end
    if self.pass then
        if not self.fly and not self.cork then
            self.pass.t = self.pass.t - dt
            if self.pass.t <= 0 then
                advance(self)
            end
        end
        live = true
    end
    if live then
        self:Draw()
    end
    if ui and ui.note:IsShown() then
        ui.note:SetAlpha(0.90 + 0.10 * sin(self.time * 2.5))
    end
    tickLiquid(self, dt)
end
function Game:Score()
    return self.solved or 0
end
function Game:IsOver()
    return false
end
function Game:Brink()
    local last = self.colors
    for i = 1, self.n do
        local b = {}
        if i < last then
            for s = 1, self.cap do
                b[s] = i
            end
        elseif i == last then
            for s = 1, self.cap - 1 do
                b[s] = last
            end
        elseif i == last + 1 then
            b[1] = last
        end
        self.bag[i] = b
        self.seen[i] = {}
    end
    self.undo = {}
    self.picked = nil
    self.fly, self.cork, self.flash, self.pass = nil, nil, nil, nil
    self.ripple = nil
    self.stuck = false
    self.brinked = true
    reveal(self)
end
function Game:Stop()
    if cur == self then
        cur = nil
    end
    if back then
        back:Hide()
    end
    if flaskPool then
        flaskPool:HideAll()
    end
    if flyPool then
        flyPool:HideAll()
    end
    if ui then
        ui.note:Hide()
        ui.plate:Hide()
        ui.status:Hide()
        ui.hud:Hide()
    end
end
function Game:Bar()
    local passing = self.pass ~= nil
    local canUndo = not passing and #self.undo > 0
    local state = tostring(canUndo) .. tostring(passing)
    if self.barState == state then
        return
    end
    self.barState = state
    ns.window:SetGameBar {
        { label = "apothecary.resetLabel", side = "right",
          disabled = passing,
          tip = "apothecary.resetTip",
          tipDim = passing and "apothecary.tipDimPassing"
                  or "apothecary.resetTipDim",
          onClick = function()
              if cur then
                  cur:Move { k = "reset" }
              end
          end },
        { label = "apothecary.undoLabel", side = "right",
          disabled = not canUndo,
          tip = "apothecary.undoTip",
          tipDim = passing and "apothecary.tipDimPassing"
                  or (not canUndo and "apothecary.undoTipDim" or nil),
          onClick = function()
              if cur and #cur.undo > 0 then
                  cur:Move { k = "undo" }
              end
          end },
    }
end
local MARGIN_X = ns.Space.pad
local TOP_PAD = 24
local HUD_LEVEL = 30
local PLATE_H = 34
local PLATE_A = 0.82
local LEDGE_H = 40
local BOT_PAD = LEDGE_H
local GAP_X = 10
local GAP_ROW = ns.Space.gap
local WALL = 2
local EDGE = 2
local EDGE_A = 0.72
local SLOT_GAP = 0
local LIFT = 6
local ARC_UP = 26
local CORK_K = 0.26
local BOWL_K = 0.50
local GLOW_K = 0.50
local GLOW_DIP = 0.12
local GLOW_A = 0.60
local GLOW_MIX = 0.45
local COL_PICKED = { 0.30, 1.00, 0.40, 1 }
local COL_FLASH = { 1.00, 0.15, 0.15, 1 }
local COL_HOVER = { 1.00, 0.82, 0.00, 0.85 }
local COL_CORKED = { 1.00, 0.82, 0.00, 0.90 }
local COL_IDLE = { 0.42, 0.46, 0.52, 0.85 }
local GLASS = { 0.09, 0.10, 0.13, 0.94 }
local GLASS_LIP = { 0.58, 0.64, 0.72, 0.90 }
local SHINE = { 1.00, 1.00, 1.00, 0.10 }
local SURFACE = { 1.00, 1.00, 1.00, 0.35 }
local CORK_TOP = { 0.78, 0.58, 0.34, 1 }
local CORK_LIT = { 0.74, 0.54, 0.31, 1 }
local CORK_BODY = { 0.66, 0.47, 0.26, 1 }
local CORK_SHADE = { 0.52, 0.36, 0.19, 1 }
local CORK_GRAIN = { 0.48, 0.33, 0.17, 1 }
local CORK_BAND = { 0.34, 0.23, 0.12, 1 }
local QMARK_COL = { 0.62, 0.65, 0.70 }
local BG_SET = "lfg"
local BG_PICS = {
    "UI-LFG-BACKGROUND-Utgarde",
    "UI-LFG-BACKGROUND-UtgardePinnacle",
    "UI-LFG-BACKGROUND-StormwindStockades",
}
local BG_SALT = 7717
local BG_TINT = { 0.70, 0.58, 0.46 }
local BG_A = 0.55
local BG_BASE = { 0.04, 0.03, 0.02, 1 }
local VEIL_A = 0.55
local VEIL_K = 0.60
local LEDGE_TOP = { 0.37, 0.26, 0.15, 1 }
local LEDGE_LOW = 0.62
local LEDGE_EDGE = { 0.59, 0.45, 0.25, 1 }
local LEDGE_DARK = { 0.10, 0.07, 0.04, 1 }
local PLANK_H = 8
local PLANK_OUT = 14
local PLANK_LOW = 0.45
local SHADOW_A = 0.30
local SHADOW_H = 8
local LOOK = ns.MakeLook {
    wood = { LEDGE_TOP[1], LEDGE_TOP[2], LEDGE_TOP[3] },
    edge = { COL_HOVER[1], COL_HOVER[2], COL_HOVER[3] },
    screen = { BG_BASE[1], BG_BASE[2], BG_BASE[3] },
}
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local LIQ_LOW = 0.66
local ICON_A = 0.26
local ICON_A_RAW = 0.20
local ICON_K = 0.62
local function measure(canvas, count, rows)
    local perRow = ceil(count / rows)
    local availW = canvas.W - MARGIN_X * 2
    local availH = canvas.H - TOP_PAD - BOT_PAD
    local rowH = (availH - (rows - 1) * GAP_ROW) / rows
    local byW = (availW - (perRow - 1) * GAP_X) / perRow - WALL * 2
    local byH = (rowH - WALL * 2 - (CAP - 1) * SLOT_GAP) / (CAP + CORK_K + BOWL_K)
    local cell = ns.CellFit(1, min(byW, byH), 0, 0)
    local g = {
        rows = rows, perRow = perRow, cell = cell,
        corkH = max(6, floor(cell * CORK_K)),
        availH = availH,
    }
    g.bodyH = CAP * cell + (CAP - 1) * SLOT_GAP + WALL * 2
    g.flaskW = cell + WALL * 2
    g.bowlH = max(4, floor(cell * BOWL_K))
    g.flaskH = g.bodyH + g.corkH + g.bowlH
    g.lipH = max(2, floor(cell * 0.09))
    g.wob = max(2, floor(cell * 0.12))
    g.totalH = rows * g.flaskH + (rows - 1) * GAP_ROW
    g.rowW = perRow * g.flaskW + (perRow - 1) * GAP_X
    return g
end
local function layout(canvas, count)
    local best
    for rows = 1, 2 do
        local g = measure(canvas, count, rows)
        local fits = g.rowW <= canvas.W - MARGIN_X * 2 and g.totalH <= g.availH
        if fits and (not best or g.cell > best.cell) then
            best = g
        end
    end
    return best or measure(canvas, count, 2)
end
local function paint(t, c)
    ns.Paint(t, c[1], c[2], c[3], c[4] or 1)
end
local function place(t, x, y, w, h)
    t:ClearAllPoints()
    t:SetPoint("BOTTOMLEFT", x, y)
    t:SetWidth(max(1, w))
    t:SetHeight(max(1, h))
end
local function styleFlask(f)
    local c = (f:IsMouseOver() and not f.locked) and COL_HOVER or f.baseColor
    if f.edgeColor == c then
        return
    end
    f.edgeColor = c
    for i = 1, #f.edges do
        paint(f.edges[i], c)
        f.edges[i]:SetAlpha(EDGE_A)
    end
    paint(f.lip, c == COL_IDLE and GLASS_LIP or c)
    f.bowlEdge:SetVertexColor(c[1], c[2], c[3])
    f.bowlEdge:SetAlpha(c[4] or 1)
end
local function makeFlask(canvas)
    local f = ns.NewFrame("Button", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + 1)
    f.shadow = f:CreateTexture(nil, "BACKGROUND")
    f.shadow:SetTexture(DISC)
    f.shadow:SetVertexColor(0, 0, 0)
    f.shadow:SetAlpha(SHADOW_A)
    f.body = f:CreateTexture(nil, "BACKGROUND")
    f.bowlEdge = f:CreateTexture(nil, "BACKGROUND")
    f.bowlEdge:SetTexture(DISC)
    f.bowlEdge:SetTexCoord(0, 1, 0.5, 1)
    f.bowl = f:CreateTexture(nil, "BORDER")
    f.bowl:SetTexture(DISC)
    f.bowl:SetTexCoord(0, 1, 0.5, 1)
    f.bowl:SetVertexColor(GLASS[1], GLASS[2], GLASS[3])
    f.bowl:SetAlpha(GLASS[4])
    f.hl = ns.Fill(f, "HIGHLIGHT", { 1, 1, 1, 0.06 })
    f.liq = ns.NewFrame("Frame", nil, f)
    f.liq:SetFrameLevel(f:GetFrameLevel() + 1)
    f.cap = f.liq:CreateTexture(nil, "BACKGROUND")
    f.cap:SetTexture(DISC)
    f.cap:SetTexCoord(0, 1, 0.5, 1)
    f.slots = {}
    for s = 1, CAP do
        local it = {}
        it.fill = f.liq:CreateTexture(nil, "BACKGROUND")
        it.fill:SetTexture(WHITE)
        it.icon = f.liq:CreateTexture(nil, "ARTWORK")
        it.q = f.liq:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        it.q:SetText("?")
        it.q:SetTextColor(QMARK_COL[1], QMARK_COL[2], QMARK_COL[3])
        f.slots[s] = it
    end
    f.surf = ns.Fill(f.liq, "OVERLAY", SURFACE)
    f.bub = ns.NewFrame("Frame", nil, f)
    f.bub:SetFrameLevel(f:GetFrameLevel() + 2)
    f.bubs, f.bubX = {}, {}
    for k = 1, BUBBLES do
        local b = f.bub:CreateTexture(nil, "ARTWORK")
        b:SetTexture(DISC)
        b:SetVertexColor(1, 1, 1)
        b:Hide()
        f.bubs[k] = b
    end
    f.glass = ns.NewFrame("Frame", nil, f)
    f.glass:SetFrameLevel(f:GetFrameLevel() + 3)
    f.shine = ns.Fill(f.glass, "ARTWORK", SHINE)
    f.edges = {}
    for i = 1, 2 do
        f.edges[i] = f.glass:CreateTexture(nil, "OVERLAY")
    end
    f.lip = f.glass:CreateTexture(nil, "OVERLAY")
    f.corkBand = ns.Fill(f.glass, "BACKGROUND", CORK_BAND)
    f.cork = ns.Fill(f.glass, "BACKGROUND", CORK_BODY)
    f.corkLit = ns.Fill(f.glass, "BORDER", CORK_LIT)
    f.corkShade = ns.Fill(f.glass, "BORDER", CORK_SHADE)
    f.corkTop = f.glass:CreateTexture(nil, "BACKGROUND")
    f.corkTop:SetTexture(DISC)
    f.corkTop:SetTexCoord(0, 1, 0, 0.22)
    f.corkTop:SetVertexColor(CORK_TOP[1], CORK_TOP[2], CORK_TOP[3])
    f.corkGrain = {}
    for i = 1, 3 do
        f.corkGrain[i] = ns.Fill(f.glass, "ARTWORK", CORK_GRAIN)
    end
    f.glow = f.bub:CreateTexture(nil, "OVERLAY")
    f.glow:SetTexture(WHITE)
    f.glow:Hide()
    f:SetScript("OnEnter", function(b)
        styleFlask(b)
    end)
    f:SetScript("OnLeave", function(b)
        styleFlask(b)
    end)
    f:SetScript("OnClick", function(b)
        if ns.Loop.IsPaused() then
            ns.Loop.Resume()
            ns.window:RefreshHead()
            return
        end
        if cur and b.idx then
            pick(cur, b.idx)
        end
    end)
    return f
end
local function placeCork(f, g, dy)
    local w, y = g.flaskW, f.mouthY + dy
    local band = max(2, floor(g.cell * 0.09))
    local dome = max(2, floor(g.corkH * 0.28))
    local bodyH = max(3, g.corkH - dome - band)
    local over = max(1, floor(g.cell * 0.06))
    local cw = w + over * 2
    place(f.corkBand, 0, y - band, w, band * 2)
    place(f.cork, -over, y + band, cw, bodyH)
    local side = max(1, floor(cw * 0.16))
    place(f.corkLit, -over, y + band, side, bodyH)
    place(f.corkShade, -over + cw - side, y + band, side, bodyH)
    place(f.corkTop, -over, y + band + bodyH - 1, cw, dome)
    local grain = max(1, floor(g.cell * 0.03))
    local run = { 0.62, 0.44, 0.30 }
    for i = 1, 3 do
        local gw = floor(cw * run[i])
        place(f.corkGrain[i], -over + floor((cw - gw) * (i == 2 and 0.72 or 0.28)),
                y + band + floor(bodyH * (0.22 + 0.26 * (i - 1))), gw, grain)
    end
end
local function showCork(f, a)
    f.corkBand:SetAlpha(a)
    f.cork:SetAlpha(a)
    f.corkLit:SetAlpha(a)
    f.corkShade:SetAlpha(a)
    f.corkTop:SetAlpha(a)
    for i = 1, 3 do
        f.corkGrain[i]:SetAlpha(a)
    end
    f.corkBand:Show()
    f.cork:Show()
    f.corkLit:Show()
    f.corkShade:Show()
    f.corkTop:Show()
    for i = 1, 3 do
        f.corkGrain[i]:Show()
    end
end
local function hideCork(f)
    f.corkBand:Hide()
    f.cork:Hide()
    f.corkLit:Hide()
    f.corkShade:Hide()
    f.corkTop:Hide()
    for i = 1, 3 do
        f.corkGrain[i]:Hide()
    end
end
local function layoutFlask(f, g)
    local cell, bodyH, w = g.cell, g.bodyH, g.flaskW
    local bowlH = g.bowlH
    local bodyY = bowlH
    f:SetWidth(w)
    f:SetHeight(g.flaskH)
    place(f.shadow, WALL, -SHADOW_H, cell, SHADOW_H)
    place(f.bowlEdge, 0, 0, w, bowlH)
    place(f.bowl, EDGE, EDGE, w - EDGE * 2, bowlH - EDGE)
    place(f.body, 0, bodyY, w, bodyH)
    paint(f.body, GLASS)
    place(f.lip, 0, bodyY + bodyH, w, g.lipH)
    place(f.edges[1], 0, bodyY, EDGE, bodyH)
    place(f.edges[2], w - EDGE, bodyY, EDGE, bodyH)
    f.edgeColor = nil
    f.mouthY = bodyY + bodyH
    f.corkDrop = min(max(6, floor(cell * 0.5)), g.corkH + GAP_ROW - 2)
    f.hl:ClearAllPoints()
    f.hl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", EDGE, bodyY + EDGE)
    f.hl:SetWidth(w - EDGE * 2)
    f.hl:SetHeight(bodyH - EDGE * 2)
    f.liq:ClearAllPoints()
    f.liq:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", WALL, bodyY + WALL)
    f.liq:SetWidth(cell)
    f.liq:SetHeight(bodyH - WALL * 2)
    local capH = bowlH + WALL - EDGE
    place(f.cap, 0, -capH, cell, capH)
    f.capCol = nil
    f.up = 0
    local fontPath = GameFontNormal:GetFont()
    f.tokI = max(6, floor(cell * ICON_K))
    for s = 1, CAP do
        local it = f.slots[s]
        it.fy, it.fh = nil, nil
        it.icon:SetWidth(f.tokI)
        it.icon:SetHeight(f.tokI)
        ns.SetFont(it.q, fontPath, max(8, floor(cell * 0.42)), "OUTLINE")
        it.q:ClearAllPoints()
        it.q:SetPoint("CENTER", f.liq, "BOTTOMLEFT", cell / 2,
                (s - 1) * (cell + SLOT_GAP) + cell / 2)
    end
    f.bub:ClearAllPoints()
    f.bub:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", WALL, bodyY + WALL)
    f.bub:SetWidth(cell)
    f.bub:SetHeight(bodyH - WALL * 2)
    f.bubSize = max(2, floor(cell * 0.11))
    for k = 1, BUBBLES do
        local lane = (k - 1 + (f.idx or 1) % BUBBLES) % BUBBLES
        f.bubX[k] = floor(cell * (0.20 + 0.30 * lane))
        f.bubs[k]:SetWidth(f.bubSize)
        f.bubs[k]:SetHeight(f.bubSize)
    end
    f.glass:ClearAllPoints()
    f.glass:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.glass:SetWidth(w)
    f.glass:SetHeight(g.flaskH)
    place(f.shine, WALL + 1, bodyY + WALL + 3, max(2, floor(cell * 0.10)), bodyH - WALL * 2 - 8)
    placeCork(f, g, 0)
    f.stamp = g.stamp
end
local function placeFill(it, y, h, cell)
    if it.fy == y and it.fh == h then
        return
    end
    it.fy, it.fh = y, h
    place(it.fill, -EDGE, y, cell + EDGE * 2, h)
end
local desatOK
local function tintHerb(t, col)
    t:SetBlendMode("ADD")
    local ok = t:SetDesaturated(true)
    if desatOK == nil then
        desatOK = ok and true or false
    end
    if desatOK then
        local c = HUE_ICON[col] or HUE_ICON[1]
        t:SetVertexColor(c[1], c[2], c[3])
        t:SetAlpha(ICON_A)
    else
        t:SetVertexColor(1, 1, 1)
        t:SetAlpha(ICON_A_RAW)
    end
end
local function paintSlot(it, col, icons, hidden, showIcon, gLo, gHi)
    if not col then
        if it.col ~= false then
            it.col, it.icoTex = false, nil
            it.fill:Hide();
            it.icon:Hide();
            it.q:Hide()
        end
        return
    end
    local key = hidden and -1 or col
    if it.col ~= key or it.gLo ~= gLo or it.gHi ~= gHi then
        it.col, it.gLo, it.gHi = key, gLo, gHi
        local h = hidden and COL_HIDDEN or (HUE[col] or HUE[1])
        ns.Gradient(it.fill, "VERTICAL",
                h[1] * gLo, h[2] * gLo, h[3] * gLo, 1,
                h[1] * gHi, h[2] * gHi, h[3] * gHi, 1)
        if hidden then
            it.q:Show()
        else
            it.q:Hide()
        end
        it.fill:Show()
    end
    local want = (not hidden) and showIcon and icons[col] or nil
    if it.icoTex ~= want or (want and it.icoCol ~= col) then
        it.icoTex, it.icoCol = want, col
        if want then
            it.icon:SetTexture(want)
            ns.CropIcon(it.icon)
            tintHerb(it.icon, col)
            it.icon:Show()
        else
            it.icon:Hide()
        end
    end
end
local function placeToken(f, it)
    it.icon:ClearAllPoints()
    it.icon:SetPoint("BOTTOMLEFT", f.liq, "BOTTOMLEFT",
            floor(it.dw / 2), floor(it.dy + it.dh / 2))
end
local function makeFly(canvas)
    local f = ns.NewFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + 20)
    f.fill = f:CreateTexture(nil, "ARTWORK")
    f.fill:SetTexture(DISC)
    return f
end
local function buildUI(canvas)
    local u = {}
    u.hud = ns.NewFrame("Frame", nil, canvas)
    u.hud:SetAllPoints(canvas)
    u.hud:SetFrameLevel(canvas:GetFrameLevel() + HUD_LEVEL)
    u.status = u.hud:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    u.status:SetPoint("TOPLEFT", u.hud, "TOPLEFT", MARGIN_X, -8)
    u.status:Hide()
    u.plate = ns.NewFrame("Frame", nil, u.hud)
    u.plate:SetPoint("CENTER", u.hud, "CENTER", 0, 0)
    u.plate:SetHeight(PLATE_H)
    u.plate:SetBackdrop(ns.CARD_BACKDROP)
    u.plate:SetBackdropColor(0, 0, 0, PLATE_A)
    u.plate:Hide()
    u.pass = u.plate:CreateFontString(nil, "OVERLAY", "NumberFont_Outline_Large")
    u.pass:SetPoint("CENTER", u.plate, "CENTER", 0, 0)
    u.pass:SetTextColor(1, 0.82, 0)
    u.note = u.hud:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    u.note:SetPoint("LEFT", u.status, "RIGHT", 14, 0)
    u.note:SetTextColor(1, 0.62, 0.25)
    u.note:Hide()
    return u
end
local function makeBack(canvas)
    local f = ns.NewFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel())
    f:SetAllPoints(canvas)
    f.base = f:CreateTexture(nil, "BACKGROUND")
    f.base:SetAllPoints(f)
    paint(f.base, BG_BASE)
    f.pic = f:CreateTexture(nil, "BORDER")
    f.pic:SetAllPoints(f)
    f.pic:SetVertexColor(BG_TINT[1], BG_TINT[2], BG_TINT[3])
    f.pic:SetAlpha(BG_A)
    f.veil = f:CreateTexture(nil, "ARTWORK")
    f.veil:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.veil:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.veil:SetHeight(max(1, floor(canvas.H * VEIL_K)))
    f.veil:SetTexture(WHITE)
    ns.Gradient(f.veil, "VERTICAL", 0, 0, 0, 0, 0, 0, 0, VEIL_A)
    f.ledge = f:CreateTexture(nil, "ARTWORK")
    f.ledge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.ledge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.ledge:SetHeight(LEDGE_H)
    f.ledge:SetTexture(WHITE)
    ns.Gradient(f.ledge, "VERTICAL",
            LEDGE_TOP[1] * LEDGE_LOW, LEDGE_TOP[2] * LEDGE_LOW, LEDGE_TOP[3] * LEDGE_LOW, 1,
            LEDGE_TOP[1], LEDGE_TOP[2], LEDGE_TOP[3], 1)
    f.ledgeEdge = f:CreateTexture(nil, "OVERLAY")
    f.ledgeEdge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, LEDGE_H - 2)
    f.ledgeEdge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, LEDGE_H - 2)
    f.ledgeEdge:SetHeight(2)
    paint(f.ledgeEdge, LEDGE_EDGE)
    f.ledgeDark = f:CreateTexture(nil, "OVERLAY")
    f.ledgeDark:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.ledgeDark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.ledgeDark:SetHeight(1)
    paint(f.ledgeDark, LEDGE_DARK)
    f.plank = f:CreateTexture(nil, "OVERLAY")
    f.plank:SetTexture(WHITE)
    ns.Gradient(f.plank, "VERTICAL",
            LEDGE_EDGE[1] * PLANK_LOW, LEDGE_EDGE[2] * PLANK_LOW, LEDGE_EDGE[3] * PLANK_LOW, 1,
            LEDGE_EDGE[1], LEDGE_EDGE[2], LEDGE_EDGE[3], 1)
    f.plank:Hide()
    return f
end
local function pickBack(seed)
    if not back then
        return
    end
    local list = {}
    for _, name in ipairs(BG_PICS) do
        local path = ns.Pics.Path(BG_SET, name)
        if path then
            list[#list + 1] = path
        end
    end
    if #list == 0 then
        back.pic:Hide()
        return
    end
    local path = list[ns.RNG.New(seed + BG_SALT):Int(#list)]
    back.pic:SetTexture(path)
    if not back.pic:GetTexture() then
        back.pic:Hide()
        return
    end
    back.pic:SetDesaturated(false)
    back.pic:SetVertexColor(BG_TINT[1], BG_TINT[2], BG_TINT[3])
    back.pic:SetAlpha(BG_A)
    ns.Pics.Fit(back.pic, path, back:GetWidth(), back:GetHeight())
    back.pic:Show()
end
local function ensureUI(self)
    back = back or makeBack(self.canvas)
    flaskPool = flaskPool or ns.NewPool(function()
        return makeFlask(self.canvas)
    end,
            function(f)
                f.locked = false
                f.baseColor = COL_IDLE
                f.liq:SetAlpha(1)
                f.bub:SetAlpha(1)
            end)
    flyPool = flyPool or ns.NewPool(function()
        return makeFly(self.canvas)
    end)
    ui = ui or buildUI(self.canvas)
end
local function bezier(t, p0, p1, p2, p3)
    local u = 1 - t
    return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3
end
local function slotXY(self, i, s)
    local r = self.rect[i]
    local g = self.geom
    return r.x + WALL, r.y + g.bowlH + WALL + (s - 1) * (g.cell + SLOT_GAP)
end
local function drawFly(self)
    flyPool:Reset()
    local fl = self.fly
    if not fl or not self.rect[fl.from] or not self.rect[fl.to] then
        flyPool:HideExtras()
        return
    end
    local g = self.geom
    local rf, rt = self.rect[fl.from], self.rect[fl.to]
    local apex = max(rf.y + rf.h, rt.y + rt.h) + ARC_UP
    local hue = HUE[fl.col] or HUE[1]
    local _, yS = slotXY(self, fl.from, fl.na - fl.m + 1)
    local drainT = flyDrain(fl.m)
    for k = 1, fl.m do
        local _, y1 = slotXY(self, fl.to, fl.nb + k)
        for j = 1, DROPS do
            local dep = (k - 1) * FLY_LAG + (j - 1) * DROP_LAG
            local t = (fl.t - dep) / FLY_DUR
            if t >= 0 and t < 1 then
                local size = max(3, floor(g.cell * DROP_K[j]))
                local x0 = rf.x + floor((g.flaskW - size) / 2)
                local x1 = rt.x + floor((g.flaskW - size) / 2)
                local q = dep / drainT
                if q > 1 then
                    q = 1
                end
                local y0 = yS + floor(fl.m * g.cell * (1 - q))
                local f = flyPool:Acquire()
                f:SetWidth(size)
                f:SetHeight(size)
                f:ClearAllPoints()
                f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT",
                        floor(bezier(t, x0, x0, x1, x1)), floor(bezier(t, y0, apex, apex, y1)))
                place(f.fill, 0, 0, size, size)
                f.fill:SetVertexColor(hue[1], hue[2], hue[3])
            end
        end
    end
    flyPool:HideExtras()
end
local DISP, RUN_LO, RUN_HI = {}, {}, {}
local function runs(bag, vis, blind, seen)
    for s = 1, CAP do
        local v = bag[s]
        if s > vis then
            v = nil
        end
        if v and blind and not (seen and seen[s]) then
            v = -1
        end
        DISP[s] = v
    end
    local s, top = 1, 0
    while s <= CAP and DISP[s] do
        local e = s
        while e < CAP and DISP[e + 1] == DISP[s] do
            e = e + 1
        end
        for k = s, e do
            RUN_LO[k], RUN_HI[k] = s, e
        end
        top = e
        s = e + 1
    end
    return top
end
function tickLiquid(self, dt)
    if not flaskPool or not self.geom then
        return
    end
    local t = (self.bubT or 0) + dt
    self.bubT = t
    local items = flaskPool.items
    for i = 1, self.n do
        local f = items[i]
        if not f then
            break
        end
        local span = f.bubOn and (f.bubY1 - f.bubY0 - f.bubSize) or 0
        for k = 1, BUBBLES do
            local b = f.bubs[k]
            if span < 3 then
                b:Hide()
            else
                local salt = i * 7 + k * 13
                local rise = BUB_RISE * (0.7 + (salt % 13) / 13 * 0.6)
                local p = (t / rise + (salt % 17) / 17) % 1
                local sway = sin(t * BUB_SWAY + salt) * f.bubSize * 0.7
                b:ClearAllPoints()
                b:SetPoint("BOTTOMLEFT", f.bub, "BOTTOMLEFT",
                        floor(f.bubX[k] + sway), floor(f.bubY0 + p * span))
                local a = 1
                if p < 0.15 then
                    a = p / 0.15
                elseif p > 0.82 then
                    a = (1 - p) / 0.18
                end
                b:SetAlpha(a * BUB_A)
                b:Show()
            end
        end
    end
end
function Game:Draw()
    ensureUI(self)
    if back.seed ~= self.seed then
        back.seed = self.seed
        pickBack(self.seed)
    end
    back:Show()
    local canvas = self.canvas
    if not self.geom then
        self.geom = layout(canvas, self.n)
        self.geom.stamp = self.stamp
    end
    local g = self.geom
    local cell = g.cell
    local fl = self.fly
    local landed = 0
    if fl then
        for k = 1, fl.m do
            if fl.t >= (k - 1) * FLY_LAG + FLY_DUR then
                landed = landed + 1
            end
        end
    end
    local yBase = LEDGE_H
    if g.rows == 2 then
        local rowW = g.perRow * g.flaskW + (g.perRow - 1) * GAP_X
        place(back.plank, floor((canvas.W - rowW) / 2) - PLANK_OUT,
                yBase + g.flaskH + GAP_ROW - PLANK_H, rowW + PLANK_OUT * 2, PLANK_H)
        back.plank:Show()
    else
        back.plank:Hide()
    end
    flaskPool:Reset()
    for i = 1, self.n do
        local f = flaskPool:Acquire()
        f.idx = i
        if f.stamp ~= g.stamp then
            layoutFlask(f, g)
        end
        local r = ceil(i / g.perRow)
        local col = i - (r - 1) * g.perRow
        local inRow = self.n - (r - 1) * g.perRow
        if inRow > g.perRow then
            inRow = g.perRow
        end
        local rowW = inRow * g.flaskW + (inRow - 1) * GAP_X
        local x = floor((canvas.W - rowW) / 2 + (col - 1) * (g.flaskW + GAP_X))
        local y = floor(yBase + (g.rows - r) * (g.flaskH + GAP_ROW))
        local up = (self.picked == i) and LIFT or 0
        if f.up ~= up then
            f.up = up
            place(f.shadow, WALL, -SHADOW_H - up, cell, SHADOW_H)
        end
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y + up)
        self.rect[i] = { x = x, y = y + up, w = g.flaskW, h = g.flaskH }
        local bag = self.bag[i]
        local nOcc = #bag
        local isCork = Apo.Corked(self, i)
        local closing = isCork and not (self.cork and self.cork.i == i and self.cork.wait)
        f.locked = isCork
        if self.flash and self.flash.i == i then
            f.baseColor = COL_FLASH
        elseif self.picked == i then
            f.baseColor = COL_PICKED
        elseif closing then
            f.baseColor = COL_CORKED
        else
            f.baseColor = COL_IDLE
        end
        styleFlask(f)
        if closing then
            local a, dy = 1, 0
            if self.cork and self.cork.i == i then
                local k = 1 - self.cork.t / ANIM_CORK
                dy = floor(f.corkDrop * (1 - k * k))
                a = k < 0.33 and (k / 0.33) or 1
            end
            placeCork(f, g, dy)
            showCork(f, a)
            f.liq:SetAlpha(0.55)
            f.bub:SetAlpha(0.55)
            f.hl:SetAlpha(0)
        else
            hideCork(f)
            f.liq:SetAlpha(1)
            f.bub:SetAlpha(1)
            f.hl:SetAlpha(1)
        end
        local vis, partH, drainS, drainH = nOcc, nil, nil, nil
        if fl and i == fl.to then
            vis = fl.nb + landed
            if landed > 0 then
                local p = (fl.t - ((landed - 1) * FLY_LAG + FLY_DUR)) / FILL_T
                if p < 1 then
                    partH = max(2, floor(cell * p))
                end
            end
        elseif fl and i == fl.from then
            local q = fl.t / flyDrain(fl.m)
            if q < 1 then
                drainS = fl.na - fl.m + 1
                drainH = max(1, floor(fl.m * cell * (1 - q)))
            end
        end
        local top = runs(bag, vis, self.blind, self.seen[i])
        local wob = 0
        if top < CAP and self.ripple and self.ripple.i == i and self.ripple.t > 0 then
            local p = self.ripple.t / RIPPLE_DUR
            wob = floor(g.wob * (1 - p) * sin(p * RIPPLE_W) + 0.5)
        end
        for s = 1, CAP do
            local v = DISP[s]
            local hidden = v == -1
            local raw = v and bag[s] or nil
            local lo, hi = RUN_LO[s], RUN_HI[s]
            local gLo, gHi = LIQ_LOW, 1
            if v then
                local len = hi - lo + 1
                gLo = LIQ_LOW + (1 - LIQ_LOW) * (s - lo) / len
                gHi = LIQ_LOW + (1 - LIQ_LOW) * (s - lo + 1) / len
                local y = (s - 1) * (cell + SLOT_GAP)
                local h = cell + (s < hi and SLOT_GAP or 0)
                if partH and s == top then
                    h = partH
                end
                if s == top and wob ~= 0 then
                    h = max(2, h + wob)
                end
                placeFill(f.slots[s], y, h, cell)
            end
            local it = f.slots[s]
            local showIcon = v and s == hi and not (partH and s == top) or false
            paintSlot(it, raw, self.icons, hidden, showIcon, gLo, gHi)
            if it.icoTex then
                local yLo = (lo - 1) * (cell + SLOT_GAP)
                local yHi = (s - 1) * (cell + SLOT_GAP) + cell
                it.dy = yLo
                it.dw = max(0, cell - f.tokI)
                it.dh = max(0, yHi - yLo - f.tokI)
                placeToken(f, it)
            end
        end
        if drainS and drainS <= CAP then
            local it = f.slots[drainS]
            placeFill(it, (drainS - 1) * (cell + SLOT_GAP), drainH, cell)
            paintSlot(it, fl.col, self.icons, false, false, LIQ_LOW, 1)
        end
        local bot = DISP[1]
        if bot then
            local key = (bot == -1) and -1 or bag[1]
            if f.capCol ~= key then
                f.capCol = key
                local h = (bot == -1) and COL_HIDDEN or (HUE[bag[1]] or HUE[1])
                f.cap:SetVertexColor(h[1] * LIQ_LOW, h[2] * LIQ_LOW, h[3] * LIQ_LOW)
            end
            f.cap:Show()
        else
            f.cap:Hide()
        end
        local surfY
        if drainS then
            surfY = (drainS - 1) * (cell + SLOT_GAP) + drainH - 2
        elseif top > 0 then
            surfY = (top - 1) * (cell + SLOT_GAP) + (partH or cell) - 2 + wob
        end
        if surfY then
            place(f.surf, -EDGE, surfY, cell + EDGE * 2, 2)
            f.surf:Show()
        else
            f.surf:Hide()
        end
        if top > 0 and DISP[top] ~= -1 and not closing then
            f.bubY0 = 0
            f.bubY1 = (top - 1) * (cell + SLOT_GAP) + cell
            f.bubOn = true
        else
            f.bubOn = false
            for k = 1, BUBBLES do
                f.bubs[k]:Hide()
            end
        end
        local glowOn = f.bubOn and self.picked ~= i
        if glowOn then
            local room = g.bodyH - WALL * 2 - f.bubY1
            local h = min(floor(cell * GLOW_K), room)
            if h >= 3 then
                local c = HUE[DISP[top]] or HUE[1]
                local m = GLOW_MIX
                local r, gg, b = c[1] + (1 - c[1]) * m, c[2] + (1 - c[2]) * m, c[3] + (1 - c[3]) * m
                ns.Gradient(f.glow, "VERTICAL", r, gg, b, GLOW_A, r, gg, b, 0)
                local dip = floor(cell * GLOW_DIP)
                place(f.glow, -EDGE, f.bubY1 - dip, cell + EDGE * 2, h + dip)
                f.glow:Show()
            else
                glowOn = false
            end
        end
        if not glowOn then
            f.glow:Hide()
        end
    end
    flaskPool:HideExtras()
    drawFly(self)
    ui.hud:Show()
    local left = ns.T("apothecary.statusLevel", self.level)
    if self.blind then
        left = left .. ns.T("apothecary.statusBlindSuffix")
    end
    ui.status:SetText(left)
    ui.status:Show()
    if self.pass then
        ui.pass:SetText(ns.T("apothecary.statusPassed", self.pass.level))
        ui.plate:SetWidth(ui.pass:GetStringWidth() + 44)
        ui.plate:Show()
    else
        ui.plate:Hide()
    end
    self:Bar()
    if self.stuck and not self.pass then
        ui.note:SetText(ns.T("apothecary.stuckNote"))
        ui.note:Show()
    else
        ui.note:Hide()
    end
end
function Game:Stage(n)
    setLevel(self, max(1, floor(n)))
    checkStuck(self)
    self:Bar()
    self:Draw()
end
local MINI_LOW = { 0.86, 0.22, 0.22 }
local MINI_TOP = { 0.30, 0.68, 0.96 }
local MINI_FULL = { 0.36, 0.74, 0.34 }
local MINI = {
    {
        cols = 1, rows = 4, cell = 30, gap = 2, back = "plain", face = GLASS,
        fill = {
            { c = 1, r = 1, col = MINI_LOW }, { c = 1, r = 2, col = MINI_LOW },
            { c = 1, r = 3, col = MINI_TOP }, { c = 1, r = 4, col = MINI_TOP },
        },
        ring = { { c = 1, r = 3 }, { c = 1, r = 4 } },
    },
    {
        cols = 3, rows = 4, cell = 26, gap = 3, back = "plain", face = GLASS,
        fill = {
            { c = 1, r = 1, col = MINI_LOW }, { c = 1, r = 2, col = MINI_LOW },
            { c = 1, r = 3, col = MINI_TOP }, { c = 1, r = 4, col = MINI_TOP },
            { c = 3, r = 1, col = MINI_TOP },
        },
        ring = { { c = 1, r = 3 }, { c = 1, r = 4 } },
        arrow = {
            { c1 = 1, r1 = 4, c2 = 2, r2 = 1, col = MINI_TOP },
            { c1 = 1, r1 = 4, c2 = 3, r2 = 2, col = MINI_TOP },
        },
    },
    {
        cols = 1, rows = 4, cell = 30, gap = 2, back = "plain", face = GLASS,
        fill = {
            { c = 1, r = 1, col = MINI_FULL }, { c = 1, r = 2, col = MINI_FULL },
            { c = 1, r = 3, col = MINI_FULL }, { c = 1, r = 4, col = MINI_FULL },
        },
        dot = { { c = 1, r = 4, col = COL_HOVER } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, spec.face)
    for _, m in ipairs(spec.fill or {}) do
        g:Fill(m.c, m.r, m.col)
    end
    for _, m in ipairs(spec.ring or {}) do
        g:Ring(m.c, m.r, 0.75)
    end
    for _, m in ipairs(spec.dot or {}) do
        g:Dot(m.c, m.r, m.col)
    end
    for _, m in ipairs(spec.arrow or {}) do
        g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col)
    end
end
local function helpBlock(host)
    paintMini(host, MINI[1])
end
local function helpTarget(host)
    paintMini(host, MINI[2])
end
local function helpSeal(host)
    paintMini(host, MINI[3])
end
ns.RegisterGame {
    id = ID,
    label = "apothecary.label",
    icon = ns.herbDB and ns.herbDB[1] and ns.herbDB[1].id,
    tip = "apothecary.tip",
    order = 4,
    duo = "score",
    physics = false,
    look = LOOK,
    clock = "off",
    tally = false,
    record = false,
    again = false,
    done = true,
    stages = { max = 999 },
    New = New,
    help = function()
        return {
            ns.T("apothecary.help1"),
            ns.T("apothecary.help2"),
            { art = helpBlock, h = 134 },
            ns.T("apothecary.help3"),
            { art = helpTarget, h = 121 },
            ns.T("apothecary.help4"),
            { art = helpSeal, h = 134 },
            ns.T("apothecary.help5"),
            ns.T("apothecary.help6"),
            ns.T("apothecary.help7"),
        }
    end,
}
function RaidWaitingArcadeApothecaryTest(n)
    n = n or 50
    local bad, walked, worstNodes, worstTries = 0, 0, 0, 0
    for level = 1, 20 do
        local colors = colorsFor(level)
        local empty = EMPTY
        local sumTries, sumNodes = 0, 0
        for t = 1, n do
            local rng = ns.RNG.New(t * 1000003 + level * 7919)
            local bag, tries, nodes = ns.Apo.Build(rng, colors, CAP, empty)
            sumTries = sumTries + tries
            sumNodes = sumNodes + nodes
            if nodes > worstNodes then
                worstNodes = nodes
            end
            if tries > worstTries then
                worstTries = tries
            end
            if not bag then
                bad = bad + 1
            elseif tries > (ns.Apo.TRIES or 20) then
                walked = walked + 1
            else
                local full, free = 0, 0
                for i = 1, colors + empty do
                    local len = #bag[i]
                    if len == CAP then
                        full = full + 1
                    elseif len == 0 then
                        free = free + 1
                    end
                end
                if full ~= colors or free ~= empty then
                    bad = bad + 1
                end
            end
        end
        ns.say(("уровень %d: видов %d, свободных %d, столов %d, пересдач в среднем %.2f, узлов в среднем %d")
                :format(level, colors, empty, n, sumTries / n - 1, floor(sumNodes / n)))
    end
    ns.say(("обратной прогулкой построено столов: %d"):format(walked))
    ns.say(("худший стол: пересдач %d, узлов %d"):format(worstTries, worstNodes))
    ns.say(bad == 0 and "генератор чист" or ("провалов: " .. bad))
end
function RaidWaitingArcadeApothecaryStuck(maxNodes)
    if not cur or cur.pass then
        ns.say("аптекарь: партии нет");
        return
    end
    if cur.stuck then
        ns.say("аптекарь: стол уже в тупике");
        return
    end
    maxNodes = maxNodes or 50000
    local function key(bag)
        local parts = {}
        for i = 1, #bag do
            parts[i] = table.concat(bag[i], ",")
        end
        return table.concat(parts, "|")
    end
    local n, cap = cur.n, CAP
    local seen = {}
    local stack = { { bag = Apo.CopyBag(cur.bag), path = {} } }
    seen[key(cur.bag)] = true
    local nodes = 0
    while #stack > 0 do
        local node = stack[#stack]
        stack[#stack] = nil
        nodes = nodes + 1
        if nodes > maxNodes then
            break
        end
        local st = { bag = node.bag, n = n, cap = cap }
        if not Apo.HasMove(st) and not Apo.Solved(st) then
            for i = 1, #node.path do
                local mv = node.path[i]
                cur:Move { k = "pour", from = mv[1], to = mv[2] }
            end
            ns.say(("аптекарь: тупик за %d переливов, просмотрено %d узлов"):format(#node.path, nodes))
            return
        end
        for from = 1, n do
            for to = 1, n do
                if Apo.CanPour(st, from, to) then
                    local nb = Apo.CopyBag(node.bag)
                    Apo.Pour({ bag = nb, n = n, cap = cap }, from, to)
                    local k = key(nb)
                    if not seen[k] then
                        seen[k] = true
                        local path = {}
                        for i = 1, #node.path do
                            path[i] = node.path[i]
                        end
                        path[#path + 1] = { from, to }
                        stack[#stack + 1] = { bag = nb, path = path }
                    end
                end
            end
        end
    end
    ns.say(("аптекарь: тупик не найден, просмотрено %d узлов"):format(nodes))
end
function RaidWaitingArcadeApothecaryLadder(n)
    local box = ladder()
    box.done = max(0, floor(tonumber(n) or 0))
    ns.say(("лестница: пройдено %d, следующая ступень %d"):format(box.done, box.done + 1))
    if cur and ns.window and ns.window.Restart then
        ns.Store.Clear(ID)
        ns.window:StartGame(ID)
    end
end
