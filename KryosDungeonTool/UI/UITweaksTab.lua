-- Kryos Dungeon Tool  
-- UI/UITweaksTab.lua - UI Tweaks Tab (Custom Dropdowns, English, Fixed Positions)

local addonName, KDT = ...

-- Helper function to create collapsible section
local function CreateCollapsibleSection(parent, title, yOffset)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetHeight(32)
    section:SetPoint("TOPLEFT", 15, yOffset)
    section:SetPoint("TOPRIGHT", -15, yOffset)
    section:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    section:SetBackdropColor(0.08, 0.08, 0.10, 1)
    section:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    section.isExpanded = false
    
    section:EnableMouse(true)
    section:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.10, 0.12, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    section:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.10, 1)
        self:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    end)
    
    section.icon = section:CreateFontString(nil, "OVERLAY")
    section.icon:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    section.icon:SetPoint("LEFT", 12, 0)
    section.icon:SetText("+")
    section.icon:SetTextColor(0.8, 0.2, 0.2)
    
    section.title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    section.title:SetPoint("LEFT", 38, 0)
    section.title:SetText(title)
    section.title:SetTextColor(1, 1, 1)
    
    section.content = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section.content:SetPoint("TOPLEFT", section, "BOTTOMLEFT", 0, -2)
    section.content:SetPoint("TOPRIGHT", section, "BOTTOMRIGHT", 0, -2)
    section.content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    section.content:SetBackdropColor(0.03, 0.03, 0.05, 0.95)
    section.content:SetBackdropBorderColor(0.15, 0.15, 0.20, 1)
    section.content:Hide()
    
    -- Hook OnShow to prevent content from showing when section is collapsed
    section.content:HookScript("OnShow", function(self)
        if not section.isExpanded then
            self:Hide()
        end
    end)
    
    section:SetScript("OnMouseDown", function(self)
        self.isExpanded = not self.isExpanded
        if self.isExpanded then
            self.icon:SetText("-")
            self.content:Show()
        else
            self.icon:SetText("+")
            self.content:Hide()
        end
    end)
    
    return section
end

-- Helper: CUSTOM Dropdown (Simple v arrow)
local function CreateCustomDropdown(parent, label, options, configKey, yOffset, updateCallback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(38)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, -8)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    local dropdownBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdownBtn:SetPoint("TOPRIGHT", 0, 0)
    dropdownBtn:SetSize(200, 28)
    dropdownBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    
    dropdownBtn.text = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownBtn.text:SetPoint("LEFT", 8, 0)
    dropdownBtn.text:SetPoint("RIGHT", -20, 0)
    dropdownBtn.text:SetJustifyH("LEFT")
    dropdownBtn.text:SetTextColor(1, 1, 1)
    
    dropdownBtn.arrow = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownBtn.arrow:SetPoint("RIGHT", -6, 0)
    dropdownBtn.arrow:SetText("v")
    dropdownBtn.arrow:SetTextColor(0.6, 0.6, 0.6)
    
    dropdownBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    dropdownBtn:SetScript("OnLeave", function(self)
        if not self.menu or not self.menu:IsShown() then
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        end
    end)
    
    local menu = CreateFrame("Frame", nil, dropdownBtn, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, -2)
    menu:SetPoint("TOPRIGHT", dropdownBtn, "BOTTOMRIGHT", 0, -2)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    menu:SetBackdropColor(0.10, 0.10, 0.12, 1)
    menu:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(dropdownBtn:GetFrameLevel() + 10)
    menu:Hide()
    dropdownBtn.menu = menu
    
    menu.buttons = {}
    
    local function BuildMenu()
        for _, btn in ipairs(menu.buttons) do
            btn:Hide()
        end
        wipe(menu.buttons)
        
        local yPos = -2
        for i, option in ipairs(options) do
            local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
            btn:SetPoint("TOPLEFT", 2, yPos)
            btn:SetPoint("TOPRIGHT", -2, yPos)
            btn:SetHeight(24)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8"
            })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetText(option)
            btn.text:SetTextColor(1, 1, 1)
            
            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.8, 0.2, 0.2, 0.3)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)
            btn:SetScript("OnClick", function(self)
                KDT.MouseCursor:SetConfig(configKey, option)
                dropdownBtn.text:SetText(option)
                menu:Hide()
                if updateCallback then updateCallback() end
                KDT.MouseCursor:ApplySettings()
            end)
            
            btn:Show()
            menu.buttons[i] = btn
            yPos = yPos - 24
        end
        
        menu:SetHeight(math.abs(yPos) + 2)
    end
    
    dropdownBtn:SetScript("OnClick", function(self)
        if menu:IsShown() then
            menu:Hide()
        else
            BuildMenu()
            menu:Show()
        end
    end)
    
    menu:SetScript("OnHide", function(self)
        dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)
    
    local currentValue = KDT.MouseCursor:GetConfig(configKey)
    dropdownBtn.text:SetText(currentValue or options[1])
    
    return container, yOffset - 43
