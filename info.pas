unit info;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, jpeg, ShellApi;

type
  TFrm_Info = class(TForm)
    pnlBg: TPanel;
    lblName: TLabel;
    lblAuthor: TLabel;
    lblEmail: TLabel;
    lblHomepage: TLabel;
    lblCopyright: TLabel;
    imgPic: TImage;
    btnClose: TSpeedButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lblHomepageClick(Sender: TObject);
    procedure lblEmailClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Frm_Info: TFrm_Info;

implementation
uses globalDefinitions;

{$R *.dfm}

procedure TFrm_Info.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrm_Info.FormCreate(Sender: TObject);
begin
  lblName.Caption := progName+' '+progVersion;
  lblAuthor.Caption := progAuthor;
  lblEmail.Caption := progAuthorEmail;
  lblHomepage.Caption := progAuthorHomepage;
  lblCopyright.Caption := progCopyright;
end;

procedure TFrm_Info.lblHomepageClick(Sender: TObject);
begin
  ShellExecute(Application.Handle,
               'open',
               PChar(progAuthorHomepage),
               nil,
               nil,
               SW_ShowNormal);
end;

procedure TFrm_Info.lblEmailClick(Sender: TObject);
begin
  ShellExecute(Application.Handle,
               'open',
               PChar('mailto:'+progAuthorEmail+'?subject='+progName+' '+progVersion),
               nil,
               nil,
               sw_ShowNormal);
end;

end.
