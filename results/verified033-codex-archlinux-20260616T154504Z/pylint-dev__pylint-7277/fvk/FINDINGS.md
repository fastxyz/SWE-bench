# FINDINGS.md

Status: constructed, not machine-checked.

## F1 - Resolved Code Bug: Unconditional First Pop

- Classification: code bug, resolved by V1.
- Evidence: E1/E2/E3.
- Input: `sys.path = ["something", cwd, ...]`, `PYTHONPATH` with no relevant
  edge-colon branch.
- Pre-fix observed behavior: `sys.path.pop(0)` removed `"something"`.
- Expected behavior: `"something"` is not `""`, `"."`, or `cwd`, so it must be
  preserved.
- V1 result: `_remove_sys_path_entry(0)` checks the first item before popping,
  so `"something"` is preserved.
- Proof obligation: PO-1.

## F2 - Confirmed: CWD Startup Entries Still Removed

- Classification: intended behavior preserved.
- Evidence: E3/E4/E8.
- Input: `sys.path = [cwd, ...]`, `PYTHONPATH` with no relevant edge-colon
  branch.
- Expected behavior: remove the first CWD-like startup entry.
- V1 result: `_remove_sys_path_entry(0)` removes `cwd`, `""`, or `"."`.
- Proof obligation: PO-2.

## F3 - Confirmed: PYTHONPATH Cleanup Does Not Reintroduce the Bug

- Classification: intended behavior preserved with safety improvement.
- Evidence: E2/E5/E6/E8.
- Input: `sys.path = ["something", cwd, "/custom", ...]` with a leading
  implicit-current-directory `PYTHONPATH` case.
- Expected behavior: preserve `"something"` and remove only a CWD-like implicit
  slot.
- V1 result: the target index is shifted when the first entry is preserved, and
  `_remove_sys_path_entry` still checks the target before popping.
- Proof obligations: PO-3, PO-4, PO-5.

## F4 - Confirmed: Later CWD Entries Are Not Globally Removed

- Classification: intended behavior preserved.
- Evidence: E7.
- Input: `sys.path = ["", "/site", cwd]`.
- Expected behavior: remove only the first `""`; preserve the later `cwd`.
- V1 result: only documented startup slots are targeted.
- Proof obligation: PO-6.

## F5 - No Code Change: Exact Path Matching Is Intent-Derived

- Classification: rejected alternative.
- Evidence: E3.
- Alternative considered: normalize path strings or remove any path resolving to
  `cwd`.
- Decision: do not change V1. The public issue names the exact removable forms
  `""`, `"."`, and `os.getcwd()`. Broader normalization is outside this issue
  and could remove caller-owned paths not identified by public intent.
- Proof obligations: PO-1, PO-2.

## F6 - Proof Status Caveat

- Classification: proof process caveat, not a code bug.
- Evidence: FVK methodology.
- Result: the proof is constructed but not machine-checked. No tests should be
  deleted based on this artifact alone.
- Proof obligations: all.
