local ADDON, ns = ...
local ID = "chess"
local floor = math.floor
local CP = ns.ChessPieces
local KING, QUEEN, ROOK, BISHOP, KNIGHT, PAWN = 1, 2, 3, 4, 5, 6
local LETTER = { "chess.letterKing", "chess.letterQueen", "chess.letterRook",
                 "chess.letterBishop", "chess.letterKnight", "chess.letterPawn" }
local PROMO_LIST = { QUEEN, ROOK, BISHOP, KNIGHT }
local BACK = { ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK }
local FILES = { "a", "b", "c", "d", "e", "f", "g", "h" }
local VALUE = { 0, 9, 5, 3, 3, 1 }
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local BACK_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local GLOW_TEX = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local SCREEN_TEX = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local C_LIGHT = { 0.78, 0.71, 0.56 }
local C_DARK  = { 0.40, 0.31, 0.24 }
local C_FRAME = { 0.58, 0.47, 0.28 }
local C_GROUT = { 0.05, 0.04, 0.04, 0.95 }
local SIDE_COL = CP.SIDE
local C_SEL   = { 1.00, 0.82, 0.00, 0.42 }
local C_LAST  = { 0.40, 0.70, 1.00, 0.26 }
local C_CHECK = { 0.85, 0.12, 0.10, 0.55 }
local C_TAKE  = { 0.90, 0.25, 0.20, 0.45 }
local C_BAN   = { 0.90, 0.28, 0.24, 0.24 }
local C_DOT   = { 0.35, 0.90, 0.40 }
local C_TABLE = { 0.230, 0.190, 0.130 }
local C_NICHE = { 0.075, 0.062, 0.045, 1 }
local C_EDGE  = { 0.29, 0.24, 0.14, 1 }
local C_RULE  = { 0.21, 0.18, 0.14, 1 }
local C_CAP   = { 0.54, 0.51, 0.45 }
local C_TEXT  = { 0.91, 0.90, 0.86 }
local C_SOFT  = { 0.65, 0.61, 0.53 }
local C_GOLD  = { 1.00, 0.82, 0.00 }
local C_LIVE  = { 0.44, 0.75, 0.36 }
local C_GONE  = { 0.48, 0.45, 0.39 }
local C_WIN   = { 0.40, 0.90, 0.40 }
local C_CHECK_TXT = { 0.92, 0.34, 0.30 }
local LOOK = ns.MakeLook{ wood = C_TABLE, edge = C_GOLD, screen = C_TABLE }
local MARGIN = 14
local TOPGAP = 26
local PAD = 6
local BOARD_MAX = 416
local ZONE = BOARD_MAX + PAD * 2
local miniOn = false
local GY = TOPGAP
local COL_W = 170
local PANEL_PAD = 12
local COL = COL_W - PANEL_PAD * 2
local ROW = 22
local CLOCK_TOP = 107
local LOG_ROW = 15
local LOG_VIS = 8
local LOG_NUM = 22
local LOG_HALF = 62
local TAKEN_SIL = 20
local TAKEN_STEP = 17
local TAKEN_COLS = 8
local TURN_DISC = 26
local END_FLASH = 0.6
local MAX_DOTS = 32
local notate
local function cell(c, r)
    return (r - 1) * 8 + c
end
local function colOf(i)
    return (i - 1) % 8 + 1
end
local function rowOf(i)
    return floor((i - 1) / 8) + 1
end
local function turnIdx(flip, i)
    if not flip then return i end
    return cell(9 - colOf(i), 9 - rowOf(i))
