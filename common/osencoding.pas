unit osencoding;

// This code is part of the opsi.org project

// Copyright (c) uib gmbh (www.uib.de)
// This sourcecode is owned by the uib gmbh, D55118 Mainz, Germany
// and published under the Terms of the GNU Affero General Public License.
// Text of the AGPL: http://www.gnu.org/licenses/agpl-3.0-standalone.html
// author: Rupert Roeder, detlef oertel
// credits: http://www.opsi.org/credits/



{$mode delphi}

interface

uses
  Classes,
  SysUtils,
  lconvencoding,
  charencstreams,
  LAZUTF8;

procedure initEncoding;
function isSupportedEncoding(testEncoding: string): boolean;
procedure logSupportedEncodings;

function isEncodingUnicode(encodingString: string): boolean;
function hasFileBom(infilename: string): boolean;

function loadUnicodeTextFile(filename: string): TStringList;
procedure saveUnicodeTextFile(inlist: TStrings; outFileName: string; encoding: string);

function stringListLoadUnicodeFromList(inlist: TStringList): TStringList;

function searchEncoding(const searchText: string): string;

function reencode(const sourceText: string; const sourceEncoding: string): string;
  overload;
function reencode(const sourceText: string; const sourceEncoding: string;
  var usedSourceEncoding: string): string; overload;
function reencode(const sourceText: string; const sourceEncoding: string;
  var usedSourceEncoding: string; destEncoding: string): string; overload;

function loadTextFileWithEncoding(filename, encoding: string): TStringList;
procedure saveTextFileWithEncoding(inlist: TStrings; outFileName: string; encoding: string);

var
  supportedEncodings: TStringList;
  mysystemEncoding: string;
  DefaultEncoding: string = 'utf8';

implementation

uses
  oslog;

var
  i, k: integer;
  additionalEncoding: string;


procedure initEncoding;
begin
  {$IFDEF LINUX}
  mysystemEncoding := 'utf8';
  {$ENDIF LINUX}
  {$IFDEF DARWIN}
  mysystemEncoding := GetDefaultTextEncoding;
  {$ENDIF DARWIN}
  {$IFDEF WINDOWS}
  //mysystemEncoding := 'utf8';
  mysystemEncoding := GetDefaultTextEncoding;
  {$ENDIF WINDOWS}
  // get the supported encodings
  supportedEncodings := TStringList.Create;
  GetSupportedEncodings(supportedEncodings);
  supportedEncodings.Add('UTF-16');
  supportedEncodings.Add('UTF-16BE');
  supportedEncodings.Add('UTF-16LE');
  supportedEncodings.Add('unicode');
  supportedEncodings.Add('UTF-16-BOM');
  supportedEncodings.Add('UTF-16BE-BOM');
  supportedEncodings.Add('UTF-16LE-BOM');
  supportedEncodings.Add('UTF-32-BOM');
  supportedEncodings.Add('UTF-32BE-BOM');
  supportedEncodings.Add('UTF-32LE-BOM');

  // add the aliases (utf8 is alias for UTF-8)
  k := supportedEncodings.Count;
  for i := 0 to k - 1 do
  begin
    additionalEncoding := LowerCase(supportedEncodings.Strings[i]);
    if pos('-', additionalEncoding) > 0 then
      additionalEncoding := copy(additionalEncoding, 0,
        pos('-', additionalEncoding) - 1) + copy(additionalEncoding,
        pos('-', additionalEncoding) + 1, length(additionalEncoding));
    supportedEncodings.Add(additionalEncoding);
  end;
  //for i:= 0 to supportedEncodings.Count-1 do writeln(supportedEncodings.Strings[i]);
end;

function isSupportedEncoding(testEncoding: string): boolean;
begin
  Result := False;
  if supportedEncodings.IndexOf(testEncoding) > -1 then
    Result := True;
  // logdatei.log_prog('Found or given Encoding: ' + testEncoding +
  //              ' is not supported.', LLWarning);
end;

procedure logSupportedEncodings;
begin
  if LogDatei <> nil then
    for i := 0 to supportedEncodings.Count - 1 do
      logdatei.log_prog(supportedEncodings.Strings[i], LLDebug2);
end;



function isEncodingUnicode(encodingString: string): boolean;
var
  lencstr: string;
begin
  lencstr := NormalizeEncoding(encodingString);
  Result := False;
  if copy(lencstr, length(lencstr) - 3, length(lencstr)) = 'bom' then
    Result := True
  else if (lencstr = Lowercase('unicode')) or (lencstr = Lowercase('utf8')) or
    (lencstr = Lowercase('utf16')) or (lencstr = Lowercase('utf32')) or
    (lencstr = Lowercase('utf16le')) or (lencstr = Lowercase('utf16be')) or
    (lencstr = Lowercase('ucs2le')) or (lencstr = Lowercase('ucs2be')) or
    (lencstr = Lowercase('utf32le')) or (lencstr = Lowercase('utf32be')) then
    Result := True;
