-- Kryos Dungeon Tool
-- Modules/InstanceDifficulty.lua - Instance difficulty text on minimap

local _, KDT = ...

local InstDiff = { enabled = false }
KDT.InstanceDifficulty = InstDiff

local idFrame = CreateFrame("Frame")
local indicator = MinimapCluster and MinimapCluster.InstanceDifficulty

-- Hide default sub-widgets
if indicator then
    if indicator.Default then
        indicator.Default:Hide()
        indicator.Default:SetScript("OnShow", indicator.Default.Hide)
    end
    if indicator.ChallengeMode then
        indicator.ChallengeMode:Hide()
        indicator.ChallengeMode:SetScript("OnShow", indicator.ChallengeMode.Hide)
    end
    if indicator.Guild then
        indicator.Guild:Hide()
        indicator.Guild:SetScript("OnShow", indicator.Guild.Hide)
    end
    indicator:HookScript("OnShow", function() InstDiff:Update() end)
end

-- Create text overlay
local FONT = "Fonts\\FRIZQT__.TTF"
if indicator then
    InstDiff.text = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    InstDiff.text:SetFont(FONT, 14, "OUTLINE")
    InstDiff.text:SetPoint("CENTER", indicator, "CENTER", 0, 0)
    InstDiff.text:Hide()
end

-- Difficulty ID -> short label
local NM_IDS = { [1]=true, [3]=true, [4]=true, [14]=true, [33]=true, [150]=true, [12]=true }
local HC_IDS = { [2]=true, [5]=true, [6]=true, [15]=true, [205]=true, [230]=true, [13]=true }
local M_IDS = { [16]=true, [23]=true }
local LFR_IDS = { [7]=true, [17]=true, [151]=true }

local function getShortLabel(diffID)
    if NM_IDS[diffID] then return "NM", "NM"
    elseif HC_IDS[diffID] then return "HC", "HC"
    elseif M_IDS[diffID] then return "M", "M"
    elseif diffID == 8 then
        local level = C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo()
        if level and type(level) == "number" and level > 0 then
            return "M+" .. level, "MPLUS"
        end
        return "M+", "MPLUS"
    elseif LFR_IDS[diffID] then return "LFR", "LFR"
    elseif diffID == 24 then return "TW", "TW"
    end
    return nil, nil
end

-- Default colors per code
local DEFAULT_COLORS = {
    NM    = { r = 0.20, g = 0.95, b = 0.20 },
    HC    = { r = 0.25, g = 0.55, b = 1.00 },
    M     = { r = 0.80, g = 0.40, b = 1.00 },
    MPLUS = { r = 0.80, g = 0.40, b = 1.00 },
    LFR   = { r = 1.00, g = 1.00, b = 1.00 },
    TW    = { r = 1.00, g = 1.00, b = 1.00 },
}

function InstDiff:Update()
    if not self.enabled or not self.text then return end
    if not IsInInstance() then
        self.text:Hide()
        return
    end
    
    local _, _, diffID, diffName, _, _, _, _, maxPlayers = GetInstanceInfo()
    local short, code = getShortLabel(diffID)
    if not short then
        short = diffName or "?"
        code = "NM"
    end
    
    local text
    if maxPlayers and maxPlayers > 0 then
        text = string.format("%d (%s)", maxPlayers, short)
    else
        text = short
    end
    
    local qol = KDT.DB and KDT.DB.qol
    local fontSize = (qol and qol.instanceDiffFontSize) or 14
    self.text:SetFont(FONT, fontSize, "OUTLINE")
    
    -- Apply color
    if qol and qol.instanceDiffUseColors then
        local c = DEFAULT_COLORS[code] or { r = 1, g = 1, b = 1 }
        self.text:SetTextColor(c.r, c.g, c.b)
    else
        self.text:SetTextColor(1, 1, 1)
    end
    
    self.text:SetText(text)
    self.text:Show()
end

function InstDiff:SetEnabled(value)
    self.enabled = value
    if value then
        idFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        idFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        idFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
        idFrame:RegisterEvent("CHALLENGE_MODE_START")
        if indicator and indicator.Default then
            indicator.Default:Hide()
            indicator.Default:SetScript("OnShow", indicator.Default.Hide)
        end
        self:Update()
    else
        idFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        idFrame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
        idFrame:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED")
        idFrame:UnregisterEvent("CHALLENGE_MODE_START")
        if self.text then self.text:Hide() end
        if indicator and indicator.Default then
            indicator.Default:SetScript("OnShow", nil)
            if IsInInstance() then indicator.Default:Show() end
        end
    end
end

idFrame:SetScript("OnEvent", function() InstDiff:Update() end)

function KDT:InitInstanceDifficulty()
    local qol = self.DB and self.DB.qol
    if qol and qol.showInstanceDifficulty then
        InstDiff:SetEnabled(true)
    end
end
