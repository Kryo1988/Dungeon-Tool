# KryosDungeonTool Changelog

## Version 1.8.36 (2025-02-05)

### Fixes
- **Removed startup message**: Removed "DMG Meter: C_DamageMeter (live)" print on load
- **Fixed FormatNumber crash**: Fixed Lua error "attempt to compare local 'num' (a secret value)" when hovering meter bars during combat - now properly handles WoW's secret values from C_DamageMeter API
- **Fixed pet tracking**: Pets are no longer shown as "Player 6" in the meter - only actual players are tracked now
- **Fixed healing tracking**: Healing is now tracked via CLEU (Combat Log) on WoW 12.0+ since C_DamageMeter doesn't reliably provide live healing data. This ensures healing is properly displayed during and after combat
- **Overall data always available**: "Overall Data" segment is now always visible at the top of the segment dropdown (right after "Current Segment"), showing combined data from current segment + all historical segments

## Version 1.8.18 (2026-02-04)

### New Feature: Damage / Heal Meter

**Complete Damage Meter module** with combat logging and real-time display.

#### Core Features:
- **Combat Log Parser**: Tracks damage, healing, interrupts, deaths from COMBAT_LOG_EVENT_UNFILTERED
- **Multiple Display Modes**:
  - Damage Done / DPS
  - Healing Done / HPS
  - Interrupts / Deaths
  - Damage Taken
- **Multi-Window Support**: Create multiple meter windows for different data views
- **Current/Overall Toggle**: Switch between current segment and overall session data
- **Spell Breakdown**: Tooltip shows top 5 spells per player

#### Meter Window Features (Details-inspired):
- Draggable and resizable floating window
- Class-colored bars with percentage display
- **Hover Buttons**: Reset Segment, Reset All, Report, Overall toggle
- **Click mode label** to toggle paired modes (Damage ↔ DPS, Healing ↔ HPS)
- **Right-click context menu** with categorized mode selection (like Details)
- Report to chat function
- Live refresh during combat (0.5 sec update)

#### Settings Tab (METER):
- Enable/Disable meter tracking
- Bar height, font size, max bars sliders
- Show rank, percent, class colors toggles
- Mode shortcut buttons for quick access

#### Slash Commands:
- `/kdt meter` - Toggle meter window
- `/kdt meter reset` - Reset all combat data
- `/kdt meter new` - Create additional window

### Bug Fixes:
- **Fixed ADDON_ACTION_FORBIDDEN error**: Delayed event registration for WoW 12.0 compatibility
- **Fixed Season 3 dungeons**: Replaced Cinderbrew (CoE) with Ara-Kara (ARAK) - correct S3 rotation

### Season 3 Dungeon Pool (Patch 11.2):
1. Eco-Dome Al'dani (EDA) - NEW
2. Ara-Kara, City of Echoes (ARAK)
3. The Dawnbreaker (DB)
4. Priory of the Sacred Flame (PSF)
5. Operation: Floodgate (FG)
6. Tazavesh: Streets of Wonder (STRT)
7. Tazavesh: So'leah's Gambit (GMBT)
8. Halls of Atonement (HOA)

---

## Version 1.8.17 (2026-02-04)

### Major UI Redesign: Group Members Panel

**Complete visual overhaul** of the Group Members section, inspired by Raider.IO's party view design.

#### New Features:
- **Player Cards**: Each group member now displayed in a modern card layout instead of simple table rows
- **Class Icons**: Large class icon portraits for each player with class-colored accent bar
- **RIO Score Display**: Prominent, color-coded RIO score (22pt font) with quality-based coloring
- **Dungeon Header**: Season 3 dungeon icons displayed at top with tooltips
  - Eco-Dome, Priory, Dawnbreaker, Halls of Atonement
  - Cinderbrew, Streets, Floodgate, Gambit
- **Key Level Per Dungeon**: Shows player's key level under matching dungeon icon
- **Compact Overview**: Streamlined top panel with role counts, BR/BL status, and group keys

