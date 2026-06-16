module MINI-COPY-ROUTING-SYNTAX
  imports BOOL-SYNTAX

  syntax CopyArg ::= "None" | Bool
  syntax CopyPair ::= "(" Bool "," Bool ")"
  syntax Route ::= "fitRoute" "(" Bool "," CopyArg ")"
  syntax KResult ::= CopyPair
endmodule

module MINI-COPY-ROUTING
  imports MINI-COPY-ROUTING-SYNTAX
  imports BOOL

  configuration <k> $PGM:Route </k>

  rule <k> fitRoute(SelfCopy:Bool, None) => (SelfCopy, SelfCopy) </k>
  rule <k> fitRoute(_:Bool, FitCopy:Bool) => (FitCopy, FitCopy) </k>
endmodule
