local ADDON, ns = ...
local ID = "solitaire"
local DECK = "deck"
local WOOD = { 0.230, 0.190, 0.130 }
local EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = WOOD, edge = EDGE }
local floor, abs = math.floor, math.abs
local min, max = math.min, math.max
local END_FLASH = 0.8
local CANVAS_W, CANVAS_H = 640, 480
local CARD_W, CARD_H = 68, 96
local NICHE_X, NICHE_Y, NICHE_H = 14, 10, 28
local EXIT_W, EXIT_GAP = 150, 10
local NICHE_LEFT = NICHE_X + EXIT_W + EXIT_GAP
local NICHE_W = CANVAS_W - NICHE_LEFT - NICHE_X
local NICHE_GROUP = {
    { key = "clock", x = 24,  w = 112, cap = "solitaire.time" },
    { key = "moves", x = 152, w = 104, cap = "solitaire.nicheMoves" },
    { key = "best",  x = 272, w = 168, cap = "solitaire.nicheBest" },
}
local ROW_GAP = 12
local MARGIN_TOP = NICHE_Y + NICHE_H + 8
local MARGIN_BOTTOM = 10
local L = { cols = 7, colx = {}, topY = 0, tabTopY = 0, avail = 0 }
local function relayout(m)
    local cols, gap = m.cols, m.gap
    local width = cols * CARD_W + (cols - 1) * gap
    L.cols = cols
    local margin = floor((CANVAS_W - width) / 2)
    for i = 1, cols do L.colx[i] = margin + (i - 1) * (CARD_W + gap) end
    for i = cols + 1, #L.colx do L.colx[i] = nil end
    L.topY = CANVAS_H - MARGIN_TOP - CARD_H
    L.tabTopY = L.topY - ROW_GAP - CARD_H
    L.avail = L.tabTopY + CARD_H - MARGIN_BOTTOM
    L.zone = { home = {}, cell = {} }
    local homes, cells = 0, 0
    for i = 1, cols do
        local kind, x = m.top[i], L.colx[i]
        if kind == "stock" then L.zone.stock = x
        elseif kind == "waste" then L.zone.waste = x
        elseif kind == "home" then homes = homes + 1; L.zone.home[homes] = x
        elseif kind == "cell" then cells = cells + 1; L.zone.cell[cells] = x
        end
    end
    L.homeN, L.cellN = homes, cells
end
local MARK_INSET, INDEX_RANK, MARK_SIZE, INDEX_W = ns.DeckCardIndexBox(CARD_W, CARD_H)
local PAPER_PLAIN = ns.DECK_PAPER
local PAPER_HELD  = { 1, 0.97, 0.84 }
local PAPER_DIM   = { 0.56, 0.49, 0.36 }
local INK_DIM     = 0.90
local COVER_DIM   = 0.58
local HELD_LIFT   = 6
local OFFSET_CLOSED = 9
local OFFSET_OPEN = MARK_INSET + INDEX_RANK + 1 + MARK_SIZE
local MIN_OFFSET = 6
local board, cardLayer, cardF, banner
local felt
local niche, exit, nicheCap, nicheVal
local menu
local M_PAD = 16
local SLOT_TOP, SLOT_H, SLOT_GAP = 20, 104, 8
local SEAM1, SEAM2 = 147, 394
local BAND_TOP = 160
local PLAY_W, PLAY_H, PLAY_TOP = 220, 44, 414
local PAIR_W, PAIR_GAP = 200, 16
local MENU_MAX = 4
local LIFT_TIME = 0.34
local GROW_TIME = 0.32
local MINI_X, MINI_W = M_PAD, CANVAS_W - M_PAD * 2
local MINI_TOP, MINI_H = BAND_TOP, SEAM2 - BAND_TOP - 12
local MINI_MAX = 0.72
local C_CAP   = { 0.54, 0.51, 0.45 }
local C_TEXT  = { 0.91, 0.90, 0.86 }
local C_SOFT  = { 0.65, 0.61, 0.53 }
local C_GOLD  = { 1, 0.82, 0 }
local C_SEAM  = { 0.52, 0.42, 0.26, 0.45 }
local C_RULE  = { 0.21, 0.18, 0.14, 1 }
local VAL_FONT = "Fonts\\FRIZQT__.TTF"
local backIcon
local suitIcon = {}
local ASK_LEVEL = 80
local ask
local staying
local dragHost
local dragTick
local press
local drag
local lastTap
local FONT_TXT = "Fonts\\ARIALN.TTF"
local function bigFont(fs, size)
    if fs:SetFont(FONT_TXT, size, "THICKOUTLINE") then return end
    fs:SetFont((fs:GetFont()), size, "THICKOUTLINE")
end
local SLOT_LIP = 6
local SLOT_TONE = {
    plain = {
        bg    = { 0.15, 0.12, 0.07, 0.55 },
        edge  = { 1, 0.82, 0, 0.40 },
        shade = { 0, 0, 0, 0.55 },
        light = { 1, 0.86, 0.48, 0.22 },
    },
    go = {
        bg    = { 0.34, 0.27, 0.09, 0.75 },
        edge  = { 1, 0.82, 0, 1 },
        shade = { 0, 0, 0, 0.45 },
        light = { 1, 0.92, 0.60, 0.60 },
    },
    dim = {
        bg    = { 0.05, 0.04, 0.02, 0.45 },
        edge  = { 1, 0.82, 0, 0.10 },
        shade = { 0, 0, 0, 0.35 },
        light = { 1, 0.86, 0.48, 0.05 },
    },
}
local slots = {}
local slotUsed = 0
local slotAt = { home = {}, cell = {}, col = {} }
local function bevel(f)
    if f.lip then return end
    local function bar(p1, p2, w, h, dx1, dy1, dx2, dy2)
        local t = ns.Fill(f, "ARTWORK", { 0, 0, 0, 1 })
        t:SetPoint(p1, f, p1, dx1, dy1)
        t:SetPoint(p2, f, p2, dx2, dy2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        return t
    end
    local i = SLOT_LIP
    f.lip = {
        bar("TOPLEFT", "TOPRIGHT", nil, 1, i, -i, -i, -i),
        bar("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1, i, i, -i, i),
        bar("TOPLEFT", "BOTTOMLEFT", 1, nil, i, -(i + 1), i, i + 1),
        bar("TOPRIGHT", "BOTTOMRIGHT", 1, nil, -i, -(i + 1), -i, i + 1),
    }
end
local function useSlot(canvas, x, y)
    slotUsed = slotUsed + 1
    local f = slots[slotUsed]
    if not f then
        f = CreateFrame("Frame", nil, board)
        f:SetWidth(CARD_W)
        f:SetHeight(CARD_H)
        f:SetBackdrop(ns.CARD_BACKDROP)
        bevel(f)
        slots[slotUsed] = f
    end
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y)
    f:Show()
    return f
end
local function toneSlot(f, tone)
    local sk = SLOT_TONE[tone] or SLOT_TONE.plain
    f:SetBackdropColor(sk.bg[1], sk.bg[2], sk.bg[3], sk.bg[4])
    f:SetBackdropBorderColor(sk.edge[1], sk.edge[2], sk.edge[3], sk.edge[4])
    if not f.lip then return end
    local sh, li = sk.shade, sk.light
    f.lip[1]:SetTexture(sh[1], sh[2], sh[3], sh[4])
    f.lip[3]:SetTexture(sh[1], sh[2], sh[3], sh[4])
    f.lip[2]:SetTexture(li[1], li[2], li[3], li[4])
    f.lip[4]:SetTexture(li[1], li[2], li[3], li[4])
end
local function placeSlots(canvas, m)
    slotUsed = 0
    slotAt = { home = {}, cell = {}, col = {} }
    local homes, cells = 0, 0
    for i = 1, L.cols do
        local kind = m.top[i]
        if kind then
            local f = useSlot(canvas, L.colx[i], L.topY)
            if kind == "stock" then slotAt.stock = f
            elseif kind == "waste" then slotAt.waste = f
            elseif kind == "home" then homes = homes + 1; slotAt.home[homes] = f
            elseif kind == "cell" then cells = cells + 1; slotAt.cell[cells] = f
            end
        end
    end
    for c = 1, L.cols do slotAt.col[c] = useSlot(canvas, L.colx[c], L.tabTopY) end
    for i = 1, slotUsed do toneSlot(slots[i], nil) end
    for i = slotUsed + 1, #slots do slots[i]:Hide() end
end
local function buildCard()
    local f = ns.MakeDeckCard(cardLayer)
    f:SetWidth(CARD_W)
    f:SetHeight(CARD_H)
    ns.DeckCardPaper(f)
    f.rank:SetPoint("CENTER", f, "CENTER", 0, 0)
    local axis = MARK_INSET + INDEX_W / 2
    local drop = MARK_INSET + INDEX_RANK + 1
    f.corner:ClearAllPoints()
    f.corner:SetWidth(INDEX_W)
    f.corner:SetJustifyH("CENTER")
    f.corner:SetPoint("TOPLEFT", f, "TOPLEFT", MARK_INSET, -MARK_INSET)
    f.mark:ClearAllPoints()
    f.mark:SetWidth(MARK_SIZE)
    f.mark:SetHeight(MARK_SIZE)
    f.mark:SetPoint("TOP", f, "TOPLEFT", axis, -drop)
    f.corner2:ClearAllPoints()
    f.corner2:SetWidth(INDEX_W)
    f.corner2:SetJustifyH("CENTER")
    f.corner2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -MARK_INSET, MARK_INSET)
    f.mark2:ClearAllPoints()
    f.mark2:SetWidth(MARK_SIZE)
    f.mark2:SetHeight(MARK_SIZE)
    f.mark2:SetPoint("BOTTOM", f, "BOTTOMRIGHT", -axis, drop)
    f:Hide()
    return f
