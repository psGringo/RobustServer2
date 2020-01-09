unit uStartApp;

interface

uses
  Vcl.Forms, Vcl.SvcMgr, uMain, uRSCommandGet, Vcl.Themes, Vcl.Styles, uRSTimers, uRSMemory, uRSCommon, uRSDecodePostRequest, uUniqueName, uRP, uRPTests, uRPFiles, uRSService,
  Winapi.Windows, uRPSystem, System.SysUtils, uRSMainModule, uRPRegistrations, uRSGui, uRSLastHttpRequests, uRSConst, uRSSettingsFile, IniFIles, uPSClasses;

procedure StartApp();

implementation

procedure StartApp();
var
  ini: ISP<TIniFile>;
  startupType: string;
  isVisible: Boolean;
  pathToSettings: string;
begin
  pathToSettings := Format('%s%s', [ExtractFilePath(Vcl.Forms.Application.ExeName), SETTINGS_FILE_NAME]);
  ini := TSP<Tinifile>.Create(Tinifile.Create(pathToSettings));
  startupType := ini.ReadString('startup', 'type', '<None>');
  isVisible := ini.ReadBool('startup', 'isVisible', true);

  if startupType = 'exe' then
  begin
    Vcl.Forms.Application.Initialize;
    Vcl.Forms.Application.MainFormOnTaskbar := True;
    TStyleManager.TrySetStyle('Light');
    Vcl.Forms.Application.ShowMainForm := isVisible;
    Vcl.Forms.Application.CreateForm(TMain, Main);
    Vcl.Forms.Application.Run;
  end
  else if startupType = 'service' then
  begin
    if not Vcl.SvcMgr.Application.DelayInitialize or Vcl.SvcMgr.Application.Installing then
      Vcl.SvcMgr.Application.Initialize;
    Vcl.SvcMgr.Application.CreateForm(TRobustService, RobustService);
    Application.Run;
  end;
end;

end.

