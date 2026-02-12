-- Kryos Dungeon Tool
-- Modules/KeystoneHelper.lua - Keystone Helper (Auto-Slot, Announce, Party Keys)
-- WoW 12.0 API compliant

local _, KDT = ...

local function GetQoL() return KDT.DB and KDT.DB.qol end
local function isSecret(v) return issecretvalue and issecretvalue(v) end

---------------------------------------------------------------------------
-- KEYSTONE DATA
---------------------------------------------------------------------------
local KEYSTONE_ITEM_ID = 180653  -- Mythic Keystone item ID

local function GetOwnKeystone()
    -- WoW 12.0: C_MythicPlus API
    if C_MythicPlus then
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID and C_MythicPlus.GetOwnedKeystoneMapID()
        local level = C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()
        if mapID and level and mapID > 0 and level > 0 then
            local mapName = "Unknown"
            if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                mapName = C_ChallengeMode.GetMapUIInfo(mapID) or mapName
            end
            return {
                mapID = mapID,
                level = level,
                mapName = mapName,
            }
        end
    end
    -- Fallback: C_ChallengeMode
    if C_ChallengeMode then
        local mapID = C_ChallengeMode.GetOwnedKeystoneMapID and C_ChallengeMode.GetOwnedKeystoneMapID()
        if mapID and mapID > 0 then
            local level = C_ChallengeMode.GetOwnedKeystoneLevel and C_ChallengeMode.GetOwnedKeystoneLevel() or 0
            local mapName = C_ChallengeMode.GetMapUIInfo(mapID) or "Unknown"
            return {
                mapID = mapID,
                level = level,
                mapName = mapName,
            }
        end
    end
    return nil
end

local function GetKeystoneItemLink()
    -- Search bags for keystone item
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local itemID = info.itemID
                if itemID == KEYSTONE_ITEM_ID then
                    return info.hyperlink, bag, slot
                end
            end
        end
    end
    return nil
end

local function FormatKeystoneString(keyData)
    if not keyData then return nil end
    return string.format("+%d %s", keyData.level, keyData.mapName)
end

---------------------------------------------------------------------------
-- AUTO-SLOT KEYSTONE INTO FONT OF POWER
---------------------------------------------------------------------------
local autoSlotRegistered = false

local function TryAutoSlotKeystone()
    local qol = GetQoL()
    if not qol or not qol.keystoneAutoSlot then return end
    
    -- Find the keystone in bags and use it
    local link, bag, slot = GetKeystoneItemLink()
    if link and bag and slot then
        C_Timer.After(0.3, function()
            C_Container.UseContainerItem(bag, slot)
        end)
    end
end

local function RegisterAutoSlot()
    if autoSlotRegistered then return end
    autoSlotRegistered = true
    
    -- Hook the ChallengesKeystoneFrame when it shows (Font of Power UI)
    -- This frame is created by Blizzard when you interact with the keystone receptacle
    local hookFrame = CreateFrame("Frame")
    hookFrame:RegisterEvent("ADDON_LOADED")
    hookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    local function HookKeystoneFrame()
        if ChallengesKeystoneFrame and not ChallengesKeystoneFrame._kdtHooked then
            ChallengesKeystoneFrame:HookScript("OnShow", function()
                TryAutoSlotKeystone()
            end)
            ChallengesKeystoneFrame._kdtHooked = true
            hookFrame:UnregisterAllEvents()
        end
    end
    
    hookFrame:SetScript("OnEvent", function(self, event)
        HookKeystoneFrame()
    end)
    
    -- Also try immediately in case frame already exists
    C_Timer.After(1, HookKeystoneFrame)
end

