-- Kryos Dungeon Tool
-- Modules/Talents.lua - Talent Build Management (Requires PeaversTalentsData)

local addonName, KDT = ...

KDT.Talents = {}
local Talents = KDT.Talents

-- Check if PeaversTalentsData is available
function Talents:IsAvailable()
    return _G["PeaversTalentsData"] and _G["PeaversTalentsData"].API ~= nil
end

-- Get API reference
function Talents:GetAPI()
    if not self:IsAvailable() then
        return nil
    end
    return _G["PeaversTalentsData"].API
end

-- Spec data structure: [classID] = { [specID] = {name, role} }
Talents.SPEC_DATA = {
    [1] = { -- Warrior
        [71] = {name = "Arms", role = "DAMAGER"},
        [72] = {name = "Fury", role = "DAMAGER"},
        [73] = {name = "Protection", role = "TANK"},
    },
    [2] = { -- Paladin
        [65] = {name = "Holy", role = "HEALER"},
        [66] = {name = "Protection", role = "TANK"},
        [70] = {name = "Retribution", role = "DAMAGER"},
    },
    [3] = { -- Hunter
        [253] = {name = "Beast Mastery", role = "DAMAGER"},
        [254] = {name = "Marksmanship", role = "DAMAGER"},
        [255] = {name = "Survival", role = "DAMAGER"},
    },
    [4] = { -- Rogue
        [259] = {name = "Assassination", role = "DAMAGER"},
        [260] = {name = "Outlaw", role = "DAMAGER"},
        [261] = {name = "Subtlety", role = "DAMAGER"},
    },
    [5] = { -- Priest
        [256] = {name = "Discipline", role = "HEALER"},
        [257] = {name = "Holy", role = "HEALER"},
        [258] = {name = "Shadow", role = "DAMAGER"},
    },
    [6] = { -- Death Knight
        [250] = {name = "Blood", role = "TANK"},
        [251] = {name = "Frost", role = "DAMAGER"},
        [252] = {name = "Unholy", role = "DAMAGER"},
    },
    [7] = { -- Shaman
        [262] = {name = "Elemental", role = "DAMAGER"},
        [263] = {name = "Enhancement", role = "DAMAGER"},
        [264] = {name = "Restoration", role = "HEALER"},
    },
    [8] = { -- Mage
        [62] = {name = "Arcane", role = "DAMAGER"},
        [63] = {name = "Fire", role = "DAMAGER"},
        [64] = {name = "Frost", role = "DAMAGER"},
    },
    [9] = { -- Warlock
        [265] = {name = "Affliction", role = "DAMAGER"},
        [266] = {name = "Demonology", role = "DAMAGER"},
        [267] = {name = "Destruction", role = "DAMAGER"},
    },
    [10] = { -- Monk
        [268] = {name = "Brewmaster", role = "TANK"},
        [270] = {name = "Mistweaver", role = "HEALER"},
        [269] = {name = "Windwalker", role = "DAMAGER"},
    },
    [11] = { -- Druid
        [102] = {name = "Balance", role = "DAMAGER"},
        [103] = {name = "Feral", role = "DAMAGER"},
        [104] = {name = "Guardian", role = "TANK"},
        [105] = {name = "Restoration", role = "HEALER"},
    },
    [12] = { -- Demon Hunter
        [577] = {name = "Havoc", role = "DAMAGER"},
        [581] = {name = "Vengeance", role = "TANK"},
        [1480] = {name = "Devourer", role = "DAMAGER"}, -- New in WoW 12.0 (Midnight)
    },
    [13] = { -- Evoker
        [1467] = {name = "Devastation", role = "DAMAGER"},
        [1468] = {name = "Preservation", role = "HEALER"},
        [1473] = {name = "Augmentation", role = "DAMAGER"},
    },
}

