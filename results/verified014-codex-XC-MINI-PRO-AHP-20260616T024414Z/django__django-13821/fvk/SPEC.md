# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-13821`, whose public issue
requires dropping support for SQLite versions older than 3.9.0. The proof target
is the SQLite backend support-floor guard:

- `repo/django/db/backends/sqlite3/base.py::check_sqlite_version()`

The audit also covers current public documentation entries that state the active
SQLite support floor:

- `repo/docs/ref/databases.txt`
- `repo/docs/ref/contrib/gis/install/index.txt`

`repo/django/db/backends/sqlite3/introspection.py` is included as a frame item
because V1 changed only a stale compatibility comment there.

## Intent Ledger

| ID | Public evidence | Obligation |
| --- | --- | --- |
| E1 | `benchmark/PROBLEM.md`: "Drop support for SQLite < 3.9.0" | Reject every SQLite version tuple below `(3, 9, 0)`. |
| E2 | `benchmark/PROBLEM.md`: "SQLite 3.11.0 (which will still by supported by Django)" | Accept SQLite versions newer than the new floor. |
| E3 | `benchmark/PROBLEM.md`: "SQLITE_ENABLE_JSON1 compile-time option" | Keep JSON1 as runtime capability detection, not merely a version implication. |
| E4 | Current backend source calls `check_sqlite_version()` at import time. | Enforce the support floor before normal backend use. |
| E5 | Current docs state Django's supported SQLite version. | Current docs must advertise 3.9.0 or later after the support drop. |

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the full ledger.

## Formal Contract

Let `version(M, N, P)` represent `Database.sqlite_version_info` and `S` represent
`Database.sqlite_version`.

1. If `M.N.P < 3.9.0`, `check_sqlite_version(version(M, N, P), S)` reaches
   `raised("SQLite 3.9.0 or later is required (found " + S + ").")`.
2. If `M.N.P >= 3.9.0`, `check_sqlite_version(version(M, N, P), S)` reaches
   `ok`.

The formal K claims are in `fvk/sqlite-version-spec.k`, using the fragment in
`fvk/mini-python.k`.

## Adequacy Summary

The formal claims match the public issue: they reject exactly versions below
3.9.0 and accept 3.9.0 and later. The proof does not claim that JSON1 is always
available on 3.9.0+ because the public issue describes JSON1 as compile-time
optional; Django's runtime JSON feature probe remains in place.

No loops or recursive calls exist in the audited function, so no circularity
claim is needed.

## Trusted Base and Limits

This is a constructed FVK proof over a minimal semantics fragment, not a
machine-checked proof. It abstracts Python import mechanics to the call of
`check_sqlite_version()` and models only the support-floor branch behavior.
The emitted K commands in `fvk/PROOF.md` were not executed, per task constraints.
