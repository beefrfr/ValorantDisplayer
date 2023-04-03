script "valorantBehavior"

/* Valorant vars */
global sPdUrl, sGlzUrl
global sRegion
global sCurrentSeason
global sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol
global sHeaders, sPUUID
global sCurrentVersion
global sSetup
global sWeapons, sWeaponList
global sAgents, sMaps
global sSettings

/* Stack script */

global tRunning

on log pMessage
  /* Log to file */
  local tLog
  put empty into tLog
end log

on openStack
  put empty into sWeapons
  put empty into sWeaponList
  put empty into sAgents
  send "goToPreLoad" to me in 5 milliseconds

  /* Load Settings */
  local tValorantDisplayerFolder
  put specialfolderpath("Documents") & slash & "ValorantDisplayer" into tValorantDisplayerFolder
  if there is not a folder tValorantDisplayerFolder then
    create folder tValorantDisplayerFolder
  end if

  local tSettingsFile
  put (tValorantDisplayerFolder & slash & "settings.json") into tSettingsFile
  if there is not a file tSettingsFile then
    put empty into sSettings
    put "255,215,180,255" into sSettings["partyColors"][1]
    put "60,180,75,255" into sSettings["partyColors"][2]
    put "145,30,80,255" into sSettings["partyColors"][3]
    put "240,50,30,255" into sSettings["partyColors"][4]
    put "245,130,38,255" into sSettings["partyColors"][5]
    put "128,0,0,255" into sSettings["partyColors"][6]
    put "210,245,60,255" into sSettings["partyColors"][7]

    put "agent,name,Vandal,Phantom,rank,peak,winrate,level" into sSettings["visibleSections"]

    put "0,0,255,128" into sSettings["blueColor"]
    put "255,0,0,128" into sSettings["redColor"]
    put "128,128,0,128" into sSettings["myColor"]

    put false into sSettings["alwaysShowName"]
    put false into sSettings["alwaysShowRank"]
    put false into sSettings["alwaysShowLevel"]
    put false into sSettings["alwaysShowWinrate"]
    put true into sSettings["showParties"]

    put jsonExport(sSettings) into URL("file:" & tSettingsFile)
  else
    local tSettingsContents
    put URL("file:" & tSettingsFile) into tSettingsContents
    put JsonImport(tSettingsContents) into sSettings

    local tSettingsChanged
    put false into tSettingsChanged
    if "visibleSections" is not among the keys of sSettings or sSettings["visibleSections"] is empty then
      put "agent,name,Vandal,Phantom,rank,peak,wr,level" into sSettings["visibleSections"]
      put true into tSettingsChanged
    end if

    if "blueColor" is not among the keys of sSettings or sSettings["blueColor"] is empty then
      put "0,0,255,128" into sSettings["blueColor"]
      put true into tSettingsChanged
    end if

    if "redColor" is not among the keys of sSettings or sSettings["redColor"] is empty then
      put "255,0,0,128" into sSettings["redColor"]
      put true into tSettingsChanged
    end if

    if "myColor" is not among the keys of sSettings or sSettings["myColor"] is empty then
      put "128,128,0,128" into sSettings["myColor"]
      put true into tSettingsChanged
    end if

    if "showParties" is not among the keys of sSettings or sSettings["showParties"] is empty then
      put true into sSettings["showParties"]
      put true into tSettingsChanged
    end if

    /* Check always show */
    repeat for each item tAlways in "alwaysShowName,alwaysShowRank,alwaysShowLevel,alwaysShowWinrate"
      if tAlways is not among the keys of sSettings or sSettings[tAlways] is empty then
        put false into sSettings[tAlways]
        put true into tSettingsChanged
      end if
    end repeat

    if tSettingsChanged then
      put jsonExport(sSettings) into URL("file:" & tSettingsFile)
    end if
  end if
end openStack

on saveSettings
  local tSettingsFile
  put (tValorantDisplayerFolder & slash & "settings.json") into tSettingsFile
  put jsonExport(sSettings) into URL("file:" & tSettingsFile)
end saveSettings

on closeStack
  put false into tRunning
  close this stack
end closeStack

