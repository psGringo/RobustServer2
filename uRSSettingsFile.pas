unit uRSSettingsFile;

interface

uses
  System.SysUtils, System.Classes, SyncObjs, IdContext, IdCustomHTTPServer, System.ImageList, Vcl.ImgList, Vcl.Controls, IdCustomTCPServer, IdHTTPServer, IdBaseComponent,
  IdComponent, IdServerIOHandler, IdSSL, IdSSLOpenSSL, uRSService, System.IOUtils, LDSLogger, IniFiles, uRSConst, VCL.Forms, uPSClasses, uRSTimers, uRSLastHttpRequests, idhttp,
  superObject;

type
  TAdress = class
  private
    FInternalAdress: string;
    FExternalAdress: string;
  public
    property InternalAdress: string read FInternalAdress write FInternalAdress;
    property ExternalAdress: string read FExternalAdress write FExternalAdress;
  end;

  THost = class
  private
    FExternalHost: string;
    FInternalHost: string;
  public
    property InternalHost: string read FInternalHost write FInternalHost;
    property ExternalHost: string read FExternalHost write FExternalHost;
  end;

  THttpProtocolSettings = class
  private
    FProtocol: string;
    FHost: ISP<THost>;
    FPort: integer;
    FAdress: ISP<TAdress>;
    FFilePathSettings: string;
    function GetPort(): integer;
    function GetProtocol(): string;
    procedure CorrectPortIfNeeded(aIni: ISP<TIniFile>);
    procedure ReadSettingsFromFile();
    procedure WriteSettingsToFile();
    function GetExternalHost(): string;
  public
    constructor Create(aFilePathSettings: string; aIsCreatedNewSettingsFile: Boolean);
    property Host: ISP<THost> read FHost;
    property Port: integer read FPort;
    property Adress: ISP<TAdress> read FAdress;
    property Protocol: string read FProtocol;
  end;

  TSettingsFile = class
  private
    FHttpProtocol: ISP<THttpProtocolSettings>;
    FWasCreatedNewFile: Boolean;
  public
    constructor Create(aSettingsFilePath: string; aServer: TIdHTTPServer);
    property HttpProtocol: ISP<THttpProtocolSettings> read FHttpProtocol;
    function GetInternalAdress(): string;
    function GetExternalAdress(): string;
  end;

implementation

{ FHttpProtocolSettings }

procedure THttpProtocolSettings.ReadSettingsFromFile();
var
  ini: ISP<TIniFile>;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFIlePathSettings));
  FProtocol := ini.ReadString('server', 'protocol', '<None>');
  FHost.InternalHost := ini.ReadString('server', 'hostInternal', '<None>');
  FHost.ExternalHost := ini.ReadString('server', 'hostExternal', '<None>');
  FPort := ini.ReadString('server', 'port', '<None>').ToInteger();

  CorrectPortIfNeeded(ini);
end;

procedure THttpProtocolSettings.WriteSettingsToFile();
var
  ini: ISP<TIniFile>;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFIlePathSettings));
  ini.WriteString('server', 'protocol', GetProtocol());
  ini.WriteString('server', 'hostInternal', DEFAULT_HTTP_HOST);
  ini.WriteString('server', 'hostExternal', FHost.ExternalHost);
  ini.WriteString('server', 'port', GetPort().ToString());
end;


{ THttpProtocolSettings }

procedure THttpProtocolSettings.CorrectPortIfNeeded(aIni: ISP<TIniFile>);
var
  port: integer;
begin
  port := GetPort();

  if FPort <> port then
  begin
    aIni.WriteString('server', 'port', port.ToString());
    FPort := port;
  end;
end;

constructor THttpProtocolSettings.Create(aFilePathSettings: string; aIsCreatedNewSettingsFile: Boolean);
begin
  FFIlePathSettings := aFilePathSettings;

  FHost := TSP<THost>.Create();
  FAdress := TSP<TAdress>.Create();

  FHost.ExternalHost := GetExternalHost();

  if aIsCreatedNewSettingsFile then
    WriteSettingsToFile();

  ReadSettingsFromFile();

  FAdress.InternalAdress := Format('%s://%s:%s', [FProtocol, FHost.InternalHost, FPort.ToString()]);
  FAdress.ExternalAdress := Format('%s://%s:%s', [FProtocol, FHost.ExternalHost, FPort.ToString()]);
end;

function THttpProtocolSettings.GetExternalHost: string;
var
  client: ISP<TIdHttp>;
  json: ISuperObject;
begin
  client := TSP<TIdHttp>.Create();
  try
    json := SO(client.Get('http://ipinfo.io/json'));
    Result := json.S['ip'];
  except
    on E: Exception do
      Result := 'ExternalIp not defined with http://ipinfo.io/json, check internet connection or adress...';
  end;
end;

function THttpProtocolSettings.GetPort: integer;
var
  ini: ISP<TIniFile>;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFIlePathSettings));
  Result := ini.ReadString('server', 'port', '<None>').ToInteger();
end;

function THttpProtocolSettings.GetProtocol: string;
var
  ini: ISP<TIniFile>;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFIlePathSettings));
  Result := ini.ReadString('server', 'protocol', '<None>');
end;

{ TSettingsFile }

constructor TSettingsFile.Create(aSettingsFilePath: string; aServer: TIdHTTPServer);
var
  validator: ISP<TParamValidator>;
  fs: TFileStream;
begin
  FWasCreatedNewFile := false;
  validator := TSP<TParamValidator>.Create();
  validator.EnsureNotNull(aServer);

  if not TFile.Exists(aSettingsFilePath) then
  begin
    FWasCreatedNewFile := true;
    fs := TFile.Create(aSettingsFilePath);
    try
      // do nothing...
    finally
      fs.Free();
    end;
  end;

  FHttpProtocol := TSP<THttpProtocolSettings>.Create(THttpProtocolSettings.Create(aSettingsFilePath, FWasCreatedNewFile));
  aServer.DefaultPort := FHttpProtocol.Port;
end;

function TSettingsFile.GetExternalAdress: string;
begin
  Result := FHttpProtocol.Adress.ExternalAdress;
end;

function TSettingsFile.GetInternalAdress: string;
begin
  Result := FHttpProtocol.Adress.InternalAdress;
end;

end.

