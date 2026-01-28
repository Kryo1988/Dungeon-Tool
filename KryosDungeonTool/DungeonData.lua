-- Kryos Dungeon Tool
-- DungeonData.lua - Dungeon MapIDs and Teleport Data

local addonName, KDT = ...

-- ==================== KEYSTONE MAP IDs ====================
-- Used to display keystone dungeon names
KDT.DUNGEON_NAMES = {
    -- TWW Season 3 (from C_ChallengeMode.GetMapTable)
    [499] = "PSF",    -- Priory of the Sacred Flame
    [542] = "EDA",    -- Eco-Dome Al'dani
    [378] = "HOA",    -- Halls of Atonement
    [525] = "FLOOD",  -- Operation: Floodgate
    [503] = "AK",     -- Ara-Kara, City of Echoes
    [392] = "GMBT",   -- Tazavesh: So'leah's Gambit
    [391] = "STRT",   -- Tazavesh: Streets of Wonder
    [505] = "DB",     -- The Dawnbreaker
    
    -- Alternative/Internal MapIDs (from actual keystones)
    [2649] = "PSF",   -- Priory of the Sacred Flame (internal ID)
    [2688] = "EDA",   -- Eco-Dome Al'dani (internal ID)
    [2287] = "HOA",   -- Halls of Atonement (internal ID)
    [2773] = "FLOOD", -- Operation: Floodgate (internal ID)
    [2660] = "AK",    -- Ara-Kara, City of Echoes (internal ID)
    [2662] = "DB",    -- The Dawnbreaker (internal ID)
    
    -- TWW other dungeons
    [501] = "SV",     -- Stonevault
    [502] = "COT",    -- City of Threads
    [500] = "ROOK",   -- The Rookery
    [504] = "BREW",   -- Cinderbrew Meadery
    [506] = "DFC",    -- Darkflame Cleft
    
    -- Shadowlands
    [375] = "NW",     -- Necrotic Wake
    [379] = "PF",     -- Plaguefall
    [380] = "SD",     -- Sanguine Depths
    [381] = "SOA",    -- Spires of Ascension
    [382] = "TOP",    -- Theater of Pain
    [377] = "DOS",    -- De Other Side
    [376] = "MISTS",  -- Mists of Tirna Scithe
    
    -- Dragonflight
    [399] = "RLP",    -- Ruby Life Pools
    [400] = "NO",     -- The Nokhud Offensive
    [401] = "AV",     -- The Azure Vault
    [402] = "AA",     -- Algeth'ar Academy
    [403] = "ULD",    -- Uldaman: Legacy of Tyr
    [404] = "NELTH",  -- Neltharus
    [405] = "BH",     -- Brackenhide Hollow
    [406] = "HOI",    -- Halls of Infusion
    [463] = "DOTI",   -- Dawn of the Infinite: Galakrond's Fall
    [464] = "DOTI",   -- Dawn of the Infinite: Murozond's Rise
}

