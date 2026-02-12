-- Kryos Dungeon Tool
-- Modules/Tooltip.lua - Tooltip Enhancements

local _, KDT = ...

local function GetQoL() return KDT.DB and KDT.DB.qol end
local function isSecret(v) return issecretvalue and issecretvalue(v) end
local function safeFind(t, p) if not t or isSecret(t) then return nil end return t:find(p, 1, true) end

---------------------------------------------------------------------------
-- TOOLTIP SCALE
---------------------------------------------------------------------------
local SCALE_TARGETS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "EmbeddedItemTooltip" }

function KDT:ApplyTooltipScale()
    local qol = GetQoL()
    local scale = (qol and qol.tooltipScale) or 1
    for _, name in ipairs(SCALE_TARGETS) do
        local tt = _G[name]
        if tt and tt.SetScale then tt:SetScale(scale) end
    end
end

---------------------------------------------------------------------------
-- TOOLTIP DATA PROCESSOR (WoW 12.0 API)
---------------------------------------------------------------------------
-- Kind map: TooltipDataProcessor type IDs -> kind strings
local KIND_MAP = {}
if Enum and Enum.TooltipDataType then
    local T = Enum.TooltipDataType
    if T.Spell then KIND_MAP[T.Spell] = "spell" end
    if T.Item then KIND_MAP[T.Item] = "item" end
    if T.Unit then KIND_MAP[T.Unit] = "unit" end
    if T.Macro then KIND_MAP[T.Macro] = "macro" end
    if T.Currency then KIND_MAP[T.Currency] = "currency" end
    if T.UnitAura then KIND_MAP[T.UnitAura] = "aura" end
end

---------------------------------------------------------------------------
-- INSPECT CACHE (for Spec + Item Level on other players)
---------------------------------------------------------------------------
local inspectCache = {}  -- [guid] = { spec, specIcon, ilvl, time }
local INSPECT_CACHE_TTL = 30  -- seconds
local lastInspectTime = 0
local pendingInspectUnit = nil  -- store the unit we called NotifyInspect on
local INSPECT_THROTTLE = 1.5  -- seconds between inspects

local inspectFrame = CreateFrame("Frame")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(_, event, inspecteeGUID)
    if event ~= "INSPECT_READY" then return end
    -- Delay slightly - inspect data not always ready immediately
    C_Timer.After(0.2, function()
        if not inspecteeGUID then return end
        
        -- Try to find the unit matching this GUID
        local unit = nil
        -- Check mouseover first
        local mOK, mExists = pcall(UnitExists, "mouseover")
        if mOK and mExists then
            local mGUID = UnitGUID("mouseover")
            if mGUID and not isSecret(mGUID) and mGUID == inspecteeGUID then
                unit = "mouseover"
            end
        end
        -- Check target
        if not unit then
            local tOK, tExists = pcall(UnitExists, "target")
            if tOK and tExists then
                local tGUID = UnitGUID("target")
                if tGUID and not isSecret(tGUID) and tGUID == inspecteeGUID then
                    unit = "target"
                end
            end
        end
        -- Check party/raid members
        if not unit then
            for i = 1, 4 do
                local pUnit = "party" .. i
                local pOK, pExists = pcall(UnitExists, pUnit)
                if pOK and pExists then
                    local pGUID = UnitGUID(pUnit)
                    if pGUID and not isSecret(pGUID) and pGUID == inspecteeGUID then
                        unit = pUnit
                        break
                    end
                end
            end
        end
        
        local entry = {}
        
        -- Spec (needs a unit token)
        if unit and GetInspectSpecialization then
            local ok, specID = pcall(GetInspectSpecialization, unit)
            if ok and specID and specID > 0 then
                local sok, _, specName, _, specIcon = pcall(GetSpecializationInfoByID, specID)
                if sok and specName then
                    entry.spec = specName
                    entry.specIcon = specIcon
                end
            end
        end
        
        -- Item Level (WoW 12.0: no unit argument)
        if C_PaperDollInfo then
            local ilvlFunc = C_PaperDollInfo.GetInspectItemLevel
            if ilvlFunc then
                local ok, ilvl = pcall(ilvlFunc)
                if ok and ilvl and not isSecret(ilvl) and ilvl > 0 then
                    entry.ilvl = ilvl
                end
            end
            -- Fallback: try with unit arg (older API)
            if not entry.ilvl and unit and C_PaperDollInfo.GetInspectItemLevel then
                local ok2, ilvl2 = pcall(C_PaperDollInfo.GetInspectItemLevel, unit)
                if ok2 and ilvl2 and not isSecret(ilvl2) and ilvl2 > 0 then
                    entry.ilvl = ilvl2
                end
            end
        end
        
        if entry.spec or entry.ilvl then
            entry.time = GetTime()
            inspectCache[inspecteeGUID] = entry
            -- Refresh tooltip if still hovering
            if GameTooltip:IsShown() then
                GameTooltip:Show()
            end
        end
        
        ClearInspectPlayer()
    end)
