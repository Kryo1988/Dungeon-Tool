---------------------------------------------------------------------------
-- KryosDungeonTool: MountActions Module
-- Smart random mount with keybindable buttons, class-specific forms,
-- slow fall when falling, and context-aware mount selection
-- Ported from EnhanceQoL/Submodules/MountActions.lua
---------------------------------------------------------------------------
local _, KDT = ...

local MountActions = {}
KDT.MountActions = MountActions
local issecretvalue = _G.issecretvalue

local RANDOM_FAVORITE_SPELL_ID = 150544
local GHOST_WOLF_SPELL_ID = 2645
local SLOW_FALL_SPELL_ID = 130
local LEVITATE_SPELL_ID = 1706
local DRACTHYR_VISAGE_AURA_CHECK = 372014
local DRACTHYR_VISAGE_SPELL = 351239
local REPAIR_MOUNT_SPELLS = { 457485, 122708, 61425, 61447 }
local AH_MOUNT_SPELLS = { 264058, 465235 }

local MOUNT_TYPE_CATEGORIES = {
    water   = { 231, 254, 232, 407 },
    flying  = { 247, 248, 398, 407, 424, 402 },
    ground  = { 230, 241, 269, 284, 408, 412, 231 },
}
local MOUNT_TYPE_KNOWN = {}
for _, ids in pairs(MOUNT_TYPE_CATEGORIES) do
    for _, id in ipairs(ids) do MOUNT_TYPE_KNOWN[id] = true end
end

---------------------------------------------------------------------------
-- UTILITY
---------------------------------------------------------------------------
local function isFlyableArea()
    if IsFlyableArea and IsFlyableArea() then return true end
    if IsAdvancedFlyableArea and IsAdvancedFlyableArea() then return true end
    return false
end

local function isSwimming()
    if IsSubmerged and IsSubmerged() then return true end
    if IsSwimming and IsSwimming() then return true end
    return false
end

local function getSpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    if GetSpellInfo then return GetSpellInfo(spellID) end
    return nil
end

local function isSpellKnown(spellID)
    if not spellID then return false end
    if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(spellID) == true end
    if IsSpellKnown then return IsSpellKnown(spellID) == true end
    return false
end

local function entryMatchesCategory(entry, category)
    if not category then return true end
    if category == "flying" and entry.isSteadyFlight then return true end
    local mtID = entry.mountTypeID
    if not mtID or not MOUNT_TYPE_KNOWN[mtID] then return category == "ground" end
    local ids = MOUNT_TYPE_CATEGORIES[category]
    if not ids then return false end
    for i = 1, #ids do if ids[i] == mtID then return true end end
    return false
end

local function isEntryUsable(entry)
    if not entry or not entry.mountID then return false end
    if C_MountJournal and C_MountJournal.GetMountUsabilityByID then
        local usable = C_MountJournal.GetMountUsabilityByID(entry.mountID, true)
        if usable ~= nil then return usable == true end
    end
    return entry.isUsable == true
end

local function pickRandom(entries, category)
    local count, chosen = 0, nil
    for i = 1, #entries do
        local e = entries[i]
        if entryMatchesCategory(e, category) and isEntryUsable(e) then
            count = count + 1
            if math.random(count) == 1 then chosen = e.spellID end
        end
    end
    return chosen
end

local function getMountIDFromSpell(spellID)
    if not spellID or not C_MountJournal then return nil end
    if C_MountJournal.GetMountFromSpell then return C_MountJournal.GetMountFromSpell(spellID) end
    return nil
end

local function isMountSpellUsable(spellID)
    local mountID = getMountIDFromSpell(spellID)
    if not mountID then return false end
    local _, _, _, _, isUsable, _, _, _, _, shouldHide, isCollected = C_MountJournal.GetMountInfoByID(mountID)
    if not isCollected or shouldHide then return false end
    if C_MountJournal.GetMountUsabilityByID then
        local u = C_MountJournal.GetMountUsabilityByID(mountID, true)
        if u ~= nil then isUsable = u end
    end
    return isUsable == true
end

local function pickFirstUsable(spellList)
    for _, spellID in ipairs(spellList) do
        if isMountSpellUsable(spellID) then return spellID end
    end
    return nil
end

---------------------------------------------------------------------------
-- CLASS-SPECIFIC MACROS
---------------------------------------------------------------------------
local function getQoL()
    return KDT.DB and KDT.DB.qol
end

