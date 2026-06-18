module MINI-SYMPY-RELATIONAL-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Sym ::= Id

  // Period classes used by Boolean.as_set's public routing.
  syntax Period ::= nonPeriodic | zeroPeriod | periodic

  // Abstract result of solve_univariate_inequality(..., relational=False).
  syntax SolverOutcome ::= exact(Set) | cannotSolve

  // A univariate relational is modeled by its single symbol, periodicity
  // class, and solver outcome. The relational condition itself is preserved
  // inside conditionSet.
  syntax Rel ::= rel(Sym, Period, SolverOutcome)

  syntax Set ::= reals
               | emptySet
               | universalSet
               | finiteSet(Sym)
               | interval(Sym, Sym)
               | exactSet(Id)
               | conditionSet(Sym, Rel, Set)

  syntax Result ::= ret(Set) | raisesNotImplemented
  syntax KResult ::= Result

  syntax KItem ::= relEvalAsSet(Rel)
                 | boolAsSet(Rel)

  syntax Bool ::= isTrivialPeriodicSet(Set) [function]
endmodule

module MINI-SYMPY-RELATIONAL
  imports MINI-SYMPY-RELATIONAL-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  rule isTrivialPeriodicSet(reals) => true
  rule isTrivialPeriodicSet(emptySet) => true
  rule isTrivialPeriodicSet(universalSet) => true
  rule isTrivialPeriodicSet(finiteSet(_)) => false
  rule isTrivialPeriodicSet(interval(_, _)) => false
  rule isTrivialPeriodicSet(exactSet(_)) => false
  rule isTrivialPeriodicSet(conditionSet(_, _, _)) => false

  // Relational._eval_as_set(): successful solver result is returned unchanged.
  rule <k> relEvalAsSet(rel(X, P, exact(S))) => ret(S) ... </k>

  // Relational._eval_as_set(): solver incompleteness is represented as an
  // unevaluated real ConditionSet.
  rule <k> relEvalAsSet(rel(X, P, cannotSolve))
        => ret(conditionSet(X, rel(X, P, cannotSolve), reals)) ... </k>

  // Boolean.as_set(): for non-periodic or zero-period univariate relationals,
  // delegate to the relational set conversion.
  rule <k> boolAsSet(rel(X, nonPeriodic, O))
        => relEvalAsSet(rel(X, nonPeriodic, O)) ... </k>
  rule <k> boolAsSet(rel(X, zeroPeriod, O))
        => relEvalAsSet(rel(X, zeroPeriod, O)) ... </k>

  // Boolean.as_set(): periodic relationals are only accepted here when the
  // relational conversion collapses to a whole/trivial set.
  rule <k> boolAsSet(rel(X, periodic, exact(S))) => ret(S) ... </k>
    requires isTrivialPeriodicSet(S)
  rule <k> boolAsSet(rel(X, periodic, exact(S))) => raisesNotImplemented ... </k>
    requires notBool isTrivialPeriodicSet(S)
  rule <k> boolAsSet(rel(X, periodic, cannotSolve)) => raisesNotImplemented ... </k>
endmodule