end)

local function RequestInspect(unit)
    local ok, canInspect = pcall(CanInspect, unit)
    if not ok or not canInspect then return end
    local guid = UnitGUID(unit)
    if not guid or isSecret(guid) then return end
    local now = GetTime()
    -- Check cache
    local cached = inspectCache[guid]
    if cached and (now - cached.time) < INSPECT_CACHE_TTL then return end
    -- Throttle
    if (now - lastInspectTime) < INSPECT_THROTTLE then return end
    lastInspectTime = now
    pendingInspectUnit = unit
    NotifyInspect(unit)
end

local function GetInspectData(unit)
    local guid = UnitGUID(unit)
    if not guid or isSecret(guid) then return nil end
    local cached = inspectCache[guid]
    if cached and (GetTime() - cached.time) < INSPECT_CACHE_TTL then
        return cached
    end
    return nil
end

-- Self spec + ilvl (no inspect needed)
local function GetSelfSpec()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local _, name, _, icon = GetSpecializationInfo(specIndex)
        return name, icon
    end
    return nil, nil
end

local function GetSelfItemLevel()
    local _, ilvl = GetAverageItemLevel()
    if ilvl and ilvl > 0 then return ilvl end
    return nil
end

local function GetNPCIDFromGUID(guid)
    if not guid or isSecret(guid) then return nil end
    local _, _, _, _, _, npcID = strsplit("-", guid)
    return tonumber(npcID)
end

local function FormatUnitName(unit)
    if not unit or isSecret(unit) then return nil end
    local ok, exists = pcall(UnitExists, unit)
    if not ok or not exists then return nil end
    local name = UnitName(unit)
    if not name or isSecret(name) then return nil end
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local r, g, b = GetClassColor(class)
            return string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, name)
        end
    end
    return name
end

---------------------------------------------------------------------------
-- SPELL / ITEM / UNIT HANDLERS
---------------------------------------------------------------------------
local function handleSpell(tooltip, id)
    local qol = GetQoL()
    if not qol then return end
    
    if qol.tooltipShowSpellID and id then
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine("Spell ID", tostring(id), 0.5, 0.5, 1, 1, 1, 1)
    end
    
    -- Inline spell icon
    if qol.tooltipShowSpellIcon and id then
        local spellInfo = C_Spell and C_Spell.GetSpellInfo(id)
        if spellInfo and spellInfo.iconID then
            local line = _G[tooltip:GetName() .. "TextLeft1"]
            if line then
                local current = line:GetText()
                if current and not isSecret(current) and not safeFind(current, "|T") then
                    local tex = string.format("|T%d:16:16:0:0|t ", spellInfo.iconID)
                    line:SetText(tex .. current)
                end
            end
        end
    end
end

