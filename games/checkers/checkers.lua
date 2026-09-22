local ADDON, ns = ...
local ID = "checkers"
local floor = math.floor
local N = 8
local CELLS = N * N
local START_MEN = 12
local DRAW_PLY = 60
local EMPTY, W_MAN, W_KING, B_MAN, B_KING = 0, 1, 2, 3, 4
local WHITE, BLACK = 1, 2
local DIRS = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local function cr(i)
    local c = (i - 1) % N + 1
    return c, floor((i - 1) / N) + 1
end
local function idx(c, r)
    return (r - 1) * N + c
end
local function onBoard(c, r)
    return c >= 1 and c <= N and r >= 1 and r <= N
end
local function dark(c, r)
    return (r + c) % 2 == 0
end
local function sideOf(p)
    return (p <= W_KING) and WHITE or BLACK
end
local function isKing(p)
    return p == W_KING or p == B_KING
end
local FILES = { "a", "b", "c", "d", "e", "f", "g", "h" }
local function sqName(i)
    local c, r = cr(i)
    return FILES[c] .. r
end
local function record(self, f, t, took, chained)
    if not self.log then return end
    if chained and self.log[#self.log] then
        self.log[#self.log] = self.log[#self.log] .. ":" .. sqName(t)
    else
        self.log[#self.log + 1] = sqName(f) .. (took and ":" or "-") .. sqName(t)
    end
    self.ply = #self.log
end
local MARGIN = 14
local TOPGAP = 26
local PAD = 6
local BOARD_MAX = 416
local ZONE = BOARD_MAX + PAD * 2
local MINI_MARGIN = 11
local MINI_W = MINI_MARGIN * 2 + ZONE
local MINI_H = MINI_W
local COL_W = 170
local PANEL_PAD = 12
local COL = COL_W - PANEL_PAD * 2
local TURN_DISC = 26
local FOE_DISC = 18
local SIDE_DISC = 12
local LOG_ROW = 15
local LOG_VIS = 10
local LOG_NUM = 22
local LOG_HALF = 62
local LOG_TOP = 254
local M_PAD = 16
local CAP_TOP = 14
local TILE_W, TILE_H, TILE_GAP = 146, 104, 8
local TILE_TOP = 31
local SEAM1 = 147
local BAND_CAP = 162
local BAND_TOP = 176
local PREV_CELL = 25
local INFO_X = 248
local INFO_TOP = 178
local INFO_STEP = 22
local RULE_CAP = 264
local RULE_TOP = 280
local RULE_STEP = 20
local SEAM2 = 394
local PLAY_TOP, PLAY_W, PLAY_H = 408, 220, 44
local NOTE_TOP = 458
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local BACK_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local C_LIGHT = { 0.72, 0.63, 0.48, 1 }
local C_DARK  = { 0.34, 0.25, 0.19, 1 }
local C_GROUT = { 0.04, 0.04, 0.05, 0.95 }
local C_FRAME = { 0.58, 0.47, 0.28, 1 }
local C_RULE  = { 0.21, 0.18, 0.14, 1 }
local C_SEAM  = { 0.52, 0.42, 0.26, 0.45 }
local C_CAP  = { 0.54, 0.51, 0.45 }
local C_TEXT = { 0.91, 0.90, 0.86 }
local C_SOFT = { 0.65, 0.61, 0.53 }
local C_DIM  = { 0.42, 0.39, 0.34 }
local C_GOLD = { 1, 0.82, 0 }
local C_LIVE = { 0.44, 0.75, 0.36 }
local C_WARN = { 0.79, 0.64, 0.15 }
local C_GONE = { 0.48, 0.45, 0.39 }
local LOOK = ns.MakeLook{ wood = { 0.230, 0.190, 0.130 }, edge = C_GOLD }
local P_WHITE = {
    face = { 0.93, 0.91, 0.84 }, ring = { 0.40, 0.33, 0.22 },
    faceTop = { 0.97, 0.95, 0.89 }, faceLow = { 0.86, 0.82, 0.72 },
    edgeTop = { 0.88, 0.82, 0.67 }, edgeLow = { 0.46, 0.38, 0.25 },
}
local P_BLACK = {
    face = { 0.16, 0.15, 0.18 }, ring = { 0.72, 0.68, 0.60 },
    faceTop = { 0.29, 0.28, 0.32 }, faceLow = { 0.16, 0.15, 0.19 },
    edgeTop = { 0.72, 0.68, 0.61 }, edgeLow = { 0.33, 0.31, 0.29 },
}
local C_SHADE = { 0, 0, 0 }
local C_GLOSS = { 1, 1, 1 }
local C_PIP_TOP = { 1, 0.90, 0.44 }
local C_PIP_LOW = { 0.66, 0.46, 0.05 }
local PIECE = {
    shade = { d = 1.00, x = 0.05, y = -0.10 },
    edge  = { d = 1.00, y = -0.05 },
    face  = { d = 0.84, y = 0 },
    gloss = { d = 0.42, y = 0.17 },
    pip   = { d = 0.34, y = 0 },
    eye   = { d = 0.17, y = 0 },
}
local A_SHADE, A_GLOSS = 0.42, 0.20
local A_DEAD = 0.4
local A_MUST = 0.35
local A_SEL  = 0.65
local A_GOAL = 0.3
local A_LOCK = 0.42
local FOES = {
    { key = "easy", label = "checkers.foeEasyLabel", name = "checkers.foeEasyName",
      desc = "checkers.foeEasyDesc", depth = 2, ms = 250 },
    { key = "mid", label = "checkers.foeMidLabel", name = "checkers.foeMidName",
      desc = "checkers.foeMidDesc", depth = 5, ms = 700 },
    { key = "hard", label = "checkers.foeHardLabel", name = "checkers.foeHardName",
      desc = "checkers.foeHardDesc", depth = 12, ms = 1800 },
    { key = "duo", label = "checkers.foeDuoLabel", name = "checkers.foeDuoName",
      desc = "checkers.foeDuoDesc" },
}
local DEF_FOE = "mid"
local function foeBy(key)
    local fallback
    for _, f in ipairs(FOES) do
        if f.key == key then return f end
        if f.key == DEF_FOE then fallback = f end
    end
    return fallback or FOES[1]
end
local Game = {}
Game.__index = Game
local function capturesFrom(self, i, out)
    local p = self.b[i]
    if p == EMPTY then return end
    local side = sideOf(p)
    local king = isKing(p)
    local c, r = cr(i)
    for d = 1, 4 do
        local dc, dr = DIRS[d][1], DIRS[d][2]
        local cc, rr = c + dc, r + dr
        if king then
            while onBoard(cc, rr) and self.b[idx(cc, rr)] == EMPTY do
                cc, rr = cc + dc, rr + dr
            end
        end
        if onBoard(cc, rr) then
            local m = idx(cc, rr)
            local q = self.b[m]
            if q ~= EMPTY and not self.dead[m] and sideOf(q) ~= side then
                local lc, lr = cc + dc, rr + dr
                if king then
                    while onBoard(lc, lr) and self.b[idx(lc, lr)] == EMPTY do
                        out[#out + 1] = { f = i, t = idx(lc, lr), cap = m }
                        lc, lr = lc + dc, lr + dr
                    end
                elseif onBoard(lc, lr) and self.b[idx(lc, lr)] == EMPTY then
                    out[#out + 1] = { f = i, t = idx(lc, lr), cap = m }
                end
            end
        end
    end
end
local function quietFrom(self, i, out)
    local p = self.b[i]
    if p == EMPTY then return end
    local c, r = cr(i)
    if isKing(p) then
        for d = 1, 4 do
            local dc, dr = DIRS[d][1], DIRS[d][2]
            local cc, rr = c + dc, r + dr
            while onBoard(cc, rr) and self.b[idx(cc, rr)] == EMPTY do
                out[#out + 1] = { f = i, t = idx(cc, rr) }
                cc, rr = cc + dc, rr + dr
            end
        end
        return
    end
    local dr = (sideOf(p) == WHITE) and 1 or -1
    for k = 1, 2 do
        local dc = (k == 1) and -1 or 1
        local cc, rr = c + dc, r + dr
        if onBoard(cc, rr) and self.b[idx(cc, rr)] == EMPTY then
            out[#out + 1] = { f = i, t = idx(cc, rr) }
        end
    end
end
function Game:Legal()
    if self.legal then return self.legal end
    local out = {}
    if not self.over then
        if self.chain then
            capturesFrom(self, self.chain, out)
        else
            for i = 1, CELLS do
                local p = self.b[i]
                if p ~= EMPTY and sideOf(p) == self.side then
                    capturesFrom(self, i, out)
                end
            end
            if #out == 0 then
                for i = 1, CELLS do
                    local p = self.b[i]
                    if p ~= EMPTY and sideOf(p) == self.side then
                        quietFrom(self, i, out)
                    end
                end
            end
        end
    end
    self.legal = out
    return out
end
local function endTurn(self)
    if self.deadN > 0 then
        for i = 1, CELLS do
            if self.dead[i] then
                self.b[i] = EMPTY
                self.dead[i] = false
            end
        end
        self.deadN = 0
    end
    self.chain = nil
    if self.tookTurn or self.promTurn or self.manTurn then
        self.idle = 0
    else
        self.idle = self.idle + 1
    end
    self.tookTurn, self.promTurn, self.manTurn = false, false, false
    self.side = (self.side == WHITE) and BLACK or WHITE
    self.legal = nil
    if #self:Legal() == 0 then
        self.over = (self.side == WHITE) and "black" or "white"
    elseif self.idle >= DRAW_PLY then
        self.over = "draw"
    end
    if self.over then self.legal = nil end
end
local function apply(self, move)
    if self.over or type(move) ~= "table" or move.k ~= "mv" then return false, false, false end
    local f, t = move.f, move.t
    if type(f) ~= "number" or type(t) ~= "number" then return false, false, false end
    local chained = self.chain ~= nil
    local m
    local list = self:Legal()
    for k = 1, #list do
        local e = list[k]
        if e.f == f and e.t == t then
            m = e
            break
        end
    end
    if not m then return false, false, false end
    local p = self.b[f]
    local wasMan = not isKing(p)
    self.b[f] = EMPTY
    self.b[t] = p
    local took = false
    if m.cap then
        self.dead[m.cap] = true
        self.deadN = self.deadN + 1
        self.alive = self.alive - 1
        self.tookTurn = true
        took = true
    elseif wasMan then
        self.manTurn = true
    end
    local _, tr = cr(t)
    if p == W_MAN and tr == N then
        self.b[t] = W_KING
        self.promTurn = true
    elseif p == B_MAN and tr == 1 then
        self.b[t] = B_KING
        self.promTurn = true
    end
    self.legal = nil
    local cont = false
    if m.cap then
        local more = {}
        capturesFrom(self, t, more)
        cont = #more > 0
    end
    if cont then
        self.chain = t
    else
        endTurn(self)
    end
    record(self, f, t, took, chained)
    return true, took, self.over ~= nil
end
local SLICE_MS = 8
local THINK_MIN = 0.4
local V_MAN, V_KING = 100, 300
local V_ROW, V_EDGE = 6, 4
local function evaluate(g, me)
    local score = 0
    for i = 1, CELLS do
        local p = g.b[i]
        if p ~= EMPTY and not g.dead[i] then
            local c, r = cr(i)
            local v
            if isKing(p) then
                v = V_KING
            else
                local adv = (sideOf(p) == WHITE) and (r - 1) or (N - r)
                v = V_MAN + adv * V_ROW
            end
            if c == 1 or c == N then v = v + V_EDGE end
            if sideOf(p) == me then score = score + v else score = score - v end
        end
    end
    return score
end
local snaps = {}
local function snapAt(d)
    local s = snaps[d]
    if not s then
        s = { b = {}, dead = {} }
        snaps[d] = s
    end
    return s
end
local function save(g, s)
    local gb, gd, sb, sd = g.b, g.dead, s.b, s.dead
    for i = 1, CELLS do
        sb[i] = gb[i]
        sd[i] = gd[i]
    end
    s.side, s.chain, s.over, s.legal = g.side, g.chain, g.over, g.legal
    s.deadN, s.idle, s.alive = g.deadN, g.idle, g.alive
    s.tookTurn, s.promTurn, s.manTurn = g.tookTurn, g.promTurn, g.manTurn
end
local function restore(g, s)
    local gb, gd, sb, sd = g.b, g.dead, s.b, s.dead
    for i = 1, CELLS do
        gb[i] = sb[i]
        gd[i] = sd[i]
    end
    g.side, g.chain, g.over = s.side, s.chain, s.over
    g.legal = s.legal
    g.deadN, g.idle, g.alive = s.deadN, s.idle, s.alive
    g.tookTurn, g.promTurn, g.manTurn = s.tookTurn, s.promTurn, s.manTurn
end
local function clone(g)
    local c = setmetatable({ b = {}, dead = {} }, Game)
    for i = 1, CELLS do
        c.b[i] = g.b[i]
        c.dead[i] = g.dead[i]
    end
    c.side, c.chain, c.over, c.legal = g.side, g.chain, g.over, nil
    c.deadN, c.idle, c.alive = g.deadN, g.idle, g.alive
    c.tookTurn, c.promTurn, c.manTurn = g.tookTurn, g.promTurn, g.manTurn
    return c
end
local function newJob(self)
    local node = clone(self)
    local me = self.bot
    local sp = 0
    local lvl = foeBy(self.foe)
    local step = { k = "mv" }
    return ns.Search.New{
        node = node,
        me = me,
        depth = lvl.depth or 5,
        budget = lvl.ms or 700,
        moves = function(g) return g:Legal() end,
        turn  = function(g) return g.side end,
        over  = function(g) return g.over ~= nil end,
        eval  = evaluate,
        result = function(g, who)
            if g.over == "draw" then return 0 end
            local win = (g.over == "white") and WHITE or BLACK
            return (win == who) and 1 or -1
        end,
        same = function(a, b) return a.f == b.f and a.t == b.t end,
        apply = function(g, mv)
            sp = sp + 1
            save(g, snapAt(sp))
            step.f, step.t = mv.f, mv.t
            apply(g, step)
            return sp
        end,
        undo = function(g, token)
            restore(g, snapAt(token))
            sp = token - 1
        end,
    }
end
local field, deck, squares, ui, menu, piecePool, markPool
local function coat(tex, anchor, d, k, c1, a1, c2, a2)
    local s = floor(d * k.d + 0.5)
    if s < 1 then s = 1 end
    tex:SetWidth(s)
    tex:SetHeight(s)
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", anchor, "CENTER",
                 floor(d * (k.x or 0) + 0.5), floor(d * k.y + 0.5))
    tex:SetTexture(DISC)
    ns.Gradient(tex, "VERTICAL", c1[1], c1[2], c1[3], a1, c2[1], c2[2], c2[3], a2)
    tex:Show()
end
local function dressPiece(p, anchor, d, tone, king)
    coat(p.shade, anchor, d, PIECE.shade, C_SHADE, A_SHADE, C_SHADE, A_SHADE * 0.25)
    coat(p.edge,  anchor, d, PIECE.edge,  tone.edgeLow, 1, tone.edgeTop, 1)
    coat(p.face,  anchor, d, PIECE.face,  tone.faceLow, 1, tone.faceTop, 1)
    coat(p.gloss, anchor, d, PIECE.gloss, C_GLOSS, 0, C_GLOSS, A_GLOSS)
    if not p.pip then return end
    if king then
        coat(p.pip, anchor, d, PIECE.pip, C_PIP_LOW, 1, C_PIP_TOP, 1)
        coat(p.eye, anchor, d, PIECE.eye, tone.faceLow, 1, tone.faceTop, 1)
    else
        p.pip:Hide()
        p.eye:Hide()
    end
end
local function makePiece(parent)
    local f = ns.PlainFrame(parent, 1)
    f.shade = f:CreateTexture(nil, "BACKGROUND")
    f.edge = f:CreateTexture(nil, "BORDER")
    f.face = f:CreateTexture(nil, "ARTWORK")
    f.gloss = f:CreateTexture(nil, "OVERLAY")
    f.cap = ns.PlainFrame(f, 1)
    f.cap:SetAllPoints(f)
    f.pip = f.cap:CreateTexture(nil, "ARTWORK")
    f.eye = f.cap:CreateTexture(nil, "OVERLAY")
    return f
end
local function makeMark(parent)
    local f = ns.PlainFrame(parent, 3)
    f.tex = f:CreateTexture(nil, "OVERLAY")
    f.tex:SetTexture(ns.CELL_HL)
    f.tex:SetBlendMode("ADD")
    f.tex:SetAllPoints(f)
    return f
end
local function buildColumn(canvas)
    ui.panel = ns.MakeNiche(canvas, 2, LOOK)
    ui.panel:SetWidth(COL_W)
    ui.panel:SetHeight(ZONE)
    ui.panel:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -MARGIN, TOPGAP)
    ui.col = ns.PlainFrame(ui.panel, 1)
    ui.col:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", PANEL_PAD, -PANEL_PAD)
    ui.col:SetPoint("BOTTOMRIGHT", ui.panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
    local function rule(y)
        local t = ns.Fill(ui.col, "ARTWORK", C_RULE)
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y)
    end
    local function pair(y)
        local cap = ns.MakeCap(ui.col, 0, y)
        local val = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetJustifyH("RIGHT")
        val:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y + 1)
        return cap, val
    end
    ui.foeCap = ns.MakeCap(ui.col, 0, 8)
    ui.foeDisc = ui.col:CreateTexture(nil, "ARTWORK")
    ui.foeDisc:SetTexture(DISC)
    ui.foeDisc:SetWidth(FOE_DISC)
    ui.foeDisc:SetHeight(FOE_DISC)
    ui.foeDisc:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -26)
    ui.foeName = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.foeName:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 24, -27)
    ui.foeName:SetJustifyH("LEFT")
    ui.foeName:SetWidth(COL - 24)
    ui.foeDot = ui.col:CreateTexture(nil, "OVERLAY")
    ui.foeDot:SetTexture(DISC)
    ui.foeDot:SetWidth(7)
    ui.foeDot:SetHeight(7)
    ui.foeDot:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 2, -54)
    ui.foeState = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.foeState:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 13, -51)
    ui.foeState:SetJustifyH("LEFT")
    ui.foeState:SetWidth(COL - 13)
    rule(70)
    ui.turnDisc = ui.col:CreateTexture(nil, "ARTWORK")
    ui.turnDisc:SetTexture(DISC)
    ui.turnDisc:SetWidth(TURN_DISC)
    ui.turnDisc:SetHeight(TURN_DISC)
    ui.turnDisc:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -78)
    ui.turn = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.turn:SetPoint("LEFT", ui.turnDisc, "RIGHT", 8, 0)
    ui.turn:SetJustifyH("LEFT")
    ui.turn:SetWidth(COL - TURN_DISC - 8)
    ui.gameCap, ui.gameVal = pair(116)
    ui.gameVal:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
    ui.moveCap, ui.moveVal = pair(138)
    ui.moveVal:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    rule(164)
    ui.cntCap = ns.MakeCap(ui.col, 0, 174)
    ui.cntVal = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.cntVal:SetJustifyH("RIGHT")
    ui.cntVal:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -174)
    ui.cntVal:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.men = {}
    for k = 1, 2 do
        local y = 189 + (k - 1) * 18
        local row = {}
        row.disc = ui.col:CreateTexture(nil, "ARTWORK")
        row.disc:SetTexture(DISC)
        row.disc:SetWidth(SIDE_DISC)
        row.disc:SetHeight(SIDE_DISC)
        row.disc:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(y + 3))
        row.text = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.text:SetPoint("TOPLEFT", ui.col, "TOPLEFT", SIDE_DISC + 8, -y)
        row.text:SetJustifyH("LEFT")
        row.text:SetWidth(COL - SIDE_DISC - 8)
        ui.men[k] = row
    end
    rule(230)
    ui.logCap = ns.MakeCap(ui.col, 0, 240)
    ui.logPly = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.logPly:SetJustifyH("RIGHT")
    ui.logPly:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -240)
    ui.logPly:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
    ui.logRow = {}
    for k = 1, LOG_VIS do
        local y = LOG_TOP + (k - 1) * LOG_ROW
        local r = {}
        r.lit = ns.Fill(ui.col, "BACKGROUND", 0.16, 0.14, 0.09)
        r.lit:SetHeight(LOG_ROW)
        r.lit:SetPoint("TOPLEFT", ui.col, "TOPLEFT", -2, -y)
        r.lit:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 2, -y)
        r.lit:Hide()
        r.num = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.num:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y - 1)
        r.num:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
        r.w = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.w:SetPoint("TOPLEFT", ui.col, "TOPLEFT", LOG_NUM, -y - 1)
        r.w:SetJustifyH("LEFT")
        r.w:SetWidth(LOG_HALF)
        r.b = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.b:SetPoint("TOPLEFT", ui.col, "TOPLEFT", LOG_NUM + LOG_HALF, -y - 1)
        r.b:SetJustifyH("LEFT")
        r.b:SetWidth(COL - LOG_NUM - LOG_HALF)
        ui.logRow[k] = r
    end
    ui.col:EnableMouseWheel(true)
    ui.col:SetScript("OnMouseWheel", function(_, delta)
        local g = ns.Loop.Current()
        if g and g.LogScroll then g:LogScroll(-delta) end
    end)
