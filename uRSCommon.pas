unit uRSCommon;

interface

uses
  LDSLogger, uRSConst, System.SysUtils, System.Classes, IdCustomHTTPServer, superobject, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdMessage,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP, IdMessageCoderMIME, IdMessageCoder, IdGlobal,
  HTTPApp, vcl.Forms, System.NetEncoding, IdException, Winapi.Windows, uPSClasses, uRSMainModule, idHTTP;

type
  TEmail = class(TInterfacedObject)
    procedure Send(aHost: string; aPort: int; aSubject, aEmailContent, aRecipientEmail, aMyEmail, aMyPassword, aFromName: string); overload;
    procedure Send(aSenderEmail, aSenderName, aSubject, aContent, aRecipientEmail: string); overload;
  end;

  TLogger = class
    procedure LogError(aMsg: string);
    procedure LogInfo(aMsg: string);
  end;

  TResponses = class(TInterfacedObject)
  private
    FAResponseInfo: TIdHTTPResponseInfo;
    FARequestInfo: TIdHTTPRequestInfo;
    FTimeCounterFinish: TLargeInteger;
    FTimeCounterStart: TLargeInteger;
    FICounterPerSec: TLargeInteger;
    function GetCommandType(): string;
    function FormatExecutionTime: string;
  public
    constructor Create(aRequestInfo: TIdHTTPRequestInfo; aResponseInfo: TIdHTTPResponseInfo);
    procedure OK();
    procedure OkWithJson(aJsonData: string);
    procedure Error(EMessage: string = ''; ACodeNumber: integer = -1);
    procedure Deactivate();
    property ARequestInfo: TIdHTTPRequestInfo read FARequestInfo write FARequestInfo;
    property AResponseInfo: TIdHTTPResponseInfo read FAResponseInfo write FAResponseInfo;
    property TimeCounterStart: TLargeInteger read FTimeCounterStart write FTimeCounterStart;
    property TimeCounterFinish: TLargeInteger read FTimeCounterFinish write FTimeCounterFinish;
    property ICounterPerSec: TLargeInteger read FICounterPerSec write FICounterPerSec;
  end;

  TCommon = class
  public
    procedure DecodeFormDataRemy(ARequestInfo: TIdHTTPRequestInfo);
    {< method from Remy, doesn't work...}
    procedure IsNotNull(aObject: TObject);
  end;

  TNotifyLongTask = procedure(aProgress: double = 0.00; aMsg: string = '') of object;

  TNotifyLongTaskException = procedure(aObject: TObject; aEClass: string; aMsg: string) of object;

  TLongTaskThread = class(TThread)
  private
    FProgress: double;
    FGuid: string;
    FProc: TProc;
    FOnStart: TNotifyLongTask;
    FOnProgress: TNotifyLongTask;
    FOnFinish: TNotifyLongTask;
    FOnException: TNotifyLongTaskException;
  protected
    procedure Execute(); override;
  public
    constructor Create(aProc: TProc);
    function IsTerminated: Boolean;
    property Progress: double read FProgress write FProgress;
    property GuiId: string read FGuid;
    property OnStart: TNotifyLongTask read FOnStart write FOnStart;
    property OnProgress: TNotifyLongTask read FOnProgress write FOnProgress;
    property OnFinish: TNotifyLongTask read FOnFinish write FOnFinish;
    property OnException: TNotifyLongTaskException read FOnException write FOnException;
  end;

  THTTPAttributes = class(TCustomAttribute)
    FCommandType: string;
    constructor Create(aCommandType: string); overload;
    property CommandType: string read FCommandType;
  end;

implementation

uses
  uMain, uRSService;
{ TLDSLoggerImpl }

//Creates a mutex to see if the program is already running.

function IsSingleInstance(MutexName: string; KeepMutex: boolean = true): boolean;
const
  MUTEX_GLOBAL = 'Global\'; //Prefix to explicitly create the object in the global or session namespace. I.e. both client app (local user) and service (system account)
var
  MutexHandle: THandle;
  SecurityDesc: TSecurityDescriptor;
  SecurityAttr: TSecurityAttributes;
  ErrCode: integer;
begin
    // By default (lpMutexAttributes =nil) created mutexes are accessible only by
    // the user running the process. We need our mutexes to be accessible to all
    // users, so that the mutex detection can work across user sessions.
    // I.e. both the current user account and the System (Service) account.
    // To do this we use a security descriptor with a null DACL.
  InitializeSecurityDescriptor(@SecurityDesc, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@SecurityDesc, True, nil, False);
  SecurityAttr.nLength := SizeOf(SecurityAttr);
  SecurityAttr.lpSecurityDescriptor := @SecurityDesc;
  SecurityAttr.bInheritHandle := False;

    // The mutex is created in the global name space which makes it possible to
    // access across user sessions.

  MutexHandle := CreateMutex(@SecurityAttr, True, PChar(MUTEX_GLOBAL + MutexName));
  ErrCode := GetLastError;
    // If the function fails, the return value is 0
    // If the mutex is a named mutex and the object existed before this function
    // call, the return value is a handle to the existing object, GetLastError
    // returns ERROR_ALREADY_EXISTS.
  if (MutexHandle = 0) or (ErrCode = ERROR_ALREADY_EXISTS) then
  begin
    result := false;
    closeHandle(MutexHandle);
  end
  else
  begin
    // Mutex object has not yet been created, meaning that no previous
    // instance has been created.
    result := true;

    if not KeepMutex then
      CloseHandle(MutexHandle);
  end;
    // The Mutexhandle is not closed because we want it to exist during the
    // lifetime of the application. The system closes the handle automatically
    //when the process terminates.
end;

procedure TLogger.LogError(aMsg: string);
var
  l: ISP<TLDSLogger>;
begin
  l := TSP<TLDSLogger>.Create(TLDSLogger.Create(LOG_FILE_NAME));
  l.LogStr(aMsg, tlpError);
end;

procedure TLogger.LogInfo(aMsg: string);
var
  l: ISP<TLDSLogger>;
begin
  l := TSP<TLDSLogger>.Create(TLDSLogger.Create(LOG_FILE_NAME));
  l.LogStr(aMsg, tlpInformation);
end;


{ TEmail }
procedure TEmail.Send(aHost: string; aPort: int; aSubject, aEmailContent, aRecipientEmail, aMyEmail, aMyPassword, aFromName: string);
var
  idSMTP: ISP<TIdSMTP>;
  msg: ISP<TIdMessage>;
  sslOpen: ISP<TIdSSLIOHandlerSocketOpenSSL>;
begin
  idSMTP := TSP<TIdSMTP>.Create(TIdSMTP.Create(nil));
  msg := TSP<TIdMessage>.Create(TIdMessage.Create(nil));
  sslOpen := TSP<TIdSSLIOHandlerSocketOpenSSL>.Create(TIdSSLIOHandlerSocketOpenSSL.Create(nil));

  idSMTP.Host := aHost;
  idSMTP.Port := aPort;
  idSMTP.AuthType := satDefault;
  idSMTP.Username := aMyEmail;
  idSMTP.Password := aMyPassword;
  //for SSL
  //  SSLOpen := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  sslOpen.Destination := idSMTP.Host + ':' + IntToStr(idSMTP.Port);
  sslOpen.Host := idSMTP.Host;
  sslOpen.Port := idSMTP.Port;
  sslOpen.DefaultPort := 0;
  sslOpen.SSLOptions.Method := sslvSSLv23;
  sslOpen.SSLOptions.Mode := sslmUnassigned;

  idSMTP.IOHandler := sslOpen;
  idSMTP.UseTLS := utUseImplicitTLS;

  msg.ContentType := 'text/html; charset=windows-1251';
  msg.Body.Text := aEmailContent;
  msg.Subject := aSubject;
  msg.From.Address := aMyEmail; // 'shop.bel-ozero@yandex.ru';
  msg.From.Name := aFromName;
  msg.Recipients.EMailAddresses := aRecipientEmail;

  try
    idSMTP.Connect;
    idSMTP.Send(msg);
  except
    on E: Exception do
    begin
      raise Exception.Create('Error Message ' + e.Message);
      idSMTP.Disconnect();
    end;
  end;
end;

procedure TCommon.DecodeFormDataRemy(ARequestInfo: TIdHTTPRequestInfo);
var
  msgEnd: Boolean;
  decoder: TIdMessageDecoder;
  tmp: string;
  dest: TStream;
  headers: ISP<TStringList>;
  boundary: string;
  ss: TStringStream;
begin
  msgEnd := False;
  decoder := TIdMessageDecoderMIME.Create(nil);
  try
    headers := TSP<TStringList>.Create();
    ExtractHeaderFields([';'], [' '], PChar(ARequestInfo.ContentType), headers, false, false);
    boundary := headers.Values['boundary'];
    TIdMessageDecoderMIME(decoder).MIMEBoundary := boundary;  //TIdMIMEBoundary.  FindBoundary(Header);

    decoder.SourceStream := ARequestInfo.PostStream;
    decoder.FreeSourceStream := False;
    decoder.ReadLn;

    repeat
      decoder.ReadHeader;
      //decoder.ReadLn;
      case decoder.PartType of
      //mcptUnknown:
      //    raise Exception('Unknown form data detected');
        mcptText:
          begin
            tmp := decoder.Headers.Values['Content-Type'];
            ss := TStringStream.Create();
            try
              decoder := decoder.ReadBody(ss, msgEnd);

                            {
              if AnsiSameText(Fetch(tmp, ';'), 'multipart/mixed') then
                DecodeFormData(ARequestInfo,tmp, dest)
              else
              }
                // use Dest as needed...
              begin


                //  ss.Free();
              end;
            finally
              FreeAndNil(ss);
            end;
          end;
        mcptAttachment:
          begin
            tmp := ExtractFileName(decoder.FileName);
            if tmp <> '' then
              tmp := ExtractFileDir(Application.ExeName) + '\files\' + tmp; //'c:\some folder\" + Tmp';
            //else
            //Tmp := MakeTempFilename("c:\somefolder\");
            dest := TFileStream.Create(tmp, fmCreate);
            try
              decoder := decoder.ReadBody(dest, msgEnd);
            finally
              FreeAndNil(dest);
            end;
          end;
      end;
    until (decoder = nil) or msgEnd;
  finally
    FreeAndNil(decoder);
  end;
end;


    { // example of use...
    begin

        S := ARequestInfo.Headers.Values['Content-Type'];
        if AnsiSameText(Fetch(S, ';'), 'multipart/form-data') then
            DecodeFormData(S, ARequestInfo.PostStream)
        else
            // use request data as needed...

    end;
    }

procedure TEmail.Send(aSenderEmail, aSenderName, aSubject, aContent, aRecipientEmail: string);
var
  client: ISP<TIdHTTP>;
  ss: ISP<TStringStream>;
  joRequest, joResponse: ISuperobject;
begin
  client := TSP<TIdHTTP>.Create();
  ss := TSP<TStringStream>.Create();

  joRequest := SO();

  joRequest.S['senderEmail'] := aSenderEmail;
  joRequest.S['subject'] := aSubject;
  joRequest.S['content'] := aContent;
  joRequest.S['recipientEmail'] := aRecipientEmail;
  joRequest.S['fromName'] := aSenderName;

  ss.WriteString(joRequest.AsJSon(false, false));
  client.Request.ContentType := 'application/json';
  client.Request.ContentEncoding := 'utf-8';
  joResponse := SO(client.Post(TRSMainModule.GetInstance.Adress + '/Email/Send', ss));

  if joResponse.S['answer'] <> 'ok' then
    raise Exception.Create(joResponse.S['errorMessage']);
end;

{ TResponses }

constructor TResponses.Create(aRequestInfo: TIdHTTPRequestInfo; aResponseInfo: TIdHTTPResponseInfo);
begin
  FAResponseInfo := aResponseInfo;
  FARequestInfo := aRequestInfo;
end;

procedure TResponses.Deactivate();
begin
  try
    TRSMainModule.GetInstance.Server.Active := false;
  except
    on E: EIdException do
      Error(E.Message);
    on E: Exception do
      Error(E.Message);
  end;
end;

procedure TResponses.Error(EMessage: string = ''; ACodeNumber: integer = -1);
var
  json: ISuperObject;
begin
  json := SO;
  json.S['answer'] := 'not ok';
  json.S['errorCode'] := ACodeNumber.ToString();
  json.S['errorMessage'] := EMessage;
  json.S['uri'] := ARequestInfo.URI;
  json.S['responseNo'] := aResponseInfo.ResponseNo.ToString();
  json.S['commandType'] := GetCommandType();
  json.S['executionTime'] := FormatExecutionTime();
  FaResponseInfo.ResponseNo := 200;
  FAResponseInfo.ContentType := 'application/json; charset=utf-8';
  FaResponseInfo.CacheControl := 'no-cache';
  FaResponseInfo.CustomHeaders.Add('Access-Control-Allow-Origin: *');
  FaResponseInfo.ContentText := json.AsJSon(false, false);
  FaResponseInfo.WriteContent;
end;

function TResponses.GetCommandType: string;
begin
  if (ARequestInfo.CommandType = hcGet) then
    Result := 'GET'
  else if (ARequestInfo.CommandType = hcPOST) then
    Result := 'POST'
  else
    Result := 'Other';
end;

procedure TResponses.OK();
var
  json: ISuperObject;
begin
  json := SO;
  json.S['answer'] := 'ok';
  json.S['uri'] := ARequestInfo.URI;
  json.S['commandType'] := GetCommandType();
  json.S['executionTime'] := FormatExecutionTime();
  FaResponseInfo.ResponseNo := 200;
  FAResponseInfo.ContentType := 'application/json; charset=utf-8';
  FaResponseInfo.CacheControl := 'no-cache';
  FaResponseInfo.CustomHeaders.Add('Access-Control-Allow-Origin: *');
  FaResponseInfo.ContentText := json.AsJSon(false, false);
  FaResponseInfo.WriteContent;
end;

procedure TResponses.OkWithJson(aJsonData: string);
var
  json, jsonResult: ISuperobject;
begin
  json := SO(aJsonData);
  jsonResult := SO();
  jsonResult.S['answer'] := 'ok';
  jsonResult.S['uri'] := ARequestInfo.URI;
  jsonResult.O['data'] := json;
  jsonResult.S['commandType'] := GetCommandType();
  jsonResult.S['executionTime'] := FormatExecutionTime();

  FAResponseInfo.ResponseNo := 200;
  FAResponseInfo.ContentType := 'application/json; charset=utf-8';
  FAResponseInfo.CacheControl := 'no-cache';
  FAResponseInfo.CustomHeaders.Add('Access-Control-Allow-Origin: *');
  FAResponseInfo.ContentText := jsonResult.AsJSon(false, false);
  FAResponseInfo.WriteContent;
end;

function TResponses.FormatExecutionTime: string;
begin
  Result := '0.0000000';
  QueryPerformanceCounter(FTimeCounterFinish);
  if FICounterPerSec <> 0 then
    Result := FormatFloat('0.0000000', (FTimeCounterFinish - FTimeCounterStart) / (FICounterPerSec)) + ' sec.';
end;

procedure TCommon.IsNotNull(aObject: TObject);
begin
  if (aObject = nil) then
    raise Exception.Create('Object is nil');
end;

{ TLongTaskThread }

constructor TLongTaskThread.Create(aProc: TProc);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  FProc := aProc;
  FGuid := TGuid.NewGuid.ToString();
end;

procedure TLongTaskThread.Execute;
begin
  inherited;
  try
    if not Terminated then
      FProc();
  except
    on E: Exception do
      if Assigned(OnException) then
        OnException(Self, E.ClassName, E.Message);
  end;
end;

function TLongTaskThread.IsTerminated: Boolean;
begin
  Result := Terminated;
end;

{ THTTPAttributes }

constructor THTTPAttributes.Create(aCommandType: string);
begin
  FCommandType := aCommandType;
end;

end.

