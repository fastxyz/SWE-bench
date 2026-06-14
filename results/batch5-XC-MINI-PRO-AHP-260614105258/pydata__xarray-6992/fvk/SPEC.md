# SPEC — `Dataset.reset_index` and the `DataVariables` length invariant

Target: `xarray/core/dataset.py` — `Dataset.reset_index(dims_or_levels, drop=False)`
and the class invariant it must preserve, which `DataVariables.__len__` relies on.

This is **intent-spec mode**: the contract below captures the *intended* behaviour
(from the issue, docstrings, and tests); the implementation is checked against it.
Default scope is **partial correctness** (correct results *if* the method returns;
it always returns — there are no loops over unbounded data).

---

## 1. The object under specification

Two pieces of code, one invariant linking them.

```python
# xarray/core/dataset.py
class DataVariables(Mapping[Any, "DataArray"]):
    def __len__(self) -> int:
        return len(self._dataset._variables) - len(self._dataset._coord_names)   # line ~368
```

`DataVariables` enumerates the *data* variables of a Dataset = the variables that
are **not** coordinates. `__len__` computes that count by subtraction, which is
correct **iff** every coordinate name backs an actual variable.

```python
# xarray/core/dataset.py  (the fixed line, end of reset_index)
variables   = {k: v for k, v in self._variables.items() if k not in drop_variables}
variables.update(new_variables)
coord_names = (self._coord_names - set(drop_variables)) | set(new_variables)   # FIX (V2)
return self._replace(variables, coord_names=coord_names, indexes=indexes)
```

## 2. The class invariant (the property to preserve)

> **INV (well-formedness):** `set(ds._coord_names) ⊆ set(ds._variables)`.

Every `Dataset` must satisfy INV. It is the implicit contract of the whole class:
coordinates are a distinguished subset of the variables. `DataVariables.__len__`,
`.data_vars`, `repr`, `to_dataframe`, indexing, and `Dataset.identical`
(`self._coord_names == other._coord_names`) all assume it.

**Corollary (the crash the issue reports):** if INV holds then, for finite sets,
`|coord_names| ≤ |variables|`, so
`DataVariables.__len__ = len(_variables) − len(_coord_names) ≥ 0`. Python's
`list`/`Sequence` protocol requires `__len__() ≥ 0`; violating INV makes the
subtraction negative and raises `ValueError: __len__() should return >= 0`.

`reset_index` is a Dataset→Dataset transformation, so it carries a **proof
obligation**: *given* an input satisfying INV, its output must satisfy INV.
(See `PROOF_OBLIGATIONS.md`.) This is the inductive step of the class invariant;
`reset_index` was the unique method that broke it (see `FINDINGS.md` F1, F6).

## 3. Set model of `reset_index`'s tail

Let, for the input `self`:

| symbol | meaning |
|---|---|
| `V` | `set(self._variables)` — input variable names |
| `C` | `self._coord_names` — input coordinate names (INV: `C ⊆ V`) |
| `D` | `set(drop_variables)` — names removed (only when `drop=True`) |
| `N` | `set(new_variables)` — names (re)created by the multi-index "keep levels" path |

The tail of `reset_index` computes:

```
keys(variables) = (V − D) ∪ N         # comprehension drops D, then update adds N
coord_names     = (C − D) ∪ N         # V2 fix  (set_index uses this exact form)
```

## 4. Contract of `reset_index`

**Precondition (`requires`):** `C ⊆ V` (the input Dataset satisfies INV).

**Postcondition (`ensures`):**

- **P1 (INV preserved / the headline property):** `coord_names ⊆ keys(variables)`.
  Hence `len(variables) − len(coord_names) ≥ 0`: `DataVariables.__len__` never
  raises and the repr/`data_vars` work.
