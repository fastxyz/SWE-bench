# FVK Spec: sympy__sympy-13877

Status: constructed from public intent and source review; not machine-checked.

## Scope

Target observable: `det(Matrix(...))` for concrete SymPy matrices, through
`MatrixDeterminant.det()` and the default Bareiss path for matrices larger than
3 by 3.

Target source:

- `repo/sympy/matrices/matrices.py::MatrixDeterminant.det`
- `repo/sympy/matrices/matrices.py::MatrixDeterminant._eval_det_bareiss`
- the local `_find_pivot` helper inside `_eval_det_bareiss`

The formal core abstracts full SymPy algebra to the property needed for this
issue: whether a matrix entry is `S.NaN`, exact zero, an expression that expands
to exact zero, or an expression that remains truthy after expansion.

## Intent Spec

1. For the reported no-input-`nan` symbolic matrices
   `M[n][j, i] = i + a*j`, determinant computation must not return `nan` or
   raise `TypeError("Invalid NaN comparison")`.
2. Bareiss remains a valid determinant method for symbolic matrices; the fix
   should not switch the default method to LU merely because entries are
   symbolic.
3. Bareiss pivot selection must not choose a candidate pivot that is
   algebraically zero under the zero detection named in the public issue
   discussion: expansion before truthiness acceptance.
4. If the input matrix already contains `S.NaN`, determinant computation should
   return `S.NaN` directly rather than treating that `nan` as an internally
   generated Bareiss failure to work around.
5. Existing public determinant behavior is preserved outside these obligations:
   non-square matrices raise `NonSquareMatrixError`, accepted method names stay
   the same, and the existing size-specific determinant formulas remain in use
   after the input-`nan` guard.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Matrix determinant raises Invalid NaN comparison with particular symbolic entries" | The reported determinant path must not raise that `TypeError` for the symbolic matrix family. | Encoded by O2/O3/O4. |
| E2 | prompt example | `f(5) -> nan`, `f(6) -> TypeError` for `i + a*j` entries | A no-input-`nan` determinant must not synthesize `nan` through invalid Bareiss pivots. | Encoded by O2/O3. |
| E3 | public hint | "Bareiss ... is equally valid for other matrices." | Do not change the default method away from Bareiss solely due symbolic entries. | Encoded as a frame condition. |
| E4 | public hint | "if the matrix contained nan to begin with ... return nan immediately" | Input `S.NaN` is a distinct case and must short-circuit to `S.NaN`. | Encoded by O1; V2 source change. |
| E5 | public hint | "`_find_pivot` should use some zero detection like `val = val.expand()` before `if val:`" | A candidate expression that expands to zero must not be accepted as a pivot. | Encoded by O2; V1 source change retained. |
| E6 | source docstring | `det` computes determinant, with methods `bareiss`, `berkowitz`, and `lu` | Preserve public method names and determinant entry point behavior. | Encoded by O5. |

## Formal Claims In English

Claim C1, input-NaN guard: for any square matrix whose entry list contains
`S.NaN`, `det()` returns `S.NaN` before choosing a determinant method or entering
Bareiss.

Claim C2, pivot expansion: for any Bareiss candidate pivot `v` that is an
expression and whose `v.expand()` is exact zero, the local pivot scan continues
past `v` and never returns it as `(pivot_pos, pivot_val)`.

Claim C3, pivot preservation: for any candidate whose expansion remains truthy,
the local pivot scan returns the expanded value. For exact-zero candidates, the
scan behaves as before and skips them.

Claim C4, no internally generated expanded-zero denominator: in recursive
Bareiss states over polynomial-like expressions where expansion detects the
zero pivots relevant to the issue, every cumulative pivot used as the next
division denominator was previously accepted only after expansion did not
produce exact zero.

Claim C5, compatibility frame: the patch does not alter determinant method
normalization, non-square error behavior, the 0 by 0 determinant convention, or
public method signatures.

## Adequacy Audit

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| C1 | Pass | Directly required by E4. |
| C2 | Pass | Directly required by E5 and explains the E1/E2 symptom. |
| C3 | Pass | Necessary frame condition for E3/E6: nonzero pivots remain usable. |
| C4 | Pass within stated abstraction | Covers the polynomial expanded-zero mechanism identified in E5. Full SymPy identity reasoning beyond expansion is outside the public obligation and is recorded as residual risk. |
| C5 | Pass | Preserves public API and method contract from E3/E6. |

## Public Compatibility Audit

Changed public symbol: `MatrixDeterminant.det`.

- Signature unchanged: `det(self, method="bareiss")`.
- Method names and aliases unchanged: `bareis -> bareiss`, `det_lu -> lu`.
- Non-square behavior unchanged: `NonSquareMatrixError`.
- Return type family unchanged: SymPy expression or `S.NaN`.
- Public override/callsite risk: no new arguments, no changed dispatch protocol,
  and no new subclass override requirement. The new guard calls existing
  `MatrixCommon.has`, already part of the matrix common API.

Changed internal helper: local `_find_pivot` inside `_eval_det_bareiss`.

- No public signature exists.
- Return tuple shape unchanged.
- Pivot value may now be the expanded equivalent of the original expression,
  which is semantically compatible with Bareiss arithmetic and required by E5.

