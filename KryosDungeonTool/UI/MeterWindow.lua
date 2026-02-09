-- Kryos Dungeon Tool
-- UI/MeterWindow.lua - Floating Damage/Heal Meter Window (Details-inspired)

local addonName, KDT = ...
local Meter = KDT.Meter

-- Helper: safely read values that may be secret during combat (WoW 12.0)
local function SafeRead(value)
    if value == nil then return nil end
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

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
            { mode = Meter.MODES.ABSORBS, name = "Absorbs" },
        }
    },
    {
        name = "Miscellaneous",
        icon = "Interface\\Icons\\inv_misc_questionmark",
        modes = {
            { mode = Meter.MODES.INTERRUPTS, name = "Interrupts" },
            { mode = Meter.MODES.DISPELS, name = "Dispels" },
            { mode = Meter.MODES.DEATHS, name = "Deaths" },
        }
    },
}

-- ==================== METER WINDOW CLASS ====================
local MeterWindowMixin = {}

function MeterWindowMixin:Initialize(id)
    self.id = id
    self.mode = Meter.MODES.DAMAGE
    self.viewingOverall = false
    self.viewingSegmentIndex = 0  -- Per-window: 0=current, -1=overall, >0=saved segment index
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
        if savedPos.left and savedPos.top then
            -- New format: absolute UIParent coordinates
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedPos.left, savedPos.top)
        elseif savedPos.point then
            local relativeFrame = savedPos.relativeTo
            if type(relativeFrame) == "string" then
                relativeFrame = _G[relativeFrame] or UIParent
            end
            frame:SetPoint(savedPos.point, relativeFrame or UIParent, savedPos.relativePoint or "CENTER", savedPos.x or 0, savedPos.y or 0)
        elseif savedPos[1] then
            local relativeFrame = savedPos[2]
            if type(relativeFrame) == "string" then
                relativeFrame = _G[relativeFrame] or UIParent
            end
            frame:SetPoint(savedPos[1], relativeFrame or UIParent, savedPos[3] or "CENTER", savedPos[4] or 0, savedPos[5] or 0)
        end
        if savedPos.width and savedPos.height and savedPos.width > 10 and savedPos.height > 10 then
            frame:SetSize(savedPos.width, savedPos.height)
        end
        if savedPos.mode then
            self.mode = savedPos.mode
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
        
        -- If docked, move the root of the dock chain
        if self.dockedTo then
            local root = self:GetDockRoot()
            if root and root.frame and not root.isLocked then
                root.frame:StartMoving()
                return
            end
        end
        f:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(f) 
        if self.isLocked then return end
        
        if self.dockedTo then
            local root = self:GetDockRoot()
            if root and root.frame then
                root.frame:StopMovingOrSizing()
                self:ClampToScreen(root.frame)
                root:SavePosition()
                return
            end
        end
        f:StopMovingOrSizing()
        self:ClampToScreen(f)
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
    
    -- Clear Dropdown Button (like Mode button)
    local clearBtn = self:CreateHoverButton(hoverButtons, "Clear", 38)
    clearBtn:SetPoint("LEFT", 2, 0)
    clearBtn:SetScript("OnClick", function()
        self:ShowClearDropdown(clearBtn)
    end)
    clearBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.3, 0.3, 0.35, 1)
        btn.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Clear meter data")
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Report Button
    local reportBtn = self:CreateHoverButton(hoverButtons, "Post", 32)
    reportBtn:SetPoint("LEFT", clearBtn, "RIGHT", 2, 0)
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
    
    -- ==================== BAR CONTAINER (Scrollable) ====================
    local barScrollFrame = CreateFrame("ScrollFrame", nil, frame)
    barScrollFrame:SetPoint("TOPLEFT", 4, -22)
    barScrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
    barScrollFrame:SetClipsChildren(true)
    self.barScrollFrame = barScrollFrame
    
    local barContainer = CreateFrame("Frame", nil, barScrollFrame)
    barContainer:SetPoint("TOPLEFT", 0, 0)
    barContainer:SetWidth(barScrollFrame:GetWidth())
    barContainer:SetHeight(1) -- Will be updated dynamically
    barScrollFrame:SetScrollChild(barContainer)
    self.barContainer = barContainer
    self.barScrollOffset = 0
    
    -- Mouse wheel scrolling (invisible scrollbar)
    barScrollFrame:EnableMouseWheel(true)
    barScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = math.max(0, barContainer:GetHeight() - barScrollFrame:GetHeight())
        self.barScrollOffset = math.max(0, math.min(maxScroll, self.barScrollOffset - delta * (self.settings.barHeight + self.settings.barSpacing)))
        barContainer:SetPoint("TOPLEFT", 0, self.barScrollOffset)
    end)
    
    -- Update scroll child width on resize
    barScrollFrame:SetScript("OnSizeChanged", function(sf, w, h)
        barContainer:SetWidth(w)
    end)
    
    -- Propagate drags from scrollFrame to main frame for window movement
    barScrollFrame:RegisterForDrag("LeftButton")
    barScrollFrame:SetScript("OnDragStart", function()
        local handler = frame:GetScript("OnDragStart")
        if handler then handler(frame) end
    end)
    barScrollFrame:SetScript("OnDragStop", function()
        local handler = frame:GetScript("OnDragStop")
        if handler then handler(frame) end
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

function MeterWindowMixin:UpdateScrollHeight()
    local settings = self.settings
    local visibleCount = 0
    for _, bar in ipairs(self.bars) do
        if bar:IsShown() then visibleCount = visibleCount + 1 end
    end
    local contentHeight = visibleCount * (settings.barHeight + settings.barSpacing)
    self.barContainer:SetHeight(math.max(contentHeight, 1))
    -- Clamp scroll offset
    if self.barScrollFrame then
        local maxScroll = math.max(0, contentHeight - self.barScrollFrame:GetHeight())
        if self.barScrollOffset > maxScroll then
            self.barScrollOffset = maxScroll
            self.barContainer:SetPoint("TOPLEFT", 0, self.barScrollOffset)
        end
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
    
    -- Tooltip + Click for spell breakdown
    bar:EnableMouse(true)
    
    -- Propagate drag to parent frame for window movement
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        local win = self.window
        if win and win.frame then
            -- Trigger the frame's own drag handler
            local handler = win.frame:GetScript("OnDragStart")
            if handler then handler(win.frame) end
        end
    end)
    bar:SetScript("OnDragStop", function(self)
        local win = self.window
        if win and win.frame then
            local handler = win.frame:GetScript("OnDragStop")
            if handler then handler(win.frame) end
        end
    end)
    
    bar:SetScript("OnEnter", function(self)
        if self.playerData and self.window then
            self.window:ShowBarTooltip(self)
        end
    end)
    bar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    -- Use OnMouseUp (Frame API) for spell breakdown on left click
    bar:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.playerData and self.window then
            self.window:ShowSpellBreakdownWindow(self)
        end
    end)
    
    return bar
