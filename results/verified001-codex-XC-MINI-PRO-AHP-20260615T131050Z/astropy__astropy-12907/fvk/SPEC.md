# FVK Specification: astropy__astropy-12907

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 repair for `astropy.modeling.separable` on the
public issue "Modeling's `separability_matrix` does not compute separability
correctly for nested CompoundModels." The formal target is the observable
`separability_matrix` behavior for compound `&` composition as implemented by
recursive `_separable` calls and `_cstack` on already computed coordinate
matrices.

The proof model intentionally focuses on the ndarray branch of `_cstack`,
because that is the branch reached by `_separable(transform.left)` and
`_separable(transform.right)` for public compound-model separability
calculation.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | prompt | "`cm = m.Linear1D(10) & m.Linear1D(5)` ... `separability_matrix(cm)` is a diagonal" | `&` composition of independent 1-input, 1-output models must produce independent diagonal dependency blocks. | Encoded in PO-2 and claim `CSTACK-RIGHT-PRESERVE`. |
| INT-2 | prompt | "`m.Pix2Sky_TAN() & m.Linear1D(10) & m.Linear1D(5)` ... outputs and inputs to the linear models are separable and independent" | A nonseparable left block must not couple later independent right-hand blocks. | Encoded in PO-3 and claim `CSTACK-OFF-BLOCKS`. |
| INT-3 | prompt | "If however, I nest these compound models ... Suddenly the inputs and outputs are no longer separable? This feels like a bug" | Parenthesizing a right-hand `&` compound model must preserve its already computed separability matrix. | Encoded in PO-3 and claim `CSTACK-RIGHT-PRESERVE`. |
| INT-4 | source docstring | `coord_matrix` has shape `(n_outputs, n_inputs)` and each operator returns an array of shape `(n_outputs, n_inputs)` | `_cstack(left, right)` must return a matrix whose row count is the sum of operand output rows and whose column count is the sum of operand input columns. | Encoded in PO-1 and claim `CSTACK-SHAPE`. |
| INT-5 | source code | `CompoundModel.__init__` for `op == '&'` sets `n_inputs = left.n_inputs + right.n_inputs` and `n_outputs = left.n_outputs + right.n_outputs` | The matrix block layout for `&` follows output and input concatenation order: left first, right second. | Encoded in PO-1 through PO-4. |
| INT-6 | prompt, suspect legacy output | The nested example printed bottom-right all-True rows before the fix. | This is the reported bug symptom, not an intended behavior. | Recorded as FVK-F1; rejected as spec evidence. |

## Contract

For in-domain coordinate matrices `L` and `R` with nonnegative dimensions,
`_cstack(L, R)` must compute a block matrix `C` such that:

1. `rows(C) = rows(L) + rows(R)`.
2. `cols(C) = cols(L) + cols(R)`.
3. For every in-range `i, j` in the left block,
   `C[i, j] = L[i, j]`.
4. For every in-range `i, j` in the right block,
   `C[rows(L) + i, cols(L) + j] = R[i, j]`.
5. For every off-diagonal block coordinate, `C` is zero/False.

For public `separability_matrix`, the final `np.where(matrix != 0, True, False)`
conversion must preserve this dependency relation as a boolean matrix.

## Expected Reported Instance

Let `P` be the 2-output, 2-input nonseparable `Pix2Sky_TAN` dependency block:

```text
[[1, 1],
 [1, 1]]
```

Let `D` be the separable nested `Linear1D & Linear1D` dependency block:

```text
[[1, 0],
 [0, 1]]
```

The intended result for `P & D` is:

```text
[[1, 1, 0, 0],
 [1, 1, 0, 0],
 [0, 0, 1, 0],
 [0, 0, 0, 1]]
```

The V1 source line `cright[-right.shape[0]:, -right.shape[1]:] = right`
implements contract item 4. The previous value `= 1` violated contract item 4
whenever `R` contained any zero/False entry.