end
local PAWN_DC = { -1, 1 }
local DIR_R = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local DIR_B = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local DIR_Q = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
                { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local KN = { { 1, 2 }, { 2, 1 }, { 2, -1 }, { 1, -2 },
             { -1, -2 }, { -2, -1 }, { -2, 1 }, { -1, 2 } }
local function attacked(self, i, by)
    local p, s = self.p, self.s
    local c, r = colOf(i), rowOf(i)
    local pr = r + ((by == 1) and -1 or 1)
    if pr >= 1 and pr <= 8 then
        for k = 1, 2 do
            local pc = c + PAWN_DC[k]
            if pc >= 1 and pc <= 8 then
                local j = cell(pc, pr)
                if p[j] == PAWN and s[j] == by then return true end
            end
        end
    end
    for k = 1, 8 do
        local nc, nr = c + KN[k][1], r + KN[k][2]
        if nc >= 1 and nc <= 8 and nr >= 1 and nr <= 8 then
            local j = cell(nc, nr)
            if p[j] == KNIGHT and s[j] == by then return true end
        end
    end
    for k = 1, 8 do
        local dc, dr = DIR_Q[k][1], DIR_Q[k][2]
        local diag = (dc ~= 0 and dr ~= 0)
        local nc, nr, step = c + dc, r + dr, 1
        while nc >= 1 and nc <= 8 and nr >= 1 and nr <= 8 do
            local j = cell(nc, nr)
            local t = p[j]
            if t then
                if s[j] == by then
                    if t == QUEEN then return true end
                    if step == 1 and t == KING then return true end
                    if diag and t == BISHOP then return true end
                    if not diag and t == ROOK then return true end
                end
                break
            end
            nc, nr, step = nc + dc, nr + dr, step + 1
        end
    end
    return false
end
local function castle(self, from, me, out)
    local rights = self.cr[me]
    if not (rights.k or rights.q) then return end
    local r = (me == 1) and 1 or 8
    if from ~= cell(5, r) then return end
    local p, s = self.p, self.s
    local foe = 3 - me
    if attacked(self, from, foe) then return end
    if rights.k and not p[cell(6, r)] and not p[cell(7, r)]
        and p[cell(8, r)] == ROOK and s[cell(8, r)] == me
        and not attacked(self, cell(6, r), foe)
        and not attacked(self, cell(7, r), foe) then
        out[cell(7, r)] = true
    end
    if rights.q and not p[cell(2, r)] and not p[cell(3, r)] and not p[cell(4, r)]
        and p[cell(1, r)] == ROOK and s[cell(1, r)] == me
        and not attacked(self, cell(4, r), foe)
        and not attacked(self, cell(3, r), foe) then
        out[cell(3, r)] = true
    end
end
local function moves(self, from, out)
    local p, s = self.p, self.s
    local t = p[from]
    if not t then return out end
    local me = s[from]
    local foe = 3 - me
    local c, r = colOf(from), rowOf(from)
    local function put(nc, nr)
        if nc < 1 or nc > 8 or nr < 1 or nr > 8 then return false end
        local j = cell(nc, nr)
        if s[j] == me then return false end
        out[j] = true
        return p[j] == nil
    end
    if t == PAWN then
        local d = (me == 1) and 1 or -1
        local nr = r + d
        if nr >= 1 and nr <= 8 then
            local one = cell(c, nr)
            if not p[one] then
                out[one] = true
                local home = (me == 1) and 2 or 7
                if r == home then
                    local two = cell(c, r + d + d)
                    if not p[two] then out[two] = true end
                end
            end
            for k = 1, 2 do
                local nc = c + PAWN_DC[k]
                if nc >= 1 and nc <= 8 then
                    local j = cell(nc, nr)
                    if (p[j] and s[j] == foe) or j == self.ep then out[j] = true end
                end
            end
        end
    elseif t == KNIGHT then
        for k = 1, 8 do put(c + KN[k][1], r + KN[k][2]) end
    elseif t == KING then
        for k = 1, 8 do put(c + DIR_Q[k][1], r + DIR_Q[k][2]) end
        castle(self, from, me, out)
    else
        local dirs = DIR_Q
        if t == ROOK then dirs = DIR_R elseif t == BISHOP then dirs = DIR_B end
        for k = 1, #dirs do
            local dc, dr = dirs[k][1], dirs[k][2]
            local nc, nr = c + dc, r + dr
            while put(nc, nr) do nc, nr = nc + dc, nr + dr end
        end
    end
    return out
end
local apply
local function probe(self)
    local p, s = {}, {}
    for i = 1, 64 do p[i] = self.p[i]; s[i] = self.s[i] end
    return {
        p = p, s = s, turn = self.turn, ply = self.ply, ep = self.ep,
        cr = { { k = self.cr[1].k, q = self.cr[1].q },
               { k = self.cr[2].k, q = self.cr[2].q } },
        taken = { {}, {} }, log = {}, t = 0,
        quiet = true,
    }
end
local function kingAt(self, side)
    for i = 1, 64 do
        if self.p[i] == KING and self.s[i] == side then return i end
    end
    return nil
end
local function safeAfter(self, mv)
    local me = self.turn
    local nx = probe(self)
    if not apply(nx, mv) then return false end
    local k = kingAt(nx, me)
    if not k then return false end
    return not attacked(nx, k, 3 - me)
end
local function banned(self, from, can)
    local out, n = {}, 0
    local all = moves(self, from, {})
    for to in pairs(all) do
        if not can[to] then
            out[to] = true
            n = n + 1
        end
    end
    if n == 0 then return nil end
    return out
end
local function legal(self, from, out)
    out = out or {}
    local all = moves(self, from, {})
    for to in pairs(all) do
        if safeAfter(self, { k = "mv", from = from, to = to }) then out[to] = true end
    end
    return out
end
local function hasLegal(self, side)
    for i = 1, 64 do
        if self.s[i] == side then
            if next(legal(self, i, {})) then return true end
        end
    end
    return false
end
local function dropRookRight(self, i)
    if i == 1 then self.cr[1].q = false
    elseif i == 8 then self.cr[1].k = false
    elseif i == 57 then self.cr[2].q = false
    elseif i == 64 then self.cr[2].k = false
    end
end
apply = function(self, mv)
    if self.over then return false end
    if mv.k ~= "mv" then return false end
    local from, to = mv.from, mv.to
    if type(from) ~= "number" or type(to) ~= "number" then return false end
    if from < 1 or from > 64 or to < 1 or to > 64 then return false end
    local p, s = self.p, self.s
    local t = p[from]
    if not t or s[from] ~= self.turn then return false end
    if self.quiet then
        if not moves(self, from, {})[to] then return false end
    else
        if not legal(self, from, {})[to] then return false end
    end
    local me = self.turn
    local fc, fr = colOf(from), rowOf(from)
    local tc, tr = colOf(to), rowOf(to)
    local nHead = ((t ~= PAWN) and ns.TL(LETTER[t]) or "") .. FILES[fc] .. fr
    local nCastle = 0
    if t == KING then
        if tc - fc == 2 then nCastle = 1 elseif fc - tc == 2 then nCastle = 2 end
    end
    local eatAt = to
    if t == PAWN and to == self.ep and not p[to] then eatAt = cell(tc, fr) end
    local eat = p[eatAt]
    if eat then
        p[eatAt], s[eatAt] = nil, nil
        local list = self.taken[me]
        list[#list + 1] = eat
        dropRookRight(self, eatAt)
    end
    local put = t
    if t == PAWN and (tr == 8 or tr == 1) then
        local pr = mv.promo
        put = (pr == ROOK or pr == BISHOP or pr == KNIGHT) and pr or QUEEN
    end
    p[to], s[to] = put, me
    p[from], s[from] = nil, nil
    if t == KING and (tc - fc == 2 or fc - tc == 2) then
        local rf = (tc > fc) and cell(8, fr) or cell(1, fr)
        local rt = (tc > fc) and cell(6, fr) or cell(4, fr)
        p[rt], s[rt] = p[rf], s[rf]
        p[rf], s[rf] = nil, nil
    end
    if t == KING then
        self.cr[me].k, self.cr[me].q = false, false
    elseif t == ROOK then
        dropRookRight(self, from)
    end
    if t == PAWN and (tr - fr == 2 or fr - tr == 2) then
        self.ep = cell(fc, floor((fr + tr) / 2))
    else
        self.ep = nil
    end
    self.last = { from = from, to = to,
        eat = eat and eatAt or nil, eatKind = eat, eatSide = eat and (3 - me) or nil }
    self.turn = 3 - me
    self.ply = self.ply + 1
    if not self.quiet then
        if not hasLegal(self, self.turn) then
            local k = kingAt(self, self.turn)
            if k and attacked(self, k, me) then
                self.over = me
                self.boom = k
                self.endKind = "mate"
            else
                self.over = 0
                self.endKind = "stale"
            end
            self.overAt = self.t
        end
        self.log[self.ply] = notate(self, nHead, nCastle, tc, tr, eat ~= nil,
            (put ~= t) and put or nil)
    end
    return true
end
notate = function(self, head, castle, tc, tr, ate, put)
    local s
    if castle == 1 then
        s = "0-0"
    elseif castle == 2 then
        s = "0-0-0"
    else
        s = head .. (ate and ":" or "-") .. FILES[tc] .. tr
        if put then s = s .. ns.TL(LETTER[put]) end
    end
    if self.over == 0 then return s .. "=" end
    if self.over then return s .. "#" end
    for i = 1, 64 do
        if self.p[i] == KING and self.s[i] == self.turn
            and attacked(self, i, 3 - self.turn) then
            return s .. "+"
        end
    end
    return s
end
ns.ChessRules = {
    Moves = moves,
    Legal = legal,
    Banned = banned,
    Apply = apply,
    Attacked = attacked,
    HasLegal = hasLegal,
    Cell = cell,
    ColOf = colOf,
    RowOf = rowOf,
    KING = KING, QUEEN = QUEEN, ROOK = ROOK,
    BISHOP = BISHOP, KNIGHT = KNIGHT, PAWN = PAWN,
}
local board, marks, host, ui, pool
local function capText(parent, x, y, anchor)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint(anchor or "TOPLEFT", parent, "TOPLEFT", x, -y)
    fs:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
    return fs
end
local function ensureView(canvas)
    if board then return end
    ui = {}
    ui.deco = ns.NewFrame("Frame", nil, canvas)
    ui.deco:SetFrameLevel(canvas:GetFrameLevel())
    ui.deco:SetAllPoints(canvas)
    ui.deco:Hide()
    local scr = ns.window:ScreenFill(ui.deco)
    scr:SetTexture(SCREEN_TEX)
    scr:SetVertexColor(C_TABLE[1], C_TABLE[2], C_TABLE[3])
    board = ns.NewFrame("Frame", nil, canvas)
    board:SetFrameLevel(canvas:GetFrameLevel() + 1)
    board:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    board:SetBackdropColor(C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
    board:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], 1)
    board:Hide()
    local deck = ns.NewFrame("Frame", nil, board)
    deck:SetFrameLevel(board:GetFrameLevel() + 1)
    board.deck = deck
    board.sq, board.mark = {}, {}
    for k = 1, 64 do
        board.sq[k] = deck:CreateTexture(nil, "BACKGROUND")
        board.mark[k] = deck:CreateTexture(nil, "BORDER")
    end
    board.file, board.rank = {}, {}
    for k = 1, 8 do
        board.file[k] = deck:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        board.rank[k] = deck:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    end
    marks = ns.NewFrame("Frame", nil, canvas)
    marks:SetFrameLevel(board:GetFrameLevel() + 2)
    marks:SetAllPoints(canvas)
    marks.dot = {}
    for k = 1, MAX_DOTS do
        local t = marks:CreateTexture(nil, "ARTWORK")
        t:Hide()
        marks.dot[k] = t
    end
    host = ns.NewFrame("Frame", nil, canvas)
    host:SetFrameLevel(board:GetFrameLevel() + 3)
    host:SetAllPoints(canvas)
    pool = ns.NewPool(function() return CP.Make(host) end)
    ui.dust = CP.MakeDust(host)
    ui.dust:SetFrameLevel(host:GetFrameLevel() + 2)
    ui.panel = ns.NewFrame("Frame", nil, canvas)
    ui.panel:SetFrameLevel(canvas:GetFrameLevel() + 2)
    ui.panel:SetWidth(COL_W)
    ui.panel:SetHeight(ZONE)
    ui.panel:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -MARGIN, TOPGAP)
    ui.plate = ui.panel:CreateTexture(nil, "BACKGROUND")
    ui.plate:SetAllPoints(ui.panel)
    ns.Paint(ui.plate, C_NICHE[1], C_NICHE[2], C_NICHE[3], C_NICHE[4])
    local function edge(p1, p2, w, h)
        local t = ui.panel:CreateTexture(nil, "BORDER")
        ns.Paint(t, C_EDGE[1], C_EDGE[2], C_EDGE[3], C_EDGE[4])
        t:SetPoint(p1, ui.panel, p1, 0, 0)
        t:SetPoint(p2, ui.panel, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    edge("TOPLEFT", "TOPRIGHT", nil, 1)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
    ui.col = ns.NewFrame("Frame", nil, ui.panel)
    ui.col:SetFrameLevel(ui.panel:GetFrameLevel() + 1)
    ui.col:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", PANEL_PAD, -PANEL_PAD)
    ui.col:SetPoint("BOTTOMRIGHT", ui.panel, "BOTTOMRIGHT", -PANEL_PAD, PANEL_PAD)
    local function rule(y)
        local t = ui.col:CreateTexture(nil, "ARTWORK")
        ns.Paint(t, C_RULE[1], C_RULE[2], C_RULE[3], C_RULE[4])
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y)
        return t
    end
    ui.peerCap = capText(ui.col, 0, 0)
    ui.peerCap:SetText(ns.T("chess.peerCap"))
    ui.back = ns.MakeKitButton(ui.col)
    ui.back:SetWidth(74)
    ui.back:SetHeight(16)
    ui.back:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, 2)
    ui.back.text:SetText(ns.T("chess.toLobby"))
    ui.back.tip = ns.T("chess.toLobbyTip")
    ui.back.onClick = function()
        local g = ns.Loop.Current()
        if g and g.ToLobby then g:ToLobby() end
    end
    ui.peerDisc = CP.Make(ui.col)
    ui.peerDisc:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -15)
    ui.peerName = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.peerName:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 24, -16)
    ui.peerName:SetJustifyH("LEFT")
    ui.peerName:SetWidth(COL - 24)
    ui.peerDot = ui.col:CreateTexture(nil, "OVERLAY")
    ui.peerDot:SetTexture(CP.DISC_TEX)
    ui.peerDot:SetWidth(7)
    ui.peerDot:SetHeight(7)
    ui.peerDot:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 2, -42)
    ui.peerState = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.peerState:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 13, -40)
    ui.peerState:SetJustifyH("LEFT")
    ui.peerState:SetWidth(COL - 13)
    ui.call = ns.MakeKitButton(ui.col)
    ui.call:SetWidth(COL)
    ui.call:SetHeight(24)
    ui.call:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -15)
    ui.solo = ns.MakeKitButton(ui.col)
    ui.solo:SetWidth(COL)
    ui.solo:SetHeight(22)
    ui.solo:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -43)
    ui.solo:Hide()
    ui.peerNote = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.peerNote:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -42)
    ui.peerNote:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -42)
    ui.peerNote:SetJustifyH("LEFT")
    ui.peerNote:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    rule(61)
    ui.turnDisc = CP.Make(ui.col)
    ui.turnDisc:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -72)
    ui.turn = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.turn:SetPoint("LEFT", ui.turnDisc, "RIGHT", 8, 0)
    ui.turn:SetJustifyH("LEFT")
    ui.turn:SetWidth(COL - TURN_DISC - 8)
    local function row(y)
        local cap = capText(ui.col, 0, y)
        local val = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetJustifyH("RIGHT")
        val:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y + 1)
        return cap, val
    end
    ui.gameCap, ui.gameVal = row(CLOCK_TOP)
    ui.gameCap:SetText(ns.T("chess.clockGame"))
    ui.gameVal:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
    ui.moveCap, ui.moveVal = row(CLOCK_TOP + ROW)
    ui.moveVal:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    rule(157)
    ui.takeCap = capText(ui.col, 0, 168)
    ui.takeCap:SetText(ns.T("chess.takenCap"))
    ui.takeScore = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.takeScore:SetJustifyH("RIGHT")
    ui.takeScore:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -168)
    ui.takeScore:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.takeMark = {}
    for k = 1, 2 do
        local t = ui.col:CreateTexture(nil, "ARTWORK")
        t:SetTexture(CP.DISC_TEX)
        t:SetWidth(12)
        t:SetHeight(12)
        t:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(183 + (k - 1) * TAKEN_STEP + 4))
        ui.takeMark[k] = t
    end
    rule(229)
    ui.logCap = capText(ui.col, 0, 240)
    ui.logCap:SetText(ns.T("chess.logCap"))
    ui.logPly = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.logPly:SetJustifyH("RIGHT")
    ui.logPly:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -240)
    ui.logPly:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
    ui.logRow = {}
    for k = 1, LOG_VIS do
        local y = 252 + (k - 1) * LOG_ROW
        local r = {}
        r.lit = ui.col:CreateTexture(nil, "BACKGROUND")
        ns.Paint(r.lit, 0.16, 0.14, 0.09, 1)
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
    ui.resign = ns.MakeKitButton(ui.col)
    ui.resign:SetWidth(71)
    ui.resign:SetHeight(22)
    ui.resign:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, 0)
    ui.resign.text:SetText(ns.T("chess.resignBtn"))
    ui.resign.tip = ns.T("chess.resignTip")
    ui.resign.onClick = function()
        local g = ns.Loop.Current()
        if g and g.AskResign then g:AskResign() end
    end
    ui.draw = ns.MakeKitButton(ui.col)
    ui.draw:SetWidth(71)
    ui.draw:SetHeight(22)
    ui.draw:SetPoint("BOTTOMRIGHT", ui.col, "BOTTOMRIGHT", 0, 0)
    ui.draw.text:SetText(ns.T("chess.drawBtn"))
    ui.draw.tip = ns.T("chess.drawTip")
    ui.draw.onClick = function() ns.Duo.OfferDraw() end
    ui.col:EnableMouseWheel(true)
    ui.col:SetScript("OnMouseWheel", function(_, delta)
        local g = ns.Loop.Current()
        if g and g.LogScroll then g:LogScroll(-delta) end
    end)
    ui.pickBox = ns.NewFrame("Frame", nil, canvas)
    ui.pickBox:SetFrameLevel(board:GetFrameLevel() + 5)
    ui.pickBox:SetBackdrop({
        bgFile = BACK_TEX, edgeFile = EDGE_TEX,
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    ui.pickBox:SetBackdropColor(0.05, 0.05, 0.06, 0.95)
    ui.pickBox:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], 1)
    ui.pickBox:Hide()
    ui.pick = {}
    for k = 1, 4 do
        ui.pick[k] = CP.Make(ui.pickBox)
        ui.pick[k]:Hide()
    end
    ui.glow = ns.NewFrame("Frame", nil, canvas)
    ui.glow:SetFrameLevel(board:GetFrameLevel() + 6)
    ui.glow.tex = ui.glow:CreateTexture(nil, "OVERLAY")
    ui.glow.tex:SetAllPoints(ui.glow)
    ui.glow.tex:SetTexture(GLOW_TEX)
    ui.glow.tex:SetBlendMode("ADD")
    ui.glow.tex:SetVertexColor(1, 0.45, 0.15)
    ui.glow:Hide()
    ui.panel:Hide()
