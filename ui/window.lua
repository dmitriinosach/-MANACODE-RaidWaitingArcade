local ADDON, ns = ...
local CANVAS_W, CANVAS_H = 640, 480
local canvasW, canvasH = CANVAS_W, CANVAS_H
local GAP = ns.Space.gap
local ROW = ns.Space.row
local HEAD_H = 50
local MINI_HEAD_H = 26
local MINI_SCALE = 70
local miniOn, miniWant = false, false
local function headH()
    return miniOn and MINI_HEAD_H or HEAD_H
end
local W, H = CANVAS_W, CANVAS_H
local SEE_A = 0.5
local BAR_ROW_H = 26
local SCORE_LANE, CLOCK_LANE = 96, 52
local Window = {}
ns.window = Window
local function frameInsets()
    local ins = ns.CurrentTheme().window.backdrop.insets
    W = canvasW + ins.left + ins.right
    H = ins.top + headH() + canvasH + ins.bottom
    return ins
end
local frame, canvas, head, bar
local barShown = false
local headForm
local cur, curDef, curOpts
local over = false
local finale = false
local finaleUI
local finaleCard
local brinked = false
local brinkWhy
local hideFinale
local moves
local seed
local elapsed = 0
local headThrottle = 0
local icons = {}
local function paintIcon(b)
    local th = ns.ButtonSkin()
    b:SetBackdrop(th.backdrop)
    b:SetBackdropColor(th.bg[1], th.bg[2], th.bg[3], th.bg[4])
    b:SetBackdropBorderColor(th.border[1], th.border[2], th.border[3], th.border[4])
