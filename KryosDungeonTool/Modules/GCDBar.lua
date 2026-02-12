-- Kryos Dungeon Tool
-- Modules/GCDBar.lua - Global Cooldown Bar Indicator
-- Adapted from EnhanceQoL GCDBar.lua - WoW 12.0 compatible
-- Shows a StatusBar that fills/drains during GCD after casting

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- CONSTANTS & UPVALUES
---------------------------------------------------------------------------
local GCD_SPELL_ID = 61304
local DEFAULT_TEX = "Interface\\TargetingFrame\\UI-StatusBar"
local GetTime = GetTime

-- WoW 12.0: C_Spell.GetSpellCooldown returns a table
local function GetGCDCooldown()
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(GCD_SPELL_ID)
        if type(info) == "table" then
            return info.startTime, info.duration, info.isEnabled, info.modRate or 1
        end
        return info -- fallback for older API returning multiple values
    elseif GetSpellCooldown then
        return GetSpellCooldown(GCD_SPELL_ID)
    end
    return nil
end

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local gcdFrame = nil
local gcdActive = false
local gcdStart = 0
local gcdDuration = 0
local gcdModRate = 1
local eventsRegistered = false

---------------------------------------------------------------------------
-- SETTINGS HELPERS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT and KDT.DB and KDT.DB.qol
end

local function GetSetting(key, fallback)
    local qol = GetQoL()
    if not qol then return fallback end
    local v = qol[key]
    if v == nil then return fallback end
    return v
end

---------------------------------------------------------------------------
-- FRAME CREATION
---------------------------------------------------------------------------
local function EnsureFrame()
    if gcdFrame then return gcdFrame end

    local bar = CreateFrame("StatusBar", "KDT_GCDBar", UIParent)
    bar:SetMinMaxValues(0, 1)
    bar:SetClampedToScreen(true)
    bar:SetMovable(true)
    bar:EnableMouse(false) -- not interactive by default
    bar:Hide()

    -- Status bar texture
    bar:SetStatusBarTexture(DEFAULT_TEX)
    bar:SetStatusBarColor(1, 0.82, 0.2, 1) -- gold

    -- Background
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0, 0, 0, 0.5)
    bar.bg = bg

    -- Border
    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    border:SetFrameLevel((bar:GetFrameLevel() or 0) + 2)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 0.8)
    bar.border = border

    -- Drag label (only visible when unlocked)
    local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText("GCD Bar (drag)")
    label:Hide()
    bar.label = label

    gcdFrame = bar
    return bar
end

---------------------------------------------------------------------------
-- APPEARANCE & SIZE
---------------------------------------------------------------------------
local function ApplyAppearance()
    if not gcdFrame then return end
    local width = GetSetting("gcdBarWidth", 200)
    local height = GetSetting("gcdBarHeight", 18)
    gcdFrame:SetSize(width, height)

    -- Color
    local color = GetSetting("gcdBarColor", nil)
    if type(color) == "table" then
        gcdFrame:SetStatusBarColor(color.r or 1, color.g or 0.82, color.b or 0.2, color.a or 1)
    else
        gcdFrame:SetStatusBarColor(1, 0.82, 0.2, 1)
    end

    -- Background toggle
    if gcdFrame.bg then
        if GetSetting("gcdBarShowBackground", true) then
            gcdFrame.bg:Show()
        else
            gcdFrame.bg:Hide()
        end
    end

    -- Border toggle
    if gcdFrame.border then
        if GetSetting("gcdBarShowBorder", true) then
            gcdFrame.border:Show()
        else
            gcdFrame.border:Hide()
        end
    end

    -- Reverse fill direction
    if gcdFrame.SetReverseFill then
        gcdFrame:SetReverseFill(GetSetting("gcdBarFillReverse", false))
    end
end

local function ApplyPosition()
    if not gcdFrame then return end
    gcdFrame:ClearAllPoints()
    local pos = GetSetting("gcdBarPosition", nil)
    if type(pos) == "table" and pos.point then
        gcdFrame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or -120)
    else
        gcdFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end
end

