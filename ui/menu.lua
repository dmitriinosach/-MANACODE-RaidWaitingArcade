local ADDON, ns = ...
local PAD   = ns.Space.pad
local GAP   = ns.Space.gap
local INSET = ns.Space.inset
local CAP_H = ns.Space.cap
local TILE_H      = 52
local TILE_MAX_W  = 220
local TILE_PAD_X  = 10
local ICON_SZ     = 36
local ICON_GAP    = 10
local PAGER_H     = 22
local SHEEN_TEX  = "Interface\\Buttons\\WHITE8X8"
local HALO_TEX   = "Interface\\Buttons\\UI-ActionButton-Border"
local SHEEN_SPAN = 0.62
local SHEEN_A    = 0.22
local HALO_OVER  = 22
local HALO_A     = 0.7
local LINK_SZ    = 28
local LINK_GAP   = 12
local LINK_CAP_H = 12
local ADDR_H     = 18
local ADDR_PAD   = 7
local ADDR_KEY   = { 0.72, 0.65, 0.50 }
local LINK_DIM   = 0.45
local LINKS_H    = LINK_SZ + 2 + LINK_CAP_H + 4 + ADDR_H
local ADDR_BACKDROP = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local Menu = {}
ns.menu = Menu
local frame, games, pool, links, devRow
local probe
local function styleTile(t)
    local th = ns.CurrentTheme().tile
    local bg = t.hovered and th.bgHover or th.bg
    local br = t.hovered and th.borderHover or th.border
    t:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    t:SetBackdropBorderColor(br[1], br[2], br[3], br[4])
    t.label:SetTextColor(unpack(t.hovered and th.titleHover or th.title))
end
local function glowTile(t, on)
    if on then
        local g = ns.CurrentTheme().tile.glow
        t.sheen:SetGradientAlpha("HORIZONTAL", g[1], g[2], g[3], SHEEN_A, g[1], g[2], g[3], 0)
        t.halo:SetVertexColor(g[1], g[2], g[3], HALO_A)
        t.sheen:Show()
        t.halo:Show()
    else
        t.sheen:Hide()
        t.halo:Hide()
    end
end
local function makeTile(parent)
    local t = CreateFrame("Button", nil, parent)
    t:SetBackdrop(ns.CurrentTheme().tile.backdrop)
    t.sheen = t:CreateTexture(nil, "BORDER")
    t.sheen:SetTexture(SHEEN_TEX)
    t.sheen:SetBlendMode("ADD")
    t.sheen:SetPoint("TOPLEFT", t, "TOPLEFT", 5, -5)
    t.sheen:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 5, 5)
    t.sheen:Hide()
    t.cell = ns.MakeCell(t)
    t.cell:EnableMouse(false)
    ns.StyleCell(t.cell, "framed")
    t.cell:SetWidth(ICON_SZ); t.cell:SetHeight(ICON_SZ)
    t.cell:SetPoint("LEFT", t, "LEFT", TILE_PAD_X, 0)
    t.halo = t:CreateTexture(nil, "BORDER")
    t.halo:SetTexture(HALO_TEX)
    t.halo:SetBlendMode("ADD")
    t.halo:SetWidth(ICON_SZ + HALO_OVER); t.halo:SetHeight(ICON_SZ + HALO_OVER)
    t.halo:SetPoint("CENTER", t.cell, "CENTER", 0, 0)
    t.halo:Hide()
    t.cell.art = CreateFrame("Frame", nil, t.cell)
    t.cell.art:SetFrameLevel(t.cell:GetFrameLevel() + 1)
    t.cell.art:SetPoint("TOPLEFT", t.cell, "TOPLEFT", 2, -2)
    t.cell.art:SetPoint("BOTTOMRIGHT", t.cell, "BOTTOMRIGHT", -2, 2)
    t.cell.art:Hide()
    t.label = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.label:SetPoint("LEFT", t.cell, "RIGHT", ICON_GAP, 0)
    t.label:SetJustifyH("LEFT")
    t:SetScript("OnEnter", function(self)
        self.hovered = true
        styleTile(self)
        glowTile(self, true)
        ns.TipShow(self)
    end)
    t:SetScript("OnLeave", function(self)
        self.hovered = false
        styleTile(self)
        glowTile(self, false)
        ns.TipHide()
    end)
    styleTile(t)
    return t
