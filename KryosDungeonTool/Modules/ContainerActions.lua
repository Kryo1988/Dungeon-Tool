-- Kryos Dungeon Tool
-- Modules/ContainerActions.lua - Auto-Open Container Button
-- Adapted from EnhanceQoL ContainerActions.lua - WoW 12.0 compatible
-- Scans bags for openable items (containers, cosmetics, uncollected mounts)
-- and provides a secure button to use them

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- UPVALUES (WoW 12.0)
---------------------------------------------------------------------------
local CreateFrame = CreateFrame
local UIParent = UIParent
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local C_Container = C_Container
local C_Item = C_Item
local C_TooltipInfo = C_TooltipInfo
local C_ChallengeMode = C_ChallengeMode
local C_MountJournal = C_MountJournal
local C_Timer = C_Timer
local NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink
local GetBagItemTooltip = C_TooltipInfo and C_TooltipInfo.GetBagItem

local BUTTON_SIZE = 44
local PREVIEW_ICON = "Interface\\Icons\\INV_Misc_Bag_10"

-- Item classes for tooltip scanning filter
local ITEM_CLASS = Enum and Enum.ItemClass
local MISC_SUBCLASS = Enum and Enum.ItemMiscellaneousSubclass
local TOOLTIP_CLASS_FILTER = {}
if ITEM_CLASS then
    if ITEM_CLASS.Consumable then TOOLTIP_CLASS_FILTER[ITEM_CLASS.Consumable] = true end
    if ITEM_CLASS.Container then TOOLTIP_CLASS_FILTER[ITEM_CLASS.Container] = true end
    if ITEM_CLASS.Miscellaneous then TOOLTIP_CLASS_FILTER[ITEM_CLASS.Miscellaneous] = true end
end

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local ContainerActions = {
    initialized = false,
    button = nil,
    secureItems = {},
    openableCache = {},
    mountCache = {},
    visibilityBlocks = {},
    pendingItem = nil,
    pendingVisibility = nil,
    desiredVisibility = nil,
    challengeModeActive = false,
}

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT and KDT.DB and KDT.DB.qol
end

local function IsEnabled()
    local qol = GetQoL()
    return qol and qol.containerActionsEnabled == true
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

---------------------------------------------------------------------------
-- BUTTON HELPERS (from original)
---------------------------------------------------------------------------
local function GetButtonIcon(button)
    if not button then return nil end
    return button.Icon or button.icon or button:GetNormalTexture()
end

local function SetButtonIconTexture(button, texture)
    local icon = GetButtonIcon(button)
    if icon and icon.SetTexture then
        icon:SetTexture(texture)
    elseif button and button.SetNormalTexture then
        button:SetNormalTexture(texture or "")
    end
end

local function SetButtonIconTexCoord(button, ...)
    local icon = GetButtonIcon(button)
    if icon and icon.SetTexCoord then icon:SetTexCoord(...) end
end

---------------------------------------------------------------------------
-- SECURE BUTTON CREATION (from original)
---------------------------------------------------------------------------
local function EnsureButton()
    if ContainerActions.button then return ContainerActions.button end

    local button = CreateFrame("Button", "KDT_ContainerActionButton", UIParent, "ActionButtonTemplate,SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    button:SetAttribute("pressAndHoldAction", false)
    button:SetAttribute("*type*", nil)
    SetButtonIconTexCoord(button, 0.08, 0.92, 0.08, 0.92)
    if button.HotKey then button.HotKey:SetText("") end
    if button.Name then button.Name:Hide() end
    button:SetClampedToScreen(true)
    button:SetMovable(true)
    button:Hide()

    -- Position from saved vars
    local qol = GetQoL()
    local pos = qol and qol.containerActionsPosition
    if type(pos) == "table" and pos.point then
        button:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or -200)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end

    -- Tooltip
    button:SetScript("OnEnter", function(btn)
        if not IsEnabled() or not btn:IsMouseEnabled() then return end
        if btn.entry then
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(btn.entry.bag, btn.entry.slot)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF90EE90Left-click to use|r")
            GameTooltip:AddLine("|cFFFF9090Shift+Right-click to blacklist|r")
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    -- Post-click: rescan after use
    button:SetScript("PostClick", function()
        if not IsEnabled() then return end
        C_Timer.After(0.5, function()
            ContainerActions:ScanAndUpdate()
        end)
    end)

    -- Right-click blacklist
    button:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "RightButton" and IsShiftKeyDown() then
            ContainerActions:BlacklistCurrentItem()
        end
    end)

    -- Combat visibility driver: hide in combat, show out
    if RegisterStateDriver then
        pcall(RegisterStateDriver, button, "visibility", "[combat] hide; show")
    end

    ContainerActions.button = button
    return button
