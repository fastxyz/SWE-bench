# Constructed Proof

Status: constructed, not machine-checked. The commands below were not run.

## Claims Proved by Construction

The proof covers `Query.resolve_lookup_value()` over the value classes relevant
to the issue:

- expression-like value;
- scalar value;
- list;
- plain tuple;
- standard named tuple, including the public two-field `__range` case.

The K-style artifacts are:

- `fvk/mini-python.k`
- `fvk/resolve-lookup-value-spec.k`

## Proof Sketch

Let `R(v)` denote the recursive result of
`resolve_lookup_value(v, can_reuse, allow_joins)`.

Path 1: `value` has `resolve_expression`.

The first branch calls `value.resolve_expression(self, reuse=can_reuse,
allow_joins=allow_joins)` and returns that value unless another branch is
entered. No code in V1 changes this branch. This discharges the expression
frame portion of PO4.

Path 2: `value` is a list, tuple, or named tuple.

The function constructs one generator:

```python
(
    self.resolve_lookup_value(sub_value, can_reuse, allow_joins)
    for sub_value in value
)
```

By Python iteration order, this generator yields `R(v0), R(v1), ...` in the
same order as the original container. This discharges PO3.

Subpath 2a: `value` is a standard named tuple.

For a public range input `T(a, b)`, standard named tuple instances satisfy both
`isinstance(value, tuple)` and `hasattr(value, '_fields')`. The V1 branch calls:

```python
type(value)(*resolved_values)
```

The generator is expanded into positional arguments, so the constructor receives
`R(a)` and `R(b)`, not one generator object. The reached result is `T(R(a),
R(b))`, and the pre-fix missing-`far` TypeError path is removed. This discharges
PO2.

Subpath 2b: `value` is a plain list or plain tuple.

The named tuple condition is false, so V1 returns:

```python
type(value)(resolved_values)
```

This is the same constructor protocol as before V1 for non-named containers.
This discharges PO4 and avoids the regression in F3.

Path 3: `value` is a non-expression scalar.

No branch applies, and the function returns `value` unchanged. This discharges
the scalar frame portion of PO4.

Compatibility composition:

`Query.build_filter()` still calls `resolve_lookup_value(value, can_reuse,
allow_joins)` with the same signature. A named tuple result remains an iterable
of two resolved values, which is enough for
`FieldGetDbPrepValueIterableMixin.get_prep_lookup()` and the range lookup path.
This discharges PO5.

## Machine-Check Commands

These commands are emitted for later checking only:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell resolve-lookup-value-spec.k
kprove resolve-lookup-value-spec.k
```

Expected result after a successful machine check: `#Top`.

## Test Recommendation

No tests were run and no tests were edited.

Conditioned on a future successful machine check, a narrow unit test asserting
that `resolve_lookup_value()` reconstructs a two-field named tuple from resolved
members is subsumed by PO2. Integration tests for `field__range=NamedTuple(...)`
should be kept because this constructed proof does not model SQL compilation,
database preparation, or backend execution.

## Residual Risk

This is a partial-correctness proof over the modeled value-domain fragment. It
assumes finite containers, standard named tuple behavior, and correctness of
external `resolve_expression()` implementations. It is constructed, not
machine-checked.
