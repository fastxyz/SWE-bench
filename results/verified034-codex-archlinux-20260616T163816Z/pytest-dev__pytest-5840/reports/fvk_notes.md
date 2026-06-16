# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional pytest source-code change
needed after `unique_path()` was changed from `normcase(str(path.realpath()))` to
`type(path)(str(Path(str(path)).resolve()))`.

## Trace to Findings

F1 confirms the reported defect was the lowercased path reaching
`_importconftest().pyimport()`. V1 removes the only `normcase()` transition in
that flow, so no further source edit was needed for the main bug.

F2 records the remaining dependency on `Path.resolve()` and the OS filesystem
returning canonical paths with real casing. I treated that as a trusted-base
boundary, not a pytest source bug, because it is the exact mechanism suggested by
the public hint and matches the helper's case-preserving contract.

F3 confirms the symlink/same-file alias behavior remains covered because all
runtime conftest callers still share `unique_path()` as the canonicalization
point. This is why I did not split cache-key normalization from import-path
normalization in `_importconftest()`.

F4 confirms the public API and return shape are unchanged. This is why no caller
edits were made.

## Trace to Proof Obligations

PO-1 and PO-6 are discharged by keeping `type(path)(...)` and the same
`unique_path(path)` signature.

PO-2 is discharged as far as pytest source can discharge it: the implementation
uses `Path(str(path)).resolve()` and no longer lowercases. The actual filesystem
casing guarantee remains the explicit external obligation from F2.

PO-3 is discharged because `_importconftest()` calls `unique_path()` before
`pypkgpath()` and `pyimport()`, so V1's case-preserving canonical path is the
path used for import.

PO-4 and PO-5 are discharged by using the same shared canonicalizer for
directory and conftest-path dictionaries, preserving the same-file alias behavior
that the previous realpath-based code was meant to provide.

PO-7 is discharged by labeling all FVK proof artifacts as constructed, not
machine-checked, and by not recommending test deletion.

## Artifacts Written

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the supporting FVK core files required by the method:
`fvk/mini-python-path.k`, `fvk/unique-path-spec.k`, `fvk/INTENT_SPEC.md`,
`fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`,
`fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

No tests, Python, or K tooling were run, per the task instructions.
