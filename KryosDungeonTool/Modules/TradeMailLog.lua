-- Kryos Dungeon Tool
-- Modules/TradeMailLog.lua - Trade & Mail logging
-- Standalone implementation - logs to chat and stores in SavedVariables

local _, KDT = ...

local TML = { tradeState = nil, pendingSend = nil, seq = 0 }
KDT.TradeMailLog = TML

local frame = CreateFrame("Frame")
local MAX_LOG_ENTRIES = 200

local function now() return GetServerTime and GetServerTime() or time() end
local function trim(s) return s and s:gsub("^%s+", ""):gsub("%s+$", "") or "" end

local function GetQoL() return KDT.DB and KDT.DB.qol end

---------------------------------------------------------------------------
-- FORMATTING
---------------------------------------------------------------------------
local function FormatMoney(amount)
    if not amount or amount <= 0 then return nil end
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(amount)
    end
    if GetCoinTextureString then return GetCoinTextureString(amount) end
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100
    local parts = {}
    if gold > 0 then parts[#parts+1] = gold .. "g" end
    if silver > 0 then parts[#parts+1] = silver .. "s" end
    if copper > 0 then parts[#parts+1] = copper .. "c" end
    return table.concat(parts, " ")
end

local function FormatItemList(items)
    if not items or #items == 0 then return "none" end
    local parts = {}
    for _, item in ipairs(items) do
        local name = item.link or item.name or "?"
        if item.count and item.count > 1 then
            name = name .. " x" .. item.count
        end
        parts[#parts+1] = name
    end
    return table.concat(parts, ", ")
end

---------------------------------------------------------------------------
-- LOG STORAGE
---------------------------------------------------------------------------
local function EnsureLog()
    if not KDT.DB then return nil end
    if not KDT.DB.tradeMailLog then KDT.DB.tradeMailLog = {} end
    return KDT.DB.tradeMailLog
end

local function StoreEntry(entry)
    local log = EnsureLog()
    if not log then return end
    entry.timestamp = now()
    entry.date = date("%Y-%m-%d %H:%M:%S", entry.timestamp)
    table.insert(log, 1, entry) -- newest first
    -- Trim to max
    while #log > MAX_LOG_ENTRIES do
        table.remove(log)
    end
end

---------------------------------------------------------------------------
-- CHAT OUTPUT
---------------------------------------------------------------------------
local function PrintTrade(state)
    local partner = state.partner or UNKNOWN or "Unknown"
    local status = state.status == "completed" and "|cFF00FF00Completed|r" or "|cFFFF0000Cancelled|r"

    KDT:Print("|cFFFFD200Trade|r with |cFFFFFFFF" .. partner .. "|r - " .. status)

    if state.playerItems and #state.playerItems > 0 then
        KDT:Print("  |cFF00FF00You gave:|r " .. FormatItemList(state.playerItems))
    end
    if state.playerMoney and state.playerMoney > 0 then
        KDT:Print("  |cFF00FF00You gave:|r " .. (FormatMoney(state.playerMoney) or "?"))
    end
    if state.targetItems and #state.targetItems > 0 then
        KDT:Print("  |cFFFF8000Received:|r " .. FormatItemList(state.targetItems))
    end
    if state.targetMoney and state.targetMoney > 0 then
        KDT:Print("  |cFFFF8000Received:|r " .. (FormatMoney(state.targetMoney) or "?"))
    end
end

local function PrintMail(data)
    local dir = data.direction == "sent" and "|cFF00FF00Sent|r" or "|cFFFF8000Received|r"
    local who = data.direction == "sent" and data.receiver or data.sender
    local subject = data.subject or ""
    if subject == "" then subject = "(No Subject)" end

    KDT:Print("|cFFFFD200Mail|r " .. dir .. " - " .. (who or "?") .. " - " .. subject)

    if data.items and #data.items > 0 then
        KDT:Print("  Items: " .. FormatItemList(data.items))
    end
    if data.money and data.money > 0 then
        KDT:Print("  Gold: " .. (FormatMoney(data.money) or "?"))
    end
    if data.cod and data.cod > 0 then
        KDT:Print("  COD: " .. (FormatMoney(data.cod) or "?"))
    end
end

---------------------------------------------------------------------------
-- TRADE TRACKING
---------------------------------------------------------------------------
local function GetTradeItemSlots()
    local max = MAX_TRADE_ITEMS or 6
    if TRADE_ENCHANT_SLOT and max == TRADE_ENCHANT_SLOT then max = max - 1 end
    return math.max(max, 1)
end

local function GetTradeItems(isTarget)
    local items = {}
    local maxSlots = GetTradeItemSlots()
    for i = 1, maxSlots do
        local name, texture, count, quality
        if isTarget then
            name, texture, count, quality = GetTradeTargetItemInfo(i)
        else
            name, texture, count, quality = GetTradePlayerItemInfo(i)
        end
        if name then
            local link = isTarget and GetTradeTargetItemLink(i) or GetTradePlayerItemLink(i)
            local itemID = link and tonumber(link:match("item:(%d+)")) or nil
            items[#items+1] = {
                name = name, link = link, itemID = itemID,
                texture = texture, count = count or 1, quality = quality, slot = i,
            }
        end
    end
    return items
end

function TML:UpdateTradeSnapshot()
    if not self.tradeState then return end
    self.tradeState.playerItems = GetTradeItems(false)
    self.tradeState.targetItems = GetTradeItems(true)
    self.tradeState.playerMoney = GetPlayerTradeMoney and GetPlayerTradeMoney() or 0
    self.tradeState.targetMoney = GetTargetTradeMoney and GetTargetTradeMoney() or 0
end

function TML:StartTrade()
    local partner = GetUnitName and GetUnitName("NPC", true) or nil
    if not partner or partner == "" then
        local name, realm = UnitName("npc")
        partner = (name and realm) and (name .. "-" .. realm) or name
    end
    if not partner or partner == "" then partner = UNKNOWN or "Unknown" end

    self.tradeState = {
        kind = "trade",
        partner = partner,
        playerName = UnitName("player") or "",
        zone = GetRealZoneText and GetRealZoneText() or "",
        time = now(),
        playerAccepted = 0, targetAccepted = 0,
    }
    self:UpdateTradeSnapshot()
end

local function HasTradeContent(state)
    if not state then return false end
    if state.playerMoney and state.playerMoney > 0 then return true end
    if state.targetMoney and state.targetMoney > 0 then return true end
    if state.playerItems and #state.playerItems > 0 then return true end
    if state.targetItems and #state.targetItems > 0 then return true end
    return false
end

function TML:FinishTrade()
    local state = self.tradeState
    if not state then return end

    local completed = state.playerAccepted == 1 and state.targetAccepted == 1
    state.completed = completed
    state.status = completed and "completed" or "cancelled"

    if HasTradeContent(state) or completed then
        -- Serialize items to plain data (strip links for storage)
        local entry = {
            type = "trade",
            partner = state.partner,
            status = state.status,
            zone = state.zone,
            playerItems = {},
            targetItems = {},
            playerMoney = state.playerMoney or 0,
            targetMoney = state.targetMoney or 0,
        }
        for _, item in ipairs(state.playerItems or {}) do
            entry.playerItems[#entry.playerItems+1] = { name = item.name, count = item.count, itemID = item.itemID, quality = item.quality }
        end
        for _, item in ipairs(state.targetItems or {}) do
            entry.targetItems[#entry.targetItems+1] = { name = item.name, count = item.count, itemID = item.itemID, quality = item.quality }
        end
        StoreEntry(entry)
        PrintTrade(state)
    end
    self.tradeState = nil
end

---------------------------------------------------------------------------
-- MAIL TRACKING
---------------------------------------------------------------------------
function TML:CaptureSendMail()
    if not SendMailNameEditBox or not SendMailSubjectEditBox then return end
    local recipient = trim(SendMailNameEditBox:GetText())
    if recipient == "" then return end

    local subject = SendMailSubjectEditBox:GetText() or ""
    local body = SendMailBodyEditBox and SendMailBodyEditBox:GetText() or ""
    local money = GetSendMailMoney and GetSendMailMoney() or 0
    local cod = GetSendMailCOD and GetSendMailCOD() or 0

    local items = {}
    local maxAttach = ATTACHMENTS_MAX_SEND or 12
    for i = 1, maxAttach do
        if HasSendMailItem and HasSendMailItem(i) then
            local name, itemID, texture, count, quality = GetSendMailItem(i)
            items[#items+1] = { name = name, itemID = itemID, count = count or 1, quality = quality, slot = i }
        end
    end

    self.pendingSend = {
        kind = "mail", direction = "sent",
        sender = UnitName("player") or "", receiver = recipient,
        subject = subject, body = body,
        money = money, cod = cod, items = items,
        zone = GetRealZoneText and GetRealZoneText() or "",
    }
end

function TML:LogMail(data)
    local entry = {
        type = "mail",
        direction = data.direction,
        sender = data.sender, receiver = data.receiver,
        subject = data.subject or "",
        money = data.money or 0, cod = data.cod or 0,
        items = {},
        zone = data.zone or "",
    }
    for _, item in ipairs(data.items or {}) do
        entry.items[#entry.items+1] = { name = item.name, count = item.count, itemID = item.itemID, quality = item.quality }
    end
    StoreEntry(entry)
    PrintMail(data)
end

function TML:LogInboxMail(index)
    if not index or not GetInboxHeaderInfo then return end

    local _, _, sender, subject, money, cod, _, itemCount = GetInboxHeaderInfo(index)
    if not sender or sender == "" then sender = UNKNOWN or "Unknown" end

    -- Dedup check
    local sig = (sender or "") .. "|" .. (subject or "") .. "|" .. (money or 0) .. "|" .. index
    if self.lastInboxSig == sig then return end
    self.lastInboxSig = sig

    local items = {}
    local maxAttach = ATTACHMENTS_MAX_RECEIVE or 16
    for i = 1, maxAttach do
        if HasInboxItem and HasInboxItem(index, i) then
            local name, itemID, texture, count, quality = GetInboxItem(index, i)
            local link = GetInboxItemLink and GetInboxItemLink(index, i) or nil
            items[#items+1] = { name = name, link = link, itemID = itemID, count = count or 1, quality = quality }
        end
    end

    self:LogMail({
        kind = "mail", direction = "received",
        sender = sender, receiver = UnitName("player") or "",
        subject = subject or "", money = money or 0, cod = cod or 0,
        items = items, zone = GetRealZoneText and GetRealZoneText() or "",
    })
end

---------------------------------------------------------------------------
-- MAIL HOOKS
---------------------------------------------------------------------------
local mailHooked = false

local function EnsureMailHooks()
    if mailHooked then return end
    local sendOk, inboxOk = false, false

    if type(SendMailFrame_SendMail) == "function" then
        hooksecurefunc("SendMailFrame_SendMail", function() TML:CaptureSendMail() end)
        sendOk = true
    end
    if type(InboxFrame_OnClick) == "function" then
        hooksecurefunc("InboxFrame_OnClick", function(_, index) TML:LogInboxMail(index) end)
        inboxOk = true
    end
    mailHooked = sendOk and inboxOk
end

---------------------------------------------------------------------------
-- SHOW LOG COMMAND
---------------------------------------------------------------------------
function TML:ShowLog(count)
    count = count or 20
    local log = EnsureLog()
    if not log or #log == 0 then
        KDT:Print("No trade/mail history recorded yet.")
        return
    end
    KDT:Print("|cFFFFD200--- Trade & Mail Log (last " .. math.min(count, #log) .. ") ---|r")
    for i = 1, math.min(count, #log) do
        local e = log[i]
        local dateStr = e.date or "?"
        if e.type == "trade" then
            local status = e.status == "completed" and "|cFF00FF00OK|r" or "|cFFFF0000X|r"
            local items = 0
            items = items + #(e.playerItems or {}) + #(e.targetItems or {})
            local moneyStr = ""
            if (e.playerMoney or 0) > 0 or (e.targetMoney or 0) > 0 then
                moneyStr = " | Gold"
            end
            KDT:Print(string.format("  %s [%s] Trade w/ %s — %d items%s", dateStr, status, e.partner or "?", items, moneyStr))
        elseif e.type == "mail" then
            local dir = e.direction == "sent" and "|cFF00FF00→|r" or "|cFFFF8000←|r"
            local who = e.direction == "sent" and (e.receiver or "?") or (e.sender or "?")
            local subj = e.subject or ""
            if #subj > 30 then subj = subj:sub(1, 30) .. "..." end
            KDT:Print(string.format("  %s %s Mail %s — %s", dateStr, dir, who, subj))
        end
    end
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------
function TML:OnEvent(event, ...)
    local qol = GetQoL()
    if not qol or not qol.enableTradeMailLog then return end

    if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" or event == "MAIL_SHOW" then
        EnsureMailHooks()
    elseif event == "MAIL_SEND_SUCCESS" then
        if self.pendingSend then self:LogMail(self.pendingSend) end
        self.pendingSend = nil
    elseif event == "MAIL_FAILED" or event == "MAIL_CLOSED" then
        self.pendingSend = nil
    elseif event == "TRADE_SHOW" then
        self:StartTrade()
    elseif event == "TRADE_UPDATE" or event == "TRADE_PLAYER_ITEM_CHANGED"
        or event == "TRADE_TARGET_ITEM_CHANGED" or event == "TRADE_MONEY_CHANGED"
        or event == "PLAYER_TRADE_MONEY" then
        if self.tradeState then self:UpdateTradeSnapshot() end
    elseif event == "TRADE_ACCEPT_UPDATE" then
        if self.tradeState then
            local p, t = ...
            self.tradeState.playerAccepted = p or 0
            self.tradeState.targetAccepted = t or 0
        end
    elseif event == "TRADE_CLOSED" then
        if self.tradeState then self:FinishTrade() end
    end
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
function KDT:ShowTradeMailLog()
    local log = self.DB and self.DB.tradeMailLog
    if not log or #log == 0 then
        KDT:Print("Trade & Mail Log is empty.")
        return
    end
    
    local maxShow = 20
    local count = math.min(#log, maxShow)
    KDT:Print("|cffffd200Trade & Mail Log|r (showing " .. count .. " of " .. #log .. " entries)")
    KDT:Print("----------------------------------")
    
    for i = 1, count do
        local entry = log[i]
        if entry then
            local dateStr = entry.date or "?"
            local entryType = entry.type or "unknown"
            
            if entryType == "trade" then
                local partner = entry.partner or "Unknown"
                local status = entry.status == "completed" and "|cFF00FF00OK|r" or "|cFFFF4444Cancelled|r"
                local line = string.format("  |cFF888888%s|r |cFFFFD200Trade|r %s with |cFFFFFFFF%s|r", dateStr, status, partner)
                
                -- Items given
                if entry.playerItems and #entry.playerItems > 0 then
                    local items = {}
                    for _, item in ipairs(entry.playerItems) do
                        table.insert(items, (item.name or "?") .. (item.count > 1 and ("x" .. item.count) or ""))
                    end
                    line = line .. " | Gave: " .. table.concat(items, ", ")
                end
                -- Items received
                if entry.targetItems and #entry.targetItems > 0 then
                    local items = {}
                    for _, item in ipairs(entry.targetItems) do
                        table.insert(items, (item.name or "?") .. (item.count > 1 and ("x" .. item.count) or ""))
                    end
                    line = line .. " | Got: " .. table.concat(items, ", ")
                end
                -- Gold
                if entry.playerGold and entry.playerGold > 0 then
                    line = line .. " | Gave: " .. GetCoinTextureString(entry.playerGold)
                end
                if entry.targetGold and entry.targetGold > 0 then
                    line = line .. " | Got: " .. GetCoinTextureString(entry.targetGold)
                end
                KDT:Print(line)
                
            elseif entryType == "mail_sent" then
                local recipient = entry.recipient or "Unknown"
                local line = string.format("  |cFF888888%s|r |cFF4488FFMail Sent|r to |cFFFFFFFF%s|r", dateStr, recipient)
                if entry.subject and entry.subject ~= "" then
                    line = line .. " [" .. entry.subject .. "]"
                end
                if entry.items and #entry.items > 0 then
                    local items = {}
                    for _, item in ipairs(entry.items) do
                        table.insert(items, (item.name or "?") .. (item.count > 1 and ("x" .. item.count) or ""))
                    end
                    line = line .. " | " .. table.concat(items, ", ")
                end
                if entry.gold and entry.gold > 0 then
                    line = line .. " | " .. GetCoinTextureString(entry.gold)
                end
                KDT:Print(line)
                
            elseif entryType == "mail_received" then
                local sender = entry.sender or "Unknown"
                local line = string.format("  |cFF888888%s|r |cFF44FF88Mail Received|r from |cFFFFFFFF%s|r", dateStr, sender)
                if entry.subject and entry.subject ~= "" then
                    line = line .. " [" .. entry.subject .. "]"
                end
                if entry.items and #entry.items > 0 then
                    local items = {}
                    for _, item in ipairs(entry.items) do
                        table.insert(items, (item.name or "?") .. (item.count > 1 and ("x" .. item.count) or ""))
                    end
                    line = line .. " | " .. table.concat(items, ", ")
                end
                if entry.gold and entry.gold > 0 then
                    line = line .. " | " .. GetCoinTextureString(entry.gold)
                end
                KDT:Print(line)
            end
        end
    end
    
    if #log > maxShow then
        KDT:Print("|cFF888888... and " .. (#log - maxShow) .. " more entries.|r")
    end
end

function KDT:InitTradeMailLog()
    local qol = self.DB and self.DB.qol
    if not qol or not qol.enableTradeMailLog then return end

    frame:SetScript("OnEvent", function(_, event, ...) TML:OnEvent(event, ...) end)
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("MAIL_SHOW")
    frame:RegisterEvent("MAIL_SEND_SUCCESS")
    frame:RegisterEvent("MAIL_FAILED")
    frame:RegisterEvent("MAIL_CLOSED")
    frame:RegisterEvent("TRADE_SHOW")
    frame:RegisterEvent("TRADE_UPDATE")
    frame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
    frame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
    frame:RegisterEvent("TRADE_ACCEPT_UPDATE")
    frame:RegisterEvent("TRADE_MONEY_CHANGED")
    frame:RegisterEvent("PLAYER_TRADE_MONEY")
    frame:RegisterEvent("TRADE_CLOSED")

    EnsureMailHooks()
end
