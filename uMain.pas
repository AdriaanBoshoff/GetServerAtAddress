unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, uDataModule, FMX.Edit, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.ListBox, FMX.Layouts,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, djson, FMX.ScrollBox,
  FMX.Memo, IniFiles, System.IOUtils;

type
  TfrmMain = class(TForm)
    pnlHead: TPanel;
    lbl1: TLabel;
    edtIP: TEdit;
    btnClearIP: TClearEditButton;
    btnGetServers: TButton;
    lstServers: TListBox;
    statBottom: TStatusBar;
    lblTotalServers: TLabel;
    lblVersion: TLabel;
    procedure GetServers(IP: string);
    procedure btnGetServersClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SaveSettingString(Section, Name, Value, SettingsFile: string);
    function LoadSettingString(Section, Name, Value, SettingsFile: string): string;
    procedure edtIPKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    { Private declarations }
    Android_Settings_File: string;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

const
  API_URL = 'http://api.steampowered.com/ISteamApps/GetServersAtAddress/v1?addr=';
  Other_Settings_File = '.\config.ini';

implementation

{$R *.fmx}

procedure TfrmMain.btnGetServersClick(Sender: TObject);
begin
  {$IFDEF Android}
  SaveSettingString('IP', 'ip', edtIP.Text, Android_Settings_File);
  {$ENDIF}
  {$IFDEF MSWindows}
  SaveSettingString('IP', 'ip', edtIP.Text, Other_Settings_File);
  {$ENDIF}

  GetServers(edtIP.Text);
end;

procedure TfrmMain.edtIPKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    {$IFDEF Android}
    SaveSettingString('IP', 'ip', edtIP.Text, Android_Settings_File);
    {$ENDIF}
    {$IFDEF MSWindows}
    SaveSettingString('IP', 'ip', edtIP.Text, Other_Settings_File);
    {$ENDIF}

    GetServers(edtIP.Text);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Application.Title := 'GSAA';
  Android_Settings_File := System.IOUtils.TPath.GetDocumentsPath + System.SysUtils.PathDelim + 'getserversettings.ini';
  {$IFDEF Android}
  edtIP.Text := LoadSettingString('IP', 'ip', edtIP.Text, Android_Settings_File);
  {$ENDIF}
  {$IFDEF MSWindows}
  edtIP.Text := LoadSettingString('IP', 'ip', edtIP.Text, Other_Settings_File);
  {$ENDIF}
end;

procedure TfrmMain.GetServers(IP: string);
var
  ListBoxItem: TListBoxItem;
  httpclient: TIdHTTP;
  data, sregion: string;
  serverinfo, server: TJSON;
begin
  // Clear Server List
  lstServers.Clear;

  // Retrieve the json data via api
  httpclient := TIdHTTP.Create(Self);
  try
    data := httpclient.Get(API_URL + IP);
    httpclient.Free;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      httpclient.Free;
      Exit;
    end;
  end;

  // Parse the Data
  serverinfo := TJSON.Parse(data);
  try
    // Check if IP is valid
    if not serverinfo['response']['success'].AsBoolean then
    begin
      ShowMessage('There has been an error. Is your IP valid?' + sLineBreak + sLineBreak + 'ERROR: ' + serverinfo['response']['message'].AsString);
      Exit;
    end;

    // Start the loop to add each server
    for server in serverinfo['response']['servers'] do
    begin
      // Set the region
      case server['region'].AsInteger of
        -1:
          sregion := 'UNKNOWN';
        0:
          sregion := 'US - East';
        1:
          sregion := 'US - West';
        2:
          sregion := 'South America';
        3:
          sregion := 'Europe';
        4:
          sregion := 'Asia';
        5:
          sregion := 'Australia';
        6:
          sregion := 'Middle East';
        7:
          sregion := 'Africa';
        255:
          sregion := 'UNKNOWN';
      end;

      // Add the Items
      ListBoxItem := TListBoxItem.Create(lstServers);
      // Image will be loaded if it exists
      if FileExists('.\images\' + server['gamedir'].AsString + '.png') then
        ListBoxItem.ItemData.Bitmap.LoadFromFile('.\images\' + server['gamedir'].AsString + '.png');

      ListBoxItem.ItemData.Text := UpperCase(server['gamedir'].AsString) + ' on ' + server['addr'].AsString;
      ListBoxItem.ItemData.Detail := 'Region: ' + sregion + '   Secure: ' + server['secure'].AsString + '   AppID: ' + server['appid'].AsString;
      lstServers.AddObject(ListBoxItem);
    end;
  finally
    lblTotalServers.Text := 'Total Servers: ' + IntToStr(lstServers.Count);
    serverinfo.Free;
  end;
end;

function TfrmMain.LoadSettingString(Section, Name, Value, SettingsFile: string): string;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(SettingsFile);
  try
    Result := ini.ReadString(Section, Name, Value);
  finally
    ini.Free;
  end;
end;

procedure TfrmMain.SaveSettingString(Section, Name, Value, SettingsFile: string);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(SettingsFile);
  try
    ini.WriteString(Section, Name, Value);
  finally
    ini.Free;
  end;
end;

end.

