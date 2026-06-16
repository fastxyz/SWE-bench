# Public Evidence Ledger

| ID | Source | Quote / evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "AlterField operation should be noop when adding/changing choices on SQLite." | SQLite choices-only changes must be classified as no-op. |
| E2 | `benchmark/PROBLEM.md` | "new table + insert + drop + rename" | Reaching SQLite table remake for choices-only changes is the reported bug. |
| E3 | `benchmark/PROBLEM.md` | "would cause a regression for third-party enum fields" | Do not ignore `choices` globally. |
| E4 | `benchmark/PROBLEM.md` | "safely overwrite `_field_should_be_altered()` only on SQLite" | Apply the behavior in SQLite only. |
| E5 | Source code | Base `_field_should_be_altered()` strips a fixed local list of non-database attrs. | Preserve that list and make SQLite extend it. |
| E6 | Source code | SQLite `alter_field()` returns immediately when `_field_should_be_altered()` is false. | The no-op decision point is sufficient to prevent table remake. |
