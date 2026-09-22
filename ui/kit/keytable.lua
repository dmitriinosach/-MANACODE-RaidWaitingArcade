local ADDON, ns = ...
local ROW_H   = 26
local HEAD_H  = 20
local KEY_W   = 150
local MOUSE_W = 150
local GAP     = ns.Space.gap
local GRAB_SEC = 15
local TINT = {
    prefs = ns.ATTN,
    own   = { ns.Accent() },
    none  = { 0.5, 0.5, 0.5 },
}
local Table = {}
Table.__index = Table
function ns.KeyTableHeight(n, spec)
    local rows = n
    if (spec.cols or 1) == 2 then
        local split = spec.split or math.ceil(n / 2)
        rows = math.max(split, n - split)
    end
    return (spec.header and HEAD_H or 0) + rows * ROW_H
end
function ns.MakeKeyTable(parent, spec)
    local t = setmetatable({ spec = spec, rows = {} }, Table)
    t.frame = ns.NewFrame("Frame", nil, parent)
    t.frame:SetWidth(spec.width or parent:GetWidth() or 400)
    t.frame:SetHeight(ROW_H)
    if spec.header then
        local f = t.frame
        t.hAction = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.hKey    = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.hMouse  = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t.hRule   = f:CreateTexture(nil, "ARTWORK")
        t.hRule:SetHeight(1)
    end
    return t
end
function Table:Frame()
    return self.frame
end
function Table:Height()
    return self.frame:GetHeight()
end
local function rowAt(self, i)
    local r = self.rows[i]
    if r then return r end
    local f = self.frame
    r = {}
    r.cap = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.cap:SetJustifyH("LEFT")
    r.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.hint:SetJustifyH("LEFT")
    r.mouse = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.mouse:SetJustifyH("CENTER")
    r.fixed = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.fixed:SetJustifyH("CENTER")
    r.btn = ns.MakeKitButton(f)
    r.btn:SetHeight(ns.Space.ctl)
    r.btn:SetWidth(KEY_W)
    local me = self
    r.btn.onClick = function()
        if me.spec.onGrab and r.data then me.spec.onGrab(r.data) end
    end
    self.rows[i] = r
    return r
end
local function tipFor(row)
    if row.fixed then return ns.T("keysRowFixed") end
    if row.origin == "own" then return ns.T("keysRowOwn", ns.Keys.KeyText(row.base)) end
    if row.origin == "prefs" then return ns.T("keysRowWas", ns.Keys.KeyText(row.base)) end
    if row.key then return ns.T("keysGameTip") end
    if row.base then return ns.T("keysRowTaken") end
    return ns.T("keysRowFree")
end
local function place(self, r, row, x, y, w)
    local sp = self.spec
    local f = self.frame
    local mouseCol = sp.mouse == "col"
    local keyX = x + w - KEY_W - (mouseCol and (MOUSE_W + GAP) or 0)
    r.cap:ClearAllPoints()
    r.cap:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(y + 4))
    r.cap:SetText(row.label)
    r.cap:SetTextColor(ns.CardEdge(ns.LookOf(f)))
    r.cap:Show()
    if sp.mouse == "hint" and row.mouse then
        r.hint:ClearAllPoints()
        r.hint:SetPoint("LEFT", r.cap, "RIGHT", 4, 0)
        r.hint:SetText(row.mouse)
        r.hint:Show()
    else
        r.hint:Hide()
    end
    if row.fixed then
        r.btn:Hide()
        r.fixed:ClearAllPoints()
        r.fixed:SetWidth(KEY_W)
        r.fixed:SetPoint("TOPLEFT", f, "TOPLEFT", keyX, -(y + 4))
        r.fixed:SetText(row.text)
        r.fixed:Show()
    else
        r.fixed:Hide()
        r.btn:ClearAllPoints()
        r.btn:SetPoint("TOPLEFT", f, "TOPLEFT", keyX, -(y + 2))
        r.btn:SetText(row.text)
        r.btn.tint = row.key and TINT[row.origin] or TINT.none
        r.btn.tipTitle = row.label
        r.btn.tip = ns.T("keysRowTip")
        r.btn.tipDim = tipFor(row)
        ns.StyleButton(r.btn)
        r.btn:Show()
    end
    if mouseCol then
        r.mouse:ClearAllPoints()
        r.mouse:SetWidth(MOUSE_W)
        r.mouse:SetPoint("TOPLEFT", f, "TOPLEFT", x + w - MOUSE_W, -(y + 4))
        r.mouse:SetText(row.mouse or "")
        if sp.mouseDim then
            r.mouse:SetTextColor(0.45, 0.45, 0.45)
        else
            r.mouse:SetTextColor(1, 1, 1)
        end
        r.mouse:Show()
    else
        r.mouse:Hide()
    end