end

-- Helper: Slider
local function CreateSlider(parent, label, min, max, step, configKey, yOffset, updateCallback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(45)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, -8)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPRIGHT", -60, -5)
    slider:SetWidth(220)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:GetThumbTexture():SetSize(12, 24)
    
    local value = KDT.MouseCursor:GetConfig(configKey)
    slider:SetValue(value or min)
    
    local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueLabel:SetPoint("RIGHT", 0, -5)
    valueLabel:SetText(string.format("%.2f", value or min))
    valueLabel:SetTextColor(1, 0.82, 0)
    
    slider:SetScript("OnValueChanged", function(self, val)
        val = tonumber(string.format("%.2f", val))
        valueLabel:SetText(string.format("%.2f", val))
        KDT.MouseCursor:SetConfig(configKey, val)
        if updateCallback then updateCallback() end
        KDT.MouseCursor:ApplySettings()
    end)
    
    return container, yOffset - 50
end

-- Helper: Checkbox (Fixed spacing)
local function CreateCheckbox(parent, label, configKey, yOffset, updateCallback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(30)
    
    local cb = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", 0, 0)
    cb:SetSize(24, 24)
    cb:SetChecked(KDT.MouseCursor:GetConfig(configKey))
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    cb:SetScript("OnClick", function(self)
        KDT.MouseCursor:SetConfig(configKey, self:GetChecked())
        if updateCallback then updateCallback() end
        KDT.MouseCursor:ApplySettings()
    end)
    
    return container, yOffset - 40
end

-- Helper: Color Picker (Fixed position)
local function CreateColorPicker(parent, label, colorModeKey, customColorKey, yOffset, updateCallback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(38)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, -8)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    local dropdownBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdownBtn:SetPoint("TOPRIGHT", -32, 0)
    dropdownBtn:SetSize(168, 28)
    dropdownBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    
    dropdownBtn.text = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownBtn.text:SetPoint("LEFT", 8, 0)
    dropdownBtn.text:SetPoint("RIGHT", -20, 0)
    dropdownBtn.text:SetJustifyH("LEFT")
    dropdownBtn.text:SetTextColor(1, 1, 1)
    
    dropdownBtn.arrow = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownBtn.arrow:SetPoint("RIGHT", -6, 0)
    dropdownBtn.arrow:SetText("v")
    dropdownBtn.arrow:SetTextColor(0.6, 0.6, 0.6)
    
    local colorBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
    colorBtn:SetSize(28, 28)
    colorBtn:SetPoint("TOPRIGHT", 0, 0)
    colorBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    
    local swatch = colorBtn:CreateTexture(nil, "OVERLAY")
    swatch:SetPoint("TOPLEFT", 2, -2)
    swatch:SetPoint("BOTTOMRIGHT", -2, 2)
    swatch:SetColorTexture(1, 1, 1)
    colorBtn.swatch = swatch
    
    local function UpdateColorButton()
        local mode = KDT.MouseCursor:GetConfig(colorModeKey)
        local c = KDT.MouseCursor:GetConfig(customColorKey)
        if c then
            swatch:SetVertexColor(c.r, c.g, c.b)
        end
        
        if mode == "custom" then
            colorBtn:Enable()
            colorBtn:SetAlpha(1.0)
            colorBtn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        else
            colorBtn:Disable()
            colorBtn:SetAlpha(0.5)
            colorBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end
    
    dropdownBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    dropdownBtn:SetScript("OnLeave", function(self)
        if not self.menu or not self.menu:IsShown() then
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        end
    end)
    
    local menu = CreateFrame("Frame", nil, dropdownBtn, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, -2)
    menu:SetPoint("TOPRIGHT", dropdownBtn, "BOTTOMRIGHT", 0, -2)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    menu:SetBackdropColor(0.10, 0.10, 0.12, 1)
    menu:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(dropdownBtn:GetFrameLevel() + 10)
    menu:Hide()
    dropdownBtn.menu = menu
    
    local options = {
        {text = "Default", value = "default"},
        {text = "Class Color", value = "class"},
        {text = "Custom Color", value = "custom"}
    }
    
    local function BuildMenu()
        local yPos = -2
        for i, option in ipairs(options) do
            if not menu["btn" .. i] then
                local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
                btn:SetPoint("TOPLEFT", 2, yPos)
                btn:SetPoint("TOPRIGHT", -2, yPos)
                btn:SetHeight(24)
                btn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8"
                })
                btn:SetBackdropColor(0, 0, 0, 0)
                
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                btn.text:SetPoint("LEFT", 8, 0)
                btn.text:SetJustifyH("LEFT")
                btn.text:SetText(option.text)
                btn.text:SetTextColor(1, 1, 1)
                
                btn:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.8, 0.2, 0.2, 0.3)
                end)
                btn:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)
                btn:SetScript("OnClick", function(self)
                    KDT.MouseCursor:SetConfig(colorModeKey, option.value)
                    dropdownBtn.text:SetText(option.text)
                    menu:Hide()
                    UpdateColorButton()
                    if updateCallback then updateCallback() end
                    KDT.MouseCursor:ApplySettings()
                end)
                
                menu["btn" .. i] = btn
            end
            yPos = yPos - 24
        end
        menu:SetHeight(math.abs(yPos) + 2)
    end
    
    dropdownBtn:SetScript("OnClick", function(self)
        if menu:IsShown() then
            menu:Hide()
        else
            BuildMenu()
            menu:Show()
        end
    end)
    
    menu:SetScript("OnHide", function(self)
        dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)
    
    colorBtn:SetScript("OnClick", function()
        local c = KDT.MouseCursor:GetConfig(customColorKey)
        local r, g, b = 1, 1, 1
        if c then
            r, g, b = c.r, c.g, c.b
        end
        
        local info = {
            r = r, g = g, b = b,
            hasOpacity = false,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                KDT.MouseCursor:SetConfig(customColorKey, {r = newR, g = newG, b = newB})
                UpdateColorButton()
                if updateCallback then updateCallback() end
                KDT.MouseCursor:ApplySettings()
            end,
            cancelFunc = function()
                KDT.MouseCursor:SetConfig(customColorKey, {r = r, g = g, b = b})
                UpdateColorButton()
                if updateCallback then updateCallback() end
                KDT.MouseCursor:ApplySettings()
            end,
        }
        
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    local currentMode = KDT.MouseCursor:GetConfig(colorModeKey) or "default"
    local modeText = currentMode == "default" and "Default" or 
                    currentMode == "class" and "Class Color" or "Custom Color"
    dropdownBtn.text:SetText(modeText)
    UpdateColorButton()
    
    return container, yOffset - 43
end

-- Helper: Separator
local function CreateSeparator(parent, yOffset)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.25, 0.25, 0.30, 0.6)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 15, yOffset)
    sep:SetPoint("TOPRIGHT", -15, yOffset)
    return sep, yOffset - 10