end
local function seamAt(parent, y)
    local t = ns.Fill(parent, "ARTWORK", C_SEAM)
    t:SetHeight(1)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", M_PAD, -y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -M_PAD, -y)
    return t
end
local function buildMenu(canvas)
    menu = {}
    menu.root = ns.PlainFrame(canvas, 6)
    menu.root:SetAllPoints(canvas)
    menu.root:Hide()
    menu.cap = ns.MakeCap(menu.root, M_PAD, CAP_TOP)
    menu.tile = {}
    for i = 1, #FOES do
        local t = ns.MakeSlot(menu.root, LOOK)
        t:SetFrameLevel(menu.root:GetFrameLevel() + 1)
        t:SetWidth(TILE_W)
        t:SetHeight(TILE_H)
        t:SetPoint("TOPLEFT", menu.root, "TOPLEFT",
                   M_PAD + (i - 1) * (TILE_W + TILE_GAP), -TILE_TOP)
        t.title = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t.title:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -11)
        t.desc = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.desc:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -34)
        t.desc:SetWidth(TILE_W - 24)
        t.desc:SetJustifyH("LEFT")
        t.desc:SetJustifyV("TOP")
        t.foot = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.foot:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 12, 9)
        t.dot = t:CreateTexture(nil, "OVERLAY")
        t.dot:SetTexture(DISC)
        t.dot:SetWidth(7)
        t.dot:SetHeight(7)
        t.dot:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -47)
        t.dot:Hide()
        t.who = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t.who:SetPoint("TOPLEFT", t, "TOPLEFT", 26, -40)
        t.who:SetWidth(TILE_W - 38)
        t.who:SetJustifyH("LEFT")
        t.who:Hide()
        t:SetScript("OnClick", function()
            local g = ns.Loop.Current()
            if g and g.PickFoe then ns.Sfx.Ui(); g:PickFoe(FOES[i].key) end
        end)
        menu.tile[i] = t
    end
    menu.paint = function()
        for i = 1, #menu.tile do
            local t = menu.tile[i]
            local on = (FOES[i].key == menu.foeKey)
            t:Tone(on)
            local c = on and C_GOLD or C_TEXT
            t.title:SetTextColor(c[1], c[2], c[3])
            c = on and C_SOFT or C_DIM
            t.desc:SetTextColor(c[1], c[2], c[3])
            t.foot:SetTextColor(c[1], c[2], c[3])
        end
    end
    seamAt(menu.root, SEAM1)
    seamAt(menu.root, SEAM2)
    menu.boardCap = ns.MakeCap(menu.root, M_PAD, BAND_CAP)
    local side = PREV_CELL * N
    menu.prev = ns.PlainFrame(menu.root, 1)
    menu.prev:SetWidth(side + PAD * 2)
    menu.prev:SetHeight(side + PAD * 2)
    menu.prev:SetPoint("TOPLEFT", menu.root, "TOPLEFT", M_PAD, -BAND_TOP)
    menu.prev:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    menu.prev:SetBackdropColor(C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
    menu.prev:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], C_FRAME[4])
    menu.prevDeck = ns.PlainFrame(menu.prev, 1)
    menu.prevDeck:SetPoint("TOPLEFT", menu.prev, "TOPLEFT", PAD, -PAD)
    menu.prevDeck:SetWidth(side)
    menu.prevDeck:SetHeight(side)
    menu.prevSq = {}
    for i = 1, CELLS do
        local c, r = cr(i)
        local col = dark(c, r) and C_DARK or C_LIGHT
        local t = ns.Fill(menu.prevDeck, "BACKGROUND", col)
        t:SetWidth(PREV_CELL)
        t:SetHeight(PREV_CELL)
        t:SetPoint("BOTTOMLEFT", menu.prevDeck, "BOTTOMLEFT",
                   (c - 1) * PREV_CELL, (r - 1) * PREV_CELL)
        menu.prevSq[i] = t
    end
    for i = 1, CELLS do
        local c, r = cr(i)
        if dark(c, r) and (r <= 3 or r >= N - 2) then
            local ins = floor(PREV_CELL * 0.10)
            local d = PREV_CELL - ins * 2
            local f = makePiece(menu.prevDeck)
            f:SetWidth(d)
            f:SetHeight(d)
            f:SetPoint("BOTTOMLEFT", menu.prevDeck, "BOTTOMLEFT",
                       (c - 1) * PREV_CELL + ins, (r - 1) * PREV_CELL + ins)
            dressPiece(f, f, d, (r <= 3) and P_WHITE or P_BLACK, false)
        end
    end
    menu.infoCap = ns.MakeCap(menu.root, INFO_X, BAND_CAP)
    menu.info = {}
    for k = 1, 3 do
        local y = INFO_TOP + (k - 1) * INFO_STEP
        local row = {}
        row.cap = ns.MakeCap(menu.root, INFO_X, y + 2)
        row.val = menu.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.val:SetPoint("TOPRIGHT", menu.root, "TOPRIGHT", -M_PAD, -y)
        row.val:SetJustifyH("RIGHT")
        menu.info[k] = row
    end
    menu.ruleCap = ns.MakeCap(menu.root, INFO_X, RULE_CAP)
    menu.rules = {}
    for k = 1, 5 do
        local fs = menu.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", menu.root, "TOPLEFT", INFO_X, -(RULE_TOP + (k - 1) * RULE_STEP))
        fs:SetWidth(640 - INFO_X - M_PAD)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
        menu.rules[k] = fs
    end
    menu.play = ns.MakeKitButton(menu.root)
    menu.play:SetWidth(PLAY_W)
    menu.play:SetHeight(PLAY_H)
    menu.play:SetPoint("TOPLEFT", menu.root, "TOPLEFT",
                       floor((640 - PLAY_W) / 2), -PLAY_TOP)
    menu.note = menu.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    menu.note:SetPoint("TOPLEFT", menu.root, "TOPLEFT", M_PAD, -NOTE_TOP)
    menu.note:SetPoint("TOPRIGHT", menu.root, "TOPRIGHT", -M_PAD, -NOTE_TOP)
    menu.note:SetJustifyH("CENTER")
