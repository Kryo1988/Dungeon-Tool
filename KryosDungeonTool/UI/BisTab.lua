-- Kryos Dungeon Tool
-- UI/BisTab.lua - Best in Slot Gear Tab with In-Game Editor
-- Version 1.7 - No Unicode symbols, clean alignment

local addonName, KDT = ...

-- Source colors
local SOURCE_COLORS = {
    RAID = {1, 0.5, 0},
    MYTHIC_PLUS = {0.6, 0.4, 1},
    CRAFTED = {0, 0.8, 0.4},
    DELVE = {0.4, 0.8, 1},
    WORLD = {0.8, 0.8, 0.3},
    PVP = {1, 0.2, 0.2},
    UNKNOWN = {0.5, 0.5, 0.5},
}

-- Edit Dialog Frame
local editFrame = nil

local function CreateEditDialog()
    if editFrame then return editFrame end
    
    editFrame = CreateFrame("Frame", "KryosDTEditFrame", UIParent, "BackdropTemplate")
    editFrame:SetSize(420, 400)
    editFrame:SetPoint("CENTER")
    editFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    editFrame:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    editFrame:SetBackdropBorderColor(0.3, 0.6, 1, 1)
    editFrame:SetFrameStrata("DIALOG")
    editFrame:EnableMouse(true)
    editFrame:SetMovable(true)
    editFrame:RegisterForDrag("LeftButton")
    editFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    editFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    editFrame:Hide()
    
    -- Title
    local title = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFF00D4FFEdit BiS Slot|r")
    editFrame.title = title
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, editFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() editFrame:Hide() end)
    
    -- Slot label
    local slotLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slotLabel:SetPoint("TOPLEFT", 20, -50)
    slotLabel:SetText("Slot:")
    slotLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local slotValue = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    slotValue:SetPoint("LEFT", slotLabel, "RIGHT", 10, 0)
    slotValue:SetText("HEAD")
    slotValue:SetTextColor(1, 0.84, 0)
    editFrame.slotValue = slotValue
    
    local yPos = -80
    
    -- Item ID
    local idLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idLabel:SetPoint("TOPLEFT", 20, yPos)
    idLabel:SetText("Item ID:")
    idLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local idBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    idBox:SetSize(120, 22)
    idBox:SetPoint("TOPLEFT", 120, yPos + 3)
    idBox:SetAutoFocus(false)
    idBox:SetNumeric(true)
    editFrame.idBox = idBox
    
    yPos = yPos - 30
    
    -- Item Name
    local nameLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 20, yPos)
    nameLabel:SetText("Item Name:")
    nameLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local nameBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    nameBox:SetSize(260, 22)
    nameBox:SetPoint("TOPLEFT", 120, yPos + 3)
    nameBox:SetAutoFocus(false)
    editFrame.nameBox = nameBox
    
    yPos = yPos - 35
    
    -- Source buttons
    local sourceLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceLabel:SetPoint("TOPLEFT", 20, yPos)
    sourceLabel:SetText("Source:")
    sourceLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local sources = {"RAID", "MYTHIC_PLUS", "CRAFTED"}
    local sourceButtons = {}
    editFrame.selectedSource = "RAID"
    
    local function UpdateSourceButtons()
        for _, b in ipairs(sourceButtons) do
            if b.source == editFrame.selectedSource then
                b:SetBackdropColor(0.2, 0.4, 0.6, 1)
                b:SetBackdropBorderColor(0.3, 0.6, 1, 1)
            else
                b:SetBackdropColor(0.15, 0.15, 0.18, 1)
                b:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
            end
        end
    end
    editFrame.UpdateSourceButtons = UpdateSourceButtons
    
    local btnX = 120
    for i, src in ipairs(sources) do
        local btn = CreateFrame("Button", nil, editFrame, "BackdropTemplate")
        btn:SetSize(85, 22)
        btn:SetPoint("TOPLEFT", btnX, yPos + 3)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1
        })
        btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(KDT.BIS_SOURCE[src] or src)
        
        btn.source = src
        btn:SetScript("OnClick", function(self)
            editFrame.selectedSource = self.source
            UpdateSourceButtons()
        end)
        btn:SetScript("OnEnter", function(self)
            if self.source ~= editFrame.selectedSource then
                self:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if self.source ~= editFrame.selectedSource then
                self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
            end
        end)
        sourceButtons[i] = btn
        btnX = btnX + 90
    end
    editFrame.sourceButtons = sourceButtons
    
    yPos = yPos - 35
    
    -- Source Detail
    local detailLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailLabel:SetPoint("TOPLEFT", 20, yPos)
    detailLabel:SetText("Drop Location:")
    detailLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local detailBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    detailBox:SetSize(220, 22)
    detailBox:SetPoint("TOPLEFT", 120, yPos + 3)
    detailBox:SetAutoFocus(false)
    editFrame.detailBox = detailBox
    
    yPos = yPos - 35
    
    -- Enchant ID
    local enchantLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enchantLabel:SetPoint("TOPLEFT", 20, yPos)
    enchantLabel:SetText("Enchant ID:")
    enchantLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local enchantBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    enchantBox:SetSize(120, 22)
    enchantBox:SetPoint("TOPLEFT", 120, yPos + 3)
    enchantBox:SetAutoFocus(false)
    enchantBox:SetNumeric(true)
    editFrame.enchantBox = enchantBox
    
    local enchantHelp = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enchantHelp:SetPoint("LEFT", enchantBox, "RIGHT", 10, 0)
    enchantHelp:SetText("|cFF8888880 = none|r")
    
    yPos = yPos - 35
    
    -- Gem IDs
    local gemLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gemLabel:SetPoint("TOPLEFT", 20, yPos)
    gemLabel:SetText("Gem IDs:")
    gemLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local gemBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    gemBox:SetSize(180, 22)
    gemBox:SetPoint("TOPLEFT", 120, yPos + 3)
    gemBox:SetAutoFocus(false)
    editFrame.gemBox = gemBox
    
    local gemHelp = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gemHelp:SetPoint("LEFT", gemBox, "RIGHT", 10, 0)
    gemHelp:SetText("|cFF888888comma separated|r")
    
    yPos = yPos - 35
    
    -- Popularity
    local popLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popLabel:SetPoint("TOPLEFT", 20, yPos)
    popLabel:SetText("Popularity %:")
    popLabel:SetTextColor(0.7, 0.7, 0.7)
    
    local popBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    popBox:SetSize(80, 22)
    popBox:SetPoint("TOPLEFT", 120, yPos + 3)
    popBox:SetAutoFocus(false)
    editFrame.popBox = popBox
    
    -- Status text
    local status = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("BOTTOMLEFT", 20, 55)
    status:SetWidth(300)
    status:SetJustifyH("LEFT")
    status:SetText("")
    editFrame.status = status
    
    -- Save button (styled)
    local saveBtn = CreateFrame("Button", nil, editFrame, "BackdropTemplate")
    saveBtn:SetSize(100, 26)
    saveBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    saveBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    saveBtn:SetBackdropColor(0.1, 0.3, 0.1, 1)
    saveBtn:SetBackdropBorderColor(0.2, 0.5, 0.2, 1)
    
    saveBtn.text = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    saveBtn.text:SetPoint("CENTER")
    saveBtn.text:SetText("Save")
    saveBtn.text:SetTextColor(0.4, 1, 0.4)
    
    saveBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.3, 0.7, 0.3, 1)
    end)
    saveBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.2, 0.5, 0.2, 1)
    end)
    saveBtn:SetScript("OnClick", function()
        local specID = KDT:GetPlayerSpecID()
        local slot = editFrame.currentSlot
        
        if not slot then
            editFrame.status:SetText("|cFFFF0000No slot selected|r")
            return
        end
        
        -- Parse gem IDs
        local gems = {}
        local gemText = editFrame.gemBox:GetText() or ""
        for gid in gemText:gmatch("%d+") do
            local g = tonumber(gid)
            if g and g > 0 then
                table.insert(gems, g)
            end
        end
        
        -- Build item data
        local itemData = {
            id = tonumber(editFrame.idBox:GetText()) or 0,
            name = editFrame.nameBox:GetText() or "Unknown",
            source = editFrame.selectedSource or "RAID",
            detail = editFrame.detailBox:GetText() or "",
            popularity = tonumber(editFrame.popBox:GetText()) or 0,
            enchant = tonumber(editFrame.enchantBox:GetText()) or nil,
            gems = #gems > 0 and gems or nil,
        }
        
        if itemData.enchant == 0 then itemData.enchant = nil end
        
        -- Save to custom data
        KDT:SaveCustomBisSlot(specID, slot, itemData)
        
        editFrame.status:SetText("|cFF00FF00Saved!|r")
        
        -- Refresh BiS display
        if KDT.mainFrame and KDT.mainFrame.RefreshBis then
            KDT.mainFrame:RefreshBis()
        end
    end)
    
    -- Reset button (styled)
    local resetBtn = CreateFrame("Button", nil, editFrame, "BackdropTemplate")
    resetBtn:SetSize(100, 26)
    resetBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    resetBtn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    resetBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    resetBtn.text = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetBtn.text:SetPoint("CENTER")
    resetBtn.text:SetText("Reset Slot")
    
    resetBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)
    end)
    resetBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    end)
    resetBtn:SetScript("OnClick", function()
        local specID = KDT:GetPlayerSpecID()
        local slot = editFrame.currentSlot
        
        if slot then
            KDT:ResetCustomBisSlot(specID, slot)
            editFrame.status:SetText("|cFFFFFF00Slot reset to default|r")
            
            if KDT.mainFrame and KDT.mainFrame.RefreshBis then
                KDT.mainFrame:RefreshBis()
            end
        end
    end)
    
    return editFrame
