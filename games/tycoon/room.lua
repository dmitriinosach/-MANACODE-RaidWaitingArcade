local ADDON, ns = ...
local B = ns.TycoonBoards
local T = ns.Table
local V = ns.TycoonView
local CW, CH = 1320, 720
local RCOL = CW - 240
local C = V.C
local LOOKS = V.LOOKS
local M = {
    table = { x = 370, y = 130, w = 580, h = 480 },
    seatW = 176, seatH = 76,
    seat = { top = { x = 205, y = -40 }, left = { x = -24, y = 202 }, right = { x = 428, y = 202 }, me = { x = 205, y = 444 } },
    tokX = 20, tokY = 48, tok = 104, tokH = 92,
    find = { x = RCOL, y = CH - 48, w = 230, h = 32 },
    rowY = 120, rowH = 40, rowGap = 6, rows = 8,
}
local POS_ORDER = { "left", "top", "right" }
local BOT_CLASS = { "WARRIOR", "PALADIN", "PRIEST" }
local CLASS_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local MENU = { { key = "bot", lab = "tycoon.menuBot" }, { key = "open", lab = "tycoon.menuOpen" },
               { key = "call", lab = "tycoon.menuCall" }, { key = "free", lab = "tycoon.menuFree" },
               { key = "off", lab = "tycoon.menuOff" } }
local menuF, ui, pop
local function at(f, x, y, parent)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", parent or menuF, "TOPLEFT", x, -y)
end
local paint, text, button = V.paint, V.text, V.button
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
local function buildRows()
    local rows = {}
    for i = 1, M.rows do
        local r = ns.MakeSlot(menuF, LOOKS.azeroth)
        r:SetWidth(CW - 48)
        r:SetHeight(M.rowH)
        at(r, 24, M.rowY + (i - 1) * (M.rowH + M.rowGap))
        r.name = text(r, "GameFontNormal", 14, 12, 280, nil, 13)
        r.what = text(r, "GameFontNormalSmall", 320, 14, 220, nil, 12)
        r.seats = text(r, "GameFontNormalSmall", 560, 14, 220, nil, 12)
        r.sit = ns.MakeKitButton(r)
        r.sit:SetWidth(100)
        r.sit:SetHeight(26)
        r.sit:SetPoint("RIGHT", r, "RIGHT", -10, 0)
        r.sit.onClick = function(self)
            local g = V.game
            if g and self.room then g:Sit(self.room) end
        end
        r:Hide()
        rows[i] = r
    end
    return rows
