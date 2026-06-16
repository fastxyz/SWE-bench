module MINI-CPP-LITERALS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Kind ::= "num" | "str" | "chr"
  syntax Command ::= parse(Kind, String, String, String)
  syntax Parsed ::= parsed(Kind, String, String, String)
  syntax KResult ::= Parsed

  syntax Bool ::= isCore(Kind, String) [function]
  syntax Bool ::= isUdlSuffix(String) [function]
endmodule

module MINI-CPP-LITERALS
  imports MINI-CPP-LITERALS-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Command </k>

  // Abstract parser transition for the source-level behavior:
  // parse(kind, core, suffix, rest) consumes suffix iff it is a valid
  // immediate UDL suffix and leaves the following input `rest` untouched.
  rule <k> parse(K:Kind, CORE:String, SUFFIX:String, REST:String)
        => parsed(K, CORE +String SUFFIX, SUFFIX, REST) </k>
    requires isCore(K, CORE) andBool isUdlSuffix(SUFFIX)

  rule <k> parse(K:Kind, CORE:String, "", REST:String)
        => parsed(K, CORE, "", REST) </k>
    requires isCore(K, CORE)
endmodule
