# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## P1: SI dimension dependency fact

The issue establishes that the collected dimension for
`second/(ohm*farad)` is accepted by
`SI.get_dimension_system().is_dimensionless(dim)`.

The SI dependency table also supports that result:

- `time` contributes `T: 1`;
- `impedance` contributes `M: 1, L: 2, I: -2, T: -3`;
- `capacitance` contributes `M: -1, L: -2, I: 2, T: 4`.

For `time/(capacitance*impedance)`, the exponents cancel:

- `M: 0`;
- `L: 0`;
- `I: 0`;
- `T: 1 - 4 + 3 = 0`.

Therefore the dimension has no base-dimensional dependencies and is
dimensionless under SI.

## P2: Function branch proof

Obligation: PO1.

Symbolic starting point:

`_collect_factor_and_dimension(arg) = (F, DRC)`, where `DRC` is
`Dimension(time/(capacitance*impedance))`.

V2 source path:

1. The `Function` branch collects all arguments into `fds`.
2. It computes `dims = [Dimension(1) if self._is_dimensionless(dim) else dim ...]`.
3. For `DRC`, `_is_dimensionless(DRC)` asks the dimension system and receives
   true by P1.
4. The result dimension for the one-argument function is therefore
   `Dimension(1)`.

For `exp(second/(ohm*farad))`, the scale-factor side is unchanged from the
collector's existing behavior. Under the SI scale factors involved in the
reproducer it reduces to `E`, matching the public issue's expected shape
`100 + E`.

## P3: Add branch proof for the reported expression

Obligation: PO2.

Symbolic starting point:

- `_collect_factor_and_dimension(100) = (100, Dimension(1))`;
- by P2, `_collect_factor_and_dimension(exp(second/(ohm*farad))) =
  (E, Dimension(1))`.

V2 source path:

1. The `Add` branch initializes `factor, dim` from the first addend.
2. For each later addend it checks `_dimensions_equivalent(dim, addend_dim)`.
3. `Dimension(1)` and `Dimension(1)` are structurally equal, so the helper
   returns true without asking the dimension system.
4. No `ValueError` is raised.
5. The factor is accumulated and the branch returns `(100 + E, Dimension(1))`.

This discharges the public reproducer.

## P4: Add branch proof for incompatible dimensions

Obligation: PO3.

For addend dimensions `D1` and `DLEN`:

1. `_dimensions_equivalent(D1, DLEN)` first checks structural equality, which is
   false.
2. It asks the dimension system for equivalence.
3. The dimension system returns false because a length-like dependency is not
   equivalent to dimensionless.
4. The `Add` branch raises `ValueError`.

This preserves public tests that expect incompatible unit additions, including
the existing path where `1 - exp(u / w)` is rejected because `u / w` is not
dimensionless.

## P5: Conservative helper proof for unsupported dimension expressions

Obligation: PO4.

For `_is_dimensionless(DUNSUPPORTED)`:

1. The helper obtains the dimension system.
2. The dimension-system call raises `TypeError`.
3. The helper catches `TypeError` and returns false.
4. The `Function` branch therefore preserves the original dimension instead of
   normalizing it to `Dimension(1)`.

For `_dimensions_equivalent(D1, DUNSUPPORTED)`:

1. The helper sees structural inequality.
2. The dimension-system equivalence call raises `TypeError`.
3. The helper catches `TypeError` and returns false.
4. The `Add` branch raises its normal `ValueError` for incompatible addends.

This is the V2 improvement over V1.

## P6: Compatibility proof

Obligation: PO5.

The public method `_collect_factor_and_dimension(self, expr)` retains the same
signature and return shape. The new helpers are private methods on `UnitSystem`.
No tests or public callers need signature changes.

The patch does not alter quantity scale-factor lookup, multiplication, powers,
derivatives, or the fallback branch. It only changes:

- how the `Add` branch decides dimension compatibility;
- how the `Function` branch canonicalizes dimensions already proven
  dimensionless.

Dimensionful function arguments remain non-strict: if `_is_dimensionless(dim)`
returns false, the original collected dimension is preserved.

## Test-redundancy recommendation

No test removal is recommended. The proof is constructed but not machine-checked,
and this task forbids modifying tests. Existing public tests should be kept.

Additional tests that would be justified in a normal development setting are
listed in `ITERATION_GUIDANCE.md`.

## Machine-check commands

These commands are recorded for a future environment with K installed. They were
not run here.

```sh
kompile fvk/mini-sympy-units.k --backend haskell
kast --backend haskell fvk/unitsystem-collect-spec.k
kprove fvk/unitsystem-collect-spec.k
```

Expected result after a successful machine check: `#Top`.
