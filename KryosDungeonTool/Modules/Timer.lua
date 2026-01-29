-- Kryos Dungeon Tool
-- Modules/Timer.lua - External M+ Timer (Complete Rewrite)

local addonName, KDT = ...

-- Timer state
KDT.timerState = {
    active = false,
    startTime = 0,
    elapsed = 0,
    timeLimit = 0,
    deaths = 0,
    deathLog = {}, -- {name, time, class}
    dungeonName = "",
    level = 0,
    mapID = 0,
    forcesTotal = 0,
    forcesCurrent = 0,
    forcesPercent = 0,
    bosses = {},
    completed = false,
    completedTime = 0,
    inInstance = false,
}

-- Default colors
local defaultColors = {
    timerNormal = {1, 1, 1, 1},
    timerPlus3 = {0, 1, 0, 1},
    timerPlus2 = {1, 1, 0, 1},
    timerPlus1 = {1, 0.5, 0, 1},
    timerFail = {1, 0, 0, 1},
    deaths = {1, 1, 1, 1},
    forcesIncomplete = {1, 0.8, 0, 1},
    forcesComplete = {0, 1, 0, 1},
    bossIncomplete = {0.6, 0.6, 0.6, 1},
    bossComplete = {0, 1, 0, 1},
    splitAhead = {0, 1, 0, 1},
    splitBehind = {1, 0, 0, 1},
    barPlus3 = {0, 0.8, 0, 1},
    barPlus2 = {1, 1, 0, 1},
    barPlus1 = {1, 0.5, 0, 1},
    barBackground = {0.2, 0.2, 0.2, 1},
    forcesBar = {1, 0.8, 0, 1},
}

-- ==================== FORMAT TIME ====================
function KDT:FormatTime(seconds, showSign)
    if not seconds then return "0:00" end
    
    local negative = seconds < 0
    seconds = math.abs(seconds)
    
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    local str
    if hours > 0 then
        str = string.format("%d:%02d:%02d", hours, mins, secs)
    else
        str = string.format("%d:%02d", mins, secs)
    end
    
    if showSign then
        return negative and "-" .. str or "+" .. str
    end
    return negative and "-" .. str or str
end

