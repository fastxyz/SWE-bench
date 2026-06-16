# FVK Proof Obligations

Status: constructed, not machine-checked.

## O1 - Input NaN Short-Circuit

Source: `SPEC.md` E4, Finding F2.

For any square matrix `M`, if `M.has(S.NaN)` is true, then `M.det(method)`
returns `S.NaN` before the size-specific determinant formulas or method-specific
algorithms run.

Discharge argument: V2 inserts the guard immediately after the non-square check
and before `n = self.rows`, the 0/1/2/3 formulas, and the Bareiss/Berkowitz/LU
dispatch.

## O2 - Expanded-Zero Pivot Rejection

Source: `SPEC.md` E5, Finding F1.

For each candidate `val` visited by Bareiss `_find_pivot`, if `val` is an
`Expr` and `val.expand()` is exact zero, then `_find_pivot` does not return that
candidate as the pivot.

Discharge argument: V2 retains the V1 code:

```python
if isinstance(val, Expr):
    val = val.expand()
if not val:
    continue
return (pos, val, None, None)
```

Since `S.Zero.__bool__()` is false, an expanded exact zero reaches `continue`.

## O3 - Nonzero Pivot Preservation

Source: `SPEC.md` E3/E6, Finding F1.

If a candidate was exact zero before V1, it is still skipped. If a candidate is
an `Expr` whose expansion remains truthy, `_find_pivot` returns the same
position and an algebraically equivalent expanded pivot value. If a candidate is
not an `Expr`, the old truthiness behavior is preserved.

Discharge argument: the only new branch is between the old truthiness check and
the unchanged return tuple. It filters only candidates that become false after
expansion.

## O4 - No Expanded-Zero Cumulative Denominator In Bareiss

Source: `SPEC.md` E1/E2/E5, Finding F1.

For Bareiss recursive states in the issue's polynomial expression domain, a
cumulative pivot `cumm` used in the next recursive level was previously accepted
by `_find_pivot` only if it did not expand to exact zero. Therefore the specific
expanded-zero denominator mechanism that produced `0/0`, `nan`, and invalid
`factor_terms` comparison is removed.

Discharge argument: `bareiss()` passes the selected `pivot_val` as the next
recursive call's `cumm`. O2 proves expanded-zero candidates are not selected.
Thus an expanded-zero polynomial pivot cannot become `cumm`.

## O5 - Public Compatibility Frame

Source: `SPEC.md` E3/E6.

The fix must not change `det()`'s method argument, accepted method names,
non-square exception, or local `_find_pivot` return shape.

Discharge argument: V2 changes no signatures, no method normalization branches,
and no exception branches. `_find_pivot` still returns either
`(pos, val, None, None)` or `(None, None, None, None)`.

## O6 - Machine Check Commands Are Emitted But Not Run

Source: FVK honesty gate and task no-exec constraint.

The artifacts must include exact commands a human could run later, while making
no claim that those commands have returned `#Top`.

Commands:

```sh
kompile fvk/mini-sympy-bareiss.k --backend haskell
kast --backend haskell fvk/bareiss-det-spec.k
kprove fvk/bareiss-det-spec.k
```

