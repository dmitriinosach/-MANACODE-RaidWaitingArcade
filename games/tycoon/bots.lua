local ADDON, ns = ...
local B = ns.TycoonBoards
local R = ns.Tycoon
local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
local CELLS, PROPS, GROUPS = B.cells, B.props, B.groups
local K = { [1] = 0.5, [2] = 0.9, [3] = 1.0, [4] = 1.3, [5] = 1.2, [6] = 1.2, [7] = 1.1, [8] = 1.1, [10] = 0.6 }
local BUILD = { 4, 6, 5, 8, 7, 3, 2, 1 }
local UNBUILD = { 1, 2, 3, 7, 8, 5, 6, 4 }
local CARD_V = 50
local PREMIUM = 1.0
local RICH = 10
local FLOOR = 0
local SWEET = 1.5
local RESERVE_CAP = 600
local function ceil10(v)
    return ceil(v / 10) * 10
end
local function othersOwn(S, s, g, skip)
    local who
    for _, c in ipairs(GROUPS[g]) do
        if c ~= skip then
            local o = S.own[c]
            if o == 0 or o == s then return nil end
            if who and who ~= o then return nil end
            who = o
        end
    end
    return who
end
local function completesOwn(S, s, c)
    local g = CELLS[c].g
    if g > 8 then return false end
    for _, x in ipairs(GROUPS[g]) do
        if x ~= c and S.own[x] ~= s then return false end
    end
    return true
end
local function blocks(S, s, c)
    local g = CELLS[c].g
    if g > 8 then return false end
    return othersOwn(S, s, g, c) ~= nil
end
local function value(S, s, c)
    local cell = CELLS[c]
    local k
    if cell.t == "rail" then
        k = 1.0 + 0.2 * R.CountKind(S, s, "rail")
    else
        k = K[cell.g] or 1
    end
    local v = cell.price * k
    if completesOwn(S, s, c) then v = v * 2
    elseif blocks(S, s, c) then v = v * 1.5 end
    return v
end
R.BotValue = value
local function reserve(S, s)
    local built = false
    for _, c in ipairs(PROPS) do
        if S.own[c] ~= s and S.own[c] ~= 0 and S.lv[c] > 0 then built = true break end
    end
    if not built then return FLOOR end
    local worst = FLOOR
    for d = 2, 12 do
        local c = (S.pos[s] + d) % 40
        local o = S.own[c]
        if o and o ~= 0 and o ~= s and not S.mort[c] then
            worst = max(worst, R.Rent(S, c))
        end
    end
    return min(worst, RESERVE_CAP)
end
R.BotReserve = reserve
local function fullGroups(S, s)
    local n = 0
    for g = 1, 8 do
        if R.GroupFull(S, s, g) then n = n + 1 end
    end
    return n
end
local function buildMove(S, s, rsv)
    for _, target in ipairs({ 3, 5 }) do
        for _, g in ipairs(BUILD) do
            if R.GroupFull(S, s, g) then
                local best, bl
                for _, c in ipairs(GROUPS[g]) do
                    if S.lv[c] < target and R.CanUp(S, s, c) and S.cash[s] - CELLS[c].house >= rsv then
                        if not best or S.lv[c] < bl then best, bl = c, S.lv[c] end
                    end
                end
                if best then return { k = "up", s = s, c = best } end
            end
        end
    end
    return nil