end;

function uniEncoding2UniStreamTypes(fileName: string; encodingString: string;
  var hasBOM: boolean): TUniStreamTypes;
var
  lencstr: string;
  fCES: TCharEncStream;
begin
  Result := ufUtf8;
  hasBOM := False;
  //fCES := TCharEncStream.Create;
  //fCES.Reset;
  lencstr := NormalizeEncoding(encodingString);
  if copy(lencstr, length(lencstr) - 3, length(lencstr)) = 'bom' then
  begin
    hasBOM := True;
    lencstr := copy(lencstr, 0, length(lencstr) - 3);
  end;

  if lencstr = Lowercase('unicode') then
    if fileExists(fileName)
    then
    begin
      fCES := TCharEncStream.Create;
      fCES.Reset;
      fCES.LoadFromFile(ExpandFileName(fileName));
      //hasBOM := fCES.HasBOM;
      Result := fCES.UniStreamType;
    end
  else
      Result := ufUtf8;

  if (lencstr = Lowercase('utf8')) then
    Result := ufUtf8;

  if (lencstr = Lowercase('utf16le')) or (lencstr = Lowercase('ucs2le')) then
    Result := ufUtf16le;

  if (lencstr = Lowercase('utf16')) or (lencstr = Lowercase('utf16be')) or
    (lencstr = Lowercase('ucs2be')) then
    Result := ufUtf16be;

  if (lencstr = Lowercase('utf32')) or (lencstr = Lowercase('utf32be')) then
    Result := ufUtf32be;

  if (lencstr = Lowercase('utf32le')) then
    Result := ufUtf32le;

end;

function hasFileBom(inFileName: string): boolean;
var
  fCES: TCharEncStream;
begin
  fCES := TCharEncStream.Create;
  fCES.Reset;
  inFileName := ExpandFileName(inFileName);
  fCES.LoadFromFile(inFileName);
  Result := fCES.hasBOM;
  fCES.Free;
end;

function loadUnicodeTextFile(fileName: string): TStringList;
var
  fCES: TCharEncStream;
begin
  Result := TStringList.Create;
  fCES := TCharEncStream.Create;
  fCES.Reset;
  fileName := ExpandFileName(fileName);
  fCES.LoadFromFile(fileName);
  fCES.ANSIEnc := GetSystemEncoding;
  Result.Text := fCES.UTF8Text;
  fCES.Free;
end;

procedure saveUnicodeTextFile(inlist: TStrings; outFileName: string; encoding: string);
var
  fCES: TCharEncStream;
  hasBOM: boolean;
begin
  fCES := TCharEncStream.Create;
  fCES.Reset;
  fCES.UniStreamType := uniEncoding2UniStreamTypes(outFileName,encoding, hasBOM);
  fCES.HasBOM := hasBOM;
  fCES.ForceType := True;
  fCES.UTF8Text := inlist.Text;
  fCES.SaveToFile(outFileName);
  fCES.ANSIEnc := GetSystemEncoding;
  fCES.Free;
end;

(*
function stringListLoadUtf16leFromFile(filename: string): TStringList;
var
  fCES: TCharEncStream;
begin
  Result := TStringList.Create;
  fCES := TCharEncStream.Create;
  fCES.Reset;
  fCES.UniStreamType := ufUtf16le;
  fileName := ExpandFileName(fileName);
  fCES.LoadFromFile(fileName);
  fCES.ANSIEnc := GetSystemEncoding;
  Result.Text := fCES.UTF8Text;
  fCES.Free;
end;
*)

function stringListLoadUnicodeFromList(inlist: TStringList): TStringList;
var
  fCES: TCharEncStream;
begin
  Result := TStringList.Create;
  fCES := TCharEncStream.Create;
  fCES.Reset;
  inlist.SaveToStream(fCES);
  fCES.ANSIEnc := GetSystemEncoding;
  Result.Text := fCES.UTF8Text;
  fCES.Free;
end;


function isStringInList(const str: string; const list: TStringList): boolean;
  // list.IndexOf(str) > -1 does not work as expected: ucs2be is found if str is 'u c s 2 b e'
var
  i: integer;
begin
  Result := False;
  i := 0;
  repeat
    if list.Strings[i] = str then
    begin
      Result := True;
    end;
    Inc(i);
  until (Result = True) or (i >= list.Count);
end;

function searchEncoding(const searchText: string): string;
  // tries to find entry: encoding=<encoding to use>
var
  mylist, myencodings: TStringList;
  i: integer;
  mytext: string;
  found: boolean;
  foundencodingstring, newencodingstring: string;
