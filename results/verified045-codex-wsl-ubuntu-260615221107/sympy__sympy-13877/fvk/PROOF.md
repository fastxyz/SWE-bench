# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Formal Core

The constructed K core is:

- `fvk/mini-sympy-bareiss.k`
- `fvk/bareiss-det-spec.k`

The model is a small abstraction of the relevant SymPy behavior. It does not
model all Python or all SymPy expressions. It preserves the bug-relevant
observable distinctions:

- an input contains `nan`;
- a candidate pivot is exact zero;
- a candidate pivot is an expression whose expansion is exact zero;
- a candidate pivot is an expression whose expansion remains truthy.

This abstraction passes the discriminator test for this issue: before V1,
`exprZero` could be accepted as a pivot; after V1/V2, `exprZero` is skipped.
Before V2, a matrix with `nan` outside an all-zero first pivot column could
return zero; after V2, the determinant guard returns `nan`.

## Constructed Claim Proofs

### C1 / O1 - Input NaN Guard

Initial state: `det(M)` with `hasNan(M) == true`.

Symbolic execution:

1. `det()` normalizes and validates `method`; this does not inspect entries.
2. `det()` checks square shape. O1's domain assumes this check passes.
3. The new guard `self.has(S.NaN)` is true.
4. Control returns `S.NaN`.
5. No size-specific formula or determinant method dispatch is reachable.

Therefore the public input-`nan` obligation is satisfied for all square matrix
sizes and all determinant methods.

### C2 / O2 - Expanded-Zero Pivot Rejection

Initial state: `_find_pivot` scans a candidate `val` with `isinstance(val,
Expr)` and `val.expand() == S.Zero`.

Symbolic execution:

1. The old outer truthiness check admits symbolic expression objects, so the
   body is entered.
2. The new branch assigns `val = val.expand()`.
3. The exact zero result is false under SymPy's zero truthiness.
4. The new `if not val: continue` branch skips the return.
5. The scan advances to the next candidate or returns no pivot if none remains.

Therefore an expression that expands to exact zero cannot be returned as
`pivot_val`.

### C3 / O3 - Nonzero Pivot Preservation

Case split:

- Exact-zero candidate: old code skipped it because `if val` was false; V2
  still skips it.
- Non-`Expr` truthy candidate: the `isinstance(val, Expr)` branch is false, so
  V2 returns the same candidate shape as V1.
- `Expr` truthy candidate whose expansion is truthy: V2 returns the same
  position and an algebraically equivalent expanded value.

Thus the fix does not alter the method contract except where E5 requires it.

### C4 / O4 - Bareiss Denominator Safety For The Issue Mechanism

Bareiss passes each selected `pivot_val` into the next recursive call as
`cumm`. By C2, no selected polynomial pivot in the issue's abstraction expands
to exact zero. Consequently, the specific mechanism described in the issue
discussion - an algebraically zero pivot becoming the next denominator and
creating `0/0` - is absent.

This is a partial-correctness result over the expanded-polynomial pivot domain.
It does not prove that `.expand()` detects every possible SymPy identity.

## Adequacy Gate

The English claims in `SPEC.md` are entailed by the public issue text and
public hints:

- The no-input-`nan` failure is addressed by C2/C4.
- The input-`nan` case is addressed by C1.
- Bareiss remains the default symbolic determinant method.
- No public signature or dispatch compatibility change is introduced.

No claim is derived solely from the candidate implementation.

## Test Recommendation

No tests should be removed. The proof is constructed, not machine-checked, and
the task forbids modifying test files. Useful tests after a normal development
cycle would cover:

- the reported `i + a*j` matrix family for `n = 5` and `n = 6`;
- a direct pivot candidate such as `a**2 - a*(a + 1) + a`;
- a matrix containing `S.NaN` in a position that Bareiss might otherwise skip.

## Reproduce The Machine Check Later

These commands are emitted for a future environment with K installed. They were
not run here.

```sh
kompile fvk/mini-sympy-bareiss.k --backend haskell
kast --backend haskell fvk/bareiss-det-spec.k
kprove fvk/bareiss-det-spec.k
```

Expected result after any needed K syntax adjustment for the local toolchain:
`kprove` reduces the listed claims to `#Top`.

