local ADDON, ns = ...
ns.Blacklist = {}
ns.Blacklist.stamp = 1
function ns.Blacklist.Key(tex)
    if type(tex) ~= "string" then return tostring(tex) end
    local name = tex:match("[^\\/]+$") or tex
    return name:lower()
end
local function store()
    local db = ns.Store.DB()
    db.blacklist = db.blacklist or {}
    return db.blacklist
end
function ns.Blacklist.Has(tex)
    if type(tex) ~= "string" or tex == "" then return false end
    return store()[ns.Blacklist.Key(tex)] ~= nil
end
function ns.Blacklist.Add(tex)
    if type(tex) ~= "string" or tex == "" then return false end
    local box = store()
    local k = ns.Blacklist.Key(tex)
    if box[k] then return false end
    box[k] = tex
    ns.Blacklist.stamp = ns.Blacklist.stamp + 1
    return true
end
function ns.Blacklist.Remove(tex)
    if type(tex) ~= "string" or tex == "" then return end
    local box = store()
    local k = ns.Blacklist.Key(tex)
    if box[k] == nil then return end
    box[k] = nil
    ns.Blacklist.stamp = ns.Blacklist.stamp + 1
end
function ns.Blacklist.List()
    local keys = {}
    local box = store()
    for k in pairs(box) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for i = 1, #keys do out[i] = box[keys[i]] end
    return out
end
function ns.Blacklist.Count()
    local n = 0
    for _ in pairs(store()) do n = n + 1 end
    return n
end
function ns.Blacklist.Wipe()
    local box = store()
    if not next(box) then return end
    for k in pairs(box) do box[k] = nil end
    ns.Blacklist.stamp = ns.Blacklist.stamp + 1
end