on goToPreLoad
  go to card "preLoad"
  send "main" to card "preLoad" in 5 milliseconds
end gotoPreLoad

on goToMenu
  go to card "menu"
  send "menuSetup" to card "menu" in 5 milliseconds
end goToMenu

on goToInGame
  go to card "inGame"
  send "inGameSetup" to card "inGame" in 5 milliseconds
end goToInGame

on goToPreGame
  go to card "preGame"
  send "preGameSetup" to card "preGame" in 5 milliseconds
end goToPreGame

/* Valorant Information */
on valorantSetup pForce
  if sSetup is false then
    put true into pForce
  end if
  put true into sSetup
  if getLockFile() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getHeaders() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if pForce is false then
    exit valorantSetup
  end if

  if getCurrentVersion() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getRegion() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getCurrentSeason() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getWeapons() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getAgents() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getMaps() is false then
    put false into sSetup
    exit valorantSetup
  end if
end valorantSetup

function getRegion
  local tPath
  put specialfolderpath("Support") into tPath
  set the itemdelimiter to slash
  delete the last item of tPath
  put "/local/VALORANT/Saved/Logs/ShooterGame.log" after tPath

  put empty into sPdUrl
  put empty into sGlzUrl

  if there is not a file tPath then
    return false
  end if

  put url("file:" & tPath) into tFileContents
  repeat for each line tLine in tFileContents
    if matchtext(tLine, "(https://glz-[^.]*.[^.]*.a.pvp.net)", sGlzUrl) then
      put slash after sGlzUrl
    else if matchtext(tLine, "(https://pd.[^.]*.a.pvp.net)", sPdUrl) then
      put slash after sPdUrl
      if matchtext(tLine, "https://pd.([^.]*).a.pvp.net", sRegion) then
      end if
    end if

    if sPdUrl is not empty and sGlzUrl is not empty then
      if sPdUrl is "pbe" then
        put "https://pd.na.a.pvp.net/" into sPdUrl
        put "https://glz-na-1.na.a.pvp.net/" into sGlzUrl
      end if
      return true
    end if
  end repeat
  return false
end getRegion

function getLockFile
  put empty into sLockName
  put empty into sLockPID
  put empty into sLockPort
  put empty into sLockPassword
  put empty into sLockProtocol

  local tPath
  put specialfolderpath("Support") into tPath
  set the itemdelimiter to slash
  delete the last item of tPath
  put "/local/Riot Games/Riot Client/Config/lockfile" after tPath

  if there is not a file tPath then
    return false
  end if

  put url("file:" & tPath) into tFileContents

  return matchtext(tFileContents, "([^.]*):([^.]*):([^.]*):([^.]*):([^.]*)", sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol)
end getLockFile

function getHeaders
  put empty into sHeaders

  local tEntitlements, tAuthPass, tEncodedAuthPass, tAuthHeader, tUrl
  put "riot:" & sLockPassword into tAuthPass
  put base64Encode(tAuthPass) into tEncodedAuthPass
  put "Authorization: Basic " & tEncodedAuthPass into tAuthHeader
  
  put "https://127.0.0.1:" & sLockPort & "/entitlements/v1/token" into tUrl
  
  put empty into response
  put empty into tEntitlements
  
  try
    tsNetVerifySSLPeer false
    set the httpHeaders to tAuthHeader
    get URL tUrl
    try
      put JsonImport(it) into tEntitlements
    catch tError
      return false
    end try
  catch e
    exit getHeaders
  end try
  
  put tEntitlements["subject"] into sPUUID
  
  put "User-Agent: " & "ShooterGame/13 Windows/10.0.19043.1.256.64bit" & return after sHeaders
  put "Authorization: Bearer " & tEntitlements["accessToken"] & return after sHeaders
  put "X-Riot-Entitlements-JWT: " & tEntitlements["token"] & return after sHeaders
  put "X-Riot-ClientVersion: " & sCurrentVersion & return after sHeaders
  put "X-Riot-ClientPlatform: " & "ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjog" & \
  "IldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5" & \
  "MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVua25vd24iDQp9" after sHeaders
  return true
end getHeaders

