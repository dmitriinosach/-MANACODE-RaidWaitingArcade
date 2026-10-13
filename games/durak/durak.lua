local ADDON, ns = ...
local ID = "durak"
local DECK = "deck"
local R = ns.Durak
local T = ns.Table
local WOOD = { 0.230, 0.190, 0.130 }
local EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = WOOD, edge = EDGE }
local floor, min, max = math.floor, math.min, math.max
local CW, CH = 640, 480
local BOT_PAUSE = 0.8
local END_FLASH = 0.8
local TURN = 30
local MISS_AWAY = 2
local L = {
    backW = 34, backH = 48, backStep = 10,
    pairW = 48, pairH = 68, pairStep = 66, pairY = 150, beatDX = 14, beatDY = 16,
    drop = { x1 = 116, y1 = 122, x2 = 556, y2 = 268 },
    handW = 56, handH = 80, handX = 120, handSpan = 400, handY = 372, dragMin = 4, lift = 12,
    deckX = 14, deckY = 190, deckW = 50, deckH = 70, trumpX = 58, trumpY = 200,
    btnX = 265, btnY = 300, btnW = 110, btnH = 26,
    av = 40,
    clockX = 600, clockY = 404, statusY = 282,
}
local POS = {
    left  = { x = 26,  y = 26,  fx = 80,  fy = 22 },
    top   = { x = 280, y = 26,  fx = 334, fy = 22 },
    right = { x = 574, y = 26,  fx = 570, fy = 116, vert = true },
    me    = { x = 20,  y = 380 },
}
local POS_ORDER = { "left", "top", "right" }
local REL = { [2] = { "top" }, [3] = { "left", "right" }, [4] = { "left", "top", "right" } }
local BOT_CLASS = { "WARRIOR", "PALADIN", "PRIEST" }
local CLASS_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local M = {
    variant = { { x = 16, y = 182 }, { x = 120, y = 182 } },
    seat = { left = { x = 24, y = 266 }, top = { x = 245, y = 196 }, right = { x = 466, y = 266 }, me = { x = 245, y = 330 } },
    center = { x = 320, y = 298 },
    seatW = 150, seatH = 64,
    find = { x = 210, y = 414, w = 220, h = 40 },
    rowY = 214, rowH = 38, rowGap = 6, rows = 4,
}
local C = {
    text = { 0.91, 0.90, 0.86 }, soft = { 0.65, 0.61, 0.53 }, cap = { 0.54, 0.51, 0.45 },
    gold = { 1, 0.82, 0 }, fool = { 0.95, 0.35, 0.30 }, seam = { 0.52, 0.42, 0.26, 0.45 },
}
local root, hudF, menuF, dragCard
local cardPool, seatUI
local hud = {}
local menuUI
local backIcon
local suitIcon = {}
local game
local function at(f, x, y, parent)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", parent or root, "TOPLEFT", x, -y)
end
local function paint(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local function kitRank(c)
    local r = R.Rank(c)
    return (r == 14) and 1 or r
end
local function seatsOf(opts)
    local s = type(opts) == "table" and opts.seats
    if type(s) ~= "string" or not s:match("^[box][box][box]$") then
        local m = type(opts) == "table" and opts.mask
        if type(m) == "string" and m:match("^[01][01][01]$") then
            s = m:gsub("1", "b"):gsub("0", "x")
        else
            s = "bbb"
        end
    end
    if not s:find("[bo]") then s = "xbx" end
    return s
end
local function variantOf(opts)
    return (type(opts) == "table" and opts.variant == "transfer") and "transfer" or "throw"
end
local function setClass(tex, cls)
    local tc = cls and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
    if tc then
        tex:SetTexture(CLASS_TEX)
        tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        tex:Show()
    else
        tex:Hide()
    end
end
local function paintFace(f, c, w, h, hot)
    f:SetWidth(w)
    f:SetHeight(h)
    local p = ns.DECK_PAPER
    ns.DeckCardPaper(f, p[1], p[2], p[3])
    ns.DeckCardCover(f, false)
    local s = R.Suit(c)
    ns.DeckCardFace(f, kitRank(c), s, { icon = suitIcon[s] })
    if hot then ns.DeckCardEdge(f, ns.Attn()) else ns.DeckCardEdge(f, nil) end
end
local function paintBack(f, w, h)
    f:SetWidth(w)
    f:SetHeight(h)
    ns.DeckCardPaper(f)
    ns.DeckCardRank(f.rank, nil)
    ns.DeckCardRank(f.corner, nil)
    ns.DeckCardRank(f.corner2, nil)
    ns.DeckCardSuit(f.mark, nil, nil)
    ns.DeckCardSuit(f.mark2, nil, nil)
    ns.DeckCardArt(f, nil)
    ns.DeckCardEdge(f, nil)
    ns.DeckCardCover(f, true, backIcon, nil)
end
local level
local function useCard(x, y)
    local f = cardPool:Acquire()
    level = level + 2
    f:SetFrameLevel(level)
    at(f, x, y, root)
    return f
end
local function inside(r, x, y)
    return x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2
end
local function unbeaten(v)
    for i = 1, #v.table do if not v.table[i].b then return true end end
    return false
end
local function canTake(v)
    return not v.over and v.defender == v.me and not v.taking and unbeaten(v)
end
local function canPass(v)
    if v.over or v.defender == v.me or v.passed[v.me] or v.gone[v.me] or #v.table == 0 then return false end
    return v.taking or not unbeaten(v)
end
local function awaited(v)
    if v.over then return false end
    if #v.table == 0 then return v.attacker == v.me end
    if v.defender == v.me then return unbeaten(v) and not v.taking end
    return canPass(v)
end
local function buildSeat(pos)
    local u = {}
    u.av = hudF:CreateTexture(nil, "ARTWORK")
    u.av:SetWidth(L.av)
    u.av:SetHeight(L.av)
    u.rim = ns.Fill(hudF, "BORDER", 0.69, 0.54, 0.24, 1)
    u.rim:SetWidth(L.av + 4)
    u.rim:SetHeight(L.av + 4)
    u.name = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.role = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.count = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    u.bub = ns.PlainFrame(hudF, 2)
    u.bub:SetWidth(58)
    u.bub:SetHeight(18)
    local bg = ns.Fill(u.bub, "BACKGROUND", 0.18, 0.14, 0.20, 0.95)
    bg:SetAllPoints(u.bub)
    u.bubText = u.bub:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    u.bubText:SetPoint("CENTER", u.bub, "CENTER", 0, 0)
    u.bub:Hide()
    local p = POS[pos]
    at(u.rim, p.x - 2, p.y - 2, hudF)
    at(u.av, p.x, p.y, hudF)
    u.name:SetPoint("TOP", hudF, "TOPLEFT", p.x + L.av / 2, -(p.y + L.av + 4))
    u.role:SetPoint("TOP", hudF, "TOPLEFT", p.x + L.av / 2, -(p.y + L.av + 18))
    at(u.bub, p.x + L.av / 2 - 29, p.y + L.av + 16, hudF)
    return u
end
local function slotText(slot, style, x, y)
    local fs = slot:CreateFontString(nil, "OVERLAY", style)
    if x then fs:SetPoint("TOPLEFT", slot, "TOPLEFT", x, -y) end
    return fs
end
local function buildRows()
    local rows = {}
    for i = 1, M.rows do
        local r = ns.MakeSlot(menuF, LOOK)
        r:SetWidth(CW - 32)
        r:SetHeight(M.rowH)
        at(r, 16, M.rowY + (i - 1) * (M.rowH + M.rowGap), menuF)
        r.name = slotText(r, "GameFontNormal", 14, 12)
        r.what = slotText(r, "GameFontNormalSmall", 200, 14)
        r.seats = slotText(r, "GameFontNormalSmall", 330, 14)
        r.sit = ns.MakeKitButton(r)
        r.sit:SetWidth(86)
        r.sit:SetHeight(24)
        r.sit:SetPoint("RIGHT", r, "RIGHT", -8, 0)
        r.sit.onClick = function(self)
            local g = game
            if g and self.room then g:Sit(self.room) end
        end
        r:Hide()
        rows[i] = r
    end
    return rows
end
local function buildMenu()
    menuF = ns.PlainFrame(root, 110)
    menuF:SetAllPoints()
    menuF:EnableMouse(true)
    menuUI = { bg = ns.MakeTable(menuF, LOOK) }
    menuUI.bg:Show()
    menuUI.hub = ns.MakeCardHub(menuF, LOOK)
    for _, y in ipairs({ ns.CardHub.Bottom() + 12, 400 }) do
        local t = ns.Fill(menuF, "ARTWORK", C.seam)
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", menuF, "TOPLEFT", 16, -y)
        t:SetPoint("TOPRIGHT", menuF, "TOPRIGHT", -16, -y)
    end
    menuUI.variant = {}
    for i, key in ipairs({ "throw", "transfer" }) do
        local b = ns.MakeSlot(menuF, LOOK)
        b:SetWidth(104)
        b:SetHeight(24)
        at(b, M.variant[i].x, M.variant[i].y, menuF)
        b.text = slotText(b, "GameFontNormal")
        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.key = key
        b:SetScript("OnClick", function(self)
            if game then ns.Sfx.Ui(); game:PickVariant(self.key) end
        end)
        menuUI.variant[i] = b
    end
    menuUI.note = menuF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    menuUI.note:SetPoint("TOPRIGHT", menuF, "TOPLEFT", CW - 16, -188)
    menuUI.center = menuF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menuUI.center:SetPoint("CENTER", menuF, "TOPLEFT", M.center.x, -M.center.y)
    menuUI.start = ns.MakeKitButton(menuF)
    menuUI.start:SetWidth(120)
    menuUI.start:SetHeight(30)
    menuUI.start:SetPoint("CENTER", menuF, "TOPLEFT", M.center.x, -M.center.y)
    menuUI.start.onClick = function() if game then game:BeginRound() end end
    menuUI.seat = {}
    for pos, p in pairs(M.seat) do
        local b = ns.MakeSlot(menuF, LOOK)
        b:SetWidth(M.seatW)
        b:SetHeight(M.seatH)
        at(b, p.x, p.y, menuF)
        b:SetScript("OnClick", nil)
        b.av = b:CreateTexture(nil, "ARTWORK")
        b.av:SetWidth(32)
        b.av:SetHeight(32)
        b.av:SetPoint("TOPLEFT", b, "TOPLEFT", 8, -8)
        b.name = slotText(b, "GameFontNormal", 48, 9)
        b.sub = slotText(b, "GameFontNormalSmall", 48, 27)
        b.pos = pos
        b.opt = {}
        if pos ~= "me" then
            for k, key in ipairs({ "bot", "open", "off" }) do
                local o = ns.MakeKitButton(b)
                o:SetWidth(46)
                o:SetHeight(18)
                o:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 5 + (k - 1) * 48, 5)
                o.key = key
                o.onClick = function(self)
                    if game then game:PickSeat(b.pos, self.key) end
                end
                b.opt[k] = o
            end
            b.act = ns.MakeKitButton(b)
            b.act:SetWidth(94)
            b.act:SetHeight(17)
            b.act:SetPoint("TOPLEFT", b, "TOPLEFT", 48, -24)
            b.act.onClick = function(self)
                if game and self.key then game:PickSeat(b.pos, self.key) end
            end
        end
        menuUI.seat[pos] = b
    end
    menuUI.find = ns.MakeKitButton(menuF)
    menuUI.find:SetWidth(M.find.w)
    menuUI.find:SetHeight(M.find.h)
    at(menuUI.find, M.find.x, M.find.y, menuF)
    menuUI.find.onClick = function() if game then game:FindButton() end end
    menuUI.empty = menuF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menuUI.empty:SetPoint("TOP", menuF, "TOPLEFT", CW / 2, -(M.rowY + 60))
    menuUI.rows = buildRows()
    menuF:Hide()
