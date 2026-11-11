local ADDON, ns = ...
local R = {}
ns.seabattle = R
local floor = math.floor
local N = 10
R.N = N
R.CELLS = N * N
R.FLEET = { 4, 3, 3, 2, 2, 2, 1, 1, 1, 1 }
R.SIZES = { 4, 3, 2, 1 }
R.COUNT = { [4] = 1, [3] = 2, [2] = 3, [1] = 4 }
R.NONE, R.MISS, R.HIT, R.SUNK, R.SHUT = 0, 1, 2, 3, 4
R.LEVELS = { "nov", "cap", "adm" }
R.ADM_NEAR = 0.9
R.TRY_CAP = 6000
local LET = "abcdefghij"
local DIRS2 = { "h", "v" }
local DIRS1 = { "h" }
local function cr(i)
    return (i - 1) % N + 1, floor((i - 1) / N) + 1
end
local function idx(c, r)
    return (r - 1) * N + c
end
local function inside(c, r)
    return c >= 1 and c <= N and r >= 1 and r <= N
end
R.cr, R.idx, R.inside = cr, idx, inside
function R.fits(ship)
    local c, r = cr(ship.s)
    if ship.d == "v" then return r + ship.n - 1 <= N end
    return c + ship.n - 1 <= N
end
function R.cells(ship, out)
    out = out or {}
    local c, r = cr(ship.s)
    for k = 0, ship.n - 1 do
        local cc, rr = c, r
        if ship.d == "v" then rr = r + k else cc = c + k end
        if not inside(cc, rr) then return nil end
        out[#out + 1] = idx(cc, rr)
    end
    return out
end
local function around(i, fn)
    local c, r = cr(i)
    for dc = -1, 1 do
        for dr = -1, 1 do
            local cc, rr = c + dc, r + dr
            if inside(cc, rr) then fn(idx(cc, rr), dc, dr) end
        end
    end
end
R.around = around
function R.blockMap(fleet, skip, map)
    map = map or {}
    for i = 1, R.CELLS do map[i] = false end
    for k = 1, #fleet do
        if k ~= skip then
            local cs = R.cells(fleet[k])
            if cs then
                for _, i in ipairs(cs) do
                    around(i, function(j) map[j] = true end)
                end
            end
        end
    end
    return map
end
function R.canPlace(fleet, ship, skip, map)
    if not R.fits(ship) then return false end
    map = map or R.blockMap(fleet, skip)
    local cs = R.cells(ship)
    if not cs then return false end
    for _, i in ipairs(cs) do
        if map[i] then return false end
    end
    return true
end
function R.shipOk(sh)
    if type(sh) ~= "table" then return false end
    if type(sh.n) ~= "number" or sh.n < 1 or sh.n > 4 or sh.n ~= floor(sh.n) then return false end
    if sh.d ~= "h" and sh.d ~= "v" then return false end
    if type(sh.s) ~= "number" or sh.s < 1 or sh.s > R.CELLS or sh.s ~= floor(sh.s) then return false end
    return R.fits(sh)
end
function R.fleetLegal(fleet)
    if type(fleet) ~= "table" or #fleet ~= 10 then return false end
    local cnt = { 0, 0, 0, 0 }
    for k = 1, 10 do
        local sh = fleet[k]
        if not R.shipOk(sh) then return false end
        cnt[sh.n] = cnt[sh.n] + 1
        if not R.canPlace(fleet, sh, k) then return false end
    end
    return cnt[4] == 1 and cnt[3] == 2 and cnt[2] == 3 and cnt[1] == 4
end
function R.shipAt(fleet, i)
    for k = 1, #fleet do
        local cs = R.cells(fleet[k])
        if cs then
            for _, j in ipairs(cs) do
                if j == i then return k end
            end
        end
    end
    return nil
end
local STATIC = {
    { s = 1, d = "h", n = 4 }, { s = 21, d = "h", n = 3 }, { s = 25, d = "h", n = 3 },
    { s = 41, d = "h", n = 2 }, { s = 44, d = "h", n = 2 }, { s = 47, d = "h", n = 2 },
    { s = 61, d = "h", n = 1 }, { s = 63, d = "h", n = 1 }, { s = 65, d = "h", n = 1 },
    { s = 67, d = "h", n = 1 },
}
local function tryGenerate(rng, fixed)
    local have = { 0, 0, 0, 0 }
    local fleet, need = {}, {}
    if fixed then
        for _, sh in ipairs(fixed) do
            fleet[#fleet + 1] = { s = sh.s, d = sh.d, n = sh.n }
            have[sh.n] = have[sh.n] + 1
        end
    end
    for _, n in ipairs(R.FLEET) do
        if have[n] > 0 then have[n] = have[n] - 1 else need[#need + 1] = n end
    end
    local tries = 0
    local function place(k)
        if k > #need then return true end
        tries = tries + 1
        if tries > R.TRY_CAP then return false end
        local n = need[k]
        local map = R.blockMap(fleet)
        local cands = {}
        for i = 1, R.CELLS do
            for _, d in ipairs(n == 1 and DIRS1 or DIRS2) do
                local sh = { s = i, d = d, n = n }
                if R.canPlace(fleet, sh, nil, map) then cands[#cands + 1] = sh end
            end
        end
        rng:Shuffle(cands)
        for _, sh in ipairs(cands) do
            fleet[#fleet + 1] = sh
            if place(k + 1) then return true end
            fleet[#fleet] = nil
            if tries > R.TRY_CAP then return false end
        end
        return false
    end
    if place(1) then return fleet end
    return nil
end
function R.generate(rng, fixed)
    if fixed and #fixed > 0 then
        local f = tryGenerate(rng, fixed)
        if f then return f end
    end
    for _ = 1, 4 do
        local f = tryGenerate(rng, nil)
        if f then return f end
    end
    local f = {}
    for k, sh in ipairs(STATIC) do f[k] = { s = sh.s, d = sh.d, n = sh.n } end
    return f
end
function R.encode(fleet)
    local list = {}
    for k = 1, #fleet do list[k] = fleet[k] end
    table.sort(list, function(a, b)
        if a.n ~= b.n then return a.n > b.n end
        return a.s < b.s
    end)
    local out = {}
    for k = 1, #list do
        local sh = list[k]
        local c, r = cr(sh.s)
        out[#out + 1] = LET:sub(c, c) .. (r - 1) .. (sh.n == 1 and "h" or sh.d)
    end
    return table.concat(out)
end
function R.decode(str)
    if type(str) ~= "string" or #str ~= 30 then return nil end
    local fleet = {}
    for k = 1, 10 do
        local a = str:sub(3 * k - 2, 3 * k)
        local c = LET:find(a:sub(1, 1), 1, true)
        local r = tonumber(a:sub(2, 2))
        local d = a:sub(3, 3)
        if not c or not r or (d ~= "h" and d ~= "v") then return nil end
        local n = R.FLEET[k]
        fleet[k] = { s = idx(c, r + 1), d = (n == 1) and "h" or d, n = n }
    end
    return fleet
end
function R.lineThrough(marks, i)
    local c, r = cr(i)
    local horiz, vert = {}, {}
    local function run(dc, dr, out)
        local cc, rr = c + dc, r + dr
        while inside(cc, rr) and marks[idx(cc, rr)] == R.HIT do
            out[#out + 1] = idx(cc, rr)
            cc, rr = cc + dc, rr + dr
        end
    end
    run(-1, 0, horiz)
    run(1, 0, horiz)
    run(0, -1, vert)
    run(0, 1, vert)
    if #horiz > 0 and #vert > 0 then return nil end
    local list = { i }
    local src = (#horiz > 0) and horiz or vert
    for _, j in ipairs(src) do list[#list + 1] = j end
    table.sort(list)
    return list, (#vert > 0) and "v" or "h"
end
function R.shutDiag(marks, i)
    around(i, function(j, dc, dr)
        if dc ~= 0 and dr ~= 0 and marks[j] == R.NONE then marks[j] = R.SHUT end
    end)
end
function R.shutAround(marks, cells)
    for _, i in ipairs(cells) do
        around(i, function(j)
            if marks[j] == R.NONE then marks[j] = R.SHUT end
        end)
    end
end
function R.targets(marks)
    local out = {}
    for i = 1, R.CELLS do
        if marks[i] == R.NONE then out[#out + 1] = i end
    end
    return out
end
function R.hitCells(marks)
    local out = {}
    for i = 1, R.CELLS do
        if marks[i] == R.HIT then out[#out + 1] = i end
    end
    return out
end
function R.answer(fleet, marks, i)
    local k = R.shipAt(fleet, i)
    if not k then return "miss", nil end
    local sh = fleet[k]
    local cs = R.cells(sh)
    for _, j in ipairs(cs) do
        if j ~= i and marks[j] ~= R.HIT then return "hit", nil end
    end
    return "kill", sh
end
function R.verify(fleet, marks, sunk)
    local deck = {}
    for _, sh in ipairs(fleet) do
        local cs = R.cells(sh)
        if cs then
            for _, j in ipairs(cs) do deck[j] = true end
        end
    end
    local odd, seen = {}, {}
    local function mark(i)
        if not seen[i] then
            seen[i] = true
            odd[#odd + 1] = i
        end
    end
    for i = 1, R.CELLS do
        local m = marks[i]
        if m == R.MISS and deck[i] then mark(i) end
        if (m == R.HIT or m == R.SUNK) and not deck[i] then mark(i) end
    end
    for _, sh in ipairs(fleet) do
        local cs = R.cells(sh)
        local whole = cs ~= nil
        for _, j in ipairs(cs or {}) do
            if marks[j] ~= R.HIT then whole = false break end
        end
        if whole then for _, j in ipairs(cs) do mark(j) end end
    end
    for _, sk in ipairs(sunk or {}) do
        local found = false
        for _, sh in ipairs(fleet) do
            if sh.s == sk.s and sh.d == sk.d and sh.n == sk.n then found = true break end
        end
        if not found then
            local cs = R.cells(sk)
            if cs then for _, j in ipairs(cs) do mark(j) end end
        end
    end
    return odd
end
local function density(marks, left, hits)
    local w = {}
    for i = 1, R.CELLS do w[i] = 0 end
    local hitSet = {}
    for _, i in ipairs(hits) do hitSet[i] = true end
    for n = 1, 4 do
        local cnt = left[n] or 0
        if cnt > 0 and n >= #hits then
            for s = 1, R.CELLS do
                for _, d in ipairs(n == 1 and DIRS1 or DIRS2) do
                    local sh = { s = s, d = d, n = n }
                    if R.fits(sh) then
                        local cs = R.cells(sh)
                        local ok, covered = true, 0
                        for _, j in ipairs(cs) do
                            if hitSet[j] then
                                covered = covered + 1
                            elseif marks[j] ~= R.NONE then
                                ok = false
                                break
                            end
                        end
                        if ok and covered == #hits then
                            for _, j in ipairs(cs) do
                                if not hitSet[j] then w[j] = w[j] + cnt end
                            end
                        end
                    end
                end
            end
        end
    end
    return w
end
local function neighbours(marks, hits)
    local cand, seen = {}, {}
    for _, i in ipairs(hits) do
        around(i, function(j, dc, dr)
            if (dc == 0 or dr == 0) and marks[j] == R.NONE and not seen[j] then
                seen[j] = true
                cand[#cand + 1] = j
            end
        end)
    end
    return cand
end
local function lineEnds(marks, hits)
    table.sort(hits)
    local c1, r1 = cr(hits[1])
    local c2, r2 = cr(hits[#hits])
    local cand = {}
    local function add(c, r)
        if inside(c, r) and marks[idx(c, r)] == R.NONE then cand[#cand + 1] = idx(c, r) end
    end
    if r1 == r2 then
        add(c1 - 1, r1)
        add(c2 + 1, r1)
    else
        add(c1, r1 - 1)
        add(c1, r2 + 1)
    end
    return cand
end
function R.pick(level, marks, left, rng, parity)
    local all = R.targets(marks)
    if #all == 0 then return nil end
    local hits = R.hitCells(marks)
    if level == "adm" then
        local w = density(marks, left, hits)
        local best = 0
        for _, i in ipairs(all) do
            if w[i] > best then best = w[i] end
        end
        if best == 0 then return all[rng:Int(#all)] end
        local thr = (rng:Int(10) == 1) and best * R.ADM_NEAR or best
        local pool = {}
        for _, i in ipairs(all) do
            if w[i] >= thr then pool[#pool + 1] = i end
        end
        return pool[rng:Int(#pool)]
    end
    if #hits > 0 then
        local cand
        if level == "cap" and #hits >= 2 then
            cand = lineEnds(marks, hits)
        else
            cand = neighbours(marks, hits)
        end
        if #cand > 0 then return cand[rng:Int(#cand)] end
    end
    if level == "cap" and rng:Int(5) ~= 1 then
        local pool = {}
        for _, i in ipairs(all) do
            local c, r = cr(i)
            if (c + r) % 2 == parity then pool[#pool + 1] = i end
        end
        if #pool > 0 then return pool[rng:Int(#pool)] end
    end
    return all[rng:Int(#all)]
end
function R.newState(seed, duo, side)
    local rng = ns.RNG.New(seed)
    local st = {
        phase = "setup", ready = { false, false }, shooter = 1, shot = nil,
        marks = { {}, {} }, sunk = { {}, {} }, left = { {}, {} }, last = {},
        fac = {}, sky = 1, me = 1, fleet = {}, winner = nil, resigned = false,
        broke = nil, odd = {}, lastSunk = nil, ans = nil, auto = false,
        shots = { 0, 0 }, oddNote = nil,
    }
    for s = 1, 2 do
        for i = 1, R.CELLS do st.marks[s][i] = R.NONE end
        for n = 1, 4 do st.left[s][n] = R.COUNT[n] end
    end
    local f1 = rng:Int(2)
    st.fac[1], st.fac[2] = f1, 3 - f1
    local roll = rng:Int(2)
    st.me = duo and (side or 1) or roll
    st.sky = rng:Int(3)
    return st
end
function R.turn(st)
    if st.phase == "setup" then return st.ready[1] and 2 or 1 end
    if st.phase == "aim" then return st.shooter end
    if st.phase == "answer" then return 3 - st.shooter end
    return st.winner or 1
end
function R.leftTotal(st, side)
    local t = 0
    for n = 1, 4 do t = t + st.left[side][n] end
    return t
end
local function applyReady(st, move, ctx)
    if st.phase ~= "setup" then return false end
    local side = R.turn(st)
    if ctx.duo then
        if move.f ~= nil then return false end
    elseif side == ctx.bot then
        st.fleet[side] = ctx.botFleet()
    else
        local fl = R.decode(move.f)
        if not fl or not R.fleetLegal(fl) then return false end
        st.fleet[side] = fl
    end
    st.ready[side] = true
    if st.ready[1] and st.ready[2] then
        st.phase = "aim"
        st.shooter = 1
    end
    return true
end
local function afterAnswer(st)
    local def = 3 - st.shooter
    if R.leftTotal(st, def) == 0 then
        st.phase = "reveal"
        st.winner = st.shooter
        return true
    end
    st.phase = "aim"
    if #R.targets(st.marks[3 - st.shooter]) == 0 then
        st.broke = "targets"
        st.phase = "over"
    end
    return true
end
local function applyAnswer(st, move)
    if st.phase ~= "answer" or not st.shot then return false end
    local r = move.r
    if r ~= "miss" and r ~= "hit" and r ~= "kill" then return false end
    local def = 3 - st.shooter
    local marks = st.marks[def]
    local i = st.shot
    if marks[i] ~= R.NONE then return false end
    if r == "miss" then
        marks[i] = R.MISS
        st.last[def] = i
        st.shot = nil
        st.ans = "miss"
        st.shooter = def
        return afterAnswer(st)
    end
    local line = R.lineThrough(marks, i)
    if not line or #line > 4 then return false end
    if r == "hit" then
        marks[i] = R.HIT
        R.shutDiag(marks, i)
        st.last[def] = i
        st.shot = nil
        st.ans = "hit"
        return afterAnswer(st)
    end
    local sh = { s = move.s, d = move.d, n = move.n }
    if not R.shipOk(sh) or sh.n ~= #line then return false end
    if sh.n == 1 then sh.d = "h" end
    local cs = R.cells(sh)
    for k = 1, #line do
        if cs[k] ~= line[k] then return false end
    end
    if st.left[def][sh.n] <= 0 then return false end
    for _, j in ipairs(cs) do marks[j] = R.SUNK end
    R.shutAround(marks, cs)
    st.sunk[def][#st.sunk[def] + 1] = sh
    st.left[def][sh.n] = st.left[def][sh.n] - 1
    st.lastSunk = { side = def, n = sh.n }
    st.last[def] = i
    st.shot = nil
    st.ans = "kill"
    return afterAnswer(st)
end
local function applyFleet(st, move)
    if st.phase ~= "reveal" or not st.winner then return false end
    local win, lose = st.winner, 3 - st.winner
    local fl = R.decode(move.f)
    if not fl or not R.fleetLegal(fl) then
        st.oddNote = "norev"
        st.odd[win] = {}
    else
        st.fleet[win] = fl
        local odd = R.verify(fl, st.marks[win], st.sunk[win])
        if #odd > 0 then
            st.odd[win] = odd
            st.oddNote = "odd"
        end
    end
    if not st.resigned and R.leftTotal(st, lose) == 0 then
        local lf = st.sunk[lose]
        local odd
        if R.fleetLegal(lf) then
            odd = R.verify(lf, st.marks[lose], nil)
        else
            odd = {}
            for _, sh in ipairs(lf) do
                local cs = R.cells(sh)
                if cs then for _, j in ipairs(cs) do odd[#odd + 1] = j end end
            end
        end
        if #odd > 0 then
            st.odd[lose] = odd
            st.oddNote = st.oddNote or "odd"
        end
        st.fleet[lose] = st.fleet[lose] or lf
    end
    st.phase = "over"
    return true
end
function R.apply(st, move, ctx)
    if type(move) ~= "table" or type(move.k) ~= "string" then return false end
    if st.phase == "over" then return false end
    local k = move.k
    if k == "ready" then return applyReady(st, move, ctx) end
    if k == "shot" then
        if st.phase ~= "aim" then return false end
        local i = move.i
        if type(i) ~= "number" or i < 1 or i > R.CELLS or i ~= floor(i) then return false end
        if st.marks[3 - st.shooter][i] ~= R.NONE then return false end
        st.shot = i
        st.auto = (move.a == 1)
        st.shots[st.shooter] = st.shots[st.shooter] + 1
        st.phase = "answer"
        return true
    end
    if k == "ans" then return applyAnswer(st, move) end
    if k == "resign" then
        if st.phase ~= "aim" and st.phase ~= "answer" then return false end
        local side = R.turn(st)
        st.winner = 3 - side
        st.resigned = true
        st.shot = nil
        st.phase = "reveal"
        return true
    end
    if k == "fleet" then return applyFleet(st, move) end
    return false
end