-- ==================== CREATE EXTERNAL TIMER ====================
function KDT:CreateExternalTimer()
    if self.ExternalTimer then return self.ExternalTimer end
    
    local WIDTH = 280
    local db = self.DB.timer
    local colors = db.colors or defaultColors
    
    -- Main frame (transparent - no background)
    local f = CreateFrame("Frame", "KryosExternalTimer", UIParent)
    f:SetSize(WIDTH, 200)
    f:SetPoint("RIGHT", UIParent, "RIGHT", -50, 100)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetFrameStrata("MEDIUM")
    
    -- Dragging
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not KDT.DB.timer.locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        KDT.DB.timer.position = {point = point, relPoint = relPoint, x = x, y = y}
    end)
    
    -- Right click menu
    f:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            KDT:ShowTimerContextMenu(self)
        end
    end)
    
    local yOffset = -5
    local font = db.font or "Fonts\\FRIZQT__.TTF"
    
    -- ==================== ROW 1: Main Timer ====================
    f.timerText = f:CreateFontString(nil, "OVERLAY")
    f.timerText:SetFont(font, db.fontSize or 28, "OUTLINE")
    f.timerText:SetPoint("TOP", 0, yOffset)
    f.timerText:SetText("0:00 / 0:00")
    
    -- Death counter with tooltip
    f.deathFrame = CreateFrame("Frame", nil, f)
    f.deathFrame:SetSize(40, 25)
    f.deathFrame:SetPoint("TOPRIGHT", -5, yOffset)
    
    f.deathText = f.deathFrame:CreateFontString(nil, "OVERLAY")
    f.deathText:SetFont(font, db.deathFontSize or 16, "OUTLINE")
    f.deathText:SetPoint("CENTER")
    f.deathText:SetText("[0]")
    
    -- Death tooltip
    f.deathFrame:SetScript("OnEnter", function(self)
        if #KDT.timerState.deathLog > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Deaths", 1, 0.8, 0)
            for _, death in ipairs(KDT.timerState.deathLog) do
                local classColor = RAID_CLASS_COLORS[death.class] or {r=1, g=1, b=1}
                GameTooltip:AddDoubleLine(
                    death.name,
                    KDT:FormatTime(death.time),
                    classColor.r, classColor.g, classColor.b,
                    1, 1, 1
                )
            end
            GameTooltip:Show()
        end
    end)
    f.deathFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    yOffset = yOffset - 35
    
    -- ==================== ROW 2: Three Timer Bars ====================
    local barWidth = (WIDTH - 20) / 3 - 2
    local barHeight = 10
    
    f.splitBars = CreateFrame("Frame", nil, f)
    f.splitBars:SetSize(WIDTH - 16, barHeight + 20)
    f.splitBars:SetPoint("TOP", 0, yOffset)
    
    -- +3 Bar
    f.bar3Bg = f.splitBars:CreateTexture(nil, "BACKGROUND")
    f.bar3Bg:SetSize(barWidth, barHeight)
    f.bar3Bg:SetPoint("TOPLEFT", 0, 0)
    f.bar3Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.bar3 = f.splitBars:CreateTexture(nil, "ARTWORK")
    f.bar3:SetPoint("TOPLEFT", f.bar3Bg, "TOPLEFT", 0, 0)
    f.bar3:SetSize(1, barHeight)
    f.bar3:SetColorTexture(0, 0.8, 0, 1)
    
    f.time3 = f.splitBars:CreateFontString(nil, "OVERLAY")
    f.time3:SetFont(font, 11, "OUTLINE")
    f.time3:SetPoint("TOP", f.bar3Bg, "BOTTOM", 0, -2)
    f.time3:SetTextColor(0, 1, 0, 1)
    
    -- +2 Bar
    f.bar2Bg = f.splitBars:CreateTexture(nil, "BACKGROUND")
    f.bar2Bg:SetSize(barWidth, barHeight)
    f.bar2Bg:SetPoint("LEFT", f.bar3Bg, "RIGHT", 3, 0)
    f.bar2Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.bar2 = f.splitBars:CreateTexture(nil, "ARTWORK")
    f.bar2:SetPoint("TOPLEFT", f.bar2Bg, "TOPLEFT", 0, 0)
    f.bar2:SetSize(1, barHeight)
    f.bar2:SetColorTexture(1, 1, 0, 1)
    
    f.time2 = f.splitBars:CreateFontString(nil, "OVERLAY")
    f.time2:SetFont(font, 11, "OUTLINE")
    f.time2:SetPoint("TOP", f.bar2Bg, "BOTTOM", 0, -2)
    f.time2:SetTextColor(1, 1, 0, 1)
    
    -- +1 Bar
    f.bar1Bg = f.splitBars:CreateTexture(nil, "BACKGROUND")
    f.bar1Bg:SetSize(barWidth, barHeight)
    f.bar1Bg:SetPoint("LEFT", f.bar2Bg, "RIGHT", 3, 0)
    f.bar1Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.bar1 = f.splitBars:CreateTexture(nil, "ARTWORK")
    f.bar1:SetPoint("TOPLEFT", f.bar1Bg, "TOPLEFT", 0, 0)
    f.bar1:SetSize(1, barHeight)
    f.bar1:SetColorTexture(1, 0.5, 0, 1)
    
    f.time1 = f.splitBars:CreateFontString(nil, "OVERLAY")
    f.time1:SetFont(font, 11, "OUTLINE")
    f.time1:SetPoint("TOP", f.bar1Bg, "BOTTOM", 0, -2)
    f.time1:SetTextColor(1, 0.5, 0, 1)
    
    yOffset = yOffset - 35
    
    -- ==================== ROW 3: Forces ====================
    f.forcesRow = CreateFrame("Frame", nil, f)
    f.forcesRow:SetSize(WIDTH - 16, 40)
    f.forcesRow:SetPoint("TOP", 0, yOffset)
    
    f.forcesText = f.forcesRow:CreateFontString(nil, "OVERLAY")
    f.forcesText:SetFont(font, 12, "OUTLINE")
    f.forcesText:SetPoint("TOP", 0, 0)
    f.forcesText:SetText("0.00%")
    
    f.forcesBarBg = f.forcesRow:CreateTexture(nil, "BACKGROUND")
    f.forcesBarBg:SetSize(WIDTH - 16, 16)
    f.forcesBarBg:SetPoint("TOP", f.forcesText, "BOTTOM", 0, -2)
    f.forcesBarBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.forcesBar = f.forcesRow:CreateTexture(nil, "ARTWORK")
    f.forcesBar:SetPoint("TOPLEFT", f.forcesBarBg, "TOPLEFT", 0, 0)
    f.forcesBar:SetSize(1, 16)
    f.forcesBar:SetColorTexture(1, 0.8, 0, 1)
    
    yOffset = yOffset - 42
    
    -- ==================== ROW 4: Bosses ====================
    f.bossContainer = CreateFrame("Frame", nil, f)
    f.bossContainer:SetSize(WIDTH - 16, 120)
    f.bossContainer:SetPoint("TOP", 0, yOffset)
    
    f.bossFrames = {}
    for i = 1, 8 do
        local bf = CreateFrame("Frame", nil, f.bossContainer)
        bf:SetSize(WIDTH - 16, 16)
        bf:SetPoint("TOPRIGHT", 0, -(i-1) * 17)
        
        -- Split time (left)
        bf.splitTime = bf:CreateFontString(nil, "OVERLAY")
        bf.splitTime:SetFont(font, 12, "OUTLINE")
        bf.splitTime:SetPoint("LEFT", 0, 0)
        bf.splitTime:SetText("")
        
        -- Kill time 
        bf.killTime = bf:CreateFontString(nil, "OVERLAY")
        bf.killTime:SetFont(font, 12, "OUTLINE")
        bf.killTime:SetPoint("LEFT", 50, 0)
        bf.killTime:SetText("")
        
        -- Boss name (right)
        bf.name = bf:CreateFontString(nil, "OVERLAY")
        bf.name:SetFont(font, 12, "OUTLINE")
        bf.name:SetPoint("RIGHT", 0, 0)
        bf.name:SetText("")
        
        bf:Hide()
        f.bossFrames[i] = bf
    end
    
    self.ExternalTimer = f
    
    -- Apply saved position
    if db.position then
        local pos = db.position
        f:ClearAllPoints()
        f:SetPoint(pos.point or "RIGHT", UIParent, pos.relPoint or "RIGHT", pos.x or -50, pos.y or 100)
    end
    
    if db.scale then
        f:SetScale(db.scale)
    end
    
    return f
