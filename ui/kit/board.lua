local ADDON, ns = ...
local ROW = 22
local VAL_FONT = "Fonts\\FRIZQT__.TTF"
local VAL_SIZE = 16
local C_RUN   = ns.ATTN
local C_SOFT  = { 0.78, 0.66, 0.36 }
local C_WARN  = { 1, 0.3, 0.3 }
local C_PAUSE = { 0.5, 0.5, 0.5 }
local Board = {}
local function span(sec)
    local m = math.floor(sec / 60)
    return string.format("%d:%02d", m, math.floor(sec - m * 60))
end
function Board:Sync()
    local win, game = ns.window, ns.Loop.Current()
    if not game then return end
    local def = game.def
    local off = def and def.tally == false
    if off ~= self.tallyOff then
        self.tallyOff = off
        self.clockBox:ClearAllPoints()
        self.clockBox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, off and 0 or -ROW)
        self.clockBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, off and 0 or -ROW)
    end
    if off then
        self.coin:Hide()
        self.scoreCap:Hide()
        self.score:SetText("")
    else
        local mark = ns.Records.MarkFor(def, "score")
        local ok, sc = ns.SafeCall(game, "Score")
        self.score:SetText(ns.Records.Format(mark, ok and sc or 0))
        self.coin:SetTexture(ns.Records.Icon(mark.mark))
        self.coin:Show()
        self.scoreCap:SetText(ns.TL(mark.label) or ns.T("panelScore"))
        self.scoreCap:Show()
    end
    local paused = ns.Loop.IsPaused()
    local text, warn
    if game.Clock then text, warn = game:Clock() end
    if not text then text = span(win:Elapsed()) end
    local grade = (def and def.clock) or (game.Clock and "hard") or "soft"
    if grade == "off" then
        self.clockBox:Hide()
    else
        self.clockBox:Show()
        self.clockCap:SetText(game.clockCap or ns.T("panelClock"))
        self.clock:SetText(text)
        local c = paused and C_PAUSE
            or (warn and C_WARN)
            or (grade == "hard" and C_RUN or C_SOFT)
        self.clock:SetTextColor(c[1], c[2], c[3])
        self.clockBox.tip = game.clockTip
    end
    if ns.Duo.Active() then
        if ns.Duo.MyTurn() then
            self.duo:SetText(ns.T("duoMyTurn"))
            self.duo:SetTextColor(0.4, 0.9, 0.4)
        else
            self.duo:SetText(ns.T("duoHisTurn", ns.Duo.Peer() or ""))
            self.duo:SetTextColor(ns.Attn())
        end
    else
        self.duo:SetText("")
    end
end
function Board:Notices(host, x, y)
    self.duo:ClearAllPoints()
    self.duo:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
end
function ns.MakeScoreboard(parent, w)
    w = w or 148
    local f = ns.NewFrame("Frame", nil, parent)
    f:SetWidth(w)
    f:SetHeight(ROW * 4)
    f:SetFrameLevel(parent:GetFrameLevel() + 30)
    local function stat(y, capKey, host)
        host = host or f
        local cap = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("LEFT", host, "TOPLEFT", 0, -(y + ROW / 2))
        cap:SetText(ns.T(capKey))
        local val = host:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.SetFont(val, VAL_FONT, VAL_SIZE, "")
        val:SetJustifyH("RIGHT")
        val:SetPoint("RIGHT", host, "TOPRIGHT", 0, -(y + ROW / 2))
        return cap, val
    end
    f.scoreCap, f.score = stat(0, "panelScore")
    f.coin = f:CreateTexture(nil, "ARTWORK")
    f.coin:SetWidth(12); f.coin:SetHeight(12)
    ns.CropIcon(f.coin)
    f.coin:SetPoint("RIGHT", f.score, "LEFT", -3, 0)
    f.clockBox = ns.NewFrame("Frame", nil, f)
    f.clockBox:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -ROW)
    f.clockBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -ROW)
    f.clockBox:SetHeight(ROW)
    f.clockBox:EnableMouse(true)
    f.clockBox:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    f.clockBox:SetScript("OnLeave", ns.TipHide)
    f.clockCap, f.clock = stat(0, "panelClock", f.clockBox)
    f.duo = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.duo:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -ROW * 2)
    f.duo:SetWidth(w)
    f.duo:SetJustifyH("LEFT")
    f.Sync = Board.Sync
    f.Notices = Board.Notices
    return f
end
