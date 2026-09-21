local ADDON, ns = ...
ns.mines = ns.mines or {}
local G = ns.mines
local floor = math.floor
G.CAP = 8
local nbCache = {}
function G.Neighbors(cols, rows)
    local key = cols .. "x" .. rows
    local nb = nbCache[key]
    if nb then return nb end
    nb = {}
    for i = 1, cols * rows do
        local c = (i - 1) % cols + 1
        local r = floor((i - 1) / cols) + 1
        local list = {}
        for dr = -1, 1 do
            for dc = -1, 1 do
                if not (dr == 0 and dc == 0) then
                    local rr, cc = r + dr, c + dc
                    if rr >= 1 and rr <= rows and cc >= 1 and cc <= cols then
                        list[#list + 1] = (rr - 1) * cols + cc
                    end
                end
            end
        end
        nb[i] = list
    end
    nbCache[key] = nb
    return nb
end
local function lay(rng, cols, rows, mines, first, nb)
    local n = cols * rows
    local safe = {}
    safe[first] = true
    for _, j in ipairs(nb[first]) do safe[j] = true end
    local free = {}
    for i = 1, n do
        if not safe[i] then free[#free + 1] = i end
    end
    if #free < mines then
        free = {}
        for i = 1, n do
            if i ~= first then free[#free + 1] = i end
        end
    end
    local m = mines
    if m > #free then m = #free end
    local mine = {}
    for k = 1, m do
        local j = rng:Int(k, #free)
        free[k], free[j] = free[j], free[k]
        mine[free[k]] = true
    end
    local near = {}
    for i = 1, n do
        local k = 0
        if not mine[i] then
            for _, j in ipairs(nb[i]) do
                if mine[j] then k = k + 1 end
            end
        end
        near[i] = k
    end
    return mine, near, m
end
local UNKNOWN, OPENED, KNOWN = 0, 1, 2
local function solvable(mine, near, cols, rows, laid, first, nb)
    local n = cols * rows
    local safeCells = n - laid
    local st = {}
    for i = 1, n do st[i] = UNKNOWN end
    local opened, known = 0, 0
    local stack = {}
    local function open(i)
        if st[i] ~= UNKNOWN then return end
        st[i] = OPENED
        opened = opened + 1
        if near[i] ~= 0 then return end
        local top = 0
        for _, j in ipairs(nb[i]) do top = top + 1; stack[top] = j end
        while top > 0 do
            local k = stack[top]
            top = top - 1
            if st[k] == UNKNOWN then
                st[k] = OPENED
                opened = opened + 1
                if near[k] == 0 then
                    for _, j in ipairs(nb[k]) do top = top + 1; stack[top] = j end
                end
            end
        end
    end
    local function mark(i)
        if st[i] ~= UNKNOWN then return end
        st[i] = KNOWN
        known = known + 1
    end
    open(first)
    while true do
        if opened >= safeCells then return true end
        local moved = false
        local cu, cr, cn = {}, {}, 0
        for i = 1, n do
            if st[i] == OPENED and near[i] > 0 then
                local rem = near[i]
                local u, un = {}, 0
                for _, j in ipairs(nb[i]) do
                    if st[j] == KNOWN then rem = rem - 1
                    elseif st[j] == UNKNOWN then un = un + 1; u[un] = j end
                end
                if un > 0 then
                    if rem == 0 then
                        for k = 1, un do open(u[k]) end
                        moved = true
                    elseif rem == un then
                        for k = 1, un do mark(u[k]) end
                        moved = true
                    else
                        cn = cn + 1; cu[cn] = u; cr[cn] = rem
                    end
                end
            end
        end
        if not moved then
            for a = 1, cn do
                local ua, ra = cu[a], cr[a]
                for b = 1, cn do
                    local ub = cu[b]
                    if b ~= a and #ua < #ub then
                        local inB = {}
                        for _, j in ipairs(ub) do inB[j] = true end
                        local sub = true
                        for _, j in ipairs(ua) do
                            if not inB[j] then sub = false; break end
                        end
                        if sub then
                            local inA = {}
                            for _, j in ipairs(ua) do inA[j] = true end
                            local diff, dn = {}, 0
                            for _, j in ipairs(ub) do
                                if not inA[j] then dn = dn + 1; diff[dn] = j end
                            end
                            local rd = cr[b] - ra
                            if rd == 0 then
                                for k = 1, dn do open(diff[k]) end
                                moved = true
                            elseif rd == dn then
                                for k = 1, dn do mark(diff[k]) end
                                moved = true
                            end
                        end
                    end
                    if moved then break end
                end
                if moved then break end
            end
        end
        if not moved then
            local left = laid - known
            local unk, un = {}, 0
            for i = 1, n do
                if st[i] == UNKNOWN then un = un + 1; unk[un] = i end
            end
            if un > 0 and left == 0 then
                for k = 1, un do open(unk[k]) end
                moved = true
            elseif un > 0 and left == un then
                for k = 1, un do mark(unk[k]) end
                moved = true
            end
        end
        if not moved then return false end
    end
end
G.Solvable = solvable
function G.Build(rng, cols, rows, mines, first)
    local nb = G.Neighbors(cols, rows)
    local mine, near, laid
    for k = 1, G.CAP do
        mine, near, laid = lay(rng, cols, rows, mines, first, nb)
        if solvable(mine, near, cols, rows, laid, first, nb) then
            return mine, near, laid, k
        end
    end
    return mine, near, laid, G.CAP
end
