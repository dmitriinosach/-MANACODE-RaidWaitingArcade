local ADDON, ns = ...
local RADIUS = 80
local DEF_ANGLE = 210
local ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local ICON_COORD = { 0.75, 1, 0.25, 0.5 }
local button
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
local function build()
    button = CreateFrame("Button", "HTP_ArcadeMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexture(ICON)
    icon:SetTexCoord(ICON_COORD[1], ICON_COORD[2], ICON_COORD[3], ICON_COORD[4])
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    button:SetScript("OnClick", function()
        ns.Sfx.Ui("open")
        ns.window:Toggle()
    end)
    button.tipTitle = ns.T("appTitle")
    button.tip = ns.T("mmTipLeft")
    button.tipDim = ns.T("mmTipDrag")
    button.tipAnchor = "ANCHOR_LEFT"
    button:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    button:SetScript("OnLeave", ns.TipHide)
    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:SetScript("OnUpdate", function()
            local a = angleUnderCursor()
            place(a)
            ns.Store.DB().mmAngle = a
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
    end)
    place(ns.Store.DB().mmAngle or DEF_ANGLE)
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if not Minimap then return end
    build()
end)
function ns.MinimapButton()
    return button
end
