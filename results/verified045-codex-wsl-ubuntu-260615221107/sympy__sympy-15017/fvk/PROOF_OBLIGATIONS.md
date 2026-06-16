# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Empty-shape product identity

For shape `()`, the element-count product is `1`.

- Formal claim support: C1-C4 in `fvk/array-size-spec.k`.
- Source support: `functools.reduce(lambda x,y: x*y, shape, 1)` returns the initializer `1` for an empty shape.
- Finding link: F1, F3.

## PO2: Nonempty-shape product preservation

For nonempty shape `(d1, d2, ..., dn)`, the element count remains `d1 * d2 * ... * dn`.

- Formal claim support: C5 and semantics rule `product(D : REST) => D *Int product(REST)`.
- Source support: adding a reduce initializer does not change reduce results for nonempty shapes.
- Finding link: F3.

## PO3: `__len__` returns constructor-cached size

For any audited array object, `len(array)` returns `_loop_size`.

- Formal claim support: semantics rule `len(arr(SHAPE, SIZE)) => SIZE`.
- Source support: `NDimArray.__len__` returns `self._loop_size`.
- Finding link: F1, F3.

## PO4: All storage and mutability variants are covered

The scalar length obligation holds for immutable dense, mutable dense, immutable sparse, and mutable sparse arrays.

- Formal claim support: C1-C4.
- Source support: V1 changes all four constructor computations.
- Finding link: F3.

## PO5: Public compatibility is preserved except for the intended value change

The fix does not change public signatures, constructor signatures, return types, or dispatch shapes.

- Formal claim support: frame F1 in `FORMAL_SPEC_ENGLISH.md`.
- Source support: the diff changes only `_loop_size` expressions.
- Finding link: F4.

## PO6: Bug-preserving public test evidence is not authoritative

The legacy public assertion `len(rank_zero_array) == 0` must not be used as a postcondition because it conflicts with the issue intent.

- Formal claim support: `SPEC_AUDIT.md` marks the assertion SUSPECT.
- Source support: no test files are modified; production code follows public issue intent.
- Finding link: F2.
