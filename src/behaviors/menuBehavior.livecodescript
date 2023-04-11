script "menuBehavior"

/* Valorant vars */
global sPdUrl, sGlzUrl
global sRegion
global sCurrentSeason
global sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol
global sHeaders, sPUUID
global sCurrentVersion
global sSetup
global sWeapons, sWeaponList
global sAgents, sMaps, sRanks
global sSettings
global sSeasons
global sActs
global sFetchDataCache
global sShouldCache

local sParty

/* UI vars */

constant kCurrentCard = "menu"
constant kGameState = "MENUS"

on menuSetup
  clearControls
  createControls
  mainLoop
end menuSetup

on resizeStack
  layoutControls
end resizeStack

on clearControls
  repeat with x = (the number of controls of card kCurrentCard) down to 1
    if there is a control x of card kCurrentCard then delete control x of card kCurrentCard
  end repeat
end clearControls

on createControls
  /* Clean up stack */
  clearControls

  set the backgroundcolor of me to "34, 42, 53"

  create field "stateField" in card kCurrentCard
  set the lockText of field "stateField" to true
  set the textAlign of field "stateField" to "center"
  set the textSize of field "stateField" to 14
  set the textStyle of field "stateField" to "bold"
  set the textHeight of field "stateField" to 30
  set the margins of field "stateField" to 0
  set the borderWidth of field "stateField" to 0
  set the opaque of field "stateField" to false

  create group "playersGroup" in card kCurrentCard
  set the lockLoc of group "playersGroup" to true

  create widget "playersPolylist" as "com.livecode.widget.polylist" in group "playersGroup" of card kCurrentCard
  set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
  set the margin of widget "playersPolylist" to 1
  set the borderWidth of widget "playersPolylist" to 0
  set the itemRoundRadius of widget "playersPolylist" to 5
  set the autohilite of widget "playersPolylist" to false
  set the blendLevel of widget "playersPolylist" to 8
  set the plitemcolor of widget "playersPolylist" to "0,0,0,0"
  set the enableImageCache of widget "playersPolylist" to false
  set the dataContent of widget "playersPolylist" to empty

  set the width of the templategraphic to 4
  set the opaque of the templategraphic to true
  set the lineSize of the templategraphic to 0
  set the backgroundColor of the templategraphic to "#929292"

  create invisible button "rightClickMenu" in card kCurrentCard
  set the menuMode of button "rightClickMenu" to "popup"
  set the style of button "rightClickMenu" to "menu"

  reset the templategraphic

  layoutControls
end createControls

on layoutControls
  try
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
    put max(1,the numberofelements of widget "playersPolylist") into tRows
    put ((the height of me - 35 - ((the margin of widget "playersPolylist" + the borderWidth of widget "playersPolylist") * tRows)) / (tRows)) into tItemHeight
    put min(max(tItemHeight, 100), 200) into tItemHeight
    set the itemHeight of widget "playersPolylist" to tItemHeight

    set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
  catch tErr
    createControls
    layoutControls
  end try
end layoutControls

on setupPolylist
  set the dataContent of widget "playersPolylist" to getPolylistData(sParty)
  set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
  layoutControls
end setupPolylist

function itemHeightPercentToPixels pItemHeight, pPercent
  return round(pPercent * pItemHeight) & "px"
end itemHeightPercentToPixels