end
local function makeIcon(h)
    local b = CreateFrame("Button", nil, h)
    b:SetWidth(24); b:SetHeight(24)
    paintIcon(b)
    icons[#icons + 1] = b
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(16); b.icon:SetHeight(16)
    b.icon:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    b:SetScript("OnLeave", ns.TipHide)
    b:SetScript("OnMouseDown", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER", self, "CENTER", 1, -1)
    end)
    b:SetScript("OnMouseUp", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER", self, "CENTER", 0, 0)
    end)
    b:SetScript("OnClick", function(self, button)
        ns.Sfx.Ui(self.clickSfx)
        if self.onClick then self.onClick(self, button) end
    end)
    return b
end
local GLYPH_TEX = "Interface\\Buttons\\WHITE8X8"
local GLYPH_C = { 1, 0.82, 0 }
local function glyphBar(b, w, h, x, y)
    local t = b:CreateTexture(nil, "OVERLAY")
    t:SetTexture(GLYPH_TEX)
    t:SetVertexColor(GLYPH_C[1], GLYPH_C[2], GLYPH_C[3])
    t:SetWidth(w); t:SetHeight(h)
    t:SetPoint("TOPLEFT", b.icon, "TOPLEFT", x, -y)
    return t
end
local function glyphFrame(b, x, y, w, h, top)
    glyphBar(b, w, top, x, y)
    glyphBar(b, w, 1, x, y + h - 1)
    glyphBar(b, 1, h, x, y)
    glyphBar(b, 1, h, x + w - 1, y)
end
local function glyphIcon(b, small)
    b.icon:SetTexture(nil)
    if small then
        glyphFrame(b, 1, 2, 14, 12, 1)
        glyphBar(b, 7, 6, 7, 7)
    else
        glyphFrame(b, 1, 2, 14, 12, 3)
    end
end
local function fitButton(b, text)
    b:SetText(text)
    b:SetWidth(math.max(72, (b.text:GetStringWidth() or 0) + 22))
end
local function syncPrefsBack(h)
    local on = ns.PrefsUI and ns.PrefsUI.IsShown()
    if cur then
        if on then
            h.prefs:Hide()
            fitButton(h.prefsBack, ns.T("setBackGame"))
            h.prefsBack:Show()
        else
            h.prefsBack:Hide()
            h.prefs:Show()
        end
    else
        h.prefsBack:Hide()
        fitButton(h.menuPrefs, ns.T(on and "cfgBack" or "prefsOpen"))
        h.menuPrefs.tip = on and nil or ns.T("prefsOpenTip")
    end
end
local function headTexts(h)
    h.note:SetText(ns.T("headHint"))
    h.menu:SetText(ns.T("btnMenu"))
    h.menu.tip = ns.T("tipMenu")
    h.again.tipTitle = ns.T("btnAgain")
    h.again.tip = ns.T("tipAgain")
    h.help:SetCaption(ns.T("btnHowTo"))
    h.help.tip = ns.T("tipHelp")
    h.prefs.tipTitle = ns.T("prefsOpen")
    h.prefs.tip = ns.T("prefsOpenTip")
    h.mini.tipTitle = ns.T("btnMini")
    h.mini.tip = ns.T("tipMini")
    h.keys.tipTitle = ns.T("btnKeys")
    h.keys.tip = ns.T("tipKeys")
    h.top.tipTitle = ns.T("btnRecords")
    h.top.tip = ns.T("tipRecords")
    syncPrefsBack(h)
    h.sound.box.tipTitle = ns.T("lblSound")
    h.musicNext.tipTitle = ns.T("btnMusicNext")
    h.musicNext.tip = ns.T("tipMusicNext")
end
local MATE_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local MATE_FREE = "INV_Misc_GroupLooking"
local MATE_COL = {
    live = { 0.44, 0.75, 0.36 }, duo = { 0.44, 0.75, 0.36 },
    combat = { 0.79, 0.64, 0.15 }, away = { 0.79, 0.64, 0.15 },
    gone = { 0.48, 0.45, 0.39 },
}
local MATE_KEY = {
    live = "pairLive", combat = "pairCombat", away = "pairAway",
    duo = "pairInGame", gone = "pairOffline",
}
local function duoList()
    local defs = {}
    for _, def in pairs(ns.games) do
        if def.duo == "turns" then defs[#defs + 1] = def end
    end
    table.sort(defs, function(a, b) return (a.order or 99) < (b.order or 99) end)
    local names = {}
    for i = 1, #defs do names[i] = ns.TL(defs[i].label) or defs[i].id end
    return "\n- " .. table.concat(names, "\n- ")
end
local function syncMate(h)
    local m = h.mate
    local mate = ns.Pair.Mate()
    local icon = m.cell.icon
    if not mate then
        icon:SetTexture(ns.IconPath(MATE_FREE))
        ns.CropIcon(icon)
        m.dot:Hide()
        m.name:SetText(ns.T("pairShort"))
        m.cell.tipTitle = ns.T("pairCall")
        m.cell.tipColor = { 1, 0.82, 0 }
        m.cell.tipBodyColor = { 1, 1, 1 }
        m.cell.tip = ns.T("pairCallTip", duoList())
        h.mateX:Hide()
    else
        local cls = ns.Pair.Class()
        local tc = cls and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
        if tc then
            icon:SetTexture(MATE_TEX)
            icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        else
            icon:SetTexture(ns.IconPath(MATE_FREE))
            ns.CropIcon(icon)
        end
        m.name:SetText(mate)
        m.cell.tipTitle = mate
        m.cell.tipColor, m.cell.tipBodyColor = nil, nil
        if ns.Pair.Waiting() then
            m.dot:Hide()
            m.cell.tip = ns.T("pairAsking")
            h.mateX.tipTitle = ns.T("duoCancel")
            h.mateX.tip = ns.T("pairCancelTip")
        else
            local where = ns.Pair.Where() or "gone"
            local c = MATE_COL[where] or MATE_COL.gone
            m.dot:SetTexture(c[1], c[2], c[3], 1)
            m.dot:Show()
            if ns.Duo.Held() then
                local at = ns.Duo.HeldAt()
                m.cell.tipTitle = mate .. ": " .. ns.T("pairHeld", at and math.floor((time() - at) / 60) or 0)
                m.cell.tip = ns.T("pairHeldTip")
            else
                m.cell.tipTitle = mate .. ": " .. ns.T(MATE_KEY[where] or "pairOffline")
                m.cell.tip = ns.T("pairPingTip")
            end
            h.mateX.tipTitle = ns.T("pairBreak")
            h.mateX.tip = ns.T("pairBreakTip")
        end
        h.mateX:Show()
    end
    m:SetWidth(24 + 4 + (m.name:GetStringWidth() or 0))
end
local function buildHead(parent)
    local h = CreateFrame("Frame", nil, parent)
    h:SetHeight(HEAD_H)
    h.title = ns.TitleText(h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    h.title:SetPoint("LEFT", h, "LEFT", 0, 0)
    h.note = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h.note:SetPoint("LEFT", h.title, "RIGHT", GAP, 0)
    h.menu = ns.MakeKitButton(h)
    h.menu:SetWidth(82); h.menu:SetHeight(24)
    h.menu.onClick = function() Window:ToMenu() end
    local foot = parent.devFoot
    if ns.Dev then
        h.brink = ns.MakeKitButton(foot)
        h.brink:SetWidth(58)
        h.brink:SetHeight(24)
        h.brink:SetText(ns.Dev.LABEL)
        h.brink:SetPoint("LEFT", foot, "LEFT", 8, 0)
        h.brink.tip = ns.Dev.TIP
        h.brink.onClick = function() Window:Brink() end
        h.brink:Hide()
    end
    if ns.DevStage then
        h.stage = ns.MakeKitButton(foot)
        h.stage:SetWidth(46)
        h.stage:SetHeight(24)
        h.stage:SetPoint("LEFT", foot, "LEFT", 8 + 58 + 6, 0)
        h.stage:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        h.stage.tip = ns.DevStage.TIP
        h.stage.tipDim = ns.DevStage.TIPDIM
        h.stage.onClick = function(_, button)
            local step = IsShiftKeyDown() and 5 or 1
            if button == "RightButton" then step = -step end
            ns.DevStage.Set(ns.DevStage.Get() + step)
            Window:JumpToStage()
        end
        h.stage:Hide()
    end
    h.again = makeIcon(h)
    h.again.icon:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Undo")
    h.again.onClick = function() Window:Restart() end
    h.again:Hide()
    h.pause = makeIcon(h)
    h.pause.icon:SetTexture(ns.IconPath("Spell_Nature_TimeStop"))
    ns.CropIcon(h.pause.icon)
    h.pause.onClick = function(self)
        if ns.Loop.IsPaused() then
            ns.Loop.Resume()
        else
            ns.Loop.Pause(ns.T("pauseSelf"))
        end
        Window:RefreshHead()
        ns.TipShow(self)
    end
    h.pause:Hide()
    h.help = ns.MakeHelpButton(h)
    h.help:SetPoint("LEFT", h.title, "RIGHT", GAP, 0)
    h.help.onClick = function() Window:ShowHelp() end
    h.help:Hide()
    h.prefs = makeIcon(h)
    h.prefs.icon:SetTexture(ns.IconPath("INV_Misc_Gear_01"))
    ns.CropIcon(h.prefs.icon)
    h.prefs.clickSfx = "open"
    h.prefs.onClick = function() if ns.PrefsUI then ns.PrefsUI.Show() end end
    h.prefs:Hide()
    h.prefsBack = ns.MakeKitButton(h)
    h.prefsBack:SetHeight(24)
    h.prefsBack.onClick = function() if ns.PrefsUI then ns.PrefsUI.Back() end end
    h.prefsBack:Hide()
    h.mini = makeIcon(h)
    glyphIcon(h.mini, true)
    h.mini.onClick = function() Window:SetMini(true) end
    h.mini:Hide()
    h.keys = makeIcon(h)
    h.keys.icon:SetTexture(ns.IconPath("INV_Misc_Key_11"))
    ns.CropIcon(h.keys.icon)
    h.keys.clickSfx = "open"
    h.keys.onClick = function() Window:ShowControls() end
    h.keys:Hide()
    h.top = ns.MakeCell(h)
    h.top:SetWidth(24); h.top:SetHeight(24)
    ns.StyleCell(h.top, "framed")
    h.top.icon:SetTexture(ns.Records.Icon("trophy"))
    h.top.onClick = function() Window:ShowRecords() end
    h.top:Hide()
    h.menuPrefs = ns.MakeKitButton(h)
    h.menuPrefs:SetWidth(100); h.menuPrefs:SetHeight(24)
    h.menuPrefs.onClick = function()
        if not ns.PrefsUI then return end
        if ns.PrefsUI.IsShown() then ns.PrefsUI.Back() else ns.PrefsUI.Show() end
    end
    h.music = makeIcon(h)
    h.music.icon:SetTexture(ns.IconPath("INV_Misc_Drum_02"))
    ns.CropIcon(h.music.icon)
    h.music:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    h.music.onClick = function(self, button)
        if button == "RightButton" then
            if not ns.Music.NextShelf() then return end
        else
            ns.Music.SetOn(not ns.Music.On())
        end
        Window:RefreshHead()
        ns.TipShow(self)
    end
    h.musicNext = makeIcon(h)
    h.musicNext.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    h.musicNext.clickSfx = "tick"
    h.musicNext.onClick = function(self)
        ns.Music.Skip()
        Window:RefreshHead()
        ns.TipShow(self)
    end
    h.musicNext:Hide()
    h.sound = CreateFrame("Frame", nil, h)
    h.sound:SetHeight(24); h.sound:SetWidth(24)
    h.sound.box = ns.MakeCheck(h.sound)
    h.sound.box:SetPoint("LEFT", h.sound, "LEFT", 0, 0)
    h.sound.box.onToggle = function(on)
        ns.Store.SetSound(on)
        Window:RefreshHead()
        if ns.PrefsUI and ns.PrefsUI.IsShown() then ns.PrefsUI.Refresh() end
    end
    h.hideDone = CreateFrame("Frame", nil, h)
    h.hideDone:SetHeight(24); h.hideDone:SetWidth(24)
    h.hideDone.box = ns.MakeCheck(h.hideDone)
    h.hideDone.box:SetPoint("LEFT", h.hideDone, "LEFT", 0, 0)
    h.hideDone.box.onToggle = function(on)
        ns.Store.SetHideDone(on)
        if ns.menu then ns.menu:Refresh() end
    end
    h.hideDone:Hide()
    h.mate = CreateFrame("Frame", nil, h)
    h.mate:SetHeight(24); h.mate:SetWidth(24)
    h.mate.cell = ns.MakeCell(h.mate)
    h.mate.cell:SetWidth(24); h.mate.cell:SetHeight(24)
    h.mate.cell:SetPoint("LEFT", h.mate, "LEFT", 0, 0)
    ns.StyleCell(h.mate.cell, "framed")
    h.mate.cell.onClick = function()
        if ns.Pair.Waiting() then return end
        if ns.Pair.Bound() then
            ns.Link.Ask(ns.Pair.Mate())
            return
        end
        ns.CallPanel.Show(Window:Frame(), {
            pair = true, title = ns.T("pairCall"), autoHide = true,
        })
    end
    h.mate.dot = h.mate.cell.over:CreateTexture(nil, "OVERLAY")
    h.mate.dot:SetWidth(7); h.mate.dot:SetHeight(7)
    h.mate.dot:SetPoint("BOTTOMRIGHT", h.mate.cell, "BOTTOMRIGHT", -1, 1)
    h.mate.name = ns.TitleText(h.mate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    h.mate.name:SetPoint("LEFT", h.mate.cell, "RIGHT", 4, 0)
    h.mateX = makeIcon(h)
    h.mateX.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    h.mateX.onClick = function()
        if ns.Pair.Waiting() then ns.Pair.Cancel() else ns.Pair.Break() end
    end
    h.mateX:Hide()
    headTexts(h)
    return h
end
local soundLabel
local function syncSound(h)
    local c = h.sound.box
    c:SetChecked(ns.Store.Sound())
    local text = ns.T("lblSound")
    if soundLabel ~= text then
        soundLabel = text
        c.label:SetText(text)
        c.tipTitle = text
        c.tip = ns.T("tipSound")
        h.sound:SetWidth(24 + 2 + (c.label:GetStringWidth() or 0))
    end
end
local function syncMusic(h)
    local on = ns.Music.On()
    local live = ns.Music.Live()
    local key = ns.Music.Pick()
    local shelf = key and ns.Music.ShelfLabel(key)
    h.music.icon:SetVertexColor(live and 1 or 0.45, live and 1 or 0.45, live and 1 or 0.45)
    h.music.tipTitle = ns.T("lblMusic")
    local now = live and ns.Music.Playing()
    if not shelf then
        h.music.tip = ns.T("tipMusicEmpty")
    elseif on and not ns.Store.Sound() then
        h.music.tip = ns.T("tipMusicMute", shelf)
    elseif on then
        h.music.tip = ns.T("tipMusicOn", shelf)
    else
        h.music.tip = ns.T("tipMusicOff", shelf)
    end
    h.music.tipDim = now and ns.Music.Label(now) or nil
    if live and shelf then h.musicNext:Show() else h.musicNext:Hide() end
end
local function syncPause(h)
    local b = h.pause
    if ns.Loop.IsPaused() then
        b.icon:SetVertexColor(1, 0.82, 0)
        b.tipTitle = ns.T("pauseTitle")
        b.tip = ns.T("tipPauseOn")
    else
        b.icon:SetVertexColor(0.7, 0.7, 0.7)
        b.tipTitle = ns.T("btnPause")
        b.tip = ns.T("tipPauseOff")
    end
    b.tipDim = ns.Keys.PauseText()
    if ns.PauseUI then ns.PauseUI.Sync() end
end
local doneLabel
local function syncHideDone(h)
    local c = h.hideDone.box
    c:SetChecked(ns.Store.HideDone())
    local text = ns.T("lblHideDone")
    if doneLabel ~= text then
        doneLabel = text
        c.label:SetText(text)
        c.tipTitle = text
        c.tip = ns.T("tipHideDone")
        h.hideDone:SetWidth(24 + 2 + (c.label:GetStringWidth() or 0))
    end
end
local function placeNote(h, used)
    local avail = h:GetWidth() or 0
    if avail <= 0 or h.noteOff then return end
    local free = avail - used - (h.title:GetStringWidth() or 0) - GAP
    if free >= (h.note:GetStringWidth() or 0) then
        h.note:Show()
    else
        h.note:Hide()
    end
end
local function placeHead()
    local h = head
    local right
    local used = 0
    local function put(f, gap)
        if not f:IsShown() then return end
        f:ClearAllPoints()
        if right then
            f:SetPoint("RIGHT", right, "LEFT", -(gap or ROW), 0)
            used = used + (gap or ROW)
        else
            f:SetPoint("RIGHT", h, "RIGHT", 0, 0)
        end
        used = used + (f:GetWidth() or 0)
        right = f
    end
    put(h.mini)
    put(h.menu)
    put(h.menuPrefs)
    put(h.sound, GAP)
    put(h.music, GAP)
    put(h.musicNext)
    put(h.hideDone, GAP)
    put(h.again, GAP)
    put(h.pause)
    put(h.top)
    put(h.prefs)
    put(h.prefsBack)
    put(h.keys)
    put(h.mateX, GAP)
    put(h.mate, 4)
    placeNote(h, used)
end
local function buildBar(parent)
    local b = CreateFrame("Frame", nil, parent)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    b:SetHeight(BAR_ROW_H + 4)
    b:SetFrameLevel(parent:GetFrameLevel() + 40)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetTexture(0, 0, 0, 0.55)
    b.coin = b:CreateTexture(nil, "ARTWORK")
    b.coin:SetWidth(14); b.coin:SetHeight(14)
    ns.CropIcon(b.coin)
    b.coin:SetPoint("TOPLEFT", b, "TOPLEFT", 12, -8)
    b.score = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.score:SetJustifyH("LEFT")
    b.score:SetPoint("TOPLEFT", b, "TOPLEFT", 30, -9)
    b.clockBox = CreateFrame("Frame", nil, b)
    b.clockBox:SetWidth(CLOCK_LANE); b.clockBox:SetHeight(BAR_ROW_H)
    b.clockBox:SetPoint("TOPLEFT", b, "TOPLEFT", 30 + SCORE_LANE, 0)
    b.clockBox:EnableMouse(true)
    b.clockBox:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    b.clockBox:SetScript("OnLeave", ns.TipHide)
    b.clock = b.clockBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.clock:SetPoint("LEFT", b.clockBox, "LEFT", 0, 0)
    b.duo = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.duo:SetPoint("LEFT", b.clockBox, "RIGHT", GAP, 0)
    b:Hide()
    return b
end
local function layoutBody()
    if not frame then return end
    local ins = frameInsets()
    frame:SetSize(W, H)
    if frame.body then
        frame.body:ClearAllPoints()
        if ns.CurrentTheme().window.full then
            frame.body:SetAllPoints(frame)
        else
            frame.body:SetPoint("TOPLEFT", frame, "TOPLEFT", ins.left, -ins.top)
            frame.body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ins.right, ins.bottom)
        end
    end
    if frame.plate then
        frame.plate:ClearAllPoints()
        frame.plate:SetPoint("TOPLEFT", frame, "TOPLEFT", ins.left, -ins.top)
        frame.plate:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -ins.right, -(ins.top + headH()))
    end
    if head then
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", frame, "TOPLEFT", ins.left + 11, -ins.top)
        head:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(ins.right + 42), -ins.top)
    end
    if head then
        if miniOn then head:Hide() else head:Show() end
    end
    if frame.miniStrip then
        local st = frame.miniStrip
        st:ClearAllPoints()
        st:SetPoint("TOPLEFT", frame, "TOPLEFT", ins.left + 6, -ins.top)
        st:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(ins.right + 28), -ins.top)
        if miniOn then st:Show() else st:Hide() end
    end
    if frame.close then
        local k = miniOn and 0.75 or 1
        frame.close:SetScale(k)
        frame.close:ClearAllPoints()
        frame.close:SetPoint("CENTER", frame, "TOPRIGHT",
            -(ins.right + (miniOn and 14 or 20)) / k, -(ins.top + headH() / 2) / k)
    end
    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT", frame, "TOPLEFT", ins.left, -(ins.top + headH()))
    if frame.board then
        frame.board:ClearAllPoints()
        frame.board:SetAllPoints(canvas)
    end
