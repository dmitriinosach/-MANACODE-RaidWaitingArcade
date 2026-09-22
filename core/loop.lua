local ADDON, ns = ...
local STEP = 1 / 60
local MAX_DT = 0.1
local MAX_STEPS = 6
local FRAME = 1 / 60
local since = 0
ns.Loop = {}
local driver = ns.NewFrame("Frame", "RaidWaitingArcadeLoop", UIParent)
driver:Hide()
local cur
local acc = 0
local paused = false
local pauseWhy
local function onUpdate(self, elapsed)
    if not cur or paused then return end
    since = since + elapsed
    if since < FRAME then return end
    local dt = since
    since = 0
    if dt > MAX_DT then dt = MAX_DT end
    local function step(d)
        local ok = ns.SafeCall(cur, "Update", d)
        if not ok then
            ns.Loop.Stop()
            ns.window:ToMenu()
            return false
        end
        return true
    end
    if cur.def and cur.def.physics then
        acc = acc + dt
        local steps = 0
        while acc >= STEP and steps < MAX_STEPS do
            if not step(STEP) then return end
            acc = acc - STEP
            steps = steps + 1
        end
        if steps >= MAX_STEPS then acc = 0 end
    else
        if not step(dt) then return end
    end
    ns.window:Tick(dt)
    local ok, done = ns.SafeCall(cur, "IsOver")
    if not ok then
        ns.Loop.Stop()
        ns.window:ToMenu()
        return
    end
    if done then
        if ns.window:Finale() then return end
        ns.Loop.Stop()
        ns.window:GameOver()
    end
end
driver:SetScript("OnUpdate", onUpdate)
function ns.Loop.Start(game)
    cur = game
    acc = 0
    paused = false
    pauseWhy = nil
    driver:Show()
end
function ns.Loop.Stop()
    cur = nil
    paused = false
    pauseWhy = nil
    ns.Keys.PauseKeys(false)
    if ns.PauseUI then ns.PauseUI.Sync() end
    driver:Hide()
end
function ns.Loop.Pause(why)
    if not cur or paused then return end
    paused = true
    pauseWhy = why
    ns.Keys.Clear()
    ns.Keys.PauseKeys(true)
    ns.window:SaveCurrent()
    ns.window:RefreshHead()
end
function ns.Loop.Resume()
    if not cur then return end
    paused = false
    pauseWhy = nil
    acc = 0
    if cur.Key then ns.Keys.Bind(cur.def) end
    ns.Keys.PauseKeys(true)
    ns.window:RefreshHead()
end
function ns.Loop.IsPaused()
    return paused, pauseWhy
end
function ns.Loop.Current()
    return cur
end
local events = ns.NewFrame("Frame", "RaidWaitingArcadeEvents", UIParent)
ns.Listen(events, "ADDON_LOADED")
ns.Listen(events, "PLAYER_LOGOUT")
ns.Listen(events, "PLAYER_REGEN_DISABLED")
ns.Listen(events, "PLAYER_REGEN_ENABLED")
ns.Listen(events, "READY_CHECK")
ns.Listen(events, "PARTY_INVITE_REQUEST")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            ns.Store.Init()
            if ns.Shelves and ns.Shelves.Settle then ns.Shelves.Settle() end
        end
    elseif event == "PLAYER_LOGOUT" then
        ns.window:SaveCurrent()
        ns.Duo.Quit("logout")
    elseif event == "PLAYER_REGEN_DISABLED" then
        if cur then
            ns.Loop.Pause(ns.T("pauseCombat"))
            if ns.Store.CombatClose() then ns.window:Close() end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.Keys.Retry()
    elseif event == "READY_CHECK" or event == "PARTY_INVITE_REQUEST" then
        if cur then ns.Loop.Pause(ns.T(event == "READY_CHECK" and "pauseReady" or "pauseInvite")) end
    end
end)
