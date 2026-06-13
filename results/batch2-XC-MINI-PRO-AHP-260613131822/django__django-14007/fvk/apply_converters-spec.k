// ===========================================================================
// mini-py-converters-spec.k  —  reachability claims for the V1 fix.
// STATUS: constructed, NOT machine-checked (FVK MVP).
//
// Four claims, all [all-path]:
//   (CHAIN) inner loop  — folds a converter chain over a single value.
//   (ROW)   middle loop — converts one row at the converter positions (uses CHAIN).
//   (ROWS)  outer loop  — converts every row (uses ROW).
//   (APPLY) function    — list(apply_converters(rows, converters)) (uses ROWS).
//
// Because converters are UNINTERPRETED (applyC has no rule), every postcondition
// is a pure structural fold; there are NO nonlinear arithmetic VCs.  The only
// side conditions are index-in-range facts, discharged by Z3, plus the builtin
// list-update length lemma and List associativity.
// ===========================================================================

requires "apply_converters.k"

module MINI-PY-CONVERTERS-SPEC-SYNTAX
  imports MINI-PY-CONVERTERS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-PY-CONVERTERS-SPEC-SYNTAX
  imports MINI-PY-CONVERTERS
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ---- spec-only fold functions (the "closed forms") ----------------------

  // applyChain(convs, v, e, c): apply each converter in `convs` left-to-right.
  syntax Val ::= applyChain(List, Val, Opaque, Opaque) [function]
  rule applyChain(.List, V, _, _) => V
  rule applyChain(ListItem(F:Opaque) Rest:List, V, E, C)
    => applyChain(Rest, applyC(F, V, E, C), E, C)

  // convertRow(row, entries, conn): apply each entry's chain at its position.
  syntax List ::= convertRow(List, List, Opaque) [function]
  rule convertRow(R, .List, _) => R
  rule convertRow(R, ListItem(entry(P:Int, CL:List, E:Opaque)) Rest:List, C)
    => convertRow(R [ P <- applyChain(CL, R[P], E, C) ], Rest, C)
    requires 0 <=Int P andBool P <Int size(R)

  // convertRows(rows, entries, conn): convert every row independently.
  syntax List ::= convertRows(List, List, Opaque) [function]
  rule convertRows(.List, _, _) => .List
  rule convertRows(ListItem(R0:List) Rest:List, CVS, C)
    => ListItem(convertRow(R0, CVS, C)) convertRows(Rest, CVS, C)

  // ---- domain predicates --------------------------------------------------

  // every entry position lies in [0, N)
  syntax Bool ::= positionsInRange(List, Int) [function]
  rule positionsInRange(.List, _) => true
  rule positionsInRange(ListItem(entry(P:Int, _, _)) Rest:List, N)
    => (0 <=Int P andBool P <Int N) andBool positionsInRange(Rest, N)

  // every row is long enough for every entry position
  syntax Bool ::= allRowsPositionsInRange(List, List) [function]
  rule allRowsPositionsInRange(.List, _) => true
  rule allRowsPositionsInRange(ListItem(R:List) Rest:List, CVS)
    => positionsInRange(CVS, size(R)) andBool allRowsPositionsInRange(Rest, CVS)

  // ---- simplification lemmas (the VC oracle) ------------------------------
  // a functional list update preserves length (needed so positionsInRange
  // survives the row[P]=value store in the ROW loop).
  rule size(L:List [ _:Int <- _:Val ]) => size(L) [simplification]
  // (List concatenation associativity + .List unit are builtin in K's LIST,
  //  so the outer-loop accumulator regrouping needs no explicit lemma.)
endmodule

