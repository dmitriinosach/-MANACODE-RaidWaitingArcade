local ADDON, ns = ...
local ID = "gems"
local G = ns.gems
local N = 8
local GAP = 4
local PAD = 12
local TINT_EDGE = 4
local GOAL_CELL = 30
local COL_W = 156
local COL_PAD = 14
local COL_IN = COL_W - COL_PAD * 2
local ROW = 22
local M_PAD = 16
local CARD_W, CARD_H, CARD_GAP = 194, 96, 13
local CARD_Y = 360
local SHOW_CELL = 52
local SHOW_STEP = 68
local BLOCK_CELL = 44
local REC_X, REC_W = 440, 184
local LAD_ROWS = 7
local LAD_ROW_H = 42
local LAD_W = 324
local LAD_CARD_X = 360
local LAD_CARD_W = 264
local LAD_DOT = 14
local COLORS_OPEN = 6
local TIME = 180
local MOVES = 30
local MODE_TIME, MODE_MOVES, MODE_SHOP = "time", "moves", "shop"
local TRIES = 3
local HAMMER_ITEM = 5956
local HAMMER_ICON = 16
local T_SWAP, T_CLEAR, T_FALL, T_REFILL = 0.24, 0.18, 0.36, 0.06
local T_BACK = 0.52
local BACK_OUT, BACK_HOLD = 0.42, 0.13
local SEL_A = 0.85
local SEL_HEAT = 0.55
local RING_TEX = "Interface\\AchievementFrame\\UI-Achievement-IconFrame"
local RING_COORD = { 0, 0.5625, 0, 0.5625 }
local RING_SCALE = 1.28
local RING_LIFT = 0.45
local function lift(r, g, b)
    local k = RING_LIFT
    return r + (1 - r) * k, g + (1 - g) * k, b + (1 - b) * k
end
local T_OUT  = 0.38
local T_POUR = 0.85
local POUR_WAYS = 3
local T_CHAIN = 0.7
local T_LEVEL = 1.1
local T_SQUASH = 0.08
local SQUASH = 3
local SWAP_ARC = 4
local CHAIN_SHAKE = 3
local T_SHAKE = 0.16
local SHAKE = 3
local SHAKE_W = 118
local T_GOAL_POP = 0.18
local GOAL_POP = 0.16
local MAX_REMAKE = 100
local DEAD_LIMIT = 3
local FX_RAY  = "beam"
local FX_BOMB = "blast"
local FX_META = "vacuum"
local FX_WIPE = "ripple"
local BLAST_POINTS = 10
local LVL_BONUS = 100
local LEFT_BONUS = 20
local EDGE = { 0.9, 0.74, 0.32, 1 }
local LOOK_WOOD = { 0.230, 0.190, 0.130 }
local LOOK_SCREEN = { 0.138, 0.114, 0.078 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = { EDGE[1], EDGE[2], EDGE[3] },
                          screen = LOOK_SCREEN }
local T_POP = 0.8
local MARK_TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local STAR_COORD = { 0, 0.25, 0, 0.25 }
local ARROW_TEX = "Interface\\TalentFrame\\UI-TalentArrows"
local ARROW = {
    right = { 0.5, 1, 0, 0.5 },
    left  = { 1, 0.5, 0, 0.5 },
    down  = { 0, 0.5, 0, 0.5 },
    up    = { 0, 0.5, 0.5, 0 },
}
local KIND_PLAIN, KIND_ROW, KIND_COL, KIND_BOMB, KIND_META =
    G.KIND_PLAIN, G.KIND_ROW, G.KIND_COL, G.KIND_BOMB, G.KIND_META
local B_NONE, B_ROCK, B_FRAME, B_RAW =
    G.BLOCK_NONE, G.BLOCK_ROCK, G.BLOCK_FRAME, G.BLOCK_RAW
local WILD, WILD_ONE_IN = G.WILD, G.WILD_ONE_IN
local pool, ui, menu, ladder
local preDeck, preKeep
local Game = {}
Game.__index = Game
local floor, abs, min, max = math.floor, math.abs, math.min, math.max
local tinsert = table.insert
local sin, PI = math.sin, math.pi
local function rowY(self, r)
    return self.oy + (self.sy or 0) + (r - 1) * (self.cs + GAP)
end
local function colX(self, c)
    return self.ox + (self.sx or 0) + (c - 1) * (self.cs + GAP)
end
local function neighbor(c, r, d)
    if d == "r" then return c + 1, r end
    return c, r + 1
end
function Game:CellAt(x, y)
    local fx, fy = x - self.ox, y - self.oy
    local step, cs = self.cs + GAP, self.cs
    if fx < 0 or fy < 0 or fx > self.fw or fy > self.fw then return nil, "out" end
    local c = floor(fx / step) + 1
    local r = floor(fy / step) + 1
    if c < 1 or c > N or r < 1 or r > N then return nil, "out" end
    if fx - (c - 1) * step > cs then return nil, "gap" end
    if fy - (r - 1) * step > cs then return nil, "gap" end
    if not self:In(c, r) then return nil, "out" end
    return c, r
end
function Game:In(c, r)
    if c < 1 or c > N then return false end
    return r >= self.low[c] and r <= self.high[c]
end
function Game:MV(c, r)
    if not self:In(c, r) then return nil end
    if self.kind[c][r] == KIND_META then return nil end
    local b = self.block[c][r]
    if b == B_ROCK or b == B_RAW then return nil end
    return self.cell[c][r]
end
function Game:Movable(c, r)
    if not self:In(c, r) then return false end
    if self.block[c][r] ~= B_NONE then return false end
    return self.cell[c][r] ~= nil
end
local WAYS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local AXES = { true, false }
function Game:Run(c, r, horiz, v)
    local dc, dr = horiz and 1 or 0, horiz and 0 or 1
    local len, real = 0, 0
    local function walk(sc, sr, sign)
        local i, k = sc, sr
        while true do
            local w = self:MV(i, k)
            if w == nil or (w ~= v and w ~= WILD) then break end
            len = len + 1
            if w ~= WILD then real = real + 1 end
            i, k = i + dc * sign, k + dr * sign
        end
    end
    walk(c, r, 1)
    walk(c - dc, r - dr, -1)
    return len, real
