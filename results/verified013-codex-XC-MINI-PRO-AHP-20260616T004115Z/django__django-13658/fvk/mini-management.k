module MINI-MANAGEMENT-SYNTAX
  imports STRING-SYNTAX

  syntax MaybeString ::= "none" | "some" "(" String ")"
  syntax Pgm ::= "mgmtPreparse" "(" String "," String ")"
               | "optionPreparse" "(" MaybeString "," String ")"
  syntax KResult ::= MaybeString
endmodule

module MINI-MANAGEMENT
  imports MINI-MANAGEMENT-SYNTAX
  imports STRING

  configuration
    <k> $PGM:Pgm </k>
    <parserProg> none </parserProg>

  syntax String ::= mgmtProg(String) [function]
                  | helperProg(MaybeString) [function]

  rule mgmtProg("__main__.py") => "python -m django"
  rule mgmtProg(P:String) => P requires P =/=String "__main__.py" [owise]

  rule helperProg(some(P:String)) => P
  rule helperProg(none) => ""

  rule <k> mgmtPreparse(ARGV_PROG:String, SYS_PROG:String) => .K </k>
       <parserProg> _ => some(mgmtProg(ARGV_PROG)) </parserProg>

  rule <k> optionPreparse(ARGV_PROG:MaybeString, SYS_PROG:String) => .K </k>
       <parserProg> _ => some(helperProg(ARGV_PROG)) </parserProg>
endmodule
