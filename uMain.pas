unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdHTTPServer, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, uRSCommandGet, IdTCPConnection, IdTCPClient, IdCustomHTTPServer, IdContext, Vcl.Samples.Spin,
  System.ImageList, Vcl.ImgList, uRSCommon, System.Classes, superobject, IdHeaderList, ShellApi, Registry, uRSConst, System.SyncObjs, IdServerIOHandler, IdSSL, IdSSLOpenSSL,
  Vcl.AppEvnts, Vcl.Menus,
  //
  uPSClasses, //
  uRPRegistrations, //
  uRSMainModule, //
  uRSGui, //
  uRP, //
  uRPTests, //
  uRPFiles, //
  uRPSystem //
;

type
  TMain = class(TForm)
    procedure pNormalWindowClick(Sender: TObject);
  private
    FRSGui: TRSGui;
    FRSMainModule: TRSMainModule;
    procedure RegisterRPClasses;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Main: TMain;

implementation
{$R *.dfm}

uses
  System.NetEncoding, IdMultipartFormData, uClientExamples, System.Math, System.IOUtils, System.IniFiles, uRSService;

{ TMain }
constructor TMain.Create(AOwner: TComponent);
begin
  inherited;
  ReportMemoryLeaksOnShutdown := True;
  GlobalRPRegistrations := TRPRegistrations.Create;
  RegisterRPClasses();
  FRSMainModule := TRSMainModule.Create(Self, True);
  FRSGui := TRSGui.Create(Self, RSMainModule);
  FRSGui.Parent := Self;
  FRSGui.Align := alClient;
  FRSGui.Show();
end;

destructor TMain.Destroy;
begin
  GlobalRPRegistrations.Free();
  inherited;
end;

procedure TMain.RegisterRPClasses;
begin
  GlobalRPRegistrations.RegisterRPClass(TRPTests, RP_Tests);
  GlobalRPRegistrations.RegisterRPClass(TRPFiles, RP_Files);
  GlobalRPRegistrations.RegisterRPClass(TRPSystem, RP_System);
end;

procedure TMain.pNormalWindowClick(Sender: TObject);
begin
  Self.WindowState := wsNormal;
end;

end.