end
local Game = {}
Game.__index = Game
ns.Duo.OnChange(function()
    local game = ns.Loop.Current()
    if not game or not game.def or game.def.id ~= ID then return end
    if game.SyncPeer then game:SyncPeer() end
end)
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, saved)
    self.p, self.s = {}, {}
    for c = 1, 8 do
        self.p[cell(c, 1)], self.s[cell(c, 1)] = BACK[c], 1
        self.p[cell(c, 2)], self.s[cell(c, 2)] = PAWN, 1
        self.p[cell(c, 7)], self.s[cell(c, 7)] = PAWN, 2
        self.p[cell(c, 8)], self.s[cell(c, 8)] = BACK[c], 2
    end
    self.turn, self.ply = 1, 0
    self.ep = nil
    self.cr = { { k = true, q = true }, { k = true, q = true } }
    self.taken = { {}, {} }
    self.log = {}
    self.over, self.overAt, self.boom = nil, nil, nil
    self.endKind, self.stuck = nil, nil
    self.last = nil
    self.t, self.moveAt = 0, 0
    self.sel, self.can, self.ban, self.promo, self.pick = nil, nil, nil, nil, nil
    self.logTop = 1
    local restored = saved and #saved > 0
    if restored then
        for m = 1, #saved do apply(self, saved[m]) end
        if self.over then self.overAt = -END_FLASH end
    end
    if not ns.Duo.Active() then ns.Duo.Adopt(ID) end
    if not restored and ns.Duo.Held() then ns.Duo.GoSolo() end
    local room = ns.ChessRooms.Get(ns.ChessRooms.opening)
    ns.ChessRooms.opening = nil
    self.solo = (room and room.solo)
        or (restored and not ns.Duo.Active() and not ns.Duo.Held())
        or false
    self.side = ns.Duo.Side()
    self.peerName = ns.Duo.Peer()
    self.mid = ns.Duo.Mid() or (room and room.mid) or nil
    self.flip = (self.side == 2)
    self:Build()
    self:Draw()
    self:SyncPeer()
    if ns.Duo.Active() and not restored then
        ns.Sfx.Play("start")
        local mid = ns.Duo.Mid()
        if mid then ns.ChessRooms.Begin(mid, ns.Duo.Peer(), ns.Duo.Side()) end
    end
    if not (ns.Duo.Active() or restored or self.solo) then
        self:ToLobby()
    end