#### Visual Improvements:
- Dark theme cards with subtle borders
- Class-colored left accent bar on each card
- Color-coded key levels (orange 15+, purple 12+, blue 10+, green 7+)
- Color-coded RIO scores (orange 3500+, purple 3000+, blue 2500+, green 2000+)
- Blacklist warning overlay with red tint
- Improved typography hierarchy (name > spec > RIO)

#### Layout Changes:
- Buttons reorganized in 2x2 grid (Ready Check, Post Chat, Countdown, Abandon)
- Hidden countdown settings (uses saved value)
- Scrollable card container with mouse wheel support

---

## Version 1.8.16 (2026-02-04)

### BiS Data Update
- **Devourer BiS Data**: Added complete BiS gear list for Demon Hunter Devourer spec
  - Full Charhound's Vicious tier set from M+
  - Crafted pieces: Amulet of Earthen Craftsmanship, Rune-Branded Waistband
  - Raid pieces: Reshii Wraps, Interloper's Reinforced Sandals, Signet of Collapsing Stars
  - Trinkets: Astral Antenna, Chant of Winged Grace
  - Weapons: Everforged Warglaive + Collapsing Phaseblades

---

## Version 1.8.15 (2026-02-04)

### New Feature
- **Devourer Spec Support**: Added support for the new 3rd Demon Hunter spec introduced in Midnight
  - SpecID 1480 (Devourer) is now recognized as a full spec, not a Hero Talent
  - Devourer is an Intellect-based caster DPS spec (different from Havoc/Vengeance)
  - BiS data placeholder added - use right-click to edit or wait for Archon.gg data

### Technical
- Updated `SPEC_NAMES` to include Devourer (1480)
- Updated `ARCHON_SPEC_SLUGS` for Devourer
- Added Devourer BiS data template (needs population from Archon.gg)
- Removed incorrect Hero Talent mappings (1480 is not a Hero Talent)

---

## Version 1.8.14 (2026-02-01)

### Bugfixes
- **Dropdown Height Fix**: Class dropdown now has exact same height (20px) as other input fields
- **Dropdown Styling**: Uses same font and border colors as input boxes for consistent look
- **Key Sharing Fix**: Keys from other players are now correctly stored and displayed
  - Keys are now saved in both `groupKeys` and `receivedKeys` for compatibility
  - Keys should now appear for all group members using KDT

### Notes
- Group Check features (RIO, iLvl, Scrollbar, Abandon Button) were already implemented in previous versions
- Teleport announce checkbox was already present in M+ Teleports tab

---

## Version 1.8.13 (2026-02-01)

### Bugfixes
- **Tab Overlap Fixed**: Group Check content no longer shows through when switching to Blacklist tab
  - memberContainer is now explicitly hidden during tab switches
- **Dropdown Arrow**: Changed from "▼" (Unicode) to "v" for better font compatibility

---

## Version 1.8.12 (2026-02-01)

### Blacklist Improvements

**Right-Click Menu Enhancements:**
- **Automatic Class Detection**: When adding a player via right-click, their class is automatically detected and saved
- **Server Name Saved**: Full player name with server is now stored (e.g., "Kryos-Blackmoore")

**Custom Class Dropdown:**
- New dropdown design matching the addon's dark theme
- Class colors displayed in dropdown menu
- Color indicator bar for each class option

**Server Support:**
- Blacklist entries now store full name with server
- Intelligent matching: checks both with and without server for backwards compatibility
- Display shows server name in gray after player name
- Group join check uses full name with server for accurate matching

---

## Version 1.8.11 (2026-02-01)

### Blacklist Overhaul

**New Features:**
- **Class Display**: Players shown with class color and class name
- **Class Dropdown**: Select class when manually adding players
- **Search Function**: Filter blacklist by name, reason, or class
- **Invisible Scrollbar**: Mouse wheel scrolling without visible scrollbar
- **Entry Counter**: Shows filtered/total count

**UI Changes:**
- Removed "Share List" button from UI (command still works via `/kdt share`)
- Removed `/kdt share` from `/kdt help` output