end

---------------------------------------------------------------------------
-- VISIBILITY MANAGEMENT (from original)
---------------------------------------------------------------------------
function ContainerActions:HasVisibilityBlock()
    return self.visibilityBlocks and next(self.visibilityBlocks) ~= nil
end

function ContainerActions:SetVisibilityBlock(reason, blocked)
    if not reason then return end
    self.visibilityBlocks = self.visibilityBlocks or {}
    if blocked then
        self.visibilityBlocks[reason] = true
    else
        self.visibilityBlocks[reason] = nil
    end
    -- Re-evaluate visibility
    local shouldShow = self.desiredVisibility
    if self:HasVisibilityBlock() then shouldShow = false end
    self:ApplyVisibility(shouldShow)
end

function ContainerActions:ApplyVisibility(show)
    local button = self.button
    if not button then return end
    if InCombat() then
        self.pendingVisibility = show
        return
    end
    if show then
        if not button:IsShown() then button:Show() end
        button:EnableMouse(true)
    else
        if button:IsShown() then button:Hide() end
        button:EnableMouse(false)
    end
end

function ContainerActions:RequestVisibility(show)
    self.desiredVisibility = show
    if self:HasVisibilityBlock() then show = false end
    self:ApplyVisibility(show)
end

---------------------------------------------------------------------------
-- BLACKLIST
---------------------------------------------------------------------------
function ContainerActions:GetBlacklist()
    local qol = GetQoL()
    if not qol then return {} end
    qol.containerActionsBlacklist = qol.containerActionsBlacklist or {}
    return qol.containerActionsBlacklist
end

function ContainerActions:IsBlacklisted(itemID)
    local bl = self:GetBlacklist()
    return bl[itemID] == true
end

function ContainerActions:BlacklistCurrentItem()
    local button = self.button
    if not button or not button.entry then return end
    local itemID = button.entry.itemID
    if not itemID then return end
    local bl = self:GetBlacklist()
    bl[itemID] = true
    local name = C_Item.GetItemNameByID(itemID) or ("item:" .. itemID)
    if KDT.Print then KDT:Print("|cFFFF9090Blacklisted:|r " .. name) end
    self:ScanAndUpdate()
end

---------------------------------------------------------------------------
-- TOOLTIP SCANNING (from original - checks for ITEM_OPENABLE)
---------------------------------------------------------------------------
function ContainerActions:ShouldInspectTooltip(itemID)
    if not itemID then return false end
    if not ITEM_CLASS then return true end
    local _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    if not classID then return true end
    return TOOLTIP_CLASS_FILTER[classID] ~= nil
end

function ContainerActions:IsTooltipOpenable(bag, slot, info)
    info = info or (GetContainerItemInfo and GetContainerItemInfo(bag, slot))
    if not info or not info.itemID then return false end

    local itemID = info.itemID
    if self.openableCache[itemID] ~= nil then return self.openableCache[itemID] end
    if not self:ShouldInspectTooltip(itemID) then
        self.openableCache[itemID] = false
        return false
    end

    local tooltip = GetBagItemTooltip and GetBagItemTooltip(bag, slot)
    if not tooltip or not tooltip.lines then
        self.openableCache[itemID] = false
        return false
    end

    -- Surface args for WoW 12.0
    if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(tooltip) end

    for _, line in ipairs(tooltip.lines) do
        if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
        local text = line.leftText
        if text then
            -- ITEM_OPENABLE = "Right Click to Open" / ITEM_COSMETIC_LEARN
            if text == ITEM_OPENABLE or text == (ITEM_COSMETIC_LEARN or "") then
                self.openableCache[itemID] = true
                return true
            end
        end
    end
    self.openableCache[itemID] = false
    return false
end