module MINI-PY-CONVERTERS-SPEC
  imports VERIFICATION

  // ======================================================================
  // (CHAIN) inner loop: fold the converter chain CL over `value`.
  //   for conv in <CL> : value = conv(value, expression, connection)
  // generalized over the running value V and the (suffix) chain CL; `expression`
  // and `connection` are the per-entry opaque values held fixed during the loop.
  // ======================================================================
  claim
    <k> #forLoop( conv ,
                  CL:List ,
                  value = applyC( conv , value , expression , connection ) )
        => .K ... </k>
    <store>
      value      |-> ( V:Val => applyChain(CL, V, E, Cn) )
      expression |-> E:Opaque
      connection |-> Cn:Opaque
      conv       |-> ( _:Val => ?_:Val )
    </store>
    [all-path]

  // ======================================================================
  // (ROW) middle loop: convert one row at every entry position.  The loop body
  // models the real code's tuple unpacking `for pos, (convs, expression) in
  // converters:` as three binds, so the inner loop matches (CHAIN) verbatim.
  //   for ent in <CVS> :
  //       pos = entPos(ent); convs = entConvs(ent); expression = entExpr(ent)
  //       value = row[pos]
  //       for conv in convs : value = applyC(conv, value, expression, connection)
  //       row[pos] = value
  // generalized over the row R and the (suffix) entry list CVS; uses (CHAIN).
  // side condition: every entry position is a valid index of R.
  // ======================================================================
  claim
    <k> #forLoop( ent ,
                  CVS:List ,
                  ( pos = entPos(ent)  convs = entConvs(ent)  expression = entExpr(ent)
                    value = row [ pos ]
                    for conv in convs : value = applyC( conv , value , expression , connection )
                    row [ pos ] = value ) )
        => .K ... </k>
    <store>
      row        |-> ( R:List => convertRow(R, CVS, Cn) )
      connection |-> Cn:Opaque
      value      |-> ( _:Val => ?_:Val )
      ent        |-> ( _:Val => ?_:Val )
      pos        |-> ( _:Val => ?_:Val )
      convs      |-> ( _:Val => ?_:Val )
      expression |-> ( _:Val => ?_:Val )
      conv       |-> ( _:Val => ?_:Val )
    </store>
    requires positionsInRange(CVS, size(R))
    [all-path]

  // ======================================================================
  // (ROWS) outer loop: convert every row, appending into `result`.
  //   for row0 in <ROWS> :
  //       row = list(row0)
  //       for ent in converters : (MIDDLE-BODY)
  //       append(result, row)
  // generalized over accumulator Acc and the (suffix) row list ROWS; uses (ROW).
  // ======================================================================
  claim
    <k> #forLoop( row0 ,
                  ROWS:List ,
                  ( row = list( row0 )
                    for ent in converters :
                        ( pos = entPos(ent)  convs = entConvs(ent)  expression = entExpr(ent)
                          value = row [ pos ]
                          for conv in convs : value = applyC( conv , value , expression , connection )
                          row [ pos ] = value )
                    append( result , row ) ) )
        => .K ... </k>
    <store>
      result     |-> ( Acc:List => Acc convertRows(ROWS, CVS, Cn) )
      converters |-> CVS:List
      connection |-> Cn:Opaque
      row        |-> ( _:Val => ?_:Val )
      row0       |-> ( _:Val => ?_:Val )
      value      |-> ( _:Val => ?_:Val )
      ent        |-> ( _:Val => ?_:Val )
      pos        |-> ( _:Val => ?_:Val )
      convs      |-> ( _:Val => ?_:Val )
      expression |-> ( _:Val => ?_:Val )
      conv       |-> ( _:Val => ?_:Val )
    </store>
    requires allRowsPositionsInRange(ROWS, CVS)
    [all-path]

  // ======================================================================
  // (APPLY) function contract:
  //   result = []
  //   for row0 in rows: row = list(row0); for ent in converters: ...; append(result,row)
  //   return result
  // returns convertRows(rows, converters, connection), provided every row is
  // long enough for every converter position.  Reuses (ROWS).
  // ======================================================================
  claim
    <k> ( result = .List
          for row0 in rows :
              ( row = list( row0 )
                for ent in converters :
                    ( pos = entPos(ent)  convs = entConvs(ent)  expression = entExpr(ent)
                      value = row [ pos ]
                      for conv in convs : value = applyC( conv , value , expression , connection )
                      row [ pos ] = value )
                append( result , row ) )
          return result )
        => convertRows(ROWS, CVS, Cn) ... </k>
    <store>
      rows       |-> ROWS:List
      converters |-> CVS:List
      connection |-> Cn:Opaque
      result     |-> ( _:Val => ?_:List )
      row        |-> ( _:Val => ?_:Val )
      row0       |-> ( _:Val => ?_:Val )
      value      |-> ( _:Val => ?_:Val )
      ent        |-> ( _:Val => ?_:Val )
      pos        |-> ( _:Val => ?_:Val )
      convs      |-> ( _:Val => ?_:Val )
      expression |-> ( _:Val => ?_:Val )
      conv       |-> ( _:Val => ?_:Val )
    </store>
    requires allRowsPositionsInRange(ROWS, CVS)
    [all-path]
endmodule
