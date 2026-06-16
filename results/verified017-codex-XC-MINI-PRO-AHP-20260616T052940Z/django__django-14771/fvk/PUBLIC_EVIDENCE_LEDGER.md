# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Auto-reloader should pass -X options (for cpython implementation)" | Child argv built by the autoreloader must replay CPython `-X` options. | Encoded in C1-C5. |
| E2 | prompt | `python -X utf8 manage.py runserver ...` prints `UTF-8`, then after reload prints `cp936`. | The ordinary script relaunch path is in-domain and must preserve UTF-8 mode. | Encoded in C1 and F-001. |
| E3 | prompt | `python -X utf8 ... --noreload` prints only `UTF-8`. | The bug is introduced by autoreload child-process construction, not by Django app import logic. | Encoded in localization finding F-001. |
| E4 | prompt | Reference to `sys._xoptions`. | `sys._xoptions` is the intended in-process source for reconstructing `-X` options. | Encoded in PO-001 and PO-002. |
| E5 | source | `args = [sys.executable] + ['-W%s' % o for o in sys.warnoptions]` in `get_child_arguments()`. | Existing warning-option preservation is a frame condition; `-X` preservation should compose with it. | Encoded in PO-003. |
| E6 | source/public tests | Existing tests cover module, script, script-entrypoint, `.exe` fallback, and missing-script behavior. | The fix must avoid unrelated launch-shape changes. | Encoded in PO-004 through PO-007. |
| E7 | implementation | V1 adds `hasattr(sys, '_xoptions')` and formats each item before module/script arguments. | Candidate behavior to verify, not by itself intent. | Audited in C1-C6 and F-002/F-003. |
