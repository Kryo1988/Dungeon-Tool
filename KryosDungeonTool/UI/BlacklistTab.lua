-- Kryos Dungeon Tool
-- UI/BlacklistTab.lua - Blacklist tab UI with custom dropdowns, server support

local addonName, KDT = ...

-- Class colors for display
local CLASS_COLORS = {
    WARRIOR = {r=0.78, g=0.61, b=0.43},
    PALADIN = {r=0.96, g=0.55, b=0.73},
    HUNTER = {r=0.67, g=0.83, b=0.45},
    ROGUE = {r=1.00, g=0.96, b=0.41},
    PRIEST = {r=1.00, g=1.00, b=1.00},
    DEATHKNIGHT = {r=0.77, g=0.12, b=0.23},
    SHAMAN = {r=0.00, g=0.44, b=0.87},
    MAGE = {r=0.41, g=0.80, b=0.94},
    WARLOCK = {r=0.58, g=0.51, b=0.79},
    MONK = {r=0.00, g=1.00, b=0.59},
    DRUID = {r=1.00, g=0.49, b=0.04},
    DEMONHUNTER = {r=0.64, g=0.19, b=0.79},
    EVOKER = {r=0.20, g=0.58, b=0.50},
}

local CLASS_NAMES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", 
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", 
    "MONK", "DRUID", "DEMONHUNTER", "EVOKER"
}

local CLASS_DISPLAY_NAMES = {
    WARRIOR = "Warrior",
    PALADIN = "Paladin",
    HUNTER = "Hunter",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    DEATHKNIGHT = "Death Knight",
    SHAMAN = "Shaman",
    MAGE = "Mage",
    WARLOCK = "Warlock",
    MONK = "Monk",
    DRUID = "Druid",
    DEMONHUNTER = "Demon Hunter",
    EVOKER = "Evoker",
}

-- ==================== CUSTOM DROPDOWN CREATION ====================
local function CreateCustomDropdown(parent, width, onSelect)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(width, 20)  -- Same height as CreateInput (20px)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdown:SetBackdropColor(0.05, 0.05, 0.07, 1)
    dropdown:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)  -- Same as CreateInput
    
    dropdown.selectedValue = nil
    dropdown.selectedText = nil
    
    -- Text display
    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")  -- Same font as input
    dropdown.text:SetPoint("LEFT", 5, 0)
    dropdown.text:SetPoint("RIGHT", -15, 0)
    dropdown.text:SetJustifyH("LEFT")
    dropdown.text:SetText("|cFF666666Select...|r")
    
    -- Arrow using simple "v" character
    dropdown.arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdown.arrow:SetPoint("RIGHT", -4, 0)
    dropdown.arrow:SetText("v")
    dropdown.arrow:SetTextColor(0.5, 0.5, 0.5)
    
    -- Dropdown menu frame
    dropdown.menu = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    dropdown.menu:SetWidth(width + 30)
    dropdown.menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdown.menu:SetBackdropColor(0.08, 0.08, 0.1, 0.98)
    dropdown.menu:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    dropdown.menu:SetFrameStrata("TOOLTIP")
    dropdown.menu:SetFrameLevel(100)
    dropdown.menu:Hide()
    
    dropdown.menuItems = {}
    
    function dropdown:SetValue(value, text)
        self.selectedValue = value
        self.selectedText = text
        if value and CLASS_COLORS[value] then
            local c = CLASS_COLORS[value]
            self.text:SetText(string.format("|cFF%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, text or CLASS_DISPLAY_NAMES[value]))
        elseif text then
            self.text:SetText("|cFFAAAAAA" .. text .. "|r")
        else
            self.text:SetText("|cFF666666Select...|r")
        end
    end
    
    function dropdown:GetValue()
        return self.selectedValue
    end
    
    function dropdown:Clear()
        self.selectedValue = nil
        self.selectedText = nil
        self.text:SetText("|cFF666666Select...|r")
    end
    
    function dropdown:PopulateClassMenu()
        -- Clear existing items
        for _, item in ipairs(self.menuItems) do
            item:Hide()
        end
        wipe(self.menuItems)
        
        local yOffset = -4
        local itemHeight = 18
        
        -- "Unknown" option
        local unknownItem = CreateFrame("Button", nil, self.menu, "BackdropTemplate")
        unknownItem:SetHeight(itemHeight)
        unknownItem:SetPoint("TOPLEFT", 4, yOffset)
        unknownItem:SetPoint("TOPRIGHT", -4, yOffset)
        unknownItem:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        unknownItem:SetBackdropColor(0, 0, 0, 0)
        
        local unknownText = unknownItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        unknownText:SetPoint("LEFT", 5, 0)
        unknownText:SetText("|cFF888888Unknown|r")
        
        unknownItem:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.2, 0.25, 1) end)
        unknownItem:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
        unknownItem:SetScript("OnClick", function()
            dropdown:SetValue(nil, "Unknown")
            dropdown.menu:Hide()
            if onSelect then onSelect(nil) end
        end)
        
        table.insert(self.menuItems, unknownItem)
        yOffset = yOffset - itemHeight
        
        -- Class options
        for _, class in ipairs(CLASS_NAMES) do
            local item = CreateFrame("Button", nil, self.menu, "BackdropTemplate")
            item:SetHeight(itemHeight)
            item:SetPoint("TOPLEFT", 4, yOffset)
            item:SetPoint("TOPRIGHT", -4, yOffset)
            item:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
            item:SetBackdropColor(0, 0, 0, 0)
            
            local color = CLASS_COLORS[class]
            local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            itemText:SetPoint("LEFT", 5, 0)
            itemText:SetText(string.format("|cFF%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, CLASS_DISPLAY_NAMES[class]))
            
            -- Color indicator bar
            local colorBar = item:CreateTexture(nil, "ARTWORK")
            colorBar:SetSize(3, itemHeight - 4)
            colorBar:SetPoint("RIGHT", -2, 0)
            colorBar:SetColorTexture(color.r, color.g, color.b, 1)
            
            item:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.2, 0.25, 1) end)
            item:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
            item:SetScript("OnClick", function()
                dropdown:SetValue(class, CLASS_DISPLAY_NAMES[class])
                dropdown.menu:Hide()
                if onSelect then onSelect(class) end
            end)
            
            table.insert(self.menuItems, item)
            yOffset = yOffset - itemHeight
        end
        
        self.menu:SetHeight(math.abs(yOffset) + 8)
    end
    
    -- Toggle menu on click
    dropdown:EnableMouse(true)
    dropdown:SetScript("OnMouseDown", function(self)
        if self.menu:IsShown() then
            self.menu:Hide()
        else
            self:PopulateClassMenu()
            self.menu:Show()
        end
    end)
    
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)
    
    -- Close menu when clicking elsewhere
    dropdown.menu:SetScript("OnShow", function(self)
        self:SetPropagateKeyboardInput(true)
    end)
    
    return dropdown
