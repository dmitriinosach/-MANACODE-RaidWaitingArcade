local ADDON, ns = ...
local abs, sqrt = math.abs, math.sqrt
local C = {
    MODE = "citadel",
    SEALS = 3,
    SEAL_INV = 1.0,
    SEAL_KICK = 0.7,
    ARENA_GAP = 60,
    VAULT_H = 30,
    VAULT_GAP = 160,
    BOSS_DROP = 130,
    ARENA_CEIL = 34,
    BOSS_V = 70,
    BOSS_HB = 30,
    BOSS_STOMP = 3,
    BOSS_SHOT = 1,
    MOB_CITADEL_FROM = 300,
    MOB_CITADEL_MIN = 500,
    MOB_CITADEL_MAX = 620,
    ELITE_FROM = 400,
    ELITE_P = 0.34,
    ELITE_HP = 3,
    ELITE_HB = 17,
    ELITE_SCALE = 1.4,
    FLAME_EVERY = 4.0,
    FLAME_V = 190,
    FLAME_H = 10,
    SPIKE_EVERY = 6.0,
    SPIKE_LIFE = 5.0,
    SPIKE_HP = 2,
    SPIKE_W = 10,
    SPIKE_H = 26,
    STORM_EVERY = 12.0,
    STORM_TIME = 5.0,
    STORM_WARN = 1.0,
    STORM_MUL = 2.2,
    SHIELD_N = 4,
    SERV_EVERY = 3.2,
    SERV_HP = 2,
    SERV_KEY = "servant",
    POOL_EVERY = 5.0,
    POOL_WARN = 1.0,
    POOL_LIFE = 3.0,
    POOL_W = 64,
    POOL_H = 8,
    SHADE_EVERY = 6.0,
    SHADE_RAGE = 3.6,
    SHADE_WARN = 0.7,
    SHADE_V = 105,
    SHADE_LIFE = 5.0,
    SHADE_HB = 11,
    SHADE_SIZE = 22,
    MODEL_W = 150,
    MODEL_H = 150,
    MODEL_HOLD = 4,
}
ns.jumpCitadel = C
local K = {}
function C.Bind(core) K = core end
local M = {}
C.methods = M
function M:GateSync()
    local g = self.gate and ns.jumpGates and ns.jumpGates[self.gate]
    self.gateY = g and g.at or nil
    self.gateCam = self.gateY and (self.gateY - self.H) or nil
end
function M:InArena(y)
    return self.gateY ~= nil and y > self.gateY - self.H
end
function M:HitFlame()
    local f = self.flame
    if not f then return end
    local top, bot = f.y + C.FLAME_H / 2, f.y - C.FLAME_H / 2
    if self.y > top or self.y + K.PSIZE < bot then return end
    local x = self.x
    if (x >= f.l and x <= f.x) or (x >= f.x and x <= f.r) then self:Hurt() end
end
function M:HitBoss(y0)
    local b = self.boss
    if not b then return end
    local dx = abs(b.x - self.x)
    if dx > C.BOSS_HB + K.HB then return end
    if self.y > b.y + C.BOSS_HB then return end
    if self.y + K.PSIZE < b.y - C.BOSS_HB then return end
    if self.vy < 0 and y0 >= b.y and not b.storm then
        self:DamageBoss(C.BOSS_STOMP)
        self.y = b.y + C.BOSS_HB
        self.vy = K.BOUNCE
        return
    end
    self:Hurt()
end
function M:DamageBoss(n)
    local b = self.boss
    if not b then return end
    if (b.shield or 0) > 0 then
        b.hurt = 0.12
        return
    end
    b.hp = b.hp - n
    b.hurt = 0.12
    if b.hp > 0 then return end
    self.flash = { x = b.x, y = b.y, t = K.FLASH_T }
    if self.spike and self.spike.plat then self.spike.plat.spiked = nil end
    if self.pool and self.pool.plat then self.pool.plat.pooled = nil end
    self.flame, self.spike, self.pin = nil, nil, nil
    self.pool, self.shade = nil, nil
    self.boss = nil
    self.gate = self.gate + 1
    self:GateSync()
    ns.Sfx.Play("big")
