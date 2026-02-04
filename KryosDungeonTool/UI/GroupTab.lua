-- Kryos Dungeon Tool
-- UI/GroupTab.lua - Group Check tab UI with modern panel design
-- Inspired by Raider.IO party view - Version 1.8.17

local addonName, KDT = ...

-- ==================== SEASON 3 DUNGEON DATA ====================
-- TWW Season 3 (Patch 11.2 - Ghosts of K'aresh)
local SEASON_DUNGEONS = {
    { short = "EDA", name = "Eco-Dome", mapID = 542, icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome" },
    { short = "ARAK", name = "Ara-Kara", mapID = 503, icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara" },
    { short = "DB", name = "Dawnbreaker", mapID = 505, icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker" },
    { short = "PSF", name = "Priory", mapID = 499, icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame" },
    { short = "FG", name = "Floodgate", mapID = 525, icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks" },
    { short = "STRT", name = "Streets", mapID = 391, icon = "Interface\\Icons\\Achievement_dungeon_theotherside_dealergexa" },
    { short = "GMBT", name = "Gambit", mapID = 392, icon = "Interface\\Icons\\achievement_dungeon_brokerdungeon" },
    { short = "HOA", name = "Halls", mapID = 378, icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement" },
}

-- Class icon coordinates in Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES
local CLASS_ICON_COORDS = {
    WARRIOR = {0, 0.25, 0, 0.25},
    MAGE = {0.25, 0.5, 0, 0.25},
    ROGUE = {0.5, 0.75, 0, 0.25},
    DRUID = {0.75, 1, 0, 0.25},
    HUNTER = {0, 0.25, 0.25, 0.5},
    SHAMAN = {0.25, 0.5, 0.25, 0.5},
    PRIEST = {0.5, 0.75, 0.25, 0.5},
    WARLOCK = {0.75, 1, 0.25, 0.5},
    PALADIN = {0, 0.25, 0.5, 0.75},
    DEATHKNIGHT = {0.25, 0.5, 0.5, 0.75},
    MONK = {0.5, 0.75, 0.5, 0.75},
    DEMONHUNTER = {0.75, 1, 0.5, 0.75},
    EVOKER = {0, 0.25, 0.75, 1},
}

-- Get RIO color based on score
local function GetRIOColor(score)
    if not score or score == 0 then return 0.5, 0.5, 0.5 end
    if score >= 3500 then return 1, 0.5, 0 end        -- Orange (Legendary)
    if score >= 3000 then return 0.64, 0.21, 0.93 end -- Purple
    if score >= 2500 then return 0.0, 0.44, 0.87 end  -- Blue
    if score >= 2000 then return 0.12, 1, 0 end       -- Green
    if score >= 1500 then return 1, 1, 1 end          -- White
    return 0.62, 0.62, 0.62                            -- Gray
end

-- Get key level color
local function GetKeyLevelColor(level)
    if not level or level == 0 then return 0.4, 0.4, 0.4 end
    if level >= 15 then return 1, 0.5, 0 end        -- Orange
    if level >= 12 then return 0.64, 0.21, 0.93 end -- Purple
    if level >= 10 then return 0.0, 0.44, 0.87 end  -- Blue
    if level >= 7 then return 0.12, 1, 0 end        -- Green
    return 1, 1, 1                                    -- White
end

-- ==================== GROUP TAB ELEMENTS ====================
function KDT:CreateGroupElements(f)
    local e = f.groupElements
    local c = f.content
    
    -- Overview Box (compact version)
    e.box = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.box:SetPoint("TOPLEFT", 10, -5)
    e.box:SetPoint("TOPRIGHT", -10, -5)
    e.box:SetHeight(70)
    e.box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.box:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.box:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    -- Left side: Role icons and utility info
    e.roleText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.roleText:SetPoint("TOPLEFT", 10, -10)
    
    e.utilText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.utilText:SetPoint("TOPLEFT", 10, -30)
    e.utilText:SetPoint("RIGHT", e.box, "CENTER", -20, 0)
    e.utilText:SetJustifyH("LEFT")
    
    e.keyText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.keyText:SetPoint("TOPLEFT", 10, -48)
    e.keyText:SetPoint("RIGHT", e.box, "CENTER", -20, 0)
    e.keyText:SetJustifyH("LEFT")
    
    -- Right side: Buttons (2x2 grid)
    e.readyBtn = self:CreateButton(e.box, "Ready Check", 85, 22)
    e.readyBtn:SetPoint("TOPRIGHT", -95, -10)
    e.readyBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
    e.readyBtn:SetScript("OnClick", function()
        if IsInGroup() then DoReadyCheck() end
    end)
    e.readyBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.55, 0.2, 1) end)
    e.readyBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.45, 0.15, 1) end)
    
    e.postBtn = self:CreateButton(e.box, "Post Chat", 85, 22)
    e.postBtn:SetPoint("TOPRIGHT", -5, -10)
    e.postBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.postBtn:SetScript("OnClick", function() KDT:PostToChat() end)
    e.postBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.45, 0.7, 1) end)
    e.postBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.35, 0.6, 1) end)
    
    e.cdBtn = self:CreateButton(e.box, "Countdown", 85, 22)
    e.cdBtn:SetPoint("TOP", e.readyBtn, "BOTTOM", 0, -5)
    e.cdBtn:SetBackdropColor(0.5, 0.35, 0.1, 1)
    e.cdBtn:SetScript("OnClick", function() KDT:StartCountdown() end)
    e.cdBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.45, 0.15, 1) end)
    e.cdBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.35, 0.1, 1) end)
    
    e.abandonBtn = self:CreateButton(e.box, "Abandon", 85, 22)
    e.abandonBtn:SetPoint("TOP", e.postBtn, "BOTTOM", 0, -5)
    e.abandonBtn:SetBackdropColor(0.6, 0.15, 0.15, 1)
    e.abandonBtn:SetScript("OnClick", function()
        StaticPopupDialogs["KRYOS_ABANDON"] = {
            text = "Are you sure you want to abandon your keystone?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                SlashCmdList["MYTHICPLUS"]("abandon")
                KDT:Print("Keystone abandoned.")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("KRYOS_ABANDON")
    end)
    e.abandonBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.2, 0.2, 1) end)
    e.abandonBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.6, 0.15, 0.15, 1) end)
    
    -- Hidden settings (loaded from DB)
    e.secInput = CreateFrame("EditBox", nil, e.box)
    e.secInput:SetSize(1, 1)
    e.secInput:SetPoint("TOPLEFT", 0, 0)
    e.secInput:SetAutoFocus(false)
    e.secInput:Hide()
    
    e.autoCheck = CreateFrame("CheckButton", nil, e.box)
    e.autoCheck:SetSize(1, 1)
    e.autoCheck:SetPoint("TOPLEFT", 0, 0)
    e.autoCheck:Hide()
    
    -- ==================== PARTY PANEL (New Design) ====================
    e.partyPanel = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.partyPanel:SetPoint("TOPLEFT", e.box, "BOTTOMLEFT", 0, -8)
    e.partyPanel:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -10, 40)
    e.partyPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.partyPanel:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
    e.partyPanel:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    
    -- Party Title with shadow effect
    local titleShadow = e.partyPanel:CreateFontString(nil, "ARTWORK")
    titleShadow:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    titleShadow:SetPoint("TOPLEFT", 17, -14)
    titleShadow:SetText("Party")
    titleShadow:SetTextColor(0, 0, 0, 0.5)
    
    e.partyTitle = e.partyPanel:CreateFontString(nil, "OVERLAY")
    e.partyTitle:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    e.partyTitle:SetPoint("TOPLEFT", 15, -12)
    e.partyTitle:SetText("Party")
    e.partyTitle:SetTextColor(0.9, 0.9, 0.9)
    
    -- Dungeon Icons Header
    e.dungeonHeader = CreateFrame("Frame", nil, e.partyPanel)
    e.dungeonHeader:SetPoint("TOPLEFT", 180, -5)
    e.dungeonHeader:SetPoint("TOPRIGHT", -10, -5)
    e.dungeonHeader:SetHeight(50)
    
    e.dungeonIcons = {}
    local numDungeons = #SEASON_DUNGEONS
    
    for i, dungeon in ipairs(SEASON_DUNGEONS) do
        local iconFrame = CreateFrame("Frame", nil, e.dungeonHeader)
        iconFrame:SetSize(48, 48)
        -- Distribute evenly across header
        iconFrame:SetPoint("LEFT", e.dungeonHeader, "LEFT", (i-1) * 52, 0)
        
        -- Icon background (dark circle)
        local iconBg = iconFrame:CreateTexture(nil, "BACKGROUND")
        iconBg:SetSize(36, 36)
        iconBg:SetPoint("TOP", 0, -2)
        iconBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        iconBg:SetVertexColor(0.1, 0.1, 0.12, 1)
        
        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
        icon:SetTexture(dungeon.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        local label = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", iconBg, "BOTTOM", 0, -1)
        label:SetText(dungeon.short)
        label:SetTextColor(0.6, 0.6, 0.6)
        
        -- Tooltip
        iconFrame:EnableMouse(true)
        iconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(dungeon.name, 1, 0.82, 0)
            GameTooltip:Show()
            icon:SetVertexColor(1.2, 1.2, 1.2)
        end)
        iconFrame:SetScript("OnLeave", function() 
            GameTooltip:Hide() 
            icon:SetVertexColor(1, 1, 1)
        end)
        
        e.dungeonIcons[i] = iconFrame
    end
    
    -- Member Cards Container (scrollable)
    e.memberScroll = CreateFrame("ScrollFrame", "KryosDTMemberScroll", e.partyPanel, "UIPanelScrollFrameTemplate")
    e.memberScroll:SetPoint("TOPLEFT", 5, -58)
    e.memberScroll:SetPoint("BOTTOMRIGHT", -5, 5)
    
    -- Hide scrollbar
    local scrollBar = e.memberScroll.ScrollBar or _G["KryosDTMemberScrollScrollBar"]
    if scrollBar then
        scrollBar:SetAlpha(0)
        scrollBar:SetWidth(1)
        scrollBar:EnableMouse(false)
        if scrollBar.ScrollUpButton then scrollBar.ScrollUpButton:SetAlpha(0) scrollBar.ScrollUpButton:EnableMouse(false) end
        if scrollBar.ScrollDownButton then scrollBar.ScrollDownButton:SetAlpha(0) scrollBar.ScrollDownButton:EnableMouse(false) end
    end
    
    e.memberScroll:EnableMouseWheel(true)
    e.memberScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * 80)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    e.memberContainer = CreateFrame("Frame", "KryosDTMemberContainer", e.memberScroll)
    e.memberContainer:SetSize(1, 1)
    e.memberScroll:SetScrollChild(e.memberContainer)
    
    -- Bottom Buttons
    e.refreshBtn = self:CreateButton(c, "Refresh", 80, 22)
    e.refreshBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.refreshBtn:SetScript("OnClick", function() f:RefreshGroup() end)
    
    -- Compatibility elements (hidden)
    e.membersTitle = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.membersTitle:SetText("")
    e.membersTitle:Hide()
    
    e.headerFrame = CreateFrame("Frame", nil, c)
    e.headerFrame:SetSize(1, 1)
    e.headerFrame:Hide()
