local ADDON, ns = ...
local P = ns.Patience
local CELLS = 4
local function capacity(self, to)
    local free = 0
    for i = 1, CELLS do
        if not self.cells[i] then free = free + 1 end
    end
    local empty = 0
    for c = 1, self.cols do
        if #self.tableau[c] == 0 and c ~= to then empty = empty + 1 end
    end
    return (free + 1) * 2 ^ empty
end
ns.RegisterPatience("freecell", {
    label = "solitaire.modeFreecell",
    line  = "solitaire.freecellLine",
    cols  = 8,
    gap   = 8,
    cells = CELLS,
    top   = { "cell", "cell", "cell", "cell", "home", "home", "home", "home" },
    Deal = function(self, order)
        for k = 1, 52 do
            local c = (k - 1) % 8 + 1
            local card = self.deck[order[k]]
            card.open = true
            local pile = self.tableau[c]
            pile[#pile + 1] = card
        end
    end,
    CanDrop = P.DropAny,
    TailOk = function(self, col, fi)
        if not P.TailAlt(self.tableau[col], fi) then return false end
        local n = #self.tableau[col] - fi + 1
        return n <= capacity(self, nil)
    end,
    TailFits = function(self, col, fi, to)
        local n = #self.tableau[col] - fi + 1
        return n <= capacity(self, to)
    end,
    Home = P.HomeBySuit,
    NoMoves = function(self)
        for i = 1, CELLS do
            if not self.cells[i] then
                for c = 1, self.cols do
                    if #self.tableau[c] > 0 then return false end
                end
            end
        end
        for i = 1, CELLS do
            local card = self.cells[i]
            if card then
                if P.HomeBySuit(self, card) then return false end
                for c = 1, self.cols do
                    if P.DropAny(self, card, c) then return false end
                end
            end
        end
        for c = 1, self.cols do
            local pile = self.tableau[c]
            local n = #pile
            if n > 0 then
                if P.HomeBySuit(self, pile[n]) then return false end
                for p = 1, n do
                    if P.TailAlt(pile, p) and (n - p + 1) <= capacity(self, nil) then
                        for d = 1, self.cols do
                            if d ~= c and P.DropAny(self, pile[p], d)
                               and not P.Null(self, c, p, d) then
                                return false
                            end
                        end
                    end
                end
            end
        end
        return true
    end,
})
