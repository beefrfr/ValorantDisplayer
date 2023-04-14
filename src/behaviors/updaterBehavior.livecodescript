script "updaterBehavior"

local sDownloadProgress, sSettings

constant kContentUrl = "https://beefrfr.uk/content.php"

constant kRelease = "beta"
constant kVersion = "2"
constant kSubversion = "3"

on openStack
	set the backgroundcolor of me to "34, 42, 53"
	getSettings
	clearControls
	layoutControls
	getData
end openStack

on resizeStack
	lock screen
	layoutControls
	unlock screen
end resizeStack

on getSettings
  /* Load Settings */
  local tValorantDisplayerFolder
  put specialfolderpath("resources") into tValorantDisplayerFolder
  if there is not a folder tValorantDisplayerFolder then
    create folder tValorantDisplayerFolder
  end if

  put empty into sDefaultSettings
  put kRelease into sDefaultSettings["release"]
  put kVersion into sDefaultSettings["version"]
  put kSubversion into sDefaultSettings["subversion"]

  local tSettingsFile
  put (tValorantDisplayerFolder & slash & "settings.json") into tSettingsFile
  if there is not a file tSettingsFile then
    put sDefaultSettings into sSettings
    put jsonExport(sDefaultSettings) into URL("file:" & tSettingsFile)
  else
    local tSettingsContents
    put URL("file:" & tSettingsFile) into tSettingsContents
    put JsonImport(tSettingsContents) into sSettings

    local tSettingsChanged
    put false into tSettingsChanged
    repeat for each key tKey in sDefaultSettings
      if tKey is not among the keys of sSettings or sSettings[tKey] is empty then
        put sDefaultSettings[tKey] into sSettings[tkey]
        put true into tSettingsChanged
      end if
    end repeat

    if tSettingsChanged then
      put jsonExport(sSettings) into URL("file:" & tSettingsFile)
    end if
  end if
end getSettings

on saveSettings
  local tSettingsFile, tValorantDisplayerFolder
  put specialfolderpath("resources") into tValorantDisplayerFolder
  put (tValorantDisplayerFolder & slash & "settings.json") into tSettingsFile
  put jsonExport(sSettings) into URL("file:" & tSettingsFile)
end saveSettings

on clearControls
	repeat with x = (the number of controls of me) down to 1
		if there is a control x of me then delete control x of me
	end repeat
end clearControls

on createControls
	clearControls

	set the height of the templategraphic to 50
	set the opaque of the templategraphic to true
	set the lineSize of the templategraphic to 0

	create graphic "progressBarBack"
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

	create graphic "progressBarProgress"
	set the backgroundcolor of graphic "progressBarProgress" to "153,41,41"
	set the cProgressBarCount of graphic "progressBarProgress" to 0
	set the cProgressBarMax of graphic "progressBarProgress" to 10
end createControls

on layoutControls
	lock screen
	try
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

