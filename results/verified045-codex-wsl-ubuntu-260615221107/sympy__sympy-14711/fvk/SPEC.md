# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The verified unit is the public arithmetic behavior of
`sympy.physics.vector.Vector.__add__` as exercised by Python's reflected
addition path and `sum()` default start value. The relevant implementation is
`repo/sympy/physics/vector/vector.py`.

The mini semantics are in `fvk/mini-python-vector.k`; the reachability claims
are in `fvk/vector-add-spec.k`.

## Public Intent Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "vector add 0 error" | Scalar zero is an in-domain additive boundary for vectors. |
| E2 | `benchmark/PROBLEM.md` | `sum([N.x, (0 * N.x)])` | This expression must return `N.x` without `TypeError`. |
| E3 | `benchmark/PROBLEM.md` | `TypeError: A Vector must be supplied` | The scalar-zero rejection in addition is the reported bug, not behavior to preserve. |
| E4 | `benchmark/PROBLEM.md` | `#if other == 0: return self` | Additive zero should be handled before `_check_vector`. |
| E5 | `Vector.__init__` docstring | `The only exception is to create a zero vector: zv = Vector(0)` | `Vector(0)` is the zero-vector representation. |
| E6 | `Vector` implementation | `__radd__ = __add__` | The `0 + vector` path reaches `Vector.__add__`. |
| E7 | `Vector.__mul__` and constructor | scalar multiplication followed by zero-component removal | `0 * vector` becomes `Vector(0)`. |
| E8 | `_check_vector()` implementation | raises `TypeError('A Vector must be supplied')` | Nonzero non-vector operands remain invalid. |
| E9 | source search | `_check_vector()` is shared outside addition | Do not coerce scalar zero in `_check_vector()`. |
| E10 | default Python behavior | `sum()` starts from integer `0` | Left scalar-zero identity is required for the reproducer. |

## Contract

For every `sympy.physics.vector.Vector` value `v`:

- `v + 0` returns a `Vector` equal to `v`.
- `0 + v` returns a `Vector` equal to `v` through the existing
  `__radd__ = __add__` alias.
- `v + w` for another `Vector` `w` preserves the existing behavior:
  `Vector(v.args + w.args)`.
- `v + x` for a nonzero non-`Vector` operand `x` continues to raise
  `TypeError('A Vector must be supplied')`.
- `sum([v, 0 * v])` returns a `Vector` equal to `v`.

The contract is partial with respect to arbitrary Python objects whose equality
comparison to `0` may itself have side effects or raise. The public intent and
existing SymPy usage cover scalar zeros and ordinary invalid operands, not
adversarial `__eq__` implementations.

## V1 Audit Conclusion

V1 satisfies the contract by adding this branch to `Vector.__add__`:

```python
if not isinstance(other, Vector) and other == 0:
    return Vector(self.args + [])
```

This branch handles scalar zero before `_check_vector()` while leaving all
`Vector` operands and nonzero invalid operands on the original path. No further
source change is justified by the FVK findings.
