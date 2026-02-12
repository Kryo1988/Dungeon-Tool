-- Kryos Dungeon Tool
-- Core/Core.lua - Main addon logic

local addonName, KDT = ...

-- Default database structure
local defaults = {
    minimapPos = 220,
    frameWidth = 700,
    frameHeight = 550,
    blacklist = {},
    runHistory = {},
    settings = {
        autoPost = false,
        countdownSeconds = 10,
        customSound = true,
    },
    timer = {
        enabled = true,
        locked = false,
        showWhenInactive = false,
        scale = 1.2,
        spacing = 3,
        frameStrata = "HIGH",
        hideObjectiveTracker = false,
        position = { anchor = "RIGHT", relativeTo = "RIGHT", xOffset = 0, yOffset = 250 },
        background = { enabled = true, color = {0, 0, 0, 0.5}, borderColor = {0, 0, 0, 1}, borderSize = 1 },
        keyInfo = { width = 330, height = 14 },
        keyLevel = { enabled = true, fontSize = 16, color = {1, 1, 1, 1} },
        dungeonName = { enabled = true, fontSize = 16, shorten = 14, color = {1, 1, 1, 1} },
        deathCounter = { enabled = true, iconEnabled = true, showTimer = false, fontSize = 16, color = {1, 1, 1, 1} },
        timerBar = {
            width = 330, height = 24, borderSize = 1,
            backgroundColor = {0, 0, 0, 0.5}, borderColor = {0, 0, 0, 1},
            texture = "Interface\\Buttons\\WHITE8X8",
            colors = {
                [0] = {89/255, 90/255, 92/255, 1},
                [1] = {1, 112/255, 0, 1},
                [2] = {1, 1, 0, 1},
                [3] = {128/255, 1, 0, 1},
            },
        },
        timerText = { enabled = true, fontSize = 16, color = {1, 1, 1, 1}, successColor = {0, 1, 0, 1}, failColor = {1, 0, 0, 1} },
        chestTimer = { enabled = true, fontSize = 16, aheadColor = {0, 1, 0, 1}, behindColor = {1, 0, 0, 1} },
        ticks = { enabled = true, width = 2, color = {1, 1, 1, 1} },
        bosses = { width = 330, height = 16 },
        bossName = { enabled = true, fontSize = 16, maxLength = 22, color = {1, 1, 1, 1}, completionColor = {0, 1, 0, 1} },
        bossTimer = { enabled = true, fontSize = 16, color = {1, 1, 1, 1} },
        bossSplit = { enabled = true, fontSize = 16, successColor = {0, 1, 0, 1}, failColor = {1, 0, 0, 1}, equalColor = {1, 0.8, 0, 1} },
        forcesBar = {
            width = 330, height = 24, borderSize = 1,
            backgroundColor = {0, 0, 0, 0.5}, borderColor = {0, 0, 0, 1},
            texture = "Interface\\Buttons\\WHITE8X8",
            colors = {
                [1] = {1, 117/255, 128/255, 1},
                [2] = {1, 130/255, 72/255, 1},
                [3] = {1, 197/255, 103/255, 1},
                [4] = {1, 249/255, 150/255, 1},
                [5] = {104/255, 205/255, 1, 1},
            },
            completionColor = {205/255, 1, 167/255, 1},
        },
        percentCount = { enabled = true, fontSize = 16, color = {1, 1, 1, 1}, remaining = false },
        realCount = { enabled = true, fontSize = 16, color = {1, 1, 1, 1}, remaining = true, total = false },
    },
    meter = {
        enabled = true,
    },
    qol = {
        sellJunk = false,
        autoRepairEnabled = false,
        autoRepairMode = "personal",  -- "personal" or "guild"
        autoRoleAccept = false,
        autoRolePreference = "dps",   -- "dps", "healer", "tank"
        autoAcceptInvites = false,
        autoAcceptQuest = false,
        autoTurnInQuest = false,
        skipGossip = false,
        skipCutscene = false,
        -- Interface: Nameplates & Names
        showClassColorsNameplates = false,
        showGuildNames = false,
        showPvPTitles = false,
        -- Interface: UI Tweaks
        hideTalkingHead = false,
        hideDeathEffect = false,
        hideZoneText = false,
        hideRaidTools = false,
        autoUnwrapCollections = false,
        -- Interface: Resource Bars (class-specific)
        hideRuneFrame = false,
        hideComboPoints = false,
        hideHolyPower = false,
        hideHarmonyBar = false,
        hideEssenceBar = false,
        hideSoulShards = false,
        hideTotemBar = false,
        -- Economy: Auction House
        ahCloseBags = false,
        ahPersistFilter = false,
        ahCurrentExpansion = false,
        -- Economy: Mark Known on Merchant
        markKnownTransmog = false,
        markKnownRecipes = false,
        markKnownToys = false,
        markCollectedPets = false,
        -- Economy: Gold Tracking
        goldTrackingEnabled = false,
        -- Economy: Extended Merchant
        extMerchantEnabled = false,
        minimapCollectorEnabled = false,
        -- Social: Privacy & Blocking
        blockDuels = false,
        blockPetBattles = false,
        blockPartyInvites = false,
        -- Social: Auto Accept Invite (upgraded)
        autoAcceptInviteGuildOnly = false,
        autoAcceptInviteFriendOnly = false,
        -- Social: Auto Accept Summon
        autoAcceptSummon = false,
        -- Social: Community Chat Privacy
        communityChatPrivacy = false,
        communityChatPrivacyMode = "always",  -- "always" or "session"
        -- Social: Friends List Decor
        friendsListDecor = false,
        friendsListDecorLocation = true,
        friendsListDecorHideOwnRealm = true,
        -- General: Dialogs & Confirmations
        deleteItemFillDialog = false,
        confirmReplaceEnchant = false,
        confirmSocketReplace = false,
        confirmHighCostItem = false,
        confirmPurchaseTokenItem = false,
        confirmTimerRemovalTrade = false,
        -- General: Utilities
        autoDismount = false,
        autoDismountFlying = false,
        hideScreenshotStatus = false,
        showTrainAllButton = false,
        autoQuickLoot = false,
        autoQuickLootWithShift = false,
        -- Gameplay: Combat & Dungeon
        autoAcceptResurrection = false,
        autoAcceptResurrectionExcludeCombat = true,
        autoAcceptResurrectionExcludeAfterlife = true,
        autoReleasePvP = false,
        autoReleasePvPDelay = 0,
        autoCombatLog = false,
        hideBossBanner = false,
        -- Interface: Unit Frames
        hideHitIndicatorPlayer = false,
        hideHitIndicatorPet = false,
        hideRestingGlow = false,
        hidePartyFrameTitle = false,
        hideMacroNames = false,
        hideExtraActionArtwork = false,
        hideMicroMenuNotification = false,
        hideAzeriteToast = false,
        hideQuickJoinToast = false,
        -- Chat
        chatEditBoxOnTop = false,
        chatUseArrowKeys = false,
        chatHideCombatLogTab = false,
        chatMaxLines2000 = false,
        chatUnclampFrame = false,
        chatFadeEnabled = false,
        chatFadeTimeVisible = 120,
        chatFadeDuration = 10,
        chatHideLearnUnlearn = false,
        -- Gameplay: LFG Tweaks
        lfgSortByRio = false,
        lfgPersistSignUpNote = false,
        lfgSkipSignUpDialog = false,
        -- Phase 2: Chat Icons
        chatItemIcons = false,
        chatItemLevel = false,
        chatItemLevelLocation = false,
        -- Phase 2: Health Text
        healthTextPlayer = "OFF",
        healthTextTarget = "OFF",
        healthTextBoss = "OFF",
        -- Phase 2: Instance Difficulty Text
        showInstanceDifficulty = false,
        instanceDiffFontSize = 14,
        instanceDiffUseColors = false,
        instanceDiffColors = {
            NM = { r = 0.20, g = 0.95, b = 0.20 },
            HC = { r = 0.25, g = 0.55, b = 1.00 },
            M  = { r = 0.80, g = 0.40, b = 1.00 },
            MPLUS = { r = 0.80, g = 0.40, b = 1.00 },
            LFR = { r = 1.00, g = 1.00, b = 1.00 },
            TW  = { r = 1.00, g = 1.00, b = 1.00 },
        },
        -- Phase 2: Extended Merchant (20 items/page)
        enableExtendedMerchant = false,
        -- Phase 2: Mount Actions
        randomMountUseAll = false,
        randomMountSlowFallWhenFalling = false,
        randomMountDracthyrVisageBeforeMount = false,
        randomMountDruidNoShiftWhileMounted = false,
        -- Phase 2: Tooltip Enhancements
        tooltipClassColors = false,
        tooltipShowGuildRank = false,
        tooltipColorGuildName = false,
        tooltipShowMythicScore = false,
        tooltipMythicScoreModifier = "SHIFT",
        tooltipShowTargetOfTarget = false,
        tooltipShowMount = false,
        tooltipShowSpec = false,
        tooltipShowItemLevel = false,
        tooltipShowSpellID = false,
        tooltipShowSpellIcon = false,
        tooltipShowItemID = false,
        tooltipShowItemIcon = false,
        tooltipShowNPCID = false,
        tooltipShowCurrencyID = false,
        tooltipHideInCombat = false,
        tooltipHideHealthBar = false,
        tooltipHideFaction = false,
        tooltipHidePvP = false,
        tooltipHideRightClick = false,
        tooltipAnchorCursor = false,
        tooltipScale = 1,
        -- Phase 2: Bag Item Level
        showBagItemLevel = false,
        showBagUpgradeArrow = false,
        -- Phase 2: Trade & Mail Log
        enableTradeMailLog = false,
        -- Phase 2: Action Bar Tweaks
        actionBarShortenHotkeys = false,
        actionBarRangeColoring = false,
        -- Phase 3: GCD Bar
        gcdBarEnabled = false,
        gcdBarPosition = nil,  -- {point, relativePoint, x, y}
        -- Phase 3: Loot Toast Filter
        lootToastFilterEnabled = false,
        -- Phase 3: Container Actions (auto-open containers)
        containerActionsEnabled = false,
        containerActionsPosition = nil,
        containerActionsBlacklist = {},
        -- Phase 3: Dungeon Journal Loot Spec
        djLootSpecEnabled = false,
        djLootSpecShowAll = false,
        -- Phase 3: Frame Mover
        frameMoverEnabled = false,
        frameMoverRequireModifier = true,
        frameMoverModifier = "SHIFT",  -- SHIFT, CTRL, ALT
        frameMoverScaleEnabled = false,
        frameMoverScaleModifier = "CTRL",
        frameMoverPersistence = "reset",  -- close, lockout, reset
        -- Phase 3: Food Reminder
        foodReminderEnabled = false,
        foodReminderSound = true,
        foodReminderPosition = nil,
        foodReminderFlask = true,
        foodReminderFood = true,
        foodReminderRune = false,       -- Off by default (not everyone uses runes)
        foodReminderWeapon = false,     -- Off by default (not all specs use temp enchants)
        foodReminderHealthPot = true,
        foodReminderCombatPot = false,  -- Off by default (casual players may not use)
        -- Phase 3: Chat History
        chatHistoryEnabled = false,
        chatHistoryMaxMessages = 500,
        chatHistoryShowTimestamps = true,
        -- Phase 3: Unit Frame Visibility
        ufVisibilityEnabled = false,
        ufVisibilityFadeInCombat = false,
        ufVisibilityFadeOOC = false,
        ufVisibilityFadeAlpha = 0.3,
        -- Keystone Helper
        keystoneAutoSlot = false,
        keystoneShowDisplay = false,
        visibilityRules = {},
        visibilityFadeAmount = 100,
        keystoneDepletionWarning = true,
        keystoneDisplayPoint = nil,
        keystoneDisplayRelPoint = nil,
        keystoneDisplayX = 0,
        keystoneDisplayY = 0,
    },
    tradeMailLog = {},  -- Stored trade/mail history entries
    goldTracker = {},  -- {["Name-Realm"] = {gold=12345, class="WARRIOR", lastSeen=time()}}
    frameMoverPositions = {},  -- {[frameId] = {point, x, y, scale, enabled}}
    chatHistoryData = {},  -- {[channelKey] = {{msg, sender, time}, ...}}
    chatEnhancer = {
        enabled = false,         -- Master toggle (requires /reload)
        transparency = 18,       -- Background (0-100)
        tabTransparency = 0,     -- Tab (0-100)
        classColors = true,      -- Class-colored names in chat
        clickableURLs = true,    -- Clickable URL links
        shortenChannels = true,  -- Shorten channel names
    },
    editModeLayouts = {},  -- EditMode layout position data per layout
    dataPanels = {},  -- DataPanel configurations
    cooldownPanels = {  -- CooldownPanels configuration
        version = 1,
        panels = {},
        order = {},
        selectedPanel = nil,
        defaults = {
            layout = {
                iconSize = 36,
                spacing = 2,
                direction = "RIGHT",
                wrapCount = 0,
                wrapDirection = "DOWN",
                strata = "MEDIUM",
            },
            entry = {
                alwaysShow = true,
                showCooldown = true,
                showCooldownText = true,
                showCharges = false,
                showStacks = false,
                glowReady = false,
                glowDuration = 0,
            },
        },
    },
    cooldownPanelsEditorPoint = "CENTER",
    cooldownPanelsEditorX = 0,
    cooldownPanelsEditorY = 0,
    cooldownPanelsFilterClass = false,
}

