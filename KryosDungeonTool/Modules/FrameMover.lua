-- Kryos Dungeon Tool
-- Modules/FrameMover.lua - Frame Mover System
-- Adapted from EnhanceQoL Mover module - WoW 12.0 compatible
-- Allows repositioning and scaling of Blizzard UI frames

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local CreateFrame = CreateFrame
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local GetMouseFoci = GetMouseFoci
local pairs = pairs
local ipairs = ipairs
local type = type
local pcall = pcall
local C_Timer = C_Timer
local C_AddOns = C_AddOns
local issecretvalue = issecretvalue

local IsAddonLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

---------------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------------
local SCALE_MIN = 0.5
local SCALE_MAX = 2.0
local SCALE_STEP = 0.05

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT.DB and KDT.DB.qol
end

local function GetFrameDB()
    return KDT.DB and KDT.DB.frameMoverPositions
end

---------------------------------------------------------------------------
-- FRAME DEFINITIONS (from original EnhanceQoL frames.lua)
---------------------------------------------------------------------------
local frameDefinitions = {
    -- System
    { id = "SettingsPanel", label = "Settings", group = "system", names = { "SettingsPanel" }, addon = "Blizzard_Settings", defaultEnabled = true },
    { id = "GameMenuFrame", label = "Game Menu", group = "system", names = { "GameMenuFrame" }, addon = "Blizzard_GameMenu", handlesRelative = { "Header" }, skipOnHide = true, defaultEnabled = true },
    { id = "MacroFrame", label = "Macros", group = "system", names = { "MacroFrame" }, addon = "Blizzard_MacroUI", defaultEnabled = true },
    { id = "AddonList", label = "Addon List", group = "system", names = { "AddonList" }, defaultEnabled = true },
    { id = "ChatConfigFrame", label = "Chat Settings", group = "system", names = { "ChatConfigFrame" }, defaultEnabled = true },
    { id = "HelpFrame", label = "Support", group = "system", names = { "HelpFrame" }, addon = "Blizzard_HelpFrame", defaultEnabled = true },
    { id = "CatalogShopFrame", label = "Blizzard Shop", group = "system", names = { "CatalogShopFrame" }, defaultEnabled = true },
    { id = "TransmogFrame", label = "Transmog", group = "system", names = { "TransmogFrame" }, addon = "Blizzard_Transmog", defaultEnabled = true },
    { id = "StaticPopup", label = "Static Popups", group = "system", names = { "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4" }, defaultEnabled = true },
    { id = "EventToastManagerFrame", label = "Event Toasts", group = "system", names = { "EventToastManagerFrame" }, defaultEnabled = true },
    { id = "CalendarFrame", label = "Calendar", group = "system", names = { "CalendarFrame" }, addon = "Blizzard_Calendar", defaultEnabled = true },
    { id = "TimeManagerFrame", label = "Time Manager", group = "system", names = { "TimeManagerFrame" }, addon = "Blizzard_TimeManager", defaultEnabled = true },
    -- Character
    { id = "CharacterFrame", label = "Character", group = "character", names = { "CharacterFrame" }, defaultEnabled = true },
    { id = "AchievementFrame", label = "Achievements", group = "character", names = { "AchievementFrame" }, addon = "Blizzard_AchievementUI", handlesRelative = { "Header" }, defaultEnabled = true },
    { id = "InspectFrame", label = "Inspect", group = "character", names = { "InspectFrame" }, addon = "Blizzard_InspectUI", defaultEnabled = true },
    { id = "PlayerSpellsFrame", label = "Talents & Spells", group = "character", names = { "PlayerSpellsFrame" }, addon = "Blizzard_PlayerSpells", handlesRelative = { "TalentsFrame", "SpecFrame" }, defaultEnabled = true },
    { id = "HeroTalentsSelectionDialog", label = "Hero Talents", group = "character", names = { "HeroTalentsSelectionDialog" }, addon = "Blizzard_PlayerSpells", defaultEnabled = true },
    { id = "CollectionsJournal", label = "Collections", group = "character", names = { "CollectionsJournal" }, addon = "Blizzard_Collections", defaultEnabled = true },
    { id = "DressUpFrame", label = "Dressing Room", group = "character", names = { "DressUpFrame" }, defaultEnabled = true },
    { id = "ItemInteractionFrame", label = "Catalyst", group = "character", names = { "ItemInteractionFrame" }, addon = "Blizzard_ItemInteractionUI", defaultEnabled = true },
    { id = "PlayerChoiceFrame", label = "Player Choice", group = "character", names = { "PlayerChoiceFrame" }, addon = "Blizzard_PlayerChoice", defaultEnabled = true },
    { id = "CooldownViewerSettings", label = "Cooldown Viewer", group = "character", names = { "CooldownViewerSettings" }, addon = "Blizzard_CooldownViewer", defaultEnabled = true },
    -- Activities
    { id = "PVEFrame", label = "Group Finder", group = "activities", names = { "PVEFrame" }, defaultEnabled = true },
    { id = "EncounterJournal", label = "Encounter Journal", group = "activities", names = { "EncounterJournal" }, addon = "Blizzard_EncounterJournal", defaultEnabled = true },
    { id = "LFGDungeonReadyDialog", label = "Dungeon Ready", group = "activities", names = { "LFGDungeonReadyDialog" }, defaultEnabled = true },
    { id = "LFGListInviteDialog", label = "LFG Invite", group = "activities", names = { "LFGListInviteDialog" }, defaultEnabled = true },
    { id = "ReadyCheckFrame", label = "Ready Check", group = "activities", names = { "ReadyCheckFrame" }, defaultEnabled = true },
    { id = "WeeklyRewardsFrame", label = "Great Vault", group = "activities", names = { "WeeklyRewardsFrame" }, addon = "Blizzard_WeeklyRewards", defaultEnabled = true },
    { id = "ChallengesKeystoneFrame", label = "Font of Power", group = "activities", names = { "ChallengesKeystoneFrame" }, addon = "Blizzard_ChallengesUI", defaultEnabled = true },
    { id = "CommunitiesFrame", label = "Communities", group = "activities", names = { "CommunitiesFrame" }, addon = "Blizzard_Communities", defaultEnabled = true },
    { id = "FriendsFrame", label = "Friends", group = "activities", names = { "FriendsFrame" }, defaultEnabled = true },
    { id = "ExpansionLandingPage", label = "Expansion Landing Page", group = "activities", names = { "ExpansionLandingPage" }, addon = "Blizzard_MajorFactions", defaultEnabled = true },
    { id = "MajorFactionRenownFrame", label = "Renown", group = "activities", names = { "MajorFactionRenownFrame" }, addon = "Blizzard_MajorFactions", handlesRelative = { "HeaderFrame" }, defaultEnabled = true },
    { id = "DelvesCompanionConfigurationFrame", label = "Delves Companion", group = "activities", names = { "DelvesCompanionConfigurationFrame" }, addon = "Blizzard_DelvesDashboardUI", defaultEnabled = true },
    -- Housing
    { id = "HousingControlsFrame", label = "Housing Controls", group = "housing", names = { "HousingControlsFrame" }, addon = "Blizzard_HousingControls", defaultEnabled = true },
    { id = "HousingDashboardFrame", label = "Housing Dashboard", group = "housing", names = { "HousingDashboardFrame" }, addon = "Blizzard_HousingDashboard", defaultEnabled = true },
    { id = "HouseFinderFrame", label = "House Finder", group = "housing", names = { "HouseFinderFrame" }, addon = "Blizzard_HousingHouseFinder", defaultEnabled = true },
    { id = "HouseListFrame", label = "House List", group = "housing", names = { "HouseListFrame" }, addon = "Blizzard_HouseList", defaultEnabled = true },
    -- World
    { id = "WorldMapFrame", label = "World Map", group = "world", names = { "WorldMapFrame" }, defaultEnabled = true },
    { id = "FlightMapFrame", label = "Flight Map", group = "world", names = { "FlightMapFrame" }, addon = "Blizzard_FlightMap", defaultEnabled = true },
    { id = "QuestFrame", label = "Quest / Gossip", group = "world", names = { "QuestFrame", "GossipFrame" }, defaultEnabled = true },
    -- Bags
    { id = "ContainerFrameCombinedBags", label = "Combined Bags", group = "bags", names = { "ContainerFrameCombinedBags" }, defaultEnabled = true },
    { id = "BankFrame", label = "Bank", group = "bags", names = { "BankFrame" }, defaultEnabled = true },
    -- Vendors
    { id = "MerchantFrame", label = "Merchant", group = "vendors", names = { "MerchantFrame" }, defaultEnabled = true, ignoreFramePositionManager = true, userPlaced = true },
    { id = "AuctionHouseFrame", label = "Auction House", group = "vendors", names = { "AuctionHouseFrame" }, addon = "Blizzard_AuctionHouseUI", defaultEnabled = true },
    { id = "MailFrame", label = "Mail", group = "vendors", names = { "MailFrame" }, addon = "Blizzard_MailFrame", useRootHandle = true, handles = { "SendMailFrame", "MailFrameInset" }, defaultEnabled = true },
    { id = "ItemUpgradeFrame", label = "Item Upgrade", group = "vendors", names = { "ItemUpgradeFrame" }, addon = "Blizzard_ItemUpgradeUI", defaultEnabled = true },
    -- Professions
    { id = "ProfessionsFrame", label = "Professions", group = "professions", names = { "ProfessionsFrame" }, addon = "Blizzard_Professions", defaultEnabled = true },
    { id = "ProfessionsBookFrame", label = "Professions Book", group = "professions", names = { "ProfessionsBookFrame" }, addon = "Blizzard_ProfessionsBook", defaultEnabled = true },
    { id = "ProfessionsCustomerOrdersFrame", label = "Customer Orders", group = "professions", names = { "ProfessionsCustomerOrdersFrame" }, addon = "Blizzard_ProfessionsCustomerOrders", defaultEnabled = true },
}

