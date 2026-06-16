# Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands. The FVK audit found no source-level defect requiring a V2 code edit.

## Why No Source Edit Is Needed

- F1 and PO1 show the central bug is fixed: `_af_new` is classmethod-like and
  allocates with `cls`.
- F2 and PO2/PO3 show the constructor paths that used to collapse subclasses now
  route through `cls` or preserve an already-compatible existing object.
- F3 and PO5 show external base-bound aliases remain compatible.
- F4 and PO4 justify keeping the broader V1 updates to inherited operations and
  classmethods: they are the same class-preservation principle applied where the
  current class is available.
- F5 and PO6/PO8 are proof-scope limits, not code defects.

## Follow-Up Commands for a Real Execution Environment

These commands are recorded for later use and were not run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/permutation-subclass-spec.k
kprove fvk/permutation-subclass-spec.k
```

Project-level tests should also be run later in an environment where executing
code is allowed.

## Suggested Public Tests For Maintainers

Do not add these in this benchmark task, because test files are fixed. They are
useful maintainer checks:

- `class SubPerm(Permutation): pass; isinstance(SubPerm._af_new([1, 0]), SubPerm)`
- `isinstance(SubPerm([1, 0]), SubPerm)`
- `isinstance(SubPerm(Permutation([1, 0])), SubPerm)`
- `isinstance(~SubPerm([1, 0]), SubPerm)`
- `isinstance(SubPerm.unrank_lex(3, 0), SubPerm)`

