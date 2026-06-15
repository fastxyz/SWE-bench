# Public Evidence Ledger

| ID | Source | Public excerpt | Obligation |
| --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | `("name"DESC)` should be `("name" DESC)` | Put one separator between quoted column and non-empty order suffix. |
| E-2 | `benchmark/PROBLEM.md` | `("name" text_pattern_ops )` has whitespace after `text_pattern_ops`; expected `("name" text_pattern_ops)` | Suppress empty order suffixes and avoid trailing whitespace. |
| E-3 | `benchmark/PROBLEM.md` | `When used with a descending order it will look correct.` | Preserve correct tokenization for opclass plus descending suffix. |
| E-4 | `repo/django/db/models/indexes.py:30-33` | `# A list of 2-tuple with the field name and ordering ('' or 'DESC').` | Treat suffixes as bare tokens from the public producer. |
| E-5 | `repo/django/db/models/indexes.py:25-26` | `Index.fields and Index.opclasses must have the same number of elements.` | Model opclass lookup as defined for every indexed column when opclasses are in use. |
| E-6 | `repo/django/db/backends/base/schema.py:981-982` | `return Columns(...)` | Normal index rendering uses `Columns`. |
| E-7 | `repo/django/db/backends/postgresql/schema.py:177-180` | `if opclasses: return IndexColumns(...)` | PostgreSQL opclass rendering uses `IndexColumns`. |
| E-8 | `repo/django/db/backends/ddl_references.py:93,124` | `return ', '.join(...)` | Multi-column delimiter is comma-space and should be preserved. |