local function handleItem(tooltip, id, guid)
    local qol = GetQoL()
    if not qol then return end
    
    if qol.tooltipShowItemID and id then
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine("Item ID", tostring(id), 0.5, 0.5, 1, 1, 1, 1)
    end
    
    -- Inline item icon
    if qol.tooltipShowItemIcon and id then
        local icon = select(5, GetItemInfoInstant(id))
        local line = _G[tooltip:GetName() .. "TextLeft1"]
        if line and icon then
            local current = line:GetText()
            if current and not isSecret(current) and not safeFind(current, "|T") then
                local tex = string.format("|T%d:16:16:0:0|t ", icon)
                line:SetText(tex .. current)
            end
        end
    end
end

local function handleUnit(tooltip)
    local qol = GetQoL()
    if not qol then return end
    
    -- Resolve unit token (may be secret in WoW 12.0 secure tooltip context)
    local unit
    if tooltip.GetUnit then
        _, unit = tooltip:GetUnit()
    end
    -- Guard: unit token itself can be a secret value in WoW 12.0
    if isSecret(unit) then return end
    if not unit then unit = "mouseover" end
    
    -- pcall wrapper for all unit API calls (secret value protection)
    local unitOK, unitExists = pcall(UnitExists, unit)
    if not unitOK or not unitExists then return end
    
    -- Hide health bar
    if qol.tooltipHideHealthBar then
        if tooltip.StatusBar then tooltip.StatusBar:Hide() end
        local sb = _G[tooltip:GetName() .. "StatusBar"]
        if sb then sb:Hide() end
    end
    
    -- NPC ID (non-player units only)
    if qol.tooltipShowNPCID and not UnitPlayerControlled(unit) then
        local guid = UnitGUID(unit)
        local npcID = GetNPCIDFromGUID(guid)
        if npcID then
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine("NPC ID", tostring(npcID), 0.5, 0.5, 1, 1, 1, 1)
        end
        return
    end
    
    -- Player-specific enhancements
    if UnitIsPlayer(unit) then
        -- Class-colored name
        if qol.tooltipClassColors then
            local _, class = UnitClass(unit)
            if class then
                local r, g, b = GetClassColor(class)
                local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
                if nameLine then nameLine:SetTextColor(r, g, b) end
            end
        end
        
        -- Hide faction line
        if qol.tooltipHideFaction then
            local factionName = select(2, UnitFactionGroup(unit))
            if factionName then
                for i = 1, tooltip:NumLines() do
                    local line = _G[tooltip:GetName() .. "TextLeft" .. i]
                    local text = line and line:GetText()
                    if text and not isSecret(text) and text == factionName then
                        line:SetText("")
                        line:Hide()
                        break
                    end
                end
            end
        end
        
        -- Hide PvP line
        if qol.tooltipHidePvP then
            local pvpText = PVP or "PvP"
            for i = 1, tooltip:NumLines() do
                local line = _G[tooltip:GetName() .. "TextLeft" .. i]
                local text = line and line:GetText()
                if text and not isSecret(text) and text == pvpText then
                    line:SetText("")
                    line:Hide()
                    break
                end
            end
        end
        
        -- Guild rank
        if qol.tooltipShowGuildRank then
            local guildName, guildRank = GetGuildInfo(unit)
            if guildName and guildRank then
                for i = 1, tooltip:NumLines() do
                    local line = _G[tooltip:GetName() .. "TextLeft" .. i]
                    local text = line and line:GetText()
                    if text and safeFind(text, guildName) and not safeFind(text, guildRank) then
                        line:SetText(text .. " - |cffaaaaaa" .. guildRank .. "|r")
                        break
                    end
                end
            end
        end
        
        -- Color guild name
        if qol.tooltipColorGuildName then
            local guildName = GetGuildInfo(unit)
            if guildName then
                for i = 1, tooltip:NumLines() do
                    local line = _G[tooltip:GetName() .. "TextLeft" .. i]
                    local text = line and line:GetText()
                    if text and not isSecret(text) and safeFind(text, guildName) then
                        line:SetTextColor(0.25, 0.78, 0.92)
                        break
                    end
                end
            end
        end
        
        -- Target of Target
        if qol.tooltipShowTargetOfTarget then
            local targetUnit = unit .. "target"
            local tokOK, texists = pcall(UnitExists, targetUnit)
            if tokOK and texists then
                local targetName = FormatUnitName(targetUnit)
                if targetName then
                    tooltip:AddDoubleLine("|cffffd200Targeting|r", targetName)
                end
            end
        end
        
        -- M+ Score
        if qol.tooltipShowMythicScore and C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
            local rating = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
            if rating and rating.currentSeasonScore and rating.currentSeasonScore > 0 then
                local r, g, b = 1, 1, 1
                if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
                    r, g, b = C_ChallengeMode.GetDungeonScoreRarityColor(rating.currentSeasonScore):GetRGB()
                end
                tooltip:AddLine(" ")
                tooltip:AddDoubleLine(DUNGEON_SCORE or "M+ Score", tostring(rating.currentSeasonScore), 1, 1, 0, r, g, b)
                
                -- Best dungeon
                if rating.runs then
                    local best
                    for _, run in pairs(rating.runs) do
                        if not best or run.mapScore > best.mapScore then best = run end
                    end
                    if best and best.mapScore > 0 and best.bestRunLevel > 0 then
                        local mapName = "?"
                        if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                            mapName = C_ChallengeMode.GetMapUIInfo(best.challengeModeID) or mapName
                        end
                        local prefix = best.finishedSuccess and "+" or ""
                        tooltip:AddDoubleLine("|cffffd200Best Run|r", prefix .. best.bestRunLevel .. " " .. mapName, 1, 1, 0, 1, 1, 1)
                    end
                end
            end
        end
        
        -- Mount info
        if qol.tooltipShowMount then
            local mountName, mountIcon
            if C_UnitAuras and C_UnitAuras.GetUnitAuras and C_MountJournal and C_MountJournal.GetMountFromSpell then
                local auras = C_UnitAuras.GetUnitAuras(unit, "HELPFUL")
                if type(auras) == "table" then
                    for _, aura in ipairs(auras) do
                        local spellID = aura and aura.spellId
                        if spellID and not isSecret(spellID) then
                            local mountID = C_MountJournal.GetMountFromSpell(spellID)
                            if mountID then
                                local name, _, icon = C_MountJournal.GetMountInfoByID(mountID)
                                mountName = name
                                mountIcon = icon
                                break
                            end
                        end
                    end
                end
            end
            if mountName then
                local display = mountName
                if mountIcon then display = string.format("|T%d:16:16:0:0|t %s", mountIcon, mountName) end
                tooltip:AddDoubleLine("|cffffd200Mount|r", display)
            end
        end
        
        -- Specialization
        if qol.tooltipShowSpec then
            local isSelf = UnitIsUnit(unit, "player")
            if isSelf then
                local specName, specIcon = GetSelfSpec()
                if specName then
                    local display = specName
                    if specIcon then display = string.format("|T%d:16:16:0:0|t %s", specIcon, specName) end
                    tooltip:AddDoubleLine("|cffffd200Spec|r", display)
                end
            else
                local data = GetInspectData(unit)
                if data and data.spec then
                    local display = data.spec
                    if data.specIcon then display = string.format("|T%d:16:16:0:0|t %s", data.specIcon, data.spec) end
                    tooltip:AddDoubleLine("|cffffd200Spec|r", display)
                end
                RequestInspect(unit)
            end
        end
        
        -- Item Level
        if qol.tooltipShowItemLevel then
            local isSelf = UnitIsUnit(unit, "player")
            if isSelf then
                local ilvl = GetSelfItemLevel()
                if ilvl then
                    tooltip:AddDoubleLine("|cffffd200Item Level|r", string.format("%.1f", ilvl), 1, 1, 0, 1, 1, 1)
                end
            else
                local data = GetInspectData(unit)
                if data and data.ilvl then
                    tooltip:AddDoubleLine("|cffffd200Item Level|r", string.format("%.1f", data.ilvl), 1, 1, 0, 1, 1, 1)
                end
                RequestInspect(unit)
            end
        end
    end
