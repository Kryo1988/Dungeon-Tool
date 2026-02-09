-- Kryos Dungeon Tool
-- Modules/Meter.lua - Enhanced Damage/Heal Meter
-- WoW 12.0+: Uses C_DamageMeter API with Blizzard DamageMeter overlay (Details-inspired)
-- Features: Session-based tracking, Spell breakdowns, Absorbs/Dispels, Live overlay

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
    
    -- Session tracking (WoW 12.0)
    currentSessionId = nil,
    sessionMap = {},
    storedSessionIds = {},
    dismissedSessionIds = {},  -- Sessions hidden after Clear All
    
    -- Restriction state tracking
    isRestricted = false,
    
    -- Blizzard DamageMeter overlay
    blzOverlayEnabled = false,
    blzWindows = {},
    
    defaults = {
        enabled = true, barHeight = 18, barSpacing = 1,
        barTexture = "Interface\\Buttons\\WHITE8X8",
        maxBars = 10, font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11, fontFlags = "OUTLINE",
        classColors = true, windowWidth = 250, windowHeight = 200,
        windowScale = 1.0, showSelfTop = false, clearOnEnter = false,
        showRank = true, showPercent = true,
        bgColor = {0.05, 0.05, 0.07, 0.9},
        borderColor = {0.2, 0.2, 0.25, 1},
    }
}

-- Extended modes including new WoW 12.0 types (from Details)
KDT.Meter.MODES = {
    DAMAGE = 1, HEALING = 2, DPS = 3, HPS = 4,
    INTERRUPTS = 5, DEATHS = 6, DAMAGE_TAKEN = 7,
    ABSORBS = 8, DISPELS = 9,
}

KDT.Meter.MODE_NAMES = {
    [1] = "Damage Done", [2] = "Healing Done", [3] = "DPS", [4] = "HPS",
    [5] = "Interrupts", [6] = "Deaths", [7] = "Damage Taken",
    [8] = "Absorbs", [9] = "Dispels",
}

-- Map modes to Blizzard DamageMeterType (WoW 12.0 Enum)
-- Includes new types: Dps, Hps, Absorbs, Dispels (discovered via Details)
KDT.Meter.MODE_TO_BLIZZARD = {}
if IS_MIDNIGHT and Enum and Enum.DamageMeterType then
    KDT.Meter.MODE_TO_BLIZZARD = {
        [1] = Enum.DamageMeterType.DamageDone,
        [2] = Enum.DamageMeterType.HealingDone,
        [3] = Enum.DamageMeterType.Dps or Enum.DamageMeterType.DamageDone,
        [4] = Enum.DamageMeterType.Hps or Enum.DamageMeterType.HealingDone,
        [5] = Enum.DamageMeterType.Interrupts,
        [6] = nil,
        [7] = Enum.DamageMeterType.DamageTaken,
        [8] = Enum.DamageMeterType.Absorbs,
        [9] = Enum.DamageMeterType.Dispels,
    }
end

-- Max DamageMeterType enum value (for iteration like Details)
local CONST_MAX_DAMAGEMETER_TYPES = 0
if IS_MIDNIGHT and Enum and Enum.DamageMeterType then
    for _, v in pairs(Enum.DamageMeterType) do
        if v > CONST_MAX_DAMAGEMETER_TYPES then
            CONST_MAX_DAMAGEMETER_TYPES = v
        end
    end
end

local function CreateSegment(name)
    return {
        name = name or "Combat", startTime = GetTime(), endTime = 0, duration = 0,
        players = {}, totalDamage = 0, totalHealing = 0, totalInterrupts = 0,
        totalDeaths = 0, totalAbsorbs = 0, totalDispels = 0, totalDamageTaken = 0,
        timestamp = date("%H:%M:%S"),
        sessionId = nil,
        spellData = {},
    }
end

local function CreatePlayerData(name, class)
    return {
        name = name or "Unknown", class = class or "UNKNOWN",
        damage = 0, healing = 0, damageTaken = 0,
        interrupts = 0, deaths = 0, dps = 0, hps = 0,
        absorbs = 0, dispels = 0,
        sourceGUID = nil,
        specIcon = nil,
    }
end

local function FormatNumber(num)
    if num == nil then return "0" end
    if issecretvalue and issecretvalue(num) then return "?" end
    if num == 0 then return "0" end
    if num >= 1000000000 then return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

