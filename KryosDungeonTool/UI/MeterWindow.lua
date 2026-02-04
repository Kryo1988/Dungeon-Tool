-- Kryos Dungeon Tool
-- UI/MeterWindow.lua - Floating Damage/Heal Meter Window (Details-inspired)

local addonName, KDT = ...
local Meter = KDT.Meter

-- Mode categories for right-click menu (like Details)
local MODE_CATEGORIES = {
    {
        name = "Damage",
        icon = "Interface\\Icons\\ability_warrior_savageblow",
        modes = {
            { mode = Meter.MODES.DAMAGE, name = "Damage Done" },
            { mode = Meter.MODES.DPS, name = "DPS" },
            { mode = Meter.MODES.DAMAGE_TAKEN, name = "Damage Taken" },
        }
    },
    {
        name = "Heal",
        icon = "Interface\\Icons\\spell_holy_flashheal",
        modes = {
            { mode = Meter.MODES.HEALING, name = "Healing Done" },
            { mode = Meter.MODES.HPS, name = "HPS" },
        }
    },
    {
        name = "Miscellaneous",
        icon = "Interface\\Icons\\inv_misc_questionmark",
        modes = {
            { mode = Meter.MODES.INTERRUPTS, name = "Interrupts" },
            { mode = Meter.MODES.DEATHS, name = "Deaths" },
        }
    },
}

-- ==================== METER WINDOW CLASS ====================
local MeterWindowMixin = {}

function MeterWindowMixin:Initialize(id)
    self.id = id
    self.mode = Meter.MODES.DAMAGE
    self.viewingOverall = false  -- false = current segment, true = overall
    self.bars = {}
    self.settings = Meter.defaults
    
    self:CreateUI()
    Meter.windows[id] = self
end

