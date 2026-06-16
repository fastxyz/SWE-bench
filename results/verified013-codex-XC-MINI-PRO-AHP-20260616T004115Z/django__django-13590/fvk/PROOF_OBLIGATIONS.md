# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent adequacy

The formal claims must express the public issue's intended behavior, not merely
the current implementation.

Required by: IE1, IE2, IE5.

Discharge: `SPEC.md`, `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and
`SPEC_AUDIT.md` all state the named two-field tuple range case as successful
resolution with positional named tuple construction.

Status: satisfied.

## PO2: Named two-field tuple reconstruction

For any standard named tuple value `T(a, b)` in the range RHS domain, if
`a -> ra` and `b -> rb` under recursive lookup resolution, then
`resolve_lookup_value(T(a, b), can_reuse, allow_joins)` returns `T(ra, rb)` and
does not call `T(iter([ra, rb]))`.

Current code evidence:

```python
resolved_values = (
    self.resolve_lookup_value(sub_value, can_reuse, allow_joins)
    for sub_value in value
)
if isinstance(value, tuple) and hasattr(value, '_fields'):
    return type(value)(*resolved_values)
```

Verification condition VC-NT-1: standard named tuples satisfy
`isinstance(value, tuple)` and `hasattr(value, '_fields')`.

Verification condition VC-NT-2: iterating the named tuple yields `a`, then `b`,
so the generator yields `ra`, then `rb`.

Verification condition VC-NT-3: `type(value)(*resolved_values)` supplies two
positional arguments to a two-field named tuple constructor.

Findings: F1, F2.

Status: discharged by V1.

## PO3: Recursive element resolution

Every element inside a list, tuple, or named tuple must be resolved by calling
`resolve_lookup_value(sub_value, can_reuse, allow_joins)` with the same
resolution context.

Current code evidence: the only generator used by both the named tuple and
non-named branches maps each `sub_value` through the same recursive call.

Findings: F1, F2.

Status: discharged by V1.

## PO4: Frame behavior for non-named containers and scalars

The fix must not regress existing behavior for:

- expression-like values;
- plain lists;
- plain tuples;
- non-expression scalars.

Current code evidence:

- the `resolve_expression` branch is unchanged;
- non-named list/tuple values still return `type(value)(resolved_values)`;
- scalar values still fall through to `return value`.

Findings: F3.

Status: discharged by V1.

## PO5: Range lookup compatibility

After resolution, a `__range` RHS remains an ordered two-value iterable suitable
for `FieldGetDbPrepValueIterableMixin.get_prep_lookup()` and `Range`.

Current code evidence:

- method signature remains `resolve_lookup_value(self, value, can_reuse,
  allow_joins)`;
- named tuple output is still iterable and preserves the two fields;
- `FieldGetDbPrepValueIterableMixin.get_prep_lookup()` iterates over `self.rhs`;
- `Range.get_rhs_op()` consumes the processed SQL RHS positions.

Findings: F4.

Status: discharged by V1.

## PO6: Named tuple marker precondition

The branch condition `isinstance(value, tuple) and hasattr(value, '_fields')`
must be a justified approximation of "standard named tuple" for this issue.

Evidence: standard `collections.namedtuple` and `typing.NamedTuple` instances
are tuple instances with `_fields`. The issue names named tuples, not arbitrary
tuple subclasses.

Findings: F5.

Status: satisfied as a default-domain assumption.

## PO7: Proof honesty and non-execution

The FVK pass must not claim machine-checked proof or test results.

Discharge: artifacts include exact commands to run later and label the result
"constructed, not machine-checked." No tests, Python, or K tooling were run.

Findings: F5.

Status: satisfied.
