-- Kryos Dungeon Tool
-- Modules/QoL.lua - Quality of Life Automation Features
-- WoW 12.0 compatible

local addonName, KDT = ...

local qolFrame = CreateFrame("Frame")

---------------------------------------------------------------------------
-- SETTINGS HELPER
---------------------------------------------------------------------------
local function GetQoL()
    return KDT.DB and KDT.DB.qol
end

---------------------------------------------------------------------------
-- FORMAT MONEY HELPER
---------------------------------------------------------------------------
local function FormatMoney(copper)
    if not copper or copper == 0 then return "0g" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    if gold > 0 then
        return string.format("%dg %ds %dc", gold, silver, cop)
    elseif silver > 0 then
        return string.format("%ds %dc", silver, cop)
    else
        return string.format("%dc", cop)
    end
end

---------------------------------------------------------------------------
-- MERCHANT: SELL JUNK + AUTO REPAIR (upgraded for WoW 12.0)
---------------------------------------------------------------------------
local function OnMerchantShow()
    local qol = GetQoL()
    if not qol then return end

    -- Sell junk using WoW 12.0 API if available, fallback to manual
    if qol.sellJunk then
        if C_MerchantFrame and C_MerchantFrame.SellAllJunkItems and C_MerchantFrame.IsSellAllJunkEnabled and C_MerchantFrame.IsSellAllJunkEnabled() then
            C_MerchantFrame.SellAllJunkItems()
            KDT:Print("Selling all junk items.")
        else
            -- Fallback: manual iteration
            local soldCount = 0
            for bag = 0, 4 do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.quality == Enum.ItemQuality.Poor then
                        C_Container.UseContainerItem(bag, slot)
                        soldCount = soldCount + 1
                    end
                end
            end
            if soldCount > 0 then
                KDT:Print(soldCount .. " junk item(s) sold.")
            end
        end
    end

    -- Auto repair
    if qol.autoRepairEnabled and CanMerchantRepair() then
        local repairCost = GetRepairAllCost()
        if repairCost and repairCost > 0 then
            local usedGuild = false
            if qol.autoRepairMode == "guild" and CanGuildBankRepair() then
                RepairAllItems(true)
                usedGuild = true
            else
                RepairAllItems(false)
            end
            PlaySound(SOUNDKIT.ITEM_REPAIR)
            local src = usedGuild and " (guild bank)" or " (personal)"
            KDT:Print("Repaired: " .. FormatMoney(repairCost) .. src)
        end
    end

    -- Mark known items on merchant (delayed to let merchant populate)
    C_Timer.After(0.1, function()
        KDT:UpdateMerchantKnownMarks()
    end)
end

-- Auto-accept the "sell all junk" confirmation popup
local function OnStaticPopupShow()
    local qol = GetQoL()
    if not qol or not qol.sellJunk then return end

    for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() and popup.data and type(popup.data) == "table" then
            if popup.data.text == SELL_ALL_JUNK_ITEMS_POPUP and popup.button1 then
                popup.button1:Click()
                return
            end
        end
    end
end

---------------------------------------------------------------------------
-- ROLE CHECK: AUTO ACCEPT
---------------------------------------------------------------------------
local function OnRoleCheckShow()
    local qol = GetQoL()
    if not qol or not qol.autoRoleAccept then return end

    local pref = qol.autoRolePreference or "dps"
    SetLFGRoles(false, pref == "tank", pref == "healer", pref == "dps")
    CompleteLFGRoleCheck(true)
end

---------------------------------------------------------------------------
-- SOCIAL: BLOCK DUELS
---------------------------------------------------------------------------
local function OnDuelRequested()
    local qol = GetQoL()
    if not qol or not qol.blockDuels then return end
    CancelDuel()
    StaticPopup_Hide("DUEL_REQUESTED")
end

---------------------------------------------------------------------------
-- SOCIAL: BLOCK PET BATTLE REQUESTS
---------------------------------------------------------------------------
local function OnPetBattleDuelRequested()
    local qol = GetQoL()
    if not qol or not qol.blockPetBattles then return end
    if C_PetBattles and C_PetBattles.CancelPVPDuel then
        C_PetBattles.CancelPVPDuel()
    end
    StaticPopup_Hide("PET_BATTLE_PVP_DUEL_REQUESTED")
end

---------------------------------------------------------------------------
-- PARTY INVITES: AUTO ACCEPT / BLOCK (upgraded with guild & friend filters)
---------------------------------------------------------------------------
local function OnPartyInvite(inviterName, _, _, _, _, _, inviterGUID)
    local qol = GetQoL()
    if not qol then return end

    -- Auto Accept with optional filters
    if qol.autoAcceptInvites then
        local shouldAccept = false

        if qol.autoAcceptInviteGuildOnly then
            local numGuild = GetNumGuildMembers()
            if numGuild then
                for i = 1, numGuild do
                    local name = GetGuildRosterInfo(i)
                    if name == inviterName then
                        shouldAccept = true
                        break
                    end
                end
            end
        end

        if qol.autoAcceptInviteFriendOnly and not shouldAccept then
            -- Check BNet friends
            if inviterGUID and C_BattleNet and C_BattleNet.GetGameAccountInfoByGUID then
                local gameInfo = C_BattleNet.GetGameAccountInfoByGUID(inviterGUID)
                if gameInfo then shouldAccept = true end
            end
            -- Check WoW friends
            if not shouldAccept and C_FriendList then
                for i = 1, C_FriendList.GetNumFriends() do
                    local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
                    if friendInfo and friendInfo.name == inviterName then
                        shouldAccept = true
                        break
                    end
                end
            end
        end

        -- If no filters enabled, accept all
        if not qol.autoAcceptInviteGuildOnly and not qol.autoAcceptInviteFriendOnly then
            shouldAccept = true
        end

        if shouldAccept then
            AcceptGroup()
            StaticPopup_Hide("PARTY_INVITE")
            return
        end
    end

    -- Block party invites (only if not auto-accepting)
    if qol.blockPartyInvites then
        DeclineGroup()
        StaticPopup_Hide("PARTY_INVITE")
    end
end

---------------------------------------------------------------------------
-- SOCIAL: AUTO ACCEPT SUMMON
---------------------------------------------------------------------------
local function OnConfirmSummon()
    local qol = GetQoL()
    if not qol or not qol.autoAcceptSummon then return end
    if UnitAffectingCombat("player") then return end

    local summonInfo = C_SummonInfo
    if not summonInfo or not summonInfo.ConfirmSummon then return end

    C_Timer.After(0, function()
        local q = GetQoL()
        if not q or not q.autoAcceptSummon then return end
        if UnitAffectingCombat("player") then return end
        if not C_SummonInfo then return end
        if C_SummonInfo.GetSummonConfirmTimeLeft and C_SummonInfo.GetSummonConfirmTimeLeft() <= 0 then return end
        if C_SummonInfo.GetSummonConfirmSummoner and not C_SummonInfo.GetSummonConfirmSummoner() then return end

        C_SummonInfo.ConfirmSummon()
        StaticPopup_Hide("CONFIRM_SUMMON")
        StaticPopup_Hide("CONFIRM_SUMMON_SCENARIO")
        StaticPopup_Hide("CONFIRM_SUMMON_STARTING_AREA")
    end)
end

---------------------------------------------------------------------------
-- SOCIAL: COMMUNITY CHAT PRIVACY
---------------------------------------------------------------------------
local CommunityChatPrivacy = {
    enabled = false,
    sessionAllowed = false,
    loaded = false,
    hooksInstalled = false,
}

local function IsCommunitiesLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("Blizzard_Communities") end
    return false
end

function CommunityChatPrivacy:IsAlwaysMode()
    local qol = GetQoL()
    return not qol or qol.communityChatPrivacyMode ~= "session"
end

function CommunityChatPrivacy:IsHidden()
    return self.enabled and not self.sessionAllowed
end

function CommunityChatPrivacy:Apply()
    if not self.loaded or not CommunitiesFrame then return end
    local hidden = self:IsHidden()
    local displayMode = CommunitiesFrame.GetDisplayMode and CommunitiesFrame:GetDisplayMode() or nil
    local showChat = displayMode == COMMUNITIES_FRAME_DISPLAY_MODES.CHAT or displayMode == COMMUNITIES_FRAME_DISPLAY_MODES.MINIMIZED
    local showMemberList = displayMode == COMMUNITIES_FRAME_DISPLAY_MODES.CHAT or displayMode == COMMUNITIES_FRAME_DISPLAY_MODES.ROSTER

    if hidden then
        if CommunitiesFrame.Chat then CommunitiesFrame.Chat:Hide() end
        if CommunitiesFrame.MemberList then CommunitiesFrame.MemberList:Hide() end
    else
        if CommunitiesFrame.Chat and showChat then CommunitiesFrame.Chat:Show() end
        if CommunitiesFrame.MemberList and showMemberList then CommunitiesFrame.MemberList:Show() end
    end

    -- Update overlay
    if hidden and self.overlay then
        local anchor = (showChat and CommunitiesFrame.Chat) or (showMemberList and CommunitiesFrame.MemberList) or nil
        if anchor then
            self.overlay:ClearAllPoints()
            self.overlay:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
            self.overlay:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
            self.overlay:Show()
        else
            self.overlay:Hide()
        end
    elseif self.overlay then
        self.overlay:Hide()
    end

    -- Update eye button
    if self.eyeButton then
        self.eyeButton:SetShown(self.enabled)
        local tex = self.eyeButton:GetNormalTexture()
        if tex then
            local LFG_EYE_TEXTURE = [[Interface\LFGFrame\LFG-Eye]]
            tex:SetTexture(LFG_EYE_TEXTURE)
            local frameIdx = (not hidden) and 0 or 4
            local cols = 512 / 64
            local col = frameIdx % cols
            local row = math.floor(frameIdx / cols)
            tex:SetTexCoord((col * 64) / 512, ((col + 1) * 64) / 512, (row * 64) / 256, ((row + 1) * 64) / 256)
        end
    end
