local ADDON, ns = ...
ns.Keys = {}
local SHARED = {
    { action = "left",  label = "actLeft",  mouse = "MOVE" },
    { action = "right", label = "actRight", mouse = "MOVE" },
    { action = "up",    label = "actUp",    mouse = "MOVE" },
    { action = "down",  label = "actDown",  mouse = "MOVE" },
    { action = "fire",  label = "actFire",  mouse = "LMB"  },
    { action = "alt",   label = "actAlt",   mouse = "RMB"  },
}
local MOVES = { left = true, right = true, up = true, down = true }
local DEFAULT = {
    LEFT  = "left",
    RIGHT = "right",
    UP    = "up",
    DOWN  = "down",
    SPACE = "fire",
}
local FORBID = {
    ENTER = true, NUMPADENTER = true, ESCAPE = true,
}
local MOUSE = {
    LMB = "mouseLMB", RMB = "mouseRMB", MMB = "mouseMMB",
    ["SHIFT-LMB"] = "mouseShiftLMB", ["SHIFT-RMB"] = "mouseShiftRMB",
    ["CTRL-LMB"] = "mouseCtrlLMB", ["CTRL-RMB"] = "mouseCtrlRMB",
    DRAG = "mouseDrag", WHEEL = "mouseWheel", MOVE = "mouseMove",
    DOUBLE = "mouseDouble",
}
local MOUSE_MOVE = {
    left = "mouseMoveLeft", right = "mouseMoveRight",
    up = "mouseMoveUp", down = "mouseMoveDown",
}
local buttons = {}
local held = {}
local bound = false
local pauseOn = false
local wantClear = false
local lastDef
local function button(action)
    if buttons[action] then return buttons[action] end
    local name = "RaidWaitingArcadeKey_" .. action
    local b = ns.NewFrame("Button", name, UIParent)
    b:RegisterForClicks("AnyDown", "AnyUp")
    b:SetScript("OnClick", function(self, _, down)
        ns.Keys.Fire(action, down and true or false)
    end)
    b:Hide()
    buttons[action] = b
    return b
end
for _, a in ipairs(SHARED) do button(a.action) end
function ns.Keys.Fire(action, down)
    local game = ns.Loop.Current()
    if not game or not game.Key then return end
    if not ns.window:IsShown() then return end
    if ns.Loop.IsPaused() then return end
    if down then held[action] = true else held[action] = nil end
    game:Key(action, down)
end
local function releaseHeld()
    local game = ns.Loop.Current()
    for action in pairs(held) do
        if game and game.Key then game:Key(action, false) end
        held[action] = nil
    end
end
local function base()
    return ns.Store and ns.Store.DB and ns.Store.DB()
end
local function clamp(t)
    if not t then return {} end
    for action, key in pairs(t) do
        if type(action) ~= "string" or type(key) ~= "string"
            or key == "" or FORBID[key] then
            t[action] = nil
        end
    end
    return t
end
function ns.Keys.Custom()
    local db = base()
    if not db then return {} end
    db.keys = db.keys or {}
    return clamp(db.keys)
end
function ns.Keys.Own(id)
    local db = base()
    if not db or type(id) ~= "string" then return {} end
    db.gameKeys = db.gameKeys or {}
    db.gameKeys[id] = db.gameKeys[id] or {}
    return clamp(db.gameKeys[id])
end
function ns.Keys.HasOwn(id)
    return next(ns.Keys.Own(id)) ~= nil
end
function ns.Keys.MouseOn(id)
    if not id then
        local game = ns.Loop.Current()
        id = game and game.def and game.def.id
    end
    local db = base()
    if not db or not id then return true end
    return not (db.mouseOff and db.mouseOff[id])
end
function ns.Keys.SetMouseOn(id, on)
    local db = base()
    if not db or type(id) ~= "string" then return end
    db.mouseOff = db.mouseOff or {}
    db.mouseOff[id] = (not on) or nil
end
local function apply(out, has, layer)
    for action, key in pairs(layer) do
        if has[action] then
            for k, a in pairs(out) do
                if a == action then out[k] = nil end
            end
            out[key] = action
        end
    end
end
local function merge(def)
    local out, has = {}, {}
    for key, action in pairs(def and def.keymap or DEFAULT) do
        if not FORBID[key] then out[key] = action; has[action] = true end
    end
    apply(out, has, ns.Keys.Custom())
    if def then apply(out, has, ns.Keys.Own(def.id)) end
    return out