function MeterWindowMixin:CreateUI()
    local settings = self.settings
    
    -- Main Frame
    local frame = CreateFrame("Frame", "KryosMeterWindow" .. self.id, UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(settings.windowWidth, settings.windowHeight)
    
    -- Load saved position and lock state
    local savedPos = nil
    local isLocked = false
    if KDT.DB and KDT.DB.meter then
        if KDT.DB.meter.windows then
            savedPos = KDT.DB.meter.windows["KryosMeterWindow" .. self.id]
        end
        if KDT.DB.meter.locked ~= nil then
            isLocked = KDT.DB.meter.locked
        end
    end
    self.isLocked = isLocked
    
    if savedPos then
        frame:ClearAllPoints()
        -- Support both old array format and new table format
        if savedPos.point then
            -- New format
            local relativeFrame = savedPos.relativeTo
            if type(relativeFrame) == "string" then
                relativeFrame = _G[relativeFrame] or UIParent
            end
            frame:SetPoint(savedPos.point, relativeFrame, savedPos.relativePoint, savedPos.x, savedPos.y)
            if savedPos.width and savedPos.height then
                frame:SetSize(savedPos.width, savedPos.height)
            end
        elseif savedPos[1] then
            -- Old array format (backward compatibility)
            local relativeFrame = savedPos[2]
            if type(relativeFrame) == "string" then
                relativeFrame = _G[relativeFrame] or UIParent
            end
            frame:SetPoint(savedPos[1], relativeFrame, savedPos[3], savedPos[4], savedPos[5])
        end
    else
        frame:SetPoint("CENTER", 200 + (self.id - 1) * 30, 0)
    end
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    frame:SetBackdropColor(unpack(settings.bgColor))
    frame:SetBackdropBorderColor(unpack(settings.borderColor))
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetClampRectInsets(0, 0, 0, 0) -- Prevent any part from going off screen
    frame:EnableMouse(true)
    frame:SetScale(settings.windowScale)
    frame.window = self
    
    -- Make frame draggable (respects lock)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) 
        -- Don't move if locked
        if self.isLocked then return end
        
        -- If docked to another window, move the parent instead
        if self.dockedTo then
            local parentWindow = Meter:GetWindow(self.dockedTo)
            if parentWindow and parentWindow.frame and not parentWindow.isLocked then
                parentWindow.frame:StartMoving()
                return
            end
        end
        f:StartMoving()
        -- Move docked children
        self:StartMovingDockedChildren()
    end)
    frame:SetScript("OnDragStop", function(f) 
        -- Don't process if locked
        if self.isLocked then return end
        
        -- If docked to another window, stop moving the parent
        if self.dockedTo then
            local parentWindow = Meter:GetWindow(self.dockedTo)
            if parentWindow and parentWindow.frame then
                parentWindow.frame:StopMovingOrSizing()
                -- Clamp parent position
                self:ClampToScreen(parentWindow.frame)
                return
            end
        end
        f:StopMovingOrSizing()
        -- Clamp position to screen
        self:ClampToScreen(f)
        self:StopMovingDockedChildren()
        -- Save position
        self:SavePosition()
    end)
    
    -- Resize handle
    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    self.resizeHandle = resizeHandle
    resizeHandle:SetScript("OnMouseDown", function()
        if self.isLocked then return end
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeHandle:SetScript("OnMouseUp", function()
        if self.isLocked then return end
        frame:StopMovingOrSizing()
        self:UpdateBars()
        self:SavePosition()
    end)
    -- WoW 12.0 uses SetResizeBounds instead of SetMinResize/SetMaxResize
    frame:SetResizeBounds(150, 80, 500, 600)
    
    -- Update resize handle visibility based on lock state
    if self.isLocked then
        resizeHandle:Hide()
    end
    
    -- ==================== TITLE BAR ====================
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(20)
    titleBar:EnableMouse(true)
    self.titleBar = titleBar
    
    -- TitleBar shows hover buttons
    titleBar:SetScript("OnEnter", function()
        if self.hoverButtons then
            self.hoverButtons:Show()
        end
    end)
    titleBar:SetScript("OnLeave", function()
        C_Timer.After(0.1, function()
            if frame:IsVisible() and self.hoverButtons then
                if not frame:IsMouseOver() and not self.hoverButtons:IsMouseOver() then
                    self.hoverButtons:Hide()
                end
            end
        end)
    end)
    
    -- Mode Label (left side) - clickable to switch paired mode
    local modeLabel = CreateFrame("Button", nil, titleBar)
    modeLabel:SetPoint("LEFT", 4, 0)
    modeLabel:SetHeight(20)
    modeLabel.text = modeLabel:CreateFontString(nil, "OVERLAY")
    modeLabel.text:SetFont(settings.font, 10, settings.fontFlags)
    modeLabel.text:SetPoint("LEFT")
    modeLabel.text:SetText(Meter.MODE_NAMES[self.mode] or "DMG Meter")
    modeLabel.text:SetTextColor(0.9, 0.8, 0.2)
    modeLabel:SetWidth(modeLabel.text:GetStringWidth() + 10)
    self.modeLabel = modeLabel
    
    -- Click to toggle paired mode (Damage <-> DPS, Healing <-> HPS)
    modeLabel:SetScript("OnClick", function()
        self:TogglePairedMode()
    end)
    modeLabel:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Click to toggle (e.g., Damage ↔ DPS)", 1, 1, 1)
        GameTooltip:Show()
    end)
    modeLabel:SetScript("OnLeave", function(self)
        self.text:SetTextColor(0.9, 0.8, 0.2)
        GameTooltip:Hide()
    end)
    
    -- Segment indicator (Overall / Current)
    local segmentText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    segmentText:SetPoint("LEFT", modeLabel, "RIGHT", 4, 0)
    segmentText:SetText("[Current]")
    segmentText:SetTextColor(0.5, 0.5, 0.5)
    self.segmentText = segmentText
    
    -- Combat Time (right side)
    local timeText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", -22, 0)
    timeText:SetTextColor(0.6, 0.6, 0.6)
    self.timeText = timeText
    
    -- Close Button (X)
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("RIGHT", -2, 0)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY")
    closeBtn.text:SetFont(settings.font, 14, settings.fontFlags)
    closeBtn.text:SetPoint("CENTER")
    closeBtn.text:SetText("×")
    closeBtn.text:SetTextColor(0.5, 0.5, 0.5)
    closeBtn:SetScript("OnClick", function() self:Hide() end)
    closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(0.5, 0.5, 0.5) end)
    
    -- ==================== HOVER BUTTONS (appear on mouse enter - ABOVE window) ====================
    -- Parent to UIParent so buttons appear above the window, not inside it
    local hoverButtons = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hoverButtons:SetHeight(22)
    hoverButtons:Hide()
    hoverButtons:SetFrameStrata("DIALOG")
    hoverButtons:SetFrameLevel(100)
    hoverButtons:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    hoverButtons:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    hoverButtons:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    self.hoverButtons = hoverButtons
    
    -- Position above the main frame
    local function UpdateHoverPosition()
        hoverButtons:ClearAllPoints()
        hoverButtons:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
        hoverButtons:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
    end
    UpdateHoverPosition()
    
    -- Update position when frame moves
    frame:HookScript("OnDragStop", UpdateHoverPosition)
    
    -- Compact buttons with shorter text
    local resetSegBtn = self:CreateHoverButton(hoverButtons, "Reset", 38)
    resetSegBtn:SetPoint("LEFT", 2, 0)
    resetSegBtn:SetScript("OnClick", function()
        Meter:Reset()  -- Use proper reset function
        self:Refresh()
    end)
    resetSegBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Reset Current Segment")
        GameTooltip:Show()
    end)
    resetSegBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Reset All Button
    local resetAllBtn = self:CreateHoverButton(hoverButtons, "All", 28)
    resetAllBtn:SetPoint("LEFT", resetSegBtn, "RIGHT", 2, 0)
    resetAllBtn:SetScript("OnClick", function()
        Meter:ResetAll()  -- Use proper reset all function
        self:Refresh()
    end)
    resetAllBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Reset All Data")
        GameTooltip:Show()
    end)
    resetAllBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Report Button
    local reportBtn = self:CreateHoverButton(hoverButtons, "Post", 32)
    reportBtn:SetPoint("LEFT", resetAllBtn, "RIGHT", 2, 0)
    reportBtn:SetScript("OnClick", function()
        self:ReportToChat()
    end)
    reportBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Report to Chat")
        GameTooltip:Show()
    end)
    reportBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Segments Dropdown Button
    local segBtn = self:CreateHoverButton(hoverButtons, "Seg", 32)
    segBtn:SetPoint("LEFT", reportBtn, "RIGHT", 2, 0)
    self.segBtn = segBtn
    segBtn:SetScript("OnClick", function()
        self:ShowSegmentDropdown(segBtn)
    end)
    segBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        -- Show dropdown on hover
        self:ShowSegmentDropdown(btn)
    end)
    segBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    -- Mode Selector Button
    local modeBtn = self:CreateHoverButton(hoverButtons, "Mode", 38)
    modeBtn:SetPoint("LEFT", segBtn, "RIGHT", 2, 0)
    modeBtn:SetScript("OnClick", function()
        self:ShowModeDropdown(modeBtn)
    end)
    modeBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Select display mode")
        GameTooltip:Show()
    end)
    modeBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Dock Button (to dock/undock windows)
    local dockBtn = self:CreateHoverButton(hoverButtons, "Dock", 34)
    dockBtn:SetPoint("LEFT", modeBtn, "RIGHT", 2, 0)
    self.dockBtn = dockBtn
    dockBtn:SetScript("OnClick", function()
        self:ToggleDock()
    end)
    dockBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        if self.dockedTo then
            GameTooltip:SetText("Undock from Window " .. self.dockedTo)
        else
            GameTooltip:SetText("Dock to previous window")
        end
        GameTooltip:Show()
    end)
    dockBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Lock Button
    local lockBtn = self:CreateHoverButton(hoverButtons, self.isLocked and "Unlk" or "Lock", 32)
    lockBtn:SetPoint("LEFT", dockBtn, "RIGHT", 2, 0)
    self.lockBtn = lockBtn
    lockBtn:SetScript("OnClick", function()
        self:ToggleLock()
    end)
    lockBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        if self.isLocked then
            GameTooltip:SetText("Unlock window (allow moving)")
        else
            GameTooltip:SetText("Lock window (prevent moving)")
        end
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    -- Update lock button color based on state
    if self.isLocked then
        lockBtn:SetBackdropColor(0.4, 0.2, 0.2, 1)
        lockBtn.text:SetTextColor(1, 0.5, 0.5)
    end
    
    -- Show/hide hover buttons on mouse enter/leave
    frame:SetScript("OnEnter", function()
        if frame:IsVisible() then
            hoverButtons:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        -- Check if mouse is over frame or hover buttons
        C_Timer.After(0.15, function()
            if not frame:IsVisible() then
                hoverButtons:Hide()
                return
            end
            if not frame:IsMouseOver() and not hoverButtons:IsMouseOver() then
                hoverButtons:Hide()
            end
        end)
    end)
    hoverButtons:SetScript("OnEnter", function()
        hoverButtons:Show()
    end)
    hoverButtons:SetScript("OnLeave", function()
        C_Timer.After(0.15, function()
            if not frame:IsVisible() then
                hoverButtons:Hide()
                return
            end
            if not frame:IsMouseOver() and not hoverButtons:IsMouseOver() then
                hoverButtons:Hide()
            end
        end)
    end)
    
    -- Hide hover buttons when main frame hides
    frame:HookScript("OnHide", function()
        hoverButtons:Hide()
    end)
    
    -- ==================== BAR CONTAINER ====================
    local barContainer = CreateFrame("Frame", nil, frame)
    barContainer:SetPoint("TOPLEFT", 4, -22)
    barContainer:SetPoint("BOTTOMRIGHT", -4, 4)
    self.barContainer = barContainer
    
    -- Right-click for context menu
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            self.window:ShowContextMenu()
        end
    end)
    
    self:CreateBars()
