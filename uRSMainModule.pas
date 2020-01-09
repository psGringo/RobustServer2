unit uRSMainModule;

interface

uses
  System.SysUtils, System.Classes, SyncObjs, IdContext, IdCustomHTTPServer, System.ImageList, Vcl.ImgList, Vcl.Controls, IdCustomTCPServer, IdHTTPServer, IdBaseComponent,
  IdComponent, IdServerIOHandler, IdSSL, IdSSLOpenSSL, uRSService, System.IOUtils, LDSLogger, IniFiles, uRSConst, VCL.Forms, uPSClasses, uRSTimers, uRSLastHttpRequests,
  uRSSettingsFile;

type
  TRSMainModule = class(TDataModule)
    IdServerIOHandlerSSLOpenSSL: TIdServerIOHandlerSSLOpenSSL;
    Server: TIdHTTPServer;
    ilPics: TImageList;
    procedure ServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  private
    FTimers: TTimers;
    FSettingsFile: ISP<TSettingsFile>;
    FLastHttpRequests: ISP<TLastHttpRequests>;
    FLongTaskThreads: ISP<TThreadList>;
    FCS: ISP<TCriticalSection>;
    FOnStart: TNotifyEvent;
    FOnStop: TNotifyEvent;
    FRSGui: TObject;
    function GetInternalAdress(): string;
    procedure SetRSGui(const Value: TObject);
  public
    constructor Create(aOwner: TComponent; aIsStartOnCreate: Boolean); reintroduce;
    destructor Destroy; override;
    procedure ToggleStartStop();
    procedure Start;
    procedure Stop;
    class function GetInstance(): TRSMainModule;
    property Timers: TTimers read FTimers write FTimers;
    property Adress: string read GetInternalAdress;
    property LongTaskThreads: ISP<TThreadList> read FLongTaskThreads;
    property LastHttpRequests: ISP<TLastHttpRequests> read FLastHttpRequests;
    property CS: ISP<TCriticalSection> read FCS write FCS;
    property OnStart: TNotifyEvent read FOnStart;
    property OnStop: TNotifyEvent read FOnStop;
    property RSGui: TObject read FRSGui write SetRSGui;
    property SettingsFile: ISP<TSettingsFile> read FSettingsFile;
  end;

var
  RSMainModule: TRSMainModule;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uRSCommon, uRSCommandGet, uRSGui;

{ TRSMainModule }

constructor TRSMainModule.Create(aOwner: TComponent; aIsStartOnCreate: Boolean);
var
  filePathSettings: string;
begin
  inherited Create(aOwner);

  filePathSettings := ExtractFilePath(Application.ExeName) + SETTINGS_FILE_NAME;

  FSettingsFile := TSP<TSettingsFile>.Create(TSettingsFile.Create(filePathSettings, Server));
  FLastHttpRequests := TSP<TLastHttpRequests>.Create(TLastHttpRequests.Create(filePathSettings));
  FTimers := TTimers.Create(Self, aIsStartOnCreate);
  FLongTaskThreads := TSP<TThreadList>.Create();
  FCS := TSP<TCriticalSection>.Create();

  RSMainModule := Self;

  if aIsStartOnCreate then
    Start();
end;

destructor TRSMainModule.Destroy;
begin
  Stop();
  inherited;
end;

function TRSMainModule.GetInternalAdress: string;
begin
  Result := FSettingsFile.GetInternalAdress();
end;

class function TRSMainModule.GetInstance: TRSMainModule;
begin
  if Assigned(RobustService) then
    Result := TRSMainModule(RobustService.MainInstance)
  else
    Result := RSMainModule;
end;

procedure TRSMainModule.ServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  cg: ISP<TCommandGet>;
begin
  cg := TSP<TCommandGet>.Create(TCommandGet.Create(AContext, ARequestInfo, AResponseInfo, FLastHttpRequests));
end;

procedure TRSMainModule.SetRSGui(const Value: TObject);
begin
  if Value.ClassType <> TRSGui then
    raise Exception.Create('Value is not a TRSGui');

  FRSGui := Value;
end;

procedure TRSMainModule.Start;
var
  l: ISP<TLogger>;
begin
  if Server.Active then
    Exit;

  l := TSP<TLogger>.Create();
  Server.Active := true;
  l.LogInfo('Server successfully started');

  if Assigned(FOnStart) then
    FOnStart(Self)
end;

procedure TRSMainModule.Stop;
var
  l: ISP<TLogger>;
  i: integer;
begin
  if not Server.Active then
    Exit;

  l := TSP<TLogger>.Create();
  Server.Active := false;
  FTimers.StopAllTimers();

  l.LogInfo('Server successfully stopped');
  with LongTaskThreads.LockList() do
  try
    for i := 0 to Count - 1 do
    begin
      TLongTaskThread(Items[i]).FreeOnTerminate := false; // in other case they will be destroyed automatically
      TLongTaskThread(Items[i]).Terminate;
    end;
  finally
    LongTaskThreads.UnlockList();
  end;

  if Assigned(FOnStop) then
    FOnStop(Self);
end;

procedure TRSMainModule.ToggleStartStop;
begin
  if not Server.Active then
    Start
  else
    Stop();
end;

end.

