local ADDON, ns = ...
local B, R = ns.TycoonBoards, ns.Tycoon
local V = ns.TycoonView
local C = V.C
local floor, min, max = math.floor, math.min, math.max
local CELLS, PROPS, GROUPS = B.cells, B.props, B.groups
local CW, CH = 1200, 720
local MODAL_W, MODAL_H = 700, 520
local COL_W, ROW_H, ROWS = 320, 22, 28
local MINI_W = 150
local au, tm, bd, rs = {}, {}, {}, {}
local function ensureAuction()
    local pr = V.prompt
    au.big = V.text(pr, "GameFontNormalLarge", nil, nil, 160, "RIGHT", 26)
    au.big:SetPoint("TOPRIGHT", pr, "TOPRIGHT", -12, -10)
    au.bigSub = V.text(pr, "GameFontHighlightSmall", nil, nil, 160, "RIGHT", 11)
    au.bigSub:SetPoint("TOPRIGHT", pr, "TOPRIGHT", -12, -40)
    au.rule = V.text(pr, "GameFontHighlightSmall", nil, nil, 200, "RIGHT", 11)
    au.rule:SetPoint("TOPRIGHT", pr, "TOPRIGHT", -12, -56)
    au.rows = {}
    for q = 1, 4 do
        local f = ns.PlainFrame(pr, 1)
        f:SetWidth(470)
        f:SetHeight(24)
        f.bg = V.grad(f, "BACKGROUND")
        f.bg:SetAllPoints(f)
        f.edge = V.edgeBars(f, "BORDER", { 0, 0, 0, 1 })
        f.ring = V.Ring(f, 20)
        V.at(f.ring, 4, 2, f)
        f.name = V.text(f, "GameFontHighlightSmall", 30, 4, 180, nil, 12)
        f.st = V.text(f, "GameFontNormalSmall", 220, 4, 240, "RIGHT", 12)
        f.tmBg = ns.Fill(f, "ARTWORK", 0, 0, 0, 0.8)
        f.tmBg:SetHeight(3)
        f.tmBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
        f.tmBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        f.tm = V.grad(f, "OVERLAY")
        f.tm:SetHeight(3)
        f.tm:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
        f:Hide()
        au.rows[q] = f
    end
    au.wait = V.text(pr, "GameFontHighlightSmall", 10, 0, 300, nil, 12)
