local ADDON, ns = ...
ns.RecordsUI = {}
local WIDTH = 420
local ROWS = 10
local ROW_H = 15
local PICK_H = 24
local CAP_W = 70
local PICK_W = 150
local ICON = 12
local PAD = 8
local GAP = 6
local RANK_W = 20
local WHEN_W = 52
local COL_MIN = 60
local TABLE_H = PAD + ROW_H + 6 + ROWS * ROW_H + PAD
local DASH = "—"
local card
local picksHost, tableHost
local picks, rows = {}, {}
local panel, head
local curId, curDef, sel
local function pickAt(i)
    local p = picks[i]
    if p then return p end
    p = {}
    p.label = ns.TitleText(picksHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
    p.label:SetJustifyH("LEFT")
    p.label:SetWidth(CAP_W)
    p.label:SetPoint("TOPLEFT", picksHost, "TOPLEFT", 0, -((i - 1) * PICK_H + 4))
    p.step = ns.MakeStepper(picksHost)
    p.step:SetHeight(20)
    p.step:SetWidth(PICK_W)
    p.step:SetPoint("TOPLEFT", picksHost, "TOPLEFT", CAP_W, -((i - 1) * PICK_H))
    picks[i] = p
    return p
end
local refresh, render
local function repick(key, value)
    sel = ns.Records.Repick(curDef, sel, key, value)
    render()
end
local function ensureTable()
    if panel then return end
    panel = CreateFrame("Frame", nil, tableHost)
    panel:SetAllPoints(tableHost)
    head = { icon = {}, label = {} }
    head.when = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    head.when:SetJustifyH("LEFT")
    head.rule = panel:CreateTexture(nil, "ARTWORK")
    head.rule:SetHeight(1)
end
local function headCol(n)
    if not head.icon[n] then
        local ic = panel:CreateTexture(nil, "ARTWORK")
        ic:SetWidth(ICON); ic:SetHeight(ICON)
        ns.CropIcon(ic)
        local fs = ns.TitleText(panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
        fs:SetJustifyH("RIGHT")
        head.icon[n], head.label[n] = ic, fs
    end
    return head.icon[n], head.label[n]
end
local function rowAt(i)
    local r = rows[i]
    if r then return r end
    r = { col = {} }
    r.rank = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.rank:SetJustifyH("RIGHT")
    r.when = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.when:SetJustifyH("LEFT")
    rows[i] = r
    return r
end
local function colAt(r, n)
    if not r.col[n] then
        local c = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        c:SetJustifyH("RIGHT")
        r.col[n] = c
    end
    return r.col[n]
end
local function layout(marks)
    local w = tableHost:GetWidth() or (WIDTH - 24)
    local inner = w - PAD * 2
    local n = #marks
    local colW = math.floor((inner - RANK_W - WHEN_W - GAP * (n + 1)) / math.max(n, 1))
    if colW < COL_MIN then colW = COL_MIN end
    local headY = -PAD
    local rowY0 = -(PAD + ROW_H + 6)
    head.when:ClearAllPoints()
    head.when:SetWidth(WHEN_W)
    head.when:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + RANK_W + GAP, headY)
    head.rule:ClearAllPoints()
    head.rule:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, headY - ROW_H - 2)
    head.rule:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, headY - ROW_H - 2)
    for k = 1, n do
        local right = -(PAD + (n - k) * (colW + GAP))
        local ic, fs = headCol(k)
        fs:ClearAllPoints()
        fs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", right, headY)
        ic:ClearAllPoints()
        ic:SetPoint("RIGHT", fs, "LEFT", -3, 0)
        for i = 1, ROWS do
            local c = colAt(rowAt(i), k)
            c:ClearAllPoints()
            c:SetWidth(colW)
            c:SetPoint("TOPRIGHT", panel, "TOPRIGHT", right, rowY0 - (i - 1) * ROW_H)
        end
    end
    for i = 1, ROWS do
        local r = rowAt(i)
        local y = rowY0 - (i - 1) * ROW_H
        r.rank:ClearAllPoints()
        r.rank:SetWidth(RANK_W)
        r.rank:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
        r.when:ClearAllPoints()
        r.when:SetWidth(WHEN_W)
        r.when:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + RANK_W + GAP, y)
    end
end
local painted
local function paint(force)
    if not panel then return end
    local key = ns.ThemeKey()
    if painted == key and not force then return end
    painted = key
    local th = ns.CurrentTheme()
    panel:SetBackdrop(th.panel.backdrop)
    panel:SetBackdropColor(unpack(th.panel.bg))
    panel:SetBackdropBorderColor(unpack(th.panel.border))
    head.rule:SetTexture(th.rule[1], th.rule[2], th.rule[3], th.rule[4])
