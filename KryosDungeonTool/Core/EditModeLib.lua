local _, addon = ...
if not addon or not addon.EditMode then addon = _G["KryosDungeonTool"] end

-- Shim to expose LibEditModeImproved to the addon namespace
local LibStub = _G.LibStub
assert(LibStub, "KryosDungeonTool requires LibStub to load LibEditModeImproved")

local EditMode = LibStub("LibEQOLEditMode-1.0")

addon.EditModeLib = EditMode