end

function CommunityChatPrivacy:OnCommunitiesLoaded()
    if self.loaded or not CommunitiesFrame then return end
    self.loaded = true

    -- Create eye button
    local button = CreateFrame("Button", nil, CommunitiesFrame)
    button:SetSize(24, 24)
    button:SetNormalTexture([[Interface\LFGFrame\LFG-Eye]])
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(CommunitiesFrame:GetFrameLevel() + 1)
    local anchor = CommunitiesFrame.MaximizeMinimizeFrame
    if anchor then
        button:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
    else
        button:SetPoint("TOPRIGHT", CommunitiesFrame, "TOPRIGHT", -40, -8)
    end
    button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
    local hl = button:GetHighlightTexture()
    if hl then hl:SetAlpha(0) end
    button:SetScript("OnClick", function()
        if not CommunityChatPrivacy.enabled then return end
        CommunityChatPrivacy.sessionAllowed = not CommunityChatPrivacy.sessionAllowed
        CommunityChatPrivacy:Apply()
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if CommunityChatPrivacy:IsHidden() then
            GameTooltip:SetText("Show Communities chat and members")
        else
            GameTooltip:SetText("Hide Communities chat and members")
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    self.eyeButton = button

    -- Create overlay
    local overlay = CreateFrame("Frame", nil, CommunitiesFrame)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(CommunitiesFrame:GetFrameLevel() + 1)
    overlay:EnableMouse(false)
    overlay:Hide()
    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOPLEFT", overlay, "TOPLEFT", 12, -12)
    text:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -12, 12)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(true)
    text:SetText("Click the eye to reveal chat")
    self.overlay = overlay

    -- Install hooks
    if not self.hooksInstalled then
        if CommunitiesFrame.RegisterCallback and CommunitiesFrameMixin and CommunitiesFrameMixin.Event then
            CommunitiesFrame:RegisterCallback(CommunitiesFrameMixin.Event.DisplayModeChanged, function() self:Apply() end, self)
            CommunitiesFrame:RegisterCallback(CommunitiesFrameMixin.Event.ClubSelected, function() self:Apply() end, self)
        end
        CommunitiesFrame:HookScript("OnShow", function() self:Apply() end)
        CommunitiesFrame:HookScript("OnHide", function()
            if self.enabled and self:IsAlwaysMode() then self.sessionAllowed = false end
        end)
        self.hooksInstalled = true
    end

    self:Apply()
end

function CommunityChatPrivacy:SetEnabled(enabled)
    self.enabled = enabled and true or false
    if not self.enabled then self.sessionAllowed = false end
    if self.enabled and IsCommunitiesLoaded() then self:OnCommunitiesLoaded() end
    if self.eyeButton then self.eyeButton:SetShown(self.enabled) end
    self:Apply()
end

-- Loader for lazy-loaded Communities addon
local ccpLoader = CreateFrame("Frame")
ccpLoader:RegisterEvent("ADDON_LOADED")
ccpLoader:SetScript("OnEvent", function(_, _, name)
    if name == "Blizzard_Communities" then
        local qol = GetQoL()
        if qol and qol.communityChatPrivacy then
            CommunityChatPrivacy:SetEnabled(true)
        end
    end
end)

function KDT:SetCommunityChatPrivacy(enabled)
    CommunityChatPrivacy:SetEnabled(enabled)
end

function KDT:SetCommunityChatPrivacyMode(mode)
    CommunityChatPrivacy.sessionAllowed = false
    CommunityChatPrivacy:Apply()
end

---------------------------------------------------------------------------
-- SOCIAL: FRIENDS LIST DECOR (class colors, location, faction icons)
---------------------------------------------------------------------------
local FriendsListDecor = {
    enabled = false,
    hookInstalled = false,
}

-- Build localized class name -> token map
local localizedClassMap = {}
if LOCALIZED_CLASS_NAMES_MALE then
    for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
        if type(name) == "string" and name ~= "" then localizedClassMap[name] = token end
    end
end
if LOCALIZED_CLASS_NAMES_FEMALE then
    for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
        if type(name) == "string" and name ~= "" and not localizedClassMap[name] then localizedClassMap[name] = token end
    end
end

local function GetClassColorFromToken(token)
    if not token or token == "" then return nil end
    local colorObj = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(token)
    if colorObj and colorObj.r then return colorObj.r, colorObj.g, colorObj.b end
    local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if rc and rc.r then return rc.r, rc.g, rc.b end
    return nil
end

local function ResolveClassToken(classToken, classID, localizedName)
    if type(classToken) == "string" and classToken ~= "" then
        local token = localizedClassMap[classToken] or classToken:upper()
        if GetClassColorFromToken(token) then return token end
    end
    if classID and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
        local info = C_CreatureInfo.GetClassInfo(classID)
        if info and info.classFile and GetClassColorFromToken(info.classFile) then return info.classFile end
    end
    if type(localizedName) == "string" then
        local token = localizedClassMap[localizedName]
        if token and GetClassColorFromToken(token) then return token end
    end
    return nil
end

local function WrapColor(text, r, g, b)
    if not text or text == "" then return text end
    return string.format("|cff%02x%02x%02x%s|r",
        math.min(255, math.floor(r * 255 + 0.5)),
        math.min(255, math.floor(g * 255 + 0.5)),
        math.min(255, math.floor(b * 255 + 0.5)), text)
end

local function FormatFriendLevel(level)
    if not level or level <= 0 then return nil end
    if not GetQuestDifficultyColor then return tostring(level) end
    local color = GetQuestDifficultyColor(level)
    if not color then return tostring(level) end
    return WrapColor(tostring(level), color.r, color.g, color.b)
end

local playerRealmNorm
do
    local realm = GetRealmName and GetRealmName()
    if realm then playerRealmNorm = realm:gsub("[%s%-']", ""):lower() end
end