end
ns.OnTheme(function() paint(true) end)
ns.OnLocale(function()
    if card and card:IsShown() then refresh() end
end)
local function drawPicks(host) picksHost = host end
local function drawTable(host) tableHost = host end
local function when(at)
    if not at then return DASH end
    return date("%d.%m", at)
end
local DIM = { 0.45, 0.45, 0.45 }
local PLAIN = { 0.85, 0.85, 0.85 }
local WHEN_C = { 0.6, 0.6, 0.6 }
function refresh()
    if not (picksHost or tableHost) then return end
    local axes = ns.Records.AxesOpen(curDef, sel)
    if picksHost then
        for i, axis in ipairs(axes) do
            local p = pickAt(i)
            p.label:SetText(ns.TL(axis.label) or axis.key)
            p.label:Show()
            local key = axis.key
            p.step:SetSpec{
                label = ns.TL(axis.label), tip = ns.TL(axis.tip),
                value = sel[key],
                options = ns.Records.Options(axis, sel),
                min = ns.Records.Bound(axis, "min", sel),
                max = ns.Records.Bound(axis, "max", sel),
                step = axis.step, big = axis.big,
                format = axis.format,
                onPick = function(k) repick(key, k) end,
                onSet = function(v) repick(key, v) end,
            }
            p.step:Restyle()
            p.step:Show()
        end
        for i = #axes + 1, #picks do
            picks[i].label:Hide()
            picks[i].step:Hide()
        end
    end
    if not tableHost then return end
    ensureTable()
    paint()
    local marks = ns.Records.Marks(curDef)
    layout(marks)
    head.when:SetText(ns.T("recWhen"))
    for n, mark in ipairs(marks) do
        local ic, fs = headCol(n)
        ic:SetTexture(ns.Records.Icon(mark.mark))
        ic:Show()
        fs:SetText(ns.TL(mark.label) or mark.key)
        fs:Show()
    end
    for n = #marks + 1, #head.label do
        head.icon[n]:Hide()
        head.label[n]:Hide()
    end
    local list = ns.Records.List(curId, sel)
    local gold = { ns.CardEdge() }
    for i = 1, ROWS do
        local r = rowAt(i)
        local rec = list[i]
        local top = (i == 1) and rec ~= nil
        r.rank:SetText(tostring(i))
        r.rank:SetTextColor(unpack(rec and (top and gold or PLAIN) or DIM))
        r.rank:Show()
        r.when:SetText(when(rec and rec.at))
        r.when:SetTextColor(unpack(rec and WHEN_C or DIM))
        r.when:Show()
        for n, mark in ipairs(marks) do
            local c = colAt(r, n)
            c:SetText(rec and ns.Records.Format(mark, rec[mark.key]) or DASH)
            c:SetTextColor(unpack(rec and (top and gold or PLAIN) or DIM))
            c:Show()
        end
        for n = #marks + 1, #r.col do r.col[n]:Hide() end
    end
end
local function ensure()
    if card then return card end
    card = ns.MakeCard{
        name = "RaidWaitingArcadeRecordsOverlay",
        escape = true,
        dismiss = true,
        width = WIDTH,
        strata = "FULLSCREEN_DIALOG",
    }
    return card
end
function render()
    local win = ns.window and ns.window:Frame()
    if not win then return end
    local axes = ns.Records.AxesOpen(curDef, sel)
    local bare = #ns.Records.List(curId, sel) == 0
    local body = {
        { art = drawPicks, h = (#axes > 0) and (#axes * PICK_H) or 1 },
        { art = drawTable, h = TABLE_H, sub = bare and ns.T("recEmpty") or nil },
    }
    local note = ns.Records.Note(curDef)
    if note then body[#body + 1] = { t = ns.TL(note) } end
    ensure():Show(win,
        ns.T("recTitle", curDef and curDef.label or curId),
        body,
        { label = ns.T("helpClose"), onClick = function() ns.RecordsUI.Hide() end })
    refresh()
end
function ns.RecordsUI.Show(id, opts)
    curId = id
    curDef = ns.games and ns.games[id]
    sel = ns.Records.Normalize(curDef, opts or ns.Store.LastOpts(id))
    render()
end
function ns.RecordsUI.Hide()
    if card then card:Hide() end
end
function ns.RecordsUI.IsShown()
    return card and card:IsShown() or false
end