end
local function bare(parent, caption)
    local p = CreateFrame("Frame", nil, parent)
    if caption then
        p.cap = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        p.cap:SetPoint("TOPLEFT", p, "TOPLEFT", ns.Space.inset, -9)
        p.cap:SetText(caption)
    end
    return p
end
local function paintWeave()
    local wv = ns.CurrentTheme().weave
    if wv then
        games:SetBackdrop(wv.backdrop)
        games:SetBackdropColor(wv.color[1], wv.color[2], wv.color[3], wv.color[4])
    else
        games:SetBackdrop(nil)
    end
end
ns.menuDev = {}
function ns.RegisterMenuDev(def)
    if type(def) ~= "table" or type(def.run) ~= "function" then return end
    ns.menuDev[#ns.menuDev + 1] = def
end
local function buildDevRow(parent)
    if #ns.menuDev == 0 then return end
    local foot = ns.window:Frame().devFoot
    devRow = CreateFrame("Frame", nil, parent)
    devRow:SetHeight(ns.Space.ctl)
    devRow:SetPoint("RIGHT", foot, "RIGHT", -8, 0)
    devRow:SetFrameLevel(foot:GetFrameLevel() + 5)
    local prev
    for _, d in ipairs(ns.menuDev) do
        local b = ns.MakeKitButton(devRow)
        b:SetHeight(ns.Space.ctl)
        if d.text then b.devText = d.text end
        if d.clicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
        b:SetText(d.text and d.text() or (d.label or "?"))
        b:SetWidth(math.max(72, b.text:GetStringWidth() + 22))
        b.tipTitle = d.label
        b.tip = d.tip
        b.tipDim = d.tipDim
        b.onClick = function(self, button)
            d.run(button)
            if self.devText then self:SetText(self.devText()) end
        end
        if prev then
            b:SetPoint("RIGHT", prev, "LEFT", -ns.Space.row, 0)
        else
            b:SetPoint("RIGHT", devRow, "RIGHT", 0, 0)
        end
        prev = b
    end
    devRow:Hide()
end
local function showAddr(p, url)
    p.addr.url = url
    p.addr:SetText(url)
    p.addr:SetCursorPosition(0)
end
local function markLinks(p)
    local th = ns.CurrentTheme().tile
    for i, c in ipairs(p.cells) do
        local on = (p.chosen == nil) or (i == p.chosen)
        ns.CellDim(c, on and 1 or LINK_DIM)
        c.icon:SetAlpha(on and 1 or 0.6)
        c.cap:SetTextColor(unpack(i == p.chosen and th.titleHover or th.title))
    end
end
local function hideAddr(p)
    p.chosen = nil
    p.addr:ClearFocus()
    p.box:Hide()
    markLinks(p)
end
local function chooseLink(p, i)
    local item = ns.About.Links()[i]
    if not item then return end
    p.chosen = i
    p.box:Show()
    showAddr(p, item.url)
    markLinks(p)
    p.addr:SetFocus()
    p.addr:HighlightText()
end
local function buildLinks(parent)
    local list = ns.About and ns.About.Links() or {}
    if #list == 0 then return nil end
    local p = CreateFrame("Frame", nil, parent)
    p:SetHeight(LINKS_H)
    p:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", PAD, PAD)
    p:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PAD, PAD)
    p.ver = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.ver:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -8)
    p.ver:SetJustifyH("RIGHT")
    p.box = CreateFrame("Frame", nil, p)
    p.box:SetHeight(ADDR_H)
    p.box:SetPoint("BOTTOM", p, "BOTTOM", 0, 0)
    p.box:SetBackdrop(ADDR_BACKDROP)
    p.key = p.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.key:SetPoint("RIGHT", p.box, "RIGHT", -ADDR_PAD, 0)
    p.probe = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p.probe:Hide()
    p.addr = CreateFrame("EditBox", nil, p.box)
    p.addr:SetFrameLevel(p.box:GetFrameLevel() + 1)
    p.addr:SetHeight(ADDR_H - 4)
    p.addr:SetPoint("LEFT", p.box, "LEFT", ADDR_PAD, 0)
    p.addr:SetPoint("RIGHT", p.key, "LEFT", -ADDR_PAD, 0)
    p.addr:EnableMouse(true)
    p.addr:SetAutoFocus(false)
    p.addr:SetFontObject("GameFontHighlightSmall")
    p.addr:SetJustifyH("LEFT")
    p.addr:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    p.addr:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetCursorPosition(0)
    end)
    p.addr:SetScript("OnTextChanged", function(self)
        if self.url and self:GetText() ~= self.url then self:SetText(self.url) end
    end)
    p.addr:SetScript("OnEscapePressed", function() hideAddr(p) end)
    p.box:Hide()
    p.cells = {}
    for i, item in ipairs(list) do
        local c = ns.MakeCell(p)
        p.cells[i] = c
        ns.StyleCell(c, "framed")
        c:SetWidth(LINK_SZ); c:SetHeight(LINK_SZ)
        c.icon:SetTexture(ns.IconPath(item.icon))
        c.cap = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        c.cap:SetPoint("TOP", c, "BOTTOM", 0, -2)
        c.onClick = function()
            ns.Sfx.Ui("open")
            if p.chosen == i then hideAddr(p) else chooseLink(p, i) end
        end
    end
    return p
