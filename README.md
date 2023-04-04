# - Valorant Displayer -
Displays stats about players in your valorant games.
Built using LiveCode.

## Download Instructions
There are two ways to download, installer or manual.

### Installer
1. Go to [Dist/Installers](Dist/Installers)
2. Select your version
3. Download `Installer.exe`
4. Run `Installer.exe` and follow the installation instructions

### Manual
1. Go to [Dist/Files](Dist/Files)
2. Select your version
3. Download the contents
 * `Externals/`
 * `revsecurity.dll`
 * `ValorantDisplayer.exe`
4. Place the contents in the folder you want on your PC
5. Run ValorantDisplayer.exe

## To Do:
 - [ ] Complete UI overhaul
 - [ ] Allow user to reorder columns (might be made redundant by UI overhaul)
 - [ ] Fix stats disappearing occasionally
 - [ ] Double click open valorant tracker
 - [ ] Implement way to view players full inventory
 - [x] Fix stack not closing on stack close occasionally
 - [x] Allow user to view "Streamer Mode" details
 - [ ] Potential smurf marker (can be disabled) which highlights players with high ADR/ low level (and potentially no vandal) ((add setting for ADR limit, with defaults (low - 170, mid - 190, high - 210+))
 - [ ] Add support for previously played with
     1. Store in a folder of current PUUID
     2. Store player name, agent, map, date, puuid
     3. When puuids match check if names match and if not show old name
 - [ ] Add support for viewing gun buddys
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
