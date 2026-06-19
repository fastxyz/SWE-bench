# django__django-14434 — FVK analysis

- **Verdict:** D_EQUIVALENT — fvk reproduced the exact upstream human fix verbatim, but its 3 extra lines over baseline are a pure raw-string refactor; baseline's single-line change already fixes the bug completely and behaves identically across the whole reference interface (verified by execution).
- **Pitch-worthiness (1-5):** 1 — there is no "passed tests but still wrong" story here; baseline is genuinely correct, so this instance does not demonstrate the hypothesis.

## The issue
`BaseDatabaseSchemaEditor._create_unique_sql()` built a deferred SQL `Statement` for a unique constraint/index. It accidentally passed a `Table` *object* where a raw table-name *string* was expected when constructing the constraint's `Columns` reference. As a result `Statement.references_column(table, column)` always returned `False`, so Django could not recognize that the unique SQL referenced a column — e.g. deferred unique SQL could be left stale when its column was dropped.

## What baseline did
Baseline made the minimal targeted fix: it changed the one broken consumer so `_index_columns()` receives the raw `model._meta.db_table` string instead of the `Table` object.
```python
table = Table(model._meta.db_table, self.quote_name)          # unchanged (object)
name  = IndexName(model._meta.db_table, columns, '_uniq', ...) # unchanged (already raw)
columns = self._index_columns(model._meta.db_table, columns, ...)  # FIXED: object -> raw str
columns = Expressions(model._meta.db_table, expressions, ...)  # unchanged (already raw)
Statement(..., table=table, ...)                              # unchanged (object, correct here)
```
This is the complete behavioral fix: the only part whose `.table` was wrong was `columns`, and baseline corrected exactly that.

## What fvk changed and why
fvk hoisted `table = model._meta.db_table` (raw string), reused that raw `table` for `IndexName`, `_index_columns`, and `Expressions`, and re-wrapped it as `Table(table, self.quote_name)` only at the `Statement(table=...)` site. fvk's stated rationale (fvk_notes.md D-001/D-003) is a "raw-name-first invariant" matching the sibling `_create_index_sql()`. This is a readability/consistency refactor, not an additional behavioral fix. fvk's patch is byte-for-byte identical to the human gold patch.

## Concrete demonstration
I reconstructed all three versions (ORIGINAL/BASELINE/FVK) of the method, monkeypatched them onto the real `connection.schema_editor()`, and exercised the full `Reference` interface on `UniqueConstraint(fields=['name'])` against a real model (sqlite, in-tree Django 4.0.dev).

ORIGINAL bug reproduced (explicit name, references_column):
```
ORIGINAL  references_column('demoapp_author','name') = False   <-- the reported bug
BASELINE  references_column('demoapp_author','name') = True
FVK       references_column('demoapp_author','name') = True
```
Baseline vs fvk, every observable (both name=None and explicit name='name_uq'):
```
                       BASELINE            FVK
references_column        True              True     SAME
references_table         True              True     SAME
rename_column_references identical SQL + identical refs   SAME
rename_table_references  identical SQL + identical refs   SAME
rendered SQL (__str__)   identical                        SAME
```
There is no input that distinguishes baseline from fvk — they are behaviorally identical. (An earlier harness appeared to show a difference; that was a test-harness artifact: a shared mutable ['name'] list mutated by rename_column_references leaking between runs. With a defensive copy the difference vanished.) Mechanistically they must agree: in the ORIGINAL, IndexName and Expressions already received the raw string (they were never the bug); Table.references_table/rename_table_references operate on the inner raw string regardless of wrapping; so baseline's object graph and fvk's object graph carry the same table-name values in every reference-bearing part.

## Why the tests missed it
They didn't. The FAIL_TO_PASS test test_unique_constraint (added in gold_test.patch) asserts sql.references_table(table) is True and sql.references_column(table, 'name') is True. I applied the test patch and ran it on BOTH reconstructed solutions:
```
FVK      schema.tests.SchemaTests.test_unique_constraint ... ok
BASELINE schema.tests.SchemaTests.test_unique_constraint ... ok
BASELINE unique-constraint cluster (8 tests incl. func/composite/quoting) ... OK
```
The hidden test fully and correctly catches the original bug and passes on baseline because baseline is a correct fix — not because the test is weak.

## Gold comparison
fvk matches the human gold fix exactly (identical diff). Baseline is a strict 1-line subset of gold's 4-line change. Gold's 3 extra edits are the same refactor fvk applied, e.g.:
```python
-        name = IndexName(model._meta.db_table, columns, '_uniq', create_unique_name)
+        name = IndexName(table, columns, '_uniq', create_unique_name)   # table == model._meta.db_table
```
These substitute one expression for an equal-valued one (table = model._meta.db_table) — cosmetic, value-preserving. So fvk is "closer to gold" only in source text, not in behavior.

## Confidence & caveats
High confidence. Evidence is executable, not argued: ORIGINAL reproduces the bug (False); BASELINE and FVK are byte-checked against baseline.patch/gold.patch and produce identical results across references_table/column, both rename methods, and rendered SQL, for both name modes; both pass the official FAIL_TO_PASS test and the unique-constraint PASS_TO_PASS cluster. The "gold-overlap = fvk added 4 gold-confirmed lines baseline lacked" signal is real at the text level but those lines are an equal-value refactor with no behavioral effect (PostgreSQL's _index_columns override also receives the identical raw string in both). fvk_FINDINGS.md itself concedes (F-002) that V1/baseline "was behaviorally correct"; this audit confirms it. Conclusion: genuine but cosmetic convergence on gold; not a correctness improvement over baseline -> D_EQUIVALENT (leaning E_COSMETIC, but classified D since real code expressions changed).
