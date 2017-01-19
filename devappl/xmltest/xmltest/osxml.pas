unit osxml;

// This code is part of the opsi.org project

// Copyright (c) uib gmbh (www.uib.de)
// This sourcecode is owned by the uib gmbh, D55118 Mainz, Germany
// and published under the Terms of the GNU Affero General Public License.
// Text of the AGPL: http://www.gnu.org/licenses/agpl-3.0-standalone.html
// author: martina hammel, detlef oertel
// credits: http://www.opsi.org/credits/

//***************************************************************************
// Subversion:
// $Revision: 518 $
// $Author: hammel $
// $Date: 2016-12-06 14:15:37 +0100 (Di, 06. Dez 2016) $
//***************************************************************************


{$mode delphi}

interface

uses
  Classes, SysUtils, DOM, osxmltdom, XMLRead, XMLWrite;

(*
type
  Topsiscriptxml = class(TXMLDocument)
  protected
    procedure create(str : String;);
    function createXmlDocFromString(str:string) : TXMLDocument;

    function nodeElementsCount(mynode : TDOMNode) : integer;
    function docElementsCount(myxdoc : TXMLDocument) : integer;
    function nodeElements(mynode : TDOMNode) : TStringlist;
    function docElements(myxdoc : TXMLDocument) : TStringlist;
    function getNodeByName(mynode : TDOMNode; name:string) : TDOMNode;
    function getNodeByIndex(mynode : TDOMNode; index:integer) : TDOMNode;
    function getTextEntry(mynode : TDOMNode) : string;
    function getAttributeList(mynode : TDOMNode) : TStringlist;
    function getAttributeKeyList(mynode : TDOMNode) : TStringlist;
    function getAttributeValueList(mynode : TDOMNode) : TStringlist;

  public
    start(list : TStringlist;);

    function xmldoc(list : TStringlist;) : Tstringlist;
    function xmlnode(list : TStringlist;) : Tstringlist;

  end;
*)
(* DOM
  ELEMENT_NODE = 1;
  ATTRIBUTE_NODE = 2;
  TEXT_NODE = 3;
  CDATA_SECTION_NODE = 4;
  ENTITY_REFERENCE_NODE = 5;
  ENTITY_NODE = 6;
  PROCESSING_INSTRUCTION_NODE = 7;
  COMMENT_NODE = 8;
  DOCUMENT_NODE = 9;
  DOCUMENT_TYPE_NODE = 10;
  DOCUMENT_FRAGMENT_NODE = 11;
  NOTATION_NODE = 12;
  *)


function getXMLDocAsTStringlist(): TStringlist;
function getDocumentElementAsStringlist(docstrlist: TStringList): TStringList;
function setDocumentElementAsStringlist(var docstrlist: TStringList; docelemstrlist:TStringlist): boolean;
function getDocNodeNameFromStringList(docstrlist: TStringList): string;
function getDocNodeNameFromXMLDoc () : string;
function getDocNodeType(docstrlist: TStringList): string;

//******************************************************************************
function appendXmlNodeToDocFromStringlist(docstrlist: TStringList;
  nodestrlist: TStringList; var strList: TStringList): boolean;
function appendXmlNodeToNodeFromStringlist(var nodestrlist1:
  TStringlist; nodestrlist2: TStringlist): boolean;
//******************************************************************************
// direkte node-Stringvalue operation   TODO
function xmlAsStringlistSetNodevalue (var nodestrlist: TStringlist; value: String) :boolean;
function xmlAsStringlistGetNodevalue (nodestrlist: TStringlist; var value: String) :boolean;
function xmlAsStringlistGetNodeAttributeKeys (nodestrlist: TStringlist; var keylist: TStringlist) :boolean;
function xmlAsStringlistSetNodeattributeByKey (var nodestrlist: TStringlist; attributekey: String; value: String) :boolean;
//******************************************************************************
// by index
function xmlAsStringlistGetChildnodeByIndex(nodestrlist: TStringList;
  index: integer; var Value: TStringList): boolean;
