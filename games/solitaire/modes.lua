local ADDON, ns = ...
ns.Patience = { modes = {}, order = {} }
function ns.RegisterPatience(key, def)
    if type(key) ~= "string" or type(def) ~= "table" then return end
    if ns.Patience.modes[key] then return end
    def.key = key
    def.cols = def.cols or 7
    def.gap = def.gap or 12
    def.top = def.top or {}
    def.Won = def.Won or function(self) return self.homeCount >= 52 end
    ns.Patience.modes[key] = def
    ns.Patience.order[#ns.Patience.order + 1] = key
end
function ns.Patience.Get(key)
    return ns.Patience.modes[key or ""] or ns.Patience.modes[ns.Patience.order[1]]
end
function ns.Patience.List()
    local out = {}
    for _, key in ipairs(ns.Patience.order) do
        local m = ns.Patience.modes[key]
        out[#out + 1] = { key = key, label = m.label or key }
    end
    return out
end
function ns.Patience.IsRed(suit)
    local s = ns.DECK_SUITS[suit]
    return (s and s.red) and true or false
end
function ns.Patience.StacksAlt(card, onto)
    if not onto then return false end
    return onto.open and onto.rank == card.rank + 1
           and ns.Patience.IsRed(onto.suit) ~= ns.Patience.IsRed(card.suit)
end
function ns.Patience.TailAlt(pile, fi)
    local n = #pile
    if type(fi) ~= "number" or fi < 1 or fi > n then return false end
    for i = fi, n do
        if not pile[i].open then return false end
    end
    for i = fi, n - 1 do
        if not ns.Patience.StacksAlt(pile[i + 1], pile[i]) then return false end
    end
    return true
end
function ns.Patience.Null(self, from, fi, to)
    return fi == 1 and #self.tableau[to] == 0
end
function ns.Patience.DropKing(self, card, col)
    local pile = self.tableau[col]
    if #pile == 0 then return card.rank == 13 end
    return ns.Patience.StacksAlt(card, pile[#pile])
end
function ns.Patience.DropAny(self, card, col)
    local pile = self.tableau[col]
    if #pile == 0 then return true end
    return ns.Patience.StacksAlt(card, pile[#pile])
end
function ns.Patience.HomeBySuit(self, card)
    if not card then return nil end
    if self.foundation[card.suit] == card.rank - 1 then return card.suit end
    return nil
end
