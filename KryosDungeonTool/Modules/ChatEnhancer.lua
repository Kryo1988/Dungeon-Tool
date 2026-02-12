-- Kryos Dungeon Tool
-- Modules/ChatEnhancer.lua - Dark chat skin, copy chat, class colors, URLs, channel shortening
-- Non-destructive: skins existing Blizzard frames with overlays/hooks
-- Master toggle requires /reload, sub-features toggle instantly

local _, KDT = ...

local ChatEnhancer = {}
KDT.ChatEnhancer = ChatEnhancer

---------------------------------------------------------------------------
-- UPVALUES
---------------------------------------------------------------------------
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local pairs, ipairs, type = pairs, ipairs, type
local format = string.format
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS or 10
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local UnitName = UnitName
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local issecretvalue = issecretvalue

---------------------------------------------------------------------------
-- SKIN COLORS
---------------------------------------------------------------------------
local SKIN = {
    frameBg      = { 0.06, 0.06, 0.08 },
    editBg       = { 0.04, 0.04, 0.06 },
    tabNormal    = { 0.10, 0.10, 0.13 },
    tabSelected  = { 0.20, 0.20, 0.25 },
    tabHover     = { 0.25, 0.25, 0.32 },
    btnBg        = { 0.08, 0.08, 0.10, 0.90 },
    btnHover     = { 0.15, 0.55, 0.65, 0.70 },
    accent       = { 0.23, 0.82, 0.93 },
    border       = { 0.18, 0.18, 0.22, 0.50 },
}

---------------------------------------------------------------------------
-- CONFIG HELPERS
---------------------------------------------------------------------------
local function GetCfg(key)
    local db = KDT.DB and KDT.DB.chatEnhancer
    if db and db[key] ~= nil then return db[key] end
    return nil
end

local function SetCfg(key, value)
    if KDT.DB and KDT.DB.chatEnhancer then
        KDT.DB.chatEnhancer[key] = value
    end
end

---------------------------------------------------------------------------
-- TRACKING
---------------------------------------------------------------------------
local skinnedFrames = {}
local skinnedTabs = {}
local skinnedEditBoxes = {}
local buttonBars = {}
local copyChatFrame = nil

---------------------------------------------------------------------------
-- HELPER: Iterate all chat frames
---------------------------------------------------------------------------
local function ForEachChatFrame(fn)
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if frame then fn(frame, editBox, i) end
    end
end

