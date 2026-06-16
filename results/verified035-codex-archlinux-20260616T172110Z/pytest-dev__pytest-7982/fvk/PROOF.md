# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` command has been run in this environment.

## What Is Proved

For finite acyclic traversal graphs, the V1 `visit(path, recurse)` implementation is partially correct with respect to the FVK spec:

- it yields sorted entries for the current directory before child traversal;
- it recurses into directory symlinks because `entry.is_dir()` follows symlinks by default;
- it still requires `recurse(entry)` before descent;
- it recurses through `entry.path`, preserving symlink spelling;
- it does not recurse into broken symlinks or non-directory entries.

## Proof Sketch

1. `visit(P, R)` evaluates `entries = sorted(os.scandir(P), key=lambda entry: entry.name)`.
2. The first `yield from entries` emits every entry in `entries` in sorted order. This discharges PO2's current-level ordering.
3. The recursive loop iterates over the same `entries` sequence in the same order.
4. For each entry `E`, the condition is exactly `E.is_dir() and R(E)`.
5. If `E` is a symlink to a directory, default `E.is_dir()` is true, so when `R(E)` is true the branch calls `visit(E.path, R)`. This discharges PO1 and PO4.
6. If `R(E)` is false, the branch is skipped even for directories. This discharges PO3.
7. If `E` is a broken symlink or not a directory under default `is_dir()`, the branch is skipped. This discharges PO5.
8. By structural induction over the finite acyclic traversal graph, recursively applying steps 1-7 yields the sequence characterized in `SPEC.md`.

## K Claims

The K artifacts are:

- `mini-pytest-visit.k`: small-step semantics for the relevant filesystem traversal fragment.
- `pytest-visit-spec.k`: claims `VISIT`, `VISIT-SYMLINK-DIR`, `VISIT-RECURSE-FILTER`, and `VISIT-BROKEN-SYMLINK`.

The claims use a spec-only `expectedVisit(FS, P, R)` function to state the emitted list. The discriminator property is preserved: a symlink-directory entry and a non-followed symlink entry map to different predicates (`isDirFollow` true vs false), so the model can distinguish the reported bug from the fixed behavior.

## Residual Risk

This is partial correctness only. Termination in the presence of recursive symlink cycles is not proved. That risk is recorded as F-004 and PO6.

The proof uses a mini semantics rather than full Python/K semantics. The trusted base is the adequacy of the mini filesystem model for the observed property, Python's `DirEntry.is_dir()` default symlink-following behavior, and K reachability logic when the emitted commands are run later.

## Machine-Check Commands Not Run

The exact commands to run later are:

```sh
kompile fvk/mini-pytest-visit.k --backend haskell
kast --backend haskell fvk/pytest-visit-spec.k
kprove fvk/pytest-visit-spec.k
```

Expected machine-check result after a successful run: `#Top`.

## Test Guidance

Do not delete tests in this benchmark task. If the K proof is machine-checked later, focused unit tests that only assert traversal of finite symlinked directories under accepted `recurse` predicates are proof-redundant in principle. Keep tests for integration with pytest collection, path spelling, broken symlinks, hook behavior, `norecursedirs`, and cyclic symlink/termination behavior.

