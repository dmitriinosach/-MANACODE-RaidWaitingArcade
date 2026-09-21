local ADDON, ns = ...
local C_TITLE = { 1, 1, 1 }
local C_BODY  = { 1, 0.82, 0 }
local C_DIM   = { 0.62, 0.62, 0.62 }
local function ownText(f)
    if f.isSelect and f.caption then return f.caption end
    if f.text and f.text.GetText then return f.text:GetText() end
    if f.label and f.label.GetText then return f.label:GetText() end
    if f.GetText then return f:GetText() end
    return nil
end
function ns.TipShow(f)
    local body = f.tip
    local title = f.tipTitle
    if title == nil then title = ownText(f) end
    if title == false or title == "" then title = nil end
    if title and body and title == body then body = nil end
    if not title and not body and not f.tipDim then return end
    GameTooltip:SetOwner(f, f.tipAnchor or "ANCHOR_RIGHT")
    local first = true
    local function line(text, c)
        if first then
            GameTooltip:SetText(text, c[1], c[2], c[3], 1, true)
            first = false
        else
            GameTooltip:AddLine(text, c[1], c[2], c[3], true)
        end
    end
    if title then line(title, f.tipColor or C_TITLE) end
    if body then line(body, f.tipBodyColor or C_BODY) end
    if f.tipDim then line(f.tipDim, C_DIM) end
    GameTooltip:Show()
end
function ns.TipHide()
    GameTooltip:Hide()
end
