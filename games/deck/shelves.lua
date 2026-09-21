local ADDON, ns = ...
ns.RegisterShelves("deck", {
    label = "Колода",
    shelves = {
        { key = "s1",   label = "Масть: черва" },
        { key = "s2",   label = "Масть: бубна" },
        { key = "s3",   label = "Масть: пика" },
        { key = "s4",   label = "Масть: треф" },
        { key = "back", label = "Рубашка" },
    },
})
ns.RegisterShelfData("deck", "base",
    "theme.base", {
        ["s1"] = {
        },
        ["s2"] = {
        },
        ["s3"] = {
        },
        ["s4"] = {
        },
        ["back"] = {
            "Interface\\Glues\\LoadingScreens\\LoadScreenDeathKnight#0.4604,0.8220,0.2764,0.7850",
            "Interface\\LFGFrame\\LFGIcon-AzjolNerub",
            "Interface\\LFGFrame\\LFGIcon-Ahnkalet",
            "Interface\\LFGFrame\\LFGICON-AQTEMPLE",
            "Interface\\LFGFrame\\LFGIcon-ArgentRaid",
            "Interface\\LFGFrame\\LFGICON-BLACKFATHOMDEEPS",
        },
    }, {
})