end

-- Helper: Section Header
local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 15, yOffset)
    header:SetText(text)
    header:SetTextColor(1, 0.82, 0)
    return header, yOffset - 30
end

-- Helper: QoL Checkbox (uses KDT.DB.qol)
local function CreateQoLCheckbox(parent, label, configKey, yOffset, description)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(description and 45 or 30)
    
    local cb = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", 0, description and 5 or 0)
    cb:SetSize(24, 24)
    
    local qol = KDT.DB and KDT.DB.qol
    cb:SetChecked(qol and qol[configKey] or false)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    if description then
        local descText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descText:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 32, 2)
        descText:SetText(description)
        descText:SetTextColor(0.5, 0.5, 0.5)
    end
    
    cb:SetScript("OnClick", function(self)
        if KDT.DB and KDT.DB.qol then
            KDT.DB.qol[configKey] = self:GetChecked()
        end
    end)
    
    return container, yOffset - (description and 50 or 35)
end

-- Helper: QoL Dropdown (uses KDT.DB.qol)
local function CreateQoLDropdown(parent, label, options, configKey, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(38)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, -8)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    local dropdownBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdownBtn:SetPoint("TOPRIGHT", 0, 0)
    dropdownBtn:SetSize(200, 28)
    dropdownBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    
    dropdownBtn.text = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownBtn.text:SetPoint("LEFT", 8, 0)
    dropdownBtn.text:SetPoint("RIGHT", -20, 0)
    dropdownBtn.text:SetJustifyH("LEFT")
    dropdownBtn.text:SetTextColor(1, 1, 1)
    
    dropdownBtn.arrow = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownBtn.arrow:SetPoint("RIGHT", -6, 0)
    dropdownBtn.arrow:SetText("v")
    dropdownBtn.arrow:SetTextColor(0.6, 0.6, 0.6)
    
    dropdownBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    dropdownBtn:SetScript("OnLeave", function(self)
        if not self.menu or not self.menu:IsShown() then
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        end
    end)
    
    local menu = CreateFrame("Frame", nil, dropdownBtn, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, -2)
    menu:SetPoint("TOPRIGHT", dropdownBtn, "BOTTOMRIGHT", 0, -2)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    menu:SetBackdropColor(0.10, 0.10, 0.12, 1)
    menu:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(dropdownBtn:GetFrameLevel() + 10)
    menu:Hide()
    dropdownBtn.menu = menu
    
    menu.buttons = {}
    
    local function BuildMenu()
        for _, btn in ipairs(menu.buttons) do btn:Hide() end
        wipe(menu.buttons)
        
        local yPos = -2
        for i, option in ipairs(options) do
            local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
            btn:SetPoint("TOPLEFT", 2, yPos)
            btn:SetPoint("TOPRIGHT", -2, yPos)
            btn:SetHeight(24)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetText(option.text)
            btn.text:SetTextColor(1, 1, 1)
            
            btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.8, 0.2, 0.2, 0.3) end)
            btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
            btn:SetScript("OnClick", function(self)
                if KDT.DB and KDT.DB.qol then
                    KDT.DB.qol[configKey] = option.value
                end
                dropdownBtn.text:SetText(option.text)
                menu:Hide()
            end)
            
            btn:Show()
            table.insert(menu.buttons, btn)
            yPos = yPos - 24
        end
        menu:SetHeight(math.abs(yPos) + 2)
    end
    
    dropdownBtn:SetScript("OnClick", function(self)
        if menu:IsShown() then
            menu:Hide()
        else
            BuildMenu()
            menu:Show()
        end
    end)
    
    menu:SetScript("OnHide", function(self)
        dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)
    
    -- Set initial text
    local currentValue = KDT.DB and KDT.DB.qol and KDT.DB.qol[configKey]
    for _, option in ipairs(options) do
        if option.value == currentValue then
            dropdownBtn.text:SetText(option.text)
            break
        end
    end
    
    return container, yOffset - 43
