# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

## PO-1 - Preserve Non-CWD First Entry

- Intent evidence: E1, E2, E3.
- Formal claims: `FIRST-NONCWD-NOEDGE`, `FIRST-NONCWD-LEADING`,
  `FIRST-NONCWD-TRAILING`.
- Required result: a first element not equal to `""`, `"."`, or `cwd` remains at
  the front of the resulting path list.
- V1 status: discharged by `_remove_sys_path_entry(0)` checking the target
  before popping.

## PO-2 - Remove CWD-Like First Entry

- Intent evidence: E3, E4, E8.
- Formal claims: `FIRST-CWD-NOEDGE`, `FIRST-CWD-LEADING`,
  `FIRST-CWD-TRAILING`.
- Required result: a first element equal to `""`, `"."`, or `cwd` is removed.
- V1 status: discharged by `_is_cwd_path` and `_remove_sys_path_entry(0)`.

## PO-3 - Leading Implicit PYTHONPATH Cleanup

- Intent evidence: E5, E8.
- Formal claims: `FIRST-NONCWD-LEADING`, `FIRST-CWD-LEADING`.
- Required result: in the leading implicit-current-directory case, remove the
  CWD-like entry adjacent to the startup slot after accounting for whether the
  first entry was removed.
- V1 status: discharged by using index `0` if the first entry was removed and
  index `1` otherwise.

## PO-4 - Trailing Implicit PYTHONPATH Cleanup

- Intent evidence: E5, E8.
- Formal claims: `FIRST-NONCWD-TRAILING`, `FIRST-CWD-TRAILING`.
- Required result: in the trailing implicit-current-directory case, remove the
  CWD-like trailing startup entry after accounting for whether the first entry
  was removed.
- V1 status: discharged by using index `1` if the first entry was removed and
  index `2` otherwise.

## PO-5 - Explicit PYTHONPATH Exception

- Intent evidence: E6, E8.
- Formal claims: `EXPLICIT-LEADING`, `EXPLICIT-TRAILING`.
- Required result: when `PYTHONPATH` explicitly contains `.` or `cwd` at the
  edge, skip the extra colon cleanup.
- V1 status: discharged by preserving the existing exception checks
  `f":{cwd}"`, `":."`, `f"{cwd}:"`, and `".:"`.

## PO-6 - Preserve Later CWD-Like Entries

- Intent evidence: E7.
- Formal claim: `LATER-CWD-PRESERVED`.
- Required result: CWD-like entries outside the documented startup slots remain.
- V1 status: discharged because V1 only calls `_remove_sys_path_entry` on
  startup indices.

## PO-7 - Public Compatibility

- Intent evidence: E8 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Formal frame: F-API.
- Required result: no signature, callsite, return-shape, or dispatch protocol
  change.
- V1 status: discharged. Helpers are local to `modify_sys_path()`.
