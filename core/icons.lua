local ADDON, ns = ...
ns.Icons = {}
local QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
ns.Icons.QMARK = QMARK
local CUT = "#"
local MIN_CUT = 0.01
ns.QMARK = QMARK
function ns.IconPath(name)
    if type(name) ~= "string" or name == "" then return QMARK end
    if name:find(CUT, 1, true) then name = ns.Pics.Cut(name) or name end
    if name:find("\\", 1, true) or name:find("/", 1, true) then return name end
    return "Interface\\Icons\\" .. name
end
function ns.Icons.Item(itemID)
    return ns.Compat.ItemIcon(itemID) or QMARK
end
function ns.Icons.FromBags()
    local seen, out = {}, {}
    for bag = 0, NUM_BAG_SLOTS do
        local slots = ns.Compat.BagSlots(bag) or 0
        for slot = 1, slots do
            local tex = ns.Compat.BagItemIcon(bag, slot)
            if tex and not seen[tex] then
                seen[tex] = true
                out[#out + 1] = tex
            end
        end
    end
    return out
end
function ns.Icons.Set(kind, n)
    local out = {}
    local seen = {}
    if kind == "items" then
        local bags = ns.Icons.FromBags()
        for i = 1, #bags do
            if #out >= n then break end
            if not seen[bags[i]] then
                seen[bags[i]] = true
                out[#out + 1] = bags[i]
            end
        end
        for _, id in ipairs(ns.itemSets.items or {}) do
            if #out >= n then break end
            local tex = ns.Compat.ItemIcon(id)
            if tex and not seen[tex] then
                seen[tex] = true
                out[#out + 1] = tex
            end
        end
    end
    for _, id in ipairs(ns.itemSets.gems) do
        if #out >= n then break end
        local tex = ns.Compat.ItemIcon(id)
        if tex and not seen[tex] then
            seen[tex] = true
            out[#out + 1] = tex
        end
    end
    while #out < n do
        out[#out + 1] = QMARK
    end
    return out
end
function ns.Icons.Gem(color)
    local id = ns.itemSets.gems[color]
    return id and ns.Icons.Item(id) or QMARK
end
ns.Pics = {}
local function setOf(key)
    return (ns.picsSets or {})[key or ""]
end
function ns.Pics.Sets()
    local out = {}
    for _, key in ipairs(ns.picsOrder or {}) do
        local s = setOf(key)
        if s then
            local box = (s.kind == "wall") and (ns.picsWalls or {}) or (ns.picsDB or {})
            out[#out + 1] = { key = key, label = s.label or key, kind = s.kind or "whole",
                              dir = s.dir, n = #(box[key] or {}) }
        end
    end
    return out
end
function ns.Pics.Kind(key)
    local s = setOf(key)
    return (s and s.kind) or "whole"
end
function ns.Pics.List(key)
    if ns.Pics.Kind(key) == "wall" then return (ns.picsWalls or {})[key or ""] or {} end
    return (ns.picsDB or {})[key or ""] or {}
end
function ns.Pics.Path(key, file)
    local s = setOf(key)
    if not s or type(file) ~= "string" or file == "" then return nil end
    return s.dir .. file
end
function ns.Pics.TileName(wall, k)
    if type(wall) ~= "table" or type(k) ~= "number" then return nil end
    if k < 1 or k > (wall.n or 0) then return nil end
    if wall.keep and wall.keep:sub(k, k) ~= "1" then return nil end
    return wall.b .. ((wall.first or 1) + k - 1)
end
function ns.Pics.Tiles(wall)
    local out = {}
    for k = 1, (wall and wall.n) or 0 do
        local f = ns.Pics.TileName(wall, k)
        if f then out[#out + 1] = { f = f, k = k } end
    end
    return out
end
function ns.Pics.Face(key, wall)
    if type(wall) ~= "table" then return nil end
    local i = wall.face or wall.first or 1
    return ns.Pics.Path(key, wall.b .. i)
end
local whole, base
local function build()
    whole, base = {}, {}
    for _, key in ipairs(ns.picsOrder or {}) do
        local kind = ns.Pics.Kind(key)
        if kind == "wall" then
            base[key] = {}
            for _, w in ipairs(ns.Pics.List(key)) do base[key][w.b:lower()] = w end
        else
            whole[key] = {}
            for _, p in ipairs(ns.Pics.List(key)) do whole[key][p.f:lower()] = p end
        end
    end
end
function ns.Pics.Find(path)
    if type(path) ~= "string" then return nil end
    if not whole then build() end
    path = ns.Pics.Cut(path) or path
    local low = path:lower()
    for _, key in ipairs(ns.picsOrder or {}) do
        local s = setOf(key)
        local dir = s and s.dir and s.dir:lower()
        if dir and low:sub(1, #dir) == dir then
            local tail = low:sub(#dir + 1)
            if whole[key] then
                local hit = whole[key][tail]
                if hit then return hit, key end
            else
                local b, num = tail:match("^(.-)(%d+)$")
                local w = b and base[key][b]
                if w then
                    local k = tonumber(num) - (w.first or 1) + 1
                    if k >= 1 and k <= w.n then return w, key, k end
                end
            end
        end
    end
    return nil
end
function ns.Pics.Cut(name)
    if type(name) ~= "string" then return nil end
    local at = name:find(CUT, 1, true)
    if not at then return name end
    local path = name:sub(1, at - 1)
    local l, r, t, b = name:sub(at + 1)
        :match("^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
    l, r, t, b = tonumber(l), tonumber(r), tonumber(t), tonumber(b)
    if not (l and r and t and b) then return path end
    if l < 0 or t < 0 or r > 1 or b > 1 then return path end
    if r - l < MIN_CUT or b - t < MIN_CUT then return path end
    return path, l, r, t, b
end
function ns.Pics.Pack(path, l, r, t, b)
    return ("%s%s%.4f,%.4f,%.4f,%.4f"):format(path, CUT, l, r, t, b)
end
local function validCut(rec)
    if type(rec) ~= "table" or type(rec.p) ~= "string" or rec.p == "" then return false end
    local l, r, t, b = tonumber(rec.l), tonumber(rec.r), tonumber(rec.t), tonumber(rec.b)
    if not (l and r and t and b) then return false end
    if l < 0 or t < 0 or r > 1 or b > 1 then return false end
    return r - l >= MIN_CUT and b - t >= MIN_CUT
end
local function cutStore()
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    if type(db) ~= "table" then return {} end
    db.picsCut = db.picsCut or {}
    return db.picsCut
end
local cutList, cutName
function ns.Pics.CutFolderName(s)
    if type(s) ~= "string" then return "" end
    s = s:gsub("[\"\\|#%?]", ""):gsub("^%s*(.-)%s*$", "%1")
    return s:sub(1, 24)
end
local function buildCuts()
    cutList, cutName = {}, {}
    local function take(rec)
        if not validCut(rec) then return end
        local key = ns.Pics.Pack(rec.p, rec.l, rec.r, rec.t, rec.b)
        local low = key:lower()
        if rec.n == "" then
            for i = #cutList, 1, -1 do
                if cutList[i].key:lower() == low then table.remove(cutList, i) end
            end
            cutName[low] = nil
            return
        end
        local g = (rec.g ~= nil) and ns.Pics.CutFolderName(rec.g) or nil
        if cutName[low] then
            cutName[low] = rec.n or cutName[low]
            for _, c in ipairs(cutList) do
                if c.key:lower() == low then
                    c.name = cutName[low]
                    if g then c.g = g end
                end
            end
            return
        end
        cutName[low] = (rec.n ~= nil) and rec.n or key
        cutList[#cutList + 1] = { key = key, name = cutName[low], p = rec.p,
                                  l = rec.l, r = rec.r, t = rec.t, b = rec.b,
                                  g = g or "" }
    end
    for _, rec in ipairs(ns.cutsDB or {}) do take(rec) end
    for _, rec in ipairs(cutStore()) do take(rec) end
end
function ns.Pics.Cuts()
    if not cutList then buildCuts() end
    return cutList
end
function ns.Pics.CutName(name)
    if type(name) ~= "string" then return nil end
    if not cutList then buildCuts() end
    return cutName[name:lower()]
end
function ns.Pics.AddCut(path, l, r, t, b, label, folder)
    local rec = { p = path, l = l, r = r, t = t, b = b, n = label,
                  g = ns.Pics.CutFolderName(folder) }
    if not validCut(rec) then return nil end
    local same = {}
    for _, old in ipairs(ns.Pics.Cuts()) do
        if old.p:lower() == path:lower() and old.name == label then
            same[#same + 1] = old.key
        end
    end
    for _, k in ipairs(same) do ns.Pics.DropCut(k) end
    local box = cutStore()
    box[#box + 1] = rec
    cutList = nil
    return ns.Pics.Pack(path, l, r, t, b)
end
function ns.Pics.DropCut(key)
    local path, l, r, t, b = ns.Pics.Cut(key)
    if not l then return false end
    local box = cutStore()
    for i = #box, 1, -1 do
        local rec = box[i]
        if validCut(rec)
            and ns.Pics.Pack(rec.p, rec.l, rec.r, rec.t, rec.b):lower() == key:lower() then
            table.remove(box, i)
        end
    end
    cutList = nil
    if ns.Pics.CutName(key) then
        box[#box + 1] = { p = path, l = l, r = r, t = t, b = b, n = "" }
        cutList = nil
    end
    return true
end
function ns.Pics.SetCutFolder(key, folder)
    local path, l, r, t, b = ns.Pics.Cut(key)
    if not l then return false end
    local name = ns.Pics.CutName(key)
    if not name then return false end
    folder = ns.Pics.CutFolderName(folder)
    local box = cutStore()
    for i = #box, 1, -1 do
        local rec = box[i]
        if rec.n ~= "" and validCut(rec)
            and ns.Pics.Pack(rec.p, rec.l, rec.r, rec.t, rec.b):lower() == key:lower() then
            rec.g = folder
            cutList = nil
            return true
        end
    end
    box[#box + 1] = { p = path, l = l, r = r, t = t, b = b, n = name, g = folder }
    cutList = nil
    return true
end
local PIC_CUT  = { "UI-LFG-BACKGROUND-", "LFGICON-", "LOADSCREEN" }
local PIC_TAIL = { "-TOPLEFT" }
local function bareName(p)
    local s = p.b or p.f
    if type(s) ~= "string" or s == "" then return nil end
    local up = s:upper()
    for _, pre in ipairs(PIC_CUT) do
        if up:sub(1, #pre) == pre then s = s:sub(#pre + 1) break end
    end
    up = s:upper()
    for _, suf in ipairs(PIC_TAIL) do
        if #s > #suf and up:sub(-#suf) == suf then s = s:sub(1, #s - #suf) break end
    end
    return (s ~= "") and s or nil
end
local twins
local function twinOf(bare)
    if not twins then
        twins = {}
        for _, set in ipairs(ns.picsOrder or {}) do
            for _, q in ipairs(ns.Pics.List(set)) do
                local s = bareName(q)
                if s and s:find("%l") then
                    local up = s:upper()
                    if not twins[up] then twins[up] = s end
                end
            end
        end
    end
    return twins[bare:upper()]
end
local function picEnglish(p)
    local s = bareName(p)
    if not s then return nil end
    if not s:find("%l") then
        s = twinOf(s) or (s:sub(1, 1) .. s:sub(2):lower())
    end
    s = s:gsub("(%l)(%u)", "%1 %2")
    s = s:gsub("(%u)(%u%l)", "%1 %2")
    s = s:gsub("(%a)(%d)", "%1 %2")
    return s
end
function ns.Pics.Label(p, k)
    if type(p) ~= "table" then return "?" end
    local ru = (p.ru and p.ru ~= "") and p.ru or nil
    local en = picEnglish(p)
    local name
    if ns.CurrentLocale() == "enUS" then name = en or ru else name = ru or en end
    name = name or "?"
    if k and p.n then return ("%s, %d/%d"):format(name, k, p.n) end
    return name
end
function ns.Pics.Title(name)
    local own = ns.Pics.CutName(name)
    if own and own ~= "" then return own end
    local path, l = ns.Pics.Cut(name)
    local p, _, k = ns.Pics.Find(path)
    local base = p and ns.Pics.Label(p, k) or tostring(path)
    if l then return "вырезка: " .. base end
    return base
end
local FALLBACK = { 0.18, 0.21, 0.27 }
function ns.Pics.Apply(tex, name, r, g, b)
    if not tex then return false end
    tex.arcCut = nil
    local path, cl, cr, ct, cb = ns.Pics.Cut(name)
    if type(path) == "string" and path ~= "" then
        tex:SetTexture(nil)
        tex:SetTexture(path)
        if tex:GetTexture() then
            if cl then
                tex.arcCut = { cl, cr, ct, cb }
                tex:SetTexCoord(cl, cr, ct, cb)
            end
            return true
        end
    end
    tex:SetVertexColor(1, 1, 1)
    ns.Paint(tex, r or FALLBACK[1], g or FALLBACK[2], b or FALLBACK[3])
    return false
end
local function middle(pw, ph, aw, ah)
    if not pw or not ph or pw <= 0 or ph <= 0 or aw <= 0 or ah <= 0 then
        return 0, 1, 0, 1
    end
    local want, have = aw / ah, pw / ph
    if have > want then
        local keep = (1 - want / have) / 2
        return keep, 1 - keep, 0, 1
    elseif have < want then
        local keep = (1 - have / want) / 2
        return 0, 1, keep, 1 - keep
    end
    return 0, 1, 0, 1
end
local function inside(c, l, r, t, b)
    if not c then return l, r, t, b end
    local w, h = c[2] - c[1], c[4] - c[3]
    return c[1] + l * w, c[1] + r * w, c[3] + t * h, c[3] + b * h
end
function ns.Pics.Crop(tex, pw, ph, aw, ah)
    local c = tex and tex.arcCut
    if c then
        pw = (pw or 0) * (c[2] - c[1])
        ph = (ph or 0) * (c[4] - c[3])
    end
    tex:SetTexCoord(inside(c, middle(pw, ph, aw or 1, ah or 1)))
end
function ns.Pics.Fit(tex, name, aw, ah)
    if not tex then return false end
    local path, cl, cr, ct, cb = ns.Pics.Cut(name)
    local rec = ns.Pics.Find(path)
    local pw, ph = (rec and rec.w) or 1, (rec and rec.h) or 1
    local c = cl and { cl, cr, ct, cb } or nil
    if c then pw, ph = pw * (cr - cl), ph * (cb - ct) end
    tex:SetTexCoord(inside(c, middle(pw, ph, aw or 1, ah or 1)))
    return true
end
