# Formal Spec in English

Status: paraphrase of `fvk/vector-add-spec.k`. Constructed, not
machine-checked.

## Claims

`ADD-ZERO-RIGHT`: For every vector component list `Cs`, evaluating
`vectorAdd(Vec(Cs), 0)` returns `Vec(Cs)`.

`PY-ADD-ZERO-LEFT`: For every vector component list `Cs`, evaluating Python-like
addition `pyAdd(0, Vec(Cs))` dispatches to vector reflected addition and returns
`Vec(Cs)`.

`VECTOR-VECTOR-ADD`: For every pair of vector component lists `Cs` and `Ds`,
evaluating `vectorAdd(Vec(Cs), Vec(Ds))` returns
`Vec(merge(Cs, Ds))`, preserving the existing vector-plus-vector combination
path.

`MUL-ZERO-VECTOR`: For every vector component list `Cs`, evaluating
`mul(0, Vec(Cs))` returns `Vec(.Comps)`, the modeled zero vector.

`SUM-REPRODUCER`: For every vector component list `Cs`, evaluating
`sum2(Vec(Cs), mul(0, Vec(Cs)))` returns `Vec(Cs)`.

`NONZERO-SCALAR-REJECT`: For every vector component list `Cs` and integer `I`
where `I =/=Int 0`, evaluating `vectorAdd(Vec(Cs), I)` returns `TypeError`.

## Frame Conditions

The model does not change the public signatures of `Vector.__add__`,
`Vector.__radd__`, or `_check_vector()`. It only adds a scalar-zero branch to
the addition path.
