---------------------------------------------------------------------------
-- KryosDungeonTool: Minimap Button Collector
-- Based on MinimapButtonButton's approach: parent buttons to a container,
-- override movement methods, don't touch textures.
---------------------------------------------------------------------------
local _, KDT = ...

local Collector = {}
KDT.MinimapCollector = Collector

local collectedButtons = {}
local collectedButtonMap = {}
local collectorButton = nil
local buttonContainer = nil
local trayVisible = false
local BUTTON_SIZE = 33
local BUTTON_SPACING = 1
local SCAN_DELAY = 4

-- Cached original methods (before any addon overwrites them)
local OrigClearAllPoints = UIParent.ClearAllPoints
local OrigSetPoint = UIParent.SetPoint
local OrigSetScale = UIParent.SetScale

local function doNothing() end

-- Polling for mouse-leave
local pollFrame = CreateFrame("Frame")
pollFrame:Hide()

---------------------------------------------------------------------------
-- BLACKLIST
---------------------------------------------------------------------------
local BLACKLIST = {
	["Minimap"] = true,
	["MinimapBackdrop"] = true,
	["MinimapCluster"] = true,
	["MinimapCompassTexture"] = true,
	["MinimapZoneText"] = true,
	["MinimapZoneTextButton"] = true,
	["MinimapBorder"] = true,
	["MinimapBorderTop"] = true,
	["MinimapNorthTag"] = true,
	["MiniMapTracking"] = true,
	["MiniMapTrackingButton"] = true,
	["MiniMapMailFrame"] = true,
	["MiniMapMailIcon"] = true,
	["MiniMapMailBorder"] = true,
	["MinimapZoomIn"] = true,
	["MinimapZoomOut"] = true,
	["MiniMapWorldMapButton"] = true,
	["GameTimeFrame"] = true,
	["TimeManagerClockButton"] = true,
	["QueueStatusMinimapButton"] = true,
	["GarrisonLandingPageMinimapButton"] = true,
	["ExpansionLandingPageMinimapButton"] = true,
	["AddonCompartmentFrame"] = true,
	["MinimapToggleButton"] = true,
	["MiniMapInstanceDifficulty"] = true,
	["GuildInstanceDifficulty"] = true,
	["MiniMapChallengeMode"] = true,
	["MiniMapLFGFrame"] = true,
	["LFGMinimapFrame"] = true,
	["QueueStatusButton"] = true,
	["MinimapOverlayFrame"] = true,
	["KDT_MinimapCollectorButton"] = true,
}

local function isSecureFrame(name)
	if not name then return false end
	return issecurevariable(_G, name)
end

local function nameMatchesButtonPattern(name)
	local patterns = {
		"^LibDBIcon10_",
		"MinimapButton",
		"MinimapFrame",
		"MinimapIcon",
		"[-_]Minimap[-_]",
		"Minimap$",
	}
	for _, pattern in ipairs(patterns) do
		if name:match(pattern) then return true end
	end
	return false
end

local function isMinimapButton(frame)
	if type(frame) ~= "table" then return false end
	if not frame.IsObjectType or not frame:IsObjectType("Frame") then return false end

	local name = frame:GetName()
	if not name then
		-- Unnamed frames: check for LibDBIcon .icon field
		if frame.icon and frame:GetWidth() >= 20 then return true end
		return false
	end

	if BLACKLIST[name] then return false end
	if isSecureFrame(name) then return false end

	-- Skip numbered duplicates (like Button1, Button2)
	if name:match("%d$") and not name:match("^TomCats%-") then return false end

	return nameMatchesButtonPattern(name)
end

---------------------------------------------------------------------------
-- COLLECTING
---------------------------------------------------------------------------
local function collectButton(button)
	if collectedButtonMap[button] then return end

	button:SetParent(buttonContainer)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:SetScript("OnDragStart", nil)
	button:SetScript("OnDragStop", nil)
	button:SetIgnoreParentScale(false)
	button:SetScale(1)

	-- Override movement methods to prevent addons from reclaiming buttons
	button.ClearAllPoints = doNothing
	button.SetPoint = doNothing
	button.SetParent = doNothing
	button.SetScale = doNothing

	table.insert(collectedButtons, button)
	collectedButtonMap[button] = true
end

local function collectLibDBIconButtons()
	local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
	if not LibDBIcon then return end

	for _, buttonName in ipairs(LibDBIcon:GetButtonList()) do
		local button = LibDBIcon:GetMinimapButton(buttonName)
		if button and not collectedButtonMap[button] and not BLACKLIST[button:GetName() or ""] then
			collectButton(button)
		end
	end
end

local function scanMinimapChildren()
	if not Minimap then return end
	for _, child in ipairs({ Minimap:GetChildren() }) do
		if not collectedButtonMap[child] and isMinimapButton(child) then
			collectButton(child)
		end
	end
end

