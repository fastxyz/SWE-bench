// ===========================================================================
// mini-py-converters.k  —  a "mini-X" K fragment for the V1 fix of
// django__django-14007 (SQLInsertCompiler.execute_sql converter application).
//
// STATUS: constructed, NOT machine-checked (FVK MVP — no kompile/kprove run).
//
// Scope: this fragment models ONLY the constructs the fixed code path uses, in
// the *eager* form actually evaluated by the caller, i.e.
//     list(self.apply_converters(rows, converters))
// composed under get_converters / execute_sql's branch selection.
//
// The generator `yield` in the real apply_converters is modelled by an
// accumulate-into-a-result-list loop, because the only caller wraps the
// generator in list(...) (compiler.py:  rows = list(self.apply_converters(...))).
// That is observationally equivalent and is the form we verify.
//
// KEY MODELLING CHOICE — converters are UNINTERPRETED.  A database converter
// `f(value, expression, connection)` is an arbitrary function (from_db_value, a
// backend converter, …).  We therefore model converter application as an opaque
// *constructor* `applyC(F,V,E,C)` with NO rewrite rule: both the executing code
// and the specification build up the *same* applyC(...) terms, so correctness
// reduces to structural fold-equality, with no arithmetic VC.  The only side
// conditions are index-in-range and position-distinctness (see -spec.k).
// ===========================================================================

module MINI-PY-CONVERTERS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  // ---- expressions the fragment actually uses -----------------------------
  syntax Exp ::= Id | Int
               | "list" "(" Exp ")"          [strict]   // shallow copy of a row -> fresh List
               | Exp "[" Exp "]"             [seqstrict] // subscript read  row[pos]
               | applyC "(" Exp "," Exp "," Exp ")" [strict] // opaque converter call
               | chainHd "(" Exp ")"         [strict]    // first converter of a chain (head)
               | chainTl "(" Exp ")"         [strict]    // remaining converters (tail)
               | isEmpty "(" Exp ")"         [strict]    // chain/list emptiness test
               | entPos "(" Exp ")"          [strict]    // entry -> position (Int)
               | entConvs "(" Exp ")"        [strict]    // entry -> converter chain (List)
               | entExpr "(" Exp ")"         [strict]    // entry -> expression (Opaque)

  // opaque values: converter functions, expressions, connection, db values
  syntax Opaque
  // a converters-entry: (position, converter-chain, expression) == one (pos,(convs,expression))
  syntax Entry ::= entry(Int, List, Opaque)
  syntax Val ::= Int | Opaque | List | Entry
  syntax KResult ::= Val

  // ---- statements ---------------------------------------------------------
  syntax Stmt ::= Id "=" Exp                 [strict(2)] // assignment
                | Exp "[" Exp "]" "=" Exp     [seqstrict] // subscript store  row[pos] = v
                | "append" "(" Id "," Exp ")" [strict(2)] // result.append(row)
                | "for" Id "in" Exp ":" Stmt  [strict(2)] // for x in <list>: body
                | "return" Exp               [strict]
                | Stmt Stmt                  [left]
endmodule

module MINI-PY-CONVERTERS
  imports MINI-PY-CONVERTERS-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>          // Id |-> Val

  // ---- variable lookup ----------------------------------------------------
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>

  // ---- assignment ---------------------------------------------------------
  rule <k> X:Id = V:Val => .K ... </k> <store> STORE => STORE [ X <- V ] </store>

  // ---- list(row): shallow copy of a List value ----------------------------
  // copying matters: apply_converters mutates `row`, never the source `rows`.
  rule <k> list( L:List ) => L ... </k>           // List is a value sort: copy == identity

  // ---- subscript read:  L[I] ---------------------------------------------
  rule <k> L:List [ I:Int ] => L[I] ... </k>
    requires 0 <=Int I andBool I <Int size(L)

  // ---- subscript store:  X[I] = V  (X is an Id holding a List) ------------
  // NOTE evaluation: in `Exp[Exp] = Exp`, the seqstrict on the *read* form is
  //   reused for the index; the base object stays an Id so we can rebind it.
  rule <k> X:Id [ I:Int ] = V:Val => .K ... </k>
       <store> ... X |-> (L:List => L [ I <- V ]) ... </store>
    requires 0 <=Int I andBool I <Int size(L)

  // ---- result.append(v) ---------------------------------------------------
  rule <k> append( X:Id , V:Val ) => .K ... </k>
       <store> ... X |-> (L:List => L ListItem(V)) ... </store>

  // ---- for x in <list> : body  (desugar to an internal #forLoop) ----------
  syntax Stmt ::= "#forLoop" "(" Id "," List "," Stmt ")"
  rule <k> for X:Id in L:List : S => #forLoop(X, L, S) ... </k>
  rule <k> #forLoop(_, .List, _) => .K ... </k>
  rule <k> #forLoop(X:Id, ListItem(V:Val) Rest:List, S)
        => (X = V) ~> S ~> #forLoop(X, Rest, S) ... </k>

  // ---- statement sequencing ----------------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // ---- return -------------------------------------------------------------
  rule <k> return V:Val => V ... </k>

  // ---- chain / entry accessors (structural, total on well-formed inputs) --
  // a converter chain is a List of opaque converters; chainHd/chainTl split it.
  rule <k> chainHd( ListItem(F:Val) _:List ) => F ... </k>
  rule <k> chainTl( ListItem(_:Val) Rest:List ) => Rest ... </k>
  rule <k> isEmpty( .List ) => true  ... </k>
  rule <k> isEmpty( ListItem(_) _ ) => false ... </k>

  // an entry bundles (position, converter-chain, expression); accessors read it.
  rule <k> entPos(   entry(P:Int, _, _) ) => P  ... </k>
  rule <k> entConvs( entry(_, CL:List, _) ) => CL ... </k>
  rule <k> entExpr(  entry(_, _, E:Opaque) ) => E ... </k>

  // applyC has NO evaluation rule: it is the opaque converter-application term.
endmodule