end
function Game:LineThrough(c, r)
    local v = self:MV(c, r)
    if not v then return false end
    local try = {}
    if v == WILD then
        for _, d in ipairs(WAYS) do
            local i, k = c + d[1], r + d[2]
            while true do
                local w = self:MV(i, k)
                if w == nil then break end
                if w ~= WILD then try[#try + 1] = w break end
                i, k = i + d[1], k + d[2]
            end
        end
    else
        try[1] = v
    end
    for _, want in ipairs(try) do
        for _, horiz in ipairs(AXES) do
            local len, real = self:Run(c, r, horiz, want)
            if len >= 3 and real >= 2 then return true end
        end
    end
    return false
end
function Game:SwapOk(c, r, d)
    local c2, r2 = neighbor(c, r, d)
    if not self:Movable(c, r) or not self:Movable(c2, r2) then return false end
    if self.kind[c][r] ~= KIND_PLAIN or self.kind[c2][r2] ~= KIND_PLAIN then
        return true
    end
    local a, b = self.cell[c][r], self.cell[c2][r2]
    if a == b then return false end
    self.cell[c][r], self.cell[c2][r2] = b, a
    local ok = self:LineThrough(c, r) or self:LineThrough(c2, r2)
    self.cell[c][r], self.cell[c2][r2] = a, b
    return ok
end
function Game:HasMove()
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            if self.kind[c][r] ~= KIND_PLAIN and self.block[c][r] == B_NONE then
                if self:Movable(c + 1, r) or self:Movable(c, r + 1)
                   or self:Movable(c - 1, r) or self:Movable(c, r - 1) then
                    return true
                end
            end
        end
    end
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            if self:SwapOk(c, r, "r") then return true end
            if self:SwapOk(c, r, "u") then return true end
        end
    end
    return false
end
local function linePoints(len)
    if len >= 5 then return 100 end
    if len == 4 then return 60 end
    return 30
end
local function birthAt(self, run, touch)
    if touch then
        for i = 1, #run do
            local s = run[i]
            if ((s.c == touch.c and s.r == touch.r)
                or (s.c == touch.c2 and s.r == touch.r2))
               and self:MV(s.c, s.r) ~= WILD then
                return s.c, s.r
            end
        end
    end
    local m = floor((#run + 1) / 2)
    for i = 0, #run do
        local a, b = run[m - i], run[m + i]
        if a and self:MV(a.c, a.r) ~= WILD then return a.c, a.r end
        if b and self:MV(b.c, b.r) ~= WILD then return b.c, b.r end
    end
    local s = run[m]
    return s.c, s.r
end
function Game:Collect(touch)
    local hit, pts, runs = {}, 0, {}
    for c = 1, N do hit[c] = {} end
    local function scan(at, horiz)
        local run, v, real = {}, nil, 0
        local function close()
            if #run >= 3 and real >= 2 then
                pts = pts + linePoints(#run)
                for k = 1, #run do hit[run[k].c][run[k].r] = true end
                runs[#runs + 1] = { cells = run, horiz = horiz }
            end
        end
        for i = 1, N + 1 do
            local c, r = at(i)
            local w = (i <= N) and self:MV(c, r) or nil
            if w == WILD or (w ~= nil and (v == nil or w == v)) then
                run[#run + 1] = { c = c, r = r }
                if w ~= WILD then v, real = w, real + 1 end
            else
                close()
                local tail = {}
                if w ~= nil then
                    for k = #run, 1, -1 do
                        local s = run[k]
                        if self:MV(s.c, s.r) ~= WILD then break end
                        tinsert(tail, 1, s)
                    end
                end
                run, v, real = tail, nil, 0
                if w ~= nil then
                    run[#run + 1] = { c = c, r = r }
                    v, real = w, 1
                end
            end
        end
    end
    for r = 1, N do scan(function(i) return i, r end, true) end
    for c = 1, N do scan(function(i) return c, i end, false) end
    local births, taken = {}, {}
    local function mark(c, r, kind)
        local key = c * 100 + r
        if taken[key] then return end
        taken[key] = true
        births[#births + 1] = { c = c, r = r, kind = kind }
    end
    for _, run in ipairs(runs) do
        if #run.cells >= 5 then
            local c, r = birthAt(self, run.cells, touch)
            mark(c, r, KIND_META)
        end
    end
    local inH, inV = {}, {}
    for _, run in ipairs(runs) do
        local t = run.horiz and inH or inV
        for _, s in ipairs(run.cells) do t[s.c * 100 + s.r] = true end
    end
    for c = 1, N do
        for r = 1, N do
            local key = c * 100 + r
            if inH[key] and inV[key] then mark(c, r, KIND_BOMB) end
        end
    end
    for _, run in ipairs(runs) do
        if #run.cells == 4 then
            local c, r = birthAt(self, run.cells, touch)
            mark(c, r, run.horiz and KIND_ROW or KIND_COL)
        end
    end
    for _, b in ipairs(births) do hit[b.c][b.r] = nil end
    return hit, pts, births
end
function Game:TopColor()
    local n = {}
    for v = 1, self.colors do n[v] = 0 end
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            local v = self:MV(c, r)
            if v and n[v] then n[v] = n[v] + 1 end
        end
    end
    local best, bn = 1, -1
    for v = 1, self.colors do
        if n[v] > bn then best, bn = v, n[v] end
    end
    return best
end
function Game:Blast(hit, c, r, kind, color)
    if kind == KIND_ROW then
        for i = 1, N do if self:In(i, r) then hit[i][r] = true end end
    elseif kind == KIND_COL then
        for i = self.low[c], self.high[c] do hit[c][i] = true end
    elseif kind == KIND_BOMB then
        for i = c - 1, c + 1 do
            for k = r - 1, r + 1 do
                if self:In(i, k) then hit[i][k] = true end
            end
        end
    elseif kind == KIND_META then
        local want = color or self:TopColor()
        for i = 1, N do
            for k = self.low[i], self.high[i] do
                if self.cell[i][k] == want and self.kind[i][k] ~= KIND_META then
                    hit[i][k] = true
                end
            end
        end
    end
end
local function countHit(self, hit)
    local n = 0
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            if hit[c][r] then n = n + 1 end
        end
    end
    return n
end
function Game:Expand(hit)
    local fired, list = {}, {}
    local before = countHit(self, hit)
    local again = true
    while again do
        again = false
        for c = 1, N do
            for r = self.low[c], self.high[c] do
                local k = self.kind[c][r]
                if hit[c][r] and k ~= KIND_PLAIN and not fired[c * 100 + r] then
                    fired[c * 100 + r] = true
                    list[#list + 1] = { c = c, r = r, kind = k }
                    self:Blast(hit, c, r, k, nil)
                    again = true
                end
            end
        end
    end
    return countHit(self, hit) - before, list
end
function Game:Credit(kind, color)
    for _, g in ipairs(self.goal) do
        if g.kind == kind and (kind ~= "color" or g.color == color) then
            if g.done < g.need then g.done = g.done + 1 end
        end
    end
end
function Game:GoalsDone()
    for _, g in ipairs(self.goal) do
        if g.done < g.need then return false end
    end
    return true
end
function Game:Wave(touch, seed)
    local hit, pts, births = self:Collect(touch)
    if seed then
        for c = 1, N do
            for r = 1, N do
                if seed[c] and seed[c][r] then hit[c][r] = true end
            end
        end
    end
    local blasted, fired = self:Expand(hit)
    pts = pts + blasted * BLAST_POINTS
    local rock = {}
    for c = 1, N do
        rock[c] = {}
        for r = self.low[c], self.high[c] do
            if self.block[c][r] == B_ROCK then
                if hit[c][r]
                   or (self:In(c - 1, r) and hit[c - 1][r])
                   or (self:In(c + 1, r) and hit[c + 1][r])
                   or (self:In(c, r - 1) and hit[c][r - 1])
                   or (self:In(c, r + 1) and hit[c][r + 1]) then
                    rock[c][r] = true
                end
            end
        end
    end
    local dying = {}
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            local b = self.block[c][r]
            if rock[c][r] then
                self.block[c][r] = B_NONE
                self:Credit("rock")
                dying[#dying + 1] = { c = c, r = r, rock = true }
            elseif hit[c][r] then
                if b == B_RAW then
                elseif b == B_FRAME then
                    self.block[c][r] = B_NONE
                    self:Credit("frame")
                    dying[#dying + 1] = { c = c, r = r, frame = true }
                else
                    local v = self.cell[c][r]
                    dying[#dying + 1] = { c = c, r = r, color = v,
                                          kind = self.kind[c][r] }
                    self:Credit("color", v)
                    self.cell[c][r] = nil
                    self.kind[c][r] = KIND_PLAIN
                end
            end
        end
    end
    for _, b in ipairs(births) do
        if self.cell[b.c][b.r] then self.kind[b.c][b.r] = b.kind end
    end
    return dying, pts, blasted, fired
end
local function moveCell(self, c, from, to)
    self.cell[c][to], self.cell[c][from] = self.cell[c][from], nil
    self.kind[c][to], self.kind[c][from] = self.kind[c][from], KIND_PLAIN
    self.block[c][to], self.block[c][from] = self.block[c][from], B_NONE
end
function Game:Fall()
    local moved = {}
    for c = 1, N do
        local w = self.low[c]
        local function refill(from, to)
            local k = 0
            for r = from, to do
                if not self.cell[c][r] and self.block[c][r] == B_NONE then
                    k = k + 1
                    if self.rng:Int(WILD_ONE_IN) == 1 then
                        self.cell[c][r] = WILD
                    else
                        self.cell[c][r] = self.rng:Int(self.colors)
                    end
                    self.kind[c][r] = KIND_PLAIN
                    moved[#moved + 1] = { c = c, r = r, from = to + k }
                end
            end
        end
        for r = self.low[c], self.high[c] do
            local b = self.block[c][r]
            if b == B_ROCK or b == B_FRAME then
                refill(w, r - 1)
                w = r + 1
            elseif self.cell[c][r] or b == B_RAW then
                if w ~= r then
                    moveCell(self, c, r, w)
                    moved[#moved + 1] = { c = c, r = w, from = r }
                end
                w = w + 1
            end
        end
        refill(w, self.high[c])
    end
    return moved
end
function Game:Deliver()
    local n = 0
    for c = 1, N do
        local r = self.low[c]
        if self.block[c][r] == B_RAW then
            self.block[c][r] = B_NONE
            self.cell[c][r] = nil
            self:Credit("raw")
            n = n + 1
        end
    end
    return n
end
function Game:Fill()
    local ok = {}
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            local b = self.block[c][r]
            if b == B_ROCK or b == B_RAW then
                self.cell[c][r] = nil
            else
                local n = 0
                for v = 1, self.colors do
                    local l = self:MV(c - 1, r) == v and self:MV(c - 2, r) == v
                    local d = self:MV(c, r - 1) == v and self:MV(c, r - 2) == v
                    if not (l or d) then
                        n = n + 1
                        ok[n] = v
                    end
                end
                self.cell[c][r] = ok[self.rng:Int(n)]
                self.kind[c][r] = KIND_PLAIN
            end
        end
    end
end
function Game:Remake()
    for _ = 1, MAX_REMAKE do
        self:Fill()
        if self:HasMove() then return true end
    end
    return false
end
function Game:Settle()
    if self:HasMove() then
        self.dead = 0
        return
    end
    repeat
        self.dead = self.dead + 1
        self:Remake()
    until self:HasMove() or self.dead >= DEAD_LIMIT
    self.stuck = not self:HasMove()
end
function Game:Left()
    if self.mode == MODE_TIME then return 0 end
    return max(0, (self.budget or MOVES) - self.used)
end
function Game:Enter(level, attempt)
    self.level, self.attempt = level, attempt
    self.used, self.dead = 0, 0
    self.hammer, self.hammerOn = true, false
    self.cell, self.kind = {}, {}
    for c = 1, N do
        self.cell[c], self.kind[c] = {}, {}
        for r = 1, N do self.kind[c][r] = KIND_PLAIN end
    end
    if self.mode == MODE_SHOP then
        local p = G.Build(self, level, attempt)
        self.budget = p.moves
    else
        G.Open(self, COLORS_OPEN)
        self.budget = MOVES
        self.rng = ns.RNG.New(self.seed)
    end
    self:Remake()
end
function Game:PassLevel()
    self.score = self.score + LVL_BONUS * self.level + LEFT_BONUS * self:Left()
    self.passed = true
end
function Game:FailLevel()
    self.tries = self.tries - 1
    self.passed = false
end
function Game:NextLevel()
    if self.passed then
        self:Enter(self.level + 1, 1)
    else
        self:Enter(self.level, self.attempt + 1)
    end
    if not self.replay and ns.window and ns.window.Checkpoint then
        ns.window:Checkpoint{ k = "lvl", n = self.level, sc = self.score,
                              tr = self.tries, at = self.attempt }
    end
end
function Game:Stage(n)
    self:Enter(max(1, floor(n)), 1)
end
function Game:ApplySwap(move)
    local c, r, d = move.c, move.r, move.d
    if type(c) ~= "number" or type(r) ~= "number" then return false end
    if d ~= "r" and d ~= "u" then return false end
    local c2, r2 = neighbor(c, r, d)
    if not self:Movable(c, r) or not self:Movable(c2, r2) then return false end
    self.cell[c][r], self.cell[c2][r2] = self.cell[c2][r2], self.cell[c][r]
    self.kind[c][r], self.kind[c2][r2] = self.kind[c2][r2], self.kind[c][r]
    self.plays = self.plays + 1
    self.used = self.used + 1
    return true
end
function Game:ApplyHit(move)
    local c, r = move.c, move.r
    if type(c) ~= "number" or type(r) ~= "number" then return false end
    if not self:In(c, r) then return false end
    if not self.hammer then return false end
    local b = self.block[c][r]
    if b == B_RAW then return false end
    if b == B_NONE and not self.cell[c][r] then return false end
    self.hammer = false
    if b == B_ROCK then
        self.block[c][r] = B_NONE
        self:Credit("rock")
    elseif b == B_FRAME then
        self.block[c][r] = B_NONE
        self:Credit("frame")
    else
        self:Credit("color", self.cell[c][r])
        self.cell[c][r] = nil
        self.kind[c][r] = KIND_PLAIN
    end
    return true
end
function Game:Trigger(c, r, c2, r2)
    local k1, k2 = self.kind[c][r], self.kind[c2][r2]
    if k1 == KIND_PLAIN and k2 == KIND_PLAIN then return nil end
    local hit = {}
    for i = 1, N do hit[i] = {} end
    local kill1, kill2 = false, false
    if k1 == KIND_META and k2 == KIND_META then
        kill1, kill2 = true, true
        for i = 1, N do
            for m = self.low[i], self.high[i] do hit[i][m] = true end
        end
    elseif k1 == KIND_META or k2 == KIND_META then
        local other = (k1 == KIND_META) and k2 or k1
        local oc = (k1 == KIND_META) and c2 or c
        local orr = (k1 == KIND_META) and r2 or r
        local want = self.cell[oc][orr]
        if want == WILD then want = self:TopColor() end
        if other == KIND_PLAIN then
            self:Blast(hit, c, r, KIND_META, want)
        else
            for i = 1, N do
                for m = self.low[i], self.high[i] do
                    if self.cell[i][m] == want and self.block[i][m] == B_NONE then
                        self.kind[i][m] = other
                        hit[i][m] = true
                    end
                end
            end
        end
        hit[c][r], hit[c2][r2] = true, true
        kill1, kill2 = (k1 == KIND_META), (k2 == KIND_META)
    elseif k1 == KIND_BOMB and k2 == KIND_BOMB then
        for i = c - 2, c + 2 do
            for m = r - 2, r + 2 do
                if self:In(i, m) then hit[i][m] = true end
            end
        end
        kill1, kill2 = true, true
    elseif (k1 == KIND_BOMB or k2 == KIND_BOMB)
           and k1 ~= KIND_PLAIN and k2 ~= KIND_PLAIN then
        for m = r - 1, r + 1 do
            for i = 1, N do if self:In(i, m) then hit[i][m] = true end end
        end
        for i = c - 1, c + 1 do
            if i >= 1 and i <= N then
                for m = self.low[i], self.high[i] do hit[i][m] = true end
            end
        end
        kill1, kill2 = true, true
    elseif k1 ~= KIND_PLAIN and k2 ~= KIND_PLAIN then
        for i = 1, N do if self:In(i, r) then hit[i][r] = true end end
        for m = self.low[c], self.high[c] do hit[c][m] = true end
        kill1, kill2 = true, true
    else
        local sc = (k1 ~= KIND_PLAIN) and c or c2
        local sr = (k1 ~= KIND_PLAIN) and r or r2
        hit[sc][sr] = true
        return hit
    end
    if k1 == KIND_META and k2 == KIND_META then
        self.fxForce, self.fxDir = FX_WIPE, nil
    elseif k1 == KIND_META or k2 == KIND_META then
        self.fxForce, self.fxDir = FX_META, nil
    elseif k1 == KIND_BOMB or k2 == KIND_BOMB then
        self.fxForce, self.fxDir = FX_BOMB, nil
    else
        self.fxForce, self.fxDir = FX_RAY, "h"
    end
    if kill1 then self.kind[c][r] = KIND_PLAIN end
    if kill2 then self.kind[c2][r2] = KIND_PLAIN end
    return hit
end
function Game:ResolveAll(seed, touch)
    local chain = 1
    while chain <= 200 do
        local dying, pts = self:Wave(touch, seed)
        seed, touch = nil, nil
        if #dying > 0 then
            self.score = self.score + pts * chain
            self:Fall()
            self:Deliver()
            self:Fall()
        elseif self:Deliver() > 0 then
            self:Fall()
        else
            break
        end
        chain = chain + 1
    end
    self.fxForce, self.fxDir = nil, nil
    self:Settle()
    if self.mode == MODE_SHOP then
        if self:GoalsDone() then
            self:PassLevel()
            self:NextLevel()
        elseif self:Left() <= 0 then
            self:FailLevel()
            if self.tries > 0 then self:NextLevel() else self.over = true end
        end
    end
end
local MODES = {
    { key = MODE_TIME,  label = "gems.modeTimeLabel",
      tip = "gems.modeTimeTip" },
    { key = MODE_MOVES, label = "gems.modeMovesLabel",
      tip = "gems.modeMovesTip" },
    { key = MODE_SHOP,  label = "gems.modeShopLabel",
      tip = "gems.modeShopTip" },
}
function Game:Hammer()
    if self.mode ~= MODE_SHOP or not self.hammer then return end
    if self.phase ~= "idle" then return end
    self.hammerOn = not self.hammerOn
    self.picked = nil
    self:Panel()
    self:Draw()
end
function Game:Clock()
    if self.mode ~= MODE_TIME then return nil end
    return ns.Records.Span(self.t), self.t <= 10
end
local function show(f, want)
    if want then f:Show() else f:Hide() end
end
local function ensureUI(canvas)
    if ui then return ui end
    ui = {}
    ui.mulF = CreateFrame("Frame", nil, canvas)
    ui.mulF:SetAllPoints(canvas)
    ui.mulF:SetFrameLevel(canvas:GetFrameLevel() + 20)
    ui.mul = ui.mulF:CreateFontString(nil, "OVERLAY", "NumberFont_Outline_Large")
    if not ui.mul:SetFont("Fonts\\ARIALN.TTF", 52, "THICKOUTLINE") then
        ui.mul:SetFont((ui.mul:GetFont()), 52, "THICKOUTLINE")
    end
    ui.mul:SetTextColor(1, 0.9, 0.3)
    ui.mul:Hide()
    ui.pop = ui.mulF:CreateFontString(nil, "OVERLAY", "NumberFont_Outline_Large")
    if not ui.pop:SetFont("Fonts\\ARIALN.TTF", 22, "OUTLINE") then
        ui.pop:SetFont((ui.pop:GetFont()), 22, "OUTLINE")
    end
    ui.pop:SetTextColor(1, 0.95, 0.6)
    ui.pop:Hide()
    ui.line = {}
    for i = 1, 4 do
        local t = ui.mulF:CreateTexture(nil, "OVERLAY")
        t:SetTexture(1, 1, 1, 1)
        t:Hide()
        ui.line[i] = t
    end
    ui.rings, ui.ringN = {}, 0
    ui.note = ui.mulF:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.note:SetPoint("CENTER", ui.mulF, "CENTER", 0, 0)
    ui.note:Hide()
    ui.root = CreateFrame("Frame", nil, canvas)
    ui.root:SetFrameLevel(canvas:GetFrameLevel() + 3)
    ui.root:SetAllPoints(canvas)
    ui.root:Hide()
    ui.seam = ui.root:CreateTexture(nil, "ARTWORK")
    ui.seam:SetTexture(EDGE[1], EDGE[2], EDGE[3], 0.4)
    ui.seam:SetWidth(1)
    ui.seam:SetPoint("TOPRIGHT", ui.root, "TOPRIGHT", -COL_W, -PAD)
    ui.seam:SetPoint("BOTTOMRIGHT", ui.root, "BOTTOMRIGHT", -COL_W, PAD)
    ui.col = CreateFrame("Frame", nil, ui.root)
    ui.col:SetFrameLevel(ui.root:GetFrameLevel() + 1)
    ui.col:SetPoint("TOPRIGHT", ui.root, "TOPRIGHT", -COL_PAD, -COL_PAD)
    ui.col:SetPoint("BOTTOMRIGHT", ui.root, "BOTTOMRIGHT", -COL_PAD, COL_PAD)
    ui.col:SetWidth(COL_IN)
    ui.tally = ns.MakeScoreboard(ui.col, COL_IN)
    ui.tally:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, 0)
    local function statRow(y, text, big)
        local cap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
        if text then cap:SetText(text) end
        local val = ui.col:CreateFontString(nil, "OVERLAY",
            big and "GameFontNormalLarge" or "GameFontNormal")
        val:SetJustifyH("RIGHT")
        val:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y)
        return cap, val
    end
    ui.bestCap, ui.best = statRow(ROW * 4 + 6, ns.T("gems.colBest"))
    ui.rule = ui.col:CreateTexture(nil, "ARTWORK")
    ui.rule:SetTexture(EDGE[1], EDGE[2], EDGE[3], 0.35)
    ui.rule:SetHeight(1)
    ui.rule:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 5 + 4))
    ui.rule:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -(ROW * 5 + 4))
    ui.leftCap, ui.left = statRow(ROW * 5 + 26, nil, true)
    ui.barBg = ui.col:CreateTexture(nil, "ARTWORK")
    ui.barBg:SetTexture(0.10, 0.09, 0.07, 1)
    ui.barBg:SetWidth(COL_IN)
    ui.barBg:SetHeight(4)
    ui.barBg:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 5 + 52))
    ui.bar = ui.col:CreateTexture(nil, "OVERLAY")
    ui.bar:SetTexture(EDGE[1], EDGE[2], EDGE[3], 0.9)
    ui.bar:SetHeight(4)
    ui.bar:SetPoint("TOPLEFT", ui.barBg, "TOPLEFT", 0, 0)
    ui.lvlCap, ui.lvl = statRow(ROW * 8 + 4, nil, true)
    ui.triesCap, ui.tries = statRow(ROW * 9 + 8, ns.T("gems.colTries"))
    ui.goals = {}
    for i = 1, 3 do
        local row = CreateFrame("Frame", nil, ui.col)
        row:SetWidth(COL_IN)
        row:SetHeight(GOAL_CELL)
        if i == 1 then
            row:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 10 + 12))
        else
            row:SetPoint("TOPLEFT", ui.goals[i - 1], "BOTTOMLEFT", 0, -8)
        end
        row:Hide()
        row.cell = ns.MakeCell(row)
        ns.StyleCell(row.cell, "framed")
        row.cell.tint = row.cell:CreateTexture(nil, "BACKGROUND")
        row.cell.tint:SetAllPoints(row.cell)
        ns.SizeCell(row.cell, GOAL_CELL, 3)
        row.cell:ClearAllPoints()
        row.cell:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        row.text:SetPoint("LEFT", row.cell, "RIGHT", 8, 0)
        ui.goals[i] = row
    end
    ui.back = ns.MakeKitButton(ui.col)
    ui.back:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, 0)
    ui.back:SetWidth(COL_IN)
    ui.back:SetHeight(ROW)
    ns.SetKeyText(ui.back, "gems.toMenu")
    ns.SetKeyTip(ui.back, "gems.toMenuTip")
    ui.ladder = ns.MakeKitButton(ui.col)
    ui.ladder:SetPoint("BOTTOMLEFT", ui.back, "TOPLEFT", 0, 8)
    ui.ladder:SetWidth(COL_IN)
    ui.ladder:SetHeight(ROW)
    ns.SetKeyText(ui.ladder, "gems.toLadder")
    ns.SetKeyTip(ui.ladder, "gems.toLadderTip")
    ui.hammerBtn = ns.MakeKitButton(ui.col)
    ui.hammerBtn:SetPoint("BOTTOMLEFT", ui.ladder, "TOPLEFT", 0, 8)
    ui.hammerBtn:SetWidth(COL_IN)
    ui.hammerBtn:SetHeight(ROW)
    ns.SetKeyText(ui.hammerBtn, "gems.hammerLabel")
    ui.hammerBtn.icon = ui.hammerBtn:CreateTexture(nil, "OVERLAY")
    ui.hammerBtn.icon:SetTexture(ns.Icons.Item(HAMMER_ITEM))
    ns.CropIcon(ui.hammerBtn.icon)
    ui.hammerBtn.icon:SetWidth(HAMMER_ICON)
    ui.hammerBtn.icon:SetHeight(HAMMER_ICON)
    ui.hammerBtn.icon:SetPoint("LEFT", ui.hammerBtn, "LEFT", 6, 0)
    return ui
end
local GOAL_NAME = { rock = "gems.goalRock", frame = "gems.goalFrame", raw = "gems.goalRaw" }
local GOAL_TITLE = { rock = "gems.blkRockCap", frame = "gems.blkFrameCap",
                     raw = "gems.blkRawCap" }
local GOAL_TIP = { rock = "gems.goalRockTip", frame = "gems.goalFrameTip",
                   raw = "gems.goalRawTip" }
function Game:DressGoal(f, g)
    f.icon:SetVertexColor(1, 1, 1)
    if g.kind == "color" then
        f.icon:SetTexture(self:Gem(g.color))
        ns.CropIcon(f.icon)
        local name = self.shelf and self.shelf[g.color]
        local r, gr, b
        if name then r, gr, b = ns.Shelves.Tint(name) else r, gr, b = ns.Palette.RGB(g.color) end
        if not r then r, gr, b = 0.55, 0.55, 0.55 end
        f.tint:SetTexture(r * 0.55, gr * 0.55, b * 0.55, 1)
        f:SetBackdropBorderColor(r, gr, b, 1)
        f.tipTitle = false
        f.tip = ns.T("gems.goalColorTip")
    else
        local own = self.blk and self.blk[g.kind == "rock" and B_ROCK or B_RAW]
        if g.kind == "rock" then
            f.icon:SetTexture(own and ns.IconPath(own) or nil)
            f.tint:SetTexture(0.30, 0.24, 0.18, 1)
            f:SetBackdropBorderColor(0.45, 0.38, 0.30, 1)
        elseif g.kind == "raw" then
            f.icon:SetTexture(own and ns.IconPath(own) or nil)
            f.tint:SetTexture(0.72, 0.62, 0.28, 1)
            f:SetBackdropBorderColor(1, 0.9, 0.4, 1)
        else
            f.icon:SetTexture(self:Gem(1))
            f.icon:SetVertexColor(0.45, 0.55, 0.75)
            f.tint:SetTexture(0.22, 0.30, 0.44, 1)
            f:SetBackdropBorderColor(0.6, 0.8, 1, 1)
        end
        ns.CropIcon(f.icon)
        f.tipTitle = ns.TL(GOAL_TITLE[g.kind])
        f.tip = ns.TL(GOAL_TIP[g.kind])
    end
end
function Game:Panel()
    local u = ensureUI(self.canvas)
    local shop = (self.mode == MODE_SHOP)
    u.root:Show()
    u.best:SetText(self.best and ns.Records.Format(nil, self.best) or ns.T("gems.colNoBest"))
    local left, whole
    if self.mode == MODE_TIME then
        u.leftCap:SetText(ns.T("gems.colLeftTime"))
        u.left:SetText(ns.Records.Span(self.t))
        left, whole = self.t, TIME
    else
        u.leftCap:SetText(ns.T("gems.colLeftMoves"))
        u.left:SetText(tostring(self:Left()))
        left, whole = self:Left(), (self.budget or MOVES)
    end
    if left <= (self.mode == MODE_TIME and 10 or 3) then
        u.left:SetTextColor(1, 0.3, 0.3)
    else
        u.left:SetTextColor(1, 0.82, 0)
    end
    if whole > 0 and left > 0 then
        u.bar:SetWidth(max(1, floor(COL_IN * left / whole)))
        u.bar:Show()
    else
        u.bar:Hide()
    end
    show(u.hammerBtn, shop)
    show(u.ladder, shop)
    if shop then
        local ready = (self.hammer and self.phase == "idle") or false
        if u.hammerReady ~= ready then
            u.hammerReady = ready
            if ready then u.hammerBtn:Enable() else u.hammerBtn:Disable() end
        end
        u.hammerBtn.tip = ns.T("gems.hammerTipReady")
        u.hammerBtn.tipDim = (not self.hammer) and ns.T("gems.hammerTipSpent") or nil
    end
    show(u.lvlCap, shop)
    show(u.lvl, shop)
    show(u.triesCap, shop)
    show(u.tries, shop)
    if not shop then
        for i = 1, #u.goals do u.goals[i]:Hide() end
        return
    end
    u.lvlCap:SetText(ns.T("gems.colOrder"))
    u.lvl:SetText(tostring(self.level) .. (self.wall and " |cffff8080!|r" or ""))
    local col = self.tries > 1 and "|cff40ff40" or "|cffff4040"
    u.tries:SetText(ns.T("gems.triesValFmt", col .. self.tries .. "|r", TRIES))
    for i = 1, #u.goals do
        local g = self.goal[i]
        local row = u.goals[i]
        if g then
            local key = g.kind .. "/" .. (g.color or 0)
            if row.dressed ~= key then
                row.dressed = key
                self:DressGoal(row.cell, g)
            end
            local col = g.done >= g.need and "|cff40ff40" or "|cffffffff"
            row.text:SetText(col .. g.done .. "/" .. g.need .. "|r")
            if row.was and g.done > row.was then row.pop = T_GOAL_POP end
            row.was = g.done
            row:Show()
        else
            row.was, row.pop, row.dressed = nil, nil, nil
            row.cell:SetScale(1)
            row:Hide()
        end
    end
end
function Game:PanelSync()
    if not ui then return end
    if self.menu or self.onLadder then return end
    ui.tally:Sync()
    self:Panel()
end
function Game:ShowPick(c, r)
    local u = ensureUI(self.canvas)
    if not c or not self.cell[c] or not self.cell[c][r] then
        for i = 1, 4 do u.line[i]:Hide() end
        return
    end
    local w = self.cs >= 52 and 2 or 1
    local x, y, sz = colX(self, c), rowY(self, r), self.cs
    local cr, cg, cb = self:Tint(self.cell[c][r])
    local box = {
        { x - w, y - w, sz + w * 2, w },
        { x - w, y + sz, sz + w * 2, w },
        { x - w, y, w, sz },
        { x + sz, y, w, sz },
    }
    for i = 1, 4 do
        local t, m = u.line[i], box[i]
        t:SetTexture(cr, cg, cb, SEL_A)
        t:ClearAllPoints()
        t:SetWidth(m[3])
        t:SetHeight(m[4])
        t:SetPoint("BOTTOMLEFT", u.mulF, "BOTTOMLEFT", m[1], m[2])
        t:Show()
    end
end
function Game:Ring(c, r)
    local u = ensureUI(self.canvas)
    u.ringN = u.ringN + 1
    local t = u.rings[u.ringN]
    if not t then
        t = u.mulF:CreateTexture(nil, "ARTWORK")
        t:SetTexture(RING_TEX)
        t:SetTexCoord(RING_COORD[1], RING_COORD[2], RING_COORD[3], RING_COORD[4])
        t:SetBlendMode("ADD")
        u.rings[u.ringN] = t
    end
    local sz = floor(self.cs * RING_SCALE)
    t:ClearAllPoints()
    t:SetWidth(sz)
    t:SetHeight(sz)
    t:SetPoint("CENTER", u.mulF, "BOTTOMLEFT",
               colX(self, c) + self.cs / 2, rowY(self, r) + self.cs / 2)
    t:Show()
    return t
end
function Game:RingsHide()
    if not ui then return end
    for i = 1, ui.ringN do ui.rings[i]:Hide() end
    ui.ringN = 0
end
function Game:ShowChain(n)
    if not ui then return end
    if n < 2 then
        ui.mul:Hide()
        self.mulT = 0
        return
    end
    ui.mul:SetText("x" .. n)
    ui.mul:ClearAllPoints()
    ui.mul:SetPoint("CENTER", ui.mulF, "BOTTOMLEFT",
                    self.ox + self.fw / 2, self.oy + self.fw / 2)
    ui.mul:SetAlpha(1)
    ui.mul:Show()
    self.mulT = T_CHAIN
end
function Game:ShowPop(pts, x, y)
    if not ui or pts <= 0 then return end
    ui.pop:SetText("+" .. pts)
    ui.pop:ClearAllPoints()
    ui.pop:SetPoint("CENTER", ui.mulF, "BOTTOMLEFT", x, y)
    ui.pop:SetAlpha(1)
    ui.pop:Show()
    self.popT, self.popX, self.popY = T_POP, x, y
end
function Game:SayWall()
    if self.mode ~= MODE_SHOP or not self.wall then return end
    self:ShowNote(ns.T("gems.noteWall"))
end
function Game:ShowNote(text)
    if not ui then return end
    if not text then
        ui.note:Hide()
        return
    end
    ui.mul:Hide()
    self.mulT = 0
    ui.note:SetText(text)
    ui.note:Show()
end
local function makeGemCell(parent)
    local f = ns.MakeCell(parent)
    f:EnableMouse(false)
    ns.StyleCell(f, "framed")
    f.tint = f:CreateTexture(nil, "BACKGROUND")
    f.tint:SetAllPoints(f)
    f.glow = f.over:CreateTexture(nil, "OVERLAY")
    f.glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    f.glow:SetBlendMode("ADD")
    f.glow:SetAllPoints(f)
    f.glow:Hide()
    f.m1 = f:CreateTexture(nil, "OVERLAY")
    f.m2 = f:CreateTexture(nil, "OVERLAY")
    f.m1:Hide()
    f.m2:Hide()
    return f
end
local function ensurePool(canvas)
    if pool then return pool end
    pool = ns.NewPool(function()
        return makeGemCell(canvas)
    end, function(f)
        ns.ResetCell(f)
        f._tint, f._mark = nil, nil
        f.glow:Hide()
        f.m1:Hide()
        f.m2:Hide()
        f:SetAlpha(1)
        f:SetBackdropBorderColor(EDGE[1], EDGE[2], EDGE[3], EDGE[4])
    end)
    return pool
end
local function buildMenu(canvas)
    local m = { cards = {}, gem = {}, sp = {}, blk = {}, rec = {} }
    m.root = CreateFrame("Frame", nil, canvas)
    m.root:SetFrameLevel(canvas:GetFrameLevel() + 6)
    m.root:SetAllPoints(canvas)
    m.root:Hide()
    for i = 1, #MODES do
        local x = M_PAD + (i - 1) * (CARD_W + CARD_GAP)
        local b = CreateFrame("Button", nil, m.root)
        b:SetFrameLevel(m.root:GetFrameLevel() + 2)
        b:SetWidth(CARD_W)
        b:SetHeight(CARD_H)
        b:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", x, CARD_Y)
        b:SetBackdrop{
            bgFile = ns.CARD_BACKDROP.bgFile,
            edgeFile = ns.CARD_BACKDROP.edgeFile,
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        }
        b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        b.name:SetPoint("TOPLEFT", b, "TOPLEFT", 14, -14)
        b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -8)
        b.sub:SetWidth(CARD_W - 28)
        b.sub:SetJustifyH("LEFT")
        b.sub:SetText(ns.TL(MODES[i].tip))
        b:SetScript("OnEnter", function(btn) ns.TipShow(btn) end)
        b:SetScript("OnLeave", function() ns.TipHide() end)
        b:SetScript("OnClick", function(btn)
            if btn.onPick then ns.Sfx.Ui(); btn.onPick() end
        end)
        m.cards[i] = b
    end
    m.gemCap = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.gemCap:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", M_PAD, 330)
    ns.SetKeyText(m.gemCap, "gems.menuGemsCap")
    for i = 1, COLORS_OPEN do
        local f = makeGemCell(m.root)
        f:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT",
                   M_PAD + (i - 1) * SHOW_STEP, 272)
        m.gem[i] = f
    end
    m.spCap = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.spCap:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", M_PAD, 246)
    ns.SetKeyText(m.spCap, "gems.menuSpecialCap")
    local spKind = { KIND_ROW, KIND_COL, KIND_BOMB, KIND_META, KIND_PLAIN }
    local spName = { "gems.spRowLabel", "gems.spColLabel", "gems.spBombLabel",
                     "gems.spMetaLabel", "gems.spWildLabel" }
    local spTip = { "gems.spRowTip", "gems.spColTip", "gems.spBombTip",
                    "gems.spMetaTip", "gems.spWildTip" }
    for i = 1, #spKind do
        local x = M_PAD + (i - 1) * SHOW_STEP
        local f = makeGemCell(m.root)
        f:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", x, 188)
        f.kind = spKind[i]
        f.wild = (spKind[i] == KIND_PLAIN)
        f:EnableMouse(true)
        f.nameKey, f.tipKey = spName[i], spTip[i]
        m.sp[i] = f
    end
    m.blkCap = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.blkCap:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", M_PAD, 150)
    ns.SetKeyText(m.blkCap, "gems.menuBlocksCap")
    local blkName = { "gems.blkRockCap", "gems.blkFrameCap", "gems.blkRawCap" }
    local blkTip = { "gems.goalRockTip", "gems.goalFrameTip", "gems.goalRawTip" }
    for i = 1, 3 do
        local f = makeGemCell(m.root)
        f:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", M_PAD + (i - 1) * SHOW_STEP, 96)
        f:EnableMouse(true)
        f.nameKey, f.tipKey = blkName[i], blkTip[i]
        m.blk[i] = f
    end
    m.recCap = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.recCap:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", REC_X, 330)
    ns.SetKeyText(m.recCap, "gems.menuRecordsCap")
    for i = 1, #MODES do
        local y = 300 - (i - 1) * 26
        local row = {}
        row.name = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", REC_X, y)
        row.name:SetText(ns.TL(MODES[i].label))
        row.val = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.val:SetJustifyH("RIGHT")
        row.val:SetPoint("BOTTOMRIGHT", m.root, "BOTTOMLEFT", REC_X + REC_W, y)
        m.rec[i] = row
    end
    m.play = ns.MakeKitButton(m.root)
    m.play:SetFrameLevel(m.root:GetFrameLevel() + 2)
    m.play:SetWidth(REC_W)
    m.play:SetHeight(40)
    m.play:SetPoint("BOTTOMLEFT", m.root, "BOTTOMLEFT", REC_X, 96)
    ns.SetKeyText(m.play, "gems.play")
    return m
end
local function buildLadder(canvas)
    local d = { row = {}, dot = {}, goal = {} }
    d.root = CreateFrame("Frame", nil, canvas)
    d.root:SetFrameLevel(canvas:GetFrameLevel() + 6)
    d.root:SetAllPoints(canvas)
    d.root:Hide()
    d.sumCap = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d.sumCap:SetPoint("TOPLEFT", d.root, "TOPLEFT", M_PAD, -18)
    d.sumCap:SetText(ns.T("gems.ladRunCap"))
    d.sum = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    d.sum:SetPoint("TOPLEFT", d.sumCap, "BOTTOMLEFT", 0, -6)
    d.rule = d.root:CreateTexture(nil, "ARTWORK")
    d.rule:SetTexture(EDGE[1], EDGE[2], EDGE[3], 0.35)
    d.rule:SetHeight(1)
    d.rule:SetPoint("TOPLEFT", d.root, "TOPLEFT", M_PAD, -84)
    d.rule:SetPoint("TOPRIGHT", d.root, "TOPRIGHT", -M_PAD, -84)
    for i = 1, LAD_ROWS do
        local row = CreateFrame("Frame", nil, d.root)
        row:SetWidth(LAD_W)
        row:SetHeight(LAD_ROW_H - 4)
        row:SetPoint("TOPLEFT", d.root, "TOPLEFT", M_PAD, -(96 + (i - 1) * LAD_ROW_H))
        row.plate = row:CreateTexture(nil, "BACKGROUND")
        row.plate:SetAllPoints(row)
        row.num = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.num:SetJustifyH("RIGHT")
        row.num:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
        row.num:SetWidth(26)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -4)
        row.goal = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.goal:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -20)
        row.state = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.state:SetJustifyH("RIGHT")
        row.state:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -12)
        d.row[i] = row
    end
    d.cardCap = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d.cardCap:SetPoint("TOPLEFT", d.root, "TOPLEFT", LAD_CARD_X, -96)
    d.cardCap:SetText(ns.T("gems.ladNowCap"))
    d.cardName = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    d.cardName:SetPoint("TOPLEFT", d.root, "TOPLEFT", LAD_CARD_X, -116)
    local side = N * LAD_DOT + (N - 1) * 2
    local mx = LAD_CARD_X + floor((LAD_CARD_W - side) / 2)
    for c = 1, N do
        d.dot[c] = {}
        for r = 1, N do
            local t = d.root:CreateTexture(nil, "ARTWORK")
            t:SetWidth(LAD_DOT)
            t:SetHeight(LAD_DOT)
            t:SetPoint("TOPLEFT", d.root, "TOPLEFT",
                       mx + (c - 1) * (LAD_DOT + 2),
                       -(146 + (N - r) * (LAD_DOT + 2)))
            t:Hide()
            d.dot[c][r] = t
        end
    end
    for i = 1, 3 do
        local fs = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", d.root, "TOPLEFT", LAD_CARD_X, -(288 + (i - 1) * 22))
        fs:SetWidth(LAD_CARD_W)
        fs:SetJustifyH("LEFT")
        fs:Hide()
        d.goal[i] = fs
    end
    d.moves = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    d.moves:SetPoint("TOPLEFT", d.root, "TOPLEFT", LAD_CARD_X, -356)
    d.hammer = d.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d.hammer:SetPoint("TOPLEFT", d.root, "TOPLEFT", LAD_CARD_X, -378)
    d.back = ns.MakeKitButton(d.root)
    d.back:SetFrameLevel(d.root:GetFrameLevel() + 2)
    d.back:SetWidth(LAD_CARD_W)
    d.back:SetHeight(34)
    d.back:SetPoint("TOPLEFT", d.root, "TOPLEFT", LAD_CARD_X, -420)
    d.back:SetText(ns.T("gems.ladBack"))
    return d