on getData
	put empty into sDownloadProgress
	put false into sDownloadProgress["allStarted"]

	local tVersionResult
	get URL(kContentUrl & "?data=current")
	put it into tResult
	local tCurrentVersion
	put JsonImport(tResult) into tCurrentVersion

	if tCurrentVersion["release"] is "beta" and sSettings["release"] is "release" then
		loadValorantDisplayer
		exit getData
	else if tCurrentVersion["release"] is sSettings["release"] then
		if sSettings["version"] >= tCurrentVersion["version"] then
			loadValorantDisplayer
			exit getData
		else if sSettings["version"] is tCurrentVersion["version"] and sSettings["subversion"] >= tCurrentVersion["subversion"] then
			loadValorantDisplayer
			exit getData
		end if
  end if

	libURLSetStatusCallback "showProgress", the long name of me
	
	set the cProgressBarCount of graphic "progressBarProgress" to 0
	set the cProgressBarMax of graphic "progressBarProgress" to tCurrentVersion["size"]

	set the cNewRelease of this stack to tCurrentVersion["release"]
	set the cNewVersion of this stack to tCurrentVersion["version"]
	set the cNewSubversion of this stack to tCurrentVersion["subversion"]

	put the number of elements of tCurrentVersion["requirements"] into sDownloadProgress["totalCount"]
	put 0 into sDownloadProgress["downloadCount"]
	repeat for each element tRequirement in tCurrentVersion["requirements"]
		wait 50 milliseconds with messages
		local tUrl, tGetData
		put "data=file&" into tGetData
		put "directory=" & urlencode(tCurrentVersion["directory"]) & "&" after tGetData
		put "file=" & urlencode(tRequirement) after tGetData
		put (kContentUrl & "?" & tGetData) into tUrl

		put empty into sDownloadProgress["urls"][tUrl]
		put 0 into sDownloadProgress["urls"][tUrl]["downloaded"]
		put false into sDownloadProgress["urls"][tUrl]["complete"]
		put empty into sDownloadProgress["urls"][tUrl]["data"]
		put tRequirement into sDownloadProgress["urls"][tUrl]["location"]
		load URL tUrl with message "downloadComplete"
	end repeat
	put true into sDownloadProgress["allStarted"]
end getData

command showProgress pURL, pStatus
	if the number of items in pStatus > 1 then
		put item 2 of pStatus into sDownloadProgress["urls"][pUrl]["downloaded"]
	end if

	if sDownloadProgress["allStarted"] is true then
		local tDownloadedBytes
		repeat for each element pCurrentDownload in sDownloadProgress["urls"]
			add pCurrentDownload["downloaded"] to tDownloadedBytes
		end repeat
		set the cProgressBarCount of graphic "progressBarProgress" to tDownloadedBytes
		layoutControls
	end if
end showProgress

command downloadComplete pURL, pStatus
	if pStatus = "error" or pStatus = "timeout" then
		answer error "Update Failed"
		quit
	end if
	if sDownloadProgress["urls"][pUrl]["complete"] is false then
		put true into sDownloadProgress["urls"][pUrl]["complete"]
		put URL pURL into sDownloadProgress["urls"][pUrl]["data"]
		add 1 to sDownloadProgress["downloadCount"]
		if sDownloadProgress["downloadCount"] is sDownloadProgress["totalCount"] then
			saveFiles
		end if
	end if
end downloadComplete

on saveFiles
	set the cProgressBarCount of graphic "progressBarProgress" to the cProgressBarMax of graphic "progressBarProgress" 

	local tResources
	put specialFolderPath("resources") into tResources
	set the itemdelimiter to slash
	repeat for each key tUrl in sDownloadProgress["urls"]
		local tLocalPath, tAbsolutePath
		put sDownloadProgress["urls"][tUrl]["location"] into tLocalPath
		put tResources & slash & tLocalPath into tAbsolutePath

		if the number of items of tLocalPath > 1 then
			local tParentDirectory
			put empty into tParentDirectory
			repeat for each item tCurrentDirectory in (item 1 to -2 of tLocalPath)
				put slash & tCurrentDirectory after tParentDirectory
				local tCurrentDirectoryAbsolutePath
				put tResources & tParentDirectory into tCurrentDirectoryAbsolutePath
				if there is not a folder tCurrentDirectoryAbsolutePath then
					create folder tCurrentDirectoryAbsolutePath
				end if
			end repeat
		end if

		put URL tUrl into URL ("binfile:" & tAbsolutePath)
		unload tUrl
	end repeat
	set the itemdelimiter to comma
	loadValorantDisplayer
end saveFiles

on loadValorantDisplayer
	local tResources
	put specialFolderPath("resources") into tResources

	put the cNewRelease of this stack into sSettings["release"]
	put the cNewVersion of this stack into sSettings["version"]
	put the cNewSubversion of this stack into sSettings["subversion"]
	saveSettings

	launch document (tResources & "/Valorant Displayer.exe")
	quit
end loadValorantDisplayer
