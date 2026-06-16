# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

Keep the V1 source-code behavior in `pylint/config/__init__.py`; it satisfies PO-1 through PO-7 and PO-9. Apply one V2 improvement: update `repo/doc/faq.rst` to satisfy PO-8 and resolve F-004.

## Suggested Tests To Add Later

Do not add or edit tests in this benchmark task. In a normal development pass, add focused tests for:

- `PYLINTHOME=/tmp/pylint-home` overrides all defaults.
- No `PYLINTHOME`, `HOME=/home/alice`, `XDG_CACHE_HOME=/tmp/xdg-cache` selects `/tmp/xdg-cache/pylint`.
- No `PYLINTHOME`, `HOME=/home/alice`, missing `XDG_CACHE_HOME` selects `/home/alice/.cache/pylint`.
- Empty or relative `XDG_CACHE_HOME` falls back to `/home/alice/.cache/pylint`.
- `expanduser("~") == "~"` falls back to `.pylint.d`.
- `save_results()` creates a nested selected directory recursively.

## Machine-Check Commands For A Future Environment

```sh
kompile fvk/mini-python-config.k --backend haskell
kast --backend haskell fvk/pylint-config-spec.k
kprove fvk/pylint-config-spec.k
```

Expected result after tool installation and any syntax repair required by real K: `#Top` for all claims.

## Open Product Questions

- Whether Pylint should eventually use `platformdirs` or `appdirs` for platform-specific cache directories is beyond the minimal XDG issue. The current proof treats the public Windows note as a question, not a requirement.
- Whether old `~/.pylint.d` stats should be migrated is not specified in the public issue. The proof only covers the new default location and explicit override behavior.

