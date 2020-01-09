unit uRSServers;

interface

uses
  uRSMainModule, System.Classes, uRSConst, uRSCommon, System.Generics.Collections, VCL.Forms, Winapi.Windows, uPSClasses, idHttp;

type
  TRSServer = class
  private
    FID: TGuid;
    FName: string;
    FPort: integer;
    FFilePath: string;
    FAdress: string;
  public
    constructor Create(const aName: string; aPort: integer; const aFilePath: string; const aAdress: string);
    procedure StartProcess();
    procedure StopProcess();
    function IsServerProcessExists(): Boolean;
    procedure Offline();
    procedure Online();
    property FilePath: string read FFilePath write FFilePath;
    property Name: string read FName;
    property Adress: string read FAdress;
    property Port: integer read FPort;
  end;

  TRSServers = class
  private
    FServers: TObjectList<TRSServer>;
    FFIlePathSettings: string;
    FCount: integer;
    function CopyServer(aName: string): string;
    procedure WriteServerToIni(const aName: string; aPort: integer; const aFilePath: string; const aAdress: string);
    procedure ReadServersFromIni();
    function GetServer(aIndex: integer): TRSServer;
    function GetCount(): integer;
    procedure SetCount(const Value: integer);
  public
    constructor Create();
    destructor Destroy; override;
    procedure Add(aName: string; aPort: integer);
    procedure Delete(aName: string);
    function FindByName(aName: string): TRSServer;
    function FindByNameOrPort(aName: string; aPort: integer): TRSServer;
    property Item[aIndex: integer]: TRSServer read GetServer; default;
    property Count: integer read GetCount;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, uMain, System.IniFiles;

{ TRSServers }

procedure TRSServers.Add(aName: string; aPort: integer);
var
  serverFilePath: string;
  adress: string;
  rs: TRSServer;
begin
  rs := FindByNameOrPort(aName, aPort);

  if Assigned(rs) then
    raise Exception.Create(Format('server with name %s or Port %s already exists', [aName, aPort.ToString()]));

  serverFilePath := CopyServer(aName);

  adress := Format('%s://%s:%s', [DEFAULT_HTTP_PROTOCOL, DEFAULT_HTTP_HOST, aPort.ToString()]);
  rs := TRSServer.Create(aName, aPort, serverFilePath, adress);
  FServers.Add(rs);
  WriteServerToIni(aName, aPort, serverFilePath, adress);
end;

constructor TRSServers.Create;
var
  fs: TFileStream;
begin
  FServers := TObjectList<TRSServer>.Create(true);
  FFIlePathSettings := Format('%s\%s', [ExtractFileDir(Application.ExeName), SETTINGS_FILE_NAME]);

  if not TFIle.Exists(FFIlePathSettings) then
  begin
    fs := TFile.Create(FFIlePathSettings);
    try
      // do nothing
    finally
      fs.Free();
    end;
  end;

  ReadServersFromIni();
end;

procedure TRSServers.Delete(aName: string);
var
  rs: TRSServer;
begin
  rs := FindByName(aName);
  if rs = nil then
    raise Exception.Create(Format('server %s not found', [aName]));

  rs.StopProcess();
  TDirectory.Delete(ExtractFileDir(rs.FilePath), true);
end;

destructor TRSServers.Destroy;
begin
  FServers.Destroy();
  inherited;
end;

function TRSServers.FindByName(aName: string): TRSServer;
var
  rs: TRSServer;
begin
  Result := nil;

  for rs in FServers do
  begin
    if rs.Name = aName then
    begin
      Result := rs;
      Exit;
    end;
  end;
end;

function TRSServers.FindByNameOrPort(aName: string; aPort: integer): TRSServer;
var
  rs: TRSServer;
begin
  Result := nil;

  for rs in FServers do
  begin
    if (rs.Name = aName) or (rs.Port = aPort) then
    begin
      Result := rs;
      Exit;
    end;
  end;
