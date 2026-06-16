# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbol

`sklearn.ensemble.IsolationForest.__init__`

## Compatibility checks

| Check | Result | Evidence |
| --- | --- | --- |
| Keyword call `IsolationForest(warm_start=True)` | Supported in V2 | `warm_start=False` is present in the public signature and is passed to `BaseBagging`. |
| Default call `IsolationForest()` | Preserved | The new parameter defaults to `False`, matching `BaseBagging`'s default. |
| Existing keyword calls for `n_jobs`, `behaviour`, `random_state`, `verbose` | Preserved | The V2 signature retains all names and forwards old keywords unchanged. |
| Existing positional calls through `verbose` | Preserved in V2 | `warm_start` is appended after the old parameters. |
| Subclass overrides of `IsolationForest` | None found in public source | `rg` found no `class ... IsolationForest` definitions under `repo/`. |
| Public in-repo callsites | No update required | Public examples use keyword arguments, so V1 did not break them, but positional compatibility still matters for external users. |

## V1 compatibility failure

V1 placed `warm_start` before `n_jobs`. An old positional call of the form

```python
IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)
```

previously meant:

```text
n_jobs=3, behaviour="new", random_state=0, verbose=1
```

Under V1 it would mean:

```text
warm_start=3, n_jobs="new", behaviour=0, random_state=1, verbose=0
```

That is a public API regression. V2 fixes it by appending `warm_start` after
`verbose`.