- **P2 (created coords are present & remain coords):** `N ⊆ keys(variables)` and
  `N ⊆ coord_names`. A level coordinate recreated by `keep_levels` stays a
  coordinate (never demoted to a data variable, even if its name also appears in
  `D` — the `N ∩ D ≠ ∅` corner; see `FINDINGS.md` F3).
- **P3 (drop semantics):** for `x ∈ D \ N`, `x ∉ keys(variables)` and
  `x ∉ coord_names` — a coordinate named in `dims_or_levels` with `drop=True`,
  and not recreated, is fully removed.
- **P4 (frame condition for `drop=False`):** when `drop=False`, `D = ∅`, so
  `coord_names = C ∪ N` and `keys(variables) = V ∪ N` — i.e. **`drop=False`
  behaviour is byte-for-byte unchanged** from the pre-fix code. All `reset_index`
  semantics asserted by existing tests for `drop=False` are preserved.

Termination is trivial (straight-line set operations + finite comprehensions over
`dims_or_levels` and the variable mapping); there is no unbounded loop.

## 5. Public intent ledger

| # | source | evidence (quoted) | obligation | status |
|---|---|---|---|---|
| I1 | prompt / `PROBLEM.md` | "we can end up with more `_coord_names` than `_variables` which breaks a number of stuff (e.g. the repr)" | output must satisfy INV `C' ⊆ V'` (P1) | **discharged** (V2) |
| I2 | prompt / `PROBLEM.md` | "`ValueError: __len__() should return >= 0`" + pointer to `DataVariables.__len__` (line 368) | `len(V') − len(C') ≥ 0` (corollary of P1) | **discharged** (V2) |
| I3 | prompt MVCE | `ds.set_index(z=['a','b']).reset_index("z", drop=True)` must not raise | the `drop=True` multi-index-dim path must satisfy P1 | **discharged** (V2) — see PROOF §3 |
| I4 | code: `DataVariables.__iter__`/`__contains__`/`__getitem__` | data var ⇔ `key in _variables and key not in _coord_names` | INV makes `__len__` agree with `__iter__` cardinality | **discharged** (P1) |
| I5 | code: `set_index` line 4102 `self._coord_names - set(drop_variables) \| set(new_variables)` | sibling reset/replace methods keep INV via `(C−D)∪N` | use the same form for consistency (P2) | **discharged** (V2 adopts it) |
| I6 | docstring: `drop=True` "remove the specified indexes and/or multi-index levels instead of extracting them as new coordinates"; `drop=False` "extract … as new coordinates" | P3 (drop removes named coords) / P4 (drop=False keeps them) | **discharged** — matches `test_(dataset\|dataarray).py::test_reset_index` |
| I7 | tests: `test_dataarray.py::test_reset_index` case 5 `reset_index("x", drop=True)` ⇒ coords `{level_1, level_2}` | resetting a multi-index *dimension* with `drop=True` drops only the dim coord, keeps levels | **discharged** — P3 with `D={x}`, `N=∅` ⇒ `C'={level_1,level_2}` |
| I8 | tests: `test_groupby.py:540` `.reset_index("id", drop=True)` in an end-to-end pipeline | the `drop=True` path must yield a consistent Dataset usable by downstream `drop_vars`/`assign` | **discharged** (P1) — see FINDINGS F1 trace |

No requirement document beyond the issue exists; intent is taken from the issue
text, the method docstrings, and the public test suite (the tests are read as
intent evidence only — they are **not** modified).

## 6. Trusted base / residual risk

- The mini-X fragment in `reset_index.k` faithfully models *only* the post-loop
  set algebra; the `for name in dims_or_levels` loop is summarised by its outputs
  `(D, N)` (justified in `PROOF.md` §4). Adequacy of that abstraction is trusted.
- Proof is **constructed, not machine-checked** (no `kprove` run here).
- Partial correctness only (termination not separately proved; trivial here).
- INV on the *input* is assumed (precondition `C ⊆ V`); this is the standard class
  invariant maintained by Dataset constructors and every other method (F6).