**Bugfixes:**
- **Share Function Fixed**: Added CHAT_MSG_ADDON event handler
  - Recipients now correctly receive shared blacklist entries
  - Import dialog appears as expected
- **Class Info Shared**: When sharing blacklist, class information is included

---

## Version 1.8.10 (2026-01-31)

### M+ Timer Improvements

**1. Blizzard Timer - Only Hidden in M+ Dungeons**
- The default Blizzard timer is now ONLY hidden when you are actually inside a Mythic+ dungeon
- In open world or other content, the Blizzard timer remains visible as normal

**2. No More Empty Space**
- Fixed the issue where hiding the Blizzard timer left a large empty gap in the objective tracker
- Now properly collapses the frame instead of just making it invisible

**3. Dungeon Name & Key Level Display**
- Added a header row above the timer showing the dungeon name and key level
- Format: "+15 Operation: Mechagon" (with colored key level)

**4. Options Button**
- Added gear icon (⚙️) in top-right corner of timer
- Click to open Timer Settings directly
- Works both inside and outside M+ dungeons

**5. Redesigned Timer Settings Window**
- Matches KDT dark UI theme
- Organized sections with headers
- **Working Font Size Sliders** - Changes apply immediately by recreating the timer
- **Working Color Pickers** - Compatible with WoW 11.0+ and legacy API
- Checkboxes for Lock Position and Show Preview
- Three bottom buttons: Reset Position, Reset Colors, Hide Timer

**6. Completion Time Preservation Fix**
- Fixed bug where timer would reset to 0:00 after dungeon completion
- Now properly preserves and displays the final completion time
- Last boss is now correctly marked as killed when dungeon completes

**7. Preview Mode**
- When "Show Timer Outside M+" is enabled, displays demo data
- Shows "[PREVIEW]" indicator so you know it's not real data
- Useful for positioning and testing color settings

---

## Version 1.8.9 (2026-01-29)

### Critical Bugfix: Warrior Tier Set IDs Corrected

**Fixed incorrect tier set item IDs for all Warrior specs** - The previous version had Priest tier IDs (237700 series) instead of Warrior Living Weapon's tier IDs (237610 series).

### Fixes:
- **Fury (72)**: Fixed tier set IDs (237610, 237608, 237613, 237611, 237609), updated trinkets to Astral Antenna + Cursed Stone Idol, updated weapon to Circuit Breaker
- **Arms (71)**: Fixed tier set IDs, updated trinkets to Astral Antenna + Cursed Stone Idol
- **Protection (73)**: Fixed tier set IDs

### Havoc DH Updates:
- **Havoc (577)**: Updated trinkets to Astral Antenna (50.5%) + Cursed Stone Idol (44.0%) based on current Archon.gg M+ meta (Sigil of the Cosmic Hunt was only 14.2%)

### Data Source:
All corrections verified against Archon.gg M+ gear data (January 2025)

---

## Version 1.8.8 (2026-01-29)

### Major Update: All Specs BiS Data Updated from Archon.gg

**Complete BiS data refresh for all 39 specs** with correct Tier Set items and current M+ meta gear.

### Death Knight
- **Blood (250)**: Hollow Sentinel's tier, Brand of Ceaseless Ire + Astral Antenna trinkets, Charged Claymore
- **Frost (251)**: Hollow Sentinel's tier, Astral Antenna + Cursed Stone Idol, Charged Claymore  
- **Unholy (252)**: Hollow Sentinel's tier, Astral Antenna + Cursed Stone Idol, Charged Claymore

### Demon Hunter
- **Havoc (577)**: Charhound's Vicious tier, Sigil of the Cosmic Hunt + Astral Antenna, Everforged Warglaives
- **Vengeance (581)**: Charhound's Vicious tier, Astral Antenna + Brand of Ceaseless Ire, Everforged Warglaives

### Warrior
- **Arms (71)**: Living Weapon tier, Sigil of the Cosmic Hunt + Astral Antenna, Void Reaper's Greatsword
- **Fury (72)**: Living Weapon tier, Sigil of the Cosmic Hunt + Seaforium Pacemaker, Void Reaper's Edge x2
- **Protection (73)**: Living Weapon tier, Brand of Ceaseless Ire + Astral Antenna, Longsword + Shield

