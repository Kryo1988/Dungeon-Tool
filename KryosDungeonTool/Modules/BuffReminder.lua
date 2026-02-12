-- Kryos Dungeon Tool
-- Modules/BuffReminder.lua - Consumable Buff Reminder for M+
-- Adapted from EnhanceQoL FoodReminder.lua pattern - WoW 12.0 compatible
-- Shows a bouncing warning icon when missing Well Fed / Flask / Augment Rune
-- before Mythic+ keystones

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local CreateFrame = CreateFrame
local UIParent = UIParent
local UnitBuff = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex or UnitBuff
local GetTime = GetTime
local C_Timer = C_Timer
local C_ChallengeMode = C_ChallengeMode

---------------------------------------------------------------------------
-- BUFF CATEGORY SPELL IDS (WoW 12.0 / The War Within)
-- These are the aura *categories* to check, not specific spell IDs
-- We check by buff subtype/name patterns for maximum compatibility
---------------------------------------------------------------------------
local WELL_FED_SPELL_NAME = "Well Fed"        -- localized via GetSpellInfo at init
local WELL_FED_PATTERN = nil                    -- set at init time

-- Flask/Phial buff names (checked by partial match)
local FLASK_PATTERNS = {
    "Flask of",
    "Phial of",
    "Cauldron",
}

-- Augment Rune
local RUNE_PATTERNS = {
    "Augment",
    "Dreambound",  -- TWW augment rune
}

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local reminderFrame = nil
local reminderIcon = nil
local reminderText = nil
local bounceAnim = nil
local isShowing = false
local isUnlocked = false

---------------------------------------------------------------------------
-- SETTINGS
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
-- BUFF CHECKING (WoW 12.0 API: C_UnitAuras)
---------------------------------------------------------------------------
local function HasBuffMatching(patterns)
    if not patterns then return false end
    for i = 1, 40 do
        local auraData
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        end
        if not auraData then break end
        local name = auraData.name
        if name then
            for _, pattern in ipairs(patterns) do
                if name:find(pattern, 1, true) then return true end
            end
        end
    end
    return false
end

local function HasWellFedBuff()
    -- Check for "Well Fed" specifically
    for i = 1, 40 do
        local auraData
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        end
        if not auraData then break end
        local name = auraData.name
        if name and (name == WELL_FED_SPELL_NAME or (WELL_FED_PATTERN and name:find(WELL_FED_PATTERN, 1, true))) then
            return true
        end
        -- Also check for the eating/drinking intermediate buff that leads to Well Fed
        -- Some food gives "Well Fed" directly as the buff name
    end
    return false
end

local function HasFlaskBuff()
    return HasBuffMatching(FLASK_PATTERNS)
end

local function HasRuneBuff()
    return HasBuffMatching(RUNE_PATTERNS)
end