end
local function ensureView(canvas)
    if field then return end
    ui = {}
    ui.deco = ns.MakeTable(canvas, LOOK)
    field = ns.PlainFrame(canvas, 1)
    field:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    field:SetBackdropColor(C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
    field:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], C_FRAME[4])
    field:Hide()
    deck = ns.PlainFrame(field, 1)
    squares = {}
    for i = 1, CELLS do
        squares[i] = deck:CreateTexture(nil, "BACKGROUND")
    end
    deck.file, deck.rank = {}, {}
    for k = 1, N do
        deck.file[k] = deck:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        deck.rank[k] = deck:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    end
    piecePool = ns.NewPool(function() return makePiece(deck) end)
    markPool = ns.NewPool(function() return makeMark(deck) end)
    buildColumn(canvas)
    buildMenu(canvas)
    ui.panel:Hide()
end
local function hideView()
    if not field then return end
    field:Hide()
    piecePool:HideAll()
    markPool:HideAll()
    ui.deco:Hide()
    ui.panel:Hide()
    menu.root:Hide()
end
ns.Duo.OnChange(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    if game.SyncPeer then game:SyncPeer() end
    if game.SyncMenu then game:SyncMenu() end
end)
ns.Pair.OnChange(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    if game.SyncMenu then game:SyncMenu() end
end)
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    self.b, self.dead = {}, {}
    for i = 1, CELLS do
        self.b[i] = EMPTY
        self.dead[i] = false
        local c, r = cr(i)
        if dark(c, r) then
            if r <= 3 then
                self.b[i] = W_MAN
            elseif r >= N - 2 then
                self.b[i] = B_MAN
            end
        end
    end
    self.side = WHITE
    self.chain, self.sel, self.over, self.legal = nil, nil, nil, nil
    self.deadN, self.idle = 0, 0
    self.tookTurn, self.promTurn, self.manTurn = false, false, false
    self.alive = START_MEN * 2
    self.nw, self.nb, self.kw, self.kb = START_MEN, START_MEN, 0, 0
    self.log, self.ply, self.logTop = {}, 0, nil
    self.t, self.moveAt = 0, 0
    self.foe = (self.opts and self.opts.foe) or DEF_FOE
    local restored = moves and #moves > 0
    if restored then
        for k = 1, #moves do apply(self, moves[k]) end
    end
    self.sel = self.chain
    if not ns.Duo.Active() then ns.Duo.Adopt(ID) end
    local dropped
    if not restored and ns.Duo.Held() then
        dropped = ns.Duo.Peer()
        ns.Duo.GoSolo()
    end
    local duo = ns.Duo.Active() or ns.Duo.Held()
    if duo then self.foe = "duo" end
    self.mySide = ns.Duo.Side() or WHITE
    self.flip = (ns.Duo.Side() == BLACK)
    self.bot = (not duo and self.foe ~= "duo") and BLACK or nil
    self.job, self.think = nil, 0
    self.menu = not restored and not duo
    self:Build()
    self:Draw()
    self:SyncPeer()
    if ns.Duo.Active() and not restored then ns.Sfx.Play("start") end
    if dropped then
        ns.Curtain.Ask(self.canvas, ns.T("checkers.label"),
            { ns.T("checkers.heldGone", dropped) },
            { { label = ns.T("checkers.heldGoneOk"),
                onClick = function() ns.Curtain.Hide() end } })
    end