local function ShouldShowRealm(realm)
    local qol = GetQoL()
    if not qol or not qol.friendsListDecorHideOwnRealm then return true end
    if not realm or realm == "" then return false end
    local norm = realm:gsub("%(%*%)", ""):gsub("%*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if norm == "" then return false end
    local normLower = norm:gsub("[%s%-']", ""):lower()
    return normLower ~= playerRealmNorm
end

local function BuildLocationText(area, realm)
    local qol = GetQoL()
    if not qol or not qol.friendsListDecorLocation then return nil end
    local areaStr = (type(area) == "string" and area ~= "") and area or nil
    local realmStr = ShouldShowRealm(realm) and realm or nil
    if realmStr then
        realmStr = realmStr:gsub("%(%*%)", ""):gsub("%*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if realmStr == "" then realmStr = nil end
    end
    if areaStr and realmStr then return areaStr .. " - " .. realmStr end
    return areaStr or realmStr
end

-- Faction icon helper
local FACTION_ATLAS = { Alliance = "FactionIcon-Alliance", Horde = "FactionIcon-Horde" }
local factionLookup = {}
local function RegFaction(f, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "string" and v ~= "" then factionLookup[v:lower()] = f end
    end
end
RegFaction("Alliance", "Alliance", ALLIANCE or "", FACTION_ALLIANCE or "")
RegFaction("Horde", "Horde", HORDE or "", FACTION_HORDE or "")

local function SetFactionIcon(button, factionName)
    if not button then return end
    local tex = button._kdtFactionIcon
    if not factionName then
        if tex then tex:Hide() end
        return
    end
    if not tex then
        tex = button:CreateTexture(nil, "OVERLAY", nil, 1)
        tex:SetSize(16, 16)
        if button.name then
            tex:SetPoint("LEFT", button.name, "RIGHT", 4, 0)
        end
        button._kdtFactionIcon = tex
    end
    local norm = factionLookup[factionName:lower()]
    local atlas = norm and FACTION_ATLAS[norm]
    if atlas and tex.SetAtlas then
        pcall(tex.SetAtlas, tex, atlas)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:Show()
    else
        tex:Hide()
    end
end

-- Decorate WoW (non-BNet) friend
local function DecorateWoWFriend(button)
    if not FriendsListDecor.enabled then
        SetFactionIcon(button, nil)
        return
    end
    local nameFont = button and button.name
    local infoFont = button and button.info
    if not nameFont or not C_FriendList then return end

    local id = button.id
    if not id then return end

    local info = C_FriendList.GetFriendInfoByIndex(id)
    if not info or not info.name then return end

    local isConnected = info.connected == true
    local baseName = info.name:match("^([^%-]+)") or info.name
    local realm = info.name:match("%-(.+)$")
    local levelText = FormatFriendLevel(info.level)

    local nameColored = baseName
    if isConnected then
        local token = ResolveClassToken(
            info.classTag or info.classFileName or info.classFile,
            info.classID,
            info.className or info.class
        )
        if token then
            local r, g, b = GetClassColorFromToken(token)
            if r then nameColored = WrapColor(baseName, r, g, b) end
        end
    else
        nameColored = WrapColor(baseName, 0.6, 0.6, 0.6)
    end

    local display = nameColored
    if levelText then display = nameColored .. " " .. levelText end
    nameFont:SetText(display)
    if not isConnected then nameFont:SetTextColor(0.6, 0.6, 0.6) end

    if infoFont then
        local location = isConnected and BuildLocationText(info.area, realm) or nil
        infoFont:SetText(location or "")
    end
    SetFactionIcon(button, nil)
end

-- Decorate Battle.net friend
local function DecorateBNetFriend(button)
    if not FriendsListDecor.enabled then
        SetFactionIcon(button, nil)
        return
    end
    if not C_BattleNet or not C_BattleNet.GetFriendAccountInfo then return end
    local nameFont = button and button.name
    local infoFont = button and button.info
    if not nameFont then return end

    local id = button.id
    if not id then return end

    local accountInfo = C_BattleNet.GetFriendAccountInfo(id)
    if not accountInfo then return end

    local gameInfo = accountInfo.gameAccountInfo
    local isOnline = gameInfo and gameInfo.isOnline == true
    local realID = accountInfo.accountName or (accountInfo.battleTag and accountInfo.battleTag:match("^[^#]+")) or ""
    local displayName = realID
    local infoText = ""
    local factionName = nil

    if gameInfo and gameInfo.clientProgram == BNET_CLIENT_WOW then
        local charName = gameInfo.characterName or ""
        local levelText = FormatFriendLevel(gameInfo.characterLevel)
        if levelText and charName ~= "" then
            charName = charName .. " " .. levelText
        end
        local token = ResolveClassToken(
            gameInfo.classTag or gameInfo.classFile,
            gameInfo.classID,
            gameInfo.className or gameInfo.class
        )
        if token then
            local r, g, b = GetClassColorFromToken(token)
            if r then charName = WrapColor(charName, r, g, b) end
        end
        if realID ~= "" and charName ~= "" then
            displayName = WrapColor(realID, 0.866, 0.69, 0.18) .. " || " .. charName
        elseif charName ~= "" then
            displayName = charName
        end
        infoText = BuildLocationText(gameInfo.areaName, gameInfo.realmDisplayName) or gameInfo.richPresence or ""
        factionName = gameInfo.factionName
    else
        infoText = (gameInfo and gameInfo.richPresence) or accountInfo.note or ""
    end

    nameFont:SetText(displayName)
    if not isOnline then nameFont:SetTextColor(0.6, 0.6, 0.6) end
    if infoFont then infoFont:SetText(infoText) end
    SetFactionIcon(button, factionName)
end

-- Main update hook
local function UpdateFriendButton(button)
    if not button or not button.buttonType then return end
    if not FriendsListDecor.enabled then
        if button._kdtFactionIcon then button._kdtFactionIcon:Hide() end
        return
    end
    if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
        DecorateWoWFriend(button)
    elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
        DecorateBNetFriend(button)
    else
        if button._kdtFactionIcon then button._kdtFactionIcon:Hide() end
    end
end

local function EnsureFriendsHook()
    if FriendsListDecor.hookInstalled then return end
    if type(FriendsFrame_UpdateFriendButton) ~= "function" then return end
    hooksecurefunc("FriendsFrame_UpdateFriendButton", UpdateFriendButton)
    FriendsListDecor.hookInstalled = true
end

function FriendsListDecor:Refresh()
    EnsureFriendsHook()
    if FriendsList_UpdateFriends then FriendsList_UpdateFriends()
    elseif FriendsFrame_UpdateFriends then FriendsFrame_UpdateFriends()
    elseif FriendsList_Update then FriendsList_Update()
    end
end

function FriendsListDecor:SetEnabled(enabled)
    self.enabled = enabled and true or false
    EnsureFriendsHook()
    self:Refresh()
end

function KDT:SetFriendsListDecor(enabled)
    FriendsListDecor:SetEnabled(enabled)
end

function KDT:RefreshFriendsListDecor()
    FriendsListDecor:Refresh()
end

---------------------------------------------------------------------------
-- QUESTS: AUTO ACCEPT & AUTO TURN-IN
---------------------------------------------------------------------------
local function OnQuestDetail()
    local qol = GetQoL()
    if not qol or not qol.autoAcceptQuest then return end
    if IsShiftKeyDown() then return end
    AcceptQuest()
end

local function OnQuestComplete()
    local qol = GetQoL()
    if not qol or not qol.autoTurnInQuest then return end
    if IsShiftKeyDown() then return end
    local numChoices = GetNumQuestChoices()
    if numChoices > 1 then return end
    GetQuestReward(numChoices > 0 and 1 or nil)
end

---------------------------------------------------------------------------
-- GOSSIP: AUTO-SELECT SINGLE OPTION
---------------------------------------------------------------------------
local gossipClicked = {}

local function OnGossipShow()
    local qol = GetQoL()
    if not qol or not qol.skipGossip then return end
    if IsShiftKeyDown() then return end

    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local numActiveQuests = C_GossipInfo.GetNumActiveQuests()
    if (availableQuests and #availableQuests > 0) or (numActiveQuests and numActiveQuests > 0) then
        return
    end

    local options = C_GossipInfo.GetOptions()
    if not options or #options == 0 then return end

    local validOptions = {}
    for _, option in pairs(options) do
        if option.gossipOptionID then
            table.insert(validOptions, option)
        end
    end

    if #validOptions == 1 then
        local option = validOptions[1]
        local optionID = option.gossipOptionID
        if optionID and not gossipClicked[optionID] then
            gossipClicked[optionID] = true
            C_GossipInfo.SelectOption(optionID)
        end
    end
end

local function OnGossipClosed()
    wipe(gossipClicked)
end

---------------------------------------------------------------------------
-- CUTSCENE: AUTO-SKIP
---------------------------------------------------------------------------
local function OnPlayMovie()
    local qol = GetQoL()
    if not qol or not qol.skipCutscene then return end
    if MovieFrame and MovieFrame:IsShown() then MovieFrame:Hide() end
end

local function OnCinematicStart()
    local qol = GetQoL()
    if not qol or not qol.skipCutscene then return end
    CinematicFrame_CancelCinematic()
end

---------------------------------------------------------------------------
-- INTERFACE: NAMEPLATES & NAMES
---------------------------------------------------------------------------
function KDT:ApplyNameplateCVars()
    local qol = GetQoL()
    if not qol or not C_CVar or not C_CVar.SetCVar then return end
    -- WoW 12.0: Some CVars are protected and can cause taint. Use pcall.
    pcall(C_CVar.SetCVar, "ShowClassColorInNameplate", qol.showClassColorsNameplates and "1" or "0")
    pcall(C_CVar.SetCVar, "UnitNamePlayerGuild", qol.showGuildNames and "1" or "0")
    pcall(C_CVar.SetCVar, "UnitNamePlayerPVPTitle", qol.showPvPTitles and "1" or "0")
end

---------------------------------------------------------------------------
-- INTERFACE: TALKING HEAD
---------------------------------------------------------------------------
local talkingHeadHooked = false
function KDT:ApplyTalkingHeadSetting()
    local qol = GetQoL()
    if not qol then return end
    if TalkingHeadFrame and not talkingHeadHooked then
        hooksecurefunc(TalkingHeadFrame, "Show", function(self)
            local q = GetQoL()
            if q and q.hideTalkingHead then self:Hide() end
        end)
        talkingHeadHooked = true
    end
    if TalkingHeadFrame and TalkingHeadFrame:IsShown() and qol.hideTalkingHead then
        TalkingHeadFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- INTERFACE: DEATH EFFECT, ZONE TEXT, RAID TOOLS
---------------------------------------------------------------------------
function KDT:ApplyDeathEffectSetting()
    local qol = GetQoL()
    if not qol or not C_CVar then return end
    pcall(C_CVar.SetCVar, "ffxDeath", qol.hideDeathEffect and "0" or "1")
end

function KDT:ApplyZoneTextSetting()
    local qol = GetQoL()
    if not qol then return end
    if qol.hideZoneText then
        if ZoneTextFrame then ZoneTextFrame:SetScript("OnShow", function(s) s:Hide() end) end
        if SubZoneTextFrame then SubZoneTextFrame:SetScript("OnShow", function(s) s:Hide() end) end
    else
        if ZoneTextFrame then ZoneTextFrame:SetScript("OnShow", nil) end
        if SubZoneTextFrame then SubZoneTextFrame:SetScript("OnShow", nil) end
    end
end

function KDT:ApplyRaidToolsSetting()
    local qol = GetQoL()
    if not qol or not CompactRaidFrameManager then return end
    if qol.hideRaidTools then
        CompactRaidFrameManager:UnregisterAllEvents()
        CompactRaidFrameManager:Hide()
    else
        CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
        CompactRaidFrameManager:RegisterEvent("UPDATE_ACTIVE_BATTLEFIELD")
        CompactRaidFrameManager:RegisterEvent("UNIT_FLAGS")
        if IsInRaid() then CompactRaidFrameManager:Show() end
    end
end

---------------------------------------------------------------------------
-- INTERFACE: AUTO-UNWRAP COLLECTION FANFARE
---------------------------------------------------------------------------
local unwrapDebounce = false

local function ClearMountFanfare()
    if not C_MountJournal or not C_MountJournal.GetNumMountsNeedingFanfare then return end
    if C_MountJournal.GetNumMountsNeedingFanfare() <= 0 then return end
    for i = 1, C_MountJournal.GetNumDisplayedMounts() do
        local mountID = C_MountJournal.GetDisplayedMountID(i)
        if mountID and C_MountJournal.NeedsFanfare and C_MountJournal.NeedsFanfare(mountID) then
            C_MountJournal.ClearFanfare(mountID)
        end
    end
end

local function ClearPetFanfare()
    if not C_PetJournal or not C_PetJournal.GetNumPetsNeedingFanfare then return end
    if (C_PetJournal.GetNumPetsNeedingFanfare() or 0) == 0 then return end
    if C_PetJournal.GetOwnedPetIDs then
        for _, petID in ipairs(C_PetJournal.GetOwnedPetIDs() or {}) do
            if petID and C_PetJournal.PetNeedsFanfare and C_PetJournal.PetNeedsFanfare(petID) then
                if C_PetJournal.ClearFanfare then C_PetJournal.ClearFanfare(petID) end
            end
        end
    end
end

local function ClearToyFanfare()
    if not C_ToyBoxInfo or not C_ToyBoxInfo.ClearFanfare or not C_ToyBoxInfo.NeedsFanfare then return end
    if not C_ToyBox or not C_ToyBox.GetNumToys or not C_ToyBox.GetToyFromIndex then return end
    for i = 1, C_ToyBox.GetNumToys() do
        local toyID = C_ToyBox.GetToyFromIndex(i)
        if toyID and C_ToyBoxInfo.NeedsFanfare(toyID) then
            C_ToyBoxInfo.ClearFanfare(toyID)
        end
    end
end

local function DoAutoUnwrap()
    local qol = GetQoL()
    if not qol or not qol.autoUnwrapCollections or unwrapDebounce then return end
    unwrapDebounce = true
    C_Timer.After(0.3, function()
        ClearMountFanfare()
        ClearPetFanfare()
        ClearToyFanfare()
        if CollectionsMicroButton and MainMenuMicroButton_HideAlert then
            MainMenuMicroButton_HideAlert(CollectionsMicroButton)
        end
        unwrapDebounce = false
    end)
end

if MainMenuMicroButton_ShowAlert then
    hooksecurefunc("MainMenuMicroButton_ShowAlert", function(microButton, text)
        local qol = GetQoL()
        if not qol or not qol.autoUnwrapCollections then return end
        if text == COLLECTION_UNOPENED_PLURAL or text == COLLECTION_UNOPENED_SINGULAR then
            DoAutoUnwrap()
        end
    end)
end

---------------------------------------------------------------------------
-- INTERFACE: CLASS-SPECIFIC RESOURCE BARS
---------------------------------------------------------------------------
function KDT:ApplyResourceBarSettings()
    local qol = GetQoL()
    if not qol then return end
    local _, classTag = UnitClass("player")
    if not classTag then return end

    if classTag == "DEATHKNIGHT" then
        if RuneFrame then if qol.hideRuneFrame then RuneFrame:Hide() else RuneFrame:Show() end end
        if TotemFrame then if qol.hideTotemBar then TotemFrame:Hide() else TotemFrame:Show() end end
    elseif classTag == "DRUID" then
        if DruidComboPointBarFrame then if qol.hideComboPoints then DruidComboPointBarFrame:Hide() else DruidComboPointBarFrame:Show() end end
        if TotemFrame then if qol.hideTotemBar then TotemFrame:Hide() else TotemFrame:Show() end end
    elseif classTag == "EVOKER" then
        if EssencePlayerFrame then if qol.hideEssenceBar then EssencePlayerFrame:Hide() else EssencePlayerFrame:Show() end end
    elseif classTag == "MONK" then
        if MonkHarmonyBarFrame then if qol.hideHarmonyBar then MonkHarmonyBarFrame:Hide() else MonkHarmonyBarFrame:Show() end end
        if TotemFrame then if qol.hideTotemBar then TotemFrame:Hide() else TotemFrame:Show() end end
    elseif classTag == "PALADIN" then
        if PaladinPowerBarFrame then if qol.hideHolyPower then PaladinPowerBarFrame:Hide() else PaladinPowerBarFrame:Show() end end
        if TotemFrame then if qol.hideTotemBar then TotemFrame:Hide() else TotemFrame:Show() end end
    elseif classTag == "ROGUE" then
        if RogueComboPointBarFrame then if qol.hideComboPoints then RogueComboPointBarFrame:Hide() else RogueComboPointBarFrame:Show() end end
    elseif classTag == "WARLOCK" then
        if WarlockPowerFrame then if qol.hideSoulShards then WarlockPowerFrame:Hide() else WarlockPowerFrame:Show() end end
        if TotemFrame then if qol.hideTotemBar then TotemFrame:Hide() else TotemFrame:Show() end end
    elseif classTag == "SHAMAN" or classTag == "MAGE" or classTag == "PRIEST" then
        if TotemFrame then if qol.hideTotemBar then TotemFrame:Hide() else TotemFrame:Show() end end
    end
end

function KDT:GetPlayerClassTag()
    local _, classTag = UnitClass("player")
    return classTag
end

---------------------------------------------------------------------------
-- ECONOMY: AUCTION HOUSE TWEAKS
---------------------------------------------------------------------------
local ahHooked = false

local function OnAuctionHouseShow()
    local qol = GetQoL()
    if not qol then return end

    -- Close bags
    if qol.ahCloseBags then
        CloseAllBags()
    end

    -- Always current expansion filter
    if qol.ahCurrentExpansion and AuctionHouseFrame then
        C_Timer.After(0, function()
            if AuctionHouseFrame and AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.FilterButton then
                local fb = AuctionHouseFrame.SearchBar.FilterButton
                if fb.filters and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly then
                    fb.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
                    if AuctionHouseFrame.SearchBar.UpdateClearFiltersButton then
                        AuctionHouseFrame.SearchBar:UpdateClearFiltersButton()
                    end
                end
            end
        end)
    end

    -- Persist filter: hook Reset to restore saved filters
    if qol.ahPersistFilter and AuctionHouseFrame and not ahHooked then
        local fb = AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.FilterButton
        if fb then
            hooksecurefunc(fb, "Reset", function(self)
                local q = GetQoL()
                if not q or not q.ahPersistFilter then return end
                if not KDT._savedAHFilters then return end
                self.filters = KDT._savedAHFilters
                self.minLevel = KDT._savedAHMinLevel
                self.maxLevel = KDT._savedAHMaxLevel
                KDT._savedAHFilters = nil
                if self.ClearFiltersButton then self.ClearFiltersButton:Show() end
                -- Re-apply current expansion on top of restored filters
                if q.ahCurrentExpansion and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly then
                    self.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
                end
            end)
            ahHooked = true
        end
    end
end

local function OnAuctionHouseClosed()
    local qol = GetQoL()
    if not qol or not qol.ahPersistFilter then return end
    if not AuctionHouseFrame then return end

    local fb = AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.FilterButton
    if fb and fb.ClearFiltersButton and fb.ClearFiltersButton:IsShown() then
        KDT._savedAHFilters = fb.filters
        KDT._savedAHMinLevel = fb.minLevel
        KDT._savedAHMaxLevel = fb.maxLevel
    else
        KDT._savedAHFilters = nil
    end
end

---------------------------------------------------------------------------
-- ECONOMY: MARK KNOWN ITEMS ON MERCHANT
---------------------------------------------------------------------------
local knownOverlays = {}

local function IsTransmogKnown(itemLink)
    if not C_TransmogCollection or not C_TransmogCollection.PlayerHasTransmog then return false end
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return false end
    -- Check if the visual is known for the item appearance
    local appearanceID = C_TransmogCollection.GetItemInfo(itemLink)
    if appearanceID then
        local sources = C_TransmogCollection.GetAppearanceSources(appearanceID)
        if sources then
            for _, src in ipairs(sources) do
                if src.isCollected then return true end
            end
        end
    end
    return C_TransmogCollection.PlayerHasTransmog(itemID)
end

-- Tooltip-based "Already Known" check (works for recipes, transmog, toys - anything with ITEM_SPELL_KNOWN in tooltip)
-- Adapted from EnhanceQoL original: uses C_TooltipInfo.GetMerchantItem, NOT GetMerchantItemInfo (removed in WoW 12.0)
local function merchantItemIsKnown(itemIndex)
    if not itemIndex or itemIndex <= 0 then return false end
    if not C_TooltipInfo or (not C_TooltipInfo.GetMerchantItem and not C_TooltipInfo.GetHyperlink) then return false end

    local tooltipData
    if C_TooltipInfo.GetMerchantItem then tooltipData = C_TooltipInfo.GetMerchantItem(itemIndex) end

    if not tooltipData and C_TooltipInfo.GetHyperlink and GetMerchantItemLink then
        local itemLink = GetMerchantItemLink(itemIndex)
        if itemLink then tooltipData = C_TooltipInfo.GetHyperlink(itemLink) end
    end

    if not tooltipData then return false end
    if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(tooltipData) end
    if not tooltipData.lines then return false end
    for _, line in ipairs(tooltipData.lines) do
        if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
        local text = line.leftText or line.rightText
        if text and text:find(ITEM_SPELL_KNOWN, 1, true) then return true end
    end
    return false
end

local function IsToyKnown(itemLink)
    if not C_ToyBox or not C_ToyBox.PlayerHasToy then return false end
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return false end
    return C_ToyBox.PlayerHasToy(itemID)
end

local function IsPetCollected(itemLink)
    if not C_PetJournal then return false end
    local itemID, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemLink)
    -- classID 15 = Miscellaneous, subclassID 2 = Companion Pets
    if classID ~= 15 or subclassID ~= 2 then return false end
    if not itemID then return false end
    -- Check if any species from this item is already collected
    local numPets = C_PetJournal.GetNumPets()
    if not numPets then return false end
    -- Use the item to find the species
    local speciesID = C_PetJournal.GetPetInfoByItemID and C_PetJournal.GetPetInfoByItemID(itemID)
    if speciesID then
        local _, _, _, _, _, _, _, _, _, _, _, numCollected = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        return numCollected and numCollected > 0
    end
    return false
end

local function GetOrCreateKnownOverlay(button, index)
    if knownOverlays[index] then return knownOverlays[index] end

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    overlay:SetColorTexture(0, 1, 0, 0.3)
    overlay:Hide()

    local icon = button:CreateTexture(nil, "OVERLAY", nil, 2)
    icon:SetPoint("TOPRIGHT", button, "TOPRIGHT", 2, 2)
    icon:SetSize(16, 16)
    icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    icon:Hide()

    knownOverlays[index] = {overlay = overlay, icon = icon}
    return knownOverlays[index]
end

function KDT:UpdateMerchantKnownMarks()
    local qol = GetQoL()
    if not qol then return end

    local anyEnabled = qol.markKnownTransmog or qol.markKnownRecipes or qol.markKnownToys or qol.markCollectedPets
    if not anyEnabled then
        -- Hide all overlays
        for _, data in pairs(knownOverlays) do
            data.overlay:Hide()
            data.icon:Hide()
        end
        return
    end

    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE or 10
    for i = 1, itemsPerPage do
        local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
        if itemButton and itemButton:IsShown() then
            local buttonID = itemButton:GetID()
            local itemIndex = buttonID and buttonID > 0 and buttonID or i
            local itemLink = GetMerchantItemLink(itemIndex)
            local isKnown = false

            if itemLink then
                -- Check transmog
                if qol.markKnownTransmog and not isKnown then
                    isKnown = IsTransmogKnown(itemLink)
                end

                -- Check recipes via tooltip "Already Known" text (WoW 12.0: GetMerchantItemInfo removed)
                if qol.markKnownRecipes and not isKnown then
                    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemLink)
                    if classID == 9 then -- Recipe
                        isKnown = merchantItemIsKnown(itemIndex)
                    end
                end

                -- Check toys
                if qol.markKnownToys and not isKnown then
                    isKnown = IsToyKnown(itemLink)
                end

                -- Check pets
                if qol.markCollectedPets and not isKnown then
                    isKnown = IsPetCollected(itemLink)
                end
            end

            local data = GetOrCreateKnownOverlay(itemButton, i)
            if isKnown then
                data.overlay:Show()
                data.icon:Show()
            else
                data.overlay:Hide()
                data.icon:Hide()
            end
        else
            -- Button not shown, hide overlay
            if knownOverlays[i] then
                knownOverlays[i].overlay:Hide()
                knownOverlays[i].icon:Hide()
            end
        end
    end
end

-- Hook merchant page updates to refresh marks
local merchantHooked = false
local function HookMerchantUpdates()
    if merchantHooked then return end
    if MerchantFrame_UpdateMerchantInfo then
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
            C_Timer.After(0.05, function() KDT:UpdateMerchantKnownMarks() end)
        end)
    end
    if MerchantFrame_UpdateBuybackInfo then
        hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
            -- Hide marks on buyback tab
            for _, data in pairs(knownOverlays) do
                data.overlay:Hide()
                data.icon:Hide()
            end
        end)
    end
    merchantHooked = true