end
local function ensureView(canvas)
    if root then return end
    root = ns.NewFrame("Frame", nil, canvas)
    root:SetAllPoints()
    root:SetFrameLevel(canvas:GetFrameLevel() + 1)
    root:Hide()
    local bg = ns.MakeTable(root, LOOK)
    bg:Show()
    cardPool = ns.NewPool(function()
        local f = ns.MakeDeckCard(root)
        ns.DeckCardPaper(f)
        return f
    end, function(f)
        ns.DeckCardCover(f, false)
        ns.DeckCardEdge(f, nil)
    end)
    hudF = ns.PlainFrame(root, 100)
    hudF:SetAllPoints()
    seatUI = {}
    for pos in pairs(POS) do seatUI[pos] = buildSeat(pos) end
    hud.deck = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hud.deck:SetPoint("TOP", hudF, "TOPLEFT", L.deckX + L.deckW / 2, -(L.deckY + L.deckH + 26))
    hud.trump = hudF:CreateTexture(nil, "ARTWORK")
    hud.trump:SetWidth(20)
    hud.trump:SetHeight(20)
    at(hud.trump, L.deckX + 15, L.deckY + 25, hudF)
    hud.variant = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hud.variant:SetPoint("TOPRIGHT", hudF, "TOPLEFT", CW - 16, -(L.btnY + 6))
    hud.clock = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    hud.clock:SetPoint("CENTER", hudF, "TOPLEFT", L.clockX, -L.clockY)
    hud.status = hudF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hud.status:SetPoint("CENTER", hudF, "TOPLEFT", CW / 2, -L.statusY)
    hud.zone = {}
    local d = L.drop
    for i, r in ipairs({ { d.x1, d.y1, d.x2 - d.x1, 1 }, { d.x1, d.y2, d.x2 - d.x1, 1 },
                         { d.x1, d.y1, 1, d.y2 - d.y1 }, { d.x2, d.y1, 1, d.y2 - d.y1 + 1 } }) do
        local t = ns.Fill(hudF, "ARTWORK", 1, 0.82, 0, 0.55)
        at(t, r[1], r[2], hudF)
        t:SetWidth(r[3])
        t:SetHeight(r[4])
        t:Hide()
        hud.zone[i] = t
    end
    local dragF = ns.PlainFrame(root, 130)
    dragF:SetAllPoints()
    dragCard = ns.MakeDeckCard(dragF)
    ns.DeckCardPaper(dragCard)
    dragCard:Hide()
    hud.take = ns.MakeKitButton(hudF)
    hud.pass = ns.MakeKitButton(hudF)
    for _, b in ipairs({ hud.take, hud.pass }) do
        b:SetWidth(L.btnW)
        b:SetHeight(L.btnH)
        at(b, L.btnX, L.btnY, hudF)
    end
    hud.take.onClick = function() if game then game:Act{ k = "take" } end end
    hud.pass.onClick = function() if game then game:Act{ k = "pass" } end end
    buildMenu()
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:PosList()
    local kinds = self.guest and T.Room() and T.Room().kinds or nil
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
function Game:Start(seed, moves)
    ensureView(self.canvas)
    game = self
    local pick = ns.RNG.New(seed)
    backIcon = ns.Shelves.Pick(DECK, "back", pick)
    for s = 1, 4 do suitIcon[s] = ns.Shelves.Pick(DECK, "s" .. s, pick) end
    local room = T.Room()
    self.guest = T.Role() == "guest" and room and room.game == ID or false
    self.seats = seatsOf(self.opts)
    self.variant = self.guest and variantOf(room.opts) or variantOf(self.opts)
    self.opts = { seats = self.seats, variant = self.variant }
    self.S = R.Deal(seed, #self:PosList() + 1, self.variant)
    local restored = not self.guest and moves and #moves > 0
    if restored then
        for i = 1, #moves do
            if R.Legal(self.S, moves[i]) then R.Apply(self.S, moves[i]) end
        end
    end
    self.t, self.lastT, self.overT = 0, 0, 0
    self.press, self.view, self.pending = nil, nil, nil
    self.away, self.miss = {}, {}
    self.browse = false
    self.phase = restored and "play" or "menu"
    self.myTurn = false
    if not self.guest then
        local kinds = {}
        for i = 1, 3 do kinds[i] = self.seats:sub(i, i) end
        T.Host(ID, { variant = self.variant }, kinds)
    end
    root:Show()
    self:Draw()
    return true
end
function Game:Restart(seats, variant)
    ns.Store.Clear(ID)
    ns.window:StartGame(ID, { seats = seats or self.seats, variant = variant or self.variant })
end
function Game:PickVariant(key)
    if self.phase ~= "menu" or self.guest or key == self.variant then return end
    self:Restart(nil, key)
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
            title = ns.T("durak.callTitle"), autoHide = true,
            onCall = function(who)
                T.Invite(who)
                ns.CallPanel.Hide()
                return true
            end,
        })
    end
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
    if self.phase ~= "menu" then return end
    self.phase = "play"
    self.lastT = self.t
    T.Begin()
    ns.Sfx.Play("start")
    self:Push()
    self:Draw()
