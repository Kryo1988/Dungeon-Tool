-- Kryos Dungeon Tool v1.2
local addonName = "KryosDungeonTool"
local DB
local alreadyAlerted = {}
local MainFrame

-- Data
local CLASS_COLORS = {
    WARRIOR={0.78,0.61,0.43}, PALADIN={0.96,0.55,0.73}, HUNTER={0.67,0.83,0.45},
    ROGUE={1,0.96,0.41}, PRIEST={1,1,1}, DEATHKNIGHT={0.77,0.12,0.23},
    SHAMAN={0,0.44,0.87}, MAGE={0.25,0.78,0.92}, WARLOCK={0.53,0.53,0.93},
    MONK={0,1,0.6}, DRUID={1,0.49,0.04}, DEMONHUNTER={0.64,0.19,0.79}, EVOKER={0.2,0.58,0.5}
}
local CLASS_NAMES = {
    WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest",
    DEATHKNIGHT="Death Knight", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock",
    MONK="Monk", DRUID="Druid", DEMONHUNTER="Demon Hunter", EVOKER="Evoker"
}
local BATTLE_REZ = {DRUID=true, DEATHKNIGHT=true, WARLOCK=true, PALADIN=true}
local BLOODLUST = {SHAMAN=true, MAGE=true, HUNTER=true, EVOKER=true}
local ROLE_ICONS = {
    TANK="|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",
    HEALER="|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
    DAMAGER="|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"
}
local DUNGEON_NAMES = {[2830]="ED",[2831]="AK",[2832]="DB",[2833]="OF",[2834]="PSF",[2835]="HOA",[2836]="SOW",[2837]="SG"}

local function InitDB()
    if not KryosDungeonToolDB then
        KryosDungeonToolDB = {blacklist={}, settings={countdownSeconds=10, autoPost=false, customSound=true}, minimapPos=220}
    end
    DB = KryosDungeonToolDB
    DB.settings = DB.settings or {countdownSeconds=10, autoPost=false, customSound=true}
    DB.blacklist = DB.blacklist or {}
end

local function GetClassColorHex(class)
    local c = CLASS_COLORS[class] or {1,1,1}
    return string.format("%02x%02x%02x", c[1]*255, c[2]*255, c[3]*255)
end

local function IsBlacklisted(name)
    if not name or not DB then return false end
    return DB.blacklist[name:gsub("%-.*", "")] ~= nil
end

local function AddToBlacklist(name, reason)
    if not name or name == "" then return end
    name = name:gsub("^%l", string.upper):gsub("%-.*", "")
    DB.blacklist[name] = {reason = reason or "No reason", timestamp = time()}
    print("|cFFFF0000[Kryos]|r Added: " .. name)
end

local function RemoveFromBlacklist(name)
    if not name then return end
    local cleanName = name:gsub("%-.*", "")
    DB.blacklist[cleanName] = nil
    alreadyAlerted[cleanName] = nil
    print("|cFFFF0000[Kryos]|r Removed: " .. cleanName)
end

-- Share
C_ChatInfo.RegisterAddonMessagePrefix("KryosDT")

local function ShareBlacklist()
    if not IsInGroup() then print("|cFFFF0000[Kryos]|r Not in a group.") return end
    local count = 0
    local channel = IsInRaid() and "RAID" or "PARTY"
    for name, info in pairs(DB.blacklist) do
        C_ChatInfo.SendAddonMessage("KryosDT", "BL:"..name..":"..((info.reason or ""):gsub("[|:]", " ")), channel)
        count = count + 1
    end
    if count == 0 then print("|cFFFF0000[Kryos]|r Blacklist is empty.")
    else print("|cFF00FF00[Kryos]|r Shared "..count.." players.") end
end

local function ReceiveBlacklist(msg, sender)
    if not msg:match("^BL:") then return end
    if sender:gsub("%-.*", "") == UnitName("player") then return end
    local name, reason = msg:match("^BL:([^:]+):(.*)$")
    if name and not DB.blacklist[name] then
        DB.blacklist[name] = {reason = (reason or "").." (from "..sender:gsub("%-.*", "")..")", timestamp = time()}
        print("|cFF00FF00[Kryos]|r Received: "..name.." from "..sender:gsub("%-.*", ""))
    end
end

local function GetKeystoneInfo(unit)
    if not unit or not UnitExists(unit) then return nil end
    if UnitIsUnit(unit, "player") then
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        if mapID then
            local level = C_MythicPlus.GetOwnedKeystoneLevel() or 0
            return {level=level, text=(DUNGEON_NAMES[mapID] or "???").." +"..level}
        end
    else
        local idx = tonumber(unit:match("party(%d+)"))
        if idx then
            local mapID, level = C_MythicPlus.GetPartyKeystoneInfo(idx)
            if mapID and level and level > 0 then
                return {level=level, text=(DUNGEON_NAMES[mapID] or "???").." +"..level}
            end
        end
    end
    return nil
