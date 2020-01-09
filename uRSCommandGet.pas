unit uRSCommandGet;

interface

uses
  System.Classes, IdContext, IdCustomHTTPServer, System.Generics.Collections, superobject, System.NetEncoding, System.IOUtils, Vcl.Forms, uUniqueName, uRSCommon, Spring.Collections,
  uRP, uRPRegistrations, IdException, uPSClasses, SyncObjs, uRSLastHttpRequests;

type
  TCommandGet = class
  private
    FContext: TIdContext;
    FRequestInfo: TIdHTTPRequestInfo;
    FResponseInfo: TIdHTTPResponseInfo;
    FCS: TCriticalSection;
    FRPRegistrations: ISP<TRPRegistrations>;
    FLastHttpRequests: TLastHttpRequests;
    procedure ProcessRequest();
    function ParseFirstSection(): string;
    procedure DownloadFile;
  public
    constructor Create(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo; aLastHttpRequests: TLastHttpRequests);
    destructor Destroy; override;
    procedure Execute();
    property Context: TIdContext read FContext write FContext;
    property RequestInfo: TIdHTTPRequestInfo read FRequestInfo write FRequestInfo;
    property ResponseInfo: TIdHTTPResponseInfo read FResponseInfo write FResponseInfo;
  end;

implementation

uses
  uRPTests, uRPFiles, uRPSystem, uRSDecodePostRequest, System.SysUtils, DateUtils, uRSConst;

{ TCommandGet }

constructor TCommandGet.Create(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo; aLastHttpRequests: TLastHttpRequests);
begin
  FContext := AContext;
  FRequestInfo := ARequestInfo;
  FResponseInfo := AResponseInfo;
  FLastHttpRequests := aLastHttpRequests;

  FRPRegistrations := TSP<TRPRegistrations>.Create();

  FRPRegistrations.Assign(GlobalRPRegistrations);
  Execute();
end;

destructor TCommandGet.Destroy;
begin
  FRPRegistrations := nil;
  inherited;
end;

procedure TCommandGet.DownloadFile();
var
  f: ISP<TRPFiles>;
begin
  if FRPRegistrations.RPClasses.ContainsKey(RP_Files) then
  begin
    f := TSP<TRPFiles>.Create(TRPFiles.Create(FContext, FRequestInfo, FResponseInfo, true, FLastHttpRequests));
    f.Download();
  end;
end;

procedure TCommandGet.Execute();
var
  responses: ISP<TResponses>;
begin
  try
    ProcessRequest();
    DownloadFile();
    FResponseInfo.ResponseNo := 404;
  except
    on E: Exception do
    begin
      responses := TSP<TResponses>.Create(TResponses.Create(FRequestInfo, FResponseInfo));
      responses.Error(e.Message);
    end;
  end;
end;

function TCommandGet.ParseFirstSection(): string;
var
  a: TArray<string>;
begin
  Result := '';
  a := FRequestInfo.URI.Split(['/']);
  if Length(a) > 0 then
    Result := a[1]; // Parses Users from /Users/Add for example....
end;

procedure TCommandGet.ProcessRequest();
var
  rp: ISP<TRP>;
  firstSection: string;
  c: TClass;
  className: string;
begin
  firstSection := ParseFirstSection();
  if FRPRegistrations.RPClasses.ContainsKey(firstSection) then
  begin
    c := FRPRegistrations.RPClasses.GetValueOrDefault(firstSection);
    className := c.ClassName;
    rp := TSP<TRP>.Create(FRPRegistrations.RPClasses.GetValueOrDefault(firstSection).Create(FContext, FRequestInfo, FResponseInfo, FLastHttpRequests));
  end
end;

end.

