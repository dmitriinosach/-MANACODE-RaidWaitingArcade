local ADDON, ns = ...
ns.RegisterShelves("snake", {
    label = "Змейка",
    shelves = {
        { key = "food", label = "Еда" },
    },
})
ns.RegisterShelfData("snake", "base",
    "theme.base", {
        ["food"] = {
            "INV_Misc_Food_62", "INV_Misc_Food_153_Doughnut", "INV_Misc_Food_25",
            "INV_Misc_Food_20", "INV_ValentinesChocolate01", "INV_Misc_Food_93_SkethylBerries",
            "INV_Misc_Food_57", "INV_Misc_Food_24", "INV_Misc_Food_22",
            "INV_Misc_Food_19", "INV_Misc_Food_42", "INV_Misc_Food_23",
        },
    }, {
})
