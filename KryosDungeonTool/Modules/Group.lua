-- Kryos Dungeon Tool
-- Modules/Group.lua - Group management with keystone sharing

local addonName, KDT = ...

-- Known group members cache
KDT.knownMembers = {}
KDT.alreadyAlerted = {}
KDT.receivedKeys = {}
KDT.groupKeystones = {}

-- Get group member units
function KDT:GetGroupUnits()
    local units = {}
    local seen = {}
    
    -- Always include player first
    table.insert(units, "player")
    seen["player"] = true
    
    local numGroup = GetNumGroupMembers()
    
    if numGroup > 0 then
        if IsInRaid() then
            -- In raid, iterate raid units
            for i = 1, 40 do
                local unit = "raid" .. i
                if UnitExists(unit) then
                    local name = UnitName(unit)
                    if name and not seen[name] then
                        seen[name] = true
                        if not UnitIsUnit(unit, "player") then
                            table.insert(units, unit)
                        end
                    end
                end
            end
        else
            -- In party, iterate party units
            for i = 1, 4 do
                local unit = "party" .. i
                if UnitExists(unit) then
                    local name = UnitName(unit)
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(units, unit)
                    end
                end
            end
        end
    end
    
    return units
end

-- Refresh group info
function KDT:RefreshGroupInfo()
    local units = self:GetGroupUnits()
    
    -- Request inspects for spec data
    for _, unit in ipairs(units) do
        if UnitIsConnected(unit) and UnitIsVisible(unit) then
            self:QueueInspect(unit)
        end
    end
    
    -- Broadcast own key
    self:BroadcastOwnKey()
    
    -- Update UI if shown
    if self.groupMemberFrames then
        self:UpdateGroupMemberFrames()
    end
    
    -- Update overview
    if self.UpdateGroupOverview then
        self:UpdateGroupOverview()
    end
end

-- Get own keystone info
function KDT:GetOwnKeystone()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
    if mapID and level then
        return {
            mapID = mapID,
            level = level,
            name = self:GetDungeonName(mapID),
        }
    end
    return nil
end