-- Deep copy function
local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

-- Merge tables (apply defaults to saved vars)
local function MergeDefaults(sv, def)
    if type(sv) ~= "table" then return DeepCopy(def) end
    for k, v in pairs(def) do
        if sv[k] == nil then
            sv[k] = DeepCopy(v)
        elseif type(v) == "table" and type(sv[k]) == "table" then
            MergeDefaults(sv[k], v)
        end
    end
    return sv
end

-- Initialize database
function KDT:InitDB()
    if not KryosDungeonToolDB then
        KryosDungeonToolDB = DeepCopy(defaults)
    else
        KryosDungeonToolDB = MergeDefaults(KryosDungeonToolDB, defaults)
    end
    self.DB = KryosDungeonToolDB
    self.db = self.DB  -- Alias for ported EnhanceQoL modules
    
    -- Migration: Update default scale from 1 to 1.2 for existing users
    if self.DB.timer and self.DB.timer.scale == 1 and not self.DB.migratedScale then
        self.DB.timer.scale = 1.2
        self.DB.migratedScale = true
    end
    
    -- Migration: customBis flat format -> per-mode format
    -- Old: customBis[specID]["HEAD"] = {...}
    -- New: customBis[specID]["overall"]["HEAD"] = {...}
    if self.DB.customBis and not self.DB.migratedCustomBisPerMode then
        for specID, specData in pairs(self.DB.customBis) do
            if type(specData) == "table" then
                -- Detect old format: slot keys like "HEAD", "NECK" exist at top level
                local isOldFormat = specData["HEAD"] or specData["NECK"] or specData["CHEST"]
                                    or specData["MAINHAND"] or specData["TRINKET1"]
                if isOldFormat then
                    -- Move all slot data into "custom" mode
                    local slotData = {}
                    for slot, data in pairs(specData) do
                        slotData[slot] = data
                    end
                    self.DB.customBis[specID] = { custom = slotData }
                end
            end
        end
        self.DB.migratedCustomBisPerMode = true
    end
