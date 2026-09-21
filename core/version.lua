local ADDON, ns = ...
ns.Version = {}
local NOTE_DELAY = 10
local VER_MAX = 16
local DAY = 24 * 60 * 60
local SHAPE = "^%d%d?%.%d%d?%.%d%d?$"
local SHAPE_PRE = "^%d%d?%.%d%d?%.%d%d?%-beta%d?%d?$"
local RELEASE = 1000
local VOUCH_NEED = 2
local VOUCH_KEEP = 16
local mine, newest, dueAt, timer, booted
local listeners = {}
local dueListeners = {}
function ns.Version.OnNew(fn)
    listeners[#listeners + 1] = fn
end
function ns.Version.OnDue(fn)
    dueListeners[#dueListeners + 1] = fn
end
function ns.Version.Valid(s)
    if type(s) ~= "string" or #s > VER_MAX then return false end
    return string.find(s, SHAPE) ~= nil or string.find(s, SHAPE_PRE) ~= nil
end
local function parse(s)
    if not ns.Version.Valid(s) then return nil end
    local a, b, c, rest = string.match(s, "^(%d+)%.(%d+)%.(%d+)(.*)$")
    local pre = RELEASE
    if rest ~= "" then pre = tonumber(string.match(rest, "(%d+)$")) or 1 end
    return tonumber(a), tonumber(b), tonumber(c), pre
end
function ns.Version.Mine()
    if not mine then
        mine = (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version"))
            or ns.VERSION or "0.0.0"
    end
    return mine
end
function ns.Version.Newer(a, b)
    local a1, a2, a3, a4 = parse(a)
    local b1, b2, b3, b4 = parse(b)
    if not a1 or not b1 then return false end
    if a1 ~= b1 then return a1 > b1 end
    if a2 ~= b2 then return a2 > b2 end
    if a3 ~= b3 then return a3 > b3 end
    return a4 > b4
end
function ns.Version.Newest()
    return newest
end
local function store()
    local db = ns.Store.DB()
    db.ver = db.ver or {}
    return db.ver
end
function ns.Version.NeedTop()
    return (booted and newest and store().top ~= newest) and true or false
end
function ns.Version.TopSeen()
    if booted and newest then store().top = newest end
end
function ns.Version.NeedInside()
    if not booted or not newest then return false end
    local box = store()
    if box.top ~= newest then return false end
    return (time() - (tonumber(box.day) or 0)) >= DAY
end
function ns.Version.InsideShown()
    if booted and newest then store().day = time() end
end
local function system(text)
    local c = ChatTypeInfo and ChatTypeInfo["SYSTEM"]
    local line = ns.T("appTitle") .. ": " .. text
    if c then
        DEFAULT_CHAT_FRAME:AddMessage(line, c.r, c.g, c.b)
    else
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
end
local function due()
    dueAt = nil
    timer:SetScript("OnUpdate", nil)
    if not newest then return end
    if not booted or store().told ~= newest then
        if booted then store().told = newest end
        system(ns.T("verNew", newest, ns.Version.Mine()))
        system(ns.T("verWhere"))
    end
    for i = 1, #dueListeners do dueListeners[i](newest) end
end
local function arm()
    if dueAt then return end
    dueAt = GetTime() + NOTE_DELAY
    timer = timer or CreateFrame("Frame")
    timer:SetScript("OnUpdate", function()
        if dueAt and GetTime() >= dueAt then due() end
    end)
end
local function adopt(ver)
    newest = ver
    if booted then
        local box = store()
        if box.seen ~= ver then box.seen, box.day = ver, nil end
    end
    arm()
    for i = 1, #listeners do listeners[i](newest) end
end
local vouch, vouchN = {}, 0
function ns.Version.Heard(from, ver)
    if not ns.Version.Valid(ver) then return end
    if not ns.Version.Newer(ver, newest or ns.Version.Mine()) then return end
    local major = parse(ver)
    local myMajor = parse(ns.Version.Mine())
    if myMajor and major > myMajor + 1 then return end
    if from == nil then adopt(ver) return end
    if type(from) ~= "string" then return end
    local who = from:lower()
    local set = vouch[ver]
    if not set then
        if vouchN >= VOUCH_KEEP then vouch, vouchN = {}, 0 end
        set = { n = 0 }
        vouch[ver], vouchN = set, vouchN + 1
    end
    if set[who] then return end
    set[who], set.n = true, set.n + 1
    if set.n >= VOUCH_NEED then adopt(ver) end
end
function ns.Version.Boot()
    if booted then return end
    booted = true
    local box = store()
    local seen = box.seen
    local ok = ns.Version.Valid(seen) and ns.Version.Newer(seen, ns.Version.Mine())
        and parse(seen) <= (parse(ns.Version.Mine()) or 0) + 1
    if not ok then
        box.seen, box.told, box.top, box.day = nil, nil, nil, nil
        return
    end
    if not newest or ns.Version.Newer(seen, newest) then adopt(seen) end
end
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, who)
    if who ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    ns.Version.Boot()
end)
