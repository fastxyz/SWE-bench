# reports/fvk_notes.md — FVK audit of the sympy-16597 fix

## Outcome: V1 stands unchanged

The Formal Verification Kit audit (artifacts under [`../fvk/`](../fvk/)) found
**no correctness defect** in the V1 fix. The single added production

```python
'rational       ->  finite',     # sympy/core/assumptions.py:175
```

discharges every intent obligation and every safety obligation. No source file
was edited in this pass. Each decision below traces to specific entries in
[`../fvk/FINDINGS.md`](../fvk/FINDINGS.md) (F-tags) and
[`../fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md) (PO-tags).

## Why I kept the code exactly as in V1

### Decision 1 — keep `rational -> finite` (no change). 
Traces to **PO1/PO2/PO3** (discharged, [`PROOF.md`](../fvk/PROOF.md) §1–3) and **F1**.
Symbolic execution of the closure shows `even → integer → rational → finite`
delivers `is_finite=True` to every even/odd/integer/rational symbol — the exact
bug in the issue. Removing the line reproduces the bug (PROOF §1 note). So the
line must stay, and it is sufficient.

### Decision 2 — do NOT switch to `real -> finite`. 
Traces to **PO5** and **F6** (the spec-difficulty signal). `oo`/`-oo` are
`is_real=True` *and* `is_infinite=True` (extended reals), so `real → finite`
would force them inconsistent and **crash SymPy at import** (`deduce_alpha_
implications`/`_tell` raise, L4/L5/L6). The audit makes this the single genuine
design smell (F6) and confirms the fix correctly attaches `finite` to a predicate
that *excludes* the infinities.

### Decision 3 — do NOT narrow to `integer -> finite`. 
Traces to **PO3** and ledger **L3**. `integer → finite` alone would leave a bare
`Symbol('r', rational=True)` non-finite, contradicting "all rationals are finite"
and the public hint. `rational → finite` is the maximal safe choice and subsumes
integer/even/odd through the existing chain. (ITERATION_GUIDANCE "Decisions
locked" #1.)

### Decision 4 — do NOT modify `irrational == real & !rational`. 
Traces to **F2**, **PO-C1**, and **F6**. The post-fix value `oo.is_irrational =
True` is *forced and consistent* (PROOF §4) given the codebase's own definition
of `irrational`. The two ways to suppress it both fail the audit:
- adding `irrational -> finite` makes `oo` **inconsistent** (beta rule `real &
  !rational → irrational` vs `irrational → finite` on a non-finite `oo`) →
  violates **PO5**, crashes import;
- redefining `irrational == real & finite & !rational` changes `irrational` for
  ordinary symbols and exceeds the issue/hint scope (**L3/L4**), risking the
  existing `irrational` test assertions.
So the minimal, in-scope, consistent choice is to leave `irrational` alone and
record `oo.is_irrational=True` as an accepted consequence (F2), with the proper
resolution (an `extended_real` predicate) deferred as a separate issue
(ITERATION_GUIDANCE open question).

### Decision 5 — do NOT address the `Pow` infinite-base path (F5). 
Traces to **F5** (residual). `oo.is_irrational=True` now feeds
`Pow._eval_is_rational`/`_eval_is_algebraic` for the rare unevaluated infinite
power. That path's correctness predates and is independent of this fix; touching
it is out of scope for #16597. Flagged for a future audit, not changed.

### Decision 6 — do NOT reformat the rule line. 
The hint's literal phrasing `'rational -> real & finite'` compiles to the **same**
two implications as the separate `'rational -> finite'` line (`_process_rule`
splits `a -> b & c`). I kept the standalone line because it is self-documenting
and isolates the new fact; functionally identical, so no behavior risk.

## Safety obligations the audit additionally discharged (beyond the issue)

- **PO4 / VC-A** — the new edge does not make the rule base inconsistent: the
  antecedents forcing `finite=true` (`rational`/`zero`) and `finite=false`
  (`infinite`) are mutually exclusive, so `deduce_alpha_implications` does not
  raise. Import is safe.
- **PO5 / VC-B** — static audit: no class asserts `(rational|integer|even|odd)=
  True` together with `(finite=False|infinite=True)` (checked `Rational`,
  `Integer`, `KroneckerDelta`, `LeviCivita`, `Idx`); the singletons `oo/-oo/zoo`
  close to `ok` (CONSISTENT-OO claim). No construction raises.
- **PO5-rt / VC-B(rt)** — `Add`/`Mul` report `is_rational=True` only when all args
  are rational (hence finite under the new rule), so the composite is finite too;
  no runtime `InconsistentAssumptions`.
- **PO6 / VC-C** — conservativity: `Closure_R ⊇ Closure_{R₀}`, and the new facts
  are inert unless `rational=True`/`finite=False` is present. Finite numbers
  (e.g. `Rational(3,4).is_finite`, L8) and generic symbols are unchanged.
- **PO7 / NO-CONVERSE** — only the forward edge was added; a merely-finite symbol
  keeps `is_rational=None`. The fix is not over-strengthened.
- **PO8 / VC-T** — the closure terminates (finite fact lattice).

## Tests

The suite is fixed and hidden; I modified no test. Per
[`PROOF.md`](../fvk/PROOF.md) §10 the proof would subsume the new even/integer/
rational finiteness regression points once machine-checked, but the Honesty gate
keeps them; the `oo/-oo/zoo/nan` assertion blocks must be **kept** (they pin the
forced F2/F3 consequences). No deletions recommended.

## One-line conclusion

The audit confirms V1: `rational -> finite` is the minimal change that fixes the
reported `even/integer ⟹ finite` gap (PO1–PO3) while provably preserving global
and per-object consistency (PO4–PO7) and conservativity (PO6); the only surfaced
smell — `oo.is_irrational=True` (F2) rooted in the extended-real meaning of
`real` (F6) — is a forced, consistent, out-of-scope design gap, so the code
stands unchanged.
