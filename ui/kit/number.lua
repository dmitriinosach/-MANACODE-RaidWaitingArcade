local ADDON, ns = ...
local floor = math.floor
local BG = { 0.063, 0.051, 0.031, 1 }
local EDGE = { 0.31, 0.27, 0.21, 1 }
local FOCUS = { 0.78, 0.63, 0.29, 1 }
local function bars(f, col)
    local out = {}
    local spec = {
        { "TOPLEFT", "TOPRIGHT", nil, 1 },
        { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil },
        { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
    }
    for i = 1, 4 do
        local s = spec[i]
        local t = f:CreateTexture(nil, "BORDER")
        ns.Paint(t, col[1], col[2], col[3], col[4])
        t:SetPoint(s[1], f, s[1], 0, 0)
        t:SetPoint(s[2], f, s[2], 0, 0)
        if s[3] then t:SetWidth(s[3]) end
        if s[4] then t:SetHeight(s[4]) end
        out[i] = t
    end
    return out
end
local function tint(list, col)
    for i = 1, #list do ns.Paint(list[i], col[1], col[2], col[3], col[4]) end
end
local function clamp(b, n)
    n = floor(tonumber(n) or b.lo)
    if n < b.lo then n = b.lo end
    if b.hi and n > b.hi then n = b.hi end
    return n
end
function ns.MakeNumberBox(parent, o)
    o = o or {}
    local b = ns.NewFrame("EditBox", nil, parent)
    b:SetWidth(o.w or 90)
    b:SetHeight(o.h or 24)
    b:SetAutoFocus(false)
    b:SetNumeric(true)
    b:SetMaxLetters(o.letters or 6)
    b:SetFontObject(o.font or "GameFontHighlight")
    b:SetJustifyH("RIGHT")
    b:SetTextInsets(6, 8, 0, 0)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    ns.Paint(bg, BG[1], BG[2], BG[3], BG[4])
    local edge = bars(b, o.edge or EDGE)
    b.lo, b.hi = o.min or 0, o.max
    b.onChange, b.onEnter = o.onChange, o.onEnter
    function b:Value()
        return clamp(self, self:GetText())
    end
    function b:SetValue(n)
        self.quiet = true
        self:SetText(tostring(clamp(self, n)))
        self.quiet = nil
    end
    function b:SetRange(lo, hi)
        self.lo, self.hi = lo or 0, hi
        if self:GetText() ~= "" then self:SetValue(self:GetText()) end
    end
    b:SetScript("OnTextChanged", function(self)
        if self.quiet or not self.onChange then return end
        self.onChange(self:Value())
    end)
    b:SetScript("OnEditFocusGained", function(self)
        tint(edge, o.focus or FOCUS)
        self:HighlightText()
    end)
    b:SetScript("OnEditFocusLost", function(self)
        tint(edge, o.edge or EDGE)
        self:SetValue(self:GetText())
    end)
    b:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    b:SetScript("OnEnterPressed", function(self)
        local n = self:Value()
        self:SetValue(n)
        self:ClearFocus()
        if self.onEnter then self.onEnter(n) end
    end)
    b:SetValue(o.value or b.lo)
    return b
end
