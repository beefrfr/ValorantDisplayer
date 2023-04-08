# - Valorant Displayer -
Displays stats about players in your valorant games.
Built using LiveCode.

## Download Instructions
1. Go to [Dist](Dist)
2. Select your version
3. Download `Installer.exe`
4. Run `Installer.exe` and follow the installation instructions

## To Do:
 - [ ] Select visible columns from menu at the top (should be in dropdowns within menu, e.g. ranks, weapons, player info
     - [ ] separators need to be dynamically created now -- reduce margin on them
 - [ ] Allow polylist to be wider than current window (with a setting) so extra rows dont cramp the screen
 - [ ] `Ban Mode` that will allow users to view hidden players stats (against riot api TOS)
 - [ ] make different menus for menu, in game, and pregame
 - [ ] Double click a player to show their full inventory (layout like valorant using png template of inventory)
 - [ ] Potential smurf marker (can be disabled) which highlights players with high ADR/ low level (and potentially no vandal) ((add setting for ADR limit, with defaults (low - 170, mid - 190, high - 210+)
 - [ ] Fix redirect screen to
     1. Show status of what's happening so users knows it's not hanging
     2. Show if Valorant isn't open (if user clicks button saying it is, provide textlog for error feedback)
 - [ ] Previously played with (`%appdata%/local`)
     1. Store in a folder of current PUUID
     2. Store player name, agent, map, date, puuid
     3. When puuids match check if names match and if not show old name
 - [ ] Show players with riot gun buddy


## Save as Standalone Instructions
1. Open Project Browser
3. Delete all substacks of `displayerStack`
4. For each stack other than `displayerStack` open Property Inspector and set the "Main Stack" to `displayerStack`
5. Supress messages
6. Stop all current running code (`ctrl` + `.`)
7. Update standalone settings
8. Build standalone (if it asks to save, save it)
9. Close livecode
10. Fix folder structure of created standalone
 * Move all files into `Dist/Files/{version}`
11. Commit standalone
12. Delete changes to `displayer.livecode`
13. Rename created folder in `Dist/Files/` to be the App Version
14. Change `AppVersion` in `ValorantDisplayerSetupScript.iss` to be the App 
Version defined in step 9
15. Compile installer using Inno Setup