---------------------------------------------------------------------------
-- MOUNT CHECK (from original)
---------------------------------------------------------------------------
function ContainerActions:IsCollectibleMount(info)
    if not info or not info.itemID then return false end
    if not C_MountJournal or not C_MountJournal.GetMountFromItem then return false end

    local itemID = info.itemID
    if self.mountCache[itemID] ~= nil then
        return self.mountCache[itemID] ~= false, self.mountCache[itemID]
    end

    -- Quick check: is it a Miscellaneous/Mount item?
    local _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    local miscClass = ITEM_CLASS and ITEM_CLASS.Miscellaneous
    local mountSub = MISC_SUBCLASS and MISC_SUBCLASS.Mount
    if classID and subclassID and miscClass and mountSub then
        if classID ~= miscClass or subclassID ~= mountSub then
            self.mountCache[itemID] = false
            return false
        end
    end

    local mountID = C_MountJournal.GetMountFromItem(itemID)
    if not mountID then
        self.mountCache[itemID] = false
        return false
    end
    self.mountCache[itemID] = mountID

    -- Check if already collected
    local hasMount = false
    if C_MountJournal.PlayerHasMount then
        hasMount = C_MountJournal.PlayerHasMount(mountID) == true
    elseif C_MountJournal.GetMountInfoByID then
        local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        hasMount = isCollected == true
    end

    if hasMount then return false end
    return true, mountID
end

---------------------------------------------------------------------------
-- BAG SCANNING (from original)
---------------------------------------------------------------------------
function ContainerActions:ScanBags()
    local items = {}
    if not IsEnabled() then return items end

    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local slotCount = GetContainerNumSlots and GetContainerNumSlots(bag)
        if slotCount and slotCount > 0 then
            for slot = 1, slotCount do
                local info = GetContainerItemInfo and GetContainerItemInfo(bag, slot)
                if info and info.itemID and not info.isLocked then
                    if not self:IsBlacklisted(info.itemID) then
                        local shouldAdd = false

                        -- Check for uncollected mount
                        local isMount = self:IsCollectibleMount(info)
                        if isMount then
                            shouldAdd = true
                        end

                        -- Check for openable items via tooltip
                        if not shouldAdd and self:IsTooltipOpenable(bag, slot, info) then
                            shouldAdd = true
                        end

                        -- Check for Reagent type containers (classID 20, subclassID 0 = Tokens etc)
                        if not shouldAdd then
                            local _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(info.itemID)
                            if classID == 20 and subclassID == 0 then
                                shouldAdd = true
                            end
                        end

                        if shouldAdd then
                            items[#items + 1] = {
                                bag = bag,
                                slot = slot,
                                itemID = info.itemID,
                                icon = info.iconFileID,
                                count = info.stackCount or 1,
                            }
                        end
                    end
                end
            end
        end
    end

    -- Sort by bag, slot
    table.sort(items, function(a, b)
        if a.bag == b.bag then return a.slot < b.slot end
        return a.bag < b.bag
    end)

    return items
end

---------------------------------------------------------------------------
-- APPLY ITEM TO BUTTON (from original)
---------------------------------------------------------------------------
function ContainerActions:ApplyButtonEntry(entry)
    local button = EnsureButton()
    if InCombat() then
        self.pendingItem = entry or false
        return
    end

    if entry then
        button.entry = entry
        SetButtonIconTexture(button, entry.icon or PREVIEW_ICON)

        local macroText = ("/use %d %d"):format(entry.bag, entry.slot)
        button:SetAttribute("*type*", "macro")
        button:SetAttribute("macrotext", macroText)

        -- Count text
        if button.Count then
            local total = 0
            for _, item in ipairs(self.secureItems) do
                total = total + (item.count or 1)
            end
            if total > 1 then
                button.Count:SetText(total)
            else
                button.Count:SetText("")
            end
        end
    else
        button.entry = nil
        SetButtonIconTexture(button, nil)
        button:SetAttribute("macrotext", nil)
        button:SetAttribute("*type*", nil)
        if button.Count then button.Count:SetText("") end
    end
end

---------------------------------------------------------------------------
-- SCAN & UPDATE
---------------------------------------------------------------------------
function ContainerActions:ScanAndUpdate()
    if not IsEnabled() then
        self.secureItems = {}
        self:ApplyButtonEntry(nil)
        self:RequestVisibility(false)
        return
    end

    self.secureItems = self:ScanBags()

    if #self.secureItems == 0 then
        self:ApplyButtonEntry(nil)
        self:RequestVisibility(false)
    else
        self:ApplyButtonEntry(self.secureItems[1])
        self:RequestVisibility(true)
    end
end

