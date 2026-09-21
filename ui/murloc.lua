local ADDON, ns = ...
local M = {}
ns.Murloc = M
local MODEL = "Creature\\MurlocCostume\\murloccostume_noflag.M2"
local SLOT_ART = "Interface\\Buttons\\UI-Quickslot"
local SEQ = {
    sit = 97, jumpStart = 37, jump = 38, run = 5, cry = 77, yank = 62,
    taunt = { 73, 70, 69, 84 },
}
local LEN = {
    [5] = 666, [37] = 433, [38] = 833, [62] = 1667, [69] = 6533, [70] = 2667,
    [73] = 3334, [77] = 3766, [84] = 2267, [97] = 1667,
}
local CAGE_W, CAGE_H = 48, 44
local BODY, HAND = 56, 34
local HAND_DX, HAND_DY = 16, -6
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local SPEED, FEAR = 900, 320
local TIRE_FULL, TIRE_MIN, REST_K = 16, 0.6, 2
local ZIG, ZIG_T = 0.7, 0.3
local DODGE_R, DODGE_K, DODGE_T, DODGE_COOL = 130, 1.4, 0.22, 0.45
local PULL = 0.8
local CATCH_MIN = 0.12
local TURN = 16
local IDLE_LEAVE, LOOSE_CAP = 9, 5.5
local WANDER_T, EDGE = 2.5, 70
local DASH_K, DASH_T = 1.6, 0.5
local OUT_T, YANK_T, CRY_T, FADE_T, FLY_T = 0.5, 1.3, 1.2, 0.4, 0.45
local SAY_T = 2.2
local GONE_T = 60
local STEP_GAP = 0.28
local MODEL_HOLD = 3
local SND_OUT = "sound\\creature\\murloc\\mmurlocpreaggroa.wav"
local SND_YANK = "Sound\\Creature\\Murloc\\mMurlocAggroOld.wav"
local SND_CAUGHT = "sound\\creature\\murloc\\mmurlocpreaggroa.wav"
local SND_STEP = {
    "Sound\\Character\\Footsteps\\FootstepFishA.wav",
    "Sound\\Character\\Footsteps\\FootstepFishB.wav",
    "Sound\\Character\\Footsteps\\FootstepFishC.wav",
    "Sound\\Character\\Footsteps\\FootstepFishD.wav",
}
local DEF = {
    cageX = 0, cageY = 0, cageZ = 0, cageS = 1, cageF = 0,
    bodyX = 0, bodyY = 0, bodyZ = 0, bodyS = 1, bodyF = 0,
    faceOff = math.pi, faceSign = 1,
}
M.KEYS = {
    "cageX", "cageY", "cageZ", "cageS", "cageF",
    "bodyX", "bodyY", "bodyZ", "bodyS", "bodyF",
    "faceOff", "faceSign",
}
local cage, body, cover, fly, timer
local state = "caged"
local target
local pos = { x = 0, y = 0, vx = 0, vy = 0 }
local t = { phase = 0, tire = 0, idle = 0, loose = 0, step = 0, gone = 0, dash = 0 }
local taunt = SEQ.taunt[1]
local exit, away
function M.Get(key)
    local v = ns.Config and ns.Config.Get("murloc", key, nil)
    if type(v) ~= "number" then return DEF[key] end
    return v
end
function M.Set(key, v)
    if DEF[key] == nil then return end
    ns.Config.Set("murloc", key, v)
    if cage and cage.model then cage.model.hold = MODEL_HOLD end
    if body and body.model then body.model.hold = MODEL_HOLD end
end
function M.State()
    return state
end
function M.SetModelPath(path)
    MODEL = path or "Creature\\MurlocCostume\\murloccostume_noflag.M2"
    for _, f in ipairs({ cage, body }) do
        local m = f and f.model
        if m then
            pcall(m.SetModel, m, MODEL)
            m.hold = MODEL_HOLD
            m.seq, m.facing, m.shown = nil, nil, nil
        end
    end
    return MODEL
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
local function cursor()
    local x, y = GetCursorPosition()
    local k = UIParent:GetEffectiveScale()
    return x / k, y / k
end
local function screen()
    return UIParent:GetWidth(), UIParent:GetHeight()
