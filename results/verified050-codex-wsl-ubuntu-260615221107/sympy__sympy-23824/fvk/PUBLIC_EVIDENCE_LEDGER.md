# PUBLIC_EVIDENCE_LEDGER.md

| ID | Source | Quote / reference | Obligation | Spec status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`kahane_simplify()` incorrectly reverses order of leading uncontracted gamma matrices" | Preserve order of leading uncontracted gamma matrices. | RESTORE-GENERAL. |
| E2 | `benchmark/PROBLEM.md` | "Leading gamma matrices without contractions should be unaffected" | Leading free prefix is a frame condition. | RESTORE-GENERAL and PO-1. |
| E3 | `benchmark/PROBLEM.md` | Both example expressions should simplify to `4*G(rho)*G(sigma)` | Witness-specific ordered output. | RESTORE-WITNESS. |
| E4 | `benchmark/PROBLEM.md` | "the insertion loop is just backward" | The loop direction is the suspected cause and repair point. | PO-3 and LEGACY-WITNESS. |
| E5 | `gamma_matrices.py` docstring | "cancels contracted elements ... without the contracted gamma matrices" | Contracted elements may be removed; leading free elements are not removal targets. | PO-5. |
| E6 | `gamma_matrices.py` implementation | `first_dum_pos = min(map(min, dum))` | Defines the boundary between leading skipped prefix and graph-processed suffix. | PO-2. |
| E7 | `gamma_matrices.py` implementation | `resulting_indices` is a list of lists | Prefix must be restored for every additive branch. | PO-4. |
