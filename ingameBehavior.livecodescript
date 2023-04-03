script "ingameBehavior"

/* FIX being able to reorder columns */
/* Double click open valorant tracker */

/* Valorant vars */
global sPdUrl, sGlzUrl
global sRegion
global sCurrentSeason
global sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol
global sHeaders, sPUUID
global sCurrentVersion
global sSetup
global sWeapons, sWeaponList
global sAgents
global sSettings

local sTeams

/* UI vars */
global tRunning

on closeStack
  put false into tRunning
  close this stack
end closeStack

on inGameSetup
  clearControls
  createControls
  inGameSetupRecursive
end inGameSetup

on inGameSetupRecursive
  valorantSetup
  if sSetup then
    put true into tRunning
    local tPresences, tPrivatePresence, tGameState
    put "INGAME" into tGameState

    local tMatchID, tMatchStats
    put getMatchID(0) into tMatchID
    if tMatchID is false then
      goToPreLoad
    end if

    put getPresences() into tPresences
    put getPrivatePresence(tPresences) into tPrivatePresence
    put tPrivatePresence["sessionLoopState"] into tGameState

    local tDidFail
    put getTeams(tMatchID, tPresences, tDidFail) into sTeams

    local tGamemode
    if tPrivatePresence["provisioningFlow"] is "CustomGame" then
      put "Custom Game" into tGamemode
    else
      put tPrivatePresence["queueid"] into tGamemode
    end if

    set the text of field "stateField" to capitalizeWords(tGamemode) & space & slash & slash & space & capitalizeWords(sTeams["map"])

    setupPolylist
    if tGameState is "INGAME" then
      if tDidFail then
        send "inGameSetupRecursive" to me in 50 milliseconds
      else
        send "mainLoop" to me in 1 seconds
      end if
    else
      goToPreLoad
    end if
  else
    goToPreLoad
  end if
end inGameSetupRecursive

on resizeStack
  layoutControls
end resizeStack

on clearControls
  repeat with x = (the number of controls of card "inGame") down to 1
    if there is a control x of card "inGame" then delete control x of card "inGame"
  end repeat
end clearControls

on createControls
  /* Clean up stack */
  clearControls

  set the backgroundcolor of me to "0,120,200"

  create field "stateField" in card "inGame"
  set the lockText of field "stateField" to true
  set the textAlign of field "stateField" to "center"
  set the textSize of field "stateField" to 14
  set the textStyle of field "stateField" to "bold"
  set the textHeight of field "stateField" to 30
  set the margins of field "stateField" to 0
  set the borderWidth of field "stateField" to 0
  set the opaque of field "stateField" to false

  create group "playersGroup" in card "inGame"
  set the lockLoc of group "playersGroup" to true

  create widget "playersPolylist" as "com.livecode.widget.polylist" in group "playersGroup" of card "inGame"
  set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
  set the margin of widget "playersPolylist" to 1
  set the borderWidth of widget "playersPolylist" to 0
  set the itemRoundRadius of widget "playersPolylist" to 5
  set the autohilite of widget "playersPolylist" to false
  set the blendLevel of widget "playersPolylist" to 8
  set the plitemcolor of widget "playersPolylist" to "0,0,0,0"

  set the width of the templategraphic to 4
  set the opaque of the templategraphic to true
  set the lineSize of the templategraphic to 0
  set the backgroundColor of the templategraphic to "#929292"

  create invisible button "rightClickMenu" in card "inGame"
  set the menuMode of button "rightClickMenu" to "popup"
  set the style of button "rightClickMenu" to "menu"

  reset the templategraphic

  layoutControls
end createControls

on layoutControls
  set the minWidth of this stack to the number of items of sSettings["visibleSections"] * 100
  set the minHeight of this stack to 300
  if the width of this stack < the minWidth of this stack then
    set the width of this stack to the minWidth of this stack
  end if
  if the height of this stack < the minHeight of this stack then
    set the height of this stack to the minHeight of this stack
  end if

  /* set field rect */
  set the width of field "stateField" to the width of me
  set the height of field "stateField" to 35
  set the topLeft of field "stateField" to 0, 0
  
  /* set group rect */
  set the width of group "playersGroup" to the width of me
  set the height of group "playersGroup" to the height of me - 35
  set the topLeft of group "playersGroup" to 0, 35

  /* set polylist rect */
  set the width of widget "playersPolylist" to the width of group "playersGroup"
  set the height of widget "playersPolylist" to the height of group "playersGroup"
  set the topLeft of widget "playersPolylist" to the topLeft of group "playersGroup"

  local tItemHeight, tRows
  put min(1,the numberofelements of widget "playersPolylist") into tRows
  put ((the height of me - 35 - ((the margin of widget "playersPolylist" + the borderWidth of widget "playersPolylist") * tRows)) / (tRows)) into tItemHeight
  put min(max(tItemHeight, 25), 50) into tItemHeight
  set the itemHeight of widget "playersPolylist" to tItemHeight
end layoutControls

on setupPolylist
  set the tsvData of widget "playersPolylist" to getTsvData(sTeams)
  set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
  layoutControls
end setupPolylist

