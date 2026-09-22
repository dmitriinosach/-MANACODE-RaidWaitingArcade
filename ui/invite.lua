local ADDON, ns = ...
ns.Invite = {}
local WIDTH = 268
local FADE_IN, FADE_OUT = 0.3, 0.4
local BTN_W, BTN_H = 76, 22
local BTN_GAP = ns.Space.row
local PAD = 12
local INSET = 5
local GAP = 10
local CAP_Y, RULE_Y, TEXT_Y = 10, 28, 36
local ICON = 20
local CLASS_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local NOTIFY = "TellMessage"
local DOCK_GAP = 6
local plate
local shown
local docked
local function atWindow()
    return (ns.window and ns.window.IsShown and ns.window:IsShown()) and true or false
end
local function place(f)
    docked = atWindow()
    f:ClearAllPoints()
    if not docked then
        f:SetPoint("TOP", ns.News.Tail(), "TOP", 0, 0)
        return
    end
    local win = ns.window:Frame()
    local room = win:GetBottom()
    if room and room < f:GetHeight() + DOCK_GAP then
        f:SetPoint("BOTTOMRIGHT", win, "TOPRIGHT", 0, DOCK_GAP)
    else
        f:SetPoint("TOPRIGHT", win, "BOTTOMRIGHT", 0, -DOCK_GAP)
    end
end
local function build()
    local f = ns.NewFrame("Frame", "RaidWaitingArcadeInvite", UIParent)
    f:SetWidth(WIDTH)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetFrameLevel(200)
    f:SetClampedToScreen(true)
    ns.DressCard(f)
    f:EnableMouse(true)
    f:Hide()
    f.body = f:CreateTexture(nil, "BORDER")
    f.body:SetPoint("TOPLEFT", f, "TOPLEFT", INSET, -INSET)
    f.body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -INSET, INSET)
    f.cap = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.cap:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -CAP_Y)
    f.cap:SetJustifyH("LEFT")
    f.rule = f:CreateTexture(nil, "ARTWORK")
    f.rule:SetHeight(1)
    f.rule:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -RULE_Y)
    f.rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -RULE_Y)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetWidth(ICON); f.icon:SetHeight(ICON)
    f.icon:SetTexture(CLASS_TEX)
    f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -TEXT_Y)
    f.icon:Hide()
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -TEXT_Y)
    f.text:SetJustifyH("LEFT")
    f.yes = ns.MakeKitButton(f)
    f.yes:SetWidth(BTN_W); f.yes:SetHeight(BTN_H)
    f.yes:SetText(ns.T("duoYes"))
    f.yes.tip = ns.T("duoYesTip")
    f.yes.onClick = function()
        local fn = shown and shown.onYes
        ns.Invite.Hide()
        if fn then fn() end
    end
    f.no = ns.MakeKitButton(f)
    f.no:SetWidth(BTN_W); f.no:SetHeight(BTN_H)
    f.no:SetText(ns.T("duoNo"))
    f.no.tip = ns.T("duoNoTip")
    f.no.onClick = function()
        local fn = shown and shown.onNo
        ns.Invite.Hide()
        if fn then fn("no") end
    end
    f.block = ns.MakeKitButton(f)
    f.block:SetWidth(BTN_W); f.block:SetHeight(BTN_H)
    f.block:SetText(ns.T("pairBlock"))
    f.block.tip = ns.T("pairBlockTip")
    f.block.onClick = function()
        local fn = shown and shown.onNo
        local who = shown and shown.who
        ns.Invite.Hide()
        if who then ns.Ignore.Add(who) end
        if fn then fn("block") end
    end
    for _, b in ipairs({ f.yes, f.no, f.block }) do
        b:SetFrameLevel(f:GetFrameLevel() + 6)
    end
    f:SetScript("OnUpdate", function(self, elapsed)
        if not shown then return end
        if docked ~= atWindow() then place(self) end
        if shown.fade == "in" then
            shown.alpha = shown.alpha + elapsed / FADE_IN
            if shown.alpha >= 1 then shown.alpha, shown.fade = 1, nil end
            self:SetAlpha(shown.alpha)
        elseif shown.fade == "out" then
            shown.alpha = shown.alpha - elapsed / FADE_OUT
            if shown.alpha <= 0 then
                shown = nil
                self:Hide()
                return
            end
            self:SetAlpha(shown.alpha)
            return
        end
        if shown.deadline and GetTime() >= shown.deadline then
            local fn = shown.onNo
            ns.Invite.Hide()
            if fn then fn("timeout") end
        end
    end)
    return f