end
function V.DrawAuction(g, v, S, me)
    local pr = V.prompt
    local pal = V.Pal()
    local T = ns.T
    local a = v.auc
    local c = a.c
    V.promptLot(g, v, c)
    pr.sub:SetText((CELLS[c].g and T(B.GroupKey(g.board, CELLS[c].g)) .. " — " or "") .. T("tycoon.aucPrice", V.Gold(CELLS[c].price)))
    pr.price:SetText("")
    pr.text:SetText("")
    au.big:SetText(a.lead > 0 and V.Gold(a.bid) or T("tycoon.aucNone"))
    V.paint(au.big, C.gold)
    au.bigSub:SetText(a.lead > 0 and (T("tycoon.aucBidCap") .. " — " .. g:SeatTag(a.lead)) or "")
    V.paint(au.bigSub, C.soft)
    au.rule:SetText(T("tycoon.aucRule"))
    V.paint(au.rule, C.soft)
    local y = 70
    local k = 0
    for i = 0, v.n - 1 do
        local q = (v.turn + i - 1) % v.n + 1
        local st = v.seats[q]
        local f = au.rows[q]
        if st then
            k = k + 1
            V.at(f, 10, y, pr)
            y = y + 26
            V.SetRing(f.ring, q, st.token)
            f.name:SetText(g:SeatName(q) .. ((q == me) and (" (" .. T("tycoon.you") .. ")") or ""))
            V.paint(f.name, C.text)
            local text, col = "", C.soft
            local passed = S.auc.passed[q]
            if not st.alive then text, col = T("tycoon.aucOut"), C.cap
            elseif q == a.lead then text, col = T("tycoon.aucLead", V.Gold(a.bid)), C.gold
            elseif passed then text, col = T("tycoon.aucPassed"), C.bad
            elseif q == v.who then text, col = (q == me) and T("tycoon.aucMine") or T("tycoon.aucThink"), pal.accent end
            f.st:SetText(text)
            V.paint(f.st, col)
            local hot = q == v.who
            V.hgrad(f.bg, hot and pal.panel2 or pal.log, pal.log, hot and 0.9 or 0.5)
            V.tintBars(f.edge, hot and pal.accent or pal.cellline)
            f:SetAlpha((passed or not st.alive) and 0.5 or 1)
            local left, limit = g:LeftFor(q)
            if hot and left and limit and limit > 0 then
                f.tm:SetWidth(max(1, 468 * max(0, min(1, left / limit))))
                V.hgrad(f.tm, pal.frame2, pal.accent)
                f.tm:Show()
                f.tmBg:Show()
            else
                f.tm:Hide()
                f.tmBg:Hide()
            end
            f:Show()
        else
            f:Hide()
        end
    end
    y = y + 6
    if v.who == me then
        for j = 1, 3 do
            V.at(pr.plus[j], 112 + (j - 1) * 56, y, pr)
            pr.plus[j]:Show()
        end
        V.at(pr.num, 10, y - 1, pr)
        pr.num:SetRange(a.bid + 1, v.seats[me].cash)
        if pr.num:Value() <= a.bid then pr.num:SetValue(a.bid + 1) end
        pr.num:Show()
        au.wait:Hide()
        V.setBtn(pr.b[1], T("tycoon.bid"), true, T("tycoon.aucMax"))
        pr.b[1].act = function(gg) gg:Act{ k = "bid", v = pr.num:Value() } end
        V.setBtn(pr.b[2], T("tycoon.pass"), true, T("tycoon.passTip"))
        pr.b[2].act = function(gg) gg:Act{ k = "pass" } end
        local h = y + 30 + 36
        V.promptSize(h)
        V.at(pr.b[1], 290, y - 2, pr)
        V.at(pr.b[2], 290 + 100, y - 2, pr)
        pr.b[1]:SetWidth(96)
        pr.b[2]:SetWidth(96)
        pr:SetHeight(y + 30)
        return y + 30
    end
    pr.b[1]:SetWidth(150)
    pr.b[2]:SetWidth(150)
    local left = g:LeftFor(v.who)
    au.wait:SetText(T("tycoon.aucWait", g:SeatTag(v.who)) .. (left and (" — " .. floor(left + 0.5)) or ""))
    V.paint(au.wait, C.soft)
    V.at(au.wait, 12, y, pr)
    au.wait:Show()
    V.promptSize(y + 22)
    for j = 1, 3 do pr.b[j]:Hide() end
    return y + 22