end

function MeterWindowMixin:CreateHoverButton(parent, text, width)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 16)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetFont(self.settings.font, 9, self.settings.fontFlags)
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(0.8, 0.8, 0.8)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.35, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.25, 1)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    return btn
end

function MeterWindowMixin:CreateBars()
    local settings = self.settings
    
    for i = 1, settings.maxBars do
        local bar = self:CreateBar(i)
        self.bars[i] = bar
    end
end

function MeterWindowMixin:CreateBar(index)
    local settings = self.settings
    local container = self.barContainer
    
    local bar = CreateFrame("Frame", nil, container, "BackdropTemplate")
    bar:SetHeight(settings.barHeight)
    bar:SetPoint("TOPLEFT", 0, -(index - 1) * (settings.barHeight + settings.barSpacing))
    bar:SetPoint("RIGHT", 0, 0)
    bar:Hide()
    
    -- Background
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(settings.barTexture)
    bg:SetVertexColor(0.1, 0.1, 0.12, 0.8)
    bar.bg = bg
    
    -- Status bar (colored part)
    local statusBar = bar:CreateTexture(nil, "ARTWORK")
    statusBar:SetPoint("TOPLEFT", 1, -1)
    statusBar:SetPoint("BOTTOMLEFT", 1, 1)
    statusBar:SetTexture(settings.barTexture)
    bar.statusBar = statusBar
    
    -- Rank number
    local rank = bar:CreateFontString(nil, "OVERLAY")
    rank:SetFont(settings.font, settings.fontSize - 1, settings.fontFlags)
    rank:SetPoint("LEFT", 4, 0)
    rank:SetWidth(14)
    rank:SetJustifyH("LEFT")
    bar.rank = rank
    
    -- Player name
    local name = bar:CreateFontString(nil, "OVERLAY")
    name:SetFont(settings.font, settings.fontSize, settings.fontFlags)
    name:SetPoint("LEFT", 20, 0)
    name:SetJustifyH("LEFT")
    bar.name = name
    
    -- Value (right side)
    local value = bar:CreateFontString(nil, "OVERLAY")
    value:SetFont(settings.font, settings.fontSize, settings.fontFlags)
    value:SetPoint("RIGHT", -4, 0)
    value:SetJustifyH("RIGHT")
    bar.value = value
    
    -- Percent
    local percent = bar:CreateFontString(nil, "OVERLAY")
    percent:SetFont(settings.font, settings.fontSize - 1, settings.fontFlags)
    percent:SetPoint("RIGHT", value, "LEFT", -4, 0)
    percent:SetJustifyH("RIGHT")
    percent:SetTextColor(0.7, 0.7, 0.7)
    bar.percent = percent
    
    name:SetPoint("RIGHT", percent, "LEFT", -4, 0)
    
    -- Store window reference on bar for tooltip
    bar.window = self
    
    -- Tooltip
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        if self.playerData and self.window then
            self.window:ShowBarTooltip(self)
        end
    end)
    bar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return bar
end

function MeterWindowMixin:Refresh()
    if not self.frame:IsShown() then return end
    
    local segmentName = Meter:GetSegmentName()
    
    -- Update mode label
    self.modeLabel.text:SetText(Meter.MODE_NAMES[self.mode] or "DMG Meter")
    self.modeLabel:SetWidth(self.modeLabel.text:GetStringWidth() + 10)
    
    -- Update segment text
    self.segmentText:SetText("[" .. segmentName .. "]")
    
    -- Check if we should use LIVE data from Blizzard API
    local useLiveData = Meter.isMidnight and C_DamageMeter and Meter.viewingSegmentIndex == 0 and Meter.inCombat
    
    if useLiveData then
        -- LIVE MODE: Bind secret values directly to UI widgets
        self:RefreshLive()
    else
        -- HISTORICAL MODE: Use stored segment data
        self:RefreshHistorical()
    end
end

