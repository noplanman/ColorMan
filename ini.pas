unit ini;

interface

procedure setString(section,key,value:String);
procedure setInteger(section,key:String;value:Integer);
function getString(section,key,default:String):String;
function getInteger(section,key:String;default:Integer):Integer;

implementation

uses SysUtils, IniFiles, globalDefinitions;

var
iniFile : TIniFile;
filePath : String;

procedure setString(section,key,value:String);
begin
  try
    filePath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
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
    filePath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
    iniFile := TIniFile.Create(filePath + iniFileName);
    iniFile.WriteInteger(section,key,value);
    iniFile.UpdateFile;
  finally
    iniFile.Free;
  end;
end;

function getString(section,key,default:String):String;
begin
  try
    filePath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
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
    filePath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
    iniFile := TIniFile.Create(filePath + iniFileName);
    default := iniFile.ReadInteger(section,key,default);
  finally
    iniFile.Free;
  end;
  result := default;
end;

end.