---------------------------------------------------------------------------
-- ANNOUNCE KEYSTONE
---------------------------------------------------------------------------
function KDT:AnnounceKeystone(channel)
    local keyData = GetOwnKeystone()
    if not keyData then
        KDT:Print("You don't have a Mythic Keystone.")
        return
    end
    
    local link = GetKeystoneItemLink()
    local msg
    if link then
        msg = string.format("My Keystone: %s (+%d %s)", link, keyData.level, keyData.mapName)
    else
        msg = string.format("My Keystone: +%d %s", keyData.level, keyData.mapName)
    end
    
    channel = channel or "PARTY"
    
    if channel == "PRINT" then
        KDT:Print(msg)
        return
    end
    
    if channel == "PARTY" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            SendChatMessage(msg, "INSTANCE_CHAT")
        elseif IsInGroup() then
            SendChatMessage(msg, "PARTY")
        else
            KDT:Print(msg)
        end
    elseif channel == "GUILD" then
        if IsInGuild() then
            SendChatMessage(msg, "GUILD")
        else
            KDT:Print("You are not in a guild.")
        end
    elseif channel == "SAY" then
        SendChatMessage(msg, "SAY")
    else
        SendChatMessage(msg, channel)
    end
end

---------------------------------------------------------------------------
-- PARTY KEYSTONE COLLECTION (via addon comms)
---------------------------------------------------------------------------
local COMM_PREFIX = "KDT_KEY"
local partyKeys = {}  -- [name-realm] = { mapName, level, class }
local partyKeysFrame = CreateFrame("Frame")

local function SendKeystoneToParty()
    if not IsInGroup() then return end
    local keyData = GetOwnKeystone()
    if not keyData then return end
    local _, class = UnitClass("player")
    local msg = string.format("%d:%d:%s", keyData.mapID, keyData.level, class or "UNKNOWN")
    local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    C_ChatInfo.SendAddonMessage(COMM_PREFIX, msg, chatType)
end

local function RequestPartyKeys()
    if not IsInGroup() then
        KDT:Print("Not in a group.")
        return
    end
    wipe(partyKeys)
    -- Request from party via addon message
    local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    C_ChatInfo.SendAddonMessage(COMM_PREFIX, "REQUEST", chatType)
    -- Also add our own key
    local keyData = GetOwnKeystone()
    if keyData then
        local name = UnitName("player")
        local realm = GetNormalizedRealmName() or GetRealmName():gsub("%s", "")
        local _, class = UnitClass("player")
        partyKeys[name .. "-" .. realm] = {
            mapName = keyData.mapName,
            level = keyData.level,
            class = class,
        }
    end
    -- Display after short delay for responses
    C_Timer.After(1.5, function() KDT:DisplayPartyKeys() end)
end

function KDT:DisplayPartyKeys()
    local count = 0
    for _ in pairs(partyKeys) do count = count + 1 end
    
    if count == 0 then
        KDT:Print("No keystones found in party.")
        return
    end
    
    KDT:Print("|cffffd200Party Keystones:|r")
    local sorted = {}
    for name, data in pairs(partyKeys) do
        table.insert(sorted, {name = name, data = data})
    end
    table.sort(sorted, function(a, b) return (a.data.level or 0) > (b.data.level or 0) end)
    
    local colors = RAID_CLASS_COLORS or {}
    for _, entry in ipairs(sorted) do
        local cc = colors[entry.data.class]
        local nameColor = cc and string.format("|cff%02x%02x%02x", cc.r*255, cc.g*255, cc.b*255) or "|cffffffff"
        local shortName = entry.name:match("^([^%-]+)") or entry.name
        KDT:Print(string.format("  %s%s|r: +%d %s",
            nameColor, shortName, entry.data.level or 0, entry.data.mapName or "?"))
    end
end

---------------------------------------------------------------------------
-- KEYSTONE DEPLETION WARNING
---------------------------------------------------------------------------
local depletionFrame = CreateFrame("Frame")
local depletionRegistered = false

