local ADDON, ns = ...
ns.RegisterShelves("apothecary", {
    label = "Аптекарь",
    shelves = {
        { key = "b1",  label = "Вид 1 — красный" },
        { key = "b2",  label = "Вид 2 — голубой" },
        { key = "b3",  label = "Вид 3 — янтарный" },
        { key = "b4",  label = "Вид 4 — зелёный" },
        { key = "b5",  label = "Вид 5 — фиолетовый" },
        { key = "b6",  label = "Вид 6 — оранжевый" },
        { key = "b7",  label = "Вид 7 — бирюзовый" },
        { key = "b8",  label = "Вид 8 — розовый" },
        { key = "b9",  label = "Вид 9 — жёлтый" },
        { key = "b10", label = "Вид 10 — синий" },
        { key = "b11", label = "Вид 11 — салатовый" },
        { key = "b12", label = "Вид 12 — коричневый" },
    },
})
ns.RegisterShelfData("apothecary", "herbs",
    "theme.herbs", {
        ["b1"] = {
            "INV_Jewelry_Talisman_03", "INV_Misc_Herb_19", "INV_Misc_Herb_16",
        },
        ["b2"] = {
            "INV_Misc_Herb_Whispervine", "INV_Misc_Herb_Flamecap", "INV_Misc_Herb_DreamFoil",
        },
        ["b3"] = {
            "INV_Misc_Herb_15", "INV_Misc_Herb_Dreamingglory",
        },
        ["b4"] = {
            "INV_Misc_Herb_04", "INV_Misc_Herb_11", "INV_Misc_Herb_10",
            "INV_Misc_Herb_08",
        },
        ["b5"] = {
            "INV_Misc_Herb_13", "INV_Misc_Herb_PlagueBloom",
        },
        ["b6"] = {
            "INV_Misc_Herb_Tigerlily",
        },
        ["b7"] = {
            "INV_Misc_Herb_IceThorn", "INV_Misc_Herb_MountainSilverSage",
        },
        ["b8"] = {
            "INV_Misc_Herb_TalandrasRose",
        },
        ["b9"] = {
            "INV_Misc_Herb_GoldClover",
        },
        ["b10"] = {
            "INV_Misc_Herb_IceCap",
        },
        ["b11"] = {
            "INV_Misc_Herb_Terrocone",
        },
        ["b12"] = {
            "INV_Misc_Herb_ConstrictorGrass",
        },
    }, {
})
