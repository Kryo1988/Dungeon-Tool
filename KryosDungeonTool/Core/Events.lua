-- Kryos Dungeon Tool
-- Core/Events.lua - Event handling (WoW 12.0 Midnight compatible)
-- NO RegisterEvent calls - uses only polling with C_Timer

local addonName, KDT = ...

-- State tracking for polling
local lastGroupSize = 0
local lastInGroup = false
local lastInInstance = false
local initialized = false

-- ==================== INITIALIZATION ====================
EventUtil.ContinueOnAddOnLoaded(addonName, function()
    if initialized then return end
    initialized = true
    
    -- Initialize database
    KDT:InitDB()
    KDT:Print("v" .. KDT.version .. " loaded. Type /kdt for options.")
    
    -- Register addon message prefix (this is safe)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("KDT")
    end
    
    -- Create main UI
    KDT.MainFrame = KDT:CreateMainFrame()
    KDT:CreateGroupElements(KDT.MainFrame)
    KDT:CreateTeleportElements(KDT.MainFrame)
    KDT:CreateTimerElements(KDT.MainFrame)
    KDT:CreateBlacklistElements(KDT.MainFrame)
    KDT:SetupTabSwitching(KDT.MainFrame)
    KDT:SetupGroupRefresh(KDT.MainFrame)
    KDT:SetupBlacklistRefresh(KDT.MainFrame)
    KDT:SetupTeleportRefresh(KDT.MainFrame)
    KDT:SetupTimerRefresh(KDT.MainFrame)
    
    -- Initially hide all elements except group
    for _, el in pairs(KDT.MainFrame.blacklistElements) do
        if el.Hide then el:Hide() end
    end
    for _, el in pairs(KDT.MainFrame.teleportElements) do
        if el.Hide then el:Hide() end
    end
    for _, el in pairs(KDT.MainFrame.timerElements) do
        if el.Hide then el:Hide() end
    end
    
    -- Minimap button
    KDT:CreateMinimapButton()
    KDT:UpdateMinimapPosition()
    KDT:SetupMinimapButton()
    
    -- Setup tooltip hook
    KDT:SetupTooltipHook()
    
    -- Setup right-click menu (WoW 12.0 Menu API)
    KDT:SetupRightClickMenu()
    
    -- Hook LFG frame to auto-open addon
    if PVEFrame then
        pcall(function()
            PVEFrame:HookScript("OnShow", function()
                if KDT.MainFrame and not KDT.MainFrame:IsShown() then
                    KDT.MainFrame:Show()
                    KDT.MainFrame:SwitchTab("group")
                end
            end)
        end)
    end
    
    -- Request map info
    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        C_MythicPlus.RequestMapInfo()
    end
    
    -- Create external timer if enabled
    if KDT.DB.timer.enabled then
        KDT:CreateExternalTimer()
    end
    
    -- ==================== POLLING SYSTEM ====================
    -- Fast ticker for timer updates (0.1 sec)
    C_Timer.NewTicker(0.1, function()
        KDT:UpdateTimerFromGame()
        KDT:UpdateExternalTimer()
    end)
    
    -- Death tracking ticker (0.5 sec) - checks who died
    local knownDead = {}
    C_Timer.NewTicker(0.5, function()
        if not C_ChallengeMode or not C_ChallengeMode.IsChallengeModeActive or not C_ChallengeMode.IsChallengeModeActive() then
            wipe(knownDead)
            return
        end
        
        -- Get official death count
        local deaths = C_ChallengeMode.GetDeathCount()
        if deaths then
            KDT.timerState.deaths = deaths
        end
        
        -- Check each group member for death status
        local units = KDT:GetGroupUnits()
        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local name = UnitName(unit)
                local isDead = UnitIsDead(unit) or UnitIsGhost(unit)
                
                if name then
                    if isDead and not knownDead[name] then
                        -- Player just died!
                        knownDead[name] = true
                        local _, class = UnitClass(unit)
                        KDT:RecordDeath(name, class)
                    elseif not isDead and knownDead[name] then
                        -- Player was resurrected
                        knownDead[name] = nil
                    end
                end
            end
        end
    end)
    
    -- Slow ticker for group/UI updates (1 sec)
    C_Timer.NewTicker(1, function()
        local inGroup = IsInGroup()
        local groupSize = GetNumGroupMembers()
        
        -- Group changed?
        if inGroup ~= lastInGroup or groupSize ~= lastGroupSize then
            lastInGroup = inGroup
            lastGroupSize = groupSize
            
            -- Handle group change
            KDT:CheckForNewMembers()
            
            if inGroup then
                KDT:BroadcastOwnKey()
            else
                wipe(KDT.knownGroupMembers)
                wipe(KDT.groupKeys)
            end
            
            if KDT.MainFrame and KDT.MainFrame:IsShown() then
                KDT.MainFrame:RefreshGroup()
            end
            
            KDT:CheckGroupForBlacklist()
        end
        
        -- Instance changed?
        local inInstance = IsInInstance()
        if inInstance ~= lastInInstance then
            lastInInstance = inInstance
            
            if C_MythicPlus and C_MythicPlus.RequestMapInfo then
                C_MythicPlus.RequestMapInfo()
            end
        end
        
        -- Update timer tab if visible
        if KDT.MainFrame and KDT.MainFrame:IsShown() and KDT.MainFrame.currentTab == "timer" then
            KDT.MainFrame:RefreshTimer()
        end
    end)
    
    -- Initial group check after 2 seconds
    C_Timer.After(2, function()
        if IsInGroup() then
            KDT:BroadcastOwnKey()
            KDT:RequestGroupKeys()
        end
        KDT:CheckGroupForBlacklist()
        
        if KDT.MainFrame and KDT.MainFrame:IsShown() then
            KDT.MainFrame:RefreshGroup()
        end
    end)
end)

