# SPEC — `_delete_composed_index` and its `alter_*_together` callers

Target: `django/db/backends/base/schema.py` (with the V1 fix applied), the
constraint-resolution path exercised by the bug
[`django__django-12708`](../benchmark/PROBLEM.md):

> *Migration crashes deleting an `index_together` if there is a `unique_together`
> on the same fields.*

Formal artifacts: [`schema_index.k`](schema_index.k) (mini fragment semantics),
[`schema_index-spec.k`](schema_index-spec.k) (reachability claims). **Constructed,
not machine-checked** — no K toolchain runs here; the claims are accompanied by the
domain-level discharge in [`PROOF.md`](PROOF.md).

---

## 1. What the code is (intent ↔ implementation)

Three functions cooperate. Their *intended* contracts, inferred from the issue, the
docstrings, the introspection backends, and the call sites:

### 1a. `_constraint_names(model, column_names, exclude=None, **kw)`

Pure query. Returns the **set of constraint names** on `model`'s table whose
introspected descriptor

- has `columns` **exactly equal** to `column_names` (ordered list compare), and
- matches **every** pinned keyword flag (`unique=`, `index=`, `primary_key=`,
  `check=`, `foreign_key=`, `type_=`), and
- is **not** in `exclude`.

Modeled in the fragment as the `filter` scan loop plus the abstraction
`cnames(CS, COLS, KW, EXCL)`.

### 1b. `_delete_composed_index(model, fields, constraint_kwargs, sql)`

Resolves `fields` to columns, builds `exclude = {Meta.constraints names} ∪
{Meta.indexes names}`, calls `_constraint_names(..., **constraint_kwargs)`, and:

- **precondition for success:** the returned set has **cardinality exactly 1**;
- **postcondition:** issue `sql` to drop that single constraint;
- **else:** raise `ValueError("Found wrong number (N) of constraints …")`.

Modeled as the `checkDelete` guard: `size(result)==1 ⇒ deleted(result)`, else
`valueError(size)`.

### 1c. The two callers choose `constraint_kwargs`

| caller | deletes | `constraint_kwargs` | fragment `KW` |
|---|---|---|---|
| `alter_unique_together` | a `unique_together` | `{'unique': True}` | `uniqFilter` |
| `alter_index_together` (V0, pre-fix) | an `index_together` | `{'index': True}` | `idxFilterV0` |
| `alter_index_together` (**V1, fixed**) | an `index_together` | `{'index': True, 'unique': False}` | `idxFilter` |

An `index_together` index is created by `_create_index_sql(model, fields,
suffix="_idx")` — a plain **non-unique** `CREATE INDEX`. A `unique_together`
constraint is created by `_create_unique_sql` — a **unique** constraint.

---

## 2. The model of the world (introspection facts)

For a 2-field model carrying both a `unique_together` and an `index_together` over
the same column tuple `(a, b)`, `get_constraints()` reports two descriptors over
`(a, b)`:

```
c_uniq = con(name_uniq, (a,b), unique=True,  index=IU)
c_idx  = con(name_idx,  (a,b), unique=False, index=True)
```

where `IU` ("is the unique constraint *also* reported as an index?") is
**backend-determined**:

| backend | `IU` | why (verified in source) |
|---|---|---|
| MySQL | **True** | `information_schema` marks it `unique`; `SHOW INDEX` then sets `index=True` on the same name (`mysql/introspection.py:263`). |
| SQLite | **True** | `PRAGMA index_list` reports the unique index with `unique=True, index=True` (`sqlite3/introspection.py:386-394`). |
| PostgreSQL | **False** | `pg_constraint` sets `unique=True, index=False`; the index loop skips the same-named row, so `index` stays `False` (`postgresql/introspection.py:171-174,210`). |

The two invariants that the whole fix rests on, true on **every** backend:

- **(INV-U)** the unique constraint is unique: `c_uniq.unique == True`.
- **(INV-I)** the index_together index is **never** unique and **is** an index:
  `c_idx.unique == False ∧ c_idx.index == True`.

Both `name_uniq` and `name_idx` come from `*_together`, so neither is in `exclude`
(which holds only `Meta.indexes`/`Meta.constraints` names).

---

## 3. The contracts (reachability claims)

Let `cnames(CS, COLS, KW, EXCL)` be the matching-name set (the abstraction in
`schema_index.k`). The three function contracts:

- **(FILTER)** — loop circularity: the `filter` scan over `CS` adds exactly
  `cnames(CS, COLS, KW, EXCL)` to the result accumulator. (`schema_index-spec.k`
  claim `(FILTER)`.)

- **(DEL-IDX)** — *V1 index deletion.* Precondition **PRE-IDX**:
  `size(cnames(CS, COLS, idxFilter, EXCL)) == 1`. Then
  `_delete_composed_index` reaches `deleted(cnames(...))` (no `ValueError`) and
  drops that one constraint. In the Django scenario the single survivor is
  `c_idx`, on **every** backend. (`(DEL-IDX)`.)

- **(DEL-UNIQ)** — *unique deletion (unchanged path).* Precondition **PRE-UNIQ**:
  `size(cnames(CS, COLS, uniqFilter, EXCL)) == 1`. Then it drops exactly
  `c_uniq`, on every backend. (`(DEL-UNIQ)`.)

And two diagnostic claims that pin the failure modes:

- **(DEL-IDX-V0)** — the **pre-fix** filter `idxFilterV0` on `IU=True`
  (MySQL/SQLite) reaches `valueError(2)`: this *is* the reported crash.
- **(DEL-IDX-DRIFT)** — with the `_idx` index already absent and only `c_uniq`
  left, the V1 filter reaches `valueError(0)` (safe loud failure) whereas the
  pre-fix filter would have size 1 and silently `DROP INDEX` the unique
  constraint.

---

## 4. Domain & residual risk

- **Domain.** Composite (multi-column) index/unique deletion where the column
  tuple carries at most one non-unique composite index not in `Meta.indexes` and
  at most one unique constraint not in `Meta.constraints`. This is exactly what
  `unique_together`/`index_together` can produce (each de-dupes by column-tuple
  set in the `alter_*_together` `news.difference(olds)` loop).
- **Out of domain / residual risk** (see [`FINDINGS.md`](FINDINGS.md)): a
  `unique_together` declared on the *primary-key* columns (F5); a second,
  independently-created non-unique composite index on identical columns (F8); the
  autodetector re-creating an index when its declaration *moves* between
  `index_together` and `Meta.indexes` (F6, the issue's secondary point — a
  no-op-churn concern, not a crash).
- **Trusted base.** The mini-fragment's adequacy to the real Python; the
  introspection facts in §2 (read from the backend source, not executed); the K
  reachability metatheory; and "constructed, not machine-checked".
- **Partial correctness.** All loops here are finite scans over a finite
  constraint list; termination is immediate, but per kit default we state partial
  correctness.
