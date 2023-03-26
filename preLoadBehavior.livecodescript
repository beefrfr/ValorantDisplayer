script "preLoadBehavior"

/* Valorant vars */
global sPdUrl, sGlzUrl
global sRegion
global sCurrentSeason
global sLockName, sLockPID, sLockPort, sLockPassword, sLockProtocol
global sHeaders, sPUUID
global sCurrentVersion
global sSetup

global tRunning

on openCard
   set the text of field "statusField" to ""
   resizeStack
end openCard

on resizeStack
   set the width of field "statusField" to the width of this stack
   set the height of field "statusField" to the height of this stack / 2
   set the topleft of field "statusField" to 0, 0
end resizeStack

on closeStack
  put false into tRunning
  close this stack
end closeStack

on setStatus pStatus
   set the text of field "statusField" to pStatus
   wait 150 milliseconds with messages
end setStatus

on redirect
   setStatus "Startup"
   put true into tRunning
   put false into sSetup

   setStatus ""
   valorantSetup
   repeat while sSetup is false
      setStatus "Valorant not detected"
      valorantSetup
      wait 5 milliseconds with messages

      if not tRunning then
         setStatus "Quit"
         exit redirect
      end if
   end repeat
   
   setStatus "Getting users"
   local tPresences, tGameState, tPrivatePresence
   put getPresences() into tPresences
   
   local tLoops
   put 0 into tLoops
   repeat while getPrivatePresence(tPresences) is empty
      setStatus "Getting current user"
      wait 5 milliseconds with messages
      put getPresences() into tPresences
      add 1 to tLoops
      if tLoops is 10 then
         valorantSetup
         put 0 into tLoops
      end if

      if not tRunning then
         exit redirect
      end if
   end repeat
   setStatus "Getting current screens"
   put getPrivatePresence(tPresences) into tPrivatePresence
   put tPrivatePresence["sessionLoopState"] into tGameState

   if not tRunning then
      setStatus "Quit"
      exit redirect
   end if

   setStatus "Redirecting"
   switch tGameState
      case "MENUS"
         go to card "menu"
         send "menuSetup" to card "menu" in 5 milliseconds
         break
      case "PREGAME"
         break
      case "INGAME"
         break
   end switch
end redirect
