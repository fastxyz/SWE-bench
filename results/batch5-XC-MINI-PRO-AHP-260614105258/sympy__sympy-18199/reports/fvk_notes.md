# FVK audit notes — sympy__sympy-18199

This documents the FVK pass over the V1 fix and justifies the disposition. **Outcome: V1
stands unchanged.** Every decision below traces to entries in `fvk/FINDINGS.md` (F*) and
`fvk/PROOF_OBLIGATIONS.md` (PO-*).

## What V1 is

`repo/sympy/ntheory/residue_ntheory.py:779–781` — after the `isprime(p)` guard and before the
two solving paths:

```python
    if a % p == 0:
        # ``x**n = 0 (mod p)`` has the single root ``x = 0`` for prime ``p``
        return [0] if all_roots else 0
```

## Decision 1 — keep the fix (no code change)

- **Why:** the constructed proof of `CLAIM-ZERO` discharges every obligation that bears on the
  branch: `PO-ROOT` (`0` solves the congruence), `PO-ONLY` (`0` is the *only* root, by Euclid's
  lemma — `fvk/PROOF.md` §B), `PO-EQUIV` (the guard `a%p==0` fires *exactly* when `0` is a
  root), `PO-COMPLETE`/`PO-SHAPE` (returned `0`/`[0]` equals the documented contract value with
  the right type). The branch's two mathematical preconditions are not assumed but **enforced
  upstream**: `PO-PRIME` by the `isprime` guard at line 776, `PO-NGE1` by `is_nthpow_residue`
  plus the `n==0`/`n==2` early exits (`FINDINGS.md` F2). With nothing open against the fix and
  the change already minimal, the methodology's "may stand unchanged if justified" applies.

- **Robustness the audit *added* confidence about (F1).** Formalizing made the pre-fix failure
  taxonomy precise: the final `pa` of the gcd loop is `gcd(n, p-1)` (the loop is Euclid on the
  *exponents*, independent of `a`), so pre-fix, `a%p==0` either returned `0` by luck
  (`gcd==1`, e.g. the issue's own `289,5,17`), or **crashed** with `ValueError: Log does not
  exist` (`_nthroot_mod1(0,…)` → `discrete_log(p,0,h)`, line 1060) whenever `gcd(n,p-1)>2` or
  `n | (p-1)` — e.g. `nthroot_mod(11,5,11)`, `nthroot_mod(13,9,13)`. V1's short-circuit fires
  before *either* path, so it is correct on the lucky case **and** the crashing cases
  uniformly. This is why a short-circuit (not "append 0 to the computed roots") is the right
  shape: on the crashing inputs there are no computed roots to append to.

- **Placement justified, not incidental (F3/F6, PO-FRAME-*).** The guard sits *after*
  `isprime` (so composite `p` still raises — `PO-FRAME-COMPOSITE`/F6; moving it earlier would
  silently change that contract) and *after* the `n==2` delegation (so `n==2` keeps using the
  canonical, tested `sqrt_mod`, which independently returns `0`/`[0]` for `a≡0` — `PO-FRAME-N2`
  /F3). The result is a function that is *uniform* on `a≡0` across all `n`, which the audit
  verified rather than assumed.

## Decision 2 — do **not** broaden the fix to other discovered issues

The spec pass surfaced two genuine but **unrelated, pre-existing** defects:

- **F4 / G2** — `n==1` returns an unreduced representative (`nthroot_mod(20,1,7)→20` not `6`).
- **F5 / G3** — `n==0` raises `ZeroDivisionError` at `(p-1)%n` (an out-of-domain input).

Both are left untouched. **Why:** each triggers only on `a % p != 0` (F4) or outside the
documented `n ≥ 1` domain (F5) — i.e. *outside* `CLAIM-ZERO`'s domain and unrelated to issue
#18199. The task requires a minimal, targeted change; fixing them would touch the `a%p≠0`
algorithm / out-of-domain paths the issue never mentions and risk regressions in
`PO-SOLVE`-territory code. They are recorded as findings and routed to `fvk/ITERATION_GUIDANCE.md`
(G2, G3) for a future pass instead.

## Decision 3 — do not weaken or over-claim the proof

- `PO-ONLY` rests on Euclid's lemma, which is **false for composite `p`** (`2²≡0 mod 4`,
  `x=2≠0`). The audit kept the dependence explicit and tied it to the `isprime` guard
  (`PO-PRIME`) rather than papering over it. The *machine* discharge of that lemma needs an
  inductive primality theory beyond the bundled K tier, so it is marked `[ESCALATION BOUNDARY]`
  (`FINDINGS.md` PF2, `PROOF.md` §B) and proved **by hand**, never admitted as `[trusted]`.
- The pre-existing solver (`_nthroot_mod1`/gcd) is **assumed** correct on `a%p≠0` (`PO-SOLVE`,
  ASSUME-SOLVE), not re-derived — it is out of audit scope and unchanged by V1.

## Consistency with V1's baseline_notes

`reports/baseline_notes.md` already argued the short-circuit and rejected "append 0 to computed
roots". The FVK pass *strengthens* that argument with the explicit crash taxonomy (F1) and the
guard-enforced-precondition findings (F2), and confirms — via PO-PRIME/PO-NGE1/PO-ONLY — that
the rejected alternative would have been actively wrong on the crashing inputs. No claim in the
baseline notes was contradicted.

## Net change this iteration

- **Code:** none (V1 confirmed correct and minimal).
- **Artifacts added:** `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
  `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, and this report.
- **Recommended (for maintainers, not done here — tests are fixed/hidden):** the regression
  pins in `ITERATION_GUIDANCE.md` G5, especially `nthroot_mod(11,5,11)` and
  `nthroot_mod(13,9,13,True)` which exercise the pre-fix *crash* modes.