end

function MeterWindowMixin:Refresh()
    if not self.frame:IsShown() then return end
    
    local segmentName = Meter:GetSegmentName(self.viewingSegmentIndex)
    
    -- Update mode label
    self.modeLabel.text:SetText(Meter.MODE_NAMES[self.mode] or "DMG Meter")
    self.modeLabel:SetWidth(self.modeLabel.text:GetStringWidth() + 10)
    
    -- Update segment text
    self.segmentText:SetText("[" .. segmentName .. "]")
    
    -- Check if we should use LIVE data from Blizzard API
    local useLiveData = Meter.isMidnight and C_DamageMeter and self.viewingSegmentIndex == 0 and Meter.inCombat
    
    if useLiveData then
        -- LIVE MODE: Bind secret values directly to UI widgets
        self:RefreshLive()
    else
        -- HISTORICAL MODE: Use stored segment data
        self:RefreshHistorical()
    end
end

-- Smooth bar animation: time-based lerp for fluid movement like Details
local BAR_LERP_SPEED = 12  -- Units per second, higher = faster

local function LerpBarWidth(bar, targetWidth)
    local now = GetTime()
    if not bar.currentWidth or not bar:IsShown() or not bar.lastLerpTime then
        bar.currentWidth = targetWidth
        bar.lastLerpTime = now
    else
        local dt = now - bar.lastLerpTime
        bar.lastLerpTime = now
        local diff = targetWidth - bar.currentWidth
        if math.abs(diff) < 0.5 then
            bar.currentWidth = targetWidth
        else
            -- Exponential decay: smooth approach to target
            local factor = 1 - math.exp(-BAR_LERP_SPEED * dt)
            bar.currentWidth = bar.currentWidth + diff * factor
        end
    end
    bar.statusBar:SetWidth(math.max(bar.currentWidth, 2))
end

-- Helper to get sortable value from a source
local function GetSortableValue(source, showPerSecond)
    local val = showPerSecond and source.amountPerSecond or source.totalAmount
    if val == nil then return 0 end
    if issecretvalue and issecretvalue(val) then return 0 end
    return val
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
    
    -- Update time from session or fallback
    if session.durationSeconds then
        local duration = session.durationSeconds
        local durationValue = duration
        if issecretvalue and issecretvalue(duration) then
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
    local containerWidth = self.barContainer:GetWidth() - 2
    if containerWidth <= 0 then containerWidth = self.frame:GetWidth() - 10 end
    if containerWidth <= 0 then containerWidth = self.settings.windowWidth - 10 end
    local showPerSecond = (self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS)
    
    -- Filter out pets FIRST (nil classFilename)
    local playerSources = {}
    for _, source in ipairs(combatSources) do
        local classFile = source.classFilename
        if classFile then
            local isSecret = issecretvalue and issecretvalue(classFile)
            if isSecret or (type(classFile) == "string" and classFile ~= "") then
                table.insert(playerSources, source)
            end
        end
    end
    
    -- ALWAYS sort by display value (fixes DPS ranking + equal interrupt bars)
    table.sort(playerSources, function(a, b)
        return GetSortableValue(a, showPerSecond) > GetSortableValue(b, showPerSecond)
    end)
    
    -- "Always Show Self at Top" option
    if Meter.defaults.showSelfTop then
        for idx, source in ipairs(playerSources) do
            if source.isLocalPlayer and idx > 1 then
                table.remove(playerSources, idx)
                table.insert(playerSources, 1, source)
                break
            end
        end
    end
    
    -- Calculate maxValue from FILTERED + SORTED playerSources (not raw combatSources)
    local maxValue = 0
    local allSecret = true
    for _, source in ipairs(playerSources) do
        local val = GetSortableValue(source, showPerSecond)
        if val > 0 then allSecret = false end
        if val > maxValue then maxValue = val end
    end
    maxValue = math.max(maxValue, 1)
    local numPlayers = #playerSources
    
    -- Store session reference for live spell breakdown
    self.liveSession = session
    self.liveSessionType = blizzType
    
    for i, bar in ipairs(self.bars) do
        local source = playerSources[i]
        
        if source then
            bar:Show()
            
            -- Get player name
            local playerName
            if source.isLocalPlayer then
                playerName = UnitName("player")
            else
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
            
            -- Get value based on display mode
            local value
            if showPerSecond then
                value = source.amountPerSecond
            else
                value = source.totalAmount
            end
            
            -- Calculate bar width with smooth animation
            local barPercent
            if allSecret then
                -- During combat, values are secret (WoW 12.0)
                -- Blizzard already sorts combatSources by performance
                -- Use rank-based proportional widths: #1=100%, #2=85%, #3=70%, etc.
                barPercent = math.max(1.0 - (i - 1) * (0.8 / math.max(numPlayers - 1, 1)), 0.15)
            else
                local sortableVal = GetSortableValue(source, showPerSecond)
                barPercent = maxValue > 0 and (sortableVal / maxValue) or 1.0
            end
            
            local barWidth = math.max(containerWidth * barPercent, 2)
            LerpBarWidth(bar, barWidth)
            bar.statusBar:SetVertexColor(classColors[1], classColors[2], classColors[3], 0.8)
            
            bar.rank:SetText(Meter.defaults.showRank and tostring(i) or "")
            bar.name:SetText(playerName or "Unknown")
            
            -- Format value
            if value then
                local canReadValue = not (issecretvalue and issecretvalue(value))
                if canReadValue then
                    local valueText = Meter.FormatNumber(value)
                    if showPerSecond then valueText = valueText .. "/s" end
                    bar.value:SetText(valueText)
                else
                    local ok, formatted = pcall(function() return AbbreviateNumbers(value) end)
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
            
            bar.percent:SetText("")
            
            bar.playerData = {
                name = playerName,
                class = classFile,
                value = value,
                source = source,
                isLive = true
            }
        else
            bar:Hide()
            bar.playerData = nil
            bar.currentWidth = nil
            bar.lastLerpTime = nil
        end
    end
    self:UpdateScrollHeight()