end

local function GetGroupMembers()
    local members = {}
    
    -- Player
    local pName = UnitName("player") or "Unknown"
    local _, pClass = UnitClass("player")
    pClass = pClass or "WARRIOR"
    local pRole = UnitGroupRolesAssigned("player") or "DAMAGER"
    if pRole == "" or pRole == "NONE" then pRole = "DAMAGER" end
    
    local pSpec = "Unknown"
    local specIdx = GetSpecialization()
    if specIdx then 
        local _, sn = GetSpecializationInfo(specIdx)
        if sn then pSpec = sn end
    end
    
    local pKey = nil
    pcall(function() pKey = GetKeystoneInfo("player") end)
    
    members[1] = {
        name = pName,
        class = pClass,
        role = pRole,
        spec = pSpec,
        keystone = pKey
    }
    
    -- Party members
    for i = 1, 4 do
        local unit = "party"..i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                local _, class = UnitClass(unit)
                class = class or "WARRIOR"
                
                local role = UnitGroupRolesAssigned(unit) or "DAMAGER"
                if role == "" or role == "NONE" then role = "DAMAGER" end
                
                local specText = "DPS"
                if role == "TANK" then specText = "Tank"
                elseif role == "HEALER" then specText = "Healer" end
                
                local key = nil
                pcall(function() key = GetKeystoneInfo(unit) end)
                
                local cleanName = name
                if name:find("-") then
                    cleanName = name:gsub("%-.*", "")
                end
                
                members[#members + 1] = {
                    name = cleanName,
                    class = class,
                    role = role,
                    spec = specText,
                    keystone = key
                }
            end
        end
    end
    
    return members
end

