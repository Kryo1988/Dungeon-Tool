-- Kryos Dungeon Tool
-- Modules/MouseCursor.lua - Mouse Cursor Enhancement Module (WoW 12.0 Compatible)

local addonName, KDT = ...

KDT.MouseCursor = {}
local MC = KDT.MouseCursor

-- Default configuration
MC.defaults = {
    enabled = false,
    scale = 1.0,
    innerRing = "GCD",
    mainRing = "Main Ring",
    outerRing = "Cast",
    usePowerColors = false,
    
    -- Color modes: "default", "class", or "custom"
    reticleColorMode = "default",
    reticleCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    mainRingColorMode = "default",
    mainRingCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    gcdColorMode = "default",
    gcdCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    castColorMode = "default",
    castCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    healthColorMode = "default",
    healthCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    healthColorLock = false,
    trailColorMode = "default",
    trailCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    powerColorMode = "default",
    powerCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    
    enableTrail = false,
    trailUseClassColor = false,
    trailDuration = 0.5,
    trailDensity = 0.005,
    trailScale = 1.0,
    trailMinMovement = 0.5,
    showOnlyInCombat = false,
    shiftAction = "None",
    ctrlAction = "None",
    altAction = "None",
    reticle = "Dot",
    reticleScale = 1.5,
    transparency = 1.0,
    
    -- High Contrast Ring settings
    highContrastOuterThickness = 2,
    highContrastOuterColor = {r = 0.0, g = 0.0, b = 0.0},
    highContrastOuterColorMode = "default",
    highContrastInnerThickness = -4,
    highContrastInnerColor = {r = 1.0, g = 1.0, b = 1.0},
    highContrastInnerColorMode = "default",
    
    -- Cast/GCD Animation settings
    gcdFillDrain = "fill",
    castFillDrain = "fill",
    gcdRotation = 12,
    castRotation = 12,
}

-- Ring options
MC.ringOptions = {
    "None",
    "Main Ring",
    "Main Ring + GCD",
    "Main Ring + Cast",
    "Cast",
    "GCD",
    "Health and Power",
    "Health",
    "Power",
    "High Contrast Ring",
}

-- Modifier options
MC.modifierOptions = {
    "None",
    "Show Rings",
    "Ping with ring",
    "Ping with area",
    "Ping with crosshair",
    "Show Crosshair",
}

-- Reticle options
MC.reticleOptions = {
    "Dot",
    "Chevron",
    "Crosshair",
    "Diamond",
    "Flatline",
    "Star",
    "Ring",
    "Tech Arrow",
    "X",
    "No Reticle",
}

-- Reticle textures
MC.reticleTextures = {
    ["Dot"] = { path = "Interface\\Addons\\KryosDungeonTool\\Textures\\Reticle_Dot", scale = 0.5 },
    ["Chevron"] = { path = "uitools-icon-chevron-down", scale = 1.0, isAtlas = true },
    ["Crosshair"] = { path = "uitools-icon-plus", scale = 1.0, isAtlas = true },
    ["Diamond"] = { path = "UF-SoulShard-FX-FrameGlow", scale = 1.0, isAtlas = true },
    ["Flatline"] = { path = "uitools-icon-minus", scale = 1.0, isAtlas = true },
    ["Star"] = { path = "AftLevelup-WhiteStarBurst", scale = 2.0, isAtlas = true },
    ["Ring"] = { path = "Interface\\Addons\\KryosDungeonTool\\Textures\\Reticle_Circle", scale = 1.0 },
    ["Tech Arrow"] = { path = "ProgLan-w-4", scale = 1.0, isAtlas = true },
    ["X"] = { path = "uitools-icon-close", scale = 1.0, isAtlas = true },
    ["No Reticle"] = { path = nil, scale = 1.0 },
}

