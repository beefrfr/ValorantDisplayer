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
	set the text of field "statusField" to ""
	resizeStack
end openCard

on resizeStack
	layoutControls
end resizeStack

on clearControls
  repeat with x = (the number of controls of card "preLoad") down to 1
    if there is a control x of card "preLoad" then delete control x of card "preLoad"
  end repeat
end clearControls

on createControls
	clearControls

	set the backgroundcolor of me to "34, 42, 53"

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
  set the cProgressBarMax of graphic "progressBarProgress" to 9
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
	set the text of field "statusField" to pStatus
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

on main
	createControls
	layoutControls
	wait 10 milliseconds with messages

	local tErrorCount
	put false into sSetup
	repeat while sSetup is false
		put 0 into tErrorCount
		setStatus "Looking for Valorant Object", 0
	  repeat while getLockFile() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting Header data", 1
	  repeat while getHeaders() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting current Valorant version", 2
	  repeat while getCurrentVersion() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting account region", 3
	  repeat while getRegion() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting season data", 4
	  repeat while getSeasons() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting rank data", 5
	  repeat while getRanks() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting weapon data", 6
	  repeat while getWeapons() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting agent data", 7
	  repeat while getAgents() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Getting map data", 8
	  repeat while getMaps() is false and tErrorCount < 25
	  	wait 25 milliseconds with messages
	  	add 1 to tErrorCount
	  end repeat
	  if tErrorCount > 25 then
	  	next repeat
	  end if

	  setStatus "Setup Complete", 9
	  put true into sSetup
	  redirect
	end repeat
end main
