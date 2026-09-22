local ADDON, ns = ...
local ID = "breaker"
local floor, min, max = math.floor, math.min, math.max
local MIN_SIZE, MAX_SIZE = 10, 20
local DEFAULT_SIZE = 10
local SIZES = { 10, 15, 20 }
local MIN_GROUP = 2
local MODE_CLASSIC, MODE_TIME, MODE_WAVES = "classic", "time", "waves"
local DEFAULT_MODE = MODE_CLASSIC
local TIME_LIMIT = 120
local WAVES_BY_SIZE = { [10] = 4, [15] = 3, [20] = 2 }
local BONUS_CLEAR = 1000
local NEUTRAL = { 1, 1, 1 }
local BIG = 5
local SERIES_PT = 20
local SERIES_CAP = 6
local MODES = {
    { key = MODE_CLASSIC, label = "breaker.modeClassicLabel",
      tip = "breaker.modeClassicTip" },
    { key = MODE_TIME, label = "breaker.modeTimeLabel",
      tip = "breaker.modeTimeTip" },
    { key = MODE_WAVES, label = "breaker.modeWavesLabel",
      tip = "breaker.modeWavesTip" },
}
local function colorsFor(size)
    return size >= 15 and 5 or 4
end
local function wavesFor(size)
    return WAVES_BY_SIZE[size] or 3
end
local function SIZE_OPTS()
    local out = {}
    for _, n in ipairs(SIZES) do
        out[#out + 1] = {
            key = n, label = n .. "x" .. n,
            tip = ns.T("breaker.sizeTipFmt", n, n, colorsFor(n)),
        }
    end
    return out
end
local function modeLabel(mode)
    for _, m in ipairs(MODES) do
        if m.key == mode then return ns.TL(m.label) end
    end
    return mode