end
local SCALE_MIN = 0.5
local function scaleMax()
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    if not sw or sw <= 0 or not sh or sh <= 0 then return 1 end
    return math.max(1, math.min(sw / W, sh / H))
end
local function clampScale(s)
    if s < SCALE_MIN then return SCALE_MIN end
    local top = scaleMax()
    if s > top then return top end
    return s
end
local function scaleValue()
    local key
    if miniOn then
        key = ns.Store.DB().uiScaleMini or MINI_SCALE
    else
        key = ns.Store.Scale and ns.Store.Scale() or 100
    end
    if key == "full" then return scaleMax() end
    local n = tonumber(key)
    if n then return clampScale(n / 100) end
    return 1
end
function Window:ScaleRange()
    return math.floor(SCALE_MIN * 100 + 0.5), math.floor(scaleMax() * 100)
end
local function anchorTopLeft(L, T, s)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", L / s, T / s)
end
local function savePos()
    local p, _, rp, x, y = frame:GetPoint()
    ns.Store.DB()[miniOn and "miniPos" or "pos"] = { p = p, rp = rp, x = x, y = y }
end
function Window:ApplyScale()
    if not frame then return end
    local s = scaleValue()
    local old = frame:GetScale()
    local L, T = frame:GetLeft(), frame:GetTop()
    frame:SetScale(s)
    if L and T and old ~= s and frame:IsShown() then
        anchorTopLeft(L * old, T * old, s)
        savePos()
    end
end
local GRIP_TEX = "Interface\\AddOns\\HTP_Arcade\\art\\grip"
local GRIP_CURSOR = "Interface\\AddOns\\HTP_Arcade\\art\\grip_cursor"
local GRIP_BLANK = "Interface\\AddOns\\HTP_Arcade\\art\\blank"
local GRIP_GOLD = { 1.00, 0.80, 0.30 }
local GRIP_LIT = { 1.00, 0.93, 0.62 }
local GRIP_PRESS = { 0.78, 0.58, 0.18 }
local function gripTint(g, c)
    g.tex:SetVertexColor(c[1], c[2], c[3])