-- ==================== AUTO-POST TRACKING ====================
KDT.knownGroupMembers = {}

function KDT:CheckForNewMembers()
    if not self.DB or not self.DB.settings or not self.DB.settings.autoPost then return end
    if not IsInGroup() then 
        wipe(self.knownGroupMembers)
        return 
    end
    
    -- Only post if we are the group leader
    if not UnitIsGroupLeader("player") then return end
    
    local units = self:GetGroupUnits()
    local currentMembers = {}
    
    for _, unit in ipairs(units) do
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local name = UnitName(unit)
            if name then
                currentMembers[name] = unit
                
                -- Check if this is a new member
                if not self.knownGroupMembers[name] then
                    self.knownGroupMembers[name] = true
                    
                    -- Get class and spec
                    local _, class = UnitClass(unit)
                    local className = self.CLASS_NAMES[class] or class or "Unknown"
                    local specData = self:GetUnitSpec(unit)
                    local specName = specData and specData.specName or nil
                    
                    -- Build class/spec string
                    local classSpecStr = className
                    if specName then
                        classSpecStr = className .. " - " .. specName
                    end
                    
                    -- Build utility string
                    local utils = {}
                    if self.BATTLE_REZ and self.BATTLE_REZ[class] then
                        table.insert(utils, "BR")
                    end
                    if self.BLOODLUST and self.BLOODLUST[class] then
                        table.insert(utils, "BL")
                    end
                    
                    local utilStr = ""
                    if #utils > 0 then
                        utilStr = " - brings " .. table.concat(utils, " & ")
                    end
                    
                    local channel = IsInRaid() and "RAID" or "PARTY"
                    local msg = "[KDT] " .. name .. " joined (" .. classSpecStr .. ")" .. utilStr
                    SendChatMessage(msg, channel)
                end
            end
        end
    end
    
    -- Clean up old members
    for name in pairs(self.knownGroupMembers) do
        if not currentMembers[name] then
            self.knownGroupMembers[name] = nil
        end
    end
end

-- ==================== TOOLTIP HOOK ====================
function KDT:SetupTooltipHook()
    if not TooltipDataProcessor then return end
    
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not self.DB or not self.DB.blacklist then return end
        
        local _, unit = tooltip:GetUnit()
        if not unit or not UnitIsPlayer(unit) then return end
        
        local name = UnitName(unit)
        if not name then return end
        
        for _, entry in ipairs(self.DB.blacklist) do
            if entry.name == name then
                tooltip:AddLine(" ")
                tooltip:AddLine("|cFFFF0000[BLACKLISTED]|r " .. (entry.reason or "No reason"), 1, 0, 0)
                tooltip:Show()
                break
            end
        end
    end)
end