-- Runtime state
MC.currentGroupScale = 1.0
MC.lastGCDTime = 0
MC.isGCDAnimating = false
MC.isCasting = false
MC.lastHealthPercent = 1.0
MC.lastPowerPercent = 1.0
MC.trailElements = {}
MC.trailActive = {}
MC.trailTimer = 0
MC.trailLastX = 0
MC.trailLastY = 0
MC.lastShiftState = false
MC.lastCtrlState = false
MC.lastAltState = false
MC.pingTimer = 0
MC.isPingAnimating = false
MC.pingDuration = 0.5
MC.pingStartSize = 250
MC.pingEndSize = 70
MC.crosshairTimer = 0
MC.isCrosshairAnimating = false
MC.crosshairDuration = 1.5
MC.crosshairGap = 35
MC.GCDCooldownFrame = nil
MC.GCDBackgroundFrame = nil
MC.CastFrame = nil
MC.CastBackgroundFrame = nil
MC.HealthFrame = nil
MC.HealthBackgroundFrame = nil
MC.PowerFrame = nil

-- Initialize configuration from saved variables
function MC:InitConfig()
    if not KDT.DB.mouseCursor then
        KDT.DB.mouseCursor = {}
    end
    
    for key, value in pairs(self.defaults) do
        if KDT.DB.mouseCursor[key] == nil then
            KDT.DB.mouseCursor[key] = value
        end
    end
end

-- Get configuration value
function MC:GetConfig(key)
    if not KDT.DB.mouseCursor then
        return self.defaults[key]
    end
    return KDT.DB.mouseCursor[key] or self.defaults[key]
end

-- Set configuration value
function MC:SetConfig(key, value)
    if not KDT.DB.mouseCursor then
        KDT.DB.mouseCursor = {}
    end
    KDT.DB.mouseCursor[key] = value
end

-- Get class color for ring type
function MC:GetClassColor(ringType)
    local colorMode = "default"
    local customColor = nil
    
    if ringType == "main" then
        colorMode = self:GetConfig("mainRingColorMode")
        customColor = self:GetConfig("mainRingCustomColor")
    elseif ringType == "gcd" then
        colorMode = self:GetConfig("gcdColorMode")
        customColor = self:GetConfig("gcdCustomColor")
    elseif ringType == "cast" then
        colorMode = self:GetConfig("castColorMode")
        customColor = self:GetConfig("castCustomColor")
    elseif ringType == "reticle" then
        colorMode = self:GetConfig("reticleColorMode")
        customColor = self:GetConfig("reticleCustomColor")
    elseif ringType == "trail" then
        colorMode = self:GetConfig("trailColorMode")
        customColor = self:GetConfig("trailCustomColor")
    elseif ringType == "power" then
        colorMode = self:GetConfig("powerColorMode")
        customColor = self:GetConfig("powerCustomColor")
    end
    
    -- Return custom color if mode is custom
    if colorMode == "custom" and customColor then
        return customColor.r or 1.0, customColor.g or 1.0, customColor.b or 1.0
    end
    
    -- Return class color if mode is class
    if colorMode == "class" then
        local _, class = UnitClass("player")
        local classColor = C_ClassColor.GetClassColor(class)
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end
    
    -- Return default color
    if ringType == "power" then
        return 0.0, 0.5, 1.0  -- Cyan blue for power
    else
        return 1.0, 1.0, 1.0  -- White for others
    end
end

-- Convert clock position to radians
function MC:ClockToRadians(clockPosition)
    local position = (clockPosition == 12) and 0 or clockPosition
    return (position * math.pi / 6)
end

-- Set group scale
function MC:SetGroupScale(scale)
    self.currentGroupScale = scale
    if KDT_MouseCursorFrame then
        KDT_MouseCursorFrame:SetScale(scale)
    end
end

