local ADDON, ns = ...
local SLOT_TEX   = "Interface\\Buttons\\UI-Quickslot2"
local SLOT_SCALE = 1.7
ns.SLOT_SCALE = SLOT_SCALE
local EDGE       = "Interface\\Tooltips\\UI-Tooltip-Border"
local ACT_BG     = "Interface\\Tooltips\\UI-Tooltip-Background"
local ACT_COLOR    = { 0.62, 0.55, 0.38, 0.85 }
local ACT_BG_COLOR = { 0.08, 0.07, 0.05, 0.75 }
local FRAME_COLOR  = { 0.9, 0.74, 0.32, 1 }
local ICON = 38
ns.ICON_SIZE = ICON
function ns.SlotOver(size)
    return math.ceil(size * (SLOT_SCALE - 1) / 2)
end
local compareItem
local function hideCompare()
    if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
    if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
    if ShoppingTooltip3 then ShoppingTooltip3:Hide() end
end
local function showCompare()
    if compareItem and IsShiftKeyDown() and GameTooltip_ShowCompareItem then
        GameTooltip_ShowCompareItem(GameTooltip)
    end
end
local function cellEnter(self)
    if self.tipItem then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.tipItem)
        if self.tip then GameTooltip:AddLine(self.tip, 1, 0.82, 0, true) end
        GameTooltip:Show()
        compareItem = self.tipItem
        showCompare()
    elseif self.tipSpell then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. self.tipSpell)
        if self.tip then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(self.tip, 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    else
        ns.TipShow(self)
    end
    if self.onEnter then self.onEnter(self) end
end
local function cellLeave(self)
    compareItem = nil
    hideCompare()
    ns.TipHide()
    if self and self.onLeave then self.onLeave(self) end
end
ns.CellEnter = cellEnter
local shiftWatch = ns.NewFrame("Frame")
ns.Listen(shiftWatch, "MODIFIER_STATE_CHANGED")
shiftWatch:SetScript("OnEvent", function(_, _, key, state)
    if not compareItem or (key ~= "LSHIFT" and key ~= "RSHIFT") then return end
    if state == 1 then showCompare() else hideCompare() end
end)
function ns.MakeCell(parent)
    local b = ns.NewFrame("Button", nil, parent)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    ns.CropIcon(b.icon)
    b.slot = b:CreateTexture(nil, "OVERLAY")
    b.slot:SetTexture(SLOT_TEX)
    b.slot:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.slot:Hide()
    b.over = ns.NewFrame("Frame", nil, b)
    b.over:SetAllPoints(b)
    b.over:SetFrameLevel(b:GetFrameLevel() + 1)
    b.check = b.over:CreateTexture(nil, "OVERLAY")
    b.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    b.check:Hide()
    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    b.count:Hide()
    b.center = b:CreateFontString(nil, "OVERLAY", "NumberFont_Outline_Large")
    b.center:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.center:Hide()
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnEnter", cellEnter)
    b:SetScript("OnLeave", cellLeave)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(self, button)
        if self.onClick then self.onClick(self, button) end
    end)
    return b
