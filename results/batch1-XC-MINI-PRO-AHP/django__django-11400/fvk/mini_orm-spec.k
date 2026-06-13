// mini_orm-spec.k — reachability claims (function contracts) for the patched
// methods of django__django-11400, over the mini_orm.k semantics.
//
// Constructed, NOT machine-checked (FVK MVP: claims + run-commands are emitted;
// the toolchain is not invoked here). Run-commands:
//   kompile mini_orm.k --backend haskell
//   kprove  mini_orm-spec.k                  # expected: #Top (all claims proved)
//
// There is NO counting loop here: each patched method is straight-line, and the
// single list comprehension is a pure order-preserving map (SPEC.md note L1), so
// no loop-invariant circularity is required — the contracts are plain reachability
// rules discharged by unfolding the [function] rules (= symbolic execution).

requires "mini_orm.k"

module MINI-ORM-SPEC
  imports MINI-ORM

  // (GC-ORD)  get_choices with a NON-EMPTY ordering enumerates by THAT ordering.
  //   isTruthy(ORD)  =>  choicesOrdering(META, ORD) == ORD
  claim <k> choicesOrdering(META:Ord, ORD:Ord) => ORD </k>
    requires isTruthy(ORD)

  // (GC-META)  get_choices with the EMPTY ordering () falls back to Meta.ordering.
  //   choicesOrdering(META, ()) == META            <-- the core of the fix
  claim <k> choicesOrdering(META:Ord, .Ord) => META </k>

  // (GC-REV-ORD / GC-REV-META)  the reverse-relation core has the same contract.
  claim <k> effOrdering(getChoicesRev(META:Ord, ORD:Ord)) => ORD </k>
    requires isTruthy(ORD)
  claim <k> effOrdering(getChoicesRev(META:Ord, .Ord)) => META </k>

  // (FC-ADMIN)  field_choices orders by the related ModelAdmin ordering when an
  //   admin is registered AND its ordering is non-empty.
  //   hasAdmin & isTruthy(AO)  =>  fieldChoicesOrdering(true, AO, META) == AO
  claim <k> fieldChoicesOrdering(true, AO:Ord, META:Ord) => AO </k>
    requires isTruthy(AO)

  // (FC-META-NOADMIN)  with no related admin, field_choices falls back to Meta.ordering.
  claim <k> fieldChoicesOrdering(false, AO:Ord, META:Ord) => META </k>

  // (FC-META-EMPTYADMIN)  with an admin but EMPTY admin ordering, fall back to Meta.ordering.
  claim <k> fieldChoicesOrdering(true, .Ord, META:Ord) => META </k>

  // (BUG-OLD)  THE COUNTEREXAMPLE: the pre-fix core drops Meta.ordering for empty ORD.
  //   choicesOrderingOLD(META, ()) == ()   (NOT META)  — proves the regression existed
  //   and that (GC-META) FAILS for the old code, i.e. the fix is load-bearing.
  claim <k> choicesOrderingOLD(META:Ord, .Ord) => .Ord </k>
endmodule
