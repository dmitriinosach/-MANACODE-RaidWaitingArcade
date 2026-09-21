local ADDON, ns = ...
ns.ControlsUI = {}
local WIDTH = 480
local SPEC = { cols = 1, header = true, mouse = "col" }
local card, tbl, host
local curId, curDef, curKeyed
local function ensure()
    if card then return card end
    card = ns.MakeCard{
        name = "RaidWaitingArcadeControlsOverlay",
        escape = true,
        dismiss = true,
        width = WIDTH,
        strata = "FULLSCREEN_DIALOG",
    }
    return card
end
local render
local function grabRow(row)
    local win = ns.window and ns.window:Frame()
    if not win then return end
    local id = curId
    ns.KeyGrab.Start(win, row.label, function(key)
        ns.Keys.SetKey(row.action, key, id)
        render()
    end)
end
local function drawTable(h)
    host = h
    tbl = ns.MakeKeyTable(h, {
        cols = SPEC.cols, header = SPEC.header, mouse = SPEC.mouse,
        width = h:GetWidth(), onGrab = grabRow,
    })
    tbl:Frame():SetPoint("TOPLEFT", h, "TOPLEFT", 0, 0)
end
local switch
local function drawSwitch(h)
    switch = ns.MakeCheck(h)
    switch:SetPoint("LEFT", h, "LEFT", 0, 0)
    switch.onToggle = function(on)
        ns.Keys.SetMouseOn(curId, on)
        render()
    end
end
local function refresh()
    if not tbl then return end
    local on = ns.Keys.MouseOn(curId)
    tbl.spec.mouseDim = not on
    tbl:Frame():SetWidth(host:GetWidth())
    tbl:SetRows(ns.Keys.Scheme(curDef, curKeyed))
    if switch then
        switch:SetChecked(on)
        switch.label:SetText(ns.T("ctlMouseOn"))
        switch.tipTitle = ns.T("ctlMouseOn")
        switch.tip = ns.T("ctlMouseOnTip")
    end
end
function render()
    local win = ns.window and ns.window:Frame()
    if not win or not curDef then return end
    local rows = ns.Keys.Scheme(curDef, curKeyed)
    local body = {
        { art = drawTable, h = ns.KeyTableHeight(#rows, SPEC) },
    }
    if curKeyed then
        body[#body + 1] = { art = drawSwitch, h = 24 }
    end
    body[#body + 1] = { t = ns.T("ctlLegend"), sub = ns.T("ctlFoot") }
    local id = curId
    ensure():Show(win,
        ns.T("ctlTitle", curDef.label or curId),
        body,
        {
            { label = ns.T("helpClose"), onClick = function() ns.ControlsUI.Hide() end },
            {
                label = ns.T("ctlLikePrefs"),
                tip = ns.T("ctlLikePrefsTip"),
                off = not ns.Keys.HasOwn(id),
                onClick = function()
                    ns.Keys.Reset(id)
                    render()
                end,
            },
        })
    refresh()
end
function ns.ControlsUI.Show(id, keyed)
    curId = id
    curDef = ns.games and ns.games[id]
    curKeyed = keyed and true or false
    if not curDef then return end
    if ns.Loop.Current() then
        ns.Loop.Pause(ns.T("pauseKeys"))
    end
    render()
end
function ns.ControlsUI.Hide()
    ns.KeyGrab.Stop()
    if card then card:Hide() end
end
function ns.ControlsUI.IsShown()
    return card and card:IsShown() or false
end
