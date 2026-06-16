# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Symlink Directory Descent

Claim: for any entry `E` produced by `os.scandir(P)`, if `E` is a symlink whose target is a directory and `recurse(E)` is true, `visit(P, recurse)` eventually calls `visit(E.path, recurse)` after yielding the entries of `P`.

Source: E1-E3.

Discharged by: source condition `entry.is_dir() and recurse(entry)` and K claim `VISIT-SYMLINK-DIR`.

## PO2: Breadth-First Within Each Directory Level

Claim: entries returned for one directory level are sorted by `entry.name` and all yielded before any child traversal.

Source: `visit` docstring and implementation structure; needed as a frame condition because V1 should not disturb ordering.

Discharged by: `entries = sorted(os.scandir(path), key=lambda entry: entry.name)` followed by `yield from entries` before the recursive loop; K claim `VISIT`.

## PO3: Recursion Predicate Preservation

Claim: no entry is recursively visited unless `recurse(entry)` is true.

Source: E5 and existing caller contracts.

Discharged by: source condition `entry.is_dir() and recurse(entry)`; K claim `VISIT-RECURSE-FILTER`.

## PO4: Symlink Path Preservation

Claim: when traversing a symlinked directory, the recursive scan path is the symlink path `entry.path`, not the resolved target path.

Source: E6-E7.

Discharged by: source recursive call `visit(entry.path, recurse)`; K claim `VISIT-SYMLINK-DIR`.

## PO5: Non-Directory and Broken Symlink Non-Descent

Claim: entries that are not directories under default `DirEntry.is_dir()` semantics are not recursively scanned.

Source: E8.

Discharged by: source condition `entry.is_dir()`; K claim `VISIT-BROKEN-SYMLINK`.

## PO6: Partial-Correctness Boundary

Claim: the proof assumes finite acyclic traversal under the active recursion predicate.

Source: D1 and FVK partial-correctness default.

Discharged by: explicit precondition in K claims. Total correctness over cyclic symlink graphs is not proved.

