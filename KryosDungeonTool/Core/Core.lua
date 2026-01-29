-- Kryos Dungeon Tool
-- Core/Core.lua - Main addon logic

local addonName, KDT = ...

-- Default database structure
local defaults = {
    minimapPos = 220,
    frameWidth = 700,
    frameHeight = 550,
    blacklist = {},
    runHistory = {},
    settings = {
        autoPost = false,
        countdownSeconds = 10,
        customSound = true,
    },
    timer = {
        enabled = true,
        locked = false,
        showWhenInactive = false,
        scale = 1.2,
        spacing = 3,
        frameStrata = "HIGH",
        hideObjectiveTracker = false,
        position = { anchor = "RIGHT", relativeTo = "RIGHT", xOffset = 0, yOffset = 250 },
        background = { enabled = true, color = {0, 0, 0, 0.5}, borderColor = {0, 0, 0, 1}, borderSize = 1 },
        keyInfo = { width = 330, height = 14 },
        keyLevel = { enabled = true, fontSize = 16, color = {1, 1, 1, 1} },
        dungeonName = { enabled = true, fontSize = 16, shorten = 14, color = {1, 1, 1, 1} },
        deathCounter = { enabled = true, iconEnabled = true, showTimer = false, fontSize = 16, color = {1, 1, 1, 1} },
        timerBar = {
            width = 330, height = 24, borderSize = 1,
            backgroundColor = {0, 0, 0, 0.5}, borderColor = {0, 0, 0, 1},
            texture = "Interface\\Buttons\\WHITE8X8",
            colors = {
                [0] = {89/255, 90/255, 92/255, 1},
                [1] = {1, 112/255, 0, 1},
                [2] = {1, 1, 0, 1},
                [3] = {128/255, 1, 0, 1},
            },
        },
        timerText = { enabled = true, fontSize = 16, color = {1, 1, 1, 1}, successColor = {0, 1, 0, 1}, failColor = {1, 0, 0, 1} },
        chestTimer = { enabled = true, fontSize = 16, aheadColor = {0, 1, 0, 1}, behindColor = {1, 0, 0, 1} },
        ticks = { enabled = true, width = 2, color = {1, 1, 1, 1} },
        bosses = { width = 330, height = 16 },
        bossName = { enabled = true, fontSize = 16, maxLength = 22, color = {1, 1, 1, 1}, completionColor = {0, 1, 0, 1} },
        bossTimer = { enabled = true, fontSize = 16, color = {1, 1, 1, 1} },
        bossSplit = { enabled = true, fontSize = 16, successColor = {0, 1, 0, 1}, failColor = {1, 0, 0, 1}, equalColor = {1, 0.8, 0, 1} },
        forcesBar = {
            width = 330, height = 24, borderSize = 1,
            backgroundColor = {0, 0, 0, 0.5}, borderColor = {0, 0, 0, 1},
            texture = "Interface\\Buttons\\WHITE8X8",
            colors = {
                [1] = {1, 117/255, 128/255, 1},
                [2] = {1, 130/255, 72/255, 1},
                [3] = {1, 197/255, 103/255, 1},
                [4] = {1, 249/255, 150/255, 1},
                [5] = {104/255, 205/255, 1, 1},
            },
            completionColor = {205/255, 1, 167/255, 1},
        },
        percentCount = { enabled = true, fontSize = 16, color = {1, 1, 1, 1}, remaining = false },
        realCount = { enabled = true, fontSize = 16, color = {1, 1, 1, 1}, remaining = true, total = false },
    },
}

-- Deep copy function
local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

-- Merge tables (apply defaults to saved vars)
local function MergeDefaults(sv, def)
    if type(sv) ~= "table" then return DeepCopy(def) end
    for k, v in pairs(def) do
        if sv[k] == nil then
            sv[k] = DeepCopy(v)
        elseif type(v) == "table" and type(sv[k]) == "table" then
            MergeDefaults(sv[k], v)
        end
    end
    return sv
end

