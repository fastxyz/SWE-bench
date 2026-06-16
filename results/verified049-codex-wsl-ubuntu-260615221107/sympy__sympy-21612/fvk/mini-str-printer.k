module MINI-STR-PRINTER-SYNTAX
  imports INT-SYNTAX

  syntax Kind ::= "atomK" | "addK" | "mulK" | "powK"

  syntax Text ::= "oneText"
                | "symA"
                | "symB"
                | "symX"
                | "symY"
                | "yTimesY"
                | "fracNumer"
                | "cSquared"
                | "parenText" "(" Text ")"
                | "slashText" "(" Text "," Text ")"

  syntax Base ::= "base" "(" Kind "," Int "," Text ")"
  syntax Factor ::= "reciprocal" "(" Base ")"
  syntax Command ::= "printMul" "(" Text "," Factor ")"
  syntax KResult ::= Text
endmodule

module MINI-STR-PRINTER
  imports MINI-STR-PRINTER-SYNTAX
  imports INT

  configuration <k> $PGM:Command </k>

  syntax Text ::= "denomText" "(" Base ")" [function]

  rule <k> printMul(N, reciprocal(B)) => slashText(N, denomText(B)) </k>

  // This is the V1 behavior: compound Mul and Pow denominator bases are
  // explicitly wrapped before they become the denominator of the outer slash.
  rule denomText(base(mulK, A, T)) => parenText(T) requires A =/=Int 1
  rule denomText(base(powK, A, T)) => parenText(T) requires A =/=Int 1

  // Singleton or non-target bases are already handled by ordinary precedence
  // printing in the real StrPrinter path.
  rule denomText(base(mulK, 1, T)) => T
  rule denomText(base(powK, 1, T)) => T
  rule denomText(base(atomK, A, T)) => T
  rule denomText(base(addK, A, T)) => T
endmodule
