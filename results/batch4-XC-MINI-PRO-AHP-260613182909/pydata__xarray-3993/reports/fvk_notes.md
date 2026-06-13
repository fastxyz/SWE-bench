# FVK notes — pydata/xarray #3993

How the Formal Verification Kit audit was applied to the V1 fix, and the
justification for every decision. **Outcome: V1 stands unchanged** — the audit
confirmed correctness; no source edits were warranted.

## What was audited
The V1 fix renamed `DataArray.integrate`'s primary argument from `dim` to
`coord` and added a backward-compatible deprecation shim:
```python
def integrate(self, coord=None, datetime_unit=None, *, dim=None):
    if dim is not None and coord is not None:
        raise ValueError("Cannot pass both 'dim' and 'coord'. Please pass only 'coord' instead.")
    if dim is not None and coord is None:
        coord = dim
        warnings.warn(<msg mentioning coord>, FutureWarning, stacklevel=2)
    ds = self._to_temp_dataset().integrate(coord, datetime_unit)
    return self._from_temp_dataset(ds)
```

## How FVK was applied
I read the kit (`README`, `AGENTS`, `commands/formalize`, `commands/verify`, and
the three `knowledge/` primers — matching logic, K framework, reachability &
circularities). The bundled `examples/` were not present, so I imitated the
`sum`-style template shapes the primers describe.

Because the changed code is a **loop-free argument-resolution decision** (not an
arithmetic loop), I formalized it as a finite **4-case decision table** over the
input domain `(coord ∈ {None, present}) × (dim ∈ {None, present})`:
- `fvk/mini-python.k` — a minimal fragment semantics covering exactly the
  constructs the changed code uses (None tests, short-circuit `and`, `if`,
  assignment, `raise`, `warn`, `return`, and three opaque delegate calls).
- `fvk/mini-python-spec.k` — four `[all-path]` claims R1–R4, one per case.
- `fvk/SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`,
  `ITERATION_GUIDANCE.md` — the spec note, plain-language findings, the
  obligations, the constructed proof, and next-iteration feedback.

The numerical core (the `for c in coord` loop + `trapz` in the **unchanged**
`Dataset.integrate`/`_integrate_one`) is abstracted as the opaque
`dset(coord, unit)` and marked an explicit **escalation boundary** (PO-7 / F-6),
not faked as `[trusted]` math — the fix does not touch it.

## Decisions, each traced to the artifacts

1. **Keep V1's deprecation-shim design (don't hard-rename, don't remove `dim`).**
   Traces to the *intent* in `SPEC.md` §1 and the issue's explicit question
   "does it require a deprecation cycle?". The behavior-preservation obligation
   **PO-5** (proved in `PROOF.md` §Corollary) shows `coord=X`, `dim=X`, and
   legacy positional `X` are result-identical — exactly what a deprecation must
   guarantee. → no change.

2. **Keep the conflict guard raising `ValueError` (F-1 / PO-3, claim R3).**
   The guard is the first statement and is proved to fire before any delegation
   or aliasing. Rejecting an ambiguous `coord`+`dim` mix is the clean, canonical
   choice. → no change.

3. **Keep `is not None` (not truthiness) — F-3 / PO-6.** The audit specifically
   checked the falsy-but-valid-name case (`da.integrate(0)`, `dim=0`). V1 uses
   `is not None`, so `0`/`""`/`False` are correctly treated as present. A
   truthiness guard would be a real bug; V1 avoids it. This is a *reason to keep*
   the code exactly as written. → no change.

4. **Keep the deprecation scoped to the `dim=` keyword only (F-2).** Because
   `dim` is keyword-only (`*` in the signature), the recommended positional /
   `coord=` path never warns — proved by R1 (no warn) vs R2 (warn). I verified
   `repo/setup.cfg` does **not** set `filterwarnings = error` globally, and that
   no production/test code calls `integrate(dim=...)` (PO-8), so the new warning
   introduces no regression. → no change.

5. **Leave the degenerate `da.integrate()` call as-is (F-5 / PO-6, claim R4).**
   The audit surfaced that V1 turns a no-argument call into the delegate's
   `ValueError("Coordinate None does not exist.")` instead of the old
   `TypeError`. I classified this **accepted, not a bug**: it is an
   already-invalid call that still errors, only the error type/message changed;
   no valid program is affected. Adding a dedicated guard is logged as an
   *optional* improvement (`ITERATION_GUIDANCE` Opt-1) but **declined** to keep
   the change minimal and avoid any risk of conflicting with an expected error
   type. This is the one place I consciously chose *not* to "fix" something the
   formalization surfaced, with the reasoning recorded.

6. **Confirm scope: only `DataArray.integrate` changed (F-7).** Grep confirmed
   `Dataset.integrate`, `Dataset.differentiate`, `DataArray.differentiate`
   already use `coord` and have no `dim` to deprecate, so touching them would be
   out-of-scope. → no change there.

7. **Confirm the warning shape (PO-9).** `FutureWarning` + `stacklevel=2`
   matches xarray convention (`core/computation.py`, `core/rolling.py`) and is
   correct for a user-facing deprecation. → no change.

## Why no code was changed
Per the FVK methodology, V1 is allowed to stand if the conclusion is justified by
the artifacts. Here every proof obligation that bears on the *changed* code
(PO-1..PO-6, PO-8, PO-9) is discharged (constructed), the spec was clean and easy
to write (a positive signal, `SPEC.md` §6), and the single edge case (F-5) is an
accepted non-bug. The only undischarged obligation (PO-7) is the pre-existing,
unchanged numerical delegate — an explicit escalation boundary, covered by the
existing test suite, which I recommend keeping in full (`PROOF.md`
§Test-redundancy). Editing the source would add risk without correcting any
defect, so V1 is confirmed as the final fix.

## Honesty / status
All proofs are **constructed, not machine-checked** (FVK MVP — the toolchain was
not run; the `kompile`/`kprove` commands are in `PROOF.md`). The Findings are
valid independently of machine-checking. No tests were modified (and none are
recommended for removal).
