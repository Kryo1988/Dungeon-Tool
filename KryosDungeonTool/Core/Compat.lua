-- KryosDungeonTool Compatibility Layer
-- Bridges KDT namespace for ported EnhanceQoL modules
-- Must load AFTER Core.lua but BEFORE any ported modules

local addonName, KDT = ...

-- Expose addon table globally so ported modules can access it
_G["KryosDungeonTool"] = KDT

-- Alias: ported files use addon.db, KDT uses KDT.DB
-- This will be set properly after ADDON_LOADED in Init.lua
-- For now just ensure the namespaces exist
KDT.functions = KDT.functions or {}
KDT.Aura = KDT.Aura or {}

-- Provide InitDBValue helper (used by ported Init files)
function KDT.functions.InitDBValue(key, defaultValue)
    if not KDT.DB then return end
    if KDT.DB[key] == nil then KDT.DB[key] = defaultValue end
end

-- Simple L table: returns key as fallback (no localization needed for English)
-- AceLocale will override this for modules that use it
KDT.L = KDT.L or setmetatable({}, {
    __index = function(_, key) return key end,
    __newindex = rawset,
})

-- Provide addon.variables fallback (used by DataPanel for default font)
KDT.variables = KDT.variables or {}

-- Provide formatMoney helper (used by Stream_Gold)
function KDT.functions.formatMoney(amount, style)
    if not amount or amount == 0 then return "0g" end
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100
    if gold > 0 then
        return string.format("%dg %ds %dc", gold, silver, copper)
    elseif silver > 0 then
        return string.format("%ds %dc", silver, copper)
    else
        return string.format("%dc", copper)
    end
end

-- Provide IsTimerunner helper (used by Stream_Durability)
function KDT.functions.IsTimerunner()
    local fn = _G and _G.PlayerGetTimerunningSeasonID
    if type(fn) == "function" then return fn() ~= nil end
    return false
end

-- AceGUI container helper (used by Stream tooltips)
-- Returns nil gracefully if AceGUI not available
function KDT.functions.createContainer(containerType, layout)
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
    if not AceGUI then return nil end
    local container = AceGUI:Create(containerType)
    if container and layout then container:SetLayout(layout) end
    return container
end
