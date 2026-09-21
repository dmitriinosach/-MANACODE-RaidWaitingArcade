local ADDON, ns = ...
local GLOW_INSET, GLOW_A = 3, 0.10
local function styleButton(b)
    local bt = ns.ButtonSkin(b.skinFrom or b)
    local bg, br, t
    if b.btnDisabled and b.active then
        bg, br, t = bt.bgActive, bt.borderActive, bt.textOff
    elseif b.btnDisabled then
        bg, br, t = bt.bgOff, bt.borderOff, bt.textOff
    elseif b.active then
        bg, br, t = bt.bgActive, bt.borderActive, bt.textActive
    elseif b.pressed then
        bg, br, t = bt.bgDown, bt.borderHover, bt.textHover
    elseif b.hovered then
        bg, br, t = bt.bgHover, bt.borderHover, bt.textHover
    else
        bg, br, t = bt.bg, bt.border, bt.text
    end
    if b.tint and not b.btnDisabled then t = b.tint end
    b:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    b:SetBackdropBorderColor(br[1], br[2], br[3], br[4])
    b.text:SetTextColor(t[1], t[2], t[3])
    if b.glow then
        if b.hovered and not b.pressed and not b.btnDisabled then
            local g = bt.glow
            b.glow:SetTexture(g[1], g[2], g[3], GLOW_A)
            b.glow:Show()
        else
            b.glow:Hide()
        end
    end
end
ns.StyleButton = styleButton
local made = {}
local function paintMade(b)
    b:SetBackdrop(ns.ButtonSkin(b.skinFrom or b).backdrop)
    styleButton(b)
end
local function repaintMade()
    for i = 1, #made do paintMade(made[i]) end
end
ns.OnTheme(repaintMade)
function ns.MakeKitButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetBackdrop(ns.ButtonSkin().backdrop)
    b:SetHeight(22)
    b.kitPaint = paintMade
    made[#made + 1] = b
    b.glow = ns.Fill(b, "ARTWORK", 1, 1, 1, GLOW_A)
    b.glow:SetBlendMode("ADD")
    b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", GLOW_INSET, -GLOW_INSET)
    b.glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -GLOW_INSET, GLOW_INSET)
    b.glow:Hide()
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetJustifyH("CENTER")
    b:SetFontString(b.text)
    b:SetPushedTextOffset(1, -1)
    function b:Enable()
        self.btnDisabled = nil
        styleButton(self)
    end
    function b:Disable()
        self.btnDisabled = true
        styleButton(self)
    end
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        styleButton(self)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = false
        self.pressed = nil
        styleButton(self)
        ns.TipHide()
    end)
    b:SetScript("OnMouseDown", function(self)
        if self.btnDisabled then return end
        self.pressed = true
        styleButton(self)
    end)
    b:SetScript("OnMouseUp", function(self)
        if not self.pressed then return end
        self.pressed = nil
        styleButton(self)
    end)
    b:SetScript("OnClick", function(self, button)
        if self.btnDisabled then return end
        ns.Sfx.Ui(self.clickSfx)
        if self.onClick then self.onClick(self, button) end
    end)
    styleButton(b)
    return b
end
local INFO_DISC  = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local INFO_ICON  = "Interface\\FriendsFrame\\InformationIcon"
local INFO_COORD = { 0.0625, 0.9375, 0.0625, 0.9375 }
local helps = {}
local function paintHelp(b)
    local r, g, bl = ns.CardEdge(ns.LookOf(b))
    b.ring:SetVertexColor(r, g, bl)
    b.label:SetTextColor(r, g, bl)
