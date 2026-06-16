# FVK Specification: recursive `ignore-paths`

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` were run.

## Scope

The audited behavior is the path-filtering slice that determines which files
become `FileItem`s and can therefore be linted:

- `pylint.lint.expand_modules._is_in_ignore_list_re`
- `pylint.lint.expand_modules._is_in_ignore_list_re_with_normalized_path`
- `pylint.lint.expand_modules._is_ignored_file`
- `pylint.lint.expand_modules.expand_modules`
- the recursive call chain in `PyLinter.check`: `_discover_files(...)` then
  `_iterate_file_descrs(...)` then `_check_file(...)`

The model abstracts Python regex internals and astroid module-name inference.
Those are treated as inputs to the filtering proof because the bug is where
Pylint applies ignore decisions, not how Python's regex engine computes a match.

## Intent-only obligations

I-001. Source: prompt. Evidence: "`--recursive=y` ignores `ignore-paths`" and
the shown `pyproject.toml` pattern `"^src/gen/.*$"`. Obligation: in recursive
mode, a discovered Python file whose path matches a configured `ignore-paths`
regex must not be linted.

I-002. Source: prompt. Evidence: command `pylint --recursive=y src/` and output
containing `src\gen\about.py`, `src\gen\design.py`, and other generated files.
Obligation: the fix must handle paths discovered from a top-level argument that
uses `/` while the runtime path display uses `\`.

I-003. Source: docs in `base_options.py` and generated option docs. Evidence:
"The regex matches against paths and can be in Posix or Windows format."
Obligation: `ignore-paths` matching must be separator-format tolerant.

I-004. Source: existing public tests. Evidence: recursive ignore tests cover
`--ignore`, `--ignore-patterns`, and broad `--ignore-paths` patterns. Obligation:
basename ignore and basename-regex ignore behavior must be preserved.

I-005. Source: implementation contract of `expand_modules`. Evidence: docstring
says it returns module descriptions "which have to be actually checked."
Obligation: ignored paths must not be emitted as module descriptions, because
those descriptions are the inputs to `_check_file`.

## Formal model

Let:

- `raw_match(p, R)` mean some configured regex in `R` matches `p`.
- `norm(p)` mean `os.path.normpath(p).replace("\\", "/")`.
- `path_match(p, R)` mean `raw_match(p, R) or raw_match(norm(p), R)`.
- `ignored(p)` mean `basename(p)` is in `ignore`, or matches
  `ignore-patterns`, or `path_match(p, ignore-paths)`.

Function contract for `_is_in_ignore_list_re_with_normalized_path`:

- Precondition: `element` is a path string and `ignore_list_re` is the compiled
  pattern list supplied by Pylint configuration.
- Postcondition: returns true if the raw element matches or if the normalized
  Posix-style element matches.
- Frame condition: raw matching remains sufficient; no existing raw-regex
  behavior is removed.

Function contract for `_is_ignored_file`:

- Precondition: `element` is a file or directory candidate path.
- Postcondition: returns true exactly when basename ignore, basename-regex
  ignore, or path-regex ignore applies.
- Frame condition: basename checks are unchanged from V1 and pre-V1 behavior.

Expansion contract for `expand_modules`:

- A top-level candidate whose original argument path is ignored is skipped.
- A resolved file path whose actual lint target is ignored is not emitted as a
  module description.
- Package traversal is not stopped merely because the resolved package
  `__init__.py` is ignored; submodules are traversed and filtered independently.
- Every submodule path is passed through the same `_is_ignored_file` predicate
  before it is emitted.

Recursive-mode contract:

- `_discover_files` may yield filesystem candidates, including mixed-separator
  paths. `_iterate_file_descrs` expands and filters them before `_check_file` can
  run.
- Therefore no lint message is produced for a discovered file whose raw or
  normalized path matches `ignore-paths`.

## K artifacts

The constructed mini-semantics and claims are in:

- `fvk/mini-pylint-ignore.k`
- `fvk/pylint-ignore-paths-spec.k`

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-pylint-ignore.k --backend haskell
kast --backend haskell fvk/pylint-ignore-paths-spec.k
kprove fvk/pylint-ignore-paths-spec.k
```

## Compatibility audit

No public function signatures, return types, config option names, or reporter
message shapes are changed. The source edit is confined to
`repo/pylint/lint/expand_modules.py`. No test files are modified.
