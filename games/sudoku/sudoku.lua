local ADDON, ns = ...
local ID = "sudoku"
local BANK
local CELL   = 45
local GAP    = 3
local BGAP   = 9
local FIELD  = 9 * CELL + 6 * GAP + 2 * BGAP
local PITCH  = CELL + GAP
local BLOCK  = 3 * CELL + 2 * GAP
local BPITCH = BLOCK + BGAP
local BEXTRA = BGAP - GAP
local MARGIN = 16
local FULL_OY = 20
local OX, OY = MARGIN, FULL_OY
local BOARD_EDGE = 8
local PAL_EDGE   = 6
local PAL     = 44
local PAL_GAP = 6
local PAL_W   = 3 * PAL + 2 * PAL_GAP
local PAL_X   = 640 - MARGIN - PAL_W
local PAL_Y   = 239
local MINI_PAL_GAP = 5
local MINI_PAL_W   = 9 * PAL + 8 * MINI_PAL_GAP
local MINI_PAL_X   = OX + math.floor((FIELD - MINI_PAL_W) / 2)
local MINI_PAL_Y   = 12
local MINI_OY      = MINI_PAL_Y + PAL + PAL_EDGE + 6 + BOARD_EDGE
local MINI_W       = OX * 2 + FIELD
local MINI_H       = MINI_OY + FIELD + BOARD_EDGE + 8
local miniOn       = false
local TROW    = 22
local MARK_FONT = "NumberFontNormalSmall"
local MPITCH    = 14
local DIGIT = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local WIN_FLASH = 0.8
local HINT_COST = 60
local SOLID_TEX = "Interface\\Tooltips\\UI-Tooltip-Background"
local HL_TEX   = "Interface\\Buttons\\ButtonHilight-Square"
local EDGE_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"
local OK_TEX   = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ASK_TEX  = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local Skins = ns.sudokuSkins
local LOOK_WOOD   = { 0.230, 0.190, 0.130 }
local LOOK_EDGE   = { 1, 0.82, 0 }
local LOOK_SCREEN = Skins.night.screen
local LOOK = ns.MakeLook{ wood = LOOK_WOOD, edge = LOOK_EDGE, screen = LOOK_SCREEN }
local LEVELS = {
    { key = "easy",   label = "sudoku.levelEasyLabel",
      tip = "sudoku.levelEasyTip" },
    { key = "normal", label = "sudoku.levelNormalLabel",
      tip = "sudoku.levelNormalTip" },
    { key = "hard",   label = "sudoku.levelHardLabel",
      tip = "sudoku.levelHardTip" },
    { key = "expert", label = "sudoku.levelExpertLabel",
      tip = "sudoku.levelExpertTip" },
    { key = "evil",   label = "sudoku.levelEvilLabel",
      tip = "sudoku.levelEvilTip" },
}
local DEFAULT_LEVEL = "normal"
local pool, palPool, ui, cur
local Game = {}
Game.__index = Game
local function levelOf(key)
    for _, l in ipairs(LEVELS) do
        if l.key == key then return l end
    end
    for _, l in ipairs(LEVELS) do
        if l.key == DEFAULT_LEVEL then return l end
    end
    return LEVELS[1]
end
local PEERS = {}
local UNITS = {}
local BLOCK_ODD = {}
local CROSS = {}
local function rowcol(i)
    return math.floor((i - 1) / 9) + 1, (i - 1) % 9 + 1