function getCurrentVersion
  local tPath
  put specialfolderpath("Support") into tPath
  set the itemdelimiter to slash
  delete the last item of tPath
  put "/local/VALORANT\Saved\Logs\ShooterGame.log" after tPath

  if there is not a file tPath then
    return false
  end if

  put url("file:" & tPath) into tFileContents
  local tRawVersion, tRawVersionRight
  if matchtext(tFileContents, "CI server version:\s?([^-]*\-[^-]*\-)(.*)", tRawVersionLeft, tRawVersionRight) then
    put tRawVersionLeft & "shipping-" & tRawVersionRight into sCurrentVersion
  end if

  return tRawVersionLeft is not empty and tRawVersionRight is not empty
end getCurrentVersion 

function getCurrentSeason
  local tContent
  put fetchData("custom", "https://shared." & sRegion & ".a.pvp.net/content-service/v3/content", "GET") into tContent
  if tContent is false then
    return false
  end if
  repeat for each element tSeason in tContent["Seasons"]
    if tSeason["IsActive"] is true then
      put tSeason["ID"] into sCurrentSeason
      return true
      exit getCurrentSeason
    end if
  end repeat
  return false
end getCurrentSeason

function getWeapons
  if sWeapons is not empty then
    return true
  end if
  put empty into sWeaponList
  local tRawWeapons
  put fetchData("custom", "https://valorant-api.com/v1/weapons", "get") into tRawWeapons
  if tRawWeapons is false then
    return false
  end if
  repeat for each element tWeapon in tRawWeapons["data"]
    local tWeaponName
    put tWeapon["DisplayName"] into tWeaponName
    put tWeaponName & comma after sWeaponList
    repeat for each element tSkin in tWeapon["skins"]
      local tSkinName, tSkinUUID
      put tSkin["DisplayName"] into tSkinName
      put tSkin["uuid"] into tSkinUUID
      put tWeaponName into sWeapons[tSkinUUID]["Weapon"]
      put tSkinName into sWeapons[tSkinUUID]["Skin"]
      put tSkinUUID into sWeapons[tSkinUUID]["uuid"]
    end repeat
  end repeat
  if the last character of sWeaponList is comma then delete the last character of sWeaponList
  return true
end getWeapons

function getWeaponList
  return sWeaponList
end getWeaponList

function getAgents
  if sAgents is not empty then
    return true
  end if
  local tRawAgents
  put fetchData("custom", "https://valorant-api.com/v1/agents", "get") into tRawAgents
  if tRawAgents is false then
    return false
  end if
  repeat for each element tAgent in tRawAgents["data"]
    put tAgent["displayName"] into sAgents[tAgent["uuid"]]
  end repeat
  return true
end getAgents

function getMaps
  if sMaps is not empty then
    return true
  end if
  local tRawMaps
  put fetchData("custom", "https://valorant-api.com/v1/maps", "get") into tRawMaps
  if tRawMaps is false then
    return false
  end if
  repeat for each element tMap in tRawMaps["data"]
    put tMap["displayName"] into sMaps[tMap["mapUrl"]]
  end repeat
  return true
end getMaps

function fetchData pUrlType, pUrl, pMethod, rSuccess
  if pMethod is empty then put "GET" into pMethod

  set the httpHeaders to sHeaders

  local tUrl
  switch pUrlType
  case "glz"
    if pUrl begins with slash then delete the first character of pUrl
    put (sGlzUrl & pUrl) into tUrl
    break
  case "pd"
    if pUrl begins with slash then delete the first character of pUrl
    put (sPdUrl & pUrl) into tUrl
    break
  case "local"
    if pUrl begins with slash then delete the first character of pUrl
    local tAuthPass, tEncodedAuthPass, tAuthHeader
    put "riot:" & sLockPassword into tAuthPass
    put base64Encode(tAuthPass) into tEncodedAuthPass
    put "Authorization: Basic " & tEncodedAuthPass into tAuthHeader
    set the httpHeaders to tAuthHeader
    
    put "https://127.0.0.1:" & sLockPort & "/" & pUrl into tUrl
    break
  case "custom"
    put pUrl into tUrl
    break
  default
    exit fetchData
  end switch

  local tResponse
  if pMethod is "GET" then
    tsNetVerifySSLPeer false
    get URL tUrl
    try
      put JsonImport(it) into tResponse
      return tResponse
    catch tError
      return false
    end try
  else if pMethod is "POST" then
    tsNetVerifySSLPeer false
    post empty to URL tUrl
    try
      put JsonImport(it) into tResponse
      return tResponse
    catch tError
      return false
    end try
  end if
  return false
