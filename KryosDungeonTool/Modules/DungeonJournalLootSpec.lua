-- Kryos Dungeon Tool
-- Modules/DungeonJournalLootSpec.lua - Dungeon Journal Loot Spec Icons
-- Adapted from EnhanceQoL DungeonJournalLootSpec.lua - WoW 12.0 compatible
-- Shows which specs can use each loot item in the Encounter Journal

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local pairs = pairs
local ipairs = ipairs
local next = next
local wipe = wipe
local table_sort = table.sort
local CreateFrame = CreateFrame
local CreateTexturePool = CreateTexturePool
local hooksecurefunc = hooksecurefunc
local UnitClass = UnitClass

local GetNumClasses = GetNumClasses
local GetNumSpecializationsForClassID = GetNumSpecializationsForClassID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
local GetClassInfo = C_CreatureInfo and C_CreatureInfo.GetClassInfo

local EJ_SelectInstance = EJ_SelectInstance
local EJ_SetLootFilter = EJ_SetLootFilter
local EJ_GetNumLoot = EJ_GetNumLoot
local EJ_SelectEncounter = EJ_SelectEncounter
local EJ_GetDifficulty = EJ_GetDifficulty
local EJ_GetLootFilter = EJ_GetLootFilter
local GetLootInfoByIndex = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex

---------------------------------------------------------------------------
-- MODULE STATE
---------------------------------------------------------------------------
local Module = {
    frame = CreateFrame("Frame"),
    enabled = false,
    scanInProgress = false,
    pendingEncounterUpdate = false,
    updateScheduled = false,
    updateAll = false,
    isUpdatingLoot = false,
    needsRerun = false,
    scrollBox = nil,
    pool = nil,
    scrollCallbacks = nil,
    hookedLootUpdate = false,
    layout = nil,
}

local classes = {}
local roles = {}
local cache = { items = {} }
local numSpecs = 0
local fakeEveryoneSpec = { { specIcon = 922035 } }

local ROLES_ATLAS = {
    TANK = "UI-LFG-RoleIcon-Tank-Micro-GroupFinder",
    HEALER = "UI-LFG-RoleIcon-Healer-Micro-GroupFinder",
    DAMAGER = "UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
}

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT and KDT.DB and KDT.DB.qol
end

---------------------------------------------------------------------------
-- CLASS/SPEC DATA (from original)
---------------------------------------------------------------------------
local function BuildClassData()
    wipe(classes)
    wipe(roles)
    numSpecs = 0

    for i = 1, GetNumClasses() do
        local classInfo = GetClassInfo and GetClassInfo(i)
        if classInfo and classInfo.classID then
            classInfo.numSpecs = GetNumSpecializationsForClassID(classInfo.classID) or 0
            classInfo.specs = {}
            classes[classInfo.classID] = classInfo

            for j = 1, classInfo.numSpecs do
                local specID, specName, _, specIcon, specRole = GetSpecializationInfoForClassID(classInfo.classID, j)
                if specID and specRole then
                    classInfo.specs[specID] = {
                        id = specID,
                        name = specName,
                        icon = specIcon,
                        role = specRole,
                    }
                    numSpecs = numSpecs + 1
                    roles[specRole] = roles[specRole] or {}
                    roles[specRole][specID] = classInfo.classID
                end
            end
        end
    end

    for _, specToClass in pairs(roles) do
        local count = 0
        for specID in pairs(specToClass) do
            if specID ~= "numSpecs" then count = count + 1 end
        end
        specToClass.numSpecs = count
    end
end

---------------------------------------------------------------------------
-- COMPRESS SPECS/ROLES (from original - shows class icon if all specs can use)
---------------------------------------------------------------------------
local function CompressSpecs(specs)
    local compress
    for classID, classInfo in pairs(classes) do
        local remaining = classInfo.numSpecs or 0
        if remaining > 0 then
            for specID in pairs(classInfo.specs) do
                for _, info in ipairs(specs) do
                    if info.specID == specID then remaining = remaining - 1; break end
                end
                if remaining == 0 then break end
            end
            if remaining == 0 then
                compress = compress or {}
                compress[classID] = true
            end
        end
    end
    if not compress then return specs end

    local encountered = {}
    local compressed = {}
    local index = 0
    for _, info in ipairs(specs) do
        if compress[info.classID] then
            if not encountered[info.classID] then
                encountered[info.classID] = true
                index = index + 1
                info.specID = 0
                info.specName = info.className
                info.specIcon = true -- signals class icon
                info.specRole = ""
                compressed[index] = info
            end
        else
            index = index + 1
            compressed[index] = info
        end
    end
    return compressed
end

