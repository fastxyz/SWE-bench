module MINI-SYMBOL-CONVENTIONS-SYNTAX
  imports BOOL-SYNTAX

  syntax Name
  syntax Name ::= "concat" "(" Name "," Name ")" [function]

  syntax SplitResult ::= "NoSplit" "(" Name ")"
                       | "Split" "(" Name "," Name ")"

  syntax Exp ::= "applyNameWithDigits" "(" Name ")"

  syntax KResult ::= SplitResult
endmodule

module MINI-SYMBOL-CONVENTIONS
  imports MINI-SYMBOL-CONVENTIONS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= "isBaseRun" "(" Name ")"       [function]
                | "isAsciiDigitRun" "(" Name ")" [function]
                | "isNameDigits" "(" Name ")"    [function]

  // Abstract model of Python regex ^([^\W\d_]+)([0-9]+)$.
  // isBaseRun(B) denotes a non-empty run of Unicode word chars excluding
  // digits and underscore. isAsciiDigitRun(D) denotes non-empty [0-9]+.
  rule isNameDigits(concat(B:Name, D:Name)) => true
    requires isBaseRun(B) andBool isAsciiDigitRun(D)

  rule <k> applyNameWithDigits(concat(B:Name, D:Name)) => Split(B, D) </k>
    requires isBaseRun(B) andBool isAsciiDigitRun(D)

  rule <k> applyNameWithDigits(N:Name) => NoSplit(N) </k>
    requires notBool isNameDigits(N)
endmodule