end
local function ensureTrade()
    local f = ns.PlainFrame(V.root, 10)
    f:SetAllPoints()
    f:EnableMouse(true)
    f.shade = ns.Fill(f, "BACKGROUND", 0, 0, 0, 0.62)
    f.shade:SetAllPoints(f)
    f:Hide()
    tm.f = f
    local box = V.panel(f, 1, (CW - MODAL_W) / 2, (CH - MODAL_H) / 2, MODAL_W, MODAL_H)
    tm.box = box
    box.title = V.text(box, "GameFontNormalLarge", 0, 12, MODAL_W, "CENTER", 20)
    box.sub = V.text(box, "GameFontHighlightSmall", 0, 38, MODAL_W, "CENTER", 12)
    tm.cols = {}
    for side = 1, 2 do
        local col = V.panel(box, 1, 14 + (side - 1) * (COL_W + 32), 60, COL_W, MODAL_H - 60 - 70)
        col.ring = V.Ring(col, 22)
        V.at(col.ring, 8, 8, col)
        col.name = V.text(col, "GameFontNormal", 36, 10, 150, nil, 13)
        col.role = V.text(col, "GameFontHighlightSmall", nil, nil, 110, "RIGHT", 11)
        col.role:SetPoint("TOPRIGHT", col, "TOPRIGHT", -8, -12)
        col.who = V.button(col, COL_W - 118, 6, 110, 22, function()
            local g = V.game
            local vv = g and g:View()
            if not g or not vv or not g.tb then return end
            local cur = g.tb.to
            for i = 1, vv.n do
                local q = (cur + i - 1) % vv.n + 1
                if q ~= g:Me() and vv.seats[q].alive then g:TradeWho(q) return end
            end
        end)
        col.who:Hide()
        col.rows = {}
        for i = 1, ROWS do
            local r = ns.NewFrame("Button", nil, col)
            r:SetWidth(COL_W - 16)
            r:SetHeight(ROW_H)
            V.at(r, 8, 40 + (i - 1) * ROW_H, col)
            r.box = ns.Fill(r, "ARTWORK", 0, 0, 0, 1)
            r.box:SetWidth(13)
            r.box:SetHeight(13)
            V.at(r.box, 2, 4, r)
            r.boxEdge = V.edgeBars(r, "ARTWORK", C.gold)
            r.on = ns.Fill(r, "OVERLAY", C.gold)
            r.on:SetWidth(7)
            r.on:SetHeight(7)
            r.on:SetPoint("CENTER", r.box, "CENTER", 0, 0)
            r.chip = ns.Fill(r, "ARTWORK", 0.5, 0.5, 0.5, 1)
            r.chip:SetWidth(8)
            r.chip:SetHeight(8)
            V.at(r.chip, 22, 7, r)
            r.icon = r:CreateTexture(nil, "ARTWORK")
            r.icon:SetWidth(16)
            r.icon:SetHeight(16)
            V.at(r.icon, 36, 3, r)
            r.name = V.text(r, "GameFontHighlightSmall", 58, 4, 190, nil, 12)
            r.mark = V.text(r, "GameFontHighlightSmall", nil, nil, 50, "RIGHT", 11)
            r.mark:SetPoint("TOPRIGHT", r, "TOPRIGHT", -4, -4)
            r:SetScript("OnClick", function(self)
                local g = V.game
                if g and g.tb and self.cell then g:TradeToggle(self.cell) end
            end)
            r:Hide()
            col.rows[i] = r
        end
        col.goldLab = V.text(col, "GameFontHighlightSmall", 8, 0, 60, nil, 12)
        col.goldBox = ns.MakeNumberBox(col, { w = 90, h = 24, min = 0, max = 999999, onChange = function(n)
            local g = V.game
            if g then g:TradeGold(side == 1 and "a" or "b", n) end
        end })
        col.goldText = V.text(col, "GameFontNormal", nil, nil, 120, "RIGHT", 14)
        col.goldOf = V.text(col, "GameFontHighlightSmall", nil, nil, 120, "RIGHT", 11)
        col.cardBtn = V.button(col, 8, 0, 180, 22, function()
            local g = V.game
            if g then g:TradeCard(side == 1 and "a" or "b") end
        end)
        col.cardText = V.text(col, "GameFontHighlightSmall", 8, 0, COL_W - 16, nil, 12)
        tm.cols[side] = col
    end
    box.arrow = V.text(box, "GameFontNormalLarge", 0, 0, MODAL_W, "CENTER", 22)
    box.arrow:SetPoint("CENTER", box, "CENTER", 0, 0)
    box.foot = V.text(box, "GameFontHighlightSmall", 14, MODAL_H - 56, 300, nil, 12)
    box.tmBg = ns.Fill(box, "ARTWORK", 0, 0, 0, 0.8)
    box.tmBg:SetHeight(6)
    V.at(box.tmBg, 14, MODAL_H - 34, box)
    box.tmBg:SetWidth(360)
    box.tm = V.grad(box, "OVERLAY")
    box.tm:SetHeight(6)
    V.at(box.tm, 14, MODAL_H - 34, box)
    box.b = {}
    for k = 1, 2 do
        box.b[k] = V.button(box, MODAL_W - 14 - 150 - (k - 1) * 158, MODAL_H - 42, 150, 28, function(self)
            local g = V.game
            if g and self.act then self.act(g) end
        end)
    end