end

function MeterWindowMixin:RefreshHistorical()
    -- Get segment based on this window's viewing index
    local segment = Meter:GetCurrentSegment(self.viewingSegmentIndex)
    
    local data = Meter:GetSortedData(self.mode, segment)
    local total = Meter:GetTotal(self.mode, segment)
    
    -- "Always Show Self at Top" option
    if Meter.defaults.showSelfTop and #data > 1 then
        local myName = UnitName("player")
        for idx, entry in ipairs(data) do
            if entry.name == myName and idx > 1 then
                table.remove(data, idx)
                table.insert(data, 1, entry)
                break
            end
        end
    end
    
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
    if containerWidth <= 0 then containerWidth = self.frame:GetWidth() - 10 end
    if containerWidth <= 0 then containerWidth = self.settings.windowWidth - 10 end
    
    for i, bar in ipairs(self.bars) do
        local entry = data[i]
        
        if entry and entry.value > 0 then
            bar:Show()
            bar.playerData = entry
            
            local classColors = KDT.CLASS_COLORS[entry.class] or {0.5, 0.5, 0.5}
            
            local barPercent = entry.value / maxValue
            local barWidth = math.max(containerWidth * barPercent, 2)
            LerpBarWidth(bar, barWidth)
            bar.statusBar:SetVertexColor(classColors[1], classColors[2], classColors[3], 0.8)
            
            bar.rank:SetText(Meter.defaults.showRank and tostring(i) or "")
            bar.name:SetText(entry.name)
            
            local valueText = Meter.FormatNumber(entry.value)
            if self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS then
                valueText = valueText .. "/s"
            end
            bar.value:SetText(valueText)
            
            if Meter.defaults.showPercent then
                local pct = total > 0 and (entry.value / total * 100) or 0
                bar.percent:SetText(string.format("%.1f%%", pct))
            else
                bar.percent:SetText("")
            end
        else
            bar:Hide()
            bar.playerData = nil
            bar.currentWidth = nil  -- Reset animation state
            bar.lastLerpTime = nil
        end
    end
    self:UpdateScrollHeight()
end

function MeterWindowMixin:TogglePairedMode()
    -- Toggle between paired modes (including new WoW 12.0 types)
    local newMode = self.mode
    if self.mode == Meter.MODES.DAMAGE then
        newMode = Meter.MODES.DPS
    elseif self.mode == Meter.MODES.DPS then
        newMode = Meter.MODES.DAMAGE
    elseif self.mode == Meter.MODES.HEALING then
        newMode = Meter.MODES.HPS
    elseif self.mode == Meter.MODES.HPS then
        newMode = Meter.MODES.ABSORBS
    elseif self.mode == Meter.MODES.ABSORBS then
        newMode = Meter.MODES.HEALING
    elseif self.mode == Meter.MODES.INTERRUPTS then
        newMode = Meter.MODES.DISPELS
    elseif self.mode == Meter.MODES.DISPELS then
        newMode = Meter.MODES.INTERRUPTS
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
    
    local modes = {
        {mode = Meter.MODES.DAMAGE, name = "Damage"},
        {mode = Meter.MODES.DPS, name = "DPS"},
        {mode = Meter.MODES.DAMAGE_TAKEN, name = "Dmg Taken"},
        {mode = Meter.MODES.HEALING, name = "Healing"},
        {mode = Meter.MODES.HPS, name = "HPS"},
        {mode = Meter.MODES.ABSORBS, name = "Absorbs"},
        {mode = Meter.MODES.INTERRUPTS, name = "Interrupts"},
        {mode = Meter.MODES.DISPELS, name = "Dispels"},
        {mode = Meter.MODES.DEATHS, name = "Deaths"},
    }
    
    local itemHeight = 24
    local fullHeight = #modes * itemHeight + 4
    
    -- Screen boundary check - limit dropdown height if it goes off-screen
    local anchorBottom = anchor:GetBottom() or 0
    local screenScale = UIParent:GetEffectiveScale()
    local availableSpace = anchorBottom - 10  -- 10px margin from bottom
    local dropdownHeight = math.min(fullHeight, math.max(availableSpace, 120))
    local needsScroll = dropdownHeight < fullHeight
    
    local dropdown = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown:SetSize(120, dropdownHeight)
    dropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown:SetClipsChildren(true)
    self.modeDropdown = dropdown
    
    -- Content frame (scrollable child)
    local content = CreateFrame("Frame", nil, dropdown)
    content:SetSize(116, fullHeight)
    content:SetPoint("TOPLEFT", 2, 0)
    
    local scrollOffset = 0
    
    if needsScroll then
        dropdown:EnableMouseWheel(true)
        dropdown:SetScript("OnMouseWheel", function(_, delta)
            local maxScroll = fullHeight - dropdownHeight
            scrollOffset = math.max(0, math.min(maxScroll, scrollOffset - delta * itemHeight))
            content:SetPoint("TOPLEFT", 2, scrollOffset)
        end)
    end
    
    for i, modeData in ipairs(modes) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(116, 22)
        btn:SetPoint("TOPLEFT", 0, -2 - (i-1) * itemHeight)
        
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

