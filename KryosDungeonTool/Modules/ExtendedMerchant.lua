---------------------------------------------------------------------------
-- KryosDungeonTool: Extended Merchant Module
-- 1) Expands merchant frame to 20 items (from EnhanceQoL)
-- 2) Sell Marked: Shift-click bag items to mark, sell via button at vendor
---------------------------------------------------------------------------
local _, KDT = ...

local ExtMerchant = {}
KDT.ExtMerchant = ExtMerchant

ExtMerchant.enabled = false
ExtMerchant.hooked = false
ExtMerchant.originalItemsPerPage = _G.MERCHANT_ITEMS_PER_PAGE or 10

---------------------------------------------------------------------------
-- PART 1: EXPAND MERCHANT (1:1 from EnhanceQoL Merchant.lua)
---------------------------------------------------------------------------
local function RebuildMerchantFrame()
	if not ExtMerchant.enabled or not MerchantFrame then return end
	MerchantFrame:SetWidth(696)
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		if not _G["MerchantItem" .. i] then
			CreateFrame("Frame", "MerchantItem" .. i, MerchantFrame, "MerchantItemTemplate")
		end
	end
end

local function UpdateSlotPositions()
	if not ExtMerchant.enabled or not MerchantFrame then return end
	local vertSpacing = -16
	local perSubpage = ExtMerchant.originalItemsPerPage or 10
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local slot = _G["MerchantItem" .. i]
		if slot then
			slot:Show()
			if (i % perSubpage) == 1 then
				if i == 1 then
					slot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 24, -70)
				else
					slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - (perSubpage - 1))], "TOPRIGHT", 12, 0)
				end
			else
				if (i % 2) == 1 then
					slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 2)], "BOTTOMLEFT", 0, vertSpacing)
				else
					slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", 12, 0)
				end
			end
		end
	end
	local n = securecall("GetMerchantNumItems")
	if n and n <= MERCHANT_ITEMS_PER_PAGE then
		if MerchantPageText then MerchantPageText:Show() end
		if MerchantPrevPageButton then MerchantPrevPageButton:Show(); MerchantPrevPageButton:Disable() end
		if MerchantNextPageButton then MerchantNextPageButton:Show(); MerchantNextPageButton:Disable() end
	end
end

local function UpdateBuyBackSlotPositions()
	if not ExtMerchant.enabled or not MerchantFrame then return end
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local slot = _G["MerchantItem" .. i]
		if slot then
			if i > (BUYBACK_ITEMS_PER_PAGE or 12) then
				slot:Hide()
			else
				if i == 1 then
					slot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 64, -105)
				elseif (i % 3) == 1 then
					slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 3)], "BOTTOMLEFT", 0, -30)
				else
					slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", 50, 0)
				end
			end
		end
	end
end

local function RebuildTokenPositions()
	if not ExtMerchant.enabled or not MerchantFrame then return end
	local moneyBg = _G.MerchantMoneyBg
	local moneyInset = _G.MerchantMoneyInset
	local extraInset = _G.MerchantExtraCurrencyInset
	local extraBg = _G.MerchantExtraCurrencyBg
	if moneyBg then
		moneyBg:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMRIGHT", -8, 25)
		moneyBg:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMRIGHT", -169, 6)
	end
	if extraInset and moneyInset then
		extraInset:ClearAllPoints()
		extraInset:SetPoint("TOPLEFT", moneyInset, "TOPLEFT", -171, 0)
		extraInset:SetPoint("BOTTOMRIGHT", moneyInset, "BOTTOMLEFT", 0, 0)
	end
	if extraBg and moneyBg then
		extraBg:ClearAllPoints()
		extraBg:SetPoint("TOPLEFT", moneyBg, "TOPLEFT", -171, 0)
		extraBg:SetPoint("BOTTOMRIGHT", moneyBg, "BOTTOMLEFT", -3, 0)
	end
	if GetMerchantCurrencies then
		local currencies = { GetMerchantCurrencies() }
		MerchantFrame.numCurrencies = #currencies
		for index = 1, #currencies do
			local tokenButton = _G["MerchantToken" .. index]
			if tokenButton then
				tokenButton:ClearAllPoints()
				if index == 1 then
					tokenButton:SetPoint("BOTTOMRIGHT", -16, 8)
				elseif index == 4 then
					tokenButton:SetPoint("RIGHT", _G["MerchantToken" .. index - 1], "LEFT", -15, 0)
				else
					tokenButton:SetPoint("RIGHT", _G["MerchantToken" .. index - 1], "LEFT", 0, 0)
				end
			end
		end
	end