KDT.Meter.FormatNumber = FormatNumber

local Meter = KDT.Meter

-- ==================== HELPER FUNCTIONS ====================
local function SafeRead(value)
    if value == nil then return nil end
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

local function GetSourceName(source)
    if source.isLocalPlayer then return UnitName("player") end
    local name = SafeRead(source.name)
    if name then
        local resolved = UnitName(name)
        return resolved or name
    end
    return nil
end

local function GetSourceClass(source)
    return SafeRead(source.classFilename) or "UNKNOWN"
end

-- ==================== RESTRICTION STATE (WoW 12.0) ====================
function Meter:UpdateRestrictionState()
    if not IS_MIDNIGHT then self.isRestricted = false; return end
    
    if C_RestrictedActions and C_RestrictedActions.GetAddOnRestrictionState then
        local stateCombat = C_RestrictedActions.GetAddOnRestrictionState(Enum.AddOnRestrictionType.Combat)
        local stateEncounter = C_RestrictedActions.GetAddOnRestrictionState(Enum.AddOnRestrictionType.Encounter)
        local stateCM = C_RestrictedActions.GetAddOnRestrictionState(Enum.AddOnRestrictionType.ChallengeMode)
        self.isRestricted = (stateCombat ~= 0) or (stateEncounter ~= 0) or (stateCM ~= 0)
    else
        self.isRestricted = self.inCombat
    end
end

-- ==================== SESSION MANAGEMENT (WoW 12.0) ====================
function Meter:GetAvailableSessions()
    if not IS_MIDNIGHT or not C_DamageMeter then return {} end
    return C_DamageMeter.GetAvailableCombatSessions() or {}
end

function Meter:GetCurrentSessionId()
    local sessions = self:GetAvailableSessions()
    if #sessions > 0 then return sessions[#sessions].sessionID end
    return nil
end

function Meter:DoesSessionExist(sessionId)
    for _, session in ipairs(self:GetAvailableSessions()) do
        if session.sessionID == sessionId then return true end
    end
    return false
end

-- ==================== COMBAT LIFECYCLE ====================
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
    
    if IS_MIDNIGHT then
        self.currentSessionId = self:GetCurrentSessionId()
        if self.currentSessionId then
            self.currentSegment.sessionId = self.currentSessionId
        end
    end
    
    self:UpdateRestrictionState()
end

function Meter:EndCombat()
    if not self.inCombat then return end
    
    self.inCombat = false
    
    if self.currentSegment then
        self.currentSegment.endTime = GetTime()
        self.currentSegment.duration = self.currentSegment.endTime - self.currentSegment.startTime
        
        if IS_MIDNIGHT then
            local sessionId = self:GetCurrentSessionId()
            if sessionId then
                self.currentSegment.sessionId = sessionId
                self.currentSessionId = sessionId
            end
        end
        
        -- Final data collection (values are readable after combat ends)
        if IS_MIDNIGHT and C_DamageMeter then
            self:CollectSessionData()
        end
        
        if self.currentSegment.totalDamage > 0 or self.currentSegment.totalHealing > 0 then
            table.insert(self.segments, 1, self.currentSegment)
            while #self.segments > self.maxSegments do table.remove(self.segments) end
        end
    end
    
    self:UpdateRestrictionState()
    self:RefreshAllWindows()
end

-- ==================== SESSION DATA COLLECTION (WoW 12.0) ====================
function Meter:CollectSessionData()
    if not self.currentSegment then return end
    
    local sessionId = self.currentSegment.sessionId or self:GetCurrentSessionId()
    if not sessionId then
        self:CollectFinalData()
        return
    end
    
    self.storedSessionIds[sessionId] = true
    
    -- Reset totals before collecting (prevent double-counting)
    self.currentSegment.totalDamage = 0
    self.currentSegment.totalHealing = 0
    self.currentSegment.totalInterrupts = 0
    self.currentSegment.totalDamageTaken = 0
    self.currentSegment.totalAbsorbs = 0
    self.currentSegment.totalDispels = 0
    
    self:CollectTypeData(sessionId, Enum.DamageMeterType.DamageDone, "damage", "dps", "totalDamage")
    self:CollectTypeData(sessionId, Enum.DamageMeterType.HealingDone, "healing", "hps", "totalHealing")
    self:CollectTypeData(sessionId, Enum.DamageMeterType.DamageTaken, "damageTaken", nil, "totalDamageTaken")
    self:CollectTypeData(sessionId, Enum.DamageMeterType.Interrupts, "interrupts", nil, "totalInterrupts")
    
    if Enum.DamageMeterType.Absorbs then
        self:CollectTypeData(sessionId, Enum.DamageMeterType.Absorbs, "absorbs", nil, "totalAbsorbs")
    end
    if Enum.DamageMeterType.Dispels then
        self:CollectTypeData(sessionId, Enum.DamageMeterType.Dispels, "dispels", nil, "totalDispels")
    end
    
    -- Collect spell breakdowns
    self:CollectSpellBreakdowns(sessionId)
