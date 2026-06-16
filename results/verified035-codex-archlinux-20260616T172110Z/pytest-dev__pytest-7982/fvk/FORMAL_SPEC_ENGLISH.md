# Formal Spec English

This file paraphrases the nontrivial claims in `pytest-visit-spec.k`.

## CLAIM VISIT

For every finite acyclic filesystem fragment `FS`, path `P`, and recursion predicate `R`, executing the modeled `visit(P, R)` emits exactly:

1. the entries returned by `os.scandir(P)`, sorted by entry name;
2. followed by, for each emitted entry in that same sorted order, the recursively emitted sequence for `entry.path` when `entry.is_dir()` with default symlink-following semantics is true and `R(entry)` is true.

Non-directory entries are emitted at their parent level but are not recursed into.

## CLAIM VISIT-SYMLINK-DIR

For a directory `P` with one entry `E` that is a symlink to a real directory, if `R(E)` is true, executing `visit(P, R)` emits `E` and then emits the modeled traversal of `E.path`.

The path used for the recursive scan is the symlink path `E.path`, not the resolved target path.

## CLAIM VISIT-RECURSE-FILTER

For any entry `E`, even if `E` is a real directory or a symlink to a directory, executing `visit` does not recurse into `E.path` unless `R(E)` is true.

## CLAIM VISIT-BROKEN-SYMLINK

For an entry `E` that is a broken symlink or otherwise not a directory under default `is_dir()` semantics, executing `visit` may emit `E` at its parent level but does not recursively scan `E.path`.

## Frame Conditions

The traversal change does not alter collection hook signatures, return types, node construction APIs, or the ordering rule that entries at each directory level are sorted by name and yielded before descending.

## Side Conditions

The proof is partial-correctness only. It assumes finite acyclic traversal under the active recursion predicate. Recursive symlink cycles remain a termination risk outside the constructed proof.