end

local function RebuildSellAllJunkButtonPositions()
	if not ExtMerchant.enabled then return end
	if not securecall("CanMerchantRepair") then
		local junk = _G.MerchantSellAllJunkButton
		local bb = _G.MerchantBuyBackItem
		if junk and bb then junk:SetPoint("RIGHT", bb, "LEFT", -18, 0) end
	end
end

local function RebuildGuildBankRepairButtonPositions()
	if not ExtMerchant.enabled then return end
	local g = _G.MerchantGuildBankRepairButton
	local r = _G.MerchantRepairAllButton
	if g and r then g:SetPoint("LEFT", r, "RIGHT", 10, 0) end
end

local function RebuildBuyBackItemPositions()
	if not ExtMerchant.enabled then return end
	local bb = _G.MerchantBuyBackItem
	local mi10 = _G.MerchantItem10
	if bb and mi10 then bb:SetPoint("TOPLEFT", mi10, "BOTTOMLEFT", 17, -20) end
end

local function RebuildPageButtonPositions()
	if not ExtMerchant.enabled then return end
	if MerchantPrevPageButton then MerchantPrevPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 36, 55) end
	if MerchantPageText then MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOM", 166, 50) end
	if MerchantNextPageButton then MerchantNextPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 296, 55) end
end

function ExtMerchant:Enable()
	if self.enabled then return end
	self.enabled = true
	_G.MERCHANT_ITEMS_PER_PAGE = 20
	RebuildMerchantFrame()
	RebuildPageButtonPositions()
	RebuildBuyBackItemPositions()
	RebuildTokenPositions()
	RebuildGuildBankRepairButtonPositions()
	if not self.hooked then
		hooksecurefunc("MerchantFrame_UpdateRepairButtons", RebuildSellAllJunkButtonPositions)
		hooksecurefunc("MerchantFrame_UpdateMerchantInfo", UpdateSlotPositions)
		hooksecurefunc("MerchantFrame_UpdateBuybackInfo", UpdateBuyBackSlotPositions)
		self.hooked = true
	end
	if MerchantFrame then
		UpdateSlotPositions()
		UpdateBuyBackSlotPositions()
	end
end

function ExtMerchant:Disable()
	if not self.enabled then return end
	self.enabled = false
end

---------------------------------------------------------------------------
-- PART 2: SELL MARKED ITEMS
--
-- Button: NO global name. Stored on KDT._sellBtn only.
-- This prevents old HookScript closures from finding/creating dupes.
-- Click: OnClick + IsShiftKeyDown (proven working in WoW 12.0)
---------------------------------------------------------------------------
local markedItems = {}
local markedCount = 0

local function MarkKey(bag, slot)
	return bag .. ":" .. slot
end

local function RecountMarked()
	local n = 0
	for _ in pairs(markedItems) do n = n + 1 end
	markedCount = n
	return n
end

