-- Kryos Dungeon Tool
-- Modules/Timer.lua - External M+ Timer (v2.0) - New Design
-- Features: Custom frame design with textures, modern layout, WoW 12.0 API

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
    inMythicPlus = false, -- Track M+ state specifically
    -- Sound tracking
    lastTimeTier = 0, -- 0=not started, 1=failed, 2=+1, 3=+2, 4=+3
    soundsPlayed = {
        cd2 = false,
        cd1 = false,
        failed = false,
    }
}

-- Default colors (all customizable)
local defaultColors = {
    -- Timer text colors
    timerNormal = {1, 1, 1, 1},
    timerPlus3 = {0, 1, 0, 1},
    timerPlus2 = {1, 1, 0, 1},
    timerPlus1 = {1, 0.5, 0, 1},
    timerFail = {1, 0, 0, 1},
    -- Header colors
    dungeonName = {1, 0.82, 0, 1}, -- Gold
    keyLevel = {0.5, 1, 0.5, 1}, -- Light green
    -- Deaths
    deaths = {1, 1, 1, 1},
    -- Forces
    forcesIncomplete = {1, 0.8, 0, 1},
    forcesComplete = {0, 1, 0, 1},
    forcesBar = {1, 0.8, 0, 1},
    forcesBarComplete = {0, 1, 0, 1},
    -- Boss
    bossIncomplete = {0.6, 0.6, 0.6, 1},
    bossComplete = {0, 1, 0, 1},
    -- Splits
    splitAhead = {0, 1, 0, 1},
    splitBehind = {1, 0, 0, 1},
    -- Bars
    barPlus3 = {0, 0.8, 0, 1},
    barPlus2 = {1, 1, 0, 1},
    barPlus1 = {1, 0.5, 0, 1},
    barBackground = {0.15, 0.15, 0.15, 1},
    -- Split times text
    splitTimePlus3 = {0, 1, 0, 1},
    splitTimePlus2 = {1, 1, 0, 1},
    splitTimePlus1 = {1, 0.5, 0, 1},
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

-- ==================== GET COLOR ====================
function KDT:GetTimerColor(colorName)
    local db = self.DB and self.DB.timer
    local colors = db and db.colors or {}
    return colors[colorName] or defaultColors[colorName] or {1, 1, 1, 1}
end

-- ==================== CREATE EXTERNAL TIMER ====================
function KDT:CreateExternalTimer()
    if self.ExternalTimer then return self.ExternalTimer end
    
    local WIDTH = 600
    local HEIGHT = 340
    local db = self.DB.timer
    
    -- Main frame
    local f = CreateFrame("Frame", "KryosExternalTimer", UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("TOP", UIParent, "TOP", 0, -100)
    f:SetMovable(true)
    -- SetClampedToScreen removed - allow free movement
    f:EnableMouse(true)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    
    -- Background frame texture
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetTexture("Interface\\AddOns\\KryosDungeonTool\\Textures\\rahmen")
    f.bg:SetAllPoints(f)
    
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
    
    local font = db.customFont or db.font or "Fonts\\FRIZQT__.TTF"
    
    -- Content area inside the frame (accounting for frame borders)
    local contentTop = -70  -- Tiefer gesetzt von -60
    local contentWidth = WIDTH - 120
    
    -- ==================== OPTIONS BUTTON (top right corner) ====================
    f.optionsBtn = CreateFrame("Button", nil, f)
    f.optionsBtn:SetSize(24, 24)
    f.optionsBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -100, -65)  -- Von -80 auf -100 (weiter links)
    f.optionsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    f.optionsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    f.optionsBtn:SetScript("OnClick", function(self, button)
        KDT:ShowTimerSettings()
    end)
    f.optionsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Timer Settings", 1, 0.82, 0)
        GameTooltip:AddLine("Click to open settings", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    f.optionsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- ==================== DUNGEON NAME & KEY LEVEL ====================
    f.dungeonText = f:CreateFontString(nil, "OVERLAY")
    f.dungeonText:SetFont(font, 18, "OUTLINE")
    f.dungeonText:SetPoint("TOP", f, "TOP", 0, contentTop)
    f.dungeonText:SetTextColor(1, 1, 1, 1)  -- White
    f.dungeonText:SetText("Dungeon Name")
    
    -- ==================== AFFIXES ====================
    f.affixText = f:CreateFontString(nil, "OVERLAY")
    f.affixText:SetFont(font, 14, "OUTLINE")
    f.affixText:SetPoint("TOP", f.dungeonText, "BOTTOM", 0, -8)
    f.affixText:SetTextColor(1, 0.82, 0, 1)  -- Gold
    f.affixText:SetText("Fortified / Raging / Volcanic")
    
    -- ==================== MAIN TIMER (Large, Center) ====================
    f.timerText = f:CreateFontString(nil, "OVERLAY")
    f.timerText:SetFont(font, 52, "THICKOUTLINE")
    f.timerText:SetPoint("CENTER", f, "CENTER", 0, 10)
    f.timerText:SetTextColor(0, 1, 0, 1)  -- Green
    f.timerText:SetText("24:31")
    
    -- ==================== SPLIT TIMES (+3, +2, +1) - Horizontal zentriert ====================
    local splitTimesYOffset = -65  -- Unter dem Main Timer
    local splitTimesSpacing = 100   -- Abstand zwischen den Zeiten
    
    -- +3 Time (Links)
    f.time3Text = f:CreateFontString(nil, "OVERLAY")
    f.time3Text:SetFont(font, 18, "OUTLINE")
    f.time3Text:SetPoint("CENTER", f.timerText, "CENTER", -splitTimesSpacing, splitTimesYOffset)
    f.time3Text:SetTextColor(0, 1, 0, 1)  -- Green
    f.time3Text:SetText("+3: 18:00")
    
    -- +2 Time (Mitte)
    f.time2Text = f:CreateFontString(nil, "OVERLAY")
    f.time2Text:SetFont(font, 18, "OUTLINE")
    f.time2Text:SetPoint("CENTER", f.timerText, "CENTER", 0, splitTimesYOffset)
    f.time2Text:SetTextColor(1, 1, 0, 1)  -- Yellow
    f.time2Text:SetText("+2: 24:00")
    
    -- +1 Time (Rechts)
    f.time1Text = f:CreateFontString(nil, "OVERLAY")
    f.time1Text:SetFont(font, 18, "OUTLINE")
    f.time1Text:SetPoint("CENTER", f.timerText, "CENTER", splitTimesSpacing, splitTimesYOffset)
    f.time1Text:SetTextColor(1, 0.5, 0, 1)  -- Orange
    f.time1Text:SetText("+1: 30:00")
    
    -- ==================== PROGRESS BARS (Three small bars ABOVE split times) ====================
    local barWidth = 80   -- Kleiner: von 150 auf 80
    local barHeight = 8   -- Kleiner: von 12 auf 8
    local barsYOffset = -45  -- Über den Split-Times (20px höher als Split-Times)
    
    -- +3 Bar (Links, über +3 Time)
    f.bar3Bg = f:CreateTexture(nil, "BACKGROUND")
    f.bar3Bg:SetSize(barWidth, barHeight)
    f.bar3Bg:SetPoint("CENTER", f.timerText, "CENTER", -splitTimesSpacing, barsYOffset)
    f.bar3Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.bar3 = f:CreateTexture(nil, "ARTWORK")
    f.bar3:SetPoint("LEFT", f.bar3Bg, "LEFT", 0, 0)
    f.bar3:SetSize(1, barHeight)
    f.bar3:SetColorTexture(0, 0.8, 0, 1)  -- Green
    
    -- +2 Bar (Mitte, über +2 Time)
    f.bar2Bg = f:CreateTexture(nil, "BACKGROUND")
    f.bar2Bg:SetSize(barWidth, barHeight)
    f.bar2Bg:SetPoint("CENTER", f.timerText, "CENTER", 0, barsYOffset)
    f.bar2Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.bar2 = f:CreateTexture(nil, "ARTWORK")
    f.bar2:SetPoint("LEFT", f.bar2Bg, "LEFT", 0, 0)
    f.bar2:SetSize(1, barHeight)
    f.bar2:SetColorTexture(1, 1, 0, 1)  -- Yellow
    
    -- +1 Bar (Rechts, über +1 Time)
    f.bar1Bg = f:CreateTexture(nil, "BACKGROUND")
    f.bar1Bg:SetSize(barWidth, barHeight)
    f.bar1Bg:SetPoint("CENTER", f.timerText, "CENTER", splitTimesSpacing, barsYOffset)
    f.bar1Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    f.bar1 = f:CreateTexture(nil, "ARTWORK")
    f.bar1:SetPoint("LEFT", f.bar1Bg, "LEFT", 0, 0)
    f.bar1:SetSize(1, barHeight)
    f.bar1:SetColorTexture(1, 0.5, 0, 1)  -- Orange


    
    -- ==================== DEATHS (Bottom Left with Icon) ====================
    f.deathIcon = f:CreateTexture(nil, "OVERLAY")
    f.deathIcon:SetTexture("Interface\\AddOns\\KryosDungeonTool\\Textures\\death")
    f.deathIcon:SetSize(24, 24)
    f.deathIcon:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 150, 65)  -- Von 80 auf 65 (tiefer)
    
    f.deathText = f:CreateFontString(nil, "OVERLAY")
    f.deathText:SetFont(font, 16, "OUTLINE")
    f.deathText:SetPoint("LEFT", f.deathIcon, "RIGHT", 8, 0)
    f.deathText:SetTextColor(1, 0, 0, 1)  -- Red
    f.deathText:SetText("Deaths: 2 (-10s)")
    
    -- Death tooltip frame
    f.deathFrame = CreateFrame("Frame", nil, f)
    f.deathFrame:SetSize(150, 30)
    f.deathFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 150, 60)  -- Von 75 auf 60
    f.deathFrame:EnableMouse(true)
    f.deathFrame:SetScript("OnEnter", function(self)
        if #KDT.timerState.deathLog > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
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
    
    -- ==================== TRASH PERCENTAGE (Bottom Right with Icon) ====================
    f.trashIcon = f:CreateTexture(nil, "OVERLAY")
    f.trashIcon:SetTexture("Interface\\AddOns\\KryosDungeonTool\\Textures\\trash")
    f.trashIcon:SetSize(24, 24)
    f.trashIcon:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -250, 65)  -- Von 80 auf 65 (tiefer)
    
    f.trashText = f:CreateFontString(nil, "OVERLAY")
    f.trashText:SetFont(font, 16, "OUTLINE")
    f.trashText:SetPoint("LEFT", f.trashIcon, "RIGHT", 8, 0)
    f.trashText:SetTextColor(0, 0.8, 1, 1)  -- Cyan
    f.trashText:SetText("Trash: 67%")
    
    -- Store reference
    self.ExternalTimer = f
    f:Hide()  -- Hidden by default
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
    
    -- Check if we're actually in M+ (via API)
    local inMythicPlus = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    state.inMythicPlus = inMythicPlus
    
    -- Show/Hide logic:
    local shouldShow = false
    if db.enabled then
        if inMythicPlus or state.active then
            shouldShow = true
        elseif state.completed and state.inInstance then
            shouldShow = true
        elseif db.showWhenInactive then
            shouldShow = true
        end
    end
    
    if not shouldShow then
        f:Hide()
        return
    end
    
    f:Show()
    
    -- Get times - use completion time if completed, otherwise live data
    local elapsed = 0
    local timeLimit = 1
    local deaths = 0
    local dungeonName = "Unknown"
    local level = 0
    local forcesPercent = 0
    local isPreviewMode = false
    
    -- CRITICAL: If completed, ALWAYS use the saved completion time
    if state.completed and state.completedTime > 0 then
        elapsed = state.completedTime
        timeLimit = state.timeLimit or 1
        deaths = state.deaths or 0
        dungeonName = state.dungeonName or "Completed"
        level = state.level or 0
        forcesPercent = state.forcesPercent or 100
    elseif inMythicPlus then
        -- Get data directly from API
        local mapID = C_ChallengeMode.GetActiveChallengeMapID()
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
        
        if mapID then
            local name, _, limit = C_ChallengeMode.GetMapUIInfo(mapID)
            if limit and limit > 0 then
                timeLimit = limit
            end
            if name then
                dungeonName = name
            end
        end
        
        if keystoneLevel then
            level = keystoneLevel
        end
        
        -- Get elapsed time
        local _, elapsedTime = GetWorldElapsedTime(1)
        if elapsedTime and elapsedTime > 0 then
            elapsed = elapsedTime
        end
        
        -- Get deaths
        local deathCount = C_ChallengeMode.GetDeathCount()
        if deathCount then
            deaths = deathCount
        end
        
        -- Get forces from scenario info
        local numCriteria = 0
        if C_Scenario and C_Scenario.GetStepInfo then
            local _, _, numCrit = C_Scenario.GetStepInfo()
            numCriteria = numCrit or 0
        end
        
        for i = 1, numCriteria do
            local criteriaInfo = C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo(i)
            if criteriaInfo then
                if criteriaInfo.isWeightedProgress then
                    local current = criteriaInfo.quantity or 0
                    local total = criteriaInfo.totalQuantity or 1
                    
                    -- TWW API FIX: For weighted progress, quantity IS the percentage (0-100)
                    -- NOT the absolute count! So quantity=100 means 100% complete.
                    forcesPercent = current  -- current is already the percentage!
                    
                    -- Calculate actual count for display
                    local actualCount = math.floor((current / 100) * total)
                    state.forcesCurrent = actualCount
                    state.forcesTotal = total
                    break
                end
            end
        end
        
        -- Update state values
        state.elapsed = elapsed
        state.timeLimit = timeLimit
        state.dungeonName = dungeonName
        state.level = level
        state.deaths = deaths
        state.forcesPercent = forcesPercent
    elseif state.active then
        elapsed = state.elapsed or 0
        timeLimit = state.timeLimit or 1
        deaths = state.deaths or 0
        dungeonName = state.dungeonName or "Unknown"
        level = state.level or 0
        forcesPercent = state.forcesPercent or 0
    elseif db.showWhenInactive then
        -- Preview mode with demo data for positioning
        isPreviewMode = true
        elapsed = 845 -- 14:05
        timeLimit = 1800 -- 30:00
        deaths = 2
        dungeonName = "Preview Mode"
        level = 12
        forcesPercent = 72.5
        -- Create demo boss data
        state.bosses = {
            {name = "First Boss", killed = true, killTime = 185},
            {name = "Second Boss", killed = true, killTime = 412},
            {name = "Third Boss", killed = false, killTime = nil},
            {name = "Final Boss", killed = false, killTime = nil},
        }
        state.forcesCurrent = 580
        state.forcesTotal = 800
    end
    
    if timeLimit <= 0 then timeLimit = 1 end
    
    local plus3Time = timeLimit * 0.6
    local plus2Time = timeLimit * 0.8
    local plus1Time = timeLimit
    
    -- ==================== Dungeon Name & Key Level ====================
    local headerText = dungeonName
    if level and level > 0 then
        headerText = string.format("%s |cFF80FF80+%d|r", dungeonName, level)
    end
    if isPreviewMode then
        headerText = "|cFFFF8800[PREVIEW]|r " .. headerText
    end
    f.dungeonText:SetText(headerText)
    
    -- ==================== Affixes ====================
    -- Get affixes from C_ChallengeMode API (WoW 12.0)
    local affixText = ""
    if inMythicPlus or (state.active and state.level > 0) then
        local affixes = C_MythicPlus.GetCurrentAffixes()
        if affixes and #affixes > 0 then
            local affixNames = {}
            for i, affix in ipairs(affixes) do
                local affixInfo = C_ChallengeMode.GetAffixInfo(affix.id)
                if affixInfo and affixInfo.name then
                    table.insert(affixNames, affixInfo.name)
                end
            end
            affixText = table.concat(affixNames, " / ")
        end
    end
    
    -- Fallback to placeholder if no affixes
    if affixText == "" then
        affixText = "Fortified / Raging / Volcanic"
    end
    f.affixText:SetText(affixText)
    
    -- ==================== Main Timer ====================
    f.timerText:SetText(self:FormatTime(elapsed))
    
    -- Color based on time thresholds
    local currentTimeTier = 0
    if state.completed then
        if elapsed <= plus3Time then
            f.timerText:SetTextColor(unpack(self:GetTimerColor("timerPlus3")))
            currentTimeTier = 4
        elseif elapsed <= plus2Time then
            f.timerText:SetTextColor(unpack(self:GetTimerColor("timerPlus2")))
            currentTimeTier = 3
        elseif elapsed <= plus1Time then
            f.timerText:SetTextColor(unpack(self:GetTimerColor("timerPlus1")))
            currentTimeTier = 2
        else
            f.timerText:SetTextColor(unpack(self:GetTimerColor("timerFail")))
            currentTimeTier = 1
        end
    elseif elapsed < plus3Time then
        f.timerText:SetTextColor(unpack(self:GetTimerColor("timerPlus3")))
        currentTimeTier = 4
    elseif elapsed < plus2Time then
        f.timerText:SetTextColor(unpack(self:GetTimerColor("timerPlus2")))
        currentTimeTier = 3
    elseif elapsed < plus1Time then
        f.timerText:SetTextColor(unpack(self:GetTimerColor("timerPlus1")))
        currentTimeTier = 2
    else
        f.timerText:SetTextColor(unpack(self:GetTimerColor("timerFail")))
        currentTimeTier = 1
    end
    
    -- ==================== Sound Alerts ====================
    if db.soundEnabled and inMythicPlus and not state.completed then
        -- +3 to +2 drop (Tier 4 to 3)
        if state.lastTimeTier == 4 and currentTimeTier == 3 and db.soundCD2 and not state.soundsPlayed.cd2 then
            PlaySoundFile("Interface\\AddOns\\KryosDungeonTool\\Sounds\\cd2.wav", "Master")
            state.soundsPlayed.cd2 = true
            self:Print("|cFFFF8800Timer Alert:|r +3 time lost!")
        end
        
        -- +2 to +1 drop (Tier 3 to 2)
        if state.lastTimeTier == 3 and currentTimeTier == 2 and db.soundCD1 and not state.soundsPlayed.cd1 then
            PlaySoundFile("Interface\\AddOns\\KryosDungeonTool\\Sounds\\cd1.wav", "Master")
            state.soundsPlayed.cd1 = true
            self:Print("|cFFFF8800Timer Alert:|r +2 time lost!")
        end
        
        -- Failed (Tier 2 to 1)
        if state.lastTimeTier == 2 and currentTimeTier == 1 and db.soundFailed and not state.soundsPlayed.failed then
            PlaySoundFile("Interface\\AddOns\\KryosDungeonTool\\Sounds\\failed.wav", "Master")
            state.soundsPlayed.failed = true
            self:Print("|cFFFF0000Timer Alert:|r Key failed!")
        end
        
        -- Update last tier
        state.lastTimeTier = currentTimeTier
    end
    
    -- Reset sound tracking when new run starts
    if state.lastTimeTier == 0 and currentTimeTier > 0 then
        state.lastTimeTier = currentTimeTier
        state.soundsPlayed.cd2 = false
        state.soundsPlayed.cd1 = false
        state.soundsPlayed.failed = false
    end
    
    -- ==================== Split Times ====================
    f.time3Text:SetText("+3: " .. self:FormatTime(plus3Time))
    f.time2Text:SetText("+2: " .. self:FormatTime(plus2Time))
    f.time1Text:SetText("+1: " .. self:FormatTime(plus1Time))
    
    -- ==================== Progress Bars ====================
    local barWidth = f.bar3Bg:GetWidth()
    
    -- Update bar colors from settings
    f.time3Text:SetTextColor(unpack(self:GetTimerColor("splitTimePlus3")))
    f.time2Text:SetTextColor(unpack(self:GetTimerColor("splitTimePlus2")))
    f.time1Text:SetTextColor(unpack(self:GetTimerColor("splitTimePlus1")))
    
    -- +3 Bar (fills from 0 to +3 time)
    if elapsed < plus3Time then
        local progress = elapsed / plus3Time
        f.bar3:SetWidth(math.max(1, barWidth * progress))
        f.bar3:SetColorTexture(unpack(self:GetTimerColor("barPlus3")))
    else
        f.bar3:SetWidth(barWidth)
        f.bar3:SetColorTexture(0.3, 0.5, 0.3, 0.8)  -- Darker green when complete
    end
    
    -- +2 Bar (fills from +3 time to +2 time)
    if elapsed < plus3Time then
        f.bar2:SetWidth(1)
        f.bar2:SetColorTexture(unpack(self:GetTimerColor("barPlus2")))
    elseif elapsed < plus2Time then
        local progress = (elapsed - plus3Time) / (plus2Time - plus3Time)
        f.bar2:SetWidth(math.max(1, barWidth * progress))
        f.bar2:SetColorTexture(unpack(self:GetTimerColor("barPlus2")))
    else
        f.bar2:SetWidth(barWidth)
        f.bar2:SetColorTexture(0.5, 0.5, 0.3, 0.8)  -- Darker yellow when complete
    end
    
    -- +1 Bar (fills from +2 time to +1 time)
    if elapsed < plus2Time then
        f.bar1:SetWidth(1)
        f.bar1:SetColorTexture(unpack(self:GetTimerColor("barPlus1")))
    elseif elapsed < plus1Time then
        local progress = (elapsed - plus2Time) / (plus1Time - plus2Time)
        f.bar1:SetWidth(math.max(1, barWidth * progress))
        f.bar1:SetColorTexture(unpack(self:GetTimerColor("barPlus1")))
    else
        f.bar1:SetWidth(barWidth)
        f.bar1:SetColorTexture(0.5, 0.3, 0.3, 0.8)  -- Darker orange when complete
    end

    
    -- ==================== Deaths ====================
    local deathPenalty = deaths * 5  -- 5 seconds per death
    f.deathText:SetText(string.format("Deaths: %d (-%ds)", deaths, deathPenalty))
    
    -- ==================== Trash Percentage ====================
    local forcesPct = state.forcesPercent or forcesPercent or 0
    f.trashText:SetText(string.format("Trash: %.1f%%", forcesPct))
    
    -- Change color when complete
    if forcesPct >= 100 then
        f.trashText:SetTextColor(0, 1, 0, 1)  -- Green
    else
        f.trashText:SetTextColor(0, 0.8, 1, 1)  -- Cyan
    end