end
ns.OnTheme(function()
    for i = 1, #helps do paintHelp(helps[i]) end
end)
local INFO_BTN, INFO_ICON_SZ, INFO_CAP_GAP = 20, 13, 5
function ns.MakeHelpButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(INFO_BTN); b:SetHeight(INFO_BTN)
    b.ring = b:CreateTexture(nil, "BORDER")
    b.ring:SetTexture(INFO_DISC)
    b.ring:SetWidth(INFO_BTN); b.ring:SetHeight(INFO_BTN)
    b.ring:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.disc = b:CreateTexture(nil, "ARTWORK")
    b.disc:SetTexture(INFO_DISC)
    b.disc:SetVertexColor(0.07, 0.07, 0.08, 0.95)
    b.disc:SetWidth(INFO_BTN - 3); b.disc:SetHeight(INFO_BTN - 3)
    b.disc:SetPoint("CENTER", b.ring, "CENTER", 0, 0)
    b.icon = b:CreateTexture(nil, "OVERLAY")
    b.icon:SetTexture(INFO_ICON)
    b.icon:SetTexCoord(INFO_COORD[1], INFO_COORD[2], INFO_COORD[3], INFO_COORD[4])
    b.icon:SetWidth(INFO_ICON_SZ); b.icon:SetHeight(INFO_ICON_SZ)
    b.icon:SetPoint("CENTER", b.ring, "CENTER", 0, 0)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.label:SetPoint("LEFT", b.ring, "RIGHT", INFO_CAP_GAP, 0)
    b.label:Hide()
    b.kitPaint = paintHelp
    helps[#helps + 1] = b
    paintHelp(b)
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        self.ring:SetVertexColor(1, 1, 1)
        self.label:SetTextColor(1, 1, 1)
        self.icon:SetWidth(INFO_ICON_SZ + 2); self.icon:SetHeight(INFO_ICON_SZ + 2)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = false
        paintHelp(self)
        self.icon:SetWidth(INFO_ICON_SZ); self.icon:SetHeight(INFO_ICON_SZ)
        ns.TipHide()
    end)
    b:SetScript("OnMouseDown", function(self)
        self.icon:SetWidth(INFO_ICON_SZ - 1); self.icon:SetHeight(INFO_ICON_SZ - 1)
    end)
    b:SetScript("OnMouseUp", function(self)
        local sz = self.hovered and (INFO_ICON_SZ + 2) or INFO_ICON_SZ
        self.icon:SetWidth(sz); self.icon:SetHeight(sz)
    end)
    b:SetScript("OnClick", function(self)
        ns.Sfx.Ui("open")
        if self.onClick then self.onClick(self) end
    end)
    function b:SetCaption(text)
        if text and text ~= "" then
            self.label:SetText(text)
            self.label:Show()
            self:SetWidth(INFO_BTN + INFO_CAP_GAP + self.label:GetStringWidth())
        else
            self.label:SetText("")
            self.label:Hide()
            self:SetWidth(INFO_BTN)
        end
    end
    return b
