-- Kryos Dungeon Tool
-- Modules/FoodReminder.lua - Consumable Reminder
-- WoW 12.0 compatible: NO aura field access (secret values), only spell ID existence checks
-- Checks player + group members, post-to-chat support

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
local UnitName = UnitName
local UnitExists = UnitExists
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid = IsInRaid
local format = string.format
local tinsert = table.insert
local tconcat = table.concat

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT.DB and KDT.DB.qol
end

---------------------------------------------------------------------------
-- BUFF SPELL IDs (comprehensive, WoW 12.0 / TWW / Midnight)
-- We ONLY check existence via GetPlayerAuraBySpellID / GetAuraDataBySpellID
-- NEVER access .name, .duration, etc (secret values crash)
---------------------------------------------------------------------------

-- Flask / Phial buff spell IDs
local FLASK_SPELL_IDS = {
    -- TWW Flasks (R1-R3)
    432021, 432022, 432023,   -- Flask of Alchemical Chaos
    431972, 431973, 431974,   -- Flask of Tempered Mastery
    431975, 431976, 431977,   -- Flask of Tempered Versatility
    431978, 431979, 431980,   -- Flask of Tempered Haste
    431981, 431982, 431983,   -- Flask of Tempered Aggression (Crit)
    431984, 431985, 431986,   -- Flask of Tempered Swiftness
    431987, 431988, 431989,   -- Flask of Saving Graces
    -- PvP Flasks
    432024, 432025, 432026,   -- Vicious Flask of Honor
    432027, 432028, 432029,   -- Vicious Flask of Classical Spirits
    432030, 432031, 432032,   -- Vicious Flask of the Wrecking Ball
    432033, 432034, 432035,   -- Vicious Flask of Manifested Fury
    -- Midnight Flasks (placeholders for future IDs)
    -- Dragonflight Phials (still usable in some content)
    371354, 371355, 371356,   -- Phial of Icy Preservation
    371386, 371387, 371388,   -- Phial of Charged Isolation
    371339, 371340, 371341,   -- Phial of Static Empowerment
    371357, 371358, 371359,   -- Phial of Glacial Fury
    373257, 373258, 373259,   -- Phial of Tepid Versatility
}

-- Food (Well Fed) buff spell IDs
local FOOD_SPELL_IDS = {
    -- Generic Well Fed
    19705,
    -- TWW individual food buffs (stat foods)
    462210, 462211, 462212,   -- TWW Crit food
    462213, 462214, 462215,   -- TWW Haste food
    462216, 462217, 462218,   -- TWW Mastery food
    462219, 462220, 462221,   -- TWW Versatility food
    462222, 462223, 462224,   -- TWW Primary stat food
    -- TWW Feasts
    445113, 445114, 445115,   -- Feast of the Divine Day
    445116, 445117, 445118,   -- Feast of the Midnight Masquerade
    1237104,                   -- Blooming Feast
    1278909,                   -- Hearty Blooming Feast
    -- TWW Hearty food (persists through death)
    462310, 462311, 462312,
    462313, 462314, 462315,
    462316, 462317, 462318,
    -- TWW misc food
    461894, 461895, 461896,   -- Sushi Special variants
    461897, 461898, 461899,   -- Beledar's Bounty variants
    461900, 461901, 461902,   -- Cave Pepper variants
    -- Earthen gem food (Ingest Minerals racial)
    461960, 461961, 461962, 461963,
    -- Conjured Mana food (Mage)
    80167,                     -- Conjured Mana Bun buff
    -- Fiery Fish Sticks (TWW)
    461860,                    -- Fiery Fish Sticks Well Fed buff
    -- DF food (still usable)
    382134, 382135, 382136, 382137,
}

-- Augment Rune buff spell IDs
local RUNE_SPELL_IDS = {
    453256,   -- Crystallized Augment Rune buff (TWW)
    453250,   -- Crystallized Augment Rune (alternate buff ID)
    393438,   -- DF Augment Rune
    270058,   -- Lightning-Forged Augment Rune
    347901,   -- Veiled Augment Rune
}

