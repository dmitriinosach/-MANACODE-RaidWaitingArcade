local ADDON, ns = ...
local floor = math.floor
local random = math.random
ns.ChessPieces = {}
local CP = ns.ChessPieces
CP.DISC_TEX = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
CP.MAX_PARTS = 16
CP.SIDE = {
    { disc = { 0.95, 0.93, 0.87 }, ring = { 0.14, 0.11, 0.08 }, text = { 0.10, 0.09, 0.08 } },
    { disc = { 0.15, 0.14, 0.16 }, ring = { 0.93, 0.87, 0.72 }, text = { 0.95, 0.94, 0.92 } },
}
CP.PARTS = {
    [1] = {
        { "r", 10.9, 0.5, 13.1, 7.2 },
        { "r", 8.6, 2.4, 15.4, 4.6 },
        { "r", 5.0, 7.2, 19.0, 9.6 },
        { "r", 6.6, 9.6, 17.4, 11.0 },
        { "r", 9.2, 11.0, 14.8, 12.4 },
        { "r", 7.8, 12.4, 16.2, 15.4 },
        { "r", 7.2, 15.4, 16.8, 18.2 },
        { "r", 6.6, 18.2, 17.4, 19.4 },
        { "r", 5.4, 19.4, 18.6, 20.8 },
        { "r", 4.4, 20.8, 19.6, 23.0 },
    },
    [2] = {
        { "c", 12.0, 3.4, 1.9 },
        { "r", 11.2, 4.8, 12.8, 6.8 },
        { "c", 7.4, 5.9, 1.3 },
        { "c", 16.6, 5.9, 1.3 },
        { "r", 5.8, 6.2, 18.2, 7.8 },
        { "r", 6.8, 7.8, 17.2, 8.8 },
        { "r", 5.4, 8.8, 18.6, 10.6 },
        { "r", 9.2, 10.6, 14.8, 12.0 },
        { "r", 7.8, 12.0, 16.2, 15.4 },
        { "r", 7.2, 15.4, 16.8, 18.2 },
        { "r", 6.6, 18.2, 17.4, 19.4 },
        { "r", 5.4, 19.4, 18.6, 20.8 },
        { "r", 4.4, 20.8, 19.6, 23.0 },
    },
    [3] = {
        { "r", 4.4, 4.5, 7.6, 8.4 },
        { "r", 10.4, 4.5, 13.6, 8.4 },
        { "r", 16.4, 4.5, 19.6, 8.4 },
        { "r", 4.4, 8.4, 19.6, 10.4 },
        { "r", 6.6, 10.4, 17.4, 11.8 },
        { "r", 7.8, 11.8, 16.2, 17.6 },
        { "r", 6.6, 17.6, 17.4, 18.8 },
        { "r", 5.4, 18.8, 18.6, 20.8 },
        { "r", 4.4, 20.8, 19.6, 23.0 },
    },
    [4] = {
        { "c", 12.0, 3.7, 1.2 },
        { "r", 11.3, 4.6, 12.7, 5.8 },
        { "c", 12.0, 8.6, 3.8 },
        { "r", 8.2, 8.6, 15.8, 12.4 },
        { "h", 12.2, 5.4, 13.7, 7.6 },
        { "h", 13.3, 7.6, 14.8, 9.8 },
        { "h", 14.4, 9.8, 15.8, 12.0 },
        { "r", 7.2, 12.4, 16.8, 13.8 },
        { "r", 9.6, 13.8, 14.4, 15.2 },
        { "r", 8.2, 15.2, 15.8, 18.4 },
        { "r", 7.0, 18.4, 17.0, 19.6 },
        { "r", 5.6, 19.6, 18.4, 20.8 },
        { "r", 4.4, 20.8, 19.6, 23.0 },
    },
    [5] = {
        { "r", 14.4, 3.5, 15.8, 4.6 },
        { "r", 13.2, 4.4, 16.0, 5.8 },
        { "r", 10.4, 5.6, 16.2, 7.0 },
        { "r", 8.8, 7.0, 16.8, 8.4 },
        { "r", 7.4, 8.4, 17.4, 9.8 },
        { "r", 6.2, 9.8, 17.8, 11.2 },
        { "r", 5.6, 11.2, 18.0, 12.6 },
        { "r", 5.8, 12.6, 9.0, 13.8 },
        { "r", 11.2, 12.6, 17.8, 13.8 },
        { "r", 10.6, 13.8, 17.4, 15.4 },
        { "h", 11.0, 7.4, 12.2, 8.6 },
        { "r", 7.2, 15.4, 16.8, 18.2 },
        { "r", 6.6, 18.2, 17.4, 19.4 },
        { "r", 5.4, 19.4, 18.6, 20.8 },
        { "r", 4.4, 20.8, 19.6, 23.0 },
    },
    [6] = {
        { "c", 12.0, 9.3, 2.8 },
        { "r", 10.8, 11.6, 13.2, 13.2 },
        { "r", 8.8, 13.2, 15.2, 14.6 },
        { "r", 10.2, 14.6, 13.8, 17.0 },
        { "r", 9.4, 17.0, 14.6, 18.6 },
        { "r", 7.4, 18.6, 16.6, 20.6 },
        { "r", 6.0, 20.6, 18.0, 23.0 },
    },
}
local KNIGHT = 5
local GRID = 24
local function pass(tex, kind, side, anchor, sil, col, grow, hole)
    local list = CP.PARTS[kind]
    local u = sil / GRID
    local half = sil / 2
    local mirror = (side == 2 and kind == KNIGHT)
    local n = 0
    if list then
        for k = 1, #list do
            local p = list[k]
            if p[1] ~= "h" or hole then
                n = n + 1
                local t = tex[n]
                t:ClearAllPoints()
                if p[1] == "c" then
                    local gx = mirror and (GRID - p[2]) or p[2]
                    local d = p[4] * 2 * u + grow * 2
                    t:SetTexture(CP.DISC_TEX)
                    t:SetVertexColor(col[1], col[2], col[3])
                    t:SetWidth(d)
                    t:SetHeight(d)
                    t:SetPoint("CENTER", anchor, "CENTER", -half + gx * u, half - p[3] * u)
                else
                    local x0, x1 = p[2], p[4]
                    if mirror then x0, x1 = GRID - p[4], GRID - p[2] end
                    local c = (p[1] == "h") and hole or col
                    t:SetTexture(c[1], c[2], c[3])
                    t:SetVertexColor(1, 1, 1)
                    t:SetWidth((x1 - x0) * u + grow * 2)
                    t:SetHeight((p[5] - p[3]) * u + grow * 2)
                    t:SetPoint("TOPLEFT", anchor, "CENTER",
                        -half + x0 * u - grow, half - p[3] * u + grow)
                end
                t:Show()
            end
        end
    end
    for k = n + 1, CP.MAX_PARTS do tex[k]:Hide() end