function MeterWindowMixin:ShowClearDropdown(anchor)
    if self.clearDropdown then
        self.clearDropdown:Hide()
        self.clearDropdown = nil
        return
    end
    
    local items = {
        {name = "Clear Current", fn = function()
            Meter:ClearCurrent()
            KDT:Print("Current segment cleared")
        end},
        {name = "Clear All", fn = function()
            Meter:ResetAll()
            KDT:Print("All meter data cleared")
        end},
    }
    
    local itemHeight = 24
    local dropdown = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown:SetSize(120, #items * itemHeight + 4)
    dropdown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.12, 0.98)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    self.clearDropdown = dropdown
    
    for i, item in ipairs(items) do
        local btn = CreateFrame("Button", nil, dropdown)
        btn:SetSize(116, 22)
        btn:SetPoint("TOPLEFT", 2, -2 - (i-1) * itemHeight)
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.4, 0.5)
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(self.settings.font, 10, "OUTLINE")
        text:SetPoint("LEFT", 6, 0)
        text:SetText(item.name)
        text:SetTextColor(0.9, 0.9, 0.9)
        
        btn:SetScript("OnClick", function()
            item.fn()
            dropdown:Hide()
            self.clearDropdown = nil
        end)
    end
    
    dropdown:SetScript("OnUpdate", function(frame)
        if not frame:IsMouseOver() and not anchor:IsMouseOver() then
            C_Timer.After(0.5, function()
                if frame and frame:IsShown() and not frame:IsMouseOver() then
                    frame:Hide()
                    self.clearDropdown = nil
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
    dropdown:SetClipsChildren(true)
    self.segmentDropdown = dropdown
    
    -- Scrollable content (invisible scrollbar - mouse wheel only)
    local fullHeight = numItems * itemHeight
    local content = CreateFrame("Frame", nil, dropdown)
    content:SetSize(156, fullHeight)
    content:SetPoint("TOPLEFT", 2, 0)
    
    local scrollOffset = 0
    if fullHeight > dropdownHeight then
        dropdown:EnableMouseWheel(true)
        dropdown:SetScript("OnMouseWheel", function(_, delta)
            local maxScroll = fullHeight - dropdownHeight + 4
            scrollOffset = math.max(0, math.min(maxScroll, scrollOffset - delta * itemHeight))
            content:SetPoint("TOPLEFT", 2, scrollOffset)
        end)
    end
    
    -- Create segment buttons
    for i, segData in ipairs(segments) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(154, itemHeight)
        btn:SetPoint("TOPLEFT", 0, -(i-1) * itemHeight)
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.4, 0.5)
        
        -- Selection indicator
        local selected = self.viewingSegmentIndex == segData.index
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
            -- Per-window segment selection
            self.viewingSegmentIndex = segData.index
            -- Handle Blizzard session loading if needed
            if segData.index >= 1000 and Meter.isMidnight then
                Meter:LoadBlizzardSession(segData.index - 1000)
                self.viewingSegmentIndex = 1
            end
            self:Refresh()
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
-- Windows dock in any direction based on their relative position.
-- Each window knows its parent (dockedTo), its direct child (dockedChild), and the dock side.

function MeterWindowMixin:ToggleDock()
    if self.dockedTo then
        self:Undock()
    else
        local targetId = self:FindClosestWindow()
        if targetId then
            self:SmartDockTo(targetId)
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
    if not myLeft then return nil end
    
    local closest = nil
    local closestDist = 999999
    
    for id, window in pairs(Meter.windows) do
        if id ~= self.id and window.frame and window.frame:IsShown() then
            local left = window.frame:GetLeft()
            if left then
                local right = window.frame:GetRight()
                local top = window.frame:GetTop()
                local bottom = window.frame:GetBottom()
                
                -- Center-to-center distance
                local myCX, myCY = (myLeft + myRight) / 2, (myTop + myBottom) / 2
                local tCX, tCY = (left + right) / 2, (top + bottom) / 2
                local dist = math.sqrt((myCX - tCX)^2 + (myCY - tCY)^2)
                
                if dist < closestDist then
                    closestDist = dist
                    closest = id
                end
            end
        end
    end
    
    return closest
end

-- Prevent circular docking
function MeterWindowMixin:IsInMyChain(targetId)
    local child = self.dockedChild and Meter:GetWindow(self.dockedChild)
    local visited = {}
    while child do
        if visited[child.id] then break end
        visited[child.id] = true
        if child.id == targetId then return true end
        child = child.dockedChild and Meter:GetWindow(child.dockedChild)
    end
    return false
end

-- Find the root (topmost parent) of a dock chain
function MeterWindowMixin:GetDockRoot()
    local win = self
    local visited = {}
    while win.dockedTo do
        if visited[win.id] then break end
        visited[win.id] = true
        local parent = Meter:GetWindow(win.dockedTo)
        if not parent then break end
        win = parent
    end
    return win
end

function MeterWindowMixin:SmartDockTo(targetId)
    local targetWindow = Meter:GetWindow(targetId)
    if not targetWindow or not targetWindow.frame then return end
    
    -- Prevent circular docking
    if self:IsInMyChain(targetId) then
        KDT:Print("Cannot dock: would create circular reference")
        return
    end
    
    -- If we're already docked somewhere, undock first
    if self.dockedTo then
        self:Undock()
    end
    
    -- Determine best dock side based on relative position of centers
    local myLeft = self.frame:GetLeft()
    local myTop = self.frame:GetTop()
    local myRight = self.frame:GetRight()
    local myBottom = self.frame:GetBottom()
    
    local tLeft = targetWindow.frame:GetLeft()
    local tTop = targetWindow.frame:GetTop()
    local tRight = targetWindow.frame:GetRight()
    local tBottom = targetWindow.frame:GetBottom()
    
    local myCX = (myLeft + myRight) / 2
    local myCY = (myTop + myBottom) / 2
    local tCX = (tLeft + tRight) / 2
    local tCY = (tTop + tBottom) / 2
    
    local dx = myCX - tCX
    local dy = myCY - tCY
    
    local chosenSide
    if math.abs(dy) >= math.abs(dx) then
        chosenSide = dy > 0 and "TOP" or "BOTTOM"
    else
        chosenSide = dx > 0 and "RIGHT" or "LEFT"
    end
    
    -- Store dock relationship
    self.dockedTo = targetId
    self.dockSide = chosenSide
    targetWindow.dockedChild = self.id
    
    -- Save our width/height BEFORE anchoring
    local myWidth = self.frame:GetWidth()
    local myHeight = self.frame:GetHeight()
    
    -- Anchor to target
    self.frame:ClearAllPoints()
    
    if chosenSide == "BOTTOM" then
        self.frame:SetPoint("TOPLEFT", targetWindow.frame, "BOTTOMLEFT", 0, -2)
        self.frame:SetSize(targetWindow.frame:GetWidth(), myHeight)
    elseif chosenSide == "TOP" then
        self.frame:SetPoint("BOTTOMLEFT", targetWindow.frame, "TOPLEFT", 0, 2)
        self.frame:SetSize(targetWindow.frame:GetWidth(), myHeight)
    elseif chosenSide == "RIGHT" then
        self.frame:SetPoint("TOPLEFT", targetWindow.frame, "TOPRIGHT", 2, 0)
        self.frame:SetSize(myWidth, targetWindow.frame:GetHeight())
    elseif chosenSide == "LEFT" then
        self.frame:SetPoint("TOPRIGHT", targetWindow.frame, "TOPLEFT", -2, 0)
        self.frame:SetSize(myWidth, targetWindow.frame:GetHeight())
    end
    
    if self.dockBtn then self.dockBtn.text:SetText("Undk") end
    
    local sideNames = {BOTTOM = "below", TOP = "above", RIGHT = "right of", LEFT = "left of"}
    KDT:Print("Window #" .. self.id .. " docked " .. (sideNames[chosenSide] or "to") .. " Window #" .. targetId)
end

function MeterWindowMixin:DockTo(targetId)
    self:SmartDockTo(targetId)
end

function MeterWindowMixin:Undock()
    if not self.dockedTo then return end
    
    local parentWindow = Meter:GetWindow(self.dockedTo)
    local oldDock = self.dockedTo
    
    -- Remove parent -> self link
    if parentWindow and parentWindow.dockedChild == self.id then
        parentWindow.dockedChild = nil
    end
    
    -- If we have a child, re-link child to our parent
    if self.dockedChild then
        local childWindow = Meter:GetWindow(self.dockedChild)
        if childWindow then
            if parentWindow and parentWindow.dockedChild == nil then
                parentWindow.dockedChild = self.dockedChild
                childWindow.dockedTo = parentWindow.id
                childWindow.frame:ClearAllPoints()
                if childWindow.dockSide == "BOTTOM" then
                    childWindow.frame:SetPoint("TOPLEFT", parentWindow.frame, "BOTTOMLEFT", 0, -2)
                    childWindow.frame:SetSize(parentWindow.frame:GetWidth(), childWindow.frame:GetHeight())
                elseif childWindow.dockSide == "TOP" then
                    childWindow.frame:SetPoint("BOTTOMLEFT", parentWindow.frame, "TOPLEFT", 0, 2)
                    childWindow.frame:SetSize(parentWindow.frame:GetWidth(), childWindow.frame:GetHeight())
                elseif childWindow.dockSide == "RIGHT" then
                    childWindow.frame:SetPoint("TOPLEFT", parentWindow.frame, "TOPRIGHT", 2, 0)
                    childWindow.frame:SetSize(childWindow.frame:GetWidth(), parentWindow.frame:GetHeight())
                elseif childWindow.dockSide == "LEFT" then
                    childWindow.frame:SetPoint("TOPRIGHT", parentWindow.frame, "TOPLEFT", -2, 0)
                    childWindow.frame:SetSize(childWindow.frame:GetWidth(), parentWindow.frame:GetHeight())
                end
            else
                -- No parent to re-link to, child becomes free
                childWindow.dockedTo = nil
                childWindow.dockSide = nil
                childWindow.frame:ClearAllPoints()
                childWindow.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                if childWindow.dockBtn then childWindow.dockBtn.text:SetText("Dock") end
            end
        end
    end
    
    -- Clear our dock state
    self.dockedTo = nil
    self.dockedChild = nil
    self.dockSide = nil
    
    -- Reposition independently using saved width/height
    local w = self.frame:GetWidth()
    local h = self.frame:GetHeight()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 50 * self.id, 0)
    self.frame:SetSize(w > 10 and w or self.settings.windowWidth, h > 10 and h or self.settings.windowHeight)
    
    if self.dockBtn then self.dockBtn.text:SetText("Dock") end
    KDT:Print("Window #" .. self.id .. " undocked from Window #" .. oldDock)
