local ADDON, ns = ...
local RADIUS = 80
local DEF_ANGLE = 210
local ICON = "Interface\\AddOns\\" .. ADDON .. "\\art\\arcade_icon"
local LAUNCH = 40
local LAUNCH_POS = { "CENTER", "CENTER", 0, 200 }
local button, launcher
ns.Launch = {}
local function place(angle)
    if not button then return end
    local rad = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(rad) * RADIUS, math.sin(rad) * RADIUS)
end
local function angleUnderCursor()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    return math.deg(math.atan2(cy - my, cx - mx))
end
local function open()
    ns.Sfx.Ui("open")
    ns.window:Toggle()
end
local function tips(b, drag)
    b.tipTitle = ns.T("appTitle")
    b.tip = ns.T("mmTipLeft")
    b.tipDim = ns.T(drag)
    b.tipAnchor = "ANCHOR_LEFT"
    b:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    b:SetScript("OnLeave", ns.TipHide)
end
local function buildMinimap()
    button = ns.NewFrame("Button", "RaidWaitingArcadeMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexture(ICON)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    button:SetScript("OnClick", open)
    tips(button, "mmTipDrag")
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local a = angleUnderCursor()
            place(a)
            ns.Store.DB().mmAngle = a
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    place(ns.Store.DB().mmAngle or DEF_ANGLE)
end
local function placeLauncher()
    local p = ns.Store.DB().launcherPos or LAUNCH_POS
    launcher:ClearAllPoints()
    launcher:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end
local function buildLauncher()
    launcher = ns.NewFrame("Button", "RaidWaitingArcadeLauncher", UIParent)
    launcher:SetSize(LAUNCH, LAUNCH)
    launcher:SetFrameStrata("MEDIUM")
    launcher:SetClampedToScreen(true)
    launcher:SetMovable(true)
    launcher:RegisterForClicks("LeftButtonUp")
    launcher:RegisterForDrag("LeftButton")
    local icon = launcher:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(ICON)
    local hi = launcher:CreateTexture(nil, "HIGHLIGHT")
    hi:SetAllPoints()
    hi:SetTexture(ICON)
    hi:SetBlendMode("ADD")
    hi:SetAlpha(0.35)
    launcher:SetScript("OnClick", open)
    tips(launcher, "lcTipDrag")
    launcher:SetScript("OnDragStart", function(self) self:StartMoving() end)
    launcher:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p1, _, p2, x, y = self:GetPoint(1)
        ns.Store.DB().launcherPos = { p1, p2, math.floor(x + 0.5), math.floor(y + 0.5) }
    end)
    placeLauncher()
end
function ns.Launch.Sync()
    if button then
        if ns.Store.Minimap() then button:Show() else button:Hide() end
    end
    if ns.Store.Launcher() then
        if not launcher then buildLauncher() end
        launcher:Show()
    elseif launcher then
        launcher:Hide()
    end
end
local f = ns.NewFrame("Frame")
ns.Listen(f, "PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if Minimap then buildMinimap() end
    ns.Launch.Sync()
end)
function ns.MinimapButton()
    return button
end
