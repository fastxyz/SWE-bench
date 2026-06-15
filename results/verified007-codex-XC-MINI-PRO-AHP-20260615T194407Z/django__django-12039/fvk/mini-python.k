module MINI-PYTHON-SYNTAX
  imports STRING-SYNTAX

  syntax Pgm ::= quote(String)
               | emitPlain(String, String)
               | emitIndex(String, String, String)

  syntax KResult ::= String
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Pgm </k>

  rule <k> quote(C:String) => "\"" +String C +String "\"" </k>

  rule <k> emitPlain(C:String, "") => "\"" +String C +String "\"" </k>
  rule <k> emitPlain(C:String, S:String)
        => "\"" +String C +String "\"" +String " " +String S
       </k>
    requires S =/=String ""

  rule <k> emitIndex(C:String, O:String, "")
        => "\"" +String C +String "\"" +String " " +String O
       </k>
    requires O =/=String ""

  rule <k> emitIndex(C:String, O:String, S:String)
        => "\"" +String C +String "\"" +String " " +String O +String " " +String S
       </k>
    requires O =/=String "" andBool S =/=String ""
endmodule