local function RegisterDepletionWarning()
    if depletionRegistered then return end
    depletionRegistered = true
    
    -- pcall in case event name changes in future patches
    local ok = pcall(depletionFrame.RegisterEvent, depletionFrame, "CHALLENGE_MODE_COMPLETED")
    if not ok then return end
    depletionFrame:SetScript("OnEvent", function(self, event)
        local qol = GetQoL()
        if not qol or not qol.keystoneDepletionWarning then return end
        
        if C_ChallengeMode and C_ChallengeMode.GetCompletionInfo then
            local info = C_ChallengeMode.GetCompletionInfo()
            if info then
                local mapID = info.mapChallengeModeID
                local level = info.level
                local onTime = info.onTime
                local mapName = "Dungeon"
                if C_ChallengeMode.GetMapUIInfo then
                    mapName = C_ChallengeMode.GetMapUIInfo(mapID) or mapName
                end
                
                if onTime then
                    local upgrades = info.keystoneUpgradeLevels or 1
                    KDT:Print(string.format("|cff00ff00Timed!|r +%d %s - Key upgraded by %d level(s)!",
                        level, mapName, upgrades))
                else
                    KDT:Print(string.format("|cffff4444Depleted.|r +%d %s - Key downgraded by 1 level.",
                        level, mapName))
                end
            end
        end
    end)
end

---------------------------------------------------------------------------
-- CURRENT KEY DISPLAY WIDGET (small moveable frame)
---------------------------------------------------------------------------
local keyDisplayFrame = nil

local function CreateKeyDisplay()
    if keyDisplayFrame then return keyDisplayFrame end
    
    keyDisplayFrame = CreateFrame("Frame", "KDT_KeystoneDisplay", UIParent, "BackdropTemplate")
    keyDisplayFrame:SetSize(180, 28)
    keyDisplayFrame:SetPoint("TOP", UIParent, "TOP", 0, -10)
    keyDisplayFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    keyDisplayFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    keyDisplayFrame:SetBackdropBorderColor(0.15, 0.15, 0.20, 1)
    keyDisplayFrame:SetMovable(true)
    keyDisplayFrame:EnableMouse(true)
    keyDisplayFrame:RegisterForDrag("LeftButton")
    keyDisplayFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    keyDisplayFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint(1)
        if KDT.DB and KDT.DB.qol then
            KDT.DB.qol.keystoneDisplayPoint = point
            KDT.DB.qol.keystoneDisplayRelPoint = relPoint
            KDT.DB.qol.keystoneDisplayX = x
            KDT.DB.qol.keystoneDisplayY = y
        end
    end)
    keyDisplayFrame:SetClampedToScreen(true)
    
    keyDisplayFrame.icon = keyDisplayFrame:CreateTexture(nil, "ARTWORK")
    keyDisplayFrame.icon:SetSize(20, 20)
    keyDisplayFrame.icon:SetPoint("LEFT", 4, 0)
    keyDisplayFrame.icon:SetTexture(525134)  -- Keystone icon
    
    keyDisplayFrame.text = keyDisplayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyDisplayFrame.text:SetPoint("LEFT", keyDisplayFrame.icon, "RIGHT", 6, 0)
    keyDisplayFrame.text:SetPoint("RIGHT", -4, 0)
    keyDisplayFrame.text:SetJustifyH("LEFT")
    keyDisplayFrame.text:SetTextColor(1, 1, 1)
    
    -- Click to link keystone
    keyDisplayFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            KDT:AnnounceKeystone("PARTY")
        end
    end)
    
    keyDisplayFrame:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Keystone Helper", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        local keyData = GetOwnKeystone()
        if keyData then
            GameTooltip:AddDoubleLine("Key:", string.format("+%d %s", keyData.level, keyData.mapName), 0.5, 0.5, 0.5, 1, 1, 1)
        else
            GameTooltip:AddLine("No keystone found", 0.5, 0.5, 0.5)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff888888Right-click: Announce to party|r")
        GameTooltip:AddLine("|cff888888Drag to move|r")
        GameTooltip:Show()
    end)
    keyDisplayFrame:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.15, 0.15, 0.20, 1)
        GameTooltip:Hide()
    end)
    
    return keyDisplayFrame