-- Initialize database
function KDT:InitDB()
    if not KryosDungeonToolDB then
        KryosDungeonToolDB = DeepCopy(defaults)
    else
        KryosDungeonToolDB = MergeDefaults(KryosDungeonToolDB, defaults)
    end
    self.DB = KryosDungeonToolDB
    
    -- Migration: Update default scale from 1 to 1.2 for existing users
    if self.DB.timer and self.DB.timer.scale == 1 and not self.DB.migratedScale then
        self.DB.timer.scale = 1.2
        self.DB.migratedScale = true
    end
end

-- Class colors
KDT.CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1.00, 0.96, 0.41},
    PRIEST = {1.00, 1.00, 1.00},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    SHAMAN = {0.00, 0.44, 0.87},
    MAGE = {0.41, 0.80, 0.94},
    WARLOCK = {0.58, 0.51, 0.79},
    MONK = {0.00, 1.00, 0.59},
    DRUID = {1.00, 0.49, 0.04},
    DEMONHUNTER = {0.64, 0.19, 0.79},
    EVOKER = {0.20, 0.58, 0.50},
}

-- Role icons
KDT.ROLE_ICONS = {
    TANK = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",
    HEALER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
    DAMAGER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t",
}

-- Battle rez classes
KDT.BATTLE_REZ = {
    DRUID = true,
    DEATHKNIGHT = true,
    WARLOCK = true,
    PALADIN = true,
}

-- Bloodlust classes
KDT.BLOODLUST = {
    SHAMAN = true,
    MAGE = true,
    HUNTER = true,
    EVOKER = true,
}

-- Class names
KDT.CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue",
    PRIEST = "Priest", DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage",
    WARLOCK = "Warlock", MONK = "Monk", DRUID = "Druid", DEMONHUNTER = "Demon Hunter",
    EVOKER = "Evoker",
}

-- Utf8 substring (for non-ASCII characters)
function KDT:Utf8Sub(str, startChar, endChar)
    if not str then return str end
    local startIndex, endIndex = 1, #str
    local currentIndex, currentChar = 1, 0
    while currentIndex <= #str do
        currentChar = currentChar + 1
        if currentChar == startChar then startIndex = currentIndex end
        if endChar and currentChar > endChar then endIndex = currentIndex - 1; break end
        local c = string.byte(str, currentIndex)
        if c < 0x80 then currentIndex = currentIndex + 1
        elseif c < 0xE0 then currentIndex = currentIndex + 2
        elseif c < 0xF0 then currentIndex = currentIndex + 3
        else currentIndex = currentIndex + 4 end
    end
    return string.sub(str, startIndex, endIndex)
end

-- Format time (MM:SS or H:MM:SS)
function KDT:FormatTime(time, round)
    if not time then return "0:00" end
    local negative = time < 0
    time = math.abs(time)
    local timeMin = math.floor(time / 60)
    local timeSec = round and math.floor(time - (timeMin * 60) + 0.5) or math.floor(time - (timeMin * 60))
    local timeHour = 0
    if timeMin >= 60 then
        timeHour = math.floor(time / 3600)
        timeMin = timeMin - (timeHour * 60)
    end
    local result
    if timeHour > 0 then result = string.format("%d:%02d:%02d", timeHour, timeMin, timeSec)
    else result = string.format("%d:%02d", timeMin, timeSec) end
    return (negative and "-" or "") .. result
end

-- ==================== UI HELPERS ====================

-- Get class color as hex string
function KDT:GetClassColorHex(class)
    local c = self.CLASS_COLORS[class]
    if c then
        return string.format("%02X%02X%02X", c[1] * 255, c[2] * 255, c[3] * 255)
    end
    return "FFFFFF"
end

-- Create a styled button
function KDT:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    end)
    
    return btn
end

-- Create a styled input box
function KDT:CreateInput(parent, width)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width, 20)
    input:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    input:SetBackdropColor(0.05, 0.05, 0.07, 1)
    input:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    input:SetFontObject("GameFontHighlightSmall")
    input:SetTextInsets(5, 5, 0, 0)
    input:SetAutoFocus(false)
    
    return input
end

-- Print message to chat
function KDT:Print(msg)
    print("|cFFFF0000Kryos|r Dungeon Tool: " .. msg)
end

-- Version
KDT.version = "1.6"

-- Already alerted (for blacklist)
KDT.alreadyAlerted = {}
