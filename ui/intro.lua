local ADDON, ns = ...
ns.Intro = {}
local SLIDES = {
    { head = "introGamesHead", target = "shell.games", lines = { "introGames1", "introGames2" } },
    { head = "introRulesHead", lines = { "introRules1", "introRules2" } },
    { head = "introMateHead", target = "shell.mate", lines = { "introMate1", "introMate2" } },
    { head = "introPrefsHead", target = "shell.prefs", lines = { "introPrefs1", "introPrefs2" } },
    { head = "introSizeHead", target = "shell.grip", lines = { "introSize1", "introSize2", "introSize3" } },
}
local function build()
    local out = {}
    for i, s in ipairs(SLIDES) do
        local lines = {}
        for j, k in ipairs(s.lines) do lines[j] = ns.T(k) end
        out[i] = { head = ns.T(s.head), target = s.target, lines = lines }
    end
    return out
end
function ns.Intro.Show()
    ns.Slides.Show(ns.T("introTitle"), build())
end
local waiter
function ns.Intro.Maybe()
    if ns.Store.DB().introSeen then return end
    waiter = waiter or ns.NewFrame("Frame")
    waiter:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        if not ns.window:IsShown() or ns.window:CurrentId() then return end
        ns.Store.DB().introSeen = true
        ns.Intro.Show()
    end)
end
