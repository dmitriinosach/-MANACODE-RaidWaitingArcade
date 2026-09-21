local ADDON, ns = ...
local M = {}
ns.Bomb = M
local MINE_ICON = "INV_Misc_Bomb_01"
local RING_ART = "Interface\\Minimap\\MiniMap-TrackingBorder"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local RING = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local SMITH_MODEL = "Creature\\HUMLBlackSmith\\HUMLBlackSmith.m2"
local SND_RAGE = "Sound\\Creature\\Goblin\\GoblinAggroA.wav"
local SND_FUSE = "Sound\\Item\\UseSounds\\UseFuseLighting.wav"
local SND_TICK = "Sound\\Spells\\SimonGame_Visual_GameTick.wav"
local SND_BOOM = "Sound\\Spells\\DynamiteExplode.wav"
local SEQ = { gobStand = 0, gobThrow = 107, smStand = 0, smWalk = 4, smBye = 35 }
local LEN_SMITH = { [0] = 2000, [4] = 1066, [35] = 1500 }
local GOB_SZ, SMITH_SZ = 72, 80
local GOB_LIFT, GOB_RISE, GOB_RISE_T, GOB_FADE = 16, 14, 0.25, 0.5
local MODEL_HOLD, TURN = 3, 16
local TWO_PI = math.pi * 2
local RAGE_T, RED_T, RED_A = 2.0, 0.15, 0.35
local RED_AT = { 0.35, 0.95 }
local THROW_T, THROW_OUT = 1.0, 0.4
local FLY_T, ARC_H, BOMB_SZ, SPARK_SZ = 0.7, 180, 44, 10
local FALL_T, BOUNCE_H = 0.4, 24
local FUSE_T, BLINK_MAX, BLINK_MIN = 3.0, 0.5, 0.1
local FLASH_UP, FLASH_DOWN, FLASH_A = 0.06, 0.55, 0.9
local RING_T, RING_K, RING_MIN = 0.7, 1.7, 60
local GRAV, VX, VY_MIN, VY_MAX, FLY_CAP = 1500, 220, 120, 420, 4
local SPIN_MIN, SPIN_MAX, SPIN_FLAT = 6, 14, 0.15
local BOUNCE_K, LIE_T = 0.35, 0.45
local ASH_GREY, DARK_T, CRUMBLE_T = 0.25, 0.4, 1.2
local GRAIN_MIN, GRAIN_MAX, GRAIN_BTN, GRAIN_ART, GRAIN_CAP = 4, 7, 10, 14, 260
local GRAIN_GRAV, GRAIN_SPREAD, LAND_MIN, LAND_MAX = 900, 90, 2, 12
local PILE_H, PILE_GREY, PILE_FADE = 26, 0.22, 0.6
local WAIT_T = 10
local ENTER_T, DROP_T, DROP_BOUNCE_T, DROP_BOUNCE_H = 1.6, 0.3, 0.2, 12
local BYE_T, LEAVE_T, LEAVE_FADE = 1.0, 1.4, 0.35
local BTN_W, BTN_H, BTN_GAP, BTN_A = 130, 22, 12, 0.3
local PANEL_ART = {
    "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
    "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap",
}
local DEF = {
    gobX = 0, gobY = 0, gobZ = 0, gobS = 1,
    smX = 0, smY = 0, smZ = 0, smS = 1,
}
M.KEYS = { "gobX", "gobY", "gobZ", "gobS", "smX", "smY", "smZ", "smS" }
local gob, bomb, flash, ring, pile, copy, smithL, smithR, drv, restore, pool, fxHost
local pieces, shards, grains = {}, {}, {}
local grainN, grainLand = 0, 0
local phase, t
local redFired = 0
local fuse = { blink = 0, ticks = 0 }
local dv = {}
local fadeT
local from, to = { x = 0, y = 0 }, { x = 0, y = 0 }
local hidden = false
local buttons = {}
local BLAST_K = 0.5
function M.Get(key)
    local v = ns.Config and ns.Config.Get("bomb", key, nil)
    if type(v) ~= "number" then return DEF[key] end
    return v
