local ADDON, ns = ...
ns.Sfx = {}
ns.Sounds = {}
local BS = string.char(92)
local NAMES = {
    hover  = "UChatScrollButton",
    pop    = "igMainMenuOptionCheckBoxOn",
    big    = "igSpellBookOpen",
    clear  = "ReadyCheck",
    over   = "igQuestLogOpen",
    pick   = "igCharacterInfoTab",
    deny   = "igPlayerInviteDecline",
    stuck  = "igQuestFailed",
}
ns.Sfx.keyOrder = { "start", "hover", "pick", "slide", "pop", "big", "clear",
                    "deny", "stuck", "turn", "over" }
ns.Sfx.keyLabel = {
    start = "партия началась",
    turn  = "твой ход",
    hover = "под курсором",
    pick  = "фишка выбрана",
    slide = "фишка сдвинулась",
    pop   = "снятие группы",
    big   = "крупная группа или серия",
    clear = "поле вычищено",
    deny  = "так нельзя",
    stuck = "тупик: ходов нет",
    over  = "партия окончена",
}
ns.Sfx.gameLabel = {
    ["deck"] = {
        hover = "курсор на карте",
        pick  = "карту взяли в руку",
        pop   = "карту положили",
        big   = "карта ушла в дом или собрался ряд",
        clear = "пасьянс сошёлся",
        deny  = "так нельзя: карта не ложится",
        over  = "партия окончена",
    },
    ["gems"] = {
        pick  = "камень выбран",
        pop   = "линия снята",
        big   = "сработал особый камень или пошёл каскад",
        clear = "заказ сдан, уровень пройден",
        deny  = "так нельзя: обмен без линии, порода, оправа",
        over  = "партия окончена",
    },
    ["invaders"] = {
        shotfire = "выстрел огненным шаром",
        shotarrow = "выстрел стрелой",
        shotshadow = "выстрел тенью",
        shotaxe = "бросок топора",
        shotlaser = "выстрел лазером",
        shotbolt = "выстрел молнией",
        gun = "подобрано оружие",
        pop = "подобран бонус",
        pick = "способность оружия",
        hit = "корабль потерял жизнь",
        deny = "оберег погасил удар",
        big = "серия, дирижабль или змей",
        boss = "босс побеждён",
        rage = "босс в ярости",
        warn = "способность босса",
        start = "пришла новая волна",
        clear = "волна зачищена",
        over = "партия окончена",
    },
    ["arkanoid"] = {
        start = "мяч пущен с платформы",
        turn  = "мяч отбит платформой",
        hover = "мяч отскочил от стенки или золота",
        pick  = "капсула поймана",
        pop   = "кирпич разбит",
        big   = "мультибол или удар грозы",
        clear = "уровень вычищен",
        deny  = "мяч улетел вниз",
        stuck = "застрявший мяч возвращён",
        over  = "партия окончена",
    },
    ["snake"] = {
        pop   = "змея съела еду",
        clear = "поле заполнено, победа",
        deny  = "разворот назад нельзя",
        over  = "змея врезалась, конец",
    },
    ["mines"] = {
        pick  = "флажок поставлен",
        pop   = "клетка вскрыта",
        big   = "вскрыт каскад клеток",
        clear = "поле разминировано",
        over  = "мина подорвана",
    },
    ["merge"] = {
        pop   = "плитки осели после сдвига",
        clear = "впервые взята новая ступень лестницы",
    },
    ["chess"] = {
        start = "партия началась",
        pick  = "фигуру подняли с клетки",
        pop   = "фигуру поставили",
        big   = "фигуру съели",
        turn  = "соперник сходил, ваш ход",
        deny  = "так нельзя: фигура туда не ходит",
        over  = "партия окончена: мат, пат или сдача",
    },
    ["tetris"] = {
        pick  = "фигура повернулась",
        pop   = "фигура легла",
        big   = "четыре строки разом",
        clear = "строка стёрта",
        over  = "стакан переполнен",
    },
    ["sudoku"] = {
        pick  = "цифра взята в руку",
        pop   = "ход по полю принят",
        clear = "поле досчитано, победа",
    },
    ["tower"] = {
        pop   = "обычная посадка этажа",
        big   = "посадка пиксель в пиксель (золотой поясок)",
        deny  = "бросок мимо: этаж не удержался, попытка потеряна",
        stuck = "обрушение: несколько этажей осыпались",
        over  = "все попытки потрачены, партия окончена",
        clear = "здание достроено до цели",
    },
    ["stack"] = {
        start = "смена началась",
        pick  = "рабочий прыгнул",
        turn  = "кран отпустил ящик",
        slide = "рабочий сдвинул ящик",
        pop   = "ящик лёг в штабель",
        big   = "снято два ряда разом и больше",
        clear = "ряд собран и снят",
        deny  = "прыгать некуда: над головой ящик",
        stuck = "склад забит: крану некуда целиться",
        over  = "рабочего придавило ящиком",
        hover = "бонус подобран",
    },
}
local DECK = "deck"
ns.Sfx.deckLabel = "Колода"
local function playsDeck(game)
    local def = (ns.games or {})[game or ""]
    return (def and def.deck) and true or false