end
function Game:PeerEnd(why)
    if self.over then return end
    local mine = self.side or self.turn
    if why == "draw" then
        self.over, self.endKind = 0, "draw"
    else
        self.over, self.endKind = mine, "resign"
    end
    self.overAt = self.t
    ns.Sfx.Play("over")
    self:Room()
    self:Draw()
end
function Game:AskResign()
    local me = self
    ns.Curtain.Ask(self.canvas, ns.T("chess.label"),
        { ns.T("chess.resignAsk", ns.Duo.Peer() or "") },
        {
            {
                label = ns.T("chess.resignYes"),
                onClick = function()
                    local mine = me.side or me.turn
                    me.over, me.endKind = 3 - mine, "resign"
                    me.overAt = me.t
                    me:Room()
                    ns.Duo.Resign()
                    ns.Curtain.Hide()
                    ns.Sfx.Play("over")
                    me:Draw()
                end,
            },
            { label = ns.T("chess.soloNo"), onClick = function() ns.Curtain.Hide() end },
        })
end
function Game:ResultText()
    if not self.over then return nil end
    local mine = self.side
    local peer = self.peerName or ""
    if self.endKind == "draw" then return ns.T("chess.overDrawDeal") end
    if self.over == 0 then return ns.T("chess.overDraw") end
    if self.endKind == "resign" then
        if not mine then
            return ns.T((self.over == 1) and "chess.overResignBlack" or "chess.overResignWhite")
        end
        return (self.over == mine) and ns.T("chess.overResignPeer", peer)
            or ns.T("chess.overResignMine")
    end
    if not mine then
        return ns.T((self.over == 1) and "chess.overMateWhite" or "chess.overMateBlack")
    end
    return (self.over == mine) and ns.T("chess.overMateMine")
        or ns.T("chess.overMatePeer", peer)