function xmlAsStringlistSetChildnodeValueByIndex (var mynodeAsStringlist: TStringList;
  index: integer; value: string ): boolean;
function xmlAsStringlistGetChildnodeValueByIndex(mynodeAsStringlist: TStringList; index: integer;
  var Value: string): boolean;
function xmlAsStringlistDeleteChildnodeByIndex(var mynodeAsStringlist: TStringList;
  index: integer): boolean;
//******************************************************************************
// by name
function xmlAsStringlistGetUniqueChildnodeByName(nodestrlist: TStringList;
  Name: string; var childnodeSL: TStringList): boolean;
function xmlAsStringlistSetChildnodeByName(var nodestrlist: TStringList;
  NodeName: string; childnodeSL: TStringList): boolean;

//******************************************************************************
// attributes
function xmlAsStringlistgetAttributesValueList(nodeAsStringlist: TStringList;
     var attributeValueList:TStringlist): boolean;
function xmlAsStringlistdeleteChildAttributeByKey(var nodeAsStringlist: TStringList;
     attributekey: string) : boolean;
function xmlAsStringlistGetChildAttributeValueByNameAndKey(nodeAsStringlist: TStringList;
  nodename:string; attributekey:string; var attributevalue:string) :boolean;
function xmlAsStringlistSetChildAttributeValueByNameAndKey(var nodeAsStringlist: TStringList;
  nodename:string; attributekey:string; attributevalue:string) :boolean;
//******************************************************************************
function xmlAsStringlistAllElementsCount(nodeAsStringlist: TStringList): integer;
function xmlAsStringlistElementsCount(nodeAsStringlist: TStringList): integer;
function xmlAsStringlistCommentElementsCount(nodeAsStringlist: TStringList): integer;
function xmlAsStringlistHasChildNodes(nodeAsStringlist: TStringList): boolean;
function xmlAsStringlistGetChildNodes(nodeAsStringlist: TStringList;
  var childnodes: TStringList): boolean;
function isValid(str: string): boolean;      // tut nix


implementation
var XMLasStringList: TStringList;


function getXMLDocAsTStringlist(): TStringlist;
var nodeStream: TMemoryStream;
    mystringlist: TStringList;
begin
  result:=NIL;
  if XMLexists then
    try
      mystringlist := TStringList.Create;
      nodeStream := TMemoryStream.Create;
      WriteXML(getXMLDoc, nodestream);
      nodeStream.Position := 0;
      mystringlist.LoadFromStream(nodestream);
      Result := mystringlist;
    finally
      nodestream.Free;
    end;
end;

function setDocumentElementAsStringlist(var docstrlist: TStringList; docelemstrlist:TStringlist): boolean;
var mynode: TDOMNode;
begin
  result:=false;
  try
    mynode:= createXMLNodeFromString(docelemstrlist);
    getXMLDoc.RemoveChild(getXMLDoc.FirstChild);
    getXMLDoc.AppendChild(mynode);
    docstrlist:= getXMLDocAsTStringlist();
    result:=true;
  finally
    mynode.Free;
  end;
end;


//*****************************************************************************
function getDocumentElementAsStringlist(docstrlist: TStringList): TStringList;
var
  nodeStream: TMemoryStream;
  mystringlist: TStringList;
  mynode: TDOMNode;
begin
  mystringlist := TStringList.Create;
  nodeStream := TMemoryStream.Create;
  if createXmlDocFromStringlist(docstrlist) then
    begin
      mynode := getXMLDoc.DocumentElement;
      try
        WriteXML(mynode, nodeStream);
        nodeStream.Position := 0;
        mystringlist.LoadFromStream(nodestream);
        Result := mystringlist;
      finally
        nodestream.Free;
        mynode.free;
        //mystringlist.Free;       muss bleiben, damit result bleibt
      end;
    end;
end;

