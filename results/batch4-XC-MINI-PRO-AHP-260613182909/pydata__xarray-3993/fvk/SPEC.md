# SPEC.md — formal specification of the V1 fix for pydata/xarray #3993

**Target:** `DataArray.integrate` in `repo/xarray/core/dataarray.py` (lines
3483–3557), specifically the **argument-resolution logic** the V1 fix
introduced. **Status: CONSTRUCTED, NOT MACHINE-CHECKED** (FVK MVP — we do not
run `kompile`/`kprove`; see `PROOF.md` for the exact commands).

Artifacts: `mini-python.k` (fragment semantics), `mini-python-spec.k` (the four
reachability claims), this note, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`,
`PROOF.md`, `ITERATION_GUIDANCE.md`.

---

## 1. Intent (what the code is *supposed* to do)

From `benchmark/PROBLEM.md`: `DataArray.integrate` was the only one of the four
calculus methods that named its primary argument `dim`; the other three
(`Dataset.integrate`, `Dataset.differentiate`, `DataArray.differentiate`) use
`coord`. The intent is to make `DataArray.integrate` use **`coord`** too, while
**not breaking** existing code that passes `dim=...` — i.e. a **deprecation
cycle**: keep `dim` working but emit a warning, and keep the *numerical* result
identical.

So the intended contract is a **pure argument-resolution decision** layered on
top of the unchanged numerical delegate `Dataset.integrate`:

> Resolve a single *effective coordinate* `c` from `(coord, dim)`, optionally
> emit a deprecation warning, then delegate to the (unchanged)
> `Dataset.integrate(c, datetime_unit)`. The resolution must be
> **behavior-preserving**: for any coordinate value, the new spelling
> `coord=X`, the deprecated spelling `dim=X`, and the legacy positional `X` all
> drive the *same* delegated computation, differing only in whether a warning
> fires.

## 2. The function being formalized (V1, transcribed)

```python
def integrate(self, coord=None, datetime_unit=None, *, dim=None):
    if dim is not None and coord is not None:
        raise ValueError("Cannot pass both 'dim' and 'coord'. Please pass only 'coord' instead.")
    if dim is not None and coord is None:
        coord = dim
        warnings.warn(msg, FutureWarning, stacklevel=2)   # msg mentions `coord`
    ds = self._to_temp_dataset().integrate(coord, datetime_unit)
    return self._from_temp_dataset(ds)
```

`*` makes `dim` **keyword-only**; `coord` is the first positional parameter.

## 3. Domain abstraction

Every argument is abstracted to **`None`** or **`tok(_)`** ("some present,
non-None value"). This is faithful because the resolution logic only ever tests
`is not None` / `is None` — it never inspects the value. In particular `tok(_)`
also represents **falsy-but-valid** names such as `0`, `""`, `False` (these are
*not* `None`), which a truthiness test would mishandle but `is not None` does
not (see `FINDINGS` F-3).

The numerical delegate `self._to_temp_dataset().integrate(c, u)` →
`self._from_temp_dataset(...)` is abstracted to the opaque value
`daOf(dset(c, u))`. The fix does not change it; its correctness (the `for c in
coord` loop, `trapz`, datetime handling) is pre-existing and separately tested
(`FINDINGS` F-6, `PROOF_OBLIGATIONS` PO-7).

## 4. The contract — a 4-case decision table

Let `c` = `coord`, `d` = `dim`, `u` = `datetime_unit`. Precondition for the
"happy path" is **not both present**. The full table (proved as claims R1–R4):

| case | `coord` | `dim` | effective coord forwarded | warning? | observable result |
|------|---------|-------|---------------------------|----------|--------------------|
| R1 new-style | present `X` | None | `X` | **no** | `daOf(dset(X, u))` |
| R2 deprecated | None | present `X` | `X` | **yes** (`FutureWarning`) | `daOf(dset(X, u))` |
| R3 conflict | present | present | — (none) | no | `ValueError("Cannot pass both 'dim' and 'coord'. …")` |
| R4 degenerate | None | None | `None` | no | `daOf(dset(None, u))` → delegate raises `ValueError("Coordinate None does not exist.")` at runtime |

**Postcondition, stated once:** the effective coordinate is
`coord if coord is not None else (dim if dim is not None else None)`, a warning
is emitted **iff** the chosen value came from `dim` (i.e. `dim is not None and
coord is None`), and the two-present case is rejected before any delegation.

## 5. Reachability claims (see `mini-python-spec.k`)

Each row is one `[all-path]` K claim over `mini-python.k`, started from a store
binding `coord`, `datetimeUnit`, `dim` to the abstracted inputs and asserting
the final `<warned>` flag and `<out>` value:

- **R1**: `coord|->tok(CI), dim|->None` ⇒ `<out> = daOf(dset(tok(CI),U))`, `<warned>=false`.
- **R2**: `coord|->None, dim|->tok(DI)` ⇒ `<out> = daOf(dset(tok(DI),U))`, `<warned>=true`.
- **R3**: `coord|->tok(CI), dim|->tok(DI)` ⇒ `<out> = raised("Cannot pass both …")`, `<warned>=false`.
- **R4**: `coord|->None, dim|->None` ⇒ `<out> = daOf(dset(None,U))`, `<warned>=false`.

A fifth, *derived* property (no separate claim file entry; it is a corollary of
R1+R2, see `PROOF_OBLIGATIONS` PO-5) is the **behavior-preservation** statement:
for any present `X`, R1 and R2 reach the **same** `dset(X,U)` — only `<warned>`
differs. This is the heart of "a deprecation must not change results."

## 6. Why this spec was *easy* to write (a good signal)

Per FVK, difficulty writing a clean spec is a bug signal; conversely, this spec
is a clean, total, 4-case table with a one-line precondition ("not both
present") and no awkward case splits. That cleanliness is positive evidence the
V1 logic has no hidden corner case beyond the single documented degenerate case
(R4 / `FINDINGS` F-5), which is an already-invalid call that still errors.

## 7. Trusted base / residual risk

- **Mini-X adequacy.** The fragment in `mini-python.k` models only the resolution
  logic; the numerical delegate and Python exception *propagation* are abstracted
  (R4's runtime error happens inside the trusted delegate — `PROOF_OBLIGATIONS`
  PO-6/PO-7, an explicit escalation boundary, **not** faked as `[trusted]` math).
- **Partial correctness.** There is no loop in the changed code, so termination
  of the resolution logic is immediate; termination/perf of the delegate is out
  of scope.
- **Constructed, not machine-checked.** See the Honesty gate in `PROOF.md`.
