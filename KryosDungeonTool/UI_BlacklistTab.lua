-- Kryos Dungeon Tool
-- UI_BlacklistTab.lua - Blacklist tab UI

local addonName, KDT = ...

-- ==================== BLACKLIST TAB ELEMENTS ====================
function KDT:CreateBlacklistElements(f)
    local e = f.blacklistElements
    local c = f.content
    
    -- Add Box
    e.box = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.box:SetPoint("TOPLEFT", 10, -5)
    e.box:SetPoint("TOPRIGHT", -10, -5)
    e.box:SetHeight(75)
    e.box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
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
    
    e.nameInput = self:CreateInput(e.box, 130)
    e.nameInput:SetPoint("TOPLEFT", 10, -42)
    e.nameInput:SetMaxLetters(12)
    
    e.reasonLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.reasonLabel:SetPoint("TOPLEFT", 155, -28)
    e.reasonLabel:SetText("Reason")
    e.reasonLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.reasonInput = self:CreateInput(e.box, 340)
    e.reasonInput:SetPoint("TOPLEFT", 155, -42)
    e.reasonInput:SetMaxLetters(100)
    
    e.addBtn = self:CreateButton(e.box, "Add", 70, 22)
    e.addBtn:SetPoint("TOPLEFT", 510, -42)
    e.addBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.addBtn:SetScript("OnClick", function()
        local n = e.nameInput:GetText()
        if n and n ~= "" then
            KDT:AddToBlacklist(n, e.reasonInput:GetText())
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
    e.clearBtn = self:CreateButton(c, "Clear All", 80, 22)
    e.clearBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.clearBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
    e.clearBtn:SetScript("OnClick", function()
        StaticPopupDialogs["KRYOS_CLEAR"] = {
            text = "Clear blacklist?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                KDT.DB.blacklist = {}
                wipe(KDT.alreadyAlerted)
                f:RefreshBlacklist()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("KRYOS_CLEAR")
    end)
    e.clearBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.2, 0.2, 1) end)
    e.clearBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 1) end)
    
    e.shareBtn = self:CreateButton(c, "Share List", 80, 22)
    e.shareBtn:SetPoint("LEFT", e.clearBtn, "RIGHT", 10, 0)
    e.shareBtn:SetBackdropColor(0.15, 0.4, 0.15, 1)
    e.shareBtn:SetScript("OnClick", function() KDT:ShareBlacklist() end)
    e.shareBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.5, 0.2, 1) end)
    e.shareBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.4, 0.15, 1) end)
    
    e.soundCheck = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    e.soundCheck:SetSize(20, 20)
    e.soundCheck:SetPoint("LEFT", e.shareBtn, "RIGHT", 15, 0)
    e.soundCheck.Text:SetText("Custom Sound")
    e.soundCheck.Text:SetFontObject("GameFontNormalSmall")
    e.soundCheck:SetScript("OnClick", function(self)
        KDT.DB.settings.customSound = self:GetChecked()
    end)
end

-- ==================== REFRESH BLACKLIST ====================
function KDT:SetupBlacklistRefresh(f)
    function f:RefreshBlacklist()
        local e = self.blacklistElements
        
        e.soundCheck:SetChecked(KDT.DB.settings.customSound ~= false)
        
        for _, row in ipairs(self.blRows) do
            row:Hide()
            row:ClearAllPoints()
        end
        wipe(self.blRows)
        
        local sorted = {}
        for name, data in pairs(KDT.DB.blacklist) do
            sorted[#sorted + 1] = {name = name, data = data}
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        
        local yOffset = 0
        for _, entry in ipairs(sorted) do
            local row = CreateFrame("Frame", nil, e.scrollChild, "BackdropTemplate")
            row:SetSize(640, 42)
            row:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", 0, yOffset)
            row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
            row:SetBackdropColor(0.07, 0.07, 0.09, 0.95)
            
            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("TOPLEFT", 10, -8)
            name:SetText("|cFFFF6666" .. entry.name .. "|r")
            
            local reason = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            reason:SetPoint("TOPLEFT", 10, -24)
            reason:SetWidth(480)
            reason:SetJustifyH("LEFT")
            reason:SetText(entry.data.reason or "No reason")
            reason:SetTextColor(0.5, 0.5, 0.5)
            
            local delBtn = KDT:CreateButton(row, "Delete", 55, 20)
            delBtn:SetPoint("RIGHT", -8, 0)
            delBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
            delBtn:SetScript("OnClick", function()
                KDT:RemoveFromBlacklist(entry.name)
                f:RefreshBlacklist()
            end)
            delBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.2, 0.2, 1) end)
            delBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 1) end)
            
            local editBtn = KDT:CreateButton(row, "Edit", 45, 20)
            editBtn:SetPoint("RIGHT", delBtn, "LEFT", -5, 0)
            editBtn:SetBackdropColor(0.3, 0.3, 0.5, 1)
            editBtn.playerName = entry.name
            editBtn:SetScript("OnClick", function(self)
                local playerName = self.playerName
                KDT:ShowEditReasonDialog(playerName, f)
            end)
            editBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.4, 0.4, 0.6, 1) end)
            editBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.3, 0.3, 0.5, 1) end)
            
            self.blRows[#self.blRows + 1] = row
            yOffset = yOffset - 45
        end
        
        if #sorted == 0 then
            local empty = e.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            empty:SetPoint("TOP", e.scrollChild, "TOP", 0, -30)
            empty:SetText("Blacklist is empty")
            empty:SetTextColor(0.4, 0.4, 0.4)
            local frame = CreateFrame("Frame", nil, e.scrollChild)
            frame.text = empty
            self.blRows[#self.blRows + 1] = frame
        end
        
        e.scrollChild:SetHeight(math.max(1, math.abs(yOffset)))
    end
end