end
local function paint()
    if not plate then return end
    local th = ns.CurrentTheme()
    ns.PaintBody(plate.body, th.window.body, 1)
    local r = th.rule
    ns.Paint(plate.rule, r[1], r[2], r[3], r[4] or 1)
    plate.cap:SetTextColor(ns.Accent())
end
local function ensure()
    if not plate then
        plate = build()
        paint()
    end
    return plate
end
ns.OnTheme(paint)
local function dressIcon(f, who)
    local cls = who and ns.Link.PeerClass(who) or nil
    local tc = cls and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
    f.text:ClearAllPoints()
    f.text:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -TEXT_Y)
    if not tc then
        f.icon:Hide()
        f.text:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -TEXT_Y)
        return false
    end
    f.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    f.icon:Show()
    f.text:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + 8, -TEXT_Y)
    return true
end
local function put(text, buttons, seconds, who, face)
    local f = ensure()
    f:ClearAllPoints()
    local win = ns.window and ns.window:IsShown() and ns.window:Frame()
    if win then
        f:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, PAD)
    else
        local side = ns.News.Up() and "BOTTOM" or "TOP"
        f:SetPoint(side, ns.News.Tail(), side, 0, 0)
    end
    local row = buttons and (who and 3 or 2) or 0
    local list = { f.yes, f.no, f.block }
    local rowW = 0
    for i = 1, row do
        local b = list[i]
        b:SetWidth(math.max(BTN_W, (b.text:GetStringWidth() or 0) + 22))
        rowW = rowW + b:GetWidth() + (i > 1 and BTN_GAP or 0)
    end
    f:SetWidth(math.max(WIDTH, PAD * 2 + rowW))
    f.cap:SetText(face or ns.T("appTitle"))
    dressIcon(f, face)
    f.text:SetText(text)
    local body = f.text:GetStringHeight()
    if f.icon:IsShown() and body < ICON then body = ICON end
    local h = TEXT_Y + body
    if row > 0 then
        local x = -PAD
        for i = row, 1, -1 do
            local b = list[i]
            b:ClearAllPoints()
            b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", x, PAD)
            b:Show()
            x = x - b:GetWidth() - BTN_GAP
        end
        f:SetHeight(h + GAP + BTN_H + PAD)
    else
        f:SetHeight(h + PAD)
    end
    for i = row + 1, #list do list[i]:Hide() end
    shown = { fade = "in", alpha = 0, who = who,
              deadline = seconds and (GetTime() + seconds) or nil }
    place(f)
    f:SetAlpha(0)
    f:Show()
    return shown
end
function ns.Invite.Ask(who, label, seconds, onYes, onNo, detail, foe)
    local text
    if detail and detail ~= "" then
        text = ns.T("duoAskOpts", who, label, detail)
    else
        text = ns.T("duoAsk", who, label)
    end
    local s = put(text, true, seconds, foe and who or nil, who)
    s.onYes, s.onNo = onYes, onNo
    ns.Sounds.Play(NOTIFY)
end
function ns.Invite.AskPair(who, seconds, onYes, onNo)
    local s = put(ns.T("pairAsk", who), true, seconds, who, who)
    s.onYes, s.onNo = onYes, onNo
    ns.Sounds.Play(NOTIFY)
end
function ns.Invite.Note(text, seconds)
    ns.News.Push{ text = text, life = seconds }
end
function ns.Invite.Hide()
    if not shown then return end
    shown.onYes, shown.onNo, shown.deadline, shown.who = nil, nil, nil, nil
    shown.fade = "out"
end
function ns.Invite.IsShown()
    return (shown and shown.fade ~= "out") and true or false
end
