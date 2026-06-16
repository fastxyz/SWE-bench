# FVK Findings

Status: constructed, not machine-checked.

## F-001: V1 fixed the runtime support-floor guard

- Classification: resolved code bug.
- Evidence: `PROOF_OBLIGATIONS.md` PO-001 and PO-002.
- Input: SQLite version tuple `(3, 8, 7)`.
- V1/V2 expected result: `ImproperlyConfigured` with a message requiring SQLite
  3.9.0 or later.
- Status: resolved by V1 in `repo/django/db/backends/sqlite3/base.py`.

## F-002: V1 left current public docs advertising SQLite 3.8.3 support

- Classification: resolved public documentation mismatch.
- Evidence: `PROOF_OBLIGATIONS.md` PO-003.
- Input: developer reads current SQLite notes or GeoDjango install table.
- V1 observed result: active docs still stated SQLite 3.8.3 / 3.8.3+ support.
- Expected result: active docs state SQLite 3.9.0 / 3.9.0+ support.
- Status: resolved in V2 by updating `repo/docs/ref/databases.txt` and
  `repo/docs/ref/contrib/gis/install/index.txt`.

## F-003: JSON1 must remain runtime-detected

- Classification: confirmed non-change.
- Evidence: `PROOF_OBLIGATIONS.md` PO-004.
- Input: SQLite 3.9.0+ compiled without JSON1.
- Expected result: Django must still report JSONField support based on the
  runtime JSON function probe, not solely on the version floor.
- Status: no source change. V1 correctly left `supports_json_field` as a runtime
  probe.

## F-004: Expression-index support is not actionable in this checkout

- Classification: confirmed non-change.
- Evidence: `PROOF_OBLIGATIONS.md` PO-005.
- Input: audit of this checkout's generic `Index` API.
- Observed result: `Index` does not expose expression-index arguments in this
  branch.
- Expected result: do not invent a new API as part of this support-floor issue.
- Status: no source change.

## Unresolved Findings

None.
