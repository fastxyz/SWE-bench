# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source change is recommended by this FVK pass.

Rationale:

- F-001 and PO1 show the reported regression is closed by replacing `entry.is_dir(follow_symlinks=False)` with `entry.is_dir()`.
- F-002 and PO3 show the fix preserves `_recurse` filtering.
- F-003 and PO4 show the fix follows symlinked directories without resolving path spelling.
- F-005 and PO5 show broken symlink behavior remains compatible.

## Do Not Add in This Patch

Do not add cycle detection for recursive symlink loops in this issue. F-004 and PO6 record that total correctness is outside the proven domain, but the public intent for this task is to restore previous symlink-directory traversal. Cycle detection would be a broader behavior change.

Do not edit callers in `main.py` or `python.py`. The shared helper `visit` is the common source of the traversal predicate, and both callers already pass their recursion filters.

Do not modify tests. The task forbids test edits, and proof-derived test removal is only recommendation-only after machine checking.

## Suggested Follow-Up Tests For Maintainers

Add or keep public tests that create a directory symlink inside a collected test directory and assert tests under the symlink path are collected.

Keep coverage for `norecursedirs`, `pytest_ignore_collect`, broken symlinks, and node ID path spelling because these are integration behaviors outside the core proof.

