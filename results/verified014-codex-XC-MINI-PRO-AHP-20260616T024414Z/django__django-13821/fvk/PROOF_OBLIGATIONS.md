# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Reject SQLite versions below 3.9.0

- Source: evidence E1.
- Formal claim: `reject-sqlite-below-390` in `fvk/sqlite-version-spec.k`.
- Domain: nonnegative integer version components.
- Obligation: if `below390(version(M, N, P))` holds, the guard raises the
  3.9.0 `ImproperlyConfigured` message.
- Disposition: discharged by symbolic execution over the first K rule for
  `checkSqliteVersion`.

## PO-002: Accept SQLite 3.9.0 and later

- Source: evidence E1 and E2.
- Formal claim: `accept-sqlite-390-or-newer` in `fvk/sqlite-version-spec.k`.
- Domain: nonnegative integer version components.
- Obligation: if `below390(version(M, N, P))` does not hold, the guard returns
  normally.
- Disposition: discharged by symbolic execution over the second K rule for
  `checkSqliteVersion`.

## PO-003: Keep active public docs consistent with the support floor

- Source: evidence E5 and E6.
- Obligation: active documentation entries that state the supported SQLite
  version must say 3.9.0 or later.
- Disposition: V2 updates the current database docs and GeoDjango install table.
  Historical release notes are excluded because they describe past releases.

## PO-004: Preserve JSON1 runtime detection

- Source: evidence E3.
- Obligation: do not replace `supports_json_field` with a pure
  `sqlite_version_info >= (3, 9, 0)` constant.
- Disposition: V2 makes no change to the runtime JSON function probe.

## PO-005: Do not add expression-index API surface in this branch

- Source: baseline source audit and `SPEC.md` scope.
- Obligation: because this checkout's generic `Index` API has no expression
  arguments, the support-floor change does not imply adding a new expression
  index API here.
- Disposition: V2 makes no expression-index API change.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were
not executed in this session.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell sqlite-version-spec.k
kprove sqlite-version-spec.k
```
