module MINI-ROC-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Score ::= "Inf"
                 | "finite" "(" Int ")"

  syntax Scores ::= ".Scores"
                  | Score ";" Scores [right]

  syntax Exp ::= "prependStart" "(" Scores ")"
               | "legacyPrependPlusOne" "(" Score "," Scores ")"
               | "clipPrependOne" "(" Scores ")"

  syntax KResult ::= Score | Scores
endmodule

module MINI-ROC
  imports MINI-ROC-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> prependStart(TS:Scores) => Inf ; TS ... </k>

  rule <k> legacyPrependPlusOne(finite(M:Int), TS:Scores)
        => finite(M +Int 1) ; finite(M) ; TS ... </k>

  rule <k> clipPrependOne(TS:Scores) => finite(1) ; TS ... </k>
endmodule
