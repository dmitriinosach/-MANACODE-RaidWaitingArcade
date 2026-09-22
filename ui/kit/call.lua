local ADDON, ns = ...
ns.CallPanel = {}
local P = ns.CallPanel
local VIS = 5
local TABS = { "target", "name", "friends", "guild", "block" }
local TAB_W, TAB_STEP = 86, 90
local PW = 486
local Y_LIST = 86
local H_LIST = 214
local PH_LIST = Y_LIST + H_LIST + 70
local PH_NAME = Y_LIST + 132
local C_NICHE = { 0.075, 0.062, 0.045, 1 }
local C_RULE = { 0.21, 0.18, 0.14, 1 }
local C_TEXT = { 0.91, 0.90, 0.86 }
local C_SOFT = { 0.65, 0.61, 0.53 }
local C_LIVE = { 0.44, 0.75, 0.36 }
local ui
local job
local pending, said
local function fromTarget()
    local name, why = ns.Duo.Target()
    if not name then
        return { { why = why or "duoNoTarget" } }
    end
    return { { name = name } }
end
local function fromFriends()
    local out = {}
    local n = ns.Compat.NumFriends()
    for i = 1, n do
        local name, connected = ns.Compat.FriendInfo(i)
        if type(name) == "string" and name ~= "" and connected then
            out[#out + 1] = { name = name }
        end
    end
    return out
end
local function fromBlock()
    local out = {}
    for _, name in ipairs(ns.Ignore.List()) do
        out[#out + 1] = { name = name, off = true }
    end
    return out
end
local function fromGuild()
    local out = {}
    if not (IsInGuild and IsInGuild()) then
        return out
    end
    local n = GetNumGuildMembers and GetNumGuildMembers() or 0
    for i = 1, n do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if type(name) == "string" and name ~= "" and online and not ns.Link.IsMe(name) then
            out[#out + 1] = { name = name }
        end
    end
    return out
end
local function text(parent, x, y, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    fs:SetJustifyH("LEFT")
    return fs
end
local function plate(parent, col)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(parent)
    ns.Paint(t, col[1], col[2], col[3], col[4] or 1)
    return t
end
local function outline(f, col)
    local function bar(p1, p2, w, h)
        local t = f:CreateTexture(nil, "BORDER")
        ns.Paint(t, col[1], col[2], col[3], col[4] or 1)
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if w then
            t:SetWidth(w)
        end
        if h then
            t:SetHeight(h)
        end
    end
    bar("TOPLEFT", "TOPRIGHT", nil, 1)
    bar("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    bar("TOPLEFT", "BOTTOMLEFT", 1, nil)
    bar("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end
local refresh, call
local function build()
    ui = {}
    ui.dim = ns.NewFrame("Frame", nil, UIParent)
    ui.dim:EnableMouse(true)
    ui.dim:Hide()
    local d = ui.dim:CreateTexture(nil, "BACKGROUND")
    d:SetAllPoints(ui.dim)
    ns.Paint(d, 0.04, 0.035, 0.025, 0.72)
    ui.panel = ns.NewFrame("Frame", nil, ui.dim)
    ui.panel:SetFrameLevel(ui.dim:GetFrameLevel() + 1)
    ui.panel:SetWidth(PW)
    ui.panel:SetHeight(PH_LIST)
    ui.panel:SetPoint("TOPLEFT", ui.dim, "TOPLEFT", 84, -60)
    plate(ui.panel, { 0.102, 0.086, 0.059, 1 })
    outline(ui.panel, { 0.54, 0.42, 0.16, 1 })
    ui.cap = text(ui.panel, 20, 18, "GameFontNormal")
    ui.cap:SetTextColor(0.91, 0.79, 0.49)
    ui.what = ui.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.what:SetPoint("TOPRIGHT", ui.panel, "TOPRIGHT", -46, -20)
    ui.what:SetJustifyH("RIGHT")
    ui.what:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.close = ns.MakeKitButton(ui.panel)
    ui.close:SetWidth(22)
    ui.close:SetHeight(22)
    ui.close:SetPoint("TOPRIGHT", ui.panel, "TOPRIGHT", -14, -14)
    ui.close.text:SetText("X")
    ui.close.tipTitle = false
    ui.close.onClick = function()
        P.Hide()
    end
    ui.tab = {}
    for i, key in ipairs(TABS) do
        local b = ns.MakeKitButton(ui.panel)
        b:SetWidth(TAB_W)
        b:SetHeight(26)
        b:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", 20 + (i - 1) * TAB_STEP, -46)
        b.text:SetText(ns.T("callTab_" .. key))
        b.tipTitle = false
        b.onClick = function()
            ui.tabKey = key
            refresh()
        end
        ui.tab[key] = b
    end
    ui.list = ns.NewFrame("Frame", nil, ui.panel)
    ui.list:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", 20, -Y_LIST)
    ui.list:SetWidth(PW - 40)
    ui.list:SetHeight(H_LIST)
    plate(ui.list, C_NICHE)
    outline(ui.list, C_RULE)
    ui.list:EnableMouseWheel(true)
    ui.list:SetScript("OnMouseWheel", function(_, delta)
        ui.top = (ui.top or 1) - delta
        refresh()
    end)
    ui.cand = {}
    for i = 1, VIS do
        local f = ns.NewFrame("Frame", nil, ui.list)
        f:SetWidth(PW - 52)
        f:SetHeight(38)
        f:SetPoint("TOPLEFT", ui.list, "TOPLEFT", 6, -(8 + (i - 1) * 42))
        f.dot = f:CreateTexture(nil, "OVERLAY")
        ns.Paint(f.dot, 1, 1, 1, 1)
        f.dot:SetWidth(8)
        f.dot:SetHeight(8)
        f.dot:SetPoint("LEFT", f, "LEFT", 10, 0)
        f.name = text(f, 28, 11, "GameFontNormal")
        f.state = text(f, 164, 12)
        f.state:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
        f.call = ns.MakeKitButton(f)
        f.call:SetWidth(84)
        f.call:SetHeight(22)
        f.call:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        f.call.text:SetText(ns.T("callBtn"))
        f.call.onClick = function(self)
            if not self.who then return end
            if self.act == "free" then
                ns.Ignore.Remove(self.who)
                refresh()
                return
            end
            call(self.who)
        end
        f:Hide()
        ui.cand[i] = f
    end
    ui.none = text(ui.list, 14, 14)
    ui.none:SetWidth(PW - 68)
    ui.none:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.hint = text(ui.panel, 20, 88)
    ui.hint:SetWidth(PW - 40)
    ui.hint:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.hint:SetText(ns.T("callByName"))
    ui.box = ns.NewFrame("EditBox", nil, ui.panel)
    ui.box:SetWidth(PW - 168)
    ui.box:SetHeight(26)
    ui.box:SetPoint("TOPLEFT", ui.panel, "TOPLEFT", 20, -132)
    ui.box:SetAutoFocus(false)
    ui.box:SetMaxLetters(24)
    ui.box:SetFontObject("GameFontHighlightSmall")
    ui.box:SetTextInsets(8, 8, 0, 0)
    plate(ui.box, { 0.063, 0.051, 0.031, 1 })
    outline(ui.box, { 0.31, 0.27, 0.21, 1 })
    ui.box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    ui.box:SetScript("OnEnterPressed", function(self)
        call(self:GetText())
    end)
    ui.boxCall = ns.MakeKitButton(ui.panel)
    ui.boxCall:SetWidth(100)
    ui.boxCall:SetHeight(26)
    ui.boxCall:SetPoint("TOPRIGHT", ui.panel, "TOPRIGHT", -20, -132)
    ui.boxCall.text:SetText(ns.T("callBtn"))
    ui.boxCall.onClick = function()
        call(ui.box:GetText())
    end
    ui.priv = ns.MakeKitButton(ui.panel)
    ui.priv:SetHeight(24)
    ui.priv:SetWidth(232)
    ui.priv:SetPoint("BOTTOMLEFT", ui.panel, "BOTTOMLEFT", 20, 12)
    ui.priv.onClick = function()
        ns.Ignore.SetMode(ns.Ignore.NextMode())
        refresh()
    end
    ui.note = ui.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.note:SetJustifyH("LEFT")
    ui.note:SetWidth(PW - 40)
    ui.note:SetPoint("BOTTOMLEFT", ui.priv, "TOPLEFT", 0, 8)
    ui.note:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
end
refresh = function()
    if not ui or not ui.dim:IsShown() then
        return
    end
    local key = ui.tabKey or "target"
    for _, k in ipairs(TABS) do
        local b = ui.tab[k]
        if k == key then
            b:Disable()
        else
            b:Enable()
        end
    end
    local single = (key == "name")
    ui.panel:SetHeight(single and PH_NAME or PH_LIST)
    if single then
        ui.list:Hide()
        ui.box:Show()
        ui.boxCall:Show()
        ui.hint:Show()
    else
        ui.list:Show()
        ui.box:Hide()
        ui.boxCall:Hide()
        ui.hint:Hide()
    end
    local mode = ns.Ignore.Mode()
    ui.priv:SetText(ns.T("privBtn", ns.T("priv_" .. mode)))
    ui.priv:SetWidth(math.max(200, (ui.priv.text:GetStringWidth() or 0) + 26))
    ui.priv.tipTitle = ns.T("privTitle")
    ui.priv.tip = ns.T("privTip")
    local src = {}
    if key == "target" then
        src = fromTarget()
    elseif key == "friends" then
        src = fromFriends()
    elseif key == "guild" then
        src = fromGuild()
    elseif key == "block" then
        src = fromBlock()
    end
    local top = ui.top or 1
    if top > #src - VIS + 1 then
        top = #src - VIS + 1
    end
    if top < 1 then
        top = 1
    end
    ui.top = top
    for i = 1, VIS do
        local f = ui.cand[i]
        local c = (not single) and src[top + i - 1] or nil
        if not c or not c.name then
            f:Hide()
        else
            if c.off then
                f.dot:SetVertexColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
            else
                f.dot:SetVertexColor(C_LIVE[1], C_LIVE[2], C_LIVE[3])
            end
            f.name:SetText(c.name)
            f.name:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
            f.state:SetText(c.off and ns.T("callBlocked") or "")
            f.call.who = c.name
            f.call.act = c.off and "free" or "call"
            f.call.text:SetText(ns.T(c.off and "callFree" or "callBtn"))
            f.call.tip = ns.T(c.off and "callFreeTip" or "callBtnTip")
            if not c.off and (ns.Duo.Waiting() or ns.Pair.Waiting()) then
                f.call:Disable()
            else
                f.call:Enable()
            end
            f:Show()
        end
    end
    local why
    if not single then
        if #src == 0 then
            why = (key == "target") and "duoNoTarget"
                    or (key == "friends") and "callNoFriends"
                    or (key == "block") and "callNoBlock"
                    or "callNoGuild"
        elseif src[1] and not src[1].name then
            why = src[1].why
        end
    end
    if why then
        ui.none:SetText(ns.T(why))
        ui.none:Show()
    else
        ui.none:Hide()
    end
    ui.note:SetText(ns.Pair.Status() or ns.Duo.Status() or said or "")
end
call = function(name)
    if not job then
        return
    end
    local who = ns.Link.Norm(name)
    if not who or ns.Link.IsMe(who) then
        return
    end
    if job.onCall and job.onCall(who) then
        return
    end
    if ns.Link.State(who) ~= "yes" then
        pending = who
        said = ns.T("duoAsking", who)
        ns.Link.Ask(who)
        if ui.note then
            ui.note:SetText(said)
        end
        return
    end
    pending, said = nil, nil
    local sent
    if job.pair then
        sent = ns.Pair.Call(who)
    else
        sent = ns.Duo.Invite(job.id, who, job.opts)
    end
    if sent and job.autoHide then
        P.Hide()
        return
    end
    refresh()
end
local function poke()
    if not ui or not pending then
        return
    end
    local who = pending
    local state = ns.Link.State(who)
    if state == "asking" then
        return
    end
    pending = nil
    if state == "yes" then
        call(who)
    else
        said = ns.T("duoSilent", who)
        if ui.note then
            ui.note:SetText(said)
        end
    end
end
function P.Show(host, o)
    if not ui then
        build()
    end
    job = o or {}
    pending, said = nil, nil
    ui.dim:SetParent(host)
    ui.dim:SetFrameStrata("FULLSCREEN_DIALOG")
    ui.dim:SetFrameLevel(host:GetFrameLevel() + 4)
    ui.dim:ClearAllPoints()
    ui.dim:SetAllPoints(host)
    ui.cap:SetText(job.title or ns.T("callTitle"))
    ui.what:SetText(job.id and ns.Records.Describe(ns.games[job.id], job.opts) or "")
    ui.tabKey = ui.tabKey or "target"
    ui.top = 1
    ui.box:SetText("")
    ns.Compat.RefreshRoster()
    ui.dim:Show()
    refresh()
end
function P.Hide()
    pending, said = nil, nil
    if ui then
        ui.dim:Hide()
    end
end
function P.IsShown()
    return ui and ui.dim:IsShown() and true or false
end
ns.Link.OnPresence(function()
    poke()
    refresh()
end)
ns.Duo.OnChange(refresh)
ns.Pair.OnChange(function()
    if ns.Pair.Bound() then
        P.Hide()
    end
    refresh()
end)
