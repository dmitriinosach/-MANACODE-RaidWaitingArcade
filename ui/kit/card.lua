local ADDON, ns = ...
local WIDTH = 380
local ICON = 18
local DIM_A = 0.72
local GAP = 9
local HEAD = 39
local FOOT = 40
local MIN_H = 200
local STEP = 28
local BAR_W = 4
local Card = {}
Card.__index = Card
function ns.MakeCard(spec)
    return setmetatable({ spec = spec or {}, lines = {} }, Card)
end
function Card:Look()
    local l = self.spec.look
    if type(l) == "function" then
        return l()
    end
    return l
end
function Card:Ensure(host)
    local sp = self.spec
    if not self.overlay then
        self.overlay = CreateFrame("Frame", sp.name, host)
        self.overlay:EnableMouse(true)
        self.overlay:Hide()
        if sp.name and sp.escape then
            tinsert(UISpecialFrames, sp.name)
        end
        self.dim = self.overlay:CreateTexture(nil, "BACKGROUND")
        self.dim:SetAllPoints()
        self.dim:SetTexture(0, 0, 0, DIM_A)
        self.card = CreateFrame("Frame", nil, self.overlay)
        self.card:SetWidth(sp.width or WIDTH)
        self.card:SetPoint("CENTER", self.overlay, "CENTER", 0, 0)
        ns.DressCard(self.card, self:Look())
        self.title = ns.TitleText(self.card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
        self.title:SetPoint("TOPLEFT", self.card, "TOPLEFT", 12, -11)
        self.title:SetJustifyH("LEFT")
        self.note = ns.TitleText(self.card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        self.note:SetPoint("TOPRIGHT", self.card, "TOPRIGHT", -12, -14)
        self.note:SetJustifyH("RIGHT")
        self.scroll = CreateFrame("ScrollFrame", nil, self.card)
        self.scroll:SetPoint("TOPLEFT", self.card, "TOPLEFT", 0, -HEAD)
        self.scroll:SetPoint("BOTTOMRIGHT", self.card, "BOTTOMRIGHT", 0, FOOT)
        self.scroll:EnableMouseWheel(true)
        self.body = CreateFrame("Frame", nil, self.scroll)
        self.body:SetWidth(sp.width or WIDTH)
        self.body:SetHeight(1)
        self.scroll:SetScrollChild(self.body)
        self.track = self.card:CreateTexture(nil, "ARTWORK")
        self.track:SetWidth(BAR_W)
        self.track:SetPoint("TOPRIGHT", self.card, "TOPRIGHT", -4, -HEAD)
        self.track:SetPoint("BOTTOMRIGHT", self.card, "BOTTOMRIGHT", -4, FOOT)
        self.track:SetTexture(1, 1, 1, 0.08)
        self.track:Hide()
        self.thumb = self.card:CreateTexture(nil, "OVERLAY")
        self.thumb:SetWidth(BAR_W)
        self.thumb:Hide()
        local me = self
        self.scroll:SetScript("OnMouseWheel", function(f, delta)
            local range = f:GetVerticalScrollRange()
            if range <= 0 then
                return
            end
            local v = f:GetVerticalScroll() - delta * STEP
            if v < 0 then
                v = 0
            elseif v > range then
                v = range
            end
            f:SetVerticalScroll(v)
            me:SyncBar()
        end)
        self.scroll:SetScript("OnScrollRangeChanged", function()
            me:SyncBar()
        end)
        self.btn = ns.MakeKitButton(self.card)
        self.btn:SetWidth(sp.btnWidth or 110)
        self.btn2 = ns.MakeKitButton(self.card)
        self.btn2:SetWidth(sp.btnWidth or 110)
        self.btn2:Hide()
        if sp.dismiss then
            self.overlay:SetScript("OnMouseDown", function()
                me:Hide()
            end)
        end
    end
    if self.host ~= host then
        self.host = host
        self.overlay:SetParent(host)
        self.overlay:ClearAllPoints()
        self.overlay:SetAllPoints(host)
        if sp.strata then
            self.overlay:SetFrameStrata(sp.strata)
        end
        if sp.level then
            self.overlay:SetFrameLevel((host:GetFrameLevel() or 0) + sp.level)
        end
    end
end
function Card:Overlay()
    return self.overlay
end
function Card:Panel()
    return self.card
end
function Card:Dim(on)
    if not self.dim then
        return
    end
    if on then
        self.dim:Show()
    else
        self.dim:Hide()
    end
end
function Card:Note(text)
    self.noteText = text
    return self
end
function Card:SyncBar()
    local range = self.scroll:GetVerticalScrollRange()
    if range <= 0 then
        self.track:Hide()
        self.thumb:Hide()
        return
    end
    local seen = self.scroll:GetHeight()
    local full = seen + range
    local h = seen * seen / full
    if h < 12 then
        h = 12
    end
    local at = self.scroll:GetVerticalScroll() / range
    self.thumb:ClearAllPoints()
    self.thumb:SetHeight(h)
    self.thumb:SetPoint("TOPRIGHT", self.card, "TOPRIGHT",
            -4, -HEAD - (seen - h) * at)
    local r, g, b = ns.Attn()
    self.thumb:SetTexture(r, g, b, 0.75)
    self.track:Show()
    self.thumb:Show()
end
function Card:LineAt(i)
    local ln = self.lines[i]
    if ln then
        return ln
    end
    ln = {
        fs = self.body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
        sub = self.body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
        ic = self.body:CreateTexture(nil, "ARTWORK"),
    }
    ln.fs:SetJustifyH("LEFT")
    ln.sub:SetJustifyH("LEFT")
    ln.sub:SetShadowOffset(0, 0)
    self.lines[i] = ln
    return ln
end
function Card:ArtHost(ln, art)
    ln.hosts = ln.hosts or {}
    local h = ln.hosts[art]
    if not h then
        h = CreateFrame("Frame", nil, self.body)
        ln.hosts[art] = h
    end
    for a, other in pairs(ln.hosts) do
        if a ~= art then
            other:Hide()
        end
    end
    return h
end
function Card:Show(host, title, body, btn)
    if not host then
        return
    end
    self:Ensure(host)
    local w = self.spec.width or WIDTH
    ns.Restyle(self.card, self:Look())
    self.title:SetText(title or "")
    self:Dim(true)
    self.note:SetText(self.noteText or "")
    self.title:ClearAllPoints()
    self.title:SetPoint("TOPLEFT", self.card, "TOPLEFT", 12, -11)
    if self.noteText then
        self.title:SetPoint("TOPRIGHT", self.card, "TOPRIGHT", -(self.note:GetStringWidth() + 20), -11)
    end
    self.noteText = nil
    local first, second = btn, nil
    if btn and btn[1] then
        first, second = btn[1], btn[2]
    end
    if first then
        self.btn:SetText(first.label or "")
        self.btn.onClick = first.onClick
        self.btn.tip = first.tip
        if first.off then
            self.btn:Disable()
        else
            self.btn:Enable()
        end
        ns.StyleButton(self.btn)
        self.btn:Show()
    end
    if second then
        self.btn2:SetText(second.label or "")
        self.btn2.onClick = second.onClick
        self.btn2.tip = second.tip
        if second.off then
            self.btn2:Disable()
        else
            self.btn2:Enable()
        end
        ns.StyleButton(self.btn2)
        self.btn2:Show()
        self.btn:ClearAllPoints()
        self.btn:SetPoint("BOTTOMRIGHT", self.card, "BOTTOM", -4, 10)
        self.btn2:ClearAllPoints()
        self.btn2:SetPoint("BOTTOMLEFT", self.card, "BOTTOM", 4, 10)
    else
        self.btn2:Hide()
        self.btn:ClearAllPoints()
        self.btn:SetPoint("BOTTOM", self.card, "BOTTOM", 0, 10)
    end
    local y = 0
    local gutter = 0
    for _, p in ipairs(body or {}) do
        if type(p) == "table" and p.icon then
            gutter = ICON + 6
            break
        end
    end
    local x = 12 + gutter
    for i, p in ipairs(body or {}) do
        local ln = self:LineAt(i)
        local tbl = type(p) == "table"
        local art = tbl and p.art or nil
        local icon = tbl and p.icon or nil
        local sub = tbl and p.sub or nil
        if art then
            ln.fs:Hide()
            ln.ic:Hide()
            local ah = self:ArtHost(ln, art)
            ah:SetWidth(w - x - 12)
            ah:SetHeight(p.h or 60)
            ah:ClearAllPoints()
            ah:SetPoint("TOPLEFT", self.body, "TOPLEFT", x, -y)
            if ah.drawn ~= art then
                art(ah)
                ah.drawn = art
            end
            ah:Show()
            y = y + ah:GetHeight() + 4
        else
            for _, h in pairs(ln.hosts or {}) do
                h:Hide()
            end
            ln.fs:SetWidth(w - x - 12)
            ln.fs:SetText(tbl and p.t or p)
            ln.fs:ClearAllPoints()
            ln.fs:SetPoint("TOPLEFT", self.body, "TOPLEFT", x, -y)
            ln.fs:Show()
            local h = ln.fs:GetStringHeight()
            if h <= 1 then
                h = 12
            end
            if icon then
                ln.ic:SetTexture(icon)
                if p.coord then
                    ln.ic:SetTexCoord(p.coord[1], p.coord[2], p.coord[3], p.coord[4])
                else
                    ns.CropIcon(ln.ic)
                end
                ln.ic:SetWidth(ICON);
                ln.ic:SetHeight(ICON)
                ln.ic:ClearAllPoints()
                ln.ic:SetPoint("TOPLEFT", self.body, "TOPLEFT", 12, -y)
                ln.ic:Show()
                if h < ICON then
                    h = ICON
                end
            else
                ln.ic:Hide()
            end
            y = y + h + 2
        end
        if sub then
            ln.sub:SetWidth(w - x - 12)
            ln.sub:SetText(sub)
            ln.sub:SetTextColor(ns.Attn())
            ln.sub:ClearAllPoints()
            ln.sub:SetPoint("TOPLEFT", self.body, "TOPLEFT", x, -y)
            ln.sub:Show()
            y = y + ln.sub:GetStringHeight()
        else
            ln.sub:Hide()
        end
        y = y + GAP
    end
    for i = #(body or {}) + 1, #self.lines do
        self.lines[i].fs:Hide();
        self.lines[i].sub:Hide();
        self.lines[i].ic:Hide()
        for _, h in pairs(self.lines[i].hosts or {}) do
            h:Hide()
        end
    end
    self.body:SetWidth(w)
    self.body:SetHeight(y > 1 and y or 1)
    local room = (self.overlay:GetHeight() or 0) - 24
    local maxH = self.spec.maxH or room
    if maxH < MIN_H then
        maxH = MIN_H
    end
    local want = HEAD + y + FOOT
    self.card:SetHeight(want > maxH and maxH or want)
    self.scroll:SetVerticalScroll(0)
    self:SyncBar()
    self.overlay:Show()
end
function Card:Hide()
    if self.overlay then
        self.overlay:Hide()
    end
end
function Card:IsShown()
    return self.overlay and self.overlay:IsShown() and true or false
end
local DECK_FONT = "Fonts\\ARIALN.TTF"
local floor = math.floor
local function deckFont(fs, size, flags)
    flags = flags or "THICKOUTLINE"
    if not fs:SetFont(DECK_FONT, size, flags) then
        fs:SetFont((fs:GetFont()), size, flags)
    end
    if flags == "" then
        fs:SetShadowOffset(0, 0)
    else
        fs:SetShadowOffset(1, -1)
    end
end
function ns.MakeDeckCard(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetBackdrop(ns.CARD_BACKDROP)
    f.rank = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.rank:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.corner = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.corner:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -5)
    f.corner:Hide()
    f.mark = f:CreateTexture(nil, "OVERLAY")
    f.mark:Hide()
    f.corner2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.corner2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 5)
    f.corner2:Hide()
    f.mark2 = f:CreateTexture(nil, "OVERLAY")
    f.mark2:Hide()
    return f
end
function ns.DeckCardRank(fs, size, text, r, g, b, flags)
    if not text then
        fs:Hide();
        return
    end
    deckFont(fs, size, flags)
    fs:SetText(text)
    fs:SetTextColor(r or 1, g or 1, b or 1)
    fs:Show()
end
ns.DECK_SUITS = {
    { red = true, shape = {
        { 0.03, 0.02, 0.42, 0.16 },
        { 0.55, 0.02, 0.42, 0.16 },
        { 0.00, 0.18, 0.46, 0.14 },
        { 0.54, 0.18, 0.46, 0.14 },
        { 0.00, 0.32, 1.00, 0.16 },
        { 0.08, 0.48, 0.84, 0.14 },
        { 0.18, 0.62, 0.64, 0.13 },
        { 0.30, 0.75, 0.40, 0.13 },
        { 0.42, 0.88, 0.16, 0.12 },
    } },
    { red = true, shape = {
        { 0.44, 0.00, 0.12, 0.11 },
        { 0.35, 0.11, 0.30, 0.11 },
        { 0.25, 0.22, 0.50, 0.11 },
        { 0.15, 0.33, 0.70, 0.11 },
        { 0.05, 0.44, 0.90, 0.12 },
        { 0.15, 0.56, 0.70, 0.11 },
        { 0.25, 0.67, 0.50, 0.11 },
        { 0.35, 0.78, 0.30, 0.11 },
        { 0.44, 0.89, 0.12, 0.11 },
    } },
    { shape = {
        { 0.44, 0.00, 0.12, 0.10 },
        { 0.34, 0.10, 0.32, 0.12 },
        { 0.22, 0.22, 0.56, 0.13 },
        { 0.10, 0.35, 0.80, 0.14 },
        { 0.00, 0.49, 1.00, 0.15 },
        { 0.00, 0.64, 0.36, 0.12 },
        { 0.64, 0.64, 0.36, 0.12 },
        { 0.44, 0.64, 0.12, 0.24 },
        { 0.28, 0.88, 0.44, 0.12 },
    } },
    { shape = {
        { 0.36, 0.00, 0.28, 0.10 },
        { 0.28, 0.10, 0.44, 0.12 },
        { 0.24, 0.22, 0.52, 0.10 },
        { 0.02, 0.32, 0.96, 0.10 },
        { 0.00, 0.42, 1.00, 0.12 },
        { 0.02, 0.54, 0.96, 0.08 },
        { 0.04, 0.62, 0.28, 0.10 },
        { 0.68, 0.62, 0.28, 0.10 },
        { 0.44, 0.62, 0.12, 0.26 },
        { 0.26, 0.88, 0.48, 0.12 },
    } },
}
local SUIT_PARTS_MAX = 10
ns.DECK_PAPER = { 0.96, 0.94, 0.88 }
ns.DECK_EDGE = { 0.15, 0.13, 0.12 }
local INK_BLACK = { 0.06, 0.05, 0.05 }
local INK_RED = { 0.60, 0.05, 0.07 }
local PAPER_TEX = "Interface\\Buttons\\WHITE8X8"
local PAPER_BACKDROP = {
    bgFile = PAPER_TEX,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
function ns.DeckSuitInk(suit)
    local s = ns.DECK_SUITS[suit or 0]
    local c = (s and s.red) and INK_RED or INK_BLACK
    return c[1], c[2], c[3]
end
local RANK_SHORT = {
    [1] = "deckRankAce", [11] = "deckRankJack",
    [12] = "deckRankQueen", [13] = "deckRankKing",
}
function ns.DeckRankLabel(r)
    local k = RANK_SHORT[r]
    return k and ns.T(k) or tostring(r)
end
local RANK_NAME = {
    "deckRankName1", "deckRankName2", "deckRankName3", "deckRankName4",
    "deckRankName5", "deckRankName6", "deckRankName7", "deckRankName8",
    "deckRankName9", "deckRankName10", "deckRankName11", "deckRankName12",
    "deckRankName13",
}
local RANK_MANY = {
    "deckRankMany1", "deckRankMany2", "deckRankMany3", "deckRankMany4",
    "deckRankMany5", "deckRankMany6", "deckRankMany7", "deckRankMany8",
    "deckRankMany9", "deckRankMany10", "deckRankMany11", "deckRankMany12",
    "deckRankMany13",
}
function ns.DeckRankName(r, many)
    local k = (many and RANK_MANY or RANK_NAME)[r]
    return k and ns.T(k) or tostring(r)
end
local function edgeBar(f, a1, a2, w, h)
    local t = f:CreateTexture(nil, "BORDER")
    t:SetPoint(a1, f, a1, 0, 0)
    t:SetPoint(a2, f, a2, 0, 0)
    if w then
        t:SetWidth(w)
    end
    if h then
        t:SetHeight(h)
    end
    return t
end
function ns.DeckCardPaper(f, r, g, b)
    local p = ns.DECK_PAPER
    f.paperTint = f.paperTint or {}
    f.paperTint[1], f.paperTint[2], f.paperTint[3] = r or p[1], g or p[2], b or p[3]
    if not f.paper then
        f:SetBackdrop(PAPER_BACKDROP)
        f.paper = {
            edgeBar(f, "TOPLEFT", "TOPRIGHT", nil, 1),
            edgeBar(f, "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1),
            edgeBar(f, "TOPLEFT", "BOTTOMLEFT", 1, nil),
            edgeBar(f, "TOPRIGHT", "BOTTOMRIGHT", 1, nil),
        }
    end
    f:SetBackdropColor(r or p[1], g or p[2], b or p[3], 1)
    ns.DeckCardEdge(f)
end
function ns.DeckCardEdge(f, r, g, b)
    if not f.paper then
        return
    end
    local e = ns.DECK_EDGE
    local rr, gg, bb = r or e[1], g or e[2], b or e[3]
    for i = 1, #f.paper do
        f.paper[i]:SetTexture(rr, gg, bb, 1)
    end
end
local function suitParts(tex)
    if tex.suitParts then
        return tex.suitParts
    end
    local parent, layer = tex:GetParent(), tex:GetDrawLayer()
    local box = {}
    for i = 1, SUIT_PARTS_MAX do
        box[i] = parent:CreateTexture(nil, layer)
        box[i]:Hide()
    end
    tex.suitParts = box
    return box
end
local function hideSuitParts(tex)
    local box = tex.suitParts
    if not box then
        return
    end
    for i = 1, #box do
        box[i]:Hide()
    end
end
local function paintSuit(tex, suit, r, g, b)
    local s = ns.DECK_SUITS[suit or 0]
    if not s then
        hideSuitParts(tex)
        tex:Hide()
        return false
    end
    if not r then
        r, g, b = ns.DeckSuitInk(suit)
    end
    tex:SetTexture(0, 0, 0, 0)
    tex:Show()
    local w, h = tex:GetWidth() or 0, tex:GetHeight() or 0
    local box = suitParts(tex)
    for i = 1, SUIT_PARTS_MAX do
        local p = s.shape[i]
        if p then
            local t = box[i]
            t:SetTexture(r, g, b, 1)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", tex, "TOPLEFT", p[1] * w, -p[2] * h)
            t:SetWidth(p[3] * w)
            t:SetHeight(p[4] * h)
            t:Show()
        else
            box[i]:Hide()
        end
    end
    return true
end
function ns.DeckCardSuit(tex, icon, suit, r, g, b)
    if icon then
        hideSuitParts(tex)
        tex:SetTexture(ns.IconPath(icon))
        ns.CropIcon(tex)
        tex:SetDesaturated(false)
        tex:SetVertexColor(1, 1, 1)
        tex:Show()
        return
    end
    paintSuit(tex, suit, r, g, b)
end
local PIC_ASPECT = {
    { "Interface\\LFGFrame\\", 2 },
}
local function isPicture(name)
    return name:find("\\", 1, true) ~= nil or name:find("/", 1, true) ~= nil
end
local function aspectOf(name)
    for i = 1, #PIC_ASPECT do
        if name:find(PIC_ASPECT[i][1], 1, true) == 1 then
            return PIC_ASPECT[i][2]
        end
    end
    return 1
end
local function cropToField(tex, name, fw, fh)
    if ns.Pics and ns.Pics.Fit and isPicture(name) then
        if ns.Pics.Fit(tex, name, fw, fh) then
            return
        end
    end
    local pic = isPicture(name)
    local trim = pic and 1 or (ns.CELL_CROP[2] - ns.CELL_CROP[1])
    local u, v = 1, 1
    local k = (fw / fh) / (pic and aspectOf(name) or 1)
    if k <= 1 then
        u = k
    else
        v = 1 / k
    end
    u, v = u * trim, v * trim
    tex:SetTexCoord(0.5 - u / 2, 0.5 + u / 2, 0.5 - v / 2, 0.5 + v / 2)
end
local function trySetTexture(tex, path)
    tex:SetTexture(nil)
    if not path then
        return false
    end
    tex:SetTexture(path)
    return tex:GetTexture() ~= nil
end
local cropScratch
function ns.DeckCropCoords(name, fw, fh)
    if not cropScratch then
        cropScratch = UIParent:CreateTexture(nil, "BACKGROUND")
        cropScratch:Hide()
    end
    cropToField(cropScratch, name, fw, fh)
    local ulx, uly, llx, lly, urx = cropScratch:GetTexCoord()
    return { ulx, urx, uly, lly }
end
local COVER_RULE = 6
local COVER_ART_MIN = 32
local COVER_BG = { 0.46, 0.11, 0.13 }
local COVER_GOLD = { 0.85, 0.70, 0.34 }
local COVER_GOLD_D = { 0.47, 0.38, 0.18 }
local COVER_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    tile = true, tileSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}
local function coverOf(f)
    if f.cover then
        return f.cover
    end
    local c = CreateFrame("Frame", nil, f)
    c:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    c:SetBackdrop(COVER_BACKDROP)
    c:SetBackdropColor(COVER_BG[1], COVER_BG[2], COVER_BG[3], 1)
    c.art = c:CreateTexture(nil, "ARTWORK")
    c.bars = {}
    local function band(col, a, inset, thick)
        local function bar(a1, x1, y1, a2, x2, y2, w, h)
            local t = c:CreateTexture(nil, "OVERLAY")
            t:SetTexture(col[1], col[2], col[3], a)
            t:SetPoint(a1, c, a1, x1, y1)
            t:SetPoint(a2, c, a2, x2, y2)
            if w then
                t:SetWidth(w)
            end
            if h then
                t:SetHeight(h)
            end
            c.bars[#c.bars + 1] = { t = t, r = col[1], g = col[2], b = col[3], a = a }
        end
        local i, j = inset, inset + thick
        bar("TOPLEFT", i, -i, "TOPRIGHT", -i, -i, nil, thick)
        bar("BOTTOMLEFT", i, i, "BOTTOMRIGHT", -i, i, nil, thick)
        bar("TOPLEFT", i, -j, "BOTTOMLEFT", i, j, thick, nil)
        bar("TOPRIGHT", -i, -j, "BOTTOMRIGHT", -i, j, thick, nil)
    end
    band(ns.DECK_EDGE, 1, 0, 1)
    band(COVER_GOLD, 0.9, 1, 2)
    band(COVER_GOLD_D, 0.9, 3, 1)
    band(COVER_GOLD, 0.5, COVER_RULE, 1)
    f.cover = c
    return c
end
function ns.DeckCardCover(f, on, icon, emblem)
    if not on then
        if f.cover then
            f.cover:Hide()
        end
        return
    end
    local c = coverOf(f)
    local w, h = f:GetWidth() or 0, f:GetHeight() or 0
    local side = (w < h) and w or h
    c:SetFrameLevel(f:GetFrameLevel() + 1)
    if c.rank then
        c.rank:Hide()
    end
    c.art:ClearAllPoints()
    if icon and side >= COVER_ART_MIN and trySetTexture(c.art, ns.IconPath(icon)) then
        c.art:SetAllPoints(c)
        if w > 0 and h > 0 then
            cropToField(c.art, icon, w, h)
        end
        c.art:SetDesaturated(false)
        c.artCol = { 1, 1, 1 }
        c.art:Show()
    elseif emblem and side >= COVER_ART_MIN then
        local s = floor(side * 0.42)
        c.art:SetPoint("CENTER", c, "CENTER", 0, 0)
        c.art:SetWidth(s)
        c.art:SetHeight(s)
        c.art:SetTexture(ns.IconPath(emblem))
        ns.CropIcon(c.art)
        c.art:SetDesaturated(true)
        c.artCol = { 1, 0.86, 0.5 }
        c.art:Show()
    else
        c.art:Hide()
    end
    c.tone = nil
    ns.DeckCardCoverTone(f, f.coverTone)
    c:Show()
end
function ns.DeckCardCoverTone(f, k)
    k = k or 1
    f.coverTone = k
    local c = f.cover
    if not c or c.tone == k then
        return
    end
    c.tone = k
    c:SetBackdropColor(COVER_BG[1] * k, COVER_BG[2] * k, COVER_BG[3] * k, 1)
    local a = c.artCol
    if a then
        c.art:SetVertexColor(a[1] * k, a[2] * k, a[3] * k)
    end
    for i = 1, #(c.bars or {}) do
        local b = c.bars[i]
        b.t:SetTexture(b.r * k, b.g * k, b.b * k, b.a)
    end
end
function ns.DeckCardLevel(f, level)
    f:SetFrameLevel(level)
    if f.cover then
        f.cover:SetFrameLevel(level + 1)
    end
end
function ns.DeckCardCoverRank(f, size, text, r, g, b)
    local c = f.cover
    if not c then
        return
    end
    if not c.rank then
        c.rank = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        c.rank:SetPoint("CENTER", c, "CENTER", 0, 0)
    end
    ns.DeckCardRank(c.rank, size, text, r, g, b)
end
local ART_INSET = 2
local ART_SIDE = 0.15
local ART_TOP = 1
local FADE_X, FADE_Y = 0.19, 0.05
local FADE_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\card_fade.tga"
local function artOf(f)
    if f.art then
        return f.art
    end
    local a = {}
    a.big = f:CreateTexture(nil, "BORDER")
    a.big:Hide()
    a.veil = f:CreateTexture(nil, "ARTWORK")
    a.veil:SetTexture(FADE_TEX)
    a.veil:Hide()
    f.art = a
    return a
end
local function hideFades(a)
    if a.veil then a.veil:Hide() end
end
local function fadeEdges(f, a, x1, y1, x2, y2)
    local p = f.paperTint or ns.DECK_PAPER
    a.veil:ClearAllPoints()
    a.veil:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x1, y1)
    a.veil:SetPoint("TOPRIGHT", f, "BOTTOMLEFT", x2, y2)
    a.veil:SetVertexColor(p[1], p[2], p[3])
    a.veil:Show()
end
function ns.DeckCardArtBox(w, h)
    local x1 = floor(w * ART_SIDE)
    return x1, ART_TOP, w - x1, h - ART_TOP
end
function ns.DeckCardArt(f, icon)
    local a = f.art
    if f.frame then
        f.frame:Hide()
        f.caption:Hide()
    end
    f.rank:ClearAllPoints()
    f.rank:SetPoint("CENTER", f, "CENTER", 0, 0)
    if not icon then
        if a then
            a.big:Hide()
            hideSuitParts(a.big)
            hideFades(a)
        end
        return false
    end
    a = artOf(f)
    hideSuitParts(a.big)
    if not trySetTexture(a.big, ns.IconPath(icon)) then
        a.big:Hide()
        hideFades(a)
        return false
    end
    local w, h = f:GetWidth() or 0, f:GetHeight() or 0
    local x1, y1, x2, y2 = ns.DeckCardArtBox(w, h)
    a.big:ClearAllPoints()
    a.big:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x1, y1)
    a.big:SetPoint("TOPRIGHT", f, "BOTTOMLEFT", x2, y2)
    cropToField(a.big, icon, x2 - x1, y2 - y1)
    a.big:SetDesaturated(false)
    a.big:SetVertexColor(1, 1, 1)
    a.big:Show()
    fadeEdges(f, a, x1, y1, x2, y2)
    return true
end
local POSTER_FRAME = "Interface\\AddOns\\" .. ADDON .. "\\art\\card_frame.tga"
local POSTER_PLATE_Y = 12 / 101
local POSTER_FONT = 10 / 101
local POSTER_INK = { 0.20, 0.12, 0.05 }
function ns.DeckCardPoster(f, icon, caption)
    local a = artOf(f)
    if not f.frame then
        f.frame = f:CreateTexture(nil, "OVERLAY")
        f.frame:SetAllPoints(f)
        f.caption = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    end
    f.rank:ClearAllPoints()
    f.rank:SetPoint("CENTER", f, "CENTER", 0, 0)
    hideSuitParts(a.big)
    hideFades(a)
    if not icon or not trySetTexture(a.big, ns.IconPath(icon)) then
        a.big:Hide()
        f.frame:Hide()
        f.caption:Hide()
        return false
    end
    local w, h = f:GetWidth() or 0, f:GetHeight() or 0
    local x1, y1, x2, y2 = ART_INSET, ART_INSET, w - ART_INSET, h - ART_INSET
    a.big:ClearAllPoints()
    a.big:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x1, y1)
    a.big:SetPoint("TOPRIGHT", f, "BOTTOMLEFT", x2, y2)
    cropToField(a.big, icon, x2 - x1, y2 - y1)
    a.big:SetDesaturated(false)
    a.big:SetVertexColor(1, 1, 1)
    a.big:Show()
    f.frame:ClearAllPoints()
    f.frame:SetTexture(POSTER_FRAME)
    local framed = f.frame:GetTexture() ~= nil
    if framed then
        f.frame:SetAllPoints(f)
        f.frame:SetTexCoord(0, 1, 0, 1)
    else
        f.frame:SetTexture(0, 0, 0, 0.62)
        f.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x1, y1)
        f.frame:SetWidth(x2 - x1)
        f.frame:SetHeight(h * POSTER_PLATE_Y * 2)
    end
    f.frame:Show()
    f.caption:ClearAllPoints()
    f.caption:SetPoint("CENTER", f, "BOTTOM", 0, h * POSTER_PLATE_Y)
    f.caption:SetWidth(w - 12)
    f.caption:SetJustifyH("CENTER")
    local size = floor(h * POSTER_FONT + 0.5)
    if size < 7 then size = 7 end
    if framed then
        ns.DeckCardRank(f.caption, size, caption, POSTER_INK[1], POSTER_INK[2], POSTER_INK[3], "")
    else
        ns.DeckCardRank(f.caption, size, caption, 1, 1, 1)
    end
    return true
