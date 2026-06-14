# FINDINGS — `reset_index` / `DataVariables` (FVK audit of the V1 fix)

Plain-language findings, each as `input → observed vs expected`. Findings F1–F6
are from `/formalize` (writing the spec); F7–F9 are proof-derived (`/verify`).
The headline result: **the class invariant `coord_names ⊆ keys(variables)` is the
real specification, V1 restores it, and V2 (this pass) strengthens it on one
corner case and aligns it with the sibling `set_index`.**

---

## F1 — ROOT CAUSE: `reset_index` could produce `coord_names ⊄ variables` (the reported bug)

**Where:** `Dataset.reset_index`, the pre-V1 final line
`coord_names = set(new_variables) | self._coord_names`.

**Input:** `xr.Dataset(coords={"a": ("x", [1,2,3]), "b": ("x", ['a','b','c'])}).set_index(z=['a','b']).reset_index("z", drop=True)`.

**Trace:**
- after `set_index(z=['a','b'])`: dim `z`, `variables = {z,a,b}`, `coord_names = {z,a,b}`.
- in `reset_index("z", drop=True)`: `drop_variables=['z']`, `new_variables={}`, so
  `variables = {a,b}` but pre-V1 `coord_names = {} | {z,a,b} = {z,a,b}`.

**Observed:** `coord_names = {z,a,b} ⊄ {a,b} = keys(variables)`; `z` is a
coordinate name with no variable. `DataVariables.__len__ = 2 − 3 = −1` →
`ValueError: __len__() should return >= 0`; repr and `data_vars` break.
**Expected (spec P1/INV):** `coord_names ⊆ keys(variables)`, so `__len__ ≥ 0`.

**Set-algebra reason:** `(N ∪ C) ⊆ (V−D) ∪ N` fails exactly when some
`x ∈ C ∩ D` with `x ∉ N` (here `x = z`): `x` is in `coord_names` but `−D` from the
variables side removed it. The general bug is "`coord_names` keeps a dropped
name." **This is the unique invariant-breaking line.** Fixed by subtracting `D`.

## F2 — The reported symptom site (`DataVariables.__len__`) is correct *given* the invariant; fix the producer, not the consumer

**Where:** `DataVariables.__len__` (line ~368), the site the issue points at.
**Finding:** `len(_variables) − len(_coord_names)` is the right formula **iff**
INV holds. Clamping it (`max(0, …)`) or counting by iteration would *mask* a
malformed Dataset that still misbehaves elsewhere (`identical` compares
`_coord_names`; `data_vars`/`to_dataframe`/indexing all assume INV). **Expected
fix location:** the method that *creates* the malformed state. Confirmed:
`reset_index`. (No change to `__len__`.)

## F3 — CORNER CASE `N ∩ D ≠ ∅`: V1's formula keeps INV but demotes a recreated coordinate

**Where:** `reset_index` when `dims_or_levels` contains **both** a multi-index
*dimension* name and a *level* name, with `drop=True`, on a multi-index with **≥3
levels** (so ≥2 levels are kept and `keep_levels` returns a *multi*-index, whose
`create_variables` re-emits the dimension coordinate).

**Input (illustrative):** a Dataset with multi-index `x` over levels `l1,l2,l3`;
`ds.reset_index(["x", "l1"], drop=True)`.

**Trace:** `D = {x, l1}`; the level path keeps `{l2,l3}` → still a multi-index →
`new_variables` keys `N = {x, l2, l3}`. So `N ∩ D = {x} ≠ ∅`, and
`new_indexes` registers an index on `x`.

**Observed under V1** (`coord_names = (N ∪ C) − D`): `x ∈ N` but `−D` removes it,
so `x ∈ keys(variables)` (re-added by `update(new_variables)`) and
`x ∈ indexes` **but `x ∉ coord_names`** → `x` is a *data variable carrying an
index*: a different consistency violation (not a negative length, but still
malformed). INV (P1) still holds, but P2 fails.
**Expected (P2):** a name that is (re)created in `new_variables` is a coordinate.