local function getFallingSafetyMacro()
    local qol = getQoL()
    if not qol or not qol.randomMountSlowFallWhenFalling then return nil end
    if not (IsFalling and IsFalling()) then return nil end
    local _, class = UnitClass("player")
    if class == "PRIEST" and isSpellKnown(LEVITATE_SPELL_ID) then
        local name = getSpellName(LEVITATE_SPELL_ID)
        if name then return "/cast [@player] " .. name end
    elseif class == "MAGE" and isSpellKnown(SLOW_FALL_SPELL_ID) then
        local name = getSpellName(SLOW_FALL_SPELL_ID)
        if name then return "/cast [@player] " .. name end
    end
    return nil
end

local function getDruidMoveFormMacro()
    local travel = getSpellName(783)
    local cat = getSpellName(768)
    if not travel and not cat then return nil end
    local t = travel or cat
    local c = cat or travel or ""
    if c == "" then c = t end
    return "/cancelform\n/cast [swimming][outdoors] " .. t .. "; [indoors] " .. c .. "; " .. c
end

local function getShamanGhostWolfMacro()
    local name = getSpellName(GHOST_WOLF_SPELL_ID)
    if not name or name == "" then return nil end
    return "/cancelform\n/cast " .. name
end

local function shouldUseDracthyrVisage()
    local qol = getQoL()
    if not qol or not qol.randomMountDracthyrVisageBeforeMount then return false end
    local _, race = UnitRace("player")
    if race ~= "Dracthyr" then return false end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        return C_UnitAuras.GetPlayerAuraBySpellID(DRACTHYR_VISAGE_AURA_CHECK) == nil
    end
    return false
end

local function buildMountMacro(spellID)
    local name = getSpellName(spellID)
    if not name or name == "" then return "/run C_MountJournal.SummonByID(0)" end
    local lines = {}
    if shouldUseDracthyrVisage() then
        local vName = getSpellName(DRACTHYR_VISAGE_SPELL)
        if vName then table.insert(lines, "/cast " .. vName) end
    end
    table.insert(lines, "/cast " .. name)
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- MOUNT CACHE
---------------------------------------------------------------------------
function MountActions:BuildCache(useAll)
    local list = {}
    if not C_MountJournal or not C_MountJournal.GetMountIDs then return list end
    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local _, spellID, _, _, isUsable, _, isFavorite, _, _, shouldHide, isCollected, _, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
        if isCollected and not shouldHide and spellID and (useAll or isFavorite) then
            local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
            list[#list + 1] = {
                mountID = mountID, spellID = spellID, mountTypeID = mountTypeID,
                isSteadyFlight = isSteadyFlight == true, isUsable = isUsable == true,
            }
        end
    end
    return list
end

function MountActions:GetRandomSpell()
    local qol = getQoL()
    local useAll = qol and qol.randomMountUseAll
    local mode = useAll and "all" or "fav"
    if self.dirty or not self.cache or self.cacheMode ~= mode then
        self.cache = self:BuildCache(useAll)
        self.cacheMode = mode
        self.dirty = false
    end
    local list = self.cache
    if not list or #list == 0 then return nil end
    local spellID
    if isSwimming() then
        spellID = pickRandom(list, "water")
        if not spellID and isFlyableArea() then spellID = pickRandom(list, "flying") end
        if not spellID then spellID = pickRandom(list, "ground") end
    elseif isFlyableArea() then
        spellID = pickRandom(list, "flying")
        if not spellID then spellID = pickRandom(list, "ground") end
    else
        spellID = pickRandom(list, "ground")
    end
    return spellID or pickRandom(list)
end

function MountActions:MarkDirty() self.dirty = true end

