local ADDON, ns = ...
ns.RegisterShelves("arkanoid", {
    label = "Арканоид",
    shelves = {
        { key = "brick",        label = "Осколки кирпича" },
        { key = "bonus_wide",   label = "Бонус: платформа шире", role = "fixed" },
        { key = "bonus_multi",  label = "Бонус: мультибол",      role = "fixed" },
        { key = "bonus_sticky", label = "Бонус: липучка",        role = "fixed" },
    },
})
