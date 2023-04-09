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
global sAgents
global sSettings

on openCard
	set the text of field "statusField" to ""
	resizeStack
end openCard

on resizeStack
	set the width of field "statusField" to the width of this stack
	set the height of field "statusField" to the height of this stack / 2
	set the topleft of field "statusField" to 0, 0
end resizeStack

on setStatus pStatus
	set the text of field "statusField" to pStatus
	wait 150 milliseconds with messages
end setStatus

on main
	setStatus "Startup"
	put false into sSetup

	setStatus ""
	getValorant
end main

on getValorant
	setStatus "Looking for Valorant process"
	valorantSetup true
	wait 5 milliseconds with messages

	if not isRunning() then
		setStatus "Quit"
		exit getValorant
	end if
	if not sSetup then
		send "getValorant" to me in 50 milliseconds
	else
		getUsers
	end if
end getValorant

on getUsers pLoops
	setStatus "Getting current user"
	local tPresences, tGameState, tPrivatePresence
	put getPresences() into tPresences
	
	if pLoops is empty then put 0 into pLoops
	if pLoops is 10 then
		valorantSetup true
		put 0 into pLoops
		wait 1 milliseconds with messages
	end if
	add 1 to pLoops
	if getPrivatePresence(tPresences) is empty then
		getUsers pLoops
		exit getUsers
	end if

	if not isRunning() then
		exit getUsers
	end if
	redirect
end getUsers
