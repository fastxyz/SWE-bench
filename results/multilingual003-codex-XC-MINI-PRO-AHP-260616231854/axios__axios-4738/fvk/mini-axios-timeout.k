module MINI-AXIOS-TIMEOUT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Custom ::= "noCustom" | "someCustom" "(" String ")"
  syntax Code ::= "ECONNABORTED" | "ETIMEDOUT"
  syntax Msg ::= "defaultMsg" "(" Int ")" | "customMsg" "(" String ")"
  syntax Rejected ::= "none" | "rejected" "(" Msg "," Code ")"
  syntax Stmt ::= "handleTimeout"
  syntax KResult ::= Custom | Code | Msg | Rejected
endmodule

module MINI-AXIOS-TIMEOUT
  imports MINI-AXIOS-TIMEOUT-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Stmt </k>
    <timeout> 0 </timeout>
    <custom> noCustom </custom>
    <clarify> false </clarify>
    <aborted> false </aborted>
    <rejected> none </rejected>

  syntax Msg ::= "chooseMsg" "(" Int "," Custom ")" [function]
  syntax Code ::= "chooseCode" "(" Bool ")" [function]

  rule chooseMsg(T:Int, someCustom(M:String)) => customMsg(M)
  rule chooseMsg(T:Int, noCustom) => defaultMsg(T)
  rule chooseCode(true) => ETIMEDOUT
  rule chooseCode(false) => ECONNABORTED

  rule
    <k> handleTimeout => .K </k>
    <timeout> T:Int </timeout>
    <custom> C:Custom </custom>
    <clarify> CL:Bool </clarify>
    <aborted> false => true </aborted>
    <rejected> none => rejected(chooseMsg(T, C), chooseCode(CL)) </rejected>
    requires T >Int 0
endmodule
