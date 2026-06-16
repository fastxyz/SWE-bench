# FVK Proof

Status: constructed, not machine-checked. The commands below were written for
later reproduction and were not executed:

```sh
kompile fvk/mini-pylint-discovery.k --backend haskell
kast --backend haskell fvk/pylinter-recursive-discovery-spec.k
kprove fvk/pylinter-recursive-discovery-spec.k
```

## Claims

The K artifacts are:

- `fvk/mini-pylint-discovery.k`: a minimal abstract filesystem-discovery
  semantics. It models directories, package roots, `.py` files, ordered yielded
  path streams, and an abstract `ignored(path, config)` predicate.
- `fvk/pylinter-recursive-discovery-spec.k`: reachability claims for ignored
  argument pruning, ignored directory pruning, ignored file skipping, unignored
  file yielding, package root yielding, and sibling package preservation.

## Constructed Proof Sketch

O1 follows by direct symbolic evaluation of `_is_ignored_file`: the return
expression is a disjunction of exactly the basename ignore-list check,
basename-regex check, raw-path-regex check, and normalized-path-regex check.
The `or` structure means any matching configured ignore source is sufficient,
and if none match the helper returns false.

O2 follows by the first branch in `_discover_files()`: before any filesystem
classification, V2 checks `if ignore_file(something): continue`. The `continue`
skips both yielding and descent for that starting argument.

O3 follows from two traversal facts. First, when an `os.walk()` root is ignored,
V2 sets `directories[:] = []` and continues, so no files are yielded at that
root and no child directory is scheduled for descent. Second, before processing
an unignored root, V2 rewrites `directories[:]` to remove every direct child
whose joined path is ignored. Since `os.walk()` is top-down, removed children are
not later visited. Therefore descendants of ignored directories are not emitted.

O4 follows from the generator expression in the non-package branch: a candidate
file must satisfy both `file.endswith(".py")` and
`not ignore_file(os.path.join(root, file))`. If the ignore predicate is true for
the file path, the conjunction is false and the file is omitted.

O5 is the V2 improvement over V1. When `__init__.py` is present in `files`, V2
yields the current package root and clears `directories[:]`. This prevents
separate descent into the package subtree, delegating package expansion to
`expand_modules()`. Because V2 no longer stores package roots in a
`skip_subtrees` list and no longer tests later roots with `startswith()`, a
sibling such as `pkg2` is processed independently of `pkg`.

O6 follows from `PyLinter.check()`: the recursive branch constructs
`files_or_modules` with `self._discover_files(files_or_modules,
self._is_ignored_file)`. The non-recursive branch does not call
`_discover_files()`, preserving existing non-recursive expansion.

O7 follows from `_discover_files()` defaulting `is_ignored` to `_is_not_ignored`.
For callers that pass only `files_or_modules`, the helper behaves as the old
static method did with respect to ignores.

## Adequacy Gate

The English claims in `SPEC.md` match the public intent for recursive ignore
handling. The only mismatch is the default `ignore-patterns` statement in the
issue, which conflicts with both the quoted help text and repository source.
That mismatch is recorded as Finding F3 and is intentionally not encoded as a
code change.

The proof model preserves the observable that matters: ordered yielded paths.
This is why F2 is visible; a set-only abstraction would hide the difference
between "both `pkg` and `pkg2` yielded" and "`pkg2` dropped".

## Residual Risk

This is a partial-correctness proof over an abstract mini semantics, not a
machine-checked proof over full Python. It assumes finite filesystem traversal,
correct `os.walk()` top-down directory-list mutation semantics, and correct
Python regex behavior behind the abstract ignore predicate.

No test removal is recommended. Existing and hidden tests should be kept unless
the K claims are later machine-checked and mapped to specific redundant tests.
