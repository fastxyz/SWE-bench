# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Applied V2 Change

F2 and O5 justified a source edit beyond V1:

- Removed prefix-based `skip_subtrees` state in `_discover_files()`.
- When a package root is yielded, clear `directories[:]` so `os.walk()` does not
  descend into that package subtree.

This preserves the intended package handoff to `expand_modules()` while avoiding
false pruning of sibling packages whose paths merely share a string prefix.

## Kept From V1

F1, F4, and O1-O4 confirmed the V1 ignore-predicate and pruning approach:

- Keep basename matching for `--ignore`.
- Keep basename-regex matching for `--ignore-patterns`.
- Keep raw-path and normalized-path matching for `--ignore-paths`.
- Keep directory pruning rather than only filtering yielded files.

O7 confirmed the optional predicate fallback is useful compatibility protection
for the private static helper.

## Rejected or Deferred Changes

- Do not change the default `ignore-patterns` value. F3/A1 records contradictory
  public evidence in this checkout.
- Do not modify tests. The task forbids test edits, and the proof is not
  machine-checked.
- Do not broaden this patch into `expand_modules()` normalization. The issue and
  proof target recursive pre-expansion discovery; changing non-recursive
  path-ignore semantics would require a separate compatibility audit.

## Suggested Follow-up Tests

These are recommendations only; no tests were edited:

- Recursive `--ignore=.a .` should omit `.a/foo.py` and keep `bar.py`.
- Recursive `--ignore-patterns="^\\.a" .` should omit `.a/foo.py`.
- Recursive `--ignore-paths=.a .` should omit `.a/foo.py`, including when
  `os.walk()` discovers it as `./.a/foo.py`.
- Recursive discovery should yield both sibling packages `pkg` and `pkg2`.
- Recursive discovery should not emit files below an ignored nested directory.

## Machine-checking Commands

The commands to run in an environment with K installed are:

```sh
kompile fvk/mini-pylint-discovery.k --backend haskell
kast --backend haskell fvk/pylinter-recursive-discovery-spec.k
kprove fvk/pylinter-recursive-discovery-spec.k
```