end
local function debtMove(S, s)
    for _, g in ipairs(UNBUILD) do
        local best, bl
        for _, c in ipairs(GROUPS[g]) do
            if S.own[c] == s and S.lv[c] > 0 and R.CanDown(S, s, c) then
                if not best or S.lv[c] > bl then best, bl = c, S.lv[c] end
            end
        end
        if best then return { k = "down", s = s, c = best } end
    end
    local list = {}
    for _, c in ipairs(PROPS) do
        if R.CanMort(S, s, c) then list[#list + 1] = c end
    end
    if #list == 0 then return nil end
    table.sort(list, function(a, b)
        local fa = CELLS[a].g <= 8 and R.GroupFull(S, s, CELLS[a].g)
        local fb = CELLS[b].g <= 8 and R.GroupFull(S, s, CELLS[b].g)
        if fa ~= fb then return fb end
        local va, vb = value(S, s, a), value(S, s, b)
        if va ~= vb then return va < vb end
        return a < b
    end)
    return { k = "mort", s = s, c = list[1] }
end
local function liftMove(S, s, rsv)
    local best, bf, bp
    for _, c in ipairs(PROPS) do
        if R.CanLift(S, s, c) and S.cash[s] > 2 * rsv + R.LiftCost(c) then
            local full = CELLS[c].g <= 8 and R.GroupFull(S, s, CELLS[c].g)
            if not best or (full and not bf) or (full == bf and CELLS[c].price > bp) then
                best, bf, bp = c, full, CELLS[c].price
            end
        end
    end
    return best and { k = "lift", s = s, c = best } or nil
end
local function jailBuilt(S, s)
    for c = 11, 29 do
        local o = S.own[c]
        if o and o ~= 0 and o ~= s and S.lv[c] > 0 then return true end
    end
    return false
end
local function offerMove(S, s)
    if S.offers > 0 then return nil end
    local sig = R.OwnSig(S)
    for _, g in ipairs(BUILD) do
        local missing, to, mine = nil, nil, 0
        for _, c in ipairs(GROUPS[g]) do
            if S.own[c] == s then mine = mine + 1
            elseif S.own[c] ~= 0 and not missing then missing, to = c, S.own[c]
            else missing = -1 end
        end
        local want = missing and missing > 0 and CELLS[missing].price or 0
        local tier = (S.cash[s] > RICH * want) and 2 or 1
        if missing and missing > 0 and mine == #GROUPS[g] - 1 and S.alive[to] and S.bno[s] ~= sig .. ":" .. to .. ":" .. tier then
            local give, gd
            for _, c in ipairs(PROPS) do
                if S.own[c] == s and CELLS[c].g ~= g and not completesOwn(S, to, c)
                    and not (CELLS[c].t == "prop" and R.GroupBuilt(S, CELLS[c].g)) then
                    local d = math.abs(CELLS[c].price - want)
                    if d <= 200 and (not give or d < gd) then give, gd = c, d end
                end
            end
            if give then
                local diff = want - CELLS[give].price
                local ga = ceil10(max(0, diff) + want * PREMIUM * tier)
                if S.cash[s] - ga >= reserve(S, s) then
                    local m = { k = "offer", s = s, to = to, ga = ga, gb = 0,
                                la = R.MaskOf({ give }), lb = R.MaskOf({ missing }), ja = "", jb = "" }
                    if R.Legal(S, m) then return m end
                end
            end
        end
    end
    return nil
end
local function groupsAfter(S, s, la, lb)
    local keep = {}
    for _, c in ipairs(la) do keep[c] = S.own[c] S.own[c] = s end
    for _, c in ipairs(lb) do keep[c] = S.own[c] S.own[c] = 0 end
    local n = fullGroups(S, s)
    for c, o in pairs(keep) do S.own[c] = o end
    return n
end
local function answer(S, s)
    local o = S.offer
    local la, lb = R.MaskList(o.la), R.MaskList(o.lb)
    local before = fullGroups(S, s)
    local after = groupsAfter(S, s, la, lb)
    if after > before then return { k = "yes", s = s } end
    if after < before then return { k = "no", s = s } end
    local given = 0
    for _, c in ipairs(lb) do given = given + CELLS[c].price end
    if o.ga - o.gb >= SWEET * given and #lb > 0 then return { k = "yes", s = s } end
    local sum = o.ga - o.gb + CARD_V * (#o.ja - #o.jb)
    for _, c in ipairs(la) do
        sum = sum + value(S, s, c)
        if S.mort[c] then sum = sum - R.LiftCost(c) end
    end
    for _, c in ipairs(lb) do sum = sum - value(S, s, c) end
    return { k = sum > 0 and "yes" or "no", s = s }
end
function R.Bot(S, s)
    if S.over or not S.alive[s] then return nil end
    local who = R.Waiting(S)
    if who ~= s then return nil end
    local ph = S.phase
    local rsv = reserve(S, s)
    if ph == "pre" then
        local m = buildMove(S, s, rsv)
        if m then return m end
        if S.jail[s] > 0 and not S.rolled then
            if jailBuilt(S, s) then return { k = "roll", s = s } end
            if S.free[s] ~= "" then return { k = "free", s = s } end
            if S.cash[s] - 50 >= rsv and S.cash[s] >= 50 then return { k = "bail", s = s } end
        end
        return { k = "roll", s = s }
    end
    if ph == "buy" then
        local c = S.buyAt
        local price = CELLS[c].price
        if S.cash[s] >= price and ((completesOwn(S, s, c) or blocks(S, s, c)) or S.cash[s] - price >= rsv) then
            return { k = "buy", s = s }
        end
        return { k = "skip", s = s }
    end
    if ph == "auction" then
        local a = S.auc
        local c = a.c
        local limit = min(value(S, s, c), S.cash[s] - rsv)
        local step = (limit - a.bid < 50) and 10 or max(10, floor(CELLS[c].price / 100 + 0.5) * 10)
        local nextBid = a.bid + step
        if nextBid <= limit and nextBid <= S.cash[s] then return { k = "bid", s = s, v = nextBid } end
        return { k = "pass", s = s }
    end
    if ph == "post" then
        local m = liftMove(S, s, rsv)
        if m then return m end
        m = offerMove(S, s)
        if m then return m end
        return { k = "end", s = s }
    end
    if ph == "debt" then return debtMove(S, s) end
    if ph == "trade" then return answer(S, s) end
    if ph == "lien" then
        local c = S.liens[1].c
        local cost = R.LiftCost(c)
        if S.cash[s] >= cost and S.cash[s] - cost >= rsv then return { k = "lien", s = s, v = 1 } end
        return { k = "lien", s = s, v = 0 }
    end
    return nil
end