**Observed under V2** (`coord_names = (C − D) ∪ N`): `x ∈ N` is re-added, so
`x` is a variable ∧ a coordinate ∧ an index → fully consistent. P2 holds.

**Severity / scope:** pre-existing, never covered by a test, only on this narrow
multi-key `drop=True` call; **not** the reported bug and **not** a V1 regression
(pre-V1 it was *also* broken here, with a negative length). V2 resolves it for
free by matching `set_index`'s form.

## F4 — Precondition surfaced: `reset_index` assumes a well-formed input (`C ⊆ V`)

Writing P1 required the precondition `self._coord_names ⊆ set(self._variables)`
(spec §4). This is **clean** (it is the class invariant), so it is *not* a
spec-difficulty bug signal — it is the inductive hypothesis. `reset_index` does
not, and need not, repair a malformed input; it must only *preserve* INV. Recorded
as the proof's `requires`.

## F5 — Minor: `dims` is not recomputed by `reset_index`

`reset_index` calls `self._replace(...)` without passing `dims`, so the output
keeps `self._dims`. In every reachable case at least one variable referencing each
original dimension survives (a kept level, or the multi-index coord), so `_dims`
stays correct; the repr's "Dimensions" line is consistent. Pre-existing behaviour,
unchanged by V1/V2, no INV impact. **Kept as-is** (out of scope; changing it would
be unrelated churn). Flagged only for completeness.

## F6 — INV has a single producer-bug; other `coord_names` builders are safe

Audited every `coord_names`/`_coord_names` assembly in `dataset.py`:
- `set_index` (line 4102): `self._coord_names - set(drop_variables) | set(new_variables)` — **subtracts D**, INV-safe. (V2 makes `reset_index` identical in shape.)
- `_reindex_callback` (line ~2815): `self._coord_names | set(new_indexes)` — only
  *adds* index names that are also in `new_variables`; reindex drops no coords, so
  `C ⊆ V` is preserved. INV-safe.
- `reset_index` — the **only** builder that omitted `− drop_variables`. F1.
This pinpoints the fix to one line and explains why `set_index` (same kind of
operation) never exhibited the bug.

---

## Proof-derived findings from `/verify`

## F7 — P1 discharges by pure finite set algebra; **no loop circularity needed**

Constructing the proof (PROOF §2) shows the obligation is a first-order set
inclusion `(C−D)∪N ⊆ (V−D)∪N` under `C ⊆ V`, with **no induction**: the Python
`for`-loop only *produces* `D` and `N`; `coord_names`/`variables` are computed by
straight-line bulk set operations afterwards. **Classification:** correctness
confirmed. The proof closes by two elementary lemmas (difference-monotonicity,
union-superset). That a clean, induction-free spec/proof exists is positive
evidence the fix is right and minimal.

## F8 — `(C−D)∪N` vs `(N∪C)−D`: equal on the verified domain, V2 strictly better off it

The VC makes the choice explicit. Both forms satisfy P1, and they are **equal
whenever `N ∩ D = ∅`** (which holds for every realistic/tested input, incl. the
MVCE where `N=∅`). They differ **only** on F3's corner, where `(C−D)∪N` also
satisfies P2 while `(N∪C)−D` does not. **Classification:** chosen code change.
**Recommended (and applied in V2):** `coord_names = (self._coord_names -
set(drop_variables)) | set(new_variables)` — also makes `reset_index` and
`set_index` share one idiom (I5/F6).

## F9 — `__len__ ≥ 0` is a corollary, not an independent obligation

Once P1 (`C' ⊆ V'`) is machine-checkable, `|C'| ≤ |V'|` for finite sets, so
`DataVariables.__len__ ≥ 0` follows with no extra proof. **Classification:** test
gap → the regression test for #6992 should assert the *structural* invariant
(e.g. `len(ds.data_vars) >= 0`, `set(ds.coords) <= set(ds.variables)`, repr
succeeds) rather than only that no exception is raised, because the invariant is
the actual contract. (Recommendation only — no test files are edited.)
