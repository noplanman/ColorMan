unit ini;

interface

procedure setString(section,key,value:String);
procedure setInteger(section,key:String;value:Integer);
procedure setBool(section,key:String;value:Boolean);
function getString(section,key,default:String):String;
function getInteger(section,key:String;default:Integer):Integer;
function getBool(section,key:String;default:Boolean):Boolean;

implementation

uses SysUtils, IniFiles, globalDefinitions;

var
iniFile : TIniFile;
filePath : String;

procedure setString(section,key,value:String);
begin
  try
    filePath := ExtractFilePath(ParamStr(0));
    iniFile := TIniFile.Create(filePath + iniFileName);
    iniFile.WriteString(section,key,value);
    iniFile.UpdateFile;
  finally
    iniFile.Free;
  end;
end;

procedure setInteger(section,key:String;value:Integer);
begin
  try
    filePath := ExtractFilePath(ParamStr(0));
    iniFile := TIniFile.Create(filePath + iniFileName);
    iniFile.WriteInteger(section,key,value);
    iniFile.UpdateFile;
  finally
    iniFile.Free;
  end;
end;

procedure setBool(section,key:String;value:Boolean);
begin
  try
    filePath := ExtractFilePath(ParamStr(0));
    iniFile := TIniFile.Create(filePath + iniFileName);
    iniFile.WriteBool(section,key,value);
    iniFile.UpdateFile;
  finally
    iniFile.Free;
  end;
end;

function getString(section,key,default:String):String;
begin
  try
    filePath := ExtractFilePath(ParamStr(0));
    iniFile := TIniFile.Create(filePath + iniFileName);
    default := iniFile.ReadString(section,key,default);
  finally
    iniFile.Free;
  end;
  result := default;
end;

function getInteger(section,key:String;default:Integer):Integer;
begin
  try
    filePath := ExtractFilePath(ParamStr(0));
    iniFile := TIniFile.Create(filePath + iniFileName);
    default := iniFile.ReadInteger(section,key,default);
  finally
    iniFile.Free;
  end;
  result := default;
end;

function getBool(section,key:String;default:Boolean):Boolean;
begin
  try
    filePath := ExtractFilePath(ParamStr(0));
    iniFile := TIniFile.Create(filePath + iniFileName);
    default := iniFile.ReadBool(section,key,default);
  finally
    iniFile.Free;
  end;
  result := default;
end;

end.
