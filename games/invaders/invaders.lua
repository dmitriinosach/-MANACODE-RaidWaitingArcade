local ADDON, ns = ...
local ID = "invaders"
local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local sin, cos, sqrt = math.sin, math.cos, math.sqrt
local D = ns.invadersData
local LOOK_WOOD = { 0.08, 0.09, 0.14 }
local LOOK_EDGE = { 1.00, 0.86, 0.35 }
local LOOK_SCREEN = { 0.05, 0.06, 0.10 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE, screen = LOOK_SCREEN }
local COLS, ROWS = 11, 5
local LIVES, LIVES_MAX = 3, 5
local ROW_SCORE = { 30, 20, 20, 10, 10 }
local WAVE_BONUS = 100
local LIFE_BONUS = 50
local DROP_SCORE = 250
local BOSS_SCORE = 500
local INVULN     = 1.5
local WAVE_PAUSE = 2.0
local OVER_PAUSE = 0.8
local MAX_SHOT, MAX_BOMB, MAX_DROP, MAX_MOB = 20, 24, 8, 40
local STEP_X = 8
local STEP_BASE, STEP_FLOOR = 0.30, 0.04
local WAVE_SPEED, WAVE_SPEED_FLOOR = 0.85, 0.35
local WAVE_DROP_MAX = 2
local HP_FROM, HP_MAX = 2, 6
local BOMB_BASE, BOMB_STEP, BOMB_FLOOR = 1.20, 0.06, 0.35
local BOMB_V = 170
local BOMB_V_STEP, BOMB_V_MAX = 9, 250
local DROP_CHANCE = 0.09
local DROP_V = 95
local BOSS_DROPS = 3
local BOSS_EVERY = 5
local BOSS_SIZE = 76
local BOSS_HP_BASE, BOSS_HP_STEP = 40, 25
local BOSS_FIRE_BASE, BOSS_FIRE_FLOOR = 2.2, 0.9
local BOSS_V_BASE = 70
local BOSS_ROWS = 2
local F = {
    rageAt = 0.4, rageFire = 0.7, rageV = 1.4,
    spinN = 5, spinStep = 0.55, spinV = 0.85,
    frostTell = 1.0, frostOn = 1.2, frostGap = 4.5, frostW = 120,
    iceHp = 8, iceN = 2,
    plagueGap = 3.2, plagueLife = 7.0, plagueR = 46,
    summonGap = 5.0, summonN = 3, maxPool = 6,
    flameGap = 6.0, flameV = 130, flameHalf = 26, flameSparks = 5,
    spikeGap = 8.0, spikeLife = 4.5, spikeN = 3, spikeTell = 0.9,
    pullGap = 11.0, pullTime = 2.5, pullV = 150,
    streamGap = 8.0, streamOn = 1.6, streamTell = 0.8, streamW = 46,
    swarmGap = 10.0, swarmN = 4, swarmV = 70,
    tombGap = 7.0, tombTell = 1.6, tombHp = 4,
    cloudGap = 9.0, cloudV = 46, cloudR = 34,
    shieldGap = 12.0,
}
local DIVE_FROM = 3
local DIVE_BASE, DIVE_STEP, DIVE_FLOOR = 7.0, 0.4, 3.0
local DIVE_V, DIVE_VX, DIVE_TRACK, DIVE_SWAY = 190, 220, 70, 34
local DIVE_BOMB_Y = 220
local DIVE_MUL = 2
local UFO_MIN_ALIVE = 8
local UFO_GAP_LO, UFO_GAP_HI = 20, 30
local UFO_V, UFO_SIZE, UFO_TOP, UFO_HP = 90, 28, 30, 3
local UFO_SCORE = { 100, 100, 150, 150, 200, 300 }
local WYRM_FROM = 8
local WYRM_GAP_LO, WYRM_GAP_HI = 25, 35
local WYRM_V, WYRM_SIZE, WYRM_HP, WYRM_SCORE = 60, 44, 8, 400
local BEAM_TELL, BEAM_ON, BEAM_W, BEAM_GAP = 0.7, 0.6, 24, 3.0
local NECRO_FROM, NECRO_GAP, NECRO_V, NECRO_HP = 6, 6.0, 60, 3
local ABOM_FROM, ABOM_V, ABOM_HP = 4, 30, 5
local SPIDER_FROM = 7
local WEB_SLOW = 3.0
local PACK_GAP, PACK_AMP, PACK_SPACING = 3.0, 55, 40
local PACK_LANES = 2
local RING_N, RING_R, RING_SINK = 12, 120, 8
local RAIN_TIME, RAIN_BASE, RAIN_STEP, RAIN_FLOOR = 14, 0.7, 0.03, 0.25
local BLAST_R = 70
local SIEGE_Y, SIEGE_SWAY = 0.78, 40
local GUN_MAX, PERK_AT = 5, 4
local GUN_LEVEL = {
    { n = 1, spread = 0,  rel = 1.0 },
    { n = 2, spread = 0,  rel = 1.0 },
    { n = 3, spread = 90, rel = 1.0 },
    { n = 3, spread = 90, rel = 0.8 },
    { n = 5, spread = 70, rel = 0.8 },
}
local CHAIN_STEP, CHAIN_MAX = 10, 5
local SHOT_SFX = 0.6
local BEAM_TIME, BEAM_HIT, BEAM_HALF = 2.0, 0.12, 9
local FORM_ROWS = {
    { "ghoul", "ghoul", "ghoul", "ghoul", "ghoul" },
    { "ghoul", "ghoul", "ghoul", "archer", "archer" },
    { "ghoul", "ghoul", "cultist", "archer", "archer" },
    { "ghoul", "cultist", "cultist", "archer", "spider" },
}
local SPECIAL = { "ring", "rain", "siege" }
local WEAPONS = {
    {
        key = "fire", label = "invaders.gunFireLabel",
        shotV = 470, reload = 0.34, blast = 1, perkBlast = 2,
        colour = { 1.00, 0.60, 0.23 },
        cd = 20, ability = "invaders.abFrost", aTip = "invaders.abFrostTip",
        tip = "invaders.gunFireTip",
    },
    {
        key = "arrow", label = "invaders.gunArrowLabel",
        shotV = 760, reload = 0.26, perkPierce = 2,
        colour = { 0.62, 0.85, 0.42 },
        cd = 15, ability = "invaders.abVolley", aTip = "invaders.abVolleyTip",
        tip = "invaders.gunArrowTip",
    },
    {
        key = "shadow", label = "invaders.gunShadowLabel",
        shotV = 380, reload = 0.50, pierce = 2, perkPierce = 3,
        colour = { 0.66, 0.42, 0.91 },
        cd = 25, ability = "invaders.abWard", aTip = "invaders.abWardTip",
        tip = "invaders.gunShadowTip",
    },
    {
        key = "axe", label = "invaders.gunAxeLabel",
        shotV = 440, reload = 0.36, inherit = 0.5, perkDmg = 2,
        colour = { 0.75, 0.79, 0.85 },
        cd = 18, ability = "invaders.abRush", aTip = "invaders.abRushTip",
        tip = "invaders.gunAxeTip",
    },
    {
        key = "laser", label = "invaders.gunLaserLabel",
        shotV = 1200, reload = 0.62, pierce = 4, perkPierce = 9,
        colour = { 0.25, 0.66, 1.00 },
        cd = 22, ability = "invaders.abBeam", aTip = "invaders.abBeamTip",
        tip = "invaders.gunLaserTip",
    },
    {
        key = "bolt", label = "invaders.gunBoltLabel",
        shotV = 620, reload = 0.44, chain = 2, perkChain = 3,
        colour = { 0.78, 0.66, 1.00 },
        cd = 20, ability = "invaders.abStorm", aTip = "invaders.abStormTip",
        tip = "invaders.gunBoltTip",
    },
}
local byGun = {}
for _, w in ipairs(WEAPONS) do byGun[w.key] = w end
local GUN_START = "fire"
local CHAIN_R = 74
local SLOW_TIME, RUSH_TIME, WARD_HITS = 5.0, 2.0, 2
local RAPID_MUL, SWIFT_MUL = 0.55, 1.6
local EN, EGAP = 32, 7
local EPX, EPY = EN + EGAP, EN + EGAP
local FORM_W = COLS * EN + (COLS - 1) * EGAP
local FORM_H = ROWS * EN + (ROWS - 1) * EGAP
local ICON_CROP = 0.08
local MARGIN = 12
local DROP_Y  = 14
local TOP_PAD = 62
local SHIP, SHIP_Y, SHIP_V = 30, 26, 260
local LOSE_Y = 60
local HOLD_T, EBB_V = 3.0, 120
local SHOT_W, SHOT_H = 10, 16
local SHOT_ART = 26
local BOMB_W, BOMB_H = 12, 18
local BOMB_ART = 28
local PICK = 26
local WARD_BUBBLE = 1.9
local SKY_LAYERS = 3
local SKY_PER_LAYER = 16
local SKY_V = { 8, 16, 28 }
local HP_COLOR = {
    { 0.55, 0.85, 1.00 },
    { 0.45, 1.00, 0.50 },
    { 1.00, 0.90, 0.35 },
    { 1.00, 0.62, 0.25 },
    { 1.00, 0.38, 0.38 },
    { 0.85, 0.45, 1.00 },
}
local BOMB_TINT = {
    plain  = { 1, 0.25, 0.15 },
    aim    = { 1, 0.65, 0.15 },
    web    = { 0.5, 1, 0.6 },
    bone   = { 0.9, 0.85, 0.7 },
    ice    = { 0.45, 0.75, 1 },
    plague = { 0.45, 0.95, 0.3 },
    shadow = { 0.55, 0.25, 0.9 },
    spark  = { 0.5, 0.9, 1 },
}
local view, enemyPool, shotPool, bombPool, dropPool, poolPool, boltPool
local function roundFrame(parent, level, size, elite)
    local f = ns.NewFrame("Frame", nil, parent)
    f:SetFrameLevel(parent:GetFrameLevel() + level)
    f:SetWidth(size)
    f:SetHeight(size)
    local ic = size * D.RIM_ICON
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetWidth(ic)
    f.icon:SetHeight(ic)
    f.icon:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.icon:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
    local rs = size * D.RIM_SCALE
    f.rim = f:CreateTexture(nil, "OVERLAY")
    f.rim:SetWidth(rs)
    f.rim:SetHeight(rs)
    f.rim:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.rim:SetTexture(D.RIM)
    if elite then
        local eh = size * 0.46
        f.elite = f:CreateTexture(nil, "HIGHLIGHT")
        f.elite:SetWidth(eh * D.ELITE_RATIO)
        f.elite:SetHeight(eh)
        f.elite:SetPoint("TOP", f, "TOP", 0, eh * 0.42)
        f.elite:SetTexture(D.ELITE)
        f.elite:SetTexCoord(D.ELITE_COORD[1], D.ELITE_COORD[2], D.ELITE_COORD[3], D.ELITE_COORD[4])
        f.elite:Hide()
    end
    f:Hide()
    return f
end
local function boltFrame(canvas, level, art)
    local f = ns.NewFrame("Frame", nil, canvas)
    f:SetFrameLevel(canvas:GetFrameLevel() + level)
    f:SetWidth(art)
    f:SetHeight(art)
    f.glow = f:CreateTexture(nil, "BACKGROUND")
    f.glow:SetAllPoints()
    f.glow:SetTexture(D.GLOW)
    f.glow:SetBlendMode("ADD")
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    f.icon:SetTexture(D.BOLTS)
    f:Hide()
    return f
end
local function boltArt(f, key)
    local c = D.BOLT[key] or D.BOLT.plain
    f.icon:SetTexture(D.BOLTS)
    f.icon:SetTexCoord(c[1], c[2], c[3], c[4])
end
local function ensureView(canvas)
    if view then return end
    view = {}
    local art = D.Pack()
    view.art = art
    view.sky = {}
    for L = 1, SKY_LAYERS do
        local f = ns.NewFrame("Frame", nil, canvas)
        f:SetFrameLevel(canvas:GetFrameLevel())
        f:Hide()
        f.star = {}
        for i = 1, SKY_PER_LAYER do
            local t = f:CreateTexture(nil, "BACKGROUND")
            local s = 1 + L
            local a = 0.14 + 0.12 * L
            t:SetWidth(s)
            t:SetHeight(s)
            ns.Paint(t, 1, 1, 1, a)
            f.star[i] = t
        end
        view.sky[L] = f
    end
    view.form = ns.NewFrame("Frame", nil, canvas)
    view.form:SetFrameLevel(canvas:GetFrameLevel() + 2)
    view.form:SetWidth(FORM_W)
    view.form:SetHeight(FORM_H)
    view.form:Hide()
    view.breath = ns.NewFrame("Frame", nil, canvas)
    view.breath:SetFrameLevel(canvas:GetFrameLevel() + 1)
    view.breath:SetWidth(F.frostW)
    view.breath.tex = view.breath:CreateTexture(nil, "ARTWORK")
    view.breath.tex:SetAllPoints()
    ns.Paint(view.breath.tex, 0.6, 0.85, 1, 0.5)
    view.breath:Hide()
    poolPool = ns.NewPool(function()
        local f = ns.NewFrame("Frame", nil, canvas)
        f:SetFrameLevel(canvas:GetFrameLevel() + 1)
        f:SetWidth(F.plagueR * 2)
        f:SetHeight(F.plagueR * 2)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints()
        f.tex:SetTexture(D.GLOW)
        f.tex:SetBlendMode("ADD")
        f.tex:SetVertexColor(0.45, 0.95, 0.35, 0.55)
        return f
    end)
    view.beam = ns.NewFrame("Frame", nil, canvas)
    view.beam:SetFrameLevel(canvas:GetFrameLevel() + 1)
    view.beam:SetWidth(BEAM_W)
    view.beam:SetHeight(10)
    view.beam.tex = view.beam:CreateTexture(nil, "ARTWORK")
    view.beam.tex:SetAllPoints()
    ns.Paint(view.beam.tex, 0.7, 0.9, 1, 0.5)
    view.beam:Hide()
    view.ward = ns.NewFrame("Frame", nil, canvas)
    view.ward:SetFrameLevel(canvas:GetFrameLevel() + 2)
    view.ward:SetWidth(SHIP * WARD_BUBBLE)
    view.ward:SetHeight(SHIP * WARD_BUBBLE)
    view.ward.tex = view.ward:CreateTexture(nil, "ARTWORK")
    view.ward.tex:SetAllPoints()
    view.ward.tex:SetTexture(D.GLOW)
    view.ward.tex:SetBlendMode("ADD")
    view.ward:Hide()
    view.ship = roundFrame(canvas, 3, SHIP)
    if view.ship.icon:SetTexture(D.SHIP_ART) then
        view.ship.icon:SetWidth(SHIP + 2)
        view.ship.icon:SetHeight(SHIP + 2)
        view.ship.icon:SetTexCoord(0, 1, 0, 1)
        view.ship.rim:Hide()
        view.ship.shipIsClass = false
        view.ship.shipIsSprite = true
    elseif art.ship then
        view.ship.icon:SetTexture(art.ship)
        view.ship.shipIsClass = false
    else
        view.ship.icon:SetTexture(D.CLASS_CIRCLES)
        view.ship.icon:SetWidth(SHIP)
        view.ship.icon:SetHeight(SHIP)
        view.ship.rim:Hide()
        view.ship.shipIsClass = true
    end
    view.boss = roundFrame(canvas, 3, BOSS_SIZE, true)
    view.diver = roundFrame(canvas, 3, EN, true)
    view.ufo = roundFrame(canvas, 3, UFO_SIZE)
    view.ufo.icon:SetTexture(art.ufo or D.UFO_FALLBACK)
    view.ufo.rim:SetVertexColor(1, 0.85, 0.3)
    view.wyrm = roundFrame(canvas, 3, WYRM_SIZE, true)
    view.wyrm.icon:SetTexture(D.kinds.wyrm.icon)
    view.wyrm.rim:SetVertexColor(0.6, 0.85, 1)
    view.wyrm.elite:SetVertexColor(D.ELITE_GOLD[1], D.ELITE_GOLD[2], D.ELITE_GOLD[3])
    view.wyrm.elite:Show()
    view.mobs = {}
    local hud = ns.NewFrame("Frame", nil, canvas)
    hud:SetAllPoints()
    hud:SetFrameLevel(canvas:GetFrameLevel() + 6)
    hud:EnableMouse(false)
    view.hud = hud
    view.wave = hud:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.wave:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -12)
    view.score = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    view.score:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -10)
    view.life = {}
    for i = 1, LIVES_MAX do
        local t = hud:CreateTexture(nil, "ARTWORK")
        t:SetWidth(20)
        t:SetHeight(20)
        t:SetTexture(D.SHIP_ART)
        t:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12 + (i - 1) * 24, 6)
        t:Hide()
        view.life[i] = t
    end
    view.bossBg = hud:CreateTexture(nil, "ARTWORK")
    view.bossBg:SetHeight(10)
    ns.Paint(view.bossBg, 0, 0, 0, 0.65)
    view.bossBg:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -38)
    view.bossBg:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -38)
    view.bossBg:Hide()
    view.bossFill = hud:CreateTexture(nil, "OVERLAY")
    view.bossFill:SetHeight(10)
    ns.Paint(view.bossFill, 0.85, 0.25, 0.25, 0.95)
    view.bossFill:SetPoint("TOPLEFT", view.bossBg, "TOPLEFT", 0, 0)
    view.bossFill:Hide()
    view.bossName = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.bossName:SetPoint("TOPLEFT", hud, "TOPLEFT", 14, -22)
    view.bossName:Hide()
    view.gun = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.gun:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12, 46)
    view.gun:SetJustifyH("LEFT")
    view.buffs = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.buffs:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12, 32)
    view.buffs:SetJustifyH("LEFT")
    view.ability = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.ability:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", -12, 20)
    view.ability:SetJustifyH("RIGHT")
    view.cdBg = hud:CreateTexture(nil, "ARTWORK")
    view.cdBg:SetWidth(120)
    view.cdBg:SetHeight(6)
    ns.Paint(view.cdBg, 0, 0, 0, 0.6)
    view.cdBg:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", -12, 8)
    view.cdFill = hud:CreateTexture(nil, "OVERLAY")
    view.cdFill:SetHeight(6)
    view.cdFill:SetPoint("BOTTOMLEFT", view.cdBg, "BOTTOMLEFT", 0, 0)
    view.banner = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.banner:SetPoint("CENTER", hud, "CENTER", 0, 60)
    view.banner:Hide()
    view.note = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.note:SetPoint("TOP", view.banner, "BOTTOM", 0, -6)
    view.note:Hide()
    enemyPool = ns.NewPool(function() return roundFrame(view.form, 1, EN, true) end)
    shotPool = ns.NewPool(function() return boltFrame(canvas, 4, SHOT_ART) end)
    bombPool = ns.NewPool(function() return boltFrame(canvas, 4, BOMB_ART) end)
    boltPool = ns.NewPool(function() return boltFrame(canvas, 2, BOMB_ART) end)
    dropPool = ns.NewPool(function() return boltFrame(canvas, 5, PICK) end)
