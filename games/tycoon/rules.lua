local ADDON, ns = ...
local B = ns.TycoonBoards
local R = {}
ns.Tycoon = R
local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
local CELLS, PROPS, PIDX, GROUPS = B.cells, B.props, B.pidx, B.groups
R.PHASES = { "pre", "buy", "auction", "debt", "trade", "lien", "post", "over" }
local PH = {}
for i, p in ipairs(R.PHASES) do PH[p] = i - 1 end
R.PH = PH
R.EVENTS = { "none", "roll", "move", "go", "buy", "rent", "tax", "card", "jail", "bail", "freecard", "stay",
    "unjail", "forsale", "auction", "bid", "pass", "won", "nobid", "up", "down", "mort", "lift", "offer",
    "yes", "no", "lien", "debt", "bankrupt", "quit", "turn", "over", "pay", "get", "repairs", "each",
    "birthday", "set", "hotel", "setup" }
local EV = {}
for i, e in ipairs(R.EVENTS) do EV[e] = i - 1 end
R.EV = EV
R.TIME = { pre = 60, buy = 60, auction = 30, debt = 60, trade = 60, lien = 30, post = 60 }
R.CFG = { gold = 1500, turn = 60, auc = 30, trade = 60, fin = "last" }
R.CFG_LIST = { gold = { 1000, 1500, 2000, 2500 }, turn = { 30, 60, 90, 120 }, auc = { 15, 30, 45 }, trade = { 30, 60, 90 },
               fin = { "last", "t60", "t90", "t120", "cap" } }
R.CAP_GOAL = 10000
function R.Cfg(c)
    local out = {}
    for k, d in pairs(R.CFG) do
        local v = type(c) == "table" and c[k] or nil
        if k ~= "fin" then v = tonumber(v) end
        local ok = false
        for _, x in ipairs(R.CFG_LIST[k]) do if x == v then ok = true end end
        out[k] = ok and v or d
    end
    return out
end
function R.TimeOf(c, ph)
    if type(c) == "table" and c.n then c = c.cfg end
    c = c or R.CFG
    if ph == "auction" or ph == "lien" then return c.auc or 30 end
    if ph == "trade" then return c.trade or 60 end
    if R.TIME[ph] then return c.turn or 60 end
    return nil
end
function R.TimeLimit(S)
    local f = (S.cfg or R.CFG).fin
    local m = type(f) == "string" and tonumber(f:match("^t(%d+)$"))
    return m and m * 60 or nil