---------------------------------------------------------------------------
-- GCD TIMER LOGIC (from original)
---------------------------------------------------------------------------
local function StopTimer()
    if gcdFrame and gcdFrame.SetScript then gcdFrame:SetScript("OnUpdate", nil) end
    gcdActive = false
    gcdStart = 0
    gcdDuration = 0
    gcdModRate = 1
    if gcdFrame then gcdFrame:Hide() end
end

local function UpdateTimer()
    if not gcdFrame then return end
    if not gcdActive then return end
    if not gcdStart or gcdDuration <= 0 then
        StopTimer()
        return
    end
    local now = GetTime()
    local rate = gcdModRate or 1
    local elapsed = (now - gcdStart) * rate
    if elapsed >= gcdDuration then
        StopTimer()
        return
    end
    local progress = elapsed / gcdDuration
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    -- Default: show remaining (bar drains)
    local value = 1 - progress
    if GetSetting("gcdBarShowElapsed", false) then
        value = progress -- bar fills
    end

    gcdFrame:SetMinMaxValues(0, 1)
    gcdFrame:SetValue(value)
    gcdFrame:Show()
end

local function UpdateGCD()
    if not gcdFrame then return end

    local start, duration, enabled, modRate = GetGCDCooldown()
    if not enabled or not duration or duration <= 0 or not start or start <= 0 then
        StopTimer()
        return
    end
    gcdActive = true
    gcdStart = start
    gcdDuration = duration
    gcdModRate = modRate or 1
    gcdFrame:SetScript("OnUpdate", UpdateTimer)
    UpdateTimer()
end

---------------------------------------------------------------------------
-- UNLOCK/LOCK FOR POSITIONING
---------------------------------------------------------------------------
local isUnlocked = false

local function UnlockBar()
    if not gcdFrame then return end
    isUnlocked = true
    gcdFrame:EnableMouse(true)
    gcdFrame:RegisterForDrag("LeftButton")
    gcdFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    gcdFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, x, y = self:GetPoint()
        local qol = GetQoL()
        if qol then
            qol.gcdBarPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
        end
    end)
    gcdFrame.label:Show()
    gcdFrame:SetMinMaxValues(0, 1)
    gcdFrame:SetValue(0.65) -- preview value
    gcdFrame:Show()
    if KDT.Print then KDT:Print("GCD Bar |cFF44FF44unlocked|r. Drag to reposition.") end
end

local function LockBar()
    if not gcdFrame then return end
    isUnlocked = false
    gcdFrame:EnableMouse(false)
    gcdFrame:SetScript("OnDragStart", nil)
    gcdFrame:SetScript("OnDragStop", nil)
    gcdFrame.label:Hide()
    gcdFrame:Hide()
    if KDT.Print then KDT:Print("GCD Bar |cFFFF4444locked|r.") end
end

---------------------------------------------------------------------------
-- ENABLE / DISABLE
---------------------------------------------------------------------------
local function EnableGCDBar()
    local bar = EnsureFrame()
    ApplyAppearance()
    ApplyPosition()

    if not eventsRegistered then
        bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        bar:SetScript("OnEvent", function(_, event, ...)
            if event == "SPELL_UPDATE_COOLDOWN" then
                UpdateGCD()
            end
        end)
        eventsRegistered = true
    end
end

local function DisableGCDBar()
    if not gcdFrame then return end
    StopTimer()
    if eventsRegistered then
        gcdFrame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
        gcdFrame:SetScript("OnEvent", nil)
        eventsRegistered = false
    end
    gcdFrame:Hide()
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:InitGCDBar()
    local qol = GetQoL()
    if not qol or not qol.gcdBarEnabled then
        DisableGCDBar()
        return
    end
    EnableGCDBar()
end

function KDT:ToggleGCDBarLock()
    if isUnlocked then
        LockBar()
    else
        if not gcdFrame then EnsureFrame() end
        ApplyAppearance()
        ApplyPosition()
        UnlockBar()
    end
end

function KDT:RefreshGCDBar()
    if not gcdFrame then return end
    ApplyAppearance()
    ApplyPosition()
end
