local ADDON, ns = ...
local ID = "jump"
local floor, abs, max, min, sqrt = math.floor, math.abs, math.max, math.min, math.sqrt
local GRAV     = 1400
local BOUNCE   = 620
local SPRING_MUL = 1.8
local SIDE_V   = 300
local SIDE_A   = 1800
local FRICTION = 0.85
local FIELD_W  = 300
local FIELD_X  = 170
local PW, PH   = 52, 12
local PSIZE    = 30
local HB       = 9
local SAFE_H   = 500
local MOVE_V   = 60
local RUNG = {
    { h = 0,     gapLo = 30, gapHi =  84, drift = 130,
      plain = 0.55, rot = 0.20, ice = 0.00, mobLo = 600, mobHi = 1000, spring = 0.080, ride = 0.028 },
    { h = 2500,  gapLo = 36, gapHi =  88, drift = 134,
      plain = 0.42, rot = 0.28, ice = 0.00, mobLo = 600, mobHi =  960, spring = 0.070, ride = 0.026 },
    { h = 6000,  gapLo = 46, gapHi =  94, drift = 140,
      plain = 0.34, rot = 0.34, ice = 0.10, mobLo = 570, mobHi =  900, spring = 0.060, ride = 0.022 },
    { h = 12000, gapLo = 58, gapHi = 104, drift = 146,
      plain = 0.27, rot = 0.39, ice = 0.14, mobLo = 540, mobHi =  840, spring = 0.048, ride = 0.016 },
    { h = 20000, gapLo = 70, gapHi = 112, drift = 148,
      plain = 0.20, rot = 0.44, ice = 0.18, mobLo = 520, mobHi =  800, spring = 0.036, ride = 0.010 },
}
local RG = {}
local RUNG_KEYS = { "gapLo", "gapHi", "drift", "plain", "rot", "ice",
                    "mobLo", "mobHi", "spring", "ride" }
local SPRING_W, SPRING_H = 16, 18
local SPRING_T = 0.22
local RIDE = ns.jumpRides
local RIDE_LOCK = ns.jumpRideSteer.LOCK
local RIDE_FREE = ns.jumpRideSteer.FREE
local RIDE_HOME = ns.jumpRideSteer.HOME
local RIDE_FROM = 1500
local RIDE_HOME_V = 110
local CRUMBLE_T = 0.28
local OVER_PAUSE = 0.8
local FALL_OUT = 40
local MOB_FROM = 1200
local MOB_SIZE, MOB_HB, MOB_V = 30, 12, 40
local AIM_R    = 220
local SHOT_V   = 520
local SHOT_CD  = 1.0
local SHOT_LIFE = 1.2
local SHOT_SIZE = 12
local FLASH_T  = 0.25
local KINDS = 4
local ICE = 4
local ICE_SLIP = 0.18
local ICE_NEXT = 0.25
local ROT_GAP  = 0.5
local PLATE = {
    { { 0.49, 0.42, 0.33 }, { 0.71, 0.63, 0.52 }, { 0.28, 0.24, 0.18 }, { 0.37, 0.31, 0.25 } },
    { { 0.31, 0.39, 0.50 }, { 0.56, 0.69, 0.82 }, { 0.17, 0.23, 0.30 }, { 0.23, 0.30, 0.39 } },
    { { 0.29, 0.23, 0.20 }, { 0.43, 0.35, 0.29 }, { 0.17, 0.13, 0.11 }, nil },
    { { 0.60, 0.75, 0.86 }, { 0.93, 0.98, 1.00 }, { 0.34, 0.45, 0.57 }, nil },
}
local C_COIL  = { 0.60, 0.64, 0.68 }
local C_GLOSS = { 0.89, 0.92, 0.94 }
local C_MARK  = { 0.95, 0.80, 0.34 }
local NOTE_T    = 1.8
local NOTE_FADE = 0.6
local SQUASH_T = 0.12
local DROP_T   = 0.7
local GLOW    = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local C = ns.jumpCitadel
local MODE_CITADEL = C.MODE
local CITADEL_ON = false
local RAY_DOTS = 8
local SKY_BANDS = 10
local WALL_W    = FIELD_X
local ROW_H     = 30
local ROWS      = 17
local PX_WALL, PX_FAR, PX_DUST = 0.35, 0.15, 0.60
local TORCH_STEP, TORCH_N = 280, 2
local FAR_STEP, FAR_N = 180, 4
local DUST_SPAN, DUST_N = 520, 12
local RULER_MINOR, RULER_MAJOR = 20, 100
local RULER_X = FIELD_X - 26
local BIOME = {
    { h = 0,     name = "jump.biomeCellar", lo = { 0.11, 0.09, 0.08 }, hi = { 0.20, 0.16, 0.12 },
      wall = { 0.115, 0.090, 0.070 }, far = { 0.42, 0.35, 0.26 }, torch = 1 },
    { h = 1200,  name = "jump.biomeHall", lo = { 0.23, 0.18, 0.13 }, hi = { 0.36, 0.29, 0.22 },
      wall = { 0.155, 0.125, 0.095 }, far = { 0.50, 0.42, 0.31 }, torch = 1 },
    { h = 3000,  name = "jump.biomeSky", lo = { 0.31, 0.49, 0.67 }, hi = { 0.66, 0.79, 0.89 },
      wall = { 0.300, 0.270, 0.230 }, far = { 0.86, 0.90, 0.95 }, torch = 0 },
    { h = 6000,  name = "jump.biomeVoid", lo = { 0.16, 0.11, 0.27 }, hi = { 0.04, 0.03, 0.08 },
      wall = { 0.100, 0.080, 0.140 }, far = { 0.55, 0.45, 0.78 }, torch = 0 },
    { h = 10000, name = "jump.biomeAurora", lo = { 0.05, 0.13, 0.15 }, hi = { 0.09, 0.33, 0.27 },
      wall = { 0.080, 0.150, 0.140 }, far = { 0.36, 0.92, 0.64 }, torch = 0 },
    { h = 16000, name = "jump.biomeFrost", lo = { 0.50, 0.64, 0.77 }, hi = { 0.82, 0.90, 0.96 },
      wall = { 0.330, 0.390, 0.460 }, far = { 0.94, 0.98, 1.00 }, torch = 0 },
    { h = 24000, name = "jump.biomeStars", lo = { 0.03, 0.05, 0.14 }, hi = { 0.09, 0.13, 0.30 },
      wall = { 0.070, 0.085, 0.170 }, far = { 0.74, 0.84, 1.00 }, torch = 0 },
    { h = 32000, name = "jump.biomeLight", lo = { 0.28, 0.25, 0.16 }, hi = { 0.97, 0.93, 0.79 },
      wall = { 0.300, 0.270, 0.200 }, far = { 1.00, 0.97, 0.82 }, torch = 0 },
}
local DUST = {
    {  52,  30 }, { 214,  76 }, { 128, 132 }, { 266, 168 },
    {  20, 214 }, { 176, 251 }, {  92, 296 }, { 238, 330 },
    { 148, 372 }, {  36, 404 }, { 284, 448 }, { 108, 486 },
}
local FAR = {
    {  46,   20, 62 }, { 196,  190, 54 },
    { 106,  372, 70 }, { 234,  548, 58 },
}
local view, platPool
local CH = 480
local function tex(f, layer, c, a)
    local t = f:CreateTexture(nil, layer)
    if c then ns.Paint(t, c[1], c[2], c[3], a or 1) end
    return t
end
local function sheet(canvas, level)
    local f = ns.NewFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + level)
    f:SetAllPoints(canvas)
    f:Hide()
    return f
end
local function place(t, canvas, x, y, w, h)
    local y0, y1 = y, y + h
    if y0 < 0 then y0 = 0 end
    if y1 > CH then y1 = CH end
    if w <= 0 or y1 - y0 <= 0 then t:Hide() return end
    t:ClearAllPoints()
    t:SetWidth(w)
    t:SetHeight(y1 - y0)
    t:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y0)
    t:Show()
end
local function placeIcon(t, canvas, cx, cy, size)
    if cy - size / 2 < 0 or cy + size / 2 > CH then t:Hide() return false end
    t:ClearAllPoints()
    t:SetWidth(size)
    t:SetHeight(size)
    t:SetPoint("CENTER", canvas, "BOTTOMLEFT", cx, cy)
    t:Show()
    return true
end
local function mix3(a, b, t)
    return a[1] + (b[1] - a[1]) * t,
           a[2] + (b[2] - a[2]) * t,
           a[3] + (b[3] - a[3]) * t
end
local function plateFrame(parent)
    local f = ns.NewFrame("Frame", nil, parent)
    f.body  = tex(f, "BACKGROUND")
    f.edge  = tex(f, "BORDER")
    f.shade = tex(f, "BORDER")
    f.capL  = tex(f, "ARTWORK")
    f.capR  = tex(f, "ARTWORK")
    f.mark1 = tex(f, "ARTWORK")
    f.mark2 = tex(f, "ARTWORK")
    f.coil = {}
    for i = 1, 3 do f.coil[i] = tex(f, "OVERLAY", C_COIL) end
    f.cap = tex(f, "OVERLAY", C_GLOSS)
    f.ride = {}
    for i = 1, RIDE.parts do
        f.ride[i] = tex(f, "OVERLAY", C_COIL)
        f.ride[i]:Hide()
    end
    f.badge = f:CreateTexture(nil, "OVERLAY")
    f.badge:Hide()
    f:Hide()
    return f
end
local function paintPlate(f, kind, spring)
    local p = PLATE[kind] or PLATE[1]
    ns.Paint(f.body, p[1][1], p[1][2], p[1][3], 1)
    ns.Paint(f.edge, p[2][1], p[2][2], p[2][3], 1)
    ns.Paint(f.shade, p[3][1], p[3][2], p[3][3], 1)
    if p[4] then
        ns.Paint(f.capL, p[4][1], p[4][2], p[4][3], 1)
        ns.Paint(f.capR, p[4][1], p[4][2], p[4][3], 1)
        f.capL:Show(); f.capR:Show()
    else
        f.capL:Hide(); f.capR:Hide()
    end
    local mc = (kind == 3) and p[3] or p[2]
    if kind == 2 or kind == 3 or kind == ICE then
        ns.Paint(f.mark1, mc[1], mc[2], mc[3], 1)
        ns.Paint(f.mark2, mc[1], mc[2], mc[3], 1)
    else
        f.mark1:Hide(); f.mark2:Hide()
    end
    local show = spring and true or false
    for i = 1, 3 do
        if show then f.coil[i]:Show() else f.coil[i]:Hide() end
    end
    if show then f.cap:Show() else f.cap:Hide() end
