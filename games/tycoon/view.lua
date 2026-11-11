local ADDON, ns = ...
local B, R = ns.TycoonBoards, ns.Tycoon
local V = ns.TycoonView or {}
ns.TycoonView = V
local floor, min, max, sin, PI = math.floor, math.min, math.max, math.sin, math.pi
local CELLS, PROPS, GROUPS = B.cells, B.props, B.groups
local CW, CH = 1320, 720
local BX, BY, CORNER, CORNER_H, CELL_W, CELL_H = 4, 11, 188, 110, 104, 53
local BOARD_W, BOARD_H = CORNER * 2 + CELL_W * 9, CORNER_H * 2 + CELL_H * 9
local STRIPE, BAND, SSTRIPE, SBAND, NAMEH, ICON = 10, 15, 8, 40, 42, 28
local TOKEN = 28
local PANEL_H = 104
local STEP = 0.16
local FLY_T, COIN_T, COIN_N = 0.7, 0.55, 4
local COIN_TEX = "Interface\\MoneyFrame\\UI-GoldIcon"
local GOLD_MARK = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
local GOLD_MARK_L = "|TInterface\\MoneyFrame\\UI-GoldIcon:16:16:2:0|t"
local LOG_LINES, MAX_LOG, HOLD_LINES = 6, 40, 10
local PIC_H = 64
local HOUSE_SZ, HOTEL_SZ = 14, 18
local FX0, FY0, FCW, FCH = BX + CORNER, BY + CORNER_H, BOARD_W - 2 * CORNER, BOARD_H - 2 * CORNER_H
local MX, FW = 240, FCW - 480
local PX, PY, PW = FX0 + 6, FY0 + 6, 226
local RX, RY, RW = FX0 + FCW - 232, FY0 + 6, 226
local PAD = 10
local WHITE = "Interface\\Buttons\\WHITE8X8"
local LS = "Interface\\Glues\\LoadingScreens\\"
local LFG = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-"
local WM = "Interface\\WorldMap\\"
local CELL_ART = {
    azeroth = {
        [0] = { B.PlacePath("az_c0"), 0.073, 0.927, 0, 1 },
        [10] = { B.PlacePath("az_c32"), 0.073, 0.927, 0, 1 },
        [20] = { B.PlacePath("az_c20"), 0.073, 0.927, 0, 1 },
    },
    icc = {
        [0] = { LS .. "LoadScreenIcecrownCitadel", 0.1, 0.9, 0.3, 0.768 },
        [10] = { LFG .. "IcecrownCitadel", 0.075, 0.925, 0, 1 },
        [20] = { LFG .. "TheForgeofSouls", 0.075, 0.925, 0, 1 },
        [30] = { LFG .. "PitofSaron", 0.075, 0.925, 0, 1 },
    },
    dalaran = {
        [0] = { B.PlacePath("dal_c0"), 0.073, 0.927, 0, 1 },
        [10] = { LS .. "LoadScreenDalaranPrison", 0.08, 0.92, 0.42, 0.911 },
        [20] = { B.PlacePath("dal_c20"), 0.073, 0.927, 0, 1 },
        [30] = { B.PlacePath("dal_c30"), 0.073, 0.927, 0, 1 },
    },
}
local DICE_SPIN, DICE_TICK = 0.6, 0.08
local FLASH_T, POP_T, FLOAT_T, PULSE_T, GOLD_T = 0.7, 0.35, 1.4, 1.5, 0.6
local CARD_FLIP, CARD_HOLD, CARD_OUT = 0.3, 2.4, 0.4
local WIN_Y, WIN_H, TAB_Y, TAB_H, LOG_Y = 58, 170, 234, 90, 330
local CARDBACK_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_cardback.tga"
local WIN_ART = {
    azeroth = { B.PlacePath("az_c24"), 0, 1, 0.13, 0.875 },
    icc = { "Interface\\Glues\\LoadingScreens\\LoadScreenIcecrownCitadel", 0.05, 0.95, 0.33, 0.666 },
    dalaran = { B.PlacePath("dal_c0"), 0, 1, 0.13, 0.875 },
}
local DECK_ART = {
    azeroth = { B.PlacePath("az_c24"), 0, 1, 0, 1 },
    icc = { "Interface\\LFGFrame\\UI-LFG-BACKGROUND-IcecrownCitadel", 0, 1, 0, 1 },
    dalaran = { B.PlacePath("dal_c0"), 0, 1, 0, 1 },
}
local MAP = {
    azeroth = { kind = "tiles", path = "Interface\\WorldMap\\World\\World", cols = 4, rows = 3 },
    icc = { kind = "one", path = "Interface\\Glues\\LoadingScreens\\LoadScreenIcecrownCitadel", coord = { 0.02, 0.58, 0.30, 0.86 } },
    dalaran = { kind = "tiles", path = "Interface\\WorldMap\\Dalaran\\Dalaran1_", cols = 4, rows = 3 },
}
local C = {
    text = { 0.91, 0.90, 0.86 }, soft = { 0.72, 0.68, 0.60 }, cap = { 0.58, 0.55, 0.48 }, title = { 0.95, 0.85, 0.54 },
    gold = { 1, 0.82, 0 }, bad = { 0.95, 0.35, 0.30 }, ok = { 0.48, 0.79, 0.42 }, ink = { 0.08, 0.06, 0.04 }, pale = { 0.87, 0.87, 0.87 },
    house = { 0.30, 0.68, 0.28 }, hotel = { 0.82, 0.22, 0.18 },
}
V.C = C
local LOOKS = {}
for k, spec in pairs(B.look) do LOOKS[k] = ns.MakeLook(spec) end
V.LOOKS = LOOKS
local TOKEN_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_tokens.tga"
local TEAM_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_tokens_team.tga"
local SPOT_TEX = "Interface\\AddOns\\" .. ADDON .. "\\art\\tycoon_spot.tga"
local MORPH = "Fonts\\MORPHEUS.TTF"
local root, boardF, tableBg, hudF, fxF, shadowF, midF, ringF
local cells, tokens, players, coins = {}, {}, {}, {}
local center, card, hold, side, bank, deckCard = {}, {}, {}, {}, {}, {}
local shown, anim = {}, {}
local fx = { flash = {}, pop = {}, float = {}, pulse = {}, gold = {}, fly = {} }
local curLook, pal
function V.Gold(n)
    return tostring(n) .. GOLD_MARK
end
local gold = V.Gold
local function at(f, x, y, parent)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", parent or root, "TOPLEFT", x, -y)
end
local function paint(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local function size(fs, px, flags)
    ns.SetFont(fs, (fs:GetFont()), px, flags or "")
end
local function sizeM(fs, px)
    ns.SetFont(fs, MORPH, px, "")
end
local function text(parent, style, x, y, w, justify, px)
    local fs = parent:CreateFontString(nil, "OVERLAY", style or "GameFontNormal")
    if x then fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y) end
    if w then fs:SetWidth(w) end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetShadowColor(0, 0, 0, 0)
    fs:SetShadowOffset(0, 0)
    if px then size(fs, px) end
    return fs
end
local function button(parent, x, y, w, h, fn)
    local b = ns.MakeKitButton(parent)
    b:SetWidth(w)
    b:SetHeight(h)
    at(b, x, y, parent)
    b.onClick = fn
    return b
end
local function grad(parent, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(WHITE)
    return t
end
local function vgrad(t, top, bottom, a1, a2)
    ns.Gradient(t, "VERTICAL", bottom[1], bottom[2], bottom[3], a2 or a1 or 1, top[1], top[2], top[3], a1 or 1)
end
local function hgrad(t, left, right, a)
    ns.Gradient(t, "HORIZONTAL", left[1], left[2], left[3], a or 1, right[1], right[2], right[3], a or 1)
end
local function lum(c)
    local function lin(v) if v <= 0.03928 then return v / 12.92 end return ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3])
end
local function bandTone(c)
    local r, g, b = c[1], c[2], c[3]
    local L = lum(c)
    if L >= 0.2 then
        local k = 0
        while L < 0.22 and k < 20 do
            r, g, b = r + (1 - r) * 0.1, g + (1 - g) * 0.1, b + (1 - b) * 0.1
            L = lum({ r, g, b })
            k = k + 1
        end
        return r, g, b, true
    end
    local k = 0
    while L > 0.18 and k < 20 do
        r, g, b = r * 0.9, g * 0.9, b * 0.9
        L = lum({ r, g, b })
        k = k + 1
    end
    return r, g, b, false
end
V.BandTone = bandTone
local function lighten(c, k)
    return { c[1] + (1 - c[1]) * k, c[2] + (1 - c[2]) * k, c[3] + (1 - c[3]) * k }