end

-- ==================== CONTEXT MENU ====================
function KDT:ShowTimerContextMenu(frame)
    -- Create custom context menu (EasyMenu doesn't exist in WoW 12.0)
    if self.timerContextMenu then
        self.timerContextMenu:Hide()
        self.timerContextMenu = nil
        return
    end
    
    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetSize(160, 180)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    menu:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    menu:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    menu:SetFrameStrata("DIALOG")
    menu:SetPoint("CENTER", UIParent, "CENTER")
    self.timerContextMenu = menu
    
    -- Make it draggable
    menu:EnableMouse(true)
    menu:SetMovable(true)
    menu:RegisterForDrag("LeftButton")
    menu:SetScript("OnDragStart", menu.StartMoving)
    menu:SetScript("OnDragStop", menu.StopMovingOrSizing)
    
    local yOffset = -5
    local function AddButton(text, onClick, isChecked)
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(156, 20)
        btn:SetPoint("TOPLEFT", 2, yOffset)
        yOffset = yOffset - 22
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.4, 0.5)
        
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        label:SetPoint("LEFT", 8, 0)
        label:SetText(text)
        label:SetTextColor(0.9, 0.9, 0.9)
        
        if isChecked then
            local check = btn:CreateFontString(nil, "OVERLAY")
            check:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            check:SetPoint("RIGHT", -8, 0)
            check:SetText("*")
            check:SetTextColor(0.2, 1, 0.2)
        end
        
        btn:SetScript("OnClick", function()
            onClick()
            menu:Hide()
            self.timerContextMenu = nil
        end)
    end
    
    local function AddTitle(text)
        local label = menu:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        label:SetPoint("TOPLEFT", 8, yOffset)
        label:SetText(text)
        label:SetTextColor(0.6, 0.6, 0.2)
        yOffset = yOffset - 18
    end
    
    AddTitle("KDT Timer")
    AddButton("Lock Position", function() 
        self.DB.timer.locked = not self.DB.timer.locked
        self:Print("Timer " .. (self.DB.timer.locked and "locked" or "unlocked"))
    end, self.DB.timer.locked)
    AddButton("Show When Inactive", function()
        self.DB.timer.showWhenInactive = not self.DB.timer.showWhenInactive
    end, self.DB.timer.showWhenInactive)
    AddButton("Scale 75%", function() self:SetTimerScale(0.75) end)
    AddButton("Scale 100%", function() self:SetTimerScale(1.0) end)
    AddButton("Scale 125%", function() self:SetTimerScale(1.25) end)
    AddButton("Timer Settings", function() self:ShowTimerSettings() end)
    AddButton("Hide Timer", function()
        self.DB.timer.enabled = false
        self.ExternalTimer:Hide()
        self:UpdateDefaultTimerVisibility()
        self:Print("Timer hidden. Use /kdt timer to re-enable.")
    end)
    
    -- Adjust height
    menu:SetHeight(-yOffset + 10)
    
    -- Auto-close
    C_Timer.After(10, function()
        if menu and menu:IsShown() then
            menu:Hide()
            self.timerContextMenu = nil
        end
    end)
