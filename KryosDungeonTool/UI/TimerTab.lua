-- Kryos Dungeon Tool
-- UI/TimerTab.lua - M+ Timer tab UI (settings for external timer)

local addonName, KDT = ...

-- ==================== TIMER TAB ELEMENTS ====================
function KDT:CreateTimerElements(f)
    local e = f.timerElements
    local c = f.content
    
    -- Info Box
    e.infoBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.infoBox:SetPoint("TOPLEFT", 10, -5)
    e.infoBox:SetPoint("TOPRIGHT", -10, -5)
    e.infoBox:SetHeight(80)
    e.infoBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.infoBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.infoBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    e.infoTitle = e.infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    e.infoTitle:SetPoint("TOP", 0, -10)
    e.infoTitle:SetText("|cFFFFD100M+ Timer|r")
    
    e.infoText = e.infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.infoText:SetPoint("TOP", e.infoTitle, "BOTTOM", 0, -8)
    e.infoText:SetText("External timer overlay - automatically shows in M+")
    e.infoText:SetTextColor(0.7, 0.7, 0.7)
    
    e.infoText2 = e.infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.infoText2:SetPoint("TOP", e.infoText, "BOTTOM", 0, -4)
    e.infoText2:SetText("Right-click the timer to access options")
    e.infoText2:SetTextColor(0.5, 0.5, 0.5)
    
    -- Settings Box
    e.settingsBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.settingsBox:SetPoint("TOPLEFT", e.infoBox, "BOTTOMLEFT", 0, -10)
    e.settingsBox:SetPoint("TOPRIGHT", e.infoBox, "BOTTOMRIGHT", 0, -10)
    e.settingsBox:SetHeight(160)
    e.settingsBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.settingsBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.settingsBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    e.settingsTitle = e.settingsBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.settingsTitle:SetPoint("TOPLEFT", 10, -10)
    e.settingsTitle:SetText("TIMER SETTINGS")
    e.settingsTitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Enable Timer Checkbox
    e.enableCB = CreateFrame("CheckButton", nil, e.settingsBox, "UICheckButtonTemplate")
    e.enableCB:SetSize(24, 24)
    e.enableCB:SetPoint("TOPLEFT", 15, -30)
    e.enableCB.Text:SetText("Enable M+ Timer Overlay")
    e.enableCB:SetScript("OnClick", function(self)
        KDT.DB.timer.enabled = self:GetChecked()
        if KDT.DB.timer.enabled then
            KDT:CreateExternalTimer()
            if KDT.timerState.active then
                KDT.ExternalTimer:Show()
            end
        elseif KDT.ExternalTimer then
            KDT.ExternalTimer:Hide()
        end
        -- Hide/show default WoW timer based on setting
        KDT:UpdateDefaultTimerVisibility()
    end)
    
    -- Lock Position Checkbox
    e.lockCB = CreateFrame("CheckButton", nil, e.settingsBox, "UICheckButtonTemplate")
    e.lockCB:SetSize(24, 24)
    e.lockCB:SetPoint("TOPLEFT", 15, -55)
    e.lockCB.Text:SetText("Lock Timer Position")
    e.lockCB:SetScript("OnClick", function(self)
        KDT.DB.timer.locked = self:GetChecked()
    end)
    
    -- Show When Inactive Checkbox (for positioning outside M+)
    e.inactiveCB = CreateFrame("CheckButton", nil, e.settingsBox, "UICheckButtonTemplate")
    e.inactiveCB:SetSize(24, 24)
    e.inactiveCB:SetPoint("TOPLEFT", 15, -80)
    e.inactiveCB.Text:SetText("Show Timer Outside M+ (for positioning)")
    e.inactiveCB:SetScript("OnClick", function(self)
        KDT.DB.timer.showWhenInactive = self:GetChecked()
        KDT:UpdateExternalTimer()
    end)
    
    -- Scale Label
    e.scaleLabel = e.settingsBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.scaleLabel:SetPoint("TOPLEFT", 15, -115)
    e.scaleLabel:SetText("Timer Scale: 1.0")
    
    -- Scale Slider
    e.scaleSlider = CreateFrame("Slider", "KryosTimerScaleSlider", e.settingsBox, "OptionsSliderTemplate")
    e.scaleSlider:SetSize(180, 16)
    e.scaleSlider:SetPoint("LEFT", e.scaleLabel, "RIGHT", 15, 0)
    e.scaleSlider:SetMinMaxValues(0.5, 2.0)
    e.scaleSlider:SetValueStep(0.1)
    e.scaleSlider.Low:SetText("0.5")
    e.scaleSlider.High:SetText("2.0")
    e.scaleSlider:SetScript("OnValueChanged", function(self, value)
        KDT.DB.timer.scale = value
        e.scaleLabel:SetText("Timer Scale: " .. string.format("%.1f", value))
        if KDT.ExternalTimer then
            KDT.ExternalTimer:SetScale(value)
        end
    end)
    
    -- Buttons
    e.resetPosBtn = self:CreateButton(e.settingsBox, "Reset Position", 100, 24)
    e.resetPosBtn:SetPoint("TOPRIGHT", -15, -30)
    e.resetPosBtn:SetScript("OnClick", function()
        KDT.DB.timer.position = nil
        if KDT.ExternalTimer then
            KDT.ExternalTimer:ClearAllPoints()
            KDT.ExternalTimer:SetPoint("RIGHT", UIParent, "RIGHT", -50, 100)
        end
        KDT:Print("Timer position reset.")
    end)
    
    -- Show Timer button
    e.showTimerBtn = self:CreateButton(e.settingsBox, "Show Timer", 100, 24)
    e.showTimerBtn:SetPoint("TOPRIGHT", -15, -60)
    e.showTimerBtn:SetScript("OnClick", function()
        if KDT.ExternalTimer then
            KDT.ExternalTimer:Show()
        else
            KDT:CreateExternalTimer()
            KDT.ExternalTimer:Show()
        end
    end)
    
    -- Run History Box (responsive - fills remaining space)
    e.historyBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.historyBox:SetPoint("TOPLEFT", e.settingsBox, "BOTTOMLEFT", 0, -10)
    e.historyBox:SetPoint("TOPRIGHT", e.settingsBox, "BOTTOMRIGHT", 0, -10)
    e.historyBox:SetPoint("BOTTOM", c, "BOTTOM", 0, 10)
    e.historyBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.historyBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.historyBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    e.historyBox:SetClipsChildren(true)
    
    e.historyTitle = e.historyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.historyTitle:SetPoint("TOPLEFT", 10, -8)
    e.historyTitle:SetText("RECENT RUNS (Last 30)")
    e.historyTitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Clear history button
    e.clearHistoryBtn = self:CreateButton(e.historyBox, "Clear", 50, 18)
    e.clearHistoryBtn:SetPoint("TOPRIGHT", -10, -5)
    e.clearHistoryBtn:SetScript("OnClick", function()
        KDT:ClearRunHistory()
        f:RefreshTimer()
    end)
    
    -- History content (NO SCROLLBAR - simple frame)
    e.historyContent = CreateFrame("Frame", nil, e.historyBox)
    e.historyContent:SetPoint("TOPLEFT", 5, -28)
    e.historyContent:SetPoint("BOTTOMRIGHT", -5, 5)
    
    -- History entry frames (30 entries in 3 columns x 10 rows)
    e.historyEntries = {}
    local ROW_HEIGHT = 38
    local COLS = 3
    
    for i = 1, 30 do
        local col = ((i - 1) % COLS) -- 0, 1, 2
        local row = math.floor((i - 1) / COLS) -- 0-9
        
        local entry = CreateFrame("Frame", nil, e.historyContent, "BackdropTemplate")
        entry:SetHeight(ROW_HEIGHT - 2)
        entry:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        entry:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
        
        -- Position will be set dynamically in RefreshTimer based on parent width
        entry.col = col
        entry.row = row
        entry.rowHeight = ROW_HEIGHT
        
        -- Dungeon name + level
        entry.dungeonText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        entry.dungeonText:SetPoint("TOPLEFT", 5, -3)
        entry.dungeonText:SetPoint("RIGHT", -5, 0)
        entry.dungeonText:SetJustifyH("LEFT")
        
        -- Time + result
        entry.timeText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        entry.timeText:SetPoint("BOTTOMLEFT", 5, 3)
        entry.timeText:SetJustifyH("LEFT")
        
        -- Date
        entry.dateText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        entry.dateText:SetPoint("BOTTOMRIGHT", -5, 3)
        entry.dateText:SetJustifyH("RIGHT")
        entry.dateText:SetTextColor(0.5, 0.5, 0.5)
        
        entry:Hide()
        e.historyEntries[i] = entry
    end
    
    -- No history text
    e.noHistoryText = e.historyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.noHistoryText:SetPoint("CENTER", 0, -10)
    e.noHistoryText:SetText("|cFF666666No runs recorded yet|r")