end
function M.Set(key, v)
    if DEF[key] == nil then return end
    ns.Config.Set("bomb", key, v)
    if gob and gob.model then gob.model.hold = MODEL_HOLD end
    if smithL and smithL.model then smithL.model.hold = MODEL_HOLD end
    if smithR and smithR.model then smithR.model.hold = MODEL_HOLD end
end
function M.State()
    return phase or "idle"
end
local function play(p)
    if ns.Store.Sound() then ns.Sounds.Play(p) end
end
local function uiPoint(f)
    local cx, cy = f:GetCenter()
    if not cx then return nil end
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return cx * k, cy * k
end
local function screen()
    return UIParent:GetWidth(), UIParent:GetHeight()
end
local function place(f, x, y)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end
local function slotOf(btn)
    if ActionButton_GetPagedID then
        local ok, id = pcall(ActionButton_GetPagedID, btn)
        if ok and type(id) == "number" then return id end
    end
    return btn.action or btn:GetID()
end
local function topFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(false)
    f:Hide()
    return f
end
local function makeModel(parent, w, h, path, len)
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, parent)
    if not ok or not m or not m.SetModel or not m.SetSequenceTime then return nil end
    m:SetWidth(w)
    m:SetHeight(h)
    m:SetPoint("CENTER", parent, "CENTER", 0, 0)
    m:SetFrameLevel(parent:GetFrameLevel() + 1)
    if not pcall(m.SetModel, m, path) then
        m:Hide()
        return nil
    end
    m.path, m.len = path, len
    m.hold = MODEL_HOLD
    m.anim = 0
    m:SetScript("OnShow", function(self)
        pcall(self.SetModel, self, self.path)
        self.hold = MODEL_HOLD
        self.seq = nil
        self.facing = nil
        self.shown = nil
    end)
    return m
end
local function drive(m, dt, id, facing, cam)
    if m.hold > 0 then m.hold = m.hold - dt end
    if m.facing == nil then m.facing = facing end
    local diff = (facing - m.facing) % TWO_PI
    if diff > math.pi then diff = diff - TWO_PI end
    local step = TURN * dt
    if math.abs(diff) <= step then m.facing = facing else m.facing = m.facing + (diff > 0 and step or -step) end
    if m.hold > 0 or m.shown ~= m.facing then
        m.shown = m.facing
        if m.SetModelScale then pcall(m.SetModelScale, m, M.Get(cam .. "S")) end
        if m.SetPosition then
            pcall(m.SetPosition, m, M.Get(cam .. "X"), M.Get(cam .. "Y"), M.Get(cam .. "Z"))
        end
        if m.SetFacing then pcall(m.SetFacing, m, m.facing) end
    end
    if m.seq ~= id then
        m.seq = id
        m.anim = 0
    end
    m.anim = m.anim + dt * 1000
    local len = m.len[id] or 1000
    if m.anim >= len then m.anim = m.anim - len end
    pcall(m.SetSequenceTime, m, id, m.anim)
end
local function walkFacing()
    local off, sign = math.pi, 1
    if ns.Murloc and ns.Murloc.Get then
        off, sign = ns.Murloc.Get("faceOff"), ns.Murloc.Get("faceSign")
    end
    return off + sign * math.atan2(1, 0)
end
local function newShard()
    local f = topFrame()
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    return f
end
local function resetShard(f)
    f:SetAlpha(1)
    f.tex:SetVertexColor(1, 1, 1)
end
local function makeSmith()
    local f = topFrame()
    f:SetWidth(SMITH_SZ)
    f:SetHeight(SMITH_SZ)
    f.model = makeModel(f, SMITH_SZ, SMITH_SZ, SMITH_MODEL, LEN_SMITH)
    return f
