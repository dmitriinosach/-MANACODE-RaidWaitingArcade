local ADDON, ns = ...
local P = ns.Patience
local COLS = 7
local OPEN_PER_PILE = 5
ns.RegisterPatience("yukon", {
    label = "solitaire.modeYukon",
    line  = "solitaire.yukonLine",
    cols  = COLS,
    gap   = 12,
    top   = { false, false, false, "home", "home", "home", "home" },
    Deal = function(self, order)
        local k = 0
        for c = 1, COLS do
            local pile = self.tableau[c]
            local closed = c - 1
            local open = (c == 1) and 1 or OPEN_PER_PILE
            for i = 1, closed + open do
                k = k + 1
                local card = self.deck[order[k]]
                card.open = (i > closed)
                pile[#pile + 1] = card
            end
        end
    end,
    CanDrop = P.DropKing,
    TailOk = function(self, col, fi)
        local card = self.tableau[col][fi]
        return (card and card.open) and true or false
    end,
    Home = P.HomeBySuit,
    NoMoves = function(self)
        for c = 1, COLS do
            local pile = self.tableau[c]
            local n = #pile
            if n > 0 and P.HomeBySuit(self, pile[n]) then return false end
        end
        for c = 1, COLS do
            local pile = self.tableau[c]
            for p = 1, #pile do
                if pile[p].open then
                    for d = 1, COLS do
                        if d ~= c and P.DropKing(self, pile[p], d)
                           and not P.Null(self, c, p, d) then
                            return false
                        end
                    end
                end
            end
        end
        return true
    end,
})