end
function Game:LeftFor(q)
    if not self:Live() then return nil end
    local w = R.Waiting(self.S)
    for i = 1, #w do
        if w[i] == q then return max(0, TURN - (self.t - self.lastT)) end
    end
    return nil
end
function Game:Push(only)
    if T.Role() ~= "host" or not T.Room() or not T.Room().playing then return end
    for q = 2, self.S.n do
        local p = self:PosOf(q)
        if p and T.Kind(p) == "p" and (not only or only == q) then
            T.SendView(p, self.S.seq, R.Pack(R.View(self.S, q), self:LeftFor(q)))
        end
    end
end
function Game:Sound(old, v)
    if not old or v.seq <= old.seq then return end
    local function cards(x)
        local n = 0
        for i = 1, #x.table do n = n + (x.table[i].b and 2 or 1) end
        return n
    end
    if cards(v) > cards(old) then
        ns.Sfx.Play("pop")
    elseif #v.table == 0 and #old.table > 0 and old.taking then
        ns.Sfx.Play("big")
    elseif #v.table == 0 and #old.table > 0 then
        ns.Sfx.Play("clear")
    end
    if v.over and not old.over then ns.Sfx.Play("over") end
    local mine = awaited(v)
    if mine and not self.myTurn then ns.Sfx.Play("turn") end
    self.myTurn = mine