end;

function TRSServers.GetCount: integer;
begin
  Result := FServers.Count;
end;

function TRSServers.GetServer(aIndex: integer): TRSServer;
begin

end;

procedure TRSServers.ReadServersFromIni;
var
  ini: ISP<TIniFile>;
  serverName: string;
  adress: string;
  port: integer;
  servers: ISP<TStringList>;
  i: integer;
  rs: TRSServer;
  filePath: string;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFIlePathSettings));
  servers := TSP<TStringList>.Create();
  ini.ReadSections(servers);
  for i := 0 to servers.Count - 1 do
  begin
    serverName := servers[i];
    rs := FindByName(serverName);
    if not Assigned(rs) then
    begin
      adress := ini.ReadString(serverName, 'adress', '<None>');
      filePath := ini.ReadString(serverName, 'serverFilePath', '<None>');
      port := ini.ReadInteger(serverName, 'port', -1);
      rs := TRSServer.Create(serverName, port, filePath, adress);
      FServers.Add(rs);
    end;
  end;
end;

procedure TRSServers.SetCount(const Value: integer);
begin
  FCount := Value;
end;

procedure TRSServers.WriteServerToIni(const aName: string; aPort: integer; const aFilePath: string; const aAdress: string);
var
  ini: ISP<TIniFile>;
  adress: string;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFIlePathSettings));
  ini.WriteInteger(aName, 'port', aPort);
  ini.WriteString(aName, 'adress', aAdress);
  ini.WriteString(aName, 'serverFilePath', aFilePath);
end;

function TRSServers.CopyServer(aName: string): string;
var
  ext: string;
  serverFileName: string;
  serverFilePath: string;
  absDir: string;
begin
  absDir := Format('%s\%s\%s', [ExtractFileDir(Application.ExeName), SERVERS_RELATIVE_DIR, aName]);
  if TDirectory.Exists(absDir) then
    raise Exception.Create(Format('Subdirectory %s already exists, please find another server name', [absDir]));
  TDirectory.CreateDirectory(absDir);
  ext := ExtractFileExt(Application.ExeName);
  serverFileName := Format('%s_%s%s', [ChangeFileExt(ExtractFileName(Application.ExeName), ''), aName, ext]);
  serverFilePath := Format('%s\%s', [absDir, serverFileName]);
  TFile.Copy(Application.ExeName, serverFilePath);

  Result := serverFilePath;
end;

{ TRSServer }

constructor TRSServer.Create(const aName: string; aPort: integer; const aFilePath: string; const aAdress: string);
begin
  FName := aName;
  FPort := aPort;
  FFilePath := aFilePath;
  FAdress := aAdress;
end;

procedure TRSServer.StartProcess;
var
  psWindows: ISP<TPSWindows>;
begin
  psWindows := TSP<TPSWindows>.Create();
  if not psWindows.IsProcessExists(FFilePath) then
    psWindows.StartProcess(FFilePath);
end;

procedure TRSServer.StopProcess;
var
  psWindows: ISP<TPSWindows>;
begin
  psWindows := TSP<TPSWindows>.Create();
  if psWindows.IsProcessExists(FFilePath) then
    psWindows.StopProcess(FFilePath);
end;

function TRSServer.IsServerProcessExists: Boolean;
var
  psWindows: ISP<TPSWindows>;
begin
  psWindows := TSP<TPSWindows>.Create();
  Result := psWindows.IsProcessExists(FFilePath);
end;

procedure TRSServer.Offline;
var
  c: ISP<TIdHTTP>;
  r: string;
begin
  c := TSP<TIdHTTP>.Create();
  r := c.Get(Format('%s/System/Offline', [FAdress]));
end;

procedure TRSServer.Online;
var
  c: ISP<TIdHTTP>;
  r: string;
begin
  c := TSP<TIdHTTP>.Create();
  r := c.Get(Format('%s/System/Online', [FAdress]));
end;

end.

