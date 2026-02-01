-- Kryos Dungeon Tool
-- UI/GroupTab.lua - Group Check tab UI with RIO, iLvl, hidden scrollbar

local addonName, KDT = ...

-- ==================== GROUP TAB ELEMENTS ====================
function KDT:CreateGroupElements(f)
    local e = f.groupElements
    local c = f.content
    
    -- Overview Box
    e.box = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.box:SetPoint("TOPLEFT", 10, -5)
    e.box:SetPoint("TOPRIGHT", -10, -5)
    e.box:SetHeight(130)
    e.box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
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
    e.keyText:SetPoint("RIGHT", -220, 0)
    e.keyText:SetJustifyH("LEFT")
    
    -- Buttons column (right side)
    e.readyBtn = self:CreateButton(e.box, "Ready Check", 95, 22)
    e.readyBtn:SetPoint("TOPRIGHT", -110, -8)
    e.readyBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
    e.readyBtn:SetScript("OnClick", function()
        if IsInGroup() then DoReadyCheck() end
    end)
    e.readyBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.55, 0.2, 1) end)
    e.readyBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.45, 0.15, 1) end)
    
    e.postBtn = self:CreateButton(e.box, "Post to Chat", 95, 22)
    e.postBtn:SetPoint("TOPRIGHT", -10, -8)
    e.postBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.postBtn:SetScript("OnClick", function() KDT:PostToChat() end)
    e.postBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.45, 0.7, 1) end)
    e.postBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.35, 0.6, 1) end)
    
    e.cdBtn = self:CreateButton(e.box, "Countdown", 95, 22)
    e.cdBtn:SetPoint("TOP", e.readyBtn, "BOTTOM", 0, -5)
    e.cdBtn:SetBackdropColor(0.5, 0.35, 0.1, 1)
    e.cdBtn:SetScript("OnClick", function() KDT:StartCountdown() end)
    e.cdBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.45, 0.15, 1) end)
    e.cdBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.35, 0.1, 1) end)
    
    -- Abandon button (new)
    e.abandonBtn = self:CreateButton(e.box, "Abandon Key", 95, 22)
    e.abandonBtn:SetPoint("TOP", e.postBtn, "BOTTOM", 0, -5)
    e.abandonBtn:SetBackdropColor(0.6, 0.15, 0.15, 1)
    e.abandonBtn:SetScript("OnClick", function()
        StaticPopupDialogs["KRYOS_ABANDON"] = {
            text = "Are you sure you want to abandon your keystone?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Use slash command for abandon
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
    
    -- Countdown seconds input
    e.secLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.secLabel:SetPoint("TOP", e.cdBtn, "BOTTOM", -12, -5)
    e.secLabel:SetText("Sec:")
    e.secLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.secInput = self:CreateInput(e.box, 30)
    e.secInput:SetPoint("LEFT", e.secLabel, "RIGHT", 5, 0)
    e.secInput:SetNumeric(true)
    e.secInput:SetMaxLetters(2)
    e.secInput:SetText("10")
    e.secInput:SetScript("OnEnterPressed", function(self)
        local v = math.max(1, math.min(60, tonumber(self:GetText()) or 10))
        KDT.DB.settings.countdownSeconds = v
        self:SetText(tostring(v))
        self:ClearFocus()
    end)
    
    -- Auto-post checkbox (moved below abandon button)
    e.autoCheck = CreateFrame("CheckButton", nil, e.box, "UICheckButtonTemplate")
    e.autoCheck:SetSize(20, 20)
    e.autoCheck:SetPoint("TOP", e.abandonBtn, "BOTTOM", -20, -3)
    e.autoCheck.Text:SetText("Auto-Post")
    e.autoCheck.Text:SetFontObject("GameFontNormalSmall")
    e.autoCheck:SetScript("OnClick", function(self)
        KDT.DB.settings.autoPost = self:GetChecked()
    end)
    
    -- Members Section
    e.membersTitle = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.membersTitle:SetPoint("TOPLEFT", e.box, "BOTTOMLEFT", 0, -8)
    e.membersTitle:SetText("GROUP MEMBERS")
    e.membersTitle:SetTextColor(0.8, 0.8, 0.8)
    
    -- Column headers
    e.headerFrame = CreateFrame("Frame", nil, c)
    e.headerFrame:SetPoint("TOPLEFT", e.membersTitle, "BOTTOMLEFT", 0, -3)
    e.headerFrame:SetPoint("RIGHT", c, "RIGHT", -10, 0)
    e.headerFrame:SetHeight(16)
    
    local headers = {
        {text = "", x = 5},      -- Role icon
        {text = "Name", x = 28},
        {text = "Class", x = 130},
        {text = "Spec", x = 200},
        {text = "iLvl", x = 280},
        {text = "RIO", x = 325},
        {text = "Key", x = 380},
    }
    
    for _, h in ipairs(headers) do
        local headerText = e.headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("LEFT", h.x, 0)
        headerText:SetText("|cFF666666" .. h.text .. "|r")
    end
    
    -- Scroll frame for member list (with hidden scrollbar)
    e.memberScroll = CreateFrame("ScrollFrame", "KryosDTMemberScroll", c, "UIPanelScrollFrameTemplate")
    e.memberScroll:SetPoint("TOPLEFT", e.headerFrame, "BOTTOMLEFT", 0, -2)
    e.memberScroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -10, 45)
    
    -- Hide the scrollbar but keep functionality
    local scrollBar = e.memberScroll.ScrollBar or _G["KryosDTMemberScrollScrollBar"]
    if scrollBar then
        scrollBar:SetAlpha(0)
        scrollBar:SetWidth(1)
        scrollBar:EnableMouse(false)
        if scrollBar.ScrollUpButton then scrollBar.ScrollUpButton:SetAlpha(0) scrollBar.ScrollUpButton:EnableMouse(false) end
        if scrollBar.ScrollDownButton then scrollBar.ScrollDownButton:SetAlpha(0) scrollBar.ScrollDownButton:EnableMouse(false) end
        local upBtn = _G["KryosDTMemberScrollScrollBarScrollUpButton"]
        local downBtn = _G["KryosDTMemberScrollScrollBarScrollDownButton"]
        if upBtn then upBtn:SetAlpha(0) upBtn:EnableMouse(false) end
        if downBtn then downBtn:SetAlpha(0) downBtn:EnableMouse(false) end
    end
    
    -- Enable mouse wheel scrolling
    e.memberScroll:EnableMouseWheel(true)
    e.memberScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * 34)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    e.memberContainer = CreateFrame("Frame", "KryosDTMemberContainer", e.memberScroll)
    e.memberContainer:SetSize(1, 1)
    e.memberScroll:SetScrollChild(e.memberContainer)
    
    e.refreshBtn = self:CreateButton(c, "Refresh", 80, 22)
    e.refreshBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.refreshBtn:SetScript("OnClick", function() f:RefreshGroup() end)