end
function Table:SetRows(rows)
    local sp = self.spec
    local f = self.frame
    local W = f:GetWidth()
    local cols = sp.cols or 1
    local split = sp.split or math.ceil(#rows / 2)
    local colW = (cols == 2) and math.floor((W - GAP) / 2) or W
    local y = 0
    if sp.header then
        local keyX = W - KEY_W - (sp.mouse == "col" and (MOUSE_W + GAP) or 0)
        self.hAction:ClearAllPoints()
        self.hAction:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -2)
        self.hAction:SetText(ns.T("colAction"))
        local hr, hg, hb = ns.CardEdge(ns.LookOf(f))
        self.hAction:SetTextColor(hr, hg, hb)
        self.hKey:ClearAllPoints()
        self.hKey:SetWidth(KEY_W)
        self.hKey:SetPoint("TOPLEFT", f, "TOPLEFT", keyX, -2)
        self.hKey:SetJustifyH("CENTER")
        self.hKey:SetText(ns.T("colKey"))
        self.hKey:SetTextColor(hr, hg, hb)
        if sp.mouse == "col" then
            self.hMouse:ClearAllPoints()
            self.hMouse:SetWidth(MOUSE_W)
            self.hMouse:SetPoint("TOPLEFT", f, "TOPLEFT", W - MOUSE_W, -2)
            self.hMouse:SetJustifyH("CENTER")
            self.hMouse:SetText(ns.T("colMouse"))
            self.hMouse:SetTextColor(hr, hg, hb)
            self.hMouse:Show()
        else
            self.hMouse:Hide()
        end
        local c = (ns.LookOf(f) or ns.CurrentTheme()).rule
        ns.Paint(self.hRule, c[1], c[2], c[3], c[4])
        self.hRule:ClearAllPoints()
        self.hRule:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(HEAD_H - 3))
        self.hRule:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -(HEAD_H - 3))
        y = HEAD_H
    end
    for i, row in ipairs(rows) do
        local r = rowAt(self, i)
        r.data = row
        local col, n = 0, i - 1
        if cols == 2 and i > split then col, n = 1, i - split - 1 end
        place(self, r, row, col * (colW + GAP), y + n * ROW_H, colW)
    end
    for i = #rows + 1, #self.rows do
        local r = self.rows[i]
        r.data = nil
        r.cap:Hide(); r.hint:Hide(); r.mouse:Hide(); r.fixed:Hide(); r.btn:Hide()
    end
    local h = ns.KeyTableHeight(#rows, sp)
    f:SetHeight(math.max(h, 1))
    return h
end
ns.KeyGrab = {}
local grab, onKey
local function build()
    local f = ns.NewFrame("Frame", nil, UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true)
    f:Hide()
    local dim = f:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints()
    ns.Paint(dim, 0, 0, 0, 0.7)
    local card = ns.NewFrame("Frame", nil, f)
    card:SetWidth(320)
    card:SetHeight(142)
    card:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.card = ns.DressCard(card, ns.GameLook())
    f.title = ns.TitleText(card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"), f.card)
    f.title:SetPoint("TOP", card, "TOP", 0, -ns.Space.pad)
    local textW = card:GetWidth() - ns.Space.pad * 2
    f.what = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.what:SetPoint("TOP", f.title, "BOTTOM", 0, -6)
    f.what:SetWidth(textW)
    f.note = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.note:SetPoint("TOP", f.what, "BOTTOM", 0, -8)
    f.note:SetWidth(textW)
    f.cancel = ns.MakeKitButton(card)
    f.cancel:SetWidth(96)
    f.cancel:SetHeight(ns.Space.ctl)
    f.cancel:SetPoint("BOTTOM", card, "BOTTOM", 0, ns.Space.pad)
    f.cancel.onClick = function() ns.KeyGrab.Stop() end
    f:SetScript("OnShow", function(self)
        self:EnableKeyboard(true)
        self.left = GRAB_SEC
    end)
    f:SetScript("OnHide", function(self)
        self:EnableKeyboard(false)
        onKey = nil
    end)
    f:SetScript("OnUpdate", function(self, elapsed)
        self.left = (self.left or GRAB_SEC) - elapsed
        if self.left <= 0 then ns.KeyGrab.Stop() end
    end)
    f:SetScript("OnMouseDown", function() ns.KeyGrab.Stop() end)
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then ns.KeyGrab.Stop(); return end
        if GetBindingFromClick(key) == "SCREENSHOT" then
            TakeScreenshot()
            return
        end
        local k = ns.Keys.Normalize(key)
        if not k then return end
        local fn = onKey
        ns.KeyGrab.Stop()
        if fn then fn(k) end
    end)
    return f
end
function ns.KeyGrab.Start(host, label, fn)
    if InCombatLockdown() then
        ns.say(ns.T("keysCombat"))
        return
    end
    ns.SelectClose()
    grab = grab or build()
    if grab.host ~= host then
        grab.host = host
        grab:SetParent(host)
        grab:ClearAllPoints()
        grab:SetAllPoints(host)
        grab:SetFrameStrata("FULLSCREEN_DIALOG")
        grab:SetFrameLevel((host:GetFrameLevel() or 0) + 60)
    end
    onKey = fn
    ns.Restyle(grab.card, ns.GameLook())
    grab.title:SetText(ns.T("keysAsk"))
    grab.what:SetText(ns.T("keysAskFor", label))
    grab.note:SetText(ns.T("keysAskNote"))
    grab.cancel:SetText(ns.T("keysCancel"))
    grab:Show()
end
function ns.KeyGrab.Stop()
    if grab then grab:Hide() end
    onKey = nil
end
function ns.KeyGrab.IsShown()
    return grab and grab:IsShown() or false
end
