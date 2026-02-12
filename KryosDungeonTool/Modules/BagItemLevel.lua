-- Kryos Dungeon Tool
-- Modules/BagItemLevel.lua - Item level display on bag items

local _, KDT = ...

local BagIlvl = { hooked = false }
KDT.BagItemLevel = BagIlvl

local FONT = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 14

-- Equipment slot mapping for upgrade comparison
local EQUIP_SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_RANGED = { 16 }, INVTYPE_RANGEDRIGHT = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_SHIELD = { 17 },
    INVTYPE_WEAPON = { 16, 17 },
}

local function ensureIlvlText(button)
    if button.KDT_IlvlText then return button.KDT_IlvlText end
    local fs = button:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, FONT_SIZE, "OUTLINE")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.KDT_IlvlText = fs
    return fs
end

local function ensureUpgradeIcon(button)
    if button.KDT_UpgradeIcon then return button.KDT_UpgradeIcon end
    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Up-Highlight")
    icon:SetSize(16, 16)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.KDT_UpgradeIcon = icon
    return icon
end

local function getEquippedIlvlForSlots(slots)
    if not slots then return nil end
    local worst
    for _, s in ipairs(slots) do
        local link = GetInventoryItemLink("player", s)
        local ilvl = link and C_Item.GetDetailedItemLevelInfo(link) or 0
        if not worst or ilvl < worst then worst = ilvl end
    end
    return worst
end

local function updateBagButton(button, bag, slot)
    local qol = KDT.DB and KDT.DB.qol
    if not qol or not qol.showBagItemLevel then
        if button.KDT_IlvlText then button.KDT_IlvlText:Hide() end
        if button.KDT_UpgradeIcon then button.KDT_UpgradeIcon:Hide() end
        return
    end
    
    local itemLink = C_Container.GetContainerItemLink(bag, slot)
    if not itemLink then
        if button.KDT_IlvlText then button.KDT_IlvlText:Hide() end
        if button.KDT_UpgradeIcon then button.KDT_UpgradeIcon:Hide() end
        return
    end
    
    local eItem = Item:CreateFromItemLink(itemLink)
    if not eItem or eItem:IsItemEmpty() then
        if button.KDT_IlvlText then button.KDT_IlvlText:Hide() end
        if button.KDT_UpgradeIcon then button.KDT_UpgradeIcon:Hide() end
        return
    end
    
    eItem:ContinueOnItemLoad(function()
        local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
        local ilvl = loc and C_Item.GetCurrentItemLevel(loc)
        if not ilvl then ilvl = eItem:GetCurrentItemLevel() end
        
        if not ilvl or ilvl <= 0 then
            if button.KDT_IlvlText then button.KDT_IlvlText:Hide() end
            if button.KDT_UpgradeIcon then button.KDT_UpgradeIcon:Hide() end
            return
        end
        
        -- Check if it's equippable
        local _, _, _, equipLoc = GetItemInfoInstant(itemLink)
        if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP_IGNORE" or equipLoc == "INVTYPE_BAG" or equipLoc == "INVTYPE_TABARD" or equipLoc == "INVTYPE_BODY" then
            if button.KDT_IlvlText then button.KDT_IlvlText:Hide() end
            if button.KDT_UpgradeIcon then button.KDT_UpgradeIcon:Hide() end
            return
        end
        
        -- Show item level text
        local fs = ensureIlvlText(button)
        fs:SetText(ilvl)
        local quality = eItem:GetItemQualityColor()
        if quality then
            fs:SetTextColor(quality.r, quality.g, quality.b, 1)
        else
            fs:SetTextColor(1, 1, 1)
        end
        fs:Show()
        
        -- Upgrade indicator
        if qol.showBagUpgradeArrow then
            local slots = EQUIP_SLOTS[equipLoc]
            local baseline = getEquippedIlvlForSlots(slots)
            if baseline and ilvl > baseline then
                local icon = ensureUpgradeIcon(button)
                icon:Show()
            elseif button.KDT_UpgradeIcon then
                button.KDT_UpgradeIcon:Hide()
            end
        elseif button.KDT_UpgradeIcon then
            button.KDT_UpgradeIcon:Hide()
        end
    end)
end

-- Hook into bag frame updates
function BagIlvl:Hook()
    if self.hooked then return end
    self.hooked = true
    
    -- WoW 12.0 uses ContainerFrameUtil_EnumerateContainerFrames or direct frame hooks
    -- Hook ContainerFrame_Update for classic/retail compatibility
    if ContainerFrame_Update then
        hooksecurefunc("ContainerFrame_Update", function(frame)
            if not frame or not frame.GetID then return end
            local qol = KDT.DB and KDT.DB.qol
            if not qol or not qol.showBagItemLevel then return end
            
            -- Delay until next frame so button layout is complete
            -- (avoids ilvl text appearing on wrong slot)
            C_Timer.After(0, function()
                if not frame or not frame.Items then return end
                for _, button in ipairs(frame.Items) do
                    if button:IsShown() and button.GetSlotAndBagID then
                        local slot, bag = button:GetSlotAndBagID()
                        if slot and bag then
                            updateBagButton(button, bag, slot)
                        end
                    end
                end
            end)
        end)
    end
    
    -- Also hook BAG_UPDATE_DELAYED for refresh
    local bagFrame = CreateFrame("Frame")
    bagFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    bagFrame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    bagFrame:SetScript("OnEvent", function()
        local qol = KDT.DB and KDT.DB.qol
        if not qol or not qol.showBagItemLevel then return end
        -- Refresh all visible bag buttons
        C_Timer.After(0.1, function() BagIlvl:RefreshAll() end)
    end)
end

function BagIlvl:RefreshAll()
    local qol = KDT.DB and KDT.DB.qol
    if not qol or not qol.showBagItemLevel then return end
    
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            -- Try to find the button widget for this bag/slot
            -- WoW 12.0 ContainerFrame approach
            local containerFrame = _G["ContainerFrame" .. (bag + 1)]
            if containerFrame and containerFrame.Items then
                for _, button in ipairs(containerFrame.Items) do
                    if button:IsShown() and button.GetSlotAndBagID then
                        local bSlot, bBag = button:GetSlotAndBagID()
                        if bSlot == slot and bBag == bag then
                            updateBagButton(button, bag, slot)
                        end
                    end
                end
            end
        end
    end
end

function KDT:InitBagItemLevel()
    local qol = self.DB and self.DB.qol
    if not qol then return end
    self.BagItemLevel:Hook()
    if qol.showBagItemLevel then
        C_Timer.After(1, function() self.BagItemLevel:RefreshAll() end)
    end
end
