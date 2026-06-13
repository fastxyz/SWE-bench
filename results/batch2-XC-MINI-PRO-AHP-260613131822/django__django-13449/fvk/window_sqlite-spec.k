// =============================================================================
// Claims for the mini-SQL-builder fragment  (django__django-13449)
// CONSTRUCTED, NOT MACHINE-CHECKED.
//
// These are reachability claims  phi_pre => phi_post  over window_sqlite.k.
// There is no loop and no recursive back-edge (compileFunc is a leaf call), so
// no circularity/coinduction is needed: every claim is discharged by finite
// symbolic execution + one case-split on the output Type.  Run-commands:
//
//     kompile window_sqlite.k --backend haskell
//     kprove  window_sqlite-spec.k          // expected: #Top  (all proved)
// =============================================================================

requires "window_sqlite.k"

module WINDOW-SQLITE-SPEC-SYNTAX
  imports WINDOW-SQLITE-SYNTAX
endmodule

module VERIFICATION
  imports WINDOW-SQLITE-SPEC-SYNTAX
  imports WINDOW-SQLITE
  imports K-EQUAL
endmodule

module WINDOW-SQLITE-SPEC
  imports VERIFICATION

  // ---------------------------------------------------------------------
  // (V2-FUNC)  Functional correctness of the fix.
  //   For every windowed function N, every source type Ts, every window
  //   clause WC, and every Window output type Tw, V2 produces exactly the
  //   intended SQL term spec(...).
  //   N (=N), Ts, Tw range over all values -> the claim is universal.
  // ---------------------------------------------------------------------
  claim <k> asSqliteWindowV2(window(func(N:Id, Ts:Type), WC:WClause, Tw:Type))
        => spec(window(func(N, Ts), WC, Tw)) </k>   [all-path]

  // ---------------------------------------------------------------------
  // (V2-SAFE)  Safety: the fix NEVER closes a CAST before OVER.
  //   For all inputs, V2's output is OVER-valid.
  //   This is the property whose violation is the OperationalError.
  // ---------------------------------------------------------------------
  claim <k> overValid(asSqliteWindowV2(window(func(N:Id, Ts:Type), WC:WClause, Tw:Type)))
        => true </k>   [all-path]

  // ---------------------------------------------------------------------
  // (V2-NOREG)  Non-regression on "normal" windows (Window output type ==
  //   source type, the only shape producible WITHOUT an explicit override).
  //   V2 and V1 agree there -> the fix changes no currently-working SQL.
  // ---------------------------------------------------------------------
  claim <k> asSqliteWindowV2(window(func(N:Id, T:Type), WC:WClause, T))
        => asSqliteWindowV1(window(func(N, T), WC, T)) </k>
        requires (T ==K decimal) orBool (T ==K other)   [all-path]

  // ---------------------------------------------------------------------
  // (BUG-V1)  Counter-claim: V1 is UNSAFE for an explicit non-decimal
  //   override on a DECIMAL source. This claim is EXPECTED TO HOLD and is
  //   exactly the residual bug the audit found: V1 emits over(cast(...),wc).
  //   (Stated over the model to make the finding machine-checkable.)
  // ---------------------------------------------------------------------
  claim <k> overValid(asSqliteWindowV1(window(func(N:Id, decimal), WC:WClause, other)))
        => false </k>   [all-path]

  // ---------------------------------------------------------------------
  // (BUG-OLD)  Counter-claim: the pre-V1 code is unsafe on the ORIGINAL
  //   issue (decimal source, decimal window). over(cast(...),wc) again.
  // ---------------------------------------------------------------------
  claim <k> overValid(asSqliteOld(window(func(N:Id, decimal), WC:WClause, decimal)))
        => false </k>   [all-path]
endmodule