function getPolylistDataLayout
  local rDataLayout

  put "background" into rDataLayout[1]["name"]
  put "100" into rDataLayout[1]["height"]
  put "0" into rDataLayout[1]["top"]
  put "0" into rDataLayout[1]["left"]
  put "100" into rDataLayout[1]["width"]
  put "color" into rDataLayout[1]["content-type"]

  local tColumnCount
  put 0 into tColumnCount
  repeat for each item tColumn in sSettings["visibleSections"]
    local tCurrentColumn
    put tColumn into tCurrentColumn["name"]
    put "100" into tCurrentColumn["height"]
    put "0" into tCurrentColumn["top"]
    put (round(100 / the number of items of sSettings["visibleSections"]) * tColumnCount)  into tCurrentColumn["left"]
    put round(100 / the number of items of sSettings["visibleSections"]) into tCurrentColumn["width"]
    put "center" into tCurrentColumn["align"]
    put "text-multiline" into tCurrentColumn["content-type"]
    appendArray rDataLayout, tCurrentColumn
    add 1 to tColumnCount
  end repeat

  return rDataLayout
end getPolylistDataLayout

on toggleVisibleSection pSection
  set wholematches to true
  if pSection is among the items of sSettings["visibleSections"] then
    delete item itemoffset(pSection,sSettings["visibleSections"]) of sSettings["visibleSections"]
  else
    put comma & pSection after sSettings["visibleSections"]
  end if

end toggleVisibleSection

on menuPick pChosenItem
  set the itemdelimiter to "|"
  if item 1 of pChosenItem is "Bannable Settings" then
    switch item 2 of pChosenItem
    case "Show Hidden Ranks"
      put not sSettings["alwaysShowRank"] into sSettings["alwaysShowRank"]
      break
    case "Show Hidden Names"
      put not sSettings["alwaysShowName"] into sSettings["alwaysShowName"]
      break
    case "Show Hidden Levels"
      put not sSettings["alwaysShowLevel"] into sSettings["alwaysShowLevel"]
      break
    end switch
  else if item 1 of pChosenItem is "Parties" then
    switch item 2 of pChosenItem
    case "Dye"
      put not sSettings["showParties"] into sSettings["showParties"]
      break
    case "Number"
      toggleVisibleSection "party"
      break
    end switch
  else if item 1 of pChosenItem is "Visible Weapons" then
    toggleVisibleSection (item 2 of pChosenItem)
  else
    toggleVisibleSection (item 1 of pChosenItem)
  end if
  saveSettings
  setupPolylist
  set the itemdelimiter to comma
end menuPick

function generateRightClickMenu
  local tMenu
  put empty into tMenu

  put "(Visible Sections" & return after tMenu
  repeat for each item tItem in "agent,name,rank,peak,winrate,level"
    if tItem is among the items of sSettings["visibleSections"] then
      put "!c" & capitalizeWords(tItem) & return after tMenu
    else
      put capitalizeWords(tItem) & return after tMenu
    end if
  end repeat

  put "Visible Weapons" & return after tMenu
  repeat for each item tWeapon in getWeaponList()
    if tWeapon is among the items of sSettings["visibleSections"] then
      put tab & "!c" & capitalizeWords(tWeapon) & return after tMenu
    else
      put tab & capitalizeWords(tWeapon) & return after tMenu
    end if
  end repeat
  put "-" & return after tMenu

  put "Parties" & return after tMenu
  if sSettings["showParties"] is true then
    put tab & "!cDye" & return after tMenu
  else
    put tab & "Dye" & return after tMenu
  end if
  if "party" is among the items of sSettings["visibleSections"] then
    put tab & "!cNumber" & return after tMenu
  else
    put tab & "Number" & return after tMenu
  end if
  put "-" & return after tMenu

  put "Bannable Settings" & return after tMenu
  put tab & "(These settings are against Valorant" & return after tMenu
  put tab & "(TOS and may result in a ban" & return after tMenu
  if sSettings["alwaysShowRank"] is true then
    put tab & "!cShow Hidden Ranks" & return after tMenu
  else
    put tab & "Show Hidden Ranks" & return after tMenu
  end if

  if sSettings["alwaysShowName"] is true then
    put tab & "!cShow Hidden Names" & return after tMenu
  else
    put tab & "Show Hidden Names" & return after tMenu
  end if

  if sSettings["alwaysShowLevel"] is true then
    put tab & "!cShow Hidden Levels" & return after tMenu
  else
    put tab & "Show Hidden Levels" & return after tMenu
  end if
  return tMenu
end generateRightClickMenu

on mouseUp pButton
  if pButton is 3 then
    set the text of button "rightClickMenu" to generateRightClickMenu()
    popup button "rightClickMenu" at the mouseloc
  end if
end mouseUp

on mouseDown
  
end mouseDown

