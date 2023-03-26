script "valorantBehavior"

global tRunning

on openStack
  send "goToPreLoad" to me in 5 milliseconds
end openStack

on closeStack
  put false into tRunning
  close this stack
end closeStack

on goToPreLoad
  go to card "preLoad"
  send "redirect" to card "preLoad" in 5 milliseconds
end gotoPreLoad

/* Valorant vars */
global sPdUrl, sGlzUrl
global sRegion
global sCurrentSeason
global sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol
global sHeaders, sPUUID
global sCurrentVersion
global sSetup

/* Valorant Information */
on valorantSetup
  put true into sSetup
  if getLockFile() is false then
    put false into sSetup
    exit valorantSetup
  end if
  if getHeaders() is false then
    put false into sSetup
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

function fetchData pUrlType, pUrl, pMethod, rSuccess
  if pMethod is empty then put "GET" into pMethod

  set the httpHeaders to sHeaders

  local tUrl
  switch pUrlType
  case "glz"
    put (sGlzUrl & pUrl) into tUrl
    break
  case "pd"
    put (sPdUrl & pUrl) into tUrl
    break
  case "local"
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
  else
    return false
  end if
end fetchData

function getPresences
  local tPresences
  put fetchData("local", "chat/v4/presences", "GET") into tPresences
  return tPresences["presences"]
end getPresences

function getPrivatePresence pPresences
  repeat for each element tPresence in pPresences
    if tPresence["puuid"] is sPUUID then
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

function getPartyMemberData pPresences
  local tPartyInfo
  put empty into tPartyInfo

  local tParty, tPartyUUIDs
  put empty into tPartyUUIDs
  put getPartyMembers(pPresences) into tParty
  repeat for each element tPartyMember in tParty
    put tPartyMember["uuid"] & comma after tPartyUUIDs
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

    local tPartyMemberHistory
    put fetchData("pd", ("mmr/v1/players/" & tPartyMember["uuid"]), "GET") into tPartyMemberHistory

    if tPartyMemberHistory is false then
      put 0 into tPartyInfo[tPartyMember["uuid"]]["rank"]
      put 0 into tPartyInfo[tPartyMember["uuid"]]["rr"]
      put 0 into tPartyInfo[tPartyMember["uuid"]]["wr"]
      put 0 into tPartyInfo[tPartyMember["uuid"]]["peak"]
      next repeat
    end if

    put rankNumberToRank(tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["CompetitiveTier"]) into tPartyInfo[tPartyMember["uuid"]]["rank"]
    put tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["RankedRating"] into tPartyInfo[tPartyMember["uuid"]]["rr"]

    local tWR
    if tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfGames"] is 0 then
      put "N/A" into tWR
    else
      put tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfWinsWithPlacements"] / tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][sCurrentSeason]["NumberOfGames"] into tWR
    end if
    put tWR into tPartyInfo[tPartyMember["uuid"]]["wr"]

    local tCurrentMaxRank
    put 0 into tCurrentMaxRank
    repeat for each key tKey in tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"]
      if the number of elements of tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey] is 0 then
        next repeat
      end if
      if tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey]["Rank"] > tCurrentMaxRank then
        put tPartyMemberHistory["QueueSkills"]["competitive"]["SeasonalInfoBySeasonID"][tKey]["Rank"] into tCurrentMaxRank
      end if
    end repeat
    put rankNumberToRank(tCurrentMaxRank) into tPartyInfo[tPartyMember["uuid"]]["peak"]
  end repeat
  return tPartyInfo
end getPartyMemberData

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

