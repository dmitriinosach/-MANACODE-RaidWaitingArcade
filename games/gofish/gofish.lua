local ADDON, ns = ...
local ID = "gofish"
local DECK = "deck"
local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local HAND_SIZE = 7
local DECK_N = 52
local RANK_N = 13
local GOALS = {
    { key = 1, goal = 5,  label = "gofish.goalRace", tip = "gofish.goalRaceTip" },
    { key = 2, goal = 13, label = "gofish.goalFull", tip = "gofish.goalFullTip" },
}
local MODE = { CARD = "card", SET = "azeroth" }
local FACE_OPTIONS = {
    { key = MODE.CARD, label = "gofish.faceCardLabel", tip = "gofish.faceCardTip" },
    { key = MODE.SET,  label = "gofish.faceSetLabel",  tip = "gofish.faceSetTip" },
}
local SIGN_DIR = "Interface\\LFGFrame\\"
local TALENT_DIR = "Interface\\TalentFrame\\"
local SCREEN_DIR = "Interface\\Glues\\LoadingScreens\\"
local SET_CARDS = {
    { pic = SIGN_DIR .. "LFGICON-SERPENTSHRINECAVERN", name = "gofish.setVashj" },
    { pic = TALENT_DIR .. "HunterPetCunning-TopLeft", name = "gofish.setSerpent" },
    { pic = SIGN_DIR .. "LFGICON-SHADOWFANGKEEP", name = "gofish.setWorgen" },
    { pic = SIGN_DIR .. "LFGICON-GRUULSLAIR", name = "gofish.setGruul" },
    { pic = TALENT_DIR .. "WarlockCurses-TopLeft", name = "gofish.setCurse" },
    { pic = SIGN_DIR .. "LFGICON-HELLFIRECITADELRAID", name = "gofish.setMagtheridon" },
    { pic = SIGN_DIR .. "LFGICON-BATTLEGROUND", name = "gofish.setThrall" },
    { pic = SIGN_DIR .. "LFGIcon-TheForgeofSouls", name = "gofish.setForge" },
    { pic = SIGN_DIR .. "LFGICON-SUNWELL", name = "gofish.setKiljaeden" },
    { pic = TALENT_DIR .. "WarriorProtection-TopLeft", name = "gofish.setCastle" },
    { pic = SIGN_DIR .. "LFGICON-BLACKTEMPLE", name = "gofish.setIllidan" },
    { pic = SCREEN_DIR .. "LoadScreenNetherBattlegrounds#0.6600,0.9800,0.1700,0.6260", name = "gofish.setKael" },
    { pic = SCREEN_DIR .. "LoadScreenNorthrend#0.0000,0.3000,0.0600,0.4900", name = "gofish.setArthas" },
}
local LVL = {
    X = 309, W = 172, H = 22, Y = 20, STEP = 26, CAP_Y = 100,
    LIST = {
        { key = 1, label = "gofish.lvlNaive", tip = "gofish.lvlNaiveTip",
          can = { spread = true, shy = true } },
        { key = 2, label = "gofish.lvlMemo",  tip = "gofish.lvlMemoTip",
          can = { memo = true, fresh = true } },
        { key = 3, label = "gofish.lvlCount", tip = "gofish.lvlCountTip",
          can = { memo = true, fresh = true, count = true, tally = true } },
    },
}
local BOT_DELAY = 0.8
local END_FLASH = 0.8
local function rankName(self, r, many)
    if self.face == MODE.SET and SET_CARDS[r] then return ns.T(SET_CARDS[r].name) end
    return ns.DeckRankName(r, many)
end
local function rankOf(card)
    return (card - 1) % RANK_N + 1
end
local function suitOf(card)
    return floor((card - 1) / RANK_N) + 1
end
local function countRank(hand, rank)
    local n = 0
    for i = 1, #hand do
        if rankOf(hand[i]) == rank then n = n + 1 end
    end
    return n
end
local function handHasRank(hand, rank)
    return countRank(hand, rank) > 0