function getDocNodeNameFromStringList(docstrlist: TStringList): string;
begin
  if createXmlDocFromStringlist(docstrlist) then
    if XMLexists then Result := getDocNodeName()
    else result:='';
  freeXmlDoc();
end;

function getDocNodeNameFromXMLDoc () : string;
begin
  if XMLexists then Result := getDocNodeName()
    else result:='';
end;

function getDocNodeType(docstrlist: TStringList): string;
begin
  Result:='';
  if createXmlDocFromStringlist(docstrlist) then
    Result := getNodeType(getXMLDoc.DocumentElement);
  freeXmlDoc();
end;

//*****************************************************************************
function appendXmlNodeToDocFromStringlist(docstrlist: TStringList;
  nodestrlist: TStringList; var strList: TStringList): boolean;
  // done -- erneutes erzeugen des XML-Dokuments????
var
  docstream: TMemoryStream;
  mynode: TDOMNode;
begin
  Result := False;
  if createXmlDocFromStringlist(docstrlist) then
    begin
      docstream := TMemoryStream.Create;
      try
        mynode:=createXMLNodeFromString(nodestrlist);
        getXMLDoc.DocumentElement.AppendChild(mynode);
        WriteXMLFile(getXMLDoc, docstream);
        docstream.Position := 0;
        strList := TStringList.Create;
        strList.LoadFromStream(docstream);
        Result := True;
      finally
        docstream.Free;
      end;
    end;
end;

// TODO
function appendXmlNodeToNodeFromStringlist(var nodestrlist1: TStringlist;
  nodestrlist2: TStringlist): boolean;
var mynode1,mynode2:TDOMNode;

begin
  Result:= false;
  try
    mynode1 := createXMLNodeFromString(nodestrlist1);
    mynode2 := createXMLNodeFromString(nodestrlist2);
    mynode1.AppendChild(mynode2);
    createStringListFromXMLNode(mynode1, nodestrlist1);
    result:=true;
  except
    //
  end;
  mynode1.Free;
  mynode2.Free;
end;
//************************************************************
// direkte node operation

function xmlAsStringlistSetNodevalue (var nodestrlist: TStringlist; value: String) :boolean;
var mynode: TDOMNode;
begin
  result:=false;
  try
    mynode := createXMLNodeFromString(nodestrlist);
    mynode.TextContent:=value;
    // nodestrlist.clear?
    if createStringListFromXMLNode(mynode, nodestrlist) then
      result:=true;
  except
    //
  end;
  mynode.Free;
end;
function xmlAsStringlistGetNodevalue (nodestrlist: TStringlist; var value: String) :boolean;
var mynode: TDOMNode;
begin
  result:=false;
  try
    mynode := createXMLNodeFromString(nodestrlist);
    value:=mynode.TextContent;
    result:=true;
  except
    //
  end;
  mynode.Free;
end;
function xmlAsStringlistGetNodeAttributeKeys (nodestrlist: TStringlist; var keylist: TStringlist) :boolean;
var mynode: TDOMNode;
begin
  result:=false;
  keylist:= TStringlist.Create;
  try
     mynode := createXMLNodeFromString(nodestrlist);
     keylist:= getAttributeKeylist(mynode);
     result:=true;
  except
    //
  end;
  mynode.Free;
end;
function xmlAsStringlistSetNodeattributeByKey (var nodestrlist: TStringlist; attributekey: String; value: String) :boolean;
// TODO
var mynode: TDOMNode;
begin
  result:=false;
end;

//************************************************************
// by index

function xmlAsStringlistGetChildnodeByIndex(nodestrlist: TStringList;
  index: integer; var Value: TStringList): boolean;
var mynode,newnode:TDOMNode;
begin
  result:=false;
  mynode := createXMLNodeFromString(nodestrlist);
  if getChildTDOMNodeByIndex(mynode, index, newnode) then
    if createStringListFromXMLNode(newnode, Value) then
    begin
      Result := True;
    end;