end
local function versionText()
    local new = ns.Version.Newest()
    if new then return ns.T("linkUpdate", new) end
    return ns.Version.Mine()
end
local function linkTexts()
    if not links then return end
    links.ver:SetText(versionText())
    local th = ns.CurrentTheme().tile
    links.box:SetBackdropColor(unpack(th.bg))
    links.box:SetBackdropBorderColor(unpack(th.border))
    links.key:SetText(ns.T("linkCopy"))
    links.key:SetTextColor(ADDR_KEY[1], ADDR_KEY[2], ADDR_KEY[3])
    local list = ns.About.Links()
    local wide = 0
    for _, item in ipairs(list) do
        links.probe:SetText(item.url)
        local w = links.probe:GetStringWidth() or 0
        if w > wide then wide = w end
    end
    local boxW = math.ceil(wide + (links.key:GetStringWidth() or 0) + ADDR_PAD * 3 + 6)
    local room = links:GetWidth() or 0
    if room > 0 and boxW > room then boxW = room end
    links.box:SetWidth(boxW)
    local step = LINK_SZ + LINK_GAP
    for i, c in ipairs(links.cells) do
        local item = list[i]
        if item then
            c.cap:SetText(item.label)
            c.tipTitle = item.label
            c.tip = ns.T(item.tipKey or "linkTip")
            local w = (c.cap:GetStringWidth() or 0) + LINK_GAP
            if w > step then step = w end
        end
    end
    local n = #links.cells
    for i, c in ipairs(links.cells) do
        c:ClearAllPoints()
        c:SetPoint("TOP", links, "TOP", (i - (n + 1) / 2) * step, 0)
    end
    local cur = links.chosen and list[links.chosen]
    if cur and not links.addr:HasFocus() then showAddr(links, cur.url) end
    markLinks(links)
