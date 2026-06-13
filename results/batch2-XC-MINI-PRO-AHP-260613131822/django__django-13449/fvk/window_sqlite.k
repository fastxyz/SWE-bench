// =============================================================================
// mini-SQL-builder : a minimal K fragment for django__django-13449
// =============================================================================
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP — no kompile/kprove run here).
//
// The bug and the fix are about the *structure* of the SQL string that
// `Window.as_sqlite` builds, not about arithmetic. So the "mini-X" fragment
// models exactly that structure: SQL is an algebraic term over three builders
//
//     bare(N)        ~  "LAG(...)"                 (a bare window-function call)
//     over(S, WC)    ~  "S OVER (WC)"              (append an OVER clause)
//     cast(S)        ~  "CAST(S AS NUMERIC)"       (SQLite numeric cast)
//
// This is faithful: the real code produces these three shapes by `%`/join, and
// the only property that matters for the OperationalError is *where the cast
// parenthesis closes relative to OVER* — which the term shape captures exactly.
//
// The inputs are modelled by a 2-constructor expression algebra:
//
//     func(N, T)             a windowed function (name N, its own output type T)
//     window(F, WC, T)       a Window over source F, window clause WC,
//                            and the Window's OWN output type T (which may be
//                            set explicitly and so differ from F's type).
//
// Output types are `decimal` (DecimalField) or `other` (anything else); a third
// value `unresolved` models output_field raising FieldError (see FINDINGS).
// =============================================================================

module WINDOW-SQLITE-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // ----- output field type tags -----------------------------------------
  syntax Type ::= "decimal" | "other" | "unresolved"

  // ----- the window clause is opaque here (PARTITION BY / ORDER BY / frame)
  syntax WClause ::= "wc"

  // ----- input expression algebra ---------------------------------------
  syntax Expr ::= func(Id, Type)              // a window-compatible function
                | window(Expr, WClause, Type) // Window(source, clause, out-type)

  // ----- output SQL term algebra ----------------------------------------
  syntax Sql ::= bare(Id)            // "<fn>(...)"      bare function call
               | cast(Sql)           // "CAST(<sql> AS NUMERIC)"
               | over(Sql, WClause)  // "<sql> OVER (<wc>)"

  syntax KResult ::= Sql | Bool | Type
endmodule

module WINDOW-SQLITE
  imports WINDOW-SQLITE-SYNTAX
  imports BOOL

  // =======================================================================
  // compiler.compile(F)  on the SQLite backend, for a *function* node F.
  // Dispatches to SQLiteNumericMixin.as_sqlite(F):
  //     sql = F.as_sql()            ==  bare(N)
  //     if F.output_field is Decimal: sql = "CAST(%s AS NUMERIC)" % sql
  // (try/except FieldError around the type check is modelled by the
  //  `unresolved` rule: no cast.)
  // =======================================================================
  syntax Sql ::= compileFunc(Expr) [function]
  rule compileFunc(func(N, decimal))    => cast(bare(N))
  rule compileFunc(func(N, other))      => bare(N)
  rule compileFunc(func(N, unresolved)) => bare(N)        // FieldError caught

  // =======================================================================
  // Window.as_sql(W):   over( compile(source) , wc )
  // (The source is compiled with whatever output type it currently carries.)
  // =======================================================================
  syntax Sql ::= asSqlWindow(Expr) [function]
  rule asSqlWindow(window(F, WC, _)) => over(compileFunc(F), WC)

  // =======================================================================
  // castIf(T, S):   the guarded outer cast.
  //   T == decimal      -> wrap          (output_field is DecimalField)
  //   T == other        -> no wrap
  //   T == unresolved   -> no wrap       (try/except FieldError: pass)
  // =======================================================================
  syntax Sql ::= castIf(Type, Sql) [function]
  rule castIf(decimal, S)    => cast(S)
  rule castIf(other, S)      => S
  rule castIf(unresolved, S) => S

  // =======================================================================
  // forceFloat(F): the `source_expression.output_field = FloatField()` step,
  // applied to a COPY of the windowed function. A function's SQL (`bare(N)`)
  // does not depend on its output type, so the only effect is to make
  // compileFunc never cast it: func(N, _) |-> func(N, other).
  // =======================================================================
  syntax Expr ::= forceFloat(Expr) [function]
  rule forceFloat(func(N, _)) => func(N, other)

  // =======================================================================
  // Window.as_sqlite  --  V2  (the fix under audit)
  //   copy; source := forceFloat(source); sql = copy.as_sql();
  //   try: if self.output_field is Decimal: sql = cast(sql)
  //   except FieldError: pass
  // self.output_field is the Window's OWN type Tw (3rd component).
  // =======================================================================
  syntax Sql ::= asSqliteWindowV2(Expr) [function]
  rule asSqliteWindowV2(window(F, WC, Tw))
    => castIf(Tw, asSqlWindow(window(forceFloat(F), WC, Tw)))

  // =======================================================================
  // Window.as_sqlite  --  V1  (the previous fix, kept for the FINDINGS
  // contrast). Suppression of the inner cast happens ONLY in the decimal
  // branch; the non-decimal branch falls through to as_sql on the UNMODIFIED
  // source -- which is the residual bug.
  // =======================================================================
  syntax Sql ::= asSqliteWindowV1(Expr) [function]
  rule asSqliteWindowV1(window(F, WC, decimal))
    => cast(asSqlWindow(window(forceFloat(F), WC, decimal)))
  rule asSqliteWindowV1(window(F, WC, other))
    => asSqlWindow(window(F, WC, other))            // <-- no forceFloat: bug
  // (V1 has no rule for Tw == unresolved: the unguarded
  //  self.output_field.get_internal_type() raises FieldError -- modelled as a
  //  stuck term; see FINDINGS F2.)

  // =======================================================================
  // OLD  (pre-V1): Window had no as_sqlite, so compile(W) == as_sql(W).
  // =======================================================================
  syntax Sql ::= asSqliteOld(Expr) [function]
  rule asSqliteOld(W) => asSqlWindow(W)

  // =======================================================================
  // SAFETY PREDICATE: overValid(S)
  // The SQLite grammar requires the operand of OVER to be a window function,
  // i.e. a bare call -- never a CAST(...) and never another OVER(...).
  // =======================================================================
  syntax Bool ::= isBare(Sql) [function]
  rule isBare(bare(_))    => true
  rule isBare(cast(_))    => false
  rule isBare(over(_, _)) => false

  syntax Bool ::= overValid(Sql) [function]
  rule overValid(bare(_))     => true
  rule overValid(cast(S))     => overValid(S)
  rule overValid(over(S, WC)) => isBare(S) andBool overValid(S)

  // =======================================================================
  // INTENT / reference postcondition: spec(W)
  // The correct SQL: cast the WHOLE "<fn> OVER (...)" iff the WINDOW's output
  // is decimal; never cast the function on its own.
  // =======================================================================
  syntax Sql ::= spec(Expr) [function]
  rule spec(window(func(N, _), WC, decimal)) => cast(over(bare(N), WC))
  rule spec(window(func(N, _), WC, other))   => over(bare(N), WC)
  rule spec(window(func(N, _), WC, unresolved)) => over(bare(N), WC)
endmodule
