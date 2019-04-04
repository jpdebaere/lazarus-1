unit odg_main;

{$mode objfpc}{$H+}


interface


uses
  fileinfo,
  winpeimagereader, // {need this for reading exe info}
  elfreader, // {needed for reading ELF executables}
  FileUtil,
  odg_os_deffunc,
  odg_py_deffunc,
  oslog,
  odg_os_asciidoc,
  odg_py_asciidoc,
  process,
  LCLIntf,
  Classes,
  SysUtils;

function convertOslibToAsciidoc(): boolean;
function convertPylibToAsciidoc(): boolean;
function save_compile_show() : boolean;

var
  sourcelist : TStringlist;
  targetlist : TStringlist;
  myversion : string;
  FileVerInfo : TFileVersionInfo;

implementation

function convertOslibToAsciidoc(): boolean;
begin
  result := parseInput_opsiscriptlibrary();
  writeDocToList;
end;

function convertPylibToAsciidoc(): boolean;
begin
  result := parseInput_pythonlibrary();
  writePyDocToList;
end;

function writeToAsciidocFile() : string;
var
  tmpfilename, currentdatetime : string;
begin
  result := '';
  currentdatetime := FormatDateTime('yyyy"-"mm"-"dd"_"hh:nn', Now);
  tmpfilename := IncludeTrailingPathDelimiter(GetCurrentDir)+'docgenerated_'+currentdatetime+'.asciidoc';
  targetlist.SaveToFile(tmpfilename);
  result := tmpfilename;
  LogDatei.log('Wrote asciidoc file to: '+tmpfilename,LLinfo);
end;

function callasciidoctor(filename : string): boolean;
var
  output : string;
  myasciidoc : string;
  shell, shelloption, optionstr : string;
begin
  result := false;
  {$ifdef WINDOWS}
  if not RunCommand('cmd.exe',['/c' ,'where asciidoctor.'],output) then
  begin
    writeln('Could not find asciidoctor binary');
    LogDatei.log('Could not find asciidoctor binary',LLcritical);
  end
  else
  begin
    myasciidoc := output;
    myasciidoc := myasciidoc.Replace(#13#10,'');
    myasciidoc := myasciidoc.Replace('''','');
    shell := 'cmd.exe';
    shelloption := '/c';
  end;
  LogDatei.log('Try to call asciidoctor binary',LLnotice);
  if not RunCommand(shell,[shelloption+' '+myasciidoc+' --backend xhtml5 '+filename],output) then
  {$endif WINDOWS}
  {$ifdef LINUX}
  shell := '/bin/bash';
  shelloption := '-c ';
  if not RunCommand('/usr/bin/which',['asciidoctor'],output) then
   writeln('Could not find asciidoctor binary')
  else
  begin
    myasciidoc := output;
    myasciidoc := myasciidoc.Replace(#10,'');
    myasciidoc := myasciidoc.Replace('''','');
  end;
  optionstr := '--backend xhtml5 '+ExtractFileName(filename);
  writeln('calling: indir: '+ ExtractFileDir(filename));
  writeln('calling: : '+ myasciidoc+' '+optionstr);
  LogDatei.log('calling: indir: '+ ExtractFileDir(filename),LLnotice);
  LogDatei.log('calling: '+ myasciidoc+' '+optionstr,LLnotice);
  if not RunCommand(myasciidoc,['--backend','xhtml5',filename],output) then
  //if not RunCommandIndir(ExtractFileDir(filename),myasciidoc,[optionstr],output) then
  //if not RunCommand(myasciidoc,['--backend xhtml5 ','"'+filename+'"'],output) then
  //if not RunCommand(shell,[shelloption+''''+myasciidoc+' --backend xhtml5 '+filename+''''],output) then
  {$endif LINUX}
  //if not RunCommand(shell,[shelloption+' '+myasciidoc+' --backend xhtml5 '+filename],output) then
  begin
   writeln('Call asciidoctor failed');
   writeln(output);
   LogDatei.log('Call asciidoctor failed: '+output,LLcritical);
  end
  else
  result := true;
end;

function save_compile_show() : boolean;
var
  asciidocfile : string;
begin
  asciidocfile := writeToAsciidocFile();
  if not callasciidoctor(asciidocfile) then
  begin
    writeln('callasciidoctor failed');
    LogDatei.log('callasciidoctor failed',LLcritical);
  end
  else
    OpenDocument(ExtractFileNameWithoutExt(asciidocfile)+'.html');
end;


initialization
  sourcelist := TStringlist.create;
  targetlist := TStringlist.create;
  LogDatei := TLogInfo.Create;
  logdatei.CreateTheLogfile('opsi-doc-gen.log');
  LogDatei.LogLevel:=8;

  //from http://wiki.freepascal.org/Show_Application_Title,_Version,_and_Company
   FileVerInfo := TFileVersionInfo.Create(nil);
   try
     FileVerInfo.FileName := ParamStr(0);
     FileVerInfo.ReadFileInfo;
     myversion := FileVerInfo.VersionStrings.Values['FileVersion'];
   finally
     FileVerInfo.Free;
   end;

finalization
  sourcelist.Free;
  targetlist.Free;
end.

