module MINI-SQLITE-CHECK-CONSTRAINTS-SYNTAX
  imports BOOL-SYNTAX

  syntax Name ::= "kw" [klabel(KW)]
                | "nonkw" [klabel(NONKW)]

  syntax Ident ::= "raw" "(" Name ")" [klabel(raw)]
                 | "quoted" "(" Name ")" [klabel(quoted)]

  syntax Result ::= "OK" [klabel(OK)]
                  | "ERR" [klabel(ERR)]
                  | Result "andThen" Result [function, left, klabel(andThen)]
                  | "parseIdent" "(" Ident ")" [function, klabel(parseIdent)]
                  | "quote" "(" Name ")" [function, klabel(quote)]
                  | "checkFK" "(" Ident ")" [function, klabel(checkFK)]
                  | "checkFKList" "(" Ident ")" [function, klabel(checkFKList)]
                  | "checkSelect" "(" Ident "," Ident "," Ident ")" [function, klabel(checkSelect)]
                  | "preNoViolation" "(" Name ")" [function, klabel(preNoViolation)]
                  | "v1NoViolation" "(" Name ")" [function, klabel(v1NoViolation)]
                  | "v1WithViolation" "(" Name "," Name "," Name ")" [function, klabel(v1WithViolation)]
endmodule

module MINI-SQLITE-CHECK-CONSTRAINTS
  imports MINI-SQLITE-CHECK-CONSTRAINTS-SYNTAX

  configuration <k> $PGM:Result </k>

  rule quote(N:Name) => quoted(N)

  rule parseIdent(raw(kw)) => ERR
  rule parseIdent(raw(nonkw)) => OK
  rule parseIdent(quoted(_:Name)) => OK

  rule OK andThen R:Result => R
  rule ERR andThen _:Result => ERR

  rule checkFK(I:Ident) => parseIdent(I)
  rule checkFKList(I:Ident) => parseIdent(I)
  rule checkSelect(T:Ident, PK:Ident, FK:Ident) =>
    parseIdent(T) andThen parseIdent(PK) andThen parseIdent(FK)

  // Pre-fix behavior: table names were interpolated raw.
  rule preNoViolation(N:Name) => checkFK(raw(N))

  // V1 behavior: all SQL identifiers reachable in the audited branch are quoted.
  rule v1NoViolation(N:Name) => checkFK(quote(N))
  rule v1WithViolation(T:Name, PK:Name, FK:Name) =>
    checkFK(quote(T))
    andThen checkFKList(quote(T))
    andThen checkSelect(quote(T), quote(PK), quote(FK))
endmodule
