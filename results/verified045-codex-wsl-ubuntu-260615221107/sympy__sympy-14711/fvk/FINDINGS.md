# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and the FVK proof obligations.

## Findings

### FVK-F1: Scalar zero was rejected before vector addition could apply identity

Input: `sum([N.x, 0 * N.x])`

Observed pre-fix behavior: the `sum()` start value `0` reached
`Vector.__radd__`, which is aliased to `Vector.__add__`; `__add__` immediately
called `_check_vector(0)` and raised `TypeError('A Vector must be supplied')`.

Expected behavior: scalar zero acts as the additive identity, so the expression
returns a `Vector` equal to `N.x`.

Status: fixed by V1. Proof obligations: PO1, PO2, PO4.

### FVK-F2: Nonzero non-vector operands must still be rejected

Input: `N.x + 1`

Observed V1 behavior by inspection: `1` is not a `Vector` and does not compare
equal to `0`, so execution falls through to `_check_vector(1)`, preserving the
existing `TypeError`.

Expected behavior: nonzero scalar addition is not part of the public issue and
should remain invalid.

Status: confirmed. Proof obligation: PO5.

### FVK-F3: `_check_vector()` must not coerce scalar zero globally

Input class: non-add APIs such as dot, cross, outer product, frame setters, and
point setters receiving scalar `0`.

Observed risk in an alternative fix: changing `_check_vector(0)` to return
`Vector(0)` would make scalar zero acceptable across APIs that only require a
real `Vector`.

Expected behavior: the scalar-zero exception is confined to addition.

Status: V1 avoids the risk by changing only `Vector.__add__`. Proof
obligations: PO5, PO6, PO7.

### FVK-F4: The formal proof is constructed but not machine-checked

Input: the generated K artifacts `mini-python-vector.k` and
`vector-add-spec.k`.

Observed limitation: this session forbids running K tooling, so `kompile` and
`kprove` were not executed.

Expected next step outside this benchmark constraint: run the emitted commands
and expect `kprove` to reduce the claims to `#Top`.

Status: residual verification risk only; not a source-code bug. Proof
obligations: PO8.

### FVK-F5: Scope remains `sympy.physics.vector.Vector`

Input class: related but distinct arithmetic APIs such as `sympy.vector.Vector`
and `sympy.physics.vector.Dyadic`.

Observed public evidence: the issue imports from `sympy.physics.vector`, and
the traceback points to `sympy/physics/vector/vector.py`.

Expected behavior: fix the reported physics `Vector` addition behavior without
refactoring or changing unrelated vector subsystems.

Status: confirmed. Proof obligation: PO7.

## Proof-Derived Findings From `/verify`

No new source-code defect was surfaced beyond FVK-F1. The proof construction
does require the explicit side condition that only scalar zero receives the
identity treatment; this is already encoded in V1 by the `other == 0` guard and
the fall-through to `_check_vector()` for all other non-vector operands.
