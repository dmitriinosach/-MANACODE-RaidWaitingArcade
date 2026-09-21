local ADDON, ns = ...
ns.RegisterShelves("mines", {
    label = "Сапёр",
    shelves = {
        { key = "bomb", label = "Взрывчатка" },
    },
})
ns.RegisterShelfData("mines", "bombs",
    "theme.bombs", {
        ["bomb"] = {
            "INV_Misc_EngGizmos_31", "INV_Misc_Bomb_08", "INV_Gizmo_FelIronBomb",
            "INV_Misc_Bomb_02", "INV_Misc_Bomb_01", "INV_Misc_Bomb_07",
        },
})