end
local function ensureLadder(canvas)
    if not ladder then ladder = buildLadder(canvas) end
    return ladder
end
local function ensureMenu(canvas)
    if not menu then menu = buildMenu(canvas) end
    return menu
end
local function put(f, x, y, squash)
    f:ClearAllPoints()
    if f._cs then f:SetHeight(f._cs - (squash or 0)) end
    f:SetPoint("BOTTOMLEFT", f:GetParent(), "BOTTOMLEFT", x, y)
end
local function reseat(self)
    for c = 1, N do
        local col = self.tile[c]
        if col then
            for r, f in pairs(col) do put(f, colX(self, c), rowY(self, r)) end
        end
    end
    for i = 1, #self.dying do
        local d = self.dying[i]
        if d.f then put(d.f, colX(self, d.c), rowY(self, d.r)) end
    end
end
function Game:Gem(color)
    if color == WILD then
        if self.wild then return ns.IconPath(self.wild) end
        return ns.Icons.Gem(1)
    end
    local own = self.shelf and self.shelf[color]
    if own then return ns.IconPath(own) end
    return ns.Icons.Gem(color)
end
function Game:Mark(f, kind)
    if f._mark == kind and f._markCs == self.cs then return end
    f._mark, f._markCs = kind, self.cs
    f.m1:Hide()
    f.m2:Hide()
    if kind == KIND_PLAIN or kind == KIND_META then return end
    if kind == KIND_BOMB then
        f.m1:SetTexture(MARK_TEX)
        f.m1:SetTexCoord(STAR_COORD[1], STAR_COORD[2], STAR_COORD[3], STAR_COORD[4])
        f.m1:SetBlendMode("BLEND")
        f.m1:SetVertexColor(1, 1, 1)
        local s = floor((f._cs or self.cs) * 0.34)
        f.m1:ClearAllPoints()
        f.m1:SetWidth(s)
        f.m1:SetHeight(s)
        f.m1:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.m1:Show()
        return
    end
    local s = floor((f._cs or self.cs) * 0.60)
    local pair = (kind == KIND_ROW)
        and { { ARROW.left, "LEFT", 1, 0 }, { ARROW.right, "RIGHT", -1, 0 } }
        or  { { ARROW.up, "TOP", 0, -1 },   { ARROW.down, "BOTTOM", 0, 1 } }
    local list = { f.m1, f.m2 }
    for i = 1, 2 do
        local t, w = list[i], pair[i]
        t:SetTexture(ARROW_TEX)
        t:SetTexCoord(w[1][1], w[1][2], w[1][3], w[1][4])
        t:SetBlendMode("BLEND")
        t:SetVertexColor(1, 1, 1)
        t:SetAlpha(1)
        t:ClearAllPoints()
        t:SetWidth(s)
        t:SetHeight(s)
        t:SetPoint(w[2], f, w[2], w[3], w[4])
        t:Show()
    end