local function SetOverlay(button, show)
	if not button then return end
	if show then
		if not button._kdtSellOverlay then
			local ov = button:CreateTexture(nil, "OVERLAY", nil, 2)
			ov:SetAllPoints()
			ov:SetColorTexture(0.9, 0.1, 0.1, 0.35)
			button._kdtSellOverlay = ov
		end
		button._kdtSellOverlay:Show()
		if not button._kdtSellX then
			local x = button:CreateFontString(nil, "OVERLAY", nil)
			x:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
			x:SetPoint("TOPRIGHT", -1, -1)
			x:SetText("X")
			x:SetTextColor(1, 0.2, 0.2, 1)
			button._kdtSellX = x
		end
		button._kdtSellX:Show()
	else
		if button._kdtSellOverlay then button._kdtSellOverlay:Hide() end
		if button._kdtSellX then button._kdtSellX:Hide() end
	end
end

local function RefreshAllOverlays()
	for i = 1, 13 do
		local cf = _G["ContainerFrame" .. i]
		if cf and cf:IsShown() and cf.Items then
			for _, button in ipairs(cf.Items) do
				if button:IsShown() and button.GetSlotAndBagID then
					local s, b = button:GetSlotAndBagID()
					if s and b then
						SetOverlay(button, markedItems[MarkKey(b, s)] == true)
					end
				end
			end
		end
	end
end

local function UpdateSellButton()
	local btn = KDT._sellBtn
	if not btn then return end
	if markedCount > 0 then
		btn.text:SetText("Sell Marked (" .. markedCount .. ")")
		btn.text:SetTextColor(1, 1, 1)
		btn:SetBackdropColor(0.6, 0.1, 0.1, 0.9)
		btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
	else
		btn.text:SetText("Sell Marked (0)")
		btn.text:SetTextColor(0.5, 0.5, 0.5)
		btn:SetBackdropColor(0.15, 0.15, 0.15, 0.7)
		btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	end
end

local function ToggleMark(bag, slot)
	if not bag or not slot then return end
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if not info then return end
	local key = MarkKey(bag, slot)
	if markedItems[key] then
		markedItems[key] = nil
	else
		markedItems[key] = true
	end
	RecountMarked()
	C_Timer.After(0, RefreshAllOverlays)
	UpdateSellButton()
end

local function ClearAllMarks()
	wipe(markedItems)
	markedCount = 0
	C_Timer.After(0, RefreshAllOverlays)
	UpdateSellButton()
end

local function SellAllMarked()
	if markedCount == 0 then return end
	if not MerchantFrame or not MerchantFrame:IsShown() then
		KDT:Print("Open a merchant to sell marked items.")
		return
	end
	local sold = 0
	for key in pairs(markedItems) do
		local bag, slot = key:match("^(%d+):(%d+)$")
		bag, slot = tonumber(bag), tonumber(slot)
		if bag and slot then
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info then
				C_Container.UseContainerItem(bag, slot)
				sold = sold + 1
			end
		end
	end
	if sold > 0 then
		KDT:Print(string.format("Sold %d marked item(s).", sold))
	end
	ClearAllMarks()
end

-- Kill every old button from all previous versions
local function NukeOldButtons()
	for _, name in ipairs({
		"KDT_SellMarkedButton",
		"KDT_SellMarkedBtn",
	}) do
		local f = _G[name]
		if f then
			f:Hide()
			f:SetParent(nil)
			f:ClearAllPoints()
			f:UnregisterAllEvents()
			_G[name] = nil
		end
	end
	-- Also kill our own if it exists from a previous init
	if KDT._sellBtn then
		KDT._sellBtn:Hide()
		KDT._sellBtn:SetParent(nil)
		KDT._sellBtn:ClearAllPoints()
		KDT._sellBtn = nil
	end
end