end
function Game:Room()
    local mid = self.mid or ns.Duo.Mid()
    if not mid then return end
    self.roomPly = self.ply
    if self.over then
        ns.ChessRooms.Put{ mid = mid, peer = ns.Duo.Peer(), side = ns.Duo.Side(),
            n = self.ply, over = true, at = time() }
        return
    end
    ns.ChessRooms.Sync(mid, ns.Duo.Peer(), ns.Duo.Side())
end
function Game:ToLobby()
    self:Room()
    if board then board:Hide() end
    if pool then pool:HideAll() end
    if ui then CP.DustStop(ui.dust) end
    if marks then
        for k = 1, MAX_DOTS do marks.dot[k]:Hide() end
    end
    ui.panel:Hide()
    ui.pickBox:Hide()
    ui.glow:Hide()
    ns.ChessLobby.Show(self.canvas)
end
function Game:BeginRound()
    if self:Playable() then return end
    ns.ChessRooms.Solo()
end
function Game:Playable()
    return self.solo or ns.Duo.Active()
end
function Game:Move(mv)
    local was = self.over
    local took = apply(self, mv)
    if took then
        self.moveAt = self.t
        self.logTop, self.stuck = nil, nil
        local mine = ns.Duo.Active() and self.turn == ns.Duo.Side()
        local ate = self.last and self.last.eat
        if ate then
            self:Dust(self.last.eat, self.last.eatKind, self.last.eatSide)
        end
        if self.over and not was then
            ns.Sfx.Play("over")
        elseif mine then
            ns.Sfx.Play("turn")
        elseif ate then
            ns.Sfx.Play("big")
        else
            ns.Sfx.Play("pop")
        end
    end
    self:Draw()
    return took
end
function Game:Dust(i, kind, side)
    if not (ui and ui.dust and self.cell) then return end
    local x, y = self:CellXY(i)
    ui.dust:ClearAllPoints()
    ui.dust:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x + 3, y + 3)
    CP.Crumble(ui.dust, kind, side, self.cell - 6)
end
function Game:Turn()
    return self.turn
end
function Game:Click(x, y, button)
    if self.over then return end
    if not self:Playable() then return end
    local mine = self.solo and self.turn or (ns.Duo.Side() or 1)
    if self.turn ~= mine then return end
    if self.promo then
        local t = self:PickAt(x, y)
        local from, to = self.promo.from, self.promo.to
        self.promo, self.sel, self.can, self.ban = nil, nil, nil, nil
        if t then
            self:Move{ k = "mv", from = from, to = to, promo = t }
        else
            self:Draw()
        end
        return
    end
    local i = self:CellAt(x, y)
    if button == "RightButton" or not i then
        self:Deselect()
        return
    end
    if self.s[i] == mine then
        if self.sel == i then
            self:Deselect()
        else
            self.sel = i
            self.can = legal(self, i, {})
            self.ban = (self.p[i] == KING) and banned(self, i, self.can) or nil
            self.stuck = (next(self.can) == nil) or nil
            ns.Sfx.Play("pick")
            self:Draw()
        end
        return
    end
    if self.sel and self.can and self.can[i] then
        if self.p[self.sel] == PAWN and (rowOf(i) == 8 or rowOf(i) == 1) then
            self.promo = { from = self.sel, to = i }
            self:Draw()
            return
        end
        local from = self.sel
        self.sel, self.can, self.ban = nil, nil, nil
        self:Move{ k = "mv", from = from, to = i }
        return
    end
    if self.sel then ns.Sfx.Play("deny") end
    self:Deselect()
end
function Game:Deselect()
    if not self.sel and not self.promo then return end
    self.sel, self.can, self.ban, self.promo, self.stuck = nil, nil, nil, nil, nil
    self:Draw()
end
function Game:Update(dt)
    if not ns.Duo.Held() then self.t = self.t + dt end
    if self.over then self:Flash() end
end
function Game:Score()
    return self.ply
end
function Game:Ranked()
    return ns.T("chess.ranked")
end
function Game:IsOver()
    if not self.over then return false end
    return (self.t - (self.overAt or 0)) >= END_FLASH
end
function Game:Mini(on)
    miniOn = on and true or false
    GY = miniOn and MARGIN or TOPGAP
    if self.cell then self:Build() end
end
function Game:Stop()
    miniOn, GY = false, TOPGAP
    ns.Curtain.Hide()
    ns.ChessLobby.Hide()
    if board then board:Hide() end
    if pool then pool:HideAll() end
    if ui then CP.DustStop(ui.dust) end
    if marks then
        for k = 1, MAX_DOTS do marks.dot[k]:Hide() end
    end
    if ui then
        ui.deco:Hide()
        ui.panel:Hide()
        ui.pickBox:Hide()
        ui.glow:Hide()
    end
end
local function targetLine()
    local said = ns.Duo.Status()
    if said then return nil, said, false end
    local name, why = ns.Duo.Target()
    if not name then return nil, ns.T(why or "duoNoTarget"), false end
    ns.Link.Ask(name)
    local state = ns.Link.State(name)
    if state == "yes" then return name, ns.T("chess.peerReady", name), true end
    if state == "asking" then return name, ns.T("duoAsking", name), false end
    return name, ns.T("duoSilent", name), false
