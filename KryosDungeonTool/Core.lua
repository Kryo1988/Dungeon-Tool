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

-- ==================== EDIT REASON DIALOG ====================
function KDT:ShowEditReasonDialog(playerName, mainFrame)
    -- Create dialog if it doesn't exist
    if not self.editDialog then
        local dialog = CreateFrame("Frame", "KryosEditDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(350, 120)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2
        })
        dialog:SetBackdropColor(0.1, 0.1, 0.12, 0.95)
        dialog:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        dialog:Hide()
        
        -- Title
        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        dialog.title:SetPoint("TOP", 0, -12)
        
        -- Input
        dialog.input = CreateFrame("EditBox", nil, dialog, "BackdropTemplate")
        dialog.input:SetSize(310, 24)
        dialog.input:SetPoint("TOP", 0, -40)
        dialog.input:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        dialog.input:SetBackdropColor(0.05, 0.05, 0.07, 1)
        dialog.input:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
        dialog.input:SetFontObject("GameFontNormal")
        dialog.input:SetTextInsets(8, 8, 0, 0)
        dialog.input:SetAutoFocus(true)
        dialog.input:SetMaxLetters(200)
        
        -- Save Button
        dialog.saveBtn = self:CreateButton(dialog, "Save", 80, 24)
        dialog.saveBtn:SetPoint("BOTTOMLEFT", 60, 15)
        dialog.saveBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
        dialog.saveBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.55, 0.2, 1) end)
        dialog.saveBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.45, 0.15, 1) end)
        
        -- Cancel Button
        dialog.cancelBtn = self:CreateButton(dialog, "Cancel", 80, 24)
        dialog.cancelBtn:SetPoint("BOTTOMRIGHT", -60, 15)
        dialog.cancelBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
        dialog.cancelBtn:SetScript("OnClick", function() dialog:Hide() end)
        dialog.cancelBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.2, 0.2, 1) end)
        dialog.cancelBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 1) end)
        
        -- ESC to close
        dialog:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)
        dialog:EnableKeyboard(true)
        
        self.editDialog = dialog
    end
    
    local dialog = self.editDialog
    
    -- Set up for this player
    dialog.title:SetText("Edit reason for |cFFFFFF00" .. playerName .. "|r")
    dialog.input:SetText(self.DB.blacklist[playerName] and self.DB.blacklist[playerName].reason or "")
    dialog.input:HighlightText()
    dialog.playerName = playerName
    dialog.mainFrame = mainFrame
    
    -- Save action
    dialog.saveBtn:SetScript("OnClick", function()
        local newReason = dialog.input:GetText()
        local pName = dialog.playerName
        if newReason and pName and KDT.DB.blacklist[pName] then
            KDT.DB.blacklist[pName].reason = newReason
            KDT:PrintSuccess("Updated reason for " .. pName)
            dialog:Hide()
            if dialog.mainFrame then
                dialog.mainFrame:RefreshBlacklist()
            end
        end
    end)
    
    -- Enter to save
    dialog.input:SetScript("OnEnterPressed", function()
        dialog.saveBtn:Click()
    end)
    
    dialog.input:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
    
    dialog:Show()
    dialog.input:SetFocus()
end
