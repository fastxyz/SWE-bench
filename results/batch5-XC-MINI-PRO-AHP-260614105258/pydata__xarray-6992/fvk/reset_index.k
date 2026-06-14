// mini-Python (mini-X) fragment semantics for the *post-loop* core of
// Dataset.reset_index -- just enough to model the final set algebra that
// computes ``variables`` and ``coord_names``.
//
// The Python code being modelled (after the ``for name in dims_or_levels`` loop
// has produced the name-sets V, C, D, N) is straight-line:
//
//     variables   = {k: v for k, v in self._variables.items() if k not in D}
//     variables.update(new_variables)            # keys(variables) = (V - D) | N
//     coord_names = (self._coord_names - D) | N  # the fixed line
//     return coord_names <= keys(variables)      # the invariant we prove
//
// We abstract each mapping by its *key set* (a K builtin Set), because the
// invariant ``coord_names ⊆ keys(variables)`` only depends on the key sets, and
// because ``DataVariables.__len__`` is ``len(_variables) - len(_coord_names)``,
// a function of set cardinalities alone. Set values stand in for:
//     V = keys(self._variables), C = self._coord_names,
//     D = set(drop_variables),   N = set(new_variables)   (== keys(new_variables))
//
// MVP stopgap: this is a minimal fragment, not full Python-in-K. It covers only
// set difference, set union, subset, assignment, sequencing and return -- the
// constructs the modelled body actually uses. "Constructed, not machine-checked."

module RESET-INDEX-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports SET

  // Set-valued expressions.  A fully evaluated Set is itself an SExp value.
  syntax SExp ::= Id
                | Set
                | "(" SExp ")"        [bracket]
                > SExp "-" SExp       [seqstrict, left]   // set difference  (-Set)
                > SExp "|" SExp       [seqstrict, left]   // set union       (|Set)

  // Boolean-valued expressions.
  syntax BExp ::= Bool
                | SExp "<=" SExp      [seqstrict]         // subset test  (A ⊆ B)

  syntax Stmt ::= Id "=" SExp ";"     [strict(2)]
                | "return" BExp ";"   [strict]
                > Stmt Stmt           [left]

  syntax KResult ::= Set | Bool
endmodule

module RESET-INDEX
  imports RESET-INDEX-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports SET

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>     // Id |-> Set

  // variable lookup
  rule <k> X:Id => V ... </k> <store> ... X |-> V:Set ... </store>

  // set operators (value level; seqstrict supplies the heating/cooling)
  rule <k> S1:Set - S2:Set => S1 -Set S2 ... </k>
  rule <k> S1:Set | S2:Set => S1 |Set S2 ... </k>

  // subset A ⊆ B  encoded as  (A \ B) == ∅
  rule <k> S1:Set <= S2:Set => (S1 -Set S2) ==K .Set ... </k>

  // assignment and sequencing
  rule <k> X:Id = V:Set ; => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // return delivers the (boolean) result to the <k> cell
  rule <k> return B:Bool ; => B ... </k>
endmodule