end
function Game:Tint(color)
    local name = self.shelf and self.shelf[color]
    local r, g, b
    if name then
        r, g, b = ns.Shelves.Tint(name)
    else
        r, g, b = ns.Palette.RGB(color)
    end
    if not r then r, g, b = 0.55, 0.55, 0.55 end
    return r, g, b
end
function Game:Dress(f, color, kind, size)
    size = size or self.cs
    if f._cs ~= size then
        ns.SizeCell(f, size, TINT_EDGE)
        f._cs = size
    end
    kind = kind or KIND_PLAIN
    local own = self.sp and self.sp[kind]
    if own then
        f.icon:SetTexture(ns.IconPath(own))
    else
        f.icon:SetTexture(self:Gem(color))
    end
    ns.CropIcon(f.icon)
    local grey = (kind == KIND_META and not own)
        or (color == WILD and not self.wild)
    if not f.icon:SetDesaturated(grey) and grey then
        f.icon:SetVertexColor(0.72, 0.74, 0.82)
    end
    self:Mark(f, (kind == KIND_BOMB and own) and KIND_PLAIN or kind)
    local key = (kind == KIND_META or color == WILD) and -1 or color
    if f._tint ~= key then
        f._tint = key
        local r, g, b
        if key == -1 then
            r, g, b = 1, 1, 1
        else
            r, g, b = self:Tint(color)
        end
        f.tint:SetTexture(r * 0.55, g * 0.55, b * 0.55, 1)
    end
