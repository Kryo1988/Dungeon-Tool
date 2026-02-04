-- Kryos Dungeon Tool
-- Modules/Meter.lua - Damage/Heal Meter
-- WoW 12.0+: Uses C_DamageMeter API with DIRECT UI binding (like Details!)
-- KEY INSIGHT: Pass secret values directly to UI widgets - they can render them!

local addonName, KDT = ...

local _, _, _, buildInfo = GetBuildInfo()
local IS_MIDNIGHT = buildInfo >= 120000

-- ==================== METER DATA ====================
KDT.Meter = {
    enabled = true,
    segments = {},
    currentSegment = nil,
    viewingSegmentIndex = 0,
    overallData = nil,
    inCombat = false,
    combatStartTime = 0,
    windows = {},
    initialized = false,
    processCount = 0,
    isMidnight = IS_MIDNIGHT,
    updateTicker = nil,
    maxSegments = 25,
    
    -- Live data from API (may contain secret values)
    liveSession = nil,
    liveDamageType = nil,
    
    defaults = {
        enabled = true, barHeight = 18, barSpacing = 1,
        barTexture = "Interface\\Buttons\\WHITE8X8",
        maxBars = 10, font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11, fontFlags = "OUTLINE",
        classColors = true, windowWidth = 250, windowHeight = 200,
        windowScale = 1.0,
        bgColor = {0.05, 0.05, 0.07, 0.9},
        borderColor = {0.2, 0.2, 0.25, 1},
    }
}

KDT.Meter.MODES = {
    DAMAGE = 1, HEALING = 2, DPS = 3, HPS = 4,
    INTERRUPTS = 5, DEATHS = 6, DAMAGE_TAKEN = 7,
}

KDT.Meter.MODE_NAMES = {
    [1] = "Damage Done", [2] = "Healing Done", [3] = "DPS", [4] = "HPS",
    [5] = "Interrupts", [6] = "Deaths", [7] = "Damage Taken",
}

-- Map our modes to Blizzard's DamageMeterType
KDT.Meter.MODE_TO_BLIZZARD = {
    [1] = Enum.DamageMeterType.DamageDone,
    [2] = Enum.DamageMeterType.HealingDone,
    [3] = Enum.DamageMeterType.DamageDone,  -- DPS uses damage
    [4] = Enum.DamageMeterType.HealingDone, -- HPS uses healing
    [5] = Enum.DamageMeterType.Interrupts,
    [6] = nil, -- Deaths not available
    [7] = Enum.DamageMeterType.DamageTaken,
}

local function CreateSegment(name)
    return {
        name = name or "Combat", startTime = GetTime(), endTime = 0, duration = 0,
        players = {}, totalDamage = 0, totalHealing = 0, totalInterrupts = 0,
        totalDeaths = 0, timestamp = date("%H:%M:%S"),
    }
end

local function CreatePlayerData(name, class)
    return {
        name = name or "Unknown", class = class or "UNKNOWN",
        damage = 0, healing = 0, damageTaken = 0,
        interrupts = 0, deaths = 0, dps = 0, hps = 0,
    }
end

local function FormatNumber(num)
    if not num or num == 0 then return "0" end
    if num >= 1000000000 then return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

KDT.Meter.FormatNumber = FormatNumber

local Meter = KDT.Meter

function Meter:StartCombat(name)
    if self.inCombat then return end
    
    self.inCombat = true
    self.combatStartTime = GetTime()
    
    local segmentName = name or "Combat"
    local instanceName = GetInstanceInfo()
    if instanceName and instanceName ~= "" then segmentName = instanceName end
    
    local targetName = UnitName("target")
    if targetName and UnitIsEnemy("player", "target") then
        local classification = UnitClassification("target")
        if classification == "worldboss" or classification == "rareelite" or classification == "elite" or classification == "rare" then
            segmentName = targetName
        end
    end
    
    self.currentSegment = CreateSegment(segmentName)
    self.viewingSegmentIndex = 0
end

function Meter:EndCombat()
    if not self.inCombat then return end
    
    self.inCombat = false
    
    if self.currentSegment then
        self.currentSegment.endTime = GetTime()
        self.currentSegment.duration = self.currentSegment.endTime - self.currentSegment.startTime
        
        -- Final data collection when combat ends (values are readable now)
        if IS_MIDNIGHT and C_DamageMeter then
            self:CollectFinalData()
        end
        
        if self.currentSegment.totalDamage > 0 or self.currentSegment.totalHealing > 0 then
            table.insert(self.segments, 1, self.currentSegment)
            while #self.segments > self.maxSegments do table.remove(self.segments) end
            self:CalculateOverall()
        end
    end
    
    self:RefreshAllWindows()
