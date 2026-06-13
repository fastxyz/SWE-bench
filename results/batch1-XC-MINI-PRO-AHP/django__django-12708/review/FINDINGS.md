# Code review — V1 fix for django__django-12708

V1 changed `BaseDatabaseSchemaEditor.alter_index_together()` in
`django/db/backends/base/schema.py` so the composed-index deletion filter is
`{'index': True, 'unique': False}` instead of `{'index': True}`.

Below are the review findings, numbered. Each is marked **[OK]** (V1 behavior is
correct / confirmed), **[FIX]** (a change was made), or **[OUT OF SCOPE]**.

---

## F1 — Core correctness against the reported crash — [OK]

The issue: deleting an `index_together` while a `unique_together` exists on the same
fields raises `ValueError: Found wrong number (2) of constraints`.

`_delete_composed_index()` resolves the constraint to drop via
`_constraint_names(model, columns, **constraint_kwargs)` and requires exactly one
match. With `{'index': True}` the filter matched *both* the unique constraint and
the plain index, because on the affected backends a unique constraint is backed by
an index and is introspected with `index=True`.

Traced through `_constraint_names()` (schema.py:1142-1170) with
`unique=False, index=True`:
- unique-together row `{unique:True, index:True}` → `infodict['unique'] (True) !=
  unique (False)` is True → `continue` → **excluded**.
- index-together row `{unique:False, index:True}` → passes both the `unique` and
  `index` checks → **included**.

Result: exactly one match → the `len(constraint_names) != 1` guard passes → the
correct (`_idx`) index is dropped. The crash is resolved. **Confirmed.**

## F2 — Cross-backend validity of the filter — [OK]

Verified the `get_constraints()` introspection of every bundled backend to confirm
the unique-together constraint is excluded and the index-together index is kept:

- **MySQL** (`mysql/introspection.py`): unique constraint gets `unique=True` from
  `information_schema.table_constraints`, then the same-named row from `SHOW INDEX`
  sets `index=True` (~line 263). Bug present originally; fixed by `unique=False`.
- **SQLite** (`sqlite3/introspection.py`): `PRAGMA index_list` yields the unique
  index as `unique=True, index=True` (~lines 386-394). Bug present; fixed.
- **Oracle** (`oracle/introspection.py`): unique constraint stored with
  `'index': unique` i.e. `index` truthy — comment "All uniques come with an index"
  (line 234). Bug present; fixed. (Note: Oracle yields `unique` as integer `1`/`0`;
  `1 != False` is `True` in Python, so the unique row is still correctly excluded —
  see F8.)
- **PostgreSQL** (`postgresql/introspection.py`): unique constraint is added from
  `pg_constraint` with `index=False` (line 174); the backing index is *skipped* by
  the later index loop because the name already exists (`if index not in
  constraints`). So `_uniq` has `index=False` and never matched `{'index': True}`
  in the first place. **PostgreSQL was never affected**; the fix is a behavioral
  no-op there (the `_idx` still matches; `_uniq` excluded by either predicate).

Conclusion: fix repairs MySQL/SQLite/Oracle and leaves PostgreSQL unchanged.

## F3 — The asymmetry with `alter_unique_together` is intentional and must stay — [OK]

A natural "symmetry" instinct would be to also constrain the unique-deletion path
(line 380) to `{'unique': True, 'index': True}`. **That would be a bug.** On
PostgreSQL the unique constraint has `index=False`, so adding `index=True` there
would match *zero* rows → `ValueError`. The unique side must therefore stay
`{'unique': True}` only. Conversely, the index side genuinely needs the extra
`unique=False` because unique constraints pollute the `index=True` set on most
backends. The asymmetry is correct and deliberate. **No change to line 380.**

## F4 — `unique=False` can never exclude the legitimate target — [OK]

An `index_together` index is created by `_create_index_sql(..., suffix="_idx")`,
which renders `sql_create_index = "CREATE INDEX ..."` — never `CREATE UNIQUE
INDEX` (schema.py:87 vs 88). A non-unique index is, by definition, introspected
with `unique=False` on every backend. Therefore adding the `unique=False` predicate
can only ever exclude *unique* constraints, never the index we intend to drop. No
risk of turning a previous 1-match into a 0-match. **Safe on all backends.**

