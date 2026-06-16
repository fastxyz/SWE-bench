module MINI-SYMPY-AS-SET-SYNTAX
  imports ID-SYNTAX

  syntax Domain ::= "Reals"
  syntax Rel ::= rel(Id)
  syntax Set ::= solverSet(Id) | conditionSet(Id, Rel, Domain)
  syntax MaybeSet ::= noSet | some(Set)
  syntax SolverOutcome ::= solved(Set) | notImplemented
  syntax Exception ::= none | notImplementedError
  syntax Cmd ::= evalAsSet(Rel, SolverOutcome)
  syntax KResult ::= Set | MaybeSet | Exception
endmodule

module MINI-SYMPY-AS-SET
  imports MINI-SYMPY-AS-SET-SYNTAX

  configuration
    <k> $PGM:Cmd </k>
    <result> noSet </result>
    <exception> none </exception>

  rule
    <k> evalAsSet(R:Rel, solved(S:Set)) => .K </k>
    <result> noSet => some(S) </result>
    <exception> _ => none </exception>

  rule
    <k> evalAsSet(rel(X:Id), notImplemented) => .K </k>
    <result> noSet => some(conditionSet(X, rel(X), Reals)) </result>
    <exception> _ => none </exception>
endmodule