-- Health Potions (bag check)
local HEALTH_POTION_ITEMS = {
    211878, 211879, 211880,   -- Algari Healing Potion (R1-R3)
    212242, 212243, 212244,   -- Cavedweller's Delight (R1-R3)
    244839,                    -- Invigorating Healing Potion
    5512,                      -- Healthstone
    224464,                    -- Healthstone (alternate)
}

-- Combat Potions (bag check)
local COMBAT_POTION_ITEMS = {
    212247, 212248, 212249,   -- Tempered Potion (R1-R3)
    212259, 212260, 212261,   -- Potion of Unwavering Focus (R1-R3)
    212265, 212266, 212267,   -- Frontline Potion (R1-R3)
}

---------------------------------------------------------------------------
-- SAFE BUFF CHECK (WoW 12.0 - no field access, only existence)
---------------------------------------------------------------------------

-- Check if a unit has ANY of the given spell IDs as a buff
-- Returns true/false ONLY - no name/duration (secret values)
local function UnitHasAnyBuff(unit, spellIDs)
    if not C_UnitAuras then return false end

    local checkFn
    if unit == "player" and C_UnitAuras.GetPlayerAuraBySpellID then
        checkFn = function(id)
            return C_UnitAuras.GetPlayerAuraBySpellID(id) ~= nil
        end
    elseif C_UnitAuras.GetAuraDataBySpellID then
        checkFn = function(id)
            return C_UnitAuras.GetAuraDataBySpellID(unit, id) ~= nil
        end
    else
        return false
    end

    for _, spellID in ipairs(spellIDs) do
        local ok, result = pcall(checkFn, spellID)
        if ok and result then
            return true
        end
    end
    return false
end

-- Check for temporary weapon enchant
local function HasWeaponEnchant()
    if not GetWeaponEnchantInfo then return false end
    local ok, hasMainHand = pcall(GetWeaponEnchantInfo)
    return ok and hasMainHand or false
end

-- Check bag contents for items
local function HasAnyItem(itemList)
    if not C_Item or not C_Item.GetItemCount then return false, 0 end
    local totalCount = 0
    for _, itemId in ipairs(itemList) do
        local ok, count = pcall(C_Item.GetItemCount, itemId, false, false)
        if ok and count and count > 0 then
            totalCount = totalCount + count
        end
    end
    return totalCount > 0, totalCount
end

---------------------------------------------------------------------------
-- CHECK LOGIC
---------------------------------------------------------------------------

-- Check one unit for all enabled consumables
-- Returns table of { category, status, detail }
local function CheckUnit(unit, qol)
    local results = {}

    -- Flask
    if qol.foodReminderFlask ~= false then
        local has = UnitHasAnyBuff(unit, FLASK_SPELL_IDS)
        tinsert(results, { cat = "Flask", ok = has })
    end

    -- Food
    if qol.foodReminderFood ~= false then
        local has = UnitHasAnyBuff(unit, FOOD_SPELL_IDS)
        tinsert(results, { cat = "Food", ok = has })
    end

    -- Rune
    if qol.foodReminderRune then
        local has = UnitHasAnyBuff(unit, RUNE_SPELL_IDS)
        tinsert(results, { cat = "Rune", ok = has })
    end

    -- Weapon (player only)
    if qol.foodReminderWeapon and unit == "player" then
        local has = HasWeaponEnchant()
        tinsert(results, { cat = "Weapon", ok = has })
    end

    -- Potions (player only, bag check)
    if qol.foodReminderHealthPot ~= false and unit == "player" then
        local has, count = HasAnyItem(HEALTH_POTION_ITEMS)
        tinsert(results, { cat = "HP Pot", ok = has, count = count, warn = (has and count <= 3) })
    end

    if qol.foodReminderCombatPot and unit == "player" then
        local has, count = HasAnyItem(COMBAT_POTION_ITEMS)
        tinsert(results, { cat = "Combat Pot", ok = has, count = count, warn = (has and count <= 2) })
    end

    return results
