# Public Evidence Ledger

Status: constructed for FVK, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Drop support for SQLite < 3.9.0" | SQLite versions lexicographically less than 3.9.0 are out of Django's supported runtime domain. | Encoded in `sqlite-version-spec.k` claims and implemented in `base.py`. |
| E2 | `benchmark/PROBLEM.md` | "Ubuntu Xenial ships with SQLite 3.11.0 (which will still by supported by Django)" | Versions greater than 3.9.0 remain accepted; the support drop must not reject 3.11.0. | Encoded by the accept claim for all versions not below 3.9.0. |
| E3 | `benchmark/PROBLEM.md` | "SQLITE_ENABLE_JSON1 compile-time option" | JSON1 support must not be inferred solely from the numeric SQLite version. | Preserved by leaving `supports_json_field` as a runtime probe. |
| E4 | `repo/django/db/backends/sqlite3/base.py` | `check_sqlite_version()` is called at module import. | The import-time guard is the source mechanism that enforces the SQLite support floor before backend use. | Used as implementation evidence in the K semantics. |
| E5 | `repo/docs/ref/databases.txt` | Current SQLite notes state the supported SQLite version. | Current docs must match the new 3.9.0 floor. | V2 updates the line to 3.9.0. |
| E6 | `repo/docs/ref/contrib/gis/install/index.txt` | GeoDjango install table lists SQLite supported versions. | Current GeoDjango docs must match the new 3.9.0 floor. | V2 updates the table entry to 3.9.0+. |
| E7 | Source search | `check_sqlite_version` has no callsites beyond its definition and import-time call. | The V2 change preserves the function signature and has no public override/callsite compatibility burden. | Recorded in `PUBLIC_COMPATIBILITY_AUDIT.md`. |