local function CompressRoles(specs)
    local compress
    for role, specToClass in pairs(roles) do
        local remaining = specToClass.numSpecs or 0
        for specID in pairs(specToClass) do
            if specID ~= "numSpecs" then
                for _, info in ipairs(specs) do
                    if info.specID == specID then remaining = remaining - 1; break end
                end
                if remaining == 0 then break end
            end
        end
        if remaining == 0 then
            compress = compress or {}
            compress[role] = true
        end
    end
    if not compress then return specs end

    local encountered = {}
    local compressed = {}
    local index = 0
    for _, info in ipairs(specs) do
        if compress[info.specRole] then
            if not encountered[info.specRole] then
                encountered[info.specRole] = true
                index = index + 1
                info.specID = 0
                info.specName = info.specRole
                info.specIcon = true
                info.specRole = true -- signals role icon
                compressed[index] = info
            end
        else
            index = index + 1
            compressed[index] = info
        end
    end
    return compressed
end

local function SortByClassAndSpec(a, b)
    if a.className == b.className then return a.specName < b.specName end
    return a.className < b.className
end

---------------------------------------------------------------------------
-- SPEC QUERY PER ITEM
---------------------------------------------------------------------------
local function GetSpecsForItem(button, showAll, playerClassID, specs)
    local itemID = button and button.itemID
    if not itemID then return end
    local itemCache = cache.items[itemID]
    if not itemCache then return end
    if itemCache.everyone then return true end

    specs = specs or {}
    wipe(specs)
    local index = 0

    for specID, classID in pairs(itemCache.specs) do
        if showAll or playerClassID == classID then
            local classInfo = classes[classID]
            local specInfo = classInfo and classInfo.specs and classInfo.specs[specID]
            if classInfo and specInfo then
                index = index + 1
                specs[index] = {
                    classID = classID,
                    className = classInfo.className,
                    classFile = classInfo.classFile,
                    specID = specID,
                    specName = specInfo.name,
                    specIcon = specInfo.icon,
                    specRole = specInfo.role,
                }
            end
        end
    end

    for i = index + 1, #specs do specs[i] = nil end
    if not specs[1] then return end

    if specs[2] then specs = CompressSpecs(specs) end
    if specs[2] then specs = CompressRoles(specs) end
    if specs[2] then table_sort(specs, SortByClassAndSpec) end

    return specs
end

---------------------------------------------------------------------------
-- SCAN ITEMS (from original - iterates all class/spec combos)
---------------------------------------------------------------------------
local function UpdateItems()
    if not EncounterJournal or not EncounterJournal.encounter then return end
    local difficulty = EJ_GetDifficulty and EJ_GetDifficulty()
    if cache.difficulty == difficulty and cache.instanceID == EncounterJournal.instanceID
        and cache.encounterID == EncounterJournal.encounterID then return end

    cache.difficulty = difficulty
    cache.instanceID = EncounterJournal.instanceID
    cache.encounterID = EncounterJournal.encounterID
    if EJ_GetLootFilter then
        cache.classID, cache.specID = EJ_GetLootFilter()
    end
    if not cache.instanceID then return end

    EJ_SelectInstance(cache.instanceID)
    wipe(cache.items)
    Module.scanInProgress = true

    local currentClassID, currentSpecID
    for classID, classData in pairs(classes) do
        for specID in pairs(classData.specs) do
            if currentClassID ~= classID or currentSpecID ~= specID then
                EJ_SetLootFilter(classID, specID)
                currentClassID, currentSpecID = classID, specID
            end
            for index = 1, EJ_GetNumLoot() or 0 do
                local itemInfo = GetLootInfoByIndex and GetLootInfoByIndex(index)
                if itemInfo and itemInfo.itemID then
                    local ic = cache.items[itemInfo.itemID]
                    if not ic then
                        ic = itemInfo
                        ic.specs = {}
                        cache.items[itemInfo.itemID] = ic
                    end
                    ic.specs[specID] = classID
                end
            end
        end
    end

    if cache.encounterID then EJ_SelectEncounter(cache.encounterID) end
    if cache.classID and cache.specID then EJ_SetLootFilter(cache.classID, cache.specID) end
    Module.scanInProgress = false

    for _, ic in pairs(cache.items) do
        local count = 0
        for _ in pairs(ic.specs) do count = count + 1 end
        ic.everyone = count == numSpecs
    end
end