end
function Game:Move(m)
    if self.phase ~= "play" or self.guest or not R.Legal(self.S, m) then return false end
    local old = R.View(self.S, 1)
    R.Apply(self.S, m)
    self.lastT = self.t
    self:Sound(old, R.View(self.S, 1))
    self:Push()
    if self.S.over then T.End() end
    self:Draw()
    return true
end
function Game:Act(m)
    if self.phase ~= "play" then return end
    if self.guest then
        if not self.view then return end
        self.pending = self.view.seq
        T.Act(m, self.view.seq)
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
    self.away[q], self.miss[q] = nil, 0
    if seq ~= self.S.seq or not self:Move(m) then self:Push(q) end
end
function Game:SeatLeft(pos)
    local q = self:SeatOf(pos)
    if q then self.away[q] = true end
    self:Draw()
end
function Game:SetView(blob)
    if not self.guest then return end
    local v = R.Unpack(blob)
    if not v then return end
    if self.pending and v.seq == self.pending then ns.Sfx.Play("deny") end
    self.pending = nil
    self:Sound(self.view, v)
    self.view = v
    self.leftUntil = v.left and (self.t + v.left) or nil
    if self.phase ~= "play" then
        self.phase = "play"
        ns.Sfx.Play("start")
    end
    self:Draw()
end
function Game:Bots()
    local S = self.S
    for k = 0, S.n - 1 do
        local q = (S.attacker + k - 1) % S.n + 1
        if q ~= 1 and (not self:Human(q) or self.away[q]) then
            local m = R.Bot(S, q)
            if m then return m end
        end
    end
    return nil
end
function Game:Timeouts()
    if not self:Live() or self.t - self.lastT < TURN then return false end
    local w = R.Waiting(self.S)
    for i = 1, #w do
        local q = w[i]
        if self:Human(q) and not self.away[q] then
            local m = R.Default(self.S, q)
            if m and self:Move(m) then
                if q ~= 1 then
                    self.miss[q] = (self.miss[q] or 0) + 1
                    if self.miss[q] >= MISS_AWAY then self.away[q] = true end
                end
                return true
            end
        end
    end
    return false
end
function Game:Update(dt)
    if self.phase ~= "play" then return end
    self.t = self.t + dt
    self:DragTick()
    self:Clock()
    if self.guest then
        if self.view and self.view.over then self.overT = self.overT + dt end
        return
    end
    if self.S.over then
        self.overT = self.overT + dt
        return
    end
    if self:Timeouts() then return end
    if self.t - self.lastT < BOT_PAUSE then return end
    local m = self:Bots()
    if m then self:Move(m) end
end
function Game:Clock()
    local v = self:View()
    local left
    if v and awaited(v) then
        if self.guest then
            left = self.leftUntil and (self.leftUntil - self.t)
        elseif self:Live() then
            left = TURN - (self.t - self.lastT)
        end
    end
    if left then
        hud.clock:SetText(tostring(max(0, floor(left + 0.5))))
        paint(hud.clock, left <= 10 and C.fool or C.gold)
        hud.clock:Show()
    else
        hud.clock:Hide()
    end