-- Dungeon names mapping (dungeonID to name)
-- IDs 0-8 are defined by PeaversTalentsData structure
-- These IDs remain consistent across seasons in the data source
Talents.DUNGEON_NAMES = {
    [0] = "All Dungeons",
    [1] = "Ara Kara",
    [2] = "Eco Dome",
    [3] = "Halls",
    [4] = "Floodgate",
    [5] = "Priory",
    [6] = "Gambit",
    [7] = "Streets",
    [8] = "Dawnbreaker",
}

-- Content type names
Talents.CONTENT_TYPES = {
    mythic = "Mythic+",
    heroic_raid = "Heroic Raid",
    mythic_raid = "Mythic Raid",
    raid = "Raid",
    misc = "Misc",
}

-- Source display names
Talents.SOURCE_NAMES = {
    archon = "Archon",
    ["icy-veins"] = "Icy Veins",
    wowhead = "Wowhead",
    ugg = "U.gg",
}

-- Get player's current class and spec
function Talents:GetPlayerInfo()
    if not UnitExists("player") then
        return nil, nil
    end
    
    local classID = select(3, UnitClass("player"))
    if not classID then
        return nil, nil
    end
    
    local specIndex = GetSpecialization()
    if not specIndex then
        return nil, nil
    end
    
    local specID = GetSpecializationInfo(specIndex)
    if not specID then
        return nil, nil
    end
    
    return classID, specID
end

-- Get all specs for a class
function Talents:GetClassSpecs(classID)
    return self.SPEC_DATA[classID] or {}
end

-- Get spec info
function Talents:GetSpecInfo(classID, specID)
    local specs = self:GetClassSpecs(classID)
    return specs[specID]
end

-- Get all available sources
function Talents:GetSources()
    local API = self:GetAPI()
    if not API then
        return {}
    end
    
    return API.GetSources() or {}
end

-- Get talent builds
function Talents:GetBuilds(classID, specID, source, dungeonID)
    local API = self:GetAPI()
    if not API then
        return nil, "PeaversTalentsData not available"
    end
    
    local builds, err = API.GetBuilds(classID, specID, source, dungeonID)
    
    if not builds then
        return nil, err
    end
    
    return builds
end

-- Get update timestamps
function Talents:GetLastUpdate(source)
    local API = self:GetAPI()
    if not API then
        return nil
    end
    
    return API.GetLastUpdate(source)
end

-- Load talent build - Shows dialog with import string
function Talents:LoadBuild(talentString)
    if not talentString or talentString == "" then
        return false, "Invalid talent string (empty)"
    end
    
    -- Check if we're in a protected context
    if InCombatLockdown() then
        return false, "Cannot load talents in combat"
    end
    
    print("|cFFFF0000Kryos|r Dungeon Tool: Opening import dialog...")
    print("|cFFFF0000Kryos|r Dungeon Tool: Talent String: " .. talentString:sub(1, 20) .. "...")
    
    -- Show dialog with import instructions
    local dialog = StaticPopup_Show("KDT_LOAD_TALENT", talentString)
    if dialog then
        dialog.editBox:SetText(talentString)
        dialog.editBox:HighlightText()
        dialog.editBox:SetFocus()
        return true, "Dialog opened - Copy string and paste into talent import"
    end
    
    return false, "Could not open dialog. Please use Copy button instead."
end

-- Register static popup for load dialog
if not StaticPopupDialogs["KDT_LOAD_TALENT"] then
    StaticPopupDialogs["KDT_LOAD_TALENT"] = {
        text = "Talent Import String:\n\n1. Press Ctrl+A then Ctrl+C to copy\n2. Open Talent window (N)\n3. Click 'Import Loadout'\n4. Press Ctrl+V to paste\n5. Click Import",
        button1 = "Done",
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self)
            self.editBox:SetText(self.text.text_arg1)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- Copy talent string to clipboard using chat edit box