---------------------------------------------------------------------------
-- REGISTRY
---------------------------------------------------------------------------
local registry = {
    frames = {},      -- [id] = entry
    frameList = {},   -- ordered list
    byName = {},      -- [frameName] = id
    addonIndex = {},  -- [addonName] = {entry, ...}
    noAddonEntries = {},
}

local pendingApply = {}
local combatQueue = {}
local sessionPositions = {}

---------------------------------------------------------------------------
-- RESOLVE HELPERS (from original)
---------------------------------------------------------------------------
local function resolveFramePath(path)
    if not path or type(path) ~= "string" then return nil end
    local first, rest = path:match("([^.]+)%.?(.*)")
    local obj = _G[first]
    if not obj then return nil end
    if rest and rest ~= "" then
        for seg in rest:gmatch("([^.]+)") do
            obj = obj and obj[seg]
            if not obj then return nil end
        end
    end
    return obj
end

local function resolveEntry(entryOrId)
    if type(entryOrId) == "table" then return entryOrId end
    if type(entryOrId) == "string" then return registry.frames[entryOrId] end
    return nil
end

local function clampScale(value)
    if type(value) ~= "number" then return 1 end
    if value < SCALE_MIN then return SCALE_MIN end
    if value > SCALE_MAX then return SCALE_MAX end
    return value
