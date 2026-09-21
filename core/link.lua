local ADDON, ns = ...
ns.Link = {}
local PREFIX = "rwArc"
local VER = 1
local BODY_MAX = 248
local SEND_CAP = 10
local RECV_GAP = 0.5
local CACHE_MAX = 200
local ASK_WAIT = 3
local OK_TTL   = 60
local NO_TTL   = 15
local TAGS = {
    HI = true, HERE = true,
    INV = true, YES = true, NO = true, MV = true, END = true, RE = true,
    PR = true, PRY = true, PRN = true, PRX = true,
    OF = true,
}
local function int(lo, hi)
    return function(v)
        if not string.find(v, "^%d+$") or #v > 10 then return false end
        local n = tonumber(v)
        return n >= lo and n <= hi
    end
end
local function oneOf(...)
    local set = {}
    for i = 1, select("#", ...) do set[(select(i, ...))] = true end
    return function(v) return set[v] == true end
end
local function shape(pat, max)
    return function(v) return #v <= max and string.find(v, pat) ~= nil end
end
local MID   = int(1, 4294967295)
local PROTO = int(1, 99)
local STEP  = int(0, 100000)
local APPV  = function(v) return ns.Version.Valid(v) end
local GAME  = shape("^%l+$", 24)
local PACK  = shape("^[%w_=;%.%-]*$", BODY_MAX)
local CLS   = shape("^%u*$", 12)
local WHY   = oneOf("no", "busy", "combat", "timeout", "game", "closed")
local SCHEMA = {
    HI   = { PROTO, APPV },
    HERE = { PROTO, int(0, 3), APPV, CLS },
    INV  = { MID, GAME, PROTO, PACK, oneOf("h", "g") },
    YES  = { MID },
    NO   = { MID, WHY },
    MV   = { MID, int(1, 100000), PACK },
    END  = { MID, oneOf("over", "resign", "desync", "quit", "silence", "logout") },
    RE   = { MID, STEP },
    OF   = { MID, oneOf("draw", "yes", "no") },
    PR   = { PROTO },
    PRY  = {},
    PRN  = { WHY },
    PRX  = {},
}
local function fits(tag, ...)
    local rule = SCHEMA[tag]
    if not rule then return false end
    local got = select("#", ...)
    while got > 0 and (select(got, ...)) == nil do got = got - 1 end
    if got ~= #rule then return false end
    for i = 1, got do
        local v = (select(i, ...))
        if type(v) ~= "string" or not rule[i](v) then return false end
    end
    return true
end
ns.Link.Fits = fits
function ns.Link.Num(v, lo, hi)
    local n = tonumber(v)
    if not n then return nil end
    if n ~= n or n == math.huge or n == -math.huge then return nil end
    if n ~= math.floor(n) then return nil end
    if lo and n < lo then return nil end
    if hi and n > hi then return nil end
    return n
end
local function plain(v)
    local s = tostring(v)
    if string.find(s, "[\t;=|]") then return false end
    if string.find(s, "%c") then return false end
    return true
end
ns.Link.Plain = plain
local function field(v)
    local s = tostring(v)
    if string.find(s, "[|%c]") then return false end
    return true