end

-- Class colors
KDT.CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1.00, 0.96, 0.41},
    PRIEST = {1.00, 1.00, 1.00},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    SHAMAN = {0.00, 0.44, 0.87},
    MAGE = {0.41, 0.80, 0.94},
    WARLOCK = {0.58, 0.51, 0.79},
    MONK = {0.00, 1.00, 0.59},
    DRUID = {1.00, 0.49, 0.04},
    DEMONHUNTER = {0.64, 0.19, 0.79},
    EVOKER = {0.20, 0.58, 0.50},
}

-- Role icons
KDT.ROLE_ICONS = {
    TANK = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",
    HEALER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
    DAMAGER = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t",
}

-- Battle rez classes
KDT.BATTLE_REZ = {
    DRUID = true,
    DEATHKNIGHT = true,
    WARLOCK = true,
    PALADIN = true,
}

-- Bloodlust classes
KDT.BLOODLUST = {
    SHAMAN = true,
    MAGE = true,
    HUNTER = true,
    EVOKER = true,
}

-- Class names
KDT.CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue",
    PRIEST = "Priest", DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage",
    WARLOCK = "Warlock", MONK = "Monk", DRUID = "Druid", DEMONHUNTER = "Demon Hunter",
    EVOKER = "Evoker",
}