end

-- Get party/raid unit IDs
local function GetGroupUnits()
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
                tinsert(units, unit)
            end
        end
    elseif IsInGroup() then
        tinsert(units, "player")
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
                tinsert(units, unit)
            end
        end
    else
        tinsert(units, "player")
    end
    return units
end

---------------------------------------------------------------------------
-- REMINDER FRAME
---------------------------------------------------------------------------
local reminderFrame = nil
local reminderVisible = false
local lastCheckResults = {} -- stored for Post to Chat

local function CreateReminderFrame()
    if reminderFrame then return reminderFrame end

    local f = CreateFrame("Frame", "KDTFoodReminderFrame", UIParent, "BackdropTemplate")
    f:SetSize(340, 200)
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
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetColorTexture(0.23, 0.82, 0.93, 0.8)

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cFF3BD1ECConsumable Check|r")

    -- Status text
    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.status:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
    f.status:SetWidth(315)
    f.status:SetJustifyH("LEFT")
    f.status:SetWordWrap(true)
    f.status:SetSpacing(3)

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

    -- Button bar
    local btnY = 8
    local btnH = 22

    -- Helper to create dark buttons
    local function CreateDarkButton(parent, width, text, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(width, btnH)
        btn:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8", edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1 })
        btn:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
        btn:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.4)
        local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("CENTER")
        t:SetText("|cFF3BD1EC" .. text .. "|r")
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.2, 0.2, 0.25, 0.9)
            btn:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.8)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
            btn:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.4)
        end)
        return btn
    end

    -- Recheck button
    f.recheckBtn = CreateDarkButton(f, 80, "Recheck", function()
        KDT:CheckConsumables()
    end)
    f.recheckBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, btnY)

    -- Post to Party button
    f.postBtn = CreateDarkButton(f, 110, "Post to Party", function()
        KDT:PostConsumablesToChat()
    end)
    f.postBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, btnY)

    -- ESC to close
    f:SetScript("OnShow", function()
        for i = 1, #UISpecialFrames do
            if UISpecialFrames[i] == "KDTFoodReminderFrame" then return end
        end
        tinsert(UISpecialFrames, "KDTFoodReminderFrame")
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
-- FORMAT & DISPLAY
---------------------------------------------------------------------------
local GOOD = "|cFF44FF44+|r "
local BAD  = "|cFFFF4444X|r "
local WARN = "|cFFFFAA00!|r "

local function FormatResult(r)
    if r.ok then
        if r.warn then
            return format("%s%s: |cFFFFAA00%d left|r", WARN, r.cat, r.count or 0)
        elseif r.count then
            return format("%s%s: %d", GOOD, r.cat, r.count)
        else
            return format("%s%s: Active", GOOD, r.cat)
        end
    else
        return format("%s%s: |cFFFF6666Missing!|r", BAD, r.cat)
    end
end

local function FormatUnitName(unit)
    local name = UnitName(unit) or unit
    local _, classFile = UnitClass(unit)
    if classFile and RAID_CLASS_COLORS[classFile] then
        local c = RAID_CLASS_COLORS[classFile]
        return format("|cFF%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
    end
    return name
end

---------------------------------------------------------------------------
-- MAIN CHECK
---------------------------------------------------------------------------
local function CheckConsumables()
    local qol = GetQoL()
    if not qol or not qol.foodReminderEnabled then return end

    local lines = {}
    local anyMissing = false
    local anyWarning = false
    lastCheckResults = {}

    -- Check player first
    local playerResults = CheckUnit("player", qol)
    local playerLines = {}
    local playerMissing = false
    for _, r in ipairs(playerResults) do
        tinsert(playerLines, "  " .. FormatResult(r))
        if not r.ok then playerMissing = true; anyMissing = true end
        if r.warn then anyWarning = true end
    end

    tinsert(lines, "|cFF3BD1ECYou:|r")
    for _, l in ipairs(playerLines) do tinsert(lines, l) end
    lastCheckResults["player"] = playerResults

    -- Check group members (only buffs, not bags)
    if qol.foodReminderCheckGroup and IsInGroup() then
        local units = GetGroupUnits()
        for _, unit in ipairs(units) do
            if unit ~= "player" then
                local name = UnitName(unit)
                if name then
                    local memberResults = CheckUnit(unit, qol)
                    local memberMissing = false
                    local memberLines = {}

                    for _, r in ipairs(memberResults) do
                        -- Only show missing items for group members
                        if not r.ok then
                            tinsert(memberLines, "  " .. FormatResult(r))
                            memberMissing = true
                            anyMissing = true
                        end
                    end

                    if memberMissing then
                        tinsert(lines, "")
                        tinsert(lines, FormatUnitName(unit) .. ":")
                        for _, l in ipairs(memberLines) do tinsert(lines, l) end
                    end
                    lastCheckResults[unit] = memberResults
                end
            end
        end
    end

    -- Show frame if anything is wrong
    if anyMissing or anyWarning then
        local f = CreateReminderFrame()
        f.status:SetText(tconcat(lines, "\n"))

        -- Resize to fit
        local textHeight = f.status:GetStringHeight() or 60
        f:SetHeight(textHeight + 80)

        -- Show/hide post button based on group
        f.postBtn:SetShown(IsInGroup())

        f:Show()
        reminderVisible = true

        -- Sound
        if anyMissing and qol.foodReminderSound then
            C_Timer.After(0.5, function()
                PlaySound(SOUNDKIT.RAID_WARNING, "Master")
            end)
        end
    else
        if reminderFrame and reminderVisible then
            reminderFrame:Hide()
            reminderVisible = false
        end
    end
end

---------------------------------------------------------------------------
-- POST TO CHAT
---------------------------------------------------------------------------
local function PostConsumablesToChat()
    local qol = GetQoL()
    if not qol then return end

    local chatLines = {}
    tinsert(chatLines, "[KDT] Consumable Check:")

    for unit, results in pairs(lastCheckResults) do
        local name = UnitName(unit) or unit
        local missing = {}
        for _, r in ipairs(results) do
            if not r.ok then
                tinsert(missing, r.cat)
            elseif r.warn then
                tinsert(missing, r.cat .. " (low)")
            end
        end

        if #missing > 0 then
            tinsert(chatLines, format("  %s: Missing %s", name, tconcat(missing, ", ")))
        end
    end

    if #chatLines <= 1 then
        tinsert(chatLines, "  All consumables OK!")
    end

    -- Send to party/raid chat
    local channel = IsInRaid() and "RAID" or "PARTY"
    for _, line in ipairs(chatLines) do
        SendChatMessage(line, channel)
    end
end

---------------------------------------------------------------------------
-- EVENTS - DUNGEON/M+ ONLY
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local lastCheckTime = 0
local CHECK_COOLDOWN = 8

local function OnEvent(self, event, ...)
    local qol = GetQoL()
    if not qol or not qol.foodReminderEnabled then return end

    local now = GetTime()
    if now - lastCheckTime < CHECK_COOLDOWN then return end

    if event == "CHALLENGE_MODE_START" then
        -- Always check at M+ start
        lastCheckTime = now
        C_Timer.After(1.5, CheckConsumables)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInstance, instanceType = IsInInstance()
        -- Only trigger in party/raid instances (not arena/pvp/scenarios)
        if isInstance and (instanceType == "party" or instanceType == "raid") and IsInGroup() then
            lastCheckTime = now
            C_Timer.After(3, CheckConsumables)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local isInstance, instanceType = IsInInstance()
        if isInstance and (instanceType == "party" or instanceType == "raid") and IsInGroup() then
            lastCheckTime = now
            C_Timer.After(2, CheckConsumables)
        end
    end
end

eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:SetScript("OnEvent", OnEvent)

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:CheckConsumables()
    CheckConsumables()
end

function KDT:PostConsumablesToChat()
    PostConsumablesToChat()
end

-- Backward compat
function KDT:CheckFoodReminder()
    CheckConsumables()
end
