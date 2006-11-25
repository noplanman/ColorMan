unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, dxCore, dxButtons, Buttons, Clipbrd,
  ImgList, Menus, Spin, ShellApi, CoolTrayIcon, TextTrayIcon, jpeg,
  JvExControls, JvComponent, JvArrowButton;

const
  validChars: array[0..16] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', #8);
  IC_CLICK = WM_APP + 201;

type
  TMainForm = class(TForm)
    editHex: TEdit;
    timerColor: TTimer;
    imgZoom: TImage;
    pnlForm: TPanel;
    imgList: TImageList;
    pnlColor: TPanel;
    editRed: TSpinEdit;
    editGreen: TSpinEdit;
    editBlue: TSpinEdit;
    btnMinimize: TSpeedButton;
    btnClose: TSpeedButton;
    popupCopy: TPopupMenu;
    popupCopyHex: TMenuItem;
    popupCopyRGB: TMenuItem;
    btnSettings: TSpeedButton;
    popupSettings: TPopupMenu;
    popupSettingsStartMinimized: TMenuItem;
    trayIcon: TTextTrayIcon;
    popupTrayIcon: TPopupMenu;
    popupTrayIconExit: TMenuItem;
    popupTrayIconShowHide: TMenuItem;
    popupSettingsZoomFactor: TMenuItem;
    popupSettingsZoomFactor1: TMenuItem;
    popupSettingsZoomFactor2: TMenuItem;
    popupSettingsZoomFactor3: TMenuItem;
    popupSettingsZoomFactor4: TMenuItem;
    popupSettingsZoomFactor5: TMenuItem;
    popupSettingsInfo: TMenuItem;
    imgTopBar: TImage;
    imgBG: TImage;
    pnlZoom: TPanel;
    tmrFade: TTimer;
    btnCopy: TJvArrowButton;
    procedure timerColorTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure imgColorMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgColorMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure popupCopyHexClick(Sender: TObject);
    procedure popupCopyRGBClick(Sender: TObject);
    procedure setColors(Sender: TObject);
    procedure btnMinimizeClick(Sender: TObject);
    procedure popupSettingsStartMinimizedClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure popupTrayIconExitClick(Sender: TObject);
    procedure popupTrayIconShowHideClick(Sender: TObject);
    procedure setZoomFactor(Sender: TObject);
    procedure imgTopBarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure trayIconClick(Sender: TObject);
    procedure popupSettingsInfoClick(Sender: TObject);
    procedure tmrFadeTimer(Sender: TObject);
    procedure trayIconStartup(Sender: TObject; var ShowMainForm: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure editHexKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    procedure loadSettings;
    procedure FadeForm(Action:String);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  filePath: String;
  mHandle:THandle;
  FadeAction:String;
  FadeSpeed:Integer;

implementation
uses Math, StrUtils, ini, globalDefinitions, functions, info;


{$R *.dfm}


procedure delay(msecs:Cardinal);
var
  FirstTickCount:Cardinal;
begin
  FirstTickCount := GetTickCount;
  repeat
    Application.ProcessMessages; {allowing access to other controls, etc.}
  until ((GetTickCount-FirstTickCount) >= msecs);
end;

procedure TMainForm.loadSettings;
begin
  // get filepath of file
  filePath := ExtractFilePath(ParamStr(0));
  if FileExists(filePath + iniFileName) then
  begin
    // StartMinimized
    startMinimized := ini.getBool('Settings','StartMinimized',startMinimized);
    popupSettingsStartMinimized.Checked := startMinimized;

    if not StartMinimized then
      FadeForm('show')
    else
      AlphaBlendValue := 0;

    // ZoomFactor
    zoomFactor := ini.getInteger('Settings','ZoomFactor',4);
    if zoomFactor > 5 then zoomFactor := 5 else if zoomFactor < 1 then zoomFactor := 1;
    setInteger('Settings','ZoomFactor',zoomFactor);
    (FindComponent('popupSettingsZoomFactor'+IntToStr(zoomFactor)) as TMenuItem).Checked := True;
  end
  else
  begin
    setBool('Settings','StartMinimized',startMinimized);
    setInteger('Settings','ZoomFactor',zoomFactor);
  end;
end;

procedure TMainForm.FadeForm(Action:String);
begin
  FadeAction := LowerCase(Action);
  if FadeAction = 'auto' then
    if Visible then FadeAction := 'hide' else FadeAction := 'show';

  if FadeAction = 'show' then
    AlphaBlendValue := 0
  else
  if FadeAction = 'hide' then
    AlphaBlendValue := 255;
  tmrFade.Enabled := True;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  // clear tab from taskbar
  SetWindowLong(Application.Handle,GWL_EXSTYLE,WS_EX_TOOLWINDOW);
  loadSettings;
end;

procedure TMainForm.timerColorTimer(Sender: TObject);
var
  hDesk : HWND;
  hdcDesktop : HDC;
  crefPixel : COLORREF;
  p : TPoint;
  iWidth,iHeight:Integer;
  C:TCanvas;
  iTmpX,iTmpY:Real;
  Srect,Drect,Ex1,Ex2:TRect;
begin
  if not IsIconic(Application.Handle) then
  begin
    GetCursorPos(p);

    hDesk := GetDesktopWindow;
    hdcDesktop := GetWindowDC(hDesk);
    crefPixel := GetPixel(hdcDesktop, p.x, p.y);
    ReleaseDC(hDesk, hdcDesktop);

    editHex.Text := toHTMLHex(IntToHex(crefPixel,6));

    Ex1 := Rect(MainForm.Left + pnlColor.Left,
                MainForm.Top + pnlColor.Top,
                MainForm.Left + pnlColor.Left + pnlColor.Width,
                MainForm.Top + pnlColor.Top + pnlColor.Height);

    Ex2 := Rect(MainForm.Left + pnlZoom.Left,
                MainForm.Top + pnlZoom.Top,
                MainForm.Left + pnlZoom.Left + pnlZoom.Width,
                MainForm.Top + pnlZoom.Top + pnlZoom.Height);

    if not PtInRect(Ex1,p) and not PtInRect(Ex2,p) then
    begin
      iWidth:=imgZoom.Width;
      iHeight:=imgZoom.Height;
      Drect:=Bounds(0,0,iWidth,iHeight);
      iTmpX:=iWidth / (2 * zoomFactor);
      iTmpY:=iHeight / (2 * zoomFactor);
      Srect:= Rect(p.x,p.y,p.x,p.y);
      InflateRect(Srect,Round(iTmpX),Round(iTmpY));

      C:=TCanvas.Create;
      try
       C.Handle:=GetDC(GetDesktopWindow);
       imgZoom.Canvas.CopyRect(Drect,C,Srect);
      finally
        ReleaseDC(hDesk, C.Handle);
        C.Free;
      end;
    end;
    Application.ProcessMessages;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Left := Screen.WorkAreaWidth - MainForm.Width;
  MainForm.Top := Screen.WorkAreaHeight - MainForm.Height;
  with imgZoom.Canvas do
  begin
//    Rectangle(0,0,imgZoom.Width,imgZoom.Height);
    Ellipse(5,5,20,20);
    Ellipse(8,8,17,17);
    Rectangle(12,4,13,22);
    Rectangle(4,12,22,13);
    Pen.Color := clWhite;
  end;
end;

procedure TMainForm.btnCloseClick(Sender: TObject);
begin
  FadeForm('close');
end;

procedure TMainForm.imgColorMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Screen.Cursor := crCross;
  if Button = mbLeft then timerColor.Enabled := True;
end;

procedure TMainForm.imgColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Screen.Cursor := crDefault;
  if Button = mbLeft then timerColor.Enabled := False;
end;

procedure TMainForm.popupCopyHexClick(Sender: TObject);
begin
  if editHex.Text <> '' then
    Clipboard.AsText := editHex.Text
  else
    Clipboard.Clear;
end;

procedure TMainForm.popupCopyRGBClick(Sender: TObject);
begin
  if (editRed.Text <> '') and (editGreen.Text <> '') and (editBlue.Text <> '') then
    Clipboard.AsText := editRed.Text + ' ' + editGreen.Text + ' ' + editBlue.Text
  else
    Clipboard.Clear;
end;

procedure TMainForm.setColors(Sender: TObject);
var
  r,g,b:Integer;
  color:TColor;
  i:Integer;
begin
  if Sender is TSpinEdit then
  begin
    editHex.OnChange := nil;

    TryStrToInt(editRed.Text,r);
    TryStrToInt(editGreen.Text,g);
    TryStrToInt(editBlue.Text,b);
    pnlColor.Color := RGB(r,g,b);

    editHex.Text := toHTMLHex(IntToHex(RGB(r,g,b),6));
    editHex.OnChange := setColors;
  end
  else
  if Sender is TEdit then
  begin
    editRed.OnChange := nil;
    editGreen.OnChange := nil;
    editBlue.OnChange := nil;

    TryStrToInt('$' + toHTMLHex(editHex.Text),i);
    color := StringToColor(IntToStr(i));
    pnlColor.Color := color;
    editRed.Text   := IntToStr(color and $FF);
    editGreen.Text := IntToStr(color and $FF00 div $100);
    editBlue.Text  := IntToStr(color and $FF0000 div $10000);

    editRed.OnChange := setColors;
    editGreen.OnChange := setColors;
    editBlue.OnChange := setColors;
  end;
end;

procedure TMainForm.btnMinimizeClick(Sender: TObject);
begin
  FadeForm('hide');
end;

procedure TMainForm.popupSettingsStartMinimizedClick(Sender: TObject);
begin
  startMinimized := popupSettingsStartMinimized.Checked;
  ini.setBool('Settings','StartMinimized',startMinimized);
end;

procedure TMainForm.btnSettingsClick(Sender: TObject);
begin
  popupSettings.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end;

procedure TMainForm.popupTrayIconExitClick(Sender: TObject);
begin
  FadeForm('close');
end;

procedure TMainForm.popupTrayIconShowHideClick(Sender: TObject);
begin
  FadeForm('auto');
end;

procedure TMainForm.setZoomFactor(Sender: TObject);
begin
  zoomFactor := (Sender as TMenuItem).Tag;
  ini.setInteger('Settings','ZoomFactor',zoomFactor);
end;

procedure TMainForm.imgTopBarMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if (ssLeft in Shift) then
  begin
    ReleaseCapture;
    SendMessage(MainForm.Handle, WM_SYSCOMMAND, SC_MOVE+1,0);
  end;
end;

procedure TMainForm.trayIconClick(Sender: TObject);
begin
  FadeForm('auto');
end;

procedure TMainForm.popupSettingsInfoClick(Sender: TObject);
begin
  Application.CreateForm(TFrm_Info, Frm_Info);
  try
    Frm_Info.ShowModal;
  finally
    Frm_Info.Release;
  end;
end;

procedure Init;
begin
  zoomFactor := 4;
  startMinimized := True;
  FadeSpeed := 10;
end;

procedure TMainForm.tmrFadeTimer(Sender: TObject);
begin
  AlphaBlend := True;
  if FadeAction = 'show' then
  begin
    if not Visible then Show;
    if AlphaBlendValue <= 255 - FadeSpeed then
      AlphaBlendValue := AlphaBlendValue + FadeSpeed
    else
    begin
      AlphaBlend := False;
      tmrFade.Enabled := False;
    end;
  end
  else
  if FadeAction = 'hide' then
  begin
    if AlphaBlendValue >= FadeSpeed then
      AlphaBlendValue := AlphaBlendValue - FadeSpeed
    else
    begin
      Hide;
      AlphaBlend := False;
      tmrFade.Enabled := False;
    end;
  end
  else
  if FadeAction = 'close' then
  begin
    if AlphaBlendValue >= FadeSpeed then
      AlphaBlendValue := AlphaBlendValue - FadeSpeed
    else
    begin
      Close;
    end;
  end;
end;

procedure TMainForm.trayIconStartup(Sender: TObject;
  var ShowMainForm: Boolean);
begin
  ShowMainForm := False;
  MainForm.FormActivate(MainForm);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  popupTrayIconShowHide.Caption := 'Hide';
end;

procedure TMainForm.FormHide(Sender: TObject);
begin
  popupTrayIconShowHide.Caption := 'Show';
end;

procedure TMainForm.btnCopyClick(Sender: TObject);
begin
  if editHex.Text <> '' then
    Clipboard.AsText := editHex.Text
  else
    Clipboard.Clear;
end;

procedure TMainForm.editHexKeyPress(Sender: TObject; var Key: Char);
var
  i:integer;
  origKey:Char;
begin
  origKey := UpCase(Key);
  for i := Low(validChars) to High(validChars) do
  begin
    if origKey = validChars[i] then
    begin
      Key := origKey;
      break;
    end
    else Key := #0;
  end;
end;

initialization
  Init;
// Check if ColorMan.exe is already running
  mHandle := CreateMutex(nil,True,'ColorMan');
  if GetLastError = ERROR_ALREADY_EXISTS then halt; // Already running

finalization
if mHandle <> 0 then CloseHandle(mHandle);

end.