---------------------------------------------------------------------------
-- SKIN: Chat Frame Background
---------------------------------------------------------------------------
local function SkinChatFrame(frame, idx)
    if skinnedFrames[frame] then return end
    skinnedFrames[frame] = true

    local alpha = (GetCfg("transparency") or 18) / 100

    -- Dark background
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetColorTexture(SKIN.frameBg[1], SKIN.frameBg[2], SKIN.frameBg[3], alpha)
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
    frame._kdtBg = bg

    -- Subtle border
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetPoint("TOPLEFT", bg, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(SKIN.border[1], SKIN.border[2], SKIN.border[3], SKIN.border[4])
    border:SetFrameLevel(math.max(1, frame:GetFrameLevel() - 1))
    frame._kdtBorder = border

    -- Hide Blizzard clutter
    local scrollBar = _G["ChatFrame" .. idx .. "ScrollBar"]
    if scrollBar then scrollBar:SetAlpha(0) end

    local scrollToBottom = frame.ScrollToBottomButton or _G["ChatFrame" .. idx .. "ScrollToBottomButton"]
    if scrollToBottom then scrollToBottom:SetAlpha(0); scrollToBottom:EnableMouse(false) end

    for _, suffix in ipairs({"ButtonFrameUpButton", "ButtonFrameDownButton", "ButtonFrameBottomButton"}) do
        local btn = _G["ChatFrame" .. idx .. suffix]
        if btn then btn:SetAlpha(0); btn:EnableMouse(false) end
    end

    -- Pause fade on hover
    frame:HookScript("OnEnter", function(self) self:SetFading(false) end)
    frame:HookScript("OnLeave", function(self)
        local qol = KDT.DB and KDT.DB.qol
        if qol and qol.chatFadeEnabled then
            self:SetFading(true)
        end
    end)
end

---------------------------------------------------------------------------
-- SKIN: Tabs
---------------------------------------------------------------------------
local function SkinTab(tab, idx)
    if not tab or skinnedTabs[tab] then return end
    skinnedTabs[tab] = true

    local alpha = (GetCfg("tabTransparency") or 0) / 100

    -- Hide default textures
    for _, region in ipairs({ tab:GetRegions() }) do
        if region.SetTexture or region.SetAtlas then
            if region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
                region:SetAtlas(nil)
            end
        end
    end

    -- Custom background
    local bg = tab:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(SKIN.tabNormal[1], SKIN.tabNormal[2], SKIN.tabNormal[3], alpha)
    tab._kdtBg = bg

    -- Text styling
    local text = tab:GetFontString()
    if text then
        text:SetFont(text:GetFont() or "Fonts\\FRIZQT__.TTF", 11)
        text:SetShadowOffset(1, -1)
    end

    -- Hover/Selected states
    tab:HookScript("OnEnter", function(self)
        if self._kdtBg then
            self._kdtBg:SetColorTexture(SKIN.tabHover[1], SKIN.tabHover[2], SKIN.tabHover[3], math.max(alpha, 0.3))
        end
    end)
    tab:HookScript("OnLeave", function(self)
        if self._kdtBg then
            local isSelected = (SELECTED_CHAT_FRAME == _G["ChatFrame" .. idx])
            if isSelected then
                self._kdtBg:SetColorTexture(SKIN.tabSelected[1], SKIN.tabSelected[2], SKIN.tabSelected[3], math.max(alpha, 0.2))
            else
                self._kdtBg:SetColorTexture(SKIN.tabNormal[1], SKIN.tabNormal[2], SKIN.tabNormal[3], alpha)
            end
        end
    end)
end

local function UpdateTabStates()
    local alpha = (GetCfg("tabTransparency") or 0) / 100
    for i = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab and tab._kdtBg then
            local isSelected = (SELECTED_CHAT_FRAME == _G["ChatFrame" .. i])
            if isSelected then
                tab._kdtBg:SetColorTexture(SKIN.tabSelected[1], SKIN.tabSelected[2], SKIN.tabSelected[3], math.max(alpha, 0.2))
            else
                tab._kdtBg:SetColorTexture(SKIN.tabNormal[1], SKIN.tabNormal[2], SKIN.tabNormal[3], alpha)
            end
        end
    end
end

---------------------------------------------------------------------------
-- SKIN: Edit Box
---------------------------------------------------------------------------
local function SkinEditBox(editBox, idx)
    if not editBox or skinnedEditBoxes[editBox] then return end
    skinnedEditBoxes[editBox] = true

    -- Hide default textures
    for _, region in ipairs({ editBox:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            region:SetTexture(nil)
            region:SetAtlas(nil)
        end
    end

    -- Dark background
    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(SKIN.editBg[1], SKIN.editBg[2], SKIN.editBg[3], 0.85)

    -- Top separator line
    local sep = editBox:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, 0)
    sep:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", 0, 0)
    sep:SetColorTexture(SKIN.accent[1], SKIN.accent[2], SKIN.accent[3], 0.4)

    -- Font color
    editBox:SetTextColor(0.9, 0.9, 0.9)
end

---------------------------------------------------------------------------
-- BUTTON BAR (Copy Chat + Scroll to Bottom)
---------------------------------------------------------------------------
local function CreateButton(parent, text, tooltipText, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(22, 22)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(SKIN.btnBg[1], SKIN.btnBg[2], SKIN.btnBg[3], SKIN.btnBg[4])
    btn._bg = bg

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(0.7, 0.7, 0.7)
    btn._label = label

    btn:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(SKIN.btnHover[1], SKIN.btnHover[2], SKIN.btnHover[3], SKIN.btnHover[4])
        self._label:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltipText, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self._bg:SetColorTexture(SKIN.btnBg[1], SKIN.btnBg[2], SKIN.btnBg[3], SKIN.btnBg[4])
        self._label:SetTextColor(0.7, 0.7, 0.7)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function GetCopyChatFrame()
    if copyChatFrame then return copyChatFrame end

    local f = CreateFrame("Frame", "KDTCopyChatFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 350)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    f:SetBackdropBorderColor(SKIN.accent[1], SKIN.accent[2], SKIN.accent[3], 0.5)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- ESC to close
    f:SetScript("OnShow", function(self)
        -- Add to special frames for ESC handling
        for i = 1, #UISpecialFrames do
            if UISpecialFrames[i] == "KDTCopyChatFrame" then return end
        end
        table.insert(UISpecialFrames, "KDTCopyChatFrame")
    end)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("|cFF3BD1ECCopy Chat|r")

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetNormalFontObject("GameFontNormal")
    local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(0.8, 0.3, 0.3)
    close:SetScript("OnClick", function() f:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.4, 0.4) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(0.8, 0.3, 0.3) end)

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "KDTCopyChatScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local editBox = CreateFrame("EditBox", "KDTCopyChatEditBox", scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scroll:GetWidth() or 450)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
    scroll:SetScrollChild(editBox)

    f.editBox = editBox
    copyChatFrame = f
    return f
end

local function CopyChat(chatFrame)
    local f = GetCopyChatFrame()
    local lines = {}

    local numMessages = chatFrame:GetNumMessages()
    for i = 1, numMessages do
        local text = chatFrame:GetMessageInfo(i)
        if text and type(text) == "string" then
            -- Strip textures and color codes for clean copy
            text = text:gsub("|T[^|]+|t", "")
            text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
            text = text:gsub("|r", "")
            text = text:gsub("|H[^|]+|h", "")
            text = text:gsub("|h", "")
            lines[#lines + 1] = text
        end
    end

    f.editBox:SetText(table.concat(lines, "\n"))
    f.editBox:SetWidth(f:GetWidth() - 50)
    f:Show()
    f.editBox:HighlightText()
    f.editBox:SetFocus()
end

local function CreateButtonBar(chatFrame, idx)
    if buttonBars[idx] then return end

    local bar = CreateFrame("Frame", nil, chatFrame)
    bar:SetSize(48, 22)
    bar:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -2, -2)
    bar:SetFrameLevel(chatFrame:GetFrameLevel() + 5)

    -- Copy Chat button
    local copyBtn = CreateButton(bar, "C", "Copy Chat", function()
        CopyChat(chatFrame)
    end)
    copyBtn:SetPoint("RIGHT", bar, "RIGHT", 0, 0)

    -- Scroll to Bottom button
    local scrollBtn = CreateButton(bar, "v", "Scroll to Bottom", function()
        chatFrame:ScrollToBottom()
    end)
    scrollBtn:SetPoint("RIGHT", copyBtn, "LEFT", -2, 0)

    buttonBars[idx] = bar
end

---------------------------------------------------------------------------
-- MESSAGE FILTER: Class-Colored Names
---------------------------------------------------------------------------
local nameClassCache = {}

local function WipeClassCache()
    nameClassCache = {}
end

local function ResolveClass(name)
    if not name or name == "" then return nil end
    if nameClassCache[name] then return nameClassCache[name] end

    -- Check player
    local playerName = UnitName("player")
    if playerName and name == playerName then
        local _, class = UnitClass("player")
        if class then nameClassCache[name] = class; return class end
    end

    -- Check group
    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumGroupMembers() - 1
    end

    if prefix and count then
        for i = 1, count do
            local unit = prefix .. i
            local uName = UnitName(unit)
            if uName then
                local _, uClass = UnitClass(unit)
                if uClass then nameClassCache[uName] = uClass end
            end
        end
    end

    return nameClassCache[name]
end

local CLASS_COLOR_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER",
}

local function ClassColorFilter(self, event, message, sender, ...)
    if not GetCfg("classColors") then return false end
    if issecretvalue and issecretvalue(message) then return end
    if type(message) ~= "string" then return false end

    -- Extract name without realm
    local name = sender
    if name and name:find("-") then
        name = name:match("([^-]+)")
    end

    local class = ResolveClass(name)
    if not class or not RAID_CLASS_COLORS[class] then return false end

    local color = RAID_CLASS_COLORS[class]
    local hex = format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)

    -- Color the sender name in the message
    -- Pattern: |Hplayer:Name|h[Name]|h -> |Hplayer:Name|h[|cFFxxxxxx Name|r]|h
    local modified = message
    if name then
        modified = modified:gsub(
            "(|Hplayer:[^|]+|h%[)" .. name .. "(%]|h)",
            "%1|cFF" .. hex .. name .. "|r%2"
        )
        -- Also handle BNet and channel formats
        modified = modified:gsub(
            "(|HBNplayer:[^|]+|h%[)" .. name .. "(%]|h)",
            "%1|cFF" .. hex .. name .. "|r%2"
        )
    end

    if modified ~= message then
        return false, modified, sender, ...
    end
    return false
end

---------------------------------------------------------------------------
-- MESSAGE FILTER: Clickable URLs
---------------------------------------------------------------------------
local URL_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_SYSTEM",
}