function MeterWindowMixin:RefreshLive()
    -- Get live session from Blizzard API
    local blizzType = Meter.MODE_TO_BLIZZARD[self.mode]
    if not blizzType then
        self:RefreshHistorical()
        return
    end
    
    local session = C_DamageMeter.GetCombatSessionFromType(Enum.DamageMeterSessionType.Current, blizzType)
    if not session or not session.combatSources or #session.combatSources == 0 then
        self:RefreshHistorical()
        return
    end
    
    -- Update time from session
    if session.durationSeconds then
        local duration = session.durationSeconds
        -- Try to read duration, use live calculation if secret
        local durationValue = duration
        if issecretvalue and issecretvalue(duration) then
            -- Fallback to our own timer
            if Meter.currentSegment and Meter.currentSegment.startTime then
                durationValue = GetTime() - Meter.currentSegment.startTime
            else
                durationValue = 0
            end
        end
        local mins = math.floor(durationValue / 60)
        local secs = math.floor(durationValue % 60)
        self.timeText:SetText(string.format("%d:%02d", mins, secs))
    else
        if Meter.currentSegment and Meter.currentSegment.startTime then
            local duration = GetTime() - Meter.currentSegment.startTime
            local mins = math.floor(duration / 60)
            local secs = math.floor(duration % 60)
            self.timeText:SetText(string.format("%d:%02d", mins, secs))
        else
            self.timeText:SetText("0:00")
        end
    end
    
    local combatSources = session.combatSources
    local maxValue = session.maxAmount
    local containerWidth = self.barContainer:GetWidth() - 2
    
    -- Determine if we show DPS/HPS or total
    local showPerSecond = (self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS)
    
    for i, bar in ipairs(self.bars) do
        local source = combatSources[i]
        
        if source then
            bar:Show()
            
            -- Get player name using UnitName() - this resolves secret values!
            local playerName
            if source.isLocalPlayer then
                playerName = UnitName("player")
            else
                -- UnitName can resolve secret unit references
                local ok, resolved = pcall(function() return UnitName(source.name) end)
                if ok and resolved then
                    playerName = resolved
                else
                    playerName = "Player " .. i
                end
            end
            
            -- Class color
            local classFile = source.classFilename
            local classColors = {0.5, 0.5, 0.5}
            if classFile and not (issecretvalue and issecretvalue(classFile)) then
                classColors = KDT.CLASS_COLORS[classFile] or classColors
            end
            
            -- Get value - may be secret
            local value = showPerSecond and source.amountPerSecond or source.totalAmount
            local maxVal = maxValue
            
            -- Calculate bar width
            local barPercent = 1
            if maxVal and value then
                -- Both might be secret - try to use them directly
                local canRead = not (issecretvalue and (issecretvalue(value) or issecretvalue(maxVal)))
                if canRead and maxVal > 0 then
                    barPercent = value / maxVal
                else
                    -- Secret values - estimate from position (first is 100%, others proportionally less)
                    barPercent = 1 - (i - 1) * 0.1
                    barPercent = math.max(barPercent, 0.1)
                end
            end
            
            local barWidth = math.max(containerWidth * barPercent, 2)
            bar.statusBar:SetWidth(barWidth)
            bar.statusBar:SetVertexColor(classColors[1], classColors[2], classColors[3], 0.8)
            
            bar.rank:SetText(tostring(i))
            bar.name:SetText(playerName or "Unknown")
            
            -- Format value - AbbreviateNumbers CAN handle secret values!
            if value then
                local canReadValue = not (issecretvalue and issecretvalue(value))
                if canReadValue then
                    local valueText = Meter.FormatNumber(value)
                    if showPerSecond then valueText = valueText .. "/s" end
                    bar.value:SetText(valueText)
                else
                    -- Try using AbbreviateNumbers directly with secret value
                    local ok, formatted = pcall(function()
                        return AbbreviateNumbers(value)
                    end)
                    if ok and formatted then
                        local text = tostring(formatted)
                        if showPerSecond then text = text .. "/s" end
                        bar.value:SetText(text)
                    else
                        bar.value:SetText("---")
                    end
                end
            else
                bar.value:SetText("---")
            end
            
            -- Percent - skip if we can't calculate
            bar.percent:SetText("")
            
            -- Store data for tooltip
            bar.playerData = {
                name = playerName,
                class = classFile,
                value = value,
                source = source
            }
        else
            bar:Hide()
            bar.playerData = nil
        end
    end
end

function MeterWindowMixin:RefreshHistorical()
    -- Get current segment from Meter
    local segment = Meter:GetCurrentSegment()
    
    local data = Meter:GetSortedData(self.mode, segment)
    local total = Meter:GetTotal(self.mode, segment)
    
    -- Update time text
    if segment then
        local duration = segment.duration
        if duration == 0 and segment.startTime and segment.startTime > 0 and Meter.inCombat then
            duration = GetTime() - segment.startTime
        end
        if duration > 0 then
            local mins = math.floor(duration / 60)
            local secs = math.floor(duration % 60)
            self.timeText:SetText(string.format("%d:%02d", mins, secs))
        else
            self.timeText:SetText("0:00")
        end
    else
        self.timeText:SetText("--:--")
    end
    
    -- Update bars
    local maxValue = data[1] and data[1].value or 1
    maxValue = math.max(maxValue, 1)
    
    local containerWidth = self.barContainer:GetWidth() - 2
    
    for i, bar in ipairs(self.bars) do
        local entry = data[i]
        
        if entry and entry.value > 0 then
            bar:Show()
            bar.playerData = entry
            
            local classColors = KDT.CLASS_COLORS[entry.class] or {0.5, 0.5, 0.5}
            
            local barPercent = entry.value / maxValue
            local barWidth = math.max(containerWidth * barPercent, 2)
            bar.statusBar:SetWidth(barWidth)
            bar.statusBar:SetVertexColor(classColors[1], classColors[2], classColors[3], 0.8)
            
            bar.rank:SetText(tostring(i))
            bar.name:SetText(entry.name)
            
            local valueText = Meter.FormatNumber(entry.value)
            if self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS then
                valueText = valueText .. "/s"
            end
            bar.value:SetText(valueText)
            
            local pct = total > 0 and (entry.value / total * 100) or 0
            bar.percent:SetText(string.format("%.1f%%", pct))
        else
            bar:Hide()
            bar.playerData = nil
        end
    end
end

function MeterWindowMixin:GetOverallData()
    -- Merge all historical combats into one
    local overall = {
        startTime = 0,
        endTime = GetTime(),
        duration = 0,
        name = "Overall",
        players = {},
        totalDamage = 0,
        totalHealing = 0,
        totalInterrupts = 0,
        totalDeaths = 0,
    }
    
    -- Merge current combat if exists
    if Meter.currentCombat then
        self:MergeCombatData(overall, Meter.currentCombat)
    end
    
    -- Merge history
    for _, combat in ipairs(Meter.historyCombats) do
        self:MergeCombatData(overall, combat)
    end
    
    return overall