end
local function ensureView(canvas)
    if view then return end
    view = {}
    CH = canvas.H or 480
    view.sky = sheet(canvas, 1)
    view.band = {}
    local bh = CH / SKY_BANDS
    for i = 1, SKY_BANDS do
        local t = tex(view.sky, "BACKGROUND", BIOME[1].lo)
        t:SetPoint("BOTTOMLEFT", view.sky, "BOTTOMLEFT", 0, (i - 1) * bh)
        t:SetPoint("BOTTOMRIGHT", view.sky, "BOTTOMRIGHT", 0, (i - 1) * bh)
        t:SetHeight((i < SKY_BANDS) and (bh + 1) or bh)
        view.band[i] = t
    end
    view.farSheet = sheet(canvas, 2)
    view.far = {}
    for i = 1, FAR_N do
        view.far[i] = {
            tex(view.farSheet, "BACKGROUND"),
            tex(view.farSheet, "BACKGROUND"),
            tex(view.farSheet, "BACKGROUND"),
        }
    end
    view.wall = sheet(canvas, 3)
    view.wallBase = {
        tex(view.wall, "BACKGROUND", BIOME[1].wall),
        tex(view.wall, "BACKGROUND", BIOME[1].wall),
    }
    view.wallBase[1]:SetPoint("BOTTOMLEFT", view.wall, "BOTTOMLEFT", 0, 0)
    view.wallBase[1]:SetWidth(WALL_W)
    view.wallBase[1]:SetHeight(CH)
    view.wallBase[2]:SetPoint("BOTTOMRIGHT", view.wall, "BOTTOMRIGHT", 0, 0)
    view.wallBase[2]:SetWidth(WALL_W)
    view.wallBase[2]:SetHeight(CH)
    view.row = {}
    for i = 1, ROWS do
        view.row[i] = {
            tex(view.wall, "BORDER"), tex(view.wall, "BORDER"),
            tex(view.wall, "BORDER"), tex(view.wall, "BORDER"),
            tex(view.wall, "BORDER"), tex(view.wall, "BORDER"),
        }
    end
    local VIG = { 0.07, 0.06, 0.05 }
    view.vig = {}
    for i = 1, 3 do
        local a = 0.34 - (i - 1) * 0.13
        local l = tex(view.wall, "ARTWORK", VIG, a)
        l:SetPoint("BOTTOMLEFT", view.wall, "BOTTOMLEFT", FIELD_X + (i - 1) * 6, 0)
        l:SetWidth(6); l:SetHeight(CH)
        local r = tex(view.wall, "ARTWORK", VIG, a)
        r:SetPoint("BOTTOMLEFT", view.wall, "BOTTOMLEFT",
                   FIELD_X + FIELD_W - i * 6, 0)
        r:SetWidth(6); r:SetHeight(CH)
        view.vig[i] = { l, r }
    end
    for _, x in ipairs({ FIELD_X - 2, FIELD_X + FIELD_W }) do
        local edge = tex(view.wall, "OVERLAY", { 0.55, 0.47, 0.34 })
        edge:SetPoint("BOTTOMLEFT", view.wall, "BOTTOMLEFT", x, 0)
        edge:SetWidth(2); edge:SetHeight(CH)
    end
    view.torch = {}
    for i = 1, TORCH_N * 2 do
        local t = {}
        t.arm = tex(view.wall, "ARTWORK", { 0.27, 0.23, 0.18 })
        t.glow = view.wall:CreateTexture(nil, "ARTWORK")
        t.glow:SetTexture(GLOW)
        t.glow:SetBlendMode("ADD")
        t.glow:SetVertexColor(0.91, 0.57, 0.24)
        t.fire = tex(view.wall, "OVERLAY", { 1.00, 0.78, 0.37 })
        view.torch[i] = t
    end
    view.ruler = sheet(canvas, 4)
    local plumb = tex(view.ruler, "BACKGROUND", { 0.36, 0.31, 0.22 })
    plumb:SetPoint("BOTTOMLEFT", view.ruler, "BOTTOMLEFT", RULER_X + 22, 0)
    plumb:SetWidth(1); plumb:SetHeight(CH)
    view.tick, view.big, view.label = {}, {}, {}
    for i = 1, floor(CH / RULER_MINOR) + 2 do
        view.tick[i] = tex(view.ruler, "ARTWORK", { 0.37, 0.31, 0.22 })
    end
    for i = 1, floor(CH / RULER_MAJOR) + 2 do
        view.big[i] = tex(view.ruler, "ARTWORK", { 0.60, 0.52, 0.38 })
        local s = view.ruler:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        s:SetJustifyH("RIGHT")
        s:SetTextColor(0.60, 0.52, 0.38)
        view.label[i] = s
    end
    view.markLine = tex(view.ruler, "OVERLAY", C_MARK, 0.85)
    view.markTip = tex(view.ruler, "OVERLAY", C_MARK)
    view.markText = view.ruler:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.markText:SetJustifyH("LEFT")
    view.markText:SetTextColor(C_MARK[1], C_MARK[2], C_MARK[3])
    view.dustSheet = sheet(canvas, 5)
    view.dust = {}
    for i = 1, DUST_N do
        view.dust[i] = tex(view.dustSheet, "ARTWORK", { 1.00, 0.96, 0.85 }, 0.16)
    end
    view.vault = {}
    for i = 1, 8 do view.vault[i] = tex(view.ruler, "ARTWORK", { 0.24, 0.31, 0.40 }) end
    view.vault[9] = tex(view.ruler, "OVERLAY", { 0.35, 0.48, 0.60 })
    for i = 10, 12 do view.vault[i] = tex(view.ruler, "OVERLAY", { 0.56, 0.71, 0.82 }) end
    platPool = ns.NewPool(function()
        local f = plateFrame(canvas)
        f:SetFrameLevel(canvas:GetFrameLevel() + 6)
        f:SetAllPoints(canvas)
        return f
    end)
    view.mobSheet = sheet(canvas, 7)
    view.mobArt = {}
    view.shotGlow = view.mobSheet:CreateTexture(nil, "ARTWORK")
    view.shotGlow:SetTexture(GLOW)
    view.shotGlow:SetBlendMode("ADD")
    view.shotGlow:SetVertexColor(0.95, 0.75, 0.35)
    view.shotCore = tex(view.mobSheet, "OVERLAY", { 1.00, 0.95, 0.81 })
    view.flash = view.mobSheet:CreateTexture(nil, "OVERLAY")
    view.flash:SetTexture(GLOW)
    view.flash:SetBlendMode("ADD")
    view.flame = {
        tex(view.mobSheet, "BACKGROUND", { 0.35, 0.61, 0.77 }, 0.55),
        tex(view.mobSheet, "BACKGROUND", { 0.35, 0.61, 0.77 }, 0.55),
        tex(view.mobSheet, "ARTWORK", { 0.75, 0.89, 0.97 }, 0.8),
        tex(view.mobSheet, "ARTWORK", { 0.75, 0.89, 0.97 }, 0.8),
    }
    view.spike = {
        tex(view.mobSheet, "ARTWORK", { 0.86, 0.84, 0.72 }),
        tex(view.mobSheet, "OVERLAY", { 0.72, 0.70, 0.58 }),
        tex(view.mobSheet, "OVERLAY", { 0.93, 0.91, 0.80 }),
        tex(view.mobSheet, "BACKGROUND", { 0.60, 0.58, 0.48 }),
    }
    view.pool = {
        tex(view.mobSheet, "BACKGROUND", { 0.16, 0.34, 0.20 }, 0.85),
        tex(view.mobSheet, "ARTWORK", { 0.36, 0.72, 0.38 }, 0.85),
        tex(view.mobSheet, "OVERLAY", { 0.74, 0.98, 0.68 }, 0.95),
    }
    view.shade = {}
    view.shade[1] = view.mobSheet:CreateTexture(nil, "ARTWORK")
    view.shade[1]:SetTexture(GLOW)
    view.shade[1]:SetBlendMode("ADD")
    view.shade[1]:SetVertexColor(0.58, 0.36, 0.92)
    view.shade[2] = tex(view.mobSheet, "OVERLAY", { 0.80, 0.68, 1.00 }, 0.95)
    view.shade[3] = tex(view.mobSheet, "OVERLAY", { 0.42, 0.24, 0.62 }, 0.9)
    view.shade[4] = tex(view.mobSheet, "OVERLAY", { 0.98, 0.94, 1.00 })
    view.shade[5] = tex(view.mobSheet, "OVERLAY", { 0.98, 0.94, 1.00 })
    view.storm = {}
    for i = 1, 6 do
        view.storm[i] = tex(view.mobSheet, "OVERLAY", { 0.90, 0.88, 0.76 }, 0.85)
    end
    view.ray, view.mark = {}, {}
    for i = 1, RAY_DOTS do
        view.ray[i] = tex(view.mobSheet, "OVERLAY", { 0.91, 0.57, 0.24 }, 0.45)
    end
    for i = 1, 4 do
        view.mark[i] = tex(view.mobSheet, "OVERLAY", { 0.95, 0.70, 0.30 })
    end
    view.bossSheet = sheet(canvas, 7)
    view.bossArt = {}
    view.hud = sheet(canvas, 9)
    view.note = view.hud:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.note:SetJustifyH("CENTER")
    view.noteSub = view.hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.noteSub:SetJustifyH("CENTER")
    view.hpBack = tex(view.hud, "BACKGROUND", { 0.10, 0.09, 0.07 })
    view.hpFill = tex(view.hud, "ARTWORK", { 0.62, 0.28, 0.24 })
    view.shFill = tex(view.hud, "OVERLAY", { 0.38, 0.62, 0.92 })
    view.shEdge = tex(view.hud, "OVERLAY", { 0.72, 0.88, 1.00 })
    view.seal, view.sealDot = {}, {}
    for i = 1, C.SEALS do
        view.seal[i] = tex(view.hud, "BACKGROUND", { 0.14, 0.11, 0.08 })
        view.sealDot[i] = tex(view.hud, "ARTWORK", { 0.79, 0.63, 0.29 })
    end
    view.rideSheet = sheet(canvas, 7)
    view.rideArt = {}
    for i = 1, RIDE.parts do view.rideArt[i] = tex(view.rideSheet, "ARTWORK", C_COIL) end
    view.meSheet = sheet(canvas, 8)
    view.hero = {}
    view.playSheets = { view.mobSheet, view.bossSheet, view.rideSheet, view.meSheet, view.hud }
    view.slipMark = {}
    for i = 1, 3 do
        view.slipMark[i] = tex(view.meSheet, "BACKGROUND", { 0.86, 0.95, 1.00 }, 0.8)
    end
end
local HERO_LAYER = { "BACKGROUND", "BORDER", "ARTWORK", "OVERLAY", "HIGHLIGHT" }
local function ensureHero(idx)
    local def = ns.jumpHeroes and ns.jumpHeroes[idx]
    if not def or type(def.parts) ~= "table" or #def.parts == 0 then return nil end
    if view.hero[idx] then return view.hero[idx] end
    local list = {}
    for i = 1, #def.parts do
        local p = def.parts[i]
        local t = view.meSheet:CreateTexture(nil, HERO_LAYER[p[9] or 3] or "ARTWORK")
        ns.Paint(t, p[5] or 1, p[6] or 1, p[7] or 1, p[8] or 1)
        t:Hide()
        list[i] = t
    end
    view.hero[idx] = list
    return list
end
local function hideHeroes()
    if not view or not view.hero then return end
    for _, list in pairs(view.hero) do
        for i = 1, #list do list[i]:Hide() end
    end
end
local function ensureMob(idx)
    local def = ns.jumpMobs and ns.jumpMobs[idx]
    if not def or type(def.parts) ~= "table" or #def.parts == 0 then return nil end
    if view.mobArt[idx] then return view.mobArt[idx] end
    local list = {}
    for i = 1, #def.parts do
        local p = def.parts[i]
        local t = view.mobSheet:CreateTexture(nil, HERO_LAYER[p[9] or 3] or "ARTWORK")
        ns.Paint(t, p[5] or 1, p[6] or 1, p[7] or 1, p[8] or 1)
        t:Hide()
        list[i] = t
    end
    view.mobArt[idx] = list
    return list
end
local function hideMobArt(except)
    if not view or not view.mobArt then return end
    if view.mobShown == except then return end
    for i, list in pairs(view.mobArt) do
        if i ~= except then
            for j = 1, #list do list[j]:Hide() end
        end
    end
    view.mobShown = except
end
local function ensureModel(canvas)
    if view.model ~= nil then return view.model end
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, canvas)
    if not ok or not m or not m.SetCreature then
        view.model = false
        return false
    end
    m:SetFrameLevel(canvas:GetFrameLevel() + 7)
    m:SetWidth(C.MODEL_W)
    m:SetHeight(C.MODEL_H)
    m:Hide()
    view.model = m
    return m
end
local function ensureBoss(idx)
    local g = ns.jumpGates and ns.jumpGates[idx]
    if not g or type(g.art) ~= "table" or #g.art == 0 then return nil end
    if view.bossArt[idx] then return view.bossArt[idx] end
    local list = {}
    for i = 1, #g.art do
        local p = g.art[i]
        local t = view.bossSheet:CreateTexture(nil, HERO_LAYER[p[9] or 3] or "ARTWORK")
        ns.Paint(t, p[5] or 1, p[6] or 1, p[7] or 1, p[8] or 1)
        t:Hide()
        list[i] = t
    end
    view.bossArt[idx] = list
    return list
end
local function hideBossArt(except)
    if not view or not view.bossArt then return end
    if view.bossShown == except then return end
    for i, list in pairs(view.bossArt) do
        if i ~= except then
            for j = 1, #list do list[j]:Hide() end
        end
    end
    view.bossShown = except
end
local function hideView()
    if not view then return end
    view.sky:Hide()
    view.farSheet:Hide()
    view.wall:Hide()
    view.ruler:Hide()
    view.dustSheet:Hide()
    view.mobSheet:Hide()
    view.meSheet:Hide()
    view.rideSheet:Hide()
    view.bossSheet:Hide()
    if view.model then view.model:Hide() end
    view.hud:Hide()
    hideHeroes()
    view.mobShown = nil
    view.bossShown = nil
    hideMobArt()
    hideBossArt()
    if platPool then platPool:HideAll() end
end
local function showView()
    view.bossSheet:Show()
    view.hud:Show()
    view.sky:Show()
    view.farSheet:Show()
    view.wall:Show()
    view.ruler:Show()
    view.dustSheet:Show()
    view.mobSheet:Show()
    view.meSheet:Show()
    view.rideSheet:Show()
end
local PANEL_W = 146
local C_GOLD = { 0.86, 0.72, 0.38 }
local C_SOFT = { 0.72, 0.66, 0.52 }
local C_DIM  = { 0.45, 0.41, 0.33 }
local ui, menu
local active
local againAt
local function label(host, font, c)
    local t = host:CreateFontString(nil, "OVERLAY", font)
    t:SetTextColor(c[1], c[2], c[3])
    return t
end
local function hideAll(t)
    for i = 1, #t do t[i]:Hide() end