end
local function build()
    local parent = ns.window:Frame()
    local canvas = ns.window:Canvas()
    frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(canvas)
    links = buildLinks(frame)
    if ns.Murloc then
        local cage = ns.Murloc.Mount(frame)
        if links then
            cage:SetPoint("TOPLEFT", links, "TOPLEFT", 0, 0)
        else
            cage:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
        end
    end
    if ns.Dev then buildDevRow(frame) end
    games = bare(frame)
    games:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    games:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD,
        PAD + (links and LINKS_H + GAP or 0))
    paintWeave()
    ns.SlideAnchor("shell.games", games)
    games.empty = games:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    games.empty:SetPoint("CENTER", games, "CENTER", 0, 0)
    games.empty:SetText(ns.T("menuEmpty"))
    games.empty:Hide()
    probe = games:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    probe:Hide()
    games.pager = CreateFrame("Frame", nil, games)
    games.pager:SetHeight(PAGER_H)
    games.pager:SetPoint("BOTTOMLEFT", games, "BOTTOMLEFT", INSET, INSET - 4)
    games.pager:SetPoint("BOTTOMRIGHT", games, "BOTTOMRIGHT", -INSET, INSET - 4)
    games.pager:Hide()
    games.prev = ns.MakeKitButton(games.pager)
    games.prev:SetWidth(30)
    games.prev:SetPoint("LEFT", games.pager, "LEFT", 0, 0)
    games.prev:SetText("<")
    games.prev.tipTitle = ns.T("menuPrev")
    games.prev.tip = ns.T("menuTurnTip")
    games.prev.onClick = function() Menu:Turn(-1) end
    games.next = ns.MakeKitButton(games.pager)
    games.next:SetWidth(30)
    games.next:SetPoint("RIGHT", games.pager, "RIGHT", 0, 0)
    games.next:SetText(">")
    games.next.tipTitle = ns.T("menuNext")
    games.next.tip = ns.T("menuTurnTip")
    games.next.onClick = function() Menu:Turn(1) end
    games.pageText = games.pager:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    games.pageText:SetPoint("CENTER", games.pager, "CENTER", 0, 0)
    games:EnableMouseWheel(true)
    games:SetScript("OnMouseWheel", function(_, delta) Menu:Turn(-delta) end)
    pool = ns.NewPool(function() return makeTile(games) end)
end
local function ensure()
    if not frame then build() end
end
function ns.ArtFill(host, i, layer)
    host.fills = host.fills or {}
    local t = host.fills[i]
    if not t then
        t = host:CreateTexture(nil, "ARTWORK")
        host.fills[i] = t
    end
    t:SetDrawLayer(layer or "ARTWORK")
    t:ClearAllPoints()
    t:Show()
    return t
end
function ns.ArtText(host, i, layer)
    host.texts = host.texts or {}
    local fs = host.texts[i]
    if not fs then
        fs = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        host.texts[i] = fs
    end
    fs:SetDrawLayer(layer or "OVERLAY")
    fs:ClearAllPoints()
    fs:Show()
    return fs
end
function ns.ArtClear(host)
    if host.fills then for _, t in ipairs(host.fills) do t:Hide() end end
    if host.texts then for _, t in ipairs(host.texts) do t:Hide() end end
end
local function setIcon(cell, ic)
    ns.ArtClear(cell.art)
    if type(ic) == "table" and ic.draw then
        cell.icon:SetTexture(nil)
        cell.art:Show()
        ic.draw(cell.art, (cell:GetWidth() or ICON_SZ) - 4)
        return
    end
    cell.art:Hide()
    if type(ic) == "table" then
        cell.icon:SetTexture(ic.tex or ns.QMARK)
        local c = ic.coord
        if c then cell.icon:SetTexCoord(c[1], c[2], c[3], c[4])
        else cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
    else
        cell.icon:SetTexture(type(ic) == "number" and ns.Icons.Item(ic) or ic or ns.QMARK)
        cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
end
local function tileMinWidth(list)
    local w = 0
    for _, def in ipairs(list) do
        probe:SetText(def.label or def.id)
        local need = probe:GetStringWidth()
        if need > w then w = need end
    end
    return math.ceil(w) + TILE_PAD_X * 2 + ICON_SZ + ICON_GAP