end

function MeterWindowMixin:MergeCombatData(target, source)
    target.duration = target.duration + (source.duration or 0)
    target.totalDamage = target.totalDamage + (source.totalDamage or 0)
    target.totalHealing = target.totalHealing + (source.totalHealing or 0)
    target.totalInterrupts = target.totalInterrupts + (source.totalInterrupts or 0)
    target.totalDeaths = target.totalDeaths + (source.totalDeaths or 0)
    
    for guid, player in pairs(source.players or {}) do
        if not target.players[guid] then
            target.players[guid] = {
                guid = player.guid,
                name = player.name,
                class = player.class,
                damage = 0,
                healing = 0,
                damageTaken = 0,
                interrupts = 0,
                deaths = 0,
                spells = {},
            }
        end
        local tp = target.players[guid]
        tp.damage = tp.damage + (player.damage or 0)
        tp.healing = tp.healing + (player.healing or 0)
        tp.damageTaken = tp.damageTaken + (player.damageTaken or 0)
        tp.interrupts = tp.interrupts + (player.interrupts or 0)
        tp.deaths = tp.deaths + (player.deaths or 0)
    end
end

function MeterWindowMixin:TogglePairedMode()
    -- Toggle between paired modes
    local newMode = self.mode
    if self.mode == Meter.MODES.DAMAGE then
        newMode = Meter.MODES.DPS
    elseif self.mode == Meter.MODES.DPS then
        newMode = Meter.MODES.DAMAGE
    elseif self.mode == Meter.MODES.HEALING then
        newMode = Meter.MODES.HPS
    elseif self.mode == Meter.MODES.HPS then
        newMode = Meter.MODES.HEALING
    end
    self:SetMode(newMode)
end

function MeterWindowMixin:SetMode(mode)
    self.mode = mode
    self:Refresh()
    -- Save mode change
    Meter:SaveOpenWindows()
end

function MeterWindowMixin:ShowModeDropdown(anchor)
    -- Create a simple custom dropdown menu
    if self.modeDropdown then
        self.modeDropdown:Hide()
        self.modeDropdown = nil
        return
    end
    
    local dropdown = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown:SetSize(120, 190)
    dropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    self.modeDropdown = dropdown
    
    local modes = {
        {mode = Meter.MODES.DAMAGE, name = "Damage"},
        {mode = Meter.MODES.DPS, name = "DPS"},
        {mode = Meter.MODES.DAMAGE_TAKEN, name = "Dmg Taken"},
        {mode = Meter.MODES.HEALING, name = "Healing"},
        {mode = Meter.MODES.HPS, name = "HPS"},
        {mode = Meter.MODES.INTERRUPTS, name = "Interrupts"},
        {mode = Meter.MODES.DEATHS, name = "Deaths"},
    }
    
    for i, modeData in ipairs(modes) do
        local btn = CreateFrame("Button", nil, dropdown)
        btn:SetSize(116, 22)
        btn:SetPoint("TOPLEFT", 2, -2 - (i-1) * 24)
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.4, 0.5)
        
        local check = btn:CreateFontString(nil, "OVERLAY")
        check:SetFont(self.settings.font, 10, "OUTLINE")
        check:SetPoint("LEFT", 4, 0)
        check:SetText(self.mode == modeData.mode and ">" or "")
        check:SetTextColor(0.2, 1, 0.2)
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(self.settings.font, 10, "OUTLINE")
        text:SetPoint("LEFT", 18, 0)
        text:SetText(modeData.name)
        text:SetTextColor(0.9, 0.9, 0.9)
        
        btn:SetScript("OnClick", function()
            self:SetMode(modeData.mode)
            dropdown:Hide()
            self.modeDropdown = nil
        end)
    end
    
    -- Close when clicking elsewhere
    dropdown:SetScript("OnUpdate", function(frame)
        if not frame:IsMouseOver() and not anchor:IsMouseOver() then
            C_Timer.After(0.5, function()
                if frame and not frame:IsMouseOver() then
                    frame:Hide()
                    self.modeDropdown = nil
                end
            end)
        end
    end)
end

