# Iteration Guidance

Status: constructed, not machine-checked.

## Code and Docs

V2 should stand:

- Keep the V1 runtime guard change in
  `repo/django/db/backends/sqlite3/base.py`.
- Keep the V1 introspection comment cleanup in
  `repo/django/db/backends/sqlite3/introspection.py`.
- Keep the V2 documentation updates in `repo/docs/ref/databases.txt` and
  `repo/docs/ref/contrib/gis/install/index.txt`.
- Do not change JSON1 detection into a pure version flag.
- Do not add expression-index API surface as part of this issue.

## Suggested Tests for a Normal Development Environment

Do not add tests in this benchmark task, but a normal follow-up should cover:

- SQLite `(3, 8, 7)` or `(3, 8, 99)` rejects with an
  `ImproperlyConfigured` message requiring SQLite 3.9.0.
- SQLite `(3, 9, 0)` is accepted.
- SQLite `(3, 11, 0)` is accepted.
- JSONField support remains gated by the runtime JSON function probe.

## Machine Verification

The emitted FVK commands should be run only in an environment with K installed:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell sqlite-version-spec.k
kprove sqlite-version-spec.k
```

Until then, the proof remains constructed, not machine-checked.