end
local function edgeBars(f, layer, c, w)
    local out = {}
    local spec = {
        { "TOPLEFT", "TOPRIGHT", nil, w or 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, w or 1 },
        { "TOPLEFT", "BOTTOMLEFT", w or 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", w or 1, nil },
    }
    for k = 1, 4 do
        local s = spec[k]
        local t = ns.Fill(f, layer, c)
        t:SetPoint(s[1], f, s[1], 0, 0)
        t:SetPoint(s[2], f, s[2], 0, 0)
        if s[3] then t:SetWidth(s[3]) end
        if s[4] then t:SetHeight(s[4]) end
        out[k] = t
    end
    return out
end
local function tintBars(bars, c, a)
    for k = 1, 4 do ns.Paint(bars[k], c[1], c[2], c[3], a or 1) end
end
local function showBars(bars, on, c)
    for k = 1, 4 do
        if on then
            if c then ns.Paint(bars[k], c[1], c[2], c[3], 1) end
            bars[k]:Show()
        else
            bars[k]:Hide()
        end
    end
end
local function panel(parent, level, x, y, w, h)
    local f = ns.PlainFrame(parent, level or 2)
    f:SetWidth(w)
    f:SetHeight(h)
    at(f, x, y, parent)
    f.bg = grad(f, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.edge = edgeBars(f, "BORDER", { 0.3, 0.3, 0.3, 1 })
    return f
end
V.at, V.paint, V.size, V.text, V.button = at, paint, size, text, button
V.grad, V.vgrad, V.hgrad, V.lighten = grad, vgrad, hgrad, lighten
V.edgeBars, V.tintBars, V.showBars, V.panel = edgeBars, tintBars, showBars, panel
function V.Pal() return pal end
local function ring(parent, sz)
    local f = ns.PlainFrame(parent, 1)
    f:SetWidth(sz)
    f:SetHeight(sz)
    f.rim = ns.Fill(f, "BACKGROUND", 1, 1, 1, 1)
    f.rim:SetAllPoints(f)
    f.ink = ns.Fill(f, "BORDER", 0.04, 0.04, 0.05, 1)
    f.ink:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    f.ink:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    f.tex = f:CreateTexture(nil, "OVERLAY")
    f.tex:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
    f.tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    f.team = f:CreateTexture(nil, "ARTWORK")
    f.team:SetAllPoints(f.tex)
    return f
end
V.Ring = ring
local function tokenCoord(t)
    local i = (t or 1) - 1
    local cx, cy = i % 4, floor(i / 4)
    return cx * 0.25, cx * 0.25 + 0.25, cy * 0.5, cy * 0.5 + 0.5
end
function V.TokenTex(tex, t)
    tex:SetTexture(TOKEN_TEX)
    tex:SetTexCoord(tokenCoord(t))
end
function V.TeamTex(tex, t, q)
    tex:SetTexture(TEAM_TEX)
    tex:SetTexCoord(tokenCoord(t))
    local sc = B.SEAT_COLOR[q] or C.text
    tex:SetVertexColor(sc[1], sc[2], sc[3])
end
function V.CellIcon(tex, board, c)
    local id = B.icon[board] and B.icon[board][c]
    if type(id) == "number" and id < B.SPECIAL_N then
        tex:SetTexture(B.SPECIAL_TEX)
        tex:SetTexCoord(B.SpecialCoord(id))
    elseif type(id) == "string" then
        tex:SetTexture(ns.IconPath(id))
        ns.CropIcon(tex)
    else
        tex:SetTexture(ns.Icons.Item(id or 0))
        ns.CropIcon(tex)
    end
end
function V.SetRing(f, q, t)
    local sc = B.SEAT_COLOR[q] or C.text
    ns.Paint(f.rim, sc[1], sc[2], sc[3], 1)
    V.TokenTex(f.tex, t)
    if f.team then V.TeamTex(f.team, t, q) end
end
local function cellRect(i)
    local far = BX + BOARD_W - CORNER
    local low = BY + BOARD_H - CORNER_H
    if i == 0 then return far, low, CORNER, CORNER_H, "corner" end
    if i < 10 then return far - i * CELL_W, low, CELL_W, CORNER_H, "bottom" end
    if i == 10 then return BX, low, CORNER, CORNER_H, "corner" end
    if i < 20 then return BX, low - (i - 10) * CELL_H, CORNER, CELL_H, "left" end
    if i == 20 then return BX, BY, CORNER, CORNER_H, "corner" end
    if i < 30 then return BX + CORNER + (i - 21) * CELL_W, BY, CELL_W, CORNER_H, "top" end
    if i == 30 then return far, BY, CORNER, CORNER_H, "corner" end
    return far, BY + CORNER_H + (i - 31) * CELL_H, CORNER, CELL_H, "right"
end
V.CellRect = cellRect
function V.HitCell(x, yt)
    for i = 0, 39 do
        local cx, cy, w, h = cellRect(i)
        if x >= cx and x < cx + w and yt >= cy and yt < cy + h then return i end
    end
    return nil
end
local function rowTop(sd)
    return sd == "bottom" and (1 + STRIPE + 1) or (1 + BAND + 1)
end
local function iconArea(i)
    local x, y, w, h, sd = cellRect(i)
    if sd == "corner" then return x + 10, y + 10, 44, 44 end
    if sd == "bottom" or sd == "top" then return x + w / 2 - ICON / 2, y + rowTop(sd) + NAMEH + 2, ICON, ICON end
    local ix = sd == "left" and (1 + SBAND) or (1 + SSTRIPE)
    return x + ix + 6, y + floor((h - 26) / 2), 26, 26
end
local function tokenZone(i)
    local x, y, w, h, sd = cellRect(i)
    if sd == "corner" then return x + 10, y + 58, w - 20, 34 end
    local ax, ay, aw, ah = iconArea(i)
    if sd == "bottom" or sd == "top" then return x, ay - 2, w, ah + 4 end
    return ax - 2, ay - 2, aw + 4, ah + 4
end
local SIDE_SLOT = {
    { { 0, 0 } }, { { -9, 0 }, { 9, 0 } }, { { -9, -7 }, { 9, -7 }, { 0, 7 } }, { { -9, -7 }, { 9, -7 }, { -9, 7 }, { 9, 7 } },
}
local function tokenSlot(i, k, n)
    local _, _, _, _, sd = cellRect(i)
    local zx, zy, zw, zh = tokenZone(i)
    if sd == "left" or sd == "right" then
        local p = SIDE_SLOT[min(n, 4)][min(k, 4)]
        return zx + zw / 2 + p[1], zy + zh / 2 + p[2], n > 1 and 24 or TOKEN
    end
    local sz = sd == "corner" and 30 or TOKEN
    local step = sz + 2
    if n > 1 then step = min(step, (zw - sz) / (n - 1)) end
    return zx + zw / 2 + (k - (n + 1) / 2) * step, zy + zh / 2, sz
end
local function cellXY(c)
    local x, y, w, h = tokenZone(c)
    return x + w / 2, y + h / 2
end
local function buildCell(i)
    local x, y, w, h, sd = cellRect(i)
    local b = ns.NewFrame("Button", nil, boardF)
    b:SetWidth(w)
    b:SetHeight(h)
    at(b, x, y, boardF)
    b.id = i
    b.sd = sd
    b.bg = grad(b, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.line = edgeBars(b, "BORDER", { 0.35, 0.26, 0.15, 1 })
    local ax, ay, aw, ah = iconArea(i)
    local rows = sd == "bottom" or sd == "top"
    local sides = sd == "left" or sd == "right"
    local ix = sd == "left" and (1 + SBAND) or (1 + SSTRIPE)
    local iw = w - SBAND - SSTRIPE - 2
    b.tint = ns.Fill(b, "BORDER", 1, 1, 1, 0.3)
    b.veil = ns.Fill(b, "BORDER", 1, 1, 1, 0.7)
    if rows then
        at(b.tint, 1, rowTop(sd), b)
        b.tint:SetWidth(w - 2)
        b.tint:SetHeight(h - STRIPE - BAND - 4)
    elseif sides then
        at(b.tint, ix, 1, b)
        b.tint:SetWidth(iw)
        b.tint:SetHeight(h - 2)
    else
        at(b.tint, 1, 1, b)
        b.tint:SetWidth(w - 2)
        b.tint:SetHeight(h - 2)
        at(b.veil, 58, 8, b)
        b.veil:SetWidth(w - 62)
        b.veil:SetHeight(48)
    end
    b.veil:Hide()
    b.stripe = ns.Fill(b, "BORDER", 0.5, 0.5, 0.5, 1)
    b.band = ns.Fill(b, "BORDER", 0.5, 0.5, 0.5, 1)
    if sd == "bottom" then
        at(b.stripe, 1, 1, b); b.stripe:SetWidth(w - 2); b.stripe:SetHeight(STRIPE)
        at(b.band, 1, h - BAND - 1, b); b.band:SetWidth(w - 2); b.band:SetHeight(BAND)
    elseif sd == "top" then
        at(b.stripe, 1, h - STRIPE - 1, b); b.stripe:SetWidth(w - 2); b.stripe:SetHeight(STRIPE)
        at(b.band, 1, 1, b); b.band:SetWidth(w - 2); b.band:SetHeight(BAND)
    elseif sd == "left" then
        at(b.stripe, w - SSTRIPE - 1, 1, b); b.stripe:SetWidth(SSTRIPE); b.stripe:SetHeight(h - 2)
        at(b.band, 1, 1, b); b.band:SetWidth(SBAND); b.band:SetHeight(h - 2)
    elseif sd == "right" then
        at(b.stripe, 1, 1, b); b.stripe:SetWidth(SSTRIPE); b.stripe:SetHeight(h - 2)
        at(b.band, w - SBAND - 1, 1, b); b.band:SetWidth(SBAND); b.band:SetHeight(h - 2)
    else
        b.stripe:Hide()
        at(b.band, 1, h - BAND - 1, b); b.band:SetWidth(w - 2); b.band:SetHeight(BAND)
    end
    b.price = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    size(b.price, 13)
    b.price:SetShadowOffset(0, 0)
    b.price:SetShadowColor(0, 0, 0, 0)
    b.price:SetJustifyH("CENTER")
    b.price:SetJustifyV("MIDDLE")
    b.ownTex = b:CreateTexture(nil, "ARTWORK")
    b.ownTex:SetWidth(13)
    b.ownTex:SetHeight(13)
    b.ownTex:Hide()
    if sides then
        b.price:SetPoint("TOP", b.band, "TOP", 0, -3)
        b.price:SetWidth(SBAND + 4)
        b.price:SetHeight(34)
        b.ownTex:SetPoint("BOTTOM", b.band, "BOTTOM", 0, 2)
    else
        b.price:SetPoint("CENTER", b.band, "CENTER", 0, 0)
        b.price:SetHeight(BAND)
        b.ownTex:SetPoint("LEFT", b.band, "LEFT", 3, 0)
    end
    b.iconBg = ns.Fill(b, "BORDER", 0, 0, 0, 0.55)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(aw)
    b.icon:SetHeight(aw)
    b.iconBg:SetWidth(aw + 4)
    b.iconBg:SetHeight(aw + 4)
    b.icon:SetPoint("CENTER", b, "TOPLEFT", ax - x + aw / 2, -(ay - y + ah / 2))
    b.iconBg:SetPoint("CENTER", b.icon, "CENTER", 0, 0)
    b.cap = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.cap:SetShadowOffset(0, 0)
    b.cap:SetShadowColor(0, 0, 0, 0)
    b.cap:SetJustifyV("MIDDLE")
    if sd == "corner" then
        sizeM(b.cap, 15)
        b.cap:SetWidth(w - 66)
        b.cap:SetHeight(48)
        b.cap:SetJustifyH("LEFT")
        b.cap:SetPoint("TOPLEFT", b, "TOPLEFT", 62, -8)
    elseif rows then
        size(b.cap, 12)
        b.cap:SetWidth(w - 8)
        b.cap:SetHeight(NAMEH)
        b.cap:SetJustifyH("CENTER")
        b.cap:SetPoint("TOP", b, "TOP", 0, -rowTop(sd))
    else
        size(b.cap, 12)
        b.cap:SetWidth(iw - 44)
        b.cap:SetHeight(h - 6)
        b.cap:SetJustifyH("LEFT")
        b.cap:SetPoint("TOPLEFT", b, "TOPLEFT", ix + 40, -3)
    end
    b.houses = {}
    for k = 1, 4 do
        local t = b:CreateTexture(nil, "OVERLAY")
        t:SetTexture(B.HOUSE_TEX)
        t:SetWidth(HOUSE_SZ)
        t:SetHeight(HOUSE_SZ)
        if sides then
            t:SetPoint("CENTER", b.stripe, "TOP", 0, -(8 + (k - 1) * 12))
        else
            t:SetPoint("CENTER", b.stripe, "LEFT", 9 + (k - 1) * 13, 0)
        end
        b.houses[k] = t
    end
    b.hotel = b:CreateTexture(nil, "OVERLAY")
    b.hotel:SetTexture(B.HOUSE_TEX)
    b.hotel:SetWidth(HOTEL_SZ)
    b.hotel:SetHeight(HOTEL_SZ)
    b.hotel:SetPoint("CENTER", b.stripe, "CENTER", 0, 0)
    b.dust = b:CreateTexture(nil, "OVERLAY")
    b.dust:SetTexture(COIN_TEX)
    b.dust:SetVertexColor(0.85, 0.8, 0.7)
    b.dust:SetBlendMode("ADD")
    b.dust:SetPoint("CENTER", b.stripe, "CENTER", 0, 0)
    b.dust:Hide()
    b.glow = ns.Fill(b, "OVERLAY", 1, 1, 1, 0)
    b.glow:SetAllPoints(b.tint)
    b.glow:SetBlendMode("ADD")
    b.glow:Hide()
    b.dim = ns.Fill(b, "ARTWORK", 0.16, 0.16, 0.18, 0.82)
    b.dim:SetAllPoints(b.tint)
    b.dim:Hide()
    b.mortText = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    size(b.mortText, 11)
    b.mortText:SetShadowOffset(0, 0)
    b.mortText:SetShadowColor(0, 0, 0, 0)
    b.mortText:SetTextColor(1, 1, 1)
    if sides then
        b.mortText:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", ix + 40, 4)
    else
        b.mortText:SetPoint("CENTER", b.icon, "CENTER", 0, 0)
    end
    b.mortText:Hide()
    b.flash = ns.Fill(b, "OVERLAY", 1, 1, 1, 0)
    b.flash:SetAllPoints(b)
    b.flash:SetBlendMode("ADD")
    b.flash:Hide()
    b.own = edgeBars(b, "OVERLAY", C.gold, 2)
    b.sel = edgeBars(b, "OVERLAY", C.gold, 3)
    b:SetScript("OnClick", function(self)
        local g = V.game
        if g then g:CellClick(self.id) end
    end)
    b:SetScript("OnEnter", function(self)
        local g = V.game
        if g then g:Hover(self.id) end
    end)
    b:SetScript("OnLeave", function(self)
        local g = V.game
        if g then g:Hover(nil) end
    end)
    return b
end
local function buildToken(q)
    local f = ns.PlainFrame(boardF, 6)
    f:SetWidth(TOKEN)
    f:SetHeight(TOKEN)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    f.team = f:CreateTexture(nil, "BORDER")
    f.team:SetAllPoints(f)
    f.shadow = shadowF:CreateTexture(nil, "ARTWORK")
    f.shadow:SetTexture(SPOT_TEX)
    f.shadow:SetVertexColor(0, 0, 0)
    f.shadow:SetAlpha(0.45)
    f.shadow:SetWidth(TOKEN)
    f.shadow:SetHeight(TOKEN * 0.4)
    f.shadow:Hide()
    f:Hide()
    return f
end
local function buildCoins()
    for k = 1, COIN_N * 2 do
        local f = ns.PlainFrame(fxF, 3)
        f:SetWidth(18)
        f:SetHeight(18)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetTexture(COIN_TEX)
        f.tex:SetAllPoints(f)
        f:Hide()
        coins[k] = f
    end
end
local function buildPlayer(q)
    local p = panel(midF, 2, PX, PY + (q - 1) * PANEL_H, PW, PANEL_H - 6)
    p.ring = ring(p, 64)
    at(p.ring, 6, 6, p)
    p.name = text(p, "GameFontNormal", 78, 7, 124, nil, 13)
    p.gold = text(p, "GameFontNormalLarge", 78, 25, 100, nil, 18)
    p.info = text(p, "GameFontHighlightSmall", 78, 50, 70, nil, 10)
    p.info2 = text(p, "GameFontHighlightSmall", 118, 50, 100, "RIGHT", 10)
    p.info3 = text(p, "GameFontHighlightSmall", 78, 63, 140, nil, 10)
    p.num = text(p, "GameFontNormalLarge", 196, 8, 22, "RIGHT", 11)
    p.chips = {}
    for k = 1, 10 do
        local bgc = ns.Fill(p, "BORDER", 0, 0, 0, 0.5)
        bgc:SetWidth(14)
        bgc:SetHeight(10)
        at(bgc, 78 + (k - 1) * 14, PANEL_H - 23, p)
        local t = ns.Fill(p, "ARTWORK", 0.5, 0.5, 0.5, 1)
        t:SetWidth(12)
        t:SetHeight(8)
        at(t, 79 + (k - 1) * 14, PANEL_H - 22, p)
        p.chips[k] = t
    end
    p.waitBar = ns.Fill(p, "ARTWORK", 1, 1, 1, 1)
    p.waitBar:SetWidth(4)
    p.waitBar:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
    p.waitBar:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
    p.waitBar:Hide()
    p.edge2 = edgeBars(p, "OVERLAY", C.gold, 2)
    showBars(p.edge2, false)
    p.tmBg = ns.Fill(p, "ARTWORK", 0, 0, 0, 0.8)
    p.tmBg:SetHeight(4)
    p.tmBg:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 1, 1)
    p.tmBg:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
    p.tmBg:Hide()
    p.tm = grad(p, "OVERLAY")
    p.tm:SetHeight(4)
    p.tm:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 1, 1)
    p.tm:SetWidth(1)
    p.tm:Hide()
    local fl = ns.PlainFrame(fxF, 2)
    fl:SetWidth(120)
    fl:SetHeight(24)
    fl.text = text(fl, "GameFontNormalLarge", nil, nil, 120, "RIGHT", 18)
    fl.text:SetPoint("RIGHT", fl, "RIGHT", 0, 0)
    fl:Hide()
    p.float = fl
    return p
end
local function buildBank()
    local f = panel(midF, 2, PX, PY + 4 * PANEL_H, PW, 44)
    bank.f = f
    bank.rows = {}
    for k = 1, 2 do
        bank.rows[k] = { lab = text(f, "GameFontHighlightSmall", 10, 7 + (k - 1) * 16, 136, nil, 11),
                         val = text(f, "GameFontNormal", 150, 7 + (k - 1) * 16, 66, "RIGHT", 12) }
    end
end
local function die(parent, x, y)
    local d = ns.PlainFrame(parent, 3)
    d:SetWidth(36)
    d:SetHeight(36)
    at(d, x, y, parent)
    d.bg = ns.Fill(d, "BACKGROUND", 0.95, 0.91, 0.80, 1)
    d.bg:SetAllPoints(d)
    d.edge = edgeBars(d, "BORDER", { 0.25, 0.18, 0.10, 1 }, 2)
    d.pips = {}
    local P = { { 18, 18 }, { 9, 9 }, { 27, 27 }, { 27, 9 }, { 9, 27 }, { 9, 18 }, { 27, 18 } }
    for k = 1, 7 do
        local t = ns.Fill(d, "ARTWORK", 0.16, 0.10, 0.05, 1)
        t:SetWidth(6)
        t:SetHeight(6)
        t:SetPoint("CENTER", d, "TOPLEFT", P[k][1], -P[k][2])
        d.pips[k] = t
    end
    return d
end
local DIE_PIPS = { [1] = { 1 }, [2] = { 2, 3 }, [3] = { 1, 2, 3 }, [4] = { 2, 3, 4, 5 }, [5] = { 1, 2, 3, 4, 5 }, [6] = { 2, 3, 4, 5, 6, 7 } }
local function showDie(d, n)
    local on = DIE_PIPS[n] or {}
    for k = 1, 7 do d.pips[k]:Hide() end
    for _, k in ipairs(on) do d.pips[k]:Show() end
    if n > 0 then d:Show() else d:Hide() end
end
local function buildDeckCard()
    local f = ns.PlainFrame(fxF, 4)
    f:SetWidth(190)
    f:SetHeight(250)
    f:SetPoint("CENTER", boardF, "TOPLEFT", FX0 + FCW / 2, -(FY0 + FCH / 2))
    f.bg = grad(f, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.edge = edgeBars(f, "BORDER", C.gold, 2)
    f.pic = f:CreateTexture(nil, "ARTWORK")
    f.pic:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    f.pic:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    f.pic:SetHeight(93)
    f.plate = ns.Fill(f, "ARTWORK", 0, 0, 0, 0.8)
    f.plate:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -95)
    f.plate:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -95)
    f.plate:SetHeight(22)
    f.head = text(f, "GameFontNormal", nil, nil, 170, "CENTER", 13)
    sizeM(f.head, 14)
    f.head:SetPoint("TOP", f, "TOP", 0, -99)
    f.body = text(f, "GameFontHighlight", nil, nil, 170, "CENTER", 12)
    f.body:SetPoint("TOP", f, "TOP", 0, -126)
    f.body:SetHeight(110)
    f.body:SetJustifyV("TOP")
    f:Hide()
    deckCard.f = f
