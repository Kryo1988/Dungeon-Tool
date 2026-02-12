-- Kryos Dungeon Tool
-- Data/BisData.lua - Best in Slot data bridge to PeaversBestInSlotData
-- Version: 2.0 - Fully driven by PeaversBestInSlotData addon

local addonName, KDT = ...

-- =============================================================================
-- CONSTANTS
-- =============================================================================

KDT.BIS_SOURCE = {
    RAID = "Raid",
    MYTHIC_PLUS = "M+",
    CRAFTED = "Crafted",
    DELVE = "Delve",
    WORLD = "World",
    PVP = "PvP",
    UNKNOWN = "???",
}

KDT.SLOT_ORDER = {
    "HEAD", "NECK", "SHOULDER", "BACK", "CHEST", 
    "WRIST", "HANDS", "WAIST", "LEGS", "FEET",
    "FINGER1", "FINGER2", "TRINKET1", "TRINKET2", "MAINHAND", "OFFHAND"
}

KDT.SLOT_NAMES = {
    HEAD = "Head", NECK = "Neck", SHOULDER = "Shoulders", BACK = "Back",
    CHEST = "Chest", WRIST = "Wrists", HANDS = "Hands", WAIST = "Waist",
    LEGS = "Legs", FEET = "Feet", FINGER1 = "Ring 1", FINGER2 = "Ring 2",
    TRINKET1 = "Trinket 1", TRINKET2 = "Trinket 2", MAINHAND = "Main Hand", OFFHAND = "Off Hand",
}

KDT.SPEC_NAMES = {
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    [577] = "Havoc", [581] = "Vengeance", [1480] = "Devourer",
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Restoration",
    [1467] = "Devastation", [1468] = "Preservation", [1473] = "Augmentation",
    [253] = "Beast Mastery", [254] = "Marksmanship", [255] = "Survival",
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    [268] = "Brewmaster", [270] = "Mistweaver", [269] = "Windwalker",
    [65] = "Holy", [66] = "Protection", [70] = "Retribution",
    [256] = "Discipline", [257] = "Holy", [258] = "Shadow",
    [259] = "Assassination", [260] = "Outlaw", [261] = "Subtlety",
    [262] = "Elemental", [263] = "Enhancement", [264] = "Restoration",
    [265] = "Affliction", [266] = "Demonology", [267] = "Destruction",
    [71] = "Arms", [72] = "Fury", [73] = "Protection",
}

-- =============================================================================
-- HERO TALENT SPEC MAPPING (TWW)
-- =============================================================================
KDT.HERO_SPEC_TO_BASE = {}

function KDT:GetBaseSpecID(specID)
    return self.HERO_SPEC_TO_BASE[specID] or specID
end

-- =============================================================================
-- PEAVERS BESTINSLOTDATA BRIDGE
-- =============================================================================

KDT.bisMode = "overall"  -- "overall", "raid", "dungeon", "custom"

-- PeaversBestInSlotData slot ID (numeric) -> KDT slot key (string)
local PEAVERS_SLOT_MAP = {
    [1]  = "HEAD",
    [2]  = "NECK",
    [3]  = "SHOULDER",
    [5]  = "CHEST",
    [6]  = "WAIST",
    [7]  = "LEGS",
    [8]  = "FEET",
    [9]  = "WRIST",
    [10] = "HANDS",
    [11] = "FINGER1",
    [12] = "FINGER2",
    [13] = "TRINKET1",
    [14] = "TRINKET2",
    [15] = "BACK",
    [16] = "MAINHAND",
    [17] = "OFFHAND",
}

-- SpecID -> ClassID mapping (WoW standard)
local SPEC_TO_CLASS = {
    [71] = 1, [72] = 1, [73] = 1,           -- Warrior
    [65] = 2, [66] = 2, [70] = 2,           -- Paladin
    [253] = 3, [254] = 3, [255] = 3,        -- Hunter
    [259] = 4, [260] = 4, [261] = 4,        -- Rogue
    [256] = 5, [257] = 5, [258] = 5,        -- Priest
    [250] = 6, [251] = 6, [252] = 6,        -- Death Knight
    [262] = 7, [263] = 7, [264] = 7,        -- Shaman
    [62] = 8, [63] = 8, [64] = 8,           -- Mage
    [265] = 9, [266] = 9, [267] = 9,        -- Warlock
    [268] = 10, [269] = 10, [270] = 10,     -- Monk
    [102] = 11, [103] = 11, [104] = 11, [105] = 11,  -- Druid
    [577] = 12, [581] = 12, [1480] = 12,    -- Demon Hunter
    [1467] = 13, [1468] = 13, [1473] = 13,  -- Evoker
}