end
do
    for r = 1, 9 do
        local u = {}
        for c = 1, 9 do u[c] = (r - 1) * 9 + c end
        UNITS[#UNITS + 1] = u
    end
    for c = 1, 9 do
        local u = {}
        for r = 1, 9 do u[r] = (r - 1) * 9 + c end
        UNITS[#UNITS + 1] = u
    end
    for b = 0, 8 do
        local r0, c0 = math.floor(b / 3) * 3, (b % 3) * 3
        local u = {}
        for r = 1, 3 do
            for c = 1, 3 do u[#u + 1] = (r0 + r - 1) * 9 + c0 + c end
        end
        UNITS[#UNITS + 1] = u
    end
    for i = 1, 81 do
        local ri, ci = rowcol(i)
        local bi = math.floor((ri - 1) / 3) * 3 + math.floor((ci - 1) / 3)
        local list = {}
        for j = 1, 81 do
            if j ~= i then
                local rj, cj = rowcol(j)
                local bj = math.floor((rj - 1) / 3) * 3 + math.floor((cj - 1) / 3)
                if ri == rj or ci == cj or bi == bj then list[#list + 1] = j end
            end
        end
        PEERS[i] = list
        local cross = {}
        for j = 1, 81 do
            if j ~= i then
                local rj, cj = rowcol(j)
                if ri == rj or ci == cj then cross[#cross + 1] = j end
            end
        end
        CROSS[i] = cross
        local br, bc = math.floor((ri - 1) / 3), math.floor((ci - 1) / 3)
        BLOCK_ODD[i] = ((br + bc) % 2 == 1)
    end
end
local function cellXY(i)
    local r, c = rowcol(i)
    local up = 9 - r
    return OX + (c - 1) * PITCH + math.floor((c - 1) / 3) * BEXTRA,
           OY + up * PITCH + math.floor(up / 3) * BEXTRA
end
local function axis(d)
    if d < 0 then return nil end
    local b = math.floor(d / BPITCH)
    if b > 2 then return nil end
    local inb = d - b * BPITCH
    if inb > BLOCK then return nil end
    local k = math.floor(inb / PITCH)
    if inb - k * PITCH > CELL then return nil end
    return b * 3 + k + 1
end
local function cellAt(x, y)
    local c = axis(x - OX)
    if not c then return nil end
    local up = axis(y - OY)
    if not up then return nil end
    return (9 - up) * 9 + c
end
local function palXY(k)
    if miniOn then
        return MINI_PAL_X + (k - 1) * (PAL + MINI_PAL_GAP), MINI_PAL_Y
    end
    local col = (k - 1) % 3 + 1
    local row = math.floor((k - 1) / 3) + 1
    return PAL_X + (col - 1) * (PAL + PAL_GAP),
           PAL_Y + (3 - row) * (PAL + PAL_GAP)
end
local function palAt(x, y)
    for k = 1, 9 do
        local px, py = palXY(k)
        if x >= px and x <= px + PAL and y >= py and y <= py + PAL then return k end
    end
    return nil
end
local function digitsOf(s, from)
    local g = {}
    for i = 1, 81 do
        g[i] = tonumber(s:sub(from + i - 1, from + i - 1)) or 0
    end
    return g
end
local function rowPerm(rng)
    local bands = rng:Shuffle({ 0, 1, 2 })
    local out = {}
    for _, b in ipairs(bands) do
        local inner = rng:Shuffle({ 0, 1, 2 })
        for _, k in ipairs(inner) do out[#out + 1] = b * 3 + k end
    end
    return out
end
local function transform(grid, tr)
    local out = {}
    for i = 1, 81 do
        local r0 = math.floor((i - 1) / 9)
        local c0 = (i - 1) % 9
        local nr, nc = tr.rows[r0 + 1], tr.cols[c0 + 1]
        if tr.flip then nr, nc = nc, nr end
        local v = grid[i]
        out[nr * 9 + nc + 1] = (v == 0) and 0 or tr.digits[v]
    end
    return out
end
local function validSolution(g)
    for _, u in ipairs(UNITS) do
        local seen = {}
        for _, i in ipairs(u) do
            local v = g[i]
            if not v or v < 1 or v > 9 or seen[v] then return false end
            seen[v] = true
        end
    end
    return true
end
local function clueCount(g)
    local n = 0
    for i = 1, 81 do
        if g[i] ~= 0 then n = n + 1 end
    end
    return n
end
local function transformOK(p, s, clues)
    if not validSolution(s) then return false end
    if clueCount(p) ~= clues then return false end
    for i = 1, 81 do
        if p[i] ~= 0 and p[i] ~= s[i] then return false end
    end
    return true
end
local function valueAt(self, i)
    local g = self.given[i]
    if g ~= 0 then return g end
    return self.put[i]
end
local function fits(self, i, c)
    for _, j in ipairs(PEERS[i]) do
        if valueAt(self, j) == c then return false end
    end
    return true
end
local function hasMark(self, i)
    local m = self.mark[i]
    return m ~= nil and next(m) ~= nil
end
local function recount(self)
    local conf, filled = {}, 0
    for i = 1, 81 do
        if valueAt(self, i) ~= 0 then filled = filled + 1 end
    end
    for i = 1, 81 do
        local c = self.put[i]
        if c ~= 0 then
            for _, j in ipairs(PEERS[i]) do
                if valueAt(self, j) == c then
                    conf[i] = true
                    break
                end
            end
        end
    end
    self.conf, self.filled = conf, filled
    if not self.won and filled == 81 and next(conf) == nil then
        self.won = true
        self.wonAt = self.t
    end
end
local function hintCell(self)
    local best, bestN
    for i = 1, 81 do
        if self.given[i] == 0 and self.put[i] == 0 then
            local n = 0
            for c = 1, 9 do
                if fits(self, i, c) then n = n + 1 end
            end
            if not bestN or n < bestN then best, bestN = i, n end
        end
    end
    if best then return best end
    for i = 1, 81 do
        if self.given[i] == 0 and self.put[i] ~= self.solve[i] then return i end
    end
    return nil
end
local function canNote(self)
    for i = 1, 81 do
        if self.given[i] == 0 and self.put[i] == 0 and not hasMark(self, i) then return true end
    end
    return false
end
local function apply(self, move)
    if not move then return false end
    local k = move.k
    local i = move.i
    if k == "put" or k == "clear" or k == "mark" then
        if type(i) ~= "number" or i < 1 or i > 81 then return false end
        if self.given[i] ~= 0 then return false end
    end
    if k == "put" then
        local c = move.c
        if type(c) ~= "number" or c < 1 or c > 9 then return false end
        self.put[i] = c
    elseif k == "clear" then
        if self.put[i] == 0 then return false end
        self.put[i] = 0
    elseif k == "mark" then
        local c = move.c
        if type(c) ~= "number" or c < 1 or c > 9 then return false end
        local m = self.mark[i]
        if not m then
            m = {}
            self.mark[i] = m
        end
        if m[c] then m[c] = nil else m[c] = true end
    elseif k == "note" then
        local did = false
        for j = 1, 81 do
            if self.given[j] == 0 and self.put[j] == 0 and not hasMark(self, j) then
                local m = {}
                for c = 1, 9 do
                    if fits(self, j, c) then m[c] = true end
                end
                if next(m) then
                    self.mark[j] = m
                    did = true
                end
            end
        end
        if not did then return false end
    elseif k == "hint" then
        local j = hintCell(self)
        if not j then return false end
        self.given[j] = self.solve[j]
        self.put[j] = 0
        self.mark[j] = nil
        self.hints = self.hints + 1
    else
        return false
    end
    self.started = true
    recount(self)
    return true
end
local function New(canvas)
    local self = setmetatable({}, Game)
    self.canvas = canvas
    return self
end
function Game:Start(seed, moves)
    self.sk, self.skinKey = ns.SudokuSkin(ns.Store.Skin(ID))
    self.lv = levelOf(self.opts and self.opts.level)
    self.opts = { level = self.lv.key }
    local rng = ns.RNG.New(seed)
    local list = (BANK and (BANK[self.lv.key] or BANK[DEFAULT_LEVEL])) or {}
    local raw = list[rng:Int(#list)]
    if not raw then
        ns.say(ns.T("sudoku.sayBankEmpty"))
        raw = string.rep("0", 162)
    end
    local basePuzzle = digitsOf(raw, 1)
    local baseSolve  = digitsOf(raw, 82)
    local tr = {
        rows   = rowPerm(rng),
        cols   = rowPerm(rng),
        digits = rng:Shuffle({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }),
        flip   = rng:Int(2) == 1,
    }
    local given = transform(basePuzzle, tr)
    local solve = transform(baseSolve, tr)
    if not transformOK(given, solve, clueCount(basePuzzle)) then
        ns.say(ns.T("sudoku.sayTransformFail"))
        given, solve = basePuzzle, baseSolve
    end
    self.given, self.solve = given, solve
    self.put, self.mark = {}, {}
    for i = 1, 81 do self.put[i] = 0 end
    self.pick = 1
    self.cur = nil
    self.hover = nil
    self.hints = 0
    self.t = 0
    self.started = false
    self.won, self.wonAt = false, nil
    recount(self)
    if moves and #moves > 0 then
        for n = 1, #moves do apply(self, moves[n]) end
        local rec = ns.Store.Load(ID)
        self.t = (rec and rec.elapsed) or 0
        self.started = true
    end
    cur = self
    self:Build()
    self._panelLock, self._panelSkin = nil, nil
    self:Draw()
end
function Game:Move(move)
    local wasWon = self.won
    local took = apply(self, move)
    self:Draw()
    if took then
        ns.Sfx.Play((self.won and not wasWon) and "clear" or "pop")
    end
    return took
end
function Game:Click(x, y, button)
    if self.won then return end
    local k = palAt(x, y)
    if k then
        self.pick = k
        self:Draw()
        ns.Sfx.Play("pick")
        return
    end
    local i = cellAt(x, y)
    if not i then return end
    if button == "RightButton" then
        if self.given[i] ~= 0 then return end
        if self.put[i] ~= 0 then
            self:Move{ k = "clear", i = i }
        else
            self:Move{ k = "mark", i = i, c = self.pick }
        end
        return
    end
    if self.given[i] ~= 0 then
        self.pick = self.given[i]
        self:Draw()
        ns.Sfx.Play("pick")
        return
    end
    if self.put[i] == self.pick then
        self:Move{ k = "clear", i = i }
    else
        self:Move{ k = "put", i = i, c = self.pick }
    end
end
function Game:Key(action, down)
    if not down or self.won then return end
    local num = string.match(action, "^num(%d)$")
    if num then
        self.pick = tonumber(num)
        self:Draw()
        ns.Sfx.Play("pick")
        return
    end
    if action == "left" or action == "right" or action == "up" or action == "down" then
        if not self.cur then
            self.cur = 41
        else
            local r, c = rowcol(self.cur)
            if action == "left" then c = (c > 1) and (c - 1) or 9
            elseif action == "right" then c = (c < 9) and (c + 1) or 1
            elseif action == "up" then r = (r > 1) and (r - 1) or 9
            else r = (r < 9) and (r + 1) or 1
            end
            self.cur = (r - 1) * 9 + c
        end
        self:Draw()
        return
    end
    local i = self.cur
    if not i then return end
    if action == "fire" then
        if self.given[i] ~= 0 then
            self.pick = self.given[i]
            self:Draw()
            ns.Sfx.Play("pick")
        elseif self.put[i] == self.pick then
            self:Move{ k = "clear", i = i }
        else
            self:Move{ k = "put", i = i, c = self.pick }
        end
    elseif action == "mark" then
        if self.given[i] ~= 0 then return end
        if self.put[i] ~= 0 then
            self:Move{ k = "clear", i = i }
        else
            self:Move{ k = "mark", i = i, c = self.pick }
        end
    end
end
function Game:Update(dt)
    if self.started then self.t = self.t + dt end
    if self.won then
        self:Flash()
        return
    end
    self:Hover()
end
function Game:Score()
    return 0
end
function Game:Brink()
    local spare
    for i = 1, 81 do
        if self.given[i] == 0 then
            if not spare then
                spare = i
                self.put[i] = 0
            else
                self.put[i] = self.solve[i]
            end
        end
    end
    self.started = true
    recount(self)
end
function Game:Penalized()
    return math.floor((self.wonAt or self.t) + HINT_COST * self.hints)
end
function Game:Clock()
    return ns.Records.Span(self:Penalized()), false
end
function Game:Marks()
    return { time = self:Penalized() }
end
function Game:IsOver()
    if not self.won then return false end
    return (self.t - (self.wonAt or 0)) >= WIN_FLASH
end
function Game:Mini(on)
    miniOn = on and true or false
    OY = miniOn and MINI_OY or FULL_OY
    if not self.cells then return end
    self:Build()
    for i = 1, 81 do
        local c = self.cells[i]
        c._num, c._out, c._style = nil, nil, nil
    end
    for k = 1, 9 do
        local c = self.pals[k]
        c._num, c._out, c._style = nil, nil, nil
    end
end
function Game:Stop()
    miniOn, OY = false, FULL_OY
    if cur == self then cur = nil end
    if pool then pool:HideAll() end
    if palPool then palPool:HideAll() end
    if ui then
        ui.note:Hide()
        ui.hint:Hide()
        ui.side:Hide()
        ui.screen:Hide()
        ui.board:Hide()
        ui.boardPal:Hide()
        ui.flash:Hide()
        ui.hl:Hide()
        ui.kb:Hide()
    end
    self.cells, self.pals = nil, nil
end
function Game:PanelSync()
    if not ui or ns.Loop.Current() ~= self then return end
    ui.tally:Sync()
    local locked = ns.window:AxisLocked()
    if self._panelLock == locked and self._panelSkin == self.skinKey then return end
    self._panelLock, self._panelSkin = locked, self.skinKey
    for _, it in ipairs(ns.window:PanelItems()) do
        if it.kind == "step" then
            ui.lvl:SetSpec(it)
            if it.disabled then ui.lvl:Disable() else ui.lvl:Enable() end
            ui.lvl:Restyle()
        end
    end
    local opts = {}
    for _, key in ipairs(Skins.order) do
        local sk = Skins[key]
        opts[#opts + 1] = { key = key, label = ns.TL(sk.label), tip = ns.TL(sk.tip) }
    end
    ui.skin:SetOptions(opts, self.skinKey, ns.T("sudoku.skinLabel"))
end
local function makeCell(parent)
    local c = ns.MakeCell(parent)
    c:EnableMouse(false)
    ns.StyleCell(c, "plain")
    c.bg = c:CreateTexture(nil, "BACKGROUND")
    c.bg:SetAllPoints(c)
    c.mark = {}
    for k = 1, 9 do
        local col = (k - 1) % 3 + 1
        local row = math.floor((k - 1) / 3) + 1
        local t = c:CreateFontString(nil, "BORDER", MARK_FONT)
        t:SetPoint("CENTER", c, "CENTER", (col - 2) * MPITCH, (2 - row) * MPITCH)
        t:SetText(DIGIT[k])
        t:Hide()
        c.mark[k] = t
    end
    return c
end
local function dressCell(c, sk, grain)
    if grain then
        c.bg:SetTexture(grain.tex)
        local co = grain.coord
        if co then c.bg:SetTexCoord(co[1], co[2], co[3], co[4]) end
    else
        c.bg:SetTexCoord(0, 1, 0, 1)
        c.bg:SetVertexColor(1, 1, 1, 1)
    end
    local mf = sk.markFont
    for k = 1, 9 do
        local fs = c.mark[k]
        if mf then
            ns.SetFont(fs, mf.font, mf.size, mf.outline)
        else
            fs:SetFontObject(MARK_FONT)
        end
    end
end
local function resetCell(c)
    ns.ResetCell(c)
    for k = 1, 9 do c.mark[k]:Hide() end
    c._num, c._out = nil, nil
    c:SetAlpha(1)
end
local probe
local probed = {}
local function haveTexture(path)
    if probed[path] ~= nil then return probed[path] end
    if not probe then
        local f = ns.NewFrame("Frame", nil, UIParent)
        f:Hide()
        probe = f:CreateTexture(nil, "BACKGROUND")
    end
    local ok = probe:SetTexture(path) and true or false
    probed[path] = ok
    if not ok then ns.say(ns.T("sudoku.sayTextureMissing", path)) end
    return ok
end
function Game:ApplySkin()
    if not ui or not self.cells then return end
    local sk = self.sk
    local grain = sk.grain and haveTexture(sk.grain.tex) and sk.grain or nil
    self.grain = grain
    local function dress(f, inset)
        f:SetBackdrop{
            bgFile = grain and grain.tex or SOLID_TEX,
            edgeFile = sk.edge.file,
            tile = false,
            edgeSize = sk.edge.size,
            insets = { left = inset, right = inset, top = inset, bottom = inset },
        }
        local p, e = sk.panel, sk.edge.color
        f:SetBackdropColor(p[1], p[2], p[3], p[4] or 1)
        f:SetBackdropBorderColor(e[1], e[2], e[3], e[4] or 1)
        f:Show()
    end
    local scr = sk.screen
    ns.Paint(ui.screen.tex, scr[1], scr[2], scr[3], 1)
    ui.screen:Show()
    dress(ui.board, 4)
    dress(ui.boardPal, 3)
    local hov, key = sk.curHover, sk.curKey
    ui.hl:SetBackdropBorderColor(hov[1], hov[2], hov[3], 1)
    ui.kb:SetBackdropBorderColor(key[1], key[2], key[3], 1)
    for i = 1, 81 do dressCell(self.cells[i], sk, grain) end
    for k = 1, 9 do dressCell(self.pals[k], sk, grain) end
end
function Game:PickSkin(key)
    if ns.Loop.Current() ~= self or not self.cells then return end
    local sk, real = ns.SudokuSkin(key)
    if real == self.skinKey then return end
    self.sk, self.skinKey = sk, real
    ns.Store.SetSkin(ID, real)
    for i = 1, 81 do
        local c = self.cells[i]
        c._num, c._out, c._style = nil, nil, nil
    end
    for k = 1, 9 do
        local c = self.pals[k]
        c._num, c._out, c._style = nil, nil, nil
    end
    self:ApplySkin()
    self:Draw()
    self._panelSkin = nil
    self:PanelSync()
end
local function buildUI(canvas)
    local u = {}
    u.side = ns.NewFrame("Frame", nil, canvas)
    u.side:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", PAL_X, OY)
    u.side:SetWidth(PAL_W)
    u.side:SetHeight(FIELD)
    u.tally = ns.MakeScoreboard(u.side, PAL_W)
    u.tally:SetPoint("TOPLEFT", u.side, "TOPLEFT", 0, 0)
    u.tally:Notices(u.side, 0, TROW)
    local function counter(y, capKey)
        local row = {}
        row.cap = u.side:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.cap:SetPoint("BOTTOMLEFT", u.side, "BOTTOMLEFT", 0, y)
        row.cap:SetText(ns.T(capKey))
        row.val = u.side:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.val:SetJustifyH("RIGHT")
        row.val:SetPoint("BOTTOMRIGHT", u.side, "BOTTOMRIGHT", 0, y)
        return row
    end
    u.status = counter(171, "sudoku.leftCap")
    u.hints = counter(155, "sudoku.hintsCap")
    u.lvl = ns.MakeStepper(u.side)
    u.lvl:SetWidth(PAL_W); u.lvl:SetHeight(20)
    u.lvl:SetPoint("BOTTOMLEFT", u.side, "BOTTOMLEFT", 0, 26)
    u.skin = ns.MakeSelect(u.side)
    u.skin:SetWidth(PAL_W); u.skin:SetHeight(20)
    u.skin:SetPoint("BOTTOMLEFT", u.side, "BOTTOMLEFT", 0, 0)
    u.skin.tip = ns.T("sudoku.skinTip")
    u.skin.onPick = function(key) if cur then cur:PickSkin(key) end end
    local function unpause()
        if not ns.Loop.IsPaused() then return false end
        ns.Loop.Resume()
        ns.window:RefreshHead()
        return true
    end
    u.note = ns.MakeKitButton(canvas)
    u.note:SetWidth(PAL_W)
    u.note:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", PAL_X, 139)
    u.note:SetText(ns.T("sudoku.noteButton"))
    u.note.tip = ns.T("sudoku.noteTip")
    u.note.onClick = function()
        if unpause() then return end
        if cur and not cur.won and canNote(cur) then cur:Move{ k = "note" } end
    end
    u.hint = ns.MakeKitButton(canvas)
    u.hint:SetWidth(PAL_W)
    u.hint:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", PAL_X, 113)
    u.hint:SetText(ns.T("sudoku.hintButtonFmt", ns.Records.Span(HINT_COST)))
    u.hint.tip = ns.T("sudoku.hintTipFmt", ns.Records.Span(HINT_COST))
    u.hint.onClick = function()
        if unpause() then return end
        if cur and not cur.won then cur:Move{ k = "hint" } end
    end
    local function border()
        local f = ns.NewFrame("Frame", nil, canvas)
        f:SetFrameLevel(canvas:GetFrameLevel() + 6)
        f:SetBackdrop({ edgeFile = EDGE_TEX, edgeSize = 12 })
        f:SetWidth(CELL + 6)
        f:SetHeight(CELL + 6)
        f:Hide()
        return f
    end
    local function board(w, h)
        local f = ns.NewFrame("Frame", nil, canvas)
        f:SetFrameLevel(canvas:GetFrameLevel() + 1)
        f:SetWidth(w)
        f:SetHeight(h)
        f:Hide()
        return f
    end
    u.screen = ns.NewFrame("Frame", nil, canvas)
    u.screen:SetFrameLevel(canvas:GetFrameLevel())
    u.screen:SetAllPoints(canvas)
    u.screen.tex = ns.window:ScreenFill(u.screen)
    u.screen:Hide()
    u.board = board(FIELD + BOARD_EDGE * 2, FIELD + BOARD_EDGE * 2)
    u.board:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", OX - BOARD_EDGE, OY - BOARD_EDGE)
    u.boardPal = board(PAL_W + PAL_EDGE * 2, PAL_W + PAL_EDGE * 2)
    u.boardPal:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", PAL_X - PAL_EDGE, PAL_Y - PAL_EDGE)
    u.hl = border()
    u.kb = border()
    u.flash = ns.NewFrame("Frame", nil, canvas)
    u.flash:SetFrameLevel(canvas:GetFrameLevel() + 8)
    u.flash:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", OX, OY)
    u.flash:SetWidth(FIELD)
    u.flash:SetHeight(FIELD)
    u.flash.tex = u.flash:CreateTexture(nil, "OVERLAY")
    u.flash.tex:SetAllPoints(u.flash)
    u.flash.tex:SetTexture(HL_TEX)
    u.flash.tex:SetBlendMode("ADD")
    u.flash:Hide()
    return u
end
function Game:Build()
    local canvas = self.canvas
    pool = pool or ns.NewPool(function() return makeCell(canvas) end, resetCell)
    palPool = palPool or ns.NewPool(function() return makeCell(canvas) end, resetCell)
    ui = ui or buildUI(canvas)
    local lvl = canvas:GetFrameLevel() + 3
    pool:Reset()
    self.cells = {}
    for i = 1, 81 do
        local c = pool:Acquire()
        c:SetWidth(CELL)
        c:SetHeight(CELL)
        c:SetFrameLevel(lvl)
        c:ClearAllPoints()
        local x, y = cellXY(i)
        c:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y)
        self.cells[i] = c
    end
    pool:HideExtras()
    palPool:Reset()
    self.pals = {}
    for k = 1, 9 do
        local c = palPool:Acquire()
        c:SetWidth(PAL)
        c:SetHeight(PAL)
        c:SetFrameLevel(lvl)
        c:ClearAllPoints()
        local x, y = palXY(k)
        c:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x, y)
        self.pals[k] = c
    end
    palPool:HideExtras()
    ui.board:ClearAllPoints()
    ui.board:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", OX - BOARD_EDGE, OY - BOARD_EDGE)
    ui.flash:ClearAllPoints()
    ui.flash:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", OX, OY)
    ui.boardPal:ClearAllPoints()
    if miniOn then
        ui.boardPal:SetWidth(MINI_PAL_W + PAL_EDGE * 2)
        ui.boardPal:SetHeight(PAL + PAL_EDGE * 2)
        ui.boardPal:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", MINI_PAL_X - PAL_EDGE, MINI_PAL_Y - PAL_EDGE)
        ui.note:Hide()
        ui.hint:Hide()
        ui.side:Hide()
    else
        ui.boardPal:SetWidth(PAL_W + PAL_EDGE * 2)
        ui.boardPal:SetHeight(PAL_W + PAL_EDGE * 2)
        ui.boardPal:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", PAL_X - PAL_EDGE, PAL_Y - PAL_EDGE)
        ui.note:Show()
        ui.hint:Show()
        ui.side:Show()
    end
    self:ApplySkin()
end
local function paint(c, col, grain)
    if grain then
        c.bg:SetVertexColor(col[1], col[2], col[3], col[4] or 1)
    else
        ns.Paint(c.bg, col[1], col[2], col[3], col[4])
    end
end
local function setDigit(c, txt, sk)
    local want = (sk.font or "") .. "#" .. sk.outline
    if c._num == txt and c._out == want then return end
    c._num, c._out = txt, want
    ns.CellCenter(c, txt)
    if txt and (sk.font or sk.outline ~= "THICKOUTLINE") then
        local font, size = c.center:GetFont()
        if size then
            ns.SetFont(c.center, sk.font or font, size, sk.outline ~= "" and sk.outline or nil)
        end
    end
end
function Game:Relocalize()
    if not ui then return end
    ui.skin.tip = ns.T("sudoku.skinTip")
    ui.note:SetText(ns.T("sudoku.noteButton"))
    ui.note.tip = ns.T("sudoku.noteTip")
    ui.hint:SetText(ns.T("sudoku.hintButtonFmt", ns.Records.Span(HINT_COST)))
    ui.hint.tip = ns.T("sudoku.hintTipFmt", ns.Records.Span(HINT_COST))
    self._panelLock, self._panelSkin = nil, nil
    self:PanelSync()
    self:Draw()
end
function Game:Draw()
    if not self.cells then return end
    local focus = self.hover or self.cur
    local lit = {}
    if focus then
        for _, j in ipairs(CROSS[focus]) do lit[j] = true end
        lit[focus] = true
    end
    local left = {}
    for c = 1, 9 do left[c] = 9 end
    local sk = self.sk
    local grain = self.grain
    for i = 1, 81 do
        local c = self.cells[i]
        local g, p = self.given[i], self.put[i]
        local v = (g ~= 0) and g or p
        if v ~= 0 then left[v] = left[v] - 1 end
        if self.conf[i] then paint(c, sk.bgConf, grain)
        elseif v ~= 0 and v == self.pick then paint(c, sk.bgPick, grain)
        elseif g ~= 0 then paint(c, sk.bgGiven, grain)
        elseif lit[i] then paint(c, sk.bgLit, grain)
        elseif sk.bgAlt and BLOCK_ODD[i] then paint(c, sk.bgAlt, grain)
        else paint(c, sk.bgEmpty, grain) end
        ns.StyleCell(c, (g ~= 0 and sk.frameGiven) and "framed" or "plain")
        if v ~= 0 then
            setDigit(c, DIGIT[v], sk)
            if g ~= 0 then
                c.center:SetTextColor(sk.fgGiven[1], sk.fgGiven[2], sk.fgGiven[3])
            elseif self.conf[i] then
                c.center:SetTextColor(sk.fgConf[1], sk.fgConf[2], sk.fgConf[3])
            else
                c.center:SetTextColor(sk.fgMine[1], sk.fgMine[2], sk.fgMine[3])
            end
            for k = 1, 9 do c.mark[k]:Hide() end
        else
            setDigit(c, nil, sk)
            local m = self.mark[i]
            for k = 1, 9 do
                local fs = c.mark[k]
                if m and m[k] then
                    if k == self.pick then
                        fs:SetTextColor(sk.fgMarkPick[1], sk.fgMarkPick[2], sk.fgMarkPick[3])
                    else
                        fs:SetTextColor(sk.fgMark[1], sk.fgMark[2], sk.fgMark[3])
                    end
                    fs:Show()
                else
                    fs:Hide()
                end
            end
        end
    end
    for k = 1, 9 do
        local c = self.pals[k]
        local off = left[k] <= 0
        ns.StyleCell(c, (k == self.pick) and "framed" or "plain")
        paint(c, (k == self.pick) and sk.bgPick
            or (off and sk.palOffBg) or sk.bgEmpty, grain)
        setDigit(c, DIGIT[k], sk)
        local fg = off and sk.palOffFg or sk.fgMine
        c.center:SetTextColor(fg[1], fg[2], fg[3])
        ns.CellCount(c, (left[k] > 0) and left[k] or nil)
    end
    self:Cursor()
    if self.won then
        ui.status.cap:SetText(ns.T("sudoku.statusWon"))
        ui.status.val:SetText("")
    else
        ui.status.cap:SetText(ns.T("sudoku.leftCap"))
        ui.status.val:SetText(81 - self.filled)
    end
    local used = self.hints > 0
    ui.hints.cap:SetText(used and ns.T("sudoku.hintsCap") or "")
    ui.hints.val:SetText(used and self.hints or "")
    if self.won then
        ui.note:Disable()
        ui.note.tipDim = ns.T("sudoku.tipDimWon")
    elseif not canNote(self) then
        ui.note:Disable()
        ui.note.tipDim = ns.T("sudoku.tipDimNoNote")
    else
        ui.note:Enable()
        ui.note.tipDim = nil
    end
    if self.won then
        ui.hint:Disable()
        ui.hint.tipDim = ns.T("sudoku.tipDimWon")
    else
        ui.hint:Enable()
        ui.hint.tipDim = nil
    end
end
function Game:Cursor()
    local canvas = self.canvas
    local function put(f, i)
        if not i then
            f:Hide()
            return
        end
        local x, y = cellXY(i)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", x - 3, y - 3)
        f:Show()
    end
    put(ui.hl, (not self.won) and self.hover or nil)
    put(ui.kb, (not self.won) and self.cur or nil)
end
function Game:Hover()
    local canvas = self.canvas
    local i
    if not ns.Help.IsShown() then
        local left, bottom = canvas:GetLeft(), canvas:GetBottom()
        local scale = canvas:GetEffectiveScale()
        if left and bottom and scale and scale > 0 then
            local mx, my = GetCursorPosition()
            i = cellAt(mx / scale - left, my / scale - bottom)
        end
    end
    if i == self.hover then return end
    self.hover = i
    self:Draw()
end
function Game:Flash()
    if not ui then return end
    local p = (self.t - (self.wonAt or 0)) / WIN_FLASH
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    local a = (p < 0.2) and (p / 0.2) or ((1 - p) / 0.8)
    ui.flash.tex:SetAlpha(a * 0.7)
    ui.flash:Show()
end
local MINI_EMPTY = { 0.16, 0.145, 0.12, 1 }
local MINI_GIVEN = { 0.25, 0.21, 0.135, 1 }
local MINI_ROW   = { 0.23, 0.25, 0.34, 1 }
local MINI_COL   = { 0.30, 0.26, 0.13, 1 }
local MINI_BOX   = { 0.17, 0.28, 0.21, 1 }
local MINI_CONF  = { 0.55, 0.10, 0.10, 1 }
local INK_GIVEN  = { 1.00, 0.94, 0.78 }
local INK_MINE   = { 0.45, 0.78, 1.00 }
local INK_CONF   = { 1.00, 0.88, 0.88 }
local MINI = {
    {
        cols = 9, rows = 9, cell = 20, gap = 1, back = "plain",
        fill = {
            { c = 1, r = 5, col = MINI_ROW }, { c = 2, r = 5, col = MINI_ROW },
            { c = 3, r = 5, col = MINI_ROW }, { c = 4, r = 5, col = MINI_ROW },
            { c = 5, r = 5, col = MINI_ROW }, { c = 6, r = 5, col = MINI_ROW },
            { c = 7, r = 5, col = MINI_ROW }, { c = 8, r = 5, col = MINI_ROW },
            { c = 9, r = 5, col = MINI_ROW },
            { c = 2, r = 1, col = MINI_COL }, { c = 2, r = 2, col = MINI_COL },
            { c = 2, r = 3, col = MINI_COL }, { c = 2, r = 4, col = MINI_COL },
            { c = 2, r = 5, col = MINI_COL }, { c = 2, r = 6, col = MINI_COL },
            { c = 2, r = 7, col = MINI_COL }, { c = 2, r = 8, col = MINI_COL },
            { c = 2, r = 9, col = MINI_COL },
            { c = 7, r = 7, col = MINI_BOX }, { c = 8, r = 7, col = MINI_BOX },
            { c = 9, r = 7, col = MINI_BOX }, { c = 7, r = 8, col = MINI_BOX },
            { c = 8, r = 8, col = MINI_BOX }, { c = 9, r = 8, col = MINI_BOX },
            { c = 7, r = 9, col = MINI_BOX }, { c = 8, r = 9, col = MINI_BOX },
            { c = 9, r = 9, col = MINI_BOX },
        },
    },
    {
        cols = 3, rows = 3, cell = 30, gap = 1, back = "plain",
        fill = {
            { c = 2, r = 3, col = MINI_GIVEN },
            { c = 1, r = 1, col = MINI_CONF }, { c = 3, r = 3, col = MINI_CONF },
        },
        text = {
            { c = 2, r = 3, s = "7", col = INK_GIVEN },
            { c = 3, r = 2, s = "2", col = INK_MINE },
            { c = 1, r = 1, s = "5", col = INK_CONF },
            { c = 3, r = 3, s = "5", col = INK_CONF },
        },
    },
}
local function paintMini(host, spec)
    local g = ns.MiniGrid(host, spec.cols, spec.rows, spec.cell, spec.gap)
    ns.MiniPlain(g, MINI_EMPTY)
    for _, m in ipairs(spec.fill or {}) do g:Fill(m.c, m.r, m.col) end
    for _, m in ipairs(spec.text or {}) do g:Text(m.c, m.r, m.s, m.col) end
end
local function helpAreas(host) paintMini(host, MINI[1]) end
local function helpInk(host) paintMini(host, MINI[2]) end
ns.RegisterGame{
    id = ID,
    label = "sudoku.label",
    icon = { draw = ns.SudokuTileIcon },
    tip = "sudoku.tip",
    order = 5,
    duo = "score",
    physics = false,
    done = true,
    ownPanel = true,
    tally = false,
    look = LOOK,
    mini = { w = MINI_W, h = MINI_H },
    finale = true,
    New = New,
    opts = {
        { key = "level", label = "sudoku.optLevelLabel", def = DEFAULT_LEVEL,
          ordered = true, options = LEVELS,
          tip = "sudoku.optLevelTip" },
    },
    record = {
        { key = "time",  label = "sudoku.recTime", by = "min", mark = "clock", format = "span" },
    },
    keymap = {
        LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
        SPACE = "fire", ["SHIFT-SPACE"] = "mark",
        ["1"] = "num1", ["2"] = "num2", ["3"] = "num3",
        ["4"] = "num4", ["5"] = "num5", ["6"] = "num6",
        ["7"] = "num7", ["8"] = "num8", ["9"] = "num9",
    },
    controls = {
        { action = "left",  mouse = false },
        { action = "right", mouse = false },
        { action = "up",    mouse = false },
        { action = "down",  mouse = false },
        { action = "fire",  label = "sudoku.ctlPut",   mouse = "LMB" },
        { action = "mark",  label = "sudoku.ctlMark",  mouse = "RMB" },
        { action = "num1",  label = "sudoku.ctlDigit", keys = "sudoku.ctlDigits", mouse = "LMB", where = "sudoku.ctlOnPalette" },
    },
    help = {
        "sudoku.help1",
        { art = helpAreas, h = 194, sub = "sudoku.helpAreasSub" },
        { icon = ASK_TEX, coord = { 0, 1, 0, 1 },
          t = "sudoku.help2" },
        "sudoku.help2Sub",
        { icon = OK_TEX, coord = { 0, 1, 0, 1 },
          t = "sudoku.help3" },
        "sudoku.help3Sub",
        "sudoku.help4",
        { art = helpInk, h = 102 },
        "sudoku.help5",
        "sudoku.help6",
        { icon = ASK_TEX, coord = { 0, 1, 0, 1 },
          t = "sudoku.help7" },
        "sudoku.help7Sub",
        "sudoku.help8",
    },
}
BANK = {
    ["easy"] = {
        "000000093300028500807059400623800000045902760000004235001490307006280009780000000562741893394628571817359426623875914145932768978164235251496387436287159789513642",
        "098000000001098765000310902124086500300040008009730241507023000982470300000000420298567134431298765756314982124986573375142698869735241547623819982471356613859427",
        "035080900608004130000703080002007090307549201040200700020105000053400609009060420235681947678954132194723586562817394387549261941236758426195873853472619719368425",
        "000006208100000500000203170601748020045609830080135407067902000008000002203400000379516248126874593854293176631748925745629831982135467567982314498361752213457689",
        "000900070702040000640310000860201903030654080204803067000085091000030406090002000153928674782546319649317258865271943937654182214893567326485791578139426491762835",
        "006501003000060789000730610040105067605208401180306050019054000268010000400807100976581243531462789824739615342195867695278431187346952719654328268913574453827196",
        "000001040591043200000050701400009508010504060609100007906010000007360159020900000762891345591743286384256791473629518218574963659138427936415872847362159125987634",
        "000057402020000070803240105108470000350902041000031809205064907010000080409710000961857432524193678873246195198475263356982741742631859285364917617529384439718526",
        "010000605860710002023600070351208046000104000490503128040001280500036017109000060714382695865719432923645871351298746278164359496573128647951283582436917139827564",
        "003508162607090000000046750540800610000050000028001045086710000000080506975403200493578162657192438812346759549827613361954827728631945286715394134289576975463281",
        "290006000050004706063800520709165000000000000000938604015009380904700060000600059297516843158324796463897521749165238836472915521938674615249387984753162372681459",
        "000590040536000100002300076100703062207961405960204007640007300005000684010045000871596243536472198492318576154783962287961435963254817649827351725139684318645729",
        "100026000006070390030409016007040900308090701002010800260804070091060400000930005189326547426175398735489216617548932348692751952713864263854179591267483874931625",
        "006340570000082004900001003720000341090803020361000058600400009200160000084025700816349572573682194942751863728596341495813627361274958657438219239167485184925736",
        "019008076300960140502010003000500034007102600850009000200090307086073009790400260419328576378965142562714893621587934937142685854639721245896317186273459793451268",
        "003190005010800064200507813100740030704000502030028001371209006980001020400073100863194275517832964249567813128745639794316582635928741371289456986451327452673198",
        "000200030160900254020740190009004720000392000042600900083076010496003072010009000954261837167938254328745196639854721871392645542617983283576419496183572715429368",
        "243500680000400307180030495072105000000020000000804270529010064604007000038006152243579681965481327187632495872165943496723518351894276529318764614257839738946152",
        "050000081023050900001000250000821060608397502090546000034000600009030820570000030956273481423158976781964253345821769618397542297546318834712695169435827572689134",
        "063012900178000002000006138936100200000793000004005389391400000200000453005230890563812947178349562429576138936184275852793614714625389391458726287961453645237891",
        "719050040308600029000013708000506087000000000680709000802460000540001602060020894719258346358674129426913758231546987975182463684739215892467531543891672167325894",
        "200900000759300010001752036900806070100090008040105009690521800010007592000009001236914785759368214481752936925846173167293458348175629693521847814637592572489361",
        "408300790210000506900010204694078000000000000000630479702040008506000047049007302468352791217489536953716284694578123371294865825631479732945618586123947149867352",
        "000701030000069784980024560000000140103040806098000000035290017812470000040605000564781932321569784987324561256837149173942856498156273635298417812473695749615328",
        "000590207078032004509000018086204701000060000304907620740000106100470580802015000431598267678132954529746318986254731257361849314987625745823196163479582892615473",
        "800200030700301024200090507900536702000080000502147008108020005340809001020003009814275936759361824263498517981536742476982153532147698198624375347859261625713489",
        "260804030700000040405006800621350008000000000500021673007600902040000007030209084269814735783592146415736829621357498374968251598421673857643912942185367136279584",
        "005020030002900047003870502021080093300501006670090150906058700140009300050010900765124839812935647493876512521687493389541276674392158936458721147269385258713964",
        "007005200460900003020000186300080420900734008046050007293000060700001035001300700137865294468912573529473186375186429912734658846259317293547861784621935651398742",
        "209800003050100400013020009502006307001592600604300205300050940007003020900008706279864153856139472413725869592486317731592684684371295328657941167943528945218736",
    },
    ["normal"] = {
        "000108025006007003010290004000021900090000050008750000400012030700900200180304000974138625826547193315296874537421986291863457648759312459612738763985241182374569",
        "010038070034600800600500200000000907040060030805000000006005004003006180090280050912438675534627891678519243321854967749162538865973412186395724253746189497281356",
        "408005900030600000600000380097052004000090000500160270041000003000007050003400701478235916139678542625941387397852164216794835584163279741589623962317458853426791",
        "000600009020389000009000700100730905870090021905061007007000500000857030600003000483675219721389654569142783142738965876594321935261847317426598294857136658913472",
        "090630050000072900200000800109400003030209080400003706006000009004390000070026040798634152615872934243915867169487523537269481482153796356748219824391675971526348",
        "190050760000060090600000003000025004510070039400690000300000002020030000061080075194253768253768491678149523789325614516874239432691857347516982825937146961482375",
        "800050002000001705530200401000900020004000900080002000705008019308500000200010007871459632462831795539276481657943128124785963983162574745628319318597246296314857",
        "006004070007000000430007506080405002600090007200803050109500028000000900070100400526314879917658243438927516783465192654291387291873654149536728865742931372189465",
        "200070403036500200070003001004089000009000600000160800700600020002005170501090006218976453936541287475823961164289735829357614357164892743618529692435178581792346",
        "600700300400001600000206097058000001700000004100000760270903000001600003003004002629745318487391625315286497958467231736129854142538769274953186891672543563814972",
        "130079000078000001450000076805340000000020000000068502640000095500000620000530084136479258978652431452813976825341769764925813319768542641287395583194627297536184",
        "060300019005008003000010570640120000200000001000084067036070000500400700420001030762345819915768423384219576649127358278653941153984267836572194591436782427891635",
        "040009000068000354000006091002070060400000007070030200580400000297000540000900070741359628968712354325846791832571469456298137179634285583467912297183546614925873",
        "375060480200300000000000307000003004608070205700500000107000000000002001032090578375169482284357196961248357529813764618974235743526819197485623856732941432691578",
        "900001300600005790308000204000068000002000800000940000809000107067100003003700005974821356621435798358679214795268431432517869186943572849356127567182943213794685",
        "320090806000008000000000275000046008017000920400970000253000000000700000804030052321597846745268319986314275592146738617853924438972561253481697169725483874639152",
        "005460070000000005089003406050800600208000307006005080504300720800000000090027800325461978461978235789253416157832694248619357936745182514386729872194563693527841",
        "790060003000300410100090760009003004015080970400900300061030007037005000900070032794168253856327419123594768689753124315482976472916385561239847237845691948671532",
        "805007002000086475007002030009030000620000083000010500030700800796820000500400706865347912213986475947152638159638247624579183378214569432765891796821354581493726",
        "600000000408163002050000063000058000005621800000740000540000080900482701000000009613295478478163592259874163164358927795621834382749615541937286936482751827516349",
        "010049000000102000006000104061700500020508040008006710107000600000907000000460050813649275574182963296375184361794528729518346458236719147853692685927431932461857",
        "000000050800120307307000040200006500059000620001300004090000705403075001070000000916437852845129367327568149234796518759841623681352974192684735463975281578213496",
        "053001090004000300800300014092530000000010000000092730420006003006000900030800640253471896614289357879365214792538461368714529145692738427956183586143972931827645",
        "008001050210060800000400070300000960009604500052000008040008000006090084030200700498721653217563849563489172374852961189634527652917438945378216726195384831246795",
        "908310000050000090000009807600083000470090086000470002805700000040000020000034905968317254257648391134259867612583479473192586589476132895721643341965728726834915",
        "200014037000078500008000010030000169000030000812000070080000300007480000420950006259614837146378592378295614735842169694137258812569473981726345567483921423951786",
        "000004009400060013000500060080001506005608900109300080020005000570020008300100000613784259457962813892513764784291536235648971169357482926835147571426398348179625",
        "070020900000405700000006080903000800057204130006000205030600000002308000001050040478123956369485721215796483923571864857264139146839275734612598592348617681957342",
        "000800607004300080000040090850062004010000060900180023080030000090005800306008000539821647174396285628547391853962174412753968967184523785639412291475836346218759",
        "000010240000209305003040600470001002000000000500900064008020500709804000015090000657318249184269375923745618476581932892436751531972864348127596769854123215693487",
    },
    ["hard"] = {
        "400050700010907085000080140070090000000702000000060050065020000780406030001070006498251763613947285527683149176598324954732618832164957365829471789416532241375896",
        "010000030080006000700030900009702500200504003005301700004050002000400080060000050412975836983146275756238941139782564278564193645391728894657312527413689361829457",
        "060004850001070240000000007008020090302000108090060700700000000083050400026100030267314859931578246845296317618723594372945168594861723759432681183659472426187935",
        "020081046000000000870450030105000080007060200090000305030048071000000000610970050923781546451326897876459132165293784387564219294817365532648971749135628618972453",
        "080000760000850200000000348020508000006020100000304080219000000003086000068000030982143765634857219157692348321568497846729153795314682219435876473986521568271934",
        "806237000540100000070400006002003000700806001000700500300002080000004092000985307816237954549168723273459816182543679735896241964721538397612485658374192421985367",
        "170205306020003000806000000200470000008000600000082001000000208000300040504701063179245386425863197836917524251476839748139652963582471397654218612398745584721963",
        "060800000000607841070003002046000005050000080900000370400100030591306000000008010169824753235697841874513962346781295752439186918265374487152639591376428623948517",
        "010028000000000032020360000704002093001000500250800407000076050530000000000230040413728965678459132925361784784512693391647528256893417842976351539184276167235849",
        "020000000037209860000051000006007090080000040010600500000370000053906420000000030528763914137249865694851273246587391385192746719634582462378159853916427971425638",
        "004000061000001204000090805200050040009807500010020009401070000308100000590000300984532761753681294162794835237956148649817523815423679421375986378169452596248317",
        "000000020017800000206405000700160900690000017001098002000502408000009250080000000845931726917826534236475189728163945693254817451798362369512478174689253582347691",
        "006150307000002090502070000003000008750000012600000500000060804060800000304097100896154327471382695532679481243915768758436912619728543927561834165843279384297156",
        "004207000080010200000030014000043059000608000390570000750080000006050020000906500134267895689415273527839614268143759475698132391572486752384961946751328813926547",
        "040500800098071000100030000200100730010000090036007004000050007000210950003009020742596813398471562165832479289164735417385296536927184921658347674213958853749621",
        "001405000507008006206000100090040700700000009003070060009000508100300207000802600931465872547128936286937154692543781754681329813279465329716548168354297475892613",
        "620001003000070268850002040000100030002000800070008000010500086435060000700200054627481593941375268853692741598126437362754819174938625219547386435869172786213954",
        "400016030030007000075400000000000201001080500703000000000008140000300060090170002482516937639827415175439826568743291941682573723951684357268149214395768896174352",
        "809100000000007300072000400050080001094352860700040020005000190007500000000008702849135276516427389372869415253786941194352867768941523685273194927514638431698752",
        "200003700700001240000200001004000025090040070150000800900006000043900008006300007281493756735681249469275381374168925698542173152739864917856432543927618826314597",
        "009406005305082000000000002942700000100509004000001329600000000000270906700605200279416835315982467486357192942763581138529674567841329624198753853274916791635248",
        "000090800374650000050701004007000080920000037040000900400102090000034128001080000612493875374658219859721364537249681926815437148367952483172596765934128291586743",
        "010320040000050160800900200000000071600000002450000000007001003036070000080032090719326548342758169865914237923865471678143952451297386597481623236579814184632795",
        "200070000000109000097008600721000003503000406400000287005800120000304000000050008214675839856139742397248651721486593583792416469513287935867124178324965642951378",
        "000900064000000308000810000500020001024070850300080006000037000106000000950008000783952164215764398469813572598426731624371859371589246842637915136295487957148623",
        "000000081050200009006100304000070010302000405040090000509007800400008050860000000234769581158243769976185324685374912392816475741592638519627843427938156863451297",
        "060000010003900000108600040720038090600070005040160023010007809000006400080000030564783912273941568198652347721538694639274185845169723416327859352896471987415236",
        "001050936000000050005906004003600000000801000000009400900504700070000000142080600481257936369418257725936184213645879694871523857329461938564712576192348142783695",
        "007026300200003040000470900700009000056000490000300001001034000030200005005890700547926318269183547183475926712649853356718492498352671871534269934267185625891734",
        "050900060000030407608000000504070030000000000020010509000000108901080000060005090453927861192638457678451923514879236389562714726314589235796148941283675867145392",
    },
    ["expert"] = {
        "700005020000001700060070341800010000405000102000060005671040080009700000040100007714635928983421756562978341896512473435897162127364895671243589359786214248159637",
        "600000810000493020040010030060000300300701008005000070010020080030675000072000003693257814851493627247816539764582391329761458185934276416329785938675142572148963",
        "008000090000060004100293058200004000080050010000100007490678001600040000020000400368415792952867134147293658219784365784356219536129847493678521671542983825931476",
        "062008010008603000401000000000800006790000054800005000000000208000309500010200960962548713578613492431972685154897326793126854826435179649751238287369541315284967",
        "507060800000002000000005090085090130100503004034010270070400000000100000008050402547961823869732541312845697785294136126573984934618275271486359453129768698357412",
        "060100203090060050008000000000400530400603008016002000000000600020050070105006090564179283291368457738245961982417536457693128316582749873924615629851374145736892",
        "900000005040800610000410000600031800009000200003920006000083000027004060100000002971362485245879613836415927652731894789546231413928756564283179327194568198657342",
        "000608000108000700079000208917000000200906007000000329506000980002000105000302000325678491168294753479135268917523846283946517654781329536417982742869135891352674",
        "000007800903000000076300042800036004000708000100590008750001960000000705008900000421657839983142657576389142897236514345718296162594378754821963219463785638975421",
        "000030600100400050006900007030006700004593200001700080700009800010002006009080000957238614123467958486951327235816749874593261691724583762149835518372496349685172",
        "014006005509000000030007401007840000000503000000061700403600070000000804800700250714326985529418367638957421367849512142573698985261743453682179276195834891734256",
        "050090410712000030000280000003000720800000004071000500000048000090000857087050040658397412712564938349281675463815729825973164971426583536748291194632857287159346",
        "091007305000008000000003078089004030007000200030700860710400000000200000302800450891627345473518692526943178289164537647385219135792864718456923954231786362879451",
        "000005000107200300300010074004000006080403020600000400860050001009008207000900000498375162157246389326819574234597816981463725675182493862754931519638247743921658",
        "020400900000097600008001030000000065060175090380000000090300200003780000007004080526438971134597628978261534719823465462175893385649712891356247643782159257914386",
        "020070503500003700001200000700800400008020100005007002000004600003100007104030090826479513549613728371258964732861459498325176615947382287594631953186247164732895",
        "005100000309200004040070210000000300502408106001000000068090030900001802000006900275184693319265784846973215684517329592438176731629458468792531957341862123856947",
        "020004810000001250701000090800100000002030500000002004040000105095200000073800060526394817439781256781526493854167329962438571317952684248679135695213748173845962",
        "310900700058300049000800000000000007400706001500000000000008000790005360001003095316954782258317649974862513163589427429736851587421936635298174792145368841673295",
        "100000803040000000000820590080043900000000000005780040092056000000000030401000007129465873548937162673821594287643915364519728915782346792356481856174239431298657",
        "080000000100009470096072000000008006059000730200900000000720860023500007000000040782345619135869472496172358317458926859216734264937581941723865623584197578691243",
        "070020300001000000090418000100009500806030407007600001000364050000000800002080060578926314461753928293418675124879536856132497937645281789364152615297843342581769",
        "004002000000480036080007001800000060026000980040000007100600070790051000000200800654132798917485236283967451879523164326714985541896327132648579798351642465279813",
        "000005070600000003050280046000008025003906700810300000940061030100000004060800000234695871689417253751283946496178325523946718817352469948761532172539684365824197",
        "300090000000640100001008360100000843050000020946000001019500400005026000000010008364791285528643197791258364172965843853174926946832571619587432485326719237419658",
        "300960050050000600800000002690057000400000008000680079900000004001000030070031005314962857752348691869715342698257413427193568135684279983576124541829736276431985",
        "050008006100700200060090800001000004024010970900000500009070050005002009700800020457238196198764235362591847871925364524613978936487512289176453615342789743859621",
        "400001307003090000006000910000720400300010002007038000069000500000070600204600009492861357183597246576342918951726483348915762627438195769284531835179624214653879",
        "450900000009006800600005700070802410000000000086504030001200007002600100000001065457918623239746851618325794375892416924163578186574932861259347542637189793481265",
        "000016005060000930500000080805900000620040059000005408080000003074000020200190000798316245461582937532479186845937612627841359319265478186724593974653821253198764",
    },
    ["evil"] = {
        "000300096028160000600027005009000008000030000800000500400510009000092160910006000174385296528169473693427815749251638251638947836974521462513789385792164917846352",
        "040657080090180000500000000020000400450030061006000030000000004000094070080723090142657389793182546568349217321976458459238761876415932937561824215894673684723195",
        "000100730000500086003000001000018009007060100600230000200000500350004000091007000582196734149573286763842951425718369937465128618239475274681593356924817891357642",
        "005000070000010089040002100450200600060000020001003094008700050970030000030000700195348276326517489847962135453289617769451328281673594618724953974135862532896741",
        "800037000039005076500000400200000040000284000040000003001000005780900320000670009864137592139425876572896431217563948395284617648719253921348765786951324453672189",
        "360005071000060005009004000400309080000000000090106004000600200700030000810200063368925471142763895579814326451379682687452139293186754935648217726531948814297563",
        "394078010000501000020006000000000027060020040870000000000900030000703000040180579394278615786531294125496783431659827569827341872314956217965438958743162643182579",
        "005063002000000015040010000900005430400000006081600009000030060170000000500420900715963842693248715248517693962185437457392186381674259824739561179856324536421978",
        "009187000130000700000000400400008350300090004096400007002000000004000065000965800249187536135246798867359421421678359378592614596431287652814973984723165713965842",
        "009480050000090000380007000108900070002030500070008302000100093000070000060029100219483657457296831386517924138952476642731589975648312824165793591374268763829145",
        "000006050674030100003000400905004000800070009000200504007000300002090761060100000218746953674935182593821476925614837841573629736289514187462395452398761369157248",
        "090800150000700000100049068032000070000030000060000410650920001000008000019005020493862157286751934175349268932184675741536892568297413654923781327618549819475326",
        "070008009092003014030000800000109006000060000100207000004000060380500140500600030671428359892753614435916872257139486943865721168247593724381965386592147519674238",
        "800301000002090040610050009000900050400030001020005000300010078070080400000203006894321567752896143613457829136948752485732691927165384369514278271689435548273916",
        "005012084000900620200008000000600030100000007080003000000100006013009000590870300965312784348957621271468593752691438139584267486723159827135946613249875594876312",
        "000026078000000090063000005080400001071030950400009030500000180040000000130760000954126378718354692263987415389475261671832954425619837597243186846591723132768549",
        "004200000905000037106050200000008070000762000030400000009020704710000806000007100384279615925816437176354289641538972598762341237491568869123754713945826452687193",
        "800034002029000030034600000001008009000070000900400200000007160010000780300150004867934512129785436534612897741328659682579341953461278295847163416293785378156924",
        "200070403000800012309000050000400200900020004002008000090000706750009000108060005281675493574893612369142857835417269917326584642958371493581726756239148128764935",
        "000800007000490000430000050200704008670000013500302004090000046000035000800006000962851437157493682438627951213764598674589213589312764395278146746135829821946375",
        "500003070000050804900000020002500040070349080080007100030000008809060000010400002548213679327956814961874523692581347175349286483627195234195768859762431716438952",
        "000050700017008005600000301200509000500040002000302008301000009400700510008090000843251796917638245625974381286519437539847162174362958361425879492786513758193624",
        "009006007301000002080005001050200700004000800008003020600900040900000603800400200529146387361798452487325961156284739234579816798613524675932148942851673813467295",
        "580071040000006000017800000078000000005382400000000920000008360000700000040260057583971642429536781617824593278649135195382476364157928752418369836795214941263857",
        "030600700010800006600009508000006000800010002000700000907300004300002090002004030238645719519827346674139528791256483865413972423798165987361254346572891152984637",
        "060000903002030061000009000045000008000298000900000630000500000230060700506000040867412953492735861351689472145376298673298514928154637789543126234961785516827349",
        "009000400000059000860200700600007003907010804200400005001003048000740000006000100139876452472159386865234791684597213957312864213468975791623548528741639346985127",
        "000905008890006070000000006406507090000030000030408705200000000010600029700302000674925138893146572521783946486517293157239684932468715249851367315674829768392451",
        "700000030040200006310800000026000010000509000070000340000008074200001090050000008762495831948213756315867429826734915134529687579186342691358274287641593453972168",
        "001500000036000021000030000090460007750000016600017080000040000910000340000009800481572693536894721279631458198465237754328916623917584865243179912786345347159862",
    },
}