function MeterWindowMixin:ShowSegmentDropdown(anchor)
    -- Hide if already shown
    if self.segmentDropdown and self.segmentDropdown:IsShown() then
        return
    end
    
    -- Close existing dropdown
    if self.segmentDropdown then
        self.segmentDropdown:Hide()
    end
    
    local segments = Meter:GetSegmentList()
    local numItems = #segments
    local itemHeight = 20
    local dropdownHeight = math.min(numItems * itemHeight + 4, 300)
    
    local dropdown = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown:SetSize(160, dropdownHeight)
    dropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.1, 0.98)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown:SetFrameLevel(200)
    self.segmentDropdown = dropdown
    
    -- Scrollable content
    local scrollFrame = CreateFrame("ScrollFrame", nil, dropdown, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 2)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(136, numItems * itemHeight)
    scrollFrame:SetScrollChild(content)
    
    -- Create segment buttons
    for i, segData in ipairs(segments) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(134, itemHeight)
        btn:SetPoint("TOPLEFT", 0, -(i-1) * itemHeight)
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.4, 0.5)
        
        -- Selection indicator
        local selected = Meter.viewingSegmentIndex == segData.index
        local check = btn:CreateFontString(nil, "OVERLAY")
        check:SetFont(self.settings.font, 10, "OUTLINE")
        check:SetPoint("LEFT", 2, 0)
        check:SetText(selected and ">" or "")
        check:SetTextColor(0.2, 1, 0.2)
        
        -- Class color dot for segments with data
        local dot = btn:CreateTexture(nil, "OVERLAY")
        dot:SetSize(8, 8)
        dot:SetPoint("LEFT", 12, 0)
        
        if segData.segment and segData.segment.totalDamage then
            if segData.segment.totalDamage > 0 then
                dot:SetColorTexture(0.2, 0.8, 0.2, 1) -- Green = has damage
            else
                dot:SetColorTexture(0.5, 0.5, 0.5, 1) -- Gray = no data
            end
        else
            dot:SetColorTexture(0.5, 0.5, 0.5, 1)
        end
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(self.settings.font, 10, "OUTLINE")
        text:SetPoint("LEFT", 24, 0)
        text:SetPoint("RIGHT", -2, 0)
        text:SetJustifyH("LEFT")
        text:SetText(segData.name)
        
        -- Color based on type
        if segData.index == 0 then
            text:SetTextColor(1, 0.82, 0) -- Gold for current
        elseif segData.index == -1 then
            text:SetTextColor(0.4, 0.8, 1) -- Blue for overall
        else
            text:SetTextColor(0.9, 0.9, 0.9) -- White for saved
        end
        
        btn:SetScript("OnClick", function()
            Meter:SetViewingSegment(segData.index)
            dropdown:Hide()
            self.segmentDropdown = nil
        end)
    end
    
    -- Auto-close logic
    local closeTimer = nil
    dropdown:SetScript("OnEnter", function()
        if closeTimer then closeTimer:Cancel() closeTimer = nil end
    end)
    dropdown:SetScript("OnLeave", function()
        closeTimer = C_Timer.NewTimer(0.3, function()
            if dropdown and not dropdown:IsMouseOver() and not anchor:IsMouseOver() then
                dropdown:Hide()
                self.segmentDropdown = nil
            end
            closeTimer = nil
        end)
    end)
    anchor:HookScript("OnLeave", function()
        closeTimer = C_Timer.NewTimer(0.3, function()
            if dropdown and dropdown:IsShown() and not dropdown:IsMouseOver() and not anchor:IsMouseOver() then
                dropdown:Hide()
                self.segmentDropdown = nil
            end
            closeTimer = nil
        end)
    end)
end

-- ==================== SMART DOCKING SYSTEM ====================
function MeterWindowMixin:ToggleDock()
    if self.dockedTo then
        self:Undock()
    else
        -- Find closest window to dock to
        local targetId = self:FindClosestWindow()
        if targetId then
            local targetWindow = Meter:GetWindow(targetId)
            if targetWindow and targetWindow.frame then
                self:SmartDockTo(targetId)
            end
        else
            KDT:Print("No other windows to dock to")
        end
    end
end

function MeterWindowMixin:FindClosestWindow()
    local myLeft = self.frame:GetLeft()
    local myTop = self.frame:GetTop()
    local myRight = self.frame:GetRight()
    local myBottom = self.frame:GetBottom()
    
    local closest = nil
    local closestDist = 999999
    
    for id, window in pairs(Meter.windows) do
        if id ~= self.id and window.frame and window.frame:IsShown() then
            local left = window.frame:GetLeft()
            local top = window.frame:GetTop()
            local right = window.frame:GetRight()
            local bottom = window.frame:GetBottom()
            
            -- Calculate distance between edges
            local dist = math.min(
                math.abs(myLeft - right),   -- my left to their right
                math.abs(myRight - left),   -- my right to their left
                math.abs(myTop - bottom),   -- my top to their bottom
                math.abs(myBottom - top)    -- my bottom to their top
            )
            
            if dist < closestDist then
                closestDist = dist
                closest = id
            end
        end
    end
    
    return closest
end

function MeterWindowMixin:SmartDockTo(targetId)
    local targetWindow = Meter:GetWindow(targetId)
    if not targetWindow or not targetWindow.frame then return end
    
    -- Store dock relationship
    self.dockedTo = targetId
    self.dockSide = nil
    targetWindow.dockedChildren = targetWindow.dockedChildren or {}
    targetWindow.dockedChildren[self.id] = true
    
    -- Determine best dock position based on current positions
    local myLeft = self.frame:GetLeft()
    local myTop = self.frame:GetTop()
    local myRight = self.frame:GetRight()
    local myBottom = self.frame:GetBottom()
    
    local tLeft = targetWindow.frame:GetLeft()
    local tTop = targetWindow.frame:GetTop()
    local tRight = targetWindow.frame:GetRight()
    local tBottom = targetWindow.frame:GetBottom()
    
    -- Calculate distances for each side
    local distBelow = math.abs(myTop - tBottom)
    local distAbove = math.abs(myBottom - tTop)
    local distRight = math.abs(myLeft - tRight)
    local distLeft = math.abs(myRight - tLeft)
    
    local minDist = math.min(distBelow, distAbove, distRight, distLeft)
    
    self.frame:ClearAllPoints()
    
    if minDist == distBelow then
        -- Dock below
        self.frame:SetPoint("TOPLEFT", targetWindow.frame, "BOTTOMLEFT", 0, -2)
        self.frame:SetWidth(targetWindow.frame:GetWidth())
        self.dockSide = "BOTTOM"
    elseif minDist == distAbove then
        -- Dock above  
        self.frame:SetPoint("BOTTOMLEFT", targetWindow.frame, "TOPLEFT", 0, 2)
        self.frame:SetWidth(targetWindow.frame:GetWidth())
        self.dockSide = "TOP"
    elseif minDist == distRight then
        -- Dock to the right
        self.frame:SetPoint("TOPLEFT", targetWindow.frame, "TOPRIGHT", 2, 0)
        self.frame:SetHeight(targetWindow.frame:GetHeight())
        self.dockSide = "RIGHT"
    else
        -- Dock to the left
        self.frame:SetPoint("TOPRIGHT", targetWindow.frame, "TOPLEFT", -2, 0)
        self.frame:SetHeight(targetWindow.frame:GetHeight())
        self.dockSide = "LEFT"
    end
    
    -- Update dock button text
    if self.dockBtn then
        self.dockBtn.text:SetText("Undk")
    end
    
    local sideNames = {BOTTOM = "below", TOP = "above", RIGHT = "right of", LEFT = "left of"}
    KDT:Print("Window #" .. self.id .. " docked " .. (sideNames[self.dockSide] or "to") .. " Window #" .. targetId)
end

function MeterWindowMixin:DockTo(targetId)
    -- Legacy function - now uses SmartDockTo
    self:SmartDockTo(targetId)
