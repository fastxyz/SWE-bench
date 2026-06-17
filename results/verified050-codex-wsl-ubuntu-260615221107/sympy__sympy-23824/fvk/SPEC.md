# SPEC.md

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 change in
`repo/sympy/physics/hep/gamma_matrices.py` inside `kahane_simplify()`. The
formalized unit is the leading-free-gamma restoration step:

```python
for i in range(first_dum_pos - 1, -1, -1):
    [ri.insert(0, free_pos[i]) for ri in resulting_indices]
```

The full Kahane graph algorithm is treated as framed context. This is the
right slice for the reported defect because the public issue explicitly says
the leading matrices are removed before the algorithm and inserted at the start
of the product afterward, and that the insertion loop is backward.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue title | "`kahane_simplify()` incorrectly reverses order of leading uncontracted gamma matrices" | The order of leading uncontracted gamma matrices is observable and must be preserved. | Encoded by PO-1 and claim RESTORE-GENERAL. |
| E2 | prompt / issue body | "Leading gamma matrices without contractions should be unaffected" | A leading free prefix must be a frame condition: it passes through unchanged. | Encoded by PO-1, PO-3, and PO-4. |
| E3 | prompt example | `G(rho)*G(sigma)*G(mu)*G(-mu)` should simplify to `4*G(rho)*G(sigma)` | For prefix `[rho, sigma]` and a contracted suffix simplifying to coefficient `4`, the resulting product keeps `[rho, sigma]`. | Encoded by claim RESTORE-WITNESS. |
| E4 | prompt mechanism hint | "the leading matrices are removed ... then inserted at the start ... the insertion loop is just backward" | The suspected root cause is the direction of the prepend loop, not the contraction identities. | Encoded by PO-3 and the legacy witness. |
| E5 | docstring / API contract | "cancels contracted elements ... without the contracted gamma matrices" | Contracted matrices may be removed; free gamma matrices are not a target for removal or reordering except where Kahane identities operate on non-leading suffix content. | Encoded as frame obligation PO-5. |
| E6 | implementation | `first_dum_pos = min(map(min, dum))` and loop skips `i < first_dum_pos` | Positions before `first_dum_pos` are the leading segment ignored by the graph walk and restored later. | Used as implementation evidence for PO-2. |
| E7 | implementation | `resulting_indices` is a list of index lists, one per additive branch | The prefix restoration must apply to every branch, not only the first branch. | Encoded by PO-4. |

## Intended Contract

Let:

- `P = [free_pos[0], ..., free_pos[first_dum_pos - 1]]`, the leading free
  gamma prefix of an in-domain `TensMul` gamma product.
- `R = [r0, r1, ..., rn]`, the branch list produced by the Kahane graph walk
  for the suffix starting at `first_dum_pos`.
- `C`, the scalar coefficient already computed from contractions and connected
  components.

The restoration step must produce branch list:

```text
[P ++ r0, P ++ r1, ..., P ++ rn]
```

and must not change `C`, the branch count, or the relative order inside any
branch `ri`.

For the issue witness, `P = [rho, sigma]`, `R = [[]]`, and `C = 4`, so the
observable result is:

```text
4 * GammaMatrix(rho) * GammaMatrix(sigma)
```

not:

```text
4 * GammaMatrix(sigma) * GammaMatrix(rho)
```

## Formal Model

The K artifacts model only the order-restoration slice:

- `fvk/mini-kahane-prefix.k` defines ordered gamma-index lists, branch lists,
  fixed restoration, and legacy forward-prepend restoration.
- `fvk/kahane-prefix-spec.k` states:
  - `RESTORE-GENERAL`: fixed restoration equals `mapPrefix(P, branches)` for
    every prefix and every branch list.
  - `RESTORE-WITNESS`: fixed restoration maps `[rho, sigma]` over one empty
    branch to `[rho, sigma]`.
  - `LEGACY-WITNESS`: the old forward-prepend loop maps the same witness to
    `[sigma, rho]`, matching the reported bug.

The model preserves the property under test: it distinguishes `[rho, sigma]`
from `[sigma, rho]`.

## V1 Audit Result

V1 iterates `range(first_dum_pos - 1, -1, -1)` while still inserting each
leading index at position zero. For any branch `ri`, after processing suffix
positions `i + 1` through `first_dum_pos - 1`, the branch equals
`P[i + 1:first_dum_pos] ++ ri_old`. Processing `i` inserts `P[i]` at the front,
yielding `P[i:first_dum_pos] ++ ri_old`. At loop exit this is
`P[0:first_dum_pos] ++ ri_old`.

No source change beyond V1 is required by this FVK pass.