local function AnalyzeGroup(members)
    local info = {tanks=0, healers=0, dps=0, hasBR=false, brClasses={}, hasBL=false, blClasses={}, stacking={}}
    local counts = {}
    for _, m in ipairs(members) do
        if m.role == "TANK" then info.tanks = info.tanks + 1
        elseif m.role == "HEALER" then info.healers = info.healers + 1
        else info.dps = info.dps + 1 end
        counts[m.class] = (counts[m.class] or 0) + 1
        if BATTLE_REZ[m.class] then info.hasBR = true; info.brClasses[m.class] = true end
        if BLOODLUST[m.class] then info.hasBL = true; info.blClasses[m.class] = true end
    end
    for c, n in pairs(counts) do if n > 1 then info.stacking[#info.stacking+1] = n.."x "..(CLASS_NAMES[c] or c) end end
    return info
end

local function PostToChat()
    local members = GetGroupMembers()
    
    if #members < 2 then print("|cFFFF0000[Kryos]|r Need 2+ players.") return end
    
    local ch = nil
    if IsInRaid() then 
        ch = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then 
        ch = "INSTANCE_CHAT"
    elseif IsInGroup() then 
        ch = "PARTY"
    end
    
    if not ch then print("|cFFFF0000[Kryos]|r Not in group.") return end
    
    local info = AnalyzeGroup(members)
    
    -- Build all messages first
    local messages = {}
    messages[#messages+1] = "====== GROUP CHECK ======"
    
    for i, m in ipairs(members) do
        local utilities = {}
        if m.class and BATTLE_REZ[m.class] then 
            utilities[#utilities+1] = "BR" 
        end
        if m.class and BLOODLUST[m.class] then 
            utilities[#utilities+1] = "BL" 
        end
        
        local utilStr = ""
        if #utilities > 0 then 
            utilStr = " ["..table.concat(utilities, "/").."]" 
        end
        
        local keyStr = ""
        if m.keystone and m.keystone.text then 
            keyStr = " | "..m.keystone.text 
        end
        
        local playerName = m.name or "Unknown"
        local className = "Unknown"
        if m.class and CLASS_NAMES[m.class] then
            className = CLASS_NAMES[m.class]
        elseif m.class then
            className = m.class
        end
        local specName = m.spec or "Unknown"
        
        messages[#messages+1] = playerName.." - "..className.." ("..specName..")"..utilStr..keyStr
    end
    
    if not info.hasBR then
        messages[#messages+1] = "[X] NO Battle Rez!"
    end
    if not info.hasBL then
        messages[#messages+1] = "[X] NO Bloodlust!"
    end
    
    messages[#messages+1] = "========================="
    
    -- Send with delay
    local delay = 0
    for i, msg in ipairs(messages) do
        C_Timer.After(delay, function()
            SendChatMessage(msg, ch)
        end)
        delay = delay + 0.3
    end
    
    C_Timer.After(delay, function()
        print("|cFF00FF00[Kryos]|r Posted to "..ch)
    end)
end

local function AnnouncePlayerJoin(name, class, spec)
    local ch = nil
    if IsInRaid() then 
        ch = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then 
        ch = "INSTANCE_CHAT"
    elseif IsInGroup() then 
        ch = "PARTY"
    end
    
    if not ch then return end
    
    local utilities = {}
    if BATTLE_REZ[class] then utilities[#utilities+1] = "BR" end
    if BLOODLUST[class] then utilities[#utilities+1] = "BL" end
    
    local utilStr = ""
    if #utilities > 0 then 
        utilStr = " - brings "..table.concat(utilities, " & ") 
    end
    
    local className = CLASS_NAMES[class] or class or "Unknown"
    local specName = spec or "Unknown"
    
    SendChatMessage("[+] "..name.." joined ("..className.." - "..specName..")"..utilStr, ch)
end

local function StartCountdown()
    if IsInGroup() then C_PartyInfo.DoCountdown(DB.settings.countdownSeconds or 10)
    else print("|cFFFF0000[Kryos]|r Need group.") end
end

-- Track known members for auto-post
local knownMembers = {}

local function CheckBlacklistAlert()
    local current = {}
    for i = 1, 4 do
        local name = UnitName("party"..i)
        if name then
            local clean = name:gsub("%-.*", "")
            current[clean] = true
            if IsBlacklisted(clean) and not alreadyAlerted[clean] then
                alreadyAlerted[clean] = true
                local d = DB.blacklist[clean]
                print("|cFFFF0000[Kryos ALERT]|r "..clean.." is blacklisted! Reason: "..(d and d.reason or "?"))
                if DB.settings.customSound then
                    PlaySoundFile("Interface\\AddOns\\KryosDungeonTool\\intruder.mp3", "Master")
                else
                    PlaySound(SOUNDKIT.RAID_WARNING, "Master")
                end
            end
        end
    end
    for name in pairs(alreadyAlerted) do
        if not current[name] then alreadyAlerted[name] = nil end
    end
end

local function CheckNewMembers()
    if not DB or not DB.settings.autoPost then return end
    
    local current = {}
    for i = 1, 4 do
        local unit = "party"..i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                local clean = name:gsub("%-.*", "")
                local _, class = UnitClass(unit)
                class = class or "WARRIOR"
                local role = UnitGroupRolesAssigned(unit) or "DAMAGER"
                if role == "" or role == "NONE" then role = "DAMAGER" end
                local spec = (role == "TANK" and "Tank") or (role == "HEALER" and "Healer") or "DPS"
                
                current[clean] = {class = class, spec = spec}
                
                -- Check if new
                if not knownMembers[clean] then
                    AnnouncePlayerJoin(clean, class, spec)
                end
            end
        end
    end
    
    -- Update known members
    knownMembers = current
end

-- ==================== UI ====================
local function CreateMainFrame()
    local f = CreateFrame("Frame", "KryosDTMain", UIParent, "BackdropTemplate")
    f:SetSize(700, 550)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
    f:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    f:Hide()
    
    f.currentTab = "group"
    f.groupElements = {}
    f.blacklistElements = {}
    f.memberRows = {}
    f.blRows = {}
    
    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetSize(700, 40)
    titleBar:SetPoint("TOP")
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    
    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 12, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_SealOfKings")
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    title:SetText("|cFFFFFFFFKRYOS DUNGEON TOOL|r")
    
    local ver = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ver:SetPoint("LEFT", title, "RIGHT", 8, 0)
    ver:SetText("v1.2")
    ver:SetTextColor(0.5, 0.5, 0.5)
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPoint("RIGHT", -5, 0)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
    closeBtn.text:SetPoint("CENTER", 0, 2)
    closeBtn.text:SetText("×")
    closeBtn.text:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeBtn.text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeBtn.text:SetTextColor(0.6, 0.6, 0.6) end)
    
    -- Tab Buttons
    local function CreateTab(text, xPos)
        local tab = CreateFrame("Button", nil, f, "BackdropTemplate")
        tab:SetSize(150, 28)
        tab:SetPoint("TOPLEFT", 10 + xPos, -45)
        tab:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(text)
        tab.indicator = tab:CreateTexture(nil, "OVERLAY")
        tab.indicator:SetSize(150, 2)
        tab.indicator:SetPoint("BOTTOM")
        tab.indicator:SetColorTexture(0.8, 0.2, 0.2, 1)
        return tab
    end
    
    f.groupTab = CreateTab("GROUP CHECK", 0)
    f.blacklistTab = CreateTab("BLACKLIST", 155)
    
    -- Content Area
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 0, -78)
    f.content:SetPoint("BOTTOMRIGHT", 0, 0)
    
    return f
end

local function CreateButton(parent, text, w, h)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.25, 0.25, 0.30, 1) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.15, 0.18, 1) end)
    return btn
end

local function CreateInput(parent, w)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(w, 22)
    box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    box:SetBackdropColor(0.1, 0.1, 0.12, 1)
    box:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
    box:SetFontObject("GameFontNormalSmall")
    box:SetTextInsets(5, 5, 0, 0)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

-- ==================== GROUP CHECK ELEMENTS ====================
local function CreateGroupElements(f)
    local e = f.groupElements
    local c = f.content
    
    -- Overview Box
    e.box = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.box:SetPoint("TOPLEFT", 10, -5)
    e.box:SetPoint("TOPRIGHT", -10, -5)
    e.box:SetHeight(125)
    e.box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    e.box:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.box:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    e.title = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.title:SetPoint("TOPLEFT", 10, -8)
    e.title:SetText("GROUP OVERVIEW")
    e.title:SetTextColor(0.8, 0.8, 0.8)
    
    e.roleText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.roleText:SetPoint("TOPLEFT", 10, -28)
    
    e.rezText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.rezText:SetPoint("TOPLEFT", 10, -46)
    
    e.blText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.blText:SetPoint("TOPLEFT", 10, -62)
    
    e.stackText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.stackText:SetPoint("TOPLEFT", 10, -78)
    
    e.keyText = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.keyText:SetPoint("TOPLEFT", 10, -94)
    e.keyText:SetWidth(320)
    e.keyText:SetJustifyH("LEFT")
    
    -- Buttons
    e.readyBtn = CreateButton(e.box, "Ready Check", 95, 22)
    e.readyBtn:SetPoint("TOPRIGHT", -110, -20)
    e.readyBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
    e.readyBtn:SetScript("OnClick", function() if IsInGroup() then DoReadyCheck() end end)
    e.readyBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.55, 0.2, 1) end)
    e.readyBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.45, 0.15, 1) end)
    
    e.postBtn = CreateButton(e.box, "Post to Chat", 95, 22)
    e.postBtn:SetPoint("TOPRIGHT", -10, -20)
    e.postBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.postBtn:SetScript("OnClick", PostToChat)
    e.postBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.45, 0.7, 1) end)
    e.postBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.35, 0.6, 1) end)
    
    e.cdBtn = CreateButton(e.box, "Countdown", 95, 22)
    e.cdBtn:SetPoint("TOP", e.readyBtn, "BOTTOM", 0, -5)
    e.cdBtn:SetBackdropColor(0.5, 0.35, 0.1, 1)
    e.cdBtn:SetScript("OnClick", StartCountdown)
    e.cdBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.45, 0.15, 1) end)
    e.cdBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.35, 0.1, 1) end)
    
    e.secLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.secLabel:SetPoint("TOP", e.cdBtn, "BOTTOM", -12, -5)
    e.secLabel:SetText("Sec:")
    e.secLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.secInput = CreateInput(e.box, 30)
    e.secInput:SetPoint("LEFT", e.secLabel, "RIGHT", 5, 0)
    e.secInput:SetNumeric(true)
    e.secInput:SetMaxLetters(2)
    e.secInput:SetText("10")
    e.secInput:SetScript("OnEnterPressed", function(self)
        local v = math.max(1, math.min(60, tonumber(self:GetText()) or 10))
        DB.settings.countdownSeconds = v
        self:SetText(tostring(v))
        self:ClearFocus()
    end)
    
    e.autoCheck = CreateFrame("CheckButton", nil, e.box, "UICheckButtonTemplate")
    e.autoCheck:SetSize(20, 20)
    e.autoCheck:SetPoint("TOP", e.postBtn, "BOTTOM", -20, -3)
    e.autoCheck.Text:SetText("Auto-Post")
    e.autoCheck.Text:SetFontObject("GameFontNormalSmall")
    e.autoCheck:SetScript("OnClick", function(self) DB.settings.autoPost = self:GetChecked() end)
    
    -- Members
    e.membersTitle = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.membersTitle:SetPoint("TOPLEFT", e.box, "BOTTOMLEFT", 0, -10)
    e.membersTitle:SetText("GROUP MEMBERS")
    e.membersTitle:SetTextColor(0.8, 0.8, 0.8)
    
    e.scroll = CreateFrame("ScrollFrame", "KryosDTGroupScroll", c, "UIPanelScrollFrameTemplate")
    e.scroll:SetPoint("TOPLEFT", e.membersTitle, "BOTTOMLEFT", 0, -5)
    e.scroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -28, 45)
    
    e.scrollChild = CreateFrame("Frame", nil, e.scroll)
    e.scrollChild:SetSize(640, 1)
    e.scroll:SetScrollChild(e.scrollChild)
    
    e.refreshBtn = CreateButton(c, "Refresh", 80, 22)
    e.refreshBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.refreshBtn:SetScript("OnClick", function() f:RefreshGroup() end)