end
function Game:Playable()
    if self.menu or self.over then return false end
    if ns.Duo.Held() then return false end
    if ns.Duo.Active() and not ns.Duo.MyTurn() then return false end
    return true
end
function Game:Move(move)
    local how = ns.Duo.Active() and ns.Duo.Gate() or "own"
    local ok, took, ended = apply(self, move)
    if not ok then return false end
    self.sel = self.chain
    self.moveAt = self.t
    self.logTop = nil
    if ended then
        ns.Sfx.Play("over")
    elseif how == "remote" and not self.chain then
        ns.Sfx.Play("turn")
    elseif took then
        ns.Sfx.Play("pop")
    end
    if self.job then
        self.job:Cancel()
        self.job = nil
    end
    self.think = 0
    self:Draw()
    return true
end
function Game:Click(x, y, button)
    if button == "RightButton" then return end
    if not self:Playable() then return end
    if self.bot and self.side == self.bot then return end
    local i = self:CellAt(x, y)
    if not i then return end
    local list = self:Legal()
    if self.sel then
        for k = 1, #list do
            local e = list[k]
            if e.f == self.sel and e.t == i then
                self:Move{ k = "mv", f = e.f, t = e.t }
                return
            end
        end
    end
    if self.chain then
        if self.b[i] == EMPTY then ns.Sfx.Play("deny") end
        return
    end
    if i == self.sel then
        self.sel = nil
        self:Draw()
        return
    end
    for k = 1, #list do
        if list[k].f == i then
            self.sel = i
            ns.Sfx.Play("pick")
            self:Draw()
            return
        end
    end
    if self.sel and self.b[i] == EMPTY then
        ns.Sfx.Play("deny")
    end