end

-- ==================== UPDATE EXTERNAL TIMER ====================
function KDT:UpdateExternalTimer()
    local f = self.ExternalTimer
    if not f then return end
    
    local state = self.timerState
    local db = self.DB.timer
    local colors = db.colors or defaultColors
    
    -- Check if we're actually in M+ (via API)
    local inMythicPlus = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    
    -- Show/Hide logic:
    -- 1. If enabled AND in M+ -> ALWAYS show
    -- 2. If enabled AND showWhenInactive AND NOT in M+ -> show (for positioning/testing)
    local shouldShow = false
    if db.enabled then
        if inMythicPlus or state.active then
            -- Always show in M+
            shouldShow = true
        elseif state.completed and state.inInstance then
            -- Keep showing after completion until leaving instance
            shouldShow = true
        elseif db.showWhenInactive then
            -- Show outside M+ for positioning/testing
            shouldShow = true
        end
    end
    
    if not shouldShow then
        f:Hide()
        return
    end
    
    f:Show()
    
    -- Get times
    local elapsed = state.completed and state.completedTime or (state.elapsed or 0)
    local timeLimit = state.timeLimit or 1
    local plus3Time = timeLimit * 0.6
    local plus2Time = timeLimit * 0.8
    local plus1Time = timeLimit
    
    -- ==================== Main Timer ====================
    f.timerText:SetText(self:FormatTime(elapsed) .. " / " .. self:FormatTime(timeLimit))
    
    if elapsed < plus3Time then
        f.timerText:SetTextColor(unpack(colors.timerPlus3 or defaultColors.timerPlus3))
    elseif elapsed < plus2Time then
        f.timerText:SetTextColor(unpack(colors.timerPlus2 or defaultColors.timerPlus2))
    elseif elapsed < plus1Time then
        f.timerText:SetTextColor(unpack(colors.timerPlus1 or defaultColors.timerPlus1))
    else
        f.timerText:SetTextColor(unpack(colors.timerFail or defaultColors.timerFail))
    end
    
    -- ==================== Deaths ====================
    f.deathText:SetText("[" .. (state.deaths or 0) .. "]")
    f.deathText:SetTextColor(unpack(colors.deaths or defaultColors.deaths))
    
    -- ==================== Split Bars ====================
    local barWidth = f.bar3Bg:GetWidth()
    
    f.time3:SetText(self:FormatTime(plus3Time))
    f.time2:SetText(self:FormatTime(plus2Time))
    f.time1:SetText(self:FormatTime(plus1Time))
    
    -- +3 Bar
    if elapsed < plus3Time then
        local progress = elapsed / plus3Time
        f.bar3:SetWidth(math.max(1, barWidth * progress))
        f.bar3:SetColorTexture(unpack(colors.barPlus3 or defaultColors.barPlus3))
    else
        f.bar3:SetWidth(barWidth)
        f.bar3:SetColorTexture(0.3, 0.5, 0.3, 1)
    end
    
    -- +2 Bar
    if elapsed < plus3Time then
        f.bar2:SetWidth(1)
    elseif elapsed < plus2Time then
        local progress = (elapsed - plus3Time) / (plus2Time - plus3Time)
        f.bar2:SetWidth(math.max(1, barWidth * progress))
        f.bar2:SetColorTexture(unpack(colors.barPlus2 or defaultColors.barPlus2))
    else
        f.bar2:SetWidth(barWidth)
        f.bar2:SetColorTexture(0.5, 0.5, 0.3, 1)
    end
    
    -- +1 Bar
    if elapsed < plus2Time then
        f.bar1:SetWidth(1)
    elseif elapsed < plus1Time then
        local progress = (elapsed - plus2Time) / (plus1Time - plus2Time)
        f.bar1:SetWidth(math.max(1, barWidth * progress))
        f.bar1:SetColorTexture(unpack(colors.barPlus1 or defaultColors.barPlus1))
    else
        f.bar1:SetWidth(barWidth)
        f.bar1:SetColorTexture(0.5, 0.3, 0.2, 1)
    end
    
    -- ==================== Forces ====================
    local forcesPct = state.forcesPercent or 0
    local forcesCurrent = state.forcesCurrent or 0
    local forcesTotal = state.forcesTotal or 0
    
    local forcesStr = string.format("%.2f%% (%d/%d)", forcesPct, forcesCurrent, forcesTotal)
    f.forcesText:SetText(forcesStr)
    
    if forcesPct >= 100 then
        f.forcesText:SetTextColor(unpack(colors.forcesComplete or defaultColors.forcesComplete))
        f.forcesBar:SetColorTexture(unpack(colors.forcesComplete or defaultColors.forcesComplete))
    else
        f.forcesText:SetTextColor(unpack(colors.forcesIncomplete or defaultColors.forcesIncomplete))
        f.forcesBar:SetColorTexture(unpack(colors.forcesBar or defaultColors.forcesBar))
    end
    
    local forcesBarWidth = f.forcesBarBg:GetWidth()
    f.forcesBar:SetWidth(math.max(1, math.min(forcesBarWidth, forcesBarWidth * (forcesPct / 100))))
    
    -- ==================== Bosses ====================
    local bossCount = #state.bosses
    for i, bf in ipairs(f.bossFrames) do
        if i <= bossCount then
            local boss = state.bosses[i]
            
            if boss.killed then
                -- Calculate expected time (evenly distributed)
                local expectedTime = (plus2Time / bossCount) * i
                local diff = (boss.killTime or elapsed) - expectedTime
                
                -- Split time
                bf.splitTime:SetText(self:FormatTime(diff, true))
                if diff <= 0 then
                    bf.splitTime:SetTextColor(unpack(colors.splitAhead or defaultColors.splitAhead))
                else
                    bf.splitTime:SetTextColor(unpack(colors.splitBehind or defaultColors.splitBehind))
                end
                
                -- Kill time
                bf.killTime:SetText("[" .. self:FormatTime(boss.killTime or 0) .. "]")
                bf.killTime:SetTextColor(1, 1, 1, 1)
                
                -- Boss name
                bf.name:SetText(boss.name or "Boss " .. i)
                bf.name:SetTextColor(unpack(colors.bossComplete or defaultColors.bossComplete))
            else
                bf.splitTime:SetText("")
                bf.killTime:SetText("")
                bf.name:SetText(boss.name or "Boss " .. i)
                bf.name:SetTextColor(unpack(colors.bossIncomplete or defaultColors.bossIncomplete))
            end
            
            bf:Show()
        else
            bf:Hide()
        end
    end
    
    -- Adjust frame height
    local height = 115 + math.max(0, bossCount) * 17
    f:SetHeight(height)