-- Get keystone for a unit
function KDT:GetUnitKeystone(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    local name = UnitName(unit)
    local guid = UnitGUID(unit)
    
    -- Check if it's the player
    if UnitIsUnit(unit, "player") then
        return self:GetOwnKeystone()
    end
    
    -- Check received keys from addon messages
    if name and self.receivedKeys[name] then
        local data = self.receivedKeys[name]
        -- Only use if not too old (5 minutes)
        if GetTime() - (data.time or 0) < 300 then
            return {
                mapID = data.mapID,
                level = data.level,
                name = self:GetDungeonName(data.mapID),
            }
        end
    end
    
    -- Check by full name (server included)
    local fullName = name
    local realm = GetNormalizedRealmName()
    if UnitRealmRelationship(unit) ~= LE_REALM_RELATION_SAME then
        local _, unitRealm = UnitName(unit)
        if unitRealm and unitRealm ~= "" then
            fullName = name .. "-" .. unitRealm
        end
    end
    
    if fullName and self.receivedKeys[fullName] then
        local data = self.receivedKeys[fullName]
        if GetTime() - (data.time or 0) < 300 then
            return {
                mapID = data.mapID,
                level = data.level,
                name = self:GetDungeonName(data.mapID),
            }
        end
    end
    
    return nil
end

-- Get unit spec info
function KDT:GetUnitSpec(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    local guid = UnitGUID(unit)
    
    -- Check if it's the player
    if UnitIsUnit(unit, "player") then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID, specName, _, _, role = GetSpecializationInfo(specIndex)
            return {
                specID = specID,
                specName = specName,
                role = role,
            }
        end
        return nil
    end
    
    -- Check cache first (from Events.lua inspect system)
    if guid and self.specCache and self.specCache[guid] and self.specCache[guid].specName then
        return self.specCache[guid]
    end
    
    -- Try to get spec directly (might work if inspect was done recently)
    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
        local _, specName, _, _, role = GetSpecializationInfoByID(specID)
        if specName then
            -- Cache it
            if not self.specCache then self.specCache = {} end
            self.specCache[guid] = {
                specID = specID,
                specName = specName,
                role = role,
                time = GetTime()
            }
            return self.specCache[guid]
        end
    end
    
    return nil
end

-- Get group overview data
function KDT:GetGroupOverview()
    local overview = {
        tanks = 0,
        healers = 0,
        dps = 0,
        battleRez = nil,
        bloodlust = nil,
        hasStacking = false,
        groupKey = nil,
    }
    
    local classes = {}
    local units = self:GetGroupUnits()
    
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            if class then
                classes[class] = (classes[class] or 0) + 1
                
                -- Check battle rez
                if self.BATTLE_REZ[class] and not overview.battleRez then
                    overview.battleRez = { class = class, unit = unit }
                end
                
                -- Check bloodlust
                if self.BLOODLUST[class] and not overview.bloodlust then
                    overview.bloodlust = { class = class, unit = unit }
                end
            end
            
            -- Count roles
            local specData = self:GetUnitSpec(unit)
            if specData and specData.role then
                if specData.role == "TANK" then
                    overview.tanks = overview.tanks + 1
                elseif specData.role == "HEALER" then
                    overview.healers = overview.healers + 1
                else
                    overview.dps = overview.dps + 1
                end
            else
                -- Fallback to UnitGroupRolesAssigned
                local role = UnitGroupRolesAssigned(unit)
                if role == "TANK" then
                    overview.tanks = overview.tanks + 1
                elseif role == "HEALER" then
                    overview.healers = overview.healers + 1
                else
                    overview.dps = overview.dps + 1
                end
            end
            
            -- Get key
            local keyData = self:GetUnitKeystone(unit)
            if keyData and UnitIsUnit(unit, "player") then
                overview.groupKey = keyData
            end
        end
    end
    
    -- Check for stacking (multiple of same class)
    for class, count in pairs(classes) do
        if count > 1 then
            overview.hasStacking = true
            break
        end
    end
    
    return overview
end

-- Update group member frames in UI
function KDT:UpdateGroupMemberFrames()
    if not self.groupMemberFrames then return end
    
    local units = self:GetGroupUnits()
    
    for i, frame in ipairs(self.groupMemberFrames) do
        local unit = units[i]
        
        if unit and UnitExists(unit) then
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            local specData = self:GetUnitSpec(unit)
            local keyData = self:GetUnitKeystone(unit)
            
            -- Role icon
            local role = specData and specData.role or UnitGroupRolesAssigned(unit)
            if role and self.ROLE_ICONS[role] then
                frame.roleIcon:SetText(self.ROLE_ICONS[role])
            else
                frame.roleIcon:SetText("")
            end
            
            -- Name with class color
            if name then
                local color = class and self.CLASS_COLORS[class] or {1, 1, 1}
                frame.nameText:SetText(name)
                frame.nameText:SetTextColor(color[1], color[2], color[3])
            else
                frame.nameText:SetText("Unknown")
                frame.nameText:SetTextColor(0.5, 0.5, 0.5)
            end
            
            -- Class
            frame.classText:SetText(class and self.CLASS_NAMES[class] or "")
            
            -- Spec
            frame.specText:SetText(specData and specData.specName or "")
            
            -- Keystone
            if keyData then
                frame.keyText:SetText(string.format("[Key] %s +%d", 
                    self:GetShortDungeonName(keyData.mapID), keyData.level))
                frame.keyText:SetTextColor(1, 0.82, 0) -- Gold
            else
                frame.keyText:SetText("No Key")
                frame.keyText:SetTextColor(0.5, 0.5, 0.5)
            end
            
            -- Battle Rez indicator
            if class and self.BATTLE_REZ[class] then
                frame.brText:SetText("BR")
                frame.brText:SetTextColor(0, 1, 0)
                frame.brText:Show()
            else
                frame.brText:Hide()
            end
            
            -- Bloodlust indicator
            if class and self.BLOODLUST[class] then
                frame.blText:SetText("BL")
                frame.blText:SetTextColor(0, 0.5, 1)
                frame.blText:Show()
            else
                frame.blText:Hide()
            end
            
            frame:Show()
        else
            frame:Hide()
        end
    end
end

-- Post group info to chat
function KDT:PostGroupToChat()
    local overview = self:GetGroupOverview()
    local units = self:GetGroupUnits()
    
    -- Build message
    local msg = "Group Composition: "
    msg = msg .. overview.tanks .. " Tank, "
    msg = msg .. overview.healers .. " Healer, "
    msg = msg .. overview.dps .. " DPS"
    
    if overview.battleRez then
        msg = msg .. " | BR: " .. self.CLASS_NAMES[overview.battleRez.class]
    end
    
    if overview.bloodlust then
        msg = msg .. " | BL: " .. self.CLASS_NAMES[overview.bloodlust.class]
    end
    
    -- Send to appropriate channel
    local channel = "SAY"
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    end
    
    SendChatMessage(msg, channel)
end

-- Do ready check
function KDT:DoReadyCheck()
    if not IsInGroup() then
        self:Print("You must be in a group to do a ready check.")
        return
    end
    
    DoReadyCheck()
end

-- Start countdown
function KDT:StartCountdown(seconds)
    if not IsInGroup() then
        self:Print("You must be in a group to start a countdown.")
        return
    end
    
    seconds = seconds or (self.DB and self.DB.settings and self.DB.settings.countdownSeconds) or 10
    C_PartyInfo.DoCountdown(seconds)
end

-- ==================== v1.4 STYLE FUNCTIONS ====================

-- Get group members data
function KDT:GetGroupMembers()
    local members = {}
    local units = self:GetGroupUnits()
    
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            local specData = self:GetUnitSpec(unit)
            local keyData = self:GetUnitKeystone(unit)
            local role = specData and specData.role or UnitGroupRolesAssigned(unit)
            
            local member = {
                unit = unit,
                name = name,
                class = class,
                spec = specData and specData.specName or nil,
                role = role,
                keystone = nil,
            }
            
            if keyData then
                member.keystone = {
                    mapID = keyData.mapID,
                    level = keyData.level,
                    text = self:GetShortDungeonName(keyData.mapID) .. " +" .. keyData.level,
                }
            end
            
            table.insert(members, member)
        end
    end
    
    return members
end

-- Analyze group composition
function KDT:AnalyzeGroup(members)
    local info = {
        tanks = 0,
        healers = 0,
        dps = 0,
        hasBR = false,
        hasBL = false,
        brClasses = {},
        blClasses = {},
        stacking = {},
    }
    
    local classCounts = {}
    
    for _, m in ipairs(members) do
        -- Role counts
        if m.role == "TANK" then
            info.tanks = info.tanks + 1
        elseif m.role == "HEALER" then
            info.healers = info.healers + 1
        else
            info.dps = info.dps + 1
        end
        
        -- Class utilities
        if m.class then
            if self.BATTLE_REZ[m.class] then
                info.hasBR = true
                info.brClasses[m.class] = true
            end
            if self.BLOODLUST[m.class] then
                info.hasBL = true
                info.blClasses[m.class] = true
            end
            
            -- Count classes for stacking
            classCounts[m.class] = (classCounts[m.class] or 0) + 1
        end
    end
    
    -- Check for stacking
    for class, count in pairs(classCounts) do
        if count > 1 then
            table.insert(info.stacking, self.CLASS_NAMES[class] or class)
        end
    end
    
    return info
end

-- Post to chat (v1.4 style) with timer to avoid spam
function KDT:PostToChat()
    if not IsInGroup() then
        self:Print("You must be in a group to post.")
        return
    end
    
    local members = self:GetGroupMembers()
    local info = self:AnalyzeGroup(members)
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    
    -- Find group key (highest level key or own key)
    local groupKey = nil
    local groupKeyLevel = 0
    for _, m in ipairs(members) do
        if m.keystone and m.keystone.level > groupKeyLevel then
            groupKey = m.keystone
            groupKeyLevel = m.keystone.level
        end
    end
    
    -- Build messages queue
    local messages = {}
    
    -- Welcome line with dungeon info
    if groupKey then
        local dungeonName = self:GetDungeonName(groupKey.mapID) or groupKey.text:match("^(%S+)")
        table.insert(messages, "Welcome to this M+ " .. dungeonName .. " +" .. groupKey.level .. " run")
    else
        table.insert(messages, "Welcome to this M+ run")
    end
    
    -- Group composition line
    local header = "[KDT] Group: " .. info.tanks .. " Tank, " .. info.healers .. " Healer, " .. info.dps .. " DPS"
    if info.hasBR and info.hasBL then
        header = header .. " | BR + BL"
    elseif info.hasBR then
        header = header .. " | BR"
    elseif info.hasBL then
        header = header .. " | BL"
    end
    table.insert(messages, header)
    
    -- Each member
    for _, m in ipairs(members) do
        local specStr = m.spec or "?"
        local classStr = self.CLASS_NAMES[m.class] or m.class or "?"
        
        local utils = {}
        if self.BATTLE_REZ[m.class] then table.insert(utils, "BR") end
        if self.BLOODLUST[m.class] then table.insert(utils, "BL") end
        local utilStr = #utils > 0 and " [" .. table.concat(utils, "+") .. "]" or ""
        
        local msg = "- " .. m.name .. " (" .. classStr .. " - " .. specStr .. ")" .. utilStr
        table.insert(messages, msg)
    end
    
    -- Warning if no BR
    if not info.hasBR then
        table.insert(messages, "Be Careful you dont have a BR so dont die!")
    end
    
    -- Warning if no BL
    if not info.hasBL then
        table.insert(messages, "Warning: No Bloodlust available!")
    end
    
    -- Send messages with delay
    local delay = 0
    for i, msg in ipairs(messages) do
        C_Timer.After(delay, function()
            SendChatMessage(msg, channel)
        end)
        delay = delay + 0.5  -- 0.5 second between each message
    end
    
    self:Print("Group info posted to chat.")
end

-- Queue inspect for a unit (simple implementation)
function KDT:QueueInspect(unit)
    if not unit or not UnitExists(unit) then return end
    if UnitIsUnit(unit, "player") then return end
    if not UnitIsConnected(unit) then return end
    if not CanInspect(unit) then return end
    
    -- Simply notify inspect - spec data will be retrieved via GetInspectSpecialization
    NotifyInspect(unit)
end
