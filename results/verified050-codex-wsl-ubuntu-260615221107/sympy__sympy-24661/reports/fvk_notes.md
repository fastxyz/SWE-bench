# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the existing
`EvaluateFalseTransformer.visit_Compare` patch discharges the public issue
intent for `parse_expr(..., evaluate=False)` and the delegated `sympify` string
path. No additional production-code edit is justified by the proof obligations.

## Decisions Traced to Findings and Proof Obligations

1. Kept the `ast.Compare` repair in `repo/sympy/parsing/sympy_parser.py`.
   - Finding trace: F1 identifies the pre-fix symptom
     `parse_expr('1 < 2', evaluate=False) -> True` and marks it resolved.
   - Proof trace: PO1 requires a supported single comparison to become a
     relational constructor call with `evaluate=False`; PO4 connects that
     transformed AST to the `parse_expr` evaluation path.

2. Kept `sympify` unchanged.
   - Finding trace: F2 records that the public `sympify('1 < 2',
     evaluate=False)` symptom is resolved through parser delegation.
   - Proof trace: PO5 shows string `sympify` passes the `evaluate` argument to
     `parse_expr`, so duplicating the fix in `sympify` would be unnecessary.

3. Kept support for all six standard Python comparison operators.
   - Finding trace: F3 treats the public hint's equality/inequality/less/greater
     operator family as the intended comparison family.
   - Proof trace: PO1 and PO2 require the mapping for single and chained
     supported comparisons; PO3 preserves fallback behavior for unsupported
     comparison forms.

4. Kept chained comparison handling.
   - Finding trace: F4 records chained comparisons as part of the same
     `ast.Compare` family and notes the residual side-effect evaluation-count
     assumption.
   - Proof trace: PO2 gives the loop invariant for constructing pairwise
     relationals and wrapping multi-relation chains in unevaluated `And`.

5. Did not add relation constructor names to the generic `visit_Call` whitelist.
   - Finding trace: F5 records explicit relational constructor calls as a
     considered but non-blocking scope decision.
   - Proof trace: PO6 limits the fix to the comparison syntax described by the
     public issue and avoids a broader name-based compatibility change, such as
     affecting local dictionaries that shadow `Eq` or `Lt`.

6. Did not run tests, Python imports, or K tooling.
   - Finding trace: F6 records the honesty gate.
   - Proof trace: PO7 requires the proof to remain constructed, not
     machine-checked, under this benchmark's no-execution rule.

## Artifacts Written

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- Supporting constructed K skeletons:
  - `fvk/mini-sympy-parser.k`
  - `fvk/sympy-parser-spec.k`

## Residual Risk

The proof is not machine-checked and the project test suite was not run. The
source conclusion rests on public intent, static source inspection, and the
constructed proof obligations only.