end
local function buildTile(root)
    local t = ns.MakeSlot(root, LOOK)
    t:SetHeight(SLOT_H)
    t.name = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.name:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -11)
    t.line = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t.line:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -34)
    t.line:SetJustifyH("LEFT")
    t.line:SetJustifyV("TOP")
    t.best = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t.best:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 12, 9)
    t.foot = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t.foot:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -12, 9)
    t:SetScript("OnClick", function(self2)
        local g = ns.Loop.Current()
        if g and g.Pick and self2.pick then ns.Sfx.Ui(); g:Pick(self2.pick) end
    end)
    return t
end
local function seam(parent, y)
    local t = ns.Fill(parent, "ARTWORK", C_SEAM)
    t:SetHeight(1)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", M_PAD, -y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -M_PAD, -y)
end
local function buildMenu(canvas)
    local m = {}
    m.root = ns.PlainFrame(canvas, 50)
    m.root:SetAllPoints()
    m.root:EnableMouse(true)
    m.bg = ns.MakeTable(m.root, LOOK)
    m.bg:Show()
    m.tile = {}
    for i = 1, MENU_MAX do m.tile[i] = buildTile(m.root) end
    seam(m.root, SEAM1)
    seam(m.root, SEAM2)
    m.mini, m.miniSlot, m.miniOf = {}, {}, {}
    m.play = ns.MakeKitButton(m.root)
    m.play:SetHeight(PLAY_H)
    m.resume = ns.MakeKitButton(m.root)
    m.resume:SetHeight(PLAY_H)
    m.resume:Hide()
    m.root:Hide()
    return m
end
local function ensureView(canvas)
    if cardLayer then return end
    board = CreateFrame("Frame", nil, canvas)
    board:SetAllPoints()
    board:SetFrameLevel(canvas:GetFrameLevel() + 1)
    cardLayer = CreateFrame("Frame", nil, canvas)
    cardLayer:SetAllPoints()
    cardLayer:SetFrameLevel(canvas:GetFrameLevel() + 2)
    dragHost = CreateFrame("Frame", nil, canvas)
    dragHost:Hide()
    dragHost:SetScript("OnUpdate", function()
        if dragTick then dragTick() end
    end)
    felt = ns.MakeTable(canvas, LOOK)
    niche = ns.MakeNiche(canvas, 30, LOOK)
    niche:SetPoint("TOPLEFT", canvas, "TOPLEFT", NICHE_LEFT, -NICHE_Y)
    niche:SetWidth(NICHE_W)
    niche:SetHeight(NICHE_H)
    niche:Hide()
    exit = ns.MakeKitButton(canvas)
    exit:SetFrameLevel(canvas:GetFrameLevel() + 30)
    exit:SetWidth(EXIT_W)
    exit:SetHeight(NICHE_H)
    exit:SetPoint("TOPLEFT", canvas, "TOPLEFT", NICHE_X, -NICHE_Y)
    exit:Hide()
    nicheCap, nicheVal = {}, {}
    for i, g in ipairs(NICHE_GROUP) do
        if i > 1 then
            local sep = ns.Fill(niche, "ARTWORK", C_RULE)
            sep:SetWidth(1)
            sep:SetPoint("TOP", niche, "TOPLEFT", g.x - 10, -6)
            sep:SetPoint("BOTTOM", niche, "TOPLEFT", g.x - 10, -(NICHE_H - 6))
        end
        nicheCap[g.key] = ns.MakeCap(niche, g.x, 9)
        local val = niche:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetFont(VAL_FONT, 16, "")
        val:SetJustifyH("RIGHT")
        val:SetPoint("TOPRIGHT", niche, "TOPLEFT", g.x + g.w, -6)
        nicheVal[g.key] = val
    end
    exit.onClick = function()
        local g = ns.Loop.Current()
        if g and g.ToMenu then g:ToMenu() end
    end
    menu = buildMenu(canvas)
    menu.play.onClick = function()
        local g = ns.Loop.Current()
        if not g then return end
        if g.Started and g:Started() then g:AskFresh() else g:BeginRound() end
    end
    menu.resume.onClick = function()
        local g = ns.Loop.Current()
        if g and g.BeginRound then g:BeginRound() end
    end
    cardF = {}
    for id = 1, 52 do cardF[id] = buildCard() end
    local bannerHost = CreateFrame("Frame", nil, canvas)
    bannerHost:SetAllPoints()
    bannerHost:SetFrameLevel(canvas:GetFrameLevel() + 3)
    banner = bannerHost:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bigFont(banner, 16)
    banner:Hide()
end
local function miniCard(i)
    local f = menu.mini[i]
    if not f then
        f = ns.MakeDeckCard(menu.root)
        ns.DeckCardPaper(f)
        f.corner:SetJustifyH("CENTER")
        f.rank:SetPoint("CENTER", f, "CENTER", 0, 0)
        menu.mini[i] = f
    end
    return f
end
local function miniSlot(i)
    local f = menu.miniSlot[i]
    if not f then
        f = CreateFrame("Frame", nil, menu.root)
        f:SetFrameLevel(menu.root:GetFrameLevel() + 1)
        f:SetBackdrop(ns.CARD_BACKDROP)
        local sk = SLOT_TONE.plain
        f:SetBackdropColor(sk.bg[1], sk.bg[2], sk.bg[3], sk.bg[4])
        f:SetBackdropBorderColor(sk.edge[1], sk.edge[2], sk.edge[3], sk.edge[4])
        menu.miniSlot[i] = f
    end
    return f
end
local function layoutMini(f, scale)
    f:SetWidth(floor(CARD_W * scale))
    f:SetHeight(floor(CARD_H * scale))
end
local function paintMini(f, card, scale)
    ns.DeckCardRank(f.corner2, nil)
    ns.DeckCardSuit(f.mark2, nil, nil)
    if card.open then
        ns.DeckCardCover(f, false)
        ns.DeckCardFace(f, card.rank, card.suit, { icon = suitIcon[card.suit] })
    else
        ns.DeckCardRank(f.rank, nil)
        ns.DeckCardRank(f.corner, nil)
        ns.DeckCardSuit(f.mark, nil, nil)
        ns.DeckCardArt(f, nil)
        ns.DeckCardCover(f, true, backIcon, nil)
    end