---------------------------------------------------------------------------
-- UPDATE ITEM ICONS (from original)
---------------------------------------------------------------------------
local function UpdateItem(button, showAll, playerClassID)
    local specs = GetSpecsForItem(button, showAll, playerClassID, button.kdtSpecs)
    if specs == nil then
        if button.kdtIcons then
            for i = 1, #button.kdtIcons do button.kdtIcons[i]:Hide() end
        end
        return
    end

    if specs == true then
        specs = fakeEveryoneSpec
    else
        button.kdtSpecs = specs
    end

    local icons = button.kdtIcons
    if not icons then
        icons = {}
        button.kdtIcons = icons
    end

    local previousTexture
    for index, info in ipairs(specs) do
        local texture = icons[index]
        if not texture then
            texture = Module.pool:Acquire()
            icons[index] = texture
            texture:SetParent(button)
            texture:SetSize(16, 16)
        end

        texture:ClearAllPoints()
        if previousTexture then
            texture:SetPoint("TOPRIGHT", previousTexture, "TOPLEFT", 1, 0)
        else
            texture:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -6)
        end

        -- Set icon based on type
        if info.specRole == true then
            -- Role icon
            local atlas = ROLES_ATLAS[info.specName] or ""
            texture:SetAtlas(atlas)
        elseif info.specIcon == true then
            -- Class icon
            texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[info.classFile]
            if coords then
                texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            else
                texture:SetTexCoord(0, 1, 0, 1)
            end
        else
            -- Spec icon
            texture:SetTexture(info.specIcon or 134400)
            texture:SetTexCoord(0, 1, 0, 1)
        end

        texture:Show()
        previousTexture = texture
    end

    for index = #specs + 1, #icons do icons[index]:Hide() end
end

---------------------------------------------------------------------------
-- SCROLL BOX CALLBACKS
---------------------------------------------------------------------------
local function OnScrollBoxAcquired(_, button)
    if not Module.enabled or not button then return end
    button.kdtDirty = true
    Module:RequestLootUpdate(button, false)
end

local function OnScrollBoxReleased(_, button)
    if not button then return end
    if button.kdtIcons then
        for i = 1, #button.kdtIcons do
            button.kdtIcons[i]:Hide()
            if Module.pool then Module.pool:Release(button.kdtIcons[i]) end
        end
        wipe(button.kdtIcons)
        button.kdtIcons = nil
    end
    button.kdtSpecs = nil
    button.kdtDirty = nil
end

local function OnDataRangeChanged()
    Module:RequestLootUpdate(nil, true)
end

---------------------------------------------------------------------------
-- POOL & HOOKS
---------------------------------------------------------------------------
function Module:EnsurePool()
    if not EncounterJournal or not EncounterJournal.encounter or not EncounterJournal.encounter.info then return end
    local lootContainer = EncounterJournal.encounter.info.LootContainer
    if not lootContainer or not lootContainer.ScrollBox then return end

    local scrollBox = lootContainer.ScrollBox

    -- If scrollbox changed, clean up old one
    if self.scrollBox and self.scrollBox ~= scrollBox then
        self:UnregisterScrollCallbacks()
        if self.pool then self.pool:ReleaseAll(); self.pool = nil end
    end

    self.scrollBox = scrollBox

    if not self.pool then
        self.pool = CreateTexturePool(scrollBox, "OVERLAY", 7)
        self.updateAll = true
    end
    return true
end

function Module:RegisterScrollCallbacks()
    if not self.scrollBox then return end
    self.scrollCallbacks = self.scrollCallbacks or {}
    if not self.scrollCallbacks.acquired then
        self.scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnAcquiredFrame, OnScrollBoxAcquired)
        self.scrollCallbacks.acquired = true
    end
    if not self.scrollCallbacks.released then
        self.scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnReleasedFrame, OnScrollBoxReleased)
        self.scrollCallbacks.released = true
    end
    if not self.scrollCallbacks.dataRange then
        self.scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnDataRangeChanged, OnDataRangeChanged)
        self.scrollCallbacks.dataRange = true
    end
end

function Module:UnregisterScrollCallbacks()
    if not self.scrollBox or not self.scrollCallbacks then return end
    if self.scrollCallbacks.acquired then
        self.scrollBox:UnregisterCallback(ScrollBoxListMixin.Event.OnAcquiredFrame, OnScrollBoxAcquired)
    end
    if self.scrollCallbacks.released then
        self.scrollBox:UnregisterCallback(ScrollBoxListMixin.Event.OnReleasedFrame, OnScrollBoxReleased)
    end
    if self.scrollCallbacks.dataRange then
        self.scrollBox:UnregisterCallback(ScrollBoxListMixin.Event.OnDataRangeChanged, OnDataRangeChanged)
    end
    self.scrollCallbacks = nil
end

