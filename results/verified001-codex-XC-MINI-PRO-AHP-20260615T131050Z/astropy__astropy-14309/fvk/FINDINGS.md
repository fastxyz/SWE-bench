# FINDINGS

Status: constructed, not machine-checked.

## F-001: Resolved code bug - empty args after non-FITS filepath

- Classification: code bug, resolved by V1.
- Evidence: E-001, E-002, E-003.
- Input: `identify_format("write", Table, "bububu.ecsv", None, [], {})`.
- Pre-fix observed behavior: the FITS identifier reached `args[0]` and raised
  `IndexError`.
- Expected behavior: the FITS identifier should return `False`, allowing the
  registry to continue checking other formats or report no match.
- Proof obligation: PO-003.
- V1 audit result: satisfied. The final return now short-circuits on
  `len(args) > 0`, so empty `args` returns `False` and cannot index `args[0]`.

## F-002: Preserved positive FITS identification branches

- Classification: compatibility finding, resolved.
- Evidence: E-005, E-006, E-007.
- Inputs:
  - file object whose first bytes equal `FITS_SIGNATURE`;
  - filepath ending in one of the existing FITS suffixes;
  - positional object of type `HDUList`, `TableHDU`, `BinTableHDU`, or
    `GroupsHDU`.
- Expected behavior: these remain FITS matches.
- Proof obligations: PO-001, PO-002, PO-004.
- V1 audit result: satisfied. V1 changes only the guard before inspecting
  `args[0]`; it does not change file-object signature checks, suffix checks, or
  object-type checks when an object argument exists.

## F-003: Registry/API compatibility preserved

- Classification: compatibility finding, resolved.
- Evidence: E-004.
- Input shape: `identify_format` calls identifiers as
  `identifier(origin, path, fileobj, *args, **kwargs)`.
- Expected behavior: no public signature or call protocol changes are required.
- Proof obligation: PO-005.
- V1 audit result: satisfied. The `is_fits` signature is unchanged and the
  registry code is unchanged.

## F-004: Similar `args[0]` patterns are not part of this repair

- Classification: scoped non-finding / rejected expansion.
- Evidence: E-001, E-002, E-003 identify the FITS write-path failure with a
  non-FITS filepath. Static source search found other identifier functions with
  object-fallback `args[0]` checks, but they are not on the reported
  `write + non-FITS filepath + empty args` path that produced the stack trace.
- Expected behavior for this task: fix the FITS identifier defect without a
  family-wide registry refactor.
- Proof obligation: PO-006.
- V1 audit result: V1 stands. A broader hardening pass might be reasonable in a
  separate issue, but public evidence here localizes the defect to
  `is_fits`.

## F-005: Proof is constructed, not machine-checked

- Classification: verification limitation, not a code bug.
- Evidence: FVK method honesty gate.
- Impact: the proof artifacts provide a static constructed proof and exact
  commands, but `kompile`, `kast`, and `kprove` were not run.
- Proof obligation: PO-007.
- Required action: keep all tests; any test-removal recommendation would be
  conditional on later machine checking.
