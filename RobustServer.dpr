program RobustServer;

uses
  Vcl.Forms,
  Vcl.SvcMgr,
  uMain in 'uMain.pas' {Main},
  uRSCommandGet in 'uRSCommandGet.pas',
  Vcl.Themes,
  Vcl.Styles,
  uRSTimers in 'uRSTimers.pas' {Timers: TDataModule},
  uRSMemory in 'uRSMemory.pas',
  uRSCommon in 'uRSCommon.pas',
  uRSDecodePostRequest in 'uRSDecodePostRequest.pas',
  uUniqueName in 'uUniqueName.pas',
  uRP in 'RP\uRP.pas',
  uRPTests in 'RP\uRPTests.pas',
  uRPFiles in 'RP\uRPFiles.pas',
  uRSService in 'uRSService.pas' {RobustService},
  Winapi.Windows {MainService: TDataModule},
  uRPSystem in 'RP\uRPSystem.pas',
  System.SysUtils,
  uRSMainModule in 'uRSMainModule.pas' {RSMainModule: TDataModule},
  uRPRegistrations in 'RP\uRPRegistrations.pas',
  uRSGui in 'uRSGui.pas' {RSGui: TFrame},
  uRSLastHttpRequests in 'uRSLastHttpRequests.pas',
  uRSConst in 'uRSConst.pas',
  uRSSettingsFile in 'uRSSettingsFile.pas',
  IniFIles,
  uPSClasses,
  uStartApp in 'uStartApp.pas';

{$R *.res}

begin
  StartApp();
end.

