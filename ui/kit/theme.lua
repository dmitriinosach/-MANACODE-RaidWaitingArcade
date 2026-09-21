local ADDON, ns = ...
ns.Space = {
    pad   = 14,
    gap   = 12,
    inset = 12,
    row   = 6,
    cap   = 26,
    ctl   = 22,
}
local ACCENT = { 0.22, 0.72, 0.32 }
local ATTN   = { 1, 0.82, 0 }
ns.ACCENT = ACCENT
ns.ATTN   = ATTN
ns.LINK   = { 0.4, 0.85, 1.0 }
ns.QMARK  = "Interface\\Icons\\INV_Misc_QuestionMark"
local PRIMARY   = { 0.9, 0.9, 0.9 }
local SECONDARY = { 0.75, 0.75, 0.75 }
local DIMMED    = { 0.45, 0.45, 0.45 }
local NOTE      = { 0.6, 0.6, 0.6 }
local NICHE_CAP = { 0.54, 0.51, 0.45 }
local WHITE     = { 1, 1, 1 }
local TIP_BG     = "Interface\\Tooltips\\UI-Tooltip-Background"
local TIP_EDGE   = "Interface\\Tooltips\\UI-Tooltip-Border"
local DLG_DARK   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
local DLG_PAPER  = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DLG_GOLD   = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local DLG_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"
local PARCH      = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
local WOOD       = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder"
local ACH_BG     = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local STONE      = "Interface\\ItemTextFrame\\ItemText-Stone-TopLeft"
local WEAVE      = "Interface\\AddOns\\HTP_Arcade\\art\\weave_%s.tga"
local DRAGON     = "Interface\\AchievementFrame\\UI-Achievement-StatsBackground"
local PAPER_OLD  = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal-Desaturated"
local STONE_CROP = { 0.03125, 1, 0.046875, 1 }
local DLG_INSET  = { left = 7, right = 8, top = 8, bottom = 7 }
local TIP_INSET  = { left = 4, right = 4, top = 4, bottom = 4 }
ns.CARD_BACKDROP = {
    bgFile = TIP_BG, edgeFile = TIP_EDGE,
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
}
ns.INFO_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = TIP_EDGE,
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local BUTTON_BACKDROP = {
    bgFile = TIP_BG, edgeFile = TIP_EDGE,
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local TILE_BACKDROP = {
    bgFile = TIP_BG, edgeFile = TIP_EDGE,
    tile = true, tileSize = 16, edgeSize = 14,
    insets = TIP_INSET,
}
local function panelBackdrop(edgeFile)
    return {
        bgFile = TIP_BG, edgeFile = edgeFile,
        tile = true, tileSize = 16, edgeSize = 14,
        insets = TIP_INSET,
    }
end
local function clamp(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end
local function tone(c, k, a)
    return { clamp(c[1] * k), clamp(c[2] * k), clamp(c[3] * k), a }
end
local function rgba(c, a)
    return { c[1], c[2], c[3], a }
end
local function lift(c, top)
    local m = c[1]
    if c[2] > m then m = c[2] end
    if c[3] > m then m = c[3] end
    if m <= 0 then return { top, top, top } end
    return tone(c, top / m)
end
local function buttonSkin(w)
    local metal = lift(w, 0.82)
    local dusk  = lift(w, 0.22)
    return {
        backdrop     = BUTTON_BACKDROP,
        bg           = tone(dusk, 0.55, 0.92),
        bgHover      = tone(dusk, 1.00, 0.95),
        bgDown       = tone(dusk, 0.38, 0.95),
        bgActive     = tone(ACCENT, 0.4, 0.95),
        bgOff        = tone(dusk, 0.35, 0.90),
        border       = rgba(tone(metal, 0.66), 0.9),
        borderHover  = rgba(metal, 1),
        borderActive = rgba(metal, 1),
        borderOff    = rgba(tone(metal, 0.42), 0.6),
        glow         = metal,
        text         = SECONDARY,
        textHover    = WHITE,
        textActive   = WHITE,
        textOff      = DIMMED,
    }
end
function ns.LookOf(f)
    local canvas = _G.HTP_ArcadeCanvas
    local game = canvas and ns.GameLook and ns.GameLook()
    while f do
        if f.look then return f.look end
        if game and f == canvas then return game end
        f = f:GetParent()
    end
    return nil
end
function ns.ButtonSkin(b)
    local look = ns.LookOf(b)
    if look and look.button then return look.button end
    return ns.CurrentTheme().button
end
local function gameLook(t)
    local e, w = t.edge, t.wood
    return {
        edge   = e,
        screen = t.screen or tone(w, 0.6, 1),
        rule   = t.rule or rgba(e, 0.38),
        button = buttonSkin(w),
        panel = {
            backdrop = panelBackdrop(t.panelEdge or TIP_EDGE),
            bg       = t.panelBg or { 0, 0, 0, 0.55 },
            border   = t.panelBorder or (t.panelEdge and { 1, 1, 1, 1 })
                or tone(e, 0.6, 0.9),
        },
        table = { tex = t.tableTex or ACH_BG, crop = t.tableCrop, tone = w },
        niche = {
            bg   = tone(w, 0.33, 1),
            edge = tone(w, 1.30, 1),
            cap  = NICHE_CAP,
        },
        slot = {
            bg   = tone(w, 0.48, 1),
            bgOn = tone(w, 0.87, 1),
            edge = tone(w, 1.30, 1),
            hot  = tone(w, 2.15, 1),
        },
        card = {
            backdrop = ns.INFO_BACKDROP,
            bg       = tone(lift(w, 0.22), 0.35, 0.97),
            border   = rgba(e, 1),
        },
    }
end
function ns.MakeLook(spec)
    spec = spec or {}
    return gameLook({
        wood = spec.wood or { 0.230, 0.190, 0.130 },
        edge = spec.edge or ATTN,
        screen = spec.screen,
        tableTex = spec.tableTex,
        tableCrop = spec.tableCrop,
    })
end
local function weaveSkin(t)
    local wv = t.weave
    if not wv then return nil end
    return {
        backdrop = { bgFile = WEAVE:format(wv[1]), tile = true, tileSize = 64 },
        color    = rgba(t.edge, wv[2]),
    }
end
local function dress(t)
    local e, w = t.edge, t.wood
    local g = gameLook(t)
    return {
        labelKey = t.labelKey,
        edge     = g.edge,
        accent   = ACCENT,
        window = {
            backdrop = t.frame,
            bg       = t.frameBg or { 1, 1, 1, 1 },
            border   = t.frameBorder or { 1, 1, 1, 1 },
            body     = t.body,
            full     = t.bodyFull,
        },
        panel = g.panel,
        button = g.button,
        tile = {
            backdrop    = TILE_BACKDROP,
            bg          = { 0, 0, 0, 0.6 },
            bgHover     = tone(e, 0.28, 0.85),
            border      = t.tileBorder or tone(e, 0.6, 0.85),
            borderHover = rgba(e, 1),
            title       = PRIMARY,
            titleHover  = WHITE,
            note        = NOTE,
            glow        = e,
        },
        weave = weaveSkin(t),
        screenBody = t.screenTex or { color = g.screen },
        card = g.card,
        rule = g.rule,
        screen = g.screen,
        table = g.table,
        niche = g.niche,
        slot  = g.slot,
    }
end
local THEMES = {
    parchment = {
        labelKey = "themeParchment",
        edge = ATTN,
        wood = { 0.230, 0.190, 0.130 },
        frame = {
            bgFile = PARCH, edgeFile = DLG_GOLD,
            tile = false, edgeSize = 32, insets = DLG_INSET,
        },
        body = { tex = PARCH },
        panelBorder = { 0.5, 0.45, 0.3, 0.9 },
        tileBorder = { 0.5, 0.45, 0.3, 0.8 },
        rule = { 1, 0.82, 0, 0.35 },
        screenTex = { tex = DRAGON, color = { 0.82, 0.78, 0.70 } },
    },
    gold = {
        labelKey = "themeDarkGold",
        edge = ATTN,
        wood = { 0.230, 0.190, 0.130 },
        frame = {
            bgFile = DLG_DARK, edgeFile = WOOD,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        body = { tex = ACH_BG, color = { 0.26, 0.20, 0.12 } },
        bodyFull = true,
        panelEdge = DLG_GOLD,
        panelBg = { 0.08, 0.06, 0.02, 0.75 },
        tileBorder = { 0.62, 0.48, 0.18, 0.9 },
        rule = { 1, 0.86, 0.35, 0.4 },
        weave = { "lattice", 0.06 },
        screenTex = { tex = ACH_BG, color = { 0.30, 0.24, 0.15 } },
    },
    scroll = {
        labelKey = "themeScroll",
        edge = { 1, 0.86, 0.42 },
        wood = { 0.255, 0.205, 0.135 },
        frame = {
            bgFile = DLG_PAPER, edgeFile = DLG_BORDER,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        body = { tex = PARCH, color = { 0.74, 0.62, 0.44 } },
        panelBg = { 0.10, 0.07, 0.04, 0.78 },
        weave = { "hatch", 0.06 },
        screenTex = { tex = PAPER_OLD, color = { 0.58, 0.50, 0.38 } },
    },
    stone = {
        labelKey = "themeStone",
        edge = { 0.80, 0.80, 0.72 },
        wood = { 0.185, 0.190, 0.170 },
        frame = {
            bgFile = TIP_BG, edgeFile = DLG_BORDER,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        body = { tex = STONE, crop = STONE_CROP, color = { 0.46, 0.47, 0.43 } },
        panelBg = { 0.06, 0.065, 0.060, 0.8 },
        tableTex = STONE,
        tableCrop = STONE_CROP,
        screenTex = { tex = STONE, crop = STONE_CROP, color = { 0.36, 0.37, 0.34 } },
    },
    slate = {
        labelKey = "themeSlate",
        edge = { 0.62, 0.70, 0.85 },
        wood = { 0.150, 0.160, 0.195 },
        frame = {
            bgFile = TIP_BG, edgeFile = TIP_EDGE,
            tile = true, tileSize = 16, edgeSize = 16, insets = TIP_INSET,
        },
        frameBg = { 0.11, 0.12, 0.15, 1 },
        frameBorder = { 0.35, 0.39, 0.47, 1 },
        body = { color = { 0.11, 0.12, 0.15 } },
        panelBg = { 0.07, 0.08, 0.11, 0.9 },
        panelBorder = { 0.35, 0.39, 0.47, 1 },
        tileBorder = { 0.33, 0.37, 0.45, 0.9 },
        rule = { 0.5, 0.56, 0.68, 0.45 },
        weave = { "hatch", 0.06 },
    },
    flat = {
        labelKey = "themeFlat",
        edge = { 0.55, 0.70, 0.88 },
        wood = { 0.105, 0.115, 0.130 },
        frame = {
            bgFile = TIP_BG, edgeFile = TIP_EDGE,
            tile = true, tileSize = 16, edgeSize = 16, insets = TIP_INSET,
        },
        frameBg = { 0.03, 0.04, 0.05, 1 },
        frameBorder = { 0.42, 0.47, 0.54, 1 },
        body = { color = { 0.03, 0.04, 0.05 } },
        panelBg = { 0, 0, 0, 0.75 },
        panelBorder = { 0.45, 0.52, 0.62, 1 },
        tileBorder = { 0.38, 0.44, 0.52, 0.9 },
        rule = { 0.55, 0.68, 0.82, 0.45 },
    },
}
ns.themeOrder = { "parchment", "gold", "scroll", "stone", "slate", "flat" }
for _, key in ipairs(ns.themeOrder) do
    THEMES[key] = dress(THEMES[key])
end
local DEFAULT = "parchment"
local cur
function ns.ThemeKey()
    if cur then return cur end
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    local key = db and db.uiTheme
    cur = (key and THEMES[key]) and key or DEFAULT
    return cur
end
function ns.CurrentTheme()
    return THEMES[ns.ThemeKey()]
end
local function lookOf(f)
    return ns.LookOf(f) or THEMES[ns.ThemeKey()]
end
local painters = {}
function ns.OnTheme(fn)
    painters[#painters + 1] = fn
end
function ns.SetTheme(key)
    if not THEMES[key] or key == ns.ThemeKey() then return end
    cur = key
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    if db then db.uiTheme = key end
    for _, fn in ipairs(painters) do fn() end
end
function ns.ThemeOptions()
    local out = {}
    for i, key in ipairs(ns.themeOrder) do
        out[i] = { key = key, label = ns.T(THEMES[key].labelKey) }
    end
    return out
end
local panels = {}
function ns.PaintPanel(p)
    local th = lookOf(p).panel
    p:SetBackdrop(th.backdrop)
    p:SetBackdropColor(th.bg[1], th.bg[2], th.bg[3], th.bg[4])
    p:SetBackdropBorderColor(th.border[1], th.border[2], th.border[3], th.border[4])
    if p.cap then p.cap:SetTextColor(ns.CardEdge(ns.LookOf(p))) end
end
function ns.MakePanel(parent, caption, look)
    local p = CreateFrame("Frame", nil, parent)
    p.look = look
    p.kitPaint = ns.PaintPanel
    panels[#panels + 1] = p
    ns.PaintPanel(p)
    if caption then
        p.cap = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        p.cap:SetPoint("TOPLEFT", p, "TOPLEFT", ns.Space.inset, -9)
        p.cap:SetText(caption)
        p.cap:SetTextColor(ns.CardEdge(look))
    end
    return p
end
local titles = {}
function ns.TitleText(fs, owner)
    titles[#titles + 1] = { fs = fs, owner = owner }
    local host = owner or fs:GetParent()
    host.kitTitles = host.kitTitles or {}
    host.kitTitles[#host.kitTitles + 1] = fs
    ns.PaintTitle(fs, owner)
    return fs
end
function ns.PaintTitle(fs, owner)
    fs:SetTextColor(ns.CardEdge(ns.LookOf(owner or fs:GetParent())))
end
function ns.PaintCard(f)
    local th = lookOf(f).card
    f:SetBackdrop(th.backdrop)
    f:SetBackdropColor(th.bg[1], th.bg[2], th.bg[3], th.bg[4])
    f:SetBackdropBorderColor(th.border[1], th.border[2], th.border[3], th.border[4])
end
local cards = {}
function ns.DressCard(f, look)
    f.look = look
    f.kitPaint = ns.PaintCard
    cards[#cards + 1] = f
    ns.PaintCard(f)
    return f
end
function ns.PaintBody(tex, body, a, v0, v1)
    v0, v1 = v0 or 0, v1 or 1
    if body.tex then
        local c = body.color
        tex:SetTexture(body.tex)
        local cr = body.crop or { 0, 1, 0, 1 }
        local span = cr[4] - cr[3]
        tex:SetTexCoord(cr[1], cr[2], cr[3] + span * v0, cr[3] + span * v1)
        tex:SetVertexColor(c and c[1] or 1, c and c[2] or 1, c and c[3] or 1, a)
    else
        local c = body.color or { 0, 0, 0 }
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetTexture(c[1], c[2], c[3], a)
    end
end
function ns.PaintScreen(tex, a)
    ns.PaintBody(tex, ns.CurrentTheme().screenBody, a)
end
function ns.Accent()
    return ACCENT[1], ACCENT[2], ACCENT[3]
end
function ns.Attn()
    return ATTN[1], ATTN[2], ATTN[3]
end
function ns.Screen()
    return ns.CurrentTheme().screen
end
function ns.CardEdge(look)
    local e = (look or THEMES[ns.ThemeKey()]).edge
    return e[1], e[2], e[3]
end
function ns.ClassColor(token)
    local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end
local tables, niches, slots = {}, {}, {}
local function paintTable(f)
    local th = lookOf(f).table
    f.tex:SetTexture(th.tex)
    if th.crop then
        f.tex:SetTexCoord(th.crop[1], th.crop[2], th.crop[3], th.crop[4])
    else
        f.tex:SetTexCoord(0, 1, 0, 1)
    end
    f.tex:SetVertexColor(th.tone[1], th.tone[2], th.tone[3])
end
function ns.MakeTable(canvas, look)
    local f = ns.PlainFrame(canvas, 0)
    f.look = look
    f:SetAllPoints(canvas)
    f.tex = ns.window:ScreenFill(f)
    f.kitPaint = paintTable
    paintTable(f)
    tables[#tables + 1] = f
    f:Hide()
    return f
end
local function paintNiche(f)
    local th = lookOf(f).niche
    f.plate:SetTexture(th.bg[1], th.bg[2], th.bg[3], th.bg[4])
    for i = 1, #f.edge do
        f.edge[i]:SetTexture(th.edge[1], th.edge[2], th.edge[3], th.edge[4])
    end
end
function ns.MakeNiche(parent, level, look)
    local f = ns.PlainFrame(parent, level or 2)
    f.look = look
    f.plate = ns.Fill(f, "BACKGROUND", { 0, 0, 0, 1 })
    f.plate:SetAllPoints(f)
    f.edge = {}
    local function bar(p1, p2, w, h)
        local t = ns.Fill(f, "BORDER", { 0, 0, 0, 1 })
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        f.edge[#f.edge + 1] = t
    end
    bar("TOPLEFT", "TOPRIGHT", nil, 1)
    bar("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    bar("TOPLEFT", "BOTTOMLEFT", 1, nil)
    bar("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
    f.kitPaint = paintNiche
    paintNiche(f)
    niches[#niches + 1] = f
    return f
end
function ns.MakeCap(parent, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(NICHE_CAP[1], NICHE_CAP[2], NICHE_CAP[3])
    return fs
end
function ns.MakeSlot(parent, look)
    local b = CreateFrame("Button", nil, parent)
    b.look = look
    b.bg = ns.Fill(b, "BACKGROUND", { 0, 0, 0, 1 })
    b.bg:SetAllPoints(b)
    b.edge = {}
    local function bar(p1, p2, w, h)
        local t = ns.Fill(b, "BORDER", { 0, 0, 0, 1 })
        t:SetPoint(p1, b, p1, 0, 0)
        t:SetPoint(p2, b, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        b.edge[#b.edge + 1] = t
    end
    bar("TOPLEFT", "TOPRIGHT", nil, 1)
    bar("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    bar("TOPLEFT", "BOTTOMLEFT", 1, nil)
    bar("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
    function b:Tone(on)
        self.on = on and true or false
        local th = lookOf(self).slot
        local bg = on and th.bgOn or th.bg
        self.bg:SetTexture(bg[1], bg[2], bg[3], bg[4])
        local e = th.edge
        if on then
            e = { ns.CardEdge(ns.LookOf(self)) }
        elseif self.hot then
            e = th.hot
        end
        for i = 1, #self.edge do
            self.edge[i]:SetTexture(e[1], e[2], e[3], e[4] or 1)
        end
    end
    b:SetScript("OnEnter", function(self)
        self.hot = true
        self:Tone(self.on)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hot = nil
        self:Tone(self.on)
        ns.TipHide()
    end)
    b.kitPaint = function(self) self:Tone(self.on) end
    b:Tone(false)
    slots[#slots + 1] = b
    return b
end
local function repaint(f)
    if f.kitPaint then f.kitPaint(f) end
    local t = f.kitTitles
    if t then
        for i = 1, #t do ns.PaintTitle(t[i], f) end
    end
    local kids = { f:GetChildren() }
    for i = 1, #kids do repaint(kids[i]) end
end
function ns.Restyle(root, look)
    root.look = look
    repaint(root)
end
ns.OnTheme(function()
    for i = 1, #titles do
        local t = titles[i]
        ns.PaintTitle(t.fs, t.owner)
    end
    for i = 1, #panels do ns.PaintPanel(panels[i]) end
    for i = 1, #cards do ns.PaintCard(cards[i]) end
    for i = 1, #tables do paintTable(tables[i]) end
    for i = 1, #niches do paintNiche(niches[i]) end
    for i = 1, #slots do slots[i]:Tone(slots[i].on) end
end)