end
local tick
local function ensure()
    if drv then return end
    gob = topFrame()
    gob:SetWidth(GOB_SZ)
    gob:SetHeight(GOB_SZ)
    gob.say = CreateFrame("Frame", nil, gob)
    gob.say:SetFrameLevel(gob:GetFrameLevel() + 4)
    gob.say:SetWidth(260)
    gob.say:SetHeight(16)
    gob.say:SetPoint("BOTTOM", gob, "TOP", 0, 2)
    gob.say.text = gob.say:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gob.say.text:SetPoint("BOTTOM", gob.say, "BOTTOM", 0, 0)
    gob.say.text:SetTextColor(1, 0.55, 0.35)
    gob.t = 0
    bomb = topFrame()
    bomb:SetWidth(BOMB_SZ)
    bomb:SetHeight(BOMB_SZ)
    bomb.icon = bomb:CreateTexture(nil, "ARTWORK")
    bomb.icon:SetWidth(BOMB_SZ * 20 / 32)
    bomb.icon:SetHeight(BOMB_SZ * 20 / 32)
    bomb.icon:SetPoint("CENTER", bomb, "CENTER", 0, BOMB_SZ / 32)
    bomb.ring = bomb:CreateTexture(nil, "BORDER")
    bomb.ring:SetTexture(RING_ART)
    bomb.ring:SetWidth(BOMB_SZ * 53 / 32)
    bomb.ring:SetHeight(BOMB_SZ * 53 / 32)
    bomb.ring:SetPoint("TOPLEFT", bomb, "TOPLEFT", 0, 0)
    bomb.spark = bomb:CreateTexture(nil, "OVERLAY")
    bomb.spark:SetTexture(DISC)
    bomb.spark:SetBlendMode("ADD")
    bomb.spark:SetVertexColor(1, 0.15, 0.1)
    bomb.spark:SetWidth(SPARK_SZ)
    bomb.spark:SetHeight(SPARK_SZ)
    bomb.spark:SetPoint("CENTER", bomb, "TOPRIGHT", -8, -8)
    fxHost = topFrame()
    fxHost:SetAllPoints(UIParent)
    fxHost:Show()
    flash = topFrame()
    flash:SetAllPoints(UIParent)
    flash.tex = flash:CreateTexture(nil, "BACKGROUND")
    flash.tex:SetTexture(WHITE)
    flash.tex:SetAllPoints(flash)
    flash.t, flash.up, flash.down, flash.peak = 0, 1, 1, 0
    ring = topFrame()
    ring.tex = ring:CreateTexture(nil, "ARTWORK")
    ring.tex:SetTexture(RING)
    ring.tex:SetBlendMode("ADD")
    ring.tex:SetVertexColor(1, 0.6, 0.2)
    ring.tex:SetAllPoints(ring)
    pile = topFrame()
    pile.tex = pile:CreateTexture(nil, "ARTWORK")
    pile.tex:SetTexture(DISC)
    pile.tex:SetVertexColor(PILE_GREY, PILE_GREY, PILE_GREY)
    pile.tex:SetAllPoints(pile)
    copy = topFrame()
    copy.list = {}
    smithL = makeSmith()
    smithR = makeSmith()
    pool = ns.NewPool(newShard, resetShard)
    restore = ns.MakeKitButton(UIParent)
    restore:SetFrameStrata("FULLSCREEN_DIALOG")
    restore:SetWidth(BTN_W)
    restore:SetHeight(BTN_H)
    restore:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", BTN_GAP, BTN_GAP)
    restore:SetAlpha(BTN_A)
    restore.tipTitle = false
    restore.onClick = function() M.Restore() end
    restore:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
    restore:HookScript("OnLeave", function(self) self:SetAlpha(BTN_A) end)
    restore:Hide()
    drv = CreateFrame("Frame", nil, UIParent)
    drv:Hide()
    drv:SetScript("OnUpdate", function(_, dt)
        local ok, err = pcall(tick, dt)
        if not ok then
            ns.say("bomb: " .. tostring(err))
            M.Abort()
        end
    end)
