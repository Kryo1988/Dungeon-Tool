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
    [577] = "Havoc", [581] = "Vengeance",
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

KDT.ARCHON_SPEC_SLUGS = {
    [250] = "blood/death-knight", [251] = "frost/death-knight", [252] = "unholy/death-knight",
    [577] = "havoc/demon-hunter", [581] = "vengeance/demon-hunter",
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
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 91.2, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 36.4, gems = {213743, 213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 91.4 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Tactical Vest of the Sudden Eclipse", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 97.0, enchant = 223692 },
        WRIST = { name = "Armbands of the Sudden Eclipse", itemID = 237660, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 40.1, enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of Haunting Fixation", itemID = 178832, source = "MYTHIC_PLUS", sourceDetail = "Halls of Atonement", stats = "Haste/Crit", popularity = 11.7 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 41.8, gems = {213467} },
        LEGS = { name = "Pants of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.7, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 85.5, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 76.5, enchant = 223680, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 24.0, enchant = 223680, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 66.3 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 58.9 },
        MAINHAND = { name = "Ergospheric Cudgel", itemID = 237731, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", popularity = 21.0, enchant = 223781 },
        OFFHAND = { name = "Geezle's Coercive Volt-Ohmmeter", itemID = 234493, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi 1H", popularity = 15.6, enchant = 223784 },
    },
    
    -- ROGUE - ASSASSINATION (259)
    [259] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.5, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 35.0, gems = {213743, 213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Tactical Vest of the Sudden Eclipse", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 95.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 68.2, enchant = 223713, gems = {213467} },
        HANDS = { name = "Deathgrips of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", popularity = 55.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213467} },
        LEGS = { name = "Pants of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 80.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 75.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242405, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 20.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Ara-Kara Sacbrood", itemID = 219314, source = "MYTHIC_PLUS", sourceDetail = "Ara-Kara", stats = "Int + Proc", popularity = 45.0 },
        MAINHAND = { name = "Vengeful Netherspike", itemID = 237740, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Dagger", popularity = 30.0, enchant = 223781 },
        OFFHAND = { name = "Prodigious Gene Splicer", itemID = 237729, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Dagger", popularity = 25.0, enchant = 223784 },
    },
    
    -- ROGUE - SUBTLETY (261)
    [261] = {
        HEAD = { name = "Hood of the Sudden Eclipse", itemID = 237664, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 34.0, gems = {213743, 213467} },
        SHOULDER = { name = "Smokemantle of the Sudden Eclipse", itemID = 237662, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Tactical Vest of the Sudden Eclipse", itemID = 237667, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 65.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Deathgrips of the Sudden Eclipse", itemID = 237665, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", popularity = 52.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 42.0, gems = {213467} },
        LEGS = { name = "Pants of the Sudden Eclipse", itemID = 237663, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 74.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 22.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 58.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 52.0 },
        MAINHAND = { name = "Vengeful Netherspike", itemID = 237740, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Dagger", popularity = 35.0, enchant = 223781 },
        OFFHAND = { name = "Prodigious Gene Splicer", itemID = 237729, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Dagger", popularity = 28.0, enchant = 223784 },
    },
    
    -- DEMON HUNTER - HAVOC (577)
    [577] = {
        HEAD = { name = "Nexus of the Charhound's Hunt", itemID = 237620, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 40.0, gems = {213743, 213467} },
        SHOULDER = { name = "Shoulderpads of the Charhound's Hunt", itemID = 237618, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 91.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Nexus Wraps of the Charhound's Hunt", itemID = 237621, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 95.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 83.7, enchant = 223713, gems = {213467} },
        HANDS = { name = "Grips of the Charhound's Hunt", itemID = 237617, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 50.0, gems = {213467} },
        LEGS = { name = "Trousers of the Charhound's Hunt", itemID = 237619, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 60.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 82.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 78.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 25.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 65.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 55.0 },
        MAINHAND = { name = "Void Reaper's Warglaive", itemID = 242368, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Glaive", popularity = 45.0, enchant = 223781 },
        OFFHAND = { name = "Void Reaper's Claw", itemID = 242368, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Glaive", popularity = 45.0, enchant = 223784 },
    },
    
    -- DEMON HUNTER - VENGEANCE (581)
    [581] = {
        HEAD = { name = "Nexus of the Charhound's Hunt", itemID = 237620, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 35.0, gems = {213743, 213455} },
        SHOULDER = { name = "Shoulderpads of the Charhound's Hunt", itemID = 237618, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Nexus Wraps of the Charhound's Hunt", itemID = 237621, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 49.3, enchant = 223713, gems = {213455} },
        HANDS = { name = "Grips of the Charhound's Hunt", itemID = 237617, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 80.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213455} },
        LEGS = { name = "Trousers of the Charhound's Hunt", itemID = 237619, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 55.0, enchant = 219908 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 75.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 20.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Unyielding Netherprism", itemID = 242396, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tank Proc", popularity = 55.0 },
        TRINKET2 = { name = "Improvised Seaforium Pacemaker", itemID = 232541, source = "MYTHIC_PLUS", sourceDetail = "Operation: Floodgate", stats = "On-Use", popularity = 40.0 },
        MAINHAND = { name = "Void Reaper's Warglaive", itemID = 242368, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Glaive", popularity = 40.0, enchant = 223663 },
        OFFHAND = { name = "Void Reaper's Claw", itemID = 242368, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Glaive", popularity = 40.0, enchant = 223663 },
    },
    
    -- WARRIOR - FURY (72)
    [72] = {
        HEAD = { name = "Casque of the Living Weapon", itemID = 237700, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 38.0, gems = {213743, 213455} },
        SHOULDER = { name = "Shoulderguards of the Living Weapon", itemID = 237698, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hauberk of the Living Weapon", itemID = 237701, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213455} },
        HANDS = { name = "Gauntlets of the Living Weapon", itemID = 237697, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 48.0, gems = {213455} },
        LEGS = { name = "Greaves of the Living Weapon", itemID = 237699, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 75.0, enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 80.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223680, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 28.0, enchant = 223680, gems = {213455, 213455} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Improvised Seaforium Pacemaker", itemID = 232541, source = "MYTHIC_PLUS", sourceDetail = "Operation: Floodgate", stats = "On-Use", popularity = 50.0 },
        MAINHAND = { name = "Void Reaper's Edge", itemID = 242369, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", popularity = 40.0, enchant = 223781 },
        OFFHAND = { name = "Void Reaper's Edge", itemID = 242369, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", popularity = 40.0, enchant = 223784 },
    },
    
    -- WARRIOR - ARMS (71)
    [71] = {
        HEAD = { name = "Casque of the Living Weapon", itemID = 237700, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 35.0, gems = {213743, 213467} },
        SHOULDER = { name = "Shoulderguards of the Living Weapon", itemID = 237698, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hauberk of the Living Weapon", itemID = 237701, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Living Weapon", itemID = 237697, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 45.0, gems = {213467} },
        LEGS = { name = "Greaves of the Living Weapon", itemID = 237699, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 72.0, enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242405, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 22.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 58.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Reaper's Greatsword", itemID = 242367, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", popularity = 55.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- WARRIOR - PROTECTION (73)
    [73] = {
        HEAD = { name = "Casque of the Living Weapon", itemID = 237700, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 32.0, gems = {213743, 213455} },
        SHOULDER = { name = "Shoulderguards of the Living Weapon", itemID = 237698, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hauberk of the Living Weapon", itemID = 237701, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 48.0, enchant = 223716, gems = {213455} },
        HANDS = { name = "Gauntlets of the Living Weapon", itemID = 237697, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 78.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 42.0, gems = {213455} },
        LEGS = { name = "Greaves of the Living Weapon", itemID = 237699, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219908 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 72.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 65.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 18.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Unyielding Netherprism", itemID = 242396, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tank Proc", popularity = 58.0 },
        TRINKET2 = { name = "Improvised Seaforium Pacemaker", itemID = 232541, source = "MYTHIC_PLUS", sourceDetail = "Operation: Floodgate", stats = "On-Use", popularity = 45.0 },
        MAINHAND = { name = "Void Reaper's Edge", itemID = 242369, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", popularity = 35.0, enchant = 223663 },
        OFFHAND = { name = "Shield", itemID = 0, source = "RAID", sourceDetail = "Various", stats = "Shield", popularity = 100.0 },
    },
    
    -- DEATH KNIGHT - FROST (251)
    [251] = {
        HEAD = { name = "Gaze of the Frozen Nightmare", itemID = 237636, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 38.0, gems = {213743, 213467} },
        SHOULDER = { name = "Blight-Kin Pauldrons", itemID = 237634, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Chestguard of Forsaken Souls", itemID = 237637, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Grips of the Frozen Nightmare", itemID = 237633, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 48.0, gems = {213467} },
        LEGS = { name = "Legguards of the Frozen Nightmare", itemID = 237635, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 26.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Improvised Seaforium Pacemaker", itemID = 232541, source = "MYTHIC_PLUS", sourceDetail = "Operation: Floodgate", stats = "On-Use", popularity = 48.0 },
        MAINHAND = { name = "Void Reaper's Edge", itemID = 242369, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", popularity = 45.0, enchant = 223781 },
        OFFHAND = { name = "Void Reaper's Edge", itemID = 242369, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", popularity = 45.0, enchant = 223784 },
    },
    
    -- DEATH KNIGHT - UNHOLY (252)
    [252] = {
        HEAD = { name = "Gaze of the Frozen Nightmare", itemID = 237636, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213458} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 35.0, gems = {213743, 213458} },
        SHOULDER = { name = "Blight-Kin Pauldrons", itemID = 237634, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Chestguard of Forsaken Souls", itemID = 237637, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213458} },
        HANDS = { name = "Grips of the Frozen Nightmare", itemID = 237633, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 82.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 45.0, gems = {213458} },
        LEGS = { name = "Legguards of the Frozen Nightmare", itemID = 237635, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 75.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223674, gems = {213458, 213458} },
        FINGER2 = { name = "Band of the Shattered Soul", itemID = 242405, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 22.0, enchant = 223674, gems = {213458, 213458} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 58.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 50.0 },
        MAINHAND = { name = "Void Reaper's Greatsword", itemID = 242367, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", popularity = 52.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DEATH KNIGHT - BLOOD (250)
    [250] = {
        HEAD = { name = "Gaze of the Frozen Nightmare", itemID = 237636, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 32.0, gems = {213743, 213455} },
        SHOULDER = { name = "Blight-Kin Pauldrons", itemID = 237634, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Chestguard of Forsaken Souls", itemID = 237637, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 48.0, enchant = 223716, gems = {213455} },
        HANDS = { name = "Grips of the Frozen Nightmare", itemID = 237633, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 78.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 42.0, gems = {213455} },
        LEGS = { name = "Legguards of the Frozen Nightmare", itemID = 237635, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 65.0, enchant = 219908 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 72.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 65.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 18.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Unyielding Netherprism", itemID = 242396, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tank Proc", popularity = 55.0 },
        TRINKET2 = { name = "Improvised Seaforium Pacemaker", itemID = 232541, source = "MYTHIC_PLUS", sourceDetail = "Operation: Floodgate", stats = "On-Use", popularity = 42.0 },
        MAINHAND = { name = "Void Reaper's Greatsword", itemID = 242367, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", popularity = 48.0, enchant = 223663 },
        OFFHAND = nil,
    },
    
    -- MAGE - FIRE (63)
    [63] = {
        HEAD = { name = "Cowl of the Cryptic Illusionist", itemID = 237680, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 91.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 40.0, gems = {213743, 213461} },
        SHOULDER = { name = "Mantle of the Cryptic Illusionist", itemID = 237678, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Robes of the Cryptic Illusionist", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 95.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Cuffs", itemID = 219334, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 58.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Gloves of the Cryptic Illusionist", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219331, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 50.0, gems = {213461} },
        LEGS = { name = "Trousers of the Cryptic Illusionist", itemID = 237679, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 72.0, enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 80.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 75.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 28.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 55.0 },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 48.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MAGE - FROST (64)
    [64] = {
        HEAD = { name = "Cowl of the Cryptic Illusionist", itemID = 237680, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 38.0, gems = {213743, 213467} },
        SHOULDER = { name = "Mantle of the Cryptic Illusionist", itemID = 237678, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Robes of the Cryptic Illusionist", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 93.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Cuffs", itemID = 219334, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Cryptic Illusionist", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219331, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 48.0, gems = {213467} },
        LEGS = { name = "Trousers of the Cryptic Illusionist", itemID = 237679, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 73.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 25.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 58.0 },
        TRINKET2 = { name = "So'leah's Secret Technique", itemID = 190958, source = "MYTHIC_PLUS", sourceDetail = "Tazavesh: Gambit", stats = "Int + Crit", popularity = 45.0 },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 45.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- HUNTER - BEAST MASTERY (253)
    [253] = {
        HEAD = { name = "Helm of the Deathstalker", itemID = 237656, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 36.0, gems = {213743, 213467} },
        SHOULDER = { name = "Shoulderguards of the Deathstalker", itemID = 237654, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Chestguard of the Deathstalker", itemID = 237657, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Grips of the Deathstalker", itemID = 237653, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 82.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213467} },
        LEGS = { name = "Legguards of the Deathstalker", itemID = 237655, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 75.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 22.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 58.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 50.0 },
        MAINHAND = { name = "Void Reaper's Longbow", itemID = 242370, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Ranged", popularity = 55.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PALADIN - RETRIBUTION (70)
    [70] = {
        HEAD = { name = "Casque of the Twilight Arbiter", itemID = 237692, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 38.0, gems = {213743, 213467} },
        SHOULDER = { name = "Shoulderplates of the Twilight Arbiter", itemID = 237690, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Breastplate of the Twilight Arbiter", itemID = 237693, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219334, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Gauntlets of the Twilight Arbiter", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219331, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 48.0, gems = {213467} },
        LEGS = { name = "Greaves of the Twilight Arbiter", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 72.0, enchant = 219911 },
        FEET = { name = "Interloper's Plated Sabatons", itemID = 243304, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 26.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Improvised Seaforium Pacemaker", itemID = 232541, source = "MYTHIC_PLUS", sourceDetail = "Operation: Floodgate", stats = "On-Use", popularity = 48.0 },
        MAINHAND = { name = "Void Reaper's Greatsword", itemID = 242367, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 2H", popularity = 55.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- PRIEST - SHADOW (258)
    [258] = {
        HEAD = { name = "Cowl of the Devoured", itemID = 237712, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 40.0, gems = {213743, 213461} },
        SHOULDER = { name = "Mantle of the Devoured", itemID = 237710, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Vestments of the Devoured", itemID = 237713, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Cuffs", itemID = 219334, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Gloves of the Devoured", itemID = 237709, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219331, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 48.0, gems = {213461} },
        LEGS = { name = "Trousers of the Devoured", itemID = 237711, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Interloper's Woven Slippers", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 73.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 26.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Screams of a Forgotten Sky", itemID = 242398, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 52.0 },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 48.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- DRUID - BALANCE (102)
    [102] = {
        HEAD = { name = "Cowl of the Verdant Guardian", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0, gems = {213458} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 38.0, gems = {213743, 213458} },
        SHOULDER = { name = "Mantle of the Verdant Guardian", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Robes of the Verdant Guardian", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 93.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213458} },
        HANDS = { name = "Grips of the Verdant Guardian", itemID = 237625, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 48.0, gems = {213458} },
        LEGS = { name = "Trousers of the Verdant Guardian", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223674, gems = {213458, 213458} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 24.0, enchant = 223674, gems = {213458, 213458} },
        TRINKET1 = { name = "Araz's Ritual Forge", itemID = 242399, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 58.0 },
        TRINKET2 = { name = "So'leah's Secret Technique", itemID = 190958, source = "MYTHIC_PLUS", sourceDetail = "Tazavesh: Gambit", stats = "Int + Crit", popularity = 48.0 },
        MAINHAND = { name = "Ergospheric Shiftstaff", itemID = 237730, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 50.0, enchant = 223781 },
        OFFHAND = nil,
    },
    
    -- MONK - WINDWALKER (269)
    [269] = {
        HEAD = { name = "Helm of the Storm Ascendant", itemID = 237684, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 38.0, gems = {213743, 213455} },
        SHOULDER = { name = "Shoulderguards of the Storm Ascendant", itemID = 237682, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Vest of the Storm Ascendant", itemID = 237685, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213455} },
        HANDS = { name = "Grips of the Storm Ascendant", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 48.0, gems = {213455} },
        LEGS = { name = "Legguards of the Storm Ascendant", itemID = 237683, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 73.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 25.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 52.0 },
        MAINHAND = { name = "Void Reaper's Fist", itemID = 242371, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Fist", popularity = 45.0, enchant = 223781 },
        OFFHAND = { name = "Void Reaper's Fist", itemID = 242371, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Fist", popularity = 45.0, enchant = 223784 },
    },
    
    -- MONK - BREWMASTER (268)
    [268] = {
        HEAD = { name = "Helm of the Storm Ascendant", itemID = 237684, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 40.0, gems = {213743, 213455} },
        SHOULDER = { name = "Shoulderguards of the Storm Ascendant", itemID = 237682, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223734 },
        CHEST = { name = "Vest of the Storm Ascendant", itemID = 237685, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 58.0, enchant = 223716, gems = {213455} },
        HANDS = { name = "Grips of the Storm Ascendant", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 50.0, gems = {213455} },
        LEGS = { name = "Legguards of the Storm Ascendant", itemID = 237683, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219908 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 75.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 28.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Infinitely Divisible Ooze", itemID = 178769, source = "MYTHIC_PLUS", sourceDetail = "Priory of the Sacred Flame", stats = "Agi + Absorb", popularity = 55.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Reaper's Quarterstaff", itemID = 242372, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Staff", popularity = 60.0, enchant = 223781 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- MONK - MISTWEAVER (270)
    [270] = {
        HEAD = { name = "Helm of the Storm Ascendant", itemID = 237684, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 42.0, gems = {213746, 213461} },
        SHOULDER = { name = "Shoulderguards of the Storm Ascendant", itemID = 237682, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Vest of the Storm Ascendant", itemID = 237685, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Grips of the Storm Ascendant", itemID = 237681, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 80.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213461} },
        LEGS = { name = "Legguards of the Storm Ascendant", itemID = 237683, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 65.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 72.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 68.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 30.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 50.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 45.0 },
        MAINHAND = { name = "Void Instrument of Mending", itemID = 242388, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 55.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- MAGE - ARCANE (62)
    [62] = {
        HEAD = { name = "Hexflame Arcanist's Hood", itemID = 237712, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213458} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", popularity = 38.0, gems = {213743, 213458} },
        SHOULDER = { name = "Hexflame Arcanist's Mantle", itemID = 237710, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hexflame Arcanist's Vestment", itemID = 237713, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 93.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219335, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 60.0, enchant = 223713, gems = {213458} },
        HANDS = { name = "Hexflame Arcanist's Handwraps", itemID = 237709, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219332, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 48.0, gems = {213458} },
        LEGS = { name = "Hexflame Arcanist's Leggings", itemID = 237711, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 72.0, enchant = 219911 },
        FEET = { name = "Slippers of Astral Geometry", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Vers", popularity = 78.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223674, gems = {213458, 213458} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 28.0, enchant = 223674, gems = {213458, 213458} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 55.0 },
        MAINHAND = { name = "Void Instrument of Annihilation", itemID = 242387, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 65.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- HUNTER - MARKSMANSHIP (254)
    [254] = {
        HEAD = { name = "Thunderspeaker's Crest", itemID = 237676, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", popularity = 36.0, gems = {213743, 213467} },
        SHOULDER = { name = "Thunderspeaker's Shoulderpads", itemID = 237674, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Thunderspeaker's Chainmail", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 93.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Thunderspeaker's Gauntlets", itemID = 237673, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 48.0, gems = {213467} },
        LEGS = { name = "Thunderspeaker's Legguards", itemID = 237675, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 76.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 26.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 64.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 56.0 },
        MAINHAND = { name = "Sharpshooter's Void Rifle", itemID = 242374, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Gun", popularity = 70.0, enchant = 223781 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (Ranged)", stats = "", popularity = 0 },
    },
    
    -- HUNTER - SURVIVAL (255)
    [255] = {
        HEAD = { name = "Thunderspeaker's Crest", itemID = 237676, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", popularity = 38.0, gems = {213743, 213461} },
        SHOULDER = { name = "Thunderspeaker's Shoulderpads", itemID = 237674, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Thunderspeaker's Chainmail", itemID = 237677, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 91.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 58.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Thunderspeaker's Gauntlets", itemID = 237673, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 82.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 50.0, gems = {213461} },
        LEGS = { name = "Thunderspeaker's Legguards", itemID = 237675, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 74.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 28.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Ara-Kara Sacbrood", itemID = 219314, source = "MYTHIC_PLUS", sourceDetail = "Ara-Kara", stats = "Agi + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Reaper's Polearm", itemID = 242373, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Polearm", popularity = 65.0, enchant = 223781 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- PALADIN - HOLY (65)
    [65] = {
        HEAD = { name = "Righteous Crusader's Helm", itemID = 237644, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", popularity = 40.0, gems = {213746, 213461} },
        SHOULDER = { name = "Righteous Crusader's Spaulders", itemID = 237642, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Righteous Crusader's Breastplate", itemID = 237645, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Vambraces", itemID = 219336, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Righteous Crusader's Gauntlets", itemID = 237641, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 82.0 },
        WAIST = { name = "Rune-Branded Greatbelt", itemID = 219329, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 50.0, gems = {213461} },
        LEGS = { name = "Righteous Crusader's Legguards", itemID = 237643, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Greaves of Divine Judgment", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", popularity = 75.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 30.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 52.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Mace of Sanctification", itemID = 242383, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Mace", popularity = 45.0, enchant = 223764 },
        OFFHAND = { name = "Void Shield of Faith", itemID = 242389, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Shield", popularity = 40.0 },
    },
    
    -- PALADIN - PROTECTION (66)
    [66] = {
        HEAD = { name = "Righteous Crusader's Helm", itemID = 237644, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 42.0, gems = {213743, 213455} },
        SHOULDER = { name = "Righteous Crusader's Spaulders", itemID = 237642, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223734 },
        CHEST = { name = "Righteous Crusader's Breastplate", itemID = 237645, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Vambraces", itemID = 219336, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 60.0, enchant = 223716, gems = {213455} },
        HANDS = { name = "Righteous Crusader's Gauntlets", itemID = 237641, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Greatbelt", itemID = 219329, source = "CRAFTED", sourceDetail = "Blacksmithing", stats = "Custom", popularity = 52.0, gems = {213455} },
        LEGS = { name = "Righteous Crusader's Legguards", itemID = 237643, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219908 },
        FEET = { name = "Greaves of Divine Judgment", itemID = 243308, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 32.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Infinitely Divisible Ooze", itemID = 178769, source = "MYTHIC_PLUS", sourceDetail = "Priory of the Sacred Flame", stats = "Str + Absorb", popularity = 58.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str + Proc", popularity = 50.0 },
        MAINHAND = { name = "Void Blade of Retribution", itemID = 242381, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Str 1H", popularity = 55.0, enchant = 223781 },
        OFFHAND = { name = "Void Fortress Shield", itemID = 242390, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Shield", popularity = 52.0 },
    },
    
    -- PRIEST - DISCIPLINE (256)
    [256] = {
        HEAD = { name = "Benevolent Invoker's Cowl", itemID = 237652, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", popularity = 40.0, gems = {213746, 213461} },
        SHOULDER = { name = "Benevolent Invoker's Mantle", itemID = 237650, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Benevolent Invoker's Vestment", itemID = 237653, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219335, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Benevolent Invoker's Gloves", itemID = 237649, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219332, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 48.0, gems = {213461} },
        LEGS = { name = "Benevolent Invoker's Leggings", itemID = 237651, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Slippers of Astral Geometry", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 75.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 30.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 52.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Staff of Atonement", itemID = 242386, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 60.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- PRIEST - HOLY (257)
    [257] = {
        HEAD = { name = "Benevolent Invoker's Cowl", itemID = 237652, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 42.0, gems = {213746, 213467} },
        SHOULDER = { name = "Benevolent Invoker's Mantle", itemID = 237650, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Benevolent Invoker's Vestment", itemID = 237653, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219335, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Benevolent Invoker's Gloves", itemID = 237649, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 80.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219332, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 45.0, gems = {213467} },
        LEGS = { name = "Benevolent Invoker's Leggings", itemID = 237651, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 65.0, enchant = 219911 },
        FEET = { name = "Slippers of Astral Geometry", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 72.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 68.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 28.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 50.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 45.0 },
        MAINHAND = { name = "Void Staff of Renewal", itemID = 242385, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 58.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- DRUID - FERAL (103)
    [103] = {
        HEAD = { name = "Antlers of the Woodland Spirit", itemID = 237604, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", popularity = 38.0, gems = {213743, 213467} },
        SHOULDER = { name = "Spaulders of the Woodland Spirit", itemID = 237602, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Tunic of the Woodland Spirit", itemID = 237605, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 58.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Gloves of the Woodland Spirit", itemID = 237601, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 50.0, gems = {213467} },
        LEGS = { name = "Breeches of the Woodland Spirit", itemID = 237603, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 78.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 26.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 55.0 },
        MAINHAND = { name = "Void Polearm of the Wild", itemID = 242376, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Polearm", popularity = 65.0, enchant = 223781 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- DRUID - GUARDIAN (104)
    [104] = {
        HEAD = { name = "Antlers of the Woodland Spirit", itemID = 237604, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213455} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Haste", popularity = 42.0, gems = {213743, 213455} },
        SHOULDER = { name = "Spaulders of the Woodland Spirit", itemID = 237602, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223734 },
        CHEST = { name = "Tunic of the Woodland Spirit", itemID = 237605, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 60.0, enchant = 223716, gems = {213455} },
        HANDS = { name = "Gloves of the Woodland Spirit", itemID = 237601, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 52.0, gems = {213455} },
        LEGS = { name = "Breeches of the Woodland Spirit", itemID = 237603, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219908 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 76.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223683, gems = {213455, 213455} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 30.0, enchant = 223683, gems = {213455, 213455} },
        TRINKET1 = { name = "Infinitely Divisible Ooze", itemID = 178769, source = "MYTHIC_PLUS", sourceDetail = "Priory of the Sacred Flame", stats = "Agi + Absorb", popularity = 55.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Polearm of the Wild", itemID = 242376, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Polearm", popularity = 62.0, enchant = 223781 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- DRUID - RESTORATION (105)
    [105] = {
        HEAD = { name = "Antlers of the Woodland Spirit", itemID = 237604, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", popularity = 40.0, gems = {213746, 213461} },
        SHOULDER = { name = "Spaulders of the Woodland Spirit", itemID = 237602, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Tunic of the Woodland Spirit", itemID = 237605, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Armbands", itemID = 219334, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Gloves of the Woodland Spirit", itemID = 237601, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 80.0 },
        WAIST = { name = "Rune-Branded Waistband", itemID = 219331, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213461} },
        LEGS = { name = "Breeches of the Woodland Spirit", itemID = 237603, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 65.0, enchant = 219911 },
        FEET = { name = "Interloper's Reinforced Sandals", itemID = 243306, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Vers/Mastery", popularity = 72.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 68.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 28.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 50.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 45.0 },
        MAINHAND = { name = "Void Staff of Nature's Renewal", itemID = 242384, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 58.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- SHAMAN - ELEMENTAL (262)
    [262] = {
        HEAD = { name = "Stormcaller's Faceguard", itemID = 237692, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", popularity = 38.0, gems = {213743, 213467} },
        SHOULDER = { name = "Stormcaller's Shoulderguards", itemID = 237690, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Stormcaller's Chainmail", itemID = 237693, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Stormcaller's Grips", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 48.0, gems = {213467} },
        LEGS = { name = "Stormcaller's Leggings", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 78.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 26.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 55.0 },
        MAINHAND = { name = "Void Staff of Storms", itemID = 242379, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 65.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- SHAMAN - ENHANCEMENT (263)
    [263] = {
        HEAD = { name = "Stormcaller's Faceguard", itemID = 237692, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", popularity = 40.0, gems = {213743, 213461} },
        SHOULDER = { name = "Stormcaller's Shoulderguards", itemID = 237690, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Stormcaller's Chainmail", itemID = 237693, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223692 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 58.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Stormcaller's Grips", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 50.0, gems = {213461} },
        LEGS = { name = "Stormcaller's Leggings", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 75.0, enchant = 223656 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 28.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Ara-Kara Sacbrood", itemID = 219314, source = "MYTHIC_PLUS", sourceDetail = "Ara-Kara", stats = "Agi + Proc", popularity = 50.0 },
        MAINHAND = { name = "Void Fist of the Storm", itemID = 242377, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Fist", popularity = 55.0, enchant = 223781 },
        OFFHAND = { name = "Void Fist of the Storm", itemID = 242377, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Agi Fist", popularity = 55.0, enchant = 223784 },
    },
    
    -- SHAMAN - RESTORATION (264)
    [264] = {
        HEAD = { name = "Stormcaller's Faceguard", itemID = 237692, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 42.0, gems = {213746, 213467} },
        SHOULDER = { name = "Stormcaller's Shoulderguards", itemID = 237690, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Stormcaller's Chainmail", itemID = 237693, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Stormcaller's Grips", itemID = 237689, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 80.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213467} },
        LEGS = { name = "Stormcaller's Leggings", itemID = 237691, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 65.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 72.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 68.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 30.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 52.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Mace of Tides", itemID = 242378, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Mace", popularity = 50.0, enchant = 223764 },
        OFFHAND = { name = "Void Totem Shield", itemID = 242391, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Shield", popularity = 45.0 },
    },
    
    -- WARLOCK - AFFLICTION (265)
    [265] = {
        HEAD = { name = "Hexflame Coven's Cowl", itemID = 237720, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Mastery", popularity = 38.0, gems = {213743, 213461} },
        SHOULDER = { name = "Hexflame Coven's Mantle", itemID = 237718, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hexflame Coven's Vestment", itemID = 237721, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219335, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Hexflame Coven's Gloves", itemID = 237717, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219332, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 48.0, gems = {213461} },
        LEGS = { name = "Hexflame Coven's Leggings", itemID = 237719, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Slippers of Astral Geometry", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 78.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 26.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 55.0 },
        MAINHAND = { name = "Void Staff of Suffering", itemID = 242380, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 65.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- WARLOCK - DEMONOLOGY (266)
    [266] = {
        HEAD = { name = "Hexflame Coven's Cowl", itemID = 237720, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213461} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Crit", popularity = 40.0, gems = {213743, 213461} },
        SHOULDER = { name = "Hexflame Coven's Mantle", itemID = 237718, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hexflame Coven's Vestment", itemID = 237721, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219335, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 58.0, enchant = 223713, gems = {213461} },
        HANDS = { name = "Hexflame Coven's Gloves", itemID = 237717, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219332, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 50.0, gems = {213461} },
        LEGS = { name = "Hexflame Coven's Leggings", itemID = 237719, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Slippers of Astral Geometry", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 75.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223680, gems = {213461, 213461} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 28.0, enchant = 223680, gems = {213461, 213461} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 52.0 },
        MAINHAND = { name = "Void Staff of Demons", itemID = 242382, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 62.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- WARLOCK - DESTRUCTION (267)
    [267] = {
        HEAD = { name = "Hexflame Coven's Cowl", itemID = 237720, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 89.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Haste", popularity = 36.0, gems = {213743, 213467} },
        SHOULDER = { name = "Hexflame Coven's Mantle", itemID = 237718, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 87.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Hexflame Coven's Vestment", itemID = 237721, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 93.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Bindings", itemID = 219335, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 56.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Hexflame Coven's Gloves", itemID = 237717, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        WAIST = { name = "Rune-Branded Cord", itemID = 219332, source = "CRAFTED", sourceDetail = "Tailoring", stats = "Custom", popularity = 49.0, gems = {213467} },
        LEGS = { name = "Hexflame Coven's Leggings", itemID = 237719, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 69.0, enchant = 219911 },
        FEET = { name = "Slippers of Astral Geometry", itemID = 243305, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 76.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 71.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 27.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 64.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 56.0 },
        MAINHAND = { name = "Void Staff of Chaos", itemID = 242375, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 68.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- EVOKER - DEVASTATION (1467)
    [1467] = {
        HEAD = { name = "Scalesworn Chronoguard's Helm", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, gems = {213458} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Crit", popularity = 38.0, gems = {213743, 213458} },
        SHOULDER = { name = "Scalesworn Chronoguard's Spaulders", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Scalesworn Chronoguard's Chainmail", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 94.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 55.0, enchant = 223713, gems = {213458} },
        HANDS = { name = "Scalesworn Chronoguard's Gauntlets", itemID = 237625, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 85.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 48.0, gems = {213458} },
        LEGS = { name = "Scalesworn Chronoguard's Legguards", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 70.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 78.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 72.0, enchant = 223674, gems = {213458, 213458} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 26.0, enchant = 223674, gems = {213458, 213458} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 62.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 55.0 },
        MAINHAND = { name = "Void Staff of Eternity", itemID = 242392, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 65.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- EVOKER - PRESERVATION (1468)
    [1468] = {
        HEAD = { name = "Scalesworn Chronoguard's Helm", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0, gems = {213467} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 40.0, gems = {213746, 213467} },
        SHOULDER = { name = "Scalesworn Chronoguard's Spaulders", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 84.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Scalesworn Chronoguard's Chainmail", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 90.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 52.0, enchant = 223713, gems = {213467} },
        HANDS = { name = "Scalesworn Chronoguard's Gauntlets", itemID = 237625, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 80.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 45.0, gems = {213467} },
        LEGS = { name = "Scalesworn Chronoguard's Legguards", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 65.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 72.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 68.0, enchant = 223677, gems = {213467, 213467} },
        FINGER2 = { name = "Signet of Collapsing Stars", itemID = 185813, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Haste/Vers", popularity = 30.0, enchant = 223677, gems = {213467, 213467} },
        TRINKET1 = { name = "Unbound Changeling", itemID = 178708, source = "MYTHIC_PLUS", sourceDetail = "The Dawnbreaker", stats = "Int + Proc", popularity = 52.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 48.0 },
        MAINHAND = { name = "Void Staff of Time", itemID = 242393, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 58.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
    
    -- EVOKER - AUGMENTATION (1473)
    [1473] = {
        HEAD = { name = "Scalesworn Chronoguard's Helm", itemID = 237628, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 88.0, gems = {213458} },
        NECK = { name = "Chrysalis of Sundered Souls", itemID = 237568, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Mastery/Haste", popularity = 42.0, gems = {213743, 213458} },
        SHOULDER = { name = "Scalesworn Chronoguard's Spaulders", itemID = 237626, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 86.0 },
        BACK = { name = "Reshii Wraps", itemID = 235499, source = "RAID", sourceDetail = "Artifact Cloak", stats = "Adaptive", popularity = 100.0, enchant = 223731 },
        CHEST = { name = "Scalesworn Chronoguard's Chainmail", itemID = 237629, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 92.0, enchant = 223680 },
        WRIST = { name = "Rune-Branded Wristguards", itemID = 219333, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 58.0, enchant = 223713, gems = {213458} },
        HANDS = { name = "Scalesworn Chronoguard's Gauntlets", itemID = 237625, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Tier", popularity = 83.0 },
        WAIST = { name = "Rune-Branded Girdle", itemID = 219330, source = "CRAFTED", sourceDetail = "Leatherworking", stats = "Custom", popularity = 50.0, gems = {213458} },
        LEGS = { name = "Scalesworn Chronoguard's Legguards", itemID = 237627, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Non-Tier", popularity = 68.0, enchant = 219911 },
        FEET = { name = "Treads of Unseen Peril", itemID = 243307, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Mastery", popularity = 75.0, enchant = 223653 },
        FINGER1 = { name = "Ring of Earthen Craftsmanship", itemID = 215135, source = "CRAFTED", sourceDetail = "Jewelcrafting", stats = "Custom", popularity = 70.0, enchant = 223674, gems = {213458, 213458} },
        FINGER2 = { name = "Logic Gate: Alpha", itemID = 237567, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Crit/Vers", popularity = 28.0, enchant = 223674, gems = {213458, 213458} },
        TRINKET1 = { name = "Sigil of the Cosmic Hunt", itemID = 242397, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 60.0 },
        TRINKET2 = { name = "Astral Antenna", itemID = 242395, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int + Proc", popularity = 52.0 },
        MAINHAND = { name = "Void Staff of Augmentation", itemID = 242394, source = "RAID", sourceDetail = "Manaforge Omega", stats = "Int Staff", popularity = 62.0, enchant = 223764 },
        OFFHAND = { name = "", itemID = 0, source = "UNKNOWN", sourceDetail = "N/A (2H)", stats = "", popularity = 0 },
    },
}

-- =============================================================================
-- DATA ACCESS FUNCTIONS
-- =============================================================================

function KDT:GetBisForSpec(specID)
    if KDT.BIS_IMPORTED and KDT.BIS_IMPORTED[specID] and KDT.BIS_IMPORTED[specID].slots then
        local result = {}
        for slot, data in pairs(KDT.BIS_IMPORTED[specID].slots) do
            result[slot] = { name = data.name, itemID = data.id, source = data.source, sourceDetail = data.detail, stats = data.stats or "", popularity = data.popularity or 0, enchant = data.enchant, gems = data.gems }
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

function KDT:GetSpecName(specID) return KDT.SPEC_NAMES[specID] or "Unknown" end
function KDT:GetPlayerSpecID() return GetSpecializationInfo(GetSpecialization() or 1) or 0 end

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
    return KDT.BIS_DATA[specID] ~= nil
end
