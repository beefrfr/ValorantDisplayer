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
global sAgents, sMaps, sRanks
global sSettings
global sSeasons
global sActs
global sFetchDataCache
global sShouldCache

/* Stack script */

constant kDivisionList = "Unranked,Iron,Bronze,Silver,Gold,Plat,Diamond,Ascendant,Immortal,Radiant"
constant kCacheTimeoutMilliseconds = 10000

global sRunning
local sTsNetResults

on useCache
  put true into sShouldCache
end useCache

on ignoreCache
  put false into sShouldCache
end ignoreCache

on log pMessage
  /* Log to file */
  local tLog
  put empty into tLog
end log

on openStack
  put empty into sTsNetResults
  put true into sRunning
  set the destroyWindow of this stack to true
  put empty into sWeapons
  put empty into sWeaponList
  put empty into sAgents
  put empty into sFetchDataCache
  useCache
  send "goToPreLoad" to me in 5 milliseconds

  /* Load Settings */
  local tValorantDisplayerFolder
  put specialfolderpath("resources") into tValorantDisplayerFolder
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
  local tSettingsFile, tValorantDisplayerFolder
  put specialfolderpath("resources") into tValorantDisplayerFolder
  put (tValorantDisplayerFolder & slash & "settings.json") into tSettingsFile
  put jsonExport(sSettings) into URL("file:" & tSettingsFile)
end saveSettings

on closeStack
  put false into sRunning
  close this stack
end closeStack

function stopRunning
  put false into sRunning
end stopRunning

function isRunning
  return (sRunning and the mode of this stack is not 0)
end isRunning

on goToPreLoad
  if isRunning() then
    go to card "preLoad"
    send "main" to card "preLoad" in 5 milliseconds
  end if
end gotoPreLoad

on redirect
  if isRunning() then
    valorantSetup
    local tPresences, tPrivatePresence, tGameState
    put getPresences() into tPresences
    put getPrivatePresence(pPresences) into tPrivatePresence
    put tPrivatePresence["sessionLoopState"] into tGameState

    if not isRunning() then
      exit redirect
    end if

    switch tGameState
      case "MENUS"
        goToMenu
        break
      case "PREGAME"
        goToPreGame
        break
      case "INGAME"
            goToInGame
        break
    end switch
  end if
end redirect

on goToMenu
  if isRunning() then
    go to card "menu"
    send "menuSetup" to card "menu" in 5 milliseconds
  end if
end goToMenu

on goToInGame
  if isRunning() then
    go to card "inGame"
    send "inGameSetup" to card "inGame" in 5 milliseconds
  end if
end goToInGame

on goToPreGame
  if isRunning() then
    go to card "preGame"
    send "preGameSetup" to card "preGame" in 5 milliseconds
  end if
end goToPreGame

/* Valorant Information */
on valorantSetup pForce
  put empty into sTsNetResults
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
  if pForce is not true then
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
  if getSeasons() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getRanks() is false then
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

  if not waitForSeconds(0.5, getGameState()) then

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

  local tEntitlements
  ignoreCache
  put fetchData("local", "entitlements/v1/token", "GET") into tEntitlements
  useCache

  if tEntitlements is false then
    return false
  end if

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

function getSeasons
  local tContent
  put empty into sCurrentSeason
  put empty into sSeasons
  put empty into sActs
  put fetchData("custom", "https://shared." & sRegion & ".a.pvp.net/content-service/v3/content", "GET") into tContent
  if tContent is false then
    return false
  end if
  local tActCount, tEpisodeCount
  local tActIDs
  put empty into tActIDs
  put 1 into tActCount
  put 0 into tEpisodeCount
  repeat for each element tSeason in tContent["Seasons"]
    if tSeason["IsActive"] and tSeason["type"] is "ACT" is true then
      put tSeason["ID"] into sCurrentSeason
    end if
    if tSeason["type"] is "ACT" then
      put tEpisodeCount into sSeasons[tSeason["id"]]["episode"]
      put tActCount into sSeasons[tSeason["id"]]["act"]
      add 1 to tActCount
      put tSeason["id"] & comma after tActIDs
    else if tSeason["type"] is "EPISODE" then
      if the last character of tActIDs is comma then delete the last character of tActIDs
      put 1 into tActCount
      repeat for each item tActID in tActIDs
        put tEpisodeCount into sActs[tActID]["episode"]
        put tActCount into sActs[tActID]["act"]
        add 1 to tActCount
      end repeat
      put empty into tActIDs
      add 1 to tEpisodeCount
      put 1 into tActCount
    end if
  end repeat
  return (sCurrentSeason is not empty)
end getSeasons