end

---------------------------------------------------------------------------
-- ECONOMY: GOLD TRACKING
---------------------------------------------------------------------------
function KDT:UpdateGoldTracking()
    local qol = GetQoL()
    if not qol or not qol.goldTrackingEnabled then return end
    if not KDT.DB then return end
    if not KDT.DB.goldTracker then KDT.DB.goldTracker = {} end

    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then return end

    local key = name .. "-" .. realm
    local _, classTag = UnitClass("player")
    local money = GetMoney()

    KDT.DB.goldTracker[key] = {
        gold = money,
        class = classTag,
        lastSeen = time(),
    }
end

function KDT:GetGoldTrackingData()
    if not KDT.DB or not KDT.DB.goldTracker then return {} end
    return KDT.DB.goldTracker
end

function KDT:GetGoldTrackingTotal()
    local total = 0
    for _, data in pairs(KDT.DB.goldTracker or {}) do
        total = total + (data.gold or 0)
    end
    return total
end

function KDT:RemoveGoldTrackingChar(charKey)
    if not KDT.DB or not KDT.DB.goldTracker then return end
    KDT.DB.goldTracker[charKey] = nil
end

---------------------------------------------------------------------------
-- APPLY ALL INTERFACE SETTINGS
---------------------------------------------------------------------------
function KDT:ApplyAllInterfaceSettings()
    self:ApplyNameplateCVars()
    self:ApplyDeathEffectSetting()
    self:ApplyZoneTextSetting()
    self:ApplyRaidToolsSetting()
    self:ApplyResourceBarSettings()
    C_Timer.After(1, function() self:ApplyTalkingHeadSetting() end)
