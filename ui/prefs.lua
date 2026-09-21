local ADDON, ns = ...
local PAD   = ns.Space.pad
local GAP   = ns.Space.gap
local INSET = ns.Space.inset
local CAP_H = ns.Space.cap
local CTL_H = ns.Space.ctl
local TITLE_H = 26
local ROW_H   = 26
local CHECK_SZ = 20
local KEY_ROWS = 4
local MUSIC_OFF = "!"
local UI = {}
ns.PrefsUI = UI
local frame, look, play, keys, wipe, icons
local wipeSel
local function checkRow(panel, y, label, tip)
    local c = ns.MakeCheck(panel)
    c:SetWidth(CHECK_SZ); c:SetHeight(CHECK_SZ)
    c:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -y)
    c.label:SetText(label)
    c.tip = tip
    return c
end
local function pickRow(panel, y, label, make)
    local cap = ns.TitleText(panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    cap:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -(y + 4))
    cap:SetText(label)
    local f = make(panel)
    f:SetHeight(CTL_H)
    f:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -INSET, -y)
    f.cap = cap
    return f, cap
end
local function gameLabel(id)
    local def = ns.games and ns.games[id]
    return def and (ns.TL(def.label) or def.id) or id
end
local function doWipe(id)
    if ns.window and ns.window:CurrentId() == id then
        ns.window:ToMenu()
    end
    ns.Store.WipeGame(id)
    wipeSel = nil
    if UI.IsShown() then UI.Refresh() else UI.Show() end
    if ns.window then ns.window:RefreshHead() end
    if ns.menu and ns.menu.Refresh then ns.menu:Refresh() end
    if ns.say then ns.say(ns.T("wipeDone"):format(gameLabel(id))) end