end
local function setPhase(p)
    phase = p
    t = 0
end
local function showPanel()
    if not hidden then return end
    hidden = false
    if MainMenuBar then MainMenuBar:SetAlpha(1) end
    for i = 1, #buttons do pcall(buttons[i].btn.SetAlpha, buttons[i].btn, 1) end
    if restore then restore:Hide() end
end
local function finish()
    phase = nil
    if drv then
        drv:Hide()
        gob:Hide()
        gob.say:Hide()
        bomb:Hide()
        flash:Hide()
        ring:Hide()
        pile:Hide()
        copy:Hide()
        smithL:Hide()
        smithR:Hide()
        pool:HideAll()
    end
    pieces, shards, grains = {}, {}, {}
    grainN, grainLand = 0, 0
    fadeT = nil
    showPanel()
end
local function fireFlash(up, down, peak, r, g, b)
    flash.tex:SetVertexColor(r, g, b)
    flash.up, flash.down, flash.peak, flash.t = up, down, peak, 0
    flash:SetAlpha(0)
    flash:Show()
end
local function flashTick(dt)
    if not flash:IsShown() then return false end
    flash.t = flash.t + dt
    local a
    if flash.t < flash.up then
        a = flash.peak * flash.t / flash.up
    else
        a = flash.peak * math.max(0, 1 - (flash.t - flash.up) / flash.down)
    end
    flash:SetAlpha(a)
    if a <= 0 and flash.t >= flash.up then
        flash:Hide()
        return false
    end
    return true
end
local function ringTick()
    if not ring:IsShown() then return false end
    local W = screen()
    local k = math.min(1, ring.t / RING_T)
    local e = 1 - (1 - k) * (1 - k)
    local size = RING_MIN + (W * RING_K - RING_MIN) * e
    ring:SetWidth(size)
    ring:SetHeight(size)
    ring:SetAlpha(1 - k)
    if k >= 1 then
        ring:Hide()
        return false
    end
    return true
end
local function gobTick(dt)
    local gt = gob.t + dt
    gob.t = gt
    local a, y = 1, from.y
    if gt < GOB_RISE_T then
        a = gt / GOB_RISE_T
        y = from.y - GOB_RISE * (1 - a)
    end
    local seq = SEQ.gobStand
    if gt >= RAGE_T then seq = SEQ.gobThrow end
    if gt >= RAGE_T + THROW_T then
        a = 1 - (gt - RAGE_T - THROW_T) / GOB_FADE
        if a <= 0 then
            gob:Hide()
            gob.say:Hide()
            return
        end
    end
    gob:SetAlpha(a)
    place(gob, from.x, y)
    if gob.model then drive(gob.model, dt, seq, 0, "gob") end
