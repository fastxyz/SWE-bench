# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbols: none.

The V1 source change modifies only branch guards inside
`src/_pytest/skipping.py::pytest_runtest_makereport`. It does not change a
function signature, class, hook name, store key, report attribute name, marker
name, option name, or return shape.

Public hook compatibility:

| Surface | Status | Reason |
| --- | --- | --- |
| `pytest_runtest_makereport(item, call)` hook | Compatible | Signature and hookwrapper behavior are unchanged. |
| `--runxfail` option | Compatible | Option registration and help text are unchanged. |
| `rep.wasxfail` producer | Compatible | Still produced only by non-runxfail xfail branches. |
| skipped report `longrepr` tuple | Compatible | Existing marker-skip rewrite still produces `(filename, line, reason)` and now does so under runxfail too. |

No public override or callsite requires an update.