end
function Game:Update(dt)
    if not ns.Duo.Held() then self.t = self.t + dt end
    if self.menu or self.over then return end
    if not self.bot or self.side ~= self.bot then return end
    self.think = (self.think or 0) + dt
    if not self.job then
        self.job = newJob(self)
        self:SyncTurn()
    end
    local done, move = self.job:Step(SLICE_MS)
    if not done then return end
    if self.think < THINK_MIN then return end
    self.job = nil
    self.think = 0
    if move then
        self:Move{ k = "mv", f = move.f, t = move.t }
    else
        local list = self:Legal()
        if list[1] then self:Move{ k = "mv", f = list[1].f, t = list[1].t } end
    end
end
function Game:Score()
    return START_MEN * 2 - self.alive
end
function Game:Ranked()
    if self.bot then
        return ns.T("checkers.rankedBot")
    end
    return ns.T("checkers.rankedDuo")
end
function Game:Turn()
    return self.side
end
function Game:IsOver()
    return self.over ~= nil
end
function Game:Stop()
    if self.job then
        self.job:Cancel()
        self.job = nil
    end
    self.miniOn = false
    ns.CallPanel.Hide()
    ns.Curtain.Hide()
    hideView()
end
function Game:Mini(on)
    self.miniOn = on and true or false
    if not field then return end
    self:Build()
end
local PAIR_KEY = {
    live = "checkers.pairLive", duo = "checkers.pairInGame",
    combat = "checkers.pairCombat", away = "checkers.pairAway",
    gone = "checkers.pairOffline",
}
local GIST_KEY = {
    "checkers.menuGist1", "checkers.menuGist2", "checkers.menuGist3",
    "checkers.menuGist4", "checkers.menuGist5",
}
function Game:PickFoe(key)
    if not self.menu or key == self.foe then return end
    if ns.Duo.Waiting() or ns.Duo.Active() then return end
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, { foe = key })
end
function Game:BeginRound()
    if not self.menu then return end
    if self.foe == "duo" then return end
    self.menu = false
    self.moveAt = self.t
    self:Draw()
end
function Game:SyncNote()
    if not menu then return end
    local said = ns.Duo.Status() or ns.Pair.Status()
    if said then
        menu.note:SetText(said)
        menu.note:SetTextColor(C_LIVE[1], C_LIVE[2], C_LIVE[3])
        return
    end
    if self.foe == "duo" and not ns.Pair.Bound() then
        menu.note:SetText(ns.T("checkers.menuHint"))
        menu.note:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
        return
    end
    menu.note:SetText("")
