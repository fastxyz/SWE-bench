# Iteration Guidance

Status: V1 stands unchanged.

## Code Decision

No source edit is justified by the FVK audit. V1 directly addresses FINDING F1
and discharges PO-1, PO-3, PO-5, and PO-6. PO-2/PO-4 depend on external
filesystem/pathlib canonicalization semantics, which is the intended trusted
base for this OS-dependent bug and is explicitly recorded rather than hidden.

## If Another Iteration Were Needed

1. Machine-check the K artifacts only after replacing the external
   `resolveCanon` assumptions with an adequate Python/pathlib/Windows filesystem
   semantics, or after accepting those assumptions as the trusted base.
2. Add or keep integration tests that exercise:
   - a mixed-case package component in a conftest import path;
   - a wrong-cased working directory on Windows;
   - a symlinked conftest path that should not double-load.
3. Do not reintroduce `os.path.normcase()` into any path that is later passed to
   `pyimport()`.

## Residual Risk

The proof is partial and constructed only. It does not prove termination of
pytest collection, the full behavior of `py.path.local.pyimport()`, or real
Windows filesystem APIs. Those are integration concerns intentionally kept out
of the mini semantics.
