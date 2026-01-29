-- Kryos Dungeon Tool
-- UI/SlashCommands.lua - Slash command handlers (v1.4 Style)

local addonName, KDT = ...

-- Register slash commands
SLASH_KDT1 = "/kdt"
SLASH_KDT2 = "/kryos"
SLASH_KDT3 = "/kdungeon"

SlashCmdList["KDT"] = function(msg)
    local cmd = msg:lower():match("^%s*(%S*)")
    
    if cmd == "" then
        -- Open Group Check
        if KDT.MainFrame then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("group")
        end
        
    elseif cmd == "bl" or cmd == "blacklist" then
        -- Open Blacklist
        if KDT.MainFrame then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("blacklist")
        end
        
    elseif cmd == "tp" or cmd == "teleport" then
        -- Open Teleports
        if KDT.MainFrame then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("teleport")
        end
        
    elseif cmd == "cd" or cmd == "countdown" then
        -- Start countdown
        KDT:StartCountdown()
        
    elseif cmd == "ready" then
        -- Ready check
        if IsInGroup() then DoReadyCheck() end
        
    elseif cmd == "post" then
        -- Post to chat
        KDT:PostToChat()
        
    elseif cmd == "share" then
        -- Share blacklist
        KDT:ShareBlacklist()
        
    elseif cmd == "debug" then
        -- Debug keystone MapIDs
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        local level = C_MythicPlus.GetOwnedKeystoneLevel()
        if mapID then
            KDT:Print("Your keystone: MapID=" .. mapID .. " Level=" .. (level or "?"))
            KDT:Print("Dungeon name: " .. (KDT:GetDungeonName(mapID) or "UNKNOWN"))
        else
            KDT:Print("No keystone found.")
        end
        
    elseif cmd == "debuggroup" then
        -- Debug group info
        KDT:Print("=== Group Debug ===")
        KDT:Print("IsInGroup: " .. tostring(IsInGroup()))
        KDT:Print("IsInRaid: " .. tostring(IsInRaid()))
        KDT:Print("GetNumGroupMembers: " .. tostring(GetNumGroupMembers()))
        
        -- Check party units
        KDT:Print("--- Party Units ---")
        for i = 1, 4 do
            local unit = "party" .. i
            local exists = UnitExists(unit)
            local name = exists and UnitName(unit) or "N/A"
            KDT:Print(unit .. ": exists=" .. tostring(exists) .. " name=" .. tostring(name))
        end
        
        -- Show GetGroupUnits result
        local units = KDT:GetGroupUnits()
        KDT:Print("--- GetGroupUnits (" .. #units .. ") ---")
        for _, u in ipairs(units) do
            KDT:Print("  " .. u .. " = " .. (UnitName(u) or "?"))
        end
        
        -- Show GetGroupMembers result
        local members = KDT:GetGroupMembers()
        KDT:Print("--- GetGroupMembers (" .. #members .. ") ---")
        for _, m in ipairs(members) do
            KDT:Print("  " .. (m.name or "?") .. " (" .. (m.class or "?") .. ")")
        end
        
    elseif cmd == "debugui" then
        -- Debug UI elements
        KDT:Print("=== UI Debug ===")
        if KDT.MainFrame then
            KDT:Print("MainFrame exists: true")
            KDT:Print("MainFrame shown: " .. tostring(KDT.MainFrame:IsShown()))
            
            local e = KDT.MainFrame.groupElements
            if e then
                KDT:Print("groupElements exists: true")
                KDT:Print("memberContainer exists: " .. tostring(e.memberContainer ~= nil))
                if e.memberContainer then
                    KDT:Print("memberContainer shown: " .. tostring(e.memberContainer:IsShown()))
                    KDT:Print("memberContainer visible: " .. tostring(e.memberContainer:IsVisible()))
                    local w, h = e.memberContainer:GetSize()
                    KDT:Print("memberContainer size: " .. (w or 0) .. " x " .. (h or 0))
                end
            else
                KDT:Print("groupElements exists: false")
            end
            
            KDT:Print("memberRows count: " .. #KDT.MainFrame.memberRows)
            for i, row in ipairs(KDT.MainFrame.memberRows) do
                if row then
                    KDT:Print("  Row " .. i .. ": shown=" .. tostring(row:IsShown()) .. " visible=" .. tostring(row:IsVisible()))
                end
            end
        else
            KDT:Print("MainFrame exists: false")
        end
        
    elseif cmd == "debugtimer" then
        -- Debug timer and forces
        KDT:Print("=== Timer Debug ===")
        local state = KDT.timerState
        KDT:Print("Active: " .. tostring(state.active) .. " | Completed: " .. tostring(state.completed))
        KDT:Print("In Instance: " .. tostring(state.inInstance))
        KDT:Print("Forces: " .. (state.forcesCurrent or 0) .. "/" .. (state.forcesTotal or 0) .. " (" .. string.format("%.2f", state.forcesPercent or 0) .. "%)")
        KDT:Print("Deaths: " .. (state.deaths or 0) .. " | Death Log: " .. #(state.deathLog or {}))
        
        -- Debug scenario info
        if C_ChallengeMode.IsChallengeModeActive() then
            -- Get numCriteria via C_Scenario.GetStepInfo (MPlusTimer method)
            local numCriteria = 0
            if C_Scenario and C_Scenario.GetStepInfo then
                local _, _, num = C_Scenario.GetStepInfo()
                numCriteria = num or 0
                KDT:Print("C_Scenario.GetStepInfo numCriteria: " .. numCriteria)
            end
            
            KDT:Print("--- Criteria Details ---")
            for i = 1, numCriteria do
                if C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
                    local info = C_ScenarioInfo.GetCriteriaInfo(i)
                    if info then
                        KDT:Print(i .. ": desc=" .. (info.description or "?"))
                        KDT:Print("   qty=" .. tostring(info.quantity) .. " total=" .. tostring(info.totalQuantity))
                        KDT:Print("   qtyStr='" .. tostring(info.quantityString) .. "' weighted=" .. tostring(info.isWeighted))
                        KDT:Print("   completed=" .. tostring(info.completed))
                    end
                end
            end
        else
            KDT:Print("Not in M+")
        end
        
    elseif cmd == "history" then
        -- Show run history
        local history = KDT:GetRunHistory()
        if #history == 0 then
            KDT:Print("No runs recorded yet.")
        else
            KDT:Print("=== Recent Runs ===")
            for i, run in ipairs(history) do
                local status = run.upgrade > 0 and ("+" .. run.upgrade) or "Depleted"
                KDT:Print(string.format("%d. [%s] +%d %s - %s / %s", 
                    i, status, run.level or 0, run.dungeon or "?", 
                    KDT:FormatTime(run.time), KDT:FormatTime(run.timeLimit)))
            end
        end
    
    elseif cmd == "saverun" then
        -- Manually save current run to history
        local state = KDT.timerState
        if state.dungeonName and state.dungeonName ~= "" and state.level > 0 then
            state.completed = true
            if state.completedTime == 0 then
                state.completedTime = state.elapsed
            end
            KDT:SaveRunToHistory()
        else
            KDT:Print("No active M+ run to save.")
        end
        
    elseif cmd == "timer" then
        -- Open Timer settings
        if KDT.MainFrame then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("timer")
        end
        
    elseif cmd == "help" then
        KDT:Print("Commands:")
        KDT:Print("  /kdt - Open Group Check")
        KDT:Print("  /kdt bl - Open Blacklist")
        KDT:Print("  /kdt tp - Open Teleports")
        KDT:Print("  /kdt timer - Open Timer settings")
        KDT:Print("  /kdt history - Show run history")
        KDT:Print("  /kdt saverun - Manually save current run")
        KDT:Print("  /kdt cd - Start countdown")
        KDT:Print("  /kdt ready - Ready check")
        KDT:Print("  /kdt post - Post group to chat")
        KDT:Print("  /kdt share - Share blacklist")
        KDT:Print("  /kdt debug - Debug keystone MapIDs")
        KDT:Print("  /kdt debugtimer - Debug timer/forces info")
        
    else
        KDT:Print("Unknown command. Type /kdt help")
    end
end