end
local function takeAllOfRank(hand, rank)
    local out, keep = {}, {}
    for i = 1, #hand do
        local c = hand[i]
        if rankOf(c) == rank then out[#out + 1] = c else keep[#keep + 1] = c end
    end
    for i = #hand, 1, -1 do hand[i] = nil end
    for i = 1, #keep do hand[i] = keep[i] end
    return out
end
local function ownRanks(hand)
    local seen, list = {}, {}
    for i = 1, #hand do
        local r = rankOf(hand[i])
        if not seen[r] then
            seen[r] = true
            list[#list + 1] = r
        end
    end
    return list
end
local function drawCard(self, who)
    if self.deckPos > DECK_N then return nil end
    local c = self.deck[self.deckPos]
    self.deckPos = self.deckPos + 1
    if who == 1 then self.drawn = self.drawn + 1 end
    return c
end
local function checkEnd(self, silent)
    if self.over then return end
    local goal = self.goal or GOALS[1].goal
    local race = self.books[1] >= goal or self.books[2] >= goal
    if race or (self.deckPos > DECK_N and (#self.hand[1] == 0 or #self.hand[2] == 0)) then
        self.over = true
        self.overT = 0
        if not silent then
            ns.Sfx.Play("over")
            ns.Config.Set(ID, "played", (ns.Config.Get(ID, "played", 0) or 0) + 1)
        end
    end
end
local function ensureHand(self, who, silent)
    local hand = self.hand[who]
    if #hand == 0 and self.deckPos <= DECK_N then
        hand[1] = drawCard(self, who)
    end
    checkEnd(self, silent)
end
local function checkBook(self, who, rank, silent)
    local hand = self.hand[who]
    if countRank(hand, rank) >= 4 then
        takeAllOfRank(hand, rank)
        self.books[who] = self.books[who] + 1
        self.bookRanks[who][#self.bookRanks[who] + 1] = rank
        self.known[rank] = nil
        self.owe[rank] = 0
        return true
    end
    return false
end
local function askResolve(self, asker, rank, silent)
    local opp = 3 - asker
    local got = takeAllOfRank(self.hand[opp], rank)
    local result = { rank = rank, got = #got, cards = got, drew = false,
                     drewMatch = false, again = false, book = nil }
    if asker == 1 and (self.owe[rank] or 0) < 1 then self.owe[rank] = 1 end
    if #got > 0 then
        local h = self.hand[asker]
        for i = 1, #got do h[#h + 1] = got[i] end
        if asker == 1 then
            self.owe[rank] = (self.owe[rank] or 0) + #got
        else
            self.owe[rank] = 0
        end
        result.again = true
        if not silent then ns.Sfx.Play("pick") end
        if checkBook(self, asker, rank, silent) then result.book = rank end
    else
        if not silent then ns.Sfx.Play("deny") end
        local card = drawCard(self, asker)
        if card then
            result.drew = true
            result.card = card
            local h = self.hand[asker]
            h[#h + 1] = card
            local cardRank = rankOf(card)
            if cardRank == rank then
                result.drewMatch = true
                result.again = true
            end
            if checkBook(self, asker, cardRank, silent) then result.book = cardRank end
        end
    end
    if asker == 2 then
        self.known[rank] = nil
        self.denyAge[rank] = self.drawn
    else
        self.known[rank] = true
        self.denyAge[rank] = nil
    end
    checkEnd(self, silent)
    return result
end
local function botCan(self)
    local lv = LVL.LIST[self.level]
    return (lv and lv.can) or {}
end
local function denyCost(self, r, can)
    local at = self.denyAge[r]
    if not at then return 0 end
    local d = self.drawn - at
    if d <= 0 then return 1000 end
    if can.fresh and d <= 2 then return 11 end
    return 0
end
local function botPickRank(self)
    local hand = self.hand[2]
    local can = botCan(self)
    local own = ownRanks(hand)
    local free = {}
    for i = 1, #own do
        if denyCost(self, own[i], can) < 1000 then free[#free + 1] = own[i] end
    end
    if #free > 0 then own = free end
    local best, pick = nil, {}
    for i = 1, #own do
        local r = own[i]
        local s = -denyCost(self, r, can)
        if can.memo and self.known[r] then
            s = s + 60 + (can.tally and (self.owe[r] or 1) * 20 or 40)
        end
        if can.count then s = s + countRank(hand, r) * 10 end
        if can.spread then s = s - countRank(hand, r) * 10 end
        if can.shy and self.known[r] then s = s - 50 end
        if best == nil or s > best then
            best, pick = s, { r }
        elseif s == best then
            pick[#pick + 1] = r
        end
    end
    return self.rng:Pick(pick)
end
local function botTakeTurn(self, silent)
    ensureHand(self, 2, silent)
    if self.over then return nil end
    local rank = botPickRank(self)
    if not rank then
        self.over = true
        return nil
    end
    local result = askResolve(self, 2, rank, silent)
    result.who = 2
    self.last = result
    if not result.again then self.turn = 1 end
    return result
end
local function apply(self, move, silent)
    if type(move) ~= "table" or move.k ~= "ask" then return false end
    if self.over then return false end
    local rank = move.v
    if type(rank) ~= "number" or rank < 1 or rank > RANK_N then return false end
    local side = self.turn
    if not self.net and side ~= 1 then return false end
    if not handHasRank(self.hand[side], rank) then return false end
    local result = askResolve(self, side, rank, silent)
    result.who = side
    self.last = result
    if not result.again then self.turn = 3 - side end
    return true
end
local CW, CH = 640, 480
local TABLE_Y0, TABLE_Y1 = 106, 254
local CHAR_SC = 1.3
local CHAR_X, CHAR_Y, CHAR_W, CHAR_H = 133, 221, 288, 202
local PLAYER_CW, PLAYER_CH, PLAYER_Y = 72, 101, 4
local BOT = { CW = 46, CH = 64, Y = 250 }
local PILE = { X = 470, Y = 152, MX = 505, MY = 156 }
local LIE = { W = 84, D = 34, DEPTH = 60, SKEW = 0.5, DY = 3, MAX = 5, GLOW = 3, MARGIN = 3, SIDE_ROW = 2 }
local FACE = { CW = 54, CH = 76, Y = 14, XS = { 77, 141 }, LIFT = 4, CX = 136 }
local MENU_BTN = { X = 504, W = 200, H = 24, PLAY_Y = 46, CALL_Y = 20, NOTE_Y = 100 }
local GOAL_BTN = { W = 96, H = 22, Y = 72, XS = { 452, 556 } }
local CAP_Y = 100
local NICHE = { W = 44, H = 32, STEP = 46, FONT = 15, X = 16, XR = 624, MY_Y = 128, OP_Y = 214,
                BIG = { 44, 32, 46, 15 }, SMALL = { 30, 22, 32, 11 } }
local BUB_MINE = { W = 252, H = 88, X = 16, Y = 162 }
local BUB_FOE = { W = 200, H = 110, X = 436, Y = 326 }
local NOTE = { Y = 470, Y0 = 460, H = 19, PAD = 24,
               PARCH = { 0.86, 0.78, 0.60 }, HI = { 0.93, 0.87, 0.72 },
               EDGE = { 0.36, 0.25, 0.12 }, INK = { 0.20, 0.12, 0.05 },
               HOT = { 0.52, 0.26, 0.02 },
               DARK = { 0.16, 0.12, 0.08 }, GOLD = { 0.92, 0.84, 0.52 },
               GOLD2 = { 0.86, 0.70, 0.36 }, TAIL = { 18, 12, 6 } }
NOTE.RINGS = { { 1, NOTE.DARK }, { 2, NOTE.GOLD }, { 1, NOTE.GOLD2 }, { 1, NOTE.EDGE } }
NOTE.THIN = { { 1, NOTE.DARK }, { 1, NOTE.GOLD2 } }
local HAND_STACK_ROOM = 4
local MARK_INSET, INDEX_W = 3, 20
local BACK_EMBLEM = "INV_Box_01"
local FAN_MIN_STEP = MARK_INSET + INDEX_W + 6
local BOT_FAN_SPAN, BOT_FAN_X, BOT_FAN_STEP = 250, 195, 14
local FX = { LIFT = 0.18, BUBBLE = 0.15, THINK = 0.45, ANSWER = 1.00, FLY = 0.55, HOLD = 0.75,
             CHEST = 1.20, DROP = 0.25, LIFT_UP = 10 }
FX.BOOK_SHOW = 0.45
FX.BOOK_FLY = 0.50
FX.ROW_X = 300
FX.ROW_Y = 180
FX.ROW_GAP = 4
FX.LEN = FX.ANSWER + FX.FLY + FX.HOLD
FX.WAIT = 4.0
FX.ASK = 0.55
FX.ASK_WAIT = 2.6
local SAID_HOLD = 2.0
local RAGE_T = 3.0
local YOU_ASK = { "gofish.youAskFmt", "gofish.youAsk2Fmt", "gofish.youAsk3Fmt" }
local YOU_DENY = { "gofish.youDeny", "gofish.youDeny2", "gofish.youDeny3",
                   "gofish.youDeny4", "gofish.youDeny5" }
local YOU_DREW = { "gofish.youDrewMatchFmt", "gofish.youDrew2Fmt", "gofish.youDrew3Fmt" }
local INK_BUB_TEXT = NOTE.INK
local INK_BUB_CAP  = NOTE.HOT
local INK_SHADOW   = { 0, 0, 0 }
local LOOK_WOOD = { 0.230, 0.190, 0.130 }
local LOOK_EDGE = { 1, 0.82, 0 }
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE }
local CHEST_MINE = {
    body = { 0.478, 0.290, 0.133 }, dark = { 0.298, 0.173, 0.071 },
    lid  = { 0.557, 0.353, 0.169 }, lite = { 0.690, 0.463, 0.227 },
    band = { 0.851, 0.643, 0.255 }, text = { 0.165, 0.102, 0.039 },
}
local CHEST_OPP = {
    body = { 0.224, 0.255, 0.310 }, dark = { 0.137, 0.161, 0.208 },
    lid  = { 0.271, 0.306, 0.369 }, lite = { 0.353, 0.392, 0.455 },
    band = { 0.624, 0.659, 0.722 }, text = { 0.055, 0.071, 0.098 },
}
local function newInk(frame)
    return { f = frame, n = 0, t = {} }
end
local function ink(p, x, y, w, h, c, a, layer)
    if w <= 0 or h <= 0 then return end
    p.n = p.n + 1
    local t = p.t[p.n]
    if not t then
        t = p.f:CreateTexture(nil, layer or "ARTWORK")
        p.t[p.n] = t
    end
    t:SetDrawLayer(layer or "ARTWORK")
    t:ClearAllPoints()
    t:SetPoint("BOTTOMLEFT", p.f, "BOTTOMLEFT", x, y)
    t:SetWidth(w)
    t:SetHeight(h)
    ns.Paint(t, c[1], c[2], c[3], a or 1)
    t:Show()
end
local function inkTex(p, x, y, w, h, path, l, r, t, b, layer)
    if w <= 0 or h <= 0 then return end
    p.n = p.n + 1
    local tx = p.t[p.n]
    if not tx then
        tx = p.f:CreateTexture(nil, layer or "ARTWORK")
        p.t[p.n] = tx
    end
    tx:SetDrawLayer(layer or "ARTWORK")
    tx:ClearAllPoints()
    tx:SetPoint("BOTTOMLEFT", p.f, "BOTTOMLEFT", x, y)
    tx:SetWidth(w)
    tx:SetHeight(h)
    tx:SetTexture(path)
    tx:SetTexCoord(l, r, t, b)
    tx:Show()
end
local function inkDone(p)
    for i = p.n + 1, #p.t do p.t[i]:Hide() end
    p.n = 0
end
local root, pool
local cardBase
local game
local sceneF, charF, planeF, faceF, tableF, chestF, bubbleF, handF, menuF
local sceneInk, tableInk, chestInk, bubInk, handInk, faceInk, planeInk
local liveInk, deckInk, glowInk
local deckKey
local bub, plate, deckNote, deckCount, menuUI, chestFS
local backIcon
local suitIcon = {}
local courtIcon = {}
local foe, room
local function markBox(f, size, inset)
    f.mark:ClearAllPoints()
    f.mark:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
    f.mark:SetWidth(size)
    f.mark:SetHeight(size)
end
local function atLevel(f, i)
    f:SetFrameLevel(root:GetFrameLevel() + cardBase + i * 2)
end
local function bubbleAbove(lvl)
    local want = root:GetFrameLevel() + cardBase + (lvl + 2) * 2
    if want > 124 then want = 124 end
    if bubbleF:GetFrameLevel() ~= want then bubbleF:SetFrameLevel(want) end
end
local function fanXs(n, cw)
    return ns.DeckFan(n, {
        w = cw, span = CW - 24 * 2, x = 24,
        gap = 6, minStep = FAN_MIN_STEP,
    })
end
local function botFanXs(n)
    return ns.DeckFan(n, {
        w = BOT.CW, span = BOT_FAN_SPAN, x = BOT_FAN_X,
        gap = 4, minStep = BOT_FAN_STEP,
    })
end
local function paintRoom()
    local p = sceneInk
    for i = 1, #room.bands do
        local b = room.bands[i]
        local y0 = b[1]
        local y1 = (room.bands[i + 1] and room.bands[i + 1][1]) or CH
        ink(p, 0, y0, CW, y1 - y0, { b[2], b[3], b[4] }, nil, "BACKGROUND")
    end
    for i = 0, 9 do
        ink(p, i * 64 + 26, TABLE_Y1, 12, CH - TABLE_Y1, room.stripe, 0.35, "BACKGROUND")
    end
    for i = 1, #room.props do
        local r = room.props[i]
        ink(p, r[1], r[2], r[3], r[4], { r[5], r[6], r[7] }, r[8], "BORDER")
    end
    inkDone(p)
end
local function paintTable()
    local p = tableInk
    ink(p, 0, TABLE_Y0, CW, TABLE_Y1 - TABLE_Y0, room.felt, nil, "BACKGROUND")
    ink(p, 0, TABLE_Y1 - 14, CW, 8, room.feltHi, 0.5, "BORDER")
    ink(p, 0, TABLE_Y1 - 6, CW, 6, room.edge, nil, "BORDER")
    ink(p, 0, TABLE_Y0, CW, 12, room.near, nil, "BORDER")
    ink(p, 0, TABLE_Y0 + 12, CW, 3, room.edge, 0.6, "BORDER")
    inkDone(p)
end
local function paintLive(t)
    local p = liveInk
    if room.live == "lamps" then
        local step = floor(t * 2)
        for i = 0, 10 do
            local on = ((step + i) % 3 == 0)
            ink(p, 20 + i * 60, 436, 6, 6,
                on and { 0.949, 0.824, 0.294 } or { 0.478, 0.353, 0.125 }, nil, "ARTWORK")
        end
    elseif room.live == "water" then
        for i = 0, 5 do
            local y = 318 + i * 24 + ((t * 8 + i * 7) % 16)
            ink(p, 0, y, CW, 2, { 0.561, 0.839, 0.753 }, 0.10, "ARTWORK")
        end
    elseif room.live == "snow" then
        for i = 0, 13 do
            local x = (i * 61 + 17) % CW
            local y = 448 - ((t * 22 + i * 37) % 142)
            ink(p, x, y, 3, 3, { 0.776, 0.863, 0.933 }, 0.55, "ARTWORK")
        end
    end
    inkDone(p)
end
local function paintChar()
    for i = 1, #planeInk do planeInk[i].n = 0 end
    local LAYER = { "BACKGROUND", "BORDER", "ARTWORK", "OVERLAY", "HIGHLIGHT" }
    for i = 1, #foe.parts do
        local r = foe.parts[i]
        local p = planeInk[r[6]] or planeInk[1]
        ink(p, r[1], r[2], r[3], r[4], foe.pal[r[5]], nil, LAYER[r[7]])
    end
    for i = 1, #planeInk do inkDone(planeInk[i]) end
end
local function roundInk(p, x, y, w, h, c, a, layer, r)
    if r * 2 >= w or r * 2 >= h or r < 1 then
        ink(p, x, y, w, h, c, a, layer)
        return
    end
    ink(p, x, y + r, w, h - 2 * r, c, a, layer)
    ink(p, x + r, y, w - 2 * r, r, c, a, layer)
    ink(p, x + r, y + h - r, w - 2 * r, r, c, a, layer)
end
local function eyeRound(w, h)
    local r = floor(min(w, h) * 0.22)
    if r > 8 then r = 8 end
    return r
end
local function paintEye(p, box, mood, blink)
    local pal, kind = foe.pal, foe.ink
    local x, y, w, h = box[1], box[2], box[3], box[4]
    local r = eyeRound(w, h)
    if foe.glow then
        local lit = 0.75
        if mood == "glad" or mood == "smug" then lit = 1
        elseif mood == "sad" then lit = 0.45 end
        if blink then lit = 0.15 end
        roundInk(p, x - 3, y - 3, w + 6, h + 6, pal[kind.accent], 0.18 * lit, "ARTWORK", r + 2)
        roundInk(p, x, y, w, h, pal[kind.accent], lit, "OVERLAY", r)
        roundInk(p, x + 2, y + 2, w - 4, h - 4, pal[kind.pupil], lit, "HIGHLIGHT", max(1, r - 1))
        return
    end
    roundInk(p, x - 2, y - 2, w + 4, h + 4, pal[1], nil, "ARTWORK", r + 2)
    if blink then
        ink(p, x, y + h / 2 - 2, w, 4, pal[kind.skin], nil, "OVERLAY")
        return
    end
    roundInk(p, x, y, w, h, pal[kind.white], nil, "OVERLAY", r)
    local pw, ph = floor(w * 0.42), floor(h * 0.5)
    local px, py = x + w / 2 - pw / 2, y + h / 2 - ph / 2
    if mood == "think" then px = px - w * 0.16; py = py + h * 0.18 end
    if mood == "sad" then py = py - h * 0.18 end
    roundInk(p, px, py, pw, ph, pal[kind.pupil], nil, "HIGHLIGHT", max(1, floor(r * 0.6)))
    if mood == "angry" then
        ink(p, x - 3, y + h - 3, w + 6, 5, pal[1], nil, "OVERLAY")
    elseif foe.brows or mood == "think" then
        local by = (mood == "think") and (y + h + 1) or (y + h + 4)
        ink(p, x - 2, by, w + 4, 4, pal[1], nil, "OVERLAY")
    end
    if mood == "smug" then
        ink(p, x - 2, y + h / 2, w + 4, h / 2 + 4, pal[kind.skin], nil, "HIGHLIGHT")
    end
end
local function paintMouth(p, mood)
    local pal, kind = foe.pal, foe.ink
    if mood == "angry" then mood = "sad" end
    if not foe.mouth then
        local b = foe.breath or { 102, 56, 56, 25 }
        local pf = 0.35
        if mood == "think" then pf = 1 elseif mood == "sad" then pf = 0.7 end
        ink(p, b[1] + b[3] * 0.43, b[2] + b[4] * 0.8, b[3] * 0.54, 5, pal[kind.mouth], 0.42 * pf, "OVERLAY")
        ink(p, b[1] + b[3] * 0.21, b[2] + b[4] * 0.4, b[3] * 0.79, 5, pal[kind.mouth], 0.30 * pf, "OVERLAY")
        ink(p, b[1], b[2], b[3], 4, pal[kind.mouth], 0.20 * pf, "OVERLAY")
        return
    end
    local m = foe.mouth
    local x, y, w, h = m[1], m[2], m[3], m[4]
    if foe.wideMouth and (mood == "idle" or mood == "think") then
        ink(p, x, y, w, h * 0.6, pal[1], nil, "OVERLAY")
        ink(p, x + 2, y + 2, w - 4, h * 0.6 - 4, pal[kind.mouth], nil, "HIGHLIGHT")
        ink(p, x + 5, y + h * 0.6 - 7, w - 10, 4, pal[kind.teeth], nil, "HIGHLIGHT")
        return
    end
    if mood == "idle" or mood == "think" then
        ink(p, x + w * 0.12, y + h * 0.34, w * 0.76, 5, pal[1], nil, "OVERLAY")
        ink(p, x + w * 0.06, y + h * 0.52, w * 0.10, 5, pal[1], nil, "OVERLAY")
        ink(p, x + w * 0.84, y + h * 0.52, w * 0.10, 5, pal[1], nil, "OVERLAY")
        if foe.fang then
            ink(p, x + w * 0.22, y + h * 0.34 - 7, 7, 7, pal[kind.teeth], nil, "HIGHLIGHT")
        end
        if mood == "think" then
            ink(p, x + w * 0.60, y + h * 0.34, w * 0.28, 5, pal[kind.skin], nil, "HIGHLIGHT")
        end
        return
    end
    if mood == "sad" then
        ink(p, x + w * 0.20, y + h * 0.35, w * 0.6, 4, pal[1], nil, "OVERLAY")
        ink(p, x + w * 0.12, y + h * 0.55, w * 0.12, 4, pal[1], nil, "OVERLAY")
        ink(p, x + w * 0.76, y + h * 0.55, w * 0.12, 4, pal[1], nil, "OVERLAY")
        return
    end
    local ww = (mood == "smug" and not foe.wideMouth) and w * 0.6 or w
    local xx = (mood == "smug" and not foe.wideMouth) and (x + w * 0.34) or x
    ink(p, xx, y, ww, h, pal[1], nil, "OVERLAY")
    ink(p, xx + 2, y + 2, ww - 4, h - 4, pal[kind.mouth], nil, "HIGHLIGHT")
    ink(p, xx + 4, y + h - 6, ww - 8, 4, pal[kind.teeth], nil, "HIGHLIGHT")
end
local function paintFace(mood, blink)
    local p = faceInk
    paintEye(p, foe.eyeL, mood, blink)
    paintEye(p, foe.eyeR, mood, blink)
    paintMouth(p, mood)
    if foe.monocle then
        local m, pal = foe.eyeR, foe.pal
        local x, y, w, h = m[1], m[2], m[3], m[4]
        local a = pal[foe.ink.accent]
        ink(p, x - 6, y - 6, w + 12, 4, a, nil, "HIGHLIGHT")
        ink(p, x - 6, y + h + 2, w + 12, 4, a, nil, "HIGHLIGHT")
        ink(p, x - 6, y - 6, 4, h + 12, a, nil, "HIGHLIGHT")
        ink(p, x + w + 2, y - 6, 4, h + 12, a, nil, "HIGHLIGHT")
        ink(p, x - 10, y - 14, 4, 6, a, nil, "HIGHLIGHT")
        ink(p, x - 16, y - 22, 4, 6, a, nil, "HIGHLIGHT")
    end
    inkDone(p)
end
local FINGERS = 4
local function paintHand(p, box, left)
    local pal = foe.pal
    local x, y, w, hh = box[1], box[2], box[3], box[4]
    roundInk(p, x, y, w, hh, pal[1], nil, "BACKGROUND", 5)
    roundInk(p, x + 2, y + 2, w - 4, hh - 4, pal[3], nil, "BORDER", 4)
    local tw = floor(w * 0.30)
    local th = floor(hh * 0.66)
    local tx = left and (x + w - tw - 2) or (x + 2)
    local fx0 = left and (x + 3) or (x + tw + 4)
    local fw = w - tw - 7
    local bh = floor((hh - 6) / FINGERS)
    for k = 0, FINGERS - 2 do
        local by = y + hh - 4 - (k + 1) * bh
        ink(p, fx0, by, fw, 1, foe.handWeb and pal[4] or pal[1], foe.handWeb and 0.7 or nil, "ARTWORK")
        ink(p, fx0 + 1, by + 1, fw - 2, 2, pal[4], 0.55, "ARTWORK")
    end
    if foe.handSteel then
        ink(p, fx0, y + floor(hh * 0.5), fw, 2, pal[4], nil, "ARTWORK")
        ink(p, fx0 + 2, y + hh - 8, 3, 3, pal[4], nil, "ARTWORK")
        ink(p, fx0 + fw - 5, y + hh - 8, 3, 3, pal[4], nil, "ARTWORK")
    end
    roundInk(p, tx - 1, y + 3, tw + 2, th + 2, pal[1], nil, "OVERLAY", 3)
    roundInk(p, tx, y + 4, tw, th, pal[3], nil, "HIGHLIGHT", 3)
end
local function paintHands()
    local p = handInk
    for i = 1, #foe.hands do
        paintHand(p, foe.hands[i], i == 1)
    end
    inkDone(p)
end
local function chestX(i, mine)
    if mine then return NICHE.X + (i - 1) * NICHE.STEP end
    return NICHE.XR - NICHE.W - (i - 1) * NICHE.STEP
end
local function paintChest(p, x, y, mine)
    local c = mine and CHEST_MINE or CHEST_OPP
    local w, h = NICHE.W, NICHE.H
    local body = floor(h * 0.56)
    local band = max(3, floor(w * 0.09))
    local bx = max(3, floor(w * 0.11))
    local lw, lh = max(6, floor(w * 0.18)), max(8, floor(h * 0.31))
    local lx, ly = floor(x + (w - lw) / 2), floor(y + h * 0.37)
    ink(p, x, y, w, h, { 0.078, 0.063, 0.039 }, nil, "BACKGROUND")
    ink(p, x + 1, y + 1, w - 2, body, c.body, nil, "BORDER")
    ink(p, x + 1, y + body, w - 2, h - body - 1, c.lid, nil, "BORDER")
    ink(p, x + 1, y + h - 3, w - 2, 2, c.lite, nil, "ARTWORK")
    ink(p, x + 1, y + body - 2, w - 2, 2, c.dark, nil, "ARTWORK")
    ink(p, x + bx, y + 1, band, h - 2, c.band, nil, "ARTWORK")
    ink(p, x + w - bx - band, y + 1, band, h - 2, c.band, nil, "ARTWORK")
    ink(p, lx, ly, lw, lh, c.band, nil, "OVERLAY")
    ink(p, lx + 2, ly + 3, max(2, lw - 4), max(2, lh - 6), c.dark, nil, "HIGHLIGHT")
end
local function paintBubble(p, x, y, w, h, rings, dir)
    ink(p, x - 2, y - 2, w + 4, h + 4, INK_SHADOW, 0.45, "BACKGROUND")
    local d = 0
    for i = 1, #rings do
        local t, c = rings[i][1], rings[i][2]
        local x0, y0, w0, h0 = x + d, y + d, w - 2 * d, h - 2 * d
        ink(p, x0, y0 + h0 - t, w0, t, c, nil, "BORDER")
        ink(p, x0, y0, w0, t, c, nil, "BORDER")
        ink(p, x0, y0 + t, t, h0 - 2 * t, c, nil, "BORDER")
        ink(p, x0 + w0 - t, y0 + t, t, h0 - 2 * t, c, nil, "BORDER")
        d = d + t
    end
    ink(p, x + d, y + d, w - 2 * d, h - 2 * d, NOTE.PARCH, nil, "BORDER")
    ink(p, x + d + 1, y + h - d - 2, w - 2 * d - 2, 1, NOTE.HI, 0.7, "ARTWORK")
    if not dir then return end
    local STEP = NOTE.TAIL
    local join = d + 1
    if dir == "down" then
        local cx = x + 42
        for i = 1, 3 do
            local sw, sy = STEP[i], y - i * 5
            ink(p, cx - sw / 2 - 2, sy - 2, sw + 4, 7, NOTE.DARK, nil, "BORDER")
            ink(p, cx - sw / 2 - 1, sy - 1, sw + 2, 6, NOTE.GOLD2, nil, "ARTWORK")
            ink(p, cx - sw / 2, sy, sw, 5 + (i == 1 and join or 0), NOTE.PARCH, nil, "OVERLAY")
        end
        local sw = STEP[1]
        ink(p, cx - sw / 2 - 1, y, 1, 1, NOTE.GOLD2, nil, "ARTWORK")
        ink(p, cx + sw / 2, y, 1, 1, NOTE.GOLD2, nil, "ARTWORK")
        return
    end
    local cy = y + h - 30
    for i = 1, 3 do
        local sh, sx = STEP[i], x - i * 5
        ink(p, sx - 2, cy - sh / 2 - 2, 7, sh + 4, NOTE.DARK, nil, "BORDER")
        ink(p, sx - 1, cy - sh / 2 - 1, 6, sh + 2, NOTE.GOLD2, nil, "ARTWORK")
        ink(p, sx, cy - sh / 2, 5 + (i == 1 and join or 0), sh, NOTE.PARCH, nil, "OVERLAY")
    end
    local sh = STEP[1]
    ink(p, x, cy - sh / 2 - 1, 1, 1, NOTE.GOLD2, nil, "ARTWORK")
    ink(p, x, cy + sh / 2, 1, 1, NOTE.GOLD2, nil, "ARTWORK")
end
local function lieRows(p, x, y, w, d, c, a, tex, crop, layer)
    for j = 0, d - 1 do
        local lx = x + LIE.SKEW * j
        if tex and crop then
            local v0 = crop[3] + (crop[4] - crop[3]) * (1 - (j + 1) / d)
            local v1 = crop[3] + (crop[4] - crop[3]) * (1 - j / d)
            inkTex(p, lx, y + j, w, 1, tex, crop[1], crop[2], v0, v1, layer)
        else
            ink(p, lx, y + j, w, 1, c or ns.DECK_EDGE, a, layer)
        end
    end
end
LIE.FACE = { 0.46, 0.11, 0.13 }
LIE.GOLD = { 1, 0.82, 0 }
LIE.PAPER = { 0.80, 0.77, 0.70 }
local function lieLayers(n)
    return min(LIE.MAX, max(1, n))
end
local function paintStack(p, x, y, n, tex)
    local layers = lieLayers(n)
    local edge = ns.DECK_EDGE
    local T = layers * LIE.DY
    local W, D = LIE.W, LIE.D
    ink(p, x + 1, y - 2, W + 2, 2, INK_SHADOW, 0.35, "BACKGROUND")
    ink(p, x - 1, y - 1, W + 2, T + 1, edge, nil, "BACKGROUND")
    for i = 0, layers - 1 do
        ink(p, x, y + i * LIE.DY, W, LIE.DY - 1, LIE.PAPER, nil, "BORDER")
    end
    local rx = x + W
    local r = 0
    while r < D + T do
        local rh = min(LIE.SIDE_ROW, D + T - r)
        local rm = r + rh / 2
        local left = rx + LIE.SKEW * max(0, rm - T)
        local right = rx + LIE.SKEW * min(rm, D)
        if right > left then
            ink(p, left, y + r, right - left + 1, rh, edge, nil, "BACKGROUND")
            ink(p, left, y + r, right - left, rh, LIE.PAPER, nil, "BORDER")
            for i = 1, layers - 1 do
                local lx = rx + LIE.SKEW * (rm - i * LIE.DY)
                if lx > left and lx < right then
                    ink(p, lx, y + r, 1, rh, edge, nil, "ARTWORK")
                end
            end
        end
        r = r + rh
    end
    local top = y + T
    lieRows(p, x - 1, top - 1, W + 2, D + 2, edge, nil, nil, nil, "BACKGROUND")
    lieRows(p, x, top, W, D, LIE.PAPER, nil, nil, nil, "BORDER")
    local m = LIE.MARGIN
    local iw, id = W - 2 * m, D - 2 * m
    local crop = tex and ns.DeckCropCoords(tex, iw, LIE.DEPTH * id / D) or nil
    if crop then
        lieRows(p, x + m + LIE.SKEW * m, top + m, iw, id, nil, nil, tex, crop, "ARTWORK")
    else
        lieRows(p, x + m + LIE.SKEW * m, top + m, iw, id, LIE.FACE, nil, nil, nil, "ARTWORK")
    end
end
local function paintGlow(p, x, y, n, a)
    local g = LIE.GLOW
    local top = y + lieLayers(n) * LIE.DY
    local h = LIE.D + 2 * g
    for j = 0, h - 1 do
        local lx = x - g + LIE.SKEW * (j - g)
        if j < g or j >= h - g then
            ink(p, lx, top - g + j, LIE.W + 2 * g, 1, LIE.GOLD, a, "OVERLAY")
        else
            ink(p, lx, top - g + j, g, 1, LIE.GOLD, a, "OVERLAY")
            ink(p, lx + LIE.W + g, top - g + j, g, 1, LIE.GOLD, a, "OVERLAY")
        end
    end
end
local function ensureView(canvas)
    if root then return end
    root = ns.NewFrame("Frame", nil, canvas)
    root:SetAllPoints()
    root:SetFrameLevel(canvas:GetFrameLevel() + 1)
    root:Hide()
    sceneF = ns.PlainFrame(root, 1)
    sceneF:SetAllPoints()
    sceneInk = newInk(sceneF)
    liveInk = newInk(sceneF)
    charF = ns.NewFrame("Frame", nil, root)
    charF:SetWidth(CHAR_W)
    charF:SetHeight(CHAR_H)
    charF:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", CHAR_X / CHAR_SC, CHAR_Y / CHAR_SC)
    charF:SetScale(CHAR_SC)
    charF:SetFrameLevel(root:GetFrameLevel() + 2)
    local planes = 1
    for i = 1, #ns.GofishChars do
        planes = max(planes, ns.GofishChars[i].planes or 1)
    end
    planeF, planeInk = {}, {}
    for i = 1, planes do
        planeF[i] = ns.PlainFrame(charF, i - 1)
        planeF[i]:SetAllPoints()
        planeInk[i] = newInk(planeF[i])
    end
    faceF = ns.PlainFrame(charF, planes)
    faceF:SetAllPoints()
    faceInk = newInk(faceF)
    local above = 2 + planes + 1
    tableF = ns.PlainFrame(root, above + 1)
    tableF:SetAllPoints()
    tableInk = newInk(tableF)
    chestF = ns.PlainFrame(root, above + 2)
    chestF:SetAllPoints()
    chestInk = newInk(chestF)
    bubbleF = ns.PlainFrame(root, above + 3)
    bubbleF:SetAllPoints()
    bubInk = newInk(bubbleF)
    deckInk = newInk(tableF)
    glowInk = newInk(tableF)
    cardBase = above + 5
    handF = ns.NewFrame("Frame", nil, charF)
    handF:SetAllPoints()
    handF:SetFrameLevel(root:GetFrameLevel() + 44)
    handInk = newInk(handF)
    pool = ns.NewPool(function()
        local f = ns.MakeDeckCard(root)
        ns.DeckCardPaper(f)
        return f
    end, function(f)
        f.rank:SetText("")
        ns.DeckCardRank(f.corner, nil)
        ns.DeckCardSuit(f.mark, nil, nil)
        ns.DeckCardRank(f.corner2, nil)
        ns.DeckCardSuit(f.mark2, nil, nil)
        ns.DeckCardArt(f, nil)
        ns.DeckCardCover(f, false)
    end)
    bub = { panel = ns.PlainFrame(bubbleF, 1) }
    bub.panel:SetWidth(BUB_MINE.W)
    bub.panel:SetHeight(BUB_MINE.H)
    bub.panel:Hide()
    bub.cap = bub.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bub.cap:SetPoint("TOPLEFT", bub.panel, "TOPLEFT", 14, -10)
    bub.text = bub.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bub.text:SetPoint("TOPLEFT", bub.panel, "TOPLEFT", 14, -30)
    bub.text:SetWidth(BUB_MINE.W - 28)
    bub.text:SetJustifyH("LEFT")
    bub.text:SetJustifyV("TOP")
    deckNote = bubbleF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deckNote:SetPoint("CENTER", bubbleF, "BOTTOMLEFT", CW / 2, NOTE.Y)
    deckNote:SetJustifyH("CENTER")
    deckCount = tableF:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    deckCount:SetJustifyH("CENTER")
    plate = bubbleF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    plate:SetPoint("CENTER", bubbleF, "BOTTOMLEFT", CW / 2, TABLE_Y1 + 15)
    menuF = ns.PlainFrame(root, 50)
    menuF:SetAllPoints()
    menuUI = {}
    menuUI.ink = newInk(menuF)
    local function menuText(style, x, y, anchor)
        local fs = menuF:CreateFontString(nil, "OVERLAY", style)
        fs:SetPoint(anchor or "LEFT", menuF, "BOTTOMLEFT", x, y)
        return fs
    end
    menuUI.oppCap  = menuText("GameFontDisableSmall", CW / 2, 206, "CENTER")
    menuUI.oppCap:SetJustifyH("CENTER")
    menuUI.oppName = menuText("GameFontNormalLarge", CW / 2, 186, "CENTER")
    menuUI.oppName:SetJustifyH("CENTER")
    menuUI.oppTip  = menuText("GameFontHighlightSmall", CW / 2, 164, "CENTER")
    menuUI.oppTip:SetWidth(340)
    menuUI.oppTip:SetJustifyH("CENTER")
    menuUI.rec     = menuText("GameFontDisableSmall", CW / 2, 140, "CENTER")
    menuUI.rec:SetJustifyH("CENTER")
    menuUI.note = menuText("GameFontHighlightSmall", MENU_BTN.X, MENU_BTN.NOTE_Y, "CENTER")
    menuUI.note:SetWidth(MENU_BTN.W + 20)
    menuUI.note:SetJustifyH("CENTER")
    menuUI.play = ns.MakeKitButton(menuF)
    menuUI.play:SetWidth(MENU_BTN.W)
    menuUI.play:SetHeight(MENU_BTN.H)
    menuUI.play:SetPoint("CENTER", menuF, "BOTTOMLEFT", MENU_BTN.X, MENU_BTN.PLAY_Y)
    menuUI.call = ns.MakeKitButton(menuF)
    menuUI.call:SetWidth(MENU_BTN.W)
    menuUI.call:SetHeight(MENU_BTN.H)
    menuUI.call:SetPoint("CENTER", menuF, "BOTTOMLEFT", MENU_BTN.X, MENU_BTN.CALL_Y)
    menuUI.faceCap = menuText("GameFontDisableSmall", FACE.CX, CAP_Y, "CENTER")
    menuUI.faceCap:SetJustifyH("CENTER")
    menuUI.lvlCap = menuText("GameFontDisableSmall", LVL.X, CAP_Y, "CENTER")
    menuUI.lvlCap:SetJustifyH("CENTER")
    menuUI.lvl = {}
    for i = 1, #LVL.LIST do
        local b = ns.MakeKitButton(menuF)
        b:SetWidth(LVL.W)
        b:SetHeight(LVL.H)
        b:SetPoint("CENTER", menuF, "BOTTOMLEFT", LVL.X, LVL.Y + (#LVL.LIST - i) * LVL.STEP)
        b.text:SetText(ns.TL(LVL.LIST[i].label))
        b.tip = ns.TL(LVL.LIST[i].tip)
        b.onClick = function() if game then game:PickLevel(i) end end
        menuUI.lvl[i] = b
    end
    menuUI.goal = {}
    for i = 1, #GOALS do
        local b = ns.MakeKitButton(menuF)
        b:SetWidth(GOAL_BTN.W)
        b:SetHeight(GOAL_BTN.H)
        b:SetPoint("CENTER", menuF, "BOTTOMLEFT", GOAL_BTN.XS[i], GOAL_BTN.Y)
        b.text:SetText(ns.TL(GOALS[i].label))
        b.tip = ns.TL(GOALS[i].tip)
        b.onClick = function() if game then game:PickGoal(i) end end
        menuUI.goal[i] = b
    end
    menuF:Hide()
end
local Game = {}
Game.__index = Game
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    self.rng = ns.RNG.New(seed)
    local pick = ns.RNG.New(seed)
    backIcon = ns.Shelves.Pick(DECK, "back", pick)
    for s = 1, 4 do suitIcon[s] = ns.Shelves.Pick(DECK, "s" .. s, pick) end
    local court = ns.Shelves.Get(ID, "court")
    for i = 1, 3 do courtIcon[RANK_N - 3 + i] = court[i] end
    local chars = ns.GofishChars
    foe = chars[pick:Int(#chars)]
    room = foe.room
    self.face = (ns.Store.Skin(ID) == MODE.SET) and MODE.SET or MODE.CARD
    local deck = {}
    for i = 1, DECK_N do deck[i] = i end
    self.rng:Shuffle(deck)
    self.deck = deck
    self.deckPos = 2 * HAND_SIZE + 1
    self.hand = { {}, {} }
    for i = 1, HAND_SIZE do
        self.hand[1][i] = deck[i]
        self.hand[2][i] = deck[HAND_SIZE + i]
    end
    self.books = { 0, 0 }
    self.bookRanks = { {}, {} }
    self.known = {}
    self.owe = {}
    self.denyAge = {}
    self.drawn = 0
    for r = 1, RANK_N do
        checkBook(self, 1, r, true)
        checkBook(self, 2, r, true)
    end
    self.level = ns.Store.Num(ns.Config.Get(ID, "level", 2), 1, #LVL.LIST, 2)
    self.goalKey = ns.Store.Num(ns.Config.Get(ID, "goal", 1), 1, #GOALS, 1)
    self.goal = GOALS[self.goalKey].goal
    local niche = (self.goal > 7) and NICHE.SMALL or NICHE.BIG
    NICHE.W, NICHE.H, NICHE.STEP, NICHE.FONT = niche[1], niche[2], niche[3], niche[4]
    self.turn = 1
    self.over, self.overT = false, nil
    self.botT = 0
    self.last = nil
    self.cardRects = {}
    self.t = 0
    self.fx = nil
    self.blinkT, self.blink = 0, false
    self.faceMood = nil
    self.said = nil
    self.askT = 0
    self.net = ns.Duo.Active()
    self.me = self.net and (ns.Duo.Side() or 1) or 1
    if moves and #moves > 0 then ns.Store.Clear(ID) end
    ensureView(self.canvas)
    game = self
    root:Show()
    deckKey = nil
    self.phase = self.net and "play" or "menu"
    paintRoom()
    paintChar()
    paintTable()
    paintHands()
    charF:SetAlpha(1)
    self:SyncMenu()
    self:Draw()
end
function Game:PickLevel(i)
    if ns.Loop.Current() ~= self then return end
    if i == self.level then return end
    self.level = i
    ns.Config.Set(ID, "level", i)
    self:SyncMenu()
end
function Game:PickGoal(i)
    if ns.Loop.Current() ~= self then return end
    if i == self.goalKey then return end
    self.goalKey = i
    self.goal = GOALS[i].goal
    ns.Config.Set(ID, "goal", i)
    self:SyncMenu()
end
function Game:PickFace(key)
    if ns.Loop.Current() ~= self then return end
    if key ~= MODE.SET then key = MODE.CARD end
    if key == self.face then return end
    self.face = key
    ns.Store.SetSkin(ID, key)
    self:SyncMenu()
    self:Draw()
end
local function targetLine()
    local said = ns.Duo.Status()
    if said then return nil, said, false end
    local name, why = ns.Duo.Target()
    if not name then return nil, ns.T(why or "duoNoTarget"), false end
    ns.Link.Ask(name)
    local state = ns.Link.State(name)
    if state == "yes" then return name, ns.T("gofish.menuReadyFmt", name), true end
    if state == "asking" then return name, ns.T("duoAsking", name), false end
    return name, ns.T("duoSilent", name), false
end
function Game:SyncMenu()
    if not menuF then return end
    if self.phase ~= "menu" then
        menuF:Hide()
        return
    end
    menuF:Show()
    menuUI.oppCap:SetText(ns.T("gofish.menuOpponent"))
    menuUI.oppName:SetText(ns.T(foe.name))
    menuUI.oppTip:SetText(ns.T(foe.tip))
    menuUI.rec:SetText(ns.T("gofish.menuPlayedFmt", ns.Config.Get(ID, "played", 0) or 0))
    menuUI.faceCap:SetText(ns.T("gofish.barFaceLabel"))
    menuUI.lvlCap:SetText(ns.T("gofish.lvlCap"))
    for i = 1, #menuUI.lvl do
        menuUI.lvl[i].active = (i == self.level)
        ns.StyleButton(menuUI.lvl[i])
    end
    for i = 1, #menuUI.goal do
        menuUI.goal[i].active = (i == self.goalKey)
        ns.StyleButton(menuUI.goal[i])
    end
    menuUI.play.text:SetText(ns.T("gofish.menuPlay"))
    menuUI.play.tip = ns.T("gofish.menuPlayTip")
    menuUI.play.active = true
    ns.StyleButton(menuUI.play)
    menuUI.play.onClick = function()
        if game then game:BeginRound() end
    end
    if ns.Duo.Waiting() then
        menuUI.call.text:SetText(ns.T("duoCancel"))
        menuUI.call.tip = ns.T("duoCancelTip")
        menuUI.call.onClick = function() ns.Duo.Cancel() end
        menuUI.call:Enable()
        menuUI.note:SetText(ns.Duo.Status() or "")
        return
    end
    local name, line, ready = targetLine()
    menuUI.call.text:SetText(ns.T("gofish.menuCall"))
    menuUI.call.tip = ns.T("gofish.menuCallTip")
    menuUI.call.onClick = function()
        local target = ns.Duo.Target()
        if target and game then ns.Duo.Invite(ID, target, game.opts) end
    end
    if ready then menuUI.call:Enable() else menuUI.call:Disable() end
    menuUI.note:SetText(line)
end
function Game:BeginRound()
    if self.phase ~= "menu" then return end
    if ns.Loop.Current() ~= self then return end
    self.phase = "play"
    self:SyncMenu()
    self:Draw()
end
ns.Duo.OnChange(function()
    if game and ns.Loop.Current() == game then
        game:SyncMenu()
        game:Draw()
    end
end)
local function startFx(self, result)
    local mine = (result.who == self.me)
    local fly = {}
    if result.got > 0 then
        for i = 1, min(4, #result.cards) do
            fly[#fly + 1] = { card = result.cards[i] }
        end
    elseif result.drew then
        fly[#fly + 1] = { card = result.card, deck = true, x0 = PILE.X + 6, y0 = PILE.Y }
    end
    self.fx = {
        t = 0,
        vary = (result.rank or 0) * 7 + #self.hand[1] * 3 + self.books[1] * 5
            + self.books[2] * 11 + self.deckPos,
        waitT = 0,
        wait = (mine and result.drew) or false,
        taken = false,
        holdT = 0,
        hold = not mine,
        held = false,
        who = result.who,
        rank = result.rank,
        got = result.got,
        drew = result.drew,
        drewMatch = result.drewMatch,
        book = result.book,
        mine = mine,
        fly = fly,
        bookFrom = {},
        len = FX.LEN + (result.book and FX.CHEST or 0),
    }
end
function Game:FxDone()
    self.fx = nil
end
local function ease(a)
    if a <= 0 then return 0 end
    if a >= 1 then return 1 end
    return a * a * (3 - 2 * a)
end
local function seg(t, a, b)
    return ease((t - a) / (b - a))
end
function Game:Mood()
    local fx = self.fx
    if self.rage and not fx then return "angry" end
    if not fx then return "idle" end
    if fx.mine then
        if fx.t < FX.THINK then return "idle" end
        if fx.t < FX.ANSWER then return "think" end
        return (fx.got > 0) and "sad" or "smug"
    end
    if fx.t < FX.ANSWER then return "smug" end
    return (fx.got > 0) and "glad" or "sad"
end
function Game:Move(move)
    if not apply(self, move, false) then return false end
    if self.last then startFx(self, self.last) end
    if not self.over then ensureHand(self, self.turn, false) end
    self.botT = 0
    self:Draw()
    return true
end
function Game:Turn()
    return self.turn
end
function Game:Update(dt)
    if not room then return end
    self.t = self.t + dt
    paintLive(self.t)
    local tilt = 0
    if self.fx and self.fx.mine and self.fx.t >= FX.THINK and self.fx.t < FX.ANSWER then
        tilt = -4
    end
    charF:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", CHAR_X / CHAR_SC,
        CHAR_Y / CHAR_SC + floor(math.sin(self.t * 2.6) * 2 + 0.5) + tilt)
    if self.phase == "menu" then
        self.askT = (self.askT or 0) + dt
        if self.askT >= 0.34 then
            self.askT = 0
            self:SyncMenu()
        end
        return
    end
    self.blinkT = self.blinkT + dt
    local blink = (self.blinkT % 4.2) < 0.1
    if blink ~= self.blink then
        self.blink = blink
        self.faceMood = nil
    end
    if self.fx then
        if self.fx.hold and not self.fx.held and self.fx.t >= FX.ASK then
            self.fx.holdT = self.fx.holdT + dt
            if self.fx.holdT >= FX.ASK_WAIT then self.fx.held = true end
            self:Draw()
            return
        end
        if self.fx.wait and not self.fx.taken and self.fx.t >= FX.ANSWER then
            self.fx.waitT = self.fx.waitT + dt
            if self.fx.waitT >= FX.WAIT then self.fx.taken = true end
            self:Draw()
            return
        end
        self.fx.t = self.fx.t + dt
        if self.fx.book and not self.fx.popped and self.fx.t >= self.fx.len - FX.DROP then
            self.fx.popped = true
            ns.Sfx.Play("pop")
        end
        if self.fx.t >= self.fx.len then
            self.fx.t = self.fx.len
            local sw, st = self:Talk()
            self.said = { who = sw, text = st }
            self.saidT = 0
            self.fx = nil
        end
        self:Draw()
    end
    if not self.fx and not self.over then ensureHand(self, self.turn, false) end
    if self.said and not self.fx then
        self.saidT = (self.saidT or 0) + dt
        if self.saidT >= SAID_HOLD then
            self.said = nil
            self:Draw()
        end
    end
    if self.over then
        self.overT = (self.overT or 0) + dt
        if self.rage then
            self.rage = self.rage - dt
            if self.rage <= 0 then self.rage = nil end
            self:Draw()
        end
        if not self.fx and self.bombed ~= self.deck then
            self.bombed = self.deck
            if ns.Bomb and not self.net and foe.key == "goblin"
                and self.books[self.me] > self.books[3 - self.me] then
                local bx, by = charF:GetCenter()
                if bx then
                    local k = charF:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    ns.Bomb.Throw(bx * k, by * k)
                    self.rage = RAGE_T
                    self.said = { who = 2, text = ns.T("bombRage") }
                    self.saidT = 0
                    self:Draw()
                end
            end
        end
        return
    end
    if self.net then return end
    if self.turn ~= 2 then return end
    if self.fx then return end
    self.botT = self.botT + dt
    if self.botT < BOT_DELAY then return end
    self.botT = 0
    local result = botTakeTurn(self, false)
    if result then startFx(self, result) end
    if not self.over and self.turn == 1 then ensureHand(self, 1, false) end
    self:Draw()
end
function Game:Score()
    return 100 * self.books[self.me]
end
function ns.GofishGoal()
    return (game and game.goal) or GOALS[1].goal
end
function Game:IsOver()
    if not self.over then return false end
    if self.fx then return false end
    return (self.overT or 0) >= END_FLASH
end
function Game:Stop()
    if root then root:Hide() end
    if menuF then menuF:Hide() end
    if game == self then game = nil end
end
function Game:Click(x, y)
    if self.phase == "menu" then
        for i = 1, #(self.faceRects or {}) do
            local r = self.faceRects[i]
            if x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2 then
                self:PickFace(r.key)
                return
            end
        end
        return
    end
    if self.fx and self.fx.hold and not self.fx.held then
        self.fx.held = true
        self:Draw()
        return
    end
    if self.fx and self.fx.wait and not self.fx.taken then
        self.fx.taken = true
        self:Draw()
        return
    end
    if self.over then return end
    if self.fx then self:FxDone(); self:Draw(); return end
    if self.turn ~= self.me then return end
    for i = #self.cardRects, 1, -1 do
        local r = self.cardRects[i]
        if x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2 then
            self:Move{ k = "ask", v = r.rank }
            return
        end
    end
end
local function chestDrop(fx)
    local k = (fx.t - (fx.len - FX.DROP)) / FX.DROP
    if k <= 0 then return 26 end
    if k >= 1 then return 0 end
    if k < 0.75 then return (1 - k / 0.75) * 26 end
    return -math.sin((k - 0.75) / 0.25 * math.pi) * 4
end
function Game:ResultLine()
    local p, b = self.books[self.me], self.books[3 - self.me]
    if p > b then return ns.T("gofish.resultWinFmt", p, b) end
    if p < b then return ns.T("gofish.resultLoseFmt", p, b) end
    return ns.T("gofish.resultDrawFmt", p, b)
end
local function sayKey(key, vary)
    if type(key) ~= "table" then return key end
    return key[(vary or 0) % #key + 1]
end
function Game:Talk()
    local fx = self.fx
    if self.over and not fx then
        local heWon = self.books[3 - self.me] > self.books[self.me]
        return 2, ns.T(sayKey(heWon and foe.say.win or foe.say.lose, self.books[1]))
    end
    if fx then
        if fx.mine then
            if fx.t < FX.BUBBLE then return nil, "" end
            if fx.t < FX.ANSWER then
                return 1, ns.T(sayKey(YOU_ASK, fx.vary), rankName(self, fx.rank, true))
            end
            if fx.got > 0 then return 2, ns.T(sayKey(foe.say.give, fx.vary)) end
            if fx.drewMatch and fx.taken and fx.t >= FX.ANSWER + FX.FLY then
                return 1, ns.T(sayKey(YOU_DREW, fx.vary), rankName(self, fx.rank))
            end
            return 2, ns.T(sayKey(foe.say.deny, fx.vary))
        end
        if fx.t < FX.BUBBLE then return nil, "" end
        if fx.t < FX.ANSWER then
            return 2, ns.T(sayKey(foe.say.ask, fx.vary), rankName(self, fx.rank, true))
        end
        if fx.got > 0 then return 2, ns.T(sayKey(foe.say.got, fx.vary)) end
        if fx.drewMatch and foe.say.drew and fx.t >= FX.ANSWER + FX.FLY then
            return 2, ns.T(sayKey(foe.say.drew, fx.vary), rankName(self, fx.rank))
        end
        return 1, ns.T(sayKey(YOU_DENY, fx.vary))
    end
    if self.turn ~= self.me then return 2, ns.T("gofish.thinking") end
    if self.said then return self.said.who, self.said.text end
    return nil, ""
end
function Game:GameLine()
    if self:Holding() then
        return ns.T(self.fx.got > 0 and "gofish.giveAsked" or "gofish.denyAsked"), true
    end
    if self:Waiting() then return ns.T("gofish.takeCard"), true end
    if self.over then return nil, false end
    if not self.fx and self.turn == self.me then
        return ns.T("gofish.promptAsk"), false
    end
    return nil, false
end
function Game:ResultText()
    return self:ResultLine()
end
function Game:Waiting()
    local fx = self.fx
    return (fx and fx.wait and not fx.taken and fx.t >= FX.ANSWER) or false
end
function Game:Holding()
    local fx = self.fx
    return (fx and fx.hold and not fx.held and fx.t >= FX.ASK) or false
end
local function groupByRank(hand)
    local byRank, ranks = {}, {}
    for i = 1, #hand do
        local r = rankOf(hand[i])
        local g = byRank[r]
        if not g then
            g = {}
            byRank[r] = g
            ranks[#ranks + 1] = r
        end
        g[#g + 1] = hand[i]
    end
    table.sort(ranks)
    local groups = {}
    for i = 1, #ranks do groups[i] = byRank[ranks[i]] end
    return groups
end
local function dressFace(f, card, mode)
    local r, s = rankOf(card), suitOf(card)
    if mode == MODE.SET then
        ns.DeckCardArt(f, nil)
        ns.DeckCardPoster(f, SET_CARDS[r].pic, ns.T(SET_CARDS[r].name))
        ns.DeckCardRank(f.rank, nil)
        ns.DeckCardRank(f.corner, nil)
        ns.DeckCardSuit(f.mark, nil, nil)
        ns.DeckCardRank(f.corner2, nil)
        ns.DeckCardSuit(f.mark2, nil, nil)
        return
    end
    ns.DeckCardPoster(f, nil)
    ns.DeckCardFace(f, r, s, { icon = suitIcon[s], court = courtIcon[r] })
end
function Game:Draw()
    pool:Reset()
    self.cardRects = {}
    local lvl = 0
    local function card(x, y, w, h)
        local f = pool:Acquire()
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x, y)
        f:SetWidth(w)
        f:SetHeight(h)
        lvl = lvl + 1
        atLevel(f, lvl)
        return f
    end
    local menu = (self.phase == "menu")
    local fx = self.fx
    local back = (self.face ~= MODE.SET) and backIcon or nil
    local mood = menu and "idle" or self:Mood()
    if mood ~= self.faceMood then
        self.faceMood = mood
        paintFace(mood, self.blink)
    end
    if menu then
        inkDone(chestInk)
        self:DrawChestRanks()
        inkDone(bubInk)
        if deckKey ~= "menu:" .. self.face then
            paintStack(deckInk, PILE.MX, PILE.MY, 3, back)
            inkDone(deckInk)
            deckKey = "menu:" .. self.face
        end
        inkDone(glowInk)
        ns.DeckCardRank(deckCount, 20, nil)
        self.faceRects = {}
        inkDone(menuUI.ink)
        for i = 1, #FACE_OPTIONS do
            local key = FACE_OPTIONS[i].key
            local on = (key == self.face)
            local fx0 = FACE.XS[i]
            local fy0 = FACE.Y + (on and FACE.LIFT or 0)
            local f = card(fx0, fy0, FACE.CW, FACE.CH)
            dressFace(f, (key == MODE.CARD) and (13 + 7) or RANK_N, key)
            if on then
                ink(menuUI.ink, fx0 - 2, FACE.Y - 5, FACE.CW + 4, 3, LIE.GOLD, nil, "ARTWORK")
            end
            self.faceRects[i] = { x1 = fx0, y1 = FACE.Y, x2 = fx0 + FACE.CW,
                                  y2 = FACE.Y + FACE.CH + FACE.LIFT, key = key }
        end
        inkDone(menuUI.ink)
        bub.panel:ClearAllPoints()
        bub.panel:SetPoint("BOTTOMLEFT", bubbleF, "BOTTOMLEFT", BUB_FOE.X, BUB_FOE.Y)
        bub.panel:SetWidth(BUB_FOE.W)
        bub.panel:SetHeight(BUB_FOE.H)
        bub.text:SetWidth(BUB_FOE.W - 28)
        bub.panel:Show()
        paintBubble(bubInk, BUB_FOE.X, BUB_FOE.Y, BUB_FOE.W, BUB_FOE.H, NOTE.RINGS, "left")
        inkDone(bubInk)
        ns.DeckCardRank(bub.cap, 12, ns.T(foe.name),
            INK_BUB_CAP[1], INK_BUB_CAP[2], INK_BUB_CAP[3], "")
        ns.DeckCardRank(bub.text, 17, ns.T(sayKey(foe.say.hi, ns.Config.Get(ID, "played", 0) or 0)),
            INK_BUB_TEXT[1], INK_BUB_TEXT[2], INK_BUB_TEXT[3], "")
        ns.DeckCardRank(deckNote, 13, nil)
        plate:SetText("")
        pool:HideExtras()
        self.cardLvl = lvl
        return
    end
    local opp = 3 - self.me
    local me = self.me
    local slots = { {}, {} }
    self.slots = slots
    local mode = self.face
    local waiting = fx and fx.wait and not fx.taken
    local flyOn = fx and #fx.fly > 0 and not waiting
        and fx.t >= FX.ANSWER and fx.t < FX.ANSWER + FX.FLY
    local landed = fx and #fx.fly > 0 and fx.t >= FX.ANSWER + FX.FLY
    local bookPhase = fx and fx.book and fx.t >= FX.LEN
    local flying = {}
    if fx then
        for i = 1, #fx.fly do flying[fx.fly[i].card] = true end
    end
    local bookCards = {}
    if fx and fx.book then
        for su = 1, 4 do bookCards[(su - 1) * RANK_N + fx.book] = true end
    end
    local function viewOf(who)
        local src = self.hand[who]
        local out = {}
        local receiver = fx and (who == fx.who)
        for i = 1, #src do
            local c = src[i]
            if not (flying[c] and receiver and not (flyOn or landed)) then out[#out + 1] = c end
        end
        if fx and not receiver and fx.got > 0 and not landed then
            for i = 1, #fx.fly do out[#out + 1] = fx.fly[i].card end
        end
        if fx and receiver and fx.book and not bookPhase then
            for su = 1, 4 do
                local c = (su - 1) * RANK_N + fx.book
                if not (flying[c] and not (flyOn or landed)) then out[#out + 1] = c end
            end
        end
        return out
    end
    local function hideChest(who)
        return fx and fx.book and fx.who == who and fx.t < fx.len - FX.DROP
    end
    local pIn = chestInk
    local his = self.bookRanks[opp]
    for i = 1, #his do
        if not (i == #his and hideChest(opp)) then
            local drop = (i == #his and fx and fx.book and fx.who == opp) and chestDrop(fx) or 0
            paintChest(pIn, chestX(i, false), NICHE.OP_Y + drop, false)
        end
    end
    local mine = self.bookRanks[me]
    for i = 1, #mine do
        if not (i == #mine and hideChest(me)) then
            local drop = (i == #mine and fx and fx.book and fx.who == me) and chestDrop(fx) or 0
            paintChest(pIn, chestX(i, true), NICHE.MY_Y + drop, true)
        end
    end
    inkDone(pIn)
    self:DrawChestRanks()
    local botView = viewOf(opp)
    local bxs = botFanXs(#botView)
    for i = 1, #botView do
        local c = botView[i]
        slots[opp][c] = { x = bxs[i], y = BOT.Y }
        if bookCards[c] and not bookPhase then fx.bookFrom[c] = { x = bxs[i], y = BOT.Y } end
        if not (flying[c] and flyOn) then
            local f = card(bxs[i], BOT.Y, BOT.CW, BOT.CH)
            ns.DeckCardCover(f, true, back, BACK_EMBLEM)
        end
    end
    local left = DECK_N - self.deckPos + 1
    if left < 0 then left = 0 end
    if fx and fx.drew and fx.t < FX.ANSWER + FX.FLY then left = left + 1 end
    inkDone(glowInk)
    if self:Waiting() then
        paintGlow(glowInk, PILE.X, PILE.Y, left, 0.45 + 0.35 * math.sin(self.t * 6))
    end
    inkDone(glowInk)
    if left > 0 then
        local key = "play:" .. self.face .. ":" .. left
        if deckKey ~= key then
            paintStack(deckInk, PILE.X, PILE.Y, left, back)
            inkDone(deckInk)
            deckKey = key
        end
        local top = PILE.Y + lieLayers(left) * LIE.DY
        deckCount:ClearAllPoints()
        deckCount:SetPoint("CENTER", tableF, "BOTTOMLEFT",
            PILE.X + LIE.W / 2 + LIE.SKEW * LIE.D / 2, top + LIE.D / 2)
        ns.DeckCardRank(deckCount, 20, tostring(left), 1, 0.82, 0)
    else
        if deckKey ~= "none" then
            inkDone(deckInk)
            deckKey = "none"
        end
        ns.DeckCardRank(deckCount, 20, nil)
    end
    local groups = groupByRank(viewOf(me))
    local xs, step, tight = fanXs(#groups, PLAYER_CW)
    local pdx, pdy = 2, 2
    if mode == MODE.SET then pdx, pdy = 3, 5 end
    for gi = 1, #groups do
        local group = groups[gi]
        local m = #group
        local r = rankOf(group[1])
        local lift = 0
        if fx and fx.rank == r and fx.t < FX.ANSWER and (fx.mine or fx.got > 0) then
            lift = FX.LIFT_UP * seg(fx.t, 0, FX.LIFT)
        end
        local offs2, growX, growY = ns.DeckPile(m, { dx = pdx, dy = pdy, max = 3 })
        local base = m - #offs2
        local topCard
        for k = 1, m do
            local c = group[k]
            local o = offs2[max(1, k - base)]
            local sx, sy = xs[gi] + o.dx, PLAYER_Y + lift + o.dy
            slots[me][c] = { x = sx, y = sy }
            if bookCards[c] and not bookPhase then fx.bookFrom[c] = { x = sx, y = sy } end
            if k > base and not (flying[c] and flyOn) then
                topCard = { f = card(sx, sy, PLAYER_CW, PLAYER_CH), c = c }
            end
        end
        if topCard then dressFace(topCard.f, topCard.c, mode) end
        local hitW = PLAYER_CW
        if tight and gi < #groups then hitW = step end
        self.cardRects[#self.cardRects + 1] = {
            x1 = xs[gi], y1 = PLAYER_Y,
            x2 = xs[gi] + hitW + growX, y2 = PLAYER_Y + PLAYER_CH + growY,
            rank = r,
        }
    end
    if flyOn then
        local from, to = slots[3 - fx.who], slots[fx.who]
        local w0, h0 = BOT.CW, BOT.CH
        local w1, h1 = PLAYER_CW, PLAYER_CH
        if not fx.mine then w0, h0, w1, h1 = w1, h1, w0, h0 end
        for i = 1, #fx.fly do
            local f = fx.fly[i]
            if f.deck then w0, h0 = PLAYER_CW, PLAYER_CH end
            if not f.x0 then
                local sl = from[f.card]
                f.x0 = sl and sl.x or (CW / 2 - PLAYER_CW / 2)
                f.y0 = sl and sl.y or (fx.mine and BOT.Y or PLAYER_Y)
            end
            local tg = to[f.card]
            local x1 = tg and tg.x or (CW / 2 - PLAYER_CW / 2)
            local y1 = tg and tg.y or (fx.mine and PLAYER_Y or BOT.Y)
            local k = min(1, seg(fx.t, FX.ANSWER, FX.ANSWER + FX.FLY) + (i - 1) * 0.06)
            local e = ease(k)
            local w = w0 + (w1 - w0) * e
            local h = h0 + (h1 - h0) * e
            local x = f.x0 + (x1 - f.x0) * e
            local y = f.y0 + (y1 - f.y0) * e + math.sin(k * math.pi) * 40
            local sq = abs(math.cos(k * math.pi))
            local cw = max(2, w * sq)
            local c = card(x + (w - cw) / 2, y, cw, h)
            local faceUp = (fx.mine and k >= 0.5)
                or (not fx.mine and k < 0.5 and (not f.deck or fx.drewMatch))
            if faceUp then
                dressFace(c, f.card, mode)
            else
                ns.DeckCardCover(c, true, back, BACK_EMBLEM)
            end
        end
    end
    if bookPhase then
        local who = fx.who
        local nb = #self.bookRanks[who]
        local cx = chestX(nb, who == me) + NICHE.W / 2
        local cy = (who == me and NICHE.MY_Y or NICHE.OP_Y) + NICHE.H / 2
        local w0, h0 = PLAYER_CW, PLAYER_CH
        if who ~= me then w0, h0 = BOT.CW, BOT.CH end
        local show = ease((fx.t - FX.LEN) / FX.BOOK_SHOW)
        local flyT = (fx.t - FX.LEN - FX.BOOK_SHOW) / FX.BOOK_FLY
        local span = 4 * w0 + 3 * FX.ROW_GAP
        local rx0 = floor(FX.ROW_X - span / 2)
        local ry = floor(FX.ROW_Y - h0 / 2)
        for su = 1, 4 do
            local c = (su - 1) * RANK_N + fx.book
            local fr = fx.bookFrom[c] or { x = cx - w0 / 2, y = cy }
            local rx = rx0 + (su - 1) * (w0 + FX.ROW_GAP)
            local x = fr.x + (rx - fr.x) * show
            local y = fr.y + (ry - fr.y) * show + math.sin(show * math.pi) * 12
            local w, h = w0, h0
            if flyT > 0 then
                local k = ease(flyT * 1.24 - (su - 1) * 0.08)
                w, h = w0 * (1 - 0.6 * k), h0 * (1 - 0.6 * k)
                x = rx + (cx - w / 2 - rx) * k
                y = ry + (cy - h / 2 - ry) * k + math.sin(k * math.pi) * 16
            end
            dressFace(card(x, y, w, h), c, mode)
        end
    end
    pool:HideExtras()
    self.cardLvl = lvl
    self:DrawTalk()
end
function Game:DrawChestRanks()
    chestFS = chestFS or {}
    local fx = self.fx
    local n = 0
    if self.phase == "menu" then
        for i = 1, #chestFS do chestFS[i]:Hide() end
        return
    end
    local function row(list, y, isMine)
        local who = isMine and self.me or (3 - self.me)
        for i = 1, #list do
            local moving = (fx and fx.book and fx.who == who and i == #list) or false
            if not moving then
                n = n + 1
                local fs = chestFS[n]
                if not fs then
                    fs = chestF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    chestFS[n] = fs
                end
                fs:ClearAllPoints()
                fs:SetPoint("CENTER", chestF, "BOTTOMLEFT",
                    chestX(i, isMine) + NICHE.W / 2, y + floor(NICHE.H * 0.78))
                ns.DeckCardRank(fs, NICHE.FONT, ns.DeckRankLabel(list[i]), 1, 1, 1, "")
            end
        end
    end
    row(self.bookRanks[3 - self.me], NICHE.OP_Y, false)
    row(self.bookRanks[self.me], NICHE.MY_Y, true)
    for i = n + 1, #chestFS do chestFS[i]:Hide() end
end
function Game:DrawTalk()
    bubbleAbove(self.cardLvl or 0)
    local who, line = self:Talk()
    if not who or line == "" then who, line = nil, "" end
    local mine = (who == 1)
    local bx = mine and BUB_MINE.X or BUB_FOE.X
    local by = mine and BUB_MINE.Y or BUB_FOE.Y
    local bw = mine and BUB_MINE.W or BUB_FOE.W
    local bh = mine and BUB_MINE.H or BUB_FOE.H
    inkDone(bubInk)
    if who then
        bub.panel:ClearAllPoints()
        bub.panel:SetPoint("BOTTOMLEFT", bubbleF, "BOTTOMLEFT", bx, by)
        bub.panel:SetWidth(bw)
        bub.panel:SetHeight(bh)
        bub.text:SetWidth(bw - 28)
        bub.panel:Show()
        paintBubble(bubInk, bx, by, bw, bh, NOTE.RINGS, mine and "down" or "left")
    else
        bub.panel:Hide()
    end
    local gl, hot = self:GameLine()
    local c = hot and NOTE.HOT or NOTE.INK
    ns.DeckCardRank(deckNote, 13, gl, c[1], c[2], c[3], "")
    if gl then
        local w = (deckNote:GetStringWidth() or 0) + NOTE.PAD
        local x0 = floor(CW / 2 - w / 2)
        paintBubble(bubInk, x0 - 2, NOTE.Y0 - 2, w + 4, NOTE.H + 4, NOTE.THIN, nil)
    end
    inkDone(bubInk)
    ns.DeckCardRank(bub.text, 17, who and line or nil,
        INK_BUB_TEXT[1], INK_BUB_TEXT[2], INK_BUB_TEXT[3], "")
    ns.DeckCardRank(bub.cap, 12,
        who and (mine and ns.T("gofish.youLabel") or ns.T(foe.name)) or nil,
        INK_BUB_CAP[1], INK_BUB_CAP[2], INK_BUB_CAP[3], "")
    if self.net and ns.Duo.Peer() then
        if ns.Duo.Held() then
            plate:SetText(ns.T("gofish.plateAwayFmt", ns.Duo.Peer()))
            plate:SetTextColor(0.6, 0.58, 0.54)
            charF:SetAlpha(0.45)
        else
            plate:SetText(ns.Duo.Peer())
            plate:SetTextColor(1, 0.82, 0)
            charF:SetAlpha(1)
        end
    else
        plate:SetText("")
        charF:SetAlpha(1)
    end
end
local MINI_BG   = { 0.14, 0.12, 0.10 }
local MINI_MINE = { 0.478, 0.290, 0.133 }
local MINI_OPP  = { 0.224, 0.255, 0.310 }
local MINI_GOLD = { 1, 0.82, 0 }
local MINI_INK  = { 0.055, 0.071, 0.098 }
local MINI_PAPER = { 0.851, 0.643, 0.255 }
local MINI_DECK  = { 0.298, 0.173, 0.071 }
local MINI = {
    {
        cols = 4, rows = 2, cell = 28, gap = 4, back = "plain", face = MINI_BG,
        fill = {
            { c = 1, r = 2, col = MINI_PAPER }, { c = 2, r = 2, col = MINI_PAPER },
            { c = 3, r = 2, col = MINI_PAPER }, { c = 4, r = 2, col = MINI_PAPER },
            { c = 2, r = 1, col = MINI_MINE },
        },
        ring = { { c = 2, r = 1 } },
        text = {
            { c = 1, r = 2, s = "7", col = MINI_INK }, { c = 2, r = 2, s = "7", col = MINI_INK },
            { c = 3, r = 2, s = "7", col = MINI_INK }, { c = 4, r = 2, s = "7", col = MINI_INK },
            { c = 2, r = 1, s = "7", col = MINI_INK },
        },
        arrow = {
            { c1 = 1, r1 = 2, c2 = 2, r2 = 1, col = MINI_GOLD },
            { c1 = 2, r1 = 2, c2 = 2, r2 = 1, col = MINI_GOLD },
            { c1 = 3, r1 = 2, c2 = 2, r2 = 1, col = MINI_GOLD },
            { c1 = 4, r1 = 2, c2 = 2, r2 = 1, col = MINI_GOLD },
        },
    },
    {
        cols = 3, rows = 2, cell = 28, gap = 4, back = "plain", face = MINI_BG,
        fill = {
            { c = 1, r = 2, col = MINI_OPP }, { c = 2, r = 2, col = MINI_OPP },
            { c = 1, r = 1, col = MINI_MINE }, { c = 2, r = 1, col = MINI_MINE },
        },
        text = {
            { c = 1, r = 2, s = "7", col = MINI_INK }, { c = 2, r = 2, s = "7", col = MINI_INK },
            { c = 1, r = 1, s = "7", col = MINI_INK }, { c = 2, r = 1, s = "7", col = MINI_INK },
        },
        arrow = {
            { c1 = 1, r1 = 2, c2 = 1, r2 = 1, col = MINI_GOLD },
            { c1 = 2, r1 = 2, c2 = 2, r2 = 1, col = MINI_GOLD },
        },
    },
    {
        cols = 3, rows = 2, cell = 28, gap = 4, back = "plain", face = MINI_BG,
        fill = { { c = 2, r = 2, col = MINI_DECK }, { c = 2, r = 1, col = MINI_PAPER } },
        ring = { { c = 2, r = 2 } },
        text = { { c = 2, r = 1, s = "?", col = MINI_INK } },
        arrow = { { c1 = 2, r1 = 2, c2 = 2, r2 = 1, col = MINI_GOLD } },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, spec.face)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.ring or {}) do g:Ring(m.c, m.r, 0.75) end
    for _, m in ipairs(spec.text or {}) do g:Text(m.c, m.r, m.s, m.col) end
    for _, m in ipairs(spec.arrow or {}) do g:Arrow(m.c1, m.r1, m.c2, m.r2, m.col) end
end
local function helpChestArt(host) paintMini(host, MINI[1]) end
local function helpHitArt(host) paintMini(host, MINI[2]) end
local function helpMissArt(host) paintMini(host, MINI[3]) end
ns.RegisterGame{
    id = ID,
    label = "gofish.label",
    icon = { tex = "Interface\\Icons\\INV_Box_01", coord = { 0.07, 0.93, 0.07, 0.93 } },
    tip = "gofish.tip",
    duo = "turns",
    physics = false,
    look = LOOK,
    ownPanel = true,
    record = false,
    save = false,
    finale = true,
    New = New,
    controls = {
        { action = "ask",  label = "gofish.ctlAsk",  mouse = "LMB", where = "gofish.ctlOnCard" },
        { action = "draw", label = "gofish.ctlDraw", mouse = "LMB", where = "gofish.ctlOnDeck" },
        { action = "skip", label = "gofish.ctlSkip", mouse = "LMB", where = "gofish.ctlOnField" },
    },
    help = {
        "gofish.helpChest",
        { art = helpChestArt, h = 68 },
        "gofish.helpAsk",
        "gofish.helpHit",
        { art = helpHitArt, h = 68 },
        "gofish.helpMiss",
        { art = helpMissArt, h = 68 },
        "gofish.helpEnd",
    },
}
