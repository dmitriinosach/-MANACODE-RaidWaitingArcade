local ADDON, ns = ...
ns.FX = {}
local MAX_GHOSTS = 120
local kinds, order, fancy = {}, {}, {}
function ns.RegisterFX(def)
    if type(def) ~= "table" or type(def.key) ~= "string" then return end
    if not kinds[def.key] then
        order[#order + 1] = def.key
        if def.fancy then fancy[#fancy + 1] = def.key end
    end
    kinds[def.key] = def
end
function ns.FX.Get(key)
    return kinds[key]
end
function ns.FX.Keys()
    local out = {}
    for i, k in ipairs(order) do out[i] = k end
    return out
end
local LEVELS = { "full", "plain", "off" }
local LEVEL_KEY = { full = "fxFull", plain = "fxPlain", off = "fxOff" }
function ns.FX.Level()
    local db = ns.Store.DB()
    return db.fx or "full"
end
function ns.FX.LevelName()
    return ns.T(LEVEL_KEY[ns.FX.Level()] or "fxFull")
end
function ns.FX.SetLevel(key)
    if not LEVEL_KEY[key] then return end
    ns.Store.DB().fx = key
end
function ns.FX.LevelOptions()
    local out = {}
    for i, key in ipairs(LEVELS) do
        out[i] = { key = key, label = ns.T(LEVEL_KEY[key]) }
    end
    return out
end
local pool
local function newGhost()
    local f = ns.NewFrame("Frame", nil, UIParent)
    f.tex = f:CreateTexture(nil, "OVERLAY")
    f.tex:SetAllPoints(f)
    f.anim = f:CreateAnimationGroup()
    f.move = f.anim:CreateAnimation("Translation")
    f.grow = f.anim:CreateAnimation("Scale")
    f.fade = f.anim:CreateAnimation("Alpha")
    f.anim:SetScript("OnFinished", function() f:Hide() end)
    return f
end
function ns.FX.Ghost(parent, x, y, size, tex, crop)
    pool = pool or ns.NewPool(newGhost)
    local f = pool:Acquire()
    f:SetParent(parent)
    f:SetFrameLevel(parent:GetFrameLevel() + 5)
    f:SetWidth(size); f:SetHeight(size)
    f:ClearAllPoints()
    f:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
    f:SetAlpha(1)
    f:SetScale(1)
    f.tex:SetTexture(tex)
    f.tex:SetVertexColor(1, 1, 1)
    f.tex:SetBlendMode("BLEND")
    crop = crop or ns.CELL_CROP
    f.tex:SetTexCoord(crop[1], crop[2], crop[3], crop[4])
    f.tex:SetAlpha(1)
    f.move:SetStartDelay(0); f.grow:SetStartDelay(0); f.fade:SetStartDelay(0)
    f.move:SetSmoothing("NONE"); f.grow:SetSmoothing("NONE"); f.fade:SetSmoothing("NONE")
    f.anim:Stop()
    return f
end
function ns.FX.Stop()
    if not pool then return end
    for i = 1, pool:Size() do
        local f = pool.items[i]
        f.anim:Stop()
        f:Hide()
    end
    pool:Reset()
end
local FANCY_EVERY = 3
local tick, turn = 0, 0
function ns.FX.Pick(big, n, force, set)
    local level = ns.FX.Level()
    if level == "off" then return nil end
    local want
    if force and kinds[force] then
        want = force
    else
        tick = tick + 1
        want = "burst"
        local ring = fancy
        if type(set) == "table" then
            local own = {}
            for i = 1, #set do
                if kinds[set[i]] then own[#own + 1] = set[i] end
            end
            if #own > 0 then ring = own end
        end
        if level ~= "plain" and #ring > 0 and (big or tick % FANCY_EVERY == 0) then
            turn = turn % #ring + 1
            want = ring[turn]
        end
    end
    while want do
        local def = kinds[want]
        if not def then return nil end
        if n * (def.cost or 1) <= MAX_GHOSTS then return def end
        want = def.cheaper
    end
    return nil
end
local rng
function ns.FX.Play(parent, cells, opts)
    if not parent or type(cells) ~= "table" or #cells == 0 then return end
    local def = ns.FX.Pick(opts and opts.big, #cells, opts and opts.force, opts and opts.set)
    if not def then return end
    rng = rng or ns.RNG.New(time())
    def.play(parent, cells, rng, opts)
end
