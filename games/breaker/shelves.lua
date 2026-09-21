local ADDON, ns = ...
ns.RegisterShelves("breaker", {
    label = "Шарики",
    shelves = {
        { key = "c1", label = "Цвет 1" },
        { key = "c2", label = "Цвет 2" },
        { key = "c3", label = "Цвет 3" },
        { key = "c4", label = "Цвет 4" },
        { key = "c5", label = "Цвет 5" },
        { key = "c6", label = "Цвет 6" },
        { key = "c7", label = "Цвет 7" },
    },
})
ns.RegisterShelfData("breaker", "enge",
    "theme.engineering", {
        ["c1"] = {
            "INV_Misc_EngGizmos_12", "INV_Gizmo_AdamantiteFrame", "INV_Misc_EngGizmos_28",
            "INV_Misc_MissileSmallCluster_Blue", "INV_Misc_MissileLargeCluster_Blue",
        },
        ["c2"] = {
            "INV_Misc_EngGizmos_27", "INV_Misc_Food_26",
        },
        ["c3"] = {
            "INV_Ingot_03", "INV_Ingot_Bronze", "INV_Misc_Dust_06",
        },
        ["c4"] = {
            "INV_Ore_Eternium", "INV_Ingot_11", "INV_Gizmo_KhoriumPowerCore",
        },
        ["c5"] = {
            "INV_Gizmo_SuperSapperCharge", "INV_Misc_Dust_01", "INV_Gizmo_05",
        },
        ["c6"] = {
            "INV_Ingot_FelIron", "INV_Ore_FelIron", "INV_Ingot_Felsteel",
            "INV_Gizmo_FelIronBolts", "INV_Gizmo_FelIronCasing", "INV_Misc_MissileLargeCluster_Green",
            "INV_Misc_EngGizmos_10", "INV_Misc_EngGizmos_09", "INV_Gizmo_FelIronShell",
        },
        ["c7"] = {
            "INV_Gizmo_BronzeFramework_01", "INV_Crate_01", "INV_Crate_02",
            "INV_Crate_03",
        },
    }, {
        ["c1"] = "blue",
        ["c2"] = "red",
        ["c3"] = "yellow",
        ["c4"] = "purple",
        ["c5"] = "orange",
        ["c6"] = "green",
        ["c7"] = "dragonseye",
}, 20260911)
ns.RegisterShelfData("breaker", "bm",
    "theme.smithing", {
        ["c1"] = {
            "INV_Ore_Copper_01", "INV_Ingot_Titansteel_red", "INV_Stone_WeightStone_05",
            "INV_Stone_GrindingStone_05", "INV_Ingot_02",
        },
        ["c2"] = {
            "INV_Ore_Cobalt", "INV_Ingot_Cobalt", "INV_Ore_Arcanite_02",
            "INV_Ingot_Titansteel_blue", "INV_Ore_TrueSilver_01",
        },
        ["c3"] = {
            "INV_Ingot_03", "INV_Ore_Gold_01", "INV_Ingot_Bronze",
        },
        ["c4"] = {
            "INV_Ore_Eternium", "INV_Ingot_11", "INV_Ore_Khorium_01",
        },
        ["c6"] = {
            "INV_Ingot_FelIron", "INV_Ore_FelIron", "INV_Ingot_Felsteel",
            "INV_Ingot_Yoggthorite", "INV_Ore_Saronite_01", "INV_Stone_04",
        },
        ["c7"] = {
            "INV_Stone_09", "INV_Stone_10", "INV_Stone_12",
            "INV_Ingot_Platinum", "INV_Ore_Platinum_01", "INV_Ore_Iron_01",
            "INV_Ingot_Mithril",
        },
    }, {
        ["c1"] = "orange",
        ["c2"] = "blue",
        ["c3"] = "yellow",
        ["c4"] = "purple",
        ["c6"] = "green",
        ["c7"] = "meta",
}, 20260911)
ns.RegisterShelfData("breaker", "ecnh",
    "theme.enchanting", {
        ["c1"] = {
            "INV_Enchant_EssenceEternalSmall", "INV_Enchant_EssenceEternalLarge", "INV_Enchant_AbyssCrystal",
            "INV_Enchant_ShardGleamingSmall", "INV_Enchant_ShardPrismaticSmall", "INV_Enchant_EssenceMagicLarge",
        },
        ["c2"] = {
            "INV_Enchant_DustArcane", "INV_Enchant_ShardNexusLarge", "INV_Enchant_EssenceMysticalLarge",
            "INV_Enchant_EssenceArcaneLarge",
        },
        ["c3"] = {
            "INV_Enchant_ShardBrilliantLarge", "INV_Enchant_ShardBrilliantSmall",
        },
        ["c4"] = {
            "INV_Enchant_EssenceAstralLarge", "INV_Enchant_EssenceAstralSmall", "INV_Enchant_ShardRadientLarge",
        },
        ["c5"] = {
            "INV_Enchant_DustStrange", "INV_Enchant_EssenceNetherLarge", "INV_Enchant_EssenceNetherSmall",
        },
        ["c6"] = {
            "INV_Enchant_DustDream", "INV_Enchant_DreamShard_01", "INV_Enchant_DreamShard_02",
            "INV_Enchant_ShardGlowingLarge", "INV_Enchant_ShardPrismaticLarge",
        },
    }, {
        ["c1"] = "blue",
        ["c2"] = "red",
        ["c3"] = "yellow",
        ["c4"] = "orange",
        ["c5"] = "green",
        ["c6"] = "meta",
}, 20260911)
ns.RegisterShelfData("breaker", "alch",
    "theme.alchemy", {
        ["c1"] = {
            "INV_Potion_156", "INV_Potion_74",
            "INV_Potion_75", "INV_Potion_76", "INV_Potion_168",
            "INV_Potion_137", "INV_Alchemy_Elixir_02", "INV_Potion_126",
            "INV_Potion_72", "INV_Potion_04", "INV_Potion_20",
            "INV_Misc_Herb_IceCap",
        },
        ["c2"] = {
            "INV_Potion_53", "INV_Potion_24", "INV_Potion_120",
            "INV_Alchemy_Elixir_05", "INV_Potion_54", "INV_Potion_21",
            "INV_Potion_167", "INV_Potion_142", "INV_Alchemy_Potion_02",
            "INV_Jewelry_Talisman_03", "INV_Misc_Herb_TalandrasRose", "INV_Misc_Herb_Tigerlily",
        },
        ["c3"] = {
            "INV_Potion_61", "INV_Potion_165", "INV_Potion_58",
            "INV_Potion_147", "INV_Potion_60", "INV_Potion_31",
            "INV_Alchemy_Elixir_01", "INV_Potion_125", "INV_Potion_26",
            "INV_Misc_Flower_01", "INV_Misc_Herb_18",
            "INV_Misc_Herb_Dreamingglory",
        },
        ["c4"] = {
            "INV_Misc_Herb_FelLotus", "INV_Misc_Herb_Felweed", "INV_Misc_Herb_EvergreenMoss",
            "INV_Potion_127", "INV_Potion_22", "INV_Potion_95",
            "INV_Potion_138", "INV_Potion_12", "INV_Potion_155",
            "INV_Potion_96", "INV_Potion_93", "INV_Potion_162",
            "INV_Alchemy_EndlessFlask_03", "INV_Potion_97",
        },
        ["c5"] = {
            "INV_Potion_48", "INV_Alchemy_EndlessFlask_05", "INV_Potion_30",
            "INV_Alchemy_Potion_04", "INV_Potion_46", "INV_Potion_158",
            "INV_Potion_145", "INV_Potion_09", "INV_Alchemy_Elixir_06",
            "INV_Potion_134", "INV_Potion_44", "INV_Potion_25",
            "INV_Potion_110", "INV_Misc_Herb_13", "INV_Misc_Herb_PlagueBloom",
        },
    }, {
        ["c1"] = "blue",
        ["c2"] = "red",
        ["c3"] = "yellow",
        ["c4"] = "green",
        ["c5"] = "purple",
}, 20260911)
ns.RegisterShelfData("breaker", "gems",
    "theme.gems", {
        ["c1"] = {
            "INV_Jewelcrafting_CrimsonSpinel_02", "INV_Jewelcrafting_LivingRuby_03",
            "INV_Misc_Gem_Ruby_01", "INV_Jewelcrafting_Gem_04", "INV_Misc_Gem_Ruby_02",
            "inv_jewelcrafting_dragonseye05",
        },
        ["c2"] = {
            "INV_Jewelcrafting_EmpyreanSapphire_02", "INV_Jewelcrafting_StarOfElune_03",
            "INV_Jewelcrafting_Gem_24", "INV_Jewelcrafting_Gem_05", "inv_jewelcrafting_dragonseye04",
        },
        ["c3"] = {
            "INV_Jewelcrafting_Lionseye_02", "INV_Jewelcrafting_Dawnstone_03",
            "INV_Jewelcrafting_Gem_21", "INV_Jewelcrafting_Gem_03", "INV_Misc_Gem_Topaz_02",
            "INV_Misc_Gem_Topaz_01", "inv_jewelcrafting_dragonseye03",
        },
        ["c4"] = {
            "INV_Jewelcrafting_SeasprayEmerald_02", "INV_Jewelcrafting_Talasite_03",
            "INV_Jewelcrafting_Gem_19", "INV_Jewelcrafting_Gem_01", "INV_Misc_Gem_Emerald_02",
        },
        ["c5"] = {
            "INV_Jewelcrafting_ShadowsongAmethyst_02", "INV_Jewelcrafting_Nightseye_03",
            "INV_Jewelcrafting_Gem_23", "INV_Jewelcrafting_Gem_06", "INV_Jewelcrafting_ShadowSpirit_01",
        },
        ["c6"] = {
            "INV_Jewelcrafting_Pyrestone_02", "INV_Jewelcrafting_NobleTopaz_03",
            "INV_Jewelcrafting_Gem_20", "INV_Misc_Gem_FlameSpessarite_02", "INV_Jewelcrafting_Gem_02",
        },
        ["c7"] = {
            "INV_Misc_Gem_Pearl_02", "INV_Misc_Gem_Pearl_03",
        },
    }, {
        ["c1"] = "red",
        ["c2"] = "blue",
        ["c3"] = "yellow",
        ["c4"] = "green",
        ["c5"] = "purple",
        ["c6"] = "orange",
        ["c7"] = "prismatic",
}, 20260911)
ns.RegisterShelfData("breaker", "cloth",
    "theme.cloth", {
        ["c1"] = {
            "INV_Fabric_Frostweave_Bolt", "INV_Fabric_Frostweave_ImbuedBolt",
            "INV_Fabric_Soulcloth_Bolt", "INV_Fabric_Soulcloth",
        },
        ["c2"] = {
            "INV_Fabric_Netherweave_Bolt_Imbued",
        },
        ["c3"] = {
            "INV_Fabric_Netherweave_Bolt", "INV_Fabric_Netherweave",
            "INV_Fabric_Silk_03", "INV_Fabric_Silk_01", "INV_Fabric_Silk_02",
        },
        ["c4"] = {
            "INV_Fabric_Spellweave", "INV_Fabric_Spellfire", "INV_Fabric_Linen_02",
        },
        ["c5"] = {
            "INV_Fabric_Wool_01", "INV_Fabric_Wool_02", "INV_Fabric_Linen_01",
        },
        ["c6"] = {
            "INV_Fabric_Moonshroud", "INV_Fabric_MoonRag_01", "INV_Fabric_MoonRag_02",
            "INV_Fabric_MoonRag_Primal", "INV_Fabric_Mageweave_01",
            "INV_Fabric_Mageweave_02", "INV_Fabric_Mageweave_03",
        },
    }, {
        ["c1"] = "blue",
        ["c2"] = "purple",
        ["c3"] = "red",
        ["c4"] = "orange",
        ["c5"] = "yellow",
        ["c6"] = "meta",
}, 20260911)
ns.RegisterShelfData("breaker", "bijou",
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
        ["c7"] = {
            "INV_Bijou_Silver", "INV_Bijou_Bronze",
        },
    }, {
        ["c1"] = "red",
        ["c2"] = "blue",
        ["c3"] = "yellow",
        ["c4"] = "purple",
        ["c5"] = "orange",
        ["c6"] = "green",
        ["c7"] = "prismatic",
}, 20260911)
