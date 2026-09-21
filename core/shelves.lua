local ADDON, ns = ...
ns.Shelves = {}
local NO_THEME = "?"
local function themeKey(game)
    return ns.Shelves.Theme(game) or NO_THEME
end
ns.shelvesDB = ns.shelvesDB or {}
ns.shelfDB = ns.shelfDB or {}
ns.shelfOrder = ns.shelfOrder or {}
function ns.RegisterShelves(id, def)
    if type(id) ~= "string" or type(def) ~= "table" then return end
    ns.shelvesDB[id] = def
end
function ns.RegisterShelfData(id, key, label, tbl, colours, stamp)
    if type(id) ~= "string" or type(key) ~= "string" or type(tbl) ~= "table" then
        return
    end
    ns.shelfDB[id] = ns.shelfDB[id] or {}
    if not ns.shelfDB[id][key] then
        ns.shelfOrder[id] = ns.shelfOrder[id] or {}
        local o = ns.shelfOrder[id]
        o[#o + 1] = key
    end
    ns.shelfDB[id][key] = { key = key, label = label or key,
                            shelves = tbl, colours = colours or {}, stamp = stamp }
end
function ns.Shelves.Colour(game, shelf)
    local theme = themeKey(game)
    local db = ns.Store.DB().shelfColour
    db = db and db[game] and db[game][theme]
    if db and db[shelf] then
        return (db[shelf] ~= "") and db[shelf] or nil
    end
    local t = (ns.shelfDB[game] or {})[theme]
    return t and t.colours and t.colours[shelf]
end
function ns.Shelves.SetColour(game, shelf, colour)
    local theme = themeKey(game)
    local db = ns.Store.DB()
    db.shelfColour = db.shelfColour or {}
    db.shelfColour[game] = db.shelfColour[game] or {}
    db.shelfColour[game][theme] = db.shelfColour[game][theme] or {}
    db.shelfColour[game][theme][shelf] = colour or ""
    ns.Shelves.stamp = ns.Shelves.stamp + 1
end
function ns.Shelves.Themes(game)
    local out = {}
    for _, key in ipairs(ns.shelfOrder[game] or {}) do
        local t = ns.shelfDB[game] and ns.shelfDB[game][key]
        if t then out[#out + 1] = { key = t.key, label = ns.TL(t.label) } end
    end
    return out
end
function ns.Shelves.Filled(game, key)
    local t = (ns.shelfDB[game] or {})[key or ""]
    for _, list in pairs(t and t.shelves or {}) do
        if #list > 0 then return true end
    end
    local box = ns.Store.DB().shelf
    box = box and box[game] and box[game][key or NO_THEME]
    for _, list in pairs(box or {}) do
        if #list > 0 then return true end
    end
    return false
end
function ns.Shelves.Theme(game)
    local db = ns.Store.DB()
    local want = db.shelfTheme and db.shelfTheme[game]
    if want and ns.shelfDB[game] and ns.shelfDB[game][want] then return want end
    local first = (ns.shelfOrder[game] or {})[1]
    return first
end
function ns.Shelves.SetTheme(game, key)
    local db = ns.Store.DB()
    db.shelfTheme = db.shelfTheme or {}
    db.shelfTheme[game] = key
    ns.Shelves.stamp = ns.Shelves.stamp + 1
end
ns.Shelves.stamp = 1
function ns.Shelves.List(game)
    local def = (ns.shelvesDB or {})[game]
    return (def and def.shelves) or {}
end
function ns.Shelves.Label(game)
    local def = (ns.shelvesDB or {})[game]
    return (def and def.label) or tostring(game)
end
function ns.Shelves.Games()
    local out = {}
    for id in pairs(ns.shelvesDB or {}) do out[#out + 1] = id end
    table.sort(out)
    return out
end
function ns.Shelves.Known(game, shelf)
    for _, sh in ipairs(ns.Shelves.List(game)) do
        if sh.key == shelf then return true end
    end
    return false
end
local function store()
    local db = ns.Store.DB()
    db.shelf = db.shelf or {}
    return db.shelf
end
local function override(game, shelf)
    local box = store()[game]
    box = box and box[themeKey(game)]
    return box and box[shelf]
end
local function baked(game, shelf)
    local t = (ns.shelfDB[game] or {})[themeKey(game)]
    return (t and t.shelves[shelf]) or {}
end
local function edit(game, shelf)
    local theme = themeKey(game)
    local box = store()
    box[game] = box[game] or {}
    box[game][theme] = box[game][theme] or {}
    if not box[game][theme][shelf] then
        local copy = {}
        for i, name in ipairs(baked(game, shelf)) do copy[i] = name end
        box[game][theme][shelf] = copy
    end
    return box[game][theme][shelf]
end
function ns.Shelves.Get(game, shelf)
    if not game or not shelf then return {} end
    return override(game, shelf) or baked(game, shelf)
end
function ns.Shelves.Count(game, shelf)
    return #ns.Shelves.Get(game, shelf)
end
function ns.Shelves.Map(game)
    local out = {}
    for _, sh in ipairs(ns.Shelves.List(game)) do
        for _, name in ipairs(ns.Shelves.Get(game, sh.key)) do
            out[name:lower()] = sh.label
        end
    end
    return out
end
function ns.Shelves.Add(game, shelf, name)
    if type(name) ~= "string" then return false end
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return false end
    if not ns.Shelves.Known(game, shelf) then return false end
    local b = edit(game, shelf)
    for i = 1, #b do
        if b[i]:lower() == name:lower() then return false end
    end
    b[#b + 1] = name
    ns.Shelves.stamp = ns.Shelves.stamp + 1
    return true
end
function ns.Shelves.Remove(game, shelf, name)
    local b = edit(game, shelf)
    for i = 1, #b do
        if b[i]:lower() == name:lower() then
            table.remove(b, i)
            ns.Shelves.stamp = ns.Shelves.stamp + 1
            return true
        end
    end
    return false
end
function ns.Shelves.Clear(game, shelf)
    local b = edit(game, shelf)
    for i = #b, 1, -1 do b[i] = nil end
    ns.Shelves.stamp = ns.Shelves.stamp + 1
end
function ns.Shelves.Reset(game, shelf)
    local box = store()[game]
    box = box and box[themeKey(game)]
    if box then box[shelf] = nil end
    ns.Shelves.stamp = ns.Shelves.stamp + 1
end
local function moveColours(game, live)
    local db = ns.Store.DB().shelfColour
    local byTheme = db and db[game]
    local draft = byTheme and byTheme[NO_THEME]
    if not draft then return end
    byTheme[NO_THEME] = nil
    byTheme[live] = byTheme[live] or {}
    for shelf, colour in pairs(draft) do
        if byTheme[live][shelf] == nil then byTheme[live][shelf] = colour end
    end
end
function ns.Shelves.Prune()
    local box = store()
    local kept = 0
    for game, byTheme in pairs(box) do
        local moved
        for k, v in pairs(byTheme) do
            if type(v) == "table" and type(v[1]) == "string" then
                moved = moved or {}
                moved[k] = v
                byTheme[k] = nil
            end
        end
        if moved then
            local theme = themeKey(game)
            byTheme[theme] = byTheme[theme] or {}
            for k, v in pairs(moved) do byTheme[theme][k] = v end
        end
        local draft = byTheme[NO_THEME]
        local live = themeKey(game)
        if draft and live ~= NO_THEME then
            byTheme[NO_THEME] = nil
            byTheme[live] = byTheme[live] or {}
            for shelf, list in pairs(draft) do
                if byTheme[live][shelf] == nil then byTheme[live][shelf] = list end
            end
            moveColours(game, live)
        end
        for theme, shelves in pairs(byTheme) do
            if theme ~= NO_THEME
                and not (ns.shelfDB[game] and ns.shelfDB[game][theme]) then
                byTheme[theme] = nil
                shelves = {}
            end
            for shelf, list in pairs(shelves) do
                if not ns.Shelves.Known(game, shelf) then
                    shelves[shelf] = nil
                else
                    local t = (ns.shelfDB[game] or {})[theme]
                    local ref = (t and t.shelves[shelf]) or {}
                    local same = (#ref == #list)
                    if same then
                        for i = 1, #ref do
                            if ref[i]:lower() ~= list[i]:lower() then
                                same = false
                                break
                            end
                        end
                    end
                    if same then shelves[shelf] = nil else kept = kept + 1 end
                end
            end
        end
    end
    return kept
end
function ns.Shelves.Settle()
    local db = ns.Store.DB()
    db.shelfStamp = db.shelfStamp or {}
    for game, themes in pairs(ns.shelfDB) do
        for theme, t in pairs(themes) do
            if type(t.stamp) == "number" then
                local seen = db.shelfStamp[game] and db.shelfStamp[game][theme]
                if seen ~= t.stamp then
                    if db.shelf and db.shelf[game] then db.shelf[game][theme] = nil end
                    if db.shelfColour and db.shelfColour[game] then
                        db.shelfColour[game][theme] = nil
                    end
                    db.shelfStamp[game] = db.shelfStamp[game] or {}
                    db.shelfStamp[game][theme] = t.stamp
                    ns.Shelves.stamp = (ns.Shelves.stamp or 0) + 1
                end
            end
        end
    end
end
local tintMap
local function buildTint()
    tintMap = {}
    for cat, list in pairs(ns.poolDB or {}) do
        local colour = cat:match("^gem/(.+)$")
        if colour then
            for _, name in ipairs(list) do tintMap[name:lower()] = colour end
        end
    end
end
function ns.Shelves.Tint(name)
    if type(name) ~= "string" then return nil end
    if not tintMap then buildTint() end
    local colour = tintMap[name:lower()]
    if not colour then return nil end
    local r, g, b = ns.Palette.RGB(colour)
    if r == 1 and g == 1 and b == 1 then return nil end
    return r, g, b
end
local MIN_DIST = 250
local function colourDist(a, b)
    local rm = (a[1] + b[1]) / 2 * 255
    local dr, dg, db = (a[1] - b[1]) * 255, (a[2] - b[2]) * 255, (a[3] - b[3]) * 255
    return math.sqrt((2 + rm / 256) * dr * dr + 4 * dg * dg
                     + (2 + (255 - rm) / 256) * db * db)
end
function ns.Shelves.ShelfTint(game, shelf)
    local own = ns.Shelves.Colour(game, shelf)
    if own then
        local r, g, b = ns.Palette.RGB(own)
        if not (r == 1 and g == 1 and b == 1) then return { r, g, b } end
    end
    local count, best, bestN = {}, nil, 0
    for _, name in ipairs(ns.Shelves.Get(game, shelf)) do
        local r, g, b = ns.Shelves.Tint(name)
        if r then
            local k = ("%.3f/%.3f/%.3f"):format(r, g, b)
            count[k] = (count[k] or 0) + 1
            if count[k] > bestN then best, bestN = { r, g, b }, count[k] end
        end
    end
    return best
end
function ns.Shelves.Pick(game, shelf, rng)
    local list = ns.Shelves.Get(game, shelf)
    if #list == 0 then return nil end
    if #list == 1 then return list[1] end
    return rng:Pick(list)
end
function ns.Shelves.Deal(game, n, rng)
    local all = {}
    for _, sh in ipairs(ns.Shelves.List(game)) do
        if not sh.role then all[#all + 1] = sh end
    end
    if #all == 0 then return {} end
    rng:Shuffle(all)
    local out, tints = {}, {}
    local skipped = {}
    for _, sh in ipairs(all) do
        if #out >= n then break end
        if ns.Shelves.Count(game, sh.key) > 0 then
            local t = ns.Shelves.ShelfTint(game, sh.key)
            local ok = true
            if t then
                for _, u in ipairs(tints) do
                    if colourDist(t, u) < MIN_DIST then ok = false; break end
                end
            end
            if ok then
                out[#out + 1] = sh
                if t then tints[#tints + 1] = t end
            else
                skipped[#skipped + 1] = sh
            end
        end
    end
    for _, sh in ipairs(skipped) do
        if #out >= n then break end
        out[#out + 1] = sh
    end
    return out
end