begin
  Result := '';
  found := False;
  mylist := TStringList.Create;
  myencodings := TStringList.Create;
  mylist.Text := searchText;
  GetSupportedEncodings(myencodings);
  if mylist.IndexOfName('encoding') <> -1 then
  begin
    // we found an entry: encoding=<encoding to use>
    foundencodingstring := trim(mylist.Values['encoding']);
    logdatei.log('foundencodingstring: ' + foundencodingstring, LLDebug2);
    if isStringInList(foundencodingstring, supportedEncodings) then
      Result := foundencodingstring
    else
    begin
      i := 0;
      repeat
        // convert via utf8
        newencodingstring := ConvertEncoding(foundencodingstring,
          myencodings.Strings[i], 'utf8');
        newencodingstring := ConvertEncoding(newencodingstring, 'utf8',
          DefaultEncoding);
        logdatei.log('myencodings.Strings[i]: ' + myencodings.Strings[i] +
          'newencodingstring: ' + newencodingstring, LLDebug3);
        if isStringInList(newencodingstring, supportedEncodings) then
        begin
          // newencodingstring is a supported encoding
          Result := newencodingstring;
          found := True;
        end;
        Inc(i);
      until (found = True) or (i >= myencodings.Count);
    end;
    //logdatei.DependentAdd('searchText: '+searchText+', foundencodingstring: '+foundencodingstring+', mysystemEncoding: '+mysystemEncoding,LLEssential);
    //result := foundencodingstring;
  end
  else
  begin
    // it seems that we normally do not reach this branch

    // we found no encoding entry
    // we have now 2 possibilities:
    // a) there is no encoding entry
    // b) there is one but we do not find it because of the wrong encoding
    i := 0;
    repeat
      begin
        mytext := ConvertEncoding(searchText, myencodings.Strings[i], DefaultEncoding);
        logdatei.log('mytext: ' + mytext + ', myencodings.Strings[i]: ' +
          myencodings.Strings[i] + ', DefaultEncoding: ' + DefaultEncoding, LLDebug3);
        mylist.Text := mytext;
        if mylist.IndexOfName('encoding') <> -1 then
        begin
          // we found an entry: encoding=<encoding to use>
          Result := mylist.Values['encoding'];
          found := True;
        end;
        Inc(i);
      end;
    until (found = True) or (i >= myencodings.Count);
  end;
  myencodings.Free;
  mylist.Free;
end;

function reencode(const sourceText: string; const sourceEncoding: string): string;
var
  str: string;
begin
  Result := reencode(sourceText, sourceEncoding, str);
end;

function reencode(const sourceText: string; const sourceEncoding: string;
  var usedSourceEncoding: string): string;
begin
  Result := reencode(sourceText, sourceEncoding, usedSourceEncoding, 'utf8');
end;

function reencode(const sourceText: string; const sourceEncoding: string;
  var usedSourceEncoding: string; destEncoding: string): string;
var
  str: string;
  mylist: TStringList;
  i: integer;