local function CreateSellButton()
	if not MerchantFrame then return end

	-- Anonymous frame - NO global name
	local btn = CreateFrame("Button", nil, MerchantFrame, "BackdropTemplate")
	btn:SetSize(120, 22)
	btn:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 85, 2)
	btn:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	btn:SetBackdropColor(0.15, 0.15, 0.15, 0.7)
	btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	btn:SetFrameStrata("DIALOG")

	btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	btn.text:SetPoint("CENTER", 0, 0)
	btn.text:SetText("Sell Marked (0)")
	btn.text:SetTextColor(0.5, 0.5, 0.5)

	btn:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Sell Marked Items", 1, 1, 1)
		GameTooltip:AddLine(markedCount .. " item(s) marked", 0.7, 0.7, 0.7)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Left-click: Sell all marked", 0.5, 0.8, 0.5)
		GameTooltip:AddLine("Right-click: Clear all marks", 0.8, 0.5, 0.5)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function(self)
		if markedCount > 0 then
			self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
		else
			self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
		end
		GameTooltip:Hide()
	end)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:SetScript("OnClick", function(_, mouseBtn)
		if mouseBtn == "RightButton" then
			ClearAllMarks()
		else
			SellAllMarked()
		end
	end)

	btn:Hide()
	KDT._sellBtn = btn
end

---------------------------------------------------------------------------
-- INIT SELL MARKED
---------------------------------------------------------------------------
local SellMarked = {}
KDT.SellMarked = SellMarked

function SellMarked:Init()
	-- 1) Nuke all old buttons from every previous version
	NukeOldButtons()

	-- 2) Create one fresh anonymous button
	CreateSellButton()

	-- 3) Hook shift-click on bag items via ContainerFrameItemButtonMixin
	-- This is the WoW 12.0 API that was proven working
	if _G.ContainerFrameItemButtonMixin and not KDT._sellClickHooked then
		KDT._sellClickHooked = true
		hooksecurefunc(_G.ContainerFrameItemButtonMixin, "OnModifiedClick", function(self, button)
			local qol = KDT.DB and KDT.DB.qol
			if not qol or not qol.extMerchantEnabled then return end
			if not IsShiftKeyDown() then return end
			local bag = self:GetParent():GetID()
			local slot = self:GetID()
			if bag and slot then
				ToggleMark(bag, slot)
			end
		end)
	end

	-- 4) Hook ContainerFrame_Update for overlay refresh only
	if ContainerFrame_Update and not KDT._sellOverlayHooked then
		KDT._sellOverlayHooked = true
		hooksecurefunc("ContainerFrame_Update", function(frame)
			if not frame or not frame.Items then return end
			local qol = KDT.DB and KDT.DB.qol
			if not qol or not qol.extMerchantEnabled then return end
			C_Timer.After(0, RefreshAllOverlays)
		end)
	end

	-- 5) Merchant show/hide via events
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("MERCHANT_SHOW")
	ev:RegisterEvent("MERCHANT_CLOSED")
	ev:RegisterEvent("BAG_UPDATE_DELAYED")
	ev:SetScript("OnEvent", function(_, event)
		local qol = KDT.DB and KDT.DB.qol
		if not qol or not qol.extMerchantEnabled then return end

		if event == "MERCHANT_SHOW" then
			-- Nuke old ghosts AGAIN just to be safe
			for _, name in ipairs({"KDT_SellMarkedButton", "KDT_SellMarkedBtn"}) do
				local f = _G[name]
				if f then f:Hide(); f:SetParent(nil); _G[name] = nil end
			end
			if not KDT._sellBtn then CreateSellButton() end
			KDT._sellBtn:Show()
			UpdateSellButton()
		elseif event == "MERCHANT_CLOSED" then
			if KDT._sellBtn then KDT._sellBtn:Hide() end
		elseif event == "BAG_UPDATE_DELAYED" then
			C_Timer.After(0, RefreshAllOverlays)
		end
	end)
end

function SellMarked:UpdateButton()
	UpdateSellButton()
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
function KDT:InitExtendedMerchant()
	local qol = self.DB and self.DB.qol
	if not qol then return end
	if qol.extMerchantEnabled then
		self.ExtMerchant:Enable()
		self.SellMarked:Init()
	end
end