end
function Game:Score() return 0 end
function Game:View()
    if self.guest then return self.view end
    return self.S and R.View(self.S, 1)
end
function Game:IsOver()
    local v = self:View()
    return v ~= nil and v.over and self.overT >= END_FLASH
end
function Game:ResultText()
    local v = self:View()
    if not v or not v.over then return nil end
    if v.fool == v.me then return ns.T("durak.resFool") end
    if not v.fool then return ns.T("durak.resDraw") end
    for i = 1, #v.out do
        if v.out[i] == v.me then return ns.T("durak.res" .. min(i, 3)) end
    end
    return nil
end
function Game:Stop()
    if root then root:Hide() end
    if menuF then menuF:Hide() end
    if cardPool then cardPool:HideAll() end
    if dragCard then dragCard:Hide() end
    self.press = nil
    T.Release()
    if game == self then game = nil end
end
local function cursorTop()
    if not root or not root:GetLeft() then return nil end
    local s = root:GetEffectiveScale()
    if not s or s == 0 then return nil end
    local x, y = GetCursorPosition()
    return x / s - root:GetLeft(), CH - (y / s - root:GetBottom())
end
function Game:DropMove(c, x, y, v)
    if v.defender == v.me then
        local pr = self.pairRects or {}
        for i = #pr, 1, -1 do
            if inside(pr[i], x, y) then return { k = "beat", c = c, i = pr[i].i } end
        end
        return { k = "tr", c = c }
    end
    if v.attacker == v.me and #v.table == 0 then return { k = "att", c = c } end
    return { k = "add", c = c }
end
function Game:Aim(x, y)
    local v = self:View()
    if not v or not inside(L.drop, x, y) then return nil end
    if v.defender == v.me then
        local pr = self.pairRects or {}
        for i = #pr, 1, -1 do
            if inside(pr[i], x, y) then return i end
        end
    end
    return 0
end
function Game:Drop(x, y)
    local p = self.press
    self.press = nil
    self.aim = nil
    if not p then return end
    local v = self:View()
    if p.drag and x and v and inside(L.drop, x, y) then
        self:Act(self:DropMove(p.c, x, y, v))
    end
    self:Draw()
end
function Game:DragTick()
    local p = self.press
    if not p then return end
    local x, y = cursorTop()
    if not x then return end
    if not p.drag and (math.abs(x - p.x) >= L.dragMin or math.abs(y - p.y) >= L.dragMin) then
        p.drag = true
        self:Draw()
    end
    if p.drag then
        at(dragCard, x - p.ox, y - p.oy, root)
        local aim = self:Aim(x, y)
        if aim ~= self.aim then
            self.aim = aim
            self:Draw()
        end
    end
    if not IsMouseButtonDown("LeftButton") then self:Drop(x, y) end
end
function Game:Click(x, y, button)
    if button and button ~= "LeftButton" then return end
    local v = self:View()
    if self.phase ~= "play" or not v or v.over then return end
    local yt = CH - y
    local hand = self.handRects or {}
    for i = #hand, 1, -1 do
        local r = hand[i]
        if inside(r, x, yt) then
            self.press = { c = r.c, x = x, y = yt, ox = x - r.x1, oy = yt - r.y1 + L.lift }
            ns.Sfx.Play("pick")
            self:Draw()
            return
        end
    end
end
function Game:Release(x, y, button)
    if button and button ~= "LeftButton" then return end
    if not self.press then return end
    local cx, cy = cursorTop()
    self:Drop(cx or x, cy or (CH - y))
end
function Game:SeatName(q, v)
    if q == v.me then return UnitName("player") or "" end
    local room = T.Room()
    if q == 1 then return room and room.host or "" end
    local p = self:PosOf(q)
    local name = p and T.Name(p)
    if name and not self.away[q] then return name end
    return ns.T("durak.bot")
end
function Game:SeatClass(q, v)
    if q == v.me then
        local _, cls = UnitClass("player")
        return cls
    end
    local room = T.Room()
    if q == 1 then return room and ns.Link.PeerClass(room.host) end
    local p = self:PosOf(q)
    local name = p and T.Name(p)
    if name then return T.Class(p) or ns.Link.PeerClass(name) end
    return BOT_CLASS[p or 1]
end
local function waitingOf(v)
    local out = {}
    if v.over then return out end
    if #v.table == 0 then
        out[v.attacker] = true
    elseif unbeaten(v) and not v.taking then
        out[v.defender] = true
    else
        for q = 1, v.n do
            if q ~= v.defender and not v.passed[q] and not v.gone[q] then out[q] = true end
        end
    end
    return out
