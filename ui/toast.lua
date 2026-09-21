local ADDON, ns = ...
ns.Toast = {}
local W, H, PAD, ICON = 360, 58, 10, 30
local LIFE = 12
local SLIDE = 16
local TOP_Y = -30
local frame, banner
local function dress(f)
    ns.DressCard(f)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetWidth(ICON); f.icon:SetHeight(ICON)
    f.icon:SetPoint("LEFT", f, "LEFT", PAD, 0)
    f.icon:SetTexture(ns.IconPath("INV_Crate_04"))
    ns.CropIcon(f.icon)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + 8, -PAD)
    f.title:SetJustifyH("LEFT")
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
    f.text:SetWidth(W - PAD * 2 - ICON - 8)
    f.text:SetJustifyH("LEFT")
end
local function fill(f, ver)
    f.title:SetText(ns.T("toastTitle", ver))
    f.text:SetText(ns.T("toastText", ns.Version.Mine()))
end
local function build()
    local host = ns.window:Frame()
    frame = CreateFrame("Button", nil, host)
    frame:SetFrameLevel(host:GetFrameLevel() + 30)
    frame:SetWidth(W); frame:SetHeight(H)
    frame:SetPoint("TOP", ns.window:Canvas(), "TOP", 0, -8)
    dress(frame)
    frame:SetScript("OnClick", function()
        ns.Sfx.Ui()
        ns.Toast.Hide()
    end)
    frame:SetScript("OnUpdate", function(self, dt)
        if not self.left then return end
        self.left = self.left - dt
        if self.left <= 0 then ns.Toast.Hide() end
    end)
    frame:Hide()
end
local function buildBanner()
    banner = CreateFrame("Button", nil, UIParent)
    banner:SetFrameStrata("HIGH")
    banner:SetWidth(W); banner:SetHeight(H)
    banner:SetPoint("TOP", UIParent, "TOP", 0, TOP_Y)
    banner:SetClampedToScreen(true)
    banner:EnableMouse(true)
    dress(banner)
    banner:SetScript("OnEnter", function(self)
        ns.Version.TopSeen()
        ns.Anim.Leave(self, 0, SLIDE)
    end)
    banner:Hide()
end
function ns.Toast.Update(ver)
    if not frame then build() end
    fill(frame, ver)
    frame.left = LIFE
    ns.Anim.Slide(frame, 0, SLIDE)
end
function ns.Toast.Hide()
    if not frame then return end
    frame.left = nil
    ns.Anim.Leave(frame, 0, SLIDE)
end
function ns.Toast.Flush()
    if not ns.Version.NeedInside() then return end
    ns.Version.InsideShown()
    ns.Toast.Update(ns.Version.Newest())
end
function ns.Toast.Banner(ver)
    if not ns.Version.NeedTop() then return end
    if not banner then buildBanner() end
    fill(banner, ver)
    ns.Anim.Slide(banner, 0, SLIDE)
end
ns.Version.OnDue(ns.Toast.Banner)
