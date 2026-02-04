-- Kryos Dungeon Tool
-- Data/BisData.lua - Best in Slot Gear Data with Import System
-- Data Source: Archon.gg (archon.gg/wow/builds) - Live Meta Data
-- Version: 1.7

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
    [577] = "Havoc", [581] = "Vengeance", [1480] = "Devourer",  -- DH has 3 specs in Midnight!
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
-- Maps Hero Talent SpecIDs to their base spec for BiS data lookup
-- Hero Talents don't change gear - they use the same BiS as base spec
-- Note: 1480 (Devourer) is NOT a hero talent - it's a new 3rd DH spec in Midnight
-- =============================================================================
KDT.HERO_SPEC_TO_BASE = {
    -- Add Hero Talent mappings here as needed
    -- Example: [heroTalentSpecID] = baseSpecID,
}

-- Helper function to get base spec ID for BiS lookup
function KDT:GetBaseSpecID(specID)
    return self.HERO_SPEC_TO_BASE[specID] or specID
end

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
-- ENCHANT DATA (Season 3 - TWW 11.2)
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

-- =============================================================================
-- GEM DATA (Season 3 - TWW 11.2)
-- =============================================================================
KDT.GEM_DATA = {
    [213743] = {name = "Culminating Blasphemite", type = "META", stats = "Crit + Proc"},
    [213746] = {name = "Incandescent Blasphemite", type = "META", stats = "Damage Proc"},
    [213467] = {name = "Deadly Sapphire", type = "EPIC", stats = "Crit/Mastery"},
    [213455] = {name = "Versatile Ruby", type = "EPIC", stats = "Vers/Mastery"},
    [213461] = {name = "Quick Topaz", type = "EPIC", stats = "Haste/Vers"},
    [213458] = {name = "Masterful Emerald", type = "EPIC", stats = "Mastery/Haste"},
}

-- =============================================================================
-- DEFAULT BiS DATA (Season 3 - Manaforge Omega - Archon.gg Data)
-- =============================================================================