end
local function hideView()
    if not view then return end
    for L = 1, SKY_LAYERS do view.sky[L]:Hide() end
    view.form:Hide()
    view.ship:Hide()
    view.ward:Hide()
    view.boss:Hide()
    view.diver:Hide()
    view.ufo:Hide()
    view.wyrm:Hide()
    view.beam:Hide()
    view.breath:Hide()
    view.hud:Hide()
    view.banner:Hide()
    view.note:Hide()
    for i = 1, #view.mobs do view.mobs[i]:Hide() end
    if enemyPool then enemyPool:HideAll() end
    if shotPool then shotPool:HideAll() end
    if bombPool then bombPool:HideAll() end
    if dropPool then dropPool:HideAll() end
    if poolPool then poolPool:HideAll() end
    if boltPool then boltPool:HideAll() end
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    self.enemy = {}
    self.shot = {}
    self.bomb = {}
    self.drop = {}
    self.mob = {}
    self.queue = {}
    self.freeMob = {}
    self.ship = { x = 0, y = SHIP_Y, vx = 0, invuln = 0, ward = 0 }
    self.buff = { rapid = 0, swift = 0 }
    self.gun = { k = "MAGE", lvl = 1 }
    self.pick = {}
    self.t = 0
    self.score = 0
    self.wave = 1
    self.lives = LIVES
    self.phase = "play"
    self.phaseT = 0
    self.cd, self.slow, self.rush, self.webT = 0, 0, 0, 0
    self.beamT, self.beamHit = 0, 0
    self.chain, self.mult = 0, 1
    self.reloadT = 0
    self.bombT = 0
    self.bombAim = false
    self.diver, self.diveT = nil, 0
    self.ufo, self.ufoT = nil, 0
    self.wyrm, self.wyrmT, self.beam = nil, 0, nil
    self.breath = nil
    self.flame, self.tomb, self.stream = nil, nil, nil
    self.pull = 0
    self.pool = {}
    self.rainT, self.spawnT = 0, 0
    self.wtype = "form"
    return self
end
local function gunOf(key)
    return byGun[key or ""] or byGun[GUN_START]
