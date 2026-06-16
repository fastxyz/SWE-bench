module MINI-SPHINX-VERSION-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Needs ::= ".Needs"
                 | "need" "(" String "," String ")" ";" Needs [right]
  syntax Loaded ::= ".Loaded"
                  | "have" "(" String "," String ")" ";" Loaded [right]
  syntax Outcome ::= "normal"
                   | "warned" "(" String "," Outcome ")"
                   | "raised" "(" String "," String "," String ")"
endmodule

module MINI-SPHINX-VERSION
  imports MINI-SPHINX-VERSION-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= validVersion(String) [function]
  syntax Bool ::= versionGE(String, String) [function]
  syntax Bool ::= stringGE(String, String) [function]
  syntax Bool ::= needsSatisfied(String, String) [function]
  syntax Bool ::= hasExt(Loaded, String) [function]
  syntax String ::= lookupExt(Loaded, String) [function]
  syntax Outcome ::= verify(Needs, Loaded) [function]

  rule needsSatisfied(REQUIRED:String, LOADED:String) => versionGE(LOADED, REQUIRED)
    requires validVersion(REQUIRED) andBool validVersion(LOADED)

  rule needsSatisfied(REQUIRED:String, LOADED:String) => stringGE(LOADED, REQUIRED)
    requires notBool (validVersion(REQUIRED) andBool validVersion(LOADED))

  rule hasExt(.Loaded, NAME:String) => false
  rule hasExt(have(NAME:String, VERSION:String); REST:Loaded, NAME) => true
  rule hasExt(have(OTHER:String, VERSION:String); REST:Loaded, NAME:String) => hasExt(REST, NAME)
    requires OTHER =/=String NAME

  rule lookupExt(have(NAME:String, VERSION:String); REST:Loaded, NAME) => VERSION
  rule lookupExt(have(OTHER:String, VERSION:String); REST:Loaded, NAME:String) => lookupExt(REST, NAME)
    requires OTHER =/=String NAME

  rule verify(.Needs, LOADED:Loaded) => normal

  rule verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
    => warned(NAME, verify(REST, LOADED))
    requires notBool hasExt(LOADED, NAME)

  rule verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
    => raised(NAME, REQUIRED, "unknown version")
    requires hasExt(LOADED, NAME)
     andBool lookupExt(LOADED, NAME) ==String "unknown version"

  rule verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
    => raised(NAME, REQUIRED, lookupExt(LOADED, NAME))
    requires hasExt(LOADED, NAME)
     andBool lookupExt(LOADED, NAME) =/=String "unknown version"
     andBool notBool needsSatisfied(REQUIRED, lookupExt(LOADED, NAME))

  rule verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
    => verify(REST, LOADED)
    requires hasExt(LOADED, NAME)
     andBool lookupExt(LOADED, NAME) =/=String "unknown version"
     andBool needsSatisfied(REQUIRED, lookupExt(LOADED, NAME))
endmodule