end
local function buildDeck(parent, x, y)
    local d = ns.PlainFrame(parent, 2)
    d:SetWidth(72)
    d:SetHeight(TAB_H)
    at(d, x, y, parent)
    d.backs = {}
    for k = 1, 3 do
        local t = d:CreateTexture(nil, "ARTWORK")
        t:SetTexture(CARDBACK_TEX)
        t:SetWidth(34)
        t:SetHeight(64)
        t:SetPoint("TOP", d, "TOP", 10 - k * 3, -(10 - k * 2))
        d.backs[k] = t
    end
    d.plate = ns.Fill(d, "OVERLAY", 0, 0, 0, 0.92)
    d.plate:SetHeight(18)
    d.plate:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 0, 0)
    d.plate:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", 0, 0)
    d.cap = text(d, "GameFontHighlightSmall", nil, nil, 72, "CENTER", 10)
    d.cap:SetPoint("BOTTOM", d, "BOTTOM", 0, 4)
    return d
end
local function buildCenter()
    local f = panel(boardF, 2, FX0, FY0, FCW, FCH)
    center.f = f
    center.map = {}
    for k = 1, 12 do
        local t = f:CreateTexture(nil, "BORDER")
        t:Hide()
        center.map[k] = t
    end
    center.shade = ns.Fill(f, "ARTWORK", 0, 0, 0, 0.55)
    center.shade:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    center.shade:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    local col = ns.PlainFrame(f, 1)
    col:SetWidth(FW)
    col:SetHeight(FCH)
    at(col, MX, 0, f)
    center.col = col
    center.plate = ns.Fill(col, "BACKGROUND", 0, 0, 0, 0.92)
    at(center.plate, 0, 0, col)
    center.plate:SetWidth(FW)
    center.plate:SetHeight(WIN_Y - 4)
    center.title = text(col, "GameFontNormalLarge", 0, 4, FW, "CENTER", 22)
    sizeM(center.title, 26)
    center.status = text(col, "GameFontNormal", 0, 32, FW, "CENTER", 15)
    local win = ns.PlainFrame(col, 1)
    win:SetWidth(FW)
    win:SetHeight(WIN_H)
    at(win, 0, WIN_Y, col)
    win.bg = ns.Fill(win, "BACKGROUND", 0, 0, 0, 0.6)
    win.bg:SetAllPoints(win)
    win.art = win:CreateTexture(nil, "ARTWORK")
    win.art:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -1)
    win.art:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -1, 1)
    win.edge = edgeBars(win, "OVERLAY", C.gold, 1)
    center.win = win
    center.deck = { c = buildDeck(col, 10, TAB_Y), t = buildDeck(col, FW - 82, TAB_Y) }
    local tray = panel(col, 1, 108, TAB_Y, FW - 216, TAB_H)
    center.tray = tray
    center.d1 = die(tray, (FW - 216) / 2 - 46, 16)
    center.d2 = die(tray, (FW - 216) / 2 + 10, 16)
    center.sum = text(tray, "GameFontNormal", 0, 60, FW - 216, "CENTER", 14)
    center.log = panel(col, 1, 0, LOG_Y, FW, LOG_LINES * 15 + 10)
    center.lines = {}
    for k = 1, LOG_LINES do
        center.lines[k] = text(center.log, "GameFontHighlightSmall", 8, 6 + (k - 1) * 15, FW - 16, nil, 11)
    end
    local pr = panel(col, 3, 0, WIN_Y, FW, 100)
    center.prompt = pr
    pr.bar = ns.Fill(pr, "ARTWORK", 0.5, 0.5, 0.5, 1)
    pr.bar:SetHeight(6)
    pr.bar:SetPoint("TOPLEFT", pr, "TOPLEFT", 1, -1)
    pr.bar:SetPoint("TOPRIGHT", pr, "TOPRIGHT", -1, -1)
    pr.bar:Hide()
    pr.iconBg = grad(pr, "ARTWORK")
    pr.iconBg:SetWidth(48)
    pr.iconBg:SetHeight(48)
    at(pr.iconBg, 10, 12, pr)
    pr.iconBg:Hide()
    pr.icon = pr:CreateTexture(nil, "OVERLAY")
    pr.icon:SetWidth(40)
    pr.icon:SetHeight(40)
    pr.icon:SetPoint("CENTER", pr.iconBg, "CENTER", 0, 0)
    pr.title = text(pr, "GameFontNormal", 68, 12, FW - 200, nil, 15)
    pr.sub = text(pr, "GameFontHighlightSmall", 68, 31, FW - 200, nil, 11)
    pr.price = text(pr, "GameFontNormalLarge", FW - 120, 12, 100, "RIGHT", 20)
    pr.text = text(pr, "GameFontHighlightSmall", 68, 46, FW - 100, nil, 11)
    pr.text:SetHeight(30)
    pr.text:SetJustifyV("TOP")
    pr.give = text(pr, "GameFontHighlightSmall", 10, 76, (FW - 36) / 2, nil, 11)
    pr.give:SetHeight(50)
    pr.give:SetJustifyV("TOP")
    pr.get = text(pr, "GameFontHighlightSmall", 12 + (FW - 36) / 2, 76, (FW - 36) / 2, nil, 11)
    pr.get:SetHeight(50)
    pr.get:SetJustifyV("TOP")
    pr.who = {}
    for k = 1, 3 do
        pr.who[k] = button(pr, 10 + (k - 1) * 128, 48, 120, 22, function(self)
            local g = V.game
            if g and self.seat then g:TradeWho(self.seat) end
        end)
    end
    pr.goldA = ns.MakeNumberBox(pr, { w = 80, h = 22, min = 0, max = 999999, onChange = function(n) local g = V.game if g then g:TradeGold("a", n) end end })
    at(pr.goldA, 10, 132, pr)
    pr.goldB = ns.MakeNumberBox(pr, { w = 80, h = 22, min = 0, max = 999999, onChange = function(n) local g = V.game if g then g:TradeGold("b", n) end end })
    at(pr.goldB, 12 + (FW - 36) / 2, 132, pr)
    pr.cardA = button(pr, 98, 132, 140, 22, function() local g = V.game if g then g:TradeCard("a") end end)
    pr.cardB = button(pr, 100 + (FW - 36) / 2, 132, 140, 22, function() local g = V.game if g then g:TradeCard("b") end end)
    pr.plus = {}
    for k, inc in ipairs({ 10, 50, 100 }) do
        pr.plus[k] = button(pr, 72 + (k - 1) * 56, 80, 50, 22, function()
            local g = V.game
            local v = g and g:View()
            if v and v.auc then pr.num:SetValue(max(pr.num:Value(), v.auc.bid) + inc) end
        end)
        pr.plus[k]:SetText("+" .. inc)
    end
    pr.num = ns.MakeNumberBox(pr, { w = 90, h = 24, min = 1, max = 999999 })
    at(pr.num, 244, 79, pr)
    pr.b = {}
    for k = 1, 3 do
        pr.b[k] = button(pr, 10 + (k - 1) * 150, 60, 142, 26, function(self)
            local g = V.game
            if g and self.act then self.act(g) end
        end)
    end
    local dy = FCH - PAD - 30
    center.endTurn = button(col, FW - 130, dy, 130, 28, function() local g = V.game if g then g:Act{ k = "end" } end end)
    center.roll = button(col, FW - 268, dy, 130, 28, function() local g = V.game if g then g:Act{ k = "roll" } end end)
    center.clockBg = ns.Fill(col, "BACKGROUND", 0, 0, 0, 0.92)
    at(center.clockBg, 0, dy, col)
    center.clockBg:SetWidth(180)
    center.clockBg:SetHeight(28)
    center.clock = text(col, "GameFontHighlightSmall", 6, dy + 8, 170, nil, 12)
    for _, b in ipairs({ center.roll, center.endTurn, pr.b[1], pr.b[2], pr.b[3] }) do
        b.prim = edgeBars(b, "OVERLAY", C.gold, 2)
        for k = 1, 4 do b.prim[k]:Hide() end
    end
end
local function buildCard()
    local n = panel(midF, 2, RX, RY, RW, 220)
    card.f = n
    card.pic = n:CreateTexture(nil, "ARTWORK")
    card.pic:SetPoint("TOPLEFT", n, "TOPLEFT", 1, -1)
    card.pic:SetWidth(RW - 2)
    card.pic:SetHeight(PIC_H)
    card.pic:Hide()
    local body = ns.PlainFrame(n, 1)
    body:SetPoint("TOPLEFT", n, "TOPLEFT", 0, 0)
    body:SetPoint("BOTTOMRIGHT", n, "BOTTOMRIGHT", 0, 0)
    card.body = body
    n = body
    card.group = ns.Fill(n, "ARTWORK", 0.5, 0.5, 0.5, 1)
    card.group:SetHeight(6)
    card.group:SetPoint("TOPLEFT", n, "TOPLEFT", 1, -1)
    card.group:SetPoint("TOPRIGHT", n, "TOPRIGHT", -1, -1)
    card.iconBg = grad(n, "ARTWORK")
    card.iconBg:SetWidth(40)
    card.iconBg:SetHeight(40)
    at(card.iconBg, 8, 12, n)
    card.icon = n:CreateTexture(nil, "OVERLAY")
    card.icon:SetWidth(32)
    card.icon:SetHeight(32)
    card.icon:SetPoint("CENTER", card.iconBg, "CENTER", 0, 0)
    card.house = n:CreateTexture(nil, "OVERLAY")
    card.house:SetTexture(B.HOUSE_TEX)
    card.house:SetWidth(28)
    card.house:SetHeight(28)
    card.house:SetPoint("BOTTOMRIGHT", card.iconBg, "BOTTOMRIGHT", 6, -6)
    card.house:Hide()
    card.name = text(n, "GameFontNormal", 54, 10, 100, nil, 13)
    sizeM(card.name, 15)
    card.gname = text(n, "GameFontHighlightSmall", 54, 28, 100, nil, 10)
    card.price = text(n, "GameFontNormalLarge", 150, 10, 68, "RIGHT", 18)
    card.what = text(n, "GameFontHighlightSmall", 8, 56, 210, nil, 10)
    card.what:SetHeight(28)
    card.what:SetJustifyV("TOP")
    card.rows = {}
    for k = 1, 7 do
        local lab = text(n, "GameFontHighlightSmall", 8, 86 + (k - 1) * 13, 150, nil, 11)
        local val = text(n, "GameFontHighlightSmall", 150, 86 + (k - 1) * 13, 68, "RIGHT", 11)
        card.rows[k] = { lab = lab, val = val }
    end
    card.owner = text(n, "GameFontNormalSmall", 8, 164, 210, nil, 11)
    card.build = button(n, 6, 178, 104, 20, function() local g = V.game if g and g.sel then g:Act{ k = "up", c = g.sel } end end)
    card.down = button(n, 116, 178, 104, 20, function() local g = V.game if g and g.sel then g:Act{ k = "down", c = g.sel } end end)
    card.mortB = button(n, 6, 199, 104, 20, function() local g = V.game if g and g.sel then g:Act{ k = "mort", c = g.sel } end end)
    card.lift = button(n, 116, 199, 104, 20, function() local g = V.game if g and g.sel then g:Act{ k = "lift", c = g.sel } end end)
    hold.plate = ns.Fill(midF, "BACKGROUND", 0, 0, 0, 0.92)
    at(hold.plate, RX, RY + 248, midF)
    hold.plate:SetWidth(RW)
    hold.plate:SetHeight(184)
    hold.cap = text(midF, "GameFontNormal", RX + 8, RY + 253, RW - 16, nil, 12)
    hold.orn = ns.Fill(midF, "ARTWORK", 1, 1, 1, 1)
    hold.orn:SetHeight(1)
    at(hold.orn, RX + 8, RY + 268, midF)
    hold.orn:SetWidth(RW - 16)
    hold.rows = {}
    for k = 1, HOLD_LINES do
        local y = RY + 272 + (k - 1) * 16
        local r = {}
        r.bg = ns.Fill(midF, "BORDER", 1, 0.82, 0, 0.22)
        at(r.bg, RX + 4, y, midF)
        r.bg:SetWidth(RW - 8)
        r.bg:SetHeight(14)
        r.bg:Hide()
        r.chip = ns.Fill(midF, "ARTWORK", 0.5, 0.5, 0.5, 1)
        r.chip:SetWidth(5)
        r.chip:SetHeight(14)
        at(r.chip, RX + 8, y, midF)
        r.name = text(midF, "GameFontHighlightSmall", RX + 17, y + 1, 100, nil, 10)
        r.count = text(midF, "GameFontHighlightSmall", RX + 118, y + 1, 24, "RIGHT", 10)
        r.sq = {}
        for j = 1, 4 do
            local s = ns.PlainFrame(midF, 3)
            s:SetWidth(16)
            s:SetHeight(14)
            at(s, RX + RW - 24 - 18 * (4 - j), y, midF)
            s.bg = ns.Fill(s, "BACKGROUND", 0.2, 0.2, 0.2, 1)
            s.bg:SetAllPoints(s)
            s.edge = edgeBars(s, "BORDER", { 0, 0, 0, 1 })
            s.icon = s:CreateTexture(nil, "ARTWORK")
            s.icon:SetWidth(12)
            s.icon:SetHeight(12)
            s.icon:SetPoint("CENTER", s, "CENTER", 0, 0)
            s.mark = text(s, "GameFontHighlightSmall", nil, nil, 16, "CENTER", 8)
            s.mark:SetPoint("BOTTOM", s, "BOTTOM", 0, 0)
            s:EnableMouse(true)
            s:SetScript("OnEnter", function(self) ns.TipShow(self) end)
            s:SetScript("OnLeave", function() ns.TipHide() end)
            r.sq[j] = s
        end
        hold.rows[k] = r
    end
    side.trade = button(midF, RX, FY0 + FCH - 32, 150, 26, function() local g = V.game if g then g:TradeOpen() end end)
    side.quit = button(midF, RX + RW - 70, FY0 + FCH - 32, 70, 26, function()
        local g = V.game
        if not g then return end
        if g.quitAsk then
            g.quitAsk = nil
            g:Act{ k = "quit" }
        else
            g.quitAsk = g.t or 0
            g:Draw()
        end
    end)