function Talents:CopyToClipboard(text)
    if not text or text == "" then 
        print("|cFFFF0000Kryos|r Dungeon Tool: |cFFFF4444No talent string to copy!|r")
        return false
    end
    
    -- Method 1: Try to use the main chat edit box
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        editBox = DEFAULT_CHAT_FRAME.editBox
    end
    
    if editBox then
        -- Show the edit box if hidden
        if not editBox:IsShown() then
            ChatEdit_ActivateChat(editBox)
        end
        
        -- Set the text
        editBox:SetText(text)
        editBox:HighlightText()
        editBox:SetFocus()
        
        -- Instructions for user
        print("|cFFFF0000Kryos|r Dungeon Tool: |cFF00FF00Talent string is in chat box - Press Ctrl+A then Ctrl+C to copy!|r")
        print("|cFFFF0000Kryos|r Dungeon Tool: |cFFFFAA00Then press ESC to clear chat box.|r")
        
        return true
    end
    
    -- Fallback: Create a dialog with the string
    local dialog = StaticPopup_Show("KDT_COPY_STRING", text)
    if dialog then
        dialog.editBox:SetText(text)
        dialog.editBox:HighlightText()
        dialog.editBox:SetFocus()
        return true
    end
    
    return false
end

-- Register static popup for copy dialog
if not StaticPopupDialogs["KDT_COPY_STRING"] then
    StaticPopupDialogs["KDT_COPY_STRING"] = {
        text = "Talent String (Press Ctrl+A then Ctrl+C to copy):",
        button1 = "Done",
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self)
            self.editBox:SetText(self.text.text_arg1)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- Format category name for display
function Talents:FormatCategory(category)
    return self.CONTENT_TYPES[category] or category
end

-- Format source name for display
function Talents:FormatSource(source)
    return self.SOURCE_NAMES[source] or source
end

-- Format dungeon name for display
function Talents:FormatDungeon(dungeonID)
    return self.DUNGEON_NAMES[dungeonID] or "Unknown"
end

-- Get color for content category
function Talents:GetCategoryColor(category)
    if category == "mythic" then
        return {0.6, 0.4, 1}
    elseif category == "heroic_raid" then
        return {1, 0.5, 0}
    elseif category == "mythic_raid" then
        return {1, 0.3, 0.3}
    elseif category == "raid" then
        return {1, 0.6, 0}
    else
        return {0.8, 0.8, 0.3}
    end
end

-- Get color for source
function Talents:GetSourceColor(source)
    if source == "archon" then
        return {0.4, 0.8, 1}
    elseif source == "icy-veins" then
        return {0.6, 0.9, 1}
    elseif source == "wowhead" then
        return {1, 0.7, 0.3}
    elseif source == "ugg" then
        return {0.8, 0.4, 1}
    else
        return {0.7, 0.7, 0.7}
    end
end

-- Get current active dungeon (if in M+)
function Talents:GetCurrentDungeon()
    local inInstance, instanceType = IsInInstance()
    
    if not inInstance or instanceType ~= "party" then
        return nil
    end
    
    local name, _, difficulty = GetInstanceInfo()
    
    -- Check if it's a Mythic+ dungeon (difficulty 8 = Mythic, 23 = Mythic+)
    if difficulty ~= 8 and difficulty ~= 23 then
        return nil
    end
    
    -- Map dungeon names to IDs (TWW Season 3)
    -- Based on PeaversTalentsData structure (IDs 0-8)
    local dungeonMap = {
        ["Ara-Kara, City of Echoes"] = 1,          -- ID 1: Ara Kara
        ["Cinderbrew Meadery"] = 2,                -- ID 2: Eco Dome Aldani / Cinderbrew
        ["Darkflame Cleft"] = 3,                   -- ID 3: Halls
        ["Priory of the Sacred Flame"] = 5,        -- ID 5: Priory
        ["The Rookery"] = 6,                       -- ID 6: Gambit
        ["The Stonevault"] = 3,                    -- ID 3: Halls / Stonevault
        ["City of Threads"] = 7,                   -- ID 7: Streets
        ["The Dawnbreaker"] = 8,                   -- ID 8: The Dawnbreaker
        -- Season 3 might include different dungeons - mapping to available IDs
    }
    
    return dungeonMap[name]
end

print("|cFFFF0000Kryos|r Dungeon Tool: Talents module loaded")