end
local function makeModel(parent, w, h)
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, parent)
    if not ok or not m or not m.SetModel or not m.SetSequenceTime then return nil end
    m:SetWidth(w)
    m:SetHeight(h)
    m:SetPoint("CENTER", parent, "CENTER", 0, 0)
    if not pcall(m.SetModel, m, MODEL) then
        m:Hide()
        return nil
    end
    m.hold = MODEL_HOLD
    m.anim = 0
    m:SetScript("OnShow", function(self)
        pcall(self.SetModel, self, MODEL)
        self.hold = MODEL_HOLD
        self.seq = nil
        self.facing = nil
        self.shown = nil
    end)
    return m
end
local TWO_PI = math.pi * 2
local function drive(m, dt, id, facing, cam)
    if M.devSeq then id = M.devSeq end
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
    local len = LEN[id] or 1000
    if m.anim >= len then m.anim = m.anim - len end
    pcall(m.SetSequenceTime, m, id, m.anim)
end
function M.SyncCage()
    if not cage then return end
    local open = state ~= "caged"
    if cage.model then
        if open then cage.model:Hide() else cage.model:Show() end
    end
    for i, b in ipairs(cage.bars.list) do
        for _, tex in ipairs(b) do
            if open and i >= 4 then tex:Hide() else tex:Show() end
        end
    end
    if open then cage.bars.lock:Hide() else cage.bars.lock:Show() end
