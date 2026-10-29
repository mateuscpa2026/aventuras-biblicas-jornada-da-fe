#define AppName "Aventuras Bíblicas: Jornada da Fé"
#define AppShortName "Aventuras Biblicas"
#define AppVersion "1.0"
#define AppPublisher "Mateus"
#define AppExe "AventurasBiblicas.exe"

[Setup]
AppId={{8C4F2A6E-3D2B-4B7A-9C51-6F0E2D9A1B42}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={code:GetDefaultDir}
DefaultGroupName=Aventuras Bíblicas
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=D:\Meus Programas de PC\Jogos
OutputBaseFilename=AventurasBiblicas-Setup-{#AppVersion}
SetupIconFile=app.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion=1.0.0.0
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na Área de Trabalho"; GroupDescription: "Atalhos:"; Flags: unchecked

[Files]
Source: "..\build\windows\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\AventurasBiblicas.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\assets\fonts\OFL.txt"; DestDir: "{app}\licencas"; DestName: "Baloo2-OFL.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\Aventuras Bíblicas"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\Aventuras Bíblicas"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "Abrir Aventuras Bíblicas"; Flags: nowait postinstall skipifsilent

[Code]
function GetDefaultDir(Param: String): String;
begin
  if DirExists('D:\Meus Programas de PC\Jogos') then
    Result := 'D:\Meus Programas de PC\Jogos\Aventuras Biblicas'
  else
    Result := ExpandConstant('{autopf}\Aventuras Biblicas');
end;
