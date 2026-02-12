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
local function CreateQoLCheckbox(parent, label, configKey, yOffset, description, onChangeCallback)
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
        descText:SetPoint("RIGHT", container, "RIGHT", -10, 0)
        descText:SetJustifyH("LEFT")
        descText:SetText(description)
        descText:SetTextColor(0.5, 0.5, 0.5)
    end
    
    cb:SetScript("OnClick", function(self)
        if KDT.DB and KDT.DB.qol then
            KDT.DB.qol[configKey] = self:GetChecked()
        end
        if onChangeCallback then
            onChangeCallback(self:GetChecked())
        end
    end)
    
    return container, yOffset - (description and 50 or 35)
end

-- Helper: QoL Slider (uses KDT.DB.qol)
local function CreateQoLSlider(parent, label, min, max, step, configKey, yOffset, description)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(description and 55 or 40)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetTextColor(0.85, 0.85, 0.85)
    
    local qol = KDT.DB and KDT.DB.qol
    local currentVal = qol and qol[configKey] or min
    
    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -16)
    slider:SetPoint("TOPRIGHT", -50, -16)
    slider:SetHeight(16)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(currentVal)
    slider.Low:SetText(tostring(min))
    slider.High:SetText(tostring(max))
    
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valueText:SetTextColor(1, 0.82, 0)
    
    labelText:SetText(label .. " " .. string.format("%.0f", currentVal))
    valueText:SetText("")
    
    if description then
        local descText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
        descText:SetPoint("RIGHT", container, "RIGHT", -10, 0)
        descText:SetJustifyH("LEFT")
        descText:SetText(description)
        descText:SetTextColor(0.5, 0.5, 0.5)
    end
    
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        if KDT.DB and KDT.DB.qol then
            KDT.DB.qol[configKey] = value
        end
        labelText:SetText(label .. " " .. string.format("%.0f", value))
    end)
    
    return container, yOffset - (description and 60 or 45)
end

local function CreateQoLDropdown(parent, label, options, configKey, yOffset, description, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 15, yOffset)
    container:SetPoint("TOPRIGHT", -15, yOffset)
    container:SetHeight(description and 55 or 40)

    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, -8)
    labelText:SetText(label)
    labelText:SetTextColor(0.85, 0.85, 0.85)

    local qol = KDT.DB and KDT.DB.qol
    local current = qol and qol[configKey] or options[1].value

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

        local menuY = -2
        for i, opt in ipairs(options) do
            local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
            btn:SetPoint("TOPLEFT", 2, menuY)
            btn:SetPoint("TOPRIGHT", -2, menuY)
            btn:SetHeight(24)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            btn:SetBackdropColor(0, 0, 0, 0)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetText(opt.text)
            btn.text:SetTextColor(1, 1, 1)

            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.8, 0.2, 0.2, 0.3)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)
            btn:SetScript("OnClick", function()
                if KDT.DB and KDT.DB.qol then KDT.DB.qol[configKey] = opt.value end
                dropdownBtn.text:SetText(opt.text)
                menu:Hide()
                if onChange then onChange(opt.value) end
            end)

            btn:Show()
            menu.buttons[i] = btn
            menuY = menuY - 24
        end

        menu:SetHeight(math.abs(menuY) + 2)
    end

    dropdownBtn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            BuildMenu()
            menu:Show()
        end
    end)

    menu:SetScript("OnHide", function()
        dropdownBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dropdownBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)

    -- Set initial display text
    for _, opt in ipairs(options) do
        if opt.value == current then dropdownBtn.text:SetText(opt.text) break end
    end

    if description then
        local descText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descText:SetPoint("TOPLEFT", 0, -35)
        descText:SetPoint("RIGHT", container, "RIGHT", -10, 0)
        descText:SetJustifyH("LEFT")
        descText:SetText(description)
        descText:SetTextColor(0.5, 0.5, 0.5)
    end

    return container, yOffset - (description and 55 or 43)
end

-- ==================== CATEGORY BUILDER FUNCTIONS ====================
-- Each builder gets its own local scope to avoid the 200 local variable limit

local function CreateEconomySections(scrollChild, frame, allSections, sectionY)
    local s, yPos
    
    -- Vendor & Repair
    s = CreateCollapsibleSection(scrollChild, "Vendor & Repair", sectionY)
    s.category = "Economy"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Sell Junk Items", "sellJunk", yPos,
        "Sells all gray items via WoW 12.0 API. Auto-accepts the confirmation popup.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto Repair Equipment", "autoRepairEnabled", yPos,
        "Automatically repairs all equipment when visiting a repair vendor.")
    _, yPos = CreateQoLDropdown(s.content, "Repair Payment:", {
        {text = "Personal Gold", value = "personal"},
        {text = "Guild Bank", value = "guild"},
    }, "autoRepairMode", yPos)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Auction House
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Auction House", sectionY)
    s.category = "Economy"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Close Bags on AH Open", "ahCloseBags", yPos,
        "Automatically closes all bags when the Auction House opens.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Persist AH Search Filters", "ahPersistFilter", yPos,
        "Remembers your AH filter settings between sessions.\nFilters are restored when you reopen the AH.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Always Current Expansion Only", "ahCurrentExpansion", yPos,
        "Automatically enables the 'Current Expansion' filter when opening the AH.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Mark Known Items
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Mark Known Items on Merchant", sectionY)
    s.category = "Economy"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Mark Known Transmog", "markKnownTransmog", yPos,
        "Highlights items on merchants that you already have the appearance for.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Mark Known Recipes", "markKnownRecipes", yPos,
        "Highlights recipes on merchants that you already know.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Mark Known Toys", "markKnownToys", yPos,
        "Highlights toys on merchants that you already own.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Mark Collected Pets", "markCollectedPets", yPos,
        "Highlights companion pets on merchants that you already have.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Gold Tracking
    sectionY = sectionY - 37
    local goldSection = CreateCollapsibleSection(scrollChild, "Gold Tracking", sectionY)
    goldSection.category = "Economy"
    table.insert(frame.uitweaksElements, goldSection)
    table.insert(allSections, goldSection)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(goldSection.content, "Enable Gold Tracking", "goldTrackingEnabled", yPos,
        "Tracks gold across all characters. Updates on login and gold changes.")
    _, yPos = CreateSeparator(goldSection.content, yPos)
    
    local goldListContainer = CreateFrame("Frame", nil, goldSection.content)
    goldListContainer:SetPoint("TOPLEFT", 15, yPos)
    goldListContainer:SetPoint("TOPRIGHT", -15, yPos)
    goldListContainer:SetHeight(20)
    
    local goldListLabel = goldListContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldListLabel:SetPoint("TOPLEFT", 0, 0)
    goldListLabel:SetText("Character Gold:")
    goldListLabel:SetTextColor(1, 0.82, 0)
    
    local goldCharRows = {}
    local goldYPos = yPos  -- capture for closure
    
    local function FormatGoldDisplay(copper)
        if not copper or copper == 0 then return "0g" end
        local gold = math.floor(copper / 10000)
        local silver = math.floor((copper % 10000) / 100)
        return string.format("|cFFFFD700%s|rg |cFFC0C0C0%d|rs", BreakUpLargeNumbers(gold), silver)
    end
    
    local function UpdateGoldDisplay()
        for _, row in ipairs(goldCharRows) do row:Hide() end
        
        local trackerData = KDT:GetGoldTrackingData()
        local sortedKeys = {}
        for k in pairs(trackerData) do table.insert(sortedKeys, k) end
        table.sort(sortedKeys)
        
        local rowY = -25
        local idx = 0
        local colors = RAID_CLASS_COLORS or {}
        
        for _, charKey in ipairs(sortedKeys) do
            local data = trackerData[charKey]
            idx = idx + 1
            local row = goldCharRows[idx]
            if not row then
                row = CreateFrame("Frame", nil, goldListContainer)
                row:SetHeight(20)
                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.name:SetPoint("LEFT", 5, 0)
                row.name:SetJustifyH("LEFT")
                row.gold = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.gold:SetPoint("RIGHT", -30, 0)
                row.gold:SetJustifyH("RIGHT")
                row.deleteBtn = CreateFrame("Button", nil, row)
                row.deleteBtn:SetSize(16, 16)
                row.deleteBtn:SetPoint("RIGHT", 0, 0)
                row.deleteBtn.tex = row.deleteBtn:CreateTexture(nil, "ARTWORK")
                row.deleteBtn.tex:SetAllPoints()
                row.deleteBtn.tex:SetTexture("Interface\\Buttons\\UI-StopButton")
                row.deleteBtn.tex:SetVertexColor(0.6, 0.2, 0.2)
                row.deleteBtn:SetScript("OnEnter", function(self)
                    self.tex:SetVertexColor(1, 0.3, 0.3)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("Remove " .. (self.charKey or "character"), 1, 1, 1)
                    GameTooltip:Show()
                end)
                row.deleteBtn:SetScript("OnLeave", function(self)
                    self.tex:SetVertexColor(0.6, 0.2, 0.2)
                    GameTooltip:Hide()
                end)
                goldCharRows[idx] = row
            end
            row:SetPoint("TOPLEFT", goldListContainer, "TOPLEFT", 0, rowY)
            row:SetPoint("TOPRIGHT", goldListContainer, "TOPRIGHT", 0, rowY)
            local cc = colors[data.class] or {r = 1, g = 1, b = 1}
            row.name:SetText(charKey)
            row.name:SetTextColor(cc.r, cc.g, cc.b)
            row.gold:SetText(FormatGoldDisplay(data.gold))
            row.deleteBtn.charKey = charKey
            row.deleteBtn:SetScript("OnClick", function(self)
                KDT:RemoveGoldTrackingChar(self.charKey)
                UpdateGoldDisplay()
            end)
            row:Show()
            rowY = rowY - 22
        end
        
        if idx > 0 then
            idx = idx + 1
            local row = goldCharRows[idx]
            if not row then
                row = CreateFrame("Frame", nil, goldListContainer)
                row:SetHeight(22)
                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.name:SetPoint("LEFT", 5, 0)
                row.gold = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.gold:SetPoint("RIGHT", -30, 0)
                row.gold:SetJustifyH("RIGHT")
                goldCharRows[idx] = row
            end
            if row.deleteBtn then row.deleteBtn:Hide() end
            row:SetPoint("TOPLEFT", goldListContainer, "TOPLEFT", 0, rowY - 5)
            row:SetPoint("TOPRIGHT", goldListContainer, "TOPRIGHT", 0, rowY - 5)
            row.name:SetText("Total")
            row.name:SetTextColor(1, 0.82, 0)
            row.gold:SetText(FormatGoldDisplay(KDT:GetGoldTrackingTotal()))
            row:Show()
            rowY = rowY - 27
        end
        
        goldListContainer:SetHeight(math.abs(rowY) + 10)
        goldSection.content:SetHeight(math.abs(goldYPos) + math.abs(rowY) + 30)
    end
    
    frame.UpdateGoldDisplay = UpdateGoldDisplay
    goldSection.content:SetHeight(math.abs(yPos) + 50)
    goldSection.content:Hide()
    goldSection._updateGoldDisplay = UpdateGoldDisplay
    
    -- Extended Merchant
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Extended Merchant", sectionY)
    s.category = "Economy"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Expand & Sell Marked Items", "extMerchantEnabled", yPos,
        "Expands the merchant vendor frame to 20 items (2x10 grid).\nShift-Click items in your bags to mark them for selling.\nA 'Sell Marked' button appears at the vendor.")
    
    local infoText = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 15, yPos - 5)
    infoText:SetPoint("TOPRIGHT", -15, yPos - 5)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("|cFF888888Requires /reload after toggling.|r")
    infoText:SetTextColor(0.6, 0.6, 0.6)
    yPos = yPos - 20
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Trade & Mail Log
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Trade & Mail Log", sectionY)
    s.category = "Economy"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Enable Trade & Mail Logging", "enableTradeMailLog", yPos,
        "Logs all trades and mails (items, gold, partners) to a persistent history.\nUp to 200 entries are stored.")
    
    local logInfoText = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    logInfoText:SetPoint("TOPLEFT", 15, yPos - 5)
    logInfoText:SetPoint("TOPRIGHT", -15, yPos - 5)
    logInfoText:SetJustifyH("LEFT")
    logInfoText:SetText("|cFF888888How it works:|r\n" ..
        "|cFFBBBBBB•|r Trades are automatically logged when completed\n" ..
        "|cFFBBBBBB•|r Sent and received mail is tracked with items & gold\n" ..
        "|cFFBBBBBB•|r Type |cFFFFD100/kdt tradelog|r to view recent entries")
    logInfoText:SetTextColor(0.6, 0.6, 0.6)
    logInfoText:SetSpacing(2)
    yPos = yPos - 75
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    return sectionY
end

