script "pregameBehavior"

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

local sTeams
local sMatchID

/* UI vars */

constant kCurrentCard = "preGame"
constant kGameState = "PREGAME"

on preGameSetup
  clearControls
  createControls
  preGameSetupRecursive
end preGameSetup

on preGameSetupRecursive
  if sSetup then
    local tPresences, tPrivatePresence, tGameState
    put kCurrentCard into tGameState

    put getPresences() into tPresences
    put getPrivatePresence(tPresences) into tPrivatePresence
    put tPrivatePresence["sessionLoopState"] into tGameState

    local tMatchStats
    put getPreGameID(0) into sMatchID
    if sMatchID is false or tGameState is not kGameState then
      redirect
      exit preGameSetupRecursive
    end if

    mainLoop
  else
    redirect
  end if
end preGameSetupRecursive

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

  set the backgroundcolor of me to getBackgroundColor()

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
  set the dataContent of widget "playersPolylist" to getPolylistData(sTeams)
  set the dataLayout of widget "playersPolylist" to getPolylistDataLayout()
  layoutControls
end setupPolylist

function itemHeightPercentToPixels pItemHeight, pPercent
  return round(pPercent * pItemHeight) & "px"
end itemHeightPercentToPixels

function getPolylistDataLayout
  local rDataLayout, tItemHeight
  put the itemHeight of widget "playersPolylist" into tItemHeight

  local tCurrentIndex
  put 1 into tCurrentIndex

  put "agent" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.6) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.6) into rDataLayout[tCurrentIndex]["height"]
  put (round(tItemHeight * 0.1) + 10) & "px" into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.2) into rDataLayout[tCurrentIndex]["top"]
  put "image-data" into rDataLayout[tCurrentIndex]["content-type"]
  put "scale-down" into rDataLayout[tCurrentIndex]["content-fit"]
  add 1 to tCurrentIndex

  put "agentSelected" into rDataLayout[tCurrentIndex]["name"]
  put "color" into rDataLayout[tCurrentIndex]["content-type"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[tCurrentIndex]["height"]
  put "10px" into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[tCurrentIndex]["top"]
  add 1 to tCurrentIndex

  put "party" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[tCurrentIndex]["height"]
  put "10px" into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[tCurrentIndex]["top"]
  put "image-file" into rDataLayout[tCurrentIndex]["content-type"]
  put "scale-down" into rDataLayout[tCurrentIndex]["content-fit"]
  put true into rDataLayout[tCurrentIndex]["dropShadow"]
  add 1 to tCurrentIndex

  put "team" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.8) into rDataLayout[tCurrentIndex]["height"]
  put "10px" into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[tCurrentIndex]["top"]
  put "image-file" into rDataLayout[tCurrentIndex]["content-type"]
  put "scale-down" into rDataLayout[tCurrentIndex]["content-fit"]
  put true into rDataLayout[tCurrentIndex]["dropShadow"]
  add 1 to tCurrentIndex

  put "level" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.25) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.15) into rDataLayout[tCurrentIndex]["height"]
  put itemHeightPercentToPixels(tItemHeight, 0.65) into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[tCurrentIndex]["bottom"]
  put "text" into rDataLayout[tCurrentIndex]["content-type"]
  put "rounded-rectangle" into rDataLayout[tCurrentIndex]["fill-type"]
  put "29,99,32,255" into rDataLayout[tCurrentIndex]["fill-color"]
  put "5" into rDataLayout[tCurrentIndex]["fill-cornerRadius"]
  put round(0.1 * tItemHeight) into rDataLayout[tCurrentIndex]["text-size"]
  put "center" into rDataLayout[tCurrentIndex]["align"]
  put "255,255,255,255" into rDataLayout[tCurrentIndex]["color"]
  put true into rDataLayout[tCurrentIndex]["dropShadow"]
  put true into rDataLayout[tCurrentIndex]["fill"]
  add 1 to tCurrentIndex

  put "username" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[tCurrentIndex]["top"]
  put itemHeightPercentToPixels(tItemHeight, 1) into rDataLayout[tCurrentIndex]["left"]
  put round(0.3 * tItemHeight) into rDataLayout[tCurrentIndex]["text-size"]
  put "255,255,255,200" into rDataLayout[tCurrentIndex]["color"]
  put "50" into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[tCurrentIndex]["height"]
  add 1 to tCurrentIndex

  put "rank" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.7) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.7) into rDataLayout[tCurrentIndex]["height"]
  put "10px" into rDataLayout[tCurrentIndex]["right"]
  put itemHeightPercentToPixels(tItemHeight, 0.1) into rDataLayout[tCurrentIndex]["top"]
  put "image-data" into rDataLayout[tCurrentIndex]["content-type"]
  put "scale-down" into rDataLayout[tCurrentIndex]["content-fit"]
  put true into rDataLayout[tCurrentIndex]["dropShadow"]
  add 1 to tCurrentIndex

  put "rr" into rDataLayout[tCurrentIndex]["name"]
  put "0px" into rDataLayout[tCurrentIndex]["bottom"]
  put "center" into rDataLayout[tCurrentIndex]["align"]
  put "10px" into rDataLayout[tCurrentIndex]["right"]
  put round(0.18 * tItemHeight) into rDataLayout[tCurrentIndex]["text-size"]
  put "255,255,255,200" into rDataLayout[tCurrentIndex]["color"]
  put itemHeightPercentToPixels(tItemHeight, 0.7) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[tCurrentIndex]["height"]
  add 1 to tCurrentIndex

  put "peakText" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[tCurrentIndex]["height"]
  put itemHeightPercentToPixels(tItemHeight, 0.4) into rDataLayout[tCurrentIndex]["width"]
  put round(0.18 * tItemHeight) into rDataLayout[tCurrentIndex]["text-size"]
  put "right" into rDataLayout[tCurrentIndex]["align"]
  put itemHeightPercentToPixels(tItemHeight, 1) into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.15) into rDataLayout[tCurrentIndex]["bottom"]
  put "255,255,255,200" into rDataLayout[tCurrentIndex]["color"]
  add 1 to tCurrentIndex

  put "peak" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.35) into rDataLayout[tCurrentIndex]["width"]
  put itemHeightPercentToPixels(tItemHeight, 0.35) into rDataLayout[tCurrentIndex]["height"]
  put itemHeightPercentToPixels(tItemHeight, 1.5) into rDataLayout[tCurrentIndex]["left"]
  put itemHeightPercentToPixels(tItemHeight, 0.25) into rDataLayout[tCurrentIndex]["bottom"]
  put "image-data" into rDataLayout[tCurrentIndex]["content-type"]
  put "scale-down" into rDataLayout[tCurrentIndex]["content-fit"]
  put true into rDataLayout[tCurrentIndex]["dropShadow"]
  add 1 to tCurrentIndex

  put "peakAct" into rDataLayout[tCurrentIndex]["name"]
  put itemHeightPercentToPixels(tItemHeight, 0.3) into rDataLayout[tCurrentIndex]["height"]
  put itemHeightPercentToPixels(tItemHeight, 0.35) into rDataLayout[tCurrentIndex]["width"]
  put round(0.14 * tItemHeight) into rDataLayout[tCurrentIndex]["text-size"]
  put "center" into rDataLayout[tCurrentIndex]["align"]
  put itemHeightPercentToPixels(tItemHeight, 1.5) into rDataLayout[tCurrentIndex]["left"]
  put "0px" into rDataLayout[tCurrentIndex]["bottom"]
  put "255,255,255,200" into rDataLayout[tCurrentIndex]["color"]
  add 1 to tCurrentIndex

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