end

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
    e.nameLabel:SetText("Name-Server")
    e.nameLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.nameInput = self:CreateInput(e.box, 120)
    e.nameInput:SetPoint("TOPLEFT", 10, -42)
    e.nameInput:SetMaxLetters(50) -- Allow longer names with server
    
    -- Class dropdown (custom styled)
    e.classLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.classLabel:SetPoint("TOPLEFT", 140, -28)
    e.classLabel:SetText("Class")
    e.classLabel:SetTextColor(0.5, 0.5, 0.5)
    
    e.classDropdown = CreateCustomDropdown(e.box, 95, function(class)
        e.selectedClass = class
    end)
    e.classDropdown:SetPoint("TOPLEFT", 140, -42)
    e.selectedClass = nil
    
    e.reasonLabel = e.box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.reasonLabel:SetPoint("TOPLEFT", 245, -28)
    e.reasonLabel:SetText("Reason")
    e.reasonLabel:SetTextColor(0.5, 0.5, 0.5)
    
    -- Add button (anchored to right side)
    e.addBtn = self:CreateButton(e.box, "Add", 55, 22)
    e.addBtn:SetPoint("TOPRIGHT", e.box, "TOPRIGHT", -10, -42)
    e.addBtn:SetBackdropColor(0.15, 0.35, 0.6, 1)
    e.addBtn:SetScript("OnClick", function()
        local n = e.nameInput:GetText()
        if n and n ~= "" then
            KDT:AddToBlacklist(n, e.reasonInput:GetText(), e.classDropdown:GetValue())
            e.nameInput:SetText("")
            e.reasonInput:SetText("")
            e.classDropdown:Clear()
            e.selectedClass = nil
            f:RefreshBlacklist()
        end
    end)
    e.addBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.2, 0.45, 0.7, 1) end)
    e.addBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.35, 0.6, 1) end)
    
    -- Reason input stretches to Add button
    e.reasonInput = self:CreateInput(e.box, 100)
    e.reasonInput:SetPoint("TOPLEFT", 245, -42)
    e.reasonInput:SetPoint("RIGHT", e.addBtn, "LEFT", -10, 0)
    e.reasonInput:SetMaxLetters(100)
    
    e.nameInput:SetScript("OnEnterPressed", function() e.reasonInput:SetFocus() end)
    e.reasonInput:SetScript("OnEnterPressed", function() e.addBtn:Click() end)
    
    -- Search Box
    e.searchBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
    e.searchBox:SetPoint("TOPLEFT", e.box, "BOTTOMLEFT", 0, -8)
    e.searchBox:SetPoint("TOPRIGHT", e.box, "BOTTOMRIGHT", 0, -8)
    e.searchBox:SetHeight(28)
    e.searchBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    e.searchBox:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    e.searchBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    
    e.searchIcon = e.searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.searchIcon:SetPoint("LEFT", 10, 0)
    e.searchIcon:SetText("|cFF888888Search:|r")
    
    e.searchInput = self:CreateInput(e.searchBox, 200)
    e.searchInput:SetPoint("LEFT", e.searchIcon, "RIGHT", 5, 0)
    e.searchInput:SetPoint("RIGHT", e.searchBox, "RIGHT", -10, 0)
    e.searchInput:SetMaxLetters(50)
    e.searchInput:SetScript("OnTextChanged", function(self)
        f:RefreshBlacklist()
    end)
    
    -- List Title
    e.listTitle = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    e.listTitle:SetPoint("TOPLEFT", e.searchBox, "BOTTOMLEFT", 0, -8)
    e.listTitle:SetText("BLACKLISTED PLAYERS")
    e.listTitle:SetTextColor(0.8, 0.8, 0.8)
    
    e.countText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.countText:SetPoint("LEFT", e.listTitle, "RIGHT", 10, 0)
    e.countText:SetTextColor(0.5, 0.5, 0.5)
    
    -- Scroll Frame with INVISIBLE scrollbar
    e.scroll = CreateFrame("ScrollFrame", "KryosDTBlacklistScroll", c, "UIPanelScrollFrameTemplate")
    e.scroll:SetPoint("TOPLEFT", e.listTitle, "BOTTOMLEFT", 0, -5)
    e.scroll:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -10, 45)
    
    -- Hide the scrollbar but keep functionality
    local scrollBar = e.scroll.ScrollBar or _G["KryosDTBlacklistScrollScrollBar"]
    if scrollBar then
        scrollBar:SetAlpha(0)
        scrollBar:SetWidth(1)
        scrollBar:EnableMouse(false)
        if scrollBar.ScrollUpButton then scrollBar.ScrollUpButton:SetAlpha(0) scrollBar.ScrollUpButton:EnableMouse(false) end
        if scrollBar.ScrollDownButton then scrollBar.ScrollDownButton:SetAlpha(0) scrollBar.ScrollDownButton:EnableMouse(false) end
        local upBtn = _G["KryosDTBlacklistScrollScrollBarScrollUpButton"]
        local downBtn = _G["KryosDTBlacklistScrollScrollBarScrollDownButton"]
        if upBtn then upBtn:SetAlpha(0) upBtn:EnableMouse(false) end
        if downBtn then downBtn:SetAlpha(0) downBtn:EnableMouse(false) end
    end
    
    e.scrollChild = CreateFrame("Frame", nil, e.scroll)
    e.scrollChild:SetHeight(1)
    e.scroll:SetScrollChild(e.scrollChild)
    
    -- Enable mouse wheel scrolling
    e.scroll:EnableMouseWheel(true)
    e.scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * 45)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    -- Bottom Buttons
    e.clearBtn = self:CreateButton(c, "Clear All", 80, 22)
    e.clearBtn:SetPoint("BOTTOMLEFT", 10, 12)
    e.clearBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
    e.clearBtn:SetScript("OnClick", function()
        StaticPopupDialogs["KRYOS_CLEAR"] = {
            text = "Clear entire blacklist?",
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
    
    e.soundCheck = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    e.soundCheck:SetSize(20, 20)
    e.soundCheck:SetPoint("LEFT", e.clearBtn, "RIGHT", 15, 0)
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
        
        -- Get search filter
        local searchFilter = e.searchInput:GetText():lower()
        
        local sorted = {}
        for name, data in pairs(KDT.DB.blacklist) do
            -- Apply search filter
            local matchesSearch = searchFilter == "" or 
                name:lower():find(searchFilter, 1, true) or
                (data.reason and data.reason:lower():find(searchFilter, 1, true)) or
                (data.class and CLASS_DISPLAY_NAMES[data.class] and CLASS_DISPLAY_NAMES[data.class]:lower():find(searchFilter, 1, true))
            
            if matchesSearch then
                sorted[#sorted + 1] = {name = name, data = data}
            end
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        
        -- Update count display
        local totalCount = 0
        for _ in pairs(KDT.DB.blacklist) do totalCount = totalCount + 1 end
        if searchFilter ~= "" then
            e.countText:SetText("(" .. #sorted .. "/" .. totalCount .. ")")
        else
            e.countText:SetText("(" .. totalCount .. ")")
        end
        
        -- Set scrollChild width dynamically
        local scrollWidth = e.scroll:GetWidth() or 600
        e.scrollChild:SetWidth(scrollWidth - 5)
        
        local yOffset = 0
        for _, entry in ipairs(sorted) do
            local row = CreateFrame("Frame", nil, e.scrollChild, "BackdropTemplate")
            row:SetHeight(42)
            row:SetPoint("TOPLEFT", e.scrollChild, "TOPLEFT", 0, yOffset)
            row:SetPoint("RIGHT", e.scrollChild, "RIGHT", 0, 0)
            row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
            row:SetBackdropColor(0.07, 0.07, 0.09, 0.95)
            
            -- Enable mouse wheel on rows
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function(self, delta)
                local scroll = e.scroll
                local current = scroll:GetVerticalScroll()
                local maxScroll = scroll:GetVerticalScrollRange()
                local newScroll = current - (delta * 45)
                newScroll = math.max(0, math.min(newScroll, maxScroll))
                scroll:SetVerticalScroll(newScroll)
            end)
            
            -- Class color indicator
            local classColor = entry.data.class and CLASS_COLORS[entry.data.class]
            local classIndicator = row:CreateTexture(nil, "ARTWORK")
            classIndicator:SetSize(4, 30)
            classIndicator:SetPoint("LEFT", 2, 0)
            classIndicator:SetColorTexture(
                classColor and classColor.r or 0.5,
                classColor and classColor.g or 0.5,
                classColor and classColor.b or 0.5,
                1
            )
            
            -- Parse name and server
            local displayName = entry.name
            local nameOnly = entry.name:match("^([^%-]+)") or entry.name
            local server = entry.name:match("%-(.+)$")
            
            -- Player name with class color
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", 12, -6)
            if classColor then
                nameText:SetText(string.format("|cFF%02x%02x%02x%s|r", 
                    classColor.r*255, classColor.g*255, classColor.b*255, nameOnly))
            else
                nameText:SetText("|cFFFF6666" .. nameOnly .. "|r")
            end
            
            -- Server name (smaller, grayed out)
            if server then
                local serverText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                serverText:SetPoint("LEFT", nameText, "RIGHT", 2, 0)
                serverText:SetText("|cFF666666-" .. server .. "|r")
            end
            
            -- Class name display
            local classText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            classText:SetPoint("TOPLEFT", 12, -20)
            if entry.data.class and CLASS_DISPLAY_NAMES[entry.data.class] then
                local c = CLASS_COLORS[entry.data.class]
                classText:SetText(string.format("|cFF%02x%02x%02x%s|r", c.r*128+64, c.g*128+64, c.b*128+64, CLASS_DISPLAY_NAMES[entry.data.class]))
            end
            
            -- Reason
            local reason = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            reason:SetPoint("LEFT", classText, "RIGHT", 10, 0)
            reason:SetPoint("RIGHT", row, "RIGHT", -140, 0)
            reason:SetJustifyH("LEFT")
            if entry.data.reason and entry.data.reason ~= "" then
                reason:SetText("|cFF888888" .. entry.data.reason .. "|r")
            end
            
            -- Date
            local date = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            date:SetPoint("TOPRIGHT", -130, -6)
            date:SetText(entry.data.date or "")
            date:SetTextColor(0.4, 0.4, 0.4)
            
            -- Edit Button
            local editBtn = KDT:CreateButton(row, "Edit", 50, 20)
            editBtn:SetPoint("RIGHT", -70, 0)
            editBtn:SetBackdropColor(0.3, 0.3, 0.5, 1)
            local entryName = entry.name
            local entryData = entry.data
            editBtn:SetScript("OnClick", function()
                KDT:ShowEditBlacklistDialog(entryName, entryData, f)
            end)
            editBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.4, 0.4, 0.6, 1) end)
            editBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.3, 0.3, 0.5, 1) end)
            
            -- Delete Button
            local delBtn = KDT:CreateButton(row, "Delete", 55, 20)
            delBtn:SetPoint("RIGHT", -8, 0)
            delBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
            delBtn:SetScript("OnClick", function()
                KDT:RemoveFromBlacklist(entry.name)
                f:RefreshBlacklist()
            end)
            delBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.2, 0.2, 1) end)
            delBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.15, 0.15, 1) end)
            
            self.blRows[#self.blRows + 1] = row
            yOffset = yOffset - 45
        end
        
        if #sorted == 0 then
            local empty = e.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            empty:SetPoint("TOP", e.scrollChild, "TOP", 0, -30)
            if searchFilter ~= "" then
                empty:SetText("No players found matching '" .. searchFilter .. "'")
            else
                empty:SetText("Blacklist is empty")
            end
            empty:SetTextColor(0.4, 0.4, 0.4)
            local frame = CreateFrame("Frame", nil, e.scrollChild)
            frame.text = empty
            self.blRows[#self.blRows + 1] = frame
        end
        
        e.scrollChild:SetHeight(math.max(1, math.abs(yOffset)))
    end
end

-- ==================== EDIT DIALOG ====================
function KDT:ShowEditBlacklistDialog(entryName, entryData, mainFrame)
    if self.editDialog then
        self.editDialog:Hide()
    end
    
    local dialog = CreateFrame("Frame", "KryosEditDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(380, 170)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    dialog:SetBackdropBorderColor(0.3, 0.3, 0.5, 1)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    -- Parse name for display
    local nameOnly = entryName:match("^([^%-]+)") or entryName
    local server = entryName:match("%-(.+)$")
    local displayName = nameOnly
    if server then
        displayName = nameOnly .. "|cFF666666-" .. server .. "|r"
    end
    
    local titleText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -12)
    titleText:SetText("Edit |cFFFF6666" .. displayName .. "|r")
    
    -- Reason
    local reasonLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reasonLabel:SetPoint("TOPLEFT", 20, -40)
    reasonLabel:SetText("Reason:")
    reasonLabel:SetTextColor(0.6, 0.6, 0.6)
    
    local editBox = CreateFrame("EditBox", nil, dialog, "BackdropTemplate")
    editBox:SetSize(340, 24)
    editBox:SetPoint("TOPLEFT", 20, -55)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    editBox:SetBackdropColor(0.05, 0.05, 0.07, 1)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetAutoFocus(true)
    editBox:SetText(entryData.reason or "")
    editBox:HighlightText()
    editBox:SetTextInsets(8, 8, 0, 0)
    
    -- Class dropdown (custom styled)
    local classLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classLabel:SetPoint("TOPLEFT", 20, -90)
    classLabel:SetText("Class:")
    classLabel:SetTextColor(0.6, 0.6, 0.6)
    
    local selectedClass = entryData.class
    
    local classDropdown = CreateCustomDropdown(dialog, 140, function(class)
        selectedClass = class
    end)
    classDropdown:SetPoint("TOPLEFT", 20, -105)
    
    if selectedClass and CLASS_DISPLAY_NAMES[selectedClass] then
        classDropdown:SetValue(selectedClass, CLASS_DISPLAY_NAMES[selectedClass])
    else
        classDropdown:SetValue(nil, "Unknown")
    end
    
    local saveBtn = self:CreateButton(dialog, "Save", 80, 24)
    saveBtn:SetPoint("BOTTOMLEFT", 80, 15)
    saveBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
    saveBtn:SetScript("OnClick", function()
        local newReason = editBox:GetText()
        if KDT.DB.blacklist[entryName] then
            KDT.DB.blacklist[entryName].reason = newReason
            KDT.DB.blacklist[entryName].class = selectedClass
        end
        dialog:Hide()
        mainFrame:RefreshBlacklist()
    end)
    
    local cancelBtn = self:CreateButton(dialog, "Cancel", 80, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", -80, 15)
    cancelBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    editBox:SetScript("OnEnterPressed", function()
        saveBtn:Click()
    end)
    
    editBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
    
    dialog:Show()
    self.editDialog = dialog
end
