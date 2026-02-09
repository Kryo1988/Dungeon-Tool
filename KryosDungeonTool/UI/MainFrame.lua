-- Kryos Dungeon Tool
-- UI/MainFrame.lua - Main window and tab system (v1.4 Style)

local addonName, KDT = ...

-- Default and min/max sizes
local DEFAULT_WIDTH = 700
local DEFAULT_HEIGHT = 550
local MIN_WIDTH = 550
local MIN_HEIGHT = 400
local MAX_WIDTH = 1200
local MAX_HEIGHT = 900

-- ==================== MAIN FRAME ====================
function KDT:CreateMainFrame()
    local f = CreateFrame("Frame", "KryosDTMain", UIParent, "BackdropTemplate")
    
    -- Load saved size or use defaults
    local savedWidth = KDT.DB and KDT.DB.frameWidth or DEFAULT_WIDTH
    local savedHeight = KDT.DB and KDT.DB.frameHeight or DEFAULT_HEIGHT
    f:SetSize(savedWidth, savedHeight)
    
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetClampedToScreen(true)
    f:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
    f:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    f:Hide()
    
    -- ESC to close: Use WoW's native UISpecialFrames system (WoW 12.0 compatible)
    -- This is the recommended way to handle ESC key for custom frames
    tinsert(UISpecialFrames, "KryosDTMain")
    
    f.currentTab = "group"
    f.groupElements = {}
    f.blacklistElements = {}
    f.teleportElements = {}
    f.timerElements = {}
    f.bisElements = {}
    f.meterElements = {}
    f.uitweaksElements = {}
    f.memberRows = {}
    f.blRows = {}
    f.bisRows = {}
    f.teleportButtons = {}
    
    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(40)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
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
    
    -- Tab Buttons (5 tabs now)
    local function CreateTab(text, xPos, width)
        local tab = CreateFrame("Button", nil, f, "BackdropTemplate")
        tab:SetSize(width or 100, 28)
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
        tab.indicator:SetSize(width or 100, 2)
        tab.indicator:SetPoint("BOTTOM")
        tab.indicator:SetColorTexture(0.8, 0.2, 0.2, 1)
        return tab
    end
    
    f.groupTab = CreateTab("GROUP CHECK", 0, 95)
    f.teleportTab = CreateTab("M+ TELEPORTS", 98, 95)
    f.timerTab = CreateTab("M+ TIMER", 196, 75)
    f.meterTab = CreateTab("DMG METER", 274, 80)
    f.bisTab = CreateTab("BiS GEAR", 357, 70)
    f.uitweaksTab = CreateTab("TWEAKS", 430, 60)
    f.blacklistTab = CreateTab("BLACKLIST", 493, 75)
    
    -- Content Area (with clipping to hide overflow)
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 0, -78)
    f.content:SetPoint("BOTTOMRIGHT", 0, 0)
    f.content:SetClipsChildren(true)  -- Clip elements that overflow
    
    -- Resize Handle (bottom-right corner)
    local resizeHandle = CreateFrame("Button", nil, f)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeHandle:SetFrameLevel(f:GetFrameLevel() + 10)
    resizeHandle:EnableMouse(true)
    
    -- Resize arrow texture
    local resizeTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    resizeTex:SetAllPoints()
    resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    
    resizeHandle:SetScript("OnEnter", function(self)
        resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeHandle:SetScript("OnLeave", function(self)
        resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function(self, button)
        f:StopMovingOrSizing()
        resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        -- Save new size
        local width, height = f:GetSize()
        if KDT.DB then
            KDT.DB.frameWidth = width
            KDT.DB.frameHeight = height
        end
    end)
    
    f.resizeHandle = resizeHandle
    
    -- SwitchTab method (defined here so it's available immediately)
    function f:SwitchTab(tabName)
        self.currentTab = tabName
        
        -- Reset all tabs
        local tabs = {self.groupTab, self.teleportTab, self.timerTab, self.bisTab, self.meterTab, self.uitweaksTab, self.blacklistTab}
        for _, tab in ipairs(tabs) do
            tab:SetBackdropColor(0.08, 0.08, 0.10, 1)
            tab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
            tab.text:SetTextColor(0.5, 0.5, 0.5)
            tab.indicator:Hide()
        end
        
        -- Hide all elements
        for _, el in pairs(self.groupElements) do if el and el.Hide then el:Hide() end end
        for _, el in pairs(self.blacklistElements) do if el and el.Hide then el:Hide() end end
        for _, el in pairs(self.teleportElements) do if el and el.Hide then el:Hide() end end
        for _, el in pairs(self.timerElements) do if el and el.Hide then el:Hide() end end
        for _, el in pairs(self.bisElements) do if el and el.Hide then el:Hide() end end
        for _, el in pairs(self.meterElements) do if el and el.Hide then el:Hide() end end
        for _, el in pairs(self.uitweaksElements) do if el and el.Hide then el:Hide() end end
        for _, btn in ipairs(self.teleportButtons) do if btn and btn.Hide then btn:Hide() end end
        
        -- Also hide dynamic rows (member rows, blacklist rows, bis rows)
        if self.memberRows then
            for _, row in ipairs(self.memberRows) do if row and row.Hide then row:Hide() end end
        end
        if self.blRows then
            for _, row in ipairs(self.blRows) do if row and row.Hide then row:Hide() end end
        end
        if self.bisRows then
            for _, row in ipairs(self.bisRows) do if row and row.Hide then row:Hide() end end
        end
        
        -- CRITICAL: Hide the memberContainer specifically (contains group member rows)
        if self.groupElements and self.groupElements.memberContainer then
            self.groupElements.memberContainer:Hide()
        end
        
        -- Show selected tab
        local function ActivateTab(tab)
            tab:SetBackdropColor(0.15, 0.15, 0.18, 1)
            tab:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
            tab.text:SetTextColor(1, 1, 1)
            tab.indicator:Show()
        end
        
        if tabName == "group" then
            ActivateTab(self.groupTab)
            for _, el in pairs(self.groupElements) do if el and el.Show then el:Show() end end
            -- Make sure memberContainer is shown for group tab
            if self.groupElements and self.groupElements.memberContainer then
                self.groupElements.memberContainer:Show()
            end
            if self.RefreshGroup then self:RefreshGroup() end
        elseif tabName == "teleport" then
            ActivateTab(self.teleportTab)
            for _, el in pairs(self.teleportElements) do if el and el.Show then el:Show() end end
            for _, btn in ipairs(self.teleportButtons) do if btn and btn.Show then btn:Show() end end
            if self.RefreshTeleports then self:RefreshTeleports() end
        elseif tabName == "timer" then
            ActivateTab(self.timerTab)
            for _, el in pairs(self.timerElements) do if el and el.Show then el:Show() end end
            if self.RefreshTimer then self:RefreshTimer() end
        elseif tabName == "bis" then
            ActivateTab(self.bisTab)
            for _, el in pairs(self.bisElements) do if el and el.Show then el:Show() end end
            if self.RefreshBis then self:RefreshBis() end
        elseif tabName == "meter" then
            ActivateTab(self.meterTab)
            for _, el in pairs(self.meterElements) do if el and el.Show then el:Show() end end
            if self.RefreshMeter then self:RefreshMeter() end
        elseif tabName == "uitweaks" then
            ActivateTab(self.uitweaksTab)
            for _, el in pairs(self.uitweaksElements) do if el and el.Show then el:Show() end end
            if self.RefreshUITweaks then self:RefreshUITweaks() end
        else
            ActivateTab(self.blacklistTab)
            for _, el in pairs(self.blacklistElements) do if el and el.Show then el:Show() end end
            if self.RefreshBlacklist then self:RefreshBlacklist() end
        end
    end
    
    -- Tab click handlers
    f.groupTab:SetScript("OnClick", function() f:SwitchTab("group") end)
    f.teleportTab:SetScript("OnClick", function() f:SwitchTab("teleport") end)
    f.timerTab:SetScript("OnClick", function() f:SwitchTab("timer") end)
    f.bisTab:SetScript("OnClick", function() f:SwitchTab("bis") end)
    f.meterTab:SetScript("OnClick", function() f:SwitchTab("meter") end)
    f.uitweaksTab:SetScript("OnClick", function() f:SwitchTab("uitweaks") end)
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
