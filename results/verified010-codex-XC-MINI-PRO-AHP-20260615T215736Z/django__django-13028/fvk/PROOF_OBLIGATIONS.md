# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are the bridge from
the public intent ledger in `fvk/SPEC.md` to the V2 source change.

## PO-01: Non-expression RHS values are outside the expression filterability contract

Statement: for every value `v`, if `hasattr(v, 'resolve_expression')` is false,
then `check_filterable(v)` returns without raising `NotSupportedError` and
without inspecting `v.filterable` or `v.get_source_expressions()`.

Intent trace: E-01, E-02, E-03, E-05.

V2 evidence: `check_filterable()` begins with
`if not hasattr(expression, 'resolve_expression'): return`.

Required by findings: F-01 and F-02.

## PO-02: Real non-filterable expressions remain disallowed

Statement: for every value `e`, if `hasattr(e, 'resolve_expression')` is true
and `getattr(e, 'filterable', True)` is false, then `check_filterable(e)`
raises `NotSupportedError`.

Intent trace: E-04.

V2 evidence: the `filterable` guard is evaluated immediately after the
non-expression early return.

Required by findings: F-03.

## PO-03: Real expression source recursion remains enforced

Statement: for every value `e`, if `hasattr(e, 'resolve_expression')` is true,
`getattr(e, 'filterable', True)` is true, and
`hasattr(e, 'get_source_expressions')` is true, then each source expression is
validated by the same `check_filterable()` contract.

Intent trace: E-04, E-05.

V2 evidence: the existing recursive loop over
`expression.get_source_expressions()` is unchanged after the expression
discriminator.

Required by findings: F-02 and F-04.

## PO-04: `build_filter()` sends ordinary related-object RHS values through normal lookup validation

Statement: for the reported filter form `metadata_type=<model instance>`,
`resolve_lookup_value()` leaves the model instance as a non-expression RHS;
`check_filterable()` returns by PO-01; relation-specific validation continues
in `check_related_objects()`.

Intent trace: E-01 and E-02.

V2 evidence: `resolve_lookup_value()` resolves only objects with
`resolve_expression` and lists/tuples containing such values. A model instance
without that method remains a direct value.

Required by findings: F-01.

## PO-05: Public API and tests are not changed

Statement: the repair must not alter method signatures, public call shape, or
test files.

Intent trace: I-04 and the benchmark restrictions.

V2 evidence: only the body of `check_filterable()` changed. No tests were
edited.

Required by findings: F-05.

## PO-06: Proof honesty boundary is explicit

Statement: because no code execution or K tooling is allowed, FVK proof results
must be reported as constructed, not machine-checked, and no test-removal claim
may be unconditional.

Intent trace: FVK documentation and the benchmark no-execution rule.

V2 evidence: all FVK artifacts and reports carry the constructed/not
machine-checked caveat.

Required by findings: F-05.
