# FINDINGS.md — pydata/xarray #3993 (V1 fix audit)

Plain-language findings, each as `input → observed vs expected`. Findings are
**non-blocking advice**. Most here are *positive* (the audit confirms a property
the fix gets right); F-5/F-6/F-8 are scoped/escalation notes. None is a bug.

Legend: ✅ confirmed-correct · ⚠️ accepted limitation · 🔎 scope/escalation.

---

## ✅ F-1 — Conflicting `coord` + `dim` is rejected (positive)
- **input:** `da.integrate(coord="x", dim="x")` (or any two non-None values).
- **observed:** raises `ValueError("Cannot pass both 'dim' and 'coord'. Please
  pass only 'coord' instead.")` *before* delegating; no warning, no computation.
- **expected:** an ambiguous mix of the new and deprecated spelling should be
  rejected with a clear message.
- **verdict:** correct. Proved as claim **R3** (`PROOF_OBLIGATIONS` PO-3). The
  guard is the *first* statement, so it fires before the alias branch — order
  matters and is right.

## ✅ F-2 — Deprecation warns only on the `dim=` keyword, never on positional (positive, important)
- **input A:** `da.integrate("x")` (legacy positional, now binds `coord`).
- **observed A:** no warning; forwards coord `"x"`.
- **input B:** `da.integrate(dim="x")`.
- **observed B:** emits `FutureWarning`, forwards `"x"`.
- **expected:** the *recommended* call form (positional / `coord=`) must stay
  warning-free; only the explicitly deprecated `dim=` keyword should warn.
- **verdict:** correct, and it matters: the global test config
  (`repo/setup.cfg` `[tool:pytest] filterwarnings`) does **not** turn warnings
  into errors, but even a stricter local `filterwarnings("error")` would not be
  tripped by the common positional path, because no warning fires there. Proved
  by R1 (no warn) vs R2 (warn). Because `dim` is **keyword-only** (`*` in the
  signature), positional use can never accidentally bind `dim`.

## ✅ F-3 — `is not None` (not truthiness) handles falsy-but-valid names (positive)
- **input:** `da.integrate(0)` where a dimension/coordinate is literally named
  `0`; also `da.integrate(dim=0)`.
- **observed:** `0 is not None` is `True`, so `0` is treated as a *present*
  coordinate and forwarded (with a warning in the `dim=0` case).
- **expected:** falsy hashable names (`0`, `""`, `False`) are valid coordinates
  and must not be treated as "absent".
- **verdict:** correct. Had the guards used truthiness (`if dim and not
  coord:`), `dim=0` would have been silently dropped — a real bug the V1 code
  avoids. Captured by the `tok(_)` abstraction in `SPEC` §3 / PO-6.

## ✅ F-4 — Backward compatibility / behavior preservation (positive, core property)
- **input:** every legacy form — `da.integrate("x")`, `da.integrate("x", "D")`,
  `da.integrate(("y","x"))`, `da.integrate("time", datetime_unit="D")`.
- **observed:** each binds to `coord` (and `datetime_unit`) and reaches the
  *same* delegated computation `Dataset.integrate(coord, datetime_unit)` as
  before the fix — i.e. identical numerics. The existing visible tests
  (`repo/xarray/tests/test_dataset.py` lines ~6575–6655) all use these forms and
  remain green.
- **expected:** a deprecation must not change results, only the API surface.
- **verdict:** correct. This is the corollary PO-5: for present `X`,
  `coord=X` / `dim=X` / positional `X` all yield `dset(X,U)`; only the warning
  flag differs.

## ⚠️ F-5 — Degenerate call `da.integrate()` errors with a deeper message (accepted)
- **input:** `da.integrate()` (neither `coord` nor `dim`).
- **observed (V1):** `coord=None` is forwarded; the **unchanged** delegate
  raises `ValueError("Coordinate None does not exist.")`.
- **observed (pre-fix):** `dim` was a required positional, so this raised
  `TypeError: integrate() missing 1 required positional argument: 'dim'`.
- **expected:** an error either way (a coordinate is mandatory).
- **verdict:** accepted, **not fixed**. Severity: cosmetic — only the error
  *type/message* changed for an already-invalid call; no valid program is
  affected. Adding a dedicated guard (e.g. raise a clear
  `TypeError`/`ValueError` up front) is an *optional* clarity improvement; we
  decline it to keep the fix minimal and to avoid any (tiny) risk of conflicting
  with an expected error type. Tracked as PO-6 and in `ITERATION_GUIDANCE`.

## 🔎 F-6 — Numerical core is abstracted, not re-verified (escalation boundary)
- The trapezoidal integration — the `for c in coord` loop in `Dataset.integrate`
  and the array ops/`trapz`/datetime conversion in `_integrate_one` — is
  **unchanged** by this fix and is abstracted as the opaque `dset(coord, unit)`.
- Re-verifying it would require list/loop + floating-point/array reasoning
  beyond the bundled arithmetic tier — an explicit `[ESCALATION BOUNDARY]`. It is
  **assumed** (PO-7), not faked as `[trusted]` math, and is covered by the
  existing numerical tests, which we **keep** (`PROOF.md` §Test-redundancy).

## ✅ F-7 — The reported inconsistency is resolved (the issue itself)
- **before:** `da.integrate(dim=...)` vs `ds.integrate(coord=...)` /
  `*.differentiate(coord=...)` — inconsistent.
- **after:** all four methods take `coord`; `DataArray.integrate` additionally
  accepts a deprecated keyword-only `dim`. `Dataset.integrate`,
  `Dataset.differentiate`, `DataArray.differentiate` already used `coord` and
  were correctly left untouched (verified by grep: only the DataArray wrapper
  used `dim`).
- **verdict:** the fix is correctly *scoped* — exactly the one inconsistent
  method, nothing more.

## 🔎 F-8 — Deprecation is documented (doc, not tested)
- `DataArray.integrate` docstring marks `dim` `.. deprecated:: 0.17.0`; a
  "Deprecations" entry was added to `doc/whats-new.rst` naming a removal target
  of 0.19.0. The removal version is a *plan*, not enforced or tested; it is
  consistent with deprecating in the current dev version (0.17.0, per
  `whats-new.rst`). No action needed; flagged for confirmation in
  `ITERATION_GUIDANCE`.

---

## Spec-difficulty signal
Writing the spec was **easy**: a clean, total 4-case decision table with a
one-line precondition ("not both present") and no awkward splits. Per the FVK
methodology, an easy clean spec is positive evidence of no hidden corner case —
the only edge (F-5) is an already-invalid input that still errors.

## Proof-derived findings from `/verify`
No proof obstacle arose for the changed code: all four claims discharge by
direct symbolic execution (no circularity, no nonlinear VC). The only obligation
that cannot be discharged in the bundled tier is **PO-7** (the abstracted
numerical delegate), surfaced above as F-6 and marked `[ESCALATION BOUNDARY]`,
not as a code defect.
