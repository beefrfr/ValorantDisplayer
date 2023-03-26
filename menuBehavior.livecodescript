script "menuBehavior"

/* Valorant vars */
global sPdUrl, sGlzUrl
global sRegion
global sCurrentSeason
global sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol
global sHeaders, sPUUID
global sCurrentVersion
global sSetup

/* UI vars */
local sDivAgentName, sDivNameSkin, sDivSkinRank, sDivRankPeak, sDivPeakWR, sDivWRLevel
global tRunning

/* Constants */
constant kDividerNames = "agent/name,name/skin,skin/rank,rank/peak,peak/wr,wr/level"
constant kDividerBuffer = 10

on closeStack
  put false into tRunning
  close this stack
end closeStack

on menuSetup
  clearControls
  createControls
  valorantSetup
  if sSetup then
    put true into tRunning
    mainLoop
  else
    go to card "preLoad"
    send "redirect" to card "preLoad" in 5 milliseconds
  end if
end menuSetup

on resizeStack
  layoutControls
end resizeStack

on clearControls
  repeat with x = (the number of controls of card "menu") down to 1
    if there is a control x of card "menu" then delete control x of card "menu"
  end repeat
end clearControls

on createControls
  /* Clean up stack */
  clearControls
  put 10 into sDivAgentName
  put 25 into sDivNameSkin
  put 60 into sDivSkinRank
  put 70 into sDivRankPeak
  put 80 into sDivPeakWR
  put 90 into sDivWRLevel

  create field "stateField" in card "menu"
  set the lockText of field "stateField" to true
  set the textAlign of field "stateField" to "center"

  create group "playersGroup" in card "menu"
  set the lockLoc of group "playersGroup" to true

  create widget "playersPolylist" as "com.livecode.widget.polylist" in group "playersGroup" of card "menu"
  set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()

  set the width of the templategraphic to 4
  set the opaque of the templategraphic to true
  set the lineSize of the templategraphic to 0
  set the backgroundColor of the templategraphic to "#929292"

  repeat for each item tDividerName in kDividerNames
    create graphic tDividerName in group "playersGroup" of card "menu"
  end repeat

  reset the templategraphic

  layoutControls
end createControls

on layoutControls
  set the minWidth of this stack to 7 * 100
  set the minHeight of this stack to 300

  /* set field rect */
  set the width of field "stateField" to the width of me
  set the height of field "stateField" to 20
  set the topLeft of field "stateField" to 0, 0
  
  /* set group rect */
  set the width of group "playersGroup" to the width of me
  set the height of group "playersGroup" to the height of me - 20
  set the topLeft of group "playersGroup" to 0, 20

  /* set polylist rect */
  set the width of widget "playersPolylist" to the width of group "playersGroup"
  set the height of widget "playersPolylist" to the height of group "playersGroup"
  set the topLeft of widget "playersPolylist" to the topLeft of group "playersGroup"

  /* set divider rects */
  repeat for each item tDividerName in kDividerNames
    set the height of graphic tDividerName to the dataHeight of widget "playersPolylist"
  end repeat

  set the topLeft of graphic "agent/name" to the width of group "playersGroup" * (sDivAgentName / 100), the top of group "playersGroup"
  set the topLeft of graphic "name/skin" to the width of group "playersGroup" * (sDivNameSkin / 100), the top of group "playersGroup"
  set the topLeft of graphic "skin/rank" to the width of group "playersGroup" * (sDivSkinRank / 100), the top of group "playersGroup"
  set the topLeft of graphic "rank/peak" to the width of group "playersGroup" * (sDivRankPeak / 100), the top of group "playersGroup"
  set the topLeft of graphic "peak/wr" to the width of group "playersGroup" * (sDivPeakWR / 100), the top of group "playersGroup"
  set the topLeft of graphic "wr/level" to the width of group "playersGroup" * (sDivWRLevel / 100), the top of group "playersGroup"

end layoutControls

