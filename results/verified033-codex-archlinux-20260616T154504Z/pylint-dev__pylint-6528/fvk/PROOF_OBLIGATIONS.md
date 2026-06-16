# FVK Proof Obligations

Status: constructed, not machine-checked.

## O1 - Ignore Predicate Equivalence

For any path `P`, `_is_ignored_file(P)` returns true iff at least one configured
ignore source matches:

- `basename(P) in self.config.ignore`
- some pattern in `self.config.ignore_patterns` matches `basename(P)`
- some pattern in `self.config.ignore_paths` matches `P`
- some pattern in `self.config.ignore_paths` matches `normpath(P)`

Intent evidence: E1-E5. Source: `PyLinter._is_ignored_file`.

## O2 - Ignored Starting Argument Is Not Yielded

For every starting argument `A`, if O1 says `A` is ignored, then
`_discover_files([A], _is_ignored_file)` yields no item for `A` and does not walk
inside it.

Intent evidence: E1-E4.

## O3 - Ignored Directory Is Pruned

For any directory root or child directory `D`, if O1 says `D` is ignored, then no
descendant of `D` is yielded by recursive discovery.

Intent evidence: E2. Source: `directories[:] = []` for ignored roots and
directory-list filtering before descent.

## O4 - Ignored Python File Is Not Yielded

For any `.py` file `F` under an unignored non-package directory, if O1 says `F`
is ignored, then `F` is omitted from the yielded file stream.

Intent evidence: E1-E5.

## O5 - Package Roots Are Yielded Once Without Prefix Sibling Loss

For any unignored package directory `P` reached by recursive discovery:

- `P` is yielded as a package root for downstream `expand_modules()`;
- `P`'s child directories are pruned from this `os.walk()` traversal;
- pruning `P` does not suppress any sibling directory `S` unless `S` itself is
  ignored.

Intent evidence: E6. Finding: F2.

## O6 - Recursive Check Wires the Ignore Predicate

When `self.config.recursive` is true, `PyLinter.check()` replaces
`files_or_modules` with `tuple(self._discover_files(files_or_modules,
self._is_ignored_file))`. When recursive mode is false, discovery is not used.

Intent evidence: E1. Compatibility evidence: E7.

## O7 - Static Helper Compatibility

Calling `_discover_files(files_or_modules)` without an ignore predicate preserves
the previous no-ignore behavior. This keeps the private static helper compatible
with any existing private direct call.

Intent evidence: E7.

## Adequacy Obligations

A1. Do not encode a default-ignore-pattern change. The issue text is
contradictory: it asserts a default of `"^\."` while also quoting help text and
the repository source showing `^\.#`.

A2. The formal model must distinguish pass and fail for the relevant observable:
the yielded path stream. It must not abstract discovery to a set if that would
hide duplicate-yield or sibling-prefix-loss behavior.

A3. The proof may assume a finite filesystem traversal domain. Total correctness
and `os.walk()` termination are not proved.
