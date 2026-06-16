# Public Compatibility Audit

Changed public symbol: none.

Changed internal helper: `_pytest.pathlib.visit(path, recurse)`.

Signature compatibility: unchanged. The helper still accepts `path: str` and `recurse: Callable[[os.DirEntry[str]], bool]`, and still returns an iterator of `os.DirEntry[str]`.

Callsite compatibility:

| Callsite | Compatibility Result | Reason |
| --- | --- | --- |
| `repo/src/_pytest/main.py`, session directory collection | PASS | Still receives `os.DirEntry` values and applies `_recurse` before descent. |
| `repo/src/_pytest/python.py`, package collection | PASS | Still receives `os.DirEntry` values and applies package `_recurse` before descent. |

Override/subclass audit: not applicable. `visit` is a module-level helper, not a virtual method.

Producer/consumer shape: unchanged. The yielded entries remain `os.DirEntry` objects from the scanned path. Recursive scans use `entry.path`, preserving symlink path spelling rather than resolving to a target path.

Unhandled compatibility concerns: none found.

