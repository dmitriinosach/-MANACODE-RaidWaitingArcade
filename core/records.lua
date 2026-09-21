local ADDON, ns = ...
ns.Records = {}
local DEFAULT = { { key = "score", by = "max", mark = "token" } }
local function default()
    DEFAULT[1].label = ns.T("recAxisScore")
    return DEFAULT
end
function ns.Records.Keeps(def)
    return not (def and def.record == false)
end
function ns.Records.Marks(def)
    local r = def and def.record
    if type(r) ~= "table" or #r == 0 then return default() end
    return r
end
function ns.Records.Main(def)
    return ns.Records.Marks(def)[1]
end
function ns.Records.MainFor(def, opts)
    local pick = def and def.mainMark
    if type(pick) == "function" then
        local ok, key = pcall(pick, opts)
        if ok and key then return ns.Records.MarkFor(def, key) end
    end
    return ns.Records.Main(def)
end
function ns.Records.MarkFor(def, key)
    for _, mark in ipairs(ns.Records.Marks(def)) do
        if mark.key == key then return mark end
    end
    return default()[1]
end
function ns.Records.Note(def)
    local r = def and def.record
    return type(r) == "table" and r.note or nil
end
local function span(sec)
    if not sec or sec < 0 then sec = 0 end
    local m = math.floor(sec / 60)
    return string.format("%d:%02d", m, math.floor(sec - m * 60))
end
ns.Records.Span = span
function ns.Records.Format(mark, v)
    if type(v) ~= "number" then return "—" end
    local f = mark and mark.format
    if f == "span" then return span(v) end
    if type(f) == "string" then return string.format(f, v) end
    return tostring(math.floor(v))
end
function ns.Records.Icon(key)
    local m = key and ns.markDB and ns.markDB[key]
    if not m then return ns.QMARK end
    if m.item then return ns.Icons.Item(m.item) end
    return ns.IconPath(m.icon)
end
local function cmp(mark, a, b)
    if a == b then return 0 end
    if type(a) ~= "number" then return 1 end
    if type(b) ~= "number" then return -1 end
    if mark.by == "min" then
        return (a < b) and -1 or 1
    end
    return (a > b) and -1 or 1
end
function ns.Records.Better(def, a, b)
    for _, mark in ipairs(ns.Records.Marks(def)) do
        local c = cmp(mark, a[mark.key], b[mark.key])
        if c ~= 0 then return c < 0 end
    end
    return false
end
local function defOf(id)
    return ns.games and ns.games[id]
end
function ns.Records.KeyOpts(def, opts)
    if opts == nil then return nil end
    local axes = ns.Records.Axes(def)
    if #axes == 0 then return opts end
    local sel = ns.Records.Normalize(def, opts)
    local out = {}
    for _, axis in ipairs(axes) do
        local v = sel[axis.key]
        if not (axis.thin and v == ns.Records.Bound(axis, "def", sel)) then
            out[axis.key] = v
        end
    end
    return out