end
local function askWipe()
    local id = wipeSel
    if not id then return end
    local label = gameLabel(id)
    StaticPopupDialogs["RAIDWAITINGARCADE_WIPE2"] = {
        text = ns.T("wipeAsk2"),
        button1 = ns.T("wipeBtn"),
        button2 = ns.T("btnCancel"),
        OnAccept = function() doWipe(id) end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopupDialogs["RAIDWAITINGARCADE_WIPE1"] = {
        text = ns.T("wipeAsk1"):format(label),
        button1 = ns.T("wipeBtn"),
        button2 = ns.T("btnCancel"),
        OnAccept = function() StaticPopup_Show("RAIDWAITINGARCADE_WIPE2") end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("RAIDWAITINGARCADE_WIPE1")
end
local OVER_LEVEL = 100
local function build()
    local parent = ns.window:Frame()
    local canvas = ns.window:Canvas()
    frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(canvas)
    frame:SetFrameLevel(canvas:GetFrameLevel() + OVER_LEVEL)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame:EnableMouse(true)
    frame:Hide()
    frame.title = ns.TitleText(frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    frame.title:SetText(ns.T("prefsTitle"))
    local colW = math.floor((canvas.W - PAD * 2 - GAP) / 2)
    local rowsLook = CAP_H + ROW_H * 6 + INSET
    local rowsPlay = rowsLook
    look = ns.MakePanel(frame, ns.T("prefsLook"))
    look:SetWidth(colW)
    look:SetHeight(rowsLook)
    look.theme = pickRow(look, CAP_H, ns.T("lblLook"), ns.MakeSelect)
    look.theme.tip = ns.T("tipLook")
    look.theme.onPick = function(key) ns.SetTheme(key) end
    look.scale = pickRow(look, CAP_H + ROW_H, ns.T("lblScale"), ns.MakeStepper)
    look.seethru = checkRow(look, CAP_H + ROW_H * 2, ns.T("lblSeeThrough"), ns.T("tipSeeThrough"))
    look.seethru.onToggle = function(on) ns.Store.SetSeeThrough(on) end
    look.combat = checkRow(look, CAP_H + ROW_H * 3, ns.T("lblCombat"), ns.T("tipCombat"))
    look.combat.onToggle = function(on) ns.Store.SetCombatClose(on) end
    look.lang = pickRow(look, CAP_H + ROW_H * 4, ns.T("lblLang"), ns.MakeSelect)
    look.lang.tip = ns.T("tipLang")
    look.lang.onPick = function(key)
        ns.SetLocale(key)
        UI.Refresh()
    end
    look.news = pickRow(look, CAP_H + ROW_H * 5, ns.T("newsAnchor"), function(parent)
        local box = CreateFrame("Frame", nil, parent)
        box:SetHeight(CTL_H)
        box.reset = ns.MakeKitButton(box)
        box.reset:SetWidth(84); box.reset:SetHeight(CTL_H)
        box.reset:SetPoint("RIGHT", box, "RIGHT", 0, 0)
        box.reset:SetText(ns.T("newsReset"))
        box.reset.tip = ns.T("newsResetTip")
        box.reset.onClick = function() ns.News.ResetAnchor() end
        box.move = ns.MakeKitButton(box)
        box.move:SetWidth(104); box.move:SetHeight(CTL_H)
        box.move:SetPoint("RIGHT", box.reset, "LEFT", -ns.Space.row, 0)
        box.move:SetText(ns.T("newsMove"))
        box.move.onClick = function()
            UI.Back()
            ns.News.Move(true)
        end
        box:SetWidth(104 + ns.Space.row + 84)
        return box
    end)
    play = ns.MakePanel(frame, ns.T("prefsPlay"))
    play:SetWidth(colW)
    play:SetHeight(rowsPlay)
    play.sound = checkRow(play, CAP_H, ns.T("lblSound"), ns.T("tipSound"))
    play.sound.onToggle = function(on)
        ns.Store.SetSound(on)
        if ns.window then ns.window:RefreshHead() end
    end
    play.volume = pickRow(play, CAP_H + ROW_H, ns.T("lblVolume"), ns.MakeStepper)
    play.fx = pickRow(play, CAP_H + ROW_H * 2, ns.T("lblFX"), ns.MakeSelect)
    play.fx.tip = ns.T("tipFX")
    play.fx.onPick = function(key) ns.FX.SetLevel(key) end
    play.cell = pickRow(play, CAP_H + ROW_H * 3, ns.T("cellSize"), ns.MakeStepper)
    play.music = pickRow(play, CAP_H + ROW_H * 4, ns.T("lblMusic"), ns.MakeSelect)
    play.music.onPick = function(key)
        if key == MUSIC_OFF then
            ns.Music.SetOn(false)
        else
            local was = ns.Music.On()
            ns.Music.SetPick(key)
            if not was then ns.Music.SetOn(true) end
        end
        if ns.window then ns.window:RefreshHead() end
    end
    keys = ns.MakePanel(frame, ns.T("prefsKeys"))
    keys:SetWidth(canvas.W - PAD * 2)
    keys:SetHeight(CAP_H + ROW_H * KEY_ROWS + INSET)
    keys.reset = ns.MakeKitButton(keys)
    keys.reset:SetWidth(96)
    keys.reset:SetHeight(CTL_H)
    keys.reset:SetPoint("BOTTOMRIGHT", keys, "BOTTOMRIGHT", -INSET, INSET + 2)
    keys.reset:SetText(ns.T("keysReset"))
    keys.reset.tip = ns.T("keysResetTip")
    keys.reset.onClick = function()
        ns.Keys.Reset()
        UI.Refresh()
    end
    keys.info = ns.MakeHelpButton(keys)
    keys.info:SetCaption(nil)
    keys.info:SetPoint("RIGHT", keys.reset, "LEFT", -ns.Space.row, 0)
    keys.info.tipTitle = ns.T("prefsKeys")
    keys.info.tip = ns.T("keysNote")
    keys.table = ns.MakeKeyTable(keys, {
        cols = 2, split = KEY_ROWS,
        width = keys:GetWidth() - INSET * 2,
        onGrab = function(row)
            ns.KeyGrab.Start(frame, row.label, function(k)
                ns.Keys.SetKey(row.action, k)
                UI.Refresh()
            end)
        end,
    })
    keys.table:Frame():SetPoint("TOPLEFT", keys, "TOPLEFT", INSET, -CAP_H)
    local halfW = math.floor((canvas.W - PAD * 2 - GAP) / 2)
    wipe = ns.MakePanel(frame, ns.T("prefsWipe"))
    wipe:SetWidth(halfW)
    wipe:SetHeight(CAP_H + CTL_H + INSET)
    wipe.info = ns.MakeHelpButton(wipe)
    wipe.info:SetCaption(nil)
    wipe.info:SetPoint("TOPRIGHT", wipe, "TOPRIGHT", -INSET, -6)
    wipe.info.tipTitle = ns.T("prefsWipe")
    wipe.info.tip = ns.T("wipeNote")
    wipe.pick = ns.MakeSelect(wipe)
    wipe.pick:SetHeight(CTL_H)
    wipe.pick:SetPoint("TOPLEFT", wipe, "TOPLEFT", INSET, -CAP_H)
    wipe.pick.onPick = function(key)
        wipeSel = key ~= "" and key or nil
        wipe.btn.tip = wipeSel and ns.T("wipeBtnTip") or ns.T("wipeBtnNone")
    end
    wipe.btn = ns.MakeKitButton(wipe)
    wipe.btn:SetWidth(72)
    wipe.btn:SetHeight(CTL_H)
    wipe.btn:SetPoint("LEFT", wipe.pick, "RIGHT", ns.Space.row, 0)
    wipe.btn.onClick = function() askWipe() end
    icons = ns.MakePanel(frame, ns.T("prefsIcon"))
    icons:SetWidth(halfW)
    icons:SetHeight(wipe:GetHeight())
    look.minimap = checkRow(icons, CAP_H, ns.T("lblMinimap"))
    look.minimap.onToggle = function(on) ns.Store.SetMinimap(on) end
    look.launcher = checkRow(icons, CAP_H, ns.T("lblLauncher"), ns.T("tipLauncher"))
    look.launcher:SetPoint("TOPLEFT", icons, "TOPLEFT", INSET + math.floor((halfW - INSET * 2) / 2), -CAP_H)
    look.launcher.onToggle = function(on) ns.Store.SetLauncher(on) end
    local lastH = wipe:GetHeight()
    local blockH = rowsLook + GAP + keys:GetHeight() + GAP + lastH
    local topY = PAD + TITLE_H
    local y = topY + math.floor((canvas.H - topY - PAD - blockH) / 2)
    look:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -y)
    play:SetPoint("TOPLEFT", look, "TOPRIGHT", GAP, 0)
    keys:SetPoint("TOPLEFT", look, "BOTTOMLEFT", 0, -GAP)
    wipe:SetPoint("TOPLEFT", keys, "BOTTOMLEFT", 0, -GAP)
    icons:SetPoint("TOPLEFT", wipe, "TOPRIGHT", GAP, 0)
    parent:HookScript("OnHide", function() UI.Hide() end)
    UI.Paint()
end
local function ensure()
    if not frame then build() end
end
function UI.Paint()
    if not frame then return end
    ns.PaintScreen(frame.bg, 1)
    ns.PaintPanel(look)
    ns.PaintPanel(play)
    ns.PaintPanel(keys)
    ns.PaintPanel(wipe)
    ns.PaintPanel(icons)
end
ns.OnLocale(function()
    if UI.IsShown() then UI.Refresh() end
end)
ns.OnTheme(UI.Paint)
function UI.Refresh()
    ensure()
    look.theme:SetOptions(ns.ThemeOptions(), ns.ThemeKey(), ns.T("lblLook"))
    look.theme:SetWidth(look.theme:FitWidth())
    local sMin, sMax = ns.window:ScaleRange()
    local sCur = ns.Store.Scale()
    sCur = sCur == "full" and sMax or math.max(sMin, math.min(sMax, sCur))
    look.scale:SetSpec{
        label = ns.T("lblScale"),
        value = sCur, min = sMin, max = sMax,
        step = 5, big = 25, format = "%d%%",
        home = 100,
        tip = ns.T("tipScale"),
        onSet = function(v) ns.Store.SetScale(v) end,
    }
    look.scale:SetWidth(look.scale:FitWidth())
    look.seethru:SetChecked(ns.Store.SeeThrough())
    look.combat:SetChecked(ns.Store.CombatClose())
    look.minimap:SetChecked(ns.Store.Minimap())
    look.launcher:SetChecked(ns.Store.Launcher())
    look.lang:SetOptions(ns.LocaleOptions(), ns.LocalePref(), ns.T("lblLang"))
    look.lang:SetWidth(look.lang:FitWidth())
    look.lang.tip = ns.T("tipLang")
    frame.title:SetText(ns.T("prefsTitle"))
    look.cap:SetText(ns.T("prefsLook"))
    play.cap:SetText(ns.T("prefsPlay"))
    keys.cap:SetText(ns.T("prefsKeys"))
    icons.cap:SetText(ns.T("prefsIcon"))
    look.theme.cap:SetText(ns.T("lblLook"))
    look.scale.cap:SetText(ns.T("lblScale"))
    look.seethru.label:SetText(ns.T("lblSeeThrough"))
    look.seethru.tip = ns.T("tipSeeThrough")
    look.combat.label:SetText(ns.T("lblCombat"))
    look.combat.tip = ns.T("tipCombat")
    look.minimap.label:SetText(ns.T("lblMinimap"))
    look.launcher.label:SetText(ns.T("lblLauncher"))
    look.launcher.tip = ns.T("tipLauncher")
    look.lang.cap:SetText(ns.T("lblLang"))
    look.news.cap:SetText(ns.T("newsAnchor"))
    look.news.move:SetText(ns.T("newsMove"))
    look.news.reset:SetText(ns.T("newsReset"))
    look.news.reset.tip = ns.T("newsResetTip")
    look.news.move.tip = ns.T("newsMoveTip")
    keys.reset:SetText(ns.T("keysReset"))
    keys.reset.tip = ns.T("keysResetTip")
    keys.info.tipTitle = ns.T("prefsKeys")
    keys.info.tip = ns.T("keysNote")
    play.sound:SetChecked(ns.Store.Sound())
    play.sound.label:SetText(ns.T("lblSound"))
    play.sound.tip = ns.T("tipSound")
    local vopts = {}
    for _, v in ipairs(ns.Sfx.LEVELS) do
        vopts[#vopts + 1] = { key = tostring(v), label = math.floor(v * 100 + 0.5) .. "%" }
    end
    play.volume:SetSpec{
        label = ns.T("lblVolume"),
        options = vopts,
        value = tostring(ns.Sfx.Volume()),
        home = "1",
        tip = ns.T("tipVolume"),
        onPick = function(key) ns.Sfx.SetVolume(tonumber(key)) end,
    }
    play.volume:SetWidth(play.volume:FitWidth())
    play.volume.cap:SetText(ns.T("lblVolume"))
    play.fx:SetOptions(ns.FX.LevelOptions(), ns.FX.Level(), ns.T("lblFX"))
    play.fx:SetWidth(play.fx:FitWidth())
    play.fx.cap:SetText(ns.T("lblFX"))
    local opts = {}
    for _, px in ipairs(ns.Config.CELL_SIZES) do
        opts[#opts + 1] = { key = px, label = tostring(px) }
    end
    play.cell:SetSpec{
        label = ns.T("cellSize"),
        options = opts,
        value = ns.Config.CellSize(),
        home = ns.Config.ICON_MAX,
        tip = ns.T("cellSizeTip", ns.Config.ICON_MAX),
        onPick = function(key) ns.Config.SetCellSize(key) end,
    }
    play.cell:SetWidth(play.cell:FitWidth())
    play.cell.cap:SetText(ns.T("cellSize"))
    local mopts = { { key = MUSIC_OFF, label = ns.T("musicOff") } }
    for _, sh in ipairs(ns.Music.Shelves()) do
        if sh.n > 0 then
            mopts[#mopts + 1] = { key = sh.key, label = sh.label }
        end
    end
    play.music:SetOptions(mopts, ns.Music.On() and ns.Music.Pick() or MUSIC_OFF, ns.T("lblMusic"))
    play.music:SetWidth(play.music:FitWidth())
    play.music.cap:SetText(ns.T("lblMusic"))
    play.music.tip = ns.T("tipMusicSet")
    keys.table:SetRows(ns.Keys.Scheme(nil))
    local opts = { { key = "", label = ns.T("wipePick") } }
    for _, def in ipairs(ns.gameOrder or {}) do
        local lk = def.id .. ".label"
        opts[#opts + 1] = { key = def.id, label = ns.HasT(lk) and lk or def.label }
    end
    wipe.pick:SetOptions(opts, wipeSel or "", ns.T("prefsWipe"))
    wipe.pick:SetWidth(math.min(wipe.pick:FitWidth(),
        wipe:GetWidth() - INSET * 2 - ns.Space.row - wipe.btn:GetWidth()))
    wipe.cap:SetText(ns.T("prefsWipe"))
    wipe.btn:SetText(ns.T("wipeBtn"))
    wipe.btn.tip = wipeSel and ns.T("wipeBtnTip") or ns.T("wipeBtnNone")
    wipe.info.tipTitle = ns.T("prefsWipe")
    wipe.info.tip = ns.T("wipeNote")
end
function UI.Show()
    ensure()
    if ns.Loop.Current() then
        ns.Loop.Pause(ns.T("pausePrefs"))
    else
        ns.menu:Hide()
    end
    UI.Refresh()
    frame:Show()
end
function UI.Hide()
    ns.SelectClose()
    ns.KeyGrab.Stop()
    if frame then frame:Hide() end
end
function UI.Back()
    UI.Hide()
    if ns.Loop.Current() then
        ns.window:RefreshHead()
        return
    end
    ns.menu:Show()
end
function UI.IsShown()
    return frame and frame:IsShown() and true or false
end