end

-- ==================== TIMER CONTEXT MENU ====================
function KDT:ShowTimerContextMenu(frame)
    local menu = CreateFrame("Frame", "KryosTimerMenu", UIParent, "UIDropDownMenuTemplate")
    
    local menuList = {
        {text = "Kryos M+ Timer", isTitle = true, notCheckable = true},
        {text = self.DB.timer.locked and "Unlock Position" or "Lock Position", notCheckable = true, func = function()
            self.DB.timer.locked = not self.DB.timer.locked
        end},
        {text = "Timer Settings", notCheckable = true, func = function()
            self:ShowTimerSettings()
        end},
        {text = "", notCheckable = true, disabled = true},
        {text = "Hide Timer", notCheckable = true, func = function()
            self.DB.timer.enabled = false
            if self.ExternalTimer then
                self.ExternalTimer:Hide()
            end
        end},
    }
    
    EasyMenu(menuList, menu, "cursor", 0, 0, "MENU")
end

-- ==================== TIMER SETTINGS ====================
function KDT:ShowTimerSettings()
    if self.timerSettingsFrame then
        self.timerSettingsFrame:Show()
        return
    end
    
    local f = CreateFrame("Frame", "KryosTimerSettingsFrame", UIParent, "BackdropTemplate")
    f:SetSize(400, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    f:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    f:SetBackdropBorderColor(0.3, 0.3, 0.5, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFFFFD100M+ Timer Settings|r")
    
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    closeBtn.text:SetPoint("CENTER")
    closeBtn.text:SetText("×")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(350, 600)
    scrollFrame:SetScrollChild(content)
    
    local yPos = 0
    
    -- Enable checkbox
    local enableCB = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    enableCB:SetSize(24, 24)
    enableCB:SetPoint("TOPLEFT", 5, yPos)
    enableCB.Text:SetText("Enable M+ Timer")
    enableCB:SetChecked(self.DB.timer.enabled)
    enableCB:SetScript("OnClick", function(self) KDT.DB.timer.enabled = self:GetChecked() end)
    yPos = yPos - 28
    
    -- Lock checkbox
    local lockCB = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    lockCB:SetSize(24, 24)
    lockCB:SetPoint("TOPLEFT", 5, yPos)
    lockCB.Text:SetText("Lock Position")
    lockCB:SetChecked(self.DB.timer.locked)
    lockCB:SetScript("OnClick", function(self) KDT.DB.timer.locked = self:GetChecked() end)
    yPos = yPos - 28
    
    -- Show when inactive
    local inactiveCB = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    inactiveCB:SetSize(24, 24)
    inactiveCB:SetPoint("TOPLEFT", 5, yPos)
    inactiveCB.Text:SetText("Show when not in M+")
    inactiveCB:SetChecked(self.DB.timer.showWhenInactive)
    inactiveCB:SetScript("OnClick", function(self) KDT.DB.timer.showWhenInactive = self:GetChecked() end)
    yPos = yPos - 40
    
    -- Scale
    local scaleLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 5, yPos)
    scaleLabel:SetText("Scale: " .. string.format("%.1f", self.DB.timer.scale or 1))
    
    local scaleSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    scaleSlider:SetSize(180, 16)
    scaleSlider:SetPoint("LEFT", scaleLabel, "RIGHT", 20, 0)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(self.DB.timer.scale or 1)
    scaleSlider.Low:SetText("0.5")
    scaleSlider.High:SetText("2.0")
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        KDT.DB.timer.scale = value
        scaleLabel:SetText("Scale: " .. string.format("%.1f", value))
        if KDT.ExternalTimer then KDT.ExternalTimer:SetScale(value) end
    end)
    yPos = yPos - 40
    
    -- Font Size
    local fontLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", 5, yPos)
    fontLabel:SetText("Timer Font Size: " .. (self.DB.timer.fontSize or 28))
    
    local fontSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    fontSlider:SetSize(150, 16)
    fontSlider:SetPoint("LEFT", fontLabel, "RIGHT", 20, 0)
    fontSlider:SetMinMaxValues(16, 40)
    fontSlider:SetValueStep(1)
    fontSlider:SetValue(self.DB.timer.fontSize or 28)
    fontSlider.Low:SetText("16")
    fontSlider.High:SetText("40")
    fontSlider:SetScript("OnValueChanged", function(self, value)
        KDT.DB.timer.fontSize = value
        fontLabel:SetText("Timer Font Size: " .. value)
    end)
    yPos = yPos - 50
    
    -- COLOR SETTINGS HEADER
    local colorHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    colorHeader:SetPoint("TOPLEFT", 5, yPos)
    colorHeader:SetText("|cFFFFD100Color Settings|r")
    yPos = yPos - 25
    
    -- Initialize colors if needed
    self.DB.timer.colors = self.DB.timer.colors or {}
    for k, v in pairs(defaultColors) do
        if not self.DB.timer.colors[k] then
            self.DB.timer.colors[k] = {unpack(v)}
        end
    end
    
    -- Color picker function
    local function CreateColorButton(parent, yOffset, label, colorKey)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 5, yOffset)
        lbl:SetText(label)
        
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(20, 20)
        btn:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
        
        local c = KDT.DB.timer.colors[colorKey] or defaultColors[colorKey]
        btn.tex = btn:CreateTexture(nil, "ARTWORK")
        btn.tex:SetAllPoints()
        btn.tex:SetColorTexture(c[1], c[2], c[3], 1)
        
        btn:SetScript("OnClick", function()
            local r, g, b = c[1], c[2], c[3]
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.func = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                KDT.DB.timer.colors[colorKey] = {nr, ng, nb, 1}
                btn.tex:SetColorTexture(nr, ng, nb, 1)
            end
            ColorPickerFrame:Show()
        end)
        
        return yOffset - 25
    end
    
    yPos = CreateColorButton(content, yPos, "Timer +3:", "timerPlus3")
    yPos = CreateColorButton(content, yPos, "Timer +2:", "timerPlus2")
    yPos = CreateColorButton(content, yPos, "Timer +1:", "timerPlus1")
    yPos = CreateColorButton(content, yPos, "Timer Fail:", "timerFail")
    yPos = CreateColorButton(content, yPos, "Deaths:", "deaths")
    yPos = CreateColorButton(content, yPos, "Forces Incomplete:", "forcesIncomplete")
    yPos = CreateColorButton(content, yPos, "Forces Complete:", "forcesComplete")
    yPos = CreateColorButton(content, yPos, "Boss Incomplete:", "bossIncomplete")
    yPos = CreateColorButton(content, yPos, "Boss Complete:", "bossComplete")
    yPos = CreateColorButton(content, yPos, "Split Ahead:", "splitAhead")
    yPos = CreateColorButton(content, yPos, "Split Behind:", "splitBehind")
    yPos = yPos - 20
    
    -- Reset buttons
    local resetPosBtn = self:CreateButton(content, "Reset Position", 100, 24)
    resetPosBtn:SetPoint("TOPLEFT", 5, yPos)
    resetPosBtn:SetScript("OnClick", function()
        KDT.DB.timer.position = nil
        if KDT.ExternalTimer then
            KDT.ExternalTimer:ClearAllPoints()
            KDT.ExternalTimer:SetPoint("RIGHT", UIParent, "RIGHT", -50, 100)
        end
    end)
    
    local resetColorsBtn = self:CreateButton(content, "Reset Colors", 100, 24)
    resetColorsBtn:SetPoint("LEFT", resetPosBtn, "RIGHT", 10, 0)
    resetColorsBtn:SetScript("OnClick", function()
        KDT.DB.timer.colors = {}
        for k, v in pairs(defaultColors) do
            KDT.DB.timer.colors[k] = {unpack(v)}
        end
        KDT:Print("Colors reset to default. Reopen settings to see changes.")
    end)
    
    content:SetHeight(math.abs(yPos) + 50)
    self.timerSettingsFrame = f
