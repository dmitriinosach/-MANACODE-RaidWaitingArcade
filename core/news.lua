local ADDON, ns = ...
ns.News = {}
local MAX_SHOWN = 4
local LIFE = 6
local SOUND_GAP = 0.4
local NOTIFY = "TellMessage"
local queue = {}
local live = {}
local liveN = 0
local soundAt = 0
local presenter
local function sing()
    local now = GetTime()
    if now - soundAt < SOUND_GAP then return end
    soundAt = now
    ns.Sounds.Play(NOTIFY)
end
local function pump()
    if not presenter then return end
    while liveN < MAX_SHOWN do
        local item = table.remove(queue, 1)
        if not item then return end
        live[item] = true
        liveN = liveN + 1
        if not item.mute then sing() end
        presenter.show(item)
    end
end
function ns.News.Done(item)
    if item and live[item] then
        live[item] = nil
        liveN = liveN - 1
    end
    pump()
end
function ns.News.SetPresenter(p)
    presenter = p
    pump()
end
local function pending(key)
    for it in pairs(live) do
        if it.key == key then return true end
    end
    for i = 1, #queue do
        if queue[i].key == key then return true end
    end
    return false
end
function ns.News.Push(p)
    if type(p) ~= "table" then return end
    if type(p.text) ~= "string" or p.text == "" then return end
    local key = type(p.key) == "string" and p.key or nil
    if key and pending(key) then return end
    local buttons
    if type(p.buttons) == "table" then
        buttons = {}
        for _, b in ipairs(p.buttons) do
            if type(b) == "table" and type(b.text) == "string" and b.text ~= "" then
                buttons[#buttons + 1] = {
                    text = b.text,
                    onClick = type(b.onClick) == "function" and b.onClick or nil,
                }
            end
        end
        if #buttons == 0 then buttons = nil end
    end
    local life
    if not buttons then
        life = tonumber(p.life) or LIFE
        if life <= 0 then life = LIFE end
    end
    queue[#queue + 1] = {
        title = type(p.title) == "string" and p.title or ns.T("appTitle"),
        text = p.text,
        icon = type(p.icon) == "string" and p.icon or nil,
        life = life,
        key = key,
        buttons = buttons,
        mute = p.mute and true or nil,
    }
    pump()
end
