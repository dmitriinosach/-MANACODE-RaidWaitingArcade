local ADDON, ns = ...
ns.gems = ns.gems or {}
local G = ns.gems
local floor = math.floor
G.N = 8
G.KIND_PLAIN, G.KIND_ROW, G.KIND_COL, G.KIND_BOMB, G.KIND_META = 0, 1, 2, 3, 4
G.BLOCK_NONE, G.BLOCK_ROCK, G.BLOCK_FRAME, G.BLOCK_RAW = 0, 1, 2, 3
G.WILD = 0
G.WILD_ONE_IN = 60
local MASK = {
    full  = { {1,8},{1,8},{1,8},{1,8},{1,8},{1,8},{1,8},{1,8} },
    bowl  = { {3,8},{2,8},{1,8},{1,8},{1,8},{1,8},{2,8},{3,8} },
    waist = { {1,8},{1,8},{2,7},{3,6},{3,6},{2,7},{1,8},{1,8} },
    rhomb = { {4,5},{3,6},{2,7},{1,8},{1,8},{2,7},{3,6},{4,5} },
    pyre  = { {1,3},{1,4},{1,6},{1,8},{1,8},{1,6},{1,4},{1,3} },
}
G.RECIPES = {
    { key = "plain", label = "gems.recipePlainLabel", mask = "full",
      goal = { "color" },          base = 67, moves = 27 },
    { key = "two",   label = "gems.recipeTwoLabel", mask = "bowl",
      goal = { "color", "color" }, base = 61, moves = 28 },
    { key = "rock",  label = "gems.recipeRockLabel", mask = "full",
      goal = { "rock" },           rock = 35, moves = 22 },
    { key = "frame", label = "gems.recipeFrameLabel", mask = "waist",
      goal = { "frame" },          frame = 6,  moves = 30 },
    { key = "raw",   label = "gems.recipeRawLabel", mask = "rhomb",
      goal = { "raw" },            raw = 2, rock = 2, moves = 36 },
    { key = "mix",   label = "gems.recipeMixLabel", mask = "pyre",
      goal = { "color", "frame" }, base = 33, frame = 8, rock = 4, moves = 30 },
}
G.COLORS_MIN, G.COLORS_MAX = 4, 5
G.INTRO = 3
G.MOVES_MIN = 18
G.GOAL_MAX = 120
G.WALL_EVERY = 10
G.WALL_MOVES = 3
G.BLOCK_SHARE = 0.72
G.FRAME_SHARE = 0.30
G.FRAME_MAX = 10
G.RAW_SHARE = 0.60
G.STEP_MAX = 36
G.MOVES_STEP = 14
G.NEED_STEP = 9
G.ROCK_STEP = 5
G.FRAME_STEP = 10
G.RAW_STEP = 24
function G.Room(key)
    local m = MASK[key] or MASK.full
    local spots, tops = 0, 0
    for c = 1, G.N do
        local lo, hi = m[c][1], m[c][2]
        spots = spots + (hi - lo)
        if hi - lo >= 3 then tops = tops + 1 end
    end
    return spots, tops
