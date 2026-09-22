local ADDON, ns = ...
ns.About = {}
local ABOUT = {
    titleKey = "abtTitle",
    lineKeys = { "abtLine1", "abtLine2", "abtLine3" },
    site = "https://wow-addons.manacode.su",
    sitePage = { ruRU = "/arcade/", other = "/en/arcade/" },
    discord = "https://discord.gg/CYnxS6R9qY",
    release = "https://github.com/dmitriinosach/-MANACODE-RaidWaitingArcade/releases",
    releaseName = "GitHub",
}
local MIRRORS = {
    { label = "CurseForge",   icon = "INV_Misc_EngGizmos_20", url = "" },
    { label = "WoWInterface", icon = "INV_Misc_EngGizmos_20", url = "" },
}
ns.About.DATA = ABOUT
function ns.About.Site()
    local page = ABOUT.sitePage[ns.CurrentLocale()] or ABOUT.sitePage.other
    return ABOUT.site .. page
end
ns.About.MIRRORS = MIRRORS
function ns.About.Links()
    local out = {}
    local function add(label, url, icon, tipKey)
        if url and url ~= "" then
            out[#out + 1] = { label = label, url = url, icon = icon, tipKey = tipKey }
        end
    end
    add(ABOUT.releaseName or ns.T("abtRelease"), ABOUT.release,
        "INV_Crate_04", "linkTipRelease")
    add("Discord", ABOUT.discord, "INV_Misc_Note_01", "linkTipDiscord")
    add(ns.T("abtOthers"), ns.About.Site(), "INV_Misc_Book_09", "linkTipOthers")
    for _, m in ipairs(MIRRORS) do add(m.label, m.url, m.icon) end
    return out
end
local frame
local ROW_H = 22
local ROW_X = 110
local ROW_W = 322
local function copyRow(parent, label, url, y)
    if not url or url == "" then return y end
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -y - 4)
    fs:SetText(label)
    local box = ns.NewFrame("Frame", nil, parent)
    box:SetWidth(ROW_W)
    box:SetHeight(ROW_H)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", ROW_X, -y)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.5)
    box:SetBackdropBorderColor(0.52, 0.47, 0.40, 1)
    local key = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    key:SetPoint("RIGHT", box, "RIGHT", -7, 0)
    key:SetText(ns.T("abtCopyKey"))
    local edit = ns.NewFrame("EditBox", nil, box)
    edit:SetFrameLevel(box:GetFrameLevel() + 1)
    edit:SetHeight(ROW_H - 6)
    edit:SetPoint("LEFT", box, "LEFT", 7, 0)
    edit:SetPoint("RIGHT", key, "LEFT", -7, 0)
    edit:EnableMouse(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetText(url)
    edit:SetCursorPosition(0)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetCursorPosition(0)
    end)
    edit:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= url then self:SetText(url) end
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return y + ROW_H + 6
end
local function build()
    frame = ns.NewFrame("Frame", ADDON .. "AboutFrame", UIParent)
    frame:SetSize(460, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(1, 1, 1, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)
    tinsert(UISpecialFrames, ADDON .. "AboutFrame")
    local close = ns.NewFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    local y = 18
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -y)
    title:SetText(ns.T(ABOUT.titleKey))
    y = y + 28
    for _, key in ipairs(ABOUT.lineKeys) do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -y)
        fs:SetWidth(420)
        fs:SetJustifyH("LEFT")
        fs:SetText(ns.T(key))
        y = y + fs:GetStringHeight() + 6
    end
    y = y + 8
    frame.ver = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.ver:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -y)
    frame.ver:SetWidth(420)
    frame.ver:SetJustifyH("LEFT")
    y = y + 22
    y = copyRow(frame, ns.T("abtRelease"), ABOUT.release, y)
    y = copyRow(frame, "Discord", ABOUT.discord, y)
    y = copyRow(frame, ns.T("abtOthers"), ns.About.Site(), y)
    local shown = 0
    for _, m in ipairs(MIRRORS) do
        if m.url and m.url ~= "" then
            if shown == 0 then
                y = y + 6
                local head = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                head:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -y)
                head:SetText(ns.T("abtMirrors"))
                y = y + 22
            end
            shown = shown + 1
            y = copyRow(frame, m.label, m.url, y)
        end
    end
    frame:SetHeight(y + 24)
    frame:Hide()
end
local function refresh()
    if not (frame and frame.ver) then return end
    local mine = ns.Version and ns.Version.Mine() or ns.VERSION or "?"
    local new = ns.Version and ns.Version.Newest()
    if new then
        frame.ver:SetText(ns.T("abtVerOld", mine, new))
    else
        frame.ver:SetText(ns.T("abtVer", mine))
    end
end
function ns.About.Show()
    if not frame then build() end
    refresh()
    frame:Show()
end
function ns.About.Toggle()
    if not frame then build() end
    if frame:IsShown() then
        frame:Hide()
    else
        refresh()
        frame:Show()
    end
end
