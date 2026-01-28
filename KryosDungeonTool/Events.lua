-- Kryos Dungeon Tool
-- Events.lua - Event handling and initialization

local addonName, KDT = ...

-- ==================== EVENTS ====================
function KDT:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:RegisterEvent("INSPECT_READY")
    
    eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, _, arg4)
        if event == "ADDON_LOADED" and arg1 == addonName then
            KDT:OnAddonLoaded()
            
        elseif event == "GROUP_ROSTER_UPDATE" then
            KDT:OnGroupRosterUpdate()
            
        elseif event == "INSPECT_READY" then
            KDT:OnInspectReady(arg1)
            
        elseif event == "CHAT_MSG_ADDON" and arg1 == "KryosDT" then
            KDT:ReceiveBlacklist(arg2, arg4)
            if KDT.MainFrame then KDT.MainFrame:RefreshBlacklist() end
        end
    end)
end

-- ==================== EVENT HANDLERS ====================
function KDT:OnAddonLoaded()
    -- Initialize database
    self:InitDB()
    
    -- Create UI
    self.MainFrame = self:CreateMainFrame()
    self:CreateGroupElements(self.MainFrame)
    self:CreateTeleportElements(self.MainFrame)
    self:CreateBlacklistElements(self.MainFrame)
    
    -- Setup UI functionality
    self:SetupTabSwitching(self.MainFrame)
    self:SetupGroupRefresh(self.MainFrame)
    self:SetupBlacklistRefresh(self.MainFrame)
    self:SetupTeleportRefresh(self.MainFrame)
    
    -- Initially hide blacklist and teleport elements
    for _, el in pairs(self.MainFrame.blacklistElements) do
        if el.Hide then el:Hide() end
    end
    for _, el in pairs(self.MainFrame.teleportElements) do
        if el.Hide then el:Hide() end
    end
    
    -- Minimap button
    self:CreateMinimapButton()
    self:UpdateMinimapPosition()
    self:SetupMinimapButton()
    
    -- Slash commands
    self:RegisterSlashCommands()
    
    -- Hook LFG
    if PVEFrame then
        PVEFrame:HookScript("OnShow", function()
            if not KDT.MainFrame:IsShown() then
                KDT.MainFrame:Show()
                KDT.MainFrame:SwitchTab("group")
            end
        end)
    end
    
    -- Setup integrations
    self:SetupRightClickMenu()
    self:SetupTooltipHook()
    
    print("|cFFFF0000[Kryos Dungeon Tool]|r v" .. self.version .. " loaded. /kdt")
end

function KDT:OnGroupRosterUpdate()
    self:CheckBlacklistAlert()
    self:CheckNewMembers()
    
    -- Request inspect for party members
    C_Timer.After(0.5, function()
        KDT:RequestPartyInspect()
    end)
    
    if self.MainFrame and self.MainFrame:IsShown() and self.MainFrame.currentTab == "group" then
        self.MainFrame:RefreshGroup()
    end
end

function KDT:OnInspectReady(guid)
    if not guid then return end
    
    -- Find the unit with this GUID and cache their spec
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            local specID = GetInspectSpecialization(unit)
            if specID and specID > 0 then
                local _, specName = GetSpecializationInfoByID(specID)
                if specName then
                    local name = UnitName(unit)
                    if name then
                        local cleanName = name:gsub("%-.*", "")
                        self.specCache[cleanName] = specName
                        self.pendingInspects[cleanName] = nil
                    end
                end
            end
            break
        end
    end
    
    -- Refresh group display
    if self.MainFrame and self.MainFrame:IsShown() and self.MainFrame.currentTab == "group" then
        self.MainFrame:RefreshGroup()
    end
end

-- ==================== INTEGRATIONS ====================
function KDT:SetupRightClickMenu()
    pcall(function()
        for _, m in ipairs({"MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_FRIEND"}) do
            Menu.ModifyMenu(m, function(_, root, data)
                local n = data and (data.name or (data.unit and UnitName(data.unit)))
                if n then
                    n = n:gsub("%-.*", "")
                    if not KDT:IsBlacklisted(n) then
                        root:CreateButton("|cFFFF4444Add to Blacklist|r", function()
                            KDT:AddToBlacklist(n, "Right-click")
                            if KDT.MainFrame then KDT.MainFrame:RefreshBlacklist() end
                        end)
                    else
                        root:CreateButton("|cFFFF4444Remove from Blacklist|r", function()
                            KDT:RemoveFromBlacklist(n)
                            if KDT.MainFrame then KDT.MainFrame:RefreshBlacklist() end
                        end)
                    end
                end
            end)
        end
    end)
end

function KDT:SetupTooltipHook()
    pcall(function()
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt)
            if tt ~= GameTooltip then return end
            local _, unit = tt:GetUnit()
            if not unit or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
            local n = UnitName(unit)
            if n and KDT:IsBlacklisted(n) then
                local d = KDT.DB.blacklist[n:gsub("%-.*", "")]
                tt:AddLine(" ")
                tt:AddLine("|cFFFF4444[!] BLACKLISTED|r")
                if d then tt:AddLine("|cFFFF8888" .. d.reason .. "|r") end
                tt:Show()
            end
        end)
    end)
end
