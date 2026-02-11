-- Kryos Dungeon Tool
-- UI/TalentsTab.lua - Talents Tab (Standalone Module)
-- Extracted from UITweaksTab into its own tab

local addonName, KDT = ...

-- ==================== TALENTS TAB ====================
function KDT:CreateTalentsTab(frame)
    local content = frame.content
    
    -- Initialize element storage
    frame.talentsElements = frame.talentsElements or {}
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(frame.talentsElements, scrollFrame)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(content:GetWidth() - 20, 1200)
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
    
    -- Check if PeaversTalentsData is available
    local function IsPTDAvailable()
        return KDT.Talents and KDT.Talents:IsAvailable()
    end
    
    if not IsPTDAvailable() then
        local warningFrame = CreateFrame("Frame", nil, scrollChild)
        warningFrame:SetPoint("TOPLEFT", 15, -40)
        warningFrame:SetPoint("TOPRIGHT", -15, -40)
        warningFrame:SetHeight(120)
        table.insert(frame.talentsElements, warningFrame)
        
        local warningIcon = warningFrame:CreateFontString(nil, "OVERLAY")
        warningIcon:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
        warningIcon:SetPoint("TOP", 0, 0)
        warningIcon:SetText("!")
        warningIcon:SetTextColor(1, 0.3, 0.3)
        
        local warningText = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        warningText:SetPoint("TOP", warningIcon, "BOTTOM", 0, -10)
        warningText:SetText("|cFFFF4444PeaversTalentsData addon not found!|r")
        
        local warningDesc = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warningDesc:SetPoint("TOP", warningText, "BOTTOM", 0, -10)
        warningDesc:SetText("Install PeaversTalentsData to use this feature.\nIt provides talent builds from Archon, Wowhead, Icy-Veins, and U.gg")
        warningDesc:SetJustifyH("CENTER")
        warningDesc:SetTextColor(0.7, 0.7, 0.7)
        
        frame.RefreshTalents = function() end
        return
    end
    
    -- ==================== STATE ====================
    local selectedClassID, selectedSpecID = KDT.Talents:GetPlayerInfo()
    local selectedContentType = "mythic"
    local selectedDungeonID = 0
    local selectedSources = {archon = true, ["icy-veins"] = true, wowhead = true, ugg = true}
    
    local yPos = -20
    
    -- ==================== INFO TEXT ====================
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 15, yPos)
    infoText:SetPoint("TOPRIGHT", -15, yPos)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Browse and load optimized talent builds from top players and theorycrafters.")
    infoText:SetTextColor(0.7, 0.7, 0.7)
    yPos = yPos - 30
    
    -- ==================== CLASS/SPEC DISPLAY ====================
    local classSpecHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classSpecHeader:SetPoint("TOPLEFT", 15, yPos)
    classSpecHeader:SetText("Class & Specialization:")
    classSpecHeader:SetTextColor(1, 0.82, 0)
    
    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    refreshBtn:SetSize(70, 20)
    refreshBtn:SetPoint("TOPRIGHT", -15, yPos + 2)
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
    
    yPos = yPos - 25
    
    -- Class/Spec text
    local classSpecText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    classSpecText:SetPoint("TOPLEFT", 15, yPos)
    
    local function UpdateClassSpecText()
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
        
        classSpecText:SetText("No spec selected - Click Refresh")
        classSpecText:SetTextColor(1, 0.5, 0.5)
        return false
    end
    
    UpdateClassSpecText()
    yPos = yPos - 35
    
    -- ==================== CONTENT TYPE BUTTONS ====================
    local contentTypeHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentTypeHeader:SetPoint("TOPLEFT", 15, yPos)
    contentTypeHeader:SetText("Content Type:")
    contentTypeHeader:SetTextColor(1, 0.82, 0)
    yPos = yPos - 25
    
    local contentTypes = {
        {id = "mythic", label = "Mythic+"},
        {id = "raid", label = "Raid"},
        {id = "heroic_raid", label = "Heroic Raid"},
        {id = "mythic_raid", label = "Mythic Raid"},
    }
    
    local contentButtons = {}
    local btnX = 15
    local UpdateContentButtons
    local RefreshBuildsList
    
    for _, ct in ipairs(contentTypes) do
        local btn = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
        btn:SetSize(95, 26)
        btn:SetPoint("TOPLEFT", btnX, yPos)
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
    
    yPos = yPos - 35
    
    -- ==================== DUNGEON DROPDOWN ====================
    local dungeonHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonHeader:SetPoint("TOPLEFT", 15, yPos)
    dungeonHeader:SetText("Dungeon:")
    dungeonHeader:SetTextColor(1, 0.82, 0)
    
    local dungeonDropdown = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    dungeonDropdown:SetSize(250, 26)
    dungeonDropdown:SetPoint("TOPLEFT", 100, yPos + 3)
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
    
    -- Dungeon dropdown menu
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
        for _, btn in ipairs(dungeonMenu.buttons) do btn:Hide() end
        wipe(dungeonMenu.buttons)
        
        local menuY = -2
        for id = 0, 8 do
            local btn = CreateFrame("Button", nil, dungeonMenu, "BackdropTemplate")
            btn:SetPoint("TOPLEFT", 2, menuY)
            btn:SetPoint("TOPRIGHT", -2, menuY)
            btn:SetHeight(24)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetText(KDT.Talents:FormatDungeon(id))
            btn.text:SetTextColor(1, 1, 1)
            
            local dungeonID = id
            btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.8, 0.2, 0.2, 0.3) end)
            btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
            btn:SetScript("OnClick", function()
                selectedDungeonID = dungeonID
                dungeonDropdown.text:SetText(KDT.Talents:FormatDungeon(dungeonID))
                dungeonMenu:Hide()
                RefreshBuildsList()
            end)
            
            btn:Show()
            table.insert(dungeonMenu.buttons, btn)
            menuY = menuY - 24
        end
        dungeonMenu:SetHeight(math.abs(menuY) + 2)
    end
    
    dungeonDropdown:SetScript("OnClick", function()
        if dungeonMenu:IsShown() then
            dungeonMenu:Hide()
        else
            BuildDungeonMenu()
            dungeonMenu:Show()
        end
    end)
    
    dungeonMenu:SetScript("OnHide", function()
        dungeonDropdown:SetBackdropColor(0.12, 0.12, 0.14, 1)
        dungeonDropdown:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end)
    
    -- UpdateContentButtons
    UpdateContentButtons = function()
        for _, btn in ipairs(contentButtons) do
            if btn.contentType == selectedContentType then
                btn:SetBackdropColor(0.8, 0.2, 0.2, 1)
                btn:SetBackdropBorderColor(1, 0.3, 0.3, 1)
                btn.text:SetTextColor(1, 1, 1)
            else
                btn:SetBackdropColor(0.12, 0.12, 0.14, 1)
                btn:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
                btn.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
        
        if selectedContentType == "mythic" then
            dungeonHeader:Show()
            dungeonDropdown:Show()
        else
            dungeonHeader:Hide()
            dungeonDropdown:Hide()
            selectedDungeonID = 0
            dungeonDropdown.text:SetText(KDT.Talents:FormatDungeon(0))
        end
    end
    
    UpdateContentButtons()
    yPos = yPos - 35
    
    -- ==================== SOURCE FILTERS ====================
    local sourceHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceHeader:SetPoint("TOPLEFT", 15, yPos)
    sourceHeader:SetText("Sources:")
    sourceHeader:SetTextColor(1, 0.82, 0)
    yPos = yPos - 25
    
    local sources = {"archon", "icy-veins", "wowhead", "ugg"}
    local sourceCheckboxes = {}
    btnX = 15
    
    for _, source in ipairs(sources) do
        local container = CreateFrame("Frame", nil, scrollChild)
        container:SetSize(110, 24)
        container:SetPoint("TOPLEFT", btnX, yPos)
        
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
    yPos = yPos - 35
    
    -- ==================== TALENT WARNING CHECKBOX ====================
    local warnCheckContainer = CreateFrame("Frame", nil, scrollChild)
    warnCheckContainer:SetSize(400, 24)
    warnCheckContainer:SetPoint("TOPLEFT", 15, yPos)
    
    local warnCheckbox = CreateFrame("CheckButton", nil, warnCheckContainer, "UICheckButtonTemplate")
    warnCheckbox:SetSize(20, 20)
    warnCheckbox:SetPoint("LEFT", 0, 0)
    warnCheckbox:SetChecked(KDT.DB and KDT.DB.talentWarningEnabled or false)
    
    local warnLabel = warnCheckContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnLabel:SetPoint("LEFT", warnCheckbox, "RIGHT", 5, 0)
    warnLabel:SetText("Warn when entering dungeon/raid with non-matching talents")
    warnLabel:SetTextColor(1, 0.82, 0)
    
    warnCheckbox:SetScript("OnClick", function(self)
        if KDT.DB then
            KDT.DB.talentWarningEnabled = self:GetChecked()
        end
    end)
    
    yPos = yPos - 35
    
    -- ==================== SEPARATOR ====================
    local sep1 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep1:SetColorTexture(0.25, 0.25, 0.30, 0.6)
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", 15, yPos)
    sep1:SetPoint("TOPRIGHT", -15, yPos)
    yPos = yPos - 15
    
    -- ==================== BUILDS HEADER ====================
    local buildsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildsHeader:SetPoint("TOPLEFT", 15, yPos)
    buildsHeader:SetText("Available Builds:")
    buildsHeader:SetTextColor(1, 0.82, 0)
    yPos = yPos - 20
    
    -- Data freshness note
    local dataWarning = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dataWarning:SetPoint("TOPLEFT", 15, yPos)
    dataWarning:SetPoint("TOPRIGHT", -15, yPos)
    dataWarning:SetText("Note: Talent data depends on PeaversTalentsData addon. Update it regularly for current season builds.")
    dataWarning:SetTextColor(1, 0.7, 0.3)
    dataWarning:SetJustifyH("LEFT")
    dataWarning:SetWordWrap(true)
    yPos = yPos - 35
    
    -- ==================== BUILD ROWS (directly in scrollChild - no nested scroll) ====================
    local buildsStartY = yPos
    local buildRows = {}
    
    -- Helper: Update scrollChild total height based on content
    local function UpdateScrollHeight(endY)
        local totalHeight = math.abs(endY) + 30
        scrollChild:SetHeight(totalHeight)
    end
    
    -- ==================== REFRESH BUILDS ====================
    RefreshBuildsList = function()
        -- Hide all existing rows
        for _, row in ipairs(buildRows) do
            row:Hide()
            if row.messageText then row.messageText:Hide() end
        end
        
        if not selectedClassID or not selectedSpecID then
            if not buildRows[1] then
                buildRows[1] = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                buildRows[1]:SetHeight(60)
                buildRows[1]:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1
                })
            end
            
            local msgRow = buildRows[1]
            msgRow:ClearAllPoints()
            msgRow:SetPoint("TOPLEFT", 15, buildsStartY)
            msgRow:SetPoint("TOPRIGHT", -15, buildsStartY)
            msgRow:SetHeight(60)
            msgRow:SetBackdropColor(0.15, 0.08, 0.08, 1)
            msgRow:SetBackdropBorderColor(1, 0.3, 0.3, 1)
            
            if not msgRow.messageText then
                msgRow.messageText = msgRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                msgRow.messageText:SetPoint("CENTER")
                msgRow.messageText:SetJustifyH("CENTER")
            end
            
            msgRow.messageText:SetText("No class/spec detected.\nPlease click the 'Refresh' button to detect your character.")
            msgRow.messageText:SetTextColor(1, 0.7, 0.7)
            msgRow.messageText:Show()
            msgRow:Show()
            UpdateScrollHeight(buildsStartY - 80)
            return
        end
        
        -- Get builds from selected sources via PeaversTalentsData API
        local allBuilds = {}
        for source, enabled in pairs(selectedSources) do
            if enabled then
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
        
        -- No builds found
        if #allBuilds == 0 then
            if not buildRows[1] then
                buildRows[1] = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                buildRows[1]:SetHeight(60)
                buildRows[1]:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1
                })
            end
            
            local msgRow = buildRows[1]
            msgRow:ClearAllPoints()
            msgRow:SetPoint("TOPLEFT", 15, buildsStartY)
            msgRow:SetPoint("TOPRIGHT", -15, buildsStartY)
            msgRow:SetHeight(60)
            msgRow:SetBackdropColor(0.08, 0.08, 0.15, 1)
            msgRow:SetBackdropBorderColor(0.3, 0.3, 0.8, 1)
            
            if not msgRow.messageText then
                msgRow.messageText = msgRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                msgRow.messageText:SetPoint("CENTER")
                msgRow.messageText:SetJustifyH("CENTER")
            end
            
            msgRow.messageText:SetText("No builds found for this selection.\nTry selecting different sources or content type.")
            msgRow.messageText:SetTextColor(0.7, 0.7, 1)
            msgRow.messageText:Show()
            msgRow:Show()
            UpdateScrollHeight(buildsStartY - 80)
            return
        end
        
        -- Create/update build rows (anchored directly to scrollChild)
        local rowY = buildsStartY
        for i, build in ipairs(allBuilds) do
            local row = buildRows[i]
            
            if not row then
                row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                row:SetHeight(50)
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1
                })
                
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
            
            -- Hide message text if row was previously used as message
            if row.messageText then row.messageText:Hide() end
            
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 15, rowY)
            row:SetPoint("TOPRIGHT", -15, rowY)
            
            -- Build name
            local dungeonText = ""
            if build.category == "mythic" and build.dungeonID then
                dungeonText = KDT.Talents:FormatDungeon(build.dungeonID)
            end
            row.nameText:SetText(dungeonText .. (build.label and ((dungeonText ~= "" and " - " or "") .. build.label) or ""))
            row.nameText:SetTextColor(1, 1, 1)
            
            -- Source color
            local r, g, b = unpack(KDT.Talents:GetSourceColor(build.source))
            row.sourceText:SetText(KDT.Talents:FormatSource(build.source))
            row.sourceText:SetTextColor(r, g, b)
            
            -- Row color by category
            local catR, catG, catB = unpack(KDT.Talents:GetCategoryColor(build.category))
            row:SetBackdropColor(catR * 0.15, catG * 0.15, catB * 0.15, 1)
            row:SetBackdropBorderColor(catR * 0.3, catG * 0.3, catB * 0.3, 1)
            
            -- Copy button action
            row.copyBtn:SetScript("OnClick", function()
                if not build.talentString or build.talentString == "" then return end
                KDT.Talents:CopyToClipboard(build.talentString)
            end)
            
            row:Show()
            rowY = rowY - 55
        end
        
        UpdateScrollHeight(rowY)
    end
    
    -- ==================== REFRESH BUTTON ====================
    refreshBtn:SetScript("OnClick", function()
        UpdateClassSpecText()
        RefreshBuildsList()
    end)
    
    -- ==================== INITIAL REFRESH (delayed for player data availability) ====================
    C_Timer.After(0.5, function()
        UpdateClassSpecText()
        RefreshBuildsList()
    end)
    
    -- ==================== TAB REFRESH (called on every tab switch) ====================
    frame.RefreshTalents = function(self)
        UpdateClassSpecText()
        RefreshBuildsList()
    end
end
