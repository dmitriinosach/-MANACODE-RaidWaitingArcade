local ADDON, ns = ...
local WIDTH = 340
local X, Y = -24, 220
local GAP = 6
local PAD = 12
local INSET = 5
local ICON = 22
local BTN_W, BTN_H, BTN_GAP = 92, 22, 6
local FADE_IN, FADE_OUT = 0.3, 0.4
local MAX_PLATES = 4
local anchor, tail, grip
local plates = {}
local shown = {}
local relayout
local function store()
    local db = ns.Store.DB()
    db.news = db.news or {}
    return db.news
end
local function restore()
    local a = store()
    anchor:ClearAllPoints()
    if a.point then
        anchor:SetPoint(a.point, UIParent, a.relPoint or a.point, a.x or 0, a.y or 0)
    else
        anchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", X, Y)
    end
end
function ns.News.Up()
    if not anchor then return false end
    local _, y = anchor:GetCenter()
    return (y or 0) < UIParent:GetHeight() / 2
end
local function keep()
    local point, _, relPoint, x, y = anchor:GetPoint()
    local a = store()
    a.point, a.relPoint, a.x, a.y = point, relPoint, x, y
end
local function frames()
    if anchor then return anchor end
    anchor = CreateFrame("Frame", nil, UIParent)
    anchor:SetWidth(WIDTH); anchor:SetHeight(1)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    restore()
    tail = CreateFrame("Frame", nil, UIParent)
    tail:SetWidth(WIDTH); tail:SetHeight(1)
    local side = ns.News.Up() and "BOTTOM" or "TOP"
    tail:SetPoint(side, anchor, side, 0, 0)
    return anchor
end
function ns.News.Tail()
    frames()
    return tail
end
local function paintPlate(p)
    local th = ns.CurrentTheme()
    ns.PaintBody(p.body, th.window.body, 1)
    p.title:SetTextColor(ns.Accent())
end
local function build()
    local p = CreateFrame("Button", nil, UIParent)
    p:SetWidth(WIDTH)
    p:SetFrameStrata("HIGH")
    p:SetClampedToScreen(true)
    ns.DressCard(p)
    p:Hide()
    p.body = p:CreateTexture(nil, "BORDER")
    p.body:SetPoint("TOPLEFT", p, "TOPLEFT", INSET, -INSET)
    p.body:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -INSET, INSET)
    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.icon:SetWidth(ICON); p.icon:SetHeight(ICON)
    p.icon:SetPoint("TOPLEFT", p, "TOPLEFT", PAD, -PAD)
    p.icon:Hide()
    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.title:SetJustifyH("LEFT")
    p.text = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p.text:SetJustifyH("LEFT")
    p.btn = {}
    for i = 1, 3 do
        local b = ns.MakeKitButton(p)
        b:SetWidth(BTN_W); b:SetHeight(BTN_H)
        b:Hide()
        b.onClick = function(self)
            local fn = self.act
            self.act = nil
            ns.News.Drop(p)
            if fn then fn() end
        end
        p.btn[i] = b
    end
    p:SetScript("OnClick", function(self)
        if self.keep then return end
        ns.Sfx.Ui()
        ns.News.Drop(self)
    end)
    p:SetScript("OnUpdate", function(self, elapsed)
        if self.fade == "in" then
            self.a = self.a + elapsed / FADE_IN
            if self.a >= 1 then self.a, self.fade = 1, nil end
            self:SetAlpha(self.a)
        elseif self.fade == "out" then
            self.a = self.a - elapsed / FADE_OUT
            if self.a <= 0 then
                self.fade = nil
                self:Hide()
                local item = self.item
                self.item, self.left, self.keep = nil, nil, nil
                relayout()
                ns.News.Done(item)
                return
            end
            self:SetAlpha(self.a)
            return
        end
        if self.left then
            self.left = self.left - elapsed
            if self.left <= 0 then ns.News.Drop(self) end
        end
    end)
    paintPlate(p)
    return p
end
local function free()
    for i = 1, MAX_PLATES do
        local p = plates[i]
        if not p then
            p = build()
            plates[i] = p
            return p
        end
        if not p.item then return p end
    end
    return nil
end
relayout = function()
    frames()
    for i = #shown, 1, -1 do
        if not shown[i].item then table.remove(shown, i) end
    end
    local up = ns.News.Up()
    local side = up and "BOTTOM" or "TOP"
    local away = up and "TOP" or "BOTTOM"
    local step = up and GAP or -GAP
    local prev
    for i = 1, #shown do
        local p = shown[i]
        p:ClearAllPoints()
        if prev then
            p:SetPoint(side, prev, away, 0, step)
        else
            p:SetPoint(side, anchor, side, 0, 0)
        end
        prev = p
    end
    tail:ClearAllPoints()
    if prev then
        tail:SetPoint(side, prev, away, 0, step)
    else
        tail:SetPoint(side, anchor, side, 0, 0)
    end