end

---------------------------------------------------------------------------
-- DB HELPERS
---------------------------------------------------------------------------
local function ensureFrameDb(entry)
    local resolved = resolveEntry(entry)
    if not resolved then return nil end
    local frameDB = GetFrameDB()
    if not frameDB then return nil end
    frameDB[resolved.id] = frameDB[resolved.id] or {}
    local fdb = frameDB[resolved.id]
    if fdb.enabled == nil then fdb.enabled = resolved.defaultEnabled ~= false end
    return fdb
end

local function isEntryActive(entry)
    local qol = GetQoL()
    if not qol or not qol.frameMoverEnabled then return false end
    local fdb = ensureFrameDb(entry)
    return fdb and fdb.enabled ~= false
end

local function modifierPressed()
    local qol = GetQoL()
    if not qol or not qol.frameMoverRequireModifier then return true end
    local mod = qol.frameMoverModifier or "SHIFT"
    return (mod == "SHIFT" and IsShiftKeyDown()) or (mod == "CTRL" and IsControlKeyDown()) or (mod == "ALT" and IsAltKeyDown())
end

local function scaleModifierPressed()
    local qol = GetQoL()
    local mod = qol and qol.frameMoverScaleModifier or "CTRL"
    return (mod == "SHIFT" and IsShiftKeyDown()) or (mod == "CTRL" and IsControlKeyDown()) or (mod == "ALT" and IsAltKeyDown())