end
local function controlRow(def, action)
    local list = def and def.controls
    if type(list) ~= "table" then return nil end
    for _, row in ipairs(list) do
        if type(row) == "table" and row.action == action then return row end
    end
    return nil
end
function ns.Keys.Label(action, def)
    local row = controlRow(def, action)
    if row and type(row.label) == "string" and row.label ~= "" then
        return ns.T(row.label)
    end
    for _, s in ipairs(SHARED) do
        if s.action == action then return ns.T(s.label) end
    end
    return action
end
function ns.Keys.KeyText(key)
    if not key then return NOT_BOUND or ns.T("keyNone") end
    local s = GetBindingText(key, "KEY_")
    if not s or s == "" then return key end
    return s
end
function ns.Keys.MouseText(token, action, where)
    if type(token) ~= "string" or token == "" then return nil end
    local key
    if token == "MOVE" and action and MOUSE_MOVE[action] then
        key = MOUSE_MOVE[action]
    else
        key = MOUSE[token]
    end
    local s = key and ns.T(key) or token
    if type(where) == "string" and where ~= "" then
        s = s .. " " .. ns.T(where)
    end
    return s
end
local function byAction(map)
    local out = {}
    for key, action in pairs(map) do
        if out[action] == nil or key < out[action] then out[action] = key end
    end
    return out
