local ADDON, ns = ...
ns.RegisterShelves("gems", {
    label = "Три в ряд",
    shelves = {
        { key = "c1", label = "Цвет 1" },
        { key = "c2", label = "Цвет 2" },
        { key = "c3", label = "Цвет 3" },
        { key = "c4", label = "Цвет 4" },
        { key = "c5", label = "Цвет 5" },
        { key = "c6", label = "Цвет 6" },
        { key = "sp_row",   label = "Луч ряда",      role = "fixed" },
        { key = "sp_col",   label = "Луч столбца",   role = "fixed" },
        { key = "sp_bomb",  label = "Бомба",        role = "fixed" },
        { key = "sp_meta",  label = "Призма",       role = "fixed" },
        { key = "sp_wild",  label = "Джокер",       role = "fixed" },
        { key = "blk_rock", label = "Порода",       role = "fixed" },
        { key = "blk_raw",  label = "Сырьё",        role = "fixed" },
    },
})
ns.RegisterShelfData("gems", "gems",
    "theme.gems", {
        ["c1"] = {
            "INV_Jewelcrafting_Gem_37", "INV_Jewelcrafting_CrimsonSpinel_02", "INV_Jewelcrafting_LivingRuby_03",
            "INV_Misc_Gem_Ruby_01", "INV_Jewelcrafting_Gem_04", "INV_Misc_Gem_Ruby_02",
            "inv_jewelcrafting_dragonseye05",
        },
        ["c2"] = {
            "INV_Jewelcrafting_Gem_42", "INV_Jewelcrafting_EmpyreanSapphire_02", "INV_Jewelcrafting_StarOfElune_03",
            "INV_Jewelcrafting_Gem_24", "INV_Jewelcrafting_Gem_05", "inv_jewelcrafting_dragonseye04",
        },
        ["c3"] = {
            "INV_Jewelcrafting_Gem_38", "INV_Jewelcrafting_Lionseye_02", "INV_Jewelcrafting_Dawnstone_03",
            "INV_Jewelcrafting_Gem_21", "INV_Jewelcrafting_Gem_03", "INV_Misc_Gem_Topaz_02",
            "INV_Misc_Gem_Topaz_01", "inv_jewelcrafting_dragonseye03",
        },
        ["c4"] = {
            "inv_jewelcrafting_gem_41", "INV_Jewelcrafting_SeasprayEmerald_02", "INV_Jewelcrafting_Talasite_03",
            "INV_Jewelcrafting_Gem_19", "INV_Jewelcrafting_Gem_01", "INV_Misc_Gem_Emerald_02",
        },
        ["c5"] = {
            "inv_jewelcrafting_gem_40", "INV_Jewelcrafting_ShadowsongAmethyst_02", "INV_Jewelcrafting_Nightseye_03",
            "INV_Jewelcrafting_Gem_23", "INV_Jewelcrafting_Gem_06", "INV_Jewelcrafting_ShadowSpirit_01",
        },
        ["c6"] = {
            "inv_jewelcrafting_gem_39", "INV_Jewelcrafting_Pyrestone_02", "INV_Jewelcrafting_NobleTopaz_03",
            "INV_Jewelcrafting_Gem_20", "INV_Misc_Gem_FlameSpessarite_02", "INV_Jewelcrafting_Gem_02",
        },
        ["sp_bomb"] = {
            "INV_Misc_Bomb_01", "INV_Misc_Bomb_02", "INV_Gizmo_FelIronBomb",
            "INV_Misc_EngGizmos_31", "Spell_Shadow_MindBomb",
        },
        ["sp_wild"] = {
            "INV_Jewelcrafting_DragonsEye02",
        },
        ["sp_meta"] = {
            "INV_Misc_Gem_Diamond_01", "inv_misc_gem_pearl_14", "INV_Jewelcrafting_IceDiamond_01",
            "INV_Jewelcrafting_IceDiamond_02", "INV_Misc_Gem_Diamond_04", "INV_Misc_Gem_Diamond_05",
            "INV_Misc_Gem_Diamond_06", "INV_Misc_Gem_Diamond_07",
        },
        ["blk_rock"] = {
            "INV_Stone_06", "INV_Stone_09", "INV_Stone_10",
            "INV_Stone_12", "INV_Stone_15", "INV_Ore_Adamantium",
            "INV_Ore_Saronite_01", "INV_Ore_Tin_01", "INV_Ore_Iron_01",
            "INV_Ore_Thorium_02", "INV_Ore_Platinum_01",
        },
        ["blk_raw"] = {
            "INV_Misc_Gem_Stone_01", "INV_Misc_Gem_Crystal_01", "INV_Misc_Gem_Crystal_02",
            "INV_Misc_Gem_01", "INV_Misc_Gem_Opal_03", "INV_Misc_Gem_Pearl_09",
        },
    }, {
})
ns.RegisterShelfData("gems", "bijou",
    "theme.bijou", {
        ["c1"] = {
            "INV_Bijou_Red",
        },
        ["c2"] = {
            "INV_Bijou_Blue",
        },
        ["c3"] = {
            "INV_Bijou_Yellow",
        },
        ["c4"] = {
            "INV_Bijou_Purple",
        },
        ["c5"] = {
            "INV_Bijou_Orange", "INV_Bijou_Gold",
        },
        ["c6"] = {
            "INV_Bijou_Green",
        },
        ["sp_meta"] = {
            "INV_Bijou_Silver",
        },
        ["sp_wild"] = {
            "INV_Jewelcrafting_DragonsEye02",
        },
        ["blk_rock"] = {
            "INV_Stone_06", "INV_Stone_09", "INV_Stone_10",
            "INV_Stone_12", "INV_Stone_15", "INV_Ore_Adamantium",
            "INV_Ore_Saronite_01", "INV_Ore_Tin_01", "INV_Ore_Iron_01",
            "INV_Ore_Thorium_02", "INV_Ore_Platinum_01",
        },
        ["blk_raw"] = {
            "INV_Misc_Gem_Stone_01", "INV_Misc_Gem_Crystal_01", "INV_Misc_Gem_Crystal_02",
            "INV_Misc_Gem_01", "INV_Misc_Gem_Opal_03", "INV_Misc_Gem_Pearl_09",
        },
    }, {
        ["c1"] = "red",
        ["c2"] = "blue",
        ["c3"] = "yellow",
        ["c4"] = "purple",
        ["c5"] = "orange",
        ["c6"] = "green",
        ["sp_meta"] = "prismatic",
})