end

-- Generic type data collection (reduces code duplication)
function Meter:CollectTypeData(sessionId, dmType, field, psField, totalField)
    local session = C_DamageMeter.GetCombatSessionFromID(sessionId, dmType)
    if not session or not session.combatSources then return end
    
    for _, source in ipairs(session.combatSources) do
        if source.classFilename then
            local name = GetSourceName(source)
            if name then
                local p = self:GetOrCreatePlayer(self.currentSegment, name, GetSourceClass(source))
                if p then
                    p.sourceGUID = SafeRead(source.sourceGUID) or p.sourceGUID
                    p.specIcon = SafeRead(source.specIconID) or p.specIcon
                    local amount = SafeRead(source.totalAmount)
                    if amount then
                        p[field] = amount
                        if totalField then
                            self.currentSegment[totalField] = self.currentSegment[totalField] + amount
                        end
                    end
                    if psField then
                        local perSec = SafeRead(source.amountPerSecond)
                        if perSec then p[psField] = perSec end
                    end
                end
            end
        end
    end
end

-- ==================== SPELL BREAKDOWNS (WoW 12.0) ====================
function Meter:CollectSpellBreakdowns(sessionId)
    if not C_DamageMeter.GetCombatSessionSourceFromID then return end
    
    local segment = self.currentSegment
    if not segment then return end
    segment.spellData = segment.spellData or {}
    
    local typesToCollect = {
        {type = Enum.DamageMeterType.DamageDone, field = "damageSpells"},
        {type = Enum.DamageMeterType.HealingDone, field = "healingSpells"},
    }
    if Enum.DamageMeterType.Absorbs then
        table.insert(typesToCollect, {type = Enum.DamageMeterType.Absorbs, field = "absorbSpells"})
    end
    if Enum.DamageMeterType.Interrupts then
        table.insert(typesToCollect, {type = Enum.DamageMeterType.Interrupts, field = "interruptSpells"})
    end
    if Enum.DamageMeterType.Dispels then
        table.insert(typesToCollect, {type = Enum.DamageMeterType.Dispels, field = "dispelSpells"})
    end
    
    for _, typeInfo in ipairs(typesToCollect) do
        local session = C_DamageMeter.GetCombatSessionFromID(sessionId, typeInfo.type)
        if session and session.combatSources then
            for _, source in ipairs(session.combatSources) do
                local name = GetSourceName(source)
                local guid = SafeRead(source.sourceGUID)
                if name and guid then
                    local ok, spellData = pcall(C_DamageMeter.GetCombatSessionSourceFromID, sessionId, typeInfo.type, guid)
                    if ok and spellData and spellData.combatSpells then
                        segment.spellData[name] = segment.spellData[name] or {}
                        segment.spellData[name][typeInfo.field] = {}
                        
                        for _, spell in ipairs(spellData.combatSpells) do
                            local spellId = SafeRead(spell.spellID)
                            local spellTotal = SafeRead(spell.totalAmount)
                            if spellId and spellTotal then
                                local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
                                local spellName = spellInfo and spellInfo.name or ("Spell " .. spellId)
                                local spellIcon = spellInfo and spellInfo.iconID
                                table.insert(segment.spellData[name][typeInfo.field], {
                                    id = spellId,
                                    name = spellName or ("Spell " .. spellId),
                                    icon = spellIcon,
                                    total = spellTotal,
                                })
                            end
                        end
                        
                        table.sort(segment.spellData[name][typeInfo.field], function(a, b) return a.total > b.total end)
                    end
                end
            end
        end
    end
