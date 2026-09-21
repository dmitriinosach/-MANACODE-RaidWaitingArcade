local ADDON, ns = ...
ns.Duo = {}
local HOST_WAIT  = 60
local GUEST_WAIT = 45
local QUIET      = 60
local QUIET_ANS  = 5
local INVITE_GAP = 15
local AWAY       = 180
local TICK       = 0.5
local TAIL_MAX   = 16
local stage
local peer
local mid
local side
local gameId
local opts
local n = 0
local remote
local starting
local lastHeard
local pinged
local deadline
local heldAt
local reWait
local awaySince
local invited = {}
local pending
local watchers = {}
local function tell()
    for i = 1, #watchers do watchers[i]() end
end
local function sameName(a, b)
    local x, y = ns.Link.Norm(a), ns.Link.Norm(b)
    return x ~= nil and y ~= nil and x:lower() == y:lower()
end
function ns.Duo.OnChange(fn)
    if type(fn) == "function" then watchers[#watchers + 1] = fn end
end
local status
local function say(text)
    status = text
    tell()
end
function ns.Duo.Status()
    return status
end
function ns.Duo.ClearStatus()
    status = nil
end
function ns.Duo.Active()
    return stage == "play"
end
function ns.Duo.Waiting()
    return stage == "asking"
end
function ns.Duo.Peer()
    return peer
end
function ns.Duo.Held()
    return stage == "held"
end
function ns.Duo.Calling()
    return stage == "held" and reWait ~= nil
end
function ns.Duo.HeldAt()
    return heldAt
end
function ns.Duo.PeerState()
    if stage ~= "play" or not peer then return nil end
    if pinged then return "quiet" end
    local st = ns.Link.PeerHere(peer)
    if st == 3 then return "combat" end
    if st == 0 then return "away" end
    return "live"
end
function ns.Duo.Side()
    return side
end
function ns.Duo.Mid()
    return mid
end
function ns.Duo.MyTurn()
    if stage ~= "play" then return true end
    local game = ns.Loop.Current()
    if not game or not game.Turn then return true end
    local ok, t = ns.SafeCall(game, "Turn")
    if not ok then return true end
    return t == side
end
local function reset()
    stage, peer, mid, side, gameId, opts = nil, nil, nil, nil, nil, nil
    n = 0
    remote, lastHeard, pinged, deadline = nil, nil, nil, nil
    ns.Link.busy = false
    tell()
end
local function hold()
    if not stage or stage == "held" then return end
    stage = "held"
    heldAt = time()
    reWait, pinged, lastHeard, awaySince = nil, nil, nil, nil
    ns.Link.busy = false
    ns.window:SaveCurrent()
    if gameId then
        ns.Store.SetDuo(gameId, {
            peer = peer, mid = mid, side = side, n = n, at = heldAt,
        })
    end
    tell()
end
function ns.Duo.Quit(why)
    if not stage or stage == "held" then return end
    if starting then return end
    local who = peer
    if peer and mid then ns.Link.Send(peer, "END", mid, why) end
    if why == "over" or why == "desync" then
        if gameId then ns.Store.SetDuo(gameId, nil) end
        if why ~= "over" then ns.window:SaveCurrent() end
        reset()
        if why == "desync" then ns.Invite.Note(ns.T("duoDesync", who or "")) end
        return
    end
    hold()
    if why == "silence" then ns.Invite.Note(ns.T("duoLeft", who or "")) end
end
local function tellGame(why)
    local game = ns.Loop.Current()
    if game and game.PeerEnd then ns.SafeCall(game, "PeerEnd", why) end
end
function ns.Duo.Resign()
    if stage ~= "play" then return end
    if peer and mid then ns.Link.Send(peer, "END", mid, "resign") end
    if gameId then ns.Store.SetDuo(gameId, nil) end
    reset()
end
function ns.Duo.OfferDraw()
    if stage ~= "play" or not peer or not mid then return end
    ns.Link.Send(peer, "OF", mid, "draw")
    say(ns.T("duoDrawSent"))
end
function ns.Duo.GoSolo()
    if stage ~= "held" then return end
    local id = gameId
    if peer and mid then ns.Link.Send(peer, "END", mid, "quit") end
    reset()
    heldAt, reWait = nil, nil
    if id then ns.Store.SetDuo(id, nil) end
end
function ns.Duo.Adopt(id)
    if stage then return end
    local blk = ns.Store.Duo(id)
    if not blk or type(blk.peer) ~= "string" or type(blk.mid) ~= "number" then return end
    stage, gameId = "held", id
    peer, mid, side, n = blk.peer, blk.mid, blk.side or 1, blk.n or 0
    heldAt, reWait = blk.at, nil
    ns.Link.busy = false
    tell()
end
function ns.Duo.Gate()
    if stage ~= "play" then return "own" end
    if remote then return "remote" end
    return ns.Duo.MyTurn() and "own" or "no"
end
function ns.Duo.Sent(move)
    if stage ~= "play" then return end
    n = n + 1
    ns.Link.Send(peer, "MV", mid, n, ns.Link.Encode(move))
end
local function begin(id, o, seed, mySide)
    stage, gameId, opts, side, mid = "play", id, o, mySide, seed
    n = 0
    lastHeard, pinged = GetTime(), nil
    ns.Link.busy = true
    ns.window:SaveCurrent()
    starting = true
    ns.window:Open()
    ns.window:StartGame(id, o, false, seed)
    starting = false
    say(nil)
end
function ns.Duo.Target()
    if not UnitExists("target") then return nil, "duoNoTarget" end
    if not UnitIsPlayer("target") then return nil, "duoNotPlayer" end
    if UnitIsUnit("target", "player") then return nil, "duoSelf" end
    if UnitFactionGroup("target") ~= UnitFactionGroup("player") then
        return nil, "duoFaction"
    end
    local name, realm = UnitName("target")
    if type(name) ~= "string" or name == "" then return nil, "duoNoTarget" end
    if realm and realm ~= "" then return nil, "duoRealm" end
    return name, nil
end
function ns.Duo.Invite(id, name, o)
    if stage then return false end
    local who = ns.Link.Norm(name)
    local def = who and ns.games[id]
    if not who or not def or def.duo ~= "turns" then return false end
    if ns.Link.State(who) ~= "yes" then return false end
    mid = time()
    local roll = ns.RNG.New(mid + math.floor(GetTime() * 1000))
    local first = (roll:Int(2) == 1) and "h" or "g"
    peer, gameId, opts = who, id, o
    side = (first == "h") and 1 or 2
    stage = "asking"
    deadline = GetTime() + HOST_WAIT
    ns.Link.busy = true
    ns.Link.Send(who, "INV", mid, id, ns.Link.Version(), ns.Link.Encode(o), first)
    say(ns.T("duoSent", who))
    return true
end
function ns.Duo.Cancel()
    if stage ~= "asking" then return end
    reset()
    say(nil)
end
ns.Link.On("INV", function(from, aMid, aGame, aVer, aOpts, aFirst)
    local m = tonumber(aMid)
    if not m or m <= 0 then return end
    if aFirst ~= "h" and aFirst ~= "g" then return end
    local may, deny = ns.Ignore.Allowed(from)
    if not may then
        if deny == "privacy" then ns.Link.Send(from, "NO", m, "closed") end
        return
    end
    local now = GetTime()
    local k = from:lower()
    if invited[k] and now - invited[k] < INVITE_GAP then return end
    if tonumber(aVer) ~= ns.Link.Version() then
        ns.Link.Send(from, "NO", m, "game")
        return
    end
    local def = ns.games[aGame]
    if not def or def.duo ~= "turns" then
        ns.Link.Send(from, "NO", m, "game")
        return
    end
    if stage then
        ns.Link.Send(from, "NO", m, "busy")
        return
    end
    if UnitAffectingCombat("player") then
        ns.Link.Send(from, "NO", m, "combat")
        return
    end
    local o = ns.Link.Decode(aOpts)
    if pending then
        ns.Link.Send(pending.who, "NO", pending.mid, "busy")
        invited[pending.who:lower()] = nil
    end
    pending = { who = from, mid = m }
    invited[k] = now
    ns.Invite.Ask(from, def.label or aGame, GUEST_WAIT,
        function()
            pending = nil
            invited[k] = nil
            ns.Link.Send(from, "YES", m)
            peer = from
            begin(aGame, o, m, (aFirst == "h") and 2 or 1)
        end,
        function(why)
            pending = nil
            if why ~= "timeout" then invited[k] = nil end
            if why ~= "block" then ns.Link.Send(from, "NO", m, why or "no") end
        end,
        ns.Records.Describe(def, o), not sameName(from, ns.Pair.Mate()))
end)
ns.Link.On("YES", function(from, aMid)
    if stage ~= "asking" or from ~= peer then return end
    if tonumber(aMid) ~= mid then return end
    begin(gameId, opts, mid, side)
end)
ns.Link.On("NO", function(from, aMid, aWhy)
    if stage ~= "asking" or from ~= peer then return end
    if tonumber(aMid) ~= mid then return end
    local key = ({ no = "duoNoNo", busy = "duoNoBusy", combat = "duoNoCombat",
                   timeout = "duoNoTimeout", game = "duoNoGame",
                   closed = "duoNoClosed" })[aWhy] or "duoNoNo"
    local who = peer
    reset()
    say(ns.T(key, who))
    ns.News.Push{ text = ns.T(key, who), key = "duo" }
end)
ns.Link.On("MV", function(from, aMid, aN, aMove)
    if stage ~= "play" or from ~= peer then return end
    if tonumber(aMid) ~= mid then return end
    lastHeard, pinged = GetTime(), nil
    local num = tonumber(aN)
    if not num then return end
    if num <= n then return end
    if num > n + 1 then ns.Duo.Quit("desync") return end
    local move = ns.Link.Decode(aMove)
    if type(move.k) ~= "string" then ns.Duo.Quit("desync") return end
    local game = ns.Loop.Current()
    if not game then ns.Duo.Quit("desync") return end
    if ns.Duo.MyTurn() then ns.Duo.Quit("desync") return end
    n = num
    remote = true
    ns.SafeCall(game, "Move", move)
    remote = nil
    ns.window:RefreshHead()
end)
ns.Link.On("END", function(from, aMid, aWhy)
    if not stage or stage == "held" or from ~= peer then return end
    if ns.Link.Num(aMid) ~= mid then return end
    local who = peer
    local why = aWhy
    if why == "over" then reset() return end
    if why == "resign" then
        tellGame("resign")
        if gameId then ns.Store.SetDuo(gameId, nil) end
        reset()
        return
    end
    if why == "desync" then
        if gameId then ns.Store.SetDuo(gameId, nil) end
        ns.window:SaveCurrent()
        reset()
        ns.Invite.Note(ns.T("duoDesync", who))
        return
    end
    hold()
    ns.Invite.Note(ns.T("duoHeld", who))
end)
local function resumePlay(theirN)
    local game = ns.Loop.Current()
    local live = game and game.def and game.def.id == gameId
    if not live then
        starting = true
        ns.window:Open()
        ns.window:StartGame(gameId, nil, true)
        starting = false
    end
    stage = "play"
    heldAt, reWait, awaySince = nil, nil, nil
    lastHeard, pinged = GetTime(), nil
    ns.Link.busy = true
    if gameId then ns.Store.SetDuo(gameId, nil) end
    if theirN > n + TAIL_MAX or theirN < n - TAIL_MAX then
        ns.Duo.Quit("desync")
        return
    end
    if theirN < n then
        for i = theirN + 1, n do
            local mv = ns.window:MoveAt(i)
            if mv then ns.Link.Send(peer, "MV", mid, i, ns.Link.Encode(mv)) end
        end
    end
    say(nil)
end
function ns.Duo.Resume()
    if stage ~= "held" or not peer or reWait then return end
    ns.Link.Ask(peer)
    ns.Link.Send(peer, "RE", mid, n)
    reWait = GetTime() + HOST_WAIT
    say(ns.T("duoCalling", peer))
end
local function findHeld(m)
    for id in pairs(ns.games) do
        local blk = ns.Store.Duo(id)
        if blk and blk.mid == m then return id, blk end
    end
    return nil, nil
end
ns.Link.On("OF", function(from, aMid, aWhat)
    if stage ~= "play" or from ~= peer then return end
    if ns.Link.Num(aMid) ~= mid then return end
    if aWhat == "yes" then
        tellGame("draw")
        if gameId then ns.Store.SetDuo(gameId, nil) end
        reset()
        return
    end
    if aWhat == "no" then
        say(ns.T("duoDrawNo", peer or ""))
        return
    end
    if aWhat ~= "draw" then return end
    local who, m = peer, mid
    ns.Invite.Ask(who, ns.T("duoDrawAsk", who), GUEST_WAIT,
        function()
            ns.Link.Send(who, "OF", m, "yes")
            tellGame("draw")
            if gameId then ns.Store.SetDuo(gameId, nil) end
            reset()
        end,
        function()
            ns.Link.Send(who, "OF", m, "no")
        end)
end)
ns.Link.On("RE", function(from, aMid, aN)
    local m, num = tonumber(aMid), tonumber(aN)
    if not m or not num or num < 0 then return end
    if ns.Ignore.Blocked(from) then return end
    if stage == "held" and reWait and from == peer and m == mid then
        resumePlay(num)
        return
    end
    if stage == "play" or stage == "asking" then
        ns.Link.Send(from, "NO", m, "busy")
        return
    end
    local id, blk
    if stage == "held" and m == mid then
        id, blk = gameId, { peer = peer, mid = mid, side = side, n = n }
    else
        id, blk = findHeld(m)
    end
    if not id or not blk or ns.Link.Norm(blk.peer) ~= ns.Link.Norm(from) then
        ns.Link.Send(from, "NO", m, "game")
        return
    end
    if UnitAffectingCombat("player") then
        ns.Link.Send(from, "NO", m, "combat")
        return
    end
    local def = ns.games[id]
    ns.Invite.Ask(from, def and def.label or id, GUEST_WAIT,
        function()
            stage, gameId = "held", id
            peer, mid, side, n = blk.peer, blk.mid, blk.side or 1, blk.n or 0
            ns.Link.Send(from, "RE", m, n)
            resumePlay(num)
        end,
        function(why)
            ns.Link.Send(from, "NO", m, why or "no")
        end)
end)
ns.Link.OnPresence(function(name)
    if stage ~= "play" or not peer then return end
    if name:lower() ~= peer:lower() then return end
    lastHeard, pinged = GetTime(), nil
end)
local ticker = CreateFrame("Frame")
local since = 0
ticker:RegisterEvent("PLAYER_TARGET_CHANGED")
ticker:SetScript("OnEvent", function()
    if not stage then tell() end
end)
ns.Link.OnPresence(function()
    if not stage then tell() end
end)
ticker:SetScript("OnUpdate", function(_, elapsed)
    if not stage then return end
    since = since + elapsed
    if since < TICK then return end
    since = 0
    local now = GetTime()
    if stage == "held" then
        if reWait and now >= reWait then
            local who = peer
            reWait = nil
            say(ns.T("duoNoTimeout", who))
        end
        return
    end
    if stage == "play" and ns.Link.PeerHere(peer) == 0 then
        awaySince = awaySince or now
        if now - awaySince >= AWAY then
            local who = peer
            hold()
            ns.Invite.Note(ns.T("duoHeld", who or ""))
            return
        end
    else
        awaySince = nil
    end
    if stage == "asking" then
        if deadline and now >= deadline then
            local who = peer
            reset()
            say(ns.T("duoNoTimeout", who))
        end
        return
    end
    if ns.Duo.MyTurn() then
        lastHeard, pinged = now, nil
        return
    end
    if pinged then
        if now - pinged >= QUIET_ANS then ns.Duo.Quit("silence") end
        return
    end
    if lastHeard and now - lastHeard >= QUIET then
        pinged = now
        ns.Link.Send(peer, "HI", ns.Link.Version())
    end
end)