-- Utf8 substring (for non-ASCII characters)
function KDT:Utf8Sub(str, startChar, endChar)
    if not str then return str end
    local startIndex, endIndex = 1, #str
    local currentIndex, currentChar = 1, 0
    while currentIndex <= #str do
        currentChar = currentChar + 1
        if currentChar == startChar then startIndex = currentIndex end
        if endChar and currentChar > endChar then endIndex = currentIndex - 1; break end
        local c = string.byte(str, currentIndex)
        if c < 0x80 then currentIndex = currentIndex + 1
        elseif c < 0xE0 then currentIndex = currentIndex + 2
        elseif c < 0xF0 then currentIndex = currentIndex + 3
        else currentIndex = currentIndex + 4 end
    end
    return string.sub(str, startIndex, endIndex)
end

-- Format time (MM:SS or H:MM:SS)
function KDT:FormatTime(time, round)
    if not time then return "0:00" end
    local negative = time < 0
    time = math.abs(time)
    local timeMin = math.floor(time / 60)
    local timeSec = round and math.floor(time - (timeMin * 60) + 0.5) or math.floor(time - (timeMin * 60))
    local timeHour = 0
    if timeMin >= 60 then
        timeHour = math.floor(time / 3600)
        timeMin = timeMin - (timeHour * 60)
    end
    local result
    if timeHour > 0 then result = string.format("%d:%02d:%02d", timeHour, timeMin, timeSec)
    else result = string.format("%d:%02d", timeMin, timeSec) end
    return (negative and "-" or "") .. result