end fetchData

function getPresences
  local tPresences
  put fetchData("local", "chat/v4/presences", "GET") into tPresences
  return tPresences["presences"]
end getPresences

function getPrivatePresence pPresences, pUUID
  if pUUID is empty then put sPUUID into pUUID
  repeat for each element tPresence in pPresences
    if tPresence["puuid"] is pUUID then
      return JsonImport(base64Decode(tPresence["private"]))
    end if
  end repeat
  return empty
end getPrivatePresence

on appendArray @xArray, pElement
  put pElement into xArray[the number of elements in xArray + 1]
end appendArray

function getPartyMembers pPresences
  local rParty, tPartyID, tCurrentPrivatePresence, tCurrentPlayer

  put getPrivatePresence(pPresences) into tCurrentPrivatePresence
  put tCurrentPrivatePresence["partyId"] into tPartyID
  put sPUUID into tCurrentPlayer["uuid"]
  put tCurrentPrivatePresence["accountLevel"] into tCurrentPlayer["level"]

  appendArray rParty, tCurrentPlayer
  put empty into tCurrentPlayer

  repeat for each element tPresence in pPresences
    if tPresence["product"] is not "valorant" then next repeat
    
    put JsonImport(base64Decode(tPresence["private"])) into tCurrentPrivatePresence
    if tCurrentPrivatePresence["partyId"] is tPartyID and tPresence["puuid"] is not sPUUID then
      put tPresence["puuid"] into tCurrentPlayer["uuid"]
      put tCurrentPrivatePresence["accountLevel"] into tCurrentPlayer["level"]

      appendArray rParty, tCurrentPlayer
      put empty into tCurrentPlayer
    end if
  end repeat
  return rParty
end getPartyMembers

function getPartyMemberData pPresences, @xDidFail
  local tPartyInfo
  put empty into tPartyInfo

  local tParty, tPartyUUIDs
  put empty into tPartyUUIDs
  put getPartyMembers(pPresences) into tParty
  repeat for each element tPartyMember in tParty
    put tPartyMember["uuid"] & comma after tPartyUUIDs
    put getPlayerStats(tPartyMember["uuid"], xDidFail) into tPartyInfo[tPartyMember["uuid"]]
  end repeat
  if the last character of tPartyUUIDs is comma then delete the last character of tPartyUUIDs

  local tNames
  put getNames(tPartyUUIDs) into tNames
  if tNames is empty then
    next repeat
  end if

  repeat for each element tPartyMember in tParty
    put tPartyMember["level"] into tPartyInfo[tPartyMember["uuid"]]["level"]
    put tNames[tPartyMember["uuid"]] into tPartyInfo[tPartyMember["uuid"]]["name"]
  end repeat
  return tPartyInfo
end getPartyMemberData

function getPlayerStats pUUID, @xDidFail
  local tPlayerHistory, tPlayerStats
  put fetchData("pd", ("mmr/v1/players/" & pUUID), "GET") into tPlayerHistory

  put pUUID into tPlayerStats["uuid"]
  if the number of elements of tPlayerHistory is 0 or tPlayerHistory is false then
    put 0 into tPlayerStats["rank"]
    put 0 into tPlayerStats["rr"]
    put 0 into tPlayerStats["wr"]
    put 0 into tPlayerStats["peak"]
    put true into xDidFail
    return tPlayerStats
  end if
  if sCurrentSeason is not among the keys of tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"] then
    put "Unranked" into tPlayerStats["rank"]
    put "N/A" into tPlayerStats["rr"]
    put "-1" into tPlayerStats["wr"]
  else
    put rankNumberToRank(tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["CompetitiveTier"]) into tPlayerStats["rank"]
    put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["RankedRating"] into tPlayerStats["rr"]

    local tWR
    if tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfGames"] is 0 then
      put "-1" into tWR
    else
      put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfWinsWithPlacements"] / tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfGames"] into tWR
    end if
    put tWR into tPlayerStats["wr"]
  end if

  local tCurrentMaxRank
  put 0 into tCurrentMaxRank
  repeat for each key tKey in tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"]
    if the number of elements of tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey] is 0 then
      next repeat
    end if
    if tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey]["Rank"] > tCurrentMaxRank then
      put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey]["Rank"] into tCurrentMaxRank
    end if
  end repeat
  put rankNumberToRank(tCurrentMaxRank) into tPlayerStats["peak"]
  return tPlayerStats
