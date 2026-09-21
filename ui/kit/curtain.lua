local ADDON, ns = ...
ns.Curtain = {}
local card
local LEVEL = 100
function ns.Curtain.Show(host, title, body, label, onPlay)
    ns.Curtain.Ask(host, title, body, {
        {
            label = label or ns.T("curtainPlay"),
            tip = ns.T("curtainTip"),
            onClick = function()
                ns.Curtain.Hide()
                if onPlay then onPlay() end
            end,
        },
    })
end
function ns.Curtain.Ask(host, title, body, buttons)
    card = card or ns.MakeCard{ name = "RaidWaitingArcadeCurtain", level = LEVEL }
    card:Show(host, title, body, buttons)
end
function ns.Curtain.Hide()
    if card then card:Hide() end
end
function ns.Curtain.IsShown()
    return card and card:IsShown() or false
end