end
function CP.Make(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetFrameLevel(parent:GetFrameLevel() + 1)
    f.out, f.part = {}, {}
    for k = 1, CP.MAX_PARTS do
        f.out[k] = f:CreateTexture(nil, "BACKGROUND")
        f.out[k]:Hide()
        f.part[k] = f:CreateTexture(nil, "ARTWORK")
        f.part[k]:Hide()
    end
    return f
end
local function rim(sil)
    local w = floor(sil / 24 + 0.5)
    if w < 1 then w = 1 end
    return w
end
function CP.Dress(f, side, kind, size)
    local col = CP.SIDE[side]
    f:SetWidth(size)
    f:SetHeight(size)
    if not kind then
        for k = 1, CP.MAX_PARTS do
            f.out[k]:Hide()
            f.part[k]:Hide()
        end
        return
    end
    pass(f.out, kind, side, f, size, col.ring, rim(size), nil)
    pass(f.part, kind, side, f, size, col.disc, 0, col.ring)
end
function CP.Blank(f, side, size)
    local col = CP.SIDE[side]
    f:SetWidth(size)
    f:SetHeight(size)
    local ring, disc = f.out[1], f.part[1]
    ring:ClearAllPoints()
    ring:SetTexture(CP.DISC_TEX)
    ring:SetVertexColor(col.ring[1], col.ring[2], col.ring[3])
    ring:SetWidth(size)
    ring:SetHeight(size)
    ring:SetPoint("CENTER", f, "CENTER", 0, 0)
    ring:Show()
    disc:ClearAllPoints()
    disc:SetTexture(CP.DISC_TEX)
    disc:SetVertexColor(col.disc[1], col.disc[2], col.disc[3])
    disc:SetWidth(size - 4)
    disc:SetHeight(size - 4)
    disc:SetPoint("CENTER", f, "CENTER", 0, 0)
    disc:Show()
    for k = 2, CP.MAX_PARTS do
        f.out[k]:Hide()
        f.part[k]:Hide()
    end
end
function CP.Paint(host, base, side, kind, anchor, size)
    local col = CP.SIDE[side]
    local out, fill = {}, {}
    for k = 1, CP.MAX_PARTS do
        out[k] = ns.ArtFill(host, base + k - 1, "BORDER")
        fill[k] = ns.ArtFill(host, base + CP.MAX_PARTS + k - 1, "ARTWORK")
    end
    pass(out, kind, side, anchor, size, col.ring, rim(size), nil)
    pass(fill, kind, side, anchor, size, col.disc, 0, col.ring)
    return base + CP.MAX_PARTS * 2
end
CP.GRAIN = 11
local DUST_LIFE = 0.75
local DUST_FADE = 0.45
local DUST_FALL = 12
local DUST_ROW = 0.022
local DUST_HEAP = 0.12
local DUST_SINK = 0.06
local DUST_DRAG = 5
local DUST_KICK = 2.2
local DUST_STEP = 0.05
local function solid(kind, x, y)
    local list = CP.PARTS[kind]
    if not list then return false end
    for k = 1, #list do
        local p = list[k]
        if p[1] == "c" then
            local dx, dy = x - p[2], y - p[3]
            if dx * dx + dy * dy <= p[4] * p[4] then return true end
        elseif p[1] == "r" then
            if x >= p[2] and x <= p[4] and y >= p[3] and y <= p[5] then return true end
        end
    end
    return false
end
local function fall(f, e)
    f.t = f.t + e
    local d = e
    if d > DUST_STEP then d = DUST_STEP end
    local a = 1
    if f.t > DUST_FADE then
        a = 1 - (f.t - DUST_FADE) / (DUST_LIFE - DUST_FADE)
        if a < 0 then a = 0 end
    end
    for k = 1, f.n do
        local g = f.g[k]
        if f.t > g.delay then
            if g.rest then
                g.x = g.x + g.vx * d
                g.vx = g.vx - g.vx * DUST_DRAG * d
            else
                g.vy = g.vy - f.pull * d
                g.y = g.y + g.vy * d
                g.x = g.x + g.vx * d
                if g.y <= g.floor then
                    g.y, g.rest = g.floor, true
                    g.vx = g.vx * DUST_KICK
                end
            end
        end
        local t = f.grain[k]
        t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", g.x, g.y)
        t:SetAlpha(a * g.a)
    end
    if f.t >= DUST_LIFE then CP.DustStop(f) end
end
function CP.MakeDust(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetFrameLevel(parent:GetFrameLevel() + 1)
    f.grain, f.g, f.n, f.t = {}, {}, 0, 0
    for k = 1, CP.GRAIN * CP.GRAIN do
        f.grain[k] = f:CreateTexture(nil, "OVERLAY")
        f.grain[k]:Hide()
        f.g[k] = {}
    end
    f:Hide()
    return f
end
function CP.DustStop(f)
    if not f then return end
    f:SetScript("OnUpdate", nil)
    for k = 1, CP.GRAIN * CP.GRAIN do f.grain[k]:Hide() end
    f.n, f.t = 0, 0
    f:Hide()
end
function CP.Crumble(f, kind, side, size)
    if not f or not CP.PARTS[kind] then return end
    local paint = CP.SIDE[side] or CP.SIDE[1]
    local step = GRID / CP.GRAIN
    local cell = size / CP.GRAIN
    local mirror = (side == 2 and kind == KNIGHT)
    local n = 0
    for row = 1, CP.GRAIN do
        for cx = 1, CP.GRAIN do
            local gx = (cx - 0.5) * step
            local gy = (row - 0.5) * step
            if mirror then gx = GRID - gx end
            if solid(kind, gx, gy) then
                n = n + 1
                local g = f.g[n]
                g.x = (cx - 1) * cell
                g.y = size - row * cell
                g.floor = size * (random() * DUST_HEAP - DUST_SINK)
                g.vx = (random() - 0.5) * size * 0.7
                g.vy = 0
                g.rest = false
                g.a = 0.75 + random() * 0.25
                g.delay = (row - 1) * DUST_ROW + random() * DUST_ROW
                local edge = not (solid(kind, gx - step, gy)
                    and solid(kind, gx + step, gy)
                    and solid(kind, gx, gy - step)
                    and solid(kind, gx, gy + step))
                local c = edge and paint.ring or paint.disc
                local t = f.grain[n]
                t:ClearAllPoints()
                t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", g.x, g.y)
                t:SetTexture(c[1], c[2], c[3])
                t:SetWidth(cell)
                t:SetHeight(cell)
                t:SetAlpha(g.a)
                t:Show()
            end
        end
    end
    for k = n + 1, CP.GRAIN * CP.GRAIN do f.grain[k]:Hide() end
    f.n, f.t = n, 0
    f.pull = size * DUST_FALL
    f:SetWidth(size)
    f:SetHeight(size)
    f:SetScript("OnUpdate", fall)
    f:Show()
end