end
local STATE_KEY = {
    live = "chess.peerLive", combat = "chess.peerCombat",
    away = "chess.peerAway", quiet = "chess.peerQuiet",
}
function Game:SyncPeer()
    if not ui then return end
    local me = self
    local playing = ns.Duo.Active()
    local held = ns.Duo.Held()
    local peer = ns.Duo.Peer()
    ui.peerDisc:Hide()
    ui.peerName:Hide()
    ui.peerDot:Hide()
    ui.peerState:Hide()
    ui.call:Hide()
    ui.solo:Hide()
    ui.peerNote:Hide()
    if playing and peer then
        local side = ns.Duo.Side() or 1
        CP.Blank(ui.peerDisc, 3 - side, 18)
        ui.peerDisc:SetAlpha(1)
        ui.peerDisc:Show()
        ui.peerName:SetText(peer)
        ui.peerName:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
        ui.peerName:Show()
        local st = ns.Duo.PeerState() or "live"
        local col = (st == "live") and C_LIVE or C_SOFT
        ui.peerDot:SetVertexColor(col[1], col[2], col[3])
        ui.peerDot:Show()
        ui.peerState:SetText(ns.T(STATE_KEY[st] or STATE_KEY.live))
        ui.peerState:SetTextColor(col[1], col[2], col[3])
        ui.peerState:Show()
        return
    end
    if held and peer then
        local side = ns.Duo.Side() or 1
        CP.Blank(ui.peerDisc, 3 - side, 18)
        ui.peerDisc:SetAlpha(0.5)
        ui.peerDisc:Show()
        ui.peerName:SetText(peer)
        ui.peerName:SetTextColor(C_GONE[1], C_GONE[2], C_GONE[3])
        ui.peerName:Show()
        local at = ns.Duo.HeldAt()
        local mins = at and floor((time() - at) / 60) or 0
        ui.peerDot:SetVertexColor(C_GONE[1], C_GONE[2], C_GONE[3])
        ui.peerDot:Show()
        ui.peerState:SetText(ns.T("chess.peerHeld", mins))
        ui.peerState:SetTextColor(C_GONE[1], C_GONE[2], C_GONE[3])
        ui.peerState:Show()
        ui.call:ClearAllPoints()
        ui.call:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -60)
        ui.call:SetHeight(22)
        ui.call.text:SetText(ns.T("chess.callBack", peer))
        ui.call.tip = ns.T("chess.callBackTip")
        ui.call.onClick = function() ns.Duo.Resume() end
        if ns.Duo.Calling() then ui.call:Disable() else ui.call:Enable() end
        ui.call:Show()
        ui.solo.text:SetText(ns.T("chess.soloBtn"))
        ui.solo.tip = ns.T("chess.soloTip")
        ui.solo.onClick = function() me:AskSolo() end
        ui.solo:Show()
        return
    end
    if self.solo then
        ui.peerName:SetText(ns.T("chess.soloName"))
        ui.peerName:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
        ui.peerName:ClearAllPoints()
        ui.peerName:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -16)
        ui.peerName:Show()
        return
    end
    ui.peerName:ClearAllPoints()
    ui.peerName:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 24, -16)
    local name, line, can = targetLine()
    ui.call:ClearAllPoints()
    ui.call:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -15)
    ui.call:SetHeight(24)
    if ns.Duo.Waiting() then
        ui.call.text:SetText(ns.T("duoCancel"))
        ui.call.tip = ns.T("duoCancelTip")
        ui.call.onClick = function() ns.Duo.Cancel() end
        ui.call:Enable()
    else
        ui.call.text:SetText(ns.T("chess.callBtn"))
        ui.call.tip = ns.T("duoWithTip")
        ui.call.onClick = function()
            local who = ns.Duo.Target()
            if who then ns.Duo.Invite(ID, who, me.opts) end
        end
        if can and name then ui.call:Enable() else ui.call:Disable() end
    end
    ui.call:Show()
    ui.peerNote:SetText(line or "")
    ui.peerNote:Show()
end
function Game:AskSolo()
    local me = self
    ns.Curtain.Ask(self.canvas, ns.T("chess.label"),
        { ns.T("chess.soloAsk", ns.Duo.Peer() or "") },
        {
            {
                label = ns.T("chess.soloYes"),
                tip = ns.T("chess.soloTip"),
                onClick = function()
                    ns.Duo.GoSolo()
                    me.solo = true
                    ns.Curtain.Hide()
                    me:SyncPeer()
                    me:Draw()
                end,
            },
            {
                label = ns.T("chess.soloNo"),
                onClick = function() ns.Curtain.Hide() end,
            },
        })
end
local function clock(sec)
    if sec < 0 then sec = 0 end
    return ("%d:%02d"):format(floor(sec / 60), floor(sec % 60))
end
function Game:PanelSync()
    if not ui or not ui.panel:IsShown() then return end
    if self.roomPly ~= self.ply then self:Room() end
    ui.gameVal:SetText(clock(ns.window:Elapsed()))
    local paused, why = ns.Loop.IsPaused()
    if ns.Duo.Held() then
        ui.moveCap:SetText(ns.T("chess.clockHeld"))
        ui.moveVal:SetText("")
    elseif paused then
        ui.moveCap:SetText(ns.T("chess.clockPause"))
        ui.moveVal:SetText(why or "")
    else
        ui.moveCap:SetText(ns.T("chess.clockMove"))
        ui.moveVal:SetText(clock(self.t - (self.moveAt or 0)))
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
end
local function turnText(self)
    local draw = (self.over == 0)
    local who = (self.over and not draw) and self.over or self.turn
    if draw then return ns.T("chess.turnDraw"), C_SOFT end
    if self.over then
        return (who == 1) and ns.T("chess.turnWhiteWon") or ns.T("chess.turnBlackWon"), C_WIN
    end
    if not self:Playable() then return ns.T("chess.turnWait"), C_SOFT end
    local k = kingAt(self, who)
    local check = k and attacked(self, k, 3 - who)
    if self.stuck and not check then return ns.T("chess.stuck"), C_SOFT end
    local text
    if self.solo then
        if check then
            text = (who == 1) and ns.T("chess.checkWhite") or ns.T("chess.checkBlack")
        else
            text = (who == 1) and ns.T("chess.turnWhiteTurn") or ns.T("chess.turnBlackTurn")
        end
    elseif who == (ns.Duo.Side() or 1) then
        text = check and ns.T("chess.checkMine") or ns.T("chess.turnMine")
    else
        text = check and ns.T("chess.checkPeer", ns.Duo.Peer() or "")
            or ns.T("chess.turnPeer", ns.Duo.Peer() or "")
    end
    return text, check and C_CHECK_TXT or C_GOLD
end
function Game:SyncTurn()
    local draw = (self.over == 0)
    local who = (self.over and not draw) and self.over or self.turn
    if ns.Duo.Active() and not self.over then
        ui.resign:Show()
        ui.draw:Show()
    else
        ui.resign:Hide()
        ui.draw:Hide()
    end
    CP.Blank(ui.turnDisc, who, TURN_DISC)
    ui.turnDisc:Show()
    local text, col = turnText(self)
    ui.turn:SetText(text)
    ui.turn:SetTextColor(col[1], col[2], col[3])
