-- Kryos Dungeon Tool
-- UI/TeleportTab.lua - M+ Teleports tab UI (v1.4 Style)

local addonName, KDT = ...

-- ==================== TELEPORT TAB ELEMENTS ====================
function KDT:CreateTeleportElements(f)
    local e = f.teleportElements
    local c = f.content
    
    -- Settings box at top
    e.settingsBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.settingsBox:SetPoint("TOPLEFT", 10, -5)
    e.settingsBox:SetPoint("TOPRIGHT", -10, -5)
    e.settingsBox:SetHeight(30)
    e.settingsBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.settingsBox:SetBackdropColor(0.08, 0.08, 0.10, 0.95)
    e.settingsBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    -- Chat message checkbox
    e.chatMsgCheck = CreateFrame("CheckButton", nil, e.settingsBox, "UICheckButtonTemplate")
    e.chatMsgCheck:SetSize(20, 20)
    e.chatMsgCheck:SetPoint("LEFT", 10, 0)
    e.chatMsgCheck.Text:SetText("Announce teleport in chat")
    e.chatMsgCheck.Text:SetFontObject("GameFontNormalSmall")
    e.chatMsgCheck:SetScript("OnClick", function(self)
        if not KDT.DB.settings then KDT.DB.settings = {} end
        KDT.DB.settings.announceTeleport = self:GetChecked()
    end)
    
    -- Scroll Frame for all teleports
    e.scroll = CreateFrame("ScrollFrame", "KryosDTTeleportScroll", c, "UIPanelScrollFrameTemplate")
    e.scroll:SetPoint("TOPLEFT", e.settingsBox, "BOTTOMLEFT", 0, -5)
    e.scroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -28, 10)
    
    e.scrollChild = CreateFrame("Frame", nil, e.scroll)
    e.scrollChild:SetSize(640, 1)
    e.scroll:SetScrollChild(e.scrollChild)
end