local URL_PATTERNS = {
    "(https?://[%w%.%-_/%%?=&#:~!@$+,;]+)",
    "(www%.[%w%.%-_/%%?=&#:~!@$+,;]+)",
}

local function URLFilter(self, event, message, ...)
    if not GetCfg("clickableURLs") then return false end
    if issecretvalue and issecretvalue(message) then return end
    if type(message) ~= "string" then return false end

    local modified = message
    for _, pattern in ipairs(URL_PATTERNS) do
        modified = modified:gsub(pattern, function(url)
            -- Don't double-wrap already linked URLs
            if url:find("|H") then return url end
            return format("|cFF3BD1EC|Hgarrmission:%s|h[%s]|h|r", url, url)
        end)
    end

    if modified ~= message then
        return false, modified, ...
    end
    return false
end

-- URL click handler
local function OnHyperlinkClick(self, link, text, button)
    if not link then return end
    local url = link:match("^garrmission:(.+)")
    if not url then return end

    -- Show copy dialog
    StaticPopupDialogs["KDT_COPY_URL"] = StaticPopupDialogs["KDT_COPY_URL"] or {
        text = "Copy URL:",
        button1 = CLOSE,
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self, data)
            self.editBox:SetText(data)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("KDT_COPY_URL", nil, nil, url)
