-- Kryos Dungeon Tool
-- SlashCommands.lua - Slash commands

local addonName, KDT = ...

-- ==================== SLASH COMMANDS ====================
function KDT:RegisterSlashCommands()
    SLASH_KDT1 = "/kdt"
    SLASH_KDT2 = "/kryos"
    
    SlashCmdList["KDT"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        
        if cmd == "" then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("group")
            
        elseif cmd == "bl" or cmd == "blacklist" then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("blacklist")
            
        elseif cmd == "tp" or cmd == "teleport" then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("teleport")
            
        elseif cmd == "cd" then
            KDT:StartCountdown()
            
        elseif cmd == "ready" then
            if IsInGroup() then DoReadyCheck() end
            
        elseif cmd == "post" then
            KDT:PostToChat()
            
        elseif cmd == "share" then
            KDT:ShareBlacklist()
            
        elseif cmd == "debug" then
            KDT:DebugKeystone()
            
        else
            KDT:Print("Commands: /kdt, /kdt bl, /kdt tp, /kdt cd, /kdt ready, /kdt post, /kdt share, /kdt debug")
        end
    end
end

-- ==================== DEBUG ====================
function KDT:DebugKeystone()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
    if mapID then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        print("|cFF00FFFF[Kryos Debug]|r Your Keystone:")
        print("  MapID: |cFFFFFF00" .. mapID .. "|r")
        print("  Name: |cFFFFFF00" .. (name or "Unknown") .. "|r")
        print("  Level: |cFFFFFF00+" .. (level or 0) .. "|r")
        print("  Current mapping: |cFFFFFF00" .. (self.DUNGEON_NAMES[mapID] or "NOT FOUND") .. "|r")
    else
        print("|cFF00FFFF[Kryos Debug]|r You don't have a keystone")
    end
    
    -- Show all season dungeons
    print("|cFF00FFFF[Kryos Debug]|r Current Season Dungeons:")
    local mapIDs = C_ChallengeMode.GetMapTable()
    if mapIDs then
        for _, id in ipairs(mapIDs) do
            local dname = C_ChallengeMode.GetMapUIInfo(id)
            local mapped = self.DUNGEON_NAMES[id] or "MISSING"
            print("  [" .. id .. "] " .. (dname or "?") .. " = " .. mapped)
        end
    end
end
