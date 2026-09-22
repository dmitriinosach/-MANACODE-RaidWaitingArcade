local ADDON, ns = ...
ns.Music = {}
local BS = string.char(92)
function ns.Music.Sets()
    local out = {}
    for _, key in ipairs(ns.musicOrder or {}) do
        local s = (ns.musicSets or {})[key]
        if s then
            out[#out + 1] = { key = key, label = s.label or key, kind = s.kind,
                              n = #((ns.musicDB or {})[key] or {}) }
        end
    end
    return out
end
function ns.Music.List(key)
    return (ns.musicDB or {})[key or ""] or {}
end
local index, indexSet
local function build()
    if index then return end
    index, indexSet = {}, {}
    for _, key in ipairs(ns.musicOrder or {}) do
        for _, e in ipairs(ns.Music.List(key)) do
            local low = e.p:lower()
            index[low] = e
            indexSet[low] = key
        end
    end
end
function ns.Music.Find(p)
    if type(p) ~= "string" or p == "" then return nil end
    build()
    local low = p:lower()
    return index[low], indexSet[low]
end
function ns.Music.Label(p)
    if type(p) ~= "string" then return "" end
    local name = p:match("[^\\/]+$") or p
    return (name:gsub("%.[Mm][Pp]3$", ""):gsub("%.[Oo][Gg][Gg]$", ""):gsub("%.[Ww][Aa][Vv]$", ""))
end
function ns.Music.Where(p)
    local _, key = ns.Music.Find(p)
    local s = key and (ns.musicSets or {})[key]
    return s and s.label or key
end
local playing
local stopTicker
local function raw(p)
    if type(p) ~= "string" or p == "" then return false end
    if not ns.Compat.PlayMusic(p) then return false end
    playing = p
    return true
end
function ns.Music.Play(p)
    if stopTicker then stopTicker() end
    return raw(p)
end
function ns.Music.Stop()
    if stopTicker then stopTicker() end
    playing = nil
    ns.Compat.StopMusic()
end
function ns.Music.Playing()
    return playing
end
function ns.Music.Muted()
    if type(GetCVar) ~= "function" then return nil end
    if GetCVar("Sound_EnableAllSound") == "0" then return "звук выключен в самом клиенте" end
    if GetCVar("Sound_EnableMusic") == "0" then return "музыка выключена в самом клиенте" end
    local v = tonumber(GetCVar("Sound_MasterVolume") or "")
    if v and v <= 0 then return "общая громкость клиента на нуле" end
    v = tonumber(GetCVar("Sound_MusicVolume") or "")
    if v and v <= 0 then return "громкость музыки на нуле" end
    return nil
end
function ns.Music.Volume()
    if type(GetCVar) ~= "function" then return 1 end
    local held = ns.Sfx and ns.Sfx.BaseOf and ns.Sfx.BaseOf("Sound_MusicVolume")
    if held then return held end
    return tonumber(GetCVar("Sound_MusicVolume") or "") or 1
end
function ns.Music.SetVolume(v)
    if type(SetCVar) ~= "function" then return end
    if ns.Sfx and ns.Sfx.Rebase and ns.Sfx.Rebase("Sound_MusicVolume", v) then return end
    SetCVar("Sound_MusicVolume", tostring(v))
end
local function banBox()
    local db = ns.Store.DB()
    db.musicBan = db.musicBan or {}
    return db.musicBan
end
local function banKey(p)
    return (p:match("[^\\/]+$") or p):lower()
end
function ns.Music.Banned(p)
    if type(p) ~= "string" or p == "" then return false end
    return banBox()[banKey(p)] ~= nil
end
function ns.Music.Ban(p)
    if type(p) ~= "string" or p == "" then return false end
    local box = banBox()
    local k = banKey(p)
    if box[k] then return false end
    box[k] = p
    return true
end
function ns.Music.Unban(p)
    if type(p) ~= "string" or p == "" then return end
    banBox()[banKey(p)] = nil
end
function ns.Music.BanList()
    local keys = {}
    local box = banBox()
    for k in pairs(box) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for i = 1, #keys do out[i] = box[keys[i]] end
    return out
end
function ns.Music.BanCount()
    local n = 0
    for _ in pairs(banBox()) do n = n + 1 end
    return n
end
local function offBox()
    local db = ns.Store.DB()
    db.musicCatOff = db.musicCatOff or {}
    return db.musicCatOff
end
function ns.Music.CatOff(key)
    if type(key) ~= "string" then return false end
    local v = offBox()[key]
    if v ~= nil then return v == true end
    local s = (ns.musicSets or {})[key]
    return (s and s.off) and true or false
end
function ns.Music.SetCatOff(key, off)
    if type(key) ~= "string" then return end
    local s = (ns.musicSets or {})[key]
    local baked = (s and s.off) and true or false
    off = off and true or false
    if off == baked then offBox()[key] = nil else offBox()[key] = off end
end
function ns.Music.CatOffCount()
    local n = 0
    for _, s in ipairs(ns.Music.Sets()) do
        if ns.Music.CatOff(s.key) then n = n + 1 end
    end
    return n
end
local function shelfBox()
    local db = ns.Store.DB()
    db.musicShelf = db.musicShelf or {}
    return db.musicShelf
end
local function own(key)
    for _, sh in ipairs(shelfBox()) do
        if sh.key == key then return sh end
    end
    return nil
end
local function gone(key)
    local db = ns.Store.DB()
    return (db.musicShelfGone or {})[key] == true
end
local function baked(key)
    if gone(key) then return nil end
    local sh = (ns.musicShelves or {})[key]
    if not sh then return nil end
    return { key = key, label = ns.HasT("musShelf_" .. key) and ns.T("musShelf_" .. key) or sh.label or key, list = sh.list or {} }
end
function ns.Music.Shelves()
    local out, seen = {}, {}
    for _, key in ipairs(ns.musicShelfOrder or {}) do
        local sh = own(key) or baked(key)
        if sh and not seen[key] then
            seen[key] = true
            out[#out + 1] = { key = key, label = sh.label, n = #sh.list, baked = own(key) == nil }
        end
    end
    for _, sh in ipairs(shelfBox()) do
        if not seen[sh.key] then
            seen[sh.key] = true
            out[#out + 1] = { key = sh.key, label = sh.label, n = #(sh.list or {}), baked = false }
        end
    end
    return out
end
function ns.Music.ShelfList(key)
    if type(key) ~= "string" then return {} end
    local sh = own(key) or baked(key)
    return sh and sh.list or {}
end
function ns.Music.ShelfLabel(key)
    if type(key) ~= "string" then return nil end
    local sh = own(key) or baked(key)
    return sh and sh.label or nil
end
function ns.Music.AddShelf(label)
    if type(label) ~= "string" or label:match("^%s*$") then return nil end
    local db = ns.Store.DB()
    db.musicShelfSeq = (db.musicShelfSeq or 0) + 1
    local key = "m" .. db.musicShelfSeq
    while own(key) or (ns.musicShelves or {})[key] do
        db.musicShelfSeq = db.musicShelfSeq + 1
        key = "m" .. db.musicShelfSeq
    end
    local box = shelfBox()
    box[#box + 1] = { key = key, label = label:gsub("^%s+", ""):gsub("%s+$", ""), list = {} }
    return key
end
function ns.Music.RemoveShelf(key)
    local box = shelfBox()
    for i = #box, 1, -1 do
        if box[i].key == key then table.remove(box, i) end
    end
    if (ns.musicShelves or {})[key] then
        local db = ns.Store.DB()
        db.musicShelfGone = db.musicShelfGone or {}
        db.musicShelfGone[key] = true
    end
end
local function editable(key)
    local sh = own(key)
    if sh then return sh end
    local b = baked(key)
    if not b then return nil end
    local copy = { key = key, label = b.label, list = {} }
    for i, p in ipairs(b.list) do copy.list[i] = p end
    local box = shelfBox()
    box[#box + 1] = copy
    return copy
end
function ns.Music.Has(key, p)
    if type(p) ~= "string" then return false end
    local low = p:lower()
    for _, q in ipairs(ns.Music.ShelfList(key)) do
        if q:lower() == low then return true end
    end
    return false
end
function ns.Music.Toggle(key, p)
    if type(key) ~= "string" or type(p) ~= "string" or p == "" then return nil end
    local sh = editable(key)
    if not sh then return nil end
    local low = p:lower()
    for i, q in ipairs(sh.list) do
        if q:lower() == low then
            table.remove(sh.list, i)
            return false
        end
    end
    sh.list[#sh.list + 1] = p
    return true
end
function ns.Music.Put(key, p)
    if ns.Music.Has(key, p) then return false end
    return ns.Music.Toggle(key, p) == true
end
function ns.Music.ShelvesOf(p)
    local out = {}
    for _, sh in ipairs(ns.Music.Shelves()) do
        if ns.Music.Has(sh.key, p) then out[#out + 1] = sh.label end
    end
    return out
end
local FADE = 2
local ticker, left, order, at
local function shuffled(list)
    local out = {}
    for i, p in ipairs(list) do out[i] = p end
    for i = #out, 2, -1 do
        local j = math.random(i)
        out[i], out[j] = out[j], out[i]
    end
    return out
end
function ns.Music.On()
    return ns.Store.DB().musicOn == true
end
function ns.Music.Live()
    return ns.Music.On() and ns.Store.Sound()
end
function ns.Music.Pick()
    local key = ns.Store.DB().musicPick
    if type(key) == "string" and #ns.Music.ShelfList(key) > 0 then return key end
    for _, sh in ipairs(ns.Music.Shelves()) do
        if sh.n > 0 then return sh.key end
    end
    return nil
end
function ns.Music.SetPick(key)
    ns.Store.DB().musicPick = key
    if ns.Music.On() then ns.Music.Restart() end
end
function ns.Music.NextShelf()
    local list = {}
    for _, sh in ipairs(ns.Music.Shelves()) do
        if sh.n > 0 then list[#list + 1] = sh.key end
    end
    if #list == 0 then return nil end
    local now = ns.Music.Pick()
    local i = 1
    for k, key in ipairs(list) do
        if key == now then i = k % #list + 1 end
    end
    ns.Music.SetPick(list[i])
    return list[i]
end
stopTicker = function()
    if ticker then ticker:Hide() end
    order, at, left = nil, nil, nil
end
local function playNext()
    if not order or #order == 0 then return false end
    at = (at or 0) + 1
    if at > #order then
        order = shuffled(order)
        at = 1
    end
    local p = order[at]
    local e = ns.Music.Find(p)
    left = (e and e.sec or 90) + FADE
    return raw(p)
end
local function ensureTicker()
    if ticker then return end
    ticker = ns.NewFrame("Frame", nil, UIParent)
    ticker:Hide()
    ticker:SetScript("OnUpdate", function(_, dt)
        if not left then return end
        left = left - dt
        if left > 0 then return end
        if not playNext() then stopTicker() end
    end)
end
function ns.Music.Restart()
    if not ns.Store.Sound() then
        ns.Music.Stop()
        return false
    end
    local key = ns.Music.Pick()
    local list = {}
    for _, p in ipairs(ns.Music.ShelfList(key)) do
        if not ns.Music.Banned(p) then list[#list + 1] = p end
    end
    if #list == 0 then
        ns.Music.Stop()
        stopTicker()
        return false
    end
    ensureTicker()
    order, at = shuffled(list), 0
    if not playNext() then
        stopTicker()
        return false
    end
    ticker:Show()
    return true
end
function ns.Music.Skip()
    if not order then return ns.Music.Restart() end
    ensureTicker()
    if not playNext() then
        stopTicker()
        return false
    end
    ticker:Show()
    return true
end
function ns.Music.SetOn(on)
    on = on and true or false
    ns.Store.DB().musicOn = on
    if on then
        ns.Music.Restart()
    else
        stopTicker()
        ns.Music.Stop()
    end
end
function ns.Music.Hush()
    if not order then return end
    stopTicker()
    ns.Music.Stop()
end
function ns.Music.Resume()
    if not ns.Music.Live() then return end
    if order then return end
    if ns.window and not ns.window:IsShown() then return end
    ns.Music.Restart()
end