end
local function waveType(w)
    if w % BOSS_EVERY == 0 then return "boss" end
    local r = w % BOSS_EVERY
    if r == 1 or r == 3 then return "form" end
    if r == 2 then return "packs" end
    return SPECIAL[floor((w - 1) / BOSS_EVERY) % #SPECIAL + 1]
end
local function rowKinds(w)
    return FORM_ROWS[min(#FORM_ROWS, floor((w - 1) / BOSS_EVERY) + 1)]
end
function Game:Layout()
    local W, H = self.canvas.W or 640, self.canvas.H or 480
    self.W, self.H = W, H
    self.minX, self.maxX = MARGIN, W - MARGIN
    self.topY = H - TOP_PAD
    self.maxY = floor(H / 2) - SHIP
end
function Game:BuildSky()
    self.skyY = self.skyY or {}
    for L = 1, SKY_LAYERS do
        local f = view.sky[L]
        f:SetWidth(self.W)
        f:SetHeight(self.H)
        for i = 1, SKY_PER_LAYER do
            local t = f.star[i]
            t:ClearAllPoints()
            t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",
                self.rng:Int(0, self.W - 2), self.rng:Int(0, self.H - 2))
        end
        self.skyY[L] = 0
        f:Show()
    end
end
function Game:MoveSky(dt)
    for L = 1, SKY_LAYERS do
        local y = self.skyY[L] - SKY_V[L] * dt
        if y <= -self.H then y = y + self.H end
        self.skyY[L] = y
    end
end
local function hpFor(wave, row)
    local extra = max(0, wave - HP_FROM)
    local hp = 1 + floor((extra + ROWS - row) / ROWS)
    return min(hp, HP_MAX)
end
local function rowsFor(wave)
    local wt = waveType(wave)
    if wt == "boss" then return BOSS_ROWS end
    if wt == "form" then return ROWS end
    return 0
end
function Game:AssignIcons()
    local mobs = D.mobs
    local kinds = rowKinds(self.wave)
    local shift = ((self.wave - 1) * ROWS) % #mobs
    for i = 1, ROWS * COLS do
        local e = self.enemy[i]
        local k = kinds[e.row]
        if k == "ghoul" then
            e.icon = mobs[(shift + e.row - 1) % #mobs + 1]
        else
            e.icon = D.kinds[k].icon
        end
    end
    self.layoutDirty = true
end
function Game:Splash(r, c, reach, dmg)
    for i = 1, reach do
        for dc = -i, i, 2 * i do
            local e = self.enemy[(r - 1) * COLS + c + dc]
            if e and e.row == r and e.hp > 0 and not e.dive then self:Hurt(e, dmg) end
        end
    end
end
function Game:BuildForm(rows)
    self.rows = rows
    for r = 1, ROWS do
        for c = 1, COLS do
            local i = (r - 1) * COLS + c
            local e = self.enemy[i]
            if not e then
                e = {}
                self.enemy[i] = e
            end
            e.col, e.row = c, r
            e.dive = nil
            if r <= rows then
                e.hp = hpFor(self.wave, r)
                e.hpMax = e.hp
            else
                e.hp, e.hpMax = 0, 0
            end
        end
    end
    self.alive = rows * COLS
    self.dir = 1
    self.formX = floor((self.W - FORM_W) / 2)
    self.formY = self.topY - min(self.wave - 1, WAVE_DROP_MAX) * EPY
    self.hold, self.ebb = 0, false
    self:Bounds()
    self:AssignIcons()
    self.formDirty = true
end
function Game:Bounds()
    local lo, hi, low
    for i = 1, ROWS * COLS do
        local e = self.enemy[i]
        if e.hp > 0 and not e.dive then
            if not lo or e.col < lo then lo = e.col end
            if not hi or e.col > hi then hi = e.col end
            if not low or e.row > low then low = e.row end
        end
    end
    self.loCol, self.hiCol, self.loRow = lo or 1, hi or COLS, low or 1
end
function Game:StepPeriod()
    local p = STEP_BASE * self.alive / (max(1, self.rows) * COLS)
        * max(WAVE_SPEED_FLOOR, WAVE_SPEED ^ (self.wave - 1)) + STEP_FLOOR
    if self.slow > 0 then p = p * 2 end
    return p
end
function Game:Formation(dt)
    if self.alive <= 0 then return end
    local v = STEP_X / self:StepPeriod()
    self.formX = self.formX + self.dir * v * dt
    local left  = self.formX + (self.loCol - 1) * EPX
    local right = self.formX + (self.hiCol - 1) * EPX + EN
    local over
    if self.dir > 0 and right > self.maxX then
        over = right - self.maxX
    elseif self.dir < 0 and left < self.minX then
        over = self.minX - left
    end
    if over then
        self.formX = self.formX - self.dir * over
        self.dir = -self.dir
        if (self.hold or 0) <= 0 and not self.ebb then
            self.formY = self.formY - DROP_Y
            local bottom = LOSE_Y + (self.loRow - 1) * EPY + EN
            if self.formY <= bottom then
                self.formY = bottom
                self.hold = HOLD_T
                ns.Sfx.Play("warn")
            end
        end
    end
    if (self.hold or 0) > 0 then
        self.hold = self.hold - dt
        if self.hold <= 0 then self.ebb = true end
    elseif self.ebb then
        local home = self.topY - min(self.wave - 1, WAVE_DROP_MAX) * EPY
        self.formY = min(home, self.formY + EBB_V * dt)
        if self.formY >= home then self.ebb = false end
    end
    self:Ram()
end
function Game:Ram()
    local ship = self.ship
    if ship.invuln > 0 then return end
    local sx, sy = ship.x - SHIP / 2, ship.y
    if sy + SHIP < self.formY - (self.loRow - 1) * EPY - EN then return end
    for i = 1, ROWS * COLS do
        local e = self.enemy[i]
        if e.hp > 0 and not e.dive then
            local ex = self.formX + (e.col - 1) * EPX
            local ey = self.formY - (e.row - 1) * EPY - EN
            if ey < sy + SHIP and ey + EN > sy and ex + EN > sx and ex < sx + SHIP then
                self:Hurt(e, e.hp)
                self:TakeHit()
                return
            end
        end
    end
end
function Game:DiveGap()
    local gap = DIVE_BASE - DIVE_STEP * max(0, self.wave - DIVE_FROM)
    if gap < DIVE_FLOOR then gap = DIVE_FLOOR end
    return gap * (0.75 + self.rng:Float() * 0.5)
end
function Game:UfoGap()
    return UFO_GAP_LO + self.rng:Float() * (UFO_GAP_HI - UFO_GAP_LO)
end
function Game:WyrmGap()
    return WYRM_GAP_LO + self.rng:Float() * (WYRM_GAP_HI - WYRM_GAP_LO)
end
function Game:BombV()
    return min(BOMB_V_MAX, BOMB_V + BOMB_V_STEP * (self.wave - 1))
end
function Game:Enqueue(at, q)
    q.at = at
    self.queue[#self.queue + 1] = q
end
function Game:BuildWave()
    local w = self.wave
    local wt = waveType(w)
    self.wtype = wt
    for i = #self.queue, 1, -1 do self.queue[i] = nil end
    self:ClearMobs()
    self:BuildForm(rowsFor(w))
    self.bombT = 1.0
    self.bombAim = false
    self.diver = nil
    self.diveT = self:DiveGap()
    self.ufo = nil
    self.ufoT = self:UfoGap()
    self.wyrm, self.beam = nil, nil
    self.wyrmT = self:WyrmGap()
    self.rainT, self.spawnT = 0, 0
    self.ring = nil
    self.breath, self.flame, self.tomb, self.stream = nil, nil, nil, nil
    self.pull = 0
    for i = #self.pool, 1, -1 do self.pool[i] = nil end
    view.diver:Hide()
    view.ufo:Hide()
    view.wyrm:Hide()
    view.beam:Hide()
    local t = self.t
    if wt == "boss" then
        self:SpawnBoss()
    elseif wt == "form" then
        if w >= NECRO_FROM then
            self:Enqueue(t + 3, { w = "mob", kind = "necro" })
        end
    elseif wt == "packs" then
        local packs = 4 + floor(w / BOSS_EVERY)
        local size = 7 + floor(w / 6)
        for i = 1, packs do
            local kind = (i % 2 == 1) and "bat" or "ghoul"
            if w >= SPIDER_FROM and i % 3 == 0 then kind = "spider" end
            local lanes = (i > 2) and PACK_LANES or 1
            for L = 1, lanes do
                self:Enqueue(t + (i - 1) * PACK_GAP + (L - 1) * 0.8, {
                    w = "pack", kind = kind, side = ((i + L) % 2 == 1) and 1 or -1,
                    n = size, lane = L,
                })
            end
        end
        if w >= ABOM_FROM then self:Enqueue(t + 2, { w = "mob", kind = "abom" }) end
    elseif wt == "ring" then
        self.ring = { cx = self.W / 2, cy = self.H * 0.62, r = RING_R, w = 0.9 + 0.03 * w, ph = 0 }
        for i = 1, RING_N do
            local m = self:AddMob("cultist", self.ring.cx, self.ring.cy, "ring")
            if m then
                m.ang = (i - 1) * 6.2832 / RING_N
                m.hp = 2 + floor(w / 10)
                m.hpMax = m.hp
                m.fireT = 1 + i * 0.4
            end
        end
    elseif wt == "rain" then
        self.rainT = RAIN_TIME + 0.3 * w
        self.spawnT = 0.5
    elseif wt == "siege" then
        local xs = { 0.2, 0.5, 0.8 }
        for i = 1, #xs do
            local m = self:AddMob("archer", self.W * xs[i], self.H * SIEGE_Y, "sit")
            if m then
                m.x0 = m.x
                m.ph = i * 2.1
                m.hp = 6 + floor(w / 2)
                m.hpMax = m.hp
                m.fireT = 1.5 + i * 0.5
            end
        end
        for i = 1, 3 do
            self:Enqueue(t + 4 + (i - 1) * 6, { w = "pack", kind = "bat", side = (i % 2 == 1) and 1 or -1, n = 6 })
        end
        if w >= ABOM_FROM then self:Enqueue(t + 8, { w = "mob", kind = "abom" }) end
    end
end
function Game:Spawns(dt)
    if self.phase ~= "play" then return end
    local q = self.queue
    local i = 1
    while i <= #q do
        local e = q[i]
        if e.at <= self.t then
            table.remove(q, i)
            if e.w == "pack" then self:SpawnPack(e) else self:SpawnSpecial(e.kind) end
        else
            i = i + 1
        end
    end
    if self.wtype == "rain" and self.rainT > 0 then
        self.rainT = self.rainT - dt
        self.spawnT = self.spawnT - dt
        if self.spawnT <= 0 then
            self.spawnT = max(RAIN_FLOOR, RAIN_BASE - RAIN_STEP * self.wave)
            local x = MARGIN + EN / 2 + self.rng:Float() * (self.W - 2 * MARGIN - EN)
            if self.rng:Float() < 0.2 then
                local m = self:AddMob("barrel", x, self.H + EN / 2, "fall")
                if m then m.vx, m.vy = 0, -90 end
            else
                local m = self:AddMob("rock", x, self.H + EN / 2, "fall")
                if m then
                    m.hp, m.hpMax = 2, 2
                    m.vx = (self.rng:Float() - 0.5) * 80
                    m.vy = -(120 + 4 * self.wave + self.rng:Float() * 80)
                end
            end
        end
    end
end
function Game:SpawnPack(e)
    local v = min(260, 150 + 5 * self.wave)
    local lane = (e.lane or 1) - 1
    local y0 = self.H * 0.55 + lane * 72 + self.rng:Float() * 60
    local ph = self.rng:Float() * 6.2832
    local x0 = (e.side > 0) and -EN or (self.W + EN)
    for i = 1, e.n do
        local m = self:AddMob(e.kind, x0 - e.side * (i - 1) * PACK_SPACING, y0, "sine")
        if m then
            m.dir, m.v, m.y0, m.amp, m.ph = e.side, v, y0, PACK_AMP, ph
            if e.kind == "ghoul" then m.hp, m.hpMax = 2, 2 end
            m.fireT = 1.5 + i * 0.6
        end
    end
end
function Game:SpawnSpecial(kind)
    if kind == "necro" then
        local m = self:AddMob("necro", self.W / 2, self.topY + 8 + EN / 2, "hover")
        if m then
            m.dir, m.v = 1, NECRO_V
            m.hp, m.hpMax = NECRO_HP, NECRO_HP
            m.fireT = NECRO_GAP
        end
    elseif kind == "abom" then
        local x = MARGIN + EN + self.rng:Float() * (self.W - 2 * MARGIN - 2 * EN)
        local m = self:AddMob("abom", x, self.H + EN / 2, "sink")
        if m then
            m.v = ABOM_V
            m.hp, m.hpMax = ABOM_HP, ABOM_HP
            m.fireT = 2.5
        end
    end
end
function Game:WaveClear()
    if self.alive > 0 or self.boss or self.diver then return false end
    if #self.mob > 0 or #self.queue > 0 then return false end
    if self.wtype == "rain" and self.rainT > 0 then return false end
    return true
end
function Game:MobFrame()
    local f = table.remove(self.freeMob)
    if f then return f end
    f = roundFrame(self.canvas, 3, EN, true)
    view.mobs[#view.mobs + 1] = f
    return f
end
function Game:AddMob(kind, x, y, beh)
    if #self.mob >= MAX_MOB then return nil end
    local k = D.kinds[kind]
    local m = {
        kind = kind, x = x, y = y, beh = beh,
        hp = 1, hpMax = 1, fireT = 0, dirty = true,
        dir = 1, v = 0, y0 = y, amp = 0, ph = 0, ang = 0, x0 = x, vx = 0, vy = 0,
        life = 0, tell = 0,
    }
    local f = self:MobFrame()
    f.icon:SetTexture(k.icon)
    f:Show()
    m.f = f
    self.mob[#self.mob + 1] = m
    return m
end
function Game:RemoveMob(m)
    for i = #self.mob, 1, -1 do
        if self.mob[i] == m then
            table.remove(self.mob, i)
            break
        end
    end
    if m.f then
        m.f:Hide()
        self.freeMob[#self.freeMob + 1] = m.f
        m.f = nil
    end
end
function Game:ClearMobs()
    for i = #self.mob, 1, -1 do
        local m = self.mob[i]
        if m.f then
            m.f:Hide()
            self.freeMob[#self.freeMob + 1] = m.f
            m.f = nil
        end
        self.mob[i] = nil
    end
end
function Game:HurtMob(m, n)
    m.hp = m.hp - n
    m.dirty = true
    if m.hp > 0 then return false end
    self:KillMob(m, true)
    return true
end
function Game:KillMob(m, scored)
    local k = D.kinds[m.kind]
    local x, y = m.x, m.y
    self:RemoveMob(m)
    if scored then
        if k.score > 0 then self:Chain() end
        self:Award(k.score)
        if self.rng:Float() < DROP_CHANCE then self:SpawnDrop(x, y - EN / 2) end
    end
    ns.FX.Nova(self.canvas, x, y, EN, k.icon)
    if m.kind == "abom" then
        for s = -1, 1, 2 do
            local g = self:AddMob("ghoul", x + s * 20, y, "split")
            if g then
                g.vx, g.vy = s * 90, -110
                g.fireT = 1.0
            end
        end
    elseif m.kind == "barrel" then
        self:Explode(x, y)
    end
end
function Game:Explode(x, y)
    local hit = {}
    for i = 1, #self.mob do
        local m = self.mob[i]
        local dx, dy = m.x - x, m.y - y
        if dx * dx + dy * dy <= BLAST_R * BLAST_R then hit[#hit + 1] = m end
    end
    for i = 1, #hit do self:HurtMob(hit[i], 3) end
    local sx, sy = self.ship.x, self.ship.y + SHIP / 2
    if (sx - x) * (sx - x) + (sy - y) * (sy - y) <= BLAST_R * BLAST_R then self:TakeHit() end
    ns.FX.Nova(self.canvas, x, y, BLAST_R, D.kinds.barrel.icon, 1.6)
end
function Game:Bomb(x, y, vx, vy, tint, kind)
    if #self.bomb >= MAX_BOMB then return end
    self.bomb[#self.bomb + 1] = { x = x, y = y, vx = vx, vy = vy, a = tint or "plain", k = kind }
end
function Game:AimedBomb(x, y, mul)
    local v = self:BombV() * (mul or 1)
    local dx = self.ship.x - x
    local dy = (self.ship.y + SHIP / 2) - y
    if dy > -10 then dy = -10 end
    local len = sqrt(dx * dx + dy * dy)
    self:Bomb(x, y, dx / len * v, dy / len * v, "aim")
end
function Game:FireAs(kind, x, y)
    local v = self:BombV()
    if kind == "archer" then
        self:AimedBomb(x, y, 1.35)
    elseif kind == "cultist" then
        for i = -1, 1 do self:Bomb(x, y, i * 70, -v) end
    elseif kind == "spider" then
        self:Bomb(x, y, 0, -v * 0.8, "web", "web")
    else
        self:Bomb(x, y, 0, -v)
    end
end
function Game:MobFire(m)
    local k = m.kind
    if k == "bat" or k == "rock" or k == "barrel" then return end
    if k == "necro" then
        m.fireT = NECRO_GAP
        local dead = self.pick
        for i = #dead, 1, -1 do dead[i] = nil end
        for i = 1, ROWS * COLS do
            local e = self.enemy[i]
            if e.row <= self.rows and e.hp <= 0 then dead[#dead + 1] = i end
        end
        local idx = self.rng:Pick(dead)
        if idx then
            local e = self.enemy[idx]
            e.hp = hpFor(self.wave, e.row)
            e.hpMax = e.hp
            self.alive = self.alive + 1
            self:Bounds()
            self.formDirty = true
            ns.FX.Nova(self.canvas,
                self.formX + (e.col - 1) * EPX + EN / 2,
                self.formY - (e.row - 1) * EPY - EN / 2, EN, e.icon or ns.QMARK)
        end
        return
    end
    if m.beh == "ring" then
        m.fireT = 2.2
        local v = self:BombV()
        self:Bomb(m.x, m.y, cos(m.ang) * v, sin(m.ang) * v)
        return
    end
    local y = m.y - EN / 2
    if k == "archer" then
        m.fireT = max(0.9, 1.6 - 0.03 * self.wave)
    elseif k == "cultist" then
        m.fireT = 2.4
    elseif k == "spider" then
        m.fireT = 2.0
    else
        m.fireT = 2.5
    end
    self:FireAs(k, m.x, y)
end
function Game:MoveMobs(dt)
    if self.phase ~= "play" then return end
    local k = (self.slow > 0) and 0.5 or 1
    local W = self.W
    local sx, sy = self.ship.x - SHIP / 2, self.ship.y
    local i = 1
    while i <= #self.mob do
        local m = self.mob[i]
        local gone = false
        local b = m.beh
        if b == "sine" then
            m.x = m.x + m.dir * m.v * k * dt
            m.y = m.y0 + m.amp * sin(m.x * 0.02 + m.ph)
            if (m.dir > 0 and m.x > W + EN) or (m.dir < 0 and m.x < -EN) then
                m.x = (m.dir > 0) and -EN or (W + EN)
                m.y0 = max(SHIP_Y + SHIP + 40, m.y0 - 26)
                m.laps = (m.laps or 0) + 1
            end
        elseif b == "sit" then
            m.x = m.x0 + SIEGE_SWAY * sin(self.t * 0.8 + m.ph)
        elseif b == "ring" then
            local r = self.ring
            if r then
                m.ang = m.ang + r.w * k * dt
                m.x = r.cx + r.r * cos(m.ang)
                m.y = r.cy + r.r * sin(m.ang)
            end
        elseif b == "fall" or b == "split" then
            m.x = m.x + m.vx * k * dt
            m.y = m.y + m.vy * k * dt
            gone = m.y < -EN or m.x < -EN or m.x > W + EN
        elseif b == "hover" then
            m.x = m.x + m.dir * m.v * k * dt
            if m.x < self.minX + EN / 2 then m.x, m.dir = self.minX + EN / 2, 1
            elseif m.x > self.maxX - EN / 2 then m.x, m.dir = self.maxX - EN / 2, -1 end
        elseif b == "sink" then
            m.y = m.y - m.v * k * dt
            gone = m.y < -EN
        elseif b == "rise" then
            m.y = m.y + m.v * k * dt
            gone = m.y > self.H + EN
        elseif b == "spike" then
            m.life = m.life - dt
            if m.tell > 0 then m.tell = m.tell - dt end
            gone = m.life <= 0
        elseif b == "chase" then
            local dx = self.ship.x - m.x
            local dy = (self.ship.y + SHIP / 2) - m.y
            local len = sqrt(dx * dx + dy * dy)
            if len > 1 then
                m.x = m.x + dx / len * m.v * k * dt
                m.y = m.y + dy / len * m.v * k * dt
            end
        end
        if not gone then
            m.fireT = m.fireT - dt
            if m.fireT <= 0 and m.y > SHIP_Y + SHIP + 40 and m.x > 0 and m.x < W then self:MobFire(m) end
        end
        local armed = (m.kind ~= "spike") or (m.tell or 0) <= 0
        if not gone and armed and m.kind ~= "necro" and m.kind ~= "ice"
            and m.y - EN / 2 < sy + SHIP and m.y + EN / 2 > sy
            and m.x + EN / 2 > sx and m.x - EN / 2 < sx + SHIP then
            if m.kind == "spike" then
                self:TakeHit()
                m.tell = 1.2
                i = i + 1
            else
                self:KillMob(m, false)
                self:TakeHit()
            end
        elseif gone then
            self:RemoveMob(m)
        else
            i = i + 1
        end
    end
    local r = self.ring
    if r then
        r.ph = r.ph + dt
        r.cx = W / 2 + 60 * sin(r.ph * 0.5)
        r.cy = max(r.cy - RING_SINK * k * dt, SHIP_Y + 20 + r.r)
    end
end
function Game:SpawnBoss()
    local tier = floor(self.wave / BOSS_EVERY)
    local info = D.bosses[(tier - 1) % #D.bosses + 1]
    self.boss = {
        name = ns.TL(info.name),
        icon = info.icon,
        fight = info.fight or "spin",
        tier = tier,
        hpMax = BOSS_HP_BASE + BOSS_HP_STEP * (tier - 1),
        x = self.W / 2,
        dir = 1,
        fireT = 2.0,
        ang = 0,
        rage = false,
    }
    self.boss.hp = self.boss.hpMax
    self.boss.y = self.topY - BOSS_SIZE + 10
    view.boss.icon:SetTexture(info.icon)
    view.boss.rim:SetVertexColor(1, 0.35, 0.35)
    if view.boss.elite then
        view.boss.elite:SetVertexColor(D.ELITE_GOLD[1], D.ELITE_GOLD[2], D.ELITE_GOLD[3])
        view.boss.elite:Show()
    end
    view.boss:Show()
end
function Game:MoveBoss(dt)
    local b = self.boss
    if not b then return end
    if self.phase ~= "play" then return end
    if not b.rage and b.hp <= b.hpMax * F.rageAt then
        b.rage = true
        self.note = ns.T("invaders.hudRageFmt", b.name)
        self.noteT = 2.0
        ns.Sfx.Play("rage")
        if b.fight == "frost" then self:SpawnIce() end
    end
    local half = BOSS_SIZE / 2
    local v = (BOSS_V_BASE + 12 * (b.tier - 1)) * (b.rage and F.rageV or 1)
    if self.slow > 0 then v = v * 0.5 end
    b.x = b.x + b.dir * v * dt
    if b.x < self.minX + half then
        b.x, b.dir = self.minX + half, 1
    elseif b.x > self.maxX - half then
        b.x, b.dir = self.maxX - half, -1
    end
    if b.fight == "frost" then self:BossFrost(dt) end
    self:BossTrick(dt)
    b.fireT = b.fireT - dt
    if b.fireT > 0 then return end
    local gap = max(BOSS_FIRE_FLOOR, BOSS_FIRE_BASE - 0.12 * (b.tier - 1))
    if b.rage then gap = gap * F.rageFire end
    if b.fight == "spin" then
        b.fireT = F.spinStep
        b.ang = b.ang + (b.rage and 0.9 or 0.7)
        local v2 = self:BombV() * F.spinV
        local n = b.rage and F.spinN + 2 or F.spinN
        for i = 1, n do
            local a = b.ang + i * 6.2832 / n
            self:Bomb(b.x, b.y, cos(a) * v2, sin(a) * v2 - 40)
        end
    elseif b.fight == "plague" then
        b.fireT = gap
        local v2 = self:BombV()
        for i = -1, 1 do self:Bomb(b.x + i * 22, b.y, i * 55, -v2) end
        if not b.poolT or b.poolT <= self.t then
            b.poolT = self.t + (b.rage and F.plagueGap * 0.6 or F.plagueGap)
            self:SpawnPool()
        end
    elseif b.fight == "summon" then
        b.fireT = b.rage and F.summonGap * 0.7 or F.summonGap
        local n = b.rage and F.summonN + 1 or F.summonN
        for i = 1, n do
            local x = self.minX + EN + self.rng:Float() * (self.maxX - self.minX - 2 * EN)
            local m = self:AddMob("ghoul", x, b.y - 10, "split")
            if m then
                m.vx = (self.rng:Float() - 0.5) * 120
                m.vy = -120
                m.fireT = 1.2 + self.rng:Float()
            end
        end
        self:Bomb(b.x, b.y, 0, -self:BombV())
    else
        b.fireT = gap
        local v2 = self:BombV()
        for i = -1, 1 do self:Bomb(b.x + i * 22, b.y, i * 55, -v2) end
    end
end
local TRICK_NAME = {
    spin   = "invaders.trickFlame",
    frost  = "invaders.trickTomb",
    plague = "invaders.trickCloud",
    summon = "invaders.trickShield",
}
function Game:BossTrick(dt)
    local b = self.boss
    b.trickT = (b.trickT or 4) - dt
    if b.trickT > 0 then return end
    b.tick = not b.tick
    local second = b.tick
    if b.fight == "frost" and second then
        b.trickT = b.rage and F.pullGap * 0.6 or F.pullGap
        self.pull = F.pullTime
        self.note = ns.T("invaders.trickPull")
        self.noteT = 1.8
        ns.Sfx.Play("warn")
        return
    elseif b.fight == "plague" and second then
        b.trickT = b.rage and F.streamGap * 0.6 or F.streamGap
        self.stream = { x = b.x, t = 0 }
        self.note = ns.T("invaders.trickStream")
        self.noteT = 1.8
        return
    elseif b.fight == "summon" and second then
        b.trickT = b.rage and F.swarmGap * 0.6 or F.swarmGap
        self.note = ns.T("invaders.trickSwarm")
        self.noteT = 1.8
        for i = 1, F.swarmN + (b.rage and 2 or 0) do
            local x = self.minX + EN + self.rng:Float() * (self.maxX - self.minX - 2 * EN)
            local m = self:AddMob("bug", x, -EN / 2, "rise")
            if m then
                m.v = F.swarmV + self.rng:Float() * 30
                m.hp, m.hpMax = 2, 2
                m.fireT = 1e6
            end
        end
        return
    end
    self.note = ns.T(TRICK_NAME[b.fight] or TRICK_NAME.spin)
    self.noteT = 1.8
    if b.fight == "spin" then
        b.trickT = b.rage and F.flameGap * 0.6 or F.flameGap
        self.flame = { x = b.x, dir = 1, t = 0, two = true }
        self:Spikes()
        ns.Sfx.Play("warn")
    elseif b.fight == "frost" then
        b.trickT = b.rage and F.tombGap * 0.6 or F.tombGap
        self.tomb = { x = self.ship.x, y = self.ship.y + SHIP / 2, t = 0 }
    elseif b.fight == "plague" then
        b.trickT = b.rage and F.cloudGap * 0.6 or F.cloudGap
        local m = self:AddMob("cloud", self.rng:Int(MARGIN, self.W - MARGIN), b.y - 20, "chase")
        if m then
            m.v = F.cloudV
            m.hp, m.hpMax = 6, 6
            m.fireT = 1e6
        end
    else
        b.trickT = F.shieldGap
        b.shield = true
        for i = 1, F.summonN do
            local x = self.minX + EN + self.rng:Float() * (self.maxX - self.minX - 2 * EN)
            local m = self:AddMob("cultist", x, b.y - 24, "split")
            if m then
                m.vx = (self.rng:Float() - 0.5) * 100
                m.vy = -90
                m.hp, m.hpMax = 3, 3
                m.fireT = 2.0
            end
        end
        ns.Sfx.Play("warn")
    end
end
function Game:Shielded()
    local b = self.boss
    if not b or not b.shield then return false end
    for i = 1, #self.mob do
        local k = self.mob[i].kind
        if k == "cultist" or k == "ghoul" then return true end
    end
    b.shield = false
    return false
end
function Game:Stream(dt)
    local st = self.stream
    if not st then return end
    if not self.boss then
        self.stream = nil
        return
    end
    st.t = st.t + dt
    st.x = self.boss.x
    if st.t >= F.streamTell + F.streamOn then
        self.stream = nil
        return
    end
    if self.phase ~= "play" or st.t < F.streamTell then return end
    st.hit = (st.hit or 0) - dt
    if st.hit > 0 then return end
    if abs(st.x - self.ship.x) < F.streamW / 2 + SHIP / 2 then
        st.hit = 0.6
        self:TakeHit()
    end
end
function Game:Flame(dt)
    local f = self.flame
    if not f then return end
    f.t = f.t + dt
    local run = F.flameV * f.t
    local lo, hi = f.x - run, f.x + run
    if run > self.W then
        self.flame = nil
        return
    end
    if self.phase ~= "play" then return end
    if self.ship.y >= SHIP_Y + 46 then return end
    local sx = self.ship.x
    local half = F.flameHalf + SHIP / 2
    if abs(sx - hi) < half or (f.two and abs(sx - lo) < half) then
        self:TakeHit()
    end
end
function Game:Spikes()
    for i = 1, F.spikeN do
        local x = self.minX + EN + self.rng:Float() * (self.maxX - self.minX - 2 * EN)
        if i == 1 then x = self.ship.x end
        local m = self:AddMob("spike", x, SHIP_Y + 18 + self.rng:Float() * 60, "spike")
        if m then
            m.hp, m.hpMax = 3, 3
            m.fireT = 1e6
            m.life = F.spikeLife
            m.tell = F.spikeTell
        end
    end
end
function Game:Tomb(dt)
    local t = self.tomb
    if not t then return end
    t.t = t.t + dt
    if t.t < F.tombTell then return end
    self.tomb = nil
    local m = self:AddMob("ice", t.x, t.y, "sit")
    if m then
        m.x0, m.ph, m.v = t.x, 0, 0
        m.hp, m.hpMax = F.tombHp, F.tombHp
        m.fireT = 1e6
    end
    if abs(t.x - self.ship.x) < EN / 2 + SHIP / 2
        and abs(t.y - (self.ship.y + SHIP / 2)) < EN / 2 + SHIP / 2 then
        self:TakeHit()
    end
end
function Game:BossFrost(dt)
    local b = self.boss
    local br = self.breath
    if br then
        br.t = br.t + dt
        if br.t >= F.frostTell and br.t < F.frostTell + F.frostOn and not br.hit then
            if abs(self.ship.x - br.x) < F.frostW / 2 + SHIP / 2 and not self:IcedAt(br.x) then
                br.hit = true
                self:TakeHit()
            end
        end
        if br.t >= F.frostTell + F.frostOn then self.breath = nil end
        return
    end
    b.breathT = (b.breathT or F.frostGap) - dt
    if b.breathT <= 0 then
        b.breathT = b.rage and F.frostGap * 0.65 or F.frostGap
        self.breath = { x = b.x, t = 0, hit = false }
    end
end
function Game:IcedAt(x)
    for i = 1, #self.mob do
        local m = self.mob[i]
        if m.kind == "ice" and abs(m.x - self.ship.x) < EN and abs(m.x - x) < F.frostW then
            return true
        end
    end
    return false
end
function Game:SpawnIce()
    for i = 1, F.iceN do
        local x = self.W * (i * 2 - 1) / (F.iceN * 2)
        local m = self:AddMob("ice", x, SHIP_Y + SHIP + 60, "sit")
        if m then
            m.x0 = m.x
            m.ph = 0
            m.v = 0
            m.hp, m.hpMax = F.iceHp, F.iceHp
            m.fireT = 1e6
        end
    end
end
function Game:SpawnPool()
    if #self.drop >= MAX_DROP then return end
    local p = self.pool
    if #p >= F.maxPool then table.remove(p, 1) end
    p[#p + 1] = {
        x = MARGIN + F.plagueR + self.rng:Float() * (self.W - 2 * MARGIN - 2 * F.plagueR),
        y = SHIP_Y + self.rng:Float() * (self.maxY - SHIP_Y + SHIP),
        t = F.plagueLife,
    }
end
function Game:Beam(dt)
    if self.beamT <= 0 then return end
    self.beamT = self.beamT - dt
    self.beamHit = self.beamHit - dt
    if self.beamHit > 0 then return end
    self.beamHit = BEAM_HIT
    local x = self.ship.x
    local lo, hi = x - BEAM_HALF, x + BEAM_HALF
    if self.boss and not self:Shielded() then
        local half = BOSS_SIZE / 2
        if hi > self.boss.x - half and lo < self.boss.x + half then self:HurtBoss(1) end
    end
    for i = #self.mob, 1, -1 do
        local m = self.mob[i]
        if m and hi > m.x - EN / 2 and lo < m.x + EN / 2 and m.y > self.ship.y then
            self:HurtMob(m, 1)
        end
    end
    if self.alive > 0 then
        for r = 1, ROWS do
            for c = 1, COLS do
                local e = self.enemy[(r - 1) * COLS + c]
                if e.hp > 0 and not e.dive then
                    local ex = self.formX + (c - 1) * EPX
                    if hi > ex and lo < ex + EN then self:Hurt(e, 1) end
                end
            end
        end
    end
end
function Game:Chainto(x, y, jumps, dmg)
    for _ = 1, jumps do
        local best, bd
        for i = 1, #self.mob do
            local m = self.mob[i]
            if m.kind ~= "ice" then
                local dx, dy = m.x - x, m.y - y
                local d = dx * dx + dy * dy
                if d <= CHAIN_R * CHAIN_R and (not bd or d < bd) then best, bd = m, d end
            end
        end
        if best then
            ns.FX.Nova(self.canvas, best.x, best.y, EN, D.BOLTS, 0.6)
            self:HurtMob(best, dmg)
            x, y = best.x, best.y
        else
            if self.alive <= 0 then return end
            local bi
            for i = 1, ROWS * COLS do
                local e = self.enemy[i]
                if e.hp > 0 and not e.dive then
                    local ex = self.formX + (e.col - 1) * EPX + EN / 2
                    local ey = self.formY - (e.row - 1) * EPY - EN / 2
                    local dx, dy = ex - x, ey - y
                    local d = dx * dx + dy * dy
                    if d <= CHAIN_R * CHAIN_R and (not bd or d < bd) then
                        bd, bi, best = d, i, e
                    end
                end
            end
            if not bi then return end
            x = self.formX + (best.col - 1) * EPX + EN / 2
            y = self.formY - (best.row - 1) * EPY - EN / 2
            self:Hurt(best, dmg)
        end
        bd = nil
    end
end
function Game:Pools(dt)
    local p = self.pool
    local sx, sy = self.ship.x, self.ship.y + SHIP / 2
    local i = 1
    while i <= #p do
        local z = p[i]
        z.t = z.t - dt
        if z.t <= 0 then
            table.remove(p, i)
        else
            if self.phase == "play" then
                local dx, dy = sx - z.x, sy - z.y
                if dx * dx + dy * dy <= F.plagueR * F.plagueR then
                    z.burn = (z.burn or 0) - dt
                    if z.burn <= 0 then
                        z.burn = 1.0
                        self:TakeHit()
                    end
                else
                    z.burn = 0
                end
            end
            i = i + 1
        end
    end
end
function Game:HurtBoss(n)
    local b = self.boss
    if not b then return false end
    if self:Shielded() then return true end
    b.hp = b.hp - n
    if b.hp > 0 then return true end
    self:Chain()
    self:Award(BOSS_SCORE * b.tier)
    for i = 1, BOSS_DROPS do
        self:SpawnDrop(b.x + (i - 2) * 30, b.y)
    end
    self.boss = nil
    self.breath, self.flame, self.tomb, self.stream = nil, nil, nil, nil
    self.pull = 0
    for i = #self.pool, 1, -1 do self.pool[i] = nil end
    for i = #self.mob, 1, -1 do
        if self.mob[i].kind == "ice" then self:RemoveMob(self.mob[i]) end
    end
    view.boss:Hide()
    ns.FX.Nova(self.canvas, b.x, b.y + BOSS_SIZE / 2, BOSS_SIZE, b.icon, 1.5)
    if self.alive > 0 then ns.Sfx.Play("boss") end
    return true
end
function Game:SpawnDrop(x, y)
    if #self.drop >= MAX_DROP then return end
    local roll = self.rng:Float() * D.dropWeight
    local acc = 0
    for _, d in ipairs(D.drops) do
        acc = acc + d.weight
        if roll < acc then
            local key = d.key
            if key == "gun" then
                key = "gun" .. WEAPONS[self.rng:Int(#WEAPONS)].key
            end
            self.drop[#self.drop + 1] = { x = x, y = y, k = key }
            return
        end
    end
end
function Game:TakeDrop(key)
    if key:match("^gun") then ns.Sfx.Play("gun") else ns.Sfx.Play("pop") end
    local gunKey = key:match("^gun(%a+)$")
    if gunKey and byGun[gunKey] then
        if self.gun.k == gunKey then
            if self.gun.lvl < GUN_MAX then self.gun.lvl = self.gun.lvl + 1
            else self.score = self.score + DROP_SCORE end
        else
            self.gun.k = gunKey
        end
        self.shotArt = "shot" .. gunKey
        self.note = ns.T("invaders.hudGunFmt", ns.T(byGun[gunKey].label), self.gun.lvl)
        self.noteT = 1.6
        return
    end
    local d = D.dropByKey[key]
    if not d then return end
    if key == "heal" then
        if self.lives < LIVES_MAX then self.lives = self.lives + 1
        else self.score = self.score + DROP_SCORE end
    elseif key == "score" then
        self.score = self.score + DROP_SCORE
    elseif key == "ward" then
        self.ship.ward = WARD_HITS
    elseif key == "ready" then
        self.cd = 0
    else
        self.buff[key] = d.dur
    end
    self.note = d.label
    self.noteT = 1.6
end
function Game:MoveDrops(dt)
    local sx, sy = self.ship.x - SHIP / 2, self.ship.y
    local i = 1
    while i <= #self.drop do
        local p = self.drop[i]
        p.y = p.y - DROP_V * dt
        local dead = p.y + PICK < 0
        if not dead
            and p.y < sy + SHIP and p.y + PICK > sy
            and p.x + PICK / 2 > sx and p.x - PICK / 2 < sx + SHIP then
            dead = true
            self:TakeDrop(p.k)
        end
        if dead then table.remove(self.drop, i) else i = i + 1 end
    end
end
function Game:Key(action, down)
    if self.phase == "over" then return end
    if action == "left" then
        self.keyLeft = down and true or nil
    elseif action == "right" then
        self.keyRight = down and true or nil
    elseif action == "up" then
        self.keyUp = down and true or nil
    elseif action == "down" then
        self.keyDown = down and true or nil
    elseif action == "fire" and down then
        if self.cd <= 0 then self:Move{ k = "cast" } end
    end
end
function Game:MoveShip(dt)
    local half = SHIP / 2
    local dx, dy = 0, 0
    if self.keyLeft then dx = dx - 1 end
    if self.keyRight then dx = dx + 1 end
    if self.keyUp then dy = dy + 1 end
    if self.keyDown then dy = dy - 1 end
    local v = SHIP_V
    if self.rush > 0 then v = v * 2 end
    if self.buff.swift > 0 then v = v * SWIFT_MUL end
    if self.webT > 0 then v = v * 0.5 end
    local x = self.ship.x + dx * v * dt
    if x < half then x = half elseif x > self.W - half then x = self.W - half end
    local y = self.ship.y + dy * v * dt
    if self.pull > 0 then y = y + F.pullV * dt end
    if y < SHIP_Y then y = SHIP_Y elseif y > self.maxY then y = self.maxY end
    local d = x - self.ship.x
    self.ship.vx = dt > 0 and d / dt or 0
    self.ship.x, self.ship.y = x, y
end
function Game:Gun()
    return byGun[self.gun.k] or byGun[GUN_START]
end
function Game:GunSpec()
    local c = self:Gun()
    local pierce, blast, dmg, chain = c.pierce or 1, c.blast, 1, c.chain
    if self.gun.lvl >= PERK_AT then
        if c.perkPierce then pierce = c.perkPierce end
        if c.perkBlast then blast = c.perkBlast end
        if c.perkDmg then dmg = c.perkDmg end
        if c.perkChain then chain = c.perkChain end
    end
    return pierce, blast, dmg, chain
end
function Game:Award(n)
    self.score = self.score + n * self.mult
end
function Game:Chain()
    self.chain = self.chain + 1
    local m = min(CHAIN_MAX, 1 + floor(self.chain / CHAIN_STEP))
    if m > self.mult then
        self.mult = m
        self.note = ns.T("invaders.hudChainFmt", m)
        self.noteT = 1.4
        if m >= 3 then ns.Sfx.Play("big") end
    end
end
function Game:BreakChain()
    self.chain, self.mult = 0, 1
end
function Game:Fire(vx, dx)
    if #self.shot >= MAX_SHOT then return end
    local c = self:Gun()
    if c.inherit then
        local ivx = self.ship.vx * c.inherit
        if ivx > 220 then ivx = 220 elseif ivx < -220 then ivx = -220 end
        vx = vx + ivx
    end
    local pierce, blast, dmg, chain = self:GunSpec()
    self.shot[#self.shot + 1] = {
        x = self.ship.x + dx, y = self.ship.y + SHIP,
        vx = vx, vy = c.shotV, p = pierce, b = blast, d = dmg, c = chain,
    }
end
local function shotSound(k)
    if k == "fire" then ns.Sfx.Play("shotfire")
    elseif k == "arrow" then ns.Sfx.Play("shotarrow")
    elseif k == "shadow" then ns.Sfx.Play("shotshadow")
    elseif k == "axe" then ns.Sfx.Play("shotaxe")
    elseif k == "laser" then ns.Sfx.Play("shotlaser")
    elseif k == "bolt" then ns.Sfx.Play("shotbolt")
    end
end
function Game:AutoFire()
    if self.t - (self.shotSfxT or -1) >= SHOT_SFX then
        self.shotSfxT = self.t
        shotSound(self.gun.k)
    end
    local L = GUN_LEVEL[self.gun.lvl] or GUN_LEVEL[1]
    if L.n == 1 then
        self:Fire(0, 0)
    elseif L.n == 2 then
        self:Fire(0, -8)
        self:Fire(0, 8)
    else
        local k = (L.n - 1) / 2
        for i = -k, k do self:Fire(i * L.spread, 0) end
    end
    local rel = self:Gun().reload * L.rel
    if self.buff.rapid > 0 then rel = rel * RAPID_MUL end
    self.reloadT = rel
end
function Game:RowOfY(y)
    local d = self.formY - y
    if d < 0 then return nil end
    local r = floor(d / EPY) + 1
    if r < 1 or r > ROWS then return nil end
    if d - (r - 1) * EPY > EN then return nil end
    return r
end
function Game:ShotHitEnemy(s)
    local xl, xr = s.x - SHOT_W / 2, s.x + SHOT_W / 2
    local yb, yt = s.y, s.y + SHOT_H
    local dmg = s.d or 1
    local b = self.boss
    if b then
        local half = BOSS_SIZE / 2
        if yt > b.y and yb < b.y + BOSS_SIZE and xr > b.x - half and xl < b.x + half then
            self:HurtBoss(dmg)
            return true
        end
    end
    local u = self.ufo
    if u then
        local half = UFO_SIZE / 2
        local uy = self.H - UFO_TOP - UFO_SIZE
        if yt > uy and yb < uy + UFO_SIZE and xr > u.x - half and xl < u.x + half then
            self:HurtUfo()
            return true
        end
    end
    local wy = self.wyrm
    if wy then
        local half = WYRM_SIZE / 2
        local y0 = self.H - UFO_TOP - WYRM_SIZE
        if yt > y0 and yb < y0 + WYRM_SIZE and xr > wy.x - half and xl < wy.x + half then
            self:HurtWyrm()
            return true
        end
    end
    local d = self.diver
    if d then
        if yt > d.y and yb < d.y + EN and xr > d.x and xl < d.x + EN then
            self:Hurt(self.enemy[d.i], dmg)
            s.p = s.p - 1
            if s.p <= 0 then return true end
        end
    end
    for i = #self.mob, 1, -1 do
        local m = self.mob[i]
        if m and yt > m.y - EN / 2 and yb < m.y + EN / 2
            and xr > m.x - EN / 2 and xl < m.x + EN / 2 then
            local mx, my = m.x, m.y
            self:HurtMob(m, dmg)
            if s.c then self:Chainto(mx, my, s.c, dmg) end
            s.p = s.p - 1
            if s.p <= 0 then return true end
        end
    end
    if self.alive <= 0 then return false end
    local rA = self:RowOfY(s.y)
    local rB = self:RowOfY(s.y + SHOT_H)
    if rB == rA then rB = nil end
    if not rA and not rB then return false end
    local c1 = floor((xl - self.formX) / EPX) + 1
    local c2 = floor((xr - self.formX) / EPX) + 1
    if c1 < 1 then c1 = 1 end
    if c2 > COLS then c2 = COLS end
    local blast = s.b
    for pass = 1, 2 do
        local r = (pass == 1) and rA or rB
        if r then
            for c = c1, c2 do
                local e = self.enemy[(r - 1) * COLS + c]
                if e and e.hp > 0 and not e.dive then
                    local ex = self.formX + (c - 1) * EPX
                    if xr > ex and xl < ex + EN then
                        self:Hurt(e, dmg)
                        if blast then self:Splash(r, c, blast, dmg) end
                        if s.c then
                            self:Chainto(self.formX + (c - 1) * EPX + EN / 2,
                                self.formY - (r - 1) * EPY - EN / 2, s.c, dmg)
                        end
                        s.p = s.p - 1
                        if s.p <= 0 then return true end
                    end
                end
            end
        end
    end
    return false
end
function Game:Hurt(e, n)
    e.hp = e.hp - (n or 1)
    if e.hp > 0 then
        self.formDirty = true
        return false
    end
    self.alive = self.alive - 1
    self:Chain()
    local gain = (ROW_SCORE[e.row] or 10) * e.hpMax
    local cx = self.formX + (e.col - 1) * EPX + EN / 2
    local by = self.formY - (e.row - 1) * EPY - EN
    if e.dive then
        local d = self.diver
        if d then cx, by = d.x + EN / 2, d.y end
        gain = gain * DIVE_MUL
        e.dive = nil
        self.diver = nil
        view.diver:Hide()
    end
    self:Award(gain)
    self:Bounds()
    self.formDirty = true
    local f = self.frame[(e.row - 1) * COLS + e.col]
    if f then f:Hide() end
    ns.FX.Nova(self.canvas, cx, by + EN / 2, EN, e.icon or ns.QMARK)
    if self.rng:Float() < DROP_CHANCE then self:SpawnDrop(cx, by) end
    return true
end
function Game:Dives(dt)
    if self.phase ~= "play" or self.wave < DIVE_FROM then return end
    if self.diver then
        self:MoveDiver(dt)
        return
    end
    self.diveT = self.diveT - dt
    if self.diveT > 0 or self.alive <= 1 then return end
    local pick = self.pick
    for i = #pick, 1, -1 do pick[i] = nil end
    for c = 1, COLS do
        for r = ROWS, 1, -1 do
            local e = self.enemy[(r - 1) * COLS + c]
            if e.hp > 0 then
                pick[#pick + 1] = (r - 1) * COLS + c
                break
            end
        end
    end
    local idx = self.rng:Pick(pick)
    if idx then
        local e = self.enemy[idx]
        e.dive = true
        self.diver = {
            i = idx, ph = 0, aim = self.ship.x,
            x = self.formX + (e.col - 1) * EPX,
            y = self.formY - (e.row - 1) * EPY - EN,
            sway = self.rng:Float() * 6.2832,
        }
        view.diver.icon:SetTexture(e.icon or ns.QMARK)
        view.diver:Show()
        self:Bounds()
        self.formDirty = true
    end
    self.diveT = self:DiveGap()
end
function Game:MoveDiver(dt)
    local d = self.diver
    local e = self.enemy[d.i]
    local k = (self.slow > 0) and 0.5 or 1
    local vy, vx = DIVE_V * k * dt, DIVE_VX * k * dt
    if d.ph == 0 then
        local step = DIVE_TRACK * k * dt
        local want = self.ship.x - d.aim
        if want > step then want = step elseif want < -step then want = -step end
        d.aim = d.aim + want
        local tx = d.aim - EN / 2 + DIVE_SWAY * sin(self.t * 5 + d.sway)
        local dx = tx - d.x
        if dx > vx then dx = vx elseif dx < -vx then dx = -vx end
        d.x = d.x + dx
        d.y = d.y - vy
        if not d.bombed and d.y < DIVE_BOMB_Y then
            d.bombed = true
            self:Bomb(d.x + EN / 2, d.y, 0, -self:BombV(), "aim")
        end
        local sx, sy = self.ship.x - SHIP / 2, self.ship.y
        if d.y < sy + SHIP and d.y + EN > sy and d.x + EN > sx and d.x < sx + SHIP then
            e.hp = 0
            self.alive = self.alive - 1
            e.dive = nil
            self.diver = nil
            view.diver:Hide()
            self:Bounds()
            self.formDirty = true
            ns.FX.Nova(self.canvas, d.x + EN / 2, d.y + EN / 2, EN, e.icon or ns.QMARK)
            self:TakeHit()
            return
        end
        if d.y + EN < 0 then
            d.ph = 1
            d.y = self.H
        end
    else
        local sx = self.formX + (e.col - 1) * EPX
        local sy = self.formY - (e.row - 1) * EPY - EN
        local dx = sx - d.x
        if dx > vx then dx = vx elseif dx < -vx then dx = -vx end
        d.x = d.x + dx
        d.y = d.y - vy
        if d.y <= sy then
            e.dive = nil
            self.diver = nil
            view.diver:Hide()
            self:Bounds()
            self.formDirty = true
        end
    end
end
function Game:Ufos(dt)
    local u = self.ufo
    if u then
        u.x = u.x + u.dir * UFO_V * dt
        if u.x < -UFO_SIZE or u.x > self.W + UFO_SIZE then
            self.ufo = nil
            view.ufo:Hide()
        end
        return
    end
    if self.phase ~= "play" then return end
    self.ufoT = self.ufoT - dt
    if self.ufoT > 0 or self.boss or self.wyrm or self.wtype == "rain" then return end
    if self.wtype == "form" and self.alive < UFO_MIN_ALIVE then return end
    if self.wtype ~= "form" and #self.mob == 0 then return end
    local dir = (self.rng:Float() < 0.5) and 1 or -1
    self.ufo = {
        x = (dir > 0) and -UFO_SIZE / 2 or self.W + UFO_SIZE / 2,
        dir = dir, hp = UFO_HP,
        val = UFO_SCORE[self.rng:Int(1, #UFO_SCORE)],
    }
    self.ufoT = self:UfoGap()
    view.ufo:Show()
end
function Game:HurtUfo()
    local u = self.ufo
    if not u then return false end
    u.hp = u.hp - 1
    if u.hp > 0 then return true end
    self:Chain()
    self:Award(u.val)
    self.note = ns.T("invaders.hudUfoFmt", u.val * self.mult)
    self.noteT = 1.6
    self.ufo = nil
    view.ufo:Hide()
    ns.FX.Nova(self.canvas, u.x, self.H - UFO_TOP - UFO_SIZE / 2, UFO_SIZE,
        view.art.ufo or D.UFO_FALLBACK)
    ns.Sfx.Play("big")
    return true
end
function Game:Wyrms(dt)
    local w = self.wyrm
    if w then
        if self.phase == "play" then
            w.x = w.x + w.dir * WYRM_V * dt
            w.fireT = w.fireT - dt
            if w.fireT <= 0 and not self.beam and w.x > MARGIN and w.x < self.W - MARGIN then
                w.fireT = BEAM_GAP
                self.beam = { x = w.x, t = 0, hit = false }
            end
        end
        if w.x < -WYRM_SIZE or w.x > self.W + WYRM_SIZE then
            self.wyrm = nil
            view.wyrm:Hide()
        end
    end
    local bm = self.beam
    if bm then
        bm.t = bm.t + dt
        if bm.t >= BEAM_TELL and bm.t < BEAM_TELL + BEAM_ON and not bm.hit then
            if abs(self.ship.x - bm.x) < BEAM_W / 2 + SHIP / 2 then
                bm.hit = true
                self:TakeHit()
            end
        end
        if bm.t >= BEAM_TELL + BEAM_ON then
            self.beam = nil
            view.beam:Hide()
        end
    end
    if self.phase ~= "play" or self.wyrm or self.wave < WYRM_FROM then return end
    self.wyrmT = self.wyrmT - dt
    if self.wyrmT > 0 or self.boss or self.ufo or self.wtype == "rain" then return end
    local dir = (self.rng:Float() < 0.5) and 1 or -1
    self.wyrm = {
        x = (dir > 0) and -WYRM_SIZE / 2 or self.W + WYRM_SIZE / 2,
        dir = dir, hp = WYRM_HP, fireT = 1.5,
    }
    self.wyrmT = self:WyrmGap()
    view.wyrm:Show()
end
function Game:HurtWyrm()
    local w = self.wyrm
    if not w then return false end
    w.hp = w.hp - 1
    if w.hp > 0 then return true end
    self:Chain()
    self:Award(WYRM_SCORE)
    self.note = ns.T("invaders.hudUfoFmt", WYRM_SCORE * self.mult)
    self.noteT = 1.6
    self.wyrm = nil
    view.wyrm:Hide()
    ns.FX.Nova(self.canvas, w.x, self.H - UFO_TOP - WYRM_SIZE / 2, WYRM_SIZE, D.kinds.wyrm.icon, 1.3)
    ns.Sfx.Play("big")
    for i = 1, 2 do self:SpawnDrop(w.x + (i - 1.5) * 30, self.H - UFO_TOP - WYRM_SIZE) end
    return true
end
function Game:MoveShots(dt)
    local i = 1
    while i <= #self.shot do
        local s = self.shot[i]
        s.y = s.y + s.vy * dt
        s.x = s.x + s.vx * dt
        local dead = s.y > self.H or s.x < 0 or s.x > self.W
        if not dead and self.phase == "play" then dead = self:ShotHitEnemy(s) end
        if dead then table.remove(self.shot, i) else i = i + 1 end
    end
end
function Game:Bombs(dt)
    if self.phase ~= "play" then return end
    self.bombT = self.bombT - dt
    if self.bombT > 0 or self.alive <= 0 or #self.bomb >= MAX_BOMB then return end
    local pick = self.pick
    for i = #pick, 1, -1 do pick[i] = nil end
    for c = 1, COLS do
        for r = ROWS, 1, -1 do
            local e = self.enemy[(r - 1) * COLS + c]
            if e.hp > 0 and not e.dive then
                pick[#pick + 1] = (r - 1) * COLS + c
                break
            end
        end
    end
    self.bombAim = not self.bombAim
    local idx
    if self.bombAim then
        local best
        for i = 1, #pick do
            local e = self.enemy[pick[i]]
            local d = abs(self.formX + (e.col - 1) * EPX + EN / 2 - self.ship.x)
            if not best or d < best then best, idx = d, pick[i] end
        end
    else
        idx = self.rng:Pick(pick)
    end
    if idx then
        local e = self.enemy[idx]
        local x = self.formX + (e.col - 1) * EPX + EN / 2
        local y = self.formY - (e.row - 1) * EPY - EN
        local kind = rowKinds(self.wave)[e.row]
        if kind == "ghoul" then
            self:Bomb(x, y, 0, -self:BombV(), self.bombAim and "aim" or "plain")
        else
            self:FireAs(kind, x, y)
        end
    end
    local base = BOMB_BASE - BOMB_STEP * (self.wave - 1)
    if base < BOMB_FLOOR then base = BOMB_FLOOR end
    self.bombT = base * (0.75 + self.rng:Float() * 0.5)
end
function Game:MoveBombs(dt)
    local sx, sy = self.ship.x - SHIP / 2, self.ship.y
    local i = 1
    while i <= #self.bomb do
        local b = self.bomb[i]
        b.y = b.y + b.vy * dt
        b.x = b.x + b.vx * dt
        local dead = b.y + BOMB_H < 0 or b.y > self.H or b.x < 0 or b.x > self.W
        if not dead
            and b.y < sy + SHIP and b.y + BOMB_H > sy
            and b.x + BOMB_W / 2 > sx and b.x - BOMB_W / 2 < sx + SHIP then
            dead = true
            if b.k == "web" then
                if self.ship.invuln <= 0 then self.webT = WEB_SLOW end
            else
                self:TakeHit()
            end
        end
        if dead then table.remove(self.bomb, i) else i = i + 1 end
    end
end
function Game:TakeHit()
    if self.phase == "over" then return end
    if self.ship.invuln > 0 then return end
    if self.ship.ward > 0 then
        self.ship.ward = self.ship.ward - 1
        ns.Sfx.Play("deny")
        return
    end
    self.lives = self.lives - 1
    self.ship.invuln = INVULN
    ns.Sfx.Play("hit")
    self:BreakChain()
    if self.gun.lvl > 1 then self.gun.lvl = self.gun.lvl - 1 end
    if self.lives <= 0 then
        self.lives = 0
        self:EndGame(ns.T("invaders.endNoLives"))
    end
end
function Game:CheckWaveDone()
    if self.phase ~= "play" then return end
    if not self:WaveClear() then return end
    self.score = self.score + WAVE_BONUS * self.wave
    self.phase = "wave"
    self.phaseT = WAVE_PAUSE
    ns.Sfx.Play("clear")
    for i = #self.shot, 1, -1 do self.shot[i] = nil end
end
function Game:NextWave()
    self.wave = self.wave + 1
    self.phase = "play"
    self.phaseT = 0
    self:BuildWave()
    ns.Sfx.Play("start")
end
function Game:EndGame(why, restoring)
    if self.phase == "over" then return end
    self.phase = "over"
    self.phaseT = OVER_PAUSE
    self.why = why
    if self.lives > 0 then self.score = self.score + self.lives * LIFE_BONUS end
    if not restoring then ns.Sfx.Play("over") end
end
function Game:Start(seed, moves)
    ensureView(self.canvas)
    self.rng = ns.RNG.New(seed)
    self:Layout()
    self.gun.k, self.gun.lvl = GUN_START, 1
    self.ship.x, self.ship.y = self.W / 2, SHIP_Y
    self.ship.vx, self.ship.invuln, self.ship.ward = 0, 0, 0
    self.keyLeft, self.keyRight, self.keyUp, self.keyDown = nil, nil, nil, nil
    self.buff.rapid, self.buff.swift = 0, 0
    self.reloadT, self.webT = 0, 0
    self.beamT, self.beamHit = 0, 0
    self.chain, self.mult = 0, 1
    self.boss = nil
    view.boss:Hide()
    self.diver, self.ufo, self.wyrm, self.beam = nil, nil, nil, nil
    self.flame, self.tomb, self.stream = nil, nil, nil
    self.pull = 0
    view.diver:Hide()
    view.ufo:Hide()
    view.wyrm:Hide()
    view.beam:Hide()
    self:BuildSky()
    self:BuildWave()
    if moves and type(moves[1]) == "table" and moves[1].k == "snap" then
        self:Restore(moves[1])
    end
    enemyPool:Reset()
    self.frame = {}
    for i = 1, ROWS * COLS do
        self.frame[i] = enemyPool:Acquire()
    end
    enemyPool:HideExtras()
    self.layoutDirty = true
    self.shotArt = "shot" .. self.gun.k
    self:PaintGun()
    view.form:Show()
    view.ship:Show()
    view.hud:Show()
    self.formDirty = true
    self:Draw()
end
function Game:Update(dt)
    self.t = self.t + dt
    if self.cd > 0 then self.cd = self.cd - dt end
    if self.slow > 0 then self.slow = self.slow - dt end
    if self.rush > 0 then self.rush = self.rush - dt end
    if self.webT > 0 then self.webT = self.webT - dt end
    if self.pull > 0 then self.pull = self.pull - dt end
    if self.ship.invuln > 0 then self.ship.invuln = self.ship.invuln - dt end
    if self.reloadT > 0 then self.reloadT = self.reloadT - dt end
    if self.noteT and self.noteT > 0 then self.noteT = self.noteT - dt end
    for k, v in pairs(self.buff) do
        if v > 0 then self.buff[k] = v - dt end
    end
    self:MoveSky(dt)
    if self.phase == "over" then
        self.phaseT = self.phaseT - dt
        self:Draw()
        return
    end
    self:MoveShip(dt)
    if self.phase == "play" then
        self:Formation(dt)
        self:MoveBoss(dt)
        self:Spawns(dt)
        self:MoveMobs(dt)
        self:Dives(dt)
        self:Ufos(dt)
        self:Wyrms(dt)
        self:Pools(dt)
        self:Beam(dt)
        self:Flame(dt)
        self:Tomb(dt)
        self:Stream(dt)
        if self.phase == "play" and self.reloadT <= 0 then self:AutoFire() end
        self:Bombs(dt)
    else
        self:Ufos(dt)
        self:Wyrms(dt)
        self.phaseT = self.phaseT - dt
        if self.phaseT <= 0 then self:NextWave() end
    end
    self:MoveShots(dt)
    self:MoveBombs(dt)
    self:MoveDrops(dt)
    self:CheckWaveDone()
    self:Draw()
end
function Game:Move(move)
    if not move or move.k ~= "cast" then return end
    if self.phase == "over" then return end
    if self.cd > 0 then return end
    local w = self:Gun()
    self.cd = w.cd
    ns.Sfx.Play("pick")
    local k = w.key
    if k == "fire" then
        self.slow = SLOW_TIME
    elseif k == "arrow" then
        for i = -2, 2 do self:Fire(i * 80, 0) end
    elseif k == "shadow" then
        self.ship.ward = WARD_HITS
    elseif k == "axe" then
        self.rush = RUSH_TIME
        if self.ship.invuln < RUSH_TIME then self.ship.invuln = RUSH_TIME end
    elseif k == "laser" then
        self.beamT = BEAM_TIME
    else
        for i = 1, ROWS * COLS do
            local e = self.enemy[i]
            if e.hp > 0 and not e.dive then self:Hurt(e, 1) end
        end
        for i = #self.mob, 1, -1 do
            local m = self.mob[i]
            if m and m.kind ~= "ice" then self:HurtMob(m, 1) end
        end
        ns.FX.Nova(self.canvas, self.W / 2, self.H / 2, self.W / 2, D.kinds.wyrm.icon, 1.2)
    end
end
function Game:Click(x, y, button)
end
function Game:Score()
    return floor(self.score or 0)
end
function Game:IsOver()
    return self.phase == "over" and self.phaseT <= 0
end
function Game:Marks()
    return { wave = self.wave }
end
function Game:Stop()
    hideView()
end
function Game:Serialize()
    local en = {}
    for i = 1, ROWS * COLS do en[i] = tostring(min(self.enemy[i].hp, 9)) end
    local shot = {}
    for i = 1, #self.shot do
        local s = self.shot[i]
        shot[#shot + 1] = { x = s.x, y = s.y, vx = s.vx, vy = s.vy, p = s.p, b = s.b, d = s.d, c = s.c }
    end
    local bomb = {}
    for i = 1, #self.bomb do
        local b = self.bomb[i]
        bomb[#bomb + 1] = { x = b.x, y = b.y, vx = b.vx, vy = b.vy, a = b.a, k = b.k }
    end
    local drop = {}
    for i = 1, #self.drop do
        local p = self.drop[i]
        drop[#drop + 1] = { x = p.x, y = p.y, k = p.k }
    end
    local mob = {}
    for i = 1, #self.mob do
        local m = self.mob[i]
        mob[#mob + 1] = {
            k = m.kind, b = m.beh, hp = m.hp, hpMax = m.hpMax, x = m.x, y = m.y,
            dir = m.dir, v = m.v, y0 = m.y0, amp = m.amp, ph = m.ph, ang = m.ang,
            x0 = m.x0, vx = m.vx, vy = m.vy, ft = m.fireT, life = m.life, tell = m.tell,
        }
    end
    local queue = {}
    for i = 1, #self.queue do
        local q = self.queue[i]
        queue[#queue + 1] = { at = q.at - self.t, w = q.w, kind = q.kind, side = q.side, n = q.n }
    end
    local boss
    if self.boss then
        local bb = self.boss
        boss = { hp = bb.hp, hpMax = bb.hpMax, tier = bb.tier, x = bb.x, dir = bb.dir,
                 fireT = bb.fireT, ang = bb.ang, rage = bb.rage and 1 or 0,
                 breathT = bb.breathT, poolT = bb.poolT and (bb.poolT - self.t) or nil,
                 trickT = bb.trickT, shield = bb.shield and 1 or 0,
                 tick = bb.tick and 1 or 0 }
    end
    local flame
    if self.flame then
        flame = { x = self.flame.x, dir = self.flame.dir, t = self.flame.t }
    end
    local tomb
    if self.tomb then tomb = { x = self.tomb.x, y = self.tomb.y, t = self.tomb.t } end
    local breath
    if self.breath then
        breath = { x = self.breath.x, t = self.breath.t, hit = self.breath.hit and 1 or 0 }
    end
    local pool = {}
    for i = 1, #self.pool do
        local z = self.pool[i]
        pool[#pool + 1] = { x = z.x, y = z.y, t = z.t }
    end
    local diver
    if self.diver then
        local d = self.diver
        diver = { i = d.i, x = d.x, y = d.y, ph = d.ph, aim = d.aim,
                  sway = d.sway, bombed = d.bombed and 1 or 0 }
    end
    local ufo
    if self.ufo then
        ufo = { x = self.ufo.x, dir = self.ufo.dir, hp = self.ufo.hp, val = self.ufo.val }
    end
    local wyrm
    if self.wyrm then
        wyrm = { x = self.wyrm.x, dir = self.wyrm.dir, hp = self.wyrm.hp, fireT = self.wyrm.fireT }
    end
    local beam
    if self.beam then beam = { x = self.beam.x, t = self.beam.t, hit = self.beam.hit and 1 or 0 } end
    local ring
    if self.ring then
        ring = { cx = self.ring.cx, cy = self.ring.cy, r = self.ring.r, w = self.ring.w, ph = self.ring.ph }
    end
    return {
        k = "snap", v = 4,
        gun = self.gun.k, glvl = self.gun.lvl,
        wave = self.wave, lives = self.lives, score = self.score, t = self.t,
        dir = self.dir, fx = self.formX, fy = self.formY,
        hold = self.hold, ebb = self.ebb and 1 or 0,
        sx = self.ship.x, sy = self.ship.y, inv = self.ship.invuln, ward = self.ship.ward,
        cd = self.cd, slow = self.slow, rush = self.rush, web = self.webT, beam = self.beamT,
        rel = self.reloadT, bt = self.bombT, ba = self.bombAim and 1 or 0,
        dt = self.diveT, ut = self.ufoT, wt = self.wyrmT,
        rain = self.rainT, spawn = self.spawnT,
        rapid = self.buff.rapid, swift = self.buff.swift,
        chain = self.chain, mult = self.mult,
        phase = self.phase, pt = self.phaseT,
        rng = self.rng:State(),
        en = table.concat(en),
        shot = shot, bomb = bomb, drop = drop, boss = boss,
        diver = diver, ufo = ufo, wyrm = wyrm, beam = beam, ring = ring,
        breath = breath, pool = pool, flame = flame, tomb = tomb,
        pull = self.pull, stream = self.stream and self.stream.t or nil,
        mob = mob, queue = queue,
    }
end
function Game:Restore(s)
    if s.v ~= 4 then return end
    self.gun.k = byGun[s.gun or ""] and s.gun or GUN_START
    self.gun.lvl = ns.Store.Num(s.glvl, 1, GUN_MAX, 1)
    self.wave  = ns.Store.Num(s.wave, 1, 9999, 1)
    self.lives = ns.Store.Num(s.lives, 0, LIVES_MAX, LIVES)
    self.score = ns.Store.Num(s.score, 0, 1e9, 0)
    self.t     = ns.Store.Num(s.t, 0, 1e6, 0)
    self.wtype = waveType(self.wave)
    self.rows  = rowsFor(self.wave)
    self:AssignIcons()
    self.dir   = (ns.Store.Num(s.dir, -1, 1, 1) < 0) and -1 or 1
    self.formX = ns.Store.Num(s.fx, -FORM_W, self.W, floor((self.W - FORM_W) / 2))
    self.formY = ns.Store.Num(s.fy, LOSE_Y, self.H, self.topY)
    self.hold  = ns.Store.Num(s.hold, 0, HOLD_T, 0)
    self.ebb   = s.ebb == 1
    self.ship.x      = ns.Store.Num(s.sx, SHIP / 2, self.W - SHIP / 2, self.W / 2)
    self.ship.y      = ns.Store.Num(s.sy, SHIP_Y, self.maxY, SHIP_Y)
    self.ship.invuln = ns.Store.Num(s.inv, 0, INVULN, 0)
    self.ship.ward   = ns.Store.Num(s.ward, 0, WARD_HITS, 0)
    self.cd      = ns.Store.Num(s.cd, 0, self:Gun().cd, 0)
    self.slow    = ns.Store.Num(s.slow, 0, SLOW_TIME, 0)
    self.rush    = ns.Store.Num(s.rush, 0, RUSH_TIME, 0)
    self.webT    = ns.Store.Num(s.web, 0, WEB_SLOW, 0)
    self.beamT   = ns.Store.Num(s.beam, 0, BEAM_TIME, 0)
    self.reloadT = ns.Store.Num(s.rel, 0, 1, 0)
    self.bombT   = ns.Store.Num(s.bt, 0, BOMB_BASE * 1.5, 0)
    self.bombAim = ns.Store.Num(s.ba, 0, 1, 0) > 0
    self.diveT   = ns.Store.Num(s.dt, 0, DIVE_BASE * 1.5, 0)
    self.ufoT    = ns.Store.Num(s.ut, 0, UFO_GAP_HI, 0)
    self.wyrmT   = ns.Store.Num(s.wt, 0, WYRM_GAP_HI, 0)
    self.rainT   = ns.Store.Num(s.rain, 0, RAIN_TIME + 0.3 * self.wave, 0)
    self.spawnT  = ns.Store.Num(s.spawn, 0, RAIN_BASE, 0)
    self.buff.rapid = ns.Store.Num(s.rapid, 0, 15, 0)
    self.buff.swift = ns.Store.Num(s.swift, 0, 15, 0)
    self.chain = ns.Store.Num(s.chain, 0, 1e6, 0)
    self.mult  = ns.Store.Num(s.mult, 1, CHAIN_MAX, 1)
    self.phase  = (s.phase == "wave") and "wave" or "play"
    self.phaseT = ns.Store.Num(s.pt, 0, WAVE_PAUSE, 0)
    if s.rng then self.rng = ns.RNG.Restore(s.rng) end
    if type(s.en) == "string" and #s.en == ROWS * COLS then
        local n = 0
        for i = 1, ROWS * COLS do
            local e = self.enemy[i]
            local hp = tonumber(string.sub(s.en, i, i)) or 0
            if hp > HP_MAX then hp = HP_MAX end
            if e.row > self.rows then hp = 0 end
            e.hp = hp
            e.hpMax = max(hp, hpFor(self.wave, e.row))
            if hp > 0 then n = n + 1 end
        end
        self.alive = n
        self:Bounds()
    end
    for i = #self.shot, 1, -1 do self.shot[i] = nil end
    for _, sh in ipairs(type(s.shot) == "table" and s.shot or {}) do
        if #self.shot < MAX_SHOT and type(sh) == "table" then
            self.shot[#self.shot + 1] = {
                x = ns.Store.Num(sh.x, 0, self.W, 0), y = ns.Store.Num(sh.y, 0, self.H, 0),
                vx = ns.Store.Num(sh.vx, -600, 600, 0),
                vy = ns.Store.Num(sh.vy, 1, 1400, self:Gun().shotV),
                p = ns.Store.Num(sh.p, 1, 4, 1),
                b = sh.b and ns.Store.Num(sh.b, 1, 3, 1) or nil,
                d = ns.Store.Num(sh.d, 1, 3, 1),
                c = sh.c and ns.Store.Num(sh.c, 1, 4, 1) or nil,
            }
        end
    end
    for i = #self.bomb, 1, -1 do self.bomb[i] = nil end
    for _, b in ipairs(type(s.bomb) == "table" and s.bomb or {}) do
        if #self.bomb < MAX_BOMB and type(b) == "table" then
            self.bomb[#self.bomb + 1] = {
                x = ns.Store.Num(b.x, 0, self.W, 0), y = ns.Store.Num(b.y, 0, self.H, 0),
                vx = ns.Store.Num(b.vx, -400, 400, 0), vy = ns.Store.Num(b.vy, -400, 400, -BOMB_V),
                a = BOMB_TINT[b.a] and b.a or "plain", k = (b.k == "web") and "web" or nil,
            }
        end
    end
    for i = #self.drop, 1, -1 do self.drop[i] = nil end
    for _, p in ipairs(type(s.drop) == "table" and s.drop or {}) do
        local ok = type(p) == "table" and type(p.k) == "string"
            and (D.dropByKey[p.k] or byGun[p.k:match("^gun(%a+)$") or ""])
        if #self.drop < MAX_DROP and ok then
            self.drop[#self.drop + 1] = {
                x = ns.Store.Num(p.x, 0, self.W, 0), y = ns.Store.Num(p.y, 0, self.H, 0), k = p.k,
            }
        end
    end
    self:ClearMobs()
    for _, mm in ipairs(type(s.mob) == "table" and s.mob or {}) do
        if type(mm) == "table" and D.kinds[mm.k] and type(mm.b) == "string" then
            local m = self:AddMob(mm.k, ns.Store.Num(mm.x, -EN, self.W + EN, self.W / 2),
                ns.Store.Num(mm.y, -EN, self.H + EN, self.H / 2), mm.b)
            if m then
                m.hpMax = ns.Store.Num(mm.hpMax, 1, 99, 1)
                m.hp    = ns.Store.Num(mm.hp, 1, m.hpMax, 1)
                m.dir   = (ns.Store.Num(mm.dir, -1, 1, 1) < 0) and -1 or 1
                m.v     = ns.Store.Num(mm.v, 0, 400, 0)
                m.y0    = ns.Store.Num(mm.y0, 0, self.H, m.y)
                m.amp   = ns.Store.Num(mm.amp, 0, 200, 0)
                m.ph    = ns.Store.Num(mm.ph, 0, 100, 0)
                m.ang   = ns.Store.Num(mm.ang, -1e4, 1e4, 0)
                m.x0    = ns.Store.Num(mm.x0, 0, self.W, m.x)
                m.vx    = ns.Store.Num(mm.vx, -400, 400, 0)
                m.vy    = ns.Store.Num(mm.vy, -400, 400, 0)
                m.fireT = ns.Store.Num(mm.ft, 0, 1e6, 1)
                m.life  = ns.Store.Num(mm.life, 0, F.spikeLife, 0)
                m.tell  = ns.Store.Num(mm.tell, 0, 2, 0)
            end
        end
    end
    for i = #self.queue, 1, -1 do self.queue[i] = nil end
    for _, q in ipairs(type(s.queue) == "table" and s.queue or {}) do
        if type(q) == "table" and (q.w == "pack" or q.w == "mob") and D.kinds[q.kind] then
            self:Enqueue(self.t + ns.Store.Num(q.at, 0, 120, 0), {
                w = q.w, kind = q.kind,
                side = (ns.Store.Num(q.side, -1, 1, 1) < 0) and -1 or 1,
                n = ns.Store.Num(q.n, 1, 12, 6),
            })
        end
    end
    self.ring = nil
    if type(s.ring) == "table" and self.wtype == "ring" then
        self.ring = {
            cx = ns.Store.Num(s.ring.cx, 0, self.W, self.W / 2),
            cy = ns.Store.Num(s.ring.cy, 0, self.H, self.H * 0.62),
            r  = ns.Store.Num(s.ring.r, 10, 300, RING_R),
            w  = ns.Store.Num(s.ring.w, 0, 10, 1),
            ph = ns.Store.Num(s.ring.ph, 0, 1e6, 0),
        }
    end
    self.boss = nil
    view.boss:Hide()
    if type(s.boss) == "table" and self.wtype == "boss" then
        self:SpawnBoss()
        local b = self.boss
        b.hp    = ns.Store.Num(s.boss.hp, 1, b.hpMax, b.hpMax)
        b.x     = ns.Store.Num(s.boss.x, MARGIN, self.W - MARGIN, self.W / 2)
        b.dir   = (ns.Store.Num(s.boss.dir, -1, 1, 1) < 0) and -1 or 1
        b.fireT = ns.Store.Num(s.boss.fireT, 0, max(BOSS_FIRE_BASE, F.summonGap), BOSS_FIRE_BASE)
        b.ang   = ns.Store.Num(s.boss.ang, -1e4, 1e4, 0)
        b.rage  = ns.Store.Num(s.boss.rage, 0, 1, 0) > 0
        b.breathT = ns.Store.Num(s.boss.breathT, 0, F.frostGap, F.frostGap)
        local pt = ns.Store.Num(s.boss.poolT, 0, F.plagueGap, -1)
        b.poolT = pt >= 0 and (self.t + pt) or nil
        b.trickT = ns.Store.Num(s.boss.trickT, 0, F.shieldGap, 4)
        b.shield = ns.Store.Num(s.boss.shield, 0, 1, 0) > 0
        b.tick = ns.Store.Num(s.boss.tick, 0, 1, 0) > 0
    end
    self.pull = ns.Store.Num(s.pull, 0, F.pullTime, 0)
    self.stream = nil
    if self.boss and s.stream then
        self.stream = { x = self.boss.x, t = ns.Store.Num(s.stream, 0, F.streamTell + F.streamOn, 0) }
    end
    self.flame, self.tomb = nil, nil
    if self.boss and type(s.flame) == "table" then
        self.flame = {
            x = ns.Store.Num(s.flame.x, -20, self.W + 20, self.W / 2),
            dir = (ns.Store.Num(s.flame.dir, -1, 1, 1) < 0) and -1 or 1,
            t = ns.Store.Num(s.flame.t, 0, 30, 0),
        }
    end
    if self.boss and type(s.tomb) == "table" then
        self.tomb = {
            x = ns.Store.Num(s.tomb.x, 0, self.W, self.W / 2),
            y = ns.Store.Num(s.tomb.y, 0, self.H, SHIP_Y),
            t = ns.Store.Num(s.tomb.t, 0, F.tombTell, 0),
        }
    end
    self.breath = nil
    if type(s.breath) == "table" and self.boss then
        self.breath = {
            x = ns.Store.Num(s.breath.x, 0, self.W, self.boss.x),
            t = ns.Store.Num(s.breath.t, 0, F.frostTell + F.frostOn, 0),
            hit = ns.Store.Num(s.breath.hit, 0, 1, 0) > 0,
        }
    end
    for i = #self.pool, 1, -1 do self.pool[i] = nil end
    for _, z in ipairs(type(s.pool) == "table" and s.pool or {}) do
        if #self.pool < F.maxPool and type(z) == "table" then
            self.pool[#self.pool + 1] = {
                x = ns.Store.Num(z.x, 0, self.W, self.W / 2),
                y = ns.Store.Num(z.y, 0, self.H, SHIP_Y),
                t = ns.Store.Num(z.t, 0, F.plagueLife, F.plagueLife),
            }
        end
    end
    self.diver = nil
    view.diver:Hide()
    local dv = type(s.diver) == "table" and s.diver or nil
    local di = dv and ns.Store.Num(dv.i, 1, ROWS * COLS, 0) or 0
    if di > 0 and self.enemy[di].hp > 0 and self.wave >= DIVE_FROM then
        local e = self.enemy[di]
        e.dive = true
        self.diver = {
            i = di,
            x = ns.Store.Num(dv.x, -EN, self.W, self.W / 2),
            y = ns.Store.Num(dv.y, -EN, self.H, self.H / 2),
            ph = (ns.Store.Num(dv.ph, 0, 1, 0) > 0) and 1 or 0,
            aim = ns.Store.Num(dv.aim, 0, self.W, self.W / 2),
            sway = ns.Store.Num(dv.sway, 0, 6.2832, 0),
            bombed = ns.Store.Num(dv.bombed, 0, 1, 0) > 0,
        }
        view.diver.icon:SetTexture(e.icon or ns.QMARK)
        view.diver:Show()
        self:Bounds()
    end
    self.ufo = nil
    view.ufo:Hide()
    if type(s.ufo) == "table" and not self.boss then
        self.ufo = {
            x = ns.Store.Num(s.ufo.x, -UFO_SIZE, self.W + UFO_SIZE, self.W / 2),
            dir = (ns.Store.Num(s.ufo.dir, -1, 1, 1) < 0) and -1 or 1,
            hp = ns.Store.Num(s.ufo.hp, 1, UFO_HP, UFO_HP),
            val = ns.Store.Num(s.ufo.val, 50, 300, UFO_SCORE[1]),
        }
        view.ufo:Show()
    end
    self.wyrm, self.beam = nil, nil
    view.wyrm:Hide()
    view.beam:Hide()
    if type(s.wyrm) == "table" and not self.boss and not self.ufo then
        self.wyrm = {
            x = ns.Store.Num(s.wyrm.x, -WYRM_SIZE, self.W + WYRM_SIZE, self.W / 2),
            dir = (ns.Store.Num(s.wyrm.dir, -1, 1, 1) < 0) and -1 or 1,
            hp = ns.Store.Num(s.wyrm.hp, 1, WYRM_HP, WYRM_HP),
            fireT = ns.Store.Num(s.wyrm.fireT, 0, BEAM_GAP, BEAM_GAP),
        }
        view.wyrm:Show()
        if type(s.beam) == "table" then
            self.beam = {
                x = ns.Store.Num(s.beam.x, 0, self.W, self.wyrm.x),
                t = ns.Store.Num(s.beam.t, 0, BEAM_TELL + BEAM_ON, 0),
                hit = ns.Store.Num(s.beam.hit, 0, 1, 0) > 0,
            }
        end
    end
    if self.lives <= 0 then self:EndGame(ns.T("invaders.endNoLives"), true) end
    self.formDirty, self.layoutDirty = true, true
end
function Game:PaintGun()
    local w = self:Gun()
    local c = w.colour
    ns.Paint(view.cdFill, c[1], c[2], c[3], 0.9)
    if not view.ship.shipIsSprite and not view.ship.shipIsClass then
        view.ship.rim:SetVertexColor(c[1], c[2], c[3])
    end
    for i = 1, LIVES_MAX do
        view.life[i]:SetVertexColor(c[1], c[2], c[3])
    end
    self.shotArt = "shot" .. w.key
end
function Game:Stage(n)
    self.wave = max(1, floor(n))
    self.phase = "play"
    self.phaseT = 0
    self:BuildWave()
end
function Game:Locked()
    return self.alive < ROWS * COLS or self.wave > 1 or self.lives < LIVES
end
local function paintRound(f, hp, hpMax)
    local col = HP_COLOR[min(max(hp, 1), #HP_COLOR)]
    f.rim:SetVertexColor(col[1], col[2], col[3])
    local k = hpMax > 1 and (0.55 + 0.45 * hp / hpMax) or 1
    f.icon:SetVertexColor(k, k, k)
    if f.elite then
        if hpMax >= 4 then
            f.elite:SetVertexColor(D.ELITE_GOLD[1], D.ELITE_GOLD[2], D.ELITE_GOLD[3])
            f.elite:Show()
        elseif hpMax >= 3 then
            f.elite:SetVertexColor(D.ELITE_SILVER[1], D.ELITE_SILVER[2], D.ELITE_SILVER[3])
            f.elite:Show()
        else
            f.elite:Hide()
        end
    end
end
function Game:Draw()
    local canvas = self.canvas
    for L = 1, SKY_LAYERS do
        local f = view.sky[L]
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", 0, self.skyY[L])
    end
    if self.layoutDirty then
        self.layoutDirty = false
        for i = 1, ROWS * COLS do
            local e, f = self.enemy[i], self.frame[i]
            if f then
                f:ClearAllPoints()
                f:SetPoint("BOTTOMLEFT", view.form, "BOTTOMLEFT",
                    (e.col - 1) * EPX, FORM_H - (e.row - 1) * EPY - EN)
                f.icon:SetTexture(e.icon or ns.QMARK)
            end
        end
    end
    if self.formDirty then
        self.formDirty = false
        for i = 1, ROWS * COLS do
            local e, f = self.enemy[i], self.frame[i]
            if f then
                if e.hp > 0 and not e.dive then
                    paintRound(f, e.hp, e.hpMax)
                    f:Show()
                else
                    f:Hide()
                end
            end
        end
    end
    view.form:ClearAllPoints()
    view.form:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.formX, self.formY - FORM_H)
    if self.boss then
        view.boss:ClearAllPoints()
        view.boss:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
            self.boss.x - BOSS_SIZE / 2, self.boss.y)
    end
    local d = self.diver
    if d then
        local e = self.enemy[d.i]
        paintRound(view.diver, e.hp, e.hpMax)
        view.diver:ClearAllPoints()
        view.diver:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", d.x, d.y)
    end
    for i = 1, #self.mob do
        local m = self.mob[i]
        local f = m.f
        if f then
            if m.dirty then
                m.dirty = false
                paintRound(f, m.hp, m.hpMax)
            end
            if m.kind == "spike" then
                local t = m.tell or 0
                local a = t > 0 and (0.30 + 0.35 * sin(self.t * 14)) or 1
                f.icon:SetAlpha(a)
                f.rim:SetVertexColor(1, t > 0 and 0.75 or 0.35, 0.35)
            end
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", m.x - EN / 2, m.y - EN / 2)
        end
    end
    local u = self.ufo
    if u then
        view.ufo:ClearAllPoints()
        view.ufo:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
            u.x - UFO_SIZE / 2, self.H - UFO_TOP - UFO_SIZE)
    end
    local wy = self.wyrm
    if wy then
        local k = 0.55 + 0.45 * wy.hp / WYRM_HP
        view.wyrm.icon:SetVertexColor(k, k, k)
        view.wyrm:ClearAllPoints()
        view.wyrm:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT",
            wy.x - WYRM_SIZE / 2, self.H - UFO_TOP - WYRM_SIZE)
    end
    poolPool:Reset()
    for i = 1, #self.pool do
        local z = self.pool[i]
        local f = poolPool:Acquire()
        local a = z.t < 1.5 and 0.2 + 0.35 * z.t / 1.5 or 0.55
        f.tex:SetVertexColor(0.45, 0.95, 0.35, a)
        f:ClearAllPoints()
        f:SetPoint("CENTER", canvas, "BOTTOMLEFT", z.x, z.y)
    end
    poolPool:HideExtras()
    boltPool:Reset()
    local fl = self.flame
    if fl then
        for i = -1, 1 do
            local f = boltPool:Acquire()
            boltArt(f, "spark")
            f.glow:SetVertexColor(0.5, 0.9, 1, 0.5)
            f:ClearAllPoints()
            f:SetPoint("CENTER", canvas, "BOTTOMLEFT", fl.x - fl.dir * i * 14, SHIP_Y + 12)
        end
    end
    local tb = self.tomb
    if tb then
        local f = boltPool:Acquire()
        boltArt(f, "ice")
        local pulse = 0.3 + 0.5 * (tb.t / F.tombTell)
        f.glow:SetVertexColor(0.45, 0.75, 1, pulse)
        f:ClearAllPoints()
        f:SetPoint("CENTER", canvas, "BOTTOMLEFT", tb.x, tb.y)
    end
    boltPool:HideExtras()
    local sm = self.stream
    if sm and self.boss then
        view.breath:SetWidth(F.streamW)
        view.breath:SetHeight(self.boss.y)
        view.breath:ClearAllPoints()
        view.breath:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", sm.x - F.streamW / 2, 0)
        if sm.t < F.streamTell then
            ns.Paint(view.breath.tex, 0.5, 0.9, 0.3, 0.12 + 0.18 * (sm.t / F.streamTell))
        else
            ns.Paint(view.breath.tex, 0.45, 0.95, 0.3, 0.7)
        end
        view.breath:Show()
    else
    local br = self.breath
    if br and self.boss then
        local top = self.boss.y
        view.breath:SetHeight(top)
        view.breath:ClearAllPoints()
        view.breath:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", br.x - F.frostW / 2, 0)
        if br.t < F.frostTell then
            ns.Paint(view.breath.tex, 0.5, 0.8, 1, 0.10 + 0.14 * (br.t / F.frostTell))
        else
            ns.Paint(view.breath.tex, 0.75, 0.95, 1, 0.75)
        end
        view.breath:Show()
    else
        view.breath:Hide()
    end
    end
    local bm = self.beam
    if bm then
        local top = self.H - UFO_TOP - WYRM_SIZE
        view.beam:SetHeight(top)
        view.beam:ClearAllPoints()
        view.beam:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", bm.x - BEAM_W / 2, 0)
        if bm.t < BEAM_TELL then
            ns.Paint(view.beam.tex, 1, 0.4, 0.3, 0.18 + 0.15 * (bm.t / BEAM_TELL))
        else
            ns.Paint(view.beam.tex, 0.75, 0.92, 1, 0.85)
        end
        view.beam:Show()
    else
        view.beam:Hide()
    end
    local shown = not (self.ship.invuln > 0 and floor(self.t * 8) % 2 == 0)
    view.ship:ClearAllPoints()
    view.ship:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", self.ship.x - SHIP / 2, self.ship.y)
    if shown then view.ship:Show() else view.ship:Hide() end
    if self.pull > 0 then
        view.ward.tex:SetVertexColor(0.55, 0.85, 1, 0.35 + 0.3 * sin(self.t * 9))
        view.ward:ClearAllPoints()
        view.ward:SetPoint("CENTER", view.ship, "CENTER", 0, 0)
        view.ward:Show()
    elseif self.ship.ward > 0 then
        local pulse = 0.45 + 0.25 * sin(self.t * 4)
        view.ward.tex:SetVertexColor(0.45, 0.75, 1, pulse)
        view.ward:ClearAllPoints()
        view.ward:SetPoint("CENTER", view.ship, "CENTER", 0, 0)
        view.ward:Show()
    else
        view.ward:Hide()
    end
    local gc = self:Gun().colour
    local r, g, b = gc[1], gc[2], gc[3]
    shotPool:Reset()
    for i = 1, #self.shot do
        local s = self.shot[i]
        local f = shotPool:Acquire()
        boltArt(f, self.shotArt)
        f.glow:SetVertexColor(r, g, b, 0.55)
        f:ClearAllPoints()
        f:SetPoint("CENTER", canvas, "BOTTOMLEFT", s.x, s.y + SHOT_H / 2)
    end
    shotPool:HideExtras()
    bombPool:Reset()
    for i = 1, #self.bomb do
        local bo = self.bomb[i]
        local f = bombPool:Acquire()
        boltArt(f, bo.a)
        local tn = BOMB_TINT[bo.a] or BOMB_TINT.plain
        f.glow:SetVertexColor(tn[1], tn[2], tn[3], 0.5)
        f:ClearAllPoints()
        f:SetPoint("CENTER", canvas, "BOTTOMLEFT", bo.x, bo.y + BOMB_H / 2)
    end
    bombPool:HideExtras()
    dropPool:Reset()
    for i = 1, #self.drop do
        local p = self.drop[i]
        local f = dropPool:Acquire()
        boltArt(f, D.DropArt(p.k))
        f.glow:SetVertexColor(0.45, 1, 0.5, 0.45)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", p.x - PICK / 2, p.y)
    end
    dropPool:HideExtras()
    self:DrawHud()
end
local WAVE_NAME = {
    form = "invaders.waveForm", packs = "invaders.wavePacks", ring = "invaders.waveRing",
    rain = "invaders.waveRain", siege = "invaders.waveSiege",
}
function Game:DrawHud()
    view.wave:SetText(ns.T("invaders.hudWaveFmt", self.wave))
    view.score:SetText(tostring(floor(self.score or 0)))
    for i = 1, LIVES_MAX do
        if i <= self.lives then view.life[i]:Show() else view.life[i]:Hide() end
    end
    if self.boss then
        local frac = self.boss.hp / self.boss.hpMax
        if frac < 0 then frac = 0 end
        if self:Shielded() then
            view.bossName:SetText(self.boss.name .. "  |cff60d0ff" .. ns.T("invaders.hudShield") .. "|r")
            ns.Paint(view.bossFill, 0.35, 0.6, 0.9, 0.95)
        else
            view.bossName:SetText(self.boss.name)
            ns.Paint(view.bossFill, 0.85, 0.25, 0.25, 0.95)
        end
        view.bossFill:SetWidth(max(1, (self.W - 24) * frac))
        view.bossName:Show()
        view.bossBg:Show()
        view.bossFill:Show()
    else
        view.bossName:Hide()
        view.bossBg:Hide()
        view.bossFill:Hide()
    end
    local c = self:Gun()
    if self.ship.ward > 0 then
        view.ability:SetText(ns.T("invaders.hudWardFmt", self.ship.ward))
    elseif self.cd > 0 then
        view.ability:SetText("|cff808080" .. ns.TL(c.ability) .. " " .. floor(self.cd + 0.99) .. "|r")
    else
        view.ability:SetText(ns.T("invaders.hudAbilityReadyFmt", ns.TL(c.ability)))
    end
    local left = self.cd > 0 and (1 - self.cd / c.cd) or 1
    view.cdFill:SetWidth(max(1, 120 * left))
    local gunLine = ns.T("invaders.hudGunFmt", ns.T(self:Gun().label), self.gun.lvl)
    if self.mult > 1 then
        gunLine = gunLine .. "  |cffffd040" .. ns.T("invaders.hudChainFmt", self.mult) .. "|r"
    end
    view.gun:SetText(gunLine)
    local parts = ""
    if self.buff.rapid > 0 then parts = parts .. ns.T("invaders.hudBuffRapidFmt", floor(self.buff.rapid + 0.99)) end
    if self.buff.swift > 0 then parts = parts .. ns.T("invaders.hudBuffSwiftFmt", floor(self.buff.swift + 0.99)) end
    if self.webT > 0 then parts = parts .. ns.T("invaders.hudWebFmt", floor(self.webT + 0.99)) end
    view.buffs:SetText(parts)
    if self.phase == "wave" then
        local nextWave = self.wave + 1
        view.banner:SetText(ns.T("invaders.hudWaveFmt", nextWave))
        local wt = waveType(nextWave)
        if wt == "boss" then
            local tier = floor(nextWave / BOSS_EVERY)
            view.note:SetText("|cffff6060" .. ns.TL(D.bosses[(tier - 1) % #D.bosses + 1].name) .. "|r")
        else
            view.note:SetText(ns.T(WAVE_NAME[wt]))
        end
        view.banner:Show()
        view.note:Show()
    elseif self.phase == "over" then
        view.banner:SetText(self.why or ns.T("invaders.hudGameOverDefault"))
        view.note:SetText(ns.T("invaders.hudWaveFmt", self.wave))
        view.banner:Show()
        view.note:Show()
    elseif self.noteT and self.noteT > 0 then
        view.banner:SetText("")
        view.note:SetText("|cff66dd66" .. (ns.TL(self.note) or "") .. "|r")
        view.banner:Hide()
        view.note:Show()
    else
        view.banner:Hide()
        view.note:Hide()
    end
    if self.barLocked ~= self:Locked() then
        self.barLocked = self:Locked()
        ns.window:SyncBar()
    end
end
local M = {
    sky    = { 0.05, 0.06, 0.10 },
    enemy  = { 0.55, 0.85, 1.00 },
    ship   = { 0.95, 0.85, 0.35 },
    shot   = { 1.00, 0.95, 0.55 },
    line   = { 1.00, 0.38, 0.38 },
    pack   = { 0.75, 0.55, 1.00 },
    pool   = { 0.45, 0.95, 0.35 },
    ice    = { 0.85, 0.97, 1.00 },
    breath = { 0.30, 0.48, 0.66 },
}
local MINI = {
    {
        cols = 7, rows = 4, cell = 22, gap = 1,
        fill = {
            { c = 2, r = 4, col = M.enemy }, { c = 3, r = 4, col = M.enemy },
            { c = 4, r = 4, col = M.enemy }, { c = 5, r = 4, col = M.enemy },
            { c = 6, r = 4, col = M.enemy },
        },
        arrow = {
            { c1 = 6, r1 = 4, c2 = 7, r2 = 4, col = M.shot },
            { c1 = 7, r1 = 4, c2 = 7, r2 = 3, col = M.shot },
        },
    },
    {
        cols = 6, rows = 5, cell = 20, gap = 1,
        fill = {
            { c = 1, r = 1, col = M.line }, { c = 2, r = 1, col = M.line },
            { c = 3, r = 1, col = M.line }, { c = 4, r = 1, col = M.line },
            { c = 5, r = 1, col = M.line }, { c = 6, r = 1, col = M.line },
            { c = 2, r = 2, col = M.enemy }, { c = 3, r = 2, col = M.enemy },
            { c = 4, r = 2, col = M.enemy }, { c = 5, r = 2, col = M.enemy },
        },
    },
    {
        cols = 5, rows = 5, cell = 22, gap = 1,
        fill = {
            { c = 3, r = 1, col = M.ship },
            { c = 3, r = 4, col = M.enemy },
        },
        arrow = { { c1 = 3, r1 = 1, c2 = 3, r2 = 4, col = M.shot } },
        ring  = { { c = 3, r = 4 } },
    },
    {
        cols = 7, rows = 5, cell = 20, gap = 1,
        fill = {
            { c = 1, r = 4, col = M.pack }, { c = 2, r = 5, col = M.pack },
            { c = 3, r = 4, col = M.pack }, { c = 4, r = 3, col = M.pack },
            { c = 5, r = 4, col = M.pack },
            { c = 4, r = 1, col = M.ship },
        },
        arrow = {
            { c1 = 5, r1 = 4, c2 = 7, r2 = 4, col = M.pack },
            { c1 = 4, r1 = 1, c2 = 4, r2 = 2, col = M.shot },
        },
    },
    {
        cols = 7, rows = 5, cell = 20, gap = 1,
        fill = {
            { c = 4, r = 5, col = M.line },
            { c = 4, r = 4, col = M.breath }, { c = 4, r = 3, col = M.breath },
            { c = 2, r = 2, col = M.pool }, { c = 6, r = 2, col = M.pool },
            { c = 4, r = 2, col = M.ice },
            { c = 4, r = 1, col = M.ship },
        },
        ring = { { c = 4, r = 2 } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, M.sky)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function art(i)
    return function(host) paintMini(host, MINI[i]) end
end
ns.RegisterGame{
    id = ID,
    label = "invaders.label",
    icon = D.mobs[4],
    tip = "invaders.tip",
    order = 7,
    duo = "none",
    physics = true,
    look = LOOK,
    ownPanel = true,
    canvas = { w = 600, h = 620 },
    New = New,
    record = {
        { key = "score", label = "invaders.recScore", by = "max", mark = "token" },
        { key = "wave",  label = "invaders.recWave",  by = "max", mark = "flask" },
    },
    stages = { max = 999 },
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
        { action = "up",    mouse = false },
        { action = "down",  mouse = false },
        { action = "fire",  label = "invaders.ctlAbility", mouse = false },
    },
    help = {
        "invaders.help1",
        { art = art(1), h = 99 },
        "invaders.helpMarchSub",
        "invaders.help2",
        { art = art(2), h = 112 },
        "invaders.helpWaves",
        { art = art(4), h = 106 },
        "invaders.helpPackSub",
        { icon = D.kinds.abom.icon, t = "invaders.helpMobs" },
        "invaders.help3",
        { art = art(3), h = 122 },
        { icon = D.bosses[1].icon, t = "invaders.help4" },
        { art = art(5), h = 106 },
        "invaders.helpBossSub",
        { icon = D.kinds.wyrm.icon, t = "invaders.helpChain" },
        { icon = D.BOLTS, coord = D.BOLT.score, t = "invaders.help5" },
        { icon = D.BOLTS, coord = D.BOLT.gunlaser, t = "invaders.helpGun" },
        "invaders.help6",
        "invaders.help9",
        { icon = D.UFO_FALLBACK, t = "invaders.help10" },
        "invaders.help8",
    },
}