end
function Game:MiniNote()
    if not self.cell then return nil end
    return (turnText(self))
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
    local full = floor((self.ply + 1) / 2)
    local top = self.logTop
    if not top or top > full - LOG_VIS + 1 then
        top = full - LOG_VIS + 1
        if top < 1 then top = 1 end
    end
    ui.logPly:SetText(ns.T("chess.logPly", self.ply))
    for k = 1, LOG_VIS do
        local no = top + k - 1
        local r = ui.logRow[k]
        if no <= full and no >= 1 then
            r.num:SetText(no .. ".")
            r.w:SetText(self.log[no * 2 - 1] or "")
            r.b:SetText(self.log[no * 2] or "")
            local last = (no * 2 == self.ply) or (no * 2 - 1 == self.ply)
            if last then
                r.lit:Show()
                r.w:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
                r.b:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
            else
                r.lit:Hide()
                r.w:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
                r.b:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
            end
        else
            r.num:SetText("")
            r.w:SetText("")
            r.b:SetText("")
            r.lit:Hide()
        end
    end
end
function Game:CellXY(i)
    local k = turnIdx(self.flip, i)
    return self.ox + (colOf(k) - 1) * self.cell, self.oy + (rowOf(k) - 1) * self.cell
end
function Game:CellAt(x, y)
    if not self.cell then return nil end
    local c = floor((x - self.ox) / self.cell) + 1
    local r = floor((y - self.oy) / self.cell) + 1
    if c < 1 or c > 8 or r < 1 or r > 8 then return nil end
    return turnIdx(self.flip, cell(c, r))
end
function Game:Build()
    local canvas = self.canvas
    ensureView(canvas)
    self.cell = ns.CellFit(8, BOARD_MAX, 0, 0)
    local side = self.cell * 8
    local slack = floor((BOARD_MAX - side) / 2)
    self.ox = MARGIN + PAD + slack
    self.oy = GY + PAD + slack
    board:ClearAllPoints()
    board:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.ox - PAD, self.oy - PAD)
    board:SetWidth(side + PAD * 2)
    board:SetHeight(side + PAD * 2)
    board:Show()
    board.deck:ClearAllPoints()
    board.deck:SetPoint("BOTTOMLEFT", board, "BOTTOMLEFT", PAD, PAD)
    board.deck:SetWidth(side)
    board.deck:SetHeight(side)
    for k = 1, 64 do
        local c, r = colOf(k), rowOf(k)
        local x, y = (c - 1) * self.cell, (r - 1) * self.cell
        local col = ((c + r) % 2 == 0) and C_DARK or C_LIGHT
        local sq = board.sq[k]
        sq:ClearAllPoints()
        sq:SetWidth(self.cell)
        sq:SetHeight(self.cell)
        sq:SetPoint("BOTTOMLEFT", board.deck, "BOTTOMLEFT", x, y)
        ns.Paint(sq, col[1], col[2], col[3])
        local m = board.mark[k]
        m:ClearAllPoints()
        m:SetWidth(self.cell)
        m:SetHeight(self.cell)
        m:SetPoint("BOTTOMLEFT", board.deck, "BOTTOMLEFT", x, y)
        m:Hide()
    end
    for k = 1, 8 do
        local li = turnIdx(self.flip, cell(k, 1))
        local lf = board.file[k]
        lf:ClearAllPoints()
        lf:SetPoint("BOTTOMRIGHT", board.deck, "BOTTOMLEFT", k * self.cell - 3, 2)
        lf:SetText(FILES[colOf(li)])
        if (k + 1) % 2 == 0 then
            lf:SetTextColor(C_LIGHT[1], C_LIGHT[2], C_LIGHT[3])
        else
            lf:SetTextColor(C_DARK[1], C_DARK[2], C_DARK[3])
        end
        local ri = turnIdx(self.flip, cell(1, k))
        local lr = board.rank[k]
        lr:ClearAllPoints()
        lr:SetPoint("TOPLEFT", board.deck, "BOTTOMLEFT", 3, k * self.cell - 2)
        lr:SetText(rowOf(ri))
        if (1 + k) % 2 == 0 then
            lr:SetTextColor(C_LIGHT[1], C_LIGHT[2], C_LIGHT[3])
        else
            lr:SetTextColor(C_DARK[1], C_DARK[2], C_DARK[3])
        end
    end
    ui.deco:Show()
    if miniOn then ui.panel:Hide() else ui.panel:Show() end
    ui.glow:Hide()
    ui.pickBox:Hide()
end
function Game:Draw()
    if not board or not self.cell then return end
    self:DrawMarks()
    self:DrawPieces()
    self:DrawDots()
    self:DrawPick()
    self:SyncTurn()
    self:SyncLog()
end
function Game:DrawMarks()
    if not board or not self.cell then return end
    local check = {}
    for i = 1, 64 do
        if self.p[i] == KING and attacked(self, i, 3 - self.s[i]) then
            check[i] = true
        end
    end
    local trail = self.last and ns.Duo.Active() and self.turn == ns.Duo.Side()
    for k = 1, 64 do
        local i = turnIdx(self.flip, k)
        local col
        if check[i] then col = C_CHECK
        elseif self.sel == i then col = C_SEL
        elseif trail and (self.last.from == i or self.last.to == i) then col = C_LAST
        end
        local m = board.mark[k]
        if col then
            ns.Paint(m, col[1], col[2], col[3], col[4])
            m:Show()
        else
            m:Hide()
        end
    end
end
function Game:DrawPieces()
    pool:Reset()
    local sz = self.cell - 6
    for i = 1, 64 do
        local t = self.p[i]
        if t then
            local f = pool:Acquire()
            CP.Dress(f, self.s[i], t, sz)
            local x, y = self:CellXY(i)
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x + 3, y + 3)
            f:SetAlpha(1)
            f:Show()
        end
    end
    local price = { 0, 0 }
    for me = 1, 2 do
        local list = self.taken[me]
        local mark = ui.takeMark[me]
        local col = SIDE_COL[me]
        mark:SetVertexColor(col.disc[1], col.disc[2], col.disc[3])
        mark:Show()
        for k = 1, #list do
            price[me] = price[me] + (VALUE[list[k]] or 0)
            if k <= TAKEN_COLS then
                local f = pool:Acquire()
                CP.Dress(f, 3 - me, list[k], TAKEN_SIL)
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", ui.col, "TOPLEFT",
                    16 + (k - 1) * TAKEN_STEP, -(183 + (me - 1) * TAKEN_STEP))
                f:SetAlpha(1)
                f:Show()
            end
        end
    end
    ui.takeScore:SetText(price[1] .. " : " .. price[2])
    pool:HideExtras()