end

---------------------------------------------------------------------------
-- MESSAGE FILTER: Channel Shortening
---------------------------------------------------------------------------
local CHANNEL_SHORT = {
    -- English
    ["General"]           = "G",
    ["Trade"]             = "T",
    ["LocalDefense"]      = "D",
    ["LookingForGroup"]   = "LFG",
    ["WorldDefense"]      = "WD",
    ["Services"]          = "S",
    ["NewcomerChat"]      = "New",
    -- German
    ["Allgemein"]         = "A",
    ["Handel"]            = "H",
    ["LokaleVerteidigung"]= "LV",
    ["SucheNachGruppe"]   = "SNG",
    ["Dienste"]           = "D",
}

local CHANNEL_SHORT_EVENTS = {
    "CHAT_MSG_CHANNEL",
}

local function ChannelShortenFilter(self, event, message, sender, langName, channelName, ...)
    if not GetCfg("shortenChannels") then return false end
    if issecretvalue and issecretvalue(message) then return end
    if type(message) ~= "string" then return false end

    -- channelName comes as "1. General - Dornogal" or similar
    -- The actual channel prefix is already formatted by WoW in the message
    -- We modify the message text to shorten [1. General] to [1. G]
    local modified = message
    for long, short in pairs(CHANNEL_SHORT) do
        modified = modified:gsub("%[(%d+%.%s*)" .. long .. "%]", "[%1" .. short .. "]")
        modified = modified:gsub("%[(%d+%.%s*)" .. long .. "%s*%-%s*[^%]]+%]", "[%1" .. short .. "]")
    end

    if modified ~= message then
        return false, modified, sender, langName, channelName, ...
    end
    return false
end

---------------------------------------------------------------------------
-- FILTER REGISTRATION
---------------------------------------------------------------------------
local filtersRegistered = false