end
local function syncMini(self)
    local md = ns.Patience.Get(self.mode)
    local cols, gap = md.cols, md.gap
    local tabW = cols * CARD_W + (cols - 1) * gap
    local tall = CARD_H
    for c = 1, cols do
        local pile = self.tableau[c] or {}
        local ext = CARD_H
        for i = 1, #pile - 1 do
            ext = ext + (pile[i].open and OFFSET_OPEN or OFFSET_CLOSED)
        end
        if ext > tall then tall = ext end
    end
    local tabH = CARD_H + ROW_GAP + tall
    local scale = MINI_W / tabW
    if MINI_H / tabH < scale then scale = MINI_H / tabH end
    if scale > MINI_MAX then scale = MINI_MAX end
    local cw, ch = floor(CARD_W * scale), floor(CARD_H * scale)
    local step = (CARD_W + gap) * scale
    local x0 = MINI_X + floor((MINI_W - (tabW * scale)) / 2)
    local tabY = MINI_TOP + ch + ROW_GAP * scale
    local used, slotN = 0, 0
    menu.miniOf = {}
    local miniBase = menu.root:GetFrameLevel() + 2
    local function put(card, x, y, level)
        used = used + 1
        local f = miniCard(used)
        menu.miniOf[card.id] = f
        ns.DeckCardLevel(f, miniBase + level)
        layoutMini(f, scale)
        paintMini(f, card, scale)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", menu.root, "TOPLEFT", x, -y)
        f:Show()
    end
    local function hole(x, y)
        slotN = slotN + 1
        local f = miniSlot(slotN)
        f:SetWidth(cw)
        f:SetHeight(ch)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", menu.root, "TOPLEFT", x, -y)
        f:Show()
    end
    local homes, cells = 0, 0
    for i = 1, cols do
        local kind = md.top[i]
        local x = x0 + (i - 1) * step
        if kind == "stock" then
            if #self.stock > 0 then put(self.stock[#self.stock], x, MINI_TOP, 2)
            else hole(x, MINI_TOP) end
        elseif kind == "waste" then
            if #self.waste > 0 then put(self.waste[#self.waste], x, MINI_TOP, 2)
            else hole(x, MINI_TOP) end
        elseif kind == "home" then
            homes = homes + 1
            local r = self.foundation and self.foundation[homes] or 0
            if r > 0 then put(self.deck[(homes - 1) * 13 + r], x, MINI_TOP, 2)
            else hole(x, MINI_TOP) end
        elseif kind == "cell" then
            cells = cells + 1
            local card = self.cells and self.cells[cells]
            if card then put(card, x, MINI_TOP, 2) else hole(x, MINI_TOP) end
        end
    end
    for c = 1, cols do
        local pile = self.tableau[c] or {}
        local x = x0 + (c - 1) * step
        local y = tabY
        for i = 1, #pile do
            put(pile[i], x, y, i * 2)
            y = y + (pile[i].open and OFFSET_OPEN or OFFSET_CLOSED) * scale
        end
    end
    for i = used + 1, #menu.mini do menu.mini[i]:Hide() end
    for i = slotN + 1, #menu.miniSlot do menu.miniSlot[i]:Hide() end
end
local function bestText(sec)
    if not sec then return ns.T("solitaire.menuNoBest") end
    local mm = floor(sec / 60)
    return ns.T("solitaire.menuBest", ("%d:%02d"):format(mm, floor(sec - mm * 60)))
end
local function syncMenu(self)
    local list = ns.Patience.List()
    local count = #list
    local w = floor((CANVAS_W - M_PAD * 2 - SLOT_GAP * (count - 1)) / count)
    local live = self:Started()
    menu.play:SetText(ns.T("solitaire.menuPlay"))
    if live then
        local x0 = floor((CANVAS_W - (PAIR_W * 2 + PAIR_GAP)) / 2)
        menu.play.tip = ns.T("solitaire.menuFreshTip")
        menu.play:SetWidth(PAIR_W)
        menu.play:ClearAllPoints()
        menu.play:SetPoint("TOPLEFT", menu.root, "TOPLEFT", x0, -PLAY_TOP)
        menu.resume:SetText(ns.T("solitaire.menuResume"))
        menu.resume.tip = ns.T("solitaire.menuResumeTip")
        menu.resume:SetWidth(PAIR_W)
        menu.resume:ClearAllPoints()
        menu.resume:SetPoint("TOPLEFT", menu.root, "TOPLEFT",
                             x0 + PAIR_W + PAIR_GAP, -PLAY_TOP)
        menu.resume:Show()
    else
        menu.play.tip = ns.T("solitaire.menuPlayTip")
        menu.play:SetWidth(PLAY_W)
        menu.play:ClearAllPoints()
        menu.play:SetPoint("TOPLEFT", menu.root, "TOPLEFT",
                           floor((CANVAS_W - PLAY_W) / 2), -PLAY_TOP)
        menu.resume:Hide()
    end
    for i = 1, MENU_MAX do
        local t = menu.tile[i]
        local it = list[i]
        if not it then t:Hide() else
            local md = ns.Patience.Get(it.key)
            local on = (it.key == self.mode)
            t:SetWidth(w)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", menu.root, "TOPLEFT",
                       M_PAD + (i - 1) * (w + SLOT_GAP), -SLOT_TOP)
            t:Tone(on)
            t.name:SetText(ns.TL(md.label))
            local c = on and C_GOLD or C_TEXT
            t.name:SetTextColor(c[1], c[2], c[3])
            c = on and C_SOFT or C_CAP
            t.line:SetWidth(w - 24)
            t.line:SetText(ns.TL(md.line))
            t.line:SetTextColor(c[1], c[2], c[3])
            local waits = live
            if not on then
                local rec = ns.Store.Load(ID, { mode = it.key })
                waits = (rec and rec.moves and #rec.moves > 0) and true or false
            end
            if waits then
                t.best:SetText(ns.T("solitaire.menuLive"))
                t.best:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
            else
                local best = ns.Records.Best(ID, { mode = it.key })
                t.best:SetText(bestText(best and best.time))
                t.best:SetTextColor(c[1], c[2], c[3])
            end
            t.foot:SetText(ns.T("solitaire.menuCols", md.cols))
            t.foot:SetTextColor(c[1], c[2], c[3])
            t.pick = it.key
            t:Show()
        end
    end
    syncMini(self)
end
local function paintCard(f, card, tone)
    local paper = PAPER_PLAIN
    if tone == "held" then paper = PAPER_HELD
    elseif tone == "dim" then paper = PAPER_DIM end
    ns.DeckCardPaper(f, paper[1], paper[2], paper[3])
    if card.open then
        local r, g, b = ns.DeckSuitInk(card.suit)
        if tone == "dim" then r, g, b = r * INK_DIM, g * INK_DIM, b * INK_DIM end
        ns.DeckCardCover(f, false)
        ns.DeckCardFace(f, card.rank, card.suit, { icon = suitIcon[card.suit], r = r, g = g, b = b })
        if tone == "dim" and suitIcon[card.suit] then
            f.mark:SetVertexColor(COVER_DIM, COVER_DIM, COVER_DIM)
            f.mark2:SetVertexColor(COVER_DIM, COVER_DIM, COVER_DIM)
        end
    else
        ns.DeckCardRank(f.rank, nil)
        ns.DeckCardRank(f.corner, nil)
        ns.DeckCardRank(f.corner2, nil)
        ns.DeckCardSuit(f.mark, nil, nil)
        ns.DeckCardSuit(f.mark2, nil, nil)
        f.coverTone = (tone == "dim") and COVER_DIM or 1
        ns.DeckCardCover(f, true, backIcon, nil)
    end
    if tone == "held" or tone == "go" then
        ns.DeckCardEdge(f, ns.Attn())
    else
        ns.DeckCardEdge(f, nil)
    end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
local function placeCard(card, x, y, level, tone)
    local f = cardF[card.id]
    paintCard(f, card, tone)
    ns.DeckCardLevel(f, cardLayer:GetFrameLevel() + level)
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", cardLayer, "BOTTOMLEFT", x,
               y + ((tone == "held") and HELD_LIFT or 0))
    f:Show()
end
local function mode(self)
    return ns.Patience.Get(self.mode)
end
local function canDrop(self, card, destCol)
    return mode(self).CanDrop(self, card, destCol) and true or false
end
local function canHome(self, card)
    if not card then return nil end
    return mode(self).Home(self, card)
end
local function tailValid(self, col, fi)
    return mode(self).TailOk(self, col, fi) and true or false