end

-- ==================== SET TIMER SCALE ====================
function KDT:SetTimerScale(scale)
    self.DB.timer.scale = scale
    if self.ExternalTimer then
        self.ExternalTimer:SetScale(scale)
    end
    self:Print("Timer scale set to " .. (scale * 100) .. "%")
end

-- ==================== TIMER SETTINGS FRAME ====================
function KDT:ShowTimerSettings()
    if self.timerSettingsFrame then
        self.timerSettingsFrame:Show()
        self.timerSettingsFrame:Raise()
        return
    end
    
    local db = self.DB.timer
    if not db.colors then db.colors = {} end
    
    -- Main frame with KDT style
    local f = CreateFrame("Frame", "KDTTimerSettings", UIParent, "BackdropTemplate")
    f:SetSize(420, 580)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
    f:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH") -- Lower strata so ColorPicker appears on top
    f:SetFrameLevel(50)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    titleBar:SetBackdropColor(0.1, 0.1, 0.12, 1)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 0)
    title:SetText("|cFFFFD100Timer Settings|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -8, -6)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(370, 1100)  -- Von 900 auf 1100 erhöht
    scrollFrame:SetScrollChild(content)
    
    local yPos = -5
    
    -- Helper: Create section header
    local function CreateHeader(text)
        local headerFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        headerFrame:SetSize(360, 24)
        headerFrame:SetPoint("TOPLEFT", 0, yPos)
        headerFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        headerFrame:SetBackdropColor(0.15, 0.15, 0.18, 1)
        
        local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerText:SetPoint("LEFT", 8, 0)
        headerText:SetText("|cFFFFD700" .. text .. "|r")
        
        yPos = yPos - 30
        return headerFrame
    end
    
    -- Helper: Create slider with immediate apply
    local function CreateSlider(label, key, min, max, step, default, applyFunc)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(360, 45)
        row:SetPoint("TOPLEFT", 5, yPos)
        
        local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        labelText:SetPoint("TOPLEFT", 0, 0)
        labelText:SetText(label)
        
        local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("TOPRIGHT", 0, 0)
        valueText:SetText(string.format("%.1f", db[key] or default))
        valueText:SetTextColor(0.4, 0.8, 1)
        
        local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 0, -18)
        slider:SetPoint("TOPRIGHT", 0, -18)
        slider:SetHeight(16)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(db[key] or default)
        slider.Low:SetText(min)
        slider.High:SetText(max)
        
        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / step + 0.5) * step -- Round to step
            db[key] = value
            valueText:SetText(string.format("%.1f", value))
            -- Apply immediately
            if applyFunc then
                applyFunc(value)
            end
            -- Recreate timer to apply font changes
            if key == "fontSize" or key == "headerFontSize" or key == "deathFontSize" then
                KDT:RecreateExternalTimer()
            elseif key == "scale" and KDT.ExternalTimer then
                KDT.ExternalTimer:SetScale(value)
            end
        end)
        
        yPos = yPos - 50
        return row
    end
    
    -- Helper: Create color button with color picker
    local function CreateColorRow(label, colorKey)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(360, 24)
        row:SetPoint("TOPLEFT", 5, yPos)
        
        local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        labelText:SetPoint("LEFT", 0, 0)
        labelText:SetText(label)
        
        local colorBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        colorBtn:SetSize(60, 18)
        colorBtn:SetPoint("RIGHT", 0, 0)
        colorBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        colorBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        local currentColor = db.colors[colorKey] or defaultColors[colorKey] or {1, 1, 1, 1}
        colorBtn:SetBackdropColor(currentColor[1], currentColor[2], currentColor[3], currentColor[4] or 1)
        
        -- Color picker - opens beside settings frame
        colorBtn:SetScript("OnClick", function()
            local r, g, b, a = unpack(db.colors[colorKey] or defaultColors[colorKey] or {1, 1, 1, 1})
            
            local function OnColorChanged()
                local newR, newG, newB
                if ColorPickerFrame.GetColorRGB then
                    newR, newG, newB = ColorPickerFrame:GetColorRGB()
                else
                    newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
                end
                local newA = 1
                if OpacitySliderFrame and OpacitySliderFrame:IsShown() then
                    newA = 1 - OpacitySliderFrame:GetValue()
                end
                db.colors[colorKey] = {newR, newG, newB, newA}
                colorBtn:SetBackdropColor(newR, newG, newB, newA)
            end
            
            local function OnCancel()
                db.colors[colorKey] = {r, g, b, a}
                colorBtn:SetBackdropColor(r, g, b, a)
            end
            
            -- TWW / WoW 11.0+ API
            if ColorPickerFrame.SetupColorPickerAndShow then
                local info = {
                    r = r, g = g, b = b,
                    opacity = a,
                    hasOpacity = true,
                    swatchFunc = OnColorChanged,
                    opacityFunc = OnColorChanged,
                    cancelFunc = OnCancel,
                }
                ColorPickerFrame:SetupColorPickerAndShow(info)
            else
                -- Legacy API (10.x and earlier)
                ColorPickerFrame.hasOpacity = true
                ColorPickerFrame.opacity = 1 - a
                ColorPickerFrame.previousValues = {r, g, b, a}
                ColorPickerFrame.func = OnColorChanged
                ColorPickerFrame.opacityFunc = OnColorChanged
                ColorPickerFrame.cancelFunc = OnCancel
                ColorPickerFrame:SetColorRGB(r, g, b)
                ColorPickerFrame:Hide()
                ColorPickerFrame:Show()
            end
            
            -- Position color picker to the RIGHT of settings frame
            ColorPickerFrame:ClearAllPoints()
            ColorPickerFrame:SetPoint("LEFT", f, "RIGHT", 10, 0)
        end)
        
        -- Hover effect
        colorBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 0.82, 0, 1)
        end)
        colorBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end)
        
        yPos = yPos - 26
        return row
    end
    
    -- Helper: Create checkbox
    local function CreateCheckbox(label, key)
        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", 5, yPos)
        cb.Text:SetText(label)
        cb.Text:SetFontObject("GameFontHighlight")
        cb:SetChecked(db[key])
        cb:SetScript("OnClick", function(self)
            db[key] = self:GetChecked()
        end)
        
        yPos = yPos - 28
        return cb
    end
    
    -- ==================== BUILD SETTINGS ====================
    
    -- General Settings
    CreateHeader("General Settings")
    CreateCheckbox("Lock Timer Position", "locked")
    CreateCheckbox("Show Timer Outside M+ (Preview)", "showWhenInactive")
    CreateSlider("Timer Scale", "scale", 0.5, 2.0, 0.05, 1.0)
    CreateSlider("Timer Font Size", "fontSize", 14, 40, 1, 28)
    CreateSlider("Header Font Size", "headerFontSize", 8, 20, 1, 14)
    CreateSlider("Death Font Size", "deathFontSize", 8, 20, 1, 16)
    
    yPos = yPos - 5
    
    -- Sound Alerts
    CreateHeader("Sound Alerts")
    CreateCheckbox("Enable Sound Alerts", "soundEnabled")
    CreateCheckbox("Play +3 → +2 Drop Sound (cd2.wav)", "soundCD2")
    CreateCheckbox("Play +2 → +1 Drop Sound (cd1.wav)", "soundCD1")
    CreateCheckbox("Play Failed Sound (failed.wav)", "soundFailed")
    
    -- Sound volume slider
    local soundNote = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    soundNote:SetPoint("TOPLEFT", 10, yPos)
    soundNote:SetText("|cFF888888Place sound files in: Interface\\AddOns\\KryosDungeonTool\\Sounds\\|r")
    soundNote:SetJustifyH("LEFT")
    yPos = yPos - 20
    
    yPos = yPos - 5
    
    -- Custom Font
    CreateHeader("Custom Font")
    
    -- Font path input
    local fontRow = CreateFrame("Frame", nil, content)
    fontRow:SetSize(360, 60)
    fontRow:SetPoint("TOPLEFT", 5, yPos)
    
    local fontLabel = fontRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontLabel:SetPoint("TOPLEFT", 0, 0)
    fontLabel:SetText("Font Path (relative to WoW folder):")
    
    local fontInput = CreateFrame("EditBox", nil, fontRow, "InputBoxTemplate")
    fontInput:SetSize(350, 20)
    fontInput:SetPoint("TOPLEFT", 0, -20)
    fontInput:SetAutoFocus(false)
    fontInput:SetText(db.customFont or "Fonts\\FRIZQT__.TTF")
    fontInput:SetScript("OnEnterPressed", function(self)
        db.customFont = self:GetText()
        self:ClearFocus()
        KDT:RecreateExternalTimer()
        KDT:Print("Custom font applied: " .. (db.customFont or "default"))
    end)
    fontInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    local fontNote = fontRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontNote:SetPoint("TOPLEFT", 0, -42)
    fontNote:SetText("|cFF888888Press Enter to apply. Examples: Fonts\\ARIALN.TTF, Fonts\\skurri.ttf|r")
    fontNote:SetJustifyH("LEFT")
    
    yPos = yPos - 68
    
    yPos = yPos - 5
    
    -- Timer Text Colors
    CreateHeader("Timer Text Colors")
    CreateColorRow("+3 Time (ahead)", "timerPlus3")
    CreateColorRow("+2 Time", "timerPlus2")
    CreateColorRow("+1 Time", "timerPlus1")
    CreateColorRow("Over Time (failed)", "timerFail")
    
    yPos = yPos - 5
    
    -- Progress Bar Colors
    CreateHeader("Progress Bar Colors")
    CreateColorRow("+3 Bar", "barPlus3")
    CreateColorRow("+2 Bar", "barPlus2")
    CreateColorRow("+1 Bar", "barPlus1")
    
    yPos = yPos - 5
    
    -- Forces Colors
    CreateHeader("Forces Colors")
    CreateColorRow("Forces Incomplete", "forcesIncomplete")
    CreateColorRow("Forces Complete", "forcesComplete")
    CreateColorRow("Forces Bar", "forcesBar")
    
    yPos = yPos - 5
    
    -- Boss Colors
    CreateHeader("Boss Colors")
    CreateColorRow("Boss Incomplete", "bossIncomplete")
    CreateColorRow("Boss Complete", "bossComplete")
    
    yPos = yPos - 5
    
    -- Other Colors
    CreateHeader("Other Colors")
    CreateColorRow("Dungeon Name", "dungeonName")
    CreateColorRow("Death Counter", "deaths")
    
    -- Set content height
    content:SetHeight(math.abs(yPos) + 20)
    
    -- Bottom buttons (2 rows, 2 columns)
    local buttonFrame = CreateFrame("Frame", nil, f)
    buttonFrame:SetHeight(65)
    buttonFrame:SetPoint("BOTTOMLEFT", 10, 5)
    buttonFrame:SetPoint("BOTTOMRIGHT", -10, 5)
    
    local btnWidth = 185
    local btnHeight = 26
    
    -- Row 1: Reset Position, Reset Colors
    local resetPosBtn = CreateFrame("Button", nil, buttonFrame, "BackdropTemplate")
    resetPosBtn:SetSize(btnWidth, btnHeight)
    resetPosBtn:SetPoint("TOPLEFT", 0, 0)
    resetPosBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    resetPosBtn:SetBackdropColor(0.2, 0.2, 0.25, 1)
    resetPosBtn:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
    
    local resetPosText = resetPosBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetPosText:SetPoint("CENTER")
    resetPosText:SetText("Reset Position")
    
    resetPosBtn:SetScript("OnClick", function()
        db.position = nil
        if KDT.ExternalTimer then
            KDT.ExternalTimer:ClearAllPoints()
            KDT.ExternalTimer:SetPoint("RIGHT", UIParent, "RIGHT", -50, 100)
        end
        KDT:Print("Timer position reset.")
    end)
    resetPosBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.3, 0.35, 1) end)
    resetPosBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.25, 1) end)
    
    local resetColorsBtn = CreateFrame("Button", nil, buttonFrame, "BackdropTemplate")
    resetColorsBtn:SetSize(btnWidth, btnHeight)
    resetColorsBtn:SetPoint("TOPRIGHT", 0, 0)
    resetColorsBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    resetColorsBtn:SetBackdropColor(0.2, 0.2, 0.25, 1)
    resetColorsBtn:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
    
    local resetColorsText = resetColorsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetColorsText:SetPoint("CENTER")
    resetColorsText:SetText("Reset Colors")
    
    resetColorsBtn:SetScript("OnClick", function()
        db.colors = {}
        f:Hide()
        KDT.timerSettingsFrame = nil
        KDT:RecreateExternalTimer()
        KDT:Print("Colors reset to defaults.")
    end)
    resetColorsBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.3, 0.35, 1) end)
    resetColorsBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.25, 1) end)
    
    -- Row 2: Reset All, Hide Timer
    local resetAllBtn = CreateFrame("Button", nil, buttonFrame, "BackdropTemplate")
    resetAllBtn:SetSize(btnWidth, btnHeight)
    resetAllBtn:SetPoint("BOTTOMLEFT", 0, 0)
    resetAllBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    resetAllBtn:SetBackdropColor(0.3, 0.2, 0.1, 1)
    resetAllBtn:SetBackdropBorderColor(0.5, 0.35, 0.2, 1)
    
    local resetAllText = resetAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetAllText:SetPoint("CENTER")
    resetAllText:SetText("|cFFFFAA00Reset All|r")
    
    resetAllBtn:SetScript("OnClick", function()
        -- Reset ALL settings to defaults
        db.colors = {}
        db.position = nil
        db.scale = 1.0
        db.fontSize = 28
        db.headerFontSize = 14
        db.deathFontSize = 16
        db.locked = false
        db.showWhenInactive = false
        db.enabled = true
        
        f:Hide()
        KDT.timerSettingsFrame = nil
        KDT:RecreateExternalTimer()
        KDT:Print("All timer settings reset to defaults.")
    end)
    resetAllBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.4, 0.3, 0.15, 1) end)
    resetAllBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.3, 0.2, 0.1, 1) end)
    
    local hideBtn = CreateFrame("Button", nil, buttonFrame, "BackdropTemplate")
    hideBtn:SetSize(btnWidth, btnHeight)
    hideBtn:SetPoint("BOTTOMRIGHT", 0, 0)
    hideBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    hideBtn:SetBackdropColor(0.4, 0.15, 0.15, 1)
    hideBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)
    
    local hideText = hideBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hideText:SetPoint("CENTER")
    hideText:SetText("|cFFFF6666Hide Timer|r")
    
    hideBtn:SetScript("OnClick", function()
        db.enabled = false
        if KDT.ExternalTimer then
            KDT.ExternalTimer:Hide()
        end
        KDT:UpdateDefaultTimerVisibility()
        KDT:Print("Timer hidden. Use /kdt timer to re-enable.")
        f:Hide()
    end)
    hideBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.5, 0.2, 0.2, 1) end)
    hideBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.4, 0.15, 0.15, 1) end)
    
    self.timerSettingsFrame = f