end
local function layout()
    ensure()
    linkTexts()
    pool:Reset()
    local list = ns.MenuList()
    local n = #list
    if n == 0 then
        games.empty:Show()
        pool:HideExtras()
        games.pager:Hide()
        return
    end
    games.empty:Hide()
    local canvas = ns.window:Canvas()
    local areaW = canvas.W - PAD * 2
    local panelH = canvas.H - PAD * 2 - (links and LINKS_H + GAP or 0)
    local fullH = panelH
    local function fitRows(h)
        local r = math.floor((h + GAP) / (TILE_H + GAP))
        return r < 1 and 1 or r
    end
    local function fitFor(cols)
        local rows, h = fitRows(fullH), fullH
        if n > cols * rows then
            h = fullH - PAGER_H - GAP
            rows = fitRows(h)
        end
        return rows, h
    end
    local minW = tileMinWidth(list)
    local fit = math.floor((areaW + GAP) / (minW + GAP))
    if fit < 1 then fit = 1 end
    local cols, pages, rows, areaH, skew = 1, nil, nil, nil, nil
    for c = 1, fit do
        local r, h = fitFor(c)
        local p = math.ceil(n / (c * r))
        local used = math.ceil(math.min(n, c * r) / c)
        local sk = math.abs(c - used)
        if pages == nil or p < pages or (p == pages and sk < skew) then
            cols, pages, rows, areaH, skew = c, p, r, h, sk
        end
    end
    local tileW = math.floor((areaW - (cols - 1) * GAP) / cols)
    if tileW > TILE_MAX_W then tileW = TILE_MAX_W end
    local perPage = cols * rows
    local page = Menu.page or 1
    if page > pages then page = pages end
    if page < 1 then page = 1 end
    Menu.page = page
    local first = (page - 1) * perPage + 1
    local last = math.min(n, page * perPage)
    local shown = last - first + 1
    local usedRows = math.ceil(shown / cols)
    local tileH = TILE_H
    local blockH = usedRows * tileH + (usedRows - 1) * GAP
    local y0 = math.floor((areaH - blockH) / 2)
    for i = first, last do
        local def = list[i]
        local t = pool:Acquire()
        local k = i - first
        local col = k % cols
        local row = math.floor(k / cols)
        local inRow = shown - row * cols
        if inRow > cols then inRow = cols end
        local rowW = inRow * tileW + (inRow - 1) * GAP
        local x0 = math.floor((areaW - rowW) / 2)
        t:SetSize(tileW, tileH)
        t.label:SetWidth(tileW - TILE_PAD_X * 2 - ICON_SZ - ICON_GAP)
        t.sheen:SetWidth(math.floor((tileW - 10) * SHEEN_SPAN))
        t.sheen:Hide()
        t.halo:Hide()
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", games, "TOPLEFT",
            x0 + col * (tileW + GAP),
            -(y0 + row * (tileH + GAP)))
        styleTile(t)
        setIcon(t.cell, def.icon)
        t.tipName = def.label or def.id
        t.label:SetText(t.tipName)
        t.tip = def.tip
        t:SetScript("OnClick", function()
            ns.Sfx.Ui()
            ns.window:StartGame(def.id, nil, ns.Store.HasSaved(def.id))
        end)
    end
    pool:HideExtras()
    if pages > 1 then
        games.pageText:SetText(ns.T("menuPage", page, pages))
        if page > 1 then games.prev:Enable() else games.prev:Disable() end
        if page < pages then games.next:Enable() else games.next:Disable() end
        games.pager:Show()
    else
        games.pager:Hide()
    end
end
function Menu:Turn(d)
    self.page = (self.page or 1) + d
    layout()
end
function Menu:Refresh()
    if not (frame and frame:IsShown()) then return end
    self.page = 1
    layout()
end
local function hideOverlays()
    if ns.PrefsUI then ns.PrefsUI.Hide() end
end
function Menu:Show()
    ensure()
    hideOverlays()
    if links then hideAddr(links) end
    if devRow then
        if ns.Dev.On() then devRow:Show() else devRow:Hide() end
    end
    layout()
    frame:Show()
end
function Menu:Hide()
    ensure()
    hideOverlays()
    frame:Hide()
end
ns.OnTheme(function()
    if not frame then return end
    paintWeave()
    if frame:IsShown() then layout() end
end)
ns.Version.OnNew(function()
    if links and frame and frame:IsShown() then links.ver:SetText(versionText()) end
end)
ns.OnLocale(function()
    if not frame then return end
    games.empty:SetText(ns.T("menuEmpty"))
    games.prev.tipTitle = ns.T("menuPrev")
    games.prev.tip = ns.T("menuTurnTip")
    games.next.tipTitle = ns.T("menuNext")
    games.next.tip = ns.T("menuTurnTip")
    if frame:IsShown() then layout() end
end)
