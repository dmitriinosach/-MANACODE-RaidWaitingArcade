local ADDON, ns = ...
ns.Pair = {}
local BOX = "pair"
local ASK_WAIT = 30
local GUEST_WAIT = 45
local PING = 15
local INVITE_GAP = 15
local invited = {}
local mate, stage, since, note
local deadline, auto
local watchers = {}
local nextPing = 0
local function tell()
    for i = 1, #watchers do watchers[i]() end
end
function ns.Pair.OnChange(fn)
    if type(fn) == "function" then watchers[#watchers + 1] = fn end
end
local function saved()
    local v = ns.Config.Get(BOX, "mate", nil)
    return type(v) == "string" and v or nil
end
local function remember(name)
    ns.Config.Set(BOX, "mate", name)
end
local function say(text)
    note = text
    tell()
end
local function news(text, key)
    if text then ns.News.Push{ text = text, key = key } end
end
local function reset(keepSaved)
    mate, stage, since, deadline = nil, nil, nil, nil
    if not keepSaved then remember(nil) end
    tell()
end
local function bind(who)
    mate, stage, since, deadline = who, "bound", time(), nil
    remember(who)
    local back = auto
    auto = nil
    say(back and ns.T("pairBack", who) or nil)
    news(back and ns.T("pairBack", who) or ns.T("pairNow", who), "pair")
end
function ns.Pair.Mate()
    return mate
end
function ns.Pair.Saved()
    return saved()
end
function ns.Pair.Class()
    return mate and ns.Link.PeerClass(mate) or nil
end
function ns.Pair.Bound()
    return stage == "bound"
end
function ns.Pair.Waiting()
    return stage == "asking"
end
function ns.Pair.Since()
    return since
end
function ns.Pair.Status()
    return note
end
function ns.Pair.Where()
    if not mate then return nil end
    if ns.Link.State(mate) ~= "yes" then return "gone" end
    local st = ns.Link.PeerHere(mate)
    if st == 3 then return "combat" end
    if st == 2 then return "duo" end
    if st == 0 then return "away" end
    return "live"
end
function ns.Pair.Call(name)
    if stage then return false end
    local who = ns.Link.Norm(name)
    if not who or ns.Link.IsMe(who) then return false end
    if ns.Link.State(who) ~= "yes" then return false end
    mate, stage = who, "asking"
    deadline = GetTime() + ASK_WAIT
    ns.Link.Send(who, "PR", ns.Link.Version())
    say(ns.T("pairSent", who))
    return true
end
function ns.Pair.Cancel()
    if stage ~= "asking" then return end
    reset(true)
    say(ns.T("pairCancelled"))
end
function ns.Pair.Break()
    if not stage then return end
    local who = mate
    if who then ns.Link.Send(who, "PRX") end
    if ns.Duo.Active() or ns.Duo.Held() then ns.Duo.Quit("quit") end
    reset()
    say(who and ns.T("pairGone", who) or nil)
end
function ns.Pair.Play(id, opts)
    if stage ~= "bound" or not mate then return false end
    if ns.Duo.Active() or ns.Duo.Waiting() then return false end
    if ns.Link.State(mate) ~= "yes" then
        ns.Link.Ask(mate)
        say(ns.T("duoAsking", mate))
        return false
    end
    return ns.Duo.Invite(id, mate, opts) and true or false
end
ns.Link.On("PR", function(from, aVer)
    local ok, why = ns.Ignore.Allowed(from)
    if not ok then
        if why == "privacy" then ns.Link.Send(from, "PRN", "closed") end
        return
    end
    if tonumber(aVer) ~= ns.Link.Version() then
        ns.Link.Send(from, "PRN", "game")
        return
    end
    if stage == "bound" then
        if ns.Link.Norm(from) == mate then
            ns.Link.Send(from, "PRY")
            return
        end
        ns.Link.Send(from, "PRN", "busy")
        return
    end
    if stage == "asking" then
        if ns.Link.Norm(from) == mate then
            ns.Link.Send(from, "PRY")
            bind(ns.Link.Norm(from))
            return
        end
        ns.Link.Send(from, "PRN", "busy")
        return
    end
    if ns.Link.Norm(from) == saved() then
        ns.Link.Send(from, "PRY")
        auto = true
        bind(ns.Link.Norm(from))
        return
    end
    if UnitAffectingCombat("player") then
        ns.Link.Send(from, "PRN", "combat")
        return
    end
    local k = (ns.Link.Norm(from) or from):lower()
    local now = GetTime()
    if invited[k] and now - invited[k] < INVITE_GAP then return end
    invited[k] = now
    ns.Invite.AskPair(from, GUEST_WAIT,
        function()
            invited[k] = nil
            ns.Link.Send(from, "PRY")
            bind(ns.Link.Norm(from))
        end,
        function(why)
            if why ~= "timeout" then invited[k] = nil end
            if why == "block" then return end
            ns.Link.Send(from, "PRN", why or "no")
        end)
end)
ns.Link.On("PRY", function(from)
    if stage ~= "asking" then return end
    if ns.Link.Norm(from) ~= mate then return end
    bind(mate)
end)
ns.Link.On("PRN", function(from, aWhy)
    if stage ~= "asking" then return end
    if ns.Link.Norm(from) ~= mate then return end
    local key = ({ no = "pairNoNo", busy = "pairNoBusy", combat = "duoNoCombat",
                   timeout = "duoNoTimeout", game = "duoNoGame",
                   closed = "duoNoClosed" })[aWhy] or "pairNoNo"
    local who = mate
    reset(true)
    say(ns.T(key, who))
    news(ns.T(key, who), "pair")
end)
ns.Link.On("PRX", function(from)
    if not stage or ns.Link.Norm(from) ~= mate then return end
    local who = mate
    reset()
    say(ns.T("pairLeft", who))
    news(ns.T("pairLeft", who), "pair")
end)
local ticker = CreateFrame("Frame")
local acc = 0
ticker:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc < 1 then return end
    acc = 0
    if stage == "asking" and deadline and GetTime() >= deadline then
        local who = mate
        reset(true)
        say(ns.T("duoNoTimeout", who or ""))
        news(ns.T("duoNoTimeout", who or ""), "pair")
        return
    end
    local now = GetTime()
    if now < nextPing then return end
    if stage == "bound" and mate then
        nextPing = now + PING
        ns.Link.Ask(mate)
        return
    end
    if not stage and saved() then
        nextPing = now + PING * 4
        ns.Link.Ask(saved())
    end
end)
ns.Link.OnPresence(function(name)
    if not name then return end
    local old = saved()
    if not stage and old and name:lower() == old:lower()
       and ns.Link.State(old) == "yes" then
        auto = true
        if not ns.Pair.Call(old) then auto = nil end
        return
    end
    if mate and name:lower() == mate:lower() then tell() end
end)
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    local who = saved()
    if who then ns.Link.Ask(who) end
end)
