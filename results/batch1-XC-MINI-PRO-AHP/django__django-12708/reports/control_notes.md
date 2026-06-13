# Control notes — review & revision of the V1 fix (django__django-12708)

This documents the outcome of a systematic review of the V1 fix. Findings are in
`review/FINDINGS.md` (referenced below as F1–F12). The short version: V1's
*behavior* is correct and stands; the only edit made in this pass is a cosmetic
single-line collapse of the changed call.

## The fix that stands (behavior)

`django/db/backends/base/schema.py`, `alter_index_together()`:

```python
self._delete_composed_index(model, fields, {'index': True, 'unique': False}, self.sql_delete_index)
```

(was `{'index': True}`).

## Decisions and their justification

### D1 — Keep the behavioral change (`unique=False` added). Traces to F1, F2, F4, F5.

The added `unique=False` predicate is what fixes the reported crash: on MySQL,
SQLite, and Oracle the `unique_together` constraint is introspected with
`index=True` (F2), so the old `{'index': True}` filter matched two constraints and
tripped the `len != 1` guard. Filtering out unique constraints leaves exactly the
non-unique `index_together` index (F1). It cannot misfire, because an
`index_together` index is created via plain `CREATE INDEX` and is therefore always
`unique=False` on every backend (F4), and the no-unique-together common case still
yields exactly one match, identical to before (F5). Confirmed correct → kept.

### D2 — Do NOT mirror the change onto `alter_unique_together`. Traces to F3.

It is tempting to make the unique-deletion path symmetric
(`{'unique': True, 'index': True}`). The review showed this would *introduce* a
regression: on PostgreSQL the unique constraint has `index=False`, so the added
`index=True` would match zero rows and raise. The unique side must remain
`{'unique': True}` only. The asymmetry between the two methods is therefore correct
and intentional, and line 380 is left untouched.

### D3 — Do NOT widen/relax the `len(constraint_names) != 1` guard. Traces to F10.

An alternative "robustness" approach would be to loop over all matches or pick the
first. Rejected: the strict guard is valuable — it still catches genuinely
ambiguous or missing constraints. V1 fixes the *cause* of the spurious second match
rather than masking the symptom, so the guard stays as-is.

### D4 — Do NOT change the introspection backends. Traces to F2.

The bug could also be "fixed" by making MySQL/SQLite/Oracle stop reporting unique
constraints with `index=True`. Rejected: on those databases a unique constraint
genuinely *is* index-backed, other `_constraint_names` callers may rely on that, and
it is a far broader, riskier change. The targeted caller-side filter is the correct
locus.

### D5 — No change needed for the MySQL override or `Meta.indexes`/`constraints`
interactions. Traces to F7, F9.

The MySQL `_delete_composed_index` override forwards `*args`, so the new
`constraint_kwargs` propagate automatically (F9). Co-located `Meta.indexes` /
`Meta.constraints` objects are already excluded by name inside
`_delete_composed_index` (F7). Both paths keep working with no edit.

### D6 — Collapse the call to a single line (the only edit this pass). Traces to F11.

V1 had reformatted the call across six lines. The sibling `alter_unique_together`
deletion is a single line and the new call is 111 chars (< the project's 119-char
limit, setup.cfg). I collapsed it back to one line for a minimal, symmetric diff.
This is purely cosmetic — zero behavioral effect — and makes the two parallel
methods read consistently.

### D7 — Leave issue "point 2" (index relocation) unaddressed. Traces to F12.

The reporter's secondary wish — that moving a declaration from `index_together` to
`Meta.indexes` not drop+recreate the index — is a migration-autodetector concern,
independent of the schema-editor crash, and explicitly speculative in the issue
hint. Fixing it would require broad autodetector changes outside the minimal scope.
The concrete, reproducible failure (point 1) is fully resolved by D1.

## Net change vs V1

- Behavior: **unchanged** from V1 (still `{'index': True, 'unique': False}`),
  re-confirmed correct across MySQL, SQLite, Oracle, and verified a no-op on
  PostgreSQL.
- Code: one cosmetic edit (D6 / F11) — multi-line call collapsed to a single line.
- `reports/baseline_notes.md` (the V1 write-up) is retained as the V1 record;
  this file supersedes it for the post-review state.
