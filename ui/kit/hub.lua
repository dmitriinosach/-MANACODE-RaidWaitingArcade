local ADDON, ns = ...
local floor, max = math.floor, math.max
ns.CardHub = {}
local TOP, H, GAP, PAD, WIDTH = 20, 64, 8, 16, 640
local C_TEXT = { 0.91, 0.90, 0.86 }
local C_SOFT = { 0.65, 0.61, 0.53 }
local C_CAP  = { 0.54, 0.51, 0.45 }
local C_GOLD = { 1, 0.82, 0 }
local providers = {}
function ns.CardHub.Provide(row, id, fn)
    if type(fn) ~= "function" then return end
    providers[#providers + 1] = { row = (row == 2) and 2 or 1, id = id, fn = fn }
end
function ns.CardHub.Bottom()
    return TOP + H * 2 + GAP
end
function ns.CardHub.Here(id)
    local g = ns.Loop.Current()
    if g and g.def and g.def.id == id then return g end
    return nil
end
local Hub = {}
Hub.__index = Hub
local function tileOf(hub, i)
    local t = hub.tiles[i]
    if t then return t end
    t = ns.MakeSlot(hub.parent, hub.look)
    t:SetHeight(H)
    t.name = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.name:SetPoint("TOPLEFT", t, "TOPLEFT", 12, -12)
    t.best = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t.best:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 12, 11)
    t.foot = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t.foot:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -12, 11)
    t:SetScript("OnClick", function(self)
        if self.open and not self.on then
            ns.Sfx.Ui()
            self.open()
        end
    end)
    hub.tiles[i] = t
    return t
end
function ns.MakeCardHub(parent, look)
    return setmetatable({ parent = parent, look = look, tiles = {} }, Hub)
end
function Hub:Sync()
    local rows = { {}, {} }
    for i = 1, #providers do
        local p = providers[i]
        local list = p.fn() or {}
        for j = 1, #list do
            local row = rows[p.row]
            row[#row + 1] = list[j]
        end
    end
    local n = 0
    for r = 1, 2 do
        local row = rows[r]
        local k = #row
        local w = floor((WIDTH - PAD * 2 - GAP * (k - 1)) / max(k, 1))
        for i = 1, k do
            local it = row[i]
            n = n + 1
            local t = tileOf(self, n)
            t:SetWidth(w)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", self.parent, "TOPLEFT", PAD + (i - 1) * (w + GAP), -(TOP + (r - 1) * (H + GAP)))
            t:Tone(it.on)
            t.on = it.on and true or false
            local c = it.on and C_GOLD or C_TEXT
            t.name:SetText(it.label or "")
            t.name:SetTextColor(c[1], c[2], c[3])
            c = it.on and C_SOFT or C_CAP
            t.best:SetText(it.best or "")
            local b = it.bestGold and C_GOLD or c
            t.best:SetTextColor(b[1], b[2], b[3])
            t.foot:SetText(it.foot or "")
            t.foot:SetTextColor(c[1], c[2], c[3])
            t.tipTitle = it.label
            t.tip = it.line
            t.open = it.open
            t:Show()
        end
    end
    for i = n + 1, #self.tiles do self.tiles[i]:Hide() end
end
