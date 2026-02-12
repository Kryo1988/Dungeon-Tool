-- Kryos Dungeon Tool
-- Modules/ActionBarTweaks.lua - Action bar keybind shortening, hotkey visibility, range coloring

local _, KDT = ...

local ABTweaks = {}
KDT.ActionBarTweaks = ABTweaks

local NUM_BUTTONS = _G.NUM_ACTIONBAR_BUTTONS or 12
local NUM_PET = _G.NUM_PET_ACTION_SLOTS or 10
local NUM_STANCE = _G.NUM_STANCE_SLOTS or _G.NUM_SHAPESHIFT_SLOTS or 10

---------------------------------------------------------------------------
-- HOTKEY SHORTENING
---------------------------------------------------------------------------
local HOTKEY_REPLACEMENTS = {
    { "MOUSE WHEEL DOWN", "MWD" },
    { "MOUSE WHEEL UP", "MWU" },
    { "MOUSE WHEEL", "MW" },
    { "MOUSE BUTTON", "M" },
    { "MOUSEBUTTON", "M" },
    { "BUTTON", "M" },
    { "NUM PAD ", "N" },
    { "NUMPAD", "N" },
    { "PAGEUP", "PU" },
    { "PAGEDOWN", "PD" },
    { "SPACEBAR", "SP" },
    { "BACKSPACE", "BS" },
    { "DELETE", "DEL" },
    { "INSERT", "INS" },
    { "HOME", "HM" },
    { "ARROW", "" },
    { "CAPSLOCK", "CAPS" },
}

local function ShortenHotkeyText(text)
    if type(text) ~= "string" or text == "" then return text end
    if _G.RANGE_INDICATOR and text == _G.RANGE_INDICATOR then return text end
    local isMinus = text:sub(-1) == "-"
    local short = text:upper()
    -- Modifier keys
    short = short:gsub("CTRL%-", "C")
    short = short:gsub("CONTROL%-", "C")
    short = short:gsub("ALT%-", "A")
    short = short:gsub("SHIFT%-", "S")
    short = short:gsub("OPTION%-", "O")
    short = short:gsub("COMMAND%-", "CM")
    -- Localized modifiers
    local shift = _G.SHIFT_KEY_TEXT
    if shift and shift ~= "" then short = short:gsub(shift:upper() .. "%-", "S") end
    local ctrl = _G.CTRL_KEY_TEXT
    if ctrl and ctrl ~= "" then short = short:gsub(ctrl:upper() .. "%-", "C") end
    local alt = _G.ALT_KEY_TEXT
    if alt and alt ~= "" then short = short:gsub(alt:upper() .. "%-", "A") end
    -- Mouse and special keys
    for _, repl in ipairs(HOTKEY_REPLACEMENTS) do
        short = short:gsub(repl[1], repl[2])
    end
    short = short:gsub("PLUS", "+")
    short = short:gsub("MINUS", "-")
    short = short:gsub("[%s%-]", "")
    if isMinus then short = short .. "-" end
    return short
end

---------------------------------------------------------------------------
-- BUTTON ITERATION
---------------------------------------------------------------------------
local BAR_INFO = {
    { prefix = "ActionButton",       count = NUM_BUTTONS },
    { prefix = "MultiBarBottomLeftButton",  count = NUM_BUTTONS },
    { prefix = "MultiBarBottomRightButton", count = NUM_BUTTONS },
    { prefix = "MultiBarRightButton",       count = NUM_BUTTONS },
    { prefix = "MultiBarLeftButton",        count = NUM_BUTTONS },
    { prefix = "MultiBar5Button",           count = NUM_BUTTONS },
    { prefix = "MultiBar6Button",           count = NUM_BUTTONS },
    { prefix = "MultiBar7Button",           count = NUM_BUTTONS },
    { prefix = "PetActionButton",    count = NUM_PET },
    { prefix = "StanceButton",       count = NUM_STANCE },
}

local function ForEachButton(callback)
    for _, info in ipairs(BAR_INFO) do
        for i = 1, info.count do
            local btn = _G[info.prefix .. i]
            if btn then callback(btn, info.prefix) end
        end
    end
end

---------------------------------------------------------------------------
-- HOTKEY FUNCTIONS
---------------------------------------------------------------------------
local function GetHotkey(btn)
    if btn.HotKey then return btn.HotKey end
    if btn.GetName then return _G[btn:GetName() .. "HotKey"] end
    return nil
