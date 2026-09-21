local ADDON, ns = ...
local function play(id)
    ns.window:Open()
    ns.window:StartGame(id, nil, ns.Store.HasSaved(id))
end
local function render()
    local doc = { page = {} }
    tinsert(doc, { k = "h", t = ns.T("htpHead") })
    local items = {}
    for _, def in ipairs(ns.GameList()) do
        local mark = ns.Records.MainFor(def, ns.Store.LastOpts(def.id))
        local rec = ns.Records.Best(def.id, ns.Store.LastOpts(def.id))
            or ns.Records.Best(def.id)
        local sub
        if ns.Store.HasSaved(def.id) then
            sub = ns.T("menuResume")
        elseif not ns.Records.Keeps(def) then
            sub = nil
        elseif rec then
            sub = ns.T("menuRecord", ns.Records.Format(mark, rec[mark.key]))
        else
            sub = ns.T("menuNoRecord")
        end
        items[#items + 1] = {
            label = def.label or def.id,
            sub = sub,
            tip = def.tip,
            onClick = function() play(def.id) end,
        }
    end
    if #items > 0 then
        tinsert(doc, { k = "actions", cols = 2, items = items })
    else
        tinsert(doc, { k = "d", t = ns.T("menuEmpty") })
    end
    tinsert(doc, { k = "d", t = ns.T("htpNote") })
    return ns.T("htpPage"), doc
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if not HowToPlay_API or not HowToPlay_API.RegisterPage then return end
    HowToPlay_API.RegisterPage{
        id = "arcade",
        label = ns.T("htpPage"),
        tip = ns.T("htpTip"),
        order = 90,
        render = render,
    }
end)