local function CreateGameplaySections(scrollChild, frame, allSections, sectionY)
    local s, yPos
    
    -- Role Check
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Role Check Auto Accept", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Accept Role Check", "autoRoleAccept", yPos,
        "Automatically accepts the role check popup in dungeon finder.")
    _, yPos = CreateQoLDropdown(s.content, "Preferred Role:", {
        {text = "DPS", value = "dps"},
        {text = "Healer", value = "healer"},
        {text = "Tank", value = "tank"},
    }, "autoRolePreference", yPos)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Quest Auto Accept
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Quest Auto Accept & Turn-In", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Accept Quests", "autoAcceptQuest", yPos,
        "Automatically accepts quests from NPCs. Hold Shift to override.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto Turn-In Quests", "autoTurnInQuest", yPos,
        "Automatically turns in completed quests. Hold Shift to override.\nWill not auto-select if multiple rewards are available.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Auto Accept Resurrection
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Auto Accept Resurrection", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Accept Resurrection", "autoAcceptResurrection", yPos,
        "Automatically accepts resurrection requests from other players.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Exclude During Combat", "autoAcceptResurrectionExcludeCombat", yPos,
        "Don't auto-accept if you are in combat.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Exclude Afterlife Casters", "autoAcceptResurrectionExcludeAfterlife", yPos,
        "Don't auto-accept if the caster is dead (e.g. Druid Afterlife talent).")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Auto Release in PvP
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Auto Release in PvP", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Release Spirit in PvP", "autoReleasePvP", yPos,
        "Automatically releases your spirit when you die in PvP instances.")
    _, yPos = CreateQoLDropdown(s.content, "Release Delay (sec):", {
        {text = "Instant", value = 0},
        {text = "1 second", value = 1},
        {text = "2 seconds", value = 2},
        {text = "3 seconds", value = 3},
    }, "autoReleasePvPDelay", yPos)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Auto Combat Logging
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Auto Combat Logging", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Combat Log in Instances", "autoCombatLog", yPos,
        "Automatically starts/stops combat logging when entering/leaving\ndungeons and raids. Logs saved to WoWCombatLog.txt.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Loot & Banners
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Loot & Banners", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Hide Boss Kill Banner", "hideBossBanner", yPos,
        "Hides the large boss kill banner that appears after defeating a boss.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Azerite Power Toast", "hideAzeriteToast", yPos,
        "Hides the Azerite level-up toast notification.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- LFG Tweaks
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "LFG Tweaks", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Sort Applicants by M+ Score", "lfgSortByRio", yPos,
        "Sorts LFG applicant list by Mythic+ dungeon score (highest first).")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Persist Sign-Up Note", "lfgPersistSignUpNote", yPos,
        "Keeps your LFG sign-up note between applications\ninstead of clearing it each time.",
        function(checked) KDT:ToggleLFGPersistNote(checked) end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Skip Sign-Up Dialog", "lfgSkipSignUpDialog", yPos,
        "Auto-clicks the Sign Up button when the dialog appears.\nHold Shift to override and show the dialog.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Mount Options
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Smart Mount", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Use All Mounts (Not Just Favorites)", "randomMountUseAll", yPos,
        "Random mount selection includes all collected mounts,\nnot just your favorites.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Slow Fall When Falling", "randomMountSlowFallWhenFalling", yPos,
        "Automatically casts Slow Fall / Levitate instead of\nmounting when you are falling.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Dracthyr: Visage Before Mount", "randomMountDracthyrVisageBeforeMount", yPos,
        "Switches to Visage form before mounting (Dracthyr only).")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Druid: Don't Unshift While Mounted", "randomMountDruidNoShiftWhileMounted", yPos,
        "Prevents accidentally leaving mount when pressing the keybind\nwhile already mounted (Druid only).")
    
    local mountInfoText = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mountInfoText:SetPoint("TOPLEFT", 15, yPos - 5)
    mountInfoText:SetPoint("TOPRIGHT", -15, yPos - 5)
    mountInfoText:SetJustifyH("LEFT")
    mountInfoText:SetText("|cFF888888Usage:|r |cFFBBBBBBBind 'Smart Random Mount' in Key Bindings.\n" ..
        "Automatically picks ground/flying/water mount based on zone.\n" ..
        "Druids use Travel Form, Shamans use Ghost Wolf when appropriate.|r")
    mountInfoText:SetTextColor(0.6, 0.6, 0.6)
    mountInfoText:SetSpacing(2)
    yPos = yPos - 60
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Keystone Helper
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Keystone Helper", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Slot Keystone", "keystoneAutoSlot", yPos,
        "Automatically inserts your Mythic Keystone into the Font of Power\nwhen the receptacle opens.",
        function() KDT:InitKeystoneHelper() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Keystone Display", "keystoneShowDisplay", yPos,
        "Shows a small moveable frame with your current keystone.\nRight-click to announce to party. Drag to reposition.",
        function() KDT:InitKeystoneHelper() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Depletion / Upgrade Warning", "keystoneDepletionWarning", yPos,
        "Shows a chat message after M+ completion indicating\nwhether your key was upgraded or depleted.")
    _, yPos = CreateSeparator(s.content, yPos)
    
    -- Announce button
    local announceContainer = CreateFrame("Frame", nil, s.content)
    announceContainer:SetPoint("TOPLEFT", 15, yPos - 5)
    announceContainer:SetPoint("TOPRIGHT", -15, yPos - 5)
    announceContainer:SetHeight(30)
    
    local announceLabel = announceContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    announceLabel:SetPoint("LEFT", 0, 0)
    announceLabel:SetText("Announce Key:")
    announceLabel:SetTextColor(0.85, 0.85, 0.85)
    
    local function MakeAnnounceBtn(parent, label, channel, xOff)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(70, 22)
        btn:SetPoint("LEFT", parent, "LEFT", xOff, 0)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        btn:SetBackdropColor(0.12, 0.12, 0.14, 1)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER", 0, 0)
        btn.text:SetText(label)
        btn.text:SetTextColor(1, 1, 1)
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.18, 1)
            self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        end)
        btn:SetScript("OnClick", function()
            KDT:AnnounceKeystone(channel)
        end)
        return btn
    end
    
    MakeAnnounceBtn(announceContainer, "Party", "PARTY", 120)
    MakeAnnounceBtn(announceContainer, "Guild", "GUILD", 195)
    MakeAnnounceBtn(announceContainer, "Say", "SAY", 270)
    yPos = yPos - 40
    
    -- Request party keys button
    local requestContainer = CreateFrame("Frame", nil, s.content)
    requestContainer:SetPoint("TOPLEFT", 15, yPos - 5)
    requestContainer:SetPoint("TOPRIGHT", -15, yPos - 5)
    requestContainer:SetHeight(30)
    
    local requestLabel = requestContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    requestLabel:SetPoint("LEFT", 0, 0)
    requestLabel:SetText("Party Keys:")
    requestLabel:SetTextColor(0.85, 0.85, 0.85)
    
    local requestBtn = CreateFrame("Button", nil, requestContainer, "BackdropTemplate")
    requestBtn:SetSize(120, 22)
    requestBtn:SetPoint("LEFT", 120, 0)
    requestBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    requestBtn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    requestBtn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    requestBtn.text = requestBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    requestBtn.text:SetPoint("CENTER", 0, 0)
    requestBtn.text:SetText("Show Party Keys")
    requestBtn.text:SetTextColor(1, 1, 1)
    requestBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    requestBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.14, 1)
        self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)
    requestBtn:SetScript("OnClick", function()
        KDT:RequestPartyKeys()
    end)
    yPos = yPos - 40
    
    local keystoneInfo = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keystoneInfo:SetPoint("TOPLEFT", 15, yPos - 5)
    keystoneInfo:SetPoint("TOPRIGHT", -15, yPos - 5)
    keystoneInfo:SetJustifyH("LEFT")
    keystoneInfo:SetText("|cFF888888Commands:|r\n" ..
        "|cFFBBBBBB/kdt key|r - Show your keystone\n" ..
        "|cFFBBBBBB/kdt key party|r - Announce to party\n" ..
        "|cFFBBBBBB/kdt key guild|r - Announce to guild\n" ..
        "|cFFBBBBBB/kdt partykeys|r - Request party keystones")
    keystoneInfo:SetTextColor(0.6, 0.6, 0.6)
    keystoneInfo:SetSpacing(2)
    yPos = yPos - 75
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Consumable Reminder
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Consumable Reminder", sectionY)
    s.category = "Gameplay"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Enable Consumable Reminder", "foodReminderEnabled", yPos,
        "Shows a checklist when entering dungeons or M+ to remind you of missing consumables.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Play Warning Sound", "foodReminderSound", yPos,
        "Plays a raid warning sound when consumables are missing.")
    _, yPos = CreateSeparator(s.content, yPos)
    
    local checksHeader = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checksHeader:SetPoint("TOPLEFT", 15, yPos)
    checksHeader:SetText("|cFF3BD1ECWhat to Check|r")
    yPos = yPos - 20
    
    _, yPos = CreateQoLCheckbox(s.content, "Flask / Phial Buff", "foodReminderFlask", yPos,
        "Checks for an active Flask or Phial buff.")
    _, yPos = CreateQoLCheckbox(s.content, "Food Buff (Well Fed)", "foodReminderFood", yPos,
        "Checks for an active Well Fed food buff.")
    _, yPos = CreateQoLCheckbox(s.content, "Augment Rune", "foodReminderRune", yPos,
        "Checks for an active Augment Rune buff.")
    _, yPos = CreateQoLCheckbox(s.content, "Weapon Enchant (Oil / Stone)", "foodReminderWeapon", yPos,
        "Checks for a temporary weapon enchant on your main hand.")
    _, yPos = CreateQoLCheckbox(s.content, "Health Potions in Bags", "foodReminderHealthPot", yPos,
        "Checks if you have healing potions or healthstones.")
    _, yPos = CreateQoLCheckbox(s.content, "Combat Potions in Bags", "foodReminderCombatPot", yPos,
        "Checks if you have Tempered Potions or similar combat potions.")
    _, yPos = CreateSeparator(s.content, yPos)
    
    -- Manual recheck button
    local recheckBtn = CreateFrame("Button", nil, s.content, "BackdropTemplate")
    recheckBtn:SetSize(140, 24)
    recheckBtn:SetPoint("TOPLEFT", 15, yPos - 5)
    recheckBtn:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8", edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1 })
    recheckBtn:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
    recheckBtn:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.4)
    local recheckBtnText = recheckBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    recheckBtnText:SetPoint("CENTER")
    recheckBtnText:SetText("|cFF3BD1ECCheck Now|r")
    recheckBtn:SetScript("OnClick", function() KDT:CheckConsumables() end)
    recheckBtn:SetScript("OnEnter", function()
        recheckBtn:SetBackdropColor(0.2, 0.2, 0.25, 0.9)
        recheckBtn:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.8)
    end)
    recheckBtn:SetScript("OnLeave", function()
        recheckBtn:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
        recheckBtn:SetBackdropBorderColor(0.23, 0.82, 0.93, 0.4)
    end)
    yPos = yPos - 35
    
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    return sectionY
end

