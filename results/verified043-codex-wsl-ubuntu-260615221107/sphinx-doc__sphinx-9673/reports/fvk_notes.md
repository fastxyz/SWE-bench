# FVK Notes

## Decision

V1 stands unchanged. The audit found one real defect in the pre-V1 behavior,
recorded as `F-1`, and V1's single source edit discharges it through `PO-2`
and `PO-3`.

## Source Changes

No additional source changes were made during the FVK pass.

The existing V1 edit in `repo/sphinx/ext/autodoc/typehints.py` recognizes
`returns` alongside `return` when populating the canonical return-description
marker. That is exactly the condition required by `PO-2`; once it is true, the
existing append logic satisfies `PO-3` by adding `rtype` from
`annotations['return']`.

## Rejected Alternatives

I kept Napoleon unchanged because `F-2` and `PO-5` show that Napoleon already
emits valid Python-domain field syntax and the bug is autodoc's recognition of
that syntax.

I kept `modify_field_list()` unchanged because `F-3` and `PO-5` show that the
`"all"` branch does not depend on detecting a documented return description; it
already adds missing `rtype` when a return annotation exists and no `rtype` is
present.

I did not modify tests because the benchmark forbids test edits. `F-4` records
the recommended future regression test for the `:returns:` documented-mode path.

## Proof Status

The formal artifacts in `fvk/` are constructed, not machine-checked. `F-5`
records the honesty-gate limitation and `fvk/PROOF.md` contains the commands that
should be run in an environment with K installed.
