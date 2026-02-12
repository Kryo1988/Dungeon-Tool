-- Kryos Dungeon Tool
-- Modules/FoodReminder.lua - Consumable Reminder (Food, Flask, Rune, Weapon, Potions)
-- Checks active buffs + bag contents before M+ and dungeon content
-- WoW 12.0 compatible

local _, KDT = ...

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local CreateFrame = CreateFrame
local UIParent = UIParent
local C_Item = C_Item
local C_UnitAuras = C_UnitAuras
local C_Timer = C_Timer
local PlaySound = PlaySound
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local AuraUtil = AuraUtil
local format = string.format

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT.DB and KDT.DB.qol
end

---------------------------------------------------------------------------
-- BUFF DETECTION (TWW / WoW 12.0)
-- Instead of checking bag items, we check active buffs.
-- This catches ALL flask/food/rune variants automatically.
---------------------------------------------------------------------------

-- Known Flask/Phial buff spell IDs (TWW Season 1-2+)
local FLASK_SPELL_IDS = {
    -- TWW Flasks (all 3 quality ranks)
    432021, 432022, 432023,   -- Flask of Alchemical Chaos
    431972, 431973, 431974,   -- Flask of Tempered Mastery
    431975, 431976, 431977,   -- Flask of Tempered Versatility
    431978, 431979, 431980,   -- Flask of Tempered Haste
    431981, 431982, 431983,   -- Flask of Tempered Aggression (Crit)
    431984, 431985, 431986,   -- Flask of Tempered Swiftness
    431987, 431988, 431989,   -- Flask of Saving Graces
}

-- Known Augment Rune buff spell IDs
local RUNE_SPELL_IDS = {
    453256,   -- Crystallized Augment Rune (TWW)
    393438,   -- DF Augment Rune (fallback)
    270058,   -- Lightning-Forged Augment Rune
}

-- Well Fed buff spell ID
local FOOD_SPELL_IDS = {
    19705,    -- Well Fed (generic)
}

-- Health Potions to check in bags
local HEALTH_POTION_ITEMS = {
    -- TWW
    211878, 211879, 211880,   -- Algari Healing Potion (R1-R3)
    212242, 212243, 212244,   -- Cavedweller's Delight (R1-R3)
    -- Healthstones
    5512,                      -- Healthstone
    224464,                    -- Healthstone (alternate)
}

-- Combat Potions to check in bags
local COMBAT_POTION_ITEMS = {
    -- TWW Tempered Potions (R1-R3)
    212247, 212248, 212249,   -- Tempered Potion
    212259, 212260, 212261,   -- Potion of Unwavering Focus
    212265, 212266, 212267,   -- Frontline Potion
}

---------------------------------------------------------------------------
-- BUFF CHECKING FUNCTIONS
---------------------------------------------------------------------------

-- Check if player has ANY of the given spell IDs as a buff
local function HasAnyBuff(spellIDs)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return false end
    for _, spellID in ipairs(spellIDs) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if aura then
            return true, aura.name, aura.expirationTime
        end
    end
    return false
end

-- Scan all buffs for keyword match (catches unlisted variants)
local function ScanBuffsForKeyword(...)
    if not AuraUtil or not AuraUtil.ForEachAura then return false end
    local keywords = { ... }
    local found, foundName, foundExpire = false, nil, nil

    AuraUtil.ForEachAura("player", "HELPFUL", nil, function(auraData)
        if auraData and auraData.name then
            local lowerName = auraData.name:lower()
            for _, kw in ipairs(keywords) do
                if lowerName:find(kw:lower()) then
                    found = true
                    foundName = auraData.name
                    foundExpire = auraData.expirationTime
                    return true -- stop iteration
                end
            end
        end
    end)

    return found, foundName, foundExpire
end

-- Check for Well Fed buff
local function HasFoodBuff()
    local found, name, expTime = HasAnyBuff(FOOD_SPELL_IDS)
    if found then return true, name, expTime end
    -- Scan for "Well Fed" / "Satt" (DE) in buff name
    return ScanBuffsForKeyword("Well Fed", "Satt")
end

-- Check for Flask buff
local function HasFlaskBuff()
    local found, name, expTime = HasAnyBuff(FLASK_SPELL_IDS)
    if found then return true, name, expTime end
    -- Scan for flask/phial keywords (EN + DE)
    return ScanBuffsForKeyword("Flask", "Phial", "Fläschchen", "Phiole")
end

-- Check for Augment Rune buff
local function HasRuneBuff()
    local found, name, expTime = HasAnyBuff(RUNE_SPELL_IDS)
    if found then return true, name, expTime end
    return ScanBuffsForKeyword("Augment", "Verstärkungs")
end

