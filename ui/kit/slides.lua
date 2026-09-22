local ADDON, ns = ...
ns.Slides = {}
local card
local list, at, title
local bands, ring
local paused, hooked
local WIDTH = 420
local PAD = 4
local GAP = 10
local DIM_A = 0.72
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local function ensure()
    if card then return card end
    card = ns.MakeCard{
        name = "RaidWaitingArcadeSlidesOverlay",
        escape = true,
        dismiss = true,
        width = WIDTH,
        strata = "FULLSCREEN_DIALOG",
    }
    return card
end
local function ensureSpot()
    if bands then return end
    local ov = card:Overlay()
    bands = {}
    for i = 1, 4 do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        ns.Paint(t, 0, 0, 0, DIM_A)
        t:Hide()
        bands[i] = t
    end
    ring = ns.NewFrame("Frame", nil, ov)
    ring:SetBackdrop({ edgeFile = EDGE_TEX, edgeSize = 12 })
    ring:SetFrameLevel(ov:GetFrameLevel() + 1)
    ring:Hide()
end
local function hideSpot()
    if not bands then return end
    for _, t in ipairs(bands) do t:Hide() end
    ring:Hide()
end
local function maskAround(l, t, r, b)
    local ov = card:Overlay()
    local ox, oy = ov:GetLeft(), ov:GetTop()
    local ow, oh = ov:GetWidth(), ov:GetHeight()
    if not ox then return false end
    local x1, x2 = l - ox, r - ox
    local y1, y2 = oy - t, oy - b
    local function put(tx, px, py, w, h)
        tx:ClearAllPoints()
        tx:SetPoint("TOPLEFT", ov, "TOPLEFT", px, -py)
        tx:SetWidth(w > 0 and w or 0.01)
        tx:SetHeight(h > 0 and h or 0.01)
        tx:Show()
    end
    put(bands[1], 0,  0,  ow,      y1)
    put(bands[2], 0,  y2, ow,      oh - y2)
    put(bands[3], 0,  y1, x1,      y2 - y1)
    put(bands[4], x2, y1, ow - x2, y2 - y1)
    return true
end
local function placeCard(target)
    local ov, panel = card:Overlay(), card:Panel()
    local oy, oh, ow = ov:GetTop(), ov:GetHeight(), ov:GetWidth()
    local ch = panel:GetHeight() or 0
    panel:ClearAllPoints()
    if target:GetTop() > oy - oh / 2 then
        local dy = (oy - (target:GetBottom() - PAD)) + GAP
        if dy + ch > oh then dy = oh - ch end
        if dy < 0 then dy = 0 end
        panel:SetPoint("TOP", ov, "TOPLEFT", ow / 2, -dy)
    else
        local dy = (oy - (target:GetTop() + PAD)) - GAP
        if dy - ch < 0 then dy = ch end
        if dy > oh then dy = oh end
        panel:SetPoint("BOTTOM", ov, "TOPLEFT", ow / 2, -dy)
    end
end
local function pauseGame()
    if paused then return end
    if ns.Loop.Current() and not ns.Loop.IsPaused() then
        ns.Loop.Pause(ns.T("pauseHelp"))
        paused = true
    end
end
local function resumeGame()
    if not paused then return end
    paused = false
    ns.Loop.Resume()
    if ns.window then ns.window:RefreshHead() end
end
local anchors = {}
function ns.SlideAnchor(name, frame)
    anchors[name] = frame
end
local function liveTarget(name)
    local t = name and anchors[name]
    if not t then return nil end
    if t.IsShown and not t:IsShown() then return nil end
    if not t.GetLeft or not t:GetLeft() then return nil end
    return t
end
local render
local function step(d)
    at = at + d
    if at < 1 then at = 1 end
    if at > #list then at = #list end
    render()
end
render = function()
    local win = ns.window and ns.window:Frame()
    if not win then return end
    local sl = list[at] or {}
    local last = (at >= #list)
    local nextBtn = {
        label = last and ns.T("slidesDone") or ns.T("slidesNext"),
        onClick = function()
            if last then ns.Slides.Hide() else step(1) end
        end,
    }
    local btn = nextBtn
    if at > 1 then
        btn = { { label = ns.T("slidesBack"), onClick = function() step(-1) end }, nextBtn }
    end
    ensure():Note(at .. " / " .. #list)
    card:Show(win, sl.head or title, sl.lines or {}, btn)
    if not hooked then
        hooked = true
        card:Overlay():SetScript("OnHide", function()
            hideSpot()
            resumeGame()
        end)
    end
    ensureSpot()
    local target = liveTarget(sl.target)
    if target and maskAround(target:GetLeft() - PAD, target:GetTop() + PAD,
                             target:GetRight() + PAD, target:GetBottom() - PAD) then
        card:Dim(false)
        local r, g, b = ns.Attn()
        ring:SetBackdropBorderColor(r, g, b, 1)
        ring:ClearAllPoints()
        ring:SetPoint("TOPLEFT", target, "TOPLEFT", -PAD, PAD)
        ring:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", PAD, -PAD)
        ring:Show()
        placeCard(target)
    else
        hideSpot()
        card:Dim(true)
        local panel, ov = card:Panel(), card:Overlay()
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", ov, "CENTER", 0, 0)
    end
end
function ns.Slides.Show(name, slides)
    if not slides or #slides == 0 then return end
    title, list, at = ns.TL(name), ns.TLines(slides), 1
    render()
    pauseGame()
end
function ns.Slides.Hide()
    hideSpot()
    if card then card:Hide() end
end
function ns.Slides.IsShown()
    return card and card:IsShown() or false
end