end

-- ==================== CREATE MEMBER CARD ====================
local function CreateMemberCard(parent, member, yOffset, scrollFrame, dungeonData)
    local cardHeight = 70
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetHeight(cardHeight)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    card:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    card:SetBackdropColor(0.08, 0.08, 0.10, 0.98)
    card:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
    
    -- Class color accent on left
    local classColors = KDT.CLASS_COLORS[member.class] or {1, 1, 1}
    local accentBar = card:CreateTexture(nil, "OVERLAY")
    accentBar:SetSize(4, cardHeight - 2)
    accentBar:SetPoint("LEFT", 1, 0)
    accentBar:SetTexture("Interface\\Buttons\\WHITE8X8")
    accentBar:SetVertexColor(classColors[1], classColors[2], classColors[3], 1)
    
    -- Enable scrolling through cards
    card:EnableMouseWheel(true)
    card:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        local newScroll = current - (delta * 80)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        scrollFrame:SetVerticalScroll(newScroll)
    end)
    
    -- ===== LEFT SECTION: Portrait + Info =====
    
    -- Portrait Background
    local portraitBg = card:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetSize(48, 48)
    portraitBg:SetPoint("LEFT", 10, 0)
    portraitBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    portraitBg:SetVertexColor(0.1, 0.1, 0.12, 1)
    
    -- Player Portrait using PlayerModel
    local portraitModel = CreateFrame("PlayerModel", nil, card)
    portraitModel:SetSize(46, 46)
    portraitModel:SetPoint("CENTER", portraitBg, "CENTER", 0, 0)
    portraitModel:SetPortraitZoom(1)
    
    -- Try to set the unit
    if member.unit and UnitExists(member.unit) then
        portraitModel:SetUnit(member.unit)
    else
        -- Fallback: Show class icon texture instead
        portraitModel:Hide()
        local classIcon = card:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(44, 44)
        classIcon:SetPoint("CENTER", portraitBg, "CENTER", 0, 0)
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        local coords = CLASS_ICON_COORDS[member.class]
        if coords then
            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    end
    
    -- Name (class colored)
    local nameText = card:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    nameText:SetPoint("TOPLEFT", portraitBg, "TOPRIGHT", 8, -2)
    nameText:SetText(member.name or "Unknown")
    nameText:SetTextColor(classColors[1], classColors[2], classColors[3], 1)
    
    -- Spec + Class (gray, smaller)
    local specText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    specText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -1)
    local specStr = (member.spec or "Unknown") .. " " .. (KDT.CLASS_NAMES[member.class] or "")
    specText:SetText(specStr)
    specText:SetTextColor(0.5, 0.5, 0.5)
    
    -- Item Level + BR/BL (on left side, same line)
    local ilvlText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ilvlText:SetPoint("TOPLEFT", specText, "BOTTOMLEFT", 0, -1)
    
    local ilvlParts = {}
    -- iLvl
    if member.ilvl and member.ilvl > 0 then
        local ilvlColor = member.ilvl >= 639 and "FF8000" or
                         member.ilvl >= 626 and "A335EE" or
                         member.ilvl >= 610 and "0070DD" or
                         "1EFF00"
        table.insert(ilvlParts, "iLvl: |cFF" .. ilvlColor .. member.ilvl .. "|r")
    else
        table.insert(ilvlParts, "iLvl: |cFF666666-|r")
    end
    -- BR/BL
    if KDT.BATTLE_REZ[member.class] then table.insert(ilvlParts, "|cFF00DD00BR|r") end
    if KDT.BLOODLUST[member.class] then table.insert(ilvlParts, "|cFFFF8800BL|r") end
    
    ilvlText:SetText(table.concat(ilvlParts, " "))
    
    -- RIO Score (medium size, below iLvl)
    local rioR, rioG, rioB = GetRIOColor(member.rio)
    local rioText = card:CreateFontString(nil, "OVERLAY")
    rioText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    rioText:SetPoint("TOPLEFT", ilvlText, "BOTTOMLEFT", 0, -2)
    local rioDisplay = member.rio and member.rio > 0 and tostring(member.rio) or "0"
    rioText:SetText(rioDisplay)
    rioText:SetTextColor(rioR, rioG, rioB)
    
    -- Current Key (next to RIO, smaller)
    local keyInfoText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keyInfoText:SetPoint("LEFT", rioText, "RIGHT", 8, 0)
    if member.keystone then
        local kR, kG, kB = GetKeyLevelColor(member.keystone.level)
        local keyColor = string.format("%02X%02X%02X", kR*255, kG*255, kB*255)
        local keyDisplay = member.keystone.text or ("+" .. member.keystone.level)
        keyInfoText:SetText("|cFF" .. keyColor .. "(" .. keyDisplay .. ")|r")
    else
        keyInfoText:SetText("|cFF555555No Key|r")
    end
    
    -- ===== RIGHT SECTION: Dungeon Best Keys (from RIO) =====
    -- Must match header position: header starts at 180 from partyPanel, cards are in container at x=5
    -- So dungeonStartX = 180 - 5 = 175, with 52px spacing and 24px center offset
    local dungeonStartX = 175
    local dungeonColWidth = 52
    
    -- Try to get RIO dungeon data
    local rioDungeonData = nil
    if RaiderIO and RaiderIO.GetProfile then
        local rioProfile = nil
        if member.unit then
            rioProfile = RaiderIO.GetProfile(member.unit)
        end
        if rioProfile and rioProfile.mythicKeystoneProfile then
            rioDungeonData = rioProfile.mythicKeystoneProfile
        end
    end
    
    for i, dungeon in ipairs(SEASON_DUNGEONS) do
        -- Position matches header: (i-1) * 52 + 24 (center of 48px icon)
        local colX = dungeonStartX + (i-1) * dungeonColWidth + 24
        
        local levelText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        levelText:SetPoint("TOP", card, "TOPLEFT", colX, -28)
        
        -- Try to get best key level for this dungeon from RIO
        local bestLevel = nil
        
        if rioDungeonData and rioDungeonData.sortedDungeons then
            for _, dungeonInfo in ipairs(rioDungeonData.sortedDungeons) do
                -- Match by dungeon short name
                if dungeonInfo.dungeon and dungeonInfo.dungeon.shortName then
                    local rioShort = dungeonInfo.dungeon.shortName:upper()
                    if rioShort == dungeon.short:upper() or 
                       rioShort:find(dungeon.short:upper()) then
                        bestLevel = dungeonInfo.level
                        break
                    end
                end
            end
        end
        
        if bestLevel and bestLevel > 0 then
            local kR, kG, kB = GetKeyLevelColor(bestLevel)
            levelText:SetText("|cFF" .. string.format("%02X%02X%02X", kR*255, kG*255, kB*255) .. 
                "+" .. bestLevel .. "|r")
        else
            levelText:SetText("|cFF333333-|r")
        end
    end
    
    -- ===== BLACKLIST WARNING =====
    if KDT:IsBlacklisted(member.name) then
        local warnOverlay = card:CreateTexture(nil, "BACKGROUND", nil, 1)
        warnOverlay:SetAllPoints(card)
        warnOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
        warnOverlay:SetVertexColor(0.5, 0, 0, 0.25)
        
        local warnText = card:CreateFontString(nil, "OVERLAY")
        warnText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        warnText:SetPoint("BOTTOMRIGHT", -8, 8)
        warnText:SetText("|cFFFF3333[BLACKLISTED]|r")
    end
    
    return card, cardHeight + 3
