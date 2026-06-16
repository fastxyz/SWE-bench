# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a public-intent-backed defect
requiring another source edit in `repo/django/db/models/sql/query.py`.

## Trace to findings and proof obligations

- Kept the pre-merge RHS prefix bump in `Query.combine()` because F-1 is
  discharged by PO-1, PO-2, PO-3, and PO-6. The code normalizes RHS aliases
  before the join loop can create an overlapping map such as
  `{'T4': 'T5', 'T5': 'T6'}`.
- Kept the `exclude` parameter on `Query.bump_prefix()` because F-2 is
  discharged by PO-2 and PO-4. The combine algorithm needs the initial RHS
  alias preserved while later aliases move to a fresh prefix namespace.
- Kept the local `rhs.table_map` alias-list copy in `combine()` because F-3 is
  discharged by PO-5. `Query.clone()` shallow-copies `table_map`, and
  relabeling shared alias lists would violate the documented "`rhs` is not
  modified" frame condition.
- Kept existing `bump_prefix()` call compatibility unchanged because F-4 is
  discharged by PO-7. Existing callers omit `exclude`, so they retain the old
  full-relabel behavior.
- Made no test changes and did not claim machine-checked proof confidence
  because F-5 and PO-8 require the honesty gate: the proof is constructed from
  an alias-calculus abstraction and K tooling was not run.

## Artifacts produced

- `fvk/SPEC.md`: intent spec, evidence ledger, adequacy audit, compatibility
  audit, and domain assumptions.
- `fvk/FINDINGS.md`: issue-derived and proof-derived findings with V1 status.
- `fvk/PROOF_OBLIGATIONS.md`: the obligations used to audit V1.
- `fvk/PROOF.md`: constructed proof sketch, expected K commands, and test
  recommendations.
- `fvk/ITERATION_GUIDANCE.md`: final V1 decision and follow-up guidance.
- `fvk/mini-query-alias.k` and `fvk/query-alias-spec.k`: constructed formal-core
  artifacts required by the FVK method.

## Commands intentionally not run

The benchmark forbids execution, so these were recorded in `fvk/PROOF.md` but
not executed:

```sh
cd fvk
kompile mini-query-alias.k --backend haskell
kast --backend haskell query-alias-spec.k
kprove query-alias-spec.k
```
