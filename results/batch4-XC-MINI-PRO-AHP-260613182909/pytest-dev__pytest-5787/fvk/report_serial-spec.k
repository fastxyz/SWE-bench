// =============================================================================
// report_serial-spec.k  —  reachability claims for the pytest-5787 fix
// =============================================================================
// The contract is a ROUND-TRIP (inverse) property: deserialize is a left inverse
// of serialize on the in-domain (all-entry-kinds-known) inputs.  The two list
// claims (RT-ES over reprentries, RT-LS over the chain) are the CIRCULARITIES —
// they play the role the Python `[... for x in ...]` comprehensions play, and are
// discharged by structural induction (guarded coinduction on the recursive
// call), exactly like the (REC) recursion example in the kit.
//
// Read `=>` as the reachability arrow.  All claims are equational round-trips
// (LHS rewrites to RHS) under the matching `requires`.
// Constructed, NOT machine-checked (MVP): see PROOF.md for the run-commands.
// =============================================================================

requires "report_serial.k"

module REPORT-SERIAL-SPEC-SYNTAX
  imports REPORT-SERIAL-SYNTAX
endmodule

module VERIFICATION
  imports REPORT-SERIAL-SPEC-SYNTAX
  imports REPORT-SERIAL
  imports K-EQUAL

  // ----- structural lemmas the round-trip needs (Step-6 [simplification]s) ----

  // L-NOSPUR: the chain precondition discharges the "process both" top-level
  // validation.  If every link's tb is all-known, so is the OUTERMOST one
  // (chain[-1] = tbOfLast).  This is exactly what makes deserialising the
  // discarded top-level traceback NEVER spuriously fail in the chain branch.
  rule allKnownTb(tbOfLast(LS)) => true
       requires allKnownLs(LS) andBool (LS =/=K .Ls) [simplification]

  // L-SERKIND: serialisation copies the entry "type" verbatim, so it preserves
  // known-ness of every slot (serialize never validates; only deserialize does).
  rule allKnownJTb(serTb(TB)) => allKnownTb(TB)             [simplification]
  rule allKnownJLs(serLs(LS)) => allKnownLs(LS)             [simplification]
endmodule

module REPORT-SERIAL-SPEC
  imports VERIFICATION

  // (RT-C)  crash round-trip.  Case split noCrash/mkCrash.  Total, no precond.
  claim deC(serC(C:Crash)) => C  [one-path]

  // (RT-D)  descr round-trip.  Case split noDescr/mkDescr.
  claim deD(serD(D:Descr)) => D  [one-path]

  // (RT-E)  single-entry round-trip.  Case split on kind; the Unknown branch is
  // OUT OF DOMAIN (deE undefined), hence the precondition isKnown(K).
  claim deE(serE(mkE(K:Kind, D:Int))) => mkE(K, D)
        requires isKnown(K)  [one-path]

  // (RT-ES)  CIRCULARITY #1 — the reprentries list.  Generalised over the whole
  // list ES; structural induction (base .Es, step E:ES uses RT-E on the head and
  // THIS claim on the tail).  Models `[deserialize_repr_entry(x) for x in ...]`.
  claim deEs(serEs(ES:Entries)) => ES
        requires allKnownEs(ES)  [one-path]

  // (RT-TB)  traceback round-trip.  One unfold + RT-ES.
  claim deTb(serTb(TB:Tb)) => TB
        requires allKnownTb(TB)  [one-path]

  // (RT-LS)  CIRCULARITY #2 — the chain list.  Generalised over LS; structural
  // induction (base .Ls, step uses RT-TB/RT-C/RT-D on the head link and THIS
  // claim on the tail).  Models the `for ... in chain` reconstruction loop.
  claim deLs(serLs(LS:Links)) => LS
        requires allKnownLs(LS)  [one-path]

  // (RT-LR)  TOP-LEVEL CONTRACT — deserialize ∘ serialize = id on every longrepr
  // shape, on the in-domain inputs.  The chain case additionally exercises the
  // "process both" top-level validation (discharged by L-NOSPUR).
  claim deLR(serLR(lrNone))                    => lrNone                 [one-path]
  claim deLR(serLR(lrStr(S:Int)))              => lrStr(S)               [one-path]
  claim deLR(serLR(single(TB:Tb, C:Crash, SE:Int))) => single(TB, C, SE)
        requires allKnownTb(TB)  [one-path]
  claim deLR(serLR(chained(LS:Links, SE:Int))) => chained(LS, SE)
        requires (LS =/=K .Ls) andBool allKnownLs(LS)  [one-path]
endmodule