local function CreateSocialSections(scrollChild, frame, allSections, sectionY)
    local s, yPos
    
    -- Privacy & Blocking
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Privacy & Blocking", sectionY)
    s.category = "Social"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Block Duel Requests", "blockDuels", yPos,
        "Automatically declines all incoming duel requests.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Block Pet Battle Requests", "blockPetBattles", yPos,
        "Automatically declines all incoming pet battle duel requests.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Block Party Invites", "blockPartyInvites", yPos,
        "Automatically declines all incoming party invitations.\nNote: This is ignored if Auto Accept is enabled.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Party Invite Auto Accept (upgraded)
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Party Invite Auto Accept", sectionY)
    s.category = "Social"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Accept Party Invites", "autoAcceptInvites", yPos,
        "Automatically accepts incoming party invitations.\nUse the filters below to restrict who can auto-invite you.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Guild Members Only", "autoAcceptInviteGuildOnly", yPos,
        "Only auto-accept invites from guild members.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Friends Only", "autoAcceptInviteFriendOnly", yPos,
        "Only auto-accept invites from Battle.net or WoW friends.\nCan be combined with Guild filter (accepts both).")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Auto Accept Summon
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Auto Accept Summon", sectionY)
    s.category = "Social"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Accept Summon", "autoAcceptSummon", yPos,
        "Automatically accepts summoning stones and warlock summons.\nDisabled during combat.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Community Chat Privacy
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Community Chat Privacy", sectionY)
    s.category = "Social"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Enable Community Chat Privacy", "communityChatPrivacy", yPos,
        "Hides community chat and member list by default.\nClick the eye icon in the Communities window to toggle visibility.",
        function(value) KDT:SetCommunityChatPrivacy(value) end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLDropdown(s.content, "Privacy Mode:", {
        {text = "Always Hidden", value = "always"},
        {text = "Per Session", value = "session"},
    }, "communityChatPrivacyMode", yPos)
    
    local privacyInfo = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    privacyInfo:SetPoint("TOPLEFT", 15, yPos - 5)
    privacyInfo:SetPoint("TOPRIGHT", -15, yPos - 5)
    privacyInfo:SetJustifyH("LEFT")
    privacyInfo:SetText("|cFF888888Always Hidden:|r Chat resets to hidden each time you open Communities.\n" ..
        "|cFF888888Per Session:|r Once revealed, chat stays visible until you log out.")
    privacyInfo:SetTextColor(0.6, 0.6, 0.6)
    privacyInfo:SetSpacing(2)
    yPos = yPos - 40
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Friends List Decor
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Friends List Decor", sectionY)
    s.category = "Social"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Enable Friends List Decor", "friendsListDecor", yPos,
        "Adds class colors, level colors, and faction icons to the friends list.",
        function(value) KDT:SetFriendsListDecor(value) end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Location", "friendsListDecorLocation", yPos,
        "Shows the zone and realm of online friends in the info line.",
        function() KDT:RefreshFriendsListDecor() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Own Realm", "friendsListDecorHideOwnRealm", yPos,
        "Hides the realm name for friends on your own realm.",
        function() KDT:RefreshFriendsListDecor() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    return sectionY
end

