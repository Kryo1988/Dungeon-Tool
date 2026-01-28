-- Kryos Dungeon Tool
-- UI_MainFrame.lua - Main window and tab system

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
    
    f.currentTab = "group"
    f.groupElements = {}
    f.blacklistElements = {}
    f.teleportElements = {}
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
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_SealOfKings")
    
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
    
    -- Tab Buttons
    local function CreateTab(text, xPos)
        local tab = CreateFrame("Button", nil, f, "BackdropTemplate")
        tab:SetSize(120, 28)
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
        tab.indicator:SetSize(120, 2)
        tab.indicator:SetPoint("BOTTOM")
        tab.indicator:SetColorTexture(0.8, 0.2, 0.2, 1)
        return tab
    end
    
    f.groupTab = CreateTab("GROUP CHECK", 0)
    f.teleportTab = CreateTab("M+ TELEPORTS", 125)
    f.blacklistTab = CreateTab("BLACKLIST", 250)
    
    -- Content Area
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 0, -78)
    f.content:SetPoint("BOTTOMRIGHT", 0, 0)
    
    return f
end

-- ==================== TAB SWITCHING ====================
function KDT:SetupTabSwitching(f)
    local function ShowElements(elements)
        for _, el in pairs(elements) do
            if el.Show then el:Show() end
        end
    end
    
    local function HideElements(elements)
        for _, el in pairs(elements) do
            if el.Hide then el:Hide() end
        end
    end
    
    local function HideTeleportButtons()
        for _, btn in ipairs(f.teleportButtons) do
            if btn.Hide then btn:Hide() end
        end
    end
    
    local function ShowTeleportButtons()
        for _, btn in ipairs(f.teleportButtons) do
            if btn.Show then btn:Show() end
        end
    end
    
    local function ResetTabs()
        f.groupTab:SetBackdropColor(0.08, 0.08, 0.10, 1)
        f.groupTab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
        f.groupTab.text:SetTextColor(0.5, 0.5, 0.5)
        f.groupTab.indicator:Hide()
        
        f.teleportTab:SetBackdropColor(0.08, 0.08, 0.10, 1)
        f.teleportTab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
        f.teleportTab.text:SetTextColor(0.5, 0.5, 0.5)
        f.teleportTab.indicator:Hide()
        
        f.blacklistTab:SetBackdropColor(0.08, 0.08, 0.10, 1)
        f.blacklistTab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
        f.blacklistTab.text:SetTextColor(0.5, 0.5, 0.5)
        f.blacklistTab.indicator:Hide()
    end
    
    local function ActivateTab(tab)
        tab:SetBackdropColor(0.15, 0.15, 0.18, 1)
        tab:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        tab.text:SetTextColor(1, 1, 1)
        tab.indicator:Show()
    end
    
    function f:SwitchTab(tabName)
        self.currentTab = tabName
        ResetTabs()
        HideElements(self.groupElements)
        HideElements(self.blacklistElements)
        HideElements(self.teleportElements)
        HideTeleportButtons()
        
        if tabName == "group" then
            ActivateTab(self.groupTab)
            ShowElements(self.groupElements)
            self:RefreshGroup()
        elseif tabName == "teleport" then
            ActivateTab(self.teleportTab)
            ShowElements(self.teleportElements)
            ShowTeleportButtons()
            self:RefreshTeleports()
        else
            ActivateTab(self.blacklistTab)
            ShowElements(self.blacklistElements)
            self:RefreshBlacklist()
        end
    end
    
    -- Tab click handlers
    f.groupTab:SetScript("OnClick", function() f:SwitchTab("group") end)
    f.teleportTab:SetScript("OnClick", function() f:SwitchTab("teleport") end)
    f.blacklistTab:SetScript("OnClick", function() f:SwitchTab("blacklist") end)
end