end

-- ==================== UPDATE TIMER FROM GAME ====================
function KDT:UpdateTimerFromGame()
    local state = self.timerState
    
    -- Check instance status
    local inInstance, instanceType = IsInInstance()
    state.inInstance = inInstance and (instanceType == "party")
    
    -- If we left the instance after completion, reset
    if not state.inInstance and state.completed then
        state.completed = false
        state.completedTime = 0
    end
    
    local inChallenge = C_ChallengeMode.IsChallengeModeActive()
    
    if inChallenge then
        local mapChallengeModeID = C_ChallengeMode.GetActiveChallengeMapID()
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
        
        if mapChallengeModeID and keystoneLevel then
            local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
            local _, elapsedTime = GetWorldElapsedTime(1)
            
            if elapsedTime and elapsedTime > 0 then
                if not state.active then
                    -- Initialize new run
                    state.active = true
                    state.completed = false
                    state.completedTime = 0
                    state.startTime = GetTime() - elapsedTime
                    state.dungeonName = name or "Unknown"
                    state.level = keystoneLevel
                    state.mapID = mapChallengeModeID
                    state.deaths = 0
                    state.deathLog = {}
                    state.bosses = {}
                    state.forcesCurrent = 0
                    state.forcesTotal = 0
                    state.forcesPercent = 0
                    
                    self:Print("M+ Timer started: " .. state.dungeonName .. " +" .. state.level)
                end
                
                state.elapsed = elapsedTime
                state.timeLimit = timeLimit
                
                -- Update death count
                local deaths, timeLost = C_ChallengeMode.GetDeathCount()
                if deaths and deaths > state.deaths then
                    state.deaths = deaths
                end
                
                -- Update scenario info
                self:UpdateScenarioInfo()
                
                -- Check for completion via multiple methods (fallback if event didn't fire)
                if not state.completed then
                    local isComplete = false
                    local completedTime = 0
                    
                    -- Method 1: C_ChallengeMode.GetCompletionInfo (most reliable)
                    local mapChallenge, levelChallenge, timeChallenge = C_ChallengeMode.GetCompletionInfo()
                    if timeChallenge and timeChallenge > 0 then
                        isComplete = true
                        completedTime = timeChallenge / 1000
                    end
                    
                    -- Method 2: C_ChallengeMode.GetChallengeCompletionInfo (WoW 12.0+)
                    if not isComplete then
                        local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo and C_ChallengeMode.GetChallengeCompletionInfo()
                        if completionInfo and completionInfo.time and completionInfo.time > 0 then
                            isComplete = true
                            completedTime = completionInfo.time / 1000
                        end
                    end
                    
                    -- Method 3: C_Scenario.IsComplete
                    if not isComplete then
                        local scenarioComplete = C_Scenario.IsComplete and C_Scenario.IsComplete()
                        if scenarioComplete then
                            isComplete = true
                            completedTime = elapsedTime
                        end
                    end
                    
                    -- Method 4: Check if all bosses are killed and forces >= 99.4%
                    if not isComplete and state.forcesPercent >= 99.4 then
                        local allBossesKilled = true
                        local bossCount = 0
                        if state.bosses and #state.bosses > 0 then
                            for _, boss in ipairs(state.bosses) do
                                bossCount = bossCount + 1
                                if not boss.killed then
                                    allBossesKilled = false
                                    break
                                end
                            end
                            if bossCount > 0 and allBossesKilled then
                                isComplete = true
                                completedTime = elapsedTime
                            end
                        end
                    end
                    
                    if isComplete then
                        state.completed = true
                        state.completedTime = completedTime > 0 and completedTime or elapsedTime
                        state.active = false
                        -- Save to history
                        self:SaveRunToHistory()
                        self:Print("|cFF00FF00M+ completed! Time: " .. self:FormatTime(state.completedTime) .. "|r")
                    end
                end
            end
        end
    else
        if state.active then
            state.active = false
            if not state.completed then
                self:Print("M+ Timer stopped.")
            end
        end
    end
end

-- ==================== UPDATE SCENARIO INFO ====================
function KDT:UpdateScenarioInfo()
    local state = self.timerState
    
    -- Get step info (number of criteria)
    local numCriteria = 0
    if C_Scenario and C_Scenario.GetStepInfo then
        local _, _, num = C_Scenario.GetStepInfo()
        numCriteria = num or 0
    end
    
    if numCriteria == 0 then return end
    
    local oldBosses = state.bosses or {}
    state.bosses = {}
    
    -- Process all criteria
    for i = 1, numCriteria do
        local criteriaInfo = C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo(i)
        
        if criteriaInfo then
            local desc = criteriaInfo.description or ""
            local completed = criteriaInfo.completed
            local quantity = criteriaInfo.quantity
            local totalQuantity = criteriaInfo.totalQuantity
            local quantityString = criteriaInfo.quantityString or ""
            local isWeighted = criteriaInfo.isWeighted
            
            -- Forces detection: last criteria OR isWeighted OR contains "Force"/"Feind"
            local isForces = isWeighted or 
                            desc:find("Enemy Forces") or 
                            desc:find("Feindliche") or
                            desc:find("Forces ennemies") or
                            (i == numCriteria and totalQuantity and totalQuantity > 100)
            
            if isForces then
                -- Parse forces
                local total = totalQuantity or 0
                local current = 0
                local percent = 0
                
                -- quantityString in WoW 12.0 is the raw count (e.g., "123" or "45%")
                if quantityString and quantityString ~= "" then
                    -- Remove % if present and convert
                    local numStr = quantityString:gsub("%%", "")
                    local num = tonumber(numStr)
                    
                    if num then
                        if total > 0 then
                            -- Check if num is count or percentage
                            if num <= total then
                                -- It's a raw count
                                current = num
                                percent = (current / total) * 100
                            else
                                -- It's percentage * 100 or something else
                                percent = num
                                current = math.floor((percent / 100) * total)
                            end
                        else
                            percent = num
                        end
                    end
                end
                
                -- Fallback: use quantity directly
                if current == 0 and quantity and total > 0 then
                    if quantity <= total then
                        current = quantity
                        percent = (current / total) * 100
                    end
                end
                
                state.forcesCurrent = current
                state.forcesTotal = total
                state.forcesPercent = math.min(100, percent)
            else
                -- Boss
                local oldBoss = nil
                for _, b in ipairs(oldBosses) do
                    if b.name == desc then
                        oldBoss = b
                        break
                    end
                end
                
                local boss = {
                    name = desc,
                    killed = completed,
                    killTime = nil,
                }
                
                if completed then
                    if oldBoss and oldBoss.killTime then
                        boss.killTime = oldBoss.killTime
                    elseif oldBoss and not oldBoss.killed then
                        boss.killTime = state.elapsed
                    else
                        boss.killTime = state.elapsed
                    end
                end
                
                table.insert(state.bosses, boss)
            end
        end
    end
end

-- ==================== RECORD DEATH ====================
function KDT:RecordDeath(name, class)
    local state = self.timerState
    if state.active then
        table.insert(state.deathLog, {
            name = name,
            time = state.elapsed,
            class = class or "WARRIOR"
        })
    end
end

-- ==================== GET TIMER DATA ====================
function KDT:GetTimerData()
    return self.timerState
end

-- ==================== RESET TIMER ====================
function KDT:ResetTimer()
    local state = self.timerState
    state.active = false
    state.completed = false
    state.completedTime = 0
    state.startTime = 0
    state.elapsed = 0
    state.timeLimit = 0
    state.deaths = 0
    state.deathLog = {}
    state.dungeonName = ""
    state.level = 0
    state.forcesCurrent = 0
    state.forcesTotal = 0
    state.forcesPercent = 0
    state.bosses = {}
end

-- ==================== RUN HISTORY ====================
function KDT:SaveRunToHistory()
    local state = self.timerState
    
    -- Debug
    -- self:Print("SaveRunToHistory called: completed=" .. tostring(state.completed) .. " dungeon=" .. tostring(state.dungeonName))
    
    if not state.completed then
        return
    end
    
    -- Use dungeon name or get it from mapID
    local dungeonName = state.dungeonName
    if (not dungeonName or dungeonName == "" or dungeonName == "Unknown") and state.mapID then
        dungeonName = self:GetDungeonName(state.mapID) or self:GetShortDungeonName(state.mapID) or "Unknown Dungeon"
    end
    
    if not dungeonName or dungeonName == "" then
        dungeonName = "Unknown Dungeon"
    end
    
    -- Initialize history if needed
    if not self.DB.runHistory then
        self.DB.runHistory = {}
    end
    
    -- Use completedTime or calculate from elapsed
    local completedTime = state.completedTime
    if completedTime == 0 or not completedTime then
        completedTime = state.elapsed or 0
    end
    
    -- Calculate if in time
    local timeLimit = state.timeLimit or 0
    local inTime = timeLimit > 0 and completedTime <= timeLimit
    local plus3 = timeLimit > 0 and completedTime <= timeLimit * 0.6
    local plus2 = timeLimit > 0 and completedTime <= timeLimit * 0.8
    
    local upgrade = 0
    if plus3 then
        upgrade = 3
    elseif plus2 then
        upgrade = 2
    elseif inTime then
        upgrade = 1
    end
    
    -- Create run entry
    local runEntry = {
        dungeon = dungeonName,
        level = state.level or 0,
        time = completedTime,
        timeLimit = timeLimit,
        inTime = inTime,
        upgrade = upgrade,
        deaths = state.deaths or 0,
        date = date("%Y-%m-%d %H:%M"),
        timestamp = time(),
    }
    
    -- Add to history (at the beginning)
    table.insert(self.DB.runHistory, 1, runEntry)
    
    -- Keep only last 30 runs
    while #self.DB.runHistory > 30 do
        table.remove(self.DB.runHistory)
    end
    
    self:Print("Run saved: +" .. (state.level or 0) .. " " .. dungeonName .. " - " .. self:FormatTime(completedTime) .. (inTime and " (+" .. upgrade .. ")" or " (Depleted)"))
end

function KDT:GetRunHistory()
    return self.DB.runHistory or {}
end

function KDT:ClearRunHistory()
    self.DB.runHistory = {}
    self:Print("Run history cleared.")
end

-- ==================== HIDE/SHOW DEFAULT WOW TIMER ====================
function KDT:UpdateDefaultTimerVisibility()
    -- Only hide if our timer overlay is enabled
    local shouldHide = self.DB and self.DB.timer and self.DB.timer.enabled
    
    -- Try various methods to hide the default M+ timer (WoW 12.0 compatible)
    -- Method 1: ScenarioBlocksFrame (older versions)
    if ScenarioBlocksFrame then
        if shouldHide then
            ScenarioBlocksFrame:SetAlpha(0)
        else
            ScenarioBlocksFrame:SetAlpha(1)
        end
    end
    
    -- Method 2: ObjectiveTrackerFrame ScenarioHeader
    if ObjectiveTrackerFrame and ObjectiveTrackerFrame.BlocksFrame then
        local blocksFrame = ObjectiveTrackerFrame.BlocksFrame
        if blocksFrame.ScenarioHeader then
            if shouldHide then
                blocksFrame.ScenarioHeader:SetAlpha(0)
            else
                blocksFrame.ScenarioHeader:SetAlpha(1)
            end
        end
    end
    
    -- Method 3: ScenarioObjectiveTracker (WoW 12.0+)
    if ScenarioObjectiveTracker then
        if shouldHide then
            ScenarioObjectiveTracker:SetAlpha(0)
        else
            ScenarioObjectiveTracker:SetAlpha(1)
        end
    end
    
    -- Method 4: ObjectiveTrackerScenarioHeader (alternative)
    if ObjectiveTrackerScenarioHeader then
        if shouldHide then
            ObjectiveTrackerScenarioHeader:SetAlpha(0)
        else
            ObjectiveTrackerScenarioHeader:SetAlpha(1)
        end
    end
end

