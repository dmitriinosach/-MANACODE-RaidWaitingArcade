local ADDON, ns = ...
local C = {}
ns.Compat = C
C.family = "mainline"
C.checkTemplate = "UICheckButtonTemplate"
local BACKDROP = "BackdropTemplate"
function ns.NewFrame(kind, name, parent, template, id)
    if not template then
        template = BACKDROP
    elseif not template:find(BACKDROP, 1, true) then
        template = template .. "," .. BACKDROP
    end
    return CreateFrame(kind, name, parent, template, id)
end
function ns.Paint(tex, r, g, b, a)
    if type(r) == "table" then r, g, b, a = r[1], r[2], r[3], r[4] end
    tex:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
end
function ns.Gradient(tex, orient, r1, g1, b1, a1, r2, g2, b2, a2)
    tex:SetGradient(orient, CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
end
function ns.AlphaChange(anim, delta, from)
    if from == nil then
        local r = anim:GetRegionParent()
        from = r and r:GetAlpha() or 1
    end
    anim:SetFromAlpha(from)
    anim:SetToAlpha(math.min(1, math.max(0, from + delta)))
end
local ROT_PAD = (math.sqrt(2) - 1) / 2
function ns.Rotate(tex, rad)
    tex:SetTexCoord(-ROT_PAD, 1 + ROT_PAD, -ROT_PAD, 1 + ROT_PAD)
    tex:SetRotation(rad)
end
local CYRILLIC = {
    ["fonts\\frizqt__.ttf"] = "Fonts\\FRIZQT___CYR.TTF",
    ["fonts\\morpheus.ttf"] = "Fonts\\MORPHEUS_CYR.TTF",
    ["fonts\\skurri.ttf"] = "Fonts\\SKURRI_CYR.TTF",
}
function ns.SetFont(fs, path, size, flags)
    if type(path) == "string" then path = CYRILLIC[path:lower()] or path end
    return fs:SetFont(path, size, flags or "")
end
local RENAMED = {
    PARTY_MEMBERS_CHANGED = "GROUP_ROSTER_UPDATE",
    RAID_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",
}
function ns.Listen(frame, event)
    return (pcall(frame.RegisterEvent, frame, RENAMED[event] or event))
end
function C.RegisterPrefix(prefix)
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
end
function C.SendAddon(prefix, body, chan, to)
    C_ChatInfo.SendAddonMessage(prefix, body, chan, to)
end
function C.GroupSize()
    if IsInRaid() then return GetNumGroupMembers(), 0 end
    return 0, GetNumSubgroupMembers()
end
function C.ItemIcon(id)
    return C_Item.GetItemIconByID(id)
end
function C.ItemInfo(id)
    return C_Item.GetItemInfo(id)
end
function C.SpellIcon(id)
    return C_Spell.GetSpellTexture(id)
end
function C.BagSlots(bag)
    return C_Container.GetContainerNumSlots(bag)
end
function C.BagItemIcon(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    return info and info.iconFileID
end
function C.AddonMeta(addon, field)
    return C_AddOns.GetAddOnMetadata(addon, field)
end
function C.NumFriends()
    return C_FriendList.GetNumFriends() or 0
end
function C.FriendInfo(i)
    local f = C_FriendList.GetFriendInfoByIndex(i)
    if not f then return nil end
    return f.name, f.connected
end
function C.NumIgnores()
    return C_FriendList.GetNumIgnores() or 0
end
function C.IgnoreName(i)
    return C_FriendList.GetIgnoreName(i)
end
function C.RefreshRoster()
    C_FriendList.ShowFriends()
    if IsInGuild() then C_GuildInfo.GuildRoster() end
end
function C.MacroIcons()
    local out = {}
    GetLooseMacroIcons(out)
    GetMacroIcons(out)
    return out
end
local function soundKit(ref)
    if type(ref) == "number" then return ref end
    if type(ref) ~= "string" or not SOUNDKIT then return nil end
    return SOUNDKIT[ref] or SOUNDKIT[ref:upper()]
        or SOUNDKIT[(ref:gsub("(%l)(%u)", "%1_%2")):upper()]
end
function C.PlaySound(ref)
    local kit = soundKit(ref)
    if not kit then return false end
    PlaySound(kit, "Master")
    return true
end
local function fileID(ref)
    if type(ref) ~= "string" then return ref end
    local k = ref:lower():gsub("\\", "/"):gsub("%.%w+$", "")
    return ns.FDID and ns.FDID[k] or ref
end
function C.Model(path)
    return fileID(path)
end
function C.PlaySoundFile(ref)
    pcall(PlaySoundFile, fileID(ref), "Master")
end
function C.PlayMusic(ref)
    return (pcall(PlayMusic, fileID(ref)))
end
function C.StopMusic()
    StopMusic()
end
function C.ClearHighlight(button)
    button:ClearHighlightTexture()
end
function C.CheckLabel(check)
    return check.Text or check.text
end
local category
function C.CanAddOptions()
    return Settings ~= nil and Settings.RegisterCanvasLayoutCategory ~= nil
end
function C.AddOptions(panel)
    category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end
function C.OpenOptions()
    if category then Settings.OpenToCategory(category:GetID()) end
end
function C.HideOptions()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
end
