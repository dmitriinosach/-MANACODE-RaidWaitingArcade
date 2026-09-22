local ADDON, ns = ...
ns.locales = ns.locales or {}
ns.localeNames = {
    ruRU = "Русский",
    enUS = "English",
}
ns.localeOrder = { "ruRU", "enUS" }
local MISSING = "??"
local DEFAULT = "ruRU"
function ns.LocaleList()
    local out = {}
    for _, code in ipairs(ns.localeOrder) do
        if ns.locales[code] then out[#out + 1] = code end
    end
    return out
end
function ns.CurrentLocale()
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    local pref = db and db.uiLang
    return (pref and ns.locales[pref]) and pref
        or (ns.locales[GetLocale()] and GetLocale())
        or DEFAULT
end
function ns.LocalePref()
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    local pref = db and db.uiLang
    return (pref and ns.locales[pref]) and pref or "auto"
end
function ns.LocaleOptions()
    local out = { { key = "auto", label = ns.T("langAuto") } }
    for _, code in ipairs(ns.LocaleList()) do
        out[#out + 1] = { key = code, label = ns.localeNames[code] or code }
    end
    return out
end
local speakers = {}
local bound = {}
function ns.OnLocale(fn)
    speakers[#speakers + 1] = fn
end
function ns.SetKeyText(fs, key, ...)
    if not fs then return fs end
    local args = select("#", ...) > 0 and { ... } or nil
    bound[#bound + 1] = { fs = fs, key = key, args = args }
    fs:SetText(args and ns.T(key, unpack(args)) or ns.T(key))
    return fs
end
function ns.SetKeyTip(f, key, ...)
    if not f then return f end
    local args = select("#", ...) > 0 and { ... } or nil
    bound[#bound + 1] = { tipOf = f, key = key, args = args }
    f.tip = args and ns.T(key, unpack(args)) or ns.T(key)
    return f
end
local function relayBound()
    for _, b in ipairs(bound) do
        local text = b.args and ns.T(b.key, unpack(b.args)) or ns.T(b.key)
        if b.fs then b.fs:SetText(text) else b.tipOf.tip = text end
    end
end
function ns.SetLocale(key)
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    if not db then return end
    local code = (key ~= "auto" and ns.locales[key]) and key or nil
    if code == db.uiLang then return end
    db.uiLang = code
    relayBound()
    for _, fn in ipairs(speakers) do fn() end
end
function ns.HasT(key)
    if type(key) ~= "string" then return false end
    local ru = ns.locales[DEFAULT]
    return (ru and ru[key] ~= nil) or false
end
function ns.TL(v)
    if type(v) ~= "string" then return v end
    if v:match("^[%a_][%w_]*%.[%w_]+$") then return ns.T(v) end
    return v
end
function ns.TLines(body)
    if type(body) ~= "table" then return body end
    local out = {}
    for i, p in ipairs(body) do
        if type(p) == "table" then
            local c = {}
            for k, v in pairs(p) do c[k] = v end
            c.t = ns.TL(c.t)
            c.sub = ns.TL(c.sub)
            c.head = ns.TL(c.head)
            c.lines = ns.TLines(c.lines)
            out[i] = c
        else
            out[i] = ns.TL(p)
        end
    end
    return out
end
function ns.T(key, ...)
    local lang = ns.CurrentLocale()
    local base = ns.locales[DEFAULT] and ns.locales[DEFAULT][key]
    local s
    if lang == DEFAULT then
        s = base
    else
        local own = ns.locales[lang] and ns.locales[lang][key]
        if own ~= nil then
            s = own
        elseif base ~= nil then
            s = MISSING
        end
    end
    if s == nil then return "[" .. tostring(key) .. "]" end
    if select("#", ...) > 0 then return s:format(...) end
    return s
end
local function relabelGames()
    for _, def in ipairs(ns.gameOrder or {}) do
        local labelKey, tipKey = def.id .. ".label", def.id .. ".tip"
        if ns.HasT(labelKey) then def.label = ns.T(labelKey) end
        if ns.HasT(tipKey) then def.tip = ns.T(tipKey) end
    end
end
ns.OnLocale(relabelGames)
local f = ns.NewFrame("Frame")
ns.Listen(f, "ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    relabelGames()
end)