function getPolylistDataLayout
  local rDataLayout, tItemHeight
  put the itemHeight of widget "playersPolylist" into tItemHeight

  put "agent" into rDataLayout[1]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.6) into rDataLayout[1]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.6) into rDataLayout[1]["height"]
  put "20px" into rDataLayout[1]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.2) into rDataLayout[1]["top"]
  put "image-data" into rDataLayout[1]["content-type"]
  put "scale-down" into rDataLayout[1]["content-fit"]

  put "party" into rDataLayout[2]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[2]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[2]["height"]
  put "10px" into rDataLayout[2]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[2]["top"]
  put "image-file" into rDataLayout[2]["content-type"]
  put "scale-down" into rDataLayout[2]["content-fit"]
  put true into rDataLayout[2]["dropShadow"]

  put "team" into rDataLayout[3]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[3]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[3]["height"]
  put "10px" into rDataLayout[3]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[3]["top"]
  put "image-file" into rDataLayout[3]["content-type"]
  put "scale-down" into rDataLayout[3]["content-fit"]
  put true into rDataLayout[3]["dropShadow"]

  put "level" into rDataLayout[4]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.25) into rDataLayout[4]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.15) into rDataLayout[4]["height"]
  put itemHeightPercentToPixels(tItemHeight, 0.65) into rDataLayout[4]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[4]["bottom"]
  put "text" into rDataLayout[4]["content-type"]
  put "rounded-rectangle" into rDataLayout[4]["fill-type"]
  put "29,99,32,255" into rDataLayout[4]["fill-color"]
  put "5" into rDataLayout[4]["fill-cornerRadius"]
  put round(0.1 * tItemHeight) into rDataLayout[4]["text-size"]
  put "center" into rDataLayout[4]["align"]
  put "255,255,255,255" into rDataLayout[4]["color"]
  put true into rDataLayout[4]["dropShadow"]
  put true into rDataLayout[4]["fill"]

  put "username" into rDataLayout[5]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[5]["top"]
  put itemHeightPercentToPixels(tItemHeight, 1) into rDataLayout[5]["left"]
  put round(0.3 * tItemHeight) into rDataLayout[5]["text-size"]
  put "255,255,255,200" into rDataLayout[5]["color"]
  put "50" into rDataLayout[5]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[5]["height"]

  put "rank" into rDataLayout[6]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.7) into rDataLayout[6]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.7) into rDataLayout[6]["height"]
  put "10px" into rDataLayout[6]["right"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[6]["top"]
  put "image-data" into rDataLayout[6]["content-type"]
  put "scale-down" into rDataLayout[6]["content-fit"]
  put true into rDataLayout[6]["dropShadow"]

  put "rr" into rDataLayout[7]["name"]
  put "0px" into rDataLayout[7]["bottom"]
  put "center" into rDataLayout[7]["align"]
  put "10px" into rDataLayout[7]["right"]
  put round(0.18 * tItemHeight) into rDataLayout[7]["text-size"]
  put "255,255,255,200" into rDataLayout[7]["color"]
  put itemHeightPercentToPixels(tItemHeight, 0.7) into rDataLayout[7]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[7]["height"]

  put "peakText" into rDataLayout[8]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[8]["height"]
  put itemHeightPercentToPixels(tItemHeight, 0.4) into rDataLayout[8]["width"]
  put round(0.18 * tItemHeight) into rDataLayout[8]["text-size"]
  put "right" into rDataLayout[8]["align"]
  put itemHeightPercentToPixels(tItemHeight, 1) into rDataLayout[8]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.15) into rDataLayout[8]["bottom"]
  put "255,255,255,200" into rDataLayout[8]["color"]

  put "peak" into rDataLayout[9]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.35) into rDataLayout[9]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.35) into rDataLayout[9]["height"]
  put itemHeightPercentToPixels(tItemHeight, 1.5) into rDataLayout[9]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.25) into rDataLayout[9]["bottom"]
  put "image-data" into rDataLayout[9]["content-type"]
  put "scale-down" into rDataLayout[9]["content-fit"]
  put true into rDataLayout[9]["dropShadow"]

  put "peakAct" into rDataLayout[10]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[10]["height"]
  put itemHeightPercentToPixels(tItemHeight, 0.35) into rDataLayout[10]["width"]
  put round(0.14 * tItemHeight) into rDataLayout[10]["text-size"]
  put "center" into rDataLayout[10]["align"]
  put itemHeightPercentToPixels(tItemHeight, 1.5) into rDataLayout[10]["left"]
  put "0px" into rDataLayout[10]["bottom"]
  put "255,255,255,200" into rDataLayout[10]["color"]

  return rDataLayout
end getPolylistDataLayout

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

function getPolylistData pParty
  local tData
  put empty into tData
  repeat for each element tTeammate in pParty
    local tPlayerData
    put empty into tPlayerData
    
    /* Party */
    put "assets/agentborders/parties/noparty_blue.png" into tPlayerData["party"]
    
    /* Team */
    put "assets/agentborders/teams/blue.png" into tPlayerData["team"]

    /* Level */
    if tTeammate["level"] is empty then
      put "--" into tPlayerData["level"]
    else
      put tTeammate["level"] into tPlayerData["level"]
    end if
    
    /* Name */
    put tTeammate["name"] into tPlayerData["username"]
    
    /* Rank Icon */
    put tTeammate["rankIcon"] into tPlayerData["rank"]
    put tTeammate["rank"] into tPlayerData["rank_hovertext"]
    
    /* RR */
    if tTeammate["rr"] is empty or tTeammate["rank"] is "Unranked" then
      put empty into tPlayerData["rr"]
    else
      put tTeammate["rr"] & "rr" into tPlayerData["rr"]
    end if

    /* Peak Text */
    if tTeammate["peakEpisode"] is empty or tTeammate["peakAct"] is empty then
      put empty into tPlayerData["peakText"]
      appendArray tData, tPlayerData
      next repeat
    end if
    put "Peak" into tPlayerData["peakText"]

    /* Peak Icon */
    put tTeammate["peakIcon"] into tPlayerData["peak"]
    put tTeammate["peak"] into tPlayerData["peak_hovertext"]

    /* Peak Act/Episode */
    put "e" & tTeammate["peakEpisode"] & "a" & tTeammate["peakAct"] into tPlayerData["peakAct"]

    appendArray tData, tPlayerData
  end repeat

  return tData
end getPolylistData

on mainLoop
  local tPresences, tPrivatePresence, tGameState
  
  put kGameState into tGameState
  repeat while tGameState is kGameState
    if checkSetup() is false then
      goToPreLoad
      exit mainLoop
    end if

    local tDidFail
    put getPresences() into tPresences
    put getPrivatePresence(tPresences) into tPrivatePresence
    put getPartyMemberData(tPresences, tDidFail) into sParty

    local tGamemode
    put presenceToQueueType(tPrivatePresence) into tGamemode

    set the text of field "stateField" to "Menu" & space & slash & slash & space & capitalizeWords(tGamemode)

    setupPolylist

    if not isRunning() then
       exit mainLoop
    end if

    /* Update UI */
    layoutControls

    if not waitForSeconds(2, tGameState) then
      exit mainLoop
    end if

    put getGameState() into tGameState
  end repeat

  if isRunning() then
    redirect
  end if
end mainLoop
