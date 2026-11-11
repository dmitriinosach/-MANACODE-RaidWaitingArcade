local ADDON, ns = ...
ns.Table = {}
local T = ns.Table
local ANNOUNCE = 15
local ROOM_TTL = 45
local READY_WAIT = 15
local JOIN_WAIT = 6
local RELEASE_WAIT = 1
local TICK = 0.5
local BACK_TTL = 3 * 3600
local BACK_DELAY = 6
local role
local room
local rooms = {}
local watchers = {}
local hooks = {}
local joining
local announceAt = 0
local releaseAt
local backAt
local lineAt = 0
local LINE_GAP = 0.5
local function tell()
    for i = 1, #watchers do pcall(watchers[i]) end
end
function T.OnChange(fn)
    if type(fn) == "function" then watchers[#watchers + 1] = fn end
end
function T.Hooks(game, h)
    hooks[game] = h
end
local function hook(name, ...)
    local h = room and hooks[room.game]
    local fn = h and h[name]
    if fn then pcall(fn, ...) end
end
function T.Role() return role end
function T.Room() return room end
function T.Joining() return joining end
local function same(a, b)
    local x, y = ns.Link.Norm(a), ns.Link.Norm(b)
    return x ~= nil and y ~= nil and x:lower() == y:lower()
end
local function kindsStr()
    local out = {}
    for p = 1, #room.kinds do
        local k = room.kinds[p]
        if k == "o" and room.names[p] then k = "p" end
        out[p] = k
    end
    return table.concat(out)
end
function T.Kind(p)
    if not room then return nil end
    local k = room.kinds[p]
    if k == "o" and room.names[p] then return "p" end
    return k
end
function T.Name(p) return room and room.names[p] or nil end
function T.Class(p) return room and room.cls[p] or nil end
function T.PickOf(p) return room and room.picks and room.picks[p] or nil end
local function remember(r)
    ns.Config.Set("table", "last", r and { host = r.host, mid = r.mid, game = r.game, at = time() } or nil)
end
local function packOpts(opts)
    local s = ns.Link.Encode(opts)
    return s ~= "" and s or "-"
end
local function listStr(t, n)
    local out = {}
    for p = 1, n do
        local v = t[p]
        out[p] = (type(v) == "string" and v ~= "") and v or "-"
    end
    return table.concat(out, ".")
end
local function openSeat()
    for p = 1, #room.kinds do
        if room.kinds[p] == "o" and not room.names[p] then return p end
    end
    return nil
end
local function broadcast(tag, ...)
    ns.Link.Broadcast(tag, ...)
end
local function announce(force)
    if role ~= "host" then return end
    local now = GetTime()
    if not force and now - announceAt < ANNOUNCE then return end
    announceAt = now
    if room.playing or not openSeat() then
        broadcast("TC", room.mid)
        return
    end
    broadcast("TO", room.mid, room.game, ns.Link.Version(), kindsStr(), ns.Link.Encode(room.opts))
end
local function sendLineup()
    lineAt = GetTime()
    room.lineDue = nil
    local ks = kindsStr()
    local n = #room.kinds
    local names, cls = listStr(room.names, n), listStr(room.cls, n)
    local picks = { [1] = room.picks[0] }
    for p = 1, n do picks[p + 1] = room.picks[p] end
    local opts, pk = packOpts(room.opts), listStr(picks, n + 1)
    for p = 1, n do
        if room.names[p] then ns.Link.Send(room.names[p], "TL", room.mid, ks, names, cls, p, opts, pk) end
    end
end
local function lineup()
    if role ~= "host" or not room then return end
    if GetTime() - lineAt >= LINE_GAP then sendLineup() else room.lineDue = true end
end
local function pickFree(p, v)
    for q, w in pairs(room.picks) do
        if q ~= p and w == v then return false end
    end
    return true
end
local function keepHosted()
    if role ~= "host" or not room or not room.playing then return end
    local names = {}
    for p = 1, #room.kinds do names[p] = room.names[p] or room.gone[p] end
    local picks = {}
    for q, v in pairs(room.picks) do picks[q] = v end
    ns.Config.Set("table", "hosted", { game = room.game, mid = room.mid, at = time(), kinds = { unpack(room.kinds) },
        names = names, picks = picks, opts = room.opts })
end
local function dropHosted()
    ns.Config.Set("table", "hosted", nil)
end
local function dropPlayer(p, why)
    local who = room.names[p]
    if not who then return end
    room.names[p], room.cls[p] = nil, nil
    if room.playing and not why then
        room.gone[p] = who
        keepHosted()
    else
        room.picks[p] = nil
    end
    if why then ns.Link.Send(who, "TX", room.mid, why) end
    if room.ready then room.ready = nil end
    hook("left", p, who)
end
function T.Host(game, opts, kinds)
    if role == "guest" then T.Leave() end
    releaseAt = nil
    if role == "host" and room and room.game == game then
        room.opts = opts or {}
        for p = 1, #kinds do
            if kinds[p] ~= "o" and room.names[p] then dropPlayer(p, "kick") end
            room.kinds[p] = kinds[p]
        end
        for p = #kinds + 1, #room.kinds do room.kinds[p] = nil end
        lineup()
        announce(true)
        tell()
        return
    end
    role = "host"
    dropHosted()
    room = { mid = time(), game = game, opts = opts or {}, kinds = {}, names = {}, cls = {}, picks = {}, gone = {} }
    for p = 1, #kinds do room.kinds[p] = kinds[p] end
    announce(true)
    tell()
end
function T.Regather(game)
    local h = ns.Config.Get("table", "hosted")
    if type(h) ~= "table" or h.game ~= game or type(h.kinds) ~= "table" or time() - (h.at or 0) > BACK_TTL then
        return false
    end
    if role == "guest" then T.Leave() end
    releaseAt = nil
    role = "host"
    room = { mid = h.mid, game = game, opts = h.opts or {}, kinds = {}, names = {}, cls = {}, picks = {}, gone = {},
             playing = true }
    for p = 1, #h.kinds do room.kinds[p] = h.kinds[p] end
    for q, v in pairs(h.picks or {}) do room.picks[tonumber(q) or q] = v end
    for p, who in pairs(h.names or {}) do
        p = tonumber(p) or p
        if type(who) == "string" and room.kinds[p] == "o" then
            room.gone[p] = who
            ns.Link.Send(who, "TI", room.mid, game, ns.Link.Version(), ns.Link.Encode(room.opts))
        end
    end
    keepHosted()
    announce(true)
    tell()
    return true
end
function T.Players()
    local out = {}
    if role ~= "host" then return out end
    for p = 1, #room.kinds do
        if room.names[p] then out[#out + 1] = p end
    end
    return out
end
function T.Free(p)
    if role ~= "host" or not room.names[p] then return end
    dropPlayer(p, "kick")
    lineup()
    announce(true)
    tell()
end
function T.Pick(v)
    if type(v) ~= "string" or #v > 16 or not v:find("^[%w_]+$") or not room then return false end
    if role == "guest" then
        return ns.Link.Send(room.host, "TK", room.mid, v)
    end
    if role ~= "host" or not pickFree(0, v) then return false end
    room.picks[0] = v
    lineup()
    tell()
    return true
end
function T.Invite(who)
    if role ~= "host" then return false end
    who = ns.Link.Norm(who)
    if not who then return false end
    return ns.Link.Send(who, "TI", room.mid, room.game, ns.Link.Version(), ns.Link.Encode(room.opts))
end
function T.Ready(onGo)
    if role ~= "host" then return end
    local players = T.Players()
    if #players == 0 then
        onGo()
        return
    end
    room.ready = { until_ = GetTime() + READY_WAIT, yes = {}, go = onGo }
    for i = 1, #players do ns.Link.Send(room.names[players[i]], "TR", room.mid) end
    tell()
end
function T.ReadyCount()
    if role ~= "host" or not room.ready then return nil end
    local yes, all = 0, 0
    for _, p in ipairs(T.Players()) do
        all = all + 1
        if room.ready.yes[p] then yes = yes + 1 end
    end
    return yes, all
end
function T.Begin()
    if role ~= "host" then return end
    room.playing = true
    room.ready = nil
    keepHosted()
    announce(true)
    tell()
end
function T.End()
    if role ~= "host" then return end
    room.playing = false
    room.gone = {}
    dropHosted()
    announce(true)
    tell()
end
function T.SendView(p, seq, blob)
    if role ~= "host" or not room.names[p] then return end
    ns.Link.Send(room.names[p], "TS", room.mid, seq, blob)
end
function T.Close(hold)
    if role ~= "host" then return end
    local why = (hold and room.playing) and "hold" or "close"
    if why == "hold" then keepHosted() else dropHosted() end
    for p = 1, #room.kinds do
        if room.names[p] then ns.Link.Send(room.names[p], "TX", room.mid, why) end
    end
    broadcast("TC", room.mid)
    role, room = nil, nil
    tell()
end
function T.Join(host, mid, game, opts)
    host = ns.Link.Norm(host)
    if not host or not mid then return end
    if role == "host" then T.Close() end
    if role == "guest" then T.Leave() end
    joining = { host = host, mid = mid, game = game, opts = opts or {}, until_ = GetTime() + JOIN_WAIT }
    ns.Link.Send(host, "TJ", mid, ns.Link.Version())
    tell()
end
function T.Leave()
    if role ~= "guest" then return end
    ns.Link.Send(room.host, "TX", room.mid, "leave")
    if not room.seen then remember(nil) end
    role, room = nil, nil
    tell()
end
function T.Act(move, seq)
    if role ~= "guest" then return end
    ns.Link.Send(room.host, "TA", room.mid, seq, ns.Link.Encode(move))
end
function T.Release()
    if role then releaseAt = GetTime() + RELEASE_WAIT end
end
function T.Rooms(game)
    local out = {}
    local now = GetTime()
    for k, r in pairs(rooms) do
        if now - r.at > ROOM_TTL then
            rooms[k] = nil
        elseif not game or r.game == game then
            out[#out + 1] = r
        end
    end
    table.sort(out, function(a, b) return a.host:lower() < b.host:lower() end)
    return out
end
local function openGame(game, opts)
    ns.window:Open()
    local g = ns.Loop.Current()
    if g and g.def and g.def.id == game and not g:IsOver() then return g end
    ns.window:StartGame(game, opts)
    return ns.Loop.Current()
end
local function hostOnly(from, mid)
    return role == "host" and room and ns.Link.Num(mid) == room.mid
end
local function guestOnly(from, mid)
    return role == "guest" and room and same(from, room.host) and ns.Link.Num(mid) == room.mid
end
local function seatOf(from)
    for p = 1, #room.kinds do
        if same(room.names[p], from) then return p end
    end
    return nil
end
ns.Link.On("TO", function(from, aMid, aGame, aVer, aKinds, aOpts)
    local mid = ns.Link.Num(aMid)
    if not mid or tonumber(aVer) ~= ns.Link.Version() then return end
    if ns.Ignore and ns.Ignore.Blocked(from) then return end
    if not ns.games[aGame] then return end
    rooms[from:lower()] = { host = from, mid = mid, game = aGame, kinds = aKinds,
                            opts = ns.Link.Decode(aOpts), at = GetTime() }
    tell()
end)
ns.Link.On("TC", function(from, aMid)
    local r = rooms[from:lower()]
    if r and r.mid == ns.Link.Num(aMid) then
        rooms[from:lower()] = nil
        tell()
    end
end)
ns.Link.On("TJ", function(from, aMid, aVer)
    local mid = ns.Link.Num(aMid)
    if role ~= "host" or not room or mid ~= room.mid then
        if mid then ns.Link.Send(from, "TN", mid, "closed") end
        return
    end
    if tonumber(aVer) ~= ns.Link.Version() then ns.Link.Send(from, "TN", mid, "game") return end
    if ns.Ignore and ns.Ignore.Blocked(from) then ns.Link.Send(from, "TN", mid, "closed") return end
    if room.playing then
        local back
        for q, who in pairs(room.gone) do
            if same(who, from) and room.kinds[q] == "o" and not room.names[q] then back = q end
        end
        if not back then ns.Link.Send(from, "TN", mid, "busy") return end
        room.gone[back] = nil
        room.names[back] = from
        room.cls[back] = ns.Link.PeerClass(from)
        ns.Invite.Note(ns.T("tableBack", from))
        sendLineup()
        hook("back", back, from)
        tell()
        return
    end
    local p = seatOf(from) or openSeat()
    if not p then ns.Link.Send(from, "TN", mid, "full") return end
    room.names[p] = from
    room.cls[p] = ns.Link.PeerClass(from)
    ns.Invite.Note(ns.T("tableSat", from))
    lineup()
    announce(true)
    tell()
end)
ns.Link.On("TN", function(from, aMid, aWhy)
    if not joining or not same(from, joining.host) or ns.Link.Num(aMid) ~= joining.mid then return end
    if joining.back then remember(nil) end
    joining = nil
    ns.Invite.Note(ns.T("tableNo_" .. aWhy, from))
    tell()
end)
ns.Link.On("TL", function(from, aMid, aKinds, aNames, aCls, aPos, aOpts, aPicks)
    local mid = ns.Link.Num(aMid)
    local fresh = joining and same(from, joining.host) and mid == joining.mid
    if not fresh and not guestOnly(from, aMid) then return end
    local kinds, names, cls, picks = {}, {}, {}, {}
    for i = 1, #aKinds do kinds[i] = aKinds:sub(i, i) end
    local i = 0
    for v in aNames:gmatch("[^.]+") do i = i + 1; names[i] = (v ~= "-") and v or nil end
    i = 0
    for v in aCls:gmatch("[^.]+") do i = i + 1; cls[i] = (v ~= "-") and v or nil end
    i = -1
    for v in (aPicks or ""):gmatch("[^.]+") do i = i + 1; picks[i] = (v ~= "-") and v or nil end
    local pos = tonumber(aPos)
    if fresh then
        role = "guest"
        room = { host = from, mid = mid, game = joining.game, opts = joining.opts }
        joining = nil
        remember(room)
    end
    if aOpts then room.opts = ns.Link.Decode(aOpts) end
    room.kinds, room.names, room.cls, room.pos, room.picks = kinds, names, cls, pos, picks
    if fresh then openGame(room.game, room.opts) end
    tell()
end)
ns.Link.On("TR", function(from, aMid)
    if not guestOnly(from, aMid) then return end
    local mid, host = room.mid, room.host
    local def = ns.games[room.game]
    ns.Invite.Ask(host, def and ns.TL(def.label) or room.game, READY_WAIT,
        function() ns.Link.Send(host, "TY", mid, "y") end,
        function() ns.Link.Send(host, "TY", mid, "n") end,
        ns.T("tableReadyAsk"))
end)
ns.Link.On("TY", function(from, aMid, aYes)
    if not hostOnly(from, aMid) or not room.ready then return end
    local p = seatOf(from)
    if not p then return end
    if aYes ~= "y" then
        ns.Invite.Note(ns.T("tableNotReady", from))
        dropPlayer(p, "kick")
        lineup()
        announce(true)
        tell()
        return
    end
    room.ready.yes[p] = true
    local yes, all = T.ReadyCount()
    if yes == all then
        local go = room.ready.go
        room.ready = nil
        go()
    end
    tell()
end)
ns.Link.On("TS", function(from, aMid, aSeq, aBlob)
    if not guestOnly(from, aMid) then return end
    if not room.seen then
        room.seen = true
        remember(room)
    end
    local g = ns.Loop.Current()
    if not (g and g.def and g.def.id == room.game) or g:IsOver() then
        g = openGame(room.game, room.opts)
    end
    hook("view", aBlob, tonumber(aSeq))
end)
ns.Link.On("TA", function(from, aMid, aSeq, aMove)
    if not hostOnly(from, aMid) then return end
    local p = seatOf(from)
    if not p then return end
    hook("act", p, ns.Link.Decode(aMove), tonumber(aSeq))
end)
ns.Link.On("TX", function(from, aMid, aWhy)
    if guestOnly(from, aMid) then
        local host = room.host
        hook("closed")
        if aWhy ~= "hold" then remember(nil) end
        role, room = nil, nil
        ns.Invite.Note(ns.T(aWhy == "kick" and "tableKicked" or aWhy == "hold" and "tableHold" or "tableClosed", host))
        tell()
        return
    end
    if hostOnly(from, aMid) and aWhy == "leave" then
        local p = seatOf(from)
        if not p then return end
        dropPlayer(p, nil)
        ns.Invite.Note(ns.T("tableLeft", from))
        lineup()
        announce(true)
        tell()
    end
end)
ns.Link.On("TK", function(from, aMid, aPick)
    if not hostOnly(from, aMid) then return end
    local p = seatOf(from)
    if not p or room.playing then return end
    if pickFree(p, aPick) then room.picks[p] = aPick end
    lineup()
    tell()
end)
local function offerHost()
    local h = ns.Config.Get("table", "hosted")
    if type(h) ~= "table" or role or joining then return false end
    local def = ns.games[h.game]
    if not def or time() - (h.at or 0) > BACK_TTL or not ns.Store.HasSaved(h.game) then
        dropHosted()
        return false
    end
    ns.Invite.Ask(UnitName("player"), ns.TL(def.label) or h.game, 60,
        function()
            ns.window:Open()
            ns.window:StartGame(h.game, nil, true)
        end,
        function() dropHosted() end,
        ns.T("tableGatherAsk"))
    return true
end
local function offerBack()
    if offerHost() then return end
    local last = ns.Config.Get("table", "last")
    if type(last) ~= "table" or role or joining then return end
    if not (last.host and last.mid and ns.games[last.game]) or time() - (last.at or 0) > BACK_TTL then
        remember(nil)
        return
    end
    local def = ns.games[last.game]
    ns.Invite.Ask(last.host, ns.TL(def.label) or last.game, 45,
        function()
            T.Join(last.host, last.mid, last.game, {})
            if joining then joining.back = true end
        end,
        function() remember(nil) end,
        ns.T("tableBackAsk"))
end
ns.Link.On("TI", function(from, aMid, aGame, aVer, aOpts)
    local mid = ns.Link.Num(aMid)
    if not mid or tonumber(aVer) ~= ns.Link.Version() then return end
    local def = ns.games[aGame]
    if not def then return end
    local may = ns.Ignore.Allowed(from)
    if not may then return end
    if role then return end
    local opts = ns.Link.Decode(aOpts)
    ns.Invite.Ask(from, ns.TL(def.label) or aGame, 45,
        function() T.Join(from, mid, aGame, opts) end,
        function() end,
        ns.Records.Describe(def, opts))
end)
local ticker = ns.NewFrame("Frame")
local since = 0
ns.Listen(ticker, "PLAYER_LOGOUT")
ns.Listen(ticker, "PLAYER_ENTERING_WORLD")
ticker:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        backAt = GetTime() + BACK_DELAY
        return
    end
    if event ~= "PLAYER_LOGOUT" then return end
    if role == "host" then T.Close(true) elseif role == "guest" then T.Leave() end
end)
ticker:SetScript("OnUpdate", function(_, dt)
    since = since + dt
    if since < TICK then return end
    since = 0
    local now = GetTime()
    if joining and now > joining.until_ then
        local host = joining.host
        joining = nil
        ns.Invite.Note(ns.T("tableNo_timeout", host))
        tell()
    end
    if backAt and now >= backAt then
        backAt = nil
        offerBack()
    end
    if releaseAt and now >= releaseAt then
        releaseAt = nil
        local g = ns.Loop.Current()
        local here = g and g.def and room and g.def.id == room.game
        if not here then
            if role == "host" then T.Close() elseif role == "guest" then T.Leave() end
        end
    end
    if role ~= "host" or not room then return end
    if room.lineDue and now - lineAt >= LINE_GAP then sendLineup() end
    announce(false)
    local r = room.ready
    if r and now >= r.until_ then
        for _, p in ipairs(T.Players()) do
            if not r.yes[p] then
                ns.Invite.Note(ns.T("tableNotReady", room.names[p]))
                dropPlayer(p, "kick")
            end
        end
        room.ready = nil
        lineup()
        announce(true)
        tell()
    end
end)
