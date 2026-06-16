# FVK Specification

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Scope

The audited behavior is Pylint's persistent stats directory selection and creation in `pylint.config`:

- `_get_default_pylint_home()`
- module-level `PYLINT_HOME` initialization
- `_get_pdata_path()`
- `save_results()`
- public text describing the same behavior in `ENV_HELP` and `doc/faq.rst`

There are no loops or recursive functions in this slice.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "this really annoying `.pylint.d` directory in my home folder" | The default must stop creating `~/.pylint.d` when a normal user home is available. | Encoded by PO-2 and PO-3. |
| E2 | prompt | "cached files (`$HOME/.cache/<PROGRAM_NAME>`), configuration files..., and data files..." | Persistent run stats must be placed under an XDG-style program directory, not directly under `$HOME`. | Encoded by PO-2 and PO-3. |
| E3 | public hint | "`PYLINTHOME` can be set to the directory of your choice" | `PYLINTHOME` remains an exact explicit override. | Encoded by PO-1. |
| E4 | public hint | "default value is `~/.pylint.d` or `.pylint.d` in the current working directory" | The legacy behavior is the bug for normal homes, but the current-directory fallback is still useful when the home directory is not discoverable. | Encoded by PO-4. |
| E5 | public hint | "maybe ... use `~/.cache` by default, given that the data (currently only stats files) is not crucial" | The XDG cache directory is the preferred base, because Pylint stores regenerable stats. | Encoded by PO-2 and PO-3. |
| E6 | implementation | `_get_pdata_path()` creates `*.stats` paths and `save_results()` pickles analysis stats. | The stored files are cache-like derived artifacts; filename construction should stay under `PYLINT_HOME`. | Encoded by PO-6. |
| E7 | implementation | `save_results()` creates `PYLINT_HOME` before writing the pickle. | Directory creation must handle nested XDG defaults such as `~/.cache/pylint`. | Encoded by PO-5. |
| E8 | docs | `doc/faq.rst` section 3.2 describes where persistent data is stored. | Public documentation must match the changed default. | Encoded by PO-7; V1 failed, V2 fixes it. |

## Intended Contract

For all environment and home-directory states in scope:

1. If `PYLINTHOME` is present, `PYLINT_HOME` is exactly its value.
2. If `PYLINTHOME` is absent and the user home cannot be resolved (`expanduser("~") == "~"`), `PYLINT_HOME` is `.pylint.d`.
3. If `PYLINTHOME` is absent, the user home is resolved, and `XDG_CACHE_HOME` is set to an absolute path, `PYLINT_HOME` is `XDG_CACHE_HOME/pylint`.
4. If `PYLINTHOME` is absent, the user home is resolved, and `XDG_CACHE_HOME` is missing, empty, or relative, `PYLINT_HOME` is `$HOME/.cache/pylint`.
5. `save_results()` creates the selected `PYLINT_HOME` recursively when it does not exist before writing stats.
6. `_get_pdata_path(base, recurs)` writes stats under `PYLINT_HOME` and preserves the existing basename sanitization behavior.
7. `ENV_HELP` and `doc/faq.rst` describe the same directory-selection order as the implementation.

## Domain And Abstractions

- `XDG_CACHE_HOME` validity is abstracted as `XDGValid`, meaning "set, non-empty, and absolute." This matches the source condition `xdg_cache_home and os.path.isabs(xdg_cache_home)`.
- `join(a, b)` abstracts `os.path.join(a, b)`. The proof only needs the placement property: the result is under the selected base with `pylint` appended.
- `makedirs(path, exist_ok=True)` is modeled by recording a recursive-create effect for the selected path when the directory is missing.
- `PYLINTHOME` is intentionally not normalized or expanded; the old contract accepted it verbatim and the public hint says it is a directory "of your choice."

## Adequacy Audit

The formal claims in `pylint-config-spec.k` paraphrase to the intended contract above:

- Claims `PYLINTHOME-OVERRIDE`, `DEFAULT-XDG-CACHE`, `DEFAULT-HOME-CACHE`, and `DEFAULT-NO-HOME` cover every path-selection branch.
- Claim `MAKEDIRS-MISSING` covers recursive directory creation for nested XDG paths.
- Claim `NO-MAKEDIRS-EXISTING` covers the frame condition that an existing directory is not recreated.

The only V1 adequacy failure was public documentation: `doc/faq.rst` still stated the old `.pylint.d` lookup. V2 updates it.

## Public Compatibility Audit

- Public function signatures are unchanged.
- `PYLINTHOME` override behavior is unchanged.
- Stats filenames and pickle load/save behavior are unchanged apart from the containing directory.
- No tests were edited.
- The public FAQ now matches the implementation, resolving the V1 compatibility gap.