end

---------------------------------------------------------------------------
-- POSITION PERSISTENCE (from original)
---------------------------------------------------------------------------
local function getPositionData(entry, frameDb)
    local qol = GetQoL()
    local mode = qol and qol.frameMoverPersistence or "reset"
    if mode == "lockout" then
        return sessionPositions[entry.id]
    end
    if mode == "reset" then return frameDb end
    return nil
end

local function setPositionData(entry, frameDb, point, x, y)
    local qol = GetQoL()
    local mode = qol and qol.frameMoverPersistence or "reset"
    if mode == "close" then return end
    if mode == "lockout" then
        sessionPositions[entry.id] = sessionPositions[entry.id] or {}
        local data = sessionPositions[entry.id]
        data.point = point; data.x = x; data.y = y
        return
    end
    if frameDb then
        frameDb.point = point; frameDb.x = x; frameDb.y = y
    end
end

---------------------------------------------------------------------------
-- DEFAULT POINT CAPTURE/RESTORE (from original)
---------------------------------------------------------------------------
local function captureDefaultPoints(frame)
    if not frame or frame._kdtDefaultPoints then return end
    local numPoints = frame.GetNumPoints and frame:GetNumPoints() or 0
    if numPoints <= 0 then return end
    local points = {}
    for i = 1, numPoints do
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)
        if point then
            local relativeName = relativeTo and relativeTo.GetName and relativeTo:GetName() or nil
            points[#points + 1] = {
                point = point, relative = relativeTo, relativeName = relativeName,
                relativePoint = relativePoint, x = xOfs, y = yOfs,
            }
        end
    end
    if #points > 0 then frame._kdtDefaultPoints = points end
end

local function applyDefaultPoints(frame)
    local points = frame and frame._kdtDefaultPoints
    if not points or #points == 0 then return false end
    frame:ClearAllPoints()
    for _, data in ipairs(points) do
        local relative = data.relative
        if type(relative) == "string" then relative = _G[relative] end
        if not relative and data.relativeName then relative = _G[data.relativeName] end
        relative = relative or UIParent
        frame:SetPoint(data.point, relative, data.relativePoint or data.point, data.x or 0, data.y or 0)
    end
    return true
end

---------------------------------------------------------------------------
-- FRAME STATE (from original)
---------------------------------------------------------------------------
local function captureDefaultState(frame)
    if not frame or frame._kdtMoverDefaults then return end
    local defaults = {}
    if frame.IsMovable then defaults.movable = frame:IsMovable() end
    if frame.IsClampedToScreen then defaults.clamped = frame:IsClampedToScreen() end
    if frame.IsMouseEnabled then defaults.mouseEnabled = frame:IsMouseEnabled() end
    if frame.IsUserPlaced then defaults.userPlaced = frame:IsUserPlaced() end
    defaults.ignoreFramePositionManager = frame.ignoreFramePositionManager
    frame._kdtMoverDefaults = defaults
end