-- Source classification based on actual dropSource (where the item drops)
-- Season 3 known dungeons — everything else that's not Crafted is assumed RAID
local KNOWN_DUNGEONS = {
    ["Ara-Kara, City of Echoes"] = true,
    ["Cinderbrew Meadery"] = true,
    ["Eco-Dome Al'dani"] = true,
    ["Grim Batol"] = true,
    ["Halls of Atonement"] = true,
    ["Operation: Floodgate"] = true,
    ["Priory of the Sacred Flame"] = true,
    ["Spires of Ascension"] = true,
    ["Tazavesh, the Veiled Market"] = true,
    ["The Dawnbreaker"] = true,
    ["The Stonevault"] = true,
}

-- Classify an item's actual drop source from its dropSource string
local function ClassifyDropSource(dropSource)
    if not dropSource or dropSource == "" then
        return "UNKNOWN"
    elseif dropSource == "Crafted" then
        return "CRAFTED"
    elseif KNOWN_DUNGEONS[dropSource] then
        return "MYTHIC_PLUS"
    else
        -- Everything else (Manaforge Omega, The Dreamrift, Nerub-ar Palace, etc.)
        return "RAID"
    end
end

function KDT:IsPeaversBisAvailable()
    return _G["PeaversBestInSlotData"] and _G["PeaversBestInSlotData"].API ~= nil
end

-- Pre-cache item IDs so GetItemInfo resolves names on next call
local function PreCacheItems(bisList)
    if not bisList or not C_Item or not C_Item.RequestLoadItemDataByID then return end
    for _, items in pairs(bisList) do
        if items then
            for _, item in ipairs(items) do
                if item.itemID and item.itemID > 0 then
                    C_Item.RequestLoadItemDataByID(item.itemID)
                end
            end
        end
    end
end

-- Resolve item name via WoW API with Peavers fallback
local function ResolveItemName(itemID, fallbackName)
    if not itemID or itemID == 0 then return fallbackName or "Unknown" end
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return GetItemInfo(itemID) or fallbackName or "Loading..."
end

-- Build a KDT item entry from a Peavers item
local function BuildItemEntry(item)
    local drop = item.dropSource or ""
    return {
        name = ResolveItemName(item.itemID, item.itemName),
        itemID = item.itemID or 0,
        source = ClassifyDropSource(drop),
        sourceDetail = (drop ~= "Crafted" and drop ~= "") and drop or "",
    }
end

-- Collect ALL items from both Peavers databases into a unified pool per slot
-- Returns: { [slotID] = { {item=..., priority=...}, ... }, ... }
local function CollectAllItems(classID, specID)
    local API = _G["PeaversBestInSlotData"].API
    local raidList = API.GetFullBiSList(classID, specID, "raid")
    local dungeonList = API.GetFullBiSList(classID, specID, "dungeon")

    if not raidList and not dungeonList then return nil end

    PreCacheItems(raidList)
    PreCacheItems(dungeonList)

    -- Merge both lists, dedup by itemID per slot
    local pool = {}
    local allSlotIDs = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}

    for _, slotID in ipairs(allSlotIDs) do
        pool[slotID] = {}
        local seen = {}

        -- Add raid items
        if raidList and raidList[slotID] then
            for _, item in ipairs(raidList[slotID]) do
                if item.itemID and not seen[item.itemID] then
                    seen[item.itemID] = true
                    table.insert(pool[slotID], item)
                end
            end
        end

        -- Add dungeon items (skip dupes)
        if dungeonList and dungeonList[slotID] then
            for _, item in ipairs(dungeonList[slotID]) do
                if item.itemID and not seen[item.itemID] then
                    seen[item.itemID] = true
                    table.insert(pool[slotID], item)
                end
            end
        end
    end

    return pool
end

-- Paired slots: Peavers puts both rings into slot 11, both trinkets into slot 13
-- We need to take top 2 items and spread them across both KDT slots
local PAIRED_SLOTS = {
    [11] = 12,   -- FINGER1 -> FINGER2
    [13] = 14,   -- TRINKET1 -> TRINKET2
}