-- ==================== TELEPORT DATA ====================
-- Used for the M+ Teleports tab
KDT.TELEPORT_DATA = {
    -- TWW Season 3
    {
        category = "TWW Season 3",
        dungeons = {
            {name = "Ara-Kara", short = "AK", spellID = 445417, icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara"},
            {name = "Dawnbreaker", short = "DAWN", spellID = 445414, icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker"},
            {name = "Eco-Dome", short = "EDA", spellID = 1237215, icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome"},
            {name = "Halls of Atonement", short = "HOA", spellID = 354465, icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement"},
            {name = "Operation: Floodgate", short = "FLOOD", spellID = 1216786, icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks"},
            {name = "Priory of the Sacred Flame", short = "PSF", spellID = 445444, icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame"},
            {name = "Tazavesh: Gambit", short = "GMBT", spellID = 367416, icon = "Interface\\Icons\\achievement_dungeon_brokerdungeon"},
            {name = "Tazavesh: Streets", short = "STRT", spellID = 367416, icon = "Interface\\Icons\\Achievement_dungeon_theotherside_dealergexa"},
        }
    },
    -- Midnight
    {
        category = "Midnight",
        dungeons = {
            {name = "Dauntless Stronghold", short = "DON", spellID = 11, icon = "Interface\\Icons\\inv_achievement_dungeon_proveyourworth"},
            {name = "Magister's Terrace", short = "MT", spellID = 1254572, icon = "Interface\\Icons\\inv_achievement_dungeon_magistersterrace"},
            {name = "Mai'sara Caverns", short = "MC", spellID = 1254559, icon = "Interface\\Icons\\inv_achievement_dungeon_maisarahills"},
            {name = "Murder Row", short = "MR", spellID = 4, icon = "Interface\\Icons\\inv_achievement_dungeon_murderrow"},
            {name = "Nexus Point Xenas", short = "NPX", spellID = 1254563, icon = "Interface\\Icons\\inv_achievement_dungeon_nexuspointxenas"},
            {name = "Blinding Vale", short = "BV", spellID = 3, icon = "Interface\\Icons\\inv_achievement_dungeon_lightbloom"},
            {name = "Voidscar Arena", short = "VA", spellID = 1, icon = "Interface\\Icons\\inv_achievement_dungeon_voidscararena"},
            {name = "Windrunner Spire", short = "WS", spellID = 1254400, icon = "Interface\\Icons\\inv_achievement_dungeon_windrunnerspire"},
        }
    },
    -- TWW Dungeons
    {
        category = "TWW Dungeons",
        dungeons = {
            {name = "Ara-Kara", short = "AK", spellID = 445417, icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara"},
            {name = "Cinderbrew Meadery", short = "BREW", spellID = 445440, icon = "Interface\\Icons\\inv_achievement_dungeon_cinderbrewmeadery"},
            {name = "City of Threads", short = "COT", spellID = 445416, icon = "Interface\\Icons\\inv_achievement_dungeon_cityofthreads"},
            {name = "Darkflame Cleft", short = "DFC", spellID = 445441, icon = "Interface\\Icons\\inv_achievement_dungeon_darkflamecleft"},
            {name = "Dawnbreaker", short = "DAWN", spellID = 445414, icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker"},
            {name = "Eco-Dome", short = "EDA", spellID = 1237215, icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome"},
            {name = "Operation: Floodgate", short = "FLOOD", spellID = 1216786, icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks"},
            {name = "Priory of the Sacred Flame", short = "PSF", spellID = 445444, icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame"},
            {name = "The Rookery", short = "ROOK", spellID = 445443, icon = "Interface\\Icons\\inv_achievement_dungeon_rookery"},
            {name = "Stonevault", short = "SV", spellID = 445269, icon = "Interface\\Icons\\inv_achievement_dungeon_stonevault"},
        }
    },
    -- Shadowlands
    {
        category = "Shadowlands",
        dungeons = {
            {name = "De Other Side", short = "DOS", spellID = 354468, icon = "Interface\\Icons\\achievement_dungeon_theotherside"},
            {name = "Halls of Atonement", short = "HOA", spellID = 354465, icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement"},
            {name = "Mists of Tirna Scithe", short = "MISTS", spellID = 354464, icon = "Interface\\Icons\\achievement_dungeon_mistsoftirnascithe"},
            {name = "Necrotic Wake", short = "NW", spellID = 354462, icon = "Interface\\Icons\\achievement_dungeon_theneroticwake"},
            {name = "Plaguefall", short = "PF", spellID = 354463, icon = "Interface\\Icons\\achievement_dungeon_plaguefall"},
            {name = "Sanguine Depths", short = "SD", spellID = 354469, icon = "Interface\\Icons\\achievement_dungeon_sanguinedepths"},
            {name = "Spires of Ascension", short = "SOA", spellID = 354466, icon = "Interface\\Icons\\achievement_dungeon_spireofascension"},
            {name = "Tazavesh", short = "TAZ", spellID = 367416, icon = "Interface\\Icons\\achievement_dungeon_brokerdungeon"},
            {name = "Theater of Pain", short = "TOP", spellID = 354467, icon = "Interface\\Icons\\achievement_dungeon_theatreofpain"},
        }
    },
    -- Dragonflight
    {
        category = "Dragonflight",
        dungeons = {
            {name = "Algeth'ar Academy", short = "AA", spellID = 393273, icon = "Interface\\Icons\\achievement_dungeon_dragonacademy"},
            {name = "Azure Vault", short = "AV", spellID = 393279, icon = "Interface\\Icons\\achievement_dungeon_arcanevaults"},
            {name = "Brackenhide Hollow", short = "BH", spellID = 393267, icon = "Interface\\Icons\\achievement_dungeon_brackenhidehollow"},
            {name = "Dawn of the Infinite", short = "DOTI", spellID = 424197, icon = "Interface\\Icons\\achievement_dungeon_dawnoftheinfinite"},
            {name = "Halls of Infusion", short = "HOI", spellID = 393283, icon = "Interface\\Icons\\achievement_dungeon_hallsofinfusion"},
            {name = "Neltharus", short = "NELTH", spellID = 393276, icon = "Interface\\Icons\\achievement_dungeon_neltharus"},
            {name = "Nokhud Offensive", short = "NO", spellID = 393262, icon = "Interface\\Icons\\achievement_dungeon_centaurplains"},
            {name = "Ruby Life Pools", short = "RLP", spellID = 393256, icon = "Interface\\Icons\\achievement_dungeon_lifepools"},
            {name = "Uldaman", short = "ULD", spellID = 393222, icon = "Interface\\Icons\\achievement_dungeon_uldaman"},
        }
    },
    -- Legion
    {
        category = "Legion",
        dungeons = {
            {name = "Black Rook Hold", short = "BRH", spellID = 424153, icon = "Interface\\Icons\\achievement_dungeon_blackrookhold"},
            {name = "Court of Stars", short = "COS", spellID = 393766, icon = "Interface\\Icons\\achievement_dungeon_courtofstars"},
            {name = "Darkheart Thicket", short = "DHT", spellID = 424163, icon = "Interface\\Icons\\achievement_dungeon_darkheartthicket"},
            {name = "Halls of Valor", short = "HOV", spellID = 393764, icon = "Interface\\Icons\\achievement_dungeon_hallsofvalor"},
            {name = "Neltharion's Lair", short = "NL", spellID = 410078, icon = "Interface\\Icons\\achievement_dungeon_neltharionslair"},
            {name = "Karazhan", short = "KARA", spellID = 373262, icon = "Interface\\Icons\\achievement_raid_karazhan"},
            {name = "Seat of the Triumvirate", short = "SOTT", spellID = 1254551, icon = "Interface\\Icons\\achievement_dungeon_argusdungeon"},
        }
    },
    -- WoD
    {
        category = "Warlords of Draenor",
        dungeons = {
            {name = "Auchindoun", short = "AUCH", spellID = 159897, icon = "Interface\\Icons\\achievement_dungeon_auchindoun"},
            {name = "Bloodmaul Slag Mines", short = "BSM", spellID = 159895, icon = "Interface\\Icons\\achievement_dungeon_ogreslagmines"},
            {name = "Everbloom", short = "EB", spellID = 159901, icon = "Interface\\Icons\\achievement_dungeon_everbloom"},
            {name = "Grimrail Depot", short = "GD", spellID = 159900, icon = "Interface\\Icons\\achievement_dungeon_blackrockdepot"},
            {name = "Iron Docks", short = "ID", spellID = 159896, icon = "Interface\\Icons\\achievement_dungeon_blackrockdocks"},
            {name = "Shadowmoon Burial Grounds", short = "SBG", spellID = 159899, icon = "Interface\\Icons\\achievement_dungeon_shadowmoonhideout"},
            {name = "Skyreach", short = "SKY", spellID = 159898, icon = "Interface\\Icons\\achievement_dungeon_arakkoaspires"},
            {name = "Upper Blackrock Spire", short = "UBRS", spellID = 159902, icon = "Interface\\Icons\\achievement_dungeon_upperblackrockspire"},
        }
    },
    -- MoP
    {
        category = "Mists of Pandaria",
        dungeons = {
            {name = "Gate of the Setting Sun", short = "GOSS", spellID = 131225, icon = "Interface\\Icons\\achievement_greatwall"},
            {name = "Mogu'shan Palace", short = "MSP", spellID = 131222, icon = "Interface\\Icons\\achievement_dungeon_mogupalace"},
            {name = "Scholomance", short = "SCHO", spellID = 131232, icon = "Interface\\Icons\\spell_holy_senseundead"},
            {name = "Scarlet Halls", short = "SH", spellID = 131231, icon = "Interface\\Icons\\inv_helmet_52"},
            {name = "Scarlet Monastery", short = "SM", spellID = 131229, icon = "Interface\\Icons\\spell_holy_resurrection"},
            {name = "Siege of Niuzao Temple", short = "SNT", spellID = 131228, icon = "Interface\\Icons\\achievement_dungeon_siegeofniuzaotemple"},
            {name = "Shado-Pan Monastery", short = "SPM", spellID = 131206, icon = "Interface\\Icons\\achievement_shadowpan_hideout"},
            {name = "Stormstout Brewery", short = "SB", spellID = 131205, icon = "Interface\\Icons\\achievement_brewery"},
            {name = "Temple of the Jade Serpent", short = "TJS", spellID = 131204, icon = "Interface\\Icons\\achievement_jadeserpent"},
        }
    },
    -- Cata
    {
        category = "Cataclysm",
        dungeons = {
            {name = "Grim Batol", short = "GB", spellID = 445424, icon = "Interface\\Icons\\achievement_dungeon_grimbatol"},
            {name = "Throne of the Tides", short = "TOTT", spellID = 424142, icon = "Interface\\Icons\\achievement_dungeon_throne of the tides"},
            {name = "Vortex Pinnacle", short = "VP", spellID = 410080, icon = "Interface\\Icons\\achievement_dungeon_skywall"},
        }
    },
    -- Wrath
    {
        category = "Wrath of the Lich King",
        dungeons = {
            {name = "Pit of Saron", short = "POS", spellID = 1254555, icon = "Interface\\Icons\\achievement_dungeon_icecrown_pitofsaron"},
        }
    },
    -- BfA
    {
        category = "Battle for Azeroth",
        dungeons = {
            {name = "Atal'Dazar", short = "AD", spellID = 424187, icon = "Interface\\Icons\\achievement_dungeon_ataldazar"},
            {name = "Freehold", short = "FH", spellID = 410071, icon = "Interface\\Icons\\achievement_dungeon_freehold"},
            {name = "Mechagon", short = "MECH", spellID = 373274, icon = "Interface\\Icons\\achievement_boss_mechagon"},
            {name = "Underrot", short = "UR", spellID = 410074, icon = "Interface\\Icons\\achievement_dungeon_underrot"},
            {name = "Waycrest Manor", short = "WM", spellID = 424167, icon = "Interface\\Icons\\achievement_dungeon_waycrestmannor"},
        }
    },
    -- Raids
    {
        category = "TWW Raids",
        dungeons = {
            {name = "Liberation of Undermine", short = "LOU", spellID = 1226482, icon = "Interface\\Icons\\inv_achievement_zone_undermine"},
            {name = "Manaforge Omega", short = "MFO", spellID = 1239155, icon = "Interface\\Icons\\inv_112_achievement_raid_manaforgeomega"},
        }
    },
    {
        category = "DF Raids",
        dungeons = {
            {name = "Vault of the Incarnates", short = "VOTI", spellID = 432254, icon = "Interface\\Icons\\achievement_raidprimalist_raid"},
            {name = "Aberrus", short = "ABER", spellID = 432257, icon = "Interface\\Icons\\inv_achievement_raiddragon_raid"},
            {name = "Amirdrassil", short = "AMIR", spellID = 432258, icon = "Interface\\Icons\\inv_achievement_raidemeralddream_raid"},
        }
    },
    {
        category = "SL Raids",
        dungeons = {
            {name = "Castle Nathria", short = "CN", spellID = 373190, icon = "Interface\\Icons\\achievement_raid_revendrethraid_castlenathria"},
            {name = "Sanctum of Domination", short = "SOD", spellID = 373191, icon = "Interface\\Icons\\achievement_raid_torghastraid"},
            {name = "Sepulcher of the First Ones", short = "SEPUL", spellID = 373192, icon = "Interface\\Icons\\inv_achievement_raid_progenitorraid"},
        }
    },
}