end
local function applyArt(board)
    local a = WIN_ART[board] or WIN_ART.azeroth
    center.win.art:SetTexture(a[1])
    center.win.art:SetTexCoord(a[2], a[3], a[4], a[5])
    local d = DECK_ART[board] or DECK_ART.azeroth
    deckCard.f.pic:SetTexture(d[1])
    deckCard.f.pic:SetTexCoord(d[2], d[3], d[4], d[5])
    local m = MAP[board] or MAP.azeroth
    local iw, ih = FCW - 2, FCH - 2
    for k = 1, 12 do center.map[k]:Hide() end
    if m.kind == "one" then
        local t = center.map[1]
        t:SetTexture(m.path)
        t:SetTexCoord(m.coord[1], m.coord[2], m.coord[3], m.coord[4])
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", center.f, "TOPLEFT", 1, -1)
        t:SetWidth(iw)
        t:SetHeight(ih)
        t:Show()
    else
        local tw, th = iw / m.cols, ih / m.rows
        for r = 0, m.rows - 1 do
            for c = 0, m.cols - 1 do
                local k = r * m.cols + c + 1
                local t = center.map[k]
                t:SetTexture(m.path .. k)
                t:SetTexCoord(0, 1, 0, 1)
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", center.f, "TOPLEFT", 1 + c * tw, -(1 + r * th))
                t:SetWidth(tw)
                t:SetHeight(th)
                t:Show()
            end
        end
    end
end
V.WinArt = function(board) return WIN_ART[board] or WIN_ART.azeroth end
local function applyPalette(board)
    pal = B.palette[board] or B.palette.azeroth
    C.text, C.soft, C.title = pal.text, lighten(pal.muted, 0.38), pal.title
    center.f.bg:SetTexture(WHITE)
    vgrad(center.f.bg, pal.field2, pal.field)
    tintBars(center.f.edge, pal.frame2)
    tintBars(center.win.edge, pal.frame2)
    ns.Paint(center.log.bg, pal.log[1], pal.log[2], pal.log[3], 0.93)
    tintBars(center.log.edge, pal.cellline)
    ns.Paint(center.tray.bg, pal.log[1], pal.log[2], pal.log[3], 0.93)
    ns.Paint(hold.plate, pal.log[1], pal.log[2], pal.log[3], 0.92)
    local tile = B.bgTile[board] or B.bgTile.azeroth
    hudF.tile:SetTexture(tile)
    hudF.tile:SetTexCoord(0, CW / 256, 0, CH / 256)
    tintBars(center.tray.edge, pal.frame)
    for _, d in pairs(center.deck) do
        for k = 1, 3 do d.backs[k]:SetVertexColor(pal.frame2[1], pal.frame2[2], pal.frame2[3]) end
    end
    vgrad(center.prompt.bg, pal.panel2, pal.panel)
    tintBars(center.prompt.edge, pal.frame2)
    vgrad(center.prompt.iconBg, pal.cell, pal.cell2)
    vgrad(card.f.bg, pal.panel2, pal.panel)
    tintBars(card.f.edge, pal.frame2)
    vgrad(card.iconBg, pal.cell, pal.cell2)
    ns.Paint(hold.orn, pal.accent[1], pal.accent[2], pal.accent[3], 0.7)
    ns.Paint(bank.f.bg, pal.log[1], pal.log[2], pal.log[3], 1)
    tintBars(bank.f.edge, pal.frame)
    vgrad(deckCard.f.bg, pal.cell, pal.cell2)
    tintBars(deckCard.f.edge, pal.frame2)
    applyArt(board)
    for q = 1, 4 do
        local p = players[q]
        hgrad(p.bg, pal.panel, pal.panel2)
        hgrad(p.tm, pal.frame2, pal.accent)
    end
    local arts = CELL_ART[board] or {}
    local hu0, hu1, hv0, hv1 = B.HouseCoord(board, false)
    local ou0, ou1, ov0, ov1 = B.HouseCoord(board, true)
    card.house:SetTexCoord(hu0, hu1, hv0, hv1)
    for i = 0, 39 do
        local b = cells[i]
        for k = 1, 4 do b.houses[k]:SetTexCoord(hu0, hu1, hv0, hv1) end
        b.hotel:SetTexCoord(ou0, ou1, ov0, ov1)
        local art = arts[i]
        if art then
            b.bg:SetTexture(art[1])
            b.bg:SetTexCoord(art[2], art[3], art[4], art[5])
            b.bg:SetVertexColor(0.85, 0.85, 0.85, 1)
            ns.Paint(b.veil, 0, 0, 0, 0.85)
        else
            b.bg:SetTexture(WHITE)
            b.bg:SetTexCoord(0, 1, 0, 1)
            b.bg:SetVertexColor(1, 1, 1, 1)
            vgrad(b.bg, pal.cell, pal.cell2)
        end
        b.art = art ~= nil
        tintBars(b.line, pal.cellline)
    end
    if V.PaintPanels then V.PaintPanels(pal) end
end
function V.Ensure(canvas)
    if root then return end
    root = ns.NewFrame("Frame", nil, canvas)
    root:SetAllPoints()
    root:SetFrameLevel(canvas:GetFrameLevel() + 1)
    root:Hide()
    root.look = LOOKS.azeroth
    tableBg = ns.MakeTable(root)
    tableBg:Show()
    hudF = ns.PlainFrame(root, 2)
    hudF:SetAllPoints()
    hudF.tile = hudF:CreateTexture(nil, "BACKGROUND")
    hudF.tile:SetAllPoints(hudF)
    boardF = ns.PlainFrame(root, 4)
    boardF:SetAllPoints()
    midF = ns.PlainFrame(boardF, 3)
    midF:SetAllPoints()
    shadowF = ns.PlainFrame(boardF, 5)
    shadowF:SetAllPoints()
    fxF = ns.PlainFrame(root, 12)
    fxF:SetAllPoints()
    for i = 0, 39 do cells[i] = buildCell(i) end
    ringF = ns.PlainFrame(fxF, 2)
    ringF:SetWidth(14)
    ringF:SetHeight(14)
    ringF.bars = edgeBars(ringF, "OVERLAY", C.gold, 2)
    ringF:Hide()
    buildCenter()
    for q = 1, 4 do
        tokens[q] = buildToken(q)
        players[q] = buildPlayer(q)
    end
    buildBank()
    buildCard()
    buildDeckCard()
    buildCoins()
    curLook = "azeroth"
    V.root, V.boardF, V.hudF, V.fxF = root, boardF, hudF, fxF
    V.center, V.players, V.card, V.side = center, players, card, side
    V.prompt = center.prompt
    if V.EnsurePanels then V.EnsurePanels() end
    applyPalette(curLook)
    ns.SlideAnchor("tycoon.roll", center.roll)
    ns.SlideAnchor("tycoon.prompt", center.prompt)
    ns.SlideAnchor("tycoon.board", boardF)
    ns.SlideAnchor("tycoon.card", card.f)
    ns.SlideAnchor("tycoon.trade", side.trade)
end
function V.Root() return root end
function V.SetLook(board)
    if not root or curLook == board or not LOOKS[board] then return end
    curLook = board
    ns.Restyle(root, LOOKS[board])
    applyPalette(board)
end
function V.Reset()
    if V.SetPrimary then V.SetPrimary(nil) end
    shown, anim = {}, {}
    fx = { flash = {}, pop = {}, float = {}, pulse = {}, gold = {}, fly = {}, trail = {} }
    fx.dice, fx.card = nil, nil
    for q = 1, 4 do
        local p = players[q]
        if p then
            p.cash = nil
            p.float:Hide()
        end
    end
    if deckCard.f then deckCard.f:Hide() end
    for k = 1, #coins do coins[k]:Hide() end
end
local function panelXY(q)
    return PX + 104, PY + (q - 1) * PANEL_H + 35
end
local function bankXY()
    return PX + 100, PY + 4 * PANEL_H + 16