end
local COURT = {
    [11] = "Interface\\Glues\\Credits\\Human_Male2#0.0000,0.2600,0.0040,0.6760",
    [12] = "Interface\\Glues\\Credits\\Female_BloodElf2#0.0900,0.3500,0.0640,0.7360",
    [13] = "Interface\\Glues\\Credits\\LichKingTGA2#0.0000,0.2600,0.1040,0.7760",
}
local INDEX_RANK, INDEX_MARK, INDEX_INSET = 0.16, 0.09, 0.03
local INDEX_COL = 0.20
local BIG_RANK = 0.34
function ns.DeckCardIndexBox(w, h)
    return floor(h * INDEX_INSET), floor(h * INDEX_RANK), floor(h * INDEX_MARK), floor(w * INDEX_COL)
end
function ns.DeckCardFace(f, rank, suit, o)
    o = o or {}
    local w, h = f:GetWidth() or 0, f:GetHeight() or 0
    local r, g, b = o.r, o.g, o.b
    if not r then r, g, b = ns.DeckSuitInk(suit) end
    local inset, size, mark, col = ns.DeckCardIndexBox(w, h)
    local axis = inset + col / 2
    local drop = inset + size + 1
    local label = ns.DeckRankLabel(rank)
    f.corner:ClearAllPoints()
    f.corner:SetWidth(col * 2)
    f.corner:SetJustifyH("CENTER")
    f.corner:SetPoint("TOP", f, "TOPLEFT", axis, -inset)
    f.mark:ClearAllPoints()
    f.mark:SetWidth(mark)
    f.mark:SetHeight(mark)
    f.mark:SetPoint("TOP", f, "TOPLEFT", axis, -drop)
    f.corner2:ClearAllPoints()
    f.corner2:SetWidth(col * 2)
    f.corner2:SetJustifyH("CENTER")
    f.corner2:SetPoint("BOTTOM", f, "BOTTOMRIGHT", -axis, inset)
    f.mark2:ClearAllPoints()
    f.mark2:SetWidth(mark)
    f.mark2:SetHeight(mark)
    f.mark2:SetPoint("BOTTOM", f, "BOTTOMRIGHT", -axis, drop)
    ns.DeckCardRank(f.corner, size, label, r, g, b, "")
    ns.DeckCardRank(f.corner2, size, label, r, g, b, "")
    ns.DeckCardSuit(f.mark, o.icon, suit, r, g, b)
    ns.DeckCardSuit(f.mark2, o.icon, suit, r, g, b)
    local court = (rank >= 11) and (o.court or COURT[rank]) or nil
    if court and ns.DeckCardArt(f, court) then
        ns.DeckCardRank(f.rank, nil)
        return
    end
    ns.DeckCardArt(f, nil)
    f.rank:ClearAllPoints()
    f.rank:SetPoint("CENTER", f, "CENTER", 0, 0)
    ns.DeckCardRank(f.rank, floor(h * BIG_RANK), label, r, g, b, "")