end
local function ev(S, k, s, c, v)
    local e = { k = k, s = s or 0, c = c or 0, v = v or 0 }
    S.ev = e
    local log = S.log
    if log then log[#log + 1] = e end
end
local function rng(S)
    return ns.RNG.Restore(S.rng)
end
local function roll(S)
    local r = rng(S)
    local d1, d2 = r:Int(6), r:Int(6)
    S.rng = r:State()
    return d1, d2
end
function R.Interest(c)
    return ceil(CELLS[c].mort / 10)
end
function R.LiftCost(c)
    return CELLS[c].mort + R.Interest(c)
end
local function groupFull(S, s, g)
    for _, c in ipairs(GROUPS[g]) do
        if S.own[c] ~= s then return false end
    end
    return true
end
R.GroupFull = groupFull
local function groupBuilt(S, g)
    for _, c in ipairs(GROUPS[g]) do
        if S.lv[c] > 0 then return true end
    end
    return false
end
R.GroupBuilt = groupBuilt
local function groupMort(S, g)
    for _, c in ipairs(GROUPS[g]) do
        if S.mort[c] then return true end
    end
    return false
end
local function groupMinMax(S, g)
    local lo, hi = 9, -1
    for _, c in ipairs(GROUPS[g]) do
        lo, hi = min(lo, S.lv[c]), max(hi, S.lv[c])
    end
    return lo, hi
end
function R.Houses(S)
    local n = 0
    for _, c in ipairs(PROPS) do
        local l = S.lv[c]
        if l >= 1 and l <= 4 then n = n + l end
    end
    return B.HOUSES - n
end
function R.Hotels(S)
    local n = 0
    for _, c in ipairs(PROPS) do
        if S.lv[c] == 5 then n = n + 1 end
    end
    return B.HOTELS - n
end
local function countKind(S, s, t)
    local n = 0
    for _, c in ipairs(PROPS) do
        if S.own[c] == s and CELLS[c].t == t then n = n + 1 end
    end
    return n
end
R.CountKind = countKind
function R.Rent(S, c, o)
    local cell = CELLS[c]
    local owner = S.own[c]
    if owner == 0 or S.mort[c] then return 0 end
    if cell.t == "prop" then
        if S.lv[c] > 0 then return cell.rent[S.lv[c] + 1] end
        return cell.rent[1] * (groupFull(S, owner, cell.g) and 2 or 1)
    end
    if cell.t == "rail" then
        local k = countKind(S, owner, "rail")
        return 25 * 2 ^ (k - 1) * ((o and o.rentMul) or 1)
    end
    local k = countKind(S, owner, "util")
    local sum = S.dice[1] + S.dice[2]
    if o and o.utilRoll then return sum * 10 end
    return sum * (k == 2 and 10 or 4)
end
function R.Capital(S, s)
    local v = S.cash[s]
    for _, c in ipairs(PROPS) do
        if S.own[c] == s then
            local cell = CELLS[c]
            v = v + (S.mort[c] and floor(cell.price / 2) or cell.price)
            if S.lv[c] > 0 then v = v + S.lv[c] * cell.house end
        end
    end
    return v
end
local function worth(S, s)
    local v = S.cash[s]
    for _, c in ipairs(PROPS) do
        if S.own[c] == s then
            local cell = CELLS[c]
            if S.lv[c] > 0 then v = v + floor(S.lv[c] * cell.house / 2) end
            if not S.mort[c] then v = v + cell.mort end
        end
    end
    return v
end
R.Worth = worth
local ALPHA = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-"
local AIDX = {}
for i = 1, 64 do AIDX[ALPHA:sub(i, i)] = i - 1 end
local function enc(n, w)
    n = floor(tonumber(n) or 0)
    if n < 0 then n = 0 end
    local out = {}
    for i = w, 1, -1 do
        out[i] = ALPHA:sub(n % 64 + 1, n % 64 + 1)
        n = floor(n / 64)
    end
    return table.concat(out)
end
local function dec(s, at, w)
    local n = 0
    for i = at, at + w - 1 do
        local d = AIDX[s:sub(i, i)]
        if not d then return nil end
        n = n * 64 + d
    end
    return n
end
function R.MaskOf(list)
    local bits = 0
    for _, c in ipairs(list) do
        local i = PIDX[c]
        if i then bits = bits + 2 ^ (i - 1) end
    end
    return enc(bits, 5)
end
function R.MaskList(mask)
    local out = {}
    local bits = type(mask) == "string" and #mask == 5 and dec(mask, 1, 5) or 0
    for i = 1, 28 do
        if floor(bits / 2 ^ (i - 1)) % 2 == 1 then out[#out + 1] = PROPS[i] end
    end
    return out
end
local function maskOk(mask)
    return mask == nil or mask == "" or (type(mask) == "string" and #mask == 5 and dec(mask, 1, 5) ~= nil)
end
local function cardsOk(j)
    return j == nil or j == "" or j == "c" or j == "t" or j == "ct"
end
local function hasCards(have, want)
    if not want or want == "" then return true end
    for i = 1, #want do
        if not have:find(want:sub(i, i), 1, true) then return false end
    end
    return true
end
local function takeCards(have, take)
    local out = have
    for i = 1, #take do out = out:gsub(take:sub(i, i), "", 1) end
    return out
end
local function addCards(have, add)
    local out = have .. add
    if out:find("t") and out:find("c") then return "ct" end
    return out
end
local function nextAlive(S, s)
    for k = 1, S.n do
        local q = (s + k - 1) % S.n + 1
        if S.alive[q] then return q end
    end
    return nil
end
R.NextAlive = nextAlive
local function debtor(S)
    local d = S.debts[1]
    return d and d.from or nil
end
function R.Debtor(S) return debtor(S) end
function R.Deal(seed, n, board, cfg)
    local r = ns.RNG.New(seed)
    local S = {
        board = B.INDEX[board] and board or "azeroth", n = n, token = {}, cash = {}, pos = {}, jail = {},
        free = {}, alive = {}, human = {}, out = {}, own = {}, lv = {}, mort = {},
        deck = { c = {}, t = {} }, turn = 1, phase = "pre", rolled = false, dbl = 0, dice = { 0, 0 },
        offers = 0, debts = {}, liens = {}, flow = "pre", over = false, seq = 0, again = false,
        bno = {}, cfg = R.Cfg(cfg), played = 0,
    }
    for i = 1, 16 do S.deck.c[i], S.deck.t[i] = i, i end
    r:Shuffle(S.deck.c)
    r:Shuffle(S.deck.t)
    S.turn = r:Int(n)
    S.rng = r:State()
    for s = 1, n do
        S.token[s], S.cash[s], S.pos[s], S.jail[s], S.free[s], S.alive[s], S.human[s] = s, S.cfg.gold, 0, 0, "", true, false
        S.bno[s] = ""
    end
    for _, c in ipairs(PROPS) do S.own[c], S.lv[c], S.mort[c] = 0, 0, false end
    S.ev = { k = "none", s = 0, c = 0, v = 0 }
    return S
end
local function pay(S, s, sum)
    S.cash[s] = S.cash[s] + sum
end
local function charge(S, from, to, sum)
    if sum <= 0 then return end
    if S.cash[from] >= sum then
        S.cash[from] = S.cash[from] - sum
        if to > 0 then S.cash[to] = S.cash[to] + sum end
    else
        S.debts[#S.debts + 1] = { from = from, to = to, sum = sum, offers = 0 }
        ev(S, "debt", from, to, sum)
    end
end
local function acquire(S, s, c)
    S.own[c] = s
    local g = CELLS[c].g
    if g <= 8 and groupFull(S, s, g) then ev(S, "set", s, c, g) end
end
local function toJail(S, s)
    S.pos[s] = 10
    S.jail[s] = 1
    S.again = false
    ev(S, "jail", s, 10)
end
local land
local function moveTo(S, s, c, passGo)
    if passGo and c <= S.pos[s] then
        pay(S, s, 200)
        ev(S, "go", s, 0, 200)
    end
    S.pos[s] = c
    ev(S, "move", s, c)
end
local function nearest(S, s, list)
    for _, c in ipairs(list) do
        if c > S.pos[s] then return c end
    end
    return list[1]
end
local function repairs(S, s, house, hotel)
    local sum = 0
    for _, c in ipairs(PROPS) do
        if S.own[c] == s then
            if S.lv[c] == 5 then sum = sum + hotel
            elseif S.lv[c] > 0 then sum = sum + S.lv[c] * house end
        end
    end
    ev(S, "repairs", s, 0, sum)
    charge(S, s, 0, sum)
end
local function eachOther(S, s, sum, collect)
    for k = 1, S.n - 1 do
        local q = (s + k - 1) % S.n + 1
        if S.alive[q] then
            if collect then charge(S, q, s, sum) else charge(S, s, q, sum) end
        end
    end
end
local function card(S, s, d)
    local deck = S.deck[d]
    local id = table.remove(deck, 1)
    if not id then return end
    local keep = (d == "c" and id == 9) or (d == "t" and id == 5)
    if keep then
        S.free[s] = addCards(S.free[s], d)
    else
        deck[#deck + 1] = id
    end
    ev(S, "card", s, id + (d == "t" and 16 or 0))
    if d == "c" then
        if id == 1 then moveTo(S, s, 39, true) land(S, s)
        elseif id == 2 then moveTo(S, s, 0, true) land(S, s)
        elseif id == 3 then moveTo(S, s, 24, true) land(S, s)
        elseif id == 4 then moveTo(S, s, 11, true) land(S, s)
        elseif id == 5 or id == 6 then moveTo(S, s, nearest(S, s, B.RAILS), true) land(S, s, { rentMul = 2 })
        elseif id == 7 then moveTo(S, s, nearest(S, s, B.UTILS), true) land(S, s, { utilRoll = true })
        elseif id == 8 then pay(S, s, 50) ev(S, "get", s, 0, 50)
        elseif id == 9 then ev(S, "freecard", s)
        elseif id == 10 then S.pos[s] = (S.pos[s] - 3) % 40 ev(S, "move", s, S.pos[s]) land(S, s)
        elseif id == 11 then toJail(S, s)
        elseif id == 12 then repairs(S, s, 25, 100)
        elseif id == 13 then ev(S, "pay", s, 0, 15) charge(S, s, 0, 15)
        elseif id == 14 then moveTo(S, s, 5, true) land(S, s)
        elseif id == 15 then ev(S, "each", s, 0, 50) eachOther(S, s, 50, false)
        elseif id == 16 then pay(S, s, 150) ev(S, "get", s, 0, 150)
        end
    else
        local get = { [2] = 200, [4] = 50, [7] = 100, [8] = 20, [10] = 100, [13] = 25, [15] = 10, [16] = 100 }
        local cost = { [3] = 50, [11] = 100, [12] = 50 }
        if id == 1 then moveTo(S, s, 0, true) land(S, s)
        elseif id == 5 then ev(S, "freecard", s)
        elseif id == 6 then toJail(S, s)
        elseif id == 9 then ev(S, "birthday", s, 0, 10) eachOther(S, s, 10, true)
        elseif id == 14 then repairs(S, s, 40, 115)
        elseif get[id] then pay(S, s, get[id]) ev(S, "get", s, 0, get[id])
        elseif cost[id] then ev(S, "pay", s, 0, cost[id]) charge(S, s, 0, cost[id])
        end
    end
end
land = function(S, s, o)
    local c = S.pos[s]
    local cell = CELLS[c]
    local t = cell.t
    if t == "gojail" then
        toJail(S, s)
    elseif t == "tax" then
        ev(S, "tax", s, c, cell.tax)
        charge(S, s, 0, cell.tax)
    elseif t == "chance" then
        card(S, s, "c")
    elseif t == "chest" then
        card(S, s, "t")
    elseif cell.price then
        local owner = S.own[c]
        if owner == 0 then
            S.buyAt = c
            ev(S, "forsale", s, c, cell.price)
        elseif owner ~= s and not S.mort[c] then
            if o and o.utilRoll then
                local d1, d2 = roll(S)
                S.dice = { d1, d2 }
                ev(S, "roll", s, (d1 - 1) * 6 + (d2 - 1), d1 + d2)
            end
            local rent = R.Rent(S, c, o)
            ev(S, "rent", s, c, rent)
            charge(S, s, owner, rent)
        end
    end
end
local function moveBy(S, s, steps)
    local old = S.pos[s]
    local new = (old + steps) % 40
    if new < old then
        pay(S, s, 200)
        ev(S, "go", s, 0, 200)
    end
    S.pos[s] = new
    ev(S, "move", s, new)
    land(S, s)
end
local function returnCards(S, s)
    local f = S.free[s]
    if f:find("c") then table.insert(S.deck.c, 9) end
    if f:find("t") then table.insert(S.deck.t, 5) end
    S.free[s] = ""
end
local function bankrupt(S, s, to)
    ev(S, "bankrupt", s, to)
    if to > 0 and not S.alive[to] then to = 0 end
    for _, c in ipairs(PROPS) do
        if S.own[c] == s then
            local cell = CELLS[c]
            if to > 0 then
                if S.lv[c] > 0 then S.cash[to] = S.cash[to] + floor(S.lv[c] * cell.house / 2) end
                S.lv[c] = 0
                S.own[c] = to
                if S.mort[c] then S.liens[#S.liens + 1] = { s = to, c = c } end
            else
                S.lv[c], S.own[c], S.mort[c] = 0, 0, false
            end
        end
    end
    if to > 0 then
        S.cash[to] = S.cash[to] + S.cash[s]
        S.free[to] = addCards(S.free[to], S.free[s])
        S.free[s] = ""
    else
        returnCards(S, s)
    end
    S.cash[s] = 0
    S.alive[s] = false
    S.out[#S.out + 1] = s
    local keep = {}
    for _, d in ipairs(S.debts) do
        if d.from ~= s then
            if d.to == s then d.to = to end
            keep[#keep + 1] = d
        end
    end
    S.debts = keep
    local kl = {}
    for _, l in ipairs(S.liens) do
        if l.s ~= s then kl[#kl + 1] = l end
    end
    S.liens = kl
    if S.offer and (S.offer.from == s or S.offer.to == s) then S.offer = nil end
    if S.auc then S.auc.passed[s] = true end
    if to > 0 then
        for _, c in ipairs(PROPS) do
            if S.own[c] == to and CELLS[c].g <= 8 and groupFull(S, to, CELLS[c].g) then ev(S, "set", to, c, CELLS[c].g) break end
        end
    end
end
local function finish(S)
    local left = {}
    for q = 1, S.n do
        if S.alive[q] then left[#left + 1] = q end
    end
    table.sort(left, function(a, b)
        local ca, cb = R.Capital(S, a), R.Capital(S, b)
        if ca ~= cb then return ca < cb end
        return a > b
    end)
    for _, q in ipairs(left) do
        S.alive[q] = false
        S.out[#S.out + 1] = q
    end
    S.over = true
    S.phase = "over"
    S.auc, S.offer, S.buyAt = nil, nil, nil
    ev(S, "over", S.out[#S.out])
end
local function checkOver(S)
    local alive, humans = 0, 0
    for q = 1, S.n do
        if S.alive[q] then
            alive = alive + 1
            if S.human[q] then humans = humans + 1 end
        end
    end
    if alive <= 1 or (S.anyHuman and humans == 0) then
        finish(S)
        return true
    end
    if (S.cfg or R.CFG).fin == "cap" then
        for q = 1, S.n do
            if S.alive[q] and R.Capital(S, q) >= R.CAP_GOAL then
                finish(S)
                return true
            end
        end
    end
    return false
end
local function nextTurn(S)
    local lim = R.TimeLimit(S)
    if lim and (S.played or 0) >= lim then
        finish(S)
        return
    end
    local q = nextAlive(S, S.turn)
    S.turn = q
    S.rolled, S.dbl, S.offers, S.again = false, 0, 0, false
    S.flow, S.phase, S.buyAt = "pre", "pre", nil
    ev(S, "turn", q)
end
local function aucNext(S)
    local a = S.auc
    local n = S.n
    for k = 0, n - 1 do
        local q = (a.who + k - 1) % n + 1
        if S.alive[q] and not a.passed[q] and q ~= a.lead then
            if S.cash[q] > a.bid then
                a.who = q
                return
            end
            a.passed[q] = true
            ev(S, "pass", q, a.c)
        end
    end
    if a.lead > 0 then
        S.cash[a.lead] = S.cash[a.lead] - a.bid
        ev(S, "won", a.lead, a.c, a.bid)
        acquire(S, a.lead, a.c)
    else
        ev(S, "nobid", 0, a.c)
    end
    S.auc = nil
end
local function afterMove(S)
    local s = S.turn
    if S.again and S.jail[s] == 0 then
        S.phase, S.rolled, S.again = "pre", false, false
    else
        S.phase = "post"
    end
end
local function settle(S)
    if S.over then return end
    if S.offer then
        S.phase = "trade"
        return
    end
    while #S.debts > 0 do
        local d = S.debts[1]
        if not S.alive[d.from] then
            table.remove(S.debts, 1)
        elseif S.cash[d.from] >= d.sum then
            S.cash[d.from] = S.cash[d.from] - d.sum
            if d.to > 0 and S.alive[d.to] then S.cash[d.to] = S.cash[d.to] + d.sum end
            table.remove(S.debts, 1)
        elseif worth(S, d.from) < d.sum then
            bankrupt(S, d.from, d.to)
        else
            S.phase = "debt"
            return
        end
    end
    if #S.liens > 0 then
        S.phase = "lien"
        return
    end
    if checkOver(S) then return end
    if S.auc then
        S.phase = "auction"
        return
    end
    if S.buyAt then
        if S.alive[S.turn] and S.own[S.buyAt] == 0 then
            S.phase = "buy"
            return
        end
        S.buyAt = nil
    end
    if not S.alive[S.turn] then
        nextTurn(S)
        return
    end
    if S.flow == "after" then
        afterMove(S)
    else
        S.phase = S.flow
    end
end
local function canUp(S, s, c)
    local cell = CELLS[c]
    if cell.t ~= "prop" or S.own[c] ~= s or S.lv[c] >= 5 then return false, "build" end
    if not groupFull(S, s, cell.g) then return false, "group" end
    if groupMort(S, cell.g) then return false, "mortGroup" end
    local lo = groupMinMax(S, cell.g)
    if S.lv[c] > lo then return false, "even" end
    if S.lv[c] == 4 then
        if R.Hotels(S) <= 0 then return false, "noHotels" end
    elseif R.Houses(S) <= 0 then return false, "noHouses" end
    if S.cash[s] < cell.house then return false, "cash" end
    return true
end
R.CanUp = canUp
local function canDown(S, s, c)
    local cell = CELLS[c]
    if cell.t ~= "prop" or S.own[c] ~= s or S.lv[c] <= 0 then return false, "down" end
    local _, hi = groupMinMax(S, cell.g)
    if S.lv[c] < hi then return false, "evenDown" end
    return true
end
R.CanDown = canDown
local function canMort(S, s, c)
    local cell = CELLS[c]
    if not cell.price or S.own[c] ~= s or S.mort[c] then return false, "mort" end
    if cell.t == "prop" and groupBuilt(S, cell.g) then return false, "built" end
    return true
end
R.CanMort = canMort
local function canLift(S, s, c)
    local cell = CELLS[c]
    if not cell.price or S.own[c] ~= s or not S.mort[c] then return false, "lift" end
    if S.cash[s] < R.LiftCost(c) then return false, "cash" end
    return true
end
R.CanLift = canLift
local function ownPhase(S, s)
    local ph = S.phase
    if ph == "pre" or ph == "post" or ph == "buy" then return s == S.turn end
    if ph == "debt" then return debtor(S) == s end
    return false
end
local function offerCount(S, s)
    local d = S.debts[1]
    if S.phase == "debt" and d and d.from == s and s ~= S.turn then return d.offers or S.offers, d end
    return S.offers
end
local function offerPhase(S, s)
    local ph = S.phase
    if ph == "pre" or ph == "post" then return s == S.turn end
    if ph == "debt" then return debtor(S) == s end
    return false
end
local function sideOk(S, s, gold, mask, cards)
    if type(gold) ~= "number" or gold < 0 or gold ~= floor(gold) or gold > S.cash[s] then return false end
    if not maskOk(mask) or not cardsOk(cards) then return false end
    if not hasCards(S.free[s], cards or "") then return false end
    local list = R.MaskList(mask or "")
    for _, c in ipairs(list) do
        if S.own[c] ~= s then return false end
        if CELLS[c].t == "prop" and groupBuilt(S, CELLS[c].g) then return false end
    end
    return true, list
end
local function interestOf(S, list)
    local sum = 0
    for _, c in ipairs(list) do
        if S.mort[c] then sum = sum + R.Interest(c) end
    end
    return sum
end
function R.OfferOk(S, o)
    if type(o) ~= "table" then return false end
    local a, b = o.from, o.to
    if type(a) ~= "number" or type(b) ~= "number" or a == b then return false end
    if a < 1 or a > S.n or b < 1 or b > S.n or not S.alive[a] or not S.alive[b] then return false end
    local okA, la = sideOk(S, a, o.ga or 0, o.la, o.ja)
    local okB, lb = sideOk(S, b, o.gb or 0, o.lb, o.jb)
    if not okA or not okB then return false end
    local giveA = (o.ga or 0) > 0 or #la > 0 or (o.ja or "") ~= ""
    local giveB = (o.gb or 0) > 0 or #lb > 0 or (o.jb or "") ~= ""
    if not giveA or not giveB then return false end
    if #la == 0 and #lb == 0 and (o.ja or "") == "" and (o.jb or "") == "" then return false end
    if S.cash[a] - (o.ga or 0) + (o.gb or 0) < interestOf(S, lb) then return false end
    if S.cash[b] - (o.gb or 0) + (o.ga or 0) < interestOf(S, la) then return false end
    return true
end
local function canQuit(S, s)
    if S.over or not S.alive[s] then return false end
    if S.auc and not S.auc.passed[s] then return false end
    if S.offer and (S.offer.from == s or S.offer.to == s) then return false end
    return true
end
function R.Legal(S, m)
    if S.over or type(m) ~= "table" then return false end
    local s, k, c = m.s, m.k, m.c
    if type(s) ~= "number" or s < 1 or s > S.n then return false end
    if k == "setup" then
        return S.seq == 0 and type(m.tok) == "string" and #m.tok == S.n and type(m.hum) == "string" and #m.hum == S.n
    end
    if k == "quit" then return canQuit(S, s) end
    if not S.alive[s] then return false end
    local ph = S.phase
    if k == "roll" then return ph == "pre" and s == S.turn and not S.rolled end
    if k == "bail" then return ph == "pre" and s == S.turn and S.jail[s] > 0 and not S.rolled and S.cash[s] >= 50 end
    if k == "free" then return ph == "pre" and s == S.turn and S.jail[s] > 0 and not S.rolled and S.free[s] ~= "" end
    if k == "buy" then return ph == "buy" and s == S.turn and S.buyAt ~= nil and S.cash[s] >= CELLS[S.buyAt].price end
    if k == "skip" then return ph == "buy" and s == S.turn end
    if k == "bid" then
        local v = m.v
        return ph == "auction" and S.auc.who == s and type(v) == "number" and v == floor(v)
            and v > S.auc.bid and v <= S.cash[s]
    end
    if k == "pass" then return ph == "auction" and S.auc.who == s end
    if type(c) == "number" and not CELLS[c] then return false end
    if k == "up" then return (ph == "pre" or ph == "post") and s == S.turn and type(c) == "number" and canUp(S, s, c) == true end
    if k == "down" then return ownPhase(S, s) and type(c) == "number" and canDown(S, s, c) == true end
    if k == "mort" then return ownPhase(S, s) and type(c) == "number" and canMort(S, s, c) == true end
    if k == "lift" then return (ph == "pre" or ph == "post") and s == S.turn and type(c) == "number" and canLift(S, s, c) == true end
    if k == "offer" then
        if not offerPhase(S, s) or offerCount(S, s) >= 3 then return false end
        return R.OfferOk(S, { from = s, to = m.to, ga = m.ga or 0, gb = m.gb or 0, la = m.la, lb = m.lb, ja = m.ja, jb = m.jb })
    end
    if k == "yes" then return ph == "trade" and S.offer.to == s and R.OfferOk(S, S.offer) end
    if k == "no" then return ph == "trade" and (S.offer.to == s or S.offer.from == s) end
    if k == "lien" then
        if ph ~= "lien" or S.liens[1].s ~= s then return false end
        if m.v == 0 then return true end
        return m.v == 1 and S.cash[s] >= R.LiftCost(S.liens[1].c)
    end
    if k == "end" then return ph == "post" and s == S.turn end
    return false
end
local function downAll(S, s, g)
    local cells = GROUPS[g]
    local house = CELLS[cells[1]].house
    local before, hotels = 0, 0
    for _, c in ipairs(cells) do
        before = before + S.lv[c]
        if S.lv[c] == 5 then hotels = hotels + 1 end
    end
    local bank = R.Houses(S)
    local homes = before - hotels * 5
    local total = min(4 * #cells, homes + bank)
    local sorted = {}
    for i, c in ipairs(cells) do sorted[i] = c end
    table.sort(sorted, function(a, b)
        if CELLS[a].price ~= CELLS[b].price then return CELLS[a].price > CELLS[b].price end
        return a > b
    end)
    local base = floor(total / #cells)
    local extra = total - base * #cells
    for i, c in ipairs(sorted) do
        S.lv[c] = base + ((i <= extra) and 1 or 0)
    end
    local removed = before - total
    local gain = floor(removed * house / 2)
    S.cash[s] = S.cash[s] + gain
    ev(S, "down", s, cells[1], gain)
end
local function doTrade(S)
    local o = S.offer
    local a, b = o.from, o.to
    local la, lb = R.MaskList(o.la or ""), R.MaskList(o.lb or "")
    S.cash[a] = S.cash[a] - (o.ga or 0) + (o.gb or 0)
    S.cash[b] = S.cash[b] - (o.gb or 0) + (o.ga or 0)
    for _, c in ipairs(lb) do
        S.own[c] = a
        if S.mort[c] then S.liens[#S.liens + 1] = { s = a, c = c } end
    end
    for _, c in ipairs(la) do
        S.own[c] = b
        if S.mort[c] then S.liens[#S.liens + 1] = { s = b, c = c } end
    end
    S.free[a] = addCards(takeCards(S.free[a], o.ja or ""), o.jb or "")
    S.free[b] = addCards(takeCards(S.free[b], o.jb or ""), o.ja or "")
    S.offer = nil
    ev(S, "yes", b, a)
    for _, c in ipairs(lb) do
        if CELLS[c].g <= 8 and groupFull(S, a, CELLS[c].g) then ev(S, "set", a, c, CELLS[c].g) end
    end
    for _, c in ipairs(la) do
        if CELLS[c].g <= 8 and groupFull(S, b, CELLS[c].g) then ev(S, "set", b, c, CELLS[c].g) end
    end
end
function R.Apply(S, m)
    S.log = {}
    local s, k, c = m.s, m.k, m.c
    if k == "setup" then
        S.anyHuman = false
        for q = 1, S.n do
            S.token[q] = AIDX[m.tok:sub(q, q)] or q
            S.human[q] = m.hum:sub(q, q) == "1"
            if S.human[q] then S.anyHuman = true end
        end
        ev(S, "setup", S.turn)
        S.seq = S.seq + 1
        return
    end
    if k == "quit" then
        local to = 0
        for _, d in ipairs(S.debts) do
            if d.from == s and d.to > 0 then to = d.to break end
        end
        ev(S, "quit", s, to)
        bankrupt(S, s, to)
        if S.auc and S.auc.who == s then aucNext(S) end
    elseif k == "roll" then
        local d1, d2 = roll(S)
        S.dice = { d1, d2 }
        S.rolled = true
        ev(S, "roll", s, (d1 - 1) * 6 + (d2 - 1), d1 + d2)
        S.flow = "after"
        if S.jail[s] > 0 then
            S.again = false
            if d1 == d2 then
                S.jail[s] = 0
                ev(S, "unjail", s)
                moveBy(S, s, d1 + d2)
            elseif S.jail[s] >= 3 then
                S.jail[s] = 0
                ev(S, "bail", s, 0, 50)
                charge(S, s, 0, 50)
                moveBy(S, s, d1 + d2)
            else
                S.jail[s] = S.jail[s] + 1
                ev(S, "stay", s)
            end
        else
            if d1 == d2 then S.dbl = S.dbl + 1 else S.dbl = 0 end
            if S.dbl >= 3 then
                toJail(S, s)
            else
                S.again = d1 == d2
                moveBy(S, s, d1 + d2)
            end
        end
    elseif k == "bail" then
        S.cash[s] = S.cash[s] - 50
        S.jail[s] = 0
        ev(S, "bail", s, 0, 50)
    elseif k == "free" then
        local d = S.free[s]:find("c") and "c" or "t"
        S.free[s] = takeCards(S.free[s], d)
        table.insert(S.deck[d], d == "c" and 9 or 5)
        S.jail[s] = 0
        ev(S, "freecard", s, 0, 1)
    elseif k == "buy" then
        local at = S.buyAt
        S.cash[s] = S.cash[s] - CELLS[at].price
        S.buyAt = nil
        ev(S, "buy", s, at, CELLS[at].price)
        acquire(S, s, at)
    elseif k == "skip" then
        local at = S.buyAt
        S.buyAt = nil
        S.auc = { c = at, bid = 0, lead = 0, who = s % S.n + 1, passed = {} }
        ev(S, "auction", s, at)
        aucNext(S)
    elseif k == "bid" then
        S.auc.bid, S.auc.lead = m.v, s
        ev(S, "bid", s, S.auc.c, m.v)
        S.auc.who = s % S.n + 1
        aucNext(S)
    elseif k == "pass" then
        S.auc.passed[s] = true
        ev(S, "pass", s, S.auc.c)
        S.auc.who = s % S.n + 1
        aucNext(S)
    elseif k == "up" then
        local cell = CELLS[c]
        S.cash[s] = S.cash[s] - cell.house
        S.lv[c] = S.lv[c] + 1
        ev(S, S.lv[c] == 5 and "hotel" or "up", s, c, cell.house)
    elseif k == "down" then
        local cell = CELLS[c]
        if S.lv[c] == 5 and R.Houses(S) < 4 then
            downAll(S, s, cell.g)
        else
            S.lv[c] = S.lv[c] - 1
            local gain = floor(cell.house / 2)
            S.cash[s] = S.cash[s] + gain
            ev(S, "down", s, c, gain)
        end
    elseif k == "mort" then
        S.mort[c] = true
        S.cash[s] = S.cash[s] + CELLS[c].mort
        ev(S, "mort", s, c, CELLS[c].mort)
    elseif k == "lift" then
        S.mort[c] = false
        S.cash[s] = S.cash[s] - R.LiftCost(c)
        ev(S, "lift", s, c, R.LiftCost(c))
    elseif k == "offer" then
        S.offer = { from = s, to = m.to, ga = m.ga or 0, gb = m.gb or 0, la = m.la or "", lb = m.lb or "",
                    ja = m.ja or "", jb = m.jb or "" }
        local n, d = offerCount(S, s)
        if d then d.offers = n + 1 else S.offers = S.offers + 1 end
        ev(S, "offer", s, m.to)
    elseif k == "yes" then
        doTrade(S)
    elseif k == "no" then
        local o = S.offer
        S.offer = nil
        ev(S, "no", s, o.from)
        if o.from ~= s then
            local want = 0
            for _, c in ipairs(R.MaskList(o.lb)) do want = want + CELLS[c].price end
            S.bno[o.from] = R.OwnSig(S) .. ":" .. s .. ":" .. ((want > 0 and o.ga >= 2 * want) and 2 or 1)
        end
    elseif k == "lien" then
        local l = table.remove(S.liens, 1)
        if m.v == 1 then
            S.cash[s] = S.cash[s] - R.LiftCost(l.c)
            S.mort[l.c] = false
            ev(S, "lien", s, l.c, 1)
        else
            ev(S, "lien", s, l.c, 0)
            charge(S, s, 0, R.Interest(l.c))
        end
    elseif k == "end" then
        nextTurn(S)
        S.seq = S.seq + 1
        return
    end
    S.seq = S.seq + 1
    settle(S)
end
function R.OwnSig(S)
    local out = {}
    for i, c in ipairs(PROPS) do out[i] = ALPHA:sub(S.own[c] + 1, S.own[c] + 1) end
    return table.concat(out)
end
function R.Waiting(S)
    if S.over then return nil end
    local ph = S.phase
    if ph == "pre" or ph == "post" or ph == "buy" then return S.turn, R.TimeOf(S, ph) end
    if ph == "auction" then return S.auc.who, R.TimeOf(S, ph) end
    if ph == "debt" then return debtor(S), R.TimeOf(S, ph) end
    if ph == "trade" then return S.offer.to, R.TimeOf(S, ph) end
    if ph == "lien" then return S.liens[1].s, R.TimeOf(S, ph) end
    return nil
end
function R.Default(S, s)
    if S.over then return nil end
    local who = R.Waiting(S)
    if who ~= s then return nil end
    local ph = S.phase
    if ph == "pre" then return { k = "roll", s = s } end
    if ph == "buy" then return { k = "skip", s = s } end
    if ph == "post" then return { k = "end", s = s } end
    if ph == "auction" then return { k = "pass", s = s } end
    if ph == "trade" then return { k = "no", s = s } end
    if ph == "lien" then return { k = "lien", s = s, v = 0 } end
    if ph == "debt" and R.Bot then return R.Bot(S, s) end
    return nil
end
function R.Place(S, q)
    for i, s in ipairs(S.out) do
        if s == q then return S.n - i + 1 end
    end
    return nil
end
local function encDice(d)
    if not d or d[1] == 0 then return 36 end
    return (d[1] - 1) * 6 + (d[2] - 1)
end
function R.View(S, left)
    local v = {
        board = B.INDEX[S.board] or 0, seq = S.seq, phase = S.phase, turn = S.turn, who = R.Waiting(S) or 0,
        dice = encDice(S.dice), dbl = S.dbl, rolled = S.rolled, offers = (offerCount(S, debtor(S) or 0)),
        left = left and floor(min(left, 124) / 2) * 2 or 63, n = S.n, seats = {}, own = {}, lv = {}, mort = {},
        ev = { k = S.ev.k, s = S.ev.s, c = S.ev.c, v = S.ev.v }, over = S.over, buyAt = S.buyAt,
    }
    for q = 1, S.n do
        local f = S.free[q]
        v.seats[q] = {
            pos = S.pos[q], cash = S.cash[q], jail = S.jail[q], free = f, token = S.token[q],
            out = R.Place(S, q) or 0, alive = S.alive[q],
        }
    end
    for _, c in ipairs(PROPS) do
        v.own[c], v.lv[c], v.mort[c] = S.own[c], S.lv[c], S.mort[c]
    end
    if S.auc then
        local pm = 0
        for q = 1, S.n do
            if S.auc.passed[q] then pm = pm + 2 ^ (q - 1) end
        end
        v.auc = { c = S.auc.c, bid = S.auc.bid, lead = S.auc.lead, passed = pm }
    end
    if S.offer then
        local o = S.offer
        v.offer = { from = o.from, to = o.to, ga = o.ga, gb = o.gb, la = o.la, lb = o.lb, ja = o.ja, jb = o.jb }
    end
    if #S.debts > 0 then
        local d = S.debts[1]
        v.debt = { to = d.to, sum = d.sum, count = #S.debts }
    end
    if #S.liens > 0 then v.lien = S.liens[1].c end
    local lim = R.TimeLimit(S)
    if lim then v.rem = floor(max(0, lim - (S.played or 0)) / 2) * 2 end
    return v
end
local function cardBits(j)
    local n = 0
    if j and j:find("c") then n = n + 1 end
    if j and j:find("t") then n = n + 2 end
    return n
end
local function bitsCards(n)
    local s = ""
    if n % 2 == 1 then s = "c" end
    if floor(n / 2) % 2 == 1 then s = s .. "t" end
    return s
end
function R.Pack(v)
    local out = {
        "0", enc(v.board, 1), enc(v.seq, 3), enc(PH[v.phase] or 7, 1), enc(v.turn, 1), enc(v.who, 1),
        enc(v.dice, 1), enc(min(v.dbl, 3) + (v.rolled and 4 or 0) + min(v.offers, 3) * 8, 1), enc(v.left == 63 and 63 or floor(v.left / 2), 1),
    }
    for q = 1, 4 do
        local st = v.seats[q]
        if st then
            out[#out + 1] = enc(st.pos, 1) .. enc(st.cash, 4) .. enc(st.jail + cardBits(st.free) * 4, 1) .. enc(st.token, 1)
        else
            out[#out + 1] = "0000000"
        end
    end
    for q = 1, 4 do
        local st = v.seats[q]
        out[#out + 1] = enc(st and st.out or 0, 1)
    end
    for _, c in ipairs(PROPS) do
        out[#out + 1] = enc(v.own[c] * 7 + (v.mort[c] and 6 or v.lv[c]), 1)
    end
    local e = v.ev
    out[#out + 1] = enc(EV[e.k] or 0, 1) .. enc(e.s, 1) .. enc(e.c, 1) .. enc(e.v, 3)
    local s = table.concat(out)
    if v.auc then
        s = s .. "." .. enc(v.auc.c, 1) .. enc(v.auc.bid, 4) .. enc(v.auc.lead, 1) .. enc(v.auc.passed, 1)
    end
    if v.offer then
        local o = v.offer
        s = s .. "." .. enc(o.from, 1) .. enc(o.to, 1) .. enc(o.ga, 4) .. enc(o.gb, 4)
            .. ((o.la ~= "" and o.la) or enc(0, 5)) .. ((o.lb ~= "" and o.lb) or enc(0, 5))
            .. enc(cardBits(o.ja) + cardBits(o.jb) * 4, 1)
    end
    if v.debt then
        s = s .. "." .. enc(v.debt.to, 1) .. enc(v.debt.sum, 4) .. enc(v.debt.count, 1)
    end
    if v.lien then s = s .. "." .. enc(v.lien, 1) end
    if v.rem then s = s .. "." .. enc(floor(v.rem / 2), 2) end
    return s
end
function R.Unpack(s)
    if type(s) ~= "string" or #s < 77 or s:sub(1, 1) ~= "0" then return nil end
    local parts = {}
    for p in (s .. "."):gmatch("([^.]*)%.") do parts[#parts + 1] = p end
    local h = parts[1]
    if #h ~= 77 then return nil end
    local v = { seats = {}, own = {}, lv = {}, mort = {} }
    v.board = dec(h, 2, 1)
    v.seq = dec(h, 3, 3)
    v.phase = R.PHASES[(dec(h, 6, 1) or 7) + 1] or "over"
    v.turn = dec(h, 7, 1)
    v.who = dec(h, 8, 1)
    v.dice = dec(h, 9, 1)
    local f = dec(h, 10, 1) or 0
    v.dbl = f % 4
    v.rolled = floor(f / 4) % 2 == 1
    v.offers = floor(f / 8)
    v.left = dec(h, 11, 1)
    if v.left == 63 then v.left = nil else v.left = (v.left or 0) * 2 end
    local n = 0
    for q = 1, 4 do
        local at = 12 + (q - 1) * 7
        local token = dec(h, at + 6, 1)
        if token and token > 0 then
            n = q
            local jc = dec(h, at + 5, 1) or 0
            v.seats[q] = { pos = dec(h, at, 1), cash = dec(h, at + 1, 4), jail = jc % 4, free = bitsCards(floor(jc / 4)),
                           token = token, out = dec(h, 40 + q - 1, 1) or 0 }
            v.seats[q].alive = v.seats[q].out == 0
        end
    end
    v.n = n
    for i, c in ipairs(PROPS) do
        local x = dec(h, 44 + i - 1, 1) or 0
        v.own[c] = floor(x / 7)
        local r = x % 7
        v.mort[c] = r == 6
        v.lv[c] = r == 6 and 0 or r
    end
    v.ev = { k = R.EVENTS[(dec(h, 72, 1) or 0) + 1] or "none", s = dec(h, 73, 1), c = dec(h, 74, 1), v = dec(h, 75, 3) }
    v.over = v.phase == "over"
    for i = 2, #parts do
        local p = parts[i]
        if #p == 7 then
            v.auc = { c = dec(p, 1, 1), bid = dec(p, 2, 4), lead = dec(p, 6, 1), passed = dec(p, 7, 1) }
        elseif #p == 21 then
            local cb = dec(p, 21, 1) or 0
            v.offer = { from = dec(p, 1, 1), to = dec(p, 2, 1), ga = dec(p, 3, 4), gb = dec(p, 7, 4),
                        la = p:sub(11, 15), lb = p:sub(16, 20), ja = bitsCards(cb % 4), jb = bitsCards(floor(cb / 4)) }
            if v.offer.la == "00000" then v.offer.la = "" end
            if v.offer.lb == "00000" then v.offer.lb = "" end
        elseif #p == 6 then
            v.debt = { to = dec(p, 1, 1), sum = dec(p, 2, 4), count = dec(p, 6, 1) }
        elseif #p == 2 then
            v.rem = (dec(p, 1, 2) or 0) * 2
        elseif #p == 1 then
            v.lien = dec(p, 1, 1)
        end
    end
    if v.phase == "buy" and v.seats[v.turn] then v.buyAt = v.seats[v.turn].pos end
    if n < 2 or not v.turn then return nil end
    return v
end
local function ser(t, out)
    local tt = type(t)
    if tt == "number" then out[#out + 1] = tostring(t)
    elseif tt == "string" then out[#out + 1] = string.format("%q", t)
    elseif tt == "boolean" then out[#out + 1] = t and "true" or "false"
    elseif tt == "table" then
        out[#out + 1] = "{"
        local keys = {}
        for k in pairs(t) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            return a < b
        end)
        for _, k in ipairs(keys) do
            if type(k) == "number" then out[#out + 1] = "[" .. k .. "]=" else out[#out + 1] = k .. "=" end
            ser(t[k], out)
            out[#out + 1] = ","
        end
        out[#out + 1] = "}"
    end
end
function R.Save(S)
    local out = {}
    local log = S.log
    S.log = nil
    ser(S, out)
    S.log = log
    return table.concat(out)
end
function R.Load(str)
    if type(str) ~= "string" or str:sub(1, 1) ~= "{" then return nil end
    local chunk = loadstring("return " .. str)
    if not chunk then return nil end
    local ok, S = pcall(chunk)
    if not ok or type(S) ~= "table" or type(S.n) ~= "number" or not S.cash then return nil end
    return S
end