end
function Game:SyncMenu()
    if not menu or not menu.root:IsShown() then return end
    local me = self
    local waiting = ns.Duo.Waiting()
    local mate = ns.Pair.Bound() and ns.Pair.Mate() or nil
    menu.cap:SetText(ns.T("checkers.menuFoeCap"))
    menu.boardCap:SetText(ns.T("checkers.menuBoardCap"))
    menu.infoCap:SetText(ns.T("checkers.menuPartCap"))
    menu.ruleCap:SetText(ns.T("checkers.menuGistCap"))
    menu.foeKey = self.foe
    for i = 1, #FOES do
        local t = menu.tile[i]
        t.title:SetText(ns.T(FOES[i].name))
        t:SetAlpha(waiting and A_LOCK or 1)
        t:EnableMouse(not waiting)
        if FOES[i].key == "duo" then
            t.foot:SetText(mate and ns.T("checkers.tagPair") or ns.T("checkers.tagCall"))
        else
            t.foot:SetText(ns.T("checkers.tagBot"))
            t.desc:SetText(ns.T(FOES[i].desc))
        end
    end
    local slot = menu.tile[#FOES]
    slot.desc:ClearAllPoints()
    if mate then
        local where = ns.Pair.Where() or "gone"
        local col = (where == "live" or where == "duo") and C_LIVE
            or (where == "gone") and C_GONE or C_WARN
        slot.dot:SetVertexColor(col[1], col[2], col[3])
        slot.dot:Show()
        slot.who:SetText(mate)
        slot.who:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
        slot.who:Show()
        slot.desc:SetPoint("TOPLEFT", slot, "TOPLEFT", 12, -62)
        slot.desc:SetText(ns.T(PAIR_KEY[where] or PAIR_KEY.gone))
    else
        slot.dot:Hide()
        slot.who:Hide()
        slot.desc:SetPoint("TOPLEFT", slot, "TOPLEFT", 12, -34)
        slot.desc:SetText(ns.T("checkers.foeDuoDesc"))
    end
    menu.paint()
    local duoPick = (self.foe == "duo")
    menu.info[1].cap:SetText(ns.T("checkers.menuRowFoe"))
    if duoPick then
        menu.info[1].val:SetText(mate or ns.T("checkers.menuNobody"))
    else
        menu.info[1].val:SetText(ns.T(foeBy(self.foe).label))
    end
    local c = (duoPick and not mate) and C_SOFT or C_TEXT
    menu.info[1].val:SetTextColor(c[1], c[2], c[3])
    menu.info[2].cap:SetText(ns.T("checkers.menuRowColor"))
    menu.info[2].val:SetText(duoPick and ns.T("checkers.menuColorDuo")
                                     or ns.T("checkers.menuColorBot"))
    menu.info[2].val:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    menu.info[3].cap:SetText(ns.T("checkers.menuRowRec"))
    menu.info[3].val:SetText(ns.T("checkers.menuNoRec"))
    menu.info[3].val:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    for k = 1, #GIST_KEY do
        menu.rules[k]:SetText(ns.T(GIST_KEY[k]))
    end
    if waiting then
        menu.play.text:SetText(ns.T("duoCancel"))
        menu.play.tip = ns.T("duoCancelTip")
        menu.play.onClick = function() ns.Duo.Cancel() end
    elseif duoPick and mate then
        menu.play.text:SetText(ns.T("checkers.menuPlayMate", mate))
        menu.play.tip = ns.T("checkers.menuPlayMateTip")
        menu.play.onClick = function() ns.Pair.Play(ID, me.opts) end
    elseif duoPick then
        menu.play.text:SetText(ns.T("checkers.menuCall"))
        menu.play.tip = ns.T("checkers.menuCallTip")
        menu.play.onClick = function()
            ns.CallPanel.Show(ns.window:Frame(), {
                pair = true, title = ns.T("checkers.menuCall"), autoHide = true,
            })
        end
    else
        menu.play.text:SetText(ns.T("checkers.menuPlay"))
        menu.play.tip = ns.T("checkers.menuPlayTip")
        menu.play.onClick = function() me:BeginRound() end
    end
    menu.play:Enable()
    self:SyncNote()
end
local STATE_KEY = {
    live = "checkers.peerLive", combat = "checkers.peerCombat",
    away = "checkers.peerAway", quiet = "checkers.peerQuiet",
}
function Game:SyncPeer()
    if not ui then return end
    ui.foeCap:SetText(ns.T("checkers.colFoeCap"))
    local peer = ns.Duo.Peer()
    if ns.Duo.Held() and peer then
        ui.foeDisc:SetVertexColor(C_GONE[1], C_GONE[2], C_GONE[3])
        ui.foeDisc:Show()
        ui.foeName:SetText(peer)
        ui.foeName:SetTextColor(C_GONE[1], C_GONE[2], C_GONE[3])
        local at = ns.Duo.HeldAt()
        ui.foeDot:SetVertexColor(C_GONE[1], C_GONE[2], C_GONE[3])
        ui.foeDot:Show()
        ui.foeState:SetText(ns.T("checkers.peerHeld", at and floor((time() - at) / 60) or 0))
        ui.foeState:SetTextColor(C_GONE[1], C_GONE[2], C_GONE[3])
        return
    end
    if ns.Duo.Active() and peer then
        local his = (self.mySide == WHITE) and P_BLACK.ring or P_WHITE.face
        ui.foeDisc:SetVertexColor(his[1], his[2], his[3])
        ui.foeDisc:Show()
        ui.foeName:SetText(peer)
        ui.foeName:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
        local st = ns.Duo.PeerState() or "live"
        local col = (st == "live") and C_LIVE or C_SOFT
        ui.foeDot:SetVertexColor(col[1], col[2], col[3])
        ui.foeDot:Show()
        ui.foeState:SetText(ns.T(STATE_KEY[st] or STATE_KEY.live))
        ui.foeState:SetTextColor(col[1], col[2], col[3])
        return
    end
    if self.bot then
        ui.foeDisc:SetVertexColor(P_BLACK.ring[1], P_BLACK.ring[2], P_BLACK.ring[3])
        ui.foeDisc:Show()
        ui.foeName:SetText(ns.T(foeBy(self.foe).label))
        ui.foeName:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
        local thinks = (self.side == self.bot) and not self.over
        local col = thinks and C_WARN or C_LIVE
        ui.foeDot:SetVertexColor(col[1], col[2], col[3])
        ui.foeDot:Show()
        ui.foeState:SetText(thinks and ns.T("checkers.botThinks") or ns.T("checkers.botWaits"))
        ui.foeState:SetTextColor(col[1], col[2], col[3])
        return
    end
    ui.foeDisc:Hide()
    ui.foeDot:Hide()
    ui.foeName:SetText(ns.T("checkers.colNobody"))
    ui.foeName:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.foeState:SetText("")
end
function Game:SyncTurn()
    if not ui then return end
    if self.over then
        if self.over == "draw" then
            ui.turnDisc:Hide()
            ui.turn:SetText(ns.T("checkers.headDraw"))
            ui.turn:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
            return
        end
        local white = (self.over == "white")
        local col = white and P_WHITE.face or P_BLACK.ring
        ui.turnDisc:SetVertexColor(col[1], col[2], col[3])
        ui.turnDisc:Show()
        ui.turn:SetText(white and ns.T("checkers.headWhiteWon")
                              or ns.T("checkers.headBlackWon"))
        ui.turn:SetTextColor(C_LIVE[1], C_LIVE[2], C_LIVE[3])
        return
    end
    local col = (self.side == WHITE) and P_WHITE.face or P_BLACK.ring
    ui.turnDisc:SetVertexColor(col[1], col[2], col[3])
    ui.turnDisc:Show()
    if ns.Duo.Held() then
        ui.turn:SetText(ns.T("checkers.turnWait"))
        ui.turn:SetTextColor(C_GONE[1], C_GONE[2], C_GONE[3])
        return
    end
    local text
    if self.bot then
        text = (self.side == self.bot) and ns.T("checkers.turnBot")
                                       or ns.T("checkers.turnMine")
    elseif ns.Duo.Active() then
        text = (self.side == self.mySide) and ns.T("checkers.turnMine")
            or ns.T("checkers.turnPeer", ns.Duo.Peer() or "")
    else
        text = (self.side == WHITE) and ns.T("checkers.headWhiteTurn")
                                    or ns.T("checkers.headBlackTurn")
    end
    ui.turn:SetText(text)
    ui.turn:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
end
function Game:MiniReady()
    return not self.menu
end
function Game:MiniNote()
    if self.chain then return ns.T("checkers.miniChain") end
    if self.over then
        if self.over == "draw" then return ns.T("checkers.headDraw") end
        return (self.over == "white") and ns.T("checkers.headWhiteWon")
                                       or ns.T("checkers.headBlackWon")
    end
    if ns.Duo.Held() then return ns.T("checkers.turnWait") end
    if self.bot then
        return (self.side == self.bot) and ns.T("checkers.turnBot")
                                        or ns.T("checkers.turnMine")
    end
    if ns.Duo.Active() then
        return (self.side == self.mySide) and ns.T("checkers.turnMine")
            or ns.T("checkers.turnPeer", ns.Duo.Peer() or "")
    end
    return (self.side == WHITE) and ns.T("checkers.headWhiteTurn")
                                  or ns.T("checkers.headBlackTurn")
end
function Game:SyncCount()
    if not ui then return end
    ui.cntCap:SetText(ns.T("checkers.cntCap"))
    ui.cntVal:SetText(self.nw .. " : " .. self.nb)
    local rows = {
        { col = P_WHITE.face, men = self.nw, kings = self.kw },
        { col = P_BLACK.ring, men = self.nb, kings = self.kb },
    }
    for k = 1, 2 do
        local row, src = ui.men[k], rows[k]
        row.disc:SetVertexColor(src.col[1], src.col[2], src.col[3])
        row.disc:Show()
        if src.kings > 0 then
            row.text:SetText(ns.T("checkers.cntKings", src.men, src.kings))
        else
            row.text:SetText(ns.T("checkers.cntNoKings", src.men))
        end
        row.text:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    end
end
function Game:LogScroll(delta)
    local full = floor((self.ply + 1) / 2)
    if full <= LOG_VIS then return end
    local top = self.logTop or (full - LOG_VIS + 1)
    top = top + delta
    if top < 1 then top = 1 end
    if top > full - LOG_VIS + 1 then top = full - LOG_VIS + 1 end
    self.logTop = top
    self:SyncLog()
end
function Game:SyncLog()
    if not ui then return end
    local full = floor((self.ply + 1) / 2)
    local top = self.logTop
    if not top or top > full - LOG_VIS + 1 then
        top = full - LOG_VIS + 1
        if top < 1 then top = 1 end
    end
    ui.logCap:SetText(ns.T("checkers.logCap"))
    ui.logPly:SetText(ns.T("checkers.logPly", self.ply))
    for k = 1, LOG_VIS do
        local no = top + k - 1
        local r = ui.logRow[k]
        if no <= full and no >= 1 then
            r.num:SetText(no .. ".")
            r.w:SetText(self.log[no * 2 - 1] or "")
            r.b:SetText(self.log[no * 2] or "")
            local last = (no * 2 == self.ply) or (no * 2 - 1 == self.ply)
            local col = last and C_GOLD or C_TEXT
            if last then r.lit:Show() else r.lit:Hide() end
            r.w:SetTextColor(col[1], col[2], col[3])
            r.b:SetTextColor(col[1], col[2], col[3])
        else
            r.num:SetText("")
            r.w:SetText("")
            r.b:SetText("")
            r.lit:Hide()
        end
    end
end
function Game:PanelSync()
    if not ui then return end
    if self.menu then
        self:SyncNote()
        return
    end
    if not ui.panel:IsShown() then return end
    ui.gameCap:SetText(ns.T("checkers.clockGame"))
    ui.gameVal:SetText(ns.Records.Span(ns.window:Elapsed()))
    local paused, why = ns.Loop.IsPaused()
    if ns.Duo.Held() then
        ui.moveCap:SetText(ns.T("checkers.clockHeld"))
        ui.moveVal:SetText("")
    elseif paused then
        ui.moveCap:SetText(ns.T("checkers.clockPause"))
        ui.moveVal:SetText(why or "")
    else
        ui.moveCap:SetText(ns.T("checkers.clockMove"))
        ui.moveVal:SetText(ns.Records.Span(self.t - (self.moveAt or 0)))
    end
    if ns.Duo.Active() then
        local st = ns.Duo.PeerState() or "live"
        if st ~= self.peerShown then
            self.peerShown = st
            self:SyncPeer()
        end
    else
        self.peerShown = nil
    end
    if self.bot then
        local thinks = (self.side == self.bot) and not self.over
        if thinks ~= self.botShown then
            self.botShown = thinks
            self:SyncPeer()
        end
    end
end
function Game:CellXY(i)
    local c, r = cr(i)
    if self.flip then c, r = N + 1 - c, N + 1 - r end
    return (c - 1) * self.cell, (r - 1) * self.cell
end
function Game:CellAt(x, y)
    if not self.cell then return nil end
    local c = floor((x - self.ox) / self.cell) + 1
    local r = floor((y - self.oy) / self.cell) + 1
    if self.flip then c, r = N + 1 - c, N + 1 - r end
    if not onBoard(c, r) then return nil end
    if not dark(c, r) then return nil end
    return idx(c, r)
end
function Game:Screen()
    ui.deco:Show()
    if self.menu then
        field:Hide()
        ui.panel:Hide()
        piecePool:HideAll()
        markPool:HideAll()
        menu.root:Show()
    else
        menu.root:Hide()
        field:Show()
        if self.miniOn then ui.panel:Hide() else ui.panel:Show() end
    end
end
function Game:Build()
    local canvas = self.canvas
    ensureView(canvas)
    self.cell = ns.CellFit(N, BOARD_MAX, 0, 0)
    local side = self.cell * N
    local slack = floor((BOARD_MAX - side) / 2)
    if self.miniOn then
        self.ox = MINI_MARGIN + PAD + slack
        self.oy = MINI_MARGIN + PAD + slack
    else
        self.ox = MARGIN + PAD + slack
        self.oy = TOPGAP + PAD + slack
    end
    field:ClearAllPoints()
    field:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.ox - PAD, self.oy - PAD)
    field:SetWidth(side + PAD * 2)
    field:SetHeight(side + PAD * 2)
    deck:ClearAllPoints()
    deck:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", PAD, PAD)
    deck:SetWidth(side)
    deck:SetHeight(side)
    for i = 1, CELLS do
        local t = squares[i]
        local c, r = cr(i)
        local col = dark(c, r) and C_DARK or C_LIGHT
        local x, y = self:CellXY(i)
        t:ClearAllPoints()
        t:SetWidth(self.cell)
        t:SetHeight(self.cell)
        t:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", x, y)
        ns.Paint(t, col[1], col[2], col[3], col[4])
        t:Show()
    end
    for k = 1, N do
        local lf = deck.file[k]
        lf:ClearAllPoints()
        lf:SetPoint("BOTTOMRIGHT", deck, "BOTTOMLEFT", k * self.cell - 3, 2)
        lf:SetText(FILES[self.flip and (N + 1 - k) or k])
        local pale = ((k + 1) % 2 == 0) and C_LIGHT or C_DARK
        lf:SetTextColor(pale[1], pale[2], pale[3])
        local lr = deck.rank[k]
        lr:ClearAllPoints()
        lr:SetPoint("TOPLEFT", deck, "BOTTOMLEFT", 3, k * self.cell - 2)
        lr:SetText(self.flip and (N + 1 - k) or k)
        pale = ((1 + k) % 2 == 0) and C_LIGHT or C_DARK
        lr:SetTextColor(pale[1], pale[2], pale[3])
    end
    self:Screen()