end
local function tradeColumn(g, v, S, col, q, role, checked, gold, cards, editable, pal)
    local T = ns.T
    V.SetRing(col.ring, q, v.seats[q].token)
    col.name:SetText(g:SeatName(q))
    V.paint(col.name, C.text)
    col.role:SetText(role)
    V.paint(col.role, C.soft)
    local y = 40
    local k = 0
    for _, c in ipairs(PROPS) do
        if v.own[c] == q then
            k = k + 1
            local r = col.rows[k]
            if r then
                r.cell = c
                V.at(r, 8, y, col)
                y = y + ROW_H
                local cell = CELLS[c]
                local gc = cell.t == "prop" and B.GROUP_COLOR[cell.g] or cell.t == "rail" and pal.rail or pal.util
                ns.Paint(r.chip, gc[1], gc[2], gc[3], 1)
                V.CellIcon(r.icon, g.board, c)
                r.name:SetText(V.CellName(g.board, c))
                local on = checked[c]
                local locked = cell.t == "prop" and R.GroupBuilt(S, cell.g)
                V.paint(r.name, on and C.gold or (locked and C.cap or C.text))
                if on then r.on:Show() else r.on:Hide() end
                V.tintBars(r.boxEdge, on and C.gold or pal.frame2)
                local mark = ""
                if v.mort[c] then mark = T("tycoon.cardMortgaged") elseif v.lv[c] > 0 then mark = "x" .. v.lv[c] end
                r.mark:SetText(mark)
                V.paint(r.mark, C.soft)
                r:SetAlpha(locked and 0.5 or 1)
                if editable and not locked then r:EnableMouse(true) else r:EnableMouse(false) end
                r:Show()
            end
        end
    end
    for i = k + 1, ROWS do col.rows[i]:Hide() end
    if k == 0 then
        col.rows[1].cell = nil
        col.rows[1]:Hide()
    end
    local gy = col:GetHeight() - 56
    col.goldLab:ClearAllPoints()
    col.goldLab:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -(gy + 6))
    col.goldLab:SetText(T("tycoon.tbGoldCap"))
    V.paint(col.goldLab, C.soft)
    col.goldOf:ClearAllPoints()
    col.goldOf:SetPoint("TOPRIGHT", col, "TOPRIGHT", -8, -(gy + 28))
    col.goldOf:SetText(T("tycoon.trOf", V.Gold(v.seats[q].cash)))
    V.paint(col.goldOf, C.soft)
    if editable then
        col.goldBox:ClearAllPoints()
        col.goldBox:SetPoint("TOPRIGHT", col, "TOPRIGHT", -8, -gy)
        col.goldBox:SetRange(0, v.seats[q].cash)
        if col.goldBox:Value() ~= gold then col.goldBox:SetValue(gold) end
        col.goldBox:Show()
        col.goldText:Hide()
    else
        col.goldBox:Hide()
        col.goldText:ClearAllPoints()
        col.goldText:SetPoint("TOPRIGHT", col, "TOPRIGHT", -8, -(gy + 4))
        col.goldText:SetText(V.Gold(gold))
        V.paint(col.goldText, C.gold)
        col.goldText:Show()
    end
    local cardName = T(B.Key(g.board, "card"))
    col.cardBtn:ClearAllPoints()
    col.cardBtn:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -(gy - 30))
    col.cardText:ClearAllPoints()
    col.cardText:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -(gy - 26))
    if v.seats[q].free ~= "" and editable then
        V.setBtn(col.cardBtn, cardName .. ": " .. (cards ~= "" and "+" or "-"), true, nil)
        col.cardText:Hide()
    else
        col.cardBtn:Hide()
        col.cardText:SetText(cards ~= "" and T("tycoon.pCards", cardName, #cards) or "")
        V.paint(col.cardText, C.gold)
        col.cardText:Show()
    end
end
function V.TradeModal(g, v, S, me)
    local T = ns.T
    local pal = V.Pal()
    local box = tm.box
    V.vgrad(box.bg, pal.panel2, pal.panel)
    V.tintBars(box.edge, pal.frame2)
    for side = 1, 2 do
        local col = tm.cols[side]
        ns.Paint(col.bg, pal.log[1], pal.log[2], pal.log[3], 1)
        V.tintBars(col.edge, pal.frame)
    end
    box.title:SetText(T("tycoon.tbTitle"))
    V.paint(box.title, C.title)
    box.arrow:SetText("<>")
    V.paint(box.arrow, C.soft)
    box.b[1]:Hide()
    box.b[2]:Hide()
    tm.cols[1].who:Hide()
    tm.cols[2].who:Hide()
    local left, limit
    if g.tb then
        local tb = g.tb
        local to = tb.to
        box.sub:SetText(to and (g:SeatTag(me) .. " > " .. g:SeatTag(to)) or "")
        tradeColumn(g, v, S, tm.cols[1], me, T("tycoon.trGive"), tb.give, tb.ga, tb.ja, true, pal)
        if to then
            tradeColumn(g, v, S, tm.cols[2], to, T("tycoon.trGet"), tb.get, tb.gb, tb.jb, true, pal)
            local others = 0
            for q = 1, v.n do if q ~= me and v.seats[q].alive then others = others + 1 end end
            if others > 1 then
                tm.cols[2].who:SetText(T("tycoon.trWho", g:SeatName(to)))
                tm.cols[2].who:Show()
                tm.cols[2].role:Hide()
            else
                tm.cols[2].role:Show()
            end
        end
        local m = g:TradeMove()
        local ok = m ~= nil and R.Legal(S, m)
        box.foot:SetText(ok and "" or T("tycoon.tbBad"))
        V.paint(box.foot, C.bad)
        V.setBtn(box.b[1], T("tycoon.propose"), ok, nil)
        box.b[1].act = function(gg) gg:TradeSend() end
        V.setBtn(box.b[2], T("tycoon.cancel"), true, nil)
        box.b[2].act = function(gg) gg:TradeCancel() end
    else
        local o = v.offer
        box.sub:SetText(g:SeatTag(o.from) .. " > " .. g:SeatTag(o.to))
        local la, lb = {}, {}
        for _, c in ipairs(R.MaskList(o.la)) do la[c] = true end
        for _, c in ipairs(R.MaskList(o.lb)) do lb[c] = true end
        tradeColumn(g, v, S, tm.cols[1], o.from, T("tycoon.trGive"), la, o.ga, o.ja, false, pal)
        tradeColumn(g, v, S, tm.cols[2], o.to, T("tycoon.trGet"), lb, o.gb, o.jb, false, pal)
        tm.cols[2].role:Show()
        left, limit = g:LeftFor(o.to)
        if o.to == me then
            box.foot:SetText(T("tycoon.trAsked", g:SeatTag(o.from)))
            V.setBtn(box.b[1], T("tycoon.accept"), R.Legal(S, { k = "yes", s = me }), nil)
            box.b[1].act = function(gg) gg:Act{ k = "yes" } end
            V.setBtn(box.b[2], T("tycoon.decline"), true, nil)
            box.b[2].act = function(gg) gg:Act{ k = "no" } end
        else
            box.foot:SetText(T("tycoon.trWait", g:SeatTag(o.to)))
            if o.from == me then
                V.setBtn(box.b[1], T("tycoon.withdraw"), true, nil)
                box.b[1].act = function(gg) gg:Act{ k = "no" } end
            end
        end
        V.paint(box.foot, C.soft)
    end
    if left and limit and limit > 0 then
        box.tm:SetWidth(max(1, 360 * max(0, min(1, left / limit))))
        V.hgrad(box.tm, pal.frame2, pal.accent)
        box.tm:Show()
        box.tmBg:Show()
    else
        box.tm:Hide()
        box.tmBg:Hide()
    end
    tm.f:Show()
end
function V.TradeHide()
    if tm.f then tm.f:Hide() end
end
local function ensureBuild()
    local pr = V.prompt
    bd.cards = {}
    for k = 1, 3 do
        local f = V.panel(pr, 1, 10 + (k - 1) * (MINI_W + 10), 44, MINI_W, 96)
        f.bar = ns.Fill(f, "ARTWORK", 0.5, 0.5, 0.5, 1)
        f.bar:SetHeight(6)
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        f.bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetWidth(28)
        f.icon:SetHeight(28)
        V.at(f.icon, 8, 12, f)
        f.name = V.text(f, "GameFontHighlightSmall", 42, 12, MINI_W - 48, nil, 11)
        f.lv = V.text(f, "GameFontNormal", 42, 28, MINI_W - 48, nil, 12)
        f.house = f:CreateTexture(nil, "OVERLAY")
        f.house:SetTexture(B.HOUSE_TEX)
        f.house:SetWidth(32)
        f.house:SetHeight(32)
        V.at(f.house, MINI_W - 40, 6, f)
        f.house:Hide()
        f.rent = V.text(f, "GameFontHighlightSmall", 42, 44, MINI_W - 48, nil, 11)
        f.minus = V.button(f, 8, 64, 40, 24, function(self)
            local g = V.game
            if g and self.cell then g:Act{ k = "down", c = self.cell } end
        end)
        f.minus:SetText("-")
        f.plus = V.button(f, 54, 64, 40, 24, function(self)
            local g = V.game
            if g and self.cell then g:Act{ k = "up", c = self.cell } end
        end)
        f.plus:SetText("+")
        f:Hide()
        bd.cards[k] = f
    end
    bd.hint = V.text(pr, "GameFontHighlightSmall", 10, 146, 470, nil, 11)
    bd.sum = V.text(pr, "GameFontHighlightSmall", 10, 162, 470, nil, 12)
end
function V.DrawBuild(g, v, S, me)
    local c = g.sel
    if not c then return 0 end
    local cell = CELLS[c]
    if cell.t ~= "prop" or v.own[c] ~= me then return 0 end
    local ph = v.phase
    local mine = (ph == "pre" or ph == "post") and v.turn == me or (ph == "debt" and v.who == me)
    if not mine or not R.GroupFull(S, me, cell.g) then return 0 end
    local pr = V.prompt
    local pal = V.Pal()
    local T = ns.T
    local board = g.board
    V.plainPrompt()
    pr.title:SetText(T("tycoon.bdTitle", T(B.GroupKey(board, cell.g))))
    V.paint(pr.title, C.title)
    pr.text:SetText(T("tycoon.bdCost", T(B.Key(board, "house")), V.Gold(cell.house), T(B.Key(board, "hotel")), V.Gold(cell.house), T(B.Key(board, "houses"))))
    V.paint(pr.text, C.soft)
    local list = GROUPS[cell.g]
    local gc = B.GROUP_COLOR[cell.g]
    for k = 1, 3 do
        local f = bd.cards[k]
        local x = list[k]
        if x then
            f:Show()
            V.vgrad(f.bg, pal.cell, pal.cell2)
            V.tintBars(f.edge, pal.cellline)
            ns.Paint(f.bar, gc[1], gc[2], gc[3], 1)
            V.CellIcon(f.icon, board, x)
            f.name:SetText(V.CellName(board, x))
            V.paint(f.name, C.ink)
            local lv = v.lv[x]
            local lvText
            if v.mort[x] then lvText = T("tycoon.cardMortgaged")
            elseif lv == 5 then lvText = T(B.Key(board, "hotel"))
            elseif lv == 0 then lvText = T("tycoon.bdEmpty")
            else lvText = T("tycoon.cardRentN", lv, T(B.Key(board, "house"))) end
            f.lv:SetText(lvText)
            if lv > 0 and not v.mort[x] then
                f.house:SetTexCoord(B.HouseCoord(board, lv == 5))
                f.house:Show()
            else
                f.house:Hide()
            end
            V.paint(f.lv, lv == 5 and C.hotel or (lv > 0 and C.house or C.cap))
            f.rent:SetText(T("tycoon.bdRent", R.Rent(S, x)))
            V.paint(f.rent, C.ink)
            f.minus.cell, f.plus.cell = x, x
            local okUp = R.Legal(S, { k = "up", s = me, c = x })
            local okDown = R.Legal(S, { k = "down", s = me, c = x })
            local _, whyUp = R.CanUp(S, me, x)
            local _, whyDown = R.CanDown(S, me, x)
            V.setBtn(f.plus, "+", okUp, okUp and T("tycoon.build") or (ph == "debt" and T("tycoon.whyPhase") or V.Why(board, whyUp)))
            V.setBtn(f.minus, "-", okDown, okDown and T("tycoon.demolishTip") or V.Why(board, whyDown))
            if x == c then V.tintBars(f.edge, pal.accent) end
        else
            f:Hide()
        end
    end
    bd.hint:SetText(T("tycoon.bdHint"))
    V.paint(bd.hint, C.soft)
    bd.sum:SetText(T("tycoon.bdGold", V.Gold(v.seats[me].cash)) .. "   " .. T("tycoon.bdBank", T(B.Key(board, "houses")), R.Houses(S), T(B.Key(board, "hotels")), R.Hotels(S)))
    V.paint(bd.sum, C.text)
    local function arm(b, k, label, canFn)
        local ok = R.Legal(S, { k = k, s = me, c = c })
        local tip
        if not ok then
            local fine, why = canFn(S, me, c)
            tip = fine and T("tycoon.whyPhase") or V.Why(board, why)
        end
        V.setBtn(b, label, ok, tip)
    end
    arm(pr.b[1], T("tycoon.mortgage"), "mort", R.CanMort)
    pr.b[1].act = function(gg) gg:Act{ k = "mort", c = c } end
    arm(pr.b[2], T("tycoon.lift"), "lift", R.CanLift)
    pr.b[2].act = function(gg) gg:Act{ k = "lift", c = c } end
    pr.b[1]:SetWidth(150)
    pr.b[2]:SetWidth(150)
    local h = 216
    V.promptSize(h)
    bd.hint:Show()
    bd.sum:Show()
    return h
end
local function ensureResult()
    local cur = ns.PlainFrame(V.fxF, 1)
    cur:SetAllPoints(V.root)
    cur.bg = ns.Fill(cur, "BACKGROUND", 0, 0, 0, 0.65)
    cur.bg:SetAllPoints(cur)
    cur:EnableMouse(true)
    cur:Hide()
    rs.curtain = cur
    local f = ns.PlainFrame(V.fxF, 2)
    f:SetWidth(560)
    f:SetHeight(300)
    f:SetPoint("CENTER", V.boardF, "TOPLEFT", 660, -360)
    f.bg = V.grad(f, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.edge = V.edgeBars(f, "BORDER", C.gold, 2)
    f.title = V.text(f, "GameFontNormalLarge", 0, 10, 560, "CENTER", 22)
    f.sub = V.text(f, "GameFontHighlightSmall", 0, 36, 560, "CENTER", 12)
    f.pic = f:CreateTexture(nil, "ARTWORK")
    V.at(f.pic, 2, 54, f)
    f.pic:SetWidth(556)
    f.pic:SetHeight(170)
    f.pedestal = f:CreateTexture(nil, "ARTWORK")
    f.pedestal:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
    f.pedestal:SetWidth(130)
    f.pedestal:SetHeight(40)
    f.pedestal:SetPoint("CENTER", f, "TOP", 0, -214)
    f.winTok = f:CreateTexture(nil, "OVERLAY")
    f.winTok:SetWidth(96)
    f.winTok:SetHeight(96)
    f.winTok:SetPoint("BOTTOM", f.pedestal, "CENTER", 0, -6)
    f.plate = ns.Fill(f, "ARTWORK", 0, 0, 0, 0.82)
    V.at(f.plate, 2, 226, f)
    f.plate:SetWidth(556)
    f.plate:SetHeight(52)
    f.winName = V.text(f, "GameFontNormalLarge", 0, 232, 560, "CENTER", 20)
    f.winLine = V.text(f, "GameFontHighlightSmall", 0, 258, 560, "CENTER", 12)
    f.rows = {}
    for k = 1, 4 do
        local r = ns.PlainFrame(f, 1)
        r:SetWidth(532)
        r:SetHeight(36)
        V.at(r, 14, 290 + (k - 1) * 40, f)
        r.bg = V.grad(r, "BACKGROUND")
        r.bg:SetAllPoints(r)
        r.edge = V.edgeBars(r, "BORDER", { 0, 0, 0, 1 })
        r.pos = V.text(r, "GameFontNormalLarge", 6, 6, 26, "CENTER", 18)
        r.ring = V.Ring(r, 30)
        V.at(r.ring, 38, 3, r)
        r.name = V.text(r, "GameFontNormal", 76, 4, 170, nil, 13)
        r.why = V.text(r, "GameFontHighlightSmall", 76, 20, 240, nil, 10)
        r.gold = V.text(r, "GameFontNormal", 320, 4, 110, "RIGHT", 13)
        r.plots = V.text(r, "GameFontHighlightSmall", 320, 20, 110, "RIGHT", 10)
        r.cap = V.text(r, "GameFontHighlightSmall", 436, 10, 90, "RIGHT", 11)
        f.rows[k] = r
    end
    f.again = V.button(f, 0, 0, 150, 28, function() local g = V.game if g then g:Restart() end end)
    f.again:ClearAllPoints()
    f.again:SetPoint("BOTTOM", f, "BOTTOM", 0, 30)
    f.hint = V.text(f, "GameFontHighlightSmall", 0, 0, 560, "CENTER", 11)
    f.hint:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    f:Hide()
    rs.f = f
end
function V.DrawResult(g, v, S)
    local f = rs.f
    if not v.over then
        f:Hide()
        rs.curtain:Hide()
        return
    end
    local T = ns.T
    local pal = V.Pal()
    local me = g:Me()
    rs.curtain:Show()
    V.vgrad(f.bg, pal.panel2, pal.panel)
    V.tintBars(f.edge, pal.frame2)
    local wa = V.WinArt(g.board)
    f.pic:SetTexture(wa[1])
    f.pic:SetTexCoord(wa[2], wa[3], wa[4], wa[5])
    f.title:SetText(T("tycoon.resTitle"))
    V.paint(f.title, C.title)
    f.sub:SetText(T(B.Key(g.board, "title")))
    V.paint(f.sub, C.soft)
    local order = {}
    for q = 1, v.n do order[#order + 1] = q end
    table.sort(order, function(a, b) return (v.seats[a].out or 0) > (v.seats[b].out or 0) end)
    local win = order[1]
    local function plots(q)
        local n = 0
        for _, c in ipairs(PROPS) do if v.own[c] == q then n = n + 1 end end
        return n
    end
    local wc = B.SEAT_COLOR[win]
    f.pedestal:SetVertexColor(wc[1], wc[2], wc[3])
    V.TokenTex(f.winTok, v.seats[win].token)
    f.winName:SetText(g:SeatName(win) .. " " .. T("tycoon.pWin"))
    V.paint(f.winName, C.gold)
    f.winLine:SetText(T("tycoon.resWinner", V.Gold(v.seats[win].cash), plots(win)))
    V.paint(f.winLine, C.soft)
    for k = 1, 4 do
        local r = f.rows[k]
        local q = order[k]
        if q then
            local st = v.seats[q]
            r:Show()
            V.hgrad(r.bg, k == 1 and pal.panel2 or pal.log, pal.log, 0.9)
            V.tintBars(r.edge, q == me and pal.accent or pal.cellline)
            r.pos:SetText(tostring(k))
            V.paint(r.pos, k == 1 and C.gold or C.soft)
            V.SetRing(r.ring, q, st.token)
            r.ring.tex:SetAlpha(k == 1 and 1 or 0.6)
            r.name:SetText(g:SeatName(q) .. ((q == me) and (" (" .. T("tycoon.you") .. ")") or ""))
            V.paint(r.name, C.text)
            local fate = g.fate and g.fate[q]
            local why = ""
            if k > 1 then
                if fate and fate.quit then why = T("tycoon.resQuit")
                elseif fate then why = T("tycoon.resBankrupt", fate.to > 0 and g:SeatName(fate.to) or T("tycoon.bank"))
                else why = T("tycoon.pOut", k) end
            else
                why = T("tycoon.pWin")
            end
            r.why:SetText(why)
            V.paint(r.why, k == 1 and C.gold or C.soft)
            r.gold:SetText(V.Gold(st.cash))
            V.paint(r.gold, st.cash > 0 and C.gold or C.cap)
            r.plots:SetText(T("tycoon.pPlots", plots(q)))
            V.paint(r.plots, C.soft)
            r.cap:SetText(T("tycoon.resCapital", V.Gold(R.Capital(S, q))))
            V.paint(r.cap, C.soft)
        else
            r:Hide()
        end
    end
    f:SetHeight(290 + v.n * 40 + 70)
    f.again:SetText(T("tycoon.resAgain"))
    if g.guest then f.again:Hide() else f.again:Show() end
    f.hint:SetText(T("tycoon.resHint"))
    V.paint(f.hint, C.soft)
    f:Show()
end
function V.EnsurePanels()
    if au.rows then return end
    ensureAuction()
    ensureTrade()
    ensureBuild()
    ensureResult()
end
function V.PaintPanels(pal)
    if not au.rows then return end
    for k = 1, 3 do
        local f = bd.cards[k]
        V.vgrad(f.bg, pal.cell, pal.cell2)
        V.tintBars(f.edge, pal.cellline)
    end
end