local function applyFrameState(frame, entry, active)
    local defaults = frame and frame._kdtMoverDefaults
    if not defaults then return end
    if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return end
    if active then
        if frame.SetMovable then frame:SetMovable(true) end
        if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
        if entry.userPlaced ~= nil and frame.SetUserPlaced then frame:SetUserPlaced(entry.userPlaced) end
        if entry.ignoreFramePositionManager ~= nil then frame.ignoreFramePositionManager = entry.ignoreFramePositionManager end
        if frame.EnableMouse then frame:EnableMouse(true) end
    else
        if defaults.movable ~= nil and frame.SetMovable then frame:SetMovable(defaults.movable) end
        if defaults.clamped ~= nil and frame.SetClampedToScreen then frame:SetClampedToScreen(defaults.clamped) end
        if defaults.mouseEnabled ~= nil and frame.EnableMouse then frame:EnableMouse(defaults.mouseEnabled) end
        if entry.userPlaced ~= nil and defaults.userPlaced ~= nil and frame.SetUserPlaced then frame:SetUserPlaced(defaults.userPlaced) end
        if entry.ignoreFramePositionManager ~= nil then frame.ignoreFramePositionManager = defaults.ignoreFramePositionManager end
    end
end

---------------------------------------------------------------------------
-- APPLY / STORE (from original)
---------------------------------------------------------------------------
local function applyFrameSettings(frame, entry)
    if not frame then return end
    local resolved = resolveEntry(entry)
    if not resolved then return end
    if not isEntryActive(resolved) then return end
    local frameDb = ensureFrameDb(resolved)
    local posData = getPositionData(resolved, frameDb)
    local hasPoint = posData and posData.point and posData.x ~= nil and posData.y ~= nil
    local targetScale = frameDb and type(frameDb.scale) == "number" and clampScale(frameDb.scale) or nil
    local qol = GetQoL()
    if not qol or not qol.frameMoverScaleEnabled then targetScale = nil end
    if not hasPoint and not targetScale then return end
    if InCombatLockdown() and frame:IsProtected() then
        pendingApply[frame] = resolved
        return
    end
    frame._kdt_isApplying = true
    if hasPoint then
        frame:ClearAllPoints()
        frame:SetPoint(posData.point, UIParent, posData.point, posData.x, posData.y)
    end
    if targetScale and frame.SetScale then frame:SetScale(targetScale) end
    frame._kdt_isApplying = nil
end

local function storeFramePosition(frame, entry)
    local resolved = resolveEntry(entry)
    if not resolved then return end
    local frameDb = ensureFrameDb(resolved)
    if not frameDb then return end
    local point, _, _, xOfs, yOfs = frame:GetPoint()
    if not point then return end
    setPositionData(resolved, frameDb, point, xOfs, yOfs)
end