end
function ns.DeckFan(n, o)
    local xs = {}
    if n <= 0 then
        return xs, 0, false
    end
    local w, span = o.w, o.span
    local gap = o.gap or 6
    local x0 = o.x or 0
    if n == 1 then
        xs[1] = x0 + (span - w) / 2
        return xs, 0, false
    end
    local step = (span - w) / (n - 1)
    local loose = w + gap
    if step > loose then
        step = loose
    end
    local minStep = o.minStep or 18
    if step < minStep then
        local fit = (span - w) / (n - 1)
        step = minStep
        if step * (n - 1) + w > span then
            step = fit
        end
    end
    local width = step * (n - 1) + w
    local startX = x0 + (span - width) / 2
    for i = 1, n do
        xs[i] = startX + (i - 1) * step
    end
    return xs, step, step < w
end
function ns.DeckPile(n, o)
    o = o or {}
    local dx, dy = o.dx or 2, o.dy or 2
    local max = o.max or 4
    local layers = n
    if layers > max then
        layers = max
    end
    if layers < 0 then
        layers = 0
    end
    local offs = {}
    for i = 1, layers do
        offs[i] = { dx = (i - 1) * dx, dy = (i - 1) * dy }
    end
    local grow = layers > 0 and (layers - 1) or 0
    return offs, grow * dx, grow * dy
end
function ns.DeckCascade(steps, o)
    local ys = { }
    local n = #steps + 1
    if n <= 0 then
        return ys
    end
    ys[1] = 0
    if n == 1 then
        return ys
    end
    local h, room = o.h, o.room
    local floorStep = o.floor or 4
    local nominal = h
    for i = 1, #steps do
        nominal = nominal + steps[i]
    end
    local shrink = 1
    if nominal > room then
        local budget = room - h
        if budget < 0 then
            budget = 0
        end
        shrink = budget / (nominal - h)
    end
    local y = 0
    for i = 1, #steps do
        local s = steps[i] * shrink
        if s < floorStep then
            s = floorStep
        end
        y = y + s
        ys[i + 1] = y
    end
    return ys
end