function getRanks
  if sRanks is not empty then
    return true
  end if

  local tDownloadedFolder, tRanksFolder
  put specialfolderpath("resources") & "/assets/downloaded" into tDownloadedFolder
  put tDownloadedFolder & "/ranks" into tRanksFolder
  if there is not a folder tDownloadedFolder then
    create folder tDownloadedFolder
  end if
  if there is not a folder tRanksFolder then
    create folder tRanksFolder
  end if

  local tRawRanks
  put fetchData("custom", "https://valorant-api.com/v1/competitivetiers", "get") into tRawRanks
  if tRawRanks is false then
    return false
  end if
  local tIconPath, tEpisodeCount
  put 1 into tEpisodeCount
  repeat for each element tSeason in tRawRanks["data"]
    repeat for each element tRank in tSeason["tiers"]
      local tIconData, tIconLocalPath
      put tRank["tierName"] into sRanks[tEpisodeCount][tRank["tier"]]["name"]
      put tRank["divisionName"] into sRanks[tEpisodeCount][tRank["tier"]]["division"]
      put tRank["largeIcon"] into tIconPath
      put tRanksFolder & "/rank_" & tRank["tierName"] & ".data" into tIconLocalPath
      if there is a file tIconLocalPath then
        put URL("file:" & tIconLocalPath) into sRanks[tEpisodeCount][tRank["tier"]]["icon"]
        next repeat
      end if

      put fetchData("custom",tIconPath,"GET", false) into tIconData
      if tIconData is false then
        put tIconData into sRanks[tEpisodeCount][tRank["tier"]]["icon"]
        next repeat
      end if
      put tIconData into URL("file:" & tIconLocalPath)
      put tIconData into sRanks[tEpisodeCount][tRank["tier"]]["icon"]
    end repeat
    add 1 to tEpisodeCount
  end repeat
  return true
end getRanks

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

  local tDownloadedFolder, tAgentsFolder
  put specialfolderpath("resources") & "/assets/downloaded" into tDownloadedFolder
  put tDownloadedFolder & "/agents" into tAgentsFolder
  if there is not a folder tDownloadedFolder then
    create folder tDownloadedFolder
  end if
  if there is not a folder tAgentsFolder then
    create folder tAgentsFolder
  end if

  local tRawAgents
  put fetchData("custom", "https://valorant-api.com/v1/agents", "get") into tRawAgents
  if tRawAgents is false then
    return false
  end if
  local tIconPath
  repeat for each element tAgent in tRawAgents["data"]
    local tIconData, tIconLocalPath
    put tAgent["displayName"] into sAgents[tAgent["uuid"]]["name"]
    put tAgent["displayIconSmall"] into tIconPath
    put tAgentsFolder & "/agent_" & tAgent["displayName"] & ".data" into tIconLocalPath
    if there is a file tIconLocalPath then
      put URL("file:" & tIconLocalPath) into sAgents[tAgent["uuid"]]["icon"]
      next repeat
    end if

    put fetchData("custom",tIconPath,"GET", false) into tIconData
    if tIconData is false then
      put tIconData into sAgents[tAgent["uuid"]]["icon"]
      next repeat
    end if
    put tIconData into URL("file:" & tIconLocalPath)
    put tIconData into sAgents[tAgent["uuid"]]["icon"]
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

function fetchData pUrlType, pUrl, pMethod, pDecode
  if pMethod is empty then put "GET" into pMethod

  local tHeaders
  put sHeaders into tHeaders

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
    put tAuthHeader into tHeaders
    
    put "https://127.0.0.1:" & sLockPort & "/" & pUrl into tUrl
    break
  case "custom"
    put pUrl into tUrl
    break
  default
    exit fetchData
  end switch

  if sShouldCache is true then
    if tUrl is among the keys of sFetchDataCache then
      /* Check is right cache entry */
      if  sFetchDataCache[tUrl]["pUrlType"] is pUrlType and \
          sFetchDataCache[tUrl]["pMethod"] is pMethod and \
          sFetchDataCache[tUrl]["pDecode"] is pDecode then

          /* Check if cache has expired */
          if (milliseconds() - sFetchDataCache[tUrl]["millis"]) < kCacheTimeoutMilliseconds then
            /* Check cache wasnt failed */
            if sFetchDataCache[tUrl]["result"] is not false then
              return sFetchDataCache[tUrl]["result"]
            end if
          end if
      end if
    end if
  end if

  put pUrlType into sFetchDataCache[tUrl]["pUrlType"]
  put pMethod into sFetchDataCache[tUrl]["pMethod"]
  put pDecode into sFetchDataCache[tUrl]["pDecode"]
  put milliseconds() into sFetchDataCache[tUrl]["millis"]
  put false into sFetchDataCache[tUrl]["result"]

  /* Send request */
  local tResult, tConnectionID
  put milliseconds() into tConnectionID
  put empty into sTsNetResults[tConnectionID]

  tsNetVerifySSLPeer false
  if pMethod is "GET" then
    put tsNetGet(tConnectionID, tUrl, tHeaders, tsNetCallback) into tResult
  else if pMethod is "POST" then
    put tsNetPost(tConnectionID, tUrl, tHeaders, empty, tsNetCallback) into tResult
  else
    return false
  end if
  if tResult is not empty then
    exit fetchData
  end if
  repeat while sTsNetResults[tConnectionID] is empty
    wait 10 milliseconds with messages
  end repeat

  local tResponse
  if pDecode is false then
    put sTsNetResults[tConnectionID] into tResponse
    delete variable sTsNetResults[tConnectionID]
    put tResponse into sFetchDataCache[tUrl]["result"]
    return tResponse
  end if
  try
    put JsonImport(sTsNetResults[tConnectionID]) into tResponse
    delete variable sTsNetResults[tConnectionID]
    put tResponse into sFetchDataCache[tUrl]["result"]
    return tResponse
  catch tError
    delete variable sTsNetResults[tConnectionID]
    return false
  end try