## F5 — Regression check: `index_together` with no `unique_together` — [OK]

When only an `index_together` exists, the `_idx` row is `{unique:False,
index:True}`. Old filter `{'index': True}` → 1 match. New filter
`{'index': True, 'unique': False}` → still 1 match. Identical behavior; the SQL
emitted is unchanged. No regression for the common case.

## F6 — Edge case: both `unique_together` and `index_together` removed together — [OK]

These are separate schema operations (`AlterUniqueTogether`, `AlterIndexTogether`)
run as separate editor calls; their order is decided by the autodetector/optimizer.
Both orders are safe:
- unique-first: `_uniq` dropped via `{'unique': True}` (1 match), then `_idx`
  dropped via `{'index': True, 'unique': False}` (1 match).
- index-first: `_idx` dropped while `_uniq` still present — `unique=False` excludes
  `_uniq`, so still 1 match — then `_uniq` dropped (1 match).
No ordering-dependent crash remains for this pairing.

## F7 — Interaction with `Meta.indexes` / `Meta.constraints` — [OK]

`_delete_composed_index()` already passes `exclude=meta_constraint_names |
meta_index_names` to `_constraint_names()`. A `UniqueConstraint`/`Index` declared
in `Meta` is matched by name and excluded, so a co-located `Meta.indexes` index on
the same columns (also `unique=False, index=True`) does not create a second match.
V1 does not touch this path; it keeps working.

## F8 — Type coercion in the `unique` comparison (Oracle integers) — [OK]

`_constraint_names()` compares with `!=`, not identity. Oracle stores `unique` as
`1`/`0`. The passed predicate value is Python `False`. `1 != False` → `True`
(unique row excluded); the index row stores literal `False` (oracle/
introspection.py:286) so `False != False` → `False` (kept). Behaves correctly
despite the int/bool mismatch.

## F9 — MySQL `_delete_composed_index` override propagation — [OK]

`mysql/schema.py:115` overrides `_delete_composed_index(self, model, fields,
*args)` and forwards `super()._delete_composed_index(model, fields, *args)`. The new
`constraint_kwargs` ride through `*args` unchanged, so the fix applies on MySQL too.
The override's separate FK-index check uses `_constraint_names(model,
[first_field.column], index=True)` on a *single* column — unrelated to the composed
(multi-column) filter and unaffected by this change.

## F10 — Error handling unchanged and appropriate — [OK]

The strict `len(constraint_names) != 1` guard (raising on 0 *or* >1) is preserved.
V1 turns the spurious "2" back into "1" for the bug scenario without weakening the
guard, so a genuinely missing/ambiguous index is still reported loudly. Preferable
to silently iterating/dropping an arbitrary match.

## F11 — Style / minimal-diff consistency — [FIX]

V1 expanded the single call into a 6-line trailing-comma form. The sibling
`alter_unique_together` deletion (line 380) is a single line, and the new call is
111 chars — under the project's `max-line-length = 119` (setup.cfg:61). For a
minimal, symmetric diff I collapsed it back to a single line:

```python
self._delete_composed_index(model, fields, {'index': True, 'unique': False}, self.sql_delete_index)
```

Purely cosmetic; no behavioral effect.

## F12 — Issue point 2 ("moving an index shouldn't recreate it") — [OUT OF SCOPE]

The reporter raises a secondary wish: relocating a declaration from `index_together`
to `Meta.indexes` should not drop+recreate the index. That is an autodetector/
optimizer enhancement (the reporter's own hint about operation ordering is explicitly
speculative — "I haven't looked under the hood"). It is independent of the concrete
`_delete_composed_index` crash, would require broad changes in
`db/migrations/autodetector.py`, and is not needed to stop the reported failure.
Deliberately not addressed, to keep the fix minimal and targeted (per task
constraints). The crash (point 1) is fully fixed.

---

## Verdict

V1's behavioral change is correct, minimal, and robust across all four bundled
backends, with the only adjustment being the cosmetic single-line collapse in F11.
No other source change is warranted.
