local ADDON, ns = ...
local A = "Interface\\Icons\\"
ns.invadersData = {}
ns.invadersData.mobs = {
    A .. "INV_Misc_MonsterHead_02",
    A .. "INV_Misc_MonsterHead_03",
    A .. "INV_Misc_MonsterHead_04",
    A .. "INV_Misc_Head_Nerubian_01",
    A .. "INV_Misc_Head_Gnoll_01",
    A .. "INV_Misc_Head_Kobold_01",
    A .. "INV_Misc_Head_Quillboar_01",
    A .. "INV_Misc_Head_Murloc_01",
    A .. "INV_Misc_Head_Troll_01",
    A .. "INV_Misc_Head_Centaur_01",
    A .. "INV_Misc_Head_Tauren_01",
    A .. "INV_Misc_Head_Orc_02",
    A .. "INV_Misc_Head_Human_01",
    A .. "INV_Misc_Head_Dwarf_01",
    A .. "INV_Misc_Head_Elf_01",
}
ns.invadersData.bosses = {
    { name = "invaders.bossMarrowgarName",     icon = A .. "Achievement_Boss_LordMarrowgar",      fight = "spin" },
    { name = "invaders.bossSvalaName",         icon = A .. "Achievement_Boss_SvalaSorrowgrave",   fight = "summon" },
    { name = "invaders.bossTaldaramName",      icon = A .. "Achievement_Boss_PrinceTaldaram",     fight = "spin" },
    { name = "invaders.bossHodirName",         icon = A .. "Achievement_Boss_Hodir_01",           fight = "frost" },
    { name = "invaders.bossDeathwhisperName",  icon = A .. "Achievement_Boss_LadyDeathwhisper",   fight = "summon" },
    { name = "invaders.bossRotfaceName",       icon = A .. "achievement_boss_festergutrotface",   fight = "plague" },
    { name = "invaders.bossBaltharusName",     icon = A .. "INV_Misc_RubySanctum1",               fight = "spin" },
    { name = "invaders.bossSavianaName",       icon = A .. "INV_Misc_RubySanctum2",               fight = "plague" },
    { name = "invaders.bossPutricideName",     icon = A .. "achievement_boss_profputricide",      fight = "plague" },
    { name = "invaders.bossZarithrianName",    icon = A .. "INV_Misc_RubySanctum3",               fight = "summon" },
    { name = "invaders.bossSaurfangName",      icon = A .. "achievement_boss_saurfang",           fight = "spin" },
    { name = "invaders.bossAnubarakName",      icon = A .. "Achievement_Boss_Anubarak",           fight = "summon" },
    { name = "invaders.bossLanathelName",      icon = A .. "achievement_boss_lanathel",           fight = "spin" },
    { name = "invaders.bossHalionName",        icon = A .. "INV_Misc_RubySanctum4",               fight = "plague" },
    { name = "invaders.bossSindragosaName",    icon = A .. "Achievement_Boss_Sindragosa",         fight = "frost" },
    { name = "invaders.bossLichKingName",      icon = A .. "Achievement_Boss_Lichking",           fight = "frost" },
}
ns.invadersData.kinds = {
    ghoul   = { icon = A .. "INV_Misc_Head_Undead_01",             score = 10 },
    bat     = { icon = A .. "Ability_Hunter_Pet_Bat",              score = 15 },
    archer  = { icon = A .. "INV_Misc_Bone_Skull_02",              score = 30 },
    cultist = { icon = A .. "INV_Misc_Head_Vrykul",                score = 25 },
    spider  = { icon = A .. "Ability_Hunter_Pet_Spider",           score = 25 },
    necro   = { icon = A .. "INV_Misc_Head_Undead_02",             score = 150 },
    abom    = { icon = A .. "INV_Misc_MonsterHead_01",             score = 60 },
    rock    = { icon = A .. "INV_Stone_09",                        score = 15 },
    barrel  = { icon = A .. "Ability_Vehicle_PlagueBarrel",        score = 20 },
    wyrm    = { icon = A .. "INV_PET_FROSTWYRM",                   score = 400 },
    ice     = { icon = A .. "INV_Stone_02",                        score = 0 },
    cloud   = { icon = A .. "Spell_Shadow_PlagueCloud",            score = 80 },
    spike   = { icon = A .. "INV_Misc_Bone_01",                    score = 25 },
    bug     = { icon = A .. "Ability_Hunter_Pet_Silithid",         score = 20 },
}
ns.invadersData.drops = {
    { key = "heal",   weight = 10, dur = 0,  label = "invaders.buffHealLabel",        tip = "invaders.buffHealTip" },
    { key = "score",  weight = 20, dur = 0,  label = "invaders.buffScoreLabel",   tip = "invaders.buffScoreTip" },
    { key = "gun",    weight = 24, dur = 0,  label = "invaders.buffGunLabel",   tip = "invaders.buffGunTip" },
    { key = "rapid",  weight = 14, dur = 15, label = "invaders.buffRapidLabel",    tip = "invaders.buffRapidTip" },
    { key = "swift",  weight = 14, dur = 15, label = "invaders.buffSwiftLabel",    tip = "invaders.buffSwiftTip" },
    { key = "ward",   weight = 14, dur = 0,  label = "invaders.buffWardLabel",           tip = "invaders.buffWardTip" },
    { key = "ready",  weight = 8,  dur = 0,  label = "invaders.buffReadyLabel",   tip = "invaders.buffReadyTip" },
}
local total = 0
for _, d in ipairs(ns.invadersData.drops) do total = total + d.weight end
ns.invadersData.dropWeight = total
ns.invadersData.dropByKey = {}
for _, d in ipairs(ns.invadersData.drops) do
    ns.invadersData.dropByKey[d.key] = d
end
ns.invadersData.CLASS_CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"