---------------------------------------------------------------------------
-- HOOK CREATION (from original, simplified)
---------------------------------------------------------------------------
local function createHooks(frame, entry)
    if not frame then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    if frame._kdtLayoutHooks then return end

    local resolved = resolveEntry(entry)
    if not resolved then return end

    captureDefaultPoints(frame)
    captureDefaultState(frame)

    if InCombatLockdown() then
        combatQueue[frame] = resolved
        return
    end

    frame._kdtMoverEntry = resolved

    local function onStartDrag(_, button)
        if button and button ~= "LeftButton" then return end
        if not isEntryActive(resolved) then return end
        if not modifierPressed() then return end
        if InCombatLockdown() and frame:IsProtected() then return end
        frame._kdt_isDragging = true
        frame:StartMoving()
    end

    local function onStopDrag(_, button)
        if button and button ~= "LeftButton" then return end
        if not isEntryActive(resolved) then return end
        if InCombatLockdown() and frame:IsProtected() then return end
        frame:StopMovingOrSizing()
        frame._kdt_isDragging = nil
        storeFramePosition(frame, resolved)
    end

    local function onScaleWheel(_, delta)
        if not isEntryActive(resolved) then return end
        local qol = GetQoL()
        if not qol or not qol.frameMoverScaleEnabled then return end
        if not scaleModifierPressed() then return end
        local frameDb = ensureFrameDb(resolved)
        local current = frameDb and frameDb.scale
        if type(current) ~= "number" and frame.GetScale then current = frame:GetScale() end
        current = clampScale(current or 1)
        local newScale = clampScale(current + (delta * SCALE_STEP))
        if frameDb then frameDb.scale = newScale end
        if not InCombatLockdown() or not frame:IsProtected() then
            if frame.SetScale then frame:SetScale(newScale) end
        end
    end

    local function onResetClick(_, button)
        if button ~= "RightButton" then return end
        if not isEntryActive(resolved) then return end
        if not scaleModifierPressed() then return end
        local frameDb = ensureFrameDb(resolved)
        if frameDb then
            frameDb.scale = nil; frameDb.point = nil; frameDb.x = nil; frameDb.y = nil
        end
        sessionPositions[resolved.id] = nil
        if frame.SetScale then frame:SetScale(1) end
        if frame._kdtDefaultPoints then
            frame._kdt_isApplying = true
            applyDefaultPoints(frame)
            frame._kdt_isApplying = nil
        end
    end

    -- Attach drag handlers
    frame:EnableMouse(true)
    frame:HookScript("OnMouseDown", onStartDrag)
    frame:HookScript("OnMouseUp", onStopDrag)
    frame:HookScript("OnMouseUp", onResetClick)

    -- Attach handles for relative subframes
    if resolved.handles then
        for _, path in ipairs(resolved.handles) do
            local handle = resolveFramePath(path)
            if handle and not handle.IsForbidden or not handle:IsForbidden() then
                handle:HookScript("OnMouseDown", onStartDrag)
                handle:HookScript("OnMouseUp", onStopDrag)
            end
        end
    end
    if resolved.handlesRelative then
        for _, rel in ipairs(resolved.handlesRelative) do
            for _, base in ipairs(resolved.names) do
                local handle = resolveFramePath(base .. "." .. rel)
                if handle and (not handle.IsForbidden or not handle:IsForbidden()) then
                    pcall(function()
                        handle:HookScript("OnMouseDown", onStartDrag)
                        handle:HookScript("OnMouseUp", onStopDrag)
                    end)
                end
            end
        end
    end

    -- Scale via mouse wheel
    frame:HookScript("OnMouseWheel", onScaleWheel)

    -- Intercept programmatic SetPoint to reapply saved position
    hooksecurefunc(frame, "SetPoint", function(self)
        if not isEntryActive(resolved) then return end
        if self._kdt_isDragging or self._kdt_isApplying then return end
        local frameDb = ensureFrameDb(resolved)
        local posData = getPositionData(resolved, frameDb)
        if not posData or not posData.point then return end
        if InCombatLockdown() and self:IsProtected() then
            pendingApply[self] = resolved
            return
        end
        self._kdt_isApplying = true
        self:ClearAllPoints()
        self:SetPoint(posData.point, UIParent, posData.point, posData.x, posData.y)
        self._kdt_isApplying = nil
    end)

    -- Apply saved position when shown
    frame:HookScript("OnShow", function(self)
        if not self._kdtDefaultPoints then captureDefaultPoints(self) end
        applyFrameSettings(self, resolved)
    end)

    -- Reset on close (if persistence = "close")
    if not resolved.skipOnHide then
        frame:HookScript("OnHide", function(self)
            local qol = GetQoL()
            if not qol or qol.frameMoverPersistence ~= "close" then return end
            if not isEntryActive(resolved) then return end
            if self._kdt_isDragging or self._kdt_isApplying then return end
            if InCombatLockdown() and self:IsProtected() then return end
            if not self._kdtDefaultPoints then return end
            self._kdt_isApplying = true
            applyDefaultPoints(self)
            self._kdt_isApplying = nil
        end)
    end

    frame._kdtLayoutHooks = true
    combatQueue[frame] = nil

    -- Apply frame state
    local active = isEntryActive(resolved)
    applyFrameState(frame, resolved, active)
end

