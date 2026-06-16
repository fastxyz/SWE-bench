# FVK Notes

## Source Changes

Changed `repo/django/db/migrations/serializer.py` again after the V1 audit.

Decision D-1 kept the V1 core fix: importable class-bound methods now use
`klass.__qualname__`. This is traced to F-001 in `fvk/FINDINGS.md` and PO-1/PO-3
in `fvk/PROOF_OBLIGATIONS.md`.

Decision D-2 added a guard for `"<"` in `klass.__qualname__` in the class-bound
method branch. This is traced to F-002 and PO-2: a local class-bound method has
no importable migration path, so V2 now raises `ValueError` instead of emitting a
path containing `<locals>`.

Decision D-3 moved the lambda check before the class-bound branch. This is traced
to F-003 and PO-4: lambdas were already unsupported, and class-bound lambdas
should not bypass that rule.

Decision D-4 left the non-class-bound callable logic unchanged. This is traced to
F-004 and PO-5: module-level functions, local functions, and functions without a
module continue through the existing branches.

## Verification Status

The FVK proof is constructed but not machine-checked. Per the task instructions,
I did not run tests, Python, `kompile`, `kast`, or `kprove`, and I did not modify
test files.