function getPolylistDataLayout
  local rDataLayout

  put "background" into rDataLayout[1]["name"]
  put "100" into rDataLayout[1]["height"]
  put "0" into rDataLayout[1]["top"]
  put "0" into rDataLayout[1]["left"]
  put "100" into rDataLayout[1]["width"]
  put "color" into rDataLayout[1]["content-type"]

  put "agent" into rDataLayout[2]["name"]
  put "100" into rDataLayout[2]["height"]
  put "0" into rDataLayout[2]["top"]
  put "0" into rDataLayout[2]["left"]
  put sDivAgentName into rDataLayout[2]["width"]
  put "center" into rDataLayout[2]["align"]
  put "text-multiline" into rDataLayout[2]["content-type"]

  put "name" into rDataLayout[3]["name"]
  put "100" into rDataLayout[3]["height"]
  put "0" into rDataLayout[3]["top"]
  put sDivAgentName into rDataLayout[3]["left"]
  put sDivNameSkin - sDivAgentName into rDataLayout[3]["width"]
  put "center" into rDataLayout[3]["align"]
  put "text-multiline" into rDataLayout[3]["content-type"]

  put "skin" into rDataLayout[4]["name"]
  put "100" into rDataLayout[4]["height"]
  put "0" into rDataLayout[4]["top"]
  put sDivNameSkin into rDataLayout[4]["left"]
  put sDivSkinRank - sDivNameSkin into rDataLayout[4]["width"]
  put "center" into rDataLayout[4]["align"]
  put "text-multiline" into rDataLayout[4]["content-type"]

  put "rank" into rDataLayout[5]["name"]
  put "100" into rDataLayout[5]["height"]
  put "0" into rDataLayout[5]["top"]
  put sDivSkinRank into rDataLayout[5]["left"]
  put sDivRankPeak - sDivSkinRank into rDataLayout[5]["width"]
  put "center" into rDataLayout[5]["align"]
  put "text-multiline" into rDataLayout[5]["content-type"]

  put "peak" into rDataLayout[6]["name"]
  put "100" into rDataLayout[6]["height"]
  put "0" into rDataLayout[6]["top"]
  put sDivRankPeak into rDataLayout[6]["left"]
  put sDivPeakWR - sDivRankPeak into rDataLayout[6]["width"]
  put "center" into rDataLayout[6]["align"]
  put "text-multiline" into rDataLayout[6]["content-type"]

  put "wr" into rDataLayout[7]["name"]
  put "100" into rDataLayout[7]["height"]
  put "0" into rDataLayout[7]["top"]
  put sDivPeakWR into rDataLayout[7]["left"]
  put sDivWRLevel - sDivPeakWR into rDataLayout[7]["width"]
  put "center" into rDataLayout[7]["align"]
  put "text-multiline" into rDataLayout[7]["content-type"]

  put "level" into rDataLayout[8]["name"]
  put "100" into rDataLayout[8]["height"]
  put "0" into rDataLayout[8]["top"]
  put sDivWRLevel into rDataLayout[8]["left"]
  put 100 - sDivWRLevel into rDataLayout[8]["width"]
  put "center" into rDataLayout[8]["align"]
  put "text-multiline" into rDataLayout[8]["content-type"]

  return rDataLayout
end getPolylistDataLayout

on mouseDown
  if the short name of the target is in kDividerNames then
    local tLeft, tMinLeft, tMaxLeft

    switch the short name of the target
    case "agent/name"
      put kDividerBuffer into tMinLeft
      put sDivNameSkin - kDividerBuffer into tMaxLeft
      break
    case "name/skin"
      put sDivAgentName + kDividerBuffer into tMinLeft
      put sDivSkinRank - kDividerBuffer into tMaxLeft
      break
    case "skin/rank"
      put sDivNameSkin + kDividerBuffer into tMinLeft
      put sDivRankPeak - kDividerBuffer into tMaxLeft
      break
    case "rank/peak"
      put sDivSkinRank + kDividerBuffer into tMinLeft
      put sDivPeakWR - kDividerBuffer into tMaxLeft
      break
    case "peak/wr"
      put sDivRankPeak + kDividerBuffer into tMinLeft
      put sDivWRLevel - kDividerBuffer into tMaxLeft
      break
    case "wr/level"
      put sDivPeakWR + kDividerBuffer into tMinLeft
      put 100 - kDividerBuffer into tMaxLeft
      break
    end switch

    repeat while the mouse is down
      put item 1 of the mouseLoc into tLeft
      put 100 * ((tLeft - the left of group "playersGroup") / the width of group "playersGroup") into tLeft
      if tLeft < tMinLeft then
        put tMinLeft into tLeft
      else if tLeft > tMaxLeft then
        put tMaxLeft into tLeft
      end if
      switch the short name of the target
      case "agent/name"
        put tLeft into sDivAgentName
        break
      case "name/skin"
        put tLeft into sDivNameSkin
        break
      case "skin/rank"
        put tLeft into sDivSkinRank
        break
      case "rank/peak"
        put tLeft into sDivRankPeak
        break
      case "peak/wr"
        put tLeft into sDivPeakWR
        break
      case "wr/level"
        put tLeft into sDivWRLevel
        break
      end switch
      set the topLeft of the target to the width of group "playersGroup" * (tLeft / 100), the top of group "playersGroup"
      set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
      wait 1 milliseconds with messages
    end repeat
  end if
end mouseDown

on mainLoop
  local tPresences, tPrivatePresence, tGameState
  put "MENUS" into tGameState
  repeat while tGameState is "MENUS" and tRunning
    put getPresences() into tPresences
    put getPrivatePresence(tPresences) into tPrivatePresence
    put tPrivatePresence["sessionLoopState"] into tGameState

    if not tRunning then
       exit mainLoop
    end if

    local tTsvData
    put "backgrounds" & tab & "agent" & tab & "name" & tab & "skin" & tab & "rank" & tab & "peak" & tab & "wr" & tab & "level" & return into tTsvData
    put "102,102,102,102" & tab & "Agent Name" & tab & "Name" & tab & "Vandal Skin" & tab & "Rank (RR)" & tab & "Peak Rank" & tab & "Winrate" & tab & "Level" & return after tTsvData
    repeat for each element tPartyMember in getPartyMemberData(tPresences)
      put "102,102,102,102" & tab after tTsvData
      put "-" & tab after tTsvData
      put tPartyMember["name"] & tab after tTsvData
      put "-" & tab after tTsvData
      put tPartyMember["rank"] & "(" & tPartyMember["rr"] & ")" & tab after tTsvData
      put tPartyMember["peak"] & tab after tTsvData
      put round(tPartyMember["wr"] * 100) & "%" & tab after tTsvData
      put tPartyMember["level"] & return after tTsvData
    end repeat
    set the tsvData of widget "playersPolylist" to tTsvData

    /* Update UI */
    layoutControls

    repeat for 1000 times
      wait 1 milliseconds with messages
    end repeat
  end repeat
  if tRunning then
    go to card "preLoad"
    send "redirect" to card "preLoad" in 5 milliseconds
  end if
end mainLoop