end

-- ==================== BLACKLIST ELEMENTS ====================
local function CreateBlacklistElements(f)
    local e = f.blacklistElements
    local c = f.content
    
    -- Add Box
    e.box = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.box:SetPoint("TOPLEFT", 10, -5)
    e.box:SetPoint("TOPRIGHT", -10, -5)
    e.box:SetHeight(75)
    e.box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    e.box:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.box:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    e.title = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.title:SetPoint("TOPLEFT", 10, -8)
    e.title:SetText("ADD PLAYER")
    e.title:SetTextColor(0.8, 0.8, 0.8)
    
    e.nameLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.nameLabel:SetPoint("TOPLEFT", 10, -28)
    e.nameLabel:SetText("Player Name")
    e.nameLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.nameInput = CreateInput(e.box, 130)
    e.nameInput:SetPoint("TOPLEFT", 10, -42)
    e.nameInput:SetMaxLetters(12)
    
    e.reasonLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.reasonLabel:SetPoint("TOPLEFT", 155, -28)
    e.reasonLabel:SetText("Reason")
    e.reasonLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.reasonInput = CreateInput(e.box, 340)
    e.reasonInput:SetPoint("TOPLEFT", 155, -42)
    e.reasonInput:SetMaxLetters(100)
    
    e.addBtn = CreateButton(e.box, "Add", 70, 22)
    e.addBtn:SetPoint("TOPLEFT", 510, -42)
    e.addBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.addBtn:SetScript("OnClick", function()
        local n = e.nameInput:GetText()
        if n and n ~= "" then
            AddToBlacklist(n, e.reasonInput:GetText())
            e.nameInput:SetText("")
            e.reasonInput:SetText("")
            f:RefreshBlacklist()
        end
    end)
    e.addBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.45, 0.7, 1) end)
    e.addBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.35, 0.6, 1) end)
    
    e.nameInput:SetScript("OnEnterPressed", function() e.reasonInput:SetFocus() end)
    e.reasonInput:SetScript("OnEnterPressed", function() e.addBtn:Click() end)
    
    -- List
    e.listTitle = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.listTitle:SetPoint("TOPLEFT", e.box, "BOTTOMLEFT", 0, -10)
    e.listTitle:SetText("BLACKLISTED PLAYERS")
    e.listTitle:SetTextColor(0.8, 0.8, 0.8)
    
    e.scroll = CreateFrame("ScrollFrame", "KryosDTBlacklistScroll", c, "UIPanelScrollFrameTemplate")
    e.scroll:SetPoint("TOPLEFT", e.listTitle, "BOTTOMLEFT", 0, -5)
    e.scroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -28, 45)
    
    e.scrollChild = CreateFrame("Frame", nil, e.scroll)
    e.scrollChild:SetSize(640, 1)
    e.scroll:SetScrollChild(e.scrollChild)
    
    -- Bottom Buttons
    e.clearBtn = CreateButton(c, "Clear All", 80, 22)
    e.clearBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.clearBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
    e.clearBtn:SetScript("OnClick", function()
        StaticPopupDialogs["KRYOS_CLEAR"] = {
            text = "Clear blacklist?", button1 = "Yes", button2 = "No",
            OnAccept = function() DB.blacklist = {}; wipe(alreadyAlerted); f:RefreshBlacklist() end,
            timeout = 0, whileDead = true, hideOnEscape = true
        }
        StaticPopup_Show("KRYOS_CLEAR")
    end)
    e.clearBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.2, 0.2, 1) end)
    e.clearBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 1) end)
    
    e.shareBtn = CreateButton(c, "Share List", 80, 22)
    e.shareBtn:SetPoint("LEFT", e.clearBtn, "RIGHT", 10, 0)
    e.shareBtn:SetBackdropColor(0.15, 0.4, 0.15, 1)
    e.shareBtn:SetScript("OnClick", ShareBlacklist)
    e.shareBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.5, 0.2, 1) end)
    e.shareBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.4, 0.15, 1) end)
    
    e.soundCheck = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    e.soundCheck:SetSize(20, 20)
    e.soundCheck:SetPoint("LEFT", e.shareBtn, "RIGHT", 15, 0)
    e.soundCheck.Text:SetText("Custom Sound")
    e.soundCheck.Text:SetFontObject("GameFontNormalSmall")
    e.soundCheck:SetScript("OnClick", function(self) DB.settings.customSound = self:GetChecked() end)
