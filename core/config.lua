local ADDON, ns = ...
ns.Config = {}
local function bucket(gameId)
    local ch = ns.Store.Char()
    ch.config = ch.config or {}
    ch.config[gameId] = ch.config[gameId] or {}
    return ch.config[gameId]
end
function ns.Config.Get(gameId, key, default)
    if type(gameId) ~= "string" or type(key) ~= "string" then return default end
    local v = bucket(gameId)[key]
    if v == nil then return default end
    return v
end
function ns.Config.Set(gameId, key, value)
    if type(gameId) ~= "string" or type(key) ~= "string" then return end
    bucket(gameId)[key] = value
end
function ns.Config.Touched(gameId)
    for _ in pairs(bucket(gameId)) do return true end
    return false
end
function ns.Config.Wipe(gameId)
    local ch = ns.Store.Char()
    if ch.config then ch.config[gameId] = nil end
end
function ns.Config.Keys(gameId)
    local out = {}
    if type(gameId) ~= "string" then return out end
    for k in pairs(bucket(gameId)) do
        if type(k) == "string" then out[#out + 1] = k end
    end
    table.sort(out)
    return out
end
function ns.Config.CopyValue(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = ns.Config.CopyValue(x) end
    return out
end
ns.Config.ICON_MAX = 64
ns.Config.CELL_SIZES = { 40, 52, 64, 80, 100 }
local CELL_DEFAULT = 64
function ns.Config.CellSize()
    local v = ns.Store.DB().cellSize
    if type(v) ~= "number" then return CELL_DEFAULT end
    local min, max = ns.Config.CELL_SIZES[1], ns.Config.CELL_SIZES[#ns.Config.CELL_SIZES]
    if v < min then return min end
    if v > max then return max end
    return v
end
function ns.Config.SetCellSize(px)
    if type(px) ~= "number" then return end
    ns.Store.DB().cellSize = px
end
function ns.Config.IconFit(cell, border)
    cell = cell or ns.Config.CellSize()
    border = border or 0
    local icon = cell - border * 2
    if icon > ns.Config.ICON_MAX then icon = ns.Config.ICON_MAX end
    if icon < 1 then icon = 1 end
    return icon, math.floor((cell - icon) / 2)
end
