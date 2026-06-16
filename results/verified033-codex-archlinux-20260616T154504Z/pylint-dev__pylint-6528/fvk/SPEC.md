# FVK Specification: recursive discovery honors ignores

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited unit is `PyLinter.check()` when `self.config.recursive` is true,
specifically its call to `_discover_files()` and the recursive discovery
semantics in `_discover_files()` / `_is_ignored_file()` in
`repo/pylint/lint/pylinter.py`.

`expand_modules()` remains the downstream module-expansion stage. This FVK pass
does not re-specify all of `expand_modules()`; it specifies that recursive
pre-expansion discovery must not emit files or directories excluded by the same
ignore settings that `expand_modules()` already receives.

## Intent Specification

1. Recursive mode must respect `--ignore`.
   Evidence: problem statement says Pylint "does not respect the `--ignore` ...
   setting when running in recursive mode" and expects `.a/foo.py` to be ignored
   for `pylint --recursive=y --ignore=.a .`.

2. Recursive mode must respect `--ignore-patterns`.
   Evidence: problem statement expects `.a/foo.py` to be ignored for
   `pylint --recursive=y --ignore-patterns="^\.a" .`.

3. Recursive mode must respect `--ignore-paths`.
   Evidence: problem statement expects `.a/foo.py` to be ignored for
   `pylint --recursive=y --ignore-paths=.a .`; help text says this option
   matches paths and can be in POSIX or Windows format.

4. Ignore semantics must apply to directories, not just yielded files.
   Evidence: expected behavior says `foo.py` should be ignored "because it is in
   an ignored directory".

5. Recursive discovery of packages must preserve existing intended behavior:
   when a directory root is a Python package, yield that package root for
   `expand_modules()` and do not separately walk its subtree.
   Evidence: pre-existing `_discover_files()` behavior and recursive public
   tests exercise package and non-package directory discovery.

6. Public compatibility must be preserved.
   Evidence: `_discover_files()` is private, but public source only calls it
   from `PyLinter.check()`. The V2 implementation keeps the previous
   one-argument static-helper behavior by making the ignore predicate optional.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "does not respect the `--ignore`, `--ignore-paths`, or `--ignore-patterns` setting when running in recursive mode" | Recursive discovery must apply all three ignore sources. | Encoded by O1-O4 |
| E2 | prompt | "`foo.py` should be ignored ... because it is in an ignored directory" | Ignored directories must be pruned so descendants are not emitted. | Encoded by O2-O3 |
| E3 | help text in prompt | "`--ignore` ... base names, not paths" | Match `ignore` against `os.path.basename(path)`. | Encoded by O1 |
| E4 | help text in prompt | "`--ignore-patterns` ... regex matches against base names" | Match ignore-pattern regexes against basenames. | Encoded by O1 |
| E5 | help text in prompt | "`--ignore-paths` ... regex matches against paths and can be in Posix or Windows format" | Match path regexes against the discovered path; normalize `./x` to `x` as an equivalent discovered path spelling. | Encoded by O1 |
| E6 | source behavior | package roots are yielded and subtrees skipped for `expand_modules()` | Preserve package-root handoff without duplicate subtree discovery. | Encoded by O5 |
| E7 | public compatibility audit | no public callsites of `_discover_files()` outside `PyLinter.check()` were found; private helper still callable with one argument | Do not introduce a required public argument or changed public API. | Encoded by O6 |
| E8 | conflicting prompt/docs | issue prose says default `ignore-patterns` is `"^\."`, but bundled help text and `base_options.py` show `^\.#` | Do not change defaults without consistent public evidence; record ambiguity. | Finding F3 |

## Formal Spec English

The constructed K claims in `fvk/pylinter-recursive-discovery-spec.k` paraphrase
to these obligations:

1. `IGNORED-ARGUMENT`: if an input path is ignored by basename, basename regex,
   raw path regex, or normalized path regex, recursive discovery yields no item
   for that input.
2. `IGNORED-DIRECTORY-PRUNED`: if a directory root is ignored, recursive
   discovery yields neither that directory nor any descendant file.
3. `IGNORED-CHILD-DIRECTORY-PRUNED`: if a child directory is ignored, traversal
   prunes it before descent, so descendant `.py` files are not yielded.
4. `IGNORED-PY-FILE-SKIPPED`: if an individual `.py` file path is ignored, it is
   not yielded even when its containing directory is not ignored.
5. `UNIGNORED-PY-FILE-YIELDED`: an unignored `.py` file in an unignored
   non-package directory is yielded.
6. `PACKAGE-YIELDED-ONCE-SIBLING-KEPT`: when two sibling package directories
   have path names where one is a string prefix of the other, both package roots
   are yielded exactly once; discovering one package must not suppress the
   sibling.
7. `CHECK-PASSES-IGNORE-PREDICATE`: `PyLinter.check()` supplies
   `_is_ignored_file` to `_discover_files()` only in recursive mode; callers that
   invoke `_discover_files(files)` without a predicate retain the original
   no-ignore helper behavior.

## Spec Audit

All claims above pass the intent audit except the default-ignore ambiguity:

- O1-O4 are directly entailed by E1-E5.
- O5 is entailed by E6 and preserves the existing package handoff while removing
  prefix-based over-pruning.
- O6 is entailed by E7.
- The issue sentence about default `ignore-patterns="^\."` conflicts with the
  quoted help text and `base_options.py` default `^\.#`; the spec does not
  encode a default change. This is recorded as Finding F3, not used to justify a
  source edit.

## Public Compatibility Audit

Changed symbols:

- `_discover_files`: private static helper. V2 adds an optional `is_ignored`
  predicate with default no-op behavior. Existing one-argument private calls
  still work.
- `_is_ignored_file`: new private instance helper. No public callers.
- `_is_not_ignored`: new private module helper. No public callers.

Public callsites:

- `PyLinter.check()` is the only in-source callsite found. It now passes
  `self._is_ignored_file` only when `self.config.recursive` is true.

Compatibility conclusion: no public API break is introduced.
