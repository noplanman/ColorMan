program ColorMan;

uses
  Forms,
  main in 'main.pas' {MainForm},
  ini in 'ini.pas',
  globalDefinitions in 'globalDefinitions.pas',
  functions in 'functions.pas',
  info in 'info.pas' {Frm_Info};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFrm_Info, Frm_Info);
  Application.Run;
end.