end
local checks = {}
ns.OnTheme(function()
    for i = 1, #checks do ns.PaintTitle(checks[i].label, checks[i]) end
end)
function ns.MakeCheck(parent)
    local c = CreateFrame("CheckButton", nil, parent)
    c:SetSize(24, 24)
    c:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    c:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    c:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    c:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    c.label = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.label:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c.kitPaint = function(self) ns.PaintTitle(self.label, self) end
    checks[#checks + 1] = c
    ns.PaintTitle(c.label, c)
    c:SetScript("OnShow", function(self) ns.PaintTitle(self.label, self) end)
    c:SetScript("OnClick", function(self)
        local on = self:GetChecked() and true or false
        ns.Sfx.Ui(on and "checkOn" or "checkOff")
        if self.onToggle then self.onToggle(on) end
    end)
    c:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    c:SetScript("OnLeave", ns.TipHide)
    return c
end
local SELECT_ARROW = "Interface\\Buttons\\Arrow-Up-Up"
local ARROW_COORD  = { 0, 0.9375, 0.9375, 0.4375 }
local ARROW_W, ARROW_H = 11, 6
local ROW_H, ROW_GAP, LIST_PAD = 20, 2, 6
local list, catcher, rowPool, listCap, openOn
local rows = {}
local function rootOf(sel)
    local f = sel
    while f do
        local p = f:GetParent()
        if not p or p == UIParent then return f end
        f = p
    end
end
local function ensureList(sel)
    local win = rootOf(sel)
    if not win then return nil end
    if list then
        if catcher:GetParent() ~= win then
            catcher:SetParent(win)
            catcher:ClearAllPoints()
            catcher:SetAllPoints(win)
            catcher:SetFrameStrata("FULLSCREEN_DIALOG")
            list:SetFrameLevel(catcher:GetFrameLevel() + 10)
        end
        return list
    end
    catcher = CreateFrame("Frame", nil, win)
    catcher:SetAllPoints(win)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:EnableMouse(true)
    catcher:SetScript("OnMouseDown", function() ns.SelectClose() end)
    catcher:Hide()
    list = CreateFrame("Frame", nil, catcher)
    list:SetFrameLevel(catcher:GetFrameLevel() + 10)
    ns.DressCard(list)
    listCap = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    listCap:SetPoint("TOPLEFT", list, "TOPLEFT", LIST_PAD + 2, -LIST_PAD)
    rowPool = ns.NewPool(function()
        local b = ns.MakeKitButton(list)
        b:SetHeight(ROW_H)
        return b
    end)
    return list
end
function ns.SelectClose()
    if catcher then catcher:Hide() end
    if openOn then
        openOn.active = false
        styleButton(openOn)
        openOn = nil
    end
end
local function openList(sel)
    if sel.btnDisabled then return end
    if openOn == sel then ns.SelectClose(); return end
    ns.SelectClose()
    if not ensureList(sel) then return end
    local win = rootOf(sel)
    openOn = sel
    rowPool:Reset()
    for i = 1, #rows do rows[i] = nil end
    local cap = sel.caption
    listCap:SetText(cap or "")
    local y = LIST_PAD + (cap and (listCap:GetStringHeight() + 5) or 0)
    local w = sel:GetWidth() - LIST_PAD * 2
    for _, opt in ipairs(sel.options or {}) do
        local b = rowPool:Acquire()
        b.skinFrom = sel
        b:SetText(ns.TL(opt.label) or opt.key)
        b.tip = ns.TL(opt.tip)
        b.tipDim = sel.tipDim
        b.active = (opt.key == sel.value)
        b:Enable()
        b.onClick = function()
            ns.SelectClose()
            sel.value = opt.key
            sel:SetText(ns.TL(opt.label) or opt.key)
            if sel.onPick then sel.onPick(opt.key, opt) end
        end
        styleButton(b)
        local need = b.text:GetStringWidth() + 22
        if need > w then w = need end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", list, "TOPLEFT", LIST_PAD, -y)
        y = y + ROW_H + ROW_GAP
        rows[#rows + 1] = b
    end
    rowPool:HideExtras()
    if #rows == 0 then ns.SelectClose(); return end
    for i = 1, #rows do rows[i]:SetWidth(w) end
    list:SetWidth(w + LIST_PAD * 2)
    local h = y - ROW_GAP + LIST_PAD
    list:SetHeight(h)
    local top = sel:GetTop()
    local bottom = sel:GetBottom()
    local floorY = win and win:GetBottom()
    local ceilY = win and win:GetTop()
    local up = false
    if bottom and top and floorY and ceilY then
        up = (bottom - 2 - h < floorY) and (top + 2 + h <= ceilY)
    end
    list:ClearAllPoints()
    if up then
        list:SetPoint("BOTTOMLEFT", sel, "TOPLEFT", 0, 2)
    else
        list:SetPoint("TOPLEFT", sel, "BOTTOMLEFT", 0, -2)
    end
    catcher:Show()
    sel.active = true
    styleButton(sel)
end
function ns.MakeSelect(parent)
    local b = ns.MakeKitButton(parent)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b, "LEFT", 8, 0)
    b.text:SetPoint("RIGHT", b, "RIGHT", -(ARROW_W + 8), 0)
    b.text:SetJustifyH("LEFT")
    b.arrow = b:CreateTexture(nil, "OVERLAY")
    b.arrow:SetTexture(SELECT_ARROW)
    b.arrow:SetTexCoord(ARROW_COORD[1], ARROW_COORD[2], ARROW_COORD[3], ARROW_COORD[4])
    b.arrow:SetWidth(ARROW_W); b.arrow:SetHeight(ARROW_H)
    b.arrow:SetPoint("RIGHT", b, "RIGHT", -6, 0)
    b.isSelect = true
    b.clickSfx = "open"
    b.onClick = function(self) openList(self) end
    function b:SetOptions(options, value, caption)
        self.options, self.caption = options, ns.TL(caption)
        local cur
        for _, o in ipairs(options or {}) do
            if o.key == value then cur = o end
        end
        if not cur then cur = options and options[1] end
        self.value = cur and cur.key or value
        self:SetText(cur and (ns.TL(cur.label) or cur.key) or "?")
        if openOn == self then ns.SelectClose() end
    end
    function b:FitWidth()
        local cur = self.text:GetText()
        local w = 0
        for _, o in ipairs(self.options or {}) do
            self.text:SetText(ns.TL(o.label) or o.key)
            local need = self.text:GetStringWidth() + ARROW_W + 26
            if need > w then w = need end
        end
        self.text:SetText(cur)
        if w < 54 then w = 54 end
        return w
    end
    return b
end
local STEP_ARROW_W, STEP_GAP = 24, 2
local STEP_LESS, STEP_MORE = "<", ">"
local function stepIndex(s)
    for i, o in ipairs(s.options or {}) do
        if o.key == s.value then return i end
    end
    return nil
end
local function stepShow(s)
    local text, canLess, canMore
    if s.options then
        local i = stepIndex(s) or 1
        local o = s.options[i]
        text = o and (ns.TL(o.label) or o.key) or "?"
        canLess, canMore = i > 1, i < #s.options
        s.mid.tip = (o and ns.TL(o.tip)) or s.midTip
    else
        local v = s.value or 0
        text = string.format(ns.TL(s.format) or "%d", v)
        canLess, canMore = v > (s.min or 0), v < (s.max or 0)
        s.mid.tip = s.midTip
    end
    s.mid:SetText(text)
    if s.stepOff or not canLess then s.less:Disable() else s.less:Enable() end
    if s.stepOff or not canMore then s.more:Disable() else s.more:Enable() end
    if s.stepOff then s.mid:Disable() else s.mid:Enable() end
end
local function stepBy(s, dir)
    if s.stepOff then return end
    if s.options then
        local o = s.options[(stepIndex(s) or 1) + dir]
        if not o then return end
        s.value = o.key
        stepShow(s)
        if s.onPick then s.onPick(o.key, o) end
        return
    end
    local d = ((IsShiftKeyDown() and s.big) or s.step or 1) * dir
    local v = (s.value or 0) + d
    if v < s.min then v = s.min elseif v > s.max then v = s.max end
    if v == s.value then return end
    s.value = v
    stepShow(s)
    if s.onSet then s.onSet(v) end
end
local function stepHome(s)
    if s.stepOff or s.home == nil or s.home == s.value then return end
    if s.options then
        for _, o in ipairs(s.options) do
            if o.key == s.home then
                s.value = o.key
                stepShow(s)
                if s.onPick then s.onPick(o.key, o) end
                return
            end
        end
        return
    end
    s.value = s.home
    stepShow(s)
    if s.onSet then s.onSet(s.value) end
end
function ns.MakeStepper(parent)
    local s = CreateFrame("Frame", nil, parent)
    s:SetHeight(22)
    s.isStepper = true
    s.less = ns.MakeKitButton(s)
    s.less:SetText(STEP_LESS)
    s.less:SetWidth(STEP_ARROW_W)
    s.less:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0)
    s.less:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 0, 0)
    s.less.clickSfx = "tick"
    s.less.onClick = function() stepBy(s, -1) end
    s.more = ns.MakeKitButton(s)
    s.more:SetText(STEP_MORE)
    s.more:SetWidth(STEP_ARROW_W)
    s.more:SetPoint("TOPRIGHT", s, "TOPRIGHT", 0, 0)
    s.more:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, 0)
    s.more.clickSfx = "tick"
    s.more.onClick = function() stepBy(s, 1) end
    s.mid = ns.MakeKitButton(s)
    s.mid:SetPoint("TOPLEFT", s.less, "TOPRIGHT", STEP_GAP, 0)
    s.mid:SetPoint("BOTTOMRIGHT", s.more, "BOTTOMLEFT", -STEP_GAP, 0)
    s.mid.onClick = function() stepHome(s) end
    function s:SetOptions(options, value, caption)
        self.options, self.value, self.caption = options, value, ns.TL(caption)
        if stepIndex(self) == nil then
            self.value = options and options[1] and options[1].key or value
        end
        self.min, self.max, self.format = nil, nil, nil
        self.step, self.big = nil, nil
        stepShow(self)
    end
    function s:SetRange(spec)
        self.options = nil
        self.value = spec.value or spec.min or 0
        self.min = spec.min or 0
        self.max = spec.max or self.value
        self.step = spec.step or 1
        self.big = spec.big
        self.format = spec.format
        self.caption = spec.caption
        stepShow(self)
    end
    function s:SetSpec(it)
        self.home = it.home
        self.midTip = ns.TL(it.tip)
        self.onPick, self.onSet = it.onPick, it.onSet
        if it.options then
            self:SetOptions(it.options, it.value, it.label)
        else
            self:SetRange{ value = it.value, min = it.min, max = it.max,
                           step = it.step, big = it.big, format = it.format,
                           caption = it.label }
        end
        self.mid.tipTitle = ns.TL(it.label) or false
        self.mid.tipDim = ns.TL(it.tipDim)
        self.less.tipTitle = it.tipLess or false
        self.more.tipTitle = it.tipMore or false
        local how = self.big and ns.T("stepTipBig", self.big) or nil
        self.less.tip, self.more.tip = how, how
        self.less.tipDim, self.more.tipDim = self.mid.tipDim, self.mid.tipDim
    end
    function s:Disable()
        self.stepOff = true
        stepShow(self)
    end
    function s:Enable()
        self.stepOff = nil
        stepShow(self)
    end
    function s:Restyle()
        stepShow(self)
    end
    function s:FitWidth()
        local cur = self.mid.text:GetText()
        local w = 0
        local function try(text)
            self.mid.text:SetText(text)
            local need = self.mid.text:GetStringWidth() + 18
            if need > w then w = need end
        end
        if self.options then
            for _, o in ipairs(self.options) do try(ns.TL(o.label) or o.key) end
        else
            try(string.format(ns.TL(self.format) or "%d", self.min or 0))
            try(string.format(ns.TL(self.format) or "%d", self.max or 0))
        end
        self.mid.text:SetText(cur)
        if w < 44 then w = 44 end
        return w + (STEP_ARROW_W + STEP_GAP) * 2
    end
    stepShow(s)
    return s
end
