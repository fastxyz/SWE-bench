# FVK Findings

Status: constructed audit findings; no tests or formal tools were run.

## F-001: V1 discharges the reported univariate grouping defect

Input from the public issue:

`sqf_list((x**2 + 1)*(x - 1)**2*(x - 2)**3*(x - 3)**3, x)`

Pre-V1 observed behavior from the issue:

`(1, [(x**2 + 1, 1), (x - 1, 2), (x - 3, 3), (x - 2, 3)])`

Expected:

`(1, [(x**2 + 1, 1), (x - 1, 2), (x**2 - 5*x + 6, 3)])`

Audit result:

V1 applies `_combine_factors()` after `_generic_factor_list()` has converted
factor entries to `Poly` objects and before final sorting/output conversion.
For the two exponent-`3` entries, the helper replaces them with one product
entry. This satisfies PO-1 and PO-2.

Classification: fixed by V1.

## F-002: No-generator multivariate behavior remains ambiguous

Input class:

`sqf_list()` on expressions with more than one free symbol and no explicit
single generator.

Public evidence:

The issue discussion says square-free methods are intended for univariate
polynomials and that multiple-generator behavior may be indeterminate. It also
says `ValueError` could be raised, but the point is presented as uncertain.
Existing public tests include no-generator multivariate behavior for
`sqf_list(x*(x + y))`.

Expected:

Underspecified. The audit cannot derive a mandatory ValueError or mandatory
grouped output from the public evidence.

Audit result:

V1 leaves this path unchanged unless a single generator is explicit or the input
is unambiguously univariate. This is a compatibility frame, not a proof that the
legacy behavior is mathematically ideal.

Classification: underspecified intent; no source change justified in this pass.

UltimatePowers question:

For multivariate expressions with no explicit generator, should `sqf_list()` keep
legacy symbolic factoring, raise `ValueError`, or infer a primary generator by
some documented rule?

## F-003: The SO `sqf(v.expand())` example is a documentation/domain issue here

Input class:

`sqf()` on expanded expressions containing multiple symbols without an explicit
generator.

Public evidence:

The problem statement cites this as "another problem" and then says the
documentation is incomplete because square-free methods are univariate.

Expected:

The public evidence supports clarifying the univariate domain and requiring a
generator when there is ambiguity. It does not provide a precise replacement
algorithm for all multivariate `sqf()` calls.

Audit result:

V1 updated the relevant public docstring summaries to say the square-free
helpers operate on univariate polynomials. The source behavior of multivariate
`sqf()` without a generator remains outside this proof.

Classification: documented domain/ambiguity; no additional source change
justified by this audit.

## F-004: Formal proof is abstract, not full SymPy semantics

Input class:

All concrete SymPy polynomial domains, domains with extensions, and expression
trees beyond the list-of-`Poly`-factors abstraction.

Expected:

A full proof would require a complete Python/SymPy semantics and polynomial
domain theory.

Audit result:

The constructed K artifacts model exactly the changed property: exponent-grouped
factor lists after normalization to `Poly`. This distinguishes the reported
failure from the fixed behavior, but it is not a full machine-checked proof of
SymPy.

Classification: proof capability caveat, not a code bug.