end getPlayerStats

function getNames pUUIDs
  if not getHeaders() then
    exit getNames
  end if

  /* Build JSON list */
  local tJSON
  put "[" into tJson
  repeat for each item tPUUID in pUUIDs
    put quote & tPUUID & quote & comma after tJson
  end repeat
  if the last character of tJson is comma then delete the last character of tJson
  put "]" after tJson

  /* Build Headers */
  local tHeaders
  put sHeaders & return into tHeaders
  put "Content-Type: application/json" & return after tHeaders
  //put "Content-Length: " & length(tJson) & return after tHeaders
  put "PUT name-service/v2/players HTTP/1.1" & return before tHeaders
  put return & tJSON after tHeaders
  set the httpHeaders to tHeaders

  /* Send PUT request */
  local rHeaders, rResult, rBytes, tResultJSON
  tsNetVerifySSLPeer false
  put tsNetCustomUploadSync((sPdUrl & "name-service/v2/players"), "PUT", tHeaders, tJSON, rHeaders, rResult, rBytes) into tResultJSON
  if rResult is not "200" then
    exit getNames
  end if
  local tResult
  put JsonImport(tResultJSON) into tResult

  local rNames
  /* Handle response */
  repeat for each element tUser in tResult
    put tUser["GameName"] & "#" & tUser["TagLine"] into rNames[tUser["Subject"]]
  end repeat
  return rNames
end getNames

function getMatchID pAttempt
  local tResult
  put fetchData("glz", "/core-game/v1/players/" & sPUUID, "get") into tResult

  if tResult is not false and tResult["errorCode"] is not "RESOURCE_NOT_FOUND" then
    if tResult["errorCode"] is "BAD_CLAIMS" then
      valorantSetup
      return getMatchID(pAttempt + 1)
    end if
    return tResult["MatchID"]
  else if pAttempt < 5 then
    repeat for 50 times
      wait 1 milliseconds with messages
    end repeat
    return getMatchID(pAttempt + 1)
  end if
  return false
end getMatchID

function getPreGameID pAttempt
  local tResult
  put fetchData("glz", "/pregame/v1/players/" & sPUUID, "get") into tResult

  if tResult is not false and tResult["errorCode"] is not "RESOURCE_NOT_FOUND" then
    if tResult["errorCode"] is "BAD_CLAIMS" then
      valorantSetup
      return getMatchID(pAttempt + 1)
    end if
    return tResult["MatchID"]
  else if pAttempt < 5 then
    repeat for 50 times
      wait 1 milliseconds with messages
    end repeat
    return getMatchID(pAttempt + 1)
  end if
  return false
end getPreGameID

function getMatchStats pMatchID, pAttempt
  local tResult
  put fetchData("glz", "/core-game/v1/matches/" & pMatchID, "get") into tResult

  if tResult is not false and tResult["errorCode"] is not "RESOURCE_NOT_FOUND" then
    if tResult["errorCode"] is "BAD_CLAIMS" then
      valorantSetup
      return getMatchStats(pMatchID, pAttempt + 1)
    end if
    return tResult
  else if pAttempt < 5 then
    repeat for 50 times
      wait 1 milliseconds with messages
    end repeat
    return getMatchStats(pMatchID, pAttempt + 1)
  end if
  return false
end getMatchStats