begin
  //for i:= 0 to supportedEncodings.Count-1 do writeln(supportedEncodings.Strings[i]);
  Result := sourceText;
  usedSourceEncoding := sourceEncoding;
  if LowerCase(sourceEncoding) = 'system' then
    usedSourceEncoding := mysystemEncoding;
  if LowerCase(destEncoding) = 'system' then
    destEncoding := mysystemEncoding;
  // which means normally: do nothing
  if LowerCase(sourceEncoding) = 'auto' then
    usedSourceEncoding := guessEncoding(sourceText);
  if supportedEncodings.IndexOf(usedSourceEncoding) = -1 then
    if Assigned(logdatei) then
      logdatei.log_prog('Found or given Encoding: ' + usedSourceEncoding +
        ' is not supported.', LLWarning);
  if LowerCase(usedSourceEncoding) <> LowerCase(destEncoding) then
  begin
    if Assigned(logdatei) then
      logdatei.log_prog('Encodings are different so we have to reencode from ' +
        usedSourceEncoding + ' to ' + destEncoding, LLDebug2);
    if (usedSourceEncoding = 'utf8') or (usedSourceEncoding = 'UTF-8') or
      (destEncoding = 'utf8') or (destEncoding = 'UTF-8') then
    begin
      if Assigned(logdatei) then
        logdatei.log_prog('We encode directly from or to utf8.', LLDebug2);

      if (usedSourceEncoding = 'utf16') or (usedSourceEncoding = 'UTF-16') then
        usedSourceEncoding := 'ucs2be';

      if (destEncoding = 'utf16') or (destEncoding = 'UTF-16') then
        destEncoding := 'ucs2be';

      if (usedSourceEncoding = 'utf16le') or (usedSourceEncoding = 'UTF-16LE') then
        usedSourceEncoding := 'ucs2le';

      if (destEncoding = 'utf16le') or (destEncoding = 'UTF-16LE') then
        destEncoding := 'ucs2le';

      if (usedSourceEncoding = 'utf16be') or (usedSourceEncoding = 'UTF-16BE') then
        usedSourceEncoding := 'ucs2be';

      if (destEncoding = 'utf16be') or (destEncoding = 'UTF-16BE') then
        destEncoding := 'ucs2be';

      if (usedSourceEncoding = 'unicode') then
        usedSourceEncoding := 'ucs2le';

      if (destEncoding = 'unicode') then
        destEncoding := 'ucs2le';

      // we use ConvertEncoding
      Result := ConvertEncoding(sourceText, usedSourceEncoding, destEncoding);
    end
    else
    begin
      if Assigned(logdatei) then
        logdatei.log_prog('We encode via utf8.', LLDebug2);
      if Assigned(logdatei) then
        logdatei.log_prog('Encodings are different so we have to reencode from ' +
          usedSourceEncoding + ' to ' + destEncoding, LLDebug2);
      if (usedSourceEncoding = 'ucs2be') or (usedSourceEncoding = 'UCS-2BE') or
        (usedSourceEncoding = 'ucs2le') or (usedSourceEncoding = 'UCS-2LE') then
      begin
        if Assigned(logdatei) then
          logdatei.log_prog('We encode line by line.', LLDebug2);
        mylist := TStringList.Create;
        mylist.Text := sourceText;
        for i := 0 to mylist.Count - 1 do
        begin
          str := mylist.Strings[i];
          mylist.Strings[i] := ConvertEncoding(str, usedSourceEncoding, 'utf8');
          if Assigned(logdatei) then
            logdatei.log_prog(usedSourceEncoding + ' to utf8: ' +
              str + ' to ' + mylist.Strings[i],
              LLDebug3);
        end;
        Result := mylist.Text;
        mylist.Free;
      end
      else
      begin
        Result := ConvertEncoding(sourceText, usedSourceEncoding, 'utf8');
        if Assigned(logdatei) then
          logdatei.log_prog(usedSourceEncoding + ' to utf8: ' +
            sourceText + ' to ' + Result, LLDebug3);
      end;
    end;
    if Assigned(logdatei) then
      logdatei.log_prog('Reencoding from ' + usedSourceEncoding +
        ' to ' + destEncoding, LLDebug2);
  end
  else if Assigned(logdatei) then
    logdatei.log_prog('Nothing to do: Reencoding from ' + usedSourceEncoding +
      ' to ' + destEncoding, LLDebug2);
end;

function loadTextFileWithEncoding(filename, encoding: string): TStringList;
(* var
    txtfile: Text;
    rawline: WideString;
    encline: string;
  *)
begin
  Result := TStringList.Create;
  if isEncodingUnicode(encoding) then
    Result.AddStrings(loadUnicodeTextFile(filename))
  //else if (enc = 'utf16le') then
  //  Result.AddStrings(stringListLoadUtf16leFromFile(filename))
  // else if ((enc = 'utf8') or (enc = 'UTF-8')) then
  // utf8 is our internal code - nothing to do
  //  Result.LoadFromFile(filename);
  else
  begin
    Result.loadFromFile(filename);
    Result.Text := reencode(Result.Text, encoding);
    (*
    AssignFile(txtfile, filename);
    Reset(txtfile);
    while not EOF(txtfile) do
    begin
      ReadLn(txtfile, rawline);
      encline := reencode(rawline, enc);
      Result.Append(encline);
    end;
    CloseFile(txtfile);
    *)
  end;
end;

procedure saveTextFileWithEncoding(inlist: TStrings; outFileName: string;
  encoding: string);
var
  //fCES: TCharEncStream;
  //str: string;
  myfile: Text;
  usedenc: string;
begin
  (*
  fCES := TCharEncStream.Create;
  fCES.Reset;
  fCES.UTF8Text := inlist.Text;
  *)
  if isEncodingUnicode(encoding) then
    saveUnicodeTextFile(inlist, outFileName, encoding)
  else
  begin
    AssignFile(myfile, outFileName);
    Rewrite(myfile);
    LogDatei.log('Will save (' + encoding + ') to file: ' + outFileName +
      ' :', LLDebug2);
    LogDatei.log('-----------------', LLDebug3);
    writeln(myfile, reencode(inlist.Text, 'utf8', usedenc, encoding));

    LogDatei.log('-----------------', LLDebug3);
    CloseFile(myfile);
    if LogDatei.UsedLogLevel >= LLDebug3 then
    begin
      LogDatei.log('Read file ' + outFileName + ' with encoding: ' +
        encoding, LLDebug2);
      LogDatei.log('-----------------', LLDebug3);
      logdatei.includelogtail(outFileName, inlist.Count, encoding);
      LogDatei.log('-----------------', LLDebug3);
    end;
  end;
 // fCES.Free;
end;


initialization
  initEncoding;
end.