end

---------------------------------------------------------------------------
-- BATCH 1: DIALOGS & CONFIRMATIONS
---------------------------------------------------------------------------
local staticPopupsHooked = false
local function HookStaticPopups()
    if staticPopupsHooked then return end
    staticPopupsHooked = true
    -- Hook each StaticPopup frame's Show method directly (like EnhanceQoL original)
    -- This gives us `self` as the popup frame with direct access to self.which, self.editBox etc.
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup then
            hooksecurefunc(popup, "Show", function(self)
                if not self then return end
                local qol = GetQoL()
                if not qol then return end

                -- Delete Item Fill Dialog: auto-fill "DELETE" text
                if qol.deleteItemFillDialog
                    and (self.which == "DELETE_GOOD_ITEM" or self.which == "DELETE_GOOD_QUEST_ITEM")
                    and (self.editBox or (self.GetEditBox and self:GetEditBox()))
                then
                    local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
                    editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
                    editBox:ClearFocus()
                    editBox:SetAutoFocus(false)
                end

                -- Auto-confirm dialogs (using GetButton like original)
                if qol.confirmTimerRemovalTrade and self.which == "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL" and self.GetButton then
                    self:GetButton(1):Click()
                elseif qol.confirmReplaceEnchant and self.which == "REPLACE_ENCHANT" and (self.numButtons or 0) > 0 and self.GetButton then
                    self:GetButton(1):Click()
                elseif qol.confirmSocketReplace and self.which == "CONFIRM_ACCEPT_SOCKETS" and (self.numButtons or 0) > 0 and self.GetButton then
                    self:GetButton(1):Click()
                elseif qol.confirmPurchaseTokenItem and self.which == "CONFIRM_PURCHASE_TOKEN_ITEM" and (self.numButtons or 0) > 0 and self.GetButton then
                    self:GetButton(1):Click()
                elseif qol.confirmHighCostItem and self.which == "CONFIRM_HIGH_COST_ITEM" and (self.numButtons or 0) > 0 and self.GetButton then
                    C_Timer.After(0, function() self:GetButton(1):Click() end)
                end
            end)
        end
    end
end

