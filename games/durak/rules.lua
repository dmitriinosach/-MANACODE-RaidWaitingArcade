local ADDON, ns = ...
local floor = math.floor
local R = {}
ns.Durak = R
local HAND = 6
local CAP, CAP_FIRST = 6, 5
local BOT_HIGH = 11
local BOT_DECK = 6
function R.Suit(c) return floor((c - 1) / 9) + 1 end
function R.Rank(c) return (c - 1) % 9 + 6 end
function R.Card(rank, suit) return (suit - 1) * 9 + (rank - 5) end
local Suit, Rank = R.Suit, R.Rank
local function find(t, v)
    for i = 1, #t do if t[i] == v then return i end end
    return nil
end
local function takeOut(hand, c)
    local i = find(hand, c)
    if i then table.remove(hand, i) end
    return i ~= nil
end
local function nextActive(S, s)
    for k = 1, S.n do
        local q = (s + k - 1) % S.n + 1
        if not S.gone[q] then return q end
    end
    return nil
end
R.NextActive = nextActive
function R.Beats(S, c, a)
    if Suit(c) == Suit(a) then return Rank(c) > Rank(a) end
    return Suit(c) == S.trump and Suit(a) ~= S.trump
end
local beats = R.Beats
local function ranksOn(S)
    local set = {}
    for i = 1, #S.table do
        local p = S.table[i]
        set[Rank(p.a)] = true
        if p.b then set[Rank(p.b)] = true end
    end
    return set
end
local function unbeaten(S)
    for i = 1, #S.table do
        if not S.table[i].b then return true end
    end
    return false
end
R.Unbeaten = unbeaten
local function anyBeaten(S)
    for i = 1, #S.table do
        if S.table[i].b then return true end
    end
    return false
end
local function cap(S)
    return S.firstBout and CAP_FIRST or CAP
end
local function canThrow(S, s)
    if s == S.defender or S.gone[s] then return false end
    if #S.table == 0 or #S.table >= S.limit then return false end
    local set = ranksOn(S)
    local h = S.hands[s]
    for i = 1, #h do
        if set[Rank(h[i])] then return true end
    end
    return false