end
local function addPiece(x, y, w, h, tex, coords, art)
    pieces[#pieces + 1] = { x = x, y = y, w = w, h = h, tex = tex, coords = coords, art = art }
end
local function collectArt()
    for i = 1, #PANEL_ART do
        local tx = _G[PANEL_ART[i]]
        if type(tx) == "table" and tx.GetObjectType and tx:GetObjectType() == "Texture"
            and tx:IsVisible() and tx:GetTexture() then
            local p = tx:GetParent()
            local cx, cy = tx:GetCenter()
            if p and cx then
                local k = p:GetEffectiveScale() / UIParent:GetEffectiveScale()
                local ulx, uly, llx, lly, urx = tx:GetTexCoord()
                addPiece(cx * k, cy * k, tx:GetWidth() * k, tx:GetHeight() * k, tx:GetTexture(),
                    { ulx, urx, uly, lly }, true)
            end
        end
    end
end
local function collectButtons()
    local _, H = screen()
    local r2 = (H * BLAST_K) * (H * BLAST_K)
    local all = ns.ActionButtons and ns.ActionButtons(true) or {}
    buttons = {}
    for i = 1, #all do
        local b = all[i]
        local dx, dy = b.x - to.x, b.y - to.y
        if dx * dx + dy * dy <= r2 then buttons[#buttons + 1] = b end
    end
    for i = 1, #buttons do
        local b = buttons[i]
        local tex = HasAction(b.slot) and GetActionTexture(b.slot)
        if tex then addPiece(b.x, b.y, b.w, b.h, tex, nil, false) end
    end
end
local function paint(tex, p)
    tex:SetTexture(p.tex)
    if p.coords then
        tex:SetTexCoord(p.coords[1], p.coords[2], p.coords[3], p.coords[4])
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end
local KIT = { "crack", "shards", "crumb", "chip", "dust" }
local DROP_SHARE = 0.35
local function kitBreak(p)
    if p.art or not (ns.FX and ns.FX.Play and ns.FX.Pick) then return false end
    if math.random() < DROP_SHARE then return false end
    local key = KIT[math.random(#KIT)]
    if not ns.FX.Pick(false, 1, key) then return false end
    ns.FX.Play(fxHost, { { x = p.x, y = p.y, size = p.w, tex = p.tex } }, { force = key })
    return true
end
local function shatter()
    pool:HideAll()
    shards = {}
    for i = 1, #pieces do
        local p = pieces[i]
        if not kitBreak(p) then
        local f = pool:Acquire()
        f:SetWidth(p.w)
        f:SetHeight(p.h)
        paint(f.tex, p)
        place(f, p.x, p.y)
        local s = { f = f, x = p.x, y = p.y, w = p.w, h = p.h, t = 0 }
        s.vx = (math.random() * 2 - 1) * VX
        s.vy = VY_MIN + math.random() * (VY_MAX - VY_MIN)
        s.spin = (SPIN_MIN + math.random() * (SPIN_MAX - SPIN_MIN)) * (math.random(2) == 1 and 1 or -1)
        s.ph = math.random() * math.pi
        s.n = p.art and GRAIN_ART or GRAIN_BTN
        s.done = 0
        s.lie = 0
        shards[#shards + 1] = s
        end
    end
end
local function dimPanel()
    if InCombatLockdown() then return end
    if MainMenuBar and MainMenuBar:IsVisible() then MainMenuBar:SetAlpha(0) end
    for i = 1, #buttons do pcall(buttons[i].btn.SetAlpha, buttons[i].btn, 0) end
    hidden = true
    restore:SetText(ns.T("bombRestore"))
    restore:SetAlpha(BTN_A)
    restore:Show()
end
local function spawnGrain(s)
    local f = pool:Acquire()
    local sz = GRAIN_MIN + math.random() * (GRAIN_MAX - GRAIN_MIN)
    f:SetWidth(sz)
    f:SetHeight(sz)
    f.tex:SetTexture(WHITE)
    f.tex:SetTexCoord(0, 1, 0, 1)
    local g = 0.2 + math.random() * 0.1
    f.tex:SetVertexColor(g, g, g)
    local x = s.x + (math.random() - 0.5) * s.w
    local y = s.y + (math.random() - 0.5) * s.h
    place(f, x, y)
    grains[#grains + 1] = {
        f = f, x = x, y = y,
        vx = (math.random() * 2 - 1) * GRAIN_SPREAD * 1.5,
        vy = 40 + math.random() * 160,
        floor = LAND_MIN + math.random() * (LAND_MAX - LAND_MIN),
    }
    grainN = grainN + 1
end
local function growPile()
    if grainN == 0 then return end
    local k = grainLand / grainN
    pile:SetWidth(math.max(1, dv.pw / 2 * k))
    pile:SetHeight(math.max(1, PILE_H * k))
    if not pile:IsShown() then
        pile:SetAlpha(1)
        pile:ClearAllPoints()
        pile:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", dv.cx, 0)
        pile:Show()
    end
end
local function dropShard(s, dt)
    local W = screen()
    s.vy = s.vy - GRAV * dt
    s.x = s.x + s.vx * dt
    s.y = s.y + s.vy * dt
    s.ph = s.ph + s.spin * dt
    local half = s.w / 2
    if s.x < half then s.x, s.vx = half, -s.vx * 0.5 end
    if s.x > W - half then s.x, s.vx = W - half, -s.vx * 0.5 end
    local floor = s.h / 2 + 2
    if s.y <= floor then
        s.y = floor
        if s.vy < -80 and not s.bounced then
            s.bounced = true
            s.vy = -s.vy * BOUNCE_K
            s.vx = s.vx * 0.6
        else
            s.vy, s.vx, s.spin = 0, 0, 0
            s.ph = 0
            s.lie = s.lie + dt
        end
    end
    local wk = math.max(SPIN_FLAT, math.abs(math.cos(s.ph)))
    s.f:SetWidth(math.max(1, s.w * wk))
    place(s.f, s.x, s.y)
    if s.lie >= LIE_T or s.t > FLY_CAP then
        s.crumble = true
        s.t = 0
        s.f:SetWidth(s.w)
    end
end
local function ashShard(s, dt)
    if s.fade then
        s.fade = s.fade + dt
        local a = 1 - s.fade / DARK_T
        if a <= 0 then s.f:Hide() else s.f:SetAlpha(a) end
        return
    end
    if s.t < DARK_T then
        local g = 1 - (1 - ASH_GREY) * (s.t / DARK_T)
        s.f.tex:SetVertexColor(g, g, g)
        return
    end
    local due = math.min(s.n, math.floor((s.t - DARK_T) / CRUMBLE_T * s.n) + 1)
    while s.done < due do
        if grainN >= GRAIN_CAP then
            s.fade = 0
            return
        end
        s.done = s.done + 1
        spawnGrain(s)
    end
    if s.done >= s.n then s.f:Hide() else s.f:SetAlpha(1 - s.done / s.n) end
end
local function debrisTick(dt)
    local alive = false
    for i = 1, #shards do
        local s = shards[i]
        if s.f:IsShown() then
            alive = true
            s.t = s.t + dt
            if s.crumble then ashShard(s, dt) else dropShard(s, dt) end
        end
    end
    for i = 1, #grains do
        local g = grains[i]
        if not g.land and g.f:IsShown() then
            alive = true
            g.vy = g.vy - GRAIN_GRAV * dt
            g.x = g.x + g.vx * dt
            g.y = g.y + g.vy * dt
            if g.y <= g.floor then
                g.y, g.land = g.floor, true
                grainLand = grainLand + 1
            end
            place(g.f, g.x, g.y)
        end
    end
    if fadeT then
        fadeT = fadeT + dt
        local a = math.max(0, 1 - fadeT / PILE_FADE)
        pile:SetAlpha(a)
        for i = 1, #grains do grains[i].f:SetAlpha(a) end
        if a <= 0 then
            pile:Hide()
            for i = 1, #grains do grains[i].f:Hide() end
            grains = {}
            fadeT = nil
        end
    end
    return alive
end
local function boom()
    bomb:Hide()
    play(SND_BOOM)
    fireFlash(FLASH_UP, FLASH_DOWN, FLASH_A, 1, 0.82, 0.55)
    ring.t = 0
    ring:SetWidth(RING_MIN)
    ring:SetHeight(RING_MIN)
    ring:SetAlpha(1)
    place(ring, to.x, to.y)
    ring:Show()
    pieces = {}
    collectArt()
    collectButtons()
    if #pieces == 0 then
        setPhase("done")
        return
    end
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    for i = 1, #pieces do
        local p = pieces[i]
        minX, maxX = math.min(minX, p.x - p.w / 2), math.max(maxX, p.x + p.w / 2)
        minY, maxY = math.min(minY, p.y - p.h / 2), math.max(maxY, p.y + p.h / 2)
    end
    dv.pw, dv.ph = maxX - minX, maxY - minY
    dv.cx, dv.cy = (minX + maxX) / 2, (minY + maxY) / 2
    grains, grainN, grainLand = {}, 0, 0
    shatter()
    dimPanel()
    setPhase("wait")
end
local function rageTick()
    for i = 1, #RED_AT do
        if t >= RED_AT[i] and redFired < i then
            redFired = i
            fireFlash(RED_T * 0.2, RED_T * 0.8, RED_A, 1, 0.1, 0.1)
        end
    end
    if t >= RAGE_T then setPhase("throw") end
end
local function throwTick()
    if t < THROW_OUT then return end
    bomb.spark:Hide()
    place(bomb, from.x, from.y)
    bomb:SetAlpha(1)
    bomb:Show()
    setPhase("fly")
end
local function flyTick()
    local k = math.min(1, t / FLY_T)
    local x = from.x + (to.x - from.x) * k
    local y = from.y + (to.y - from.y) * k + ARC_H * 4 * k * (1 - k)
    place(bomb, x, y)
    if k >= 1 then
        play(SND_FUSE)
        setPhase("fall")
    end
end
local function fallTick()
    local k = math.min(1, t / FALL_T)
    place(bomb, to.x, to.y + BOUNCE_H * 4 * k * (1 - k))
    if k >= 1 then
        fuse.blink, fuse.ticks = 0, 0
        bomb.spark:SetAlpha(1)
        bomb.spark:Show()
        setPhase("fuse")
    end
end
local function fuseTick(dt)
    local k = math.min(1, t / FUSE_T)
    local period = BLINK_MAX + (BLINK_MIN - BLINK_MAX) * k
    fuse.blink = fuse.blink + dt / period
    bomb.spark:SetAlpha((fuse.blink % 1) < 0.5 and 1 or 0.1)
    local n = math.floor(t)
    if n >= fuse.ticks and n < FUSE_T then
        fuse.ticks = n + 1
        play(SND_TICK)
    end
    if t >= FUSE_T then boom() end
end
local function buildCopy()
    for i = 1, #pieces do
        local p = pieces[i]
        local tex = copy.list[i]
        if not tex then
            tex = copy:CreateTexture(nil, "ARTWORK")
            copy.list[i] = tex
        end
        paint(tex, p)
        tex:SetVertexColor(1, 1, 1)
        tex:SetWidth(p.w)
        tex:SetHeight(p.h)
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", copy, "CENTER", p.x - dv.cx, p.y - dv.cy)
        tex:Show()
    end
    for i = #pieces + 1, #copy.list do copy.list[i]:Hide() end
    copy:SetWidth(math.max(1, dv.pw))
    copy:SetHeight(math.max(1, dv.ph))
end
local function startDeliver()
    local W = screen()
    dv.span = math.max(SMITH_SZ / 2, dv.pw / 2 - SMITH_SZ / 2)
    dv.sy = math.max(to.y, SMITH_SZ / 2)
    dv.lift = dv.sy + SMITH_SZ / 2 + dv.ph / 2 - dv.cy
    local reach = math.max(dv.pw / 2, dv.span + SMITH_SZ / 2) + 4
    dv.x0, dv.x1 = -reach, W + reach
    dv.swapped = false
    buildCopy()
    copy:SetAlpha(1)
    copy:Show()
    smithL:SetAlpha(1)
    smithR:SetAlpha(1)
    place(smithL, dv.x0 - dv.span, dv.sy)
    place(smithR, dv.x0 + dv.span, dv.sy)
    smithL:Show()
    smithR:Show()
    setPhase("deliver")
end
local function swap()
    dv.swapped = true
    copy:Hide()
    showPanel()
    fadeT = 0
end
local T_DROP = ENTER_T + DROP_T
local T_LAND = T_DROP + DROP_BOUNCE_T
local T_BYE = T_LAND + BYE_T
local function deliverTick(dt)
    local gx, seq, facing, lift, a = dv.cx, SEQ.smStand, 0, dv.lift, 1
    if t < ENTER_T then
        gx = dv.x0 + (dv.cx - dv.x0) * (t / ENTER_T)
        seq, facing = SEQ.smWalk, walkFacing()
    elseif t < T_DROP then
        local k = (t - ENTER_T) / DROP_T
        lift = dv.lift * (1 - k * k)
    elseif t < T_LAND then
        local k = (t - T_DROP) / DROP_BOUNCE_T
        lift = DROP_BOUNCE_H * math.sin(math.pi * k)
    elseif t < T_BYE then
        if not dv.swapped then swap() end
        seq = SEQ.smBye
    else
        if not dv.swapped then swap() end
        local k = (t - T_BYE) / LEAVE_T
        if k >= 1 then
            finish()
            return
        end
        gx = dv.cx + (dv.x1 - dv.cx) * k
        seq, facing = SEQ.smWalk, walkFacing()
        a = math.min(1, (1 - k) * LEAVE_T / LEAVE_FADE)
    end
    smithL:SetAlpha(a)
    smithR:SetAlpha(a)
    place(smithL, gx - dv.span, dv.sy)
    place(smithR, gx + dv.span, dv.sy)
    if copy:IsShown() then place(copy, gx, dv.cy + lift) end
    if smithL.model then drive(smithL.model, dt, seq, facing, "sm") end
    if smithR.model then drive(smithR.model, dt, seq, facing, "sm") end
end
function tick(dt)
    if dt > 0.1 then dt = 0.1 end
    t = t + dt
    if gob:IsShown() then gobTick(dt) end
    local glow = flashTick(dt)
    if ring:IsShown() then
        ring.t = ring.t + dt
        if ringTick() then glow = true end
    end
    if phase == "rage" then
        rageTick()
    elseif phase == "throw" then
        throwTick()
    elseif phase == "fly" then
        flyTick()
    elseif phase == "fall" then
        fallTick()
    elseif phase == "fuse" then
        fuseTick(dt)
    elseif phase == "wait" then
        debrisTick(dt)
        if t >= WAIT_T then startDeliver() end
    elseif phase == "deliver" then
        debrisTick(dt)
        deliverTick(dt)
    elseif phase == "done" then
        if not debrisTick(dt) and not glow and not gob:IsShown() then finish() end
    else
        finish()
    end
end
local function target()
    local W = screen()
    if MainMenuBar and MainMenuBar:IsVisible() then
        local x, y = uiPoint(MainMenuBar)
        if x then return x, y end
    end
    local list = ns.ActionButtons and ns.ActionButtons() or {}
    if #list > 0 then
        local x1, x2, y1, y2 = list[1].x, list[1].x, list[1].y, list[1].y
        for i = 2, #list do
            local b = list[i]
            if b.x < x1 then x1 = b.x end
            if b.x > x2 then x2 = b.x end
            if b.y < y1 then y1 = b.y end
            if b.y > y2 then y2 = b.y end
        end
        return (x1 + x2) / 2, (y1 + y2) / 2
    end
    return W / 2, 40
end
function M.Active()
    return phase ~= nil
end
function M.Throw(x, y)
    if InCombatLockdown() then return end
    if phase then return end
    ensure()
    from.x, from.y = x, y
    to.x, to.y = target()
    pieces, shards, grains = {}, {}, {}
    grainN, grainLand = 0, 0
    fadeT = nil
    redFired = 0
    pool:HideAll()
    bomb.icon:SetTexture(ns.IconPath(MINE_ICON))
    bomb.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    bomb:Hide()
    gob:Hide()
    gob.say:Hide()
    play(SND_RAGE)
    setPhase("rage")
    drv:Show()
end
function M.Restore()
    showPanel()
    if phase == "wait" or phase == "deliver" then M.Abort() end
end
function M.Abort()
    finish()
end
local events = CreateFrame("Frame", nil, UIParent)
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function() M.Abort() end)