### Paladin
- **Holy (65)**: Oathbinder's tier, Araz's Ritual Forge + Creeping Coagulum
- **Protection (66)**: Oathbinder's tier, Brand of Ceaseless Ire + Astral Antenna
- **Retribution (70)**: Oathbinder's tier, Sigil of the Cosmic Hunt + Astral Antenna, Charged Claymore

### Druid
- **Balance (102)**: Arboreal Cultivator's tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Feral (103)**: Arboreal Cultivator's tier, Sigil of the Cosmic Hunt + Astral Antenna
- **Guardian (104)**: Arboreal Cultivator's tier, Brand of Ceaseless Ire + Astral Antenna
- **Restoration (105)**: Arboreal Cultivator's tier, Araz's Ritual Forge + Creeping Coagulum

### Rogue
- **Assassination (259)**: Gatecrasher's tier, Sigil of the Cosmic Hunt + Astral Antenna, Everforged Daggers
- **Outlaw (260)**: Gatecrasher's tier, Sigil of the Cosmic Hunt + Astral Antenna, Everforged Daggers
- **Subtlety (261)**: Gatecrasher's tier, Sigil of the Cosmic Hunt + Cursed Stone Idol, Everforged Daggers

### Monk
- **Brewmaster (268)**: Mystic Heron's tier, Brand of Ceaseless Ire + Astral Antenna
- **Windwalker (269)**: Mystic Heron's tier, Sigil of the Cosmic Hunt + Astral Antenna, Warglaives
- **Mistweaver (270)**: Mystic Heron's tier, Araz's Ritual Forge + Creeping Coagulum

### Hunter
- **Beast Mastery (253)**: Deathstalker's tier, Sigil of the Cosmic Hunt + Astral Antenna, Charged Bow
- **Marksmanship (254)**: Deathstalker's tier, Sigil of the Cosmic Hunt + Astral Antenna, Charged Bow
- **Survival (255)**: Deathstalker's tier, Sigil of the Cosmic Hunt + Cursed Stone Idol, Charged Halberd

### Shaman
- **Elemental (262)**: Farseer's tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Enhancement (263)**: Farseer's tier, Sigil of the Cosmic Hunt + Astral Antenna, Everforged Maces
- **Restoration (264)**: Farseer's tier, Araz's Ritual Forge + Creeping Coagulum

### Evoker
- **Devastation (1467)**: Scalecommander's tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Preservation (1468)**: Scalecommander's tier, Araz's Ritual Forge + Creeping Coagulum
- **Augmentation (1473)**: Scalecommander's tier, Araz's Ritual Forge + Astral Antenna

### Mage
- **Arcane (62)**: Cryptic Illusionist tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Fire (63)**: Cryptic Illusionist tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Frost (64)**: Cryptic Illusionist tier, Araz's Ritual Forge + So'leah's Secret Technique

### Warlock
- **Affliction (265)**: Sinister Savant tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Demonology (266)**: Sinister Savant tier, Araz's Ritual Forge + Screams of a Forgotten Sky
- **Destruction (267)**: Sinister Savant tier, Araz's Ritual Forge + Screams of a Forgotten Sky

### Priest
- **Discipline (256)**: Void-Preacher's tier, Araz's Ritual Forge + Creeping Coagulum
- **Holy (257)**: Void-Preacher's tier, Araz's Ritual Forge + Creeping Coagulum
- **Shadow (258)**: Void-Preacher's tier, Araz's Ritual Forge + Screams of a Forgotten Sky

### Common Items Across All Specs
- **Reshii Wraps** (235499) - Universal cloak with ~97% popularity
- **Ring of Earthen Craftsmanship** (215135) - Crafted ring slot 1
- **Amulet of Earthen Craftsmanship** (215136) - Crafted neck for most specs
- **Interloper's Sabatons** - Class-appropriate feet (Plate: 243307, Leather: 243306, Mail: 243305, Cloth: 243308)

