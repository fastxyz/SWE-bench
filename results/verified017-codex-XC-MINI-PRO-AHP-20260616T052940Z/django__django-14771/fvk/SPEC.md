# FVK Spec

Status: constructed, not machine-checked.

## Scope

Target function: `django.utils.autoreload.get_child_arguments()`.

The spec covers the observable argv returned for autoreloader child-process
construction. It models the branches relevant to `sys.executable` relaunches,
the direct `.exe` fallback, warning-option replay, and CPython `-X` option
replay. It does not model filesystem resolution internals, process creation, or
Python's actual command-line parser.

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | prompt | "Auto-reloader should pass -X options (for cpython implementation)" | Preserve CPython `-X` options in child argv. |
| E2 | prompt | `python -X utf8 manage.py runserver` prints `UTF-8` then `cp936` after reload | The ordinary script relaunch path must preserve `-X utf8`. |
| E3 | prompt | `--noreload` prints only `UTF-8` | The defect is in autoreload child argv construction. |
| E4 | prompt | Reference to `sys._xoptions` | Use `_xoptions` as the parent process ledger for `-X` options. |
| E5 | source | Existing `sys.warnoptions` replay | Keep warning-option replay as a frame condition. |
| E6 | source/tests | Existing branch tests for module, script, script-entrypoint, `.exe`, missing script | Avoid unrelated launch-shape changes. |

The full ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Contract

For all in-domain inputs:

1. If the child is launched through `sys.executable` as a script, module, or
   `*-script.py` entrypoint, returned argv is:

   `sys.executable + replayed warning args + replayed xoption args + launch target + user args`.

2. Replayed warning args are unchanged from the existing contract:

   `warning option "error" -> "-Werror"`.

3. Replayed xoption args are:

   `flag option key -> "-X<key>"`;
   `value option key=value -> "-X<key>=<value>"`.

4. If no `_xoptions` ledger exists, xoption replay contributes no argv entries.

5. If Django directly executes a resolved `.exe` shim, returned argv remains the
   shim path plus user args because this branch does not launch a Python
   interpreter through `sys.executable`.

## K Artifacts

- `mini-python-autoreload.k`: minimal argv-construction semantics.
- `autoreload-get-child-arguments-spec.k`: K reachability claims C1-C7.

Run commands to machine-check later:

```sh
kompile fvk/mini-python-autoreload.k --backend haskell
kast --backend haskell fvk/autoreload-get-child-arguments-spec.k
kprove fvk/autoreload-get-child-arguments-spec.k
```

Expected result after machine checking: `#Top`.
