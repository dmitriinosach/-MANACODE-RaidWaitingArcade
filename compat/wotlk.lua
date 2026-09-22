local ADDON, ns = ...
local C = {}
ns.Compat = C
C.family = "wotlk"
C.checkTemplate = "InterfaceOptionsCheckButtonTemplate"
function ns.NewFrame(kind, name, parent, template, id)
    return CreateFrame(kind, name, parent, template, id)
end
function ns.Paint(tex, r, g, b, a)
    tex:SetTexture(r, g, b, a)
end
function ns.Gradient(tex, orient, r1, g1, b1, a1, r2, g2, b2, a2)
    tex:SetGradientAlpha(orient, r1, g1, b1, a1, r2, g2, b2, a2)
end
function ns.AlphaChange(anim, delta, from)
    anim:SetChange(delta)
end
function ns.Rotate(tex, rad)
    tex:SetRotation(rad)
end
function ns.SetFont(fs, path, size, flags)
    return fs:SetFont(path, size, flags)
end
function ns.Listen(frame, event)
    frame:RegisterEvent(event)
    return true
end
function C.RegisterPrefix()
end
function C.SendAddon(prefix, body, chan, to)
    SendAddonMessage(prefix, body, chan, to)
end
function C.GroupSize()
    local raid = GetNumRaidMembers and GetNumRaidMembers() or 0
    local party = GetNumPartyMembers and GetNumPartyMembers() or 0
    return raid, party
end
function C.ItemIcon(id)
    return GetItemIcon(id)
end
function C.ItemInfo(id)
    return GetItemInfo(id)
end
function C.SpellIcon(id)
    local _, _, tex = GetSpellInfo(id)
    return tex
end
function C.BagSlots(bag)
    return GetContainerNumSlots(bag)
end
function C.BagItemIcon(bag, slot)
    return (GetContainerItemInfo(bag, slot))
end
function C.AddonMeta(addon, field)
    return GetAddOnMetadata and GetAddOnMetadata(addon, field)
end
function C.NumFriends()
    return GetNumFriends and GetNumFriends() or 0
end
function C.FriendInfo(i)
    local name, _, _, _, connected = GetFriendInfo(i)
    return name, connected
end
function C.NumIgnores()
    return GetNumIgnores and GetNumIgnores() or 0
end
function C.IgnoreName(i)
    return GetIgnoreName(i)
end
function C.RefreshRoster()
    if ShowFriends then ShowFriends() end
    if IsInGuild and IsInGuild() and GuildRoster then GuildRoster() end
end
function C.MacroIcons()
    local out = {}
    if type(GetNumMacroIcons) ~= "function" or type(GetMacroIconInfo) ~= "function" then return out end
    for i = 1, GetNumMacroIcons() or 0 do
        out[#out + 1] = GetMacroIconInfo(i)
    end
    return out
end
function C.PlaySound(ref)
    PlaySound(ref)
    return true
end
function C.Model(path)
    return path
end
function C.PlaySoundFile(ref)
    PlaySoundFile(ref)
end
function C.PlayMusic(ref)
    if type(PlayMusic) ~= "function" then return false end
    PlayMusic(ref)
    return true
end
function C.StopMusic()
    if type(StopMusic) == "function" then StopMusic() end
end
function C.ClearHighlight(button)
    button:SetHighlightTexture(nil)
end
function C.CheckLabel(check)
    return _G[check:GetName() .. "Text"]
end
function C.CanAddOptions()
    return type(InterfaceOptions_AddCategory) == "function"
end
function C.AddOptions(panel)
    InterfaceOptions_AddCategory(panel)
end
function C.OpenOptions(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end
function C.HideOptions()
    if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
end