---------------------------------------------------------------------------
-- SECURE ACTION BUTTONS
---------------------------------------------------------------------------
function MountActions:PrepareButton(btn)
    if InCombatLockdown and InCombatLockdown() then return end
    if not btn or not btn._kdtAction then return end
    btn:SetAttribute("type1", "macro")
    btn:SetAttribute("type", "macro")

    local _, class = UnitClass("player")

    -- Druid: travel/cat form while mounted and moving
    if btn._kdtAction == "random" and class == "DRUID" and IsMounted and IsMounted() and IsPlayerMoving() then
        if not (IsFlying and IsFlying()) then
            local qol = getQoL()
            if not (qol and qol.randomMountDruidNoShiftWhileMounted) then
                local macro = getDruidMoveFormMacro()
                if macro then btn:SetAttribute("macrotext1", macro) btn:SetAttribute("macrotext", macro) return end
            end
        end
    end

    -- Shaman: ghost wolf while mounted and moving
    if btn._kdtAction == "random" and class == "SHAMAN" and IsMounted and IsMounted() and IsPlayerMoving() and isSpellKnown(GHOST_WOLF_SPELL_ID) then
        if not (IsFlying and IsFlying()) then
            local macro = getShamanGhostWolfMacro()
            if macro then btn:SetAttribute("macrotext1", macro) btn:SetAttribute("macrotext", macro) return end
        end
    end

    -- Dismount if already mounted
    if IsMounted and IsMounted() then
        btn:SetAttribute("macrotext1", "/dismount")
        btn:SetAttribute("macrotext", "/dismount")
        return
    end

    -- Falling safety
    local fallMacro = getFallingSafetyMacro()
    if fallMacro then btn:SetAttribute("macrotext1", fallMacro) btn:SetAttribute("macrotext", fallMacro) return end

    -- Shaman ghost wolf while walking (not mounted)
    if btn._kdtAction == "random" and class == "SHAMAN" and IsPlayerMoving() and isSpellKnown(GHOST_WOLF_SPELL_ID) then
        local macro = getShamanGhostWolfMacro()
        if macro then btn:SetAttribute("macrotext1", macro) btn:SetAttribute("macrotext", macro) return end
    end

    -- Druid travel/cat while walking (not mounted)
    if btn._kdtAction == "random" and class == "DRUID" and IsPlayerMoving() and (isSpellKnown(783) or isSpellKnown(768)) then
        local macro = getDruidMoveFormMacro()
        if macro then btn:SetAttribute("macrotext1", macro) btn:SetAttribute("macrotext", macro) return end
    end

    -- Pick mount
    if btn._kdtAction == "random" then
        local spellID = self:GetRandomSpell()
        local macro = buildMountMacro(spellID or RANDOM_FAVORITE_SPELL_ID)
        btn:SetAttribute("macrotext1", macro)
        btn:SetAttribute("macrotext", macro)
    elseif btn._kdtAction == "repair" then
        local spellID = pickFirstUsable(REPAIR_MOUNT_SPELLS)
        if spellID then local m = buildMountMacro(spellID) btn:SetAttribute("macrotext1", m) btn:SetAttribute("macrotext", m) end
    elseif btn._kdtAction == "ah" then
        local spellID = pickFirstUsable(AH_MOUNT_SPELLS)
        if spellID then local m = buildMountMacro(spellID) btn:SetAttribute("macrotext1", m) btn:SetAttribute("macrotext", m) end
    end
end

function MountActions:EnsureButton(name, action)
    local btn = _G[name]
    if not btn then btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate") end
    btn:RegisterForClicks("AnyDown")
    btn:SetAttribute("type1", "macro")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("pressAndHoldAction", true)
    btn._kdtAction = action
    if action == "random" then
        local macro = buildMountMacro(RANDOM_FAVORITE_SPELL_ID)
        btn:SetAttribute("macrotext1", macro)
        btn:SetAttribute("macrotext", macro)
    end
    btn:SetScript("PreClick", function(self) MountActions:PrepareButton(self) end)
    return btn
end

function MountActions:Init()
    if self.initialized then return end
    self.initialized = true
    self:MarkDirty()
    self:EnsureButton("KDT_RandomMountButton", "random")
    self:EnsureButton("KDT_RepairMountButton", "repair")
    self:EnsureButton("KDT_AHMountButton", "ah")
end

-- Keybinding labels (Bindings.xml at addon root provides the UI section)
_G["BINDING_HEADER_KRYOSDUNGEONTOOL"] = "KryosDungeonTool"
_G["BINDING_NAME_CLICK KDT_RandomMountButton:LeftButton"] = "Smart Random Mount"
_G["BINDING_NAME_CLICK KDT_RepairMountButton:LeftButton"] = "Repair Mount"
_G["BINDING_NAME_CLICK KDT_AHMountButton:LeftButton"] = "AH Mount"

-- Event-driven cache invalidation
local evtFrame = CreateFrame("Frame")
evtFrame:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
evtFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
evtFrame:RegisterEvent("COMPANION_LEARNED")
evtFrame:RegisterEvent("COMPANION_UNLEARNED")
evtFrame:RegisterEvent("COMPANION_UPDATE")
evtFrame:SetScript("OnEvent", function() MountActions:MarkDirty() end)

-- Init on login
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function() MountActions:Init() end)
