# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Source changes from the FVK pass

V2 keeps the V1 normalized-path fallback and refines the resolved-file handling
in `repo/pylint/lint/expand_modules.py`.

The FVK audit found F-002: V1 used `continue` when a resolved package
`__init__.py` matched an ignore rule, which skipped the whole package traversal.
The V2 code now stores the resolved-file ignore decision in `is_ignored`, guards
only the direct result append with `not is_ignored`, and still traverses
submodules. This discharges PO-004 and PO-005.

No other source files were changed.

## Tests to add later

Do not add or edit tests in this benchmark task. For a normal development pass,
add focused coverage for:

- Recursive input `src/` with `ignore-paths = ["^src/gen/.*$"]` and a discovered
  mixed path equivalent to `src/gen\about.py`; expected: no `src/gen` file is
  emitted for linting. Covers F-001, PO-002, and PO-006.
- Package input `pkg/` with `pkg/__init__.py` and `pkg/sub.py`, plus an ignore
  pattern matching only `pkg/__init__.py`; expected: `pkg/__init__.py` is not
  emitted but `pkg/sub.py` is still considered. Covers F-002 and PO-005.
- Existing broad recursive ignore cases should remain as regression tests for
  PO-003.

## Tests to keep

Keep integration and recursive lint tests until the K claims are machine-checked
and until the mini-semantics are replaced by or validated against real Python/K
semantics. The current FVK proof is not a basis for deleting tests.

## Follow-up verification

The exact commands to run in an environment with K installed are:

```sh
kompile fvk/mini-pylint-ignore.k --backend haskell
kast --backend haskell fvk/pylint-ignore-paths-spec.k
kprove fvk/pylint-ignore-paths-spec.k
```

Expected outcome after any necessary syntax adaptation: `kprove` returns `#Top`.

## Residual risk

The model abstracts regex matching and astroid module inference. That is
appropriate for this bug because the defect is the placement and normalization
of ignore filtering, but full assurance would require either a richer Python
semantics or executable tests in a normal development environment.
