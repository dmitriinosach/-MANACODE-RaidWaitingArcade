local ADDON, ns = ...
ns.slideShelf = {
    sets = {
        { key = "screen", label = "slide.setScreen", squeeze = 4 / 3 },
        { key = "lfg",    label = "slide.setLfg" },
        { key = "sign",   label = "slide.setSign" },
        { key = "talent", label = "slide.setTalent" },
    },
    menu = { set = "screen", file = "LoadScreenNorthrend" },
}