KDT.BIS_DATA = {
    -- ROGUE - OUTLAW (260)
    [260] = {
        HEAD = { name = "Gatecrasher's Guise", itemID = 237668, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Gatecrasher's Shoulderpads", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Gatecrasher's Vest", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Gatecrasher's Handguards", itemID = 237669, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Gatecrasher's Breeches", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Dagger", itemID = 222442, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Dagger", itemID = 222442, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- ROGUE - ASSASSINATION (259)
    [259] = {
        HEAD = { name = "Gatecrasher's Guise", itemID = 237668, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Gatecrasher's Shoulderpads", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Gatecrasher's Vest", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Gatecrasher's Handguards", itemID = 237669, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Gatecrasher's Breeches", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Dagger", itemID = 222442, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Dagger", itemID = 222442, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- ROGUE - SUBTLETY (261)
    [261] = {
        HEAD = { name = "Gatecrasher's Guise", itemID = 237668, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Gatecrasher's Shoulderpads", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Gatecrasher's Vest", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Gatecrasher's Handguards", itemID = 237669, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Gatecrasher's Breeches", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Dagger", itemID = 222442, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Dagger", itemID = 222442, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- DEMON HUNTER - HAVOC (577) - Updated from Archon.gg 2025-01-29
    [577] = {
        HEAD = { name = "Charhound's Vicious Scalp", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Charhound's Vicious Hornguards", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Charhound's Vicious Bindings", itemID = 237694, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Charhound's Vicious Felclaws", itemID = 237692, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Charhound's Vicious Hidecoat", itemID = 237690, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "MYTHIC_PLUS", sourceDetail = "M+", stats = "Proc" },
        MAINHAND = { name = "Everforged Warglaive", itemID = 222441, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Warglaive", itemID = 222441, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- DEMON HUNTER - VENGEANCE (581)
    [581] = {
        HEAD = { name = "Charhound's Vicious Scalp", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Ornately Engraved Amplifier", itemID = 185842, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom" },
        SHOULDER = { name = "Charhound's Vicious Hornguards", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Charhound's Vicious Bindings", itemID = 237694, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Charhound's Vicious Felclaws", itemID = 237692, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Charhound's Vicious Hidecoat", itemID = 237690, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Ring of the Panoply", itemID = 246281, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Brand of Ceaseless Ire", itemID = 242401, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Warglaive", itemID = 222441, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Warglaive", itemID = 222441, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- DEMON HUNTER - DEVOURER (1480) - New 3rd Spec in Midnight
    -- Data from Archon.gg 2026-02-04
    [1480] = {
        HEAD = { name = "Charhound's Vicious Scalp", itemID = 241765, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Mastery/Haste", gems = {213467} },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 235513, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", gems = {213467, 213467} },
        SHOULDER = { name = "Charhound's Vicious Hornguards", itemID = 241767, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Crit/Vers" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Charhound's Vicious Vest", itemID = 241764, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Mastery/Haste", enchant = 223692 },
        WRIST = { name = "Charhound's Vicious Bindings", itemID = 241768, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Crit/Mastery", enchant = 223713, gems = {213467} },
        HANDS = { name = "Charhound's Vicious Felclaws", itemID = 241769, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Mastery/Crit" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Charhound's Vicious Legguards", itemID = 241766, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Mastery/Haste", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Haste", enchant = 223680, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467, 213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Chant of Winged Grace", itemID = 242389, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Everforged Warglaive", itemID = 234496, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Agi Warglaive", enchant = 223781 },
        OFFHAND = { name = "Collapsing Phaseblades", itemID = 241770, source = "MYTHIC_PLUS", sourceDetail = "Mythic+ Popular", stats = "Agi Dual" },
    },
    
    -- WARRIOR - FURY (72) - Fixed from Archon.gg 2025-01-29
    [72] = {
        HEAD = { name = "Living Weapon's Faceshield", itemID = 237610, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Living Weapon's Ramparts", itemID = 237608, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Living Weapon's Bulwark", itemID = 237613, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Living Weapon's Crushers", itemID = 237611, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Living Weapon's Legguards", itemID = 237609, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "MYTHIC_PLUS", sourceDetail = "Halls of Atonement", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "MYTHIC_PLUS", sourceDetail = "M+", stats = "Proc" },
        MAINHAND = { name = "Circuit Breaker", itemID = 234490, source = "MYTHIC_PLUS", sourceDetail = "Operation Mechagon", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Charged Claymore", itemID = 222447, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- WARRIOR - ARMS (71) - Fixed from Archon.gg 2025-01-29
    [71] = {
        HEAD = { name = "Living Weapon's Faceshield", itemID = 237610, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Living Weapon's Ramparts", itemID = 237608, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Living Weapon's Bulwark", itemID = 237613, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Living Weapon's Crushers", itemID = 237611, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Living Weapon's Legguards", itemID = 237609, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242405, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "MYTHIC_PLUS", sourceDetail = "M+", stats = "Proc" },
        MAINHAND = { name = "Charged Claymore", itemID = 222447, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- WARRIOR - PROTECTION (73) - Fixed from Archon.gg 2025-01-29
    [73] = {
        HEAD = { name = "Living Weapon's Faceshield", itemID = 237610, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Living Weapon's Ramparts", itemID = 237608, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Living Weapon's Bulwark", itemID = 237613, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Living Weapon's Crushers", itemID = 237611, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Living Weapon's Legguards", itemID = 237609, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "High Nerubian Signet", itemID = 221141, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Brand of Ceaseless Ire", itemID = 242401, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Longsword", itemID = 222440, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Charged Defender", itemID = 222446, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- DEATH KNIGHT - FROST (251)
    [251] = {
        HEAD = { name = "Hollow Sentinel's Stonemask", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Hollow Sentinel's Perches", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Hollow Sentinel's Breastplate", itemID = 237631, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Hollow Sentinel's Gauntlets", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Hollow Sentinel's Stonekilt", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Claymore", itemID = 222447, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DEATH KNIGHT - UNHOLY (252)
    [252] = {
        HEAD = { name = "Hollow Sentinel's Stonemask", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Hollow Sentinel's Perches", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Hollow Sentinel's Breastplate", itemID = 237631, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Hollow Sentinel's Gauntlets", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Hollow Sentinel's Stonekilt", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Claymore", itemID = 222447, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DEATH KNIGHT - BLOOD (250)
    [250] = {
        HEAD = { name = "Hollow Sentinel's Stonemask", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Hollow Sentinel's Perches", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Hollow Sentinel's Breastplate", itemID = 237631, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Hollow Sentinel's Gauntlets", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Hollow Sentinel's Stonekilt", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "High Nerubian Signet", itemID = 221141, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Brand of Ceaseless Ire", itemID = 242401, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Claymore", itemID = 222447, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MAGE - FIRE (63)
    [63] = {
        HEAD = { name = "Cowl of the Cryptic Illusionist", itemID = 237680, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Mantle of the Cryptic Illusionist", itemID = 237678, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Cryptic Illusionist", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Gloves of the Cryptic Illusionist", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Trousers of the Cryptic Illusionist", itemID = 237679, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MAGE - FROST (64)
    [64] = {
        HEAD = { name = "Cowl of the Cryptic Illusionist", itemID = 237680, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Mantle of the Cryptic Illusionist", itemID = 237678, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Cryptic Illusionist", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Gloves of the Cryptic Illusionist", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Trousers of the Cryptic Illusionist", itemID = 237679, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "So'leah's Secret Technique", itemID = 190958, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- HUNTER - BEAST MASTERY (253)
    [253] = {
        HEAD = { name = "Deathstalker's Helmet", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Deathstalker's Shoulderguards", itemID = 237654, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Deathstalker's Hauberk", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Deathstalker's Gauntlets", itemID = 237653, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Deathstalker's Leggings", itemID = 237655, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Bow", itemID = 222454, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PALADIN - RETRIBUTION (70)
    [70] = {
        HEAD = { name = "Oathbinder's Faceguard", itemID = 237712, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Oathbinder's Spaulders", itemID = 237710, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Oathbinder's Chestguard", itemID = 237715, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Oathbinder's Gauntlets", itemID = 237713, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Oathbinder's Legguards", itemID = 237711, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Claymore", itemID = 222447, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PRIEST - SHADOW (258)
    [258] = {
        HEAD = { name = "Void-Preacher's Hood", itemID = 237704, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Void-Preacher's Mantle", itemID = 237702, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Void-Preacher's Vestments", itemID = 237707, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Void-Preacher's Gloves", itemID = 237705, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Void-Preacher's Trousers", itemID = 237703, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DRUID - BALANCE (102)
    [102] = {
        HEAD = { name = "Arboreal Cultivator's Mask", itemID = 237640, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Arboreal Cultivator's Mantle", itemID = 237638, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Arboreal Cultivator's Tunic", itemID = 237643, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Arboreal Cultivator's Gloves", itemID = 237641, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Arboreal Cultivator's Leggings", itemID = 237639, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MONK - WINDWALKER (269)
    [269] = {
        HEAD = { name = "Mystic Heron's Hat", itemID = 237648, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Mystic Heron's Shoulderpads", itemID = 237646, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Mystic Heron's Jerkin", itemID = 237651, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Mystic Heron's Handwraps", itemID = 237649, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Mystic Heron's Legguards", itemID = 237647, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Warglaive", itemID = 222441, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Warglaive", itemID = 222441, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- MONK - BREWMASTER (268)
    [268] = {
        HEAD = { name = "Mystic Heron's Hat", itemID = 237648, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Mystic Heron's Shoulderpads", itemID = 237646, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Mystic Heron's Jerkin", itemID = 237651, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Mystic Heron's Handwraps", itemID = 237649, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Mystic Heron's Legguards", itemID = 237647, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Ring of the Panoply", itemID = 246281, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Brand of Ceaseless Ire", itemID = 242401, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MONK - MISTWEAVER (270)
    [270] = {
        HEAD = { name = "Mystic Heron's Hat", itemID = 237648, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Mystic Heron's Shoulderpads", itemID = 237646, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Mystic Heron's Jerkin", itemID = 237651, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Mystic Heron's Handwraps", itemID = 237649, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Mystic Heron's Legguards", itemID = 237647, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MAGE - ARCANE (62)
    [62] = {
        HEAD = { name = "Cowl of the Cryptic Illusionist", itemID = 237680, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Mantle of the Cryptic Illusionist", itemID = 237678, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Cryptic Illusionist", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Gloves of the Cryptic Illusionist", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Trousers of the Cryptic Illusionist", itemID = 237679, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- HUNTER - MARKSMANSHIP (254)
    [254] = {
        HEAD = { name = "Deathstalker's Helmet", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Deathstalker's Shoulderguards", itemID = 237654, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Deathstalker's Hauberk", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Deathstalker's Gauntlets", itemID = 237653, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Deathstalker's Leggings", itemID = 237655, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Bow", itemID = 222454, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- HUNTER - SURVIVAL (255)
    [255] = {
        HEAD = { name = "Deathstalker's Helmet", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Deathstalker's Shoulderguards", itemID = 237654, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Deathstalker's Hauberk", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Deathstalker's Gauntlets", itemID = 237653, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Deathstalker's Leggings", itemID = 237655, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Cursed Stone Idol", itemID = 246344, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Halberd", itemID = 222455, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PALADIN - HOLY (65)
    [65] = {
        HEAD = { name = "Oathbinder's Faceguard", itemID = 237712, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Oathbinder's Spaulders", itemID = 237710, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Oathbinder's Chestguard", itemID = 237715, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Oathbinder's Gauntlets", itemID = 237713, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Oathbinder's Legguards", itemID = 237711, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Longsword", itemID = 222440, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Charged Defender", itemID = 222446, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- PALADIN - PROTECTION (66)
    [66] = {
        HEAD = { name = "Oathbinder's Faceguard", itemID = 237712, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Oathbinder's Spaulders", itemID = 237710, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Oathbinder's Chestguard", itemID = 237715, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Everforged Vambraces", itemID = 222435, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Oathbinder's Gauntlets", itemID = 237713, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Everforged Greatbelt", itemID = 222431, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Oathbinder's Legguards", itemID = 237711, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "High Nerubian Signet", itemID = 221141, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Brand of Ceaseless Ire", itemID = 242401, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Longsword", itemID = 222440, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Charged Defender", itemID = 222446, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- PRIEST - DISCIPLINE (256)
    [256] = {
        HEAD = { name = "Void-Preacher's Hood", itemID = 237704, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Void-Preacher's Mantle", itemID = 237702, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Void-Preacher's Vestments", itemID = 237707, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Void-Preacher's Gloves", itemID = 237705, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Void-Preacher's Trousers", itemID = 237703, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PRIEST - HOLY (257)
    [257] = {
        HEAD = { name = "Void-Preacher's Hood", itemID = 237704, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Void-Preacher's Mantle", itemID = 237702, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Void-Preacher's Vestments", itemID = 237707, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Void-Preacher's Gloves", itemID = 237705, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Void-Preacher's Trousers", itemID = 237703, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DRUID - FERAL (103)
    [103] = {
        HEAD = { name = "Arboreal Cultivator's Mask", itemID = 237640, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Arboreal Cultivator's Mantle", itemID = 237638, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Arboreal Cultivator's Tunic", itemID = 237643, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Arboreal Cultivator's Gloves", itemID = 237641, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Arboreal Cultivator's Leggings", itemID = 237639, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DRUID - GUARDIAN (104)
    [104] = {
        HEAD = { name = "Arboreal Cultivator's Mask", itemID = 237640, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Arboreal Cultivator's Mantle", itemID = 237638, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Arboreal Cultivator's Tunic", itemID = 237643, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Arboreal Cultivator's Gloves", itemID = 237641, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Arboreal Cultivator's Leggings", itemID = 237639, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Ring of the Panoply", itemID = 246281, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Brand of Ceaseless Ire", itemID = 242401, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DRUID - RESTORATION (105)
    [105] = {
        HEAD = { name = "Arboreal Cultivator's Mask", itemID = 237640, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Arboreal Cultivator's Mantle", itemID = 237638, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Arboreal Cultivator's Tunic", itemID = 237643, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Arboreal Cultivator's Gloves", itemID = 237641, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Arboreal Cultivator's Leggings", itemID = 237639, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- SHAMAN - ELEMENTAL (262)
    [262] = {
        HEAD = { name = "Farseer's Mask", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Farseer's Shoulderpads", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Farseer's Chainmail", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Farseer's Grips", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Farseer's Kilt", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Longsword", itemID = 222440, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Charged Defender", itemID = 222446, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- SHAMAN - ENHANCEMENT (263)
    [263] = {
        HEAD = { name = "Farseer's Mask", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Farseer's Shoulderpads", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Farseer's Chainmail", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Farseer's Grips", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Farseer's Kilt", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of the False Accuser", itemID = 178824, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Mace", itemID = 222444, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Everforged Mace", itemID = 222444, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- SHAMAN - RESTORATION (264)
    [264] = {
        HEAD = { name = "Farseer's Mask", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Farseer's Shoulderpads", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Farseer's Chainmail", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Farseer's Grips", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Farseer's Kilt", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Everforged Longsword", itemID = 222440, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = { name = "Charged Defender", itemID = 222446, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223784 },
    },
    
    -- WARLOCK - AFFLICTION (265)
    [265] = {
        HEAD = { name = "Sinister Savant's Gaze", itemID = 237688, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Sinister Savant's Mantle", itemID = 237686, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Sinister Savant's Vestments", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Sinister Savant's Handwraps", itemID = 237687, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Sinister Savant's Breeches", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- WARLOCK - DEMONOLOGY (266)
    [266] = {
        HEAD = { name = "Sinister Savant's Gaze", itemID = 237688, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Sinister Savant's Mantle", itemID = 237686, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Sinister Savant's Vestments", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Sinister Savant's Handwraps", itemID = 237687, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Sinister Savant's Breeches", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- WARLOCK - DESTRUCTION (267)
    [267] = {
        HEAD = { name = "Sinister Savant's Gaze", itemID = 237688, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Sinister Savant's Mantle", itemID = 237686, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Sinister Savant's Vestments", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Weavercloth Wristwraps", itemID = 222424, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Sinister Savant's Handwraps", itemID = 237687, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Weavercloth Sash", itemID = 222420, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Sinister Savant's Breeches", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- EVOKER - DEVASTATION (1467)
    [1467] = {
        HEAD = { name = "Scalecommander's Helmet", itemID = 237720, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Scalecommander's Epaulets", itemID = 237718, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Scalecommander's Chainmail", itemID = 237723, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Scalecommander's Gloves", itemID = 237721, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Scalecommander's Tassets", itemID = 237719, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- EVOKER - PRESERVATION (1468)
    [1468] = {
        HEAD = { name = "Scalecommander's Helmet", itemID = 237720, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Scalecommander's Epaulets", itemID = 237718, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Scalecommander's Chainmail", itemID = 237723, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Scalecommander's Gloves", itemID = 237721, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Scalecommander's Tassets", itemID = 237719, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Creeping Coagulum", itemID = 219312, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- EVOKER - AUGMENTATION (1473)
    [1473] = {
        HEAD = { name = "Scalecommander's Helmet", itemID = 237720, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        NECK = { name = "Amulet of Earthen Craftsmanship", itemID = 215136, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        SHOULDER = { name = "Scalecommander's Epaulets", itemID = 237718, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Scalecommander's Chainmail", itemID = 237723, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom", enchant = 223713 },
        HANDS = { name = "Scalecommander's Gloves", itemID = 237721, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Clasp", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Scalecommander's Tassets", itemID = 237719, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Chainmail Sabatons", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680 },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Custom", enchant = 223680 },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Proc" },
        MAINHAND = { name = "Charged Runestaff", itemID = 222453, source = "CRAFTED", sourceDetail = "Crafting", stats = "Weapon", enchant = 223781 },
        OFFHAND = nil,
    },
}

-- =============================================================================
-- DATA ACCESS FUNCTIONS
-- =============================================================================

function KDT:GetBisForSpec(specID)
    if KDT.BIS_IMPORTED and KDT.BIS_IMPORTED[specID] and KDT.BIS_IMPORTED[specID].slots then
        local result = {}
        for slot, data in pairs(KDT.BIS_IMPORTED[specID].slots) do
            result[slot] = { name = data.name, itemID = data.id, source = data.source, sourceDetail = data.detail, stats = data.stats or "", enchant = data.enchant, gems = data.gems }
        end
        return result
    end
    if KDT.BIS_DATA[specID] then return KDT.BIS_DATA[specID] end
    return KDT:GetDefaultBisData()
end

function KDT:GetDefaultBisData()
    return {
        HEAD = { name = "Use /kdt import", itemID = 0, source = "UNKNOWN", sourceDetail = "Import data", stats = "" },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Universal" },
        SHOULDER = { name = "Use /kdt import", itemID = 0, source = "UNKNOWN", sourceDetail = "Import data", stats = "" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive" },
        CHEST = { name = "Use /kdt import", itemID = 0, source = "UNKNOWN", sourceDetail = "Import data", stats = "" },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        HANDS = { name = "Right-click to edit", itemID = 0, source = "UNKNOWN", sourceDetail = "", stats = "" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Crafting", stats = "Custom" },
        LEGS = { name = "Right-click to edit", itemID = 0, source = "UNKNOWN", sourceDetail = "", stats = "" },
        FEET = { name = "Right-click to edit", itemID = 0, source = "UNKNOWN", sourceDetail = "", stats = "" },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom" },
        FINGER2 = { name = "Right-click to edit", itemID = 0, source = "UNKNOWN", sourceDetail = "", stats = "" },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Universal" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Universal" },
        MAINHAND = { name = "Right-click to edit", itemID = 0, source = "UNKNOWN", sourceDetail = "", stats = "" },
        OFFHAND = { name = "Right-click to edit", itemID = 0, source = "UNKNOWN", sourceDetail = "", stats = "" },
    }
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
    local specID = GetSpecializationInfo(spec)
    return specID or 0
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
    return KDT.BIS_DATA[lookupSpecID] ~= nil
end
