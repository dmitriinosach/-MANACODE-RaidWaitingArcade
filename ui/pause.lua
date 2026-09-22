local ADDON, ns = ...
local WIDTH  = 300
local HEIGHT = 160
local DIM_A  = 0.55
local BTN_W  = 130
local TICK   = 0.15
ns.PauseUI = {}
local overlay, card, ui, elapsed
local function busy()
    if ns.Help and ns.Help.IsShown() then return true end
    if ns.ControlsUI and ns.ControlsUI.IsShown() then return true end
    if ns.RecordsUI and ns.RecordsUI.IsShown() then return true end
    if ns.PrefsUI and ns.PrefsUI.IsShown() then return true end
    if ns.Over and ns.Over.IsShown() then return true end
    return false
end
local function resume()
    if not ns.Loop.IsPaused() then return end
    ns.Loop.Resume()
    ns.window:RefreshHead()
end
local function ensure()
    if overlay then return end
    local canvas = ns.window:Canvas()
    if not canvas then return end
    overlay = ns.NewFrame("Frame", nil, canvas)
    overlay:SetAllPoints(canvas)
    overlay:SetFrameLevel(canvas:GetFrameLevel() + 60)
    overlay:EnableMouse(true)
    overlay:SetScript("OnMouseDown", resume)
    overlay:Hide()
    overlay.dim = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.dim:SetAllPoints()
    ns.Paint(overlay.dim, 0, 0, 0, DIM_A)
    card = ns.NewFrame("Frame", nil, overlay)
    card:SetWidth(WIDTH); card:SetHeight(HEIGHT)
    card:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    ns.DressCard(card)
    ui = {}
    ui.title = ns.TitleText(card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    ui.title:SetPoint("TOP", card, "TOP", 0, -14)
    ui.game = ns.TitleText(card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    ui.game:SetPoint("TOP", ui.title, "BOTTOM", 0, -4)
    ui.why = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.why:SetPoint("TOP", ui.game, "BOTTOM", 0, -12)
    ui.why:SetWidth(WIDTH - 24)
    ui.why:SetJustifyH("CENTER")
    ui.go = ns.MakeKitButton(card)
    ui.go:SetWidth(BTN_W); ui.go:SetHeight(24)
    ui.go:SetPoint("BOTTOM", card, "BOTTOM", 0, 32)
    ui.go.onClick = resume
    ui.keys = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.keys:SetPoint("BOTTOM", card, "BOTTOM", 0, 12)
    elapsed = 0
    overlay:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < TICK then return end
        elapsed = 0
        ns.PauseUI.Sync()
    end)
end
function ns.PauseUI.Sync()
    local paused, why = ns.Loop.IsPaused()
    local game = ns.Loop.Current()
    if not paused or not game then
        if overlay and overlay:IsShown() then overlay:Hide() end
        return
    end
    ensure()
    if not overlay then return end
    if busy() then
        overlay.dim:Hide()
        card:Hide()
        overlay:EnableMouse(false)
        overlay:Show()
        return
    end
    overlay.dim:Show()
    card:Show()
    overlay:EnableMouse(true)
    local look = ns.GameLook()
    if card.look ~= look then ns.Restyle(card, look) end
    local def = game.def
    ui.title:SetText(ns.T("pauseTitle"))
    ui.game:SetText(def and ns.TL(def.label) or "")
    ui.why:SetText(why and ns.T("pauseWhy", why) or "")
    ui.go:SetText(ns.T("btnResume"))
    ui.go.tip = ns.T("tipResume")
    ui.keys:SetText(ns.Keys.PauseText())
    overlay:Show()
end
function ns.PauseUI.IsShown()
    return (overlay and overlay:IsShown() and card and card:IsShown()) and true or false
end
function ns.PauseUI.Hide()
    if overlay then overlay:Hide() end
end
