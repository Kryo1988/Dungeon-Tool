# KryosDungeonTool Changelog

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
