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
 - [ ] Loading assets (ranks & agents) should be stored locally once downloaded, decreases startup time
 - [ ] Change all redirects to be in `valorantBehavior.livecodescript` instead of `preLoad.livecodescript`, preload should be used exclusively for loading files - show description of what is currently happening, what files are being downloaded, and provide a progress bar. Should be able to reduce the currently HIGH initial loading time.
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
1. Update constants in `valorantBehavior.livecodescript` and `updaterBehavior.livecodescript`
2. Compile `updater.livecode`
3. Delete `assets/downloaded/` folder
4. Open Project Browser
5. Delete all substacks of `displayerStack`
6. For each stack other than `displayerStack` open Property Inspector and set the "Main Stack" to `displayerStack`
7. Supress messages
8. Stop all current running code (`ctrl` + `.`)
9. Update standalone settings
10. Build standalone (if it asks to save, save it)
11. Close livecode
12. Fix folder structure of created standalone
 * Move all files into `Dist/Files/{version}`
13. Commit standalone
14. Delete changes to `displayer.livecode`
15. Rename created folder in `Dist/Files/` to be the App Version
16. Change `AppVersion` in `ValorantDisplayerSetupScript.iss` to be the App 
Version defined in step 9
17. Compile installer using Inno Setup