### Technical Notes
- All tier set item IDs are now correct and will show proper WoW tooltips
- Source data based on Archon.gg Mythic+ meta (January 2025)
- Popularity values reflect current M+ usage patterns

---

## Version 1.8.6 (2026-01-29)

### Major Fix
- **Fixed Havoc DH BiS Data**: Completely updated with correct Item IDs from Archon.gg
  - All Tier pieces now show correctly: Charhound's Vicious Scalp (237691), Hornguards (237689), Bindings (237694), Felclaws (237692), Hidecoat (237690)
  - Correct weapons: Interrogator's Flensing Blade (185780), Everforged Warglaive (222441)
  - Correct trinkets: Astral Antenna (242395), Cursed Stone Idol (246344)
  - All rings, neck, back, wrist, waist, feet corrected

### Improvements
- **Re-enabled native WoW tooltips** - Now that Item IDs are correct, hovering shows the actual WoW item tooltip
- **Added Archon.gg Links Reference** - ARCHON_LINKS.md contains all spec links for future BiS updates
- **Tooltip fallback** - If item ID lookup fails, shows KDT data only

### Note
- Other specs still need Item ID updates - they will show incorrect WoW tooltips
- Use `/kdt debugbis` to check your spec's data
- BiS data can be manually edited via right-click on any item

---

## Version 1.8.5 (2026-01-29)

### Bug Fixes
- **Fixed BiS Tooltip showing wrong items**: The tooltip no longer uses WoW's native `SetItemByID()` which was showing incorrect items due to wrong Item IDs in the database
  - Tooltip now shows only KDT's own data: Item Name, Source, Stats, Enchant, Gems
  - Item IDs are displayed but marked as "may need verification"
  - The displayed item **names** and **sources** are correct - only the internal IDs were wrong

### Known Issue
- Item IDs in the database are incorrect and need to be updated with correct values
- This does NOT affect the displayed information - names, sources, enchants, and gems are all correct
- Users can manually correct Item IDs via right-click → Edit if needed

---

## Version 1.8.4 (2026-01-29)

### New Features
- **Added Aldrachi Reaver Spec**: New Demon Hunter 3rd spec for WoW 12.0 (Spec ID: 1456)
  - Full BiS gear set added
  - Note: SpecID may need verification - use `/kdt debugbis` to check

### Debug Commands Added
- `/kdt debugbis` - Shows detailed BiS debugging info:
  - Player's current specID
  - Whether BIS_DATA has entry for that specID
  - What item is being returned for HEAD slot
  - Lists all available specIDs in BIS_DATA
- `/kdt clearbis` - Clears ALL custom BiS data (use if wrong items are showing)

### BiS Troubleshooting
If you're seeing wrong items for your class:
1. Run `/kdt debugbis` to see your specID and what data is loaded
2. Run `/kdt clearbis` to clear any corrupted custom data
3. Report the specID shown if items are still wrong

---

## Version 1.8.3 (2026-01-29)

### Bug Fixes
- **Fixed Death Counter Display**: The death counter was showing 0 even when deaths occurred
  - **Root Cause**: In Lua, `0` is treated as "falsy" in `or` expressions, so `state.deaths or deaths` would ignore `state.deaths` when it was 0
  - **Fix 1**: Changed to explicit nil check: `if state.deaths ~= nil then deaths = state.deaths end`
  - **Fix 2**: Added direct API call in UpdateExternalTimer to always get fresh death count from `C_ChallengeMode.GetDeathCount()`
  - **Fix 3**: UpdateTimerFromGame now always updates `state.deaths` with API value (removed `>` comparison that could skip updates)

---

## Version 1.8.2 (2026-01-29)

### Bug Fixes - Duplicate Run Entries
- **Removed SCENARIO_COMPLETED Event Handler**: This event was firing alongside CHALLENGE_MODE_COMPLETED, causing duplicate saves
- **Improved Save Protection**: 
  - Added `saveScheduled` flag to prevent multiple delayed saves
  - OnChallengeModeCompleted now checks `savedToHistory` before attempting to save
  - Backup save delay increased from 2 to 5 seconds