end

-- Get spell breakdown for a player in current mode
function Meter:GetSpellBreakdown(playerName, mode, segIdx)
    local segment = self:GetCurrentSegment(segIdx)
    if not segment or not segment.spellData or not segment.spellData[playerName] then return nil end
    
    local fieldMap = {
        [self.MODES.DAMAGE] = "damageSpells",
        [self.MODES.DPS] = "damageSpells",
        [self.MODES.HEALING] = "healingSpells",
        [self.MODES.HPS] = "healingSpells",
        [self.MODES.ABSORBS] = "absorbSpells",
        [self.MODES.INTERRUPTS] = "interruptSpells",
        [self.MODES.DISPELS] = "dispelSpells",
    }
    
    local field = fieldMap[mode]
    return field and segment.spellData[playerName][field] or nil
end

-- ==================== LEGACY FALLBACK ====================
function Meter:CollectFinalData()
    if not self.currentSegment then return end
    
    self.currentSegment.totalDamage = 0
    self.currentSegment.totalHealing = 0
    self.currentSegment.totalInterrupts = 0
    self.currentSegment.totalDamageTaken = 0
    self.currentSegment.totalAbsorbs = 0
    self.currentSegment.totalDispels = 0
    
    local sessionType = Enum.DamageMeterSessionType.Current
    
    -- Collect all types using sessionType fallback
    local typeMap = {
        {st = sessionType, dt = Enum.DamageMeterType.DamageDone, f = "damage", ps = "dps", tf = "totalDamage"},
        {st = sessionType, dt = Enum.DamageMeterType.HealingDone, f = "healing", ps = "hps", tf = "totalHealing"},
        {st = sessionType, dt = Enum.DamageMeterType.DamageTaken, f = "damageTaken", ps = nil, tf = "totalDamageTaken"},
        {st = sessionType, dt = Enum.DamageMeterType.Interrupts, f = "interrupts", ps = nil, tf = "totalInterrupts"},
    }
    if Enum.DamageMeterType.Absorbs then
        table.insert(typeMap, {st = sessionType, dt = Enum.DamageMeterType.Absorbs, f = "absorbs", ps = nil, tf = "totalAbsorbs"})
    end
    if Enum.DamageMeterType.Dispels then
        table.insert(typeMap, {st = sessionType, dt = Enum.DamageMeterType.Dispels, f = "dispels", ps = nil, tf = "totalDispels"})
    end
    
    for _, info in ipairs(typeMap) do
        local session = C_DamageMeter.GetCombatSessionFromType(info.st, info.dt)
        if session and session.combatSources then
            for _, source in ipairs(session.combatSources) do
                if source.classFilename then
                    local name = GetSourceName(source)
                    if name then
                        local p = self:GetOrCreatePlayer(self.currentSegment, name, GetSourceClass(source))
                        if p then
                            local amount = SafeRead(source.totalAmount)
                            if amount then
                                p[info.f] = amount
                                self.currentSegment[info.tf] = self.currentSegment[info.tf] + amount
                            end
                            if info.ps then
                                local perSec = SafeRead(source.amountPerSecond)
                                if perSec then p[info.ps] = perSec end
                            end
                        end
                    end
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
    self:UpdateRestrictionState()
    
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

