; AppVersion defines the folder in Dist to compile from
#define AppVersion "Beta 1.1"

#define AppName "Valorant Displayer"
#define AppDev "beefrfr"
#define AppUrl "https://github.com/beefrfr/ValorantDisplayer"
#define AppExe "Valorant Displayer.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{83C22432-C91F-48CB-B608-3E82E6209A97}
AppName={#AppName}
AppVersion={#AppVersion}
;AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppDev}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppUpdatesURL={#AppUrl}
DefaultDirName={userappdata}\{#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=C:\Users\ben\Desktop\ValorantDisplayer\App\Dist\Installers\{#AppVersion}
OutputBaseFilename=Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\ben\Desktop\ValorantDisplayer\App\Dist\Files\{#AppVersion}\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\ben\Desktop\ValorantDisplayer\App\Dist\Files\{#AppVersion}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