- **All save paths now check `savedToHistory` flag before saving**

### Save Flow (v1.8.2):
1. M+ completion detected
2. CHALLENGE_MODE_COMPLETED event fires → OnChallengeModeCompleted() → SaveRunToHistory() (sets savedToHistory=true)
3. If event doesn't fire: Polling detects completion → Schedules backup save in 5 seconds
4. Backup save checks savedToHistory flag → Skips if already saved

---

## Version 1.8.1 (2026-01-29)

### Bug Fixes
- **Fixed "attempt to compare a secret value" Error**: WoW 12.0 introduced "secret" GUIDs that cannot be directly compared with `==`. All GUID comparisons and table key usages now convert GUIDs to strings using `tostring()` before use.
- Fixed GUID comparisons in:
  - `OnInspectReady()` - now uses safe GUID matching with pcall
  - `specCache` table keys - all converted to string GUIDs
  - `pendingInspects` table keys - all converted to string GUIDs
  - `lastInspectRequest` table keys - all converted to string GUIDs
  - Spec refresh ticker - uses string GUIDs for cache lookup

---

## Version 1.8.0 (2026-01-29)

### Bug Fixes
- **Fixed API Error**: `C_ChallengeMode.GetCompletionInfo` is properly checked before calling (was causing nil error in WoW 12.0)
- **Fixed Duplicate Run Entries**: Added `savedToHistory` flag to prevent runs from being saved multiple times
  - Flag is checked at the start of SaveRunToHistory
  - Flag is reset when starting a new M+ run
  - Flag is reset in ResetTimer
  - Duplicate check time window increased from 60 to 120 seconds as additional safety

### Technical Changes
- All API calls now properly check if the function exists before calling
- Removed debug spam messages from completion detection

---

## Version 1.7.9 (2026-01-29)

### Bug Fixes - Timer Display
- **Timer Now Updates in M+**: Fixed issue where timer showed but stayed at 0:00. The timer now fetches data directly from the WoW API when in M+, even if the internal state hasn't been initialized yet.
- **Direct API Data Fetching**: Timer overlay now gets elapsed time, time limit, deaths, and forces percentage directly from game APIs:
  - `GetWorldElapsedTime(1)` for elapsed time
  - `C_ChallengeMode.GetMapUIInfo()` for time limit
  - `C_ChallengeMode.GetDeathCount()` for deaths
  - `C_ScenarioInfo.GetCriteriaInfo()` for forces percentage
- **Forces Display**: Improved forces percentage display format

### Improved Debug Command
- `/kdt debugtimer` now shows both internal state AND direct API values for easier troubleshooting

---

## Version 1.7.8 (2026-01-29)

### Bug Fixes
- **Fixed Tab Overlap on Group Change**: When someone joins/leaves the group, the Group Check tab no longer overlaps with the currently active tab. The group refresh now only updates when the Group Check tab is actually selected.
- **Fixed Dynamic Row Hiding**: Member rows, blacklist rows, and BiS rows are now properly hidden when switching tabs.

### Timer Visibility Fix
- **Timer Always Shows in M+**: The timer overlay now always appears in M+ dungeons when "Enable M+ Timer Overlay" is checked, regardless of other settings.
- **Renamed Checkbox**: "Show Timer When Not in M+" renamed to "Show Timer Outside M+ (for positioning)" to clarify its purpose - this option is only for positioning the timer when not in a dungeon.

### Summary of Timer Logic:
- `Enable M+ Timer Overlay` = Timer appears automatically when in M+
- `Show Timer Outside M+ (for positioning)` = Timer also visible outside M+ so you can move/position it

---

## Version 1.7.7 (2026-01-29)

### Bug Fixes
- **Scrollbar Removed**: Recent Runs list no longer has a scrollbar - uses simple frame with clipping
- **Improved Completion Detection**: 
  - Added SCENARIO_COMPLETED event as backup trigger
  - Better API handling for C_ChallengeMode.GetCompletionInfo() and GetChallengeCompletionInfo()
  - Debug messages now show when completion is detected (yellow text)
  - Auto-refresh Timer tab when completion is saved

