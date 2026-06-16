module MINI-PYLINT-CONFIG-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax String ::= join(String, String) [function]
  syntax Exp ::= resolveHome(Bool, String, String, Bool, String)
               | defaultHome(String, Bool, String)
               | mkdirsIfMissing(String, Bool)
  syntax KResult ::= String
endmodule

module MINI-PYLINT-CONFIG
  imports MINI-PYLINT-CONFIG-SYNTAX
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Exp </k>
    <created> false </created>
    <createdPath> "" </createdPath>

  rule join(BASE:String, CHILD:String) => BASE +String "/" +String CHILD

  rule <k> resolveHome(true, PYLINTHOME:String, HOME:String, XDGVALID:Bool, XDG:String)
        => PYLINTHOME ... </k>
  rule <k> resolveHome(false, PYLINTHOME:String, HOME:String, XDGVALID:Bool, XDG:String)
        => defaultHome(HOME, XDGVALID, XDG) ... </k>

  rule <k> defaultHome("~", XDGVALID:Bool, XDG:String) => ".pylint.d" ... </k>
  rule <k> defaultHome(HOME:String, true, XDG:String) => join(XDG, "pylint") ... </k>
    requires HOME =/=String "~"
  rule <k> defaultHome(HOME:String, false, XDG:String)
        => join(join(HOME, ".cache"), "pylint") ... </k>
    requires HOME =/=String "~"

  rule <k> mkdirsIfMissing(PATH:String, true) => PATH ... </k>
       <created> CREATED:Bool => true </created>
       <createdPath> CREATEDPATH:String => PATH </createdPath>
  rule <k> mkdirsIfMissing(PATH:String, false) => PATH ... </k>
       <created> CREATED:Bool => false </created>
       <createdPath> CREATEDPATH:String => "" </createdPath>
endmodule