end
local function prune(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    if n <= CACHE_MAX then return t end
    return {}
end
function ns.Link.Encode(t)
    if type(t) ~= "table" then return "" end
    local keys = {}
    for k in pairs(t) do
        if type(k) == "string" then keys[#keys + 1] = k end
    end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
        local v = t[k]
        if (type(v) == "number" or type(v) == "string") and plain(k) and plain(v) then
            out[#out + 1] = k .. "=" .. tostring(v)
        end
    end
    return table.concat(out, ";")
end
function ns.Link.Decode(str)
    local t = {}
    if type(str) ~= "string" or str == "" then return t end
    local n = 0
    for pair in string.gmatch(str, "[^;]+") do
        local k, v = string.match(pair, "^([%w_]+)=([%w_%.%-]*)$")
        if k then
            n = n + 1
            if n > 16 then break end
            t[k] = tonumber(v) or v
        end
    end
    return t
end
local sentAt, sentN = 0, 0
local function budgetOk()
    local now = GetTime()
    if now - sentAt >= 1 then
        sentAt, sentN = now, 0
    end
    sentN = sentN + 1
    if sentN > SEND_CAP then
        if sentN == SEND_CAP + 1 then
            ns.say("связь: перебор отправки, сообщения придержаны. Это ошибка аддона.")
        end
        return false
    end
    return true
end
function ns.Link.Send(to, tag, ...)
    to = ns.Link.Norm(to)
    if not to or not TAGS[tag] then return false end
    if not budgetOk() then return false end
    local strs = {}
    for i = 1, select("#", ...) do strs[i] = tostring((select(i, ...))) end
    if not fits(tag, unpack(strs, 1, select("#", ...))) then return false end
    local body = tag
    for i = 1, select("#", ...) do
        local v = (select(i, ...))
        if not field(v) then return false end
        body = body .. "\t" .. tostring(v)
    end
    if #body > BODY_MAX then return false end
    SendAddonMessage(PREFIX, body, "WHISPER", to)
    return true
end
local shouted = false
local partyWas, partyAt = 0, 0
local PARTY_GAP = 15
local function around()
    local raid = GetNumRaidMembers and GetNumRaidMembers() or 0
    if raid > 0 then return raid, "RAID" end
    local party = GetNumPartyMembers and GetNumPartyMembers() or 0
    if party > 0 then return party, "PARTY" end
    return 0, nil
end
local function hereBody()
    return "HERE\t" .. VER .. "\t" .. ns.Link.Here() .. "\t" .. ns.Version.Mine()
        .. "\t" .. (ns.Link.MyClass() or "")
end
local function shoutGuild()
    if shouted then return end
    shouted = true
    if not (IsInGuild and IsInGuild()) then return end
    if not budgetOk() then return end
    SendAddonMessage(PREFIX, hereBody(), "GUILD")
end
local function shoutGroup()
    local n, chan = around()
    if n <= partyWas then
        partyWas = n
        return
    end
    partyWas = n
    if not chan then return end
    local now = GetTime()
    if now - partyAt < PARTY_GAP then return end
    partyAt = now
    if not budgetOk() then return end
    SendAddonMessage(PREFIX, hereBody(), chan)
end
local SHOUT_GAP = 20
local shoutAt, shoutSt = 0, nil
function ns.Link.Shout()
    local st = ns.Link.Here()
    if st == shoutSt then return end
    local now = GetTime()
    if now - shoutAt < SHOUT_GAP then return end
    shoutSt, shoutAt = st, now
    local body = hereBody()
    if IsInGuild and IsInGuild() and budgetOk() then
        SendAddonMessage(PREFIX, body, "GUILD")
    end
    local _, chan = around()
    if chan and budgetOk() then SendAddonMessage(PREFIX, body, chan) end
end
function ns.Link.Norm(name)
    if type(name) ~= "string" or name == "" then return nil end
    local short = string.match(name, "^([^-]+)") or name
    if short == "" then return nil end
    return short
end
local function keyOf(name)
    local short = ns.Link.Norm(name)
    return short and short:lower() or nil
end
function ns.Link.IsMe(name)
    local k = keyOf(name)
    return k ~= nil and k == keyOf(UnitName("player"))
end
local known = {}
local watchers = {}
local function tell(name)
    for i = 1, #watchers do watchers[i](name) end
end
function ns.Link.OnPresence(fn)
    if type(fn) == "function" then watchers[#watchers + 1] = fn end
end
local function remember(name, ok, st, cls)
    local k = keyOf(name)
    if not k then return end
    if not (type(cls) == "string" and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]) then
        cls = known[k] and known[k].cls or nil
    end
    known[k] = { at = GetTime(), ok = ok, name = ns.Link.Norm(name), st = st, cls = cls }
    tell(known[k].name)
end
function ns.Link.MyClass()
    local _, cls = UnitClass("player")
    return type(cls) == "string" and cls or nil
end
function ns.Link.PeerClass(name)
    local k = keyOf(name)
    local rec = k and known[k]
    return rec and rec.cls or nil
end
function ns.Link.Ask(name)
    local short = ns.Link.Norm(name)
    if not short or ns.Link.IsMe(short) then return end
    local k = keyOf(short)
    local rec = known[k]
    local now = GetTime()
    if rec then
        if rec.asked and now - rec.asked < ASK_WAIT then return end
        if rec.ok and now - rec.at < OK_TTL then return end
        if rec.ok == false and rec.at and now - rec.at < NO_TTL then return end
    end
    known[k] = { asked = now, name = short }
    ns.Link.Send(short, "HI", VER, ns.Version.Mine())
end
function ns.Link.State(name)
    local k = keyOf(name)
    local rec = k and known[k]
    if not rec then return nil end
    local now = GetTime()
    if rec.ok ~= nil then
        local ttl = rec.ok and OK_TTL or NO_TTL
        if now - rec.at < ttl then return rec.ok and "yes" or "no" end
        return nil
    end
    if rec.asked then
        if now - rec.asked < ASK_WAIT then return "asking" end
        remember(rec.name or name, false)
        return "no"
    end
    return nil
end
local heard = {}
local hooks = {}
function ns.Link.On(tag, fn)
    if TAGS[tag] and type(fn) == "function" then hooks[tag] = fn end
end
local seers = {}
function ns.Link.Watch(fn)
    if type(fn) == "function" then seers[#seers + 1] = fn end
end
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
    if event == "PLAYER_ENTERING_WORLD" then
        shoutGuild()
        partyWas = 0
        shoutGroup()
        return
    end
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        shoutGroup()
        return
    end
    if prefix ~= PREFIX or type(message) ~= "string" then return end
    local from = ns.Link.Norm(sender)
    if not from then return end
    if ns.Link.IsMe(from) then return end
    if #message > BODY_MAX then return end
    if string.find(message, "|", 1, true) then return end
    if string.find((message:gsub("\t", "")), "%c") then return end
    local tag, a, b, c, d, e, extra = strsplit("\t", message)
    if not TAGS[tag] or extra ~= nil then return end
    if not fits(tag, a, b, c, d, e) then return end
    for i = 1, #seers do seers[i](from, tag, a, b, c, d, e) end
    local now = GetTime()
    local k = from:lower()
    local rec = heard[k]
    if not rec then
        heard = prune(heard)
        rec = {}
        heard[k] = rec
    end
    if rec[tag] and now - rec[tag] < RECV_GAP and tag ~= "MV" then return end
    rec[tag] = now
    if tag == "HI" then
        if ns.Ignore and ns.Ignore.Blocked(from) then return end
        ns.Link.Send(from, "HERE", VER, ns.Link.Here(), ns.Version.Mine(), ns.Link.MyClass() or "")
        remember(from, true)
        ns.Version.Heard(from, b)
        return
    end
    if tag == "HERE" then
        remember(from, true, tonumber(b), d)
        ns.Version.Heard(from, c)
        return
    end
    local fn = hooks[tag]
    if fn then fn(from, a, b, c, d, e) end
end)
ns.Link.busy = false
function ns.Link.Here()
    if UnitAffectingCombat("player") then return 3 end
    if ns.Link.busy then return 2 end
    if ns.window and ns.window.IsShown and ns.window:IsShown() then return 1 end
    return 0
end
function ns.Link.PeerHere(name)
    local k = keyOf(name)
    local rec = k and known[k]
    return rec and rec.st or nil
end
function ns.Link.Prefix()
    return PREFIX
end
function ns.Link.Version()
    return VER
end
