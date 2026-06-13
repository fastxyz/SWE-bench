# PROOF OBLIGATIONS

Obligations that the V1 fix must satisfy for the contracts in [`SPEC.md`](SPEC.md).
Each is discharged in [`PROOF.md`](PROOF.md). Notation from SPEC §2–§3:
`c_uniq=(unique=True, index=IU)`, `c_idx=(unique=False, index=True)`, both over the
same column tuple `(a,b)`, neither name excluded; `IU` backend-determined.

The core of every obligation is a **set-cardinality** fact about
`cnames(CS, COLS, KW, EXCL)` — the number of constraints simultaneously matching
the column tuple, the kwargs, and the not-excluded test.

---

## OB-FILTER — the scan computes the matching set
`filter` run over a constraint list `CS` terminates with
`result = R ∪ cnames(CS, COLS, KW, EXCL)`. *(Loop circularity; underpins every
`size(result)` claim below.)*

## OB1 — DEL-IDX existence (≥ 1 match for the V1 index filter)
In the Django scenario, `cnames(CS, (a,b), idxFilter, EXCL) ⊇ {name_idx}`.
i.e. `c_idx` matches `{'index':True,'unique':False}`:
`c_idx.columns==(a,b) ∧ c_idx.index==True ∧ c_idx.unique==False ∧ name_idx∉EXCL`.

## OB2 — DEL-IDX uniqueness (≤ 1 match for the V1 index filter)
No *other* constraint over `(a,b)` matches `idxFilter`. The only other same-column
constraint is `c_uniq`, and `c_uniq.unique==True` ⇒ `kwMatch(idxFilter,True,IU) =
IU ∧ (True==False) = False`. So `c_uniq` is excluded **regardless of `IU`**.
⇒ `cnames(CS,(a,b),idxFilter,EXCL) = {name_idx}`, **size 1**, on every backend.

## OB3 — DEL-UNIQ existence (≥ 1 match for the unique filter)
`cnames(CS,(a,b),uniqFilter,EXCL) ⊇ {name_uniq}`: `c_uniq.unique==True` ⇒ matches
`{'unique':True}`; `name_uniq∉EXCL`.

## OB4 — DEL-UNIQ uniqueness (≤ 1 match for the unique filter)
No other constraint over `(a,b)` matches `uniqFilter`. The only other is `c_idx`
with `c_idx.unique==False` ⇒ `kwMatch(uniqFilter,False,True)=False` ⇒ excluded.
⇒ `cnames(CS,(a,b),uniqFilter,EXCL) = {name_uniq}`, **size 1**, on every backend.
*(This is why `alter_unique_together` needs no change.)*

## OB5 — No-regression / monotonicity of the added guard
For all `C`: `matches(C,COLS,idxFilter,EXCL) → matches(C,COLS,idxFilterV0,EXCL)`
(because `kwMatch(idxFilter,U,IX)=IX∧¬U` implies `kwMatch(idxFilterV0,U,IX)=IX`).
Hence `cnames(·,idxFilter,·) ⊆ cnames(·,idxFilterV0,·)`, and the two differ
exactly by the `unique=True` constraints. Therefore adding `'unique':False`:
1. **never drops** `c_idx` (it has `unique=False`), and
2. **removes exactly** the spurious `c_uniq` whenever `IU=True`.
⇒ V1 cannot introduce a *new* over-match (size never increases vs V0).

## OB6 — PRE-IDX / PRE-UNIQ hold in the real Django scenario
The preconditions of DEL-IDX/DEL-UNIQ (`size==1`) are *met*, not merely assumed:
- `index_together` creates exactly one non-unique `_idx` index per column tuple
  (de-duped by tuple in `alter_index_together`); ⇒ exactly one `c_idx`.
- `unique_together` creates exactly one unique constraint per tuple; ⇒ one `c_uniq`.
- Any same-column `Meta.indexes`/`Meta.constraints` entry is name-excluded.
Together with OB2/OB4 this gives `size==1` for both filters.

## OB7 — Crash reproduction & fix (DEL-IDX-V0)
With the **pre-fix** filter and `IU=True` (MySQL/SQLite),
`cnames(CS,(a,b),idxFilterV0,EXCL) = {name_uniq, name_idx}`, **size 2** ⇒
`ValueError("Found wrong number (2) …")`. V1 (OB2) reduces this to size 1.
*(Demonstrates the audited fix actually resolves the reported failure.)*

## OB8 — Latent wrong-deletion closed (DEL-IDX-DRIFT)
If the `_idx` index is absent (DB drift) and only `c_uniq` remains, on `IU=True`
the pre-fix filter has `cnames = {name_uniq}` (**size 1**) and would
`DROP INDEX name_uniq` — silently destroying the unique constraint. Under V1,
`kwMatch(idxFilter,True,True)=False` ⇒ `cnames = {}` (**size 0**) ⇒ `ValueError`
(safe, loud). *(V1 strictly improves safety here; not a regression.)*

---

### Capability boundary (not code bugs — see FINDINGS F5/F6/F8)
- **[OUT-OF-DOMAIN]** `unique_together` on PK columns: `c_pk.unique==True`, so the
  *unique* filter could see size 2 (`c_pk` + `c_uniq`). Pre-existing, orthogonal to
  this fix, and not reachable from the issue's scenario. Not modeled.
- **[OUT-OF-DOMAIN]** a second independent non-unique composite index on identical
  columns not in `Meta.indexes`: would break OB2's "only other is `c_uniq`". Django
  cannot auto-generate this; flagged, not modeled.
- **[OUT-OF-SCOPE]** issue point 2 (index *re-creation* when a declaration moves
  between `index_together` and `Meta.indexes`): an autodetector/optimizer concern,
  not a schema-editor cardinality obligation. No crash; no obligation here.