end

-- ==================== REFRESH TIMER TAB ====================
function KDT:SetupTimerRefresh(f)
    function f:RefreshTimer()
        local e = self.timerElements
        
        -- Update checkboxes
        e.enableCB:SetChecked(KDT.DB.timer.enabled)
        e.lockCB:SetChecked(KDT.DB.timer.locked)
        e.inactiveCB:SetChecked(KDT.DB.timer.showWhenInactive)
        e.scaleSlider:SetValue(KDT.DB.timer.scale or 1)
        e.scaleLabel:SetText("Timer Scale: " .. string.format("%.1f", KDT.DB.timer.scale or 1))
        
        -- Update run history (3-column grid)
        local history = KDT:GetRunHistory()
        
        -- Calculate column width based on content frame width
        local contentWidth = e.historyContent:GetWidth()
        if contentWidth < 100 then contentWidth = e.historyBox:GetWidth() - 10 end
        local colWidth = math.floor(contentWidth / 3) - 4
        local ROW_HEIGHT = 38
        local COLS = 3
        
        if #history == 0 then
            e.noHistoryText:Show()
            for _, entry in ipairs(e.historyEntries) do
                entry:Hide()
            end
        else
            e.noHistoryText:Hide()
            
            for i, entry in ipairs(e.historyEntries) do
                local run = history[i]
                if run and i <= 30 then
                    -- Calculate position
                    local col = ((i - 1) % COLS)
                    local row = math.floor((i - 1) / COLS)
                    
                    entry:ClearAllPoints()
                    entry:SetPoint("TOPLEFT", e.historyContent, "TOPLEFT", col * (colWidth + 4), -row * ROW_HEIGHT)
                    entry:SetWidth(colWidth)
                    
                    -- Status color and text
                    local statusColor, statusIcon
                    if run.upgrade == 3 then
                        statusColor = "00FF00"
                        statusIcon = "+++"
                    elseif run.upgrade == 2 then
                        statusColor = "7FFF00"
                        statusIcon = "++"
                    elseif run.upgrade == 1 then
                        statusColor = "FFFF00"
                        statusIcon = "+"
                    else
                        statusColor = "FF4444"
                        statusIcon = "X"
                    end
                    
                    -- Format dungeon name (truncate if too long)
                    local dungeonName = run.dungeon or "Unknown"
                    if #dungeonName > 12 then
                        dungeonName = string.sub(dungeonName, 1, 11) .. "."
                    end
                    
                    -- Dungeon + level line
                    entry.dungeonText:SetText(string.format(
                        "|cFF%s[%s]|r |cFFFFD100+%d|r %s",
                        statusColor,
                        statusIcon,
                        run.level or 0,
                        dungeonName
                    ))
                    
                    -- Time line
                    local timeStr = KDT:FormatTime(run.time)
                    local deathStr = run.deaths > 0 and string.format(" |cFFFF6666[%dD]|r", run.deaths) or ""
                    entry.timeText:SetText(string.format("|cFFAAAAAA%s|r%s", timeStr, deathStr))
                    
                    -- Date (short format)
                    local dateStr = run.date or ""
                    if #dateStr > 10 then
                        dateStr = string.sub(dateStr, 6, 10) -- MM-DD
                    end
                    entry.dateText:SetText(dateStr)
                    
                    -- Background color based on result
                    if run.upgrade >= 1 then
                        entry:SetBackdropColor(0.02, 0.08, 0.02, 0.9)
                    else
                        entry:SetBackdropColor(0.08, 0.02, 0.02, 0.9)
                    end
                    
                    entry:Show()
                else
                    entry:Hide()
                end
            end
        end
    end
end
