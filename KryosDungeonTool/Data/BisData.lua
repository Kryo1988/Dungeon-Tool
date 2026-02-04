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
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", gems = {213743, 213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Tactical Vest of the Sudden Eclipse", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Armbands of the Sudden Eclipse", itemID = 237660, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of Haunting Fixation", itemID = 178832, source = "MYTHIC_PLUS", sourceDetail = "Halls of Atonement", stats = "Haste/Crit" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Pants of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Ergospheric Cudgel", itemID = 237731, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223781 },
        OFFHAND = { name = "Geezle's Coercive Volt-Ohmmeter", itemID = 234493, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223784 },        
    },
    
    -- ROGUE - ASSASSINATION (259)
    [259] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Tactical Vest of the Sudden Eclipse", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Armbands of the Sudden Eclipse", itemID = 237660, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Pants of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Ergospheric Cudgel", itemID = 237731, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223781 },
        OFFHAND = { name = "Geezle's Coercive Volt-Ohmmeter", itemID = 234493, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223784 },        
    },
    
    -- ROGUE - SUBTLETY (261)
    [261] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Tactical Vest of the Sudden Eclipse", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Armbands of the Sudden Eclipse", itemID = 237660, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Pants of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Ergospheric Cudgel", itemID = 237731, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223781 },
        OFFHAND = { name = "Geezle's Coercive Volt-Ohmmeter", itemID = 234493, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223784 },        
    },
    
    -- DEMON HUNTER - HAVOC (577) - Updated from Archon.gg 2025-01-29
    [577] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Warglaive", itemID = 237736, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Warglaive", enchant = 223781 },
        OFFHAND = { name = "Voidglass Warglaive", itemID = 237736, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Warglaive", enchant = 223784 },        
    },
    
    -- DEMON HUNTER - VENGEANCE (581)
    [581] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Warglaive", itemID = 237736, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Warglaive", enchant = 223781 },
        OFFHAND = { name = "Voidglass Warglaive", itemID = 237736, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Warglaive", enchant = 223784 },
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
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Warbelt", itemID = 219336, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Greatsword", itemID = 237732, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", enchant = 223781 },
        OFFHAND = { name = "Voidglass Greatsword", itemID = 237732, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", enchant = 223781 },        
    },
    
    -- WARRIOR - ARMS (71) - Fixed from Archon.gg 2025-01-29
    [71] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Warbelt", itemID = 219336, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Greatsword", itemID = 237732, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", enchant = 223781 },        
        OFFHAND = nil,
    },
    
    -- WARRIOR - PROTECTION (73) - Fixed from Archon.gg 2025-01-29
    [73] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Warbelt", itemID = 219336, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Bulwarkblade", itemID = 237733, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", enchant = 223781 },
        OFFHAND = { name = "Voidglass Shield", itemID = 237735, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Shield" },
    },
    
    -- DEATH KNIGHT - FROST (251)
    [251] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Deathbelt", itemID = 219338, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Ergospheric Cudgel", itemID = 237731, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", enchant = 223781 },
        OFFHAND = { name = "Geezle's Coercive Volt-Ohmmeter", itemID = 234493, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", enchant = 223784 },        
    },
    
    -- DEATH KNIGHT - UNHOLY (252)
    [252] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Deathbelt", itemID = 219338, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Greatsword", itemID = 237732, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DEATH KNIGHT - BLOOD (250)
    [250] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Vers", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Deathbelt", itemID = 219338, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Vers", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Vers", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Vers", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Greatsword", itemID = 237732, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", enchant = 223781 },        
        OFFHAND = nil,
    },
    
    -- MAGE - FIRE (63)
    [63] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- MAGE - FROST (64)
    [64] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- HUNTER - BEAST MASTERY (253)
    [253] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Ergospheric Longbow", itemID = 237738, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Bow", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PALADIN - RETRIBUTION (70)
    [70] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Lightbelt", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Greatsword", itemID = 237732, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PRIEST - SHADOW (258)
    [258] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- DRUID - BALANCE (102)
    [102] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Wildbelt", itemID = 219332, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- MONK - WINDWALKER (269)
    [269] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Serenity Belt", itemID = 219335, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Fistweapon", itemID = 237740, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Fist", enchant = 223781 },
        OFFHAND = { name = "Voidglass Fistweapon", itemID = 237740, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Fist", enchant = 223784 },
    },
    
    -- MONK - BREWMASTER (268)
    [268] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Serenity Belt", itemID = 219335, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Staff", itemID = 237737, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Staff", enchant = 223781 },        
        OFFHAND = nil,
    },
    
    -- MONK - MISTWEAVER (270)
    [270] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Serenity Belt", itemID = 219335, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Staff", itemID = 237737, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", enchant = 223781 },        
        OFFHAND = nil,
    },
    
    -- MAGE - ARCANE (62)
    [62] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- HUNTER - MARKSMANSHIP (254)
    [254] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Ergospheric Longbow", itemID = 237738, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Bow", enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- HUNTER - SURVIVAL (255)
    [255] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Spear", itemID = 237739, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Polearm", enchant = 223781 },
        OFFHAND = { name = "Ergospheric Longbow", itemID = 237738, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Bow" },
    },
    
    -- PALADIN - HOLY (65)
    [65] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Lightbelt", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Hammer", itemID = 237741, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Voidglass Shield", itemID = 237735, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Shield" },        
    },
    
    -- PALADIN - PROTECTION (66)
    [66] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Lightbelt", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Greaves", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc" },
        MAINHAND = { name = "Voidglass Bulwarkblade", itemID = 237733, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", enchant = 223781 },
        OFFHAND = { name = "Voidglass Shield", itemID = 237735, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Shield" },
    },
    
    -- PRIEST - DISCIPLINE (256)
    [256] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- PRIEST - HOLY (257)
    [257] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- DRUID - FERAL (103)
    [103] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Staff", itemID = 237737, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Staff", enchant = 223781 },        
        OFFHAND = nil,
    },
    
    -- DRUID - GUARDIAN (104)
    [104] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Vest of the Sudden Eclipse", itemID = 237670, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Wildbelt", itemID = 219332, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237671, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Voidglass Staff", itemID = 237737, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Staff", enchant = 223781 },        
        OFFHAND = nil,
    },
    
    -- DRUID - RESTORATION (105)
    [105] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Wildbelt", itemID = 219332, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- SHAMAN - ELEMENTAL (262)
    [262] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Totemic Belt", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- SHAMAN - ENHANCEMENT (263)
    [263] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467, 213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Totemic Belt", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc" },
        MAINHAND = { name = "Ergospheric Cudgel", itemID = 237731, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223781 },
        OFFHAND = { name = "Geezle's Coercive Volt-Ohmmeter", itemID = 234493, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", enchant = 223784 },        
    },
    
    -- SHAMAN - RESTORATION (264)
    [264] = {
        HEAD = { name = "Helm of the Sudden Eclipse", itemID = 237658, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Pauldrons of the Sudden Eclipse", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Battleplate of the Sudden Eclipse", itemID = 237661, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Stormbound Shackles", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Sudden Eclipse", itemID = 237659, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Totemic Belt", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Legplates of the Sudden Eclipse", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- WARLOCK - AFFLICTION (265)
    [265] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- WARLOCK - DEMONOLOGY (266)
    [266] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },        
    },
    
    -- WARLOCK - DESTRUCTION (267)
    [267] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Soulbelt", itemID = 219337, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- EVOKER - DEVASTATION (1467)
    [1467] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Scale-Belt", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- EVOKER - PRESERVATION (1468)
    [1468] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Scale-Belt", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
    },
    
    -- EVOKER - AUGMENTATION (1473)
    [1473] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", gems = {213467,213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", enchant = 223731 },
        CHEST = { name = "Robes of the Sudden Eclipse", itemID = 237666, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 223692 },
        WRIST = { name = "Consecrated Cuffs", itemID = 219339, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier" },
        WAIST = { name = "Rune-Bound Scale-Belt", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", gems = {213467} },
        LEGS = { name = "Leggings of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", enchant = 219911 },
        FEET = { name = "Interloper's Silken Striders", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223656 },
        FINGER1 = { name = "Logic Gate: Alpha", itemID = 242405, source = "MYTHIC_PLUS", sourceDetail = "Plexus Sentinel", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242402, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", enchant = 223680, gems = {213467,213467} },
        TRINKET1 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        TRINKET2 = { name = "Araz's Ritual Forge", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc" },
        MAINHAND = { name = "Voidglass Sovereign's Blade", itemID = 237734, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int 1H", enchant = 223781 },
        OFFHAND = { name = "Vagabond's Torch", itemID = 222566, source = "CRAFTED", sourceDetail = "Inscription", stats = "Int Offhand" },
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
