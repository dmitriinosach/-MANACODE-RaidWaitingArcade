local ADDON, ns = ...
ns.Help = {}
local card
local function ensure()
    if card then return card end
    card = ns.MakeCard{
        name = "RaidWaitingArcadeHelpOverlay",
        escape = true,
        dismiss = true,
        strata = "FULLSCREEN_DIALOG",
        width = 430,
        look = function() return ns.GameLook() end,
    }
    return card
end
function ns.Help.Show(title, body)
    local win = ns.window and ns.window:Frame()
    if not win then return end
    ensure():Show(win, ns.TL(title), ns.TLines(body), {
        label = ns.T("helpClose"),
        onClick = function() ns.Help.Hide() end,
    })
end
function ns.Help.Hide()
    if card then card:Hide() end
end
function ns.Help.IsShown()
    return card and card:IsShown() or false
end
