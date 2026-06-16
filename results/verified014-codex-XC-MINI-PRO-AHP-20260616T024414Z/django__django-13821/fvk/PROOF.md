# Constructed Proof

Status: constructed, not machine-checked.

## Target

The target is `check_sqlite_version()` from
`repo/django/db/backends/sqlite3/base.py`, abstracted as
`checkSqliteVersion(version(M, N, P), S)` where `(M, N, P)` is
`Database.sqlite_version_info` and `S` is `Database.sqlite_version`.

## Proof Sketch

There are no loops or recursive calls, so the proof is a direct case split on
the version comparison.

### Case 1: `version(M, N, P) < version(3, 9, 0)`

By definition of `below390`, the side condition of the first
`checkSqliteVersion` rule holds. One symbolic rewrite step changes the `<k>`
cell from:

```k
checkSqliteVersion(version(M, N, P), S)
```

to:

```k
raised("SQLite 3.9.0 or later is required (found " +String S +String ").")
```

This proves PO-001.

### Case 2: `version(M, N, P) >= version(3, 9, 0)`

The precondition of `accept-sqlite-390-or-newer` states
`notBool below390(version(M, N, P))`. Therefore the side condition of the second
`checkSqliteVersion` rule holds. One symbolic rewrite step changes the `<k>`
cell from:

```k
checkSqliteVersion(version(M, N, P), S)
```

to:

```k
ok
```

This proves PO-002.

## Documentation and Frame Obligations

PO-003 is discharged by V2 documentation edits: the active SQLite notes and
GeoDjango install table now state 3.9.0 / 3.9.0+.

PO-004 is discharged by frame inspection: `supports_json_field` still executes a
runtime `SELECT JSON(...)` probe and catches `OperationalError`.

PO-005 is discharged by scope inspection: this checkout's `Index` constructor is
field-based and does not expose expression-index arguments, so adding that API
would be outside this support-floor fix.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` paraphrases both K claims. `SPEC_AUDIT.md` marks each
claim as passing against `INTENT_SPEC.md`. `PUBLIC_COMPATIBILITY_AUDIT.md` found
no unhandled callsites, overrides, signature changes, return-shape changes, or
storage format changes.

## Residual Risk

The proof is constructed only. The K toolchain was not run, and this minimal
semantics abstracts away general Python import mechanics and exception objects.
It is a proof of the support-floor branch behavior, not of all SQLite backend
behavior.

## Machine-Check Commands

These commands are for a future environment with K installed and were not
executed here:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell sqlite-version-spec.k
kprove sqlite-version-spec.k
```

Expected result after successful machine checking: `kprove` returns `#Top`.

## Test Recommendation

No tests were read or modified. If tests were available, in-domain point tests
for versions below and at/above 3.9.0 would be candidates for proof subsumption
only after machine checking. Boundary and integration tests should be kept.
