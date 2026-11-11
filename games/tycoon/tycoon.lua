local ADDON, ns = ...
local ID = "tycoon"
local B, R, T = ns.TycoonBoards, ns.Tycoon, ns.Table
local V = ns.TycoonView
local floor, max, min = math.floor, math.max, math.min
local BOT_PAUSE = 0.8
local STEP = 0.12
local END_FLASH = 0.8
local MISS_AWAY = 2
local MAX_LOG = 40
local SEND_MAX = 6
local POS_ORDER = { "left", "top", "right" }
local game
local function seatsOf(opts)
    local s = type(opts) == "table" and opts.seats
    if type(s) ~= "string" or not s:match("^[box][box][box]$") then s = "bbb" end
    if not s:find("[bo]") then s = "xbx" end
    return s
end
local function boardOf(opts)
    local b = type(opts) == "table" and opts.board
    if B.INDEX[b] then return b end
    return "azeroth"
end
local CFG_KEYS = { "gold", "turn", "auc", "trade", "fin" }
local function hostOpts(self)
    local o = { board = self.board, seats = self.seats }
    for _, k in ipairs(CFG_KEYS) do o[k] = self.cfg[k] end
    return o
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.log = {}
    self.away, self.miss = {}, {}
    return self
end
function Game:PosList()
    local room = T.Room()
    local kinds = room and room.game == ID and room.kinds or nil
    local out = {}
    for i = 1, 3 do
        local k = kinds and kinds[i] or self.seats:sub(i, i)
        if k ~= "x" then out[#out + 1] = i end
    end
    return out
end
function Game:PosOf(q)
    if q == 1 then return nil end
    return self:PosList()[q - 1]
end
function Game:SeatOf(pos)
    local list = self:PosList()
    for i = 1, #list do if list[i] == pos then return i + 1 end end
    return nil
end
function Game:Human(q)
    if q == 1 then return true end
    local p = self:PosOf(q)
    return p ~= nil and T.Kind(p) == "p"
end
function Game:Live()
    return T.Role() == "host" and T.Room() and T.Room().playing and #T.Players() > 0
end
function Game:Me()
    if self.guest then
        local room = T.Room()
        local q = room and room.game == ID and room.pos and self:SeatOf(room.pos)
        if q then self.meSeat = q end
        return self.meSeat or 1
    end
    return 1
end
function Game:SeatName(q)
    local room = T.Room()
    if q == 1 then
        if self.guest then return room and room.host or "" end
        return UnitName("player") or ""
    end
    local p = self:PosOf(q)
    local name = p and T.Name(p)
    if name and not self.away[q] then return name end
    local tok = self.S and self.S.token[q] or (self.view and self.view.seats[q] and self.view.seats[q].token)
    if tok then return ns.T("tycoon.botName", ns.T("tycoon.tok" .. tok)) end
    return ns.T("tycoon.bot")
end
local HEX = {}
for q, c in ipairs(B.SEAT_COLOR) do
    local r, g, b = c[1] + (1 - c[1]) * 0.35, c[2] + (1 - c[2]) * 0.35, c[3] + (1 - c[3]) * 0.35
    HEX[q] = string.format("%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end
function Game:SeatTag(q)
    local name = self:SeatName(q)
    if not HEX[q] then return name end
    return "|cff" .. HEX[q] .. name .. "|r"
end
function Game:Hover(c)
    if self.phase ~= "play" or self.hover == c then return end
    self.hover = c
    V.DrawCard(self)
end
function Game:Start(seed, moves)
    V.Ensure(self.canvas)
    V.EnsureMenu(self.canvas)
    game = self
    V.game = self
    local room = T.Room()
    self.guest = T.Role() == "guest" and room and room.game == ID or false
    self.seats = seatsOf(self.opts)
    self.board = self.guest and boardOf(room.opts) or boardOf(self.opts)
    self.opts = self.opts or {}
    self.cfg = R.Cfg(self.guest and room.opts or self.opts)
    self.opts.seats, self.opts.board = self.seats, self.board
    self.seed = seed
    self.S, self.view, self.pending = nil, nil, nil
    self.t, self.lastT, self.overT, self.holdUntil = 0, 0, 0, 0
    self.log, self.sel, self.tb, self.fate = {}, nil, nil, {}
    self.away, self.miss = {}, {}
    self.browse = false
    self.myTurn = false
    V.Reset()
    if not self.guest and moves and type(moves[1]) == "string" then
        local S = R.Load(moves[1])
        if S then
            self.S = S
            self.board = S.board
            self.opts.board = S.board
            self.cfg = R.Cfg(S.cfg)
        end
    end
    self.phase = self.S and "play" or "menu"
    local held = room and T.Role() == "host" and room.game == ID and room.playing
    if not self.guest and not (self.S and (held or T.Regather(ID))) then
        if self.S then
            self.seats = self.seats:gsub("o", "b")
            self.opts.seats = self.seats
        end
        local kinds = {}
        for i = 1, 3 do kinds[i] = self.seats:sub(i, i) end
        T.Host(ID, hostOpts(self), kinds)
    end
    for _, k in ipairs(CFG_KEYS) do self.opts[k] = self.cfg[k] end
    V.Show()
    self:Draw()
    if self.S and held then self:Push() end
    return true
end
function Game:Serialize()
    if self.guest or not self.S or self.S.over then return nil end
    return R.Save(self.S)
end
function Game:Restart(seats, board)
    ns.Store.Clear(ID)
    local o = hostOpts(self)
    o.seats, o.board = seats or self.seats, board or self.board
    ns.window:StartGame(ID, o)
end
function Game:PickBoard(key)
    if self.phase ~= "menu" or self.guest or not B.INDEX[key] or key == self.board then return end
    self.board = key
    self.opts.board = key
    local kinds = {}
    for i = 1, 3 do kinds[i] = self.seats:sub(i, i) end
    T.Host(ID, hostOpts(self), kinds)
    self:Draw()
end
function Game:PickRule(key)
    local list = R.CFG_LIST[key]
    if self.phase ~= "menu" or self.guest or not list then return end
    local at = 1
    for i, x in ipairs(list) do if x == self.cfg[key] then at = i end end
    self.cfg[key] = list[at % #list + 1]
    self.opts[key] = self.cfg[key]
    local kinds = {}
    for i = 1, 3 do kinds[i] = self.seats:sub(i, i) end
    T.Host(ID, hostOpts(self), kinds)
    self:Draw()
end
function Game:PickSeat(pos, key)
    local i
    for k = 1, 3 do if POS_ORDER[k] == pos then i = k end end
    if not i or self.phase ~= "menu" or self.guest then return end
    if key == "free" then
        T.Free(i)
        self:Draw()
        return
    end
    local want = (key == "bot") and "b" or (key == "off") and "x" or "o"
    local s = self.seats:sub(1, i - 1) .. want .. self.seats:sub(i + 1)
    if not s:find("[bo]") then return end
    if s ~= self.seats then self:Restart(s) end
    if key == "call" then
        ns.CallPanel.Show(ns.window:Frame(), {
            title = ns.T("tycoon.callTitle"), autoHide = true,
            onCall = function(who)
                T.Invite(who)
                ns.CallPanel.Hide()
                return true
            end,
        })
    end
end
function Game:SeatMenu(pos, anchor)
    if self.phase ~= "menu" or self.guest or pos == "me" then return end
    local i
    for k = 1, 3 do if POS_ORDER[k] == pos then i = k end end
    if not i then return end
    local kind = T.Kind(i) or self.seats:sub(i, i)
    V.SeatMenu(pos, anchor, kind)
end
function Game:BotTokens()
    local used, out = {}, {}
    local p0 = T.PickOf(0)
    local t0 = p0 and tonumber(p0:match("^t(%d)$"))
    if t0 then used[t0] = true end
    local list = self:PosList()
    for _, pos in ipairs(list) do
        local p = T.PickOf(pos)
        local t = p and tonumber(p:match("^t(%d)$"))
        if t and (T.Kind(pos) == "p") then used[t] = true end
    end
    for _, pos in ipairs(list) do
        local kind = T.Kind(pos) or self.seats:sub(pos, pos)
        if kind == "b" then
            for t = 1, 8 do
                if not used[t] then used[t], out[pos] = true, t break end
            end
        end
    end
    return out
end
function Game:MyPick()
    if self.guest then
        local room = T.Room()
        return room and room.pos and T.PickOf(room.pos) or nil
    end
    return T.PickOf(0)
end
function Game:TakenPicks()
    local out = {}
    local p0 = T.PickOf(0)
    if p0 then out[p0] = 1 end
    for _, pos in ipairs(self:PosList()) do
        local p = T.PickOf(pos)
        if p then out[p] = self:SeatOf(pos) end
    end
    return out
end
function Game:PickToken(i)
    if self.phase ~= "menu" then return end
    if not T.Pick("t" .. i) then ns.Sfx.Play("deny") end
    self:Draw()
end
function Game:FindButton()
    if self.guest then
        T.Leave()
        self:Restart()
        return
    end
    self.browse = not self.browse
    self:Draw()
end
function Game:Sit(r)
    T.Join(r.host, r.mid, r.game, r.opts)
    self:Draw()
end
function Game:Ready()
    for i = 1, 3 do
        if self.seats:sub(i, i) == "o" and T.Kind(i) ~= "p" then return false end
    end
    return true
end
function Game:BeginRound()
    if self.phase ~= "menu" or self.guest then return end
    if not self:Ready() then return end
    if T.Room() and T.Room().ready then return end
    T.Ready(function() if game then game:Deal() end end)
    self:Draw()
end
function Game:Deal()
    if self.phase ~= "menu" or self.guest then return end
    local n = #self:PosList() + 1
    self.S = R.Deal(self.seed, n, self.board, self.cfg)
    local used, tok, hum = {}, {}, {}
    local function pickOf(q)
        local p = (q == 1) and T.PickOf(0) or T.PickOf(self:PosOf(q))
        local t = p and tonumber(p:match("^t(%d)$"))
        if t and not used[t] then return t end
        return nil
    end
    for q = 1, n do
        local t = self:Human(q) and pickOf(q) or nil
        if t then used[t] = true end
        tok[q] = t
    end
    for q = 1, n do
        if not tok[q] then
            for t = 1, 8 do
                if not used[t] then used[t], tok[q] = true, t break end
            end
        end
        hum[q] = self:Human(q) and "1" or "0"
    end
    local ts = {}
    for q = 1, n do ts[q] = tostring(tok[q]) end
    self.phase = "play"
    self.lastT = self.t
    self.away, self.miss = {}, {}
    T.Begin()
    ns.Sfx.Play("start")
    self:Move({ k = "setup", s = 1, tok = table.concat(ts), hum = table.concat(hum) })
    self:MusicStart()
    self:Draw()
end
local function stageOwn(S, c, s, lv, mort)
    S.own[c], S.lv[c], S.mort[c] = s, lv or 0, mort or false
end
local function stageMid(S)
    local who = { 1, 2, 0, 3, 1, 0, 4, 0, 3, 2 }
    local lv = { 2, 1 }
    for g = 1, 10 do
        local list = B.groups[g]
        for k, c in ipairs(list) do
            if who[g] > 0 and (g <= 2 or k < #list) then stageOwn(S, c, who[g], lv[g] or 0) end
        end
    end
    S.mort[B.groups[5][1]] = true
    S.cash = { 940, 1310, 620, 1480 }
    S.pos = { 6, 24, 6, 33 }
    S.turn = 1
end
local function stageLate(S)
    local lv = { 4, 4, 3, 1, 5, 5, 5, 5, 0, 0 }
    for g = 1, 10 do
        for _, c in ipairs(B.groups[g]) do stageOwn(S, c, (g - 1) % 4 + 1, lv[g]) end
    end
    local rails = B.groups[9]
    S.mort[rails[2]], S.mort[rails[4]], S.mort[B.groups[10][2]] = true, true, true
    S.cash = { 9999, 12450, 345, 8800 }
    S.pos = { 39, 39, 39, 39 }
    S.dice = { 3, 4 }
    S.turn = 1
    S.rolled = true
end
function Game:Stage(n)
    if self.guest or self.phase ~= "menu" then return end
    n = max(1, min(7, floor(n or 1)))
    self.seats, self.opts.seats = "bbb", "bbb"
    T.Host(ID, { board = self.board, seats = self.seats }, { "b", "b", "b" })
    self:Deal()
    local S = self.S
    if not S or n == 1 then return end
    if n == 2 or n == 4 or n == 5 then stageMid(S) else stageLate(S) end
    if n == 4 then
        S.auc = { c = 24, bid = 60, lead = 2, who = 1, passed = {} }
        S.phase, S.turn, S.rolled = "auction", 3, true
    elseif n == 5 then
        S.offer = { from = 2, to = 1, ga = 150, gb = 0, la = R.MaskOf({ 6 }), lb = R.MaskOf({ 1 }), ja = "", jb = "" }
        S.phase, S.turn, S.offers = "trade", 2, 1
    elseif n == 6 then
        S.cash[1] = 120
        S.debts = { { from = 1, to = 2, sum = 1500 } }
        S.phase, S.flow = "debt", "after"
    elseif n == 7 then
        for q = 1, S.n do S.alive[q] = false end
        S.out = { 3, 4, 2, 1 }
        S.over, S.phase = true, "over"
        S.ev = { k = "over", s = 1, c = 0, v = 0 }
    end
    S.seq = S.seq + 1
    V.Reset()
    if S.over then T.End() end
    self.lastT = self.t
    self:AfterChange()
    self:Push()
    self:Draw()
end
function Game:LeftFor(q)
    if self.guest then
        local v = self.view
        if not v or v.over or v.who ~= q then return nil end
        local limit = R.TimeOf(self.cfg, v.phase)
        if not limit or not self.leftUntil then return nil end
        return max(0, self.leftUntil - self.t), limit
    end
    local S = self.S
    if not S or S.over then return nil end
    local who, limit = R.Waiting(S)
    if who ~= q or not limit then return nil end
    if not self:Live() or not self:Human(q) or self.away[q] then return nil end
    return max(0, limit - (self.t - self.lastT)), limit
end
local function hosting(self)
    local room = T.Room()
    return T.Role() == "host" and room and self.S and (room.playing or self.S.over)
end
function Game:Push(only)
    if not hosting(self) then return end
    self.dirty = self.dirty or {}
    for q = 2, self.S.n do
        if not only or only == q then self.dirty[q] = true end
    end
    self:Flush()
end
function Game:Flush()
    local d = self.dirty
    if not d or not next(d) then return end
    if not hosting(self) then
        self.dirty = nil
        return
    end
    local now = GetTime()
    local sent = {}
    for _, at in ipairs(self.sent or {}) do
        if now - at < 1 then sent[#sent + 1] = at end
    end
    self.sent = sent
    local who = R.Waiting(self.S)
    local order = {}
    if who and d[who] then order[1] = who end
    for q = 2, self.S.n do
        if d[q] and q ~= who then order[#order + 1] = q end
    end
    local blob
    for _, q in ipairs(order) do
        if #sent >= SEND_MAX then return end
        d[q] = nil
        local p = self:PosOf(q)
        if p and T.Kind(p) == "p" then
            blob = blob or R.Pack(self:View())
            T.SendView(p, self.S.seq, blob)
            if self.repush and self.repush[q] and now >= self.repush[q] then self.repush[q] = nil end
            sent[#sent + 1] = now
        end
    end
end
function Game:Note(e)
    local v = self:View()
    if not v then return end
    local s = V.EventText(self, v, e)
    if e.k == "bankrupt" then self.fate[e.s] = { to = e.c }
    elseif e.k == "quit" then self.fate[e.s] = { quit = true, to = e.c } end
    if s then
        self.log[#self.log + 1] = s
        if #self.log > MAX_LOG then table.remove(self.log, 1) end
    end
    local k = e.k
    if k == "roll" then
        ns.Sfx.Play("pick")
    elseif k == "move" then
        ns.Sfx.Play("slide")
    elseif k == "buy" or k == "up" or k == "bid" or (k == "freecard" and e.v == 1) then
        ns.Sfx.Play("pop")
    elseif k == "set" or k == "hotel" then
        ns.Sfx.Play("big")
    elseif k == "won" or k == "yes" then
        ns.Sfx.Play("clear")
    elseif k == "jail" then
        ns.Sfx.Play("stuck")
    elseif k == "over" then
        ns.Sfx.Play("over")
    end
    V.Event(self, e)
    if e.k == "move" or e.k == "roll" then
        self.holdUntil = max(self.holdUntil, self.t + 0.7)
    elseif e.k == "card" then
        self.holdUntil = max(self.holdUntil, self.t + 3.2)
    end
end
function Game:AfterChange()
    local v = self:View()
    if not v then return end
    local me = self:Me()
    local mine = not v.over and v.who == me
    if mine and not self.myTurn then ns.Sfx.Play("turn") end
    self.myTurn = mine
    if v.over and not self.wasOver then
        self.wasOver = true
        self.overT = 0
    end
end
function Game:Move(m)
    if self.phase ~= "play" or self.guest or not self.S then return false end
    if not R.Legal(self.S, m) then return false end
    R.Apply(self.S, m)
    self.lastT = self.t
    if m.k == "roll" then self.holdUntil = self.t + 0.7 end
    for _, e in ipairs(self.S.log or {}) do self:Note(e) end
    self:AfterChange()
    if self.tb and (m.k == "offer" or m.k == "end" or m.k == "quit") then self.tb = nil end
    self:Push()
    if self.S.over then T.End() end
    self:Draw()
    return true
end
function Game:Act(m)
    if self.phase ~= "play" then return end
    if self.guest then
        if not self.view then return end
        local w = {}
        for k, v in pairs(m) do w[k] = v end
        w.s = self:Me()
        if type(w.la) == "string" then w.la = "m" .. w.la end
        if type(w.lb) == "string" then w.lb = "m" .. w.lb end
        self.pending = self.view.seq
        T.Act(w, self.view.seq)
        return
    end
    m.s = 1
    if not self:Move(m) then ns.Sfx.Play("deny") end
end
function Game:RemoteAct(pos, m, seq)
    if self.guest or self.phase ~= "play" or type(m) ~= "table" then return end
    local q = self:SeatOf(pos)
    if not q then return end
    m.s = q
    for _, k in ipairs({ "la", "lb" }) do
        local v = m[k]
        if v ~= nil then m[k] = (type(v) == "string" and v:sub(1, 1) == "m") and v:sub(2) or false end
    end
    self.away[q], self.miss[q] = nil, 0
    if seq ~= self.S.seq or not self:Move(m) then self:Push(q) end
end
function Game:SeatLeft(pos)
    local q = self:SeatOf(pos)
    if q then self.away[q] = true end
    self:Draw()
end
function Game:SeatBack(pos)
    local q = self:SeatOf(pos)
    if not q then return end
    self.away[q], self.miss[q] = nil, 0
    self:Push(q)
    self.repush = self.repush or {}
    self.repush[q] = GetTime() + 0.6
    self:Draw()
end
function Game:SetView(blob)
    if not self.guest then return end
    local v = R.Unpack(blob)
    if not v then return end
    if self.pending and v.seq == self.pending then ns.Sfx.Play("deny") end
    self.pending = nil
    local old = self.view
    self.view = v
    self.board = B.ORDER[(v.board or 0) + 1] or "azeroth"
    self.leftUntil = v.left and (self.t + v.left) or nil
    self.remAt = self.t
    if not old or v.seq ~= old.seq then self:Note(v.ev) end
    if self.phase ~= "play" then
        self.phase = "play"
        self.lastT = self.t
        ns.Sfx.Play("start")
        self:MusicStart()
    end
    self:AfterChange()
    if self.tb and (v.phase ~= "pre" and v.phase ~= "post" and v.phase ~= "debt") then self.tb = nil end
    self:Draw()
end
function Game:Bots()
    local S = self.S
    local q = R.Waiting(S)
    if not q or q == 1 then return nil end
    if self:Human(q) and not self.away[q] then return nil end
    return R.Bot(S, q)
end
function Game:Timeouts()
    if not self:Live() then return false end
    local S = self.S
    local q, limit = R.Waiting(S)
    if not q or not limit or not self:Human(q) or self.away[q] then return false end
    if self.t - self.lastT < limit then return false end
    local m = R.Default(S, q)
    if m and self:Move(m) then
        if q ~= 1 then
            self.miss[q] = (self.miss[q] or 0) + 1
            if self.miss[q] >= MISS_AWAY then self.away[q] = true end
        end
        return true
    end
    return false
end
function Game:Update(dt)
    if self.phase ~= "play" then return end
    if not self.guest then
        for q, at in pairs(self.repush or {}) do
            if GetTime() >= at then
                self.repush[q] = nil
                self:Push(q)
            end
        end
        self:Flush()
        if UnitAffectingCombat and UnitAffectingCombat("player") then return end
    end
    self.t = self.t + dt
    if not self.guest and self.S and not self.S.over then self.S.played = (self.S.played or 0) + dt end
    V.Tick(self, dt)
    self:MusicTick(dt)
    if self.wasOver then
        self.overT = self.overT + dt
        return
    end
    if self.t % 1 < dt then self:Draw() end
    if self.guest then return end
    if self:Timeouts() then return end
    if self.t < self.holdUntil or V.Moving() then return end
    if self.t - self.lastT < BOT_PAUSE then return end
    local m = self:Bots()
    if m then self:Move(m) end
end
function Game:MusicStart()
    if not ns.Music.Live() then return end
    local keys = B.music[self.board] or {}
    local list = {}
    for _, key in ipairs(keys) do
        for _, e in ipairs(ns.Music.List(key)) do
            if not ns.Music.Banned(e.p) then list[#list + 1] = e end
        end
    end
    if #list == 0 then return end
    local r = ns.RNG.New(time())
    r:Shuffle(list)
    self.music = { list = list, at = 0, left = 0 }
end
function Game:MusicTick(dt)
    local m = self.music
    if not m then return end
    if not ns.Music.Live() then
        self.music = nil
        return
    end
    m.left = m.left - dt
    if m.left > 0 then return end
    m.at = m.at % #m.list + 1
    local e = m.list[m.at]
    m.left = (e.sec or 90) + 2
    ns.Music.Play(e.p)
end
function Game:MusicStop()
    if not self.music then return end
    self.music = nil
    ns.Music.Stop()
    if ns.Music.On() then ns.Music.Restart() end
end
function Game:Score() return 0 end
function Game:View()
    if self.guest then return self.view end
    if not self.S then return nil end
    local who = R.Waiting(self.S)
    return R.View(self.S, who and self:LeftFor(who) or nil)
end
function Game:IsOver()
    local v = self:View()
    return v ~= nil and v.over and self.overT >= END_FLASH and not V.Moving()
end
function Game:ResultText()
    local v = self:View()
    if not v or not v.over then return nil end
    local me = self:Me()
    local st = v.seats[me]
    if not st then return nil end
    if st.out == v.n then return ns.T("tycoon.resWin") end
    local idx = v.n - st.out + 1
    if idx <= 3 and st.out <= 3 then return ns.T("tycoon.resOut" .. st.out) end
    return ns.T("tycoon.resPlace", idx)
end
function Game:Stop()
    V.Hide()
    V.HideMenu()
    self:MusicStop()
    T.Release()
    if game == self then game = nil end
    if V.game == self then V.game = nil end
end
function Game:Click(x, y, button)
    if self.phase ~= "play" then return end
    local c = V.HitCell(x, 720 - y)
    if button == "RightButton" then
        self.sel = nil
        self:Draw()
        return
    end
    if c then self:CellClick(c) end
end
function Game:CellClick(c)
    if self.phase ~= "play" then return end
    if self.tb then
        self:TradeToggle(c)
        return
    end
    self.sel = c
    ns.Sfx.Ui()
    self:Draw()
end
function Game:TradeOpen()
    local v = self:View()
    if not v or v.over then return end
    local me = self:Me()
    local to
    for q = 1, v.n do
        if q ~= me and v.seats[q].alive then to = to or q end
    end
    self.tb = { to = to, give = {}, get = {}, ga = 0, gb = 0, ja = "", jb = "" }
    self:Draw()
end
function Game:TradeWho(q)
    local tb = self.tb
    if not tb or tb.to == q then return end
    tb.to, tb.get, tb.gb, tb.jb = q, {}, 0, ""
    self:Draw()
end
function Game:TradeToggle(c)
    local tb, v = self.tb, self:View()
    if not tb or not v or not B.cells[c].price then return end
    local owner = v.own[c]
    if owner == self:Me() then
        tb.give[c] = not tb.give[c] or nil
    elseif tb.to and owner == tb.to then
        tb.get[c] = not tb.get[c] or nil
    else
        return
    end
    ns.Sfx.Ui()
    self:Draw()
end
function Game:TradeGold(side, n)
    local tb = self.tb
    if not tb then return end
    if side == "a" then tb.ga = n else tb.gb = n end
    self:Draw()
end
function Game:TradeCard(side)
    local tb, v = self.tb, self:View()
    if not tb or not v then return end
    if side == "a" then
        tb.ja = tb.ja == "" and v.seats[self:Me()].free:sub(1, 1) or ""
    elseif tb.to then
        tb.jb = tb.jb == "" and v.seats[tb.to].free:sub(1, 1) or ""
    end
    self:Draw()
end
function Game:TradeMove()
    local tb = self.tb
    if not tb or not tb.to then return nil end
    local la, lb = {}, {}
    for c in pairs(tb.give) do la[#la + 1] = c end
    for c in pairs(tb.get) do lb[#lb + 1] = c end
    return { k = "offer", s = self:Me(), to = tb.to, ga = tb.ga, gb = tb.gb, la = R.MaskOf(la), lb = R.MaskOf(lb),
             ja = tb.ja, jb = tb.jb }
end
function Game:TradeSend()
    local m = self:TradeMove()
    if not m then return end
    self.tb = nil
    self:Act(m)
    self:Draw()
end
function Game:TradeCancel()
    self.tb = nil
    self:Draw()
end
function Game:Brink()
    if self.guest then return end
    if self.phase == "menu" then
        self.seats = "xbx"
        self.opts.seats = self.seats
        T.Host(ID, { board = self.board, seats = self.seats }, { "x", "b", "x" })
        self:Deal()
    end
    local S = self.S
    if not S or S.over then return end
    S.phase, S.flow, S.turn, S.rolled = "pre", "pre", 1, false
    S.auc, S.offer, S.buyAt, S.debts, S.liens = nil, nil, nil, {}, {}
    for q = 2, S.n do
        if S.alive[q] then
            S.cash[q] = 1
            for _, c in ipairs(B.props) do
                if S.own[c] == q then S.own[c], S.lv[c], S.mort[c] = 1, 0, false end
            end
        end
    end
    S.cash[1] = 5000
    self:Draw()
end
function Game:Draw()
    if self.phase == "menu" then
        V.Hide()
        V.DrawMenu(self)
        return
    end
    V.HideMenu()
    V.Show()
    V.Draw(self)
end
T.Hooks(ID, {
    act = function(pos, m, seq) if game then game:RemoteAct(pos, m, seq) end end,
    left = function(pos) if game then game:SeatLeft(pos) end end,
    back = function(pos) if game then game:SeatBack(pos) end end,
    view = function(blob) if game then game:SetView(blob) end end,
})
T.OnChange(function()
    local g = game
    if not g then return end
    local room = T.Room()
    local nowGuest = T.Role() == "guest" and room and room.game == ID or false
    if g.phase == "menu" and nowGuest ~= g.guest then
        g:Restart()
        return
    end
    if g.phase == "menu" then
        if g.guest and room and room.opts then
            g.board = boardOf(room.opts)
            g.cfg = R.Cfg(room.opts)
        end
        g:Draw()
    end
end)
local SLIDES = {
    { head = "tycoon.slGoalHead", lines = { "tycoon.slGoal1", "tycoon.slGoal2" } },
    { head = "tycoon.slDiceHead", target = "tycoon.roll", lines = { "tycoon.slDice1", "tycoon.slDice2" } },
    { head = "tycoon.slBuyHead", target = "tycoon.prompt", lines = { "tycoon.slBuy1", "tycoon.slBuy2" } },
    { head = "tycoon.slRentHead", target = "tycoon.board", lines = { "tycoon.slRent1", "tycoon.slRent2" } },
    { head = "tycoon.slBuildHead", target = "tycoon.card", lines = { "tycoon.slBuild1", "tycoon.slBuild2" } },
    { head = "tycoon.slJailHead", lines = { "tycoon.slJail1", "tycoon.slJail2" } },
    { head = "tycoon.slTradeHead", target = "tycoon.trade", lines = { "tycoon.slTrade1", "tycoon.slTrade2" } },
}
ns.RegisterGame{
    id = ID,
    label = "tycoon.label",
    icon = 6948,
    tip = "tycoon.tip",
    order = 11,
    duo = "none",
    look = V.LOOKS.azeroth,
    physics = false,
    ownPanel = true,
    record = false,
    finale = true,
    canvas = { w = 1320, h = 720 },
    live = true,
    stages = { max = 7 },
    slides = SLIDES,
    help = { "tycoon.help1", "tycoon.help2", "tycoon.help3" },
    New = New,
}