end
function ns.Records.List(id, opts)
    local def = defOf(id)
    local key = ns.Store.OptsKey(ns.Records.KeyOpts(def, opts))
    local out = {}
    for _, rec in ipairs(ns.Store.RecList(id)) do
        if opts == nil or rec.opts == key then
            local c = {}
            for k, v in pairs(rec) do c[k] = v end
            out[#out + 1] = c
        end
    end
    table.sort(out, function(a, b) return ns.Records.Better(def, a, b) end)
    return out
end
function ns.Records.Best(id, opts)
    local def = defOf(id)
    local key = ns.Store.OptsKey(ns.Records.KeyOpts(def, opts))
    local best
    for _, rec in ipairs(ns.Store.RecList(id)) do
        if opts == nil or rec.opts == key then
            if best == nil or ns.Records.Better(def, rec, best) then best = rec end
        end
    end
    return best
end
function ns.Records.Submit(id, opts, vals)
    local def = defOf(id)
    if not ns.Records.Keeps(def) then return false end
    local was = ns.Records.Best(id, opts)
    local rec = { opts = ns.Store.OptsKey(ns.Records.KeyOpts(def, opts)), at = time() }
    for k, v in pairs(vals or {}) do
        if type(v) == "number" then rec[k] = math.floor(v) end
    end
    ns.Store.Push(id, rec, function(a, b) return ns.Records.Better(def, a, b) end)
    return was == nil or ns.Records.Better(def, rec, was)
end
function ns.Records.Axes(def)
    local a = def and def.opts
    if type(a) ~= "table" then return {} end
    return a
end
function ns.Records.Options(axis, sel)
    local o = axis.options
    if type(o) == "function" then return o(sel) end
    return o
end
function ns.Records.AxisOpen(axis, sel)
    local list = ns.Records.Options(axis, sel)
    return not (list and #list < 2)
end
function ns.Records.AxesOpen(def, sel)
    local out = {}
    for _, axis in ipairs(ns.Records.Axes(def)) do
        if ns.Records.AxisOpen(axis, sel) then out[#out + 1] = axis end
    end
    return out
end
function ns.Records.Bound(axis, field, sel)
    local v = axis[field]
    if type(v) == "function" then return v(sel) end
    return v
end
local function axisDefault(axis, sel)
    local d = ns.Records.Bound(axis, "def", sel)
    if d ~= nil then return d end
    local list = ns.Records.Options(axis, sel)
    if list and list[1] then return list[1].key end
    return ns.Records.Bound(axis, "min", sel) or 0
end
function ns.Records.Normalize(def, opts)
    local axes = ns.Records.Axes(def)
    if #axes == 0 then
        local out = {}
        for k, v in pairs(opts or {}) do out[k] = v end
        return out
    end
    local sel = {}
    for _, axis in ipairs(axes) do
        local want = opts and opts[axis.key]
        local list = ns.Records.Options(axis, sel)
        if list then
            local ok = false
            for _, o in ipairs(list) do
                if o.key == want then ok = true end
            end
            sel[axis.key] = ok and want or axisDefault(axis, sel)
        else
            local v = tonumber(want)
            if v then
                local lo = ns.Records.Bound(axis, "min", sel) or 0
                local hi = ns.Records.Bound(axis, "max", sel) or v
                if v < lo then v = lo elseif v > hi then v = hi end
                sel[axis.key] = math.floor(v)
            else
                sel[axis.key] = axisDefault(axis, sel)
            end
        end
    end
    return sel
end
function ns.Records.Defaults(def)
    return ns.Records.Normalize(def, nil)
end
function ns.Records.Describe(def, opts)
    local axes = ns.Records.Axes(def)
    if #axes == 0 then return "" end
    local sel = ns.Records.Normalize(def, opts)
    local out = {}
    for _, axis in ipairs(axes) do
        local list = ns.Records.Options(axis, sel)
        local v = sel[axis.key]
        if list then
            for _, o in ipairs(list) do
                if o.key == v then
                    out[#out + 1] = ns.TL(o.label) or tostring(v)
                    break
                end
            end
        elseif axis.format then
            out[#out + 1] = string.format(ns.TL(axis.format), v)
        else
            out[#out + 1] = (ns.TL(axis.label) or axis.key) .. " " .. tostring(v)
        end
    end
    return table.concat(out, ", ")
end
function ns.Records.Repick(def, opts, key, value)
    local sel = ns.Records.Normalize(def, opts)
    sel[key] = value
    for _, axis in ipairs(ns.Records.Axes(def)) do
        if axis.key == key and type(axis.reset) == "table" then
            for _, k in ipairs(axis.reset) do sel[k] = nil end
        end
    end
    return ns.Records.Normalize(def, sel)
end
function ns.Records.Label(def, opts)
    local sel = ns.Records.Normalize(def, opts)
    local parts = {}
    for _, axis in ipairs(ns.Records.Axes(def)) do
        local v = sel[axis.key]
        local text = tostring(v)
        local list = ns.Records.Options(axis, sel)
        if list then
            for _, o in ipairs(list) do
                if o.key == v then text = ns.TL(o.label) or o.key end
            end
        elseif axis.format then
            text = string.format(ns.TL(axis.format), v)
        end
        parts[#parts + 1] = text
    end
    return table.concat(parts, " - ")
end