end

local function ApplyHotkeyStyling(btn)
    local qol = KDT.DB and KDT.DB.qol
    if not qol then return end
    local hotkey = GetHotkey(btn)
    if not hotkey then return end

    -- Shorten
    if qol.actionBarShortenHotkeys then
        local text = hotkey:GetText()
        if not text or text == "" then return end
        if not hotkey.KDT_OriginalText or hotkey.KDT_OriginalText ~= text then
            if not hotkey.KDT_ShortApplied then hotkey.KDT_OriginalText = text end
        end
        local base = hotkey.KDT_OriginalText or text
        local shortened = ShortenHotkeyText(base)
        if shortened and shortened ~= hotkey:GetText() then
            hotkey:SetText(shortened)
            hotkey.KDT_ShortApplied = true
        end
    else
        if hotkey.KDT_ShortApplied and hotkey.KDT_OriginalText then
            hotkey:SetText(hotkey.KDT_OriginalText)
        end
        hotkey.KDT_ShortApplied = nil
    end
end

---------------------------------------------------------------------------
-- RANGE COLORING OVERLAY
---------------------------------------------------------------------------
local function EnsureRangeOverlay(btn)
    if btn.KDT_RangeOverlay then return btn.KDT_RangeOverlay end
    local icon = btn.icon or btn.Icon
    if not icon then return nil end
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    overlay:Hide()
    btn.KDT_RangeOverlay = overlay
    return overlay
end

local function ShowRangeOverlay(btn, show)
    local qol = KDT.DB and KDT.DB.qol
    if not qol or not qol.actionBarRangeColoring then
        if btn.KDT_RangeOverlay then btn.KDT_RangeOverlay:Hide() end
        return
    end
    local overlay = EnsureRangeOverlay(btn)
    if not overlay then return end
    if show then
        overlay:SetColorTexture(1, 0.1, 0.1, 0.45)
        overlay:Show()
    else
        overlay:Hide()
    end
end

---------------------------------------------------------------------------
-- HOOKS
---------------------------------------------------------------------------
local hotkeyHooked = false
local rangeHooked = false

local function InstallHotkeyHook()
    if hotkeyHooked then return end
    if ActionBarActionButtonMixin and type(ActionBarActionButtonMixin.UpdateHotkeys) == "function" then
        hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", ApplyHotkeyStyling)
        hotkeyHooked = true
    end
end

local function InstallRangeHook()
    if rangeHooked then return end
    if ActionButton_UpdateRangeIndicator then
        hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checksRange, inRange)
            if not self or not self.action then return end
            if checksRange and inRange == false then
                ShowRangeOverlay(self, true)
            else
                ShowRangeOverlay(self, false)
            end
        end)
        rangeHooked = true
    end
    -- Also hook UpdateUsable for persistent OOR coloring
    if ActionBarActionButtonMixin and ActionBarActionButtonMixin.UpdateUsable then
        hooksecurefunc(ActionBarActionButtonMixin, "UpdateUsable", function(self)
            local qol = KDT.DB and KDT.DB.qol
            if not qol or not qol.actionBarRangeColoring then return end
            if self.KDT_RangeOutOfRange then
                ShowRangeOverlay(self, true)
            else
                ShowRangeOverlay(self, false)
            end
        end)
    end
end

---------------------------------------------------------------------------
-- REFRESH
---------------------------------------------------------------------------
function ABTweaks:RefreshAllHotkeys()
    ForEachButton(function(btn) ApplyHotkeyStyling(btn) end)
end

function ABTweaks:RefreshAllRangeOverlays()
    ForEachButton(function(btn)
        local qol = KDT.DB and KDT.DB.qol
        if not qol or not qol.actionBarRangeColoring then
            if btn.KDT_RangeOverlay then btn.KDT_RangeOverlay:Hide() end
        end
    end)
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
function KDT:InitActionBarTweaks()
    InstallHotkeyHook()
    InstallRangeHook()
    C_Timer.After(0.5, function()
        ABTweaks:RefreshAllHotkeys()
    end)
end

-- Fallback hook install on PLAYER_LOGIN
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    InstallHotkeyHook()
    InstallRangeHook()
    self:UnregisterEvent("PLAYER_LOGIN")
end)
