local ADDON, ns = ...
local RING_TEX  = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local FLASH_TEX = "Interface\\Cooldown\\star4"
local FULL      = { 0, 1, 0, 1 }
local RING  = { 1.00, 0.92, 0.70 }
local ECHO  = { 0.85, 0.90, 1.00 }
local CORE  = { 1.00, 0.98, 0.92 }
local RING_T  = 0.30
local ECHO_T  = 0.28
local ECHO_AT = 0.07
local FLASH_T = 0.14
ns.RegisterFX{
    key = "chime", cost = 3, cheaper = "burst", fancy = true,
    play = function(parent, cells, rng)
        for i = 1, #cells do
            local c = cells[i]
            local x = c.x + (rng:Float() - 0.5) * c.size * 0.3
            local y = c.y + (rng:Float() - 0.5) * c.size * 0.3
            local ring = ns.FX.Ghost(parent, x, y, c.size * 0.5, RING_TEX, FULL)
            ring.tex:SetBlendMode("ADD")
            ring.tex:SetVertexColor(RING[1], RING[2], RING[3])
            ring:SetAlpha(0.9)
            ring.move:SetOffset(0, 0)
            ring.move:SetDuration(RING_T)
            ring.grow:SetScale(4.2, 4.2)
            ring.grow:SetDuration(RING_T)
            ring.grow:SetSmoothing("OUT")
            ring.fade:SetChange(-1)
            ring.fade:SetDuration(RING_T * 0.6)
            ring.fade:SetStartDelay(RING_T * 0.4)
            ring.anim:Play()
            local echo = ns.FX.Ghost(parent, x, y, c.size * 0.5, RING_TEX, FULL)
            echo.tex:SetBlendMode("ADD")
            echo.tex:SetVertexColor(ECHO[1], ECHO[2], ECHO[3])
            echo:SetAlpha(0.5)
            echo.move:SetOffset(0, 0)
            echo.move:SetDuration(ECHO_T)
            echo.move:SetStartDelay(ECHO_AT)
            echo.grow:SetScale(3.0, 3.0)
            echo.grow:SetDuration(ECHO_T)
            echo.grow:SetStartDelay(ECHO_AT)
            echo.grow:SetSmoothing("OUT")
            echo.fade:SetChange(-1)
            echo.fade:SetDuration(ECHO_T)
            echo.fade:SetStartDelay(ECHO_AT)
            echo.anim:Play()
            local flash = ns.FX.Ghost(parent, x, y, c.size * 0.9, FLASH_TEX, FULL)
            flash.tex:SetBlendMode("ADD")
            flash.tex:SetVertexColor(CORE[1], CORE[2], CORE[3])
            flash.move:SetOffset(0, 0)
            flash.move:SetDuration(FLASH_T)
            flash.grow:SetScale(1.6, 1.6)
            flash.grow:SetDuration(FLASH_T)
            flash.grow:SetSmoothing("OUT")
            flash.fade:SetChange(-1)
            flash.fade:SetDuration(FLASH_T)
            flash.anim:Play()
        end
    end,
}