end
function Game:DrawSeat(pos, q, v)
    local u = seatUI[pos]
    setClass(u.av, self:SeatClass(q, v))
    if waitingOf(v)[q] then
        ns.Paint(u.rim, 1, 0.82, 0, 1)
    else
        ns.Paint(u.rim, 0.30, 0.24, 0.14, 1)
    end
    u.rim:Show()
    u.name:SetText(self:SeatName(q, v))
    u.name:Show()
    paint(u.name, (q == v.attacker and not v.over) and C.gold or C.text)
    local role, rc = "", C.soft
    if v.over and v.fool == q then
        role, rc = ns.T("durak.fool"), C.fool
    elseif v.gone[q] then
        role = ns.T("durak.out")
    elseif not v.over and q == v.attacker then
        role = ns.T("durak.roleAtt")
    elseif not v.over and q == v.defender then
        role = ns.T("durak.roleDef")
    end
    u.role:SetText(role)
    paint(u.role, rc)
    u.role:Show()
    local bub
    if not v.over then
        if q == v.defender and v.taking then bub = ns.T("durak.take")
        elseif v.passed[q] then bub = ns.T("durak.pass") end
    end
    if bub and pos ~= "me" then
        u.bubText:SetText(bub)
        u.bub:Show()
        u.role:Hide()
    else
        u.bub:Hide()
    end
    if pos == "me" then return end
    local p = POS[pos]
    local k = v.counts[q] or 0
    local step = (k > 12) and floor(L.backStep * 11 / (k - 1)) or L.backStep
    local reach = 0
    for i = 1, k do
        if p.vert then
            paintBack(useCard(p.fx, p.fy + (i - 1) * step), L.backH, L.backW)
        else
            paintBack(useCard(p.fx + (i - 1) * step, p.fy), L.backW, L.backH)
        end
        reach = (i - 1) * step
    end
    u.count:ClearAllPoints()
    if p.vert then
        u.count:SetPoint("TOP", hudF, "TOPLEFT", p.fx + L.backH / 2, -(p.fy + reach + L.backW + 4))
    else
        u.count:SetPoint("LEFT", hudF, "TOPLEFT", p.fx + reach + L.backW + 6, -(p.fy + L.backH / 2))
    end
    u.count:SetText(k > 0 and tostring(k) or "")
    paint(u.count, C.soft)
    u.count:Show()