end

-- ==================== REFRESH GROUP ====================
function KDT:SetupGroupRefresh(f)
    function f:RefreshGroup()
        local e = self.groupElements
        if not e then return end
        
        -- Clear existing member rows completely
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
        
        -- Queue inspects for spec data and item level
        local units = KDT:GetGroupUnits()
        for _, unit in ipairs(units) do
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                if UnitIsConnected(unit) and CanInspect(unit) then
                    pcall(function()
                        NotifyInspect(unit)
                    end)
                end
            end
        end
        
        -- Broadcast own key and request others
        if KDT.BroadcastOwnKey then
            pcall(function() KDT:BroadcastOwnKey() end)
        end
        if KDT.RequestGroupKeys then
            pcall(function() KDT:RequestGroupKeys() end)
        end
        
        -- Get data and create rows
        self:CreateMemberRows()
        
        -- Schedule a delayed refresh to get spec/ilvl data (inspect takes time)
        if not self.pendingSpecRefresh then
            self.pendingSpecRefresh = true
            C_Timer.After(1.5, function()
                self.pendingSpecRefresh = false
                if self:IsShown() and self.currentTab == "group" then
                    self:CreateMemberRows()
                end
            end)
        end
    end
    
    -- Separate function to create member rows
    function f:CreateMemberRows()
        local e = self.groupElements
        if not e then return end
        
        -- Clear existing rows
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
        
        -- Update UI
        e.secInput:SetText(tostring(KDT.DB.settings.countdownSeconds or 10))
        e.autoCheck:SetChecked(KDT.DB.settings.autoPost or false)
        
        e.roleText:SetText(KDT.ROLE_ICONS.TANK .. " " .. info.tanks .. "  " ..
                          KDT.ROLE_ICONS.HEALER .. " " .. info.healers .. "  " ..
                          KDT.ROLE_ICONS.DAMAGER .. " " .. info.dps)
        
        if info.hasBR then
            local t = {}
            for c in pairs(info.brClasses) do
                t[#t + 1] = "|cFF" .. KDT:GetClassColorHex(c) .. (KDT.CLASS_NAMES[c] or c) .. "|r"
            end
            e.rezText:SetText("|cFF00FF00[+]|r Battle Rez: " .. table.concat(t, ", "))
        else
            e.rezText:SetText("|cFFFF4444[X] NO Battle Rez!|r")
        end
        
        if info.hasBL then
            local t = {}
            for c in pairs(info.blClasses) do
                t[#t + 1] = "|cFF" .. KDT:GetClassColorHex(c) .. (KDT.CLASS_NAMES[c] or c) .. "|r"
            end
            e.blText:SetText("|cFF00FF00[+]|r Bloodlust: " .. table.concat(t, ", "))
        else
            e.blText:SetText("|cFFFF4444[X] NO Bloodlust!|r")
        end
        
        e.stackText:SetText(#info.stacking > 0 and
            "|cFFFFCC00[!]|r Stacking: " .. table.concat(info.stacking, ", ") or
            "|cFF00FF00[+]|r No stacking")
        
        -- Keys summary
        local keys = {}
        for _, m in ipairs(members) do
            if m.keystone then
                local kc = m.keystone.level >= 12 and "|cFFFF8000" or
                          m.keystone.level >= 10 and "|cFFA335EE" or "|cFF0070DD"
                keys[#keys + 1] = kc .. m.keystone.text .. "|r"
            end
        end
        e.keyText:SetText(#keys > 0 and "|cFFFFD100[Key]|r " .. table.concat(keys, ", ") or "|cFF666666No keys|r")
        
        -- Set scroll child width
        local scrollWidth = e.memberScroll:GetWidth() or 600
        e.memberContainer:SetWidth(scrollWidth - 5)
        
        -- Create member rows
        local yOffset = 0
        
        for i, m in ipairs(members) do
            local row = CreateFrame("Frame", nil, e.memberContainer, "BackdropTemplate")
            row:SetHeight(30)
            row:SetPoint("TOPLEFT", e.memberContainer, "TOPLEFT", 0, yOffset)
            row:SetPoint("RIGHT", e.memberContainer, "RIGHT", 0, 0)
            row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
            row:SetBackdropColor(i % 2 == 0 and 0.07 or 0.05, i % 2 == 0 and 0.07 or 0.05, i % 2 == 0 and 0.09 or 0.07, 0.95)
            
            -- Enable mouse wheel on rows
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function(self, delta)
                local scroll = e.memberScroll
                local current = scroll:GetVerticalScroll()
                local maxScroll = scroll:GetVerticalScrollRange()
                local newScroll = current - (delta * 34)
                newScroll = math.max(0, math.min(newScroll, maxScroll))
                scroll:SetVerticalScroll(newScroll)
            end)
            
            -- Role icon
            local role = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            role:SetPoint("LEFT", 5, 0)
            role:SetText(KDT.ROLE_ICONS[m.role] or KDT.ROLE_ICONS.DAMAGER)
            
            -- Name (with class color)
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", 28, 0)
            nameText:SetWidth(98)
            nameText:SetJustifyH("LEFT")
            nameText:SetText("|cFF" .. KDT:GetClassColorHex(m.class) .. (m.name or "?") .. "|r")
            
            -- Class
            local classText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            classText:SetPoint("LEFT", 130, 0)
            classText:SetWidth(68)
            classText:SetJustifyH("LEFT")
            classText:SetText(KDT.CLASS_NAMES[m.class] or "?")
            classText:SetTextColor(0.5, 0.5, 0.5)
            
            -- Spec
            local specText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            specText:SetPoint("LEFT", 200, 0)
            specText:SetWidth(78)
            specText:SetJustifyH("LEFT")
            specText:SetText(m.spec or "?")
            specText:SetTextColor(0.4, 0.4, 0.4)
            
            -- Item Level
            local ilvlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ilvlText:SetPoint("LEFT", 280, 0)
            ilvlText:SetWidth(40)
            ilvlText:SetJustifyH("LEFT")
            local ilvl = m.ilvl
            if ilvl then
                local ilvlColor = ilvl >= 639 and "|cFFFF8000" or
                                 ilvl >= 626 and "|cFFA335EE" or
                                 ilvl >= 610 and "|cFF0070DD" or
                                 "|cFF1EFF00"
                ilvlText:SetText(ilvlColor .. ilvl .. "|r")
            else
                ilvlText:SetText("|cFF444444-|r")
            end
            
            -- RIO Score
            local rioText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rioText:SetPoint("LEFT", 325, 0)
            rioText:SetWidth(50)
            rioText:SetJustifyH("LEFT")
            local rio = m.rio
            if rio and rio > 0 then
                local rioColor = rio >= 3000 and "|cFFFF8000" or
                                rio >= 2500 and "|cFFA335EE" or
                                rio >= 2000 and "|cFF0070DD" or
                                rio >= 1500 and "|cFF1EFF00" or
                                "|cFFFFFFFF"
                rioText:SetText(rioColor .. rio .. "|r")
            else
                rioText:SetText("|cFF444444-|r")
            end
            
            -- Key
            local keyText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            keyText:SetPoint("LEFT", 380, 0)
            keyText:SetWidth(100)
            keyText:SetJustifyH("LEFT")
            if m.keystone then
                local kc = m.keystone.level >= 12 and "|cFFFF8000" or
                          m.keystone.level >= 10 and "|cFFA335EE" or "|cFF0070DD"
                keyText:SetText(kc .. m.keystone.text .. "|r")
            else
                keyText:SetText("|cFF444444No Key|r")
            end
            
            -- Utility icons (BR/BL) on far right
            local utilText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            utilText:SetPoint("RIGHT", -5, 0)
            local u = {}
            if KDT.BATTLE_REZ[m.class] then u[#u + 1] = "|cFF00DD00BR|r" end
            if KDT.BLOODLUST[m.class] then u[#u + 1] = "|cFFFF8800BL|r" end
            utilText:SetText(table.concat(u, " "))
            
            -- Blacklist warning
            if KDT:IsBlacklisted(m.name) then
                local warn = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                warn:SetPoint("RIGHT", utilText, "LEFT", -5, 0)
                warn:SetText("|cFFFF0000[BL!]|r")
            end
            
            row:Show()
            self.memberRows[#self.memberRows + 1] = row
            yOffset = yOffset - 32
        end
        
        -- Set scroll child height
        e.memberContainer:SetHeight(math.max(1, math.abs(yOffset) + 10))
    end
end
