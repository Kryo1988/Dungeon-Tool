-- Kryos Dungeon Tool
-- Group.lua - Group analysis and management

local addonName, KDT = ...

-- Cache for player specs
KDT.specCache = {}
KDT.pendingInspects = {}
KDT.knownMembers = {}

-- ==================== KEYSTONE INFO ====================
function KDT:GetKeystoneInfo(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    if UnitIsUnit(unit, "player") then
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        if mapID then
            local level = C_MythicPlus.GetOwnedKeystoneLevel() or 0
            local dungeonName = self.DUNGEON_NAMES[mapID] or "???"
            return {level = level, text = dungeonName .. " +" .. level, mapID = mapID}
        end
    else
        local idx = tonumber(unit:match("party(%d+)"))
        if idx then
            local mapID, level = C_MythicPlus.GetPartyKeystoneInfo(idx)
            if mapID and level and level > 0 then
                local dungeonName = self.DUNGEON_NAMES[mapID] or "???"
                return {level = level, text = dungeonName .. " +" .. level, mapID = mapID}
            end
        end
    end
    return nil
end

-- ==================== GROUP MEMBERS ====================
function KDT:GetGroupMembers()
    local members = {}
    
    -- Player
    local pName = UnitName("player") or "Unknown"
    local _, pClass = UnitClass("player")
    pClass = pClass or "WARRIOR"
    local pRole = UnitGroupRolesAssigned("player") or "DAMAGER"
    if pRole == "" or pRole == "NONE" then pRole = "DAMAGER" end
    
    local pSpec = "Unknown"
    local specIdx = GetSpecialization()
    if specIdx then
        local _, sn = GetSpecializationInfo(specIdx)
        if sn then pSpec = sn end
    end
    
    local pKey = nil
    pcall(function() pKey = self:GetKeystoneInfo("player") end)
    
    members[1] = {
        name = pName,
        class = pClass,
        role = pRole,
        spec = pSpec,
        keystone = pKey
    }
    
    -- Party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                local _, class = UnitClass(unit)
                class = class or "WARRIOR"
                
                local role = UnitGroupRolesAssigned(unit) or "DAMAGER"
                if role == "" or role == "NONE" then role = "DAMAGER" end
                
                local cleanName = name:gsub("%-.*", "")
                local guid = UnitGUID(unit)
                
                -- Try multiple methods to get spec
                local specText = nil
                
                -- Method 1: Check cache first
                if self.specCache[cleanName] then
                    specText = self.specCache[cleanName]
                end
                
                -- Method 2: Try GetInspectSpecialization
                if not specText and guid then
                    local specID = GetInspectSpecialization(unit)
                    if specID and specID > 0 then
                        local _, specName = GetSpecializationInfoByID(specID)
                        if specName then
                            specText = specName
                            self.specCache[cleanName] = specText
                        end
                    end
                end
                
                -- Method 3: Request inspect if not already pending
                if not specText and CanInspect(unit) and not self.pendingInspects[cleanName] then
                    self.pendingInspects[cleanName] = true
                    NotifyInspect(unit)
                end
                
                -- Fallback to role-based text
                if not specText then
                    if role == "TANK" then specText = "Tank"
                    elseif role == "HEALER" then specText = "Healer"
                    else specText = "DPS" end
                end
                
                -- Get keystone info
                local key = nil
                pcall(function() key = self:GetKeystoneInfo(unit) end)
                
                members[#members + 1] = {
                    name = cleanName,
                    class = class,
                    role = role,
                    spec = specText,
                    keystone = key,
                    unit = unit
                }
            end
        end
    end
    
    return members
end

-- ==================== GROUP ANALYSIS ====================
function KDT:AnalyzeGroup(members)
    local info = {
        tanks = 0,
        healers = 0,
        dps = 0,
        hasBR = false,
        brClasses = {},
        hasBL = false,
        blClasses = {},
        stacking = {}
    }
    
    local counts = {}
    for _, m in ipairs(members) do
        if m.role == "TANK" then
            info.tanks = info.tanks + 1
        elseif m.role == "HEALER" then
            info.healers = info.healers + 1
        else
            info.dps = info.dps + 1
        end
        
        counts[m.class] = (counts[m.class] or 0) + 1
        
        if self.BATTLE_REZ[m.class] then
            info.hasBR = true
            info.brClasses[m.class] = true
        end
        if self.BLOODLUST[m.class] then
            info.hasBL = true
            info.blClasses[m.class] = true
        end
    end
    
    for c, n in pairs(counts) do
        if n > 1 then
            info.stacking[#info.stacking + 1] = n .. "x " .. (self.CLASS_NAMES[c] or c)
        end
    end
    
    return info
end

-- ==================== CHAT FUNCTIONS ====================
function KDT:PostToChat()
    local members = self:GetGroupMembers()
    
    if #members < 2 then
        self:Print("Need 2+ players.")
        return
    end
    
    local ch = nil
    if IsInRaid() then
        ch = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        ch = "INSTANCE_CHAT"
    elseif IsInGroup() then
        ch = "PARTY"
    end
    
    if not ch then
        self:Print("Not in group.")
        return
    end
    
    local info = self:AnalyzeGroup(members)
    
    -- Build messages
    local messages = {}
    messages[#messages + 1] = "====== GROUP CHECK ======"
    
    for _, m in ipairs(members) do
        local utilities = {}
        if m.class and self.BATTLE_REZ[m.class] then
            utilities[#utilities + 1] = "BR"
        end
        if m.class and self.BLOODLUST[m.class] then
            utilities[#utilities + 1] = "BL"
        end
        
        local utilStr = ""
        if #utilities > 0 then
            utilStr = " [" .. table.concat(utilities, "/") .. "]"
        end
        
        local keyStr = ""
        if m.keystone and m.keystone.text then
            keyStr = " | " .. m.keystone.text
        end
        
        local className = self.CLASS_NAMES[m.class] or m.class or "Unknown"
        messages[#messages + 1] = m.name .. " - " .. className .. " (" .. m.spec .. ")" .. utilStr .. keyStr
    end
    
    if not info.hasBR then
        messages[#messages + 1] = "[X] NO Battle Rez!"
    end
    if not info.hasBL then
        messages[#messages + 1] = "[X] NO Bloodlust!"
    end
    
    messages[#messages + 1] = "========================="
    
    -- Send with delay
    local delay = 0
    for _, msg in ipairs(messages) do
        C_Timer.After(delay, function()
            SendChatMessage(msg, ch)
        end)
        delay = delay + 0.3
    end
    
    C_Timer.After(delay, function()
        KDT:PrintSuccess("Posted to " .. ch)
    end)
end

function KDT:AnnouncePlayerJoin(name, class, spec)
    local ch = nil
    if IsInRaid() then
        ch = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        ch = "INSTANCE_CHAT"
    elseif IsInGroup() then
        ch = "PARTY"
    end
    
    if not ch then return end
    
    local utilities = {}
    if self.BATTLE_REZ[class] then utilities[#utilities + 1] = "BR" end
    if self.BLOODLUST[class] then utilities[#utilities + 1] = "BL" end
    
    local utilStr = ""
    if #utilities > 0 then
        utilStr = " - brings " .. table.concat(utilities, " & ")
    end
    
    local className = self.CLASS_NAMES[class] or class or "Unknown"
    SendChatMessage("[+] " .. name .. " joined (" .. className .. " - " .. spec .. ")" .. utilStr, ch)
end

function KDT:CheckNewMembers()
    if not self.DB or not self.DB.settings.autoPost then return end
    
    local current = {}
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                local clean = name:gsub("%-.*", "")
                local _, class = UnitClass(unit)
                class = class or "WARRIOR"
                local role = UnitGroupRolesAssigned(unit) or "DAMAGER"
                if role == "" or role == "NONE" then role = "DAMAGER" end
                local spec = (role == "TANK" and "Tank") or (role == "HEALER" and "Healer") or "DPS"
                
                current[clean] = {class = class, spec = spec}
                
                if not self.knownMembers[clean] then
                    self:AnnouncePlayerJoin(clean, class, spec)
                end
            end
        end
    end
    
    self.knownMembers = current
end

-- ==================== PARTY ACTIONS ====================
function KDT:StartCountdown()
    if IsInGroup() then
        C_PartyInfo.DoCountdown(self.DB.settings.countdownSeconds or 10)
    else
        self:Print("Need group.")
    end
end

function KDT:RequestPartyInspect()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsConnected(unit) and CheckInteractDistance(unit, 1) then
            NotifyInspect(unit)
        end
    end
end