-- ==================== REFRESH TELEPORTS ====================
function KDT:SetupTeleportRefresh(f)
    function f:RefreshTeleports()
        local e = self.teleportElements
        
        -- Update checkbox state
        if e.chatMsgCheck then
            -- Default to true if not set
            local announce = KDT.DB.settings.announceTeleport
            if announce == nil then announce = true end
            e.chatMsgCheck:SetChecked(announce)
        end
        
        -- Clear existing buttons
        for _, btn in ipairs(self.teleportButtons) do
            btn:Hide()
            btn:ClearAllPoints()
        end
        wipe(self.teleportButtons)
        
        local buttonSize = 40
        local buttonSpacing = 6
        local buttonsPerRow = 5
        local columnWidth = 320
        local rowHeight = buttonSize + 20
        
        -- Track positions for left and right columns
        local leftY = 0
        local rightY = 0
        local currentColumn = 0  -- 0 = left, 1 = right
        
        for catIdx, category in ipairs(KDT.TELEPORT_DATA) do
            -- Determine which column to use (alternate)
            local xBase = currentColumn == 0 and 5 or columnWidth + 20
            local yOffset = currentColumn == 0 and leftY or rightY
            
            -- Category Header
            local header = e.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", xBase, yOffset - 5)
            header:SetText("|cFFFFD100" .. category.category .. "|r")
            
            local headerFrame = CreateFrame("Frame", nil, e.scrollChild)
            headerFrame.text = header
            self.teleportButtons[#self.teleportButtons + 1] = headerFrame
            
            yOffset = yOffset - 22
            
            -- Dungeon Buttons
            for i, dungeon in ipairs(category.dungeons) do
                local col = (i - 1) % buttonsPerRow
                local row = math.floor((i - 1) / buttonsPerRow)
                
                local xPos = xBase + col * (buttonSize + buttonSpacing)
                local yPos = yOffset - row * rowHeight
                
                -- Button Frame (SecureActionButton for spell casting)
                local btn = CreateFrame("Button", "KryosTeleport" .. #self.teleportButtons, e.scrollChild, "SecureActionButtonTemplate, BackdropTemplate")
                btn:SetSize(buttonSize, buttonSize)
                btn:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", xPos, yPos)
                btn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1
                })
                btn:SetBackdropColor(0.1, 0.1, 0.12, 1)
                btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                
                -- Register for clicks
                btn:RegisterForClicks("AnyUp", "AnyDown")
                
                -- Icon
                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(buttonSize - 6, buttonSize - 6)
                icon:SetPoint("CENTER")
                icon:SetTexture(dungeon.icon)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.icon = icon
                
                -- Check if spell is known
                local isKnown = IsSpellKnown(dungeon.spellID)
                if not isKnown then
                    icon:SetDesaturated(true)
                    btn:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
                end
                
                -- Hover overlay
                local hover = btn:CreateTexture(nil, "HIGHLIGHT")
                hover:SetAllPoints(icon)
                hover:SetColorTexture(1, 1, 1, 0.2)
                
                -- Set spell attribute
                btn:SetAttribute("type", "spell")
                btn:SetAttribute("spell", dungeon.spellID)
                
                -- Track if message was already sent for this click
                btn.messageSent = false
                
                -- PreClick: Send chat message (only once per click, and only if enabled)
                btn:SetScript("PreClick", function(self, button, down)
                    if down and not self.messageSent and isKnown then
                        self.messageSent = true
                        -- Check if announcements are enabled
                        local announce = KDT.DB.settings.announceTeleport
                        if announce == nil then announce = true end -- Default to true
                        if announce then
                            local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
                            if channel then
                                SendChatMessage("[Kryos Dungeon Tool] Porting to \"" .. dungeon.name .. "\"", channel)
                            end
                        end
                    end
                end)
                
                -- PostClick: Reset message flag
                btn:SetScript("PostClick", function(self, button, down)
                    if not down then
                        self.messageSent = false
                    end
                end)
                
                -- Name label below button (white, no shadow)
                local nameLabel = e.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                nameLabel:SetPoint("TOP", btn, "BOTTOM", 0, -1)
                nameLabel:SetText(dungeon.short)
                nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 9)
                if isKnown then
                    nameLabel:SetTextColor(1, 1, 1)
                else
                    nameLabel:SetTextColor(0.5, 0.5, 0.5)
                end
                btn.label = nameLabel
                
                -- Tooltip
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    if isKnown then
                        GameTooltip:SetSpellByID(dungeon.spellID)
                    else
                        GameTooltip:SetText(dungeon.name)
                        GameTooltip:AddLine("Not yet unlocked", 1, 0.3, 0.3)
                        GameTooltip:AddLine("Complete the dungeon on M+ to unlock", 0.7, 0.7, 0.7)
                    end
                    GameTooltip:Show()
                    self:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
                end)
                
                btn:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    if isKnown then
                        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
                    else
                        self:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
                    end
                end)
                
                btn.data = dungeon
                self.teleportButtons[#self.teleportButtons + 1] = btn
                
                -- Track label too
                local labelFrame = CreateFrame("Frame", nil, e.scrollChild)
                labelFrame.text = nameLabel
                self.teleportButtons[#self.teleportButtons + 1] = labelFrame
            end
            
            -- Calculate rows for this category
            local numRows = math.ceil(#category.dungeons / buttonsPerRow)
            local categoryHeight = 22 + (numRows * rowHeight) + 10
            
            -- Update column position
            if currentColumn == 0 then
                leftY = leftY - categoryHeight
            else
                rightY = rightY - categoryHeight
            end
            
            -- Alternate columns
            currentColumn = 1 - currentColumn
        end
        
        -- Set scroll height to the larger of the two columns
        local totalHeight = math.max(math.abs(leftY), math.abs(rightY))
        e.scrollChild:SetHeight(math.max(1, totalHeight + 20))
    end
end