function getPreGameStats pMatchID, pAttempt
  local tResult
  put fetchData("glz", "/pregame/v1/matches/" & pMatchID, "get") into tResult

  if tResult is not false and tResult["errorCode"] is not "RESOURCE_NOT_FOUND" then
    if tResult["errorCode"] is "BAD_CLAIMS" then
      valorantSetup
      return getPreGameStats(pMatchID, pAttempt + 1)
    end if
    return tResult
  else if pAttempt < 5 then
    repeat for 50 times
      wait 1 milliseconds with messages
    end repeat
    return getPreGameStats(pMatchID, pAttempt + 1)
  end if
  return false
end getPreGameStats

function agentIDtoName pAgentID
  if pAgentID is among the keys of sAgents then
    return sAgents[pAgentID]
  end if
  return "Unknown"
end agentIDtoName

function getInGameTeams pMatchID, pPresences, @xDidFail
  local tLoadouts
  put fetchData("glz", "/core-game/v1/matches/" & pMatchID & "/loadouts", "get") into tLoadouts

  local tMatchStats
  put getMatchStats(pMatchID) into tMatchStats
  if tMatchStats is false then
    goToPreLoad
  end if

  local tTeams, tUUIDs
  put empty into tTeams["blue"]
  put empty into tTeams["red"]
  put empty into tTeams["myTeam"]
  put empty into tTeams["otherTeam"]
  put empty into tTeams["myParty"]
  put sMaps[tMatchStats["mapid"]] into tTeams["map"]
  put empty into tUUIDs

  repeat for each key tKey in tMatchStats["Players"]
    local tPlayer, tRawPlayer
    put tMatchStats["Players"][tKey] into tRawPlayer

    put agentIDtoName(tRawPlayer["CharacterID"]) into tPlayer["agent"]
    put tRawPlayer["PlayerIdentity"]["Incognito"] into tPlayer["hiddenName"]
    put tRawPlayer["PlayerIdentity"]["HideAccountLevel"] into tPlayer["hiddenLevel"]
    put getPlayerStats(tRawPlayer["Subject"], xDidFail) into tPlayer["Stats"]
    put tRawPlayer["Subject"] into tPlayer["UUID"]
    put tRawPlayer["Subject"] & comma after tUUIDs

    if tLoadouts is false then
      put true into xDidFail
    else
      local tLoadout
      if tLoadouts["Loadouts"][tKey]["CharacterID"] is tRawPlayer["CharacterID"] then
        put tLoadouts["Loadouts"][tKey]["Loadout"]["items"] into tLoadout
        repeat for each element tItem in tLoadout
          local tWeapon
          put sWeapons[tItem["Sockets"]["bcef87d6-209b-46c6-8b19-fbe40bd95abc"]["Item"]["ID"]] into tWeapon
          put tWeapon into tPlayer["Loadout"][tWeapon["Weapon"]]
        end repeat
      end if
    end if

    local tPrivatePresence, tPartyID
    put getPrivatePresence(pPresences, tRawPlayer["Subject"]) into tPrivatePresence
    put tPrivatePresence["partyID"] into tPartyID
    put tPrivatePresence["accountLevel"] into tPlayer["level"]

    if tRawPlayer["Subject"] is sPUUID then
      put tPartyID into tTeams["myParty"]
    end if

    if tRawPlayer["TeamID"] is "blue" then
      put tPlayer into tTeams["blue"][tPartyID][tRawPlayer["Subject"]]
      if tRawPlayer["Subject"] is sPUUID then
        put "blue" into tTeams["myTeam"]
        put "red" into tTeams["otherTeam"]
      end if
    else
      put tPlayer into tTeams["red"][tPartyID][tRawPlayer["Subject"]]
      if tRawPlayer["Subject"] is sPUUID then
        put "red" into tTeams["myTeam"]
        put "blue" into tTeams["otherTeam"]
      end if
    end if
  end repeat
  if the last character of tUUIDs is comma then delete the last character of tUUIDs

  /* Convert UUID to names for each teammate */
  local tNames
  put getNames(tUUIDs) into tNames
  if tNames is not empty then
    repeat for each key tPartyID in tTeams["blue"]
      repeat for each key tUUID in tTeams["blue"][tPartyID]
        if tUUID is among the keys of tNames then
          put tNames[tUUID] into tTeams["blue"][tPartyID][tUUID]["Name"]
        end if
      end repeat
    end repeat
    repeat for each key tPartyID in tTeams["red"]
      repeat for each key tUUID in tTeams["red"][tPartyID]
        if tUUID is among the keys of tNames then
          put tNames[tUUID] into tTeams["red"][tPartyID][tUUID]["Name"]
        end if
      end repeat
    end repeat
  end if
  return tTeams