end
local function buildPop()
    pop = ns.PlainFrame(menuF, 20)
    pop:SetWidth(190)
    pop:SetHeight(#MENU * 24 + 8)
    pop.bg = ns.Fill(pop, "BACKGROUND", 0, 0, 0, 0.95)
    pop.bg:SetAllPoints(pop)
    pop.edge = V.edgeBars(pop, "BORDER", C.gold)
    pop:EnableMouse(true)
    pop.items = {}
    for i, it in ipairs(MENU) do
        local b = button(pop, 4, 4 + (i - 1) * 24, 182, 22, function(self)
            local g = V.game
            pop:Hide()
            if g and pop.pos then g:PickSeat(pop.pos, self.key) end
        end)
        b.key = it.key
        pop.items[i] = b
    end
    pop:Hide()
end
local function buildSeat(pos)
    local tb = ui.table
    local p = M.seat[pos]
    local b = V.panel(menuF, 3, M.table.x + p.x, M.table.y + p.y, M.seatW, M.seatH)
    b.ring = V.Ring(b, 44)
    at(b.ring, 8, 16, b)
    b.av = b:CreateTexture(nil, "ARTWORK")
    b.av:SetWidth(36)
    b.av:SetHeight(36)
    b.av:SetPoint("TOPLEFT", b, "TOPLEFT", 12, -20)
    b.name = text(b, "GameFontNormal", 60, 16, 84, nil, 13)
    b.tag = text(b, "GameFontHighlightSmall", nil, nil, 60, "RIGHT", 9)
    b.tag:SetPoint("TOPRIGHT", b, "TOPRIGHT", -6, -6)
    b.st = text(b, "GameFontHighlightSmall", 60, 38, 110, nil, 11)
    b.ask = text(b, "GameFontNormalLarge", nil, nil, 44, "CENTER", 22)
    b.ask:SetPoint("CENTER", b.ring, "CENTER", 0, 0)
    b.ask:Hide()
    b.plus = ns.MakeKitButton(b)
    b.plus:SetWidth(44)
    b.plus:SetHeight(44)
    b.plus:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.plus.onClick = function() local g = V.game if g then g:SeatMenu(b.pos, b) end end
    b.plus:SetText("+")
    V.size(b.plus.text, 26)
    b.plus:Hide()
    b.more = ns.MakeKitButton(b)
    b.more:SetWidth(24)
    b.more:SetHeight(20)
    b.more:SetPoint("TOPRIGHT", b, "TOPRIGHT", -4, -22)
    b.more.onClick = function() local g = V.game if g then g:SeatMenu(b.pos, b) end end
    b.more:SetText("...")
    b.more:Hide()
    b.pos = pos
    return b
end
function V.EnsureMenu(root)
    if menuF then return end
    menuF = ns.PlainFrame(root, 110)
    menuF:SetAllPoints()
    menuF:EnableMouse(true)
    menuF:SetScript("OnMouseDown", function() if pop then pop:Hide() end end)
    ui = { bg = ns.MakeTable(menuF, LOOKS.azeroth) }
    ui.bg:Show()
    ui.left = V.grad(menuF, "BORDER")
    at(ui.left, 0, 0)
    ui.left:SetWidth(250)
    ui.left:SetHeight(CH)
    ui.right = V.grad(menuF, "BORDER")
    at(ui.right, CW - 250, 0)
    ui.right:SetWidth(250)
    ui.right:SetHeight(CH)
    ui.mid = V.grad(menuF, "BORDER")
    at(ui.mid, 250, 0)
    ui.mid:SetWidth(CW - 500)
    ui.mid:SetHeight(CH)
    ui.tokCap = text(menuF, "GameFontNormal", M.tokX, 20, 210, nil, 13)
    ui.tok = {}
    for i = 1, 8 do
        local b = ns.MakeSlot(menuF, LOOKS.azeroth)
        b:SetWidth(M.tok)
        b:SetHeight(M.tokH)
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        at(b, M.tokX + col * (M.tok + 6), M.tokY + row * (M.tokH + 6))
        b.ring = V.Ring(b, 56)
        b.ring:SetPoint("TOP", b, "TOP", 0, -6)
        b.text = text(b, "GameFontHighlightSmall", nil, nil, M.tok - 8, "CENTER", 11)
        b.text:SetPoint("BOTTOM", b, "BOTTOM", 0, 6)
        b.idx = i
        b:SetScript("OnClick", function(self)
            local g = V.game
            if g then ns.Sfx.Ui(); g:PickToken(self.idx) end
        end)
        ui.tok[i] = b
    end
    ui.tokNote = text(menuF, "GameFontHighlightSmall", M.tokX, M.tokY + 4 * (M.tokH + 6) + 8, 210, nil, 11)
    ui.tokNote:SetHeight(40)
    ui.tokNote:SetJustifyV("TOP")
    local tb = V.panel(menuF, 2, M.table.x, M.table.y, M.table.w, M.table.h)
    ui.table = tb
    tb.inner = V.edgeBars(tb, "ARTWORK", C.cap)
    for k = 1, 4 do
        tb.inner[k]:ClearAllPoints()
    end
    tb.inner[1]:SetPoint("TOPLEFT", tb, "TOPLEFT", 18, -18); tb.inner[1]:SetPoint("TOPRIGHT", tb, "TOPRIGHT", -18, -18)
    tb.inner[2]:SetPoint("BOTTOMLEFT", tb, "BOTTOMLEFT", 18, 18); tb.inner[2]:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT", -18, 18)
    tb.inner[3]:SetPoint("TOPLEFT", tb, "TOPLEFT", 18, -18); tb.inner[3]:SetPoint("BOTTOMLEFT", tb, "BOTTOMLEFT", 18, 18)
    tb.inner[4]:SetPoint("TOPRIGHT", tb, "TOPRIGHT", -18, -18); tb.inner[4]:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT", -18, 18)
    tb.vig = V.edgeBars(tb, "BORDER", { 0, 0, 0, 0.28 }, 16)
    tb.frame = V.edgeBars(tb, "ARTWORK", { 0.4, 0.3, 0.15, 1 }, 6)
    tb.title = text(tb, "GameFontNormalHuge", nil, nil, M.table.w - 40, "CENTER", 30)
    tb.title:SetPoint("CENTER", tb, "CENTER", 0, 78)
    tb.sub = text(tb, "GameFontHighlightSmall", nil, nil, M.table.w - 40, "CENTER", 12)
    tb.sub:SetPoint("CENTER", tb, "CENTER", 0, 48)
    tb.orn = ns.Fill(tb, "ARTWORK", 1, 1, 1, 0.6)
    tb.orn:SetWidth(220)
    tb.orn:SetHeight(1)
    tb.orn:SetPoint("CENTER", tb, "CENTER", 0, 30)
    tb.start = ns.MakeKitButton(tb)
    tb.start:SetWidth(180)
    tb.start:SetHeight(40)
    tb.start:SetPoint("CENTER", tb, "CENTER", 0, -2)
    V.size(tb.start.text, 16)
    tb.start.onClick = function() local g = V.game if g then g:BeginRound() end end
    tb.note = text(tb, "GameFontHighlightSmall", nil, nil, M.table.w - 40, "CENTER", 12)
    tb.note:SetPoint("CENTER", tb, "CENTER", 0, -40)
    ui.seat = {}
    for pos in pairs(M.seat) do ui.seat[pos] = buildSeat(pos) end
    ui.boardCap = text(menuF, "GameFontNormal", RCOL, 20, 230, nil, 13)
    ui.board = {}
    for i, key in ipairs(B.ORDER) do
        local b = ns.MakeSlot(menuF, LOOKS[key])
        b:SetWidth(230)
        b:SetHeight(56)
        at(b, RCOL, 48 + (i - 1) * 62)
        b.sw = b:CreateTexture(nil, "ARTWORK")
        b.sw:SetWidth(40)
        b.sw:SetHeight(40)
        at(b.sw, 8, 8, b)
        local th = B.thumb[key]
        b.sw:SetTexture(th.path)
        b.sw:SetTexCoord(th.coord[1], th.coord[2], th.coord[3], th.coord[4])
        b.swEdge = V.edgeBars(b, "OVERLAY", B.palette[key].frame2)
        for k = 1, 4 do
            b.swEdge[k]:ClearAllPoints()
        end
        b.swEdge[1]:SetPoint("TOPLEFT", b.sw, "TOPLEFT", -1, 1); b.swEdge[1]:SetPoint("TOPRIGHT", b.sw, "TOPRIGHT", 1, 1)
        b.swEdge[2]:SetPoint("BOTTOMLEFT", b.sw, "BOTTOMLEFT", -1, -1); b.swEdge[2]:SetPoint("BOTTOMRIGHT", b.sw, "BOTTOMRIGHT", 1, -1)
        b.swEdge[3]:SetPoint("TOPLEFT", b.sw, "TOPLEFT", -1, 1); b.swEdge[3]:SetPoint("BOTTOMLEFT", b.sw, "BOTTOMLEFT", -1, -1)
        b.swEdge[4]:SetPoint("TOPRIGHT", b.sw, "TOPRIGHT", 1, 1); b.swEdge[4]:SetPoint("BOTTOMRIGHT", b.sw, "BOTTOMRIGHT", 1, -1)
        b.text = text(b, "GameFontNormal", 58, 10, 164, nil, 13)
        b.sub = text(b, "GameFontHighlightSmall", 58, 30, 164, nil, 10)
        b.key = key
        b:SetScript("OnClick", function(self)
            local g = V.game
            if g then ns.Sfx.Ui(); g:PickBoard(self.key) end
        end)
        ui.board[i] = b
    end
    ui.rulesCap = text(menuF, "GameFontNormal", RCOL, 250, 230, nil, 13)
    ui.rules = {}
    for k, key in ipairs({ "gold", "turn", "auc", "trade", "fin" }) do
        local r = { key = key }
        r.lab = text(menuF, "GameFontHighlightSmall", RCOL, 280 + (k - 1) * 30, 110, nil, 11)
        r.btn = ns.MakeKitButton(menuF)
        r.btn:SetWidth(key == "fin" and 230 or 112)
        r.btn:SetHeight(24)
        if key == "fin" then
            at(r.btn, RCOL, 274 + (k - 1) * 30 + 20)
        else
            at(r.btn, RCOL + 118, 274 + (k - 1) * 30)
        end
        r.btn.onClick = function() local g = V.game if g then g:PickRule(key) end end
        ui.rules[k] = r
    end
    ui.find = ns.MakeKitButton(menuF)
    ui.find:SetWidth(M.find.w)
    ui.find:SetHeight(M.find.h)
    at(ui.find, M.find.x, M.find.y)
    ui.find.onClick = function() local g = V.game if g then g:FindButton() end end
    ui.empty = text(menuF, "GameFontNormal", nil, nil, CW, "CENTER", 13)
    ui.empty:SetPoint("TOP", menuF, "TOP", 0, -(M.rowY + 60))
    ui.rows = buildRows()
    buildPop()
    pop:SetPoint("TOPLEFT", menuF, "TOPLEFT", 0, 0)
    menuF:Hide()
end
function V.HideMenu()
    if menuF then menuF:Hide() end
    if pop then pop:Hide() end
end
function V.SeatMenu(pos, anchor, kind)
    if not pop then return end
    pop.pos = pos
    for i, it in ipairs(MENU) do
        local b = pop.items[i]
        b:SetText(ns.T(it.lab))
        local on = true
        if it.key == "free" then on = kind == "p" end
        if it.key == "off" then on = kind ~= "x" end
        if it.key == "bot" then on = kind ~= "b" end
        if (it.key == "open" or it.key == "call") then on = kind ~= "o" and kind ~= "p" end
        if on then b:Enable() else b:Disable() end
    end
    pop:ClearAllPoints()
    pop:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 2)
    pop:Show()
