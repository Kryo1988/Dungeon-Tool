-- Kryos Dungeon Tool
-- Modules/ChatHistory.lua - Chat History Persistence
-- Adapted from EnhanceQoL ChatIM/ChannelHistory - WoW 12.0 compatible
-- Saves chat messages across sessions and restores them on login

local _, KDT_Addon = ...
local KDT = KDT_Addon

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local CreateFrame = CreateFrame
local pairs = pairs
local ipairs = ipairs
local type = type
local time = time
local date = date
local select = select
local issecretvalue = issecretvalue

---------------------------------------------------------------------------
-- EVENT TO CHANNEL MAPPING (from original)
---------------------------------------------------------------------------
local EVENT_TO_CHANNEL = {
    CHAT_MSG_SAY = "SAY",
    CHAT_MSG_YELL = "YELL",
    CHAT_MSG_WHISPER = "WHISPER",
    CHAT_MSG_WHISPER_INFORM = "WHISPER",
    CHAT_MSG_BN_WHISPER = "BN_WHISPER",
    CHAT_MSG_BN_WHISPER_INFORM = "BN_WHISPER",
    CHAT_MSG_PARTY = "PARTY",
    CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_INSTANCE_CHAT = "INSTANCE",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "INSTANCE",
    CHAT_MSG_RAID = "RAID",
    CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_GUILD = "GUILD",
    CHAT_MSG_OFFICER = "OFFICER",
    CHAT_MSG_CHANNEL = "CHANNEL",
    CHAT_MSG_SYSTEM = "SYSTEM",
    CHAT_MSG_LOOT = "LOOT",
}

-- Which channels to save by default
local DEFAULT_SAVE = {
    WHISPER = true,
    BN_WHISPER = true,
    GUILD = true,
    PARTY = true,
    RAID = true,
    INSTANCE = true,
    SAY = true,
    OFFICER = true,
}

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------
local function GetQoL()
    return KDT.DB and KDT.DB.qol
end

local function GetHistoryDB()
    return KDT.DB and KDT.DB.chatHistoryData
end

---------------------------------------------------------------------------
-- STORAGE
---------------------------------------------------------------------------
local MAX_MESSAGES_DEFAULT = 500

local function trimHistory(channelData, maxMessages)
    maxMessages = maxMessages or MAX_MESSAGES_DEFAULT
    while #channelData > maxMessages do
        table.remove(channelData, 1)
    end
end

local function saveMessage(channel, sender, message, timestamp)
    local db = GetHistoryDB()
    if not db then return end
    local qol = GetQoL()
    local maxMsg = qol and qol.chatHistoryMaxMessages or MAX_MESSAGES_DEFAULT

    db[channel] = db[channel] or {}
    db[channel][#db[channel] + 1] = {
        msg = message,
        sender = sender,
        time = timestamp or time(),
    }
    trimHistory(db[channel], maxMsg)
end

---------------------------------------------------------------------------
-- RESTORE ON LOGIN
---------------------------------------------------------------------------
local restored = false

local function restoreChatHistory()
    if restored then return end
    restored = true

    local db = GetHistoryDB()
    if not db then return end
    local qol = GetQoL()
    if not qol or not qol.chatHistoryEnabled then return end
    local showTimestamps = qol.chatHistoryShowTimestamps

    -- Find the default chat frame
    local chatFrame = DEFAULT_CHAT_FRAME or ChatFrame1
    if not chatFrame then return end

    local totalRestored = 0
    local restoreOrder = { "GUILD", "PARTY", "RAID", "INSTANCE", "WHISPER", "BN_WHISPER", "SAY", "OFFICER" }

    for _, channel in ipairs(restoreOrder) do
        local messages = db[channel]
        if messages and #messages > 0 then
            -- Only restore recent messages (last 24 hours)
            local cutoff = time() - (24 * 60 * 60)
            local hasHeader = false

            for _, entry in ipairs(messages) do
                if entry.time and entry.time >= cutoff then
                    if not hasHeader then
                        chatFrame:AddMessage("|cFF666666--- " .. channel .. " History ---|r", 0.4, 0.4, 0.4)
                        hasHeader = true
                    end

                    local timeStr = ""
                    if showTimestamps and entry.time then
                        timeStr = "|cFF888888[" .. date("%H:%M", entry.time) .. "]|r "
                    end

                    local senderStr = entry.sender or "?"
                    local color = "FFFFFF"
                    if channel == "GUILD" then color = "40FF40"
                    elseif channel == "PARTY" then color = "AAAAFF"
                    elseif channel == "RAID" then color = "FF7F00"
                    elseif channel == "WHISPER" or channel == "BN_WHISPER" then color = "FF80FF"
                    elseif channel == "OFFICER" then color = "40C040"
                    elseif channel == "INSTANCE" then color = "FF7F4F"
                    end

                    local line = string.format("%s|cFF%s[%s]|r %s", timeStr, color, senderStr, entry.msg or "")
                    chatFrame:AddMessage(line, 0.6, 0.6, 0.6)
                    totalRestored = totalRestored + 1
                end
            end
        end
    end

    if totalRestored > 0 then
        chatFrame:AddMessage("|cFF666666--- End of History (" .. totalRestored .. " messages) ---|r", 0.4, 0.4, 0.4)
    end
end

---------------------------------------------------------------------------
-- MESSAGE CAPTURE
---------------------------------------------------------------------------
local function onChatMessage(event, message, sender, ...)
    local qol = GetQoL()
    if not qol or not qol.chatHistoryEnabled then return end

    -- Guard against secret values (WoW 12.0)
    if issecretvalue and (issecretvalue(message) or issecretvalue(sender)) then return end

    local channel = EVENT_TO_CHANNEL[event]
    if not channel then return end
    if not DEFAULT_SAVE[channel] then return end

    -- Clean sender name
    local cleanSender = sender
    if cleanSender and cleanSender:find("-") then
        local name, realm = cleanSender:match("([^-]+)-?(.*)")
        local myRealm = GetRealmName and GetRealmName():gsub("%s", "") or ""
        if realm == myRealm then cleanSender = name end
    end

    saveMessage(channel, cleanSender, message, time())
end

---------------------------------------------------------------------------
-- EVENTS
---------------------------------------------------------------------------
local chatFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    local qol = GetQoL()
    if not qol or not qol.chatHistoryEnabled then return end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Restore after a short delay to ensure chat frames are ready
        C_Timer.After(2, restoreChatHistory)
    else
        -- Chat message events
        local message, sender = ...
        onChatMessage(event, message, sender)
    end
end

chatFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Register all chat message events
for event in pairs(EVENT_TO_CHANNEL) do
    chatFrame:RegisterEvent(event)
end

chatFrame:SetScript("OnEvent", OnEvent)

---------------------------------------------------------------------------
-- CLEANUP (remove messages older than 7 days)
---------------------------------------------------------------------------
function KDT:CleanChatHistory()
    local db = GetHistoryDB()
    if not db then return end
    local cutoff = time() - (7 * 24 * 60 * 60)
    local removed = 0
    for channel, messages in pairs(db) do
        local i = 1
        while i <= #messages do
            if messages[i].time and messages[i].time < cutoff then
                table.remove(messages, i)
                removed = removed + 1
            else
                i = i + 1
            end
        end
    end
    if removed > 0 then
        KDT:Print("Chat history: removed " .. removed .. " old messages.")
    end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function KDT:ClearChatHistory()
    local db = GetHistoryDB()
    if db then
        for k in pairs(db) do
            db[k] = nil
        end
    end
    KDT:Print("Chat history cleared.")
end
