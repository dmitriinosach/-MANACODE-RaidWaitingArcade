local ADDON, ns = ...
local D = ns.invadersData
local lower, find, match = string.lower, string.find, string.match
local paths, lows
local function build()
    if paths then return end
    paths, lows = {}, {}
    if type(GetNumMacroIcons) ~= "function" or type(GetMacroIconInfo) ~= "function" then
        return
    end
    local n = GetNumMacroIcons() or 0
    for i = 1, n do
        local p = GetMacroIconInfo(i)
        if type(p) == "string" and p ~= "" then
            if not find(p, "\\", 1, true) then p = "Interface\\Icons\\" .. p end
            paths[#paths + 1] = p
            lows[#lows + 1] = lower(match(p, "([^\\]+)$") or p)
        end
    end
end
function D.Find(wants, fallback)
    build()
    if not paths or #paths == 0 then return fallback end
    for _, w in ipairs(wants) do
        local lw = lower(w)
        for i = 1, #lows do
            if lows[i] == lw then return paths[i] end
        end
    end
    for _, w in ipairs(wants) do
        local lw = lower(w)
        for i = 1, #lows do
            if find(lows[i], lw, 1, true) then return paths[i] end
        end
    end
    return fallback
end
function D.IconCount()
    build()
    return paths and #paths or 0
end
local A = "Interface\\Icons\\"
local WANT = {
    ship = {
        { "ability_mount_gyrocoptor", "inv_gizmo_flyingmachine", "gyrocop",
          "flyingmachine", "rocketmount", "zeppelin", "airship" },
        false,
    },
    shotMAGE    = { { "spell_fire_flamebolt", "spell_fire_fireball02", "fireball" },
                    A .. "Spell_Fire_FireBolt02" },
    shotHUNTER  = { { "inv_ammo_arrow_02", "inv_ammo_arrow_01", "ammo_arrow" },
                    A .. "Ability_Marksmanship" },
    shotPRIEST  = { { "spell_shadow_shadowbolt", "spell_shadow_mindflay", "shadowbolt" },
                    A .. "Spell_Shadow_ShadowWordPain" },
    shotWARRIOR = { { "inv_throwingaxe_01", "inv_axe_01", "throwingaxe" },
                    A .. "Ability_BackStab" },
    bomb = { { "spell_fire_felflamebolt", "spell_shadow_shadowbolt", "spell_fire_immolation" },
             A .. "Spell_Shadow_DeathCoil" },
    ufo = { { "achievement_dungeon_hordeairship", "achievement_boss_skybreaker", "zeppelin", "airship" },
            A .. "Achievement_Dungeon_HordeAirship" },
    potRapid = { { "inv_potion_27", "inv_potion_20", "inv_potion_" },
                 A .. "Ability_Marksmanship" },
    potSwift = { { "inv_potion_43", "inv_potion_31", "inv_potion_" },
                 A .. "Ability_Rogue_Sprint" },
}
local found
function D.Pack()
    if found then return found end
    found = {}
    for key, row in pairs(WANT) do
        local wants, fb = row[1], row[2]
        if fb == false then
            local hit = D.Find(wants, "")
            found[key] = (hit ~= "") and hit or nil
        else
            found[key] = D.Find(wants, fb)
        end
    end
    return found
end
function D.DropArt(key)
    return D.BOLT[key] and key or "score"
end
D.RIM       = "Interface\\Minimap\\MiniMap-TrackingBorder"
D.RIM_ICON  = 20 / 31
D.RIM_SCALE = 53 / 31
D.GLOW = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
D.UFO_FALLBACK = A .. "Achievement_Dungeon_HordeAirship"
D.SHIP_ART = "Interface\\AddOns\\HTP_Arcade\\art\\invaders_ship.tga"
D.BOLTS = "Interface\\AddOns\\HTP_Arcade\\art\\invaders_bolts.tga"
D.BOLT = {
    shotfire = { 0, 0.125, 0, 0.25 },
    shotarrow = { 0.125, 0.25, 0, 0.25 },
    shotshadow = { 0.25, 0.375, 0, 0.25 },
    shotaxe = { 0.375, 0.5, 0, 0.25 },
    shotlaser = { 0.5, 0.625, 0, 0.25 },
    shotbolt = { 0.625, 0.75, 0, 0.25 },
    plain = { 0.75, 0.875, 0, 0.25 },
    aim = { 0.875, 1, 0, 0.25 },
    web = { 0, 0.125, 0.25, 0.5 },
    bone = { 0.125, 0.25, 0.25, 0.5 },
    ice = { 0.25, 0.375, 0.25, 0.5 },
    plague = { 0.375, 0.5, 0.25, 0.5 },
    shadow = { 0.5, 0.625, 0.25, 0.5 },
    spark = { 0.625, 0.75, 0.25, 0.5 },
    heal = { 0.75, 0.875, 0.25, 0.5 },
    score = { 0.875, 1, 0.25, 0.5 },
    ward = { 0, 0.125, 0.5, 0.75 },
    ready = { 0.125, 0.25, 0.5, 0.75 },
    rapid = { 0.25, 0.375, 0.5, 0.75 },
    swift = { 0.375, 0.5, 0.5, 0.75 },
    gunfire = { 0.5, 0.625, 0.5, 0.75 },
    gunarrow = { 0.625, 0.75, 0.5, 0.75 },
    gunshadow = { 0.75, 0.875, 0.5, 0.75 },
    gunaxe = { 0.875, 1, 0.5, 0.75 },
    gunlaser = { 0, 0.125, 0.75, 1 },
    gunbolt = { 0.125, 0.25, 0.75, 1 },
}
D.ELITE       = "Interface\\TargetingFrame\\UI-TargetingFrame-Elite"
D.ELITE_COORD = { 0.543, 0.9922, 0, 0.7656 }
D.ELITE_RATIO = 1.17
D.ELITE_GOLD   = { 1.00, 0.86, 0.35 }
D.ELITE_SILVER = { 0.82, 0.86, 0.92 }
