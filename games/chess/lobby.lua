local ADDON, ns = ...
local ID = "chess"
local floor = math.floor
ns.ChessRooms = {}
ns.ChessLobby = {}
local R = ns.ChessRooms
local L = ns.ChessLobby
local MAX_ROOMS = 12
local VIS = 5
local function all()
    local t = ns.Config.Get(ID, "rooms", nil)
    if type(t) ~= "table" then t = {} end
    return t
end
local function save(t)
    ns.Config.Set(ID, "rooms", t)
end
local function keyOf(mid)
    if type(mid) ~= "number" then return nil end
    return tostring(mid)
end
function R.List()
    local out = {}
    for _, r in pairs(all()) do
        if type(r) == "table" and type(r.mid) == "number"
            and (type(r.peer) == "string" or r.solo) then
            out[#out + 1] = r
        end
    end
    table.sort(out, function(a, b)
        local am, bm = R.Mine(a), R.Mine(b)
        if am ~= bm then return am end
        return (a.at or 0) > (b.at or 0)
    end)
    return out
end
function R.Mine(r)
    if r.over then return false end
    if r.solo then return true end
    local turn = ((r.n or 0) % 2 == 0) and 1 or 2
    return turn == (r.side or 1)
end
function R.Get(mid)
    local k = keyOf(mid)
    return k and all()[k] or nil
end
function R.ByPeer(name)
    local who = ns.Link.Norm(name)
    if not who then return nil end
    for _, r in pairs(all()) do
        if type(r) == "table" and ns.Link.Norm(r.peer) == who and not r.over then
            return r
        end
    end
    return nil
end
local function trim(t)
    local list = {}
    for k, r in pairs(t) do list[#list + 1] = { k = k, r = r } end
    if #list <= MAX_ROOMS then return end
    table.sort(list, function(a, b)
        local ao, bo = a.r.over and 1 or 0, b.r.over and 1 or 0
        if ao ~= bo then return ao > bo end
        return (a.r.at or 0) < (b.r.at or 0)
    end)
    for i = 1, #list - MAX_ROOMS do t[list[i].k] = nil end
end
function R.Put(blk)
    local k = keyOf(blk.mid)
    if not k then return end
    local t = all()
    local r = t[k] or {}
    for key, v in pairs(blk) do r[key] = v end
    r.at = blk.at or time()
    t[k] = r
    trim(t)
    save(t)
end
function R.Drop(mid)
    local k = keyOf(mid)
    if not k then return end
    local t = all()
    local r = t[k]
    t[k] = nil
    save(t)
    local rec = ns.Store.Load(ID)
    if r and rec and rec.seed == (r.seed or r.mid) then
        ns.Store.Clear(ID)
    end
end
function R.Sync(mid, peer, side)
    if not keyOf(mid) then return end
    ns.window:SaveCurrent()
    local rec = ns.Store.Load(ID)
    if not rec then return end
    local moves = rec.moves or {}
    R.Put{
        mid = mid, peer = peer, side = side,
        seed = rec.seed, moves = moves, n = #moves, at = time(),
    }
end
function R.Begin(mid, peer, side)
    R.Put{ mid = mid, peer = peer, side = side, seed = mid, moves = {}, n = 0,
        at = time() }
end
function R.Solo()
    local mid = time()
    R.Put{ mid = mid, solo = true, side = 1, seed = mid, moves = {}, n = 0,
        at = mid }
    R.Open(mid)
end
function R.Open(mid)
    local r = R.Get(mid)
    if not r then return false end
    ns.Store.Save(ID, r.seed or mid, r.moves or {}, nil)
    if r.solo then
        ns.Store.SetDuo(ID, nil)
    else
        ns.Store.SetDuo(ID, {
            peer = r.peer, mid = r.mid, side = r.side, n = r.n or #(r.moves or {}),
            at = r.at,
        })
    end
    R.opening = mid
    L.Hide()
    ns.window:StartGame(ID, nil, true)
    return true
end
local function online(name)
    local who = ns.Link.Norm(name)
    if not who then return nil end
    local low = who:lower()
    local nf = ns.Compat.NumFriends()
    for i = 1, nf do
        local nm, connected = ns.Compat.FriendInfo(i)
        if type(nm) == "string" and nm:lower() == low then return connected and true or false end
    end
    if IsInGuild and IsInGuild() then
        local ng = GetNumGuildMembers and GetNumGuildMembers() or 0
        for i = 1, ng do
            local nm, _, _, _, _, _, _, _, on = GetGuildRosterInfo(i)
            if type(nm) == "string" and nm:lower() == low then return on and true or false end
        end
    end
    return nil
end
local ui
local C_NICHE = { 0.075, 0.062, 0.045, 1 }
local C_EDGE  = { 0.29, 0.24, 0.14, 1 }
local C_CAP   = { 0.54, 0.51, 0.45 }
local C_TEXT  = { 0.91, 0.90, 0.86 }
local C_SOFT  = { 0.65, 0.61, 0.53 }
local C_DIM   = { 0.43, 0.40, 0.35 }
local C_GOLD  = { 1.00, 0.82, 0.00 }
local C_LIVE  = { 0.44, 0.75, 0.36 }
local C_GONE  = { 0.48, 0.45, 0.39 }
local ROW_H, ROW_STEP = 62, 70
local function text(parent, x, y, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    fs:SetJustifyH("LEFT")
    return fs
end
local function plate(parent, col)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(parent)
    ns.Paint(t, col[1], col[2], col[3], col[4] or 1)
    return t
end
local function outline(f, col)
    local function bar(p1, p2, w, h)
        local t = f:CreateTexture(nil, "BORDER")
        ns.Paint(t, col[1], col[2], col[3], col[4] or 1)
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    bar("TOPLEFT", "TOPRIGHT", nil, 1)
    bar("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    bar("TOPLEFT", "BOTTOMLEFT", 1, nil)
    bar("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end
local function build(canvas)
    if ui then
        ui.canvas = canvas
        return
    end
    ui = {}
    ui.canvas = canvas
    ui.frame = ns.NewFrame("Frame", nil, canvas)
    ui.frame:SetFrameLevel(canvas:GetFrameLevel() + 10)
    ui.frame:SetAllPoints(canvas)
    ui.frame:EnableMouse(true)
    ui.frame:Hide()
    local scr = ns.window:ScreenFill(ui.frame)
    scr:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementBackground")
    scr:SetVertexColor(0.230, 0.190, 0.130)
    ui.cap = text(ui.frame, 14, 22)
    ui.cap:SetTextColor(C_CAP[1], C_CAP[2], C_CAP[3])
    ui.cap:SetText(ns.T("chess.lobbyCap"))
    ui.new = ns.MakeKitButton(ui.frame)
    ui.new:SetWidth(156)
    ui.new:SetHeight(28)
    ui.new:SetPoint("TOPRIGHT", ui.frame, "TOPRIGHT", -14, -8)
    ui.new.text:SetText(ns.T("chess.lobbyNew"))
    ui.solo = ns.MakeKitButton(ui.frame)
    ui.solo:SetWidth(156)
    ui.solo:SetHeight(28)
    ui.solo:SetPoint("TOPRIGHT", ui.frame, "TOPRIGHT", -178, -8)
    ui.solo.text:SetText(ns.T("chess.soloName"))
    ui.solo.tip = ns.T("chess.soloStartTip")
    ui.solo.onClick = function() R.Solo() end
    ui.new.onClick = function()
        local mate = ns.Pair.Bound() and ns.Pair.Mate() or nil
        if mate then
            local r = R.ByPeer(mate)
            if r then
                L.Hide()
                R.Open(r.mid)
                return
            end
            ns.Pair.Play(ID, nil)
            return
        end
        ns.CallPanel.Show(ui.frame, {
            pair = true, title = ns.T("pairCall"), autoHide = true,
        })
    end
    ui.row = {}
    for i = 1, VIS do
        local f = ns.NewFrame("Button", nil, ui.frame)
        f:SetWidth(612)
        f:SetHeight(ROW_H)
        f:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", 14, -(48 + (i - 1) * ROW_STEP))
        f.bg = plate(f, C_NICHE)
        outline(f, C_EDGE)
        f.disc = ns.ChessPieces.Make(f)
        f.disc:SetPoint("LEFT", f, "LEFT", 21, 0)
        f.name = text(f, 60, 12, "GameFontNormal")
        f.dot = f:CreateTexture(nil, "OVERLAY")
        f.dot:SetTexture(ns.ChessPieces.DISC_TEX)
        f.dot:SetWidth(7)
        f.dot:SetHeight(7)
        f.dot:SetPoint("TOPLEFT", f, "TOPLEFT", 60, -38)
        f.state = text(f, 73, 36)
        f.turn = text(f, 300, 13)
        f.ply = text(f, 300, 34)
        f.ply:SetTextColor(C_DIM[1], C_DIM[2], C_DIM[3])
        f.when = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.when:SetPoint("TOPRIGHT", f, "TOPRIGHT", -60, -14)
        f.when:SetJustifyH("RIGHT")
        f.when:SetTextColor(C_DIM[1], C_DIM[2], C_DIM[3])
        f.kill = ns.MakeKitButton(f)
        f.kill:SetWidth(22)
        f.kill:SetHeight(22)
        f.kill:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -20)
        f.kill.text:SetText("X")
        f.kill.tip = ns.T("chess.lobbyDropTip")
        f:SetScript("OnClick", function(self)
            if self.mid then ns.Sfx.Ui(); R.Open(self.mid) end
        end)
        ui.row[i] = f
    end
    ui.empty = text(ui.frame, 14, 60)
    ui.empty:SetWidth(612)
    ui.empty:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
    ui.empty:SetText(ns.T("chess.lobbyEmpty"))
end
local function ago(sec)
    if sec < 60 then return ns.T("chess.agoNow") end
    if sec < 3600 then return ns.T("chess.agoMin", floor(sec / 60)) end
    if sec < 86400 then return ns.T("chess.agoHour", floor(sec / 3600)) end
    return ns.T("chess.agoDay", floor(sec / 86400))
end
function L.Refresh()
    if not ui or not ui.frame:IsShown() then return end
    local list = R.List()
    for i = 1, VIS do
        local f = ui.row[i]
        local r = list[i]
        if not r then
            f:Hide()
        else
            f.mid = r.mid
            ns.ChessPieces.Blank(f.disc, r.side or 1, 26)
            f.name:SetText(r.solo and ns.T("chess.soloName") or r.peer)
            f.name:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
            local on = not r.solo and online(r.peer) or nil
            local col = (on == true) and C_LIVE or (on == false) and C_GONE or C_DIM
            f.dot:SetVertexColor(col[1], col[2], col[3])
            f.state:SetTextColor(col[1], col[2], col[3])
            if r.solo then
                f.state:SetText(ns.T("chess.soloBoth"))
                f.state:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
                f.dot:SetVertexColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
            elseif on == true then
                f.state:SetText(ns.T("chess.lobbyOnline"))
            elseif on == false then
                f.state:SetText(ns.T("chess.lobbyOffline"))
            else
                f.state:SetText("")
            end
            if r.over then
                f.turn:SetText(ns.T("chess.lobbyDone"))
                f.turn:SetTextColor(C_DIM[1], C_DIM[2], C_DIM[3])
            elseif r.solo then
                f.turn:SetText(((r.n or 0) % 2 == 0) and ns.T("chess.turnWhiteTurn")
                    or ns.T("chess.turnBlackTurn"))
                f.turn:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
            elseif R.Mine(r) then
                f.turn:SetText(ns.T("chess.turnMine"))
                f.turn:SetTextColor(C_GOLD[1], C_GOLD[2], C_GOLD[3])
            else
                f.turn:SetText(ns.T("chess.turnPeer", r.peer))
                f.turn:SetTextColor(C_SOFT[1], C_SOFT[2], C_SOFT[3])
            end
            f.ply:SetText(ns.T("chess.logPly", r.n or 0))
            f.when:SetText(ago(time() - (r.at or time())))
            f.kill.onClick = function() L.AskDrop(r) end
            f:Show()
        end
    end
    if #list == 0 then ui.empty:Show() else ui.empty:Hide() end
end
function L.AskDrop(r)
    ns.Curtain.Ask(ui.canvas, ns.T("chess.label"),
        { ns.T("chess.lobbyDropAsk", r.peer or ns.T("chess.soloName")) },
        {
            {
                label = ns.T("chess.lobbyDropYes"),
                onClick = function()
                    R.Drop(r.mid)
                    ns.Curtain.Hide()
                    L.Refresh()
                end,
            },
            {
                label = ns.T("chess.soloNo"),
                onClick = function() ns.Curtain.Hide() end,
            },
        })
end
function L.Show(canvas)
    build(canvas)
    ns.CallPanel.Hide()
    ui.frame:Show()
    L.Refresh()
end
function L.Hide()
    if ui then
        ns.CallPanel.Hide()
        ui.frame:Hide()
    end
end
function L.IsShown()
    return ui and ui.frame:IsShown() and true or false
end
ns.Link.OnPresence(function()
    L.Refresh()
end)
ns.Duo.OnChange(function()
    L.Refresh()
end)
