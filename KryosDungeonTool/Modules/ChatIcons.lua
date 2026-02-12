-- Kryos Dungeon Tool
-- Modules/ChatIcons.lua - Item icons and item level display in chat messages

local _, KDT = ...

local ChatIcons = {}
KDT.ChatIcons = ChatIcons

local ICON_SIZE = 12
local ITEM_LINK_PATTERN = "|Hitem:.-|h%[.-%]|h|r"
local CURRENCY_LINK_PATTERN = "(|Hcurrency:(%d+)[^|]*|h%[[^%]]+%]|h%|r)"

local tonumber = tonumber
local format = string.format
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo or (C_Item and C_Item.GetDetailedItemLevelInfo)
local GetItemInfoFn = C_Item and C_Item.GetItemInfo or GetItemInfo

local CHAT_EVENTS_FALLBACK = {
    "CHAT_MSG_LOOT", "CHAT_MSG_CURRENCY",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER",
    "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_SYSTEM", "CHAT_MSG_ACHIEVEMENT",
    "CHAT_MSG_GUILD_ACHIEVEMENT", "CHAT_MSG_GUILD_ITEM_LOOTED",
}

local function BuildItemLinkEvents()
    local events = {}
    if type(ChatTypeGroup) == "table" then
        for _, group in pairs(ChatTypeGroup) do
            if type(group) == "table" then
                for _, event in pairs(group) do
                    events[event] = true
                end
            end
        end
    end
    for _, event in ipairs(CHAT_EVENTS_FALLBACK) do
        events[event] = true
    end
    return events
end

local function GetItemTexture(link)
    if not link then return nil end
    if GetItemIcon then
        local ok, tex = pcall(GetItemIcon, link)
        if ok and tex then return tex end
    end
    if C_Item and C_Item.GetItemIconByID then
        local id = link:match("item:(%d+)")
        if id then return C_Item.GetItemIconByID(tonumber(id)) end
    end
    return nil
end

local function AppendIcon(texture, link)
    if not texture then return link end
    return format("|T%s:%d|t%s", texture, ICON_SIZE, link)
end

local function GetItemLevelAndEquipLoc(link)
    local level
    if GetDetailedItemLevelInfo then level = GetDetailedItemLevelInfo(link) end
    local equipLoc
    if GetItemInfoFn then
        local _, _, _, baseLevel, _, _, _, _, itemEquipLoc = GetItemInfoFn(link)
        equipLoc = itemEquipLoc
        if not level or level == 0 then level = baseLevel end
    end
    if level and level > 0 then return level, equipLoc end
    return nil, equipLoc
end

local function FormatCurrencyLink(link, id)
    id = tonumber(id)
    if not id or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return link end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    local texture = info and (info.iconFileID or info.icon)
    return AppendIcon(texture, link)
end

local function FilterChatMessage(_, event, message, ...)
    if issecretvalue and issecretvalue(message) then return end
    if type(message) ~= "string" or message == "" then return false end
    
    local qol = KDT.DB and KDT.DB.qol
    if not qol then return false end
    
    local showIcons = qol.chatItemIcons
    local showIlvl = qol.chatItemLevel
    local showLoc = qol.chatItemLevelLocation
    
    if showIcons or showIlvl then
        message = message:gsub(ITEM_LINK_PATTERN, function(link)
            -- Item level suffix
            if showIlvl then
                local prefix, label, suffix = link:match("^(|Hitem:[^|]+|h)%[(.-)%](|h|r)$")
                if prefix and label and suffix then
                    local level, equipLoc = GetItemLevelAndEquipLoc(link)
                    if level and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
                        local parts = {}
                        if showLoc and _G[equipLoc] then
                            parts[#parts + 1] = _G[equipLoc]
                        end
                        parts[#parts + 1] = tostring(level)
                        local suffixText = table.concat(parts, " ")
                        if suffixText ~= "" then
                            link = prefix .. "[" .. label .. " (" .. suffixText .. ")]" .. suffix
                        end
                    end
                end
            end
            -- Item icon
            if showIcons then
                link = AppendIcon(GetItemTexture(link), link)
            end
            return link
        end)
    end
    
    -- Currency icons
    if showIcons and (event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_CURRENCY") then
        message = message:gsub(CURRENCY_LINK_PATTERN, FormatCurrencyLink)
    end
    
    return false, message, ...
end

ChatIcons.registeredEvents = {}

function ChatIcons:UpdateFilters()
    local qol = KDT.DB and KDT.DB.qol
    local needed = {}
    if qol and (qol.chatItemIcons or qol.chatItemLevel) then
        self.itemLinkEvents = self.itemLinkEvents or BuildItemLinkEvents()
        for event in pairs(self.itemLinkEvents) do
            needed[event] = true
        end
    end
    if qol and qol.chatItemIcons then
        needed["CHAT_MSG_LOOT"] = true
        needed["CHAT_MSG_CURRENCY"] = true
    end

    for event in pairs(self.registeredEvents) do
        if not needed[event] then
            ChatFrame_RemoveMessageEventFilter(event, FilterChatMessage)
            self.registeredEvents[event] = nil
        end
    end
    for event in pairs(needed) do
        if not self.registeredEvents[event] then
            ChatFrame_AddMessageEventFilter(event, FilterChatMessage)
            self.registeredEvents[event] = true
        end
    end
end

function KDT:UpdateChatIcons()
    self.ChatIcons:UpdateFilters()
end