end fetchData

on tsNetCallback pID, pResult, pBytes, pCurlCode
  if pCurlCode is not 0 then
    put false into sTsNetResults[pID]
  else
    local tError, tData
    put tsNetRetrData(pID, tError) into tData
    if tError is empty then
      put tData into sTsNetResults[pID]
    else
      put false into sTsNetResults[pID]
    end if
  end if
  tsNetCloseConn pID
end tsNetCallback

function getPresences
  local tPresences
  ignoreCache
  put fetchData("local", "chat/v4/presences", "GET") into tPresences
  useCache
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
    put rankNumberToRank(tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["CompetitiveTier"], sCurrentSeason) into tPlayerStats["rank"]
  put rankNumberToImage(tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["CompetitiveTier"], sCurrentSeason) into tPlayerStats["rankIcon"]
    put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["RankedRating"] into tPlayerStats["rr"]

    local tWR
    if tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfGames"] is 0 then
      put "-1" into tWR
    else
      put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfWinsWithPlacements"] / tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfGames"] into tWR
    end if
    put tWR into tPlayerStats["wr"]
  end if

  local tCurrentMaxRank, tCurrentMaxDivision, tCurrentMaxSeason
  put 0 into tCurrentMaxRank
  put item 1 of kDivisionList into tCurrentMaxDivision
  repeat for each key tKey in tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"]
    if the number of elements of tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey] is 0 then
      next repeat
    end if
    local tRank, tDivision
    put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey]["Rank"] into tRank
    put rankNumberToDivision(tRank, actIDToEpisode(tKey)) into tDivision
    if compareDivisions(tDivision, tCurrentMaxDivision) is 1 then
      put tPlayerHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey]["Rank"] into tCurrentMaxRank
      put tDivision into tCurrentMaxDivision
      put tKey into tCurrentMaxSeason
    end if
  end repeat
  put rankNumberToRank(tCurrentMaxRank, actIDToEpisode(tCurrentMaxSeason)) into tPlayerStats["peak"]
  put sSeasons[tCurrentMaxSeason]["episode"] into tPlayerStats["peakEpisode"]
  put sSeasons[tCurrentMaxSeason]["act"] into tPlayerStats["peakAct"]
  put rankNumberToImage(tCurrentMaxRank, actIDToEpisode(tCurrentMaxSeason)) into tPlayerStats["peakIcon"]
  put tCurrentMaxRank into tPlayerStats["currentMaxRank"]
  put tCurrentMaxSeason into tPlayerStats["currentMaxSeason"]
  put actIDToEpisode(tCurrentMaxSeason) into tPlayerStats["peakEpisode"]
  put actIDToAct(tCurrentMaxSeason) into tPlayerStats["peakAct"]

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

  /* Send PUT request */
  local tResult, tConnectionID
  put milliseconds() into tConnectionID
  put empty into sTsNetResults[tConnectionID]

  tsNetVerifySSLPeer false
  put tsNetCustomUpload(tConnectionID, (sPdUrl & "name-service/v2/players"), "PUT", tHeaders, tsNetCallback, tJSON) into tResult
  if tResult is not empty then
    exit getNames
  end if
  wait until sTsNetResults[tConnectionID] is not empty with messages
  try
    put JsonImport(sTsNetResults[tConnectionID]) into tResult
    delete variable sTsNetResults[tConnectionID]
  catch tError
    delete variable sTsNetResults[tConnectionID]
    return false
  end try
  

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
    repeat for 5 times
      wait 10 milliseconds with messages
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
    repeat for 5 times
      wait 10 milliseconds with messages
    end repeat
    return getMatchID(pAttempt + 1)
  end if
  return false