end
function M:StartFight()
    local g = ns.jumpGates and ns.jumpGates[self.gate]
    if not g then return end
    self.boss = {
        hp = g.hp or 12, hpMax = g.hp or 12,
        x = self.W / 2,
        y = self.cam + self.H - C.BOSS_DROP,
        vx = (self.rng:Float() < 0.5) and -C.BOSS_V or C.BOSS_V,
        mech = g.key,
        shield = (g.key == "deathwhisper") and C.SHIELD_N or 0,
        shieldMax = (g.key == "deathwhisper") and C.SHIELD_N or 0,
        flameT = C.FLAME_EVERY, spikeT = C.SPIKE_EVERY, stormT = C.STORM_EVERY,
        servT = C.SERV_EVERY, poolT = C.POOL_EVERY, shadeT = C.SHADE_EVERY,
    }
    self.flame, self.spike, self.pin = nil, nil, nil
    self.pool, self.shade = nil, nil
    self.mob, self.shot = nil, nil
    self:Note(ns.T("jump.boss" .. g.key), ns.T("jump.noteGate"), { 0.86, 0.40, 0.36 })
end
function M:BossMech(dt, b)
    if b.mech == "deathwhisper" then return self:MechLady(dt, b) end
    if b.mech ~= "marrowgar" then return end
    if b.storm then
        b.storm = b.storm - dt
        if b.storm <= 0 then
            b.storm = nil
            b.stormT = C.STORM_EVERY
            b.vx = (b.vx < 0) and -C.BOSS_V or C.BOSS_V
        end
    else
        b.stormT = b.stormT - dt
        if b.stormT <= 0 then
            b.storm = C.STORM_TIME
            b.vx = (b.vx < 0) and -C.BOSS_V * C.STORM_MUL or C.BOSS_V * C.STORM_MUL
        end
    end
    if self.flame then
        local f = self.flame
        f.l = f.l - C.FLAME_V * dt
        f.r = f.r + C.FLAME_V * dt
        if f.l <= 0 and f.r >= self.W then self.flame = nil end
    else
        b.flameT = b.flameT - dt
        if b.flameT <= 0 then
            b.flameT = C.FLAME_EVERY
            self.flame = { y = b.y - C.BOSS_HB + 6, l = b.x, r = b.x, x = b.x }
        end
    end
    if self.spike then
        local sp = self.spike
        sp.t = sp.t - dt
        if sp.t <= 0 or sp.hp <= 0 then
            if sp.plat then sp.plat.spiked = nil end
            self.spike = nil
            if self.pin then
                self.pin = nil
                self.vy = K.BOUNCE
            end
        end
    elseif not b.storm then
        b.spikeT = b.spikeT - dt
        if b.spikeT <= 0 then
            b.spikeT = C.SPIKE_EVERY
            self:GrowSpike()
        end
    end
end
function M:GrowSpike()
    local best, bd
    for i = 1, #self.plat do
        local p = self.plat[i]
        if not p.dead and not p.spiked then
            local sy = p.y - self.cam
            if sy > 20 and sy < self.H - 40 then
                local dx = abs(p.x + K.PW / 2 - self.x)
                local dy = abs(p.y - self.y)
                local d = dx + dy
                if not bd or d < bd then best, bd = p, d end
            end
        end
    end
    if not best then return end
    best.spiked = true
    self.spike = {
        plat = best, x = best.x + K.PW / 2, y = best.y,
        hp = C.SPIKE_HP, t = C.SPIKE_LIFE,
    }
