-- Kryos Dungeon Tool
-- UI/MeterTab.lua - Meter settings tab in main window

local addonName, KDT = ...
local Meter = KDT.Meter

-- ==================== METER TAB ELEMENTS ====================
function KDT:CreateMeterElements(f)
    local e = f.meterElements
    local c = f.content
    
    -- Enable/Disable Box
    local enableBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    enableBox:SetPoint("TOPLEFT", 10, -5)
    enableBox:SetPoint("TOPRIGHT", -10, -5)
    enableBox:SetHeight(85)
    enableBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    enableBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    enableBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    e.enableBox = enableBox
    
    -- Title
    local title = enableBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("DAMAGE / HEAL METER")
    title:SetTextColor(0.8, 0.8, 0.8)
    
    -- Enable checkbox - controls visibility of windows
    e.enableCheck = CreateFrame("CheckButton", nil, enableBox, "UICheckButtonTemplate")
    e.enableCheck:SetSize(24, 24)
    e.enableCheck:SetPoint("TOPLEFT", 10, -28)
    e.enableCheck.Text:SetText("Enable DMG Meter")
    e.enableCheck.Text:SetFontObject("GameFontNormal")
    e.enableCheck:SetChecked(Meter.enabled)
    e.enableCheck:SetScript("OnClick", function(self)
        local enabled = self:GetChecked()
        Meter:SetEnabled(enabled)
    end)
    -- Update checkbox when tab is shown (in case Meter.enabled changed)
    enableBox:SetScript("OnShow", function()
        e.enableCheck:SetChecked(Meter.enabled)
    end)
    
    -- Row of buttons: Show Window, New Window, Reset Data
    e.showWindowBtn = self:CreateButton(enableBox, "Show Window", 100, 24)
    e.showWindowBtn:SetPoint("TOPLEFT", e.enableCheck, "BOTTOMLEFT", 0, -8)
    e.showWindowBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
    e.showWindowBtn:SetScript("OnClick", function()
        Meter:ToggleWindow(1)
    end)
    e.showWindowBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.55, 0.2, 1) end)
    e.showWindowBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.45, 0.15, 1) end)
    
    e.newWindowBtn = self:CreateButton(enableBox, "New Window", 100, 24)
    e.newWindowBtn:SetPoint("LEFT", e.showWindowBtn, "RIGHT", 10, 0)
    e.newWindowBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.newWindowBtn:SetScript("OnClick", function()
        local id = #Meter.windows + 1
        local window = Meter:CreateWindow(id)
        window:Show()
        KDT:Print("Created new DMG Meter window #" .. id)
    end)
    e.newWindowBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.45, 0.7, 1) end)
    e.newWindowBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.35, 0.6, 1) end)
    
    e.clearBtn = self:CreateButton(enableBox, "Clear", 100, 24)
    e.clearBtn:SetPoint("LEFT", e.newWindowBtn, "RIGHT", 10, 0)
    e.clearBtn:SetBackdropColor(0.6, 0.15, 0.15, 1)
    e.clearBtn:SetScript("OnClick", function(btn)
        -- Toggle dropdown
        if e.clearDropdown and e.clearDropdown:IsShown() then
            e.clearDropdown:Hide()
            return
        end
        
        if e.clearDropdown then e.clearDropdown:Hide() end
        
        local dropdown = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        dropdown:SetSize(120, 52)
        dropdown:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        dropdown:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        dropdown:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
        dropdown:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
        e.clearDropdown = dropdown
        
        local items = {
            {name = "Clear Current", fn = function()
                Meter:ClearCurrent()
                KDT:Print("Current segment cleared")
            end},
            {name = "Clear All", fn = function()
                Meter:ResetAll()
                KDT:Print("All meter data cleared")
            end},
        }
        
        for i, item in ipairs(items) do
            local itemBtn = CreateFrame("Button", nil, dropdown)
            itemBtn:SetSize(116, 22)
            itemBtn:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 24)
            
            local hl = itemBtn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(0.3, 0.3, 0.4, 0.5)
            
            local txt = itemBtn:CreateFontString(nil, "OVERLAY")
            txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            txt:SetPoint("LEFT", 6, 0)
            txt:SetText(item.name)
            txt:SetTextColor(0.9, 0.9, 0.9)
            
            itemBtn:SetScript("OnClick", function()
                item.fn()
                dropdown:Hide()
                e.clearDropdown = nil
            end)
        end
        
        -- Auto-close when mouse leaves
        dropdown:SetScript("OnUpdate", function(frame)
            if not frame:IsMouseOver() and not btn:IsMouseOver() then
                C_Timer.After(0.5, function()
                    if frame and frame:IsShown() and not frame:IsMouseOver() then
                        frame:Hide()
                        e.clearDropdown = nil
                    end
                end)
            end
        end)
    end)
    e.clearBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.2, 0.2, 1) end)
    e.clearBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.6, 0.15, 0.15, 1) end)
    
    -- ==================== DISPLAY SETTINGS BOX ====================
    local displayBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    displayBox:SetPoint("TOPLEFT", enableBox, "BOTTOMLEFT", 0, -10)
    displayBox:SetPoint("TOPRIGHT", enableBox, "BOTTOMRIGHT", 0, -10)
    displayBox:SetHeight(230)
    displayBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    displayBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    displayBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    e.displayBox = displayBox
    
    local displayTitle = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayTitle:SetPoint("TOPLEFT", 10, -8)
    displayTitle:SetText("DISPLAY SETTINGS")
    displayTitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Bar Height Slider
    local barHeightLabel = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    barHeightLabel:SetPoint("TOPLEFT", 10, -32)
    barHeightLabel:SetText("Bar Height:")
    barHeightLabel:SetTextColor(0.6, 0.6, 0.6)
    
    e.barHeightSlider = CreateFrame("Slider", nil, displayBox, "OptionsSliderTemplate")
    e.barHeightSlider:SetSize(150, 16)
    e.barHeightSlider:SetPoint("LEFT", barHeightLabel, "RIGHT", 20, 0)
    e.barHeightSlider:SetMinMaxValues(12, 30)
    e.barHeightSlider:SetValueStep(1)
    e.barHeightSlider:SetObeyStepOnDrag(true)
    e.barHeightSlider:SetValue(Meter.defaults.barHeight)
    e.barHeightSlider.Low:SetText("12")
    e.barHeightSlider.High:SetText("30")
    e.barHeightSlider.Text:SetText(Meter.defaults.barHeight)
    e.barHeightSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.Text:SetText(value)
        Meter.defaults.barHeight = value
        for _, window in pairs(Meter.windows) do
            window.settings.barHeight = value
            window:UpdateBars()
        end
    end)
    
    -- Font Size Slider
    local fontSizeLabel = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontSizeLabel:SetPoint("TOPLEFT", barHeightLabel, "BOTTOMLEFT", 0, -20)
    fontSizeLabel:SetText("Font Size:")
    fontSizeLabel:SetTextColor(0.6, 0.6, 0.6)
    
    e.fontSizeSlider = CreateFrame("Slider", nil, displayBox, "OptionsSliderTemplate")
    e.fontSizeSlider:SetSize(150, 16)
    e.fontSizeSlider:SetPoint("LEFT", fontSizeLabel, "RIGHT", 20, 0)
    e.fontSizeSlider:SetMinMaxValues(8, 16)
    e.fontSizeSlider:SetValueStep(1)
    e.fontSizeSlider:SetObeyStepOnDrag(true)
    e.fontSizeSlider:SetValue(Meter.defaults.fontSize)
    e.fontSizeSlider.Low:SetText("8")
    e.fontSizeSlider.High:SetText("16")
    e.fontSizeSlider.Text:SetText(Meter.defaults.fontSize)
    e.fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.Text:SetText(value)
        Meter.defaults.fontSize = value
    end)
    
    -- Max Bars Slider
    local maxBarsLabel = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxBarsLabel:SetPoint("TOPLEFT", fontSizeLabel, "BOTTOMLEFT", 0, -20)
    maxBarsLabel:SetText("Max Bars:")
    maxBarsLabel:SetTextColor(0.6, 0.6, 0.6)
    
    e.maxBarsSlider = CreateFrame("Slider", nil, displayBox, "OptionsSliderTemplate")
    e.maxBarsSlider:SetSize(150, 16)
    e.maxBarsSlider:SetPoint("LEFT", maxBarsLabel, "RIGHT", 20, 0)
    e.maxBarsSlider:SetMinMaxValues(5, 20)
    e.maxBarsSlider:SetValueStep(1)
    e.maxBarsSlider:SetObeyStepOnDrag(true)
    e.maxBarsSlider:SetValue(Meter.defaults.maxBars)
    e.maxBarsSlider.Low:SetText("5")
    e.maxBarsSlider.High:SetText("20")
    e.maxBarsSlider.Text:SetText(Meter.defaults.maxBars)
    e.maxBarsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.Text:SetText(value)
        Meter.defaults.maxBars = value
    end)
    
    -- Transparency Slider
    local transparencyLabel = displayBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    transparencyLabel:SetPoint("TOPLEFT", maxBarsLabel, "BOTTOMLEFT", 0, -20)
    transparencyLabel:SetText("Transparency:")
    transparencyLabel:SetTextColor(0.6, 0.6, 0.6)
    
    local currentAlpha = Meter.defaults.bgColor[4] or 0.9
    e.transparencySlider = CreateFrame("Slider", nil, displayBox, "OptionsSliderTemplate")
    e.transparencySlider:SetSize(150, 16)
    e.transparencySlider:SetPoint("LEFT", transparencyLabel, "RIGHT", 10, 0)
    e.transparencySlider:SetMinMaxValues(0.1, 1.0)
    e.transparencySlider:SetValueStep(0.05)
    e.transparencySlider:SetObeyStepOnDrag(true)
    e.transparencySlider:SetValue(currentAlpha)
    e.transparencySlider.Low:SetText("10%")
    e.transparencySlider.High:SetText("100%")
    e.transparencySlider.Text:SetText(math.floor(currentAlpha * 100) .. "%")
    e.transparencySlider:SetScript("OnValueChanged", function(self, value)
        local pct = math.floor(value * 100)
        self.Text:SetText(pct .. "%")
        Meter.defaults.bgColor[4] = value
        -- Update all windows
        for _, window in pairs(Meter.windows) do
            window.settings.bgColor[4] = value
            if window.frame then
                local bg = window.settings.bgColor
                window.frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
            end
        end
        -- Save to DB
        if KDT.DB then
            KDT.DB.meter = KDT.DB.meter or {}
            KDT.DB.meter.transparency = value
        end
    end)
    
    -- Checkboxes for display options
    e.showRankCheck = CreateFrame("CheckButton", nil, displayBox, "UICheckButtonTemplate")
    e.showRankCheck:SetSize(20, 20)
    e.showRankCheck:SetPoint("TOPLEFT", transparencyLabel, "BOTTOMLEFT", 0, -15)
    e.showRankCheck.Text:SetText("Show Rank")
    e.showRankCheck.Text:SetFontObject("GameFontNormalSmall")
    e.showRankCheck:SetChecked(Meter.defaults.showRank)
    e.showRankCheck:SetScript("OnClick", function(self)
        Meter.defaults.showRank = self:GetChecked()
        if KDT.DB then
            KDT.DB.meter = KDT.DB.meter or {}
            KDT.DB.meter.showRank = self:GetChecked()
        end
        Meter:RefreshAllWindows()
    end)
    
    e.showPercentCheck = CreateFrame("CheckButton", nil, displayBox, "UICheckButtonTemplate")
    e.showPercentCheck:SetSize(20, 20)
    e.showPercentCheck:SetPoint("LEFT", e.showRankCheck, "RIGHT", 80, 0)
    e.showPercentCheck.Text:SetText("Show Percent")
    e.showPercentCheck.Text:SetFontObject("GameFontNormalSmall")
    e.showPercentCheck:SetChecked(Meter.defaults.showPercent)
    e.showPercentCheck:SetScript("OnClick", function(self)
        Meter.defaults.showPercent = self:GetChecked()
        if KDT.DB then
            KDT.DB.meter = KDT.DB.meter or {}
            KDT.DB.meter.showPercent = self:GetChecked()
        end
        Meter:RefreshAllWindows()
    end)
    
    e.classColorsCheck = CreateFrame("CheckButton", nil, displayBox, "UICheckButtonTemplate")
    e.classColorsCheck:SetSize(20, 20)
    e.classColorsCheck:SetPoint("LEFT", e.showPercentCheck, "RIGHT", 80, 0)
    e.classColorsCheck.Text:SetText("Class Colors")
    e.classColorsCheck.Text:SetFontObject("GameFontNormalSmall")
    e.classColorsCheck:SetChecked(Meter.defaults.classColors)
    e.classColorsCheck:SetScript("OnClick", function(self)
        Meter.defaults.classColors = self:GetChecked()
        if KDT.DB then
            KDT.DB.meter = KDT.DB.meter or {}
            KDT.DB.meter.classColors = self:GetChecked()
        end
        Meter:RefreshAllWindows()
    end)
    
    -- "Always Show Self at Top" checkbox
    e.showSelfTopCheck = CreateFrame("CheckButton", nil, displayBox, "UICheckButtonTemplate")
    e.showSelfTopCheck:SetSize(20, 20)
    e.showSelfTopCheck:SetPoint("TOPLEFT", e.showRankCheck, "BOTTOMLEFT", 0, -5)
    e.showSelfTopCheck.Text:SetText("Always Show Self at Top")
    e.showSelfTopCheck.Text:SetFontObject("GameFontNormalSmall")
    local showSelfTop = KDT.DB and KDT.DB.meter and KDT.DB.meter.showSelfTop or false
    Meter.defaults.showSelfTop = showSelfTop
    e.showSelfTopCheck:SetChecked(showSelfTop)
    e.showSelfTopCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        Meter.defaults.showSelfTop = checked
        if KDT.DB then
            KDT.DB.meter = KDT.DB.meter or {}
            KDT.DB.meter.showSelfTop = checked
        end
        Meter:RefreshAllWindows()
    end)
    
    -- "Clear on Instance Enter" checkbox
    e.clearOnEnterCheck = CreateFrame("CheckButton", nil, displayBox, "UICheckButtonTemplate")
    e.clearOnEnterCheck:SetSize(20, 20)
    e.clearOnEnterCheck:SetPoint("LEFT", e.showSelfTopCheck, "RIGHT", 140, 0)
    e.clearOnEnterCheck.Text:SetText("Clear on Instance Enter")
    e.clearOnEnterCheck.Text:SetFontObject("GameFontNormalSmall")
    local clearOnEnter = KDT.DB and KDT.DB.meter and KDT.DB.meter.clearOnEnter or false
    Meter.defaults.clearOnEnter = clearOnEnter
    e.clearOnEnterCheck:SetChecked(clearOnEnter)
    e.clearOnEnterCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        Meter.defaults.clearOnEnter = checked
        if KDT.DB then
            KDT.DB.meter = KDT.DB.meter or {}
            KDT.DB.meter.clearOnEnter = checked
        end
    end)
    e.clearOnEnterCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Clear all meter data when entering a new dungeon or raid", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    e.clearOnEnterCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- ==================== MODE SHORTCUTS BOX ====================
    local modeBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    modeBox:SetPoint("TOPLEFT", displayBox, "BOTTOMLEFT", 0, -10)
    modeBox:SetPoint("TOPRIGHT", displayBox, "BOTTOMRIGHT", 0, -10)
    modeBox:SetHeight(130)
    modeBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    modeBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    modeBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    e.modeBox = modeBox
    
    local modeTitle = modeBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeTitle:SetPoint("TOPLEFT", 10, -8)
    modeTitle:SetText("MODE SHORTCUTS")
    modeTitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create buttons for each mode
    local modeButtons = {}
    local modes = {
        {mode = Meter.MODES.DAMAGE, name = "Damage", color = {0.8, 0.2, 0.2}},
        {mode = Meter.MODES.HEALING, name = "Healing", color = {0.2, 0.8, 0.2}},
        {mode = Meter.MODES.DPS, name = "DPS", color = {0.8, 0.4, 0.2}},
        {mode = Meter.MODES.HPS, name = "HPS", color = {0.4, 0.8, 0.4}},
        {mode = Meter.MODES.ABSORBS, name = "Absorbs", color = {0.6, 0.8, 1.0}},
        {mode = Meter.MODES.INTERRUPTS, name = "Interrupts", color = {0.2, 0.6, 0.8}},
        {mode = Meter.MODES.DISPELS, name = "Dispels", color = {0.8, 0.6, 1.0}},
        {mode = Meter.MODES.DEATHS, name = "Deaths", color = {0.5, 0.5, 0.5}},
        {mode = Meter.MODES.DAMAGE_TAKEN, name = "Dmg Taken", color = {0.6, 0.3, 0.6}},
    }
    
    for i, modeData in ipairs(modes) do
        local btn = self:CreateButton(modeBox, modeData.name, 85, 22)
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        btn:SetPoint("TOPLEFT", 10 + col * 95, -30 - row * 30)
        btn:SetBackdropColor(modeData.color[1] * 0.5, modeData.color[2] * 0.5, modeData.color[3] * 0.5, 1)
        btn:SetScript("OnClick", function()
            -- Set mode on ALL visible windows
            local anyVisible = false
            for _, window in pairs(Meter.windows) do
                if window.frame and window.frame:IsShown() then
                    window:SetMode(modeData.mode)
                    anyVisible = true
                end
            end
            -- If no windows visible, create/show window 1
            if not anyVisible then
                local window = Meter:GetWindow(1)
                if not window then
                    window = Meter:CreateWindow(1)
                end
                window:SetMode(modeData.mode)
                window:Show()
            end
        end)
        btn:SetScript("OnEnter", function(self) 
            self:SetBackdropColor(modeData.color[1] * 0.7, modeData.color[2] * 0.7, modeData.color[3] * 0.7, 1) 
        end)
        btn:SetScript("OnLeave", function(self) 
            self:SetBackdropColor(modeData.color[1] * 0.5, modeData.color[2] * 0.5, modeData.color[3] * 0.5, 1) 
        end)
        modeButtons[i] = btn
    end
    e.modeButtons = modeButtons
    
    -- ==================== INFO BOX ====================
    local infoBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", modeBox, "BOTTOMLEFT", 0, -10)
    infoBox:SetPoint("TOPRIGHT", modeBox, "BOTTOMRIGHT", 0, -10)
    infoBox:SetPoint("BOTTOM", c, "BOTTOM", 0, 10)
    infoBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    infoBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    infoBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    e.infoBox = infoBox
    
    local infoTitle = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoTitle:SetPoint("TOPLEFT", 10, -8)
    infoTitle:SetText("USAGE")
    infoTitle:SetTextColor(0.8, 0.8, 0.8)
    
    local infoText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 10, -28)
    infoText:SetPoint("RIGHT", -10, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetJustifyV("TOP")
    infoText:SetTextColor(0.6, 0.6, 0.6)
    infoText:SetText([[
|cFFFFD100Commands:|r
/kdt meter - Toggle meter window
/kdt meter reset - Clear all data

|cFFFFD100Window Controls:|r
• Drag title bar to move
• Drag corner to resize
• Click mode label to toggle (Damage<->DPS)
• Right-click for context menu
• Hover for Clear/Report/Overall buttons]])
end

-- ==================== SETUP METER REFRESH ====================
function KDT:SetupMeterRefresh(f)
    -- Meter tab doesn't need periodic refresh
    -- Windows refresh themselves via timer in Meter module
end