end

-- ==================== UI HELPERS ====================

-- Get class color as hex string
function KDT:GetClassColorHex(class)
    local c = self.CLASS_COLORS[class]
    if c then
        return string.format("%02X%02X%02X", c[1] * 255, c[2] * 255, c[3] * 255)
    end
    return "FFFFFF"
end

-- Create a styled button
function KDT:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    end)
    
    return btn
end

-- Create a styled input box
function KDT:CreateInput(parent, width)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width, 20)
    input:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    input:SetBackdropColor(0.05, 0.05, 0.07, 1)
    input:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    input:SetFontObject("GameFontHighlightSmall")
    input:SetTextInsets(5, 5, 0, 0)
    input:SetAutoFocus(false)
    
    return input
end

-- Print message to chat
function KDT:Print(msg)
    print("|cFFFF0000Kryos|r Dungeon Tool: " .. msg)
end

-- Version
KDT.version = "2.7.7"

-- Already alerted (for blacklist)
KDT.alreadyAlerted = {}

-- ==================== STATIC POPUP DIALOGS ====================

-- Abandon Keystone Dialog (starts vote in active M+ run)
StaticPopupDialogs["KRYOS_ABANDON"] = {
    text = "Start abandon vote for the current Mythic+ run?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        -- Close dialog first
        StaticPopup_Hide("KRYOS_ABANDON")
        
        -- Delayed call to avoid taint issues
        C_Timer.After(0.1, function()
            local isActive = C_ChallengeMode.IsChallengeModeActive()
            
            if isActive then
                -- WoW 12.0+: Abandon system uses /abandon command (since Patch 11.2)
                -- We cannot programmatically execute /abandon as it's a protected command
                -- Instead, we open the chat box with /abandon pre-filled
                
                local chatFrame = DEFAULT_CHAT_FRAME
                local editBox = chatFrame.editBox or ChatEdit_GetActiveWindow()
                
                if editBox then
                    -- Show the edit box
                    ChatEdit_ActivateChat(editBox)
                    -- Set the text to /abandon
                    editBox:SetText("/abandon")
                    -- Set cursor to end
                    editBox:HighlightText(0, 0)
                    
                    KDT:Print("Press |cFFFFFF00ENTER|r to start the abandon vote!")
                else
                    -- Fallback if edit box not available
                    KDT:Print("To abandon this keystone, type: |cFFFFFF00/abandon|r and press ENTER")
                end
            else
                KDT:Print("No active Mythic+ run to abandon.")
            end
        end)
    end,
    OnCancel = function(self)
        StaticPopup_Hide("KRYOS_ABANDON")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
