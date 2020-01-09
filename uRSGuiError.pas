unit uRSGuiError;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.Menus, Vcl.Buttons, System.NetEncoding, ShellApi, Vcl.AppEvnts;

type
  TFrame1 = class(TFrame)
    pAnswers: TPanel;
    pAnswerTop: TPanel;
    bClearAnswers: TBitBtn;
    mAnswer: TMemo;
    PopupMenu: TPopupMenu;
    pNormalWindow: TMenuItem;
    pExit: TMenuItem;
    pPost: TPanel;
    pPostParamsTop: TPanel;
    cbPostType: TComboBox;
    mPostParams: TMemo;
    pRequest: TPanel;
    cbRequest: TComboBoxEx;
    bGo: TBitBtn;
    pTop: TPanel;
    bStartStop: TBitBtn;
    bAPI: TBitBtn;
    bLog: TBitBtn;
    cbRequestType: TComboBox;
    bSettings: TBitBtn;
    pUrlEncode: TPanel;
    bDoUrlEncode: TBitBtn;
    eUrlEncodeValue: TEdit;
    StatusBar: TStatusBar;
    TrayIcon: TTrayIcon;
    ApplicationEvents: TApplicationEvents;
    procedure bClearAnswersClick(Sender: TObject);
    procedure bDoUrlEncodeClick(Sender: TObject);
    procedure bLogClick(Sender: TObject);
    procedure bSettingsClick(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure cbRequestTypeSelect(Sender: TObject);
    procedure cbPostTypeSelect(Sender: TObject);
    procedure bGoClick(Sender: TObject);
    procedure bStartStopClick(Sender: TObject);
    procedure bAPIClick(Sender: TObject);
    procedure cbRequestKeyPress(Sender: TObject; var Key: Char);
    procedure ApplicationEventsMinimize(Sender: TObject);
  private
    procedure UpdateWorkTime(var aMsg: TMessage); message WM_WORK_TIME;
    procedure UpdateAppMemory(var aMsg: TMessage); message WM_APP_MEMORY;
  public
  end;

implementation

{$R *.dfm}

procedure TFrame1.ApplicationEventsMinimize(Sender: TObject);
begin
  TrayIcon.Visible := True;
  Application.ShowMainForm := True;
  ShowWindow(Handle, SW_HIDE);
end;

procedure TFrame1.bAPIClick(Sender: TObject);
var
  c: ISP<TIdHTTP>;
begin
//  c := TSP<TIdHTTP>.Create();
//  c.Get(FAdress + '/System/Api');
//  ShellExecute(Handle, 'open', 'c:\windows\notepad.exe', PWideChar(ExtractFilePath(Application.ExeName) + 'api.txt'), nil, SW_SHOWNORMAL);
end;

procedure TFrame1.bClearAnswersClick(Sender: TObject);
begin
  mAnswer.Lines.Clear();
end;

procedure TFrame1.bDoUrlEncodeClick(Sender: TObject);
begin
  eUrlEncodeValue.Text := System.NetEncoding.TNetEncoding.URL.Encode(eUrlEncodeValue.Text);
end;

procedure TFrame1.bGoClick(Sender: TObject);
begin
//  case cbRequestType.ItemIndex of
//    0:
//      GetRequestProcessing();
//    1:
//      PostRequestProcessing();
//  end;
end;

procedure TFrame1.bLogClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'c:\windows\notepad.exe', PWideChar(ExtractFilePath(Application.ExeName) + 'log.txt'), nil, SW_SHOWNORMAL);
end;

procedure TFrame1.bSettingsClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'c:\windows\notepad.exe', PWideChar(ExtractFilePath(Application.ExeName) + 'settings.ini'), nil, SW_SHOWNORMAL);
end;

procedure TFrame1.bStartStopClick(Sender: TObject);
begin
//  SwitchStartStopButtons();
end;

procedure TFrame1.cbPostTypeSelect(Sender: TObject);
begin
  mPostParams.Clear();
  mPostParams.Lines.BeginUpdate;
  case cbPostType.ItemIndex of
    0:
      begin
        //cmbRequest.Text := 'Test/PostJson';
        mPostParams.Text := '{ "name":"Stas", "age":35 }';
      end;
    1:
      begin
        //cmbRequest.Text := 'Test/URLEncoded';
        mPostParams.Lines.Add('PostParam1 = URLEncoded(PostParam1Value)');
        mPostParams.Lines.Add('PostParam2 = URLEncoded(PostParam2Value)');
      end;
    2:
      begin
        cbRequest.Text := 'Files/Upload';
        mPostParams.Lines.Add(ExtractFilePath(Application.ExeName) + 'testFile.php');
        mPostParams.Lines.Add('false');
      end;
  end;
  mPostParams.Lines.EndUpdate;
end;

procedure TFrame1.cbRequestKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    bGoClick(Self);
end;

procedure TFrame1.cbRequestTypeSelect(Sender: TObject);
begin
  case cbRequestType.ItemIndex of
    0:
      cbRequest.Text := 'Test/Connection';
    1:
      cbPostTypeSelect(nil);
  end;
end;

procedure TFrame1.TrayIconDblClick(Sender: TObject);
begin
  TrayIcon.Visible := False;
  Show();
//  WindowState := wsNormal;
  Application.BringToFront()
end;

procedure TFrame1.UpdateAppMemory(var aMsg: TMessage);
begin
  StatusBar.Panels[2].Text := PChar(aMsg.LParam);
end;

procedure TFrame1.UpdateWorkTime(var aMsg: TMessage);
begin
  StatusBar.Panels[1].Text := PChar(aMsg.LParam);
end;

procedure TFrame1.UpdateStartStopGlyph(aBitmapIndex: integer);
begin
  bStartStop.Glyph := nil;
//  ilPics.GetBitmap(aBitmapIndex, bStartStop.Glyph);
end;

end.