end
function M:MechLady(dt, b)
    if b.shield > 0 and not self.mob then
        b.servT = b.servT - dt
        if b.servT <= 0 then
            b.servT = C.SERV_EVERY
            self:CallServant()
        end
    end
    if self.pool then
        local p = self.pool
        p.t = p.t - dt
        if p.t <= 0 then
            if p.plat then p.plat.pooled = nil end
            self.pool = nil
        end
    else
        b.poolT = b.poolT - dt
        if b.poolT <= 0 then
            b.poolT = C.POOL_EVERY
            self:PourPool()
        end
    end
    if self.shade then
        local s = self.shade
        if s.warn > 0 then
            s.warn = s.warn - dt
        else
            local dx = self.x - s.x
            local dy = (self.y + K.PSIZE / 2) - s.y
            local d = sqrt(dx * dx + dy * dy)
            if d > 1 then
                s.x = s.x + dx / d * C.SHADE_V * dt
                s.y = s.y + dy / d * C.SHADE_V * dt
            end
            s.t = s.t - dt
            if s.t <= 0 then self.shade = nil end
        end
    else
        b.shadeT = b.shadeT - dt
        if b.shadeT <= 0 then
            b.shadeT = (b.shield > 0) and C.SHADE_EVERY or C.SHADE_RAGE
            self.shade = { x = b.x, y = b.y - C.BOSS_HB, t = C.SHADE_LIFE, warn = C.SHADE_WARN }
        end
    end
end
function M:CallServant()
    local best, bd
    for i = 1, #self.plat do
        local p = self.plat[i]
        if not p.dead and not p.pooled then
            local sy = p.y - self.cam
            if sy > 40 and sy < self.H - 60 then
                local d = abs(p.x + K.PW / 2 - self.x)
                if not bd or d > bd then best, bd = p, d end
            end
        end
    end
    if not best then return end
    local art
    local list = ns.jumpMobs
    if type(list) == "table" then
        for i = 1, #list do
            if list[i].key == C.SERV_KEY then art = i break end
        end
    end
    self.mob = {
        x = best.x + K.PW / 2, y = best.y + K.MOB_HB,
        vx = (self.rng:Float() < 0.5) and -K.MOB_V or K.MOB_V,
        art = art, hp = C.SERV_HP, serv = true,
    }
end
function M:PourPool()
    local best, bd
    for i = 1, #self.plat do
        local p = self.plat[i]
        if not p.dead and not p.pooled and not p.spiked then
            local sy = p.y - self.cam
            if sy > 20 and sy < self.H - 40 then
                local dx = abs(p.x + K.PW / 2 - self.x)
                local dy = abs(p.y - self.y)
                local d = dx + dy
                if not bd or d < bd then best, bd = p, d end
            end
        end
    end
    if not best then return end
    best.pooled = true
    self.pool = {
        plat = best, x = best.x + K.PW / 2, y = best.y,
        t = C.POOL_WARN + C.POOL_LIFE,
    }
end
function M:PoolBurns()
    return self.pool ~= nil and self.pool.t <= C.POOL_LIFE
end
function M:HitShade()
    local s = self.shade
    if not s or s.warn > 0 then return end
    local dx = abs(s.x - self.x)
    local dy = abs(s.y - (self.y + K.PSIZE / 2))
    if dx > C.SHADE_HB + K.HB or dy > C.SHADE_HB + K.PSIZE / 2 then return end
    self.shade = nil
    self.flash = { x = s.x, y = s.y, t = K.FLASH_T }
    self:Hurt()
end
function M:MapRows()
    local rec = ns.Records.Best(K.ID, { mode = C.MODE })
    local reach = rec and rec.score or 0
    local rows = { { name = ns.T("jump.floorEntry"), mark = "none", taken = true,
                     note = "", c = { 0.30, 0.25, 0.18 } } }
    local gates = ns.jumpGates or {}
    for i = 1, #gates do
        local g = gates[i]
        local taken = reach >= g.at
        rows[#rows + 1] = {
            name = ns.T("jump.boss" .. g.key), mark = "skull", taken = taken,
            note = g.at .. "   " .. ns.T(taken and "jump.floorPassed" or "jump.floorLocked"),
            c = { 0.34, 0.28, 0.22 },
        }
    end
    rows[#rows + 1] = { name = ns.T("jump.floorAhead"), mark = "lock", dim = true,
                        note = "", c = { 0.18, 0.16, 0.12 } }
    rows[#rows + 1] = { name = ns.T("jump.floorThrone"), mark = "lock", dim = true,
                        note = "", c = { 0.18, 0.16, 0.12 } }
    return rows
end