end
function G.Params(level)
    if type(level) ~= "number" or level < 1 then level = 1 end
    local rec = G.RECIPES[1 + (level - 1) % #G.RECIPES]
    local colors = (level <= G.INTRO) and G.COLORS_MIN or G.COLORS_MAX
    local step = (level > G.STEP_MAX) and G.STEP_MAX or level
    local wall = (level % G.WALL_EVERY) == 0
    local moves = rec.moves - floor(step / G.MOVES_STEP) - (wall and G.WALL_MOVES or 0)
    if moves < G.MOVES_MIN then moves = G.MOVES_MIN end
    local need = rec.base or 0
    if need > 0 then
        need = floor(need * 16 / (colors * colors) + 0.5) + floor(step / G.NEED_STEP)
    end
    if need > G.GOAL_MAX then need = G.GOAL_MAX end
    local spots, tops = G.Room(rec.mask)
    local frame = rec.frame and (rec.frame + floor(step / G.FRAME_STEP)) or 0
    if frame > 0 then
        local cap = floor(spots * G.FRAME_SHARE)
        if cap > G.FRAME_MAX then cap = G.FRAME_MAX end
        if cap < rec.frame then cap = rec.frame end
        if frame > cap then frame = cap end
    end
    local rock = rec.rock and (rec.rock + floor(step / G.ROCK_STEP)) or 0
    if rock > 0 then
        local cap = floor(spots * G.BLOCK_SHARE) - frame
        if cap < rec.rock then cap = rec.rock end
        if rock > cap then rock = cap end
    end
    local raw = rec.raw and (rec.raw + floor(step / G.RAW_STEP)) or 0
    if raw > 0 then
        local cap = floor(tops * G.RAW_SHARE)
        if cap < rec.raw then cap = rec.raw end
        if raw > cap then raw = cap end
    end
    return {
        rec = rec, wall = wall, colors = colors, moves = moves, need = need,
        rock = rock, frame = frame, raw = raw,
    }
end
function G.Seed(seed, level, attempt)
    return seed + level * 7919 + attempt * 104729
end
local function layMask(self, p)
    local m = MASK[p.rec.mask] or MASK.full
    self.low, self.high = {}, {}
    for c = 1, G.N do
        self.low[c], self.high[c] = m[c][1], m[c][2]
    end
end
local function freeCells(self, rng, skipBottom)
    local list = {}
    for c = 1, G.N do
        local from = skipBottom and (self.low[c] + 1) or self.low[c]
        for r = from, self.high[c] do
            list[#list + 1] = { c = c, r = r }
        end
    end
    rng:Shuffle(list)
    return list
end
local function layBlocks(self, p, rng)
    self.block = {}
    for c = 1, G.N do self.block[c] = {} end
    for c = 1, G.N do
        for r = 1, G.N do self.block[c][r] = G.BLOCK_NONE end
    end
    local top = {}
    for c = 1, G.N do
        if self.high[c] - self.low[c] >= 3 then
            top[#top + 1] = { c = c, r = self.high[c] }
        end
    end
    rng:Shuffle(top)
    self.rawTotal = 0
    for k = 1, p.raw do
        local s = top[k]
        if not s then break end
        self.block[s.c][s.r] = G.BLOCK_RAW
        self.rawTotal = self.rawTotal + 1
    end
    local spots = freeCells(self, rng, true)
    local i = 0
    local function lay(what, n)
        local put = 0
        while put < n do
            i = i + 1
            local s = spots[i]
            if not s then break end
            if self.block[s.c][s.r] == G.BLOCK_NONE then
                self.block[s.c][s.r] = what
                put = put + 1
            end
        end
        return put
    end
    self.rockTotal = lay(G.BLOCK_ROCK, p.rock)
    self.frameTotal = lay(G.BLOCK_FRAME, p.frame)
end
local function layGoals(self, p, rng)
    self.goal = {}
    local colors = {}
    for v = 1, p.colors do colors[v] = v end
    rng:Shuffle(colors)
    local taken = 0
    for _, kind in ipairs(p.rec.goal) do
        if kind == "color" then
            taken = taken + 1
            self.goal[#self.goal + 1] =
                { kind = "color", color = colors[taken] or 1, need = p.need, done = 0 }
        elseif kind == "rock" then
            self.goal[#self.goal + 1] = { kind = "rock", need = self.rockTotal, done = 0 }
        elseif kind == "frame" then
            self.goal[#self.goal + 1] = { kind = "frame", need = self.frameTotal, done = 0 }
        elseif kind == "raw" then
            self.goal[#self.goal + 1] = { kind = "raw", need = self.rawTotal, done = 0 }
        end
    end
end
function G.Open(self, colors)
    self.low, self.high = {}, {}
    for c = 1, G.N do self.low[c], self.high[c] = 1, G.N end
    self.block = {}
    for c = 1, G.N do
        self.block[c] = {}
        for r = 1, G.N do self.block[c][r] = G.BLOCK_NONE end
    end
    self.goal = {}
    self.colors = colors
    self.rawTotal, self.rockTotal, self.frameTotal = 0, 0, 0
end
function G.Build(self, level, attempt)
    local p = G.Params(level)
    local rng = ns.RNG.New(G.Seed(self.seed, level, attempt))
    layMask(self, p)
    layBlocks(self, p, rng)
    layGoals(self, p, rng)
    self.colors = p.colors
    self.moves = p.moves
    self.wall = p.wall
    self.rng = rng
    return p
end
