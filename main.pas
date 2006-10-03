unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, dxCore, dxButtons, Buttons, Clipbrd,
  ImgList, Menus, Spin, ShellApi, CoolTrayIcon, TextTrayIcon, jpeg;

const
  IC_CLICK = WM_APP + 201;

type
  TMainForm = class(TForm)
    timerColor: TTimer;
    editHex: TEdit;
    timerZoom: TTimer;
    imgZoom: TImage;
    pnlForm: TPanel;
    imgList: TImageList;
    imgColor: TImage;
    pnlColor: TPanel;
    editRed: TSpinEdit;
    editGreen: TSpinEdit;
    editBlue: TSpinEdit;
    btnMinimize: TSpeedButton;
    btnClose: TSpeedButton;
    popupCopy: TPopupMenu;
    popupCopyHex: TMenuItem;
    popupCopyRGB: TMenuItem;
    btnCopy: TSpeedButton;
    btnSettings: TSpeedButton;
    popupSettings: TPopupMenu;
    popupSettingsStartMinimized: TMenuItem;
    trayIcon: TTextTrayIcon;
    popupTrayIcon: TPopupMenu;
    popupTrayIconExit: TMenuItem;
    timerSlowHide: TTimer;
    timerSlowShow: TTimer;
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
    procedure btnCopyClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure popupTrayIconExitClick(Sender: TObject);
    procedure timerSlowHideTimer(Sender: TObject);
    procedure timerSlowShowTimer(Sender: TObject);
    procedure popupTrayIconShowHideClick(Sender: TObject);
    procedure setZoomFactor(Sender: TObject);
    procedure imgTopBarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure trayIconClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure popupSettingsInfoClick(Sender: TObject);
  private
    { Private declarations }
    procedure loadSettings;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  filePath: String;
  mHandle:THandle;

implementation

uses Math, StrUtils, ini, globalDefinitions, functions, info;

{$R *.dfm}

procedure delay(msecs:Integer);
var
  FirstTickCount:Longint;
begin
  FirstTickCount := GetTickCount;
  repeat
    Application.ProcessMessages; {allowing access to other controls, etc.}
  until ((GetTickCount-FirstTickCount) >= Longint(msecs));
end;

procedure TMainForm.loadSettings;
begin
  // get filepath of file
  filePath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  if FileExists(filePath + iniFileName) then
  begin
    // StartMinimized
    if ini.getInteger('Settings','StartMinimized',1) = 1 then
    begin
      popupSettingsStartMinimized.Checked := True;
      timerSlowHide.Enabled := True;
    end
    else popupSettingsStartMinimized.Checked := False;
    // ZoomFactor
    zoomFactor := ini.getInteger('Settings','ZoomFactor',4);
    if zoomFactor > 5 then zoomFactor := 5 else if zoomFactor < 1 then zoomFactor := 1;

    popupSettingsZoomFactor.Items[zoomFactor-1].Checked := True;
    setInteger('Settings','ZoomFactor',zoomFactor);
  end
  else
  begin
    setInteger('Settings','StartMinimized',startMinimized);
    setInteger('Settings','ZoomFactor',zoomFactor);
  end;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  // clear tab from taskbar
  ShowWindow(GetWindow(Handle,GW_OWNER),SW_HIDE);
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

    imgColor.Canvas.Brush.Color := crefPixel;
    imgColor.Canvas.Pen.Color := crefPixel;
    imgColor.Canvas.Rectangle(0,0,imgColor.Width,imgColor.Height);

//    editRed.Text   := IntToStr(crefPixel and $FF);
//    editGreen.Text := IntToStr(crefPixel and $FF00 div $100);
//    editBlue.Text  := IntToStr(crefPixel and $FF0000 div $10000);
    editHex.Text   := toHTMLHex(IntToHex(crefPixel,6));

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
  with imgColor.Canvas do
  begin
//    Rectangle(0,0,imgColor.Width,imgColor.Height);
    Ellipse(5,5,20,20);
    Ellipse(8,8,17,17);
    Rectangle(12,4,13,22);
    Rectangle(4,12,22,13);
    Pen.Color := clWhite;
  end;
