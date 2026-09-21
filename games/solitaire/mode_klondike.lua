local ADDON, ns = ...
local P = ns.Patience
ns.RegisterPatience("klondike", {
    label = "solitaire.modeKlondike",
    line  = "solitaire.klondikeLine",
    cols  = 7,
    gap   = 12,
    top   = { "stock", "waste", false, "home", "home", "home", "home" },
    Deal = function(self, order)
        local k = 0
        for c = 1, 7 do
            local pile = self.tableau[c]
            for _ = 1, c do
                k = k + 1
                pile[#pile + 1] = self.deck[order[k]]
            end
            pile[#pile].open = true
        end
        for i = 52, k + 1, -1 do
            self.stock[#self.stock + 1] = self.deck[order[i]]
        end
    end,
    Stock = function(self)
        if #self.stock > 0 then
            local c = table.remove(self.stock)
            c.open = true
            self.waste[#self.waste + 1] = c
            return true
        end
        if #self.waste > 0 then
            local n = #self.waste
            for i = 1, n do
                local c = self.waste[i]
                c.open = false
                self.stock[n - i + 1] = c
            end
            for i = 1, n do self.waste[i] = nil end
            self.recycled = self.recycled + 1
            if not self.everMovable then self.deadlock = true end
            self.everMovable = false
            return true
        end
        return false
    end,
    CanDrop = P.DropKing,
    TailOk = function(self, col, fi)
        return P.TailAlt(self.tableau[col], fi)
    end,
    Home = P.HomeBySuit,
    NoMoves = function(self)
        local w = self.waste[#self.waste]
        if w and P.HomeBySuit(self, w) then return false end
        for c = 1, 7 do
            local pile = self.tableau[c]
            if #pile > 0 and P.HomeBySuit(self, pile[#pile]) then return false end
        end
        if w then
            for c = 1, 7 do
                if P.DropKing(self, w, c) then return false end
            end
        end
        for c = 1, 7 do
            local pile = self.tableau[c]
            for p = 1, #pile do
                if pile[p].open then
                    for d = 1, 7 do
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
