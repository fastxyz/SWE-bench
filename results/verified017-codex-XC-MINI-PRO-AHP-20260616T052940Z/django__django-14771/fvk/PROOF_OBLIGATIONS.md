# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | V1 Status |
| --- | --- | --- | --- |
| PO-001 | Read the parent process xoption ledger when it exists. | E1, E4 | Discharged by `hasattr(sys, '_xoptions')` and iteration over `sys._xoptions.items()`. |
| PO-002 | Format every xoption as an interpreter argument, preserving both flag and `name=value` forms. | E1, E4, F-002 | Discharged by lines 224-226 in `repo/django/utils/autoreload.py`. |
| PO-003 | Preserve existing warning-option replay. | E5 | Discharged because V1 leaves the `sys.warnoptions` expression unchanged. |
| PO-004 | Preserve xoptions on ordinary script relaunch, including the reported `manage.py` path. | E1-E3 | Discharged by adding xoption args before `sys.argv` is appended. |
| PO-005 | Preserve xoptions on `python -m ...` module relaunch. | E1, E6 | Discharged because xoption args are added before the `__main__.__spec__` branch appends `-m`. |
| PO-006 | Preserve xoptions on `*-script.py` entrypoint fallback. | E1, E6 | Discharged because that branch returns `[*args, script_entrypoint, *sys.argv[1:]]`. |
| PO-007 | Avoid changing the direct `.exe` fallback branch. | E6, F-004 | Discharged because that branch still returns `[exe_entrypoint, *sys.argv[1:]]`. |
| PO-008 | Keep public API and caller compatibility. | E6 | Discharged: no signature, return type, caller, or dispatch shape change. |
| PO-009 | Maintain behavior when `_xoptions` is unavailable. | Default-domain assumption in INTENT_SPEC | Discharged by the `hasattr()` gate. |

No open code-changing obligation remains.
