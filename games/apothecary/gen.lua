local ADDON, ns = ...
ns.Apo = {}
local function topRun(list)
    local n = #list
    if n == 0 then return nil, 0 end
    local col = list[n]
    local k = 1
    while k < n and list[n - k] == col do k = k + 1 end
    return col, k
end
ns.Apo.TopRun = topRun
local function corked(st, i)
    local b = st.bag[i]
    if #b ~= st.cap then return false end
    local _, blk = topRun(b)
    return blk == st.cap
end
ns.Apo.Corked = corked
local function canPour(st, from, to)
    if not from or not to or from == to then return false end
    local a, b = st.bag[from], st.bag[to]
    if not a or not b then return false end
    if #a == 0 then return false end
    if #b >= st.cap then return false end
    if corked(st, from) then return false end
    if #b > 0 and b[#b] ~= a[#a] then return false end
    return true
end
ns.Apo.CanPour = canPour
local function pour(st, from, to)
    local a, b = st.bag[from], st.bag[to]
    local col, blk = topRun(a)
    local free = st.cap - #b
    local m = blk < free and blk or free
    for _ = 1, m do
        a[#a] = nil
        b[#b + 1] = col
    end
    return col, m
end
ns.Apo.Pour = pour
local function solved(st)
    for i = 1, st.n do
        local b = st.bag[i]
        if #b > 0 and not corked(st, i) then return false end
    end
    return true
end
ns.Apo.Solved = solved
local function hasMove(st)
    for i = 1, st.n do
        for j = 1, st.n do
            if canPour(st, i, j) then return true end
        end
    end
    return false
end
ns.Apo.HasMove = hasMove
local function copyBag(bag)
    local out = {}
    for i = 1, #bag do
        local src, dst = bag[i], {}
        for s = 1, #src do dst[s] = src[s] end
        out[i] = dst
    end
    return out
end
ns.Apo.CopyBag = copyBag
local KEY = {}
local function stateKey(st)
    local bag = st.bag
    for i = 1, st.n do
        KEY[i] = table.concat(bag[i], ",")
    end
    for i = st.n + 1, #KEY do KEY[i] = nil end
    table.sort(KEY)
    return table.concat(KEY, "|")
end
local function genMoves(st, L)
    local nm = 0
    for a = 1, st.n do
        local A = st.bag[a]
        local na = #A
        if na > 0 then
            local _, blk = topRun(A)
            for b = 1, st.n do
                if canPour(st, a, b) then
                    local B = st.bag[b]
                    local nb = #B
                    if not (nb == 0 and blk == na) then
                        local free = st.cap - nb
                        local m = blk < free and blk or free
                        local rank = (nb == 0) and 1 or 2
                        if nb + m == st.cap then rank = 3 end
                        local p = nm
                        while p > 0 and L.rank[p] < rank do
                            L.from[p + 1], L.to[p + 1], L.m[p + 1], L.rank[p + 1] =
                                L.from[p], L.to[p], L.m[p], L.rank[p]
                            p = p - 1
                        end
                        L.from[p + 1], L.to[p + 1], L.m[p + 1], L.rank[p + 1] = a, b, m, rank
                        nm = nm + 1
                    end
                end
            end
        end
    end
    L.nm = nm
    L.i = 0
end
local function apply(st, from, to, m)
    local A, B = st.bag[from], st.bag[to]
    local col = A[#A]
    for _ = 1, m do
        A[#A] = nil
        B[#B + 1] = col
    end
end
local function unapply(st, from, to, m)
    local A, B = st.bag[from], st.bag[to]
    local col = B[#B]
    for _ = 1, m do
        B[#B] = nil
        A[#A + 1] = col
    end
end
local stack = {}
local function levelAt(d)
    local L = stack[d]
    if not L then
        L = { from = {}, to = {}, m = {}, rank = {}, nm = 0, i = 0 }
        stack[d] = L
    end
    return L
end
function ns.Apo.Solvable(bag, n, cap, budget)
    local st = { bag = copyBag(bag), n = n, cap = cap }
    if solved(st) then return true, 0 end
    local seen = { [stateKey(st)] = true }
    local nodes = 1
    local d = 1
    genMoves(st, levelAt(1))
    while true do
        local L = stack[d]
        if L.i < L.nm then
            L.i = L.i + 1
            local i = L.i
            local f, t, m = L.from[i], L.to[i], L.m[i]
            apply(st, f, t, m)
            local k = stateKey(st)
            if seen[k] then
                unapply(st, f, t, m)
            else
                nodes = nodes + 1
                if solved(st) then return true, nodes end
                if nodes >= budget then return false, nodes end
                seen[k] = true
                d = d + 1
                local N = levelAt(d)
                N.mf, N.mt, N.mm = f, t, m
                genMoves(st, N)
            end
        else
            if d == 1 then return false, nodes end
            local N = stack[d]
            unapply(st, N.mf, N.mt, N.mm)
            d = d - 1
        end
    end
end
function ns.Apo.Deal(rng, colors, cap, empty)
    local pool = {}
    for c = 1, colors do
        for _ = 1, cap do pool[#pool + 1] = c end
    end
    rng:Shuffle(pool)
    local bag = {}
    for i = 1, colors do
        local b = {}
        for s = 1, cap do b[s] = pool[(i - 1) * cap + s] end
        bag[i] = b
    end
    for i = colors + 1, colors + empty do bag[i] = {} end
    return bag
end
local BACK_SALT = 104729
local BACK_FAIL = 8
local BACK_CAP  = 400
local BS, AS = {}, {}
local function backStep(st, r)
    local cap = st.cap
    local nb = 0
    for i = 1, st.n do
        if #st.bag[i] > 0 then nb = nb + 1; BS[nb] = i end
    end
    if nb == 0 then return false end
    for k = nb, 2, -1 do
        local j = r:Int(k)
        BS[k], BS[j] = BS[j], BS[k]
    end
    for k = 1, nb do
        local b = BS[k]
        local B = st.bag[b]
        local c, run = topRun(B)
        local mMax = (#B == run) and run or (run - 1)
        if mMax >= 1 then
            local m = r:Int(mMax)
            local na = 0
            for a = 1, st.n do
                if a ~= b then
                    local A = st.bag[a]
                    local nA = #A
                    if nA + m <= cap and not (nA > 0 and A[nA] == c)
                       and not (nA == 0 and m == cap) then
                        na = na + 1
                        AS[na] = a
                    end
                end
            end
            if na > 0 then
                local A = st.bag[AS[r:Int(na)]]
                for _ = 1, m do
                    B[#B] = nil
                    A[#A + 1] = c
                end
                return true
            end
        end
    end
    return false
end
function ns.Apo.Walk(r, colors, cap, empty)
    local n = colors + empty
    local bag = {}
    for i = 1, colors do
        local b = {}
        for s = 1, cap do b[s] = i end
        bag[i] = b
    end
    for i = colors + 1, n do bag[i] = {} end
    local st = { bag = bag, n = n, cap = cap }
    local fail = 0
    for _ = 1, BACK_CAP do
        if fail >= BACK_FAIL then break end
        if backStep(st, r) then fail = 0 else fail = fail + 1 end
    end
    if solved(st) then
        local from, to
        for i = 1, n do
            local len = #bag[i]
            if len > 0 and not from then from = i end
            if len == 0 and not to then to = i end
        end
        if from and to then
            local A, B = bag[from], bag[to]
            B[1] = A[#A]
            A[#A] = nil
        end
    end
    return bag
end
ns.Apo.BUDGET = 20000
local TRIES = 20
ns.Apo.TRIES = TRIES
function ns.Apo.Build(rng, colors, cap, empty)
    local seed0 = rng:State()
    local nodes = 0
    for try = 1, TRIES do
        local bag = ns.Apo.Deal(rng, colors, cap, empty)
        local st = { bag = bag, n = colors + empty, cap = cap }
        if not solved(st) then
            local ok, cost = ns.Apo.Solvable(bag, colors + empty, cap, ns.Apo.BUDGET)
            nodes = nodes + cost
            if ok then return bag, try, nodes end
        end
    end
    return ns.Apo.Walk(ns.RNG.New(seed0 + BACK_SALT), colors, cap, empty),
           TRIES + 1, nodes
end
