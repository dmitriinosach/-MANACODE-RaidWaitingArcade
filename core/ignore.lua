local ADDON, ns = ...
ns.Ignore = {}
local BOX = "pair"
local KEY = "who"
ns.Ignore.MODES = { "all", "guild", "friends", "none" }
local function store()
    local ch = ns.Store.Char()
    ch.ignore = ch.ignore or {}
    return ch.ignore
end
local function key(name)
    local short = ns.Link.Norm(name)
    return short and short:lower() or nil
end
function ns.Ignore.Has(name)
    local k = key(name)
    return k ~= nil and store()[k] ~= nil
end
function ns.Ignore.Add(name)
    local k = key(name)
    if not k or ns.Link.IsMe(name) then return false end
    local box = store()
    if box[k] then return false end
    box[k] = ns.Link.Norm(name)
    return true
end
function ns.Ignore.Remove(name)
    local k = key(name)
    if k then store()[k] = nil end
end
function ns.Ignore.List()
    local box = store()
    local keys = {}
    for k in pairs(box) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for i = 1, #keys do out[i] = box[keys[i]] end
    return out
end
function ns.Ignore.Count()
    local n = 0
    for _ in pairs(store()) do n = n + 1 end
    return n
end
function ns.Ignore.Wipe()
    local box = store()
    for k in pairs(box) do box[k] = nil end
end
function ns.Ignore.Shunned(name)
    local k = key(name)
    if not k then return false end
    for i = 1, ns.Compat.NumIgnores() do
        if key(ns.Compat.IgnoreName(i)) == k then return true end
    end
    return false
end
function ns.Ignore.Blocked(name)
    return ns.Ignore.Has(name) or ns.Ignore.Shunned(name)
end
function ns.Ignore.Mode()
    local v = ns.Config.Get(BOX, KEY, "all")
    for i = 1, #ns.Ignore.MODES do
        if ns.Ignore.MODES[i] == v then return v end
    end
    return "all"
end
function ns.Ignore.SetMode(mode)
    for i = 1, #ns.Ignore.MODES do
        if ns.Ignore.MODES[i] == mode then
            ns.Config.Set(BOX, KEY, mode)
            return
        end
    end
end
function ns.Ignore.NextMode()
    local now = ns.Ignore.Mode()
    for i = 1, #ns.Ignore.MODES do
        if ns.Ignore.MODES[i] == now then
            return ns.Ignore.MODES[(i % #ns.Ignore.MODES) + 1]
        end
    end
    return "all"
end
local function isFriend(name)
    local k = key(name)
    if not k then return false end
    for i = 1, ns.Compat.NumFriends() do
        if key((ns.Compat.FriendInfo(i))) == k then return true end
    end
    return false
end
local function isGuild(name)
    local k = key(name)
    if not k or not (IsInGuild and IsInGuild()) then return false end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return false end
    for i = 1, GetNumGuildMembers() do
        if key(GetGuildRosterInfo(i)) == k then return true end
    end
    return false
end
function ns.Ignore.Allowed(name)
    local who = ns.Link.Norm(name)
    if not who then return false, "block" end
    if ns.Ignore.Blocked(who) then return false, "block" end
    local mode = ns.Ignore.Mode()
    if mode == "none" then return false, "privacy" end
    local mate = ns.Pair.Mate() or ns.Pair.Saved()
    if mate and key(mate) == key(who) then return true end
    if mode == "all" then return true end
    if isFriend(who) then return true end
    if mode == "guild" and isGuild(who) then return true end
    return false, "privacy"
end
local boot = ns.NewFrame("Frame")
ns.Listen(boot, "PLAYER_ENTERING_WORLD")
boot:SetScript("OnEvent", function()
    ns.Compat.RefreshRoster()
end)