end
function M.Mount(parent)
    if cage then return cage end
    cage = CreateFrame("Button", nil, parent)
    cage:SetWidth(CAGE_W)
    cage:SetHeight(CAGE_H)
    cage.model = makeModel(cage, CAGE_W, CAGE_H)
    if cage.model then cage.model:SetFrameLevel(cage:GetFrameLevel() + 1) end
    cage.floor = ns.Fill(cage, "BACKGROUND", 0, 0, 0, 0.45)
    cage.floor:SetPoint("BOTTOMLEFT", cage, "BOTTOMLEFT", 2, 0)
    cage.floor:SetPoint("BOTTOMRIGHT", cage, "BOTTOMRIGHT", -2, 0)
    cage.floor:SetHeight(7)
    local bars = CreateFrame("Frame", nil, cage)
    bars:SetAllPoints(cage)
    bars:SetFrameLevel(cage:GetFrameLevel() + 2)
    bars.list = {}
    local function rod(w, h, point, x, y, dark)
        local tex = ns.Fill(bars, dark and "BORDER" or "ARTWORK",
            dark and 0.16 or 0.42, dark and 0.13 or 0.36, dark and 0.09 or 0.27, 1)
        tex:SetWidth(w)
        tex:SetHeight(h)
        tex:SetPoint(point, bars, point, x, y)
        return tex
    end
    local function bar(x)
        local shade = rod(4, CAGE_H, "LEFT", x, 0, true)
        local light = rod(2, CAGE_H, "LEFT", x, 0)
        local gloss = ns.Fill(bars, "OVERLAY", 1, 0.92, 0.7, 0.35)
        gloss:SetWidth(1)
        gloss:SetHeight(CAGE_H - 6)
        gloss:SetPoint("LEFT", bars, "LEFT", x, 1)
        return { shade, light, gloss }
    end
    rod(CAGE_W, 4, "TOP", 0, 0, true)
    rod(CAGE_W, 2, "TOP", 0, -1)
    rod(CAGE_W, 4, "BOTTOM", 0, 0, true)
    rod(CAGE_W, 2, "BOTTOM", 0, 1)
    rod(CAGE_W - 8, 3, "TOP", 0, -8, true)
    for i = 0, 4 do
        bars.list[#bars.list + 1] = bar(i * (CAGE_W - 4) / 4)
    end
    bars.lock = ns.Fill(bars, "OVERLAY", 0.85, 0.7, 0.25, 1)
    bars.lock:SetWidth(5)
    bars.lock:SetHeight(6)
    bars.lock:SetPoint("LEFT", bars, "LEFT", (CAGE_W - 4) * 3 / 4 - 1, -2)
    cage.bars = bars
    cage:SetScript("OnEnter", function(self)
        self.tipTitle = ns.T("murTitle")
        self.tipDim = nil
        if state == "caged" then
            self.tip = ns.T("murCageTip")
            if InCombatLockdown() then self.tipDim = ns.T("murCombat") end
        elseif state == "gone" then
            self.tip = ns.T("murGoneTip")
        else
            self.tip = ns.T("murLooseTip")
        end
        ns.TipShow(self)
    end)
    cage:SetScript("OnLeave", function() ns.TipHide() end)
    cage:SetScript("OnClick", function() M.Release() end)
    cage:SetScript("OnUpdate", function(self, dt)
        if self.model and self.model:IsShown() then
            drive(self.model, dt, SEQ.sit, M.Get("cageF"), "cage")
        end
    end)
    cage:SetScript("OnShow", function() M.SyncCage() end)
    M.SyncCage()
    return cage
end
local tick
local function place()
    body:ClearAllPoints()
    body:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
end
local function ensureBody()
    if body then return body end
    body = CreateFrame("Button", nil, UIParent)
    body:SetFrameStrata("FULLSCREEN_DIALOG")
    body:SetWidth(BODY)
    body:SetHeight(BODY)
    body:EnableMouse(true)
    body.model = makeModel(body, BODY, BODY)
    body.hand = CreateFrame("Frame", nil, body)
    body.hand:SetFrameLevel(body:GetFrameLevel() + 3)
    body.hand:SetWidth(HAND)
    body.hand:SetHeight(HAND)
    body.hand:SetPoint("CENTER", body, "CENTER", HAND_DX, HAND_DY)
    body.hand.icon = body.hand:CreateTexture(nil, "ARTWORK")
    body.hand.icon:SetAllPoints()
    body.hand:Hide()
    body.shadow = body:CreateTexture(nil, "BACKGROUND")
    body.shadow:SetTexture(DISC)
    body.shadow:SetVertexColor(0, 0, 0, 0.4)
    body.shadow:SetWidth(38)
    body.shadow:SetHeight(14)
    body.shadow:SetPoint("BOTTOM", body, "BOTTOM", 0, 2)
    body.say = CreateFrame("Frame", nil, body)
    body.say:SetFrameLevel(body:GetFrameLevel() + 4)
    body.say:SetWidth(120)
    body.say:SetHeight(16)
    body.say:SetPoint("BOTTOM", body, "TOP", 0, 2)
    body.say.text = body.say:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    body.say.text:SetPoint("BOTTOM", body.say, "BOTTOM", 0, 0)
    body.say.text:SetTextColor(0.55, 0.95, 0.6)
    body.say:Hide()
    body:SetScript("OnMouseDown", function() M.Catch() end)
    body:SetScript("OnUpdate", function(_, dt)
        local ok, err = pcall(tick, dt)
        if not ok then
            ns.say("murloc: " .. tostring(err))
            M.Abort()
        end
    end)
    body:Hide()
    cover = CreateFrame("Frame", nil, UIParent)
    cover:SetFrameStrata("DIALOG")
    cover.fill = ns.Fill(cover, "BACKGROUND", 0.06, 0.06, 0.06, 1)
    cover.fill:SetAllPoints()
    cover.art = cover:CreateTexture(nil, "ARTWORK")
    cover.art:SetTexture(SLOT_ART)
    cover.art:SetPoint("CENTER", cover, "CENTER", 0, -1)
    cover:Hide()
    fly = CreateFrame("Frame", nil, UIParent)
    fly:SetFrameStrata("FULLSCREEN_DIALOG")
    fly:SetWidth(HAND)
    fly:SetHeight(HAND)
    fly.icon = fly:CreateTexture(nil, "ARTWORK")
    fly.icon:SetAllPoints()
    fly:Hide()
    timer = CreateFrame("Frame", nil, UIParent)
    timer:Hide()
    timer:SetScript("OnUpdate", function(self, dt)
        t.gone = t.gone + dt
        if t.gone >= GONE_T then
            self:Hide()
            if state == "gone" then
                state = "caged"
                M.SyncCage()
            end
        end
    end)
    return body
end
local function slotOf(btn)
    if type(btn.action) == "number" and btn.action > 0 then return btn.action end
    local name = btn:GetName() or ""
    if ActionButton_GetPagedID and name:find("^ActionButton%d+$") then
        local ok, id = pcall(ActionButton_GetPagedID, btn)
        if ok and type(id) == "number" then return id end
    end
    if btn.GetAttribute then
        local a = btn:GetAttribute("action")
        if type(a) == "number" then return a end
    end
    return nil
end
function ns.ActionButtons(all)
    local list = {}
    local f = EnumerateFrames()
    while f do
        local otype = f.GetObjectType and f:GetObjectType()
        if (otype == "Button" or otype == "CheckButton") and f.GetAttribute and f:IsVisible() then
            local ok, kind = pcall(f.GetAttribute, f, "type")
            if ok and kind == "action" then
                local slot = slotOf(f)
                if type(slot) == "number" and (all or HasAction(slot)) then
                    local x, y = uiPoint(f)
                    if x then
                        local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
                        list[#list + 1] = { btn = f, slot = slot, x = x, y = y,
                            w = f:GetWidth() * k, h = f:GetHeight() * k }
                    end
                end
            end
        end
        f = EnumerateFrames(f)
    end
    return list
end
local function pickTarget()
    local list = ns.ActionButtons()
    if #list == 0 then return nil end
    return list[math.random(#list)]
end
local function pickExit()
    local W, H = screen()
    local d = { pos.x, W - pos.x, pos.y, H - pos.y }
    local best, bi = d[1], 1
    for i = 2, 4 do
        if d[i] < best then best, bi = d[i], i end
    end
    if bi == 1 then exit = { x = -BODY, y = pos.y }
    elseif bi == 2 then exit = { x = W + BODY, y = pos.y }
    elseif bi == 3 then exit = { x = pos.x, y = -BODY }
    else exit = { x = pos.x, y = H + BODY } end
end
local function say(key)
    body.say.text:SetText(ns.T(key))
    body.say:Show()
    t.say = SAY_T
end
local function grab()
    if not target then return end
    cover:ClearAllPoints()
    cover:SetPoint("CENTER", target.btn, "CENTER", 0, 0)
    local w, h = target.btn:GetWidth(), target.btn:GetHeight()
    cover:SetWidth(w)
    cover:SetHeight(h)
    cover.art:SetWidth(w * 66 / 36)
    cover.art:SetHeight(h * 66 / 36)
    cover:Show()
    body.hand.icon:SetTexture(GetActionTexture(target.slot))
    body.hand:Show()
    state = "flee"
    t.loose, t.idle, t.tire, t.dash = 0, 0, 0, 0
    local W, H = screen()
    away = { x = W * (0.3 + 0.4 * math.random()), y = H * (0.35 + 0.3 * math.random()) }
end
local function finish()
    body:Hide()
    body.hand:Hide()
    cover:Hide()
    if target and not InCombatLockdown() and not GetCursorInfo() and HasAction(target.slot) then
        PickupAction(target.slot)
        ClearCursor()
    end
    target = nil
    state = "gone"
    t.gone = 0
    timer:Show()
    M.SyncCage()
end
local function reopen()
    if not ns.window then return end
    ns.window:Open()
end
local function speedK()
    return math.max(TIRE_MIN, 1 - t.tire / TIRE_FULL)
end
local function stepTo(dt, tx, ty, v)
    local dx, dy = tx - pos.x, ty - pos.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then return true end
    local s = math.min(d, v * dt)
    pos.vx, pos.vy = dx / d * v, dy / d * v
    pos.x, pos.y = pos.x + dx / d * s, pos.y + dy / d * s
    return d - s < 4
end
local function flee(dt)
    local W, H = screen()
    local half = BODY / 2
    local cx, cy = cursor()
    local dx, dy = pos.x - cx, pos.y - cy
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then dx, dy, d = 1, 0, 1 end
    local v = SPEED * speedK()
    t.cool = math.max(0, (t.cool or 0) - dt)
    if t.dash > 0 then
        t.dash = t.dash - dt
    elseif d < DODGE_R and t.cool <= 0 then
        local px, py = -dy / d, dx / d
        local s = (px * (t.cvx or 0) + py * (t.cvy or 0)) > 0 and -1 or 1
        pos.vx, pos.vy = px * s * v * DODGE_K, py * s * v * DODGE_K
        t.dash, t.cool = DODGE_T, DODGE_COOL
    else
        t.zig = (t.zig or 0) - dt
        if t.zig <= 0 then
            t.zig = ZIG_T
            t.zigSign = -(t.zigSign or 1)
        end
        local ax, ay = dx / d + (-dy / d) * ZIG * t.zigSign, dy / d + (dx / d) * ZIG * t.zigSign
        ax = ax + (W / 2 - pos.x) / (W / 2) * PULL
        ay = ay + (H / 2 - pos.y) / (H / 2) * PULL
        local al = math.sqrt(ax * ax + ay * ay)
        if al < 0.01 then ax, ay, al = dx / d, dy / d, 1 end
        pos.vx, pos.vy = ax / al * v, ay / al * v
        local nx, ny = pos.x + pos.vx * dt, pos.y + pos.vy * dt
        local hitX = nx < half or nx > W - half
        local hitY = ny < half or ny > H - half
        if hitX and hitY then
            pos.vx, pos.vy = -dx / d * v * DASH_K, -dy / d * v * DASH_K
            t.dash = DASH_T
        elseif hitX then
            local s = pos.vy >= 0 and 1 or -1
            if math.abs(pos.vy) < 1 then s = math.random(2) == 1 and 1 or -1 end
            pos.vx, pos.vy = 0, s * v
        elseif hitY then
            local s = pos.vx >= 0 and 1 or -1
            if math.abs(pos.vx) < 1 then s = math.random(2) == 1 and 1 or -1 end
            pos.vx, pos.vy = s * v, 0
        end
    end
    pos.x = math.max(half, math.min(W - half, pos.x + pos.vx * dt))
    pos.y = math.max(half, math.min(H - half, pos.y + pos.vy * dt))
end
local function footstep(dt)
    t.step = t.step + dt
    if t.step >= STEP_GAP then
        t.step = 0
        play(SND_STEP[math.random(#SND_STEP)])
    end
end
local function runFacing()
    return M.Get("faceOff") + M.Get("faceSign") * math.atan2(pos.vx, pos.vy)
end
function tick(dt)
    if dt > 0.1 then dt = 0.1 end
    t.phase = t.phase + dt
    if t.say and t.say > 0 then
        t.say = t.say - dt
        if t.say <= 0 then body.say:Hide() end
    end
    do
        local cx, cy = cursor()
        if t.cx then
            t.cvx, t.cvy = (cx - t.cx) / dt, (cy - t.cy) / dt
        end
        t.cx, t.cy = cx, cy
        local dx, dy = pos.x - cx, pos.y - cy
        if dx * dx + dy * dy < DODGE_R * DODGE_R then
            t.near = (t.near or 0) + dt
        else
            t.near = 0
        end
    end
    local seq, facing = SEQ.run, M.Get("bodyF")
    if state == "out" then
        seq = t.phase < 0.43 and SEQ.jumpStart or SEQ.jump
        if t.phase >= OUT_T then
            target = pickTarget()
            t.phase = 0
            if target then
                state = "run"
            else
                pickExit()
                state = "escape"
            end
        end
    elseif state == "run" then
        if stepTo(dt, target.x, target.y + 10, SPEED) then
            state = "yank"
            t.phase = 0
            play(SND_YANK)
            say("murSayGrab")
        end
        facing = runFacing()
        footstep(dt)
    elseif state == "yank" then
        seq = SEQ.yank
        if t.phase >= YANK_T then grab() end
    elseif state == "flee" then
        t.loose = t.loose + dt
        if slotOf(target.btn) == target.slot then cover:Show() else cover:Hide() end
        local cx, cy = cursor()
        local dx, dy = pos.x - cx, pos.y - cy
        local near = dx * dx + dy * dy < FEAR * FEAR
        if away then
            if stepTo(dt, away.x, away.y, SPEED) then
                away = nil
                t.idle = 0
            elseif near then
                away = nil
            end
            facing = runFacing()
            footstep(dt)
        elseif near or t.dash > 0 then
            if t.idle > 0 then t.idle = 0 end
            t.tire = math.min(TIRE_FULL, t.tire + dt)
            flee(dt)
            seq = t.dash > 0 and SEQ.jump or SEQ.run
            facing = runFacing()
            footstep(dt)
        else
            if t.idle == 0 then
                taunt = SEQ.taunt[math.random(#SEQ.taunt)]
                say("murSayTaunt")
            end
            t.idle = t.idle + dt
            t.tire = math.max(0, t.tire - dt * REST_K)
            pos.vx, pos.vy = 0, 0
            seq = taunt
            if t.idle >= WANDER_T and t.idle - dt < WANDER_T then
                local W, H = screen()
                away = { x = EDGE + (W - EDGE * 2) * math.random(), y = EDGE + (H - EDGE * 2) * math.random() }
            end
            if t.idle >= IDLE_LEAVE then
                pickExit()
                state = "escape"
            end
        end
        if t.loose >= LOOSE_CAP and state == "flee" then
            pickExit()
            state = "escape"
        end
    elseif state == "escape" then
        stepTo(dt, exit.x, exit.y, SPEED * speedK())
        facing = runFacing()
        footstep(dt)
        local W, H = screen()
        local half = BODY / 2
        if pos.x < -half or pos.x > W + half or pos.y < -half or pos.y > H + half then
            finish()
            return
        end
    elseif state == "caught" then
        seq = SEQ.cry
        if fly:IsShown() then
            fly.t = fly.t + dt
            local k = math.min(1, fly.t / FLY_T)
            fly:ClearAllPoints()
            fly:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
                fly.fx + (target.x - fly.fx) * k, fly.fy + (target.y - fly.fy) * k)
            if k >= 1 then
                fly:Hide()
                cover:Hide()
            end
        end
        if t.phase >= CRY_T then
            body:SetAlpha(math.max(0, 1 - (t.phase - CRY_T) / FADE_T))
        end
        if t.phase >= CRY_T + FADE_T then
            body:Hide()
            fly:Hide()
            cover:Hide()
            target = nil
            state = "caged"
            M.SyncCage()
            reopen()
            return
        end
    end
    if body.model then drive(body.model, dt, seq, facing, "body") end
    place()
end
function M.Release(x, y)
    if state ~= "caged" then return end
    if InCombatLockdown() then
        ns.Sfx.Ui("deny")
        return
    end
    local fromCage = not x
    if fromCage then
        if not cage then return end
        x, y = uiPoint(cage)
        if not x then return end
    end
    ensureBody()
    if not body.model then return end
    state = "out"
    t.phase, t.tire, t.idle, t.loose, t.step, t.dash = 0, 0, 0, 0, 0, 0
    pos.x, pos.y, pos.vx, pos.vy = x, y, 0, -1
    target, away = nil, nil
    body:SetAlpha(1)
    body.hand:Hide()
    body:Show()
    place()
    M.SyncCage()
    play(SND_OUT)
    if fromCage and ns.window then ns.window:Close() end
end
function M.Catch(force)
    if state ~= "flee" and state ~= "escape" and state ~= "run" and state ~= "yank" then return end
    if not force and (state == "flee" or state == "escape") and (t.near or 0) < CATCH_MIN then return end
    play(SND_CAUGHT)
    say("murSayCaught")
    if cover:IsShown() and target then
        fly.icon:SetTexture(body.hand.icon:GetTexture())
        fly.fx, fly.fy, fly.t = pos.x + HAND_DX, pos.y + HAND_DY, 0
        fly:ClearAllPoints()
        fly:SetPoint("CENTER", UIParent, "BOTTOMLEFT", fly.fx, fly.fy)
        fly:Show()
    else
        cover:Hide()
    end
    body.hand:Hide()
    state = "caught"
    t.phase = 0
    pos.vx, pos.vy = 0, 0
end
function M.Abort()
    if state == "caged" or state == "gone" then return end
    if body then
        body:Hide()
        body.hand:Hide()
    end
    if cover then cover:Hide() end
    if fly then fly:Hide() end
    target = nil
    state = "caged"
    M.SyncCage()
end
local events = CreateFrame("Frame", nil, UIParent)
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:SetScript("OnEvent", function(_, event, slot)
    if event == "PLAYER_REGEN_DISABLED" then
        M.Abort()
    elseif target and state ~= "caught" and (slot == 0 or slot == target.slot) then
        M.Abort()
    end
end)