---------------------------------------------------------------------------
-- CHALLENGE MODE BLOCKS (from original)
---------------------------------------------------------------------------
function ContainerActions:UpdateChallengeModeState()
    local active = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() == true
    self.challengeModeActive = active
    self:SetVisibilityBlock("challengeMode", active)
end

function ContainerActions:UpdateVehicleState()
    local inVehicle = false
    if UnitHasVehicleUI then
        inVehicle = UnitHasVehicleUI("player") == true
    elseif UnitInVehicle then
        inVehicle = UnitInVehicle("player") == true
    end
    self:SetVisibilityBlock("vehicle", inVehicle)
end

---------------------------------------------------------------------------
-- COMBAT DEFERRED ACTIONS (from original)
---------------------------------------------------------------------------
function ContainerActions:OnCombatEnd()
    if self.pendingItem ~= nil then
        local entry = self.pendingItem
        self.pendingItem = nil
        self:ApplyButtonEntry(entry or nil)
    end
    if self.pendingVisibility ~= nil then
        local vis = self.pendingVisibility
        self.pendingVisibility = nil
        self:ApplyVisibility(vis)
    end
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
function ContainerActions:Init()
    if self.initialized then return end
    self.initialized = true

    EnsureButton()

    -- Event frame for combat, zone, bags
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    frame:RegisterEvent("UNIT_EXITED_VEHICLE")
    frame:RegisterEvent("CHALLENGE_MODE_START")
    frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("BAG_UPDATE")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            -- nothing to do on enter
        elseif event == "PLAYER_REGEN_ENABLED" then
            ContainerActions:OnCombatEnd()
        elseif event == "UNIT_ENTERED_VEHICLE" then
            local unit = ...
            if unit == "player" then ContainerActions:SetVisibilityBlock("vehicle", true) end
        elseif event == "UNIT_EXITED_VEHICLE" then
            local unit = ...
            if unit == "player" then ContainerActions:SetVisibilityBlock("vehicle", false) end
        elseif event == "CHALLENGE_MODE_START" then
            ContainerActions:UpdateChallengeModeState()
        elseif event == "CHALLENGE_MODE_COMPLETED" then
            ContainerActions:UpdateChallengeModeState()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            ContainerActions:UpdateVehicleState()
            ContainerActions:UpdateChallengeModeState()
        elseif event == "BAG_UPDATE" then
            -- Throttled rescan on bag changes
            if not ContainerActions._bagUpdatePending then
                ContainerActions._bagUpdatePending = true
                C_Timer.After(0.3, function()
                    ContainerActions._bagUpdatePending = nil
                    ContainerActions:ScanAndUpdate()
                end)
            end
        end
    end)
    self.eventFrame = frame

    self:UpdateVehicleState()
    self:UpdateChallengeModeState()
end

---------------------------------------------------------------------------
-- UNLOCK/LOCK FOR POSITIONING
---------------------------------------------------------------------------
local isUnlocked = false

function ContainerActions:UnlockButton()
    local button = self.button
    if not button then EnsureButton(); button = self.button end
    isUnlocked = true
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self) self:StartMoving() end)
    button:SetScript("OnDragStop", function(btn)
        btn:StopMovingOrSizing()
        local point, _, relativePoint, x, y = btn:GetPoint()
        local qol = GetQoL()
        if qol then
            qol.containerActionsPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
        end
    end)
    -- Show with preview icon
    SetButtonIconTexture(button, PREVIEW_ICON)
    button:Show()
    if KDT.Print then KDT:Print("Container Button |cFF44FF44unlocked|r. Drag to reposition.") end
end

function ContainerActions:LockButton()
    local button = self.button
    if not button then return end
    isUnlocked = false
    button:SetScript("OnDragStart", nil)
    button:SetScript("OnDragStop", nil)
    -- Restore normal state
    self:ScanAndUpdate()
    if KDT.Print then KDT:Print("Container Button |cFFFF4444locked|r.") end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:InitContainerActions()
    if not IsEnabled() then
        if ContainerActions.button then
            ContainerActions:ApplyButtonEntry(nil)
            ContainerActions:RequestVisibility(false)
        end
        return
    end
    ContainerActions:Init()
    ContainerActions:ScanAndUpdate()
end

function KDT:ToggleContainerActionsLock()
    if isUnlocked then
        ContainerActions:LockButton()
    else
        ContainerActions:UnlockButton()
    end
end

function KDT:ContainerActionsRescan()
    ContainerActions:ScanAndUpdate()
end