local function CreateChatSections(scrollChild, frame, allSections, sectionY)
    local s, yPos
    
    -- Chat Window
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Chat Window", sectionY)
    s.category = "Chat"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Move Edit Box to Top", "chatEditBoxOnTop", yPos,
        "Moves the chat input box above the chat window.",
        function() KDT:ApplyChatSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Use Arrow Keys in Chat", "chatUseArrowKeys", yPos,
        "Allows using arrow keys to navigate chat history.\nWithout this, arrow keys move your character.",
        function() KDT:ApplyChatSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Unclamp Chat Frame", "chatUnclampFrame", yPos,
        "Allows dragging the chat window outside screen boundaries.",
        function() KDT:ApplyChatSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Increase Max Lines to 2000", "chatMaxLines2000", yPos,
        "Increases chat history buffer from 128 to 2000 lines.",
        function() KDT:ApplyChatSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Combat Log Tab", "chatHideCombatLogTab", yPos,
        "Hides the Combat Log tab from the chat frame.",
        function() KDT:ApplyChatSettings() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Chat Fade
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Chat Fade", sectionY)
    s.category = "Chat"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Enable Chat Fading", "chatFadeEnabled", yPos,
        "Chat messages fade out after a set time.",
        function() KDT:ApplyChatSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLSlider(s.content, "Visible Duration:", 10, 300, 10, "chatFadeTimeVisible", yPos,
        "Seconds before chat text starts fading.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLSlider(s.content, "Fade Duration:", 1, 30, 1, "chatFadeDuration", yPos,
        "Seconds the fade-out animation takes.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Chat Messages
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Chat Filters", sectionY)
    s.category = "Chat"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Hide Learn/Unlearn Messages", "chatHideLearnUnlearn", yPos,
        "Suppresses 'You have learned/unlearned' spam in chat.\nUseful when switching talents or learning spells.",
        function() KDT:ApplyChatSettings() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Chat Icons & Item Level
    s = CreateCollapsibleSection(scrollChild, "Chat Icons & Item Level", sectionY)
    s.category = "Chat"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Show Item Icons in Chat", "chatItemIcons", yPos,
        "Displays item and currency icons inline in chat messages.",
        function() KDT:UpdateChatIcons() end)
    _, yPos = CreateQoLCheckbox(s.content, "Show Item Level in Chat", "chatItemLevel", yPos,
        "Appends item level to linked items in chat messages.",
        function() KDT:UpdateChatIcons() end)
    _, yPos = CreateQoLCheckbox(s.content, "Show Equip Location in Chat", "chatItemLevelLocation", yPos,
        "Also shows the equipment slot (Head, Chest, etc.) next to item level.",
        function() KDT:UpdateChatIcons() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Chat Enhancer (Dark Skin)
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Chat Enhancer (Dark Skin)", sectionY)
    s.category = "Chat"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    
    -- Helper: Read/Write chatEnhancer DB
    local function getCE(key)
        return KDT.DB and KDT.DB.chatEnhancer and KDT.DB.chatEnhancer[key]
    end
    local function setCE(key, val)
        if KDT.DB and KDT.DB.chatEnhancer then KDT.DB.chatEnhancer[key] = val end
    end
    
    -- Helper: Checkbox for chatEnhancer settings
    local function CreateCECheckbox(parent, label, configKey, yOff, desc, onChange)
        local container = CreateFrame("Frame", nil, parent)
        container:SetPoint("TOPLEFT", 15, yOff)
        container:SetPoint("TOPRIGHT", -15, yOff)
        
        local cb = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        cb:SetPoint("LEFT", 0, desc and 5 or 0)
        cb:SetSize(24, 24)
        cb:SetChecked(getCE(configKey) or false)
        
        local lt = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lt:SetPoint("LEFT", cb, "RIGHT", 8, 0)
        lt:SetText(label)
        lt:SetTextColor(0.85, 0.85, 0.85)
        
        local descHeight = 0
        if desc then
            local dt = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dt:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 32, 2)
            dt:SetPoint("RIGHT", container, "RIGHT", -10, 0)
            dt:SetJustifyH("LEFT")
            dt:SetText(desc)
            dt:SetTextColor(0.5, 0.5, 0.5)
            -- Measure actual text height
            descHeight = dt:GetStringHeight() or 14
        end
        
        local totalHeight = desc and (30 + math.max(descHeight, 14)) or 30
        container:SetHeight(totalHeight)
        
        cb:SetScript("OnClick", function(self)
            setCE(configKey, self:GetChecked())
            if onChange then onChange(self:GetChecked()) end
        end)
        
        return container, yOff - (totalHeight + 5)
    end
    
    -- Helper: Slider for chatEnhancer settings
    local function CreateCESlider(parent, label, min, max, step, configKey, yOff, desc)
        local container = CreateFrame("Frame", nil, parent)
        container:SetPoint("TOPLEFT", 15, yOff)
        container:SetPoint("TOPRIGHT", -15, yOff)
        container:SetHeight(desc and 55 or 40)
        
        local currentVal = getCE(configKey) or min
        
        local lt = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lt:SetPoint("TOPLEFT", 0, 0)
        lt:SetTextColor(0.85, 0.85, 0.85)
        lt:SetText(label .. " " .. string.format("%.0f", currentVal))
        
        local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 0, -16)
        slider:SetPoint("TOPRIGHT", -50, -16)
        slider:SetHeight(16)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(currentVal)
        slider.Low:SetText(tostring(min))
        slider.High:SetText(tostring(max))
        
        if desc then
            local dt = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dt:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
            dt:SetPoint("RIGHT", container, "RIGHT", -10, 0)
            dt:SetJustifyH("LEFT")
            dt:SetText(desc)
            dt:SetTextColor(0.5, 0.5, 0.5)
        end
        
        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / step + 0.5) * step
            setCE(configKey, value)
            lt:SetText(label .. " " .. string.format("%.0f", value))
            if KDT.ChatEnhancer then KDT.ChatEnhancer:ApplySettings() end
        end)
        
        return container, yOff - (desc and 60 or 45)
    end
    
    -- Master Enable toggle
    _, yPos = CreateCECheckbox(s.content, "Enable Chat Enhancer |cFFFF4444(requires /reload)|r", "enabled", yPos,
        "Applies a dark skin to all chat frames with copy button, class-colored names, clickable URLs, and channel shortening.",
        function(value)
            StaticPopupDialogs["KDT_CHAT_ENHANCER_RELOAD"] = StaticPopupDialogs["KDT_CHAT_ENHANCER_RELOAD"] or {
                text = "Chat Enhancer requires a UI reload to apply.\nReload now?",
                button1 = "Reload",
                button2 = "Later",
                OnAccept = function() ReloadUI() end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("KDT_CHAT_ENHANCER_RELOAD")
        end)
    _, yPos = CreateSeparator(s.content, yPos)
    
    -- Visual Settings
    local visualHeader = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    visualHeader:SetPoint("TOPLEFT", 15, yPos)
    visualHeader:SetText("|cFF3BD1ECVisual|r")
    yPos = yPos - 20
    
    _, yPos = CreateCESlider(s.content, "Background Transparency:", 0, 80, 2, "transparency", yPos)
    _, yPos = CreateCESlider(s.content, "Tab Transparency:", 0, 80, 2, "tabTransparency", yPos)
    _, yPos = CreateSeparator(s.content, yPos)
    
    -- Message Filter Settings
    local filterHeader = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterHeader:SetPoint("TOPLEFT", 15, yPos)
    filterHeader:SetText("|cFF3BD1ECMessage Filters|r")
    yPos = yPos - 20
    
    _, yPos = CreateCECheckbox(s.content, "Class-Colored Names", "classColors", yPos,
        "Colors player names by their class in chat messages.")
    _, yPos = CreateCECheckbox(s.content, "Clickable URLs", "clickableURLs", yPos,
        "Makes URLs in chat clickable with a copy dialog.")
    _, yPos = CreateCECheckbox(s.content, "Shorten Channel Names", "shortenChannels", yPos,
        "Shortens channel names: [General] to [G], [Trade] to [T],\n[Handel] to [H], [SucheNachGruppe] to [SNG], etc.")
    
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    return sectionY
end

local function CreateGeneralSections(scrollChild, frame, allSections, sectionY)
    local s, yPos
    
    -- Dialogs & Confirmations
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Dialogs & Confirmations", sectionY)
    s.category = "General"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Fill Delete Text", "deleteItemFillDialog", yPos,
        "Automatically fills in 'DELETE' when deleting rare+ items.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Confirm: Replace Enchant", "confirmReplaceEnchant", yPos,
        "Automatically confirms the enchant replacement dialog.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Confirm: Socket Replace", "confirmSocketReplace", yPos,
        "Automatically confirms when replacing gems in sockets.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Confirm: High Cost Item", "confirmHighCostItem", yPos,
        "Automatically confirms high-cost item purchases.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Confirm: Token Purchase", "confirmPurchaseTokenItem", yPos,
        "Automatically confirms WoW Token purchases.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Confirm: Trade Timer Removal", "confirmTimerRemovalTrade", yPos,
        "Automatically confirms removing trade timers on items.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Utilities
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Utilities", sectionY)
    s.category = "General"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto Quick Loot", "autoQuickLoot", yPos,
        "Instantly loots all items when opening a loot window.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Require Shift for Quick Loot", "autoQuickLootWithShift", yPos,
        "Quick loot only triggers when holding Shift.\nWithout Shift, loot window opens normally.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show 'Train All' Button", "showTrainAllButton", yPos,
        "Adds a 'Train All' button to class trainer windows.\nTrains all available skills at once.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Screenshot Status Bar", "hideScreenshotStatus", yPos,
        "Hides the screenshot notification bar that appears at the top of the screen.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Skip Gossip
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Skip Gossip", sectionY)
    s.category = "General"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Skip Single Gossip Options", "skipGossip", yPos,
        "Automatically selects the gossip option when only one is available.\nHold Shift to override. Skipped when quests are present.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Skip Cutscenes
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Skip Cutscenes", sectionY)
    s.category = "General"
    table.insert(frame.uitweaksElements, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Skip Cutscenes & Movies", "skipCutscene", yPos,
        "Automatically skips in-game cinematics and movie sequences.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    table.insert(allSections, s)
    
    -- Movement & Input
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Movement & Input", sectionY)
    s.category = "General"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Dismount", "autoDismount", yPos,
        "Automatically dismount when casting a spell or ability.",
        function() KDT:ApplyMovementCVars() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Dismount While Flying", "autoDismountFlying", yPos,
        "Automatically dismount when casting while flying.\nWarning: You will fall!",
        function() KDT:ApplyMovementCVars() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    return sectionY
end

local function CreateInterfaceSections(scrollChild, frame, allSections, sectionY)
    local s, yPos
    
    -- Minimap Button Collector
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Minimap Button Collector", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    s.sectionName = "MinimapCollector"
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Collect Addon Minimap Buttons", "minimapCollectorEnabled", yPos,
        "Hides addon minimap buttons and collects them behind a single\nKDT button. Hover over it to expand all buttons.")
    
    local mmcInfo = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mmcInfo:SetPoint("TOPLEFT", 15, yPos - 5)
    mmcInfo:SetPoint("TOPRIGHT", -15, yPos - 5)
    mmcInfo:SetJustifyH("LEFT")
    mmcInfo:SetText("|cFF888888Requires /reload after toggling. Blizzard UI buttons are excluded.|r")
    mmcInfo:SetTextColor(0.6, 0.6, 0.6)
    yPos = yPos - 20
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Mouse Cursor
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Mouse Cursor", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    s.sectionName = "MouseCursor"
    
    yPos = -20
    _, yPos = CreateCheckbox(s.content, "Enable Mouse Cursor", "enabled", yPos, function()
        if KDT.MouseCursor:GetConfig("enabled") then
            KDT.MouseCursor:Initialize()
        else
            if KDT_MouseCursorFrame then KDT_MouseCursorFrame:Hide() end
        end
    end)
    
    _, yPos = CreateSeparator(s.content, yPos - 5)
    _, yPos = CreateSectionHeader(s.content, "Ring Slot Assignment", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Reticle:", KDT.MouseCursor.reticleOptions, "reticle", yPos)
    _, yPos = CreateSlider(s.content, "Reticle Scale:", 0.5, 3.0, 0.1, "reticleScale", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Inner Ring:", KDT.MouseCursor.ringOptions, "innerRing", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Main Ring:", KDT.MouseCursor.ringOptions, "mainRing", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Outer Ring:", KDT.MouseCursor.ringOptions, "outerRing", yPos)
    
    _, yPos = CreateSeparator(s.content, yPos - 5)
    _, yPos = CreateSectionHeader(s.content, "Colors", yPos)
    _, yPos = CreateColorPicker(s.content, "Reticle Color:", "reticleColorMode", "reticleCustomColor", yPos)
    _, yPos = CreateColorPicker(s.content, "Main Ring Color:", "mainRingColorMode", "mainRingCustomColor", yPos)
    _, yPos = CreateColorPicker(s.content, "GCD Ring Color:", "gcdColorMode", "gcdCustomColor", yPos)
    _, yPos = CreateColorPicker(s.content, "Cast Ring Color:", "castColorMode", "castCustomColor", yPos)
    _, yPos = CreateColorPicker(s.content, "Health Ring Color:", "healthColorMode", "healthCustomColor", yPos)
    _, yPos = CreateColorPicker(s.content, "Power Ring Color:", "powerColorMode", "powerCustomColor", yPos)
    
    _, yPos = CreateSeparator(s.content, yPos - 5)
    _, yPos = CreateSectionHeader(s.content, "Animation Settings", yPos)
    local gcdFillOptions = {"fill", "drain"}
    _, yPos = CreateCustomDropdown(s.content, "GCD Fill/Drain:", gcdFillOptions, "gcdFillDrain", yPos)
    local clockOptions = {}
    for i = 1, 12 do table.insert(clockOptions, tostring(i)) end
    _, yPos = CreateCustomDropdown(s.content, "GCD Start Position (Clock):", clockOptions, "gcdRotation", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Cast Fill/Drain:", gcdFillOptions, "castFillDrain", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Cast Start Position (Clock):", clockOptions, "castRotation", yPos)
    
    _, yPos = CreateSeparator(s.content, yPos - 5)
    _, yPos = CreateSectionHeader(s.content, "General Settings", yPos)
    _, yPos = CreateSlider(s.content, "Overall Scale:", 0.5, 2.0, 0.1, "scale", yPos)
    _, yPos = CreateSlider(s.content, "Transparency:", 0.0, 1.0, 0.05, "transparency", yPos)
    _, yPos = CreateCheckbox(s.content, "Show Only in Combat", "showOnlyInCombat", yPos)
    
    _, yPos = CreateSeparator(s.content, yPos - 5)
    _, yPos = CreateSectionHeader(s.content, "Mouse Trail", yPos)
    _, yPos = CreateCheckbox(s.content, "Enable Mouse Trail", "enableTrail", yPos, function()
        if KDT.MouseCursor:GetConfig("enableTrail") then
            KDT.MouseCursor:InitTrail()
        else
            KDT.MouseCursor:StopTrail()
        end
    end)
    _, yPos = CreateCheckbox(s.content, "Show Trail Only in Combat", "trailOnlyInCombat", yPos)
    _, yPos = CreateSlider(s.content, "Trail Duration:", 0.2, 1.5, 0.1, "trailDuration", yPos)
    _, yPos = CreateSlider(s.content, "Trail Scale:", 0.3, 3.0, 0.1, "trailScale", yPos)
    local trailDensityOptions = {"Low", "Medium", "High", "Ultra"}
    _, yPos = CreateCustomDropdown(s.content, "Trail Density:", trailDensityOptions, "trailPreset", yPos)
    _, yPos = CreateColorPicker(s.content, "Trail Color:", "trailColorMode", "trailCustomColor", yPos)
    
    _, yPos = CreateSeparator(s.content, yPos - 5)
    _, yPos = CreateSectionHeader(s.content, "Modifier Keys", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Shift Action:", KDT.MouseCursor.modifierOptions, "shiftAction", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Ctrl Action:", KDT.MouseCursor.modifierOptions, "ctrlAction", yPos)
    _, yPos = CreateCustomDropdown(s.content, "Alt Action:", KDT.MouseCursor.modifierOptions, "altAction", yPos)
    
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Nameplates & Names
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Nameplates & Names", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Show Class Colors in Nameplates", "showClassColorsNameplates", yPos,
        "Display class-colored nameplates for friendly players.", function() KDT:ApplyNameplateCVars() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Guild Names", "showGuildNames", yPos,
        "Display guild names below player names.", function() KDT:ApplyNameplateCVars() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show PvP Titles", "showPvPTitles", yPos,
        "Display PvP titles on player nameplates.", function() KDT:ApplyNameplateCVars() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- UI Tweaks
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "UI Tweaks", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Hide Talking Head Popup", "hideTalkingHead", yPos,
        "Suppresses the Talking Head frame that appears during quests and events.", function() KDT:ApplyTalkingHeadSetting() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Disable Death Grayscale Effect", "hideDeathEffect", yPos,
        "Removes the gray screen filter when your character dies.", function() KDT:ApplyDeathEffectSetting() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Zone Text", "hideZoneText", yPos,
        "Hides the large zone name text when entering new areas.", function() KDT:ApplyZoneTextSetting() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Raid Tools Frame", "hideRaidTools", yPos,
        "Hides the Compact Raid Frame Manager button on the left side.", function() KDT:ApplyRaidToolsSetting() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Auto-Unwrap Collection Items", "autoUnwrapCollections", yPos,
        "Automatically clears fanfare on new mounts, pets, and toys.")
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Resource Bars (class-specific)
    local classTag = KDT:GetPlayerClassTag()
    local CLASS_RESOURCE_OPTIONS = {
        DEATHKNIGHT = {
            {label = "Hide Rune Frame", key = "hideRuneFrame", desc = "Hides the Death Knight rune display."},
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar."},
        },
        DRUID = {
            {label = "Hide Combo Points", key = "hideComboPoints", desc = "Hides the Druid combo point bar (Cat Form)."},
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar (Efflorescence, etc.)."},
        },
        EVOKER = {
            {label = "Hide Essence Bar", key = "hideEssenceBar", desc = "Hides the Evoker essence resource display."},
        },
        MONK = {
            {label = "Hide Chi Bar", key = "hideHarmonyBar", desc = "Hides the Monk chi/harmony resource bar."},
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar."},
        },
        PALADIN = {
            {label = "Hide Holy Power", key = "hideHolyPower", desc = "Hides the Paladin holy power display."},
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar (Consecration, etc.)."},
        },
        ROGUE = {
            {label = "Hide Combo Points", key = "hideComboPoints", desc = "Hides the Rogue combo point bar."},
        },
        WARLOCK = {
            {label = "Hide Soul Shard Bar", key = "hideSoulShards", desc = "Hides the Warlock soul shard display."},
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar."},
        },
        SHAMAN = {
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem bar."},
        },
        MAGE = {
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar (Rune of Power, etc.)."},
        },
        PRIEST = {
            {label = "Hide Totem Bar", key = "hideTotemBar", desc = "Hides the totem/widget bar."},
        },
    }
    
    local classOptions = classTag and CLASS_RESOURCE_OPTIONS[classTag]
    if classOptions and #classOptions > 0 then
        sectionY = sectionY - 37
        local className = UnitClass("player") or classTag
        s = CreateCollapsibleSection(scrollChild, "Resource Bars (" .. className .. ")", sectionY)
        s.category = "Interface"
        table.insert(frame.uitweaksElements, s)
        table.insert(allSections, s)
        
        yPos = -20
        for i, option in ipairs(classOptions) do
            if i > 1 then
                _, yPos = CreateSeparator(s.content, yPos)
            end
            _, yPos = CreateQoLCheckbox(s.content, option.label, option.key, yPos,
                option.desc, function() KDT:ApplyResourceBarSettings() end)
        end
        s.content:SetHeight(math.abs(yPos) + 20)
        s.content:Hide()
    end
    
    -- Unit Frames
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Unit Frames", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Hide Hit Indicator (Player)", "hideHitIndicatorPlayer", yPos,
        "Hides the damage flash indicator on your player frame.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Hit Indicator (Pet)", "hideHitIndicatorPet", yPos,
        "Hides the damage flash indicator on your pet frame.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Resting Glow", "hideRestingGlow", yPos,
        "Hides the pulsing rest glow on the player frame while in a rest area.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Party Frame Title", "hidePartyFrameTitle", yPos,
        "Hides the Compact Raid Frame Manager title bar above party frames.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Action Bars
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Action Bars", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Hide Macro Names", "hideMacroNames", yPos,
        "Hides macro name text on action bar buttons.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Extra Action Button Artwork", "hideExtraActionArtwork", yPos,
        "Removes the decorative frame around the Extra Action Button.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Shorten Hotkey Text", "actionBarShortenHotkeys", yPos,
        "Abbreviates keybind text on action buttons.\nCTRL-SHIFT-1 > CS1, MOUSE BUTTON 4 > M4, NUM PAD 5 > N5.",
        function() KDT:InitActionBarTweaks() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Range Coloring (Red Overlay)", "actionBarRangeColoring", yPos,
        "Shows a red overlay on action buttons when the ability is out of range.",
        function() KDT:InitActionBarTweaks() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Notifications & Toasts
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Notifications & Toasts", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Hide Micro Menu Notification", "hideMicroMenuNotification", yPos,
        "Hides the flashing notification overlay on micro menu buttons.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Azerite Level-Up Toast", "hideAzeriteToast", yPos,
        "Suppresses the Azerite power level-up notification.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Quick Join Toast", "hideQuickJoinToast", yPos,
        "Hides the Quick Join toast button near the chat frame.",
        function() KDT:ApplyBatch1InterfaceSettings() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Tooltip Enhancements
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Tooltip Enhancements", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Class-Colored Names", "tooltipClassColors", yPos,
        "Colors player names in tooltips by their class color.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Guild Rank", "tooltipShowGuildRank", yPos,
        "Displays the player's guild rank in the tooltip.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Color Guild Name", "tooltipColorGuildName", yPos,
        "Colors the guild name line in a distinct color.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Mythic+ Score", "tooltipShowMythicScore", yPos,
        "Displays the player's M+ score in the tooltip.\nUses the modifier key below to toggle visibility.")
    _, yPos = CreateQoLDropdown(s.content, "M+ Score Modifier:", {
        {text = "Always Show", value = "NONE"},
        {text = "Hold Shift", value = "SHIFT"},
        {text = "Hold Ctrl", value = "CTRL"},
        {text = "Hold Alt", value = "ALT"},
    }, "tooltipMythicScoreModifier", yPos)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Target of Target", "tooltipShowTargetOfTarget", yPos,
        "Shows who the hovered unit is targeting.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Mount Name", "tooltipShowMount", yPos,
        "Displays what mount a player is currently using.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Specialization", "tooltipShowSpec", yPos,
        "Shows the player's current specialization.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Item Level", "tooltipShowItemLevel", yPos,
        "Displays the player's average item level.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Spell ID", "tooltipShowSpellID", yPos,
        "Adds the Spell ID to spell tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Spell Icon in Tooltip", "tooltipShowSpellIcon", yPos,
        "Adds the spell icon next to the spell name in tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Item ID", "tooltipShowItemID", yPos,
        "Adds the Item ID to item tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Item Icon in Tooltip", "tooltipShowItemIcon", yPos,
        "Adds the item icon next to the item name in tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show NPC ID", "tooltipShowNPCID", yPos,
        "Adds the NPC ID to NPC tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Currency ID", "tooltipShowCurrencyID", yPos,
        "Adds the Currency ID to currency tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Tooltip in Combat", "tooltipHideInCombat", yPos,
        "Completely hides unit tooltips while you are in combat.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Health Bar", "tooltipHideHealthBar", yPos,
        "Removes the health bar from unit tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide Faction Line", "tooltipHideFaction", yPos,
        "Hides the Alliance/Horde faction text from tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide PvP Status", "tooltipHidePvP", yPos,
        "Hides the PvP status text from tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Hide 'Right-Click to...' Text", "tooltipHideRightClick", yPos,
        "Removes the right-click instruction text from tooltips.")
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Anchor Tooltip to Cursor", "tooltipAnchorCursor", yPos,
        "Positions the tooltip at your cursor instead of the default location.")
    _, yPos = CreateSeparator(s.content, yPos)
    
    -- Tooltip Scale Slider
    local scaleContainer = CreateFrame("Frame", nil, s.content)
    scaleContainer:SetSize(350, 40)
    scaleContainer:SetPoint("TOPLEFT", 15, yPos - 5)
    
    local scaleLabel = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 0, 0)
    scaleLabel:SetText("Tooltip Scale:")
    scaleLabel:SetTextColor(1, 0.82, 0)
    
    local scaleSlider = CreateFrame("Slider", nil, scaleContainer, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 0, -18)
    scaleSlider:SetWidth(200)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue(KDT.DB.qol.tooltipScale or 1)
    scaleSlider.Low:SetText("0.5")
    scaleSlider.High:SetText("2.0")
    
    local scaleValue = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scaleValue:SetPoint("LEFT", scaleSlider, "RIGHT", 10, 0)
    scaleValue:SetText(string.format("%.1f", KDT.DB.qol.tooltipScale or 1))
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10
        KDT.DB.qol.tooltipScale = value
        scaleValue:SetText(string.format("%.1f", value))
    end)
    yPos = yPos - 55
    
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Bag Item Level
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Bag Item Level Display", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Show Item Level on Bag Items", "showBagItemLevel", yPos,
        "Displays the item level overlay on items in your bags.",
        function() KDT:InitBagItemLevel() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Show Upgrade Arrow", "showBagUpgradeArrow", yPos,
        "Shows a green arrow on bag items that are an upgrade\nfor your currently equipped gear.",
        function() KDT:InitBagItemLevel() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Health Text
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Health Text on Frames", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    local healthModes = {
        {text = "Off", value = "OFF"},
        {text = "Percent (50%)", value = "PERCENT"},
        {text = "Absolute (125k)", value = "ABS"},
        {text = "Both (125k - 50%)", value = "BOTH"},
        {text = "Current / Max", value = "CURMAX"},
        {text = "Cur/Max + % (125k/250k - 50%)", value = "CURMAXPERCENT"},
    }
    _, yPos = CreateQoLDropdown(s.content, "Player Frame:", healthModes, "healthTextPlayer", yPos,
        nil, function() KDT:InitHealthText() end)
    _, yPos = CreateQoLDropdown(s.content, "Target Frame:", healthModes, "healthTextTarget", yPos,
        nil, function() KDT:InitHealthText() end)
    _, yPos = CreateQoLDropdown(s.content, "Boss Frames:", healthModes, "healthTextBoss", yPos,
        nil, function() KDT:InitHealthText() end)
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Instance Difficulty Display
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Instance Difficulty Display", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Show Instance Difficulty Text", "showInstanceDifficulty", yPos,
        "Displays the current instance difficulty (NM, HC, M, M+, LFR, TW)\nas colored text near the minimap.",
        function() KDT:InitInstanceDifficulty() end)
    _, yPos = CreateSeparator(s.content, yPos)
    _, yPos = CreateQoLCheckbox(s.content, "Color by Difficulty", "instanceDiffUseColors", yPos,
        "Colors the difficulty text (green=NM, yellow=HC, orange=M, red=M+, purple=TW).",
        function() KDT:InitInstanceDifficulty() end)
    _, yPos = CreateSeparator(s.content, yPos)
    
    -- Font Size Slider
    local fontContainer = CreateFrame("Frame", nil, s.content)
    fontContainer:SetSize(350, 40)
    fontContainer:SetPoint("TOPLEFT", 15, yPos - 5)
    
    local fontLabel = fontContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", 0, 0)
    fontLabel:SetText("Font Size:")
    fontLabel:SetTextColor(1, 0.82, 0)
    
    local fontSlider = CreateFrame("Slider", nil, fontContainer, "OptionsSliderTemplate")
    fontSlider:SetPoint("TOPLEFT", 0, -18)
    fontSlider:SetWidth(200)
    fontSlider:SetMinMaxValues(8, 24)
    fontSlider:SetValueStep(1)
    fontSlider:SetObeyStepOnDrag(true)
    fontSlider:SetValue(KDT.DB.qol.instanceDiffFontSize or 14)
    fontSlider.Low:SetText("8")
    fontSlider.High:SetText("24")
    
    local fontValue = fontContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontValue:SetPoint("LEFT", fontSlider, "RIGHT", 10, 0)
    fontValue:SetText(tostring(KDT.DB.qol.instanceDiffFontSize or 14))
    
    fontSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        KDT.DB.qol.instanceDiffFontSize = value
        fontValue:SetText(tostring(value))
        KDT:InitInstanceDifficulty()
    end)
    yPos = yPos - 55
    
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Helper: Create styled action button
    local function CreateActionButton(parent, text, xOffset, yOffset, width, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(width or 200, 26)
        btn:SetPoint("TOPLEFT", xOffset or 15, yOffset)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.12, 0.12, 0.15, 1)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", 0, 0)
        btn.text:SetText(text)
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.18, 0.18, 0.22, 1)
            self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.15, 1)
            self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        end)
        btn:SetScript("OnClick", onClick)
        return btn
    end
    
    -- DataPanels (ported from EnhanceQoL)
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Data Panels", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    local dpDesc = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpDesc:SetPoint("TOPLEFT", 15, yPos)
    dpDesc:SetPoint("TOPRIGHT", -15, yPos)
    dpDesc:SetJustifyH("LEFT")
    dpDesc:SetText("Configurable info panels: Gold, Coordinates, Durability,\n" ..
        "Bag Space, Latency, iLvl, M+ Key, Rating, Friends, Mail, etc.\n" ..
        "Right-click panels in-game to configure streams and appearance.")
    dpDesc:SetTextColor(0.6, 0.6, 0.6)
    dpDesc:SetSpacing(2)
    yPos = yPos - 50
    
    CreateActionButton(s.content, "|cFFFFD200Create New Data Panel|r", 15, yPos, 220, function()
        if KDT.DataPanel then
            local panel = KDT.DataPanel.Create(nil, "Panel")
            if panel then
                KDT:Print("Data Panel created. Right-click it to add streams and configure.")
                KDT:Print("Drag to reposition, use EditMode for advanced layout.")
            end
        else
            KDT:Print("DataPanel module not loaded.")
        end
    end)
    yPos = yPos - 35
    
    CreateActionButton(s.content, "|cFFBBBBBBShow All Panels|r", 15, yPos, 220, function()
        if KDT.DataPanel and KDT.DataPanel.List then
            local list = KDT.DataPanel.List()
            if list and #list > 0 then
                KDT:Print("|cffffd200Data Panels:|r " .. #list .. " panel(s)")
                for _, p in ipairs(list) do
                    local streamCount = p.order and #p.order or 0
                    KDT:Print("  " .. (p.name or p.id) .. " - " .. streamCount .. " stream(s)")
                    if p.frame then p.frame:Show() end
                end
            else
                KDT:Print("No Data Panels exist. Create one first.")
            end
        end
    end)
    yPos = yPos - 40
    
    local dpTip = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpTip:SetPoint("TOPLEFT", 15, yPos)
    dpTip:SetText("|cFF666666Right-click a panel in-game to add/remove data streams.|r")
    dpTip:SetTextColor(0.4, 0.4, 0.4)
    yPos = yPos - 20
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- CooldownPanels (ported from EnhanceQoL)
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Cooldown Panels", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    local cpDesc = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cpDesc:SetPoint("TOPLEFT", 15, yPos)
    cpDesc:SetPoint("TOPRIGHT", -15, yPos)
    cpDesc:SetJustifyH("LEFT")
    cpDesc:SetText("Custom cooldown tracking panels for spells, items, equipment.\n" ..
        "Grid/radial layouts, Masque skins, glow effects, class/spec filtering.")
    cpDesc:SetTextColor(0.6, 0.6, 0.6)
    cpDesc:SetSpacing(2)
    yPos = yPos - 35
    
    CreateActionButton(s.content, "|cFFFFD200Open Cooldown Panel Editor|r", 15, yPos, 250, function()
        if KDT.Aura and KDT.Aura.CooldownPanels then
            if KDT.Aura.CooldownPanels.ToggleEditor then
                KDT.Aura.CooldownPanels:ToggleEditor()
            elseif KDT.Aura.CooldownPanels.OpenEditor then
                KDT.Aura.CooldownPanels:OpenEditor()
            end
        else
            KDT:Print("CooldownPanels module not loaded.")
        end
    end)
    yPos = yPos - 40
    
    local cpTip = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cpTip:SetPoint("TOPLEFT", 15, yPos)
    cpTip:SetText("|cFF666666Also: Keybind > Addons > KDT > Toggle Cooldown Panels|r")
    cpTip:SetTextColor(0.4, 0.4, 0.4)
    yPos = yPos - 20
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Visibility & Fading (Frames) - inline settings like original QoL addon
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Visibility & Fading (Frames)", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -12
    
    -- Description
    local visTitle = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    visTitle:SetPoint("TOPLEFT", 15, yPos)
    visTitle:SetText("|cffffd200Visibility rules|r")
    yPos = yPos - 18
    
    local visDesc = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    visDesc:SetPoint("TOPLEFT", 15, yPos)
    visDesc:SetPoint("TOPRIGHT", -15, yPos)
    visDesc:SetJustifyH("LEFT")
    visDesc:SetText("Combine the same triggers for Blizzard unit frames.\nMouseover can be layered with combat or other checks.")
    visDesc:SetTextColor(0.6, 0.6, 0.6)
    visDesc:SetSpacing(2)
    yPos = yPos - 32
    
    -- Known Blizzard frames with labels
    local KNOWN_VIS_FRAMES = {
        { name = "BagsBar",        label = "Bags Bar" },
        { name = "BossTargetFrameContainer", label = "Boss Frames" },
        { name = "FocusFrame",     label = "Focus Frame" },
        { name = "MicroMenuContainer", label = "Micro Menu" },
        { name = "PetFrame",       label = "Pet Frame" },
        { name = "PlayerFrame",    label = "Player Frame" },
        { name = "TargetFrame",    label = "Target Frame" },
        { name = "PartyFrame",     label = "Party Frames" },
        { name = "BuffFrame",      label = "Buff Frame" },
        { name = "ObjectiveTrackerFrame", label = "Objectives" },
        { name = "MinimapCluster", label = "Minimap" },
    }
    
    -- Trigger options (None + all rules from Visibility helper)
    local TRIGGER_OPTIONS = {
        { key = "",             label = "(None)" },
        { key = "MOUSEOVER",   label = "Mouseover" },
        { key = "IN_COMBAT",   label = "In Combat" },
        { key = "OUT_OF_COMBAT", label = "Out of Combat" },
        { key = "IN_GROUP",    label = "In Group" },
        { key = "IN_PARTY",    label = "In Party" },
        { key = "IN_RAID",     label = "In Raid" },
        { key = "SOLO",        label = "Solo" },
        { key = "IN_INSTANCE", label = "In Instance" },
        { key = "MOUNTED",     label = "Mounted" },
        { key = "SKYRIDING",   label = "Skyriding" },
        { key = "HAS_TARGET",  label = "Has Target" },
        { key = "CASTING",     label = "Casting" },
    }
    
    -- Ensure DB
    local function EnsureVisRules()
        if not KDT.DB then return {} end
        if not KDT.DB.qol then KDT.DB.qol = {} end
        if not KDT.DB.qol.visibilityRules then KDT.DB.qol.visibilityRules = {} end
        return KDT.DB.qol.visibilityRules
    end
    
    -- Apply visibility rules via the Visibility module
    local function ApplyVisibilityRules()
        local Vis = KDT.Visibility
        if not Vis then return end
        
        local rules = EnsureVisRules()
        local fadeAmount = (KDT.DB.qol and KDT.DB.qol.visibilityFadeAmount or 100) / 100
        
        -- Delete existing KDT-managed configs
        local root = Vis.GetRoot and Vis:GetRoot()
        if root and root.configs then
            local toDelete = {}
            for configId, cfg in pairs(root.configs) do
                if cfg and cfg.name and cfg.name:find("^KDT: ") then
                    table.insert(toDelete, configId)
                end
            end
            for _, id in ipairs(toDelete) do
                Vis:DeleteConfig(id)
            end
        end
        
        -- Create new configs for each frame with a rule
        for frameName, triggerKey in pairs(rules) do
            if triggerKey and triggerKey ~= "" then
                local configId = Vis:CreateConfig("KDT: " .. frameName)
                if configId then
                    Vis:AddFrame(configId, frameName)
                    
                    -- Set config properties
                    root = Vis:GetRoot()
                    if root and root.configs and root.configs[configId] then
                        local cfg = root.configs[configId]
                        cfg.enabled = true
                        cfg.mode = "SHOW"  -- Show when condition met
                        cfg.fadeAlpha = 1 - fadeAmount  -- 0 = fully visible, 1 = fully hidden
                        cfg.rules = {
                            op = "AND",
                            children = {
                                { key = triggerKey }
                            }
                        }
                    end
                end
            end
        end
        
        -- Apply
        if Vis.RequestUpdate then
            Vis:RequestUpdate()
        elseif Vis.ApplyAll then
            Vis:ApplyAll()
        end
    end
    
    -- Build dropdown for a single frame
    local function CreateVisFrameDropdown(parent, frameInfo, yOff)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", 15, yOff)
        row:SetPoint("TOPRIGHT", -15, yOff)
        row:SetHeight(28)
        
        -- Label
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", 0, 0)
        label:SetText(frameInfo.label)
        label:SetTextColor(0.85, 0.85, 0.85)
        
        -- Dropdown button
        local dd = CreateFrame("Button", nil, row, "BackdropTemplate")
        dd:SetPoint("RIGHT", 0, 0)
        dd:SetSize(200, 26)
        dd:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        dd:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dd:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        
        dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dd.text:SetPoint("LEFT", 8, 0)
        dd.text:SetPoint("RIGHT", -20, 0)
        dd.text:SetJustifyH("LEFT")
        dd.text:SetTextColor(1, 1, 1)
        
        dd.arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dd.arrow:SetPoint("RIGHT", -6, 0)
        dd.arrow:SetText("v")
        dd.arrow:SetTextColor(0.6, 0.6, 0.6)
        
        -- Set initial text
        local rules = EnsureVisRules()
        local current = rules[frameInfo.name] or ""
        local currentLabel = "(None)"
        for _, opt in ipairs(TRIGGER_OPTIONS) do
            if opt.key == current then currentLabel = opt.label; break end
        end
        dd.text:SetText(currentLabel)
        
        -- Hover
        dd:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.18, 1)
            self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        end)
        dd:SetScript("OnLeave", function(self)
            if not self.menu or not self.menu:IsShown() then
                self:SetBackdropColor(0.12, 0.12, 0.14, 1)
                self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
            end
        end)
        
        -- Menu
        local menu = CreateFrame("Frame", nil, dd, "BackdropTemplate")
        menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
        menu:SetPoint("TOPRIGHT", dd, "BOTTOMRIGHT", 0, -2)
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        menu:SetBackdropColor(0.10, 0.10, 0.12, 1)
        menu:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(dd:GetFrameLevel() + 20)
        menu:Hide()
        dd.menu = menu
        
        local menuY = -2
        for _, opt in ipairs(TRIGGER_OPTIONS) do
            local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
            btn:SetPoint("TOPLEFT", 2, menuY)
            btn:SetPoint("TOPRIGHT", -2, menuY)
            btn:SetHeight(22)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetText(opt.label)
            btn.text:SetTextColor(1, 1, 1)
            
            btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.8, 0.2, 0.2, 0.3) end)
            btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
            btn:SetScript("OnClick", function()
                local r = EnsureVisRules()
                if opt.key == "" then
                    r[frameInfo.name] = nil
                else
                    r[frameInfo.name] = opt.key
                end
                dd.text:SetText(opt.label)
                menu:Hide()
                dd:SetBackdropColor(0.12, 0.12, 0.14, 1)
                dd:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
                ApplyVisibilityRules()
            end)
            
            btn:Show()
            menuY = menuY - 22
        end
        menu:SetHeight(math.abs(menuY) + 4)
        
        dd:SetScript("OnClick", function(self)
            if self.menu:IsShown() then
                self.menu:Hide()
                self:SetBackdropColor(0.12, 0.12, 0.14, 1)
                self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
            else
                self.menu:Show()
            end
        end)
        
        return row, yOff - 32
    end
    
    -- Create a dropdown row for each known frame
    for _, frameInfo in ipairs(KNOWN_VIS_FRAMES) do
        local _, newY = CreateVisFrameDropdown(s.content, frameInfo, yPos)
        yPos = newY
    end
    
    yPos = yPos - 10
    
    -- Fade amount slider
    local fadeLabel = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fadeLabel:SetPoint("TOPLEFT", 15, yPos)
    fadeLabel:SetText("Fade amount")
    fadeLabel:SetTextColor(0.85, 0.85, 0.85)
    
    local fadeValue = s.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fadeValue:SetPoint("TOPRIGHT", -15, yPos)
    fadeValue:SetTextColor(0.2, 0.8, 0.2)
    
    yPos = yPos - 22
    
    local slider = CreateFrame("Slider", nil, s.content, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", 15, yPos)
    slider:SetPoint("TOPRIGHT", -60, yPos)
    slider:SetHeight(16)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(5)
    slider:SetObeyStepOnDrag(true)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    slider:SetBackdropColor(0.12, 0.12, 0.14, 1)
    slider:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    
    -- Thumb texture
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 16)
    thumb:SetColorTexture(0.6, 0.6, 0.6, 1)
    slider:SetThumbTexture(thumb)
    
    local currentFade = (KDT.DB and KDT.DB.qol and KDT.DB.qol.visibilityFadeAmount) or 100
    slider:SetValue(currentFade)
    fadeValue:SetText(currentFade)
    
    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val + 0.5)
        fadeValue:SetText(val)
        if KDT.DB and KDT.DB.qol then
            KDT.DB.qol.visibilityFadeAmount = val
        end
        ApplyVisibilityRules()
    end)
    
    yPos = yPos - 30
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    -- Expose for external use & apply saved rules on startup
    KDT.ApplyVisibilityRules = ApplyVisibilityRules
    C_Timer.After(3, ApplyVisibilityRules)
    
    -- Trade & Mail Log
    sectionY = sectionY - 37
    s = CreateCollapsibleSection(scrollChild, "Trade & Mail Log", sectionY)
    s.category = "Interface"
    table.insert(frame.uitweaksElements, s)
    table.insert(allSections, s)
    
    yPos = -20
    _, yPos = CreateQoLCheckbox(s.content, "Enable Trade & Mail Logging", "enableTradeMailLog", yPos,
        "Records all trades and mail sent/received with items and gold.",
        function(checked)
            if checked then
                KDT:InitTradeMailLog()
                KDT:Print("Trade & Mail Log enabled. Requires /reload for full activation.")
            end
        end)
    _, yPos = CreateSeparator(s.content, yPos)
    
    CreateActionButton(s.content, "|cFFFFD200Show Trade & Mail Log|r", 15, yPos - 5, 220, function()
        KDT:ShowTradeMailLog()
    end)
    yPos = yPos - 40
    s.content:SetHeight(math.abs(yPos) + 20)
    s.content:Hide()
    
    return sectionY