-- ==================== RIGHT-CLICK MENU (WoW 12.0) ====================
function KDT:SetupRightClickMenu()
    -- Check if Menu API exists (WoW 12.0+)
    if not Menu or not Menu.ModifyMenu then
        return
    end
    
    -- Helper function to add blacklist option to a menu
    local function AddBlacklistOption(ownerRegion, rootDescription, contextData)
        -- Get the unit from context - try multiple approaches
        local unit = nil
        local name = nil
        
        if contextData then
            unit = contextData.unit
            name = contextData.name
        end
        
        -- If no unit from context, try to get from dropdown owner
        if not unit and ownerRegion then
            if ownerRegion.unit then
                unit = ownerRegion.unit
            elseif ownerRegion:GetAttribute("unit") then
                unit = ownerRegion:GetAttribute("unit")
            end
        end
        
        -- Get name from unit if we have one
        if unit and UnitExists(unit) then
            if not UnitIsPlayer(unit) then return end
            name = UnitName(unit)
            
            -- Don't show for self
            if UnitIsUnit(unit, "player") then return end
        end
        
        if not name then return end
        
        -- Remove realm from name
        name = name:gsub("%-.*", "")
        
        -- Check if already blacklisted
        local alreadyBlacklisted = KDT:IsBlacklisted(name)
        
        -- Add separator
        rootDescription:CreateDivider()
        
        if alreadyBlacklisted then
            -- Option to remove from blacklist
            rootDescription:CreateButton("|cFF00FF00Remove from Blacklist|r", function()
                KDT:RemoveFromBlacklist(name)
                KDT:Print("|cFF00FF00Removed from blacklist:|r " .. name)
                if KDT.MainFrame and KDT.MainFrame:IsShown() then
                    KDT.MainFrame:RefreshBlacklist()
                end
            end)
        else
            -- Option to add to blacklist - directly without dialog
            rootDescription:CreateButton("|cFFFF0000Add to Blacklist|r", function()
                KDT:AddToBlacklist(name, "Added by Rightclick")
                if KDT.MainFrame and KDT.MainFrame:IsShown() then
                    KDT.MainFrame:RefreshBlacklist()
                end
            end)
        end
    end
    
    -- Hook into various unit popup menus using all possible tag names
    local menuTags = {
        -- Standard unit menus
        "MENU_UNIT_SELF",
        "MENU_UNIT_PLAYER",
        "MENU_UNIT_PARTY",
        "MENU_UNIT_RAID",
        "MENU_UNIT_RAID_PLAYER",
        "MENU_UNIT_ENEMY_PLAYER",
        "MENU_UNIT_FRIEND",
        "MENU_UNIT_TARGET",
        "MENU_UNIT_FOCUS",
        "MENU_UNIT_BOSS",
        "MENU_UNIT_ARENA_ENEMY",
        -- LFG menus
        "MENU_LFG_FRAME_MEMBER_APPLY",
        "MENU_LFG_FRAME_SEARCH_ENTRY",
    }
    
    local registered = 0
    for _, tag in ipairs(menuTags) do
        local success = pcall(function()
            Menu.ModifyMenu(tag, AddBlacklistOption)
        end)
        if success then
            registered = registered + 1
        end
    end
end

-- ==================== KEYSTONE SHARING ====================
KDT.groupKeys = {}

function KDT:BroadcastOwnKey()
    if not IsInGroup() then return end
    
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
    if mapID and level then
        local msg = "KEY:" .. mapID .. ":" .. level
        local channel = IsInRaid() and "RAID" or "PARTY"
        C_ChatInfo.SendAddonMessage("KDT", msg, channel)
    end
end

function KDT:RequestGroupKeys()
    if not IsInGroup() then return end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage("KDT", "KEYREQ", channel)
end

function KDT:HandleAddonMessage(msg, sender)
    if not msg or not sender then return end
    
    -- Remove realm from sender name for comparison
    local senderName = strsplit("-", sender)
    
    if msg == "KEYREQ" then
        -- Someone requested keys, broadcast ours
        self:BroadcastOwnKey()
        
    elseif msg:find("^KEY:") then
        -- Someone shared their key
        local _, mapID, level = strsplit(":", msg)
        mapID = tonumber(mapID)
        level = tonumber(level)
        
        if mapID and level then
            self.groupKeys[senderName] = {
                mapID = mapID,
                level = level,
                dungeonName = self:GetDungeonName(mapID) or "Unknown",
            }
            
            -- Refresh UI if visible
            if self.MainFrame and self.MainFrame:IsShown() then
                self.MainFrame:RefreshGroup()
            end
        end
        
    elseif msg:find("^BL:") then
        -- Blacklist share
        self:HandleBlacklistShare(msg, senderName)
    end
end

function KDT:HandleBlacklistShare(msg, sender)
    -- Parse blacklist data
    local _, data = strsplit(":", msg, 2)
    if not data then return end
    
    -- Show import dialog
    if self.ShowBlacklistImportDialog then
        self:ShowBlacklistImportDialog(data, sender)
    end
end

-- ==================== INSPECT HANDLING ====================
KDT.pendingInspects = {}

function KDT:OnInspectReady(guid)
    if not guid then return end
    
    local callback = self.pendingInspects[guid]
    if callback then
        callback(guid)
        self.pendingInspects[guid] = nil
    end
end

function KDT:RequestInspect(unit, callback)
    if not unit or not UnitExists(unit) then return end
    
    local guid = UnitGUID(unit)
    if not guid then return end
    
    if callback then
        self.pendingInspects[guid] = callback
    end
    
    if CanInspect(unit) then
        NotifyInspect(unit)
    end
end