end
function Game:DrawDots()
    local n = 0
    if self.ban and self.sel and not self.promo and not self.over then
        for i in pairs(self.ban) do
            if n < MAX_DOTS then
                n = n + 1
                local d = marks.dot[n]
                local x, y = self:CellXY(i)
                d:ClearAllPoints()
                d:SetVertexColor(1, 1, 1)
                ns.Paint(d, C_BAN[1], C_BAN[2], C_BAN[3], C_BAN[4])
                d:SetWidth(self.cell)
                d:SetHeight(self.cell)
                d:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x, y)
                d:Show()
            end
        end
    end
    if self.can and self.sel and not self.promo and not self.over then
        local eating = (self.p[self.sel] == PAWN) and self.ep or nil
        for i = 1, 64 do
            if self.can[i] and n < MAX_DOTS then
                n = n + 1
                local d = marks.dot[n]
                local x, y = self:CellXY(i)
                d:ClearAllPoints()
                d:SetVertexColor(1, 1, 1)
                if self.p[i] or i == eating then
                    ns.Paint(d, C_TAKE[1], C_TAKE[2], C_TAKE[3], C_TAKE[4])
                    d:SetWidth(self.cell)
                    d:SetHeight(self.cell)
                    d:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x, y)
                else
                    local s = floor(self.cell * 0.3)
                    d:SetTexture(CP.DISC_TEX)
                    d:SetVertexColor(C_DOT[1], C_DOT[2], C_DOT[3], 0.7)
                    d:SetWidth(s)
                    d:SetHeight(s)
                    d:SetPoint("CENTER", self.canvas, "BOTTOMLEFT",
                        x + self.cell / 2, y + self.cell / 2)
                end
                d:Show()
            end
        end
    end
    for k = n + 1, MAX_DOTS do marks.dot[k]:Hide() end
end
function Game:DrawPick()
    if not self.promo then
        ui.pickBox:Hide()
        for k = 1, 4 do ui.pick[k]:Hide() end
        self.pick = nil
        return
    end
    local k = turnIdx(self.flip, self.promo.to)
    local sc, sr = colOf(k), rowOf(k)
    local dir = (sr >= 5) and -1 or 1
    local x = self.ox + (sc - 1) * self.cell
    local y0 = self.oy + (sr - 1) * self.cell
    local bottom = (dir < 0) and (y0 - 3 * self.cell) or y0
    ui.pickBox:ClearAllPoints()
    ui.pickBox:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x - 4, bottom - 4)
    ui.pickBox:SetWidth(self.cell + 8)
    ui.pickBox:SetHeight(4 * self.cell + 8)
    ui.pickBox:Show()
    self.pick = {}
    local sz = self.cell - 6
    for n = 1, 4 do
        local y = y0 + dir * (n - 1) * self.cell
        local f = ui.pick[n]
        CP.Dress(f, self.turn, PROMO_LIST[n], sz)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x + 3, y + 3)
        f:Show()
        self.pick[n] = { x = x, y = y, t = PROMO_LIST[n] }
    end
end
function Game:PickAt(x, y)
    if not self.pick then return nil end
    for n = 1, 4 do
        local r = self.pick[n]
        if x >= r.x and x < r.x + self.cell and y >= r.y and y < r.y + self.cell then
            return r.t
        end
    end
    return nil
end
function Game:Flash()
    if not ui or not self.boom or not self.cell then return end
    local p = (self.t - (self.overAt or 0)) / END_FLASH
    if p < 0 then p = 0 end
    if p >= 1 then
        ui.glow:Hide()
        return
    end
    local x, y = self:CellXY(self.boom)
    local s = self.cell * (1.2 + 3 * p)
    ui.glow:ClearAllPoints()
    ui.glow:SetPoint("CENTER", self.canvas, "BOTTOMLEFT",
        x + self.cell / 2, y + self.cell / 2)
    ui.glow:SetWidth(s)
    ui.glow:SetHeight(s)
    ui.glow.tex:SetAlpha((1 - p) * 0.85)
    ui.glow:Show()
end
local MINI_WHITE = { 0.95, 0.93, 0.87 }
local MINI_BLACK = { 0.15, 0.14, 0.16 }
local MINI = {
    {
        cols = 5, rows = 5, cell = 24, back = "checker",
        fill = {
            { c = 3, r = 3, col = MINI_WHITE },
            { c = 5, r = 5, col = C_TAKE },
        },
        ring = { { c = 3, r = 3 } },
        dot = {
            { c = 2, r = 2, col = C_DOT }, { c = 1, r = 1, col = C_DOT },
            { c = 4, r = 4, col = C_DOT }, { c = 2, r = 4, col = C_DOT },
            { c = 1, r = 5, col = C_DOT }, { c = 4, r = 2, col = C_DOT },
            { c = 5, r = 1, col = C_DOT },
            { c = 5, r = 5, col = MINI_BLACK },
        },
    },
    {
        cols = 4, rows = 2, cell = 24, back = "checker",
        fill = {
            { c = 1, r = 1, col = MINI_WHITE },
            { c = 4, r = 1, col = MINI_WHITE },
        },
        ring = { { c = 1, r = 1 } },
        dot = { { c = 3, r = 1, col = C_DOT } },
    },
    {
        cols = 5, rows = 5, cell = 24, back = "checker",
        fill = {
            { c = 3, r = 2, col = C_CHECK },
            { c = 3, r = 3, col = C_BAN },
        },
        dot = {
            { c = 3, r = 2, col = MINI_WHITE },
            { c = 3, r = 5, col = MINI_BLACK },
            { c = 2, r = 2, col = C_DOT }, { c = 4, r = 2, col = C_DOT },
        },
        arrow = { { c1 = 3, r1 = 5, c2 = 3, r2 = 2, col = C_CHECK } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell)
    ns.MiniChecker(g, C_DARK, C_LIGHT)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.dot or {}) do g:Dot(m.c, m.r, m.col) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpPick(host) paintMini(host, MINI[1]) end
local function helpCastle(host) paintMini(host, MINI[2]) end
local function helpCheck(host) paintMini(host, MINI[3]) end
local function ChessTileIcon(host2, size)
    CP.Paint(host2, 1, 1, KING, host2, size - 4)
end
ns.RegisterGame{
    id = ID,
    label = "chess.label",
    icon = { draw = ChessTileIcon },
    tip = "chess.tip",
    order = 12,
    duo = "turns",
    heldStrip = false,
    physics = false,
    ownPanel = true,
    record = false,
    look = LOOK,
    mini = { w = ZONE + MARGIN * 2, h = ZONE + MARGIN * 2 },
    finale = true,
    done = true,
    New = New,
    help = {
        "chess.help1",
        "chess.help2",
        "chess.help2Sub",
        "chess.help3",
        "chess.help4",
        { art = helpPick, h = 128 },
        "chess.helpPickSub",
        "chess.help5",
        "chess.help6",
        "chess.help7",
        { art = helpCastle, h = 56 },
        "chess.help8",
        { art = helpCheck, h = 128 },
        "chess.helpCheckSub",
        "chess.help9",
        "chess.help10",
        "chess.help11",
        "chess.help12",
        "chess.help13",
    },
}