end
function Game:DrawBrowse()
    local list = T.Rooms(ID)
    local joining = T.Joining()
    for i, r in ipairs(menuUI.rows) do
        local it = list[i]
        if it then
            r.name:SetText(ns.T("durak.roomOf", it.host))
            r.what:SetText(ns.T("durak." .. variantOf(it.opts)))
            paint(r.what, C.soft)
            local busy, all = 1, 1
            for j = 1, #it.kinds do
                local k = it.kinds:sub(j, j)
                if k ~= "x" then all = all + 1 end
                if k == "b" or k == "p" then busy = busy + 1 end
            end
            r.seats:SetText(ns.T("durak.roomSeats", busy, all))
            paint(r.seats, C.soft)
            r.sit.room = it
            r.sit:SetText(ns.T("durak.sit"))
            if joining then r.sit:Disable() else r.sit:Enable() end
            r:Show()
        else
            r:Hide()
        end
    end
    menuUI.empty:SetText(#list == 0 and ns.T("durak.noRooms") or "")
    paint(menuUI.empty, C.soft)
end
function Game:DrawSeatSlot(pos, b, kind, name, cls, sub)
    local mine = pos == "me" or (self.guest and T.Room() and POS_ORDER[T.Room().pos] == pos)
    b:Tone(mine)
    b.av:Hide()
    b.name:SetText("")
    b.sub:SetText("")
    if kind == "x" then
        b.name:SetText(ns.T("durak.noSeat"))
        paint(b.name, C.cap)
    elseif kind == "o" then
        b.name:SetText(ns.T("durak.open"))
        paint(b.name, C.gold)
        b.sub:SetText(ns.T("durak.openWait"))
        paint(b.sub, C.soft)
    else
        setClass(b.av, cls)
        b.name:SetText(name or "")
        paint(b.name, C.text)
        b.sub:SetText(sub or "")
        paint(b.sub, C.soft)
    end
    if pos == "me" then return end
    local host = not self.guest
    local cur = (kind == "p") and "o" or kind
    for _, o in ipairs(b.opt) do
        local code = (o.key == "bot") and "b" or (o.key == "off") and "x" or "o"
        o:SetText(ns.T("durak.opt_" .. o.key))
        o.tipTitle = ns.T("durak.opt_" .. o.key)
        o.tip = ns.T("durak.opt_" .. o.key .. "Tip")
        if host then o:Show() else o:Hide() end
        if code == cur then o:Disable() else o:Enable() end
    end
    b.act.key = nil
    if host and kind == "o" then
        b.act.key = "call"
        b.act:SetText(ns.T("durak.call"))
        b.act.tipTitle = ns.T("durak.call")
        b.act.tip = ns.T("durak.callTip")
        b.act:Show()
        b.sub:SetText("")
    elseif host and kind == "p" then
        b.act.key = "free"
        b.act:SetText(ns.T("durak.free"))
        b.act.tipTitle = ns.T("durak.free")
        b.act.tip = ns.T("durak.freeTip")
        b.act:Show()
        b.sub:SetText("")
    else
        b.act:Hide()
    end
end
function Game:DrawMenu()
    local u = menuUI
    u.hub:Sync()
    local room = T.Room()
    if self.guest and not room then return end
    local browse = self.browse and not self.guest
    for _, b in ipairs(u.variant) do
        b.text:SetText(ns.T("durak." .. b.key))
        b.tipTitle = ns.T("durak." .. b.key)
        b.tip = ns.T("durak." .. b.key .. "Tip")
        b:Tone(b.key == self.variant)
        paint(b.text, (b.key == self.variant) and C.gold or C.soft)
        if browse then b:Hide() else b:Show() end
    end
    for _, r in ipairs(u.rows) do r:Hide() end
    u.empty:SetText("")
    if browse then
        u.center:SetText("")
        u.start:Hide()
        for _, b in pairs(u.seat) do b:Hide() end
        u.note:SetText("")
        self:DrawBrowse()
        u.find:SetText(ns.T("durak.ownTable"))
        menuF:Show()
        return
    end
    for pos, b in pairs(u.seat) do
        b:Show()
        if pos == "me" then
            if self.guest then
                self:DrawSeatSlot(pos, b, "p", room.host, ns.Link.PeerClass(room.host), ns.T("durak.host"))
            else
                local _, cls = UnitClass("player")
                self:DrawSeatSlot(pos, b, "p", UnitName("player"), cls, ns.T("durak.you"))
            end
        else
            local i
            for k = 1, 3 do if POS_ORDER[k] == pos then i = k end end
            local kind = self.guest and room.kinds[i] or T.Kind(i) or self.seats:sub(i, i)
            if kind == "b" then
                self:DrawSeatSlot(pos, b, "b", ns.T("durak.bot"), BOT_CLASS[i], "")
            elseif kind == "p" then
                local name = T.Name(i)
                local mine = self.guest and room.pos == i
                self:DrawSeatSlot(pos, b, "p", name, T.Class(i) or ns.Link.PeerClass(name),
                    mine and ns.T("durak.you") or "")
            else
                self:DrawSeatSlot(pos, b, kind)
            end
        end
    end
    local rc = room and room.ready
    if self.guest then
        u.start:Hide()
        u.center:SetText(ns.T("durak.waitHost"))
        u.find:SetText(ns.T("durak.leave"))
    else
        u.center:SetText("")
        u.start:Show()
        if rc then
            local yes, all = T.ReadyCount()
            u.start:SetText(ns.T("durak.readyCount", yes or 0, all or 0))
            u.start:Disable()
        else
            u.start:SetText(ns.T("durak.start"))
            if self:Ready() then u.start:Enable() else u.start:Disable() end
        end
        u.find:SetText(ns.T("durak.findTable"))
    end
    paint(u.center, C.soft)
    local open = false
    for i = 1, 3 do if self.seats:sub(i, i) == "o" then open = true end end
    u.note:SetText((not self.guest and open) and ns.T("durak.visible") or "")
    paint(u.note, C.soft)
    menuF:Show()
end
function Game:Draw()
    if not root then return end
    if self.phase == "menu" then
        cardPool:HideAll()
        dragCard:Hide()
        self:DrawMenu()
        return
    end
    menuF:Hide()
    local v = self:View()
    cardPool:Reset()
    level = root:GetFrameLevel() + 3
    for _, u in pairs(seatUI) do
        u.av:Hide(); u.rim:Hide(); u.name:Hide(); u.role:Hide(); u.count:Hide(); u.bub:Hide()
    end
    if not v then
        cardPool:HideExtras()
        return
    end
    local rel = REL[v.n]
    for q = 1, v.n do
        if q ~= v.me then self:DrawSeat(rel[(q - v.me) % v.n], q, v) end
    end
    self:DrawSeat("me", v.me, v)
    self:DrawTable(v)
end
function Game:DrawStatus(v)
    local text, col = "", C.soft
    if not v.over then
        local me = v.me
        if #v.table == 0 and v.attacker == me then
            text, col = ns.T("durak.stYouAttack"), C.gold
        elseif v.defender == me and unbeaten(v) and not v.taking then
            text, col = ns.T("durak.stYouDefend"), C.gold
        elseif canPass(v) then
            text, col = ns.T("durak.stYouAdd"), C.gold
        elseif #v.table == 0 then
            text = ns.T("durak.stAttack", self:SeatName(v.attacker, v))
        elseif unbeaten(v) and not v.taking then
            text = ns.T("durak.stDefend", self:SeatName(v.defender, v))
        elseif v.taking then
            text = ns.T("durak.stTakes", self:SeatName(v.defender, v))
        else
            text = ns.T("durak.stAdding")
        end
    end
    hud.status:SetText(text)
    paint(hud.status, col)
end
function Game:DrawTable(v)
    if v.deckLeft > 0 then
        if v.trumpCard then paintFace(useCard(L.trumpX, L.trumpY), v.trumpCard, L.deckW, L.deckH) end
        for i = 1, min(3, v.deckLeft - 1) do
            paintBack(useCard(L.deckX + (i - 1) * 2, L.deckY - (i - 1) * 2), L.deckW, L.deckH)
        end
        hud.deck:SetText(tostring(v.deckLeft))
        hud.trump:Hide()
    else
        hud.deck:SetText("")
        ns.DeckCardSuit(hud.trump, suitIcon[v.trump], v.trump, ns.DeckSuitInk(v.trump))
        hud.trump:Show()
    end
    paint(hud.deck, C.soft)
    self.pairRects = {}
    local k = #v.table
    local x0 = floor((CW - (k * L.pairStep - (L.pairStep - L.pairW - L.beatDX))) / 2)
    for i = 1, k do
        local p = v.table[i]
        local x = x0 + (i - 1) * L.pairStep
        local aimed = self.aim == i
        paintFace(useCard(x, L.pairY), p.a, L.pairW, L.pairH, aimed)
        if p.b then paintFace(useCard(x + L.beatDX, L.pairY + L.beatDY), p.b, L.pairW, L.pairH, aimed) end
        self.pairRects[i] = { x1 = x - 4, y1 = L.pairY - 6, x2 = x + L.pairW + L.beatDX + 4,
                              y2 = L.pairY + L.pairH + L.beatDY + 6, i = i }
    end
    local held = self.press and self.press.drag and self.press.c or nil
    local hand = {}
    for i = 1, #v.hand do
        if v.hand[i] ~= held then hand[#hand + 1] = v.hand[i] end
    end
    local xs = ns.DeckFan(#hand, { w = L.handW, span = L.handSpan, x = L.handX, gap = 4 })
    self.handRects = {}
    local pressed = self.press and not self.press.drag and self.press.c or nil
    for i = 1, #hand do
        local x = xs[i] or L.handX
        local up = (hand[i] == pressed) and L.lift or 0
        paintFace(useCard(x, L.handY - up), hand[i], L.handW, L.handH, up > 0)
        local nx = xs[i + 1]
        self.handRects[i] = { x1 = x, y1 = L.handY, x2 = nx and min(nx, x + L.handW) or x + L.handW,
                              y2 = L.handY + L.handH, c = hand[i] }
    end
    cardPool:HideExtras()
    if held then
        paintFace(dragCard, held, L.handW, L.handH, true)
        dragCard:Show()
    else
        dragCard:Hide()
    end
    for _, t in ipairs(hud.zone) do
        if held and self.aim == 0 then t:Show() else t:Hide() end
    end
    self:DrawStatus(v)
    hud.take:SetText(ns.T("durak.take"))
    hud.take.tip = ns.T("durak.takeTip")
    hud.pass:SetText(ns.T("durak.pass"))
    hud.pass.tip = ns.T("durak.passTip")
    if canTake(v) then hud.take:Show() else hud.take:Hide() end
    if canPass(v) then hud.pass:Show() else hud.pass:Hide() end
    hud.variant:SetText(ns.T("durak." .. v.variant))
    paint(hud.variant, C.soft)
    self:Clock()
end
T.Hooks(ID, {
    act = function(pos, m, seq) if game then game:RemoteAct(pos, m, seq) end end,
    left = function(pos) if game then game:SeatLeft(pos) end end,
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
    if g.phase == "menu" then g:Draw() end
end)
ns.CardHub.Provide(2, ID, function()
    local here = ns.CardHub.Here(ID)
    local rec = ns.Store.Load(ID)
    local live = (rec and rec.moves and #rec.moves > 0) and true or false
    return { {
        label = ns.T("durak.label"), line = ns.T("durak.tip"),
        best = live and ns.T("durak.hubLive") or ns.T("durak.hubBots"), bestGold = live,
        foot = ns.T("durak.hubFoot"),
        on = here ~= nil and here.phase == "menu",
        open = function()
            ns.window:SaveCurrent()
            ns.window:StartGame(ID, nil, ns.Store.HasSaved(ID))
        end,
    } }
end)
local function DurakTileIcon(host, size)
    local m = floor(size * 0.09 + 0.5)
    local cw, ch = floor(size * 0.50 + 0.5), floor(size * 0.66 + 0.5)
    local function fill(n, layer, x, y, w, h, c)
        local t = ns.ArtFill(host, n, layer)
        ns.Paint(t, c[1], c[2], c[3], 1)
        t:SetWidth(w); t:SetHeight(h)
        t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    end
    local function cardAt(n, layer, x, y, paper)
        local e = ns.DECK_EDGE
        fill(n, layer, x, y, cw, ch, paper)
        fill(n + 1, layer, x, y, cw, 1, e)
        fill(n + 2, layer, x, y + ch - 1, cw, 1, e)
        fill(n + 3, layer, x, y, 1, ch, e)
        fill(n + 4, layer, x + cw - 1, y, 1, ch, e)
    end
    fill(1, "BACKGROUND", 0, 0, size, size, WOOD)
    cardAt(2, "BORDER", m, m, ns.DECK_PAPER)
    cardAt(7, "ARTWORK", size - m - cw, size - m - ch, ns.DECK_PAPER)
    local a = ns.ArtText(host, 1)
    ns.DeckCardRank(a, floor(ch * 0.55 + 0.5), ns.DeckRankLabel(6), 0.1, 0.1, 0.1, "")
    a:SetWidth(cw); a:SetHeight(ch)
    a:SetJustifyH("CENTER"); a:SetJustifyV("MIDDLE")
    a:SetPoint("TOPLEFT", host, "TOPLEFT", m, -m)
    local t = ns.ArtText(host, 2)
    local r, g, b = ns.DeckSuitInk(1)
    ns.DeckCardRank(t, floor(ch * 0.55 + 0.5), ns.DeckRankLabel(1), r, g, b, "")
    t:SetWidth(cw); t:SetHeight(ch)
    t:SetJustifyH("CENTER"); t:SetJustifyV("MIDDLE")
    t:SetPoint("TOPLEFT", host, "TOPLEFT", size - m - cw, -(size - m - ch))
end
ns.RegisterGame{
    id = ID,
    label = "durak.label",
    icon = { draw = DurakTileIcon },
    tip = "durak.tip",
    order = 10,
    hub = "solitaire",
    duo = "none",
    look = LOOK,
    physics = false,
    ownPanel = true,
    deck = true,
    record = false,
    finale = true,
    controls = {
        { action = "play", label = "durak.ctlPlay", mouse = "DRAG", where = "durak.ctlOnTable" },
        { action = "beat", label = "durak.ctlBeat", mouse = "DRAG", where = "durak.ctlOnPair" },
    },
    help = { "durak.help1", "durak.helpDrag", "durak.help2", "durak.help3", "durak.help4", "durak.help5" },
    New = New,
}
