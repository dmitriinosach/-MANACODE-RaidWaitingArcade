local ADDON, ns = ...
ns.Anim = {}
local FADE_TIME, SLIDE_TIME = 0.25, 0.30
local DEAL_TIME, DEAL_STEP = 0.22, 0.04
local ROLL_SWEEP, ROLL_CELL, ROLL_DROP = 0.35, 0.18, 12
local live = setmetatable({}, { __mode = "k" })
local function isFrame(f)
    return type(f) == "table"
        and type(f.CreateAnimationGroup) == "function"
        and type(f.GetCenter) == "function"
end
local function seconds(v, d)
    if type(v) == "number" and v > 0 then return v end
    return d
end
local function pause(v, d)
    if type(v) == "number" and v >= 0 then return v end
    return d
end
local function shift(v, d)
    if type(v) == "number" then return v end
    return d or 0
end
local function unit(v, d)
    if type(v) ~= "number" then return d end
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end
local function callback(fn)
    if type(fn) == "function" then return fn end
    return nil
end
local function fire(fn)
    if not fn then return end
    local ok, err = pcall(fn)
    if not ok then geterrorhandler()(err) end
end
local function collect(list)
    local out = {}
    if isFrame(list) then
        out[1] = list
    elseif type(list) == "table" then
        for i = 1, #list do
            if isFrame(list[i]) then out[#out + 1] = list[i] end
        end
    end
    return out
end
local function settle(a, natural)
    if not a.playing then return end
    a.playing = false
    live[a.frame] = nil
    local finish, onDone = a.finish, a.onDone
    a.kind, a.finish, a.onDone = nil, nil, nil
    if not natural then a.group:Stop() end
    if finish then finish(a.frame) end
    if natural then fire(onDone) end
end
local function slot(frame)
    local a = frame.arcAnim
    if a then return a end
    local group = frame:CreateAnimationGroup()
    a = {
        frame = frame,
        group = group,
        move = group:CreateAnimation("Translation"),
        fade = group:CreateAnimation("Alpha"),
        playing = false,
        offset = type(group.SetInitialOffset) == "function",
    }
    a.move:SetOrder(1)
    a.fade:SetOrder(1)
    group:SetScript("OnFinished", function() settle(a, true) end)
    frame.arcAnim = a
    return a
end
local function launch(frame, kind, p)
    local a = slot(frame)
    settle(a, false)
    local ox, oy = p.ox or 0, p.oy or 0
    local dx, dy = p.dx or 0, p.dy or 0
    if a.offset then
        a.group:SetInitialOffset(ox, oy)
    elseif ox ~= 0 or oy ~= 0 then
        dx, dy = 0, 0
    end
    local delay, ease = p.delay or 0, p.ease or "NONE"
    a.move:SetOffset(dx, dy)
    a.move:SetDuration(p.dur)
    a.move:SetStartDelay(delay)
    a.move:SetSmoothing(ease)
    ns.AlphaChange(a.fade, p.change or 0, p.alpha or frame:GetAlpha())
    a.fade:SetDuration(p.dur)
    a.fade:SetStartDelay(delay)
    a.fade:SetSmoothing(ease)
    a.kind, a.finish, a.onDone = kind, p.finish, callback(p.onDone)
    a.playing = true
    live[frame] = true
    if p.alpha then frame:SetAlpha(p.alpha) end
    if p.show then frame:Show() end
    a.group:Play()
end
function ns.Anim.Fade(frame, from, to, dur, onDone)
    if not isFrame(frame) then return false end
    local keep = frame:GetAlpha()
    from = unit(from, keep)
    to = unit(to, 1)
    if to == 0 and not frame:IsShown() then
        fire(callback(onDone))
        return true
    end
    local finish
    if to > 0 then
        finish = function(f) f:SetAlpha(to) end
    else
        finish = function(f) f:Hide(); f:SetAlpha(keep) end
    end
    launch(frame, "fade", {
        dur = seconds(dur, FADE_TIME),
        alpha = from, change = to - from,
        show = true, finish = finish, onDone = onDone,
    })
    return true
end
function ns.Anim.Slide(frame, dx, dy, dur, onDone)
    if not isFrame(frame) then return false end
    dx, dy = shift(dx), shift(dy)
    launch(frame, "slide", {
        dur = seconds(dur, SLIDE_TIME),
        ox = dx, oy = dy, dx = -dx, dy = -dy,
        ease = "OUT", show = true, onDone = onDone,
    })
    return true
end
function ns.Anim.Leave(frame, dx, dy, dur, onDone)
    if not isFrame(frame) then return false end
    if not frame:IsShown() then return false end
    local a = frame.arcAnim
    if a and a.playing and a.kind == "leave" then return true end
    local keep = frame:GetAlpha()
    launch(frame, "leave", {
        dur = seconds(dur, SLIDE_TIME),
        dx = shift(dx), dy = shift(dy),
        change = -keep, ease = "IN",
        finish = function(f) f:Hide(); f:SetAlpha(keep) end,
        onDone = onDone,
    })
    return true
end
function ns.Anim.Deal(list, opts)
    if type(opts) ~= "table" then opts = {} end
    local frames = collect(list)
    local onDone = callback(opts.onDone)
    local sx, sy
    if isFrame(opts.from) then sx, sy = opts.from:GetCenter() end
    if type(opts.x) == "number" and type(opts.y) == "number" then sx, sy = opts.x, opts.y end
    local last
    if sx and sy then
        for i = #frames, 1, -1 do
            local cx, cy = frames[i]:GetCenter()
            if cx and cy then last = i; break end
        end
    end
    if not last then
        fire(onDone)
        return false
    end
    local dur = seconds(opts.dur, DEAL_TIME)
    local step = pause(opts.step, DEAL_STEP)
    local wait = pause(opts.delay, 0)
    local n = 0
    for i = 1, last do
        local f = frames[i]
        local cx, cy = f:GetCenter()
        if cx and cy then
            launch(f, "deal", {
                dur = dur, delay = wait + n * step,
                ox = sx - cx, oy = sy - cy, dx = cx - sx, dy = cy - sy,
                ease = "OUT", show = true,
                onDone = (i == last) and onDone or nil,
            })
            n = n + 1
        end
    end
    return true
end
local SIDE = {
    left   = { axis = 1, sign =  1, dx = -1, dy =  0 },
    right  = { axis = 1, sign = -1, dx =  1, dy =  0 },
    top    = { axis = 2, sign = -1, dx =  0, dy =  1 },
    bottom = { axis = 2, sign =  1, dx =  0, dy = -1 },
}
function ns.Anim.Roll(list, opts)
    if type(opts) ~= "table" then opts = {} end
    local frames = collect(list)
    local onDone = callback(opts.onDone)
    local side = SIDE[opts.from] or SIDE.left
    local dur = seconds(opts.dur, ROLL_CELL)
    local sweep = pause(opts.span, ROLL_SWEEP)
    local drop = shift(opts.drop, ROLL_DROP)
    local wait = pause(opts.delay, 0)
    local pos, lo, hi = {}, nil, nil
    for i = 1, #frames do
        local cx, cy = frames[i]:GetCenter()
        if cx and cy then
            local v = (side.axis == 1) and cx or cy
            pos[i] = v
            if not lo or v < lo then lo = v end
            if not hi or v > hi then hi = v end
        end
    end
    if not lo then
        fire(onDone)
        return false
    end
    local width = hi - lo
    local lastI, lastD = nil, -1
    for i = 1, #frames do
        local v = pos[i]
        if v then
            local k = 0
            if width > 0 then
                k = (side.sign > 0) and (v - lo) / width or (hi - v) / width
            end
            local d = wait + sweep * k
            if d > lastD then lastI, lastD = i, d end
        end
    end
    for i = 1, #frames do
        local v = pos[i]
        if v then
            local f = frames[i]
            local keep = f:GetAlpha()
            local k = 0
            if width > 0 then
                k = (side.sign > 0) and (v - lo) / width or (hi - v) / width
            end
            launch(f, "roll", {
                dur = dur, delay = wait + sweep * k,
                alpha = 0, change = keep,
                ox = side.dx * drop, oy = side.dy * drop,
                dx = -side.dx * drop, dy = -side.dy * drop,
                ease = "OUT", show = true,
                finish = function(g) g:SetAlpha(keep) end,
                onDone = (i == lastI) and onDone or nil,
            })
        end
    end
    return true
end
function ns.Anim.Stop(frame)
    if not isFrame(frame) then return end
    local a = frame.arcAnim
    if a then settle(a, false) end
end
function ns.Anim.StopAll()
    local frames = {}
    for frame in pairs(live) do frames[#frames + 1] = frame end
    for i = 1, #frames do
        local a = frames[i].arcAnim
        if a then settle(a, false) end
    end
end
function ns.Anim.Busy(frame)
    if not isFrame(frame) then return false end
    local a = frame.arcAnim
    return a ~= nil and a.playing == true
end
