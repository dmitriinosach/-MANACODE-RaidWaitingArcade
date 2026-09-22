local ADDON, ns = ...
local WIDTH  = 300
local HEIGHT = 152
local DIM_A  = 0.55
local BTN_MIN = 96
local BTN_GAP = 8
local BTN_Y   = 14
local PAD     = 16
ns.Over = {}
local overlay, card, ui, bestLine
local function ensure()
    if overlay then return end
    local win = ns.window:Frame()
    if not win then return end
    overlay = ns.NewFrame("Frame", nil, win)
    overlay:SetAllPoints(win)
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:EnableMouse(true)
    overlay:Hide()
    local dim = overlay:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints()
    ns.Paint(dim, 0, 0, 0, DIM_A)
    card = ns.NewFrame("Frame", nil, overlay)
    card:SetWidth(WIDTH)
    card:SetHeight(HEIGHT)
    card:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    ns.DressCard(card)
    ui = {}
    ui.title = ns.TitleText(card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    ui.title:SetPoint("TOP", card, "TOP", 0, -14)
    ui.title:SetText(ns.T("overTitle"))
    ui.game = ns.TitleText(card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    ui.game:SetPoint("TOP", ui.title, "BOTTOM", 0, -4)
    ui.score = ns.TitleText(card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    ui.score:SetPoint("TOP", ui.game, "BOTTOM", 0, -12)
    ui.best = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.best:SetPoint("TOP", ui.score, "BOTTOM", 0, -6)
    ui.best:SetWidth(WIDTH - 24)
    ui.best:SetJustifyH("CENTER")
    ui.best:SetText("0")
    bestLine = ui.best:GetStringHeight() or 0
    ui.best:SetText("")
    ui.again = ns.MakeKitButton(card)
    ui.again:SetHeight(24)
    ui.own = ns.MakeKitButton(card)
    ui.own:SetHeight(24)
    ui.menu = ns.MakeKitButton(card)
    ui.menu:SetHeight(24)
end
local function layoutRow(row)
    local total = 0
    for i = 1, #row do
        local w = (row[i].text:GetStringWidth() or 0) + 24
        if w < BTN_MIN then w = BTN_MIN end
        w = math.ceil(w)
        row[i].rowW = w
        total = total + w
    end
    total = total + BTN_GAP * (#row - 1)
    local width = total + PAD * 2
    if width < WIDTH then width = WIDTH end
    card:SetWidth(width)
    local x = -total / 2
    for i = 1, #row do
        local b = row[i]
        b:SetWidth(b.rowW)
        b:ClearAllPoints()
        b:SetPoint("BOTTOMLEFT", card, "BOTTOM", x, BTN_Y)
        b:Show()
        x = x + b.rowW + BTN_GAP
    end
    return width
end
function ns.Over.Show(o)
    ensure()
    if not overlay then return end
    ns.Restyle(card, ns.GameLook())
    ui.game:SetText(o.game or "")
    ui.score:SetText(o.result or "")
    ui.again:SetText(ns.T("overAgain"))
    ui.own:SetText(ns.T("overOwn"))
    ui.menu:SetText(ns.T("overMenu"))
    local row = { ui.again }
    if o.onOwn then row[#row + 1] = ui.own else ui.own:Hide() end
    row[#row + 1] = ui.menu
    local width = layoutRow(row)
    ui.best:SetWidth(width - 24)
    if o.unranked then
        ui.best:SetText(type(o.unranked) == "string"
            and ns.T("overUnrankedWhy", o.unranked) or ns.T("overUnranked"))
        ui.best:SetTextColor(0.85, 0.65, 0.2)
    elseif o.isBest then
        ui.best:SetText(ns.T("overBest"))
        ui.best:SetTextColor(0.27, 0.8, 0.27)
    elseif o.best then
        ui.best:SetText(o.best)
        ui.best:SetTextColor(0.6, 0.6, 0.6)
    else
        ui.best:SetText("")
    end
    local grown = (ui.best:GetStringHeight() or 0) - bestLine
    card:SetHeight(HEIGHT + (grown > 0 and grown or 0))
    ui.again.onClick = o.onAgain
    ui.own.onClick = o.onOwn
    ui.menu.onClick = o.onMenu
    overlay:Show()
end
function ns.Over.Hide()
    if overlay then overlay:Hide() end
end
function ns.Over.IsShown()
    return overlay and overlay:IsShown() and true or false
end