end
local function buildGrip()
    local g = CreateFrame("Button", nil, frame)
    g:SetSize(22, 22)
    g:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    g:SetFrameStrata("FULLSCREEN")
    g.tex = g:CreateTexture(nil, "ARTWORK")
    g.tex:SetTexture(GRIP_TEX)
    g.tex:SetAllPoints(g)
    gripTint(g, GRIP_GOLD)
    local hi = g:CreateTexture(nil, "HIGHLIGHT")
    hi:SetTexture(GRIP_TEX)
    hi:SetAllPoints(g)
    hi:SetBlendMode("ADD")
    hi:SetVertexColor(GRIP_LIT[1], GRIP_LIT[2], GRIP_LIT[3])
    hi:SetAlpha(0.35)
    local badge = CreateFrame("Frame", nil, UIParent)
    badge:SetFrameStrata("TOOLTIP")
    badge:SetSize(24, 24)
    badge:Hide()
    local arrow = badge:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture(GRIP_CURSOR)
    arrow:SetTexCoord(0, 0.78125, 0, 0.78125)
    arrow:SetAllPoints(badge)
    badge:SetScript("OnUpdate", function(self)
        local u = UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / u, y / u)
        SetCursor(GRIP_BLANK)
    end)
    badge:SetScript("OnHide", function() ResetCursor() end)
    local drag
    g:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local s = frame:GetScale()
        local u = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        drag = { s = s, L = frame:GetLeft() * s, T = frame:GetTop() * s,
                 x = cx / u, y = cy / u }
        gripTint(self, GRIP_PRESS)
        self:SetScript("OnUpdate", function()
            local u2 = UIParent:GetEffectiveScale()
            local x, y = GetCursorPosition()
            x, y = x / u2, y / u2
            local d = ((x - drag.x) / W + (drag.y - y) / H) / 2
            local sc = clampScale(drag.s + d)
            if math.abs(sc - frame:GetScale()) < 0.001 then return end
            frame:SetScale(sc)
            anchorTopLeft(drag.L, drag.T, sc)
        end)
    end)
    g:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
        local over = self:IsMouseOver()
        gripTint(self, over and GRIP_LIT or GRIP_GOLD)
        if not over then badge:Hide() end
        if not drag then return end
        drag = nil
        local pct = math.floor(frame:GetScale() * 100 + 0.5)
        ns.Store.DB()[miniOn and "uiScaleMini" or "uiScale"] = pct
        Window:ApplyScale()
        savePos()
        if ns.PrefsUI and ns.PrefsUI.IsShown() then ns.PrefsUI.Refresh() end
    end)
    g:SetScript("OnEnter", function(self)
        badge:Show()
        if not drag then gripTint(self, GRIP_LIT) end
    end)
    g:SetScript("OnLeave", function(self)
        if drag then return end
        gripTint(self, GRIP_GOLD)
        badge:Hide()
    end)
    g:SetScript("OnHide", function(self)
        if drag then self:GetScript("OnMouseUp")(self) end
        badge:Hide()
    end)
    return g
end
local function setCanvasSize(w, h)
    w, h = w or CANVAS_W, h or CANVAS_H
    if w == canvasW and h == canvasH then return end
    canvasW, canvasH = w, h
    canvas:SetSize(w, h)
    canvas.W, canvas.H = w, h
    layoutBody()
    Window:ApplyScale()
end
local function canvasPoint(self)
    local x, y = GetCursorPosition()
    local scale = self:GetEffectiveScale()
    return x / scale - self:GetLeft(), y / scale - self:GetBottom()
end
local function paint()
    if not frame then return end
    local th = ns.CurrentTheme()
    frame:SetBackdrop(th.window.backdrop)
    frame:SetBackdropColor(unpack(th.window.bg))
    frame:SetBackdropBorderColor(unpack(th.window.border))
    layoutBody()
    Window:ApplyScale()
    for i = 1, #icons do paintIcon(icons[i]) end
    Window:RefreshCanvasBg()
