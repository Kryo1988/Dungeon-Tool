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
        
    elseif cmd == "meter" then
        -- Damage meter commands
        local arg = msg:lower():match("^%s*%S+%s+(%S+)")
        if arg == "reset" or arg == "clearall" then
            KDT.Meter:ResetAll()
            KDT:Print("All DMG Meter data cleared.")
        elseif arg == "clear" then
            KDT.Meter:ClearCurrent()
            KDT:Print("Current segment cleared.")
        elseif arg == "toggle" or arg == "window" then
            KDT.Meter:ToggleWindow(1)
        elseif arg == "new" then
            local id = #KDT.Meter.windows + 1
            local window = KDT.Meter:CreateWindow(id)
            window:Show()
            KDT:Print("Created new DMG Meter window #" .. id)
        elseif arg == "hide" then
            KDT.Meter:HideAllWindows()
        elseif arg == "show" then
            KDT.Meter:ShowAllWindows()
        elseif arg == "lock" then
            -- Toggle lock on first window (syncs to all)
            if KDT.Meter.windows[1] then
                KDT.Meter.windows[1]:ToggleLock()
            else
                KDT:Print("No DMG Meter window open")
            end
        elseif arg == "debug" then
            local _, _, _, buildInfo = GetBuildInfo()
            local isMidnight = buildInfo >= 120000
            KDT:Print("=== Meter Debug ===")
            KDT:Print("WoW build: " .. tostring(buildInfo) .. " (Midnight: " .. tostring(isMidnight) .. ")")
            KDT:Print("inCombat: " .. tostring(KDT.Meter.inCombat) .. ", UnitAffectingCombat: " .. tostring(UnitAffectingCombat("player")))
            KDT:Print("processCount: " .. tostring(KDT.Meter.processCount or 0))
            KDT:Print("segments: " .. tostring(#KDT.Meter.segments))
            
            if KDT.Meter.currentSegment then
                local pCount = 0
                for name, player in pairs(KDT.Meter.currentSegment.players) do
                    pCount = pCount + 1
                    KDT:Print("  - " .. tostring(name) .. ": " .. tostring(player.damage) .. " dmg")
                end
                KDT:Print("players: " .. pCount .. ", totalDmg: " .. tostring(KDT.Meter.currentSegment.totalDamage or 0))
            else
                KDT:Print("currentSegment: nil")
            end
            
            if isMidnight and C_DamageMeter then
                KDT:Print("--- C_DamageMeter API ---")
                
                -- Get available sessions
                local sessions = C_DamageMeter.GetAvailableCombatSessions()
                if sessions then
                    KDT:Print("Available sessions: " .. #sessions)
                    for i, s in ipairs(sessions) do
                        KDT:Print("  Session " .. i .. ": ID=" .. tostring(s.sessionID) .. ", name=" .. tostring(s.name or "nil"))
                    end
                end
                
                -- Try both methods
                local sessionId = sessions and #sessions > 0 and sessions[#sessions].sessionID or nil
                
                if sessionId then
                    KDT:Print("Using sessionID: " .. tostring(sessionId))
                    local session = C_DamageMeter.GetCombatSessionFromID(sessionId, Enum.DamageMeterType.DamageDone)
                    if session and session.combatSources then
                        KDT:Print("FromID sources: " .. #session.combatSources)
                        for i, src in ipairs(session.combatSources) do
                            local nameStr = (src.isLocalPlayer and UnitName("player") .. " (self)") or (not issecretvalue or not issecretvalue(src.name)) and tostring(src.name) or "SECRET"
                            local dmgStr = (not issecretvalue or not issecretvalue(src.totalAmount)) and tostring(src.totalAmount) or "SECRET"
                            KDT:Print("  " .. i .. ". " .. nameStr .. ": " .. dmgStr)
                        end
                    end
                end
                
                -- Also try Type method for comparison
                local sessionType = C_DamageMeter.GetCombatSessionFromType(Enum.DamageMeterSessionType.Current, Enum.DamageMeterType.DamageDone)
                if sessionType and sessionType.combatSources then
                    KDT:Print("FromType sources: " .. #sessionType.combatSources)
                end
            end
        elseif arg == "test" then
            -- Force add test data
            if not KDT.Meter.currentSegment then
                KDT.Meter:StartCombat("Test Combat")
            end
            local testName = UnitName("player")
            local _, testClass = UnitClass("player")
            local player = KDT.Meter:GetOrCreatePlayer(KDT.Meter.currentSegment, testName, testClass)
            if player then
                player.damage = player.damage + 10000
                KDT.Meter.currentSegment.totalDamage = KDT.Meter.currentSegment.totalDamage + 10000
                KDT:Print("Added 10k test damage for " .. tostring(testName))
                KDT.Meter:RefreshAllWindows()
            else
                KDT:Print("Failed to create test player")
            end
        elseif arg == "cltest" then
            -- Test if combat log events are being received
            KDT:Print("Starting combat log monitor for 10 seconds...")
            KDT.Meter.debugMode = true
            C_Timer.After(10, function()
                KDT.Meter.debugMode = false
                KDT:Print("Combat log monitor stopped. processCount: " .. tostring(KDT.Meter.processCount or 0))
            end)
        else
            -- Toggle main window or open settings
            KDT.Meter:ToggleWindow(1)
        end
        
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
        
    elseif cmd == "debugtimer" then
        -- Debug timer state
        KDT:Print("=== Timer Debug ===")
        local state = KDT.timerState
        KDT:Print("state.active: " .. tostring(state.active))
        KDT:Print("state.completed: " .. tostring(state.completed))
        KDT:Print("state.elapsed: " .. tostring(state.elapsed))
        KDT:Print("state.completedTime: " .. tostring(state.completedTime))
        KDT:Print("state.timeLimit: " .. tostring(state.timeLimit))
        KDT:Print("state.dungeonName: " .. tostring(state.dungeonName))
        KDT:Print("state.level: " .. tostring(state.level))
        KDT:Print("state.mapID: " .. tostring(state.mapID))
        KDT:Print("state.forcesPercent: " .. tostring(state.forcesPercent))
        KDT:Print("state.forcesCurrent: " .. tostring(state.forcesCurrent))
        KDT:Print("state.forcesTotal: " .. tostring(state.forcesTotal))
        KDT:Print("state.deaths: " .. tostring(state.deaths))
        KDT:Print("state.bosses: " .. tostring(state.bosses and #state.bosses or 0))
        if state.bosses then
            for i, boss in ipairs(state.bosses) do
                KDT:Print("  Boss " .. i .. ": " .. (boss.name or "?") .. " killed=" .. tostring(boss.killed))
            end
        end
        -- Check direct API values
        KDT:Print("--- Direct API Check ---")
        local inChallenge = C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
        KDT:Print("IsChallengeModeActive: " .. tostring(inChallenge))
        
        local mapID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
        KDT:Print("GetActiveChallengeMapID: " .. tostring(mapID))
        
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
        KDT:Print("GetActiveKeystoneInfo (level): " .. tostring(keystoneLevel))
        
        if mapID then
            local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
            KDT:Print("GetMapUIInfo name: " .. tostring(name))
            KDT:Print("GetMapUIInfo timeLimit: " .. tostring(timeLimit))
        end
        
        local _, elapsedTime = GetWorldElapsedTime(1)
        KDT:Print("GetWorldElapsedTime(1): " .. tostring(elapsedTime))
        
        local deaths = C_ChallengeMode.GetDeathCount and C_ChallengeMode.GetDeathCount()
        KDT:Print("GetDeathCount: " .. tostring(deaths))
        
        -- Scenario info
        if C_Scenario and C_Scenario.GetStepInfo then
            local _, _, numCriteria = C_Scenario.GetStepInfo()
            KDT:Print("Scenario numCriteria: " .. tostring(numCriteria))
        end
        
    elseif cmd == "testrun" then
        -- Add a test run to history
        if not KDT.DB.runHistory then
            KDT.DB.runHistory = {}
        end
        local testRun = {
            dungeon = "Test Dungeon",
            level = 15,
            time = 1800 + math.random(0, 600), -- 30-40 min
            timeLimit = 2100, -- 35 min
            inTime = true,
            upgrade = math.random(1, 3),
            deaths = math.random(0, 5),
            date = date("%Y-%m-%d %H:%M"),
            timestamp = time(),
        }
        table.insert(KDT.DB.runHistory, 1, testRun)
        while #KDT.DB.runHistory > 30 do
            table.remove(KDT.DB.runHistory)
        end
        KDT:Print("Test run added! Total runs: " .. #KDT.DB.runHistory)
        if KDT.MainFrame and KDT.MainFrame:IsShown() then
            KDT.MainFrame:RefreshTimer()
        end
        
    elseif cmd == "clearruns" then
        -- Clear run history
        KDT.DB.runHistory = {}
        KDT:Print("Run history cleared.")
        if KDT.MainFrame and KDT.MainFrame:IsShown() then
            KDT.MainFrame:RefreshTimer()
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
        
    elseif cmd == "testbl" then
        -- Test blacklist warning dialog
        KDT:Print("Testing blacklist warning dialog...")
        KDT:ShowBlacklistWarningDialog("TestPlayer", "This is a test reason")
        
    elseif cmd == "bis" then
        -- Open BiS tab
        if KDT.MainFrame then
            KDT.MainFrame:Show()
            KDT.MainFrame:SwitchTab("bis")
        end
        
    elseif cmd == "resetbis" then
        -- Reset all custom BiS for current spec
        local specID = KDT:GetPlayerSpecID()
        KDT:ResetAllCustomBis(specID)
        KDT:Print("BiS data reset for " .. KDT:GetSpecName(specID))
        if KDT.MainFrame and KDT.MainFrame.RefreshBis then
            KDT.MainFrame:RefreshBis()
        end
        
    elseif cmd == "debugbis" then
        -- Debug BiS data
        KDT:Print("=== BiS Debug ===")
        local specID = KDT:GetPlayerSpecID()
        local _, playerClass = UnitClass("player")
        local specName = KDT:GetSpecName(specID)
        
        KDT:Print("Player Class: " .. tostring(playerClass))
        KDT:Print("Spec ID: " .. tostring(specID))
        KDT:Print("Spec Name: " .. tostring(specName))
        
        -- Check if BIS_DATA has entry for this specID
        KDT:Print("--- Data Sources ---")
        KDT:Print("BIS_DATA[" .. specID .. "] exists: " .. tostring(KDT.BIS_DATA[specID] ~= nil))
        
        -- Check custom data
        local hasCustom = KryosDungeonToolDB and KryosDungeonToolDB.customBis and KryosDungeonToolDB.customBis[specID]
        KDT:Print("CustomBis[" .. specID .. "] exists: " .. tostring(hasCustom ~= nil))
        
        -- Show first item from BIS_DATA
        if KDT.BIS_DATA[specID] then
            local headItem = KDT.BIS_DATA[specID].HEAD
            if headItem then
                KDT:Print("BIS_DATA HEAD: " .. (headItem.name or "?") .. " (ID: " .. (headItem.itemID or 0) .. ")")
            end
        end
        
        -- Show what GetBisForSpec returns
        local bisData = KDT:GetBisForSpec(specID)
        if bisData and bisData.HEAD then
            KDT:Print("GetBisForSpec HEAD: " .. (bisData.HEAD.name or "?") .. " (ID: " .. (bisData.HEAD.itemID or 0) .. ")")
        end
        
        -- List all available specIDs in BIS_DATA
        KDT:Print("--- Available Spec IDs in BIS_DATA ---")
        local specIDs = {}
        for sid, _ in pairs(KDT.BIS_DATA) do
            table.insert(specIDs, sid)
        end
        table.sort(specIDs)
        local specStr = table.concat(specIDs, ", ")
        KDT:Print(specStr)
        
    elseif cmd == "clearbis" then
        -- Clear all custom BiS data for all specs
        if KryosDungeonToolDB then
            KryosDungeonToolDB.customBis = nil
        end
        KDT:Print("All custom BiS data cleared.")
        if KDT.MainFrame and KDT.MainFrame.RefreshBis then
            KDT.MainFrame:RefreshBis()
        end
        
    elseif cmd == "key" then
        local channel = args[2] and args[2]:upper() or "PRINT"
        if channel == "PARTY" or channel == "GUILD" or channel == "SAY" then
            KDT:AnnounceKeystone(channel)
        else
            KDT:AnnounceKeystone("PRINT")
        end
        
    elseif cmd == "partykeys" then
        KDT:RequestPartyKeys()
    
    elseif cmd == "tradelog" then
        KDT:ShowTradeMailLog()
    
    elseif cmd == "visibility" then
        if KDT.Visibility and KDT.Visibility.ToggleEditor then
            KDT.Visibility:ToggleEditor()
        else
            KDT:Print("Visibility module not loaded.")
        end
    
    elseif cmd == "cooldowns" then
        if KDT.Aura and KDT.Aura.CooldownPanels and KDT.Aura.CooldownPanels.ToggleEditor then
            KDT.Aura.CooldownPanels:ToggleEditor()
        elseif KDT.Aura and KDT.Aura.CooldownPanels and KDT.Aura.CooldownPanels.OpenEditor then
            KDT.Aura.CooldownPanels:OpenEditor()
        else
            KDT:Print("Cooldown Panels module not loaded. Check your addon installation.")
        end
    
    elseif cmd == "datapanels" then
        if KDT.DataPanel and KDT.DataPanel.List then
            local list = KDT.DataPanel.List()
            if list and #list > 0 then
                KDT:Print("|cffffd200Data Panels:|r " .. #list .. " panel(s) active")
                for _, p in ipairs(list) do
                    local streamCount = p.order and #p.order or 0
                    KDT:Print("  " .. (p.name or p.id) .. " - " .. streamCount .. " stream(s)")
                end
                KDT:Print("Right-click a panel to configure streams.")
            else
                KDT:Print("No Data Panels exist. Creating one...")
                local panel = KDT.DataPanel.Create(nil, "Panel")
                if panel then
                    KDT:Print("Data Panel created. Right-click it to add streams.")
                end
            end
        else
            KDT:Print("DataPanel module not loaded.")
        end
    
    elseif cmd == "help" then
        KDT:Print("Commands:")
        KDT:Print("  /kdt - Open Group Check")
        KDT:Print("  /kdt bl - Open Blacklist")
        KDT:Print("  /kdt tp - Open Teleports")
        KDT:Print("  /kdt timer - Open Timer settings")
        KDT:Print("  /kdt bis - Open BiS Gear tab (Right-click to edit)")
        KDT:Print("  /kdt resetbis - Reset BiS data for current spec")
        KDT:Print("  /kdt history - Show run history")
        KDT:Print("  /kdt cd - Start countdown")
        KDT:Print("  /kdt ready - Ready check")
        KDT:Print("  /kdt post - Post group to chat")
        KDT:Print("  /kdt key - Show your keystone")
        KDT:Print("  /kdt key party|guild|say - Announce keystone")
        KDT:Print("  /kdt partykeys - Show party keystones")
        KDT:Print("  /kdt tradelog - Show trade & mail log")
        KDT:Print("  /kdt cooldowns - Open Cooldown Panels editor")
        KDT:Print("  /kdt datapanels - Data Panels info")
        KDT:Print("  /kdt visibility - Frame Visibility info")
        
    else
        KDT:Print("Unknown command. Type /kdt help")
    end
end
