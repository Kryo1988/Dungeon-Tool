-- Kryos Dungeon Tool
-- Modules/CharPanel.lua - Character Panel: iLvl, Enchant & Socket Overlay
-- Approach based on ElvUI's InfoItemLevel: tooltip texture scanning for gems,
-- simple textures on slot buttons for rendering
-- WoW 12.0 compatible

local _, KDT = ...

local CreateFrame = CreateFrame
local GetInventoryItemLink = GetInventoryItemLink
local GameTooltip = GameTooltip
local pcall, pairs, ipairs = pcall, pairs, ipairs
local strmatch, strsplit = string.match, strsplit
local tonumber, tinsert, wipe = tonumber, table.insert, wipe

local FONT = "Fonts\\FRIZQT__.TTF"
local ILVL_SIZE = 12
local ENCH_SIZE = 9
local GEM_SZ = 14
local MAX_GEMS = 4

local function GetQoL() return KDT.DB and KDT.DB.qol end
local function isSecret(v) return _G.issecretvalue and _G.issecretvalue(v) end

local function StripMarkup(text)
    if not text then return nil end
    text = text:gsub("|A:[^|]+|a", "")
    text = text:gsub("|T[^|]+|t", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|n", " ")
    text = text:gsub("%s+", " ")
    return text:match("^%s*(.-)%s*$")
end

-- Forward declaration
local UpdateAll

---------------------------------------------------------------------------
-- SCAN TOOLTIP (hidden, for gem texture extraction)
---------------------------------------------------------------------------
local scanTT = CreateFrame("GameTooltip", "KDTCharPanelScanTT", _G.WorldFrame, "GameTooltipTemplate")
scanTT:SetOwner(_G.WorldFrame, "ANCHOR_NONE")

---------------------------------------------------------------------------
-- SLOT TABLE
---------------------------------------------------------------------------
local SLOTS = {
    { id=1,  btn="CharacterHeadSlot",          side="left",  ench=false },
    { id=2,  btn="CharacterNeckSlot",           side="left",  ench=false },
    { id=3,  btn="CharacterShoulderSlot",       side="left",  ench=false },
    { id=15, btn="CharacterBackSlot",           side="left",  ench=true  },
    { id=5,  btn="CharacterChestSlot",          side="left",  ench=true  },
    { id=9,  btn="CharacterWristSlot",          side="left",  ench=true  },
    { id=10, btn="CharacterHandsSlot",          side="right", ench=false },
    { id=6,  btn="CharacterWaistSlot",          side="right", ench=false },
    { id=7,  btn="CharacterLegsSlot",           side="right", ench=true  },
    { id=8,  btn="CharacterFeetSlot",           side="right", ench=true  },
    { id=11, btn="CharacterFinger0Slot",        side="right", ench=true  },
    { id=12, btn="CharacterFinger1Slot",        side="right", ench=true  },
    { id=13, btn="CharacterTrinket0Slot",       side="right", ench=false },
    { id=14, btn="CharacterTrinket1Slot",       side="right", ench=false },
    { id=16, btn="CharacterMainHandSlot",       side="mh",    ench=true  },
    { id=17, btn="CharacterSecondaryHandSlot",  side="oh",    ench=true  },
}

---------------------------------------------------------------------------
-- ITEM LEVEL
---------------------------------------------------------------------------
local function GetItemLevel(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link or isSecret(link) then return nil end
    if C_Item and C_Item.GetCurrentItemLevel then
        local ok, ilvl = pcall(function()
            local loc = ItemLocation:CreateFromEquipmentSlot(slotID)
            if loc and C_Item.DoesItemExist(loc) then return C_Item.GetCurrentItemLevel(loc) end
        end)
        if ok and ilvl and not isSecret(ilvl) and ilvl > 0 then return ilvl end
    end
    return nil
end

local function GetItemQualityRGB(slotID)
    if C_Item and C_Item.GetItemQuality then
        local ok, q = pcall(function()
            local loc = ItemLocation:CreateFromEquipmentSlot(slotID)
            if loc and C_Item.DoesItemExist(loc) then return C_Item.GetItemQuality(loc) end
        end)
        if ok and q and not isSecret(q) and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
            local c = ITEM_QUALITY_COLORS[q]
            return c.r, c.g, c.b
        end
    end
    return 1, 1, 1
end

---------------------------------------------------------------------------
-- ENCHANT DETECTION (name, not stats)
---------------------------------------------------------------------------
local function GetEnchantInfo(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link or isSecret(link) then return false, nil end

    -- Check enchantID in link
    local s = strmatch(link, "item:([%-?%d:]+)")
    if not s then return false, nil end
    local p = { strsplit(":", s) }
    local enchantID = tonumber(p[2]) or 0
    if enchantID == 0 then return false, nil end

    -- Get enchant name from tooltip
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local ok, td = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
        if ok and td and td.lines then
            if TooltipUtil and TooltipUtil.SurfaceArgs then pcall(TooltipUtil.SurfaceArgs, td) end
            for _, line in pairs(td.lines) do
                if TooltipUtil and TooltipUtil.SurfaceArgs and line then pcall(TooltipUtil.SurfaceArgs, line) end
                local txt = line and line.leftText
                if txt and not isSecret(txt) then
                    local name = strmatch(txt, "^Enchanted:%s*(.+)")
                              or strmatch(txt, "^Verzaubert:%s*(.+)")
                              or strmatch(txt, "^Enchanté[e]?:%s*(.+)")
                              or strmatch(txt, "^Encantado:%s*(.+)")
                    if name then return true, StripMarkup(name) end
                end
            end
        end
    end
    return true, nil -- has enchant but couldn't get name
end

---------------------------------------------------------------------------
-- GEM TEXTURES FROM TOOLTIP (ElvUI approach)
-- Scans tooltip texture regions to get gem icons, bypasses secret values
---------------------------------------------------------------------------
local function ScanGemTextures(slotID)
    local gems = {}

    scanTT:SetOwner(_G.WorldFrame, "ANCHOR_NONE")
    local ok = pcall(scanTT.SetInventoryItem, scanTT, "player", slotID)
    if not ok then return gems end

    -- WoW auto-creates texture regions on GameTooltips for gem icons
    -- Named: KDTCharPanelScanTTTexture1, KDTCharPanelScanTTTexture2, etc.
    for i = 1, 10 do
        local tex = _G["KDTCharPanelScanTTTexture" .. i]
        if tex and tex:IsShown() then
            local texture = tex:GetTexture()
            if texture and not isSecret(texture) then
                tinsert(gems, texture)
            end
        end
    end

    scanTT:ClearLines()
    return gems
end

-- Also detect empty sockets via tooltip text
local function CountEmptySockets(slotID)
    local count = 0
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then return 0 end
    local ok, td = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
    if not ok or not td or not td.lines then return 0 end
    if TooltipUtil and TooltipUtil.SurfaceArgs then pcall(TooltipUtil.SurfaceArgs, td) end
    for _, line in pairs(td.lines) do
        if TooltipUtil and TooltipUtil.SurfaceArgs and line then pcall(TooltipUtil.SurfaceArgs, line) end
        local txt = line and line.leftText
        if txt and not isSecret(txt) then
            if txt:find("Empty Socket") or txt:find("Leerer Sockel")
            or txt:find("Prismatic Socket") or txt:find("Prismatischer Sockel")
            or txt:find("Châsse vide") or txt:find("Engaste vacío") then
                count = count + 1
            end
        end
    end
    return count
end

---------------------------------------------------------------------------
-- OVERLAY SETUP (per slot)
---------------------------------------------------------------------------
local store = {}

-- Returns anchor info: xOff, yOff, gemStartY, justify
-- Matches ElvUI GetInspectPoints logic
local function GetSlotPoints(slotInfo)
    local side = slotInfo.side
    if side == "left" then
        return 40, 3, 18, "BOTTOMLEFT"
    elseif side == "right" then
        return -40, 3, 18, "BOTTOMRIGHT"
    else
        return 0, 45, 60, "BOTTOM"
    end
end

local function EnsureOverlay(slotInfo)
    local button = _G[slotInfo.btn]
    if not button then return nil end
    if store[slotInfo.id] then return store[slotInfo.id] end

    local ov = {}
    local x, y, gemY, justify = GetSlotPoints(slotInfo)

    -- iLvl text: directly on slot, OVERLAY layer (like ElvUI)
    ov.iLvlText = button:CreateFontString(nil, "OVERLAY")
    ov.iLvlText:SetFont(FONT, ILVL_SIZE, "OUTLINE")
    ov.iLvlText:SetShadowOffset(1, -1)
    ov.iLvlText:SetShadowColor(0, 0, 0, 1)
    ov.iLvlText:SetPoint("BOTTOM", button, x, y)

    -- Enchant text: on slot, positioned above iLvl
    ov.enchantText = button:CreateFontString(nil, "OVERLAY")
    ov.enchantText:SetFont(FONT, ENCH_SIZE, "OUTLINE")
    ov.enchantText:SetShadowOffset(1, -1)
    ov.enchantText:SetShadowColor(0, 0, 0, 1)

    local side = slotInfo.side
    if side == "mh" then
        ov.enchantText:SetPoint("BOTTOMRIGHT", button, -40, 3)
    elseif side == "oh" then
        ov.enchantText:SetPoint("BOTTOMLEFT", button, 40, 3)
    else
        ov.enchantText:SetPoint(justify, button, x + (justify == "BOTTOMLEFT" and 5 or -5), gemY)
    end

    -- Gem textures + backdrop frames
    -- Anchored RELATIVE to iLvlText to avoid overlap regardless of text width
    ov.gems = {}
    for i = 1, MAX_GEMS do
        local isWeapon = (side == "mh" or side == "oh")
        local gemOff = (i - 1) * (GEM_SZ + 2)

        -- The gem texture (simple texture on the slot, like ElvUI)
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tex:SetSize(GEM_SZ, GEM_SZ)

        if isWeapon then
            -- Weapons: gems horizontal, right of ilvl
            tex:SetPoint("LEFT", ov.iLvlText, "RIGHT", 2 + gemOff, 0)
        elseif justify == "BOTTOMLEFT" then
            -- Left side: gems to the right of ilvl number
            tex:SetPoint("LEFT", ov.iLvlText, "RIGHT", 2 + gemOff, 0)
        else
            -- Right side: gems to the left of ilvl number
            tex:SetPoint("RIGHT", ov.iLvlText, "LEFT", -(2 + gemOff), 0)
        end

        -- Backdrop frame for border (optional visual)
        local bd = CreateFrame("Frame", nil, button, "BackdropTemplate")
        bd:SetPoint("TOPLEFT", tex, -1, 1)
        bd:SetPoint("BOTTOMRIGHT", tex, 1, -1)
        bd:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        bd:SetBackdropColor(0, 0, 0, 0.5)
        bd:SetBackdropBorderColor(0, 0, 0, 0.8)
        bd:Hide()

        -- Clickable overlay for tooltip (invisible frame on top)
        local hover = CreateFrame("Frame", nil, button)
        hover:SetAllPoints(tex)
        hover:SetFrameLevel(button:GetFrameLevel() + 5)
        hover:EnableMouse(true)
        hover:SetScript("OnEnter", function(self)
            if self.gemItemID and self.gemItemID > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(self.gemItemID)
            elseif self.isEmpty then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Empty Socket", 1.0, 0.3, 0.3)
                GameTooltip:Show()
            end
        end)
        hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
        hover:Hide()

        ov.gems[i] = { tex = tex, bd = bd, hover = hover }
    end

    store[slotInfo.id] = ov
    return ov
end

---------------------------------------------------------------------------
-- HIDE ALL ELEMENTS FOR A SLOT
---------------------------------------------------------------------------
local function HideSlot(ov)
    if not ov then return end
    ov.iLvlText:SetText("")
    ov.iLvlText:Hide()
    ov.enchantText:SetText("")
    ov.enchantText:Hide()
    for i = 1, MAX_GEMS do
        local g = ov.gems[i]
        if g then
            g.tex:SetTexture(nil)
            g.tex:Hide()
            g.bd:Hide()
            g.hover:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- UPDATE SINGLE SLOT
---------------------------------------------------------------------------
local function UpdateSlot(slotInfo)
    local qol = GetQoL()
    if not qol or not qol.charPanelEnabled then return end
    local ov = EnsureOverlay(slotInfo)
    if not ov then return end

    local link = GetInventoryItemLink("player", slotInfo.id)
    if not link or isSecret(link) then
        HideSlot(ov)
        return
    end

    -- iLvl
    if qol.charPanelShowIlvl ~= false then
        local ilvl = GetItemLevel(slotInfo.id)
        if ilvl then
            local r, g, b = GetItemQualityRGB(slotInfo.id)
            ov.iLvlText:SetText(ilvl)
            ov.iLvlText:SetTextColor(r, g, b, 1)
            ov.iLvlText:Show()
        else
            ov.iLvlText:Hide()
        end
    else
        ov.iLvlText:Hide()
    end

    -- Enchant
    if qol.charPanelShowEnchant ~= false and slotInfo.ench then
        local hasEnch, enchName = GetEnchantInfo(slotInfo.id)
        if hasEnch then
            if enchName and #enchName > 24 then enchName = enchName:sub(1, 22) .. ".." end
            ov.enchantText:SetText(enchName or "Enchanted")
            ov.enchantText:SetTextColor(0.0, 1.0, 0.0, 0.9)
            ov.enchantText:Show()
        else
            ov.enchantText:SetText("No Enchant")
            ov.enchantText:SetTextColor(1.0, 0.3, 0.3, 0.9)
            ov.enchantText:Show()
        end
    else
        ov.enchantText:Hide()
    end

    -- Gems (tooltip texture scan + empty socket detection)
    if qol.charPanelShowSockets ~= false then
        local gemTextures = ScanGemTextures(slotInfo.id)
        local numEmpty = CountEmptySockets(slotInfo.id)
        local idx = 0

        -- Parse item link for gem item IDs (for tooltip hover)
        local gemItemIDs = {}
        local s = strmatch(link, "item:([%-?%d:]+)")
        if s then
            local p = { strsplit(":", s) }
            for pi = 3, 6 do
                local gid = tonumber(p[pi]) or 0
                if gid > 0 then tinsert(gemItemIDs, gid) end
            end
        end

        -- Filled gems (with textures from tooltip scan)
        for gi, texID in ipairs(gemTextures) do
            idx = idx + 1
            if idx <= MAX_GEMS then
                local g = ov.gems[idx]
                g.tex:SetTexture(texID)
                g.tex:Show()
                g.bd:Show()
                g.hover.gemItemID = gemItemIDs[gi] or 0
                g.hover.isEmpty = false
                g.hover:Show()
            end
        end

        -- Empty sockets
        for _ = 1, numEmpty do
            idx = idx + 1
            if idx <= MAX_GEMS then
                local g = ov.gems[idx]
                g.tex:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
                g.tex:SetDesaturated(true)
                g.tex:SetVertexColor(0.5, 0.15, 0.15, 0.9)
                g.tex:Show()
                g.bd:Show()
                g.hover.gemItemID = nil
                g.hover.isEmpty = true
                g.hover:Show()
            end
        end

        -- Hide unused
        for i = idx + 1, MAX_GEMS do
            local g = ov.gems[i]
            g.tex:SetTexture(nil)
            g.tex:Hide()
            g.bd:Hide()
            g.hover:Hide()
        end

        -- Reset desaturation for filled gems
        for gi = 1, #gemTextures do
            if gi <= MAX_GEMS then
                ov.gems[gi].tex:SetDesaturated(false)
                ov.gems[gi].tex:SetVertexColor(1, 1, 1, 1)
            end
        end
    else
        for i = 1, MAX_GEMS do
            local g = ov.gems[i]
            g.tex:SetTexture(nil)
            g.tex:Hide()
            g.bd:Hide()
            g.hover:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- UPDATE ALL
---------------------------------------------------------------------------
UpdateAll = function()
    local qol = GetQoL()
    if not qol or not qol.charPanelEnabled then
        for _, ov in pairs(store) do
            HideSlot(ov)
        end
        return
    end
    for _, slot in ipairs(SLOTS) do
        UpdateSlot(slot)
    end
end

---------------------------------------------------------------------------
-- HOOKS
---------------------------------------------------------------------------
local hooked = false

local function HookCharFrame()
    if hooked then return end
    local cf = _G.CharacterFrame
    if not cf then return end
    cf:HookScript("OnShow", function() C_Timer.After(0.15, UpdateAll) end)
    local ef = CreateFrame("Frame")
    ef:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    ef:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
    ef:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    ef:SetScript("OnEvent", function()
        if cf:IsShown() then C_Timer.After(0.25, UpdateAll) end
    end)
    local pd = _G.PaperDollFrame
    if pd and pd.HookScript then
        pd:HookScript("OnShow", function() C_Timer.After(0.15, UpdateAll) end)
    end
    hooked = true
end

local initF = CreateFrame("Frame")
initF:RegisterEvent("PLAYER_ENTERING_WORLD")
initF:SetScript("OnEvent", function(self)
    if _G.CharacterFrame then
        HookCharFrame()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    pcall(EventUtil.ContinueOnAddOnLoaded, "Blizzard_CharacterFrame", HookCharFrame)
end

if not _G.CharacterFrame and _G.ToggleCharacter then
    pcall(hooksecurefunc, "ToggleCharacter", function()
        if not hooked and _G.CharacterFrame then
            HookCharFrame()
            C_Timer.After(0.2, UpdateAll)
        end
    end)
end

---------------------------------------------------------------------------
-- PUBLIC
---------------------------------------------------------------------------
function KDT:UpdateCharPanel() UpdateAll() end
function KDT:RefreshCharPanel()
    if _G.CharacterFrame and _G.CharacterFrame:IsShown() then UpdateAll() end
end
