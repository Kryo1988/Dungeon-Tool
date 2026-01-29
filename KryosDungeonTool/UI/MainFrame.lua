-- Kryos Dungeon Tool
-- UI/MainFrame.lua - Main window and tab system (v1.4 Style)

local addonName, KDT = ...

-- ==================== MAIN FRAME ====================
function KDT:CreateMainFrame()
    local f = CreateFrame("Frame", "KryosDTMain", UIParent, "BackdropTemplate")
    f:SetSize(700, 550)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
    f:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    f:Hide()
    
    -- Register with UISpecialFrames for ESC handling (standard WoW method)
    tinsert(UISpecialFrames, "KryosDTMain")
    
    f.currentTab = "group"
    f.groupElements = {}
    f.blacklistElements = {}
    f.teleportElements = {}
    f.timerElements = {}
    f.memberRows = {}
    f.blRows = {}
    f.teleportButtons = {}
    
    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetSize(700, 40)
    titleBar:SetPoint("TOP")
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    
    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 12, 0)
    icon:SetTexture("Interface\\Icons\\inv_relics_hourglass")
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    title:SetText("|cFFFFFFFFKRYOS DUNGEON TOOL|r")
    
    local ver = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ver:SetPoint("LEFT", title, "RIGHT", 8, 0)
    ver:SetText("v" .. KDT.version)
    ver:SetTextColor(0.5, 0.5, 0.5)
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPoint("RIGHT", -5, 0)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
    closeBtn.text:SetPoint("CENTER", 0, 2)
    closeBtn.text:SetText("×")
    closeBtn.text:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeBtn.text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeBtn.text:SetTextColor(0.6, 0.6, 0.6) end)
    
    -- Tab Buttons (4 tabs now)
    local function CreateTab(text, xPos, width)
        local tab = CreateFrame("Button", nil, f, "BackdropTemplate")
        tab:SetSize(width or 110, 28)
        tab:SetPoint("TOPLEFT", 10 + xPos, -45)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(text)
        tab.indicator = tab:CreateTexture(nil, "OVERLAY")
        tab.indicator:SetSize(width or 110, 2)
        tab.indicator:SetPoint("BOTTOM")
        tab.indicator:SetColorTexture(0.8, 0.2, 0.2, 1)
        return tab
    end
    
    f.groupTab = CreateTab("GROUP CHECK", 0, 110)
    f.teleportTab = CreateTab("M+ TELEPORTS", 115, 110)
    f.timerTab = CreateTab("M+ TIMER", 230, 100)
    f.blacklistTab = CreateTab("BLACKLIST", 335, 100)
    
    -- Content Area
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 0, -78)
    f.content:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- SwitchTab method (defined here so it's available immediately)
    function f:SwitchTab(tabName)
        self.currentTab = tabName
        
        -- Reset all tabs
        local tabs = {self.groupTab, self.teleportTab, self.timerTab, self.blacklistTab}
        for _, tab in ipairs(tabs) do
            tab:SetBackdropColor(0.08, 0.08, 0.10, 1)
            tab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
            tab.text:SetTextColor(0.5, 0.5, 0.5)
            tab.indicator:Hide()
        end
        
        -- Hide all elements
        for _, el in pairs(self.groupElements) do if el.Hide then el:Hide() end end
        for _, el in pairs(self.blacklistElements) do if el.Hide then el:Hide() end end
        for _, el in pairs(self.teleportElements) do if el.Hide then el:Hide() end end
        for _, el in pairs(self.timerElements) do if el.Hide then el:Hide() end end
        for _, btn in ipairs(self.teleportButtons) do if btn.Hide then btn:Hide() end end
        
        -- Show selected tab
        local function ActivateTab(tab)
            tab:SetBackdropColor(0.15, 0.15, 0.18, 1)
            tab:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
            tab.text:SetTextColor(1, 1, 1)
            tab.indicator:Show()
        end
        
        if tabName == "group" then
            ActivateTab(self.groupTab)
            for _, el in pairs(self.groupElements) do if el.Show then el:Show() end end
            if self.RefreshGroup then self:RefreshGroup() end
        elseif tabName == "teleport" then
            ActivateTab(self.teleportTab)
            for _, el in pairs(self.teleportElements) do if el.Show then el:Show() end end
            for _, btn in ipairs(self.teleportButtons) do if btn.Show then btn:Show() end end
            if self.RefreshTeleports then self:RefreshTeleports() end
        elseif tabName == "timer" then
            ActivateTab(self.timerTab)
            for _, el in pairs(self.timerElements) do if el.Show then el:Show() end end
            if self.RefreshTimer then self:RefreshTimer() end
        else
            ActivateTab(self.blacklistTab)
            for _, el in pairs(self.blacklistElements) do if el.Show then el:Show() end end
            if self.RefreshBlacklist then self:RefreshBlacklist() end
        end
    end
    
    -- Tab click handlers
    f.groupTab:SetScript("OnClick", function() f:SwitchTab("group") end)
    f.teleportTab:SetScript("OnClick", function() f:SwitchTab("teleport") end)
    f.timerTab:SetScript("OnClick", function() f:SwitchTab("timer") end)
    f.blacklistTab:SetScript("OnClick", function() f:SwitchTab("blacklist") end)
    
    self.MainFrame = f
    return f
end

-- ==================== TAB SWITCHING (kept for compatibility) ====================
function KDT:SetupTabSwitching(f)
    -- SwitchTab is now defined in CreateMainFrame, this is just a no-op for compatibility
end

-- Toggle main frame
function KDT:ToggleMainFrame()
    if not self.MainFrame then
        self:CreateMainFrame()
    end
    
    if self.MainFrame:IsShown() then
        self.MainFrame:Hide()
    else
        self.MainFrame:Show()
        if self.MainFrame.SwitchTab then
            self.MainFrame:SwitchTab("group")
        end
    end
end