-- CLEU Processing - Only for WoW 11.x (pre-Midnight)
function Meter:ProcessCombatLogEvent(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    if IS_MIDNIGHT then return end
    if not self.enabled then return end
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
        if subevent:match("DAMAGE") or subevent:match("HEAL") or subevent == "SPELL_INTERRUPT" then self:StartCombat() end
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

-- ==================== SEGMENT MANAGEMENT ====================
function Meter:GetSegmentList()
    local list = {
        {index = 0, name = "Current Segment", segment = self.currentSegment},
        {index = -1, name = "Overall Data", segment = self:GetOverallData()},
    }
    for i, seg in ipairs(self.segments) do
        local name = (seg.name or ("Segment #" .. i))
        if seg.timestamp then name = name .. " (" .. seg.timestamp .. ")" end
        table.insert(list, {index = i, name = name, segment = seg})
    end
    
    -- Show available Blizzard sessions not yet imported or dismissed
    if IS_MIDNIGHT and C_DamageMeter then
        local sessions = self:GetAvailableSessions()
        for _, blzSession in ipairs(sessions) do
            if not self.storedSessionIds[blzSession.sessionID] and not self.dismissedSessionIds[blzSession.sessionID] then
                table.insert(list, {
                    index = 1000 + blzSession.sessionID,
                    name = (blzSession.name or "Session") .. " #" .. blzSession.sessionID .. " (Blz)",
                    sessionId = blzSession.sessionID,
                })
            end
        end
    end
    
    return list
end

function Meter:SetViewingSegment(index)
    self.viewingSegmentIndex = index
    if index >= 1000 and IS_MIDNIGHT then
        self:LoadBlizzardSession(index - 1000)
    end
    self:RefreshAllWindows()
end

function Meter:LoadBlizzardSession(sessionId)
    if not C_DamageMeter then return end
    
    local segment = CreateSegment("Session #" .. sessionId)
    segment.sessionId = sessionId
    segment.startTime = 0
    
    local savedSegment = self.currentSegment
    self.currentSegment = segment
    
    self:CollectTypeData(sessionId, Enum.DamageMeterType.DamageDone, "damage", "dps", "totalDamage")
    self:CollectTypeData(sessionId, Enum.DamageMeterType.HealingDone, "healing", "hps", "totalHealing")
    self:CollectTypeData(sessionId, Enum.DamageMeterType.DamageTaken, "damageTaken", nil, "totalDamageTaken")
    self:CollectTypeData(sessionId, Enum.DamageMeterType.Interrupts, "interrupts", nil, "totalInterrupts")
    if Enum.DamageMeterType.Absorbs then
        self:CollectTypeData(sessionId, Enum.DamageMeterType.Absorbs, "absorbs", nil, "totalAbsorbs")
    end
    if Enum.DamageMeterType.Dispels then
        self:CollectTypeData(sessionId, Enum.DamageMeterType.Dispels, "dispels", nil, "totalDispels")
    end
    self:CollectSpellBreakdowns(sessionId)
    
    table.insert(self.segments, 1, segment)
    self.storedSessionIds[sessionId] = true
    self.currentSegment = savedSegment
    self.viewingSegmentIndex = 1
end

function Meter:GetSegmentName(segIdx)
    local idx = segIdx or self.viewingSegmentIndex
    if idx == 0 then return "Current"
    elseif idx == -1 then return "Overall"
    else return self.segments[idx] and self.segments[idx].name or ("Segment " .. idx) end
end

function Meter:GetCurrentSegment(segIdx)
    local idx = segIdx or self.viewingSegmentIndex
    if idx == 0 then return self.currentSegment
    elseif idx == -1 then return self:GetOverallData()
    else return self.segments[idx] end
end

function Meter:GetOverallData()
    local overall = CreateSegment("Overall")
    overall.startTime = 0
    local playerTotals, totalDuration = {}, 0
    
    if self.currentSegment and (self.currentSegment.totalDamage > 0 or self.currentSegment.totalHealing > 0) then
        local seg = self.currentSegment
        local duration = seg.duration > 0 and seg.duration or (seg.startTime > 0 and (GetTime() - seg.startTime) or 0)
        totalDuration = totalDuration + duration
        for name, player in pairs(seg.players) do
            if not playerTotals[name] then playerTotals[name] = CreatePlayerData(name, player.class) end
            local p = playerTotals[name]
            p.damage = p.damage + player.damage
            p.healing = p.healing + player.healing
            p.damageTaken = p.damageTaken + player.damageTaken
            p.interrupts = p.interrupts + player.interrupts
            p.deaths = p.deaths + player.deaths
            p.absorbs = p.absorbs + (player.absorbs or 0)
            p.dispels = p.dispels + (player.dispels or 0)
        end
        overall.totalDamage = overall.totalDamage + seg.totalDamage
        overall.totalHealing = overall.totalHealing + seg.totalHealing
        overall.totalInterrupts = overall.totalInterrupts + seg.totalInterrupts
        overall.totalAbsorbs = overall.totalAbsorbs + (seg.totalAbsorbs or 0)
        overall.totalDispels = overall.totalDispels + (seg.totalDispels or 0)
    end
    
    for _, seg in ipairs(self.segments) do
        totalDuration = totalDuration + (seg.duration or 0)
        for name, player in pairs(seg.players) do
            if not playerTotals[name] then playerTotals[name] = CreatePlayerData(name, player.class) end
            local p = playerTotals[name]
            p.damage = p.damage + player.damage
            p.healing = p.healing + player.healing
            p.damageTaken = p.damageTaken + player.damageTaken
            p.interrupts = p.interrupts + player.interrupts
            p.deaths = p.deaths + player.deaths
            p.absorbs = p.absorbs + (player.absorbs or 0)
            p.dispels = p.dispels + (player.dispels or 0)
        end
        overall.totalDamage = overall.totalDamage + seg.totalDamage
        overall.totalHealing = overall.totalHealing + seg.totalHealing
        overall.totalInterrupts = overall.totalInterrupts + seg.totalInterrupts
        overall.totalAbsorbs = overall.totalAbsorbs + (seg.totalAbsorbs or 0)
        overall.totalDispels = overall.totalDispels + (seg.totalDispels or 0)
    end
    
    if totalDuration > 0 then
        for _, p in pairs(playerTotals) do
            p.dps = p.damage / totalDuration
            p.hps = p.healing / totalDuration
        end
    end
    overall.players, overall.duration = playerTotals, totalDuration
    return overall
end

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
        elseif mode == self.MODES.DAMAGE_TAKEN then value = player.damageTaken
        elseif mode == self.MODES.ABSORBS then value = player.absorbs or 0
        elseif mode == self.MODES.DISPELS then value = player.dispels or 0
        end
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
        if (segment.totalDamageTaken or 0) > 0 then return segment.totalDamageTaken end
        local t = 0; for _, p in pairs(segment.players) do t = t + p.damageTaken end; return t
    elseif mode == self.MODES.ABSORBS then return segment.totalAbsorbs or 0
    elseif mode == self.MODES.DISPELS then return segment.totalDispels or 0
    end
    return 0
end

-- ==================== INITIALIZATION ====================
function Meter:Initialize()
    if self.initialized then return end
    self.initialized = true
    self.eventFrame = KDT.CombatLogFrame
    if KDT.DB and KDT.DB.meter then self.enabled = KDT.DB.meter.enabled ~= false end
    if KDT.DB and KDT.DB.meter and KDT.DB.meter.showSelfTop ~= nil then
        self.defaults.showSelfTop = KDT.DB.meter.showSelfTop
    end
    if KDT.DB and KDT.DB.meter and KDT.DB.meter.clearOnEnter ~= nil then
        self.defaults.clearOnEnter = KDT.DB.meter.clearOnEnter
    end
    if KDT.DB and KDT.DB.meter and KDT.DB.meter.showRank ~= nil then
        self.defaults.showRank = KDT.DB.meter.showRank
    end
    if KDT.DB and KDT.DB.meter and KDT.DB.meter.showPercent ~= nil then
        self.defaults.showPercent = KDT.DB.meter.showPercent
    end
    if KDT.DB and KDT.DB.meter and KDT.DB.meter.classColors ~= nil then
        self.defaults.classColors = KDT.DB.meter.classColors
    end
    
    self.updateTicker = C_Timer.NewTicker(0.1, function()
        if self.enabled then
            if IS_MIDNIGHT then self:UpdateCombatState()
            elseif self.inCombat and not UnitAffectingCombat("player") then self:EndCombat() end
            self:RefreshAllWindows()
        end
    end)
    
    C_Timer.After(1, function()
        if KDT.DB and KDT.DB.meter then
            local openWindows = KDT.DB.meter.openWindows
            if openWindows and #openWindows > 0 then
                for _, windowData in ipairs(openWindows) do
                    local id = windowData.id or 1
                    if not self.windows[id] then self:CreateWindow(id) end
                    if self.windows[id] then
                        if windowData.mode then self.windows[id].mode = windowData.mode end
                        self.windows[id].frame:Show()
                        self.windows[id]:Refresh()
                    end
                end
            elseif KDT.DB.meter.windowVisible then
                if not self.windows[1] then self:CreateWindow(1) end
                if self.windows[1] then self.windows[1].frame:Show(); self.windows[1]:Refresh() end
            end
        end
    end)
end

function Meter:SaveOpenWindows()
    if not KDT.DB then return end
    KDT.DB.meter = KDT.DB.meter or {}
    local openWindows = {}
    for id, window in pairs(self.windows) do
        if window.frame and window.frame:IsShown() then
            table.insert(openWindows, { id = id, mode = window.mode })
        end
    end
    KDT.DB.meter.openWindows = openWindows
    KDT.DB.meter.windowVisible = #openWindows > 0
end

function Meter:SaveAllPositions()
    for _, window in pairs(self.windows) do
        if window.frame and window.frame:IsShown() then
            window:SavePosition()
        end
    end
    self:SaveOpenWindows()
end

-- Save all positions on logout/reload
do
    local logoutFrame = CreateFrame("Frame")
    logoutFrame:RegisterEvent("PLAYER_LOGOUT")
    logoutFrame:SetScript("OnEvent", function()
        Meter:SaveAllPositions()
    end)
end

function Meter:ClearCurrent()
    -- Clear only the current segment
    self.currentSegment = nil
    self.inCombat = false
    self.combatStartTime = nil
    self.viewingSegmentIndex = 0
    self:RefreshAllWindows()
end

function Meter:ResetAll()
    -- Clear everything: current combat, all segments, session tracking
    self.currentSegment = nil
    self.inCombat = false
    self.combatStartTime = nil
    self.viewingSegmentIndex = 0
    self.currentSessionId = nil
    wipe(self.segments)
    wipe(self.sessionMap)
    self.overallData = nil
    self.processCount = 0
    -- Dismiss all currently known Blizzard sessions so they don't reappear
    if IS_MIDNIGHT and C_DamageMeter then
        local sessions = self:GetAvailableSessions()
        for _, blzSession in ipairs(sessions) do
            self.dismissedSessionIds[blzSession.sessionID] = true
        end
    end
    -- Also mark storedSessionIds as dismissed before wiping
    for sid, _ in pairs(self.storedSessionIds) do
        self.dismissedSessionIds[sid] = true
    end
    wipe(self.storedSessionIds)
    -- Reset per-window segment indices
    for _, w in pairs(self.windows) do
        if w.viewingSegmentIndex then
            w.viewingSegmentIndex = 0
        end
    end
    self:RefreshAllWindows()
end

-- Legacy alias
function Meter:Reset() self:ClearCurrent() end
function Meter:RefreshAllWindows() for _, w in pairs(self.windows) do if w.Refresh then w:Refresh() end end end

function Meter:SetEnabled(enabled)
    self.enabled = enabled
    if enabled then
        self:UpdateCombatState()
        self:RefreshAllWindows()
        KDT:Print("Damage Meter |cFF00FF00enabled|r.")
    else
        KDT:Print("Damage Meter |cFFFF0000disabled|r.")
    end
    if KDT.DB and KDT.DB.meter then KDT.DB.meter.enabled = enabled end
end

-- ==================== BLIZZARD DAMAGEMETER OVERLAY (WoW 12.0) ====================
function Meter:EnableBlizzardDamageMeter()
    if not IS_MIDNIGHT then return false end
    local isDMEnabled = C_CVar and C_CVar.GetCVarBool("damageMeterEnabled")
    if not isDMEnabled and C_CVar then
        C_CVar.SetCVar("damageMeterEnabled", "1")
    end
    if DamageMeter and DamageMeter.Show then DamageMeter:Show() end
    return true
end

-- Possess a Blizzard DamageMeter window onto KDT bar container
function Meter:PossessBlizzardWindow(windowId, kryosBarContainer)
    if not IS_MIDNIGHT or not DamageMeter then return nil end
    
    local blzWindow = nil
    local usedWindows = {}
    
    -- Collect already-used windows
    for _, info in pairs(self.blzWindows) do
        if info.window then usedWindows[info.window] = true end
    end
    
    if DamageMeter.ForEachSessionWindow then
        DamageMeter:ForEachSessionWindow(function(thisWindow)
            if not blzWindow and thisWindow and not usedWindows[thisWindow] then
                usedWindows[thisWindow] = true
                blzWindow = thisWindow
            end
        end)
    end
    
    if not blzWindow and DamageMeter.ShowNewSessionWindow then
        DamageMeter:ShowNewSessionWindow()
        if DamageMeter.ForEachSessionWindow then
            DamageMeter:ForEachSessionWindow(function(thisWindow)
                if not blzWindow and thisWindow and not usedWindows[thisWindow] then
                    usedWindows[thisWindow] = true
                    blzWindow = thisWindow
                end
            end)
        end
    end
    
    if blzWindow and kryosBarContainer then
        local anchor1, refFrame, anchor2, x, y = blzWindow:GetPoint(1)
        
        local scrollBox = blzWindow.ScrollBox
        if scrollBox then
            scrollBox:ClearAllPoints()
            scrollBox:SetPoint("TOPLEFT", kryosBarContainer, "TOPLEFT", 0, 0)
            scrollBox:SetPoint("BOTTOMRIGHT", kryosBarContainer, "BOTTOMRIGHT", 0, 0)
        end
        
        blzWindow:ClearAllPoints()
        blzWindow:SetPoint("TOPLEFT", kryosBarContainer, "TOPLEFT", 0, 0)
        blzWindow:SetPoint("BOTTOMRIGHT", kryosBarContainer, "BOTTOMRIGHT", 0, 0)
        
        -- Hide all Blizzard UI elements except ScrollBox
        for k, v in pairs(blzWindow) do
            if k ~= "ScrollBox" and type(v) == "table" and v.Hide then
                v:Hide()
            end
        end
        
        self.blzWindows[windowId] = {
            window = blzWindow,
            originalPos = {anchor1, refFrame and refFrame:GetName() or "UIParent", anchor2, x, y},
        }
        
        return blzWindow
    end
    return nil
end

function Meter:ReleaseBlizzardWindow(windowId)
    local info = self.blzWindows[windowId]
    if not info then return end
    local blzWindow, pos = info.window, info.originalPos
    if blzWindow and pos then
        local refFrame = _G[pos[2]] or UIParent
        blzWindow:ClearAllPoints()
        blzWindow:SetPoint(pos[1], refFrame, pos[3], pos[4], pos[5])
    end
    self.blzWindows[windowId] = nil
end

function Meter:SetBlizzardWindowType(windowId, mode)
    local info = self.blzWindows[windowId]
    if not info or not info.window then return end
    local blzType = self.MODE_TO_BLIZZARD[mode]
    if blzType and info.window.SetDamageMeterType then
        info.window:SetDamageMeterType(blzType)
    end
end

function Meter:SetBlizzardWindowSession(windowId, sessionType, sessionId)
    local info = self.blzWindows[windowId]
    if not info or not info.window then return end
    if info.window.SetSession then
        info.window:SetSession(sessionType, sessionId or 0)
    end
end

-- Register DAMAGE_METER events at file load time for WoW 12.0+
if IS_MIDNIGHT then
    local dmEventFrame = CreateFrame("Frame")
    dmEventFrame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
    dmEventFrame:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
    pcall(function() dmEventFrame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_ENDED") end)
    pcall(function() dmEventFrame:RegisterEvent("DAMAGE_METER_SESSION_ADDED") end)
    
    dmEventFrame:SetScript("OnEvent", function(_, event, ...)
        if Meter.enabled then
            if event == "DAMAGE_METER_COMBAT_SESSION_ENDED" then
                local sessionId = ...
                if sessionId and Meter.currentSegment then
                    Meter.currentSegment.sessionId = sessionId
                end
            end
            Meter:UpdateCombatState()
            Meter:RefreshAllWindows()
        end
    end)
end

-- Clear on Instance Enter feature
do
    local instanceFrame = CreateFrame("Frame")
    instanceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    local lastInstanceID = nil
    
    instanceFrame:SetScript("OnEvent", function(_, event, isInitialLogin, isReloadingUi)
        if not Meter.enabled or not Meter.defaults.clearOnEnter then return end
        -- Skip initial login and UI reloads
        if isInitialLogin or isReloadingUi then
            local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
            lastInstanceID = instanceID
            return
        end
        
        local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
        -- Only trigger for dungeons (party) and raids
        if instanceType == "party" or instanceType == "raid" then
            -- Only clear if it's a different instance than last time
            if instanceID ~= lastInstanceID then
                Meter:ResetAll()
                KDT:Print("Meter data cleared (new instance entered)")
            end
        end
        lastInstanceID = instanceID
    end)
end