end

local function UpdateKeyDisplay()
    if not keyDisplayFrame then return end
    local qol = GetQoL()
    if not qol or not qol.keystoneShowDisplay then
        keyDisplayFrame:Hide()
        return
    end
    
    local keyData = GetOwnKeystone()
    if keyData then
        local levelColor
        if keyData.level >= 15 then
            levelColor = "|cffff8000"
        elseif keyData.level >= 10 then
            levelColor = "|cffa335ee"
        elseif keyData.level >= 7 then
            levelColor = "|cff0070dd"
        else
            levelColor = "|cff1eff00"
        end
        keyDisplayFrame.text:SetText(string.format("%s+%d|r %s", levelColor, keyData.level, keyData.mapName))
        keyDisplayFrame:Show()
    else
        keyDisplayFrame.text:SetText("|cff666666No Keystone|r")
        keyDisplayFrame:Show()
    end
    
    -- Restore position
    if qol.keystoneDisplayPoint then
        keyDisplayFrame:ClearAllPoints()
        keyDisplayFrame:SetPoint(
            qol.keystoneDisplayPoint,
            UIParent,
            qol.keystoneDisplayRelPoint or "CENTER",
            qol.keystoneDisplayX or 0,
            qol.keystoneDisplayY or 0
        )
    end
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local keystoneInitialized = false

function KDT:InitKeystoneHelper()
    local qol = GetQoL()
    if not qol then return end
    
    if not keystoneInitialized then
        keystoneInitialized = true
        
        -- Register addon prefix for party key sharing
        C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
        
        -- Listen for addon messages
        partyKeysFrame:RegisterEvent("CHAT_MSG_ADDON")
        partyKeysFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        partyKeysFrame:RegisterEvent("MYTHIC_PLUS_NEW_WEEKLY_RECORD")
        partyKeysFrame:RegisterEvent("BAG_UPDATE")
        partyKeysFrame:SetScript("OnEvent", function(self, event, prefix, msg, _, sender)
            if event == "CHAT_MSG_ADDON" and prefix == COMM_PREFIX then
                if msg == "REQUEST" then
                    -- Someone is requesting keys, send ours
                    SendKeystoneToParty()
                else
                    -- Parse key data: mapID:level:class
                    local mapIDStr, levelStr, class = strsplit(":", msg)
                    local mapID = tonumber(mapIDStr)
                    local level = tonumber(levelStr)
                    if mapID and level then
                        local mapName = "Unknown"
                        if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                            mapName = C_ChallengeMode.GetMapUIInfo(mapID) or mapName
                        end
                        if sender and not isSecret(sender) then
                            partyKeys[sender] = {
                                mapName = mapName,
                                level = level,
                                class = class or "UNKNOWN",
                            }
                        end
                    end
                end
            elseif event == "GROUP_ROSTER_UPDATE" then
                wipe(partyKeys)
            elseif event == "BAG_UPDATE" or event == "MYTHIC_PLUS_NEW_WEEKLY_RECORD" then
                C_Timer.After(0.5, UpdateKeyDisplay)
            end
        end)
        
        -- Depletion warning
        RegisterDepletionWarning()
    end
    
    -- Auto-slot
    if qol.keystoneAutoSlot then
        RegisterAutoSlot()
    end
    
    -- Key display
    if qol.keystoneShowDisplay then
        CreateKeyDisplay()
        C_Timer.After(1, UpdateKeyDisplay)
    elseif keyDisplayFrame then
        keyDisplayFrame:Hide()
    end
end

function KDT:RefreshKeystoneDisplay()
    UpdateKeyDisplay()
end

function KDT:RequestPartyKeys()
    RequestPartyKeys()
end