function getPolylistData pTeams
  if pTeams["myTeam"] is empty then
    return empty
  end if

  local tData, tPartyCount, tParties
  put 1 into tPartyCount
  put empty into tData

  local tMyTeam
  put pTeams[pTeams["myTeam"]] into tMyTeam

  getTeamData tMyTeam, "blue", tData, tPartyCount, tParties
  
  return tData
end getPolylistData

on getTeamData pTeam, pTeamName, @xData, @xPartyCount, @xParties
  local tParty
  repeat for each key tPartyID in pTeam
    put pTeam[tPartyID] into tParty
    repeat for each element tTeammate in tParty
      local tPlayerData
      put empty into tPlayerData
      
      /* Agent Icon */
      if tTeammate["agentIcon"] is not empty then
        put tTeammate["agentIcon"] into tPlayerData["agent"]
      end if
      put tTeammate["agent"] into tPlayerData["agent_hovertext"]

      /* Agent Shading */
      put getBackgroundColor() & ", 0" into tPlayerData["agentSelected"]
      if tTeammate["agentSelected"] is false then
        put getBackgroundColor() & ", 120" into tPlayerData["agentSelected"]
      end if
      put tTeammate["agent"] into tPlayerData["agentSelected_hovertext"]
      
      /* Party */
      if the number of elements of tParty is 1 or sSettings["showParties"] is false then
        put "assets/agentborders/parties/noparty_" & pTeamName & ".png" into tPlayerData["party"]
      else
        if tPartyID is among the keys of xParties then
          put "assets/agentborders/parties/party" & xParties[tPartyID] & ".png" into tPlayerData["party"]
        else
          put "assets/agentborders/parties/party" & xPartyCount & ".png" into tPlayerData["party"]
          put xPartyCount into xParties[tPartyID]
          add 1 to xPartyCount
        end if
      end if
      put tTeammate["agent"] into tPlayerData["party_hovertext"]
      
      /* Team */
      put "assets/agentborders/teams/" & pTeamName & ".png" into tPlayerData["team"]
      put tTeammate["agent"] into tPlayerData["team_hovertext"]

      /* Level */
      if sSettings["alwaysShowLevel"] or tTeammate["hiddenLevel"] is false or tTeammate["uuid"] is sPUUID then
        put tTeammate["level"] into tPlayerData["level"]
      else
        put "--" into tPlayerData["level"]
      end if
      
      /* Name */
      if sSettings["alwaysShowName"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID then
        put tTeammate["name"] & "#" & tTeammate["tag"] into tPlayerData["username"]
        put tTeammate["name"] into tPlayerData["name"]
        put tTeammate["tag"] into tPlayerData["tag"]
      else
        put "--" into tPlayerData["username"]
      end if
      
      /* Rank Icon */
      if sSettings["alwaysShowRank"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID then
        put tTeammate["stats"]["rankIcon"] into tPlayerData["rank"]
        put tTeammate["stats"]["rank"] into tPlayerData["rank_hovertext"]
      else
        put empty into tPlayerData["rank"]
      end if
      
      /* RR */
      if sSettings["alwaysShowRank"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID then
        if tTeammate["stats"]["rr"] is empty or tTeammate["stats"]["rank"] is "Unranked" then
          put empty into tPlayerData["rr"]
        else
          put tTeammate["stats"]["rr"] & "rr" into tPlayerData["rr"]
        end if
      else
        put empty into tPlayerData["rr"]
      end if

      /* Peak Text */
      if tTeammate["stats"]["peakEpisode"] is empty or tTeammate["stats"]["peakAct"] is empty then
        put empty into tPlayerData["peakText"]
        appendArray xData, tPlayerData
        next repeat
      end if
      put "Peak" into tPlayerData["peakText"]

      /* Peak Icon */
      if sSettings["alwaysShowRank"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID then
        put tTeammate["stats"]["peakIcon"] into tPlayerData["peak"]
        put tTeammate["stats"]["peak"] into tPlayerData["peak_hovertext"]
      else
        put empty into tPlayerData["peak"]
      end if

      /* Peak Act/Episode */
      if sSettings["alwaysShowRank"] or tTeammate["hiddenName"] is false or tTeammate["uuid"] is sPUUID then
        put "e" & tTeammate["stats"]["peakEpisode"] & "a" & tTeammate["stats"]["peakAct"] into tPlayerData["peakAct"]
      else
        put empty into tPlayerData["peakAct"]
      end if

      appendArray xData, tPlayerData
    end repeat
  end repeat
end getTeamData

on mainLoop
  local tPresences, tPrivatePresence, tGameState

  put kGameState into tGameState
  repeat while tGameState is kGameState
    if refresh() is false then
      goToPreLoad
      exit mainLoop
    end if

    if not waitForSeconds(2, tGameState) then
      exit mainLoop
    end if

    if not isRunning() or sSettings["autoRefresh"] is false then
       exit mainLoop
    end if
  end repeat

  if isRunning() then
    redirect
  end if
end mainLoop

function refresh
  if checkSetup is false then
    return false
  end if

  if getGameState() is not kGameState then
    return false
  end if

  put getPresences() into tPresences
  put getPrivatePresence(tPresences) into tPrivatePresence
  put tPrivatePresence["sessionLoopState"] into tGameState

  local tDidFail
  put getPreGameTeam(sMatchID, tPresences, tDidFail) into sTeams

  local tGamemode
  put presenceToQueueType(tPrivatePresence) into tGamemode

  set the text of field "stateField" to capitalizeWords(tGamemode) & space & slash & slash & space & capitalizeWords(sTeams["map"])

  lock screen for visual effect
  setupPolylist

  /* Update UI */
  layoutControls
  unlock screen with visual effect "dissolve" very fast
  return true
end refresh