end
R.CanThrow = canThrow
local function startBout(S)
    S.table = {}
    S.taking = false
    S.passed = {}
    S.limit = math.min(cap(S), #S.hands[S.defender])
end
function R.Deal(seed, n, variant, first)
    local rng = ns.RNG.New(seed)
    local deck = {}
    for c = 1, 36 do deck[c] = c end
    rng:Shuffle(deck)
    local S = {
        variant = (variant == "transfer") and "transfer" or "throw",
        n = n, deck = deck, hands = {}, gone = {}, out = {},
        firstBout = true, over = false, seq = 0,
    }
    for s = 1, n do S.hands[s] = {} end
    for _ = 1, HAND do
        for s = 1, n do
            S.hands[s][#S.hands[s] + 1] = table.remove(deck)
        end
    end
    S.trumpCard = deck[1]
    S.trump = Suit(S.trumpCard)
    local att = first
    if not att or att < 1 or att > n then
        local best
        for s = 1, n do
            local h = S.hands[s]
            for i = 1, #h do
                if Suit(h[i]) == S.trump and (not best or Rank(h[i]) < best) then
                    best, att = Rank(h[i]), s
                end
            end
        end
        att = att or 1
    end
    S.attacker = att
    S.defender = nextActive(S, att)
    startBout(S)
    return S
end
function R.Legal(S, m)
    if S.over or type(m) ~= "table" then return false end
    local s, c = m.s, m.c
    if type(s) ~= "number" or s < 1 or s > S.n or S.gone[s] then return false end
    local h = S.hands[s]
    local k = m.k
    if k == "att" then
        return s == S.attacker and #S.table == 0 and find(h, c) ~= nil
    end
    if k == "add" then
        if s == S.defender or #S.table == 0 or #S.table >= S.limit then return false end
        if not find(h, c) then return false end
        return ranksOn(S)[Rank(c)] == true
    end
    if k == "beat" then
        if s ~= S.defender or S.taking then return false end
        local p = S.table[m.i or 0]
        if not p or p.b or not find(h, c) then return false end
        return beats(S, c, p.a)
    end
    if k == "tr" then
        if S.variant ~= "transfer" or s ~= S.defender or S.taking then return false end
        if #S.table == 0 or anyBeaten(S) or not find(h, c) then return false end
        if Rank(c) ~= Rank(S.table[1].a) then return false end
        local nx = nextActive(S, s)
        if not nx or nx == s then return false end
        local after = #S.table + 1
        return after <= cap(S) and after <= #S.hands[nx]
    end
    if k == "take" then
        return s == S.defender and not S.taking and unbeaten(S)
    end
    if k == "pass" then
        if s == S.defender or S.passed[s] or #S.table == 0 then return false end
        if unbeaten(S) and not S.taking then return false end
        return true
    end
    return false
end
local function boutDone(S)
    if #S.table == 0 then return false end
    if unbeaten(S) and not S.taking then return false end
    for s = 1, S.n do
        if s ~= S.defender and not S.gone[s] and not S.passed[s] and canThrow(S, s) then
            return false
        end
    end
    return true
end
local function draw(S, s)
    local h = S.hands[s]
    while #h < HAND and #S.deck > 0 do
        h[#h + 1] = table.remove(S.deck)
    end
end
local function closeBout(S)
    local took = S.taking
    if took then
        local h = S.hands[S.defender]
        for i = 1, #S.table do
            h[#h + 1] = S.table[i].a
            if S.table[i].b then h[#h + 1] = S.table[i].b end
        end
    end
    S.table = {}
    local order = { S.attacker }
    for k = 1, S.n - 1 do
        local q = (S.attacker + k - 1) % S.n + 1
        if q ~= S.defender and q ~= S.attacker and not S.gone[q] then order[#order + 1] = q end
    end
    if S.defender ~= S.attacker then order[#order + 1] = S.defender end
    for i = 1, #order do draw(S, order[i]) end
    if #S.deck == 0 then
        for i = 1, #order do
            local q = order[i]
            if not S.gone[q] and #S.hands[q] == 0 then
                S.gone[q] = true
                S.out[#S.out + 1] = q
            end
        end
    end
    local left, last = 0, nil
    for q = 1, S.n do
        if not S.gone[q] then left, last = left + 1, q end
    end
    if left <= 1 then
        S.over = true
        S.fool = last
        S.taking, S.passed = false, {}
        return
    end
    local att
    if took then
        att = nextActive(S, S.defender)
    elseif S.gone[S.defender] then
        att = nextActive(S, S.defender)
    else
        att = S.defender
    end
    S.attacker = att
    S.defender = nextActive(S, att)
    S.firstBout = false
    startBout(S)
end
function R.Apply(S, m)
    local s, c, k = m.s, m.c, m.k
    local ev
    if k == "att" or k == "add" then
        takeOut(S.hands[s], c)
        S.table[#S.table + 1] = { a = c }
        S.passed = {}
        ev = "slide"
    elseif k == "beat" then
        takeOut(S.hands[s], c)
        S.table[m.i].b = c
        S.passed = {}
        ev = "slide"
    elseif k == "tr" then
        takeOut(S.hands[s], c)
        S.table[#S.table + 1] = { a = c }
        S.attacker = s
        S.defender = nextActive(S, s)
        S.limit = math.min(cap(S), #S.hands[S.defender])
        S.passed = {}
        ev = "slide"
    elseif k == "take" then
        S.taking = true
        ev = "take"
    elseif k == "pass" then
        S.passed[s] = true
        ev = "pass"
    end
    S.seq = S.seq + 1
    if boutDone(S) then
        local took = S.taking
        closeBout(S)
        ev = took and "took" or "clear"
    end
    return ev
end
function R.Waiting(S)
    local out = {}
    if S.over then return out end
    if #S.table == 0 then
        out[1] = S.attacker
        return out
    end
    if unbeaten(S) and not S.taking then
        out[1] = S.defender
        return out
    end
    for s = 1, S.n do
        if s ~= S.defender and not S.gone[s] and not S.passed[s] and canThrow(S, s) then
            out[#out + 1] = s
        end
    end
    return out
end
local function weight(S, c)
    return (Suit(c) == S.trump and 100 or 0) + Rank(c)
end
local function lowest(S, h, ok)
    local best, bw
    for i = 1, #h do
        local c = h[i]
        if not ok or ok(c) then
            local w = weight(S, c)
            if not bw or w < bw then best, bw = c, w end
        end
    end
    return best
end
function R.Default(S, s)
    if S.over then return nil end
    if #S.table == 0 then
        if s ~= S.attacker then return nil end
        return { k = "att", s = s, c = lowest(S, S.hands[s]) }
    end
    if s == S.defender then
        if unbeaten(S) and not S.taking then return { k = "take", s = s } end
        return nil
    end
    if R.Legal(S, { k = "pass", s = s }) then return { k = "pass", s = s } end
    return nil
end
local function beater(S, h, a)
    return lowest(S, h, function(c) return beats(S, c, a) end)
end
function R.Bot(S, s)
    if S.over or S.gone[s] then return nil end
    local h = S.hands[s]
    if #S.table == 0 then
        if s ~= S.attacker then return nil end
        return { k = "att", s = s, c = lowest(S, h) }
    end
    if s == S.defender then
        if S.taking or not unbeaten(S) then return nil end
        if S.variant == "transfer" and not anyBeaten(S) then
            local r = Rank(S.table[1].a)
            local c = lowest(S, h, function(x) return Rank(x) == r and Suit(x) ~= S.trump end)
            if c and R.Legal(S, { k = "tr", s = s, c = c }) then
                return { k = "tr", s = s, c = c }
            end
        end
        local used, plan = {}, nil
        for i = 1, #S.table do
            local p = S.table[i]
            if not p.b then
                local c = lowest(S, h, function(x) return not used[x] and beats(S, x, p.a) end)
                if not c then return { k = "take", s = s } end
                if Suit(c) == S.trump and Rank(c) > BOT_HIGH and #S.deck > BOT_DECK then
                    return { k = "take", s = s }
                end
                used[c] = true
                plan = plan or { k = "beat", s = s, c = c, i = i }
            end
        end
        return plan
    end
    if canThrow(S, s) then
        local set = ranksOn(S)
        local early = #S.deck > 0
        local c = lowest(S, h, function(x)
            if not set[Rank(x)] then return false end
            if early then return Suit(x) ~= S.trump and Rank(x) <= BOT_HIGH end
            return true
        end)
        if c then return { k = "add", s = s, c = c } end
    end
    if R.Legal(S, { k = "pass", s = s }) then return { k = "pass", s = s } end
    return nil
end
function R.Sort(S, hand)
    local out = {}
    for i = 1, #hand do out[i] = hand[i] end
    table.sort(out, function(x, y)
        local tx, ty = Suit(x) == S.trump, Suit(y) == S.trump
        if tx ~= ty then return ty end
        if Suit(x) ~= Suit(y) then return Suit(x) < Suit(y) end
        return Rank(x) < Rank(y)
    end)
    return out
end
local ALPHA = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function enc(n)
    n = n or 0
    return ALPHA:sub(n + 1, n + 1)
end
local function dec(ch)
    local i = ALPHA:find(ch, 1, true)
    return i and (i - 1) or nil
end
local function bits(t, n)
    local out = {}
    for q = 1, n do out[q] = t[q] and "1" or "0" end
    return table.concat(out)
end
function R.Pack(v, left)
    local hand, counts, tbl, out = {}, {}, {}, {}
    for i = 1, #v.hand do hand[i] = enc(v.hand[i]) end
    for q = 1, v.n do counts[q] = enc(v.counts[q]) end
    for i = 1, #v.table do
        tbl[#tbl + 1] = enc(v.table[i].a)
        tbl[#tbl + 1] = v.table[i].b and enc(v.table[i].b) or "_"
    end
    for i = 1, #v.out do out[i] = enc(v.out[i]) end
    return table.concat({
        enc(v.me), enc(v.n), v.variant == "transfer" and "r" or "t",
        table.concat(hand), table.concat(counts), table.concat(tbl),
        enc(v.trump), v.trumpCard and enc(v.trumpCard) or "_", enc(v.deckLeft),
        enc(v.attacker), enc(v.defender), v.taking and "1" or "0",
        bits(v.passed, v.n), bits(v.gone, v.n), table.concat(out),
        v.fool and enc(v.fool) or "_", v.over and "1" or "0",
        tostring(v.seq or 0), left and tostring(floor(left)) or "_",
    }, ".")
end
function R.Unpack(s)
    if type(s) ~= "string" then return nil end
    local f = {}
    for part in (s .. "."):gmatch("([^.]*)%.") do f[#f + 1] = part end
    if #f ~= 19 then return nil end
    local n = dec(f[2])
    if not n or n < 2 or n > 4 then return nil end
    local v = { me = dec(f[1]), n = n, variant = (f[3] == "r") and "transfer" or "throw",
                hand = {}, counts = {}, table = {}, passed = {}, gone = {}, out = {} }
    for i = 1, #f[4] do v.hand[i] = dec(f[4]:sub(i, i)) end
    for q = 1, n do v.counts[q] = dec(f[5]:sub(q, q)) or 0 end
    for i = 1, #f[6], 2 do
        local a, b = f[6]:sub(i, i), f[6]:sub(i + 1, i + 1)
        v.table[#v.table + 1] = { a = dec(a), b = (b ~= "_") and dec(b) or nil }
    end
    v.trump = dec(f[7])
    v.trumpCard = (f[8] ~= "_") and dec(f[8]) or nil
    v.deckLeft = dec(f[9]) or 0
    v.attacker, v.defender = dec(f[10]), dec(f[11])
    v.taking = f[12] == "1"
    for q = 1, n do
        v.passed[q] = f[13]:sub(q, q) == "1"
        v.gone[q] = f[14]:sub(q, q) == "1"
    end
    for i = 1, #f[15] do v.out[i] = dec(f[15]:sub(i, i)) end
    v.fool = (f[16] ~= "_") and dec(f[16]) or nil
    v.over = f[17] == "1"
    v.seq = tonumber(f[18]) or 0
    v.left = tonumber(f[19])
    if not v.me or not v.attacker or not v.defender or not v.trump then return nil end
    for i = 1, #v.hand do if not v.hand[i] then return nil end end
    for i = 1, #v.table do if not v.table[i].a then return nil end end
    return v
end
function R.View(S, s)
    local counts = {}
    for q = 1, S.n do counts[q] = #S.hands[q] end
    local tbl = {}
    for i = 1, #S.table do tbl[i] = { a = S.table[i].a, b = S.table[i].b } end
    local passed = {}
    for q = 1, S.n do passed[q] = S.passed[q] or false end
    local gone = {}
    for q = 1, S.n do gone[q] = S.gone[q] or false end
    local out = {}
    for i = 1, #S.out do out[i] = S.out[i] end
    return {
        me = s, n = S.n, variant = S.variant,
        hand = R.Sort(S, S.hands[s] or {}),
        counts = counts, table = tbl,
        trump = S.trump, trumpCard = (#S.deck > 0) and S.trumpCard or nil,
        deckLeft = #S.deck,
        attacker = S.attacker, defender = S.defender,
        taking = S.taking, passed = passed, limit = S.limit,
        gone = gone, out = out, fool = S.fool, over = S.over, seq = S.seq,
    }
end