-- Update reticle
function MC:UpdateReticle()
    if not KDT_MouseCursorFrame then return end
    
    local reticleType = self:GetConfig("reticle")
    local reticleData = self.reticleTextures[reticleType]
    
    if not reticleData or not reticleData.path then
        if KDT_MouseCursorFrame.Reticle then
            KDT_MouseCursorFrame.Reticle:Hide()
        end
        return
    end
    
    if not KDT_MouseCursorFrame.Reticle then
        KDT_MouseCursorFrame.Reticle = KDT_MouseCursorFrame:CreateTexture(nil, "OVERLAY")
        KDT_MouseCursorFrame.Reticle:SetPoint("CENTER")
    end
    
    local reticle = KDT_MouseCursorFrame.Reticle
    local baseSize = 25 * reticleData.scale * self:GetConfig("reticleScale")
    reticle:SetSize(baseSize, baseSize)
    
    if reticleData.isAtlas then
        reticle:SetAtlas(reticleData.path)
    else
        reticle:SetTexture(reticleData.path)
    end
    
    local r, g, b = self:GetClassColor("reticle")
    reticle:SetVertexColor(r, g, b)
    reticle:Show()
end

-- Update visibility based on combat state
function MC:UpdateVisibility(inCombat)
    if not KDT_MouseCursorFrame then return end
    
    local showOnlyInCombat = self:GetConfig("showOnlyInCombat")
    
    if showOnlyInCombat then
        if inCombat then
            KDT_MouseCursorFrame:Show()
        else
            KDT_MouseCursorFrame:Hide()
        end
    else
        if self:GetConfig("enabled") then
            KDT_MouseCursorFrame:Show()
        else
            KDT_MouseCursorFrame:Hide()
        end
    end
end

-- Update ring colors
function MC:UpdateRingColors()
    if not KDT_MouseCursorFrame then return end
    
    -- Main Ring
    if KDT_MouseCursorFrame.MainRing then
        local r, g, b = self:GetClassColor("main")
        KDT_MouseCursorFrame.MainRing:SetVertexColor(r, g, b)
    end
    
    -- GCD Ring
    if self.GCDCooldownFrame then
        local r, g, b = self:GetClassColor("gcd")
        self.GCDCooldownFrame:SetSwipeColor(r, g, b, 1.0)
    end
    
    -- Cast Ring
    if self.CastFrame then
        local r, g, b = self:GetClassColor("cast")
        self.CastFrame:SetSwipeColor(r, g, b, 1.0)
    end
    
    -- Reticle
    self:UpdateReticle()
end

-- GCD handler (WoW 12.0 compatible)
function MC:HandleGCD()
    if not self:GetConfig("enabled") then return end
    if not self.enableGCD then return end
    if not self.GCDCooldownFrame then return end
    
    local currentTime = GetTime()
    if currentTime - self.lastGCDTime < 0.1 then return end
    
    self.lastGCDTime = currentTime
    self.isGCDAnimating = true
    
    local gcdDuration = 1.5
    local startTime = currentTime
    local fillDrain = self:GetConfig("gcdFillDrain")
    
    if fillDrain == "drain" then
        self.GCDCooldownFrame:SetCooldown(startTime, gcdDuration)
        self.GCDCooldownFrame:SetReverse(false)
    else
        self.GCDCooldownFrame:SetCooldown(startTime, gcdDuration)
        self.GCDCooldownFrame:SetReverse(true)
    end
    
    self.GCDCooldownFrame:Show()
    
    C_Timer.After(gcdDuration, function()
        self.isGCDAnimating = false
        if self.GCDCooldownFrame then
            self.GCDCooldownFrame:Hide()
        end
    end)
end

-- Cast handler (WoW 12.0 compatible)
function MC:HandleCastStart(unit, castID, spellID)
    if not self:GetConfig("enabled") then return end
    if unit ~= "player" then return end
    if not self.enableCast then return end
    if not self.CastFrame then return end
    
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
    if not name then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
    end
    
    if not name then return end
    
    local currentTime = GetTime()
    local duration = (endTime - startTime) / 1000
    
    if duration <= 0 then return end
    
    self.isCasting = true
    local fillDrain = self:GetConfig("castFillDrain")
    
    if fillDrain == "drain" then
        self.CastFrame:SetCooldown(currentTime, duration)
        self.CastFrame:SetReverse(false)
    else
        self.CastFrame:SetCooldown(currentTime, duration)
        self.CastFrame:SetReverse(true)
    end
    
    self.CastFrame:Show()
end

-- Cast stop handler
function MC:HandleCastStop()
    if self.CastFrame then
        self.CastFrame:Hide()
    end
    self.isCasting = false
