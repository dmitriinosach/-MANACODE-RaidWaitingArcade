local ADDON, ns = ...
ns.ADDON = ADDON
ns.VERSION = "1.0.0-beta"
ns.games = {}
ns.gameOrder = {}
local function prefix()
    local name = ns.T and ns.T("abtTitle") or nil
    if type(name) ~= "string" or name == "" or name:find("^%[") then name = "HTP Arcade" end
    return "|cff33cc44" .. name .. "|r: "
end
function ns.say(msg)
    DEFAULT_CHAT_FRAME:AddMessage(prefix() .. tostring(msg))
end
ns.broken = {}
function ns.MarkBroken(id, why)
    if ns.broken[id] then return end
    ns.broken[id] = why or "?"
    for i = #ns.gameOrder, 1, -1 do
        if ns.gameOrder[i].id == id then tremove(ns.gameOrder, i) end
    end
    ns.say(("игра %s убрана из списка: %s. Подробности — /arc broken.")
        :format(id, why or "?"))
end
function ns.SafeCall(game, method, ...)
    local f = game and game[method]
    if type(f) ~= "function" then
        return false, ("нет метода :%s"):format(method)
    end
    local ok, res = pcall(f, game, ...)
    if not ok then
        local id = game.def and game.def.id or "?"
        ns.MarkBroken(id, ("ошибка в :%s — %s"):format(method, tostring(res)))
    end
    return ok, res
end
local REQUIRED = { "Start", "Update", "Click", "Move", "Score", "IsOver", "Stop" }
local DUO_KINDS = { turns = true, score = true, none = true }
function ns.CheckGame(game, id)
    if type(game) ~= "table" then
        ns.MarkBroken(id, "New вернул не таблицу")
        return false
    end
    for _, m in ipairs(REQUIRED) do
        if type(game[m]) ~= "function" then
            ns.MarkBroken(id, ("нет обязательного метода :%s"):format(m))
            return false
        end
    end
    local def = ns.games[id]
    if def and def.duo == "turns" and type(game.Turn) ~= "function" then
        ns.MarkBroken(id, "объявлен duo = turns, но нет метода :Turn")
        return false
    end
    return true
end
function ns.RegisterGame(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or type(def.New) ~= "function" then
        ns.say("игра прислала негодное объявление — нужны id и New.")
        return false
    end
    if ns.games[def.id] then
        ns.say("игра уже зарегистрирована: " .. def.id)
        return false
    end
    local flaw
    if type(def.label) ~= "string" or def.label == "" then
        flaw = "нет подписи (label)"
    elseif def.help == nil then
        flaw = "нет правил (help)"
    elseif def.physics ~= nil and type(def.physics) ~= "boolean" then
        flaw = "physics не булево"
    elseif def.done ~= nil and type(def.done) ~= "boolean" then
        flaw = "done не булево"
    elseif def.duo ~= nil and not DUO_KINDS[def.duo] then
        flaw = "duo не из списка: turns, score, none"
    elseif def.look ~= nil and (type(def.look) ~= "table" or def.look.screen == nil) then
        flaw = "look не вёрстка из ns.MakeLook"
    end
    if flaw then
        ns.say(("игра %s не объявлена как надо: %s. В список не берём."):format(def.id, flaw))
        ns.broken[def.id] = flaw
        return false
    end
    def.order = def.order or 100
    def.duo = def.duo or "none"
    ns.games[def.id] = def
    tinsert(ns.gameOrder, def)
    table.sort(ns.gameOrder, function(a, b)
        if a.order == b.order then return a.id < b.id end
        return a.order < b.order
    end)
    return true
end
function ns.GameList()
    return ns.gameOrder
end
function ns.MenuList()
    if not (ns.Store and ns.Store.HideDone()) then return ns.gameOrder end
    local out = {}
    for _, def in ipairs(ns.gameOrder) do
        if not def.done then out[#out + 1] = def end
    end
    return out
end
function ns.HasDoneGames()
    for _, def in ipairs(ns.gameOrder) do
        if def.done then return true end
    end
    return false
end
SLASH_HTPARCADE1 = "/arc"
SLASH_HTPARCADE2 = "/arcade"
SlashCmdList["HTPARCADE"] = function(msg)
    local id = strtrim(msg or ""):lower()
    if id == "broken" then
        local n = 0
        for gid, why in pairs(ns.broken) do
            n = n + 1
            ns.say(("|cffff4040%s|r — %s"):format(gid, why))
        end
        if n == 0 then ns.say("сломанных игр нет.") end
        return
    end
    if id == "about" then
        if ns.About then ns.About.Toggle() end
        return
    end
    if id ~= "" and ns.games[id] then
        ns.window:Open()
        ns.window:StartGame(id)
        return
    end
    if id ~= "" then
        ns.say("нет такой игры: " .. id)
    end
    ns.window:Toggle()
end
