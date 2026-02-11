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
-- MERCHANT: SELL JUNK + AUTO REPAIR
---------------------------------------------------------------------------
local function OnMerchantShow()
    local qol = GetQoL()
    if not qol then return end

    -- Sell gray items
    if qol.sellJunk then
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

    -- Auto repair
    if qol.autoRepairEnabled and CanMerchantRepair() then
        local repairCost = GetRepairAllCost()
        if repairCost and repairCost > 0 then
            if qol.autoRepairMode == "guild" and CanGuildBankRepair() then
                RepairAllItems(true)
                KDT:Print("Repaired using guild bank.")
            else
                RepairAllItems(false)
                KDT:Print("Repaired using personal gold.")
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

    -- Set preferred role before accepting
    local pref = qol.autoRolePreference or "dps"
    local isTank = (pref == "tank")
    local isHealer = (pref == "healer")
    local isDPS = (pref == "dps")

    -- SetLFGRoles(leader, tank, healer, dps)
    -- leader is always false for role check
    SetLFGRoles(false, isTank, isHealer, isDPS)

    -- Accept the role check
    CompleteLFGRoleCheck(true)
end

---------------------------------------------------------------------------
-- PARTY INVITES: AUTO ACCEPT
---------------------------------------------------------------------------
local function OnPartyInvite(inviterName)
    local qol = GetQoL()
    if not qol or not qol.autoAcceptInvites then return end

    AcceptGroup()
    StaticPopup_Hide("PARTY_INVITE")
end

---------------------------------------------------------------------------
-- QUESTS: AUTO ACCEPT & AUTO TURN-IN
---------------------------------------------------------------------------
local function OnQuestDetail()
    local qol = GetQoL()
    if not qol or not qol.autoAcceptQuest then return end

    -- Shift override: hold shift to prevent auto-accept
    if IsShiftKeyDown() then return end

    AcceptQuest()
end

local function OnQuestComplete()
    local qol = GetQoL()
    if not qol or not qol.autoTurnInQuest then return end

    -- Shift override: hold shift to prevent auto-turn-in
    if IsShiftKeyDown() then return end

    -- If multiple reward choices exist, let the player decide
    local numChoices = GetNumQuestChoices()
    if numChoices > 1 then return end

    GetQuestReward(numChoices > 0 and 1 or nil)
end

---------------------------------------------------------------------------
-- EVENT REGISTRATION
---------------------------------------------------------------------------
qolFrame:RegisterEvent("MERCHANT_SHOW")
qolFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
qolFrame:RegisterEvent("PARTY_INVITE_REQUEST")
qolFrame:RegisterEvent("QUEST_DETAIL")
qolFrame:RegisterEvent("QUEST_COMPLETE")

qolFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        OnRoleCheckShow()
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite(...)
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    end
end)
