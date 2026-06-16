# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and constructed proof obligations only.

## F-001: V1 closes the reported symlink-directory regression

Classification: resolved code bug.

Evidence: E1-E4, PO1.

Input: a collected directory `tests/` containing `linked -> real_tests/`, where `real_tests/` contains test files and the normal `_recurse(linked)` predicate returns true.

Observed in pre-V1 behavior: `linked` is yielded as an entry but not recursed into because `entry.is_dir(follow_symlinks=False)` is false for the symlink itself.

Expected: `linked` is treated as a directory for traversal because its target is a directory, so tests under `linked/` are considered by the normal collection pipeline.

V1 result: `entry.is_dir()` follows symlinks by default and the recursive call remains gated by `recurse(entry)`, so the modeled traversal descends into `linked/`. No further source change is indicated.

## F-002: V1 preserves recursion filters

Classification: compatibility confirmation.

Evidence: E5, PO3.

Input: a symlinked directory whose name matches `norecursedirs`, or which is rejected by `pytest_ignore_collect`.

Expected: the directory must not be recursed into even though its target is a directory.

V1 result: the condition is `entry.is_dir() and recurse(entry)`, so `_recurse` still decides whether descent is allowed. No caller edit is indicated.

## F-003: V1 follows symlink directories without resolving path spelling

Classification: compatibility confirmation.

Evidence: E6-E7, PO4.

Input: `tests/linked -> real_tests/`, where node IDs and hook lookup should use the symlink spelling for the collection path.

Expected: traversal may enter `tests/linked`, but it should do so using `entry.path`, not by resolving to `real_tests`.

V1 result: recursive traversal calls `visit(entry.path, recurse)`. The change adds no `resolve`, `realpath`, or `samefile` behavior. No additional source change is indicated.

## F-004: Termination over recursive symlink cycles remains outside the proven domain

Classification: termination gap, not a regression fix requirement.

Evidence: D1, PO6.

Input: a directory graph where a followed symlink creates a cycle and `recurse` does not reject the back edge.

Observed/expected: the constructed proof does not establish total correctness or cycle termination. The issue asks to restore previous symlink-following behavior, and adding cycle detection would be a broader behavior change with no public intent evidence in this task.

Decision: keep V1 unchanged. Record this as residual risk and keep traversal/termination tests rather than claiming they are proof-redundant.

## F-005: Broken symlinks are still not recursive roots

Classification: compatibility confirmation.

Evidence: E8, PO5.

Input: a broken symlink entry inside a package directory.

Expected: pytest may see the entry but must not recurse into it as a directory.

V1 result: default `entry.is_dir()` is false for broken symlinks, so no recursive descent occurs. No further source change is indicated.