### New Debug Commands
- `/kdt debugtimer` - Shows complete timer state (active, completed, elapsed time, bosses, forces, etc.)
- `/kdt testrun` - Adds a random test run to history (for testing UI)
- `/kdt clearruns` - Clears all run history

### Technical Notes
If runs are still not being saved after dungeon completion:
1. Use `/kdt debugtimer` at the end of a run to see the timer state
2. Check if you see the yellow "[Debug] CHALLENGE_MODE_COMPLETED event fired!" message
3. If no event fires, the polling fallback should still detect completion

---

## Version 1.7.6 (2026-01-29)

### Bug Fixes - Spec Detection
- **Added INSPECT_READY Event Handler**: Now properly captures spec data when the server responds to inspect requests
- **Improved Spec Cache**: Spec data is now reliably cached and retrieved for all party members
- **Periodic Spec Refresh**: Added a 3-second ticker that automatically tries to get specs for any party members with unknown specs
- **Removed UnitIsVisible Requirement**: Spec detection no longer requires players to be visible (in range), works for all connected party members
- **Auto UI Refresh**: Group tab automatically refreshes when new spec data is retrieved

### Technical Changes
- Created dedicated event frame for INSPECT_READY event
- Spec cache now includes timestamp for cache expiry (5 minute max)
- QueueInspect simplified - main handling done via INSPECT_READY event

---

## Version 1.7.5 (2026-01-29)

### Bug Fixes
- **Fixed WASD Movement**: Keyboard input no longer blocked when addon window is open. ESC handler now only captures the ESC key without affecting movement.

### UI Improvements - Recent Runs
- **Expanded to 30 Runs**: Now stores and displays up to 30 recent dungeon runs
- **3-Column Grid Layout**: Runs displayed in 3 columns side by side instead of a single vertical list
- **Compact Entry Display**: Each entry shows:
  - Status icon (+++ / ++ / + / X) with color coding
  - Dungeon level and name
  - Completion time and death count
  - Date (MM-DD format)
- **Color-Coded Backgrounds**: Green tint for timed runs, red tint for depleted

---

## Version 1.7.4 (2026-01-29)

### Bug Fixes (WoW 12.0 Compatibility)
- **Fixed ADDON_ACTION_BLOCKED Error**: Replaced UISpecialFrames registration with custom ESC handler to avoid protected function errors when other UI panels are opened
- **Fixed UnitIsPlayer Error**: Wrapped tooltip hook in pcall for WoW 12.0 security context compatibility
- **Fixed M+ Completion Detection**: Improved completion detection with multiple methods:
  - Forces threshold lowered to 99.4% (handles rounding)
  - Added C_Scenario.IsComplete() as fallback
  - Completion now prints success message to chat
- **Fixed Spec Detection**: Improved inspect system with retry logic (up to 3 retries) for more reliable spec detection including Protection Paladin

### UI Improvements
- **Removed Scrollbar from Recent Runs**: History box now responsive to window size instead of using scrollbar
- **Default WoW Timer Hidden**: When "Enable M+ Timer Overlay" is checked, the default WoW M+ timer is now hidden (ScenarioBlocksFrame/ObjectiveTracker)

### Technical Changes
- ESC key handler moved from UISpecialFrames to direct OnKeyDown script
- Added UpdateDefaultTimerVisibility() function with multiple fallback methods for different WoW versions
- Inspect system now caches results and auto-refreshes group UI when spec data is retrieved

---

## Version 1.7.3 (2026-01-29)

### Responsive Layout Fix
- **Content Clipping**: Added clipping to content frame to hide elements that overflow when window is resized smaller
- **Dynamic Row Widths**: All list rows (Group Members, Blacklist, BiS items) now use relative widths instead of fixed pixel values
- **Flexible Input Fields**: Blacklist reason input field now stretches dynamically between name input and Add button
- **Legend Box**: BiS tab legend box now uses relative width
- **Fixed Anchor Order**: Resolved "anchor family connection" error by correcting element creation order in GroupTab