end

-- Health ring update
function MC:UpdateHealthRing()
    if not self:GetConfig("enabled") then return end
    if not self.HealthFrame or not self.HealthFrame:IsShown() then return end
    
    local healthPercent = UnitHealth("player") / UnitPowerMax("player")
    healthPercent = math.max(0, math.min(1, healthPercent))
    
    if math.abs(healthPercent - self.lastHealthPercent) < 0.01 then return end
    
    self.lastHealthPercent = healthPercent
    local duration = 60  -- Large duration to simulate static progress
    local elapsed = duration * (1 - healthPercent)
    
    self.HealthFrame:SetCooldown(GetTime() - elapsed, duration)
    
    -- Update color
    local colorMode = self:GetConfig("healthColorMode")
    if colorMode == "default" and not self:GetConfig("healthColorLock") then
        local r = 1 - healthPercent
        local g = healthPercent
        self.HealthFrame:SetSwipeColor(r, g, 0.0, 0.8)
    end
end

-- Power ring update
function MC:UpdatePowerRing()
    if not self:GetConfig("enabled") then return end
    if not self.PowerFrame or not self.PowerFrame:IsShown() then return end
    
    local powerType, powerToken = UnitPowerType("player")
    local powerPercent = UnitPower("player", powerType) / UnitPowerMax("player", powerType)
    powerPercent = math.max(0, math.min(1, powerPercent))
    
    if math.abs(powerPercent - self.lastPowerPercent) < 0.01 then return end
    
    self.lastPowerPercent = powerPercent
    local duration = 60
    local elapsed = duration * (1 - powerPercent)
    
    self.PowerFrame:SetCooldown(GetTime() - elapsed, duration)
    
    -- Update color based on power type
    local colorMode = self:GetConfig("powerColorMode")
    if colorMode == "default" then
        local info = PowerBarColor[powerType]
        if info then
            self.PowerFrame:SetSwipeColor(info.r, info.g, info.b, 0.8)
        end
    elseif colorMode == "class" then
        local r, g, b = self:GetClassColor("power")
        self.PowerFrame:SetSwipeColor(r, g, b, 0.8)
    elseif colorMode == "custom" then
        local r, g, b = self:GetClassColor("power")
        self.PowerFrame:SetSwipeColor(r, g, b, 0.8)
    end
end

-- Create High Contrast Ring
function MC:CreateHighContrastRing(size)
    if not KDT_MouseCursorFrame then return end
    
    if not self.HighContrastRings then
        self.HighContrastRings = {}
    end
    
    -- Hide old rings
    for _, ring in pairs(self.HighContrastRings) do
        if ring.outerHalf then ring.outerHalf:Hide() end
        if ring.innerHalf then ring.innerHalf:Hide() end
    end
    
    -- Create new ring
    local ringKey = tostring(size)
    if not self.HighContrastRings[ringKey] then
        local outerHalf = KDT_MouseCursorFrame:CreateTexture(nil, "ARTWORK")
        outerHalf:SetTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
        outerHalf:SetPoint("CENTER", KDT_MouseCursorFrame, "CENTER")
        
        local innerHalf = KDT_MouseCursorFrame:CreateTexture(nil, "OVERLAY")
        innerHalf:SetTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
        innerHalf:SetPoint("CENTER", KDT_MouseCursorFrame, "CENTER")
        
        self.HighContrastRings[ringKey] = {
            outerHalf = outerHalf,
            innerHalf = innerHalf
        }
    end
    
    local ring = self.HighContrastRings[ringKey]
    
    -- Configure outer ring
    local outerThickness = self:GetConfig("highContrastOuterThickness")
    local outerSize = size + outerThickness * 2
    ring.outerHalf:SetSize(outerSize, outerSize)
    
    local outerColorMode = self:GetConfig("highContrastOuterColorMode")
    local outerColor = self:GetConfig("highContrastOuterColor")
    if outerColorMode == "class" then
        local r, g, b = self:GetClassColor("main")
        ring.outerHalf:SetVertexColor(r, g, b)
    elseif outerColorMode == "custom" and outerColor then
        ring.outerHalf:SetVertexColor(outerColor.r, outerColor.g, outerColor.b)
    else
        ring.outerHalf:SetVertexColor(0.0, 0.0, 0.0)
    end
    
    -- Configure inner ring
    local innerThickness = self:GetConfig("highContrastInnerThickness")
    local innerSize = size + innerThickness * 2
    ring.innerHalf:SetSize(innerSize, innerSize)
    
    local innerColorMode = self:GetConfig("highContrastInnerColorMode")
    local innerColor = self:GetConfig("highContrastInnerColor")
    if innerColorMode == "class" then
        local r, g, b = self:GetClassColor("main")
        ring.innerHalf:SetVertexColor(r, g, b)
    elseif innerColorMode == "custom" and innerColor then
        ring.innerHalf:SetVertexColor(innerColor.r, innerColor.g, innerColor.b)
    else
        ring.innerHalf:SetVertexColor(1.0, 1.0, 1.0)
    end
    
    ring.outerHalf:Show()
    ring.innerHalf:Show()
