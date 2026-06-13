# PROOF_OBLIGATIONS.md — pydata/xarray #3993 (V1)

The obligations that, together, establish the `SPEC.md` contract for the V1
argument-resolution logic of `DataArray.integrate`. Each notes how it is
discharged. **Constructed, not machine-checked.**

Notation: `c=coord`, `d=dim`, `u=datetime_unit`; "present" = `is not None`;
`dset(c,u)` = the opaque (unchanged) numerical delegate;
`daOf(·)` = `_from_temp_dataset`; `warned` = the FutureWarning flag.

---

### PO-1 — New-style path (claim R1)
**Obligation:** `c` present ∧ `d = None` ⇒ delegate called with `c`, `warned =
false`, returns `daOf(dset(c,u))`.
**Discharge:** symbolic execution, both `if` guards evaluate `false` (short-circuit
on `d isNotNone = false`); no alias, no warn; `dsetIntegrate(c,u) → dset(c,u)`.
See `PROOF.md` §R1. **Status: discharged (constructed).**

### PO-2 — Deprecated path (claim R2)
**Obligation:** `c = None` ∧ `d` present ⇒ `coord` is reassigned to `d`, a
`FutureWarning` is emitted (`warned = true`), delegate called with `d`, returns
`daOf(dset(d,u))`.
**Discharge:** first guard `false` (`c isNotNone = false`); second guard `true`
(`d isNotNone ∧ c isNone`); body runs `coord = dim` then `warn()`; delegate sees
`d`. See `PROOF.md` §R2. **Status: discharged (constructed).**

### PO-3 — Conflict guard (claim R3)
**Obligation:** `c` present ∧ `d` present ⇒ `ValueError("Cannot pass both 'dim'
and 'coord'. Please pass only 'coord' instead.")`, delegate **not** called,
`warned = false`.
**Discharge:** first guard `true and true = true`; `raiseValueError(M)` discards
the remaining computation, sets `<out> = raised(M)`; `dset` never evaluated;
`<warned>` untouched. See `PROOF.md` §R3. **Status: discharged (constructed).**

### PO-4 — Degenerate path resolution (claim R4)
**Obligation:** `c = None` ∧ `d = None` ⇒ delegate called with `None`, `warned =
false`, returns `daOf(dset(None,u))`.
**Discharge:** both guards `false`; no alias, no warn; `dsetIntegrate(None,u) →
dset(None,u)`. See `PROOF.md` §R4. **Status: discharged (constructed)** for the
*resolution* step. The runtime error inside the delegate is PO-6/PO-7.

### PO-5 — Behavior preservation (corollary of R1 & R2) — **core property**
**Obligation:** for every present value `X`, the new spelling `coord=X`, the
deprecated `dim=X`, and the legacy positional `X` all drive the **same**
delegated computation `dset(X,u)`; they differ **only** in the `warned` flag.
**Discharge:** R1 reaches `dset(tok(CI),U)` with `warned=false`; R2 reaches
`dset(tok(DI),U)` with `warned=true`; instantiating `CI = DI = X` makes the
delegated terms syntactically identical. Legacy positional `X` binds `coord=X`
(it is the first positional parameter) ⇒ identical to R1. **Status: discharged
(constructed).** This is what makes the deprecation *result-preserving*.

### PO-6 — Falsy-but-valid names (abstraction faithfulness)
**Obligation:** any non-`None` hashable (including falsy `0`, `""`, `False`) is
treated as "present", because the guards use `is not None`, not truthiness.
**Discharge:** the `tok(_)` abstraction in `mini-python.k` collapses all non-None
values to a single "present" case; the `isNotNone`/`isNone` rules are defined by
identity to `None` only. A truthiness-based guard would need a *third* case
(falsy-present) that behaves like None — it does not exist here. **Status:
discharged (constructed)** — confirms `FINDINGS` F-3, rules out the truthiness
bug.

### PO-7 — Delegate contract (assumed; `[ESCALATION BOUNDARY]`)
**Obligation (assumed, not proved here):**
(a) `dset(X,u)` for an existing 1-D coordinate name `X` performs the trapezoidal
integration (the `for c in coord` loop + `trapz` in unchanged
`Dataset.integrate`/`_integrate_one`);
(b) `dset(None,u)` and `dset(<missing/2-D>,u)` raise `ValueError` at runtime.
**Why assumed:** the fix does not change this code; verifying it needs
list/loop + floating-point/array reasoning beyond the bundled tier.
**Status: ESCALATION BOUNDARY** — explicitly assumed, **not** faked as
`[trusted]` arithmetic; covered by the existing numerical tests, which we keep.

### PO-8 — No internal caller regresses (whole-program side condition)
**Obligation:** introducing the `FutureWarning` must not make *unrelated* code
warn. **Discharge:** grep of `repo/` shows no production or test call to
`DataArray.integrate(dim=...)` other than this method's own docstring; the only
internal call (`self._to_temp_dataset().integrate(coord, datetime_unit)`) targets
`Dataset.integrate`, which has no `dim` parameter. **Status: discharged
(evidence-based).**

### PO-9 — Warning category & stacklevel
**Obligation:** the deprecation must be a `FutureWarning` (visible to users by
default, matching xarray convention) with `stacklevel=2` (so it points at the
caller). **Discharge:** by inspection of the V1 source (`dataarray.py:3554`,
`warnings.warn(msg, FutureWarning, stacklevel=2)`); consistent with
`core/computation.py` / `core/rolling.py`. **Status: discharged
(by inspection).**

---

## Coverage / no-gaps argument
The input domain partitions exhaustively into the four mutually-exclusive,
collectively-exhaustive cases (`c∈{None,present}` × `d∈{None,present}`), each
covered by PO-1..PO-4. PO-5/PO-6 are cross-cutting properties over those cases;
PO-7 is the assumed delegate boundary; PO-8/PO-9 are whole-program/quality side
conditions. There is no fifth case, so the case analysis is complete.
