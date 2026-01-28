-- Kryos Dungeon Tool
-- Blacklist.lua - Blacklist management

local addonName, KDT = ...

-- Track already alerted players (to avoid spam)
KDT.alreadyAlerted = {}

-- ==================== BLACKLIST FUNCTIONS ====================
function KDT:IsBlacklisted(name)
    if not name or not self.DB then return false end
    return self.DB.blacklist[name:gsub("%-.*", "")] ~= nil
end

function KDT:AddToBlacklist(name, reason)
    if not name or name == "" then return end
    name = name:gsub("^%l", string.upper):gsub("%-.*", "")
    self.DB.blacklist[name] = {
        reason = reason or "No reason",
        timestamp = time()
    }
    self:Print("Added: " .. name)
end

function KDT:RemoveFromBlacklist(name)
    if not name then return end
    local cleanName = name:gsub("%-.*", "")
    self.DB.blacklist[cleanName] = nil
    self.alreadyAlerted[cleanName] = nil
    self:Print("Removed: " .. cleanName)
end

function KDT:CheckBlacklistAlert()
    local current = {}
    for i = 1, 4 do
        local name = UnitName("party" .. i)
        if name then
            local clean = name:gsub("%-.*", "")
            current[clean] = true
            if self:IsBlacklisted(clean) and not self.alreadyAlerted[clean] then
                self.alreadyAlerted[clean] = true
                local d = self.DB.blacklist[clean]
                print("|cFFFF0000[Kryos ALERT]|r " .. clean .. " is blacklisted! Reason: " .. (d and d.reason or "?"))
                if self.DB.settings.customSound then
                    PlaySoundFile("Interface\\AddOns\\KryosDungeonTool\\intruder.mp3", "Master")
                else
                    PlaySound(SOUNDKIT.RAID_WARNING, "Master")
                end
            end
        end
    end
    -- Clear alerts for players who left
    for name in pairs(self.alreadyAlerted) do
        if not current[name] then
            self.alreadyAlerted[name] = nil
        end
    end
end

-- ==================== BLACKLIST SHARING ====================
C_ChatInfo.RegisterAddonMessagePrefix("KryosDT")

function KDT:ShareBlacklist()
    if not IsInGroup() then
        self:Print("Not in a group.")
        return
    end
    
    local count = 0
    local channel = IsInRaid() and "RAID" or "PARTY"
    
    for name, info in pairs(self.DB.blacklist) do
        C_ChatInfo.SendAddonMessage("KryosDT", "BL:" .. name .. ":" .. ((info.reason or ""):gsub("[|:]", " ")), channel)
        count = count + 1
    end
    
    if count == 0 then
        self:Print("Blacklist is empty.")
    else
        self:PrintSuccess("Shared " .. count .. " players.")
    end
end

function KDT:ReceiveBlacklist(msg, sender)
    if not msg:match("^BL:") then return end
    if sender:gsub("%-.*", "") == UnitName("player") then return end
    
    local name, reason = msg:match("^BL:([^:]+):(.*)$")
    if name and not self.DB.blacklist[name] then
        self.DB.blacklist[name] = {
            reason = (reason or "") .. " (from " .. sender:gsub("%-.*", "") .. ")",
            timestamp = time()
        }
        self:PrintSuccess("Received: " .. name .. " from " .. sender:gsub("%-.*", ""))
    end
end
