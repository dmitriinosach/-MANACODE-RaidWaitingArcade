local ADDON, ns = ...
local MAX_MOVES = 2000
local warned = {}
local MAX_RECORDS = 10
ns.Store = {}
local function charKey()
    local name = UnitName("player") or "?"
    local realm = GetRealmName() or "?"
    return name .. "-" .. realm
end
local function ensure()
    RaidWaitingArcadeDB = RaidWaitingArcadeDB or {}
    local db = RaidWaitingArcadeDB
    db.version = db.version or 1
    if db.sound == nil then db.sound = false end
    db.pos = db.pos or {}
    db.skins = db.skins or {}
    db.chars = db.chars or {}
    local key = charKey()
    db.chars[key] = db.chars[key] or {}
    local ch = db.chars[key]
    ch.saved = ch.saved or {}
    ch.records = ch.records or {}
    return db, ch
end
function ns.Store.Init()
    ensure()
end
function ns.Store.DB()
    local db = ensure()
    return db
end
function ns.Store.Char()
    local _, ch = ensure()
    return ch
end
local function slot(id, opts)
    local def = (ns.games or {})[id or ""]
    local axis = def and def.saves
    if type(axis) == "string" then axis = { axis } end
    if type(axis) ~= "table" then return id end
    local last, key = nil, id
    for i = 1, #axis do
        local k = axis[i]
        local v = opts and opts[k]
        if v == nil then
            if last == nil then last = ns.Store.LastOpts(id) or false end
            v = last and last[k]
        end
        if v == nil then return id end
        key = key .. "#" .. tostring(v)
    end
    return key
end
function ns.Store.Save(id, seed, moves, opts)
    local ch = ns.Store.Char()
    local n = #moves
    if n > MAX_MOVES and not warned[id] then
        warned[id] = true
        ns.say(("партия %s набрала %d ходов при ориентире %d — сохраняю целиком, но столько ходов в короткой партии быть не должно.")
            :format(id, n, MAX_MOVES))
    end
    local key = slot(id, opts)
    local prev = ch.saved[key]
    ch.saved[key] = { seed = seed, moves = moves, opts = opts, at = time(),
        duo = prev and prev.duo or nil }
end
function ns.Store.SetDuo(id, blk)
    local rec = ns.Store.Char().saved[slot(id, nil)]
    if rec then rec.duo = blk end
end
function ns.Store.Duo(id)
    local rec = ns.Store.Char().saved[slot(id, nil)]
    return rec and rec.duo or nil
end
function ns.Store.Load(id, opts)
    return ns.Store.Char().saved[slot(id, opts)]
end
function ns.Store.Num(v, lo, hi, def)
    v = tonumber(v)
    if not v then return def end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end
function ns.Store.Clear(id, opts)
    ns.Store.Char().saved[slot(id, opts)] = nil
end
function ns.Store.HasSaved(id, opts)
    return ns.Store.Char().saved[slot(id, opts)] ~= nil
end
function ns.Store.WipeGame(id)
    if type(id) ~= "string" or id == "" then return end
    local db, ch = ensure()
    ch.saved[id] = nil
    for key in pairs(ch.saved) do
        if key:sub(1, #id + 1) == id .. "#" then ch.saved[key] = nil end
    end
    ch.records[id] = nil
    if ch.lastOpts then ch.lastOpts[id] = nil end
    if ch.config then ch.config[id] = nil end
    if type(ch[id]) == "table" then ch[id] = nil end
    db.skins[id] = nil
    if db.shelf then db.shelf[id] = nil end
    if db.shelfTheme then db.shelfTheme[id] = nil end
    if db.shelfColour then db.shelfColour[id] = nil end
    if db.sfx then db.sfx[id] = nil end
    if ns.Shelves then ns.Shelves.stamp = (ns.Shelves.stamp or 0) + 1 end
end
local function optsKey(opts)
    if not opts then return "" end
    local keys = {}
    for k in pairs(opts) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. tostring(opts[k]) end
    return table.concat(parts, ",")
end
ns.Store.OptsKey = optsKey
function ns.Store.RecList(id)
    local ch = ns.Store.Char()
    ch.records[id] = ch.records[id] or {}
    return ch.records[id]
end
function ns.Store.Push(id, rec, better)
    local list = ns.Store.RecList(id)
    tinsert(list, rec)
    table.sort(list, better)
    local seen, keep = {}, {}
    for _, r in ipairs(list) do
        seen[r.opts] = (seen[r.opts] or 0) + 1
        if seen[r.opts] <= MAX_RECORDS then keep[#keep + 1] = r end
    end
    ns.Store.Char().records[id] = keep
end
function ns.Store.Sound()
    return ns.Store.DB().sound and true or false
end
function ns.Store.SetSound(on)
    on = on and true or false
    ns.Store.DB().sound = on
    if not ns.Music then return end
    if on then ns.Music.Resume() else ns.Music.Hush() end
end
function ns.Store.CombatClose()
    local db = ns.Store.DB()
    if db.combatClose == nil then db.combatClose = true end
    return db.combatClose and true or false
end
function ns.Store.SetCombatClose(on)
    ns.Store.DB().combatClose = on and true or false
end
function ns.Store.Minimap()
    return not ns.Store.DB().mmHide
end
function ns.Store.SetMinimap(on)
    ns.Store.DB().mmHide = not on or nil
    if ns.Launch then ns.Launch.Sync() end
end
function ns.Store.Launcher()
    return ns.Store.DB().launcher and true or false
end
function ns.Store.SetLauncher(on)
    ns.Store.DB().launcher = on and true or nil
    if ns.Launch then ns.Launch.Sync() end
end
function ns.Store.SeeThrough()
    return ns.Store.DB().seeThrough and true or false
end
function ns.Store.SetSeeThrough(on)
    ns.Store.DB().seeThrough = on and true or false
    ns.window:RefreshCanvasBg()
end
function ns.Store.Scale()
    local v = ns.Store.DB().uiScale
    if v == "full" then return v end
    return tonumber(v) or 100
end
function ns.Store.SetScale(pct)
    ns.Store.DB().uiScale = pct
    if ns.window and ns.window.ApplyScale then ns.window:ApplyScale() end
end
function ns.Store.RememberOpts(id, opts)
    local ch = ns.Store.Char()
    ch.lastOpts = ch.lastOpts or {}
    ch.lastOpts[id] = opts
end
function ns.Store.LastOpts(id)
    local ch = ns.Store.Char()
    return ch.lastOpts and ch.lastOpts[id] or nil
end
function ns.Store.Skin(id)
    return ns.Store.DB().skins[id]
end
function ns.Store.SetSkin(id, key)
    ns.Store.DB().skins[id] = key
end