end

-- Collect data after combat when values are readable
function Meter:CollectFinalData()
    if not self.currentSegment then return end
    
    local sessionType = Enum.DamageMeterSessionType.Current
    
    -- Damage
    local dmgSession = C_DamageMeter.GetCombatSessionFromType(sessionType, Enum.DamageMeterType.DamageDone)
    if dmgSession and dmgSession.combatSources then
        for i, source in ipairs(dmgSession.combatSources) do
            local name = source.isLocalPlayer and UnitName("player") or (source.name and UnitName(source.name)) or ("Player " .. i)
            if name then
                if not self.currentSegment.players[name] then
                    self.currentSegment.players[name] = CreatePlayerData(name, source.classFilename)
                end
                local p = self.currentSegment.players[name]
                if source.totalAmount and not (issecretvalue and issecretvalue(source.totalAmount)) then
                    p.damage = source.totalAmount
                    self.currentSegment.totalDamage = self.currentSegment.totalDamage + source.totalAmount
                end
                if source.amountPerSecond and not (issecretvalue and issecretvalue(source.amountPerSecond)) then
                    p.dps = source.amountPerSecond
                end
            end
        end
    end
    
    -- Healing
    local healSession = C_DamageMeter.GetCombatSessionFromType(sessionType, Enum.DamageMeterType.HealingDone)
    if healSession and healSession.combatSources then
        for i, source in ipairs(healSession.combatSources) do
            local name = source.isLocalPlayer and UnitName("player") or (source.name and UnitName(source.name)) or ("Player " .. i)
            if name then
                if not self.currentSegment.players[name] then
                    self.currentSegment.players[name] = CreatePlayerData(name, source.classFilename)
                end
                local p = self.currentSegment.players[name]
                if source.totalAmount and not (issecretvalue and issecretvalue(source.totalAmount)) then
                    p.healing = source.totalAmount
                    self.currentSegment.totalHealing = self.currentSegment.totalHealing + source.totalAmount
                end
                if source.amountPerSecond and not (issecretvalue and issecretvalue(source.amountPerSecond)) then
                    p.hps = source.amountPerSecond
                end
            end
        end
    end
end

function Meter:GetOrCreatePlayer(segment, name, class)
    if not segment or not name then return nil end
    if not segment.players[name] then
        segment.players[name] = CreatePlayerData(name, class)
    end
    return segment.players[name]
end

-- Get live session data for direct UI binding
function Meter:GetLiveSession(mode)
    if not IS_MIDNIGHT or not C_DamageMeter then return nil end
    
    local blizzType = self.MODE_TO_BLIZZARD[mode]
    if not blizzType then return nil end
    
    return C_DamageMeter.GetCombatSessionFromType(Enum.DamageMeterSessionType.Current, blizzType)
end

-- Combat state update
function Meter:UpdateCombatState()
    if not IS_MIDNIGHT then return end
    
    self.processCount = (self.processCount or 0) + 1
    
    local playerInCombat = UnitAffectingCombat("player")
    
    if playerInCombat and not self.inCombat then
        self:StartCombat()
    end
    
    if not playerInCombat and self.inCombat then
        if not self.combatEndPending then
            self.combatEndPending = true
            C_Timer.After(2, function()
                if not UnitAffectingCombat("player") and self.inCombat then
                    self:EndCombat()
                end
                self.combatEndPending = nil
            end)
        end
    end
end

