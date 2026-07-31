; Script do Inno Setup para o instalador do Windows.
;
; Roda depois de `flutter build windows --release`, no workflow do GitHub
; Actions (.github/workflows/build.yml) — este arquivo não compila nada
; sozinho, só empacota o que já foi construído em build/windows/.
;
; `MyAppVersion` chega via linha de comando (`/DMyAppVersion=...`), lida do
; pubspec.yaml pelo workflow, para as duas versões nunca se desalinharem. O
; `#ifndef` mantém um valor padrão para quem rodar o ISCC direto, fora do CI.
#ifndef MyAppVersion
  #define MyAppVersion "0.1.0"
#endif

#define MyAppName "Wroote"
#define MyAppPublisher "Wroote"
#define MyAppExeName "wroote.exe"
#define ReleaseDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{A9905E2C-6324-4B08-8A7C-366E69A26F95}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=WrooteSetup
OutputDir=..\..\build\installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

; Todo o conteúdo da pasta de release — o .exe, as DLLs do Flutter e a
; pasta `data/` com os assets — precisa viajar junto; o app não roda com
; só o .exe sozinho.
[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