end
function KDT:CreateUITweaksTab(frame)
    local content = frame.content
    
    -- ==================== CATEGORY BUTTONS ====================
    local CATEGORIES = {"Interface", "General", "Gameplay", "Social", "Economy", "Chat"}
    local activeCategory = "Interface"
    local categoryButtons = {}
    
    local catBar = CreateFrame("Frame", nil, content, "BackdropTemplate")
    catBar:SetPoint("TOPLEFT", 10, -8)
    catBar:SetPoint("TOPRIGHT", -10, -8)
    catBar:SetHeight(30)
    catBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    catBar:SetBackdropColor(0.06, 0.06, 0.08, 1)
    catBar:SetBackdropBorderColor(0.15, 0.15, 0.20, 1)
    table.insert(frame.uitweaksElements, catBar)
    
    local btnWidth = 1 / #CATEGORIES
    
    for i, catName in ipairs(CATEGORIES) do
        local btn = CreateFrame("Button", nil, catBar, "BackdropTemplate")
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        
        -- Position: evenly distribute across the bar
        btn:SetPoint("TOPLEFT", catBar, "TOPLEFT", (i - 1) * (1 / #CATEGORIES) * catBar:GetWidth(), 0)
        btn:SetPoint("BOTTOMLEFT", catBar, "BOTTOMLEFT", (i - 1) * (1 / #CATEGORIES) * catBar:GetWidth(), 0)
        btn:SetWidth(1) -- will be updated on resize
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", 0, 0)
        btn.text:SetText(catName)
        btn.categoryName = catName
        
        categoryButtons[i] = btn
    end
    
    -- Function to update button sizes and styles
    local function UpdateCategoryButtons()
        local barWidth = catBar:GetWidth()
        local perBtn = math.floor(barWidth / #CATEGORIES)
        
        for i, btn in ipairs(categoryButtons) do
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", catBar, "TOPLEFT", (i - 1) * perBtn, 0)
            btn:SetSize(perBtn, 30)
            
            if btn.categoryName == activeCategory then
                btn:SetBackdropColor(0.7, 0.15, 0.15, 1)
                btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
                btn.text:SetTextColor(1, 1, 1)
            else
                btn:SetBackdropColor(0.10, 0.10, 0.12, 1)
                btn:SetBackdropBorderColor(0.20, 0.20, 0.25, 1)
                btn.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end
    
    catBar:HookScript("OnSizeChanged", function() UpdateCategoryButtons() end)
    
    -- ==================== SCROLL FRAME (below category bar) ====================
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 0, -44)
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
    
    -- ==================== ECONOMY SECTIONS ====================
    sectionY = CreateEconomySections(scrollChild, frame, allSections, sectionY)
    
    -- ==================== GAMEPLAY SECTIONS ====================
    sectionY = CreateGameplaySections(scrollChild, frame, allSections, sectionY)
    
    -- ==================== SOCIAL SECTIONS ====================
    sectionY = CreateSocialSections(scrollChild, frame, allSections, sectionY)
    
    -- ==================== CHAT SECTIONS ====================
    sectionY = CreateChatSections(scrollChild, frame, allSections, sectionY)
    
    -- ==================== GENERAL SECTIONS ====================
    sectionY = CreateGeneralSections(scrollChild, frame, allSections, sectionY)
    
    -- ==================== INTERFACE SECTIONS ====================
    sectionY = CreateInterfaceSections(scrollChild, frame, allSections, sectionY)
    
    -- ==================== SCROLL HEIGHT MANAGEMENT ====================
    local function UpdateScrollHeight()
        local totalHeight = 20  -- Initial padding
        
        for _, section in ipairs(allSections) do
            if section.category == activeCategory then
                section:Show()
                -- Restore expanded state when switching back to this category
                if section.isExpanded then
                    section.content:Show()
                    section.icon:SetText("-")
                else
                    section.content:Hide()
                    section.icon:SetText("+")
                end
                totalHeight = totalHeight + 32 + 5
                if section.isExpanded and section.content:IsShown() then
                    totalHeight = totalHeight + (section.content:GetHeight() or 0) + 2
                end
            else
                section:Hide()
                section.content:Hide()
            end
        end
        
        totalHeight = totalHeight + 50
        scrollChild:SetHeight(totalHeight)
        
        -- Reposition only visible sections
        local currentY = -20
        for _, section in ipairs(allSections) do
            if section.category == activeCategory then
                section:ClearAllPoints()
                section:SetPoint("TOPLEFT", 15, currentY)
                section:SetPoint("TOPRIGHT", -15, currentY)
                currentY = currentY - 32 - 5
                if section.isExpanded and section.content:IsShown() then
                    currentY = currentY - (section.content:GetHeight() or 0) - 2
                end
            end
        end
        
        scrollFrame:SetVerticalScroll(0)
    end
    
    -- Category button click handler
    local function SetActiveCategory(catName)
        activeCategory = catName
        UpdateCategoryButtons()
        UpdateScrollHeight()
    end
    
    for _, btn in ipairs(categoryButtons) do
        btn:SetScript("OnClick", function(self)
            SetActiveCategory(self.categoryName)
        end)
        btn:SetScript("OnEnter", function(self)
            if self.categoryName ~= activeCategory then
                self:SetBackdropColor(0.15, 0.15, 0.18, 1)
                self.text:SetTextColor(0.85, 0.85, 0.85)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if self.categoryName ~= activeCategory then
                self:SetBackdropColor(0.10, 0.10, 0.12, 1)
                self.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end)
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
            -- Gold tracking display refresh when expanding
            if self._updateGoldDisplay and self.isExpanded then
                C_Timer.After(0.1, self._updateGoldDisplay)
            end
        end)
    end
    
    -- Initial setup
    C_Timer.After(0.1, function()
        UpdateCategoryButtons()
        UpdateScrollHeight()
    end)
    
    frame.RefreshUITweaks = function(self)
        UpdateScrollHeight()
    end
end