end
local function ensurePanel(canvas)
    if ui then return end
    ui = {}
    ui.root = ns.NewFrame("Frame", nil, canvas)
    ui.root:SetFrameLevel(canvas:GetFrameLevel() + 10)
    ui.root:SetAllPoints(canvas)
    ui.root:Hide()
    ui.col = ns.NewFrame("Frame", nil, ui.root)
    ui.col:SetFrameLevel(ui.root:GetFrameLevel() + 1)
    ui.col:SetPoint("TOPRIGHT", ui.root, "TOPRIGHT", -12, -12)
    ui.col:SetWidth(PANEL_W)
    ui.col:SetHeight(240)
    ui.tally = ns.MakeScoreboard(ui.col, PANEL_W)
    ui.tally:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, 0)
    ui.bestCap = label(ui.col, "GameFontNormalSmall", C_SOFT)
    ui.bestCap:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -96)
    ui.bestCap:SetText(ns.T("jump.panelBest"))
    ui.best = label(ui.col, "GameFontNormal", C_GOLD)
    ui.best:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -96)
    ui.floorCap = label(ui.col, "GameFontNormalSmall", C_SOFT)
    ui.floorCap:SetPoint("TOPLEFT", ui.col, "TOPLEFT", 0, -118)
    ui.floorCap:SetText(ns.T("jump.panelFloor"))
    ui.floor = label(ui.col, "GameFontNormalSmall", C_GOLD)
    ui.floor:SetPoint("TOPRIGHT", ui.col, "TOPRIGHT", 0, -118)
    ui.toMenu = ns.MakeKitButton(ui.root)
    ui.toMenu:SetWidth(PANEL_W)
    ui.toMenu:SetPoint("BOTTOMRIGHT", ui.root, "BOTTOMRIGHT", -12, 12)
    ui.toMenu:SetText(ns.T("jump.toMenu"))
    ui.toMenu.onClick = function()
        if active then active:ToMenu() end
    end
end
local M = {
    capY = 16,
    mapX = 16, mapW = 56,
    mapY = 52, mapStep = 52, mapRows = 8,
    nameX = 82, nameW = 130,
    rightX = 328, rightW = FIELD_W, rightSolo = FIELD_X,
    pad = 16,
    cardY = { 18, 92 }, cardH = 66, cardPad = 14,
    heroCap = 176, heroY = 194, heroCell = 48,
    tableCap = 266, rowY = 294, rowH = 18, rows = CITADEL_ON and 6 or 10, rowPad = 10,
    barX = 96, barW = 118,
    playY = 424, playW = 164, playH = 32,
}
local function mapRow(host)
    local r = { y = M.mapY, host = host }
    r.bar = host:CreateTexture(nil, "ARTWORK")
    r.bar:SetWidth(M.mapW)
    r.mark = {}
    for k = 1, 4 do r.mark[k] = host:CreateTexture(nil, "OVERLAY") end
    r.name = label(host, "GameFontNormalSmall", C_SOFT)
    r.name:SetWidth(M.nameW)
    r.name:SetJustifyH("LEFT")
    r.at = label(host, "GameFontNormalSmall", C_DIM)
    r.at:SetWidth(M.nameW)
    r.at:SetJustifyH("LEFT")
    return r
end
local function placeRow(r, y, bh)
    r.y = y
    r.bar:ClearAllPoints()
    r.bar:SetPoint("TOPLEFT", r.host, "TOPLEFT", M.mapX, -(y - bh + 6))
    r.bar:SetHeight(bh)
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", r.host, "TOPLEFT", M.nameX, -(y - 6))
    r.at:ClearAllPoints()
    r.at:SetPoint("TOPLEFT", r.host, "TOPLEFT", M.nameX, -(y + 10))
end
local function markAt(t, r, dx, dy, w, h)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", r.bar:GetParent(), "TOPLEFT", M.mapX + dx, -(r.y - dy))
    t:SetWidth(w)
    t:SetHeight(h)
    t:Show()
end
local function floorMark(r, kind)
    local m = r.mark
    local x = M.mapW / 2 - 6
    if kind == "skull" then
        ns.Paint(m[1], 0.86, 0.84, 0.72, 1); markAt(m[1], r, x, 16, 12, 9)
        ns.Paint(m[2], 0.86, 0.84, 0.72, 1); markAt(m[2], r, x + 2, 7, 8, 3)
        ns.Paint(m[3], 0.10, 0.09, 0.07, 1); markAt(m[3], r, x + 2, 13, 3, 3)
        ns.Paint(m[4], 0.10, 0.09, 0.07, 1); markAt(m[4], r, x + 7, 13, 3, 3)
    elseif kind == "lock" then
        ns.Paint(m[1], 0.42, 0.37, 0.28, 1); markAt(m[1], r, x + 1, 10, 10, 8)
        ns.Paint(m[2], 0.42, 0.37, 0.28, 1); markAt(m[2], r, x + 3, 16, 6, 2)
        m[3]:Hide(); m[4]:Hide()
    else
        for i = 1, 4 do m[i]:Hide() end
    end
end
local function heroCell(host, idx, x)
    local b = ns.NewFrame("Button", nil, host)
    b:SetWidth(M.heroCell)
    b:SetHeight(M.heroCell + 6)
    b:SetPoint("TOPLEFT", host, "TOPLEFT", x, -M.heroY)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.edge = {}
    for k = 1, 4 do b.edge[k] = b:CreateTexture(nil, "BORDER") end
    b.edge[1]:SetPoint("TOPLEFT"); b.edge[1]:SetPoint("TOPRIGHT"); b.edge[1]:SetHeight(1)
    b.edge[2]:SetPoint("BOTTOMLEFT"); b.edge[2]:SetPoint("BOTTOMRIGHT"); b.edge[2]:SetHeight(1)
    b.edge[3]:SetPoint("TOPLEFT"); b.edge[3]:SetPoint("BOTTOMLEFT"); b.edge[3]:SetWidth(1)
    b.edge[4]:SetPoint("TOPRIGHT"); b.edge[4]:SetPoint("BOTTOMRIGHT"); b.edge[4]:SetWidth(1)
    b.hero = idx
    if idx then
        local def = (ns.jumpHeroes or {})[idx]
        b.part = {}
        if def then
            local sc = 1.4
            local ox = (M.heroCell - 30 * sc) / 2
            for i = 1, #def.parts do
                local pp = def.parts[i]
                local t = b:CreateTexture(nil, HERO_LAYER[pp[9] or 3] or "ARTWORK")
                ns.Paint(t, pp[5] or 1, pp[6] or 1, pp[7] or 1, pp[8] or 1)
                t:SetWidth(pp[3] * sc)
                t:SetHeight(pp[4] * sc)
                t:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT",
                           ox + pp[1] * sc, 4 + pp[2] * sc)
                b.part[i] = t
            end
        end
    else
        b.any = label(b, "GameFontNormalLarge", C_SOFT)
        b.any:SetPoint("CENTER", b, "CENTER", 0, 4)
        b.any:SetText("?")
        b.anyCap = label(b, "GameFontNormalSmall", C_DIM)
        b.anyCap:SetPoint("BOTTOM", b, "BOTTOM", 0, 3)
        b.anyCap:SetText(ns.T("jump.heroAny"))
    end
    b:SetScript("OnClick", function(self)
        if active then ns.Sfx.Ui(); active:PickHero(self.hero) end
    end)
    return b
end
local function ensureMenu(canvas)
    if menu then return end
    menu = {}
    menu.root = ns.NewFrame("Frame", nil, canvas)
    menu.root:SetFrameLevel(canvas:GetFrameLevel() + 12)
    menu.root:SetAllPoints(canvas)
    menu.root:Hide()
    local veil = menu.root:CreateTexture(nil, "BACKGROUND")
    veil:SetAllPoints()
    ns.Paint(veil, 0.03, 0.03, 0.04, 0.80)
    menu.mapCap = label(menu.root, "GameFontNormalSmall", C_DIM)
    menu.mapCap:SetPoint("TOPLEFT", menu.root, "TOPLEFT", M.nameX, -M.capY)
    menu.column = menu.root:CreateTexture(nil, "BACKGROUND")
    menu.column:SetPoint("TOPLEFT", menu.root, "TOPLEFT", M.mapX, -(M.mapY - 10))
    menu.column:SetWidth(M.mapW)
    menu.column:SetHeight((M.mapRows - 1) * M.mapStep + 22)
    ns.Paint(menu.column, 0.10, 0.09, 0.07, 0.92)
    menu.floor = {}
    for i = 1, M.mapRows do menu.floor[i] = mapRow(menu.root) end
    menu.right = ns.NewFrame("Frame", nil, menu.root)
    menu.right:SetWidth(M.rightW)
    menu.right:SetPoint("TOPLEFT", menu.root, "TOPLEFT", M.rightX, 0)
    menu.right:SetPoint("BOTTOM", menu.root, "BOTTOM", 0, 0)
    menu.card = {}
    for i = 1, 2 do
        local b = ns.NewFrame("Button", nil, menu.right)
        b:SetWidth(M.rightW - M.pad * 2)
        b:SetHeight(M.cardH)
        b:SetPoint("TOPLEFT", menu.right, "TOPLEFT", M.pad, -M.cardY[i])
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.edge = {}
        for k = 1, 4 do b.edge[k] = b:CreateTexture(nil, "BORDER") end
        b.edge[1]:SetPoint("TOPLEFT"); b.edge[1]:SetPoint("TOPRIGHT"); b.edge[1]:SetHeight(2)
        b.edge[2]:SetPoint("BOTTOMLEFT"); b.edge[2]:SetPoint("BOTTOMRIGHT"); b.edge[2]:SetHeight(2)
        b.edge[3]:SetPoint("TOPLEFT"); b.edge[3]:SetPoint("BOTTOMLEFT"); b.edge[3]:SetWidth(4)
        b.edge[4]:SetPoint("TOPRIGHT"); b.edge[4]:SetPoint("BOTTOMRIGHT"); b.edge[4]:SetWidth(2)
        b.title = label(b, "GameFontNormalLarge", C_GOLD)
        b.title:SetPoint("TOPLEFT", b, "TOPLEFT", M.cardPad, -9)
        b.rec = label(b, "GameFontNormalSmall", C_DIM)
        b.rec:SetPoint("TOPRIGHT", b, "TOPRIGHT", -M.cardPad, -13)
        b.sub = label(b, "GameFontNormalSmall", C_SOFT)
        b.sub:SetPoint("TOPLEFT", b, "TOPLEFT", M.cardPad, -32)
        b.sub:SetWidth(M.rightW - M.pad * 2 - M.cardPad * 2)
        b.sub:SetJustifyH("LEFT")
        b.mode = (i == 1) and "classic" or MODE_CITADEL
        b:SetScript("OnClick", function(self)
            if active then ns.Sfx.Ui(); active:PickMode(self.mode) end
        end)
        menu.card[i] = b
    end
    menu.body = ns.NewFrame("Frame", nil, menu.right)
    menu.body:SetWidth(M.rightW)
    menu.body:SetPoint("TOPLEFT", menu.right, "TOPLEFT", 0, 0)
    menu.body:SetPoint("BOTTOM", menu.right, "BOTTOM", 0, 0)
    local inner = M.rightW - M.pad * 2
    menu.heroCap = label(menu.body, "GameFontNormalSmall", C_DIM)
    menu.heroCap:SetPoint("TOPLEFT", menu.body, "TOPLEFT", M.pad, -M.heroCap)
    menu.heroCap:SetText(ns.T("jump.heroCap"))
    menu.hero = {}
    local n = #(ns.jumpHeroes or {})
    local step = (n > 0) and floor((inner - M.heroCell) / n) or 0
    for i = 1, n do
        menu.hero[i] = heroCell(menu.body, i, M.pad + (i - 1) * step)
    end
    menu.hero[n + 1] = heroCell(menu.body, nil, M.pad + inner - M.heroCell)
    menu.tableCap = label(menu.body, "GameFontNormalSmall", C_DIM)
    menu.tableCap:SetPoint("TOPLEFT", menu.body, "TOPLEFT", M.pad, -M.tableCap)
    menu.tablePlate = menu.body:CreateTexture(nil, "BACKGROUND")
    ns.Paint(menu.tablePlate, 0.09, 0.08, 0.06, 0.92)
    menu.tablePlate:SetPoint("TOPLEFT", menu.body, "TOPLEFT", M.pad, -(M.rowY - M.rowPad))
    menu.tablePlate:SetWidth(inner)
    menu.tablePlate:SetHeight(M.rows * M.rowH + M.rowPad * 2 - 4)
    menu.row = {}
    for i = 1, M.rows do
        local r = {}
        local y = M.rowY + (i - 1) * M.rowH
        r.n = label(menu.body, "GameFontNormalSmall", C_DIM)
        r.n:SetPoint("TOPLEFT", menu.body, "TOPLEFT", M.pad + M.rowPad, -y)
        r.at = label(menu.body, "GameFontNormalSmall", C_DIM)
        r.at:SetPoint("TOPLEFT", menu.body, "TOPLEFT", M.pad + M.rowPad + 24, -y)
        r.bar = menu.body:CreateTexture(nil, "ARTWORK")
        r.bar:SetPoint("TOPLEFT", menu.body, "TOPLEFT", M.pad + M.barX, -(y + 4))
        r.bar:SetHeight(6)
        r.score = label(menu.body, "GameFontNormalSmall", C_SOFT)
        r.score:SetPoint("TOPRIGHT", menu.body, "TOPLEFT", M.rightW - M.pad - M.rowPad, -y)
        menu.row[i] = r
    end
    menu.play = ns.MakeKitButton(menu.right)
    menu.play:SetWidth(M.playW)
    menu.play:SetHeight(M.playH)
    menu.play:SetPoint("TOP", menu.right, "TOPLEFT", M.rightW / 2, -M.playY)
    menu.play:SetText(ns.T("jump.play"))
    menu.play.onClick = function()
        if active then active:BeginRound() end
    end