-- Check for temporary weapon enchant (oils, sharpening stones, etc.)
local function HasWeaponEnchant()
    if not GetWeaponEnchantInfo then return false, false end
    local hasMainHand, _, _, _, hasOffHand = GetWeaponEnchantInfo()
    return hasMainHand or false, hasOffHand or false
end

-- Check bag contents for items
local function HasAnyItem(itemList)
    if not C_Item or not C_Item.GetItemCount then return false end
    local totalCount = 0
    for _, itemId in ipairs(itemList) do
        local count = C_Item.GetItemCount(itemId, false, false)
        if count and count > 0 then
            totalCount = totalCount + count
        end
    end
    return totalCount > 0, totalCount
end

---------------------------------------------------------------------------
-- TIME FORMATTING
---------------------------------------------------------------------------
local function FormatTimeRemaining(expirationTime)
    if not expirationTime or expirationTime == 0 then return "" end
    local remaining = expirationTime - GetTime()
    if remaining <= 0 then return "|cFFFF4444expired|r" end
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    if mins > 5 then
        return format("|cFF44FF44%dm|r", mins)
    elseif mins > 0 then
        return format("|cFFFFAA00%dm %ds|r", mins, secs)
    else
        return format("|cFFFF4444%ds|r", secs)
    end
end

---------------------------------------------------------------------------
-- REMINDER FRAME
---------------------------------------------------------------------------
local reminderFrame = nil
local reminderVisible = false

local function CreateReminderFrame()
    if reminderFrame then return reminderFrame end

    local f = CreateFrame("Frame", "KDTFoodReminderFrame", UIParent, "BackdropTemplate")
    f:SetSize(320, 160)
    f:SetPoint("TOP", UIParent, "TOP", 0, -100)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local qol = GetQoL()
        if qol then
            local point, _, _, xOfs, yOfs = self:GetPoint()
            qol.foodReminderPosition = { point = point, x = xOfs, y = yOfs }
        end
    end)

    f:SetBackdrop({
        bgFile = "Interface/BUTTONS/WHITE8X8",
        edgeFile = "Interface/BUTTONS/WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    f:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.6)

    -- Title bar accent
    local titleBar = f:CreateTexture(nil, "ARTWORK")
    titleBar:SetHeight(2)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    titleBar:SetColorTexture(0.23, 0.82, 0.93, 0.8)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText("|cFF3BD1ECConsumable Check|r")
    f.title = title

    -- Status text
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("TOP", title, "BOTTOM", 0, -10)
    status:SetWidth(295)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(true)
    status:SetSpacing(3)
    f.status = status

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -4, -4)
    local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(0.8, 0.3, 0.3)
    close:SetScript("OnClick", function() f:Hide(); reminderVisible = false end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.4, 0.4) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(0.8, 0.3, 0.3) end)

    -- Recheck button
    local recheck = CreateFrame("Button", nil, f, "BackdropTemplate")
    recheck:SetSize(90, 22)
    recheck:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
    recheck:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8", edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1 })
    recheck:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
    recheck:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.4)
    local recheckText = recheck:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    recheckText:SetPoint("CENTER")
    recheckText:SetText("|cFF3BD1ECRecheck|r")
    recheck:SetScript("OnClick", function() KDT:CheckConsumables() end)
    recheck:SetScript("OnEnter", function()
        recheck:SetBackdropColor(0.2, 0.2, 0.25, 0.9)
        recheck:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.8)
    end)
    recheck:SetScript("OnLeave", function()
        recheck:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
        recheck:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.4)
    end)

    -- ESC to close
    f:SetScript("OnShow", function()
        for i = 1, #UISpecialFrames do
            if UISpecialFrames[i] == "KDTFoodReminderFrame" then return end
        end
        table.insert(UISpecialFrames, "KDTFoodReminderFrame")
    end)

    -- Restore position
    local qol = GetQoL()
    if qol and qol.foodReminderPosition then
        local pos = qol.foodReminderPosition
        f:ClearAllPoints()
        f:SetPoint(pos.point or "TOP", UIParent, pos.point or "TOP", pos.x or 0, pos.y or -100)
    end

    f:Hide()
    reminderFrame = f
    return f
end