end

-- Apply all settings
function MC:ApplySettings()
    if not self:GetConfig("enabled") then
        if KDT_MouseCursorFrame then
            KDT_MouseCursorFrame:Hide()
        end
        return
    end
    
    if not KDT_MouseCursorFrame then
        self:SetupUI()
    end
    
    -- Set scale and transparency
    self:SetGroupScale(self:GetConfig("scale"))
    if KDT_MouseCursorFrame then
        KDT_MouseCursorFrame:SetAlpha(self:GetConfig("transparency"))
    end
    
    -- Hide all rings first
    if self.GCDCooldownFrame then self.GCDCooldownFrame:Hide() end
    if self.GCDBackgroundFrame then self.GCDBackgroundFrame:Hide() end
    if self.CastFrame then self.CastFrame:Hide() end
    if self.CastBackgroundFrame then self.CastBackgroundFrame:Hide() end
    if self.HealthFrame then self.HealthFrame:Hide() end
    if self.HealthBackgroundFrame then self.HealthBackgroundFrame:Hide() end
    if self.PowerFrame then self.PowerFrame:Hide() end
    if KDT_MouseCursorFrame and KDT_MouseCursorFrame.MainRing then 
        KDT_MouseCursorFrame.MainRing:Hide() 
    end
    
    -- Hide High Contrast Rings
    if self.HighContrastRings then
        for _, ring in pairs(self.HighContrastRings) do
            if ring.outerHalf then ring.outerHalf:Hide() end
            if ring.innerHalf then ring.innerHalf:Hide() end
        end
    end
    
    self.enableGCD = false
    self.enableCast = false
    local trackHealth = false
    local trackPower = false
    
    -- Configure rings based on slot assignments
    local slots = {
        {config = self:GetConfig("innerRing"), size = 50},
        {config = self:GetConfig("mainRing"), size = 70},
        {config = self:GetConfig("outerRing"), size = 90},
    }
    
    for _, slot in ipairs(slots) do
        local ringType = slot.config
        local size = slot.size
        
        if ringType == "Main Ring" then
            if KDT_MouseCursorFrame and KDT_MouseCursorFrame.MainRing then
                KDT_MouseCursorFrame.MainRing:SetSize(size, size)
                KDT_MouseCursorFrame.MainRing:Show()
            end
        elseif ringType == "GCD" then
            if self.GCDCooldownFrame then
                self.GCDCooldownFrame:SetSize(size, size)
                self.GCDCooldownFrame:Show()
                self.enableGCD = true
            end
            if size == 70 and self.GCDBackgroundFrame then
                self.GCDBackgroundFrame:SetSize(size, size)
                self.GCDBackgroundFrame:Show()
            end
        elseif ringType == "Cast" then
            if self.CastFrame then
                self.CastFrame:SetSize(size, size)
                self.CastFrame:Show()
                self.enableCast = true
            end
            if size == 70 and self.CastBackgroundFrame then
                self.CastBackgroundFrame:SetSize(size, size)
                self.CastBackgroundFrame:Show()
            end
        elseif ringType == "Health" then
            if self.HealthFrame then
                self.HealthFrame:SetSize(size, size)
                self.HealthFrame:Show()
                trackHealth = true
            end
            if self.HealthBackgroundFrame then
                self.HealthBackgroundFrame:SetSize(size, size)
                self.HealthBackgroundFrame:Show()
            end
        elseif ringType == "Power" then
            if self.PowerFrame then
                self.PowerFrame:SetSize(size, size)
                self.PowerFrame:Show()
                trackPower = true
            end
        elseif ringType == "Health and Power" then
            if self.HealthFrame then
                self.HealthFrame:SetSize(size, size)
                self.HealthFrame:Show()
                trackHealth = true
            end
            if self.HealthBackgroundFrame then
                self.HealthBackgroundFrame:SetSize(size, size)
                self.HealthBackgroundFrame:Show()
            end
            if self.PowerFrame then
                self.PowerFrame:SetSize(size + 10, size + 10)
                self.PowerFrame:Show()
                trackPower = true
            end
        elseif ringType == "Main Ring + GCD" then
            if KDT_MouseCursorFrame and KDT_MouseCursorFrame.MainRing then
                KDT_MouseCursorFrame.MainRing:SetSize(size, size)
                KDT_MouseCursorFrame.MainRing:Show()
            end
            if self.GCDCooldownFrame then
                self.GCDCooldownFrame:SetSize(size, size)
                self.GCDCooldownFrame:Show()
                self.enableGCD = true
            end
            if self.GCDBackgroundFrame then
                self.GCDBackgroundFrame:SetSize(size, size)
                self.GCDBackgroundFrame:Show()
            end
        elseif ringType == "Main Ring + Cast" then
            if KDT_MouseCursorFrame and KDT_MouseCursorFrame.MainRing then
                KDT_MouseCursorFrame.MainRing:SetSize(size, size)
                KDT_MouseCursorFrame.MainRing:Show()
            end
            if self.CastFrame then
                self.CastFrame:SetSize(size, size)
                self.CastFrame:Show()
                self.enableCast = true
            end
            if self.CastBackgroundFrame then
                self.CastBackgroundFrame:SetSize(size, size)
                self.CastBackgroundFrame:Show()
            end
        elseif ringType == "High Contrast Ring" then
            self:CreateHighContrastRing(size)
        end
    end
    
    self:UpdateRingColors()
    self:UpdateVisibility()
    self:UpdateReticle()
    
    if trackHealth then
        self:UpdateHealthRing()
    end
    if trackPower then
        self:UpdatePowerRing()
    end
