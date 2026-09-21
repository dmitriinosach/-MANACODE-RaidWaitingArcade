local ADDON, ns = ...
local PAD, ROW = 16, 30
local panel
local checks = {}
local function check(key, textKey, y, get, set)
    local c = CreateFrame("CheckButton", "RaidWaitingArcadeOpt_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -y)
    c.textKey = textKey
    c.get = get
    c:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        if ns.PrefsUI and ns.PrefsUI.IsShown() then ns.PrefsUI.Refresh() end
    end)
    checks[#checks + 1] = c
    return c
end
local function button(y, textKey, run)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetHeight(22)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -y)
    b.textKey = textKey
    b:SetScript("OnClick", run)
    return b
end
local function openArcade(prefs)
    if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
    if HideUIPanel and GameMenuFrame then HideUIPanel(GameMenuFrame) end
    ns.window:Open()
    if prefs and ns.PrefsUI then ns.PrefsUI.Show() end
end
local function refresh()
    panel.title:SetText(ns.T("appTitle"))
    for _, c in ipairs(checks) do
        _G[c:GetName() .. "Text"]:SetText(ns.T(c.textKey))
        c:SetChecked(c.get())
    end
    for _, b in ipairs(panel.buttons) do
        b:SetText(ns.T(b.textKey))
        b:SetWidth(math.max(140, b:GetFontString():GetStringWidth() + 30))
    end
end
local function build()
    panel = CreateFrame("Frame", "RaidWaitingArcadeOptions", UIParent)
    panel.name = ns.T("appTitle")
    panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    local y = PAD + 30
    check("Minimap", "optMinimap", y, ns.Store.Minimap, ns.Store.SetMinimap)
    check("Launcher", "optLauncher", y + ROW, ns.Store.Launcher, ns.Store.SetLauncher)
    check("Sound", "lblSound", y + ROW * 2, ns.Store.Sound, function(on)
        ns.Store.SetSound(on)
        if ns.window then ns.window:RefreshHead() end
    end)
    check("Combat", "lblCombat", y + ROW * 3, ns.Store.CombatClose, ns.Store.SetCombatClose)
    local by = y + ROW * 4 + 12
    panel.buttons = {
        button(by, "optOpen", function() openArcade(false) end),
        button(by + ROW, "optAllPrefs", function() openArcade(true) end),
    }
    panel.refresh = refresh
    panel:SetScript("OnShow", refresh)
    InterfaceOptions_AddCategory(panel)
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if type(InterfaceOptions_AddCategory) ~= "function" then return end
    build()
end)
function ns.OpenBlizzOptions()
    if not panel then return end
    InterfaceOptionsFrame_OpenToCategory(panel)
end
