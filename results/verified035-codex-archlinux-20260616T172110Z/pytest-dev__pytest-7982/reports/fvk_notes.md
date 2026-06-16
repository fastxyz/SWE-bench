# FVK Notes

## Decisions

V1 stands unchanged. The audit found no source defect beyond the already-applied one-line fix in `repo/src/_pytest/pathlib.py`.

## Trace to Findings and Proof Obligations

The decision to keep `entry.is_dir()` is traced to F-001 and PO1. The issue requires symlinked directories to be followed, and PO1 is discharged by default `DirEntry.is_dir()` semantics plus the existing recursive call.

The decision not to edit `repo/src/_pytest/main.py` or `repo/src/_pytest/python.py` is traced to F-002 and PO3. Both callers already pass `_recurse`, and the source condition remains `entry.is_dir() and recurse(entry)`, so `pytest_ignore_collect`, `norecursedirs`, and `__pycache__` filtering still govern descent.

The decision not to introduce path resolution is traced to F-003 and PO4. Public docs/tests distinguish following a symlink for traversal from resolving it for collection paths. V1 recurses into `entry.path`, preserving symlink spelling.

The decision not to add special broken-symlink handling is traced to F-005 and PO5. Default `entry.is_dir()` remains false for broken symlinks, so they are not recursive roots.

The decision not to add cycle detection is traced to F-004 and PO6. The constructed proof is partial-correctness only over finite acyclic traversal; total correctness over recursive symlink cycles is a residual risk, but the public issue asks to restore the previous symlink-following behavior, not to introduce new cycle detection behavior.

## Artifact Notes

The requested artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

Because the FVK docs reject markdown-only runs, I also wrote the adequacy and formal core files: `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-pytest-visit.k`, and `fvk/pytest-visit-spec.k`.

No tests, Python, or K tooling were run.