end getPreGameID

function getMatchStats pMatchID, pAttempt
  local tResult
  ignoreCache
  put fetchData("glz", "/core-game/v1/matches/" & pMatchID, "get") into tResult
  useCache

  if tResult is not false and tResult["errorCode"] is not "RESOURCE_NOT_FOUND" then
    if tResult["errorCode"] is "BAD_CLAIMS" then
      valorantSetup
      return getMatchStats(pMatchID, pAttempt + 1)
    end if
    return tResult
  else if pAttempt < 5 then
    repeat for 5 times
      wait 10 milliseconds with messages
    end repeat
    return getMatchStats(pMatchID, pAttempt + 1)
  end if
  return false
end getMatchStats

function getPreGameStats pMatchID, pAttempt
  local tResult
  ignoreCache
  put fetchData("glz", "/pregame/v1/matches/" & pMatchID, "get") into tResult
  useCache

  if tResult is not false and tResult["errorCode"] is not "RESOURCE_NOT_FOUND" then
    if tResult["errorCode"] is "BAD_CLAIMS" then
      valorantSetup
      return getPreGameStats(pMatchID, pAttempt + 1)
    end if
    return tResult
  else if pAttempt < 5 then
    repeat for 5 times
      wait 10 milliseconds with messages
    end repeat
    return getPreGameStats(pMatchID, pAttempt + 1)
  end if
  return false
end getPreGameStats

function agentIDtoName pAgentID
  if pAgentID is among the keys of sAgents then
    return sAgents[pAgentID]["name"]
  end if
  return "Unknown"
end agentIDtoName

function agentIDtoIcon pAgentID
  if pAgentID is among the keys of sAgents then
    return sAgents[pAgentID]["icon"]
  end if
  return empty
end agentIDtoIcon

function getInGameTeams pMatchID, pPresences, @xDidFail
  local tLoadouts
  put fetchData("glz", "/core-game/v1/matches/" & pMatchID & "/loadouts", "get") into tLoadouts

  local tMatchStats
  put getMatchStats(pMatchID) into tMatchStats
  if tMatchStats is false then
    redirect
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
    put agentIDtoIcon(tRawPlayer["CharacterID"]) into tPlayer["agentIcon"]
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
    redirect
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
    put agentIDtoIcon(tRawPlayer["CharacterID"]) into tPlayer["agentIcon"]
    
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
  if not waitForSeconds(0.1, getGameState()) then

  end if
  return tTeams
end getPreGameTeam

function actIDToEpisode pActID
  return sActs[pActID]["episode"]
end actIDToEpisode

function actIDToAct pActID
  return sActs[pActID]["act"]
end actIDToAct

function compareDivisions pDiv1, pDiv2
  if itemOffset(pDiv1, kDivisionList) > itemOffset(pDiv2, kDivisionList) then
    return 1
  else
    return 2
  end if
end compareDivisions

function rankNumberToRank pRank, pSeason
  if pSeason is among the keys of sRanks then
    return sRanks[pSeason][pRank]["name"]
  end if
  local tKeys, tRecentKey
  put the keys of sranks into tKeys
  sort tKeys
  put line -1 of tKeys into tRecentKey
  return sRanks[tRecentKey][pRank]["name"]
end rankNumberToRank

function rankNumberToImage pRank, pSeason
  if pSeason is among the keys of sRanks then
    return sRanks[pSeason][pRank]["icon"]
  end if
  local tKeys, tRecentKey
  put the keys of sranks into tKeys
  sort tKeys
  put line -1 of tKeys into tRecentKey
  return sRanks[tRecentKey][pRank]["icon"]
end rankNumberToImage

function rankNumberToDivision pRank, pSeason
  if pSeason is among the keys of sRanks then
    return sRanks[pSeason][pRank]["division"]
  end if
  local tKeys, tRecentKey
  put the keys of sranks into tKeys
  sort tKeys
  put line -1 of tKeys into tRecentKey
  return sRanks[tRecentKey][pRank]["division"]
end rankNumberToDivision

function waitForSeconds pSeconds, pInitialGameState
  local tGameState, tFinishedTime
  put milliseconds() into tFinishedTime
  add pSeconds * 1000 to tFinishedTime
  repeat while milliseconds() < tFinishedTime
    wait 5 milliseconds with messages
    put getGameState() into tGameState
    if not sRunning then
      return false
    end if
    if pInitialGameState is not empty and pInitialGameState is not tGameState then
      redirect
      return false
    end if
  end repeat
  return true
end waitForSeconds

function getGameState
  put getPresences() into tPresences
  put getPrivatePresence(tPresences) into tPrivatePresence
  put tPrivatePresence["sessionLoopState"] into tGameState
  return tGameState
end getGameState