end

function MeterWindowMixin:Undock()
    if not self.dockedTo then return end
    
    local targetWindow = Meter:GetWindow(self.dockedTo)
    if targetWindow and targetWindow.dockedChildren then
        targetWindow.dockedChildren[self.id] = nil
    end
    
    -- Clear dock relationship
    local oldDock = self.dockedTo
    self.dockedTo = nil
    
    -- Reposition independently
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 50 * self.id, 0)
    
    -- Update dock button text
    if self.dockBtn then
        self.dockBtn.text:SetText("Dock")
    end
    
    KDT:Print("Window #" .. self.id .. " undocked from Window #" .. oldDock)
end

function MeterWindowMixin:StartMovingDockedChildren()
    if not self.dockedChildren then return end
    for childId, _ in pairs(self.dockedChildren) do
        local childWindow = Meter:GetWindow(childId)
        if childWindow and childWindow.frame then
            -- Children follow parent automatically via anchoring
        end
    end
end

function MeterWindowMixin:StopMovingDockedChildren()
    -- Position is maintained via anchoring, no action needed
end

function MeterWindowMixin:Show()
    self.frame:Show()
    self:Refresh()
    self:SavePosition()
    -- Save all open windows
    Meter:SaveOpenWindows()
end

function MeterWindowMixin:Hide()
    self.frame:Hide()
    -- Save all open windows
    Meter:SaveOpenWindows()
end

function MeterWindowMixin:Toggle()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function MeterWindowMixin:UpdateBars()
    local settings = self.settings
    local barHeight = settings.barHeight
    local spacing = settings.barSpacing
    
    for i, bar in ipairs(self.bars) do
        bar:SetHeight(barHeight)
        bar:SetPoint("TOPLEFT", 0, -(i - 1) * (barHeight + spacing))
    end
    
    self:Refresh()
end

function MeterWindowMixin:ShowBarTooltip(bar)
    if not bar.playerData then return end
    
    local data = bar.playerData
    GameTooltip:SetOwner(bar, "ANCHOR_RIGHT")
    GameTooltip:AddLine(data.name, 1, 0.82, 0)
    GameTooltip:AddLine(Meter.MODE_NAMES[self.mode] .. ": " .. Meter.FormatNumber(data.value), 1, 1, 1)
    
    local segment = Meter:GetCurrentSegment()
    if segment and segment.players[data.name] then
        local player = segment.players[data.name]
        
        GameTooltip:AddLine(" ")
        if player.damage > 0 then
            GameTooltip:AddDoubleLine("Damage:", Meter.FormatNumber(player.damage), 1, 1, 1, 0.7, 0.7, 0.7)
        end
        if player.healing > 0 then
            GameTooltip:AddDoubleLine("Healing:", Meter.FormatNumber(player.healing), 1, 1, 1, 0.7, 0.7, 0.7)
        end
        if player.damageTaken > 0 then
            GameTooltip:AddDoubleLine("Damage Taken:", Meter.FormatNumber(player.damageTaken), 1, 1, 1, 0.7, 0.7, 0.7)
        end
        if player.interrupts > 0 then
            GameTooltip:AddDoubleLine("Interrupts:", tostring(player.interrupts), 1, 1, 1, 0.7, 0.7, 0.7)
        end
        if player.deaths > 0 then
            GameTooltip:AddDoubleLine("Deaths:", tostring(player.deaths), 1, 1, 1, 0.7, 0.7, 0.7)
        end
    end
    
    GameTooltip:Show()
end

