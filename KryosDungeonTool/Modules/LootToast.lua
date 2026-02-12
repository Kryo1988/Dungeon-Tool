-- Kryos Dungeon Tool
-- Modules/LootToast.lua - Loot Toast Filter & Enhancement
-- Adapted from EnhanceQoL LootToast.lua - WoW 12.0 compatible
-- Filters loot toasts by quality and item level thresholds, shows upgrade indicators

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local GetTime = GetTime
local GetInventoryItemLink = GetInventoryItemLink
local UnitGUID = UnitGUID
local C_Item = C_Item
local myGUID = nil

---------------------------------------------------------------------------
-- EQUIP SLOT MAPPINGS (from original)
---------------------------------------------------------------------------
local EQUIP_LOC_TO_SLOTS = {
    INVTYPE_HEAD = { INVSLOT_HEAD },
    INVTYPE_NECK = { INVSLOT_NECK },
    INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
    INVTYPE_CLOAK = { INVSLOT_BACK },
    INVTYPE_CHEST = { INVSLOT_CHEST },
    INVTYPE_ROBE = { INVSLOT_CHEST },
    INVTYPE_WRIST = { INVSLOT_WRIST },
    INVTYPE_HAND = { INVSLOT_HAND },
    INVTYPE_WAIST = { INVSLOT_WAIST },
    INVTYPE_LEGS = { INVSLOT_LEGS },
    INVTYPE_FEET = { INVSLOT_FEET },
    INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND },
    INVTYPE_2HWEAPON = { INVSLOT_MAINHAND },
    INVTYPE_SHIELD = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE = { INVSLOT_OFFHAND },
    INVTYPE_RANGED = { INVSLOT_MAINHAND },
    INVTYPE_RANGEDRIGHT = { INVSLOT_MAINHAND },
}

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local toastFrame = CreateFrame("Frame")
local enabled = false
local alertFrameHooked = false
local handleToasts = false

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
-- ITEM LEVEL HELPERS
---------------------------------------------------------------------------
local function GetItemLevelFromLink(link)
    if not link then return nil end
    if GetDetailedItemLevelInfo then
        local level = GetDetailedItemLevelInfo(link)
        if level then return level end
    end
    if C_Item and C_Item.GetItemInfo then
        return select(4, C_Item.GetItemInfo(link))
    end
    return nil
end

local function IsUpgradeForPlayer(itemLink, itemEquipLoc)
    if not itemEquipLoc or itemEquipLoc == "" then return false end
    local slotsForLoc = EQUIP_LOC_TO_SLOTS[itemEquipLoc]
    if not slotsForLoc or #slotsForLoc == 0 then return false end

    local newItemLevel = GetItemLevelFromLink(itemLink)
    if not newItemLevel then return false end

    local lowestEquippedLevel = nil
    for _, slotID in ipairs(slotsForLoc) do
        local link = GetInventoryItemLink("player", slotID)
        if not link or link == "" then return true end -- empty slot = upgrade
        local equippedLevel = GetItemLevelFromLink(link)
        if equippedLevel then
            if not lowestEquippedLevel or equippedLevel < lowestEquippedLevel then
                lowestEquippedLevel = equippedLevel
            end
        end
    end

    if not lowestEquippedLevel then return false end
    return newItemLevel > lowestEquippedLevel
end

---------------------------------------------------------------------------
-- FILTER LOGIC (adapted from original)
---------------------------------------------------------------------------
local BLACKLISTED_EVENTS = {
    SHOW_LOOT_TOAST = true,
}

local function ShouldShowToast(itemLink)
    if not GetSetting("lootToastFilterEnabled", false) then return true end

    local _, _, quality, _, _, _, _, _, itemEquipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink)
    if not quality then return true end -- can't determine quality, show it

    -- Check minimum quality threshold
    local minQuality = GetSetting("lootToastMinQuality", 3) -- default: Rare
    if quality < minQuality then return false end

    -- Check item level threshold for equipment
    local minIlvl = GetSetting("lootToastMinIlvl", 0)
    if minIlvl > 0 and itemEquipLoc and itemEquipLoc ~= "" then
        local ilvl = GetItemLevelFromLink(itemLink)
        if ilvl and ilvl < minIlvl then return false end
    end

    -- Check upgrade filter (only show upgrades)
    if GetSetting("lootToastOnlyUpgrades", false) then
        if itemEquipLoc and itemEquipLoc ~= "" then
            if not IsUpgradeForPlayer(itemLink, itemEquipLoc) then return false end
        end
    end

    return true
end

---------------------------------------------------------------------------
-- EVENT HANDLING (from original)
---------------------------------------------------------------------------
local ITEM_LINK_PATTERN = "|Hitem:.-|h%[.-%]|h|r"

local function OnEvent(_, event, ...)
    if event == "SHOW_LOOT_TOAST" then
        local typeIdentifier, itemLink, quantity, specID, _, _, _, lessAwesome, isUpgraded, isCorrupted = ...
        if typeIdentifier ~= "item" then return end
        if not itemLink then return end

        local item = Item:CreateFromItemLink(itemLink)
        if not item or item:IsItemEmpty() then return end

        item:ContinueOnItemLoad(function()
            if ShouldShowToast(itemLink) then
                if LootAlertSystem and LootAlertSystem.AddAlert then
                    LootAlertSystem:AddAlert(itemLink, quantity, nil, nil, specID, nil, nil, nil, lessAwesome, isUpgraded, isCorrupted)
                end
            end
        end)
    end
end

---------------------------------------------------------------------------
-- ENABLE / DISABLE
---------------------------------------------------------------------------
local function Enable()
    if enabled then return end
    enabled = true
    myGUID = UnitGUID("player")

    -- Hook AlertFrame to intercept SHOW_LOOT_TOAST
    if not alertFrameHooked and AlertFrame then
        hooksecurefunc(AlertFrame, "RegisterEvent", function(selfFrame, event)
            if handleToasts and BLACKLISTED_EVENTS[event] then
                pcall(selfFrame.UnregisterEvent, selfFrame, event)
            end
        end)
        alertFrameHooked = true
    end

    handleToasts = true

    -- Take over SHOW_LOOT_TOAST from AlertFrame
    if AlertFrame:IsEventRegistered("SHOW_LOOT_TOAST") then
        AlertFrame:UnregisterEvent("SHOW_LOOT_TOAST")
    end

    toastFrame:RegisterEvent("SHOW_LOOT_TOAST")
    toastFrame:SetScript("OnEvent", OnEvent)
end

local function Disable()
    if not enabled then return end
    enabled = false
    handleToasts = false

    toastFrame:UnregisterEvent("SHOW_LOOT_TOAST")
    toastFrame:SetScript("OnEvent", nil)

    -- Restore AlertFrame toast handling
    if AlertFrame and not AlertFrame:IsEventRegistered("SHOW_LOOT_TOAST") then
        AlertFrame:RegisterEvent("SHOW_LOOT_TOAST")
    end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:InitLootToast()
    local qol = GetQoL()
    if not qol or not qol.lootToastFilterEnabled then
        Disable()
        return
    end
    Enable()
end
