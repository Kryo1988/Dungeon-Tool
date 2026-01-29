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
    end)
    
    -- Lock Position Checkbox
    e.lockCB = CreateFrame("CheckButton", nil, e.settingsBox, "UICheckButtonTemplate")
    e.lockCB:SetSize(24, 24)
    e.lockCB:SetPoint("TOPLEFT", 15, -55)
    e.lockCB.Text:SetText("Lock Timer Position")
    e.lockCB:SetScript("OnClick", function(self)
        KDT.DB.timer.locked = self:GetChecked()
    end)
    
    -- Show When Inactive Checkbox
    e.inactiveCB = CreateFrame("CheckButton", nil, e.settingsBox, "UICheckButtonTemplate")
    e.inactiveCB:SetSize(24, 24)
    e.inactiveCB:SetPoint("TOPLEFT", 15, -80)
    e.inactiveCB.Text:SetText("Show Timer When Not in M+")
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
    
    -- Run History Box (replaces Current Run Status)
    e.historyBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.historyBox:SetPoint("TOPLEFT", e.settingsBox, "BOTTOMLEFT", 0, -10)
    e.historyBox:SetPoint("TOPRIGHT", e.settingsBox, "BOTTOMRIGHT", 0, -10)
    e.historyBox:SetHeight(150)
    e.historyBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.historyBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.historyBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    e.historyTitle = e.historyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.historyTitle:SetPoint("TOPLEFT", 10, -8)
    e.historyTitle:SetText("RECENT RUNS (Last 10)")
    e.historyTitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Clear history button
    e.clearHistoryBtn = self:CreateButton(e.historyBox, "Clear", 50, 18)
    e.clearHistoryBtn:SetPoint("TOPRIGHT", -10, -5)
    e.clearHistoryBtn:SetScript("OnClick", function()
        KDT:ClearRunHistory()
        f:RefreshTimer()
    end)
    
    -- Scroll frame for history
    e.historyScroll = CreateFrame("ScrollFrame", nil, e.historyBox, "UIPanelScrollFrameTemplate")
    e.historyScroll:SetPoint("TOPLEFT", 5, -25)
    e.historyScroll:SetPoint("BOTTOMRIGHT", -25, 5)
    
    e.historyContent = CreateFrame("Frame", nil, e.historyScroll)
    e.historyContent:SetSize(e.historyBox:GetWidth() - 35, 160)
    e.historyScroll:SetScrollChild(e.historyContent)
    
    -- History entries (10 lines in scrollable area)
    e.historyLines = {}
    for i = 1, 10 do
        local line = e.historyContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", 5, -(i-1) * 15)
        line:SetPoint("RIGHT", -5, 0)
        line:SetJustifyH("LEFT")
        line:SetText("")
        e.historyLines[i] = line
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
        
        -- Update run history
        local history = KDT:GetRunHistory()
        
        if #history == 0 then
            e.noHistoryText:Show()
            for _, line in ipairs(e.historyLines) do
                line:SetText("")
            end
        else
            e.noHistoryText:Hide()
            for i, line in ipairs(e.historyLines) do
                local run = history[i]
                if run then
                    local statusColor, statusText
                    if run.upgrade == 3 then
                        statusColor = "|cFF00FF00"
                        statusText = "+3"
                    elseif run.upgrade == 2 then
                        statusColor = "|cFF00FF00"
                        statusText = "+2"
                    elseif run.upgrade == 1 then
                        statusColor = "|cFFFFFF00"
                        statusText = "+1"
                    else
                        statusColor = "|cFFFF0000"
                        statusText = "Depleted"
                    end
                    
                    local timeStr = KDT:FormatTime(run.time)
                    local limitStr = KDT:FormatTime(run.timeLimit)
                    local deathStr = run.deaths > 0 and (" |cFFFF6666(" .. run.deaths .. " deaths)|r") or ""
                    
                    line:SetText(string.format(
                        "%s[%s]|r |cFFFFD100+%d|r %s - %s/%s%s",
                        statusColor,
                        statusText,
                        run.level or 0,
                        run.dungeon or "Unknown",
                        timeStr,
                        limitStr,
                        deathStr
                    ))
                else
                    line:SetText("")
                end
            end
        end
    end
end