end

-- Setup UI (create frames)
function MC:SetupUI()
    if KDT_MouseCursorFrame then return end
    
    -- Create main cursor frame
    local f = CreateFrame("Frame", "KDT_MouseCursorFrame", UIParent)
    f:SetSize(120, 120)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:EnableMouse(false)
    f:Hide()
    
    -- Initialize at screen center (position will be updated by OnUpdate)
    f:SetPoint("CENTER", UIParent, "CENTER")
    
    -- Position at mouse cursor (fixed for frame scale)
    f:SetScript("OnUpdate", function(self, elapsed)
        local x, y = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        local frameScale = self:GetScale()
        
        -- Divide by BOTH scales (UI and Frame)
        local correctedX = (x / uiScale) / frameScale
        local correctedY = (y / uiScale) / frameScale
        
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", correctedX, correctedY)
    end)
    
    -- Main Ring
    f.MainRing = f:CreateTexture(nil, "ARTWORK")
    f.MainRing:SetSize(70, 70)
    f.MainRing:SetPoint("CENTER")
    f.MainRing:SetTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    
    -- GCD Background
    local gcdBg = CreateFrame("Cooldown", nil, f)
    gcdBg:SetSize(70, 70)
    gcdBg:SetPoint("CENTER")
    gcdBg:SetFrameLevel(2)
    gcdBg:SetSwipeTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    gcdBg:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    gcdBg:SetReverse(false)
    gcdBg:SetHideCountdownNumbers(true)
    gcdBg:SetCooldown(GetTime() - 1, 0.01)
    gcdBg:Hide()
    MC.GCDBackgroundFrame = gcdBg
    
    -- GCD Cooldown
    local gcd = CreateFrame("Cooldown", nil, f)
    gcd:SetSize(50, 50)
    gcd:SetPoint("CENTER")
    gcd:SetFrameLevel(3)
    gcd:SetSwipeTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    gcd:SetSwipeColor(1, 1, 1, 1)
    gcd:SetHideCountdownNumbers(true)
    gcd:Hide()
    MC.GCDCooldownFrame = gcd
    
    -- Cast Background
    local castBg = CreateFrame("Cooldown", nil, f)
    castBg:SetSize(70, 70)
    castBg:SetPoint("CENTER")
    castBg:SetFrameLevel(2)
    castBg:SetSwipeTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    castBg:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    castBg:SetReverse(false)
    castBg:SetHideCountdownNumbers(true)
    castBg:SetCooldown(GetTime() - 1, 0.01)
    castBg:Hide()
    MC.CastBackgroundFrame = castBg
    
    -- Cast Cooldown
    local cast = CreateFrame("Cooldown", nil, f)
    cast:SetSize(90, 90)
    cast:SetPoint("CENTER")
    cast:SetFrameLevel(3)
    cast:SetSwipeTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    cast:SetSwipeColor(1, 1, 1, 1)
    cast:SetHideCountdownNumbers(true)
    cast:Hide()
    MC.CastFrame = cast
    
    -- Health Background
    local healthBg = f:CreateTexture(nil, "ARTWORK")
    healthBg:SetSize(70, 70)
    healthBg:SetPoint("CENTER")
    healthBg:SetTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    healthBg:SetVertexColor(0.5, 0.5, 0.5, 0.7)
    healthBg:Hide()
    MC.HealthBackgroundFrame = healthBg
    
    -- Health Cooldown
    local health = CreateFrame("Cooldown", nil, f)
    health:SetSize(70, 70)
    health:SetPoint("CENTER")
    health:SetFrameLevel(3)
    health:SetSwipeTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    health:SetSwipeColor(1, 0, 0, 0.8)
    health:SetReverse(false)
    health:SetHideCountdownNumbers(true)
    health:Hide()
    MC.HealthFrame = health
    
    -- Power Cooldown
    local power = CreateFrame("Cooldown", nil, f)
    power:SetSize(80, 80)
    power:SetPoint("CENTER")
    power:SetFrameLevel(1)
    power:SetSwipeTexture("Interface\\Addons\\KryosDungeonTool\\Textures\\Ring_Main")
    power:SetSwipeColor(0, 0.5, 1, 0.8)
    power:SetReverse(false)
    power:SetHideCountdownNumbers(true)
    power:Hide()
    MC.PowerFrame = power
    
    KDT_MouseCursorFrame = f
end

-- Initialize module
function MC:Initialize()
    self:InitConfig()
    
    if self:GetConfig("enabled") then
        self:SetupUI()
        self:ApplySettings()
        
        -- Register events for combat visibility
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        eventFrame:RegisterEvent("UNIT_HEALTH")
        eventFrame:RegisterEvent("UNIT_MAXHEALTH")
        eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
        eventFrame:RegisterEvent("UNIT_MAXPOWER")
        
        eventFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_REGEN_DISABLED" then
                MC:UpdateVisibility(true)
            elseif event == "PLAYER_REGEN_ENABLED" then
                MC:UpdateVisibility(false)
            elseif event == "UNIT_SPELLCAST_SENT" then
                MC:HandleGCD()
            elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
                local unit, castID, spellID = ...
                MC:HandleCastStart(unit, castID, spellID)
            elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
                MC:HandleCastStop()
            elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                local unit = ...
                if unit == "player" then
                    MC:UpdateHealthRing()
                end
            elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
                local unit = ...
                if unit == "player" then
                    MC:UpdatePowerRing()
                end
            end
        end)
        
        MC.eventFrame = eventFrame
    end
end