end

-- ==================== SETUP GROUP REFRESH ====================
function KDT:SetupGroupRefresh(f)
    local e = f.groupElements
    
    function f:RefreshGroup()
        if not e then return end
        
        -- Clear existing cards
        if self.memberRows then
            for _, row in ipairs(self.memberRows) do
                if row then
                    row:Hide()
                    row:ClearAllPoints()
                    row:SetParent(nil)
                end
            end
        end
        self.memberRows = {}
        
        local members = KDT:GetGroupMembers()
        local info = KDT:AnalyzeGroup(members)
        
        -- Update compact overview
        e.roleText:SetText(KDT.ROLE_ICONS.TANK .. " " .. info.tanks .. "  " ..
                          KDT.ROLE_ICONS.HEALER .. " " .. info.healers .. "  " ..
                          KDT.ROLE_ICONS.DAMAGER .. " " .. info.dps)
        
        -- Utility info (compact)
        local utilParts = {}
        if info.hasBR then
            table.insert(utilParts, "|cFF00FF00BR|r")
        else
            table.insert(utilParts, "|cFFFF4444No BR|r")
        end
        if info.hasBL then
            table.insert(utilParts, "|cFF00FF00BL|r")
        else
            table.insert(utilParts, "|cFFFF4444No BL|r")
        end
        if #info.stacking > 0 then
            table.insert(utilParts, "|cFFFFCC00Stack: " .. #info.stacking .. "|r")
        end
        e.utilText:SetText(table.concat(utilParts, " | "))
        
        -- Keys summary
        local keys = {}
        for _, m in ipairs(members) do
            if m.keystone then
                local kR, kG, kB = GetKeyLevelColor(m.keystone.level)
                local keyColor = string.format("%02X%02X%02X", kR*255, kG*255, kB*255)
                -- Use text field which contains "STRT +2" format
                local keyDisplay = m.keystone.text or ("+" .. m.keystone.level)
                keys[#keys + 1] = "|cFF" .. keyColor .. keyDisplay .. "|r"
            end
        end
        e.keyText:SetText(#keys > 0 and "|cFFFFD100Keys:|r " .. table.concat(keys, ", ") or "|cFF666666No keys in group|r")
        
        -- Load settings
        if KDT.DB and KDT.DB.settings then
            e.secInput:SetText(tostring(KDT.DB.settings.countdownSeconds or 10))
            e.autoCheck:SetChecked(KDT.DB.settings.autoPost or false)
        end
        
        -- Set container width
        local scrollWidth = e.memberScroll:GetWidth() or 600
        e.memberContainer:SetWidth(scrollWidth - 10)
        
        -- Create member cards
        local yOffset = -5
        local totalHeight = 5
        
        for i, m in ipairs(members) do
            local card, cardHeight = CreateMemberCard(e.memberContainer, m, yOffset, e.memberScroll, SEASON_DUNGEONS)
            card:Show()
            self.memberRows[#self.memberRows + 1] = card
            yOffset = yOffset - cardHeight
            totalHeight = totalHeight + cardHeight
        end
        
        -- Set container height
        e.memberContainer:SetHeight(math.max(1, totalHeight + 10))
    end
end
