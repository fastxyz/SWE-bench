# FVK notes — audit and revision of the V1 fix for pydata__xarray-6992

This documents what the Formal Verification Kit pass changed, and why, tracing
every decision to `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`. Artifacts:
`fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
`fvk/ITERATION_GUIDANCE.md`, plus the constructed K files `fvk/reset_index.k` and
`fvk/reset_index-spec.k`.

## What V1 was

V1 changed one line at the end of `Dataset.reset_index`:

```python
coord_names = (set(new_variables) | self._coord_names) - set(drop_variables)   # V1
```

restoring the invariant that the issue's `ValueError: __len__() should return >= 0`
violated.

## What the FVK audit established

Writing the spec (`fvk/SPEC.md`) made the real contract explicit: the property at
stake is a **Dataset class invariant**

> **INV:** `set(_coord_names) ⊆ set(_variables)`,

which makes `DataVariables.__len__ = len(_variables) − len(_coord_names) ≥ 0`
(`SPEC.md` §2). `reset_index` carries the obligation "given an input satisfying
INV, produce an output satisfying INV" (`PROOF_OBLIGATIONS.md` **PO1**, corollary
**PO5**). The constructed proof (`fvk/PROOF.md` §2) discharges PO1 by elementary,
**induction-free** finite set algebra — confirming V1's *placement* (fix the
producer `reset_index`, not the consumer `DataVariables.__len__`) is correct
(**FINDINGS F2/F6/F7**), and discharging the MVCE (**PO6**, PROOF §3).

So **V1's location and direction were right.** The audit then surfaced one reason
to *refine* the exact expression.

## The one change this pass makes (V1 → V2)

```python
coord_names = (self._coord_names - set(drop_variables)) | set(new_variables)   # V2
```

i.e. subtract `drop_variables` (`D`) **first**, then union `new_variables` (`N`),
instead of unioning first and subtracting last.

**Why — traced to the artifacts:**

1. **FINDINGS F3 + PO2 (the deciding obligation).** Formalizing P2 ("a coordinate
   recreated in `new_variables` stays a coordinate") exposed a corner the issue
   never mentions: when `dims_or_levels` names *both* a multi-index dimension and a
   level with `drop=True` on a ≥3-level multi-index, `keep_levels` re-emits the
   dimension coordinate, so `N ∩ D ≠ ∅`. Under V1's `(N ∪ C) − D`, that recreated
   name is unioned in and then **deleted by `− D`**, leaving it as a *data variable
   that still carries an index* — a different malformed state (PO2 **fails** under
   V1). Under V2's `(C − D) ∪ N`, the name is re-added after the subtraction, so it
   stays a proper index coordinate (PO2 **discharged**). See `fvk/PROOF.md` §5 for
   the side-by-side VC table.

2. **FINDINGS F8 + PROOF §5 (no on-domain risk).** The two forms are **provably
   equal whenever `N ∩ D = ∅`** — which is every realistic and tested input,
   including the MVCE (`N = ∅`). So V2 changes nothing on the verified/ tested
   domain (PO4 frame condition for `drop=False`, PO6 for the MVCE both still hold
   identically) and only differs on the F3 corner, where it is strictly more
   consistent.

3. **FINDINGS F6 + I5 + PO7 (consistency).** The sibling `set_index` (dataset.py
   line 4102) already uses exactly `self._coord_names - set(drop_variables) |
   set(new_variables)`. V2 makes the two analogous methods share one idiom,
   removing the asymmetry that let only `reset_index` carry the bug.

This is the "minimal refinement justified by the FVK artifacts" the task invites:
same single line, same complexity, strictly stronger postcondition (adds PO2 to
PO1), and idiom parity with `set_index`.

## What was deliberately NOT changed, and why

- **`DataVariables.__len__` (the symptom site, line ~368).** Left untouched.
  `FINDINGS F2` / PO1 show it is correct *given* INV; clamping or re-counting it
  would mask invariant-breaking producers and still leave `Dataset.identical`
  (compares `_coord_names`), `data_vars`, `to_dataframe`, and indexing misbehaving.
  The principled fix is in the producer.

- **The multi-key `drop=True` keep/drop *value* semantics (PO9 / FINDINGS F3,
  `ITERATION_GUIDANCE` G3).** Whether a reduced index *should* survive when the
  dimension itself is reset is underspecified intent, out of scope for #6992. V2
  only guarantees the output is *well-formed* for whatever names the existing logic
  keeps; it does not redesign that logic. PROOF §4 shows PO1/PO2 hold for arbitrary
  `D, N`, so this is safe to leave open.

- **`dims` recomputation (FINDINGS F5 / PO10 / G4).** `reset_index` keeps
  `self._dims`; benign because every reachable output retains ≥1 variable per
  surviving dimension. Pre-existing, no INV impact, changing it would be unrelated
  churn.

- **No new internal invariant assertion** (G1) was added, to keep the change
  minimal; it is recorded as an optional next-iteration recommendation.

- **No test files touched** (forbidden, and unnecessary): existing `drop=False`
  tests are guaranteed unchanged by PO4; the `drop=True` tests
  (`test_dataset`/`test_dataarray::test_reset_index` case 5, `test_groupby`
  pipeline) are discharged by PO1/PO3/PO6. Test-redundancy is recommendation-only
  and **conditioned on `kprove` returning `#Top`** (`fvk/PROOF.md` §6–7); the
  honest recommendation is to keep all tests — the value here is the
  consistency/bug finding, not test pruning.

## Net effect

The user-visible behaviour for the issue's MVCE and for every existing test is
identical to V1 (and fixes the crash): `ds.set_index(z=['a','b']).reset_index("z",
drop=True)` returns a consistent Dataset with `len(data_vars) == 0` and a working
repr (`PROOF.md` §3). V2 additionally guarantees PO2 on the `N ∩ D` corner and
unifies the idiom with `set_index`. The fix remains a single line in
`xarray/core/dataset.py`.
