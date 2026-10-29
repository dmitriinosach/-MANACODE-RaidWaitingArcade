local ADDON, ns = ...
local ID = "nonogram"
local floor, max, min, abs = math.floor, math.max, math.min, math.abs
local MARGIN = 16
local COL_W = 120
local COL_X = 640 - MARGIN - COL_W
local AREA_X, AREA_Y = MARGIN, 20
local AREA_W = COL_X - MARGIN - AREA_X
local AREA_H = 441
local STRIP_GAP = 4
local GAP, BGAP = 1, 3
local PAD = 6
local LADDER = { 100, 80, 64, 52, 40, 32, 24 }
local SIZES = {
    [5]  = { colN = 3, colStep = 18, rowN = 3, rowStep = 20, font = "NumberFontNormal", dot = 6 },
    [10] = { colN = 5, colStep = 14, rowN = 5, rowStep = 16, font = "NumberFontNormalSmall", dot = 6 },
    [15] = { colN = 4, colStep = 14, rowN = 5, rowStep = 16, font = "NumberFontNormalSmall", dot = 3 },
}
local MAX_N = 15
local HINT_COST = 30
local FADE, PAINT = 0.6, 0.6
local FINALE = FADE + PAINT
local X_FONT = "Fonts\\ARIALN.TTF"
local X_GLYPH = "X"
local LOOK_WOOD = { 0.230, 0.190, 0.130 }
local LOOK_EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE }
local C_LINE   = { 0.36, 0.31, 0.24, 1 }
local C_EMPTY  = { 0.93, 0.89, 0.80, 1 }
local C_LIT    = { 1.00, 0.97, 0.88, 1 }
local C_INK    = { 0.20, 0.17, 0.14, 1 }
local C_INKLIT = { 0.27, 0.23, 0.19, 1 }
local C_FIXINK = { 0.42, 0.30, 0.10, 1 }
local C_PREINK = { 0.48, 0.42, 0.35, 1 }
local C_PREOFF = { 0.80, 0.72, 0.60, 1 }
local C_X      = { 0.55, 0.48, 0.40 }
local C_FIXX   = { 0.80, 0.58, 0.15 }
local C_CLUE   = { 0.95, 0.90, 0.78 }
local C_CLUELIT = { 1.00, 0.82, 0.30 }
local C_DONE   = { 0.45, 0.42, 0.38 }
local C_BAD    = { 1.00, 0.35, 0.30 }
local C_NAME   = { 1.00, 0.82, 0.30 }
local C_DOTBG  = { 0.93, 0.89, 0.80, 0.25 }
local TILE, TGAP, PER = 52, 6, 10
local TILE_X = floor((640 - (PER * TILE + (PER - 1) * TGAP)) / 2)
local TILE_MINI = { [5] = 9, [10] = 4, [15] = 3 }
local PICS, BYKEY
local ui, gal, cur
local preEnter
local Game = {}
Game.__index = Game
local function cluesOf(get, n)
    local out, run = {}, 0
    for k = 1, n do
        if get(k) then
            run = run + 1
        elseif run > 0 then
            out[#out + 1] = run
            run = 0
        end
    end
    if run > 0 then out[#out + 1] = run end
    return out
end
local function loadPack()
    if PICS then return end
    PICS, BYKEY = {}, {}
    for _, src in ipairs(ns.NonogramPack or {}) do
        local n = src.size
        if SIZES[n] and src.rows and #src.rows == n then
            local sol = {}
            for r = 1, n do
                local row = src.rows[r]
                for c = 1, n do sol[(r - 1) * n + c] = string.sub(row, c, c) == "#" end
            end
            local p = { key = src.key, n = n, tint = src.tint or C_INK, sol = sol, rows = {}, cols = {} }
            for r = 1, n do
                p.rows[r] = cluesOf(function(k) return sol[(r - 1) * n + k] end, n)
            end
            for c = 1, n do
                p.cols[c] = cluesOf(function(k) return sol[(k - 1) * n + c] end, n)
            end
            PICS[#PICS + 1] = p
            BYKEY[p.key] = p
        end
    end
end
local function picOptions()
    local list = {}
    for _, src in ipairs(ns.NonogramPack or {}) do
        list[#list + 1] = { key = src.key, label = "nonogram.pic_" .. src.key }
    end
    return list
end
local function lineCells(self, kind, k)
    local n, out = self.n, {}
    for j = 1, n do
        out[j] = (kind == "row") and ((k - 1) * n + j) or ((j - 1) * n + k)
    end
    return out
end
local function judgeLine(self, cells, clue)
    local runs, run, filled, open = {}, 0, 0, false
    for _, i in ipairs(cells) do
        local v = self.cell[i]
        if v == 1 then
            run = run + 1
            filled = filled + 1
        else
            if run > 0 then runs[#runs + 1] = run end
            run = 0
            if v == 0 then open = true end
        end
    end
    if run > 0 then runs[#runs + 1] = run end
    local same = #runs == #clue
    if same then
        for j = 1, #clue do
            if runs[j] ~= clue[j] then same = false break end
        end
    end
    if same then return "done" end
    local sum, longest = 0, 0
    for _, v in ipairs(clue) do
        sum = sum + v
        if v > longest then longest = v end
    end
    local maxRun = 0
    for _, v in ipairs(runs) do if v > maxRun then maxRun = v end end
    if filled > sum or maxRun > longest or not open then return "bad" end
    return "open"
end
local function judge(self)
    local p, n = self.p, self.n
    self.rowState, self.colState = {}, {}
    local all = true
    for k = 1, n do
        self.rowState[k] = judgeLine(self, lineCells(self, "row", k), p.rows[k])
        self.colState[k] = judgeLine(self, lineCells(self, "col", k), p.cols[k])
        if self.rowState[k] ~= "done" or self.colState[k] ~= "done" then all = false end
    end
    return all
end
local function doneCount(self)
    local d = 0
    for k = 1, self.n do
        if self.rowState[k] == "done" then d = d + 1 end
        if self.colState[k] == "done" then d = d + 1 end
    end
    return d
end
local function rcOf(self, i)
    local n = self.n
    return floor((i - 1) / n) + 1, (i - 1) % n + 1
end
local function hintCell(self)
    local N = self.n * self.n
    for i = 1, N do
        if self.cell[i] == 1 and not self.p.sol[i] then return i, 2 end
    end
    for i = 1, N do
        if self.cell[i] == 2 and self.p.sol[i] then return i, 1 end
    end
    for i = 1, N do
        if self.cell[i] == 0 and self.p.sol[i] then return i, 1 end
    end
end
local function apply(self, move)
    if self.won or type(move) ~= "table" then return false end
    local N = self.n * self.n
    if move.k == "line" then
        local a, b, from, to = tonumber(move.a), tonumber(move.b), tonumber(move.from), tonumber(move.to)
        if not (a and b and from and to) then return false end
        if a < 1 or a > N or b < 1 or b > N or from == to then return false end
        if from < 0 or from > 2 or to < 0 or to > 2 then return false end
        local ar, ac = rcOf(self, a)
        local br, bc = rcOf(self, b)
        local step
        if a == b then
            step = 1
        elseif ar == br then
            step = (b > a) and 1 or -1
        elseif ac == bc then
            step = (b > a) and self.n or -self.n
        else
            return false
        end
        local changed = false
        local i = a
        while true do
            if self.cell[i] == from and not self.fixed[i] then
                self.cell[i] = to
                changed = true
            end
            if i == b then break end
            i = i + step
        end
        if not changed then return false end
    elseif move.k == "hint" then
        local i, v = hintCell(self)
        if not i then return false end
        self.cell[i] = v
        self.fixed[i] = true
        self.hints = self.hints + 1
    else
        return false
    end
    self.started = true
    if judge(self) then
        self.won = true
        self.wonAt = self.t
        self.stroke = nil
    end
    return true
end
local function fitCell(n, sz)
    for _, c in ipairs(LADDER) do
        local g = n * c + (n - 1) * GAP + (n / 5 - 1) * (BGAP - GAP)
        local w = sz.rowN * sz.rowStep + STRIP_GAP + g
        local h = sz.colN * sz.colStep + STRIP_GAP + g
        if w <= AREA_W and h <= AREA_H then return c, g end
    end
    return LADDER[#LADDER], n * LADDER[#LADDER] + (n - 1) * GAP + (n / 5 - 1) * (BGAP - GAP)
end
local function layoutOf(n)
    local sz = SIZES[n]
    local cell, g = fitCell(n, sz)
    local rw, ch = sz.rowN * sz.rowStep, sz.colN * sz.colStep
    local bw, bh = rw + STRIP_GAP + g, ch + STRIP_GAP + g
    local bx = AREA_X + floor((AREA_W - bw) / 2)
    local by = AREA_Y + floor((AREA_H - bh) / 2)
    return {
        n = n, sz = sz, cell = cell, g = g, rw = rw, ch = ch, bw = bw, bh = bh,
        bx = bx, by = by, gx = bx + rw + STRIP_GAP, gy = by,
    }
end
local function offs(L, k)
    return (k - 1) * (L.cell + GAP) + floor((k - 1) / 5) * (BGAP - GAP)
end
local function cellBox(L, r, c)
    local x = L.gx + offs(L, c)
    local top = L.gy + L.g - offs(L, r)
    return x, top - L.cell
end
local function axisAt(L, v, from)
    for k = 1, L.n do
        local o = offs(L, k)
        if v >= o and v < o + L.cell then return k end
    end
    if v < 0 then return 1 end
    if v >= L.g then return L.n end
    local best, bd = 1, nil
    for k = 1, L.n do
        local d = abs(v - (offs(L, k) + L.cell / 2))
        if not bd or d < bd then best, bd = k, d end
    end
    return best, true
end
local function cellAt(L, x, y)
    local dx, dy = x - L.gx, (L.gy + L.g) - y
    if dx < 0 or dy < 0 or dx >= L.g or dy >= L.g then return nil end
    local c, cg = axisAt(L, dx)
    local r, rg = axisAt(L, dy)
    if cg or rg then return nil end
    return (r - 1) * L.n + c
end
local function rcNear(L, x, y)
    local c = axisAt(L, x - L.gx)
    local r = axisAt(L, (L.gy + L.g) - y)
    return r, c
end
local function paint(t, c)
    if t._c == c then return end
    t._c = c
    ns.Paint(t, c[1], c[2], c[3], c[4] or 1)
end
local function buildUI(canvas)
    local u = {}
    local base = canvas:GetFrameLevel()
    u.table = ns.MakeTable(canvas, LOOK)
    u.niche = ns.MakeNiche(canvas, 1, LOOK)
    u.niche:Hide()
    u.grid = ns.PlainFrame(canvas, 3)
    u.lines = ns.Fill(u.grid, "BACKGROUND", C_LINE)
    u.lines:SetAllPoints(u.grid)
    u.cells = {}
    for i = 1, MAX_N * MAX_N do
        u.cells[i] = ns.Fill(u.grid, "ARTWORK", C_EMPTY)
    end
    u.grid:Hide()
    u.xs = ns.PlainFrame(canvas, 4)
    u.xs:SetAllPoints(canvas)
    u.xmarks = {}
    for i = 1, MAX_N * MAX_N do
        local fs = u.xs:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetJustifyH("CENTER")
        fs:SetJustifyV("MIDDLE")
        fs:SetText(X_GLYPH)
        fs:Hide()
        u.xmarks[i] = fs
    end
    u.xs:Hide()
    u.clues = ns.PlainFrame(canvas, 4)
    u.clues:SetAllPoints(canvas)
    u.rowClue, u.colClue = {}, {}
    for i = 1, MAX_N * 5 do
        u.rowClue[i] = u.clues:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        u.colClue[i] = u.clues:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    end
    u.clues:Hide()
    u.corner = ns.PlainFrame(canvas, 3)
    u.cornerBg = ns.Fill(u.corner, "BACKGROUND", C_DOTBG)
    u.cornerBg:SetAllPoints(u.corner)
    u.dots = {}
    for i = 1, MAX_N * MAX_N do
        u.dots[i] = ns.Fill(u.corner, "ARTWORK", C_INK)
        u.dots[i]:Hide()
    end
    u.corner:Hide()
    u.kb = ns.PlainFrame(canvas, 6)
    u.kb.edge = {}
    for k = 1, 4 do u.kb.edge[k] = ns.Fill(u.kb, "OVERLAY", LOOK_EDGE[1], LOOK_EDGE[2], LOOK_EDGE[3], 1) end
    u.kb.edge[1]:SetPoint("TOPLEFT", u.kb, "TOPLEFT"); u.kb.edge[1]:SetPoint("TOPRIGHT", u.kb, "TOPRIGHT"); u.kb.edge[1]:SetHeight(2)
    u.kb.edge[2]:SetPoint("BOTTOMLEFT", u.kb, "BOTTOMLEFT"); u.kb.edge[2]:SetPoint("BOTTOMRIGHT", u.kb, "BOTTOMRIGHT"); u.kb.edge[2]:SetHeight(2)
    u.kb.edge[3]:SetPoint("TOPLEFT", u.kb, "TOPLEFT"); u.kb.edge[3]:SetPoint("BOTTOMLEFT", u.kb, "BOTTOMLEFT"); u.kb.edge[3]:SetWidth(2)
    u.kb.edge[4]:SetPoint("TOPRIGHT", u.kb, "TOPRIGHT"); u.kb.edge[4]:SetPoint("BOTTOMRIGHT", u.kb, "BOTTOMRIGHT"); u.kb.edge[4]:SetWidth(2)
    u.kb:Hide()
    u.top = ns.PlainFrame(canvas, 7)
    u.top:SetAllPoints(canvas)
    u.len = u.top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    u.len:SetTextColor(C_NAME[1], C_NAME[2], C_NAME[3])
    u.name = u.top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    u.name:SetTextColor(C_NAME[1], C_NAME[2], C_NAME[3])
    u.top:Hide()
    u.side = ns.NewFrame("Frame", nil, canvas)
    u.side:SetFrameLevel(base + 5)
    u.side:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", COL_X, AREA_Y)
    u.side:SetWidth(COL_W)
    u.side:SetHeight(AREA_H)
    u.tally = ns.MakeScoreboard(u.side, COL_W)
    u.tally:SetPoint("TOPLEFT", u.side, "TOPLEFT", 0, 0)
    u.tally:Notices(u.side, 0, 22)
    local function counter(y)
        local row = {}
        row.cap = u.side:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.cap:SetPoint("TOPLEFT", u.side, "TOPLEFT", 0, -y)
        row.val = u.side:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.val:SetJustifyH("RIGHT")
        row.val:SetPoint("TOPRIGHT", u.side, "TOPRIGHT", 0, -y)
        return row
    end
    u.size = counter(100)
    u.hints = counter(116)
    local function unpause()
        if not ns.Loop.IsPaused() then return false end
        ns.Loop.Resume()
        ns.window:RefreshHead()
        return true
    end
    u.hint = ns.MakeKitButton(u.side)
    u.hint:SetWidth(COL_W)
    u.hint:SetPoint("TOPLEFT", u.side, "TOPLEFT", 0, -140)
    u.hint.onClick = function()
        if unpause() then return end
        if cur and not cur.won and not cur.menu then cur:Move{ k = "hint" } end
    end
    u.back = ns.MakeKitButton(u.side)
    u.back:SetWidth(COL_W)
    u.back:SetPoint("BOTTOMLEFT", u.side, "BOTTOMLEFT", 0, 0)
    u.back.onClick = function()
        if unpause() then return end
        if cur then cur:ToMenu() end
    end
    u.side:Hide()
    return u
end
local function tileMini(tile, p)
    local n, px = p.n, TILE_MINI[p.n]
    local w = n * px
    local ox = floor((TILE - w) / 2)
    tile.mini = {}
    for r = 1, n do
        local c = 1
        while c <= n do
            if p.sol[(r - 1) * n + c] then
                local e = c
                while e < n and p.sol[(r - 1) * n + e + 1] do e = e + 1 end
                local t = ns.Fill(tile, "ARTWORK", p.tint[1], p.tint[2], p.tint[3], 1)
                t:SetPoint("TOPLEFT", tile, "TOPLEFT", ox + (c - 1) * px, -(ox + (r - 1) * px))
                t:SetWidth((e - c + 1) * px)
                t:SetHeight(px)
                tile.mini[#tile.mini + 1] = t
                c = e + 1
            else
                c = c + 1
            end
        end
    end
end
local function buildGallery(canvas)
    local g = {}
    g.root = ns.PlainFrame(canvas, 2)
    g.root:SetAllPoints(canvas)
    g.title = g.root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    g.title:SetPoint("TOPLEFT", g.root, "TOPLEFT", TILE_X, -12)
    g.count = g.root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    g.count:SetPoint("TOPRIGHT", g.root, "TOPLEFT", 640 - TILE_X, -16)
    g.tiles, g.caps = {}, {}
    local y = 44
    for _, n in ipairs({ 5, 10, 15 }) do
        local cap = g.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cap:SetPoint("TOPLEFT", g.root, "TOPLEFT", TILE_X, -y)
        cap.n = n
        g.caps[#g.caps + 1] = cap
        y = y + 16
        local k = 0
        for _, p in ipairs(PICS) do
            if p.n == n then
                local col = k % PER
                if k > 0 and col == 0 then y = y + TILE + 20 end
                local b = ns.MakeSlot(g.root, LOOK)
                b:SetWidth(TILE)
                b:SetHeight(TILE)
                b:SetPoint("TOPLEFT", g.root, "TOPLEFT", TILE_X + col * (TILE + TGAP), -y)
                b.p = p
                tileMini(b, p)
                b.ask = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                b.ask:SetPoint("CENTER", b, "CENTER", 0, 0)
                b.mark = ns.Fill(b, "OVERLAY", LOOK_EDGE[1], LOOK_EDGE[2], LOOK_EDGE[3], 1)
                b.mark:SetWidth(6)
                b.mark:SetHeight(6)
                b.mark:SetPoint("TOPRIGHT", b, "TOPRIGHT", -3, -3)
                b.best = g.root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                b.best:SetPoint("TOP", b, "BOTTOM", 0, -2)
                b:SetScript("OnClick", function(self)
                    if cur then cur:PickPic(self.p.key) end
                end)
                g.tiles[#g.tiles + 1] = b
                k = k + 1
            end
        end
        y = y + TILE + 26
    end
    g.next = ns.MakeKitButton(g.root)
    g.next:SetWidth(160)
    g.next:SetPoint("TOP", g.root, "TOPLEFT", 320, -(y + 4))
    g.next.onClick = function()
        if cur then cur:PickNext() end
    end
    g.root:Hide()
    return g
end
local function ensureView(canvas)
    if ui then return end
    ui = buildUI(canvas)
    gal = buildGallery(canvas)
end
local function solved(key)
    return ns.Records.Best(ID, { pic = key })
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    loadPack()
    local p = BYKEY[self.opts and self.opts.pic] or PICS[1]
    self.opts = { pic = p.key }
    self.p, self.n = p, p.n
    self.L = layoutOf(p.n)
    self.cell, self.fixed = {}, {}
    for i = 1, p.n * p.n do self.cell[i] = 0 end
    self.hints, self.t = 0, 0
    self.started, self.won, self.wonAt = false, false, nil
    self.stroke, self.hover, self.cur = nil, nil, nil
    judge(self)
    if moves and #moves > 0 and not ns.Store.Load(ID, self.opts) then moves = nil end
    if moves and #moves > 0 then
        for k = 1, #moves do apply(self, moves[k]) end
        local rec = ns.Store.Load(ID, self.opts)
        self.t = (rec and rec.elapsed) or 0
        if self.won then self.wonAt = self.t end
    end
    self.menu = not (preEnter or (moves and #moves > 0) or ns.Duo.Active())
    preEnter = nil
    cur = self
    ensureView(self.canvas)
    self:Layout()
    self:Draw()
end
function Game:Layout()
    local L, canvas = self.L, self.canvas
    ui.niche:ClearAllPoints()
    ui.niche:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", L.bx - PAD, L.by - PAD)
    ui.niche:SetWidth(L.bw + PAD * 2)
    ui.niche:SetHeight(L.bh + PAD * 2)
    ui.grid:ClearAllPoints()
    ui.grid:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", L.gx, L.gy)
    ui.grid:SetWidth(L.g)
    ui.grid:SetHeight(L.g)
    local n = L.n
    local size = floor(L.cell * 0.75)
    for i = 1, MAX_N * MAX_N do
        local t, x = ui.cells[i], ui.xmarks[i]
        if i <= n * n then
            local r, c = floor((i - 1) / n) + 1, (i - 1) % n + 1
            local cx, cy = cellBox(L, r, c)
            t:ClearAllPoints()
            t:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", cx, cy)
            t:SetWidth(L.cell)
            t:SetHeight(L.cell)
            t:Show()
            x:ClearAllPoints()
            x:SetPoint("CENTER", canvas, "BOTTOMLEFT", cx + L.cell / 2, cy + L.cell / 2)
            if not ns.SetFont(x, X_FONT, size, "") then ns.SetFont(x, (x:GetFont()), size, "") end
        else
            t:Hide()
            x:Hide()
        end
    end
    local font = _G[L.sz.font]
    for i = 1, MAX_N * 5 do
        if font then
            ui.rowClue[i]:SetFontObject(font)
            ui.colClue[i]:SetFontObject(font)
        end
        ui.rowClue[i]:Hide()
        ui.colClue[i]:Hide()
    end
    local ri, ci = 0, 0
    for k = 1, n do
        local _, cy = cellBox(L, k, 1)
        local list = self.p.rows[k]
        if #list == 0 then list = { 0 } end
        for j = 1, #list do
            ri = ri + 1
            local fs = ui.rowClue[ri]
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", canvas, "BOTTOMLEFT",
                L.gx - STRIP_GAP - (#list - j + 0.5) * L.sz.rowStep, cy + L.cell / 2)
            fs:SetText(list[j])
            fs.line, fs.kind = k, "row"
            fs:Show()
        end
        local cx = cellBox(L, 1, k)
        local cl = self.p.cols[k]
        if #cl == 0 then cl = { 0 } end
        for j = 1, #cl do
            ci = ci + 1
            local fs = ui.colClue[ci]
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", canvas, "BOTTOMLEFT",
                cx + L.cell / 2, L.gy + L.g + STRIP_GAP + (#cl - j + 0.5) * L.sz.colStep)
            fs:SetText(cl[j])
            fs.line, fs.kind = k, "col"
            fs:Show()
        end
    end
    self.nRowClue, self.nColClue = ri, ci
    local dot = L.sz.dot
    local pw = n * dot
    ui.corner:ClearAllPoints()
    ui.corner:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
        L.bx + floor((L.rw - pw) / 2), L.gy + L.g + STRIP_GAP + floor((L.ch - pw) / 2))
    ui.corner:SetWidth(pw)
    ui.corner:SetHeight(pw)
    for i = 1, MAX_N * MAX_N do
        local t = ui.dots[i]
        if i <= n * n then
            local r, c = floor((i - 1) / n) + 1, (i - 1) % n + 1
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", ui.corner, "TOPLEFT", (c - 1) * dot, -(r - 1) * dot)
            t:SetWidth(dot)
            t:SetHeight(dot)
        else
            t:Hide()
        end
    end
    ui.kb:SetWidth(L.cell + 4)
    ui.kb:SetHeight(L.cell + 4)
    ui.name:ClearAllPoints()
    ui.name:SetPoint("CENTER", canvas, "BOTTOMLEFT", L.gx + L.g / 2, L.gy + L.g + STRIP_GAP + L.ch / 2)
end
function Game:Move(move)
    local before = doneCount(self)
    local wasWon = self.won
    local took = apply(self, move)
    if took then
        if self.won and not wasWon then
            ns.Sfx.Play("clear")
        elseif doneCount(self) > before then
            ns.Sfx.Play("big")
        else
            ns.Sfx.Play("pop")
        end
    end
    self:Draw()
    return took
end
local function pair(state, button)
    if button == "RightButton" or button == "mark" then
        if state == 0 then return 0, 2 end
        if state == 2 then return 2, 0 end
        return nil
    end
    if state == 0 then return 0, 1 end
    if state == 1 then return 1, 0 end
    return nil
end
function Game:BeginStroke(i, button, key)
    if self.stroke or not i then return end
    local from, to = pair(self.cell[i], button)
    if not from then return end
    self.stroke = { a = i, b = i, from = from, to = to, btn = button, key = key }
    self:Draw()
end
function Game:Extend(r, c)
    local s = self.stroke
    if not s then return end
    local n = self.n
    local ar, ac = rcOf(self, s.a)
    if not s.axis then
        if r == ar and c == ac then
            if s.b ~= s.a then s.b = s.a; self:Draw() end
            return
        end
        if r == ar then s.axis = "row"
        elseif c == ac then s.axis = "col"
        else s.axis = (abs(c - ac) >= abs(r - ar)) and "row" or "col"
        end
    end
    local b = (s.axis == "row") and ((ar - 1) * n + c) or ((r - 1) * n + ac)
    if b ~= s.b then
        s.b = b
        self:Draw()
    end
end
function Game:Commit()
    local s = self.stroke
    if not s then return end
    self.stroke = nil
    self:Move{ k = "line", a = s.a, b = s.b, from = s.from, to = s.to }
end
function Game:Cancel()
    if not self.stroke then return end
    self.stroke = nil
    self:Draw()
end
function Game:Click(x, y, button)
    if self.menu or self.won or self.stroke then return end
    self:BeginStroke(cellAt(self.L, x, y), button)
end
function Game:Release(x, y, button)
    local s = self.stroke
    if not s or s.key or s.btn ~= button then return end
    self:Commit()
end
function Game:Key(action, down)
    if self.menu or self.won then return end
    local n = self.n
    if action == "left" or action == "right" or action == "up" or action == "down" then
        if not down then return end
        if not self.cur then
            self.cur = floor(n / 2) * n + floor(n / 2) + 1
        else
            local r, c = rcOf(self, self.cur)
            if action == "left" then c = max(1, c - 1)
            elseif action == "right" then c = min(n, c + 1)
            elseif action == "up" then r = max(1, r - 1)
            else r = min(n, r + 1)
            end
            self.cur = (r - 1) * n + c
        end
        if self.stroke and self.stroke.key then
            local r, c = rcOf(self, self.cur)
            self:Extend(r, c)
        end
        self:Draw()
        return
    end
    if action ~= "fire" and action ~= "mark" then return end
    if down then
        if not self.cur then self.cur = floor(n / 2) * n + floor(n / 2) + 1 end
        self:BeginStroke(self.cur, action == "mark" and "mark" or "LeftButton", action)
        self:Draw()
        return
    end
    local s = self.stroke
    if not s or s.key ~= action then return end
    if ns.Loop.IsPaused() then self:Cancel() else self:Commit() end
end
function Game:Update(dt)
    if self.menu then return end
    if self.won then
        if self.t - (self.wonAt or 0) <= FINALE + 0.1 then
            self.t = self.t + dt
            self:Draw()
        else
            self.t = self.t + dt
        end
        return
    end
    if self.started then self.t = self.t + dt end
    self:Hover()
end
function Game:Hover()
    local canvas, L = self.canvas, self.L
    local s = self.stroke
    if s and not s.key and not IsMouseButtonDown(s.btn) then
        self:Cancel()
        s = nil
    end
    local i, x, y
    if not ns.Help.IsShown() then
        local left, bottom = canvas:GetLeft(), canvas:GetBottom()
        local scale = canvas:GetEffectiveScale()
        if left and bottom and scale and scale > 0 then
            local mx, my = GetCursorPosition()
            x, y = mx / scale - left, my / scale - bottom
            i = cellAt(L, x, y)
        end
    end
    if s and not s.key and x then
        local r, c = rcNear(L, x, y)
        self:Extend(r, c)
    end
    if i == self.hover then return end
    self.hover = i
    self:Draw()
end
function Game:Penalized()
    return floor(self.wonAt or self.t) + HINT_COST * self.hints
end
function Game:Clock()
    return ns.Records.Span(self:Penalized()), false
end
function Game:Elapsed()
    return self.t
end
function Game:Marks()
    return { time = self:Penalized() }
end
function Game:Score()
    return 0
end
function Game:IsOver()
    if not self.won then return false end
    return (self.t - (self.wonAt or 0)) >= FINALE
end
function Game:Brink()
    local N = self.n * self.n
    local last
    for i = 1, N do if self.p.sol[i] then last = i end end
    for i = 1, N do
        if not self.fixed[i] then
            if self.p.sol[i] then
                self.cell[i] = (i == last) and 0 or 1
            else
                self.cell[i] = 2
            end
        end
    end
    self.started = true
    self.menu = false
    judge(self)
    self:Draw()
end
function Game:BeginRound()
    if not self.menu then return end
    self.menu = false
    self:Draw()
end
function Game:ToMenu()
    if self.menu then return end
    self.stroke = nil
    self.menu = true
    self:Draw()
end
function Game:PickPic(key)
    if ns.Loop.Current() ~= self then return end
    if ns.Duo.Waiting and ns.Duo.Waiting() then return end
    if key == self.p.key and not self.won then
        self:BeginRound()
        return
    end
    preEnter = true
    ns.window:SaveCurrent()
    ns.window:StartGame(ID, { pic = key }, true)
end
function Game:PickNext()
    local from = 0
    for k, p in ipairs(PICS) do if p.key == self.p.key then from = k end end
    for d = 1, #PICS do
        local p = PICS[(from + d - 1) % #PICS + 1]
        if not solved(p.key) then
            self:PickPic(p.key)
            return
        end
    end
    self:PickPic(PICS[1].key)
end
function Game:Stop()
    if cur == self then cur = nil end
    self.stroke = nil
    if ui then
        ui.table:Hide()
        ui.niche:Hide()
        ui.grid:Hide()
        ui.xs:Hide()
        ui.clues:Hide()
        ui.corner:Hide()
        ui.kb:Hide()
        ui.top:Hide()
        ui.side:Hide()
    end
    if gal then gal.root:Hide() end
end
function Game:PanelSync()
    if not ui or ns.Loop.Current() ~= self then return end
    if ns.Loop.IsPaused() and self.stroke then self:Cancel() end
    if not self.menu then ui.tally:Sync() end
end
function Game:Relocalize()
    self:Draw()
end
function Game:SyncGallery()
    local have = 0
    gal.title:SetText(ns.T("nonogram.galleryTitle"))
    for _, cap in ipairs(gal.caps) do cap:SetText(ns.T("nonogram.size" .. cap.n)) end
    for _, b in ipairs(gal.tiles) do
        local best = solved(b.p.key)
        local open = ns.Store.HasSaved(ID, { pic = b.p.key })
        if best then
            have = have + 1
            for _, t in ipairs(b.mini) do t:Show() end
            b.ask:SetText("")
            b.best:SetText(best.time and ns.Records.Span(best.time) or "")
            b.tipTitle = ns.T("nonogram.pic_" .. b.p.key)
            b.tip = best.time and ns.T("nonogram.tileBestFmt", ns.Records.Span(best.time)) or nil
        else
            for _, t in ipairs(b.mini) do t:Hide() end
            b.ask:SetText("?")
            b.best:SetText("")
            b.tipTitle = ns.T("nonogram.tileUnknown")
            b.tip = ns.T("nonogram.size" .. b.p.n)
        end
        if open then b.mark:Show() else b.mark:Hide() end
        if open then b.tip = (b.tip and (b.tip .. "\n") or "") .. ns.T("nonogram.tileStarted") end
    end
    gal.count:SetText(ns.T("nonogram.galleryCountFmt", have, #gal.tiles))
    gal.next:SetText(ns.T("nonogram.nextButton"))
    gal.next.tip = ns.T("nonogram.nextTip")
end
function Game:Draw()
    if not ui then return end
    ui.table:Show()
    if self.menu then
        ui.niche:Hide(); ui.grid:Hide(); ui.xs:Hide(); ui.clues:Hide()
        ui.corner:Hide(); ui.kb:Hide(); ui.top:Hide(); ui.side:Hide()
        gal.root:Show()
        self:SyncGallery()
        return
    end
    gal.root:Hide()
    ui.niche:Show(); ui.grid:Show(); ui.xs:Show(); ui.clues:Show()
    ui.corner:Show(); ui.top:Show(); ui.side:Show()
    local n, N, L, p = self.n, self.n * self.n, self.L, self.p
    local won = self.won
    local ft = won and (self.t - (self.wonAt or 0)) or 0
    local hr, hc
    if not won then
        local focus = self.hover or self.cur
        if focus then hr, hc = rcOf(self, focus) end
    end
    local pre = {}
    local s = self.stroke
    if s and not won then
        local ar, ac = rcOf(self, s.a)
        local br, bc = rcOf(self, s.b)
        local step = (s.a == s.b) and 1 or ((ar == br) and ((s.b > s.a) and 1 or -1) or ((s.b > s.a) and n or -n))
        local i, len = s.a, 0
        while true do
            len = len + 1
            if self.cell[i] == s.from and not self.fixed[i] then pre[i] = s.to end
            if i == s.b then break end
            i = i + step
        end
        local cx, cy = cellBox(L, br, bc)
        ui.len:ClearAllPoints()
        ui.len:SetPoint("BOTTOMLEFT", ui.top, "BOTTOMLEFT", cx + L.cell + 2, cy + L.cell - 4)
        ui.len:SetText(len)
        ui.len:Show()
    else
        ui.len:Hide()
    end
    for i = 1, N do
        local r = floor((i - 1) / n) + 1
        local v = pre[i] or self.cell[i]
        local lit = (r == hr) or ((i - 1) % n + 1 == hc)
        local col
        if won then
            local turn = FADE + PAINT * (r - 1) / n
            if v == 1 then col = (ft >= turn) and p.tint or C_INK else col = C_EMPTY end
        elseif pre[i] then
            col = (pre[i] == 1) and C_PREINK or C_PREOFF
        elseif v == 1 then
            col = self.fixed[i] and C_FIXINK or (lit and C_INKLIT or C_INK)
        else
            col = lit and C_LIT or C_EMPTY
        end
        paint(ui.cells[i], col)
        local x = ui.xmarks[i]
        if v == 2 then
            local xc = (pre[i] and C_PREINK) or (self.fixed[i] and C_FIXX) or C_X
            x:SetTextColor(xc[1], xc[2], xc[3])
            x:Show()
        else
            x:Hide()
        end
        local d = ui.dots[i]
        if self.cell[i] == 1 then
            paint(d, won and p.tint or C_INK)
            d:Show()
        else
            d:Hide()
        end
    end
    local fade = won and max(0, 1 - ft / FADE) or 1
    ui.xs:SetAlpha(fade)
    ui.clues:SetAlpha(fade)
    for k = 1, self.nRowClue do
        local fs = ui.rowClue[k]
        local st = self.rowState[fs.line]
        local c = (st == "bad" and C_BAD) or (st == "done" and C_DONE) or (fs.line == hr and C_CLUELIT) or C_CLUE
        fs:SetTextColor(c[1], c[2], c[3])
    end
    for k = 1, self.nColClue do
        local fs = ui.colClue[k]
        local st = self.colState[fs.line]
        local c = (st == "bad" and C_BAD) or (st == "done" and C_DONE) or (fs.line == hc and C_CLUELIT) or C_CLUE
        fs:SetTextColor(c[1], c[2], c[3])
    end
    if won and ft >= FINALE then
        ui.name:SetText(ns.T("nonogram.pic_" .. p.key))
        ui.name:Show()
    else
        ui.name:Hide()
    end
    if self.cur and not won then
        local r, c = rcOf(self, self.cur)
        local cx, cy = cellBox(L, r, c)
        ui.kb:ClearAllPoints()
        ui.kb:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", cx - 2, cy - 2)
        ui.kb:Show()
    else
        ui.kb:Hide()
    end
    ui.size.cap:SetText(ns.T("nonogram.sizeCap"))
    ui.size.val:SetText(ns.T("nonogram.size" .. n))
    ui.hints.cap:SetText(ns.T("nonogram.hintsCap"))
    ui.hints.val:SetText(self.hints)
    ui.hint:SetText(ns.T("nonogram.hintButtonFmt", ns.Records.Span(HINT_COST)))
    ui.hint.tip = ns.T("nonogram.hintTipFmt", ns.Records.Span(HINT_COST))
    if won then ui.hint:Disable() else ui.hint:Enable() end
    ui.back:SetText(ns.T("nonogram.backButton"))
    ui.back.tip = ns.T("nonogram.backTip")
end
local ICON_ROWS = { ".#.#.", "#####", "#####", ".###.", "..#.." }
local ICON_PLATE = { 0.16, 0.13, 0.09 }
local ICON_EMPTY = { 0.93, 0.89, 0.80 }
local ICON_INK   = { 0.86, 0.20, 0.24 }
function ns.NonogramTileIcon(host, size)
    local pad = max(1, floor(size * 0.1 + 0.5))
    local cell = max(2, floor((size - pad * 2) / 5))
    local gap = (cell >= 6) and 1 or 0
    local off = floor((size - cell * 5) / 2)
    local plate = ns.ArtFill(host, 1, "BACKGROUND")
    plate:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    plate:SetWidth(size); plate:SetHeight(size)
    ns.Paint(plate, ICON_PLATE[1], ICON_PLATE[2], ICON_PLATE[3], 1)
    for r = 1, 5 do
        for c = 1, 5 do
            local t = ns.ArtFill(host, 1 + (r - 1) * 5 + c, "ARTWORK")
            t:SetPoint("TOPLEFT", host, "TOPLEFT", off + (c - 1) * cell, -(off + (r - 1) * cell))
            t:SetWidth(cell - gap); t:SetHeight(cell - gap)
            local col = (string.sub(ICON_ROWS[r], c, c) == "#") and ICON_INK or ICON_EMPTY
            ns.Paint(t, col[1], col[2], col[3], 1)
        end
    end
end
local HELP_EMPTY = { 0.93, 0.89, 0.80, 1 }
local HELP_INK   = { 0.20, 0.17, 0.14, 1 }
local HELP_CLUE  = { 0.36, 0.31, 0.24, 1 }
local HELP_TEXT  = { 0.95, 0.90, 0.78 }
local function helpLine(host)
    local g = ns.MiniGrid(host, 8, 1, 26, 1)
    local line = "###.#."
    g:Fill(1, 1, HELP_CLUE)
    g:Fill(2, 1, HELP_CLUE)
    g:Text(1, 1, "3", HELP_TEXT)
    g:Text(2, 1, "1", HELP_TEXT)
    for c = 3, 8 do
        g:Fill(c, 1, string.sub(line, c - 2, c - 2) == "#" and HELP_INK or HELP_EMPTY)
    end
end
ns.RegisterGame{
    id = ID,
    label = "nonogram.label",
    icon = { draw = ns.NonogramTileIcon },
    tip = "nonogram.tip",
    order = 5,
    duo = "score",
    physics = false,
    ownPanel = true,
    tally = false,
    clock = "hard",
    look = LOOK,
    saves = "pic",
    finale = true,
    New = New,
    opts = {
        { key = "pic", label = "nonogram.optPicLabel", options = picOptions(),
          def = ns.NonogramPack and ns.NonogramPack[1] and ns.NonogramPack[1].key,
          tip = "nonogram.optPicTip" },
    },
    record = {
        { key = "time", label = "nonogram.recTime", by = "min", mark = "clock", format = "span" },
    },
    keymap = {
        LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
        SPACE = "fire", ["SHIFT-SPACE"] = "mark",
    },
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
        { action = "up",    mouse = false },
        { action = "down",  mouse = false },
        { action = "fire",  label = "nonogram.ctlFill",  mouse = "LMB" },
        { action = "mark",  label = "nonogram.ctlCross", mouse = "RMB" },
    },
    help = {
        "nonogram.help1",
        { art = helpLine, h = 40, sub = "nonogram.help1Sub" },
        "nonogram.help2",
        "nonogram.help3",
        "nonogram.help4",
        "nonogram.help5",
    },
}
