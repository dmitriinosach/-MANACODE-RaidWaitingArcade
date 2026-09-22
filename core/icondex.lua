local ADDON, ns = ...
ns.IconDex = {}
local ICON_DIR = "Interface\\Icons\\"
ns.IconDex.stamp = 1
local function store()
    local db = ns.Store.DB()
    db.icondex = db.icondex or { v = 1, item = {} }
    db.icondex.item = db.icondex.item or {}
    return db.icondex.item
end
local function short(path)
    if type(path) ~= "string" then return path end
    local name = path:match("[^\\/]+$")
    return name or path
end
local function full(name)
    if type(name) ~= "string" then return name end
    if name:find("\\", 1, true) then return name end
    return ICON_DIR .. name
end
function ns.IconDex.Item(id)
    local cache = store()
    local was = cache[id]
    if was then return full(was) end
    local tex = ns.Compat.ItemIcon(id)
    if not tex then
        return nil
    end
    cache[id] = short(tex)
    ns.IconDex.stamp = ns.IconDex.stamp + 1
    return tex
end
function ns.IconDex.Learn(id, tex)
    if type(id) ~= "number" or type(tex) ~= "string" or tex == "" then return false end
    local cache = store()
    if cache[id] then return false end
    cache[id] = short(tex)
    ns.IconDex.stamp = ns.IconDex.stamp + 1
    return true
end
function ns.IconDex.Spell(id)
    local tex = ns.Compat.SpellIcon(id)
    return tex
end
function ns.IconDex.Of(kind, v)
    if kind == "spell" then return ns.IconDex.Spell(v) end
    if kind == "tex" then return v end
    return ns.IconDex.Item(v)
end
local pending = {}
local known = {}
local cursor = 1
local function remember(kind, v)
    local key = kind .. ":" .. tostring(v)
    if known[key] then return end
    known[key] = true
    pending[#pending + 1] = { kind = kind, v = v, key = key }
end
function ns.IconDex.Retry(max)
    max = max or 40
    local n = #pending
    if n == 0 then return 0 end
    local got, tries = 0, 0
    while tries < max and tries < n and #pending > 0 do
        if cursor > #pending then cursor = 1 end
        local it = pending[cursor]
        if ns.IconDex.Of(it.kind, it.v) then
            known[it.key] = nil
            table.remove(pending, cursor)
            got = got + 1
        else
            if it.kind == "item" then ns.Compat.ItemInfo(it.v) end
            cursor = cursor + 1
        end
        tries = tries + 1
    end
    return got
end
function ns.IconDex.PendingCount()
    return #pending
end
local memo = {}
function ns.IconDex.Clean(key, kind, list)
    local was = memo[key]
    if was and was.stamp == ns.IconDex.stamp and was.n == #list then
        return was.distinct, was.waiting, was.iconOf
    end
    local seen, distinct, waiting, iconOf = {}, {}, {}, {}
    for i = 1, #list do
        local v = list[i]
        local tex = ns.IconDex.Of(kind, v)
        if not tex then
            waiting[#waiting + 1] = v
            remember(kind, v)
        else
            iconOf[v] = tex
            local k = type(tex) == "string" and tex:lower() or tex
            if not seen[k] then
                seen[k] = true
                distinct[#distinct + 1] = v
            end
        end
    end
    memo[key] = { stamp = ns.IconDex.stamp, n = #list,
                  distinct = distinct, waiting = waiting, iconOf = iconOf }
    return distinct, waiting, iconOf
end
function ns.IconDex.CountDistinct(key, kind, list)
    local distinct = ns.IconDex.Clean(key, kind, list)
    return #distinct
end
