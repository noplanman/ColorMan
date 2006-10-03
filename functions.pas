unit functions;

interface

function toHTMLHex(str:String):String;

implementation

uses StrUtils;

function toHTMLHex(str:String):String;
var
  i:Integer;
begin
  for i := 1 to 6 - Length(str) do
  begin
    str := '0' + str;
  end;
  str := RightStr(str,2) + MidStr(str,3,2) + LeftStr(str,2);
  result := str;
end;

end.
