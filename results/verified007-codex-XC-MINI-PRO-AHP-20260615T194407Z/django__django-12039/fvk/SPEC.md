# SPEC: CREATE INDEX Column Whitespace

Status: constructed, not machine-checked. No tests, Python, or K tooling were executed.

## Target

This FVK pass audits the V1 change in `repo/django/db/backends/ddl_references.py`, specifically:

- `Columns.__str__()`
- `IndexColumns.__str__()`

These helpers render the column list used by `CREATE INDEX` statements through `BaseDatabaseSchemaEditor._create_index_sql()` and PostgreSQL's `_index_columns()` override.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | `benchmark/PROBLEM.md` | `CREATE INDEX "idx" ON "schema_author" ("name"DESC)` should be `("name" DESC)` | A non-empty index-order suffix must be separated from the quoted column by one SQL token separator. | Encoded by PO-1 and K claim `PLAIN-NONEMPTY-SUFFIX`. |
| INT-2 | `benchmark/PROBLEM.md` | `("name" text_pattern_ops )` has unwanted whitespace after `text_pattern_ops`; expected `("name" text_pattern_ops)` | Empty order suffixes must be omitted, not rendered as a trailing separator, when opclasses are present. | Encoded by PO-3 and K claim `INDEX-EMPTY-SUFFIX`. |
| INT-3 | `benchmark/PROBLEM.md` | `When used with a descending order it will look correct.` | Opclass plus descending order should preserve the correct shape: column, opclass, and order as separate tokens. | Encoded by PO-4 and K claim `INDEX-NONEMPTY-SUFFIX`. |
| INT-4 | `repo/django/db/models/indexes.py:30-33` | `# A list of 2-tuple with the field name and ordering ('' or 'DESC').` | In-scope `col_suffixes` entries are token strings: `''` for ascending/default order or `DESC` for descending order. | Domain assumption for PO-1 through PO-4. |
| INT-5 | `repo/django/db/models/indexes.py:25-26` | `Index.fields and Index.opclasses must have the same number of elements.` | In-scope opclass rendering can assume one opclass token per indexed field. | Encoded by PO-3 and PO-4; preserves the existing precondition. |
| INT-6 | `repo/django/db/backends/base/schema.py:981-982` and `repo/django/db/backends/postgresql/schema.py:177-180` | Base backends use `Columns`; PostgreSQL uses `IndexColumns` when `opclasses` is truthy. | The fix must satisfy both normal indexes and PostgreSQL opclass indexes without changing public signatures. | Encoded by PO-5 and compatibility audit. |

Quoted legacy outputs in the issue are marked SUSPECT as expected behavior because the issue identifies them as the bug. They are used only as observed-bad examples.

## Intended Contract

For every in-scope rendered index column:

1. `Columns.__str__()` renders each quoted column alone when its suffix is empty.
2. `Columns.__str__()` renders each quoted column followed by exactly one space and the non-empty suffix token when its suffix is non-empty.
3. `IndexColumns.__str__()` renders each quoted column followed by exactly one space and its opclass token.
4. `IndexColumns.__str__()` appends the order suffix as a third token only when the suffix is non-empty.
5. Multiple columns remain comma-space separated, preserving the pre-existing `', '.join(...)` behavior.
6. Public constructor/method signatures and dispatch shape are unchanged.

## Domain

The formalized domain is the public issue path:

- column names are strings consumed by `quote_name()`;
- quoted column names are SQL token strings returned by `quote_name()`;
- suffixes are `''` or bare non-empty suffix tokens such as `DESC`, as produced by `Index.fields_orders`;
- PostgreSQL opclasses are bare non-empty token strings, with one opclass per field.

Pre-spaced suffix fragments are outside the domain because the public producer evidence passes bare tokens. This is recorded as F-4, not as a code bug.

## Formal Core

The K-style artifacts are:

- `fvk/mini-python.k`: a minimal string-renderer semantics for the column-token fragment under audit.
- `fvk/index-columns-spec.k`: parametric claims for plain columns and opclass columns.

Exact commands to run later, not executed in this session:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/index-columns-spec.k
kprove fvk/index-columns-spec.k
```

Expected result after a real machine check: `#Top`.

## Adequacy Summary

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the intent-only obligations in `fvk/INTENT_SPEC.md`. No formal obligation is candidate-derived without public evidence. The proof covers the complete observable whitespace behavior named by the issue: normal suffix rendering, empty suffix omission, opclass rendering, opclass plus descending suffix, and multi-column delimiter preservation.