end

-- Create UI Tweaks tab content (now QoL tab)
function KDT:CreateUITweaksTab(frame)
    local content = frame.content
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(frame.uitweaksElements, scrollFrame)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(content:GetWidth() - 20, 2000)
    scrollFrame:SetScrollChild(scrollChild)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 40)))
        self:SetVerticalScroll(newScroll)
    end)
    
    frame:HookScript("OnSizeChanged", function(self)
        if scrollChild then
            scrollChild:SetWidth(self:GetWidth() - 20)
        end
    end)
    
    -- Track all sections for scroll height calculation
    local allSections = {}
    local sectionY = -20
    
    -- ==================== SECTION 1: SELL JUNK + AUTO REPAIR ====================
    local sellRepairSection = CreateCollapsibleSection(scrollChild, "Sell Junk & Auto Repair", sectionY)
    table.insert(frame.uitweaksElements, sellRepairSection)
    table.insert(allSections, sellRepairSection)
    
    local yPos = -20
    local _, yPos = CreateQoLCheckbox(sellRepairSection.content, "Auto Sell Junk Items", "sellJunk", yPos,
        "Automatically sells all gray quality items when visiting a merchant.")
    
    local _, yPos = CreateSeparator(sellRepairSection.content, yPos)
    
    local _, yPos = CreateQoLCheckbox(sellRepairSection.content, "Auto Repair Equipment", "autoRepairEnabled", yPos,
        "Automatically repairs all equipment when visiting a repair vendor.")
    
    local repairOptions = {
        {text = "Personal Gold", value = "personal"},
        {text = "Guild Bank", value = "guild"},
    }
    local _, yPos = CreateQoLDropdown(sellRepairSection.content, "Repair Payment:", repairOptions, "autoRepairMode", yPos)
    
    sellRepairSection.content:SetHeight(math.abs(yPos) + 20)
    sellRepairSection.content:Hide()
    
    -- ==================== SECTION 2: ROLE CHECK AUTO ACCEPT ====================
    sectionY = sectionY - 37
    local roleCheckSection = CreateCollapsibleSection(scrollChild, "Role Check Auto Accept", sectionY)
    table.insert(frame.uitweaksElements, roleCheckSection)
    table.insert(allSections, roleCheckSection)
    
    yPos = -20
    local _, yPos = CreateQoLCheckbox(roleCheckSection.content, "Auto Accept Role Check", "autoRoleAccept", yPos,
        "Automatically accepts the role check popup in dungeon finder.")
    
    local roleOptions = {
        {text = "DPS", value = "dps"},
        {text = "Healer", value = "healer"},
        {text = "Tank", value = "tank"},
    }
    local _, yPos = CreateQoLDropdown(roleCheckSection.content, "Preferred Role:", roleOptions, "autoRolePreference", yPos)
    
    roleCheckSection.content:SetHeight(math.abs(yPos) + 20)
    roleCheckSection.content:Hide()
    
    -- ==================== SECTION 3: PARTY INVITE AUTO ACCEPT ====================
    sectionY = sectionY - 37
    local partyInviteSection = CreateCollapsibleSection(scrollChild, "Party Invite Auto Accept", sectionY)
    table.insert(frame.uitweaksElements, partyInviteSection)
    table.insert(allSections, partyInviteSection)
    
    yPos = -20
    local _, yPos = CreateQoLCheckbox(partyInviteSection.content, "Auto Accept Party Invites", "autoAcceptInvites", yPos,
        "Automatically accepts all incoming party invitations.")
    
    partyInviteSection.content:SetHeight(math.abs(yPos) + 20)
    partyInviteSection.content:Hide()
    
    -- ==================== SECTION 4: QUEST AUTO ACCEPT / TURN-IN ====================
    sectionY = sectionY - 37
    local questSection = CreateCollapsibleSection(scrollChild, "Quest Auto Accept & Turn-In", sectionY)
    table.insert(frame.uitweaksElements, questSection)
    table.insert(allSections, questSection)
    
    yPos = -20
    local _, yPos = CreateQoLCheckbox(questSection.content, "Auto Accept Quests", "autoAcceptQuest", yPos,
        "Automatically accepts quests from NPCs. Hold Shift to override.")
    
    local _, yPos = CreateSeparator(questSection.content, yPos)
    
    local _, yPos = CreateQoLCheckbox(questSection.content, "Auto Turn-In Quests", "autoTurnInQuest", yPos,
        "Automatically turns in completed quests. Hold Shift to override.\nWill not auto-select if multiple rewards are available.")
    
    questSection.content:SetHeight(math.abs(yPos) + 20)
    questSection.content:Hide()
    
    -- ==================== SECTION 5: MOUSE CURSOR ====================
    sectionY = sectionY - 37
    local mouseCursorSection = CreateCollapsibleSection(scrollChild, "Mouse Cursor", sectionY)
    table.insert(frame.uitweaksElements, mouseCursorSection)
    table.insert(allSections, mouseCursorSection)
    mouseCursorSection.sectionName = "MouseCursor"
    
    yPos = -20
    
    local enableContainer, yPos = CreateCheckbox(mouseCursorSection.content, "Enable Mouse Cursor", "enabled", yPos, function()
        if KDT.MouseCursor:GetConfig("enabled") then
            KDT.MouseCursor:Initialize()
        else
            if KDT_MouseCursorFrame then
                KDT_MouseCursorFrame:Hide()
            end
        end
    end)
    
    local _, yPos = CreateSeparator(mouseCursorSection.content, yPos - 5)
    local _, yPos = CreateSectionHeader(mouseCursorSection.content, "Ring Slot Assignment", yPos)
    
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Reticle:", KDT.MouseCursor.reticleOptions, "reticle", yPos)
    local _, yPos = CreateSlider(mouseCursorSection.content, "Reticle Scale:", 0.5, 3.0, 0.1, "reticleScale", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Inner Ring:", KDT.MouseCursor.ringOptions, "innerRing", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Main Ring:", KDT.MouseCursor.ringOptions, "mainRing", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Outer Ring:", KDT.MouseCursor.ringOptions, "outerRing", yPos)
    
    local _, yPos = CreateSeparator(mouseCursorSection.content, yPos - 5)
    local _, yPos = CreateSectionHeader(mouseCursorSection.content, "Colors", yPos)
    
    local _, yPos = CreateColorPicker(mouseCursorSection.content, "Reticle Color:", "reticleColorMode", "reticleCustomColor", yPos)
    local _, yPos = CreateColorPicker(mouseCursorSection.content, "Main Ring Color:", "mainRingColorMode", "mainRingCustomColor", yPos)
    local _, yPos = CreateColorPicker(mouseCursorSection.content, "GCD Ring Color:", "gcdColorMode", "gcdCustomColor", yPos)
    local _, yPos = CreateColorPicker(mouseCursorSection.content, "Cast Ring Color:", "castColorMode", "castCustomColor", yPos)
    local _, yPos = CreateColorPicker(mouseCursorSection.content, "Health Ring Color:", "healthColorMode", "healthCustomColor", yPos)
    local _, yPos = CreateColorPicker(mouseCursorSection.content, "Power Ring Color:", "powerColorMode", "powerCustomColor", yPos)
    
    local _, yPos = CreateSeparator(mouseCursorSection.content, yPos - 5)
    local _, yPos = CreateSectionHeader(mouseCursorSection.content, "Animation Settings", yPos)
    
    local gcdFillOptions = {"fill", "drain"}
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "GCD Fill/Drain:", gcdFillOptions, "gcdFillDrain", yPos)
    
    local clockOptions = {}
    for i = 1, 12 do table.insert(clockOptions, tostring(i)) end
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "GCD Start Position (Clock):", clockOptions, "gcdRotation", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Cast Fill/Drain:", gcdFillOptions, "castFillDrain", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Cast Start Position (Clock):", clockOptions, "castRotation", yPos)
    
    local _, yPos = CreateSeparator(mouseCursorSection.content, yPos - 5)
    local _, yPos = CreateSectionHeader(mouseCursorSection.content, "General Settings", yPos)
    
    local _, yPos = CreateSlider(mouseCursorSection.content, "Overall Scale:", 0.5, 2.0, 0.1, "scale", yPos)
    local _, yPos = CreateSlider(mouseCursorSection.content, "Transparency:", 0.0, 1.0, 0.05, "transparency", yPos)
    local _, yPos = CreateCheckbox(mouseCursorSection.content, "Show Only in Combat", "showOnlyInCombat", yPos)
    
    local _, yPos = CreateSeparator(mouseCursorSection.content, yPos - 5)
    local _, yPos = CreateSectionHeader(mouseCursorSection.content, "Modifier Keys", yPos)
    
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Shift Action:", KDT.MouseCursor.modifierOptions, "shiftAction", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Ctrl Action:", KDT.MouseCursor.modifierOptions, "ctrlAction", yPos)
    local _, yPos = CreateCustomDropdown(mouseCursorSection.content, "Alt Action:", KDT.MouseCursor.modifierOptions, "altAction", yPos)
    
    local mouseCursorContentHeight = math.abs(yPos) + 20
    mouseCursorSection.content:SetHeight(mouseCursorContentHeight)
    mouseCursorSection.content:Hide()
    
    -- ==================== SCROLL HEIGHT MANAGEMENT ====================
    local function UpdateScrollHeight()
        local totalHeight = 20  -- Initial padding
        
        for _, section in ipairs(allSections) do
            totalHeight = totalHeight + 32 + 5  -- Header + spacing
            if section.isExpanded and section.content:IsShown() then
                totalHeight = totalHeight + (section.content:GetHeight() or 0) + 2
            end
        end
        
        totalHeight = totalHeight + 50  -- Bottom padding
        scrollChild:SetHeight(totalHeight)
        
        -- Reposition sections based on expanded state
        local currentY = -20
        for _, section in ipairs(allSections) do
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", 15, currentY)
            section:SetPoint("TOPRIGHT", -15, currentY)
            currentY = currentY - 32 - 5  -- Header height + spacing
            if section.isExpanded and section.content:IsShown() then
                currentY = currentY - (section.content:GetHeight() or 0) - 2
            end
        end
    end
    
    -- Set toggle handlers for all sections
    for _, section in ipairs(allSections) do
        section:SetScript("OnMouseDown", function(self)
            self.isExpanded = not self.isExpanded
            if self.isExpanded then
                self.icon:SetText("-")
                self.content:Show()
            else
                self.icon:SetText("+")
                self.content:Hide()
            end
            UpdateScrollHeight()
        end)
    end
    
    -- Initial height update
    C_Timer.After(0.1, function()
        UpdateScrollHeight()
    end)
    
    frame.RefreshUITweaks = function(self)
        UpdateScrollHeight()
    end
end
