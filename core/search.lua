local ADDON, ns = ...
ns.Search = {}
local INF = 1e9
local WIN = 1e6
local CHECK_EVERY = 64
local Job = {}
Job.__index = Job
function ns.Search.New(spec)
    local job = setmetatable({
        spec = spec,
        best = nil,
        depth = 0,
        nodes = 0,
        spent = 0,
        done = false,
    }, Job)
    job.co = coroutine.create(function() return job:Run() end)
    return job
end
local function spentNow(self)
    local live = debugprofilestop() - self.mark
    if live < 0 then live = 0 end
    return self.spent + live
end
function Job:Breathe()
    self.nodes = self.nodes + 1
    if self.nodes % CHECK_EVERY ~= 0 then return end
    if spentNow(self) >= self.limit then
        self.stop = true
        return
    end
    local now = debugprofilestop()
    if now - self.mark < 0 or now >= self.deadline then coroutine.yield() end
end
function Job:Alphabeta(depth, alpha, beta, ply)
    local s = self.spec
    self:Breathe()
    if self.stop then return 0 end
    if s.over(s.node) then
        local r = s.result(s.node, s.me)
        if r == 0 then return 0 end
        return r > 0 and (WIN - ply) or (ply - WIN)
    end
    if depth <= 0 then return s.eval(s.node, s.me) end
    local list = s.moves(s.node)
    local nMoves = #list
    if nMoves == 0 then return s.eval(s.node, s.me) end
    if ply == 0 and self.best then
        for i = 2, nMoves do
            if s.same(list[i], self.best) then
                list[i], list[1] = list[1], list[i]
                break
            end
        end
    end
    local mine = s.turn(s.node) == s.me
    local best = mine and -INF or INF
    local bestMove
    for i = 1, nMoves do
        local mv = list[i]
        local token = s.apply(s.node, mv)
        local v = self:Alphabeta(depth - 1, alpha, beta, ply + 1)
        s.undo(s.node, token)
        if mine then
            if v > best then best, bestMove = v, mv end
            if best > alpha then alpha = best end
        else
            if v < best then best, bestMove = v, mv end
            if best < beta then beta = best end
        end
        if alpha >= beta then break end
    end
    if ply == 0 and bestMove then
        self.iterBest = bestMove
    end
    return best
end
function Job:Run()
    local s = self.spec
    local top = s.depth or 6
    self.limit = s.budget or 1000
    for d = 1, top do
        self.iterBest = nil
        self:Alphabeta(d, -INF, INF, 0)
        if self.stop then break end
        self.best = self.iterBest or self.best
        self.depth = d
    end
    if not self.best then
        local list = s.moves(s.node)
        self.best = list[1]
    end
    return self.best
end
function Job:Step(ms)
    if self.done then return true, self.best, self.depth end
    self.mark = debugprofilestop()
    self.deadline = self.mark + (ms or 8)
    local ok, err = coroutine.resume(self.co)
    local used = debugprofilestop() - self.mark
    if used > 0 then self.spent = self.spent + used end
    self.mark = debugprofilestop()
    if not ok then
        ns.say("поиск хода сорвался: " .. tostring(err))
        self.done, self.best = true, nil
        return true, nil, self.depth
    end
    if coroutine.status(self.co) == "dead" then
        self.done = true
    end
    return self.done, self.best, self.depth
end
function Job:Cancel()
    self.done, self.best = true, nil
end
function Job:Nodes()
    return self.nodes
end