end getInGameTeams

function getPreGameTeam pMatchID, pPresences, @xDidFail
  local tMatchStats
  put getPreGameStats(pMatchID) into tMatchStats
  if tMatchStats is false then
    goToPreLoad
  end if

  local tTeams, tUUIDs
  put empty into tTeams["blue"]
  put tMatchStats["team1"] into tTeams["myTeam"]
  put empty into tTeams["myParty"]
  put sMaps[tMatchStats["mapid"]] into tTeams["map"]
  put empty into tUUIDs
  repeat for each key tKey in tMatchStats["Teams"][1]["players"]
    local tPlayer, tRawPlayer
    put tMatchStats["Teams"][1]["players"][tKey] into tRawPlayer

    put agentIDtoName(tRawPlayer["CharacterID"]) into tPlayer["agent"]
    put false into tPlayer["agentSelected"]
    if tRawPlayer["CharacterSelectionState"] is "locked" then
      put true into tPlayer["agentSelected"]
    end if
    put tRawPlayer["PlayerIdentity"]["Incognito"] into tPlayer["hiddenName"]
    put tRawPlayer["PlayerIdentity"]["HideAccountLevel"] into tPlayer["hiddenLevel"]
    put getPlayerStats(tRawPlayer["Subject"], xDidFail) into tPlayer["Stats"]
    put tRawPlayer["Subject"] into tPlayer["UUID"]
    put tRawPlayer["Subject"] & comma after tUUIDs

    local tPrivatePresence, tPartyID
    put getPrivatePresence(pPresences, tRawPlayer["Subject"]) into tPrivatePresence
    put tPrivatePresence["partyID"] into tPartyID
    put tPrivatePresence["accountLevel"] into tPlayer["level"]

    if tRawPlayer["Subject"] is sPUUID then
      put tPartyID into tTeams["myParty"]
    end if
    put tPlayer into tTeams[tTeams["myTeam"]][tPartyID][tRawPlayer["Subject"]]
  end repeat
  if the last character of tUUIDs is comma then delete the last character of tUUIDs

  /* Convert UUID to names for each teammate */
  local tNames
  put getNames(tUUIDs) into tNames
  if tNames is not empty then
    repeat for each key tPartyID in tTeams[tTeams["myTeam"]]
      repeat for each key tUUID in tTeams[tTeams["myTeam"]][tPartyID]
        if tUUID is among the keys of tNames then
          put tNames[tUUID] into tTeams[tTeams["myTeam"]][tPartyID][tUUID]["Name"]
        end if
      end repeat
    end repeat
  end if
  return tTeams
end getPreGameTeam

function rankNumberToRank pRank
  switch pRank
  case 0
    return "Unranked"
  case 1
    return "Unranked"
  case 2
    return "Unranked"
  case 3
    return "Iron 1"
  case 4
    return "Iron 2"
  case 5
    return "Iron 3"
  case 6
    return "Bronze 1"
  case 7
    return "Bronze 2"
  case 8
    return "Bronze 3"
  case 9
    return "Silver 1"
  case 10
    return "Silver 2"
  case 11
    return "Silver 3"
  case 12
    return "Gold 1"
  case 13
    return "Gold 2"
  case 14
    return "Gold 3"
  case 15
    return "Platinum 1"
  case 16
    return "Platinum 2"
  case 17
    return "Platinum 3"
  case 18
    return "Diamond 1"
  case 19
    return "Diamond 2"
  case 20
    return "Diamond 3"
  case 21
    return "Ascendant 1"
  case 22
    return "Ascendant 2"
  case 23
    return "Ascendant 3"
  case 24
    return "Immortal 1"
  case 25
    return "Immortal 2"
  case 26
    return "Immortal 3"
  case 27
    return "Radiant"
  end switch
end rankNumberToRank