end
ns.OnTheme(paint)
ns.OnLocale(function()
    if not head then return end
    headTexts(head)
    headForm = nil
    Window:RefreshHead()
    Window:SyncBar()
    if cur then ns.SafeCall(cur, "Relocalize") end
end)
local function build()
    frame = CreateFrame("Frame", "HTP_ArcadeFrame", UIParent)
    frame:SetSize(W, H)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePos()
    end)
    tinsert(UISpecialFrames, "HTP_ArcadeFrame")
    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.grip = buildGrip()
    frame.devFoot = CreateFrame("Frame", nil, frame)
    frame.devFoot:SetHeight(32)
    frame.devFoot:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
    frame.devFoot:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
    frame.devFoot:SetFrameLevel(frame:GetFrameLevel() + 60)
    frame.devFoot.bg = frame.devFoot:CreateTexture(nil, "BACKGROUND")
    frame.devFoot.bg:SetAllPoints()
    frame.devFoot.bg:SetTexture(0, 0, 0, 0.8)
    frame.devFoot:Hide()
    frame.miniStrip = CreateFrame("Frame", nil, frame)
    frame.miniStrip:SetHeight(MINI_HEAD_H)
    frame.miniStrip:Hide()
    do
        local st = frame.miniStrip
        st.back = makeIcon(st)
        st.back:SetWidth(20); st.back:SetHeight(20)
        glyphIcon(st.back, false)
        st.back:SetPoint("RIGHT", st, "RIGHT", 0, 0)
        st.back.onClick = function() Window:SetMini(false) end
        st.clock = st:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        st.clock:SetPoint("RIGHT", st.back, "LEFT", -8, 0)
        st.note = st:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        st.note:SetPoint("RIGHT", st.clock, "LEFT", -10, 0)
        st.note:SetJustifyH("RIGHT")
        st.title = ns.TitleText(st:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        st.title:SetPoint("LEFT", st, "LEFT", 0, 0)
        st.title:SetPoint("RIGHT", st.note, "LEFT", -6, 0)
        st.title:SetJustifyH("LEFT")
    end
    frame.body = frame:CreateTexture(nil, "BORDER")
    frame.plate = frame:CreateTexture(nil, "ARTWORK")
    frame.board = frame:CreateTexture(nil, "ARTWORK")
    head = buildHead(frame)
    ns.SlideAnchor("shell.mate", head.mate)
    ns.SlideAnchor("shell.prefs", head.menuPrefs)
    ns.SlideAnchor("shell.grip", frame.grip)
    canvas = CreateFrame("Frame", "HTP_ArcadeCanvas", frame)
    canvas:SetSize(CANVAS_W, CANVAS_H)
    canvas.W, canvas.H = CANVAS_W, CANVAS_H
    bar = buildBar(canvas)
    paint()
    canvas:EnableMouse(true)
    canvas:SetScript("OnMouseDown", function(self, button)
        if not cur then return end
        if ns.Loop.IsPaused() then
            ns.Loop.Resume()
            Window:RefreshHead()
            return
        end
        if not ns.Duo.MyTurn() then return end
        if not ns.Keys.MouseOn(curDef and curDef.id) then return end
        local x, y = canvasPoint(self)
        ns.SafeCall(cur, "Click", x, y, button)
    end)
    canvas:SetScript("OnMouseUp", function(self, button)
        if not cur or not cur.Release then return end
        if ns.Loop.IsPaused() then return end
        if not ns.Duo.MyTurn() then return end
        if not ns.Keys.MouseOn(curDef and curDef.id) then return end
        local x, y = canvasPoint(self)
        ns.SafeCall(cur, "Release", x, y, button)
    end)
    frame:SetScript("OnHide", function()
        ns.Music.Hush()
        ns.Sfx.Release()
        ns.Help.Hide()
    ns.RecordsUI.Hide()
    ns.ControlsUI.Hide()
        ns.SelectClose()
        if over then
            Window:StopGame()
            return
        end
        if cur then
            ns.Loop.Pause(ns.T("pauseWindow"))
            ns.Loop.Stop()
        end
    end)
    local db = ns.Store.DB()
    if db.pos and db.pos.p then
        frame:SetPoint(db.pos.p, UIParent, db.pos.rp, db.pos.x, db.pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    placeHead()
    frame:Hide()
end
local function ensure()
    if not frame then build() end
end
function Window:Canvas()
    ensure()
    return canvas
end
function Window:ScreenFill(parent, layer)
    local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
    tex:SetAllPoints(parent)
    return tex
end
function Window:RefreshCanvasBg()
    if not frame or not frame.body then return end
    local th = ns.CurrentTheme()
    local see = ns.Store.SeeThrough()
    ns.PaintBody(frame.body, th.window.body, see and SEE_A or 1)
    local ins = th.window.backdrop.insets
    local v0, v1
    if th.window.full then
        v0, v1 = ins.top / H, (ins.top + headH()) / H
    else
        v0, v1 = 0, headH() / (H - ins.top - ins.bottom)
    end
    ns.PaintBody(frame.plate, th.window.body, see and SEE_A or 1, v0, v1)
    local look = ns.GameLook()
    if look and look.screen then
        ns.PaintBody(frame.board, { color = look.screen }, see and SEE_A or 1)
    else
        ns.PaintScreen(frame.board, see and SEE_A or 1)
    end
end
function Window:Frame()
    ensure()
    return frame
end
local btnPool, selPool, stepPool, sepPool
local BAR_BTN_H = 20
local BAR_GAP = ns.Space.row
local BAR_GROUP_GAP = BAR_GAP * 3
local BAR_HALF = math.floor((BAR_GROUP_GAP - 1) / 2)
local function barLocked()
    if cur and cur.Locked then
        local ok, v = ns.SafeCall(cur, "Locked")
        if ok then return v and true or false end
    end
    return (moves ~= nil and #moves > 0)
end
local function pickAxis(key, value)
    if not curDef then return end
    if barLocked() then return end
    if ns.Loop.Current() ~= cur then return end
    local was = ns.Records.Normalize(curDef, curOpts)
    if was[key] == value then return end
    local sel = ns.Records.Repick(curDef, curOpts, key, value)
    if curDef.saves then
        Window:StartGame(curDef.id, sel, true)
    else
        ns.Store.Clear(curDef.id)
        Window:StartGame(curDef.id, sel)
    end
end
local function axisKind(axis, list)
    if not list then return "step" end
    if axis.ordered then return "step" end
    return "select"
end
local function axisNote(locked)
    return locked and ns.T("barAxisLocked") or ns.T("barAxisRestart")
end
local function axisItems(locked)
    local axes = ns.Records.Axes(curDef)
    if #axes == 0 then return {} end
    local sel = ns.Records.Normalize(curDef, curOpts)
    local out = {}
    for _, axis in ipairs(axes) do
        local key = axis.key
        local list = ns.Records.Options(axis, sel)
        local it = {
            label = axis.label or key,
            kind = axisKind(axis, list),
            value = sel[key],
            disabled = locked,
            tip = axis.tip,
            tipDim = axisNote(locked),
            options = list,
        }
        if list then
            it.onPick = function(k) pickAxis(key, k) end
        else
            it.min = ns.Records.Bound(axis, "min", sel)
            it.max = ns.Records.Bound(axis, "max", sel)
            it.step, it.big = axis.step, axis.big
            it.format = axis.format
            it.home = ns.Records.Bound(axis, "def", sel)
            it.onSet = function(v) pickAxis(key, v) end
        end
        if ns.Records.AxisOpen(axis, sel) then out[#out + 1] = it end
    end
    return out
end
local function withExtras(items)
    local id = curDef and curDef.id
    if not id then return {} end
    local locked = barLocked()
    local out = axisItems(locked)
    for _, it in ipairs(items or {}) do out[#out + 1] = it end
    if not ns.Shelves then return out end
    local opts = {}
    for _, t in ipairs(ns.Shelves.Themes(id)) do
        if ns.Shelves.Filled(id, t.key) then
            opts[#opts + 1] = { key = t.key, label = ns.TL(t.label) }
        end
    end
    if #opts < 2 then return out end
    out[#out + 1] = {
        label = ns.T("barTheme"), kind = "select",
        value = ns.Shelves.Theme(id), options = opts, disabled = locked,
        gap = true,
        tip = ns.T("barThemeTip"),
        tipDim = axisNote(locked),
        onPick = function(key)
            ns.Shelves.SetTheme(id, key)
            ns.window:StartGame(id, curOpts)
        end,
    }
    return out
end
local barItems
local function resolveItems(items)
    local out = {}
    for i, it in ipairs(items or {}) do
        local c = {}
        for k, v in pairs(it) do c[k] = v end
        c.label = ns.TL(c.label)
        c.tip = ns.TL(c.tip)
        c.tipTitle = ns.TL(c.tipTitle)
        c.tipDim = ns.TL(c.tipDim)
        c.tipLess = ns.TL(c.tipLess)
        c.tipMore = ns.TL(c.tipMore)
        c.format = ns.TL(c.format)
        if it.options then
            local opts = {}
            for j, o in ipairs(it.options) do
                local oc = {}
                for k, v in pairs(o) do oc[k] = v end
                oc.label = ns.TL(oc.label)
                oc.tip = ns.TL(oc.tip)
                opts[j] = oc
            end
            c.options = opts
        end
        out[i] = c
    end
    return out
end
local function rebuildBar()
    ensure()
    ns.SelectClose()
    if curDef and curDef.ownPanel then
        bar:Hide()
        if btnPool then btnPool:Reset(); btnPool:HideExtras() end
        if selPool then selPool:Reset(); selPool:HideExtras() end
        if stepPool then stepPool:Reset(); stepPool:HideExtras() end
        if sepPool then sepPool:Reset(); sepPool:HideExtras() end
        return
    end
    local items = withExtras(barItems)
    btnPool = btnPool or ns.NewPool(function()
        local b = ns.MakeKitButton(bar)
        b:SetHeight(BAR_BTN_H)
        return b
    end)
    selPool = selPool or ns.NewPool(function()
        local s = ns.MakeSelect(bar)
        s:SetHeight(BAR_BTN_H)
        return s
    end)
    stepPool = stepPool or ns.NewPool(function()
        local s = ns.MakeStepper(bar)
        s:SetHeight(BAR_BTN_H)
        return s
    end)
    sepPool = sepPool or ns.NewPool(function()
        local s = CreateFrame("Frame", nil, bar)
        s:SetWidth(1); s:SetHeight(BAR_BTN_H - 4)
        s.line = s:CreateTexture(nil, "ARTWORK")
        s.line:SetAllPoints()
        return s
    end)
    btnPool:Reset()
    selPool:Reset()
    stepPool:Reset()
    sepPool:Reset()
    if not items or #items == 0 then
        btnPool:HideExtras()
        selPool:HideExtras()
        stepPool:HideExtras()
        sepPool:HideExtras()
        bar:SetHeight(BAR_ROW_H + 4)
        return
    end
    items = resolveItems(items)
    local prevL, prevR
    for _, it in ipairs(items) do
        local f, w
        if it.kind == "select" then
            f = selPool:Acquire()
            f:SetOptions(it.options, it.value, ns.TL(it.label))
            f.onPick = it.onPick
            f.tip = ns.TL(it.tip)
            f.tipTitle = ns.TL(it.tipTitle)
            f.tipDim = ns.TL(it.tipDim)
            w = it.width or f:FitWidth()
        elseif it.kind == "step" then
            f = stepPool:Acquire()
            f:SetSpec(it)
            w = it.width or f:FitWidth()
        else
            f = btnPool:Acquire()
            f:SetText(ns.TL(it.label) or "?")
            f.onClick = it.onClick
            f.tip = ns.TL(it.tip)
            f.tipTitle = ns.TL(it.tipTitle)
            f.tipDim = ns.TL(it.tipDim)
            f.active = it.active and true or false
            w = it.width or math.max(44, f.text:GetStringWidth() + 18)
        end
        f:SetWidth(w)
        if it.disabled then f:Disable() else f:Enable() end
        if f.isStepper then f:Restyle() else ns.StyleButton(f) end
        local sep
        if it.gap and ((it.side == "right" and prevR) or (it.side ~= "right" and prevL)) then
            sep = sepPool:Acquire()
            local rc = ns.CurrentTheme().rule
            sep.line:SetTexture(rc[1], rc[2], rc[3], rc[4])
            sep:ClearAllPoints()
        end
        f:ClearAllPoints()
        if it.side == "right" then
            if sep then
                sep:SetPoint("RIGHT", prevR, "LEFT", -BAR_HALF, 0)
                f:SetPoint("RIGHT", sep, "LEFT", -BAR_HALF, 0)
            elseif prevR then
                f:SetPoint("RIGHT", prevR, "LEFT", -BAR_GAP, 0)
            else
                f:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -12, -4)
            end
            prevR = f
        else
            if sep then
                sep:SetPoint("LEFT", prevL, "RIGHT", BAR_HALF, 0)
                f:SetPoint("LEFT", sep, "RIGHT", BAR_HALF, 0)
            elseif prevL then
                f:SetPoint("LEFT", prevL, "RIGHT", BAR_GAP, 0)
            else
                f:SetPoint("TOPLEFT", bar, "TOPLEFT", 12, -(BAR_ROW_H + 6))
            end
            prevL = f
        end
    end
    btnPool:HideExtras()
    selPool:HideExtras()
    stepPool:HideExtras()
    sepPool:HideExtras()
    bar:SetHeight(prevL and (BAR_ROW_H * 2 + 8) or (BAR_ROW_H + 4))
end
function Window:SetGameBar(items)
    barItems = items
    rebuildBar()
end
function Window:SyncBar()
    rebuildBar()
    if curDef and curDef.ownPanel and cur and cur.PanelSync then
        ns.SafeCall(cur, "PanelSync")
    end
end
function Window:PanelItems()
    if not curDef then return {} end
    return resolveItems(withExtras(barItems))
end
function Window:AxisLocked()
    return barLocked()
end
function Window:Elapsed()
    return elapsed
end
function Window:Open()
    ensure()
    frame:Show()
    ns.Sfx.Duck()
    ns.Music.Resume()
    if cur then
        ns.Loop.Start(cur)
        ns.Loop.Pause(ns.T("pauseWindow"))
    else
        setCanvasSize(nil, nil)
        canvas:Hide()
        ns.menu:Show()
    end
    self:RefreshHead()
    if ns.Toast then ns.Toast.Flush() end
    if not cur and ns.Intro then ns.Intro.Maybe() end
    ns.Link.Shout()
end
function Window:Close()
    ensure()
    frame:Hide()
    ns.Link.Shout()
end
function Window:Toggle()
    ensure()
    if frame:IsShown() then self:Close() else self:Open() end
end
function Window:IsShown()
    return frame and frame:IsShown() and true or false
end
function ns.GameLook()
    return curDef and curDef.look or nil
end
function Window:StartGame(id, opts, resume, forceSeed)
    ensure()
    local def = ns.games[id]
    if not def then
        ns.say("нет такой игры: " .. tostring(id))
        return
    end
    self:StopGame()
    local saved = resume and ns.Store.Load(id, opts) or nil
    seed = forceSeed or (saved and saved.seed) or time()
    moves = {}
    curOpts = opts or (saved and saved.opts) or ns.Store.LastOpts(id)
    curDef = def
    self:RefreshCanvasBg()
    setCanvasSize(def.canvas and def.canvas.w, def.canvas and def.canvas.h)
    if #ns.Records.Axes(def) > 0 then
        curOpts = ns.Records.Normalize(def, curOpts)
    end
    local made, inst = pcall(def.New, canvas)
    if not made then
        ns.MarkBroken(id, "ошибка в New — " .. tostring(inst))
    elseif not ns.CheckGame(inst, id) then
        made = false
    end
    if not made then
        setCanvasSize(nil, nil)
        canvas:Hide()
        ns.menu:Show()
        self:RefreshHead()
        return
    end
    cur = inst
    cur.def = def
    cur.opts = curOpts
    local rawMove = cur.Move
    cur.Move = function(self2, move)
        local how = ns.Duo.Gate()
        if how == "no" then return end
        if rawMove(self2, move) == false then return end
        if not cur.Serialize then
            moves[#moves + 1] = move
            if #moves == 1 then Window:SyncBar() end
        end
        if how == "own" then ns.Duo.Sent(move) end
    end
    if not ns.SafeCall(cur, "Start", seed, saved and saved.moves or nil) then
        cur, curDef, curOpts = nil, nil, nil
        self:RefreshCanvasBg()
        setCanvasSize(nil, nil)
        canvas:Hide()
        ns.menu:Show()
        self:RefreshHead()
        return
    end
    if cur.opts ~= nil then curOpts = cur.opts end
    ns.Store.RememberOpts(id, curOpts)
    if saved and saved.moves then moves = saved.moves end
    elapsed = saved and saved.elapsed or 0
    self:SyncBar()
    ns.menu:Hide()
    canvas:Show()
    ns.Loop.Start(cur)
    if cur.Key then ns.Keys.Bind(def) end
    ns.Keys.PauseKeys(true)
    if ns.DevStage and ns.Dev and ns.Dev.On() and not resume then
        local want = ns.DevStage.Get()
        if want > 1 and cur.Stage and ns.DevStage.Of(def) then
            if ns.SafeCall(cur, "Stage", want) then
                brinked = true
                brinkWhy = ns.DevStage.UNRANKED
                ns.Store.Clear(id, curOpts)
                ns.SafeCall(cur, "Draw")
                self:SyncBar()
            end
        end
    end
    if miniWant and def.mini then self:SetMini(true) end
    self:RefreshHead()
end
function Window:StopGame()
    if miniOn then
        local want = miniWant
        self:SetMini(false)
        miniWant = want
    end
    if cur then
        ns.Duo.Quit("quit")
        over = false
        brinked = false
        brinkWhy = nil
        hideFinale()
        finaleCard = nil
        ns.Over.Hide()
        ns.Keys.Clear()
        ns.Loop.Stop()
        ns.SafeCall(cur, "Stop")
        cur, curDef, curOpts = nil, nil, nil
        self:RefreshCanvasBg()
        moves = nil
        self:SetGameBar(nil)
    end
end
function Window:Restart(newOpts)
    if not cur or not curDef then return end
    local id, opts = curDef.id, newOpts or curOpts
    local started = moves and #moves > 0
    if not started then
        self:StartGame(id, opts)
        return
    end
    StaticPopupDialogs["HTP_ARCADE_RESTART"] = {
        text = ns.T("askRestart"),
        button1 = ns.T("btnAgain"),
        button2 = ns.T("btnCancel"),
        OnAccept = function()
            ns.Store.Clear(id)
            Window:StartGame(id, opts)
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("HTP_ARCADE_RESTART")
end
function Window:CurrentId()
    return curDef and curDef.id or nil
end
function Window:ToMenu()
    self:SaveCurrent()
    self:StopGame()
    miniWant = false
    ns.Help.Hide()
    ns.RecordsUI.Hide()
    ns.ControlsUI.Hide()
    setCanvasSize(nil, nil)
    canvas:Hide()
    ns.menu:Show()
    self:RefreshHead()
end
function Window:Checkpoint(move)
    if not cur or not moves then return end
    moves = { move }
    self:SaveCurrent()
end
function Window:MoveAt(i)
    return moves and moves[i] or nil
end
function Window:SaveCurrent()
    if not cur or not curDef then return end
    if cur:IsOver() then return end
    if brinked then return end
    if curDef.save == false then
        ns.Store.Clear(curDef.id)
        return
    end
    ns.Store.Save(curDef.id, seed,
        cur.Serialize and { cur:Serialize() } or moves, curOpts)
    local rec = ns.Store.Load(curDef.id, curOpts)
    if not rec then return end
    rec.elapsed = elapsed
    if cur.Elapsed then
        local ok, own = ns.SafeCall(cur, "Elapsed")
        if ok and type(own) == "number" then rec.elapsed = own end
    end
end
hideFinale = function()
    finale = false
    if finaleUI then finaleUI:Hide() end
end
local function showFinale()
    if not finaleUI then
        finaleUI = CreateFrame("Frame", nil, canvas)
        finaleUI:SetAllPoints(canvas)
        finaleUI:SetFrameStrata("FULLSCREEN_DIALOG")
        finaleUI:EnableMouse(true)
        finaleUI:SetScript("OnMouseDown", function() Window:EndFinale() end)
        local plate = CreateFrame("Frame", nil, finaleUI)
        plate:SetPoint("BOTTOM", finaleUI, "BOTTOM", 0, 14)
        plate:SetHeight(30)
        plate:SetBackdrop(ns.CARD_BACKDROP)
        plate:SetBackdropColor(0, 0, 0, 0.9)
        finaleUI.text = plate:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        finaleUI.text:SetPoint("CENTER", plate, "CENTER", 0, 0)
        finaleUI.plate = plate
    end
    finaleUI.text:SetText(ns.T("finaleHint"))
    finaleUI.text:SetTextColor(ns.CardEdge(ns.GameLook()))
    finaleUI.plate:SetWidth(finaleUI.text:GetStringWidth() + 36)
    finaleUI:Show()
end
function Window:Brink()
    if not cur or not cur.Brink then return end
    if not ns.SafeCall(cur, "Brink") then return end
    brinked = true
    brinkWhy = ns.Dev and ns.Dev.UNRANKED or nil
    ns.Store.Clear(curDef.id)
    ns.SafeCall(cur, "Draw")
    self:SyncBar()
    self:RefreshHead()
end
function Window:JumpToStage()
    if not cur or not cur.Stage or not curDef then
        return
    end
    local s = ns.DevStage and ns.DevStage.Of(curDef)
    if not s then return end
    local n = ns.DevStage.Get()
    if s.max and n > s.max then
        n = s.max
        ns.DevStage.Set(n)
    end
    local id, opts = curDef.id, curOpts
    self:StartGame(id, opts)
    if not ns.SafeCall(cur, "Stage", n) then return end
    brinked = true
    brinkWhy = ns.DevStage.UNRANKED
    ns.Store.Clear(id, opts)
    ns.SafeCall(cur, "Draw")
    self:SyncBar()
    self:RefreshHead()
end
local function wantsFinale()
    local f = curDef and curDef.finale
    if type(f) == "function" then
        local ok, want = pcall(f, cur)
        return ok and want and true or false
    end
    return f and true or false
end
function Window:Finale()
    if finale then return true end
    if not wantsFinale() then return false end
    self:GameOver()
    return finale
end
function Window:EndFinale()
    if not finale then return end
    hideFinale()
    ns.Loop.Stop()
    local card = finaleCard
    finaleCard = nil
    if card then ns.Over.Show(card) end
end
function Window:GameOver()
    if not cur or not curDef then return end
    local okScore, score = ns.SafeCall(cur, "Score")
    if not okScore then score = 0 end
    local ranked, why = true, nil
    if brinked then
        ranked = false
        why = brinkWhy or (ns.Dev and ns.Dev.UNRANKED) or nil
    elseif cur.Ranked then
        local okRank, r = ns.SafeCall(cur, "Ranked")
        if okRank and r ~= true then
            ranked = false
            if type(r) == "string" then why = r end
        end
    end
    local vals = { score = score, time = elapsed }
    if cur.Marks then
        local okM, extra = ns.SafeCall(cur, "Marks")
        if okM and type(extra) == "table" then
            for k, v in pairs(extra) do vals[k] = v end
        end
    end
    local isBest = ranked and ns.Records.Submit(curDef.id, curOpts, vals) or false
    ns.Store.Clear(curDef.id)
    local id = curDef.id
    local opts = curOpts
    local vs = ns.Duo.Active() and ns.Duo.Peer() or nil
    ns.Duo.Quit("over")
    ns.Keys.Clear()
    ns.Help.Hide()
    ns.RecordsUI.Hide()
    ns.ControlsUI.Hide()
    over = true
    self:RefreshHead()
    local mark = ns.Records.MainFor(curDef, opts)
    local bestRec = ns.Records.Best(id, opts)
    local own = cur.BeginRound ~= nil
    local card = {
        game = (curDef.label or id) .. (vs and ns.T("duoVs", vs) or ""),
        result = (cur.ResultText and cur:ResultText())
            or (ns.Records.Keeps(curDef)
                and ns.T("overResult", ns.TL(mark.label) or "",
                    ns.Records.Format(mark, vals[mark.key])))
            or nil,
        isBest = isBest,
        best = bestRec and ns.T("overRecord", ns.Records.Format(mark, bestRec[mark.key])) or nil,
        unranked = (not ranked) and why or nil,
        onAgain = function()
            Window:StartGame(id, opts)
            if own and cur and cur.BeginRound then
                ns.SafeCall(cur, "BeginRound")
            end
        end,
        onOwn = own and function() Window:StartGame(id, opts) end or nil,
        onMenu = function() Window:ToMenu() end,
    }
    if wantsFinale() then
        finale = true
        finaleCard = card
        showFinale()
        return
    end
    ns.Over.Show(card)
end
function ns.ShowRules(def, opts)
    if not def then return end
    local slides = def.slides
    if type(slides) == "function" then slides = slides(opts) end
    if slides and #slides > 0 then
        ns.Slides.Show(def.label or def.id, slides)
        return
    end
    local body = def.help
    if type(body) == "function" then body = body(opts) end
    ns.Help.Show(def.label or def.id, body or { ns.T("helpNoRules") })
end
function Window:ShowHelp()
    ns.ShowRules(curDef, curOpts)
end
function Window:ShowRecords()
    if not curDef or not ns.RecordsUI then return end
    ns.RecordsUI.Show(curDef.id, curOpts)
end
function Window:ShowControls()
    if not curDef or not ns.ControlsUI then return end
    ns.ControlsUI.Show(curDef.id, cur and cur.Key ~= nil)
end
function Window:Tick(dt)
    if not finale then elapsed = elapsed + dt end
    headThrottle = headThrottle + dt
    if headThrottle < 0.1 then return end
    headThrottle = 0
    self:RefreshHead()
end
local function span(sec)
    local m = math.floor(sec / 60)
    return string.format("%d:%02d", m, math.floor(sec - m * 60))
end
local CLOCK_GRADE = { off = true, soft = true, hard = true }
local function clockGrade()
    local g = curDef and curDef.clock
    if type(g) == "string" and CLOCK_GRADE[g] then return g end
    if cur and cur.Clock then return "hard" end
    return "soft"
end
local function setClock(text, warn, paused, grade)
    if not text or grade == "off" then
        bar.clock:SetText("")
        bar.clockBox:Hide()
        return
    end
    local hard = grade == "hard"
    bar.clock:SetFontObject(hard and GameFontNormal or GameFontNormalSmall)
    bar.clock:SetText(text)
    if paused then
        bar.clock:SetTextColor(0.5, 0.5, 0.5)
    elseif warn then
        bar.clock:SetTextColor(1, 0.3, 0.3)
    elseif hard then
        bar.clock:SetTextColor(ns.Attn())
    else
        bar.clock:SetTextColor(0.78, 0.66, 0.36)
    end
    bar.clockBox:Show()
end
local function miniReady()
    if not (cur and curDef and curDef.mini) then return false end
    if not cur.MiniReady then return true end
    local ok, v = ns.SafeCall(cur, "MiniReady")
    return ok and v and true or false
end
local function syncFoot(on)
    local f = frame.devFoot
    if on and not miniOn then f:Show() else f:Hide() end
end
local function headShape()
    local mus = (ns.Music.Live() and ns.Music.Pick()) and "+mus" or ""
    local mate = ns.Pair.Mate()
    mus = mus .. (mate and ("+m:" .. mate .. (ns.Pair.Waiting() and "?" or "")) or "+m0")
    if not (cur and curDef) then
        return (ns.HasDoneGames() and "menu+done" or "menu") .. mus
    end
    local s = "game" .. mus
    if miniReady() then s = s .. "+mini" end
    if ns.Records.Keeps(curDef) then s = s .. "+top" end
    if curDef.duo == "turns" then s = s .. "+duo" end
    if curDef.physics and ns.Loop.Current() then s = s .. "+pause" end
    return s
end
local function syncMini(paused)
    local st = frame.miniStrip
    st.title:SetText(curDef.label and ns.TL(curDef.label) or curDef.id)
    st.back.tipTitle = ns.T("btnMiniBack")
    local grade = clockGrade()
    local text, warn
    if cur.Clock then text, warn = cur:Clock() end
    if not text then text = span(elapsed) end
    if grade == "off" then text = "" end
    st.clock:SetText(text or "")
    local note
    if cur.MiniNote then
        local ok, v = ns.SafeCall(cur, "MiniNote")
        if ok then note = v end
    end
    st.note:SetText(note or "")
    if paused then
        st.clock:SetTextColor(0.5, 0.5, 0.5)
    elseif warn then
        st.clock:SetTextColor(1, 0.3, 0.3)
    else
        st.clock:SetTextColor(ns.Attn())
    end
end
function Window:SetMini(on)
    ensure()
    on = on and miniReady() or false
    if on == miniOn then
        miniWant = on
        return
    end
    local L, T, old = frame:GetLeft(), frame:GetTop(), frame:GetScale()
    local db = ns.Store.DB()
    miniOn, miniWant = on, on
    local saved = on and db.miniPos or db.pos
    ns.Help.Hide()
    ns.RecordsUI.Hide()
    ns.ControlsUI.Hide()
    if ns.PrefsUI and ns.PrefsUI.IsShown() then ns.PrefsUI.Back() end
    ns.SelectClose()
    if on then
        local w, h = curDef.mini.w, curDef.mini.h
        if cur.MiniSize then
            local ok, mw, mh = pcall(cur.MiniSize, cur)
            if ok and mw and mh then w, h = mw, mh end
        end
        setCanvasSize(w, h)
    else
        setCanvasSize(curDef.canvas and curDef.canvas.w, curDef.canvas and curDef.canvas.h)
    end
    layoutBody()
    local s = scaleValue()
    frame:SetScale(s)
    if saved and saved.p then
        frame:ClearAllPoints()
        frame:SetPoint(saved.p, UIParent, saved.rp, saved.x, saved.y)
    elseif L and T then
        anchorTopLeft(L * old, T * old, s)
    end
    savePos()
    self:RefreshCanvasBg()
    ns.SafeCall(cur, "Mini", on)
    ns.SafeCall(cur, "Draw")
    headForm = nil
    self:RefreshHead()
end
local heldUI
local function syncHeld()
    local on = cur and curDef and curDef.heldStrip ~= false and ns.Duo.Held()
    if not on then
        if heldUI then heldUI:Hide() end
        return
    end
    if not heldUI then
        heldUI = CreateFrame("Frame", nil, canvas)
        heldUI:SetPoint("BOTTOM", canvas, "BOTTOM", 0, 14)
        heldUI:SetHeight(34)
        heldUI:SetFrameStrata("FULLSCREEN_DIALOG")
        heldUI:SetBackdrop(ns.CARD_BACKDROP)
        heldUI:SetBackdropColor(0, 0, 0, 0.9)
        heldUI:EnableMouse(true)
        heldUI.text = heldUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        heldUI.text:SetPoint("LEFT", heldUI, "LEFT", 14, 0)
        heldUI.resume = ns.MakeKitButton(heldUI)
        heldUI.resume:SetWidth(130)
        heldUI.resume:SetPoint("LEFT", heldUI.text, "RIGHT", GAP, 0)
        heldUI.resume.onClick = function() ns.Duo.Resume() end
        heldUI.solo = ns.MakeKitButton(heldUI)
        heldUI.solo:SetWidth(130)
        heldUI.solo:SetPoint("LEFT", heldUI.resume, "RIGHT", ROW, 0)
        heldUI.solo.onClick = function()
            ns.Duo.GoSolo()
            Window:RefreshHead()
        end
    end
    local at = ns.Duo.HeldAt()
    heldUI.text:SetText((ns.Duo.Peer() or "") .. " "
        .. ns.T("pairHeld", at and math.floor((time() - at) / 60) or 0))
    heldUI.text:SetTextColor(ns.CardEdge(ns.GameLook()))
    heldUI.resume:SetText(ns.T("pairResume"))
    heldUI.resume.tip = ns.T("pairResumeTip")
    if ns.Duo.Calling() then heldUI.resume:Disable() else heldUI.resume:Enable() end
    heldUI.solo:SetText(ns.T("pairSolo"))
    heldUI.solo.tip = ns.T("pairSoloTip")
    heldUI:SetWidth(14 + (heldUI.text:GetStringWidth() or 0) + GAP + 130 + ROW + 130 + 14)
    heldUI:Show()
end
function Window:RefreshHead()
    ensure()
    local shape = headShape()
    local changed = shape ~= headForm
    headForm = shape
    if not cur or not curDef then
        head.title:SetText(ns.T("appTitle"))
        head.title:Show()
        head.noteOff = nil
        head.menu:Hide()
        head.mini:Hide()
        head.help:Hide()
        head.keys:Hide()
        head.again:Hide()
        head.pause:Hide()
        if head.brink then head.brink:Hide() end
        if head.stage then head.stage:Hide() end
        head.top:Hide()
        head.menuPrefs:Show()
        head.prefs:Hide()
        syncPrefsBack(head)
        if ns.HasDoneGames() then
            head.hideDone:Show()
            syncHideDone(head)
        else
            head.hideDone:Hide()
        end
        syncSound(head)
        syncMusic(head)
        head.mate:Show()
        syncMate(head)
        syncHeld()
        syncFoot(ns.Dev and ns.Dev.On() and #(ns.menuDev or {}) > 0)
        if changed then placeHead() end
        return
    end
    head.title:SetText(curDef.label or curDef.id)
    head.title:Show()
    head.noteOff = true
    head.note:Hide()
    head.menuPrefs:Hide()
    head.hideDone:Hide()
    head.menu:Show()
    if miniOn and not miniReady() then
        self:SetMini(false)
        return
    end
    if miniReady() then head.mini:Show() else head.mini:Hide() end
    head.help:Show()
    head.prefs:Show()
    syncPrefsBack(head)
    if curDef.again == false then head.again:Hide() else head.again:Show() end
    if head.brink then
        if ns.Dev.On() and cur.Brink then head.brink:Show() else head.brink:Hide() end
    end
    if head.stage then
        if ns.Dev.On() and cur.Stage and ns.DevStage.Of(curDef) then
            head.stage:SetText(ns.DevStage.Label(ns.DevStage.Get()))
            head.stage:Show()
        else
            head.stage:Hide()
        end
    end
    syncSound(head)
    syncMusic(head)
    if curDef.duo == "turns" then
        head.mate:Show()
        syncMate(head)
    else
        head.mate:Hide()
        head.mateX:Hide()
    end
    syncHeld()
    syncFoot((head.brink and head.brink:IsShown()) or (head.stage and head.stage:IsShown()))
    if ns.Records.Keeps(curDef) then head.top:Show() else head.top:Hide() end
    if ns.Keys.HasScheme(curDef, cur.Key ~= nil) then head.keys:Show() else head.keys:Hide() end
    if curDef.physics and ns.Loop.Current() then
        head.pause:Show()
        syncPause(head)
    else
        head.pause:Hide()
        if ns.PauseUI then ns.PauseUI.Sync() end
    end
    if changed then placeHead() end
    local paused = ns.Loop.IsPaused()
    if miniOn then syncMini(paused) end
    if curDef.ownPanel then
        bar:Hide()
        if cur.PanelSync then ns.SafeCall(cur, "PanelSync") end
        return
    end
    bar:Show()
    local tally = curDef.tally ~= false
    if tally then
        local mark = ns.Records.MarkFor(curDef, "score")
        local okS, sc = ns.SafeCall(cur, "Score")
        bar.score:SetText(ns.Records.Format(mark, okS and sc or 0))
        bar.coin:SetTexture(ns.Records.Icon(mark.mark))
        bar.coin:Show()
    else
        bar.score:SetText("")
        bar.coin:Hide()
    end
    local grade = clockGrade()
    local text, warn
    if cur.Clock then text, warn = cur:Clock() end
    if not text then text = span(elapsed) end
    setClock(text, warn, paused, grade)
    bar.clockBox.tip = cur.clockTip
    if ns.Duo.Active() then
        if ns.Duo.MyTurn() then
            bar.duo:SetText(ns.T("duoMyTurn"))
            bar.duo:SetTextColor(0.4, 0.9, 0.4)
        else
            bar.duo:SetText(ns.T("duoHisTurn", ns.Duo.Peer() or ""))
            bar.duo:SetTextColor(ns.Attn())
        end
    else
        bar.duo:SetText("")
    end
end
ns.Pair.OnChange(function()
    if head then Window:RefreshHead() end
end)
ns.Link.OnPresence(function(name)
    if not head or not name then return end
    local mate = ns.Pair.Mate()
    if mate and name:lower() == mate:lower() then Window:RefreshHead() end
end)