function blendColors pC1, pC2
  put item 1 of pC1 into tR1
  put item 2 of pC1 into tG1
  put item 3 of pC1 into tB1
  put item 4 of pC1 into tA1
  
  put item 1 of pC2 into tR2
  put item 2 of pC2 into tG2
  put item 3 of pC2 into tB2
  put item 4 of pC2 into tA2

  local rR, rG, rB, rA, rBlendedColor
  put round((tR1 + tR2) / 2) into rR
  put round((tG1 + tG2) / 2) into rG
  put round((tB1 + tB2) / 2) into rB
  put round((tA1 + tA2) / 2) into rA
  
  put rR & "," & rG & "," & rB & "," & rA into rBlendedColor
  
  return rBlendedColor
end blendColors

function capitalizeWords pString
  local tCapString
  put empty into tCapString
  repeat for each word tWord in pString
    put toUpper(character 1 of tWord) & (character 2 to -1 of tWord) & space after tCapString
  end repeat
  if the last character of tCapString is space then delete the last character of tCapString
  return tCapString
end capitalizeWords

function getTsvData pTeams
  if pTeams["myTeam"] is empty then
    return empty
  end if

  local tTsvData, tPartyCount
  put 1 into tPartyCount
  put empty into tTsvData

  /* Create tsv headers */
  put "background" & tab after tTsvData
  put "agent" & tab after tTsvData
  put "name" & tab after tTsvData
  repeat for each item tWeapon in getWeaponList()
    put tWeapon & tab after tTsvData
  end repeat
  put "rank" & tab after tTsvData
  put "peak" & tab after tTsvData
  put "winrate" & tab after tTsvData
  put "level" & return after tTsvData

  /* Create visible headers */
  put empty & tab after tTsvData
  put "Agent" & tab after tTsvData
  put "Name" & tab after tTsvData
  repeat for each item tWeapon in getWeaponList()
    put capitalizeWords(tWeapon) & tab after tTsvData
  end repeat
  put "Rank" & tab after tTsvData
  put "Peak" & tab after tTsvData
  put "Winrate" & tab after tTsvData
  put "Level" & return after tTsvData

  local tMyTeam, tOtherTeam
  put pTeams[pTeams["myTeam"]] into tMyTeam
  put pTeams[pTeams["otherTeam"]] into tOtherTeam

  put teamToTsv(tMyTeam, sSettings["blueColor"], tPartyCount) after tTsvData
  put teamToTsv(tOtherTeam, sSettings["redColor"], tPartyCount) after tTsvData
  
  return tTsvData
end getTsvData

function teamToTsv pTeam, pDefaultColor, @xPartyCount
  local rTsvData
  repeat for each element tParty in pTeam
    repeat for each element tTeammate in tParty
      /* Background */
      if tTeammate["UUID"] is sPUUID then
        put sSettings["myColor"] & tab after rTsvData
      else
        if the number of elements of tParty is 1 or sSettings["showParties"] is false then
          put pDefaultColor & tab after rTsvData
        else
          put blendColors(pDefaultColor, sSettings["partyColors"][xPartyCount]) & tab after rTsvData
        end if
      end if
      
      /* Agent */
      put tTeammate["agent"] & tab after rTsvData
      
      /* Name */
      if sSettings["alwaysShowName"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID  then
        put tTeammate["name"] & tab after rTsvData
      else
        put "--" & tab after rTsvData
      end if

      /* Weapons */
      repeat for each item tWeapon in getWeaponList()
        put tTeammate["Loadout"][tWeapon]["Skin"] & tab after rTsvData
      end repeat
      
      /* Rank */
      if sSettings["alwaysShowRank"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID  then
        if tTeammate["stats"]["rr"] is "N/A" or tTeammate["stats"]["rank"] is "Unranked" then
          put tTeammate["stats"]["rank"] & tab after rTsvData
        else
          put tTeammate["stats"]["rank"] & "(" & tTeammate["stats"]["rr"] & ")" & tab after rTsvData
        end if
      else
        put "--" & tab after rTsvData
      end if

      /* Peak */
      if sSettings["alwaysShowRank"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID  then
        put tTeammate["stats"]["peak"] & tab after rTsvData
      else
        put "--" & tab after rTsvData
      end if
      
      /* Winrate */
      if sSettings["alwaysShowWinrate"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID  then
        if tTeammate["stats"]["wr"] is -1 then
          put "N/A" & tab after rTsvData
        else
          put round(tTeammate["stats"]["wr"] * 100) & "%" & tab after rTsvData
        end if
      else
        put "--" & tab after rTsvData
      end if

      /* Level */
      if sSettings["alwaysShowLevel"] or tTeammate["hiddenLevel"] is false or tTeammate["uuid"] is sPUUID then
        put tTeammate["level"] & return after rTsvData
      else
        put "--" & return after rTsvData
      end if
    end repeat
    if the number of elements of tParty > 1 then
      add 1 to xPartyCount
    end if
  end repeat
  return rTsvData
end teamToTsv

on mainLoop
  if not tRunning then
     exit mainLoop
  end if

  valorantSetup

  local tGameState
  put getPresences() into tPresences
  put getPrivatePresence(tPresences) into tPrivatePresence
  put tPrivatePresence["sessionLoopState"] into tGameState

  /* Update UI */
  layoutControls

  if tRunning then
    if tGameState is "INGAME" then
      send "mainLoop" to me in 1 seconds
    else
      goToPreLoad
    end if
  end if
end mainLoop