end;

procedure TMainForm.btnCloseClick(Sender: TObject);
begin
  if Visible then
  begin
    timerSlowHide.Enabled := True;
    while Visible do delay(1);
  end;
  Close;
end;

procedure TMainForm.imgColorMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then timerColor.Enabled := True;
end;

procedure TMainForm.imgColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
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
  i:integer;
begin
  if Sender is TSpinEdit then
  begin
    editHex.OnChange := nil;

    TryStrToInt(editRed.Text,r);
    TryStrToInt(editGreen.Text,g);
    TryStrToInt(editBlue.Text,b);
    imgColor.Canvas.Brush.Color := RGB(r,g,b);
    imgColor.Canvas.Pen.Color := RGB(r,g,b);
    imgColor.Canvas.Rectangle(0,0,imgColor.Width,imgColor.Height);
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
    imgColor.Canvas.Brush.Color := color;
    imgColor.Canvas.Pen.Color := color;
    editRed.Text   := IntToStr(color and $FF);
    editGreen.Text := IntToStr(color and $FF00 div $100);
    editBlue.Text  := IntToStr(color and $FF0000 div $10000);
    imgColor.Canvas.Rectangle(0,0,imgColor.Width,imgColor.Height);

    editRed.OnChange := setColors;
    editGreen.OnChange := setColors;
    editBlue.OnChange := setColors;
  end;
end;

procedure TMainForm.btnMinimizeClick(Sender: TObject);
begin
  timerSlowHide.Enabled := True;
end;

procedure TMainForm.popupSettingsStartMinimizedClick(Sender: TObject);
begin
  if popupSettingsStartMinimized.Checked then
    ini.setInteger('Settings','StartMinimized',1)
  else
    ini.setInteger('Settings','StartMinimized',0);
end;

procedure TMainForm.btnCopyClick(Sender: TObject);
begin
  popupCopy.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end;

procedure TMainForm.btnSettingsClick(Sender: TObject);
begin
  popupSettings.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end;

procedure TMainForm.popupTrayIconExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.timerSlowHideTimer(Sender: TObject);
begin
  AlphaBlend := True;
  timerSlowHide.Enabled := False;
  while AlphaBlendValue > 5 do
  begin
    AlphaBlendValue := AlphaBlendValue - 5;
    delay(1);
  end;
  Hide;
  AlphaBlendValue := 255;
  AlphaBlend := False;
end;

procedure TMainForm.timerSlowShowTimer(Sender: TObject);
begin
  AlphaBlend := True;
  AlphaBlendValue := 0;
  Show;
  timerSlowShow.Enabled := False;
  while AlphaBlendValue < 255 do
  begin
    AlphaBlendValue := AlphaBlendValue + 5;
    delay(1);
  end;
  AlphaBlend := False;
end;

procedure TMainForm.popupTrayIconShowHideClick(Sender: TObject);
begin
  if Visible then timerSlowHide.Enabled := True else timerSlowShow.Enabled := True;
end;

procedure TMainForm.setZoomFactor(Sender: TObject);
begin
  zoomFactor := (Sender as TMenuItem).MenuIndex+1; // StrToInt(LeftStr((Sender as TMenuItem)..Items.Hint,1));
  setInteger('Settings','ZoomFactor',zoomFactor);
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
  if Visible then timerSlowHide.Enabled := True else timerSlowShow.Enabled := True;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Visible then
  begin
    timerSlowHide.Enabled := True;
    while Visible do delay(1);
  end;
end;

procedure TMainForm.popupSettingsInfoClick(Sender: TObject);
begin
  Frm_Info.ShowModal;
end;

initialization
  zoomFactor := 4;
  startMinimized := 1;
// Check if ColorMan.exe is already running
  mHandle := CreateMutex(nil,True,'ColorMan');
  if GetLastError = ERROR_ALREADY_EXISTS then halt; // Already running

finalization
if mHandle <> 0 then CloseHandle(mHandle);

end.