-- CLEU Processing for WoW 11.x
function Meter:ProcessCombatLogEvent(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    if not self.enabled or IS_MIDNIGHT then return end
    self.processCount = (self.processCount or 0) + 1
    
    local function IsTracked(flags)
        if not flags then return false end
        return bit.band(flags, 0x00000400) > 0 and bit.band(flags, 0x00000007) > 0
    end
    
    local function GetClass(guid)
        local _, class = guid and GetPlayerInfoByGUID(guid)
        return class or "UNKNOWN"
    end
    
    if not self.inCombat and IsTracked(sourceFlags) then
        if subevent:match("DAMAGE") or subevent:match("HEAL") then self:StartCombat() end
    end
    
    if not self.currentSegment then return end
    
    local arg12, arg13, arg14, arg15, arg16 = ...
    local trackSource = IsTracked(sourceFlags)
    
    if subevent == "SWING_DAMAGE" then
        local amount = arg12 or 0
        if trackSource and amount > 0 and sourceName then
            local p = self:GetOrCreatePlayer(self.currentSegment, sourceName, GetClass(sourceGUID))
            if p then p.damage = p.damage + amount; self.currentSegment.totalDamage = self.currentSegment.totalDamage + amount end
        end
    elseif subevent:match("SPELL.*DAMAGE") or subevent == "RANGE_DAMAGE" then
        local amount = arg15 or 0
        if trackSource and amount > 0 and sourceName then
            local p = self:GetOrCreatePlayer(self.currentSegment, sourceName, GetClass(sourceGUID))
            if p then p.damage = p.damage + amount; self.currentSegment.totalDamage = self.currentSegment.totalDamage + amount end
        end
    elseif subevent:match("SPELL.*HEAL") then
        local amount, over = arg15 or 0, arg16 or 0
        if trackSource and amount > over and sourceName then
            local p = self:GetOrCreatePlayer(self.currentSegment, sourceName, GetClass(sourceGUID))
            if p then local eff = amount - over; p.healing = p.healing + eff; self.currentSegment.totalHealing = self.currentSegment.totalHealing + eff end
        end
    elseif subevent == "SPELL_INTERRUPT" and trackSource and sourceName then
        local p = self:GetOrCreatePlayer(self.currentSegment, sourceName, GetClass(sourceGUID))
        if p then p.interrupts = p.interrupts + 1; self.currentSegment.totalInterrupts = self.currentSegment.totalInterrupts + 1 end
    end
end

-- Segment Management
function Meter:GetSegmentList()
    local list = {{index = 0, name = "Current Segment", segment = self.currentSegment}}
    for i, seg in ipairs(self.segments) do
        table.insert(list, {index = i, name = (seg.name or ("Segment #" .. i)) .. (seg.timestamp and (" (" .. seg.timestamp .. ")") or ""), segment = seg})
    end
    if self.overallData then table.insert(list, {index = -1, name = "Overall Data", segment = self.overallData}) end
    return list
end

function Meter:SetViewingSegment(index) self.viewingSegmentIndex = index; self:RefreshAllWindows() end

function Meter:GetCurrentSegment()
    if self.viewingSegmentIndex == 0 then return self.currentSegment
    elseif self.viewingSegmentIndex == -1 then return self.overallData
    else return self.segments[self.viewingSegmentIndex] end
end

function Meter:GetSegmentName()
    if self.viewingSegmentIndex == 0 then return "Current"
    elseif self.viewingSegmentIndex == -1 then return "Overall"
    else return self.segments[self.viewingSegmentIndex] and self.segments[self.viewingSegmentIndex].name or ("Segment " .. self.viewingSegmentIndex) end
end

function Meter:CalculateOverall()
    self.overallData = CreateSegment("Overall")
    self.overallData.startTime = 0
    local playerTotals, totalDuration = {}, 0
    for _, seg in ipairs(self.segments) do
        totalDuration = totalDuration + (seg.duration or 0)
        for name, player in pairs(seg.players) do
            if not playerTotals[name] then playerTotals[name] = CreatePlayerData(name, player.class) end
            local p = playerTotals[name]
            p.damage, p.healing = p.damage + player.damage, p.healing + player.healing
            p.damageTaken, p.interrupts = p.damageTaken + player.damageTaken, p.interrupts + player.interrupts
            p.deaths = p.deaths + player.deaths
        end
        self.overallData.totalDamage = self.overallData.totalDamage + seg.totalDamage
        self.overallData.totalHealing = self.overallData.totalHealing + seg.totalHealing
        self.overallData.totalInterrupts = self.overallData.totalInterrupts + seg.totalInterrupts
    end
    if totalDuration > 0 then
        for _, p in pairs(playerTotals) do p.dps, p.hps = p.damage / totalDuration, p.healing / totalDuration end
    end
    self.overallData.players, self.overallData.duration = playerTotals, totalDuration
end

-- For historical data (non-live)
function Meter:GetSortedData(mode, segment)
    segment = segment or self:GetCurrentSegment()
    if not segment then return {} end
    local data, duration = {}, math.max(segment.duration > 0 and segment.duration or (segment.startTime > 0 and (GetTime() - segment.startTime) or 1), 1)
    for name, player in pairs(segment.players) do
        local value = 0
        if mode == self.MODES.DAMAGE then value = player.damage
        elseif mode == self.MODES.HEALING then value = player.healing
        elseif mode == self.MODES.DPS then value = player.dps > 0 and player.dps or (player.damage / duration)
        elseif mode == self.MODES.HPS then value = player.hps > 0 and player.hps or (player.healing / duration)
        elseif mode == self.MODES.INTERRUPTS then value = player.interrupts
        elseif mode == self.MODES.DEATHS then value = player.deaths
        elseif mode == self.MODES.DAMAGE_TAKEN then value = player.damageTaken end
        if value > 0 then table.insert(data, {name = player.name, class = player.class, value = value}) end
    end
    table.sort(data, function(a, b) return a.value > b.value end)
    return data
end

function Meter:GetTotal(mode, segment)
    segment = segment or self:GetCurrentSegment()
    if not segment then return 0 end
    local duration = math.max(segment.duration > 0 and segment.duration or (segment.startTime > 0 and (GetTime() - segment.startTime) or 1), 1)
    if mode == self.MODES.DAMAGE then return segment.totalDamage
    elseif mode == self.MODES.HEALING then return segment.totalHealing
    elseif mode == self.MODES.DPS then return segment.totalDamage / duration
    elseif mode == self.MODES.HPS then return segment.totalHealing / duration
    elseif mode == self.MODES.INTERRUPTS then return segment.totalInterrupts
    elseif mode == self.MODES.DEATHS then return segment.totalDeaths
    elseif mode == self.MODES.DAMAGE_TAKEN then
        local t = 0; for _, p in pairs(segment.players) do t = t + p.damageTaken end; return t
    end
    return 0
end

function Meter:Initialize()
    if self.initialized then return end
    self.initialized = true
    self.eventFrame = KDT.CombatLogFrame
    if KDT.DB and KDT.DB.meter then self.enabled = KDT.DB.meter.enabled ~= false end
    
    if IS_MIDNIGHT then
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
        eventFrame:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
        eventFrame:SetScript("OnEvent", function(_, event, ...)
            if self.enabled then self:UpdateCombatState(); self:RefreshAllWindows() end
        end)
    end
    
    self.updateTicker = C_Timer.NewTicker(0.1, function()
        if self.enabled then
            if IS_MIDNIGHT then self:UpdateCombatState()
            elseif self.inCombat and not UnitAffectingCombat("player") then self:EndCombat() end
            self:RefreshAllWindows()
        end
    end)
    
    -- Restore all saved windows
    C_Timer.After(1, function()
        if KDT.DB and KDT.DB.meter then
            local openWindows = KDT.DB.meter.openWindows
            if openWindows and #openWindows > 0 then
                -- Restore each saved window
                for _, windowData in ipairs(openWindows) do
                    local id = windowData.id or 1
                    if not self.windows[id] then
                        self:CreateWindow(id)
                    end
                    if self.windows[id] then
                        -- Restore mode
                        if windowData.mode then
                            self.windows[id].mode = windowData.mode
                        end
                        self.windows[id].frame:Show()
                        self.windows[id]:Refresh()
                    end
                end
            elseif KDT.DB.meter.windowVisible then
                -- Fallback for old save format
                if not self.windows[1] then self:CreateWindow(1) end
                if self.windows[1] then self.windows[1].frame:Show(); self.windows[1]:Refresh() end
            end
        end
    end)
    
    KDT:Print("DMG Meter: " .. (IS_MIDNIGHT and "C_DamageMeter (live)" or "CLEU"))
end

function Meter:SaveOpenWindows()
    if not KDT.DB then return end
    KDT.DB.meter = KDT.DB.meter or {}
    
    local openWindows = {}
    for id, window in pairs(self.windows) do
        if window.frame and window.frame:IsShown() then
            table.insert(openWindows, {
                id = id,
                mode = window.mode
            })
        end
    end
    
    KDT.DB.meter.openWindows = openWindows
    KDT.DB.meter.windowVisible = #openWindows > 0
end

function Meter:Reset() self.currentSegment = nil; self.inCombat = false; self.viewingSegmentIndex = 0; self:RefreshAllWindows() end
function Meter:ResetAll() self:Reset(); wipe(self.segments); self.overallData = nil; self:RefreshAllWindows() end
function Meter:RefreshAllWindows() for _, w in pairs(self.windows) do if w.Refresh then w:Refresh() end end end
