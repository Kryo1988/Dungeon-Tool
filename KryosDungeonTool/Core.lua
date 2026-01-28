-- Kryos Dungeon Tool v1.4
-- Core.lua - Main namespace and utilities

local addonName, KDT = ...

-- Addon namespace
KDT.version = "1.4"
KDT.DB = nil
KDT.MainFrame = nil

-- ==================== DATA ====================
KDT.CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1, 0.96, 0.41},
    PRIEST = {1, 1, 1},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    SHAMAN = {0, 0.44, 0.87},
    MAGE = {0.25, 0.78, 0.92},
    WARLOCK = {0.53, 0.53, 0.93},
    MONK = {0, 1, 0.6},
    DRUID = {1, 0.49, 0.04},
    DEMONHUNTER = {0.64, 0.19, 0.79},
    EVOKER = {0.2, 0.58, 0.5}
}

KDT.CLASS_NAMES = {
    WARRIOR = "Warrior",
    PALADIN = "Paladin",
    HUNTER = "Hunter",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    DEATHKNIGHT = "Death Knight",
    SHAMAN = "Shaman",
    MAGE = "Mage",
    WARLOCK = "Warlock",
    MONK = "Monk",
    DRUID = "Druid",
    DEMONHUNTER = "Demon Hunter",
    EVOKER = "Evoker"
}

KDT.BATTLE_REZ = {
    DRUID = true,
    DEATHKNIGHT = true,
    WARLOCK = true,
    PALADIN = true
}

KDT.BLOODLUST = {
    SHAMAN = true,
    MAGE = true,
    HUNTER = true,
    EVOKER = true
}

KDT.ROLE_ICONS = {
    TANK = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",
    HEALER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
    DAMAGER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"
}

-- ==================== UTILITIES ====================
function KDT:GetClassColorHex(class)
    local c = self.CLASS_COLORS[class] or {1, 1, 1}
    return string.format("%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

function KDT:Print(msg)
    print("|cFFFF0000[Kryos]|r " .. msg)
end

function KDT:PrintSuccess(msg)
    print("|cFF00FF00[Kryos]|r " .. msg)
end

-- ==================== DATABASE ====================
function KDT:InitDB()
    if not KryosDungeonToolDB then
        KryosDungeonToolDB = {
            blacklist = {},
            settings = {
                countdownSeconds = 10,
                autoPost = false,
                customSound = true
            },
            minimapPos = 220
        }
    end
    self.DB = KryosDungeonToolDB
    self.DB.settings = self.DB.settings or {countdownSeconds = 10, autoPost = false, customSound = true}
    self.DB.blacklist = self.DB.blacklist or {}
end

-- ==================== UI HELPERS ====================
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
        self:SetBackdropColor(0.25, 0.25, 0.30, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
    end)
    
    return btn
end

function KDT:CreateInput(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 22)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    box:SetBackdropColor(0.1, 0.1, 0.12, 1)
    box:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
    box:SetFontObject("GameFontNormalSmall")
    box:SetTextInsets(5, 5, 0, 0)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    return box
end
