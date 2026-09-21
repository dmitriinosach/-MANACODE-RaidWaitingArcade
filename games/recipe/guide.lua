local ADDON, ns = ...
ns.RecipeArt = {
    READY = "Interface\\RaidFrame\\ReadyCheck-Ready",
    WAIT  = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    NOPE  = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}
local GEM = {
    { 0.78, 0.24, 0.18 },
    { 0.26, 0.42, 0.80 },
    { 0.85, 0.70, 0.20 },
    { 0.56, 0.32, 0.78 },
    { 0.82, 0.50, 0.16 },
    { 0.28, 0.62, 0.32 },
}
local CELL, GAP = 30, 4
local STEP = CELL + GAP
local C_EDGE = { 0.30, 0.26, 0.19 }
local C_FACE = { 0.15, 0.13, 0.10 }
local function fill(host, layer, x, y, w, h, c)
    local t = host:CreateTexture(nil, layer)
    t:SetTexture(c[1], c[2], c[3], c[4] or 1)
    t:SetWidth(w)
    t:SetHeight(h)
    t:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
    return t
end
local function cell(host, x, y, k)
    fill(host, "BACKGROUND", x, y, CELL, CELL, C_EDGE)
    fill(host, "BORDER", x + 1, y + 1, CELL - 2, CELL - 2, C_FACE)
    if k then
        fill(host, "ARTWORK", x + 5, y + 5, CELL - 10, CELL - 10, GEM[k])
        fill(host, "OVERLAY", x + 5, y + 5, CELL - 10, 3, { 1, 1, 1, 0.25 })
    end
end
local function row(host, x, y, mix)
    for i = 1, #mix do
        cell(host, x + (i - 1) * STEP, y, mix[i] ~= 0 and mix[i] or nil)
    end
end
local function answer(host, x, y, n)
    local tex = { ns.RecipeArt.READY, ns.RecipeArt.WAIT, ns.RecipeArt.NOPE }
    for k = 1, 3 do
        local gx = x + (k - 1) * 40
        local ic = host:CreateTexture(nil, "ARTWORK")
        ic:SetTexture(tex[k])
        ic:SetWidth(16)
        ic:SetHeight(16)
        ic:SetPoint("TOPLEFT", host, "TOPLEFT", gx, -(y + 7))
        local fs = host:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", host, "TOPLEFT", gx + 20, -(y + 15))
        fs:SetText(tostring(n[k]))
        if n[k] == 0 then fs:SetTextColor(0.45, 0.42, 0.36) end
    end
end
local function tag(host, x, y, text)
    local fs = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", host, "TOPLEFT", x, -y)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(1, 0.82, 0)
    fs:SetText(text)
end
local MIXW = 5 * STEP - GAP
local ANSW = 3 * 40 - 6
local FULLW = MIXW + 16 + ANSW
local function leftOf(host)
    local w = host:GetWidth() or 380
    local x = math.floor((w - FULLW) / 2)
    return x > 0 and x or 0
end
ns.recipeSlides = {
    {
        head = "recipe.slCodeHead",
        target = "recipe.code",
        lines = { { t = "recipe.slCode", sub = "recipe.slCodeSub" } },
    },
    {
        head = "recipe.slPalHead",
        target = "recipe.pal",
        lines = { { t = "recipe.slPal", sub = "recipe.slPalSub" } },
    },
    {
        head = "recipe.slRowHead",
        target = "recipe.row",
        lines = { "recipe.slRow", "recipe.slRowSub" },
    },
    {
        head = "recipe.slAnsHead",
        target = "recipe.ans",
        lines = {
            "recipe.slAns",
            { h = 46, art = function(host)
                local x = leftOf(host)
                row(host, x, 6, { 6, 3, 2, 1, 5 })
                answer(host, x + MIXW + 16, 6, { 1, 2, 2 })
            end },
            "recipe.slAnsSub",
        },
    },
    {
        head = "recipe.slLegHead",
        target = "recipe.legend",
        lines = { { t = "recipe.slLeg", sub = "recipe.slLegSub" } },
    },
    {
        head = "recipe.slTestHead",
        lines = {
            "recipe.slTest",
            { h = 46, sub = "recipe.slTestSub", art = function(host)
                local x = leftOf(host)
                row(host, x, 6, { 1, 1, 1, 1, 1 })
                answer(host, x + MIXW + 16, 6, { 2, 0, 3 })
            end },
        },
    },
    {
        head = "recipe.slSwapHead",
        lines = {
            "recipe.slSwap",
            { h = 92, art = function(host)
                local x = leftOf(host)
                row(host, x, 2, { 2, 4, 6, 3, 5 })
                answer(host, x + MIXW + 16, 2, { 1, 3, 1 })
                row(host, x, 46, { 2, 6, 4, 3, 5 })
                answer(host, x + MIXW + 16, 46, { 2, 2, 1 })
                tag(host, x + STEP + 4, 82, ns.T("recipe.slSwapTag"))
            end },
            "recipe.slSwapSub",
        },
    },
    {
        head = "recipe.slRungHead",
        target = "recipe.level",
        lines = {
            "recipe.slRung",
            "recipe.slRungB",
            "recipe.slRungC",
        },
    },
}