---------------------------------------------------------------------------
-- ADDON/FRAME INDEXING (from original)
---------------------------------------------------------------------------
local function indexEntryByAddon(entry)
    if not entry.addon then
        registry.noAddonEntries[#registry.noAddonEntries + 1] = entry
        return
    end
    local addons = type(entry.addon) == "table" and entry.addon or { entry.addon }
    for _, name in ipairs(addons) do
        registry.addonIndex[name] = registry.addonIndex[name] or {}
        registry.addonIndex[name][#registry.addonIndex[name] + 1] = entry
    end
end

local function isAnyAddonLoaded(entry)
    if not entry.addon then return true end
    if not IsAddonLoaded then return false end
    local addons = type(entry.addon) == "table" and entry.addon or { entry.addon }
    for _, name in ipairs(addons) do
        if IsAddonLoaded(name) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- REGISTRATION
---------------------------------------------------------------------------
local function registerFrame(def)
    if not def or not def.id then return end
    if registry.frames[def.id] then return end

    local names = def.names or { def.id }
    local entry = {
        id = def.id,
        label = def.label or def.id,
        group = def.group or "default",
        defaultEnabled = def.defaultEnabled,
        names = names,
        handles = def.handles,
        handlesRelative = def.handlesRelative,
        addon = def.addon,
        useRootHandle = def.useRootHandle,
        ignoreFramePositionManager = def.ignoreFramePositionManager,
        userPlaced = def.userPlaced,
        skipOnHide = def.skipOnHide,
    }

    registry.frames[entry.id] = entry
    registry.frameList[#registry.frameList + 1] = entry

    for _, name in ipairs(entry.names) do
        registry.byName[name] = entry.id
    end

    ensureFrameDb(entry)
    indexEntryByAddon(entry)
end

local function tryHookEntry(entry)
    local resolved = resolveEntry(entry)
    if not resolved then return end
    if not isAnyAddonLoaded(resolved) then return end
    if not isEntryActive(resolved) then return end
    for _, name in ipairs(resolved.names or {}) do
        local frame = resolveFramePath(name)
        if frame then
            createHooks(frame, resolved)
            applyFrameSettings(frame, resolved)
        end
    end
end

local function tryHookAll()
    for _, entry in ipairs(registry.frameList) do
        tryHookEntry(entry)
    end
end

local function refreshAll()
    for _, entry in ipairs(registry.frameList) do
        tryHookEntry(entry)
        -- Update state for already-hooked frames
        for _, name in ipairs(entry.names or {}) do
            local frame = resolveFramePath(name)
            if frame and frame._kdtLayoutHooks then
                local active = isEntryActive(entry)
                applyFrameState(frame, entry, active)
            end
        end
    end
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local moverFrame = CreateFrame("Frame")

local function OnEvent(self, event, arg1)
    local qol = GetQoL()
    if not qol or not qol.frameMoverEnabled then return end

    if event == "ADDON_LOADED" then
        -- Hook frames for newly loaded addons
        local list = registry.addonIndex[arg1]
        if list then
            for _, entry in ipairs(list) do
                tryHookEntry(entry)
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Process combat queue
        for frame, entry in pairs(combatQueue) do
            combatQueue[frame] = nil
            if frame then createHooks(frame, entry) end
        end
        for frame, entry in pairs(pendingApply) do
            pendingApply[frame] = nil
            if frame then applyFrameSettings(frame, entry) end
        end
    end
end

moverFrame:RegisterEvent("ADDON_LOADED")
moverFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
moverFrame:SetScript("OnEvent", OnEvent)

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:InitFrameMover()
    local qol = GetQoL()
    if not qol or not qol.frameMoverEnabled then return end

    -- Register all frame definitions
    for _, def in ipairs(frameDefinitions) do
        registerFrame(def)
    end

    -- Try to hook all currently available frames
    tryHookAll()
end

function KDT:RefreshFrameMover()
    refreshAll()
end

-- Get registry for UI listing
function KDT:GetFrameMoverEntries()
    return registry.frameList
end

function KDT:IsFrameMoverEntryEnabled(entry)
    return isEntryActive(entry)
end

function KDT:SetFrameMoverEntryEnabled(entry, value)
    local fdb = ensureFrameDb(entry)
    if fdb then fdb.enabled = value and true or false end
    tryHookEntry(entry)
    for _, name in ipairs(entry.names or {}) do
        local frame = resolveFramePath(name)
        if frame and frame._kdtLayoutHooks then
            applyFrameState(frame, entry, value)
        end
    end
end
