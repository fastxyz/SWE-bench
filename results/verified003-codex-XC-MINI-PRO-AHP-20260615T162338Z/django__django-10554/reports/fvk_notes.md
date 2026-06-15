# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decisions

V1 stands unchanged.

The audit localized the issue to shared mutable component query state in combined
queryset clones. `fvk/FINDINGS.md` F1 records the bug as a resolved code issue:
the original ordered union can break after a derived projection if the derived
queryset and original queryset share component `Query` objects. The source edit
in V1 discharges `fvk/PROOF_OBLIGATIONS.md` PO1 through PO4 by recursively cloning
`combined_queries`, proving clone preservation, clone isolation, mutation framing,
and the issue-specific order-position postcondition.

I did not add another compiler change. F2 explains why the existing
compiler-local clone around `set_values()` is not the central contract: it protects
one call path, while `Query.clone()` must provide ownership separation for cloned
combined querysets generally. PO2, PO3, and PO6 are the obligations that justify
keeping the V1 ownership fix at the clone boundary.

I did not change public APIs or callsites. F3 and PO5 show that V1 changes only
the internals of `Query.clone()` and preserves method signatures, queryset result
protocols, and the existing compiler API.

I did not add, edit, remove, or run tests. F4 and PO7 record the verification
boundary: the FVK proof is an abstract ownership proof, not a full SQL compiler
or backend proof, and the task forbids test and code execution. `fvk/ITERATION_GUIDANCE.md`
therefore recommends keeping tests and adding future regression coverage only in
a normal development environment.

No further production-code edit was made because F5 records no remaining V1 code
finding, and the proof obligations needed for the issue are discharged by the
current source change.