end
local FADE, FALL, FALL_PER, FALL_CAP = 0.15, 0.2, 0.02, 0.3
local END_FLASH = 1.2
local GAP = 2
local PACK = 32
local HL_A = 0.3
local EDGE_A = 0.7
local HINT_BG_A = 0.98
local HINT_BG_MIX = 0.22
local HINT_PAD = 6
local HINT_EDGE = 8
local NB = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local COL_W   = 154
local COL_PAD = 14
local COL_IN  = COL_W - COL_PAD * 2
local ROW     = 22
local RIM     = 6
local FIELD_PAD = 6
local M_PAD    = 16
local CAP_TOP  = 8
local THEME_H, THEME_TOP, THEME_GAP = 22, 453, 8
local TILE_W, TILE_H, TILE_GAP, TILE_TOP = 196, 260, 10, 24
local WIN_SIDE = 168
local WIN_PAD  = 8
local WIN_TOP  = 8
local NAME_Y, SUB_Y, REC_Y = 208, 228, 246
local SEAM1    = 296
local CAP2     = 307
local MODE_TOP, MODE_H = 324, 30
local TIP_TOP  = 364
local SEAM2    = 386
local PLAY_TOP, PLAY_W, PLAY_H = 401, 220, 44
local PAIR_W, PAIR_GAP = 200, 16
local LOOK_WOOD = { 0.230, 0.190, 0.130 }
local LOOK_EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE }
local C_GROUT = { 0.04, 0.04, 0.05, 0.95 }
local C_FRAME = { 0.58, 0.47, 0.28, 1 }
local C_RULE  = { 0.21, 0.18, 0.14, 1 }
local C_SEAM  = { 0.52, 0.42, 0.26, 0.45 }
local C_DARK  = { 0.06, 0.045, 0.03 }
local C_CAP   = { 0.54, 0.51, 0.45 }
local C_TEXT  = { 0.91, 0.90, 0.86 }
local C_SOFT  = { 0.65, 0.61, 0.53 }
local C_DIM   = { 0.42, 0.39, 0.34 }
local C_GOLD  = { 1, 0.82, 0 }
local TEX_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local TEX_BACK = "Interface\\Tooltips\\UI-Tooltip-Background"
local field, tiles, hint, fx
local deco, rim, ui, menu
local preDeck, preKeep
local TIERS = {
    { n = 12, r = 1.00, g = 0.45, b = 0.15, size = 30, word = "breaker.tierHuge" },
    { n = 8,  r = 1.00, g = 0.62, b = 0.15, size = 26, word = "breaker.tierGreat" },
    { n = BIG, r = 1.00, g = 0.88, b = 0.32, size = 22 },
    { n = 0,  r = 0.92, g = 0.92, b = 0.92, size = 17 },
}
local function tierFor(n)
    for i = 1, #TIERS do
        if n >= TIERS[i].n then return TIERS[i] end
    end
    return TIERS[#TIERS]
end
local function tierRGB(tier)
    return tier.r, tier.g, tier.b
end
local FLOATS = 10
local FLOAT_LIFE = 0.9
local FLOAT_RISE = 30
local BANNER_LIFE = 1.1
local FONT_TXT = "Fonts\\ARIALN.TTF"
local function bigFont(fs, size)
    if ns.SetFont(fs, FONT_TXT, size, "THICKOUTLINE") then return end
    ns.SetFont(fs, (fs:GetFont()), size, "THICKOUTLINE")
end
local function tileAt(i)
    local t = tiles[i]
    if t then return t end
    t = {
        ic = field:CreateTexture(nil, "ARTWORK"),
        hl = field:CreateTexture(nil, "OVERLAY"),
    }
    ns.Paint(t.hl, 1, 1, 1, 1)
    t.hl:SetBlendMode("ADD")
    t.hl:SetAlpha(HL_A)
    t.hl:Hide()
    tiles[i] = t
    return t
end
local edgeF, edges, edgeUsed = nil, nil, 0
local function edgeAt()
    edgeUsed = edgeUsed + 1
    local e = edges[edgeUsed]
    if not e then
        e = edgeF:CreateTexture(nil, "OVERLAY")
        ns.Paint(e, 1, 1, 1, 1)
        edges[edgeUsed] = e
    end
    return e
end
local function edgesHide()
    for i = 1, edgeUsed do edges[i]:Hide() end
    edgeUsed = 0
end
local function stepFor(size, canvas)
    local avail = min((canvas.W or 640) - COL_W, canvas.H or 480)
    local step = ns.CellFit(size, avail, 0, 0)
    local fit = floor((avail - FIELD_PAD * 2) / size)
    if fit < step then step = fit end
    return step
end
local function previewColor(slot, c, r, colors)
    return 1 + ((slot * 131 + c * 37 + r * 71 + c * r * 13) % colors)
end
local PRE_COLORS = colorsFor(SIZES[#SIZES])
local function previewDeck()
    local theme, stamp = ns.Shelves.Theme(ID), ns.Shelves.stamp
    if preDeck and preDeck.theme == theme and preDeck.stamp == stamp then
        return preDeck.icon
    end
    local roll = ns.RNG.New(floor(GetTime() * 1000))
    local icon = {}
    for i, sh in ipairs(ns.Shelves.Deal(ID, PRE_COLORS, roll)) do
        icon[i] = ns.Shelves.Pick(ID, sh.key, roll)
    end
    preDeck = { theme = theme, stamp = stamp, icon = icon }
    return icon
end
local function seamAt(parent, y)
    local t = ns.Fill(parent, "ARTWORK", C_SEAM)
    t:SetHeight(1)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", M_PAD, -y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -M_PAD, -y)
end
local function capAt(parent, y, key)
    local fs = ns.MakeCap(parent, M_PAD, y)
    ns.SetKeyText(fs, key)
    return fs
end
local function buildMenu(canvas)
    local m = { hover = nil, tipMode = nil }
    m.root = ns.NewFrame("Frame", nil, canvas)
    m.root:SetFrameLevel(canvas:GetFrameLevel() + 6)
    m.root:SetAllPoints(canvas)
    m.root:Hide()
    capAt(m.root, CAP_TOP, "breaker.optSizeLabel")
    m.slot = {}
    for i = 1, #SIZES do
        local x = M_PAD + (i - 1) * (TILE_W + TILE_GAP)
        local s = { tile = {} }
        s.plate = ns.MakeSlot(m.root, LOOK)
        s.plate:SetFrameLevel(m.root:GetFrameLevel() + 1)
        s.plate:SetWidth(TILE_W)
        s.plate:SetHeight(TILE_H)
        s.plate:SetPoint("TOPLEFT", m.root, "TOPLEFT", x, -TILE_TOP)
        s.win = ns.NewFrame("Frame", nil, s.plate)
        s.win:SetFrameLevel(s.plate:GetFrameLevel() + 1)
        s.win:SetWidth(WIN_SIDE + WIN_PAD * 2)
        s.win:SetHeight(WIN_SIDE + WIN_PAD * 2)
        s.win:SetPoint("TOP", s.plate, "TOP", 0, -WIN_TOP)
        s.win:SetBackdrop{
            bgFile = TEX_BACK, edgeFile = TEX_EDGE,
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        }
        s.win:SetBackdropColor(C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
        s.deck = ns.NewFrame("Frame", nil, s.win)
        s.deck:SetFrameLevel(s.win:GetFrameLevel() + 1)
        s.deck:SetPoint("BOTTOMLEFT", s.win, "BOTTOMLEFT", WIN_PAD, WIN_PAD)
        s.deck:SetWidth(WIN_SIDE)
        s.deck:SetHeight(WIN_SIDE)
        s.name = s.plate:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        s.name:SetPoint("CENTER", s.plate, "TOP", 0, -NAME_Y)
        s.sub = s.plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        s.sub:SetPoint("CENTER", s.plate, "TOP", 0, -SUB_Y)
        s.rec = s.plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        s.rec:SetPoint("CENTER", s.plate, "TOP", 0, -REC_Y)
        s.plate:HookScript("OnEnter", function(b)
            if b.onHover then b.onHover(true) end
        end)
        s.plate:HookScript("OnLeave", function(b)
            if b.onHover then b.onHover(false) end
        end)
        s.plate:SetScript("OnClick", function(b)
            if b.onPick then ns.Sfx.Ui(); b.onPick() end
        end)
        m.slot[i] = s
    end
    seamAt(m.root, SEAM1)
    capAt(m.root, CAP2, "breaker.optModeLabel")
    m.mode = {}
    for i = 1, #MODES do
        local b = ns.MakeSlot(m.root, LOOK)
        b:SetFrameLevel(m.root:GetFrameLevel() + 1)
        b:SetWidth(TILE_W)
        b:SetHeight(MODE_H)
        b:SetPoint("TOPLEFT", m.root, "TOPLEFT",
            M_PAD + (i - 1) * (TILE_W + TILE_GAP), -MODE_TOP)
        b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.name:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.name:SetText(ns.TL(MODES[i].label))
        b:HookScript("OnEnter", function()
            m.tipMode = i
            if m.onTip then m.onTip() end
        end)
        b:HookScript("OnLeave", function()
            if m.tipMode == i then m.tipMode = nil end
            if m.onTip then m.onTip() end
        end)
        b:SetScript("OnClick", function(self)
            if self.onClick then ns.Sfx.Ui(); self.onClick() end
        end)
        m.mode[i] = b
    end
    m.tip = m.root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.tip:SetPoint("TOP", m.root, "TOP", 0, -TIP_TOP)
    m.tip:SetWidth(560)
    m.tip:SetJustifyH("CENTER")
    m.tip:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    seamAt(m.root, SEAM2)
    m.themeCap = ns.MakeCap(m.root, 0, 0)
    ns.SetKeyText(m.themeCap, "barTheme")
    m.theme = ns.MakeSelect(m.root)
    m.theme:SetFrameLevel(m.root:GetFrameLevel() + 3)
    m.theme:SetHeight(THEME_H)
    ns.SetKeyTip(m.theme, "barThemeTip")
    m.play = ns.MakeKitButton(m.root)
    m.play:SetFrameLevel(m.root:GetFrameLevel() + 3)
    m.play:SetWidth(PLAY_W)
    m.play:SetHeight(PLAY_H)
    m.play:SetPoint("TOP", m.root, "TOP", 0, -PLAY_TOP)
    ns.SetKeyText(m.play, "breaker.menuPlay")
    ns.SetFont(m.play.text, (m.play.text:GetFont()), 16, "")
    m.resume = ns.MakeKitButton(m.root)
    m.resume:SetFrameLevel(m.root:GetFrameLevel() + 3)
    m.resume:SetWidth(PAIR_W)
    m.resume:SetHeight(PLAY_H)
    ns.SetKeyText(m.resume, "breaker.menuResume")
    ns.SetFont(m.resume.text, (m.resume.text:GetFont()), 16, "")
    m.resume:Hide()
    return m
end
local function ensureView(canvas)
    if field then return end
    deco = ns.MakeTable(canvas, LOOK)
    field = ns.NewFrame("Frame", nil, canvas)
    field:SetFrameLevel(canvas:GetFrameLevel() + 1)
    field:Hide()
    local bg = field:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.Paint(bg, C_GROUT[1], C_GROUT[2], C_GROUT[3], C_GROUT[4])
    rim = ns.NewFrame("Frame", nil, canvas)
    rim:SetFrameLevel(canvas:GetFrameLevel() + 1)
    rim:SetBackdrop{ edgeFile = TEX_EDGE, edgeSize = 10 }
    rim:SetBackdropBorderColor(C_FRAME[1], C_FRAME[2], C_FRAME[3], C_FRAME[4])
    rim:Hide()
    tiles = {}
    edgeF = ns.NewFrame("Frame", nil, field)
    edgeF:SetAllPoints()
    edgeF:SetFrameLevel(field:GetFrameLevel() + 3)
    edges = {}
    hint = ns.NewFrame("Frame", nil, canvas)
    hint:SetFrameLevel(field:GetFrameLevel() + 4)
    hint:SetBackdrop{
        bgFile = ns.CARD_BACKDROP.bgFile,
        edgeFile = ns.CARD_BACKDROP.edgeFile,
        tile = true, tileSize = 16, edgeSize = HINT_EDGE,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    }
    hint:SetWidth(1)
    hint:SetHeight(1)
    hint.fs = hint:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bigFont(hint.fs, 20)
    hint.fs:SetPoint("TOPLEFT", hint, "TOPLEFT", HINT_PAD, -HINT_PAD)
    hint.sub = hint:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bigFont(hint.sub, 13)
    hint.sub:SetPoint("TOPLEFT", hint.fs, "BOTTOMLEFT", 1, -1)
    hint:Hide()
    ui = {}
    ui.root = ns.NewFrame("Frame", nil, canvas)
    ui.root:SetFrameLevel(canvas:GetFrameLevel() + 3)
    ui.root:SetAllPoints(canvas)
    ui.root:Hide()
    ui.panel = ns.MakeNiche(ui.root, 1, LOOK)
    ui.panel:SetPoint("TOPRIGHT", ui.root, "TOPRIGHT", -FIELD_PAD, -FIELD_PAD)
    ui.panel:SetPoint("BOTTOMRIGHT", ui.root, "BOTTOMRIGHT", -FIELD_PAD, FIELD_PAD)
    ui.panel:SetWidth(COL_W - FIELD_PAD * 2)
    ui.col = ns.PlainFrame(ui.panel, 1)
    ui.col:SetPoint("TOPRIGHT", ui.root, "TOPRIGHT", -COL_PAD, -COL_PAD)
    ui.col:SetPoint("BOTTOMRIGHT", ui.root, "BOTTOMRIGHT", -COL_PAD, COL_PAD)
    ui.col:SetWidth(COL_IN)
    ui.tally = ns.MakeScoreboard(ui.col, COL_IN)
    ui.tally:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, 0)
    local function statRow(y, capKey, big)
        local cap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -y)
        ns.SetKeyText(cap, capKey)
        cap:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
        local val = ui.col:CreateFontString(nil, "OVERLAY",
            big and "GameFontNormalLarge" or "GameFontNormal")
        val:SetJustifyH("RIGHT")
        val:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -y)
        return cap, val
    end
    ui.bestCap, ui.best = statRow(ROW * 4 + 6, "breaker.bestCap")
    ui.rule = ui.col:CreateTexture(nil, "ARTWORK")
    ns.Paint(ui.rule, C_RULE[1], C_RULE[2], C_RULE[3], C_RULE[4])
    ui.rule:SetHeight(1)
    ui.rule:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 5 + 4))
    ui.rule:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -(ROW * 5 + 4))
    ui.leftCap, ui.left = statRow(ROW * 5 + 26, "breaker.leftCap", true)
    local clearedCap, clearedVal = statRow(ROW * 5 + 26, "breaker.clearedCap")
    ui.clearedCap = clearedCap
    clearedCap:Hide()
    clearedVal:Hide()
    ui.barBg = ui.col:CreateTexture(nil, "ARTWORK")
    ns.Paint(ui.barBg, C_DARK[1], C_DARK[2], C_DARK[3], 1)
    ui.barBg:SetWidth(COL_IN)
    ui.barBg:SetHeight(4)
    ui.barBg:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -(ROW * 5 + 52))
    ui.bar = ui.col:CreateTexture(nil, "OVERLAY")
    ns.Paint(ui.bar, C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.85)
    ui.bar:SetHeight(4)
    ui.bar:SetPoint("TOPLEFT", ui.barBg, "TOPLEFT", 0, 0)
    ui.waveCap, ui.wave = statRow(ROW * 8 + 8, "breaker.waveCap")
    ui.seriesCap, ui.series = statRow(ROW * 9 + 8, "breaker.seriesCap")
    ui.back = ns.MakeKitButton(ui.col)
    ui.back:SetPoint("BOTTOMLEFT", ui.col, "BOTTOMLEFT", 0, 0)
    ui.back:SetWidth(COL_IN)
    ui.back:SetHeight(ROW)
    ns.SetKeyText(ui.back, "breaker.toMenu")
    ns.SetKeyTip(ui.back, "breaker.toMenuTip")
    ui.set = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.set:SetPoint("BOTTOMLEFT", ui.back, "TOPLEFT", 0, 8)
    ui.setCap = ui.col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.setCap:SetPoint("BOTTOMLEFT", ui.set, "TOPLEFT", 0, 4)
    ns.SetKeyText(ui.setCap, "breaker.setCap")
    ui.setCap:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
    menu = buildMenu(canvas)
    fx = ns.NewFrame("Frame", nil, canvas)
    fx:SetAllPoints()
    fx:SetFrameLevel(field:GetFrameLevel() + 20)
    fx:Hide()
    fx.f = {}
    for i = 1, FLOATS do
        local f = { fs = fx:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") }
        bigFont(f.fs, 20)
        f.fs:Hide()
        fx.f[i] = f
    end
    fx.next = 1
    fx.banner = fx:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bigFont(fx.banner, 32)
    fx.banner:Hide()
end
local function popFloat(x, y, text, tier, word)
    if not fx then return end
    local f = fx.f[fx.next]
    fx.next = fx.next % FLOATS + 1
    bigFont(f.fs, word and (tier.size - 8) or tier.size)
    f.fs:SetText(text)
    f.fs:SetTextColor(tierRGB(tier))
    f.fs:SetAlpha(1)
    f.fs:Show()
    f.x, f.y, f.t = x, y, 0
    f.fs:ClearAllPoints()
    f.fs:SetPoint("CENTER", fx, "BOTTOMLEFT", x, y)
end
local function stepFloats(dt)
    if not fx then return end
    for i = 1, FLOATS do
        local f = fx.f[i]
        if f.t then
            f.t = f.t + dt
            local k = f.t / FLOAT_LIFE
            if k >= 1 then
                f.t = nil
                f.fs:Hide()
            else
                f.fs:ClearAllPoints()
                f.fs:SetPoint("CENTER", fx, "BOTTOMLEFT", f.x, f.y + FLOAT_RISE * k)
                f.fs:SetAlpha(k < 0.7 and 1 or (1 - (k - 0.7) / 0.3))
            end
        end
    end
    if fx.bt then
        fx.bt = fx.bt + dt
        if fx.bt >= BANNER_LIFE then
            fx.bt = nil
            fx.banner:Hide()
        else
            local k = fx.bt / BANNER_LIFE
            fx.banner:SetAlpha(k < 0.6 and 1 or (1 - (k - 0.6) * 2.5))
        end
    end
end
local function banner(text, r, g, b)
    if not fx then return end
    fx.banner:SetText(text)
    fx.banner:SetTextColor(r, g, b)
    fx.banner:SetAlpha(1)
    fx.banner:Show()
    fx.bt = 0
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
local function idx(self, c, r)
    return (c - 1) * self.rows + r
end
function Game:Group(c, r)
    if self.gc == c and self.gr == r then return self.group end
    local out = {}
    local color = self.cell[c][r]
    if color then
        local seen = {}
        local head = 1
        out[1] = idx(self, c, r)
        seen[out[1]] = true
        while head <= #out do
            local i = out[head]
            head = head + 1
            local cc = floor((i - 1) / self.rows) + 1
            local rr = i - (cc - 1) * self.rows
            for k = 1, 4 do
                local nc, nr = cc + NB[k][1], rr + NB[k][2]
                if nc >= 1 and nc <= self.cols and nr >= 1 and nr <= self.rows
                   and self.cell[nc][nr] == color then
                    local ni = idx(self, nc, nr)
                    if not seen[ni] then
                        seen[ni] = true
                        out[#out + 1] = ni
                    end
                end
            end
        end
    end
    self.gc, self.gr, self.group = c, r, out
    return out
end
local function hasMove(self)
    for c = 1, self.cols do
        local col, right = self.cell[c], self.cell[c + 1]
        for r = 1, self.rows do
            local v = col[r]
            if v then
                if col[r + 1] == v then return true end
                if right and right[r] == v then return true end
            end
        end
    end
    return false
end
local function fill(self)
    for c = 1, self.cols do
        local col = self.cell[c]
        for r = 1, self.rows do
            col[r] = self.rng:Int(self.colors)
        end
    end
    self.left = self.cols * self.rows
end
local function refill(self)
    local added = 0
    local mark = {}
    for c = 1, self.cols do
        local col = self.cell[c]
        local h = 0
        for r = 1, self.rows do
            if not col[r] then
                col[r] = self.rng:Int(self.colors)
                h = h + 1
                mark[h] = idx(self, c, r)
            end
        end
        for j = 1, h do self.fresh[mark[j]] = h end
        added = added + h
    end
    self.left = self.left + added
    return added
end
local function pour(self)
    self.wave = self.wave + 1
    self.series = 0
    refill(self)
    self.poured = true
    return hasMove(self)
end
local function gravity(self)
    for c = 1, self.cols do
        local col, org = self.cell[c], self.org[c]
        local w = 0
        for r = 1, self.rows do
            if col[r] then
                w = w + 1
                if w ~= r then
                    col[w], col[r] = col[r], nil
                    org[w], org[r] = org[r], nil
                end
            end
        end
    end
end
local function packColumns(self)
    local w = 0
    for c = 1, self.cols do
        if self.cell[c][1] then
            w = w + 1
            if w ~= c then
                self.cell[w], self.cell[c] = self.cell[c], self.cell[w]
                self.org[w], self.org[c] = self.org[c], self.org[w]
            end
        end
    end
end
local function finish(self)
    if self.bonus then return end
    self.bonus = true
    self.over = true
end
local function apply(self, move, silent)
    if move.k ~= "pop" then return false end
    local c, r = move.c, move.r
    if type(c) ~= "number" or type(r) ~= "number" then return false end
    if c < 1 or c > self.cols or r < 1 or r > self.rows then return false end
    if not self.cell[c][r] then return false end
    if self.over then return false end
    local grp = self:Group(c, r)
    local n = #grp
    if n < MIN_GROUP then return false end
    local colour = self.cell[c][r]
    local base = n * (n - 1)
    if n >= BIG then
        self.series = self.series + 1
    else
        self.series = 0
    end
    local extra = 0
    if self.series >= 2 then
        extra = SERIES_PT * min(self.series - 1, SERIES_CAP)
    end
    self.score = self.score + base + extra
    self.left = self.left - n
    self.cleared = self.cleared + n
    self.moved = self.moved + 1
    if not silent then
        local snap = self.snap
        for cc = 1, self.cols do
            local col = self.cell[cc]
            for rr = 1, self.rows do
                snap[idx(self, cc, rr)] = col[rr]
            end
        end
        self.fadeSet = grp
        local sx, sy = 0, 0
        for i = 1, n do
            local cc = floor((grp[i] - 1) / self.rows) + 1
            local rr = grp[i] - (cc - 1) * self.rows
            sx = sx + (cc - 0.5) * self.step
            sy = sy + (rr - 0.5) * self.step
        end
        self.pop = { n = n, base = base, extra = extra,
                     x = self.ox + sx / n, y = self.oy + sy / n }
        local tex = self:Gem(colour)
        local cells = {}
        for i = 1, n do
            local cc = floor((grp[i] - 1) / self.rows) + 1
            local rr = grp[i] - (cc - 1) * self.rows
            cells[i] = { x = self.ox + (cc - 0.5) * self.step,
                         y = self.oy + (rr - 0.5) * self.step,
                         size = self.step - GAP, tex = tex }
        end
        local loud = (n >= BIG or self.series >= 2)
        ns.FX.Stop()
        ns.FX.Play(self.canvas, cells, { big = loud })
        ns.Sfx.Play(self.left <= 0 and "clear" or (loud and "big" or "pop"))
    end
    for cc = 1, self.cols do
        local col, org = self.cell[cc], self.org[cc]
        for rr = 1, self.rows do
            org[rr] = col[rr] and (cc * PACK + rr) or nil
        end
    end
    for i = 1, n do
        local cc = floor((grp[i] - 1) / self.rows) + 1
        local rr = grp[i] - (cc - 1) * self.rows
        self.cell[cc][rr] = nil
        self.org[cc][rr] = nil
    end
    gravity(self)
    packColumns(self)
    self.poured = false
    for k in pairs(self.fresh) do self.fresh[k] = nil end
    self.justClear = self.left <= 0
    if self.justClear then
        self.score = self.score + BONUS_CLEAR
    end
    if self.mode == MODE_TIME then refill(self) end
    if not hasMove(self) then
        local more = self.mode == MODE_WAVES and self.wave < self.waves
        if not more or not pour(self) then finish(self) end
    end
    self.gc, self.gr, self.group = nil, nil, nil
    self.hc, self.hr = nil, nil
    if not silent then
        local slide = self.slide
        for k in pairs(slide) do slide[k] = nil end
        for cc = 1, self.cols do
            local org = self.org[cc]
            for rr = 1, self.rows do
                local from = org[rr]
                if from and from ~= cc * PACK + rr then
                    slide[idx(self, cc, rr)] = from
                end
            end
        end
    end
    return true
end
function Game:Start(seed, moves)
    if preKeep then preKeep = nil else preDeck = nil end
    local o = self.opts
    local size = o and o.size or DEFAULT_SIZE
    if type(size) ~= "number" then size = DEFAULT_SIZE end
    size = max(MIN_SIZE, min(MAX_SIZE, size))
    local mode = o and o.mode or DEFAULT_MODE
    if mode ~= MODE_TIME and mode ~= MODE_WAVES then mode = MODE_CLASSIC end
    self.opts = { size = size, mode = mode }
    self.mode = mode
    self.cols, self.rows = size, size
    self.colors = colorsFor(size)
    self.rng = ns.RNG.New(seed)
    local pick = ns.RNG.New(seed)
    self.shelf, self.shelfKey = {}, {}
    for i, sh in ipairs(ns.Shelves.Deal("breaker", self.colors, pick)) do
        self.shelf[i] = ns.Shelves.Pick("breaker", sh.key, pick)
        self.shelfKey[i] = sh.key
    end
    self.score, self.left, self.moved = 0, 0, 0
    self.cleared = 0
    self.playT = 0
    self.waves = wavesFor(size)
    self.series, self.wave, self.justClear = 0, 1, false
    self.over, self.bonus, self.timeUp, self.ended = false, false, false, false
    self.phase, self.pt, self.endT = "idle", 0, 0
    self.fallDur = FALL
    self.t = TIME_LIMIT
    self.cell, self.org = {}, {}
    self.snap, self.slide, self.fresh, self.gem = {}, {}, {}, {}
    self.mark = {}
    self.hw, self.hh = 1, 1
    self.gc, self.gr, self.group = nil, nil, nil
    self.hc, self.hr, self.pop = nil, nil, nil
    for c = 1, self.cols do
        self.cell[c] = {}
        self.org[c] = {}
    end
    self.step = stepFor(size, self.canvas)
    for i = 1, self.colors do
        if not self.shelf[i] then
            local id = ns.itemSets.gems[i]
            if id then ns.Compat.ItemInfo(id) end
        end
    end
    for _ = 1, 8 do
        fill(self)
        if hasMove(self) then break end
    end
    if not hasMove(self) then finish(self) end
    if moves then
        for i = 1, #moves do apply(self, moves[i], true) end
        local rec = ns.Store.Load(ID, self.opts)
        local was = rec and rec.elapsed
        if type(was) == "number" then self.playT = was end
        if mode == MODE_TIME and type(was) == "number" then
            self.t = TIME_LIMIT - was
            if self.t <= 0 then
                self.t, self.timeUp = 0, true
                finish(self)
            end
        end
    end
    ensureView(self.canvas)
    local fw, fh = self.cols * self.step, self.rows * self.step
    self.zoneW = (self.canvas.W or 640) - COL_W
    self.ox = floor((self.zoneW - fw) / 2)
    self.oy = floor((self.canvas.H - fh) / 2)
    field:ClearAllPoints()
    field:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", self.ox, self.oy)
    field:SetWidth(fw)
    field:SetHeight(fh)
    rim:ClearAllPoints()
    rim:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", -RIM, -RIM)
    rim:SetPoint("TOPRIGHT", field, "TOPRIGHT", RIM, RIM)
    self.rimOn = (fw + RIM * 2 <= self.zoneW) and (fh + RIM * 2 <= self.canvas.H)
    deco:Show()
    fx.banner:ClearAllPoints()
    fx.banner:SetPoint("CENTER", fx, "BOTTOMLEFT", self.ox + fw / 2, self.oy + fh / 2)
    fx.banner:Hide()
    fx.bt = nil
    self.menu = true
    local best = ns.Records.Best(ID, self.opts)
    self.best = best and best.score or nil
    local me = self
    ui.back.onClick = function() me:ToMenu() end
    self:SyncMenu()
    self:Draw()
end
function Game:Move(move)
    if not apply(self, move, false) then return false end
    local drop = 0
    for _, h in pairs(self.fresh) do
        if h > drop then drop = h end
    end
    self.phase, self.pt = "fade", 0
    self.fallDur = FALL + min(FALL_CAP, drop * FALL_PER)
    self:Layout(self.snap)
    self:HideHover()
    self:ShowPop()
    self:Panel()
    return true
end
function Game:ShowPop()
    local p = self.pop
    if not p then return end
    local tier = tierFor(p.n)
    popFloat(p.x, p.y, "+" .. (p.base + p.extra), tier)
    if p.extra > 0 then
        popFloat(p.x, p.y - 22, ns.T("breaker.floatSeriesFmt", self.series), TIERS[1], true)
    elseif tier.word then
        popFloat(p.x, p.y - 22, ns.TL(tier.word), tier, true)
    end
    if self.justClear then
        banner(ns.T("breaker.cleanBannerFmt", BONUS_CLEAR), 0.35, 1, 0.45)
    elseif self.poured then
        banner(ns.T("breaker.waveOfFmt", self.wave, self.waves), 1, 0.82, 0)
    end
end
function Game:EndFlash()
    self.ended = true
    self:HideHover()
    ns.Sfx.Play("over")
    for c = 1, self.cols do
        for r = 1, self.rows do
            if self.cell[c][r] then
                tiles[idx(self, c, r)].ic:SetAlpha(0.3)
            end
        end
    end
    if self.left <= 0 then
        banner(ns.T("breaker.bannerFieldClean"), 0.35, 1, 0.45)
    elseif self.timeUp then
        banner(ns.T("breaker.bannerTimeUp"), 1, 0.45, 0.35)
    elseif self.mode == MODE_WAVES then
        banner(ns.T("breaker.bannerWavesOver"), 1, 0.82, 0)
    else
        banner(ns.T("breaker.bannerNoMoves"), 1, 0.82, 0)
    end
    self:Panel()
end
function Game:Update(dt)
    if self.menu then return end
    self.playT = self.playT + dt
    stepFloats(dt)
    if self.mode == MODE_TIME and not self.timeUp and not self.over then
        self.t = self.t - dt
        if self.t <= 0 then
            self.t = 0
            self.timeUp = true
            finish(self)
        end
    end
    if self.phase == "fade" then
        self.pt = self.pt + dt
        if self.pt >= FADE then
            self.phase, self.pt = "fall", 0
            self:Layout(nil)
            self:Slide(0)
            self:Fresh(0)
        else
            local a = 1 - self.pt / FADE
            for i = 1, #self.fadeSet do
                tiles[self.fadeSet[i]].ic:SetAlpha(a)
            end
        end
    elseif self.phase == "fall" then
        self.pt = self.pt + dt
        if self.pt >= self.fallDur then
            self.phase = "idle"
            self:Draw()
        else
            local k = self.pt / self.fallDur
            self:Slide(k * k)
            self:Fresh(k * k)
        end
    elseif self.over then
        if not self.ended then self:EndFlash() end
        self.endT = self.endT + dt
    else
        self:Hover()
    end
end
function Game:Score()
    return self.score
end
function Game:Clock()
    if self.mode == MODE_TIME then
        return ns.Records.Span(self.t), self.t <= 10
    end
    return ns.Records.Span(self.playT)
end
function Game:Marks()
    return { time = self.playT, cleared = self.cleared }
end
function Game:Elapsed()
    return self.playT
end
function Game:IsOver()
    if self.phase ~= "idle" then return false end
    if not self.over then return false end
    return self.endT >= END_FLASH
end
function Game:Stop()
    if field then field:Hide() end
    if deco then deco:Hide() end
    if rim then rim:Hide() end
    if ui then ui.root:Hide() end
    if menu then menu.root:Hide() end
    if fx then
        fx:Hide()
        for i = 1, FLOATS do
            fx.f[i].t = nil
            fx.f[i].fs:Hide()
        end
        fx.bt = nil
        fx.banner:Hide()
    end
    if hint then hint:Hide() end
    if edges then edgesHide() end
    self.hlOn = nil
end
function Game:Stage(n)
    n = max(1, floor(n))
    if self.mode == MODE_WAVES then n = min(n, self.waves) end
    self.wave = n - 1
    pour(self)
end
function Game:CellAt(x, y)
    if x < 0 or y < 0 then return nil end
    local step = self.step
    local c = floor(x / step) + 1
    local r = floor(y / step) + 1
    if c < 1 or c > self.cols or r < 1 or r > self.rows then return nil end
    return c, r
end
function Game:Click(x, y)
    if self.menu then return end
    if self.phase ~= "idle" then return end
    if self.over then return end
    local c, r = self:CellAt(x - self.ox, y - self.oy)
    if not c then return end
    if not self.cell[c][r] then return end
    if #self:Group(c, r) < MIN_GROUP then return end
    self:Move{ k = "pop", c = c, r = r }
end
function Game:Cursor()
    if not field:IsShown() then return nil end
    local scale = field:GetEffectiveScale()
    local l, b = field:GetLeft(), field:GetBottom()
    if not scale or scale == 0 or not l or not b then return nil end
    local x, y = GetCursorPosition()
    x, y = x / scale - l, y / scale - b
    local c, r = self:CellAt(x, y)
    return c, r, x, y
end
function Game:Hover()
    if self.menu then return end
    if ns.Help.IsShown() then
        if self.hc then self:HideHover() end
        return
    end
    local c, r, x, y = self:Cursor()
    if c and self.cell[c][r] then
        if c ~= self.hc or r ~= self.hr then
            self.hc, self.hr = c, r
            local color = self.cell[c][r]
            local grp = self:Group(c, r)
            local n = #grp
            if n >= MIN_GROUP then
                self:ShowHover(grp, color)
                local tier = tierFor(n)
                local qr, qg, qb = tierRGB(tier)
                bigFont(hint.fs, max(20, tier.size - 2))
                hint.fs:SetText("+" .. n * (n - 1))
                hint.fs:SetTextColor(qr, qg, qb)
                local sub
                if n >= BIG and self.series >= 1 then
                    sub = ns.T("breaker.hoverGroupSeriesFmt", n, self.series + 1)
                else
                    sub = ns.T("breaker.hoverGroupFmt", n)
                end
                hint.sub:SetText(sub)
                hint.sub:SetTextColor(qr, qg, qb)
                local cr, cg, cb = self:Tint(color)
                hint:SetBackdropColor(cr * HINT_BG_MIX, cg * HINT_BG_MIX,
                                      cb * HINT_BG_MIX, HINT_BG_A)
                hint:SetBackdropBorderColor(cr, cg, cb, 0.9)
                self.hw = max(hint.fs:GetStringWidth(), hint.sub:GetStringWidth())
                          + HINT_PAD * 2
                self.hh = hint.fs:GetStringHeight() + hint.sub:GetStringHeight()
                          + 1 + HINT_PAD * 2
                hint:SetWidth(self.hw)
                hint:SetHeight(self.hh)
                hint:Show()
            else
                self:ShowHover(nil)
                hint:Hide()
            end
        end
        if self.hlOn then
            local hx = x + self.ox + 16
            local hy = y + self.oy + 16
            if hx + self.hw > self.zoneW then hx = self.zoneW - self.hw end
            if hy + self.hh > self.canvas.H then hy = self.canvas.H - self.hh end
            hint:ClearAllPoints()
            hint:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", hx, hy)
        end
    elseif self.hc then
        self:HideHover()
    end
end
function Game:HideHover()
    self.hc, self.hr = nil, nil
    self:ShowHover(nil)
    if hint then hint:Hide() end
end
function Game:PaintSlot(i)
    local s = menu.slot[i]
    local chosen = (self.opts.size == SIZES[i])
    local hot = (menu.hover == i)
    s.plate:Tone(chosen)
    local edge = chosen and C_GOLD or C_FRAME
    s.win:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
    local name = chosen and C_GOLD or C_TEXT
    local sub = (chosen or hot) and C_SOFT or C_DIM
    s.name:SetTextColor(name[1], name[2], name[3])
    s.sub:SetTextColor(sub[1], sub[2], sub[3])
end
function Game:SyncTip()
    local mo = MODES[menu.tipMode or 0]
    if not mo then
        for i = 1, #MODES do
            if MODES[i].key == self.opts.mode then mo = MODES[i] end
        end
    end
    menu.tip:SetText(mo and ns.TL(mo.tip) or "")
end
function Game:SyncMenu()
    local me = self
    local pre = previewDeck()
    for i = 1, #SIZES do
        local s, size = menu.slot[i], SIZES[i]
        local colors = colorsFor(size)
        s.name:SetText(size .. "x" .. size)
        s.sub:SetText(ns.T("breaker.slotSub" .. size))
        local rec = ns.Records.Best(ID, { size = size, mode = self.opts.mode })
        local sc = rec and rec.score
        if sc then
            s.rec:SetText(ns.T("breaker.menuRecFmt", ns.Records.Format(nil, sc)))
            s.rec:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
        else
            s.rec:SetText(ns.T("breaker.menuNoRec"))
            s.rec:SetTextColor(C_DIM[1], C_DIM[2], C_DIM[3])
        end
        s.plate.tipTitle = size .. "x" .. size
        s.plate.tip = ns.T("breaker.sizeTipFmt", size, size, colors)
        s.plate.onPick = function() me:PickSize(i) end
        s.plate.onHover = function(on)
            if on then
                menu.hover = i
            elseif menu.hover == i then
                menu.hover = nil
            end
            me:PaintSlot(i)
        end
        local step = stepFor(size, self.canvas)
        local cells = floor(WIN_SIDE / step)
        local off = floor((WIN_SIDE - cells * step) / 2)
        local k = 0
        for c = 1, cells do
            for r = 1, cells do
                k = k + 1
                local t = s.tile[k]
                if not t then
                    t = s.deck:CreateTexture(nil, "ARTWORK")
                    s.tile[k] = t
                end
                local color = previewColor(i, c, r, colors)
                t:SetTexture(pre[color] and ns.IconPath(pre[color])
                             or ns.Icons.Gem(color))
                ns.CropIcon(t)
                t:SetWidth(step - GAP)
                t:SetHeight(step - GAP)
                t:ClearAllPoints()
                t:SetPoint("BOTTOMLEFT", s.deck, "BOTTOMLEFT",
                    off + (c - 1) * step + GAP / 2, off + (r - 1) * step + GAP / 2)
                t:Show()
            end
        end
        for j = k + 1, #s.tile do s.tile[j]:Hide() end
        self:PaintSlot(i)
    end
    for i = 1, #MODES do
        local b, mo = menu.mode[i], MODES[i]
        b.onClick = function() me:PickMode(mo.key) end
    end
    menu.paintMode = function()
        for i = 1, #MODES do
            local b = menu.mode[i]
            local on = (MODES[i].key == me.opts.mode)
            b:Tone(on)
            local c = on and C_GOLD or C_TEXT
            b.name:SetTextColor(c[1], c[2], c[3])
        end
    end
    menu.paintMode()
    local themes = {}
    for _, t in ipairs(ns.Shelves.Themes(ID)) do
        if ns.Shelves.Filled(ID, t.key) then
            themes[#themes + 1] = { key = t.key, label = t.label }
        end
    end
    if #themes < 2 then
        menu.themeCap:Hide()
        menu.theme:Hide()
    else
        menu.theme:SetOptions(themes, ns.Shelves.Theme(ID), ns.T("barTheme"))
        local selW = menu.theme:FitWidth()
        menu.theme:SetWidth(selW)
        local capW = menu.themeCap:GetStringWidth() or 0
        menu.theme:ClearAllPoints()
        menu.theme:SetPoint("TOP", menu.root, "TOP", (capW + THEME_GAP) / 2, -THEME_TOP)
        menu.themeCap:ClearAllPoints()
        menu.themeCap:SetPoint("RIGHT", menu.theme, "LEFT", -THEME_GAP, 0)
        menu.themeCap:Show()
        menu.theme:Show()
        menu.theme.onPick = function(key)
            if key == ns.Shelves.Theme(ID) then return end
            ns.Shelves.SetTheme(ID, key)
            me:Restart{ size = me.opts.size, mode = me.opts.mode }
        end
    end
    menu.onTip = function() me:SyncTip() end
    if self:Started() then
        menu.play:SetWidth(PAIR_W)
        menu.play:ClearAllPoints()
        menu.play:SetPoint("TOPRIGHT", menu.root, "TOP", -PAIR_GAP / 2, -PLAY_TOP)
        menu.play.tip = ns.T("breaker.menuFreshTip")
        menu.play.onClick = function() ns.window:Restart() end
        menu.resume:ClearAllPoints()
        menu.resume:SetPoint("TOPLEFT", menu.root, "TOP", PAIR_GAP / 2, -PLAY_TOP)
        menu.resume.tip = ns.T("breaker.menuResumeTip")
        menu.resume.onClick = function() me:BeginRound() end
        menu.resume:Show()
    else
        menu.play:SetWidth(PLAY_W)
        menu.play:ClearAllPoints()
        menu.play:SetPoint("TOP", menu.root, "TOP", 0, -PLAY_TOP)
        menu.play.tip = ns.T("breaker.menuPlayTip")
        menu.play.onClick = function()
            if me.over then me:Restart(me.opts) else me:BeginRound() end
        end
        menu.resume:Hide()
    end
    self:SyncTip()
end
function Game:Relocalize()
    if not menu then return end
    self:SyncMenu()
end
function Game:Started()
    return self.moved > 0 and not self.over
end
function Game:Switch(opts)
    if not self.menu then return end
    if ns.Loop.Current() ~= self then return end
    preKeep = true
    ns.window:SaveCurrent()
    ns.window:StartGame(ID, opts, true)
end
function Game:PickSize(i)
    if SIZES[i] == self.opts.size then return end
    self:Switch({ size = SIZES[i], mode = self.opts.mode })
end
function Game:PickMode(key)
    if key == self.opts.mode then return end
    self:Switch({ size = self.opts.size, mode = key })
end
function Game:Restart(opts, keep)
    if ns.Loop.Current() ~= self then return end
    preKeep = keep or nil
    if self:Started() then
        ns.window:Restart(opts)
        return
    end
    ns.Store.Clear(ID, opts)
    ns.window:StartGame(ID, opts)
end
function Game:BeginRound()
    if not self.menu then return end
    self.menu = false
    self:Draw()
end
function Game:ToMenu()
    if self.menu then return end
    if not self:Started() then
        self.t, self.playT = TIME_LIMIT, 0
    end
    self.menu = true
    self:SyncMenu()
    self:Draw()
end
function Game:Tint(color)
    local name = self.shelf and self.shelf[color or 0]
    if name then
        local r, g, b = ns.Shelves.Tint(name)
        if r then return r, g, b end
        local t = self.shelfKey and ns.Shelves.ShelfTint(ID, self.shelfKey[color or 0])
        if t then return t[1], t[2], t[3] end
        return NEUTRAL[1], NEUTRAL[2], NEUTRAL[3]
    end
    return ns.Palette.RGB(color or 0)
end
function Game:Gem(color)
    local own = self.shelf and self.shelf[color]
    if own then return ns.IconPath(own) end
    local t = self.gem[color]
    if t and t ~= ns.Icons.QMARK then return t end
    t = ns.Icons.Gem(color)
    self.gem[color] = t
    return t
end
function Game:Layout(snap)
    local step = self.step
    local size = step - GAP
    local half = GAP / 2
    for c = 1, self.cols do
        local col = self.cell[c]
        for r = 1, self.rows do
            local i = idx(self, c, r)
            local color
            if snap then color = snap[i] else color = col[r] end
            local t = tileAt(i)
            local x, y = (c - 1) * step + half, (r - 1) * step + half
            t.hl:Hide()
            if color then
                local tex = self:Gem(color)
                if t.cur ~= tex then
                    t.cur = tex
                    t.ic:SetTexture(tex)
                end
                ns.CropIcon(t.ic)
                t.ic:SetWidth(size)
                t.ic:SetHeight(size)
                t.ic:ClearAllPoints()
                t.ic:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", x, y)
                t.ic:SetAlpha(1)
                t.ic:Show()
                t.hl:SetWidth(size)
                t.hl:SetHeight(size)
                t.hl:ClearAllPoints()
                t.hl:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", x, y)
            else
                t.ic:Hide()
            end
        end
    end
    for i = self.cols * self.rows + 1, #tiles do
        tiles[i].ic:Hide()
        tiles[i].hl:Hide()
    end
    edgesHide()
    self.hlOn = nil
end
function Game:ShowHover(grp, color)
    if self.hlOn then
        for i = 1, #self.hlOn do tiles[self.hlOn[i]].hl:Hide() end
    end
    edgesHide()
    self.hlOn = grp
    if not grp then return end
    local cr, cg, cb = self:Tint(color)
    local set = self.mark
    for k in pairs(set) do set[k] = nil end
    for i = 1, #grp do
        set[grp[i]] = true
        local hl = tiles[grp[i]].hl
        ns.Paint(hl, cr, cg, cb, 1)
        hl:Show()
    end
    local step = self.step
    local size = step - GAP
    local half = GAP / 2
    local w = step >= 52 and 2 or 1
    local function line(x, y, ww, hh)
        local e = edgeAt()
        ns.Paint(e, cr, cg, cb, EDGE_A)
        e:SetWidth(ww)
        e:SetHeight(hh)
        e:ClearAllPoints()
        e:SetPoint("BOTTOMLEFT", edgeF, "BOTTOMLEFT", x, y)
        e:Show()
    end
    local function has(c, r)
        if c < 1 or c > self.cols or r < 1 or r > self.rows then return false end
        return set[idx(self, c, r)] == true
    end
    local function ext(nb, draws)
        if not nb then return 0 end
        return draws and half or (half + w)
    end
    for i = 1, #grp do
        local c = floor((grp[i] - 1) / self.rows) + 1
        local r = grp[i] - (c - 1) * self.rows
        local x, y = (c - 1) * step + half, (r - 1) * step + half
        local L, R = has(c - 1, r), has(c + 1, r)
        local D, U = has(c, r - 1), has(c, r + 1)
        local DL, DR = has(c - 1, r - 1), has(c + 1, r - 1)
        local UL, UR = has(c - 1, r + 1), has(c + 1, r + 1)
        if not L then
            local a, b = ext(D, not DL), ext(U, not UL)
            line(x, y - a, w, size + a + b)
        end
        if not R then
            local a, b = ext(D, not DR), ext(U, not UR)
            line(x + size - w, y - a, w, size + a + b)
        end
        if not D then
            local a, b = ext(L, not DL), ext(R, not DR)
            line(x - a, y, size + a + b, w)
        end
        if not U then
            local a, b = ext(L, not UL), ext(R, not UR)
            line(x - a, y + size - w, size + a + b, w)
        end
    end
end
function Game:Slide(k)
    local step = self.step
    local half = GAP / 2
    for i, from in pairs(self.slide) do
        local c = floor((i - 1) / self.rows) + 1
        local r = i - (c - 1) * self.rows
        local fc = floor(from / PACK)
        local fr = from - fc * PACK
        local x0, y0 = (fc - 1) * step, (fr - 1) * step
        local x1, y1 = (c - 1) * step, (r - 1) * step
        local t = tiles[i]
        t.ic:ClearAllPoints()
        t.ic:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT",
            x0 + (x1 - x0) * k + half, y0 + (y1 - y0) * k + half)
    end
end
function Game:Fresh(k)
    local step = self.step
    local size = step - GAP
    local half = GAP / 2
    local top = self.rows * step
    local cl, cr, ct, cb = ns.CELL_CROP[1], ns.CELL_CROP[2], ns.CELL_CROP[3], ns.CELL_CROP[4]
    for i, h in pairs(self.fresh) do
        local c = floor((i - 1) / self.rows) + 1
        local r = i - (c - 1) * self.rows
        local x = (c - 1) * step + half
        local y0 = (r - 1) * step + half
        local y = y0 + h * step * (1 - k)
        local t = tiles[i]
        if y >= top then
            t.ic:Hide()
        else
            local seen = min(size, top - y)
            t.ic:SetWidth(size)
            t.ic:SetHeight(seen)
            t.ic:SetTexCoord(cl, cr, cb - (cb - ct) * (seen / size), cb)
            t.ic:ClearAllPoints()
            t.ic:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", x, y)
            t.ic:SetAlpha(1)
            t.ic:Show()
        end
    end
end
function Game:Panel()
    ui.best:SetText(ns.Records.Format(nil, self.best))
    ui.set:SetText(self.cols .. "x" .. self.rows .. "   " .. modeLabel(self.mode))
    local timed = self.mode == MODE_TIME
    if timed then
        ui.leftCap:Hide()
        ui.clearedCap:Show()
    else
        ui.clearedCap:Hide()
        ui.leftCap:Show()
    end
    ui.left:SetText(tostring(timed and self.cleared or self.left))
    local done = timed and 0 or (1 - self.left / (self.cols * self.rows))
    if done <= 0 then
        ui.bar:Hide()
    else
        ui.bar:SetWidth(max(1, floor(COL_IN * done)))
        ui.bar:Show()
    end
    if timed then ui.barBg:Hide() else ui.barBg:Show() end
    if self.mode == MODE_WAVES then
        ui.waveCap:Show()
        ui.wave:Show()
        ui.wave:SetText(ns.T("breaker.waveOfValFmt", self.wave, self.waves))
    else
        ui.waveCap:Hide()
        ui.wave:Hide()
    end
    ui.series:SetText(ns.T("breaker.seriesValFmt", max(1, self.series)))
    if self.series >= 2 then
        ui.series:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
    else
        ui.series:SetTextColor(C_DIM[1], C_DIM[2], C_DIM[3])
    end
end
function Game:PanelSync()
    if not ui then return end
    if self.menu then
        ui.tally:Hide()
        return
    end
    ui.tally:Show()
    ui.tally:Sync()
end
function Game:Draw()
    if self.menu then
        field:Hide()
        rim:Hide()
        fx:Hide()
        ui.root:Hide()
        menu.root:Show()
        return
    end
    menu.root:Hide()
    field:Show()
    fx:Show()
    ui.root:Show()
    if self.rimOn then rim:Show() else rim:Hide() end
    self:Layout(nil)
    self:Panel()
end
local MINI_BACK   = { 0.04, 0.04, 0.05 }
local MINI_BLUE   = { 0.25, 0.60, 1.00 }
local MINI_RED    = { 0.95, 0.25, 0.30 }
local MINI_YELLOW = { 1.00, 0.88, 0.25 }
local MINI_GOLD   = { 1.00, 0.82, 0.00 }
local MINI = {
    {
        cols = 5, rows = 5, cell = 22, gap = 2, back = "plain",
        fill = {
            { c = 2, r = 2, col = MINI_BLUE }, { c = 3, r = 2, col = MINI_BLUE },
            { c = 2, r = 3, col = MINI_BLUE }, { c = 3, r = 3, col = MINI_BLUE },
            { c = 4, r = 4, col = MINI_BLUE },
        },
        ring = {
            { c = 2, r = 2 }, { c = 3, r = 2 }, { c = 2, r = 3 }, { c = 3, r = 3 },
        },
    },
    {
        cols = 3, rows = 5, cell = 22, gap = 2, back = "plain",
        fill = {
            { c = 2, r = 5, col = MINI_BLUE },
            { c = 1, r = 1, col = MINI_RED }, { c = 3, r = 1, col = MINI_YELLOW },
        },
        arrow = { { c1 = 2, r1 = 5, c2 = 2, r2 = 1, col = MINI_GOLD } },
    },
    {
        cols = 5, rows = 3, cell = 22, gap = 2, back = "plain",
        fill = {
            { c = 1, r = 1, col = MINI_RED }, { c = 1, r = 2, col = MINI_RED }, { c = 1, r = 3, col = MINI_RED },
            { c = 2, r = 1, col = MINI_YELLOW }, { c = 2, r = 2, col = MINI_YELLOW }, { c = 2, r = 3, col = MINI_YELLOW },
            { c = 4, r = 1, col = MINI_BLUE }, { c = 4, r = 2, col = MINI_BLUE }, { c = 4, r = 3, col = MINI_BLUE },
            { c = 5, r = 1, col = MINI_RED }, { c = 5, r = 2, col = MINI_RED }, { c = 5, r = 3, col = MINI_RED },
        },
        arrow = {
            { c1 = 4, r1 = 2, c2 = 3, r2 = 2, col = MINI_GOLD },
            { c1 = 5, r1 = 2, c2 = 4, r2 = 2, col = MINI_GOLD },
        },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_BACK)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpArtGroup(host) paintMini(host, MINI[1]) end
local function helpArtFall(host) paintMini(host, MINI[2]) end
local function helpArtShift(host) paintMini(host, MINI[3]) end
ns.RegisterGame{
    id = ID,
    label = "breaker.label",
    icon = 40111,
    tip = "breaker.tip",
    order = 3,
    duo = "score",
    look = LOOK,
    physics = false,
    fx = true,
    done = true,
    ownPanel = true,
    saves = { "size", "mode" },
    New = New,
    opts = {
        { key = "size", label = "breaker.optSizeLabel", def = DEFAULT_SIZE, ordered = true,
          options = SIZE_OPTS, tip = "breaker.optSizeTip" },
        { key = "mode", label = "breaker.optModeLabel", def = DEFAULT_MODE, options = MODES,
          tip = "breaker.optModeTip" },
    },
    record = {
        { key = "score",   label = "breaker.recScore", by = "max", mark = "token" },
        { key = "cleared", label = "breaker.recCleared", by = "max", mark = "heap" },
        { key = "time",    label = "breaker.recTime", by = "min", mark = "clock", format = "span" },
    },
    stages = { max = 999 },
    controls = {
        { action = "pop", label = "breaker.ctlPop", mouse = "LMB", where = "breaker.ctlOnGroup" },
    },
    help = function(opts)
        local mode = opts and opts.mode or DEFAULT_MODE
        local size = opts and opts.size or DEFAULT_SIZE
        local tail
        if mode == MODE_TIME then
            tail = ns.T("breaker.helpModeTimeTail")
        elseif mode == MODE_WAVES then
            tail = ns.T("breaker.helpModeWavesTailFmt", wavesFor(size))
        else
            tail = ns.T("breaker.helpModeClassicTail")
        end
        return {
            ns.T("breaker.helpGroup"),
            { art = helpArtGroup, h = 126 },
            ns.T("breaker.helpFall"),
            { art = helpArtFall, h = 126 },
            ns.T("breaker.helpShift"),
            { art = helpArtShift, h = 78 },
            ns.T("breaker.helpShiftSub"),
            ns.T("breaker.helpScore"),
            ns.T("breaker.helpStreak"),
            ns.T("breaker.helpClear"),
            tail,
        }
    end,
}
