# reports/fvk_notes.md — FVK audit decisions for sympy__sympy-16597

This explains every decision taken in the FVK pass, tracing each to specific
entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md). **Outcome: V1 stands
unchanged**; the audit confirms it and supplies the evidence the V1 notes lacked.

## What V1 was

One edit in `sympy/core/assumptions.py`: `'rational -> real'` →
`'rational -> real & finite'`. Unchanged after this audit (re-verified;
`_assume_rules` line reads `'rational       ->  real & finite'`).

## Decision 1 — Keep the fix at `rational` (not `real`, not `complex`, not `integer`)

- **Trace:** PO1–PO3 (discharged, `PROOF.md` §1) show `rational -> finite`
  delivers even/integer/rational ⟹ finite — the full reported intent I1–I3.
- **Alternatives falsified, not hand-waved (PO7, `PROOF.md` §4):**
  - `real -> finite`: claim (CLASH-DETECTED) + the alt-R derivation show `oo`/`-oo`
    (real, infinite) would hit `infinite:T & finite:T` → `#inconsistent`. Unsound.
    Matches FINDINGS A-line on I4/E5 ("adding finite to real would break a lot of
    code").
  - `complex -> finite`: alt-C derivation — `zoo` (complex, infinite) → same
    clash. Unsound.
  - `integer -> finite` only: narrower than I3/E3/E4 (the hint says *rational*);
    would leave `Symbol(rational=True).is_finite = None`. Rejected as
    under-covering intent.
  - So `rational` is the **forced** safe attachment point — it is the lowest node
    in the hierarchy that no infinite singleton satisfies (V1 itself *derives*
    `rational:False` for `oo`/`-oo`/`zoo`). This is the FVK "forced choice"
    procedure: the alternatives demonstrably fail a public obligation (I5), so the
    choice is genuinely forced, not under-determined.

## Decision 2 — Accept `oo.is_irrational → True` rather than "fix" it (the main smell)

- **Trace:** FINDINGS **F1**; obligation **PO8**; `PROOF.md` §2 step 8 and the
  §4 alt-B two-column table.
- My V1 notes called this a "debatable/accepted consequence." `formalize.md` §7
  flags exactly that kind of phrase as a smell to investigate, so I promoted the
  fix-it alternative (**B**: `irrational == real & !rational & finite`) to a
  falsifiable hypothesis and ran it side-by-side:
  - Both V1 and B satisfy I1–I3 and I5 ⇒ the `oo.is_irrational` value is
    **under-determined** by public obligations (so I must not claim either is
    "forced" or predict it as a CONFIRMed test value).
  - B is nonetheless **rejected on positive grounds**: it contradicts the
    glossary definition `irrational == real & !rational` (I6/E7) by inserting
    `finite`, and is only coherent if `real ⟹ finite` — the very change I4/E5
    forbid. V1's `True` is, by contrast, *entailed* by the unchanged definition
    plus the pre-existing `oo.is_real=True`. So V1 is definition-faithful; B is a
    local hack papering over the real root cause (extended-real `real`).
  - No public evidence requests any `irrational` change.
- **Why this does not block the "no further change" verdict:** per
  `intent-evidence.md` §5.8, a no-change verdict is invalid if it rests on a
  SUSPECT test or a dropped named change. Here the verdict rests on PO1–PO8 plus a
  *positive* rejection of B — and explicitly treats `test_assumptions.py:108`
  (`oo.is_irrational is None`) as **SUSPECT legacy** (E8/F1), i.e. a pre-fix row
  that any correct finite-fix must perturb, never an oracle that keeps V1 honest.

## Decision 3 — Treat the `oo`/`-oo` cascade as a correctness improvement

- **Trace:** FINDINGS **F2**; PO4/PO8; `PROOF.md` §2.
- V1 makes `oo.is_integer/is_rational/is_even/is_odd = False` and
  `is_noninteger = True` (all from `!finite`). Each is mathematically correct for
  ∞, so these `None → False/True` changes are improvements, not regressions. The
  tests pinning the old `None` values are SUSPECT legacy (E8) and should be
  *updated* to the §2 fixpoint, which is recommendation-only and outside the
  task's "don't touch tests" rule.

## Decision 4 — Confirm consistency / no import-time breakage

- **Trace:** PO4, PO6 (discharged, `PROOF.md` §2 and §5); compatibility audit
  `SPEC.md` §6.
- (OO-CONSISTENT) shows `oo`/`-oo`/`zoo`/`nan` all close without `#inconsistent`.
  §5 checks every class with explicit `is_integer/is_rational=True` (`Integer`,
  `Rational`, `Idx`, `KroneckerDelta`, `LeviCivita`) is finite, and that the only
  `is_infinite=True` classes are the three singletons (none integer/rational).
  Hence no `InconsistentAssumptions` at import.

## Decision 5 — Reject the `floor` change and the `irrational`-symbol asymmetry

- **Trace:** FINDINGS **F4**/OB1 and **F5**/OB2; `PROOF_OBLIGATIONS.md`
  out-of-scope section.
- **F4:** `floor(Symbol('x', real=True, infinite=True))` becomes order-dependent
  because `floor._eval_is_integer` returns `args[0].is_real` (imprecise: should
  mean "finite real"). This is a **pre-existing** imprecision *surfaced* by V1,
  triggered only by a pathological symbolic-∞ construct with no test/intent
  evidence; `floor` of an actual ∞ evaluates away. Named change (tighten the
  handler) rejected on positive grounds (no evidence + regression risk), recorded
  for a separate issue — not dropped silently.
- **F5:** `Symbol('x', irrational=True).is_finite` stays `None`. For `real` this
  is mandated by I4; for `irrational` it is *blocked* by V1's `oo.is_irrational=
  True` (adding `irrational -> finite` would clash with `oo` per CLASH-DETECTED).
  Both are consequences of the deliberately out-of-scope extended-real model, not
  defects in V1.

## Decision 6 — No cosmetic refactor

- The `finite` in `'zero -> even & finite'` is now redundant (zero→…→finite), but
  removing it is a gratuitous, non-isolated change; keeping it is harmless and
  self-documenting. Minimal-change principle (ITERATION_GUIDANCE table).

## Adequacy gate

AG1–AG3 (`PROOF_OBLIGATIONS.md`) pass: all adequacy artifacts present
(`SPEC.md` §1–§6), `SPEC_AUDIT` all-pass, and the no-change verdict rests on
discharged obligations + positive rejection of alternatives, not on any SUSPECT
test or scope-dropped change.

## Honest status

The `.k` proof is **constructed, not machine-checked** (`PROOF.md` §7 lists the
`kompile`/`kprove` commands; no toolchain was run, per the no-execution rule).
The bug-finding results (B0 fixed; F1–F5 classified) do not depend on machine
checking. No test files were modified.

## Bottom line

V1 — the single edit `'rational -> real & finite'` — is the minimal,
definition-faithful, consistency-preserving fix for the full intent I1–I6. The
FVK audit upgrades it from "fix that seems right" to "fix backed by discharged
obligations PO1–PO8, falsified alternatives, and a compatibility audit," and
finds **no justified source change beyond V1**.