end
local function canLand(self, from, fi, cards, col)
    if from == col then return false end
    if not canDrop(self, cards[1], col) then return false end
    local m = mode(self)
    if type(from) == "number" and fi and m.TailFits
       and not m.TailFits(self, from, fi, col) then
        return false
    end
    return true
end
local function cellTakes(self, cards, from, i)
    if not cards or #cards ~= 1 then return false end
    if self.cells[i] then return false end
    if from == ("c" .. i) then return false end
    return type(from) == "number" or from == "w"
end
local function checkStuck(self)
    local movable = not mode(self).NoMoves(self)
    if movable then self.everMovable = true end
    local noCards = (#self.stock == 0 and #self.waste == 0)
    self.stuck = (not movable) and (self.deadlock or noCards)
end
local function maybeReveal(self, from)
    if type(from) ~= "number" then return end
    local pile = self.tableau[from]
    local n = #pile
    if n > 0 and not pile[n].open then
        pile[n].open = true
    end
end
local function whence(self, from)
    if from == "w" then return "waste" end
    local cell = type(from) == "string" and from:match("^c(%d+)$")
    if cell then return "cell", tonumber(cell) end
    local col = tonumber(from)
    if col and col >= 1 and col <= self.cols then return "col", col end
    return "none"
end
local function peek(self, from)
    local kind, i = whence(self, from)
    if kind == "waste" then return self.waste[#self.waste] end
    if kind == "cell" then return self.cells[i] end
    if kind == "col" then
        local pile = self.tableau[i]
        return pile[#pile]
    end
    return nil
end
local function takeTop(self, from)
    local kind, i = whence(self, from)
    if kind == "waste" then self.waste[#self.waste] = nil
    elseif kind == "cell" then self.cells[i] = nil
    elseif kind == "col" then
        local pile = self.tableau[i]
        pile[#pile] = nil
        maybeReveal(self, i)
    end
end
local function apply(self, move, silent)
    if self.over then return false end
    local m = mode(self)
    local k = move.k
    if k == "deal" then
        if not m.Stock then return false end
        if not m.Stock(self) then return false end
    elseif k == "mv" then
        local from, fi, to = move.from, move.fi, move.to
        to = tonumber(to)
        if not to or to < 1 or to > self.cols then return false end
        local kind, i = whence(self, from)
        local tail
        if kind == "col" then
            if i == to then return false end
            if not tailValid(self, i, fi) then return false end
            if m.TailFits and not m.TailFits(self, i, fi, to) then return false end
            local pile = self.tableau[i]
            tail = {}
            for p = fi, #pile do tail[#tail + 1] = pile[p] end
        else
            local card = peek(self, from)
            if not card then return false end
            tail = { card }
        end
        if not canDrop(self, tail[1], to) then return false end
        if kind == "col" then
            local pile = self.tableau[i]
            for p = #pile, fi, -1 do pile[p] = nil end
            maybeReveal(self, i)
        else
            takeTop(self, from)
        end
        local dest = self.tableau[to]
        for p = 1, #tail do dest[#dest + 1] = tail[p] end
        if not silent then ns.Sfx.Play("pop") end
    elseif k == "home" then
        local card = peek(self, move.from)
        if not card then return false end
        local home = canHome(self, card)
        if not home then return false end
        takeTop(self, move.from)
        self.foundation[home] = card.rank
        self.homeCount = self.homeCount + 1
        if m.Won(self) then
            self.won = true
            self.over = true
            if not silent then ns.Sfx.Play("clear") end
        elseif not silent then
            ns.Sfx.Play("big")
        end
    elseif k == "cell" then
        local slot = tonumber(move.to)
        if not slot or slot < 1 or slot > (m.cells or 0) then return false end
        if self.cells[slot] then return false end
        local card = peek(self, move.from)
        if not card then return false end
        local kind = whence(self, move.from)
        if kind ~= "col" and kind ~= "waste" then return false end
        takeTop(self, move.from)
        self.cells[slot] = card
        if not silent then ns.Sfx.Play("pop") end
    else
        return false
    end
    self.moves = (self.moves or 0) + 1
    checkStuck(self)
    return true
end
function Game:Start(seed, moves)
    local key = (self.opts and self.opts.mode) or ns.Patience.order[1]
    if not ns.Patience.modes[key] then key = ns.Patience.order[1] end
    self.opts = { mode = key }
    self.mode = key
    local m = ns.Patience.Get(key)
    self.cols = m.cols
    relayout(m)
    press, drag, lastTap = nil, nil, nil
    if dragHost then dragHost:Hide() end
    if ask then ask:Hide() end
    local rng = ns.RNG.New(seed)
    local pick = ns.RNG.New(seed)
    backIcon = ns.Shelves.Pick(DECK, "back", pick)
    for s = 1, 4 do suitIcon[s] = ns.Shelves.Pick(DECK, "s" .. s, pick) end
    self.deck = {}
    local order = {}
    local id = 0
    for s = 1, 4 do
        for r = 1, 13 do
            id = id + 1
            self.deck[id] = { id = id, suit = s, rank = r, open = false }
            order[id] = id
        end
    end
    rng:Shuffle(order)
    self.tableau = {}
    for c = 1, self.cols do self.tableau[c] = {} end
    self.stock = {}
    self.waste = {}
    self.cells = {}
    self.foundation = { 0, 0, 0, 0 }
    self.sel = nil
    self.homeCount, self.recycled, self.moves = 0, 0, 0
    self.everMovable, self.deadlock, self.stuck = false, false, false
    self.won, self.over = false, false
    self.endT = nil
    m.Deal(self, order)
    local best = ns.Records.Best(ID, { mode = key })
    if best and best.time then
        local mm = floor(best.time / 60)
        self.bestShown = ("%d:%02d"):format(mm, floor(best.time - mm * 60))
    else
        self.bestShown = nil
    end
    self.phase = (moves and #moves > 0) and "play" or "menu"
    if staying then self.phase = "menu" end
    staying = nil
    local rec = (moves and #moves > 0) and ns.Store.Load(ID, { mode = key }) or nil
    self.played = (rec and tonumber(rec.elapsed)) or 0
    if moves then
        for i = 1, #moves do apply(self, moves[i], true) end
    end
    checkStuck(self)
    ensureView(self.canvas)
    placeSlots(self.canvas, m)
    banner:ClearAllPoints()
    banner:SetPoint("CENTER", self.canvas, "BOTTOM", 0,
        L.tabTopY + CARD_H + ROW_GAP / 2)
    felt:Show()
    board:Show()
    cardLayer:Show()
    self:Draw()
end
function Game:Move(move)
    if not apply(self, move, false) then return false end
    self.sel = nil
    self:Draw()
    return true
end
function Game:Pick(key)
    if self.phase ~= "menu" then return end
    if ns.Loop.Current() ~= self then return end
    if not ns.Patience.modes[key] then return end
    if key == self.mode then return end
    ns.window:SaveCurrent()
    staying = true
    ns.window:StartGame(ID, { mode = key }, true)
end
function Game:Fresh()
    if self.phase ~= "menu" then return end
    if ns.Loop.Current() ~= self then return end
    local key = self.mode
    ns.Store.Clear(ID, { mode = key })
    ns.window:StartGame(ID, { mode = key })
    local g = ns.Loop.Current()
    if g and g ~= self and g.BeginRound then g:BeginRound() end
end
function Game:AskFresh()
    ask = ask or ns.MakeCard{ name = "RaidWaitingArcadeSolitaireAsk", escape = true,
                              dismiss = true, level = ASK_LEVEL, look = LOOK }
    local me = self
    ask:Show(self.canvas,
        ns.T("solitaire.askTitle"),
        { ns.T("solitaire.askBody", ns.TL(ns.Patience.Get(self.mode).label)) },
        {
            { label = ns.T("solitaire.askGo"), tip = ns.T("solitaire.askGoTip"),
              onClick = function() ask:Hide(); me:Fresh() end },
            { label = ns.T("solitaire.askStay"),
              onClick = function() ask:Hide() end },
        })
end
function Game:ToMenu()
    if self.phase ~= "play" then return end
    if self.over then return end
    if ns.Loop.Current() ~= self then return end
    if ns.Anim then ns.Anim.StopAll() end
    self.phase = "menu"
    self.sel = nil
    press, drag, lastTap = nil, nil, nil
    if dragHost then dragHost:Hide() end
    ns.window:SaveCurrent()
    self:Draw()
end
function Game:BeginRound()
    if self.phase ~= "menu" then return end
    if ns.Loop.Current() ~= self then return end
    if ns.Anim then ns.Anim.Stop(menu.root) end
    local came = {}
    if ns.Anim and menu.miniOf then
        for id, f in pairs(menu.miniOf) do
            local x, y = f:GetCenter()
            if x and y then came[id] = { x, y } end
        end
    end
    self.phase = "play"
    self:Draw()
    if not ns.Anim then return end
    for id, at in pairs(came) do
        local f = cardF[id]
        if f and f:IsShown() then
            local cx, cy = f:GetCenter()
            if cx and cy then
                ns.Anim.Slide(f, at[1] - cx, at[2] - cy, GROW_TIME)
            end
        end
    end
end
function Game:PlayTime()
    return self.played or 0
end
function Game:Started()
    return (self.moves or 0) > 0
end
function Game:ColumnY(col)
    local pile = self.tableau[col]
    local n = #pile
    local ys = {}
    if n == 0 then return ys end
    ys[1] = L.tabTopY
    if n == 1 then return ys end
    local nominal = CARD_H
    local offs = {}
    for p = 1, n - 1 do
        offs[p] = pile[p].open and OFFSET_OPEN or OFFSET_CLOSED
        nominal = nominal + offs[p]
    end
    local shrink = 1
    if nominal > L.avail then
        local budget = L.avail - CARD_H
        if budget < 0 then budget = 0 end
        shrink = budget / (nominal - CARD_H)
    end
    local floorOff = MIN_OFFSET
    local room = (L.avail - CARD_H) / (n - 1)
    if room < floorOff then floorOff = room end
    local y = L.tabTopY
    for p = 2, n do
        local o = offs[p - 1] * shrink
        if o < floorOff then o = floorOff end
        y = y - o
        ys[p] = y
    end
    return ys
end
function Game:SelCards()
    local sel = self.sel
    if not sel then return nil end
    if sel.from == "w" then
        local n = #self.waste
        if n == 0 then return nil end
        return { self.waste[n] }
    end
    local cell = type(sel.from) == "string" and sel.from:match("^c(%d+)$")
    if cell then
        local card = self.cells[tonumber(cell)]
        return card and { card } or nil
    end
    local pile = self.tableau[sel.from]
    if not pile or not tailValid(self, sel.from, sel.fi) then return nil end
    local out = {}
    for i = sel.fi, #pile do out[#out + 1] = pile[i] end
    return out
end
function Game:HitTest(x, y)
    if x < 0 or y < 0 or x > CANVAS_W or y > CANVAS_H then return nil end
    if y >= L.topY and y <= L.topY + CARD_H then
        local function over(cx)
            return cx ~= nil and x >= cx and x <= cx + CARD_W
        end
        if over(L.zone.stock) then return { zone = "stock" } end
        if over(L.zone.waste) then return { zone = "waste" } end
        for i = 1, L.homeN do
            if over(L.zone.home[i]) then return { zone = "foundation", i = i } end
        end
        for i = 1, L.cellN do
            if over(L.zone.cell[i]) then return { zone = "cell", i = i } end
        end
        return nil
    end
    for c = 1, L.cols do
        local cx = L.colx[c]
        if x >= cx and x <= cx + CARD_W then
            local pile = self.tableau[c]
            local n = #pile
            if n == 0 then
                if y >= L.tabTopY and y <= L.tabTopY + CARD_H then
                    return { zone = "tableau", c = c, card = 0 }
                end
                return nil
            end
            local ys = self:ColumnY(c)
            for p = n, 1, -1 do
                if y >= ys[p] and y <= ys[p] + CARD_H then
                    return { zone = "tableau", c = c, card = p }
                end
            end
            return nil
        end
    end
    return nil
end
local DRAG_MIN = 5
local DRAG_LIFT = 60
local DROP_MIN = 0.12
local DOUBLE_TAP = 0.4
local FLY_TIME = 0.22
local FLIP_TIME = 0.16
local function cursorXY()
    if not cardLayer or not cardLayer:GetLeft() then return nil end
    local s = cardLayer:GetEffectiveScale()
    if not s or s == 0 then return nil end
    local x, y = GetCursorPosition()
    return x / s - cardLayer:GetLeft(), y / s - cardLayer:GetBottom()
end
local function srcKey(t)
    if not t then return nil end
    if t.zone == "waste" then return "w" end
    if t.zone == "cell" then return "c" .. t.i end
    return t.c
end
local function heldCards(self, t)
    if not t then return nil end
    if t.zone == "waste" then
        local n = #self.waste
        return (n > 0) and { self.waste[n] } or nil
    end
    if t.zone == "cell" then
        local card = self.cells[t.i]
        return card and { card } or nil
    end
    if t.zone ~= "tableau" or not t.card or t.card == 0 then return nil end
    local pile = self.tableau[t.c]
    local card = pile[t.card]
    if not card or not card.open then return nil end
    if not tailValid(self, t.c, t.card) then return nil end
    local out = {}
    for i = t.card, #pile do out[#out + 1] = pile[i] end
    return out
end
local function moveHeld(x, y)
    local cards = press.cards
    local bx, by = x - drag.dx, y - drag.dy
    local step = drag.step or OFFSET_OPEN
    for i = 1, #cards do
        local f = cardF[cards[i].id]
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", cardLayer, "BOTTOMLEFT", bx, by - (i - 1) * step)
    end
end
local function beginDrag(g)
    local t = press.target
    local ox, oy
    if t.zone == "waste" then
        ox, oy = L.zone.waste, L.topY
    elseif t.zone == "cell" then
        ox, oy = L.zone.cell[t.i], L.topY
    else
        ox, oy = L.colx[t.c], g:ColumnY(t.c)[t.card]
    end
    local step = OFFSET_OPEN
    if t.zone == "tableau" and t.card then
        local ys = g:ColumnY(t.c)
        if ys[t.card] and ys[t.card + 1] then step = ys[t.card] - ys[t.card + 1] end
    end
    drag = { dx = press.x - ox, dy = press.y - oy, step = step }
    g:Draw()
    local base = cardLayer:GetFrameLevel() + DRAG_LIFT
    for i = 1, #press.cards do
        local f = cardF[press.cards[i].id]
        ns.DeckCardLevel(f, base + i * 2)
        f:Show()
    end
    ns.Sfx.Play("pick")
end
function Game:Click(x, y, button)
    if self.over then return end
    if self.phase == "menu" then return end
    if button ~= "LeftButton" then return end
    local t = self:HitTest(x, y)
    press = { g = self, x = x, y = y, target = t, cards = heldCards(self, t) }
    drag = nil
    if dragHost then dragHost:Show() end
end
function Game:Release(x, y, button)
    if button and button ~= "LeftButton" then return end
    self:DropAt(x, y)
end
local function cover(ax, ay, bx, by, bh)
    local ox = min(ax + CARD_W, bx + CARD_W) - max(ax, bx)
    local oy = min(ay + CARD_H, by + bh) - max(ay, by)
    if ox <= 0 or oy <= 0 then return 0 end
    return (ox * oy) / (CARD_W * CARD_H)
end
local function bestDrop(self, cards, hx, hy, from, fi)
    local best, area = nil, DROP_MIN
    local function offer(t, bx, by, bh)
        local a = cover(hx, hy, bx, by, bh)
        if a > area then area, best = a, t end
    end
    for c = 1, L.cols do
        local pile = self.tableau[c]
        local low = (#pile > 0) and self:ColumnY(c)[#pile] or L.tabTopY
        local h = L.tabTopY + CARD_H - low
        if c == from then
            offer({ zone = "self" }, L.colx[c], low, h)
        elseif canLand(self, from, fi, cards, c) then
            offer({ zone = "tableau", c = c }, L.colx[c], low, h)
        end
    end
    if from == "w" and L.zone.waste then
        offer({ zone = "self" }, L.zone.waste, L.topY, CARD_H)
    end
    local own = type(from) == "string" and tonumber(from:match("^c(%d+)$"))
    if own and L.zone.cell[own] then
        offer({ zone = "self" }, L.zone.cell[own], L.topY, CARD_H)
    end
    if #cards == 1 then
        local home = canHome(self, cards[1])
        if home and L.zone.home[home] then
            offer({ zone = "foundation", i = home }, L.zone.home[home], L.topY, CARD_H)
        end
        for i = 1, L.cellN do
            if cellTakes(self, cards, from, i) then
                offer({ zone = "cell", i = i }, L.zone.cell[i], L.topY, CARD_H)
            end
        end
    end
    return best
end
function Game:DropAt(x, y)
    local p, d = press, drag
    press, drag = nil, nil
    if dragHost then dragHost:Hide() end
    if not p then return end
    if self.over then self:Draw(); return end
    if not d then self:Tap(p.x, p.y); return end
    local src = p.target
    local from = srcKey(src)
    local fi = (src.zone == "tableau") and src.card or nil
    local to = bestDrop(self, p.cards, x - d.dx, y - d.dy, from, fi)
    if to and to.zone ~= "self" then
        local done = false
        if to.zone == "foundation" then
            done = self:Move{ k = "home", from = from }
        elseif to.zone == "cell" then
            done = self:Move{ k = "cell", from = from, to = to.i }
        elseif to.zone == "tableau" then
            done = self:Move{ k = "mv", from = from, fi = fi, to = to.c }
        end
        if done then return end
    end
    if not to then
        local at = self:HitTest(x, y)
        if at and ((at.zone == "tableau" and at.c ~= from)
                   or at.zone == "foundation" or at.zone == "cell") then
            ns.Sfx.Play("deny")
        end
    end
    self.sel = nil
    self:Draw()
end
dragTick = function()
    local p = press
    if not p then
        if dragHost then dragHost:Hide() end
        return
    end
    local x, y = cursorXY()
    if not x then return end
    if not drag and p.cards
       and (abs(x - p.x) >= DRAG_MIN or abs(y - p.y) >= DRAG_MIN) then
        beginDrag(p.g)
    end
    if drag then moveHeld(x, y) end
    if not IsMouseButtonDown("LeftButton") then p.g:DropAt(x, y) end
end
local function homeSource(self, target)
    if target.zone == "waste" then
        return (#self.waste > 0) and "w" or nil
    end
    if target.zone == "cell" then
        return self.cells[target.i] and ("c" .. target.i) or nil
    end
    if target.zone == "tableau" then
        local pile = self.tableau[target.c]
        if #pile > 0 and target.card == #pile then return target.c end
    end
    return nil
end
local function flyFrom(card, x0, y0, dur)
    if not ns.Anim or not x0 or not y0 then return end
    local f = cardF[card.id]
    local x1, y1 = f:GetCenter()
    if not x1 or not y1 then return end
    local base = cardLayer:GetFrameLevel()
    ns.DeckCardLevel(f, base + DRAG_LIFT)
    ns.Anim.Slide(f, x0 - x1, y0 - y1, dur, function()
        ns.DeckCardLevel(f, base + 1)
    end)
end
local function centerOf(card)
    if not card then return nil end
    local f = cardF[card.id]
    if not f:IsShown() then return nil end
    return f:GetCenter()
end
function Game:DealFromStock()
    local top = self.stock[#self.stock]
    local x0, y0 = centerOf(top)
    if not self:Move{ k = "deal" } then return false end
    if top and self.waste[#self.waste] == top then
        flyFrom(top, x0, y0, FLIP_TIME)
    end
    return true
end
function Game:SendHome(from)
    local card = peek(self, from)
    if not canHome(self, card) then return false end
    local x0, y0 = centerOf(card)
    self.sel = nil
    if not self:Move{ k = "home", from = from } then return false end
    flyFrom(card, x0, y0, FLY_TIME)
    return true
end
function Game:Tap(x, y)
    local target = self:HitTest(x, y)
    if not target then return end
    local now = GetTime()
    local twice = lastTap ~= nil
        and (now - lastTap.t) <= DOUBLE_TAP
        and lastTap.zone == target.zone
        and lastTap.c == target.c
        and lastTap.card == target.card
        and lastTap.i == target.i
    lastTap = { t = now, zone = target.zone, c = target.c,
                card = target.card, i = target.i }
    if twice then
        local from = homeSource(self, target)
        if from then
            lastTap = nil
            if self:SendHome(from) then return end
            ns.Sfx.Play("deny")
            return
        end
    end
    if target.zone == "stock" then
        if #self.stock == 0 and #self.waste == 0 then
            ns.Sfx.Play("deny")
            return
        end
        self.sel = nil
        self:DealFromStock()
        return
    end
    if target.zone == "cell" and self.sel and not self.cells[target.i] then
        local cards = self:SelCards()
        if cellTakes(self, cards, self.sel.from, target.i) then
            self:Move{ k = "cell", from = self.sel.from, to = target.i }
            return
        end
        ns.Sfx.Play("deny")
        return
    end
    local hadSel = self.sel ~= nil
    if self.sel then
        if target.zone == "foundation" then
            local cards = self:SelCards()
            if cards and #cards == 1 and canHome(self, cards[1]) == target.i then
                self:Move{ k = "home", from = self.sel.from }
                return
            end
            ns.Sfx.Play("deny")
            return
        elseif target.zone == "tableau" and self.sel.from ~= target.c then
            local cards = self:SelCards()
            if cards and canLand(self, self.sel.from, self.sel.fi, cards, target.c) then
                self:Move{ k = "mv", from = self.sel.from, fi = self.sel.fi, to = target.c }
                return
            end
        end
        if target.zone == "waste" and self.sel.from == "w" then
            self.sel = nil
            self:Draw()
            return
        end
        if target.zone == "tableau" and self.sel.from == target.c
           and target.card == self.sel.fi then
            self.sel = nil
            self:Draw()
            return
        end
    end
    if target.zone == "waste" then
        if #self.waste > 0 then
            self.sel = { from = "w" }
            ns.Sfx.Play("pick")
            self:Draw()
        elseif hadSel then
            ns.Sfx.Play("deny")
        end
        return
    end
    if target.zone == "cell" then
        local key = "c" .. target.i
        if self.sel and self.sel.from == key then
            self.sel = nil
            self:Draw()
        elseif self.cells[target.i] then
            self.sel = { from = key }
            ns.Sfx.Play("pick")
            self:Draw()
        elseif hadSel then
            ns.Sfx.Play("deny")
        end
        return
    end
    if target.zone == "tableau" and target.card and target.card > 0 then
        local card = self.tableau[target.c][target.card]
        if card.open and tailValid(self, target.c, target.card) then
            self.sel = { from = target.c, fi = target.card }
            ns.Sfx.Play("pick")
            self:Draw()
        elseif hadSel then
            ns.Sfx.Play("deny")
        end
        return
    end
    if hadSel and target.zone == "tableau" then
        ns.Sfx.Play("deny")
    end
end
function Game:Update(dt)
    if self.phase == "menu" then return end
    if self.over then
        self.endT = (self.endT or 0) + dt
    else
        self.played = (self.played or 0) + dt
    end
end
function Game:PanelSync()
    if not niche then return end
    if self.phase == "menu" then
        niche:Hide()
        exit:Hide()
        return
    end
    niche:Show()
    exit:Show()
    exit:SetText(ns.T("solitaire.toMenu"))
    exit.tip = ns.T("solitaire.toMenuTip")
    if self.over then exit:Disable() else exit:Enable() end
    for _, g in ipairs(NICHE_GROUP) do
        nicheCap[g.key]:SetText(ns.T(g.cap))
    end
    local paused = ns.Loop.IsPaused()
    local sec = floor(self:PlayTime())
    nicheVal.clock:SetText(("%d:%02d"):format(floor(sec / 60), sec % 60))
    if paused then
        nicheVal.clock:SetTextColor(0.5, 0.5, 0.5)
    else
        nicheVal.clock:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
    end
    nicheVal.moves:SetText(tostring(self.moves or 0))
    nicheVal.moves:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    nicheVal.best:SetText(self.bestShown or ns.T("solitaire.menuDash"))
    nicheVal.best:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
end
function Game:Score()
    return 0
end
function Game:Clock()
    if self.phase == "menu" then return "", false end
    local s = floor(self:PlayTime())
    return ("%d:%02d"):format(floor(s / 60), s % 60), false
end
function Game:Marks()
    return { time = floor(self:PlayTime()) }
end
function Game:Ranked()
    return self.won and true or false
end
function Game:IsOver()
    if not self.won then return false end
    return (self.endT or 0) >= END_FLASH
end
function Game:Stop()
    if ns.Anim then ns.Anim.StopAll() end
    if ask then ask:Hide() end
    if niche then niche:Hide() end
    if exit then exit:Hide() end
    if felt then felt:Hide() end
    if menu then menu.root:Hide() end
    for i = 1, #slots do slots[i]:Hide() end
    if board then board:Hide() end
    if cardLayer then cardLayer:Hide() end
    if cardF then
        for id = 1, 52 do cardF[id]:Hide() end
    end
    if banner then banner:Hide() end
    self.sel = nil
    press, drag, lastTap = nil, nil, nil
    if dragHost then dragHost:Hide() end
end
local function heldNow(self)
    if drag and press and press.cards then
        local src = press.target
        return press.cards, srcKey(src), (src.zone == "tableau") and src.card or nil
    end
    if self.sel then return self:SelCards(), self.sel.from, self.sel.fi end
    return nil
end
function Game:Draw()
    for id = 1, 52 do cardF[id]:Hide() end
    local held, from, fi = heldNow(self)
    local function target(ok)
        if not held then return nil end
        return ok and "go" or "dim"
    end
    if L.zone.stock and #self.stock > 0 then
        placeCard(self.stock[#self.stock], L.zone.stock, L.topY, 1, nil)
    end
    if L.zone.waste and #self.waste > 0 then
        local c = self.waste[#self.waste]
        placeCard(c, L.zone.waste, L.topY, 1, (from == "w") and "held" or nil)
    end
    local homeOf = held and #held == 1 and canHome(self, held[1]) or nil
    for i = 1, L.homeN do
        local tone = target(homeOf == i)
        if slotAt.home[i] then toneSlot(slotAt.home[i], tone) end
        local r = self.foundation[i]
        if r > 0 then
            placeCard(self.deck[(i - 1) * 13 + r], L.zone.home[i], L.topY, 1, tone)
        end
    end
    for i = 1, L.cellN do
        local card = self.cells[i]
        local mine = (from == ("c" .. i))
        local tone
        if mine then tone = "held"
        else tone = target(cellTakes(self, held, from, i)) end
        if slotAt.cell[i] then
            if mine then toneSlot(slotAt.cell[i], nil) else toneSlot(slotAt.cell[i], tone) end
        end
        if card then placeCard(card, L.zone.cell[i], L.topY, 1, tone) end
    end
    for c = 1, L.cols do
        local pile = self.tableau[c]
        local ys = self:ColumnY(c)
        local heldFrom = (from == c) and fi or nil
        local tone
        if not heldFrom then
            tone = target(held and canLand(self, from, fi, held, c))
        end
        if slotAt.col[c] then toneSlot(slotAt.col[c], tone) end
        for p = 1, #pile do
            local t
            if heldFrom ~= nil and p >= heldFrom then t = "held"
            elseif tone == "dim" then t = "dim"
            elseif tone == "go" and p == #pile then t = "go"
            end
            placeCard(pile[p], L.colx[c], ys[p], p * 2, t)
        end
    end
    if self.phase == "menu" then
        if ns.Anim then ns.Anim.Stop(menu.root) end
        syncMenu(self)
        menu.root:Show()
        menu.root:SetAlpha(1)
        banner:Hide()
        return
    end
    if ns.Anim then
        ns.Anim.Leave(menu.root, 0, CANVAS_H, LIFT_TIME)
    else
        menu.root:Hide()
    end
    if self.won then
        banner:SetText(ns.T("solitaire.bannerWon"))
        banner:SetTextColor(0.35, 1, 0.45)
        banner:Show()
    elseif self.stuck then
        banner:SetText(ns.T("solitaire.bannerStuck"))
        banner:SetTextColor(1, 0.82, 0)
        banner:Show()
    else
        banner:Hide()
    end
end
local function helpArt(host)
    local sw, gap = 26, 8
    local total = sw * 4 + gap * 3
    local x0 = floor((host:GetWidth() - total) / 2)
    for i = 1, 4 do
        local x = x0 + (i - 1) * (sw + gap)
        local paper = host:CreateTexture(nil, "BACKGROUND")
        paper:SetWidth(sw)
        paper:SetHeight(sw)
        paper:SetPoint("TOPLEFT", host, "TOPLEFT", x, -4)
        local p = ns.DECK_PAPER
        paper:SetTexture(p[1], p[2], p[3], 1)
        local t = host:CreateTexture(nil, "ARTWORK")
        t:SetWidth(sw - 8)
        t:SetHeight(sw - 8)
        t:SetPoint("CENTER", paper, "CENTER", 0, 0)
        ns.DeckCardSuit(t, nil, i, ns.DeckSuitInk(i))
    end
    local red = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    red:SetPoint("TOPLEFT", host, "TOPLEFT", x0, -4 - sw - 4)
    red:SetText(ns.T("solitaire.helpRed"))
    local black = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    black:SetPoint("TOPLEFT", host, "TOPLEFT", x0 + 2 * (sw + gap), -4 - sw - 4)
    black:SetText(ns.T("solitaire.helpBlack"))
end
local MINI_TABLE = { WOOD[1], WOOD[2], WOOD[3], 1 }
local MINI_SLOT  = { WOOD[1] * 0.5, WOOD[2] * 0.5, WOOD[3] * 0.5, 1 }
local MINI_UP    = { 0.96, 0.94, 0.88, 1 }
local MINI_DOWN  = { 0.24, 0.32, 0.50, 1 }
local MINI = {
    klondike = {
        cols = 7, rows = 5, cell = 20, gap = 2, back = "plain", face = MINI_TABLE,
        fill = {
            { c = 1, r = 5, col = MINI_DOWN }, { c = 2, r = 5, col = MINI_UP },
            { c = 4, r = 5, col = MINI_SLOT }, { c = 5, r = 5, col = MINI_SLOT },
            { c = 6, r = 5, col = MINI_SLOT }, { c = 7, r = 5, col = MINI_SLOT },
            { c = 1, r = 4, col = MINI_UP },
            { c = 2, r = 4, col = MINI_DOWN }, { c = 2, r = 3, col = MINI_UP },
            { c = 3, r = 4, col = MINI_DOWN }, { c = 3, r = 3, col = MINI_DOWN },
            { c = 3, r = 2, col = MINI_UP },
            { c = 4, r = 4, col = MINI_DOWN }, { c = 4, r = 3, col = MINI_DOWN },
            { c = 4, r = 2, col = MINI_DOWN }, { c = 4, r = 1, col = MINI_UP },
            { c = 5, r = 4, col = MINI_DOWN }, { c = 5, r = 3, col = MINI_DOWN },
            { c = 5, r = 2, col = MINI_DOWN }, { c = 5, r = 1, col = MINI_UP },
            { c = 6, r = 4, col = MINI_DOWN }, { c = 6, r = 3, col = MINI_DOWN },
            { c = 6, r = 2, col = MINI_DOWN }, { c = 6, r = 1, col = MINI_UP },
            { c = 7, r = 4, col = MINI_DOWN }, { c = 7, r = 3, col = MINI_DOWN },
            { c = 7, r = 2, col = MINI_DOWN }, { c = 7, r = 1, col = MINI_UP },
        },
        ring = { { c = 4, r = 5 }, { c = 5, r = 5 }, { c = 6, r = 5 }, { c = 7, r = 5 } },
    },
    freecell = {
        cols = 8, rows = 5, cell = 18, gap = 2, back = "plain", face = MINI_TABLE,
        fill = {
            { c = 1, r = 5, col = MINI_SLOT }, { c = 2, r = 5, col = MINI_SLOT },
            { c = 3, r = 5, col = MINI_SLOT }, { c = 4, r = 5, col = MINI_SLOT },
            { c = 5, r = 5, col = MINI_SLOT }, { c = 6, r = 5, col = MINI_SLOT },
            { c = 7, r = 5, col = MINI_SLOT }, { c = 8, r = 5, col = MINI_SLOT },
            { c = 1, r = 4, col = MINI_UP }, { c = 2, r = 4, col = MINI_UP },
            { c = 3, r = 4, col = MINI_UP }, { c = 4, r = 4, col = MINI_UP },
            { c = 5, r = 4, col = MINI_UP }, { c = 6, r = 4, col = MINI_UP },
            { c = 7, r = 4, col = MINI_UP }, { c = 8, r = 4, col = MINI_UP },
            { c = 1, r = 3, col = MINI_UP }, { c = 2, r = 3, col = MINI_UP },
            { c = 3, r = 3, col = MINI_UP }, { c = 4, r = 3, col = MINI_UP },
            { c = 5, r = 3, col = MINI_UP }, { c = 6, r = 3, col = MINI_UP },
            { c = 7, r = 3, col = MINI_UP }, { c = 8, r = 3, col = MINI_UP },
            { c = 1, r = 2, col = MINI_UP }, { c = 2, r = 2, col = MINI_UP },
            { c = 3, r = 2, col = MINI_UP }, { c = 4, r = 2, col = MINI_UP },
            { c = 5, r = 2, col = MINI_UP }, { c = 6, r = 2, col = MINI_UP },
            { c = 7, r = 2, col = MINI_UP }, { c = 8, r = 2, col = MINI_UP },
            { c = 1, r = 1, col = MINI_UP }, { c = 2, r = 1, col = MINI_UP },
            { c = 3, r = 1, col = MINI_UP }, { c = 4, r = 1, col = MINI_UP },
        },
        ring = { { c = 5, r = 5 }, { c = 6, r = 5 }, { c = 7, r = 5 }, { c = 8, r = 5 } },
    },
    yukon = {
        cols = 7, rows = 5, cell = 20, gap = 2, back = "plain", face = MINI_TABLE,
        fill = {
            { c = 4, r = 5, col = MINI_SLOT }, { c = 5, r = 5, col = MINI_SLOT },
            { c = 6, r = 5, col = MINI_SLOT }, { c = 7, r = 5, col = MINI_SLOT },
            { c = 1, r = 4, col = MINI_UP },
            { c = 2, r = 4, col = MINI_DOWN }, { c = 2, r = 3, col = MINI_UP },
            { c = 2, r = 2, col = MINI_UP }, { c = 2, r = 1, col = MINI_UP },
            { c = 3, r = 4, col = MINI_DOWN }, { c = 3, r = 3, col = MINI_UP },
            { c = 3, r = 2, col = MINI_UP }, { c = 3, r = 1, col = MINI_UP },
            { c = 4, r = 4, col = MINI_DOWN }, { c = 4, r = 3, col = MINI_UP },
            { c = 4, r = 2, col = MINI_UP }, { c = 4, r = 1, col = MINI_UP },
            { c = 5, r = 4, col = MINI_DOWN }, { c = 5, r = 3, col = MINI_UP },
            { c = 5, r = 2, col = MINI_UP }, { c = 5, r = 1, col = MINI_UP },
            { c = 6, r = 4, col = MINI_DOWN }, { c = 6, r = 3, col = MINI_UP },
            { c = 6, r = 2, col = MINI_UP }, { c = 6, r = 1, col = MINI_UP },
            { c = 7, r = 4, col = MINI_DOWN }, { c = 7, r = 3, col = MINI_UP },
            { c = 7, r = 2, col = MINI_UP }, { c = 7, r = 1, col = MINI_UP },
        },
        ring = { { c = 4, r = 5 }, { c = 5, r = 5 }, { c = 6, r = 5 }, { c = 7, r = 5 } },
    },
}
local function paintTable(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_TABLE)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r, 0.55) end
end
local tableArt = {}
for key, spec in pairs(MINI) do
    tableArt[key] = function(host) paintTable(host, spec) end
end
local ICON_TABLE = WOOD
local ICON_BACK = { 0.24, 0.32, 0.50 }
local ICON_SUIT = 1
local function iconFill(host, n, layer, x, y, w, h, c)
    local t = ns.ArtFill(host, n, layer)
    t:SetTexture(c[1], c[2], c[3], 1)
    t:SetWidth(w); t:SetHeight(h)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
end
local function iconCard(host, n, layer, x, y, w, h, fill)
    local rim = ns.DECK_EDGE
    iconFill(host, n, layer, x, y, w, h, fill)
    iconFill(host, n + 1, layer, x, y, w, 1, rim)
    iconFill(host, n + 2, layer, x, y + h - 1, w, 1, rim)
    iconFill(host, n + 3, layer, x, y, 1, h, rim)
    iconFill(host, n + 4, layer, x + w - 1, y, 1, h, rim)
end
local function SolitaireTileIcon(host, size)
    local m = floor(size * 0.09 + 0.5)
    local cw, ch = floor(size * 0.56 + 0.5), floor(size * 0.72 + 0.5)
    local ox, oy = size - m - cw, size - m - ch
    iconFill(host, 1, "BACKGROUND", 0, 0, size, size, ICON_TABLE)
    iconCard(host, 2, "BORDER", m, m, cw, ch, ICON_BACK)
    iconCard(host, 7, "ARTWORK", ox, oy, cw, ch, ns.DECK_PAPER)
    local fs = ns.ArtText(host, 1)
    local r, g, b = ns.DeckSuitInk(ICON_SUIT)
    ns.DeckCardRank(fs, floor(ch * 0.62 + 0.5), ns.DeckRankLabel(1), r, g, b, "")
    fs:SetWidth(cw); fs:SetHeight(ch)
    fs:SetJustifyH("CENTER"); fs:SetJustifyV("MIDDLE")
    fs:SetPoint("TOPLEFT", host, "TOPLEFT", ox, -oy)
end
ns.RegisterGame{
    id = ID,
    label = "solitaire.label",
    icon = { draw = SolitaireTileIcon },
    tip = "solitaire.tip",
    order = 10,
    duo = "none",
    look = LOOK,
    physics = false,
    ownPanel = true,
    done = true,
    deck = true,
    saves = "mode",
    record = {
        { key = "time", label = "solitaire.time", by = "min",
          mark = "clock", format = "span" },
        note = "solitaire.recNote",
    },
    opts = {
        { key = "mode", label = "solitaire.modeAxis", def = "klondike",
          thin = true, options = ns.Patience.List() },
    },
    controls = {
        { action = "drag",   label = "solitaire.ctlDrag",   mouse = "DRAG" },
        { action = "deal",   label = "solitaire.ctlDeal",   mouse = "LMB",
          where = "solitaire.ctlOnStock" },
        { action = "select", label = "solitaire.ctlSelect", mouse = "LMB",
          where = "solitaire.ctlOnCard" },
        { action = "move",   label = "solitaire.ctlMove",   mouse = "LMB",
          where = "solitaire.ctlOnTarget" },
        { action = "home",   label = "solitaire.ctlHome",   mouse = "DOUBLE",
          where = "solitaire.ctlOnTop" },
    },
    help = function(opts)
        local key = (type(opts) == "table" and opts.mode) or "klondike"
        if not ns.Patience.modes[key] then key = "klondike" end
        local out = { ns.T("solitaire." .. key .. "Help1") }
        out[#out + 1] = { art = tableArt[key], h = 122,
                          sub = ns.T("solitaire." .. key .. "TableSub") }
        out[#out + 1] = { t = ns.T("solitaire.help2") }
        out[#out + 1] = { art = helpArt, h = 40, sub = ns.T("solitaire.help2Sub") }
        out[#out + 1] = { t = ns.T("solitaire." .. key .. "Help2") }
        out[#out + 1] = { t = ns.T("solitaire.help3") }
        out[#out + 1] = { t = ns.T("solitaire.help4") }
        out[#out + 1] = { t = ns.T("solitaire.help5") }
        if key == "klondike" then
            out[#out + 1] = { t = ns.T("solitaire.help6") }
            out[#out + 1] = { t = ns.T("solitaire.help6Sub") }
        end
        out[#out + 1] = ns.T("solitaire." .. key .. "Help7")
        return out
    end,
    New = New,
}