end;

function xmlAsStringlistGetChildnodeValueByIndex(mynodeAsStringlist: TStringList; index: integer;
  var Value: string): boolean;
// TODO
var
  mynode: TDOMNode;
begin
  result:=false;
  mynode:= createXMLNodeFromString(mynodeAsStringlist);
  if getChildTDOMNodeValueByIndex(mynode,index, value) then
    result:=true;
end;

function xmlAsStringlistSetChildnodeValueByIndex (var mynodeAsStringlist: TStringList;
  index: integer; value: string ): boolean;
var
  mynode: TDOMNode;
begin
  result:=false;
  mynode := createXMLNodeFromString(mynodeAsStringlist);
  if setChildTDOMNodeValueByIndex(mynode, index, value) then
    if createStringListFromXMLNode(mynode, mynodeAsStringlist) then
    begin
      Result := True;
    end;
end;

function xmlAsStringlistDeleteChildnodeByIndex(var mynodeAsStringlist: TStringList;
  index: integer): boolean;
var
  mynode: TDOMNode;
begin
  Result := False;
  mynode := createXMLNodeFromString(mynodeAsStringlist);
  if deleteChildTDOMNodeByIndex(mynode, index) then
    if createStringListFromXMLNode(mynode, mynodeAsStringlist) then
    begin
      Result := True;
    end;
end;

//************************************************************
// alle über name
function xmlAsStringlistGetUniqueChildnodeByName(nodestrlist: TStringList;
  Name: string; var childnodeSL: TStringList): boolean; ///
var
  mynode, newnode: TDOMNode;
begin
  Result := False;
  mynode := createXMLNodeFromString(nodestrlist);
  if getUniqueChildNodeByName(mynode, Name, newnode) then
    if createStringListFromXMLNode(newnode, childnodeSL) then
    begin
      Result := True;
      newnode.Free;
    end;
  mynode.Free;
end;

function xmlAsStringlistSetChildnodeByName(var nodestrlist: TStringList;
  NodeName: string; childnodeSL: TStringList): boolean;
var
  mynode, childnode: TDOMNode;

begin
  Result := False;
  mynode := createXMLNodeFromString(nodestrlist);
  childnode:= createXMLNodeFromString(childnodeSL);
  if setChildNodeByName(mynode, NodeName, childnode) then
    if createStringListFromXMLNode(mynode, nodestrlist) then
    begin
      Result := True;
    end;
   mynode.Free;
   childnode.Free;
end;

//************************************************************
// attributes
function xmlAsStringlistGetAttributesValueList(nodeAsStringlist: TStringList;
     var attributeValueList:TStringlist): boolean;
var mynode: TDOMNode;
begin
  result:=false;
  mynode := createXMLNodeFromString(nodeAsStringlist);
  if getAttributesValueList(mynode,attributeValueList) then
    begin
      result:=true;
    end;
  mynode.Free;
end;

function xmlAsStringlistdeleteChildAttributeByKey(var nodeAsStringlist: TStringList;
     attributekey: string) : boolean;
var mynode: TDOMNode;
begin
  result:=false;
  mynode := createXMLNodeFromString(nodeAsStringlist);
  if deleteChildAttributeByKey(mynode, attributekey) then
    if createStringListFromXMLNode(mynode,nodeAsStringlist) then
      result:= true;
  mynode.Free;
end;

function xmlAsStringlistGetChildAttributeValueByNameAndKey(nodeAsStringlist: TStringList;
  nodename:string; attributekey:string; var attributevalue:string) :boolean;
var mynode, newnode: TDOMNode;
begin
  result:=false;
  mynode := createXMLNodeFromString(nodeAsStringlist);
  if mynode.HasChildNodes then
    if getUniqueChildNodeByName(mynode,nodename,newnode) then
      if getChildAttributeValueTDOMNode(newnode,attributekey,attributevalue) then
        begin
          result:=true;
          newnode.Free;
        end;
  mynode.Free;