end
function ns.Sfx.Label(game, key)
    if type(key) ~= "string" then return "" end
    local own = (ns.Sfx.gameLabel[game or ""] or {})[key]
    return own or ns.Sfx.keyLabel[key] or key
end
local BAKED = {
    ["deck"] = {
        ["pick"]  = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PickUpParchment_Paper.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownParchment_Paper.wav",
        ["deny"]  = "Sound" .. BS .. "Interface" .. BS .. "PlaceHolder.wav",
        ["big"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownRing.wav",
        ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "LevelUp.wav",
        ["over"]  = "Sound" .. BS .. "Interface" .. BS .. "GuildVaultClose.wav",
        ["hover"] = "Sound" .. BS .. "Interface" .. BS .. "MouseOverTarget.wav",
    },
    ["invaders"] = {
        ["shotfire"]    = "sound" .. BS .. "spells" .. BS .. "wandfirecast1.wav",
        ["shotarrow"]   = "Sound" .. BS .. "Item" .. BS .. "Weapons" .. BS .. "Bow" .. BS .. "BowRelease.wav",
        ["shotshadow"]  = "Sound" .. BS .. "Spells" .. BS .. "ShootWandLaunchShadow.wav",
        ["shotaxe"]     = "Sound" .. BS .. "Item" .. BS .. "Weapons" .. BS .. "WeaponSwings" .. BS .. "mWooshMedium1.wav",
        ["shotlaser"]   = "Sound" .. BS .. "Spells" .. BS .. "ShootWandLaunchArcane.wav",
        ["shotbolt"]    = "Sound" .. BS .. "Spells" .. BS .. "ShootWandLaunchLightning.wav",
        ["gun"]         = "Sound" .. BS .. "interface" .. BS .. "UnsheathShield.wav",
        ["pop"]         = "Sound" .. BS .. "Interface" .. BS .. "LootCoinLarge.wav",
        ["pick"]        = "Sound" .. BS .. "Spells" .. BS .. "FieBlast_Blue_ImpactA.wav",
        ["hit"]         = "Sound" .. BS .. "Item" .. BS .. "Weapons" .. BS .. "Axe1H" .. BS .. "m1hAxeHitMetalShield1a.wav",
        ["deny"]        = "Sound" .. BS .. "Spells" .. BS .. "AbsorbGetHitA.wav",
        ["big"]         = "Sound" .. BS .. "Spells" .. BS .. "Hunter_ExplosiveShotImpact1.wav",
        ["boss"]        = "Sound" .. BS .. "Interface" .. BS .. "LevelUp.wav",
        ["rage"]        = "Sound" .. BS .. "Spells" .. BS .. "ChallengingRoar.wav",
        ["warn"]        = "Sound" .. BS .. "interface" .. BS .. "RaidWarning.wav",
        ["start"]       = "Sound" .. BS .. "interface" .. BS .. "PVPFlagTakenMono.wav",
        ["clear"]       = "Sound" .. BS .. "Interface" .. BS .. "ReadyCheck.wav",
        ["over"]        = "Sound" .. BS .. "interface" .. BS .. "igQuestFailed.wav",
    },
    ["apothecary"] = {
        ["big"]   = "Sound" .. BS .. "Doodad" .. BS .. "BE_MagicalKnickKnack04Water.wav",
        ["clear"] = "Sound" .. BS .. "interface" .. BS .. "uMiniMapClose.wav",
        ["deny"]  = "Sound" .. BS .. "interface" .. BS .. "SheathShield.wav",
        ["hover"] = "Sound" .. BS .. "Interface" .. BS .. "MouseOverTarget.wav",
        ["pick"]  = "Sound" .. BS .. "Interface" .. BS .. "MouseOverTarget.wav",
        ["pop"]   = "Sound" .. BS .. "Doodad" .. BS .. "BE_MagicalKnickKnack04Water.wav",
    },
    ["stack"] = {
        ["start"] = "Sound" .. BS .. "Doodad" .. BS .. "DeadmineSteamWhistleOn.wav",
        ["hover"] = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PickUpGems.wav",
        ["pick"]  = "Sound" .. BS .. "Character" .. BS .. "Footsteps" .. BS .. "mFootSmallWoodA.wav",
        ["slide"] = "Sound" .. BS .. "interface" .. BS .. "SheathWood.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownWoodLarge.wav",
        ["big"]   = "Sound" .. BS .. "Interface" .. BS .. "LevelUp.wav",
        ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorCreate.wav",
        ["deny"]  = "Sound" .. BS .. "Interface" .. BS .. "PlaceHolder.wav",
        ["stuck"] = "Sound" .. BS .. "Doodad" .. BS .. "GnomereganElevatorStop.wav",
        ["turn"]  = "sound" .. BS .. "doodad" .. BS .. "icecrown_lever_close.wav",
        ["over"]  = "Sound" .. BS .. "Effects" .. BS .. "DeathImpacts" .. BS .. "mDeathImpactMediumWoodA.wav",
    },
    ["sudoku"] = {
        ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MinorCreate.wav",
        ["pick"]  = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownFoodGeneric.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownFoodGeneric.wav",
    },
    ["snake"] = {
        ["clear"] = "Sound" .. BS .. "interface" .. BS .. "iQuestComplete.wav",
        ["deny"]  = "Sound" .. BS .. "Interface" .. BS .. "PlaceHolder.wav",
        ["over"]  = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorDestroy.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "iEating1.wav",
    },
    ["recipe"] = {
        ["over"] = "Sound" .. BS .. "Interface" .. BS .. "AlarmClockWarning2.wav",
        ["pick"] = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PickUpHerb.wav",
        ["pop"]  = "Sound" .. BS .. "Spells" .. BS .. "ThrowWater.wav",
    },
    ["slide"] = {
        ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorCreate.wav",
        ["hover"] = "Sound" .. BS .. "Interface" .. BS .. "MouseOverTarget.wav",
        ["pick"]  = "Sound" .. BS .. "Item" .. BS .. "Weapons" .. BS .. "WeaponSwings" .. BS .. "mWooshSmall1.wav",
    },
    ["tetris"] = {
        ["big"]   = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorDestroy.wav",
        ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorDestroy.wav",
        ["over"]  = "Sound" .. BS .. "interface" .. BS .. "iQuestUpdate.wav",
        ["pick"]  = "Sound" .. BS .. "Item" .. BS .. "Weapons" .. BS .. "WeaponSwings" .. BS .. "mWooshSmall1.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownFoodGeneric.wav",
    },
    ["mines"] = {
        ["big"]   = "Sound" .. BS .. "Character" .. BS .. "Footsteps" .. BS .. "mFootSmallStoneA.wav",
        ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MinorCreate.wav",
        ["over"]  = "Sound" .. BS .. "Doodad" .. BS .. "Cannon01_BlastA.wav",
        ["pick"]  = "Sound" .. BS .. "interface" .. BS .. "uMiniMapClose.wav",
        ["pop"]   = "Sound" .. BS .. "Character" .. BS .. "Footsteps" .. BS .. "mFootSmallStoneA.wav",
    },
    ["gems"] = {
        ["pick"]  = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PickUpGems.wav",
        ["pop"]   = "Sound" .. BS .. "Creature" .. BS .. "Horse" .. BS .. "mFootStepsHorseStone01.wav",
        ["big"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownGems.wav",
        ["clear"] = "Sound" .. BS .. "interface" .. BS .. "JewelcraftingFinalize.wav",
        ["deny"]  = "Sound" .. BS .. "interface" .. BS .. "iDeselectTarget.wav",
        ["over"]  = "Sound" .. BS .. "interface" .. BS .. "KeyRingClose.wav",
    },
    ["breaker"] = {
        ["big"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownGems.wav",
        ["clear"] = "Sound" .. BS .. "interface" .. BS .. "uMiniMapClose.wav",
        ["over"]  = "Sound" .. BS .. "interface" .. BS .. "JewelcraftingFinalize.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownRing.wav",
        themes = {
            ["cloth"] = {
                ["big"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PickUpCloth_Leather01.wav",
                ["clear"] = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownBag.wav",
                ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownCloth_Leather01.wav",
            },
            ["enge"] = {
                ["big"]   = "Sound" .. BS .. "Doodad" .. BS .. "ID_Forge_Zap01.wav",
                ["clear"] = "Sound" .. BS .. "Doodad" .. BS .. "G_GnomeMultiBoxOpen.wav",
                ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownSmallMEtal.wav",
            },
            ["bm"] = {
                ["big"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownLArgeMEtal.wav",
                ["clear"] = "Sound" .. BS .. "Doodad" .. BS .. "UL_Forge_Iron_PressOneShot1.wav",
                ["pop"]   = "Sound" .. BS .. "Doodad" .. BS .. "DalaranForgeArmsHammer1.wav",
            },
            ["ecnh"] = {
                ["big"]   = "Sound" .. BS .. "Interface" .. BS .. "MagicClick.wav",
                ["clear"] = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorCreate.wav",
                ["pop"]   = "Sound" .. BS .. "Spells" .. BS .. "ShootWandLaunchArcane.wav",
            },
            ["alch"] = {
                ["big"]   = "Sound" .. BS .. "Doodad" .. BS .. "BE_MagicalKnickKnack04Water.wav",
                ["clear"] = "Sound" .. BS .. "Spells" .. BS .. "Tradeskills" .. BS .. "AlchemyCompleteA.wav",
                ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownWater_Liquid01.wav",
            },
        },
    },
    ["arkanoid"] = {
        ["turn"]  = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownWoodLarge.wav",
        ["pop"]   = "Sound" .. BS .. "Creature" .. BS .. "Horse" .. BS .. "mFootStepsHorseStone01.wav",
        ["hover"] = "Sound" .. BS .. "Character" .. BS .. "Footsteps" .. BS .. "MediumLargeMetalFootsteps" .. BS .. "MediumLargeFootstepMetal_01.wav",
        ["pick"]  = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PickUpGems.wav",
        ["start"] = "Sound" .. BS .. "Item" .. BS .. "Weapons" .. BS .. "Bow" .. BS .. "BowRelease.wav",
        ["big"]   = "Sound" .. BS .. "Spells" .. BS .. "ShootWandLaunchLightning.wav",
        ["clear"] = "Sound" .. BS .. "Spells" .. BS .. "Tradeskills" .. BS .. "BlackSmithCompleteA.wav",
        ["deny"]  = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorDestroy.wav",
        ["stuck"] = "Sound" .. BS .. "interface" .. BS .. "uSpellIconPickup.wav",
        ["over"]  = "Sound" .. BS .. "interface" .. BS .. "igQuestFailed.wav",
    },
    ["pairs"] = {
        ["clear"] = "Sound" .. BS .. "interface" .. BS .. "AuctionWindowOpen.wav",
        ["deny"]  = "Sound" .. BS .. "interface" .. BS .. "uMiniMapClose.wav",
        ["pick"]  = "Sound" .. BS .. "Interface" .. BS .. "MouseOverTarget.wav",
        ["pop"]   = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MajorCreate.wav",
        ["over"]  = "Sound" .. BS .. "interface" .. BS .. "AuctionWindowClose.wav",
    },
    ["jump"] = {
        ["pop"]  = "Sound" .. BS .. "Character" .. BS .. "Footsteps" .. BS .. "mFootSmallStoneA.wav",
        ["big"]  = "Sound" .. BS .. "Doodad" .. BS .. "BellowOut.wav",
        ["over"] = "Sound" .. BS .. "Interface" .. BS .. "AlarmClockWarning3.wav",
    },
    ["merge"] = {
        ["clear"] = "Sound" .. BS .. "Spells" .. BS .. "ThrowWater.wav",
        ["pop"]   = "Sound" .. BS .. "interface" .. BS .. "uMiniMapClose.wav",
    },
    ["chess"] = {
        ["big"]  = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MinorCreate.wav",
        ["deny"] = "Sound" .. BS .. "interface" .. BS .. "SheathWood.wav",
        ["over"] = "Sound" .. BS .. "interface" .. BS .. "AuctionWindowOpen.wav",
        ["pick"] = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownFoodGeneric.wav",
        ["pop"]  = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownFoodGeneric.wav",
        ["turn"] = "Sound" .. BS .. "Interface" .. BS .. "AchievementMenuOpen.wav",
    },
    ["checkers"] = {
        ["pick"] = "Sound" .. BS .. "interface" .. BS .. "PickUp" .. BS .. "PutDownFoodGeneric.wav",
        ["pop"]  = "Sound" .. BS .. "Interface" .. BS .. "Glyph_MinorCreate.wav",
        ["deny"] = "Sound" .. BS .. "interface" .. BS .. "SheathWood.wav",
        ["over"] = "Sound" .. BS .. "interface" .. BS .. "AuctionWindowOpen.wav",
        ["turn"] = "Sound" .. BS .. "Interface" .. BS .. "AchievementMenuOpen.wav",
    },
}
function ns.Sounds.Sets()
    local out = {}
    for _, key in ipairs(ns.soundsOrder or {}) do
        local s = (ns.soundsSets or {})[key]
        if s then
            out[#out + 1] = { key = key, label = s.label or key,
                              n = #((ns.soundsDB or {})[key] or {}) }
        end
    end
    return out
end
function ns.Sounds.List(key)
    return (ns.soundsDB or {})[key or ""] or {}
end
local index, indexSet
local function build()
    if index then return end
    index, indexSet = {}, {}
    for _, key in ipairs(ns.soundsOrder or {}) do
        for _, e in ipairs(ns.Sounds.List(key)) do
            local low = e.p:lower()
            index[low] = e
            indexSet[low] = key
            for i, p in ipairs(e.vp or {}) do
                local vlow = p:lower()
                if not index[vlow] then
                    index[vlow] = { s = e.s .. " " .. (i + 1), p = p, ms = e.ms,
                                    v = e.v, vi = i + 1, of = e }
                    indexSet[vlow] = key
                end
            end
        end
    end
end
function ns.Sounds.Find(ref)
    if type(ref) ~= "string" or ref == "" then return nil end
    build()
    local low = ref:lower()
    return index[low], indexSet[low]
end
function ns.Sounds.Label(ref)
    local e = ns.Sounds.Find(ref)
    if e then return e.s end
    if type(ref) == "string" then return ref end
    return ""
end
ns.Sfx.LEVELS = { 0.2, 0.35, 0.6, 1 }
function ns.Sfx.Volume()
    return ns.Store.Num(ns.Store.DB().sfxVol, 0.1, 1, 1)
end
local MASTER = "Sound_MasterVolume"
local LIFTED = { "Sound_MusicVolume", "Sound_SFXVolume", "Sound_AmbienceVolume" }
local base
local shown = false
local function cvarNum(name)
    return tonumber(GetCVar(name) or "") or 1
end
local function apply()
    local k = ns.Sfx.Volume()
    SetCVar(MASTER, tostring(base[MASTER] * k))
    for _, name in ipairs(LIFTED) do
        local up = base[name] / k
        if up > 1 then up = 1 end
        SetCVar(name, tostring(up))
    end
end
function ns.Sfx.Undock()
    if not base then return end
    for name, v in pairs(base) do SetCVar(name, tostring(v)) end
    base = nil
    ns.Store.DB().sfxDuck = nil
end
function ns.Sfx.Release()
    shown = false
    ns.Sfx.Undock()
end
function ns.Sfx.Duck()
    shown = true
    if type(SetCVar) ~= "function" or type(GetCVar) ~= "function" then return end
    if base or ns.Sfx.Volume() >= 1 then return end
    base = { [MASTER] = cvarNum(MASTER) }
    for _, name in ipairs(LIFTED) do base[name] = cvarNum(name) end
    ns.Store.DB().sfxDuck = base
    apply()
end
function ns.Sfx.SetVolume(v)
    ns.Store.DB().sfxVol = ns.Store.Num(v, 0.1, 1, 1)
    ns.Sfx.Undock()
    if shown then ns.Sfx.Duck() end
end
function ns.Sfx.Rebase(name, v)
    if not (base and base[name]) then return false end
    base[name] = v
    ns.Store.DB().sfxDuck = base
    apply()
    return true
end
function ns.Sfx.BaseOf(name)
    return base and base[name] or nil
end
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGOUT")
loader:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGOUT" then
        ns.Sfx.Undock()
        return
    end
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    local left = ns.Store.DB().sfxDuck
    if type(left) == "table" and type(SetCVar) == "function" then
        for cv, v in pairs(left) do SetCVar(cv, tostring(v)) end
    end
    ns.Store.DB().sfxDuck = nil
end)
local function emit(ref)
    if type(ref) ~= "string" or ref == "" then return false end
    local e = ns.Sounds.Find(ref)
    if e then
        if e.ps and not e.v and ns.Sfx.Volume() >= 1 then
            PlaySound(e.s)
        else
            PlaySoundFile(e.p)
        end
        return true
    end
    if ref:find(BS, 1, true) then PlaySoundFile(ref) else PlaySound(ref) end
    return true
end
function ns.Sounds.Play(ref)
    return emit(ref)
end
local UI_CLICK = {
    press    = "GAMEABILITYBUTTONMOUSEDOWN",
    tick     = "GAMEABILITYBUTTONMOUSEDOWN",
    open     = "INTERFACESOUND_CHARWINDOWTAB",
    checkOn  = "igMainMenuOptionCheckBoxOn",
    checkOff = "igMainMenuOptionCheckBoxOff",
    deny     = "Error",
}
function ns.Sfx.Ui(kind)
    if not ns.Store.Sound() then return end
    emit(UI_CLICK[kind or "press"])
end
function ns.Sounds.Muted()
    if type(GetCVar) ~= "function" then return nil end
    if GetCVar("Sound_EnableAllSound") == "0" then return "звук выключен в самом клиенте" end
    if GetCVar("Sound_EnableSFX") == "0" then return "эффекты выключены в самом клиенте" end
    local v = tonumber(GetCVar("Sound_MasterVolume") or "")
    if v and v <= 0 then return "общая громкость клиента на нуле" end
    v = tonumber(GetCVar("Sound_SFXVolume") or "")
    if v and v <= 0 then return "громкость эффектов на нуле" end
    return nil
end
local function store()
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    if type(db) ~= "table" then return {} end
    db.sfx = db.sfx or {}
    return db.sfx
end
local function themeStore()
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    if type(db) ~= "table" then return {} end
    db.sfxTheme = db.sfxTheme or {}
    return db.sfxTheme
end
function ns.Sfx.ThemeOf(game)
    if type(game) ~= "string" then return nil end
    local sh = ns.Shelves
    if not (sh and sh.Theme and sh.Themes) then return nil end
    if #sh.Themes(game) < 2 then return nil end
    return sh.Theme(game)
end
function ns.Sfx.Games()
    local out = { { id = DECK, label = ns.Sfx.deckLabel, keys = ns.Sfx.Events(DECK) } }
    for _, def in ipairs(ns.gameOrder or {}) do
        out[#out + 1] = { id = def.id, label = def.label or def.id,
                          keys = ns.Sfx.Events(def.id) }
    end
    return out
end
local rank = {}
for i, key in ipairs(ns.Sfx.keyOrder) do rank[key] = i end
function ns.Sfx.Events(game)
    local own = (ns.soundsEvents or {})[game or ""]
    if not (own and #own > 0) then return ns.Sfx.keyOrder end
    local out = {}
    for i = 1, #own do out[i] = own[i] end
    table.sort(out, function(a, b)
        local ra, rb = rank[a] or 99, rank[b] or 99
        if ra == rb then return a < b end
        return ra < rb
    end)
    return out
end
function ns.Sfx.Get(game, key)
    if type(game) ~= "string" or type(key) ~= "string" then return nil, "none" end
    local theme = ns.Sfx.ThemeOf(game)
    if theme then
        local tb = themeStore()[game]
        local mineT = tb and tb[theme] and tb[theme][key]
        if type(mineT) == "string" and mineT ~= "" then return mineT, "theme" end
        local bk = BAKED[game] and BAKED[game].themes
        local cookedT = bk and bk[theme] and bk[theme][key]
        if type(cookedT) == "string" and cookedT ~= "" then return cookedT, "themeBaked" end
    end
    local box = store()[game]
    local mine = box and box[key]
    if type(mine) == "string" and mine ~= "" then return mine, "own" end
    local cooked = (BAKED[game] or {})[key]
    if type(cooked) == "string" and cooked ~= "" then return cooked, "baked" end
    if game ~= DECK and playsDeck(game) then
        local deckBox = store()[DECK]
        local deckOwn = deckBox and deckBox[key]
        if type(deckOwn) == "string" and deckOwn ~= "" then return deckOwn, "deck" end
        local deckBaked = (BAKED[DECK] or {})[key]
        if type(deckBaked) == "string" and deckBaked ~= "" then return deckBaked, "deck" end
    end
    return nil, "none"
end
function ns.Sfx.Set(game, key, ref)
    if type(game) ~= "string" or type(key) ~= "string" then return false end
    if type(ref) ~= "string" then return false end
    ref = ref:match("^%s*(.-)%s*$")
    if ref == "" then return false end
    if not ns.Sounds.Find(ref) then return false end
    local box = store()
    box[game] = box[game] or {}
    box[game][key] = ref
    return true
end
function ns.Sfx.Audit()
    local out = {}
    local function look(box, where)
        for game, keys in pairs(box or {}) do
            if type(keys) == "table" then
                for key, ref in pairs(keys) do
                    if type(ref) == "string" and ref ~= "" and not ns.Sounds.Find(ref) then
                        out[#out + 1] = { game = game, key = key, ref = ref, from = where }
                    elseif key == "themes" and type(ref) == "table" then
                        for theme, tk in pairs(ref) do
                            look({ [game .. "/" .. theme] = tk }, where)
                        end
                    end
                end
            end
        end
    end
    look(BAKED, "baked")
    look(store(), "own")
    for game, themes in pairs(themeStore()) do
        for theme, keys in pairs(themes) do
            look({ [game .. "/" .. theme] = keys }, "theme")
        end
    end
    return out
end
function ns.Sfx.Clear(game, key)
    local box = store()[game]
    if box then box[key] = nil end
end
function ns.Sfx.SetTheme(game, key, ref)
    local theme = ns.Sfx.ThemeOf(game)
    if not theme or type(key) ~= "string" or type(ref) ~= "string" then return false end
    ref = ref:match("^%s*(.-)%s*$")
    if ref == "" or not ns.Sounds.Find(ref) then return false end
    local box = themeStore()
    box[game] = box[game] or {}
    box[game][theme] = box[game][theme] or {}
    box[game][theme][key] = ref
    return true
end
function ns.Sfx.ClearTheme(game, key)
    local theme = ns.Sfx.ThemeOf(game)
    local box = theme and themeStore()[game]
    box = box and box[theme]
    if box then box[key] = nil end
end
function ns.Sfx.Common(key)
    return NAMES[key or ""]
end
function ns.Sfx.Count(game)
    local box = store()[game or ""]
    if not box then return 0 end
    local n = 0
    for _ in pairs(box) do n = n + 1 end
    return n
end
local function currentGame()
    local inst = ns.Loop and ns.Loop.Current and ns.Loop.Current()
    local def = inst and inst.def
    return def and def.id or nil
end
local HOVER_GAP = 0.12
local lastHover = 0
local function tuning()
    return (ns.SoundsUI and ns.SoundsUI.IsShown and ns.SoundsUI.IsShown()) and true or false
end
function ns.Sfx.Play(key)
    if not (ns.Store.Sound() or tuning()) then return end
    if type(key) ~= "string" then return end
    if key == "hover" then
        local now = GetTime()
        if now - lastHover < HOVER_GAP then return end
        lastHover = now
    end
    local ref = ns.Sfx.Get(currentGame(), key)
    if ref then emit(ref) end
end
SLASH_HTPARCADESFX1 = "/arcsfx"
SlashCmdList["HTPARCADESFX"] = function(msg)
    local what = msg and msg:match("^%s*(.-)%s*$") or ""
    if what == "" then
        local list = {}
        for k, v in pairs(NAMES) do list[#list + 1] = k .. " = " .. v end
        table.sort(list)
        ns.say("общий словарь: " .. table.concat(list, ", "))
        ns.say("послушать любой: /arcsfx ИмяЗвука.")
        local lost = ns.Sfx.Audit()
        for _, r in ipairs(lost) do
            ns.say(("назначение мимо пула: %s, %s -> %s"):format(r.game, r.key, r.ref))
        end
        return
    end
    emit(what)
    ns.say("сыграл: " .. what)
end
