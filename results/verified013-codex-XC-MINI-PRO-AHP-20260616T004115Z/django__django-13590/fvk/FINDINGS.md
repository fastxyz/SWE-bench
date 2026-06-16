# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-fix named tuple reconstruction bug

Classification: code bug, fixed by V1.

Input: a standard two-field named tuple used as a `__range` lookup value, such
as `Bounds(near, far)`.

Observed before V1: `resolve_lookup_value()` recursively resolved the elements,
then called `type(value)(resolved_values_generator)`. A named tuple constructor
interprets that as one positional argument, so the second field is missing and
Python raises `TypeError: __new__() missing 1 required positional argument:
'far'`.

Expected: resolve both elements and reconstruct `Bounds(resolved_near,
resolved_far)` using positional arguments.

Evidence: IE1, IE2, IE3, IE5. Obligations: PO1, PO2, PO3.

Status after V1: resolved. The current code builds one `resolved_values`
generator, detects tuple instances with `_fields`, and calls
`type(value)(*resolved_values)`.

## F2: V1 preserves the intended named tuple type and arity

Classification: confirmation finding.

Input: a standard two-field named tuple where each member is either scalar or an
expression-like value.

Observed in V1 by static audit: the named tuple branch is reachable only after
the recursive generator is defined. Star expansion passes exactly the resolved
members as constructor arguments in iteration order.

Expected: same named tuple type and two resolved values.

Evidence: IE3, IE4, IE5. Obligations: PO2, PO3.

Status: no further source change required.

## F3: Unpacking every tuple/list would be a regression

Classification: avoided regression.

Input: a plain tuple `(low, high)` or list `[low, high]` used as an iterable
lookup value.

Observed risk in the rejected alternative: changing all list/tuple
reconstruction to `type(value)(*resolved_values)` would call `tuple(a, b)` or
`list(a, b)`, which is not the existing iterable-constructor protocol.

Expected: plain tuple/list behavior remains on `type(value)(resolved_values)`.

Evidence: IE7. Obligation: PO4.

Status after V1: avoided. V1 only unpacks tuple instances with `_fields`.

## F4: Public compatibility is preserved

Classification: compatibility finding.

Input: Django's internal call path from `Query.build_filter()` through
`resolve_lookup_value()` into iterable lookups such as `Range`.

Observed in V1 by static audit: the method signature is unchanged, callers still
receive an iterable RHS, and the downstream `FieldGetDbPrepValueIterableMixin`
continues to iterate over the resolved RHS.

Expected: no public or internal callsite needs a new argument, return protocol,
or override update.

Evidence: IE6 and the unchanged signature in `query.py`. Obligation: PO5.

Status: no compatibility source change required.

## F5: Residual proof and execution risks

Classification: proof honesty / test guidance, not a code bug.

The proof is constructed but not machine-checked. The mini semantics abstracts
arbitrary `resolve_expression()` implementations and assumes finite containers
and standard named tuple constructor behavior.

Obligations: PO6, PO7.

Status: keep existing tests. Add or retain integration coverage for named tuple
`__range` values because the unit-level proof does not model SQL compilation,
database adapters, or backend execution.