end
function ns.Keys.Scheme(def, keyed)
    local custom = ns.Keys.Custom()
    local own = def and ns.Keys.Own(def.id) or {}
    local raw
    if not def then raw = DEFAULT
    elseif def.keymap then raw = def.keymap
    elseif keyed then raw = DEFAULT
    else raw = {} end
    local now = byAction(merge(def and { id = def.id, keymap = raw } or nil))
    local was = byAction(raw)
    local mute = def ~= nil and not keyed and not def.keymap
    local function make(action, label, mouse, where, fixed)
        local key = now[action]
        if key == nil and def == nil then key = custom[action] end
        if mute then fixed = "keyMute" end
        local from
        if fixed then from = nil
        elseif key ~= nil and key == own[action] then from = "own"
        elseif key ~= nil and key == custom[action] then from = "prefs"
        elseif key ~= nil then from = "game" end
        return {
            action = action,
            label  = label,
            key    = key,
            text   = fixed and ns.T(fixed) or ns.Keys.KeyText(key),
            base   = was[action],
            origin = from,
            mouse  = ns.Keys.MouseText(mouse, def and action or nil, where),
            fixed  = fixed and true or false,
            bindable = not fixed,
        }
    end
    local out, seen = {}, {}
    for _, s in ipairs(SHARED) do
        local a = s.action
        if MOVES[a] and (def == nil or was[a] ~= nil) then
            local row = controlRow(def, a)
            local mouse = s.mouse
            if row and row.mouse ~= nil then mouse = row.mouse or nil end
            out[#out + 1] = make(a, ns.Keys.Label(a, def), mouse, row and row.where, row and row.keys)
            seen[a] = true
        end
    end
    if def and type(def.controls) == "table" then
        for _, row in ipairs(def.controls) do
            local a = type(row) == "table" and row.action
            if type(a) == "string" and not seen[a] then
                out[#out + 1] = make(a, ns.Keys.Label(a, def), row.mouse or nil, row.where, row.keys)
                seen[a] = true
            end
        end
    end
    for _, s in ipairs(SHARED) do
        local a = s.action
        if not seen[a] and (def == nil or was[a] ~= nil) then
            out[#out + 1] = make(a, ns.Keys.Label(a, def), s.mouse, nil, nil)
            seen[a] = true
        end
    end
    return out
end
function ns.Keys.HasScheme(def, keyed)
    if not def then return true end
    if keyed or def.keymap then return true end
    return type(def.controls) == "table" and #def.controls > 0
end
function ns.Keys.Normalize(key)
    if type(key) ~= "string" or key == "" or key == "UNKNOWN" then return nil end
    local side = key:sub(2)
    if side == "SHIFT" or side == "CTRL" or side == "ALT" then return nil end
    if FORBID[key] then return nil end
    if IsShiftKeyDown() then key = "SHIFT-" .. key end
    if IsControlKeyDown() then key = "CTRL-" .. key end
    if IsAltKeyDown() then key = "ALT-" .. key end
    return key
end
local function layer(id)
    if id then return ns.Keys.Own(id) end
    local db = base()
    if not db then return nil end
    db.keys = db.keys or {}
    return db.keys
end
function ns.Keys.SetKey(action, key, id)
    local t = layer(id)
    if not t or type(action) ~= "string" then return end
    if key == nil then
        t[action] = nil
    else
        if FORBID[key] then return end
        for a, k in pairs(t) do
            if k == key and a ~= action then t[a] = nil end
        end
        t[action] = key
    end
    ns.Keys.Rebind()
end
function ns.Keys.Reset(id)
    local t = layer(id)
    if not t then return end
    for a in pairs(t) do t[a] = nil end
    ns.Keys.Rebind()
end
function ns.Keys.Bind(def)
    if bound or pauseOn then ns.Keys.Clear() end
    lastDef = def
    local owner = ns.window:Frame()
    for key, action in pairs(merge(def)) do
        local b = button(action)
        if b then
            SetOverrideBindingClick(owner, false, key, b:GetName())
        end
    end
    bound = true
    wantClear = false
end
function ns.Keys.Rebind()
    if not bound then return end
    ns.Keys.Bind(lastDef)
end
function ns.Keys.Clear()
    if not bound and not pauseOn then return end
    releaseHeld()
    local owner = ns.window:Frame()
    if InCombatLockdown() then
        wantClear = true
        return
    end
    ClearOverrideBindings(owner)
    bound = false
    pauseOn = false
    wantClear = false
end
function ns.Keys.Retry()
    if wantClear then ns.Keys.Clear() end
end
local PAUSE_HOT = { "P", "PAUSE" }
local PAUSE_NAME = "P / Pause"
local pauseBtn = ns.NewFrame("Button", "RaidWaitingArcadePauseKey", UIParent)
pauseBtn:RegisterForClicks("AnyUp")
pauseBtn:SetScript("OnClick", function()
    if not ns.Loop.Current() then return end
    if ns.Loop.IsPaused() then
        if ns.PauseUI and not ns.PauseUI.IsShown() then return end
        ns.Loop.Resume()
    else
        ns.Loop.Pause(ns.T("pauseSelf"))
    end
    ns.window:RefreshHead()
end)
pauseBtn:Hide()
local function hot()
    local game = ns.Loop.Current()
    if not game then return false end
    if ns.Loop.IsPaused() then return true end
    return (game.def and game.def.physics) and true or false
end
local function spaceTaken()
    if ns.Loop.IsPaused() then return false end
    local game = ns.Loop.Current()
    if not game then return false end
    return merge(game.def)["SPACE"] ~= nil
end
function ns.Keys.PauseKeys(on)
    if on and not hot() then on = false end
    if not on and not pauseOn then return end
    if InCombatLockdown() then return end
    local owner = ns.window and ns.window:Frame()
    if not owner then return end
    if not on then
        ClearOverrideBindings(owner)
        pauseOn = false
        bound = false
        return
    end
    if not owner:IsShown() then return end
    for _, key in ipairs(PAUSE_HOT) do
        pcall(SetOverrideBindingClick, owner, false, key, pauseBtn:GetName())
    end
    if not spaceTaken() then
        SetOverrideBindingClick(owner, false, "SPACE", pauseBtn:GetName())
    end
    pauseOn = true
end
function ns.Keys.PauseText()
    if spaceTaken() then return PAUSE_NAME end
    return ns.T("pauseKeysFmt", ns.Keys.KeyText("SPACE"), PAUSE_NAME)
end
function ns.Keys.IsBound()
    return bound
end
local seen = {}
function ns.Keys.Cursor(host)
    if not host then return nil end
    local s = host:GetEffectiveScale()
    if not s or s == 0 then return nil end
    local l, b = host:GetLeft(), host:GetBottom()
    if not l or not b then return nil end
    local mx, my = GetCursorPosition()
    local x, y = mx / s - l, my / s - b
    local st = seen[host]
    if not st then st = {}; seen[host] = st end
    local moved = (x ~= st.x or y ~= st.y)
    st.x, st.y = x, y
    local inside = x >= 0 and y >= 0 and x <= host:GetWidth() and y <= host:GetHeight()
    if not ns.Keys.MouseOn() then return x, y, false, false end
    return x, y, moved, inside
end
function RaidWaitingArcadeKey(action, keystate)
    ns.Keys.Fire(action, keystate == "down")
end