-- Get BiS with preferred source priority
-- preferSource: "RAID" or "MYTHIC_PLUS" — items from this source are picked first
-- excludeSource: the opposite source, only used as fallback-blocker
-- nil/nil = overall (best from everything)
function KDT:GetBisFromPeaversFiltered(specID, preferSource, excludeSource)
    if not self:IsPeaversBisAvailable() then return nil end
    local classID = SPEC_TO_CLASS[specID]
    if not classID then return nil end

    local pool = CollectAllItems(classID, specID)
    if not pool then return nil end

    local result = {}
    local pairedSecondaryHandled = {}
    local orderedSlotIDs = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}

    -- Helper: from a list of items, pick best by priority with two-tier logic
    -- Tier 1: items matching preferSource
    -- Tier 2: items NOT matching excludeSource (fallback: Crafted, World, PvP, Delve, Unknown)
    -- Returns up to `count` items sorted by priority
    local function PickBestItems(items, count)
        if not items or #items == 0 then return {} end

        -- Split items into preferred and fallback
        local preferred = {}
        local fallback = {}
        for _, item in ipairs(items) do
            local src = ClassifyDropSource(item.dropSource)
            if preferSource and src == preferSource then
                table.insert(preferred, item)
            elseif not excludeSource or src ~= excludeSource then
                table.insert(fallback, item)
            end
        end

        -- Sort both by priority
        table.sort(preferred, function(a, b) return (a.priority or 99) < (b.priority or 99) end)
        table.sort(fallback, function(a, b) return (a.priority or 99) < (b.priority or 99) end)

        -- If no preferSource set (overall mode), just sort everything
        if not preferSource then
            local all = {}
            for _, item in ipairs(items) do table.insert(all, item) end
            table.sort(all, function(a, b) return (a.priority or 99) < (b.priority or 99) end)
            local out = {}
            for i = 1, math.min(count, #all) do out[i] = all[i] end
            return out
        end

        -- Fill results: preferred first, then fallback only for remaining empty slots
        local out = {}
        for i = 1, math.min(count, #preferred) do
            out[#out + 1] = preferred[i]
        end
        -- Only fill remaining slots with fallback
        if #out < count then
            for i = 1, #fallback do
                if #out >= count then break end
                -- Don't add dupes (same itemID)
                local dominated = false
                for _, picked in ipairs(out) do
                    if picked.itemID == fallback[i].itemID then dominated = true; break end
                end
                if not dominated then
                    out[#out + 1] = fallback[i]
                end
            end
        end
        return out
    end

    for _, slotID in ipairs(orderedSlotIDs) do
        local items = pool[slotID]
        local kdtSlot = PEAVERS_SLOT_MAP[slotID]
        if kdtSlot and items and not pairedSecondaryHandled[slotID] then
            local secondarySlotID = PAIRED_SLOTS[slotID]
            local isPaired = secondarySlotID ~= nil

            -- For paired slots, pick top 2; for normal slots, pick top 1
            local neededCount = isPaired and 2 or 1
            local best = PickBestItems(items, neededCount)

            if best[1] then
                result[kdtSlot] = BuildItemEntry(best[1])
            end

            if isPaired then
                local secondaryKdtSlot = PEAVERS_SLOT_MAP[secondarySlotID]
                if secondaryKdtSlot then
                    -- Check if secondary slot has its own data
                    local secondaryPool = pool[secondarySlotID]
                    if secondaryPool and #secondaryPool > 0 then
                        local secBest = PickBestItems(secondaryPool, 1)
                        if secBest[1] then
                            result[secondaryKdtSlot] = BuildItemEntry(secBest[1])
                        end
                    elseif best[2] then
                        result[secondaryKdtSlot] = BuildItemEntry(best[2])
                    end
                    pairedSecondaryHandled[secondarySlotID] = true
                end
            end
        end
    end

    return (next(result) and result) or nil
end

-- Convenience wrappers
function KDT:GetBisFromPeavers(specID, contentType)
    -- Raid tab: prefer RAID drops, exclude M+ drops, fallback to Crafted/World/etc
    -- M+ tab: prefer M+ drops, exclude RAID drops, fallback to Crafted/World/etc
    if contentType == "raid" then
        return self:GetBisFromPeaversFiltered(specID, "RAID", "MYTHIC_PLUS")
    elseif contentType == "dungeon" then
        return self:GetBisFromPeaversFiltered(specID, "MYTHIC_PLUS", "RAID")
    end
    return nil
end

function KDT:GetBisOverallFromPeavers(specID)
    -- No preference, no exclusion = best from ALL sources
    return self:GetBisFromPeaversFiltered(specID, nil, nil)
end

-- =============================================================================
-- ARCHON URL SLUGS
-- =============================================================================

KDT.ARCHON_SPEC_SLUGS = {
    [250] = "blood/death-knight", [251] = "frost/death-knight", [252] = "unholy/death-knight",
    [577] = "havoc/demon-hunter", [581] = "vengeance/demon-hunter", [1480] = "devourer/demon-hunter",
    [102] = "balance/druid", [103] = "feral/druid", [104] = "guardian/druid", [105] = "restoration/druid",
    [1467] = "devastation/evoker", [1468] = "preservation/evoker", [1473] = "augmentation/evoker",
    [253] = "beast-mastery/hunter", [254] = "marksmanship/hunter", [255] = "survival/hunter",
    [62] = "arcane/mage", [63] = "fire/mage", [64] = "frost/mage",
    [268] = "brewmaster/monk", [270] = "mistweaver/monk", [269] = "windwalker/monk",
    [65] = "holy/paladin", [66] = "protection/paladin", [70] = "retribution/paladin",
    [256] = "discipline/priest", [257] = "holy/priest", [258] = "shadow/priest",
    [259] = "assassination/rogue", [260] = "outlaw/rogue", [261] = "subtlety/rogue",
    [262] = "elemental/shaman", [263] = "enhancement/shaman", [264] = "restoration/shaman",
    [265] = "affliction/warlock", [266] = "demonology/warlock", [267] = "destruction/warlock",
    [71] = "arms/warrior", [72] = "fury/warrior", [73] = "protection/warrior",
}

-- =============================================================================
-- ENCHANT & GEM DATA
-- =============================================================================

KDT.ENCHANT_DATA = {
    [223781] = {name = "Authority of Radiant Power", slot = "WEAPON"},
    [223784] = {name = "Authority of the Depths", slot = "WEAPON"},
    [223764] = {name = "Authority of Air", slot = "WEAPON"},
    [223762] = {name = "Authority of Storms", slot = "WEAPON"},
    [223692] = {name = "Crystalline Radiance", slot = "CHEST"},
    [223680] = {name = "Council's Intellect", slot = "CHEST"},
    [223731] = {name = "Chant of Winged Grace", slot = "BACK"},
    [223734] = {name = "Chant of Leeching Fangs", slot = "BACK"},
    [223713] = {name = "Chant of Armored Avoidance", slot = "WRIST"},
    [223716] = {name = "Chant of Armored Leech", slot = "WRIST"},
    [219911] = {name = "Stormbound Armor Kit", slot = "LEGS"},
    [219908] = {name = "Defender's Armor Kit", slot = "LEGS"},
    [223656] = {name = "Defender's March", slot = "FEET"},
    [223653] = {name = "Scout's March", slot = "FEET"},
    [223677] = {name = "Radiant Critical Strike", slot = "RING"},
    [223674] = {name = "Radiant Mastery", slot = "RING"},
    [223683] = {name = "Radiant Versatility", slot = "RING"},
}

KDT.GEM_DATA = {
    [213743] = {name = "Culminating Blasphemite", type = "META", stats = "Crit + Proc"},
    [213746] = {name = "Incandescent Blasphemite", type = "META", stats = "Damage Proc"},
    [213467] = {name = "Deadly Sapphire", type = "EPIC", stats = "Crit/Mastery"},
    [213455] = {name = "Versatile Ruby", type = "EPIC", stats = "Vers/Mastery"},
    [213461] = {name = "Quick Topaz", type = "EPIC", stats = "Haste/Vers"},
    [213458] = {name = "Masterful Emerald", type = "EPIC", stats = "Mastery/Haste"},
}

-- Empty fallback — all real data comes from PeaversBestInSlotData
KDT.BIS_DATA = {}

-- =============================================================================
-- DATA ACCESS FUNCTIONS
-- =============================================================================

function KDT:GetDefaultBisData()
    local data = {}
    for _, slot in ipairs(KDT.SLOT_ORDER) do
        data[slot] = {
            name = "Install PeaversBestInSlotData",
            itemID = 0,
            source = "UNKNOWN",
            sourceDetail = "",
        }
    end
    return data
end

function KDT:GetEnchantName(enchantID)
    local data = KDT.ENCHANT_DATA[enchantID]
    return data and data.name or nil
end

function KDT:GetGemName(gemID)
    local data = KDT.GEM_DATA[gemID]
    return data and data.name or nil
end

function KDT:GetSpecName(specID) 
    if not specID or specID == 0 then return "Unbekannt" end
    return KDT.SPEC_NAMES[specID] or "Unbekannt" 
end

function KDT:GetPlayerSpecID() 
    local spec = GetSpecialization()
    if not spec then return 0 end
    return GetSpecializationInfo(spec) or 0
end

function KDT:GetArchonURL(specID, contentType)
    local slug = KDT.ARCHON_SPEC_SLUGS[specID]
    if not slug then return nil end
    contentType = contentType or "mythic-plus"
    if contentType == "raid" then
        return "https://archon.gg/wow/builds/" .. slug .. "/raid/gear-and-tier-set/mythic/all-bosses"
    end
    return "https://archon.gg/wow/builds/" .. slug .. "/mythic-plus/gear-and-tier-set/10/all-dungeons/this-week"
end

function KDT:HasBisDataForSpec(specID)
    local lookupSpecID = self:GetBaseSpecID(specID)
    if self:IsPeaversBisAvailable() then
        return SPEC_TO_CLASS[lookupSpecID] ~= nil
    end
    return false
end
