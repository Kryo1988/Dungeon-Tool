-- Kryos Dungeon Tool
-- Core/CombatLog.lua - Combat Log Event Handler
-- WoW 12.0+ (Midnight): Uses C_DamageMeter API - NO CLEU registration
-- WoW 11.x and below: Uses COMBAT_LOG_EVENT_UNFILTERED

local addonName, KDT = ...

-- Detect WoW version
local _, _, _, buildInfo = GetBuildInfo()
local IS_MIDNIGHT = buildInfo >= 120000  -- WoW 12.0+ (Midnight)

KDT.IsMidnight = IS_MIDNIGHT

-- Create event frame
local CLFrame = CreateFrame("Frame")
KDT.CombatLogFrame = CLFrame

-- CRITICAL: Only register CLEU for WoW 11.x and below!
-- In WoW 12.0+, CLEU registration causes ADDON_ACTION_FORBIDDEN
if not IS_MIDNIGHT then
    -- Pre-Midnight: Register CLEU at file load time
    CLFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Combat state events are safe to register in all versions
CLFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
CLFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Always register safe events
CLFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- WoW 12.0: Register restriction state change (for secret value tracking)
if IS_MIDNIGHT then
    pcall(function() CLFrame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED") end)
end

-- Event handler
CLFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- Only fires in WoW 11.x and below
        if KDT.Meter and KDT.Meter.ProcessCombatLogEvent then
            KDT.Meter:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if KDT.Meter and KDT.Meter.StartCombat then
            KDT.Meter:StartCombat()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if KDT.Meter and KDT.Meter.EndCombat then
            C_Timer.After(2, function()
                if not UnitAffectingCombat("player") and KDT.Meter then
                    KDT.Meter:EndCombat()
                end
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            if KDT.Meter and KDT.Meter.Initialize then
                KDT.Meter:Initialize()
            end
        end)
    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        -- WoW 12.0: Restriction state changed, update meter
        if KDT.Meter and KDT.Meter.UpdateRestrictionState then
            KDT.Meter:UpdateRestrictionState()
            KDT.Meter:RefreshAllWindows()
        end
    end
end)