local function updateLayout()
	local count = 0
	for _, btn in ipairs(collectedButtons) do
		if btn:IsShown() then
			count = count + 1
		end
	end

	local totalWidth = count * BUTTON_SIZE + (count - 1) * BUTTON_SPACING + 10
	local totalHeight = BUTTON_SIZE + 10

	buttonContainer:SetSize(math.max(totalWidth, 10), totalHeight)
	buttonContainer:ClearAllPoints()
	buttonContainer:SetPoint("RIGHT", collectorButton, "LEFT", -4, 0)

	local idx = 0
	for _, btn in ipairs(collectedButtons) do
		if btn:IsShown() then
			OrigClearAllPoints(btn)
			OrigSetPoint(btn, "LEFT", buttonContainer, "LEFT", 5 + idx * (BUTTON_SIZE + BUTTON_SPACING), 0)
			OrigSetScale(btn, 1)
			idx = idx + 1
		end
	end

	-- Update badge
	if collectorButton and collectorButton.badge then
		collectorButton.badge:SetText(#collectedButtons > 0 and #collectedButtons or "")
	end
end

local function collectAllAndUpdate()
	local prev = #collectedButtons
	collectLibDBIconButtons()
	scanMinimapChildren()
	if #collectedButtons > prev then
		table.sort(collectedButtons, function(a, b)
			return (a:GetName() or "") < (b:GetName() or "")
		end)
	end
	updateLayout()
end

---------------------------------------------------------------------------
-- SHOW / HIDE
---------------------------------------------------------------------------
local function IsMouseOverAny()
	if collectorButton and collectorButton:IsMouseOver() then return true end
	if buttonContainer and buttonContainer:IsShown() and buttonContainer:IsMouseOver() then return true end
	return false
end

local pollElapsed = 0
pollFrame:SetScript("OnUpdate", function(self, elapsed)
	pollElapsed = pollElapsed + elapsed
	if pollElapsed < 0.15 then return end
	pollElapsed = 0

	if not trayVisible then
		self:Hide()
		return
	end

	if not IsMouseOverAny() then
		trayVisible = false
		buttonContainer:Hide()
		self:Hide()
	end
end)

local function ShowTray()
	if trayVisible then return end
	trayVisible = true

	collectAllAndUpdate()
	buttonContainer:Show()
	updateLayout()

	pollElapsed = 0
	pollFrame:Show()
end

local function HideTray()
	if not trayVisible then return end
	trayVisible = false
	buttonContainer:Hide()
	pollFrame:Hide()
end

---------------------------------------------------------------------------
-- COLLECTOR BUTTON (minimap)
---------------------------------------------------------------------------
local function CreateCollectorButton()
	if collectorButton then return end

	local btn = CreateFrame("Button", "KDT_MinimapCollectorButton", Minimap)
	btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(10)
	btn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)

	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER", 0, 1)
	icon:SetAtlas("Garr_FollowerIconCombat")
	btn.icon = icon

	local overlay = btn:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetPoint("TOPLEFT")
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(25, 25)
	bg:SetPoint("CENTER", 0, 1)
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetVertexColor(0, 0, 0, 0.6)

	local badge = btn:CreateFontString(nil, "OVERLAY")
	badge:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
	badge:SetPoint("BOTTOMRIGHT", 2, 2)
	badge:SetTextColor(1, 0.82, 0)
	btn.badge = badge

	local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetSize(25, 25)
	highlight:SetPoint("CENTER", 0, 1)
	highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	btn:SetScript("OnEnter", function(self)
		ShowTray()
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("KDT: Minimap Buttons", 1, 1, 1)
		GameTooltip:AddLine(#collectedButtons .. " collected", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	collectorButton = btn
end

---------------------------------------------------------------------------
-- BUTTON CONTAINER
---------------------------------------------------------------------------
local function CreateButtonContainer()
	if buttonContainer then return end

	local f = CreateFrame("Frame", nil, collectorButton, "BackdropTemplate")
	f:SetFrameStrata("MEDIUM")
	f:SetFrameLevel(7)
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	f:SetBackdropColor(0, 0, 0, 0.9)
	f:SetBackdropBorderColor(0.6, 0.1, 0.1, 0.8)
	f:Hide()

	buttonContainer = f
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
function Collector:Init()
	local qol = KDT.DB and KDT.DB.qol
	if not qol or not qol.minimapCollectorEnabled then return end

	CreateCollectorButton()
	CreateButtonContainer()

	-- Hook LibDBIcon for buttons created after init
	local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
	if LibDBIcon and LibDBIcon.RegisterCallback then
		LibDBIcon.RegisterCallback("KDT_MinimapCollector", "LibDBIcon_IconCreated", function(_, button)
			if button and not collectedButtonMap[button] and not BLACKLIST[button:GetName() or ""] then
				collectButton(button)
				updateLayout()
			end
		end)
	end

	C_Timer.After(SCAN_DELAY, function() collectAllAndUpdate() end)
	C_Timer.After(SCAN_DELAY + 3, function() collectAllAndUpdate() end)
	C_Timer.After(SCAN_DELAY + 8, function() collectAllAndUpdate() end)
end
