module MINI-SCHEMA-EDITOR-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Name ::= String
  syntax Names ::= ".Names" | Name ";" Names [right]
  syntax Decision ::= "none" | "delete" "(" Name ")" | "raise"
  syntax Stmt ::= "chooseUnique" "(" Bool "," Names "," Name ")"
                | "finishChoice" "(" Names ")"
  syntax KResult ::= Decision
endmodule

module MINI-SCHEMA-EDITOR
  imports MINI-SCHEMA-EDITOR-SYNTAX
  imports BOOL
  imports INT
  imports STRING
  imports K-EQUAL

  configuration
    <k> $PGM:Stmt </k>
    <decision> none </decision>

  syntax Int ::= len(Names) [function]
  rule len(.Names) => 0
  rule len(_N:Name ; NS:Names) => 1 +Int len(NS)

  syntax Names ::= preferDefault(Names, Name) [function]
  rule preferDefault(.Names, _D:Name) => .Names
  rule preferDefault(D:Name ; NS:Names, D) => D ; .Names
  rule preferDefault(N:Name ; NS:Names, D:Name) => preferDefault(NS, D)
    requires N =/=K D

  rule <k> chooseUnique(true, NS:Names, D:Name)
        => finishChoice(preferDefault(NS, D)) ... </k>
    requires len(NS) >Int 1

  rule <k> chooseUnique(true, NS:Names, _D:Name)
        => finishChoice(NS) ... </k>
    requires len(NS) <=Int 1

  rule <k> chooseUnique(false, NS:Names, _D:Name)
        => finishChoice(NS) ... </k>

  rule <k> finishChoice(N:Name ; .Names) => .K ... </k>
       <decision> none => delete(N) </decision>

  rule <k> finishChoice(.Names) => .K ... </k>
       <decision> none => raise </decision>

  rule <k> finishChoice(_N1:Name ; _N2:Name ; _REST:Names) => .K ... </k>
       <decision> none => raise </decision>
endmodule