function MeterWindowMixin:ReportToChat()
    local segment = Meter:GetCurrentSegment()
    local data = Meter:GetSortedData(self.mode, segment)
    
    if #data == 0 then
        KDT:Print("No data to report.")
        return
    end
    
    local chatType = "SAY"
    if IsInRaid() then
        chatType = "RAID"
    elseif IsInGroup() then
        chatType = "PARTY"
    end
    
    -- Header
    local header = "Kryos DMG Meter - " .. Meter.MODE_NAMES[self.mode]
    SendChatMessage(header, chatType)
    
    -- Top 5 entries
    for i = 1, math.min(5, #data) do
        local entry = data[i]
        local valueText = Meter.FormatNumber(entry.value)
        if self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS then
            valueText = valueText .. "/s"
        end
        local line = string.format("%d. %s - %s", i, entry.name, valueText)
        SendChatMessage(line, chatType)
    end
end

function MeterWindowMixin:ShowContextMenu()
    -- Create custom context menu (EasyMenu doesn't exist in WoW 12.0)
    if self.contextMenu then
        self.contextMenu:Hide()
        self.contextMenu = nil
        return
    end
    
    local menu = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    menu:SetSize(160, 220)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    menu:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    menu:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    menu:SetFrameStrata("DIALOG")
    menu:SetPoint("CENTER", UIParent, "CENTER")
    self.contextMenu = menu
    
    -- Make it draggable
    menu:EnableMouse(true)
    menu:SetMovable(true)
    menu:RegisterForDrag("LeftButton")
    menu:SetScript("OnDragStart", menu.StartMoving)
    menu:SetScript("OnDragStop", menu.StopMovingOrSizing)
    
    local yOffset = -5
    local function AddButton(text, onClick, isChecked)
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(156, 20)
        btn:SetPoint("TOPLEFT", 2, yOffset)
        yOffset = yOffset - 22
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.4, 0.5)
        
        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(self.settings.font, 10, "OUTLINE")
        label:SetPoint("LEFT", 8, 0)
        label:SetText(text)
        label:SetTextColor(0.9, 0.9, 0.9)
        
        if isChecked then
            local check = btn:CreateFontString(nil, "OVERLAY")
            check:SetFont(self.settings.font, 10, "OUTLINE")
            check:SetPoint("RIGHT", -8, 0)
            check:SetText("*")
            check:SetTextColor(0.2, 1, 0.2)
        end
        
        btn:SetScript("OnClick", function()
            onClick()
            menu:Hide()
            self.contextMenu = nil
        end)
    end
    
    local function AddTitle(text)
        local label = menu:CreateFontString(nil, "OVERLAY")
        label:SetFont(self.settings.font, 9, "OUTLINE")
        label:SetPoint("TOPLEFT", 8, yOffset)
        label:SetText(text)
        label:SetTextColor(0.6, 0.6, 0.2)
        yOffset = yOffset - 18
    end
    
    AddTitle("Kryos DMG Meter")
    AddButton("Damage", function() self:SetMode(Meter.MODES.DAMAGE) end, self.mode == Meter.MODES.DAMAGE)
    AddButton("DPS", function() self:SetMode(Meter.MODES.DPS) end, self.mode == Meter.MODES.DPS)
    AddButton("Healing", function() self:SetMode(Meter.MODES.HEALING) end, self.mode == Meter.MODES.HEALING)
    AddButton("HPS", function() self:SetMode(Meter.MODES.HPS) end, self.mode == Meter.MODES.HPS)
    AddButton("Interrupts", function() self:SetMode(Meter.MODES.INTERRUPTS) end, self.mode == Meter.MODES.INTERRUPTS)
    yOffset = yOffset - 5
    AddButton("Report to Chat", function() self:ReportToChat() end)
    AddButton("Reset Segment", function() Meter.currentCombat = nil; Meter.inCombat = false; self:Refresh() end)
    AddButton("Close", function() self:Hide() end)
    
    -- Adjust height
    menu:SetHeight(-yOffset + 10)
    
    -- Auto-close
    C_Timer.After(10, function()
        if menu and menu:IsShown() then
            menu:Hide()
            self.contextMenu = nil
        end
    end)
end

-- ==================== WINDOW FACTORY ====================
function Meter:CreateWindow(id)
    id = id or (#self.windows + 1)
    
    local window = Mixin({}, MeterWindowMixin)
    window:Initialize(id)
    
    return window
end

function Meter:GetWindow(id)
    return self.windows[id]
end

function Meter:ToggleWindow(id)
    id = id or 1
    local window = self.windows[id]
    
    if not window then
        window = self:CreateWindow(id)
    end
    
    window:Toggle()
    
    -- Save visibility state
    if KDT.DB then
        KDT.DB.meter = KDT.DB.meter or {}
        KDT.DB.meter.windowVisible = window.frame and window.frame:IsShown()
    end
end

function Meter:ShowAllWindows()
    for _, window in pairs(self.windows) do
        window.frame:Show()
        window:Refresh()
    end
    -- Save state once at the end
    self:SaveOpenWindows()
end

-- ==================== LOCK FUNCTIONS ====================
function MeterWindowMixin:ToggleLock()
    self.isLocked = not self.isLocked
    
    -- Update button appearance
    if self.lockBtn then
        if self.isLocked then
            self.lockBtn.text:SetText("Unlk")
            self.lockBtn:SetBackdropColor(0.4, 0.2, 0.2, 1)
            self.lockBtn.text:SetTextColor(1, 0.5, 0.5)
        else
            self.lockBtn.text:SetText("Lock")
            self.lockBtn:SetBackdropColor(0.2, 0.2, 0.25, 1)
            self.lockBtn.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end
    
    -- Show/hide resize handle
    if self.resizeHandle then
        if self.isLocked then
            self.resizeHandle:Hide()
        else
            self.resizeHandle:Show()
        end
    end
    
    -- Save lock state (global for all meter windows)
    if KDT.DB then
        KDT.DB.meter = KDT.DB.meter or {}
        KDT.DB.meter.locked = self.isLocked
    end
    
    -- Sync lock state to all windows
    for _, window in pairs(Meter.windows) do
        if window ~= self then
            window.isLocked = self.isLocked
            if window.lockBtn then
                if self.isLocked then
                    window.lockBtn.text:SetText("Unlk")
                    window.lockBtn:SetBackdropColor(0.4, 0.2, 0.2, 1)
                    window.lockBtn.text:SetTextColor(1, 0.5, 0.5)
                else
                    window.lockBtn.text:SetText("Lock")
                    window.lockBtn:SetBackdropColor(0.2, 0.2, 0.25, 1)
                    window.lockBtn.text:SetTextColor(0.8, 0.8, 0.8)
                end
            end
            if window.resizeHandle then
                if self.isLocked then
                    window.resizeHandle:Hide()
                else
                    window.resizeHandle:Show()
                end
            end
        end
    end
    
    local status = self.isLocked and "locked" or "unlocked"
    KDT:Print("DMG Meter windows " .. status)
end

function MeterWindowMixin:ClampToScreen(frame)
    if not frame then return end
    
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local scale = frame:GetEffectiveScale()
    
    local left = frame:GetLeft()
    local right = frame:GetRight()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()
    
    if not left or not right or not top or not bottom then return end
    
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    
    local newX, newY
    local needsMove = false
    
    -- Check left edge
    if left < 0 then
        newX = width / 2
        needsMove = true
    -- Check right edge
    elseif right > screenWidth then
        newX = screenWidth - width / 2
        needsMove = true
    end
    
    -- Check top edge
    if top > screenHeight then
        newY = screenHeight - height / 2
        needsMove = true
    -- Check bottom edge
    elseif bottom < 0 then
        newY = height / 2
        needsMove = true
    end
    
    if needsMove then
        local currentX = (left + right) / 2
        local currentY = (top + bottom) / 2
        
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX or currentX, newY or currentY)
    end
end

function MeterWindowMixin:SavePosition()
    if not self.frame then return end
    
    if KDT.DB then
        KDT.DB.meter = KDT.DB.meter or {}
        KDT.DB.meter.windows = KDT.DB.meter.windows or {}
        
        local point, relativeTo, relativePoint, xOfs, yOfs = self.frame:GetPoint()
        local relativeToName = relativeTo and relativeTo:GetName() or "UIParent"
        local width = self.frame:GetWidth()
        local height = self.frame:GetHeight()
        
        KDT.DB.meter.windows[self.frame:GetName()] = {
            point = point,
            relativeTo = relativeToName,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs,
            width = width,
            height = height
        }
    end
end

function Meter:HideAllWindows()
    for _, window in pairs(self.windows) do
        window.frame:Hide()
    end
    -- Save state once at the end
    self:SaveOpenWindows()
end
