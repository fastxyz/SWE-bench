# ITERATION_GUIDANCE.md — pydata/xarray #3993

Feedback for the next generate→formalize→verify pass. **Headline: V1 stands.**
The audit found no bug; all four contract claims (R1–R4) and the
behavior-preservation corollary (PO-5) discharge. The items below are
clarifications and *optional* refinements, ordered by priority.

---

## Decision: keep V1 unchanged
Traceability: the fix is proved correct and complete on its intended domain —
PO-1..PO-5 discharged, PO-6 confirms the falsy-name safety, PO-8/PO-9 confirm no
regression and the right warning shape. The only edge (F-5) is an already-invalid
call that still errors. Per FVK ("V1 may stand unchanged if justified by the
artifacts, and do not patch during the loop unless asked"), no source edit is
made in this pass.

## Open questions for the intent layer (UltimatePowers)

1. **Degenerate call (F-5 / PO-6).** "When neither `coord` nor `dim` is given,
   should `DataArray.integrate()` raise its *own* clear error (e.g.
   `TypeError("integrate() missing required argument: 'coord'")`), or is
   delegating down to `ValueError('Coordinate None does not exist.')`
   acceptable?" — Current V1: the latter. Recommendation: acceptable as-is;
   optional clarity guard if a crisp message is desired.
2. **Redundant-but-equal `coord==dim` (F-1 / PO-3).** "Should
   `integrate(coord='x', dim='x')` be allowed (idempotent) or rejected?" —
   Current V1: **rejected** (`ValueError`). Recommendation: keep rejecting; a
   single canonical spelling is clearer than silently accepting duplication.
3. **Removal version (F-8).** "Confirm the planned removal release for the `dim`
   deprecation." — Docs/whatsnew currently say 0.19.0. Recommendation: confirm
   with maintainers; it is a plan, untested.

## Recommended next code/spec changes (all OPTIONAL, low priority)

- **(Opt-1)** Clearer degenerate-call message. *Only if* Q1 is answered "raise
  our own": insert, before the conflict guard,
  `if coord is None and dim is None: raise TypeError("integrate() missing required argument: 'coord'")`.
  Risk: changes the error *type* for an already-invalid call; declined in V1.
- **(Opt-2)** Micro-simplification: the second guard's `coord is None` conjunct
  is logically redundant once the first guard has raised on the both-present
  case. Leaving it explicit (V1) is clearer; collapsing to `if dim is not None:`
  is equivalent. No functional difference — do **not** change without reason.

## Tests to add / keep (recommendation only; never auto-edited)

- **ADD** (these pin the contract this audit proved):
  - R2: `with pytest.warns(FutureWarning): da.integrate(dim='x')` — and assert it
    equals `da.integrate('x')` (PO-5 behavior preservation).
  - R1/F-2: `da.integrate('x')` and `da.integrate(coord='x')` emit **no** warning
    (e.g. under `pytest.warns(None)` / `warnings.catch_warnings(record=True)`).
  - R3: `with pytest.raises(ValueError): da.integrate(coord='x', dim='x')`.
  - F-3: a coordinate named `0` integrates via `da.integrate(0)` /
    `da.integrate(dim=0)` (guards against a future truthiness refactor).
- **KEEP** (out of the verified contract / escalation boundary): all existing
  numerical tests `test_integrate` / `test_trapz_datetime` (PO-7, F-6), plus any
  termination/integration tests. No removals — see `PROOF.md` Honesty gate.

## Escalation boundary carried forward
PO-7 (the numerical delegate: `for c in coord` loop + `trapz` + datetime
conversion) is **assumed**, not proved — it is unchanged by this fix and needs
list/array/floating-point reasoning beyond the bundled tier. If a future pass
wants end-to-end verification of `integrate`, that is the boundary to escalate
(route via `knowledge/sources.md`); it is **not** a defect in this fix.
