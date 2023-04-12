script "preLoadBehavior"

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

on openCard
	layoutControls
end openCard

on resizeStack
  lock screen
  layoutControls
  unlock screen
end resizeStack

on clearControls
  repeat with x = (the number of controls of card "preLoad") down to 1
    if there is a control x of card "preLoad" then delete control x of card "preLoad"
  end repeat
end clearControls

on createControls
	clearControls

	set the backgroundcolor of me to getBackgroundColor()

  create field "statusField" in card "preLoad"
  set the lockText of field "statusField" to true
  set the textAlign of field "statusField" to "center"
  set the textSize of field "statusField" to 14
  set the textStyle of field "statusField" to "bold"
  set the textHeight of field "statusField" to 30
  set the margins of field "statusField" to 0
  set the borderWidth of field "statusField" to 0
  set the opaque of field "statusField" to false
  set the text of field "statusField" to ""
  set the foregroundcolor of field "statusField" to "255, 255, 255"
  set the blendlevel of field "statusField" to 100 - ((200 / 255) * 100)

  create field "loadingField" in card "preLoad"
  set the lockText of field "loadingField" to true
  set the textAlign of field "loadingField" to "center"
  set the textSize of field "loadingField" to 36
  set the textStyle of field "loadingField" to "bold"
  set the textHeight of field "loadingField" to 70
  set the margins of field "loadingField" to 0
  set the borderWidth of field "loadingField" to 0
  set the opaque of field "loadingField" to false
  set the text of field "loadingField" to "Loading"
  set the foregroundcolor of field "loadingField" to "255, 255, 255"
  set the blendlevel of field "loadingField" to 100 - ((200 / 255) * 100)

  set the height of the templategraphic to 50
  set the opaque of the templategraphic to true
  set the lineSize of the templategraphic to 0

  create graphic "progressBarBack" in card "preLoad"
  set the backgroundColor of graphic "progressBarBack" to "25, 31, 40"
  set the dropShadow["distance"] of graphic "progressBarBack" to 3
	set the dropShadow["size"] of graphic "progressBarBack" to 3
	set the dropShadow["color"] of graphic "progressBarBack" to 0,0,0
	set the dropShadow["filter"] of graphic "progressBarBack" to "box3pass"
	set the dropShadow["opacity"] of graphic "progressBarBack" to 255
	set the dropShadow["spread"] of graphic "progressBarBack" to 0
	set the dropShadow["blendmode"] of graphic "progressBarBack" to "normal"
	set the dropShadow["angle"] of graphic "progressBarBack" to 45
	set the dropShadow["knockout"] of graphic "progressBarBack" to true

  create graphic "progressBarProgress" in card "preLoad"
  set the backgroundcolor of graphic "progressBarProgress" to "153,41,41"
  set the cProgressBarCount of graphic "progressBarProgress" to 0
  set the cProgressBarMax of graphic "progressBarProgress" to 10
end createControls

on layoutControls
	lock screen
	try
		set the width of field "statusField" to the width of this stack
		set the height of field "statusField" to (the height of this stack / 2) - 25
		set the topLeft of field "statusField" to 0, (the height of this stack / 2) + 25

		set the width of field "loadingField" to the width of this stack
		set the height of field "loadingField" to 70
		set the topLeft of field "loadingField" to 0, ((the height of this stack / 2) - 25) - 70

		set the width of graphic "progressBarBack" to the width of this stack - 100
		set the height of graphic "progressBarBack" to 50
		set the topLeft of graphic "progressBarBack" to 50, (the height of this stack / 2) - 25

		set the width of graphic "progressBarProgress" to ((the width of graphic "progressBarBack" / the cProgressBarMax of graphic "progressBarProgress") * the cProgressBarCount of graphic "progressBarProgress")
		set the height of graphic "progressBarProgress" to 50
		set the topLeft of graphic "progressBarProgress" to the topLeft of graphic "progressBarBack"
	catch tErr
    createControls
    layoutControls
	end try
	unlock screen
end layoutControls

on setStatus pStatus, pProgress
	if the cProgressBarCount of graphic "progressBarProgress" < pProgress then
		local tStep
		put (pProgress - the cProgressBarCount of graphic "progressBarProgress") / 10 into tStep
		repeat for 10 times
			set the cProgressBarCount of graphic "progressBarProgress" to the cProgressBarCount of graphic "progressBarProgress" + tStep
			layoutControls
			wait 5 milliseconds with messages
		end repeat
	else
		wait 50 milliseconds with messages
	end if
end setStatus

on update pMessage
	set the text of field "statusField" to pMessage
end update

on main
	createControls
	layoutControls
	wait 10 milliseconds with messages
  set the text of field "loadingField" to "Loading"

  unlock screen with visual effect "dissolve" very fast

  local tGeneralSetup
  put false into tGeneralSetup
  /* General Loading */
  local tStep, tErrorCount
  repeat while tGeneralSetup is false
  	put 0 into tErrorCount
		setStatus "Loading settings", tStep
	  repeat while getSettings() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStep

		setStatus "Getting rank data", tStep
	  repeat while getRanks() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStep

	  setStatus "Getting weapon data", tStep
	  repeat while getWeapons() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStep

	  setStatus "Getting agent data", tStep
	  repeat while getAgents() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStep

	  setStatus "Getting map data", tStep
	  repeat while getMaps() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStep
	  put true into tGeneralSetup
	end repeat

	local tStepForProfile
	put false into sSetup
	repeat while sSetup is false
		put 0 into tErrorCount
		put tStep into tStepForProfile

	  /* Profile Specific */
		setStatus "Looking for Riot Client", tStepForProfile
	  repeat while getLockFile() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStepForProfile
	  wait 250 milliseconds with messages

	  setStatus "Getting Header data", tStepForProfile
	  repeat while getHeaders() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStepForProfile
	  wait 250 milliseconds with messages

	  setStatus "Getting current Valorant version", tStepForProfile
	  repeat while getCurrentVersion() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStepForProfile
	  wait 250 milliseconds with messages

	  setStatus "Getting account region", tStepForProfile
	  repeat while getRegion() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStepForProfile
	  wait 250 milliseconds with messages

	  setStatus "Getting season data", tStepForProfile
	  repeat while getSeasons() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if
	  add 1 to tStepForProfile
	  wait 250 milliseconds with messages

		if checkSetup() is false then
			next repeat
		end if

	  set the text of field "loadingField" to "Waiting"
	  setStatus "Looking for Valorant Process", tStepForProfile
	  local tPresences, tPrivatePresence, tGameState
    put getPresences() into tPresences
    put getPrivatePresence(tPresences) into tPrivatePresence
    put tPrivatePresence["sessionLoopState"] into tGameState
    if tGameState is empty then
    	next repeat
    end if

	  put true into sSetup
	  redirect
	end repeat
end main