---------------------------------------------------------------------------
-- BATCH 1: AUTO ACCEPT RESURRECTION
---------------------------------------------------------------------------
local function OnResurrectRequest(offerer)
    local qol = GetQoL()
    if not qol or not qol.autoAcceptResurrection then return end
    if qol.autoAcceptResurrectionExcludeCombat and UnitAffectingCombat("player") then return end
    if qol.autoAcceptResurrectionExcludeAfterlife and offerer then
        -- Check if offerer is dead (Afterlife talent etc.)
        local unit
        for i = 1, GetNumGroupMembers() do
            local rUnit = (IsInRaid() and "raid" or "party") .. i
            if UnitName(rUnit) == offerer or (GetUnitName(rUnit, true) or ""):find(offerer) then
                unit = rUnit
                break
            end
        end
        if unit and UnitIsDeadOrGhost(unit) then return end
    end
    C_Timer.After(0.5, function()
        if GetCorpseRecoveryDelay() == 0 then
            AcceptResurrect()
            StaticPopup_Hide("RESURRECT_NO_TIMER")
            StaticPopup_Hide("RESURRECT")
            StaticPopup_Hide("RESURRECT_NO_SICKNESS")
        end
    end)
end

---------------------------------------------------------------------------
-- BATCH 1: AUTO RELEASE IN PVP
---------------------------------------------------------------------------
local AUTO_RELEASE_PVP_EXCLUDE_ALTERAC = {[91]=true, [1459]=true}
local AUTO_RELEASE_PVP_EXCLUDE_WINTERGRASP = {[501]=true}
local AUTO_RELEASE_PVP_EXCLUDE_TOLBARAD = {[708]=true, [709]=true}
local AUTO_RELEASE_PVP_EXCLUDE_ASHRAN = {[1478]=true}

local function ShouldAutoReleasePvP()
    local qol = GetQoL()
    if not qol or not qol.autoReleasePvP then return false end
    local _, instanceType = IsInInstance()
    if instanceType ~= "pvp" and instanceType ~= "arena" then return false end
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        if AUTO_RELEASE_PVP_EXCLUDE_ALTERAC[mapID] then return false end
        if AUTO_RELEASE_PVP_EXCLUDE_WINTERGRASP[mapID] then return false end
        if AUTO_RELEASE_PVP_EXCLUDE_TOLBARAD[mapID] then return false end
        if AUTO_RELEASE_PVP_EXCLUDE_ASHRAN[mapID] then return false end
    end
    return true
end

local function OnPlayerDead()
    if not ShouldAutoReleasePvP() then return end
    local qol = GetQoL()
    local delay = tonumber(qol.autoReleasePvPDelay or 0) or 0
    C_Timer.After(math.max(0.1, delay), function()
        if UnitIsDeadOrGhost("player") and not UnitIsGhost("player") then
            RepopMe()
        end
    end)
end

---------------------------------------------------------------------------
-- BATCH 1: AUTO COMBAT LOGGING
---------------------------------------------------------------------------
local combatLogActive = false

local function UpdateCombatLogging()
    local qol = GetQoL()
    if not qol or not qol.autoCombatLog then
        if combatLogActive then
            LoggingCombat(false)
            combatLogActive = false
            KDT:Print("Combat logging |cFFFF4444stopped|r.")
        end
        return
    end
    local _, instanceType = IsInInstance()
    local shouldLog = (instanceType == "party" or instanceType == "raid")
    if shouldLog and not combatLogActive then
        LoggingCombat(true)
        combatLogActive = true
        KDT:Print("Combat logging |cFF44FF44started|r.")
    elseif not shouldLog and combatLogActive then
        LoggingCombat(false)
        combatLogActive = false
        KDT:Print("Combat logging |cFFFF4444stopped|r.")
    end
end

---------------------------------------------------------------------------
-- BATCH 1: HIDE BOSS BANNER
---------------------------------------------------------------------------
local bossBannerHooked = false
local function HookBossBanner()
    if bossBannerHooked then return end
    bossBannerHooked = true
    if BossBanner and BossBanner.PlayBanner then
        hooksecurefunc(BossBanner, "PlayBanner", function(self)
            local qol = GetQoL()
            if qol and qol.hideBossBanner then
                self:Hide()
            end
        end)
    end
end

---------------------------------------------------------------------------
-- BATCH 1: AUTO QUICK LOOT
---------------------------------------------------------------------------
local function OnLootReady(autoLoot)
    local qol = GetQoL()
    if not qol or not qol.autoQuickLoot then return end
    local requireShift = qol.autoQuickLootWithShift
    if (requireShift and IsShiftKeyDown()) or (not requireShift and not IsShiftKeyDown()) then
        for i = GetNumLootItems(), 1, -1 do
            LootSlot(i)
        end
        if GetNumLootItems() == 0 then CloseLoot() end
    end
end