end

-- Open edit dialog for a slot
local function OpenEditDialog(slot, itemData)
    local dialog = CreateEditDialog()
    
    dialog.currentSlot = slot
    dialog.slotValue:SetText(KDT.SLOT_NAMES[slot] or slot)
    
    -- Fill in current data
    dialog.idBox:SetText(tostring(itemData.itemID or itemData.id or 0))
    dialog.nameBox:SetText(itemData.name or "")
    dialog.detailBox:SetText(itemData.sourceDetail or itemData.detail or "")
    dialog.enchantBox:SetText(tostring(itemData.enchant or 0))
    dialog.popBox:SetText(tostring(itemData.popularity or 0))
    
    -- Gems
    local gemStr = ""
    if itemData.gems and #itemData.gems > 0 then
        gemStr = table.concat(itemData.gems, ", ")
    end
    dialog.gemBox:SetText(gemStr)
    
    -- Set source
    dialog.selectedSource = itemData.source or "RAID"
    if dialog.UpdateSourceButtons then
        dialog.UpdateSourceButtons()
    end
    
    dialog.status:SetText("")
    dialog:Show()
end

-- Setup BiS Tab
function KDT:SetupBisTab(f)
    local c = f.content
    local e = f.bisElements
    
    -- Title
    e.title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    e.title:SetPoint("TOPLEFT", 15, -15)
    e.title:SetText("BiS GEAR (Best in Slot)")
    e.title:SetTextColor(1, 0.84, 0)
    
    -- Subtitle with spec info
    e.specInfo = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.specInfo:SetPoint("TOPLEFT", e.title, "BOTTOMLEFT", 0, -5)
    e.specInfo:SetText("Loading spec...")
    e.specInfo:SetTextColor(0.7, 0.7, 0.7)
    
    -- Data source info
    e.sourceInfo = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.sourceInfo:SetPoint("TOPRIGHT", c, "TOPRIGHT", -15, -15)
    e.sourceInfo:SetText("Data: Archon.gg | Season 3")
    e.sourceInfo:SetTextColor(0, 0.83, 1)
    
    -- Legend box (relative width)
    e.legendBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.legendBox:SetHeight(28)
    e.legendBox:SetPoint("TOPLEFT", e.specInfo, "BOTTOMLEFT", 0, -10)
    e.legendBox:SetPoint("RIGHT", c, "RIGHT", -10, 0)
    e.legendBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    e.legendBox:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
    
    -- Legend items
    local legendX = 10
    local legends = {
        {source = "RAID", text = "Raid"},
        {source = "MYTHIC_PLUS", text = "M+"},
        {source = "CRAFTED", text = "Crafted"},
    }
    
    for _, legend in ipairs(legends) do
        local color = SOURCE_COLORS[legend.source]
        local dot = e.legendBox:CreateTexture(nil, "ARTWORK")
        dot:SetSize(10, 10)
        dot:SetPoint("LEFT", legendX, 0)
        dot:SetColorTexture(color[1], color[2], color[3], 1)
        
        local text = e.legendBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", dot, "RIGHT", 5, 0)
        text:SetText(legend.text)
        text:SetTextColor(0.8, 0.8, 0.8)
        
        legendX = legendX + text:GetStringWidth() + 30
    end
    
    -- Edit hint
    local editHint = e.legendBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editHint:SetPoint("RIGHT", e.legendBox, "RIGHT", -10, 0)
    editHint:SetText("|cFF888888Right-click to edit|r")
    
    -- Scroll frame for BiS list
    e.scroll = CreateFrame("ScrollFrame", "KryosDTBisScroll", c, "UIPanelScrollFrameTemplate")
    e.scroll:SetPoint("TOPLEFT", e.legendBox, "BOTTOMLEFT", 0, -10)
    e.scroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -28, 45)
    
    e.scrollChild = CreateFrame("Frame", nil, e.scroll)
    e.scrollChild:SetWidth(e.scroll:GetWidth() or 650)
    e.scrollChild:SetHeight(900)
    e.scroll:SetScrollChild(e.scrollChild)
    
    -- Button row
    e.refreshBtn = self:CreateButton(c, "Refresh", 80, 22)
    e.refreshBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.refreshBtn:SetScript("OnClick", function() f:RefreshBis() end)
    
    e.resetAllBtn = self:CreateButton(c, "Reset All", 80, 22)
    e.resetAllBtn:SetPoint("LEFT", e.refreshBtn, "RIGHT", 10, 0)
    e.resetAllBtn:SetScript("OnClick", function()
        StaticPopup_Show("KDT_RESET_BIS_CONFIRM")
    end)
    
    -- Confirmation popup
    StaticPopupDialogs["KDT_RESET_BIS_CONFIRM"] = {
        text = "Reset all BiS data for this spec?",
        button1 = "Ja",
        button2 = "Nein",
        OnAccept = function()
            local specID = KDT:GetPlayerSpecID()
            KDT:ResetAllCustomBis(specID)
            KDT:Print("BiS data reset for " .. KDT:GetSpecName(specID))
            if f.RefreshBis then f:RefreshBis() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

-- Refresh BiS display
function KDT:SetupBisRefresh(f)
    f.bisRows = f.bisRows or {}
    
    function f:RefreshBis()
        local e = self.bisElements
        if not e then return end
        
        -- Clear existing rows
        for _, row in ipairs(self.bisRows) do
            if row then row:Hide(); row:SetParent(nil) end
        end
        wipe(self.bisRows)
        
        -- Get player info
        local _, playerClass = UnitClass("player")
        local specID = KDT:GetPlayerSpecID()
        local specName = KDT:GetSpecName(specID)
        
        -- Update spec info text
        local classColor = KDT.CLASS_COLORS[playerClass] or {1, 1, 1}
        local classColorHex = string.format("%02x%02x%02x", classColor[1]*255, classColor[2]*255, classColor[3]*255)
        local className = KDT.CLASS_NAMES[playerClass] or playerClass or "Unknown"
        
        e.specInfo:SetText("|cFF" .. classColorHex .. className .. "|r - " .. specName)
        
        -- Update source info
        local hasCustom = KDT:HasCustomBisData(specID)
        if hasCustom then
            e.sourceInfo:SetText("|cFF00FF00Custom|r | Season 3")
        else
            e.sourceInfo:SetText("Data: |cFF00D4FFArchon.gg|r | Season 3")
        end
        
        -- Get BiS data
        local bisData = KDT:GetBisForSpec(specID)
        
        -- Update scroll child width
        local scrollWidth = e.scroll:GetWidth() or 650
        e.scrollChild:SetWidth(scrollWidth - 5)
        
        -- Column positions
        local COL_SLOT = 10
        local COL_ITEM = 90
        local COL_POP = scrollWidth - 75
        
        -- Create rows for each slot
        local yOffset = 0
        local rowHeight = 46
        
        for i, slot in ipairs(KDT.SLOT_ORDER) do
            local item = bisData[slot]
            if item then
                local row = CreateFrame("Frame", nil, e.scrollChild, "BackdropTemplate")
                row:SetHeight(rowHeight)
                row:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", 0, yOffset)
                row:SetPoint("RIGHT", e.scrollChild, "RIGHT", 0, 0)
                row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                row:SetBackdropColor(i % 2 == 0 and 0.08 or 0.05, i % 2 == 0 and 0.08 or 0.05, i % 2 == 0 and 0.1 or 0.07, 0.95)
                
                row.itemData = item
                row.slotName = slot
                row.rowIndex = i
                
                -- Slot name column (left aligned, vertically centered)
                local slotText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                slotText:SetPoint("LEFT", COL_SLOT, 0)
                slotText:SetWidth(70)
                slotText:SetJustifyH("LEFT")
                slotText:SetText(KDT.SLOT_NAMES[slot] or slot)
                slotText:SetTextColor(0.6, 0.6, 0.6)
                
                -- Source indicator bar
                local sourceColor = SOURCE_COLORS[item.source] or SOURCE_COLORS.UNKNOWN
                local sourceIndicator = row:CreateTexture(nil, "ARTWORK")
                sourceIndicator:SetSize(3, rowHeight - 12)
                sourceIndicator:SetPoint("LEFT", COL_ITEM - 5, 0)
                sourceIndicator:SetColorTexture(sourceColor[1], sourceColor[2], sourceColor[3], 1)
                
                -- Item name (line 1)
                local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetPoint("TOPLEFT", COL_ITEM, -5)
                itemText:SetPoint("RIGHT", row, "RIGHT", -80, 0)
                itemText:SetJustifyH("LEFT")
                
                local itemColor = "|cFFFFFFFF"
                if item.source == "RAID" then itemColor = "|cFFFF8000"
                elseif item.source == "MYTHIC_PLUS" then itemColor = "|cFFA335EE"
                elseif item.source == "CRAFTED" then itemColor = "|cFF00FF00" end
                itemText:SetText(itemColor .. (item.name or "Unknown") .. "|r")
                
                -- Source detail (line 2)
                local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                sourceText:SetPoint("TOPLEFT", itemText, "BOTTOMLEFT", 0, -1)
                sourceText:SetPoint("RIGHT", row, "RIGHT", -80, 0)
                sourceText:SetJustifyH("LEFT")
                local sourceLabel = KDT.BIS_SOURCE[item.source] or item.source
                sourceText:SetText("|cFF666666" .. sourceLabel .. ": " .. (item.sourceDetail or "Unknown") .. "|r")
                
                -- Enchant & Gems (line 3) - NO UNICODE SYMBOLS
                local enhanceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                enhanceText:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -1)
                enhanceText:SetPoint("RIGHT", row, "RIGHT", -80, 0)
                enhanceText:SetJustifyH("LEFT")
                
                local enhanceParts = {}
                if item.enchant and item.enchant > 0 then
                    local enchName = KDT:GetEnchantName(item.enchant) or ("ID:" .. item.enchant)
                    table.insert(enhanceParts, "|cFF00FF00E:|r " .. enchName)
                end
                if item.gems and #item.gems > 0 then
                    local gemNames = {}
                    for _, gemID in ipairs(item.gems) do
                        local gemName = KDT:GetGemName(gemID) or ("ID:" .. gemID)
                        table.insert(gemNames, gemName)
                    end
                    table.insert(enhanceParts, "|cFF00D4FFG:|r " .. table.concat(gemNames, ", "))
                end
                if #enhanceParts > 0 then
                    enhanceText:SetText(table.concat(enhanceParts, "  "))
                else
                    enhanceText:SetText("|cFF444444-|r")
                end
                
                -- Popularity (right column, top)
                local popText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                popText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -6)
                popText:SetJustifyH("RIGHT")
                local pop = item.popularity or 0
                local popColor = pop >= 50 and "|cFF00FF00" or (pop >= 25 and "|cFFFFFF00" or "|cFFFF8800")
                popText:SetText(popColor .. string.format("%.1f%%", pop) .. "|r")
                
                -- Stats (right column, below pop)
                local statsText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                statsText:SetPoint("TOPRIGHT", popText, "BOTTOMRIGHT", 0, -2)
                statsText:SetJustifyH("RIGHT")
                statsText:SetText("|cFFAAFF00" .. (item.stats or "") .. "|r")
                
                -- Mouse interaction (use SetScript for click detection)
                row:EnableMouse(true)
                
                row:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.15, 0.15, 0.2, 1)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    
                    local data = self.itemData
                    if data and data.itemID and data.itemID > 0 then
                        GameTooltip:SetItemByID(data.itemID)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cFF00D4FF--- KDT Info ---|r")
                        GameTooltip:AddDoubleLine("Popularity:", string.format("%.1f%%", data.popularity or 0), 0.7, 0.7, 0.7, 1, 1, 1)
                        if data.enchant and data.enchant > 0 then
                            local eName = KDT:GetEnchantName(data.enchant) or "Unknown"
                            GameTooltip:AddDoubleLine("Best Enchant:", eName, 0.7, 0.7, 0.7, 0, 1, 0)
                        end
                        if data.gems and #data.gems > 0 then
                            local gemNames = {}
                            for _, gid in ipairs(data.gems) do
                                table.insert(gemNames, KDT:GetGemName(gid) or "Unknown")
                            end
                            GameTooltip:AddDoubleLine("Best Gems:", table.concat(gemNames, ", "), 0.7, 0.7, 0.7, 0, 0.83, 1)
                        end
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cFFFFFF00Right-click to edit|r")
                    else
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine((data.name or "Unknown"), 1, 1, 1)
                        GameTooltip:AddLine("|cFFFFFF00Right-click to edit|r")
                    end
                    GameTooltip:Show()
                end)
                
                row:SetScript("OnLeave", function(self)
                    local idx = self.rowIndex or 1
                    self:SetBackdropColor(idx % 2 == 0 and 0.08 or 0.05, idx % 2 == 0 and 0.08 or 0.05, idx % 2 == 0 and 0.1 or 0.07, 0.95)
                    GameTooltip:Hide()
                end)
                
                row:SetScript("OnMouseUp", function(self, button)
                    if button == "RightButton" then
                        OpenEditDialog(self.slotName, self.itemData)
                    end
                end)
                
                row:Show()
                self.bisRows[#self.bisRows + 1] = row
                yOffset = yOffset - (rowHeight + 2)
            end
        end
        
        e.scrollChild:SetHeight(math.max(100, math.abs(yOffset) + 20))
    end
end

-- Save custom BiS slot
function KDT:SaveCustomBisSlot(specID, slot, itemData)
    if not KryosDungeonToolDB then KryosDungeonToolDB = {} end
    if not KryosDungeonToolDB.customBis then KryosDungeonToolDB.customBis = {} end
    if not KryosDungeonToolDB.customBis[specID] then KryosDungeonToolDB.customBis[specID] = {} end
    
    KryosDungeonToolDB.customBis[specID][slot] = itemData
end

-- Reset custom BiS slot to default
function KDT:ResetCustomBisSlot(specID, slot)
    if KryosDungeonToolDB and KryosDungeonToolDB.customBis and KryosDungeonToolDB.customBis[specID] then
        KryosDungeonToolDB.customBis[specID][slot] = nil
    end
end

-- Reset all custom BiS for spec
function KDT:ResetAllCustomBis(specID)
    if KryosDungeonToolDB and KryosDungeonToolDB.customBis then
        KryosDungeonToolDB.customBis[specID] = nil
    end
end

-- Check if spec has custom data
function KDT:HasCustomBisData(specID)
    if KryosDungeonToolDB and KryosDungeonToolDB.customBis and KryosDungeonToolDB.customBis[specID] then
        for _ in pairs(KryosDungeonToolDB.customBis[specID]) do
            return true
        end
    end
    return false
end

-- Override GetBisForSpec to include custom data
local baseGetBisForSpec = nil
function KDT:GetBisForSpec(specID)
    -- Get base data
    local baseData = {}
    
    -- Check default data first
    if KDT.BIS_DATA and KDT.BIS_DATA[specID] then
        for slot, item in pairs(KDT.BIS_DATA[specID]) do
            if item then
                baseData[slot] = {}
                for k, v in pairs(item) do
                    baseData[slot][k] = v
                end
            end
        end
    else
        -- Use default placeholder data
        local defaultData = KDT:GetDefaultBisData()
        for slot, item in pairs(defaultData) do
            baseData[slot] = {}
            for k, v in pairs(item) do
                baseData[slot][k] = v
            end
        end
    end
    
    -- Override with custom data
    if KryosDungeonToolDB and KryosDungeonToolDB.customBis and KryosDungeonToolDB.customBis[specID] then
        for slot, customItem in pairs(KryosDungeonToolDB.customBis[specID]) do
            baseData[slot] = {
                name = customItem.name,
                itemID = customItem.id or customItem.itemID or 0,
                source = customItem.source or "RAID",
                sourceDetail = customItem.detail or customItem.sourceDetail or "",
                stats = customItem.stats or "",
                popularity = customItem.popularity or 0,
                enchant = customItem.enchant,
                gems = customItem.gems,
            }
        end
    end
    
    return baseData
end