---------------------------------------------------------------------------
-- MISSING BUFFS TEXT
---------------------------------------------------------------------------
local function GetMissingBuffsText()
    local missing = {}
    local qol = GetQoL()
    if not qol then return nil end

    if qol.buffReminderFood and not HasWellFedBuff() then
        missing[#missing + 1] = "|cFFFF6666Food|r"
    end
    if qol.buffReminderFlask and not HasFlaskBuff() then
        missing[#missing + 1] = "|cFF6699FFFlask|r"
    end
    if qol.buffReminderRune and not HasRuneBuff() then
        missing[#missing + 1] = "|cFF66FF66Rune|r"
    end

    if #missing == 0 then return nil end
    return "Missing: " .. table.concat(missing, ", ")
end

---------------------------------------------------------------------------
-- FRAME CREATION (from original pattern: bouncing icon + text)
---------------------------------------------------------------------------
local function EnsureFrame()
    if reminderFrame then return reminderFrame end

    local frame = CreateFrame("Frame", "KDT_BuffReminderFrame", UIParent, "BackdropTemplate")
    frame:SetSize(48, 48)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:Hide()

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)
    frame.bg = bg

    -- Exclamation icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    reminderIcon = icon

    -- Missing buffs text below
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    text:SetText("")
    reminderText = text

    -- Bounce animation (from original)
    local animGroup = frame:CreateAnimationGroup()
    local up = animGroup:CreateAnimation("Translation")
    up:SetOffset(0, 30)
    up:SetDuration(0.8)
    up:SetSmoothing("OUT")
    up:SetOrder(1)

    local down = animGroup:CreateAnimation("Translation")
    down:SetOffset(0, -30)
    down:SetDuration(0.8)
    down:SetSmoothing("IN")
    down:SetOrder(2)

    animGroup:SetLooping("REPEAT")
    bounceAnim = animGroup

    -- Drag support (when unlocked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if isUnlocked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        local qol = GetQoL()
        if qol then
            qol.buffReminderPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
        end
    end)

    reminderFrame = frame
    return frame
end

---------------------------------------------------------------------------
-- POSITION
---------------------------------------------------------------------------
local function ApplyPosition()
    if not reminderFrame then return end
    reminderFrame:ClearAllPoints()
    local pos = GetSetting("buffReminderPosition", nil)
    if type(pos) == "table" and pos.point then
        reminderFrame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or -100)
    else
        reminderFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end
end

---------------------------------------------------------------------------
-- SHOW / HIDE
---------------------------------------------------------------------------
local function ShowReminder(missingText)
    local frame = EnsureFrame()
    ApplyPosition()
    reminderText:SetText(missingText or "")
    frame:Show()
    if bounceAnim and not bounceAnim:IsPlaying() then
        bounceAnim:Play()
    end
    isShowing = true
end

local function HideReminder()
    if not reminderFrame then return end
    if bounceAnim and bounceAnim:IsPlaying() then
        bounceAnim:Stop()
    end
    reminderFrame:Hide()
    isShowing = false
end

---------------------------------------------------------------------------
-- CHECK LOGIC (when to show reminder)
---------------------------------------------------------------------------
local function ShouldShowReminder()
    local qol = GetQoL()
    if not qol or not qol.buffReminderEnabled then return false end

    -- Only in M+ or when at keystone NPC
    -- Check if in challenge mode dungeon (not yet started = lobby time)
    local inInstance, instanceType = IsInInstance()

    -- Show when in a party dungeon (before key is started)
    if inInstance and instanceType == "party" then
        -- Check if it's a M+ dungeon (active key exists)
        local activeKeyInfo = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
        local isActive = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()

        -- Show in dungeon if NOT yet in active challenge mode (= before key insert)
        -- OR always if setting says to check everywhere
        if qol.buffReminderAlways or (activeKeyInfo and not isActive) then
            return true
        end
    end

    -- Option: check everywhere (not just dungeons)
    if qol.buffReminderAlways then
        return true
    end

    return false
end

local function CheckBuffReminder()
    if not ShouldShowReminder() then
        HideReminder()
        return
    end

    local missingText = GetMissingBuffsText()
    if missingText then
        ShowReminder(missingText)
    else
        HideReminder()
    end
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local checkPending = false

local function ScheduleCheck()
    if checkPending then return end
    checkPending = true
    C_Timer.After(0.5, function()
        checkPending = false
        CheckBuffReminder()
    end)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialize Well Fed localized name
        if GetSpellInfo then
            local name = GetSpellInfo(104280) -- Well Fed spell
            if name then WELL_FED_SPELL_NAME = name end
        end
        ScheduleCheck()
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then ScheduleCheck() end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_COMPLETED" then
        ScheduleCheck()
    elseif event == "GROUP_ROSTER_UPDATE" then
        ScheduleCheck()
    end
end)

---------------------------------------------------------------------------
-- UNLOCK/LOCK
---------------------------------------------------------------------------
function KDT:ToggleBuffReminderLock()
    if not reminderFrame then EnsureFrame() end
    ApplyPosition()
    if isUnlocked then
        isUnlocked = false
        reminderFrame:EnableMouse(false)
        reminderFrame.bg:SetColorTexture(0, 0, 0, 0.6)
        CheckBuffReminder() -- restore normal state
        if KDT.Print then KDT:Print("Buff Reminder |cFFFF4444locked|r.") end
    else
        isUnlocked = true
        reminderFrame:EnableMouse(true)
        reminderFrame.bg:SetColorTexture(0.1, 0.5, 0.1, 0.6)
        reminderText:SetText("Buff Reminder (drag)")
        reminderFrame:Show()
        if bounceAnim and not bounceAnim:IsPlaying() then bounceAnim:Play() end
        if KDT.Print then KDT:Print("Buff Reminder |cFF44FF44unlocked|r. Drag to reposition.") end
    end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:InitBuffReminder()
    local qol = GetQoL()
    if not qol or not qol.buffReminderEnabled then
        HideReminder()
        eventFrame:UnregisterAllEvents()
        return
    end

    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    ScheduleCheck()
end