end
local function drawBrowse(g)
    local list = T.Rooms("tycoon")
    local joining = T.Joining()
    for i, r in ipairs(ui.rows) do
        local it = list[i]
        if it then
            r.name:SetText(ns.T("tycoon.roomOf", it.host))
            local board = type(it.opts) == "table" and it.opts.board or "azeroth"
            r.what:SetText(ns.T(B.Key(B.INDEX[board] and board or "azeroth", "title")))
            paint(r.what, C.soft)
            local busy, all = 1, 1
            for j = 1, #it.kinds do
                local k = it.kinds:sub(j, j)
                if k ~= "x" then all = all + 1 end
                if k == "b" or k == "p" then busy = busy + 1 end
            end
            r.seats:SetText(ns.T("tycoon.roomSeats", busy, all))
            paint(r.seats, C.soft)
            r.sit.room = it
            r.sit:SetText(ns.T("tycoon.sit"))
            if joining then r.sit:Disable() else r.sit:Enable() end
            r:Show()
        else
            r:Hide()
        end
    end
    ui.empty:SetText(#list == 0 and ns.T("tycoon.noRooms") or "")
    paint(ui.empty, C.soft)
end
local function drawSeat(g, pos, b, kind, name, cls, pick, seat, pal, botTok)
    local room = T.Room()
    local mine = pos == "me" or (g.guest and room and POS_ORDER[room.pos] == pos)
    V.hgrad(b.bg, pal.panel2, pal.panel)
    V.tintBars(b.edge, mine and pal.accent or (kind == "x" and pal.frame or pal.frame2))
    b.ring:Hide()
    b.ask:Hide()
    b.av:Hide()
    b.name:SetText("")
    b.st:SetText("")
    b.tag:SetText("")
    b.plus:Hide()
    b.more:Hide()
    local host = not g.guest
    b.kind = kind
    if kind == "x" then
        b.plus:Show()
        if not host then b.plus:Disable() else b.plus:Enable() end
        return
    end
    if kind == "o" then
        b.name:SetText(ns.T("tycoon.open"))
        paint(b.name, C.gold)
        b.st:SetText(ns.T("tycoon.openWait"))
        paint(b.st, C.soft)
    else
        local t = pick and tonumber(pick:match("^t(%d)$")) or botTok
        if t then
            V.SetRing(b.ring, seat or 1, t)
            b.ring:Show()
        else
            V.SetRing(b.ring, seat or 1, 1)
            b.ring.tex:SetTexture(nil)
            b.ring:Show()
            b.ask:SetText("?")
            paint(b.ask, C.soft)
            b.ask:Show()
        end
        if kind == "b" then
            b.name:SetText(t and ns.T("tycoon.botName", ns.T("tycoon.tok" .. t)) or ns.T("tycoon.bot"))
            b.st:SetText(ns.T("tycoon.bot"))
            paint(b.st, C.soft)
        else
            b.name:SetText(name or "")
            if t then
                b.st:SetText(ns.T("tycoon.stPicked", ns.T("tycoon.tok" .. t)))
            else
                b.st:SetText(ns.T("tycoon.stPicking"))
            end
            paint(b.st, t and C.ok or C.soft)
        end
        paint(b.name, C.text)
    end
    if pos == "me" and not g.guest then
        b.tag:SetText(ns.T("tycoon.hostTag"))
        paint(b.tag, pal.accent)
    end
    if host and pos ~= "me" then b.more:Show() end
end
function V.DrawMenu(g)
    if not menuF then return end
    V.game = g
    local room = T.Room()
    if g.guest and not room then
        menuF:Show()
        return
    end
    local pal = B.palette[g.board] or B.palette.azeroth
    local browse = g.browse and not g.guest
    V.vgrad(ui.left, pal.panel2, pal.panel)
    V.vgrad(ui.right, pal.panel2, pal.panel)
    local wa = V.WinArt(g.board)
    local square = g.board == "icc"
    ui.mid:SetTexture(wa[1])
    if square then ui.mid:SetTexCoord(0.18, 0.82, 0.30, 0.86) else ui.mid:SetTexCoord(0.215, 0.785, 0, 1) end
    ui.mid:SetVertexColor(0.5, 0.5, 0.5, 1)
    local tb = ui.table
    tb.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    V.vgrad(tb.bg, pal.panel2, pal.field)
    V.tintBars(tb.vig, { 0, 0, 0 }, 0.28)
    V.tintBars(tb.frame, pal.frame)
    V.tintBars(tb.edge, pal.frame2)
    V.tintBars(tb.inner, pal.cellline)
    ns.Paint(tb.orn, pal.accent[1], pal.accent[2], pal.accent[3], 0.7)
    ui.tokCap:SetText(ns.T("tycoon.myToken"))
    paint(ui.tokCap, C.soft)
    local myPick = g:MyPick()
    local taken = g:TakenPicks()
    for i, b in ipairs(ui.tok) do
        local key = "t" .. i
        local who = taken[key]
        b.text:SetText(ns.T("tycoon.tok" .. i))
        b:Tone(myPick == key)
        V.SetRing(b.ring, who or g:Me(), i)
        if who and myPick ~= key then
            b.ring:SetAlpha(0.45)
            paint(b.text, C.cap)
        else
            b.ring:SetAlpha(1)
            paint(b.text, myPick == key and C.gold or C.text)
            if not who then ns.Paint(b.ring.rim, 0.2, 0.2, 0.22, 1) end
        end
        if browse then b:Hide() else b:Show() end
    end
    ui.tokNote:SetText("")
    ui.boardCap:SetText(ns.T("tycoon.boardCap"))
    paint(ui.boardCap, C.soft)
    for _, b in ipairs(ui.board) do
        b.text:SetText(ns.T(B.Key(b.key, "short")))
        b.sub:SetText(ns.T(B.Key(b.key, "mood")))
        paint(b.sub, C.soft)
        b:Tone(b.key == g.board)
        paint(b.text, (b.key == g.board) and C.gold or C.text)
        if g.guest then b:SetScript("OnClick", nil) end
    end
    ui.rulesCap:SetText(ns.T("tycoon.rulesCap"))
    paint(ui.rulesCap, C.soft)
    local cfg = g.cfg or {}
    for _, r in ipairs(ui.rules) do
        local key, val = r.key, cfg[r.key]
        r.lab:SetText(ns.T("tycoon.opt_" .. key))
        paint(r.lab, C.text)
        local s
        if key == "gold" then s = tostring(val)
        elseif key == "fin" then
            local m = type(val) == "string" and tonumber(val:match("^t(%d+)$"))
            s = m and ns.T("tycoon.finTime", m) or (val == "cap" and ns.T("tycoon.finCap", 10000) or ns.T("tycoon.finLast"))
        else s = ns.T("tycoon.optSec", val or 0) end
        r.btn:SetText(s)
        if g.guest or g.phase ~= "menu" then r.btn:Disable() else r.btn:Enable() end
        if browse then r.btn:Hide() r.lab:Hide() else r.btn:Show() r.lab:Show() end
    end
    for _, r in ipairs(ui.rows) do r:Hide() end
    ui.empty:SetText("")
    if browse then
        tb:Hide()
        for _, b in pairs(ui.seat) do b:Hide() end
        drawBrowse(g)
        ui.find:SetText(ns.T("tycoon.ownTable"))
        menuF:Show()
        return
    end
    tb:Show()
    tb.title:SetText(ns.T(B.Key(g.board, "title")))
    paint(tb.title, C.title)
    local hostName = g.guest and room.host or (UnitName("player") or "")
    tb.sub:SetText(ns.T("tycoon.label") .. " — " .. ns.T("tycoon.tableOf", hostName))
    paint(tb.sub, C.soft)
    local busy, all, waitName = 1, 1, nil
    local botTok = g:BotTokens()
    for pos, b in pairs(ui.seat) do
        b:Show()
        if pos == "me" then
            if g.guest then
                drawSeat(g, pos, b, "p", room.host, ns.Link.PeerClass(room.host), T.PickOf(0), 1, pal)
            else
                local _, cls = UnitClass("player")
                drawSeat(g, pos, b, "p", UnitName("player"), cls, T.PickOf(0), 1, pal)
            end
        else
            local i
            for k = 1, 3 do if POS_ORDER[k] == pos then i = k end end
            local kind = g.guest and room.kinds[i] or T.Kind(i) or g.seats:sub(i, i)
            if kind ~= "x" then all = all + 1 end
            if kind == "b" or kind == "p" then busy = busy + 1 end
            if kind == "b" then
                drawSeat(g, pos, b, "b", ns.T("tycoon.bot"), BOT_CLASS[i], nil, g:SeatOf(i), pal, botTok[i])
            elseif kind == "p" then
                local name = T.Name(i)
                drawSeat(g, pos, b, "p", name, T.Class(i) or ns.Link.PeerClass(name), T.PickOf(i), g:SeatOf(i), pal)
            else
                if kind == "o" then waitName = waitName or ns.T("tycoon.open") end
                drawSeat(g, pos, b, kind, nil, nil, nil, nil, pal)
            end
        end
    end
    local rc = room and room.ready
    local note = ns.T("tycoon.seatsTaken", busy, all)
    if waitName then note = note .. " — " .. ns.T("tycoon.seatsWait", waitName) end
    if g.guest then
        tb.start:Hide()
        tb.note:SetText(ns.T("tycoon.waitHost"))
        ui.find:SetText(ns.T("tycoon.leave"))
    else
        tb.start:Show()
        if rc then
            local yes, allR = T.ReadyCount()
            tb.start:SetText(ns.T("tycoon.readyCount", yes or 0, allR or 0))
            tb.start:Disable()
        else
            tb.start:SetText(ns.T("tycoon.start"))
            if g:Ready() then tb.start:Enable() else tb.start:Disable() end
        end
        local open = false
        for i = 1, 3 do if g.seats:sub(i, i) == "o" then open = true end end
        tb.note:SetText(note .. (open and ("\n" .. ns.T("tycoon.visible")) or ""))
        ui.find:SetText(ns.T("tycoon.findTable"))
    end
    paint(tb.note, C.soft)
    menuF:Show()
end