local function RegisterFilters()
    if filtersRegistered then return end
    filtersRegistered = true

    -- Class Colors
    for _, event in ipairs(CLASS_COLOR_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, ClassColorFilter)
    end

    -- Clickable URLs
    for _, event in ipairs(URL_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, URLFilter)
    end

    -- Channel Shortening
    for _, event in ipairs(CHANNEL_SHORT_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, ChannelShortenFilter)
    end

    -- URL hyperlink click handler - hook each chat frame individually (WoW 12.0)
    ForEachChatFrame(function(frame, _, idx)
        if frame and not frame._kdtURLHooked then
            frame:HookScript("OnHyperlinkClick", OnHyperlinkClick)
            frame._kdtURLHooked = true
        end
    end)
end

---------------------------------------------------------------------------
-- SKIN: Apply to all frames
---------------------------------------------------------------------------
local function ApplySkin()
    -- Hide global Blizzard chrome
    local menuBtn = ChatFrameMenuButton
    if menuBtn then menuBtn:SetAlpha(0); menuBtn:EnableMouse(false) end

    local channelBtn = ChatFrameChannelButton
    if channelBtn then channelBtn:SetAlpha(0); channelBtn:EnableMouse(false) end

    -- Social / Quick Join button
    if GetCfg("hideSocialButton") then
        local socialBtn = QuickJoinToastButton
        if socialBtn then socialBtn:SetAlpha(0); socialBtn:EnableMouse(false); socialBtn._kdtHidden = true end
    end

    ForEachChatFrame(function(frame, editBox, idx)
        SkinChatFrame(frame, idx)
        SkinTab(_G["ChatFrame" .. idx .. "Tab"], idx)
        if editBox then SkinEditBox(editBox, idx) end
        -- Button bar only on ChatFrame1
        if idx == 1 then
            CreateButtonBar(frame, idx)
        end
    end)

    -- Tab click hook for visual updates
    if FCF_Tab_OnClick then
        hooksecurefunc("FCF_Tab_OnClick", function()
            UpdateTabStates()
        end)
    end

    -- Hook new windows
    if FCF_OpenNewWindow then
        hooksecurefunc("FCF_OpenNewWindow", function()
            C_Timer.After(0.1, function()
                ForEachChatFrame(function(frame, editBox, idx)
                    SkinChatFrame(frame, idx)
                    SkinTab(_G["ChatFrame" .. idx .. "Tab"], idx)
                    if editBox then SkinEditBox(editBox, idx) end
                    -- Hook URL clicks on new frames
                    if frame and not frame._kdtURLHooked then
                        frame:HookScript("OnHyperlinkClick", OnHyperlinkClick)
                        frame._kdtURLHooked = true
                    end
                end)
            end)
        end)
    end
end

---------------------------------------------------------------------------
-- APPLY SETTINGS (runtime, no reload needed)
---------------------------------------------------------------------------
function ChatEnhancer:ApplySettings()
    local alpha = (GetCfg("transparency") or 18) / 100
    local tabAlpha = (GetCfg("tabTransparency") or 0) / 100

    -- Social / Quick Join button toggle
    local socialBtn = QuickJoinToastButton
    if socialBtn then
        if GetCfg("hideSocialButton") then
            socialBtn:SetAlpha(0); socialBtn:EnableMouse(false); socialBtn._kdtHidden = true
        elseif socialBtn._kdtHidden then
            socialBtn:SetAlpha(1); socialBtn:EnableMouse(true); socialBtn._kdtHidden = nil
        end
    end

    -- Update background alpha
    ForEachChatFrame(function(frame, _, idx)
        if frame._kdtBg then
            frame._kdtBg:SetColorTexture(SKIN.frameBg[1], SKIN.frameBg[2], SKIN.frameBg[3], alpha)
        end
    end)

    -- Update tab alpha
    UpdateTabStates()
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
function ChatEnhancer:Init()
    if not GetCfg("enabled") then return end

    -- Register message filters (these check their toggle per-message)
    RegisterFilters()

    -- Apply dark skin
    ApplySkin()

    -- Class cache wipe on roster change
    local cacheFrame = CreateFrame("Frame")
    cacheFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    cacheFrame:SetScript("OnEvent", WipeClassCache)
end
