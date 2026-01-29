# KryosDungeonTool Changelog

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