end

function MeterWindowMixin:StartMovingDockedChildren()
    -- Children follow via anchoring automatically
end

function MeterWindowMixin:StopMovingDockedChildren()
    -- Position is maintained via anchoring
end

function MeterWindowMixin:Show()
    self.frame:Show()
    self:Refresh()
    -- Save all open windows (but NOT position - that's saved on drag/resize/logout)
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
    
    -- Show DPS header with correct per-second value
    local headerValue = data.value
    local headerLabel = Meter.MODE_NAMES[self.mode] or "Value"
    if headerValue then
        local canRead = not (issecretvalue and issecretvalue(headerValue))
        if canRead then
            local showPS = (self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS)
            local txt = Meter.FormatNumber(headerValue)
            if showPS then txt = txt .. "/s" end
            GameTooltip:AddLine(headerLabel .. ": " .. txt, 1, 1, 1)
        end
    end
    
    -- Try live data first (during combat), then fall back to segment data
    local isLive = data.isLive and data.source
    
    if isLive and C_DamageMeter then
        -- LIVE MODE: Fetch summary stats directly from API for all types
        GameTooltip:AddLine(" ")
        
        local typesToShow = {
            {type = Enum.DamageMeterType.DamageDone, label = "Damage"},
            {type = Enum.DamageMeterType.HealingDone, label = "Healing"},
        }
        if Enum.DamageMeterType.Absorbs then
            table.insert(typesToShow, {type = Enum.DamageMeterType.Absorbs, label = "Absorbs"})
        end
        table.insert(typesToShow, {type = Enum.DamageMeterType.DamageTaken, label = "Damage Taken"})
        
        -- Find this player's data across all types
        local sourceGUID = SafeRead(data.source.sourceGUID)
        local isLocal = data.source.isLocalPlayer
        
        for _, typeInfo in ipairs(typesToShow) do
            local ok, typeSession = pcall(C_DamageMeter.GetCombatSessionFromType, Enum.DamageMeterSessionType.Current, typeInfo.type)
            if ok and typeSession and typeSession.combatSources then
                for _, src in ipairs(typeSession.combatSources) do
                    local match = false
                    if isLocal and src.isLocalPlayer then
                        match = true
                    elseif sourceGUID then
                        local srcGUID = SafeRead(src.sourceGUID)
                        if srcGUID and srcGUID == sourceGUID then match = true end
                    end
                    
                    if match then
                        local amount = SafeRead(src.totalAmount)
                        if amount and amount > 0 then
                            GameTooltip:AddDoubleLine(typeInfo.label .. ":", Meter.FormatNumber(amount), 1, 1, 1, 0.7, 0.7, 0.7)
                        end
                        break
                    end
                end
            end
        end
        
        -- LIVE Spell Breakdown: Fetch from GetCombatSessionSourceFromID
        if C_DamageMeter.GetCombatSessionSourceFromID and sourceGUID then
            local spellType = self.liveSessionType or Meter.MODE_TO_BLIZZARD[self.mode]
            if spellType then
                -- Get current session ID for spell lookup
                local sessions = nil
                pcall(function() sessions = C_DamageMeter.GetAvailableCombatSessions() end)
                local sessionId = nil
                if sessions and #sessions > 0 then
                    sessionId = sessions[#sessions].sessionID
                end
                
                if sessionId then
                    local ok, spellData = pcall(C_DamageMeter.GetCombatSessionSourceFromID, sessionId, spellType, sourceGUID)
                    if ok and spellData and spellData.combatSpells and #spellData.combatSpells > 0 then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Top Spells:", 0.9, 0.8, 0.2)
                        
                        -- Sort spells by amount
                        local spells = {}
                        local spellTotal = 0
                        for _, spell in ipairs(spellData.combatSpells) do
                            local spellId = SafeRead(spell.spellID)
                            local spellAmt = SafeRead(spell.totalAmount)
                            if spellId and spellAmt then
                                local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
                                local spellName = spellInfo and spellInfo.name or ("Spell " .. spellId)
                                local spellIcon = spellInfo and spellInfo.iconID
                                table.insert(spells, {
                                    name = spellName or ("Spell " .. spellId),
                                    icon = spellIcon,
                                    total = spellAmt,
                                })
                                spellTotal = spellTotal + spellAmt
                            end
                        end
                        table.sort(spells, function(a, b) return a.total > b.total end)
                        
                        for j = 1, math.min(8, #spells) do
                            local spell = spells[j]
                            local pct = spellTotal > 0 and (spell.total / spellTotal * 100) or 0
                            local spellLabel = spell.name
                            if spell.icon then
                                spellLabel = "|T" .. spell.icon .. ":14:14:0:0|t " .. spellLabel
                            end
                            GameTooltip:AddDoubleLine(
                                spellLabel,
                                Meter.FormatNumber(spell.total) .. " (" .. string.format("%.1f%%", pct) .. ")",
                                1, 1, 1, 0.6, 0.6, 0.6
                            )
                        end
                        
                        if #spells > 8 then
                            GameTooltip:AddLine("... and " .. (#spells - 8) .. " more", 0.5, 0.5, 0.5)
                        end
                    end
                end
            end
        end
    else
        -- HISTORICAL MODE: Use stored segment data
        local segment = Meter:GetCurrentSegment(self.viewingSegmentIndex)
        if segment and segment.players and segment.players[data.name] then
            local player = segment.players[data.name]
            
            GameTooltip:AddLine(" ")
            if player.damage > 0 then
                GameTooltip:AddDoubleLine("Damage:", Meter.FormatNumber(player.damage), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            if player.healing > 0 then
                GameTooltip:AddDoubleLine("Healing:", Meter.FormatNumber(player.healing), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            if (player.absorbs or 0) > 0 then
                GameTooltip:AddDoubleLine("Absorbs:", Meter.FormatNumber(player.absorbs), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            if player.damageTaken > 0 then
                GameTooltip:AddDoubleLine("Damage Taken:", Meter.FormatNumber(player.damageTaken), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            if player.interrupts > 0 then
                GameTooltip:AddDoubleLine("Interrupts:", tostring(player.interrupts), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            if (player.dispels or 0) > 0 then
                GameTooltip:AddDoubleLine("Dispels:", tostring(player.dispels), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            if player.deaths > 0 then
                GameTooltip:AddDoubleLine("Deaths:", tostring(player.deaths), 1, 1, 1, 0.7, 0.7, 0.7)
            end
            
            -- Spell breakdown from stored segment data
            local spells = Meter:GetSpellBreakdown(data.name, self.mode)
            if spells and #spells > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Top Spells:", 0.9, 0.8, 0.2)
                
                local spellTotal = 0
                for _, spell in ipairs(spells) do spellTotal = spellTotal + spell.total end
                
                for j = 1, math.min(8, #spells) do
                    local spell = spells[j]
                    local pct = spellTotal > 0 and (spell.total / spellTotal * 100) or 0
                    local spellLabel = spell.name
                    if spell.icon then
                        spellLabel = "|T" .. spell.icon .. ":14:14:0:0|t " .. spellLabel
                    end
                    GameTooltip:AddDoubleLine(
                        spellLabel,
                        Meter.FormatNumber(spell.total) .. " (" .. string.format("%.1f%%", pct) .. ")",
                        1, 1, 1, 0.6, 0.6, 0.6
                    )
                end
                
                if #spells > 8 then
                    GameTooltip:AddLine("... and " .. (#spells - 8) .. " more", 0.5, 0.5, 0.5)
                end
            end
        end
    end
    
    GameTooltip:Show()
end

-- ==================== SPELL BREAKDOWN WINDOW (Click on bar) ====================
function MeterWindowMixin:ShowSpellBreakdownWindow(bar)
    if not bar.playerData then return end
    local data = bar.playerData
    local playerName = data.name
    local classFile = data.class
    local isLive = data.isLive and data.source
    
    -- Close existing breakdown window
    if self.spellBreakdownFrame then
        self.spellBreakdownFrame:Hide()
        self.spellBreakdownFrame = nil
    end
    
    -- Fetch spell list
    local spells = {}
    
    if isLive and C_DamageMeter and C_DamageMeter.GetCombatSessionSourceFromID then
        local sourceGUID = SafeRead(data.source.sourceGUID)
        local spellType = self.liveSessionType or Meter.MODE_TO_BLIZZARD[self.mode]
        if sourceGUID and spellType then
            local sessions = nil
            pcall(function() sessions = C_DamageMeter.GetAvailableCombatSessions() end)
            local sessionId = sessions and #sessions > 0 and sessions[#sessions].sessionID or nil
            if sessionId then
                local ok, spellData = pcall(C_DamageMeter.GetCombatSessionSourceFromID, sessionId, spellType, sourceGUID)
                if ok and spellData and spellData.combatSpells then
                    for _, spell in ipairs(spellData.combatSpells) do
                        local spellId = SafeRead(spell.spellID)
                        local spellAmt = SafeRead(spell.totalAmount)
                        local spellPS = SafeRead(spell.amountPerSecond)
                        if spellId and spellAmt then
                            local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
                            table.insert(spells, {
                                id = spellId,
                                name = spellInfo and spellInfo.name or ("Spell " .. spellId),
                                icon = spellInfo and spellInfo.iconID,
                                total = spellAmt,
                                perSec = spellPS or 0,
                            })
                        end
                    end
                end
            end
        end
    else
        -- Historical: from stored segment
        local storedSpells = Meter:GetSpellBreakdown(playerName, self.mode, self.viewingSegmentIndex)
        if storedSpells then
            for _, s in ipairs(storedSpells) do
                table.insert(spells, {
                    id = s.id, name = s.name, icon = s.icon, total = s.total, perSec = 0,
                })
            end
        end
    end
    
    if #spells == 0 then return end
    
    table.sort(spells, function(a, b) return a.total > b.total end)
    
    local spellTotal = 0
    for _, s in ipairs(spells) do spellTotal = spellTotal + s.total end
    local maxSpellVal = spells[1] and spells[1].total or 1
    
    -- Build the window
    local settings = self.settings
    local itemHeight = 20
    local headerHeight = 28
    local numSpells = #spells
    local visibleItems = math.min(numSpells, 15)
    local windowHeight = headerHeight + visibleItems * itemHeight + 6
    local windowWidth = 280
    
    local frameName = "KryosSpellBreakdown" .. self.id
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(windowWidth, windowHeight)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    frame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    frame:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClipsChildren(true)
    self.spellBreakdownFrame = frame
    
    -- Header
    local classColors = KDT.CLASS_COLORS[classFile] or {0.7, 0.7, 0.7}
    local header = frame:CreateFontString(nil, "OVERLAY")
    header:SetFont(settings.font, settings.fontSize, settings.fontFlags)
    header:SetPoint("TOPLEFT", 8, -6)
    header:SetText(playerName .. " - " .. (Meter.MODE_NAMES[self.mode] or "Spells"))
    header:SetTextColor(classColors[1], classColors[2], classColors[3])
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetNormalFontObject("GameFontNormalSmall")
    local closeTex = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTex:SetFont(settings.font, 12, settings.fontFlags)
    closeTex:SetPoint("CENTER")
    closeTex:SetText("×")
    closeTex:SetTextColor(0.7, 0.7, 0.7)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        self.spellBreakdownFrame = nil
    end)
    closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(0.7, 0.7, 0.7) end)
    
    -- Scrollable content area
    local contentHeight = numSpells * itemHeight
    local content = CreateFrame("Frame", nil, frame)
    content:SetSize(windowWidth - 4, contentHeight)
    content:SetPoint("TOPLEFT", 2, -headerHeight)
    
    local scrollOffset = 0
    if numSpells > visibleItems then
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            local maxScroll = contentHeight - (visibleItems * itemHeight)
            scrollOffset = math.max(0, math.min(maxScroll, scrollOffset - delta * itemHeight * 2))
            content:SetPoint("TOPLEFT", 2, -headerHeight + scrollOffset)
        end)
    end
    
    -- Spell rows
    local showPerSecond = (self.mode == Meter.MODES.DPS or self.mode == Meter.MODES.HPS)
    
    for i, spell in ipairs(spells) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(windowWidth - 8, itemHeight)
        row:SetPoint("TOPLEFT", 2, -(i - 1) * itemHeight)
        
        -- Bar background
        local barBg = row:CreateTexture(nil, "BACKGROUND")
        barBg:SetAllPoints()
        barBg:SetTexture(settings.barTexture)
        barBg:SetVertexColor(0.08, 0.08, 0.1, 0.8)
        
        -- Colored bar
        local barFill = row:CreateTexture(nil, "ARTWORK")
        barFill:SetPoint("TOPLEFT", 1, -1)
        barFill:SetPoint("BOTTOMLEFT", 1, 1)
        barFill:SetTexture(settings.barTexture)
        local pct = maxSpellVal > 0 and (spell.total / maxSpellVal) or 0
        barFill:SetWidth(math.max((windowWidth - 10) * pct, 2))
        barFill:SetVertexColor(classColors[1] * 0.6, classColors[2] * 0.6, classColors[3] * 0.6, 0.7)
        
        -- Spell icon
        if spell.icon then
            local icon = row:CreateTexture(nil, "OVERLAY")
            icon:SetSize(itemHeight - 4, itemHeight - 4)
            icon:SetPoint("LEFT", 2, 0)
            icon:SetTexture(spell.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        
        -- Spell name
        local nameText = row:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(settings.font, settings.fontSize - 1, settings.fontFlags)
        nameText:SetPoint("LEFT", spell.icon and (itemHeight + 2) or 4, 0)
        nameText:SetPoint("RIGHT", -90, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(spell.name)
        nameText:SetTextColor(0.95, 0.95, 0.95)
        
        -- Value
        local valText = row:CreateFontString(nil, "OVERLAY")
        valText:SetFont(settings.font, settings.fontSize - 1, settings.fontFlags)
        valText:SetPoint("RIGHT", -40, 0)
        valText:SetJustifyH("RIGHT")
        local displayVal = showPerSecond and spell.perSec > 0 and spell.perSec or spell.total
        local valStr = Meter.FormatNumber(displayVal)
        if showPerSecond and spell.perSec > 0 then valStr = valStr .. "/s" end
        valText:SetText(valStr)
        valText:SetTextColor(0.8, 0.8, 0.8)
        
        -- Percentage
        local pctText = row:CreateFontString(nil, "OVERLAY")
        pctText:SetFont(settings.font, settings.fontSize - 1, settings.fontFlags)
        pctText:SetPoint("RIGHT", -4, 0)
        pctText:SetJustifyH("RIGHT")
        local pctVal = spellTotal > 0 and (spell.total / spellTotal * 100) or 0
        pctText:SetText(string.format("%.1f%%", pctVal))
        pctText:SetTextColor(0.6, 0.6, 0.6)
        
        -- Tooltip on hover with spell ID
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if spell.icon then
                GameTooltip:AddLine("|T" .. spell.icon .. ":16:16:0:0|t " .. spell.name, 1, 1, 1)
            else
                GameTooltip:AddLine(spell.name, 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("Total:", Meter.FormatNumber(spell.total), 0.7, 0.7, 0.7, 1, 1, 1)
            if spell.perSec and spell.perSec > 0 then
                GameTooltip:AddDoubleLine("Per Second:", Meter.FormatNumber(spell.perSec) .. "/s", 0.7, 0.7, 0.7, 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("Percentage:", string.format("%.2f%%", pctVal), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddLine("Spell ID: " .. spell.id, 0.4, 0.4, 0.4)
            GameTooltip:Show()
            barBg:SetVertexColor(0.15, 0.15, 0.2, 0.9)
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
            barBg:SetVertexColor(0.08, 0.08, 0.1, 0.8)
        end)
    end
    
    -- Total footer
    if numSpells > 1 then
        local totalText = frame:CreateFontString(nil, "OVERLAY")
        totalText:SetFont(settings.font, settings.fontSize - 2, settings.fontFlags)
        totalText:SetPoint("BOTTOMRIGHT", -6, 2)
        totalText:SetText(numSpells .. " spells | Total: " .. Meter.FormatNumber(spellTotal))
        totalText:SetTextColor(0.5, 0.5, 0.5)
    end
    
    -- Close on Escape
    tinsert(UISpecialFrames, frameName)
end

function MeterWindowMixin:ReportToChat()
    local segment = Meter:GetCurrentSegment(self.viewingSegmentIndex)
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
    menu:SetSize(160, 270)
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
    AddButton("Absorbs", function() self:SetMode(Meter.MODES.ABSORBS) end, self.mode == Meter.MODES.ABSORBS)
    AddButton("Interrupts", function() self:SetMode(Meter.MODES.INTERRUPTS) end, self.mode == Meter.MODES.INTERRUPTS)
    AddButton("Dispels", function() self:SetMode(Meter.MODES.DISPELS) end, self.mode == Meter.MODES.DISPELS)
    yOffset = yOffset - 5
    AddButton("Report to Chat", function() self:ReportToChat() end)
    AddButton("Clear Current", function() Meter:ClearCurrent(); KDT:Print("Current segment cleared") end)
    AddButton("Clear All", function() Meter:ResetAll(); KDT:Print("All meter data cleared") end)
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
    if not KDT.DB then return end
    
    local left = self.frame:GetLeft()
    local top = self.frame:GetTop()
    if not left or not top then return end
    
    local width = self.frame:GetWidth()
    local height = self.frame:GetHeight()
    if width <= 0 or height <= 0 then return end
    
    KDT.DB.meter = KDT.DB.meter or {}
    KDT.DB.meter.windows = KDT.DB.meter.windows or {}
    KDT.DB.meter.windows["KryosMeterWindow" .. self.id] = {
        left = left,
        top = top,
        width = width,
        height = height,
        mode = self.mode,
    }
end

function Meter:HideAllWindows()
    for _, window in pairs(self.windows) do
        window.frame:Hide()
    end
    -- Save state once at the end
    self:SaveOpenWindows()
end