end
local Game = {}
Game.__index = Game
C.Bind({ ID = ID, BOUNCE = BOUNCE, PSIZE = PSIZE, PW = PW, HB = HB, FLASH_T = FLASH_T,
         MOB_HB = MOB_HB, MOB_V = MOB_V })
for k, f in pairs(C.methods) do Game[k] = f end
local SCALE_FIX = 1
local function fixScale()
    if ns.Config.Get(ID, "hscale", 0) >= SCALE_FIX then return end
    for _, rec in ipairs(ns.Store.RecList(ID)) do
        if type(rec.score) == "number" then rec.score = rec.score * 10 end
    end
    ns.Config.Set(ID, "hscale", SCALE_FIX)
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.plat = {}
    fixScale()
    return self
end
local function mobHB(m)
    return m.elite and C.ELITE_HB or MOB_HB
end
local function rungAt(y)
    local a, b, t = RUNG[1], RUNG[1], 0
    for i = 1, #RUNG - 1 do
        if y >= RUNG[i].h then
            a, b = RUNG[i], RUNG[i + 1]
            t = (y - a.h) / (b.h - a.h)
            if t > 1 then t = 1 end
        end
    end
    if y >= RUNG[#RUNG].h then a, b, t = RUNG[#RUNG], RUNG[#RUNG], 0 end
    for i = 1, #RUNG_KEYS do
        local k = RUNG_KEYS[i]
        RG[k] = a[k] + (b[k] - a[k]) * t
    end
    return RG
end
function Game:KindFor(y, rg)
    if y < SAFE_H then return 1 end
    local roll = self.rng:Float()
    if roll < rg.plain then return 1 end
    if roll < rg.plain + rg.rot then return (self.lastKind == 3) and 1 or 3 end
    if roll < rg.plain + rg.rot + rg.ice then return ICE end
    return 2
end
function Game:Push(y, rg, kind)
    local drift = floor(rg.drift)
    if self.lastKind == ICE then drift = floor(drift * ICE_NEXT) end
    local x = self.lastX + self.rng:Int(-drift, drift)
    if self.lastKind == 3 then
        local lo = max(0, self.solidX - drift)
        local hi = min(self.W - PW, self.solidX + drift)
        if x < lo then x = lo elseif x > hi then x = hi end
    end
    if x < 0 then x = 0 elseif x > self.W - PW then x = self.W - PW end
    local vx = 0
    if kind == 2 then
        vx = (self.rng:Float() < 0.5) and -MOVE_V or MOVE_V
    end
    local spring = false
    if y >= SAFE_H and kind == 1 and not self.lastRisk then
        spring = self.rng:Float() < rg.spring
    end
    local ride = nil
    if y >= RIDE_FROM and kind == 1 and not spring and not self.lastRisk then
        if self.rng:Float() < rg.ride then ride = self.rng:Int(1, #RIDE) end
    end
    if self:InArena(y) then kind, vx, spring, ride = 1, 0, false, nil end
    self.plat[#self.plat + 1] = { x = x, y = y, kind = kind, vx = vx,
                                  spring = spring, ride = ride }
    self.lastX, self.lastKind = x, kind
    self.lastRisk = (kind == 3) or (kind == ICE)
    if kind ~= 3 then self.solidX, self.solidY = x, y end
end
function Game:MobArt(y)
    local list = ns.jumpMobs
    local n = 1
    for i = 1, #list do
        if (list[i].from or 0) <= y then n = i end
    end
    local roll = self.rng:Int(1, n * (n + 1) / 2)
    for i = 1, n do
        roll = roll - i
        if roll <= 0 then return i end
    end
    return n
end
function Game:MaybeMob(rg)
    local from = self.citadel and C.MOB_CITADEL_FROM or MOB_FROM
    if self.mob or self.top < from or self.top < self.mobNext then return end
    local x = self.rng:Int(MOB_HB, floor(self.W) - MOB_HB)
    local left = self.rng:Float() < 0.5
    local eliteRoll = self.rng:Float()
    local elite = self.citadel and self.top >= C.ELITE_FROM and eliteRoll < C.ELITE_P
    local art = self:MobArt(self.top)
    local d = ns.jumpMobs[art]
    local v = d.v or MOB_V
    self.mob = {
        x = x, y = self.top + 40, y0 = self.top + 40, vx = left and -v or v, art = art,
        hp = elite and C.ELITE_HP or (d.hp or 1),
        elite = elite or nil,
    }
    local lo = self.citadel and C.MOB_CITADEL_MIN or floor(rg.mobLo)
    local hi = self.citadel and C.MOB_CITADEL_MAX or floor(rg.mobHi)
    self.mobNext = self.top + self.rng:Int(lo, hi)
end
function Game:Fill()
    local ceil = self.cam + self.H + 120
    if self.gateY and ceil > self.gateY - C.VAULT_GAP then
        ceil = self.gateY - C.VAULT_GAP
    end
    while self.top < ceil do
        local rg = rungAt(self.top)
        local kind = self:KindFor(self.top + 1, rg)
        local gap = self.rng:Int(floor(rg.gapLo), floor(rg.gapHi))
        if kind == 3 then gap = floor(gap * ROT_GAP) end
        if self:InArena(self.top) then gap, kind = C.ARENA_GAP, 1 end
        local y = self.top + gap
        if self.lastKind == 3 then
            local cap = self.solidY + floor(rg.gapHi)
            if y > cap then y = cap end
        end
        if y <= self.top then y = self.top + 4 end
        self:Push(y, rg, kind)
        self.top = y
        self:MaybeMob(rg)
    end
end
function Game:Prune()
    local n = #self.plat
    local j = 0
    for i = 1, n do
        local p = self.plat[i]
        self.plat[i] = nil
        if not p.dead and p.y > self.cam - FALL_OUT - PH then
            j = j + 1
            self.plat[j] = p
        end
    end
end
function Game:Land(y0)
    local y1 = self.y
    for i = #self.plat, 1, -1 do
        local p = self.plat[i]
        if p.y < y1 then return end
        if not p.dead and not p.dying and p.y <= y0 then
            local dxc = abs(p.x + PW / 2 - self.x)
            if dxc < PW / 2 + HB then
                if p.spiked and self.spike then
                    self.y, self.vy = p.y, 0
                    self.pin = self.spike
                    ns.Sfx.Play("pop")
                    return
                end
                self.y = p.y
                if p.pooled and self:PoolBurns() then
                    self.vy = BOUNCE
                    self:Hurt()
                    return
                end
                if p.ride then
                    self:Mount(p.ride)
                    p.ride = nil
                    return
                end
                if p.spring then
                    self.vy = BOUNCE * SPRING_MUL
                    p.spr = SPRING_T
                    ns.Sfx.Play("big")
                else
                    self.vy = BOUNCE
                end
                self.squash = SQUASH_T
                if p.kind == 3 then
                    p.dying = CRUMBLE_T
                    ns.Sfx.Play("pop")
                elseif p.kind == ICE then
                    self.slip = ICE_SLIP
                end
                return
            end
        end
    end
end
function Game:HitMob(y0)
    local m = self.mob
    if not m then return end
    local r = mobHB(m)
    local dx = abs(m.x - self.x)
    if dx > r + HB then return end
    if self.y > m.y + r then return end
    if self.y + PSIZE < m.y - r then return end
    if self.vy < 0 and y0 >= m.y then
        self:DamageMob(C.BOSS_STOMP)
        self.y = m.y + r
        self.vy = BOUNCE
        self.squash = SQUASH_T
        return
    end
    if self.ride then
        self:DamageMob(C.BOSS_STOMP)
        return
    end
    self:Hurt()
end
function Game:Mount(k)
    self.ride = { k = k, t = RIDE[k].t }
    self.vy = RIDE[k].v
    self.pin = nil
    self.drop = nil
    ns.Sfx.Play("big")
end
function Game:Dismount()
    local r = self.ride
    if not r then return end
    self.drop = { k = r.k, x = self.x, y = self.y, vy = RIDE[r.k].v * 0.25, t = DROP_T }
    self.ride = nil
end
function Game:DamageMob(n)
    local m = self.mob
    if not m then return end
    m.hp = (m.hp or 1) - n
    if m.hp > 0 then
        m.hurt = 0.12
        return
    end
    self.flash = { x = m.x, y = m.y, t = FLASH_T }
    self.mob, self.shot = nil, nil
    local b = self.boss
    if m.serv and b and (b.shield or 0) > 0 then
        b.shield = b.shield - 1
        b.hurt = 0.2
        if b.shield <= 0 then ns.Sfx.Play("big") end
        return
    end
    if m.elite and self.citadel and self.seals < C.SEALS then
        self.seals = self.seals + 1
    end
end
function Game:BossModel(g)
    if not g or not g.npc then return nil end
    local m = ensureModel(self.canvas)
    if not m then return nil end
    if m.shownNpc ~= g.npc then
        if m.ClearModel then pcall(m.ClearModel, m) end
        if not pcall(m.SetCreature, m, g.npc) then
            m.shownNpc = nil
            m:Hide()
            return nil
        end
        m.shownNpc = g.npc
        m.hold = C.MODEL_HOLD
    end
    return m
end
function Game:Note(text, sub, c)
    self.note = { text = text, sub = sub, c = c or C_MARK, t = NOTE_T }
end
local function biomeAt(y)
    local n = 1
    for i = 1, #BIOME do
        if y >= BIOME[i].h then n = i end
    end
    return n
end
function Game:Marks()
    local n = biomeAt(self.best)
    local grew = self.biomeN and n > self.biomeN
    self.biomeN = n
    if self.citadel then return end
    if grew then
        self:Note(ns.T(BIOME[n].name), tostring(BIOME[n].h), BIOME[n].hi)
    end
    if not self.tookRec and (self.recBest or 0) > 0 and self.best > self.recBest then
        self.tookRec = true
        self:Note(ns.T("jump.noteRecord"), tostring(floor(self.recBest)))
        ns.Sfx.Play("big")
    end
end
function Game:Hurt()
    if self.inv > 0 or self.phase ~= "play" then return end
    self.ride = nil
    if not self.citadel then self:EndGame() return end
    self.seals = self.seals - 1
    self.inv = C.SEAL_INV
    ns.Sfx.Play("pop")
    if self.seals <= 0 then self:EndGame() return end
    self.vy = BOUNCE * C.SEAL_KICK
end
function Game:Fire(dt)
    if self.shotCd > 0 then self.shotCd = self.shotCd - dt end
    local m, b = self.mob, self.boss
    if self.pin then m, b = nil, nil end
    local s = self.shot
    if s then
        local tx, ty, tr, atBoss, atPin
        if self.pin then tx, ty, tr, atPin = self.pin.x, self.pin.y + C.SPIKE_H / 2, 10, true
        elseif m then tx, ty, tr = m.x, m.y, mobHB(m)
        elseif b then tx, ty, tr, atBoss = b.x, b.y, C.BOSS_HB, true
        else self.shot = nil return end
        local dx = tx - s.x
        local dy = ty - s.y
        local d = sqrt(dx * dx + dy * dy)
        if d <= tr then
            self.shot = nil
            if atPin then
                self.pin.hp = self.pin.hp - 1
                ns.Sfx.Play("pop")
            elseif atBoss then self:DamageBoss(C.BOSS_SHOT)
            else self:DamageMob(C.BOSS_SHOT) end
            return
        end
        local step = SHOT_V * dt
        s.x = s.x + dx / d * step
        s.y = s.y + dy / d * step
        s.t = s.t - dt
        if s.t <= 0 then self.shot = nil end
        return
    end
    local t = m or b or self.pin
    if self.shotCd > 0 or not t then return end
    local sy = self.y + PSIZE / 2
    local dx = t.x - self.x
    local dy = t.y - sy
    if dx * dx + dy * dy > AIM_R * AIM_R then return end
    self.shot = { x = self.x, y = sy, t = SHOT_LIFE }
    self.shotCd = SHOT_CD
end
function Game:EndGame()
    if self.phase == "over" then return end
    self.phase = "over"
    self.phaseT = OVER_PAUSE
    ns.Sfx.Play("over")
end
function Game:Update(dt)
    if self.menu then
        self:Draw()
        return
    end
    self.t = self.t + dt
    if self.phase == "over" then
        self.phaseT = self.phaseT - dt
        self.vy = self.vy - GRAV * dt
        self.y = self.y + self.vy * dt
        self:Draw()
        return
    end
    local dir = 0
    if self.keyL then dir = dir - 1 end
    if self.keyR then dir = dir + 1 end
    local slip = false
    if self.slip and self.slip > 0 then
        self.slip = self.slip - dt
        slip = true
    end
    local rd = self.ride and RIDE[self.ride.k] or nil
    if rd and rd.steer == RIDE_LOCK then
        self.vx = 0
    elseif rd and rd.steer == RIDE_HOME then
        local c = self.W / 2
        if abs(c - self.x) < 4 then self.vx = 0
        else self.vx = (c > self.x) and RIDE_HOME_V or -RIDE_HOME_V end
    elseif not slip then
        local acc = SIDE_A * (rd and rd.acc or 1)
        if dir > 0 then
            self.vx = min(self.vx + acc * dt, SIDE_V)
        elseif dir < 0 then
            self.vx = max(self.vx - acc * dt, -SIDE_V)
        else
            self.vx = self.vx * (rd and rd.fric or FRICTION)
        end
    end
    self.x = self.x + self.vx * dt
    if self.vx > 20 then self.face = 1 elseif self.vx < -20 then self.face = -1 end
    local hw = PSIZE / 2
    if self.x < hw then self.x, self.vx = hw, 0
    elseif self.x > self.W - hw then self.x, self.vx = self.W - hw, 0 end
    for i = 1, #self.plat do
        local p = self.plat[i]
        if p.kind == 2 and not p.dead then
            p.x = p.x + p.vx * dt
            if p.x < 0 then p.x, p.vx = 0, -p.vx
            elseif p.x > self.W - PW then p.x, p.vx = self.W - PW, -p.vx end
        end
        if p.dying then
            p.dying = p.dying - dt
            if p.dying <= 0 then p.dying, p.dead = nil, true end
        end
        if p.spr then
            p.spr = p.spr - dt
            if p.spr <= 0 then p.spr = nil end
        end
    end
    if self.inv > 0 then self.inv = self.inv - dt end
    if self.squash > 0 then self.squash = self.squash - dt end
    local dr = self.drop
    if dr then
        dr.vy = dr.vy - GRAV * dt
        dr.y = dr.y + dr.vy * dt
        dr.t = dr.t - dt
        if dr.t <= 0 then self.drop = nil end
    end
    local m = self.mob
    if m then
        local r = mobHB(m)
        local d = m.art and ns.jumpMobs[m.art]
        if d and d.chase and abs(self.x - m.x) > 4 then
            m.vx = (self.x > m.x) and d.chase or -d.chase
        end
        m.x = m.x + m.vx * dt
        if m.x < r then m.x, m.vx = r, -m.vx
        elseif m.x > self.W - r then m.x, m.vx = self.W - r, -m.vx end
        if d and d.bob then
            m.y0 = m.y0 or m.y
            m.y = m.y0 + d.bob * math.sin(self.t * 3)
        end
        if m.y < self.cam - MOB_SIZE then self.mob, self.shot = nil, nil end
        if m.hurt then
            m.hurt = m.hurt - dt
            if m.hurt <= 0 then m.hurt = nil end
        end
    end
    local b = self.boss
    if b then
        b.x = b.x + b.vx * dt
        if b.x < C.BOSS_HB then b.x, b.vx = C.BOSS_HB, -b.vx
        elseif b.x > self.W - C.BOSS_HB then b.x, b.vx = self.W - C.BOSS_HB, -b.vx end
        if b.hurt then
            b.hurt = b.hurt - dt
            if b.hurt <= 0 then b.hurt = nil end
        end
        self:BossMech(dt, b)
    end
    local y0 = self.y
    if self.pin then
        self.vy, self.vx = 0, 0
        self.y = self.pin.y
    elseif self.ride then
        self.ride.t = self.ride.t - dt
        self.vy = RIDE[self.ride.k].v
        self.y = self.y + self.vy * dt
        if self.ride.t <= 0 then
            self:Dismount()
            self.vy = 0
        end
    else
        self.vy = self.vy - GRAV * dt
        self.y = self.y + self.vy * dt
    end
    local ceilY = nil
    if self.boss then
        ceilY = self.boss.y + C.BOSS_HB + C.ARENA_CEIL
    elseif self.gateY then
        ceilY = self.gateY - C.VAULT_H
    end
    if ceilY and self.y + PSIZE > ceilY then
        self.y = ceilY - PSIZE
        if self.vy > 0 then self.vy = 0 end
        if self.ride then self:Dismount() end
    end
    self:HitMob(y0)
    self:HitBoss(y0)
    self:HitFlame()
    self:HitShade()
    if self.phase == "play" and self.vy < 0 then self:Land(y0) end
    self:Fire(dt)
    if self.flash then
        self.flash.t = self.flash.t - dt
        if self.flash.t <= 0 then self.flash = nil end
    end
    if self.y - self.cam > self.mid then self.cam = self.y - self.mid end
    if self.gateCam and self.cam >= self.gateCam then
        self.cam = self.gateCam
        if not self.boss then self:StartFight() end
    end
    if self.y > self.best then
        self.best = self.y
        self:Marks()
    end
    if self.note then
        self.note.t = self.note.t - dt
        if self.note.t <= 0 then self.note = nil end
    end
    self:Prune()
    self:Fill()
    if self.y < self.cam - FALL_OUT then
        if self.boss then
            self:Hurt()
            if self.phase == "play" then
                self.y, self.vy = self.cam + 40, BOUNCE
            end
        else
            self:EndGame()
        end
    end
    self:Draw()
end
function Game:Start(seed, moves)
    ensureView(self.canvas)
    self.W = FIELD_W
    self.H = self.canvas.H or 480
    self.mid = self.H / 2
    self.rng = ns.RNG.New(seed)
    local pickRng = ns.RNG.New(seed)
    local name = ns.Shelves.Pick(ID, "plat", pickRng)
    self.badge = name and ns.IconPath(name) or nil
    local heroes = ns.jumpHeroes
    self.heroSeed = (type(heroes) == "table" and #heroes > 0) and pickRng:Int(#heroes) or nil
    self:HeroPick()
    for i = #self.plat, 1, -1 do self.plat[i] = nil end
    self.lastX = self.W / 2 - PW / 2
    self.lastKind, self.lastRisk = 1, false
    self.solidX, self.solidY = self.lastX, 0
    self.plat[1] = { x = self.lastX, y = 0, kind = 1, vx = 0, spring = false }
    self.top = 0
    self.x, self.y = self.W / 2, 0
    self.vx, self.vy = 0, BOUNCE
    self.face = 1
    self.keyL, self.keyR = false, false
    self.cam = -60
    self.best = 0
    self.t = 0
    self.phase, self.phaseT = "play", 0
    ensurePanel(self.canvas)
    ensureMenu(self.canvas)
    active = self
    local again = againAt and GetTime() - againAt < 0.5
    againAt = nil
    self.menu = not (moves and type(moves[1]) == "table") and not again
    self.menuDirty = self.menu
    self.mob, self.shot, self.flash = nil, nil, nil
    self.mobNext = MOB_FROM
    self.shotCd = 0
    self.gateY, self.gateCam = nil, nil
    self.paintH = nil
    self.citadel = (self.opts and self.opts.mode) == MODE_CITADEL
    local rec = ns.Records.Best(ID, { mode = (self.opts and self.opts.mode) or "classic" })
    self.recBest = rec and rec.score or 0
    self.note, self.tookRec = nil, false
    self.slip = 0
    self.biomeN = 1
    self.seals = self.citadel and C.SEALS or 0
    self.inv = 0
    self.ride, self.drop, self.squash = nil, nil, 0
    self.boss = nil
    self.gate = self.citadel and 1 or nil
    if self.citadel then self.mobNext = C.MOB_CITADEL_FROM end
    self:GateSync()
    self:Fill()
    if moves and type(moves[1]) == "table" and moves[1].k == "snap" then
        self:Restore(moves[1])
    end
    showView()
    self:Draw()
end
function Game:Key(action, down)
    if self.menu or self.phase == "over" then return end
    if action == "left" then self.keyL = down
    elseif action == "right" then self.keyR = down end
end
function Game:Move(move)
    if not move or move.k ~= "dir" then return end
    if self.phase == "over" then return end
    local d = tonumber(move.d)
    if not d then return end
    self.keyL, self.keyR = d < 0, d > 0
end
function Game:Click(x, y, button)
end
function Game:Score()
    return floor(max(self.best or 0, 0))
end
function Game:IsOver()
    return self.phase == "over" and self.phaseT <= 0
end
function Game:Stop()
    if self.phase == "over" and not self.menu then againAt = GetTime() end
    hideView()
    if ui then ui.root:Hide() end
    if menu then menu.root:Hide() end
    active = nil
end
function Game:Serialize()
    local pl = {}
    for i = 1, #self.plat do
        local p = self.plat[i]
        if not p.dead and not p.dying then
            local n = #pl
            pl[n + 1], pl[n + 2], pl[n + 3] = p.x, p.y, p.kind
            pl[n + 4], pl[n + 5], pl[n + 6] = p.vx, p.spring and 1 or 0, p.ride or 0
        end
    end
    local m, s, b = self.mob, self.shot, self.boss
    return {
        k = "snap", v = 4,
        rd = self.ride and self.ride.k, rdt = self.ride and self.ride.t,
        x = self.x, y = self.y, vx = self.vx, vy = self.vy,
        cam = self.cam, best = self.best, top = self.top,
        lx = self.lastX, lk = self.lastKind, sdx = self.solidX, sdy = self.solidY,
        t = self.t, phase = self.phase, pt = self.phaseT, fc = self.face,
        mx = m and m.x, my = m and m.y, my0 = m and m.y0, mvx = m and m.vx, ma = m and m.art,
        mhp = m and m.hp, mel = (m and m.elite) and 1 or nil,
        msv = (m and m.serv) and 1 or nil,
        mn = self.mobNext, scd = self.shotCd, slp = self.slip,
        sl = self.seals, gt = self.gate, iv = self.inv,
        bx = b and b.x, by = b and b.y, bvx = b and b.vx,
        bhp = b and b.hp, bhm = b and b.hpMax, bsh = b and b.shield,
        sx = s and s.x, sy = s and s.y, st = s and s.t,
        rng = self.rng:State(),
        plat = pl,
    }
end
function Game:Restore(s)
    if s.v ~= 4 then return end
    self.cam  = ns.Store.Num(s.cam, -100, 1e9, self.cam)
    self.x    = ns.Store.Num(s.x, 0, self.W, self.W / 2)
    self.y    = ns.Store.Num(s.y, self.cam - FALL_OUT, self.cam + self.H + 300, self.cam + 60)
    self.vx   = ns.Store.Num(s.vx, -SIDE_V, SIDE_V, 0)
    self.vy   = ns.Store.Num(s.vy, -3000, BOUNCE * SPRING_MUL, 0)
    self.best = ns.Store.Num(s.best, 0, 1e9, self.y)
    self.t    = ns.Store.Num(s.t, 0, 1e6, 0)
    self.slip = ns.Store.Num(s.slp, 0, ICE_SLIP, 0)
    self.biomeN = biomeAt(self.best)
    self.tookRec = self.best > (self.recBest or 0)
    self.note = nil
    self.keyL, self.keyR = false, false
    self.lastKind = ns.Store.Num(s.lk, 1, KINDS, 1)
    self.lastRisk = (self.lastKind == 3) or (self.lastKind == ICE)
    self.lastX    = ns.Store.Num(s.lx, 0, self.W - PW, self.W / 2 - PW / 2)
    self.face   = (ns.Store.Num(s.fc, -1, 1, 1) < 0) and -1 or 1
    self.phase  = (s.phase == "over") and "over" or "play"
    self.phaseT = ns.Store.Num(s.pt, 0, OVER_PAUSE, 0)
    if s.rng then self.rng = ns.RNG.Restore(s.rng) end
    for i = #self.plat, 1, -1 do self.plat[i] = nil end
    local pl = type(s.plat) == "table" and s.plat or {}
    for i = 1, floor(#pl / 6) * 6, 6 do
        local kind = floor(ns.Store.Num(pl[i + 2], 1, KINDS, 1))
        local ride = floor(ns.Store.Num(pl[i + 5], 0, #RIDE, 0))
        self.plat[#self.plat + 1] = {
            x = ns.Store.Num(pl[i], 0, self.W - PW, 0),
            y = ns.Store.Num(pl[i + 1], self.cam - FALL_OUT - PH, self.cam + self.H + 300, self.cam),
            kind = kind,
            vx = ns.Store.Num(pl[i + 3], -MOVE_V, MOVE_V, 0),
            spring = kind == 1 and ns.Store.Num(pl[i + 4], 0, 1, 0) > 0,
            ride = (kind == 1 and ride > 0) and ride or nil,
        }
    end
    table.sort(self.plat, function(a, b) return a.y < b.y end)
    local last = self.plat[#self.plat]
    self.top = ns.Store.Num(s.top, self.cam - self.H, self.cam + self.H + 300,
                   last and last.y or self.cam)
    if last and last.y > self.top then self.top = last.y end
    self.solidX, self.solidY = self.lastX, self.top
    for i = #self.plat, 1, -1 do
        local p = self.plat[i]
        if p.kind ~= 3 then
            self.solidX, self.solidY = p.x, p.y
            break
        end
    end
    self.solidX = ns.Store.Num(s.sdx, 0, self.W - PW, self.solidX)
    self.solidY = ns.Store.Num(s.sdy, self.cam - self.H, self.cam + self.H + 300, self.solidY)
    self.mobNext = ns.Store.Num(s.mn, 0, 1e9, MOB_FROM)
    self.shotCd  = ns.Store.Num(s.scd, 0, SHOT_CD, 0)
    local rk = s.rd and floor(ns.Store.Num(s.rd, 1, #RIDE, 1)) or nil
    if rk then
        self.ride = { k = rk, t = ns.Store.Num(s.rdt, 0, RIDE[rk].t, RIDE[rk].t) }
    else
        self.ride = nil
    end
    if self.citadel then
        self.seals = floor(ns.Store.Num(s.sl, 1, C.SEALS, C.SEALS))
        self.gate  = floor(ns.Store.Num(s.gt, 1, #(ns.jumpGates or {}) + 1, 1))
        self.inv   = ns.Store.Num(s.iv, 0, C.SEAL_INV, 0)
        self:GateSync()
    end
    self.boss = nil
    self.pool, self.shade = nil, nil
    if self.citadel and s.bx and s.bhp then
        local hpMax = ns.Store.Num(s.bhm, 1, 999, 12)
        local g = ns.jumpGates and ns.jumpGates[self.gate]
        local shMax = (g and g.key == "deathwhisper") and C.SHIELD_N or 0
        self.boss = {
            x = ns.Store.Num(s.bx, C.BOSS_HB, self.W - C.BOSS_HB, self.W / 2),
            y = ns.Store.Num(s.by, self.cam, self.cam + self.H, self.cam + self.H - 130),
            vx = ns.Store.Num(s.bvx, -C.BOSS_V, C.BOSS_V, C.BOSS_V),
            hp = ns.Store.Num(s.bhp, 1, hpMax, hpMax),
            hpMax = hpMax,
            mech = g and g.key,
            shield = ns.Store.Num(s.bsh, 0, shMax, shMax),
            shieldMax = shMax,
            flameT = C.FLAME_EVERY, spikeT = C.SPIKE_EVERY, stormT = C.STORM_EVERY,
            servT = C.SERV_EVERY, poolT = C.POOL_EVERY, shadeT = C.SHADE_EVERY,
        }
    end
    self.mob, self.shot, self.flash = nil, nil, nil
    if s.mx and s.my then
        local elite = ns.Store.Num(s.mel, 0, 1, 0) > 0
        self.mob = {
            x = ns.Store.Num(s.mx, MOB_HB, self.W - MOB_HB, self.W / 2),
            y = ns.Store.Num(s.my, self.cam - MOB_SIZE, self.cam + self.H + 300, self.cam + 100),
            vx = ns.Store.Num(s.mvx, -200, 200, MOB_V),
            y0 = s.my0 and ns.Store.Num(s.my0, self.cam - self.H, self.cam + self.H + 300, s.my) or nil,
            art = floor(ns.Store.Num(s.ma, 1, #(ns.jumpMobs or {}), 1)),
            elite = elite or nil,
            serv = (ns.Store.Num(s.msv, 0, 1, 0) > 0) or nil,
            hp = ns.Store.Num(s.mhp, 1, C.ELITE_HP, elite and C.ELITE_HP or 1),
        }
        if s.sx and s.sy then
            self.shot = {
                x = ns.Store.Num(s.sx, 0, self.W, self.x),
                y = ns.Store.Num(s.sy, self.cam - 100, self.cam + self.H + 300, self.y),
                t = ns.Store.Num(s.st, 0, SHOT_LIFE, SHOT_LIFE),
            }
        end
    end
    self:Fill()
end
function Game:HeroPick()
    hideHeroes()
    self.heroIdx, self.heroTex = nil, nil
    local heroes = ns.jumpHeroes
    if type(heroes) ~= "table" or #heroes == 0 then return end
    local pick = ns.Config.Get(ID, "hero", 0)
    if type(pick) ~= "number" or pick < 1 or pick > #heroes then pick = self.heroSeed end
    if not pick then return end
    self.heroIdx = pick
    self.heroTex = ensureHero(pick)
end
function Game:BeginRound()
    if not self.menu then return end
    self.menu = false
    self:Draw()
end
function Game:ToMenu()
    if self.menu then return end
    if self.best <= 0 and self.phase == "play" then
        self.menu = true
        self.menuDirty = true
        self:Draw()
        return
    end
    if ns.window and ns.window.Restart then ns.window:Restart() end
end
function Game:PickMode(mode)
    if not self.menu then return end
    local cur = (self.opts and self.opts.mode) or "classic"
    if cur == mode then return end
    ns.window:StartGame(ID, { mode = mode })
end
function Game:MenuSync()
    menu.heroCap:SetText(ns.T("jump.heroCap"))
    menu.play:SetText(ns.T("jump.play"))
    local mode = (self.opts and self.opts.mode) or "classic"
    menu.mapCap:SetText(ns.T("jump.menuMap"))
    local map = (mode == MODE_CITADEL)
    menu.right:ClearAllPoints()
    menu.right:SetPoint("TOPLEFT", menu.root, "TOPLEFT", map and M.rightX or M.rightSolo, 0)
    menu.right:SetPoint("BOTTOM", menu.root, "BOTTOM", 0, 0)
    if map then menu.mapCap:Show(); menu.column:Show()
    else menu.mapCap:Hide(); menu.column:Hide() end
    if not map then
        for i = 1, M.mapRows do
            local r = menu.floor[i]
            r.bar:Hide(); r.name:Hide(); r.at:Hide()
            floorMark(r, "none")
        end
        return self:MenuSyncRight(mode)
    end
    local rows = self:MapRows()
    local span = (M.mapRows - 1) * M.mapStep
    local step = (#rows > 1) and (span / (#rows - 1)) or span
    for i = 1, M.mapRows do
        local r, d = menu.floor[i], rows[i]
        if not d then
            r.bar:Hide(); r.name:Hide(); r.at:Hide()
            floorMark(r, "none")
        else
            r.bar:Show(); r.name:Show(); r.at:Show()
            placeRow(r, M.mapY + (#rows - i) * step, d.tall and (step - 10) or 6)
            r.name:SetText(d.name)
            r.at:SetText(d.note)
            local c = d.c
            if d.taken then
                ns.Paint(r.bar, c[1], c[2], c[3], 1)
                r.name:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
            else
                ns.Paint(r.bar, c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 1)
                r.name:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
            end
            if d.dim then r.name:SetTextColor(C_DIM[1], C_DIM[2], C_DIM[3]) end
            floorMark(r, d.mark)
        end
    end
    self:MenuSyncRight(mode)
end
function Game:MenuSyncRight(mode)
    menu.body:ClearAllPoints()
    menu.body:SetPoint("TOPLEFT", menu.right, "TOPLEFT", 0,
                       CITADEL_ON and 0 or (M.cardY[2] - M.cardY[1]))
    menu.body:SetPoint("BOTTOM", menu.right, "BOTTOM", 0, 0)
    for i = 1, 2 do
        local c = menu.card[i]
        if i > 1 and not CITADEL_ON then c:Hide() else c:Show() end
        local on = (c.mode == mode)
        ns.Paint(c.bg, on and 0.14 or 0.09, on and 0.11 or 0.08, on and 0.08 or 0.06, 0.92)
        for k = 1, 4 do
            if on then ns.Paint(c.edge[k], 0.79, 0.63, 0.29, 1)
            else ns.Paint(c.edge[k], 0.28, 0.24, 0.18, 1) end
        end
        c.title:SetText(ns.T(c.mode == MODE_CITADEL and "jump.modeCitadel" or "jump.modeClassic"))
        c.sub:SetText(ns.T(c.mode == MODE_CITADEL and "jump.modeCitadelTip" or "jump.modeClassicTip"))
        local rec = ns.Records.Best(ID, { mode = c.mode })
        c.rec:SetText(rec and (ns.T("jump.panelBest") .. ": " .. (rec.score or 0))
                      or ns.T("jump.menuEmpty"))
    end
    local pick = ns.Config.Get(ID, "hero", 0)
    for i = 1, #menu.hero do
        local b = menu.hero[i]
        local on = (b.hero or 0) == pick
        ns.Paint(b.bg, on and 0.16 or 0.09, on and 0.12 or 0.08, on and 0.07 or 0.06, 0.92)
        for k = 1, 4 do
            if on then ns.Paint(b.edge[k], 0.79, 0.63, 0.29, 1)
            else ns.Paint(b.edge[k], 0.26, 0.22, 0.17, 1) end
        end
        if b.anyCap then b.anyCap:SetText(ns.T("jump.heroAny")) end
    end
    if CITADEL_ON then
        menu.tableCap:SetText(ns.T("jump.menuTable") .. " — " ..
            ns.T(mode == MODE_CITADEL and "jump.modeCitadel" or "jump.modeClassic"))
    else
        menu.tableCap:SetText(ns.T("jump.menuTable"))
    end
    local list = ns.Records.List(ID, { mode = mode })
    local top = list[1] and (list[1].score or 0) or 0
    for i = 1, #menu.row do
        local r, rec = menu.row[i], list[i]
        if rec then
            local v = rec.score or 0
            r.n:SetText(i .. ".")
            r.at:SetText(rec.at and date("%d.%m", rec.at) or "")
            r.score:SetText(tostring(v))
            r.n:Show(); r.at:Show(); r.score:Show()
            local w = (top > 0) and (M.barW * v / top) or 0
            if w < 2 then w = 2 end
            r.bar:SetWidth(w)
            if i == 1 then ns.Paint(r.bar, 0.79, 0.63, 0.29, 0.9)
            else ns.Paint(r.bar, 0.42, 0.34, 0.22, 0.9) end
            r.bar:Show()
        else
            r.n:Hide(); r.at:Hide(); r.score:Hide(); r.bar:Hide()
        end
    end
end
function Game:PickHero(idx)
    ns.Config.Set(ID, "hero", idx or 0)
    self:HeroPick()
    self.menuDirty = true
end
function Game:PanelSync()
    if not ui then return end
    if self.menu then
        ui.root:Hide()
        return
    end
    ui.root:Show()
    ui.tally:Sync()
    ui.bestCap:SetText(ns.T("jump.panelBest"))
    ui.toMenu:SetText(ns.T("jump.toMenu"))
    ui.best:SetText(tostring(self.recBest or 0))
    ui.floorCap:Show()
    ui.floor:Show()
    if self.citadel then
        local g = self.gate and (ns.jumpGates or {})[self.gate]
        ui.floorCap:SetText(ns.T("jump.panelFloor"))
        ui.floor:SetText(g and ns.T("jump.boss" .. g.key) or ns.T("jump.floorAhead"))
    else
        ui.floorCap:SetText(ns.T("jump.panelBiome"))
        ui.floor:SetText(ns.T(BIOME[self.biomeN or 1].name))
    end
end
ns.OnLocale(function()
    if not active or not active.def or active.def.id ~= ID then return end
    active.menuDirty = true
    active:Draw()
end)
function Game:PaintBiome(h)
    if self.paintH and abs(h - self.paintH) < 20 then return end
    self.paintH = h
    local a, b, t = BIOME[1], BIOME[1], 0
    for i = 1, #BIOME - 1 do
        if h >= BIOME[i].h then
            a, b = BIOME[i], BIOME[i + 1]
            t = (h - a.h) / (b.h - a.h)
            if t > 1 then t = 1 end
        end
    end
    if h >= BIOME[#BIOME].h then a, b, t = BIOME[#BIOME], BIOME[#BIOME], 0 end
    local lo1, lo2, lo3 = mix3(a.lo, b.lo, t)
    local hi1, hi2, hi3 = mix3(a.hi, b.hi, t)
    for i = 1, SKY_BANDS do
        local k = (i - 1) / (SKY_BANDS - 1)
        ns.Paint(view.band[i], lo1 + (hi1 - lo1) * k,
                                lo2 + (hi2 - lo2) * k,
                                lo3 + (hi3 - lo3) * k, 1)
    end
    local w1, w2, w3 = mix3(a.wall, b.wall, t)
    ns.Paint(view.wallBase[1], w1, w2, w3, 1)
    ns.Paint(view.wallBase[2], w1, w2, w3, 1)
    local m1, m2, m3 = w1 * 1.55 + 0.03, w2 * 1.55 + 0.03, w3 * 1.55 + 0.03
    local d1, d2, d3 = w1 * 0.55, w2 * 0.55, w3 * 0.55
    for i = 1, ROWS do
        local r = view.row[i]
        ns.Paint(r[1], m1, m2, m3, 1)
        ns.Paint(r[2], m1, m2, m3, 1)
        for j = 3, 6 do ns.Paint(r[j], d1, d2, d3, 1) end
    end
    local f1, f2, f3 = mix3(a.far, b.far, t)
    for i = 1, FAR_N do
        local e = view.far[i]
        ns.Paint(e[1], f1, f2, f3, 0.14)
        ns.Paint(e[2], f1, f2, f3, 0.18)
        ns.Paint(e[3], f1, f2, f3, 0.22)
    end
    self.torchA = a.torch + (b.torch - a.torch) * t
end
function Game:DrawWalls(cam)
    local canvas = self.canvas
    local off = (cam * PX_WALL) % ROW_H
    for i = 1, ROWS do
        local y = (i - 1) * ROW_H - off
        local r = view.row[i]
        place(r[1], canvas, 0, y, WALL_W, 1)
        place(r[2], canvas, FIELD_X + FIELD_W, y, WALL_W, 1)
        local sh = (i % 2 == 0) and 26 or 0
        place(r[3], canvas, 34 + sh, y + 1, 2, ROW_H - 2)
        place(r[4], canvas, 108 + sh, y + 1, 2, ROW_H - 2)
        place(r[5], canvas, FIELD_X + FIELD_W + 26 + sh, y + 1, 2, ROW_H - 2)
        place(r[6], canvas, FIELD_X + FIELD_W + 100 + sh, y + 1, 2, ROW_H - 2)
    end
    local alpha = self.torchA or 1
    local flick = 0.86 + 0.14 * math.sin(self.t * 7)
    for i = 1, TORCH_N * 2 do
        local t = view.torch[i]
        if alpha <= 0.02 then
            t.arm:Hide(); t.glow:Hide(); t.fire:Hide()
        else
            local side = (i <= TORCH_N) and 0 or 1
            local x = (side == 0) and 84 or (FIELD_X + FIELD_W + 78)
            local j = (side == 0) and i or (i - TORCH_N)
            local span = TORCH_STEP * TORCH_N
            local y = ((j - 1) * TORCH_STEP + side * 130 - cam * PX_WALL) % span - 30
            place(t.arm, canvas, x, y, 5, 12)
            t.glow:SetAlpha(alpha * flick)
            if placeIcon(t.glow, canvas, x + 2, y + 20, 44) then
                place(t.fire, canvas, x, y + 12, 5, 9)
                t.fire:SetAlpha(alpha)
            else
                t.fire:Hide()
            end
            t.arm:SetAlpha(alpha)
        end
    end
end
function Game:DrawFar(cam)
    local canvas = self.canvas
    local span = FAR_STEP * FAR_N
    for i = 1, FAR_N do
        local d = FAR[i]
        local x = FIELD_X + d[1]
        local y = (d[2] - cam * PX_FAR) % span - 80
        local h = d[3]
        local e = view.far[i]
        place(e[1], canvas, x, y, 48, h)
        place(e[2], canvas, x + 7, y + h, 34, 8)
        place(e[3], canvas, x + 14, y + h + 8, 20, 6)
    end
end
function Game:DrawDust(cam)
    local canvas = self.canvas
    for i = 1, DUST_N do
        local d = DUST[i]
        local y = (d[2] - cam * PX_DUST) % DUST_SPAN - 20
        place(view.dust[i], canvas, FIELD_X + d[1], y, 2, 2)
    end
end
function Game:DrawRuler(cam)
    local canvas = self.canvas
    local top = cam + self.H
    local n = 0
    local h = floor(max(cam, 0) / RULER_MINOR) * RULER_MINOR
    while h <= top and n < #view.tick do
        if h % RULER_MAJOR ~= 0 and h >= 0 then
            n = n + 1
            place(view.tick[n], canvas, RULER_X + 12, h - cam, 10, 1)
        end
        h = h + RULER_MINOR
    end
    for i = n + 1, #view.tick do view.tick[i]:Hide() end
    n = 0
    h = floor(max(cam, 0) / RULER_MAJOR) * RULER_MAJOR
    while h <= top and n < #view.big do
        if h >= 0 then
            n = n + 1
            local y = h - cam
            place(view.big[n], canvas, RULER_X, y, 22, 1)
            local s = view.label[n]
            if y >= 6 and y <= self.H - 12 then
                if s.drawn ~= h then
                    s.drawn = h
                    s:SetText(tostring(h))
                end
                s:ClearAllPoints()
                s:SetPoint("RIGHT", canvas, "BOTTOMLEFT", RULER_X - 4, y + 4)
                s:Show()
            else
                s:Hide()
            end
        end
        h = h + RULER_MAJOR
    end
    for i = n + 1, #view.big do
        view.big[i]:Hide()
        view.label[i]:Hide()
    end
    self:DrawMark(cam)
end
function Game:DrawSlip(cam)
    local s = self.slip or 0
    if s <= 0 or self.phase ~= "play" then
        hideAll(view.slipMark)
        return
    end
    local canvas = self.canvas
    local k = s / ICE_SLIP
    local dir = (self.vx >= 0) and -1 or 1
    local y = self.y - cam
    for i = 1, 3 do
        local w = 5 + 4 * k
        place(view.slipMark[i], canvas,
              FIELD_X + self.x + dir * (PSIZE / 2 + (i - 1) * 6), y + 1 + (i - 1) * 3,
              w, 2)
    end
end
function Game:DrawMark(cam)
    local r = self.recBest or 0
    local y = r - cam
    if r <= 0 or y < 4 or y > self.H - 4 then
        view.markLine:Hide()
        view.markTip:Hide()
        view.markText:Hide()
        return
    end
    local canvas = self.canvas
    place(view.markLine, canvas, FIELD_X, y, FIELD_W, 1)
    place(view.markTip, canvas, FIELD_X, y - 2, 5, 5)
    if view.markText.drawn ~= r then
        view.markText.drawn = r
        view.markText:SetText(ns.T("jump.noteRecord") .. "  " .. floor(r))
    end
    view.markText:ClearAllPoints()
    view.markText:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", FIELD_X + 8, y + 3)
    view.markText:Show()
end
function Game:DrawNote()
    local nt = self.note
    if not nt then
        view.note:Hide()
        view.noteSub:Hide()
        return
    end
    local a = (nt.t < NOTE_FADE) and (nt.t / NOTE_FADE) or 1
    local c = nt.c
    view.note:SetText(nt.text)
    view.note:SetTextColor(c[1], c[2], c[3], a)
    view.note:ClearAllPoints()
    view.note:SetPoint("CENTER", self.canvas, "BOTTOMLEFT", FIELD_X + FIELD_W / 2, self.H * 0.72)
    view.note:Show()
    if nt.sub then
        view.noteSub:SetText(nt.sub)
        view.noteSub:SetTextColor(c[1] * 0.8, c[2] * 0.8, c[3] * 0.8, a * 0.9)
        view.noteSub:ClearAllPoints()
        view.noteSub:SetPoint("CENTER", self.canvas, "BOTTOMLEFT",
                              FIELD_X + FIELD_W / 2, self.H * 0.72 - 18)
        view.noteSub:Show()
    else
        view.noteSub:Hide()
    end
end
function Game:DrawGate(cam)
    local canvas = self.canvas
    local v = view.vault
    local y = self.gateY and (self.gateY - cam) or nil
    if not y or y < 0 or y > self.H + C.VAULT_H then
        for i = 1, #v do v[i]:Hide() end
        return
    end
    local top = y - C.VAULT_H
    for i = 1, 8 do
        place(v[i], canvas, FIELD_X + 4 + (i - 1) * 37, top, 35, C.VAULT_H)
    end
    place(v[9], canvas, FIELD_X, top - 3, FIELD_W, 3)
    place(v[10], canvas, FIELD_X + 46, top - 11, 4, 8)
    place(v[11], canvas, FIELD_X + 152, top - 14, 4, 11)
    place(v[12], canvas, FIELD_X + 244, top - 10, 4, 7)
end
function Game:DrawHud()
    local canvas = self.canvas
    local b = self.boss
    if b then
        place(view.hpBack, canvas, FIELD_X + 10, self.H - C.VAULT_H - 22, FIELD_W - 20, 12)
        local w = (FIELD_W - 24) * max(b.hp, 0) / b.hpMax
        place(view.hpFill, canvas, FIELD_X + 12, self.H - C.VAULT_H - 20, w, 8)
        if (b.shield or 0) > 0 then
            local sw = (FIELD_W - 24) * b.shield / b.shieldMax
            place(view.shFill, canvas, FIELD_X + 12, self.H - C.VAULT_H - 20, sw, 8)
            place(view.shEdge, canvas, FIELD_X + 12, self.H - C.VAULT_H - 14, sw, 2)
        else
            view.shFill:Hide()
            view.shEdge:Hide()
        end
    else
        view.hpBack:Hide()
        view.hpFill:Hide()
        view.shFill:Hide()
        view.shEdge:Hide()
    end
    for i = 1, C.SEALS do
        if self.citadel then
            local sy = self.H - 90 - (i - 1) * 28
            place(view.seal[i], canvas, 112, sy, 22, 22)
            if i <= self.seals then
                place(view.sealDot[i], canvas, 117, sy + 5, 12, 12)
            else
                view.sealDot[i]:Hide()
            end
        else
            view.seal[i]:Hide()
            view.sealDot[i]:Hide()
        end
    end
end
function Game:DrawPlates(cam)
    local canvas = self.canvas
    platPool:Reset()
    for i = 1, #self.plat do
        local p = self.plat[i]
        if not p.dead then
            local sy = p.y - cam
            if sy > -PH - 4 and sy < self.H + SPRING_H + 4 then
                local f = platPool:Acquire()
                if f.kindDrawn ~= p.kind or f.springDrawn ~= (p.spring and true or false) then
                    f.kindDrawn = p.kind
                    f.springDrawn = p.spring and true or false
                    paintPlate(f, p.kind, p.spring)
                end
                local w, a = PW, 1
                if p.dying then
                    local k = p.dying / CRUMBLE_T
                    if k < 0 then k = 0 end
                    a = k
                    w = PW * (0.4 + 0.6 * k)
                end
                f:SetAlpha(a)
                local x = FIELD_X + p.x + (PW - w) / 2
                local y = sy - PH
                place(f.body, canvas, x, y, w, PH)
                place(f.edge, canvas, x, y + PH - 2, w, 2)
                place(f.shade, canvas, x, y, w, 2)
                if PLATE[p.kind][4] then
                    place(f.capL, canvas, x, y, 4, PH)
                    place(f.capR, canvas, x + w - 4, y, 4, PH)
                end
                if p.kind == 2 then
                    place(f.mark1, canvas, x + 5, y + 4, 3, 3)
                    place(f.mark2, canvas, x + w - 8, y + 4, 3, 3)
                elseif p.kind == 3 then
                    place(f.mark1, canvas, x + 12, y + PH - 3, 6, 3)
                    place(f.mark2, canvas, x + w - 22, y + PH - 3, 5, 3)
                elseif p.kind == ICE then
                    place(f.mark1, canvas, x + 13, y - 7, 3, 7)
                    place(f.mark2, canvas, x + w - 19, y - 5, 3, 5)
                end
                if p.spring then
                    local k = 1
                    if p.spr then k = 0.45 + 0.55 * (1 - p.spr / SPRING_T) end
                    local sh = SPRING_H * k
                    local sx = x + (w - SPRING_W) / 2
                    for j = 1, 3 do
                        place(f.coil[j], canvas, sx, sy + 2 + (j - 1) * (sh - 8) / 2,
                              SPRING_W, 2)
                    end
                    place(f.cap, canvas, sx, sy + sh - 3, SPRING_W, 3)
                end
                if p.ride then
                    local rd = RIDE[p.ride]
                    local list = ns.JumpRideFrame(rd, rd.still or 0)
                    if f.rideDrawn ~= p.ride then
                        f.rideDrawn = p.ride
                        ns.JumpRidePaint(rd, f.ride, list)
                    end
                    local cx, ry = x + w / 2, sy + (rd.py or 0)
                    for j = 1, RIDE.parts do
                        local a = list[j]
                        if a then place(f.ride[j], canvas, cx + a[1], ry + a[2], a[3], a[4])
                        else f.ride[j]:Hide() end
                    end
                elseif f.rideDrawn then
                    f.rideDrawn = nil
                    for j = 1, RIDE.parts do f.ride[j]:Hide() end
                end
                if f.badgeDrawn ~= self.badge then
                    f.badgeDrawn = self.badge
                    if self.badge then
                        f.badge:SetTexture(self.badge)
                        ns.CropIcon(f.badge)
                    end
                end
                if self.badge then
                    placeIcon(f.badge, canvas, x + w / 2, y + PH / 2, PH)
                else
                    f.badge:Hide()
                end
            end
        end
    end
    platPool:HideExtras()
end
function Game:DrawActors(cam)
    local canvas = self.canvas
    local b = self.boss
    local mdl = b and self:BossModel(ns.jumpGates[self.gate]) or nil
    if mdl then
        local g = ns.jumpGates[self.gate]
        local cx, cy = FIELD_X + b.x, b.y - cam
        if cx - C.MODEL_W / 2 >= 0 and cx + C.MODEL_W / 2 <= 640
           and cy - C.MODEL_H / 2 >= 0 and cy + C.MODEL_H / 2 <= self.H then
            hideBossArt()
            local c = g.cam or {}
            mdl:ClearAllPoints()
            mdl:SetPoint("CENTER", canvas, "BOTTOMLEFT", cx, cy)
            mdl:SetAlpha(b.hurt and 0.55 or 1)
            if (mdl.hold or 0) > 0 then
                mdl.hold = mdl.hold - 1 / 60
                if mdl.SetModelScale then pcall(mdl.SetModelScale, mdl, c.s or 1) end
                if mdl.SetPosition then pcall(mdl.SetPosition, mdl, c.x or 0, c.y or 0, c.z or 0) end
            end
            if mdl.SetRotation then
                pcall(mdl.SetRotation, mdl, (b.vx < 0) and -(c.r or 0.4) or (c.r or 0.4))
            end
            mdl:Show()
        else
            mdl:Hide()
        end
    elseif view.model then
        view.model:Hide()
    end
    local bart = (b and not mdl) and ensureBoss(self.gate) or nil
    if bart then
        hideBossArt(self.gate)
        local g = ns.jumpGates[self.gate]
        local sc = g.scale or 2
        local x0 = FIELD_X + b.x - 15 * sc
        local by = b.y - cam - 17 * sc
        local flip = b.vx < 0
        view.bossSheet:SetAlpha(b.hurt and 0.55 or 1)
        for i = 1, #bart do
            local p = g.art[i]
            local px = flip and (30 - p[1] - p[3]) or p[1]
            place(bart[i], canvas, x0 + px * sc, by + p[2] * sc, p[3] * sc, p[4] * sc)
        end
    else
        hideBossArt()
    end
    local m = self.mob
    local art = m and m.art and ensureMob(m.art) or nil
    if art then
        hideMobArt(m.art)
        local parts = ns.jumpMobs[m.art].parts
        local sc = m.elite and C.ELITE_SCALE or 1
        local x0 = FIELD_X + m.x - MOB_SIZE * sc / 2
        local by = m.y - cam - MOB_SIZE * sc / 2
        local flip = (m.vx or 0) < 0
        for i = 1, #art do
            local p = parts[i]
            local px = flip and (MOB_SIZE - p[1] - p[3]) or p[1]
            place(art[i], canvas, x0 + px * sc, by + p[2] * sc, p[3] * sc, p[4] * sc)
        end
    else
        hideMobArt()
    end
    local s = self.shot
    if s then
        local cx, cy = FIELD_X + s.x, s.y - cam
        if placeIcon(view.shotGlow, canvas, cx, cy, SHOT_SIZE * 2) then
            place(view.shotCore, canvas, cx - 2, cy - 2, 4, 4)
        else
            view.shotCore:Hide()
        end
    else
        view.shotGlow:Hide()
        view.shotCore:Hide()
    end
    local fl = self.flash
    if fl then
        local k = fl.t / FLASH_T
        view.flash:SetAlpha(k)
        view.flash:SetVertexColor(1, 0.85, 0.55)
        placeIcon(view.flash, canvas, FIELD_X + fl.x, fl.y - cam,
                  MOB_SIZE * (1.6 - 0.6 * k))
    else
        view.flash:Hide()
    end
    local hero = self.heroTex
    if hero then
        local parts = ns.jumpHeroes[self.heroIdx].parts
        local sx, sy = 1, 1
        if self.squash > 0 and self.phase == "play" then
            local k = self.squash / SQUASH_T
            sx, sy = 1 + 0.16 * k, 1 - 0.24 * k
        elseif self.vy > BOUNCE * 0.6 and not self.ride then
            sx, sy = 0.94, 1.08
        end
        local cx = FIELD_X + self.x
        local by = self.y - cam
        local flip = self.face < 0
        for i = 1, #hero do
            local p = parts[i]
            local px = flip and (PSIZE - p[1] - p[3]) or p[1]
            place(hero[i], canvas, cx + (px - PSIZE / 2) * sx, by + p[2] * sy,
                  p[3] * sx, p[4] * sy)
        end
    end
    self:DrawMech(cam)
    self:DrawAim(cam)
end
function Game:DrawMech(cam)
    local canvas = self.canvas
    local f, sp, b = self.flame, self.spike, self.boss
    if f then
        local y = f.y - cam
        local lw = f.x - max(f.l, 0)
        local rw = min(f.r, self.W) - f.x
        place(view.flame[1], canvas, FIELD_X + max(f.l, 0), y - C.FLAME_H / 2, lw, C.FLAME_H)
        place(view.flame[2], canvas, FIELD_X + f.x, y - C.FLAME_H / 2, rw, C.FLAME_H)
        place(view.flame[3], canvas, FIELD_X + max(f.l, 0), y + C.FLAME_H / 2 - 2, lw, 2)
        place(view.flame[4], canvas, FIELD_X + f.x, y + C.FLAME_H / 2 - 2, rw, 2)
    else
        for i = 1, 4 do view.flame[i]:Hide() end
    end
    if sp then
        local y = sp.y - cam
        local h = C.SPIKE_H
        local blink = (sp.t < 1 and floor(sp.t * 10) % 2 == 0)
        if blink then
            for i = 1, 4 do view.spike[i]:Hide() end
        else
            place(view.spike[4], canvas, FIELD_X + sp.x - C.SPIKE_W / 2 - 2, y, C.SPIKE_W + 4, 4)
            place(view.spike[1], canvas, FIELD_X + sp.x - C.SPIKE_W / 2, y + 2, C.SPIKE_W, h - 8)
            place(view.spike[2], canvas, FIELD_X + sp.x - C.SPIKE_W / 2, y + 2, 3, h - 8)
            place(view.spike[3], canvas, FIELD_X + sp.x - 3, y + h - 6, 6, 6)
        end
    else
        for i = 1, 4 do view.spike[i]:Hide() end
    end
    local pl = self.pool
    if pl then
        local y = pl.y - cam
        local grow = pl.t > C.POOL_LIFE
        local k = grow and (1 - (pl.t - C.POOL_LIFE) / C.POOL_WARN) or 1
        local w = C.POOL_W * (0.35 + 0.65 * k)
        local x = FIELD_X + pl.x - w / 2
        local fade = (not grow and pl.t < 0.8 and floor(pl.t * 10) % 2 == 0)
        if fade then
            hideAll(view.pool)
        else
            place(view.pool[1], canvas, x, y, w, C.POOL_H)
            place(view.pool[2], canvas, x + 3, y + 1, w - 6, C.POOL_H - 3)
            place(view.pool[3], canvas, x + 3, y + C.POOL_H - 3, w - 6, 2)
        end
    else
        hideAll(view.pool)
    end
    local sh = self.shade
    if sh then
        local y = sh.y - cam
        local k = (sh.warn > 0) and (1 - sh.warn / C.SHADE_WARN) or 1
        local s = C.SHADE_SIZE * (0.45 + 0.55 * k)
        placeIcon(view.shade[1], canvas, FIELD_X + sh.x, y, s * 2.4)
        place(view.shade[3], canvas, FIELD_X + sh.x - s / 2, y - s / 2, s, s)
        place(view.shade[2], canvas, FIELD_X + sh.x - s / 2 + 2, y - s / 2 + 2, s - 4, s - 4)
        place(view.shade[4], canvas, FIELD_X + sh.x - s / 2 + 4, y + 1, 3, 3)
        place(view.shade[5], canvas, FIELD_X + sh.x + s / 2 - 7, y + 1, 3, 3)
    else
        hideAll(view.shade)
    end
    local warn = b and not b.storm and b.stormT and b.stormT <= C.STORM_WARN
    if b and (b.storm or warn) then
        local r = b.storm and 44 or 34
        local a = b.storm and 0.9 or 0.4
        for i = 1, 6 do
            local k = self.t * (b.storm and 6 or 2) + i * 1.047
            local x = FIELD_X + b.x + math.cos(k) * r
            local y = b.y - cam + math.sin(k) * r * 0.6
            view.storm[i]:SetAlpha(a)
            place(view.storm[i], canvas, x - 3, y - 3, 6, 6)
        end
    else
        for i = 1, 6 do view.storm[i]:Hide() end
    end
end
function Game:DrawAim(cam)
    local canvas = self.canvas
    local t = self.mob or self.boss
    local pinned = self.pin
    local shown, marked = 0, false
    if pinned then
        local cx, cy = FIELD_X + pinned.x, pinned.y - cam + C.SPIKE_H / 2
        place(view.mark[1], canvas, cx - 8, cy + 6, 6, 2)
        place(view.mark[2], canvas, cx + 2, cy + 6, 6, 2)
        place(view.mark[3], canvas, cx - 8, cy - 8, 6, 2)
        place(view.mark[4], canvas, cx + 2, cy - 8, 6, 2)
        for i = 1, RAY_DOTS do view.ray[i]:Hide() end
        return
    end
    if t and self.phase == "play" then
        local sy = self.y + PSIZE / 2
        local dx = t.x - self.x
        local dy = t.y - sy
        if dx * dx + dy * dy <= AIM_R * AIM_R then
            local px, py = FIELD_X + self.x, sy - cam
            for i = 1, RAY_DOTS do
                local k = i / (RAY_DOTS + 1)
                local x = px + dx * k
                shown = shown + 1
                place(view.ray[shown], canvas, x - 1, py + dy * k - 1, 2, 2)
            end
            local r = (t == self.boss) and C.BOSS_HB or mobHB(t)
            local cx, cy = FIELD_X + t.x, t.y - cam
            place(view.mark[1], canvas, cx - r, cy + r - 1, 6, 2)
            place(view.mark[2], canvas, cx + r - 6, cy + r - 1, 6, 2)
            place(view.mark[3], canvas, cx - r, cy - r, 6, 2)
            place(view.mark[4], canvas, cx + r - 6, cy - r, 6, 2)
            marked = true
        end
    end
    for i = shown + 1, RAY_DOTS do view.ray[i]:Hide() end
    if not marked then
        for i = 1, 4 do view.mark[i]:Hide() end
    end
end
function Game:Draw()
    local cam = self.cam
    self:PaintBiome(cam + self.mid)
    self:DrawWalls(cam)
    self:DrawFar(cam)
    self:DrawDust(cam)
    self:DrawRuler(cam)
    if self.menu then
        platPool:HideAll()
        hideAll(view.playSheets)
        if view.model then view.model:Hide() end
        hideAll(view.vault)
        view.markLine:Hide()
        view.markTip:Hide()
        view.markText:Hide()
        ui.root:Hide()
        menu.root:Show()
        if self.menuDirty then
            self.menuDirty = nil
            self:MenuSync()
        end
        return
    end
    menu.root:Hide()
    for i = 1, #view.playSheets do view.playSheets[i]:Show() end
    self:DrawGate(cam)
    self:DrawPlates(cam)
    self:DrawActors(cam)
    self:DrawRide(cam)
    self:DrawSlip(cam)
    self:DrawHud()
    self:DrawNote()
    if self.inv and self.inv > 0 then
        view.meSheet:SetAlpha((floor(self.t * 12) % 2 == 0) and 0.35 or 1)
    else
        view.meSheet:SetAlpha(1)
    end
end
function Game:DrawRide(cam)
    local r, dr = self.ride, self.drop
    if not r and not dr then
        for i = 1, RIDE.parts do view.rideArt[i]:Hide() end
        view.rideDrawn = nil
        return
    end
    local canvas = self.canvas
    local k = r and r.k or dr.k
    local rd = RIDE[k]
    local frame = r and floor(self.t / RIDE.fxRate) or -1
    local list = ns.JumpRideFrame(rd, r and (frame + 1) or (rd.still or 0))
    if view.rideDrawn ~= k or view.rideFrame ~= frame then
        view.rideDrawn, view.rideFrame = k, frame
        ns.JumpRidePaint(rd, view.rideArt, list)
    end
    view.rideSheet:SetAlpha(dr and (dr.t / DROP_T) or 1)
    local x, y = r and self.x or dr.x, r and self.y or dr.y
    local cx, cy = FIELD_X + x, y - cam + (rd.ay or 0)
    for i = 1, RIDE.parts do
        local a = list[i]
        if a then place(view.rideArt[i], canvas, cx + a[1], cy + a[2], a[3], a[4])
        else view.rideArt[i]:Hide() end
    end
end
local HELP_TYPES = { 1, 2, 3, ICE, 1 }
local function drawTypes(host)
    local n = #HELP_TYPES
    local gap = 14
    local total = n * PW + (n - 1) * gap
    local w = host:GetWidth() or 0
    local ox = max(0, floor((w - total) / 2))
    for i = 1, n do
        local f = plateFrame(host)
        f:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", ox + (i - 1) * (PW + gap), 10)
        paintPlate(f, HELP_TYPES[i], i == n)
        f:Show()
    end
end
local ICON_ART = "Interface\\AddOns\\" .. ADDON .. "\\art\\jump_icon.tga"
local LOOK = ns.MakeLook{ wood = BIOME[1].wall, edge = C_GOLD, screen = BIOME[1].lo }
local MODES = {
    { key = "classic", label = "jump.modeClassic", tip = "jump.modeClassicTip" },
}
if CITADEL_ON then
    MODES[2] = { key = MODE_CITADEL, label = "jump.modeCitadel", tip = "jump.modeCitadelTip" }
end
local HELP = {
    "jump.help1",
    { art = drawTypes, h = 52 },
    "jump.help2Sub",
    "jump.help3",
    "jump.help4",
    "jump.help5",
    "jump.help6",
    "jump.help7",
    "jump.helpRide",
}
if CITADEL_ON then
    HELP[#HELP + 1] = "jump.help8"
    HELP[#HELP + 1] = "jump.help9"
end
ns.RegisterGame{
    id = ID,
    label = "jump.label",
    icon = { tex = ICON_ART, coord = { 0, 1, 0, 1 } },
    tip = "jump.tip",
    order = 8,
    duo = "none",
    look = LOOK,
    opts = {
        { key = "mode", label = "jump.optMode", def = "classic",
          options = MODES, tip = "jump.optModeTip" },
    },
    physics = true,
    ownPanel = true,
    New = New,
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
    },
    help = HELP,
}