---------------------------------------------------------------------------
-- BATCH 1: INTERFACE TWEAKS (Unit Frames, Action Bars, Toasts)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- ACTION BAR BUTTON ITERATION (used by macro names, etc.)
---------------------------------------------------------------------------
local AB_BAR_PREFIXES = {
    { prefix = "ActionButton",               count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBarBottomLeftButton",    count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBarBottomRightButton",   count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBarRightButton",         count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBarLeftButton",          count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBar5Button",             count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBar6Button",             count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBar7Button",             count = _G.NUM_ACTIONBAR_BUTTONS or 12 },
}

local function ForEachActionBarButton(callback)
    for _, info in ipairs(AB_BAR_PREFIXES) do
        for i = 1, info.count do
            local btn = _G[info.prefix .. i]
            if btn then callback(btn, info.prefix) end
        end
    end
end

function KDT:ApplyBatch1InterfaceSettings()
    local qol = GetQoL()
    if not qol then return end
    
    ---------------------------------------------------------------------------
    -- Hide Hit Indicator (Player) - bidirectional
    ---------------------------------------------------------------------------
    do
        local hitInd = PlayerFrame and PlayerFrame.PlayerFrameContent
            and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
            and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator
        if hitInd then
            if qol.hideHitIndicatorPlayer then
                hitInd:Hide()
            end
            -- Hook Show to re-hide (fires every hit flash)
            if not self._hitIndPlayerHooked then
                hooksecurefunc(hitInd, "Show", function(s)
                    local q = GetQoL()
                    if q and q.hideHitIndicatorPlayer then s:Hide() end
                end)
                self._hitIndPlayerHooked = true
            end
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Hit Indicator (Pet) - bidirectional
    ---------------------------------------------------------------------------
    if PetHitIndicator then
        if qol.hideHitIndicatorPet then
            PetHitIndicator:Hide()
        end
        if not self._hitIndPetHooked then
            hooksecurefunc(PetHitIndicator, "Show", function(s)
                local q = GetQoL()
                if q and q.hideHitIndicatorPet then s:Hide() end
            end)
            self._hitIndPetHooked = true
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Resting Glow - bidirectional (matches original pattern)
    ---------------------------------------------------------------------------
    do
        local function ApplyRestingVisuals()
            if not PlayerFrame or not PlayerFrame.PlayerFrameContent then return end
            local content = PlayerFrame.PlayerFrameContent
            local main = content.PlayerFrameContentMain
            local contextual = content.PlayerFrameContentContextual
            local q = GetQoL()
            if q and q.hideRestingGlow and IsResting() then
                if main and main.StatusTexture then main.StatusTexture:Hide() end
                if contextual and contextual.PlayerRestLoop then
                    contextual.PlayerRestLoop:Hide()
                    if contextual.PlayerRestLoop.PlayerRestLoopAnim then
                        contextual.PlayerRestLoop.PlayerRestLoopAnim:Stop()
                    end
                end
            else
                -- Let Blizzard refresh
                if PlayerFrame_UpdateStatus then PlayerFrame_UpdateStatus(PlayerFrame) end
            end
        end
        
        if PlayerFrame_UpdateStatus and not self._restingHooked then
            hooksecurefunc("PlayerFrame_UpdateStatus", function()
                local q = GetQoL()
                if not q or not q.hideRestingGlow then return end
                if not IsResting() then return end
                local content = PlayerFrame and PlayerFrame.PlayerFrameContent
                local main = content and content.PlayerFrameContentMain
                if main and main.StatusTexture then main.StatusTexture:Hide() end
            end)
            self._restingHooked = true
        end
        
        if PlayerFrame_UpdatePlayerRestLoop and not self._restingLoopHooked then
            hooksecurefunc("PlayerFrame_UpdatePlayerRestLoop", function(state)
                local q = GetQoL()
                if not q or not q.hideRestingGlow then return end
                if state then
                    local content = PlayerFrame and PlayerFrame.PlayerFrameContent
                    local contextual = content and content.PlayerFrameContentContextual
                    local restLoop = contextual and contextual.PlayerRestLoop
                    if restLoop then
                        restLoop:Hide()
                        if restLoop.PlayerRestLoopAnim then restLoop.PlayerRestLoopAnim:Stop() end
                    end
                end
            end)
            self._restingLoopHooked = true
        end
        
        ApplyRestingVisuals()
    end
    
    ---------------------------------------------------------------------------
    -- Hide Party Frame Title - bidirectional (matches original: CompactPartyFrameTitle)
    ---------------------------------------------------------------------------
    do
        local titleFrame = CompactPartyFrameTitle
        if titleFrame then
            if qol.hidePartyFrameTitle then
                titleFrame:Hide()
            else
                titleFrame:Show()
            end
            if not self._partyTitleHooked then
                titleFrame:HookScript("OnShow", function(s)
                    local q = GetQoL()
                    if q and q.hidePartyFrameTitle then s:Hide() end
                end)
                self._partyTitleHooked = true
            end
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Macro Names on ALL Action Bars - bidirectional
    -- Uses SetAlpha(0)/SetAlpha(1) like original for proper toggle
    ---------------------------------------------------------------------------
    ForEachActionBarButton(function(btn)
        local nameFrame = btn.Name or (btn.GetName and _G[btn:GetName() .. "Name"])
        if not nameFrame then return end
        if qol.hideMacroNames then
            if not nameFrame.KDT_MacroNameHidden then
                nameFrame.KDT_OrigAlpha = nameFrame:GetAlpha()
                nameFrame:SetAlpha(0)
                nameFrame.KDT_MacroNameHidden = true
            end
        elseif nameFrame.KDT_MacroNameHidden then
            nameFrame:SetAlpha(nameFrame.KDT_OrigAlpha or 1)
            nameFrame.KDT_MacroNameHidden = nil
            nameFrame.KDT_OrigAlpha = nil
        end
    end)
    
    -- Hook UpdateButtonArt to re-apply macro name hiding when Blizzard refreshes
    if not self._macroNameHooked then
        local mixin = _G.ActionBarActionButtonMixin
        if mixin and mixin.Update then
            hooksecurefunc(mixin, "Update", function(btn)
                local q = GetQoL()
                if not q or not q.hideMacroNames then return end
                local nameFrame = btn.Name or (btn.GetName and _G[btn:GetName() .. "Name"])
                if nameFrame then
                    nameFrame.KDT_OrigAlpha = nameFrame.KDT_OrigAlpha or 1
                    nameFrame:SetAlpha(0)
                    nameFrame.KDT_MacroNameHidden = true
                end
            end)
        end
        self._macroNameHooked = true
    end
    
    ---------------------------------------------------------------------------
    -- Hide Extra Action Button Artwork - bidirectional (matches original)
    ---------------------------------------------------------------------------
    do
        local shouldHide = qol.hideExtraActionArtwork == true
        -- ExtraActionButton1.style
        local eab = _G.ExtraActionButton1
        local extraStyle = eab and eab.style
        if extraStyle then
            if shouldHide then
                extraStyle:SetAlpha(0)
                extraStyle:Hide()
            else
                extraStyle:SetAlpha(1)
                extraStyle:Show()
            end
        end
        -- ZoneAbilityFrame.Style
        local zaf = _G.ZoneAbilityFrame
        local zoneStyle = zaf and zaf.Style
        if zoneStyle then
            if shouldHide then
                zoneStyle:SetAlpha(0)
                zoneStyle:Hide()
            else
                zoneStyle:SetAlpha(1)
                zoneStyle:Show()
            end
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Micro Menu Notification Overlay - bidirectional
    ---------------------------------------------------------------------------
    do
        if not self._microMenuHooked then
            if MainMenuMicroButton_ShowAlert then
                hooksecurefunc("MainMenuMicroButton_ShowAlert", function(btn)
                    local q = GetQoL()
                    if q and q.hideMicroMenuNotification and btn and btn.FlashBorder then
                        btn.FlashBorder:Hide()
                    end
                end)
            end
            self._microMenuHooked = true
        end
        -- Immediate apply
        if MicroMenu and MicroMenu.GetMicroButtons then
            for _, btn in pairs(MicroMenu:GetMicroButtons()) do
                if btn.FlashBorder then
                    if qol.hideMicroMenuNotification then
                        btn.FlashBorder:Hide()
                    end
                    -- Note: FlashBorder will reappear naturally on next alert if unchecked
                end
            end
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Azerite Toast - bidirectional
    ---------------------------------------------------------------------------
    if AzeriteLevelUpToast then
        if qol.hideAzeriteToast then
            AzeriteLevelUpToast:UnregisterAllEvents()
        else
            -- Re-register original events
            AzeriteLevelUpToast:RegisterEvent("AZERITE_EMPOWERED_ITEM_LOOTED")
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Quick Join Toast Button - bidirectional
    ---------------------------------------------------------------------------
    if QuickJoinToastButton then
        if qol.hideQuickJoinToast then
            QuickJoinToastButton:Hide()
        else
            QuickJoinToastButton:Show()
        end
    end
    
    ---------------------------------------------------------------------------
    -- Hide Screenshot Status - bidirectional (matches original toggle pattern)
    ---------------------------------------------------------------------------
    do
        local actionStatus = _G.ActionStatus or _G.ScreenshotStatus
        if actionStatus and actionStatus.UnregisterEvent and actionStatus.RegisterEvent then
            if qol.hideScreenshotStatus then
                actionStatus:UnregisterEvent("SCREENSHOT_STARTED")
                actionStatus:UnregisterEvent("SCREENSHOT_SUCCEEDED")
                actionStatus:UnregisterEvent("SCREENSHOT_FAILED")
                actionStatus:Hide()
            else
                actionStatus:RegisterEvent("SCREENSHOT_STARTED")
                actionStatus:RegisterEvent("SCREENSHOT_SUCCEEDED")
                actionStatus:RegisterEvent("SCREENSHOT_FAILED")
            end
        end
    end
    
    ---------------------------------------------------------------------------
    -- Show Train All Button
    ---------------------------------------------------------------------------
    if qol.showTrainAllButton and not self._trainAllHooked then
        local loader = CreateFrame("Frame")
        loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(_, _, name)
            if name == "Blizzard_TrainerUI" and ClassTrainerFrame then
                local trainAllBtn = CreateFrame("Button", nil, ClassTrainerFrame, "UIPanelButtonTemplate")
                trainAllBtn:SetSize(80, 22)
                trainAllBtn:SetPoint("TOPRIGHT", ClassTrainerFrame, "TOPRIGHT", -60, -28)
                trainAllBtn:SetText("Train All")
                trainAllBtn:SetScript("OnClick", function()
                    for i = 1, GetNumTrainerServices() do
                        local _, _, _, isAvailable = GetTrainerServiceInfo(i)
                        if isAvailable then BuyTrainerService(i) end
                    end
                end)
                loader:UnregisterEvent("ADDON_LOADED")
            end
        end)
        self._trainAllHooked = true
    end
end

---------------------------------------------------------------------------
-- BATCH 1: CHAT TWEAKS
---------------------------------------------------------------------------
local chatTweaksInitialized = false

local function ForEachChatFrame(fn)
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        local editBox = frame and frame.editBox
        if frame then fn(frame, editBox, i) end
    end
end

function KDT:ApplyChatSettings()
    local qol = GetQoL()
    if not qol then return end
    
    -- Arrow Keys in Chat
    ForEachChatFrame(function(frame, editBox)
        if editBox and editBox.SetAltArrowKeyMode then
            editBox:SetAltArrowKeyMode(not qol.chatUseArrowKeys)
        end
    end)
    
    -- Edit Box on Top
    ForEachChatFrame(function(frame, editBox)
        if not (frame and editBox) then return end
        editBox:ClearAllPoints()
        if qol.chatEditBoxOnTop then
            -- Position ABOVE the chat frame
            editBox:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
            editBox:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
        else
            -- Reset to default: below the chat frame
            editBox:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
            editBox:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
        end
    end)
    
    -- Unclamp Chat Frame
    ForEachChatFrame(function(frame)
        if frame and frame.SetClampedToScreen then
            frame:SetClampedToScreen(not qol.chatUnclampFrame)
        end
    end)
    
    -- Max Lines 2000
    if qol.chatMaxLines2000 then
        ForEachChatFrame(function(frame)
            if frame and frame.SetMaxLines then
                frame:SetMaxLines(2000)
            end
        end)
    end
    
    -- Hide Combat Log Tab
    if ChatFrame2Tab then
        if qol.chatHideCombatLogTab then
            if ChatFrame2 and ChatFrame2.isDocked then
                ChatFrame2Tab:Hide()
                -- Reposition tab 1 to avoid gap
                if ChatFrame1Tab and ChatFrame2Tab then
                    ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0)
                end
            end
        else
            ChatFrame2Tab:Show()
        end
    end
    
    -- Chat Fade
    ForEachChatFrame(function(frame)
        if not frame then return end
        if qol.chatFadeEnabled then
            frame:SetFading(true)
            frame:SetTimeVisible(qol.chatFadeTimeVisible or 120)
            frame:SetFadeDuration(qol.chatFadeDuration or 10)
        else
            frame:SetFading(false)
        end
    end)
    
    -- Hide Learn/Unlearn messages
    if qol.chatHideLearnUnlearn and not self._learnFilterHooked then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg, ...)
            if not qol.chatHideLearnUnlearn then return false end
            if msg and (msg:find(ERR_LEARN_SPELL_S or "You have learned") 
                     or msg:find(ERR_SPELL_UNLEARNED_S or "You have unlearned")
                     or msg:find(ERR_LEARN_ABILITY_S or "You have learned")) then
                return true  -- suppress
            end
            return false
        end)
        self._learnFilterHooked = true
    end
    
    chatTweaksInitialized = true