---------------------------------------------------------------------------
-- UPDATE LOOP
---------------------------------------------------------------------------
function Module:UpdateLoot(forceAll)
    if not self.enabled then
        if self.pool then self.pool:ReleaseAll() end
        return
    end
    if forceAll then self.updateAll = true end
    if self.isUpdatingLoot then
        if forceAll then self.needsRerun = true end
        return
    end

    if not self.pool or not self.scrollBox then
        if not self:EnsurePool() then return end
    end
    if not self.pool or not self.scrollBox then return end
    if not self.scrollCallbacks then self:RegisterScrollCallbacks() end

    local buttons = self.scrollBox:GetFrames()
    if not buttons then return end

    self.isUpdatingLoot = true
    local updateAll = self.updateAll
    self.updateAll = false

    local _, _, playerClassID = UnitClass("player")
    local qol = GetQoL()
    local showAll = qol and qol.djLootSpecShowAll or false

    local hasUpdatedItems
    for _, button in ipairs(buttons) do
        if button:IsVisible() and (updateAll or button.kdtDirty) then
            if not hasUpdatedItems then
                hasUpdatedItems = true
                UpdateItems()
            end
            UpdateItem(button, showAll, playerClassID)
            button.kdtDirty = nil
        elseif updateAll and button.kdtIcons then
            for i = 1, #button.kdtIcons do button.kdtIcons[i]:Hide() end
        end
    end

    self.isUpdatingLoot = false
    if self.needsRerun then
        self.needsRerun = false
        self:UpdateLoot()
    end
end

function Module:RequestLootUpdate(button, forceAll)
    if button then button.kdtDirty = true end
    if forceAll then
        self.updateAll = true
        if self.scrollBox then
            local buttons = self.scrollBox:GetFrames()
            if buttons then
                for _, b in ipairs(buttons) do b.kdtDirty = true end
            end
        end
    end
    if not self.enabled then return end
    if self.isUpdatingLoot then self.needsRerun = true; return end
    if self.updateScheduled then return end
    self.updateScheduled = true
    C_Timer.After(0, function()
        Module.updateScheduled = false
        Module:UpdateLoot()
    end)
end

---------------------------------------------------------------------------
-- EVENTS
---------------------------------------------------------------------------
function Module:OnEvent(event, arg1)
    if not self.enabled then return end
    if event == "ADDON_LOADED" and arg1 == "Blizzard_EncounterJournal" then
        self:TryLoad()
    elseif event == "PLAYER_LOGIN" then
        BuildClassData()
        wipe(cache.items)
        self.updateAll = true
        self:RequestLootUpdate(nil, true)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if arg1 == nil or arg1 == "player" then
            self.updateAll = true
            self:RequestLootUpdate(nil, true)
        end
    end
end

function Module:TryLoad()
    if not self.enabled then return end
    if not EncounterJournal or not EncounterJournal.encounter then return end
    self:EnsurePool()
    if not self.pool or not self.scrollBox then return end

    if not self.hookedLootUpdate and EncounterJournal_LootUpdate then
        hooksecurefunc("EncounterJournal_LootUpdate", function()
            if Module.enabled then Module:RequestLootUpdate(nil, true) end
        end)
        self.hookedLootUpdate = true
    end
    self:RegisterScrollCallbacks()
    self:UpdateLoot(true)
end

Module.frame:SetScript("OnEvent", function(_, event, arg1) Module:OnEvent(event, arg1) end)

---------------------------------------------------------------------------
-- ENABLE / DISABLE
---------------------------------------------------------------------------
function Module:SetEnabled(value)
    value = not not value
    if value == self.enabled then
        if value then self:RequestLootUpdate(nil, true) end
        return
    end
    self.enabled = value

    if value then
        self.updateScheduled = false
        self.needsRerun = false
        self.updateAll = true
        BuildClassData()
        wipe(cache.items)
        cache.difficulty = nil
        cache.instanceID = nil
        cache.encounterID = nil
        self.frame:RegisterEvent("ADDON_LOADED")
        self.frame:RegisterEvent("PLAYER_LOGIN")
        self.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        self:TryLoad()
    else
        self.updateScheduled = false
        self.frame:UnregisterEvent("ADDON_LOADED")
        self.frame:UnregisterEvent("PLAYER_LOGIN")
        self.frame:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        if self.scrollBox then
            local buttons = self.scrollBox:GetFrames()
            if buttons then
                for _, button in ipairs(buttons) do
                    OnScrollBoxReleased(nil, button)
                end
            end
            self:UnregisterScrollCallbacks()
        end
        if self.pool then self.pool:ReleaseAll(); self.pool = nil end
        self.scrollBox = nil
        self.layout = nil
    end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:InitDungeonJournalLootSpec()
    local qol = GetQoL()
    if not qol or not qol.djLootSpecEnabled then
        Module:SetEnabled(false)
        return
    end
    Module:SetEnabled(true)
end