end
function Game:Mark(i, alpha)
    local f = markPool:Acquire()
    local x, y = self:CellXY(i)
    f:ClearAllPoints()
    f:SetWidth(self.cell)
    f:SetHeight(self.cell)
    f:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", x, y)
    f.tex:SetAlpha(alpha)
end
function Game:Draw()
    if not field or not self.cell then return end
    self:Screen()
    if self.menu then
        self:SyncMenu()
        return
    end
    piecePool:Reset()
    markPool:Reset()
    local inset = floor(self.cell * 0.10)
    local d = self.cell - inset * 2
    local nw, nb, kw, kb = 0, 0, 0, 0
    for i = 1, CELLS do
        local p = self.b[i]
        if p ~= EMPTY then
            local white = sideOf(p) == WHITE
            if not self.dead[i] then
                if white then
                    nw = nw + 1
                    if isKing(p) then kw = kw + 1 end
                else
                    nb = nb + 1
                    if isKing(p) then kb = kb + 1 end
                end
            end
            local f = piecePool:Acquire()
            local x, y = self:CellXY(i)
            f:ClearAllPoints()
            f:SetWidth(d)
            f:SetHeight(d)
            f:SetPoint("BOTTOMLEFT", deck, "BOTTOMLEFT", x + inset, y + inset)
            f:SetAlpha(self.dead[i] and A_DEAD or 1)
            dressPiece(f, f, d, white and P_WHITE or P_BLACK, isKing(p))
        end
    end
    local list = self:Legal()
    if not self.over then
        if self.sel then
            self:Mark(self.sel, A_SEL)
            for k = 1, #list do
                if list[k].f == self.sel then self:Mark(list[k].t, A_GOAL) end
            end
        elseif list[1] and list[1].cap then
            local seen = {}
            for k = 1, #list do
                local from = list[k].f
                if not seen[from] then
                    seen[from] = true
                    self:Mark(from, A_MUST)
                end
            end
        end
    end
    piecePool:HideExtras()
    markPool:HideExtras()
    self.nw, self.nb, self.kw, self.kb = nw, nb, kw, kb
    self:SyncCount()
    self:SyncTurn()
    self:SyncLog()
