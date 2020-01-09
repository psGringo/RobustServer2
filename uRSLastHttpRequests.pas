unit uRSLastHttpRequests;

interface

uses
  System.SysUtils, System.Classes, IniFiles, System.IOUtils, uPSClasses, superobject;

type
  TLastHttpRequests = class
  private
    FMaxCountRequests: integer;
    FData: TStringList;
    FFilePath: string;
    procedure KeepNoMoreCountRecords(aCount: integer);
    procedure Load();
    procedure Save();
  public
    constructor Create(aFilePathSettings: string);
    destructor Destroy; override;
    procedure AddToFirstPosition(aRequest: string);
    procedure Delete(aRequest: string);
    property Data: TStringList read FData;
  end;

implementation

{ TLastHttpRequests }

procedure TLastHttpRequests.AddToFirstPosition(aRequest: string);
var
  currentIndex: integer;
  isRequestFound: Boolean;
begin
  KeepNoMoreCountRecords(FMaxCountRequests);
  aRequest := Trim(aRequest);

  currentIndex := FData.IndexOf(aRequest);
  isRequestFound := currentIndex <> -1;

  if (isRequestFound) then
    FData.Exchange(currentIndex, 0)
  else
    FData.Insert(0, aRequest);
end;

constructor TLastHttpRequests.Create(aFilePathSettings: string);
begin
  FMaxCountRequests := 10;

  if not TFile.Exists(aFilePathSettings) then
    raise Exception.Create(Format('no file %s', [aFilePathSettings]));

  FFilePath := aFilePathSettings;

  FData := TStringList.Create();
  Load();

  if FData.Count = 0 then
    FData.Add('Tests/Connection');
end;

procedure TLastHttpRequests.Delete(aRequest: string);
var
  currentIndex: integer;
  ini: ISP<TIniFile>;
  sectionName: string;
begin
  currentIndex := FData.IndexOf(aRequest);
  if currentIndex = -1 then
    Exit;

  FData.Delete(currentIndex);

  // delete from ini
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFilePath));
  sectionName := Format('lastRequest%s', [currentIndex.ToString()]);
  ini.DeleteKey('lastRequests', sectionName);
end;

destructor TLastHttpRequests.Destroy;
begin
  Save();
  FData.Free();
  inherited;
end;

procedure TLastHttpRequests.KeepNoMoreCountRecords(aCount: integer);
var
  diff: integer;
  i: integer;
begin
  diff := FData.Count - aCount;
  if diff > 0 then
  begin
    for i := aCount to FData.Count - 1 do
      FData.Delete(i);
  end;
end;

procedure TLastHttpRequests.Load();
var
  ini: ISP<TIniFile>;
  i: integer;
  sectionName: string;
  item: string;
  notFound: string;
begin
  ini := TSP<Tinifile>.Create(Tinifile.Create(FFilePath));

  i := 0;
  notFound := 'not found';

  while item <> notFound do
  begin
    sectionName := Format('lastRequest%s', [i.ToString()]);
    item := ini.ReadString('lastRequests', sectionName, notFound);
    if item <> notFound then
      FData.Add(item);
    Inc(i);
  end;
end;

procedure TLastHttpRequests.Save;
var
  ini: ISP<TIniFile>;
  i: integer;
  sectionName: string;
begin
  KeepNoMoreCountRecords(FMaxCountRequests);

  ini := TSP<Tinifile>.Create(Tinifile.Create(FFilePath));

  for i := 0 to FData.Count - 1 do
  begin
    sectionName := Format('lastRequest%s', [i.ToString()]);
    ini.WriteString('lastRequests', sectionName, FData[i]);
  end;
end;

end.