end

local function handleCurrency(tooltip, id)
    local qol = GetQoL()
    if not qol or not qol.tooltipShowCurrencyID or not id then return end
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("Currency ID", tostring(id), 0.5, 0.5, 1, 1, 1, 1)
end

---------------------------------------------------------------------------
-- REGISTRATION
---------------------------------------------------------------------------
local tooltipInitialized = false

function KDT:InitTooltip()
    if tooltipInitialized then return end
    tooltipInitialized = true
    
    -- Apply scale
    C_Timer.After(0, function() KDT:ApplyTooltipScale() end)
    
    -- Hide tooltip in combat
    GameTooltip:HookScript("OnShow", function(self)
        local qol = GetQoL()
        if qol and qol.tooltipHideInCombat and InCombatLockdown() then
            self:Hide()
        end
    end)
    
    -- Anchor override: follow cursor with adjustable offset
    local tooltipTracker = CreateFrame("Frame")
    tooltipTracker:Hide()
    tooltipTracker:SetScript("OnUpdate", function()
        if not GameTooltip:IsShown() then
            tooltipTracker:Hide()
            return
        end
        local qol = GetQoL()
        if not qol or not qol.tooltipAnchorCursor then
            tooltipTracker:Hide()
            return
        end
        local ox = (qol.tooltipCursorOffsetX or 0)
        local oy = (qol.tooltipCursorOffsetY or 0)
        local scale = GameTooltip:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx / scale + ox, cy / scale + oy)
    end)
    
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tt, parent)
        local qol = GetQoL()
        if not qol or not qol.tooltipAnchorCursor then return end
        if not tt or not parent then return end
        tt:SetOwner(parent, "ANCHOR_NONE")
        -- Immediately position at cursor
        local ox = (qol.tooltipCursorOffsetX or 0)
        local oy = (qol.tooltipCursorOffsetY or 0)
        local scale = tt:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        tt:ClearAllPoints()
        tt:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx / scale + ox, cy / scale + oy)
        -- Start tracking for continuous cursor follow
        tooltipTracker:Show()
    end)
    
    -- Hide right-click instruction
    if GameTooltip_AddInstructionLine then
        hooksecurefunc("GameTooltip_AddInstructionLine", function(tt, text)
            local qol = GetQoL()
            if not qol or not qol.tooltipHideRightClick then return end
            if tt ~= GameTooltip then return end
            if text ~= UNIT_POPUP_RIGHT_CLICK then return end
            local i = tt:NumLines()
            local line = _G[tt:GetName() .. "TextLeft" .. i]
            if line then
                local tmpText = line:GetText()
                if not isSecret(tmpText) and tmpText == text then
                    line:SetText("")
                    line:Hide()
                    tt:Show()
                end
            end
        end)
    end
    
    -- TooltipDataProcessor (WoW 12.0 API)
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
            local qol = GetQoL()
            if not qol then return end
            if not data or not data.type then return end
            
            local kind
            if isSecret(data.type) then
                -- Fallback detection
                if UnitIsEnemy("mouseover", "player") or UnitIsFriend("mouseover", "player") then
                    kind = "unit"
                else
                    kind = "aura"
                end
            else
                kind = KIND_MAP[tonumber(data.type)]
            end
            
            if kind == "spell" or kind == "macro" then
                handleSpell(tooltip, data.id)
            elseif kind == "unit" then
                handleUnit(tooltip)
            elseif kind == "item" then
                handleItem(tooltip, data.id, data.guid)
            elseif kind == "aura" then
                handleSpell(tooltip, data.id)
            elseif kind == "currency" then
                handleCurrency(tooltip, data.id)
            end
        end)
    end
end