end
function ns.News.Drop(p)
    if not p.item or p.fade == "out" then return end
    p.fade, p.left, p.keep = "out", nil, nil
    for i = 1, #p.btn do
        p.btn[i].act = nil
        p.btn[i]:Hide()
    end
end
local function dress(p, item)
    local x = PAD
    if item.icon then
        p.icon:SetTexture(item.icon)
        ns.CropIcon(p.icon)
        p.icon:Show()
        x = PAD + ICON + 8
    else
        p.icon:Hide()
    end
    p.title:ClearAllPoints()
    p.title:SetPoint("TOPLEFT", p, "TOPLEFT", x, -PAD)
    p.title:SetPoint("TOPRIGHT", p, "TOPRIGHT", -PAD, -PAD)
    p.title:SetText(item.title or ns.T("appTitle"))
    p.text:ClearAllPoints()
    p.text:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -3)
    p.text:SetPoint("TOPRIGHT", p, "TOPRIGHT", -PAD, 0)
    p.text:SetText(item.text)
    local h = PAD + p.title:GetStringHeight() + 3 + p.text:GetStringHeight() + PAD
    if item.icon and h < PAD * 2 + ICON then h = PAD * 2 + ICON end
    local n = item.buttons and #item.buttons or 0
    if n > 3 then n = 3 end
    for i = 1, #p.btn do
        local b = p.btn[i]
        local spec = (i <= n) and item.buttons[i] or nil
        if not spec then
            b.act = nil
            b:Hide()
        else
            b:SetText(spec.text)
            b.act = spec.onClick
            b:ClearAllPoints()
            b:SetPoint("BOTTOMLEFT", p, "BOTTOM",
                -(n * BTN_W + (n - 1) * BTN_GAP) / 2 + (i - 1) * (BTN_W + BTN_GAP), PAD)
            b:Show()
        end
    end
    if n > 0 then h = h + BTN_H + GAP end
    p:SetHeight(h)
    p.keep = (n > 0) or nil
end
ns.News.SetPresenter{
    show = function(item)
        local p = free()
        if not p then return end
        dress(p, item)
        p.item = item
        p.left = item.life
        p.fade, p.a = "in", 0
        p:SetAlpha(0)
        p:Show()
        shown[#shown + 1] = p
        relayout()
    end,
}
ns.OnTheme(function()
    for i = 1, #plates do paintPlate(plates[i]) end
end)
local function gripFrame()
    if grip then return grip end
    frames()
    grip = CreateFrame("Frame", nil, UIParent)
    grip:SetAllPoints(anchor)
    grip:SetHeight(52)
    local side = ns.News.Up() and "BOTTOM" or "TOP"
    grip:SetPoint(side .. "LEFT", anchor, side .. "LEFT", 0, 0)
    grip:SetPoint(side .. "RIGHT", anchor, side .. "RIGHT", 0, 0)
    grip:SetFrameStrata("FULLSCREEN_DIALOG")
    grip:EnableMouse(true)
    ns.DressCard(grip)
    grip:Hide()
    grip.body = grip:CreateTexture(nil, "BORDER")
    grip.body:SetPoint("TOPLEFT", grip, "TOPLEFT", INSET, -INSET)
    grip.body:SetPoint("BOTTOMRIGHT", grip, "BOTTOMRIGHT", -INSET, INSET)
    grip.text = ns.TitleText(grip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    grip.text:SetPoint("LEFT", grip, "LEFT", PAD, 0)
    grip.text:SetText(ns.T("newsGrip"))
    grip.done = ns.MakeKitButton(grip)
    grip.done:SetWidth(BTN_W); grip.done:SetHeight(BTN_H)
    grip.done:SetPoint("RIGHT", grip, "RIGHT", -PAD, 0)
    grip.done:SetText(ns.T("newsDone"))
    grip.done.onClick = function() ns.News.Move(false) end
    grip:SetScript("OnMouseDown", function()
        anchor:StartMoving()
    end)
    grip:SetScript("OnMouseUp", function()
        anchor:StopMovingOrSizing()
        keep()
        relayout()
    end)
    ns.PaintBody(grip.body, ns.CurrentTheme().window.body, 1)
    return grip
end
function ns.News.Move(on)
    local g = gripFrame()
    if on then
        g.text:SetText(ns.T("newsGrip"))
        g.done:SetText(ns.T("newsDone"))
        g:Show()
    else
        g:Hide()
    end
end
function ns.News.ResetAnchor()
    frames()
    local a = store()
    a.point, a.relPoint, a.x, a.y = nil, nil, nil, nil
    restore()
    relayout()
end
function ns.News.Moving()
    return (grip and grip:IsShown()) and true or false
end
