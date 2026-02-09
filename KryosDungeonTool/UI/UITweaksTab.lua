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

-- Create UI Tweaks tab content
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
    
    local mouseCursorSection = CreateCollapsibleSection(scrollChild, "Mouse Cursor", -20)
    table.insert(frame.uitweaksElements, mouseCursorSection)
    mouseCursorSection.sectionName = "MouseCursor"  -- For tracking
    -- DON'T add content to uitweaksElements! 
    -- MainFrame.lua calls Show() on all elements when tab opens
    
    -- Initialize section as closed
    mouseCursorSection.isExpanded = false
    mouseCursorSection.icon:SetText("+")
    
    local yPos = -20
    
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
    
    -- Set correct Mouse Cursor content height based on actual content
    local mouseCursorContentHeight = math.abs(yPos) + 20  -- Add padding
    mouseCursorSection.content:SetHeight(mouseCursorContentHeight)
    
    scrollChild:SetHeight(math.abs(yPos) + 50)
    
    -- IMPORTANT: Hide content AFTER all UI elements are created
    -- This ensures the content is actually hidden on initial load
    mouseCursorSection.content:Hide()
    
    -- ==================== TALENTS SECTION ====================
    -- Position relative to Mouse Cursor Section, not absolute
    local talentsSection = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    talentsSection:SetHeight(32)
    talentsSection:SetPoint("TOPLEFT", mouseCursorSection, "BOTTOMLEFT", 0, -5)
    talentsSection:SetPoint("TOPRIGHT", mouseCursorSection, "BOTTOMRIGHT", 0, -5)
    talentsSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    talentsSection:SetBackdropColor(0.08, 0.08, 0.10, 1)
    talentsSection:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    talentsSection.isExpanded = false
    
    talentsSection:EnableMouse(true)
    talentsSection:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.10, 0.12, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    talentsSection:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.10, 1)
        self:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    end)
    
    talentsSection.icon = talentsSection:CreateFontString(nil, "OVERLAY")
    talentsSection.icon:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    talentsSection.icon:SetPoint("LEFT", 12, 0)
    talentsSection.icon:SetText("+")
    talentsSection.icon:SetTextColor(0.8, 0.2, 0.2)
    
    talentsSection.title = talentsSection:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    talentsSection.title:SetPoint("LEFT", 38, 0)
    talentsSection.title:SetText("Talents (Requires PeaversTalentsData)")
    talentsSection.title:SetTextColor(1, 1, 1)
    
    talentsSection.content = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    talentsSection.content:SetPoint("TOPLEFT", talentsSection, "BOTTOMLEFT", 0, -2)
    talentsSection.content:SetPoint("TOPRIGHT", talentsSection, "BOTTOMRIGHT", 0, -2)
    talentsSection.content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    talentsSection.content:SetBackdropColor(0.03, 0.03, 0.05, 0.95)
    talentsSection.content:SetBackdropBorderColor(0.15, 0.15, 0.20, 1)
    talentsSection.content:Hide()
    
    talentsSection.content:HookScript("OnShow", function(self)
        if not talentsSection.isExpanded then
            self:Hide()
        end
    end)
    
    table.insert(frame.uitweaksElements, talentsSection)
    talentsSection.sectionName = "Talents"
    
    -- Forward declare UpdateScrollHeight so it can be called from toggle handlers
    local UpdateScrollHeight
    
    -- Function to recalculate scroll height and reposition sections
    UpdateScrollHeight = function()
        local totalHeight = 20  -- Initial padding
        
        -- Mouse Cursor Section
        totalHeight = totalHeight + 32 + 5  -- Header + spacing
        if mouseCursorSection.isExpanded and mouseCursorSection.content:IsShown() then
            totalHeight = totalHeight + (mouseCursorSection.content:GetHeight() or 0) + 2
        end
        
        -- Reposition Talents Section based on Mouse Cursor state
        talentsSection:ClearAllPoints()
        if mouseCursorSection.isExpanded and mouseCursorSection.content:IsShown() then
            -- Position below Mouse Cursor content
            talentsSection:SetPoint("TOPLEFT", mouseCursorSection.content, "BOTTOMLEFT", 0, -5)
            talentsSection:SetPoint("TOPRIGHT", mouseCursorSection.content, "BOTTOMRIGHT", 0, -5)
        else
            -- Position directly below Mouse Cursor header
            talentsSection:SetPoint("TOPLEFT", mouseCursorSection, "BOTTOMLEFT", 0, -5)
            talentsSection:SetPoint("TOPRIGHT", mouseCursorSection, "BOTTOMRIGHT", 0, -5)
        end
        
        -- Talents Section
        totalHeight = totalHeight + 32 + 5  -- Header + spacing
        if talentsSection.isExpanded and talentsSection.content:IsShown() then
            totalHeight = totalHeight + (talentsSection.content:GetHeight() or 0) + 2
        end
        
        totalHeight = totalHeight + 50  -- Bottom padding
        scrollChild:SetHeight(totalHeight)
    end
    
    -- Add toggle handler to Mouse Cursor Section
    mouseCursorSection:SetScript("OnMouseDown", function(self)
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
    
    -- Check if PeaversTalentsData is available
    local function IsPTDAvailable()
        return KDT.Talents and KDT.Talents:IsAvailable()
    end
    
    if not IsPTDAvailable() then
        local warningText = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warningText:SetPoint("TOP", 0, -20)
        warningText:SetText("|cFFFF4444PeaversTalentsData addon not found!|r\n\nInstall PeaversTalentsData to use this feature.\nIt provides talent builds from Archon, Wowhead, Icy-Veins, and U.gg")
        warningText:SetJustifyH("CENTER")
        warningText:SetTextColor(1, 0.7, 0.7)
        talentsSection.content:Hide()
        return
    end
    
    local tYPos = -20
    local selectedClassID, selectedSpecID = KDT.Talents:GetPlayerInfo()
    local selectedContentType = "mythic"
    local selectedDungeonID = 0
    local selectedSources = {archon = true, ["icy-veins"] = true, wowhead = true, ugg = true}
    local currentBuilds = {}
    
    -- Info text
    local infoText = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 15, tYPos)
    infoText:SetPoint("TOPRIGHT", -15, tYPos)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Browse and load talent builds from top players and theorycrafters.")
    infoText:SetTextColor(0.7, 0.7, 0.7)
    tYPos = tYPos - 30
    
    -- Class/Spec selection header
    local classSpecHeader = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classSpecHeader:SetPoint("TOPLEFT", 15, tYPos)
    classSpecHeader:SetText("Class & Specialization:")
    classSpecHeader:SetTextColor(1, 0.82, 0)
    
    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, talentsSection.content, "BackdropTemplate")
    refreshBtn:SetSize(70, 20)
    refreshBtn:SetPoint("TOPRIGHT", -15, tYPos + 2)
    refreshBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    refreshBtn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    refreshBtn:SetBackdropBorderColor(0.3, 0.6, 1, 1)
    
    refreshBtn.text = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    refreshBtn.text:SetPoint("CENTER")
    refreshBtn.text:SetText("Refresh")
    refreshBtn.text:SetTextColor(0.4, 0.8, 1)
    
    refreshBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.6, 1)
        self:SetBackdropBorderColor(0.4, 0.8, 1, 1)
    end)
    refreshBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.3, 0.6, 1, 1)
    end)
    
    tYPos = tYPos - 25
    
    -- Class/Spec display text
    local classSpecText = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    classSpecText:SetPoint("TOPLEFT", 15, tYPos)
    
    local function UpdateClassSpecText()
        -- Get fresh player info
        selectedClassID, selectedSpecID = KDT.Talents:GetPlayerInfo()
        
        if selectedClassID and selectedSpecID then
            local specInfo = KDT.Talents:GetSpecInfo(selectedClassID, selectedSpecID)
            if specInfo then
                local className = select(2, GetClassInfo(selectedClassID))
                classSpecText:SetText(specInfo.name .. " " .. className)
                
                local r, g, b = GetClassColor(select(2, GetClassInfo(selectedClassID)))
                classSpecText:SetTextColor(r, g, b)
                return true
            end
        end
        
        -- No spec selected
        classSpecText:SetText("No spec selected - Click Refresh")
        classSpecText:SetTextColor(1, 0.5, 0.5)
        return false
    end
    
    -- Refresh button click handler
    refreshBtn:SetScript("OnClick", function()
        UpdateClassSpecText()
        if RefreshBuildsList then
            RefreshBuildsList()
        end
    end)
    
    -- Initial update
    UpdateClassSpecText()
    tYPos = tYPos - 35
    
    -- Content Type buttons
    local contentTypeHeader = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentTypeHeader:SetPoint("TOPLEFT", 15, tYPos)
    contentTypeHeader:SetText("Content Type:")
    contentTypeHeader:SetTextColor(1, 0.82, 0)
    tYPos = tYPos - 25
    
    local contentTypes = {
        {id = "mythic", label = "Mythic+"},
        {id = "raid", label = "Raid"},
        {id = "heroic_raid", label = "Heroic Raid"},
        {id = "mythic_raid", label = "Mythic Raid"},
    }
    
    local contentButtons = {}
    local btnX = 15
    local UpdateContentButtons -- Forward declaration
    local RefreshBuildsList -- Forward declaration
    
    for _, ct in ipairs(contentTypes) do
        local btn = CreateFrame("Button", nil, talentsSection.content, "BackdropTemplate")
        btn:SetSize(95, 26)
        btn:SetPoint("TOPLEFT", btnX, tYPos)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        btn.contentType = ct.id
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(ct.label)
        
        btn:SetScript("OnClick", function(self)
            selectedContentType = self.contentType
            UpdateContentButtons()
            RefreshBuildsList()
        end)
        
        btn:SetScript("OnEnter", function(self)
            if self.contentType ~= selectedContentType then
                self:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.5)
            end
        end)
        
        btn:SetScript("OnLeave", function(self)
            UpdateContentButtons()
        end)
        
        table.insert(contentButtons, btn)
        btnX = btnX + 100
    end
    
    tYPos = tYPos - 35
    
    -- Dungeon selection (only for Mythic+)
    local dungeonHeader = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonHeader:SetPoint("TOPLEFT", 15, tYPos)
    dungeonHeader:SetText("Dungeon:")
    dungeonHeader:SetTextColor(1, 0.82, 0)
    
    local dungeonDropdown = CreateFrame("Button", nil, talentsSection.content, "BackdropTemplate")
    dungeonDropdown:SetSize(250, 26)
    dungeonDropdown:SetPoint("TOPLEFT", 100, tYPos + 3)
    dungeonDropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dungeonDropdown:SetBackdropColor(0.12, 0.12, 0.14, 1)
    dungeonDropdown:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    
    dungeonDropdown.text = dungeonDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonDropdown.text:SetPoint("LEFT", 8, 0)
    dungeonDropdown.text:SetPoint("RIGHT", -20, 0)
    dungeonDropdown.text:SetJustifyH("LEFT")
    dungeonDropdown.text:SetText(KDT.Talents:FormatDungeon(0))
    
    dungeonDropdown.arrow = dungeonDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonDropdown.arrow:SetPoint("RIGHT", -6, 0)
    dungeonDropdown.arrow:SetText("v")
    dungeonDropdown.arrow:SetTextColor(0.6, 0.6, 0.6)
    
    dungeonDropdown:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end)
    dungeonDropdown:SetScript("OnLeave", function(self)
        if not self.menu or not self.menu:IsShown() then
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
        end
    end)
    
    -- Create dungeon dropdown menu
    local dungeonMenu = CreateFrame("Frame", nil, dungeonDropdown, "BackdropTemplate")
    dungeonMenu:SetPoint("TOPLEFT", dungeonDropdown, "BOTTOMLEFT", 0, -2)
    dungeonMenu:SetPoint("TOPRIGHT", dungeonDropdown, "BOTTOMRIGHT", 0, -2)
    dungeonMenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dungeonMenu:SetBackdropColor(0.10, 0.10, 0.12, 1)
    dungeonMenu:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    dungeonMenu:SetFrameStrata("DIALOG")
    dungeonMenu:SetFrameLevel(dungeonDropdown:GetFrameLevel() + 10)
    dungeonMenu:Hide()
    dungeonDropdown.menu = dungeonMenu
    
    dungeonMenu.buttons = {}
    
    local function BuildDungeonMenu()
        -- Clear existing buttons
        for _, btn in ipairs(dungeonMenu.buttons) do
            btn:Hide()
        end
        wipe(dungeonMenu.buttons)
        
        -- Get all dungeon options
        local dungeonOptions = {}
        for id = 0, 8 do
            table.insert(dungeonOptions, {
                id = id,
                name = KDT.Talents:FormatDungeon(id)
            })
        end
        
        local yPos = -2
        for i, option in ipairs(dungeonOptions) do
            local btn = CreateFrame("Button", nil, dungeonMenu, "BackdropTemplate")
            btn:SetPoint("TOPLEFT", 2, yPos)
            btn:SetPoint("TOPRIGHT", -2, yPos)
            btn:SetHeight(24)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8"
            })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetText(option.name)
            btn.text:SetTextColor(1, 1, 1)
            
            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.8, 0.2, 0.2, 0.3)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)
            btn:SetScript("OnClick", function(self)
                selectedDungeonID = option.id
                dungeonDropdown.text:SetText(option.name)
                dungeonMenu:Hide()
                RefreshBuildsList()
            end)
            
            btn:Show()
            dungeonMenu.buttons[i] = btn
            yPos = yPos - 24
        end
        
        dungeonMenu:SetHeight(math.abs(yPos) + 2)
    end
    
    dungeonDropdown:SetScript("OnClick", function(self)
        if dungeonMenu:IsShown() then
            dungeonMenu:Hide()
        else
            BuildDungeonMenu()
            dungeonMenu:Show()
        end
    end)
    
    dungeonMenu:SetScript("OnHide", function(self)
        dungeonDropdown:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dungeonDropdown:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)
    
    -- Now define UpdateContentButtons after all elements exist
    UpdateContentButtons = function()
        for _, btn in ipairs(contentButtons) do
            if btn.contentType == selectedContentType then
                btn:SetBackdropColor(0.8, 0.2, 0.2, 1)
                btn:SetBackdropBorderColor(1, 0.3, 0.3, 1)
            else
                btn:SetBackdropColor(0.12, 0.12, 0.14, 1)
                btn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
            end
        end
        
        -- Show/hide dungeon dropdown based on content type
        if selectedContentType == "mythic" then
            dungeonHeader:Show()
            dungeonDropdown:Show()
        else
            dungeonHeader:Hide()
            dungeonDropdown:Hide()
            -- Reset dungeon selection when switching away from Mythic+
            selectedDungeonID = 0
            dungeonDropdown.text:SetText(KDT.Talents:FormatDungeon(0))
        end
    end
    
    -- Initial call to set correct visibility
    UpdateContentButtons()
    
    tYPos = tYPos - 35
    
    -- Source filters
    local sourceHeader = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceHeader:SetPoint("TOPLEFT", 15, tYPos)
    sourceHeader:SetText("Sources:")
    sourceHeader:SetTextColor(1, 0.82, 0)
    tYPos = tYPos - 25
    
    local sources = {"archon", "icy-veins", "wowhead", "ugg"}
    local sourceCheckboxes = {}
    btnX = 15
    
    for _, source in ipairs(sources) do
        local container = CreateFrame("Frame", nil, talentsSection.content)
        container:SetSize(110, 24)
        container:SetPoint("TOPLEFT", btnX, tYPos)
        
        local cb = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("LEFT", 0, 0)
        cb:SetChecked(selectedSources[source])
        cb.source = source
        
        local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        label:SetText(KDT.Talents:FormatSource(source))
        local r, g, b = unpack(KDT.Talents:GetSourceColor(source))
        label:SetTextColor(r, g, b)
        
        cb:SetScript("OnClick", function(self)
            selectedSources[self.source] = self:GetChecked()
            RefreshBuildsList()
        end)
        
        sourceCheckboxes[source] = cb
        btnX = btnX + 115
    end
    tYPos = tYPos - 35
    
    -- Talent warning checkbox
    local warnCheckContainer = CreateFrame("Frame", nil, talentsSection.content)
    warnCheckContainer:SetSize(400, 24)
    warnCheckContainer:SetPoint("TOPLEFT", 15, tYPos)
    
    local warnCheckbox = CreateFrame("CheckButton", nil, warnCheckContainer, "UICheckButtonTemplate")
    warnCheckbox:SetSize(20, 20)
    warnCheckbox:SetPoint("LEFT", 0, 0)
    warnCheckbox:SetChecked(KDT.DB.talentWarningEnabled or false)
    
    local warnLabel = warnCheckContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnLabel:SetPoint("LEFT", warnCheckbox, "RIGHT", 5, 0)
    warnLabel:SetText("Warn when entering dungeon/raid with non-matching talents")
    warnLabel:SetTextColor(1, 0.82, 0)
    
    warnCheckbox:SetScript("OnClick", function(self)
        KDT.DB.talentWarningEnabled = self:GetChecked()
    end)
    
    tYPos = tYPos - 35
    
    -- Separator
    local sep1 = talentsSection.content:CreateTexture(nil, "ARTWORK")
    sep1:SetColorTexture(0.25, 0.25, 0.30, 0.6)
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", 15, tYPos)
    sep1:SetPoint("TOPRIGHT", -15, tYPos)
    tYPos = tYPos - 15
    
    -- Builds list header
    local buildsHeader = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildsHeader:SetPoint("TOPLEFT", 15, tYPos)
    buildsHeader:SetText("Available Builds:")
    buildsHeader:SetTextColor(1, 0.82, 0)
    tYPos = tYPos - 20
    
    -- Data freshness warning
    local dataWarning = talentsSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dataWarning:SetPoint("TOPLEFT", 15, tYPos)
    dataWarning:SetPoint("TOPRIGHT", -15, tYPos)
    dataWarning:SetText("Note: Talent data depends on PeaversTalentsData addon. Update it regularly for current season builds.")
    dataWarning:SetTextColor(1, 0.7, 0.3)
    dataWarning:SetJustifyH("LEFT")
    dataWarning:SetWordWrap(true)
    tYPos = tYPos - 35
    
    -- Calculate and set content height based on elements + scroll area
    -- tYPos is negative, so we need absolute value + space for builds list (450px)
    local contentHeight = math.abs(tYPos) + 450
    talentsSection.content:SetHeight(contentHeight)
    
    -- Builds scroll frame
    local buildsScroll = CreateFrame("ScrollFrame", nil, talentsSection.content)
    buildsScroll:SetPoint("TOPLEFT", 15, tYPos)
    buildsScroll:SetPoint("BOTTOMRIGHT", -15, 15)
    
    local buildsContent = CreateFrame("Frame", nil, buildsScroll)
    buildsContent:SetSize(buildsScroll:GetWidth(), 400)
    buildsScroll:SetScrollChild(buildsContent)
    
    buildsScroll:EnableMouseWheel(true)
    buildsScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 30)))
        self:SetVerticalScroll(newScroll)
    end)
    
    local buildRows = {}
    
    RefreshBuildsList = function()
        -- Hide all existing rows
        for _, row in ipairs(buildRows) do
            row:Hide()
        end
        
        if not selectedClassID or not selectedSpecID then
            -- Show a message that no class/spec is selected
            if buildRows[1] then
                -- Reuse first row for message
                local msgRow = buildRows[1]
                msgRow:SetHeight(60)
                msgRow:ClearAllPoints()
                msgRow:SetPoint("TOPLEFT", 0, -5)
                msgRow:SetPoint("TOPRIGHT", -5, -5)
                msgRow:SetBackdropColor(0.15, 0.08, 0.08, 1)
                msgRow:SetBackdropBorderColor(1, 0.3, 0.3, 1)
                
                if not msgRow.messageText then
                    msgRow.messageText = msgRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    msgRow.messageText:SetPoint("CENTER")
                    msgRow.messageText:SetJustifyH("CENTER")
                end
                
                msgRow.messageText:SetText("No class/spec detected.\nPlease click the 'Refresh' button to detect your character.")
                msgRow.messageText:SetTextColor(1, 0.7, 0.7)
                msgRow:Show()
            end
            return
        end
        
        -- Get builds from selected sources
        local allBuilds = {}
        for source, enabled in pairs(selectedSources) do
            if enabled then
                -- Only use dungeonID for Mythic+ content
                local dungeonID = (selectedContentType == "mythic") and selectedDungeonID or nil
                local builds = KDT.Talents:GetBuilds(selectedClassID, selectedSpecID, source, dungeonID)
                if builds then
                    for _, build in ipairs(builds) do
                        if build.category == selectedContentType then
                            table.insert(allBuilds, build)
                        end
                    end
                end
            end
        end
        
        -- Check if no builds found
        if #allBuilds == 0 then
            if buildRows[1] then
                local msgRow = buildRows[1]
                msgRow:SetHeight(60)
                msgRow:ClearAllPoints()
                msgRow:SetPoint("TOPLEFT", 0, -5)
                msgRow:SetPoint("TOPRIGHT", -5, -5)
                msgRow:SetBackdropColor(0.08, 0.08, 0.15, 1)
                msgRow:SetBackdropBorderColor(0.3, 0.3, 0.8, 1)
                
                if not msgRow.messageText then
                    msgRow.messageText = msgRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    msgRow.messageText:SetPoint("CENTER")
                    msgRow.messageText:SetJustifyH("CENTER")
                end
                
                msgRow.messageText:SetText("No builds found for this selection.\nTry selecting different sources or content type.")
                msgRow.messageText:SetTextColor(0.7, 0.7, 1)
                msgRow:Show()
            end
            buildsContent:SetHeight(100)
            return
        end
        
        -- Create/update rows
        local yPos = -5
        for i, build in ipairs(allBuilds) do
            local row = buildRows[i]
            
            if not row then
                row = CreateFrame("Frame", nil, buildsContent, "BackdropTemplate")
                row:SetPoint("TOPLEFT", 0, 0)
                row:SetPoint("TOPRIGHT", -5, 0)
                row:SetHeight(50)
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1
                })
                
                -- Build info
                row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.nameText:SetPoint("TOPLEFT", 10, -8)
                row.nameText:SetPoint("TOPRIGHT", -120, -8)
                row.nameText:SetJustifyH("LEFT")
                
                row.sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                row.sourceText:SetPoint("TOPLEFT", 10, -26)
                
                -- Copy String button
                row.copyBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
                row.copyBtn:SetSize(90, 20)
                row.copyBtn:SetPoint("TOPRIGHT", -5, -15)
                row.copyBtn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1
                })
                row.copyBtn:SetBackdropColor(0.15, 0.15, 0.18, 1)
                row.copyBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                
                row.copyBtn.text = row.copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                row.copyBtn.text:SetPoint("CENTER")
                row.copyBtn.text:SetText("Copy String")
                
                row.copyBtn:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.2, 0.4, 0.6, 1)
                    self:SetBackdropBorderColor(0.3, 0.6, 1, 1)
                end)
                row.copyBtn:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0.15, 0.15, 0.18, 1)
                    self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                end)
                
                buildRows[i] = row
            end
            
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, yPos)
            row:SetPoint("TOPRIGHT", -5, yPos)
            
            -- Update content
            -- Only show dungeon name for Mythic+ content, not for Raids
            local dungeonText = ""
            if build.category == "mythic" and build.dungeonID then
                dungeonText = KDT.Talents:FormatDungeon(build.dungeonID)
            end
            row.nameText:SetText(dungeonText .. (build.label and ((dungeonText ~= "" and " - " or "") .. build.label) or ""))
            row.nameText:SetTextColor(1, 1, 1)
            
            local r, g, b = unpack(KDT.Talents:GetSourceColor(build.source))
            row.sourceText:SetText(KDT.Talents:FormatSource(build.source))
            row.sourceText:SetTextColor(r, g, b)
            
            local catR, catG, catB = unpack(KDT.Talents:GetCategoryColor(build.category))
            row:SetBackdropColor(catR * 0.15, catG * 0.15, catB * 0.15, 1)
            row:SetBackdropBorderColor(catR * 0.3, catG * 0.3, catB * 0.3, 1)
            
            -- Set button actions
            row.copyBtn:SetScript("OnClick", function()
                if not build.talentString or build.talentString == "" then
                    return
                end
                
                KDT.Talents:CopyToClipboard(build.talentString)
            end)
            
            row:Show()
            yPos = yPos - 55
        end
        
        buildsContent:SetHeight(math.abs(yPos) + 10)
    end
    
    -- Initial refresh
    C_Timer.After(0.1, RefreshBuildsList)
    
    -- Connect content type buttons to refresh
    for _, btn in ipairs(contentButtons) do
        local oldOnClick = btn:GetScript("OnClick")
        btn:SetScript("OnClick", function(self)
            oldOnClick(self)
            RefreshBuildsList()
        end)
    end
    
    -- Hide talents section content initially
    talentsSection.content:Hide()
    
    -- Update Talents toggle handler to include auto-refresh
    talentsSection:SetScript("OnMouseDown", function(self)
        self.isExpanded = not self.isExpanded
        if self.isExpanded then
            self.icon:SetText("-")
            self.content:Show()
            -- Auto-refresh when section is opened
            C_Timer.After(0.1, function()
                UpdateClassSpecText()
                if RefreshBuildsList then
                    RefreshBuildsList()
                end
            end)
        else
            self.icon:SetText("+")
            self.content:Hide()
        end
        UpdateScrollHeight()
    end)
    
    -- Initial height update after all sections are created
    C_Timer.After(0.1, function()
        UpdateScrollHeight()
    end)
    
    frame.RefreshUITweaks = function(self)
        -- Nothing to refresh currently
    end
end