end

-- ==================== SHOW/HIDE & REFRESH ====================
local function SetupMainFrame(f)
    -- Show/Hide functions for elements
    local function ShowGroupElements()
        for _, el in pairs(f.groupElements) do
            if el.Show then el:Show() end
        end
    end
    
    local function HideGroupElements()
        for _, el in pairs(f.groupElements) do
            if el.Hide then el:Hide() end
        end
    end
    
    local function ShowBlacklistElements()
        for _, el in pairs(f.blacklistElements) do
            if el.Show then el:Show() end
        end
    end
    
    local function HideBlacklistElements()
        for _, el in pairs(f.blacklistElements) do
            if el.Hide then el:Hide() end
        end
    end
    
    -- Tab switching
    function f:SwitchTab(tab)
        self.currentTab = tab
        
        -- Update tab appearance
        if tab == "group" then
            self.groupTab:SetBackdropColor(0.15, 0.15, 0.18, 1)
            self.groupTab:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
            self.groupTab.text:SetTextColor(1, 1, 1)
            self.groupTab.indicator:Show()
            
            self.blacklistTab:SetBackdropColor(0.08, 0.08, 0.10, 1)
            self.blacklistTab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
            self.blacklistTab.text:SetTextColor(0.5, 0.5, 0.5)
            self.blacklistTab.indicator:Hide()
            
            HideBlacklistElements()
            ShowGroupElements()
            self:RefreshGroup()
        else
            self.blacklistTab:SetBackdropColor(0.15, 0.15, 0.18, 1)
            self.blacklistTab:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
            self.blacklistTab.text:SetTextColor(1, 1, 1)
            self.blacklistTab.indicator:Show()
            
            self.groupTab:SetBackdropColor(0.08, 0.08, 0.10, 1)
            self.groupTab:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
            self.groupTab.text:SetTextColor(0.5, 0.5, 0.5)
            self.groupTab.indicator:Hide()
            
            HideGroupElements()
            ShowBlacklistElements()
            self:RefreshBlacklist()
        end
    end
    
    -- Refresh Group
    function f:RefreshGroup()
        local e = self.groupElements
        
        -- Clear member rows
        for _, row in ipairs(self.memberRows) do
            row:Hide()
            row:ClearAllPoints()
        end
        wipe(self.memberRows)
        
        -- Get data
        local members = GetGroupMembers()
        local info = AnalyzeGroup(members)
        
        -- Update UI
        e.secInput:SetText(tostring(DB.settings.countdownSeconds or 10))
        e.autoCheck:SetChecked(DB.settings.autoPost or false)
        
        e.roleText:SetText(ROLE_ICONS.TANK.." "..info.tanks.."  "..ROLE_ICONS.HEALER.." "..info.healers.."  "..ROLE_ICONS.DAMAGER.." "..info.dps)
        
        if info.hasBR then
            local t = {} for c in pairs(info.brClasses) do t[#t+1] = "|cFF"..GetClassColorHex(c)..(CLASS_NAMES[c] or c).."|r" end
            e.rezText:SetText("|cFF00FF00[+]|r Battle Rez: "..table.concat(t, ", "))
        else e.rezText:SetText("|cFFFF4444[X] NO Battle Rez!|r") end
        
        if info.hasBL then
            local t = {} for c in pairs(info.blClasses) do t[#t+1] = "|cFF"..GetClassColorHex(c)..(CLASS_NAMES[c] or c).."|r" end
            e.blText:SetText("|cFF00FF00[+]|r Bloodlust: "..table.concat(t, ", "))
        else e.blText:SetText("|cFFFF4444[X] NO Bloodlust!|r") end
        
        e.stackText:SetText(#info.stacking > 0 and "|cFFFFCC00[!]|r Stacking: "..table.concat(info.stacking, ", ") or "|cFF00FF00[+]|r No stacking")
        
        local keys = {} for _, m in ipairs(members) do if m.keystone then
            local kc = m.keystone.level >= 12 and "|cFFFF8000" or m.keystone.level >= 10 and "|cFFA335EE" or "|cFF0070DD"
            keys[#keys+1] = kc..m.keystone.text.."|r"
        end end
        e.keyText:SetText(#keys > 0 and "|cFFFFD100[Key]|r "..table.concat(keys, ", ") or "|cFF666666No keys|r")
        
        -- Create member rows
        local yOffset = 0
        for i, m in ipairs(members) do
            local row = CreateFrame("Frame", "KryosMemberRow"..i, e.scrollChild, "BackdropTemplate")
            row:SetSize(640, 34)
            row:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", 0, yOffset)
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
            row:SetBackdropColor(i%2==0 and 0.07 or 0.05, i%2==0 and 0.07 or 0.05, i%2==0 and 0.09 or 0.07, 0.95)
            row:Show()
            
            local role = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            role:SetPoint("LEFT", 8, 0)
            role:SetText(ROLE_ICONS[m.role] or ROLE_ICONS.DAMAGER)
            
            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("LEFT", 32, 0)
            name:SetText("|cFF"..GetClassColorHex(m.class)..(m.name or "?").."|r")
            
            local class = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            class:SetPoint("LEFT", 155, 0)
            class:SetText(CLASS_NAMES[m.class] or "?")
            class:SetTextColor(0.5, 0.5, 0.5)
            
            local spec = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            spec:SetPoint("LEFT", 265, 0)
            spec:SetText(m.spec or "?")
            spec:SetTextColor(0.4, 0.4, 0.4)
            
            local key = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            key:SetPoint("LEFT", 360, 0)
            if m.keystone then
                local kc = m.keystone.level >= 12 and "|cFFFF8000" or m.keystone.level >= 10 and "|cFFA335EE" or "|cFF0070DD"
                key:SetText(kc.."[Key] "..m.keystone.text.."|r")
            else key:SetText("|cFF444444No Key|r") end
            
            local util = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            util:SetPoint("RIGHT", -8, 0)
            local u = {}
            if BATTLE_REZ[m.class] then u[#u+1] = "|cFF00DD00BR|r" end
            if BLOODLUST[m.class] then u[#u+1] = "|cFFFF8800BL|r" end
            util:SetText(table.concat(u, " "))
            
            if IsBlacklisted(m.name) then
                local warn = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                warn:SetPoint("RIGHT", -45, 0)
                warn:SetText("|cFFFF0000[!]|r")
            end
            
            self.memberRows[#self.memberRows+1] = row
            yOffset = yOffset - 36
        end
        
        e.scrollChild:SetHeight(math.max(1, math.abs(yOffset)))
    end
    
    -- Refresh Blacklist
    function f:RefreshBlacklist()
        local e = self.blacklistElements
        
        e.soundCheck:SetChecked(DB.settings.customSound ~= false)
        
        for _, row in ipairs(self.blRows) do
            row:Hide()
            row:ClearAllPoints()
        end
        wipe(self.blRows)
        
        local sorted = {}
        for name, data in pairs(DB.blacklist) do
            sorted[#sorted+1] = {name=name, data=data}
        end
        table.sort(sorted, function(a,b) return a.name < b.name end)
        
        local yOffset = 0
        for _, entry in ipairs(sorted) do
            local row = CreateFrame("Frame", nil, e.scrollChild, "BackdropTemplate")
            row:SetSize(640, 42)
            row:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", 0, yOffset)
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
            row:SetBackdropColor(0.07, 0.07, 0.09, 0.95)
            
            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("TOPLEFT", 10, -8)
            name:SetText("|cFFFF6666"..entry.name.."|r")
            
            local reason = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            reason:SetPoint("TOPLEFT", 10, -24)
            reason:SetWidth(550)
            reason:SetJustifyH("LEFT")
            reason:SetText(entry.data.reason or "No reason")
            reason:SetTextColor(0.5, 0.5, 0.5)
            
            local delBtn = CreateButton(row, "Delete", 55, 20)
            delBtn:SetPoint("RIGHT", -8, 0)
            delBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
            delBtn:SetScript("OnClick", function()
                RemoveFromBlacklist(entry.name)
                f:RefreshBlacklist()
            end)
            delBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.2, 0.2, 1) end)
            delBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 1) end)
            
            self.blRows[#self.blRows+1] = row
            yOffset = yOffset - 45
        end
        
        if #sorted == 0 then
            local empty = e.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            empty:SetPoint("TOP", e.scrollChild, "TOP", 0, -30)
            empty:SetText("Blacklist is empty")
            empty:SetTextColor(0.4, 0.4, 0.4)
            local frame = CreateFrame("Frame", nil, e.scrollChild)
            frame.text = empty
            self.blRows[#self.blRows+1] = frame
        end
        
        e.scrollChild:SetHeight(math.max(1, math.abs(yOffset)))
    end
    
    -- Tab click handlers
    f.groupTab:SetScript("OnClick", function() f:SwitchTab("group") end)
    f.blacklistTab:SetScript("OnClick", function() f:SwitchTab("blacklist") end)
end

-- ==================== MINIMAP ====================
local minimapBtn = CreateFrame("Button", "KryosDTMinimap", Minimap)
minimapBtn:SetSize(32, 32)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetMovable(true)

local mmIcon = minimapBtn:CreateTexture(nil, "BACKGROUND")
mmIcon:SetSize(20, 20)
mmIcon:SetPoint("CENTER", 0, 1)
mmIcon:SetTexture("Interface\\Icons\\Spell_Shadow_SealOfKings")

local mmBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(52, 52)
mmBorder:SetPoint("TOPLEFT")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdateMinimapPos()
    local angle = math.rad(DB and DB.minimapPos or 220)
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle)*80, math.sin(angle)*80)
end

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        local a = math.deg(math.atan2(py/s - my, px/s - mx))
        if a < 0 then a = a + 360 end
        if DB then DB.minimapPos = a end
        UpdateMinimapPos()
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
minimapBtn:SetScript("OnClick", function(_, btn)
    if MainFrame then
        if MainFrame:IsShown() then MainFrame:Hide()
        else MainFrame:Show(); MainFrame:SwitchTab(btn=="RightButton" and "blacklist" or "group") end
    end
end)
minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Kryos Dungeon Tool")
    GameTooltip:AddLine("Left: Group | Right: Blacklist", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ==================== SLASH ====================
SLASH_KDT1 = "/kdt"
SLASH_KDT2 = "/kryos"
SlashCmdList["KDT"] = function(msg)
    local cmd = (msg or ""):lower():match("^(%S*)")
    if cmd == "" then MainFrame:Show(); MainFrame:SwitchTab("group")
    elseif cmd == "bl" or cmd == "blacklist" then MainFrame:Show(); MainFrame:SwitchTab("blacklist")
    elseif cmd == "cd" then StartCountdown()
    elseif cmd == "ready" then if IsInGroup() then DoReadyCheck() end
    elseif cmd == "post" then PostToChat()
    elseif cmd == "share" then ShareBlacklist()
    else print("|cFFFF0000[Kryos]|r /kdt, /kdt bl, /kdt cd, /kdt ready, /kdt post, /kdt share") end
end

-- ==================== EVENTS ====================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, _, arg4)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        
        MainFrame = CreateMainFrame()
        CreateGroupElements(MainFrame)
        CreateBlacklistElements(MainFrame)
        SetupMainFrame(MainFrame)
        
        -- Initially hide blacklist elements
        for _, el in pairs(MainFrame.blacklistElements) do
            if el.Hide then el:Hide() end
        end
        
        UpdateMinimapPos()
        
        -- Hook LFG
        if PVEFrame then
            PVEFrame:HookScript("OnShow", function()
                if not MainFrame:IsShown() then MainFrame:Show(); MainFrame:SwitchTab("group") end
            end)
        end
        
        -- Right-click menu
        pcall(function()
            for _, m in ipairs({"MENU_UNIT_PLAYER","MENU_UNIT_PARTY","MENU_UNIT_RAID_PLAYER","MENU_UNIT_FRIEND"}) do
                Menu.ModifyMenu(m, function(_, root, data)
                    local n = data and (data.name or (data.unit and UnitName(data.unit)))
                    if n then n = n:gsub("%-.*", "")
                        if not IsBlacklisted(n) then 
                            root:CreateButton("|cFFFF4444Add to Blacklist|r", function() 
                                AddToBlacklist(n, "Right-click")
                                if MainFrame then MainFrame:RefreshBlacklist() end
                            end)
                        else 
                            root:CreateButton("|cFFFF4444Remove from Blacklist|r", function() 
                                RemoveFromBlacklist(n)
                                if MainFrame then MainFrame:RefreshBlacklist() end
                            end) 
                        end
                    end
                end)
            end
        end)
        
        -- Tooltip
        pcall(function()
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt)
                if tt ~= GameTooltip then return end
                local _, unit = tt:GetUnit()
                if not unit or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
                local n = UnitName(unit)
                if n and IsBlacklisted(n) then
                    local d = DB.blacklist[n:gsub("%-.*", "")]
                    tt:AddLine(" "); tt:AddLine("|cFFFF4444[!] BLACKLISTED|r")
                    if d then tt:AddLine("|cFFFF8888"..d.reason.."|r") end
                    tt:Show()
                end
            end)
        end)
        
        print("|cFFFF0000[Kryos Dungeon Tool]|r v1.2 loaded. /kdt")
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        CheckBlacklistAlert()
        CheckNewMembers()
        if MainFrame and MainFrame:IsShown() and MainFrame.currentTab == "group" then
            MainFrame:RefreshGroup()
        end
        
    elseif event == "CHAT_MSG_ADDON" and arg1 == "KryosDT" then
        ReceiveBlacklist(arg2, arg4)
        if MainFrame then MainFrame:RefreshBlacklist() end
    end
end)
