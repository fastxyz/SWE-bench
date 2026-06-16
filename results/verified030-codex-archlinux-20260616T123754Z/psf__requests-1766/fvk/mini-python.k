module MINI-PYTHON-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax QopInput  ::= "noQop" | "qopOptions" "(" List ")"
  syntax QopResult ::= "qopResult" "(" String "," String ")"
                     | "unsupportedQop"
  syntax Stmt      ::= "buildDigestQop" "(" QopInput ")"
  syntax KResult   ::= QopResult
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL
  imports LIST
  imports STRING

  configuration <k> $PGM:Stmt </k>

  syntax Bool ::= containsAuth(List) [function]
  rule containsAuth(.List) => false
  rule containsAuth(ListItem("auth") REST:List) => true
  rule containsAuth(ListItem(Q:String) REST:List) => containsAuth(REST)
    requires Q =/=K "auth"

  rule <k> buildDigestQop(noQop) => qopResult("", "") </k>

  rule <k> buildDigestQop(qopOptions(QOPS:List))
        => qopResult("qop=\"auth\"", "auth") </k>
    requires containsAuth(QOPS)

  rule <k> buildDigestQop(qopOptions(QOPS:List))
        => unsupportedQop </k>
    requires notBool containsAuth(QOPS)
endmodule

