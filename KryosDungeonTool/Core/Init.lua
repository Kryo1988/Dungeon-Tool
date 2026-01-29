-- Kryos Dungeon Tool
-- Core/Init.lua - Final initialization

local addonName, KDT = ...

-- Global reference
KryosDungeonTool = KDT

-- Default tab on first show (delayed to ensure everything is set up)
if KDT.MainFrame and KDT.MainFrame.SwitchTab then
    KDT.MainFrame:SwitchTab("group")
end