---------------------------------------------------------------------------
-- MAIN CHECK LOGIC
---------------------------------------------------------------------------
local function CheckConsumables()
    local qol = GetQoL()
    if not qol or not qol.foodReminderEnabled then return end

    local lines = {}
    local missing = 0
    local warnings = 0

    local GOOD  = "|cFF44FF44+|r "
    local BAD   = "|cFFFF4444X|r "
    local WARN  = "|cFFFFAA00!|r "

    -- 1) Flask / Phial
    if qol.foodReminderFlask ~= false then
        local hasFlask, flaskName, flaskExpire = HasFlaskBuff()
        if hasFlask then
            local timeStr = FormatTimeRemaining(flaskExpire)
            lines[#lines + 1] = format("%sFlask: %s %s", GOOD, flaskName or "Active", timeStr)
        else
            lines[#lines + 1] = BAD .. "Flask: |cFFFF6666Missing!|r"
            missing = missing + 1
        end
    end

    -- 2) Food (Well Fed)
    if qol.foodReminderFood ~= false then
        local hasFood, foodName, foodExpire = HasFoodBuff()
        if hasFood then
            local timeStr = FormatTimeRemaining(foodExpire)
            lines[#lines + 1] = format("%sFood: %s %s", GOOD, foodName or "Well Fed", timeStr)
        else
            lines[#lines + 1] = BAD .. "Food: |cFFFF6666Not Well Fed!|r"
            missing = missing + 1
        end
    end

    -- 3) Augment Rune
    if qol.foodReminderRune then
        local hasRune, runeName, runeExpire = HasRuneBuff()
        if hasRune then
            local timeStr = FormatTimeRemaining(runeExpire)
            lines[#lines + 1] = format("%sRune: %s %s", GOOD, runeName or "Active", timeStr)
        else
            lines[#lines + 1] = BAD .. "Augment Rune: |cFFFF6666Missing!|r"
            missing = missing + 1
        end
    end

    -- 4) Weapon Enchant (Oils, Stones, etc.)
    if qol.foodReminderWeapon then
        local hasMainHand = HasWeaponEnchant()
        if hasMainHand then
            lines[#lines + 1] = GOOD .. "Weapon Enchant: Active"
        else
            lines[#lines + 1] = BAD .. "Weapon Enchant: |cFFFF6666Missing!|r"
            missing = missing + 1
        end
    end

    -- 5) Health Potions (bag check)
    if qol.foodReminderHealthPot ~= false then
        local hasHP, hpCount = HasAnyItem(HEALTH_POTION_ITEMS)
        if hasHP then
            if hpCount <= 3 then
                lines[#lines + 1] = format("%sHealth Potions: |cFFFFAA00%d remaining|r", WARN, hpCount)
                warnings = warnings + 1
            else
                lines[#lines + 1] = format("%sHealth Potions: %d", GOOD, hpCount)
            end
        else
            lines[#lines + 1] = BAD .. "Health Potions: |cFFFF6666None!|r"
            missing = missing + 1
        end
    end

    -- 6) Combat Potions (bag check)
    if qol.foodReminderCombatPot then
        local hasCP, cpCount = HasAnyItem(COMBAT_POTION_ITEMS)
        if hasCP then
            if cpCount <= 2 then
                lines[#lines + 1] = format("%sCombat Potions: |cFFFFAA00%d remaining|r", WARN, cpCount)
                warnings = warnings + 1
            else
                lines[#lines + 1] = format("%sCombat Potions: %d", GOOD, cpCount)
            end
        else
            lines[#lines + 1] = BAD .. "Combat Potions: |cFFFF6666None!|r"
            missing = missing + 1
        end
    end

    -- Display result
    if missing > 0 or warnings > 0 then
        local f = CreateReminderFrame()
        f.status:SetText(table.concat(lines, "\n"))

        -- Resize to fit content
        local textHeight = f.status:GetStringHeight() or 60
        f:SetHeight(textHeight + 75)
        f:Show()
        reminderVisible = true

        -- Play sound for missing items
        if missing > 0 and qol.foodReminderSound then
            C_Timer.After(0.5, function()
                PlaySound(SOUNDKIT.RAID_WARNING, "Master")
            end)
        end
    else
        -- All good
        if reminderFrame and reminderVisible then
            reminderFrame:Hide()
            reminderVisible = false
        end
    end
end

---------------------------------------------------------------------------
-- EVENTS
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local lastCheckTime = 0
local CHECK_COOLDOWN = 5

local function OnEvent(self, event, ...)
    local qol = GetQoL()
    if not qol or not qol.foodReminderEnabled then return end

    local now = GetTime()
    if now - lastCheckTime < CHECK_COOLDOWN then return end

    if event == "GROUP_ROSTER_UPDATE" or event == "GROUP_JOINED" then
        if IsInGroup() then
            lastCheckTime = now
            C_Timer.After(2, CheckConsumables)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if IsInInstance() and IsInGroup() then
            lastCheckTime = now
            C_Timer.After(3, CheckConsumables)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if IsInInstance() and IsInGroup() then
            lastCheckTime = now
            C_Timer.After(2, CheckConsumables)
        end
    elseif event == "CHALLENGE_MODE_START" then
        lastCheckTime = now
        C_Timer.After(1, CheckConsumables)
    end
end

eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:SetScript("OnEvent", OnEvent)

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:CheckConsumables()
    CheckConsumables()
end

function KDT:CheckFoodReminder()
    CheckConsumables()
end