end

-- Hook for UPDATE_CHAT_WINDOWS to reapply settings
local chatWatcher = CreateFrame("Frame")
chatWatcher:RegisterEvent("UPDATE_CHAT_WINDOWS")
chatWatcher:SetScript("OnEvent", function()
    if chatTweaksInitialized then
        KDT:ApplyChatSettings()
    end
end)

-- FCF_SetTabPosition hook for combat log tab
if FCF_SetTabPosition then
    hooksecurefunc("FCF_SetTabPosition", function()
        local qol = GetQoL()
        if qol and qol.chatHideCombatLogTab and ChatFrame2Tab and ChatFrame1Tab then
            if ChatFrame2 and ChatFrame2.isDocked then
                ChatFrame2Tab:Hide()
            end
        end
    end)
end

---------------------------------------------------------------------------
-- MOVEMENT & INPUT CVars
---------------------------------------------------------------------------
function KDT:ApplyMovementCVars()
    local qol = GetQoL()
    if not qol then return end
    if qol.autoDismount then
        pcall(SetCVar, "autoDismount", 1)
    end
    if qol.autoDismountFlying then
        pcall(SetCVar, "autoDismountFlying", 1)
    end
end

---------------------------------------------------------------------------
-- LFG TWEAKS
---------------------------------------------------------------------------
local lfgInitialized = false

local function InitLFGTweaks()
    if lfgInitialized then return end
    local qol = GetQoL()
    if not qol then return end
    
    -- Skip Sign-Up Dialog: auto-click SignUp when dialog shows
    if LFGListApplicationDialog and LFGListApplicationDialog.HookScript then
        LFGListApplicationDialog:HookScript("OnShow", function(self)
            if not qol.lfgSkipSignUpDialog then return end
            if IsShiftKeyDown() then return end
            if self.SignUpButton and self.SignUpButton:IsEnabled() then
                self.SignUpButton:Click()
            end
        end)
    end
    
    -- Persist Sign-Up Note: replace LFGListApplicationDialog_Show to keep note text
    -- The original function calls ClearApplicationTextFields which wipes the note.
    -- Our patched version skips that call so the note persists between applications.
    if LFGListApplicationDialog_Show and LFGListApplicationDialog_UpdateRoles then
        local originalShow = LFGListApplicationDialog_Show
        local patchedShow = function(self, resultID)
            if resultID then
                local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
                self.resultID = resultID
                self.activityID = searchResultInfo and searchResultInfo.activityID
            end
            LFGListApplicationDialog_UpdateRoles(self)
            StaticPopupSpecial_Show(self)
        end
        
        -- Apply immediately based on current setting
        if qol.lfgPersistSignUpNote then
            LFGListApplicationDialog_Show = patchedShow
        end
        
        -- Watch for setting changes via a ticker (settings toggle)
        KDT._lfgPersistOriginal = originalShow
        KDT._lfgPersistPatched = patchedShow
    end
    
    -- Sort LFG Applicants by Raider.IO / M+ Score
    -- Hook the sort function that WoW calls when refreshing the applicant list
    if LFGListUtil_SortApplicants then
        local sortingInProgress = false
        hooksecurefunc("LFGListUtil_SortApplicants", function(applicants)
            if not qol.lfgSortByRio then return end
            if sortingInProgress then return end  -- prevent recursion
            if not applicants or #applicants < 2 then return end
            
            sortingInProgress = true
            table.sort(applicants, function(id1, id2)
                local info1 = C_LFGList.GetApplicantInfo(id1)
                local info2 = C_LFGList.GetApplicantInfo(id2)
                if not info1 then return false end
                if not info2 then return true end
                
                local _, _, _, _, _, _, _, _, _, _, _, score1 = C_LFGList.GetApplicantMemberInfo(id1, 1)
                local _, _, _, _, _, _, _, _, _, _, _, score2 = C_LFGList.GetApplicantMemberInfo(id2, 1)
                
                return (score1 or 0) > (score2 or 0)
            end)
            
            -- Refresh the applicant viewer to show new order
            if LFGListFrame and LFGListFrame.ApplicationViewer
               and LFGListApplicationViewer_UpdateResults then
                LFGListApplicationViewer_UpdateResults(LFGListFrame.ApplicationViewer)
            end
            sortingInProgress = false
        end)
    end
    
    lfgInitialized = true
end

function KDT:ToggleLFGPersistNote(enabled)
    if enabled and self._lfgPersistPatched then
        LFGListApplicationDialog_Show = self._lfgPersistPatched
    elseif self._lfgPersistOriginal then
        LFGListApplicationDialog_Show = self._lfgPersistOriginal
    end
end

---------------------------------------------------------------------------
-- EVENT REGISTRATION (updated with Batch 1 events)
---------------------------------------------------------------------------
qolFrame:RegisterEvent("MERCHANT_SHOW")
qolFrame:RegisterEvent("MERCHANT_CLOSED")
qolFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
qolFrame:RegisterEvent("PARTY_INVITE_REQUEST")
qolFrame:RegisterEvent("QUEST_DETAIL")
qolFrame:RegisterEvent("QUEST_COMPLETE")
qolFrame:RegisterEvent("GOSSIP_SHOW")
qolFrame:RegisterEvent("GOSSIP_CLOSED")
qolFrame:RegisterEvent("PLAY_MOVIE")
qolFrame:RegisterEvent("CINEMATIC_START")
qolFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
qolFrame:RegisterEvent("PLAYER_MONEY")
qolFrame:RegisterEvent("NEW_MOUNT_ADDED")
qolFrame:RegisterEvent("NEW_PET_ADDED")
qolFrame:RegisterEvent("NEW_TOY_ADDED")
qolFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
qolFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
qolFrame:RegisterEvent("DUEL_REQUESTED")
qolFrame:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUESTED")
qolFrame:RegisterEvent("CONFIRM_SUMMON")
-- Batch 1 events
qolFrame:RegisterEvent("RESURRECT_REQUEST")
qolFrame:RegisterEvent("PLAYER_DEAD")
qolFrame:RegisterEvent("LOOT_READY")

qolFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
        HookMerchantUpdates()
    elseif event == "MERCHANT_CLOSED" then
        -- sell marked cleanup handled by ExtendedMerchant module
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        OnRoleCheckShow()
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite(...)
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    elseif event == "GOSSIP_SHOW" then
        OnGossipShow()
    elseif event == "GOSSIP_CLOSED" then
        OnGossipClosed()
    elseif event == "PLAY_MOVIE" then
        OnPlayMovie()
    elseif event == "CINEMATIC_START" then
        OnCinematicStart()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            KDT:ApplyAllInterfaceSettings()
            KDT:ApplyBatch1InterfaceSettings()
            KDT:ApplyChatSettings()
            KDT:ApplyMovementCVars()
            KDT:UpdateGoldTracking()
            UpdateCombatLogging()
            HookStaticPopups()
            HookBossBanner()
            InitLFGTweaks()
            -- Init Phase 2 modules
            KDT:InitTooltip()
            KDT:InitBagItemLevel()
            KDT:UpdateChatIcons()
            KDT:InitHealthText()
            KDT:InitInstanceDifficulty()
            KDT:InitExtendedMerchant()
            KDT:InitActionBarTweaks()
            KDT:InitTradeMailLog()
            -- Init Keystone Helper
            KDT:InitKeystoneHelper()
            -- Init Minimap Collector
            if KDT.MinimapCollector then KDT.MinimapCollector:Init() end
            -- Init Chat Enhancer
            if KDT.ChatEnhancer then KDT.ChatEnhancer:Init() end
            -- Init social features
            local qol = GetQoL()
            if qol then
                if qol.communityChatPrivacy and IsCommunitiesLoaded() then
                    CommunityChatPrivacy:SetEnabled(true)
                end
                if qol.friendsListDecor then
                    FriendsListDecor:SetEnabled(true)
                end
            end
        end)
    elseif event == "PLAYER_MONEY" then
        KDT:UpdateGoldTracking()
    elseif event == "NEW_MOUNT_ADDED" or event == "NEW_PET_ADDED" or event == "NEW_TOY_ADDED" then
        DoAutoUnwrap()
    elseif event == "AUCTION_HOUSE_SHOW" then
        OnAuctionHouseShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        OnAuctionHouseClosed()
    elseif event == "DUEL_REQUESTED" then
        OnDuelRequested()
    elseif event == "PET_BATTLE_PVP_DUEL_REQUESTED" then
        OnPetBattleDuelRequested()
    elseif event == "CONFIRM_SUMMON" then
        OnConfirmSummon()
    -- Batch 1 events
    elseif event == "RESURRECT_REQUEST" then
        OnResurrectRequest(...)
    elseif event == "PLAYER_DEAD" then
        OnPlayerDead()
    elseif event == "LOOT_READY" then
        OnLootReady(...)
    end
end)
