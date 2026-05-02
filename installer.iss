; =============================================================================
; ApprenderAI — Script Inno Setup
; =============================================================================
;
; COME USARE QUESTO FILE
; ──────────────────────
; 1. Assicurati che in lib/config/app_config.dart sia impostato:
;       static const bool isDev = false;
;
; 2. Esegui la build di release Flutter:
;       flutter build windows --release
;
; 3. Verifica che la cartella di output esista:
;       build\windows\x64\runner\Release\
;
; 4. Apri questo file con Inno Setup Compiler (tasto destro → "Compile")
;    oppure da riga di comando:
;       iscc installer.iss
;
; 5. L'installer verrà generato in:
;       installer_output\ApprenderAI_Setup_1.0.0.exe
;
; REQUISITI
; ─────────
; - Inno Setup 6.x  (https://jrsoftware.org/isinfo.php)
; - Flutter release build già completata (step 2)
; =============================================================================

#define AppName        "ApprenderAI"
#define AppVersion     "1.0.0"
#define AppPublisher   "Andrea Conrado"
#define AppURL         "https://lastmasteroflife.github.io/Portfolio/pages/ApprenderAI.html"
#define AppExeName     "progetto_finale.exe"
#define AppDescription "Piattaforma di studio AI-powered"

#define BuildDir       "build\windows\x64\runner\Release"
#define AppIcon        "windows\runner\resources\app_icon.ico"

; =============================================================================
; [Setup]
; =============================================================================
[Setup]

AppId={{B3F2A1C0-7E4D-4B8F-9A5C-D6E3F8201234}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
AppComments={#AppDescription}
AppCopyright=Copyright (C) 2025 {#AppPublisher}. Tutti i diritti riservati.

DefaultDirName={localappdata}\{#AppName}
DefaultGroupName={#AppName}
DirExistsWarning=no
DisableProgramGroupPage=yes

OutputDir=installer_output
OutputBaseFilename=ApprenderAI_Setup_{#AppVersion}
SetupIconFile={#AppIcon}
UninstallDisplayIcon={app}\{#AppExeName}

Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

WizardStyle=modern
WizardResizable=yes
DisableDirPage=no
DisableReadyPage=no

PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

MinVersion=10.0.17763

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; =============================================================================
; [Languages]
; =============================================================================
[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

; =============================================================================
; [Tasks]
; =============================================================================
[Tasks]
Name: "desktopicon";     Description: "Crea un'icona sul Desktop";            GroupDescription: "Icone aggiuntive:"; Flags: unchecked
Name: "startmenuicon";   Description: "Crea una voce nel menu Start";         GroupDescription: "Icone aggiuntive:"; Flags: checkedonce
Name: "quicklaunchicon"; Description: "Crea un'icona nella barra delle app";  GroupDescription: "Icone aggiuntive:"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

; =============================================================================
; [Files]
; =============================================================================
[Files]
Source: "{#BuildDir}\{#AppExeName}"; DestDir: "{app}";      Flags: ignoreversion
Source: "{#BuildDir}\*.dll";         DestDir: "{app}";      Flags: ignoreversion
Source: "{#BuildDir}\data\*";        DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; =============================================================================
; [Icons]
; =============================================================================
[Icons]
Name: "{group}\{#AppName}";              Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: startmenuicon
Name: "{group}\Disinstalla {#AppName}";  Filename: "{uninstallexe}";                                          Tasks: startmenuicon
Name: "{autodesktop}\{#AppName}";        Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: quicklaunchicon

; =============================================================================
; [Run]
; =============================================================================
[Run]
Filename: "{app}\{#AppExeName}"; Description: "Avvia {#AppName} adesso"; Flags: nowait postinstall skipifsilent; WorkingDir: "{app}"

; =============================================================================
; [UninstallRun]
; =============================================================================
[UninstallRun]
Filename: "taskkill.exe"; Parameters: "/F /IM {#AppExeName}"; Flags: runhidden; RunOnceId: "KillApp"

; =============================================================================
; [UninstallDelete]
; =============================================================================
[UninstallDelete]
Type: filesandordirs; Name: "{app}\cache"
Type: filesandordirs; Name: "{app}\logs"

; =============================================================================
; [Messages]
; =============================================================================
[Messages]
WelcomeLabel1=Benvenuto nel programma di installazione di [name]
WelcomeLabel2=Questo programma installerà [name] [ver] sul tuo computer.%n%nSi consiglia di chiudere tutte le altre applicazioni prima di continuare.%n%nFai clic su Avanti per continuare.
FinishedHeadingLabel=Installazione di [name] completata
FinishedLabel=[name] è stato installato correttamente sul tuo computer.%n%nFai clic su Fine per chiudere il programma di installazione.

; =============================================================================
; [Code]
; =============================================================================
[Code]

function VCRedistInstalled(): Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(
    HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed',
    Installed
  ) and (Installed = 1);
end;

procedure InitializeWizard();
var
  Dummy: Integer;
begin
  if not VCRedistInstalled() then
  begin
    Dummy := MsgBox(
      'Attenzione: Visual C++ Redistributable 2022 (x64) non sembra essere installato.' + #13#10 + #13#10 +
      'L''applicazione potrebbe non avviarsi correttamente.' + #13#10 +
      'Scaricalo da: https://aka.ms/vs/17/release/vc_redist.x64.exe' + #13#10 + #13#10 +
      'Puoi continuare l''installazione e installare il Redistributable in seguito.',
      mbInformation,
      MB_OK
    );
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  UserDataPath: String;
  AppNameStr: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    AppNameStr := 'ApprenderAI';
    UserDataPath := ExpandConstant('{localappdata}') + '\' + AppNameStr;
    if DirExists(UserDataPath) then
    begin
      if MsgBox(
        'Vuoi eliminare anche i dati e le preferenze salvate di ' + AppNameStr + '?' + #13#10 +
        '(' + UserDataPath + ')',
        mbConfirmation,
        MB_YESNO
      ) = IDYES then
        DelTree(UserDataPath, True, True, True);
    end;
  end;
end;