end
local function fly(g, x0, y0, x1, y1)
    local t = g.t or 0
    for k = 1, COIN_N do
        fx.fly[#fx.fly + 1] = { t0 = t + (k - 1) * 0.07, x0 = x0 + (k - 2.5) * 6, y0 = y0, x1 = x1, y1 = y1 }
    end
end
function V.Show() if root then root:Show() end end
function V.Hide() if root then root:Hide() end end
function V.Moving()
    for q = 1, 4 do if anim[q] then return true end end
    return fx.dice ~= nil
end
function V.Shim(v)
    local S = { n = v.n, over = v.over, phase = v.phase, turn = v.turn, rolled = v.rolled, offers = v.offers or 0,
                cash = {}, alive = {}, free = {}, jail = {}, own = v.own, lv = v.lv, mort = v.mort, buyAt = v.buyAt,
                debts = {}, liens = {}, seq = v.seq or 1, offer = v.offer,
                dice = (v.dice and v.dice < 36) and { floor(v.dice / 6) + 1, v.dice % 6 + 1 } or { 0, 0 } }
    for q = 1, v.n do
        local st = v.seats[q]
        S.cash[q], S.alive[q], S.free[q], S.jail[q] = st.cash, st.alive, st.free, st.jail
    end
    if v.auc then
        S.auc = { c = v.auc.c, bid = v.auc.bid, lead = v.auc.lead, who = v.who, passed = {} }
        for q = 1, v.n do
            if floor(v.auc.passed / 2 ^ (q - 1)) % 2 == 1 then S.auc.passed[q] = true end
        end
    end
    if v.debt then S.debts[1] = { from = v.who, to = v.debt.to, sum = v.debt.sum } end
    if v.lien then S.liens[1] = { s = v.who, c = v.lien } end
    return S
end
local WHY = {
    build = "tycoon.whyBuild", group = "tycoon.whyGroup", mortGroup = "tycoon.whyMortGroup", even = "tycoon.whyEven",
    cash = "tycoon.whyCash", down = "tycoon.whyDown", evenDown = "tycoon.whyEvenDown", mort = "tycoon.whyMort",
    built = "tycoon.whyBuilt", lift = "tycoon.whyLift",
}
function V.Why(board, reason)
    if reason == "noHouses" then return ns.T("tycoon.whyNoHouses", ns.T(B.Key(board, "houses"))) end
    if reason == "noHotels" then return ns.T("tycoon.whyNoHotels", ns.T(B.Key(board, "hotels"))) end
    return ns.T(WHY[reason] or "tycoon.whyPhase")
end
local function cellName(board, c)
    return ns.T(B.CellName(board, c))
end
V.CellName = cellName
local function seatRef(g, s)
    if s == 0 then return ns.T("tycoon.bank") end
    return g:SeatTag(s)
end
function V.EventText(g, v, e)
    local board = g.board
    local k, s, c, n = e.k, e.s, e.c, e.v
    local T = ns.T
    if k == "roll" then return T("tycoon.lgRoll", seatRef(g, s), floor(c / 6) + 1, c % 6 + 1) end
    if k == "move" then return T("tycoon.lgMove", seatRef(g, s), cellName(board, c)) end
    if k == "go" then return T("tycoon.lgGo", seatRef(g, s), cellName(board, 0)) end
    if k == "buy" then return T("tycoon.lgBuy", seatRef(g, s), cellName(board, c), n) end
    if k == "rent" then return T("tycoon.lgRent", seatRef(g, s), n, cellName(board, c)) end
    if k == "tax" then return T("tycoon.lgTax", seatRef(g, s), cellName(board, c), n) end
    if k == "card" then
        local deck = c > 16 and "t" or "c"
        return T("tycoon.lgCard", seatRef(g, s), T(B.CardKey(board, deck, deck == "t" and c - 16 or c)))
    end
    if k == "jail" then return T("tycoon.lgJail", seatRef(g, s), T(B.Key(board, "jailed"))) end
    if k == "bail" then return T("tycoon.lgBail", seatRef(g, s)) end
    if k == "freecard" and n == 1 then return T("tycoon.lgFree", seatRef(g, s), T(B.Key(board, "card"))) end
    if k == "stay" then return T("tycoon.lgStay", seatRef(g, s)) end
    if k == "unjail" then return T("tycoon.lgUnjail", seatRef(g, s)) end
    if k == "forsale" then return T("tycoon.lgForsale", cellName(board, c), n) end
    if k == "auction" then return T("tycoon.lgAuction", cellName(board, c)) end
    if k == "bid" then return T("tycoon.lgBid", seatRef(g, s), n) end
    if k == "pass" then return T("tycoon.lgPass", seatRef(g, s)) end
    if k == "won" then return T("tycoon.lgWon", seatRef(g, s), cellName(board, c), n) end
    if k == "nobid" then return T("tycoon.lgNobid", cellName(board, c)) end
    if k == "up" then return T("tycoon.lgUp", seatRef(g, s), cellName(board, c)) end
    if k == "hotel" then return T("tycoon.lgHotel", seatRef(g, s), T(B.Key(board, "hotel")), cellName(board, c)) end
    if k == "down" then return T("tycoon.lgDown", seatRef(g, s), cellName(board, c), n) end
    if k == "mort" then return T("tycoon.lgMort", seatRef(g, s), cellName(board, c), n) end
    if k == "lift" then return T("tycoon.lgLift", seatRef(g, s), cellName(board, c), n) end
    if k == "offer" then return T("tycoon.lgOffer", seatRef(g, s), seatRef(g, c)) end
    if k == "yes" then return T("tycoon.lgYes", seatRef(g, s)) end
    if k == "no" then return T("tycoon.lgNo", seatRef(g, s)) end
    if k == "lien" then return T(n == 1 and "tycoon.lgLien1" or "tycoon.lgLien0", seatRef(g, s), cellName(board, c)) end
    if k == "debt" then return T("tycoon.lgDebt", seatRef(g, s), n, seatRef(g, c)) end
    if k == "bankrupt" then
        if c > 0 then return T("tycoon.lgBankrupt", seatRef(g, s), seatRef(g, c)) end
        return T("tycoon.lgBankruptBank", seatRef(g, s))
    end
    if k == "quit" then return T("tycoon.lgQuit", seatRef(g, s)) end
    if k == "turn" then return T("tycoon.lgTurn", seatRef(g, s)) end
    if k == "over" then return T("tycoon.lgOver", seatRef(g, s)) end
    if k == "pay" then return T("tycoon.lgPay", seatRef(g, s), n) end
    if k == "get" then return T("tycoon.lgGet", seatRef(g, s), n) end
    if k == "repairs" then return T("tycoon.lgRepairs", seatRef(g, s), n) end
    if k == "each" then return T("tycoon.lgEach", seatRef(g, s), n) end
    if k == "birthday" then return T("tycoon.lgBirthday", seatRef(g, s), n) end
    if k == "set" then return T("tycoon.lgSet", seatRef(g, s), T(B.GroupKey(board, n))) end
    if k == "setup" then return T("tycoon.lgStart", seatRef(g, s)) end
    return nil
end
function V.Event(g, e)
    if not root then return end
    local k, s, c, n = e.k, e.s, e.c, e.v
    local t = g.t or 0
    local v = g:View()
    if k == "roll" and c and c < 36 then
        fx.dice = { t0 = t, d1 = floor(c / 6) + 1, d2 = c % 6 + 1, tick = 0 }
    elseif k == "buy" or k == "won" then
        fx.flash[c] = { t0 = t, s = s }
        local x0, y0 = panelXY(s)
        local x1, y1 = cellXY(c)
        fly(g, x0, y0, x1, y1)
    elseif k == "rent" and n > 0 then
        local owner = v and v.own[c] or 0
        local x0, y0 = panelXY(s)
        local x1, y1 = cellXY(c)
        fly(g, x0, y0, x1, y1)
        if owner > 0 then
            local x2, y2 = panelXY(owner)
            local f = { t0 = t + 0.3, x0 = x1, y0 = y1, x1 = x2, y1 = y2 }
            for j = 1, COIN_N do
                fx.fly[#fx.fly + 1] = { t0 = f.t0 + (j - 1) * 0.07, x0 = x1 + (j - 2.5) * 6, y0 = y1, x1 = x2, y1 = y2 }
            end
        end
    elseif k == "tax" or k == "pay" or k == "repairs" or k == "bail" or k == "each" or k == "mort" or k == "lift" then
        local x0, y0 = panelXY(s)
        local x1, y1 = bankXY()
        if k == "mort" then fly(g, x1, y1, x0, y0) else fly(g, x0, y0, x1, y1) end
    elseif k == "get" or k == "go" or k == "birthday" or k == "down" then
        local x0, y0 = bankXY()
        local x1, y1 = panelXY(s)
        fly(g, x0, y0, x1, y1)
    elseif k == "up" or k == "hotel" then
        fx.pop[c] = { t0 = t }
    elseif k == "set" and GROUPS[n] then
        for i, cc in ipairs(GROUPS[n]) do fx.flash[cc] = { t0 = t + (i - 1) * 0.12, s = s } end
    elseif k == "turn" then
        fx.pulse[s] = { t0 = t }
    elseif k == "card" then
        local deck = c > 16 and "t" or "c"
        fx.card = { t0 = t, deck = deck, id = deck == "t" and c - 16 or c, board = g.board }
    end
end
function V.Status(g, v)
    local me = g:Me()
    local T = ns.T
    if v.over then return T("tycoon.stOver"), C.soft end
    local ph, who = v.phase, v.who
    local mine = who == me
    local tag = g:SeatTag(who)
    if ph == "pre" then
        if mine then
            if v.seats[me].jail > 0 and not v.rolled then return T("tycoon.stJail", T(B.Key(g.board, "card"))), C.gold end
            return T("tycoon.stRoll"), C.gold
        end
        return T("tycoon.stTurn", tag), C.soft
    end
    if ph == "post" then
        if mine then return T("tycoon.stPost"), C.gold end
        return T("tycoon.stTurn", tag), C.soft
    end
    if ph == "buy" then
        if mine then return T("tycoon.stBuy"), C.gold end
        return T("tycoon.stTurn", tag), C.soft
    end
    if ph == "auction" then
        if mine then return T("tycoon.stBid"), C.gold end
        return T("tycoon.stBids", tag), C.soft
    end
    if ph == "trade" then
        if mine then return T("tycoon.stTradeMe"), C.gold end
        return T("tycoon.stTrade", tag), C.soft
    end
    if ph == "debt" then
        if mine then return T("tycoon.stDebt", v.debt and v.debt.sum or 0), C.bad end
        return T("tycoon.stDebtOf", tag, v.debt and v.debt.sum or 0), C.soft
    end
    if ph == "lien" then
        if mine then return T("tycoon.stLien"), C.gold end
        return T("tycoon.stLienOf", tag), C.soft
    end
    return "", C.soft
end
local function iconShow(b)
    local rows = b.sd == "top" or b.sd == "bottom"
    if b.sd == "corner" or not (b.occ or (b.mort and rows)) then
        b.icon:Show()
        b.iconBg:Show()
    else
        b.icon:Hide()
        b.iconBg:Hide()
    end
    if b.mort and not (rows and b.occ) then b.mortText:Show() else b.mortText:Hide() end
end
local function placeTokens(v)
    local here, order = {}, {}
    for q = 1, v.n do
        local st = v.seats[q]
        if st.alive or v.over then
            local target = st.pos
            if shown[q] == nil then shown[q] = target end
            if not anim[q] and shown[q] ~= target then
                local d = (target - shown[q]) % 40
                if d <= 12 then
                    anim[q] = { from = shown[q], d = d, at = 0 }
                else
                    anim[q] = { from = shown[q], to = target, d = 1, at = 0, fly = true }
                end
            end
            if not anim[q] then
                here[shown[q]] = (here[shown[q]] or 0) + 1
                order[q] = here[shown[q]]
            end
        end
    end
    for i = 0, 39 do
        local b = cells[i]
        local occ = here[i] ~= nil
        if b.occ ~= occ then
            b.occ = occ
            iconShow(b)
        end
    end
    for q = 1, 4 do
        local f = tokens[q]
        local st = v.seats[q]
        if st and (st.alive or v.over) then
            local a = anim[q]
            local x, y, hop, sz
            if a and a.fly then
                local fr = min(1, a.at)
                local x1, y1 = cellXY(a.from)
                local x2, y2 = cellXY(a.to)
                x, y = x1 + (x2 - x1) * fr, y1 + (y2 - y1) * fr
                hop, sz = 70 * sin(fr * PI), TOKEN + 10
            elseif a then
                local c1 = (a.from + floor(a.at)) % 40
                local c2 = (c1 + 1) % 40
                local fr = a.at - floor(a.at)
                local x1, y1 = cellXY(c1)
                local x2, y2 = cellXY(c2)
                x, y = x1 + (x2 - x1) * fr, y1 + (y2 - y1) * fr
                hop, sz = 14 * sin(fr * PI), TOKEN + 4
            else
                x, y, sz = tokenSlot(shown[q], order[q] or 1, here[shown[q]] or 1)
                hop = 0
            end
            local sc = B.SEAT_COLOR[q]
            f:SetWidth(sz)
            f:SetHeight(sz)
            f:ClearAllPoints()
            f:SetPoint("CENTER", boardF, "TOPLEFT", x, -(y - hop - 3))
            f.shadow:ClearAllPoints()
            f.shadow:SetPoint("CENTER", boardF, "TOPLEFT", x, -(y + sz * 0.4))
            f.shadow:SetVertexColor(sc[1], sc[2], sc[3])
            f.shadow:SetAlpha(0.95 * (1 - min(1, hop / 90)))
            f.shadow:SetWidth(sz * (1.35 + hop / 60))
            f.shadow:SetHeight(sz * 0.55)
            f.shadow:Show()
            V.TokenTex(f.tex, st.token)
            V.TeamTex(f.team, st.token, q)
            f:Show()
        else
            f:Hide()
            f.shadow:Hide()
        end
    end
end
local function tickCoins(t)
    local live = {}
    for _, c in ipairs(fx.fly) do
        if t - c.t0 < COIN_T then live[#live + 1] = c end
    end
    fx.fly = live
    for k = 1, #coins do
        local f = coins[k]
        local c = live[k]
        if c and t >= c.t0 then
            local p = (t - c.t0) / COIN_T
            local x = c.x0 + (c.x1 - c.x0) * p
            local arc = p < 0.78 and 40 * sin(p / 0.78 * PI) or 7 * sin((p - 0.78) / 0.22 * PI)
            local y = c.y0 + (c.y1 - c.y0) * min(1, p / 0.78) - arc
            f:ClearAllPoints()
            f:SetPoint("CENTER", fxF, "TOPLEFT", x, -y)
            f:SetAlpha(p > 0.8 and (1 - p) / 0.2 or 1)
            f:Show()
        else
            f:Hide()
        end
    end
end
local function tickDice(t)
    local d = fx.dice
    local cx = (FW - 216) / 2
    if not d then
        if fx.rollWait then
            local ph = t % 2.6
            local dx = ph < 0.32 and sin(t * 42) * 2 or 0
            at(center.d1, cx - 46 + dx, 16, center.tray)
            at(center.d2, cx + 10 - dx, 16, center.tray)
        end
        return
    end
    if t - d.t0 >= DICE_SPIN then
        showDie(center.d1, d.d1)
        showDie(center.d2, d.d2)
        center.sum:SetText(d.d1 .. "+" .. d.d2)
        at(center.d1, cx - 46, 16, center.tray)
        at(center.d2, cx + 10, 16, center.tray)
        fx.dice = nil
        return
    end
    local p = (t - d.t0) / DICE_SPIN
    local hop = 14 * math.abs(sin(p * PI * 3)) * (1 - p)
    at(center.d1, cx - 46, 16 - hop, center.tray)
    at(center.d2, cx + 10, 16 - hop * 0.7, center.tray)
    if t - d.tick >= DICE_TICK then
        d.tick = t
        showDie(center.d1, math.random(6))
        showDie(center.d2, math.random(6))
        center.sum:SetText("")
    end
end
local function tickGlow(v, t)
    for c, tr in pairs(fx.trail) do
        local p = (t - tr.t0) / 1.0
        local b = cells[c]
        if p >= 1 then
            fx.trail[c] = nil
            if fx.glowCell ~= c then b.glow:Hide() end
        else
            local sc = B.SEAT_COLOR[tr.s]
            ns.Paint(b.glow, sc[1], sc[2], sc[3], 0.28 * (1 - p))
            b.glow:Show()
        end
    end
    local rg = fx.ring
    if rg then
        local p = (t - rg.t0) / 0.45
        if p >= 1 then
            fx.ring = nil
            ringF:Hide()
        else
            local sz = 14 + 26 * p
            local x, y = cellXY(rg.c)
            ringF:SetWidth(sz)
            ringF:SetHeight(sz)
            ringF:ClearAllPoints()
            ringF:SetPoint("CENTER", boardF, "TOPLEFT", x, -y)
            showBars(ringF.bars, true, B.SEAT_COLOR[rg.s])
            ringF:SetAlpha(1 - p)
            ringF:Show()
        end
    end
    local pos = (not v.over and v.seats[v.turn]) and v.seats[v.turn].pos or nil
    if anim[v.turn] then pos = nil end
    if fx.glowCell and fx.glowCell ~= pos then
        if not fx.trail[fx.glowCell] then cells[fx.glowCell].glow:Hide() end
        fx.glowCell = nil
    end
    if pos then
        local sc = B.SEAT_COLOR[v.turn]
        local b = cells[pos]
        ns.Paint(b.glow, sc[1], sc[2], sc[3], 0.10 + 0.06 * sin(t * 2.5))
        b.glow:Show()
        fx.glowCell = pos
    end
end
local function tickCells(t)
    for c, f in pairs(fx.flash) do
        local p = max(0, (t - f.t0) / FLASH_T)
        local b = cells[c]
        if p >= 1 then
            fx.flash[c] = nil
            b.flash:Hide()
        else
            local sc = B.SEAT_COLOR[f.s] or C.gold
            ns.Paint(b.flash, sc[1], sc[2], sc[3], 0.9 * (1 - p))
            b.flash:Show()
        end
    end
    for c, f in pairs(fx.pop) do
        local p = (t - f.t0) / POP_T
        local b = cells[c]
        local k = p >= 1 and 1 or (1 + 1.6 * (1 - p))
        for j = 1, 4 do
            b.houses[j]:SetWidth(HOUSE_SZ * k)
            b.houses[j]:SetHeight(HOUSE_SZ * k)
        end
        b.hotel:SetWidth(HOTEL_SZ * k)
        b.hotel:SetHeight(HOTEL_SZ * k)
        if p >= 1 then
            fx.pop[c] = nil
            b.dust:Hide()
        else
            b.dust:SetWidth(12 + 34 * p)
            b.dust:SetHeight(12 + 34 * p)
            b.dust:SetAlpha(0.7 * (1 - p))
            b.dust:Show()
        end
    end
end
local function tickPlayers(g, v, t)
    for q = 1, 4 do
        local p = players[q]
        local st = v.seats[q]
        if st then
            local gl = fx.gold[q]
            if gl then
                local k = min(1, (t - gl.t0) / GOLD_T)
                local val = floor(gl.from + (gl.to - gl.from) * k + 0.5)
                p.gold:SetText(gold(val))
                if k >= 1 then fx.gold[q] = nil end
            end
            local fl = fx.float[q]
            if fl then
                local k = (t - fl.t0) / FLOAT_T
                if k >= 1 then
                    fx.float[q] = nil
                    p.float:Hide()
                else
                    p.float:ClearAllPoints()
                    p.float:SetPoint("RIGHT", p, "TOPRIGHT", -8, -(36 - 6 * k))
                    p.float:SetAlpha(k < 0.6 and 1 or (1 - k) / 0.4)
                    p.float:Show()
                end
            end
            local pu = fx.pulse[q]
            if pu then
                local k = (t - pu.t0) / PULSE_T
                if k >= 1 then
                    fx.pulse[q] = nil
                    tintBars(p.edge, pal.accent)
                else
                    local a = 0.5 + 0.5 * sin(k * PI * 6)
                    local e = pal.accent
                    tintBars(p.edge, { e[1] * a + 1 * (1 - a), e[2] * a + 1 * (1 - a), e[3] * a + 0.8 * (1 - a) })
                end
            end
        end
    end
end
local function tickCard(g, t)
    local cd = fx.card
    local f = deckCard.f
    if not cd then return end
    local age = t - cd.t0
    local total = CARD_FLIP * 2 + CARD_HOLD + CARD_OUT
    if age >= total then
        fx.card = nil
        f:Hide()
        return
    end
    local board = cd.board
    local T = ns.T
    local w = 190
    local face = age >= CARD_FLIP
    if age < CARD_FLIP * 2 then
        local p = age / CARD_FLIP
        w = p < 1 and 190 * (1 - p) or 190 * (p - 1)
    end
    f:SetWidth(max(2, w))
    local k = min(1, age / CARD_FLIP)
    local dx = cd.deck == "c" and (10 + 36) or (FW - 82 + 36)
    local x0, y0 = FX0 + MX + dx, FY0 + TAB_Y + TAB_H / 2
    local x1, y1 = FX0 + MX + FW / 2, FY0 + WIN_Y + 150
    f:ClearAllPoints()
    f:SetPoint("CENTER", boardF, "TOPLEFT", x0 + (x1 - x0) * k, -(y0 + (y1 - y0) * k))
    f:SetAlpha(age > total - CARD_OUT and (total - age) / CARD_OUT or 1)
    f.head:SetText(T(B.Key(board, cd.deck == "c" and "chance" or "chest")))
    paint(f.head, { 1, 1, 1 })
    if face then
        f.body:SetText(T(B.CardKey(board, cd.deck, cd.id)))
        f.body:Show()
        f.pic:Show()
    else
        f.body:Hide()
        f.pic:Hide()
    end
    paint(f.body, C.ink)
    f.head:SetWidth(max(1, w - 20))
    f.body:SetWidth(max(1, w - 20))
    f:Show()
end
function V.Tick(g, dt)
    if not root or not root:IsShown() then
        for q = 1, 4 do
            local a = anim[q]
            if a then
                shown[q] = a.fly and a.to or (a.from + a.d) % 40
                anim[q] = nil
            end
        end
        fx.dice = nil
        return
    end
    local v = g:View()
    if not v then return end
    local t = g.t or 0
    local moved = false
    for q = 1, 4 do
        local a = anim[q]
        if a then
            a.at = a.at + dt / (a.fly and FLY_T or STEP)
            if not a.fly then
                local cur = (a.from + floor(a.at)) % 40
                if cur ~= a.last then
                    a.last = cur
                    fx.trail[cur] = { t0 = t, s = q }
                end
            end
            if a.at >= a.d then
                shown[q] = a.fly and a.to or (a.from + a.d) % 40
                anim[q] = nil
                fx.ring = { t0 = t, c = shown[q], s = q }
            end
            moved = true
        end
    end
    if moved then placeTokens(v) end
    tickCoins(t)
    tickDice(t)
    tickCells(t)
    tickGlow(v, t)
    tickPlayers(g, v, t)
    tickCard(g, t)
    local pb = fx.primary
    if pb and pb.prim then
        local a = 0.55 + 0.45 * sin(t * 3)
        for k = 1, 4 do pb.prim[k]:SetAlpha(a) end
    end
end
local function drawCells(g, v, S)
    local board = g.board
    local tb = g.tb
    local focus = g.sel or g.hover
    local me = g:Me()
    for i = 0, 39 do
        local b = cells[i]
        local cell = CELLS[i]
        V.CellIcon(b.icon, board, i)
        b.cap:SetText(cellName(board, i))
        local owner = cell.price and v.own[i] or 0
        local lv = cell.price and v.lv[i] or 0
        local mort = cell.price and v.mort[i] or false
        if b.art then
            paint(b.cap, C.gold)
            b.veil:Show()
        else
            paint(b.cap, mort and C.pale or C.ink)
            b.veil:Hide()
        end
        local gc
        if cell.t == "prop" then gc = B.GROUP_COLOR[cell.g]
        elseif cell.t == "rail" then gc = pal.rail
        elseif cell.t == "util" then gc = pal.util
        elseif cell.t == "tax" then gc = pal.tax
        elseif cell.t == "go" then gc = pal.go end
        if cell.g then
            ns.Paint(b.stripe, gc[1], gc[2], gc[3], 1)
            b.stripe:Show()
        else
            b.stripe:Hide()
        end
        if gc then
            local bc = gc
            local label
            if cell.t == "go" then label = "+200"
            elseif cell.t == "tax" then label = tostring(cell.tax)
            elseif owner > 0 and mort then
                bc = { 0.35, 0.35, 0.35 }
                label = tostring(cell.price)
            elseif owner > 0 and owner ~= me then
                label = tostring(R.Rent(S, i))
            else
                label = tostring(cell.price)
            end
            local br, bg_, bb, dark = bandTone(bc)
            ns.Paint(b.band, br, bg_, bb, 1)
            b.band:Show()
            if b.sd == "left" or b.sd == "right" then
                b.price:SetText(label .. "\n" .. GOLD_MARK_L)
            else
                b.price:SetText(label .. GOLD_MARK_L)
            end
            paint(b.price, dark and C.ink or { 1, 1, 1 })
            if owner > 0 and v.seats[owner] then
                V.TokenTex(b.ownTex, v.seats[owner].token)
                b.ownTex:Show()
            else
                b.ownTex:Hide()
            end
        else
            b.band:Hide()
            b.price:SetText("")
            b.ownTex:Hide()
        end
        if owner > 0 then
            local sc = B.SEAT_COLOR[owner]
            ns.Paint(b.tint, sc[1], sc[2], sc[3], 0.3)
            b.tint:Show()
            local full = cell.t == "prop" and R.GroupFull(S, owner, cell.g)
            showBars(b.own, true, full and C.gold or sc)
        else
            b.tint:Hide()
            showBars(b.own, false)
        end
        for k = 1, 4 do
            if lv >= k and lv < 5 then b.houses[k]:Show() else b.houses[k]:Hide() end
        end
        if lv == 5 then b.hotel:Show() else b.hotel:Hide() end
        if mort then
            b.dim:Show()
            b.icon:SetAlpha(0.35)
            b.mortText:SetText(ns.T("tycoon.cardMortgaged"))
        else
            b.dim:Hide()
            b.icon:SetAlpha(1)
        end
        if b.sd == "left" or b.sd == "right" then b.cap:SetJustifyV(mort and "TOP" or "MIDDLE") end
        b.mort = mort
        iconShow(b)
        local picked = tb and (tb.give[i] or tb.get[i])
        if picked then
            showBars(b.sel, true, C.ok)
        elseif focus == i then
            showBars(b.sel, true, pal.accent)
        elseif focus and cell.g and CELLS[focus].g == cell.g then
            showBars(b.sel, true, gc)
        else
            showBars(b.sel, false)
        end
    end
end
local function drawPlayers(g, v, S)
    local me = g:Me()
    local T = ns.T
    local t = g.t or 0
    for q = 1, 4 do
        local p = players[q]
        local st = v.seats[q]
        if st then
            p:Show()
            V.SetRing(p.ring, q, st.token)
            p.ring.tex:SetAlpha(st.alive and 1 or 0.35)
            p.name:SetText(g:SeatName(q) .. ((q == me) and (" (" .. T("tycoon.you") .. ")") or ""))
            paint(p.name, (q == v.turn and not v.over) and C.gold or C.text)
            local prev = p.cash
            if prev ~= nil and prev ~= st.cash and not V.silent and not (v.ev and v.ev.k == "setup") then
                local d = st.cash - prev
                fx.gold[q] = { t0 = t, from = fx.gold[q] and fx.gold[q].from or prev, to = st.cash }
                p.float.text:SetText((d > 0 and "+" or "-") .. gold(math.abs(d)))
                paint(p.float.text, d > 0 and C.ok or C.bad)
                fx.float[q] = { t0 = t }
            elseif not fx.gold[q] then
                p.gold:SetText(gold(st.cash))
            end
            p.cash = st.cash
            paint(p.gold, st.alive and C.gold or C.cap)
            local plots = 0
            for _, c in ipairs(PROPS) do if v.own[c] == q then plots = plots + 1 end end
            p.info:SetText(T("tycoon.pPlots", plots))
            p.info3:SetText(st.free ~= "" and T("tycoon.pCards", T(B.Key(g.board, "card")), #st.free) or "")
            paint(p.info3, C.gold)
            paint(p.info, C.soft)
            local info2, c2 = "", C.soft
            if not st.alive and st.out > 0 and not (v.over and st.out == v.n) then
                info2 = T("tycoon.pOut", v.n - st.out + 1)
            elseif v.over and st.out == v.n then
                info2, c2 = T("tycoon.pWin"), C.gold
            elseif st.jail > 0 then
                info2, c2 = T(B.Key(g.board, "jailed")), C.bad
            elseif g.away[q] then
                info2 = T("tycoon.pAway")
            elseif st.alive and S then
                info2 = T("tycoon.pCapital", R.Capital(S, q))
            end
            p.info2:SetText(info2)
            paint(p.info2, c2)
            p.num:SetText(tostring(q))
            paint(p.num, C.cap)
            for gi = 1, 10 do
                local list = GROUPS[gi]
                local mine = 0
                for _, c in ipairs(list) do if v.own[c] == q then mine = mine + 1 end end
                local gc = gi <= 8 and B.GROUP_COLOR[gi] or gi == 9 and pal.rail or pal.util
                ns.Paint(p.chips[gi], gc[1], gc[2], gc[3], mine == #list and 1 or (mine > 0 and 0.6 or 0.3))
            end
            local waiting = (v.who == q) and not v.over
            showBars(p.edge2, waiting, pal.accent)
            if waiting then
                ns.Paint(p.waitBar, pal.accent[1], pal.accent[2], pal.accent[3], 1)
                p.waitBar:Show()
            else
                p.waitBar:Hide()
            end
            if not fx.pulse[q] then
                local e = waiting and pal.accent or (q == v.turn and not v.over and pal.frame2) or pal.frame
                tintBars(p.edge, e)
            end
            local left, limit = g:LeftFor(q)
            if left and limit and limit > 0 then
                p.tm:SetWidth(max(1, (p:GetWidth() - 2) * max(0, min(1, left / limit))))
                p.tm:Show()
                p.tmBg:Show()
            else
                p.tm:Hide()
                p.tmBg:Hide()
            end
        else
            p:Hide()
            p.cash = nil
        end
    end
end
local function drawBank(g, v, S)
    local T = ns.T
    bank.rows[1].lab:SetText(T("tycoon.bankHouses", T(B.Key(g.board, "house"))))
    bank.rows[1].val:SetText(T("tycoon.bankOf", R.Houses(S), B.HOUSES))
    bank.rows[2].lab:SetText(T("tycoon.bankHouses", T(B.Key(g.board, "hotel"))))
    bank.rows[2].val:SetText(T("tycoon.bankOf", R.Hotels(S), B.HOTELS))
    for k = 1, 2 do
        paint(bank.rows[k].lab, C.soft)
        paint(bank.rows[k].val, C.text)
    end
end
local function listNames(g, cells, gold, cards)
    local out = {}
    for _, c in ipairs(cells) do out[#out + 1] = cellName(g.board, c) end
    if gold and gold > 0 then out[#out + 1] = ns.T("tycoon.goldN", gold) end
    if cards and cards ~= "" then out[#out + 1] = ns.T("tycoon.pCards", ns.T(B.Key(g.board, "card")), #cards) end
    if #out == 0 then return ns.T("tycoon.tradeNone") end
    return table.concat(out, ", ")
end
local function setBtn(b, label, on, tip)
    b:SetText(label)
    b.tipTitle = false
    b.tip = tip
    if on then b:Enable() else b:Disable() end
    b:Show()
end
function V.SetPrimary(b)
    local old = fx.primary
    if old and old.prim then
        for k = 1, 4 do old.prim[k]:Hide() end
    end
    fx.primary = b
    if b and b.prim then
        for k = 1, 4 do b.prim[k]:Show() end
    end
end
local function hidePrompt()
    local pr = center.prompt
    pr.icon:Hide()
    pr.iconBg:Hide()
    pr.bar:Hide()
    pr.title:SetText("")
    pr.sub:SetText("")
    pr.price:SetText("")
    pr.text:SetText("")
    pr.give:SetText("")
    pr.get:SetText("")
    for k = 1, 3 do pr.who[k]:Hide(); pr.plus[k]:Hide(); pr.b[k]:Hide() end
    pr.num:Hide()
    pr.goldA:Hide()
    pr.goldB:Hide()
    pr.cardA:Hide()
    pr.cardB:Hide()
    pr.title:ClearAllPoints()
    pr.title:SetPoint("TOPLEFT", pr, "TOPLEFT", 72, -12)
    pr.text:ClearAllPoints()
    pr.text:SetPoint("TOPLEFT", pr, "TOPLEFT", 72, -48)
end
local function plainPrompt()
    local pr = center.prompt
    pr.title:ClearAllPoints()
    pr.title:SetPoint("TOPLEFT", pr, "TOPLEFT", 12, -10)
    pr.text:ClearAllPoints()
    pr.text:SetPoint("TOPLEFT", pr, "TOPLEFT", 12, -32)
end
local function promptLot(g, v, c)
    local pr = center.prompt
    local cell = CELLS[c]
    local T = ns.T
    V.CellIcon(pr.icon, g.board, c)
    pr.icon:Show()
    pr.iconBg:Show()
    local gc = cell.t == "prop" and B.GROUP_COLOR[cell.g] or cell.t == "rail" and pal.rail or pal.util
    ns.Paint(pr.bar, gc[1], gc[2], gc[3], 1)
    pr.bar:Show()
    pr.title:SetText(cellName(g.board, c))
    pr.sub:SetText(cell.g and T(B.GroupKey(g.board, cell.g)) or "")
    paint(pr.sub, C.soft)
    pr.price:SetText(gold(cell.price))
    paint(pr.price, C.gold)
    local line
    if cell.t == "prop" then
        line = T("tycoon.cardRent") .. " " .. cell.rent[1] .. " / " .. cell.rent[6] .. ". " .. T("tycoon.cardHouse", T(B.Key(g.board, "house")), cell.house)
    else
        line = T(cell.t == "rail" and "tycoon.cardRail" or "tycoon.cardUtil")
    end
    pr.text:SetText(line)
    paint(pr.text, C.text)
end
local function promptSize(h)
    local pr = center.prompt
    pr:SetHeight(h)
    for k = 1, 3 do at(pr.b[k], 10 + (k - 1) * 150, h - 34, pr) end
    pr:Show()
    return h
end
V.setBtn, V.hidePrompt, V.plainPrompt, V.promptLot, V.promptSize, V.listNames = setBtn, hidePrompt, plainPrompt, promptLot, promptSize, listNames
local function drawTradeBuilder(g, v, S, me)
    local pr = center.prompt
    local tb = g.tb
    local T = ns.T
    plainPrompt()
    pr.title:SetText(T("tycoon.tbTitle") .. " — " .. T("tycoon.tbWho") .. ":")
    pr.text:SetText(T("tycoon.tbHint"))
    local k = 0
    for q = 1, v.n do
        if q ~= me and v.seats[q].alive and k < 3 then
            k = k + 1
            local b = pr.who[k]
            b.seat = q
            setBtn(b, g:SeatName(q), true, nil)
            if tb.to == q then b:Disable() end
        end
    end
    local give, get = {}, {}
    for _, c in ipairs(PROPS) do
        if tb.give[c] then give[#give + 1] = c end
        if tb.get[c] then get[#get + 1] = c end
    end
    pr.give:SetText(T("tycoon.tbMine") .. ": " .. listNames(g, give, tb.ga, tb.ja))
    pr.get:SetText(T("tycoon.tbTheirs") .. ": " .. listNames(g, get, tb.gb, tb.jb))
    pr.goldA:SetRange(0, v.seats[me].cash)
    pr.goldA:Show()
    if tb.to then
        pr.goldB:SetRange(0, v.seats[tb.to].cash)
        pr.goldB:Show()
    end
    local cardName = T(B.Key(g.board, "card"))
    if v.seats[me].free ~= "" then
        setBtn(pr.cardA, cardName .. ": " .. (tb.ja ~= "" and "+" or "-"), true, nil)
    end
    if tb.to and v.seats[tb.to].free ~= "" then
        setBtn(pr.cardB, cardName .. ": " .. (tb.jb ~= "" and "+" or "-"), true, nil)
    end
    local m = g:TradeMove()
    local ok = m ~= nil and R.Legal(S, m)
    setBtn(pr.b[1], T("tycoon.propose"), ok, ok and nil or T("tycoon.tbBad"))
    pr.b[1].act = function(gg) gg:TradeSend() end
    setBtn(pr.b[2], T("tycoon.cancel"), true, nil)
    pr.b[2].act = function(gg) gg:TradeCancel() end
    return promptSize(200)
end
local function drawPrompt(g, v, S, me)
    hidePrompt()
    local pr = center.prompt
    local T = ns.T
    local ph, who = v.phase, v.who
    paint(pr.title, C.title)
    paint(pr.text, C.text)
    paint(pr.give, C.text)
    paint(pr.get, C.text)
    if V.TradeModal then
        if g.tb or (ph == "trade" and v.offer) then
            V.TradeModal(g, v, S, me)
            pr:Hide()
            return 0
        end
        V.TradeHide()
    elseif g.tb then
        return drawTradeBuilder(g, v, S, me)
    end
    if ph == "pre" and who == me and v.seats[me].jail > 0 and not v.rolled then
        plainPrompt()
        pr.title:SetText(T(B.Key(g.board, "jail")))
        pr.text:SetText(T("tycoon.cardJail"))
        setBtn(pr.b[1], T("tycoon.bail"), R.Legal(S, { k = "bail", s = me }), nil)
        pr.b[1].act = function(gg) gg:Act{ k = "bail" } end
        setBtn(pr.b[2], T("tycoon.useCard", T(B.Key(g.board, "card"))), R.Legal(S, { k = "free", s = me }), nil)
        pr.b[2].act = function(gg) gg:Act{ k = "free" } end
        return promptSize(100)
    end
    if ph == "buy" and v.buyAt then
        local c = v.buyAt
        promptLot(g, v, c)
        if who == me then
            local ok = R.Legal(S, { k = "buy", s = me })
            setBtn(pr.b[1], T("tycoon.buy") .. " " .. gold(CELLS[c].price), ok, ok and nil or T("tycoon.whyCash"))
            pr.b[1].act = function(gg) gg:Act{ k = "buy" } end
            if ok then V.SetPrimary(pr.b[1]) end
            setBtn(pr.b[2], T("tycoon.skip"), true, T("tycoon.skipTip"))
            pr.b[2].act = function(gg) gg:Act{ k = "skip" } end
            return promptSize(116)
        end
        return promptSize(78)
    end
    if ph == "auction" and v.auc and V.DrawAuction then
        return V.DrawAuction(g, v, S, me)
    end
    if ph == "auction" and v.auc then
        local a = v.auc
        promptLot(g, v, a.c)
        local line = a.lead > 0 and T("tycoon.aucBid", gold(a.bid), g:SeatTag(a.lead)) or T("tycoon.aucNone")
        pr.text:SetText(T("tycoon.aucLot", "") .. line .. "  |  " .. T("tycoon.aucTurn", g:SeatTag(who)))
        if who == me then
            for k = 1, 3 do pr.plus[k]:Show() end
            pr.num:SetRange(a.bid + 1, v.seats[me].cash)
            if pr.num:Value() <= a.bid then pr.num:SetValue(a.bid + 1) end
            pr.num:Show()
            setBtn(pr.b[1], T("tycoon.bid"), true, T("tycoon.aucMax"))
            pr.b[1].act = function(gg) gg:Act{ k = "bid", v = pr.num:Value() } end
            setBtn(pr.b[2], T("tycoon.pass"), true, T("tycoon.passTip"))
            pr.b[2].act = function(gg) gg:Act{ k = "pass" } end
            return promptSize(146)
        end
        return promptSize(78)
    end
    if ph == "trade" and v.offer then
        local o = v.offer
        plainPrompt()
        pr.title:SetText(T("tycoon.tradeFrom", g:SeatTag(o.from), g:SeatTag(o.to)))
        pr.give:SetText(T("tycoon.gives") .. ": " .. listNames(g, R.MaskList(o.la), o.ga, o.ja))
        pr.get:SetText(T("tycoon.wants") .. ": " .. listNames(g, R.MaskList(o.lb), o.gb, o.jb))
        pr.give:ClearAllPoints()
        pr.give:SetPoint("TOPLEFT", pr, "TOPLEFT", 12, -36)
        pr.get:ClearAllPoints()
        pr.get:SetPoint("TOPLEFT", pr, "TOPLEFT", 14 + (FW - 36) / 2, -36)
        if o.to == me then
            setBtn(pr.b[1], T("tycoon.accept"), R.Legal(S, { k = "yes", s = me }), nil)
            pr.b[1].act = function(gg) gg:Act{ k = "yes" } end
            setBtn(pr.b[2], T("tycoon.decline"), true, nil)
            pr.b[2].act = function(gg) gg:Act{ k = "no" } end
            return promptSize(130)
        elseif o.from == me then
            pr.text:SetText(T("tycoon.tradeWait", g:SeatTag(o.to)))
            pr.text:ClearAllPoints()
            pr.text:SetPoint("TOPLEFT", pr, "TOPLEFT", 12, -88)
            setBtn(pr.b[1], T("tycoon.withdraw"), true, nil)
            pr.b[1].act = function(gg) gg:Act{ k = "no" } end
            return promptSize(130)
        end
        return promptSize(96)
    end
    if ph == "debt" and v.debt then
        local d = v.debt
        plainPrompt()
        pr.title:SetText(T("tycoon.debtTo", d.sum, seatRef(g, d.to)))
        local more = d.count > 1 and ("  |  " .. T("tycoon.debtMore", d.count - 1)) or ""
        pr.text:SetText((who == me and T("tycoon.stDebt", d.sum) or T("tycoon.stDebtOf", g:SeatTag(who), d.sum)) .. more)
        paint(pr.title, C.bad)
        return promptSize(60)
    end
    if ph == "lien" and v.lien then
        local c = v.lien
        promptLot(g, v, c)
        pr.text:SetText(T("tycoon.lienAsk", cellName(g.board, c)) .. ". " .. T(who == me and "tycoon.stLien" or "tycoon.stLienOf", g:SeatTag(who)))
        if who == me then
            setBtn(pr.b[1], T("tycoon.lienBuy", gold(R.LiftCost(c))), R.Legal(S, { k = "lien", s = me, v = 1 }), nil)
            pr.b[1].act = function(gg) gg:Act{ k = "lien", v = 1 } end
            setBtn(pr.b[2], T("tycoon.lienPay", gold(R.Interest(c))), true, T("tycoon.lienPayTip"))
            pr.b[2].act = function(gg) gg:Act{ k = "lien", v = 0 } end
            return promptSize(116)
        end
        return promptSize(78)
    end
    if V.DrawBuild then
        local h = V.DrawBuild(g, v, S, me)
        if h > 0 then return h end
    end
    pr:Hide()
    return 0
end
local function drawCenter(g, v, S, me)
    local T = ns.T
    center.title:SetText(T(B.Key(g.board, "title")))
    paint(center.title, C.title)
    local st, col = V.Status(g, v)
    center.status:SetText(st)
    paint(center.status, col)
    local clock, hot = "", false
    local fin = g.cfg and g.cfg.fin
    if not v.over and v.rem then
        local rem = v.rem
        if g.guest and g.remAt then rem = max(0, rem - ((g.t or 0) - g.remAt)) end
        if rem <= 0 then clock, hot = T("tycoon.endLast"), true
        elseif rem <= 300 then clock, hot = T("tycoon.endInSec", floor(rem / 60), floor(rem % 60)), true
        else clock = T("tycoon.endIn", math.ceil(rem / 60)) end
    elseif not v.over and fin == "cap" then
        local top = 0
        for q = 1, v.n do
            if v.seats[q].alive then top = max(top, R.Capital(S, q)) end
        end
        clock = T("tycoon.endCap", R.CAP_GOAL, top)
    end
    center.clock:SetText(clock)
    paint(center.clock, hot and { 1, 0.55, 0.2 } or C.text)
    if clock == "" then center.clockBg:Hide() else center.clockBg:Show() end
    V.SetPrimary(nil)
    local ph = drawPrompt(g, v, S, me)
    local nLog = #g.log
    local shownLines = min(nLog, LOG_LINES)
    if shownLines == 0 then
        center.log:Hide()
    else
        at(center.log, 0, LOG_Y, center.col)
        center.log:SetHeight(shownLines * 15 + 10)
        center.log:Show()
    end
    if ph > 0 then at(center.prompt, 0, WIN_Y, center.col) end
    local T2 = ns.T
    center.deck.c.cap:SetText(T2(B.Key(g.board, "chance")))
    center.deck.t.cap:SetText(T2(B.Key(g.board, "chest")))
    paint(center.deck.c.cap, { 1, 1, 1 })
    paint(center.deck.t.cap, { 1, 1, 1 })
    for k = 1, LOG_LINES do
        local str = k <= shownLines and g.log[nLog - shownLines + k] or ""
        center.lines[k]:SetText(str)
        paint(center.lines[k], (k == shownLines) and C.text or C.soft)
    end
    local idle = v.phase == "pre" and not v.rolled and not fx.dice and not v.over
    if not fx.dice then
        if v.dice ~= 36 then
            local d1, d2 = floor(v.dice / 6) + 1, v.dice % 6 + 1
            showDie(center.d1, d1)
            showDie(center.d2, d2)
            center.sum:SetText(idle and "" or (d1 .. "+" .. d2))
        else
            showDie(center.d1, 5)
            showDie(center.d2, 2)
            center.sum:SetText("")
        end
    end
    local rest = (idle or v.dice == 36) and not fx.dice
    center.d1:SetAlpha(rest and 0.4 or 1)
    center.d2:SetAlpha(rest and 0.4 or 1)
    paint(center.sum, C.soft)
    local canRoll = R.Legal(S, { k = "roll", s = me })
    local canEnd = R.Legal(S, { k = "end", s = me })
    setBtn(center.roll, T("tycoon.roll"), canRoll, T("tycoon.rollTip"))
    setBtn(center.endTurn, T("tycoon.endTurn"), canEnd, T("tycoon.endTip"))
    if not fx.primary then
        if canRoll then V.SetPrimary(center.roll) elseif canEnd then V.SetPrimary(center.endTurn) end
    end
    fx.rollWait = canRoll and not fx.dice or nil
    local canOffer = not v.over and ((v.phase == "pre" or v.phase == "post") and v.turn == me or (v.phase == "debt" and v.who == me))
        and (v.offers or 0) < 3 and v.seats[me] and v.seats[me].alive
    setBtn(side.trade, T("tycoon.trade"), canOffer and not g.tb, canOffer and T("tycoon.tradeTip") or ((v.offers or 0) >= 3 and T("tycoon.whyOffers") or T("tycoon.whyPhase")))
    local canQuit = v.seats[me] and R.Legal(S, { k = "quit", s = me })
    local quitTip = T("tycoon.quitTip")
    if v.debt and v.who == me and v.debt.to > 0 then quitTip = T("tycoon.quitDebt") end
    if v.auc and not canQuit then quitTip = T("tycoon.whyAuction") end
    if g.quitAsk and ((g.t or 0) - g.quitAsk > 4 or not canQuit) then g.quitAsk = nil end
    setBtn(side.quit, T(g.quitAsk and "tycoon.quitSure" or "tycoon.quit"), canQuit, quitTip)
end
local function layoutCard(tall, buttons, used, priced)
    local body = card.body
    tall = tall and not buttons
    if tall then card.pic:Show() else card.pic:Hide() end
    local y0 = tall and (PIC_H + 2) or 0
    local nh = card.name.GetStringHeight and card.name:GetStringHeight() or 0
    if nh < 14 then nh = 14 end
    if nh > 40 then nh = 40 end
    at(card.name, 54, y0 + 10, body)
    at(card.gname, 54, y0 + 12 + nh, body)
    at(card.iconBg, 8, y0 + 12, body)
    at(card.price, 150, y0 + 10, body)
    local y = max(y0 + 12 + nh + 20, y0 + 58)
    if tall then
        card.what:Hide()
    else
        at(card.what, 8, y, body)
        card.what:Show()
        if (card.what:GetText() or "") ~= "" then y = y + 28 end
    end
    for k = 1, 7 do
        at(card.rows[k].lab, 8, y + (k - 1) * 13, body)
        at(card.rows[k].val, 150, y + (k - 1) * 13, body)
    end
    y = y + used * 13 + 2
    at(card.owner, 8, y, body)
    if priced then y = y + 14 end
    at(card.build, 6, y, body)
    at(card.down, 116, y, body)
    at(card.mortB, 6, y + 21, body)
    at(card.lift, 116, y + 21, body)
    card.f:SetHeight((buttons and (y + 42) or y) + 6)
end
local function drawCard(g, v, S, me)
    local T = ns.T
    local c = g.sel or g.hover or v.seats[v.turn] and v.seats[v.turn].pos or 0
    local cell = CELLS[c]
    local board = g.board
    local gc
    if cell.t == "prop" then gc = B.GROUP_COLOR[cell.g]
    elseif cell.t == "rail" then gc = pal.rail
    elseif cell.t == "util" then gc = pal.util
    else gc = pal.frame end
    ns.Paint(card.group, gc[1], gc[2], gc[3], 1)
    V.CellIcon(card.icon, board, c)
    card.name:SetText(cellName(board, c))
    paint(card.name, C.title)
    card.gname:SetText(cell.g and T(B.GroupKey(board, cell.g)) or "")
    paint(card.gname, C.soft)
    card.what:SetText(cell.price and T(B.CellWhat(board, c)) or "")
    paint(card.what, C.soft)
    for k = 1, 7 do
        card.rows[k].lab:SetText("")
        card.rows[k].val:SetText("")
        card.rows[k].lab:SetWidth(150)
        card.rows[k].lab:SetHeight(0)
        paint(card.rows[k].lab, C.text)
        paint(card.rows[k].val, C.text)
    end
    card.owner:SetText("")
    card.price:SetText("")
    local buttons = false
    if cell.price then
        card.price:SetText(gold(cell.price))
        if cell.t == "prop" then
            local owner = v.own[c]
            local full = owner > 0 and R.GroupFull(S, owner, cell.g)
            card.rows[1].lab:SetText(T(full and "tycoon.cardRentSet" or "tycoon.cardRent"))
            card.rows[1].val:SetText(tostring(full and cell.rent[1] * 2 or cell.rent[1]))
            for k = 1, 4 do
                card.rows[k + 1].lab:SetText(T("tycoon.cardRentN", k, T(B.Key(board, "house"))))
                card.rows[k + 1].val:SetText(tostring(cell.rent[k + 1]))
            end
            card.rows[6].lab:SetText(T(B.Key(board, "hotel")))
            card.rows[6].val:SetText(tostring(cell.rent[6]))
            local cur = v.lv[c]
            for k = 1, 6 do
                local hot = owner > 0 and ((k == 1 and cur == 0) or (k > 1 and cur == k - 1))
                paint(card.rows[k].lab, hot and pal.accent or C.text)
                paint(card.rows[k].val, hot and pal.accent or C.text)
            end
            card.rows[7].lab:SetText(T("tycoon.cardHouse", T(B.Key(board, "house")), cell.house) .. ". " .. T("tycoon.cardMort", cell.mort, R.LiftCost(c)))
            card.rows[7].lab:SetWidth(214)
            paint(card.rows[7].lab, C.soft)
        else
            card.rows[1].lab:SetText(T(cell.t == "rail" and "tycoon.cardRail" or "tycoon.cardUtil"))
            card.rows[1].lab:SetWidth(214)
            card.rows[1].lab:SetHeight(30)
            card.rows[3].lab:SetText(T("tycoon.cardMort", cell.mort, R.LiftCost(c)))
            card.rows[3].lab:SetWidth(214)
            paint(card.rows[3].lab, C.soft)
        end
        local owner = v.own[c]
        if owner > 0 then
            card.owner:SetText(T("tycoon.cardOwner", g:SeatName(owner)) .. (v.mort[c] and (", " .. T("tycoon.cardMortgaged")) or ""))
            paint(card.owner, lighten(B.SEAT_COLOR[owner], 0.4))
        else
            card.owner:SetText(T("tycoon.cardBank"))
            paint(card.owner, C.ok)
        end
        buttons = owner == me and g.sel == c
    else
        local key = cell.t == "tax" and "tycoon.cardTax" or cell.t == "go" and "tycoon.cardGo" or cell.t == "jail" and "tycoon.cardJail"
            or cell.t == "free" and "tycoon.cardFreePark" or cell.t == "gojail" and "tycoon.cardGoJail" or "tycoon.cardDeck"
        local arg = cell.t == "tax" and cell.tax or cell.t == "gojail" and T(B.Key(board, "jail")) or nil
        card.rows[1].lab:SetText(arg and T(key, arg) or T(key))
        card.rows[1].lab:SetWidth(214)
        card.rows[1].lab:SetHeight(60)
        card.rows[1].lab:SetJustifyV("TOP")
    end
    paint(card.price, C.gold)
    local pic = B.place[board] and B.place[board][c]
    local tall = pic and card.pic:SetTexture(pic) and true or false
    if tall then card.pic:SetTexCoord(0, 1, 0.5 - PIC_H / 224, 0.5 + PIC_H / 224) end
    card.tall = tall
    local lvNow = cell.t == "prop" and v.lv[c] or 0
    if lvNow > 0 and not v.mort[c] then
        card.house:SetTexCoord(B.HouseCoord(board, lvNow == 5))
        card.house:Show()
    else
        card.house:Hide()
    end
    layoutCard(tall, buttons, cell.t == "prop" and 7 or 4, cell.price ~= nil)
    if buttons then
        local function arm(b, k, label, canFn)
            local ok = R.Legal(S, { k = k, s = me, c = c })
            local tip
            if not ok then
                local fine, why = canFn(S, me, c)
                tip = fine and T("tycoon.whyPhase") or V.Why(board, why)
            elseif k == "down" then
                tip = T("tycoon.demolishTip")
            end
            setBtn(b, label, ok, tip)
        end
        arm(card.build, "up", T("tycoon.build"), R.CanUp)
        arm(card.down, "down", T("tycoon.demolish"), R.CanDown)
        arm(card.mortB, "mort", T("tycoon.mortgage"), R.CanMort)
        arm(card.lift, "lift", T("tycoon.lift"), R.CanLift)
    else
        card.build:Hide()
        card.down:Hide()
        card.mortB:Hide()
        card.lift:Hide()
    end
end
local function drawHold(g, v, me)
    local T = ns.T
    hold.cap:SetText(T("tycoon.myCap"))
    paint(hold.cap, C.soft)
    for gi = 1, 10 do
        local r = hold.rows[gi]
        local list = GROUPS[gi]
        local gc = gi <= 8 and B.GROUP_COLOR[gi] or gi == 9 and pal.rail or pal.util
        ns.Paint(r.chip, gc[1], gc[2], gc[3], 1)
        r.name:SetText(T(B.GroupKey(g.board, gi)))
        local mine = 0
        for _, c in ipairs(list) do if v.own[c] == me then mine = mine + 1 end end
        r.count:SetText(mine .. "/" .. #list)
        paint(r.name, mine == #list and C.gold or (mine > 0 and C.text or C.soft))
        if mine == #list then r.bg:Show() else r.bg:Hide() end
        paint(r.count, mine == #list and C.ok or C.soft)
        for j = 1, 4 do
            local s = r.sq[j]
            local c = list[j]
            if c then
                s:Show()
                local owner = v.own[c]
                V.CellIcon(s.icon, g.board, c)
                if owner == me then
                    local sc = B.SEAT_COLOR[me]
                    ns.Paint(s.bg, sc[1], sc[2], sc[3], 0.55)
                    tintBars(s.edge, sc)
                    s.icon:SetAlpha(1)
                elseif owner > 0 then
                    local sc = B.SEAT_COLOR[owner]
                    ns.Paint(s.bg, sc[1], sc[2], sc[3], 0.25)
                    tintBars(s.edge, sc, 0.8)
                    s.icon:SetAlpha(0.55)
                else
                    ns.Paint(s.bg, 0, 0, 0, 0.35)
                    tintBars(s.edge, pal.cellline)
                    s.icon:SetAlpha(0.3)
                end
                local mark = ""
                if v.mort[c] then mark = "M"
                elseif v.lv[c] == 5 then mark = "H"
                elseif v.lv[c] > 0 then mark = tostring(v.lv[c]) end
                s.mark:SetText(mark)
                paint(s.mark, v.mort[c] and C.bad or C.gold)
                s.tipTitle = cellName(g.board, c)
                s.tip = owner > 0 and T("tycoon.cardOwner", g:SeatName(owner)) or T("tycoon.cardBank")
            else
                s:Hide()
            end
        end
    end
end
function V.DrawCard(g)
    if not root then return end
    local v = g:View()
    if not v then return end
    local S = V.Shim(v)
    drawCard(g, v, S, g:Me())
    drawCells(g, v, S)
end
function V.Draw(g)
    if not root then return end
    local v = g:View()
    if not v then return end
    V.game = g
    V.SetLook(g.board)
    local S = V.Shim(v)
    local me = g:Me()
    drawCells(g, v, S)
    placeTokens(v)
    drawPlayers(g, v, S)
    drawBank(g, v, S)
    drawCenter(g, v, S, me)
    drawCard(g, v, S, me)
    drawHold(g, v, me)
    if V.DrawResult then V.DrawResult(g, v, S) end
end
