# PUBLIC_EVIDENCE_LEDGER.md

Status: constructed, not machine-checked.

This ledger mirrors the evidence table in `fvk/SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | Problem title | "`EncodedFile mode should not include `b`" | Wrapper mode has no binary flag. |
| E-002 | Problem body | Third-party code checks `out.mode` for `b`. | Mode must not misroute callers to bytes writes. |
| E-003 | Problem body | Wrapper advertises underlying `rb+`. | Delegated binary mode is the defect. |
| E-004 | Traceback | `write() argument must be str, not bytes`. | Wrapper is text-oriented on Python 3. |
| E-005 | Public hint | `self.buffer.mode.replace('b', '')`. | Remove `b`; preserve other flags. |
| E-006 | Source | `__getattr__` delegates to `buffer`. | Only `.mode` should be intercepted. |
