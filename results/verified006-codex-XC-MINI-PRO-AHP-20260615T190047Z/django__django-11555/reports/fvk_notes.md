# FVK Notes

Status: constructed FVK audit; no tests, Python, `kompile`, or `kprove` were
run.

## Decisions

1. Kept V1's early expression branch in
   `repo/django/db/models/sql/compiler.py`.

   - Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1.
   - Reason: the public issue identifies expression objects reaching
     `get_order_dir()` as the crash. The expression branch is the direct
     obligation: expressions return before the string-only helper can index
     them.

2. Kept V1's top-level-compatible expression normalization.

   - Trace: F1, PO2, and PO4.
   - Reason: `Lower('name')` is not already `OrderBy`, while
     `OrderBy(F(...))` is. The compiler must preserve both shapes, wrapping
     non-`OrderBy` expressions with ascending ordering and reversing when the
     enclosing relation ordering is descending.

3. Kept V1's alias-relative plain `F()` resolution.

   - Trace: `fvk/SPEC.md` contract item 5 and PO3.
   - Reason: simply appending related model expressions unchanged would avoid
     the immediate crash but would let `F('name')` inside `Lower('name')`
     resolve against the root query model. The helper uses the same
     `_setup_joins()` / `trim_joins()` / `transform_function` route that string
     related ordering already uses.

4. Changed V1 to add the non-source child guard in
   `_resolve_ordering_expression()`.

   - Trace: `fvk/FINDINGS.md` F2 and PO6.
   - Change: added `if not hasattr(expr, 'get_source_expressions'): return expr`.
   - Reason: V1 assumed every non-plain-`F` child had `copy()` and
     `get_source_expressions()`. Some expression children, notably conditional
     nodes such as `Q`, are not normal expression trees. The guard prevents a
     helper-level `AttributeError` while leaving those nodes to their own
     resolver.

5. Did not attempt a broader `Case/When(Q(...))` alias-resolution redesign.

   - Trace: `fvk/FINDINGS.md` F3 and PO8.
   - Reason: the public issue and hints specifically identify `OrderBy` and
     `Lower`/transform expressions. Full alias-relative rewriting of `Q`
     lookup strings inside conditional expressions needs a deeper query API or
     prefixing design and is not required to fix the reported crash family.
     The FVK artifacts record this as residual risk instead of treating it as
     proved.

6. Added FVK artifacts under `fvk/`.

   - Trace: F4 and the FVK artifact contract.
   - Files: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`,
     `ITERATION_GUIDANCE.md`, plus the supporting intent, evidence, adequacy,
     compatibility, and `.k` artifacts required by the FVK method.

## Verification Status

The proof is constructed, not machine-checked. The emitted commands in
`fvk/PROOF.md` are the future reproduction path, but this session's task
explicitly forbids running them.
