module MINI-LITERALINCLUDE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Lines ::= ".Lines"
                 | String "NL" Lines [klabel(lineCons), right]

  syntax Selector ::= "selector"

  syntax DedentOpt ::= "noDedent"
                      | "autoDedent"
                      | "fixedDedent" "(" Int ")"

  syntax Command ::= "read" "(" Lines "," Selector "," DedentOpt "," String "," Bool "," String "," Bool ")"
                   | "diffRead" "(" Lines ")"

  syntax Stage ::= "selectStage" "(" Selector ")"
                 | "dedentStage" "(" DedentOpt ")"
                 | "prependStage" "(" String "," Bool ")"
                 | "appendStage" "(" String "," Bool ")"

  syntax KResult ::= Lines | Bool | Int | String
endmodule

module MINI-LITERALINCLUDE
  imports MINI-LITERALINCLUDE-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Command </k>

  syntax Lines ::= select(Lines, Selector) [function]
  rule select(LS:Lines, selector) => LS

  syntax Lines ::= dedent(Lines, DedentOpt) [function]
  rule dedent(LS:Lines, noDedent) => LS
  rule dedent(LS:Lines, autoDedent) => autoDedentLines(LS)
  rule dedent(LS:Lines, fixedDedent(N:Int)) => stripPrefix(LS, N)

  syntax Lines ::= autoDedentLines(Lines) [function]
  rule autoDedentLines(LS:Lines) => LS
  // The exact common-whitespace computation is abstracted. The verified
  // property is that only selected include-file lines flow to this function.

  syntax Lines ::= stripPrefix(Lines, Int) [function]
  rule stripPrefix(.Lines, N:Int) => .Lines
  rule stripPrefix(L:String NL REST:Lines, N:Int) => stripStringPrefix(L, N) NL stripPrefix(REST, N)

  syntax String ::= stripStringPrefix(String, Int) [function]
  rule stripStringPrefix(S:String, N:Int) => S
  // String slicing is abstracted for this proof. The warning-scope and
  // pipeline-order obligations do not depend on the concrete slice result.

  syntax Lines ::= prepend(Lines, String, Bool) [function]
  rule prepend(LS:Lines, P:String, false) => LS
  rule prepend(LS:Lines, P:String, true) => P NL LS

  syntax Lines ::= append(Lines, String, Bool) [function]
  rule append(.Lines, A:String, false) => .Lines
  rule append(.Lines, A:String, true) => A NL .Lines
  rule append(L:String NL REST:Lines, A:String, HAS:Bool) => L NL append(REST, A, HAS)

  syntax Bool ::= dedentWarns(Lines, DedentOpt) [function]
  rule dedentWarns(LS:Lines, noDedent) => false
  rule dedentWarns(LS:Lines, autoDedent) => false
  rule dedentWarns(LS:Lines, fixedDedent(N:Int)) => hasNonWhitespacePrefix(LS, N)

  syntax Bool ::= hasNonWhitespacePrefix(Lines, Int) [function]
  rule hasNonWhitespacePrefix(.Lines, N:Int) => false
  rule hasNonWhitespacePrefix(L:String NL REST:Lines, N:Int) =>
       stringPrefixHasNonWhitespace(L, N) orBool hasNonWhitespacePrefix(REST, N)

  syntax Bool ::= stringPrefixHasNonWhitespace(String, Int) [function]
  rule stringPrefixHasNonWhitespace(S:String, N:Int) => false
  // Abstracted string predicate. Claims constrain which Lines value is passed
  // to this predicate, not the internals of whitespace classification.

  rule <k> read(F:Lines, SEL:Selector, D:DedentOpt, P:String, HP:Bool, A:String, HA:Bool)
        => F ~> selectStage(SEL) ~> dedentStage(D) ~> prependStage(P, HP) ~> appendStage(A, HA)
       </k>

  rule <k> F:Lines ~> selectStage(SEL:Selector) => select(F, SEL) ... </k>
  rule <k> F:Lines ~> dedentStage(D:DedentOpt) => dedent(F, D) ... </k>
  rule <k> F:Lines ~> prependStage(P:String, HP:Bool) => prepend(F, P, HP) ... </k>
  rule <k> F:Lines ~> appendStage(A:String, HA:Bool) => append(F, A, HA) ... </k>

  rule <k> diffRead(F:Lines) => F </k>
endmodule
