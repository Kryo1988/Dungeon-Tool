-- Kryos Dungeon Tool
-- Modules/Blacklist.lua - Blacklist functionality (v1.4 Style)

local addonName, KDT = ...

-- Add to blacklist
function KDT:AddToBlacklist(name, reason)
    if not name or name == "" then return false end
    
    -- Remove server name if present
    name = name:gsub("%-.*", "")
    
    -- Initialize if needed
    if not self.DB.blacklist then
        self.DB.blacklist = {}
    end
    
    -- Add/Update entry (key-value structure)
    self.DB.blacklist[name] = {
        reason = reason or "",
        date = date("%Y-%m-%d"),
    }
    
    self:Print("Added to blacklist: " .. name)
    return true
end

-- Show dialog to add someone to blacklist
function KDT:ShowAddToBlacklistDialog(playerName)
    if not playerName then return end
    
    -- Remove server name if present
    playerName = playerName:gsub("%-.*", "")
    
    -- Hide existing dialog if present
    if self.addBlacklistDialog then
        self.addBlacklistDialog:Hide()
        self.addBlacklistDialog = nil
    end
    
    local dialog = CreateFrame("Frame", "KryosAddToBlacklistDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(350, 180)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(100)
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    dialog:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red border
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    self.addBlacklistDialog = dialog
    
    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFFFF0000Add to Blacklist|r")
    
    -- Player name
    local nameText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOP", title, "BOTTOM", 0, -15)
    nameText:SetText("Player: |cFFFFFFFF" .. playerName .. "|r")
    
    -- Reason label
    local reasonLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reasonLabel:SetPoint("TOPLEFT", 20, -75)
    reasonLabel:SetText("Reason (optional):")
    reasonLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Reason editbox - use InputBoxTemplate for proper functionality
    local reasonBox = CreateFrame("EditBox", "KryosBlacklistReasonBox", dialog, "InputBoxTemplate")
    reasonBox:SetSize(310, 24)
    reasonBox:SetPoint("TOPLEFT", reasonLabel, "BOTTOMLEFT", 0, -5)
    reasonBox:SetPoint("RIGHT", dialog, "RIGHT", -20, 0)
    reasonBox:SetAutoFocus(true)
    reasonBox:SetMaxLetters(100)
    reasonBox:SetTextColor(1, 1, 1)
    
    -- Add button
    local addBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    addBtn:SetSize(120, 26)
    addBtn:SetPoint("BOTTOMLEFT", 30, 20)
    addBtn:SetText("Add to Blacklist")
    addBtn:SetScript("OnClick", function()
        local reason = reasonBox:GetText() or ""
        KDT:AddToBlacklist(playerName, reason)
        
        -- Refresh UI if visible
        if KDT.MainFrame and KDT.MainFrame:IsShown() then
            KDT.MainFrame:RefreshBlacklist()
        end
        
        dialog:Hide()
    end)
    
    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(80, 26)
    cancelBtn:SetPoint("BOTTOMRIGHT", -30, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- Close on escape
    reasonBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
    
    -- Enter to confirm
    reasonBox:SetScript("OnEnterPressed", function()
        addBtn:Click()
    end)
    
    -- Make dialog close on escape key
    tinsert(UISpecialFrames, "KryosAddToBlacklistDialog")
    
    dialog:Show()
    reasonBox:SetFocus()
end

-- Remove from blacklist
function KDT:RemoveFromBlacklist(name)
    if not name or not self.DB.blacklist then return false end
    
    -- Remove server name if present
    name = name:gsub("%-.*", "")
    
    if self.DB.blacklist[name] then
        self.DB.blacklist[name] = nil
        self:Print("Removed from blacklist: " .. name)
        return true
    end
    
    return false
end

-- Check if player is blacklisted
function KDT:IsBlacklisted(name)
    if not name or not self.DB or not self.DB.blacklist then return false end
    
    -- Remove server name if present
    name = name:gsub("%-.*", "")
    
    return self.DB.blacklist[name] ~= nil
end

-- Get blacklist entry
function KDT:GetBlacklistEntry(name)
    if not name or not self.DB or not self.DB.blacklist then return nil end
    name = name:gsub("%-.*", "")
    return self.DB.blacklist[name]
end

-- Get blacklist
function KDT:GetBlacklist()
    return self.DB.blacklist or {}
end

-- Clear blacklist
function KDT:ClearBlacklist()
    self.DB.blacklist = {}
    wipe(self.alreadyAlerted)
    self:Print("Blacklist cleared.")
end

-- Check group for blacklisted players
function KDT:CheckGroupForBlacklist()
    local units = self:GetGroupUnits()
    local found = false
    
    for _, unit in ipairs(units) do
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local name = UnitName(unit)
            if name and self:IsBlacklisted(name) then
                local entry = self:GetBlacklistEntry(name)
                self:AlertBlacklisted(name, entry and entry.reason)
                found = true
            end
        end
    end
    
    return found
end

-- Alert for blacklisted player
function KDT:AlertBlacklisted(name, reason)
    -- Don't alert for the same player multiple times per session
    if not self.alreadyAlerted then
        self.alreadyAlerted = {}
    end
    
    if self.alreadyAlerted[name] then
        return
    end
    self.alreadyAlerted[name] = true
    
    -- Print warning message
    local msg = "|cFFFF0000[KDT WARNING]|r Blacklisted player in group: |cFFFFFFFF" .. name .. "|r"
    if reason and reason ~= "" then
        msg = msg .. " - Reason: |cFFFFCC00" .. reason .. "|r"
    end
    
    -- Print to chat
    self:Print(msg)
    
    -- Also show as RaidWarning if possible
    if RaidNotice_AddMessage then
        RaidNotice_AddMessage(RaidWarningFrame, "|cFFFF0000BLACKLISTED:|r " .. name, ChatTypeInfo["RAID_WARNING"])
    end
    
    -- Play sound
    if self.DB and self.DB.settings then
        if self.DB.settings.customSound then
            -- Try to play custom sound
            local soundFile = "Interface\\AddOns\\KryosDungeonTool\\intruder.mp3"
            local willPlay, handle = PlaySoundFile(soundFile, "Master")
            if not willPlay then
                -- Fallback to default sound
                PlaySound(SOUNDKIT.RAID_WARNING, "Master")
            end
        else
            -- Default alert sound
            PlaySound(SOUNDKIT.RAID_WARNING, "Master")
        end
    else
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

-- Share blacklist via addon messages (sync with other KDT users)
function KDT:ShareBlacklist()
    if not IsInGroup() then
        self:Print("You must be in a group to share your blacklist.")
        return
    end
    
    local count = 0
    for name, _ in pairs(self.DB.blacklist) do
        count = count + 1
    end
    
    if count == 0 then
        self:Print("Blacklist is empty.")
        return
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    
    -- Send each blacklist entry as addon message
    for name, data in pairs(self.DB.blacklist) do
        local reason = data.reason or ""
        local msg = "BL_SHARE:" .. name .. ":" .. reason
        C_ChatInfo.SendAddonMessage("KDT", msg, channel)
    end
    
    -- Send completion message
    C_ChatInfo.SendAddonMessage("KDT", "BL_SHARE_DONE:" .. count, channel)
    
    self:Print("Blacklist shared with " .. count .. " entries. Other KDT users will receive it.")
end

-- Receive shared blacklist entries
function KDT:ReceiveBlacklistShare(msg, sender)
    -- Don't receive our own messages
    local myName = UnitName("player")
    if sender == myName or sender:match("^" .. myName .. "%-") then return end
    
    if msg:match("^BL_SHARE:") then
        local name, reason = msg:match("^BL_SHARE:([^:]+):(.*)$")
        if name then
            -- Add to pending shares
            if not self.pendingBlacklistShares then
                self.pendingBlacklistShares = {}
            end
            if not self.pendingBlacklistShares[sender] then
                self.pendingBlacklistShares[sender] = {}
            end
            self.pendingBlacklistShares[sender][name] = {
                reason = reason ~= "" and reason or nil,
                sharedBy = sender,
            }
        end
    elseif msg:match("^BL_SHARE_DONE:") then
        local count = msg:match("^BL_SHARE_DONE:(%d+)$")
        if count and self.pendingBlacklistShares and self.pendingBlacklistShares[sender] then
            -- Show import dialog
            self:ShowBlacklistImportDialog(sender, self.pendingBlacklistShares[sender])
        end
    end
end

-- Show dialog to import shared blacklist
function KDT:ShowBlacklistImportDialog(sender, entries)
    local count = 0
    for _ in pairs(entries) do count = count + 1 end
    
    if count == 0 then return end
    
    -- Create dialog
    local dialog = CreateFrame("Frame", "KryosBLImportDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(350, 150)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    dialog:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFFFFD100Blacklist Share Received|r")
    
    local info = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", title, "BOTTOM", 0, -15)
    info:SetText(sender .. " shared " .. count .. " blacklist entries.")
    
    local info2 = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info2:SetPoint("TOP", info, "BOTTOM", 0, -5)
    info2:SetText("Do you want to import them?")
    info2:SetTextColor(0.7, 0.7, 0.7)
    
    -- Import button
    local importBtn = self:CreateButton(dialog, "Import All", 100, 26)
    importBtn:SetPoint("BOTTOMLEFT", 30, 20)
    importBtn:SetBackdropColor(0.2, 0.6, 0.2, 1)
    importBtn:SetScript("OnClick", function()
        local imported = 0
        for name, data in pairs(entries) do
            if not self.DB.blacklist[name] then
                self.DB.blacklist[name] = {
                    reason = data.reason,
                    date = date("%Y-%m-%d"),
                    sharedBy = data.sharedBy,
                }
                imported = imported + 1
            end
        end
        self:Print("Imported " .. imported .. " new blacklist entries from " .. sender)
        if self.MainFrame and self.MainFrame.RefreshBlacklist then
            self.MainFrame:RefreshBlacklist()
        end
        dialog:Hide()
        self.pendingBlacklistShares[sender] = nil
    end)
    
    -- Decline button
    local declineBtn = self:CreateButton(dialog, "Decline", 100, 26)
    declineBtn:SetPoint("BOTTOMRIGHT", -30, 20)
    declineBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)
    declineBtn:SetScript("OnClick", function()
        self.pendingBlacklistShares[sender] = nil
        dialog:Hide()
    end)
    
    dialog:Show()
end

-- Export blacklist to string
function KDT:ExportBlacklist()
    if not self.DB.blacklist then return "" end
    
    local lines = {}
    for name, data in pairs(self.DB.blacklist) do
        table.insert(lines, string.format("%s|%s|%s", 
            name, 
            data.reason or "", 
            data.date or ""))
    end
    
    return table.concat(lines, "\n")
end

-- Import blacklist from string
function KDT:ImportBlacklist(str)
    if not str or str == "" then return 0 end
    
    local count = 0
    for line in str:gmatch("[^\n]+") do
        local name, reason, dateStr = line:match("^([^|]+)|([^|]*)|(.*)$")
        if name then
            self:AddToBlacklist(name, reason)
            count = count + 1
        end
    end
    
    return count
end
