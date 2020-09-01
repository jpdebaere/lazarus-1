unit cliapp;

{$mode objfpc}{$H+}



interface

uses
  Classes,
  SysUtils,
  custapp,
  oslog,
  osversioninfo,
  osencoding,
  beautifyopsiscript,
  lazFileUtils
  ;

type

{ TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

var
  Application: TMyApplication;
  myversion : string;

implementation





{ TMyApplication }

procedure initLogging;
var
  logfilename : string;
begin
  logdatei := TLogInfo.Create;
  logfilename := ExtractFileNameOnly(reencode(ParamStr(0), 'system'))+'-beautifier.log';
  LogDatei.WritePartLog := False;
  LogDatei.WriteErrFile:= False;
  LogDatei.WriteHistFile:= False;
  logdatei.CreateTheLogfile(logfilename, False);
  logdatei.LogLevel := 7;
  (*
  for i := 0 to preLogfileLogList.Count-1 do
    logdatei.log(preLogfileLogList.Strings[i], LLessential);
  preLogfileLogList.Free;
  *)
  logdatei.log('opsi-script-beautyfier version: ' + getversioninfo, LLessential);
  //logdatei.log('Called as: ' + ExtractFileNameOnly(reencode(ParamStr(0), 'system')), LLessential);
end;

procedure TMyApplication.DoRun;
var
  ErrorMsg: String;
  optionlist : TStringlist;
  logpath, beautiparamsfilename, opsiscriptfile : string;
  (*
  verinfo : TFileVersionInfo;
begin
  verinfo := TFileVersionInfo.Create(nil);
  verinfo.FileName := ParamStr(0);
  verinfo.ReadFileInfo;
  myversion := verinfo.VersionStrings.Values['FileVersion'];
  verinfo.Free;
  *)
begin
  writeln(ExtractFileName(ParamStr(0))+' version: ' + getversioninfo);
  logpath := copy(GetUserDir,1,Length(getUserDir)-1);      // default
  {look for configuration file (beautify.ini) in program directory by default}
  beautiparamsfilename := ExtractFileDir(ParamStr(0))+PathDelim+'beautify.ini';
  {use last param as file argument by default}
  if (paramcount > 0) and (FileExistsUTF8(ParamStr(ParamCount))) then
    opsiscriptfile := ParamStr(ParamCount)
  else opsiscriptfile := '';
  // quick check parameters
  optionlist := TStringlist.Create;
  optionlist.Add('help');
  optionlist.Add('beautiparams:');
  optionlist.Add('file:');
  optionlist.Add('logpath:');
  ErrorMsg:=CheckOptions('hbfl',optionlist);
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    WriteHelp;
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  if HasOption('b', 'beautiparams') then
  begin
    beautiparamsfilename := GetOptionValue('b','beautiparams');
  end
  else
  begin
    writeln('configuration file: '+beautiparamsfilename);
    (*
    writeln('Error: missing parameter for file beautiparams');
    WriteHelp;
    Terminate;
    Exit;
    *)
  end;

  if HasOption('f', 'file') then
  begin
    opsiscriptfile := GetOptionValue('f','file');
  end
  else
  begin
    writeln('beautify file: '+opsiscriptfile);
    (*
    writeln('Error: missing parameter file');
    WriteHelp;
    Terminate;
    Exit;
    *)
  end;

  if HasOption('l', 'logpath') then
  begin
    logpath := GetOptionValue('l','logpath');
  end;
  initLogging;
  writeln('log file: '+LogDatei.FileName);
  //writeln('file with beautifier params: ' + beautiparamsfilename);
  logdatei.log('file with beautifier params: ' + beautiparamsfilename, LLessential);
  logdatei.log('opsiscriptfile to beautify: ' + opsiscriptfile, LLessential);
  beautifyopsiscript.initialize(beautiparamsfilename,opsiscriptfile);

  // stop program loop
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
var
  filename : string;
begin
  filename := ExtractFileName(ExeName);
  writeln(filename+' version: ' + getversioninfo);
  writeln('Usage: '+ filename + '[Options] [filename]');
  writeln('Options:');
  writeln('-h, --help : print this help');
  writeln('-b, --beautiprams : path to beautiparams file * optional, default program dir');
  writeln('-f, --file : path to file.opsiscript * optional, default last param');
  writeln('-l, --logpath : set log path * optional, default userdir');
end;


end.

