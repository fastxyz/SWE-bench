# Formal Spec English

The K artifacts are constructed, not machine-checked.

## Claim C1

`len(mkDenseImmutable(.Dims, scalar(X)))` evaluates to `1`.

Meaning: an immutable dense rank-0 scalar array has length one for every scalar value `X`.

## Claim C2

`len(mkDenseMutable(.Dims, scalar(X)))` evaluates to `1`.

Meaning: a mutable dense rank-0 scalar array has length one for every scalar value `X`.

## Claim C3

`len(mkSparseImmutable(.Dims, scalar(X)))` evaluates to `1`.

Meaning: an immutable sparse rank-0 scalar array has length one for every scalar value `X`.

## Claim C4

`len(mkSparseMutable(.Dims, scalar(X)))` evaluates to `1`.

Meaning: a mutable sparse rank-0 scalar array has length one for every scalar value `X`.

## Claim C5

`len(mkDenseImmutable(D1 : D2 : .Dims, flat(N)))` evaluates to `D1 * D2` when `D1` and `D2` are nonnegative integer dimensions.

Meaning: for a representative nonempty shape, V1 preserves product-of-dimensions length behavior instead of special-casing all arrays to length one.

## Semantics S1

Every constructor modeled here stores `product(shape)` as the array size, where `product(.Dims) = 1` and `product(D : rest) = D * product(rest)`.

Meaning: the empty shape uses the mathematical product identity, and nonempty shapes use the usual product.

## Frame F1

No public method signature, constructor signature, or virtual dispatch shape is changed.

Meaning: callers still invoke the same APIs; only the cached size value changes.