---

## Version 1.7.2 (2026-01-29)

### Resizable Window
- **Resize Handle**: Added drag handle in bottom-right corner (standard WoW resize grip icon)
- **Size Persistence**: Window size is saved to SavedVariables and restored on login
- **Size Limits**: 
  - Minimum: 550 x 400 pixels
  - Maximum: 1200 x 900 pixels
  - Default: 700 x 550 pixels

---

## Version 1.7.1 (2026-01-29)

### BiS Tab - In-Game Editor
- **Slot Editor**: Right-click any BiS slot to open the edit dialog
- **Editable Fields**:
  - Item ID
  - Item Name
  - Source (Raid / M+ / Crafted)
  - Drop Location
  - Enchant ID
  - Gem IDs (comma separated)
  - Popularity percentage
- **Save/Reset**: Save changes per slot or reset individual slots to default
- **Reset All**: Button to reset all custom BiS data for current spec
- **Data Persistence**: Custom BiS data saved per spec in SavedVariables

### UI Improvements
- **Removed Unicode Symbols**: Replaced ⚡ and ◆ icons with text labels "E:" (Enchant) and "G:" (Gems) for better compatibility
- **Styled Edit Buttons**: Edit dialog buttons now match addon's dark theme
- **Source Button Highlighting**: Selected source button shows blue highlight
- **Removed Archon Link**: Removed "archon.gg/wow/builds" text from bottom of BiS tab

### Localization
- **All Text in English**: Translated all remaining German text to English:
  - "Speichern" → "Save"
  - "Gespeichert!" → "Saved!"
  - "0 = keine" → "0 = none"
  - "Komma getrennt" → "comma separated"
  - "Rechtsklick zum Bearbeiten" → "Right-click to edit"
  - Popup dialogs and status messages

### Code Cleanup
- Removed Python importer tool (archon_importer.py)
- Removed import/export string system
- Removed base64 encoding functions
- Simplified slash commands (removed /kdt import, /kdt export, /kdt archon)

---

## Version 1.7.0 (2026-01-29)

### BiS Tab Enhancements
- **Enchant & Gem Data**: Added enchantment and gem recommendations for each BiS slot
- **Season 3 Enchants**: Database of 17 current enchants (weapon, chest, back, wrist, legs, feet, rings)
- **Season 3 Gems**: Database of 6 current gems (meta gems, epic stat gems)
- **Enhanced Display**: 
  - Three-line format per slot: Item name, Source, Enchant/Gems
  - Popularity percentage with color coding (green >50%, yellow >25%, orange <25%)
  - Tooltip shows best enchant and gem recommendations

### More Default Spec Data
Added BiS data for additional specs (total 19 specs):
- **Death Knight**: Frost, Unholy, Blood
- **Mage**: Fire, Frost
- **Hunter**: Beast Mastery
- **Paladin**: Retribution
- **Priest**: Shadow
- **Druid**: Balance
- **Monk**: Windwalker
- (Previously: Rogue x3, Demon Hunter x2, Warrior x3)

### New Slash Commands
- `/kdt bis` - Open BiS Gear tab
- `/kdt resetbis` - Reset all custom BiS data for current spec

---

## Summary of Today's Changes

### Added
- ✅ Resizable main window with size persistence
- ✅ In-game BiS slot editor (right-click to edit)
- ✅ Enchant and gem tracking/display
- ✅ 10 additional spec default data sets
- ✅ Content clipping for responsive layout

### Changed
- 🔄 All UI elements now use relative positioning
- 🔄 Removed Unicode symbols for better font compatibility
- 🔄 All text translated to English
- 🔄 Edit dialog styled to match addon theme

### Removed
- ❌ Python importer tool
- ❌ Import/Export string system
- ❌ Archon.gg link display

### Fixed
- 🐛 "RegisterForClicks" error on Frame (changed to OnMouseUp)
- 🐛 Element anchor order causing SetPoint errors
- 🐛 UI elements overflowing when window resized smaller