end;

function xmlAsStringlistSetChildAttributeValueByNameAndKey(var nodeAsStringlist: TStringList;
  nodename:string; attributekey:string; attributevalue:string) :boolean;
var mynode, newnode: TDOMNode;
begin
  result:=false;
  mynode := createXMLNodeFromString(nodeAsStringlist);
  if mynode.HasChildNodes then
    if getUniqueChildNodeByName(mynode,nodename,newnode) then
      if setChildAttributeValueTDOMNode(newnode,attributekey,attributevalue) then
         if createStringListFromXMLNode(mynode,nodeAsStringlist) then
           begin
            result:=true;
            newnode.Free;
           end;
  mynode.Free;
end;
//************************************************************
function xmlAsStringlistAllElementsCount(nodeAsStringlist: TStringList): integer;
var
  mynode: TDOMNode;
  teststrlst: TStringList;
begin
  Result := 0;
  teststrlst:= TStringlist.Create;
  try
    mynode := createXmlNodeFromString(nodeAsStringlist);
    if createStringListFromXMLNode(mynode, teststrlst) then
      Result := mynode.ChildNodes.Count;
  finally
    mynode.Free;
  end;
end;

function xmlAsStringlistElementsCount(nodeAsStringlist: TStringList): integer;
  //  only elements, no comments
var
  mynode: TDOMNode;
  i: integer;
begin
  Result := 0;
  try
    mynode := createXmlNodeFromString(nodeAsStringlist);
    with mynode.ChildNodes do
      for i := 0 to (Count - 1) do
        if (Item[i].NodeType <> COMMENT_NODE) then
          Result := Result + 1;
  finally
    mynode.Free;
  end;
end;

function xmlAsStringlistCommentElementsCount(nodeAsStringlist: TStringList): integer;
  //  only comments
var
  mynode: TDOMNode;
  i: integer;
begin
  Result := 0;
  try
    mynode := createXmlNodeFromString(nodeAsStringlist);
    with mynode.ChildNodes do
      for i := 0 to (Count - 1) do
        if (Item[i].NodeType = COMMENT_NODE) then
          Result := Result + 1;
  finally
    mynode.Free;
  end;
end;

function xmlAsStringlistHasChildNodes(nodeAsStringlist: TStringList): boolean;
var
  mynode: TDOMNode;
begin
  Result := False;
  try
    mynode := createXmlNodeFromString(nodeAsStringlist);
    if mynode.hasChildNodes then
        Result := True;
  finally
    mynode.Free;
  end;
end;

function xmlAsStringlistGetChildNodes(nodeAsStringlist: TStringList;
  var childnodes: TStringList): boolean;
var
  mynode: TDOMNode;
  i: integer;
  tempstrlist: TStringList;
begin
  Result := False;
  childnodes := TStringList.Create;
  try
    mynode := createXmlNodeFromString(nodeAsStringlist);
    with mynode.ChildNodes do
      for i := 0 to (Count - 1) do
        if createStringListFromXMLNode(Item[i], tempstrlist) then
        begin
          if tempstrlist.Count>0 then
            childnodes.Add(stringlistWithoutBreaks(tempstrlist).Text);
          tempstrlist.Clear;
        end;
    Result := True;
    mynode.Free;
  finally
    //
  end;
end;

function isValid(str: string): boolean;
  // TODO  - iss noch nix
var
  Parser: TDOMParser;
  Src: TXMLInputSource;
  TheDoc: TXMLDocument;
begin
  try
    Result := False;
    Parser := TDOMParser.Create;
    Src := TXMLInputSource.Create(str);
    Parser.Options.Validate := True;
    // Festlegen einer Methode, die bei Fehlern aufgerufen wird
    // Parser.OnError := @ErrorHandler;
    Parser.Parse(Src, TheDoc);
  finally
    Src.Free;
    Parser.Free;
  end;
end;


end.