end

-- ==================== RECREATE TIMER (for font changes) ====================
function KDT:RecreateExternalTimer()
    local wasShown = self.ExternalTimer and self.ExternalTimer:IsShown()
    local position = self.DB.timer.position
    
    if self.ExternalTimer then
        self.ExternalTimer:Hide()
        self.ExternalTimer:SetParent(nil)
        self.ExternalTimer = nil
    end
    
    self:CreateExternalTimer()
    
    if position then
        self.ExternalTimer:ClearAllPoints()
        self.ExternalTimer:SetPoint(position.point or "RIGHT", UIParent, position.relPoint or "RIGHT", position.x or -50, position.y or 100)
    end
    
    if wasShown or self.DB.timer.showWhenInactive then
        self.ExternalTimer:Show()
    end
end

-- ==================== UPDATE TIMER FROM GAME ====================
function KDT:UpdateTimerFromGame()
    local state = self.timerState
    
    local inInstance, instanceType = IsInInstance()
    state.inInstance = inInstance and (instanceType == "party")
    
    local inChallenge = C_ChallengeMode.IsChallengeModeActive()
    state.inMythicPlus = inChallenge
    
    -- Keep showing completion after leaving, then reset
    if not state.inInstance and state.completed then
        if not state.leaveTimer then
            state.leaveTimer = GetTime()
        elseif GetTime() - state.leaveTimer > 30 then
            state.completed = false
            state.completedTime = 0
            state.leaveTimer = nil
        end
    else
        state.leaveTimer = nil
    end
    
    if inChallenge then
        local mapChallengeModeID = C_ChallengeMode.GetActiveChallengeMapID()
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
        
        if mapChallengeModeID and keystoneLevel then
            local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
            local _, elapsedTime = GetWorldElapsedTime(1)
            
            if elapsedTime and elapsedTime > 0 then
                if not state.active and not state.completed then
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
                    state.savedToHistory = false
                    state.saveScheduled = false
                    
                    self:Print("M+ Timer started: " .. state.dungeonName .. " +" .. state.level)
                end
                
                -- CRITICAL: Don't update elapsed if already completed
                if not state.completed then
                    state.elapsed = elapsedTime
                end
                state.timeLimit = timeLimit
                
                local apiDeaths, timeLost = C_ChallengeMode.GetDeathCount()
                if apiDeaths then
                    state.deaths = apiDeaths
                end
                
                self:UpdateScenarioInfo()
                
                -- Check for completion
                if not state.completed then
                    local isComplete = false
                    local completedTime = 0
                    
                    if C_ChallengeMode.GetCompletionInfo then
                        local mapChallenge, levelChallenge, timeChallenge = C_ChallengeMode.GetCompletionInfo()
                        if timeChallenge and timeChallenge > 0 then
                            isComplete = true
                            completedTime = timeChallenge / 1000
                        end
                    end
                    
                    if not isComplete and C_ChallengeMode.GetChallengeCompletionInfo then
                        local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
                        if completionInfo and completionInfo.time and completionInfo.time > 0 then
                            isComplete = true
                            completedTime = completionInfo.time / 1000
                        end
                    end
                    
                    if not isComplete and C_Scenario and C_Scenario.IsComplete then
                        local scenarioComplete = C_Scenario.IsComplete()
                        if scenarioComplete then
                            isComplete = true
                            completedTime = elapsedTime
                        end
                    end
                    
                    if not isComplete and state.forcesPercent >= 100 then
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
                        
                        -- Mark last boss as killed
                        if state.bosses and #state.bosses > 0 then
                            local lastBoss = state.bosses[#state.bosses]
                            if lastBoss and not lastBoss.killed then
                                lastBoss.killed = true
                                lastBoss.killTime = state.completedTime
                            end
                        end
                        
                        if not state.saveScheduled then
                            state.saveScheduled = true
                            C_Timer.After(5, function()
                                if state.completed and not state.savedToHistory then
                                    self:SaveRunToHistory()
                                end
                            end)
                        end
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
    
    if state.completed then return end
    
    local numCriteria = 0
    if C_Scenario and C_Scenario.GetStepInfo then
        local _, _, num = C_Scenario.GetStepInfo()
        numCriteria = num or 0
    end
    
    if numCriteria == 0 then return end
    
    local oldBosses = state.bosses or {}
    state.bosses = {}
    
    for i = 1, numCriteria do
        local criteriaInfo = C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo(i)
        
        if criteriaInfo then
            local desc = criteriaInfo.description or ""
            local completed = criteriaInfo.completed
            local quantity = criteriaInfo.quantity
            local totalQuantity = criteriaInfo.totalQuantity
            
            local isForces = criteriaInfo.isWeightedProgress or 
                            desc:find("Enemy Forces") or 
                            desc:find("Feindliche") or
                            desc:find("Forces ennemies") or
                            (i == numCriteria and totalQuantity and totalQuantity > 100)
            
            if isForces then
                local total = totalQuantity or 0
                local current = quantity or 0
                local percent = 0
                
                -- TWW API FIX: In WoW 12.0+, for weighted progress criteria:
                -- - quantity is already the PERCENTAGE value (0-100)
                -- - totalQuantity is the total available forces in dungeon (e.g., 346)
                -- So if quantity=100 and totalQuantity=346, it means 100% complete!
                
                if criteriaInfo.isWeightedProgress then
                    -- For weighted progress, quantity IS the percentage
                    percent = current
                    -- Calculate actual count for display: (percent/100) * total
                    local actualCount = math.floor((current / 100) * total)
                    state.forcesCurrent = actualCount
                    state.forcesTotal = total
                elseif total > 0 then
                    -- Fallback for non-weighted: traditional calculation
                    percent = (current / total) * 100
                    state.forcesCurrent = current
                    state.forcesTotal = total
                else
                    state.forcesCurrent = current
                    state.forcesTotal = total
                end
                
                state.forcesPercent = math.min(100, percent)
            else
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
    state.savedToHistory = false
    state.saveScheduled = false
    state.leaveTimer = nil
end

-- ==================== RUN HISTORY ====================
function KDT:SaveRunToHistory()
    local state = self.timerState
    
    if state.savedToHistory then return end
    if not state.completed then return end
    
    local dungeonName = state.dungeonName
    if (not dungeonName or dungeonName == "" or dungeonName == "Unknown") and state.mapID then
        dungeonName = self:GetDungeonName(state.mapID) or self:GetShortDungeonName(state.mapID) or "Unknown Dungeon"
    end
    
    if not dungeonName or dungeonName == "" then
        dungeonName = "Unknown Dungeon"
    end
    
    if not self.DB.runHistory then
        self.DB.runHistory = {}
    end
    
    local completedTime = state.completedTime
    if completedTime == 0 or not completedTime then
        completedTime = state.elapsed or 0
    end
    
    local currentTime = time()
    for _, existingRun in ipairs(self.DB.runHistory) do
        if existingRun.dungeon == dungeonName and 
           existingRun.level == (state.level or 0) and
           existingRun.timestamp and 
           math.abs(currentTime - existingRun.timestamp) < 120 then
            state.savedToHistory = true
            return
        end
    end
    
    local timeLimit = state.timeLimit or 0
    local inTime = timeLimit > 0 and completedTime <= timeLimit
    local plus3 = timeLimit > 0 and completedTime <= timeLimit * 0.6
    local plus2 = timeLimit > 0 and completedTime <= timeLimit * 0.8
    
    local upgrade = 0
    if plus3 then upgrade = 3
    elseif plus2 then upgrade = 2
    elseif inTime then upgrade = 1
    end
    
    local runEntry = {
        dungeon = dungeonName,
        level = state.level or 0,
        time = completedTime,
        timeLimit = timeLimit,
        inTime = inTime,
        upgrade = upgrade,
        deaths = state.deaths or 0,
        date = date("%Y-%m-%d %H:%M"),
        timestamp = currentTime,
    }
    
    state.savedToHistory = true
    table.insert(self.DB.runHistory, 1, runEntry)
    
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
-- CRITICAL FIX: Only hide in M+, and properly collapse (not just alpha=0)
function KDT:UpdateDefaultTimerVisibility()
    local state = self.timerState
    
    -- Only hide if: 1. Our timer is enabled, 2. We are IN a Mythic+ dungeon
    local inMythicPlus = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    local shouldHide = self.DB and self.DB.timer and self.DB.timer.enabled and (inMythicPlus or state.inMythicPlus)
    
    -- ScenarioBlocksFrame (older versions)
    if ScenarioBlocksFrame then
        if shouldHide then
            if not ScenarioBlocksFrame.kdtOrigHeight then
                ScenarioBlocksFrame.kdtOrigHeight = ScenarioBlocksFrame:GetHeight()
            end
            ScenarioBlocksFrame:SetAlpha(0)
            ScenarioBlocksFrame:SetHeight(1)
            ScenarioBlocksFrame:EnableMouse(false)
        else
            ScenarioBlocksFrame:SetAlpha(1)
            ScenarioBlocksFrame:SetHeight(ScenarioBlocksFrame.kdtOrigHeight or 100)
            ScenarioBlocksFrame:EnableMouse(true)
        end
    end
    
    -- ObjectiveTrackerFrame ScenarioHeader
    if ObjectiveTrackerFrame and ObjectiveTrackerFrame.BlocksFrame then
        local blocksFrame = ObjectiveTrackerFrame.BlocksFrame
        if blocksFrame.ScenarioHeader then
            if shouldHide then
                if not blocksFrame.ScenarioHeader.kdtOrigHeight then
                    blocksFrame.ScenarioHeader.kdtOrigHeight = blocksFrame.ScenarioHeader:GetHeight()
                end
                blocksFrame.ScenarioHeader:SetAlpha(0)
                blocksFrame.ScenarioHeader:SetHeight(1)
            else
                blocksFrame.ScenarioHeader:SetAlpha(1)
                blocksFrame.ScenarioHeader:SetHeight(blocksFrame.ScenarioHeader.kdtOrigHeight or 50)
            end
        end
    end
    
    -- ScenarioObjectiveTracker (WoW 12.0+) - Most important for TWW
    if ScenarioObjectiveTracker then
        if shouldHide then
            if not ScenarioObjectiveTracker.kdtOrigHeight then
                ScenarioObjectiveTracker.kdtOrigHeight = ScenarioObjectiveTracker:GetHeight()
            end
            ScenarioObjectiveTracker:SetAlpha(0)
            ScenarioObjectiveTracker:SetHeight(1)
            ScenarioObjectiveTracker:EnableMouse(false)
            if ScenarioObjectiveTracker.Header then
                if not ScenarioObjectiveTracker.Header.kdtOrigHeight then
                    ScenarioObjectiveTracker.Header.kdtOrigHeight = ScenarioObjectiveTracker.Header:GetHeight()
                end
                ScenarioObjectiveTracker.Header:SetAlpha(0)
                ScenarioObjectiveTracker.Header:SetHeight(1)
            end
            if ScenarioObjectiveTracker.ContentsFrame then
                ScenarioObjectiveTracker.ContentsFrame:SetAlpha(0)
                ScenarioObjectiveTracker.ContentsFrame:SetHeight(1)
            end
        else
            ScenarioObjectiveTracker:SetAlpha(1)
            ScenarioObjectiveTracker:SetHeight(ScenarioObjectiveTracker.kdtOrigHeight or 150)
            ScenarioObjectiveTracker:EnableMouse(true)
            if ScenarioObjectiveTracker.Header then
                ScenarioObjectiveTracker.Header:SetAlpha(1)
                ScenarioObjectiveTracker.Header:SetHeight(ScenarioObjectiveTracker.Header.kdtOrigHeight or 25)
            end
            if ScenarioObjectiveTracker.ContentsFrame then
                ScenarioObjectiveTracker.ContentsFrame:SetAlpha(1)
            end
        end
    end
    
    -- ObjectiveTrackerScenarioHeader (alternative)
    if ObjectiveTrackerScenarioHeader then
        if shouldHide then
            if not ObjectiveTrackerScenarioHeader.kdtOrigHeight then
                ObjectiveTrackerScenarioHeader.kdtOrigHeight = ObjectiveTrackerScenarioHeader:GetHeight()
            end
            ObjectiveTrackerScenarioHeader:SetAlpha(0)
            ObjectiveTrackerScenarioHeader:SetHeight(1)
        else
            ObjectiveTrackerScenarioHeader:SetAlpha(1)
            ObjectiveTrackerScenarioHeader:SetHeight(ObjectiveTrackerScenarioHeader.kdtOrigHeight or 50)
        end
    end
    
    -- ==================== HIDE QUEST TRACKER IN M+ ====================
    -- Hide QuestObjectiveTracker (WoW 12.0+ main quest tracker module)
    if QuestObjectiveTracker then
        if shouldHide then
            if not QuestObjectiveTracker.kdtOrigHeight then
                QuestObjectiveTracker.kdtOrigHeight = QuestObjectiveTracker:GetHeight()
            end
            QuestObjectiveTracker:SetAlpha(0)
            QuestObjectiveTracker:SetHeight(1)
            QuestObjectiveTracker:EnableMouse(false)
            -- Also hide header and contents if they exist
            if QuestObjectiveTracker.Header then
                QuestObjectiveTracker.Header:SetAlpha(0)
                QuestObjectiveTracker.Header:SetHeight(1)
            end
            if QuestObjectiveTracker.ContentsFrame then
                QuestObjectiveTracker.ContentsFrame:SetAlpha(0)
                QuestObjectiveTracker.ContentsFrame:SetHeight(1)
            end
        else
            QuestObjectiveTracker:SetAlpha(1)
            QuestObjectiveTracker:SetHeight(QuestObjectiveTracker.kdtOrigHeight or 200)
            QuestObjectiveTracker:EnableMouse(true)
            if QuestObjectiveTracker.Header then
                QuestObjectiveTracker.Header:SetAlpha(1)
            end
            if QuestObjectiveTracker.ContentsFrame then
                QuestObjectiveTracker.ContentsFrame:SetAlpha(1)
            end
        end
    end
    
    -- Hide Quest header in ObjectiveTrackerFrame.BlocksFrame (WoW 12.0+)
    if ObjectiveTrackerFrame and ObjectiveTrackerFrame.BlocksFrame then
        local blocksFrame = ObjectiveTrackerFrame.BlocksFrame
        if blocksFrame.QuestHeader then
            if shouldHide then
                if not blocksFrame.QuestHeader.kdtOrigHeight then
                    blocksFrame.QuestHeader.kdtOrigHeight = blocksFrame.QuestHeader:GetHeight()
                end
                blocksFrame.QuestHeader:SetAlpha(0)
                blocksFrame.QuestHeader:SetHeight(1)
            else
                blocksFrame.QuestHeader:SetAlpha(1)
                blocksFrame.QuestHeader:SetHeight(blocksFrame.QuestHeader.kdtOrigHeight or 50)
            end
        end
    end
    
    -- Hide entire ObjectiveTrackerFrame in M+ (nuclear option for TWW)
    -- This ensures NOTHING from the default tracker shows, including quests
    if ObjectiveTrackerFrame then
        if shouldHide then
            if not ObjectiveTrackerFrame.kdtWasShown then
                ObjectiveTrackerFrame.kdtWasShown = ObjectiveTrackerFrame:IsShown()
            end
            -- Instead of hiding completely (which might cause issues), 
            -- move it way off screen or set alpha to 0
            if not ObjectiveTrackerFrame.kdtOrigAlpha then
                ObjectiveTrackerFrame.kdtOrigAlpha = ObjectiveTrackerFrame:GetAlpha()
            end
            ObjectiveTrackerFrame:SetAlpha(0)
            ObjectiveTrackerFrame:EnableMouse(false)
        else
            if ObjectiveTrackerFrame.kdtOrigAlpha then
                ObjectiveTrackerFrame:SetAlpha(ObjectiveTrackerFrame.kdtOrigAlpha)
            else
                ObjectiveTrackerFrame:SetAlpha(1)
            end
            ObjectiveTrackerFrame:EnableMouse(true)
        end
    end
    
    -- Force ObjectiveTracker relayout
    if ObjectiveTrackerFrame and ObjectiveTrackerFrame.Update then
        if not self.lastTrackerUpdate or GetTime() - self.lastTrackerUpdate > 1 then
            self.lastTrackerUpdate = GetTime()
            C_Timer.After(0.1, function()
                if ObjectiveTrackerFrame.Update then
                    pcall(ObjectiveTrackerFrame.Update, ObjectiveTrackerFrame)
                end
            end)
        end
    end
end

-- ==================== INITIALIZE TIMER ====================
function KDT:InitializeTimer()
    if not self.DB.timer then
        self.DB.timer = {}
    end
    
    local defaults = {
        enabled = true,
        locked = false,
        scale = 1.0,
        fontSize = 28,
        headerFontSize = 14,
        deathFontSize = 16,
        showWhenInactive = false,
        position = nil,
        colors = {},
        -- Sound Alerts
        soundEnabled = true,
        soundCD2 = true,      -- +3 to +2 drop sound
        soundCD1 = true,      -- +2 to +1 drop sound
        soundFailed = true,   -- Failed sound
        soundVolume = 1.0,    -- 0.0 to 1.0
        -- Custom Font
        customFont = "Fonts\\FRIZQT__.TTF",
    }
    
    for k, v in pairs(defaults) do
        if self.DB.timer[k] == nil then
            self.DB.timer[k] = v
        end
    end
    
    self:CreateExternalTimer()
    self:UpdateDefaultTimerVisibility()
    
    self.timerTicker = C_Timer.NewTicker(0.1, function()
        KDT:UpdateTimerFromGame()
        KDT:UpdateExternalTimer()
        KDT:UpdateDefaultTimerVisibility()
    end)
end

-- ==================== TOGGLE TIMER ====================
function KDT:ToggleTimer()
    if not self.DB.timer then
        self.DB.timer = {}
    end
    
    self.DB.timer.enabled = not self.DB.timer.enabled
    
    if self.DB.timer.enabled then
        if not self.ExternalTimer then
            self:CreateExternalTimer()
        end
        self:Print("Timer overlay enabled.")
    else
        if self.ExternalTimer then
            self.ExternalTimer:Hide()
        end
        self:Print("Timer overlay disabled.")
    end
    
    self:UpdateDefaultTimerVisibility()
end