end
local function CheckersTileIcon(host, size)
    dressPiece({
        shade = ns.ArtFill(host, 1, "BACKGROUND"),
        edge  = ns.ArtFill(host, 2, "BORDER"),
        face  = ns.ArtFill(host, 3, "ARTWORK"),
        gloss = ns.ArtFill(host, 4, "OVERLAY"),
    }, host, size - 4, P_WHITE, false)
end
local HELP_CELL = 24
local HELP_H = 126
local HELP_DOT = 0.30
local A_HELP_RING = 0.75
local HELP_ART = {
    {
        n = 5,
        men = {
            { c = 3, r = 3, side = "w" },
        },
        dots = { { c = 2, r = 4 }, { c = 4, r = 4 } },
    },
    {
        n = 5,
        men = {
            { c = 4, r = 4, side = "w" },
            { c = 3, r = 3, side = "b" },
        },
        ring = { { c = 4, r = 4 } },
        dots = { { c = 2, r = 2 } },
    },
    {
        n = 5,
        men = {
            { c = 3, r = 3, side = "w" },
            { c = 2, r = 2, side = "b", dead = true },
            { c = 4, r = 2, side = "b" },
        },
        dots = { { c = 5, r = 1 } },
    },
    {
        n = 5,
        men = {
            { c = 1, r = 1, side = "w", king = true },
            { c = 3, r = 3, side = "b" },
        },
        dots = { { c = 4, r = 4 }, { c = 5, r = 5 } },
    },
}
local function helpCell(board, at)
    local f = ns.PlainFrame(board, 3)
    f:SetWidth(HELP_CELL)
    f:SetHeight(HELP_CELL)
    f:SetPoint("BOTTOMLEFT", board, "BOTTOMLEFT",
               (at.c - 1) * HELP_CELL, (at.r - 1) * HELP_CELL)
    return f
end
local function helpRing(board, at)
    local t = helpCell(board, at):CreateTexture(nil, "OVERLAY")
    t:SetTexture(ns.CELL_HL)
    t:SetBlendMode("ADD")
    t:SetAllPoints(t:GetParent())
    t:SetAlpha(A_HELP_RING)
end
local function helpDot(board, at)
    local f = helpCell(board, at)
    local d = floor(HELP_CELL * HELP_DOT)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetTexture(DISC)
    t:SetWidth(d)
    t:SetHeight(d)
    t:SetPoint("CENTER", f, "CENTER", 0, 0)
    t:SetVertexColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
end
local function helpBoard(host, spec)
    local n = spec.n
    local board = ns.PlainFrame(host, 1)
    board:SetWidth(n * HELP_CELL)
    board:SetHeight(n * HELP_CELL)
    board:SetPoint("CENTER", host, "CENTER", 0, 0)
    for r = 1, n do
        for c = 1, n do
            local col = dark(c, r) and C_DARK or C_LIGHT
            local t = ns.Fill(board, "BACKGROUND", col)
            t:SetWidth(HELP_CELL)
            t:SetHeight(HELP_CELL)
            t:SetPoint("BOTTOMLEFT", board, "BOTTOMLEFT",
                       (c - 1) * HELP_CELL, (r - 1) * HELP_CELL)
        end
    end
    for _, at in ipairs(spec.ring or {}) do helpRing(board, at) end
    for _, at in ipairs(spec.dots or {}) do helpDot(board, at) end
    local ins = floor(HELP_CELL * 0.10)
    local d = HELP_CELL - ins * 2
    for _, m in ipairs(spec.men) do
        local f = makePiece(board)
        f:SetWidth(d)
        f:SetHeight(d)
        f:SetPoint("BOTTOMLEFT", board, "BOTTOMLEFT",
                   (m.c - 1) * HELP_CELL + ins, (m.r - 1) * HELP_CELL + ins)
        f:SetAlpha(m.dead and A_DEAD or 1)
        dressPiece(f, f, d, (m.side == "w") and P_WHITE or P_BLACK, m.king)
    end
end
local function helpStep(host) helpBoard(host, HELP_ART[1]) end
local function helpBack(host) helpBoard(host, HELP_ART[2]) end
local function helpChain(host) helpBoard(host, HELP_ART[3]) end
local function helpKing(host) helpBoard(host, HELP_ART[4]) end
ns.OnLocale(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    game.peerShown, game.botShown = nil, nil
    game:Draw()
    game:SyncPeer()
end)
ns.RegisterGame{
    id = ID,
    label = "checkers.label",
    icon = { draw = CheckersTileIcon },
    tip = "checkers.tip",
    order = 10,
    duo = "turns",
    physics = false,
    ownPanel = true,
    look = LOOK,
    mini = { w = MINI_W, h = MINI_H },
    opts = {
        { key = "foe", label = "checkers.optFoeLabel", def = DEF_FOE, options = FOES,
          tip = "checkers.optFoeTip" },
    },
    record = false,
    finale = true,
    done = true,
    New = New,
    controls = {
        { action = "pick", label = "checkers.ctlPick", mouse = "LMB", where = "checkers.ctlOnPiece" },
        { action = "move", label = "checkers.ctlMove", mouse = "LMB", where = "checkers.ctlOnCell" },
        { action = "unpick", label = "checkers.ctlUnpick", mouse = "LMB", where = "checkers.ctlOnSelected" },
        { action = "resel", label = "checkers.ctlResel", mouse = "LMB", where = "checkers.ctlOnOther" },
    },
    help = {
        "checkers.help1",
        { t = "checkers.help2",
          sub = "checkers.help2Sub" },
        { t = "checkers.help3",
          sub = "checkers.help3Sub" },
        { t = "checkers.help4" },
        "checkers.help5",
        { art = helpStep, h = HELP_H },
        "checkers.help6",
        { art = helpBack, h = HELP_H },
        "checkers.helpBackSub",
        "checkers.help7",
        { art = helpChain, h = HELP_H },
        "checkers.help8",
        { art = helpKing, h = HELP_H },
        "checkers.helpKingSub",
        "checkers.help9",
    },
}