end
function Game:DressBlock(f, b, size)
    size = size or self.cs
    if f._cs ~= size then
        ns.SizeCell(f, size, TINT_EDGE)
        f._cs = size
    end
    self:Mark(f, KIND_PLAIN)
    local own = self.blk and self.blk[b]
    if own then
        f.icon:SetTexture(ns.IconPath(own))
        ns.CropIcon(f.icon)
    else
        f.icon:SetTexture(nil)
    end
    if b == B_ROCK then
        f.tint:SetTexture(0.30, 0.24, 0.18, 1)
        f._tint = "rock"
        f:SetBackdropBorderColor(0.45, 0.38, 0.30, 1)
    else
        f.tint:SetTexture(0.72, 0.62, 0.28, 1)
        f._tint = "raw"
        f:SetBackdropBorderColor(1, 0.9, 0.4, 1)
    end
end
function Game:Draw()
    local m = ensureMenu(self.canvas)
    if self.menu or self.onLadder then
        if self.onLadder then
            m.root:Hide()
            ensureLadder(self.canvas).root:Show()
        end
        if pool then pool:HideAll() end
        self:RingsHide()
        if ui then
            ui.root:Hide()
            ui.mul:Hide()
            ui.pop:Hide()
            ui.note:Hide()
            for i = 1, 4 do ui.line[i]:Hide() end
        end
        if not self.onLadder then m.root:Show() end
        return
    end
    m.root:Hide()
    if ladder then ladder.root:Hide() end
    local p = ensurePool(self.canvas)
    p:Reset()
    self.rainbow = {}
    self:RingsHide()
    self.tile = {}
    for c = 1, N do self.tile[c] = {} end
    for c = 1, N do
        for r = self.low[c], self.high[c] do
            local b = self.block[c][r]
            local v = self.cell[c][r]
            local f
            if b == B_ROCK or b == B_RAW then
                f = p:Acquire()
                self:DressBlock(f, b)
            elseif v then
                f = p:Acquire()
                self:Dress(f, v, self.kind[c][r])
                if b == B_FRAME then
                    f.icon:SetVertexColor(0.45, 0.55, 0.75)
                    f:SetBackdropBorderColor(0.6, 0.8, 1, 1)
                end
            end
            if f then
                put(f, colX(self, c), rowY(self, r))
                self.tile[c][r] = f
                local k = self.kind[c][r]
                if v and (k ~= KIND_PLAIN or v == WILD) then
                    local t = self:Ring(c, r)
                    if k == KIND_META or v == WILD then
                        self.rainbow[#self.rainbow + 1] = t
                    else
                        local cr, cg, cb = lift(self:Tint(v))
                        t._r, t._g, t._b = cr, cg, cb
                    end
                end
            end
        end
    end
    for i = 1, #self.dying do
        local d = self.dying[i]
        if d.color then
            local f = p:Acquire()
            self:Dress(f, d.color, d.kind)
            put(f, colX(self, d.c), rowY(self, d.r))
            d.f = f
        end
    end
    p:HideExtras()
    local pick = self.picked
    if pick then
        local f = self.tile[pick.c] and self.tile[pick.c][pick.r]
        if f then
            local ar, ag, ab = EDGE[1], EDGE[2], EDGE[3]
            f:SetBackdropBorderColor(ar, ag, ab, 1)
            f.glow:Show()
        end
        self:ShowPick(pick.c, pick.r)
    else
        self:ShowPick(nil)
    end
    self:Panel()
    self:ShowHover(self.hc, self.hr, true)
end
function Game:ShowHover(c, r, force)
    if not force and c == self.hc and r == self.hr then return end
    local old = self.hc and self.tile[self.hc] and self.tile[self.hc][self.hr]
    if old and not (self.picked and self.picked.c == self.hc and self.picked.r == self.hr) then
        old.glow:Hide()
    end
    self.hc, self.hr = c, r
    local f = c and self.tile[c] and self.tile[c][r]
    if f then f.glow:Show() end
end
function Game:Hover()
    if self.menu or self.onLadder then return end
    local canvas = self.canvas
    if not canvas:IsVisible() then return end
    local x, y = GetCursorPosition()
    local s = canvas:GetEffectiveScale()
    local l, b = canvas:GetLeft(), canvas:GetBottom()
    if not s or s == 0 or not l or not b then return end
    local c, r = self:CellAt(x / s - l, y / s - b)
    self:ShowHover(c, r)
end
function Game:Animate(p)
    local ph = self.phase
    if ph == "clear" then
        for i = 1, #self.dying do
            local f = self.dying[i].f
            if f then f:SetAlpha(1 - p) end
        end
        return
    end
    local a = self.anim
    if not a then return end
    if ph == "swap" then
        local x1, y1 = colX(self, a.c), rowY(self, a.r)
        local x2, y2 = colX(self, a.c2), rowY(self, a.r2)
        local f1 = self.tile[a.c] and self.tile[a.c][a.r]
        local f2 = self.tile[a.c2] and self.tile[a.c2][a.r2]
        if self.bad then
            local q
            if p < BACK_OUT then
                local t = p / BACK_OUT
                q = 1 - (1 - t) * (1 - t)
            elseif p < BACK_OUT + BACK_HOLD then
                q = 1
            else
                local t = (p - BACK_OUT - BACK_HOLD) / (1 - BACK_OUT - BACK_HOLD)
                q = 1 - t * t
            end
            if f1 then put(f1, x1 + (x2 - x1) * q, y1 + (y2 - y1) * q) end
            if f2 then put(f2, x2 + (x1 - x2) * q, y2 + (y1 - y2) * q) end
        else
            local arc = SWAP_ARC * sin(p * PI)
            local ax, ay = 0, arc
            if a.r ~= a.r2 then ax, ay = arc, 0 end
            if f1 then put(f1, x2 + (x1 - x2) * p + ax, y2 + (y1 - y2) * p + ay) end
            if f2 then put(f2, x1 + (x2 - x1) * p - ax, y1 + (y2 - y1) * p - ay) end
        end
    elseif ph == "fall" or ph == "pour" then
        local land = T_SQUASH / T_FALL
        local mp, sq = p / (1 - land), 0
        if mp >= 1 then
            mp = 1
            sq = SQUASH * (1 - (p - (1 - land)) / land)
        end
        for i = 1, #a do
            local m = a[i]
            local f = self.tile[m.c] and self.tile[m.c][m.r]
            if f then
                local mq, sq2 = mp, sq
                if m.d and m.d > 0 then
                    local pp = (p - m.d) / (1 - m.d)
                    if pp <= 0 then
                        mq, sq2 = 0, 0
                    else
                        local l2 = land / (1 - m.d)
                        mq = pp / (1 - l2)
                        if mq >= 1 then
                            mq = 1
                            sq2 = SQUASH * (1 - (pp - (1 - l2)) / l2)
                        else
                            sq2 = 0
                        end
                    end
                end
                local q = 1 - (1 - mq) * (1 - mq)
                local top = rowY(self, self.high[m.c])
                local y0, y1 = rowY(self, m.from), rowY(self, m.r)
                local y = y0 + (y1 - y0) * q
                if y > top then
                    local fade = 1 - (y - top) / (self.cs * 0.5)
                    if fade < 0 then fade = 0 end
                    f:SetAlpha(fade)
                    y = top
                else
                    f:SetAlpha(1)
                end
                put(f, colX(self, m.c), y, sq2)
            end
        end
    elseif ph == "out" then
        local drop = self.fw * 0.5 * p * p
        for c = 1, N do
            for r = self.low[c], self.high[c] do
                local f = self.tile[c] and self.tile[c][r]
                if f then
                    f:SetAlpha(1 - p)
                    put(f, colX(self, c), rowY(self, r) - drop)
                end
            end
        end
    end
end
function Game:Pour(way)
    local a = {}
    for c = 1, N do
        local k = 0
        for r = self.low[c], self.high[c] do
            if self.cell[c][r] or self.block[c][r] ~= B_NONE then
                k = k + 1
                local d
                if way == 2 then
                    d = (c - 1) / N * 0.55
                elseif way == 3 then
                    d = (N / 2 - math.abs(c - (N + 1) / 2)) / (N / 2) * 0.5
                else
                    d = ((c - 1) % 2) * 0.12
                end
                d = d + (r - self.low[c]) / N * 0.18
                if d > 0.7 then d = 0.7 end
                a[#a + 1] = { c = c, r = r, from = self.high[c] + k + 2, d = d }
            end
        end
    end
    self.anim = a
end
local function previewStand()
    local theme, stamp = ns.Shelves.Theme(ID), ns.Shelves.stamp
    if preDeck and preDeck.theme == theme and preDeck.stamp == stamp then
        return preDeck.stand
    end
    local roll = ns.RNG.New(floor(GetTime() * 1000))
    local shelf = {}
    for i, sh in ipairs(ns.Shelves.Deal(ID, COLORS_OPEN, roll)) do
        shelf[i] = ns.Shelves.Pick(ID, sh.key, roll)
    end
    local stand = setmetatable({
        shelf = shelf,
        cs = SHOW_CELL,
        sp = {
            [KIND_ROW]  = ns.Shelves.Pick(ID, "sp_row", roll),
            [KIND_COL]  = ns.Shelves.Pick(ID, "sp_col", roll),
            [KIND_BOMB] = ns.Shelves.Pick(ID, "sp_bomb", roll),
            [KIND_META] = ns.Shelves.Pick(ID, "sp_meta", roll),
        },
        wild = ns.Shelves.Pick(ID, "sp_wild", roll),
        blk = {
            [B_ROCK] = ns.Shelves.Pick(ID, "blk_rock", roll),
            [B_RAW]  = ns.Shelves.Pick(ID, "blk_raw", roll),
        },
    }, Game)
    preDeck = { theme = theme, stamp = stamp, stand = stand }
    return stand
end
function Game:SyncMenu()
    local m = ensureMenu(self.canvas)
    local me = self
    for i = 1, #MODES do
        local b, on = m.cards[i], (MODES[i].key == self.mode)
        b.name:SetText(ns.TL(MODES[i].label))
        if on then
            local ar, ag, ab = EDGE[1], EDGE[2], EDGE[3]
            b:SetBackdropBorderColor(ar, ag, ab, 1)
            b:SetBackdropColor(0.16, 0.13, 0.07, 0.95)
            b.name:SetTextColor(1, 0.9, 0.5)
        else
            b:SetBackdropBorderColor(EDGE[1], EDGE[2], EDGE[3], 0.35)
            b:SetBackdropColor(0.06, 0.05, 0.04, 0.85)
            b.name:SetTextColor(0.85, 0.82, 0.75)
        end
        b.tipTitle = ns.TL(MODES[i].label)
        b.tip = ns.TL(MODES[i].tip)
        local key = MODES[i].key
        b.onPick = function() me:PickMode(key) end
        local rec = ns.Records.Best(ID, { mode = key })
        local sc = rec and rec.score
        local row = m.rec[i]
        if sc then
            row.val:SetText(ns.Records.Format(nil, sc))
        else
            row.val:SetText(ns.T("gems.menuNoRec"))
        end
        if on then
            row.name:SetTextColor(1, 0.9, 0.5)
            row.val:SetTextColor(1, 0.9, 0.5)
        else
            row.name:SetTextColor(0.72, 0.69, 0.62)
            row.val:SetTextColor(0.72, 0.69, 0.62)
        end
    end
    local pre = previewStand()
    for i = 1, COLORS_OPEN do
        m.gem[i]._tint = nil
        pre:Dress(m.gem[i], i, KIND_PLAIN, SHOW_CELL)
    end
    for i = 1, #m.sp do
        local f = m.sp[i]
        f._tint = nil
        if f.wild then
            pre:Dress(f, WILD, KIND_PLAIN, SHOW_CELL)
        else
            local color = (f.kind == KIND_META) and 1 or ((i - 1) % COLORS_OPEN + 1)
            pre:Dress(f, color, f.kind, SHOW_CELL)
        end
    end
    for _, list in ipairs({ m.sp, m.blk }) do
        for _, f in ipairs(list) do
            f.tipTitle = ns.T(f.nameKey)
            f.tip = ns.T(f.tipKey)
        end
    end
    local blocks = { B_ROCK, B_FRAME, B_RAW }
    for i = 1, #m.blk do
        local f = m.blk[i]
        f._tint = nil
        if blocks[i] == B_FRAME then
            pre:Dress(f, 2, KIND_PLAIN, BLOCK_CELL)
            f.icon:SetVertexColor(0.45, 0.55, 0.75)
            f:SetBackdropBorderColor(0.6, 0.8, 1, 1)
        else
            pre:DressBlock(f, blocks[i], BLOCK_CELL)
        end
    end
    m.play.onClick = function() me:BeginRound() end
end
function Game:PickMode(key)
    if key == self.mode then return end
    if self.plays > 0 then return end
    if ns.Loop.Current() ~= self then return end
    preKeep = true
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, { mode = key })
end
function Game:BeginRound()
    if not self.menu then return end
    self.menu = false
    if self.mode == MODE_TIME then self.t = TIME end
    self:Draw()
end
function Game:ToMenu()
    if self.menu then return end
    if self.plays == 0 and not self:IsOver() then
        self.menu = true
        if self.mode == MODE_TIME then self.t = TIME end
        self:Draw()
        return
    end
    ns.window:Restart()
end
local function goalText(p)
    local g = p.rec.goal
    if g[1] == "rock" then return ns.T("gems.ladGoalRock") end
    if g[1] == "frame" then return ns.T("gems.ladGoalFrame") end
    if g[1] == "raw" then return ns.T("gems.ladGoalRawFmt", p.raw) end
    if g[2] == "color" then return ns.T("gems.ladGoalTwoFmt", p.need) end
    if g[2] == "frame" then return ns.T("gems.ladGoalMixFmt", p.need) end
    return ns.T("gems.ladGoalColorFmt", p.need)
end
function Game:SyncLadder()
    local d = ensureLadder(self.canvas)
    d.sum:SetText(ns.T("gems.ladSumFmt", self.score, self.level - 1, self.tries, TRIES))
    local first = self.level - (LAD_ROWS - 2)
    if first < 1 then first = 1 end
    for i = 1, LAD_ROWS do
        local n = first + i - 1
        local row = d.row[i]
        local p = G.Params(n)
        row.num:SetText(tostring(n))
        row.name:SetText(ns.TL(p.rec.label) .. (p.wall and (" " .. ns.T("gems.ladWall")) or ""))
        row.goal:SetText(goalText(p) .. "  " .. ns.T("gems.ladMovesFmt", p.moves))
        if n < self.level then
            row.plate:SetTexture(0.10, 0.12, 0.08, 0.85)
            row.state:SetText(ns.T("gems.ladDone"))
            row.state:SetTextColor(0.45, 0.80, 0.35)
            row.num:SetTextColor(0.72, 0.69, 0.62)
            row.name:SetTextColor(0.85, 0.82, 0.75)
        elseif n == self.level then
            row.plate:SetTexture(0.20, 0.16, 0.06, 0.95)
            row.state:SetText(ns.T("gems.ladNow"))
            row.state:SetTextColor(1, 0.82, 0.3)
            row.num:SetTextColor(1, 0.82, 0.3)
            row.name:SetTextColor(1, 0.9, 0.5)
        else
            row.plate:SetTexture(0.06, 0.05, 0.04, 0.7)
            row.state:SetText(ns.T("gems.ladNext"))
            row.state:SetTextColor(0.5, 0.48, 0.44)
            row.num:SetTextColor(0.5, 0.48, 0.44)
            row.name:SetTextColor(0.6, 0.58, 0.53)
        end
    end
    local p = G.Params(self.level)
    d.cardName:SetText(ns.T("gems.ladOrderFmt", self.level, ns.TL(p.rec.label)))
    for c = 1, N do
        for r = 1, N do
            local t = d.dot[c][r]
            if r >= self.low[c] and r <= self.high[c] then
                t:SetTexture(0.24, 0.21, 0.14, 1)
                t:Show()
            else
                t:Hide()
            end
        end
    end
    for i = 1, #d.goal do
        local g = self.goal[i]
        local fs = d.goal[i]
        if g then
            local name = ns.TL(GOAL_NAME[g.kind]) or ns.T("gems.goalColorName")
            fs:SetText(ns.T("gems.ladGoalRowFmt", name, g.done, g.need))
            if g.done >= g.need then
                fs:SetTextColor(0.45, 0.80, 0.35)
            else
                fs:SetTextColor(0.9, 0.87, 0.8)
            end
            fs:Show()
        else
            fs:Hide()
        end
    end
    d.moves:SetText(ns.T("gems.ladMovesLeftFmt", self:Left(), self.budget or 0))
    d.hammer:SetText(self.hammer and ns.T("gems.ladHammerReady")
                                  or ns.T("gems.ladHammerSpent"))
    local me = self
    d.back.onClick = function() me:CloseLadder() end
end
function Game:OpenLadder()
    if self.mode ~= MODE_SHOP or self.menu then return end
    if self.phase ~= "idle" then return end
    self.onLadder = true
    self:SyncLadder()
    self:Draw()
end
function Game:CloseLadder()
    if not self.onLadder then return end
    self.onLadder = false
    self:Draw()
end
local function enterPhase(self, ph, dur)
    self.phase = ph
    self.pt, self.pdur = 0, dur
    self:Draw()
    self:Animate(0)
end
local function goIdle(self)
    self.phase = "idle"
    self.anim, self.bad = nil, false
    self.dying = {}
    self:ShowNote(nil)
    self:Draw()
end
local function afterSettle(self)
    self:Settle()
    if self.mode ~= MODE_SHOP then
        goIdle(self)
        return
    end
    if self:GoalsDone() then
        self:PassLevel()
        ns.Sfx.Play("clear")
        self:ShowNote(ns.T("gems.noteGoalDone"))
        enterPhase(self, "won", T_LEVEL)
        return
    end
    if self:Left() <= 0 or self.stuck then
        local dead = self.stuck
        self.stuck = false
        self:FailLevel()
        ns.Sfx.Play("deny")
        self:ShowNote(self.tries <= 0 and ns.T("gems.noteAttemptsOver")
                      or (dead and ns.T("gems.noteStuck") or ns.T("gems.noteMovesOver")))
        enterPhase(self, "lost", T_LEVEL)
        return
    end
    goIdle(self)
end
local function beginWave(self, chain, seed, touch)
    local dying, pts, blasted, fired = self:Wave(touch, seed)
    if #dying == 0 then
        if self:Deliver() > 0 then
            self.anim = self:Fall()
            enterPhase(self, "fall", T_FALL)
            return
        end
        afterSettle(self)
        return
    end
    self.chain = chain
    self.score = self.score + pts * chain
    self.dying = dying
    if chain >= CHAIN_SHAKE then self.shakeT = T_SHAKE end
    local cells = {}
    for i = 1, #dying do
        local d = dying[i]
        if d.color then
            cells[#cells + 1] = { x = colX(self, d.c) + self.cs / 2,
                                  y = rowY(self, d.r) + self.cs / 2,
                                  size = self.cs, tex = self:Gem(d.color) }
        end
    end
    local force, dir = self.fxForce, self.fxDir
    self.fxForce, self.fxDir = nil, nil
    if not force and fired then
        local best = 0
        for i = 1, #fired do
            local k = fired[i].kind
            local rank = (k == KIND_META and 3) or (k == KIND_BOMB and 2) or 1
            if rank > best then
                best = rank
                if k == KIND_META then
                    force, dir = FX_META, nil
                elseif k == KIND_BOMB then
                    force, dir = FX_BOMB, nil
                else
                    force, dir = FX_RAY, (k == KIND_ROW) and "h" or "v"
                end
            end
        end
    end
    ns.FX.Stop()
    ns.FX.Play(self.canvas, cells,
               { big = blasted > 0 or chain >= 2, force = force, dir = dir })
    ns.Sfx.Play((blasted > 0 or chain >= 2) and "big" or "pop")
    local sx, sy, n = 0, 0, 0
    for i = 1, #cells do
        sx, sy, n = sx + cells[i].x, sy + cells[i].y, n + 1
    end
    if n > 0 then self:ShowPop(pts * chain, sx / n, sy / n) end
    self:ShowChain(chain)
    enterPhase(self, "clear", T_CLEAR)
end
local function phaseEnd(self)
    local ph = self.phase
    if ph == "swap" then
        if self.bad then
            goIdle(self)
        else
            local seed, touch = self.seedHit, self.touch
            self.seedHit, self.touch = nil, nil
            beginWave(self, 1, seed, touch)
        end
    elseif ph == "clear" then
        self.dying = {}
        self.anim = self:Fall()
        enterPhase(self, "fall", T_FALL)
    elseif ph == "fall" then
        self.anim = nil
        enterPhase(self, "refill", T_REFILL)
    elseif ph == "refill" then
        beginWave(self, self.chain + 1)
    elseif ph == "won" or ph == "lost" then
        if not self.passed and self.tries <= 0 then
            self.over = true
            self.phase = "idle"
            self:ShowNote(nil)
            return
        end
        self:ShowNote(nil)
        enterPhase(self, "out", T_OUT)
    elseif ph == "out" then
        self:NextLevel()
        self:Pour(1 + (self.level - 1) % POUR_WAYS)
        enterPhase(self, "pour", T_POUR)
        self:SayWall()
    elseif ph == "pour" then
        goIdle(self)
    else
        goIdle(self)
    end
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Measure()
    local canvas = self.canvas
    local room = canvas.W - COL_W - PAD * 2
    local avail = min(room, canvas.H - PAD * 2)
    self.cs = ns.CellFit(N, avail, GAP, 0)
    self.fw = N * self.cs + (N - 1) * GAP
    self.ox = floor(PAD + (room - self.fw) / 2)
    self.oy = floor((canvas.H - self.fw) / 2)
end
function Game:Start(seed, moves)
    if preKeep then preKeep = nil else preDeck = nil end
    self.seed = seed
    self.score, self.plays, self.chain = 0, 0, 1
    self.phase, self.picked, self.dying, self.anim = "idle", nil, {}, nil
    self.pt, self.pdur, self.mulT = 0, 0, 0
    self.bad, self.stuck, self.timeUp, self.over = false, false, false, false
    self.overSound = false
    self.passed, self.seedHit, self.touch, self.flash = false, nil, nil, nil
    self.popT, self.popX, self.popY = nil, 0, 0
    self.fxForce, self.fxDir = nil, nil
    self.shakeT, self.sx, self.sy = 0, 0, 0
    self.rainbow, self.gt, self.playT = {}, 0, 0
    self.hc, self.hr = nil, nil
    self.tile = {}
    self.tries = TRIES
    self.mode = self.opts and self.opts.mode or MODE_TIME
    if self.mode ~= MODE_MOVES and self.mode ~= MODE_SHOP then self.mode = MODE_TIME end
    self.t = TIME
    self:Measure()
    local pick = ns.RNG.New(seed)
    self.shelf = {}
    for i, sh in ipairs(ns.Shelves.Deal(ID, COLORS_OPEN, pick)) do
        self.shelf[i] = ns.Shelves.Pick(ID, sh.key, pick)
    end
    self.tints = {}
    for i = 1, COLORS_OPEN do
        local name = self.shelf and self.shelf[i]
        local r, g, b
        if name then r, g, b = ns.Shelves.Tint(name) end
        if not r then r, g, b = ns.Palette.RGB(i) end
        if r then self.tints[#self.tints + 1] = { r, g, b } end
    end
    if #self.tints == 0 then self.tints[1] = { 1, 1, 1 } end
    self.sp = {
        [KIND_ROW]  = ns.Shelves.Pick(ID, "sp_row", pick),
        [KIND_COL]  = ns.Shelves.Pick(ID, "sp_col", pick),
        [KIND_BOMB] = ns.Shelves.Pick(ID, "sp_bomb", pick),
        [KIND_META] = ns.Shelves.Pick(ID, "sp_meta", pick),
    }
    self.wild = ns.Shelves.Pick(ID, "sp_wild", pick)
    self.blk = {
        [B_ROCK] = ns.Shelves.Pick(ID, "blk_rock", pick),
        [B_RAW]  = ns.Shelves.Pick(ID, "blk_raw", pick),
    }
    local from, lvl, att = 1, 1, 1
    if moves and moves[1] and moves[1].k == "lvl" then
        local m = moves[1]
        lvl = type(m.n) == "number" and m.n or 1
        att = type(m.at) == "number" and m.at or 1
        self.score = type(m.sc) == "number" and m.sc or 0
        self.tries = type(m.tr) == "number" and m.tr or TRIES
        from = 2
    end
    self:Enter(lvl, att)
    if moves then
        self.replay = true
        for i = from, #moves do
            local mv = moves[i]
            if type(mv) == "table" then
                if mv.k == "swap" then
                    if self:ApplySwap(mv) then
                        local c2, r2 = neighbor(mv.c, mv.r, mv.d)
                        local hit = self:Trigger(mv.c, mv.r, c2, r2)
                        self:ResolveAll(hit, { c = mv.c, r = mv.r, c2 = c2, r2 = r2 })
                    end
                elseif mv.k == "hit" then
                    if self:ApplyHit(mv) then self:ResolveAll(nil, nil) end
                end
            end
        end
        self.replay = false
        local rec = ns.Store.Load(ID)
        local was = rec and rec.elapsed
        if type(was) == "number" then
            self.playT = was
            if self.mode == MODE_TIME then
                self.t = TIME - was
                if self.t <= 0 then
                    self.t, self.timeUp = 0, true
                end
            end
        end
    end
    self.menu = not (moves and #moves > 0)
    self.onLadder = false
    local best = ns.Records.Best(ID, self.opts)
    self.best = best and best.score or nil
    local u = ensureUI(self.canvas)
    local me = self
    u.hammerBtn.onClick = function() me:Hammer() end
    u.back.onClick = function() me:ToMenu() end
    u.ladder.onClick = function() me:OpenLadder() end
    self:SyncMenu()
    if moves and #moves > 0 then
        self:Draw()
    else
        self:Pour(1 + (self.level - 1) % POUR_WAYS)
        enterPhase(self, "pour", T_POUR)
        self:SayWall()
    end
end
function Game:Move(move)
    if type(move) ~= "table" then return false end
    if move.k == "hit" then
        if not self:ApplyHit(move) then return false end
        self.hammerOn = false
        self.chain = 1
        self.anim = self:Fall()
        enterPhase(self, "fall", T_FALL)
        return
    end
    if move.k ~= "swap" then return false end
    if not self:ApplySwap(move) then return false end
    self.picked = nil
    self.bad = false
    local c2, r2 = neighbor(move.c, move.r, move.d)
    self.anim = { c = move.c, r = move.r, c2 = c2, r2 = r2 }
    self.seedHit = self:Trigger(move.c, move.r, c2, r2)
    self.touch = { c = move.c, r = move.r, c2 = c2, r2 = r2 }
    self:ShowChain(1)
    enterPhase(self, "swap", T_SWAP)
end
function Game:Click(x, y)
    if self.menu or self.onLadder then return end
    if self.phase ~= "idle" then return end
    local c, r = self:CellAt(x, y)
    if not c then
        if r == "out" then
            if self.hammerOn then
                self.hammerOn = false
            end
            self.picked = nil
            self:Draw()
        end
        return
    end
    if self.hammerOn then
        self:Move{ k = "hit", c = c, r = r }
        return
    end
    if not self:Movable(c, r) then
        self.flash = { c = c, r = r, t = 0.2 }
        ns.Sfx.Play("deny")
        return
    end
    local pick = self.picked
    if not pick then
        self.picked = { c = c, r = r }
        ns.Sfx.Play("pick")
        self:Draw()
        return
    end
    if pick.c == c and pick.r == r then
        self.picked = nil
        self:Draw()
        return
    end
    local dc, dr = c - pick.c, r - pick.r
    if abs(dc) + abs(dr) ~= 1 then
        self.picked = { c = c, r = r }
        self:Draw()
        return
    end
    local ac, ar, d
    if dc == 1 then ac, ar, d = pick.c, pick.r, "r"
    elseif dc == -1 then ac, ar, d = c, r, "r"
    elseif dr == 1 then ac, ar, d = pick.c, pick.r, "u"
    else ac, ar, d = c, r, "u" end
    self.picked = nil
    if self:SwapOk(ac, ar, d) then
        self:Move{ k = "swap", c = ac, r = ar, d = d }
    else
        self.bad = true
        ns.Sfx.Play("deny")
        local c2, r2 = neighbor(ac, ar, d)
        self.anim = { c = ac, r = ar, c2 = c2, r2 = r2 }
        enterPhase(self, "swap", T_BACK)
    end
end
function Game:Update(dt)
    if self.menu or self.onLadder then return end
    self.playT = (self.playT or 0) + dt
    if self.mode == MODE_TIME and not self.timeUp then
        self.t = self.t - dt
        if self.t <= 0 then
            self.t = 0
            self.timeUp = true
        end
    end
    if self.mulT > 0 then
        self.mulT = self.mulT - dt
        if self.mulT <= 0 then
            ui.mul:Hide()
        else
            ui.mul:SetAlpha(self.mulT / T_CHAIN)
        end
    end
    self.gt = (self.gt or 0) + dt
    if self.rainbow and #self.rainbow > 0 then
        local n = #self.tints
        local t = self.gt * 0.55
        local i = floor(t) % n
        local k = t - floor(t)
        local a, b = self.tints[i + 1], self.tints[(i + 1) % n + 1]
        local r = a[1] + (b[1] - a[1]) * k
        local g = a[2] + (b[2] - a[2]) * k
        local bl = a[3] + (b[3] - a[3]) * k
        local lr, lg, lb = lift(r, g, bl)
        for j = 1, #self.rainbow do
            local t = self.rainbow[j]
            t._r, t._g, t._b = lr, lg, lb
        end
    end
    if ui and ui.ringN > 0 then
        local a = 0.72 + 0.28 * (1 + math.sin(self.gt * 2.6)) * 0.5
        for i = 1, ui.ringN do
            local t = ui.rings[i]
            t:SetVertexColor(t._r or 1, t._g or 1, t._b or 1, a)
        end
    end
    if self.popT and self.popT > 0 then
        self.popT = self.popT - dt
        if self.popT <= 0 then
            ui.pop:Hide()
            self.popT = nil
        else
            local k = 1 - self.popT / T_POP
            ui.pop:SetAlpha(1 - k * k)
            ui.pop:ClearAllPoints()
            ui.pop:SetPoint("CENTER", ui.mulF, "BOTTOMLEFT",
                            self.popX, self.popY + k * 26)
        end
    end
    if self.shakeT and self.shakeT > 0 then
        self.shakeT = self.shakeT - dt
        if self.shakeT <= 0 then
            self.shakeT, self.sx, self.sy = 0, 0, 0
        else
            local amp = SHAKE * (self.shakeT / T_SHAKE)
            self.sx = amp * sin(self.shakeT * SHAKE_W)
            self.sy = amp * sin(self.shakeT * SHAKE_W * 1.6)
        end
        reseat(self)
    end
    if ui then
        for i = 1, #ui.goals do
            local row = ui.goals[i]
            if row.pop then
                row.pop = row.pop - dt
                if row.pop <= 0 then
                    row.pop = nil
                    row.cell:SetScale(1)
                else
                    row.cell:SetScale(1 + GOAL_POP * (row.pop / T_GOAL_POP))
                end
            end
        end
    end
    if self.flash then
        self.flash.t = self.flash.t - dt
        local row = self.tile[self.flash.c]
        local f = row and row[self.flash.r]
        if self.flash.t <= 0 then
            if f then f:SetBackdropBorderColor(EDGE[1], EDGE[2], EDGE[3], EDGE[4]) end
            self.flash = nil
        elseif f then
            f:SetBackdropBorderColor(1, 0.25, 0.25, 1)
        end
    end
    if self.phase ~= "idle" then
        self.pt = self.pt + dt
        if self.pt >= self.pdur then
            phaseEnd(self)
        else
            self:Animate(self.pt / self.pdur)
        end
    else
        self:Hover()
    end
    if not self.overSound and self:IsOver() then
        self.overSound = true
        ns.Sfx.Play("over")
    end
end
function Game:Score()
    return self.score
end
function Game:Elapsed()
    return self.playT or 0
end
function Game:IsOver()
    if self.phase ~= "idle" then return false end
    if self.stuck then return true end
    if self.mode == MODE_TIME then return self.timeUp end
    if self.mode == MODE_SHOP then return self.over end
    return self:Left() <= 0
end
function Game:Stop()
    if pool then pool:HideAll() end
    if menu then menu.root:Hide() end
    if ladder then ladder.root:Hide() end
    ns.FX.Stop()
    self:RingsHide()
    if ui then
        for i = 1, 4 do ui.line[i]:Hide() end
        ui.mul:Hide()
        ui.pop:Hide()
        ui.note:Hide()
        ui.root:Hide()
        for i = 1, #ui.goals do
            ui.goals[i].pop, ui.goals[i].was = nil, nil
            ui.goals[i].dressed = nil
            ui.goals[i].cell:SetScale(1)
        end
    end
end
local MINI_FACE = { 0.16, 0.14, 0.12 }
local MINI_A    = { 0.62, 0.12, 0.16 }
local MINI_B    = { 0.16, 0.34, 0.62 }
local MINI_C    = { 0.70, 0.54, 0.12 }
local MINI_MARK = { 1.00, 0.82, 0.00 }
local MINI = {
    {
        cols = 3, rows = 3, cell = 26, gap = 2, back = "plain",
        fill = {
            { c = 2, r = 2, col = MINI_C },
            { c = 2, r = 3, col = MINI_B }, { c = 2, r = 1, col = MINI_B },
            { c = 1, r = 2, col = MINI_B }, { c = 3, r = 2, col = MINI_B },
        },
        arrow = {
            { c1 = 2, r1 = 2, c2 = 2, r2 = 3, col = MINI_MARK },
            { c1 = 2, r1 = 2, c2 = 2, r2 = 1, col = MINI_MARK },
            { c1 = 2, r1 = 2, c2 = 1, r2 = 2, col = MINI_MARK },
            { c1 = 2, r1 = 2, c2 = 3, r2 = 2, col = MINI_MARK },
        },
    },
    {
        cols = 4, rows = 1, cell = 30, gap = 2, back = "plain",
        fill = {
            { c = 1, r = 1, col = MINI_A }, { c = 2, r = 1, col = MINI_A },
            { c = 3, r = 1, col = MINI_A }, { c = 4, r = 1, col = MINI_A },
        },
        ring = { { c = 3, r = 1 } },
    },
    {
        cols = 3, rows = 4, cell = 24, gap = 2, back = "plain",
        fill = {
            { c = 1, r = 2, col = MINI_B }, { c = 1, r = 3, col = MINI_B },
            { c = 2, r = 3, col = MINI_B }, { c = 2, r = 4, col = MINI_C },
            { c = 3, r = 2, col = MINI_B }, { c = 3, r = 3, col = MINI_B },
        },
        arrow = {
            { c1 = 1, r1 = 3, c2 = 1, r2 = 1, col = MINI_MARK },
            { c1 = 2, r1 = 4, c2 = 2, r2 = 1, col = MINI_MARK },
            { c1 = 3, r1 = 3, c2 = 3, r2 = 1, col = MINI_MARK },
        },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_FACE)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpNeighbors(host) paintMini(host, MINI[1]) end
local function helpBorn(host) paintMini(host, MINI[2]) end
local function helpFall(host) paintMini(host, MINI[3]) end
local function shelfIcon(key, fallback)
    local list = ns.Shelves.Get(ID, key)
    if list and list[1] then return ns.IconPath(list[1]) end
    return fallback
end
local function wildIcon()
    return shelfIcon("sp_wild", ns.Icons.Gem(1))
end
ns.RegisterGame{
    id = ID,
    icon = ns.itemSets.gems[1],
    label = "gems.label",
    tip = "gems.tip",
    order = 6,
    duo = "score",
    physics = false,
    look = LOOK,
    opts = {
        { key = "mode", label = "gems.optModeLabel", def = MODE_TIME, options = MODES,
          tip = "gems.optModeTip" },
    },
    record = {
        { key = "score", label = "gems.recScore", by = "max", mark = "token" },
        { key = "time",  label = "gems.recTime",  by = "min", mark = "clock", format = "span" },
    },
    stages = { max = 999 },
    fx = true,
    done = true,
    ownPanel = true,
    New = New,
    controls = {
        { action = "pick", label = "gems.ctlPick", mouse = "LMB", where = "gems.ctlOnGem" },
        { action = "swap", label = "gems.ctlSwap", mouse = "LMB", where = "gems.ctlOnNeighbor" },
        { action = "hit",  label = "gems.ctlHit",  mouse = "LMB" },
    },
    help = function(opts)
        local mode = opts and opts.mode
        local body = {
            ns.T("gems.help1"),
            { icon = ns.Icons.Gem(1),
              t = ns.T("gems.help2T") },
            ns.T("gems.help2Sub"),
            { art = helpNeighbors, h = 90 },
            ns.T("gems.helpNeighborsSub"),
            ns.T("gems.help3"),
            { art = helpBorn, h = 38 },
            ns.T("gems.helpBornSub"),
            { icon = ns.Icons.Gem(4),
              t = ns.T("gems.help4T"),
              sub = ns.T("gems.help4Sub") },
            { icon = wildIcon(),
              t = ns.T("gems.help5T") },
            ns.T("gems.help5Sub"),
            { art = helpFall, h = 110 },
            ns.T("gems.helpFallSub"),
        }
        if mode == MODE_SHOP then
            body[#body + 1] = ns.T("gems.helpShop1")
            body[#body + 1] = { icon = shelfIcon("blk_rock", ns.Icons.Gem(2)),
                                t = ns.T("gems.helpShopRock") }
            body[#body + 1] = { icon = ns.Icons.Gem(3),
                                t = ns.T("gems.helpShopFrame") }
            body[#body + 1] = { icon = shelfIcon("blk_raw", ns.Icons.Gem(5)),
                                t = ns.T("gems.helpShopRaw") }
            body[#body + 1] = { icon = ns.Icons.Item(HAMMER_ITEM),
                                t = ns.T("gems.helpShopHammer") }
        elseif mode == MODE_MOVES then
            body[#body + 1] = ns.T("gems.helpMovesTail")
        else
            body[#body + 1] = ns.T("gems.helpTimeTail")
        end
        body[#body + 1] = ns.T("gems.help6")
        return body
    end,
}
