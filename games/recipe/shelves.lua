local ADDON, ns = ...
ns.RegisterShelves("recipe", {
    label = "Рецепт",
    shelves = {
        { key = "reagent", label = "Реагенты" },
    },
})
ns.RegisterShelfData("recipe", "base",
    "theme.base", {
        ["reagent"] = {
            "INV_Misc_Gem_Ruby_01", "INV_Misc_Gem_Pearl_03", "INV_Misc_Herb_13",
            "INV_Misc_Herb_Flamecap", "INV_Misc_Root_02", "INV_Misc_Flower_01",
            "INV_Misc_Herb_07", "INV_Misc_Herb_03", "INV_Misc_Root_01",
            "INV_Misc_Herb_Nightmarevine", "INV_Misc_Herb_PlagueBloom", "INV_Misc_Herb_DreamFoil",
            "INV_Misc_Herb_16", "INV_Misc_Herb_17", "INV_Misc_Herb_14",
            "INV_Misc_Herb_18", "INV_Misc_Herb_19", "INV_Misc_Herb_08",
            "INV_Misc_Herb_12", "INV_Misc_Herb_01", "INV_Misc_Herb_11",
            "INV_Misc_Herb_04", "INV_Jewelry_Talisman_03", "INV_Misc_Flower_02",
            "INV_Misc_Herb_10", "INV_Misc_Herb_MountainSilverSage", "INV_Misc_Herb_IceCap",
            "INV_Misc_Herb_15", "INV_Misc_Flower_03", "INV_Mushroom_08",
            "INV_Misc_Herb_SansamRoot", "INV_Misc_Herb_GoldClover", "INV_Misc_Herb_TalandrasRose",
            "INV_Misc_Herb_Ragveil", "INV_Misc_Herb_Felweed", "INV_Misc_Herb_EvergreenMoss",
            "INV_Misc_Herb_Terrocone", "INV_MISC_HERB_ANCIENTLICHEN", "INV_Misc_Herb_Netherbloom",
            "INV_Misc_Herb_ConstrictorGrass", "INV_Misc_Herb_Tigerlily", "INV_Misc_Herb_FrostLotus",
            "INV_Misc_Herb_BlackLotus", "INV_Misc_Herb_Whispervine", "INV_Misc_Herb_IceThorn",
            "INV_Misc_Herb_Dreamingglory", "INV_Misc_Herb_FelLotus", "INV_Misc_Herb_Manathistle",
            "INV_Potion_04", "INV_Potion_07", "INV_Potion_41",
            "INV_Potion_49", "INV_Potion_51", "INV_Potion_25",
            "INV_Potion_34", "INV_Potion_44", "INV_Potion_108",
            "INV_Potion_06", "INV_Potion_20", "INV_Potion_156",
            "INV_Potion_144", "INV_Potion_13", "INV_Potion_31",
            "INV_Potion_18", "INV_Potion_33", "INV_Potion_05",
            "INV_Misc_Herb_06", "INV_Drink_Waterskin_02", "INV_Misc_Powder_Purple",
            "INV_Mushroom_01", "INV_Mushroom_04", "INV_Misc_Food_109_HoneyLichen",
            "INV_Misc_MonsterScales_02", "INV_Misc_MonsterScales_11", "INV_Elemental_Primal_Water",
            "INV_Elemental_Eternal_Earth", "INV_Elemental_Eternal_Fire", "INV_Misc_Slime_01",
            "INV_Elemental_Eternal_Shadow", "INV_Elemental_Eternal_Life", "INV_Enchant_DustStrange",
            "INV_SummerFest_FireFlower", "Spell_Nature_ElementalShields", "INV_Potion_98",
            "INV_Potion_103", "INV_Jewelcrafting_CrimsonHare", "INV_Jewelcrafting_JadeOwl",
            "INV_Jewelcrafting_BlackPearlPanther", "INV_Jewelcrafting_EmeraldBoar", "INV_Jewelcrafting_GoldenCrab",
            "INV_Jewelcrafting_RubySerpent", "INV_Potion_68",
        },
    }, {
})