end
function ns.StyleCell(b, kind)
    if b._style == kind then return end
    b._style = kind
    b._edge = nil
    if kind == "spell" then
        b.slot:Hide()
        b:SetBackdrop(nil)
        b.icon:SetTexCoord(0, 1, 0, 1)
        b.icon:ClearAllPoints()
        b.icon:SetAllPoints(b)
    elseif kind == "framed" then
        b.slot:Hide()
        b:SetBackdrop({ edgeFile = EDGE, edgeSize = 9 })
        b:SetBackdropBorderColor(FRAME_COLOR[1], FRAME_COLOR[2], FRAME_COLOR[3], FRAME_COLOR[4])
        b._edge = FRAME_COLOR
        ns.CropIcon(b.icon)
        b.icon:ClearAllPoints()
        b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
        b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    elseif kind == "slot" then
        b:SetBackdrop(nil)
        b.icon:SetTexCoord(0, 1, 0, 1)
        b.icon:ClearAllPoints()
        b.icon:SetAllPoints(b)
        local s = (b:GetWidth() or ICON) * SLOT_SCALE
        b.slot:SetWidth(s); b.slot:SetHeight(s)
        b.slot:Show()
    elseif kind == "action" then
        b.slot:Hide()
        b:SetBackdrop({ bgFile = ACT_BG, edgeFile = EDGE, edgeSize = 8,
                        insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        b:SetBackdropColor(ACT_BG_COLOR[1], ACT_BG_COLOR[2], ACT_BG_COLOR[3], ACT_BG_COLOR[4])
        b:SetBackdropBorderColor(ACT_COLOR[1], ACT_COLOR[2], ACT_COLOR[3], ACT_COLOR[4])
        b._edge = ACT_COLOR
        ns.CropIcon(b.icon)
        b.icon:ClearAllPoints()
        b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
        b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
    else
        b.slot:Hide()
        b:SetBackdrop(nil)
        ns.CropIcon(b.icon)
        b.icon:ClearAllPoints()
        b.icon:SetAllPoints(b)
    end
end
function ns.CellCount(b, n)
    if n == nil then b.count:Hide(); return end
    b.count:SetText(n)
    if n <= 0 then b.count:SetTextColor(1, 0.2, 0.2) else b.count:SetTextColor(1, 1, 1) end
    b.count:Show()
end
local CHECK_RATIO = 0.38
local CHECK_OUT   = 0.055
local CHECK_MIN   = 8
function ns.CellCheck(b)
    local w = b:GetWidth() or ICON
    local sz = math.floor(w * CHECK_RATIO + 0.5)
    if sz < CHECK_MIN then sz = CHECK_MIN end
    local out = math.floor(w * CHECK_OUT + 0.5)
    b.check:SetWidth(sz); b.check:SetHeight(sz)
    b.check:ClearAllPoints()
    b.check:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", out, -out)
    b.check:Show()
end
local CENTER_RATIO = 0.95
local NUM_FONT = "Fonts\\ARIALN.TTF"
function ns.CellCenter(b, text)
    if not text or text == "" then b.center:Hide(); return end
    local px = math.floor((b:GetWidth() or ICON) * CENTER_RATIO + 0.5)
    local ok = ns.SetFont(b.center, NUM_FONT, px, "THICKOUTLINE")
    if not ok then
        ok = ns.SetFont(b.center, (b.center:GetFont()), px, "THICKOUTLINE")
    end
    b.center:SetText(text)
    b.center:Show()
end
function ns.Fill(f, layer, r, g, b, a)
    if type(r) == "table" then r, g, b, a = r[1], r[2], r[3], r[4] end
    local t = f:CreateTexture(nil, layer)
    ns.Paint(t, r, g, b, a or 1)
    return t
end
function ns.PlainFrame(parent, level)
    local f = ns.NewFrame("Frame", nil, parent)
    f:SetFrameLevel(parent:GetFrameLevel() + level)
    return f
end
function ns.PlaceTex(tex, anchor, w, h, dy)
    if w < 1 then w = 1 end
    if h < 1 then h = 1 end
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", anchor, "CENTER", 0, dy or 0)
    tex:SetWidth(w)
    tex:SetHeight(h)
end
function ns.CellDim(b, k)
    k = k or 1
    local e = b._edge
    if e then b:SetBackdropBorderColor(e[1], e[2], e[3], e[4] * k) end
    b.slot:SetAlpha(k)
end
function ns.ResetCell(b)
    b.tipItem, b.tipSpell, b.tipTitle, b.tip, b.tipColor = nil, nil, nil, nil, nil
    b.onClick, b.onEnter, b.onLeave = nil, nil, nil
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b.count:Hide()
    b.check:Hide()
    b.center:Hide()
    b.icon:SetVertexColor(1, 1, 1)
    b.icon:SetAlpha(1)
    b.icon:SetTexture(nil)
    ns.CellDim(b, nil)
end
ns.CELL_CROP  = { 0.07, 0.93, 0.07, 0.93 }
ns.CELL_HL    = "Interface\\Buttons\\ButtonHilight-Square"
ns.CELL_FRAME = FRAME_COLOR
function ns.CropIcon(tex)
    tex:SetTexCoord(ns.CELL_CROP[1], ns.CELL_CROP[2], ns.CELL_CROP[3], ns.CELL_CROP[4])
end
local SMALL = { 24, 32 }
local ladder
function ns.CellLadder()
    if ladder then return ladder end
    ladder = { SMALL[1], SMALL[2] }
    for _, v in ipairs(ns.Config.CELL_SIZES) do
        ladder[#ladder + 1] = v
    end
    return ladder
end
function ns.CellStep(px)
    local L = ns.CellLadder()
    local i = 1
    for k = 1, #L do
        if L[k] <= px then i = k end
    end
    return i
end
function ns.CellSize(delta)
    local L = ns.CellLadder()
    local i = ns.CellStep(ns.Config.CellSize()) + (delta or 0)
    if i < 1 then i = 1 end
    if i > #L then i = #L end
    return L[i]
end
function ns.CellFit(n, avail, gap, delta)
    gap = gap or 0
    local L = ns.CellLadder()
    local i = ns.CellStep(ns.Config.CellSize()) + (delta or 0)
    if i < 1 then i = 1 end
    if i > #L then i = #L end
    while i > 1 and n * L[i] + (n - 1) * gap > avail do
        i = i - 1
    end
    local cell = L[i]
    return cell, (n * cell + (n - 1) * gap <= avail)
end
function ns.SizeCell(b, cell, border)
    b:SetWidth(cell); b:SetHeight(cell)
    local icon, inset = ns.Config.IconFit(cell, border or 0)
    b.icon:ClearAllPoints()
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", inset, -inset)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -inset, inset)
    if b._style == "slot" then
        local s = icon * SLOT_SCALE
        b.slot:SetWidth(s); b.slot:SetHeight(s)
    end
    return icon, inset
end
local DISC_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local Mini = {}
Mini.__index = Mini
function Mini:Cell(c, r)
    local key = r * 100 + c
    local f = self.cells[key]
    if f then return f end
    f = ns.PlainFrame(self.frame, 1)
    f:SetWidth(self.cell)
    f:SetHeight(self.cell)
    f:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT",
        (c - 1) * (self.cell + self.gap), (r - 1) * (self.cell + self.gap))
    self.cells[key] = f
    return f
end
function Mini:Fill(c, r, col)
    local f = self:Cell(c, r)
    if not f.bg then
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(f)
    end
    ns.Paint(f.bg, col[1], col[2], col[3], col[4] or 1)
    f.bg:Show()
end
function Mini:Ring(c, r, alpha)
    local f = self:Cell(c, r)
    if not f.ring then
        f.ring = f:CreateTexture(nil, "BORDER")
        f.ring:SetTexture(ns.CELL_HL)
        f.ring:SetBlendMode("ADD")
        f.ring:SetAllPoints(f)
    end
    f.ring:SetAlpha(alpha or 0.75)
    f.ring:Show()
end
function Mini:Dot(c, r, col, frac)
    local f = self:Cell(c, r)
    if not f.dot then
        f.dot = f:CreateTexture(nil, "OVERLAY")
        f.dot:SetTexture(DISC_TEX)
        f.dot:SetPoint("CENTER", f, "CENTER", 0, 0)
    end
    local d = math.floor(self.cell * (frac or 0.3) + 0.5)
    if d < 2 then d = 2 end
    f.dot:SetWidth(d)
    f.dot:SetHeight(d)
    f.dot:SetVertexColor(col[1], col[2], col[3], col[4] or 1)
    f.dot:Show()
end
function Mini:Icon(c, r, path, crop)
    local f = self:Cell(c, r)
    if not f.art then
        f.art = f:CreateTexture(nil, "ARTWORK")
        f.art:SetPoint("CENTER", f, "CENTER", 0, 0)
    end
    local d = self.cell - 2
    f.art:SetWidth(d)
    f.art:SetHeight(d)
    f.art:SetTexture(path)
    if crop then ns.CropIcon(f.art) else f.art:SetTexCoord(0, 1, 0, 1) end
    f.art:SetVertexColor(1, 1, 1, 1)
    f.art:Show()
end
function Mini:Text(c, r, text, col, font)
    local f = self:Cell(c, r)
    if not f.fs then
        f.fs = f:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
        f.fs:SetPoint("CENTER", f, "CENTER", 0, 0)
    end
    f.fs:SetText(text)
    if col then f.fs:SetTextColor(col[1], col[2], col[3]) end
    f.fs:Show()
end
function Mini:Arrow(c1, r1, c2, r2, col)
    local step = self.cell + self.gap
    local x1 = (c1 - 0.5) * step
    local y1 = (r1 - 0.5) * step
    local x2 = (c2 - 0.5) * step
    local y2 = (r2 - 0.5) * step
    local n = 5
    for k = 1, n do
        local t = k / (n + 1)
        local d = math.floor(self.cell * (0.10 + 0.06 * t) + 0.5)
        if d < 2 then d = 2 end
        local dot = self.frame:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(DISC_TEX)
        dot:SetWidth(d)
        dot:SetHeight(d)
        dot:SetPoint("CENTER", self.frame, "BOTTOMLEFT",
            x1 + (x2 - x1) * t, y1 + (y2 - y1) * t)
        dot:SetVertexColor(col[1], col[2], col[3], col[4] or 1)
    end
end
function Mini:Size()
    return self.frame:GetWidth(), self.frame:GetHeight()
end
function ns.MiniGrid(host, cols, rows, cell, gap)
    gap = gap or 0
    local g = setmetatable({ cols = cols, rows = rows, cell = cell, gap = gap,
                             cells = {} }, Mini)
    g.frame = ns.PlainFrame(host, 1)
    g.frame:SetWidth(cols * cell + (cols - 1) * gap)
    g.frame:SetHeight(rows * cell + (rows - 1) * gap)
    g.frame:SetPoint("CENTER", host, "CENTER", 0, 0)
    return g
end
function ns.MiniChecker(g, dark, light)
    for r = 1, g.rows do
        for c = 1, g.cols do
            g:Fill(c, r, ((r + c) % 2 == 0) and dark or light)
        end
    end
end
function ns.MiniPlain(g, face)
    for r = 1, g.rows do
        for c = 1, g.cols do
            g:Fill(c, r, face)
        end
    end
end
